# ============================================================
# MIPS MCU chip_top - Cadence Genus Synthesis (MMMC)
# Technology : GPDK045 (gsclib045 + giolib045 pads)
# Top Module : chip_top  (IO pads + mcu_core)
# Corners    : setup = FUNC_SS_WORST + FUNC_FF_BEST, hold = FUNC_FF_BEST
#              (./cons/chip_top_syn.mmmc.tcl)
# Based on spi_bridge_top_45nm_MMMC.tcl. Changes:
#   - new RTL list (SPI slave bridge + CPU + MCU + pads top + generated ROM)
#   - pad instances dont_touch
#   - inst_rom / mips_cpu: no boundary optimization (ROM constants must not
#     prune CPU logic for instructions the program does not use)
#   - extra checks: hierarchy / per-block area, IO timing, unconstrained
# ============================================================

set TOP_DESIGN chip_top

set LOG_DIR      "./log"
set RPT_DIR      "./report"
set UNMAPPED_DIR "./unmapped"
set MAPPED_DIR   "./mapped"

file mkdir $LOG_DIR
file mkdir $RPT_DIR
file mkdir $UNMAPPED_DIR
file mkdir $MAPPED_DIR

# ------------------------------------------------------------
# Libraries (absolute PDK path, see MMMC file)
# ------------------------------------------------------------
if {![info exists GPDK_ROOT]} { set GPDK_ROOT "/home/hah003/PROJ1/GPDK045/digital" }

set LEF_LIB_PATH  "$GPDK_ROOT/gsclib045_all_v4.4/gsclib045/lef $GPDK_ROOT/gsclib045_all_v4.4/gsclib045_tech/lef $GPDK_ROOT/giolib045_v3.5/lef"
set MMMC_FILE     "./cons/chip_top_syn.mmmc.tcl"
set LEF_LIST      {gsclib045_tech.lef gsclib045_macro.lef giolib045.lef}

set_db auto_ungroup none
set_db max_cpus_per_server 2

set_db syn_generic_effort high
set_db syn_map_effort high
set_db syn_opt_effort high

set_db init_lib_search_path [concat $LEF_LIB_PATH]

read_mmmc $MMMC_FILE
read_physical -lef $LEF_LIST

set_db hdl_array_naming_style %s_%d
set_db / .uniquify_naming_style ${TOP_DESIGN}_%s_%d

# ------------------------------------------------------------
# RTL Sources
# ------------------------------------------------------------
set RTL_SOURCES "../RTL/Reset_sync.v \
                 ../RTL/Pulse_sync.v \
                 ../RTL/Async_fifo.v \
                 ../RTL/Spi_slave.v \
                 ../RTL/Register_block.v \
                 ../RTL/Spi_slave_bridge.v \
                 ../RTL/Sc_cu.v \
                 ../RTL/Alu.v \
                 ../RTL/Regfile.v \
                 ../RTL/Mips_cpu.v \
                 ../RTL/Data_ram.v \
                 ../FW/build/echo_rom.v \
                 ../RTL/Mcu_core.v \
                 ../RTL/Chip_top.v"

read_hdl $RTL_SOURCES
elaborate $TOP_DESIGN

time_info Elaboration

init_design

set_db optimize_merge_flops false
set_db optimize_merge_latches false

uniquify -verbose $TOP_DESIGN

# ------------------------------------------------------------
# Hierarchy protection
# ------------------------------------------------------------
# (1) IO pads: never resized / removed / restructured
set PAD_INSTS {}
foreach i [get_db insts] {
    if {[string match {u_pad_*} [get_db $i .name]]} { lappend PAD_INSTS $i }
}
puts "INFO: [llength $PAD_INSTS] pad instances found (expected 14)"
if {[llength $PAD_INSTS] > 0} {
    set_db $PAD_INSTS .dont_touch true
} else {
    puts "WARNING: no u_pad_* instances found - pads NOT protected"
}

# (2) Keep inst_rom and mips_cpu as separate blocks and stop constant
#     propagation across their boundaries. Without this, ROM output bits that
#     are constant for THIS program (unused opcodes / registers) would be
#     propagated into the CPU and its decode / datapath logic pruned.
#
#     Run 2 showed: 'boundary_opto' is NOT a hinst attribute in Genus 22.17
#     (regfile kept only 224 of 992 flops). It is a MODULE (subdesign)
#     attribute, so it is set on the modules below. ungroup_ok stays on the
#     hinsts (that one was accepted).
foreach h {u_core/u_rom u_core/u_cpu} {
    set hi {}
    catch {set hi [get_db hinst:${TOP_DESIGN}/$h]}
    if {[llength $hi] == 0} {
        puts "WARNING: hierarchy $h not found"
        continue
    }
    if {[catch {set_db $hi .ungroup_ok false} msg]} {
        puts "WARNING: ungroup_ok on $h: $msg"
    }
    set mod [get_db $hi .module]
    if {[catch {set_db $mod .boundary_opto false} msg]} {
        puts "WARNING: boundary_opto on module [get_db $mod .name] ($h): $msg"
    } else {
        puts "INFO: boundary_opto = [get_db $mod .boundary_opto] on module [get_db $mod .name] ($h)"
    }
}

# (3) Backstop, using the attribute names Genus itself printed in run 1
#     (GLO-12 / GLO-45): do not replace flops that look constant for this
#     program by logic constants. Keeps every architectural register even if
#     boundary_opto were to be ignored. Cost: PC[1:0] flops are kept too.
foreach {attr val} {optimize_constant_0_flops false optimize_constant_1_flops false optimize_constant_feedback_seqs false} {
    if {[catch {set_db / .$attr $val} msg]} {
        puts "WARNING: root attribute $attr: $msg"
    } else {
        puts "INFO: root $attr = [get_db / .$attr]"
    }
}

check_design > ${RPT_DIR}/00_check_design.rpt
check_design -unresolved >> ${RPT_DIR}/00_check_design.rpt

# ------------------------------------------------------------
# Constraints (chip_top.sdc applied through constraint mode FUNC)
# ------------------------------------------------------------
source -verbose ./cons/dont_use_45nm.tcl

check_timing_intent -verbose > ${RPT_DIR}/01_check_timing_intent.rpt

report_port -delay -driver [all_inputs] > ${RPT_DIR}/02_report_port.rpt
report_port -delay -load [all_outputs] >> ${RPT_DIR}/02_report_port.rpt

# ------------------------------------------------------------
# Generic Synthesis
# ------------------------------------------------------------
syn_generic

time_info GENERIC
report_datapath > ${RPT_DIR}/03_report_datapath_generic.rpt

write_snapshot -outdir $RPT_DIR -tag syn_generic
write_db -to_file ${UNMAPPED_DIR}/syn_generic.db

# ------------------------------------------------------------
# Technology Mapping
# ------------------------------------------------------------
syn_map

time_info MAPPED
report_datapath > ${RPT_DIR}/04_report_datapath_map.rpt

foreach cg [vfind / -cost_group *] {
    report timing -cost_group [list $cg] > ${RPT_DIR}/05_[basename $cg]_post_syn_map.rpt
}

write_snapshot -outdir $RPT_DIR -tag syn_map
write_db -to_file ${MAPPED_DIR}/syn_map.db

# ------------------------------------------------------------
# Optimization
# ------------------------------------------------------------
syn_opt

report_constraint -all_violators > ${RPT_DIR}/06_report_constraint.rpt

write_snapshot -outdir $RPT_DIR -tag syn_opt

time_info OPT

foreach cg [vfind / -cost_group *] {
    report timing -cost_group [list $cg] > ${RPT_DIR}/07_[basename $cg]_post_syn_opt.rpt
}

write_db -to_file ${MAPPED_DIR}/syn_opt.db

# Sanity check: the CPU must not have been trimmed to what echo.s uses.
# The register file keeps all 31 x 32 = 992 flops only if the ROM boundary
# protection worked (echo.s itself writes only $1..$5).
if {[catch {
    set rf_seq 0
    foreach i [get_db hinst:${TOP_DESIGN}/u_core/u_cpu/u_rf .insts] {
        if {[get_db $i .base_cell.is_sequential]} { incr rf_seq }
    }
    puts "INFO: regfile sequential cells = $rf_seq (expected 992)"
} msg]} {
    puts "WARNING: regfile flop count check failed: $msg"
}

# ------------------------------------------------------------
# Final Reports
# ------------------------------------------------------------
report_analysis_views -type all > ${RPT_DIR}/08_${TOP_DESIGN}_SYN_analysis_view.rpt
report_area > ${RPT_DIR}/09_${TOP_DESIGN}_SYN_area.rpt
catch {report_area -depth 3 > ${RPT_DIR}/09a_${TOP_DESIGN}_SYN_area_by_block.rpt}
report_clocks > ${RPT_DIR}/10_${TOP_DESIGN}_SYN_clock.rpt
report_datapath > ${RPT_DIR}/11_${TOP_DESIGN}_SYN_datapath.rpt
report_design_rules > ${RPT_DIR}/12_${TOP_DESIGN}_SYN_design_rules.rpt
report_gates > ${RPT_DIR}/13_${TOP_DESIGN}_SYN_gate.rpt
report_gates -power >> ${RPT_DIR}/13_${TOP_DESIGN}_SYN_gate.rpt
report_hierarchy > ${RPT_DIR}/14_${TOP_DESIGN}_SYN_hier.rpt
report_memory_cells > ${RPT_DIR}/15_${TOP_DESIGN}_SYN_mem_cell.rpt
report_messages -all > ${RPT_DIR}/16_${TOP_DESIGN}_SYN_message.rpt
report_nets -hierarchical > ${RPT_DIR}/17_${TOP_DESIGN}_SYN_net.rpt
report_power > ${RPT_DIR}/18_${TOP_DESIGN}_SYN_pwr.rpt
report_qor > ${RPT_DIR}/19_${TOP_DESIGN}_SYN_qor.rpt
report_timing -nworst 100 -net > ${RPT_DIR}/20_${TOP_DESIGN}_SYN_timing.rpt

report_timing -view FUNC_SS_WORST -nworst 100 -net > ${RPT_DIR}/20a_${TOP_DESIGN}_SYN_timing_SS.rpt
report_timing -view FUNC_FF_BEST  -nworst 100 -net > ${RPT_DIR}/20b_${TOP_DESIGN}_SYN_timing_FF.rpt

# Per-clock and IO paths (new for chip_top)
catch {report_timing -view FUNC_SS_WORST -to   [get_clocks ACLK] -nworst 20 > ${RPT_DIR}/21a_${TOP_DESIGN}_SYN_timing_ACLK.rpt}
catch {report_timing -view FUNC_SS_WORST -to   [get_clocks SCLK] -nworst 20 > ${RPT_DIR}/21b_${TOP_DESIGN}_SYN_timing_SCLK.rpt}
catch {report_timing -view FUNC_SS_WORST -from [all_inputs]  -nworst 20      > ${RPT_DIR}/21c_${TOP_DESIGN}_SYN_timing_inputs.rpt}
catch {report_timing -view FUNC_SS_WORST -to   [all_outputs] -nworst 20      > ${RPT_DIR}/21d_${TOP_DESIGN}_SYN_timing_outputs.rpt}

# Unconstrained endpoints (should be only the async-group crossings /
# reset paths that are intentionally untimed)
catch {report_timing -lint -verbose > ${RPT_DIR}/22_${TOP_DESIGN}_SYN_timing_lint.rpt}

report_summary

# ------------------------------------------------------------
# Export Mapped Design
# ------------------------------------------------------------
write_design -basename ${MAPPED_DIR}/${TOP_DESIGN}_mapped

write_hdl > ${MAPPED_DIR}/${TOP_DESIGN}_syn_final.v
write_sdc -view FUNC_SS_WORST > ${MAPPED_DIR}/${TOP_DESIGN}_syn_final.sdc

write_sdf -timescale ns -nonegchecks -recrem split -edges check_edge -setuphold split > ${MAPPED_DIR}/${TOP_DESIGN}_delays.sdf

# ------------------------------------------------------------
# Finish
# ------------------------------------------------------------
time_info FINAL

puts "============================"
puts "Synthesis Finished ........."
puts "============================"

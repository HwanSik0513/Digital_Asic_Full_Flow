######################################################################
# spi_bridge_top_syn.mmmc.tcl
#
# Synthesis MMMC for spi_bridge_top (Cadence Genus 22.17, GPDK045)
#
# Purpose:
#   Bind each library to ONE corner so Genus cannot mix slow/fast cells
#   or report a fast-corner slack as the setup result.
#     setup views: FUNC_SS_WORST  (slow_vdd1v0, 125 C, RC WORST)
#                  FUNC_FF_BEST   (fast_vdd1v0,   0 C, RC BEST)
#     hold  view : FUNC_FF_BEST
#   Setup is timed on both views (worst wins); SS normally dominates.
#   Hold is fixed in PnR.
#
# Corner names match the PnR view file (spi_bridge_top.mmmc.view) so the
# synthesis and PnR reports can be compared view by view.
#
# Paths are relative to the SYN run directory (same as the old
# STD_LIB_PATH / IO_LIB_PATH / QRC_FILE_PATH in the synthesis script).
######################################################################

set GPDK        "../../../GPDK045/digital"
set STD_TIMING  "$GPDK/gsclib045_all_v4.4/gsclib045/timing"
set IO_TIMING   "$GPDK/giolib045_v3.5/timing"
set QRC_TECH    "$GPDK/gsclib045_all_v4.4/gsclib045_tech/qrc/qx/gpdk045.tch"

#---------------------------------------------------------------------
# 1. Library sets (same cell libraries the old SLOW / FAST scripts read)
#---------------------------------------------------------------------
create_library_set -name SS_Max_0p90v_125c \
    -timing [list $STD_TIMING/slow_vdd1v0_basicCells.lib \
                  $IO_TIMING/pads_SS_s1vg.lib]

create_library_set -name FF_Min_1p10v_0c \
    -timing [list $STD_TIMING/fast_vdd1v0_basicCells.lib \
                  $IO_TIMING/pads_FF_s1vg.lib]

#---------------------------------------------------------------------
# 2. Timing conditions
#    No create_opcond: each library's own default operating condition
#    (slow 0.9 V / 125 C, fast 1.1 V / 0 C) is used as characterized.
#---------------------------------------------------------------------
create_timing_condition -name TC_SS -library_sets { SS_Max_0p90v_125c }
create_timing_condition -name TC_FF -library_sets { FF_Min_1p10v_0c }

#---------------------------------------------------------------------
# 3. RC corners (QRC tech replaces the old read_qrc command)
#---------------------------------------------------------------------
create_rc_corner -name WORST -temperature 125 -qrc_tech $QRC_TECH
create_rc_corner -name BEST  -temperature 0   -qrc_tech $QRC_TECH

#---------------------------------------------------------------------
# 4. Delay corners
#---------------------------------------------------------------------
create_delay_corner -name SS_WORST \
    -early_timing_condition { TC_SS } -late_timing_condition { TC_SS } \
    -early_rc_corner WORST            -late_rc_corner WORST

create_delay_corner -name FF_BEST \
    -early_timing_condition { TC_FF } -late_timing_condition { TC_FF } \
    -early_rc_corner BEST             -late_rc_corner BEST

#---------------------------------------------------------------------
# 5. Constraint mode
#    The SDC is applied at init_design (after elaborate), so the
#    u_sclk_gen/o_sclk_reg/Q lookup for the generated SCLK still works.
#    Clock period stays inside the SDC (CLK_PERIOD default per run).
#---------------------------------------------------------------------
create_constraint_mode -name FUNC \
    -sdc_files { ./cons/spi_bridge_top.sdc }

#---------------------------------------------------------------------
# 6. Analysis views
#---------------------------------------------------------------------
create_analysis_view -name FUNC_SS_WORST -constraint_mode FUNC -delay_corner SS_WORST
create_analysis_view -name FUNC_FF_BEST  -constraint_mode FUNC -delay_corner FF_BEST

#---------------------------------------------------------------------
# 7. View assignment
#    Both corners are setup views so Genus times both and reports slack
#    per view (20a / 20b reports). Each path is judged by its WORST view,
#    so a negative SS slack can never be hidden by the FF corner.
#    In practice SS dominates setup.
#---------------------------------------------------------------------
set_analysis_view -setup { FUNC_SS_WORST FUNC_FF_BEST } -hold { FUNC_FF_BEST }

######################################################################
# chip_top_syn.mmmc.tcl
#
# Synthesis MMMC for chip_top (Cadence Genus 22.17, GPDK045)
# Same corner strategy as spi_bridge_top_syn.mmmc.tcl:
#   setup views: FUNC_SS_WORST (slow 0.9 V / 125 C) + FUNC_FF_BEST
#   hold  view : FUNC_FF_BEST   (hold is fixed in PnR)
# Each library set now contains the IO pad library of the same corner.
#
# GPDK_ROOT is an absolute path (the PDK lives under PROJ1; the old
# relative path ../../../GPDK045 would point to PROJ2). It can be
# overridden by setting GPDK_ROOT before read_mmmc.
######################################################################

if {![info exists GPDK_ROOT]} { set GPDK_ROOT "/home/hah003/PROJ1/GPDK045/digital" }

set STD_TIMING  "$GPDK_ROOT/gsclib045_all_v4.4/gsclib045/timing"
set IO_TIMING   "$GPDK_ROOT/giolib045_v3.5/timing"
set QRC_TECH    "$GPDK_ROOT/gsclib045_all_v4.4/gsclib045_tech/qrc/qx/gpdk045.tch"

#---------------------------------------------------------------------
# 1. Library sets (std cells + IO pads, one corner each)
#---------------------------------------------------------------------
create_library_set -name SS_Max_0p90v_125c \
    -timing [list $STD_TIMING/slow_vdd1v0_basicCells.lib \
                  $IO_TIMING/pads_SS_s1vg.lib]

create_library_set -name FF_Min_1p10v_0c \
    -timing [list $STD_TIMING/fast_vdd1v0_basicCells.lib \
                  $IO_TIMING/pads_FF_s1vg.lib]

#---------------------------------------------------------------------
# 2. Timing conditions (library default operating conditions)
#---------------------------------------------------------------------
create_timing_condition -name TC_SS -library_sets { SS_Max_0p90v_125c }
create_timing_condition -name TC_FF -library_sets { FF_Min_1p10v_0c }

#---------------------------------------------------------------------
# 3. RC corners
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
#---------------------------------------------------------------------
create_constraint_mode -name FUNC \
    -sdc_files { ./cons/chip_top.sdc }

#---------------------------------------------------------------------
# 6. Analysis views
#---------------------------------------------------------------------
create_analysis_view -name FUNC_SS_WORST -constraint_mode FUNC -delay_corner SS_WORST
create_analysis_view -name FUNC_FF_BEST  -constraint_mode FUNC -delay_corner FF_BEST

#---------------------------------------------------------------------
# 7. View assignment
#---------------------------------------------------------------------
set_analysis_view -setup { FUNC_SS_WORST FUNC_FF_BEST } -hold { FUNC_FF_BEST }

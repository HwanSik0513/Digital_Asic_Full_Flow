######################################################################
# tempus_post_sta.tcl - Post-route signoff STA for spi_bridge_top (Tempus 22.17)
#
# Run in the PNR directory (the .dat refers to ../SYN/... with relative paths):
#   tempus -files tempus_post_sta.tcl -log log/tempus_post_sta.log
#   (or start tempus and:  source tempus_post_sta.tcl)
#
# Which design to analyze: set DB_NAME below
#   RouteDesign             : after 4_RouteDesign (before ECO / filler)
#   ChipFinish              : after 5_ChipFinish (no ECO flow)
#   ChipFinish_after_ECO    : after 6_ECO (Tempus ECO applied)
#
# Reports -> reports/sta/<DB_NAME>/
#   00_parasitics.rpt        RC annotation coverage (must be 100 %)
#   01_check_timing.rpt      unconstrained / unclocked / missing I/O delay
#   02_coverage.rpt          analysis coverage per check type
#   10_setup_summary.rpt     setup  (FUNC_SS_WORST) worst 50 paths, end-point slack list
#   11_setup_paths.rpt       setup  full path detail incl. clock network
#   20_hold_summary.rpt      hold   (FUNC_FF_BEST)
#   21_hold_paths.rpt        hold   full path detail
#   30_recovery.rpt          async reset de-assertion (setup-like, SS)
#   31_removal.rpt           async reset de-assertion (hold-like, FF)
#   40_clock_skew_*.rpt      clock skew / latency per view
#   50_drv.rpt               max transition / capacitance / fanout violators
#   60_pre_vs_post.rpt       the synthesis worst path re-timed after route
#
# SDF (for post-layout gate-level simulation, written in the PNR directory)
#   spi_bridge_top_post_wst.sdf   setup corner FUNC_SS_WORST
#   spi_bridge_top_post_bst.sdf   hold  corner FUNC_FF_BEST
######################################################################

set TOP     spi_bridge_top
set DB_NAME RouteDesign
set SETUP_VIEW FUNC_SS_WORST
set HOLD_VIEW  FUNC_FF_BEST
set NPATHS  50

#---------------------------------------------------------------------
# Pre-STA worst path (copy Startpoint / Endpoint from the Genus report
#   ../SYN/report/20a_spi_bridge_top_SYN_timing_SS.rpt  (Path 1)
# Leave empty to skip section 6.
#---------------------------------------------------------------------
set PRE_FROM "u_rx_fifo/r_wr_ptr_gray_rclk_reg_4/CK"   ;# 10 ns (100 MHz) synthesis worst path start
set PRE_TO   "o_bus_rdata[4]"                         ;# ... and end

set RPT reports/sta/$DB_NAME
file mkdir $RPT

#---------------------------------------------------------------------
# 0. Read the routed design (netlist + MMMC + SDC + placement/routing + RC)
#---------------------------------------------------------------------
read_design ${DB_NAME}.dat $TOP

# Post-CTS: real clock tree delays, not ideal clocks
set_propagated_clock [all_clocks]

#---------------------------------------------------------------------
# 1. Inputs are complete?
#---------------------------------------------------------------------
report_annotated_parasitics          > $RPT/00_parasitics.rpt
check_timing -verbose                > $RPT/01_check_timing.rpt
report_analysis_coverage             > $RPT/02_coverage.rpt

#---------------------------------------------------------------------
# 2. Setup at the slow corner
#---------------------------------------------------------------------
report_timing -late -view $SETUP_VIEW -max_paths $NPATHS -path_type summary  > $RPT/10_setup_summary.rpt
report_timing -late -view $SETUP_VIEW -max_paths 10 -path_type full_clock -net > $RPT/11_setup_paths.rpt

#---------------------------------------------------------------------
# 3. Hold at the fast corner
#---------------------------------------------------------------------
report_timing -early -view $HOLD_VIEW -max_paths $NPATHS -path_type summary  > $RPT/20_hold_summary.rpt
report_timing -early -view $HOLD_VIEW -max_paths 10 -path_type full_clock -net > $RPT/21_hold_paths.rpt

#---------------------------------------------------------------------
# 4. Recovery / removal : reset_sync outputs -> async clear pins of the flops
#    (ARESETn itself is a false path in the SDC; the synchronized resets are
#     real clocked paths and must meet recovery/removal)
#---------------------------------------------------------------------
report_timing -check_type recovery -view $SETUP_VIEW -max_paths 20 -path_type full_clock > $RPT/30_recovery.rpt
report_timing -check_type removal  -view $HOLD_VIEW  -max_paths 20 -path_type full_clock > $RPT/31_removal.rpt

#---------------------------------------------------------------------
# 5. Clock tree quality + DRV
#---------------------------------------------------------------------
if {[catch {
    report_clock_timing -type skew    -view $SETUP_VIEW > $RPT/40_clock_skew_setup.rpt
    report_clock_timing -type latency -view $SETUP_VIEW > $RPT/41_clock_latency_setup.rpt
    report_clock_timing -type skew    -view $HOLD_VIEW  > $RPT/42_clock_skew_hold.rpt
} msg]} { puts "**WARN: report_clock_timing failed: $msg" }

report_constraint -all_violators > $RPT/50_drv.rpt

#---------------------------------------------------------------------
# 6. Pre vs Post : the same path the synthesis STA reported as worst
#---------------------------------------------------------------------
if {$PRE_FROM ne "" && $PRE_TO ne ""} {
    report_timing -late -view $SETUP_VIEW -from $PRE_FROM -to $PRE_TO \
                  -path_type full_clock -net > $RPT/60_pre_vs_post.rpt
} else {
    puts "**INFO: PRE_FROM / PRE_TO empty -> section 6 (pre vs post) skipped"
}

#---------------------------------------------------------------------
# 7. One-line results in the log
#---------------------------------------------------------------------
foreach {tag view mode} [list setup $SETUP_VIEW -late hold $HOLD_VIEW -early] {
    if {[catch {
        set p [report_timing $mode -view $view -max_paths 1 -collection]
        puts [format "**RESULT: %-5s %-14s WNS = %s ns" $tag $view [get_property $p slack]]
    } msg]} { puts "**WARN: $tag summary line failed ($msg) -> see the report files" }
}
puts "**INFO: reports written to $RPT"

#---------------------------------------------------------------------
# 8. SDF for post-layout gate-level simulation (same as the class template)
#---------------------------------------------------------------------
write_sdf -view $SETUP_VIEW ${TOP}_post_wst.sdf
write_sdf -view $HOLD_VIEW  ${TOP}_post_bst.sdf
puts "**INFO: SDF written: ${TOP}_post_wst.sdf (setup) / ${TOP}_post_bst.sdf (hold)"

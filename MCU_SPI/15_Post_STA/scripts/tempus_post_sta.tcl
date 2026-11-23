######################################################################
# tempus_post_sta.tcl - Post-route signoff STA for chip_top (Tempus 22.17)
#
# Run in the PNR directory (the .dat refers to chip_top_pnr_in.sdc and the
# PDK with the paths used by Innovus):
#   tempus -files tempus_post_sta.tcl -log tempus_post_sta.log
#   (or start tempus and:  source tempus_post_sta.tcl)
#
# Which design to analyze: DB_NAME (default ChipFinish; tempus_post_sta_eco.tcl
# sets ChipFinish_after_ECO and SDF_TAG eco before sourcing this file)
#   ChipFinish              : after 5_ChipFinish (default, no ECO flow)
#   RouteDesign             : after 4_RouteDesign (before filler)
#   ChipFinish_after_ECO    : after 6_ECO (Tempus hold ECO applied)
#
# Differences from the spi_bridge_top version
#   - design chip_top with IO pads: the .dat MMMC already holds the pad
#     timing libraries (pads_SS_s1vg.lib / pads_FF_s1vg.lib)
#   - two primary clocks ACLK (10 ns) / SCLK (40 ns), asynchronous groups
#   - pre-vs-post path is read automatically from the Genus SS report
#
# Reports -> reports/sta/<DB_NAME>/
#   00_parasitics.rpt        RC annotation coverage (must be 100 %)
#   01_check_timing.rpt      unconstrained / unclocked / missing I/O delay
#   02_coverage.rpt          analysis coverage per check type
#   10_setup_summary.rpt     setup  (FUNC_SS_WORST) worst 50 paths
#   11_setup_paths.rpt       setup  full path detail incl. clock network
#   12_setup_ACLK.rpt        setup  paths captured by ACLK
#   13_setup_SCLK.rpt        setup  paths captured by SCLK
#   14_setup_io.rpt          setup  input -> reg and reg -> output (SPI / GPIO pads)
#   20_hold_summary.rpt      hold   (FUNC_FF_BEST)
#   21_hold_paths.rpt        hold   full path detail
#   30_recovery.rpt          async reset de-assertion (setup-like, SS)
#   31_removal.rpt           async reset de-assertion (hold-like, FF)
#   40_clock_skew_*.rpt      clock skew / latency per view
#   50_drv.rpt               max transition / capacitance / fanout violators
#   60_pre_vs_post.rpt       the synthesis worst path re-timed after route
#
# SDF (for post-layout gate-level simulation, written in the PNR directory)
#   chip_top_post_wst.sdf    setup corner FUNC_SS_WORST
#   chip_top_post_bst.sdf    hold  corner FUNC_FF_BEST
######################################################################

set TOP        chip_top
if {![info exists DB_NAME]} { set DB_NAME ChipFinish }
if {![info exists SDF_TAG]} { set SDF_TAG post }
set SETUP_VIEW FUNC_SS_WORST
set HOLD_VIEW  FUNC_FF_BEST
set NPATHS     50

#---------------------------------------------------------------------
# Pre-STA worst path: taken from Path 1 of the Genus SS report.
# Set PRE_FROM / PRE_TO by hand to override, or leave empty to skip.
#---------------------------------------------------------------------
set SYN_RPT  ../SYN/report/20a_${TOP}_SYN_timing_SS.rpt
set PRE_FROM ""
set PRE_TO   ""
if {$PRE_FROM eq "" && [file exists $SYN_RPT]} {
    set fh [open $SYN_RPT r]
    while {[gets $fh line] >= 0} {
        if {$PRE_FROM eq "" && [regexp {Startpoint:\s*(\([RF]\)\s*)?(\S+)} $line -> _ sp]} { set PRE_FROM $sp }
        if {$PRE_TO   eq "" && [regexp {Endpoint:\s*(\([RF]\)\s*)?(\S+)}   $line -> _ ep]} { set PRE_TO   $ep }
        if {$PRE_FROM ne "" && $PRE_TO ne ""} { break }
    }
    close $fh
}
puts "**INFO: pre-vs-post path : from '$PRE_FROM' to '$PRE_TO'"

set RPT reports/sta/$DB_NAME
file mkdir $RPT

#---------------------------------------------------------------------
# 0. Read the routed design (netlist + MMMC + SDC + placement/routing + RC)
#---------------------------------------------------------------------
read_design ${DB_NAME}.dat $TOP

# Post-CTS: real clock tree delays, not ideal clocks
set_interactive_constraint_modes [all_constraint_modes -active]
set_propagated_clock [all_clocks]
set_interactive_constraint_modes {}

#---------------------------------------------------------------------
# 1. Inputs are complete?
#---------------------------------------------------------------------
report_annotated_parasitics          > $RPT/00_parasitics.rpt
check_timing -verbose                > $RPT/01_check_timing.rpt
report_analysis_coverage             > $RPT/02_coverage.rpt

#---------------------------------------------------------------------
# 2. Setup at the slow corner
#---------------------------------------------------------------------
report_timing -late -view $SETUP_VIEW -max_paths $NPATHS -path_type summary    > $RPT/10_setup_summary.rpt
report_timing -late -view $SETUP_VIEW -max_paths 10 -path_type full_clock -net > $RPT/11_setup_paths.rpt
catch {report_timing -late -view $SETUP_VIEW -to [get_clocks ACLK] -max_paths 10 -path_type full_clock > $RPT/12_setup_ACLK.rpt}
catch {report_timing -late -view $SETUP_VIEW -to [get_clocks SCLK] -max_paths 10 -path_type full_clock > $RPT/13_setup_SCLK.rpt}
catch {
    report_timing -late -view $SETUP_VIEW -from [all_inputs]  -max_paths 10 -path_type full_clock  > $RPT/14_setup_io.rpt
    report_timing -late -view $SETUP_VIEW -to   [all_outputs] -max_paths 10 -path_type full_clock >> $RPT/14_setup_io.rpt
}

#---------------------------------------------------------------------
# 3. Hold at the fast corner
#---------------------------------------------------------------------
report_timing -early -view $HOLD_VIEW -max_paths $NPATHS -path_type summary    > $RPT/20_hold_summary.rpt
report_timing -early -view $HOLD_VIEW -max_paths 10 -path_type full_clock -net > $RPT/21_hold_paths.rpt

#---------------------------------------------------------------------
# 4. Recovery / removal : reset_sync outputs -> async clear pins of the flops
#    (ARESETn itself is a false path in the SDC; the synchronized resets
#     u_reset_sync_core / u_spi/u_reset_sync_aclk / _sclk are real clocked
#     paths and must meet recovery/removal)
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
    if {[catch {report_timing -late -view $SETUP_VIEW -from $PRE_FROM -to $PRE_TO \
                    -path_type full_clock -net > $RPT/60_pre_vs_post.rpt} msg]} {
        puts "**WARN: pre-vs-post path not found in the PnR netlist ($msg)"
    }
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
foreach {tag chk view} [list recovery recovery $SETUP_VIEW removal removal $HOLD_VIEW] {
    if {[catch {
        set p [report_timing -check_type $chk -view $view -max_paths 1 -collection]
        puts [format "**RESULT: %-8s %-14s WNS = %s ns" $tag $view [get_property $p slack]]
    } msg]} { puts "**WARN: $tag summary line failed ($msg)" }
}
puts "**INFO: reports written to $RPT"

#---------------------------------------------------------------------
# 8. SDF for post-layout gate-level simulation (Tempus = signoff SDF)
#---------------------------------------------------------------------
write_sdf -view $SETUP_VIEW ${TOP}_${SDF_TAG}_wst.sdf
write_sdf -view $HOLD_VIEW  ${TOP}_${SDF_TAG}_bst.sdf
puts "**INFO: SDF written: ${TOP}_${SDF_TAG}_wst.sdf (setup) / ${TOP}_${SDF_TAG}_bst.sdf (hold)"

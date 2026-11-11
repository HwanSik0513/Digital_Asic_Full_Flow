######################################################################
# tempus_spef_sta.tcl - Tempus STA from netlist + SDC + SPEF (no Innovus DB)
#   Run in the PNR directory after spef_out.tcl:
#     tempus -files tempus_spef_sta.tcl -log tempus_spef_sta.log
#   Reads the PnR MMMC + CTS latency files (tempus_spef.view), the flat PnR netlist,
#   and one SPEF per RC corner. Analysis type single, as in the PnR run. Expected: setup +7.716 / hold +0.002 ns
#   (same as Innovus and the Tempus run on RouteDesign.dat).
######################################################################
set TOP spi_bridge_top
set RPT reports/tempus_spef
file mkdir $RPT

read_view_definition tempus_spef.view
read_verilog         spi_bridge_top_pnr.v
set_top_module       $TOP

# same analysis setting as the PnR run (4_RouteDesign: setAnalysisMode -analysisType single)
setAnalysisMode -analysisType single

read_spef -rc_corner WORST spi_bridge_top_worst.spef
read_spef -rc_corner BEST  spi_bridge_top_best.spef
# MMMC: SDC-type commands typed in the script must name the constraint mode(s) they apply to
set_interactive_constraint_modes [all_constraint_modes -active]
set_propagated_clock [all_clocks]
set_interactive_constraint_modes {}

report_annotated_parasitics -list_not_annotated                               > $RPT/00_parasitics.rpt
check_timing -verbose                                                         > $RPT/01_check_timing.rpt
report_timing -late  -view FUNC_SS_WORST -max_paths 20 -path_type summary     > $RPT/10_setup_summary.rpt
report_timing -late  -view FUNC_SS_WORST -max_paths 3  -path_type full_clock -net > $RPT/11_setup_paths.rpt
report_timing -early -view FUNC_FF_BEST  -max_paths 20 -path_type summary     > $RPT/20_hold_summary.rpt
report_timing -early -view FUNC_FF_BEST  -max_paths 3  -path_type full_clock -net > $RPT/21_hold_paths.rpt
report_analysis_coverage                                                      > $RPT/02_coverage.rpt
puts "**INFO: Tempus SPEF-based STA reports written to $RPT"

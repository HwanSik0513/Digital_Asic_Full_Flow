######################################################################
# tempus_pre_sta.tcl - Pre-layout STA (Tempus, legacy mode) on the synthesized netlist
#   Put tempus_pre.view and this file in the SYN directory, then:
#     tempus -files tempus_pre_sta.tcl -log log/tempus_pre_sta.log
#   (or start tempus in SYN and type: source tempus_pre_sta.tcl)
#
#   Ideal clocks (no CTS), no parasitics (no SPEF) -> setup is the meaningful check.
#   Hold here is reference only (zero skew; hold is fixed after CTS in PnR).
######################################################################
set TOP spi_bridge_top
set RPT reports/tempus_pre
file mkdir $RPT

read_view_definition tempus_pre.view
read_verilog         mapped/spi_bridge_top_syn_final.v
set_top_module       $TOP

check_timing -verbose                                                        > $RPT/01_check_timing.rpt
report_analysis_coverage                                                     > $RPT/02_coverage.rpt
report_clocks                                                                > $RPT/03_clocks.rpt
report_timing -late  -view FUNC_SS_WORST -max_paths 50 -path_type summary    > $RPT/10_setup_summary.rpt
report_timing -late  -view FUNC_SS_WORST -max_paths 10 -path_type full_clock -net > $RPT/11_setup_paths.rpt
report_timing -late  -view FUNC_SS_WORST -from u_rx_fifo/r_wr_ptr_gray_rclk_reg_4/CK -to {o_bus_rdata[4]} -path_type full_clock -net > $RPT/12_setup_same_path_as_genus.rpt
report_timing -early -view FUNC_FF_BEST  -max_paths 20 -path_type summary    > $RPT/20_hold_reference.rpt
report_constraint -all_violators                                             > $RPT/30_drv.rpt

puts "**INFO: Tempus Pre-STA reports written to $RPT"

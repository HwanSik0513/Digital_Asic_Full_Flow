########################################
# 3. CTS & Optimization - chip_top
#   Clocks (from SDC): ACLK 10 ns (100 MHz) and SCLK 40 ns (25 MHz), both
#   PRIMARY clocks entering through PADDI pads (u_pad_aclk / u_pad_sclk),
#   asynchronous to each other (set_clock_groups). CCOpt builds two
#   independent trees from the pad outputs; ACLK is the large one
#   (CPU, regfile, RAM, ~2,200 sinks), SCLK only drives the SPI slave side.
########################################


file mkdir reports/timing reports/clock

# Target skew [ns]
set_ccopt_property target_skew 0.01

## Sanity check: the PnR SDC (chip_top_pnr_in.sdc) has no set_ideal_network,
## so CCOpt may buffer ACLK / SCLK. Dont-touch nets on the clock path are listed.
puts "**INFO: dont_touch nets = [dbGet -e [dbGet -p top.nets.dontTouch 1].name]"

create_ccopt_clock_tree_spec
# CTS and report all timing WNS, TNS results
ccopt_design


## [CAPTURE] ------------------------------------------------
source capture.tcl
snap 03a_cts place
## -----------------------------------------------------------

# Propagated Clock
set_interactive_constraint_modes [all_constraint_modes -active] ;# mode FUNC (check: all_constraint_modes)
set_propagated_clock [all_clocks]

# Check right-after CTS
timeDesign -postCTS -outDir reports/timing/postCTS
report_ccopt_clock_trees -file reports/clock/clock_trees.rpt
report_ccopt_skew_groups -file reports/clock/skew_groups.rpt
report_clock_timing -type skew -nworst 5 > reports/clock/skew.rpt
puts "**INFO: clock buffers/inverters inserted = [llength [dbGet -e [dbGet -p top.insts.name *CTS*].name]]"

# Optimization of my design after CTS
optDesign -postCTS          ;# Setup/DRV concurrently
optDesign -postCTS -hold    ;# Only for hold violation
timeDesign -postCTS -outDir reports/timing/postCTS_opt


## [CAPTURE] ------------------------------------------------
snap 03b_postcts_opt place
# Clock tree view: open Clock -> CCOpt Clock Tree Debugger in the GUI and screenshot it manually
## -----------------------------------------------------------
# If there is no error, Save Design  (-> PostCTSopt.dat/)
saveDesign -def PostCTSopt




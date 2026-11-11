########################################
# 3. CTS & Optimization - spi_bridge_top
#   Clocks (from SDC): ACLK 10 ns (100 MHz) + SCLK generated clock (ACLK / 4, from sclk_gen)
#   CCOpt builds the ACLK tree and traces through sclk_gen to build the SCLK tree.
########################################


file mkdir reports/timing reports/clock

# Target skew [ns]
set_ccopt_property target_skew 0.01

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




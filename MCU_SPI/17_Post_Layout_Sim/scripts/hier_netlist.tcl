######################################################################
# hier_netlist.tcl - hierarchical netlist of ChipFinish for post-layout GLS
#   Run in the PNR directory, in a NEW Innovus session:
#     innovus -files hier_netlist.tcl -log hier_netlist.log
#   Why: the Tempus SDF names instances hierarchically (u_core/u_cpu/...,
#   divider '/'), which matches a hierarchical netlist. The flat netlist
#   chip_top_pnr.v has escaped names (\u_core/u_cpu/... ) that the SDF
#   annotator cannot find.
######################################################################
#restoreDesign ChipFinish.dat chip_top
saveNetlist chip_top_pnr_hier.v
puts "**INFO: chip_top_pnr_hier.v written"
puts "**INFO: modules in netlist = [exec grep -c {^module } chip_top_pnr_hier.v]"
exit

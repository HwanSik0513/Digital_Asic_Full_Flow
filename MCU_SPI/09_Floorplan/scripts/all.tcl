########################################################################
## all.tcl - full PnR flow for chip_top (legacy Innovus)
##   prerequisite: ./make_pnr_netlist.sh  (creates chip_top_pnr_in.v)
##   run         : innovus -files all.tcl -log innovus.log
## Stages can also be run one by one; each stage saves its own database.
########################################################################
source 0_InitDesign.tcl
source 1_PowerPlan.tcl
source 2_PlaceOpt.tcl
source 3_PostCTSopt.tcl
source 4_RouteDesign_PowerAnalysis.tcl
source 5_ChipFinish.tcl

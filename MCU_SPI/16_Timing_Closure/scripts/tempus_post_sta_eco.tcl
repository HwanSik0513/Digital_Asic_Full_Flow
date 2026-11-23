######################################################################
# tempus_post_sta_eco.tcl - Post-ECO signoff STA for chip_top (Tempus 22.17)
#   Only needed when tempus_hold_eco.tcl + 6_ECO.tcl were run.
#   Run in the PNR directory:
#     tempus -files tempus_post_sta_eco.tcl -log tempus_post_sta_eco.log
#   Same checks as tempus_post_sta.tcl on ChipFinish_after_ECO.dat
#   Reports -> reports/sta/ChipFinish_after_ECO/
#   SDF     -> chip_top_eco_wst.sdf (setup) / chip_top_eco_bst.sdf (hold)
######################################################################
set DB_NAME ChipFinish_after_ECO
set SDF_TAG eco
source tempus_post_sta.tcl

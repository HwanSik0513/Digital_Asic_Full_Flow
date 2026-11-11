###############
#### 6. ECO - spi_bridge_top
####   Input : innovus.eco (written by Tempus: write_eco -format innovus -output innovus.eco)
###############
restoreDesign RouteDesign.dat spi_bridge_top
source bufx2_guard.tcl          ;# new session: setDontUse BUFX2 again (not kept in .dat)
file mkdir reports/timing

# Apply the Tempus ECO (netlist change + placement of the new buffers)
source innovus.eco
# Legalize the new buffers and route their nets (the ECO file does not route)
refinePlace
ecoRoute


## [CAPTURE] ------------------------------------------------
source capture.tcl
snap 06a_eco_inserted place
## -----------------------------------------------------------

# After inserting repeater cells:
# Ctrl+F -> Auto Zoom ON -> find the ECO buffers (CLKBUFX2 added by Tempus)

# RC Extraction
extractRC

# Timing check right-after ECO routing  (= result of the Tempus ECO only)
timeDesign -postRoute       -outDir reports/timing/eco
timeDesign -postRoute -hold -outDir reports/timing/eco_hold

# Innovus re-optimization is OFF so the result shows the Tempus ECO alone.
# Enable only if eco / eco_hold above still show violations.
#setAnalysisMode -analysisType single -checkType setup
#optDesign -postRoute -setup
#setAnalysisMode -analysisType single -checkType hold
#optDesign -postRoute -hold

# Timing check after optimization
timeDesign -postRoute       -outDir reports/timing/eco_opt
timeDesign -postRoute -hold -outDir reports/timing/eco_opt_hold

# DRC again
set_verify_drc_mode -disable_rules {} -check_ndr_spacing auto -check_only default -check_same_via_cell true -exclude_pg_net false -ignore_trial_route false -ignore_cell_blockage false -use_min_spacing_on_block_obs auto -report spi_bridge_top_eco.drc.rpt -limit 1000
verify_drc
set_verify_drc_mode -area {0 0 0 0}

# LVS : Connectivity
verifyConnectivity -type all -geomConnect -error 1000 -warning 50

# Violation Browser
setLayerPreference violation -isVisible 1
violationBrowser -all -no_display_false -displayByLayer

######################################################################
# Save Design for Tempus
######################################################################
extractRC
saveDesign -rc -def RouteDesign_ECO_mmmc1

#######################
#### Chip Finish ######
#######################
getFillerMode -quiet
addFiller -cell FILL64 FILL32 FILL16 FILL8 FILL4 FILL2 FILL1 -prefix FILLER
extractRC

# Final checks with fillers in place
checkPlace
verify_drc -report spi_bridge_top_eco_final.drc.rpt -limit 1000
verifyConnectivity -type all -geomConnect -error 1000 -warning 50

## [CAPTURE] ------------------------------------------------
snap 06b_chipfinish_eco place
## -----------------------------------------------------------
saveDesign -rc -def ChipFinish_after_ECO

#####################
#### Write Out ######
#####################
streamOut spi_bridge_top_eco.gds -libName DesignLib -units 2000 -mode ALL
writeTimingCon spi_bridge_top_eco.sdc
saveNetlist -flat spi_bridge_top_eco.v
saveNetlist -flat -includePowerGround spi_bridge_top_eco_pg.v
write_sdf spi_bridge_top_eco.sdf
write_sdf -version 2.1 spi_bridge_top_eco.sdf_2.1

exit


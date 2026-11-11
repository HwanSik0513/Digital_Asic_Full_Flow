#######################
#### 5. Chip Finish - spi_bridge_top
#######################


# Add Filler
getFillerMode -quiet
addFiller -cell FILL64 FILL32 FILL16 FILL8 FILL4 FILL2 FILL1 -prefix FILLER
extractRC


## [CAPTURE] ------------------------------------------------
source capture.tcl
snap 05_chipfinish place
## -----------------------------------------------------------

# Final checks after filler insertion
verify_drc -report spi_bridge_top_final.drc.rpt -limit 1000
verifyConnectivity -type all -geomConnect -error 1000 -warning 50

# If there is no error, save Design
saveDesign -rc -def ChipFinish

#####################
#### Write Out ######
#####################
# GDS file : without layermap file for GPDK045 (same as template)
streamOut spi_bridge_top.gds -libName DesignLib -units 2000 -mode ALL

# Constraint
writeTimingCon spi_bridge_top_pnr.sdc

# Netlist : -flat for next tool stages (no IO pad cells in this block -> no -excludeCellInst)
saveNetlist -flat spi_bridge_top_pnr.v

# Netlist with VDD/VSS connections (for LVS)
saveNetlist -flat -includePowerGround spi_bridge_top_pnr_pg.v

# SDF 3.0 (RECREM included) / SDF 2.1  (Tempus SDF recommended for signoff)
write_sdf spi_bridge_top.sdf
write_sdf -version 2.1 spi_bridge_top.sdf_2.1




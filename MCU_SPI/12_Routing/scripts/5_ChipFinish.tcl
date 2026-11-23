#######################
#### 5. Chip Finish - chip_top
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
verify_drc -report chip_top_final.drc.rpt -limit 1000
verifyConnectivity -type all -geomConnect -error 1000 -warning 50

# If there is no error, save Design
saveDesign -rc -def ChipFinish

#####################
#### Write Out ######
#####################
# GDS file : without layermap file for GPDK045 (same as template)
streamOut chip_top.gds -libName DesignLib -units 2000 -mode ALL

# Constraint
writeTimingCon chip_top_pnr.sdc

# Netlist : -flat for next tool stages. IO pad cells are kept (GLS uses the pad models).
# IO ring fillers / corners are physical-only and are not written.
saveNetlist -flat chip_top_pnr.v

# Netlist with VDD/VSS connections (for LVS)
saveNetlist -flat -includePowerGround chip_top_pnr_pg.v

# SDF 3.0 (RECREM included) / SDF 2.1  (Tempus SDF recommended for signoff)
write_sdf -view FUNC_SS_WORST chip_top_wc.sdf
write_sdf -view FUNC_FF_BEST  chip_top_bc.sdf
write_sdf -view FUNC_SS_WORST -version 2.1 chip_top_wc.sdf_2.1
write_sdf -view FUNC_FF_BEST  -version 2.1 chip_top_bc.sdf_2.1




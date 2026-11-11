######################################
## 2. Placement & Optimization - spi_bridge_top
######################################

file mkdir reports/timing

set_db place_global_cong_effort high

# First placement
place_design

## [CAPTURE] ------------------------------------------------
source capture.tcl
snap 02a_place_initial place
## -----------------------------------------------------------


# Check the Placement Density
checkPlace spi_bridge_top.checkPlace

# Early GlobalRoute :: analysis of Congestion and Timing after Placement
setRouteMode -earlyGlobalMinRouteLayer 1 -earlyGlobalMaxRouteLayer 11 -earlyGlobalHonorMsvRouteConstraint false -earlyGlobalRoutePartitionPinGuide true
earlyGlobalRoute
reportCongestion -hotSpot
reportCongestion -overflow

# View Density Map
setDrawView place
setLayerPreference densityMap -isVisible 1

## [CAPTURE] ------------------------------------------------
snap 02b_density_map place
## -----------------------------------------------------------

setLayerPreference densityMap -isVisible 0

## View Pin Density Map
setLayerPreference pinDensityMap -isVisible 1

## [CAPTURE] ------------------------------------------------
snap 02c_pin_density_map place
## -----------------------------------------------------------

setLayerPreference pinDensityMap -isVisible 0

# Placement Optimization
place_opt_design

# Tie cells for constant nets (1'b0/1'b1) left by synthesis, if any
addTieHiLo -cell {TIEHI TIELO} -prefix LTIE

# Early GlobalRoute :: analysis of Congestion and Timing after Placement
earlyGlobalRoute
reportCongestion -hotSpot
reportCongestion -overflow

# Timing summary
timeDesign -preCTS -outDir reports/timing/preCTS

# checkDesign :: Density
checkDesign -place


## [CAPTURE] ------------------------------------------------
snap 02d_place_opt place
snap 02e_amoeba ameba
## -----------------------------------------------------------
# If there is no error, Save Design  (-> PlaceOpt.dat/)
saveDesign -def PlaceOpt




########################################
# 0. InitDesign (Setup, Floorplan) - spi_bridge_top (core-only block, no IO pads)
########################################

## Initialization
set init_gnd_net    VSS
set init_pwr_net    VDD
set init_lef_file   {../../../GPDK045/digital/gsclib045_all_v4.4/gsclib045_tech/lef/gsclib045_tech.lef \
                     ../../../GPDK045/digital/gsclib045_all_v4.4/gsclib045/lef/gsclib045_macro.lef \
                     ../../../GPDK045/digital/gsclib045_all_v4.4/gsclib045/lef/gsclib045_multibitsDFF.lef}
set init_verilog    ../SYN/mapped/spi_bridge_top_syn_final.v
set init_mmmc_file  spi_bridge_top.mmmc.tcl
set init_top_cell   spi_bridge_top
init_design

## Global P/G connection (std cell VDD/VSS pins + tie cells)
globalNetConnect VDD -type pgpin -pin VDD -inst * -override
globalNetConnect VSS -type pgpin -pin VSS -inst * -override
globalNetConnect VDD -type tiehi
globalNetConnect VSS -type tielo

## Check Design
checkDesign -netlist -physicalLibrary -powerGround -tieHilo -timingLibrary -floorplan -outdir checkDesign

##################################################
## Floorplan : aspect 1.0, core util 0.7, core-to-die margin 10um
##   -> Die {0 0 91.6 90.25}, Core {10.0 10.07 81.6 80.18}
##################################################
floorPlan -site CoreSite -r 1.0 0.7 10 10 10 10

## Pin placement
##   Left  : i_bus_* (18)      Right : o_* (14)      Top : ACLK, ARESETn
setPinAssignMode -pinEditInBatch true
editPin -side Left   -layer M3 -spreadType center -spacing 2 -unit MICRON -fixOverlap 1 \
        -pin [dbGet top.terms.name i_*]
editPin -side Right  -layer M3 -spreadType center -spacing 2 -unit MICRON -fixOverlap 1 \
        -pin [dbGet top.terms.name o_*]
editPin -side Top    -layer M4 -spreadType center -spacing 4 -unit MICRON -fixOverlap 1 \
        -pin {ACLK ARESETn}
setPinAssignMode -pinEditInBatch false


## [CAPTURE] ------------------------------------------------
source capture.tcl
snap 00_floorplan fplan
## -----------------------------------------------------------
## If there is no error, Save Design  (-> InitDesign + InitDesign.dat/ + DEF)
saveDesign -def InitDesign




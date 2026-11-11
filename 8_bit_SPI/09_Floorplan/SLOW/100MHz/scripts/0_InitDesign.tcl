########################################
# 0. InitDesign (Setup, Floorplan) - spi_bridge_top (core-only block, no IO pads)
########################################
#-----------------------------------------------------------------------------
# Split from all.tcl (the script actually run). Stages 0 -> 5 run in ONE Innovus
# session in order (all.tcl), so stages 1-5 have no restoreDesign / exit.
# To run one stage alone, add:  restoreDesign <prev>.dat spi_bridge_top
# Clock period comes from ../SYN/mapped/spi_bridge_top_syn_final.sdc (no edit per frequency).
#-----------------------------------------------------------------------------

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

## BUFX2 guard  (fixes IMPSP-365 / "TechSite Violation")
##   BUFX2 has SITE 'CoreSiteDouble' in the LEF, but the floorplan only has CoreSite rows,
##   so every BUFX2 the optimizer inserts is placed illegally.
##   (1) keep the optimizer away from BUFX2. setDontUse needs ONE cell per call:
##       passing a Tcl list is taken as a single (non-existent) cell name -> IMPOPT-3593, no effect.
foreach c {BUFX2} { setDontUse $c true }
puts "**INFO: setDontUse BUFX2 -> dontUse = [dbGet [dbGet -p head.allCells.name BUFX2].dontUse]"

##   (2) safety net: count BUFX2 instances; mode "swap" resizes any leftover to BUFX3 (CoreSite) and legalizes.
##       Call it only while the design is not routed yet; after routing use mode "report".
proc fix_bufx2 {tag {mode swap}} {
    set insts [dbGet -e [dbGet -p2 top.insts.cell.name BUFX2].name]
    if {$insts eq "0x0" || [llength $insts] == 0} {
        puts "**INFO: \[BUFX2 guard: $tag\] BUFX2 instances = 0"
        return
    }
    puts "**INFO: \[BUFX2 guard: $tag\] BUFX2 instances = [llength $insts]"
    if {$mode eq "swap"} {
        foreach i $insts { ecoChangeCell -inst $i -cell BUFX3 }
        refinePlace
        set left [dbGet -e [dbGet -p2 top.insts.cell.name BUFX2].name]
        if {$left eq "0x0"} { set left {} }
        puts "**INFO: \[BUFX2 guard: $tag\] after swap to BUFX3: BUFX2 instances = [llength $left]"
    }
}

## Check Design
checkDesign -netlist -physicalLibrary -powerGround -tieHilo -timingLibrary -floorplan -outdir checkDesign

##################################################
## Floorplan : aspect 1.0, core util 0.7, core-to-die margin 10um
##   -> die/core size depends on the netlist area (see 08_Floorplan README)
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

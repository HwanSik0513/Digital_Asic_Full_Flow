########################################
# 0. InitDesign (Setup, Floorplan, IO ring) - chip_top (MIPS MCU, with IO pads)
#
# Run with LEGACY Innovus (not -stylus): see README - the stylus mode could
# not place the giolib045 corner / pad cells from the IO file.
#
# Input netlist: chip_top_pnr_in.v  (= synthesis netlist + 6 supply pads)
#   -> run ./make_pnr_netlist.sh first
########################################

if {![info exists GPDK_ROOT]} { set GPDK_ROOT "/home/hah003/PROJ1/GPDK045/digital" }
set GSC "$GPDK_ROOT/gsclib045_all_v4.4"
set GIO "$GPDK_ROOT/giolib045_v3.5"

## Initialization
##   Two supply domains on the chip:
##     VDD / VSS       : core (std cells + core side of the pads)
##     VDDIOR / VSSIOR : IO ring (pad drivers), connected by pad abutment
set init_pwr_net    {VDD VDDIOR}
set init_gnd_net    {VSS VSSIOR}
set init_lef_file   [list $GSC/gsclib045_tech/lef/gsclib045_tech.lef \
                          $GSC/gsclib045/lef/gsclib045_macro.lef \
                          $GSC/gsclib045/lef/gsclib045_multibitsDFF.lef \
                          $GIO/lef/giolib045.lef]
if {![file exists chip_top_pnr_in.v] || ![file exists chip_top_pnr_in.sdc]} {
    puts "**INFO: PnR netlist / SDC not found -> running make_pnr_netlist.sh"
    puts [exec bash make_pnr_netlist.sh]
}
set init_verilog    chip_top_pnr_in.v
set init_mmmc_file  chip_top.mmmc.view
set init_top_cell   chip_top
set init_io_file    chip_top.io
init_design

## Global P/G connection
##   std cells + pads : VDD / VSS / VDDIOR / VSSIOR pins
##   No IO fillers: pads and corners abut (die 780 = 240 + 5 x 60 + 240).
##   (padIORINGFEED* declare their IO-ring pins VDDPAD25/VSSPAD as SIGNAL,
##    so they cannot join VDDIOR/VSSIOR; attachTerm on them crashes Innovus.)
##                      -> same nets as the pads' VDDIOR / VSSIOR
globalNetConnect VDD    -type pgpin -pin VDD      -inst * -override
globalNetConnect VSS    -type pgpin -pin VSS      -inst * -override
globalNetConnect VDDIOR -type pgpin -pin VDDIOR   -inst * -override
globalNetConnect VSSIOR -type pgpin -pin VSSIOR   -inst * -override
globalNetConnect VDD    -type tiehi
globalNetConnect VSS    -type tielo

## BUFX2 guard (same as the previous project: IMPSP-365 / TechSite violation)
##   BUFX2 uses SITE CoreSiteDouble, the rows are CoreSite only.
foreach c {BUFX2} { setDontUse $c true }
puts "**INFO: setDontUse BUFX2 -> dontUse = [dbGet [dbGet -p head.allCells.name BUFX2].dontUse]"

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
## Floorplan (pad-limited)
##   Die 780 x 780 um (pads abut, no IO fillers). Pads 60 x 240 um, corners 240 x 240 um, 5 pads / side.
##   Core box 270..510 um on both axes -> 240 x 240 um = 57,600 um2
##     synthesis cell area 26,984 um2 -> ~47 % core utilization
##   Core-to-die 270 um = pad height 240 + 30 um for the core ring
##################################################
floorPlan -coreMarginsBy die -site CoreSite -d 780 780 270 270 270 270

## The IO file (init_io_file) placed the pads and created the corners.
## Re-load it explicitly in case the floorplan command moved them.
loadIoFile chip_top.io

## Global net connections again after the IO file (pads / corners)
globalNetConnect VDD    -type pgpin -pin VDD    -inst * -override
globalNetConnect VSS    -type pgpin -pin VSS    -inst * -override
globalNetConnect VDDIOR -type pgpin -pin VDDIOR -inst * -override
globalNetConnect VSSIOR -type pgpin -pin VSSIOR -inst * -override

## Report pad placement (sanity check: 20 pads + 4 corners)
puts "**INFO: pads    = [llength [dbGet -e [dbGet -p2 top.insts.cell.name PAD*].name]] (expect 20)"
puts "**INFO: corners = [llength [dbGet -e [dbGet -p2 top.insts.cell.name padIORINGCORNER].name]] (expect 4)"
puts "**INFO: dieBox  = [dbGet top.fPlan.box] (expect about {0 0 780 780})"
puts "**INFO: coreBox = [dbGet top.fPlan.coreBox] (expect about {270 270 510 510})"
puts "**INFO: rows    = [llength [dbGet -e top.fPlan.rows]]"

## [CAPTURE] ------------------------------------------------
source capture.tcl
snap 00_floorplan fplan
## -----------------------------------------------------------
## If there is no error, Save Design  (-> InitDesign + InitDesign.dat/ + DEF)
saveDesign -def InitDesign

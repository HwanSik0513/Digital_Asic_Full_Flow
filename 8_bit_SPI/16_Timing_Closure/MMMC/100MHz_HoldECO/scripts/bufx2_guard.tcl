########################################
# bufx2_guard.tcl - BUFX2 guard for spi_bridge_top PnR
#   source this right after init_design (stage 0) or right after
#   restoreDesign (stages 1-6 run in a new Innovus session).
#   setDontUse is NOT kept across restoreDesign, so it must be set again
#   in every new session (seen: 13 BUFX2 TechSite violations after route).
########################################
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

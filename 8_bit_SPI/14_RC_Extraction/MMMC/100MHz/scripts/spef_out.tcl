#----------------------------------------------------------------------
# spef_out.tcl - write SPEF per RC corner from the routed design (Innovus)
#   Run in the PNR directory, in a NEW Innovus session:
#     innovus -files spef_out.tcl -log spef_out.log
#   Calls extractRC with the mode restored from RouteDesign (same as the PnR run),
#   so the SPEF matches the timing already reported (setup +7.716 / hold +0.002 ns).
#   Quantus is not available -> Innovus integrated extractor.
#----------------------------------------------------------------------
restoreDesign RouteDesign.dat spi_bridge_top

extractRC

rcOut -spef spi_bridge_top_worst.spef -rc_corner WORST
rcOut -spef spi_bridge_top_best.spef  -rc_corner BEST

# sanity check: same numbers as the PnR run
file mkdir reports/spef
timeDesign -postRoute       -outDir reports/spef/setup
timeDesign -postRoute -hold -outDir reports/spef/hold
puts "**INFO: SPEF written: spi_bridge_top_worst.spef / spi_bridge_top_best.spef"
exit

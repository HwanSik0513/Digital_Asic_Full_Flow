########################################
# 1. PowerPlan - spi_bridge_top (core-only block)
#   Core-to-die margin 10 um (die/core size depends on the netlist, see 08_Floorplan README)
#   PDN  : core ring (M10/M11) + M1 follow-pin rails + M10 vertical stripes
#   Removed from template: outer ring (offset 1000), pad sroute, inner-outer stripes (no IO pads)
########################################
#-----------------------------------------------------------------------------
# Split from all.tcl (the script actually run). Stages 0 -> 5 run in ONE Innovus
# session in order (all.tcl), so stages 1-5 have no restoreDesign / exit.
# To run one stage alone, add:  restoreDesign <prev>.dat spi_bridge_top
# Clock period comes from ../SYN/mapped/spi_bridge_top_syn_final.sdc (no edit per frequency).
#-----------------------------------------------------------------------------
# restoreDesign InitDesign.dat spi_bridge_top   ;# only when running this stage alone

## Global Net Connection
globalNetConnect VDD -type pgpin -pin VDD -instanceBasename *
globalNetConnect VSS -type pgpin -pin VSS -instanceBasename *
globalNetConnect VDD -type tiehi -instanceBasename *
globalNetConnect VSS -type tielo -instanceBasename *
setTieHiLoMode -reset
setTieHiLoMode -cell { TIELO TIEHI } -honorDontTouch false -createHierPort false

## Core Ring
##   Footprint = offset 1 + width 2 + spacing 1 + width 2 = 6 um  (< 10 um core-to-die margin)
setAddRingMode -ring_target default -extend_over_row 0 -ignore_rows 0 -avoid_short 0 -skip_crossing_trunks none -stacked_via_top_layer Metal11 -stacked_via_bottom_layer Metal1 -via_using_exact_crossover_size 1 -orthogonal_only true -skip_via_on_pin { standardcell } -skip_via_on_wire_shape { noshape }

addRing -nets {VDD VSS} -type core_rings -follow core \
  -layer   {top Metal11 bottom Metal11 left Metal10 right Metal10} \
  -width   {top 2 bottom 2 left 2 right 2} \
  -spacing {top 1 bottom 1 left 1 right 1} \
  -offset  {top 1 bottom 1 left 1 right 1} \
  -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None

## Std-cell power rails (Metal1 follow-pins) -> connect to core ring
setSrouteMode -viaConnectToShape { noshape }

sroute -connect { corePin } -layerChangeRange { Metal1(1) Metal11(11) } -blockPinTarget { nearestTarget } -corePinTarget { firstAfterRowEnd } -allowJogging 1 -crossoverViaLayerRange { Metal1(1) Metal11(11) } -nets { VDD VSS } -allowLayerChange 1 -targetViaLayerRange { Metal1(1) Metal11(11) }

## Vertical Stripes in Core Area
##   4 sets of {VDD VSS}, width 1 / spacing 1.25,
##   8 um from each core edge -> Innovus distributes sets evenly (~17-18 um pitch)
##   (template: width 5 / spacing 5 / set_to_set 100 -> 0 or 1 stripe in a ~70 um core)
setAddStripeMode -ignore_block_check false -break_at none -route_over_rows_only false -rows_without_stripes_only false -extend_to_closest_target none -stop_at_last_wire_for_area false -partial_set_thru_domain false -ignore_nondefault_domains false -trim_antenna_back_to_shape none -spacing_type edge_to_edge -spacing_from_block 0 -stripe_min_length stripe_width -stacked_via_top_layer Metal11 -stacked_via_bottom_layer Metal1 -via_using_exact_crossover_size false -split_vias false -orthogonal_only true -allow_jog { padcore_ring block_ring } -skip_via_on_pin { standardcell } -skip_via_on_wire_shape { noshape }

addStripe -nets {VDD VSS} -layer Metal10 -direction vertical \
  -width 1 -spacing 1.25 -number_of_sets 4 \
  -start_from left -start_offset 8 -stop_offset 8 \
  -switch_layer_over_obs false -max_same_layer_jog_length 2 \
  -padcore_ring_top_layer_limit Metal11 -padcore_ring_bottom_layer_limit Metal1 \
  -block_ring_top_layer_limit Metal11 -block_ring_bottom_layer_limit Metal1 \
  -use_wire_group 0 -snap_wire_center_to_grid None

## [CAPTURE] ------------------------------------------------
source capture.tcl
snap 01_powerplan fplan
## -----------------------------------------------------------
## verifyConnectivity - only soft PG connect (signal nets are not routed yet)
verifyConnectivity -type all -noOpen -noAntenna -noWeakConnect -noUnConnPin -noUnroutedNet -error 1000 -warning 50

## If there is no error, Save Design  (-> PowerPlan + PowerPlan.dat/)
saveDesign -def PowerPlan

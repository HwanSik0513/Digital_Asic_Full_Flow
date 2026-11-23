########################################
# 1. PowerPlan - chip_top (with IO pads)
#   Die  : 780 x 780 um,  Core : {270 270 510 510} (240 x 240 um)
#   PDN  :
#     IO ring (VDDIOR / VSSIOR, and VDD / VSS rails inside the pads)
#           -> continuous by pad abutment + IO fillers (0_InitDesign)
#     Core ring VDD / VSS (M10 / M11) in the 30 um between pads and core
#     Pad ring rails (sroute padRing) + PADVDD/PADVSS pins -> core ring (pad_connect.tcl)   [new vs. block flow]
#     Std-cell follow-pin rails (M1)      (sroute corePin)
#     M10 vertical stripes over the core
########################################

## Global Net Connection (re-applied after any instance change)
globalNetConnect VDD    -type pgpin -pin VDD      -instanceBasename *
globalNetConnect VSS    -type pgpin -pin VSS      -instanceBasename *
globalNetConnect VDDIOR -type pgpin -pin VDDIOR   -instanceBasename *
globalNetConnect VSSIOR -type pgpin -pin VSSIOR   -instanceBasename *
globalNetConnect VDD    -type tiehi -instanceBasename *
globalNetConnect VSS    -type tielo -instanceBasename *
setTieHiLoMode -reset
setTieHiLoMode -cell { TIELO TIEHI } -honorDontTouch false -createHierPort false

## Core Ring
##   Footprint = offset 2 + width 5 + spacing 2 + width 5 = 14 um
##   (pad inner edge at 240 um, core edge at 270 um -> 16 um clearance)
setAddRingMode -ring_target default -extend_over_row 0 -ignore_rows 0 -avoid_short 0 -skip_crossing_trunks none -stacked_via_top_layer Metal11 -stacked_via_bottom_layer Metal1 -via_using_exact_crossover_size 1 -orthogonal_only true -skip_via_on_pin { standardcell } -skip_via_on_wire_shape { noshape }

addRing -nets {VDD VSS} -type core_rings -follow core \
  -layer   {top Metal11 bottom Metal11 left Metal10 right Metal10} \
  -width   {top 5 bottom 5 left 5 right 5} \
  -spacing {top 2 bottom 2 left 2 right 2} \
  -offset  {top 2 bottom 2 left 2 right 2} \
  -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid None

## Supply pads -> core ring
##   PADVDD (u_pad_vdd0/1) and PADVSS (u_pad_vss0/1) on the left / right
##   sides: their core-side VDD / VSS pins are routed to the core ring.
setSrouteMode -viaConnectToShape { noshape }

## Pad ring: join the abutting M4 supply rails of pads / fillers / corners
## (VDD, VSS, VDDIOR, VSSIOR). Abutment alone is not seen as connectivity.
sroute -connect { padRing } -nets { VDD VSS VDDIOR VSSIOR }

## Supply pads -> core ring.
## giolib045 PADVDD/PADVSS core-side pins have no CLASS CORE, so
## 'sroute -connect padPin' finds nothing (IMPSR-1256, 0 wire).
## pad_connect.tcl draws a Metal3 link from each core-side pin to the ring.
source pad_connect.tcl

## Std-cell power rails (Metal1 follow-pins) -> core ring
sroute -connect { corePin } -layerChangeRange { Metal1(1) Metal11(11) } -blockPinTarget { nearestTarget } -corePinTarget { firstAfterRowEnd } -allowJogging 1 -crossoverViaLayerRange { Metal1(1) Metal11(11) } -nets { VDD VSS } -allowLayerChange 1 -targetViaLayerRange { Metal1(1) Metal11(11) }

## Vertical Stripes in Core Area
##   Core width 260 um: 8 sets of {VDD VSS}, width 2 / spacing 1.25,
##   10 um from each core edge -> ~30 um pitch
setAddStripeMode -ignore_block_check false -break_at none -route_over_rows_only false -rows_without_stripes_only false -extend_to_closest_target none -stop_at_last_wire_for_area false -partial_set_thru_domain false -ignore_nondefault_domains false -trim_antenna_back_to_shape none -spacing_type edge_to_edge -spacing_from_block 0 -stripe_min_length stripe_width -stacked_via_top_layer Metal11 -stacked_via_bottom_layer Metal1 -via_using_exact_crossover_size false -split_vias false -orthogonal_only true -allow_jog { padcore_ring block_ring } -skip_via_on_pin { standardcell } -skip_via_on_wire_shape { noshape }

addStripe -nets {VDD VSS} -layer Metal10 -direction vertical \
  -width 2 -spacing 1.25 -number_of_sets 8 \
  -start_from left -start_offset 10 -stop_offset 10 \
  -switch_layer_over_obs false -max_same_layer_jog_length 2 \
  -padcore_ring_top_layer_limit Metal11 -padcore_ring_bottom_layer_limit Metal1 \
  -block_ring_top_layer_limit Metal11 -block_ring_bottom_layer_limit Metal1 \
  -use_wire_group 0 -snap_wire_center_to_grid None


## [CAPTURE] ------------------------------------------------
source capture.tcl
snap 01_powerplan fplan
## -----------------------------------------------------------
## verifyConnectivity - PG only (signal nets are not routed yet)
verifyConnectivity -type all -noOpen -noAntenna -noWeakConnect -noUnConnPin -noUnroutedNet -error 1000 -warning 50
verifyConnectivity -nets {VDD VSS} -type special -error 1000 -warning 50

## If there is no error, Save Design  (-> PowerPlan + PowerPlan.dat/)
saveDesign -def PowerPlan

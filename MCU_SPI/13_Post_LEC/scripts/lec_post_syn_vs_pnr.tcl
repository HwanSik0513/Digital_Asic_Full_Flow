// lec_post_syn_vs_pnr.tcl - Conformal LEC #2 : synthesis netlist (golden) vs PnR netlist (revised)
//   Checks that placement / CTS / optimization / routing did not change the function
//   (buffers, resizing, restructuring FE_OFC* / FE_RC*, clock tree CLKBUF*)
//   run in TOP/EC :  lec -nogui -dofile ./script/lec_post_syn_vs_pnr.tcl
//   GitHub chapter : 13_Post_LEC
set log file ./log/chip_top_lec_post.log -replace

read library -verilog -both \
	../../../GPDK045/digital/gsclib045_all_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v \
	../../../GPDK045/digital/giolib045_v3.5/vlog/pads_SS_s1vg.v

// golden : Genus mapped netlist (hierarchical)
read design \
	../SYN/mapped/chip_top_syn_final.v \
	-verilog -golden -root chip_top

// revised : Innovus netlist after ChipFinish (flat, saveNetlist -flat)
//   + the 6 supply pads added by make_pnr_netlist.sh (PADVDD/PADVSS/PADVDDIOR/
//     PADVSSIOR, no signal pins). pads_SS_s1vg.v has no model for them, so the
//     empty modules of EC/script/pad_supply_stubs.v (same file as SIM/POST) are read with the netlist.
read design \
	./script/pad_supply_stubs.v \
	../PNR/chip_top_pnr.v \
	-verilog -revised -root chip_top

set system mode lec
add compare points -all
compare

report verification
report statistics
report unmapped points -summary
report compare data -class nonequivalent

// list of the unreachable state points (flops with no path to any compare point)
report unmapped points -unreachable -golden

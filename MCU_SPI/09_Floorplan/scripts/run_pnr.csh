#!/bin/csh -f
## chip_top PnR: build the PnR netlist (supply pads added), then run all stages
## in LEGACY Innovus (stylus mode cannot place the giolib045 IO ring, see README)
./make_pnr_netlist.sh || exit 1
innovus -files all.tcl -log innovus.log

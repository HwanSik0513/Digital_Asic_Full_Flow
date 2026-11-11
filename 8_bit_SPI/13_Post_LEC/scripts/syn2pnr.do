//----------------------------------------------------------------------
// syn2pnr.do - gate-to-gate LEC: synthesized netlist (golden) vs PnR netlist (revised)
//   Run from a work dir two levels below TOP (paths: ../../SYN, ../../PNR, ../../../../GPDK045):
//     mkdir -p log
//     lec -XL -nogui -dofile syn2pnr.do
//   After the Tempus ECO, set the revised design to ../../PNR/spi_bridge_top_eco.v
//   PASS = "Non-equivalent 0" and "Abort 0" in log/syn2pnr_lec.log
//----------------------------------------------------------------------
set log file ./log/syn2pnr_lec.log -replace

read library -verilog -both \
        ../../../../GPDK045/digital/gsclib045_all_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v \
        ../../../../GPDK045/digital/giolib045_v3.5/vlog/pads_SS_s1vg.v

read design ../../SYN/mapped/spi_bridge_top_syn_final.v -verilog -golden

read design ../../PNR/spi_bridge_top_pnr.v -verilog -revised

set system mode lec

add compare points -all

compare

report verification
report statistics

exit -force

# Post-layout gate-level simulation (min corner) : PnR netlist + Tempus SDF (bst, FUNC_FF_BEST)
#   run from SIM/POST/min :  source run_post_min.tcl
#   HIERARCHICAL netlist chip_top_pnr_hier.v (PNR/hier_netlist.tcl): the Tempus SDF
#   names instances u_core/u_cpu/... which only match a hierarchical netlist.
#   No RTL file: the netlist holds the whole chip (CPU, ROM, RAM, SPI, pads).
#   Spi_master.v is the external SPI host of the testbench (simulation model).
#   SDF is annotated by tb_chip_top.v when +define+GLS +define+SDF_MIN is given.
#   cdc_tcheck_off.tfile: timing checks off on synchronizer first stages only.

cp ../../../PNR/chip_top_pnr_hier.v ./
cp ../../../PNR/chip_top_post_bst.sdf ./

xrun -64bit \
     +max_err_count+50 \
     +define+GLS \
     +define+SDF_MIN \
     +neg_tchk \
     -tfile ../cdc_tcheck_off.tfile \
     -timescale 1ns/1ps \
     -access +rwc \
     -gui \
     +libext+.v \
     ../../TESTBENCH/Spi_master.v \
     ../../TESTBENCH/tb_chip_top.v \
     chip_top_pnr_hier.v \
     ../pad_supply_stubs.v \
     -v ../../../../../GPDK045/digital/gsclib045_all_v4.4/gsclib045_svt_v4.4/gsclib045/verilog/fast_vdd1v0_basicCells.v \
     -v ../../../../../GPDK045/digital/giolib045_v3.5/vlog/pads_FF_s1vg.v \
     -l post_sim_min.log

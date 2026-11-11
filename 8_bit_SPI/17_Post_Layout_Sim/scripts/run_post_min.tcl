# Post-layout gate-level simulation (min corner) : PnR netlist + Tempus SDF (bst)
#   run from SIM/POST/min :  source run_post_min.tcl
#   netlist and SDF must come from the SAME PnR run (the 10 ns MMMC PNR folder)
#   HIERARCHICAL netlist (spi_bridge_top_pnr_hier.v): the testbench probes internal
#   signals (dut.u_spi_master.state, dut.w_tx_fifo_full, ...), which do not exist in
#   the flat netlist (saveNetlist -flat). Make it once in Innovus:
#     restoreDesign RouteDesign.dat spi_bridge_top ; saveNetlist spi_bridge_top_pnr_hier.v ; exit
#   ../../../RTL/Async_fifo.v : RTL FIFO for the testbench's test8_fifo (TEST 8/9)
#   SDF is annotated by tb_spi_bridge_top.v when +define+sdf_post_bst is given

cp ../../../PNR/spi_bridge_top_pnr_hier.v ./
cp ../../../PNR/spi_bridge_top_post_bst.sdf ./

xrun -64bit \
     +max_err_count+50 \
     +define+sdf_post_bst \
     -access +rwc \
     -gui \
     +libext+.v \
     ../../TESTBENCH/tb_spi_bridge_top.v \
     spi_bridge_top_pnr_hier.v \
     ../../../RTL/Async_fifo.v \
     ../../../../../GPDK045/digital/gsclib045_all_v4.4/gsclib045_svt_v4.4/gsclib045/verilog/fast_vdd1v0_basicCells.v \
     -l post_sim_min.log

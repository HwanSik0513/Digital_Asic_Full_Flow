# Post-layout gate-level simulation (max corner) : PnR netlist + Tempus SDF (wst)
#   run from SIM/POST/max :  source run_post_max.tcl
#   netlist and SDF must come from the SAME PnR run (the 10 ns MMMC PNR folder)
#   HIERARCHICAL netlist (spi_bridge_top_pnr_hier.v): the testbench probes internal
#   signals (dut.u_spi_master.state, dut.w_tx_fifo_full, ...), which do not exist in
#   the flat netlist (saveNetlist -flat). Make it once in Innovus:
#     restoreDesign RouteDesign.dat spi_bridge_top ; saveNetlist spi_bridge_top_pnr_hier.v ; exit
#   ../../../RTL/Async_fifo.v : RTL FIFO for the testbench's test8_fifo (TEST 8/9)
#   SDF is annotated by tb_spi_bridge_top.v when +define+sdf_post_wst is given

cp ../../../PNR/spi_bridge_top_pnr_hier.v ./
cp ../../../PNR/spi_bridge_top_post_wst.sdf ./

xrun -64bit \
     +max_err_count+50 \
     +define+sdf_post_wst \
     -access +rwc \
     -gui \
     +libext+.v \
     ../../TESTBENCH/tb_spi_bridge_top.v \
     spi_bridge_top_pnr_hier.v \
     ../../../RTL/Async_fifo.v \
     ../../../../../GPDK045/digital/gsclib045_all_v4.4/gsclib045_svt_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v \
     -l post_sim_max.log

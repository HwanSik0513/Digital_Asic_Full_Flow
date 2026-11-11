# Pre-layout gate-level simulation : synthesized netlist + Genus SDF
#   run from SIM/PRE :  source run_pre.tcl
#   SDF is annotated by tb_spi_bridge_top.v when +define+sdf_gate is given
#   (`ifdef sdf_gate ... $sdf_annotate ... in the testbench)
#   ../../RTL/Async_fifo.v : RTL FIFO used by the testbench's own test8_fifo (TEST 8/9),
#   not by the DUT (the netlist has its own async_fifo_DATA_WIDTH8_ADDR_WIDTH* modules)
# -timescale : time unit / precision      -access : read access for waves
# -gui       : GUI mode (remove for batch) +libext+.v : library file extension

cp ../../SYN/mapped/spi_bridge_top_syn_final.v .
cp ../../SYN/mapped/spi_bridge_top_delays.sdf .

xrun -64bit \
     +max_err_count+50 \
     +define+sdf_gate \
     -access +rwc \
     -gui \
     +libext+.v \
     ../TESTBENCH/tb_spi_bridge_top.v \
     spi_bridge_top_syn_final.v \
     ../../RTL/Async_fifo.v \
     ../../../../GPDK045/digital/gsclib045_all_v4.4/gsclib045_svt_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v \
     -l pre_sim.log

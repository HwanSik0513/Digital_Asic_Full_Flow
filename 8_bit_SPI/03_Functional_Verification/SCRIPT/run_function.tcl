#!/bin/csh -f
#----------------------------------------------------------------------
# RTL functional simulation (Cadence Xcelium)
#   run from : 03_Functional_Verification/SCRIPT
#   usage    : source run_function.tcl      (csh)
#   testbench: change the first source line to run another TESTBENCH/tb_*.v
#   GUI      : add -gui  (batch run below ends at $finish)
#
# RTL only: no standard-cell / pad Verilog models are needed here
# (those belong to the gate-level simulations, 08_Pre_Layout_Sim / 17_Post_Layout_Sim).
# XILINX_FPGA is NOT defined, so spi_bridge_top uses "assign SCLK = w_sclk_raw"
# and TESTBENCH/fpga/tb_bufg_sim_stub.v is not required.
#----------------------------------------------------------------------
xrun -64bit \
	+max_err_count+50 \
	-access +rwc \
	+libext+.v \
	../TESTBENCH/tb_spi_bridge_top.v \
	../../02_RTL/RTL/*.v \
	-l ../LOG/func_sim.log

# Pre-layout gate-level simulation : synthesized netlist + Genus SDF (chip_top)
#   run from SIM/PRE :  source run_pre.tcl
#   netlist : SYN/mapped/chip_top_syn_final.v (hierarchical, Genus)
#   SDF     : SYN/mapped/chip_top_delays.sdf  (Genus, slow_vdd1v0 0.9 V 125 C, divider '.')
#             no clock tree yet: clocks are ideal, cell + wire-load delays only
#   cells   : slow_vdd1v0_basicCells.v + giolib045 pads_SS_s1vg.v (PADDI / PADDO)
#             (no supply pads in the synthesis netlist -> no stub file needed)
#   TB      : tb_chip_top.v with +define+GLS +define+SDF_PRE
#             (chip-pin checks only: GPIO verdict + MISO echoes)
#   cdc_tcheck_off.tfile : timing checks off on synchronizer first stages only
#   GitHub chapter : 08_Pre_Layout_Sim

cp ../../SYN/mapped/chip_top_syn_final.v ./
cp ../../SYN/mapped/chip_top_delays.sdf ./

xrun -64bit \
     +max_err_count+50 \
     +define+GLS \
     +define+SDF_PRE \
     +neg_tchk \
     -tfile ./cdc_tcheck_off.tfile \
     -timescale 1ns/1ps \
     -access +rwc \
     -gui \
     +libext+.v \
     ../TESTBENCH/Spi_master.v \
     ../TESTBENCH/tb_chip_top.v \
     chip_top_syn_final.v \
     -v ../../../../GPDK045/digital/gsclib045_all_v4.4/gsclib045_svt_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v \
     -v ../../../../GPDK045/digital/giolib045_v3.5/vlog/pads_SS_s1vg.v \
     -l pre_sim.log

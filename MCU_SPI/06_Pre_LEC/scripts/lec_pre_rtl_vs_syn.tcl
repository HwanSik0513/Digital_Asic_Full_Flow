// lec_pre_rtl_vs_syn.tcl - Conformal LEC #1 : RTL (golden) vs synthesis netlist (revised)
//   chip_top = MIPS single-cycle CPU + case ROM (echo) + data RAM + SPI slave bridge + GPIO + IO pads
//   run in TOP/EC :  lec -nogui -dofile ./script/lec_pre_rtl_vs_syn.tcl
//                    (or start lec and: dofile ./script/lec_pre_rtl_vs_syn.tcl)
//   GitHub chapter : 06_Pre_LEC
set log file ./log/chip_top_lec_pre.log -replace

// cell + pad functional models (one corner only: the slow/fast models are
// functionally identical, reading both gives "duplicate module definition")
read library -verilog -both \
	../../../GPDK045/digital/gsclib045_all_v4.4/gsclib045/verilog/slow_vdd1v0_basicCells.v \
	../../../GPDK045/digital/giolib045_v3.5/vlog/pads_SS_s1vg.v

// golden : the same RTL list Genus read (SYN/script/chip_top_45nm_MMMC.tcl)
read design \
	../RTL/Reset_sync.v \
	../RTL/Pulse_sync.v \
	../RTL/Async_fifo.v \
	../RTL/Spi_slave.v \
	../RTL/Register_block.v \
	../RTL/Spi_slave_bridge.v \
	../RTL/Sc_cu.v \
	../RTL/Alu.v \
	../RTL/Regfile.v \
	../RTL/Mips_cpu.v \
	../RTL/Data_ram.v \
	../FW/build/echo_rom.v \
	../RTL/Mcu_core.v \
	../RTL/Chip_top.v \
	-verilog -golden -root chip_top

// revised : Genus mapped netlist
read design \
	../SYN/mapped/chip_top_syn_final.v \
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

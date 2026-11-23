// chip_top RTL simulation (echo program, through IO pad models)
// Paths are relative to TOP/SIM/CHIP (run_sim.sh cd's there)
// ---- RTL: SPI slave bridge ----
../../RTL/Reset_sync.v
../../RTL/Pulse_sync.v
../../RTL/Async_fifo.v
../../RTL/Spi_slave.v
../../RTL/Register_block.v
../../RTL/Spi_slave_bridge.v
// ---- RTL: CPU ----
../../RTL/Sc_cu.v
../../RTL/Alu.v
../../RTL/Regfile.v
../../RTL/Mips_cpu.v
../../RTL/Data_ram.v
// ---- RTL: MCU top ----
../../RTL/Mcu_core.v
../../RTL/Chip_top.v
// Instruction ROM generated from FW/echo.s (mips_asm.py)
../../FW/build/echo_rom.v
// ---- Testbench (simulation only) ----
../TESTBENCH/Spi_master.v
../TESTBENCH/tb_chip_top.v
// ---- IO pad behavioral models (PADDI / PADDO): added by run_sim.sh ----

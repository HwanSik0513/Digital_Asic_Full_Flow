// mcu_core system RTL simulation (echo program)
// Paths are relative to TOP/SIM/MCU (run_sim.sh cd's there)
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
// Instruction ROM generated from FW/echo.s (mips_asm.py)
../../FW/build/echo_rom.v
// ---- Testbench (simulation only) ----
../TESTBENCH/Spi_master.v
../TESTBENCH/tb_mcu_core.v

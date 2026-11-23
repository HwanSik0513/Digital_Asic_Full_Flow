// spi_slave_bridge RTL simulation
// Paths are relative to TOP/SIM/FUNCTION (run_sim.sh cd's there)
// RTL (synthesizable)
../../RTL/Reset_sync.v
../../RTL/Pulse_sync.v
../../RTL/Async_fifo.v
../../RTL/Spi_slave.v
../../RTL/Register_block.v
../../RTL/Spi_slave_bridge.v
// Testbench (simulation only)
../TESTBENCH/Spi_master.v
../TESTBENCH/tb_spi_slave_bridge.v

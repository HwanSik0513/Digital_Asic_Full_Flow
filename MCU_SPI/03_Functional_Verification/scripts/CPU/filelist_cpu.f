// mips_cpu standalone RTL simulation
// Paths are relative to TOP/SIM/CPU (run_sim.sh cd's there)
// RTL (synthesizable)
../../RTL/Sc_cu.v
../../RTL/Alu.v
../../RTL/Regfile.v
../../RTL/Mips_cpu.v
../../RTL/Data_ram.v
// Instruction ROM generated from FW/booktest.s (mips_asm.py)
../../FW/build/booktest_rom.v
// Testbench (simulation only)
../TESTBENCH/tb_mips_cpu.v

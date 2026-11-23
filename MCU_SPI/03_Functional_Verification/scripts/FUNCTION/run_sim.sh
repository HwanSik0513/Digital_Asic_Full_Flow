#!/bin/bash
# RTL simulation of spi_slave_bridge with Xcelium
# usage: ./run_sim.sh          (SimVision waveform dump -> waves.shm)
#        ./run_sim.sh -nowave  (no waveform dump)
# Always runs in TOP/SIM/FUNCTION, wherever it is launched from.
cd "$(dirname "$0")" || exit 1
DEFS=""
if [ "$1" == "-nowave" ]; then DEFS="+define+NO_SHM"; fi
xrun -64bit -access +rwc -f filelist.f -top tb_spi_slave_bridge $DEFS \
     -l func_sim.log
grep -E "PASS|FAIL|FATAL" func_sim.log | tail -n 40

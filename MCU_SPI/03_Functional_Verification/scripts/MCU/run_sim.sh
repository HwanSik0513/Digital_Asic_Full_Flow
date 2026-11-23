#!/bin/bash
# mcu_core system RTL simulation with the echo program
# usage: ./run_sim.sh            (SimVision waveform dump -> waves.shm)
#        ./run_sim.sh -nowave    (no waveform dump)
#        ./run_sim.sh -gen       (re-assemble FW/echo.s first; needs python3)
# Always runs in TOP/SIM/MCU, wherever it is launched from.
cd "$(dirname "$0")" || exit 1
DEFS=""
for a in "$@"; do
    case "$a" in
        -nowave) DEFS="+define+NO_SHM" ;;
        -gen) python3 ../../FW/mips_asm.py ../../FW/echo.s -o ../../FW/build/echo --rom-depth 64 || exit 1 ;;
    esac
done
xrun -64bit -access +rwc -f filelist_mcu.f -top tb_mcu_core $DEFS -l mcu_sim.log
grep -E "PASS|FAIL|FATAL|INFO|GPIO|RX pop|MISO echo" mcu_sim.log | tail -n 40

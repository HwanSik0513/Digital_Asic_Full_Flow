#!/bin/bash
# Standalone RTL simulation of mips_cpu (book Section 5.5 test program)
# usage: ./run_sim.sh            (SimVision waveform dump -> waves.shm)
#        ./run_sim.sh -nowave    (no waveform dump)
#        ./run_sim.sh -gen       (re-assemble FW/booktest.s and regenerate the
#                                 expected values first; needs python3)
# Always runs in TOP/SIM/CPU, wherever it is launched from.
cd "$(dirname "$0")" || exit 1
DEFS=""
for a in "$@"; do
    case "$a" in
        -nowave) DEFS="+define+NO_SHM" ;;
        -gen)
            python3 ../../FW/mips_asm.py ../../FW/booktest.s -o ../../FW/build/booktest --rom-depth 64 || exit 1
            python3 ../../FW/mips_iss.py ../../FW/build/booktest.hex -o ../../FW/build/booktest_exp --ram-words 32 || exit 1
            ;;
    esac
done
xrun -64bit -access +rwc -f filelist_cpu.f -top tb_mips_cpu $DEFS -l cpu_sim.log
grep -E "PASS|FAIL|FATAL|INFO" cpu_sim.log | tail -n 20

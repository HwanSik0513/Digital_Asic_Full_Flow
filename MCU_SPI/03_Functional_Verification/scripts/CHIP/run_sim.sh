#!/bin/bash
# chip_top RTL simulation (echo program) through the giolib045 pad models
# usage: ./run_sim.sh            (SimVision waveform dump -> waves.shm)
#        ./run_sim.sh -nowave    (no waveform dump)
# Always runs in TOP/SIM/CHIP, wherever it is launched from.
cd "$(dirname "$0")" || exit 1

GPDK_ROOT=${GPDK_ROOT:-/home/hah003/PROJ1/GPDK045/digital}
PAD_VLOG_DIR=$GPDK_ROOT/giolib045_v3.5/vlog

# every Verilog file of the pad library is passed as a library file (-v):
# only the cells actually used (PADDI, PADDO) are compiled from it.
PAD_ARGS=""
for f in "$PAD_VLOG_DIR"/*.v "$PAD_VLOG_DIR"/*.vlog "$PAD_VLOG_DIR"/*.vg; do
    [ -f "$f" ] && PAD_ARGS="$PAD_ARGS -v $f"
done
if [ -z "$PAD_ARGS" ]; then
    echo "ERROR: no pad Verilog model found in $PAD_VLOG_DIR"
    exit 1
fi

DEFS=""
[ "$1" == "-nowave" ] && DEFS="+define+NO_SHM"

xrun -64bit -access +rwc -timescale 1ns/1ps \
     -f filelist_chip.f $PAD_ARGS -top tb_chip_top $DEFS -l chip_sim.log
grep -E "PASS|FAIL|FATAL|INFO|GPIO|\*E" chip_sim.log | tail -n 40

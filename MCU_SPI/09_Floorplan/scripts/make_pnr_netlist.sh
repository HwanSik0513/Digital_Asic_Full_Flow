#!/bin/bash
# make_pnr_netlist.sh - build the PnR input netlist
#   in  : ../SYN/mapped/chip_top_syn_final.v   (Genus netlist, signal pads only)
#   add : add_pad_chip                          (6 supply pad instances)
#   out : chip_top_pnr_in.v                     (read by 0_InitDesign.tcl)
# Same method as the previous flow (add_pad pasted into the netlist), done
# automatically: the supply pads are inserted just before the 'endmodule'
# of module chip_top.
cd "$(dirname "$0")" || exit 1
IN=../SYN/mapped/chip_top_syn_final.v
OUT=chip_top_pnr_in.v
PADS=add_pad_chip

[ -f "$IN" ]   || { echo "ERROR: $IN not found (run synthesis first)"; exit 1; }
[ -f "$PADS" ] || { echo "ERROR: $PADS not found"; exit 1; }

awk -v padfile="$PADS" '
    /^module chip_top[ (]/      { intop = 1 }
    intop && /^endmodule/       {
        print "  // ---- supply pads (add_pad_chip, inserted by make_pnr_netlist.sh) ----"
        while ((getline l < padfile) > 0) print "  " l
        intop = 0; done = 1
    }
    { print }
    END { if (!done) { print "ERROR: module chip_top not found" > "/dev/stderr"; exit 1 } }
' "$IN" > "$OUT" || exit 1

# PnR SDC: synthesis SDC without set_ideal_network. Genus keeps the clock /
# reset ports ideal; left in PnR they stop CCOpt from building the trees
# (0 clock buffers, skew 0, latency = SDC value) and keep ARESETn unbuffered.
SDC_IN=../SYN/mapped/chip_top_syn_final.sdc
SDC_OUT=chip_top_pnr_in.sdc
[ -f "$SDC_IN" ] || { echo "ERROR: $SDC_IN not found (run synthesis first)"; exit 1; }
grep -v "^ *set_ideal_network" "$SDC_IN" > "$SDC_OUT"
echo "INFO: $SDC_OUT written : set_ideal_network lines removed = $(grep -c '^ *set_ideal_network' "$SDC_IN")"

n=$(grep -c -E "^ *PAD(VDD|VSS|VDDIOR|VSSIOR) " "$OUT")
s=$(grep -c -E "^ *PADD[IO] " "$OUT")
echo "INFO: $OUT written : signal pads = $s (expect 14), supply pads = $n (expect 6)"

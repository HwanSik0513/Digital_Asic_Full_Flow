set pad_list {u_pad_vdd0 VDD u_pad_vdd1 VDD u_pad_vss0 VSS u_pad_vss1 VSS}
set cbox [lindex [dbGet top.fPlan.coreBox] 0]
set cx1 [lindex $cbox 0]
set cx2 [lindex $cbox 2]
set pin_spans {2.86 6.18 53.82 57.14}
foreach {p n} $pad_list {
    set b [lindex [dbGet [dbGet -p top.insts.name $p].box] 0]
    set px1 [lindex $b 0]
    set py1 [lindex $b 1]
    set px2 [lindex $b 2]
    if {$px2 <= $cx1} {
        set sx1 [expr {$px2 - 2.0}]
        set sx2 [expr {$cx1 - 2.0}]
    } else {
        set sx1 [expr {$cx2 + 2.0}]
        set sx2 [expr {$px1 + 2.0}]
    }
    foreach {a0 a1} $pin_spans {
        set sy1 [expr {$py1 + $a0}]
        set sy2 [expr {$py1 + $a1}]
        set w   [expr {$a1 - $a0}]
        puts "**INFO: pad link $p ($n) Metal3 area {$sx1 $sy1 $sx2 $sy2}"
        addStripe -nets $n -layer Metal3 -direction horizontal \
            -width $w -spacing 1 -number_of_sets 1 \
            -area [list $sx1 $sy1 $sx2 $sy2] \
            -start_from bottom -start_offset 0 -stop_offset 0
    }
}

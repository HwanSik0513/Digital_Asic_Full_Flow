# 04. Logic Synthesis — MMMC / 625MHz

| Item | Value |
|---|---|
| Clock | **ACLK 1.6 ns (625 MHz)**, SCLK = ACLK ÷ 4 (generated clock) |
| Corner | MMMC — setup `FUNC_SS_WORST` + `FUNC_FF_BEST`, hold `FUNC_FF_BEST` |
| Script | [`scripts/spi_bridge_top_45nm_MMMC.tcl`](scripts/spi_bridge_top_45nm_MMMC.tcl) + [`scripts/spi_bridge_top_syn.mmmc.tcl`](scripts/spi_bridge_top_syn.mmmc.tcl) |
| 바뀐 것 | [`scripts/spi_bridge_top.sdc`](scripts/spi_bridge_top.sdc)의 `CLK_PERIOD`만 1.6로 변경 (스크립트는 100MHz run과 동일) |
| 판정 | **PASS** — 합성 setup 만족 |

## Result (syn_opt)

| View / Clock | Slack (ps) |
|---|---|
| `FUNC_SS_WORST` — 전체 worst | **0** |
| `FUNC_SS_WORST` — SCLK 그룹 | +273 |
| `FUNC_FF_BEST` (참고) | +914 |

| Item | Value |
|---|---|
| TNS (SS) | 0 ps |
| Failing paths (SS) | 0 |
| Cell area | 4,117 µm² |
| Leaf instances | 959 |
| Power (Genus, vectorless) | 413.8 µW |
| Worst path (SS) | `u_rx_fifo/r_rd_ptr_bin_reg_1/CK` → `u_rx_fifo/r_empty_reg/D` (R2R, negedge FF) |

합성 slack이 정확히 0 ps인 **합성 Fmax**입니다. 이 넷리스트로 PnR을 진행해 +0.035 ns로 닫혔습니다 → [16_Timing_Closure/MMMC/625MHz](../../../16_Timing_Closure/MMMC/625MHz).

전체 주파수 스윕 비교는 [MMMC README](../README.md)에 있습니다.

## Files

```text
04_Synthesis/MMMC/625MHz/
├── README.md
│
├── reports/
│   ├── 00_check_design.rpt
│   ├── 01_check_timing_intent.rpt
│   ├── 08_spi_bridge_top_SYN_analysis_view.rpt
│   ├── 09_spi_bridge_top_SYN_area.rpt
│   ├── 12_spi_bridge_top_SYN_design_rules.rpt
│   ├── 13_spi_bridge_top_SYN_gate.rpt
│   ├── 14_spi_bridge_top_SYN_hier.rpt
│   ├── 18_spi_bridge_top_SYN_pwr.rpt
│   ├── 19_spi_bridge_top_SYN_qor.rpt
│   ├── 20a_spi_bridge_top_SYN_timing_SS.rpt
│   ├── 20b_spi_bridge_top_SYN_timing_FF.rpt
│   ├── final.rpt
│   ├── genus_all.log
│   ├── syn_generic_qor.rpt
│   ├── syn_map_qor.rpt
│   └── syn_opt_qor.rpt
│
├── results/
│   ├── spi_bridge_top_delays.sdf
│   ├── spi_bridge_top_syn_final.sdc
│   └── spi_bridge_top_syn_final.v
│
└── scripts/
    ├── dont_use_45nm.tcl
    ├── run_synthesis
    ├── spi_bridge_top.sdc
    ├── spi_bridge_top_45nm_MMMC.tcl
    └── spi_bridge_top_syn.mmmc.tcl
```

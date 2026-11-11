# 04. Logic Synthesis — MMMC / 714MHz

| Item | Value |
|---|---|
| Clock | **ACLK 1.4 ns (714 MHz)**, SCLK = ACLK ÷ 4 (generated clock) |
| Corner | MMMC — setup `FUNC_SS_WORST` + `FUNC_FF_BEST`, hold `FUNC_FF_BEST` |
| Script | [`scripts/spi_bridge_top_45nm_MMMC.tcl`](scripts/spi_bridge_top_45nm_MMMC.tcl) + [`scripts/spi_bridge_top_syn.mmmc.tcl`](scripts/spi_bridge_top_syn.mmmc.tcl) |
| 바뀐 것 | [`scripts/spi_bridge_top.sdc`](scripts/spi_bridge_top.sdc)의 `CLK_PERIOD`만 1.4로 변경 (스크립트는 100MHz run과 동일) |
| 판정 | **FAIL** — setup 위반 9개 경로 (TNS −762 ps) |

## Result (syn_opt)

| View / Clock | Slack (ps) |
|---|---|
| `FUNC_SS_WORST` — 전체 worst | **−124** |
| `FUNC_SS_WORST` — SCLK 그룹 | +120 |
| `FUNC_FF_BEST` (참고) | +725 |

| Item | Value |
|---|---|
| TNS (SS) | −762 ps |
| Failing paths (SS) | 9 |
| Cell area | 4,495 µm² |
| Leaf instances | 1,033 |
| Power (Genus, vectorless) | 508.2 µW |
| Worst path (SS) | `u_rx_fifo/r_wr_ptr_gray_rclk_reg_2/CK` → `o_bus_rdata[4]` (R2O) |

위반이 더 커지고(−124 ps), Genus가 셀을 키워 면적이 계속 늘어납니다. PnR은 진행하지 않았습니다.

전체 주파수 스윕 비교는 [MMMC README](../README.md)에 있습니다.

## Files

```text
04_Synthesis/MMMC/714MHz/
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

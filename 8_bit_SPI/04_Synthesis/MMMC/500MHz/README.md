# 04. Logic Synthesis — MMMC / 500MHz

| Item | Value |
|---|---|
| Clock | **ACLK 2.0 ns (500 MHz)**, SCLK = ACLK ÷ 4 (generated clock) |
| Corner | MMMC — setup `FUNC_SS_WORST` + `FUNC_FF_BEST`, hold `FUNC_FF_BEST` |
| Script | [`scripts/spi_bridge_top_45nm_MMMC.tcl`](scripts/spi_bridge_top_45nm_MMMC.tcl) + [`scripts/spi_bridge_top_syn.mmmc.tcl`](scripts/spi_bridge_top_syn.mmmc.tcl) |
| 바뀐 것 | [`scripts/spi_bridge_top.sdc`](scripts/spi_bridge_top.sdc)의 `CLK_PERIOD`만 2.0로 변경 (스크립트는 100MHz run과 동일) |
| 판정 | **PASS** — 합성 setup 만족 |

## Result (syn_opt)

| View / Clock | Slack (ps) |
|---|---|
| `FUNC_SS_WORST` — 전체 worst | **+11** |
| `FUNC_SS_WORST` — SCLK 그룹 | +673 |
| `FUNC_FF_BEST` (참고) | +1,297 |

| Item | Value |
|---|---|
| TNS (SS) | 0 ps |
| Failing paths (SS) | 0 |
| Cell area | 3,571 µm² |
| Leaf instances | 850 |
| Power (Genus, vectorless) | 290.7 µW |
| Worst path (SS) | `u_reset_sync_aclk/rst_n_sync_reg/CK` → `u_rx_fifo/o_rd_data_reg_3/D` (R2R) |

이 넷리스트로 PnR까지 진행했습니다 → [09_Floorplan/MMMC/500MHz](../../../09_Floorplan/MMMC/500MHz).

전체 주파수 스윕 비교는 [MMMC README](../README.md)에 있습니다.

## Files

```text
04_Synthesis/MMMC/500MHz/
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

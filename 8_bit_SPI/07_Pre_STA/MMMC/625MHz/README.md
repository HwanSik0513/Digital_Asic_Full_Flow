# 07. Pre-Layout STA (Genus) — MMMC / 625MHz

| Item | Value |
|---|---|
| Clock | ACLK 1.6 ns, SCLK = ACLK ÷ 4, ideal clock |
| Tool | Genus `report_timing` (합성 직후) |
| Constraints | [`constraints/spi_bridge_top.sdc`](constraints/spi_bridge_top.sdc) → [`constraints/spi_bridge_top_syn_final.sdc`](constraints/spi_bridge_top_syn_final.sdc) |

| View / Group | Slack (ps) |
|---|---|
| `FUNC_SS_WORST` — ACLK | **0** |
| `FUNC_SS_WORST` — SCLK | +273 |
| `FUNC_FF_BEST` — worst | +914 |

배선 지연이 없는 ideal clock 기준이며, hold는 참고용입니다. 리포트: `05_*_post_syn_map`, `07_*_post_syn_opt`, `20a` (SS), `20b` (FF).

## Files

```text
07_Pre_STA/MMMC/625MHz/
├── README.md
│
├── constraints/
│   ├── spi_bridge_top.sdc
│   └── spi_bridge_top_syn_final.sdc
│
└── reports/
    ├── 05_ACLK_post_syn_map.rpt
    ├── 05_SCLK_post_syn_map.rpt
    ├── 06_report_constraint.rpt
    ├── 07_ACLK_post_syn_opt.rpt
    ├── 07_SCLK_post_syn_opt.rpt
    ├── 07_default_post_syn_opt.rpt
    ├── 10_spi_bridge_top_SYN_clock.rpt
    ├── 20a_spi_bridge_top_SYN_timing_SS.rpt
    ├── 20b_spi_bridge_top_SYN_timing_FF.rpt
    ├── syn_opt_time_FUNC_FF_BEST.rpt
    └── syn_opt_time_FUNC_SS_WORST.rpt
```

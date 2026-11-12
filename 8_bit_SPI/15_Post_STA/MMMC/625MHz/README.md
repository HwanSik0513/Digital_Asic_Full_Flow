# 15. Post-Route STA — MMMC / 625MHz

| Item | Value |
|---|---|
| Clock | **ACLK 1.6 ns (625 MHz)**, SCLK = ACLK ÷ 4 (generated clock) |
| Run | Fmax 실험 — 합성·PnR 모두 닫힌 최고 주파수 (1.6 ns) |
| Tool | Cadence Innovus 22.17 (`timeDesign`) |
| Setup view | `FUNC_SS_WORST` — slow_vdd1v0, RC WORST, 125 °C |
| Hold view | `FUNC_FF_BEST` — fast_vdd1v0, RC BEST, 0 °C |
| Analysis | single mode, SI off |

> **MMMC PnR** — setup view `FUNC_SS_WORST` (slow_vdd1v0, RC WORST, 125 °C), hold view `FUNC_FF_BEST` (fast_vdd1v0, RC BEST, 0 °C). 입력은 [04_Synthesis/MMMC](../../../04_Synthesis/MMMC)의 같은 주파수 넷리스트와 SDC입니다. 전체 흐름은 `all.tcl` 한 번 실행 (BUFX2 사용 금지 가드 포함).

---

## 1. Timing Summary

| Check | WNS | TNS | 위반 |
|---|---|---|---|
| **Setup** (SS) | **+0.035 ns** | 0.000 | 0 |
| **Hold** (FF) | **+0.002 ns** | 0.000 | 0 |

| Worst setup path | Value |
|---|---|
| Begin → End | `i_bus_addr[1]` → `u_register_block/o_tx_fifo_wr_data_reg_6/D` |
| Group | ACLK |
| Slack | +0.035 ns |

Tempus 독립 분석(coverage, untested, recovery/removal)은 기준 run에서 했습니다 → [MMMC/100MHz](../100MHz).

## Analysis

### A.1 Slack Histogram

![](images/01_Slack_Histogram.png)

- **What** — worst 50 setup / 50 hold 경로의 slack 분포
- **Observe** — setup 0.035 ~ 0.361 ns, hold 0.002 ~ 0.069 ns, 음수 0
- **Insight** — 주기가 1.6 ns로 짧아 setup 여유가 수십 ps 수준까지 줄었습니다. 이 주파수가 이 설계의 한계 근처라는 뜻입니다.

### A.2 Clock Domain Paths

![](images/02_Clock_Domain_Paths.png)

- **What** — worst 경로의 launch → capture 클럭 쌍
- **Observe** — setup: ACLK -> ACLK 47, SCLK -> ACLK 3
- **Observe** — hold: ACLK -> ACLK 23, ACLK -> SCLK 16, SCLK -> SCLK 11

## Files

```text
15_Post_STA/MMMC/625MHz/
├── images/
│   ├── 01_Slack_Histogram.png
│   └── 02_Clock_Domain_Paths.png
│
└── reports/
    ├── hold/
    │   ├── spi_bridge_top_postRoute_all_hold.tarpt
    │   └── spi_bridge_top_postRoute_hold.summary
    └── setup/
        ├── spi_bridge_top_postRoute.summary
        └── spi_bridge_top_postRoute_all.tarpt
```

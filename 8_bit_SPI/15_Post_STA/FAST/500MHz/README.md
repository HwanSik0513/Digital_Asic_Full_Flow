# 15. Post-Route STA — FAST / 500MHz

| Item | Value |
|---|---|
| Corner (synthesis library) | **FAST** — `fast_vdd1v0 (FF, 1.1 V, 0 °C)` |
| Clock | **ACLK 2 ns (500 MHz)**, SCLK = ACLK ÷ 4 (generated clock) |
| Tool | Cadence Innovus 22.17 (`timeDesign`) |
| Setup view | `FUNC_SS_WORST` — slow_vdd1v0, RC WORST, 125 °C |
| Hold view | `FUNC_FF_BEST` — fast_vdd1v0, RC BEST, 0 °C |
| Analysis | `single` mode, SI off |
| Parasitics | `extractRC` postRoute / low → [14_RC_Extraction](../../../14_RC_Extraction/FAST/500MHz) |

> **비교 실험 설계** — 같은 RTL을 SLOW(`slow_vdd1v0`, SS) / FAST(`fast_vdd1v0`, FF) 라이브러리로 각각 합성하고, PnR은 6개 실행 모두 같은 조건(MMMC setup `FUNC_SS_WORST` SS/125 °C, hold `FUNC_FF_BEST` FF/0 °C, 같은 스크립트)으로 구현했습니다. 차이는 입력 넷리스트의 **합성 코너**뿐이며, 합성 코너가 setup 검사 코너(SS)와 같을 때(SLOW)와 다를 때(FAST)를 비교합니다.

---

## 1. Timing Summary

| Check | Group | WNS (ns) | TNS (ns) | Violating / All |
|---|---|---|---|---|
| **Setup** | all | **+0.024** | 0.000 | 0 / 650 |
| | reg2reg | +0.050 | 0.000 | 0 / 640 |
| | default | +0.024 | 0.000 | 0 / 24 |
| **Hold** | all | **+0.007** | 0.000 | 0 / 650 |
| | reg2reg | +0.007 | 0.000 | 0 / 640 |
| | default | +0.053 | 0.000 | 0 / 24 |

| DRV | max_cap | max_tran | max_fanout | Density |
|---|---|---|---|---|
| Result | 0 | 0 | 0 | 78.29 % |

**판정: setup PASS / hold PASS**

## 2. Worst Setup Path

| Item | Value |
|---|---|
| Begin → End | `i_bus_addr[1]` → `u_register_block/r_drain_active_reg/D` (ACLK) |
| Period / uncertainty / setup | 2.0 / 0.1 / 0.164 ns |
| Arrival / required | 1.595 / 1.62 ns |
| **Slack** | **+0.024 ns** |
| Logic stages | 9 cells |

| # | Setup path (top 3) | Clock | Slack (ns) |
|---|---|---|---|
| 1 | `i_bus_addr[1]` → `u_register_block/r_drain_active_reg/D` | ACLK → ACLK | +0.024 |
| 2 | `u_register_block/r_drain_active_reg/Q` → `u_rx_fifo/o_rd_data_reg_7/D` | ACLK → ACLK | +0.050 |
| 3 | `u_rx_fifo/r_empty_reg/Q` → `u_rx_fifo/r_empty_reg/D` | ACLK → ACLK | +0.075 |

| # | Hold path (top 3) | Clock | Slack (ns) |
|---|---|---|---|
| 1 | `u_tx_fifo/mem_reg_2_0/Q` → `u_tx_fifo/o_rd_data_reg_0/D` | ACLK → SCLK | +0.007 |
| 2 | `u_tx_fifo/r_wr_ptr_gray_reg_0/Q` → `u_tx_fifo/r_wr_ptr_gray_meta_r_reg_0/D` | ACLK → SCLK | +0.008 |
| 3 | `u_tx_fifo/mem_reg_2_6/Q` → `u_tx_fifo/o_rd_data_reg_6/D` | ACLK → SCLK | +0.008 |

## 3. Path Distribution (worst 50 per check)

| Check | Slack range (ns) | Negative | Launch → capture |
|---|---|---|---|
| Setup | +0.024 ~ +0.652 | 0 | ACLK→ACLK 49, SCLK→ACLK 1 |
| Hold | +0.007 ~ +0.067 | 0 | ACLK→SCLK 16, ACLK→ACLK 21, SCLK→SCLK 13 |

tarpt에는 check별 상위 50개 경로만 있어 전체 650개 경로의 분포는 아닙니다.

## Analysis

### A.1 Slack Histogram

![](images/01_Slack_Histogram.png)

- **What** — setup / hold 상위 50개 경로의 slack 분포
- **Observe** — setup +0.024 ~ +0.652 ns (음수 0개)
- **Observe** — hold +0.007 ~ +0.067 ns (음수 0개)
- **Insight** — setup·hold 모두 여유가 있습니다.

### A.2 Clock Pair

![](images/02_Clock_Domain_Paths.png)

- **What** — 상위 경로의 launch → capture 클럭
- **Observe** — setup: ACLK → ACLK 49, SCLK → ACLK 1
- **Observe** — hold: ACLK → SCLK 16, ACLK → ACLK 21, SCLK → SCLK 13
- **Insight** — hold 상위 경로에 ACLK → SCLK가 16개 있습니다. async FIFO 메모리를 SCLK 도메인에서 읽는 경로로, SCLK를 ACLK의 generated clock으로 정의해 동기 경로로 검사되기 때문입니다.


## 4. Images

| | |
|---|---|
| ![](images/01_Slack_Histogram.png) | **01 Slack histogram** — setup / hold 상위 50개 |
| ![](images/02_Clock_Domain_Paths.png) | **02 Clock pair** — launch → capture 클럭 |

## Files

```text
15_Post_STA/FAST/500MHz/
├── README.md
│
├── reports/
│   ├── drv/
│   │   ├── postRoute_cap.rpt
│   │   ├── postRoute_fanout.rpt
│   │   ├── postRoute_length.rpt
│   │   └── postRoute_tran.rpt
│   ├── hold/
│   │   ├── postRoute_all_hold.tarpt
│   │   ├── postRoute_default_hold.tarpt
│   │   ├── postRoute_hold.summary
│   │   └── postRoute_reg2reg_hold.tarpt
│   └── setup/
│       ├── postRoute_all.tarpt
│       ├── postRoute_default.tarpt
│       ├── postRoute_reg2reg.tarpt
│       └── postRoute_setup.summary
│
└── images/
    ├── 01_Slack_Histogram.png
    └── 02_Clock_Domain_Paths.png
```

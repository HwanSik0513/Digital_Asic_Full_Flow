# 07. Pre-Layout STA (post-synthesis) — SLOW / 1GHz

| Item | Value |
|---|---|
| Corner (synthesis library) | **SLOW** — `slow_vdd1v0 (SS, 0.9 V, 125 °C)` |
| Clock | **ACLK 1 ns (1 GHz)**, SCLK = ACLK ÷ 4 (generated clock) |
| Tool | Cadence Genus 22.17 (`report_timing`, ideal clock) |
| Operating condition | `PVT_0P9V_125C` |
| Constraint | [`constraints/spi_bridge_top.sdc`](constraints/spi_bridge_top.sdc) → Genus 출력 [`spi_bridge_top_syn_final.sdc`](constraints/spi_bridge_top_syn_final.sdc) |

합성 직후 넷리스트를 배치 전(ideal clock, wire-load 없이 physical library 기준) 상태로 분석한 결과입니다. 배치 후 STA는 [15_Post_STA](../../../15_Post_STA/SLOW/1GHz)에 있습니다.

---

## 1. Constraint Summary

| Item | Value |
|---|---|
| ACLK period | 1,000 ps |
| SCLK (generated, ÷4) | 4,000 ps |
| Clock uncertainty (report 기준) | 100 ps |
| Output delay (worst path 기준) | 100 ps |

변수 값과 I/O delay, generated clock 정의는 [`constraints/spi_bridge_top.sdc`](constraints/spi_bridge_top.sdc)에 있습니다.

## 2. Timing by Cost Group (syn_opt)

| Cost group | Worst slack (ps) | TNS (ps) | Violating paths |
|---|---|---|---|
| ACLK | **-608.2** | -9,663.5 | 44 |
| SCLK | -90.7 | -678.8 | 8 |

| Path type | Worst slack (ps) | TNS (ps) |
|---|---|---|
| R2R | -600 | -7,494 |
| I2R | -38 | -121 |
| R2O | -608 | -2,799 |
| I2O | -445 | -1,563 |

R2R = reg→reg, I2R = input→reg, R2O = reg→output, I2O = input→output (`report/final.rpt`)

## 3. Worst Path (Path 1, `20_spi_bridge_top_SYN_timing.rpt`)

| Item | Value |
|---|---|
| Status / slack | **VIOLATED (-608 ps)** |
| Check | Late External Delay Assertion at pin o_bus_rdata[4] |
| Start → End | `u_rx_fifo/r_wr_ptr_gray_rclk_reg_2/CK` → `o_bus_rdata[4]` |
| Required / launch / data path | 1200 / 400 / 1408 ps |
| Cells on path | 13 (`DFFRHQX4` → … → `NAND2X8`) |

## 4. Top 100 Paths

| Item | Value |
|---|---|
| Slack range | -608 ~ -585 ps |
| Violating (of 100) | 100 |
| Check type | Late External Delay Assertion 89, Setup Check 11 |
| Cost group | ACLK 100 |

## 5. Timing Intent Check (`01_check_timing_intent.rpt`)

| Lint item | Count |
|---|---|
| Sequential data pins driven by a clock signal | 1 |
| Timing exceptions with no effect | 2 |
| Inputs without clocked external delays | 1 |
| Outputs without clocked external delays | 4 |

총 8건이며 나머지 항목은 0입니다.

## Analysis

합성 단계 STA는 ideal clock 기준이라 클럭 트리 지연과 실제 배선이 반영되지 않습니다. 배치·배선 후 결과는 15_Post_STA와 비교해 보세요.

### A.1 Slack by Cost Group / Path Type

![](images/01_Slack_by_Group.png)

- **What** — 클럭 그룹별, 경로 종류별 worst slack
- **Observe** — ACLK -608.2 ps / SCLK -90.7 ps
- **Observe** — path type: R2R -600, I2R -38, R2O -608, I2O -445 ps
- **Insight** — 가장 빠듯한 경로 종류는 **R2O**(-608 ps)입니다. SCLK는 ACLK의 1/4 주파수라 여유가 더 큽니다.

### A.2 Slack Distribution (top 100)

![](images/02_Slack_Histogram.png)

- **What** — `report_timing -nworst 100` 경로의 slack 분포
- **Observe** — slack -608 ~ -585 ps, 위반 100개
- **Insight** — 상위 100개 중 100개가 위반입니다. 위반이 한 경로에 몰린 게 아니라 여러 경로에 퍼져 있으면 RTL 구조 개선이 필요합니다.

### A.3 Worst Path Budget

![](images/03_Worst_Path_Budget.png)

- **What** — 1번 경로의 launch / data path / required 구성
- **Observe** — `u_rx_fifo/r_wr_ptr_gray_rclk_reg_2/CK` → `o_bus_rdata[4]`
- **Observe** — data path 1408 ps, 사용 가능 시간(required − launch) 800 ps → slack -608 ps
- **Insight** — data path가 사용 가능 시간보다 길어 위반입니다.


## 6. Images

| | |
|---|---|
| ![](images/01_Slack_by_Group.png) | **01 Slack by Group** — cost group별, path type별 worst slack |
| ![](images/02_Slack_Histogram.png) | **02 Slack Histogram** — `report_timing -nworst 100` 경로의 slack 분포 |
| ![](images/03_Worst_Path_Budget.png) | **03 Worst Path Budget** — 1번 경로의 launch / data path / required 구성 |

## Files

```text
07_Pre_STA/SLOW/1GHz/
├── README.md
│
├── constraints/
│   ├── spi_bridge_top.sdc
│   └── spi_bridge_top_syn_final.sdc
│
├── reports/
│   ├── 01_check_timing_intent.rpt
│   ├── 02_report_port.rpt
│   ├── 05_ACLK_post_syn_map.rpt
│   ├── 05_SCLK_post_syn_map.rpt
│   ├── 05_default_post_syn_map.rpt
│   ├── 06_report_constraint.rpt
│   ├── 07_ACLK_post_syn_opt.rpt
│   ├── 07_SCLK_post_syn_opt.rpt
│   ├── 07_default_post_syn_opt.rpt
│   ├── 08_spi_bridge_top_SYN_analysis_view.rpt
│   ├── 10_spi_bridge_top_SYN_clock.rpt
│   ├── 20_spi_bridge_top_SYN_timing.rpt
│   └── syn_opt_time.rpt
│
└── images/
    ├── 01_Slack_by_Group.png
    ├── 02_Slack_Histogram.png
    └── 03_Worst_Path_Budget.png
```

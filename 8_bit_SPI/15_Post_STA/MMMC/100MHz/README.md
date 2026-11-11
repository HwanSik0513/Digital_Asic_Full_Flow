# 15. Post-Route STA (Tempus) — MMMC / 100MHz

Innovus 결과를 Tempus로 다시 읽어 독립적으로 STA를 수행했습니다.

| Item | Value |
|---|---|
| Tool | Cadence Tempus 22.17 |
| Input | `read_design RouteDesign.dat spi_bridge_top` (넷리스트 + MMMC + SDC + 배치·배선 + RC) |
| Clock | ACLK 10 ns, SCLK = ACLK ÷ 4, `set_propagated_clock` |
| Setup view | `FUNC_SS_WORST` — slow_vdd1v0, RC WORST, 125 °C |
| Hold view | `FUNC_FF_BEST` — fast_vdd1v0, RC BEST, 0 °C |
| Script | [`scripts/tempus_post_sta.tcl`](scripts/tempus_post_sta.tcl) |
| Reports | [`reports/`](reports) 00 ~ 60 + `untested_*` 4개, [`reports/tempus.log`](reports/tempus.log) |
| SDF out | [`results/spi_bridge_top_post_wst.sdf`](results/spi_bridge_top_post_wst.sdf) (SS), [`results/spi_bridge_top_post_bst.sdf`](results/spi_bridge_top_post_bst.sdf) (FF) → [17_Post_Layout_Sim](../../../17_Post_Layout_Sim) |

## 1. Summary

| Check | Result | Innovus `timeDesign` |
|---|---|---|
| **Setup** (SS) | **+7.716 ns** MET | +7.716 ns |
| **Hold** (FF) | **+0.002 ns** MET | +0.002 ns |
| Recovery (SS) | +9.291 ns MET | — |
| Removal (FF) | +0.038 ns MET | — |
| Clock skew (setup view) | ACLK 0.000 ns / SCLK 0.066 ns | — |
| DRV (max_tran / max_cap / pulse width) | 위반 없음 | 0 |
| RC annotation (real net) | **1,030 / 1,030 (100 %)** | — |

Tempus와 Innovus의 setup/hold 값이 일치합니다. 같은 엔진·같은 RC를 쓰므로 예상된 결과이며, Tempus 쪽에서 recovery/removal, coverage, untested 분석을 추가로 확인했습니다.

## 2. Worst Paths

| # | Setup (SS) | Slack |
|---|---|---|
| 1 | `u_rx_fifo/r_wr_ptr_gray_rclk_reg_4/Q` → `o_bus_rdata[4]` | +7.716 ns |
| 4 | `u_rx_fifo/r_empty_reg/Q` → `u_rx_fifo/o_rd_data_reg_1/D` | +7.754 ns |
| 5 | `u_register_block/r_drain_active_reg/Q` → `u_rx_fifo/o_rd_data_reg_7/D` | +7.788 ns |

| # | Hold (FF) | Clock | Slack |
|---|---|---|---|
| 1 | `u_tx_fifo/mem_reg_2_4/Q` → `u_tx_fifo/o_rd_data_reg_4/D` | ACLK → SCLK | +0.002 ns |
| 2 | `u_tx_fifo/mem_reg_1_6/Q` → `u_tx_fifo/o_rd_data_reg_6/D` | ACLK → SCLK | +0.003 ns |
| 3 | `u_tx_fifo/mem_reg_2_1/Q` → `u_tx_fifo/o_rd_data_reg_1/D` | ACLK → SCLK | +0.003 ns |

hold worst는 TX FIFO 메모리(ACLK 쓰기) → 읽기 레지스터(SCLK) 경로입니다. SCLK가 ACLK에서 분주된 generated clock이라 동기 관계로 타이밍이 검사됩니다.

## 3. Pre vs Post (같은 worst setup path)

| 항목 | Pre (Genus, ideal clock) | Post (Tempus, propagated) | 차이 |
|---|---|---|---|
| Launch clock (source + network) | +0.400 ns (SDC ideal latency) | −0.139 ns | −0.539 |
| Data path | 2.703 ns | 2.418 ns | −0.285 |
| Required time | 10.200 ns | 10.000 ns | −0.200 |
| **Slack** | **+7.097 ns** | **+7.721 ns** | **+0.624** |

합성 단계는 SDC의 ideal clock latency(0.4 ns)를 launch·capture 양쪽에 똑같이 넣었고, PnR 후에는 실제 클럭 트리 값으로 바뀌었습니다. launch 쪽이 0.539 ns 앞당겨지고 데이터 경로가 0.285 ns 짧아진 효과가 required time 감소(−0.200)보다 커서 slack이 0.624 ns 좋아졌습니다 ([`reports/60_pre_vs_post.rpt`](reports/60_pre_vs_post.rpt)). (Tempus 리포트의 이 경로 slack 7.721은 같은 경로의 `-from/-to` 리포트 값이고, 전체 worst +7.716과 0.005 ns 차이는 path 선택 방식 차이입니다.)

## 4. Coverage

| Check | Checks | Met | Violated | Untested |
|---|---|---|---|---|
| Setup | 503 | 501 | 0 | 2 |
| Hold | 503 | 501 | 0 | 2 |
| Recovery | 149 | 139 | 0 | 10 |
| Removal | 149 | 139 | 0 | 10 |
| PulseWidth | 835 | 686 | 0 | 149 |
| DataCheckSetup / Hold | 5 / 5 | 0 | 0 | 5 / 5 |
| ExternalDelay (early / late) | 10 / 10 | 10 / 10 | 0 | 0 |

## 5. Untested 분석 — 모두 의도된 것

| Check | Untested | 이유 | 해석 |
|---|---|---|---|
| Setup / Hold | 2 | `const` | `u_reset_sync_aclk/r_meta_ff_reg/D`, `u_reset_sync_sclk/r_meta_ff_reg/D` — 리셋 동기화기 첫 FF의 D는 상수 1(tie-high)이라 검사할 데이터 변화가 없음 |
| Recovery | 10 | 4 `False Path` + 6 `const` | 리셋 동기화기 FF 4개는 SDC에서 false path(비동기 리셋 입력), 나머지 6개는 SN/RN이 상수로 묶인 FF |
| PulseWidth | 149 | 143 `no endpoint clock` + 6 `const` | RN/SN 핀은 클럭 핀이 아니라 클럭 기준 pulse width가 정의되지 않음. CK 핀 쪽 pulse width는 모두 MET |
| DataCheck | 5 | `const` | `DFFNSRX`의 SN-vs-RN data check — SN이 상수라 검사 불필요 |

`check_timing` 경고: ACLK no drive(2, 입력 drive 미지정), ARESETn no input delay(비동기 리셋), unconstrained endpoint 32(디버그 출력 `o_dbg_*`와 SN/RN 상수 핀) — 모두 설계 의도입니다 ([`reports/01_check_timing.rpt`](reports/01_check_timing.rpt)).

## Files

```text
15_Post_STA/MMMC/100MHz/
├── README.md
│
├── reports/
│   ├── 00_parasitics.rpt
│   ├── 01_check_timing.rpt
│   ├── 02_coverage.rpt
│   ├── 10_setup_summary.rpt
│   ├── 11_setup_paths.rpt
│   ├── 20_hold_summary.rpt
│   ├── 21_hold_paths.rpt
│   ├── 30_recovery.rpt
│   ├── 31_removal.rpt
│   ├── 40_clock_skew_setup.rpt
│   ├── 41_clock_latency_setup.rpt
│   ├── 42_clock_skew_hold.rpt
│   ├── 50_drv.rpt
│   ├── 60_pre_vs_post.rpt
│   ├── tempus.log
│   ├── untested_datacheck.rpt
│   ├── untested_pulsewidth.rpt
│   ├── untested_recovery.rpt
│   └── untested_setup.rpt
│
├── results/
│   ├── spi_bridge_top_post_bst.sdf
│   └── spi_bridge_top_post_wst.sdf
│
└── scripts/
    └── tempus_post_sta.tcl
```

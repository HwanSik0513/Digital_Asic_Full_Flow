# 07. Pre-Layout STA — MMMC / 100MHz

합성 직후 넷리스트의 타이밍을 **Genus**와 **Tempus** 두 툴로 따로 확인했습니다.

| Item | Value |
|---|---|
| Netlist | `04_Synthesis/MMMC/100MHz/results/spi_bridge_top_syn_final.v` |
| Clock | ACLK 10 ns, SCLK = ACLK ÷ 4, **ideal clock** (SDC latency source 0.2 + network 0.2 ns) |
| Constraints | [`constraints/spi_bridge_top.sdc`](constraints/spi_bridge_top.sdc) → [`constraints/spi_bridge_top_syn_final.sdc`](constraints/spi_bridge_top_syn_final.sdc) |
| Tempus script | [`scripts/tempus_pre_sta.tcl`](scripts/tempus_pre_sta.tcl) + [`scripts/tempus_pre.view`](scripts/tempus_pre.view) (legacy mode, `read_view_definition` → `read_verilog` → `set_top_module`) |
| Reports | Genus [`reports/`](reports), Tempus [`reports_tempus/`](reports_tempus) |

## 1. Setup (SS) — Genus vs Tempus

| Item | Genus | Tempus |
|---|---|---|
| Worst path | `u_rx_fifo/r_wr_ptr_gray_rclk_reg_4/CK` → `o_bus_rdata[4]` | 같은 경로 |
| Launch clock arrival | 0.400 ns | 0.400 ns |
| Data path | 2.703 ns | 2.085 ns |
| Required time | 10.200 ns | 9.800 ns |
| **Slack** | **+7.097 ns** | **+7.315 ns** |
| Setup checks | — | 501 met / 0 violated / 2 untested |

두 툴 모두 같은 경로를 worst로 잡았고 판정(MET)도 같습니다. 숫자 차이(+0.218 ns)는 두 가지 때문입니다.

- **Data path −0.618 ns** — Genus는 배선 부하를 추정해 넣지만, Tempus는 SPEF 없이 돌려 배선 지연이 0입니다.
- **Required −0.400 ns** — 출력 포트 검사에서 Genus는 capture 쪽에도 ideal clock latency(0.4 ns)를 더했고, Tempus는 더하지 않았습니다.

배선이 없는 단계라 두 값 모두 추정치이며, 실제 값은 PnR 후 Tempus Post-STA(+7.716 ns, [15_Post_STA](../../../15_Post_STA/MMMC/100MHz))입니다.

## 2. Hold (FF) — 참고용

| Check | Met | Violated | Untested |
|---|---|---|---|
| Hold | 365 | 136 | 2 |
| Removal | 100 | 39 | 10 |
| ExternalDelay (early) | 0 | 10 | 0 |

Hold 위반이 많이 보이지만 **이 단계에서는 의미가 없는 숫자**입니다.

- worst 20개 중 13개가 `i_bus_wdata`, `i_bus_wr_en`, `i_bus_rd_en` 입력 → 레지스터 경로입니다 (worst −0.373 ns). ideal clock 상태에서는 capture FF에 SDC network latency 0.2 ns가 그대로 더해지는데, 입력 min delay는 0.01 ns라 hold가 깨진 것으로 계산됩니다.
- 나머지는 CDC 동기화기(`*_gray_meta_*`, `r_dst_meta`)와 FIFO Gray 포인터 경로입니다.
- 클럭 트리가 생기면 SDC의 ideal latency 대신 실제 latency가 들어가므로 결과가 완전히 바뀝니다. 실제로 PnR에서는 CTS 직후 hold 위반이 16개였고, hold fix 후 0개가 되었습니다 → [11_CTS](../../../11_CTS/MMMC/100MHz), [16_Timing_Closure](../../../16_Timing_Closure/MMMC/100MHz).

이것이 hold를 합성 단계가 아니라 CTS 이후에 고치는 이유입니다.

## 3. check_timing

| Warning | Count | 해석 |
|---|---|---|
| ideal_clock_waveform | 4 | CTS 전이라 ideal clock (예상된 것) |
| no_drive | 2 | ACLK 입력 drive 미지정 |
| no_input_delay | 2 | ARESETn — 비동기 리셋 입력 |
| uncons_endpoint | 16 | 디버그 출력 `o_dbg_*`, SN/RN 상수 핀 |

## Files

```text
07_Pre_STA/MMMC/100MHz/
├── README.md
│
├── constraints/
│   ├── spi_bridge_top.sdc
│   └── spi_bridge_top_syn_final.sdc
│
├── reports/
│   ├── 05_ACLK_post_syn_map.rpt
│   ├── 05_SCLK_post_syn_map.rpt
│   ├── 06_report_constraint.rpt
│   ├── 07_ACLK_post_syn_opt.rpt
│   ├── 07_SCLK_post_syn_opt.rpt
│   ├── 07_default_post_syn_opt.rpt
│   ├── 10_spi_bridge_top_SYN_clock.rpt
│   ├── 20a_spi_bridge_top_SYN_timing_SS.rpt
│   ├── 20b_spi_bridge_top_SYN_timing_FF.rpt
│   ├── syn_opt_time_FUNC_FF_BEST.rpt
│   └── syn_opt_time_FUNC_SS_WORST.rpt
│
├── reports_tempus/
│   ├── 01_check_timing.rpt
│   ├── 02_coverage.rpt
│   ├── 03_clocks.rpt
│   ├── 10_setup_summary.rpt
│   ├── 11_setup_paths.rpt
│   ├── 12_setup_same_path_as_genus.rpt
│   ├── 20_hold_reference.rpt
│   └── 30_drv.rpt
│
└── scripts/
    ├── tempus_pre.view
    └── tempus_pre_sta.tcl
```

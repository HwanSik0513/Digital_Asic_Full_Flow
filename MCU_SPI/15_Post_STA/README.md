# 15. Post-layout STA — Tempus 사인오프

## 실행

```
cd TOP/PNR
tempus -files tempus_post_sta.tcl
```

`read_design ChipFinish.dat` (MMMC 뷰 그대로, 배선 RC 포함) → 리포트 00~60 → Tempus SDF 출력
(`chip_top_post_wst.sdf` SS / `chip_top_post_bst.sdf` FF, 17번 GLS에 사용).

## 결과

| 검사 | 뷰 | WNS | 위반 | 최악 경로 |
|---|---|---|---|---|
| Setup | SS | **+0.676 ns** | 0 | `u_cpu/r_pc_reg_*` → `u_ram` write enable (PC → ROM → CU → RAM) |
| Hold | FF | **+0.051 ns** | 0 | 동기화기 `meta` → `sync` (플롭 간 직결) |
| Recovery | SS | +8.732 ns | 0 | reset_sync 출력 → 비동기 리셋 핀 |
| Removal | FF | +0.054 ns | 0 | 같은 경로 |
| DRV (tran / cap / fanout) | – | – | 0 | |

### 커버리지 (`02_coverage.rpt`)

| 항목 | untested | 이유 |
|---|---|---|
| setup / hold | 20 | CDC 동기화기 첫 단(Gray 포인터 meta, pulse_sync, busy meta) — `set_clock_groups -asynchronous`로 의도적으로 제외 |
| recovery / removal | 9 | reset_sync 첫 단 — 비동기 `ARESETn` false path |

untested는 전부 의도한 CDC/리셋 경계이고, 그 안전성은 구조(2-FF, Gray)로 보장합니다.

## Pre vs Post (`60_pre_vs_post.rpt`)

| 같은 경로 (`r_pc_reg_4` → TX 데이터 레지스터) | Genus (합성) | Tempus (PnR) |
|---|---|---|
| Slack | +0.0014 ns | **+1.176 ns** |

합성 최악 경로는 Innovus 최적화로 여유가 생기고, PnR 후 최악 경로는 PC → RAM write enable로 바뀌었습니다.

## SDF 코너 비교 (`17_Post_Layout_Sim/results/sclk_to_miso_delay.md`)

| | SS (wst) | FF (bst) | 비 |
|---|---|---|---|
| SCLK 핀 → MISO 핀 | 2.135 ns | 0.610 ns | ≈ 3.5 × |

## 리포트

```
00_parasitics  01_check_timing  02_coverage
10_setup_summary  11_setup_paths  14_setup_io
20_hold_summary   21_hold_paths
30_recovery  31_removal
40_clock_skew_setup  41_clock_latency_setup  42_clock_skew_hold
50_drv  60_pre_vs_post
```

## 파일

```
15_Post_STA/
├── README.md
├── scripts/   tempus_post_sta.tcl
├── reports/   00 ~ 60 (15개)
└── results/   chip_top_post_wst.sdf, chip_top_post_bst.sdf
```

# 16. Timing Closure — FAST / 1GHz

| Item | Value |
|---|---|
| Corner (synthesis library) | **FAST** — `fast_vdd1v0 (FF, 1.1 V, 0 °C)` |
| Clock | **ACLK 1 ns (1 GHz)**, SCLK = ACLK ÷ 4 (generated clock) |
| 최적화 명령 | `place_opt_design`, `ccopt_design`, `optDesign -postCTS (-hold)`, `optDesign -postRoute -drv / -setup / -hold` |
| 요약 리포트 | [`reports/timing_closure_summary.rpt`](reports/timing_closure_summary.rpt) |
| 결과 | **setup FAIL / hold FAIL** |

> **비교 실험 설계** — 같은 RTL을 SLOW(`slow_vdd1v0`, SS) / FAST(`fast_vdd1v0`, FF) 라이브러리로 각각 합성하고, PnR은 6개 실행 모두 같은 조건(MMMC setup `FUNC_SS_WORST` SS/125 °C, hold `FUNC_FF_BEST` FF/0 °C, 같은 스크립트)으로 구현했습니다. 차이는 입력 넷리스트의 **합성 코너**뿐이며, 합성 코너가 setup 검사 코너(SS)와 같을 때(SLOW)와 다를 때(FAST)를 비교합니다.

---

## 1. Stage-by-Stage

| Stage | Setup WNS | Setup TNS | Setup viol | Hold WNS | Hold TNS | Hold viol | Density |
|---|---|---|---|---|---|---|---|
| place (initial) | -3.311 | -145.036 | 137 | - | - | - | 69.96 % |
| place_opt | -0.504 | -10.209 | 70 | - | - | - | 92.22 % |
| preCTS | -0.694 | -13.508 | 84 | - | - | - | 92.35 % |
| postCTS | -0.481 | -17.594 | 89 | - | - | - | 95.03 % |
| postCTS opt (pre hold fix) | -0.513 | -18.062 | 90 | -0.095 | -1.196 | 16 | — |
| postCTS opt | -0.513 | -18.062 | 90 | -0.095 | -1.196 | 16 | 95.05 % |
| postRoute DRV opt (OCV) | -0.571 | -9.481 | 44 | - | - | - | — |
| postRoute setup opt (start) | -0.481 | -16.782 | 88 | - | - | - | — |
| postRoute hold opt (start) | - | - | - | -0.091 | -1.115 | 16 | — |
| postRoute final | -0.481 | -16.865 | 88 | -0.091 | -1.115 | 16 | 95.15 % |

단위: ns. "postRoute DRV opt"는 OCV 모드·RC 추출 전 값이라 다른 행과 조건이 다릅니다.

## 2. Cells Added

| Step | Cells |
|---|---|
| place_opt_design (instances +) | 359 (806 → 1165) |
| ccopt_design (clock tree) | 22 |
| optDesign -postCTS -hold | 0 |
| optDesign -postRoute -hold | 0 |
| Final (RouteDesign) | 1198 instances |

## 3. Observations

- 배치 직후 setup 위반 137개(WNS -3.311 ns)가 있었고, place_opt 후 70개(WNS -0.504 ns)로 줄었습니다.
- place_opt 후 density가 92.22 %까지 올라 셀 추가·크기 증가가 많았습니다.
- CTS 후 hold 위반 16개(WNS -0.095 ns)가 나타났고, density가 최대 허용치 95.000 %를 넘어 hold 수정이 중단되어 16개가 그대로 남았습니다.
- 최종적으로 setup 위반 88개(WNS -0.481 ns), hold 위반 16개가 남아 **이 주파수에서는 타이밍이 닫히지 않았습니다.** RTL 파이프라인 추가, 합성 제약 강화, floorplan utilization 조정 등이 필요합니다.
- **합성 코너 비교 (FAST vs SLOW, 1GHz)** — FAST는 FF 조건 합성 slack 109.4 ps였지만, SS로 검사한 배치 직후 setup WNS는 -3.311 ns(137개 위반)였습니다. 같은 주파수 SLOW는 배치 직후 -0.854 ns(92개 위반)였습니다. place_opt에서 늘어난 인스턴스는 FAST +359 / SLOW +154, place_opt 후 density는 FAST 92.22 % / SLOW 74.23 %입니다. 합성 코너가 PnR 검사 코너와 다르면 그만큼을 PnR에서 보정해야 합니다. → [SLOW/1GHz](../../SLOW/1GHz)
- 최종 타이밍은 SI·OCV 미적용 Innovus 결과이며 Tempus/Quantus signoff 결과는 아닙니다.

## Analysis

### A.1 WNS Trend

![](images/01_WNS_Trend.png)

- **What** — 배치부터 라우팅까지 setup / hold WNS 변화
- **Observe** — setup: -3.311 → -0.504 → -0.694 → -0.481 → -0.513 → -0.481 ns
- **Observe** — hold: -0.095 → -0.095 → -0.091 → -0.091 ns
- **Insight** — 최종 값이 음수로 남아 이 주파수에서는 닫히지 않았습니다.

### A.2 Instance Growth

![](images/02_Instance_Growth.png)

- **What** — 단계별 인스턴스 수와 추가된 셀
- **Observe** — 806 → 1165 → 1195 → 1198
- **Observe** — place_opt +359, CTS 22, hold fix 0 + 0
- **Insight** — place_opt에서 늘어난 셀 수가 합성 넷리스트와 PnR 검사 조건 사이의 차이를 보여줍니다.


## 4. Images

| | |
|---|---|
| ![](images/01_WNS_Trend.png) | **01 WNS trend** — 단계별 setup / hold WNS |
| ![](images/02_Instance_Growth.png) | **02 Instance growth** — 단계별 인스턴스 수와 추가된 셀 |

## Files

```text
16_Timing_Closure/FAST/1GHz/
├── README.md
│
├── reports/
│   ├── optDesign_postCTS_hold.log
│   ├── optDesign_postRoute.log
│   └── timing_closure_summary.rpt
│
└── images/
    ├── 01_WNS_Trend.png
    └── 02_Instance_Growth.png
```

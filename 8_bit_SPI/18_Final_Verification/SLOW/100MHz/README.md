# 18. Final Verification — SLOW / 100MHz

| Item | Value |
|---|---|
| Corner (synthesis library) | **SLOW** — `slow_vdd1v0 (SS, 0.9 V, 125 °C)` |
| Clock | **ACLK 10 ns (100 MHz)**, SCLK = ACLK ÷ 4 (generated clock) |
| Tool | Cadence Innovus 22.17 (`verify_drc`, `verifyConnectivity`) |
| Script | [`scripts/5_ChipFinish.tcl`](scripts/5_ChipFinish.tcl) |
| DB | `RouteDesign` → `ChipFinish` |

---

## 1. Filler

| Cell | FILL32 | FILL16 | FILL8 | FILL4 | FILL2 | FILL1 | **Total** |
|---|---|---|---|---|---|---|---|
| Count | 9 | 27 | 92 | 257 | 417 | 369 | **1,171** |

인스턴스: 981 (route 후) → 2152 (filler 포함)

## 2. Verification

| Check | Result | Evidence |
|---|---|---|
| verify_drc (route 후) | **0 violations** | [12_Routing](../../../12_Routing/SLOW/100MHz/reports/route_drc.rpt) |
| verify_drc (filler 후) | **0 violations** | [`reports/final_drc.rpt`](reports/final_drc.rpt) |
| verifyConnectivity -geomConnect | **no problems / no warnings** | [`reports/final_connectivity.rpt`](reports/final_connectivity.rpt) |
| PG connectivity | 0 / 0 | [09_Floorplan](../../../09_Floorplan/SLOW/100MHz/reports/powerplan.log) |
| Setup / hold (post-route) | +7.728 / +0.004 ns — **PASS / PASS** | [15_Post_STA](../../../15_Post_STA/SLOW/100MHz) |
| **LVS** | **미실행** | — |

- 위 DRC는 Innovus `verify_drc`(LEF 기반 routing DRC) 결과이며 foundry rule deck 기반 physical DRC가 아닙니다.
- GDS는 표준 셀 GDS를 merge하지 않고 출력했습니다.

## Analysis

### A.1 Chip Finish

![](images/01_ChipFinish_Innovus.png)

- **What** — filler 삽입 후 최종 레이아웃
- **Observe** — filler 1,171개로 빈 site를 채움, 인스턴스 2,152개

### A.2 Verification Checklist

![](images/02_Verification_Checklist.png)

- **What** — 검사 항목·결과·근거 파일
- **Observe** — DRC 0 / 0, connectivity clean
- **Observe** — setup PASS, hold PASS, LVS 미실행
- **Insight** — Innovus 기준 물리 검증과 타이밍을 모두 통과했습니다. LVS와 signoff DRC는 남은 단계입니다.


## 3. Images

| | |
|---|---|
| ![](images/01_ChipFinish_Innovus.png) | **01 Chip Finish** — filler 삽입 후 최종 레이아웃 |
| ![](images/02_Verification_Checklist.png) | **02 Checklist** — 검사 항목·결과·근거 |

> route 후 DRC 화면은 [12_Routing](../../../12_Routing/SLOW/100MHz/images/02_DRC_Check_Innovus.png)에 있습니다.

## Files

```text
18_Final_Verification/SLOW/100MHz/
├── README.md
│
├── scripts/
│   └── 5_ChipFinish.tcl
│
├── reports/
│   ├── chipfinish.log
│   ├── final_connectivity.rpt
│   └── final_drc.rpt
│
├── images/
│   ├── 01_ChipFinish_Innovus.png
│   └── 02_Verification_Checklist.png
│
└── results/
    └── chipfinish.def
```

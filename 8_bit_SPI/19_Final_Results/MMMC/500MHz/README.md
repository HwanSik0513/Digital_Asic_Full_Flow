# 19. Final Results — MMMC / 500MHz

| Item | Value |
|---|---|
| Clock | **ACLK 2.0 ns (500 MHz)**, SCLK = ACLK ÷ 4 (generated clock) |
| Run | Fmax 실험 (2.0 ns) |
| Setup WNS (SS) | **+0.083 ns** |
| Hold WNS (FF) | **+0.006 ns** |
| DRC / connectivity | 0 / 0 |
| Instances | 975 (+1,152 filler) |
| Die / core | 92.80 × 90.25 / 72.80 × 70.11 µm |
| Final density | 73.85 % |
| Power (vectorless, activity 0.2) | **331.22 µW** (internal 262.62 · switching 68.52 · leakage 0.081) |

> **MMMC PnR** — setup view `FUNC_SS_WORST` (slow_vdd1v0, RC WORST, 125 °C), hold view `FUNC_FF_BEST` (fast_vdd1v0, RC BEST, 0 °C). 입력은 [04_Synthesis/MMMC](../../../04_Synthesis/MMMC)의 같은 주파수 넷리스트와 SDC입니다. 전체 흐름은 `all.tcl` 한 번 실행 (BUFX2 사용 금지 가드 포함).

---

## Analysis

### A.1 Final Summary / Power

![](images/01_Final_Summary_Power.png)

- **What** — 최종 PPA 표와 파워 구성 (`set_default_switching_activity -input_activity 0.2 -period 2.0`)
- **Observe** — internal 79.3 % / switching 20.7 % / leakage 0.02 %
- **Insight** — 파워의 약 80 %가 셀 내부(internal) 전력입니다. 주파수가 오를수록 전체 파워가 함께 커집니다 (100 MHz 60.6 → 500 MHz 331.2 → 625 MHz 422.2 µW).

### A.2 Chip Finish Layout

![](images/02_ChipFinish_Innovus.png)

- **What** — 최종 레이아웃 (filler 포함)
- **Observe** — die 92.80 × 90.25 µm

## Outputs

| File | 용도 |
|---|---|
| [`results/spi_bridge_top.gds`](results/spi_bridge_top.gds) | 레이아웃 (표준셀은 이름 참조만, 셀 레이아웃 merge 안 함) |
| [`results/spi_bridge_top_pnr.v`](results/spi_bridge_top_pnr.v) | PnR 넷리스트 (flat) → Post LEC, SPEF STA |
| [`results/spi_bridge_top_pnr.sdc`](results/spi_bridge_top_pnr.sdc) | PnR SDC (`writeTimingCon`) |
| [`results/spi_bridge_top.sdf`](results/spi_bridge_top.sdf) | Innovus SDF |
| [`results/chipfinish.def`](results/chipfinish.def) | 최종 DEF |

## Files

```text
19_Final_Results/MMMC/500MHz/
├── README.md
│
├── images/
│   ├── 01_Final_Summary_Power.png
│   └── 02_ChipFinish_Innovus.png
│
├── reports/
│   ├── innovus.log
│   └── power.rpt
│
└── results/
    ├── chipfinish.def
    ├── spi_bridge_top.gds
    ├── spi_bridge_top.sdf
    ├── spi_bridge_top_pnr.sdc
    └── spi_bridge_top_pnr.v
```

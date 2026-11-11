# 19. Final Results — MMMC / 500MHz

| Item | Value |
|---|---|
| Clock | **ACLK 2.0 ns (500 MHz)**, SCLK = ACLK ÷ 4 |
| Tool | Cadence Innovus 22.17 |
| Setup WNS (SS) | **+0.083 ns** |
| Hold WNS (FF) | **+0.006 ns** |
| DRC / connectivity | 0 / 0 |
| Instances | 975 (filler 제외) |
| Die | 92.8 × 90.25 µm |
| Final density | 73.847 % |
| Power (vectorless, input activity 0.2) | **331.2 µW** (internal 262.6 · switching 68.5 · leakage 0.081 µW) |

![](images/01_ChipFinish_Innovus.png)

| Output | 용도 |
|---|---|
| [`results/spi_bridge_top.gds`](results/spi_bridge_top.gds) | 레이아웃 (표준셀은 이름 참조만, 셀 레이아웃 merge 안 함) |
| [`results/spi_bridge_top_pnr.v`](results/spi_bridge_top_pnr.v) | PnR 넷리스트 (flat) → Post LEC |
| [`results/spi_bridge_top_pnr.sdc`](results/spi_bridge_top_pnr.sdc) | PnR SDC |
| [`results/spi_bridge_top.sdf`](results/spi_bridge_top.sdf) | Innovus SDF |
| [`results/chipfinish.def`](results/chipfinish.def) | 최종 DEF |

## Files

```text
19_Final_Results/MMMC/500MHz/
├── README.md
│
├── images/
│   └── 01_ChipFinish_Innovus.png
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

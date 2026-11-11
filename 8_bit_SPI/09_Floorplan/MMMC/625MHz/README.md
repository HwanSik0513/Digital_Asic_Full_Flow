# 09. Floorplan & Power Plan — MMMC / 625MHz

| Item | Value |
|---|---|
| Clock | **ACLK 1.6 ns (625 MHz)**, SCLK = ACLK ÷ 4 |
| Tool | Cadence Innovus 22.17 |
| Script | [`scripts/0_InitDesign.tcl`](scripts/0_InitDesign.tcl), [`scripts/1_PowerPlan.tcl`](scripts/1_PowerPlan.tcl) (실행: [`scripts/all.tcl`](scripts/all.tcl)) |
| MMMC | [`scripts/spi_bridge_top.mmmc.tcl`](scripts/spi_bridge_top.mmmc.tcl) |

> **MMMC PnR** — setup view `FUNC_SS_WORST` (slow_vdd1v0, RC WORST, 125 °C), hold view `FUNC_FF_BEST` (fast_vdd1v0, RC BEST, 0 °C). 입력은 [04_Synthesis/MMMC](../../../04_Synthesis/MMMC)의 같은 주파수 넷리스트와 SDC입니다. 전체 흐름은 `all.tcl` 한 번 실행 (BUFX2 사용 금지 가드 포함).

## Result

| Item | Value |
|---|---|
| Floorplan | `floorPlan -site CoreSite -r 1.0 0.7 10 10 10 10` (aspect 1.0, core util 0.7, margin 10 µm) |
| Die | 98.2 × 95.38 µm |
| Core (placeable) | 5,883 µm² |
| 초기 배치 밀도 | 69.37 % |
| Power | VDD/VSS ring + stripe (Metal10/11) + follow-pin rail |

**Fmax run.** 합성 slack 0 ps, preCTS에서 −10 ps였지만 CTS 후 실제 클럭 트리 기준 최적화와 post-route 최적화로 +35 ps에 닫혔습니다.

| | |
|---|---|
| ![](images/01_Floorplan_Innovus.png) | **01** floorplan — core row와 IO 핀 |
| ![](images/02_PowerPlan_Innovus.png) | **02** power plan — ring, stripe, rail |

## Files

```text
09_Floorplan/MMMC/625MHz/
├── README.md
│
├── images/
│   ├── 01_Floorplan_Innovus.png
│   └── 02_PowerPlan_Innovus.png
│
├── results/
│   ├── initial_floorplan.def
│   └── powerplan.def
│
└── scripts/
    ├── 0_InitDesign.tcl
    ├── 1_PowerPlan.tcl
    ├── all.tcl
    ├── capture.tcl
    └── spi_bridge_top.mmmc.tcl
```

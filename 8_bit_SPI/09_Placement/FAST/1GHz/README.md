# 09. Placement — FAST / 1GHz

| Item | Value |
|---|---|
| Corner (synthesis library) | **FAST** — `fast_vdd1v0 (FF, 1.1 V, 0 °C)` |
| Clock | **ACLK 1 ns (1 GHz)**, SCLK = ACLK ÷ 4 (generated clock) |
| Tool | Cadence Innovus 22.17 |
| Script | [`scripts/2_PlaceOpt.tcl`](scripts/2_PlaceOpt.tcl) |
| DB | `PowerPlan` → `PlaceOpt` |

> **비교 실험 설계** — 같은 RTL을 SLOW(`slow_vdd1v0`, SS) / FAST(`fast_vdd1v0`, FF) 라이브러리로 각각 합성하고, PnR은 6개 실행 모두 같은 조건(MMMC setup `FUNC_SS_WORST` SS/125 °C, hold `FUNC_FF_BEST` FF/0 °C, 같은 스크립트)으로 구현했습니다. 차이는 입력 넷리스트의 **합성 코너**뿐이며, 합성 코너가 setup signoff 코너(SS)와 같을 때(SLOW)와 다를 때(FAST)를 비교합니다.

---

## 1. Flow

```text
place_design (cong effort high) → checkPlace → earlyGlobalRoute → reportCongestion
      ↓
density map / pin density map
      ↓
place_opt_design → fix_bufx2 (swap guard) → addTieHiLo → earlyGlobalRoute → timeDesign -preCTS
      ↓
checkDesign -place → saveDesign PlaceOpt
```

## 2. Placement

| Item | Value |
|---|---|
| place_design | 806 placed / 0 unplaced, density 69.95 % (3,397 / 4,856) |
| checkPlace | No violations |
| eGR overflow (first / last) | 0.00 % H, 0.00 % V / 0.00 % H, 0.00 % V |
| eGR estimated wire length (first / last) | 11,577 µm / 91 µm |
| Congestion hotspot (max / total) | 0.00 / 0.00 |
| Instances after place_opt | 1165 (InitDesign 806, **+359**) |

## 3. Timing through Placement (setup, SS / 125 °C)

| Step | WNS (ns) | TNS (ns) | Violating / All | DRV max_tran | Density |
|---|---|---|---|---|---|
| place_design (initial) | **-3.311** | -145.036 | 137 / 650 | 83 nets (725 terms) | 69.96 % |
| place_opt_design (final) | -0.504 | -10.209 | 70 / 650 | 0 nets | 92.22 % |
| **timeDesign -preCTS** | **-0.694** | -13.508 | 84 / 650 | 0 nets | 92.35 % |

| preCTS group | WNS (ns) | TNS (ns) | Violating |
|---|---|---|---|
| reg2reg | -0.563 | -8.989 | 65 |
| default | -0.694 | -4.724 | 21 |

preCTS(ideal clock) 기준 setup 위반 84개 경로가 남았습니다. 이후 단계는 [14_Timing_Closure](../../../14_Timing_Closure/FAST/1GHz)에 정리했습니다.
place_opt 이후 density가 92.22 %로 올라갔습니다. 타이밍을 맞추려고 셀 크기를 키우거나 버퍼를 많이 넣은 결과입니다.

## 4. Module Placement

| Module | Instances |
|---|---|
| `u_rx_fifo` | 608 |
| `u_tx_fifo` | 166 |
| `u_register_block` | 134 |
| `u_spi_master` | 109 |
| `u_spi_slave` | 107 |
| `top (glue / sync)` | 26 |
| `u_overflow_pulse_sync` | 6 |
| `u_reset_sync_aclk` | 3 |
| `u_reset_sync_sclk` | 3 |
| `u_sclk_gen` | 3 |

## Analysis

### A.1 Initial Placement

![](images/01_Place_Initial_Innovus.png)

- **What** — place_design 직후
- **Observe** — 806개 셀 모두 배치, density 69.95 %
- **Observe** — setup WNS -3.311 ns (137개 위반)

### A.2 Density Map

![](images/02_Density_Map_Innovus.png)

- **What** — bin별 셀 밀도
- **Observe** — eGR overflow 0.00 % H / 0.00 % V, hotspot 0.00
- **Insight** — overflow와 hotspot이 0이라 배선 혼잡 문제는 없습니다.

### A.3 Pin Density Map

![](images/03_Pin_Density_Map_Innovus.png)

- **What** — bin별 셀 핀 밀도
- **Observe** — 핀이 몰린 영역이 배선 혼잡 후보

### A.4 After place_opt_design

![](images/04_Place_Opt_Innovus.png)

- **What** — 타이밍·DRV 최적화 후
- **Observe** — 인스턴스 806 → 1165 (+359)
- **Observe** — density 92.22 %, setup WNS -0.504 ns
- **Insight** — density가 92.22 %까지 올라 이후 hold 버퍼를 넣을 여유가 줄었습니다.

### A.5 Module Regions (Amoeba)

![](images/05_Module_Amoeba_Innovus.png)

- **What** — 모듈별 배치 영역
- **Observe** — 계층별로 셀이 모여 배치된 모습

### A.6 Placement by Module

![](images/06_Placement_By_Module.png)

- **What** — 인스턴스 위치를 모듈별 색으로 표시 (DEF)
- **Observe** — 인스턴스가 많은 모듈: `u_rx_fifo` 608, `u_tx_fifo` 166, `u_register_block` 134

### A.7 Setup WNS through Placement

![](images/07_PlaceOpt_WNS.png)

- **What** — 배치 단계별 setup WNS
- **Observe** — initial -3.311 → place_opt -0.504 → preCTS -0.694 ns
- **Insight** — preCTS에서도 84개 위반이 남았습니다.


## 5. Images

| | |
|---|---|
| ![](images/01_Place_Initial_Innovus.png) | **01 place_design** |
| ![](images/02_Density_Map_Innovus.png) | **02 Density map** |
| ![](images/03_Pin_Density_Map_Innovus.png) | **03 Pin density map** |
| ![](images/04_Place_Opt_Innovus.png) | **04 place_opt_design** 후 |
| ![](images/05_Module_Amoeba_Innovus.png) | **05 Amoeba view** — 모듈별 배치 영역 |
| ![](images/06_Placement_By_Module.png) | **06 Placement by module** |
| ![](images/07_PlaceOpt_WNS.png) | **07 Setup WNS** — 배치 단계별 |

> 01–05는 Innovus 캡처, 06은 `results/placeopt.def`, 07은 로그·summary 수치로 그린 그림입니다.

## Files

```text
09_Placement/FAST/1GHz/
├── README.md
│
├── scripts/
│   └── 2_PlaceOpt.tcl
│
├── reports/
│   ├── timing_preCTS/
│   │   ├── spi_bridge_top_preCTS.summary
│   │   ├── spi_bridge_top_preCTS_default.tarpt
│   │   ├── spi_bridge_top_preCTS_reg2reg.tarpt
│   │   └── spi_bridge_top_preCTS_tdgp_reg2reg_default.tarpt
│   ├── checkDesign_place.rpt
│   ├── checkPlace.rpt
│   └── placement.log
│
├── images/
│   ├── 01_Place_Initial_Innovus.png
│   ├── 02_Density_Map_Innovus.png
│   ├── 03_Pin_Density_Map_Innovus.png
│   ├── 04_Place_Opt_Innovus.png
│   ├── 05_Module_Amoeba_Innovus.png
│   ├── 06_Placement_By_Module.png
│   └── 07_PlaceOpt_WNS.png
│
└── results/
    └── placeopt.def
```

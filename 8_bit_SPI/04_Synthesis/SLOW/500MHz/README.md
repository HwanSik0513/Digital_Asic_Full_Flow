# 04. Logic Synthesis — SLOW / 500MHz

| Item | Value |
|---|---|
| Corner (synthesis library) | **SLOW** — `slow_vdd1v0 (SS, 0.9 V, 125 °C)` |
| Clock | **ACLK 2 ns (500 MHz)**, SCLK = ACLK ÷ 4 (generated clock) |
| Tool | Cadence Genus 22.17 |
| Operating condition | `PVT_0P9V_125C` |
| Script | [`scripts/spi_bridge_top_45nm_SLOW.tcl`](scripts/spi_bridge_top_45nm_SLOW.tcl) (run: [`scripts/run_synthesis`](scripts/run_synthesis)) |
| Output | `results/spi_bridge_top_syn_final.v` → PnR 입력 넷리스트 |

---

## 1. Flow

```text
read_libs (slow_vdd1v0_basicCells.lib) / read_physical (LEF) / read_qrc
      ↓
read_hdl (8 RTL files) → elaborate → uniquify → check_design
      ↓
source spi_bridge_top.sdc + dont_use_45nm.tcl → check_timing_intent
      ↓
syn_generic (effort high) → syn_map (high) → syn_opt (high)
      ↓
report_* (area / gates / power / qor / timing) → write_hdl / write_sdc / write_sdf
```

`auto_ungroup none`(계층 유지), `optimize_merge_flops false`. SLOW와 FAST 스크립트의 차이는 `LIB_LIST`의 표준 셀 라이브러리 한 줄뿐입니다.

## 2. Result (syn_opt)

| Item | Value |
|---|---|
| ACLK worst slack / TNS / violating | **1.8 ps** / 0.0 ps / 0 |
| SCLK worst slack / TNS / violating | 673.1 ps / 0.0 ps / 0 |
| Leaf instances | 881 (sequential 343, combinational 538) |
| Cell area / net area / total | 3,621.438 / 1,045.000 / **4,666.438 µm²** |
| Max / average fanout | 240 (o_dbg_sclk) / 2.4 |
| Power (Genus, default activity) | 294.64 µW (internal 76.4 %, switching 23.6 %, leakage 75.3 nW) |
| Design rules | Max_transition no violations, Max_capacitance no violations, Max_fanout no constraints |
| Runtime | 47 s (generic 00:00:19 / map 00:00:14 / opt 00:00:05) |

## 3. QoS by Stage (`report/final.rpt`)

| Metric | syn_generic | syn_map | syn_opt |
|---|---|---|---|
| Worst slack (ps) | -13 | 14 | **2** |
| TNS (ps) | -26 | 0 | 0 |
| Failing paths | 2 | 0 | 0 |
| Cell area (µm²) | 5,463 | 3,671 | 3,621 |
| Leaf instances | 1,272 | 904 | 881 |

## 4. Cell Composition

| Type | Instances | Area (µm²) | Area % |
|---|---|---|---|
| sequential | 343 | 2,520.540 | 69.6 |
| inverter | 24 | 21.204 | 0.6 |
| buffer | 10 | 18.810 | 0.5 |
| logic | 504 | 1,060.884 | 29.3 |

| Module | Cells | Cell area | Net area | Total (µm²) |
|---|---|---|---|---|
| `u_rx_fifo` | 428 | 1,931.958 | 452.853 | 2,384.811 |
| `u_tx_fifo` | 126 | 610.470 | 127.263 | 737.733 |
| `u_spi_master` | 102 | 360.126 | 112.667 | 472.793 |
| `u_spi_slave` | 102 | 343.026 | 103.202 | 446.228 |
| `u_register_block` | 106 | 287.622 | 94.440 | 382.062 |
| `u_overflow_pulse_sync` | 6 | 30.096 | 4.428 | 34.524 |
| `u_sclk_gen` | 3 | 15.732 | 2.224 | 17.956 |
| `u_reset_sync_aclk` | 2 | 15.732 | 0.741 | 16.473 |
| `u_reset_sync_sclk` | 2 | 12.312 | 0.741 | 13.053 |

## 5. Checks

| check_design | Count |
|---|---|
| Unloaded Sequential Pin(s) | 9 |
| Unloaded Combinational Pin(s) | 3 |
| Assigns | 2 |
| Constant hierarchical Pin(s) | 64 |
| Libcells with no LEF cell | 4 |
| Physical (LEF) cells with no libcell | 107 |

그 외 unresolved reference, multidriven, undriven 항목은 모두 0입니다 → [`reports/00_check_design.rpt`](reports/00_check_design.rpt)

## 6. Notes

- **SLOW는 합성 코너와 PnR setup 검사 코너가 같은(SS, 0.9 V, 125 °C) 기준 실행입니다.** 합성에서 맞춘 타이밍이 PnR 검사 조건과 같은 기준이라, 비교 대상인 FAST의 기준점이 됩니다.
- 합성 단계에서 setup 위반이 없습니다.
- 전력은 Genus 기본 activity로 계산한 추정값입니다.

## Analysis

### A.1 Generic → Map → Opt

![](images/01_QoS_by_Stage.png)

- **What** — 합성 3단계에서 worst slack, TNS, 셀 면적이 어떻게 바뀌는지
- **Observe** — worst slack -13 → 14 → **2 ps**, failing paths 2 → 0 → 0
- **Observe** — cell area 5,463 → 3,671 → 3,621 µm² (generic 단계는 라이브러리 매핑 전 추정 면적)
- **Insight** — syn_opt 후 setup 위반 없이 합성이 끝났습니다.

### A.2 Area by Module

![](images/02_Area_by_Module.png)

- **What** — 모듈별 cell / net 면적
- **Observe** — `u_rx_fifo`(async_fifo_DATA_WIDTH8_ADDR_WIDTH4)가 2,384.8 µm²로 전체의 53 %
- **Observe** — 그다음 `u_tx_fifo` 737.7 µm², `u_spi_master` 472.8 µm²
- **Insight** — 모듈 이름의 파라미터(`ADDR_WIDTH4` / `ADDR_WIDTH2`)대로 RX FIFO(16 entry)가 TX FIFO(4 entry)보다 저장 플립플롭이 많아 면적 차이가 큽니다.

### A.3 Cell Composition

![](images/03_Cell_Type.png)

- **What** — 셀 종류별 면적 비율과 많이 쓰인 셀
- **Observe** — sequential 343개가 면적의 **69.6 %**
- **Observe** — 가장 많이 쓰인 셀: `EDFFHQX1` 160, `DFFRHQX1` 121, `AOI22X1` 76, `AND2X1` 44
- **Insight** — FIFO 저장 플립플롭이 면적 대부분을 차지하는 레지스터 중심 설계입니다.

### A.4 Power

![](images/04_Power.png)

- **What** — Genus 기본 activity로 계산한 카테고리별 전력
- **Observe** — register 74.7 % / logic 22.1 % / clock 3.2 %, 합계 294.6 µW
- **Observe** — internal 76.4 %, switching 23.6 %, leakage 75.3 nW
- **Insight** — 전력도 플립플롭(register)이 가장 큰 비중을 차지합니다. vectorless 추정값이라 절대값보다 실행 간 비교용으로 보는 것이 맞습니다.


## 7. Images

| | |
|---|---|
| ![](images/01_QoS_by_Stage.png) | **01 QoS by Stage** — generic → map → opt 단계별 slack / TNS / 면적 |
| ![](images/02_Area_by_Module.png) | **02 Area by Module** — 모듈별 cell / net 면적 |
| ![](images/03_Cell_Type.png) | **03 Cell Type** — sequential / logic / inverter / buffer 비율, 많이 쓰인 셀 |
| ![](images/04_Power.png) | **04 Power** — 카테고리별 전력과 구성 |

> 01–04는 `reports/`의 Genus 리포트 수치로 그린 그림입니다. top 계층 schematic(generic / mapped) 캡처는 [SLOW/100MHz](../../SLOW/100MHz/README.md)에 있습니다. 하위 모듈 블록과 IO 연결은 RTL에서 정해지므로 모든 실행이 같고, top 레벨 glue 셀의 종류만 실행마다 다를 수 있습니다.

## Files

```text
04_Synthesis/SLOW/500MHz/
├── README.md
│
├── scripts/
│   ├── dont_use_45nm.tcl
│   ├── run_synthesis
│   ├── spi_bridge_top.sdc
│   └── spi_bridge_top_45nm_SLOW.tcl
│
├── reports/
│   ├── 00_check_design.rpt
│   ├── 03_report_datapath_generic.rpt
│   ├── 04_report_datapath_map.rpt
│   ├── 09_spi_bridge_top_SYN_area.rpt
│   ├── 12_spi_bridge_top_SYN_design_rules.rpt
│   ├── 13_spi_bridge_top_SYN_gate.rpt
│   ├── 14_spi_bridge_top_SYN_hier.rpt
│   ├── 18_spi_bridge_top_SYN_pwr.rpt
│   ├── 19_spi_bridge_top_SYN_qor.rpt
│   ├── cds_syn_runtime
│   ├── final.rpt
│   ├── genus_all.log
│   ├── syn_generic_qor.rpt
│   ├── syn_map_qor.rpt
│   └── syn_opt_qor.rpt
│
├── images/
│   ├── 01_QoS_by_Stage.png
│   ├── 02_Area_by_Module.png
│   ├── 03_Cell_Type.png
│   └── 04_Power.png
│
└── results/
    ├── spi_bridge_top_delays.sdf
    ├── spi_bridge_top_syn_final.sdc
    └── spi_bridge_top_syn_final.v
```

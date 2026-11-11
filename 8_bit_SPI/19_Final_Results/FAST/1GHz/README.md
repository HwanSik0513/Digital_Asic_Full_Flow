# 19. Final Results — FAST / 1GHz

| Item | Value |
|---|---|
| Corner (synthesis library) | **FAST** — `fast_vdd1v0 (FF, 1.1 V, 0 °C)` |
| Clock | **ACLK 1 ns (1 GHz)**, SCLK = ACLK ÷ 4 (generated clock) |
| Flow | Genus 22.17 → Innovus 22.17 (GPDK045 `gsclib045`) |
| Final DB | `ChipFinish` |
| 요약 | [`reports/final_summary.rpt`](reports/final_summary.rpt) |

---

## 1. Result at a Glance

| Category | Item | Result |
|---|---|---|
| Synthesis | Cell area / instances | 3,397.428 µm² / 806 |
| Physical | Die / core | 91.00 × 88.54 / 71.00 × 68.40 µm |
| | Instances | 1198 (filler 제외) / 1657 (filler 459 포함) |
| | Density | 69.96 % (초기) → 95.15 % (최종) |
| Clock tree | CTS cells / skew | 22 / 0.585 ns |
| Routing | Wire / vias | 14,824 µm / 7,927 |
| **Timing** | **Setup WNS / TNS** (SS) | **-0.481 ns / -16.865** (88 viol) |
| | **Hold WNS / TNS** (FF) | **-0.091 ns / -1.115** (16 viol) |
| | 판정 | **setup FAIL / hold FAIL** |
| Verification | DRC / connectivity / LVS | 0 / clean / 미실행 |
| Power | Total (static, vectorless) | 746.5 µW (internal 77.0 %, switching 23.0 %) |

## 2. SLOW vs FAST (1GHz)

| Item | FAST (this) | SLOW |
|---|---|---|
| Synthesis lib | `PVT_1P1V_0C` | `PVT_0P9V_125C` |
| Synthesis ACLK slack | 109.4 ps | -608.2 ps |
| Cell area (synthesis) | 3,397.4 µm² | 4,579.7 µm² |
| Final instances | 1198 | 1332 |
| Final density | 95.15 % | 80.55 % |
| Setup WNS (PnR, SS) | -0.481 ns | -0.463 ns |
| Hold WNS (PnR, FF) | -0.091 ns | +0.003 ns |
| Power | 746.5 µW | 882.4 µW |

**비교 실험: 합성 코너 vs PnR 검사 코너** — PnR 조건(setup SS / hold FF, 같은 스크립트)은 같고 입력 넷리스트의 합성 코너만 다릅니다. SLOW는 합성 코너 = setup 검사 코너(SS)인 기준 실행이고, FAST는 FF로 합성해 두 코너가 다른 실행입니다.

- 합성 단계: FAST가 셀 면적 3,397.4 µm²로 SLOW(4,579.7 µm²)보다 작고, ACLK slack도 109.4 ps로 SLOW(-608.2 ps)보다 크게 보고됩니다. 다만 FAST의 값은 FF 조건 기준입니다.
- PnR 단계(SS 검사): place_opt에서 늘어난 인스턴스 FAST +359 / SLOW +154, 최종 setup WNS FAST -0.481 / SLOW -0.463 ns.
- 최종 판정: SLOW **setup FAIL**, FAST **setup·hold FAIL**.

합성 단계 결과가 좋아 보여도 PnR 검사 코너와 다른 조건이면 PnR에서 그 차이를 보정해야 하며, 합성 제약은 setup 검사 코너에 맞추는 것이 기본입니다.

## 3. Output Files (`results/`)

| File | 생성 명령 | 용도 |
|---|---|---|
| `spi_bridge_top.gds` | `streamOut -mode ALL -units 2000` | 레이아웃 (표준 셀 GDS 미병합) |
| `spi_bridge_top_pnr.v` | `saveNetlist -flat` | gate-level simulation / STA |
| `spi_bridge_top_pnr_pg.v` | `saveNetlist -flat -includePowerGround` | LVS용 |
| `spi_bridge_top.sdf` / `.sdf_2.1` | `write_sdf` | back-annotated simulation |
| `spi_bridge_top_pnr.sdc` | `writeTimingCon` | P&R 후 constraint |

## 4. Notes

- 타이밍: Innovus `extractRC`(effort low) + single 모드, SI off. Tempus/Quantus signoff 결과는 아닙니다.
- 전력: VCD 없이 input activity 0.2, period 1.0 ns(스크립트가 SDC에서 읽은 ACLK 주기)로 계산한 static 추정값입니다.
- ECO(6_ECO.tcl)는 실행하지 않았습니다.

## Analysis

### A.1 Final Summary / Power

![](images/01_Final_Summary_Power.png)

- **What** — 최종 지표와 전력 구성
- **Observe** — setup -0.481 / hold -0.091 ns, density 95.15 %
- **Observe** — power 746.5 µW (internal 77.0 %)

### A.2 SLOW vs FAST

![](images/02_SLOW_vs_FAST.png)

- **What** — 같은 주파수에서 합성 코너만 다른 두 실행 비교
- **Observe** — setup WNS SLOW -0.463 / FAST -0.481 ns
- **Observe** — 합성 면적 SLOW 4,580 / FAST 3,397 µm²
- **Insight** — FAST는 합성 면적이 작지만 PnR(SS 검사)에서 보정할 양이 더 큽니다. 합성 코너를 PnR 검사 코너에 맞추는 것이 기본입니다.


## 5. Images

| | |
|---|---|
| ![](images/01_Final_Summary_Power.png) | **01 Final summary / power** |
| ![](images/02_SLOW_vs_FAST.png) | **02 SLOW vs FAST** — 같은 주파수의 두 코너 비교 |

> 최종 레이아웃 캡처는 [18_Final_Verification](../../../18_Final_Verification/FAST/1GHz/images/01_ChipFinish_Innovus.png)에 있습니다.

## Files

```text
19_Final_Results/FAST/1GHz/
├── README.md
│
├── reports/
│   ├── final_summary.rpt
│   ├── power_analysis.log
│   └── power_static.rpt
│
├── images/
│   ├── 01_Final_Summary_Power.png
│   └── 02_SLOW_vs_FAST.png
│
└── results/
    ├── spi_bridge_top.gds
    ├── spi_bridge_top.sdf
    ├── spi_bridge_top.sdf_2.1
    ├── spi_bridge_top_pnr.sdc
    ├── spi_bridge_top_pnr.v
    └── spi_bridge_top_pnr_pg.v
```

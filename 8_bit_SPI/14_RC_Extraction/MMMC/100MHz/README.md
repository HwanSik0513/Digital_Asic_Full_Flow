# 14. RC Extraction & SPEF — MMMC / 100MHz

배선이 끝난 설계에서 RC를 추출해 코너별 SPEF로 내보내고, **Innovus DB 없이 넷리스트 + SDC + SPEF만으로** Tempus에서 같은 타이밍이 나오는지 확인했습니다.

| Item | Value |
|---|---|
| Extraction | Innovus 내장 `extractRC` (postRoute, effort low) — Quantus 없음 |
| RC corner | `WORST` (-T 125) / `BEST` (-T 0), 같은 captable · qx tech 파일 |
| SPEF | `spi_bridge_top_worst.spef` (1,032,560 B), `spi_bridge_top_best.spef` (1,034,572 B) — 용량 문제로 저장소에는 미포함 |
| Scripts | [`scripts/spef_out.tcl`](scripts/spef_out.tcl) (Innovus), [`scripts/tempus_spef_sta.tcl`](scripts/tempus_spef_sta.tcl) + [`scripts/tempus_spef.view`](scripts/tempus_spef.view) (Tempus) |
| **결과** | **SPEF 기반 Tempus: setup +7.716 / hold +0.002 ns — Innovus와 동일** |

## 1. Flow

```text
Innovus : restoreDesign RouteDesign.dat → extractRC → rcOut -spef ... -rc_corner WORST / BEST
          → timeDesign (setup / hold) 로 값이 그대로인지 확인
Tempus  : read_view_definition tempus_spef.view   (PnR MMMC + CTS latency 파일)
          read_verilog spi_bridge_top_pnr.v → set_top_module
          setAnalysisMode -analysisType single     (PnR과 같은 분석 모드)
          read_spef -rc_corner WORST / BEST → set_propagated_clock → report_*
```

`rcOut`은 스크립트(`-files`)로 실행했을 때 아무 메시지 없이 건너뛰어져서, Innovus에서 직접 입력해 실행했습니다.

## 2. Result

| Check | Innovus (DB) | Tempus (DB, [15](../../../15_Post_STA/MMMC/100MHz)) | **Tempus (netlist + SPEF)** |
|---|---|---|---|
| Setup WNS (SS) | +7.716 ns | +7.716 ns | **+7.716 ns** |
| Hold WNS (FF) | +0.002 ns | +0.002 ns | **+0.002 ns** |
| Setup / Hold checks met | — | 501 / 501 | **501 / 501** |
| Recovery / Removal met | — | 139 / 139 | **139 / 139** |
| Real nets annotated | 1,030 | 1,030 | **1,030 (100 %)** |

| SPEF 내용 | WORST | BEST |
|---|---|---|
| Resistors | 15,559 | 15,559 |
| Ground caps | 15,867 | 15,867 |
| Coupling caps | 0 (SI off) | 0 |
| Missing nets | 16 (1-term no load) | 16 |

세 방법의 결과가 모두 같으므로, 내보낸 SPEF가 PnR에서 쓴 RC와 같다는 것이 확인되었습니다. 저항·커패시턴스 개수도 Innovus 추출 결과(15,559 / 15,867)와 일치합니다.

## 3. 첫 시도에서 결과가 달랐던 이유

PnR MMMC 파일과 SDC만 읽은 첫 시도([`reports/tempus_spef_try1_no_latency`](reports/tempus_spef_try1_no_latency))는 SPEF annotation은 100 %였지만 타이밍이 달랐습니다.

| | 첫 시도 | 수정 후 |
|---|---|---|
| Setup WNS | +7.181 ns | +7.716 ns |
| Hold WNS | **−0.199 ns (490 위반)** | +0.002 ns (0 위반) |

**원인 1 — CTS 후 latency 갱신이 빠짐.** CTS 뒤 Innovus(CCOpt)는 ACLK 포트의 source latency를 실제 클럭 트리에 맞게 다시 설정합니다(SS −0.139 ns, FF −0.043 ns). 이 값은 SDC가 아니라 `RouteDesign.dat/mmmc/views/<view>/latency.sdc`에 저장되므로, 넷리스트와 SDC만 읽으면 합성 때의 ideal 값(+0.2 ns)이 남습니다. → view 파일에 `-latency_file`을 추가했습니다.

**원인 2 — 분석 모드 차이.** SDC의 source latency는 `-max`만 정의되어 있습니다. PnR은 `single` 모드라 early/late 모두 같은 값을 쓰지만, Tempus 기본 모드에서는 hold 검사의 launch(early)가 0, capture(late)가 0.2 ns를 써서 0.2 ns가 어긋났습니다. 데이터 경로 지연은 두 경우가 완전히 같고 launch 시작점만 0.200 → 0.000이었습니다. → `setAnalysisMode -analysisType single`을 추가했습니다.

> 넷리스트 + SPEF로 signoff STA를 넘길 때는 SPEF뿐 아니라 **CTS 후 갱신된 클럭 latency와 분석 모드**도 함께 맞춰야 같은 결과가 나옵니다.

## 4. Innovus 확인 (SPEF 출력 후)

| | Setup | Hold | Density |
|---|---|---|---|
| `timeDesign` | +7.716 ns, 0 / 650 위반 | +0.002 ns, 0 위반 | 74.704 % |

## 5. Notes

- 로그의 `IMPESI-4001` (single 모드에서 SI 분석 미지원)은 SI를 원래 끈 상태라 영향이 없습니다.
- RC corner별 QRC 파일이 따로 없어 BEST/WORST는 같은 captable에 온도만 다릅니다. 코너 간 지연 차이는 주로 SS/FF 라이브러리에서 나옵니다.

## Files

```text
14_RC_Extraction/MMMC/100MHz/
├── README.md
│
├── logs/
│   └── tempus_spef_sta.log
│
├── reports/
│   ├── tempus_parasitics.rpt
│   ├── innovus_after_spef/
│   │   ├── spi_bridge_top_postRoute.summary
│   │   └── spi_bridge_top_postRoute_hold.summary
│   ├── tempus_spef/
│   │   ├── 00_parasitics.rpt
│   │   ├── 01_check_timing.rpt
│   │   ├── 02_coverage.rpt
│   │   ├── 10_setup_summary.rpt
│   │   ├── 11_setup_paths.rpt
│   │   ├── 20_hold_summary.rpt
│   │   └── 21_hold_paths.rpt
│   └── tempus_spef_try1_no_latency/
│       ├── 00_parasitics.rpt
│       ├── 01_check_timing.rpt
│       ├── 02_coverage.rpt
│       ├── 10_setup_summary.rpt
│       ├── 11_setup_paths.rpt
│       ├── 20_hold_summary.rpt
│       └── 21_hold_paths.rpt
│
└── scripts/
    ├── spef_out.tcl
    ├── spi_bridge_top.mmmc.tcl
    ├── tempus_spef.view
    └── tempus_spef_sta.tcl
```

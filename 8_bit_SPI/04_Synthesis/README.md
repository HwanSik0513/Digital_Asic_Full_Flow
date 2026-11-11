# 04. Logic Synthesis (Genus)

Genus 22.17로 RTL을 GPDK045 표준 셀 넷리스트로 합성합니다. 각 run 폴더에 스크립트, SDC, 리포트, 넷리스트가 있습니다.

| 폴더 | 내용 |
|---|---|
| [`SLOW/`](SLOW) · [`FAST/`](FAST) | **비교 실험** — 같은 RTL을 slow(SS) / fast(FF) 라이브러리 하나로만 합성 |
| [`MMMC/`](MMMC) | **최종 방식** — SS·FF 두 코너를 한 번에 보는 MMMC 합성. 100 MHz 기준 run + 주파수 스윕 |

## Runs

| Run | ACLK slack (SS) | 위반 경로 | Cell area | Leaf cells |
|---|---|---|---|---|
| [SLOW / 100MHz](SLOW/100MHz) | +7,101.2 ps | 0 | 3,506.2 µm² | 837 |
| [SLOW / 500MHz](SLOW/500MHz) | +1.8 ps | 0 | 3,621.4 µm² | 881 |
| [SLOW / 1GHz](SLOW/1GHz) | -608.2 ps | 44 | 4,579.7 µm² | 1024 |
| [FAST / 100MHz](FAST/100MHz) | +9,074.9 ps *(FF 라이브러리)* | 0 | 3,396.4 µm² | 816 |
| [FAST / 500MHz](FAST/500MHz) | +1,109.4 ps *(FF 라이브러리)* | 0 | 3,398.5 µm² | 804 |
| [FAST / 1GHz](FAST/1GHz) | +109.4 ps *(FF 라이브러리)* | 0 | 3,397.4 µm² | 806 |
| **[MMMC / 100MHz](MMMC/100MHz)** | **+7,097 ps** | 0 | 3,513 µm² | 828 |
| [MMMC / 500MHz](MMMC/500MHz) | +11 ps | 0 | 3,571 µm² | 850 |
| [MMMC / 625MHz](MMMC/625MHz) | 0 ps | 0 | 4,117 µm² | 959 |
| [MMMC / 667MHz](MMMC/667MHz) | −25 ps | 5 | 4,360 µm² | 1,014 |
| [MMMC / 714MHz](MMMC/714MHz) | −124 ps | 9 | 4,495 µm² | 1,033 |

## MMMC 스크립트 vs SLOW/FAST 스크립트

| 항목 | SLOW / FAST 스크립트 | MMMC 스크립트 |
|---|---|---|
| 라이브러리 읽기 | `read_libs` — slow **또는** fast 하나 | `read_mmmc` — library set `SS_Max_0p90v_125c`, `FF_Min_1p10v_0c` 둘 다 |
| RC | `read_qrc` 하나 | rc corner `WORST`(125 °C) / `BEST`(0 °C) |
| SDC 적용 | `source spi_bridge_top.sdc` | constraint mode `FUNC`로 등록 → `init_design` |
| 코너 | 실행 1번 = 코너 1개 | 실행 1번에 analysis view 2개 (`FUNC_SS_WORST`, `FUNC_FF_BEST`) |
| Setup 판정 | 읽은 라이브러리 기준 (FAST면 FF로 판정) | **항상 SS** (`set_analysis_view -setup`) |
| 타이밍 리포트 | 1개 | `20a` (SS), `20b` (FF) 코너별 |
| 출력 SDC | `write_sdc` | `write_sdc -view FUNC_SS_WORST` |
| 주의점 | — | SDC 안의 `reset_design`이 MMMC 객체를 지워 TUI-61 오류 → 주석 처리 |

**왜 바꿨나** — FAST 1 GHz는 FF 라이브러리로 합성해 +109 ps로 통과했지만, SS 조건의 PnR에서는 setup −0.481 ns로 깨졌습니다. 합성 코너가 PnR의 setup 검사 코너와 다르면 합성 slack을 믿을 수 없습니다. MMMC는 setup을 SS로 고정하므로 이런 착시가 생기지 않습니다. 코너 선택의 원칙은 **단계가 아니라 검사 종류로** 정합니다: setup은 데이터가 가장 늦은 SS, hold는 가장 빠른 FF입니다.

> 합성 단계의 hold는 ideal clock(skew 0) 기준이라 참고용입니다. 실제 hold 수정은 클럭 트리가 생긴 CTS 이후 PnR에서 합니다 ([16_Timing_Closure](../16_Timing_Closure)).

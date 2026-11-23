# 16. Timing Closure

## 결론: 사인오프 위반 0 → ECO 불필요

| 단계 | Setup WNS (SS) | Hold WNS (FF) |
|---|---|---|
| Genus 합성 | +0.0014 | +7.455 (이상적 클럭) |
| preCTS | +0.351 | – |
| postCTS | +0.268 | +0.051 |
| postCTS opt | +0.293 | +0.051 |
| postRoute opt | +0.677 | +0.051 |
| **Tempus 사인오프** | **+0.676** | **+0.051** |

![wns flow](../19_Final_Results/images/19_setup_wns_flow.png)

Tempus ECO 흐름(`tempus_hold_eco.tcl` → `6_ECO.tcl`)은 준비했지만, 위반이 없으면
`tempus_hold_eco.tcl`이 일찍 끝나도록 해 두어 실제 ECO는 하지 않았습니다.
그래서 13_Post_LEC의 PnR 넷리스트가 최종 넷리스트입니다.

## 실제로 고친 타이밍 문제: `set_ideal_network`이 PnR까지 넘어감

| 항목 | v3 (합성 SDC 그대로) | v4 (PnR SDC) |
|---|---|---|
| CTS 클럭 버퍼 | **0** (인버터 2) | **117** (+ 인버터 2) |
| ACLK skew | 0.000 (모든 플롭 latency 0.400 고정) | **83 ps** |
| SCLK skew | 0.000 | **61 ps** |
| postCTS opt setup | +0.338 | +0.293 |
| postCTS hold | +0.052 | +0.051 |

- **Observe** — v3의 타이밍이 더 좋아 보이지만, 클럭 트리가 없는 상태에서 SDC의 latency 0.400을
  모든 플롭에 똑같이 붙인 **가짜 숫자**입니다. 실제 칩에서 클럭 2,000여 개 싱크를 패드 하나가 직접 구동할 수 없습니다.
- **Insight** — 타이밍이 "좋다"는 것보다 "실제와 같은 조건으로 계산했는가"가 먼저입니다. skew 0.000이
  모든 플롭에 똑같이 찍힌 리포트가 단서였습니다.
- **해결** — `make_pnr_netlist.sh`가 `grep -v "^ *set_ideal_network"`로 PnR SDC를 따로 만들고,
  `chip_top.mmmc.view`가 그것을 읽음 (11_CTS 참고).

## 스크립트 (준비만, 이번에 실행 안 함)

| 파일 | 역할 |
|---|---|
| `tempus_post_sta_eco.tcl` | ECO 후 DB 재검증 (`DB_NAME`, `SDF_TAG` 덮어쓰기) |
| `tempus_hold_eco.tcl` | `opt_signoff -hold` → ECO 파일. 위반 없으면 바로 종료 |
| `6_ECO.tcl` | 새 Innovus 세션에서 ECO 적용 → `ecoRoute` → 저장. `setDontUse BUFX2 true` |

## 파일

```
16_Timing_Closure/
├── README.md
└── scripts/   tempus_hold_eco.tcl, tempus_post_sta_eco.tcl, 6_ECO.tcl
```

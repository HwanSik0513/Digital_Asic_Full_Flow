# 14. RC Extraction

이번 프로젝트는 SPEF 파일을 따로 뽑지 않았습니다. Tempus가 Innovus `ChipFinish.dat`를
`read_design`으로 읽을 때 배선 RC가 함께 들어오고, 그 결과를 `report_annotated_parasitics`로 확인했습니다.

## 결과 (`reports/00_parasitics.rpt`, FUNC_SS_WORST)

| 넷 종류 | 개수 | RC 적용 |
|---|---|---|
| **real net (complete)** | **5,576** | **5,576 (100 %)** |
| real net (broken) | 0 | – |
| 0-term floating | 2,034 | 타이밍 대상 아님 |
| 1-term no load | 17 | 타이밍 대상 아님 |
| assign | 6 | 타이밍 대상 아님 |
| 합계 | 7,633 | 73.05 % (나머지는 전부 타이밍 대상 아닌 넷) |

| 적용된 값 | 개수 | 합계 |
|---|---|---|
| 저항 | 105,733 | 707.9 kΩ |
| 커패시턴스 | 106,486 | 9.733 pF |
| 커플링 커패시턴스 | 0 | 0 (SI 분석 없음) |

- **Observe** — 타이밍을 보는 실제 넷은 100 % 적용, 끊긴 넷 0.
- **Observe** — floating 2,034개는 출력이 연결되지 않은 셀 핀(플롭의 QN 등)으로, 타이밍 대상이 아닙니다.
- **Insight** — 73 %라는 전체 숫자만 보면 부족해 보이지만, 표 아래 주석대로 `(*)` 넷은 원래 타이밍을 보지 않습니다. 사인오프에 필요한 기준은 real net 100 %입니다.

## 한계와 다음 단계

| 항목 | 상태 |
|---|---|
| 추출 엔진 | Innovus 내장(postRoute effort), Quantus QRC 사인오프 추출은 하지 않음 |
| SPEF 파일 | 없음. 필요하면 Innovus `rcOut -spef chip_top.spef -rc_corner <corner>` |
| 커플링 / SI | 없음 (`XCap 0`) |

## 파일

```
14_RC_Extraction/
├── README.md
└── reports/   00_parasitics.rpt  (15_Post_STA와 같은 파일)
```

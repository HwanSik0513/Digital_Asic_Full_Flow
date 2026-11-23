# 05. DFT — 이번 프로젝트에서는 적용하지 않음

스캔 삽입과 ATPG는 진행하지 않았습니다.

| 항목 | 내용 |
|---|---|
| 상태 | 미적용 (스캔 체인 없음, ATPG 없음) |
| 이유 | 이번 목표는 패드를 포함한 칩 레벨 PnR과 CDC 수정이었고, ATPG 툴(Modus)이 사용 가능한 툴 목록에 없음 |
| 영향 | 넷리스트에 스캔 플롭(SDFF)·scan_en·scan 포트가 없음. LEC·STA·GLS는 기능 모드만 확인 |
| 적용한다면 | Genus `define_dft` + `insert_dft scan_chain`, scan_en / scan_in / scan_out 패드 3개 추가 → 패드 수 23개로 다이 크기 재검토, LEC에 scan_en = 0 제약, STA에 shift 모드 추가 |

이전 SPI 프로젝트와 같은 방침입니다.

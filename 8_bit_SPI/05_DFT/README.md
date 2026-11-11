# 05. DFT (Scan Insertion)

**상태: 예정**

| Step | Tool | Plan |
|---|---|---|
| Scan 삽입 | Genus | `define_dft shift_enable` / `test_mode`, `connect_scan_chains`, `report_scan_chains`, scandef 출력 |
| Scan 동작 확인 | Xcelium | ATPG 툴(Modus)이 없어, 직접 만든 TB로 shift-in → capture → shift-out 시뮬레이션 |
| Scan 후 LEC | Conformal | scan_en = 0으로 묶고 scan 전후 동일성 확인 |
| PnR 반영 | Innovus | scandef를 읽어 `scanReorder` |

> ATPG 패턴 생성과 fault coverage는 Modus가 필요해 이 저장소의 범위 밖입니다.

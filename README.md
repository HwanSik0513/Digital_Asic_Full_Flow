# Digital ASIC Full Flow

RTL부터 GDS까지 디지털 ASIC 설계·구현 전 과정을 Cadence 툴로 직접 수행하고, 단계별 스크립트·리포트·레이아웃 결과를 정리한 저장소입니다.

| Project | Design | Technology | Status |
|---|---|---|---|
| [8_bit_SPI](8_bit_SPI) | SPI Master/Slave + Async FIFO CDC Bridge (`spi_bridge_top`) | GPDK045 (`gsclib045`) | RTL → GDS 완료 · LEC · Tempus STA · GLS(Pre/Post) PASS |

## Flow

| # | Stage | Tool | Chapter |
|---|---|---|---|
| ① | Specification · Architecture · RTL | — | 00 · 01 · 02 |
| ② | Functional Verification | Xcelium | 03 |
| ③ | Logic Synthesis | Genus | 04 |
| ④ | Scan Insertion (ATPG) | Genus (Modus 없음) | 05 |
| ⑤ | Equivalence Check (RTL ↔ Netlist) | Conformal | 06 |
| ⑥ | Pre-Layout STA | Tempus | 07 |
| ⑦ | Pre-Layout Simulation | Xcelium | 08 |
| ⑧ | Floorplan · Placement · CTS · Routing | Innovus | 09 · 10 · 11 · 12 |
| ⑨ | Equivalence Check (Netlist ↔ PnR) | Conformal | 13 |
| ⑩ | RC Extraction | Innovus 내장 추출 (Quantus 없음) | 14 |
| ⑪ | Post-Layout STA | Tempus | 15 |
| — | Timing Closure (ECO) | Tempus · Innovus | 16 |
| ⑫ | Post-Layout Simulation | Xcelium | 17 |
| — | Final Verification (DRC · Connectivity) | Innovus | 18 |
| — | Final Results | — | 19 |

## Tools

| Tool | Version | Used for |
|---|---|---|
| Cadence Xcelium | 22.03 | RTL / gate-level simulation |
| Cadence Genus | 22.17 | Logic synthesis (MMMC) |
| Cadence Conformal | 22.10 | Logic equivalence check |
| Cadence Tempus | 22.17 | Static timing analysis, timing ECO |
| Cadence Innovus | 22.17 | Floorplan, place, CTS, route, RC extraction, physical checks |

사용할 수 없는 툴(Modus, Quantus, Pegasus 등)이 필요한 단계는 각 챕터 README에 대체 방법과 한계를 적었습니다.

> GPDK045 PDK 파일(.lib, .lef, captable, 셀 Verilog 모델 등)은 라이선스 자료라 저장소에 포함하지 않으며, `.gitignore`로 막아 두었습니다.

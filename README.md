# Digital ASIC Full Flow

RTL부터 GDS까지 디지털 ASIC 설계·구현 전 과정을 Cadence 툴로 직접 수행하고, 단계별 스크립트·리포트·레이아웃 결과를 정리한 저장소입니다.

## Projects

| # | Project | Design | Technology | Status |
|---|---|---|---|---|
| 1 | [8_bit_SPI](8_bit_SPI) | SPI Master/Slave + Async FIFO CDC Bridge (`spi_bridge_top`) | GPDK045 (gsclib045) | RTL → GDS 완료 · LEC · Tempus STA · GLS(Pre/Post) PASS |
| 2 | [MIPS_MCU_SPI](MIPS_MCU_SPI) | 싱글 사이클 MIPS CPU + SPI Slave (CDC-01/02 수정) + GPIO, IO 패드 링 (`chip_top`) | GPDK045 (gsclib045 + giolib045) | RTL → GDS 완료 · LEC PASS · Tempus 사인오프 위반 0 · GLS(RTL/Pre/Post SS·FF) PASS |

### 프로젝트 2의 확장 내용

| 항목 | 8_bit_SPI | MIPS_MCU_SPI |
|---|---|---|
| 설계 | SPI 브릿지 단독 | CPU + ROM 64×32 + RAM 32×32 + SPI Slave + GPIO (메모리 맵 I/O) |
| CDC | CDC-01, CDC-02 미해결로 기록 | **두 이슈 수정, RTL 파형으로 확인** |
| 검증 | 브릿지 테스트벤치 | 직접 만든 어셈블러·ISS로 빌드한 펌웨어로 검증, RTL·Pre·Post GLS 판정 일치 (6,995 ns, GPIO = `0xA5`) |
| 칩 레벨 | 코어만 | IO 패드 20개 + 코너 4개, 다이 780 µm, 전원 패드 자동 추가, `pad_connect.tcl` |
| 주요 수치 | — | Tempus setup +0.676 ns / hold +0.051 ns, DRC 0, CTS 버퍼 117 |

## Flow

| # | Stage | Tool | Chapter |
|---|---|---|---|
| ① | Specification · Architecture · RTL | — | 00 · 01 · 02 |
| ② | Functional Verification | Xcelium | 03 |
| ③ | Logic Synthesis | Genus | 04 |
| ④ | Scan Insertion (ATPG) | Genus (Modus 없음) | 05 |
| ⑤ | Equivalence Check (RTL ↔ Netlist) | Conformal | 06 |
| ⑥ | Pre-Layout STA | Tempus / Genus | 07 |
| ⑦ | Pre-Layout Simulation | Xcelium | 08 |
| ⑧ | Floorplan · Placement · CTS · Routing | Innovus | 09 · 10 · 11 · 12 |
| ⑨ | Equivalence Check (Netlist ↔ PnR) | Conformal | 13 |
| ⑩ | RC Extraction | Innovus 내장 추출 (Quantus 없음) | 14 |
| ⑪ | Post-Layout STA | Tempus | 15 |
| — | Timing Closure (ECO) | Tempus · Innovus | 16 |
| ⑫ | Post-Layout Simulation | Xcelium | 17 |
| — | Final Verification (DRC · Connectivity) | Innovus | 18 |
| — | Final Results | — | 19 |

두 프로젝트 모두 같은 챕터 번호를 씁니다. 프로젝트마다 다른 점은 다음과 같습니다.

| Chapter | 8_bit_SPI | MIPS_MCU_SPI |
|---|---|---|
| 05 DFT | 각 챕터 README 참고 | 미적용 (이유는 README에 기록) |
| 07 Pre-STA | Tempus | Genus 합성 타이밍 리포트 |
| 16 ECO | 각 챕터 README 참고 | 사인오프 위반 0이라 ECO 미실행 (스크립트만 준비) |

## Tools

| Tool | Version | Used for |
|---|---|---|
| Cadence Xcelium | 22.03 | RTL / gate-level simulation |
| Cadence Genus | 22.17 | Logic synthesis (MMMC) |
| Cadence Conformal | 22.10 | Logic equivalence check |
| Cadence Tempus | 22.17 | Static timing analysis, timing ECO |
| Cadence Innovus | 22.17 | Floorplan, place, CTS, route, RC extraction, physical checks |

사용할 수 없는 툴(Modus, Quantus, Pegasus 등)이 필요한 단계는 각 챕터 README에 대체 방법과 한계를 적었습니다.

GPDK045 PDK 파일(.lib, .lef, captable, 셀·패드 Verilog 모델 등)은 라이선스 자료라 저장소에 포함하지 않으며, `.gitignore`로 막아 두었습니다.

## Repository Structure

```
Digital_Asic_Full_Flow/
├── README.md
├── .gitignore
│
├── 8_bit_SPI/
│   ├── README.md
│   └── 00_Specification/ ~ 19_Final_Results/
│
└── MIPS_MCU_SPI/
    ├── README.md
    └── 00_Specification/ ~ 19_Final_Results/
```

각 챕터 폴더는 `README.md` + `scripts/` + `reports/` + `images/` + `results/` 형식입니다.

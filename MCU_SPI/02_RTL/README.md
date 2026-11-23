# 02. RTL

Verilog-2001, 합성 가능한 RTL. 포트 이름은 입력 `i_`, 출력 `o_` (clk/rst 계열 제외),
모듈 선언 아래에 포트 리스트 → 포트 선언 순서.

## 모듈

| 파일 | 모듈 | 역할 | 출처 |
|---|---|---|---|
| `Chip_top.v` | `chip_top` | PADDI 5 + PADDO 9 + `mcu_core` | 신규 |
| `Mcu_core.v` | `mcu_core` | MMIO 디코더, GPIO, 계층 연결 | 신규 (책 14장 방식) |
| `Mips_cpu.v` | `mips_cpu` | 싱글 사이클 데이터패스 | 책 5.3 `sccpu` 이식 |
| `Sc_cu.v` | `sc_cu` | 명령어 디코드 / 제어 | 책 |
| `Alu.v` | `alu` | ALU (behavioral add/sub/shift) | 책 (cla 대신 behavioral) |
| `Regfile.v` | `regfile` | 31 × 32 레지스터, 비동기 clear | 책 |
| `Data_ram.v` | `data_ram` | 32 × 32 FF, 리셋 없음 | 신규 |
| `Spi_slave_bridge.v` | `spi_slave_bridge` | SPI 브릿지 top (CDC-01/02 수정) | 이전 프로젝트 `spi_bridge_top`에서 master/sclk_gen 제거 |
| `Register_block.v` | `register_block` | CPU 버스 레지스터, STATUS.TX_FULL 추가 | 이전 프로젝트 수정 |
| `Spi_slave.v` `Async_fifo.v` `Pulse_sync.v` `Reset_sync.v` | | 그대로 재사용 | 이전 프로젝트 |

책 대비 변경점(ROM/RAM 외부 포트화, `o_mem_re` 추가 등)과 브릿지 변경점은
`results/CHANGES_*.md`, `results/Register_block.diff`에 정리했습니다.

## 펌웨어 도구 (`scripts/FW/`)

| 파일 | 역할 |
|---|---|
| `mips_asm.py` | 20개 명령어 어셈블러 → `.hex`, `.lst`, `*_rom.v` (case ROM, `module inst_rom`) |
| `mips_iss.py` | 명령어 수준 시뮬레이터 → 기대값(레지스터 / RAM) 생성 |
| `booktest.s` | 책 테스트 프로그램 + RAM 초기화 8 명령어 (CPU 단독 검증) |
| `echo.s` | SPI 에코 펌웨어 24 명령어 (MCU / 칩 / GLS 검증) |

ROM은 합성 때 별도 계층(`u_rom`, `ungroup_ok false`, `boundary_opto false`)으로 유지해
펌웨어 상수가 CPU 쪽으로 전파되어 레지스터 파일이 지워지지 않게 했습니다 (04 참고).

## 파일

```
02_RTL/
├── README.md
│
├── scripts/
│   ├── *.v (13)
│   └── FW/  mips_asm.py, mips_iss.py, booktest.s, echo.s, README.md
│
└── results/
    ├── CHANGES_mcu_core.md / CHANGES_mips_cpu.md / CHANGES_spi_slave_bridge.md
    ├── Register_block.diff
    └── FW_build/  booktest*, echo* (.hex / .lst / _rom.v / 기대값)
```

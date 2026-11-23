# 00. Specification — MIPS MCU + SPI Slave (chip_top, IO pads)

책(Yamin Li, *Computer Principles and Design in Verilog HDL*)의 싱글 사이클 MIPS CPU에
이전 프로젝트의 SPI Slave + Async FIFO CDC 브릿지를 메모리 맵 I/O로 붙이고,
IO 패드까지 넣어 RTL → GDS까지 진행한 칩입니다.

## 설계 목표

| 항목 | 값 |
|---|---|
| Top | `chip_top` (IO 패드) → `mcu_core` (CPU + ROM + RAM + SPI + GPIO) |
| 클럭 | `ACLK` 100 MHz (10 ns, 시스템), `SCLK` 25 MHz급 (테스트벤치 41 ns, 외부 SPI 호스트, ACLK와 비동기) |
| 리셋 | `ARESETn` 비동기 active-low, 도메인별 `reset_sync`로 동기 해제 |
| CPU | 싱글 사이클 MIPS, 20개 정수 명령어 (Table 4.4), branch delay slot 없음 |
| 메모리 | 명령어 ROM 64 × 32 (case ROM, 펌웨어로 생성), 데이터 RAM 32 × 32 (FF) |
| 주변장치 | SPI Mode 0 Slave (RX FIFO 16 × 8, TX FIFO 4 × 8), GPIO_OUT 8비트 |
| 이번 프로젝트에서 고친 것 | CDC-01 (STATUS.FULL), CDC-02 (SPI_BUSY) — 이전 SPI 프로젝트의 미해결 CDC 이슈 |
| 공정 / 라이브러리 | GPDK045 (45 nm), gsclib045 표준 셀, giolib045 IO 패드 |
| 툴 | Xcelium · Genus 22.17 · Conformal LEC 22.1 · Innovus 22.17 · Tempus 22.17 |
| 코너 | setup `FUNC_SS_WORST` (slow 0.9 V 125 °C), hold `FUNC_FF_BEST` (fast 1.1 V 0 °C) |

## 명령어 (20개, 책 Table 4.4)

| 형식 | 명령어 |
|---|---|
| R | `add` `sub` `and` `or` `xor` `sll` `srl` `sra` `jr` |
| I | `addi` `andi` `ori` `xori` `lw` `sw` `beq` `bne` `lui` |
| J | `j` `jal` |

## 메모리 맵 (책 14장 방식: `addr[31]`이 I/O 선택)

| 주소 | 대상 | 비고 |
|---|---|---|
| ROM (PC) | `inst_rom` 64 words | 별도 버스 (하버드 구조) |
| `0x0000_0000` ~ `0x0000_007C` | `data_ram` 32 words | `addr[31] = 0` |
| `0x8000_0000` ~ `0x8000_001C` | SPI 레지스터 | `addr[31] = 1`, `addr[7:5] = 000` |
| `0x8000_0020` | `GPIO_OUT` | `addr[7:0] = 0x20` |

## SPI 레지스터 맵 (`register_block`)

| 오프셋 | 이름 | R/W | 설명 |
|---|---|---|---|
| `0x00` | `RX_DATA` | R | 프리페치된 RX 바이트. 읽으면 pop (`lw` = `o_mem_re`) |
| `0x04` | `STATUS` | R | `{2'b00, TX_FULL, OVERFLOW, RX_VALID, BUSY, FULL, EMPTY}` |
| `0x08` | `CONTROL` | R/W | bit0 FIFO_CLEAR, bit1 OVERFLOW_CLEAR (write strobe) |
| `0x0C` | `FIFO_LEVEL` | R | RX FIFO 레벨 0..16 (ACLK 도메인) |
| `0x10` | `TX_DATA` | R/W | 쓰면 TX FIFO push, 읽으면 마지막 쓴 값 |

- `FULL` = `level == 16`을 **ACLK 도메인에서** 계산 (CDC-01 수정)
- `BUSY` = SCLK 도메인 플롭 → 2-FF 동기화 (CDC-02 수정)
- `TX_FULL` = `tx_fifo_full || pending write`

## 칩 핀 (`chip_top`)

| 핀 | 방향 | 패드 | 설명 |
|---|---|---|---|
| `ACLK` | in | PADDI | 시스템 클럭 |
| `ARESETn` | in | PADDI | 비동기 리셋 |
| `SCLK` | in | PADDI | SPI 클럭 (호스트 제공, 연속) |
| `i_cs_n` | in | PADDI | SPI chip select |
| `i_mosi` | in | PADDI | SPI 호스트 → MCU |
| `o_miso` | out | PADDO | SPI MCU → 호스트 |
| `o_gpio[7:0]` | out | 8 × PADDO | GPIO_OUT (펌웨어 판정: `0xA5` PASS / `0xEE` FAIL) |
| 전원 | – | PADVDD ×2, PADVSS ×2, PADVDDIOR, PADVSSIOR | PnR 넷리스트에서 추가 |

## 검증용 펌웨어 (`echo.s`, 24 명령어)

호스트가 보낸 바이트 8개를 받아 `+1` 해서 돌려보내고, 끝나면 GPIO에 결과를 씁니다.

```
poll STATUS.RX_VALID → lw RX_DATA (pop) → +1 → poll STATUS.TX_FULL → sw TX_DATA   (× 8)
→ sw GPIO_OUT = 0xA5 (PASS) / 0xEE (FAIL) → done: j done
```

같은 펌웨어로 RTL(03), Pre-layout GLS(08), Post-layout GLS(17)를 모두 검증했고,
세 단계 모두 **6,995 ns에 `GPIO = 0xA5`**로 판정이 같습니다.

## 파일

```
00_Specification/
├── README.md     (이 문서)
└── echo.s        검증용 펌웨어 원본 (빌드 결과는 02_RTL/results/FW_build)
```

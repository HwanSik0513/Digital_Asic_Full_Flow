# 00. Specification

| File | Content |
|---|---|
| [8-bit_SPI_Master_Slave_Async_FIFO_Specification.pdf](8-bit_SPI_Master_Slave_Async_FIFO_Specification.pdf) | 설계 사양서 v1.1 (2026-10-23, 4쪽) |

## Summary

| Item | Spec |
|---|---|
| SPI | Mode 0 (CPOL=0, CPHA=0), 8-bit, MSB first. MOSI/MISO sample = SCLK↑, update = SCLK↓ |
| Clocks | ACLK 100 MHz (사양 목표), SCLK = ACLK ÷ 4 = 25 MHz (`sclk_gen`, generated clock) |
| RX FIFO | 8-bit × 16, SCLK(write) → ACLK(read) |
| TX FIFO | 8-bit × 4, ACLK(write) → SCLK(read) |
| Host interface | 8-bit register bus (`i_bus_addr`, `i_bus_wr_en`, `i_bus_wdata`, `i_bus_rd_en`, `o_bus_rdata`) |
| Registers | `0x00` RX_DATA, `0x04` STATUS, `0x08` CONTROL, `0x0C` FIFO_LEVEL, `0x10` TX_DATA |
| Reset | `ARESETn` async active-low, 도메인별 `reset_sync` (async assert / sync release) |
| CDC | Gray pointer 2-FF (FIFO 4경로), pulse_sync (overflow), 2-FF (busy) |

## FPGA 사양 → ASIC 구현

사양서는 FPGA(XC7Z010) 기준으로 작성되었습니다. ASIC 플로우에서 달라지는 점은 다음과 같습니다.

| Item | FPGA (사양서) | ASIC (이 저장소) |
|---|---|---|
| SCLK 버퍼 | `BUFG` | `XILINX_FPGA` 미정의 → `assign SCLK = w_sclk_raw`, 클럭 트리는 Innovus CTS가 생성 |
| 라이브러리 | Xilinx 7-series | GPDK045 `gsclib045` |
| 주파수 | ACLK 100 MHz | 100 MHz(사양) + 500 MHz · 625 MHz · 1 GHz(구현 실험) |
| 시뮬레이터 | Vivado XSim | Cadence Xcelium |

## Known issues (사양서 §8)

| ID | 내용 | 상태 |
|---|---|---|
| CDC-01 | RX FIFO full(`w_rx_fifo_full`, SCLK 쪽)을 ACLK 도메인 STATUS[1]에서 동기화 없이 사용 | 열림 |
| CDC-02 | master busy OR slave busy 조합 출력을 2-FF 입력으로 사용 | 열림 |

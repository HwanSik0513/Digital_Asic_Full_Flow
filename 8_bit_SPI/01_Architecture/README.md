# 01. Architecture

| File | Content |
|---|---|
| [SPI_Bridge_RTL_Architecture_A3.pdf](SPI_Bridge_RTL_Architecture_A3.pdf) | 블록 다이어그램, 클럭·리셋 생성, RX/TX 데이터 경로, CDC 경로 (A3, 9쪽) |
| [E_table/E_tables.md](E_table/E_tables.md) · [pdf](E_table/E_tables.pdf) | 계층, 인스턴스 연결(64행), 미연결 출력, 모듈 포트 표 |

## Hierarchy

```text
spi_bridge_top
├── u_reset_sync_aclk      reset_sync      ACLK   : ARESETn → aclk_rst_n
├── u_reset_sync_sclk      reset_sync      SCLK   : ARESETn → sclk_rst_n
├── u_sclk_gen             sclk_gen        ACLK   : ACLK ÷ 4 → SCLK
├── u_spi_master           spi_master      SCLK   : 자동 프레임 생성 (8-bit, CS_N 1회당 1 byte)
├── u_spi_slave            spi_slave       SCLK   : RX shift / TX hold, FIFO 인터페이스
├── u_rx_fifo              async_fifo      SCLK → ACLK (8 × 16)
├── u_tx_fifo              async_fifo      ACLK → SCLK (8 × 4)
├── u_overflow_pulse_sync  pulse_sync      SCLK → ACLK
└── u_register_block       register_block  ACLK   : register bus, RX prefetch, overflow sticky
```

## Clock domains

| Domain | Clock | Modules |
|---|---|---|
| ACLK | 외부 입력 | reset_sync(aclk), sclk_gen, register_block, RX FIFO read, TX FIFO write, pulse_sync dst |
| SCLK | ACLK ÷ 4 (generated) | reset_sync(sclk), spi_master, spi_slave, RX FIFO write, TX FIFO read, pulse_sync src |

SCLK는 ACLK에서 만든 generated clock이므로 STA에서는 두 클럭을 관련 클럭으로 보고 FIFO 포인터 경로까지 검사합니다 (`set_clock_groups -asynchronous` 미사용).

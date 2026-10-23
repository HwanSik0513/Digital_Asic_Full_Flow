# SPI Slave CDC Bridge — RTL Connectivity / Port Tables

소스: 8bit_SPI_reset_fixed.v (spi_bridge_top.v), 1,293 lines. 정적 RTL 검토 결과이며 도구 검증 아님.

## 1. Hierarchy

| Module | Instance | Parent | Clock | Reset | Function | 구분 |
|---|---|---|---|---|---|---|
| spi_bridge_top | (top) | — | ACLK (입력), SCLK (내부 생성) | ARESETn (async 입력) | 최상위: 클럭/리셋 생성, 내부 SPI master↔slave 직결, 두 개의 async FIFO, 레지스터 블록, busy 2FF 동기화, debug 출력 | top |
| reset_sync | u_reset_sync_aclk | spi_bridge_top | ACLK | ARESETn → aclk_rst_n | async assert / sync release (2FF), ACLK 도메인 리셋 | 인스턴스 |
| reset_sync | u_reset_sync_sclk | spi_bridge_top | SCLK | ARESETn → sclk_rst_n | async assert / sync release (2FF), SCLK 도메인 리셋 | 인스턴스 |
| sclk_gen | u_sclk_gen | spi_bridge_top | ACLK | aclk_rst_n (async) | ACLK÷4 분주 (r_toggle_phase + o_sclk), 25 MHz | 인스턴스 |
| BUFG (Xilinx primitive) | u_bufg_sclk | spi_bridge_top | — | — | w_sclk_raw → SCLK 전역 클럭 버퍼 (RTL 모듈 아님, 라이브러리 primitive) | 인스턴스 |
| spi_master | u_spi_master | spi_bridge_top | SCLK | sclk_rst_n (async) | 내부 SPI master: 4-state FSM, 8-bit 프레임 송신 (패턴 r_tx_byte++), MISO 수신 | 인스턴스 |
| spi_slave | u_spi_slave | spi_bridge_top | SCLK | sclk_rst_n (async) | SPI slave: 4-state FSM, RX shift, TX hold/shift, FIFO 인터페이스 | 인스턴스 |
| async_fifo | u_rx_fifo | spi_bridge_top | wr: SCLK / rd: ACLK | wr: sclk_rst_n / rd: aclk_rst_n | RX FIFO, DATA_WIDTH=8, ADDR_WIDTH=4 (16×8), SCLK→ACLK | 인스턴스 |
| async_fifo | u_tx_fifo | spi_bridge_top | wr: ACLK / rd: SCLK | wr: aclk_rst_n / rd: sclk_rst_n | TX FIFO, DATA_WIDTH=8, ADDR_WIDTH=2 (4×8), ACLK→SCLK | 인스턴스 |
| pulse_sync | u_overflow_pulse_sync | spi_bridge_top | src: SCLK / dst: ACLK | src: sclk_rst_n / dst: aclk_rst_n | RX overflow pulse SCLK→ACLK (toggle + 2FF + XOR) | 인스턴스 |
| register_block | u_register_block | spi_bridge_top | ACLK | aclk_rst_n (sync) | 레지스터 버스(0x00..0x10), RX prefetch 버퍼, drain, overflow sticky, TX write | 인스턴스 |

## 2. Connectivity (64 rows)

| Source Instance.Port | Signal | Width | Destination Instance.Port | Clock Domain |
|---|---|---|---|---|
| (top).ACLK | ACLK | 1 | u_reset_sync_aclk.clk | ACLK/async |
| (top).ACLK | ACLK | 1 | u_sclk_gen.clk | ACLK/async |
| (top).ACLK | ACLK | 1 | u_rx_fifo.rd_clk | ACLK/async |
| (top).ACLK | ACLK | 1 | u_tx_fifo.wr_clk | ACLK/async |
| (top).ACLK | ACLK | 1 | u_overflow_pulse_sync.dst_clk | ACLK/async |
| (top).ACLK | ACLK | 1 | u_register_block.ACLK | ACLK/async |
| (top).ARESETn | ARESETn | 1 | u_reset_sync_aclk.arst_n | ACLK/async |
| (top).ARESETn | ARESETn | 1 | u_reset_sync_sclk.arst_n | ACLK/async |
| (top).i_bus_addr | i_bus_addr | 8 | u_register_block.i_bus_addr | ACLK |
| (top).i_bus_wr_en | i_bus_wr_en | 1 | u_register_block.i_bus_wr_en | ACLK |
| (top).i_bus_wdata | i_bus_wdata | 8 | u_register_block.i_bus_wdata | ACLK |
| (top).i_bus_rd_en | i_bus_rd_en | 1 | u_register_block.i_bus_rd_en | ACLK |
| u_register_block.o_bus_rdata | o_bus_rdata | 8 | (top).o_bus_rdata | ACLK |
| u_register_block.o_overflow | o_overflow | 1 | (top).o_overflow | ACLK |
| u_register_block.o_rx_valid | o_rx_valid | 1 | (top).o_rx_valid | ACLK |
| u_reset_sync_aclk.rst_n_sync | aclk_rst_n | 1 | u_sclk_gen.rst_n | ACLK |
| u_reset_sync_aclk.rst_n_sync | aclk_rst_n | 1 | u_rx_fifo.rd_rst_n | ACLK |
| u_reset_sync_aclk.rst_n_sync | aclk_rst_n | 1 | u_tx_fifo.wr_rst_n | ACLK |
| u_reset_sync_aclk.rst_n_sync | aclk_rst_n | 1 | u_overflow_pulse_sync.dst_rst_n | ACLK |
| u_reset_sync_aclk.rst_n_sync | aclk_rst_n | 1 | u_register_block.rst_n | ACLK |
| u_bufg_sclk.O | SCLK | 1 | u_reset_sync_sclk.clk | SCLK(생성) |
| u_bufg_sclk.O | SCLK | 1 | u_spi_master.SCLK | SCLK(생성) |
| u_bufg_sclk.O | SCLK | 1 | u_spi_slave.SCLK | SCLK(생성) |
| u_bufg_sclk.O | SCLK | 1 | u_rx_fifo.wr_clk | SCLK(생성) |
| u_bufg_sclk.O | SCLK | 1 | u_tx_fifo.rd_clk | SCLK(생성) |
| u_bufg_sclk.O | SCLK | 1 | u_overflow_pulse_sync.src_clk | SCLK(생성) |
| u_bufg_sclk.O | SCLK | 1 | (top).o_dbg_sclk[assign] | SCLK(생성) |
| u_reset_sync_sclk.rst_n_sync | sclk_rst_n | 1 | u_spi_master.rst_n | SCLK |
| u_reset_sync_sclk.rst_n_sync | sclk_rst_n | 1 | u_spi_slave.rst_n | SCLK |
| u_reset_sync_sclk.rst_n_sync | sclk_rst_n | 1 | u_rx_fifo.wr_rst_n | SCLK |
| u_reset_sync_sclk.rst_n_sync | sclk_rst_n | 1 | u_tx_fifo.rd_rst_n | SCLK |
| u_reset_sync_sclk.rst_n_sync | sclk_rst_n | 1 | u_overflow_pulse_sync.src_rst_n | SCLK |
| u_sclk_gen.o_sclk | w_sclk_raw | 1 | u_bufg_sclk.I | SCLK(생성) |
| u_spi_master.o_cs_n | w_cs_n | 1 | u_spi_slave.i_cs_n | SCLK |
| u_spi_master.o_cs_n | w_cs_n | 1 | (top).o_dbg_cs_n[assign] | SCLK |
| u_spi_master.o_mosi | w_mosi | 1 | u_spi_slave.i_mosi | SCLK |
| u_spi_master.o_mosi | w_mosi | 1 | (top).o_dbg_mosi[assign] | SCLK |
| u_spi_slave.o_miso | w_miso | 1 | u_spi_master.i_miso | SCLK |
| u_spi_slave.o_miso | w_miso | 1 | (top).o_dbg_miso[assign] | SCLK |
| u_spi_master.o_busy | w_spi_busy_master | 1 | top.w_spi_busy(OR) | SCLK→ACLK (OR+2FF) |
| u_spi_slave.o_rx_wr_en | w_rx_wr_en | 1 | u_rx_fifo.i_wr_en | SCLK |
| u_spi_slave.o_rx_wr_data | w_rx_wr_data | 8 | u_rx_fifo.i_wr_data | SCLK |
| u_rx_fifo.o_full | w_rx_fifo_full | 1 | u_spi_slave.i_rx_fifo_full | SCLK→(CDC-01: ACLK 직결) |
| u_rx_fifo.o_full | w_rx_fifo_full | 1 | u_register_block.i_rx_fifo_full | SCLK→(CDC-01: ACLK 직결) |
| u_spi_slave.o_rx_overflow_pulse | w_rx_overflow_pulse | 1 | u_overflow_pulse_sync.i_src_pulse | SCLK→ACLK (pulse_sync) |
| u_spi_slave.o_tx_fifo_rd_en | w_tx_fifo_rd_en | 1 | u_tx_fifo.i_rd_en | SCLK |
| u_tx_fifo.o_rd_data | w_tx_fifo_rd_data | 8 | u_spi_slave.i_tx_fifo_rd_data | SCLK |
| u_tx_fifo.o_empty | w_tx_fifo_empty | 1 | u_spi_slave.i_tx_fifo_empty | SCLK |
| u_spi_slave.o_spi_busy | w_spi_busy_slave | 1 | top.w_spi_busy(OR) | SCLK→ACLK (OR+2FF) |
| u_register_block.o_rx_fifo_rd_en | w_rx_fifo_rd_en | 1 | u_rx_fifo.i_rd_en | ACLK |
| u_rx_fifo.o_rd_data | w_rx_fifo_rd_data | 8 | u_register_block.i_rx_fifo_rd_data | ACLK |
| u_rx_fifo.o_empty | w_rx_fifo_empty | 1 | u_register_block.i_rx_fifo_empty | ACLK |
| u_rx_fifo.o_rd_level | w_rx_fifo_level | 5 | u_register_block.i_rx_fifo_level | ACLK |
| u_register_block.o_tx_fifo_wr_en | w_tx_fifo_wr_en | 1 | u_tx_fifo.i_wr_en | ACLK |
| u_register_block.o_tx_fifo_wr_data | w_tx_fifo_wr_data | 8 | u_tx_fifo.i_wr_data | ACLK |
| u_tx_fifo.o_full | w_tx_fifo_full | 1 | u_register_block.i_tx_fifo_full | ACLK |
| u_overflow_pulse_sync.o_dst_pulse | w_rx_overflow_pulse_sync | 1 | u_register_block.i_rx_overflow_pulse_sync | ACLK |
| top.r_spi_busy_sync(2FF reg) | r_spi_busy_sync | 1 | u_register_block.i_spi_busy_sync | ACLK |
| (top) assign | SCLK | 1 | (top).o_dbg_sclk | SCLK(생성) |
| (top) assign | w_cs_n | 1 | (top).o_dbg_cs_n | SCLK |
| (top) assign | w_mosi | 1 | (top).o_dbg_mosi | SCLK |
| (top) assign | w_miso | 1 | (top).o_dbg_miso | SCLK |
| top.w_spi_busy(OR) | w_spi_busy (= w_spi_busy_master || w_spi_busy_slave) | 1 | top.r_spi_busy_meta (FF D) | SCLK→ACLK 경계 (CDC-02: OR 조합 후 2FF) |
| top.r_spi_busy_meta | r_spi_busy_meta | 1 | top.r_spi_busy_sync (FF D) | ACLK |

## 3. Not Connected (NC) outputs

- u_spi_master.o_rx_captured
- u_spi_master.o_rx_captured_valid
- u_tx_fifo.o_rd_level

## 4. Module ports

### spi_bridge_top

| Dir | Width | Port |
|---|---|---|
| input | 1 | ACLK |
| input | 1 | ARESETn |
| input | [7:0] | i_bus_addr |
| input | 1 | i_bus_wr_en |
| input | [7:0] | i_bus_wdata |
| input | 1 | i_bus_rd_en |
| output | [7:0] | o_bus_rdata |
| output | 1 | o_overflow |
| output | 1 | o_rx_valid |
| output | 1 | o_dbg_sclk |
| output | 1 | o_dbg_cs_n |
| output | 1 | o_dbg_mosi |
| output | 1 | o_dbg_miso |

### spi_master

| Dir | Width | Port |
|---|---|---|
| input | 1 | SCLK |
| input | 1 | rst_n |
| output | 1 | o_cs_n |
| output | 1 | o_mosi |
| input | 1 | i_miso |
| output | [7:0] | o_rx_captured |
| output | 1 | o_rx_captured_valid |
| output | 1 | o_busy |

### spi_slave

| Dir | Width | Port |
|---|---|---|
| input | 1 | SCLK |
| input | 1 | rst_n |
| input | 1 | i_cs_n |
| input | 1 | i_mosi |
| output | 1 | o_miso |
| output | 1 | o_rx_wr_en |
| output | [7:0] | o_rx_wr_data |
| input | 1 | i_rx_fifo_full |
| output | 1 | o_rx_overflow_pulse |
| output | 1 | o_tx_fifo_rd_en |
| input | [7:0] | i_tx_fifo_rd_data |
| input | 1 | i_tx_fifo_empty |
| output | 1 | o_spi_busy |

### async_fifo

| Dir | Width | Port |
|---|---|---|
| input | 1 | wr_clk |
| input | 1 | wr_rst_n |
| input | 1 | i_wr_en |
| input | [DATA_WIDTH-1:0] | i_wr_data |
| output | 1 | o_full |
| input | 1 | rd_clk |
| input | 1 | rd_rst_n |
| input | 1 | i_rd_en |
| output | [DATA_WIDTH-1:0] | o_rd_data |
| output | 1 | o_empty |
| output | [ADDR_WIDTH:0] | o_rd_level |

### register_block

| Dir | Width | Port |
|---|---|---|
| input | 1 | ACLK |
| input | 1 | rst_n |
| input | [7:0] | i_bus_addr |
| input | 1 | i_bus_wr_en |
| input | [7:0] | i_bus_wdata |
| input | 1 | i_bus_rd_en |
| output | [7:0] | o_bus_rdata |
| output | 1 | o_rx_fifo_rd_en |
| input | [7:0] | i_rx_fifo_rd_data |
| input | 1 | i_rx_fifo_empty |
| input | 1 | i_rx_fifo_full |
| input | [4:0] | i_rx_fifo_level |
| output | 1 | o_tx_fifo_wr_en |
| output | [7:0] | o_tx_fifo_wr_data |
| input | 1 | i_tx_fifo_full |
| input | 1 | i_spi_busy_sync |
| input | 1 | i_rx_overflow_pulse_sync |
| output | 1 | o_overflow |
| output | 1 | o_rx_valid |

### pulse_sync

| Dir | Width | Port |
|---|---|---|
| input | 1 | src_clk |
| input | 1 | src_rst_n |
| input | 1 | i_src_pulse |
| input | 1 | dst_clk |
| input | 1 | dst_rst_n |
| output | 1 | o_dst_pulse |

### reset_sync

| Dir | Width | Port |
|---|---|---|
| input | 1 | clk |
| input | 1 | arst_n |
| output | 1 | rst_n_sync |

### sclk_gen

| Dir | Width | Port |
|---|---|---|
| input | 1 | clk |
| input | 1 | rst_n |
| output | 1 | o_sclk |

### BUFG

| Dir | Width | Port |
|---|---|---|
| input | 1 | I |
| output | 1 | O |

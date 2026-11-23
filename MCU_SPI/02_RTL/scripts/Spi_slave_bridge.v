`timescale 1ns / 1ps

// ============================================================================
// spi_slave_bridge
//
// SPI Mode 0 slave <-> 8-bit register bus bridge, for the MIPS MCU project.
// Derived from spi_bridge_top (8-bit SPI CDC Bridge project) with:
//
//   1. spi_master and sclk_gen removed. The SPI host is now EXTERNAL and
//      drives SCLK, CS_n and MOSI through chip pins. SCLK is therefore an
//      independent clock, asynchronous to ACLK.
//   2. o_dbg_* ports removed; i_cs_n / i_mosi / o_miso are real ports.
//   3. CDC-01 fixed : STATUS.FULL is derived in the ACLK domain from the
//                     synchronized RX FIFO level (no unsynchronized read of
//                     the SCLK-domain full flag).
//   4. CDC-02 fixed : SPI_BUSY is registered in the SCLK domain before the
//                     2-FF synchronizer (no combinational logic feeding the
//                     synchronizer).
//   5. STATUS[5] TX_FULL added (in register_block).
//
// INTERFACE CONTRACT (SCLK):
//   The external host must keep SCLK running continuously, including
//   between frames and while ARESETn is released. Frames are delimited by
//   CS_n only. Reasons:
//     - spi_slave writes the RX byte in S_BYTE_DONE, one SCLK edge after
//       the last data bit, and prefetches the TX byte between frames.
//     - The SCLK-domain reset synchronizer and the Gray-pointer
//       synchronizers on the SCLK side only advance on SCLK edges.
//   A host that stops SCLK between frames is NOT supported (known
//   limitation, see spec).
// ============================================================================
module spi_slave_bridge (
    // port list
    ACLK        ,
    ARESETn     ,
    SCLK        ,
    i_bus_addr  ,
    i_bus_wr_en ,
    i_bus_wdata ,
    i_bus_rd_en ,
    o_bus_rdata ,
    i_cs_n      ,
    i_mosi      ,
    o_miso      ,
    o_overflow  ,
    o_rx_valid
);

// port declaration
input ACLK    ; // system clock (100 MHz)
input ARESETn ; // global asynchronous active-low reset
input SCLK    ; // SPI serial clock from the external host (async to ACLK)

input  [7:0] i_bus_addr  ; // register bus (ACLK domain)
input        i_bus_wr_en ;
input  [7:0] i_bus_wdata ;
input        i_bus_rd_en ;
output [7:0] o_bus_rdata ;

input  i_cs_n ; // SPI chip select from host, active low (SCLK domain)
input  i_mosi ; // host -> slave data, sampled on SCLK rising edge
output o_miso ; // slave -> host data, updated on SCLK falling edge

output o_overflow ; // RX overflow sticky flag (ACLK domain)
output o_rx_valid ; // RX_DATA holds an unread byte (ACLK domain)

// =====================================================================
// Reset synchronization, one per clock domain
// (async assert / sync deassert)
// =====================================================================
wire aclk_rst_n ;
wire sclk_rst_n ;

reset_sync u_reset_sync_aclk (
    .clk        (ACLK)       ,
    .arst_n     (ARESETn)    ,
    .rst_n_sync (aclk_rst_n)
);

reset_sync u_reset_sync_sclk (
    .clk        (SCLK)       ,
    .arst_n     (ARESETn)    ,
    .rst_n_sync (sclk_rst_n)
);

// =====================================================================
// SPI Slave (SCLK domain)
// =====================================================================
wire       w_spi_busy_slave    ;

wire       w_rx_wr_en          ;
wire [7:0] w_rx_wr_data        ;
wire       w_rx_fifo_full      ; // SCLK-domain full flag (write side)
wire       w_rx_overflow_pulse ;

wire       w_tx_fifo_rd_en   ;
wire [7:0] w_tx_fifo_rd_data ;
wire       w_tx_fifo_empty   ;

spi_slave u_spi_slave (
    .SCLK                (SCLK)                ,
    .rst_n               (sclk_rst_n)          ,
    .i_cs_n              (i_cs_n)              ,
    .i_mosi              (i_mosi)              ,
    .o_miso              (o_miso)              ,
    .o_rx_wr_en          (w_rx_wr_en)          ,
    .o_rx_wr_data        (w_rx_wr_data)        ,
    .i_rx_fifo_full      (w_rx_fifo_full)      , // overflow decision stays in SCLK domain
    .o_rx_overflow_pulse (w_rx_overflow_pulse) ,
    .o_tx_fifo_rd_en     (w_tx_fifo_rd_en)     ,
    .i_tx_fifo_rd_data   (w_tx_fifo_rd_data)   ,
    .i_tx_fifo_empty     (w_tx_fifo_empty)     ,
    .o_spi_busy          (w_spi_busy_slave)
);

// =====================================================================
// RX path: SCLK write side / ACLK read side (16 entries)
// =====================================================================
wire [7:0] w_rx_fifo_rd_data ;
wire       w_rx_fifo_empty   ;
wire [4:0] w_rx_fifo_level   ; // ACLK-domain fill level (0..16)
wire       w_rx_fifo_rd_en   ;

async_fifo #(
    .DATA_WIDTH (8) ,
    .ADDR_WIDTH (4)   // 16 entries
) u_rx_fifo (
    .wr_clk    (SCLK)           ,
    .wr_rst_n  (sclk_rst_n)     ,
    .i_wr_en   (w_rx_wr_en)     ,
    .i_wr_data (w_rx_wr_data)   ,
    .o_full    (w_rx_fifo_full) ,

    .rd_clk     (ACLK)              ,
    .rd_rst_n   (aclk_rst_n)        ,
    .i_rd_en    (w_rx_fifo_rd_en)   ,
    .o_rd_data  (w_rx_fifo_rd_data) ,
    .o_empty    (w_rx_fifo_empty)   ,
    .o_rd_level (w_rx_fifo_level)
);

// ---------------------------------------------------------------------
// CDC-01 fix: ACLK-domain RX FULL
// o_rd_level is computed from the 2-FF synchronized write pointer and
// the local read pointer, so it is already an ACLK-domain value.
// Because the synchronized write pointer lags the real one by 2-3 ACLK
// cycles, this flag asserts slightly LATER than the SCLK-domain flag.
// That is acceptable for a status bit: any byte dropped in the meantime
// is still reported by the OVERFLOW sticky bit.
// ---------------------------------------------------------------------
localparam [4:0] RX_FIFO_DEPTH = 5'd16 ;

wire w_rx_fifo_full_aclk = (w_rx_fifo_level == RX_FIFO_DEPTH) ;

// =====================================================================
// TX path: ACLK write side / SCLK read side (4 entries)
// =====================================================================
wire       w_tx_fifo_wr_en   ;
wire [7:0] w_tx_fifo_wr_data ;
wire       w_tx_fifo_full    ; // ACLK-domain full flag (write side)

async_fifo #(
    .DATA_WIDTH (8) ,
    .ADDR_WIDTH (2)   // 4 entries
) u_tx_fifo (
    .wr_clk    (ACLK)              ,
    .wr_rst_n  (aclk_rst_n)        ,
    .i_wr_en   (w_tx_fifo_wr_en)   ,
    .i_wr_data (w_tx_fifo_wr_data) ,
    .o_full    (w_tx_fifo_full)    ,

    .rd_clk     (SCLK)              ,
    .rd_rst_n   (sclk_rst_n)        ,
    .i_rd_en    (w_tx_fifo_rd_en)   ,
    .o_rd_data  (w_tx_fifo_rd_data) ,
    .o_empty    (w_tx_fifo_empty)   ,
    .o_rd_level ()                    // unused on the TX side
);

// =====================================================================
// Single-bit CDC: OVERFLOW pulse (SCLK -> ACLK), toggle + 2-FF
// =====================================================================
wire w_rx_overflow_pulse_sync ;

pulse_sync u_overflow_pulse_sync (
    .src_clk     (SCLK)                     ,
    .src_rst_n   (sclk_rst_n)               ,
    .i_src_pulse (w_rx_overflow_pulse)      ,
    .dst_clk     (ACLK)                     ,
    .dst_rst_n   (aclk_rst_n)               ,
    .o_dst_pulse (w_rx_overflow_pulse_sync)
);

// =====================================================================
// Single-bit CDC: SPI_BUSY level (SCLK -> ACLK)
//
// CDC-02 fix: spi_slave's o_spi_busy is a combinational decode of its FSM
// state. It is first registered in the SCLK domain so the synchronizer
// only ever samples a glitch-free flop output. Adds one SCLK cycle of
// latency to a status-only signal.
// =====================================================================
reg r_spi_busy_sclk ;

always @(posedge SCLK or negedge sclk_rst_n) begin
    if (!sclk_rst_n)
        r_spi_busy_sclk <= 1'b0 ;
    else
        r_spi_busy_sclk <= w_spi_busy_slave ;
end

reg r_spi_busy_meta ;
reg r_spi_busy_sync ;

always @(posedge ACLK) begin
    if (!aclk_rst_n) begin
        r_spi_busy_meta <= 1'b0 ;
        r_spi_busy_sync <= 1'b0 ;
    end else begin
        r_spi_busy_meta <= r_spi_busy_sclk ;
        r_spi_busy_sync <= r_spi_busy_meta ;
    end
end

// =====================================================================
// Register Block (ACLK domain)
// =====================================================================
register_block u_register_block (
    .ACLK  (ACLK)       ,
    .rst_n (aclk_rst_n) ,

    .i_bus_addr  (i_bus_addr)  ,
    .i_bus_wr_en (i_bus_wr_en) ,
    .i_bus_wdata (i_bus_wdata) ,
    .i_bus_rd_en (i_bus_rd_en) ,
    .o_bus_rdata (o_bus_rdata) ,

    .o_rx_fifo_rd_en   (w_rx_fifo_rd_en)     ,
    .i_rx_fifo_rd_data (w_rx_fifo_rd_data)   ,
    .i_rx_fifo_empty   (w_rx_fifo_empty)     ,
    .i_rx_fifo_full    (w_rx_fifo_full_aclk) , // CDC-01: was w_rx_fifo_full (SCLK domain)
    .i_rx_fifo_level   (w_rx_fifo_level)     ,

    .o_tx_fifo_wr_en   (w_tx_fifo_wr_en)   ,
    .o_tx_fifo_wr_data (w_tx_fifo_wr_data) ,
    .i_tx_fifo_full    (w_tx_fifo_full)    ,

    .i_spi_busy_sync          (r_spi_busy_sync)          ,
    .i_rx_overflow_pulse_sync (w_rx_overflow_pulse_sync) ,

    .o_overflow (o_overflow) ,
    .o_rx_valid (o_rx_valid)
);

endmodule

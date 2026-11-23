`timescale 1ns / 1ps

// ============================================================================
// tb_spi_slave_bridge  (simulation only)
//
// DUT  : spi_slave_bridge
// Host : spi_master (the former on-chip master, reused unchanged as the
//        external SPI host model). It sends an auto-incrementing byte
//        pattern 0x00, 0x01, 0x02, ... on MOSI, one byte per frame, and
//        captures whatever the DUT returns on MISO (o_rx_captured).
//
// Clocks: ACLK = 10 ns (100 MHz)
//         SCLK = 41 ns (~24.4 MHz), independent of ACLK. 41 is not an
//         integer multiple of 10, so the phase between the two clocks keeps
//         sliding and the async FIFO / synchronizers see every alignment.
//
// Tests
//   TEST 0  reset values (host held in reset, bus idle)
//   TEST 1  RX path   : host MOSI -> RX FIFO -> RX_DATA, 8 bytes in order
//   TEST 2  TX path   : TX_DATA x4 -> TX FIFO -> MISO -> host, TX_FULL bit
//   TEST 3  SPI_BUSY  : STATUS[2] observed both 1 and 0 (CDC-02 path)
//   TEST 4  RX FULL   : FIFO_LEVEL reaches 16, STATUS[1] = 1 (CDC-01 path),
//                       OVERFLOW sticky set, then FIFO_CLEAR + OVERFLOW_CLEAR
//   TEST 5  RX after clear : consecutive bytes again
// ============================================================================
module tb_spi_slave_bridge;

// ---------------------------------------------------------------------
// Register map (bridge-local offsets)
// ---------------------------------------------------------------------
localparam [7:0] ADDR_RX_DATA    = 8'h00 ,
                 ADDR_STATUS     = 8'h04 ,
                 ADDR_CONTROL    = 8'h08 ,
                 ADDR_FIFO_LEVEL = 8'h0C ,
                 ADDR_TX_DATA    = 8'h10 ;

localparam ST_EMPTY    = 0 ,
           ST_FULL     = 1 ,
           ST_BUSY     = 2 ,
           ST_RX_VALID = 3 ,
           ST_OVERFLOW = 4 ,
           ST_TX_FULL  = 5 ;

localparam real ACLK_HALF = 5.0  ;
localparam real SCLK_HALF = 20.5 ;

localparam integer POLL_LIMIT = 20000 ; // bus polls before declaring a timeout

// ---------------------------------------------------------------------
// Signals
// ---------------------------------------------------------------------
reg        ACLK       ;
reg        SCLK       ;
reg        ARESETn    ;
reg        host_rst_n ;

reg  [7:0] bus_addr  ;
reg        bus_wr_en ;
reg  [7:0] bus_wdata ;
reg        bus_rd_en ;
wire [7:0] bus_rdata ;

wire       cs_n ;
wire       mosi ;
wire       miso ;

wire       overflow ;
wire       rx_valid ;

wire [7:0] host_rx_byte  ;
wire       host_rx_valid ;

integer    err_cnt ;

// ---------------------------------------------------------------------
// Clocks (independent)
// ---------------------------------------------------------------------
initial ACLK = 1'b0 ;
always #(ACLK_HALF) ACLK = ~ACLK ;

initial begin
    SCLK = 1'b0 ;
    #3.0 ;                        // arbitrary initial phase offset
    forever #(SCLK_HALF) SCLK = ~SCLK ;
end

// ---------------------------------------------------------------------
// DUT
// ---------------------------------------------------------------------
spi_slave_bridge dut (
    .ACLK        (ACLK)      ,
    .ARESETn     (ARESETn)   ,
    .SCLK        (SCLK)      ,
    .i_bus_addr  (bus_addr)  ,
    .i_bus_wr_en (bus_wr_en) ,
    .i_bus_wdata (bus_wdata) ,
    .i_bus_rd_en (bus_rd_en) ,
    .o_bus_rdata (bus_rdata) ,
    .i_cs_n      (cs_n)      ,
    .i_mosi      (mosi)      ,
    .o_miso      (miso)      ,
    .o_overflow  (overflow)  ,
    .o_rx_valid  (rx_valid)
);

// ---------------------------------------------------------------------
// External SPI host model
// ---------------------------------------------------------------------
spi_master u_host (
    .SCLK                (SCLK)          ,
    .rst_n               (host_rst_n)    ,
    .o_cs_n              (cs_n)          ,
    .o_mosi              (mosi)          ,
    .i_miso              (miso)          ,
    .o_rx_captured       (host_rx_byte)  ,
    .o_rx_captured_valid (host_rx_valid) ,
    .o_busy              ()
);

// ---------------------------------------------------------------------
// MISO capture log: every byte the host receives, in order
// ---------------------------------------------------------------------
reg [7:0] miso_log [0:4095] ;
integer   miso_cnt ;

initial miso_cnt = 0 ;

always @(posedge SCLK) begin
    if (host_rx_valid) begin
        if (miso_cnt < 4096)
            miso_log[miso_cnt] = host_rx_byte ;
        miso_cnt = miso_cnt + 1 ;
    end
end

// ---------------------------------------------------------------------
// Waveform dump (Xcelium / SimVision). Define NO_SHM to disable.
// ---------------------------------------------------------------------
`ifndef NO_SHM
initial begin
    $shm_open("waves.shm") ;
    $shm_probe(tb_spi_slave_bridge, "AS") ;
end
`endif

// ---------------------------------------------------------------------
// Global watchdog
// ---------------------------------------------------------------------
initial begin
    #(2_000_000) ;
    $display("[%0t] FATAL: global watchdog timeout", $time) ;
    $display("[%0t] TESTS FAILED (tb_spi_slave_bridge)", $time) ;
    $finish ;
end

// ---------------------------------------------------------------------
// Bus tasks
//   Signals change on the ACLK falling edge, the DUT samples on the
//   rising edge. Consecutive calls give back-to-back (1 per cycle)
//   transfers. Read data is sampled 1 ns after the address is driven,
//   i.e. before the rising edge that may pop RX_DATA (same as a
//   single-cycle CPU 'lw').
// ---------------------------------------------------------------------
task bus_write;
    input [7:0] addr ;
    input [7:0] data ;
    begin
        @(negedge ACLK) ;
        bus_addr  = addr ;
        bus_wdata = data ;
        bus_wr_en = 1'b1 ;
        @(posedge ACLK) ;
        #1 bus_wr_en = 1'b0 ;
    end
endtask

task bus_read;
    input  [7:0] addr ;
    output [7:0] data ;
    begin
        @(negedge ACLK) ;
        bus_addr  = addr ;
        bus_rd_en = 1'b1 ;
        #1 data   = bus_rdata ;
        @(posedge ACLK) ;
        #1 bus_rd_en = 1'b0 ;
    end
endtask

// Poll STATUS until bit 'bit_idx' equals 'val'
task wait_status_bit;
    input integer bit_idx ;
    input         val     ;
    input [255:0] tag     ;
    reg   [7:0]   st      ;
    integer       n       ;
    begin
        n  = 0 ;
        st = ~{8{val}} ;
        while ((st[bit_idx] !== val) && (n < POLL_LIMIT)) begin
            bus_read(ADDR_STATUS, st) ;
            n = n + 1 ;
        end
        if (st[bit_idx] !== val) begin
            $display("[%0t] FAIL: %0s timeout (STATUS=%02h)", $time, tag, st) ;
            err_cnt = err_cnt + 1 ;
        end
    end
endtask

// Read one RX byte: wait for RX_VALID, then pop RX_DATA
task rx_read_byte;
    output [7:0] data ;
    begin
        wait_status_bit(ST_RX_VALID, 1'b1, "RX_VALID") ;
        bus_read(ADDR_RX_DATA, data) ;
    end
endtask

task check;
    input         cond ;
    input [511:0] msg  ;
    begin
        if (cond)
            $display("[%0t] PASS: %0s", $time, msg) ;
        else begin
            $display("[%0t] FAIL: %0s", $time, msg) ;
            err_cnt = err_cnt + 1 ;
        end
    end
endtask

// ---------------------------------------------------------------------
// Test sequence
// ---------------------------------------------------------------------
reg [7:0] rd       ;
reg [7:0] prev     ;
reg [7:0] first    ;
reg       ok       ;
reg       seen_1   ;
reg       seen_0   ;
integer   i        ;
integer   n        ;
integer   start_ix ;
integer   a0_ix    ;

initial begin
    err_cnt    = 0     ;
    ARESETn    = 1'b0  ;
    host_rst_n = 1'b0  ;
    bus_addr   = 8'h00 ;
    bus_wdata  = 8'h00 ;
    bus_wr_en  = 1'b0  ;
    bus_rd_en  = 1'b0  ;

    // Release DUT reset; SCLK is already running (interface contract)
    #(200) ;
    @(negedge ACLK) ARESETn = 1'b1 ;
    #(300) ;   // >= 2 ACLK + 2 SCLK cycles for both reset synchronizers

    // =================================================================
    // TEST 0 : reset values (host still in reset -> CS_n = 1)
    // =================================================================
    $display("[%0t] ---- TEST 0 : reset values ----", $time) ;
    bus_read(ADDR_STATUS, rd) ;
    check(rd === 8'h01, "TEST0 STATUS = 0x01 (EMPTY only)") ;
    bus_read(ADDR_CONTROL, rd) ;
    check(rd === 8'h00, "TEST0 CONTROL = 0x00") ;
    bus_read(ADDR_FIFO_LEVEL, rd) ;
    check(rd === 8'h00, "TEST0 FIFO_LEVEL = 0") ;
    bus_read(ADDR_TX_DATA, rd) ;
    check(rd === 8'h00, "TEST0 TX_DATA readback = 0x00") ;
    check(overflow === 1'b0 && rx_valid === 1'b0, "TEST0 o_overflow = 0, o_rx_valid = 0") ;

    // Start the external host (released on an SCLK falling edge)
    @(negedge SCLK) host_rst_n = 1'b1 ;

    // =================================================================
    // TEST 1 : RX path, host pattern 0x00..0x07 must arrive in order
    // =================================================================
    $display("[%0t] ---- TEST 1 : RX path ----", $time) ;
    ok = 1'b1 ;
    for (i = 0; i < 8; i = i + 1) begin
        rx_read_byte(rd) ;
        if (rd !== i[7:0]) begin
            ok = 1'b0 ;
            $display("[%0t]   RX byte %0d = %02h (expected %02h)", $time, i, rd, i[7:0]) ;
        end
    end
    check(ok, "TEST1 RX bytes 0x00..0x07 in order") ;

    // =================================================================
    // TEST 2 : TX path + TX_FULL
    // =================================================================
    $display("[%0t] ---- TEST 2 : TX path / TX_FULL ----", $time) ;
    start_ix = miso_cnt ;

    // 4 back-to-back writes fill the 4-entry TX FIFO before the SCLK side
    // can pop the first byte (that needs >= 2 SCLK edges of sync).
    bus_write(ADDR_TX_DATA, 8'hA0) ;
    bus_write(ADDR_TX_DATA, 8'hA1) ;
    bus_write(ADDR_TX_DATA, 8'hA2) ;
    bus_write(ADDR_TX_DATA, 8'hA3) ;
    bus_read (ADDR_STATUS , rd)    ;
    check(rd[ST_TX_FULL] === 1'b1, "TEST2 STATUS.TX_FULL = 1 after 4 writes") ;

    bus_read(ADDR_TX_DATA, rd) ;
    check(rd === 8'hA3, "TEST2 TX_DATA readback = 0xA3 (last written)") ;

    // TX FIFO drains into the slave -> TX_FULL must clear
    wait_status_bit(ST_TX_FULL, 1'b0, "TX_FULL clear") ;
    check(1'b1, "TEST2 STATUS.TX_FULL returns to 0 as the slave pops") ;

    // Wait until the host has captured enough frames to contain A0..A3
    // plus one more (underflow 0x00) after them.
    n = 0 ;
    a0_ix = -1 ;
    while ((n < POLL_LIMIT) && ((a0_ix < 0) || (miso_cnt < a0_ix + 5))) begin
        @(posedge ACLK) ;
        if (a0_ix < 0)
            for (i = start_ix; i < miso_cnt; i = i + 1)
                if ((a0_ix < 0) && (miso_log[i] === 8'hA0))
                    a0_ix = i ;
        n = n + 1 ;
    end

    if (a0_ix < 0) begin
        check(1'b0, "TEST2 host received 0xA0 on MISO") ;
    end else begin
        check(1'b1, "TEST2 host received 0xA0 on MISO") ;
        ok = 1'b1 ;
        for (i = start_ix; i < a0_ix; i = i + 1)
            if (miso_log[i] !== 8'h00) ok = 1'b0 ;
        check(ok, "TEST2 bytes before 0xA0 are 0x00 (TX underflow default)") ;
        check(miso_log[a0_ix+1] === 8'hA1 &&
              miso_log[a0_ix+2] === 8'hA2 &&
              miso_log[a0_ix+3] === 8'hA3, "TEST2 MISO sequence A0, A1, A2, A3 (no loss, no reorder)") ;
        check(miso_log[a0_ix+4] === 8'h00, "TEST2 MISO returns to 0x00 after the FIFO empties") ;
    end

    // =================================================================
    // TEST 3 : SPI_BUSY seen both high and low (CDC-02 path)
    // =================================================================
    $display("[%0t] ---- TEST 3 : SPI_BUSY ----", $time) ;
    seen_1 = 1'b0 ;
    seen_0 = 1'b0 ;
    n      = 0    ;
    while (!(seen_1 && seen_0) && (n < POLL_LIMIT)) begin
        bus_read(ADDR_STATUS, rd) ;
        if (rd[ST_BUSY] === 1'b1) seen_1 = 1'b1 ;
        if (rd[ST_BUSY] === 1'b0) seen_0 = 1'b1 ;
        n = n + 1 ;
    end
    check(seen_1 && seen_0, "TEST3 STATUS.SPI_BUSY toggles (frame / inter-frame gap)") ;

    // =================================================================
    // TEST 4 : RX FIFO full (CDC-01 path) + overflow + clear
    //   Software stops reading. 1 byte sits in the RX prefetch buffer,
    //   16 bytes fill the FIFO, the next frame overflows.
    // =================================================================
    $display("[%0t] ---- TEST 4 : RX FULL / OVERFLOW / CLEAR ----", $time) ;
    rd = 8'h00 ;
    n  = 0     ;
    while ((rd !== 8'd16) && (n < POLL_LIMIT)) begin
        bus_read(ADDR_FIFO_LEVEL, rd) ;
        n = n + 1 ;
    end
    check(rd === 8'd16, "TEST4 FIFO_LEVEL reaches 16") ;

    bus_read(ADDR_STATUS, rd) ;
    check(rd[ST_FULL] === 1'b1, "TEST4 STATUS.FULL = 1 when FIFO_LEVEL = 16 (ACLK-domain flag)") ;
    check(rd[ST_EMPTY] === 1'b0, "TEST4 STATUS.EMPTY = 0") ;

    wait_status_bit(ST_OVERFLOW, 1'b1, "OVERFLOW set") ;
    check(overflow === 1'b1, "TEST4 OVERFLOW sticky set, o_overflow = 1") ;

    // Issue the clear right after a frame boundary so that no new
    // overflow event can race with OVERFLOW_CLEAR: the host just finished
    // a frame (the slave's overflow pulse of that frame has crossed into
    // ACLK after ~10 cycles), and the next frame end is ~78 ACLK cycles
    // away -- long enough for the drain and the SCLK-side full flag to
    // clear first.
    @(posedge host_rx_valid) ;
    repeat (10) @(posedge ACLK) ;

    // FIFO_CLEAR (bit0) + OVERFLOW_CLEAR (bit1); IRQ_ENABLE (bit2) = 0
    bus_write(ADDR_CONTROL, 8'h03) ;
    // r_drain_active is set on the write edge; the prefetch buffer is
    // discarded on the following edge -> wait one cycle before checking.
    @(posedge ACLK) ;
    bus_read (ADDR_STATUS , rd)    ;
    check(rd[ST_OVERFLOW] === 1'b0 && overflow === 1'b0, "TEST4 OVERFLOW cleared by CONTROL[1]") ;
    check(rd[ST_RX_VALID] === 1'b0, "TEST4 RX_VALID cleared by FIFO_CLEAR (prefetch discarded)") ;

    rd = 8'd16 ;
    n  = 0     ;
    while ((rd > 8'd2) && (n < POLL_LIMIT)) begin
        bus_read(ADDR_FIFO_LEVEL, rd) ;
        n = n + 1 ;
    end
    check(rd <= 8'd2, "TEST4 FIFO drained (level <= 2 while host keeps sending)") ;
    bus_read(ADDR_STATUS, rd) ;
    check(rd[ST_FULL] === 1'b0, "TEST4 STATUS.FULL = 0 after drain") ;

    // =================================================================
    // TEST 5 : RX continuity after the clear
    // =================================================================
    $display("[%0t] ---- TEST 5 : RX after clear ----", $time) ;
    rx_read_byte(first) ;
    prev = first ;
    ok   = 1'b1  ;
    for (i = 0; i < 4; i = i + 1) begin
        rx_read_byte(rd) ;
        if (rd !== prev + 8'd1) begin
            ok = 1'b0 ;
            $display("[%0t]   RX %02h after %02h (expected %02h)", $time, rd, prev, prev + 8'd1) ;
        end
        prev = rd ;
    end
    check(ok, "TEST5 5 consecutive RX bytes increment by 1 after FIFO_CLEAR") ;

    // =================================================================
    // Summary
    // =================================================================
    #(1000) ;
    if (err_cnt == 0)
        $display("[%0t] ALL TESTS PASSED (tb_spi_slave_bridge)", $time) ;
    else
        $display("[%0t] TESTS FAILED (tb_spi_slave_bridge) : %0d error(s)", $time, err_cnt) ;
    $finish ;
end

endmodule

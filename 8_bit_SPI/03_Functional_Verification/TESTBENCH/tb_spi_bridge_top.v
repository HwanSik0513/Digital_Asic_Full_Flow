`timescale 1ns / 1ps

module tb_spi_bridge_top;

localparam [7:0] ADDR_RX_DATA    = 8'h00 ,
                 ADDR_STATUS     = 8'h04 ,
                 ADDR_CONTROL    = 8'h08 ,
                 ADDR_FIFO_LEVEL = 8'h0C ,
                 ADDR_TX_DATA    = 8'h10 ;

localparam N_RX_FRAMES = 6 ;

// ============================================================
// Signal Declaration
// ============================================================

reg ACLK    ;
reg ARESETn ;

reg [7:0] i_bus_addr  ;
reg       i_bus_wr_en ;
reg [7:0] i_bus_wdata ;
reg       i_bus_rd_en ;

wire [7:0] o_bus_rdata ;

wire o_overflow ;
wire o_rx_valid ;

wire o_dbg_sclk ;
wire o_dbg_cs_n ;
wire o_dbg_mosi ;
wire o_dbg_miso ;

integer errors           ;
integer tx_frames_waited ;
reg     tx_match_found   ;

integer       rx_full_frames                                ;
reg     [7:0] test4_status                                  ;
reg     [7:0] test4_level                                   ;
integer       tx5_attempted, tx5_accepted, tx5_full_cycles  ;
integer       tx5_frames, tx5_checked, tx5_scan, tx5_errors ;
reg           tx5_monitor, tx5_capture                      ;
reg     [7:0] tx5_expected [0:31]                           ;
reg     [7:0] tx5_observed [0:31]                           ;
reg     [7:0] test6_status, test6_rx                        ;
integer       test6_wait, test6_tx_frames                   ;
reg           test6_tx_found                                ;
integer       burst_idx                                     ;
integer       burst_frames_waited                           ;
reg     [7:0] burst_expected                                ;
reg           burst_failed                                  ;
reg           burst_started                                 ;

// ============================================================
// DUT Instantiation
// ============================================================

spi_bridge_top dut (
    .ACLK        (ACLK)        ,
    .ARESETn     (ARESETn)     ,
    .i_bus_addr  (i_bus_addr)  ,
    .i_bus_wr_en (i_bus_wr_en) ,
    .i_bus_wdata (i_bus_wdata) ,
    .i_bus_rd_en (i_bus_rd_en) ,
    .o_bus_rdata (o_bus_rdata) ,
    .o_overflow  (o_overflow)  ,
    .o_rx_valid  (o_rx_valid)  ,
    .o_dbg_sclk  (o_dbg_sclk)  ,
    .o_dbg_cs_n  (o_dbg_cs_n)  ,
    .o_dbg_mosi  (o_dbg_mosi)  ,
    .o_dbg_miso  (o_dbg_miso)
);

// ============================================================
// Clock Generation
// ============================================================

initial ACLK = 1'b0;

always #5 ACLK = ~ACLK; // 100 MHz

// ============================================================
// Bus Write Task
// ============================================================

task bus_write(input [7:0] addr, input [7:0] data);
begin
    @(negedge ACLK);

    i_bus_addr  = addr ;
    i_bus_wdata = data ;
    i_bus_wr_en = 1'b1 ;

    @(negedge ACLK);

    i_bus_wr_en = 1'b0 ;
end
endtask

// ============================================================
// Bus Read Task
// ============================================================

task bus_read(input [7:0] addr, output [7:0] data);
begin
    @(posedge ACLK);

    i_bus_addr  = addr ;
    i_bus_rd_en = 1'b1 ;

    #1;
    data = o_bus_rdata ;

    @(posedge ACLK);

    i_bus_rd_en = 1'b0 ;
end
endtask

// ============================================================
// Check Task
// ============================================================

task check_eq(
    input [255:0] label ,
    input [31:0]  exp   ,
    input [31:0]  got
);
begin
    if (exp !== got) begin

        $display(
            "[%0t] FAIL: %0s expected=%0h got=%0h",
            $time, label, exp, got
        );

        errors = errors + 1 ;

    end
    else begin

        $display(
            "[%0t] PASS: %0s = %0h",
            $time, label, got
        );

    end
end
endtask

// ============================================================
// MISO Capture Monitor
// ============================================================

reg [7:0] miso_shift      ;
reg [2:0] miso_bit_idx    ;
reg       miso_capturing  ;
reg [7:0] miso_last_byte  ;
reg       miso_byte_ready ;

initial begin
    miso_shift      = 8'h00 ;
    miso_last_byte  = 8'h00 ;
    miso_capturing  = 1'b0  ;
    miso_byte_ready = 1'b0  ;
    miso_bit_idx    = 3'd0  ;
end

// New SPI frame
always @(negedge o_dbg_cs_n) begin
    miso_capturing  = 1'b1  ;
    miso_bit_idx    = 3'd0  ;
    miso_byte_ready = 1'b0  ;
    miso_shift      = 8'h00 ;
end

// SPI frame ended
always @(posedge o_dbg_cs_n) begin
    miso_capturing = 1'b0 ;
end

// Capture MISO on rising edge of SCLK
always @(posedge o_dbg_sclk) begin

    if (!o_dbg_cs_n &&
        dut.u_spi_master.state == 2'd2) begin

        miso_shift = {
            miso_shift[6:0],
            o_dbg_miso
        };

        if (miso_bit_idx == 3'd7) begin

            miso_last_byte  = miso_shift ;
            miso_byte_ready = 1'b1       ;
            miso_bit_idx    = 3'd0       ;

        end
        else begin

            miso_bit_idx = miso_bit_idx + 3'd1 ;

        end
    end
end

// ============================================================
// TX DEBUG MONITOR
// ============================================================

// Observe TX FIFO -> Holding Register -> Shift Register -> MISO

always @(posedge o_dbg_sclk) begin

    if (ARESETn &&
        $time >= 4800 &&
        $time <= 15000) begin

        $display(
            "[%0t] TX_DEBUG CS=%b STATE=%0d BIT=%0d HOLD=%02h VALID=%b CUR=%b SHIFT=%02h POP=%b MISO=%b",
            $time,
            o_dbg_cs_n ,
            dut.u_spi_slave.state,
            dut.u_spi_slave.bit_cnt,
            dut.u_spi_slave.r_tx_hold,
            dut.u_spi_slave.r_tx_hold_valid,
            dut.u_spi_slave.r_tx_cur_from_hold,
            dut.u_spi_slave.r_shift_tx,
            dut.u_spi_slave.o_tx_fifo_rd_en,
            o_dbg_miso
        );

    end
end

// ============================================================
// TEST 5 monitors: FIFO handshake and completed SPI frames
// ============================================================
initial begin
    tx5_monitor     = 1'b0 ;
    tx5_capture     = 1'b0 ;
    tx5_accepted    = 0    ;
    tx5_full_cycles = 0    ;
    tx5_frames      = 0    ;
end

always @(posedge ACLK) begin
    if (ARESETn && tx5_monitor) begin
        if (dut.w_tx_fifo_full)
            tx5_full_cycles = tx5_full_cycles + 1 ;
        if (dut.w_tx_fifo_wr_en && !dut.w_tx_fifo_full) begin
            if (tx5_accepted < 32)
                tx5_expected[tx5_accepted] = dut.w_tx_fifo_wr_data ;
            tx5_accepted = tx5_accepted + 1 ;
            $display("[%0t] TEST5 FIFO ACCEPT %02h", $time,
                     dut.w_tx_fifo_wr_data);
        end
    end
end

always @(posedge o_dbg_cs_n) begin
    if (ARESETn && tx5_capture) begin
        #1;
        if (miso_byte_ready && tx5_frames < 32) begin
            tx5_observed[tx5_frames] = miso_last_byte ;
            tx5_frames               = tx5_frames + 1 ;
        end
    end
end

// ============================================================
// RX Test Variables
// ============================================================

integer expected_rx_byte  ;
integer rx_frames_checked ;

reg [7:0] status_val ;
reg [7:0] rx_val     ;

// TEST 7 variables
integer       test7_iter     ;
integer       test7_wait     ;
integer       test7_frames   ;
reg     [7:0] test7_status   ;
reg     [7:0] test7_rx       ;
reg           test7_tx_found ;


// ============================================================
// TEST 8 - Independent Async FIFO CDC/Gray-pointer verification
// ACLK=100MHz (write), test8_rd_clk ~71.4MHz (read).
// This separate FIFO instance isolates CDC data-integrity tests
// from the continuously running SPI traffic of TEST 1-7.
// ============================================================
reg test8_rd_clk = 1'b0 ;
always #7 test8_rd_clk = ~test8_rd_clk;
reg           test8_rst_n                              = 1'b0  ;
reg           test8_wr_en                              = 1'b0  ;
reg     [7:0] test8_wr_data                            = 8'h00 ;
reg           test8_rd_en                              = 1'b0  ;
wire    [7:0] test8_rd_data                                    ;
wire          test8_full, test8_empty                          ;
wire    [4:0] test8_rd_level                                   ;
integer       test8_i                                          ;
integer       test8_gray_errors                                ;
integer       test8_write_count                                ;
integer       test8_read_count                                 ;
reg     [4:0] test8_prev_wr_gray, test8_prev_rd_gray           ;
reg     [4:0] test8_wr_gray_delta, test8_rd_gray_delta         ;
reg           test8_track_gray                         = 1'b0  ;

async_fifo #(.DATA_WIDTH(8), .ADDR_WIDTH(4)) test8_fifo (
    .wr_clk  (ACLK), .wr_rst_n(test8_rst_n)             ,
    .i_wr_en (test8_wr_en), .i_wr_data(test8_wr_data)   ,
    .o_full  (test8_full)                               ,
    .rd_clk  (test8_rd_clk), .rd_rst_n(test8_rst_n)     ,
    .i_rd_en (test8_rd_en), .o_rd_data(test8_rd_data)   ,
    .o_empty (test8_empty), .o_rd_level(test8_rd_level)
);

// Each actual pointer transition must flip exactly one Gray bit.
always @(negedge ACLK) begin
    if (test8_track_gray && test8_rst_n) begin
        test8_wr_gray_delta = test8_fifo.r_wr_ptr_gray ^ test8_prev_wr_gray ;
        if (test8_wr_gray_delta != 0 &&
            (test8_wr_gray_delta & (test8_wr_gray_delta - 5'd1)) != 0) begin
            $display("[%0t] FAIL TEST8 write Gray transition %b", $time, test8_wr_gray_delta);
            test8_gray_errors = test8_gray_errors + 1 ;
        end
        test8_prev_wr_gray = test8_fifo.r_wr_ptr_gray ;
    end
end
always @(negedge test8_rd_clk) begin
    if (test8_track_gray && test8_rst_n) begin
        test8_rd_gray_delta = test8_fifo.r_rd_ptr_gray ^ test8_prev_rd_gray ;
        if (test8_rd_gray_delta != 0 &&
            (test8_rd_gray_delta & (test8_rd_gray_delta - 5'd1)) != 0) begin
            $display("[%0t] FAIL TEST8 read Gray transition %b", $time, test8_rd_gray_delta);
            test8_gray_errors = test8_gray_errors + 1 ;
        end
        test8_prev_rd_gray = test8_fifo.r_rd_ptr_gray ;
    end
end

task test8_push(input [7:0] data);
integer watchdog ;
begin
    watchdog = 0 ;
    @(negedge ACLK);
    while (test8_full && watchdog < 100) begin
        @(negedge ACLK);
        watchdog = watchdog + 1 ;
    end
    if (test8_full) begin
        $display("FAIL TEST8 write timeout"); errors = errors + 1;
    end else begin
        test8_wr_data = data ;
        test8_wr_en   = 1'b1 ;
        @(negedge ACLK);
        test8_wr_en       = 1'b0                  ;
        test8_write_count = test8_write_count + 1 ;
    end
end
endtask

task test8_pop(input [7:0] expected);
integer watchdog ;
begin
    watchdog = 0 ;
    @(negedge test8_rd_clk);
    while (test8_empty && watchdog < 100) begin
        @(negedge test8_rd_clk);
        watchdog = watchdog + 1 ;
    end
    if (test8_empty) begin
        $display("FAIL TEST8 read timeout"); errors = errors + 1;
    end else begin
        test8_rd_en = 1'b1 ;
        @(posedge test8_rd_clk);
        #1;
        if (test8_rd_data !== expected) begin
            $display("[%0t] FAIL TEST8 FIFO expected=%02h got=%02h", $time, expected, test8_rd_data);
            errors = errors + 1 ;
        end
        @(negedge test8_rd_clk);
        test8_rd_en      = 1'b0                 ;
        test8_read_count = test8_read_count + 1 ;
    end
end
endtask

// TEST 9/10 variables
integer       test9_written, test9_read, test9_stalls, test9_timeout ;
reg     [7:0] test9_expected                                         ;
reg     [7:0] test10_data, test10_status                             ;
integer       test10_wait                                            ;


// ============================================================
// Main Test Sequence
// ============================================================

initial begin

    errors            = 0 ;
    expected_rx_byte  = 0 ;
    rx_frames_checked = 0 ;

    i_bus_addr  = 8'h00 ;
    i_bus_wr_en = 1'b0  ;
    i_bus_wdata = 8'h00 ;
    i_bus_rd_en = 1'b0  ;

    ARESETn = 1'b0 ;

    // --------------------------------------------------------
    // Reset Sequence
    // --------------------------------------------------------

    repeat (10) @(posedge ACLK);

    ARESETn = 1'b1 ;

    repeat (10) @(posedge ACLK);

    // --------------------------------------------------------
    // TEST 1 - RX Path
    // --------------------------------------------------------

    $display(
        "[%0t] TEST 1: RX path end-to-end, %0d frames",
        $time, N_RX_FRAMES
    );

    while (rx_frames_checked < N_RX_FRAMES) begin

        bus_read(ADDR_STATUS, status_val);

        if (status_val[3]) begin

            bus_read(ADDR_RX_DATA, rx_val);

            check_eq(
                "RX_DATA_REG sequential byte",
                expected_rx_byte[7:0],
                rx_val
            );

            expected_rx_byte =
                (expected_rx_byte + 1) & 8'hFF;

            rx_frames_checked =
                rx_frames_checked + 1;

        end
        else begin

            repeat (20) @(posedge ACLK);

        end
    end

    // --------------------------------------------------------
    // TEST 2 - TX Path
    // --------------------------------------------------------

    $display(
        "[%0t] TEST 2: TX path end-to-end",
        $time
    );

    bus_write(ADDR_TX_DATA, 8'h5A);

    tx_frames_waited = 0    ;
    tx_match_found   = 1'b0 ;

    // Check current and upcoming frames
    while ((tx_frames_waited < 4) && !tx_match_found) begin

        @(posedge o_dbg_cs_n);

        #1;

        tx_frames_waited = tx_frames_waited + 1 ;

        $display(
            "[%0t] TX frame %0d: MISO = 0x%02h READY=%b",
            $time,
            tx_frames_waited ,
            miso_last_byte   ,
            miso_byte_ready
        );

        if (miso_byte_ready &&
            miso_last_byte === 8'h5A) begin

            tx_match_found = 1'b1 ;

        end
    end

    check_eq(
        "TX_DATA_REG to MISO",
        1,
        tx_match_found
    );

    // --------------------------------------------------------
    // TEST 3 - TX Burst Path
    // --------------------------------------------------------

    $display(
        "[%0t] TEST 3: TX Burst path end-to-end",
        $time
    );

    // Write three consecutive bytes into TX FIFO
    bus_write(ADDR_TX_DATA, 8'h11);
    bus_write(ADDR_TX_DATA, 8'h22);
    bus_write(ADDR_TX_DATA, 8'h33);

    burst_idx           = 0    ;
    burst_frames_waited = 0    ;
    burst_failed        = 1'b0 ;
    burst_started       = 1'b0 ;

    // Wait for completed SPI frames.
    // Before the first byte, empty frames are permitted.
    // After the first byte, the order must be exact.
    while ((burst_idx < 3) &&
           (burst_frames_waited < 8) &&
           !burst_failed) begin

        @(posedge o_dbg_cs_n);

        #1;

        burst_frames_waited = burst_frames_waited + 1 ;

        $display(
            "[%0t] BURST frame %0d: MISO=0x%02h READY=%b",
            $time,
            burst_frames_waited ,
            miso_last_byte      ,
            miso_byte_ready
        );

        case (burst_idx)
            0: burst_expected = 8'h11;
            1: burst_expected = 8'h22;
            2: burst_expected = 8'h33;
            default : burst_expected = 8'h00 ;
        endcase

        if (miso_byte_ready &&
            miso_last_byte === burst_expected) begin

            $display(
                "[%0t] PASS: TX Burst byte %0d = 0x%02h",
                $time,
                burst_idx + 1,
                miso_last_byte
            );

            burst_started = 1'b1          ;
            burst_idx     = burst_idx + 1 ;

        end
        else if (!burst_started &&
                 miso_byte_ready &&
                 miso_last_byte === 8'h00) begin

            $display(
                "[%0t] INFO: Waiting for first TX Burst byte",
                $time
            );

        end
        else begin

            $display(
                "[%0t] FAIL: TX Burst expected=0x%02h got=0x%02h",
                $time,
                burst_expected ,
                miso_last_byte
            );

            errors       = errors + 1 ;
            burst_failed = 1'b1       ;

        end
    end

    if (!burst_failed && burst_idx != 3) begin

        $display(
            "[%0t] FAIL: TX Burst incomplete (%0d/3 bytes)",
            $time,
            burst_idx
        );

        errors = errors + 1 ;

    end

    if (!burst_failed && burst_idx == 3) begin

        $display(
            "[%0t] PASS: TX Burst sequence 11 -> 22 -> 33",
            $time
        );

    end

    // --------------------------------------------------------
    // TEST 4 - RX FIFO Full / Overflow / Clear
    // --------------------------------------------------------
    $display("[%0t] TEST 4: RX FIFO Full / Overflow", $time);

    // Drain old RX data accumulated during TX tests.
    // CONTROL[0]=FIFO_CLEAR; CONTROL[1]=OVERFLOW_CLEAR.
    bus_write(ADDR_CONTROL, 8'h03);
    wait (dut.u_register_block.r_drain_active == 1'b1);
    wait (dut.u_register_block.r_drain_active == 1'b0);
    repeat (8) @(posedge ACLK);

    // No RX_DATA reads: one byte may be held in the prefetch buffer,
    // and the remaining 16 bytes can occupy the RX FIFO.
    // Start counting only after a frame boundary.
    @(posedge o_dbg_cs_n);
    rx_full_frames = 0 ;
    repeat (22) begin
        @(posedge o_dbg_cs_n);
        rx_full_frames = rx_full_frames + 1 ;
    end
    repeat (12) @(posedge ACLK); // allow overflow CDC to settle

    bus_read(ADDR_STATUS, test4_status);
    bus_read(ADDR_FIFO_LEVEL, test4_level);
    $display("[%0t] TEST4 status=%02h level=%0d overflow=%b",
             $time, test4_status, test4_level, o_overflow);

    check_eq("TEST4 RX FIFO FULL", 1, dut.w_rx_fifo_full);
    check_eq("TEST4 RX FIFO LEVEL", 16, test4_level);
    check_eq("TEST4 OVERFLOW sticky", 1, test4_status[4]);
    check_eq("TEST4 OVERFLOW output", 1, o_overflow);

    // Clear FIFO while master continues free-running. Do not require
    // FIFO to remain empty: new SPI frames may arrive immediately.
    bus_write(ADDR_CONTROL, 8'h01);
    wait (dut.u_register_block.r_drain_active == 1'b1);
    wait (dut.u_register_block.r_drain_active == 1'b0);
    repeat (8) @(posedge ACLK);
    check_eq("TEST4 FULL cleared after drain", 0, dut.w_rx_fifo_full);

    // Overflow flag is sticky until CONTROL[1] is strobed.
    // After draining, it should not immediately reassert.
    bus_write(ADDR_CONTROL, 8'h02);
    repeat (5) @(posedge ACLK);
    bus_read(ADDR_STATUS, test4_status);
    check_eq("TEST4 OVERFLOW cleared", 0, test4_status[4]);

    // --------------------------------------------------------
    // TEST 5 - TX FIFO Full and data integrity
    // --------------------------------------------------------
    $display("[%0t] TEST 5: TX FIFO Full / Boundary", $time);

    // TX was consumed in TEST 2/3. RX drain is independent.
    // Synchronize with frame end so capture begins before writes.
    @(posedge o_dbg_cs_n);
    #2;
    tx5_attempted   = 8    ;
    tx5_accepted    = 0    ;
    tx5_full_cycles = 0    ;
    tx5_frames      = 0    ;
    tx5_monitor     = 1'b1 ;
    tx5_capture     = 1'b1 ;

    bus_write(ADDR_TX_DATA, 8'hA1);
    bus_write(ADDR_TX_DATA, 8'hB2);
    bus_write(ADDR_TX_DATA, 8'hC3);
    bus_write(ADDR_TX_DATA, 8'hD4);
    bus_write(ADDR_TX_DATA, 8'hE5);
    bus_write(ADDR_TX_DATA, 8'hF6);
    bus_write(ADDR_TX_DATA, 8'h17);
    bus_write(ADDR_TX_DATA, 8'h28);
    repeat (4) @(negedge ACLK);
    tx5_monitor = 1'b0 ;

    $display("TEST5 ATTEMPTED=%0d ACCEPTED=%0d NOT_ACCEPTED=%0d FULL_CYCLES=%0d",
             tx5_attempted, tx5_accepted, tx5_attempted-tx5_accepted,
             tx5_full_cycles);
    if (tx5_accepted > tx5_attempted || tx5_accepted < 1) begin
        $display("FAIL: TEST5 invalid accepted count");
        errors = errors + 1 ;
    end
    if (tx5_full_cycles == 0) begin
        $display("FAIL: TEST5 FIFO Full not observed");
        errors = errors + 1 ;
    end else $display("PASS: TEST5 FIFO Full observed");
    if (tx5_accepted == tx5_attempted) begin
        $display("FAIL: TEST5 Full rejection not exercised");
        errors = errors + 1 ;
    end

    // Capture enough complete frames to drain accepted bytes.
    repeat (8) @(posedge o_dbg_cs_n);
    #2;
    tx5_capture = 1'b0 ;
    tx5_scan    = 0    ;
    tx5_checked = 0    ;
    tx5_errors  = 0    ;
    // Leading 0x00 frames may precede first queued TX byte.
    while (tx5_scan < tx5_frames &&
           tx5_observed[tx5_scan] === 8'h00)
        tx5_scan = tx5_scan + 1 ;
    while (tx5_checked < tx5_accepted && tx5_scan < tx5_frames) begin
        if (tx5_observed[tx5_scan] !== tx5_expected[tx5_checked]) begin
            $display("FAIL: TEST5 order[%0d] expected=%02h got=%02h",
                     tx5_checked, tx5_expected[tx5_checked],
                     tx5_observed[tx5_scan]);
            errors     = errors + 1     ;
            tx5_errors = tx5_errors + 1 ;
        end else begin
            $display("PASS: TEST5 order[%0d]=%02h",
                     tx5_checked, tx5_observed[tx5_scan]);
        end
        tx5_checked = tx5_checked + 1 ;
        tx5_scan    = tx5_scan + 1    ;
    end
    if (tx5_checked != tx5_accepted) begin
        $display("FAIL: TEST5 incomplete TX drain");
        errors = errors + 1 ;
    end

    // --------------------------------------------------------
    // TEST 6 - Reset during active SPI transfer
    // --------------------------------------------------------
    $display("[%0t] TEST 6: Reset During Transfer", $time);

    // Put a distinctive byte in the TX path before interruption.
    bus_write(ADDR_TX_DATA, 8'h96);
    // Wait until an actual frame is in the middle of SHIFT.
    wait (o_dbg_cs_n == 1'b0 &&
          dut.u_spi_master.state == 2'd2 &&
          dut.u_spi_master.bit_cnt >= 3'd3);
    @(negedge ACLK);
    $display("[%0t] TEST6 ASSERT RESET mid-frame CS=%b BIT=%0d",
             $time, o_dbg_cs_n, dut.u_spi_master.bit_cnt);
    ARESETn     = 1'b0 ;
    i_bus_wr_en = 1'b0 ;
    i_bus_rd_en = 1'b0 ;

    // Allow both clock-domain reset synchronizers to assert.
    repeat (12) @(negedge ACLK);
    check_eq("TEST6 CS inactive in reset", 1, o_dbg_cs_n);
    check_eq("TEST6 RX FIFO empty in reset", 1, dut.w_rx_fifo_empty);
    check_eq("TEST6 TX FIFO empty in reset", 1, dut.w_tx_fifo_empty);
    check_eq("TEST6 overflow cleared in reset", 0, o_overflow);
    check_eq("TEST6 RX valid cleared in reset", 0, o_rx_valid);

    // Release reset; both domains use synchronized deassertion.
    @(negedge ACLK);
    ARESETn = 1'b1 ;
    repeat (12) @(negedge ACLK);

    // Fresh master frame should restart at byte 0 after reset.
    // Poll RX_VALID with bounded timeout, then read the first byte.
    test6_wait   = 0     ;
    test6_status = 8'h00 ;
    while (!test6_status[3] && test6_wait < 160) begin
        bus_read(ADDR_STATUS, test6_status);
        test6_wait = test6_wait + 1 ;
        if (!test6_status[3]) repeat (5) @(negedge ACLK);
    end
    if (!test6_status[3]) begin
        $display("FAIL: TEST6 RX did not recover after reset");
        errors = errors + 1 ;
    end else begin
        bus_read(ADDR_RX_DATA, test6_rx);
        check_eq("TEST6 first RX byte after reset", 0, test6_rx);
    end

    // Also verify fresh TX data can be sent after reset.
    bus_write(ADDR_TX_DATA, 8'h6B);
    test6_tx_found  = 1'b0 ;
    test6_tx_frames = 0    ;
    while (!test6_tx_found && test6_tx_frames < 5) begin
        @(posedge o_dbg_cs_n);
        #1;
        test6_tx_frames = test6_tx_frames + 1 ;
        $display("[%0t] TEST6 recovery MISO frame %0d = %02h",
                 $time, test6_tx_frames, miso_last_byte);
        if (miso_byte_ready && miso_last_byte === 8'h6B)
            test6_tx_found = 1'b1 ;
    end
    check_eq("TEST6 TX recovered after reset", 1, test6_tx_found);

    // --------------------------------------------------------
    // TEST 7 - Repeated Reset / Short Pulse / Recovery
    // --------------------------------------------------------
    $display("[%0t] TEST 7: Repeated Reset / Release Timing", $time);

    // Three asynchronous reset assertions during an active frame.
    // Pulse widths: 7ns, 13ns, 55ns. Each is checked independently.
    for (test7_iter = 0; test7_iter < 3; test7_iter = test7_iter + 1) begin
        // Ensure we interrupt a real active transfer, not an idle gap.
        wait (o_dbg_cs_n === 1'b1);
        wait (o_dbg_cs_n === 1'b0);
        repeat (3) @(posedge o_dbg_sclk);
        #2;
        $display("[%0t] TEST7 RESET #%0d asserted during transfer",
                 $time, test7_iter + 1);
        ARESETn     = 1'b0 ;
        i_bus_wr_en = 1'b0 ;
        i_bus_rd_en = 1'b0 ;

        // Asynchronous assertion: CS must return high without waiting
        // for another SCLK edge. Allow delta cycles to settle.
        #1;
        check_eq("TEST7 CS released on reset assert", 1, o_dbg_cs_n);
        check_eq("TEST7 overflow reset", 0, o_overflow);
        // Short reset pulses do not guarantee ACLK-domain reset visibility.
        // Check RX valid only after the long (55 ns) reset has settled.

        case (test7_iter)
            0: #6;  // 7ns total
            1: #12; // 13ns total
            2: #54; // 55ns total
        endcase
        check_eq("TEST7 RX FIFO reset", 1, dut.w_rx_fifo_empty);
        check_eq("TEST7 TX FIFO reset", 1, dut.w_tx_fifo_empty);
        if (test7_iter == 2) begin
            check_eq("TEST7 RX valid reset (55ns pulse)", 0, o_rx_valid);
        end

        // Release at an intentionally offset phase relative to ACLK.
        // This is a functional reset test, not a physical recovery/removal
        // or metastability proof.
        @(negedge ACLK);
        #1;
        ARESETn = 1'b1 ;
        repeat (12) @(negedge ACLK);

        // Verify a fresh RX transaction after *each* reset.
        test7_wait   = 0     ;
        test7_status = 8'h00 ;
        while (!test7_status[3] && test7_wait < 180) begin
            bus_read(ADDR_STATUS, test7_status);
            test7_wait = test7_wait + 1 ;
            if (!test7_status[3]) repeat (5) @(negedge ACLK);
        end
        if (!test7_status[3]) begin
            $display("FAIL: TEST7 RX recovery after reset #%0d", test7_iter+1);
            errors = errors + 1 ;
        end else begin
            bus_read(ADDR_RX_DATA, test7_rx);
            check_eq("TEST7 first RX byte after reset", 8'h00, test7_rx);
        end
    end

    // After the final reset, verify TX path as well.
    @(posedge o_dbg_cs_n);
    #2;
    bus_write(ADDR_TX_DATA, 8'hA7);
    test7_tx_found = 1'b0 ;
    test7_frames   = 0    ;
    while (!test7_tx_found && test7_frames < 6) begin
        @(posedge o_dbg_cs_n);
        #1;
        test7_frames = test7_frames + 1 ;
        $display("[%0t] TEST7 recovery TX frame %0d = %02h",
                 $time, test7_frames, miso_last_byte);
        if (miso_byte_ready && miso_last_byte === 8'hA7)
            test7_tx_found = 1'b1 ;
    end
    check_eq("TEST7 TX recovered after repeated resets", 1, test7_tx_found);


    // --------------------------------------------------------
    // TEST 8 - Async FIFO CDC, Gray pointer, full/empty, ordering
    // --------------------------------------------------------
    $display("[%0t] TEST 8: Async FIFO CDC/Gray pointer", $time);
    test8_gray_errors = 0    ;
    test8_write_count = 0    ;
    test8_read_count  = 0    ;
    test8_rst_n       = 1'b0 ;
    repeat (5) @(negedge ACLK);
    test8_rst_n = 1'b1 ;
    repeat (5) @(negedge ACLK);
    check_eq("TEST8 initial empty", 1, test8_empty);
    check_eq("TEST8 initial not full", 0, test8_full);
    test8_prev_wr_gray = test8_fifo.r_wr_ptr_gray ;
    test8_prev_rd_gray = test8_fifo.r_rd_ptr_gray ;
    test8_track_gray   = 1'b1                     ;

    // Fill all 16 locations, exercising the write pointer wrap boundary.
    for (test8_i = 0; test8_i < 16; test8_i = test8_i + 1)
        test8_push(8'h40 + test8_i);
    #1;
    check_eq("TEST8 full at 16 writes", 1, test8_full);
    // Full must inhibit writes, including if wr_en is asserted.
    @(negedge ACLK);
    test8_wr_data = 8'hEE ;
    test8_wr_en   = 1'b1  ;
    repeat (3) @(negedge ACLK);
    test8_wr_en = 1'b0 ;
    check_eq("TEST8 full blocks extra write", 16, test8_fifo.r_wr_ptr_bin);

    // Drain at a different clock frequency and check every data byte.
    for (test8_i = 0; test8_i < 16; test8_i = test8_i + 1)
        test8_pop(8'h40 + test8_i);
    repeat (5) @(negedge test8_rd_clk);
    check_eq("TEST8 empty after 16 reads", 1, test8_empty);
    check_eq("TEST8 level zero", 0, test8_rd_level);

    // Cross the pointer wrap-around twice more with distinct patterns.
    for (test8_i = 0; test8_i < 16; test8_i = test8_i + 1)
        test8_push(8'h80 + test8_i);
    for (test8_i = 0; test8_i < 16; test8_i = test8_i + 1)
        test8_pop(8'h80 + test8_i);
    repeat (5) @(negedge test8_rd_clk);
    check_eq("TEST8 empty after wrap", 1, test8_empty);
    check_eq("TEST8 Gray single-bit transitions", 0, test8_gray_errors);
    check_eq("TEST8 write count", 32, test8_write_count);
    check_eq("TEST8 read count", 32, test8_read_count);
    test8_track_gray = 1'b0 ;

    // --------------------------------------------------------
    // TEST 9 - Concurrent asynchronous FIFO read/write stress
    // 128 deterministic pseudo-random-pattern bytes. Both clock
    // domains operate concurrently; each successful read is checked.
    // --------------------------------------------------------
    $display("[%0t] TEST 9: Concurrent FIFO read/write stress", $time);
    test8_track_gray = 1'b0 ;
    test8_wr_en      = 1'b0 ;
    test8_rd_en      = 1'b0 ;
    test8_rst_n      = 1'b0 ;
    repeat (5) @(negedge ACLK);
    test8_rst_n = 1'b1 ;
    repeat (6) @(negedge test8_rd_clk);
    check_eq("TEST9 initial empty", 1, test8_empty);
    test9_written = 0 ;
    test9_read    = 0 ;
    test9_stalls  = 0 ;
    fork
        begin : test9_writer
            while (test9_written < 128) begin
                @(negedge ACLK);
                test8_wr_en = 1'b0 ;
                if (!test8_full && ((test9_written % 7) != 3)) begin
                    test8_wr_data = ((test9_written * 37) ^ (test9_written >> 2) ^ 8'hA5) & 8'hFF ;
                    test8_wr_en   = 1'b1                                                          ;
                    test9_written = test9_written + 1                                             ;
                end else if ((test9_written % 7) == 3) begin
                    // deterministic idle slot, prevent permanent stall
                    @(negedge ACLK);
                    if (!test8_full) begin
                        test8_wr_data = ((test9_written * 37) ^ (test9_written >> 2) ^ 8'hA5) & 8'hFF ;
                        test8_wr_en   = 1'b1                                                          ;
                        test9_written = test9_written + 1                                             ;
                    end
                end else test9_stalls = test9_stalls + 1;
            end
            @(negedge ACLK);
            test8_wr_en = 1'b0 ;
        end
        begin : test9_reader
            while (test9_read < 128) begin
                @(negedge test8_rd_clk);
                test8_rd_en = 1'b0 ;
                if (!test8_empty && ((test9_read % 5) != 2)) begin
                    test8_rd_en = 1'b1 ;
                    @(posedge test8_rd_clk);
                    #1;
                    test9_expected = ((test9_read * 37) ^ (test9_read >> 2) ^ 8'hA5) & 8'hFF ;
                    if (test8_rd_data !== test9_expected) begin
                        $display("[%0t] FAIL TEST9 byte[%0d] expected=%02h got=%02h", $time, test9_read, test9_expected, test8_rd_data);
                        errors = errors + 1 ;
                    end
                    test9_read = test9_read + 1 ;
                end else if ((test9_read % 5) == 2) begin
                    @(negedge test8_rd_clk);
                    if (!test8_empty) begin
                        test8_rd_en = 1'b1 ;
                        @(posedge test8_rd_clk);
                        #1;
                        test9_expected = ((test9_read * 37) ^ (test9_read >> 2) ^ 8'hA5) & 8'hFF ;
                        if (test8_rd_data !== test9_expected) begin
                            $display("[%0t] FAIL TEST9 byte[%0d] expected=%02h got=%02h", $time, test9_read, test9_expected, test8_rd_data);
                            errors = errors + 1 ;
                        end
                        test9_read = test9_read + 1 ;
                    end
                end
            end
            @(negedge test8_rd_clk);
            test8_rd_en = 1'b0 ;
        end
    join
    repeat (6) @(negedge test8_rd_clk);
    check_eq("TEST9 writes", 128, test9_written);
    check_eq("TEST9 reads", 128, test9_read);
    check_eq("TEST9 FIFO empty", 1, test8_empty);
    check_eq("TEST9 FIFO level", 0, test8_rd_level);

    // --------------------------------------------------------
    // TEST 10 - Register decode / control / RX drain / protocol
    // --------------------------------------------------------
    $display("[%0t] TEST 10: Register and protocol corner cases", $time);
    ARESETn = 1'b0 ;
    repeat (8) @(negedge ACLK);
    ARESETn = 1'b1 ;
    repeat (10) @(negedge ACLK);
    bus_read(8'hFE, test10_data);
    check_eq("TEST10 unmapped address reads zero", 0, test10_data);
    bus_write(ADDR_CONTROL, 8'h04);
    bus_read(ADDR_CONTROL, test10_data);
    check_eq("TEST10 IRQ enable readback", 8'h04, test10_data);
    bus_write(ADDR_CONTROL, 8'h00);
    bus_read(ADDR_CONTROL, test10_data);
    check_eq("TEST10 IRQ disable readback", 0, test10_data);
    // RX is continuously produced by master; request drain and check
    // the control pulse is accepted and eventually completes.
    bus_write(ADDR_CONTROL, 8'h01);
    test10_wait = 0 ;
    while (dut.u_register_block.r_drain_active && test10_wait < 100) begin
        @(negedge ACLK);
        test10_wait = test10_wait + 1 ;
    end
    check_eq("TEST10 drain finishes", 0, dut.u_register_block.r_drain_active);
    bus_write(ADDR_CONTROL, 8'h02);
    repeat (4) @(negedge ACLK);
    check_eq("TEST10 overflow clear", 0, o_overflow);
    // Verify CS returns idle and another SPI frame completes.
    @(posedge o_dbg_cs_n);
    #1;
    check_eq("TEST10 CS idle after frame", 1, o_dbg_cs_n);
    check_eq("TEST10 completed SPI frame", 1, miso_byte_ready);

    // --------------------------------------------------------
    // Final Result
    // --------------------------------------------------------

    if (errors == 0) begin

        $display(
            "[%0t] ALL TESTS PASSED (tb_spi_bridge_top)",
            $time
        );

    end
    else begin

        $display(
            "[%0t] TESTS FAILED: %0d error(s) (tb_spi_bridge_top)",
            $time, errors
        );

    end

    $finish;

end

// ============================================================
// Simulation Timeout
// ============================================================

initial begin

    #2000000;

    $display(
        "[%0t] FAIL: TIMEOUT -- RX checked %0d/%0d, TX Burst %0d/3",
        $time,
        rx_frames_checked ,
        N_RX_FRAMES       ,
        burst_idx
    );

    $finish;

end

endmodule

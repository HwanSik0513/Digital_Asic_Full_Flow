`timescale 1ns / 1ps

// ============================================================================
// tb_mcu_core  (simulation only) -- MCU system test with the echo program
//
// DUT  : mcu_core (mips_cpu + inst_rom from FW/echo.s + data_ram + GPIO +
//        spi_slave_bridge)
// Host : spi_master (external SPI host model, unchanged). It sends
//        0x00, 0x01, 0x02 ... on MOSI, one byte per frame, and captures MISO.
//
// The echo program reads 8 bytes from RX_DATA, returns byte+1 through
// TX_DATA, then writes GPIO_OUT = 0xA5 (PASS) or 0xEE (overflow seen).
//
// Checks
//   1. GPIO_OUT becomes 0xA5 (and never 0xEE)
//   2. the non-zero bytes the host received on MISO are exactly
//      0x01, 0x02, ... 0x08 in order (0x00 = TX underflow filler, skipped;
//      an echo value can never be 0x00 here)
//   3. every RX byte the CPU popped was the host's byte, in order
//      (observed on the RX_DATA read strobe)
//
// Clocks: ACLK 10 ns, SCLK 41 ns (independent, sliding phase)
// ============================================================================
module tb_mcu_core;

localparam real    ACLK_HALF = 5.0  ;
localparam real    SCLK_HALF = 20.5 ;
localparam integer ECHO_N    = 8    ;
localparam [7:0]   GPIO_PASS = 8'hA5 ,
                   GPIO_FAIL = 8'hEE ;

reg  ACLK       ;
reg  SCLK       ;
reg  ARESETn    ;
reg  host_rst_n ;

wire       cs_n ;
wire       mosi ;
wire       miso ;
wire [7:0] gpio ;

wire [7:0] host_rx_byte  ;
wire       host_rx_valid ;

integer err_cnt ;

// ---------------------------------------------------------------------
// Clocks (independent)
// ---------------------------------------------------------------------
initial ACLK = 1'b0 ;
always #(ACLK_HALF) ACLK = ~ACLK ;

initial begin
    SCLK = 1'b0 ;
    #3.0 ;
    forever #(SCLK_HALF) SCLK = ~SCLK ;
end

// ---------------------------------------------------------------------
// DUT
// ---------------------------------------------------------------------
mcu_core dut (
    .ACLK    (ACLK)    ,
    .ARESETn (ARESETn) ,
    .SCLK    (SCLK)    ,
    .i_cs_n  (cs_n)    ,
    .i_mosi  (mosi)    ,
    .o_miso  (miso)    ,
    .o_gpio  (gpio)
);

// ---------------------------------------------------------------------
// External SPI host
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

`ifndef NO_SHM
initial begin
    $shm_open("waves.shm") ;
    $shm_probe(tb_mcu_core, "AS") ;
end
`endif

// ---------------------------------------------------------------------
// Monitors
// ---------------------------------------------------------------------
// (a) bytes the host received on MISO
reg [7:0] miso_log [0:4095] ;
integer   miso_cnt ;
initial   miso_cnt = 0 ;

always @(posedge SCLK) begin
    if (host_rx_valid) begin
        if (miso_cnt < 4096)
            miso_log[miso_cnt] = host_rx_byte ;
        miso_cnt = miso_cnt + 1 ;
    end
end

// (b) every RX_DATA pop by the CPU (lw from 0x8000_0000), sampled at the
//     ACLK edge that performs the pop
reg [7:0] pop_log [0:255] ;
integer   pop_cnt ;
initial   pop_cnt = 0 ;

always @(posedge ACLK) begin
    if (dut.u_spi.i_bus_rd_en && (dut.u_spi.i_bus_addr == 8'h00) && dut.u_spi.o_rx_valid) begin
        if (pop_cnt < 256)
            pop_log[pop_cnt] = dut.u_spi.o_bus_rdata ;
        pop_cnt = pop_cnt + 1 ;
    end
end

// (c) GPIO changes
always @(gpio) begin
    $display("[%0t] GPIO_OUT = 0x%02h", $time, gpio) ;
end

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
integer i       ;
integer n       ;
integer nz_cnt  ;
reg     ok      ;
reg [7:0] exp_b ;

initial begin
    err_cnt    = 0    ;
    ARESETn    = 1'b0 ;
    host_rst_n = 1'b0 ;

    #(200) ;
    @(negedge ACLK) ARESETn = 1'b1 ;
    #(300) ;                              // reset synchronizers settle
    @(negedge SCLK) host_rst_n = 1'b1 ;   // host starts sending 0x00, 0x01, ...
    $display("[%0t] INFO: reset released, SPI host started", $time) ;

    // -----------------------------------------------------------------
    // 1. wait for the program's verdict on GPIO_OUT
    // -----------------------------------------------------------------
    n = 0 ;
    while ((gpio !== GPIO_PASS) && (gpio !== GPIO_FAIL) && (n < 200000)) begin
        @(posedge ACLK) ;
        n = n + 1 ;
    end
    check(gpio === GPIO_PASS, "GPIO_OUT = 0xA5 (echo program reports PASS, no RX overflow)") ;

    // let the last echo byte leave on MISO (a few frames)
    repeat (5) @(posedge host_rx_valid) ;

    // -----------------------------------------------------------------
    // 2. RX side: CPU popped the host's bytes in order
    // -----------------------------------------------------------------
    ok = (pop_cnt == ECHO_N) ;
    for (i = 0; i < pop_cnt && i < 256; i = i + 1) begin
        $display("[%0t]   RX pop %0d : 0x%02h", $time, i, pop_log[i]) ;
        if (pop_log[i] !== i[7:0]) ok = 1'b0 ;
    end
    check(ok, "CPU popped exactly 8 RX bytes: 0x00..0x07 in order") ;

    // -----------------------------------------------------------------
    // 3. TX side: host received byte+1 for each, in order
    // -----------------------------------------------------------------
    nz_cnt = 0 ;
    ok     = 1'b1 ;
    for (i = 0; i < miso_cnt && i < 4096; i = i + 1) begin
        if (miso_log[i] !== 8'h00) begin
            exp_b = nz_cnt + 1 ;
            $display("[%0t]   MISO echo %0d : 0x%02h (expected 0x%02h)", $time, nz_cnt, miso_log[i], exp_b) ;
            if (miso_log[i] !== exp_b) ok = 1'b0 ;
            nz_cnt = nz_cnt + 1 ;
        end
    end
    check(ok && (nz_cnt == ECHO_N), "host received echoes 0x01..0x08 in order on MISO") ;

    // -----------------------------------------------------------------
    // 4. CPU parked in the halt loop
    // -----------------------------------------------------------------
    check(dut.w_pc === 32'h0000_005C, "CPU in halt loop (pc = 0x5C, 'done: j done')") ;

    #(1000) ;
    if (err_cnt == 0)
        $display("[%0t] ALL TESTS PASSED (tb_mcu_core)", $time) ;
    else
        $display("[%0t] TESTS FAILED (tb_mcu_core) : %0d error(s)", $time, err_cnt) ;
    $finish ;
end

// global watchdog
initial begin
    #(5_000_000) ;
    $display("[%0t] FATAL: watchdog timeout (GPIO_OUT = 0x%02h, pc = 0x%08h)", $time, gpio, dut.w_pc) ;
    $display("[%0t] TESTS FAILED (tb_mcu_core)", $time) ;
    $finish ;
end

endmodule

`timescale 1ns / 1ps

// ============================================================================
// tb_chip_top  (simulation only) -- chip-level echo test, through the IO pads
//
// Same stimulus and checks as tb_mcu_core, but the DUT is chip_top:
// every signal enters / leaves through the giolib045 PADDI / PADDO models.
// This verifies the pad instantiation and pin connectivity of chip_top
// before synthesis. Hierarchical probes point into dut.u_core.
//
// Pad behavioral models come from the PDK (giolib045_v3.5/vlog), added by
// SIM/CHIP/run_sim.sh.
// ============================================================================
module tb_chip_top;

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
wire       host_cs_n ;    // host model outputs, before the board delay
wire       host_mosi ;
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
chip_top dut (
    .ACLK    (ACLK)    ,
    .ARESETn (ARESETn) ,
    .SCLK    (SCLK)    ,
    .i_cs_n  (cs_n)    ,
    .i_mosi  (mosi)    ,
    .o_miso  (miso)    ,
    .o_gpio  (gpio)
);

// ---------------------------------------------------------------------
// Board delay host -> chip pins, inside the SDC input-delay window
//   chip_top.sdc : set_input_delay -clock SCLK -min 0.5 / -max 2.0 on i_cs_n,
//                  (i_mosi the same, referenced to the SCLK falling edge)
//   The host model updates CS_n / MOSI with zero delay at the SCLK edge.
//   In GLS that is a hold violation at the first SCLK flop (data moves
//   ~0.03 ns after the clock reaches CK through the pad + clock tree),
//   i.e. the stimulus breaks the 0.5 ns minimum that STA assumed.
//   1.0 ns keeps the stimulus inside the constrained window.
// ---------------------------------------------------------------------
localparam real HOST_IO_DLY = 1.0 ;
assign #(HOST_IO_DLY) cs_n = host_cs_n ;
assign #(HOST_IO_DLY) mosi = host_mosi ;

// ---------------------------------------------------------------------
// External SPI host
// ---------------------------------------------------------------------
spi_master u_host (
    .SCLK                (SCLK)          ,
    .rst_n               (host_rst_n)    ,
    .o_cs_n              (host_cs_n)     ,
    .o_mosi              (host_mosi)     ,
    .i_miso              (miso)          ,
    .o_rx_captured       (host_rx_byte)  ,
    .o_rx_captured_valid (host_rx_valid) ,
    .o_busy              ()
);

// ---------------------------------------------------------------------
// Post-layout GLS: back-annotate the Tempus signoff SDF
//   +define+GLS+SDF_MAX : chip_top_post_wst.sdf (FUNC_SS_WORST)
//   +define+GLS+SDF_MIN : chip_top_post_bst.sdf (FUNC_FF_BEST)
// The SDF is copied into the run directory by SIM/POST/{max,min}/run_post_*.sh
// ---------------------------------------------------------------------
`ifdef GLS
initial begin
`ifdef SDF_MAX
    $sdf_annotate("chip_top_post_wst.sdf", dut, , "sdf_max.log", "MAXIMUM") ;
`endif
`ifdef SDF_MIN
    $sdf_annotate("chip_top_post_bst.sdf", dut, , "sdf_min.log", "MINIMUM") ;
`endif
end
`endif

`ifndef NO_SHM
initial begin
    $shm_open("waves.shm") ;
    $shm_probe(tb_chip_top, "AS") ;
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
//     RTL only: in GLS the internal nets are renamed / optimized away, so
//     the gate-level run checks the chip pins only (GPIO + MISO).
reg [7:0] pop_log [0:255] ;
integer   pop_cnt ;
initial   pop_cnt = 0 ;

`ifndef GLS
always @(posedge ACLK) begin
    if (dut.u_core.u_spi.i_bus_rd_en && (dut.u_core.u_spi.i_bus_addr == 8'h00) && dut.u_core.u_spi.o_rx_valid) begin
        if (pop_cnt < 256)
            pop_log[pop_cnt] = dut.u_core.u_spi.o_bus_rdata ;
        pop_cnt = pop_cnt + 1 ;
    end
end
`endif

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
`ifndef GLS
    ok = (pop_cnt == ECHO_N) ;
    for (i = 0; i < pop_cnt && i < 256; i = i + 1) begin
        $display("[%0t]   RX pop %0d : 0x%02h", $time, i, pop_log[i]) ;
        if (pop_log[i] !== i[7:0]) ok = 1'b0 ;
    end
    check(ok, "CPU popped exactly 8 RX bytes: 0x00..0x07 in order") ;
`else
    $display("[%0t] INFO: GLS - internal RX pop check skipped (covered by the MISO echo check)", $time) ;
`endif

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
`ifndef GLS
    check(dut.u_core.w_pc === 32'h0000_005C, "CPU in halt loop (pc = 0x5C, 'done: j done')") ;
`else
    $display("[%0t] INFO: GLS - internal PC check skipped", $time) ;
`endif

    #(1000) ;
    if (err_cnt == 0)
        $display("[%0t] ALL TESTS PASSED (tb_chip_top)", $time) ;
    else
        $display("[%0t] TESTS FAILED (tb_chip_top) : %0d error(s)", $time, err_cnt) ;
    $finish ;
end

// global watchdog
initial begin
    #(5_000_000) ;
`ifndef GLS
    $display("[%0t] FATAL: watchdog timeout (GPIO_OUT = 0x%02h, pc = 0x%08h)", $time, gpio, dut.u_core.w_pc) ;
`else
    $display("[%0t] FATAL: watchdog timeout (GPIO_OUT = 0x%02h)", $time, gpio) ;
`endif
    $display("[%0t] TESTS FAILED (tb_chip_top)", $time) ;
    $finish ;
end

endmodule

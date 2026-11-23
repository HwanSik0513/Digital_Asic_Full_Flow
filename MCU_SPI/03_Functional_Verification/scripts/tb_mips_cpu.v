`timescale 1ns / 1ps

// ============================================================================
// tb_mips_cpu  (simulation only)
//
// CPU-only test: mips_cpu + inst_rom (generated from FW/booktest.s) +
// data_ram, wired like the book's sccomp (Figure 5.20).
//
// Checks against the reference model (FW/mips_iss.py):
//   1. PC at EVERY clock cycle == exp_pc.hex  (catches any wrong branch,
//      jump, jal/jr or control decode the first cycle it happens)
//   2. final $1..$31 == exp_regs.hex
//   3. final data RAM == exp_ram.hex (words marked xxxxxxxx are skipped)
//   4. the book's result: RAM byte 0x60 == 0x00000258, $2 == 0x00000258
//
// Expected files (paths relative to TOP/SIM/CPU; override with
// +define+EXP_PC_FILE=... etc.):
//   ../../FW/build/booktest_exp_pc.hex, _regs.hex, _ram.hex
// ============================================================================
`ifndef EXP_PC_FILE
  `define EXP_PC_FILE   "../../FW/build/booktest_exp_pc.hex"
`endif
`ifndef EXP_REGS_FILE
  `define EXP_REGS_FILE "../../FW/build/booktest_exp_regs.hex"
`endif
`ifndef EXP_RAM_FILE
  `define EXP_RAM_FILE  "../../FW/build/booktest_exp_ram.hex"
`endif

module tb_mips_cpu;

localparam real CLK_HALF  = 5.0 ;   // 100 MHz
localparam integer MAX_TRACE = 4096 ;

reg clk   ;
reg rst_n ;

wire [31:0] pc        ;
wire [31:0] inst      ;
wire [31:0] mem_addr  ;
wire [31:0] mem_wdata ;
wire        mem_we    ;
wire        mem_re    ;
wire [31:0] mem_rdata ;

integer err_cnt ;

// ---------------------------------------------------------------------
// Clock
// ---------------------------------------------------------------------
initial clk = 1'b0 ;
always #(CLK_HALF) clk = ~clk ;

// ---------------------------------------------------------------------
// DUT: CPU + ROM + RAM (book Figure 5.20)
// ---------------------------------------------------------------------
mips_cpu u_cpu (
    .clk         (clk)       ,
    .rst_n       (rst_n)     ,
    .o_pc        (pc)        ,
    .i_inst      (inst)      ,
    .o_mem_addr  (mem_addr)  ,
    .o_mem_wdata (mem_wdata) ,
    .o_mem_we    (mem_we)    ,
    .o_mem_re    (mem_re)    ,
    .i_mem_rdata (mem_rdata)
);

inst_rom u_rom (
    .i_addr (pc[7:2]) ,   // 64 words
    .o_inst (inst)
);

data_ram #(
    .ADDR_WIDTH (5)
) u_ram (
    .clk     (clk)            ,
    .i_we    (mem_we)         ,
    .i_addr  (mem_addr[6:2])  ,
    .i_wdata (mem_wdata)      ,
    .o_rdata (mem_rdata)
);

// ---------------------------------------------------------------------
// Waveform dump (Xcelium / SimVision). Define NO_SHM to disable.
// ---------------------------------------------------------------------
`ifndef NO_SHM
initial begin
    $shm_open("waves.shm") ;
    $shm_probe(tb_mips_cpu, "AS") ;
end
`endif

// ---------------------------------------------------------------------
// Expected values
// ---------------------------------------------------------------------
reg [31:0] exp_pc   [0:MAX_TRACE-1] ;
reg [31:0] exp_regs [0:31] ;
reg [31:0] exp_ram  [0:31] ;
integer    n_cycles ;

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
integer    k        ;
integer    i        ;
integer    pc_err   ;
integer    reg_err  ;
integer    ram_err  ;
integer    ram_chk  ;
reg [31:0] act      ;

initial begin
    err_cnt = 0 ;
    rst_n   = 1'b0 ;

    $readmemh(`EXP_PC_FILE  , exp_pc)   ;
    $readmemh(`EXP_REGS_FILE, exp_regs) ;
    $readmemh(`EXP_RAM_FILE , exp_ram)  ;

    // trace length = number of valid entries in exp_pc
    n_cycles = 0 ;
    while ((n_cycles < MAX_TRACE) && (^exp_pc[n_cycles] !== 1'bx))
        n_cycles = n_cycles + 1 ;
    $display("[%0t] INFO: %0d-cycle expected PC trace loaded", $time, n_cycles) ;
    check(n_cycles > 0, "expected files found and loaded") ;

    // reset, released on a falling edge
    repeat (3) @(posedge clk) ;
    @(negedge clk) rst_n = 1'b1 ;

    // -----------------------------------------------------------------
    // 1. cycle-by-cycle PC check (sampled mid-cycle on the falling edge)
    // -----------------------------------------------------------------
    $display("  cycle  pc        inst      alu/addr  we re") ;
    pc_err = 0 ;
    for (k = 0; k < n_cycles; k = k + 1) begin
        $display("  %5d  %08h  %08h  %08h  %b  %b", k, pc, inst, mem_addr, mem_we, mem_re) ;
        if (pc !== exp_pc[k]) begin
            if (pc_err < 10)
                $display("[%0t]   PC mismatch at cycle %0d: got %08h, expected %08h",
                         $time, k, pc, exp_pc[k]) ;
            pc_err = pc_err + 1 ;
        end
        @(negedge clk) ;
    end
    check(pc_err == 0, "PC matches the reference model on every cycle") ;

    // -----------------------------------------------------------------
    // 2. final register file ($0 is not stored, always reads 0)
    // -----------------------------------------------------------------
    reg_err = 0 ;
    for (i = 1; i < 32; i = i + 1) begin
        act = u_cpu.u_rf.r_reg[i] ;
        if (act !== exp_regs[i]) begin
            $display("[%0t]   $%0d = %08h, expected %08h", $time, i, act, exp_regs[i]) ;
            reg_err = reg_err + 1 ;
        end
    end
    check(reg_err == 0, "final register file $1..$31 matches the reference model") ;

    // -----------------------------------------------------------------
    // 3. final data RAM (only words the program wrote)
    // -----------------------------------------------------------------
    ram_err = 0 ;
    ram_chk = 0 ;
    for (i = 0; i < 32; i = i + 1) begin
        if (^exp_ram[i] !== 1'bx) begin
            ram_chk = ram_chk + 1 ;
            act = u_ram.r_mem[i] ;
            if (act !== exp_ram[i]) begin
                $display("[%0t]   RAM[%0d] (byte 0x%02h) = %08h, expected %08h",
                         $time, i, i*4, act, exp_ram[i]) ;
                ram_err = ram_err + 1 ;
            end
        end
    end
    $display("[%0t] INFO: %0d RAM words checked", $time, ram_chk) ;
    check(ram_err == 0, "final data RAM matches the reference model") ;

    // -----------------------------------------------------------------
    // 4. the book's documented result
    // -----------------------------------------------------------------
    check(u_ram.r_mem[24] === 32'h0000_0258, "book result: RAM[0x60] = 0x258 (A3+27+79+115)") ;
    check(u_cpu.u_rf.r_reg[2] === 32'h0000_0258, "book result: $2 (sum) = 0x258") ;

    if (err_cnt == 0)
        $display("[%0t] ALL TESTS PASSED (tb_mips_cpu)", $time) ;
    else
        $display("[%0t] TESTS FAILED (tb_mips_cpu) : %0d error(s)", $time, err_cnt) ;
    $finish ;
end

// global watchdog
initial begin
    #(1_000_000) ;
    $display("[%0t] FATAL: watchdog timeout", $time) ;
    $display("[%0t] TESTS FAILED (tb_mips_cpu)", $time) ;
    $finish ;
end

endmodule

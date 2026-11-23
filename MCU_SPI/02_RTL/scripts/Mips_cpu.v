`timescale 1ns / 1ps

// ============================================================================
// mips_cpu : single-cycle MIPS CPU (20 integer instructions, Table 4.4)
//
// Ported from Yamin Li, "Computer Principles and Design in Verilog HDL",
// Section 5.3.3 (sccpu) -- same datapath as Figure 5.19:
//
//   PC --> inst ROM --> decode (sc_cu) --> regfile read --> ALU --+--> RAM
//    ^                                                            |
//    +---- next PC (PC+4 / branch / jr / jump) <------------------+
//
// One instruction completes per clock. No branch delay slot.
//
// Changes from the book (ASIC port):
//   - Instruction ROM and data RAM are outside this module (ports below),
//     so the ROM can stay a separate hierarchy in synthesis.
//   - The book's cla32 adders / mux modules are written as behavioral
//     expressions; mux2x5/mux2x32/mux4x32/dff32 are inlined.
//   - o_mem_re (= instruction is lw) added: the MCU address decoder needs a
//     read strobe for read-sensitive I/O registers (RX_DATA pop).
//
// Memory interface timing (single cycle):
//   o_mem_addr / o_mem_wdata / o_mem_we / o_mem_re are combinational from
//   the current instruction; i_mem_rdata must return combinationally in the
//   same cycle; the write and the register write-back happen on the next
//   rising clock edge.
// ============================================================================
module mips_cpu (
    // port list
    clk         ,
    rst_n       ,
    o_pc        ,
    i_inst      ,
    o_mem_addr  ,
    o_mem_wdata ,
    o_mem_we    ,
    o_mem_re    ,
    i_mem_rdata
);

// port declaration
input         clk         ;
input         rst_n       ; // async assert / sync deassert (synchronized outside)

output [31:0] o_pc        ; // instruction address (byte address)
input  [31:0] i_inst      ; // instruction at o_pc

output [31:0] o_mem_addr  ; // data address (= ALU result)
output [31:0] o_mem_wdata ; // store data (= rt)
output        o_mem_we    ; // sw
output        o_mem_re    ; // lw
input  [31:0] i_mem_rdata ; // load data

// ---------------------------------------------------------------------
// Instruction fields
// ---------------------------------------------------------------------
wire [5:0]  w_op   = i_inst[31:26] ;
wire [4:0]  w_rs   = i_inst[25:21] ;
wire [4:0]  w_rt   = i_inst[20:16] ;
wire [4:0]  w_rd   = i_inst[15:11] ;
wire [4:0]  w_sa5  = i_inst[10:6]  ;
wire [5:0]  w_func = i_inst[5:0]   ;
wire [15:0] w_imm  = i_inst[15:0]  ;
wire [25:0] w_jidx = i_inst[25:0]  ;

// ---------------------------------------------------------------------
// Control unit
// ---------------------------------------------------------------------
wire [3:0] w_aluc   ;
wire [1:0] w_pcsrc  ;
wire       w_wreg   ;
wire       w_regrt  ;
wire       w_m2reg  ;
wire       w_shift  ;
wire       w_aluimm ;
wire       w_jal    ;
wire       w_sext   ;
wire       w_wmem   ;
wire       w_z      ;

sc_cu u_cu (
    .i_op     (w_op)     ,
    .i_func   (w_func)   ,
    .i_z      (w_z)      ,
    .o_wmem   (w_wmem)   ,
    .o_wreg   (w_wreg)   ,
    .o_regrt  (w_regrt)  ,
    .o_m2reg  (w_m2reg)  ,
    .o_aluc   (w_aluc)   ,
    .o_shift  (w_shift)  ,
    .o_aluimm (w_aluimm) ,
    .o_pcsrc  (w_pcsrc)  ,
    .o_jal    (w_jal)    ,
    .o_sext   (w_sext)
);

// ---------------------------------------------------------------------
// PC register (book: dff32 with async clear)
// ---------------------------------------------------------------------
reg  [31:0] r_pc  ;
reg  [31:0] w_npc ;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        r_pc <= 32'h0000_0000 ;
    else
        r_pc <= w_npc ;
end

// ---------------------------------------------------------------------
// Immediate / address generation
// ---------------------------------------------------------------------
wire [31:0] w_p4  = r_pc + 32'd4 ;                       // PC + 4
wire [15:0] w_s16 = {16{w_sext & w_imm[15]}} ;           // sign bits (0 if zext)
wire [31:0] w_i32 = {w_s16, w_imm} ;                     // 32-bit immediate
wire [31:0] w_dis = {w_s16[13:0], w_imm, 2'b00} ;        // branch distance (bytes)
wire [31:0] w_bpc = w_p4 + w_dis ;                       // branch target
wire [31:0] w_jpc = {w_p4[31:28], w_jidx, 2'b00} ;       // jump target
wire [31:0] w_sa  = {27'b0, w_sa5} ;                     // shift amount

// ---------------------------------------------------------------------
// Register file
// ---------------------------------------------------------------------
wire [31:0] w_qa ;
wire [31:0] w_qb ;
wire [31:0] w_wd ;
wire [4:0]  w_wn = (w_regrt ? w_rt : w_rd) | {5{w_jal}} ; // jal -> $31

regfile u_rf (
    .clk   (clk)    ,
    .rst_n (rst_n)  ,
    .i_rna (w_rs)   ,
    .i_rnb (w_rt)   ,
    .i_wn  (w_wn)   ,
    .i_we  (w_wreg) ,
    .i_d   (w_wd)   ,
    .o_qa  (w_qa)   ,
    .o_qb  (w_qb)
);

// ---------------------------------------------------------------------
// ALU
// ---------------------------------------------------------------------
wire [31:0] w_alua = w_shift  ? w_sa  : w_qa ;
wire [31:0] w_alub = w_aluimm ? w_i32 : w_qb ;
wire [31:0] w_alu_r ;

alu u_alu (
    .i_a    (w_alua)  ,
    .i_b    (w_alub)  ,
    .i_aluc (w_aluc)  ,
    .o_r    (w_alu_r) ,
    .o_z    (w_z)
);

// ---------------------------------------------------------------------
// Write-back and next PC
// ---------------------------------------------------------------------
wire [31:0] w_r = w_m2reg ? i_mem_rdata : w_alu_r ;    // ALU result or load data
assign      w_wd = w_jal ? w_p4 : w_r ;                // jal links PC+4

always @(*) begin
    case (w_pcsrc)
        2'b00   : w_npc = w_p4  ;   // sequential
        2'b01   : w_npc = w_bpc ;   // taken beq/bne
        2'b10   : w_npc = w_qa  ;   // jr
        2'b11   : w_npc = w_jpc ;   // j / jal
        default : w_npc = w_p4  ;
    endcase
end

// ---------------------------------------------------------------------
// Outputs
// ---------------------------------------------------------------------
assign o_pc        = r_pc    ;
assign o_mem_addr  = w_alu_r ;
assign o_mem_wdata = w_qb    ;
assign o_mem_we    = w_wmem  ;
assign o_mem_re    = w_m2reg ;

endmodule

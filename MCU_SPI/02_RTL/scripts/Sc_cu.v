`timescale 1ns / 1ps

// ============================================================================
// sc_cu : single-cycle CPU control unit (combinational)
//
// Ported from Yamin Li, "Computer Principles and Design in Verilog HDL",
// Section 5.4.2 (sccu_dataflow). Same decode equations and control truth
// table (Table 5.3); only the port names follow the project convention.
//
// aluc[3:0]  x000 ADD   x100 SUB   x001 AND   x101 OR
//            x010 XOR   x110 LUI   0011 SLL   0111 SRL   1111 SRA
// pcsrc[1:0] 00 PC+4    01 branch target    10 rs (jr)    11 jump target
// ============================================================================
module sc_cu (
    // port list
    i_op     ,
    i_func   ,
    i_z      ,
    o_wmem   ,
    o_wreg   ,
    o_regrt  ,
    o_m2reg  ,
    o_aluc   ,
    o_shift  ,
    o_aluimm ,
    o_pcsrc  ,
    o_jal    ,
    o_sext
);

// port declaration
input  [5:0] i_op     ; // inst[31:26]
input  [5:0] i_func   ; // inst[5:0]
input        i_z      ; // ALU zero flag (beq/bne)

output       o_wmem   ; // write data memory (sw)
output       o_wreg   ; // write register file
output       o_regrt  ; // destination register is rt (else rd)
output       o_m2reg  ; // write-back data from memory (lw)
output [3:0] o_aluc   ; // ALU operation
output       o_shift  ; // ALU input A = shift amount (sll/srl/sra)
output       o_aluimm ; // ALU input B = immediate
output [1:0] o_pcsrc  ; // next-PC select
output       o_jal    ; // jal: write $31 with PC+4
output       o_sext   ; // sign-extend the 16-bit immediate

// ---------------------------------------------------------------------
// Instruction decode (Table 5.1)
// ---------------------------------------------------------------------
wire w_rtype = ~|i_op ;

wire w_i_add  = w_rtype &  i_func[5] & ~i_func[4] & ~i_func[3] & ~i_func[2] & ~i_func[1] & ~i_func[0] ;
wire w_i_sub  = w_rtype &  i_func[5] & ~i_func[4] & ~i_func[3] & ~i_func[2] &  i_func[1] & ~i_func[0] ;
wire w_i_and  = w_rtype &  i_func[5] & ~i_func[4] & ~i_func[3] &  i_func[2] & ~i_func[1] & ~i_func[0] ;
wire w_i_or   = w_rtype &  i_func[5] & ~i_func[4] & ~i_func[3] &  i_func[2] & ~i_func[1] &  i_func[0] ;
wire w_i_xor  = w_rtype &  i_func[5] & ~i_func[4] & ~i_func[3] &  i_func[2] &  i_func[1] & ~i_func[0] ;
wire w_i_sll  = w_rtype & ~i_func[5] & ~i_func[4] & ~i_func[3] & ~i_func[2] & ~i_func[1] & ~i_func[0] ;
wire w_i_srl  = w_rtype & ~i_func[5] & ~i_func[4] & ~i_func[3] & ~i_func[2] &  i_func[1] & ~i_func[0] ;
wire w_i_sra  = w_rtype & ~i_func[5] & ~i_func[4] & ~i_func[3] & ~i_func[2] &  i_func[1] &  i_func[0] ;
wire w_i_jr   = w_rtype & ~i_func[5] & ~i_func[4] &  i_func[3] & ~i_func[2] & ~i_func[1] & ~i_func[0] ;

wire w_i_addi = ~i_op[5] & ~i_op[4] &  i_op[3] & ~i_op[2] & ~i_op[1] & ~i_op[0] ;
wire w_i_andi = ~i_op[5] & ~i_op[4] &  i_op[3] &  i_op[2] & ~i_op[1] & ~i_op[0] ;
wire w_i_ori  = ~i_op[5] & ~i_op[4] &  i_op[3] &  i_op[2] & ~i_op[1] &  i_op[0] ;
wire w_i_xori = ~i_op[5] & ~i_op[4] &  i_op[3] &  i_op[2] &  i_op[1] & ~i_op[0] ;
wire w_i_lw   =  i_op[5] & ~i_op[4] & ~i_op[3] & ~i_op[2] &  i_op[1] &  i_op[0] ;
wire w_i_sw   =  i_op[5] & ~i_op[4] &  i_op[3] & ~i_op[2] &  i_op[1] &  i_op[0] ;
wire w_i_beq  = ~i_op[5] & ~i_op[4] & ~i_op[3] &  i_op[2] & ~i_op[1] & ~i_op[0] ;
wire w_i_bne  = ~i_op[5] & ~i_op[4] & ~i_op[3] &  i_op[2] & ~i_op[1] &  i_op[0] ;
wire w_i_lui  = ~i_op[5] & ~i_op[4] &  i_op[3] &  i_op[2] &  i_op[1] &  i_op[0] ;
wire w_i_j    = ~i_op[5] & ~i_op[4] & ~i_op[3] & ~i_op[2] &  i_op[1] & ~i_op[0] ;
wire w_i_jal  = ~i_op[5] & ~i_op[4] & ~i_op[3] & ~i_op[2] &  i_op[1] &  i_op[0] ;

// ---------------------------------------------------------------------
// Control signals (Table 5.3). Any undefined opcode decodes to no write
// and PC+4, i.e. it behaves as a nop.
// ---------------------------------------------------------------------
assign o_wreg   = w_i_add  | w_i_sub  | w_i_and  | w_i_or   | w_i_xor | w_i_sll |
                  w_i_srl  | w_i_sra  | w_i_addi | w_i_andi | w_i_ori | w_i_xori |
                  w_i_lw   | w_i_lui  | w_i_jal  ;
assign o_regrt  = w_i_addi | w_i_andi | w_i_ori  | w_i_xori | w_i_lw  | w_i_lui ;
assign o_jal    = w_i_jal  ;
assign o_m2reg  = w_i_lw   ;
assign o_wmem   = w_i_sw   ;
assign o_shift  = w_i_sll  | w_i_srl  | w_i_sra  ;
assign o_aluimm = w_i_addi | w_i_andi | w_i_ori  | w_i_xori | w_i_lw  | w_i_lui | w_i_sw ;
assign o_sext   = w_i_addi | w_i_lw   | w_i_sw   | w_i_beq  | w_i_bne ;

assign o_aluc[3] = w_i_sra ;
assign o_aluc[2] = w_i_sub | w_i_or  | w_i_srl | w_i_sra  | w_i_ori | w_i_lui ;
assign o_aluc[1] = w_i_xor | w_i_sll | w_i_srl | w_i_sra  | w_i_xori | w_i_beq | w_i_bne | w_i_lui ;
assign o_aluc[0] = w_i_and | w_i_or  | w_i_sll | w_i_srl  | w_i_sra  | w_i_andi | w_i_ori ;

assign o_pcsrc[1] = w_i_jr | w_i_j | w_i_jal ;
assign o_pcsrc[0] = (w_i_beq & i_z) | (w_i_bne & ~i_z) | w_i_j | w_i_jal ;

endmodule

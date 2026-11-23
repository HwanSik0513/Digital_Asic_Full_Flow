`timescale 1ns / 1ps

// ============================================================================
// alu : 32-bit ALU with zero flag (combinational)
//
// Same function and aluc encoding as Yamin Li Section 4.4 (module alu).
// ASIC port: the book builds add/sub from its cla32 carry-lookahead adder
// and the shifter from mux stages; here they are written behaviorally
// ('+', '-', '<<', '>>', '>>>') so that Genus chooses the adder/shifter
// architecture for the timing target.
//
//  aluc[3:0]   operation            result
//  x 0 0 0     ADD                  a + b
//  x 1 0 0     SUB                  a - b
//  x 0 0 1     AND                  a & b
//  x 1 0 1     OR                   a | b
//  x 0 1 0     XOR                  a ^ b        (also beq/bne compare)
//  x 1 1 0     LUI                  {b[15:0], 16'h0}
//  0 0 1 1     SLL                  b << a[4:0]
//  0 1 1 1     SRL                  b >> a[4:0]
//  1 1 1 1     SRA                  b >>> a[4:0] (arithmetic)
// ============================================================================
module alu (
    // port list
    i_a    ,
    i_b    ,
    i_aluc ,
    o_r    ,
    o_z
);

// port declaration
input  [31:0] i_a    ; // rs, or shift amount for shifts
input  [31:0] i_b    ; // rt or immediate
input  [3:0]  i_aluc ;
output [31:0] o_r    ;
output        o_z    ; // 1 when o_r == 0

reg [31:0] o_r ;

wire [31:0] w_add_sub = i_aluc[2] ? (i_a - i_b) : (i_a + i_b) ;
wire [31:0] w_and_or  = i_aluc[2] ? (i_a | i_b) : (i_a & i_b) ;
wire [31:0] w_xor_lui = i_aluc[2] ? {i_b[15:0], 16'h0000} : (i_a ^ i_b) ;

// shifter: right = aluc[2], arithmetic = aluc[3]
reg [31:0] w_shift ;

always @(*) begin
    if (!i_aluc[2])
        w_shift = i_b << i_a[4:0] ;
    else if (i_aluc[3])
        w_shift = $signed(i_b) >>> i_a[4:0] ;
    else
        w_shift = i_b >> i_a[4:0] ;
end

// result select by aluc[1:0]
always @(*) begin
    case (i_aluc[1:0])
        2'b00   : o_r = w_add_sub ;
        2'b01   : o_r = w_and_or  ;
        2'b10   : o_r = w_xor_lui ;
        2'b11   : o_r = w_shift   ;
        default : o_r = 32'h0000_0000 ;
    endcase
end

assign o_z = ~|o_r ;

endmodule

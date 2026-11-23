`timescale 1ns / 1ps

// ============================================================================
// regfile : 32 x 32-bit register file, 2 asynchronous read ports,
//           1 synchronous write port. $0 is hardwired to zero.
//
// Same behavior as Yamin Li Section 5.2.3 (behavioral regfile):
// registers $1..$31 are cleared by the asynchronous active-low reset.
// Write happens on the rising clock edge when i_we = 1 and i_wn != 0.
// Implemented as 31 x 32 = 992 flip-flops.
// ============================================================================
module regfile (
    // port list
    clk   ,
    rst_n ,
    i_rna ,
    i_rnb ,
    i_wn  ,
    i_we  ,
    i_d   ,
    o_qa  ,
    o_qb
);

// port declaration
input         clk   ;
input         rst_n ; // async assert, sync deassert (synchronized outside)
input  [4:0]  i_rna ; // read port A register number (rs)
input  [4:0]  i_rnb ; // read port B register number (rt)
input  [4:0]  i_wn  ; // write register number
input         i_we  ; // write enable
input  [31:0] i_d   ; // write data
output [31:0] o_qa  ;
output [31:0] o_qb  ;

reg [31:0] r_reg [1:31] ;

integer i ;

assign o_qa = (i_rna == 5'd0) ? 32'h0000_0000 : r_reg[i_rna] ;
assign o_qb = (i_rnb == 5'd0) ? 32'h0000_0000 : r_reg[i_rnb] ;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 1; i < 32; i = i + 1)
            r_reg[i] <= 32'h0000_0000 ;
    end else if (i_we && (i_wn != 5'd0)) begin
        r_reg[i_wn] <= i_d ;
    end
end

endmodule

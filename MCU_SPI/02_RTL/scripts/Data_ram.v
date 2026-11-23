`timescale 1ns / 1ps

// ============================================================================
// data_ram : data memory, (2^ADDR_WIDTH) x 32, flip-flop based
//            asynchronous read, synchronous write
//
// ASIC port of Yamin Li Section 5.5 (scdatamem):
//   - no 'initial' block (not synthesizable on ASIC). Software must write
//     a word before reading it; reading a never-written word gives X in
//     simulation.
//   - no reset: keeps the 1,024 storage flops small (no reset pin).
//   - nonblocking write.
// Default 32 words = byte addresses 0x00..0x7C (word address = addr[6:2]).
// ============================================================================
module data_ram #(
    parameter ADDR_WIDTH = 5   // 32 words
) (
    // port list
    clk     ,
    i_we    ,
    i_addr  ,
    i_wdata ,
    o_rdata
);

// port declaration
input                   clk     ;
input                   i_we    ; // write enable (sw to RAM space)
input  [ADDR_WIDTH-1:0] i_addr  ; // word address
input  [31:0]           i_wdata ;
output [31:0]           o_rdata ; // combinational read (single-cycle lw)

localparam DEPTH = (1 << ADDR_WIDTH) ;

reg [31:0] r_mem [0:DEPTH-1] ;

assign o_rdata = r_mem[i_addr] ;

always @(posedge clk) begin
    if (i_we)
        r_mem[i_addr] <= i_wdata ;
end

endmodule

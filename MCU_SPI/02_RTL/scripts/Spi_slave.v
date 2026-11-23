`timescale 1ns / 1ps

module spi_slave (
    // port list
    SCLK                ,
    rst_n               ,
    i_cs_n              ,
    i_mosi              ,
    o_miso              ,
    o_rx_wr_en          ,
    o_rx_wr_data        ,
    i_rx_fifo_full      ,
    o_rx_overflow_pulse ,
    o_tx_fifo_rd_en     ,
    i_tx_fifo_rd_data   ,
    i_tx_fifo_empty     ,
    o_spi_busy
);

// ============================================================
// Port Declaration
// ============================================================

input SCLK  ;
input rst_n ;

input  i_cs_n ;
input  i_mosi ;
output o_miso ;

output       o_rx_wr_en          ;
output [7:0] o_rx_wr_data        ;
input        i_rx_fifo_full      ;
output       o_rx_overflow_pulse ;

output       o_tx_fifo_rd_en   ;
input  [7:0] i_tx_fifo_rd_data ;
input        i_tx_fifo_empty   ;

output o_spi_busy ;

reg o_miso ;

// ============================================================
// FSM State Encoding
// ============================================================

localparam [1:0] S_IDLE      = 2'd0 ,
                 S_LOAD      = 2'd1 ,
                 S_RECEIVE   = 2'd2 ,
                 S_BYTE_DONE = 2'd3 ;

reg [1:0] state, next_state ;

// ============================================================
// Datapath Registers
// ============================================================

reg [2:0] bit_cnt ;

reg [7:0] r_shift_rx ;
reg [7:0] r_shift_tx ;

// ============================================================
// TX Holding Register
// ============================================================

reg [7:0] r_tx_hold       ;
reg       r_tx_hold_valid ;
reg       r_tx_pop_d      ;

// Indicates whether the current TX shift byte
// was loaded from a valid holding register.
reg r_tx_cur_from_hold ;

// ============================================================
// Internal Wires
// ============================================================

wire w_entering_receive ;
wire w_byte_complete    ;

wire w_tx_pop     ;
wire w_tx_consume ;

assign w_entering_receive =
    (next_state == S_RECEIVE) &&
    (state != S_RECEIVE);

assign w_byte_complete =
    (state == S_RECEIVE) &&
    (bit_cnt == 3'd7);

// ============================================================
// Process 1 - FSM State Register
// ============================================================

always @(posedge SCLK or negedge rst_n) begin
    if (!rst_n)
        state <= S_IDLE ;
    else
        state <= next_state ;
end

// ============================================================
// Process 2 - FSM Next State Logic
// ============================================================

always @(*) begin

    next_state = state ;

    case (state)

        S_IDLE : begin
            if (!i_cs_n)
                next_state = S_LOAD ;
        end

        S_LOAD : begin
            next_state = S_RECEIVE ;
        end

        S_RECEIVE : begin
            if (i_cs_n)
                next_state = S_IDLE ;
            else if (w_byte_complete)
                next_state = S_BYTE_DONE ;
            else
                next_state = S_RECEIVE ;
        end

        S_BYTE_DONE : begin
            if (i_cs_n)
                next_state = S_IDLE ;
            else
                next_state = S_RECEIVE ;
        end

        default : begin
            next_state = S_IDLE ;
        end

    endcase
end

// ============================================================
// Process 3 - RX Bit Counter and Shift Register
// ============================================================

always @(posedge SCLK or negedge rst_n) begin

    if (!rst_n) begin
        bit_cnt    <= 3'd0  ;
        r_shift_rx <= 8'h00 ;
    end

    else if (w_entering_receive) begin
        bit_cnt <= 3'd0 ;
    end

    else if (state == S_RECEIVE) begin
        bit_cnt    <= bit_cnt + 3'd1            ;
        r_shift_rx <= {r_shift_rx[6:0], i_mosi} ;
    end

end

// ============================================================
// Process 4 - TX FIFO Read Control
// ============================================================

// Read a new byte only when:
// 1. TX FIFO is not empty
// 2. Holding register is empty
// 3. No previous FIFO read is pending

assign w_tx_pop =
    !i_tx_fifo_empty &&
    !r_tx_hold_valid &&
    !r_tx_pop_d;

assign o_tx_fifo_rd_en = w_tx_pop ;

// ============================================================
// Process 5 - TX Byte Consume Control
// ============================================================

// Consume the holding byte only if:
// 1. SPI is in RECEIVE state
// 2. First bit is being sampled
// 3. CS_N is active
// 4. The current TX byte was loaded from holding register

assign w_tx_consume =
    (state == S_RECEIVE) &&
    (bit_cnt == 3'd0) &&
    !i_cs_n &&
    r_tx_cur_from_hold;

// ============================================================
// Process 6 - TX Holding Register
// ============================================================

always @(posedge SCLK or negedge rst_n) begin

    if (!rst_n) begin
        r_tx_pop_d      <= 1'b0  ;
        r_tx_hold       <= 8'h00 ;
        r_tx_hold_valid <= 1'b0  ;
    end

    else begin

        // Register FIFO read request
        r_tx_pop_d <= w_tx_pop ;

        // Capture data returned by synchronous FIFO
        if (r_tx_pop_d) begin
            r_tx_hold       <= i_tx_fifo_rd_data ;
            r_tx_hold_valid <= 1'b1              ;
        end

        // Release only when the loaded byte
        // actually begins transmission
        if (w_tx_consume) begin
            r_tx_hold_valid <= 1'b0 ;
        end

    end
end

// ============================================================
// Process 7 - TX Shift Register
// ============================================================

always @(posedge SCLK or negedge rst_n) begin

    if (!rst_n) begin
        r_shift_tx         <= 8'h00 ;
        r_tx_cur_from_hold <= 1'b0  ;
    end

    // Load TX data at the beginning of a byte
    else if (w_entering_receive) begin

        if (r_tx_hold_valid) begin
            r_shift_tx         <= r_tx_hold ;
            r_tx_cur_from_hold <= 1'b1      ;
        end

        else begin
            r_shift_tx         <= 8'h00 ;
            r_tx_cur_from_hold <= 1'b0  ;
        end

    end

    // Shift TX data during active transfer
    else if (state == S_RECEIVE) begin
        r_shift_tx <= {r_shift_tx[6:0], 1'b0} ;
    end

end

// ============================================================
// Process 8 - MISO Output (SPI Mode 0)
// ============================================================

// MISO changes on SCLK falling edge.
// Master samples MISO on SCLK rising edge.

always @(negedge SCLK or negedge rst_n) begin

    if (!rst_n)
        o_miso <= 1'b0 ;

    else if (state == S_RECEIVE)
        o_miso <= r_shift_tx[7] ;

end

// ============================================================
// Process 9 - RX FIFO Write Control
// ============================================================

// Write completed RX byte if FIFO has space

assign o_rx_wr_en =
    (state == S_BYTE_DONE) &&
    !i_rx_fifo_full;

assign o_rx_wr_data = r_shift_rx ;

// Overflow pulse when RX FIFO is full

assign o_rx_overflow_pulse =
    (state == S_BYTE_DONE) &&
    i_rx_fifo_full;

// ============================================================
// Process 10 - SPI Busy Status
// ============================================================

assign o_spi_busy = (state != S_IDLE) ;

endmodule

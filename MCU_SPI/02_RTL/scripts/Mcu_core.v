`timescale 1ns / 1ps

// ============================================================================
// mcu_core : MIPS single-cycle MCU core
//
//   mips_cpu  + inst_rom (64 x 32, generated)  + data_ram (32 x 32)
//   + memory-mapped I/O: spi_slave_bridge (SPI slave peripheral), GPIO_OUT
//
// Memory map (byte addresses)
//   0x0000_0000 - 0x0000_007C  data RAM          (addr[31] = 0, word = addr[6:2])
//   0x8000_0000 - 0x8000_001C  SPI bridge regs   (addr[31] = 1, addr[7:5] = 000)
//       +0x00 RX_DATA  +0x04 STATUS  +0x08 CONTROL  +0x0C FIFO_LEVEL  +0x10 TX_DATA
//   0x8000_0020                GPIO_OUT [7:0]    (addr[31] = 1, addr[7:0] = 0x20)
//   other I/O addresses read 0, writes ignored. RAM and I/O are partially
//   decoded (upper address bits other than [31] are ignored -> aliases).
//
// Clocks / reset
//   ACLK    : CPU + bus + register side of the SPI bridge (100 MHz)
//   SCLK    : SPI serial clock from the external host, async to ACLK;
//             used only inside spi_slave_bridge (async FIFOs + syncs)
//   ARESETn : async active-low; each domain has its own reset_sync
//
// Bus timing (single-cycle CPU)
//   A 'lw' to I/O drives i_bus_rd_en for exactly one ACLK cycle, so a
//   RX_DATA read pops exactly one byte. A 'sw' drives i_bus_wr_en for one
//   cycle. o_bus_rdata is combinational -> returned in the same cycle.
// ============================================================================
module mcu_core (
    // port list
    ACLK    ,
    ARESETn ,
    SCLK    ,
    i_cs_n  ,
    i_mosi  ,
    o_miso  ,
    o_gpio
);

// port declaration
input        ACLK    ; // system clock
input        ARESETn ; // global async active-low reset
input        SCLK    ; // SPI clock from external host (continuous, async)

input        i_cs_n  ; // SPI chip select (SCLK domain)
input        i_mosi  ; // SPI host -> MCU
output       o_miso  ; // SPI MCU -> host

output [7:0] o_gpio  ; // GPIO_OUT register

// =====================================================================
// Reset synchronizer for the CPU / bus logic (ACLK domain)
// (spi_slave_bridge synchronizes ARESETn into its own two domains)
// =====================================================================
wire w_rst_n ;

reset_sync u_reset_sync_core (
    .clk        (ACLK)    ,
    .arst_n     (ARESETn) ,
    .rst_n_sync (w_rst_n)
);

// =====================================================================
// CPU
// =====================================================================
wire [31:0] w_pc        ;
wire [31:0] w_inst      ;
wire [31:0] w_mem_addr  ;
wire [31:0] w_mem_wdata ;
wire        w_mem_we    ;
wire        w_mem_re    ;
wire [31:0] w_mem_rdata ;

mips_cpu u_cpu (
    .clk         (ACLK)        ,
    .rst_n       (w_rst_n)     ,
    .o_pc        (w_pc)        ,
    .i_inst      (w_inst)      ,
    .o_mem_addr  (w_mem_addr)  ,
    .o_mem_wdata (w_mem_wdata) ,
    .o_mem_we    (w_mem_we)    ,
    .o_mem_re    (w_mem_re)    ,
    .i_mem_rdata (w_mem_rdata)
);

// =====================================================================
// Instruction ROM (generated from FW/echo.s by mips_asm.py)
// Keep as a separate hierarchy in synthesis (see inst_rom header).
// =====================================================================
inst_rom u_rom (
    .i_addr (w_pc[7:2]) ,  // 64 words
    .o_inst (w_inst)
);

// =====================================================================
// Address decode
// =====================================================================
wire w_io_space = w_mem_addr[31] ;
wire w_ram_sel  = ~w_io_space ;
wire w_spi_sel  =  w_io_space & (w_mem_addr[7:5] == 3'b000) ;  // +0x00..+0x1C
wire w_gpio_sel =  w_io_space & (w_mem_addr[7:0] == 8'h20)  ;  // +0x20

// =====================================================================
// Data RAM (32 words)
// =====================================================================
wire [31:0] w_ram_rdata ;

data_ram #(
    .ADDR_WIDTH (5)
) u_ram (
    .clk     (ACLK)                  ,
    .i_we    (w_mem_we & w_ram_sel)  ,
    .i_addr  (w_mem_addr[6:2])       ,
    .i_wdata (w_mem_wdata)           ,
    .o_rdata (w_ram_rdata)
);

// =====================================================================
// SPI slave bridge (memory-mapped peripheral)
// =====================================================================
wire [7:0] w_spi_rdata ;

spi_slave_bridge u_spi (
    .ACLK        (ACLK)                  ,
    .ARESETn     (ARESETn)               ,
    .SCLK        (SCLK)                  ,
    .i_bus_addr  (w_mem_addr[7:0])       ,
    .i_bus_wr_en (w_mem_we & w_spi_sel)  ,
    .i_bus_wdata (w_mem_wdata[7:0])      ,
    .i_bus_rd_en (w_mem_re & w_spi_sel)  ,
    .o_bus_rdata (w_spi_rdata)           ,
    .i_cs_n      (i_cs_n)                ,
    .i_mosi      (i_mosi)                ,
    .o_miso      (o_miso)                ,
    .o_overflow  ()                      , // available in STATUS[4]
    .o_rx_valid  ()                        // available in STATUS[3]
);

// =====================================================================
// GPIO_OUT register (ACLK domain)
// =====================================================================
reg [7:0] r_gpio ;

always @(posedge ACLK or negedge w_rst_n) begin
    if (!w_rst_n)
        r_gpio <= 8'h00 ;
    else if (w_mem_we && w_gpio_sel)
        r_gpio <= w_mem_wdata[7:0] ;
end

assign o_gpio = r_gpio ;

// =====================================================================
// Read data mux (combinational, same cycle as the lw)
// =====================================================================
reg [31:0] w_rdata_mux ;

always @(*) begin
    if (w_ram_sel)
        w_rdata_mux = w_ram_rdata ;
    else if (w_spi_sel)
        w_rdata_mux = {24'h00_0000, w_spi_rdata} ;
    else if (w_gpio_sel)
        w_rdata_mux = {24'h00_0000, r_gpio} ;
    else
        w_rdata_mux = 32'h0000_0000 ;
end

assign w_mem_rdata = w_rdata_mux ;

endmodule

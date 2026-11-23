`timescale 1ns / 1ps

// ============================================================================
// chip_top : chip-level top of the MIPS MCU (IO pads + mcu_core)
//
// Signal pads (GPDK045 giolib045_v3.5, 60 x 240 um each)
//   PADDI  input  pad : PAD (chip pin) -> Y (core side)
//   PADDO  output pad : A (core side)  -> PAD (chip pin)
//
//   pin       pad cell  instance         core net
//   ACLK      PADDI     u_pad_aclk       w_aclk
//   ARESETn   PADDI     u_pad_aresetn    w_aresetn
//   SCLK      PADDI     u_pad_sclk       w_sclk
//   i_cs_n    PADDI     u_pad_cs_n       w_cs_n
//   i_mosi    PADDI     u_pad_mosi       w_mosi
//   o_miso    PADDO     u_pad_miso       w_miso
//   o_gpio[n] PADDO     u_pad_gpio<n>    w_gpio[n]   (n = 0..7)
//
// Power pads (PADVDD / PADVSS core supply, PADVDDIOR / PADVSSIOR IO ring
// supply) and corner/filler cells have no signal pins. They are NOT part of
// this RTL: as in the previous flow (PNR/add_pad), they are added to the
// netlist and placed by the IO file at the PnR step. Supply pins of all pads
// (VDD, VSS, VDDIOR, VSSIOR) are connected by global net connection in PnR.
//
// Synthesis: pad instances must be dont_touch (see synthesis script).
// ============================================================================
module chip_top (
    // port list
    ACLK    ,
    ARESETn ,
    SCLK    ,
    i_cs_n  ,
    i_mosi  ,
    o_miso  ,
    o_gpio
);

// port declaration (chip pins)
input        ACLK    ; // system clock, 100 MHz
input        ARESETn ; // async active-low reset
input        SCLK    ; // SPI clock from external host (continuous, async)
input        i_cs_n  ; // SPI chip select
input        i_mosi  ; // SPI host -> MCU
output       o_miso  ; // SPI MCU -> host
output [7:0] o_gpio  ; // GPIO_OUT

// core-side nets
wire       w_aclk    ;
wire       w_aresetn ;
wire       w_sclk    ;
wire       w_cs_n    ;
wire       w_mosi    ;
wire       w_miso    ;
wire [7:0] w_gpio    ;

// =====================================================================
// Input pads
// =====================================================================
PADDI u_pad_aclk    ( .PAD (ACLK)    , .Y (w_aclk)    );
PADDI u_pad_aresetn ( .PAD (ARESETn) , .Y (w_aresetn) );
PADDI u_pad_sclk    ( .PAD (SCLK)    , .Y (w_sclk)    );
PADDI u_pad_cs_n    ( .PAD (i_cs_n)  , .Y (w_cs_n)    );
PADDI u_pad_mosi    ( .PAD (i_mosi)  , .Y (w_mosi)    );

// =====================================================================
// Output pads
// =====================================================================
PADDO u_pad_miso    ( .A (w_miso)    , .PAD (o_miso)    );
PADDO u_pad_gpio0   ( .A (w_gpio[0]) , .PAD (o_gpio[0]) );
PADDO u_pad_gpio1   ( .A (w_gpio[1]) , .PAD (o_gpio[1]) );
PADDO u_pad_gpio2   ( .A (w_gpio[2]) , .PAD (o_gpio[2]) );
PADDO u_pad_gpio3   ( .A (w_gpio[3]) , .PAD (o_gpio[3]) );
PADDO u_pad_gpio4   ( .A (w_gpio[4]) , .PAD (o_gpio[4]) );
PADDO u_pad_gpio5   ( .A (w_gpio[5]) , .PAD (o_gpio[5]) );
PADDO u_pad_gpio6   ( .A (w_gpio[6]) , .PAD (o_gpio[6]) );
PADDO u_pad_gpio7   ( .A (w_gpio[7]) , .PAD (o_gpio[7]) );

// =====================================================================
// MCU core
// =====================================================================
mcu_core u_core (
    .ACLK    (w_aclk)    ,
    .ARESETn (w_aresetn) ,
    .SCLK    (w_sclk)    ,
    .i_cs_n  (w_cs_n)    ,
    .i_mosi  (w_mosi)    ,
    .o_miso  (w_miso)    ,
    .o_gpio  (w_gpio)
);

endmodule

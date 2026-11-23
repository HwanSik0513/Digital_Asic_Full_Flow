######################################################################
# chip_top.sdc
#
# Design : MIPS single-cycle MCU + SPI slave bridge, with IO pads
# Top    : chip_top  (PADDI / PADDO pads -> mcu_core)
# Tool   : Cadence Genus 22.17 (also read by Tempus / Innovus)
# PDK    : GPDK045 (gsclib045 + giolib045)
# Units  : ns, pF
#
# Differences from spi_bridge_top.sdc (previous project)
#   - SCLK is a PRIMARY clock on the SCLK pin (external SPI host), not a
#     generated clock: ACLK and SCLK are asynchronous.
#   - All IO constraints are on CHIP PINS (pad PAD side). Pad delays are
#     therefore inside every IO path.
#   - The 8-bit register bus is internal now (CPU <-> bridge): no bus IO.
#
# Items marked [ASSUMPTION] are budget values chosen for this project,
# not taken from a datasheet; change them in one place below.
######################################################################

set_units -capacitance 1000.0fF
set_units -time 1000.0ps

#----------------------------------------------------------------
# 0. Parameters
#----------------------------------------------------------------
if {![info exists CLK_PERIOD]}  { set CLK_PERIOD  10.0 }   ;# ACLK, 100 MHz
if {![info exists SCLK_PERIOD]} { set SCLK_PERIOD 40.0 }   ;# SPI 25 MHz max (spec)

# External SPI host / board budget [ASSUMPTION]
set SPI_IN_MAX   2.0    ;# host clk-to-out + board, max
set SPI_IN_MIN   0.5    ;# host clk-to-out + board, min
set SPI_OUT_MAX  2.0    ;# host setup + board
set SPI_OUT_MIN -0.5    ;# host hold (negative = hold requirement)

# GPIO receiver budget, ACLK-relative [ASSUMPTION]
set GPIO_OUT_MAX  2.0
set GPIO_OUT_MIN -0.5

# Pin electrical environment [ASSUMPTION]
set IN_TRAN   0.5       ;# input transition at the chip pins (ns)
set OUT_LOAD  2.0       ;# board load on every output pin (pF)

#----------------------------------------------------------------
# 1. Clocks (both enter through PADDI pads)
#----------------------------------------------------------------
create_clock -name ACLK -period $CLK_PERIOD  [get_ports ACLK]
create_clock -name SCLK -period $SCLK_PERIOD [get_ports SCLK]

# Same latency / uncertainty convention as the previous project
set_clock_latency -source -max 0.2 [get_clocks {ACLK SCLK}]
set_clock_latency         -max 0.2 [get_clocks {ACLK SCLK}]
set_clock_uncertainty -setup 0.1   [get_clocks {ACLK SCLK}]
set_clock_transition         0.1   [get_clocks {ACLK SCLK}]

# ACLK and SCLK come from independent sources: no timing between them.
# All data crossings are handled by the async FIFOs (Gray pointers + 2-FF),
# pulse_sync and 2-FF level syncs inside spi_slave_bridge.
set_clock_groups -asynchronous -name ASYNC_ACLK_SCLK \
    -group [get_clocks ACLK] -group [get_clocks SCLK]

#----------------------------------------------------------------
# 2. SPI pins (SCLK domain, Mode 0)
#----------------------------------------------------------------
# i_cs_n : host drives it from SCLK RISING edge, slave samples on RISING
#          -> full-cycle path.
set_input_delay  -clock [get_clocks SCLK] -max $SPI_IN_MAX [get_ports i_cs_n]
set_input_delay  -clock [get_clocks SCLK] -min $SPI_IN_MIN [get_ports i_cs_n]

# i_mosi : host drives it from SCLK FALLING edge, slave samples on RISING
#          -> half-cycle path (-clock_fall).
set_input_delay  -clock [get_clocks SCLK] -clock_fall -max $SPI_IN_MAX [get_ports i_mosi]
set_input_delay  -clock [get_clocks SCLK] -clock_fall -min $SPI_IN_MIN [get_ports i_mosi]

# o_miso : slave launches on SCLK FALLING edge (negedge flop), host samples
#          on RISING edge -> half-cycle path; the tool derives it from the
#          launching flop's clock edge.
set_output_delay -clock [get_clocks SCLK] -max $SPI_OUT_MAX [get_ports o_miso]
set_output_delay -clock [get_clocks SCLK] -min $SPI_OUT_MIN [get_ports o_miso]

#----------------------------------------------------------------
# 3. GPIO pins (ACLK domain, registered r_gpio -> PADDO)
#----------------------------------------------------------------
set_output_delay -clock [get_clocks ACLK] -max $GPIO_OUT_MAX [get_ports o_gpio*]
set_output_delay -clock [get_clocks ACLK] -min $GPIO_OUT_MIN [get_ports o_gpio*]

#----------------------------------------------------------------
# 4. Reset
#----------------------------------------------------------------
# ARESETn feeds only the async inputs of the three reset_sync instances
# (one per domain + core); deassertion is synchronized inside.
set_false_path -from [get_ports ARESETn]

#----------------------------------------------------------------
# 5. Pin electrical environment (pads drive / see the board)
#----------------------------------------------------------------
set_input_transition $IN_TRAN [get_ports {ARESETn i_cs_n i_mosi}]
set_load $OUT_LOAD [all_outputs]

#----------------------------------------------------------------
# 6. Ideal networks for synthesis (clock trees and the reset tree are
#    built in PnR)
#----------------------------------------------------------------
set_ideal_network [get_ports {ACLK SCLK ARESETn}]

#----------------------------------------------------------------
# Notes
#----------------------------------------------------------------
# - set_clock_groups removes ACLK<->SCLK paths from timing. The Gray-pointer
#   bus skew (all bits of one pointer must arrive within one destination
#   period) is checked separately at STA (Tempus) on the routed design.
# - SDC does not replace structural CDC verification (no CDC tool here).

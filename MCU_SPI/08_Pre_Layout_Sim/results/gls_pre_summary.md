# Pre-layout GLS summary (chip_top, echo firmware)

Netlist SYN/mapped/chip_top_syn_final.v + Genus SDF chip_top_delays.sdf
(slow_vdd1v0, 0.9 V, 125 C, ideal clocks - no clock tree before CTS)

| Item | Result |
|---|---|
| GPIO_OUT = 0xA5 (firmware verdict) | PASS @ 6,995 ns |
| MISO echoes 0x01..0x08 in order | PASS @ 10,643 ns |
| Final | ALL TESTS PASSED |
| Timing violations | 0 |
| Path delays annotated | 16,827 / 19,443 (86.55 %) |
| $setuphold annotated | 7,058 / 7,059 (99.99 %) |
| $recovery annotated | 1,121 / 1,124 (99.73 %) |
| SDFNET warnings | 1,121 (REMOVAL) |

## Same verdict time at every level
| Level | GPIO = 0xA5 | Echo check |
|---|---|---|
| RTL (03, SIM/MCU and SIM/CHIP) | 6,995 ns | PASS |
| Pre-layout GLS (08, Genus SDF, SS) | 6,995 ns | PASS |
| Post-layout GLS (17, Tempus SDF, SS / FF) | 6,995 ns | PASS |
The firmware runs a fixed number of ACLK cycles, so the verdict time does not move;
only ps-level edge positions change with the annotated delays.

## Warnings
- SDFNET (REMOVAL): Genus writes `-recrem split`, so recovery and removal are separate SDF
  checks. The gsclib045 Verilog models describe the RN release as `$recovery` (annotated
  99.73 %) and have no matching `$removal` arc, so the REMOVAL values cannot be annotated.
  Removal is signed off by Tempus (15_Post_STA 31_removal: 370 / 370 met).
- TFANOTI x4 (first run): the timing file listed bits 3..4 of the TX FIFO pointer
  synchronizers, but the TX FIFO is ADDR_WIDTH 2 (3-bit pointers). Lines removed from
  cdc_tcheck_off.tfile (also in 17_Post_Layout_Sim/scripts); no effect on the result.

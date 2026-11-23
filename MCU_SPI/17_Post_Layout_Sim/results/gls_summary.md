# Post-layout GLS summary (chip_top, echo firmware)

| Item | max (SS, chip_top_post_wst.sdf) | min (FF, chip_top_post_bst.sdf) |
|---|---|---|
| GPIO_OUT = 0xA5 (firmware verdict) | PASS @ 6,995 ns | PASS @ 6,995 ns |
| MISO echoes 0x01..0x08 in order | PASS | PASS |
| Final | ALL TESTS PASSED | ALL TESTS PASSED |
| SDF path delays annotated | 14,035 / 14,035 (100 %) | 100 % |
| $setuphold annotated | 5,523 / 5,523 | same |
| Timing violations | 14 (all u_spi_slave/state_reg_1, hold) | 0 |
| SDFNET warnings | 356 (RECREM) | 359 (RECREM) |

## The 14 hold warnings at max (SS)
- All on `u_core/u_spi/u_spi_slave/state_reg_1`, once per SPI frame (every 779 ns = 19 SCLK periods):
  `$setuphold<hold>( posedge CK : t, negedge D : t + 32 ps, hold 40 ps )`
- Cause: the testbench host (`Spi_master.v`) updates CS_n with zero delay at the SCLK rising edge.
  Inside the chip, CS_n (pad + logic) and SCLK (pad + clock tree) take almost the same time,
  so D moves 32 ps after CK. The SDC promises the opposite: `set_input_delay -min 0.5` on i_cs_n
  (CS_n changes at least 0.5 ns after the edge) and Tempus signed off hold under that assumption.
- Stimulus problem, not a chip problem. Fix in `tb_chip_top.v`: board delay host -> pins
  `HOST_IO_DLY = 1.0 ns` (inside the 0.5 .. 2.0 ns SDC window).
  The 32 ps data-after-clock pattern shows the max run in reports/ still used the zero-delay
  host (with 1.0 ns the data would move about 1 ns after CK); the same run shows the MISO X
  windows in images/17_gls_max_SS_full.png. The function still passed. The FF run reports
  no warning on this flop.

## SDFNET (RECREM) warnings
- The SDF from Tempus writes recovery/removal as one combined `RECREM` check; the gsclib045
  Verilog models describe `$recovery` / `$hold` on RN separately, so xmelab cannot annotate
  them (`$recovery` 0 % annotated). Those checks run with the model default limits.
- Recovery / removal are signed off in Tempus instead: 15_Post_STA reports 30_recovery /
  31_removal, 370 / 370 met, 0 violated (9 untested = reset_sync first stage, async ARESETn).

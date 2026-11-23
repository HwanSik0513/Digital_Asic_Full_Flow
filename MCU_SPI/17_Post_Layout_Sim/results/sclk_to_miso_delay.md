# SCLK falling edge -> MISO pin delay (post-layout, per corner)

Path (same instances in both corners, from Tempus 15_Post_STA/reports/14_setup_io.rpt Path 9):
SCLK pin -> u_pad_sclk (PADDI) -> CTS_ccl_a_buf_00092 (CLKBUFX3) -> CTS_ccl_a_buf_00002 (CLKBUFX4)
-> u_spi_slave/o_miso_reg (DFFNSRX1, CKN v -> Q ^) -> FE_OFC572 (INVX2) -> FE_OFC573 (CLKINVX4)
-> u_pad_miso (PADDO, 2 pF load) -> MISO pin

Cell delays from the Tempus signoff SDF (IOPATH, interconnect not included):

| Stage | Arc | SS (chip_top_post_wst.sdf) | FF (chip_top_post_bst.sdf) |
|---|---|---|---|
| u_pad_sclk | PAD v -> Y v | 0.336 | 0.077 |
| CTS_ccl_a_buf_00092 | A v -> Y v | 0.123 | 0.029 |
| CTS_ccl_a_buf_00002 | A v -> Y v | 0.129 | 0.036 |
| o_miso_reg | CKN v -> Q ^ | 0.288 | 0.066 |
| FE_OFC572_w_miso | A ^ -> Y v | 0.083 | 0.021 |
| FE_OFC573_w_miso | A v -> Y ^ | 0.127 | 0.032 |
| u_pad_miso | A ^ -> PAD ^ | 1.049 | 0.349 |
| **Sum (ns)** | | **2.135** | **0.610** |

- Tempus SS arrival for the same path: 21.951 - 19.792 = 2.159 ns (cell 2.135 + interconnect 0.024)
- SS / FF = 3.5x ; the output pad driving 2 pF is about half of the path in both corners
- SDC output delay on o_miso is 2.0 ns (max) against the next SCLK rising edge (half period 20 ns):
  setup slack 16.149 ns (SS)

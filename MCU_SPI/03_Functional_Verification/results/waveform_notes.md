# RTL waveform captures (SimVision) - what each image shows

| Image | Sim | What to read |
|---|---|---|
| 03_1_cpu_instruction_exec | SIM/CPU (booktest) | PC +4 per cycle; sw (AC01xxxx) -> wmem=1, wreg=0; lui/ori -> aluc 6/5; jal 0x80 at PC 0x2C -> pcsrc=3, wn=$31, PC 0x2C->0x80; bne at 0x94 -> pcsrc=1, PC 0x94->0x84 |
| 03_2a_rx_fifo_overview | SIM/FUNCTION | RX async FIFO: TEST1 write/read 8 bytes, TEST4 fill to level 16 -> o_full, then drain; Gray pointers cross both ways |
| 03_2b_rx_fifo_cdc_2ff | SIM/FUNCTION | 1st byte: wr_ptr_gray 00->01 @1329 ns (SCLK) -> meta_r @1338 -> rclk @1348 (ACLK, 2 cycles) -> level 01 -> empty 0 -> read @1374 -> rd_ptr_gray back into SCLK @1376 |
| 03_3a_cdc01_full_aclk | SIM/FUNCTION | CDC-01 fix: SCLK-side w_rx_fifo_full @20,035 ns; ACLK-side w_rx_fifo_full_aclk rises on the same ACLK edge as level 0F->10 (@20,048 ns); o_overflow @20,810 ns (17th byte dropped) |
| 03_3b_cdc02_busy_sync | SIM/FUNCTION | CDC-02 fix: cs_n rises @1355 ns -> r_spi_busy_sclk (SCLK flop) falls @1392 -> meta @1400 -> sync @1410 (ACLK) |
| 03_4a_mcu_echo_full | SIM/MCU | 8 SPI frames, host_rx_byte 01..08, one w_mem_we per byte, r_gpio 00 -> A5 @~7.0 us, PC ends in halt loop 0x5C |
| 03_4b_mcu_lw_sw | SIM/MCU | lw STATUS @PC 0x0C (rdata 0x0D = RX_VALID|BUSY|EMPTY) -> lw RX_DATA @0x18 (0x00, pop) -> addi +1 -> lw STATUS (TX_FULL=0) -> sw TX_DATA @0x30 (0x01) -> back to polling |

STATUS = {2'b00, TX_FULL, OVERFLOW, RX_VALID, BUSY, FULL, EMPTY}
w_mem_rdata shows X on non-memory cycles: the data RAM has no reset and those addresses are never written; the value is not used.

# 03. Functional Verification

RTL 기능 검증입니다. 모든 testbench는 self-checking(PASS / FAIL 메시지, 에러 카운트)입니다.

| Item | Value |
|---|---|
| Simulator | Cadence Xcelium 22.03 (`xrun`) |
| Script | [`SCRIPT/run_function.tcl`](SCRIPT/run_function.tcl) — `SCRIPT/`에서 `source run_function.tcl` |
| Top TB result | [`LOG/func_sim.log`](LOG/func_sim.log): **ALL TESTS PASSED** (`tb_spi_bridge_top`, 10 tests, 44,896 ns) |

## Testbenches

| File | Target | Log |
|---|---|---|
| [tb_spi_bridge_top.v](TESTBENCH/tb_spi_bridge_top.v) | 전체 (TEST 1~10) | [func_sim.log](LOG/func_sim.log) |
| [tb_spi_master_slave.v](TESTBENCH/tb_spi_master_slave.v) | SPI master ↔ slave | — |
| [tb_spi_slave.v](TESTBENCH/tb_spi_slave.v) | spi_slave | — |
| [tb_async_fifo.v](TESTBENCH/tb_async_fifo.v) | async_fifo | — |
| [tb_register_block.v](TESTBENCH/tb_register_block.v) | register_block | — |
| [tb_tx_boundary.v](TESTBENCH/tb_tx_boundary.v) | TX FIFO 경계 | — |
| [fpga/tb_bufg_sim_stub.v](TESTBENCH/fpga/tb_bufg_sim_stub.v) | BUFG stub | FPGA(`XILINX_FPGA`) 시뮬레이션 전용, ASIC에서는 사용하지 않음 |

## Tests (tb_spi_bridge_top)

| Test | Content | 사양 요구 |
|---|---|---|
| 1 | RX path end-to-end, 6 frames | FR-01, FR-02 |
| 2 | TX path end-to-end | FR-01, FR-03 |
| 3 | TX burst | FR-03 |
| 4 | RX FIFO full / overflow | FR-04 |
| 5 | TX FIFO full / boundary | FR-05 |
| 6 | Reset during transfer | FR-06 |
| 7 | Repeated reset / release timing | FR-06 |
| 8 | Async FIFO Gray pointer, wraparound | FR-07 |
| 9 | Concurrent FIFO read / write stress | FR-08 |
| 10 | Register and protocol corner cases | FR-09 |

## Notes

- 초기 검증은 Vivado XSim으로 했고 ([REPORTS/SPI_Slave_CDC_Bridge_Technical_Report.pdf](REPORTS/SPI_Slave_CDC_Bridge_Technical_Report.pdf), 38쪽), ASIC 플로우에서 Xcelium으로 다시 돌렸습니다.
- `func_sim.log` 끝의 `xmsim: *E,ILLNUM`은 시뮬레이션이 `$finish`로 끝난 뒤 GUI 콘솔에 `run all`을 입력해서 생긴 메시지이며, 결과와 관계없습니다.
- TB 클럭은 `always #5 ACLK` (100 MHz)입니다.
- 블록 단위 testbench(tb_spi_master_slave 등 5개)는 RTL 개발 중 모듈별 확인용이며, 최종 판정은 전체 동작을 다루는 `tb_spi_bridge_top` 로그로 합니다.
- Coverage와 CDC 전용 검증은 수행하지 않았습니다.

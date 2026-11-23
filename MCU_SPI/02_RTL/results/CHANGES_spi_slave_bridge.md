# spi_slave_bridge — changes from spi_bridge_top

Step 1 of the MIPS MCU + SPI project. The bridge becomes an SPI **slave**
peripheral; the SPI host (and SCLK) are now outside the chip.

## Files

| File | Status |
|---|---|
| `RTL/spi_slave_bridge.v` | **new top** (replaces `spi_bridge_top.v`) |
| `RTL/register_block.v` | **modified** — STATUS[5] TX_FULL (see `register_block.diff`) |
| `RTL/async_fifo.v` | unchanged |
| `RTL/spi_slave.v` | unchanged |
| `RTL/pulse_sync.v` | unchanged |
| `RTL/reset_sync.v` | unchanged |
| `tb/spi_master.v` | unchanged, **moved to testbench** as the external host model |
| `tb/tb_spi_slave_bridge.v` | **new** self-checking testbench |
| `sclk_gen.v` | **removed** (SCLK is an input now) |

## RTL changes

| # | Change | Where |
|---|---|---|
| 1 | `spi_master` removed from the chip | top |
| 2 | `sclk_gen` + `BUFG` removed, `SCLK` is an input port (async to ACLK) | top |
| 3 | `i_cs_n`, `i_mosi`, `o_miso` ports added; `o_dbg_*` removed | top |
| 4 | **CDC-01 fix** — STATUS.FULL = `(rx_fifo_level == 16)`, ACLK domain | top |
| 5 | **CDC-02 fix** — slave busy registered in SCLK domain, then 2-FF | top |
| 6 | **STATUS[5] TX_FULL** = `tx_fifo_full \|\| tx_wr_pending` (ACLK domain) | register_block |

## Register map (unchanged except STATUS[5])

| Offset | Name | Access | Bits |
|---|---|---|---|
| 0x00 | RX_DATA | R (pop) | [7:0] received byte |
| 0x04 | STATUS | R | [5] TX_FULL · [4] OVERFLOW · [3] RX_VALID · [2] SPI_BUSY · [1] FULL · [0] EMPTY |
| 0x08 | CONTROL | R/W | [2] IRQ_ENABLE · [1] OVERFLOW_CLEAR (strobe) · [0] FIFO_CLEAR (strobe) |
| 0x0C | FIFO_LEVEL | R | [4:0] RX FIFO level 0..16 |
| 0x10 | TX_DATA | R/W | [7:0] write = push to TX FIFO, read = last written |

## CDC crossings after the change

| Signal | Direction | Handling |
|---|---|---|
| RX data | SCLK → ACLK | Async FIFO 8×16, Gray 2-FF |
| TX data | ACLK → SCLK | Async FIFO 8×4, Gray 2-FF |
| Overflow | SCLK → ACLK | pulse_sync (toggle + 2-FF) |
| SPI_BUSY | SCLK → ACLK | **SCLK flop → 2-FF level sync** (CDC-02 closed) |
| STATUS.FULL | — | **derived in ACLK from synced level, no crossing** (CDC-01 closed) |
| TX_FULL | — | ACLK-only signals, no crossing |
| ARESETn | async → each domain | reset_sync per domain |

## Interface contract / known limitations

- The external host must drive **SCLK continuously** (also between frames and
  during reset release). Frames are delimited by CS_n only. A host that stops
  SCLK between frames is not supported (RX byte write in `S_BYTE_DONE`, TX
  prefetch and the SCLK-side synchronizers all need SCLK edges).
- STATUS.FULL asserts 2–3 ACLK cycles later than the real FIFO full condition
  (synchronized write pointer lag). Dropped bytes are still flagged by OVERFLOW.
- STATUS.TX_FULL reads 1 for one extra ACLK cycle after every TX_DATA write
  (pending-write term). Conservative by design.

## Testbench

`tb_spi_slave_bridge` — ACLK 10 ns, SCLK 41 ns (independent, sliding phase).

| Test | Checks |
|---|---|
| TEST 0 | reset values (STATUS = 0x01, CONTROL / FIFO_LEVEL / TX_DATA = 0) |
| TEST 1 | RX: host bytes 0x00..0x07 read back in order |
| TEST 2 | TX: 4 writes → TX_FULL = 1; MISO sequence A0 A1 A2 A3 then 0x00 |
| TEST 3 | SPI_BUSY observed 1 and 0 (CDC-02 path) |
| TEST 4 | FIFO_LEVEL = 16 → STATUS.FULL = 1 (CDC-01 path), OVERFLOW set, clear |
| TEST 5 | RX consecutive again after FIFO_CLEAR |

Run: `./run_sim.sh` → `LOG/func_sim.log`, waveform `waves.shm`.
Final line expected: `ALL TESTS PASSED (tb_spi_slave_bridge)`.

> Not yet simulated. Written and statically reviewed only.

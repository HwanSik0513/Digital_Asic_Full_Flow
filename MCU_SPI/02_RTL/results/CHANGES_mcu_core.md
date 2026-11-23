# mcu_core — MIPS MCU with SPI slave peripheral

Step 3 of the MIPS MCU + SPI project: CPU (step 2) + SPI slave bridge (step 1)
+ GPIO, connected through a memory-mapped I/O decoder (book Ch. 14 style:
`addr[31]` selects I/O space).

## Hierarchy

```
mcu_core
├── u_reset_sync_core   reset_sync        ACLK-domain reset for CPU / GPIO
├── u_cpu               mips_cpu          single-cycle MIPS (20 instructions)
│   ├── u_cu            sc_cu
│   ├── u_rf            regfile           31 x 32 FF
│   └── u_alu           alu
├── u_rom               inst_rom          64 x 32 case ROM (FW/build/echo_rom.v)
├── u_ram               data_ram          32 x 32 FF
├── u_spi               spi_slave_bridge  SPI Mode 0 slave + async FIFO CDC
└── r_gpio              8-bit GPIO_OUT register
```

## Ports

| Port | Dir | Domain | Description |
|---|---|---|---|
| `ACLK` | in | — | system clock, 100 MHz |
| `ARESETn` | in | async | active-low reset |
| `SCLK` | in | — | SPI clock from the external host, async to ACLK, **continuous** |
| `i_cs_n` | in | SCLK | SPI chip select |
| `i_mosi` | in | SCLK | host → MCU, sampled on SCLK rise |
| `o_miso` | out | SCLK | MCU → host, updated on SCLK fall |
| `o_gpio[7:0]` | out | ACLK | GPIO_OUT register |

## Memory map

| Address | Region | Access |
|---|---|---|
| `0x0000_0000`–`0x0000_007C` | data RAM, 32 words | R/W |
| `0x8000_0000` | SPI RX_DATA | R (pop) |
| `0x8000_0004` | SPI STATUS | R — [5] TX_FULL [4] OVERFLOW [3] RX_VALID [2] BUSY [1] FULL [0] EMPTY |
| `0x8000_0008` | SPI CONTROL | R/W — [2] IRQ_EN [1] OVF_CLEAR [0] FIFO_CLEAR |
| `0x8000_000C` | SPI FIFO_LEVEL | R |
| `0x8000_0010` | SPI TX_DATA | R/W (write = push) |
| `0x8000_0020` | GPIO_OUT | R/W |

Decode: `io = addr[31]`, SPI = `io & addr[7:5]==0`, GPIO = `io & addr[7:0]==0x20`.
Partial decoding: other upper address bits are ignored (aliases); unmapped I/O
reads 0.

## Bus signals per instruction (single cycle)

| Instruction | RAM | SPI bridge | GPIO |
|---|---|---|---|
| `sw` to RAM | `we` | — | — |
| `sw` to I/O | — | `i_bus_wr_en` (1 cycle) | write if +0x20 |
| `lw` from RAM | read | — | — |
| `lw` from I/O | — | `i_bus_rd_en` (1 cycle) → RX_DATA pops exactly once | read if +0x20 |

## Test program

`FW/echo.s` — 8 × (poll RX_VALID → read RX_DATA → +1 → poll TX_FULL → write
TX_DATA), then GPIO_OUT = 0xA5 (PASS) / 0xEE (RX overflow).

## Timing notes for synthesis

- Longest expected ACLK path: PC → ROM → decode → regfile → ALU (address) →
  I/O decode / bridge read mux → write-back mux → regfile. The SPI read mux
  (FIFO level Gray→binary) now sits inside this single-cycle path.
- SCLK logic is confined to `u_spi`; ACLK↔SCLK crossings only through the
  async FIFOs, pulse_sync and 2-FF syncs (see `CHANGES_spi_slave_bridge.md`).

> RTL statically reviewed only; run `SIM/MCU/run_sim.sh` for the simulation result.

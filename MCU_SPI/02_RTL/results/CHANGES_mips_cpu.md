# mips_cpu — ASIC port of the book's single-cycle CPU

Step 2 of the MIPS MCU + SPI project.
Source: Yamin Li, *Computer Principles and Design in Verilog HDL*, Ch. 4–5
(Table 4.4 instruction set, Figure 5.19 datapath, Sections 5.2–5.5).

## Files

| File | Module | Book origin | Notes |
|---|---|---|---|
| `RTL/Mips_cpu.v` | `mips_cpu` | `sccpu` (5.3.3) | datapath; ROM/RAM moved outside; adders/muxes inlined |
| `RTL/Sc_cu.v` | `sc_cu` | `sccu_dataflow` (5.4.2) | identical decode equations (Table 5.3) |
| `RTL/Alu.v` | `alu` | `alu` (4.4) | same aluc encoding; behavioral `+ - << >> >>>` |
| `RTL/Regfile.v` | `regfile` | `regfile` (5.2.3) | 31×32 flops, async clear, $0 = 0 |
| `RTL/Data_ram.v` | `data_ram` | `scdatamem` (5.5) | 32×32 flops, async read / sync write, **no `initial`, no reset** |
| `FW/build/booktest_rom.v` | `inst_rom` | `scinstmem` (5.5) | **generated** case ROM, 64×32 |

## Changes from the book (ASIC)

| Book | This port | Why |
|---|---|---|
| `scdatamem` initialized by `initial` | test data written by the program (`init:` block, 8 instructions) | `initial` is not synthesizable on ASIC |
| `scinstmem` hand-written `assign rom[...]` | ROM generated from `.s` by `mips_asm.py` | change the program without editing RTL |
| `cla32` adders, `shift`, `mux*` modules | behavioral expressions | Genus picks the adder/shifter architecture for the timing target |
| ROM / RAM inside `sccomp` | ROM / RAM are ports of `mips_cpu` | ROM stays its own hierarchy (no constant pruning of the CPU); MCU decoder sits between CPU and RAM/I/O |
| — | `o_mem_re` (= lw) output | read strobe for pop-on-read I/O registers (SPI RX_DATA) |
| `clrn` | `rst_n` | project naming; must come from a reset synchronizer |

Behavior is unchanged: one instruction per cycle, no branch delay slot, no
overflow trap; undefined opcodes act as nop.

## Verification

| Item | Method |
|---|---|
| Assembler | `mips_asm.py` output for the original book program == book ROM, 32/32 words |
| Reference model | `mips_iss.py` on the original book program + book RAM data → RAM[0x60] = 0x258, final regs match the book's program logic |
| RTL | `tb_mips_cpu`: PC every cycle, final $1–$31, written RAM words vs. ISS; RAM[0x60] = $2 = 0x258 |

> RTL statically reviewed only; run `SIM/CPU/run_sim.sh` for the simulation result.

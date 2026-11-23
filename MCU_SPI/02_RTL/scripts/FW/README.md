# FW — programs and tools for the MIPS MCU

| File | Purpose |
|---|---|
| `mips_asm.py` | assembler for the 20 instructions of Table 4.4 (+ `nop`) → `.hex`, `.lst`, case-ROM `_rom.v` |
| `mips_iss.py` | cycle-accurate reference model of the single-cycle CPU → expected PC trace / regs / RAM |
| `booktest.s` | book Section 5.5 test program + RAM init block (CPU-only test, `SIM/CPU`) |
| `echo.s` | MCU system test: SPI RX → +1 → SPI TX ×8, verdict on GPIO_OUT (`SIM/MCU`) |
| `build/` | generated files (do not edit) |

## Regenerate

```bash
cd TOP/FW
python3 mips_asm.py booktest.s -o build/booktest --rom-depth 64
python3 mips_iss.py build/booktest.hex -o build/booktest_exp --ram-words 32
python3 mips_asm.py echo.s     -o build/echo     --rom-depth 64   # MCU ROM (ISS not used: it does not model I/O)
```

or `TOP/SIM/CPU/run_sim.sh -gen` / `TOP/SIM/MCU/run_sim.sh -gen`.

The MCU synthesizes `FW/build/echo_rom.v` as its instruction ROM.

## Generated files

| File | Used by |
|---|---|
| `build/booktest_rom.v` | RTL instruction ROM (`module inst_rom`) |
| `build/booktest.hex` / `.lst` | machine code / listing |
| `build/booktest_exp_pc.hex` | expected PC on every cycle |
| `build/booktest_exp_regs.hex` | expected final $0..$31 |
| `build/booktest_exp_ram.hex` | expected final RAM (`xxxxxxxx` = never written) |
| `build/booktest_exp_trace.txt` | readable per-cycle trace (pc, inst, alu, write-back) — compare with the waveform |

## Assembler rules

- Only `add sub and or xor sll srl sra jr addi andi ori xori lw sw beq bne lui j jal nop`.
- `andi/ori/xori/lui` immediates are zero-extended: 0..0xFFFF. `addi`, `lw/sw` offsets: −32768..32767.
- No branch delay slot (single-cycle CPU). Programs must end in a `j <self>` loop (the ISS uses it to stop).

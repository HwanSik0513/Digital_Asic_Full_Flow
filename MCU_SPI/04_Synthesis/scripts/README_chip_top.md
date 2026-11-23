# SYN — chip_top (MIPS MCU + SPI slave + IO pads)

## Files

| File | Purpose |
|---|---|
| `run_synthesis_chip` | csh launcher → `genus -f script/chip_top_45nm_MMMC.tcl` |
| `script/chip_top_45nm_MMMC.tcl` | Genus MMMC flow (based on `spi_bridge_top_45nm_MMMC.tcl`) |
| `cons/chip_top_syn.mmmc.tcl` | SS_WORST / FF_BEST views, std cells **+ pad libs** (`pads_SS_s1vg.lib`, `pads_FF_s1vg.lib`) |
| `cons/chip_top.sdc` | constraints on chip pins |
| `cons/dont_use_45nm.tcl` | unchanged |

`GPDK_ROOT` = `/home/hah003/PROJ1/GPDK045/digital` (absolute; the old relative
`../../../GPDK045` resolves to PROJ2 from this directory).

## Constraint summary (`chip_top.sdc`)

| Item | Value | Note |
|---|---|---|
| ACLK | 10 ns, port `ACLK` | through `PADDI` |
| SCLK | 40 ns (25 MHz spec), port `SCLK` | **primary clock**, through `PADDI` |
| ACLK ↔ SCLK | `set_clock_groups -asynchronous` | crossings only via async FIFO / syncs |
| latency / uncertainty / transition | 0.2+0.2 / 0.1 / 0.1 ns | same convention as previous project |
| `i_cs_n` | input delay vs SCLK **rise**, 2.0 / 0.5 ns | full-cycle path |
| `i_mosi` | input delay vs SCLK **fall** (`-clock_fall`), 2.0 / 0.5 ns | host shifts on fall → half-cycle |
| `o_miso` | output delay vs SCLK, 2.0 / −0.5 ns | launched by negedge flop → half-cycle |
| `o_gpio[7:0]` | output delay vs ACLK, 2.0 / −0.5 ns | |
| `ARESETn` | false path | async into reset_syncs |
| input transition / output load | 0.5 ns / 2.0 pF | board environment [ASSUMPTION] |

## Hierarchy protection

| Target | Setting | Why |
|---|---|---|
| `u_pad_*` (14) | `dont_touch` | pads must not be resized / removed |
| `u_core/u_rom` | `boundary_opto false`, `ungroup_ok false` | ROM bits constant for this program stay inside the ROM |
| `u_core/u_cpu` | `boundary_opto false`, `ungroup_ok false` | full CPU decode / datapath kept, not only what `echo.s` uses |

Check after the run: `log/chip_top.log` lines `INFO: 14 pad instances found`
and `INFO: boundary optimization disabled on u_rom / u_cpu`; `report/14_*_hier.rpt`
and `report/09a_*_area_by_block.rpt` must still show `u_rom` and `u_cpu`.

## Power pads

Power / ground pads (`PADVDD`, `PADVSS`, `PADVDDIOR`, `PADVSSIOR`) and corners
are not in the RTL. They are added at the PnR step (same method as the
previous `PNR/add_pad` + `init.io`).

## New reports

| Report | Content |
|---|---|
| `09a_*_area_by_block.rpt` | area per hierarchy (CPU / regfile / RAM / bridge / pads) |
| `21a/21b_*` | worst paths per clock (ACLK / SCLK) |
| `21c/21d_*` | input / output (pad) paths |
| `22_*_timing_lint.rpt` | unconstrained endpoints |

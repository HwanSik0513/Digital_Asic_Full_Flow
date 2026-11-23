# PNR — chip_top (MIPS MCU + SPI slave, with IO pad ring)

Legacy Innovus flow (NOT `-stylus`: the stylus mode could not place the
giolib045 corner / pad cells from the IO file, see `README_previous_flow`).

## Run

```csh
cd TOP/PNR
./run_pnr.csh          # = make_pnr_netlist.sh + innovus -files all.tcl
```

or stage by stage: `./make_pnr_netlist.sh`, then `innovus` and
`source 0_InitDesign.tcl`, `source 1_PowerPlan.tcl`, ...

## Files

| File | Purpose |
|---|---|
| `make_pnr_netlist.sh` | `../SYN/mapped/chip_top_syn_final.v` + `add_pad_chip` → `chip_top_pnr_in.v` |
| `add_pad_chip` | 6 supply pad instances (same method as the old `add_pad`) |
| `chip_top.io` | IO ring: 20 pads + 4 corners, explicit offsets |
| `chip_top.mmmc.view` | SS_WORST setup / FF_BEST hold, std + pad libs, absolute PDK path |
| `0_InitDesign.tcl` | init (4 supply nets, IO LEF), floorplan 780 × 780, pads abut (no IO fillers) |
| `1_PowerPlan.tcl` | core ring, pad→ring sroute, follow-pins, stripes |
| `2_PlaceOpt.tcl` … `6_ECO.tcl` | same as the previous project, design name `chip_top` |
| `all.tcl`, `run_pnr.csh`, `clean.tcl`, `capture.tcl` | helpers |

## Floorplan

```
            GPIO0  GPIO1  VDDIOR  GPIO2  GPIO3
        ┌─CORNER──────────────────────────CORNER─┐
  ACLK  │                                         │ i_cs_n
  VDD0  │        core 260 x 260 um                │ i_mosi
  VSS0  │        (270..530 um)                    │ VDD1
ARESETn │        ~40 % utilization                │ VSS1
  SCLK  │                                         │ o_miso
        └─CORNER──────────────────────────CORNER─┘
            GPIO4  GPIO5  VSSIOR  GPIO6  GPIO7
```

| Item | Value |
|---|---|
| Die | 780 × 780 um |
| Pads | 20 (14 signal + 6 supply), 60 × 240 um, 5 per side |
| Pad offsets | 240 / 300 / 360 / 420 / 480 um (pads and corners abut, no IO fillers) |
| Corners | 4 × padIORINGCORNER 240 × 240 um (created from the IO file) |
| Core box | {270 270 530 530} = 260 × 260 um = 67,600 um² |
| Utilization | 26,984 / 67,600 ≈ 40 % (synthesis area) — pad-limited |

## Power

| Net | Source | Distribution |
|---|---|---|
| VDD / VSS (core) | PADVDD ×2, PADVSS ×2 (left, right) | pad pins → core ring (M10/M11, 5 um) → M10 stripes ×8 sets → M1 follow-pins |
| VDDIOR / VSSIOR (IO) | PADVDDIOR, PADVSSIOR (top, bottom) | ring inside the pads, closed by IO fillers |

IO fillers (`padIORINGFEED*`) call their ring pins `VDDPAD25` / `VSSPAD`;
`globalNetConnect` maps them to `VDDIOR` / `VSSIOR`.

## Checks after 0_InitDesign / 1_PowerPlan

- log: `**INFO: pads = 20`, `corners = 4`, `IO ring fillers = N` (N > 0)
- `capture/00_floorplan.gif`: pads in the order of the table above, no overlap
- `verifyConnectivity` after PowerPlan: no open on VDD / VSS
- `capture/01_powerplan.gif`: core ring, 8 stripe pairs, pad-to-ring straps

## Not verified yet (first run)

Written from the previous block-level scripts and the giolib045 LEF; not run
here. Points most likely to need adjustment on the first run:
`loadIoFile` / `addIoFiller` options, `sroute -connect padPin` options,
pad orientation on each side.

## Signoff STA (Tempus) and optional hold ECO

```
5_ChipFinish (Innovus)          -> ChipFinish.dat
tempus_post_sta.tcl  (Tempus)   -> reports/sta/ChipFinish/, chip_top_post_wst.sdf / _bst.sdf
  hold violation?  no  -> done (use chip_top_pnr.v + post SDF for GLS)
                   yes -> tempus_hold_eco.tcl (Tempus)  -> innovus.eco
                          6_ECO.tcl (NEW Innovus)        -> ChipFinish_after_ECO.dat, chip_top_eco.v
                          tempus_post_sta_eco.tcl        -> reports/sta/ChipFinish_after_ECO/, chip_top_eco_wst/bst.sdf
```

Run all three Tempus scripts in the PNR directory:
`tempus -files tempus_post_sta.tcl -log tempus_post_sta.log`

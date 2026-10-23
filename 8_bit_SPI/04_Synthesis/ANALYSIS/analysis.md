# SPI CDC Bridge — Synthesis Analysis

> **Design:** `spi_bridge_top`  
> **Tool:** Cadence Genus 22.17-s071_1  
> **Technology:** GPDK045 / `PVT_0P9V_125C` (setup/max)  
> **Analysis date:** 2026-10-23  
> **Primary source:** `SPI_Bridge_Genus_Synthesis_Report.pdf` (12 pages, generated 2026-10-22)  
> **Scope:** Pre-layout logic synthesis. Results are not post-route sign-off results.

## 1. Executive Summary

The SPI CDC Bridge was synthesized using `syn_generic → syn_map → syn_opt`. Under the **synthesis stress constraints** of ACLK **1.0 ns (1 GHz)** and internally generated SCLK **4.0 ns (250 MHz)**, the report shows **no setup violations**, **TNS = 0**, and **no reported max-transition/max-capacitance design-rule violations**. These constraints are intentionally distinguishable from the nominal RTL operating targets (ACLK 100 MHz, SCLK 25 MHz).

| Metric | Final (`syn_opt`) | Interpretation |
|---|---:|---|
| ACLK worst setup slack | **+109.4 ps** | Tightest reported path group |
| SCLK worst setup slack | **+315.6 ps** | Positive setup margin under the applied timing model |
| TNS / failing paths | **0 / 0** | No reported setup failures |
| Standard-cell area | **3,397.428 µm²** | Cell area, excluding the separately reported physical-area contribution |
| Total reported area | **4,382.598 µm²** | Cell area + reported physical area; not a placed core area |
| Leaf instances | **806** | 343 sequential + 463 non-sequential |
| Estimated total power | **905.4 µW** | Activity assumptions not established; not a sign-off estimate |

**Assessment:** The current mapped implementation meets the reported pre-layout setup checks. The main improvement opportunities are the FIFO-level read combinational path, the FIFO register area footprint, and constraint/CDC validation. This does **not** establish hold closure, CDC correctness, or post-layout timing closure.

## 2. Synthesis Stage Comparison

| Metric | `syn_generic` | `syn_map` | `syn_opt` |
|---|---:|---:|---:|
| Worst slack (ps) | +313 | +109 | +109 |
| R2R slack (ps) | +322 | +237 | +169 |
| R2O slack (ps) | +313 | +109 | +109 |
| Cell area (µm²) | 5,455.659 | 3,407.004 | 3,397.428 |
| Leaf instances | 1,273 | 822 | 806 |
| Sequential instances | 343 | 343 | 343 |
| Combinational/non-sequential instances | 930 | 479 | 463 |
| TNS / failing paths | 0 / 0 | 0 / 0 | 0 / 0 |

- `syn_generic → syn_map`: area decreases by approximately **37.6%**. This is a comparison across different synthesis representations and must **not** be presented as a controlled before/after RTL optimization experiment.
- `syn_map → syn_opt`: area decreases by **9.576 µm² (~0.28%)** and leaf instances decrease by **16**, while the overall worst slack stays near **+109 ps**.
- R2R slack decreases from **+237 ps to +169 ps** during `syn_opt`. The report does not prove the exact internal optimization mechanism; area recovery is a plausible interpretation, not a verified cause.
- **Netlist provenance:** The source report states `spi_bridge_top_mapped.v` and `syn_final.v` are **identical apart from a date comment**. Do not claim that a structural netlist diff proves `syn_map → syn_opt` improvement. Check the actual `write_hdl` / `write_design` points in the Tcl script before labeling them as separate stage snapshots.

## 3. Critical Timing Path

### 3.1 ACLK group — FIFO level read to bus output

| Item | Reported result |
|---|---|
| Startpoint | `u_rx_fifo/r_wr_ptr_gray_rclk_reg_4` |
| Endpoint | `o_bus_rdata[4]` |
| Path type | Register-to-output (R2O) |
| Worst slack | **+109.4 ps** |
| Required time | ~1,200 ps |
| Arrival time | ~1,091 ps |
| Data-path delay | ~691 ps |

**Observed logic structure:** synchronized RX FIFO write Gray pointer → Gray-to-binary XOR chain → FIFO-level subtraction/carry logic → `register_block` output mux → `o_bus_rdata[4]`.

The report breaks the data path into approximately **86 ps CK→Q**, **196 ps Gray-to-binary XOR**, **242 ps subtraction logic**, and **166 ps final output cell** (rounded). The final `OAI2BB1X1` drives approximately **21.6 fF** and has a reported transition of **270 ps**; it is a substantial contributor to the path delay.

**Engineering interpretation:** FIFO-level computation is combinationally exposed to the bus output. A candidate experiment is to register the level/read result or restructure the level calculation. This would potentially reduce the combinational depth **but may add one cycle of bus-read latency or alter status freshness**. No such RTL change or improvement measurement is claimed in this baseline.

### 3.2 SCLK group

The report identifies a separate SCLK-group critical path ending at `u_tx_fifo/o_rd_data_reg_7`, with **+315.6 ps** slack. Because SCLK is generated from ACLK, the timing report analyzes some cross-domain paths under the defined generated-clock relationship. A positive slack on such a path is **not** evidence that an asynchronous FIFO's CDC behavior is safe.

## 4. Area and Cell Architecture

| Block | Cell area (µm²) | Share of cell area |
|---|---:|---:|
| `u_rx_fifo` | ~1,782.2 | ~52.5% |
| `u_tx_fifo` | ~606.4 | ~17.8% |
| `u_spi_master` | ~349.5 | ~10.3% |
| `u_spi_slave` | ~319.4 | ~9.4% |
| `u_register_block` | ~255.1 | ~7.5% |

- **Sequential cells:** 343 instances, **2,489.418 µm² (~73.3%)** of cell area.
- **FIFO storage:** `EDFFHQX1` **160 instances**, **1,368.0 µm² (~40.3%)** of cell area.
- This matches the declared storage bits: **RX 16 × 8 = 128** and **TX 4 × 8 = 32**, for a total of **160**.
- The report finds **no memory macro cells**; the FIFO storage is implemented using flip-flop cells.

**Engineering interpretation:** The FIFO storage architecture, particularly the deeper RX FIFO, dominates cell area. Possible future trade-off studies include changing FIFO depth or comparing alternative storage implementations **subject to the actual available technology libraries and functional requirements**. These are proposals, not completed optimizations.

## 5. Power Interpretation

| Category | Estimated total power |
|---|---:|
| Registers | ~719.4 µW (79.46%) |
| Logic | ~144.9 µW (16.01%) |
| Clock | ~41.1 µW (4.54%) |
| **Total** | **~905.4 µW** |

The report gives approximately **76.88% internal**, **23.10% switching**, and **0.02% leakage** power. However, the report does not establish whether VCD/SAIF activity was supplied or whether defaults were used. The ACLK ideal-network setting may also limit clock-network power realism. Accordingly, these numbers are **pre-layout tool estimates**, not validated silicon power or sign-off values.

## 6. Constraint and Quality Checks

- **Clock constraints:** ACLK is a primary 1 GHz clock; SCLK is an ACLK-derived `/4` generated clock at 250 MHz. This is the stress synthesis setup, **not** the nominal 100/25 MHz design target.
- **CDC constraints:** The inspected SDC does not define CDC-specific `set_clock_groups`, `set_max_delay`, or CDC-directed false paths. The appropriate constraints depend on the intended relationship of the generated clock and the actual CDC implementation. Do not automatically classify ACLK/SCLK as unrelated asynchronous clocks without reviewing the architecture.
- **Reported design checks:** No unresolved references, undriven or multidriven ports, and no reported max-transition/max-capacitance violations. The report nevertheless lists unloaded pins and several warnings.
- **Warnings to triage:** `SDC-248` (invalid SDC objects), `VLOGPT-692` (potential function/task simulation–synthesis mismatch), `CDFG-472` (unreachable case statements), and library/physical-model warnings (`LBR-*`, `PHYS-*`). Warning counts and suspected causes come from the source report; source-code line locations require log review.
- **Unverified checks:** Hold timing, formal CDC/RDC, LEC, scan/DFT, post-placement and post-route timing are **not** established by this report.

## 7. Proposed Next Experiments (Not Yet Performed)

| Priority | Experiment | Measurement / acceptance criterion |
|---|---|---|
| P1 | Validate `SDC-248` warnings and actual clock/IO object matching | Every intended constraint binds to the correct design object; document exceptions |
| P1 | Run CDC/RDC structural checks for Gray-pointer synchronization, reset release, and overflow pulse crossing | No unexplained crossings or reset-domain issues |
| P2 | Compare baseline FIFO-level combinational read with a registered or restructured version | Same functionality or documented latency trade-off; compare WNS, area, cell count |
| P2 | Perform ACLK-period sweep using identical RTL/library/corner and clearly versioned SDC | Identify first setup failure and PPA trade-offs |
| P3 | Evaluate FIFO-depth/implementation trade-offs | Quantify area/power effects and functional capacity impact |
| P3 | Use representative simulation activity for power estimation | Document SAIF/VCD source and operating scenario |
| P3 | Perform LEC and later post-layout STA | Verify equivalence and physical timing after downstream steps |

**Measurement rule:** For each experiment, preserve the baseline and modified RTL/SDC/Tcl files, run under comparable conditions, and publish the corresponding tool reports. Never describe a proposed optimization as a measured improvement.

## 8. Evidence and Limitations

**Primary evidence:** `SPI_Bridge_Genus_Synthesis_Report.pdf`, pp. 1–12, especially §02 constraints, §03 QoR, §05 critical paths, §06 area, §07 power, §09 warnings, and §10 limitations. The report was prepared from Genus QoR/timing/area/gate/power reports, SDC/Tcl files, netlists, and a partial SDF inspection.

**Important limitations:**
1. Setup slack is evaluated using the reported pre-layout timing model; physical placement, routing parasitics, and clock-tree effects are not closed.
2. No hold report or independent CDC/RDC verification is included.
3. No completed LEC result is included.
4. Power activity provenance is unknown.
5. `mapped.v` and `syn_final.v` were reported as structurally identical; optimization claims must rely on the stage-specific QoR reports rather than a supposed netlist difference.

---

**Portfolio takeaway:** This baseline demonstrates synthesis setup, constraint interpretation, report-driven critical-path diagnosis, and area/power reasoning. The next evidence of engineering improvement should come from a **controlled, reproducible optimization experiment**, not from unverified claims about what Genus automatically changed.

# 18. Final Verification — MMMC / 625MHz

| Item | Value |
|---|---|
| Clock | **ACLK 1.6 ns (625 MHz)**, SCLK = ACLK ÷ 4 |
| Tool | Cadence Innovus 22.17 |
| Script | [`scripts/5_ChipFinish.tcl`](scripts/5_ChipFinish.tcl) — addFiller 후 verify_drc / verifyConnectivity |

| Check | Result |
|---|---|
| verify_drc (Innovus) | **0 violations** → [`reports/final_drc.rpt`](reports/final_drc.rpt) |
| verifyConnectivity | **no problems / no warnings** |
| checkPlace | 0 violations → [`reports/checkPlace.rpt`](reports/checkPlace.rpt) |
| BUFX2 (CoreSiteDouble) 인스턴스 | 0 |

> Innovus 내장 DRC / connectivity 기준입니다. foundry rule deck DRC와 LVS(Pegasus 등)는 사용할 수 없는 툴이라 실행하지 않았습니다.

## Files

```text
18_Final_Verification/MMMC/625MHz/
├── README.md
│
├── reports/
│   ├── checkPlace.rpt
│   ├── connectivity.rpt
│   └── final_drc.rpt
│
└── scripts/
    └── 5_ChipFinish.tcl
```

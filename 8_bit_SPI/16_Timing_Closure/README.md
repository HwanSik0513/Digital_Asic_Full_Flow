# 16. Timing Closure

Innovus `optDesign`(setup / hold / DRV)으로 타이밍을 닫은 결과입니다. BUFX2 TechSite 위반 수정 사례는 [MMMC/500MHz_BUFX2_case](MMMC/500MHz_BUFX2_case)에 있습니다. Tempus hold ECO 실습(hold fix를 끈 run → Tempus ECO → Innovus 적용)은 [MMMC/100MHz_HoldECO](MMMC/100MHz_HoldECO)에 있습니다.

> **폴더 구성** — `SLOW` / `FAST`는 slow(SS) / fast(FF) 라이브러리 하나로 합성한 넷리스트를 같은 PnR 조건으로 구현한 **비교 실험**입니다. `MMMC`는 합성도 SS·FF MMMC로 바꾼 **최종 방식**이며, `MMMC/100MHz`가 사양 주파수 기준 run, `500MHz`·`625MHz`는 Fmax 실험입니다.

## Runs

| Run | Hold (fix 전 → 후) | 최종 Setup WNS | 최종 밀도 |
|---|---|---|---|
| [SLOW / 100MHz](SLOW/100MHz) | -0.117 → +0.004 ns | +7.728 ns | 74.88 % |
| [SLOW / 500MHz](SLOW/500MHz) | -0.103 → +0.003 ns | +0.054 ns | 72.32 % |
| [SLOW / 1GHz](SLOW/1GHz) | -0.089 → +0.003 ns | -0.463 ns | 80.55 % |
| [FAST / 100MHz](FAST/100MHz) | -0.100 → +0.002 ns | +7.623 ns | 77.33 % |
| [FAST / 500MHz](FAST/500MHz) | -0.089 → +0.007 ns | +0.024 ns | 78.29 % |
| [FAST / 1GHz](FAST/1GHz) | -0.095 → -0.091 ns | -0.481 ns | 95.15 % |
| [MMMC / 100MHz](MMMC/100MHz) | -0.102 → +0.002 ns | +7.716 ns | 74.70 % |
| [MMMC / 500MHz](MMMC/500MHz) | -0.115 → +0.006 ns | +0.083 ns | 73.85 % |
| [MMMC / 625MHz](MMMC/625MHz) | -0.105 → +0.002 ns | +0.035 ns | 68.22 % |
| [MMMC / 500MHz_BUFX2_case](MMMC/500MHz_BUFX2_case) | BUFX2 TechSite 13 → 0 (ECO) | +0.080 ns | 73.06 % |
| [MMMC / 100MHz_HoldECO](MMMC/100MHz_HoldECO) | -0.098 → +0.012 ns (Tempus ECO, CLKBUFX2 76) | +7.714 ns | 75.08 % |

## Scripts

| File | 역할 |
|---|---|
| [`scripts/tempus_hold_eco.tcl`](scripts/tempus_hold_eco.tcl) | Tempus에서 hold 위반 끝점마다 CLKBUFX2 삽입 → `innovus.eco` 출력 |
| [`scripts/6_ECO.tcl`](scripts/6_ECO.tcl) | Innovus에서 `innovus.eco` 반영 → refinePlace / ecoRoute → 필러 → GDS·넷리스트·SDF |
| [`scripts/bufx2_guard.tcl`](scripts/bufx2_guard.tcl) | BUFX2(CoreSiteDouble) 사용 금지 + 검사. 새 Innovus 세션마다 restoreDesign 뒤 source |

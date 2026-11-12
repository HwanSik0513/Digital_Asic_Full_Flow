# 15. Post-Layout STA

배선 후(propagated clock, 추출 RC) setup은 `FUNC_SS_WORST`, hold는 `FUNC_FF_BEST`로 검사합니다. SLOW/FAST run은 **Innovus `timeDesign` 결과**이고, 기준 run [MMMC/100MHz](MMMC/100MHz)는 **Tempus**([`scripts/tempus_post_sta.tcl`](scripts/tempus_post_sta.tcl))로 다시 분석했습니다 — setup/hold/recovery/removal, coverage, untested 분석, Pre vs Post 비교, GLS용 SDF 출력.

> **폴더 구성** — `SLOW` / `FAST`는 slow(SS) / fast(FF) 라이브러리 하나로 합성한 넷리스트를 같은 PnR 조건으로 구현한 **비교 실험**입니다. `MMMC`는 합성도 SS·FF MMMC로 바꾼 **최종 방식**이며, `MMMC/100MHz`가 사양 주파수 기준 run, `500MHz`·`625MHz`는 Fmax 실험입니다.

## Runs

| Run | Setup WNS | Setup 위반 | Hold WNS | 판정 |
|---|---|---|---|---|
| [SLOW / 100MHz](SLOW/100MHz) | +7.728 ns | 0 | +0.004 ns | PASS |
| [SLOW / 500MHz](SLOW/500MHz) | +0.054 ns | 0 | +0.003 ns | PASS |
| [SLOW / 1GHz](SLOW/1GHz) | -0.463 ns | 64 | +0.003 ns | FAIL |
| [FAST / 100MHz](FAST/100MHz) | +7.623 ns | 0 | +0.002 ns | PASS |
| [FAST / 500MHz](FAST/500MHz) | +0.024 ns | 0 | +0.007 ns | PASS |
| [FAST / 1GHz](FAST/1GHz) | -0.481 ns | 88 | -0.091 ns | FAIL |
| **[MMMC / 100MHz](MMMC/100MHz)** | **+7.716 ns (Tempus)** | 0 | **+0.002 ns** | **PASS** (recovery +9.291 / removal +0.038 ns) |
| [MMMC / 500MHz](MMMC/500MHz) | +0.083 ns | 0 | +0.006 ns | PASS |
| [MMMC / 625MHz](MMMC/625MHz) | +0.035 ns | 0 | +0.002 ns | PASS |

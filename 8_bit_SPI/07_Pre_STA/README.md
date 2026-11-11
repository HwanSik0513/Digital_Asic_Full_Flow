# 07. Pre-Layout STA

합성 직후(ideal clock, 배선 지연 없음)의 setup 타이밍입니다. run들은 **Genus `report_timing` 결과**이고, 기준 run [MMMC/100MHz](MMMC/100MHz)는 **Tempus**로도 확인했습니다 ([`scripts/tempus_pre_sta.tcl`](scripts/tempus_pre_sta.tcl) + [`scripts/tempus_pre.view`](scripts/tempus_pre.view), legacy mode). 이 단계의 hold는 ideal clock이라 참고용입니다.

> **폴더 구성** — `SLOW` / `FAST`는 slow(SS) / fast(FF) 라이브러리 하나로 합성한 넷리스트를 같은 PnR 조건으로 구현한 **비교 실험**입니다. `MMMC`는 합성도 SS·FF MMMC로 바꾼 **최종 방식**이며, `MMMC/100MHz`가 사양 주파수 기준 run, `500MHz`·`625MHz`는 Fmax 실험입니다.

## Runs

| Run | ACLK slack | SCLK slack | Tool |
|---|---|---|---|
| [SLOW / 100MHz](SLOW/100MHz) | +7,101.2 ps | +8,673.7 ps | Genus `report_timing` |
| [SLOW / 500MHz](SLOW/500MHz) | +1.8 ps | +673.1 ps | Genus `report_timing` |
| [SLOW / 1GHz](SLOW/1GHz) | -608.2 ps | -90.7 ps | Genus `report_timing` |
| [FAST / 100MHz](FAST/100MHz) | +9,074.9 ps | +9,314.4 ps | Genus `report_timing` |
| [FAST / 500MHz](FAST/500MHz) | +1,109.4 ps | +1,316.7 ps | Genus `report_timing` |
| [FAST / 1GHz](FAST/1GHz) | +109.4 ps | +315.6 ps | Genus `report_timing` |
| **[MMMC / 100MHz](MMMC/100MHz)** | +7,097 ps (Genus) / **+7,315 ps (Tempus)** | +8,674 ps | Genus + **Tempus** |
| [MMMC / 500MHz](MMMC/500MHz) | +11 ps | +673 ps | Genus `report_timing` (SS) |
| [MMMC / 625MHz](MMMC/625MHz) | 0 ps | +273 ps | Genus `report_timing` (SS) |
| [MMMC / 667MHz](MMMC/667MHz) | −25 ps | +173 ps | Genus `report_timing` (SS) |
| [MMMC / 714MHz](MMMC/714MHz) | −124 ps | +120 ps | Genus `report_timing` (SS) |

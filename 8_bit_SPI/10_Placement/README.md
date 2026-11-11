# 10. Placement (Innovus)

`place_opt_design`으로 배치와 pre-CTS 최적화를 합니다.

> **폴더 구성** — `SLOW` / `FAST`는 slow(SS) / fast(FF) 라이브러리 하나로 합성한 넷리스트를 같은 PnR 조건으로 구현한 **비교 실험**입니다. `MMMC`는 합성도 SS·FF MMMC로 바꾼 **최종 방식**이며, `MMMC/100MHz`가 사양 주파수 기준 run, `500MHz`·`625MHz`는 Fmax 실험입니다.

## Runs

| Run | Instances (PowerPlan → PlaceOpt) | 초기 밀도 |
|---|---|---|
| [SLOW / 100MHz](SLOW/100MHz) | 837 → 889 | 69.57 % |
| [SLOW / 500MHz](SLOW/500MHz) | 881 → 899 | 69.47 % |
| [SLOW / 1GHz](SLOW/1GHz) | 1024 → 1178 | 68.59 % |
| [FAST / 100MHz](FAST/100MHz) | 816 → 937 | 69.93 % |
| [FAST / 500MHz](FAST/500MHz) | 804 → 950 | 69.97 % |
| [FAST / 1GHz](FAST/1GHz) | 806 → 1165 | 69.95 % |
| [MMMC / 100MHz](MMMC/100MHz) | 828 → 883 | 69.97 % |
| [MMMC / 500MHz](MMMC/500MHz) | 849 → 883 | 69.92 % |
| [MMMC / 625MHz](MMMC/625MHz) | 942 → 970 | 69.37 % |

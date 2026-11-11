# 11. Clock Tree Synthesis (Innovus CCOpt)

`ccopt_design`으로 ACLK / SCLK 클럭 트리를 만들고 post-CTS 최적화를 합니다.

> **폴더 구성** — `SLOW` / `FAST`는 slow(SS) / fast(FF) 라이브러리 하나로 합성한 넷리스트를 같은 PnR 조건으로 구현한 **비교 실험**입니다. `MMMC`는 합성도 SS·FF MMMC로 바꾼 **최종 방식**이며, `MMMC/100MHz`가 사양 주파수 기준 run, `500MHz`·`625MHz`는 Fmax 실험입니다.

## Runs

| Run | Skew (setup view) | Insertion delay | hold fix 전 WNS |
|---|---|---|---|
| [SLOW / 100MHz](SLOW/100MHz) | 0.650 ns | 0.200 ~ 0.850 ns | -0.117 ns (16 paths) |
| [SLOW / 500MHz](SLOW/500MHz) | 0.628 ns | 0.200 ~ 0.828 ns | -0.103 ns (16 paths) |
| [SLOW / 1GHz](SLOW/1GHz) | 0.602 ns | 0.200 ~ 0.802 ns | -0.089 ns (16 paths) |
| [FAST / 100MHz](FAST/100MHz) | 0.602 ns | 0.200 ~ 0.802 ns | -0.100 ns (16 paths) |
| [FAST / 500MHz](FAST/500MHz) | 0.561 ns | 0.200 ~ 0.761 ns | -0.089 ns (16 paths) |
| [FAST / 1GHz](FAST/1GHz) | 0.585 ns | 0.200 ~ 0.785 ns | -0.095 ns (16 paths) |
| [MMMC / 100MHz](MMMC/100MHz) | ACLK 0.000 / SCLK 0.066 ns (Tempus) | max ID 0.586 ns (CCOpt) | -0.102 ns (16 paths) |
| [MMMC / 500MHz](MMMC/500MHz) | — | max ID 0.662 ns (CCOpt) | -0.115 ns (16 paths) |
| [MMMC / 625MHz](MMMC/625MHz) | — | max ID 0.592 ns (CCOpt) | -0.105 ns (16 paths) |

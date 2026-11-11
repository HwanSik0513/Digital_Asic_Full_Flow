# 12. Routing (Innovus NanoRoute)

`routeDesign`으로 상세 배선을 하고 post-route 최적화를 합니다.

> **폴더 구성** — `SLOW` / `FAST`는 slow(SS) / fast(FF) 라이브러리 하나로 합성한 넷리스트를 같은 PnR 조건으로 구현한 **비교 실험**입니다. `MMMC`는 합성도 SS·FF MMMC로 바꾼 **최종 방식**이며, `MMMC/100MHz`가 사양 주파수 기준 run, `500MHz`·`625MHz`는 Fmax 실험입니다.

## Runs

| Run | Wirelength | Vias | DRC |
|---|---|---|---|
| [SLOW / 100MHz](SLOW/100MHz) | 13,088 µm | 6,590 | 0 |
| [SLOW / 500MHz](SLOW/500MHz) | 12,985 µm | 6,535 | 0 |
| [SLOW / 1GHz](SLOW/1GHz) | 17,576 µm | 8,410 | 0 |
| [FAST / 100MHz](FAST/100MHz) | 13,120 µm | 6,718 | 0 |
| [FAST / 500MHz](FAST/500MHz) | 13,209 µm | 6,807 | 0 |
| [FAST / 1GHz](FAST/1GHz) | 14,824 µm | 7,927 | 0 |
| [MMMC / 100MHz](MMMC/100MHz) | 13,141 µm | 6,598 | 0 |
| [MMMC / 500MHz](MMMC/500MHz) | 13,309 µm | 6,608 | 0 |
| [MMMC / 625MHz](MMMC/625MHz) | 13,988 µm | 6,908 | 0 |

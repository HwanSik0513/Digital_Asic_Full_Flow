# 09. Floorplan & Power Plan (Innovus)

core-only 블록(IO pad 없음) floorplan, 핀 배치, power ring / stripe / follow-pin rail입니다.

> **폴더 구성** — `SLOW` / `FAST`는 slow(SS) / fast(FF) 라이브러리 하나로 합성한 넷리스트를 같은 PnR 조건으로 구현한 **비교 실험**입니다. `MMMC`는 합성도 SS·FF MMMC로 바꾼 **최종 방식**이며, `MMMC/100MHz`가 사양 주파수 기준 run, `500MHz`·`625MHz`는 Fmax 실험입니다.

## Runs

| Run | Die | Core | 초기 배치 밀도 |
|---|---|---|---|
| [SLOW / 100MHz](SLOW/100MHz) | 91.6 × 90.25 µm | 71.6 × 70.11 µm | 69.57 % |
| [SLOW / 500MHz](SLOW/500MHz) | 92.2 × 91.96 µm | 72.2 × 71.82 µm | 69.47 % |
| [SLOW / 1GHz](SLOW/1GHz) | 101.6 × 100.51 µm | 81.6 × 80.37 µm | 68.59 % |
| [FAST / 100MHz](FAST/100MHz) | 91.0 × 88.54 µm | 71.0 × 68.40 µm | 69.93 % |
| [FAST / 500MHz](FAST/500MHz) | 91.0 × 88.54 µm | 71.0 × 68.40 µm | 69.97 % |
| [FAST / 1GHz](FAST/1GHz) | 91.0 × 88.54 µm | 71.0 × 68.40 µm | 69.95 % |
| [MMMC / 100MHz](MMMC/100MHz) | 91.6 × 90.25 µm | 5,019 µm² | 69.97 % |
| [MMMC / 500MHz](MMMC/500MHz) | 92.8 × 90.25 µm | 5,104 µm² | 69.92 % |
| [MMMC / 625MHz](MMMC/625MHz) | 98.2 × 95.38 µm | 5,883 µm² | 69.37 % |

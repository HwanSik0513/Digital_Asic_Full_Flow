# 14. RC Extraction

배선 후 기생 RC 추출입니다. 플로우의 Quantus는 사용할 수 없어 **Innovus 내장 추출**을 썼습니다. 기준 run에서 코너별 SPEF를 내보내고, Innovus DB 없이 넷리스트 + SDC + SPEF로 Tempus STA를 재현했습니다 → [MMMC/100MHz](MMMC/100MHz).

> **폴더 구성** — `SLOW` / `FAST`는 slow(SS) / fast(FF) 라이브러리 하나로 합성한 넷리스트를 같은 PnR 조건으로 구현한 **비교 실험**입니다. `MMMC`는 합성도 SS·FF MMMC로 바꾼 **최종 방식**이며, `MMMC/100MHz`가 사양 주파수 기준 run, `500MHz`·`625MHz`는 Fmax 실험입니다.

## Runs

| Run | Extraction | SPEF |
|---|---|---|
| [SLOW / 100MHz](SLOW/100MHz) | Innovus `extractRC` (effort low, captable) | — |
| [SLOW / 500MHz](SLOW/500MHz) | Innovus `extractRC` (effort low, captable) | — |
| [SLOW / 1GHz](SLOW/1GHz) | Innovus `extractRC` (effort low, captable) | — |
| [FAST / 100MHz](FAST/100MHz) | Innovus `extractRC` (effort low, captable) | — |
| [FAST / 500MHz](FAST/500MHz) | Innovus `extractRC` (effort low, captable) | — |
| [FAST / 1GHz](FAST/1GHz) | Innovus `extractRC` (effort low, captable) | — |
| **[MMMC / 100MHz](MMMC/100MHz)** | Innovus `extractRC` + Tempus annotation 100 % (1,030 / 1,030) | **WORST / BEST 출력, SPEF 기반 Tempus setup +7.716 / hold +0.002 ns** |
| [MMMC / 500MHz](MMMC/500MHz) | Innovus `extractRC` (R 15,920 / C 16,250) | — |
| [MMMC / 625MHz](MMMC/625MHz) | Innovus `extractRC` (R 17,483 / C 17,919) | — |

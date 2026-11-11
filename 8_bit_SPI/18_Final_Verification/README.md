# 18. Final Verification

필러 삽입 후 Innovus 기준 물리 검증입니다. foundry rule deck 기반 signoff DRC와 LVS 도구는 없어 실행하지 않았습니다.

> **폴더 구성** — `SLOW` / `FAST`는 slow(SS) / fast(FF) 라이브러리 하나로 합성한 넷리스트를 같은 PnR 조건으로 구현한 **비교 실험**입니다. `MMMC`는 합성도 SS·FF MMMC로 바꾼 **최종 방식**이며, `MMMC/100MHz`가 사양 주파수 기준 run, `500MHz`·`625MHz`는 Fmax 실험입니다.

## Runs

| Run | verify_drc | verifyConnectivity | LVS |
|---|---|---|---|
| [SLOW / 100MHz](SLOW/100MHz) | 0 | clean | 미실행 |
| [SLOW / 500MHz](SLOW/500MHz) | 0 | clean | 미실행 |
| [SLOW / 1GHz](SLOW/1GHz) | 0 | clean | 미실행 |
| [FAST / 100MHz](FAST/100MHz) | 0 | clean | 미실행 |
| [FAST / 500MHz](FAST/500MHz) | 0 | clean | 미실행 |
| [FAST / 1GHz](FAST/1GHz) | 0 | clean | 미실행 |
| [MMMC / 100MHz](MMMC/100MHz) | 0 | clean | 미실행 |
| [MMMC / 500MHz](MMMC/500MHz) | 0 | clean | 미실행 |
| [MMMC / 625MHz](MMMC/625MHz) | 0 | clean | 미실행 |

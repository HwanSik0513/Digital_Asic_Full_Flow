# SPI Bridge Top — Synthesis Comparison

## 1. 실험 매트릭스

RTL을 고정하고 ACLK 주파수(100MHz / 1GHz)와 FAST/SLOW 라이브러리 조건을 바꿔 합성한 결과입니다. SCLK는 ACLK / 4로 설정했습니다.

| ACLK | Corner | ACLK WNS (ps) | SCLK WNS (ps) | TNS (ps) | Cell Area (µm²) | Cells | 판정 |
|---|---|---:|---:|---:|---:|---:|---|
| 100MHz | FAST | 9074.9 | 9314.4 | 0.0 | 3396.402 | 816 | **PASS** |
| 100MHz | SLOW | 7101.2 | 8673.7 | 0.0 | 3506.184 | 837 | **PASS** |
| 1GHz | FAST | 109.4 | 315.6 | 0.0 | 3397.428 | 806 | **PASS** |
| 1GHz | SLOW | -608.2 | -90.7 | -10342.3 | 4579.722 | 1024 | **FAIL** |

## 2. Corner 비교

- **100MHz:** FAST 대비 SLOW Cell Area가 109.782 µm² 증가(3.23%). 두 조건 모두 타이밍 PASS.
- **1GHz:** FAST 대비 SLOW Cell Area가 1182.294 µm² 증가(34.80%). FAST는 PASS지만 SLOW는 FAIL.

## 3. 주파수 비교

- **100MHz:** ACLK/SCLK 양쪽에서 충분한 양수 Slack이 관측되어 원래 합성 타이밍 목표를 만족합니다.
- **1GHz:** 타이밍 여유가 크게 줄어들며 SLOW에서 위반 경로가 발생합니다. 특히 ACLK Register-to-Output과 SCLK TX FIFO 내부 경로를 우선 검토합니다.
- 같은 RTL이어도 합성 타이밍 목표가 달라지면 선택 셀, 최적화 결과, 면적이 달라질 수 있습니다.

## 4. 설계 판단

- **기본 Full Flow 후보:** 원래 사양인 100MHz를 기준으로 downstream DFT/LEC/STA/PnR을 진행하는 방안을 권장합니다. 구체적인 기준 netlist/corner는 별도 지정합니다.
- **1GHz 결과:** 성능 한계 및 최적화 실험으로 보관하며, SLOW timing failure를 숨기지 않고 원인을 분석합니다.
- **유의:** Genus 합성 단계 PASS는 sign-off STA/CDC/기능 검증을 대체하지 않습니다.

## 5. 제약 및 해석상 주의

- 두 SDC는 기본 `CLK_PERIOD`가 각각 10.0ns와 1.0ns로 설정되며, TCL에서 사전 정의 시 그 값이 우선할 수 있습니다.
- Generated SCLK 정의, FIFO CDC 경로, 입출력 delay의 타당성은 물리 구현 전에 재검토해야 합니다.
- 리포트 헤더의 `Operating conditions` 표기만으로 corner를 판단하지 않고, `08_spi_bridge_top_SYN_analysis_view.rpt`의 실제 timing library 경로를 확인했습니다.
- 보고된 면적은 표준셀 합성 면적이며 실제 floorplan/core area와 다릅니다.

## 6. 원본 근거

- 각 실험의 `REPORT/<frequency>/<corner>/19_spi_bridge_top_SYN_qor.rpt`
- 각 실험의 `REPORT/<frequency>/<corner>/07_ACLK_post_syn_opt.rpt`, `07_SCLK_post_syn_opt.rpt`
- 각 실험의 `REPORT/<frequency>/<corner>/08_spi_bridge_top_SYN_analysis_view.rpt`

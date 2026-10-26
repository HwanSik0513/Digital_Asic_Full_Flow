# SPI Bridge Top — 1GHz / SLOW Synthesis Analysis

> Cadence Genus 합성 리포트 기반 분석. 수치는 합성 단계의 추정치이며 post-route STA 결과가 아닙니다.

## 1. 실험 개요

- **Top module:** `spi_bridge_top`
- **합성 도구:** Genus 22.17-s071_1
- **목표 ACLK:** 1GHz (`1000 ps`)
- **Generated SCLK:** 250MHz (4000 ps) (`divide_by 4`)
- **분석 라이브러리:** `slow_vdd1v0_basicCells.lib`
- **공정 조건 표기:** `PVT_0P9V_125C` (QoR 헤더에 표시됨; 실제 라이브러리 선택은 analysis-view 리포트 참조)
- **합성 타이밍 판정:** **FAIL**

## 2. 핵심 QoR

| 지표 | 측정값 |
|---|---:|
| ACLK Critical Path Slack | -608.2 ps |
| ACLK TNS | -9663.5 ps |
| ACLK Violating Paths | 44 |
| SCLK Critical Path Slack | -90.7 ps |
| SCLK TNS | -678.8 ps |
| SCLK Violating Paths | 8 |
| Total TNS | -10342.3 ps |
| Cell Area | 4579.722 µm² |
| Leaf Cell Count | 1024 |
| Sequential Cells | 343 |
| Combinational Cells | 681 |

## 3. 주요 타이밍 경로

### ACLK — VIOLATED (-608 ps) Late External Delay Assertion at pin o_bus_rdata[4]

- **Startpoint:** `(R) u_rx_fifo/r_wr_ptr_gray_rclk_reg_2/CK`
- **Endpoint:** `(F) o_bus_rdata[4]`
- **Data Path Delay:** 1408 ps
- **Slack:** -608.2 ps

### SCLK — VIOLATED (-91 ps) Setup Check with Pin u_tx_fifo/o_rd_data_reg_6/CK->D

- **Startpoint:** `(R) u_tx_fifo/mem_reg_3_6/CK`
- **Endpoint:** `(F) u_tx_fifo/o_rd_data_reg_6/D`
- **Data Path Delay:** 546 ps
- **Slack:** -90.7 ps

## 4. 결과 해석

- 두 클럭 그룹에서 음수 Slack이 발생했으므로 목표 주파수에서 합성 단계의 setup timing closure를 달성하지 못했습니다.
- ACLK는 RX FIFO 포인터에서 버스 데이터 출력으로 이어지는 경로가 핵심 병목입니다.
- SCLK는 TX FIFO 저장 레지스터에서 읽기 데이터 레지스터로 이어지는 경로가 핵심 병목입니다.

## 5. 검토 사항 및 다음 단계

- `01_check_timing_intent.rpt`와 `06_report_constraint.rpt`에서 제약 적용과 예외 경로를 점검합니다.
- `create_generated_clock`이 실제 SCLK 분주 구조와 일치하는지 확인합니다.
- Async FIFO의 Gray pointer 동기화 및 CDC 경로에 대해 별도의 CDC 검증과 적절한 STA 제약 검토가 필요합니다.
- 타이밍/면적 값은 Genus 합성 추정치이므로 물리 구현 이후 Pre/Post-STA에서 재검증합니다.
- 전력은 별도 activity/조건 확인 없이 이 문서에서 정확한 PPA 수치로 단정하지 않습니다.

## 6. 근거 리포트

- `REPORT/1GHz/SLOW/19_spi_bridge_top_SYN_qor.rpt`
- `REPORT/1GHz/SLOW/07_ACLK_post_syn_opt.rpt`
- `REPORT/1GHz/SLOW/07_SCLK_post_syn_opt.rpt`
- `REPORT/1GHz/SLOW/08_spi_bridge_top_SYN_analysis_view.rpt`
- `REPORT/1GHz/SLOW/09_spi_bridge_top_SYN_area.rpt`
- `CONSTRAINT/1GHz/spi_bridge_top.sdc`

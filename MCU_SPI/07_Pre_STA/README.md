# 07. Pre-layout STA (Genus 타이밍, MMMC)

이번 프로젝트의 pre-layout STA는 **Genus 합성 직후 타이밍 리포트**입니다.
이전 SPI 프로젝트처럼 Tempus로 합성 넷리스트를 따로 돌리지는 않았습니다
(`SYN/tempus_pre_sta.tcl`은 아직 spi_bridge_top용).

## 요약 (클럭은 이상적, 배선은 wire-load 추정)

| 뷰 | 그룹 | WNS | TNS | 위반 |
|---|---|---|---|---|
| FUNC_SS_WORST | ACLK | **+0.0014 ns** | 0 | 0 |
| FUNC_SS_WORST | SCLK | +16.522 ns | 0 | 0 |
| FUNC_FF_BEST | ACLK | +7.455 ns | 0 | 0 |
| FUNC_FF_BEST | SCLK | +17.462 ns | 0 | 0 |

## 리포트

| 파일 | 내용 |
|---|---|
| `20_chip_top_SYN_timing.rpt` | 전체 최악 경로 |
| `20a_..._SS.rpt` / `20b_..._FF.rpt` | 코너별 |
| `21a_..._ACLK.rpt` / `21b_..._SCLK.rpt` | 클럭 그룹별 |
| `21c_..._inputs.rpt` / `21d_..._outputs.rpt` | IO 경로 (SPI / GPIO 패드) |
| `22_..._timing_lint.rpt` | 제약 누락 검사 |
| `syn_opt_time_FUNC_SS_WORST.rpt` / `_FF_BEST.rpt` | opt 단계 |

## 임계 경로

`u_cpu/r_pc_reg_4` → ROM → regfile 읽기 → ALU 주소 → MMIO 디코드 →
`u_register_block/o_tx_fifo_wr_data_reg_4/D` (data path 9.757 ns, slack +1.4 ps).

## Pre vs Post

같은 시작/끝점을 Tempus 사인오프에서 다시 잰 결과는 15_Post_STA `60_pre_vs_post.rpt`에 있습니다.

| | Genus (pre, SS) | Tempus (post, SS) |
|---|---|---|
| Slack | +0.0014 ns | **+1.176 ns** |
| Arrival | ≈ 9.76 ns | 8.961 ns |

- **Insight** — 합성은 area recovery로 여유를 0 근처까지 깎았고, Innovus가 실제 배치에서
  이 경로를 다시 키우고(`FE_OFC*`, `FE_RC*`) 짧은 배선(코어 240 µm) 덕분에 여유가 늘었습니다.
  PnR 후 최악 경로는 다른 경로(PC → RAM write enable, +0.676 ns)로 바뀝니다.

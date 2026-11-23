# 04. Synthesis (Genus 22.17, MMMC)

## 조건

| 항목 | 값 |
|---|---|
| 스크립트 | `scripts/chip_top_45nm_MMMC.tcl` (`run_synthesis_chip`) |
| 뷰 | setup `FUNC_SS_WORST` (slow_vdd1v0 0.9 V 125 °C), hold `FUNC_FF_BEST` (fast_vdd1v0 1.1 V 0 °C) |
| 패드 | `pads_SS_s1vg.lib` / `pads_FF_s1vg.lib`, 패드 인스턴스 `dont_touch` |
| SDC | `scripts/cons/chip_top.sdc` — ACLK 10 ns, SCLK 40 ns, `set_clock_groups -asynchronous`, MOSI 입력 지연 `-clock_fall`, MISO 반주기 경로, ARESETn false path, `set_ideal_network` (클럭/리셋) |
| 계층 보존 | `u_rom`, `u_cpu`: `ungroup_ok false` + 모듈 `boundary_opto false`, 루트 `optimize_constant_*` false |

## 결과 (`reports/19_chip_top_SYN_qor.rpt`)

| 항목 | 값 |
|---|---|
| ACLK setup slack (SS) | **+1.4 ps** (WNS), TNS 0 |
| SCLK setup slack (SS) | +16.522 ns |
| 인스턴스 | 6,775 (순차 2,368 / 조합 4,407) |
| 셀 면적 | 228,584 µm² (패드 14개 포함), **코어 26,984 µm²** |
| 전력 (Genus, 정적 추정) | 5.18 mW, 패드 76.7 % |
| Max fanout | 2,161 (`w_aclk`, CTS 전 이상적 클럭) |

### 블록별 면적 (`reports/09a_chip_top_SYN_area_by_block.rpt`)

| 블록 | 셀 수 | 면적 (µm²) | 코어 대비 |
|---|---|---|---|
| `u_ram` data_ram | 1,802 | 10,494 | 38.9 % |
| `u_cpu/u_rf` regfile | 2,766 | 9,853 | 36.5 % |
| `u_spi` spi_slave_bridge | 727 | 3,128 | 11.6 % |
| `u_cpu/u_alu` alu | 959 | 1,992 | 7.4 % |
| `u_rom` inst_rom | 93 | 194 | 0.7 % |
| `u_cpu/u_cu` sc_cu | 61 | 115 | 0.4 % |

## 임계 경로 (`reports/20a_chip_top_SYN_timing_SS.rpt`)

```
u_cpu/r_pc_reg_4 → u_rom (case ROM) → regfile 32:1 read → ALU 주소 가산
→ MMIO decode → u_register_block/o_tx_fifo_wr_data_reg_4/D        data path 9.757 ns
```

`sw`로 SPI TX_DATA에 쓰는 경로입니다. 싱글 사이클이라 PC → 명령어 → 레지스터 읽기 →
ALU → 메모리/I/O가 한 사이클에 들어갑니다.

## 문제와 해결 (이번 프로젝트)

| 회차 | 증상 | 원인 | 해결 |
|---|---|---|---|
| 1 | regfile이 752셀로 줄어듦, `u_rom/u_cpu not found` 경고 | 계층 이름을 짧은 이름으로 찾음 | `hinst:chip_top/u_core/...` 전체 경로 |
| 2 | regfile 플롭 224개만 남음, `boundary_opto is not a recognized attribute for hinst` | `boundary_opto`는 hinst가 아니라 **module** 속성 | `set_db [get_db $hi .module] .boundary_opto false` + 루트 상수 플롭 최적화 off |
| 3 | **regfile 992 / 992 플롭 보존** | – | 합성 후 자동 검사 스크립트 추가 |

ROM이 고정 펌웨어라 경계 최적화를 허용하면, 펌웨어가 쓰지 않는 레지스터가 상수로 판단되어
지워집니다. 펌웨어를 바꿔도 같은 칩을 쓸 수 있도록 CPU를 펌웨어와 독립적으로 유지했습니다.

**Insight** — 합성 slack +1.4 ps는 "간신히 통과"가 아니라, 타이밍을 맞춘 뒤 area recovery가
남는 여유를 면적으로 바꾼 결과입니다. PnR 후 같은 경로는 +1.176 ns가 됩니다 (15 참고).

## 파일

```
04_Synthesis/
├── README.md
│
├── scripts/
│   ├── chip_top_45nm_MMMC.tcl, run_synthesis_chip, README_chip_top.md
│   └── cons/  chip_top.sdc, chip_top_syn.mmmc.tcl, dont_use_45nm.tcl
│
├── reports/   00_check_design ~ 22_timing_lint, syn_{generic,map,opt}_*, genus_chip_top.log
│
└── results/   chip_top_syn_final.v, chip_top_syn_final.sdc, chip_top_delays.sdf
```

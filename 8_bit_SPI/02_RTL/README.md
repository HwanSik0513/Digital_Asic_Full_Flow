# 02. RTL

Verilog-2001, 합성 가능한 RTL 8개 모듈입니다.

| File | Module | Lines | Role |
|---|---|---|---|
| [Spi_bridge_top.v](RTL/Spi_bridge_top.v) | `spi_bridge_top` | 257 | 최상위. 클럭·리셋 생성, 모듈 연결, busy 2-FF 동기화 |
| [Spi_master.v](RTL/Spi_master.v) | `spi_master` | 199 | 4-state FSM (IDLE / CS_SETUP / SHIFT / DONE), 자동 프레임 송신 |
| [Spi_slave.v](RTL/Spi_slave.v) | `spi_slave` | 307 | 4-state FSM (IDLE / LOAD / RECEIVE / BYTE_DONE), RX FIFO write, TX hold |
| [Async_fifo.v](RTL/Async_fifo.v) | `async_fifo` | 158 | Gray pointer 2-FF 동기화, registered full / empty, level 출력 |
| [Register_block.v](RTL/Register_block.v) | `register_block` | 190 | register map 0x00~0x10, RX prefetch, FIFO_CLEAR drain, overflow sticky |
| [Pulse_sync.v](RTL/Pulse_sync.v) | `pulse_sync` | 62 | toggle FF + 2-FF + edge detect (SCLK → ACLK) |
| [Reset_sync.v](RTL/Reset_sync.v) | `reset_sync` | 39 | async assert / sync release 2-FF |
| [Sclk_gen.v](RTL/Sclk_gen.v) | `sclk_gen` | 40 | ACLK ÷ 4 분주 (toggle phase + o_sclk) |

## Coding rules

- 포트: 입력 `i_`, 출력 `o_` 접두사 (클럭·리셋은 접두사 없음). 모듈 선언 아래 포트 리스트 → 포트 선언 순서.
- 순차 로직은 nonblocking. 리셋은 SCLK 도메인과 FIFO·동기화기가 비동기(`always @(posedge clk or negedge rst_n)`), `register_block`은 동기 리셋(`always @(posedge ACLK)`)입니다.
- 조합 로직은 `always @(*)` + default 할당 (FSM next-state, FIFO next pointer 등).
- FPGA 전용 `BUFG`는 `` `ifdef XILINX_FPGA `` 안에만 있습니다. ASIC 합성·시뮬레이션에서는 정의하지 않으므로 `assign SCLK = w_sclk_raw`가 쓰입니다.

## Notes

- `Sclk_gen.v` 주석의 "ACLK 100MHz / ~25 MHz"는 사양 목표 주파수 기준입니다. 분주비는 항상 ÷ 4입니다.
- 사양서의 열린 CDC 이슈(CDC-01, CDC-02)는 [00_Specification](../00_Specification) 참고.

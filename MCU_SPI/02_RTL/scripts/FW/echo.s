# ============================================================================
# echo.s - MCU system test program (CPU <-> SPI slave bridge <-> GPIO)
#
# Reads a byte received from the external SPI host (RX_DATA), adds 1, and
# sends it back (TX_DATA). Repeats ECHO_N = 8 times, then reports the result
# on GPIO_OUT:  0xA5 = PASS (no RX overflow), 0xEE = FAIL (overflow seen).
#
# Memory map (mcu_core):
#   0x0000_0000 - 0x0000_007C  data RAM (32 words)
#   0x8000_0000 + offset       I/O (addr[31] = 1)
#     0x00 RX_DATA   R  pop one received byte
#     0x04 STATUS    R  [5] TX_FULL [4] OVERFLOW [3] RX_VALID [2] BUSY [1] FULL [0] EMPTY
#     0x08 CONTROL   RW [2] IRQ_EN [1] OVERFLOW_CLEAR [0] FIFO_CLEAR
#     0x0C FIFO_LEVEL R
#     0x10 TX_DATA   RW push one byte to transmit
#     0x20 GPIO_OUT  RW 8-bit output port
# ============================================================================

        lui   $1, 0x8000          # $1 = 0x8000_0000 (I/O base)
        addi  $2, $0, 8           # $2 = ECHO_N
        sw    $0, 32($1)          # GPIO_OUT = 0x00 (running)

loop:
wait_rx:
        lw    $3, 4($1)           # STATUS
        andi  $3, $3, 0x0008      # RX_VALID
        beq   $3, $0, wait_rx
        lw    $4, 0($1)           # RX_DATA (pop)
        addi  $4, $4, 1           # +1
        andi  $4, $4, 0x00ff      # keep 8 bits
wait_tx:
        lw    $3, 4($1)           # STATUS
        andi  $3, $3, 0x0020      # TX_FULL
        bne   $3, $0, wait_tx
        sw    $4, 16($1)          # TX_DATA (push)
        addi  $2, $2, -1
        bne   $2, $0, loop

check:
        lw    $3, 4($1)           # STATUS
        andi  $3, $3, 0x0010      # OVERFLOW
        bne   $3, $0, fail
        addi  $5, $0, 0x00a5      # PASS code
        sw    $5, 32($1)          # GPIO_OUT
        j     done
fail:
        addi  $5, $0, 0x00ee      # FAIL code
        sw    $5, 32($1)
done:   j     done                # halt loop

# ============================================================================
# booktest.s - CPU-only test program
#
# Source: Yamin Li, "Computer Principles and Design in Verilog HDL",
#         Section 5.5 (scinstmem), unchanged from 'main:' on.
#
# Change for ASIC: the book initializes the data memory with an 'initial'
# block (not synthesizable). Here the same four test words are written by
# the program itself ('init:' block) before the original program starts.
#
# Expected result (same as the book): sum = A3 + 27 + 79 + 115 = 0x258,
# stored to RAM byte address 0x60 (word 0x18) and loaded back into $9.
# Covers all 20 instructions of Table 4.4.
# ============================================================================

init:   addi $1, $0, 0xa3         # data[0]
        sw   $1, 0x50($0)
        addi $1, $0, 0x27         # data[1]
        sw   $1, 0x54($0)
        addi $1, $0, 0x79         # data[2]
        sw   $1, 0x58($0)
        addi $1, $0, 0x115        # data[3]
        sw   $1, 0x5c($0)

# ---- original program (book Section 5.5) ----
main:   lui  $1, 0
        ori  $4, $1, 80           # $4 = 0x50, address of data[0]
        addi $5, $0, 4            # 4 items
call:   jal  sum
        sw   $2, 0($4)            # store the sum at 0x60
        lw   $9, 0($4)            # load it back
        sub  $8, $9, $4
        addi $5, $0, 3
loop2:  addi $5, $5, -1
        ori  $8, $5, 0xffff
        xori $8, $8, 0x5555
        addi $9, $0, -1
        andi $10, $9, 0xffff
        or   $6, $10, $9
        xor  $8, $10, $9
        and  $7, $10, $6
        beq  $5, $0, shift
        j    loop2
shift:  addi $5, $0, -1
        sll  $8, $5, 15
        sll  $8, $8, 16
        sra  $8, $8, 16
        srl  $8, $8, 15
finish: j    finish               # halt loop

sum:    add  $8, $0, $0           # $8 = 0
loop:   lw   $9, 0($4)
        addi $4, $4, 4
        add  $8, $8, $9
        addi $5, $5, -1
        bne  $5, $0, loop
        sll  $2, $8, 0            # $2 = sum
        jr   $31

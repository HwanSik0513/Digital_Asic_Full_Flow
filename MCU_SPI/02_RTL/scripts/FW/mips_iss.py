#!/usr/bin/env python3
"""
mips_iss.py - cycle-accurate reference model of the single-cycle CPU
(Yamin Li, Ch.5): one instruction per clock, no delay slot, no overflow trap.
It mirrors the RTL datapath exactly (sext only for addi/lw/sw/beq/bne,
zero-extension for andi/ori/xori/lui, jal writes $31 with PC+4, jr uses rs,
j/jal keep PC+4[31:28]).

Generates the expected-value files used by the self-checking testbench:
  exp_pc.hex     PC at every cycle after reset release (cycle 0 = 0x0)
  exp_regs.hex   final $0..$31
  exp_ram.hex    final data RAM words; never-written words are 'xxxxxxxx'
  exp_params.vh  `define EXP_N_CYCLES <n>
  iss_trace.txt  human-readable per-cycle trace (pc, inst, alu, wb)

Usage:
  python3 mips_iss.py build/prog.hex -o build/prog_exp [--ram-words 32]
         [--max-cycles 2000] [--extra 10]
Simulation stops when the program reaches a 'j <self>' loop; --extra cycles
of that loop are appended to the PC trace.
"""
import argparse
import os
import sys

M32 = 0xFFFFFFFF


def sx16(v):
    return v - 0x10000 if v & 0x8000 else v


def to_s32(v):
    return v - 0x100000000 if v & 0x80000000 else v


def disasm(w):
    op = (w >> 26) & 0x3F
    rs, rt, rd = (w >> 21) & 31, (w >> 16) & 31, (w >> 11) & 31
    sa, fn, imm = (w >> 6) & 31, w & 0x3F, w & 0xFFFF
    if op == 0:
        names = {0x20: 'add', 0x22: 'sub', 0x24: 'and', 0x25: 'or', 0x26: 'xor'}
        if fn in names:
            return "%-4s $%d, $%d, $%d" % (names[fn], rd, rs, rt)
        if fn in (0, 2, 3):
            if w == 0:
                return "nop"
            return "%-4s $%d, $%d, %d" % ({0: 'sll', 2: 'srl', 3: 'sra'}[fn], rd, rt, sa)
        if fn == 8:
            return "jr   $%d" % rs
    names = {0x08: 'addi', 0x0C: 'andi', 0x0D: 'ori', 0x0E: 'xori'}
    if op in names:
        v = sx16(imm) if op == 0x08 else imm
        return "%-4s $%d, $%d, %s" % (names[op], rt, rs, v if op == 0x08 else hex(v))
    if op in (0x23, 0x2B):
        return "%-4s $%d, %d($%d)" % ('lw' if op == 0x23 else 'sw', rt, sx16(imm), rs)
    if op in (0x04, 0x05):
        return "%-4s $%d, $%d, %d" % ('beq' if op == 4 else 'bne', rs, rt, sx16(imm))
    if op == 0x0F:
        return "lui  $%d, 0x%x" % (rt, imm)
    if op in (2, 3):
        return "%-4s 0x%x" % ('j' if op == 2 else 'jal', (w & 0x3FFFFFF) << 2)
    return "??? (%08x)" % w


class Cpu:
    def __init__(self, rom, ram_words):
        self.rom = rom
        self.pc = 0
        self.reg = [0] * 32
        self.ram_words = ram_words
        self.ram = [None] * ram_words          # None = never written
        self.ram_aw = (ram_words - 1).bit_length()

    def fetch(self, pc):
        idx = (pc >> 2)
        return self.rom[idx] if idx < len(self.rom) else 0

    def ram_idx(self, addr):
        return (addr >> 2) & (self.ram_words - 1)

    def step(self):
        """Execute one instruction (one clock). Returns trace info dict."""
        pc = self.pc
        w = self.fetch(pc)
        op = (w >> 26) & 0x3F
        rs, rt, rd = (w >> 21) & 31, (w >> 16) & 31, (w >> 11) & 31
        sa, fn, imm = (w >> 6) & 31, w & 0x3F, w & 0xFFFF
        qa, qb = self.reg[rs], self.reg[rt]
        p4 = (pc + 4) & M32
        npc = p4
        wn, wd, wreg = 0, 0, False
        alu = 0
        mem_w = None

        if op == 0:
            if fn == 0x20:
                alu = (qa + qb) & M32
            elif fn == 0x22:
                alu = (qa - qb) & M32
            elif fn == 0x24:
                alu = qa & qb
            elif fn == 0x25:
                alu = qa | qb
            elif fn == 0x26:
                alu = qa ^ qb
            elif fn == 0x00:
                alu = (qb << sa) & M32
            elif fn == 0x02:
                alu = qb >> sa
            elif fn == 0x03:
                alu = (to_s32(qb) >> sa) & M32
            elif fn == 0x08:
                npc = qa
            if fn in (0x20, 0x22, 0x24, 0x25, 0x26, 0x00, 0x02, 0x03):
                wn, wd, wreg = rd, alu, True
            elif fn != 0x08:
                pass  # undefined R-type: no write (matches RTL: no decode hit)
        elif op == 0x08:                                  # addi (sext)
            alu = (qa + sx16(imm)) & M32
            wn, wd, wreg = rt, alu, True
        elif op == 0x0C:                                  # andi (zext)
            alu = qa & imm
            wn, wd, wreg = rt, alu, True
        elif op == 0x0D:                                  # ori (zext)
            alu = qa | imm
            wn, wd, wreg = rt, alu, True
        elif op == 0x0E:                                  # xori (zext)
            alu = qa ^ imm
            wn, wd, wreg = rt, alu, True
        elif op == 0x23:                                  # lw
            alu = (qa + sx16(imm)) & M32
            v = self.ram[self.ram_idx(alu)]
            if v is None:
                sys.stderr.write("WARNING: lw from never-written RAM word at pc=0x%x addr=0x%x (X in RTL)\n" % (pc, alu))
                v = 0
            wn, wd, wreg = rt, v, True
        elif op == 0x2B:                                  # sw
            alu = (qa + sx16(imm)) & M32
            mem_w = (self.ram_idx(alu), qb)
        elif op in (0x04, 0x05):                          # beq / bne
            alu = qa ^ qb
            z = (alu == 0)
            take = z if op == 0x04 else not z
            if take:
                npc = (p4 + (sx16(imm) << 2)) & M32
        elif op == 0x0F:                                  # lui (zext imm, shifted)
            alu = (imm << 16) & M32
            wn, wd, wreg = rt, alu, True
        elif op == 0x02:                                  # j
            npc = (p4 & 0xF0000000) | ((w & 0x3FFFFFF) << 2)
        elif op == 0x03:                                  # jal
            npc = (p4 & 0xF0000000) | ((w & 0x3FFFFFF) << 2)
            wn, wd, wreg = 31, p4, True
        # else: undefined opcode -> no state change except PC+4 (matches RTL)

        if wreg and wn != 0:
            self.reg[wn] = wd & M32
        if mem_w is not None:
            self.ram[mem_w[0]] = mem_w[1] & M32
        self.pc = npc & M32
        return {'pc': pc, 'inst': w, 'alu': alu, 'wn': wn if wreg else None,
                'wd': wd, 'mem_w': mem_w, 'npc': self.pc}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('hex')
    ap.add_argument('-o', '--out', required=True, help='output prefix (directory/prefix)')
    ap.add_argument('--ram-words', type=int, default=32)
    ap.add_argument('--max-cycles', type=int, default=2000)
    ap.add_argument('--extra', type=int, default=10)
    args = ap.parse_args()

    rom = []
    with open(args.hex) as f:
        for line in f:
            line = line.split('//')[0].strip()
            if line:
                rom.append(int(line, 16))

    cpu = Cpu(rom, args.ram_words)
    pcs, trace = [], []
    halted_at = None
    for cyc in range(args.max_cycles):
        info = cpu.step()
        pcs.append(info['pc'])
        trace.append(info)
        if info['npc'] == info['pc']:            # j <self>
            halted_at = cyc
            break
    if halted_at is None:
        sys.stderr.write("ERROR: no 'j <self>' halt loop within %d cycles\n" % args.max_cycles)
        sys.exit(1)
    for _ in range(args.extra):
        info = cpu.step()
        pcs.append(info['pc'])
        trace.append(info)

    out_dir = os.path.dirname(args.out)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)
    with open(args.out + '_pc.hex', 'w') as f:
        for p in pcs:
            f.write("%08x\n" % p)
    with open(args.out + '_regs.hex', 'w') as f:
        for r in cpu.reg:
            f.write("%08x\n" % r)
    with open(args.out + '_ram.hex', 'w') as f:
        for v in cpu.ram:
            f.write("xxxxxxxx\n" if v is None else "%08x\n" % v)
    with open(args.out + '_params.vh', 'w') as f:
        f.write("// GENERATED by mips_iss.py -- number of cycles in %s_pc.hex\n" % os.path.basename(args.out))
        f.write("`define EXP_N_CYCLES %d\n" % len(pcs))
    with open(args.out + '_trace.txt', 'w') as f:
        f.write("cycle  pc        inst      disasm                    alu       writeback\n")
        for i, t in enumerate(trace):
            wb = ''
            if t['wn'] is not None and t['wn'] != 0:
                wb = "$%d <= %08x" % (t['wn'], t['wd'] & M32)
            if t['mem_w'] is not None:
                wb = "RAM[%d] <= %08x" % (t['mem_w'][0], t['mem_w'][1])
            f.write("%5d  %08x  %08x  %-24s  %08x  %s\n" %
                    (i, t['pc'], t['inst'], disasm(t['inst']), t['alu'] & M32, wb))
    print("ISS: halt loop at cycle %d, %d cycles traced -> %s_{pc,regs,ram}.hex, _params.vh, _trace.txt"
          % (halted_at, len(pcs), args.out))


if __name__ == '__main__':
    main()

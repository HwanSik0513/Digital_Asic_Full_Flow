#!/usr/bin/env python3
"""
mips_asm.py - assembler for the 20 MIPS integer instructions supported by the
single-cycle CPU of Yamin Li, "Computer Principles and Design in Verilog HDL",
Table 4.4 (add sub and or xor sll srl sra jr addi andi ori xori lw sw beq bne
lui j jal) + the pseudo-instruction 'nop'.

Outputs (from one .s source):
  <out>.hex   one 32-bit word per line ($readmemh format)
  <out>.lst   listing: address, machine code, source line
  <out>_rom.v synthesizable case-statement ROM (module inst_rom), optional

Usage:
  python3 mips_asm.py prog.s -o build/prog [--rom-depth 64] [--rom-module inst_rom]

Syntax:
  label:  op  args      # comment
  registers: $0..$31 or names ($zero $at $v0 ... $ra)
  immediates: decimal, -decimal, 0x hex
  lw/sw: rt, offset(rs)
  branch/jump targets: label or absolute byte address
"""
import argparse
import os
import re
import sys

REG_NAMES = {
    'zero': 0, 'at': 1, 'v0': 2, 'v1': 3, 'a0': 4, 'a1': 5, 'a2': 6, 'a3': 7,
    't0': 8, 't1': 9, 't2': 10, 't3': 11, 't4': 12, 't5': 13, 't6': 14, 't7': 15,
    's0': 16, 's1': 17, 's2': 18, 's3': 19, 's4': 20, 's5': 21, 's6': 22, 's7': 23,
    't8': 24, 't9': 25, 'k0': 26, 'k1': 27, 'gp': 28, 'sp': 29, 'fp': 30, 'ra': 31,
}

# R-format: func code
R_FUNC = {'add': 0x20, 'sub': 0x22, 'and': 0x24, 'or': 0x25, 'xor': 0x26,
          'sll': 0x00, 'srl': 0x02, 'sra': 0x03, 'jr': 0x08}
# I/J-format: opcode
I_OP = {'addi': 0x08, 'andi': 0x0C, 'ori': 0x0D, 'xori': 0x0E, 'lw': 0x23,
        'sw': 0x2B, 'beq': 0x04, 'bne': 0x05, 'lui': 0x0F}
J_OP = {'j': 0x02, 'jal': 0x03}


class AsmError(Exception):
    pass


def parse_reg(tok):
    tok = tok.strip()
    if not tok.startswith('$'):
        raise AsmError("expected register, got '%s'" % tok)
    name = tok[1:]
    if name.isdigit():
        n = int(name)
        if 0 <= n <= 31:
            return n
    elif name in REG_NAMES:
        return REG_NAMES[name]
    raise AsmError("bad register '%s'" % tok)


def parse_int(tok):
    tok = tok.strip()
    try:
        return int(tok, 0)
    except ValueError:
        raise AsmError("bad immediate '%s'" % tok)


def check_range(val, lo, hi, what):
    if not (lo <= val <= hi):
        raise AsmError("%s %d out of range [%d, %d]" % (what, val, lo, hi))


def split_args(s):
    return [a.strip() for a in s.split(',')] if s.strip() else []


def first_pass(lines):
    """Collect labels and instruction lines. Returns (insts, labels)."""
    labels = {}
    insts = []          # (addr, mnemonic, args_str, lineno, src)
    addr = 0
    for lineno, raw in enumerate(lines, 1):
        line = raw.split('#', 1)[0].split('//', 1)[0].strip()
        while True:
            m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.*)$', line)
            if not m:
                break
            lab = m.group(1)
            if lab in labels:
                raise AsmError("line %d: duplicate label '%s'" % (lineno, lab))
            labels[lab] = addr
            line = m.group(2).strip()
        if not line:
            continue
        parts = line.split(None, 1)
        mnem = parts[0].lower()
        args = parts[1] if len(parts) > 1 else ''
        insts.append((addr, mnem, args, lineno, raw.rstrip('\n')))
        addr += 4
    return insts, labels


def target_addr(tok, labels):
    tok = tok.strip()
    if tok in labels:
        return labels[tok]
    return parse_int(tok)


def encode(addr, mnem, args, labels):
    a = split_args(args)
    if mnem == 'nop':
        if a:
            raise AsmError("nop takes no operands")
        return 0
    if mnem in R_FUNC:
        f = R_FUNC[mnem]
        if mnem in ('sll', 'srl', 'sra'):
            if len(a) != 3:
                raise AsmError("%s rd, rt, sa" % mnem)
            rd, rt, sa = parse_reg(a[0]), parse_reg(a[1]), parse_int(a[2])
            check_range(sa, 0, 31, 'shift amount')
            return (rt << 16) | (rd << 11) | (sa << 6) | f
        if mnem == 'jr':
            if len(a) != 1:
                raise AsmError("jr rs")
            return (parse_reg(a[0]) << 21) | f
        if len(a) != 3:
            raise AsmError("%s rd, rs, rt" % mnem)
        rd, rs, rt = parse_reg(a[0]), parse_reg(a[1]), parse_reg(a[2])
        return (rs << 21) | (rt << 16) | (rd << 11) | f
    if mnem in I_OP:
        op = I_OP[mnem]
        if mnem in ('lw', 'sw'):
            if len(a) != 2:
                raise AsmError("%s rt, offset(rs)" % mnem)
            rt = parse_reg(a[0])
            m = re.match(r'^(.*)\((.*)\)$', a[1].replace(' ', ''))
            if not m:
                raise AsmError("%s rt, offset(rs)" % mnem)
            off = parse_int(m.group(1)) if m.group(1) else 0
            rs = parse_reg(m.group(2))
            check_range(off, -32768, 32767, 'offset')
            return (op << 26) | (rs << 21) | (rt << 16) | (off & 0xFFFF)
        if mnem in ('beq', 'bne'):
            if len(a) != 3:
                raise AsmError("%s rs, rt, label" % mnem)
            rs, rt = parse_reg(a[0]), parse_reg(a[1])
            tgt = target_addr(a[2], labels)
            diff = tgt - (addr + 4)
            if diff % 4:
                raise AsmError("branch target not word aligned")
            off = diff >> 2
            check_range(off, -32768, 32767, 'branch offset')
            return (op << 26) | (rs << 21) | (rt << 16) | (off & 0xFFFF)
        if mnem == 'lui':
            if len(a) != 2:
                raise AsmError("lui rt, imm")
            rt, imm = parse_reg(a[0]), parse_int(a[1])
            check_range(imm, 0, 0xFFFF, 'lui immediate')
            return (op << 26) | (rt << 16) | imm
        # addi andi ori xori
        if len(a) != 3:
            raise AsmError("%s rt, rs, imm" % mnem)
        rt, rs, imm = parse_reg(a[0]), parse_reg(a[1]), parse_int(a[2])
        if mnem == 'addi':
            check_range(imm, -32768, 32767, 'addi immediate (sign-extended)')
        else:
            # andi/ori/xori zero-extend; accept -1 style only if it fits 16 bits
            check_range(imm, 0, 0xFFFF, '%s immediate (zero-extended)' % mnem)
        return (op << 26) | (rs << 21) | (rt << 16) | (imm & 0xFFFF)
    if mnem in J_OP:
        if len(a) != 1:
            raise AsmError("%s target" % mnem)
        tgt = target_addr(a[0], labels)
        if tgt % 4:
            raise AsmError("jump target not word aligned")
        if (tgt & 0xF0000000) != ((addr + 4) & 0xF0000000):
            raise AsmError("jump target outside current 256 MB region")
        return (J_OP[mnem] << 26) | ((tgt >> 2) & 0x03FFFFFF)
    raise AsmError("unsupported instruction '%s' (only the 20 of Table 4.4 + nop)" % mnem)


def assemble(src_lines):
    insts, labels = first_pass(src_lines)
    words = []
    for addr, mnem, args, lineno, src in insts:
        try:
            w = encode(addr, mnem, args, labels)
        except AsmError as e:
            raise AsmError("line %d: %s\n    %s" % (lineno, e, src.strip()))
        words.append((addr, w, src))
    return words, labels


def write_rom_v(path, words, depth, module, src_name):
    aw = max(1, (depth - 1).bit_length())
    with open(path, 'w') as f:
        f.write("`timescale 1ns / 1ps\n\n")
        f.write("// ============================================================================\n")
        f.write("// %s : instruction ROM, %d x 32 (combinational)\n" % (module, depth))
        f.write("// GENERATED by mips_asm.py from %s -- do not edit by hand.\n" % src_name)
        f.write("// Unused words read as 0x00000000 (= sll $0,$0,0 = nop).\n")
        f.write("// Keep this module as its own hierarchy in synthesis (no boundary\n")
        f.write("// optimization into the CPU), otherwise constant ROM bits would prune\n")
        f.write("// CPU logic for instructions this program does not use.\n")
        f.write("// ============================================================================\n")
        f.write("module %s (\n    // port list\n    i_addr ,\n    o_inst\n);\n\n" % module)
        f.write("// port declaration\n")
        f.write("input  [%d:0] i_addr ; // word address = pc[%d:2]\n" % (aw - 1, aw + 1))
        f.write("output [31:0] o_inst ;\n\n")
        f.write("reg [31:0] o_inst ;\n\n")
        f.write("always @(*) begin\n    case (i_addr)\n")
        for addr, w, src in words:
            idx = addr >> 2
            comment = src.split('#', 1)[0].strip()
            f.write("        %d'd%-3d : o_inst = 32'h%08x ; // (%02x) %s\n" % (aw, idx, w, addr, comment))
        f.write("        default : o_inst = 32'h00000000 ;\n")
        f.write("    endcase\nend\n\nendmodule\n")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('src')
    ap.add_argument('-o', '--out', required=True, help='output prefix (no extension)')
    ap.add_argument('--rom-depth', type=int, default=64)
    ap.add_argument('--rom-module', default='inst_rom')
    ap.add_argument('--no-rom', action='store_true', help='do not write <out>_rom.v')
    args = ap.parse_args()

    with open(args.src) as f:
        lines = f.readlines()
    try:
        words, labels = assemble(lines)
    except AsmError as e:
        sys.stderr.write("ERROR: %s\n" % e)
        sys.exit(1)

    if len(words) > args.rom_depth:
        sys.stderr.write("ERROR: program has %d words, ROM depth is %d\n" % (len(words), args.rom_depth))
        sys.exit(1)

    out_dir = os.path.dirname(args.out)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)

    with open(args.out + '.hex', 'w') as f:
        for _, w, _ in words:
            f.write("%08x\n" % w)
    with open(args.out + '.lst', 'w') as f:
        inv = {}
        for k, v in labels.items():
            inv.setdefault(v, []).append(k)
        for addr, w, src in words:
            f.write("%08x  %08x  %s\n" % (addr, w, src.strip()))
    if not args.no_rom:
        write_rom_v(args.out + '_rom.v', words, args.rom_depth, args.rom_module,
                    os.path.basename(args.src))
    print("assembled %d instructions -> %s.hex / .lst%s" %
          (len(words), args.out, '' if args.no_rom else ' / _rom.v'))


if __name__ == '__main__':
    main()

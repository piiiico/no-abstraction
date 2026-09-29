# Replicates: Qwen3.6-35B-A3B-FP8, one-shot

Same `SPEC.md`, same prompt per program ("write program X in <arm>, one fenced block"), no feedback,
no repair. Three independent generations (g1–g3) per cell, one request each, via the Hetzner
inference rail. Tier 1 only (10 programs), in three arms: C, aarch64 asm and WAT. There is no raw arm.
Graded by the same `run.py` harness as the Opus table. `eval_gens.py` reproduces the numbers from
the generated sources (the sources are not published, see .gitignore).

Harness control: the Opus asm and WAT sources for isqrt were rebuilt through the same `run.py` on
the day, and both built and passed 25/25. So the zeros below come from the generated code, not from
the toolchain.

## Pass counts (all tests green = pass)
| arm | g1 | g2 | g3 | min / median / max | built |
|---|---|---|---|---|---|
| C | 7/10 | 8/10 | 9/10 | 7 / 8 / 9 | 30/30 |
| aarch64 asm | 0/9 | 0/9 | 0/9 | 0 / 0 / 0 | 0/27 |
| WAT | 0/10 | 0/8 | 0/3 | 0 / 0 / 0 | 0/21 |

Denominators below 10 are generations the rail never returned: it timed out or returned 504, which
leaves no file. `lru` in asm is missing in all three generations. WAT g3 is mostly missing. The rail
ran about 1 generation per 3–4 minutes at the start, and dropped to about 1 per 18 minutes on 09-29. A second 25-minute chunk returned nothing (one 504), so the run stopped at 77 of 90 files.

## Failure split
- **C:** every file compiled. The 6 failures are wrong output: jsonget ×2 (g1 9/10 tests, g2 0/10),
  lru ×2 (3/7, 4/7), csvsum (5/7) and b64enc (4/11).
- **asm and WAT:** every failure is a build failure. Not one file reached a test.

What breaks the asm files. Counts are files with at least one error of the class, out of 27. They
are lower bounds, because the stored error text is capped at 1500 characters:
- 21: an immediate where aarch64 needs a register, e.g. `mul x0,x0,#10`, `udiv x3,x0,#10`,
  `strb #10,[x5]`, `eor w10,w10,#0xFFFFFFFF`
- 8: another ISA or assembler dialect: ARM32 `push {…}`, `streq`, `addne`, `.syntax`, `.code`, and
  NASM `.resb`
- 8: w/x register-width mismatch, e.g. `ldrb x8,[x10]`, `mov w3,x0`
- 5: a symbol used as a base register, e.g. `str x9,[int_buf,x4,lsl#3]`, `ldrb w11,[alphabet,w7]`
- 3: initialised data in `.bss`

What breaks the WAT files, out of 21:
- 18: misuse of folded/stack form, e.g. `(br_if $out (i32.lt_s (local.get $i) i32.const 0))`
- 8: an undefined label, function or variable
- 3: pre-2017 syntax (`get_local` / `set_local`)
- 2: imports after definitions

## Reading
For this model the language is a capability wall, not a cost. The C arm works (80% median). In both
low-level arms the model never produces a file its own toolchain accepts. The early read of the
failures was «named memory leaks into asm», based on the single `[int_buf,…]` case. The full run
shows that is a minority mode (5 of 27). The dominant mode is more basic: the model does not hold the
target's instruction set and syntax apart from its neighbours. It writes ARM32 and x86 idioms,
immediates where aarch64 needs registers, and WAT syntax from before 2017. It fails at the layer an
assembler checks, before any semantics.

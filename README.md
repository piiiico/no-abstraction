# Does an agent still need the programming language?

Håkon Åmdal's question to his agent Pico (2026-09-26): *the end result is machine code, so every
abstraction above it should be re-examined.* This repo tests the code side of that claim. Can a model
write working programs with no high-level language: in assembly, in WebAssembly text, or as raw ELF
bytes with no assembler?

Written and run by Pico (an AI agent, Claude Opus 5.5) on 2026-09-27. Everything here is AI-authored.

## Setup
- 13 small programs with a stdin/stdout contract (`SPEC.md`). The tests were written first, from a
  Python reference (`gen_tests.py`, `gen_tests2.py`), before any solution existed.
- Arms: **C** (`gcc -O2`), **aarch64 asm** (`as` + `ld`, no libc, raw syscalls), **WAT** (wabt ->
  wasm, WASI in node), **raw**: the model writes the whole ELF file as hex bytes, with no assembler
  and no tool call between design and file. The model encoded every instruction and computed every
  branch offset in its own reasoning.
- Protocol: all files of an arm were written blind, with nothing compiled or run, then tested once.
  Tier 2 (wordfreq, bigmul, calc) was added after tier 1 hit 100% in every arm.
- Controls: a one-bit change in a raw binary, floor instead of truncating division, a reversed sort
  tie-break, and a dropped carry each turn their cell red (8/25, 0/3, 6/10, 4/9, 5/9).

## Result: Opus 5.5, first attempt, zero repairs
| task | C (gcc -O2) | aarch64 asm | WAT (node) | raw hex ELF |
|---|---|---|---|---|
| csvsum | 7/7 · 70584B · 0.009s | 7/7 · 1904B · 0.008s | 7/7 · 725B · 0.074s | — |
| isqrt | 25/25 · 70496B | 25/25 · 1608B | 25/25 · 429B | 25/25 · 408B |
| b64enc | 11/11 · 70648B · 0.006s | 11/11 · 1864B · 0.008s | 11/11 · 649B · 0.070s | — |
| utf8 | 25/25 · 70616B · 0.010s | 25/25 · 1944B · 0.010s | 25/25 · 593B · 0.072s | — |
| sort | 9/9 · 70640B · 0.086s | 9/9 · 2080B · 0.042s | 9/9 · 999B · 0.145s | — |
| jsonget | 10/10 · 70696B | 10/10 · 2160B | 10/10 · 922B | — |
| lru | 7/7 · 70656B · 0.128s | 7/7 · 2080B · 0.107s | 7/7 · 868B · 0.339s | — |
| wc | 8/8 · 70576B · 0.010s | 8/8 · 1544B · 0.010s | 8/8 · 460B · 0.064s | 8/8 · 416B · 0.009s |
| crc32 | 7/7 · 70600B · 0.013s | 7/7 · 1600B · 0.013s | 7/7 · 464B · 0.069s | 7/7 · 372B · 0.013s |
| floordiv | 3/3 · 70544B | 3/3 · 2040B | 3/3 · 832B | — |
| wordfreq | 9/9 · 71024B · 0.029s | 9/9 · 2600B · 0.023s | 9/9 · 1173B · 0.137s | — |
| bigmul | 9/9 · 70688B · 0.008s | 9/9 · 1760B · 0.010s | 9/9 · 696B · 0.138s | — |
| calc | 10/10 · 70720B · 0.003s | 10/10 · 2016B · 0.002s | 10/10 · 846B · 0.053s | 10/10 · 720B · 0.003s |

Times are for the large perf input (best of 3). WAT times include about 60 ms of node startup.

**Output tokens per program (including reasoning), from the session transcript:**

| | C | asm | WAT | raw |
|---|---|---|---|---|
| tier 1 | 361 | 2,006 | 2,626 | 7,112 |
| tier 2 | 966 | 3,585 | 3,162 | 14,024 |

## Honest limits
- Opus is N=1 per cell, and all cells were written in one context, so they are not independent.
  The weekly quota made extra Opus containers a bad trade on the day. The independent replicates
  come from another model family (below).
- The same model wrote the tests and the programs. The Python reference, a parser cross-check for
  calc, and mutation controls reduce that shared blind spot but do not remove it.
- The programs are small (40–250 instructions). The crossover may sit at larger sizes.

## Replicates: Qwen3.6-35B-A3B (3 independent one-shot generations per cell)
C passes 7, 8 and 9 of 10. aarch64 asm: 0 of 27 files even assemble. WAT: 0 of 21 files even
compile. The dominant error is not semantic. The model mixes up instruction sets and dialects
(immediates where aarch64 needs registers, ARM32 `push`/`streq`, pre-2017 WAT). Details and verbatim
errors are in `QWEN.md`.

## Run it
    npm i wabt@1.0.36 && python3 gen_tests.py && python3 gen_tests2.py
    python3 run.py raw calc      # needs aarch64 Linux; builds the ELF straight from src/raw/calc.hex

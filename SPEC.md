# Ten programs — I/O contract (written BEFORE any solution, 2026-09-27)

Every program reads ALL of stdin and writes stdout. Exit code 0. No arguments.
Arms: C (gcc -O2), aarch64 asm (as+ld, no libc, raw syscalls), WAT (wabt -> wasm, WASI preview1 in node:
must export `memory` and `_start`, may import fd_read/fd_write/proc_exit from `wasi_snapshot_preview1`),
raw bytes (hex of a complete aarch64 ELF, no assembler).

1. csvsum — CSV text; line 1 is a header. Every later non-empty line has >=2 comma-separated fields;
   field 2 is a signed decimal integer (optional leading '-', no '+', no spaces). Lines end '\n' (last may not).
   Empty lines skipped; field 1 may be empty. Print the sum of field 2 (fits int64) + '\n'.
2. isqrt — one unsigned decimal integer 0 <= n <= 2^64-1, optionally followed by '\n'. Print floor(sqrt(n)) + '\n'.
3. b64enc — arbitrary bytes (<= 1 MiB). Print standard base64 (RFC 4648 alphabet, '=' padding, no wrapping) + '\n'.
4. utf8 — arbitrary bytes. Print "valid\n" if strict UTF-8 (no overlongs, no surrogates D800-DFFF, max U+10FFFF,
   no truncated/unexpected continuation bytes), else "invalid\n". Empty input is valid.
5. sort — signed 64-bit decimal integers separated by whitespace (space/\t/\n), up to 200000 of them.
   Print them ascending, one per line. Empty input -> empty output.
6. jsonget — line 1 is a key ([A-Za-z0-9_]+). The rest is ONE flat JSON object: values are strings or integers
   (maybe negative); arbitrary JSON whitespace between tokens. Strings may contain escapes \" \\ \/ \n \t and
   \u00XX with XX < 0x80. Keys contain no escapes. Print the value for the key: string unescaped + '\n', integer
   as written + '\n'. Absent -> "null\n". Duplicate key -> first occurrence.
7. lru — line 1: capacity C (1..1000). Then lines "put K V" or "get K" (K,V integers 0..10^9), up to 100000 ops.
   For each get print the value or -1, one per line. get and put both mark K most-recently-used; put on an
   existing key updates it; put of a new key at capacity evicts the least-recently-used key first.
8. wc — arbitrary bytes. Print "L W B\n": L = number of '\n' bytes, W = number of maximal runs of
   non-whitespace bytes (whitespace = space \t \n \r \v \f), B = byte count.
9. crc32 — arbitrary bytes. Print CRC-32/ISO-HDLC (zlib's crc32) as 8 lowercase hex digits + '\n'.
10. floordiv — lines "a b" (signed 64-bit, single space, each line ends '\n'), up to 1000 lines. Per line print
   "q r" with q = floor(a/b), r = a - q*b (Python semantics); "div0" if b == 0; "overflow" if a = -2^63 and b = -1.

## Tier 2 (added after tier 1 hit 100% in every arm; tests written before any tier-2 solution)
11. wordfreq — arbitrary bytes (<= 4 MiB). A word is a maximal run of ASCII letters [A-Za-z], lowercased.
   Print the 10 most frequent as "count word\n", count descending, ties by word ascending (bytewise).
   Fewer than 10 distinct words -> print all. No words -> empty output.
12. bigmul — two lines, each a non-negative decimal integer of up to 3000 digits (no leading zeros except "0"),
   each line ends '\n'. Print the product without leading zeros + '\n'.
13. calc — one expression per line (lines end '\n'): non-negative integer literals, binary + - * /, unary minus,
   parentheses, spaces anywhere between tokens. Usual precedence (unary minus binds tightest; * / before + -;
   left-associative). / truncates toward zero. Every intermediate value fits in int64; no division by zero.
   Print each result + '\n'.

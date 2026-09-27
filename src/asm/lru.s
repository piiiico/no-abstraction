// lru — capacity <= 1000, linear-scan LRU with timestamps
.global _start
.bss
.align 4
buf:    .skip 16777216
outbuf: .skip 4194304
.align 3
keys:   .skip 8192
vals:   .skip 8192
stamps: .skip 8192
tmp:    .skip 32
.text
_start:
    ldr x19, =buf
    mov x20, #0
rd: mov x0, #0
    add x1, x19, x20
    ldr x2, =16777216
    sub x2, x2, x20
    mov x8, #63
    svc #0
    cmp x0, #0
    b.le rd_done
    add x20, x20, x0
    b rd
rd_done:
    mov x21, #0
    ldr x28, =outbuf
    bl parse_uint
    mov x22, x0                 // cap
    ldr x23, =keys
    ldr x24, =vals
    ldr x25, =stamps
    mov x26, #0                 // count
    mov x27, #0                 // clock
op:
    cmp x21, x20
    b.ge done
    ldrb w0, [x19, x21]
    cmp w0, #32
    b.hi 1f
    add x21, x21, #1
    b op
1:  mov w17, w0                 // 'g' or 'p'
    add x21, x21, #3
    bl parse_uint
    mov x15, x0                 // key
    mov x1, #0                  // search
2:  cmp x1, x26
    b.ge 3f
    ldr x2, [x23, x1, lsl #3]
    cmp x2, x15
    b.eq 3f
    add x1, x1, #1
    b 2b
3:  cmp w17, #'g'
    b.ne put
    cmp x1, x26
    b.ge miss
    add x27, x27, #1
    str x27, [x25, x1, lsl #3]
    ldr x0, [x24, x1, lsl #3]
    bl put_i64
    b nl
miss:
    mov w0, #'-'
    strb w0, [x28], #1
    mov w0, #'1'
    strb w0, [x28], #1
nl: mov w0, #10
    strb w0, [x28], #1
    b op
put:
    mov x16, x1
    bl parse_uint               // value
    mov x1, x16
    cmp x1, x26
    b.lt 6f                     // found: update
    cmp x26, x22
    b.ge 4f
    mov x1, x26                 // append
    add x26, x26, #1
    b 5f
4:  mov x1, #0                  // evict min stamp
    ldr x3, [x25]
    mov x4, #1
41: cmp x4, x26
    b.ge 5f
    ldr x5, [x25, x4, lsl #3]
    cmp x5, x3
    b.hs 42f
    mov x3, x5
    mov x1, x4
42: add x4, x4, #1
    b 41b
5:  str x15, [x23, x1, lsl #3]
6:  str x0, [x24, x1, lsl #3]
    add x27, x27, #1
    str x27, [x25, x1, lsl #3]
    b op
done:
    ldr x1, =outbuf
    sub x2, x28, x1
7:  cbz x2, 8f
    mov x0, #1
    mov x8, #64
    svc #0
    cmp x0, #0
    b.le 8f
    add x1, x1, x0
    sub x2, x2, x0
    b 7b
8:  mov x0, #0
    mov x8, #93
    svc #0

parse_uint:                     // skip non-digits, read digits at x21
    mov x0, #0
    mov x3, #10
1:  cmp x21, x20
    b.ge 3f
    ldrb w2, [x19, x21]
    sub w2, w2, #'0'
    cmp w2, #9
    b.ls 2f
    add x21, x21, #1
    b 1b
2:  cmp x21, x20
    b.ge 3f
    ldrb w2, [x19, x21]
    sub w2, w2, #'0'
    cmp w2, #9
    b.hi 3f
    madd x0, x0, x3, x2
    add x21, x21, #1
    b 2b
3:  ret

put_i64:
    ldr x9, =tmp+24
    mov x10, x9
    cmp x0, #0
    cneg x11, x0, lt
    mov x12, #10
1:  udiv x13, x11, x12
    msub x14, x13, x12, x11
    add w14, w14, #48
    sub x10, x10, #1
    strb w14, [x10]
    mov x11, x13
    cbnz x11, 1b
    cmp x0, #0
    b.ge 2f
    mov w14, #45
    strb w14, [x28], #1
2:  ldrb w14, [x10], #1
    strb w14, [x28], #1
    cmp x10, x9
    b.ne 2b
    ret

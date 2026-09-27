// jsonget — flat JSON object field lookup
.global _start
.data
s_null: .ascii "null\n"
.bss
.align 4
buf:    .skip 16777216
outbuf: .skip 16777216
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
    mov x21, #0                 // key = buf[0..x24)
1:  cmp x21, x20
    b.ge notfound
    ldrb w0, [x19, x21]
    cmp w0, #10
    b.eq 2f
    add x21, x21, #1
    b 1b
2:  mov x24, x21
    add x21, x21, #1
3:  cmp x21, x20                // find '{'
    b.ge notfound
    ldrb w0, [x19, x21]
    add x21, x21, #1
    cmp w0, #'{'
    b.ne 3b
objloop:
    cmp x21, x20
    b.ge notfound
    ldrb w0, [x19, x21]
    cmp w0, #'}'
    b.eq notfound
    cmp w0, #'"'
    b.eq key
    add x21, x21, #1            // whitespace or comma
    b objloop
key:
    add x21, x21, #1
    mov x25, x21                // key start
4:  ldrb w0, [x19, x21]
    cmp w0, #'"'
    b.eq 5f
    add x21, x21, #1
    b 4b
5:  sub x26, x21, x25           // key len
    add x21, x21, #1
    mov x27, #0                 // match flag
    cmp x26, x24
    b.ne 7f
    mov x0, #0
6:  cmp x0, x24
    b.ge 61f
    ldrb w1, [x19, x0]
    add x2, x25, x0
    ldrb w2, [x19, x2]
    cmp w1, w2
    b.ne 7f
    add x0, x0, #1
    b 6b
61: mov x27, #1
7:  ldrb w0, [x19, x21]         // skip ws and ':'
    cmp w0, #'"'
    b.eq strval
    cmp w0, #'-'
    b.eq numval
    sub w1, w0, #'0'
    cmp w1, #9
    b.ls numval
    add x21, x21, #1
    b 7b
numval:
    mov x25, x21
8:  cmp x21, x20
    b.ge 9f
    ldrb w0, [x19, x21]
    cmp w0, #'-'
    b.eq 81f
    sub w1, w0, #'0'
    cmp w1, #9
    b.hi 9f
81: add x21, x21, #1
    b 8b
9:  cbz x27, objloop
    ldr x28, =outbuf
10: cmp x25, x21
    b.ge 11f
    ldrb w0, [x19, x25]
    strb w0, [x28], #1
    add x25, x25, #1
    b 10b
11: b emit
strval:
    add x21, x21, #1
    ldr x28, =outbuf
12: ldrb w0, [x19, x21]
    add x21, x21, #1
    cmp w0, #'"'
    b.eq 20f
    cmp w0, #'\\'
    b.eq 13f
    strb w0, [x28], #1
    b 12b
13: ldrb w0, [x19, x21]
    add x21, x21, #1
    cmp w0, #'n'
    b.ne 14f
    mov w0, #10
    b 19f
14: cmp w0, #'t'
    b.ne 15f
    mov w0, #9
    b 19f
15: cmp w0, #'u'
    b.ne 19f
    mov w3, #0                  // 4 hex digits
    mov x4, #4
16: ldrb w0, [x19, x21]
    add x21, x21, #1
    cmp w0, #'9'
    b.hi 17f
    sub w0, w0, #'0'
    b 18f
17: orr w0, w0, #0x20
    sub w0, w0, #('a' - 10)
18: lsl w3, w3, #4
    orr w3, w3, w0
    subs x4, x4, #1
    b.ne 16b
    mov w0, w3
19: strb w0, [x28], #1
    b 12b
20: cbz x27, objloop
emit:
    mov w0, #10
    strb w0, [x28], #1
    ldr x1, =outbuf
    sub x2, x28, x1
    b write
notfound:
    ldr x1, =s_null
    mov x2, #5
write:
    cbz x2, exit
    mov x0, #1
    mov x8, #64
    svc #0
    cmp x0, #0
    b.le exit
    add x1, x1, x0
    sub x2, x2, x0
    b write
exit:
    mov x0, #0
    mov x8, #93
    svc #0

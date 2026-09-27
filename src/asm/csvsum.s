// csvsum — aarch64 Linux, no libc
.global _start
.bss
.align 4
buf:    .skip 16777216
outbuf: .skip 64
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
    mov x21, #0            // pos
hdr: cmp x21, x20          // skip header line
    b.ge done
    ldrb w0, [x19, x21]
    add x21, x21, #1
    cmp w0, #10
    b.ne hdr
    mov x22, #0            // sum
line:
    cmp x21, x20
    b.ge done
    ldrb w0, [x19, x21]
    cmp w0, #10
    b.ne f1
    add x21, x21, #1       // empty line
    b line
f1: ldrb w0, [x19, x21]    // skip field 1
    add x21, x21, #1
    cmp w0, #','
    b.ne f1
    mov x23, #0            // negative?
    mov x24, #0            // value
    cmp x21, x20
    b.ge addit
    ldrb w0, [x19, x21]
    cmp w0, #'-'
    b.ne dig
    mov x23, #1
    add x21, x21, #1
dig: cmp x21, x20
    b.ge sign
    ldrb w0, [x19, x21]
    sub w0, w0, #'0'
    cmp w0, #9
    b.hi sign
    mov x1, #10
    madd x24, x24, x1, x0
    add x21, x21, #1
    b dig
sign: cbz x23, addit
    neg x24, x24
addit:
    add x22, x22, x24
eol: cmp x21, x20
    b.ge done
    ldrb w0, [x19, x21]
    add x21, x21, #1
    cmp w0, #10
    b.ne eol
    b line
done:
    ldr x28, =outbuf
    mov x0, x22
    bl put_i64
    mov w0, #10
    strb w0, [x28], #1
    bl flush
    mov x0, #0
    mov x8, #93
    svc #0

put_i64:                   // x0 signed -> [x28]
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

flush:
    ldr x1, =outbuf
    sub x2, x28, x1
1:  cbz x2, 2f
    mov x0, #1
    mov x8, #64
    svc #0
    cmp x0, #0
    b.le 2f
    add x1, x1, x0
    sub x2, x2, x0
    b 1b
2:  ret

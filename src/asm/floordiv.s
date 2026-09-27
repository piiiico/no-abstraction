// floordiv — Python-semantics floor division and modulo on i64 pairs
.global _start
.data
s_div0: .ascii "div0\n"
s_ovf:  .ascii "overflow\n"
.bss
.align 4
buf:    .skip 1048576
outbuf: .skip 1048576
tmp:    .skip 32
.text
_start:
    ldr x19, =buf
    mov x20, #0
rd: mov x0, #0
    add x1, x19, x20
    ldr x2, =1048576
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
    mov x26, #1
    lsl x26, x26, #63           // INT64_MIN
line:
    cmp x21, x20                // skip whitespace
    b.ge done
    ldrb w0, [x19, x21]
    cmp w0, #32
    b.hi 1f
    add x21, x21, #1
    b line
1:  bl parse_i64
    mov x22, x0                 // a
    bl parse_i64
    mov x23, x0                 // b
    cbnz x23, 2f
    ldr x1, =s_div0
    mov x2, #5
    bl put_str
    b line
2:  cmp x22, x26
    b.ne 3f
    cmn x23, #1
    b.ne 3f
    ldr x1, =s_ovf
    mov x2, #9
    bl put_str
    b line
3:  sdiv x24, x22, x23          // q (truncated)
    msub x25, x24, x23, x22     // r = a - q*b
    cbz x25, 4f
    eor x0, x25, x23
    tbz x0, #63, 4f             // same sign -> fine
    sub x24, x24, #1
    add x25, x25, x23
4:  mov x0, x24
    bl put_i64
    mov w0, #' '
    strb w0, [x28], #1
    mov x0, x25
    bl put_i64
    mov w0, #10
    strb w0, [x28], #1
    b line
done:
    ldr x1, =outbuf
    sub x2, x28, x1
5:  cbz x2, 6f
    mov x0, #1
    mov x8, #64
    svc #0
    cmp x0, #0
    b.le 6f
    add x1, x1, x0
    sub x2, x2, x0
    b 5b
6:  mov x0, #0
    mov x8, #93
    svc #0

parse_i64:                      // skip spaces, optional '-', digits
    mov x0, #0
    mov x3, #0
    mov x4, #10
1:  ldrb w2, [x19, x21]
    cmp w2, #' '
    b.ne 2f
    add x21, x21, #1
    b 1b
2:  cmp w2, #'-'
    b.ne 3f
    mov x3, #1
    add x21, x21, #1
3:  cmp x21, x20
    b.ge 4f
    ldrb w2, [x19, x21]
    sub w2, w2, #'0'
    cmp w2, #9
    b.hi 4f
    madd x0, x0, x4, x2
    add x21, x21, #1
    b 3b
4:  cbz x3, 5f
    neg x0, x0
5:  ret

put_str:                        // x1 addr, x2 len
    cbz x2, 1f
    ldrb w0, [x1], #1
    strb w0, [x28], #1
    sub x2, x2, #1
    b put_str
1:  ret

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

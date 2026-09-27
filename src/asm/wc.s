// wc — lines words bytes
.global _start
.bss
.align 4
buf:    .skip 65536
outbuf: .skip 128
tmp:    .skip 32
.text
_start:
    ldr x19, =buf
    mov x22, #0                 // lines
    mov x23, #0                 // words
    mov x24, #0                 // bytes
    mov x25, #0                 // in word
chunk:
    mov x0, #0
    mov x1, x19
    mov x2, #65536
    mov x8, #63
    svc #0
    cmp x0, #0
    b.le done
    add x24, x24, x0
    mov x20, x0
    mov x21, #0
1:  cmp x21, x20
    b.ge chunk
    ldrb w0, [x19, x21]
    add x21, x21, #1
    cmp w0, #10
    b.ne 2f
    add x22, x22, #1
2:  cmp w0, #32
    b.eq ws
    sub w1, w0, #9
    cmp w1, #4
    b.ls ws
    cbnz x25, 1b
    mov x25, #1
    add x23, x23, #1
    b 1b
ws: mov x25, #0
    b 1b
done:
    ldr x28, =outbuf
    mov x0, x22
    bl put_u64
    mov w0, #' '
    strb w0, [x28], #1
    mov x0, x23
    bl put_u64
    mov w0, #' '
    strb w0, [x28], #1
    mov x0, x24
    bl put_u64
    mov w0, #10
    strb w0, [x28], #1
    ldr x1, =outbuf
    sub x2, x28, x1
    mov x0, #1
    mov x8, #64
    svc #0
    mov x0, #0
    mov x8, #93
    svc #0

put_u64:
    ldr x9, =tmp+24
    mov x10, x9
    mov x11, x0
    mov x12, #10
1:  udiv x13, x11, x12
    msub x14, x13, x12, x11
    add w14, w14, #48
    sub x10, x10, #1
    strb w14, [x10]
    mov x11, x13
    cbnz x11, 1b
2:  ldrb w14, [x10], #1
    strb w14, [x28], #1
    cmp x10, x9
    b.ne 2b
    ret

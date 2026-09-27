// isqrt — floor(sqrt(n)) for u64, digit-by-digit method
.global _start
.bss
.align 4
buf:    .skip 256
outbuf: .skip 64
tmp:    .skip 32
.text
_start:
    ldr x19, =buf
    mov x20, #0
rd: mov x0, #0
    add x1, x19, x20
    mov x2, #255
    sub x2, x2, x20
    cbz x2, rd_done
    mov x8, #63
    svc #0
    cmp x0, #0
    b.le rd_done
    add x20, x20, x0
    b rd
rd_done:
    mov x21, #0
    mov x22, #0            // n
    mov x1, #10
dig: cmp x21, x20
    b.ge parsed
    ldrb w0, [x19, x21]
    sub w0, w0, #'0'
    cmp w0, #9
    b.hi parsed
    madd x22, x22, x1, x0
    add x21, x21, #1
    b dig
parsed:
    mov x3, #0             // res
    mov x4, #1
    lsl x4, x4, #62        // bit
1:  cmp x4, x22
    b.ls 2f
    lsr x4, x4, #2
    cbnz x4, 1b
2:  cbz x4, fin
    add x5, x3, x4
    cmp x22, x5
    b.lo 3f
    sub x22, x22, x5
    lsr x3, x3, #1
    add x3, x3, x4
    b 4f
3:  lsr x3, x3, #1
4:  lsr x4, x4, #2
    b 2b
fin:
    ldr x28, =outbuf
    mov x0, x3
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

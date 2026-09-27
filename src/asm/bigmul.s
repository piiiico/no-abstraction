// bigmul — schoolbook base-10 multiply, u64 column accumulators, one carry pass
.global _start
.bss
.align 4
buf:    .skip 65536
.align 3
res:    .skip 65536             // u64 columns
outbuf: .skip 16384
.text
_start:
    ldr x19, =buf
    mov x20, #0
rd: mov x0, #0
    add x1, x19, x20
    ldr x2, =65536
    sub x2, x2, x20
    mov x8, #63
    svc #0
    cmp x0, #0
    b.le rd_done
    add x20, x20, x0
    b rd
rd_done:
    mov x21, #0                 // la = length of first digit run
1:  ldrb w0, [x19, x21]
    sub w0, w0, #'0'
    cmp w0, #9
    b.hi 2f
    add x21, x21, #1
    b 1b
2:  add x22, x21, #1            // s2 = start of second number
    mov x23, x22
3:  cmp x23, x20
    b.ge 4f
    ldrb w0, [x19, x23]
    sub w0, w0, #'0'
    cmp w0, #9
    b.hi 4f
    add x23, x23, #1
    b 3b
4:  sub x23, x23, x22           // lb
    ldr x24, =res
    mov x3, #0                  // i
iloop:
    cmp x3, x21
    b.ge carry
    sub x5, x21, #1
    sub x5, x5, x3
    ldrb w5, [x19, x5]
    sub w5, w5, #'0'            // xi
    cbz w5, inext
    mov x4, #0                  // j
    add x6, x22, x23
    sub x6, x6, #1              // index of y's last digit
    add x7, x24, x3, lsl #3     // &res[i]
jloop:
    cmp x4, x23
    b.ge inext
    sub x8, x6, x4
    ldrb w8, [x19, x8]
    sub w8, w8, #'0'
    ldr x9, [x7, x4, lsl #3]
    madd x9, x5, x8, x9
    str x9, [x7, x4, lsl #3]
    add x4, x4, #1
    b jloop
inext:
    add x3, x3, #1
    b iloop
carry:
    add x25, x21, x23           // columns
    mov x3, #0
    mov x10, #0                 // carry
    mov x12, #10
5:  cmp x3, x25
    b.ge top
    ldr x9, [x24, x3, lsl #3]
    add x9, x9, x10
    udiv x10, x9, x12
    msub x11, x10, x12, x9
    str x11, [x24, x3, lsl #3]
    add x3, x3, #1
    b 5b
top:
    sub x3, x25, #1
6:  cmp x3, #0
    b.le 7f
    ldr x9, [x24, x3, lsl #3]
    cbnz x9, 7f
    sub x3, x3, #1
    b 6b
7:  ldr x28, =outbuf
8:  ldr x9, [x24, x3, lsl #3]
    add w9, w9, #'0'
    strb w9, [x28], #1
    subs x3, x3, #1
    b.ge 8b
    mov w9, #10
    strb w9, [x28], #1
    ldr x1, =outbuf
    sub x2, x28, x1
9:  cbz x2, 10f
    mov x0, #1
    mov x8, #64
    svc #0
    cmp x0, #0
    b.le 10f
    add x1, x1, x0
    sub x2, x2, x0
    b 9b
10: mov x0, #0
    mov x8, #93
    svc #0

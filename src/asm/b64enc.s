// b64enc — standard base64, '=' padding, trailing newline
.global _start
.data
alpha: .ascii "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
.bss
.align 4
buf:    .skip 16777216
outbuf: .skip 25165824
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
    ldr x28, =outbuf
    ldr x27, =alpha
    mov x21, #0
full:                       // while pos+3 <= len
    add x0, x21, #3
    cmp x0, x20
    b.hi tail
    ldrb w1, [x19, x21]
    add x2, x21, #1
    ldrb w2, [x19, x2]
    add x3, x21, #2
    ldrb w3, [x19, x3]
    lsl w4, w1, #16
    orr w4, w4, w2, lsl #8
    orr w4, w4, w3
    lsr w5, w4, #18
    and w5, w5, #63
    ldrb w5, [x27, x5]
    strb w5, [x28], #1
    lsr w5, w4, #12
    and w5, w5, #63
    ldrb w5, [x27, x5]
    strb w5, [x28], #1
    lsr w5, w4, #6
    and w5, w5, #63
    ldrb w5, [x27, x5]
    strb w5, [x28], #1
    and w5, w4, #63
    ldrb w5, [x27, x5]
    strb w5, [x28], #1
    add x21, x21, #3
    b full
tail:
    sub x6, x20, x21        // remaining 0,1,2
    cbz x6, nl
    ldrb w1, [x19, x21]
    mov w2, #0
    cmp x6, #2
    b.ne 1f
    add x3, x21, #1
    ldrb w2, [x19, x3]
1:  lsl w4, w1, #16
    orr w4, w4, w2, lsl #8
    lsr w5, w4, #18
    and w5, w5, #63
    ldrb w5, [x27, x5]
    strb w5, [x28], #1
    lsr w5, w4, #12
    and w5, w5, #63
    ldrb w5, [x27, x5]
    strb w5, [x28], #1
    cmp x6, #2
    b.ne 2f
    lsr w5, w4, #6
    and w5, w5, #63
    ldrb w5, [x27, x5]
    strb w5, [x28], #1
    b 3f
2:  mov w5, #'='
    strb w5, [x28], #1
3:  mov w5, #'='
    strb w5, [x28], #1
nl: mov w5, #10
    strb w5, [x28], #1
    ldr x1, =outbuf
    sub x2, x28, x1
wr: cbz x2, out
    mov x0, #1
    mov x8, #64
    svc #0
    cmp x0, #0
    b.le out
    add x1, x1, x0
    sub x2, x2, x0
    b wr
out:
    mov x0, #0
    mov x8, #93
    svc #0

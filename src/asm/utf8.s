// utf8 — strict UTF-8 validation
.global _start
.data
s_valid:   .ascii "valid\n"
s_invalid: .ascii "invalid\n"
.bss
.align 4
buf: .skip 16777216
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
loop:
    cmp x21, x20
    b.ge valid
    ldrb w0, [x19, x21]
    cmp w0, #0x80
    b.hs multi
    add x21, x21, #1
    b loop
multi:
    cmp w0, #0xC2
    b.lo invalid
    cmp w0, #0xE0
    b.lo two
    cmp w0, #0xF0
    b.lo three
    cmp w0, #0xF5
    b.lo four
    b invalid
two:                        // 1 continuation
    mov x22, #1
    mov w3, #0x80
    mov w4, #0xBF
    b check
three:
    mov x22, #2
    mov w3, #0x80
    mov w4, #0xBF
    cmp w0, #0xE0
    b.ne 1f
    mov w3, #0xA0
1:  cmp w0, #0xED
    b.ne check
    mov w4, #0x9F
    b check
four:
    mov x22, #3
    mov w3, #0x80
    mov w4, #0xBF
    cmp w0, #0xF0
    b.ne 1f
    mov w3, #0x90
1:  cmp w0, #0xF4
    b.ne check
    mov w4, #0x8F
check:                      // x22 continuation bytes; first must be in [w3,w4]
    add x5, x21, x22
    cmp x5, x20
    b.ge invalid            // need index x21+x22 < len
    add x21, x21, #1
    ldrb w1, [x19, x21]
    cmp w1, w3
    b.lo invalid
    cmp w1, w4
    b.hi invalid
    add x21, x21, #1
    sub x22, x22, #1
cont:
    cbz x22, loop
    ldrb w1, [x19, x21]
    and w2, w1, #0xC0
    cmp w2, #0x80
    b.ne invalid
    add x21, x21, #1
    sub x22, x22, #1
    b cont
valid:
    ldr x1, =s_valid
    mov x2, #6
    b print
invalid:
    ldr x1, =s_invalid
    mov x2, #8
print:
    mov x0, #1
    mov x8, #64
    svc #0
    mov x0, #0
    mov x8, #93
    svc #0

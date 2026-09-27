// calc — recursive-descent integer expression evaluator on the machine stack
.global _start
.bss
.align 4
buf:    .skip 16777216
outbuf: .skip 4194304
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
line:
    cmp x21, x20
    b.ge done
    ldrb w0, [x19, x21]
    cmp w0, #32
    b.hi 1f
    add x21, x21, #1
    b line
1:  bl expr
    bl put_i64
    mov w0, #10
    strb w0, [x28], #1
2:  cmp x21, x20                // drop the rest of the line
    b.ge done
    ldrb w0, [x19, x21]
    add x21, x21, #1
    cmp w0, #10
    b.ne 2b
    b line
done:
    ldr x1, =outbuf
    sub x2, x28, x1
3:  cbz x2, 4f
    mov x0, #1
    mov x8, #64
    svc #0
    cmp x0, #0
    b.le 4f
    add x1, x1, x0
    sub x2, x2, x0
    b 3b
4:  mov x0, #0
    mov x8, #93
    svc #0

peek:                           // skip spaces; w0 = current char or 0
1:  cmp x21, x20
    b.ge 2f
    ldrb w0, [x19, x21]
    cmp w0, #' '
    b.ne 3f
    add x21, x21, #1
    b 1b
2:  mov w0, #0
3:  ret

expr:
    stp x29, x30, [sp, #-32]!
    stp x22, x23, [sp, #16]
    bl term
    mov x22, x0
1:  bl peek
    cmp w0, #'+'
    b.eq 2f
    cmp w0, #'-'
    b.ne 4f
2:  mov w23, w0
    add x21, x21, #1
    bl term
    cmp w23, #'+'
    b.ne 3f
    add x22, x22, x0
    b 1b
3:  sub x22, x22, x0
    b 1b
4:  mov x0, x22
    ldp x22, x23, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

term:
    stp x29, x30, [sp, #-32]!
    stp x22, x23, [sp, #16]
    bl unary
    mov x22, x0
1:  bl peek
    cmp w0, #'*'
    b.eq 2f
    cmp w0, #'/'
    b.ne 4f
2:  mov w23, w0
    add x21, x21, #1
    bl unary
    cmp w23, #'*'
    b.ne 3f
    mul x22, x22, x0
    b 1b
3:  sdiv x22, x22, x0
    b 1b
4:  mov x0, x22
    ldp x22, x23, [sp, #16]
    ldp x29, x30, [sp], #32
    ret

unary:
    stp x29, x30, [sp, #-16]!
    bl peek
    cmp w0, #'-'
    b.ne 1f
    add x21, x21, #1
    bl unary
    neg x0, x0
    b 9f
1:  cmp w0, #'('
    b.ne 2f
    add x21, x21, #1
    bl expr
    str x0, [sp, #-16]!
    bl peek
    add x21, x21, #1            // ')'
    ldr x0, [sp], #16
    b 9f
2:  mov x0, #0
    mov x3, #10
3:  cmp x21, x20
    b.ge 9f
    ldrb w2, [x19, x21]
    sub w2, w2, #'0'
    cmp w2, #9
    b.hi 9f
    madd x0, x0, x3, x2
    add x21, x21, #1
    b 3b
9:  ldp x29, x30, [sp], #16
    ret

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

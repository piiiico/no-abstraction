// sort — parse signed i64s, LSD radix sort (8 passes x 8 bits) on sign-flipped keys
.global _start
.bss
.align 4
buf:    .skip 16777216
.align 3
arr:    .skip 1703936          // 212992 * 8
arr2:   .skip 1703936
cnt:    .skip 2048             // 256 * 8
outbuf: .skip 8388608
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
    ldr x23, =arr
    mov x24, #0            // count
    mov x21, #0            // pos
    mov x6, #10
next:
    cmp x21, x20           // skip whitespace
    b.ge parsed
    ldrb w0, [x19, x21]
    cmp w0, #32
    b.hi num
    add x21, x21, #1
    b next
num:
    mov x3, #0             // neg
    cmp w0, #'-'
    b.ne 1f
    mov x3, #1
    add x21, x21, #1
1:  mov x4, #0
2:  cmp x21, x20
    b.ge 3f
    ldrb w0, [x19, x21]
    sub w0, w0, #'0'
    cmp w0, #9
    b.hi 3f
    madd x4, x4, x6, x0
    add x21, x21, #1
    b 2b
3:  cbz x3, 4f
    neg x4, x4
4:  eor x4, x4, #0x8000000000000000   // flip sign -> unsigned order
    str x4, [x23, x24, lsl #3]
    add x24, x24, #1
    b next
parsed:
    ldr x25, =arr          // src
    ldr x26, =arr2         // dst
    ldr x27, =cnt
    mov x22, #0            // shift
pass:
    cmp x22, #64
    b.ge sorted
    mov x0, #0             // zero counts
1:  str xzr, [x27, x0, lsl #3]
    add x0, x0, #1
    cmp x0, #256
    b.lt 1b
    mov x0, #0             // histogram
2:  cmp x0, x24
    b.ge 3f
    ldr x1, [x25, x0, lsl #3]
    lsr x1, x1, x22
    and x1, x1, #255
    ldr x2, [x27, x1, lsl #3]
    add x2, x2, #1
    str x2, [x27, x1, lsl #3]
    add x0, x0, #1
    b 2b
3:  mov x0, #0             // exclusive prefix sum
    mov x3, #0
4:  ldr x2, [x27, x0, lsl #3]
    str x3, [x27, x0, lsl #3]
    add x3, x3, x2
    add x0, x0, #1
    cmp x0, #256
    b.lt 4b
    mov x0, #0             // scatter
5:  cmp x0, x24
    b.ge 6f
    ldr x4, [x25, x0, lsl #3]
    lsr x1, x4, x22
    and x1, x1, #255
    ldr x2, [x27, x1, lsl #3]
    str x4, [x26, x2, lsl #3]
    add x2, x2, #1
    str x2, [x27, x1, lsl #3]
    add x0, x0, #1
    b 5b
6:  mov x0, x25            // swap src/dst
    mov x25, x26
    mov x26, x0
    add x22, x22, #8
    b pass
sorted:                    // after 8 passes result is in x25
    ldr x28, =outbuf
    mov x21, #0
7:  cmp x21, x24
    b.ge flush
    ldr x0, [x25, x21, lsl #3]
    eor x0, x0, #0x8000000000000000
    bl put_i64
    mov w0, #10
    strb w0, [x28], #1
    add x21, x21, #1
    b 7b
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
2:  mov x0, #0
    mov x8, #93
    svc #0

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

// wordfreq — FNV-1a open-addressing hash table, then top-10 selection
.global _start
.bss
.align 4
buf:    .skip 16777216
.align 4
table:  .skip 33554432          // 2^21 slots x 16: u32 off, u32 len, u64 count
dist:   .skip 8388608           // slot index per distinct word
outbuf: .skip 16777216
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
    ldr x22, =table
    ldr x23, =dist
    mov x24, #0                 // distinct count
    mov x21, #0                 // pos
scan:
    cmp x21, x20
    b.ge scanned
    ldrb w0, [x19, x21]
    orr w1, w0, #0x20
    sub w2, w1, #'a'
    cmp w2, #25
    b.ls wstart
    add x21, x21, #1
    b scan
wstart:
    mov x25, x21
    ldr x26, =0xcbf29ce484222325
    ldr x27, =0x100000001b3
wl: cmp x21, x20
    b.ge wend
    ldrb w0, [x19, x21]
    orr w1, w0, #0x20
    sub w2, w1, #'a'
    cmp w2, #25
    b.hi wend
    strb w1, [x19, x21]         // lowercase in place
    eor x26, x26, x1
    mul x26, x26, x27
    add x21, x21, #1
    b wl
wend:
    sub x3, x21, x25            // len
    ldr x4, =0x1FFFFF
    and x5, x26, x4
probe:
    add x6, x22, x5, lsl #4
    ldr w7, [x6, #4]
    cbz w7, insert
    cmp x7, x3
    b.ne next
    ldr w8, [x6]
    mov x9, #0
cmpl:
    cmp x9, x3
    b.ge found
    add x10, x8, x9
    ldrb w10, [x19, x10]
    add x11, x25, x9
    ldrb w11, [x19, x11]
    cmp w10, w11
    b.ne next
    add x9, x9, #1
    b cmpl
found:
    ldr x10, [x6, #8]
    add x10, x10, #1
    str x10, [x6, #8]
    b scan
next:
    add x5, x5, #1
    and x5, x5, x4
    b probe
insert:
    str w25, [x6]
    str w3, [x6, #4]
    mov x10, #1
    str x10, [x6, #8]
    str w5, [x23, x24, lsl #2]
    add x24, x24, #1
    b scan

scanned:
    ldr x28, =outbuf
    mov x21, #0                 // k
    mov x15, #10
    cmp x24, x15
    csel x15, x24, x15, lo      // limit = min(nd, 10)
sel:
    cmp x21, x15
    b.ge out
    mov x16, x21                // best
    add x17, x21, #1
selj:
    cmp x17, x24
    b.ge selswap
    ldr w0, [x23, x17, lsl #2]
    ldr w1, [x23, x16, lsl #2]
    bl better
    cbz x0, 1f
    mov x16, x17
1:  add x17, x17, #1
    b selj
selswap:
    ldr w0, [x23, x21, lsl #2]
    ldr w1, [x23, x16, lsl #2]
    str w1, [x23, x21, lsl #2]
    str w0, [x23, x16, lsl #2]
    add x6, x22, x1, lsl #4
    ldr x0, [x6, #8]
    bl put_u64
    mov w0, #' '
    strb w0, [x28], #1
    ldr w7, [x6]
    ldr w8, [x6, #4]
    add x7, x19, x7
2:  cbz x8, 3f
    ldrb w0, [x7], #1
    strb w0, [x28], #1
    sub x8, x8, #1
    b 2b
3:  mov w0, #10
    strb w0, [x28], #1
    add x21, x21, #1
    b sel
out:
    ldr x1, =outbuf
    sub x2, x28, x1
4:  cbz x2, 5f
    mov x0, #1
    mov x8, #64
    svc #0
    cmp x0, #0
    b.le 5f
    add x1, x1, x0
    sub x2, x2, x0
    b 4b
5:  mov x0, #0
    mov x8, #93
    svc #0

better:                         // x0 = 1 if slot x0 ranks before slot x1
    add x2, x22, x0, lsl #4
    add x3, x22, x1, lsl #4
    ldr x4, [x2, #8]
    ldr x5, [x3, #8]
    cmp x4, x5
    b.hi yes
    b.lo no
    ldr w6, [x2]
    ldr w7, [x2, #4]
    ldr w8, [x3]
    ldr w9, [x3, #4]
    mov x10, #0
bl1:
    cmp x10, x7
    b.ge a_end
    cmp x10, x9
    b.ge no
    add x11, x6, x10
    ldrb w11, [x19, x11]
    add x12, x8, x10
    ldrb w12, [x19, x12]
    cmp w11, w12
    b.lo yes
    b.hi no
    add x10, x10, #1
    b bl1
a_end:
    cmp x10, x9
    b.lo yes
no: mov x0, #0
    ret
yes:
    mov x0, #1
    ret

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

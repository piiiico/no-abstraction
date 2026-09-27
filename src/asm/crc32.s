// crc32 — zlib CRC-32, table driven, streaming reads
.global _start
.data
hex: .ascii "0123456789abcdef"
.bss
.align 4
buf:    .skip 65536
table:  .skip 1024
outbuf: .skip 16
.text
_start:
    ldr x19, =buf
    ldr x20, =table
    ldr w9, =0xEDB88320
    mov x0, #0                  // build table
1:  mov w1, w0
    mov x2, #8
2:  tst w1, #1
    lsr w1, w1, #1
    b.eq 3f
    eor w1, w1, w9
3:  subs x2, x2, #1
    b.ne 2b
    str w1, [x20, x0, lsl #2]
    add x0, x0, #1
    cmp x0, #256
    b.lt 1b
    mov w22, #0xFFFFFFFF
chunk:
    mov x0, #0
    mov x1, x19
    mov x2, #65536
    mov x8, #63
    svc #0
    cmp x0, #0
    b.le done
    mov x3, x0
    mov x4, #0
4:  cmp x4, x3
    b.ge chunk
    ldrb w5, [x19, x4]
    eor w6, w22, w5
    and w6, w6, #255
    ldr w7, [x20, x6, lsl #2]
    eor w22, w7, w22, lsr #8
    add x4, x4, #1
    b 4b
done:
    mvn w22, w22
    ldr x28, =outbuf
    ldr x10, =hex
    mov x11, #28
5:  lsr w12, w22, w11
    and w12, w12, #15
    ldrb w12, [x10, x12]
    strb w12, [x28], #1
    subs x11, x11, #4
    b.ge 5b
    mov w12, #10
    strb w12, [x28], #1
    mov x0, #1
    ldr x1, =outbuf
    mov x2, #9
    mov x8, #64
    svc #0
    mov x0, #0
    mov x8, #93
    svc #0

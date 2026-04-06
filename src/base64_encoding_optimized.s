    .data
.org             0x0
buf:             .byte  0

    .data
.org             0x40
b64_map:         .byte  'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

    .data
.org             0x88
input_addr:      .word  0x80
output_addr:     .word  0x84

    .text
.org             0x90
_start:
    movea.l  0x300, A7

    ; A5 - output address
    movea.l  output_addr, A5
    movea.l  (A5), A5

    ; A4 - input address
    movea.l  input_addr, A4
    movea.l  (A4), A4

    ; A3 - buffer address
    movea.l  buf, A3

    ; D7 - buffer size
    move.l   0, D7

read_str_loop:
    cmp.l    0x40, D7                        ; 0x40 = max buffer size
    bge      buf_overflow_exit

    move.b   (A4), (A3, D7)

    cmp.b    0xA, (A3, D7)                   ; 0xA = '\n'
    beq      base64_encoding_init

    add.l    1, D7
    jmp      read_str_loop


base64_encoding_init:
    move.b   0, (A3, D7)

    ; D6 - buffer index
    move.l   0, D6

    ; D5 - encoded buffer size
    move.l   0, D5

base64_encoding_loop:
    move.l   D7, D0
    sub.l    D6, D0                          ; counter of how many bytes left
    ble      exit

    move.l   D5, D1
    add.l    5, D1
    cmp.l    0x40, D1
    bgt      buf_overflow_exit

    move.b   2(A3, D6), D1
    move.l   D1, -(A7)                       ; symbol3
    move.b   1(A3, D6), D1
    move.l   D1, -(A7)                       ; symbol2
    move.b   (A3, D6), D1
    move.l   D1, -(A7)                       ; symbol1
    move.l   D0, -(A7)                       ; counter

    jsr      encode_base64_triple


    move.l   0, (A7)+
    move.l   0, (A7)+
    move.l   0, (A7)+
    move.l   0, (A7)+

    add.l    3, D6
    add.l    4, D5
    jmp      base64_encoding_loop



    ; encode_base64(byte symbol1, byte symbol2, byte symbol3)
    ; takes 3 ASCII symbols
    ; "returns" 4 base64 encoded bytes in D0-D3
encode_base64_triple:
    link     A6, 0
    ; 8(A6) = count, 12(A6) = s1, 16(A6) = s2, 20(A6) = s3

    ; symbol1: s1 >> 2
    move.b   12(A6), D0
    lsr.b    2, D0
    jsr      to_b64_char
    move.b   D0, (A5)

    ; symbol2: (s1 & 0x11) << 4 | (s2 >> 4)
    move.b   12(A6), D0
    lsl.b    6, D0
    lsr.b    2, D0
    move.b   16(A6), D1
    lsr.b    4, D1
    or.b     D1, D0
    jsr      to_b64_char
    move.b   D0, (A5)

    ; check for padding
    move.l   8(A6), D4
    cmp.l    1, D4
    beq      put_pad2

    ; symbol3: (s2 & 0x1111) << 2 | (s3 >> 6)
    move.b   16(A6), D0
    lsl.b    4, D0
    lsr.b    2, D0
    move.b   20(A6), D1
    lsr.b    6, D1
    or.b     D1, D0
    jsr      to_b64_char
    move.b   D0, (A5)

    cmp.l    2, D4
    beq      put_pad1

    ; symbol4: s3 & 0x111111
    move.b   20(A6), D0
    jsr      to_b64_char
    move.b   D0, (A5)
    jmp      encode_triple_return

put_pad2:
    move.b   0x3D, (A5)                      ; 0x3D = '='
put_pad1:
    move.b   0x3D, (A5)

encode_triple_return:
    unlk     A6
    rts


    ; encode_base64()
    ; takes 6 bits of symbol in D0
    ; "returns" corresponding symbol in ASCII of these 6 bits of base64 encoding in D0
to_b64_char:
    link     A6, 0
    and.l    0x3F, D0                        ; take only 6 bits
    movea.l  b64_map, A0                     ; b64_map address
    move.b   (A0, D0), D0                    ; map b64 symbol to ASCII
    unlk     A6
    rts


buf_overflow_exit:
    move.l   0xCCCCCCCC, (A5)

exit:
    halt

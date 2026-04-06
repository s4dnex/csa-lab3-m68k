    .data
buf:             .byte  0

    .data
.org             0x42
buf_size:        .word  0x40
input_addr:      .word  0x80
output_addr:     .word  0x84

    .data
.org             0x88
encoded_buf:     .byte  0

    .text
    .org     0xE0
_start:
    movea.l  0x1000, A7

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
    move.b   (A4), (A3, D7)

    add.l    1, D7
    cmp.l    0x40, D7
    bgt      buf_overflow_exit

    cmp.b    0xA, -1(A3, D7)
    bne      read_str_loop

    sub.l    1, D7
    move.b   0, (A3, D7)


base64_encoding_init:
    ; ; A1 - index to traverse buffer
    ; movea.l  0, A1

    ; ; A2 - encoded buffer pointer to last char
    ; movea.l encoded_buf, A2

    ; ; D7 - encoded buffer length
    ; movea.l 0, D6

    ; A2 - encoded buffer address
    movea.l  encoded_buf, A2

    ; D6 - buffer index
    move.l   0, D6

    ; D5 - encoded buffer size
    move.l   0, D5


base64_encoding_loop:
    cmp.l    D6, D7
    ble      print_str

    move.b   (A3, D6), -(A7)
    move.b   1(A3, D6), -(A7)
    move.b   2(A3, D6), -(A7)
    add.l    3, D6

    jsr      encode_base64_triple
    move.b   0, (A7)+
    move.b   0, (A7)+

    move.b   0, (A7)+


    move.b   D0, (A2, D5)
    move.b   D1, 1(A2, D5)
    move.b   D2, 2(A2, D5)
    move.b   D3, 3(A2, D5)
    add.l    4, D5

    jmp      base64_encoding_loop

    ; encode_base64(byte symbol1, byte symbol2, byte symbol3)
    ; takes 3 ASCII symbols and encodes them as base64
    ; "returns" 4 base64 encoded bytes in D0-D3
encode_base64_triple:
    link     A6, 3

    move.b   7(A6), D0
    lsr.b    2, D0
    move.b   D0, -(A7)
    jsr      encode_base64
    move.b   D0, -3(A6)
    move.b   0, (A7)+

    move.b   7(A6), D0
    lsl.b    6, D0
    lsr.b    2, D0
    move.b   6(A6), D1
    lsr.b    4, D1
    or.b     D1, D0
    move.b   D0, -(A7)
    jsr      encode_base64
    move.b   D0, -2(A6)
    move.b   0, (A7)+

    move.b   6(A6), D0
    lsl.b    4, D0
    lsr.b    2, D0
    move.b   5(A6), D1
    lsr.b    6, D1
    or.b     D1, D0
    move.b   D0, -(A7)
    jsr      encode_base64
    move.b   D0, -1(A6)
    move.b   0, (A7)+

    move.b   5(A6), -(A7)
    jsr      encode_base64

    move.b   D0, D3
    move.b   -1(A6), D2
    move.b   -2(A6), D1
    move.b   -3(A6), D0

    unlk     A6
    rts

    ; encode_base64(byte symbol)
    ; takes 6 bits of given parameter
    ; "returns" corresponding symbol in ASCII of these 6 bits base64 encoding in D0
encode_base64:
    link     A6, 1

    move.b   1(A6), D0
    and.b    0x3F, D0

    ; 0 - 25 = A - Z
    cmp.b    25, D0
    bgt      if_lower_letter
    add.b    0x41, D0
    jmp      encode_base64_return

    ; 26 - 51 = a - z
if_lower_letter:
    cmp.b    51, D0
    bgt      if_digit
    sub.b    26, D0
    add.b    0x61, D0
    jmp      encode_base64_return

    ; 52 - 61 = 0 - 9
if_digit:
    cmp.b    61, D0
    bgt      if_plus
    sub.b    52, D0
    add.b    0x30, D0
    jmp      encode_base64_return

    ; 62 = +
if_plus:
    cmp.b    62, D0
    bne      if_slash
    move.b   0x2B, D0
    jmp      encode_base64_return

    ; 63 = /
if_slash:
    move.b   0x2F, D0

encode_base64_return:
    unlk     A6
    rts


print_str:
    ; D6 - encoded buffer index
    move.l   0, D6

print_str_loop:
    cmp.l    D5, D6
    bge      exit

    move.b   (A2, D6), (A5)
    add.l    1, D6

    jmp      print_str_loop

buf_overflow_exit:
    move.l   0xCCCCCCCC, (A5)

exit:
    halt

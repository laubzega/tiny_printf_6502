        .import pushax, _write

        .export _main
        .export output_char
        .export buf_idx

_TINYPRINTF_PRESERVE_REGS = 1
        .include "../tiny_printf.i"

MODE_BUFFER = $00
MODE_SCREEN = $80

        .segment "ZEROPAGE"
tmp:    .word 0

        .segment "DATA"
ptr:     .word 0
str_test: .asciiz "test"
str_bye: .asciiz "Bye!"
char_m: .byte "M"
char_h: .byte "H"
char_l: .byte "L"
hex_03: .byte $03
hex_4f: .byte $4f
hex_dead: .word $dead
hex_f00bad: .byte $ad, $0b, $f0
hex_deadbabe: .dword $deadbabe
hex_fe: .byte $fe
hex_dc: .byte $dc
hex_ba: .byte $ba
hex_98: .byte $98
hex_76: .byte $76
hex_54: .byte $54
hex_32: .byte $32
hex_10: .byte $10
just_0: .byte 0
dec_37: .byte 37
dec_115: .word 115
dec_256: .word 256
dec_1928: .word 1928
dec_15000: .word 15000
dec_16777215: .byte 255, 255, 255
dec_65536: .dword 65536
dec_2000555919: .dword 2000555919


.macro TEST expected, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15
        .pushseg
        .segment "RODATA"
        .local @gold
@gold:
        .asciiz expected

        .segment "CODE"
        pha
        txa
        pha
        tya
        pha
        jsr prepare_test
        pla
        tay
        pla
        tax
        pla

        printq r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15
        ldx buf_idx
        lda #0
        sta test_buffer,x

        lda #<@gold
        ldx #>@gold
        jsr compare
        .popseg
.endmacro

        .segment "DATA"
counter: .byte 0
failed: .byte 0
print_mode: .byte 0
reg_A:  .byte 0
buf_idx: .byte 0
char_buf:
        .byte 0
test_buffer:
        .res 256, 0

 
        .segment "CODE"
_main:
        TEST "Simple test", "Simple %s", str_test
        TEST "Double testtest", "Double %s%s", str_test, str_test
        TEST "c:M/c:H/c:L", "c:%c/c:%c/c:%c", char_m, char_h, char_l

        TEST "0", "%x", just_0
        TEST "0", "%01x", just_0
        TEST "0", "%01X", just_0
        TEST "3", "%x", hex_03
        TEST "4f", "%x", hex_4f
        TEST "dead", "%lx", hex_dead
        TEST "f00bad", "%llx", hex_f00bad
        TEST "deadbabe", "%lllx", hex_deadbabe
        TEST "fedcba9876543210", "%x%x%x%x%x%x%x%x", hex_fe, hex_dc, hex_ba, hex_98, hex_76, hex_54, hex_32, hex_10
        TEST "FEDCBA9876543210", "%X%X%X%X%X%X%X%X", hex_fe, hex_dc, hex_ba, hex_98, hex_76, hex_54, hex_32, hex_10
        TEST "00DEAD", "%06lX", hex_dead
        TEST "   4f", "%5x", hex_4f
        TEST "0DEADBABE", "%09lllX", hex_deadbabe

        TEST "01001111", "%b", hex_4f
        TEST "0100_1111", "%_b", hex_4f
        TEST "0101010011111110", "%b%b", hex_54, hex_fe
        TEST "1101111010101101", "%lb", hex_dead
        TEST "1101_1110_1010_1101", "%_lb", hex_dead
        TEST "111100000000101110101101", "%llb", hex_f00bad
        TEST "1111_0000_0000_1011_1010_1101", "%_llb", hex_f00bad
        TEST "11011110101011011011101010111110", "%lllb", hex_deadbabe
        TEST "1101_1110_1010_1101_1011_1010_1011_1110", "%_lllb", hex_deadbabe

        TEST "ESCAPED", "\x45\x53\x43\x41\x50\x45\x44"
        TEST "%\\n", "\%\\\\n"

        TEST "0", "%d", just_0
        TEST "37", "%d", dec_37
        TEST "115", "%ld", dec_115
        TEST "256", "%ld", dec_256
        TEST "1928", "%ld", dec_1928
        TEST "15000","%ld", dec_15000
        TEST "16777215", "%lld", dec_16777215
        TEST "65536", "%llld", dec_65536
        TEST "2000555919", "%llld", dec_2000555919
        TEST "   115", "%6ld", dec_115
        TEST "015000","%06ld", dec_15000
        TEST "000065536", "%09llld", dec_65536

        lda #$12
        ldx #$34
        ldy #$56
        TEST "123456", "%02x%02x%02x", ^A, ^X, ^Y

        lda #<str_test
        sta ptr
        lda #>str_test
        sta ptr + 1
        TEST "xtestx", "x%psx", ptr 

        TEST "val1=$00f00bad, val2=%01001111, val3=  15000", "val1=\$%08llx, val2=\%%b, val3=%7ld", hex_f00bad, hex_4f, dec_15000
        TEST "first M0testDEAD370100_1111115", "first %c%x%s%lX%d%_b%ld", char_m, just_0, str_test, hex_dead, dec_37, hex_4f, dec_115

        lda #<hex_dead
        sta ptr
        lda #>hex_dead
        sta ptr + 1
        lda #$00
        ldx #$91
        TEST "091:e00DEAD:0", "%03X:\x65%06plX:%x", ^X, ptr, ^A

        lda #<str_bye
        ldx #>str_bye
        TEST "Bye! Bye!", "%s %s", str_bye, ^XA

        ; some negative tests
        TEST "ERR", "%llllx", hex_deadbabe
        TEST "ERR", "%lllllx", hex_deadbabe
        TEST "ERR", "%n", dec_37
        TEST "ERR", "%ln", dec_37
        TEST "ERR", "%0ln", dec_37
        TEST "ERR", "\x1g"
        TEST "AERR", "\x41\x1g\x42"

        ; tests complete
        lda #MODE_SCREEN
        sta print_mode

        lda failed
        beq @all_ok
        printq "\n%d out of %d tests FAILED\n", failed, counter
        lda #1
        rts
@all_ok:
        printq "All %d tests PASS!\n", counter
        lda #0
        rts


prepare_test:
        lda #MODE_BUFFER
        sta print_mode
        inc counter

        ldy #0
        lda #$ff
@loop:
        sta test_buffer,y
        dey
        bne @loop
        rts

compare:
        sta tmp
        stx tmp + 1

        ldy #0
@loop:
        lda test_buffer,y
        beq @eol
        cmp (tmp),y
        bne @fail
        iny
        bne @loop
        beq @fail   ; too long
@eol:
        cmp (tmp),y
        bne @fail

        rts
@fail:
        lda #MODE_SCREEN
        sta print_mode

        lda tmp
        sta ptr
        lda tmp + 1
        sta ptr + 1
        printq "* Test %d failed.\n", counter
        printq "Expected:\n%ps\n", ptr
        printq "Actual:\n%s\n", test_buffer
        inc failed
        rts
        
output_char:
        bit print_mode
        bpl @test
        jmp CHROUT
@test:
        sta reg_A
        txa
        pha

        lda reg_A
        ldx buf_idx
        sta test_buffer,x
        inc buf_idx 
        pla
        tax
        lda reg_A
        rts

CHROUT:
        sta char_buf
        pha
        txa
        pha
        tya
        pha

        lda #1
        ldx #0
        jsr pushax
        lda #<char_buf
        ldx #>char_buf
        jsr pushax
        lda #1
        ldx #0
        jsr _write

        pla
        tay
        pla
        tax
        pla
        rts

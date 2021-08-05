_TINYPRINTF_PRESERVE_REGS = 1
;JUST_THE_LIB = 1
        .include "tiny_printf.i"

        .segment "DATA"
.ifndef JUST_THE_LIB
char1: .byte "M"
char2: .byte "H"
char3: .byte "L"
start: .word $dead
value: .word $f00d, $0bad
decim: .dbyt 2043
string: .asciiz "Atari 800XL rulez!"
binary: .byte %10111010, %01101101
time:  .dword .time
ptr:     .word string
.endif


        .segment "CODE"
.ifndef JUST_THE_LIB
        lda #23     ; upper/lower case
        sta 53272

        ldx #0
@loop:
        inc $d020
;        printf "\n\n"
;        printf "var(\%X)=$%X var(\%lX)=$%lX\n", value, value
;        printf "var(\%x)=$%x var(\%lx)=$%lx\n", value, value
;        printf "var(\%llx)=$%llx var(\%lllx)=$%lllx\n", value, value
;        printf "var(\%d)=%d var(\%ld)=%ld\n", decim, decim
;        printf "var(\%0d)=%0d var(\%0ld)=%0ld\n", decim, decim
;        printf "var(\%s)=%s\n", string
;        printf "var(\%c\%c\%c)=%c%c%c\n", char1, char2, char3
;        printf "var(\%b)=\%%b\n", binary
;        printf "var(\%0_lb)=\%%0_lb\n", binary
;        printf "var(\%ps)=%ps\n", ptr
;
;        ldx #$10
;        printf "X(\%x)=$%x\n", _X
;        ldx #$BA
;        ldy #$CA
;        printf "XY(\%X\%x)=$%X%x\n", _XY
;
;        lda #<start
;        ldx #>start
;        printf "pAX(\%x)=$%x\n", pAX
;        ldy #<start
;        ldx #>start
;        printf "pYX(\%lx)=$%lx\n", pYX

        ;printf "Register \x41\x42\x4a\x4b\x4c\x4d\x4e\x4f\x30\x35\x39 X = $%d\n", _X
        printf "Register \x4a\x4A", _X
        inx
;        bne @loop
.endif
        rts

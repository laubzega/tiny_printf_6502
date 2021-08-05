_TINYPRINTF_PRESERVE_REGS = 1
;JUST_THE_LIB = 1
        .include "../tiny_printf.i"

        .segment "DATA"
.ifndef JUST_THE_LIB
char1: .byte "M"
char2: .byte "H"
char3: .byte "L"
start: .word $dead
value: .word $f00d, $0bad
decim: .dbyt 2043
string: .asciiz "Example string!"
binary: .byte %10111010, %01101101
time:  .dword .time
ptr:     .word string
deci0: .word $0
deci1: .word $5
deci2: .word $55
deci25: .word $99
deci3: .word $555
deci4: .word $5555
.endif


        .segment "CODE"

.ifndef JUST_THE_LIB
        lda #23     ; upper/lower case
        sta 53272

        printf "Start\n\n"
        printf "var(\%3d)=%3d       ", value
        printf "var(\%3ld)=%3ld\n", value
        printf "var(\%8d)=%8d  ", value
        printf "var(\%8ld)=%8ld\n", value
        printf "var(\%X)=$%X var(\%lX)=$%lX\n", value, value
        printf "var(\%x)=$%x var(\%lx)=$%lx\n", value, value
        printf "var(\%llx)=$%llx var(\%lllx)=$%lllx\n", value, value
        printf "var(\%d)=%d var(\%ld)=%ld\n", decim, decim
        printf "var(\%0d)=%0d var(\%0ld)=%0ld\n", decim, decim
        printf "var(\%06d)=%06d var(\%06ld)=%06ld\n", decim, decim
        printf "var(\%s)=%s\n", string
        printf "var(\%c\%c\%c)=%c%c%c\n", char1, char2, char3
        printf "var(\%b)=\%%b\n", binary
        printf "var(\%_lb)=\%%_lb\n", binary
        printf "var(\%ps)=%ps\n", ptr
        printf "\\x45\\x53\\x43\\x41\\x50\\x45\\x44 = \x45\x53\x43\x41\x50\x45\x44\n"
.ifdef __CBM__
        printf "\n(The \\ above is a backslash that's sadly missing from C64's charset)\n\n"
.endif
        ldx #$10
        printf "X(\%x)=$%x       ", ^X
        printf "S(\%b)=\%%b\n", ^S
        printf "PC(\%04lx)=$%04lx ", ^PC
        ldx #$BA
        ldy #$CA
        printf "XY(\%X\%x)=$%X%x\n", ^X, ^Y

        lda #<start
        ldx #>start
        printf "pAX(\%x)=$%x     ", ^XA
        ldy #<start
        ldx #>start
        printf "pYX(\%lx)=$%lx\n", ^XY
        printf "PC(\%04lx)=$%04lx\n", ^PC
.endif

        rts

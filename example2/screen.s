_TINYPRINTF_PRESERVE_REGS = 1
        .include "../tiny_printf.i"

        .segment "CODE"
        lda #23     ; upper/lower case
        sta 53272

        ldx #0
@loop:
        inc $d020
        printf "Register X=$%02X", ^X
        inx
        bne @loop
        rts

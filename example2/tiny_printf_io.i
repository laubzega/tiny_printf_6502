.macro PRINTF_INIT
        lda #0
        sta scr_idx

        ldx #39
        lda #$20
@clean:
        sta $0400,x
        dex
        bpl @clean
.endmacro

.macro PRINTF_OUTPUT_CHAR char
        jsr output_screen
.endmacro

        .segment "CODE"
output_screen:
        sta tmp
        txa
        pha

        lda tmp
        lsr
        lsr
        lsr
        lsr
        lsr
        tax
        lda petscii2scr,x
        eor tmp
        ldx scr_idx
        sta $0400,x
        inc scr_idx 

        pla
        tax
        lda tmp
        rts

        .segment "DATA"
petscii2scr:
        .byte $80, $00, $40, $20, $40, $c0, $80, $80
tmp:    .byte 0
scr_idx: .byte 0


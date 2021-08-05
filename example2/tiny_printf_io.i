.macro PRINTF_OUTPUT_CHAR char
        jsr output_screen
.endmacro

        .segment "CODE"
output_screen:
        sta tmp
        cmp #$0d
        beq @cr
        cmp #$0a
        bne @not_cr
@cr:
        lda #0
        sta scr_idx
        rts
@not_cr:
        txa
        pha

        lda scr_idx
        bne @not_starting
        ldx #39
        lda #$20
@clean:
        sta $0400,x
        dex
        bne @clean  ; no need to clean the first char

@not_starting:
        lda tmp
        lsr
        lsr
        lsr
        lsr
        lsr
        tax
        lda petscii2scr,x
        clc
        adc tmp        ; change to EOR
        ldx scr_idx
        sta $0400,x
        inc scr_idx 
        pla
        tax
        lda tmp
        rts

        .segment "DATA"
petscii2scr:
        .byte $80, $00, $c0, $e0, $40, $c0, $80, $80
        .byte $80, $00, $40, $20, $40, $c0, $80, $80
tmp:    .byte 0
scr_idx: .byte 0


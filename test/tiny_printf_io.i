        .import output_char
        .import buf_idx

.macro PRINTF_OUTPUT_CHAR char
        jsr output_char
.endmacro

.macro PRINTF_INIT
        lda #0
        sta buf_idx
.endmacro



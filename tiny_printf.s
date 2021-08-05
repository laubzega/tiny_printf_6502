
        .export _printf
        .export _printf_register_a
        .export _printf_register_x
        .export _printf_register_y
        .export _printf_register_pc
        .export _printf_register_s

        .include "tiny_printf_io.i"

_TINYPRINTF_PRESERVE_REGS = 1
_TINYPRINTF_SUPPORT_ESCAPED_HEX_LITERALS = 1
_TINYPRINTF_SUPPORT_LEADING_ZEROS = 1
_TINYPRINTF_SUPPORT_ARG_DECIMAL = 1
_TINYPRINTF_SUPPORT_ARG_BINARY = 1
_TINYPRINTF_SUPPORT_ARG_HEX = 1
_TINYPRINTF_SUPPORT_ARG_STRING = 1
_TINYPRINTF_SUPPORT_ARG_CHAR = 1
_TINYPRINTF_SUPPORT_ARG_PTR = 1


_PRINTF_MODE_NORMAL = 0
_PRINTF_MODE_BACKSPACE = 1
_PRINTF_MODE_PERCENT = 2

_PRINTF_SPACE_BIT = $80
.ifdef __C64__
        .segment "DATA"
.else
        .segment "ZEROPAGE"
.endif
_printf_width:      .res 1
_printf_str_idx:    .res 1
_printf_arg_idx:    .res 1
_printf_register_a: .res 1
_printf_register_x: .res 1
_printf_register_y: .res 1
_printf_register_pc: .res 2
_printf_register_s: .res 1
_printf_mode:       .res 1
.ifdef _TINYPRINTF_SUPPORT_LEADING_ZEROS
_printf_total_places: .res 1
.endif
_printf_zero_marker: .res 1
.ifdef _TINYPRINTF_SUPPORT_ARG_HEX
_printf_case:       .res 1
.endif
_printf_leading_zeros:  .res 1
_printf_underscores:    .res 1
.ifdef _TINYPRINTF_SUPPORT_ARG_PTR
_printf_pointer:    .res 1
.endif
_printf_tmp:    .res 1
.ifdef _TINYPRINTF_SUPPORT_ARG_DECIMAL
_printf_bin:        .res 4
_printf_bcd:        .res 5
.endif

_printf_str = 250
_printf_args = 252
_printf_src = 254


        .segment "DATA"
_printf:
        sta _printf_str
        stx _printf_str + 1

        ; preserve caller's PC in case it needs to be printed out later
        tsx
        lda $101,x
        sta _printf_register_pc
        lda $102,x
        sta _printf_register_pc + 1

.if .definedmacro(PRINTF_INIT)
        PRINTF_INIT
.endif
.ifdef _TINYPRINTF_PRESERVE_REGS
        tya
        pha
.endif

        ldy #_PRINTF_MODE_NORMAL
        sty _printf_mode
        ; compute the start of argument data
        lda (_printf_str),y
        clc
        adc _printf_str
        sta _printf_args
        lda #0
        adc _printf_str + 1
        sta _printf_args + 1

        sty _printf_arg_idx

inc_string_loop:
        iny
        
@string_loop:
        lda (_printf_str),y
        bne not_end
_printf_exit:
.ifdef _TINYPRINTF_PRESERVE_REGS
        pla
        tay
.endif
        rts

not_end:
.ifdef _TINYPRINTF_SUPPORT_LEADING_ZEROS
        bit _printf_leading_zeros
        bpl @not_zero_count
        ldx #0
        stx _printf_leading_zeros

        jsr if_digit_set_total_places
        bcc @not_zero_count

        jmp inc_string_loop     ; always taken

;@not_a_digit:
;        jmp error
.endif

@not_zero_count:
        ldx _printf_mode
        cpx #_PRINTF_MODE_BACKSPACE
        bne @not_mode_backspace
        jmp @mode_backspace
@not_mode_backspace:
        cmp #'\'
        bne @not_backspace
        jmp @backspace
@not_backspace:

        cmp #'%'
        bne @not_percent
        jmp @percent
@not_percent:

        ldx _printf_mode
        cpx #_PRINTF_MODE_NORMAL
        bne @mode_not_normal
        jmp @not_newline
@mode_not_normal:

        cpx #_PRINTF_MODE_PERCENT
        beq @mode_percent
        jmp error
@mode_percent:

.ifdef _TINYPRINTF_SUPPORT_ARG_PTR
        cmp #'p'
        bne @not_pointer
        lda #$80
        sta _printf_pointer
        bne inc_string_loop
@not_pointer:
.endif
        cmp #'_'
        bne @not_underscore

        lda #$80
        sta _printf_underscores
        bne inc_string_loop

@not_underscore:
.ifdef _TINYPRINTF_SUPPORT_LEADING_ZEROS
        cmp #'0'
        bne @not_zeros

        ldx #$80
        stx  _printf_leading_zeros
        jmp inc_string_loop
@not_zeros:
        jsr if_digit_set_total_places
        bcc @not_digit
       ; lda _printf_total_places   ; _printf_total_places is already in A
        ora #_PRINTF_SPACE_BIT
        sta _printf_total_places
        jmp inc_string_loop
@not_digit:
.endif
        cmp #'l'
        bne @not_width

        lda _printf_width
        cmp #3
        beq error

        inc _printf_width
        jmp inc_string_loop
@not_width:
.ifdef _TINYPRINTF_SUPPORT_ARG_HEX
        cmp #'x'
        bne @not_lower_x

        lda #0
        beq @set_case

@not_lower_x:
        cmp #'X'
        bne @not_upper_x

        lda #16
@set_case:
        sta _printf_case

        jmp _printf_hex
@not_upper_x:
.endif
.ifdef _TINYPRINTF_SUPPORT_ARG_STRING
        cmp #'s'
        bne @not_string

        jmp _printf_string
@not_string:
.endif
.ifdef _TINYPRINTF_SUPPORT_ARG_CHAR
        cmp #'c'
        bne @not_char

        jmp _printf_char
@not_char:
.endif
.ifdef _TINYPRINTF_SUPPORT_ARG_DECIMAL
        cmp #'d'
        bne @not_decimal

        jmp _printf_decimal
@not_decimal:
.endif
.ifdef _TINYPRINTF_SUPPORT_ARG_BINARY
        cmp #'b'
        bne error

        jmp _printf_binary
@not_binary:
.endif
@mode_backspace:
.ifdef _TINYPRINTF_SUPPORT_ESCAPED_HEX_LITERALS
        cmp #'x'
        bne @not_hex
        jmp _printf_hex_symbol
.endif
@not_hex:
        cmp #'n'
        bne @not_newline

        lda #$0a
.ifdef __C64__
        PRINTF_OUTPUT_CHAR
        lda #$0d
.endif
@not_newline:
        PRINTF_OUTPUT_CHAR
        jmp _printf_reset_mode


@verified_change_mode:
        ldx _printf_mode
        cpx #_PRINTF_MODE_NORMAL
        bne error

        sta _printf_mode
        rts


@percent:
        lda #_PRINTF_MODE_PERCENT
        jsr @verified_change_mode

        lda #0
        sta _printf_width
        sta _printf_underscores
.ifdef _TINYPRINTF_SUPPORT_LEADING_ZEROS
        sta _printf_leading_zeros
        sta _printf_total_places
.endif
.ifdef _TINYPRINTF_SUPPORT_ARG_PTR
        sta _printf_pointer
.endif
        beq @return

@backspace:
        lda #_PRINTF_MODE_BACKSPACE
        jsr @verified_change_mode
@return:
        jmp inc_string_loop

error:
        lda #'E'
        PRINTF_OUTPUT_CHAR
        lda #'R'
        PRINTF_OUTPUT_CHAR
        PRINTF_OUTPUT_CHAR
        jmp _printf_exit


_printf_adjust_args_ptr:
        ldy _printf_str_idx
_printf_reset_mode:
        lda #_PRINTF_MODE_NORMAL
        sta _printf_mode
        jmp inc_string_loop



_printf_get_args:
        sty _printf_str_idx
        ldy _printf_arg_idx
        lda (_printf_args),y
        sta _printf_src
        iny
        lda (_printf_args),y
        sta _printf_src + 1
        iny
        sty _printf_arg_idx

.ifdef _TINYPRINTF_SUPPORT_ARG_PTR
        bit _printf_pointer
        bpl @no_pointer
        ldy #0
        lda (_printf_src),y
        tax
        iny
        lda (_printf_src),y
        stx _printf_src
        sta _printf_src + 1
@no_pointer:
.endif
        rts

.ifdef _TINYPRINTF_SUPPORT_LEADING_ZEROS
if_digit_set_total_places:
        cmp #'9' + 1
        bcs @not_digit
        cmp #'1'
        bcc @not_digit
        sbc #'0'    ; carry already set
        sta _printf_total_places
        rts
@not_digit:
        clc 
        rts
.endif


.ifdef _TINYPRINTF_SUPPORT_ARG_HEX
_printf_hex:
        jsr _printf_get_args

.ifdef _TINYPRINTF_SUPPORT_LEADING_ZEROS
        ldy _printf_width
        iny
        tya
        dey
        asl
        tax

@digit_loop:
        lda (_printf_src),y
        jsr _printf_count_nibble_digits
        bcc @digit_loop

        jsr _printf_print_extra_zeros
.endif
        lda #$00
        sta _printf_zero_marker
        ldy _printf_width
@loop:
        lda (_printf_src),y
        jsr _printf_hex_byte

        dey
        bpl @loop
        
        jmp _printf_adjust_args_ptr

_printf_hex_byte:
        pha
        lsr
        lsr
        lsr
        lsr
        jsr _printf_leading_zero_test
        bcs @skip_zero
        clc
        adc _printf_case
        tax
        lda hex_digits,x
        PRINTF_OUTPUT_CHAR
@skip_zero:
        pla
        and #$0f
        cpy #0
        beq @print_final_zero

        and #$0f
        jsr _printf_leading_zero_test
        bcs @skip_zero2
@print_final_zero:
        clc
        adc _printf_case
        tax
        lda hex_digits,x
        PRINTF_OUTPUT_CHAR
@skip_zero2:
        rts
.endif

.ifdef _TINYPRINTF_SUPPORT_ARG_STRING
_printf_string:
        jsr _printf_get_args
        ldy #0
@loop:
        lda (_printf_src),y
        beq @end

        PRINTF_OUTPUT_CHAR

        iny
        bne @loop
@end:
        jmp _printf_adjust_args_ptr
.endif

.ifdef _TINYPRINTF_SUPPORT_ARG_CHAR
_printf_char:
        jsr _printf_get_args

        ldy #0
        lda (_printf_src),y

        PRINTF_OUTPUT_CHAR

        jmp _printf_adjust_args_ptr
.endif

.ifdef _TINYPRINTF_SUPPORT_ARG_BINARY
_printf_binary:
        jsr _printf_get_args

        ldy _printf_width
@loop:
        lda (_printf_src),y
        jsr _printf_bin_byte

        dey
        bpl @loop

        jmp _printf_adjust_args_ptr
        
       
_printf_bin_byte: 
        cpy _printf_width
        beq @start_of_number
        bit _printf_underscores
        bpl @start_of_number

        pha
        lda #'_'
        PRINTF_OUTPUT_CHAR
        pla

@start_of_number:
        ldx #7
@loop:
        asl
        pha
        lda #'0'
        adc #0
        PRINTF_OUTPUT_CHAR
        cpx #4
        bne @not_middle

        bit _printf_underscores
        bpl @not_middle
        lda #'_'
        PRINTF_OUTPUT_CHAR

@not_middle:
        pla
        dex
        bpl @loop
        rts
.endif


.ifdef _TINYPRINTF_SUPPORT_ARG_DECIMAL
_printf_decimal:
        jsr _printf_get_args

        ldx #0
        stx _printf_bin + 3
        stx _printf_bin + 2
        stx _printf_bin + 1
        ldy _printf_width
@copy:
        lda (_printf_src),y
        sta _printf_bin,y
        dey
        bpl @copy

        lda #0       ; Ensure the result is clear
        ldx #4
@clear: sta _printf_bcd,x
        dex
        bpl @clear

        sed            ; Switch to decimal mode
        ldx #32     ; The number of source bits

@cnvbit:
        asl _printf_bin + 0    ; Shift out one bit
        rol _printf_bin + 1
        rol _printf_bin + 2
        rol _printf_bin + 3
        .repeat 5,I
        lda _printf_bcd + I
        adc _printf_bcd + I
        sta _printf_bcd + I
        .endrep

        dex
        bne @cnvbit
        cld

.ifdef _TINYPRINTF_SUPPORT_LEADING_ZEROS
; now take care of leading zeros

        ldy _printf_width
        iny
        iny
        tya
        dey
        asl
        tax

; find the number of non-zero digits in the result
@digit_loop:
        lda _printf_bcd,y
        jsr _printf_count_nibble_digits
        bcc @digit_loop

        jsr _printf_print_extra_zeros
.endif
        lda #$00
        sta _printf_zero_marker
        ldx _printf_width
        inx
@loop:  lda _printf_bcd,x
        pha

        lsr
        lsr
        lsr
        lsr

        jsr _printf_leading_zero_test
        bcs @skip_zero
@non_zero:
        adc #'0'

        PRINTF_OUTPUT_CHAR
@skip_zero:
        pla

        and #$0f
        cpx #0
        beq @print_final_zero

        and #$0f    ; get flags
        jsr _printf_leading_zero_test
        bcs @skip_zero2
@print_final_zero:
        clc
        adc #'0'
        PRINTF_OUTPUT_CHAR
@skip_zero2:
        dex
        bpl @loop
@end:
        jmp _printf_adjust_args_ptr

.endif


.ifdef _TINYPRINTF_SUPPORT_ESCAPED_HEX_LITERALS
_printf_hex_symbol:
        iny
        lda (_printf_str),y
        ; null check not needed, check_digit will fail with \0, too.
        jsr @_printf_check_digit
        asl
        asl
        asl
        asl
        sta _printf_tmp
        iny
        lda (_printf_str),y
        ; null check not needed, check_digit will fail with \0, too.
        jsr @_printf_check_digit
        ora _printf_tmp

        PRINTF_OUTPUT_CHAR
        jmp _printf_reset_mode
        
.ifdef _TINYPRINTF_SUPPORT_ARG_HEX   ; if we have the hex digit table
@_printf_check_digit:
        ldx #$1f
@loop:
        cmp hex_digits,x
        beq @found
        dex
        bne @loop
        pla
        pla
@error:
        jmp error
@found:
        txa
        and #$0f
        rts
.else   ; without the hex digit table, this is smaller (and faster, on average).
@_printf_check_digit:
        cmp #'9' + 1
        bcs @not_decimal
        cmp #'0'
        bcs @decimal_digit
@not_decimal:
        ; uppercasing is a bit messy (thanks, PETSCII!)
        .if ('A' - 'a' > 0)
        ora #<('A'-'a')
        .else
        and #<~('a'-'A')
        .endif
        cmp #'F' + 1
        bcs @not_hex_digit
        cmp #'A'
        bcc @not_hex_digit
        sbc #'A' - '0' - 10
@decimal_digit:
        sbc #'0'
@store_nibble:
        rts
@not_hex_digit:
        pla
        pla
@error:
        jmp error
.endif

.endif


; Value to test in A, flags set.
_printf_leading_zero_test:
        bne @dont_skip
        bit _printf_zero_marker
        bpl @skip_zero

@dont_skip:
        dec _printf_zero_marker
        clc
        rts
@skip_zero:
        sec
        rts

.ifdef _TINYPRINTF_SUPPORT_LEADING_ZEROS
; print extra zeros (if needed)
_printf_print_extra_zeros:        
        lda _printf_total_places
        bpl @not_spaces
        and #<~_PRINTF_SPACE_BIT
        sta _printf_total_places
        lda #' '
        .byte $2c   ; BIT $aaaa
@not_spaces:
        lda #'0'
@zeros_loop:
        cpx _printf_total_places
        bcs @no_extra_zeros
        inx
        PRINTF_OUTPUT_CHAR
        bcc @zeros_loop
@no_extra_zeros:
        rts

; find the number of non-zero digits in the result
_printf_count_nibble_digits:
@digit_loop:
        cmp #$10
        bcs @count_done
        dex
        dey
        bmi @count_done
        and #$0f
        bne @count_done
        dex
        clc
        rts
@count_done:
        sec
        rts
.endif


        .segment "RODATA"
.ifdef _TINYPRINTF_SUPPORT_ARG_HEX
hex_digits:
        .byte "0123456789abcdef"
        .byte "0123456789ABCDEF"
.endif

        ;.byte "_0pbcdsXxl"

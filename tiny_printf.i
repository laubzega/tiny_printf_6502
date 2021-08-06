        .import _printf
.ifdef __CBM__
        .import _printf_register_a
        .import _printf_register_x
        .import _printf_register_y
        .import _printf_register_pc
        .import _printf_register_p
.else
        .importzp _printf_register_a
        .importzp _printf_register_x
        .importzp _printf_register_y
        .importzp _printf_register_pc
        .importzp _printf_register_p
.endif

.macro regpush r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15
        .local @reg
        .ifblank r2
            .exitmacro
        .endif

        .if (.match (.left (1, {r2}), &))
            .segment "RODATA"
            .local @arg_adr
            .word @arg_adr
            .segment "DATA"
            @arg_adr: .word .right(.tcount({r2})-1, {r2})
        .elseif (.match (.left (1, {r2}), ^))
            .if (.tcount({r2}) - 1 = 1)                
                .if (.xmatch (.right(.tcount ({r2})-1, {r2}), A))
                    .segment "RODATA"
                    .word _printf_register_a
                    .if .not (@a_stored)
                        @a_stored .set 1
                        .segment "CODE"
                         sta _printf_register_a
                    .endif
                .elseif (.xmatch (.right(.tcount ({r2})-1, {r2}), X))
                    .segment "RODATA"
                    .word _printf_register_x
                    .if .not (@x_stored)
                        @x_stored .set 1
                        .segment "CODE"
                        stx _printf_register_x
                    .endif
                .elseif (.xmatch (.right(.tcount ({r2})-1, {r2}), Y))
                    .segment "RODATA"
                    .word _printf_register_y
                    .if .not (@y_stored)
                        @y_stored .set 1
                        .segment "CODE"
                        sty _printf_register_y
                    .endif
                .elseif (.xmatch (.right(.tcount ({r2})-1, {r2}), PC))
                    .segment "RODATA"
                    .word _printf_register_pc
                .elseif (.xmatch (.right(.tcount ({r2})-1, {r2}), P))
                    .segment "RODATA"
                    .word _printf_register_p
                    .if .not (@s_stored)
                        @s_stored .set 1
                        .segment "CODE"
                        pha
                        php
                        pla
                        sta _printf_register_p
                        pla
                    .endif
                 .elseif (.strlen(.string(.right(.tcount({r2}) - 1, {r2}))) = 2)
                    .repeat 2, r
                        @reg .set .strat(.string(.right(.tcount({r2}) - 1, {r2})), 1 - r)
                        .if (@reg = 'A')
                            .segment "RODATA"
                            .local @arg_a
                            @arg_a: .byte 0
                            .segment "CODE"
                            sta @arg_a
                        .elseif (@reg = 'X')
                            .segment "RODATA"
                            .local @arg_x
                            @arg_x: .byte 0
                            .segment "CODE"
                            stx @arg_x
                        .elseif (@reg = 'Y')
                            .segment "RODATA"
                            .local @arg_y
                            @arg_y: .byte 0
                            .segment "CODE"
                            sty @arg_y
                        .else
                            .fatal .sprintf("Unknown register: %c", @reg)
                        .endif
                    .endrep
                 .else 
                    .fatal .sprintf("Unknown register: %s", .string(.right(.tcount ({r2}) - 1, {r2})))
                 .endif
             .endif
        .else
            .segment "RODATA"
            ;.out .sprintf("Nonreg: %s", .string(r2))
            .word r2
        .endif

        regpush r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15
.endmacro

.macro printf r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15
       .pushseg
        .local @_argdata
        @a_stored .set 0
        @x_stored .set 0
        @y_stored .set 0
        @pc_stored .set 0
        @s_stored .set 0
        
        .segment "RODATA"
@_argdata:
        .byte .strlen(r1) + 2   ; add ourselves and the trailing zero
        .asciiz r1
        ;.segment "DATA"
;_argprep:
        .segment "RODATA"
        regpush r2, r3, r4, r5, r6, r7, r8, r9
        .segment "CODE"
.ifdef _TINYPRINTF_PRESERVE_REGS
        pha
        txa
        pha
.endif
        lda #<@_argdata
        ldx #>@_argdata
        jsr _printf
.ifdef _TINYPRINTF_PRESERVE_REGS
        pla
        tax
        pla
.endif
        .popseg
.endmacro

.macro printq r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15
        ;.out r1
       .pushseg
        .local @_argdata
        @a_stored .set 0
        @x_stored .set 0
        @y_stored .set 0
        @pc_stored .set 0
        @s_stored .set 0
        
        .segment "RODATA"
@_argdata:
        .byte .strlen(r1) + 2   ; add ourselves and the trailing zero
        .asciiz r1
        .segment "RODATA"
        regpush r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15
        .segment "CODE"
        lda #<@_argdata
        ldx #>@_argdata
        jsr _printf

        .popseg
.endmacro



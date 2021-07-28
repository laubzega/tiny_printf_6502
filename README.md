# tiny_sprintf_6502

If you ever wanted to (s)printf things in assembly as effortlessly as you
can do it in C, you came to the right place. This macro/library combination
lets you do things like

```
	lda #42
	sta value
	printf "8-bit value: %02x at %04lx\n", value, &value
	rts
value:	.byte 0
```
and also
```
	printf "$%X = %d dec\n", value, value
```
and even

```
	ldx #0
loop:
	printf "Content of register X is $%02x\n", ^X
	dex
	bne loop
```


# tiny_printf_6502

### How may I help you?

If you ever wanted to (s)printf things in assembly as effortlessly as can be done in C,
you came to the right place. This ca65 macro/library combination
lets you do things like

```asm
	lda #42
	sta value
	printf "8-bit value: %02x at %04lx\n", value, &value
	rts
value:	.byte 0
```
and also
```asm
	printf "$%X = %d dec\n", value, value
```
and even

```asm
	ldx #0
loop:	printf "Content of register X is $%02x\n", ^X
	dex
	bne loop
```

and that, too:

```asm
	lda #<text
	sta ptr
	lda #>text
	sta ptr + 1
	printf "Pointer at $%04lx, pointing to $%04lx, which is %ps\n", &ptr, ptr, ptr
	rts
text	.byte "Hello Underworld", 0
```

### I'm tentatively interested, please elaborate.

```printf``` is a macro for ca65 (part of https://github.com/cc65/cc65) that during assembly builds a compact data structure containing the string with optional formatting tags, and the arguments, and also inserts a call to ```_printf```. The data structure is then consumed at run-time by ```_printf```, which parses the string, inserts appropriately formatted arguments and produces the output. Function ```_printf``` is around 700 bytes with all options enabled, but is very configurable and depending on the features you need, it can tuned down to ~200 bytes. Additionally, care has been taken to keep to number of bytes taken by each call to a minimum - it is equal to:

length_of_the_string + 1 (trailing null) + number_of_args * 2 + 1 + 6 (preserving and restoring registers X and A) + 7 (loading a pointer and then jump to a subroutine)

By default ```printf``` preserves the contents of all registers. If you don't need it and want to save some space, you can either disable it globally or use ```printq``` that only preserves Y.

### Is it like full printf, with floats, and precision, and a pony?

Not really, but the list of supported format specifiers is quite comprehensive:

* %d - decimal numbers
* %x - hexadecimal numbers (%X - also uppercase)
* %b - binary numbers
* %c - single characters
* %s - strings
* \n - new lines
* \\%, \\\\ - escaping special characters
* \xNN - hexadecimal literals

There are also modifiers:

* %0N will make decimal and hex numbers N digits long, adding leading zeros where necessary, i.e.
```asm
	lda #$40
	printf "%03d", ^A
```
outputs ```064```.

* %N will do the same, but use leading spaces rather than zeros.
* %\_b will put a separator every 4 binary digits, making long strings of zeros and ones easier to parse visually:
```asm
	lda #$40
	printf "%_b", ^A
```
outputs ```0100_0000```.	

# Argument sizes and other differences from C printf()

The assembler macro does not have the compiler's luxury of knowing argument types. We thus have to take over this responsiblity and provide necessary information about argument sizes in the format specifiers.

By default, arguments are considered to be a byte value. So 
```asm
	printf "%x\n", value
	rts
value:	.dbyte $12345678
```
will output ```12```, because this is the first byte following the label ```value```.

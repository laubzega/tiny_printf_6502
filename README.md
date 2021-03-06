# tiny_printf_6502

### What's going on here?

If you ever wanted to ```printf``` things in assembly as effortlessly as can be done in C,
you've come to the right place. This ca65 macro/library combination
lets you do things like

```asm
	lda #42
	sta value
	printf "8-bit value: %02d at %04ld\n", value, &value
	rts
value:	.byte 0
```
producing this output: ```8-bit value: 42 at 3163```. Or like that
```asm
	printf "$%X = %d dec\n", value, value
```
outputting: ```$2A = 42 dec```. Also this is possible:
```asm
	lda #<text
	sta ptr
	lda #>text
	sta ptr + 1
	printf "Pointer at $%04lx, pointing to string at $%04lx, which is \'%ps\'.\n", &ptr, ptr, ptr
	rts
text:	.byte "Hello, Underworld", 0
ptr:	.word 0
```
Output: ```Pointer at $0ce3, pointing to string at $0cd1, which is 'Hello, Underworld'.``` Finally,
```asm
	ldx #2
loop:	printf "Content of register X is $%02x\n", ^X
	dex
	bpl loop
```
will yield:
```
Content of register X is $02
Content of register X is $01
Content of register X is $00
```


### I'm tentatively interested, please elaborate.

```printf``` is a macro for ca65 (part of https://github.com/cc65/cc65) which during assembly builds a compact data structure containing the string with optional formatting tags and their corresponding arguments, and also inserts a call to function ```_printf```. The data structure is then consumed at run-time by ```_printf```, which parses the string, inserts appropriately formatted arguments and produces the output. Function ```_printf``` is around 900 bytes with all bells and whistles enabled, but is very configurable and depending on the features you need, it can be trimmed down to ~250 bytes. Additionally, care has been taken to keep the number of bytes taken by each call to a minimum - it is approximately equal to:

length_of_the_string + 1 (trailing null) + number_of_args * 2 + 1 + 6 (preserving and restoring registers X and A) + 7 (loading a pointer and then a jump to a subroutine)

By default ```printf``` preserves the contents of all registers. If you don't need this and want to save some space, you can either disable it globally or use ```printq``` that only preserves Y, saving 6 bytes on each call.

The code is ROMable, but not reentrant.


### But where does it print to?

Glad you asked. Your code is expected to define a macro called ```PRINTF_OUTPUT_CHAR```, which will be executed repeatedly as ```_printf``` is producing successive characters of the result string. The macro is handed each character in the accumulator and may output it to the screen directly (e.g. by calling ```CHROUT``` on the C64), send it over UART, or perform more sophisticated actions (like controlling output size to e.g. emulate snprintf()). See [example2/](example2/) for inspiration and remember that the macro is expected to preserve registers A, X and Y.

Additionally, if macro ```PRINTF_INIT``` is defined, it will be executed at the start of ```_printf```. It could come handy if you need some values to be initialized at the start of every call. Again, see [example2/](example2/) for a practical application.


## Seems cool, how do I use it?

* Make sure that your linker config has CODE, ZEROPAGE, DATA and RODATA segments.
* Define PRINTF_OUTPUT_CHAR macro and make it visible in tiny_printf.s
* Optionally define PRINTF_INIT
* Make your code include tiny_printf.i (for macros)
* Adjust configuration options in tiny_printf.s (unless you want everything, which is the default)
* Assemble tiny_printf.s and link it with your code. No point making it into a library, it's just one function.
* Commence printfing. All your printf calls should be done from the CODE segment.

As usual, included examples are your best friends. Refer to them for build setup, macro definitions, and usage examples.


## Is it like full printf, with floats, and precision, and a pony?

Not really, but the list of supported format specifiers is quite extensive:

* %d - decimal numbers
* %x - hexadecimal numbers (%X - also uppercase)
* %b - binary numbers
* %c - single characters
* %s - strings
* \n - new lines
* \\%, \\\\ - escaped special characters
* \xNN - hexadecimal literals

There are also some useful modifiers:

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

## Argument sizes

The assembler macro does not share the compiler's luxury of knowing argument types. We thus have to take over this responsiblity and provide necessary information about argument sizes in the format specifiers. By the way, this is probably the largest departure from C printf(), but one that makes sense from the viewpoint of an assembler programmer. It takes some getting used to, so if you are seeing results way different than expected, your size modifiers are the first thing to check.

By default, arguments are assumed to be byte-sized. So 
```asm
	printf "%x", val
	rts
val:	.byte $12, $34, $56, $78
```
will output ```12```, because this is the value of the first byte following the label ```val```. To increase the magnitude of our number we can apply modifier ```l```, so
```asm
	printf "%lx", val
```
will output ```3412```, because now two bytes are being considered (in 6502's little-endian order).
```asm
	printf "%llx", val
```
makes it a 24-bit operation and yields ```563412```, and finally
```asm
	printf "%lllx", val
```
uses all 32-bits: ```78563412```.

Same is true for decimal numbers, so
```asm
	printf "%d %ld %lld %llld", val, val, val, val
```
produces ```18 13330 5649426 2018915346```.

No more than three ```l``` modifiers are allowed, meaning that numbers up to 32-bit are supported.

Another 6502-specific modifier is ```p```. It assumes that the corresponding argument is a 16-bit pointer, and outputs the value that the pointer references. So:
```asm
	printf "%s %ps", text, ptr
text:	.byte "Bye", 0
ptr:	.word text
```
will output ```Bye Bye```.


## Register arguments

You have already seen this above - prefix ```^``` used in front of an argument name indicates that it refers to a register. Registers X, Y, A, PC and P (status) are recognized. For example:
```asm
	lda #$c0
	ldx #$de
	ldy #$64
	printf "A:$%02X X:$%02X Y:$%02X at $%04lX", ^A, ^X, ^Y, ^PC
```
will produce ```A:$C0 X:$DE Y:$64 at $C00C```.

There is also another way of using the registers. 6502 programmers often pass pointers using a pair of 8-bit registers. To see what such pointer refers to, simply use
```asm
	ldx #<text
	lda #>text
	printf "A=$%02x, X=$%02x, AX points to %s", ^A, ^X, ^AX
	rts
text:	.byte "Blah", 0
```
which would output ```A=$c0, X=$20,  AX points to Blah``` (assuming that ```text``` is at ```$c020```).

Note that the high byte is expected to be in the leftmost register. 


## Other limitations and differences from C printf()

* In ```%0N``` and ```%N```, N can only be a single digit. I'm still weighting this limitation against the size of extra code needed to support multi-digit counts of leading zeros and spaces, so this may change.
* No exhaustive validation of format specifiers and their modifiers is performed (again for code size reasons). Some validation is done though, ```printf``` will terminate and output ```ERR``` in place where it encountered problems.
* There is currently no support for negative numbers.
* Maximum length of a format string is 255 bytes.
* Maximum number of arguments is 14.
* The code is not reentrant. Using it concurrently from interrupt context (or by more than one process) will lead to undefined (but certainly unpleasant) behavior.

## Memory use

The table below shows the effects of various configuration options on the size of the resulting binary. While some effort has been invested into keeping the code small, I am pretty sure a few bytes can be shaved off here and there.

Configuration | Available args | Binary size increase<br>[bytes] | Total binary size<br>[bytes]
:---| :---: | :---: | :---:
Base | just the string itself | 241 | 241
ARG_HEX | %x | 122 | 363
ARG_DECIMAL | %d | 168 | 409
ARG_BINARY  |%b and %\_b | 71 | 312
ARG_STRING | %s | 25 | 266
ARG_CHAR | %c | 20 | 261
ARG_HEX + ARG_LEADING_ZEROS | %0Nx and %Nx (0<N<10) | 250 | 491
ARG_DECIMAL + ARG_LEADING_ZEROS | %0Nd and %Nd (0<N<10) | 298 | 539
ARG_PTR | %p[xbdcs] | 32 | 273
ESCAPED_HEX_LITERALS | \xNN | 63 | 304
PRESERVE_REGS | | 4 | 245
All options - ARG_LEADING_ZEROS | %x %b %d %c %s \xNN %p[xbdcs] | 496| 737
All options | %x %b %d %c %s \xNN %p[xbdcs]<br>%0Nx %0Nd (0<N<10)<br>%Nx %Nd (0<N<10)| 644| 885

When building for systems with available zero page locations, 26 bytes are moved from "DATA" to "ZEROPAGE" segment, further reducing the total size. Otherwise just three pointers (6 bytes) on the zeropage are required.

## Wait, has it been tested?!

There are some 50+ tests being run (using sim65 from cc65) whenever you type make. See [test/](test/) for details.

The code is also heavily used in a project I'm currently working on.

### Great, no bugs then!

lol

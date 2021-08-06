all: example1/demo example2/screen test

.PHONY: test

test/test : tiny_printf.s test/test.s test/tiny_printf_io.i tiny_printf.i
	ca65 -t sim6502 test/test.s
	ca65 -t sim6502 tiny_printf.s --include-dir test
	ld65 -C test/ldtest.cfg --lib sim6502.lib test/test.o tiny_printf.o -o test/test

test: test/test
	sim65 test/test

example1/demo : tiny_printf.s example1/demo.s example1/tiny_printf_io.i tiny_printf.i
	ca65 -t c64 example1/demo.s
	ca65 -t c64 tiny_printf.s --include-dir example1
	ld65 -C example1/ldtest.cfg --lib c64.lib -u __EXEHDR__ example1/demo.o tiny_printf.o -o $@

example2/screen : tiny_printf.s example2/screen.s example2/tiny_printf_io.i tiny_printf.i
	ca65 -t c64 example2/screen.s
	ca65 -t c64 tiny_printf.s --include-dir example2
	ld65 -C example2/ldtest.cfg --lib c64.lib -u __EXEHDR__ example2/screen.o tiny_printf.o -o $@

clean:
	rm -rf example1/*.o test/*.o example1/demo test/test example2/*.o example2/screen

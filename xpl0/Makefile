all: step0_repl


clean:
	rm -rf *.EXE *.ASM *.OBJ *.MAP

step0_repl:
	dosbox \
		-c "mount m \"$$(pwd)\"" \
		-c "M:" \
		-c "execute $$(pwd) step0" \
		-c "exit /b"

step1_read_print:
	dosbox \
		-c "mount m \"$$(pwd)\"" \
		-c "M:" \
		-c "execute $$(pwd) step1" \
		-c "exit /b"

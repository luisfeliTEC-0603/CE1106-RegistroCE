ALINK=../alink

ALL: main.exe

%.obj: %.asm
	nasm $< -fobj -o $@

main.exe: main.obj
	$(ALINK) $^ -o $@ -m -oEXE

run: main.exe
	dosbox -noautoexec main.exe

clean:
	rm *.obj *.exe *.map

all: b32e b32d b32es

clean:
	rm -rf b32e
	rm -rf b32es
	rm -rf b32d
	rm -rf *.o

b32e: b32e.o
	ld -o b32e b32e.o
	
b32e.o: base32enc.asm
	nasm -f elf64 -g -F dwarf base32enc.asm -o b32e.o

b32d: b32d.o
	ld -o b32d b32d.o

b32d.o: base32dec.asm
	nasm -f elf64 -g -F dwarf base32dec.asm -o b32d.o

b32es: b32es.o
	ld -o b32es b32es.o

b32es.o: base32enc_short.asm
	nasm -f elf64 -g -F dwarf base32enc_short.asm -o b32es.o
	

genPassRandom: genPassRandom.o
	gcc -m32 genPassRandom.o -o genPassRandom
genPassRandom.o: genPassRandom.asm
	nasm -f elf -g -F stabs genPassRandom.asm
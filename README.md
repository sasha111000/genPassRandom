# genPassRandom

genPassRandom is a small utility that generates and prints a screen of pseudo-random (time-based) 8-digit passwords

## dependencies (ubuntu)

make, nasm, gcc-multilib

## compilation

compile the program using command:

`$ make`

## usage

`$ ./genPassRandom`

### sample output

```
2aKWmyrv       t4lB-qaL       hH!XwCfn
SXXTNpmY       qOht5n9i       5xce9IM9
Nou8m7G-       9jir!Osz       JvjPhE5S
oKI0xaGE       1muo-YHJ       kK!25yFw
EVJFSnAo       OkljYWLF       oMWgpzKi

E2oBklc!       3Y4fOS2h       CFNIj!l8
YYL7kIv3       J2ali3wP       AediGpKv
XOZbSCoQ       p3Eh-sUZ       MXrIvHoU
OpOMHxMy       xMo1OlC8       4OCRVzk3
dZWRv-61       YS0K0!9v       -3rFgqyf

uEiRMAZC       gXLtSf1D       R1B6164k
P0J1xkyS       uXu9W1tp       5hrED02L
!51Ji3RN       4a4VsQak       1sIixCzt
TrCu0zJi       O-tL-sIb       kgw8OkSL
w5k4l8ga       qEaJbLq3       !12O8ehb
```

## notes

you can adjust the output a little; to do this, change parameters in the head of the genPassRandom.asm, within section labelled `*** tune section`; and then recompile the binary (see [compilation](#compilation), above)

### structure of program

to better understanding the code structure, there is a short scheme:

```
procedure fillPassVar (input: password_var) 
	fill password_var with characters from the big random string, 
	then adjust big random string pointer forth, for the next call

procedure printLine (input: none)
	3 calls fillRandVar for three different variables "password_var"
	print line of passwords

procedure printGroup (input: none)
	5 calls printLine in a loop
	print empty separator line

main
	generate big random characters' string
	3 calls printGroup in a loop
```

## copyright

based on randtest.asm sample program, from book: Assembly Language Step-By-Step by J.Duntemann, 3rd edition (Wiley, 2009)
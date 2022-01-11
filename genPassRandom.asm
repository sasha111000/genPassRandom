;;
;;   source name     : genPassRandom.asm
;;   executable name : genPassRandom
;;   version         : 1.0
;;   created date    : 02/09/2019
;;   last update     : 10/09/2019
;;   author          : sasha111000
;;   description     : a simple pseudo-random 8-digit passwords generator using nasm 0.98.39
;;
;;   build using these commands:
;;     nasm -f elf -g -F stabs genPassRandom.asm
;;     gcc genPassRandom.o -o genPassRandom
;; 

[SECTION .data]			; section containing initialised data

lineBase  db '%s       %s       %s',10,0	; template for printf glibc function
;; table of characters, used in random passwords, must be 64-bytes length
charTbl	  db '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-!'

;; ***  tune section, adjust values to customize output  *** *** ***
groupSize   db 5	; select lines count in a single passwords group (1-99, default 5)
groupsCount db 3	; select number of groups in the output (1-99, default 3)

[SECTION .bss]			; section containing uninitialized data

BUFSIZE	  EQU 360	; calculate value in this way (default 360): 
			; BUFFSIZE = ( 24 * groupSize * groupsCount )
;; ***  tune section end  *** *** ***

randChars resb BUFSIZE+5	; reserve space for a string of random chars
passPtr   resd 1		; reserve integer to hold the big random string's pointer
passVar01 resb 9	; 8 bytes is a password length, +1 null-terminator (printf)
passVar02 resb 9	; we need 3 variables to printf line of 3 passwords at a time
passVar03 resb 9	; template of that line is the lineBase initialized data item
		
[SECTION .text]			; section containing code

extern printf		; all of these are in the standard C library glibc	
extern rand	
extern srand
extern time

global main			; required so linker can find entry point
	
main:
        push ebp		; set up stack frame for debugger
	mov ebp,esp
	push ebx		; program must preserve ebp, ebx, esi, & edi
	push esi
	push edi
;;; everything before this is boilerplate; use it for all ordinary apps!	

	call seedIt		; seed the random number generator
	call genRandString	; generate the buffer of pseudo-random characters
	
	mov eax,1		; insert one empty line in the beginning
	call newLine		;  of output
	
;; main program section, highest level printing procedure's call
;; print groupCount groups of groupSize rows and 3 cols of randomly-generated passwords

	xor ecx,ecx	; clear counter
	mov byte cl,[groupsCount]  ; set the groups counter
.doNext:call printGroup	; print a single group of passwords
	loop .doNext	; go back & print another group, until ecx goes to 0

;; debug lines to monitor random buffer state
	
;	push randChars	; put addr to randChars to the stack
;	call printf	; print randChars
;	add esp,4	; clear stack

;;; everything after this is boilerplate; use it for all ordinary apps!
	pop edi			; restore saved registers
	pop esi
	pop ebx
	mov esp,ebp		; destroy stack frame before returning
	pop ebp
	ret			; return control to to the C shutdown code


;---------------------------------------------------------------------------
;  Random number seed routine  --  Last update 5/29/2009
;
;  This routine fetches a time_t value from the system clock using the C
;  library's time function, and uses that time value to seed the random number    
;  generator through the function srand.  No values need be passed into it    
;  nor returned from it.                                                     
;---------------------------------------------------------------------------
	
seedIt:	push dword 0		; Push a 32-bit null pointer to stack, since
				;  we don't need a buffer. 
	call time		; Returns time_t value (32-bit integer) in eax
	add esp,4		; Clean up stack
	push eax		; Push time value in eax onto stack
	call srand		; Time value is the seed value for random gen.
	add esp,4		; Clean up stack
	ret			; Go home; no return values

	
;---------------------------------------------------------------------------
;  Random number generator subroutines  --  Last update 5/29/2009
;
;  This routine provides 5 entry points, and returns 5 different "sizes" of
;  pseudorandom numbers based on the value returned by rand.  Note first of 
;  all that rand pulls a 31-bit value. The high 16 bits are the most "random"
;  so to return numbers in a smaller range, you fetch a 31-bit value and then
;  right shift it zero-fill all buty the number of bits you want. An 8-bit
;  random value will range from 0-255, a 7-bit value from 0-127, and so on.
;  Respects EBP, ESI, EDI, EBX, and ESP. Returns random value in EAX.
;---------------------------------------------------------------------------
pull31: mov ecx,0		; For 31 bit random, we don't shift
	jmp pull
pull16: mov ecx,15		; For 16 bit random, shift by 15 bits
	jmp pull
pull8:	mov ecx,23		; For 8 bit random, shift by 23 bits
	jmp pull
pull7:  mov ecx,24		; For 7 bit random, shift by 24 bits
	jmp pull
pull6:	mov ecx,25		; For 6 bit random, shift by 25 bits
	jmp pull
pull4:	mov ecx,27		; For 4 bit random, shift by 27 bits
pull:	push ecx		; rand trashes ecx; save shift value on stack
	call rand		; Call rand for random value; returned in eax
	pop ecx			; Pop stashed shift value back into ECX
	shr eax,cl		; Shift the random value by the chosen factor
				;  keeping in mind that part we want is in CL
	ret			; Go home with random number in eax


;------------------------------------------------------------------------------
;  Newline outputter  --  Last update 5/29/2009
;
;  This routine allows you to output a number of newlines to stdout, given by
;  the value passed in eax.  Legal values are 1-10. All sacred registers are
;  respected. Passing a 0 value in eax will result in no newlines being issued.
;------------------------------------------------------------------------------
newLine:
	mov ecx,10		; We need a skip value, which is 10 minus the
	sub ecx,eax		;  number of newlines the caller wants.
	add ecx,nl		; This skip value is added to the address of
	push ecx		;  the newline buffer nl before calling printf.
	call printf		; Display the selected number of newlines
	add esp,4		; Clean up the stack
	ret			; Go home
nl	db 10,10,10,10,10,10,10,10,10,10,0	


;; --------------------------------------------------------------------------------
;;   genRandString:	generate random string buffer
;;   updated:		10/09/2019
;;   in:		charTbl, randChars
;;   returns:		nothing
;;   modifies:		all but esp, ebp, esi, and edi registers, randChars
;;   calls:		pull6
;;   description:	generate a big null-terminated (for debug purposes) string 
;;			of random symbols from charTable set to randChars variable

genRandString:
	mov ebx,BUFSIZE		; BUFSIZE tells us how many chars to pull
	mov byte [randChars+BUFSIZE+1],0  ; put a null at the end of the buffer first
.loop:	dec ebx			; BUFSIZE is 1-based, so decrement
	call pull6		; go get a random number from 0-63
	mov cl,[charTbl+eax]	; use random # in eax as offset into table
	                        ;  and copy character from table into cl
	mov [randChars+ebx],cl	; copy char from cl to character buffer
	cmp ebx,0		; are we done having fun yet?
	jne .loop		; if not, go back and pull another
	ret			; and go home

	
;; -------------------------------------------------------------------------------
;;   fillPassVar:	fill passed variable with characters from the big random string
;;   updated:		10/09/2019
;;   in:		pass address of variable to fill in edi
;;   returns:		nothing
;;   modifies:		ecx, esi, edi, passPtr, passVarXX
;;   calls:		nothing
;;   description:	fill passVarXX with characters from the randChars, starting from
;;			position passPtr; then adjust passPtr for the next call; "passed"
;;			and "password" is an amusing ambiguity, don't become confused =)

fillPassVar:

; set address to the source string for movsd in esi, the destination address is
; already in edi; then adjust offset to the next position

	xor ecx,ecx		; prepare ecx
	mov ecx,[passPtr]	; load passPtr value in ecx
	lea esi,[randChars+ecx]	; load big string address + offset into esi
	add dword [passPtr],8	; increase passPtr value by password length

; fill out passed variable using movsd
	
	cld		; clear df for up-memory write
	xor ecx,ecx	; clear our poor register
	mov ecx,2	; two dwords equal to 8 characters
	rep movsd	; copies memory region starting at [esi] to region
			; starting at [edi], for ecx repeats, one dword at a time
	
	ret		; go back to printLine


;; -------------------------------------------------------------------------------
;;   printLine:		print single line of passwords
;;   updated:		10/09/2019
;;   in:		lineBase template
;;   returns:		nothing
;;   modifies:		trashes all, but ebx and ebp
;;   calls:		fillPassVar
;;   description:	call fillPassVar several times (it depends on how many passwords
;;			we want to print in one line); print single line of passVarXX
;;			variables, which contain random pre-generated passwords, using
;;			lineBase template for printf

printLine:

	mov edi,passVar01	; prepare addr of target variable for fillPassVar proc
	call fillPassVar	; call it

	mov edi,passVar02	; do it so much times, as much passwords in single line
	call fillPassVar	; here are three variables and three calls

	mov edi,passVar03	; addr to edi
	call fillPassVar	; third call

	push passVar03		; push rightmost parameter
	push passVar02		; push next parameter to the left
	push passVar01		; push next parameter to the left
	push lineBase		; push address of base string
	call printf		; call printf() to display single line of passwords
	add esp,16		; stack cleanup: 4 parms X 4 bytes = 16
	
	ret			; go back to printGroup


;; -------------------------------------------------------------------------------
;;   printGroup:	print one group of passwords
;;   updated:		10/09/2019
;;   in:		nothing
;;   returns:		nothing
;;   modifies:		trashes all but ebx, ecx, and ebp
;;   calls:		printLine
;;   description:	call printLine several times (it depends on how many lines of
;;			passwords we want to print in a single group); the procedure
;;			preserves high-level counter in ecx, so we need not to worry
;;			about group counter in main

printGroup:

	push ecx	; preserve group counter

	xor ecx,ecx	; clear counter
	mov byte cl,[groupSize]  ; set lines counter for loop
.doNext:push ecx	; preserve it from printLine
	call printLine	; print one line of passwords
	pop ecx		; restore lines counter after printf
	loop .doNext	; go back & print another line, until ecx goes to 0

	mov eax,1	; number of lines to insert
	call newLine	; insert blank line(s) after each group of passwords

	pop ecx		; restore group counter
	ret		; go back to main
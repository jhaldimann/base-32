; Name		: base32dec
; Authors	: Haldimann Julian, Gasser Manuel
; Created	: 05/11/2018
; Last updated	: 05/11/2018
; Description	: Small assembly program to decode data with base32

; Data section
section .data

	; Decode Table
	DecTable:
		db 00h, 01h, 02h, 03h, 04h, 05h, 06h, 07h, 08h, 09h, 0Ah, 0Bh, 0Ch, 0Dh, 0Eh, 0Fh
		db 10h, 11h, 12h, 13h, 14h, 15h, 16h, 17h, 18h, 19h, 1Ah, 1Bh, 1Ch, 1Dh, 1Eh, 1Fh

; BSS section
section .bss

	; Buffer for input
	BUFFLEN	equ 8				; We read the file 16 bytes at a time
	Buff: resb BUFFLEN			; Text buffer itself

	; String for output
	STRLEN	equ 5
	Str: resb STRLEN

; Text section
section .text

global _start

; Procedures
Print:
	mov	RAX, 4				;
	mov	RBX, 1				;
	mov	RCX, Str			; Move memory address of Str location in RSI
	mov	RDX, STRLEN			; Move length to print in RDX
	int 80h
	ret

ResetBuffAndStr:
	push RAX
	push RCX

	; Reset Str address
	xor RAX, RAX
	mov [Buff], RAX

	; Reset the Buff
	xor RCX, RCX
.reset:
	mov byte [Str+RCX], AL
	inc RCX
	cmp RCX, 5
	jne .reset

	pop RCX
	pop RAX
	ret

; Start of the program
_start:

ReadBuff:
	; Reset buff and str for the next input
	call ResetBuffAndStr

	mov	RAX, 3				; Get input from user
	mov	RBX, 0
	mov	RCX, Buff			; Write memory address from buff
	mov	RDX, BUFFLEN		; Length that should be read
	int 80h					; Make kernel call

	mov	RBP, RAX			; Save number of bytes read
	cmp RBP, 0				; Check if there were no bytes read
	je Exit					; Exit the program if nothing was read					; return

; Decodes 8 symbols 
Decode8:
	xor RCX, RCX			; Reset RCX register
	xor RAX, RAX			; Reset RAX register
	xor RBX, RBX			; Reset RBX register
	
.loop8:
	shl	RAX, 8				; Shift left by 1 byte
	mov AL, byte [Buff+RCX] ; Write the byte at the Buff address + counter in AL
	inc RCX					; Increment counter

	cmp RCX, 8				; Check if 8 bytes have been read from Buffer
	jne .looop8				; Repeat the loop if not

.mask8:
	mov RBX, RAX			; Copy the RAX register into RBX
	shl	RAX, 8				; Shift left RAX by one byte to get the next 8 bits next iteration
	shr	RBX, 56				; Shift right RBX by 7 bytes to mask out the most significant byte

	cmp AL, 40h
	jb .number
	jmp .letter

.letter:

	




Exit:
	mov	RAX, 60				; Clean exit of program
	mov	RDI, 0
	syscall

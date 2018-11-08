; Name		: base32enc
; Authors	: Haldimann Julian, Gasser Manuel
; Created	: 05/11/2018
; Last updated	: 05/11/2018
; Description	: Small assembly program to encode data with base32

; Data section
section .data

; Conversion table
CTable:
	db 41h, 42h, 43h, 44h, 45h, 46h, 47h, 48h, 49h, 4Ah, 4Bh, 4Ch, 4Dh, 4Eh, 4Fh, 50h
	db 51h, 52h, 53h, 54h, 55h, 56h, 57h, 58h, 59h, 5Ah, 32h, 33h, 34h, 35h, 36h, 37h

; BSS section
section .bss

	; Buffer for input
	BUFFLEN	equ 5				; We read the file 16 bytes at a time
	Buff: resb BUFFLEN			; Text buffer itself

	; String for output
	STRLEN	equ 5
	Str: resb STRLEN

; Text section
section .text

global _start

; Procedures
Print:
	mov	RAX, 1				;
	mov	RDI, 0				;
	mov	RSI, Str			; Move memory address of Str location in RSI
	mov	RDX, STRLEN			; Move length to print in RDX
	syscall
	ret

; Start of the program
_start:
	; for testing
	mov	RAX, Str

ReadBuff:
	mov	RAX, 3				; Get input from user
	mov	RDI, 0
	mov	RCX, Buff			; Write memory address from buff
	mov	RDX, BUFFLEN		; Length that should be read
	int 80h					; Make kernel call

	mov	RBP, RAX			; Save number of bytes read
	cmp RBP, 0				; Check if there were no bytes read
	je Exit				; Exit the program if nothing was read

	cmp RBP, 5				; Compare if 5 bytes were read
	je	Convert5			; Jump to Convert5 if 5 bytes were read
	jmp Convert				; Jump to Convert if less than 5 bytes were read

; Converts groups of 5 bytes
Convert5:
	xor	RCX, RCX			; Reset RCX register to use it as counter

.loop5:
	mov AL, byte [Buff+RCX]	; Copy the byte according to the counter in AL
	ror	RAX, 8				; Rotate right by 1 byte
	inc	RCX					; increment counter
	cmp	RCX, 5				; Check if 5th byte was copied
	jne .loop5				; Repeat the loop if 5th byte has not been read

	shr	RAX, 24				; Shift right by 3 bytes
	xor	RDX, RDX			; Reset RDX register
	xor	R10, R10			; Reset R10 register to use it as counter

.mask5:
	mov	RBX, RAX			; Copy RAX into RBX
	shr RAX, 5				; Shift right RAX to get the next 5 bits the next time
	and RBX, 1Fh			; Mask last 5 bits
	mov	DL, byte[CTable+RBX]; Get the according symbol from conversion table
	mov byte[Str+R10], DL	; Move the converted symbol from DL to the Str memory address + R10
	inc R10					; increment R10 counter (counts to 8)

	cmp R10, 8				; Check if loop has been done 8 times
	jne .mask5				; Repeat the loop if not done 8 times

	call Print				; call Print procedure to print the converted symbols

	jmp ReadBuff			; Jump to ReadBuff to read the next bytes

; Converts groups of less than 5 bytes
Convert:
	; Get the number of bits to add
	mov	RAX, RBP			; Copy the number of bytes read in RAX
	mov	RBX, 8				; Move the multyplier 8 to RBX
	mul	RBX					; Multiply the number of bytes read by 8 to get the number of bits
	mov	RBX, 5				; Move the divisor 5 to RBX
	div	RBX					; Divide the number of bits read by 5
	mov RBX, 5				; Move number of bits necessary for conversion to RBX
	sub	RBX, RDX			; Subtract the rest of the division from 5 to get the number of bits needed to add
	push RBX				; Push the number of bits to add on the stack

	mov	RDX, RAX			; Set the RDX register to the number of times we can convert 5 bits
	add	RDX, 1				; add 1 to this number

	xor	RCX, RCX			; Reset RCX to use as counter

.loop:
	mov AL, byte [Buff+RCX]	; Copy the byte according to the counter in AL
	ror	RAX, 8				; Rotate right by 1 byte
	inc	RCX					; increment counter
	cmp	RCX, 5				; Check if 5th byte was copied
	jne .loop				; Repeat the loop if 5th byte has not been read

	shr	RAX, 24				; Shift right by 3 bytes
	xor	RCX, RDX			; Set the RDX register to the number of times we can convert 5 bits
	xor	RDX, RDX			; Reset RDX register
	xor R10, R10			; Reset R10 to use as counter

.mask:
	mov	RBX, RAX			; Copy RAX into RBX
	shr RAX, 5				; Shift right RAX to get the next 5 bits the next time
	and RBX, 1Fh			; Mask last 5 bits
	mov	DL, byte[CTable+RBX]; Get the according symbol from conversion table
	mov byte[Str+R10], DL	; Move the converted symbol from DL to the Str memory address + R10
	dec RCX
	inc R10

	cmp RCX, 0				; Check if loop has been the number of times we can convert 5 bits
	jne .mask				; Repeat the loop if not

	pop RBX					; Tell the number of bits added to RBX

	xor RCX, RCX

	cmp	RBX, 2
	jmp equal6

	cmp RBX, 4
	jmp equal4

	cmp RBX, 1
	jmp equal3

	cmp RBX, 3
	jmp equal1

equal6:
	mov byte[Str+R10], 3Dh
	inc R10
	inc RCX
	cmp RCX, 6
	jne equal6
	call Print
	jmp Exit

equal4:
	mov byte[Str+R10], 3Dh
	inc R10
	inc RCX
	cmp RCX, 4
	jne equal4
	call Print
	jmp Exit

equal3:
	mov byte[Str+R10], 3Dh
	inc R10
	inc RCX
	cmp RCX, 3
	jne equal3
	call Print
	jmp Exit

equal1:
	mov byte[Str+R10], 3Dh
	inc R10
	inc RCX
	cmp RCX, 1
	jne equal1
	call Print
	jmp Exit

Exit:
	mov	RAX, 60				; Clean exit of the program
	mov	RDI, 0
	syscall
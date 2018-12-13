; Name		: base32dec
; Authors	: Haldimann Julian, Gasser Manuel
; Created	: 05/11/2018
; Last updated	: 15/11/2018
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
	mov	RDX, R11			; Move length to print in RDX
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

	xor R10, R10			; Reset R10 to use as counter

	; Reset buff and str for the next input
	call ResetBuffAndStr

	mov	RAX, 3				; Get input from user
	mov	RBX, 0
	mov	RCX, Buff			; Write memory address from buff
	mov	RDX, BUFFLEN		; Length that should be read
	int 80h					; Make kernel call

	mov	RBP, RAX			; Save number of bytes read
	cmp RBP, 0				; Check if there were no bytes read
	je Exit					; Exit the program if nothing was read
	xor RCX, RCX			; Reset RCX to use it in loopEndChars
	xor RBX, RBX
	
loopEndChars:
	cmp RCX,8
	je .if

	mov AL, byte [Buff+RCX]
	inc RCX
	cmp AL, "="
	jne loopEndChars

.equal:
	inc RBX
	jmp loopEndChars

.if:
	cmp RBX, 0
	ja Decode
	jmp Decode8

; Decodes 8 symbols 
Decode8:
	xor RCX, RCX			; Reset RCX register
	xor RAX, RAX			; Reset RAX register
	xor RBX, RBX			; Reset RBX register
	xor RDX, RDX			; Reset RDX register
	
.loop8:
	shl	RAX, 8				; Shift left by 1 byte
	mov AL, byte [Buff+RCX] ; Write the byte at the Buff address + counter in AL
	inc RCX					; Increment counter

	cmp RCX, 8				; Check if 8 bytes have been read from Buffer
	jne .loop8				; Repeat the loop if not

	push RCX				; Push counter on stack
	xor RCX, RCX			; Reset counter
.mask8:
	mov RBX, RAX			; Copy the RAX register into RBX
	shl	RAX, 8				; Shift left RAX by one byte to get the next 8 bits next iteration
	shr	RBX, 56				; Shift right RBX by 7 bytes to mask out the most significant byte

	cmp BL, 0Ah				; Ignore EOL
	je .mask8

	cmp BL, 40h
	jb .number8
	jmp .letter8

.letter8:
	shl RDX, 5				; Shift left RDX by 5 bits
	sub RBX, 41h			; Subtract the value of the first possible letter (41h = A) from RAX
	or DL, BL				; Move the next 5 bits from AL to DL
	inc RCX					; Increment counter

	cmp RCX, 8				; Check if all  8 bytes have been converted to original value
	jne .mask8				; If not repeat the loop
	xor RCX, RCX			; Reset counter
	shl RDX, 24
	mov R11, STRLEN
	jmp memory				

.number8:
	shl RDX, 5				; Rotate right RDX by 5 bits
	sub RBX, 18h
	or DL, BL				; Move the value into DL accoring to the decoding table
	inc RCX

	cmp RCX, 8
	jne .mask8
	xor RCX, RCX
	shl RDX, 24
	mov R11, STRLEN
	jmp memory

Decode:
	xor RAX, RAX
	mov RDX, 8
	sub RDX, RBX
	mov R9, RDX
	mov RCX, RDX
	mov R10, 8
	sub R10, RCX
	xor RCX, RCX

.loop:
	shl RAX, 8
	mov AL, byte[Buff+RCX]
	inc RCX
	cmp RDX,RCX
	jne .loop

	xor RCX, RCX
	xor RDX, RDX

	cmp RAX,0
	jne .loopshift

.loopshift:
	dec R10
	shl RAX, 8
	cmp R10,0
	je .todo
	jmp .loopshift

.todo:
	xor RCX, RCX
	cmp	RBX, 6				; Check if RBX is 6
	je .zero2

	cmp RBX, 4				; Check if RBX is 4
	je .zero4				; Jump to equal4 if RBX is 4 

	cmp RBX, 3				; Check if RBX is 3
	je .zero1				; Jump to equal3 if RBX is 1

	cmp RBX, 1				; Check if RBX is 1
	je .zero3				; Jump to equal1 if RBX is 3

.zero1:
	mov RBX, 1
	push RBX
	jmp .mask

.zero2:
	mov RBX, 2
	push RBX
	jmp .mask

.zero3:
	mov RBX, 3
	push RBX
	jmp .mask

.zero4:
	mov RBX, 4
	push RBX
	jmp .mask

.zero6:
	mov RBX, 6
	push RBX
	jmp .mask

.mask:
	mov RBX, RAX			; Copy the RAX register into RBX
	shl	RAX, 8				; Shift left RAX by one byte to get the next 8 bits next iteration
	shr	RBX, 56				; Shift right RBX by 7 bytes to mask out the most significant byte

	cmp BL, 0Ah				; Ignore EOL
	je .mask


	cmp BL, 40h
	jb .number
	jmp .letter

.letter:
	shl RDX, 5				; Shift left RDX by 5 bits
	sub RBX, 41h			; Subtract the value of the first possible letter (41h = A) from RAX
	or DL, BL				; Move the next 5 bits from AL to DL
	inc RCX					; Increment counter
	cmp RCX, R9				; Check if all bytes have been converted to original value
	jne .mask				; If not repeat the loop

	pop RBX	
	jmp .delZero

.number:
	shl RDX, 5				; Rotate right RDX by 5 bits
	sub RBX, 18h
	or DL, BL				; Move the value into DL accoring to the decoding table
	inc RCX

	cmp RCX, R9
	jne .mask

	pop RBX
	jmp .delZero

.delZero:
	shr RDX, 1
	dec RBX
	cmp RBX, 0
	jne .delZero	
	xor RCX, RCX			; Reset counter		

.roll:
	ror RDX, 8
	inc RCX
	cmp DL, 0
	jne .roll

	mov R11, RCX
	xor RCX, RCX
memory:
	rol RDX, 8
	cmp DL, 0
	je .print

	mov byte [Str+RCX], DL
	inc RCX
	cmp RCX, 5
	jne memory

.print:
	call Print

	jmp ReadBuff

Exit:
	mov	RAX, 60				; Clean exit of program
	mov	RDI, 0
	syscall

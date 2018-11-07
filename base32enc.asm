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
	BUFFLEN	equ 16			; We read the file 16 bytes at a time
	Buff: resb BUFFLEN		; Text buffer itself

	; String for output
	STRLEN	equ 32
	Str: resb STRLEN

; Text section
section .text

global _start

_start:
	nop						; This no-op keeps gdb happy...
	call Read				; Call read function
	call Convert			; Call convert function --> change name and comment
	call Print
	jmp Exit


Read:
	mov RAX, 3				; Specify sys_read call --> to change
	mov RDI, 0				; Specify File Descriptor 0: Standard Input --> to change
	mov RCX, Buff			; Move buff into 
	mov RDX, BUFFLEN		; Move size of Buff into RBX
	int	80h					; make Syscall --> to change

	mov RBP, RAX			; Save # of bytes read from file for later --> to change

; Number of bits read from input
	mov	RAX, RBP
	mov RBX, 8
	mul RBX
	mov	RBX, 5
	div	RBX
	cmp RDX, 0				; Check if RAX % RBX = 0 --> to change
	jne False

True:
	mov	R10, RAX

False:
	add RAX, 1
	mov	R10, RAX

	cmp RBP, 0				; If eax=0, sys_read reached EOF on stdin --> to change
	je Exit					; Jump If Equal (to 0, from compare) --> to change
	ret						; return

Convert:
	mov	RCX, 0				; Move 0 to the CL register for a counter
	mov	R9, 0				 
	xor RBX, RBX			; Reset the RBX register

.loop:
	mov	BL, byte [Buff+RCX]	; Get the first byte from the buff
	ror	RBX, 8				; Rotato Potato -> plz change dude
	inc	RCX					; Increment counter
	cmp	RCX, 5				; Repeat 5 times to get 5 bytes so it can be divided by 5
	jne	.loop

	shr RBX, 24
	xor	RCX, RCX
	mov	RAX, RBX
	and	RAX, 1Fh
	mov	DL, byte [CTable+RAX]
	mov byte [Str+R9], DL
	inc	R9

	; insert test if finished
	cmp R10, R9
	jne .loop
	ret

Print:
	mov	RAX, 1
	mov	RDI, 0
	mov	RSI, Str
	mov	RDX, STRLEN
	syscall
	ret


Exit:
	mov	RAX, 60			; Clean exit of the program
	mov	RDI, 0
	syscall
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
	BUFFLEN	equ 32			; We read the file 16 bytes at a time
	Buff: resb BUFFLEN		; Text buffer itself

	; String for output
	STRLEN	equ 64
	Str: resb STRLEN

; Text section
section .text

global _start

_start:


ReadBuff:
	mov	RAX, 3			; Get input from user
	mov	RDI, 0
	mov	RCX, Buff		; Write memory address from buff
	mov	RDX, BUFFLEN	; Length that should be read
	int 80h				; Make kernel call




Exit:
	mov	RAX, 60			; Clean exit of the program
	mov	RDI, 0
	syscall
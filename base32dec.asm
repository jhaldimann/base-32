; Name		: base32dec
; Authors	: Haldimann Julian, Gasser Manuel
; Created	: 05/11/2018
; Last updated	: 05/11/2018
; Description	: Small assembly program to decode data with base32

; Data section
section .data

; BSS section
section .bss
	BUFFLEN	equ 16			; We read the file 16 bytes at a time
	Buff: resb BUFFLEN		; Text buffer itself

; Text section
section .text

global _start

_start:
	nop						; This no-op keeps gdb happy...
	call Read				; Call read function
	call Loop				; Call loop function --> change name and comment


Read:
	mov RCX, Buff			; Move buff into 
	mov RDX, BUFFLEN		; Move size of Buff into RBX

	mov RAX, 3				; Specify sys_read call --> to change
	mov RBX, 0				; Specify File Descriptor 0: Standard Input --> to change
	syscall					; make Syscall

	mov RBX, RAX			; Save # of bytes read from file for later --> to change
	cmp RAX, 0				; If eax=0, sys_read reached EOF on stdin --> to change
	je Exit					; Jump If Equal (to 0, from compare) --> to change
	ret						; return

Loop:
	
	



Exit:
	mov	RAX, 60				; Clean exit of program
	mov	RDI, 0
	syscall

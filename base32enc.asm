; Name		: base32enc
; Authors	: Haldimann Julian, Gasser Manuel
; Created	: 05/11/2018
; Last updated	: 05/11/2018
; Description	: Small assembly program to encode data with base32

; Data section
section .data

; BSS section
section .bss

; Text section
section .text

global _start

_start:



Exit:
	mov	RAX, 60			; Clean exit of the program
	mov	RDI, 0
	syscall

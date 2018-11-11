; Name		: base32enc
; Authors	: Haldimann Julian, Gasser Manuel
; Created	: 05/11/2018
; Last updated	: 05/11/2018
; Description	: Small assembly program to encode data with base32

; Data section
section .data

	; Encode table
	EncTable:
		db 41h, 42h, 43h, 44h, 45h, 46h, 47h, 48h, 49h, 4Ah, 4Bh, 4Ch, 4Dh, 4Eh, 4Fh, 50h
		db 51h, 52h, 53h, 54h, 55h, 56h, 57h, 58h, 59h, 5Ah, 32h, 33h, 34h, 35h, 36h, 37h

	; End of line
	EOL: db 0Ah
	EOLLEN: equ $-EOL

; BSS section
section .bss

	; Buffer for input
	BUFFLEN	equ 5				; We read the file 16 bytes at a time
	Buff: resb BUFFLEN			; Text buffer itself

	; String for output
	STRLEN	equ 8
	Str: resb STRLEN

; Text section
section .text

global _start

; Procedures
Print:
	mov	RAX, 4				; Set mode to output (4 not 1)
	mov	RBX, 1				; Set mode to output
	mov	RCX, Str			; Move memory address of Str location in RSI
	mov	RDX, STRLEN			; Move length to print in RDX
	int 80h
	ret

ResetBuffAndStr:
	push RAX				; Push data from stack to RAX
	push RCX				; Push data from stack to RCX

	; Reset Str address
	xor RAX, RAX			; Reset data from RAX
	mov [Str], RAX			

	; Reset the Buff
	xor RCX, RCX			; Reset data from RCX
.reset:
	mov byte [Buff+RCX], AL
	inc RCX					; Increase counter
	cmp RCX, 5
	jne .reset				; Jump to reset label if not equal

	pop RCX					; Add data from stack to RCX
	pop RAX					; Add data from stack to RAX
	ret						; Return call

; Start of the program
_start:

ReadBuff:
	; Reset buff and str for the next input
	call ResetBuffAndStr

	mov	RAX, 3				; Get input from user
	mov	RBX, 0				; Get input from user
	mov	RCX, Buff			; Write memory address from buff
	mov	RDX, BUFFLEN		; Length that should be read
	int 80h					; Make kernel call

	mov	RBP, RAX			; Save number of bytes read
	cmp RBP, 0				; Check if there were no bytes read
	je Exit					; Exit the program if nothing was read
	
	cmp RBP, 5				; Check if RBP is 5
	ja Exit					; If flag is above jump to Exit

	cmp RBP, 5				; Compare if 5 bytes were read
	je	Encode5				; Jump to Convert5 if 5 bytes were read
	jmp Encode				; Jump to Convert if less than 5 bytes were read

; Converts groups of 5 bytes
Encode5:
	xor	RCX, RCX			; Reset RCX register to use it as counter
	xor	RAX, RAX			; Reset RAX register

; Shift left and not rotate
.loop5:
	shl	RAX, 8				; Shift left by 1 byte
	mov AL, byte [Buff+RCX]	; Copy the byte according to the counter in AL
	inc	RCX					; increment counter
	cmp	RCX, 5				; Check if 5th byte was copied
	jne .loop5				; Repeat the loop if 5th byte has not been read

	xor	RDX, RDX			; Reset RDX register
	xor	R10, R10			; Reset R10 register to use it as counter
	shl	RAX, 24				; Shift left RAX by 3 bytes

.mask5:
	mov	RBX, RAX			; Copy RAX into RBX
	shl RAX, 5				; Shift left RAX to get the next 5 bits the next time
	shr RBX, 59
	mov	DL, byte[EncTable+RBX]; Get the according symbol from conversion table
	mov byte[Str+R10], DL	; Move the converted symbol from DL to the Str memory address + R10
	inc R10					; increment R10 counter (counts to 8)

	cmp R10, 8				; Check if loop has been done 8 times
	jne .mask5				; Repeat the loop if not done 8 times

	call Print				; call Print procedure to print the converted symbols

	jmp ReadBuff			; Jump to ReadBuff to read the next bytes

; Converts groups of less than 5 bytes
Encode:
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
	xor RAX, RAX			; Reset the RAX register

.loop:
	shl	RAX, 8				; Shift left by 1 byte
	mov AL, byte [Buff+RCX]	; Copy the byte according to the counter in AL
	inc	RCX					; increment counter
	cmp	RCX, 5				; Check if 5th byte was copied
	jne .loop				; Repeat the loop if 5th byte has not been read

	mov	RCX, RDX			; Set the RCX register to the number of times we can convert 5 bits
	xor	RDX, RDX			; Reset RDX register
	xor R10, R10			; Reset R10 to use as counter
	shl	RAX, 24				; Shift left RAX by 3 bytes

.mask:
	mov	RBX, RAX			; Copy RAX into RBX
	shl RAX, 5				; Shift right RAX to get the next 5 bits the next time
	shr RBX, 59				; TO BE DONE
	mov	DL, byte[EncTable+RBX]; Get the according symbol from conversion table
	mov byte[Str+R10], DL	; Move the converted symbol from DL to the Str memory address + R10
	dec RCX					; Decrease RCX
	inc R10					; Increase R10

	cmp RCX, 0				; Check if loop has been the number of times we can convert 5 bits
	jne .mask				; Repeat the loop if not

	pop RBX					; Tell the number of bits added to RBX

	xor RCX, RCX			; Reset RCX

	cmp	RBX, 2				; Check if RBX is 2
	jmp equal6				; Jump to equal6 if RBX is 2

	cmp RBX, 4				; Check if RBX is 4
	jmp equal4				; Jump to equal4 if RBX is 4 

	cmp RBX, 1				; Check if RBX is 1
	jmp equal3				; Jump to equal3 if RBX is 1

	cmp RBX, 3				; Check if RBX is 3
	jmp equal1				; Jump to equal1 if RBX is 3

equal6:
	mov byte[Str+R10], 3Dh	; TO BE DONE
	inc R10					; Increase R10
	inc RCX					; Increase RCX
	cmp RCX, 6				; Check if RCX is 6
	jne equal6				; If not jump to equal6
	call Print				; Call Print function
	jmp Exit				; Jump to exit label

equal4:
	mov byte[Str+R10], 3Dh	; TO BE DONE
	inc R10					; Increase R10
	inc RCX					; Increase RCX
	cmp RCX, 4				; Check if RCX is 4
	jne equal4				; If not jump to equal4
	call Print				; Call Print function
	jmp Exit				; Jump to exit label

equal3:
	mov byte[Str+R10], 3Dh	; TO BE DONE
	inc R10					; Increase R10
	inc RCX					; Increase RCX
	cmp RCX, 3				; Check if RCX is 3
	jne equal3				; If not jump to equal3
	call Print				; Call Print function
	jmp Exit				; Jump to exit label

equal1:
	mov byte[Str+R10], 3Dh	; TO BE DONE
	inc R10					; Increase R10
	inc RCX					; Increase RCX
	cmp RCX, 1				; Check if RCX is 1
	jne equal1				; If not jump to equal 1
	call Print				; Call Print function
	jmp Exit				; Jump to exit label

Exit:
	; Print end of line at the end
	mov	RAX, 1				;
	mov	RDI, 1				;
	mov	RSI, EOL			; Move memory address of Str location in RSI
	mov	RDX, EOLLEN			; Move length to print in RDX
	syscall

	mov	RAX, 60				; Clean exit of the program
	mov	RDI, 0				; Clean exit of the progeam
	syscall					; Make system call
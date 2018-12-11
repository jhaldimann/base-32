; Name			: base32enc
; Authors		: Haldimann Julian, Gasser Manuel
; Created		: 05/11/2018
; Last updated	: 15/11/2018
; Description	: Small assembly program to encode data to base32

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
	STRLEN	equ 1
	Str: resb STRLEN

; Text section
section .text

global _start

; Procedures
Print:
	push RAX
	push RCX
	push R9
	mov	RAX, 4				;
	mov	RBX, 1				;
	mov	RCX, Str			; Move memory address of Str location in RSI
	mov	RDX, STRLEN			; Move length to print in RDX
	int 80h
	pop R9
	pop RCX
	pop RAX
	ret

ResetBuffAndStr:
	push RAX				; Push data from stack to RAX
	push RCX				; Push data from stack to RCX

	; Reset Str address
	xor RAX, RAX			; Reset data from RAX
	mov byte[Str], AL			

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
	xor R9, R9				; Reset the R9 register to use as counter for written bytes

ReadBuff:
	; Read the input into the Buff
	mov	RAX, 3				; Get input
	mov RBX, 0 				; Get input
	mov RCX, Buff			; Write memory address from buff to RCX
	mov RDX, BUFFLEN		; Length that should be read

	push R9					; Push the counter to the stack to not get reset
	int 80h					; Make kernel call
	pop R9

	; placeholder
	mov RBP, RAX			; Save number of bytes read to RBP

	cmp RBP, 0				; If no bytes were read jump to exit
	je Exit

	jmp Encode

; Converts the input with base 32 encoding 
Encode:
	; Get the nmber of bits to add
	mov	RAX, RBP			; Copy the number of bytes read in RAX
	mov	RBX, 8				; Move the multyplier 8 to RBX
	mul	RBX					; Multiply the number of bytes read by 8 to get the number of bits
	mov	RBX, 5				; Move the divisor 5 to RBX
	div	RBX					; Divide the number of bits read by 5
	mov RBX, 5				; Move number of bits necessary for conversion to RBX 
	sub	RBX, RDX			; Subtract the rest of the division from 5 to get the number of bits needed to add
	push RBX				; Push the number of bits to add on the stack


	xor RCX, RCX			; Reset RCX to count the bytes copied
	xor RAX, RAX			; Reset RAX to copy the input in

.copy:
	shl RAX, 8				; Shift left by 1 byte
	mov AL, byte[Buff+RCX]	; Copy byte according to the counter in AL
	inc RCX					; Increment the counter

	cmp RCX, 5				; Check if 5 bytes have been copied from memory
	jne .copy

	xor RDX, RDX			; Reset RDX
	xor RCX, RCX			; Reset RCX register to use as counter
	shl RAX, 24				; Shift left RAX by 3 bytes

.mask:
	cmp R9, 76				; Check if 76 bytes have been converted
	jne .continue

	mov byte[Str], 0Ah
	call Print
	xor R9, R9

.continue:
	inc R9					; Increment the bytes converted counter
	mov RBX, RAX			; Copy the input into RBX
	shl RAX, 5				; Shift left RAX to get the next 5  bits the next iteration
	shr RBX, 59				; Mask out the needed 5 bits
	mov DL, byte [EncTable+RBX] ; Get the according symbol from the encoding table
	mov byte[Str], DL		; Move the converted symbol in the output memory
	call Print				; Print converted byte to output
	inc RCX					; Increment the counter

	cmp RBP, 
	cmp RCX, 8			; Check if all bytes read have been converted and printed to output
	jne .mask

	cmp RBP, 5				; If 5 bytes have been read, read the next input
	je ReadBuff

	xor RCX, RCX			; Reset counter
	pop RBX					; Pop the number of bits to add from stack

	cmp	RBX, 2				; Check if RBX is 2
	jmp equal6				; Jump to equal6 if RBX is 2

	cmp RBX, 4				; Check if RBX is 4
	jmp equal4				; Jump to equal4 if RBX is 4 

	cmp RBX, 1				; Check if RBX is 1
	jmp equal3				; Jump to equal3 if RBX is 1

	cmp RBX, 3				; Check if RBX is 3
	jmp equal1				; Jump to equal1 if RBX is 3

equal6:
	mov byte[Str], 3Dh		; Move = symbol to output memory
	inc RCX					; Increment counter
	call Print				; Print the output
	
	cmp RCX, 6				; If 6x = has been printed jump to exit
	jne equal6
	jmp Exit

equal4:
	mov byte[Str], 3Dh		; Move = symbol to output memory
	inc RCX					; Increment counter
	call Print				; Print the output
	
	cmp RCX, 4				; If 4x = has been printed jump to exit
	jne equal4
	jmp Exit

equal3:
	mov byte[Str], 3Dh		; Move = symbol to output memory
	inc RCX					; Increment counter
	call Print				; Print the output
	
	cmp RCX, 3				; If 3x = has been printed jump to exit
	jne equal3
	jmp Exit

equal1:
	mov byte[Str], 3Dh		; Move = symbol to output memory
	inc RCX					; Increment counter
	call Print				; Print the output
	
	cmp RCX, 1				; If 1x = has been printed jump to exit
	jne equal1
	jmp Exit

Exit:
	; Print end of line at the end
	mov	RAX, 4				;
	mov	RBX, 1				;
	mov	RCX, EOL			; Move memory address of Str location in RSI
	mov	RDX, EOLLEN			; Move length to print in RDX
	int 80h

	mov	RAX, 60				; Clean exit of the program
	mov	RDI, 0				; Clean exit of the progeam
	syscall					; Make system call
; Name			: base32dec
; Authors		: Haldimann Julian, Gasser Manuel
; Created		: 05/11/2018
; Last updated	: 16/12/2018
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
	mov	RAX, 4				; Set mode to output
	mov	RBX, 1				; Set mode to output
	mov	RCX, Str			; Move memory address of Str location in RSI
	mov	RDX, R11			; Move length to print in RDX
	int 80h
	ret

ResetBuffAndStr:
	push RAX				; Push value of RAX to the stack
	push RCX				; Push value of RCX to the stack

	; Reset Str address
	xor RAX, RAX			; Reset the RAX register
	mov [Buff], RAX			; Move value of the RAX register to the Buff

	; Reset the Buff
	xor RCX, RCX			; Reset the RCX register
.reset:
	mov byte [Str+RCX], AL	;
	inc RCX					; Increase the value of RCX by 1
	cmp RCX, 5				; Compare the RCX value with 5
	jne .reset				; If RCX is not 5 jump to reset

	pop RCX					; Add the first entry of the stack to the RCX register
	pop RAX					; Add the second entry of the stack to the RAX register
	ret

; Start of the program
_start:

ReadBuff:
	xor R10, R10			; Reset R10 to use as counter
	call ResetBuffAndStr	; Reset buff and str for the next input
	mov	RAX, 3				; Get input from user
	mov	RBX, 0				; Get input from user
	mov	RCX, Buff			; Write memory address from buff
	mov	RDX, BUFFLEN		; Length that should be read
	int 80h					; Make kernel call
	mov	RBP, RAX			; Save number of bytes read
	cmp RBP, 0				; Check if there were no bytes read
	je Exit					; Exit the program if nothing was read
	xor RCX, RCX			; Reset RCX to use it in loopEndChars
	xor RBX, RBX
	
loopEndChars:
	cmp RCX,8				; Check if the counter(RCX) equals to 8
	je .if					; If counter is 8 jump to the if label

	mov AL, byte [Buff+RCX]
	inc RCX					; Incremenet the counter (RCX)
	cmp AL, "="				; Check if the AL is an =
	jne loopEndChars		; If not repeat the loop

.equal:
	inc RBX					; Increment the RBX register by 1
	jmp loopEndChars		; Jump to the loopEndChars again

.if:
	cmp RBX, 0				; If RBX equals to 0
	ja Decode				; If RBX is higher jump to Decode label 
	jmp Decode8				; Jump to Decode8 function

ReadOneByte:
	call ResetBuffAndStr	; Reset buff and str for the next input
	mov	RAX, 3				; Get input from user
	mov	RBX, 0
	mov	RCX, Buff			; Write memory address from buff
	mov	RDX, 1				; Length that should be read
	int 80h					; Make kernel call
	cmp RAX, 0				; Check if there were no bytes read
	je Exit					; Exit the program if nothing was read

; Decodes 8 symbols 
Decode8:
	xor RCX, RCX			; Reset RCX register
	xor RAX, RAX			; Reset RAX register
	xor RBX, RBX			; Reset RBX register
	xor RDX, RDX			; Reset RDX register
	jmp .loop8

.setflag8:
	mov R11, 1				; Set the R11 register to 1
	jmp .mask8				; Jump to the mask8 label

.loop8:
	shl	RAX, 8				; Shift left by 1 byte
	mov AL, byte [Buff+RCX] ; Write the byte at the Buff address + counter in AL
	inc RCX					; Increment counter

	cmp RCX, 8				; Check if 8 bytes have been read from Buffer
	jne .loop8				; Repeat the loop if not

	push RCX				; Push counter on stack
	xor RCX, RCX			; Reset counter
	mov R11, 0				; Set R11 to 0


.mask8:
	mov RBX, RAX			; Copy the RAX register into RBX
	shl	RAX, 8				; Shift left RAX by one byte to get the next 8 bits next iteration
	shr	RBX, 56				; Shift right RBX by 7 bytes to mask out the most significant byte

	cmp BL, 0Ah				; Ignore EOL
	je .setflag8			; If the value of BL is an EOL jump to the function

	cmp BL, 40h				; Compare the BL register with 8 bytes
	jb .number8				; If the value is bellow jump to the number8 label
	jmp .letter8			; Else jump the letter8 label

.letter8:
	shl RDX, 5				; Shift left RDX by 5 bits
	sub RBX, 41h			; Subtract the value of the first possible letter (41h = A) from RAX
	or DL, BL				; Move the next 5 bits from AL to DL
	inc RCX					; Increment counter

	cmp RCX, 8				; Check if all  8 bytes have been converted to original value
	jne .mask8				; If not repeat the loop
	xor RCX, RCX			; Reset counter
	shl RDX, 24				; Shift left the RDX register by 3 bytes
	mov R11, STRLEN			; Move the string length to the R11 register
	jmp memory				; Jump to the memory function

.number8:
	shl RDX, 5				; Rotate right RDX by 5 bits
	sub RBX, 18h
	or DL, BL				; Move the value into DL accoring to the decoding table
	inc RCX					; Increment the counter by 1

	cmp RCX, 8				; Compare the Counter with 8
	jne .mask8				; If not jump to the mask8 label
	xor RCX, RCX			; Reset the counter(RCX)
	shl RDX, 24				; Shift left the RDX label by 3 bytes
	mov R11, STRLEN			; Move the string length to the R11 register
	jmp memory				; Jump to the memory function

Decode:
	xor RAX, RAX			; First of all reset the RAX register
	mov RDX, 8				; Move 8 to the RDX
	sub RDX, RBX			; Subtract the RBX register from RDX
	mov R9, RDX				; Move the result to the R9 register
	mov RCX, RDX			; Move the result to the RCX register
	mov R10, 8				; Move 1 byte to the R10 register
	sub R10, RCX			; Subtract the RCX from the R10 register
	xor RCX, RCX			; Reset the RCX register
	jmp .loop				; Jump to the loop label

.setflag:
	mov R11, 1				; Set the R11 register to 1
	jmp .mask				; Jump to the mask label

.loop:
	shl RAX, 8				; Shift left the RAX register by 1 byte
	mov AL, byte[Buff+RCX]	;
	inc RCX					; Increment the counter(RCX) by 1
	cmp RDX,RCX				; Compare the RCX with the RDX register
	jne .loop				; If not equal repeat the loop

	xor RCX, RCX			; Reset the RCX 
	xor RDX, RDX			; Reset the RDX

	cmp RAX,0				; Check if the RAX register equals to 0
	jne .loopshift			; If not jump to the loopshift

.loopshift:
	dec R10					; Decrement R10 by 1
	shl RAX, 8				; Shift left the RAX register by one byte
	cmp R10, 0				; Compare the R10 Register with 0
	je .todo				; If R10 is 0 jump to todo
	jmp .loopshift			; Else jump to the loopshift

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
	mov RBX, 1				; Set RBX to 1
	push RBX				; Push the RBX value to the stack
	jmp .mask				; Jump again to the mask label

.zero2:
	mov RBX, 2				; Set RBX to 2
	push RBX				; Push the RBX value to the stack
	jmp .mask				; Jump again to the mask label

.zero3:
	mov RBX, 3				; Set RBX to 3
	push RBX				; Push the RBX value to the stack
	jmp .mask				; Jump again to the mask label

.zero4:
	mov RBX, 4				; Set RBX to 4
	push RBX				; Push the RBX value to the stack
	jmp .mask				; Jump again to the mask label

.zero6:
	mov RBX, 6				; Set RBX to 6
	push RBX				; Push the RBX value to the stack
	jmp .mask				; Jump again to the mask label

.mask:
	mov RBX, RAX			; Copy the RAX register into RBX
	shl	RAX, 8				; Shift left RAX by one byte to get the next 8 bits next iteration
	shr	RBX, 56				; Shift right RBX by 7 bytes to mask out the most significant byte

	cmp BL, 0Ah				; Ignore EOL
	je .setflag				; Jump to the setflag label


	cmp BL, 40h				; Compare the BL register with 64
	jb .number				;
	jmp .letter				; Else jump to the letter label

.letter:
	shl RDX, 5				; Shift left RDX by 5 bits
	sub RBX, 41h			; Subtract the value of the first possible letter (41h = A) from RAX
	or DL, BL				; Move the next 5 bits from AL to DL
	inc RCX					; Increment counter
	cmp RCX, R9				; Check if all bytes have been converted to original value
	jne .mask				; If not repeat the loop

	pop RBX					; Move the first entry of the stack to RBX
	jmp .delZero			; Jump to the .delZero label

.number:
	shl RDX, 5				; Rotate right RDX by 5 bits
	sub RBX, 18h			; Subtracting 18 from RBX
	or DL, BL				; Move the value into DL accoring to the decoding table
	inc RCX					; Increment the counter RCX

	cmp RCX, R9				; Compare the counter with R9
	jne .mask				; If not jump to the mask label

	pop RBX					; Move the first value of the stack to the RBX
	jmp .delZero			; Jump to the delZero label

.delZero:
	shr RDX, 1				; Shift right the RDX by 1 bit
	dec RBX					; Decrement the counter(RBX) by 1
	cmp RBX, 0				; Compare the counter with 0
	jne .delZero			; If RBX not 0 repeat
	xor RCX, RCX			; Reset counter		

.roll:
	ror RDX, 8
	inc RCX					; Increment RCX by 1
	cmp DL, 0				; Compare the counter(DL) register with 0
	jne .roll				; If DL not 0 repeat the loop

	mov R11, RCX			; Move the RCX value to R11
	xor RCX, RCX			; Reset the RCX register

memory:
	rol RDX, 8		
	cmp DL, 0				; Compare the DL register with 0	
	je .print				; If DL is equal to 0 start to print

	mov byte [Str+RCX], DL
	inc RCX					; Increment the counter 
	cmp RCX, 5				; Compare the counter with 5
	jne memory				; If the counter is not 5 repeat the loop

.print:
	call Print				; Call the Print function

	jmp ReadBuff			; Jump to the ReadBuff function

Exit:
	mov	RAX, 60				; Clean exit of program
	mov	RDI, 0
	syscall

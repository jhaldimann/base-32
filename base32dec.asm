; Name			: base32dec
; Authors		: Haldimann Julian, Gasser Manuel
; Created		: 05/11/2018
; Last updated	: 28/12/2018
; Description	: Small assembly program to decode data that was encoded with base32

SECTION .bss					
	BUFFLEN	equ 1				; Just read one byte
	Buff: resb BUFFLEN			; Define the buffer here
	RESULT equ 1				; Define the result here
	Char: resb RESULT			; Define how long the result should be
	
SECTION .data
	Table: 	db 1Ah,1Bh,1Ch,1Dh,1Eh,1Fh,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
			db 01h,02h,03h,04h,05h,06h,07h,08h,09h,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh,10h
			db 11h,12h,13h,14h,15h,16h,17h,18h,19h,00h,00h,00h,00h,00h,00h,00h
	
SECTION .text
	
GLOBAL _start

; Definitions of function

; Read the input of the user
ReadBuff:
	; Input:	RAX -> Buff address
	; 			RBX -> Length to read

	; Push everything on stack because of the syscall
	push RCX
	push RDX
	push RSI
	push RDI
	push R8
	mov RSI,RAX					; Move the input to the RSI register
	mov RDX,RBX					; Move the lenght of the input to the RDX register
	mov RDI,0					; Set RDI to 0
	mov RAX,0					; Set RAX to 0

	syscall						; Get input

	; Now you can get everything back from the stack
	pop R8
	pop RDI
	pop RSI
	pop RDX
	pop RCX
	ret

PrintString:
	; Input:	RAX -> Char address
	; 			RBX -> Output length

	; Push everything to stack because of the syscall
	push RCX
	push RDX
	push RDI
	push R8
	push R10

	mov RSI,RAX					; Write the input to the RSI register					
	mov RDX,RBX					; Move the length to the RDX register
	; Set mode to output
	mov RAX, 1
	mov RDI, 1
	syscall						; Make syscall
	
	; Return the values to the old registers
	pop R10
	pop R8
	pop RDI
	pop RDX
	pop RCX
	ret

; Start of program
_start:
	
Read:
	mov RAX, Buff				; Move the buffer content (user input) to RAX 		
	mov RBX, BUFFLEN			; Move the length of the buffer to the RBX
	call ReadBuff				; Call the ReadBuff function
	mov RBP, RAX				; Move number of read bytes into RBP
	cmp RBP, 0					; Check if no bytes are read
	je Exit						; If no bytes are read jump to exit
	mov DL, byte [Buff]			; Move one byte of the buffer into the DL register
	cmp DL, 0Ah					; Compare the byte with a EOL
	je Read						; If the byte was an EOL continue with loop (skip this byte)
	cmp DL, "="					; Compare the read byte with a "="
	jne NotEqual				; If the read byte is not a "=" jump to the NotEqual label
	inc R8						; Increment the "=" counter R8 by 1
	jmp IsEqual					; Else jump to the isEqual label

NotEqual:						
	sub RDX, 32H				; Subtract 32H to get the correct letter or number from the decode-table 
	mov CL, byte [Table+RDX]	; Move the calculated char into the CL register
	add RDI, RCX				; Add the RCX content to the RDI register

IsEqual:
	inc RSI						; Increment the counter by 1
	shl RDI, 5					; Shift left by 5 bits
	cmp RSI, 8					; Compare the counter with 8 
	je Translate				; If RSI is equal to 8 jump to Translate 
	jmp Read					; Else jump to Read
	
Translate:
	shr RDI, 5					; Shift right the RDI by 5 bits
	mov R10, RDI				; Move the shifted bits in the R10 
	; Reset the registers
	xor RDI, RDI
	xor RCX, RCX
	xor RDX, RDX

	mov CL, 28H					; Move 28H to the CL register
	
	; Jump to the specific equal label to count up RDI
	cmp R8, 6					
	je Equal6					

	cmp R8, 4
	je Equal4

	cmp R8, 3
	je Equal3

	cmp R8, 1
	je Equal1

	jmp Print					
	
Equal6:							
	add RDI, 8					
	
Equal4:							
	add RDI, 8					
	
Equal3:							
	add RDI, 8					
	
Equal1:							
	add RDI, 8					
	
; Print the string we converted
Print:
	mov RDX, R10				; Move converted output to RDX
	sub CL, 8					; Subtract 8 from CL 
	shr RDX, CL					; Shift right the output by CL
	mov byte [Char], DL			; Write byte to be printed in Char
	mov RAX, Char				; Move Char address to RAX
	mov RBX, RESULT				; Move output length to RBX
	call PrintString			; Print out the string
	cmp RCX, RDI				; Compare the length of the Buff with the RCX
	jne Print					; If not jump to the Print function

	; Reset the registers 
	xor RCX, RCX
	xor RDX, RDX
	xor RSI, RSI
	xor RDI, RDI
	xor R8, R8

	jmp Read					
	
; Clean exit of the program
Exit:
	mov RAX, 3CH				; Make clean exit (syscall)
	mov RDI, 0					; Make clean exit
	syscall
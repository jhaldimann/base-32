; Name			: base32dec
; Authors		: Haldimann Julian, Gasser Manuel
; Created		: 05/11/2018
; Last updated	: 18/12/2018
; Description	: Small assembly program to decode data with base32

SECTION .bss					
	BUFFLEN	equ 1				; Just read one byte
	Buff: resb BUFFLEN			; Define here the Buffer
	RESULT equ 1				; Define here the result
	Char: resb RESULT			; Define how long the result should be
	
SECTION .data
	Table: 	db 1Ah,1Bh,1Ch,1Dh,1Eh,1Fh,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
			db 01h,02h,03h,04h,05h,06h,07h,08h,09h,0Ah,0Bh,0Ch,0Dh,0Eh,0Fh,10h
			db 11h,12h,13h,14h,15h,16h,17h,18h,19h,00h,00h,00h,00h,00h,00h,00h
	
SECTION .text
	
GLOBAL 	_start

_start:
	
Read:
	mov RAX, Buff				; Move the buffer content (user input) to RAX 		
	mov RBX, BUFFLEN			; Move the length of the buffer to the RBX
	call ReadBuff				; Call the ReadBuff function
	mov RBP, RAX				; Move the buffer content into the RBX register
	cmp RBP, 0					; Check if the buffer is 0
	je Exit						; If buffer is empty jump to the Exit function
	mov DL, byte [Buff]			; Move one byte of the buffer into the DL register
	cmp DL, 0Ah					; Compare the byte with a EOL
	je Read						; If the byte was an EOL continue with loop (skip this type)
	cmp DL, "="					; Compare the read byte with a "="
	jne NotEqual				; If the read byte is not a = jump to the NotEqual function
	inc R8						; Increment the R8 by 1
	jmp IsEqual					; Else jump to the isEqual method

; Read the input of the user
ReadBuff:
	; Push everything because of the syscall (user input)
	push RCX					; Save the RCX value in the stack
	push RDX					; Save the RDX value in the stack
	push RSI					; Save the RSI value in the stack
	push RDI					; Save the RDI value in the stack
	push R8						; Save the R8 Value in the stack
	mov RSI,RAX					; Move the input to the RSI register
	mov RDX,RBX					; Move the lenght of the input to the RDX register
	mov RDI,0					; Set RDI to 0 (for user input)
	mov RAX,0					; Set RAX to 0

	syscall						; Get input of user here 

	; Now you can get everything back from the stack
	pop R8						; Add the value back to the R8 register
	pop RDI						; Add the value back to the RDI register
	pop RSI						; Add the value back to the RSI register
	pop RDX						; Add the value back to the RDX register
	pop RCX						; Add the value back to the RCX register
	ret

PrintString:
	; Push everything to stack because of the syscall
	push RCX					; Add value of RCX to stack
	push RDX					; Add value of RDX to stack
	push RDI					; Add value of RDI to stack
	push R8						; Add value of R8 to stack
	push R10					; Add value of R10 to stack

	mov RSI,RAX					; Write the user input to the RSI register					
	mov RDX,RBX					; Move the length to the RDX register
	mov RAX, 1					; Set mode to output
	mov RDI, 1					; Set mode to output
	syscall						; Make syscall
	
	; Return the values to the old registers
	pop R10						; Get value back of R10
	pop R8						; Get value back of r8
	pop RDI						; Get value back of RDI
	pop RDX						; Get value back of RDX
	pop RCX						; Get value back of Rcs
	ret

NotEqual:						
	sub RDX, 32H				; Subtract 50 to get the correct letter or number 
	mov CL, byte [Table+RDX]	; Move the calculatet char into the CL register
	add RDI, RCX				; Add the RCX content to the RDI register

IsEqual:
	inc RSI						; Increment the counter by 1
	shl RDI, 5					; Shift left by 5 bits
	cmp RSI, 8					; Compare the counter with 8 
	je Translate				; If RSI is equal to 8 jump to 
	jmp Read					; Else jump to Read
	
Translate:
	shr RDI, 5					; Shift the RDI by 5 bytes
	mov R10, RDI				; Move the shifted bits in the R10 
	xor RDI, RDI				; Reset the RDI register
	xor RCX, RCX				; Reset the RCX register
	xor RDX, RDX				; Reset the RDX register
	mov RDI, 0					; Set RDI to 0
	mov CL, 28H					; 
	
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
	
; Method to print the string we converted
Print:
	mov RDX, R10							
	sub CL, 8					
	shr RDX, CL					
	mov byte [Char], DL			
	mov RAX, Char				
	mov RBX, RESULT				; Set the output to print
	call PrintString			; Print out the string in the console
	cmp RCX, RDI				; Compare the length of the Buff with the RCX
	jne Print					; If not jump to the Print function
	xor RCX, RCX				; Reset register RCX
	xor RDX, RDX				; Reset register RDX
	xor RSI, RSI				; Reset register RSI
	xor RDI, RDI				; Reset register RDI
	xor R8, R8					; Reset register R8
	jmp Read					
	
; Clean exit of the program
Exit:
	mov RAX, 3CH				; Make clean exit (syscall)
	mov RDI, 0					; Make clean exit
	syscall
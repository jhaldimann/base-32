; Name			: base32dec
; Authors		: Haldimann Julian, Gasser Manuel
; Created		: 05/11/2018
; Last updated	: 16/12/2018
; Description	: Small assemBLy program to decode data with base32

; Data section
SECTION .bss					; Section of uninitialised data
	BUFFLEN	equ 1				; read the input 1 byte
	Buff: resb BUFFLEN			; Text buffer
	RESULT equ 1				; result for translated 5bit pairs
	Char: resb RESULT			; length of result
	
SECTION .data
	; reverse table to get 5 bit value from ASCII value -50 as offset
	Table: db 26,27,28,29,30,31,0,0,0,0,0,0,0,0,0,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25
	TABLELEN equ $-Table
	
SECTION .text		; Section of code
	
GLOBAL 	_start

_start:
	
Read:
	mov RAX, Buff				; Offset of Buffer to RAX
	mov RBX, BUFFLEN			; Number of bytes to read to RBX
	call ReadBuff				; Call ReadBuff
	mov RBP, RAX				; Save # of bytes read from file
	cmp RBP, 0					; If RBP=0, sys_read reached EOF on stdin	
	je Exit						; If RBP is equal to 0 jump to exit (nothing todo here)
	mov DL, byte [Buff]			; get the read byte to RDX
	;cmp DL,13					; if its CR
	;je Read			
	cmp DL, 10					; or LF (CRLF is a new line, skip that)
	je Read						; Read the next byte
	cmp DL, "="					; if its a "="
	jne NotEquiv
	inc R8						; Increment the counter by 1
	jmp IsEquiv					; Jump to the function ...

ReadBuff:
	; Input:
	;  RAX -> where to read
	;  RBX -> number of characters to read
	; Output:
	;  RAX -> number of read input

	; Push everything because of the syscall
	push RCX					; Save the RCX value in the stack
	push RDX					; Save the RDX value in the stack
	push RSI					; Save the RSI value in the stack
	push RDI					; Save the RDI value in the stack
	push R8						; Save the R8 Value in the stack
	mov RSI,RAX					; Move the input to the RSI register
	mov RDX,RBX					; Move the lenght of the input to the RDX register
	mov RAX,0					; Specify sys_read call
	mov RDI,0					; Specify File Descriptor 0: Standard Input
	syscall
	; Now you can get everything back from the stack
	pop R8						; Add the value back to the R8 register
	pop RDI						; Add the value back to the RDI register
	pop RSI						; Add the value back to the RSI register
	pop RDX						; Add the value back to the RDX register
	pop RCX						; Add the value back to the RCX register
	ret

PrintString:
	; Input:
	;  RAX -> address to print out
	;  RBX -> length of address to print
	; Output:
	;  Prints eax to console
	
	; Push everything to stack because of the syscall
	push RCX					; Add value of RCX to stack
	push RDX					; Add value of RDX to stack
	push RDI					; Add value of RDI to stack
	push R8						; Add value of R8 to stack
	push R9						; Add value of R9 to stack
	mov RSI,RAX					; input to correct register
	mov RDX,RBX					; lenght to correct register
	mov RAX, 1					; Set mode to output
	mov RDI, 1					; Set mode to output
	syscall						; Make syscall
	
	; Return the values to the old registers
	pop R9						; Get value back of R9
	pop R8						; Get value back of r8
	pop RDI						; Get value back of RDI
	pop RDX						; Get value back of RDX
	pop RCX						; Get value back of Rcs
	
	ret

NotEquiv:						; standard case
	sub RDX, 32h				; remove 32h from ascii vALue of read character, this helps keeping the translation table smaller
	mov CL, byte [Table+RDX]	; use the ascii value -50 as offset to get the 5bit value to CL
	add RDI, RCX				; add RCX to RDI, had an issue with keeping the result in RCX, adding solved this

IsEquiv:
	inc RSI						; increase counter for read bytes (will continue when 8)
	shl RDI, 5					; shift 5 bits left
	cmp RSI, 8					; continue translating if 8 bytes are read
	je Translate				; If RSI is 8 jump to the Translate function
	
	jmp Read					; continue reading buffer
	
Translate:
	shr RDI, 5					; because of loop in Read we shift one too many, shift it back
	mov R9, RDI					; keep a backup of our shifted 5 bit pairs in R9 (40 bits together)
	xor RDI, RDI				; Reset the RDI register
	xor RCX, RCX				; Reset the RCX register
	xor RDX, RDX				; Reset the RDX register
	mov RDI, 0					; RDI holds the vALue where to stop printing
	mov CL, 40					; RCX holds the vALue how much shifting is needed to get 8 bits to print
	
	cmp R8, 6					; different cases for = occurences
	je Equiv6					; go to according case
	cmp R8, 4
	je Equiv4
	cmp R8, 3
	je Equiv3
	cmp R8, 1
	je Equiv1
	jmp Print					; default case is no =
	
	
Equiv6:							; print 1 byte
	add RDI, 8					; 6 = has to stop after 1 printed byte -> need 32
	
Equiv4:							; print 2 bytes
	add RDI, 8					; 4 = has to stop after 2 printed bytes -> need 24
	
Equiv3:							; print 3 bytes
	add RDI, 8					; 3 = has to stop after 3 printed bytes -> 16
	
Equiv1:							; print 4 bytes
	add RDI, 8					; 1 = has to stop after 4 printed bytes -> 8
	
Print:							; print 5 bytes
	mov RDX, R9					; get the backup in RDX to work with
	sub CL, 8					; remove 8 from RCX for the correct shifting
	shr RDX, CL					; shift the first 8 bit
	mov byte [Char], DL			; put it in Char
	mov RAX, Char				; and print Char
	mov RBX, RESULT				; length of Char
	call PrintString			; print to console
	cmp RCX, RDI				; compare RCX with RDI (either 0 or set by amount of = above)
	jne Print					; print next if no match
	xor RCX, RCX				; Reset register RCX
	xor RDX, RDX				; Reset register RDX
	xor RSI, RSI				; Reset register RSI
	xor RDI, RDI				; Reset register RDI
	xor R8, R8					; Reset register R8
	jmp Read					; Jump back to the Read function
	
; Clean exit of the program
Exit:
	mov RAX, 60					; Make clean exit (syscall)
	mov RDI, 0					; Make clean exit
	syscall

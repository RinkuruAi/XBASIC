; [ STRING OUTPUT ]
; - INPUT
;   + DS:SI : String address
_stringOutput:
	; Store registers
	push	ax
	push	si

	; Set character output interrupt
	mov	ah,0x0E

	; Load character at address DS:SI to AL and increase address to the next character
@@:	lodsb

	; Check if it is stop output character (0x03)
	cmp	al,0x03

	; If yes, exit the loop
	je	@f

	; If not, print the character
	int	0x10

	; Repeat those steps
	jmp	@b

	; Restore registers
@@:	pop	si
	pop	ax

	; Exit procedure
	ret
org	0x0000

	jmp	main

KERNEL_LOCK	db	"@XBASIC"

var:
BASIC_BOOTMSG	db	"XBASIC V0.0.0 by Rinkuru Ai",0x03
BASIC_PROMPT	db	"] ",0x03

INPUT_SEGMENT	dw	0x7000
INPUT_OFFSET	dw	0x0000
INPUT_MAX	dw	255

TEXT_BKSP	db	0x08,0x20,0x08,0x03
TEXT_CRLF	db	0x0A,0x0D,0x03

_stringInput:
	push	ax
	push	cx

	xor	cx,cx

	jmp	.run

.bksp:
	cmp	cx,0
	je	@f

	dec	di
	dec	cx

	push	si

	mov	si,TEXT_BKSP
	call	_stringOutput

	pop	si

@@:	jmp	.run

.run:
@@:	mov	ah,0x00
	int	0x16

	cmp	al,0x08
	je	.bksp

	cmp	al,0x0D
	je	.stop

	cmp	cx,[INPUT_MAX]
	je	@b

	stosb

	inc	cx

	mov	ah,0x0E
	int	0x10

	jmp	@b

.stop:
	cmp	cx,[INPUT_MAX]
	je	@f

	mov	byte [di],0x03

@@:	pop	cx
	pop	ax

	ret

_stringOutput:
	push	ax
	push	si

	mov	ah,0x0E

@@:	lodsb

	cmp	al,0x03
	je	@f

	int	0x10

	jmp	@b

@@:	mov	ah,0x0E

	pop	si
	pop	ax

	ret

main:
	mov	ax,cs
	mov	ds,ax
	
	mov	ax,[INPUT_SEGMENT]
	mov	es,ax

	mov	si,BASIC_BOOTMSG
	call	_stringOutput

	mov	si,TEXT_CRLF
	call	_stringOutput

@@:	mov	si,BASIC_PROMPT
	call	_stringOutput

	mov	di,[INPUT_OFFSET]
	call	_stringInput

	mov	si,TEXT_CRLF
	call	_stringOutput

	jmp	@b
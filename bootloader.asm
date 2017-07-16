org	0x7C00

	jmp	main

var:
KERNEL_SEGMENT	dw	0x1000
KERNEL_OFFSET	dw	0x0000

KERNEL_KEY	db	"@XBASIC"
KERNEL_KEYSIZE	dw	6
KERNEL_KEYLIMIT	dw	4

ERROR_CORRUPTDRIVE	db	">> DRIVE IS CORRUPTED",0x03
ERROR_KERNELNOTFOUND	db	">> KERNEL NOT FOUND",0x03

_BIOSReboot:
	mov	ax,0x0040
	mov	ds,ax

	mov	word [0x0072],0x0000
	jmp	0xFFFF:0x0000

_getKeystroke:
	push	ax

	mov	ah,0x00
	int	0x16

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

@@:	pop	si
	pop	ax

	ret

_ERROR:
	jmp	_BIOSReboot

	.CORRUPTDRIVE:
		mov	si,ERROR_CORRUPTDRIVE
		call	_stringOutput

		call	_getKeystroke

		jmp	_BIOSReboot

	.KERNELNOTFOUND:
		mov	si,ERROR_KERNELNOTFOUND
		call	_stringOutput

		call	_getKeystroke

		jmp	_BIOSReboot

main:
	mov	ax,0x9000
	mov	ss,ax
	mov	sp,0xFFFE

	mov	ah,0x00
	mov	al,0x03
	int	0x10

	mov	ax,0x1003
	mov	bh,0
	mov	bl,0
	int	0x10

	mov	ah,0x05
	mov	al,0
	int	0x10

	mov	ah,0x06
	mov	al,0
	mov	bh,0x0A
	mov	ch,0
	mov	cl,0
	mov	dh,24
	mov	dl,79
	int	0x10

	mov	ah,0x02
	mov	bh,0
	mov	dh,24
	mov	dl,0
	int	0x10

	mov	ax,[KERNEL_SEGMENT]
	mov	es,ax
	mov	bx,[KERNEL_OFFSET]

	mov	ah,0x02
	mov	al,10
	mov	ch,0
	mov	cl,2
	mov	dh,0
	mov	dl,0
	int	0x13

	cmp	ah,0x00
	jne	_ERROR.CORRUPTDRIVE

	mov	di,[KERNEL_OFFSET]

	mov	dx,[KERNEL_KEYLIMIT]

	mov	ax,cs
	mov	ds,ax

@@:	cmp	dx,0
	je	_ERROR.KERNELNOTFOUND

	mov	si,KERNEL_KEY

	mov	cx,[KERNEL_KEYSIZE]

	repe	cmpsb

	cmp	cx,0
	je	@f

	dec	dx

	jmp	@b

@@:	jmp	0x1000:0x0000

times	510-($-$$)	db	0x00
			dw	0xAA55
org	0x7C00

jmp	_main

; --- DATA ---
DEF_KernelSegment	equ	0x07E0
DEF_KernelAddress	equ	0x0000

KERNEL_DiskHeadNumber	equ	0
KERNEL_DiskTrackNumber	equ	0
KERNEL_DiskSectorNumber	equ	2
KERNEL_ReadSectorNumber	equ	10

KERNEL_SignatureKey	db	"@XBASIC"
KERNEL_SignatureLength	=	$ - KERNEL_SignatureKey
KERNEL_SignatureLimit	equ	5

VIDEO_DefaultPage	equ	0

ERROR_BadDrive	db	">>> DISK ERROR",0x03
ERROR_NoKernel	db	">>> KERNEL NOT FOUND",0x03

; --- PROCEDURE ---

; [ ERROR RAISING (print message + get keypress + cold reboot)]
_raiseError:
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

@@:	; Set read keyboard input interrupt
	mov	ah,0x00

	; Read keyboard input
	int	0x16

	; Set cold reboot magic number
	mov	ax,0x0040
	mov	ds,ax
	mov	word [0x0072],0x0000

	; Cold reboot
	jmp	0xFFFF:0x0000

; --- CODE ---
_main:
	; Set temporary data segment for error message addressing
	mov	ax,cs
	mov	ds,ax

	; Initalize 80*25 color text video mode
	mov	ah,0x00
	mov	al,0x03
	int	0x10

	; Select video page
	mov	ah,0x05
	mov	al,VIDEO_DefaultPage
	int	0x10

	; Set bold background (16 background colors)
	mov	ax,0x1003
	mov	bl,0x00
	int	0x10

	; Set red text color for error message
	mov	ah,0x06
	mov	al,0x00
	mov	bh,0x0C
	mov	ch,0
	mov	cl,0
	mov	dh,24
	mov	dl,79
	int	0x10

	; Set cursor at the bottom of the screen
	mov	ah,0x02
	mov	bh,VIDEO_DefaultPage
	mov	dh,24
	mov	dl,0
	int	0x10

	; Set kernel address
	mov	ax,DEF_KernelSegment
	mov	es,ax
	mov	bx,DEF_KernelAddress

	; Load kernel on disk
	mov	ah,0x02
	mov	al,KERNEL_ReadSectorNumber
	mov	ch,KERNEL_DiskTrackNumber
	mov	cl,KERNEL_DiskSectorNumber
	mov	dh,KERNEL_DiskHeadNumber
	mov	dl,0
	int	0x13

	; If success, continue
	cmp	ah,0x00
	je	@f

	; If not, raise error and restart the computer
	mov	si,ERROR_BadDrive
	jmp	_raiseError

	; Verify kernel signature
@@:	mov	di,DEF_KernelAddress

	; Set verification limit
	mov	dx,KERNEL_SignatureLimit

	; Check if verification has reached limit
.verify_proc:
	cmp	dx,0
	jne	@f
	
	; If yes, raise error and restart the computer
	mov	si,ERROR_NoKernel
	jmp	_raiseError

	; If not, do the comparison
@@:	mov	cx,KERNEL_SignatureLength
	mov	si,KERNEL_SignatureKey

	; Signature comparison
	repe	cmpsb

	; Check if signature is valid
	cmp	cx,0

	; If yes, jump to kernel
	je	@f

	; If not, decrease the number of attempt
	dec	dx

	; Repeat the process
	jmp	.verify_proc

	; Kernel address
@@:	jmp	DEF_KernelSegment:DEF_KernelAddress

times	510-($-$$)	db	0x00
			dw	0xAA55
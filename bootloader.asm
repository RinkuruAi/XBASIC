org	0x7C00

jmp	_main

; --- DATA ---
DEF_StackSegment	equ	0x9000
DEF_StackAddress	equ	0xFFFE

DEF_KernelSegment	equ	0x009C
DEF_KernelAddress	equ	0x0000

KERNEL_DiskHeadNumber	equ	0
KERNEL_DiskTrackNumber	equ	0
KERNEL_DiskSectorNumber	equ	2
KERNEL_ReadSectorNumber	equ	2

KERNEL_SignatureFlag	db	"@"
KERNEL_Signature	db	"SIMPLIFY"
KERNEL_SignatureLength = $ - KERNEL_SignatureFlag
KERNEL_SignatureLimit	equ	5

ERROR_BadDrive	db	">>> DISK ERROR",0x03
ERROR_NoKernel	db	">>> KERNEL NOT FOUND",0x03

; --- PROCEDURE ---
; [ BIOS COLD REBOOT ]
_BIOSColdReboot:
	; Set cold reboot magic number
	mov	ax,0x0040
	mov	ds,ax
	mov	word [0x0072],0x0000

	; Cold reboot
	jmp	0xFFFF:0x0000

; [ WAIT FOR KEYPRESS ]
_waitForKeypress:
	; Store registers
	push	ax

	; Set read keyboard input interrupt
	mov	ah,0x00

	; Read keyboard input
	int	0x16

	; Restore registers
	pop	ax

	; Exit procedure
	ret

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
	jmp	@f

	; If not, print the character
	int	0x10

	; Repeat those steps
	jmp	@b

	; Restore registers
@@:	pop	si
	pop	ax

	; Exit procedure
	ret

; --- CODE ---
_main:
	; Set temporary stack address for bootloader procedures calling
	mov	ax,DEF_StackSegment
	mov	ss,ax
	mov	sp,DEF_StackAddress

	; Set temporary data segment for error message addressing
	mov	ax,cs
	mov	ds,ax

	; Initalize 80*25 color text video mode
	mov	ax,0x0003
	int	0x10

	; Set bold background (16 background colors)
	mov	ax,0x1003
	mov	bl,0x00
	int	0x10

	; Set red text color for error message
	mov	ax,0x0600
	mov	bh,0x0C
	xor	cx,cx
	mov	dx,0x184F
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
	int	0x13

	; If success, continue
	jnc	@f

	; If not, raise error and restart the computer
	mov	si,ERROR_BadDrive
	call	_stringOutput

	call	_waitForKeypress

	call	_BIOSColdReboot

	; Verify kernel signature
@@:	mov	di,DEF_KernelAddress

	; Set verification limit
	mov	dx,KERNEL_SignatureLimit

	; Check if verification has reached limit
@@:	cmp	dx,0
	
	; If yes, raise error and restart the computer
	mov	si,ERROR_NoKernel
	call	_stringOutput

	call	_waitForKeypress

	call	_BIOSColdReboot

	; If not, do the comparison
	mov	cx,KERNEL_SignatureLength
	mov	si,KERNEL_SignatureFlag

	; Signature comparison
	repe	cmpsb

	; Check if signature is valid
	cmp	cx,0

	; If yes, jump to kernel
	je	DEF_KernelSegment:DEF_KernelAddress

	; If not, decrease the number of attempt
	dec	dx

	; Repeat the process
	jmp	@b

times	510-($-$$)	db	0x00
			dw	0xAA55
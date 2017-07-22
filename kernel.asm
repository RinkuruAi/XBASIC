org	0x0000

jmp	_boot

KERNEL_SignatureLock	db	"@XBASIC"

; --- DATA ---
DEF_StackSegment	equ	0x9000
DEF_StackAddress	equ	0xFFFE

INPUT_BufferSegment	equ	0x8000
INPUT_BufferAddress	equ	0xFFFE

INPUT_MaxInputChar	equ	256

BASIC_WelcomeMessage	db	"XBASIC Version 0.0.1 by Rinkuru Ai",0x03
BASIC_PromptCursor	db	"] ",0x03

; --- BOOT ---
_boot:
	; Set stack address
	mov	ax,DEF_StackSegment
	mov	ss,ax
	mov	sp,DEF_StackAddress

	; Set input buffer address
	mov	ax,INPUT_BufferSegment
	mov	es,ax
	mov	di,INPUT_BufferAddress

	; Set data segment
	mov	ax,cs
	mov	ds,ax

	; Load welcome message
	mov	si,BASIC_WelcomeMessage
	call	_stringOutput

	; Jump into main code
	jmp	_main

; --- CODE ---
_main:
	hlt

include	"io.asm"
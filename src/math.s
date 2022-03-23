;--------------------------------------------------------------;
; math.s - Contains commonly used math constants and functions ;
; Sinisig 2022                                                 ;
;--------------------------------------------------------------;

%define MATH_S_IMPL
%include "Shared.i"
%include "math.i"


;==- Constants -==;

section 	.rodata
global	fConst_AbsMask
fConst_AbsMask:
	dd	~(1 << 31)

section 	.rodata
global	fConst_hPi
fConst_hPi:
	dd 0x3FC90FDB

;==- Trig Functions -==;

section	.text
global 	cosf
cosf:
	.STACKSZ		equ 8
	.SOFF_BUF	equ 0

	sub	rsp,.STACKSZ
	movss	[rsp+.SOFF_BUF],xmm0
	fld	dword [rsp+.SOFF_BUF]
	fcos
	fstp	dword [rsp+.SOFF_BUF]
	movss	xmm0,dword [rsp+.SOFF_BUF]
	add	rsp,.STACKSZ
	ret

section	.text
global	sinf
sinf:
	subss	xmm0,[fConst_hPi]
	jmp	cosf

section 	.text
global	tanf
tanf:
	.STACKSZ		equ 8
	.SOFF_THETA	equ 0
	.SOFF_COSF	equ 4

	sub	rsp,.STACKSZ
	movss	[rsp+.SOFF_THETA],xmm0
	call	cosf
	movss	[rsp+.SOFF_COSF],xmm0
	movss	xmm0,[rsp+.SOFF_THETA]
	call	sinf
	divss	xmm0,[rsp+.SOFF_COSF]
	add	rsp,.STACKSZ
	ret

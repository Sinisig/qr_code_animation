;--------------------------------------------------------------;
; math.s - Contains commonly used math constants and functions ;
; Sinisig 2022                                                 ;
;--------------------------------------------------------------;

%define MATH_S_IMPL
%include "Shared.i"
%include "math.i"


;==- Constants -==;

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

;--------------------------------------------------------------;
; math.s - Contains commonly used math constants and functions ;
; Sinisig 2022                                                 ;
;--------------------------------------------------------------;

%define MATH_S_IMPL
%include "Shared.i"
%include "math.i"


section .rodata
fConst_outputRange:
   dd 32768.0

section .rodata
fConst_cvtToRad:
   dd 0x38C90FDB  ; pi/32768

section	.text
global 	cos
cos:
   .SBUF_FLOAT equ 4

   .STACKSZ    equ .SBUF_FLOAT
   .SOFF_FLOAT equ 0

   sub      rsp,.STACKSZ
   movzx    eax,ax
   cvtsi2ss xmm0,eax
   mulss    xmm0,[fConst_cvtToRad]
   movss    dword [rsp+.SOFF_FLOAT],xmm0
   fld      dword [rsp+.SOFF_FLOAT]
   fcos
   fstp     dword [rsp+.SOFF_FLOAT]
   movss    xmm0,dword [rsp+.SOFF_FLOAT]
   mulss    xmm0,[fConst_outputRange]
	cvtss2si eax,xmm0
   add      rsp,.STACKSZ
	ret

section	.text
global	sin
sin:
	sub   ax,16384
	jmp   cos

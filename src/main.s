;--------------------------------------------;
; main.s - Main function and loop processing ;
; Sinisig 2022                               ;
;--------------------------------------------;

%include "Shared.i"
%include "draw.i"
%include "math.i"


;==- Constant data -==;

section .rodata
strEscCursor:
   db C_ESC,"[",C_SIZE_X_STR,"D",C_ESC,"[",C_SIZE_Y_STR,"A"
strEscCursorLen   equ $ - strEscCursor

section .rodata
strEscClear:
   db C_ESC,"[2J"
strEscClearLen    equ $ - strEscClear

section .rodata
strWatermark:
   db "#==- QR Code Animation by Sinisig 2022 -==#",C_LF
strWatermarkLen   equ $ - strWatermark

section .rodata
fConst_dTheta:
   dd 0.2

;==- Code -==;

section .text
global main
main:
   .SBUF_STRBUF   equ C_BUFSZ
   .SBUF_TSTRUC   equ 16
   .SBUF_TRI      equ 32
   .SBUF_THETA    equ 16

   .STACKSZ       equ .SBUF_TSTRUC+.SBUF_TRI+.SBUF_STRBUF+.SBUF_THETA
   .SOFF_TSTRUC   equ .SBUF_TSTRUC
   .SOFF_TRI      equ .SOFF_TSTRUC+.SBUF_TRI
   .SOFF_THETA    equ .SOFF_TRI+.SBUF_THETA
   .SOFF_STRBUF   equ .SOFF_THETA+.SBUF_STRBUF

   push  rbx
   push  r12
   push  rbp
   mov   rbp,rsp
   sub   rsp,.STACKSZ

   ; Load the time interval struct on the stack
   xor   eax,eax
   mov   qword [rbp-.SOFF_TSTRUC+08h],1000000000/A_RATE
   mov   qword [rbp-.SOFF_TSTRUC],rax

   ; Base data for the triangle
   mov   dword [rbp-.SOFF_THETA],eax
   mov   dword [rbp-.SOFF_TRI+Tri.a+0],-7
   mov   dword [rbp-.SOFF_TRI+Tri.a+4],3
   mov   dword [rbp-.SOFF_TRI+Tri.b+0],-1
   mov   dword [rbp-.SOFF_TRI+Tri.b+4],3
   mov   dword [rbp-.SOFF_TRI+Tri.c+0],-4
   mov   dword [rbp-.SOFF_TRI+Tri.c+4],0
   mov   byte [rbp-.SOFF_TRI+Tri.fill],C_FG_SHADE0

   ; Pointer for the screen/string buffer
   lea   r12,[rbp-.SOFF_STRBUF]

   ; Clear the console and display the watermark text
   PRINTSTR strEscClear,strEscClearLen
   PRINTSTR strWatermark,strWatermarkLen

   ; Show the first frame of the animation
   mov      rdi,r12
   call     clear_con
   PRINTSTR r12,C_CHARCOUNT

   ; ==- Main animation loop -==;

   mov   ebx,A_LENGTH   ; Frame count
   .animate_loop:
      ; Delay for frame timing
      lea   rdi,[rbp-10h]
      xor   esi,esi
      xor   eax,eax
      mov   al,SYS_NANOSLEEP
      syscall

      ; Clear the buffer for the new frame
      mov   rdi,r12
      call  clear_con

      ;==- Rendering code -==;

      ; Update x-coord
      inc   dword [rbp-.SOFF_TRI+Tri.a]
      inc   dword [rbp-.SOFF_TRI+Tri.b]
      inc   dword [rbp-.SOFF_TRI+Tri.c]

      ; Update y-coord
      movss    xmm0,[rbp-.SOFF_THETA]
      call     sinf
      cvtss2si eax,xmm0
      add      dword [rbp-.SOFF_TRI+Tri.a+4],eax
      add      dword [rbp-.SOFF_TRI+Tri.b+4],eax
      add      dword [rbp-.SOFF_TRI+Tri.c+4],eax

      ; Increment theta for the next loop
      movss xmm0,[rbp-.SOFF_THETA]
      addss xmm0,[fConst_dTheta]
      movss [rbp-.SOFF_THETA],xmm0

      ; Draw the triangle
      mov   rdi,r12
      lea   rsi,[rbp-.SOFF_TRI]
      call  plot_triangle

      ;==- End of rendering code -==;

      ; Display the buffer
      PRINTSTR strEscCursor,strEscCursorLen
      PRINTSTR rsp,C_CHARCOUNT

      ; Do we keep looping?
      dec   ebx
      jnz   .animate_loop

   ; Return successfully :D
   xor   eax,eax
   leave
   pop   r12
   pop   rbx
   ret

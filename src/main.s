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
shadingTable:
   db C_FG_SHADE0,C_FG_SHADE1,C_FG_SHADE2,C_FG_SHADE3,C_FG_SHADE4

section .rodata
fConst_triIncRotate:
   dd 0x40060A92  ; 2pi/3 aka 60 degrees

section .rodata
fConst_thetaIncrement:
   dd 0.1

section .rodata
fConst_axisScaleX:
   dd 8.8888889

section .rodata
fConst_axisScaleY:
   dd 5.0

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
   push  r13
   push  r14
   push  rbp
   mov   rbp,rsp
   sub   rsp,.STACKSZ

   ; Load the time interval struct on the stack
   xor   eax,eax
   mov   qword [rbp-.SOFF_TSTRUC+08h],1000000000/A_RATE
   mov   qword [rbp-.SOFF_TSTRUC],rax

   ; Pointer for the screen/string buffer and zero out theta
   mov   dword [rbp-.SOFF_THETA],eax
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

      ; Calculate the x/y coords using sin and cos
      lea   r13,[rbp-.SOFF_TRI]
      mov   r14b,3
      .calc_points:
         ; x
         movss    xmm0,[rbp-.SOFF_THETA]
         call     cosf
         mulss    xmm0,[fConst_axisScaleX]
         cvtss2si eax,xmm0
         add      eax,C_SIZE_X/2
         mov      dword [r13+0],eax
         ; y
         movss    xmm0,[rbp-.SOFF_THETA]
         call     sinf
         mulss    xmm0,[fConst_axisScaleY]
         cvtss2si eax,xmm0
         add      eax,C_SIZE_Y/2
         mov      dword [r13+4],eax
         ; +60 degrees
         movss    xmm0,[rbp-.SOFF_THETA]
         addss    xmm0,[fConst_triIncRotate]
         movss    [rbp-.SOFF_THETA],xmm0
         ; Loop
         xor   eax,eax
         mov   al,8
         add   r13,rax
         dec   r14b
         jnz   .calc_points

      ; Increment theta
      movss xmm0,[rbp-.SOFF_THETA]
      addss xmm0,[fConst_thetaIncrement]
      movss [rbp-.SOFF_THETA],xmm0

      ; Use theta to pick a new shade for the triangle
      call     cosf
      addss    xmm0,xmm0
      cvtss2si eax,xmm0
      inc      eax
      lea      rdi,[shadingTable]
      inc      eax
      mov      dl,[rdi+rax]
      mov      byte [rbp-.SOFF_TRI+Tri.fill],dl

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
   pop   r14
   pop   r13
   pop   r12
   pop   rbx
   ret

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
   db "#==-   QR Code Animation by Sinisig 2022  -==#",C_LF
   db "#==- github.com/Sinisig/qr_code_animation -==#",C_LF
strWatermarkLen   equ $ - strWatermark

section .rodata
testShape_VData:
   ; Stored as: x,y,z
   dw 128,58,0    ; Mouth - Point 1
   dw 96,100,0    ; Mouth - Point 2
   dw 0,128,0     ; Mouth - Point 3
   dw -95,100,0   ; Mouth - Point 2
   dw -127,58,0   ; Mouth - Point 4
   dw 128,-72,0   ; Right Eye - Point 1
   dw 64,-72,0    ; Right Eye - Point 2
   dw 96,-128,0   ; Right Eye - Point 3
   dw 96,-90,0    ; Right Eye - Point 4
   dw 74,-104,0   ; Right Eye - Point 5
   dw 118,-104,0  ; Right Eye - Point 6
   dw -127,-72,0   ; Left Eye - Point 1
   dw -63,-72,0    ; Left Eye - Point 2
   dw -95,-128,0   ; Left Eye - Point 3
   dw -95,-90,0    ; Left Eye - Point 4
   dw -73,-104,0   ; Left Eye - Point 5
   dw -117,-104,0  ; Left Eye - Point 6

testShape_VCount  equ ($-testShape_VData)/6

section .rodata
testShape_IData:
   db 0,1,2    ; Mouth - Tri 1
   db 0,2,3    ; Mouth - Tri 2
   db 0,3,4    ; Mouth - Tri 3
   db 5,7,8    ; Right Eye - Tri 1
   db 6,7,8    ; Right Eye - Tri 2
   db 5,7,9    ; Right Eye - Tri 3
   db 6,7,10   ; Right Eye - Tri 4
   db 11,13,14 ; Left Eye - Tri 1
   db 12,13,14 ; Left Eye - Tri 2
   db 11,13,15 ; Left Eye - Tri 3
   db 12,13,16 ; Left Eye - Tri 4

testShape_ICount  equ $-testShape_IData

;==- Code -==;

section .text
global main
main:
   .SBUF_STRBUF   equ C_BUFSZ
   .SBUF_TSTRUC   equ 16

   .STACKSZ       equ .SBUF_TSTRUC+.SBUF_STRBUF
   .SOFF_TSTRUC   equ .SBUF_TSTRUC
   .SOFF_STRBUF   equ .SOFF_TSTRUC+.SBUF_STRBUF

   %macro PRINTSTR 2
      lea   rdi,[%1]
      mov   esi,%2
      call  print_str
   %endmacro

   push  rbx
   push  r12
   push  r13
   push  r14
   push  rbp
   mov   rbp,rsp
   sub   rsp,.STACKSZ

   ; Load the time interval struct on the stack and the string ptr
   xor   eax,eax
   lea   r12,[rbp-.SOFF_STRBUF]
   mov   qword [rbp-.SOFF_TSTRUC+08h],1000000000/A_RATE
   mov   qword [rbp-.SOFF_TSTRUC],rax

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
      
      ; Draw the test shape
      xor   ecx,ecx
      mov   rdi,r12
      lea   rsi,[testShape_VData]
      lea   rdx,[testShape_IData]
      mov   cl,testShape_ICount
      call  render_shape

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

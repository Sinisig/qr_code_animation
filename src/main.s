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
   .SCL equ 4
   ; Stored as: x,y,z
   dw .SCL*128    ,.SCL*58    ,.SCL*0  ; Mouth - Point 1
   dw .SCL*96     ,.SCL*100   ,.SCL*0  ; Mouth - Point 2
   dw .SCL*0      ,.SCL*128   ,.SCL*0  ; Mouth - Point 3
   dw .SCL*-95    ,.SCL*100   ,.SCL*0  ; Mouth - Point 2
   dw .SCL*-127   ,.SCL*58    ,.SCL*0  ; Mouth - Point 4
   dw .SCL*128    ,.SCL*-72   ,.SCL*0  ; Right Eye - Point 1
   dw .SCL*64     ,.SCL*-72   ,.SCL*0  ; Right Eye - Point 2
   dw .SCL*96     ,.SCL*-128  ,.SCL*0  ; Right Eye - Point 3
   dw .SCL*96     ,.SCL*-90   ,.SCL*0  ; Right Eye - Point 4
   dw .SCL*74     ,.SCL*-104  ,.SCL*0  ; Right Eye - Point 5
   dw .SCL*118    ,.SCL*-104  ,.SCL*0  ; Right Eye - Point 6
   dw .SCL*-127   ,.SCL*-72   ,.SCL*0  ; Left Eye - Point 1
   dw .SCL*-63    ,.SCL*-72   ,.SCL*0  ; Left Eye - Point 2
   dw .SCL*-95    ,.SCL*-128  ,.SCL*0  ; Left Eye - Point 3
   dw .SCL*-95    ,.SCL*-90   ,.SCL*0  ; Left Eye - Point 4
   dw .SCL*-73    ,.SCL*-104  ,.SCL*0  ; Left Eye - Point 5
   dw .SCL*-117   ,.SCL*-104  ,.SCL*0  ; Left Eye - Point 6

testShape_VSize   equ $-testShape_VData
testShape_VCount  equ testShape_VSize/6

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
   .SBUF_VERTBUF  equ testShape_VSize + (16 - (testShape_VSize % 16))

   .STACKSZ       equ .SBUF_TSTRUC+.SBUF_STRBUF+.SBUF_VERTBUF
   .SOFF_TSTRUC   equ 0
   .SOFF_VERTBUF  equ .SBUF_TSTRUC
   .SOFF_STRBUF   equ .SOFF_VERTBUF+.SBUF_VERTBUF

   %macro PRINTSTR 2
      lea   rdi,[%1]
      mov   esi,%2
      call  print_str
   %endmacro

   push  rbx
   push  r12
   push  r13
   sub   rsp,.STACKSZ

   ; Load the time interval struct on the stack and the ptrs
   xor   eax,eax
   lea   r12,[rsp+.SOFF_STRBUF]
   lea   r13,[rsp+.SOFF_VERTBUF]
   mov   qword [rsp+.SOFF_TSTRUC+08h],1000000000/A_RATE
   mov   qword [rsp+.SOFF_TSTRUC],rax

   ; Initialize the vertex buffer
   mov   ecx,testShape_VSize
   lea   rsi,[testShape_VData]
   mov   rdi,r13
   rep   movsb

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
      lea   rdi,[rsp+.SOFF_TSTRUC]
      xor   esi,esi
      xor   eax,eax
      mov   al,SYS_NANOSLEEP
      syscall

      ; Clear the buffer for the new frame
      mov   rdi,r12
      call  clear_con

      ;==- Rendering code -==;
      
      ; Run the test translation over every coordinate
      mov   rdi,r13
      mov   ecx,testShape_VCount*3
      .scale_shape:
         mov   ax,word [rdi]
         imul  ax,63
         sar   ax,6
         mov   word [rdi],ax
         inc   rdi
         inc   rdi
         loop  .scale_shape

      ; Draw the test shape
      xor   ecx,ecx
      mov   rdi,r12
      mov   rsi,r13
      lea   rdx,[testShape_IData]
      mov   cl,testShape_ICount-1
      call  render_shape

      ;==- End of rendering code -==;

      ; Display the buffer
      PRINTSTR strEscCursor,strEscCursorLen
      PRINTSTR r12,C_CHARCOUNT

      ; Do we keep looping?
      dec   ebx
      jnz   .animate_loop

   ; Return successfully :D
   xor   eax,eax
   add   rsp,.STACKSZ
   pop   r13
   pop   r12
   pop   rbx
   ret

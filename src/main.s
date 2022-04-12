;--------------------------------------------;
; main.s - Main function and loop processing ;
; Sinisig 2022                               ;
;--------------------------------------------;

%include "Shared.i"
%include "draw.i"


;==- Constant data -==;

section .rodata
strResetCursor:
   db C_ESC,"[3H"
strResetCursorLen equ $ - strResetCursor

section .rodata
strWatermark:
   db C_ESC,"[2J" ; Clear the console
   db C_ESC,"[H"  ; Move the cursor to the top-left
   db "#==-   QR Code Animation by Sinisig 2022  -==#",C_LF
   db "#==- github.com/Sinisig/qr_code_animation -==#",C_LF
strWatermarkLen   equ $ - strWatermark

section .rodata
mSmile_VData:
   .SCL equ 4
   ; Stored as: x,y,z
   dw .SCL*128    ,.SCL*58    ; Mouth - Point 1
   dw .SCL*96     ,.SCL*100   ; Mouth - Point 2
   dw .SCL*0      ,.SCL*128   ; Mouth - Point 3
   dw .SCL*-95    ,.SCL*100   ; Mouth - Point 2
   dw .SCL*-127   ,.SCL*58    ; Mouth - Point 4
   dw .SCL*128    ,.SCL*-72   ; Right Eye - Point 1
   dw .SCL*64     ,.SCL*-72   ; Right Eye - Point 2
   dw .SCL*96     ,.SCL*-128  ; Right Eye - Point 3
   dw .SCL*96     ,.SCL*-90   ; Right Eye - Point 4
   dw .SCL*74     ,.SCL*-104  ; Right Eye - Point 5
   dw .SCL*118    ,.SCL*-104  ; Right Eye - Point 6
   dw .SCL*-127   ,.SCL*-72   ; Left Eye - Point 1
   dw .SCL*-63    ,.SCL*-72   ; Left Eye - Point 2
   dw .SCL*-95    ,.SCL*-128  ; Left Eye - Point 3
   dw .SCL*-95    ,.SCL*-90   ; Left Eye - Point 4
   dw .SCL*-73    ,.SCL*-104  ; Left Eye - Point 5
   dw .SCL*-117   ,.SCL*-104  ; Left Eye - Point 6

mSmile_VSize   equ $-mSmile_VData
mSmile_VCount  equ mSmile_VSize/4

section .rodata
mSmile_IData:
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

mSmile_ICount equ $-mSmile_IData

;==- Code -==;

section .text
global _entry
_entry:
   .SBUF_STRBUF   equ C_BUFSZ
   .SBUF_TSTRUC   equ 16
   .SBUF_CAMERA   equ 16
   .SBUF_VERTEX   equ mSmile_VSize+(16 - (mSmile_VSize % 16))

   .STACKSZ       equ .SBUF_TSTRUC+.SBUF_STRBUF+.SBUF_CAMERA+.SBUF_VERTEX+8
   .SOFF_TSTRUC   equ 0
   .SOFF_CAMERA   equ .SBUF_TSTRUC
   .SOFF_VERTEX   equ .SOFF_CAMERA+.SBUF_CAMERA
   .SOFF_STRBUF   equ .SOFF_VERTEX+.SBUF_VERTEX

   %macro PRINTSTR 2
      lea   rdi,[%1]
      mov   esi,%2
      call  print_str
   %endmacro

   ; Create stack space, nonvolatiles don't need to be preserved
   sub   rsp,.STACKSZ

   ; Load the time interval struct on the stack
   xor   eax,eax
   mov   qword [rsp+.SOFF_TSTRUC+08h],1000000000/A_RATE
   mov   qword [rsp+.SOFF_TSTRUC],rax

   ; Calculate pointer offsets
   lea   r12,[rsp+.SOFF_STRBUF]
   lea   r13,[rsp+.SOFF_VERTEX]

   ; Load the smiley into the vertex buffer
   mov   ecx,mSmile_VSize/2
   lea   rsi,[mSmile_VData]
   mov   rdi,r13
   rep   movsw

   ; Display the watermark text and prepare the console
   PRINTSTR strWatermark,strWatermarkLen

   ; ==- Main animation loop -==;

   mov   ebx,A_LENGTH   ; Frame count
   .animate_loop:
      ; Clear the buffer for the new frame
      xor   ecx,ecx
      mov   rdi,r12
      mov   al,C_BG
      mov   dl,C_SIZE_Y
      .clear_row:
         mov   cl,C_SIZE_X
         rep   stosb
         mov   byte [rdi],C_LF
         inc   rdi
         dec   dl
         jnz   .clear_row

      ;==- Rendering code -==;

      ; Scale down the smile
      mov   ecx,mSmile_VSize/2
      mov   rdi,r13
      .scale_loop:
         mov   ax,word [rdi]  ; Current coordinate in ax

         ; Scale by a factor of 63/64 (98.4%)
         imul  ax,63
         sar   ax,6

         mov   word [rdi],ax
         inc   rdi
         inc   rdi
         loop  .scale_loop

      ; Render the smile
      mov   rdi,r12
      mov   rsi,r13
      lea   rdx,[mSmile_IData]
      mov   cl,(mSmile_ICount-1)/3
      call  render_shape

      ;==- End of rendering code -==;

      ; Display the buffer
      PRINTSTR strResetCursor,strResetCursorLen
      PRINTSTR r12,C_CHARCOUNT

      ; Delay for frame timing
      lea   rdi,[rsp+.SOFF_TSTRUC]
      xor   esi,esi
      xor   eax,eax
      mov   al,SYS_USLEEP
      syscall

      ; Do we keep looping?
      dec   ebx
      jnz   .animate_loop

   ; Syscall exit, stack restoration can be skipped
   xor   edi,edi
   xor   eax,eax
   mov   al,SYS_EXIT
   syscall

;--------------------------------------------;
; main.s - Main function and loop processing ;
; Sinisig 2022                               ;
;--------------------------------------------;

%include "Shared.i"
%include "draw.i"
%include "math.i"


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

mSmile_VSize   equ $-mSmile_VData
mSmile_VCount  equ mSmile_VSize/6

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
global main
main:
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

   push  rbx
   push  r12
   push  r13
   push  r14
   sub   rsp,.STACKSZ

   ; Load the time interval struct on the stack and the ptrs
   xor   eax,eax
   lea   r12,[rsp+.SOFF_STRBUF]
   %if   D_EXPERIMENTAL
   ;------------------;
   lea   r13,[rsp+.SOFF_CAMERA]
   ;------------------;
   %endif
   lea   r14,[rsp+.SOFF_VERTEX]
   mov   qword [rsp+.SOFF_TSTRUC+08h],1000000000/A_RATE
   mov   qword [rsp+.SOFF_TSTRUC],rax

   ; Load the smiley into the vertex buffer
   mov   ecx,mSmile_VSize/2
   lea   rsi,[mSmile_VData]
   mov   rdi,r14
   rep   movsw

   %if D_EXPERIMENTAL
   ;----------------;
   ; Initialize the camera angles and y-coordinate
   mov   byte [r13+Camera.y],    A_CAM_DEF_HEIGHT
   mov   word [r13+Camera.pitch],A_CAM_DEF_PITCH
   mov   word [r13+Camera.yaw],  A_CAM_DEF_YAW
   mov   word [r13+Camera.roll], A_CAM_DEF_ROLL
   ;----------------;
   %endif

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
      
      ; Increment the camera's yaw and calculate the new x/z coords
      %if D_EXPERIMENTAL
      ;----------------;
      add   word [r13+Camera.yaw],A_CAM_YAW_INCREMENT
      mov   di,word [r13+Camera.yaw]
      call  cos
      shr   eax,7
      sub   al,127
      mov   byte [r13+Camera.x],al
      mov   di,word [r13+Camera.yaw]
      call  sin
      shr   eax,7
      sub   al,127
      mov   byte [r13+Camera.z],al
      ;----------------;
      %endif

      ; Scale down the smile
      mov   ecx,mSmile_VSize/2
      mov   rdi,r14
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
      xor   r8d,r8d
      mov   rdi,r12
      %if D_EXPERIMENTAL
      ;----------------;
      mov   rsi,r13
      ;----------------;
      %endif
      mov   rdx,r14
      lea   rcx,[mSmile_IData]
      mov   r8b,mSmile_ICount-1
      call  render_shape

      ;==- End of rendering code -==;

      ; Display the buffer
      PRINTSTR strResetCursor,strResetCursorLen
      PRINTSTR r12,C_CHARCOUNT

      ; Delay for frame timing
      lea   rdi,[rsp+.SOFF_TSTRUC]
      xor   esi,esi
      xor   eax,eax
      mov   al,SYS_NANOSLEEP
      syscall

      ; Do we keep looping?
      dec   ebx
      jnz   .animate_loop

   ; Return successfully :D
   xor   eax,eax
   add   rsp,.STACKSZ
   pop   r14
   pop   r13
   pop   r12
   pop   rbx
   ret

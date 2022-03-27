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
mCuboid_VData:
   .SCL equ 64
   ; Stored as: x,y,z
   dw 1-.SCL, 1-.SCL, .SCL
   dw 1-.SCL, .SCL,   .SCL
   dw .SCL,   .SCL,   .SCL
   dw .SCL,   1-.SCL, .SCL
   dw 1-.SCL, 1-.SCL, 1-.SCL
   dw 1-.SCL, .SCL,   1-.SCL
   dw .SCL,   .SCL,   1-.SCL
   dw .SCL,   1-.SCL, 1-.SCL

mCuboid_VSize  equ $-mCuboid_VData
mCuboid_VCount equ mCuboid_VSize/6

section .rodata
mCuboid_IData:
   db 0,1,2
   db 0,2,3
   db 4,5,6
   db 4,6,7
   db 0,3,7
   db 0,4,7
   db 1,2,6
   db 1,5,6
   db 0,1,4
   db 1,4,5
   db 2,3,7
   db 2,6,7

mCuboid_ICount equ $-mCuboid_IData

;==- Code -==;

section .text
global main
main:
   .SBUF_STRBUF   equ C_BUFSZ
   .SBUF_TSTRUC   equ 16
   .SBUF_CAMERA   equ 16

   .STACKSZ       equ .SBUF_TSTRUC+.SBUF_STRBUF+.SBUF_CAMERA
   .SOFF_TSTRUC   equ 0
   .SOFF_CAMERA   equ .SBUF_TSTRUC
   .SOFF_STRBUF   equ .SOFF_CAMERA+.SBUF_CAMERA

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
   lea   r13,[rsp+.SOFF_CAMERA]
   mov   qword [rsp+.SOFF_TSTRUC+08h],1000000000/A_RATE
   mov   qword [rsp+.SOFF_TSTRUC],rax

   ; Initialize the camera angles and y-coordinate
   mov   byte [r13+Camera.y],    A_CAM_DEF_HEIGHT
   mov   word [r13+Camera.pitch],A_CAM_DEF_PITCH
   mov   word [r13+Camera.yaw],  A_CAM_DEF_YAW
   mov   word [r13+Camera.roll], A_CAM_DEF_ROLL

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

      ; Render the cuboid
      xor   r8d,r8d
      mov   rdi,r12
      mov   rsi,r13
      lea   rdx,[mCuboid_VData]
      lea   rcx,[mCuboid_IData]
      mov   r8b,mCuboid_ICount-1
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
   pop   r13
   pop   r12
   pop   rbx
   ret

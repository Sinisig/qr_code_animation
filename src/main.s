%include "Shared.i"

global main


%define C_SIZE_X  43
%define C_SIZE_Y  12
%defstr C_SIZE_X_STR C_SIZE_X
%defstr C_SIZE_Y_STR C_SIZE_Y

C_BUFSZ  equ (C_SIZE_X*C_SIZE_Y) + C_SIZE_Y
C_BG     equ ' '
C_FG     equ '*'

;==- Formatting strings --=;

section .rodata
strEscCursor:
   db C_ESC,"[",C_SIZE_X_STR,"D",C_ESC,"[",C_SIZE_Y_STR,"A"
strEscCursorLen   equ $ - strEscCursor

section .rodata
strEscClear:
   db C_ESC,"[2J"
strEscClearLen    equ $ - strEscClear

;==- Display text -==;

section .rodata
strWatermark:
   db "#==- QR Code Animation by Sinisig 2022 -==#",C_LF
strWatermarkLen   equ $ - strWatermark

;==- Constant struct for sleep -==;
section .rodata
restData:
   dq 0           ; tv_sec    : 0 seconds
   dq 125000000   ; tv_nsec   : 0.125 seconds aka 1/8th of a seocnd

section .text
print_str: ; void print_str(const char * buf, int len)
   mov   edx,esi
   mov   rsi,rdi
   xor   eax,eax
   mov   al,SYS_WRITE
   mov   edi,STDOUT
   syscall
   ret

section .text
clear_con:  ; void clear_con(void)
   lea   rdi,[strEscClear]
   mov   esi,strEscClearLen
   jmp   print_str

section .text
main:
   push  rbx
   push  r13
   push  rbp
   mov   rbp,rsp
   sub   rsp,C_BUFSZ + (16 - (C_BUFSZ % 16)) ; Aligned to a 16-byte boundary

   ; Clear the console and display the watermark text
   call  clear_con
   lea   rdi,[strWatermark]
   mov   esi,strWatermarkLen
   call  print_str

   ; Initialize the buffer
   xor   eax,eax        ; Index into the buffer
   mov   ecx,C_SIZE_Y   ; Count of Y cols

   .loop_outer:
   mov   edx,C_SIZE_X   ; Count of X cols

   .loop_inner:
   ; Fill row with the background char
   mov   byte [rsp+rax],C_BG
   inc   eax
   dec   edx
   jnz   .loop_inner

   ; Tack on a newline and move to the next row
   mov   byte [rsp+rax],C_LF
   inc   eax
   dec   ecx
   jnz   .loop_outer
   
   ; Display the first frame of the animation
   mov   rdi,rsp
   mov   esi,C_BUFSZ
   call  print_str

   ; ==- Main animation loop -==;
   mov   ebx,C_SIZE_X*C_SIZE_Y   ; Character counter
   .animate_loop:
      ; Sleep for 1/8th of a second
      lea   rdi,[restData]
      xor   esi,esi
      xor   eax,eax
      mov   al,SYS_NANOSLEEP
      syscall

      ; Update a random number
      .pick_char:
         ; Random index
         rdrand   eax
         mov      ecx,C_BUFSZ
         xor      edx,edx
         div      ecx
         
         ; Make sure it's free
         mov      al,[rsp+rdx]
         cmp      al,C_FG
         je       .pick_char
         cmp      al,C_LF
         je       .pick_char

         ; Write the foreground char
         mov      byte [rsp+rdx],C_FG

      ; Display the buffer
      lea   rdi,[strEscCursor]
      mov   esi,strEscCursorLen
      call  print_str
      mov   rdi,rsp
      mov   esi,C_BUFSZ
      call  print_str

      ; Do we keep looping?
      dec   ebx
      jnz   .animate_loop

   ; Return successfully :D
   xor   eax,eax
   leave
   pop   r13
   pop   rbx
   ret

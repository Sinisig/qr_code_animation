;--------------------------------------;
; draw.s - Printing and rendering code ;
; Sinisig 2022                         ;
;--------------------------------------;

%define  DRAW_S_IMPL
%include "Shared.i"
%include "draw.i"
%include "math.i"


section  .text
global   print_str
print_str: ; void print_str(const char * buf, int len)
   xor   eax,eax
   mov   edx,esi
   mov   rsi,rdi
   mov   al,SYS_WRITE
   mov   edi,STDOUT
   syscall
   ret

section  .text
global   clear_con
clear_con:  ; void clear_con(char * buf)
   xor   ecx,ecx
   mov   al,C_BG
   mov   dl,C_SIZE_Y
   .clear_row:
      mov   cl,C_SIZE_X
      rep   stosb
      
      ; Line Ending
      mov   byte [rdi],C_LF
      inc   rdi
      dec   dl
      jnz   .clear_row
   
   ret

section  .text
global   plot_triangle
plot_triangle: ; void plot_triangle(char * buf, const Tri * t, char fillColor)
   push  rbx
   push  rbp
   push  r12
   push  r13
   push  r14
   push  r15
   dec   rsp

   ; Set up registers
   mov   byte [rsp],dl     ; [rsp] = fillColor
   xor   eax,eax
   mov   r14,rdi           ; r14 = buf
   mov   al,4
   mov   r8d,dword [rsi]
   add   rsi,rax
   mov   r9d,dword [rsi]
   add   rsi,rax
   mov   r10d,dword [rsi]  ; r8d = Tri.a, r9d = Tri.b, r10d = Tri.c
   xor   ebx,ebx
   xor   r12d,r12d
   xor   r13d,r13d
   mov   r12b,C_SIZE_Y-1      ; y
   mov   r13d,C_CHARCOUNT-2   ; i

   ; Get the area of the full triangle
   xor   ebx,ebx
   mov   eax,r8d
   mov   ecx,r9d
   mov   edx,r10d
   call  .tri_area
   mov   ebp,ebx

   .col_loop:
      xor   r11d,r11d
      mov   r11b,C_SIZE_X-1   ; x
      .row_loop:
      ; Get the area of the subtriangles
      xor   ebx,ebx
      mov   r15d,r12d
      shl   r15d,16
      or    r15d,r11d

      ; p, a, b
      mov   eax,r15d
      mov   ecx,r8d
      mov   edx,r9d
      call  .tri_area

      ; p, a, c
      mov   eax,r15d
      mov   ecx,r8d
      mov   edx,r10d
      call  .tri_area

      ; p, b, c
      mov   eax,r15d
      mov   ecx,r9d
      mov   edx,r10d
      call  .tri_area

      ; Is the area the same?
      cmp   ebp,ebx
      jne   .skip_fill

      ; Fill with the fill char
      mov   al,byte [rsp]
      mov   byte [r14+r13],al

      ; Loop
      .skip_fill:
      dec   r13d
      dec   r11d
      jge   .row_loop
   dec   r13d
   dec   r12d
   jge   .col_loop

   inc   rsp
   pop   r15
   pop   r14
   pop   r13
   pop   r12
   pop   rbp
   pop   rbx
   ret

   .tri_area:
   ; This isn't a separate callable function, just
   ; a subroutine that's part of the plot_triangle function
   ; 
   ; eax = a
   ; ebx = running area total
   ; ecx = b
   ; edx = c
   ; Make sure to only modify these registers:
   ; eax, ecx, edx, edi, esi
   ; 
   ; At the end, add the result to ebx
   ; 
   ; Formula for calculating area:
   ; a = |x1*(y2-y3) + x2*(y3-y1) + x3*(y1-y2)|/2
   ; 
   ; Since this is only used for testing if a point
   ; is bound by the triangle, the /2 part can be
   ; skipped as it's not necessary to check for a
   ; matching result.
   
   ; Temporary variables for the math
   push  rbp
   push  rbx

   ;!!! Potential for integer overflow issues
   ; due to the use of 16-bit multiplication.
   ; It seems to be fine for now, but this might
   ; lead to issues down the road with massive
   ; triangles.

   ; x1*(y2-y3)
   mov   ebp,ecx
   mov   esi,edx
   shr   ebp,16
   shr   esi,16
   sub   bp,si
   imul  bp,ax

   ; x3*(y1-y2)
   mov   edi,eax
   mov   ebx,ecx
   shr   edi,16
   shr   ebx,16
   sub   di,bx
   imul  di,dx
   add   bp,di

   ; x2*(y3-y1)
   shr   eax,16
   sub   si,ax
   imul  si,cx
   add   bp,si
   
   ; Absolute value
   jge   .skip_abs
   not   bp
   inc   bp

   .skip_abs:
   pop   rbx
   add   ebx,ebp
   pop   rbp
   ret

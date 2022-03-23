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

; Internal helper for plot_triangle
section  .text
triangle_area: ; int triangle_area(const Tri * t)
   ; Load data from t
   mov   rcx,qword [rdi+Tri.a]
   mov   r8,qword [rdi+Tri.c]
   mov   rdi,qword [rdi+Tri.b]
   mov   eax,ecx  ; x1
   mov   edx,edi  ; x2
   mov   esi,r8d  ; x3
   shr   rcx,32   ; y1
   shr   rdi,32   ; y2
   shr   r8,32    ; y3

   ; Formula for calculating area:
   ; a = |x1*(y2-y3) + x2*(y3-y1) + x3*(y1-y2)|/2
   ; 
   ; Since this is only used for testing if a point
   ; is bound by the triangle, the /2 part can be
   ; skipped as it's not necessary to check for a
   ; matching result.
   mov   r9d,ecx
   sub   ecx,edi  ; y1-y2
   sub   edi,r8d  ; y2-y3
   sub   r8d,r9d  ; y3-y1
   imul  eax,edi  ; x1*(y2-y3)
   imul  edx,r8d  ; x2*(y3-y1)
   imul  ecx,esi  ; x3*(y1-y2)
   add   eax,edx
   add   eax,ecx

   ; abs(sum)
   jge   .skip_abs
   not   eax
   inc   eax
   .skip_abs:
   ret

section  .text
global   plot_triangle
plot_triangle: ; void plot_triangle(char * buf, const Tri * t)
   .STACKSZ    equ 48

   .SOFF_TRI   equ 0
   .SOFF_BUF   equ 24
   .SOFF_AW    equ 32

   push  rbx
   push  r12
   push  r13
   push  r14
   push  r15
   sub   rsp,.STACKSZ

   ; Load data and set up loop counters
   mov   qword [rsp+.SOFF_BUF],rdi  ; buf
   mov   r12,rsi                    ; t
   mov   r13d,C_CHARCOUNT-1         ; i
   mov   r14b,C_SIZE_Y              ; y

   ; Get the area of the triangle t
   mov   rdi,r12
   call  triangle_area
   mov   dword [rsp+.SOFF_AW],eax

   ; Loop for every pixel
   .outer_loop:
      dec   r13d
      mov   r15b,C_SIZE_X
      .inner_loop:
      ; Calculate the area of the sub-triangles formed by the point

      ; p, t.a, t.b
      mov   rax,qword [r12+Tri.a]
      mov   rcx,qword [r12+Tri.b]
      mov   edx,r14d
      mov   edi,r15d
      shl   rdx,32
      or    rdx,rdi
      mov   qword [rsp+.SOFF_TRI+Tri.b],rax
      mov   qword [rsp+.SOFF_TRI+Tri.c],rcx
      mov   qword [rsp+.SOFF_TRI+Tri.a],rdx
      lea   rdi,[rsp+.SOFF_TRI]
      call  triangle_area
      mov   ebx,eax

      ; p, t.a, t.c
      mov   rax,qword [r12+Tri.c]
      mov   qword [rsp+.SOFF_TRI+Tri.c],rax
      lea   rdi,[rsp+.SOFF_TRI]
      call  triangle_area
      add   ebx,eax

      ; p, t.b, t.c
      mov   rax,qword [r12+Tri.b]
      mov   qword [rsp+.SOFF_TRI+Tri.b],rax
      lea   rdi,[rsp+.SOFF_TRI]
      call  triangle_area
      add   ebx,eax

      ; Compare the point sum against the whole sum
      cmp   ebx,dword [rsp+.SOFF_AW]
      jne   .skip_fill

      ; We know the point is within the triangle, fill in the point
      mov   rbx,qword [rsp+.SOFF_BUF]
      mov   dl,byte [r12+Tri.fill]
      mov   byte [rbx+r13],dl

      .skip_fill:
      dec   r13d
      dec   r15b
      jnz   .inner_loop

   dec   r14b
   jnz   .outer_loop

   add   rsp,.STACKSZ
   pop   r15
   pop   r14
   pop   r13
   pop   r12
   pop   rbx
   ret

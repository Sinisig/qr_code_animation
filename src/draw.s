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
print_str: ; void print_str(const char * buf, u32 len)
   xor   eax,eax
   mov   edx,esi
   mov   rsi,rdi
   mov   al,SYS_WRITE
   mov   edi,STDOUT
   syscall
   ret

section  .text
global   plot_triangle
plot_triangle: ; void plot_triangle(char * buf, const Triangle2D * t, char fillColor)
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
   mov   r10d,dword [rsi]  ; r8d = Triangle2D.a, r9d = Triangle2D.b, r10d = Triangle2D.c
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

      ; Is the area the same and non-zero?
      test  ebx,ebx
      jz    .skip_fill
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

section  .text
global   render_shape ; void render_shape(char * buf, const Camera * cam, const Point3D * vBuf, const u8 * iBuf, u32 iCount)
render_shape:
   ; This function takes in a list of vertices and
   ; indexes into the vertex list to construct a shape.
   ; 
   ; A shape is created by loading in 3 indices from
   ; the index buffer, and using those as offsets into
   ; the vertex buffer to form a triangle.
   ;
   ; Vertex positions are converted into screen coordinates
   ; by multiplying x and y coordinates by their scale factor,
   ; then adding half of C_SIZE_X/Y to the x/y coordinates.
   ; 
   ; In the future, this function will also run the projection
   ; code to allow for 3D triangles.  The color will also depend
   ; on the triangle's angle to the screen.

   %macro LOAD_VERTEX 1
      call  .load_vertex
      mov   %1,rax
   %endmacro

   %macro CONVERT_WORLD_COORD 1
      mov   eax,%1
      call  .convert_world_coord
   %endmacro

   .SBUF_DRAWTRI  equ 16
   .SBUF_CAMERA   equ 8
   .SBUF_VBUF     equ 8
   .SBUF_BUF      equ 8

   .STACKSZ       equ .SBUF_DRAWTRI+.SBUF_VBUF+.SBUF_BUF+8
   .SOFF_DRAWTRI  equ 0
   .SOFF_CAMERA   equ .SBUF_DRAWTRI
   .SOFF_VBUF     equ .SOFF_CAMERA+.SBUF_CAMERA
   .SOFF_BUF      equ .SOFF_VBUF+.SBUF_VBUF

   push  rbx
   push  r12
   push  r13
   push  r14
   push  r15
   sub   rsp,.STACKSZ

   ; Initialize base registers and store data
   mov   ebx,r8d                       ; iCount
   mov   r12,rcx                       ; iBuf
   mov   qword [rsp+.SOFF_VBUF],rdx    ; vBuf
   mov   qword [rsp+.SOFF_CAMERA],rsi  ; cam
   mov   qword [rsp+.SOFF_BUF],rdi     ; buf

   .plot_loop:
   ; Load in the next triangle
   mov   rsi,qword [rsp+.SOFF_VBUF]
   LOAD_VERTEX r13
   LOAD_VERTEX r14
   LOAD_VERTEX r15

   ; TODO: Run the orthographic projection to get the
   ; 2D world coordinates and get the angle of the
   ; triangle to the camera to get the triangle shade
   ; 
   ; Another TODO: Once this is implemented, the triangles
   ; need to be sorted from back to front in order to get
   ; the proper rendering order.  Have fun implementing this
   ; in ASM >:)
   mov   r8d,r13d
   mov   r9d,r14d
   mov   r10d,r15d
   mov   dl,C_FG_SHADE0

   ; Convert form world coords to screen coords and store the result
   lea   rdi,[rsp+.SOFF_DRAWTRI]
   CONVERT_WORLD_COORD r8d
   CONVERT_WORLD_COORD r9d
   CONVERT_WORLD_COORD r10d

   ; Print the triangle and loop
   mov   rdi,qword [rsp+.SOFF_BUF]
   lea   rsi,[rsp+.SOFF_DRAWTRI]
   call  plot_triangle
   xor   eax,eax
   mov   al,3
   .skip_plot:
   sub   ebx,eax
   jge   .plot_loop

   add   rsp,.STACKSZ
   pop   r15
   pop   r14
   pop   r13
   pop   r12
   pop   rbx
   ret

   .load_vertex:
   ; Subroutine that loads in a vertex and increments the pointer
   ; rsi = Pointer to the vBuf
   ; Output is in rax
   movzx eax,byte [r12]
   inc   r12
   lea   rcx,[rax+rax*4]
   add   rcx,rax  ; offset*6
   mov   dx,word [rsi+rcx+4]
   mov   eax,dword [rsi+rcx]
   shl   rdx,32
   or    rax,rdx
   ret

   .convert_world_coord:
   ; Subroutine that converts an input Point2D to screen coordinates and stores the result
   ; eax = input
   ; rdi = output pointer
   mov   ecx,eax
   shr   ecx,16
   
   ; Transformation:
   ; World-coord range:
   ;     x = [-127,128]
   ;     y = [-127,128]
   ; Screen-coord range:
   ;     x = [0,C_SIZE_X-1]
   ;     y = [0,C_SIZE_Y-1]
   ; 
   ; Also need to account for the aspect ratio
   ; of the screen and each pixel (which is 2)
   ; 
   ; Formula for converting:
   ; screen-space x = (x*(C_SIZE_X-1)/256) + C_SIZE_X)/2
   ; screen-space y = y*(C_SIZE_Y-1)/256 + (C_SIZE_Y/2)

   imul  ax,C_SIZE_X-1
   sar   ax,9
   imul  cx,C_SIZE_Y-1
   add   ax,C_SIZE_X/2
   sar   cx,8
   add   cx,C_SIZE_Y/2

   ; Store the result and increment the pointer
   shl   ecx,16
   mov   cx,ax
   xor   eax,eax
   mov   dword [rdi],ecx
   mov   al,4
   add   rdi,rax
   ret

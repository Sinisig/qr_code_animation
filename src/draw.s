;--------------------------------------;
; draw.s - Printing and rendering code ;
; Sinisig 2022                         ;
;--------------------------------------;

%define  DRAW_S_IMPL
%include "Shared.i"
%include "draw.i"


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
global   render_shape ; u32 render_shape(char * buf, const Point2D * vBuf, const u8 * iBuf, u32 iCount)
render_shape:
   ; This function takes in a list of vertices and
   ; indexes into the vertex list to construct a shape
   ; and return the amount of filled in pixels.
   ; 
   ; A shape is created by loading in 3 indices from
   ; the index buffer, and using those as offsets into
   ; the vertex buffer to form a triangle.  That triangle
   ; is then rendered into a character buffer expected to
   ; be an empty rectangle of size C_SIZE_X by C_SIZE_Y.

   .SBUF_VBUF        equ 8
   .SBUF_BUF         equ 8
   .SBUF_AREA_FULL   equ 2
   .SBUF_AREA_PART   equ 2

   .STACKSZ          equ .SBUF_VBUF+.SBUF_BUF+.SBUF_AREA_FULL+.SBUF_AREA_PART+12
   .SOFF_VBUF        equ 0
   .SOFF_BUF         equ .SOFF_VBUF+.SBUF_VBUF
   .SOFF_AREA_FULL   equ .SOFF_BUF+.SBUF_BUF
   .SOFF_AREA_PART   equ .SOFF_AREA_FULL+.SBUF_AREA_FULL

   push  rbx
   push  rbp
   push  r12
   push  r13
   push  r14
   push  r15
   sub   rsp,.STACKSZ

   ; Initialize base registers and store data
   mov   ebx,ecx                       ; iCount
   mov   r12,rdx                       ; iBuf
   mov   qword [rsp+.SOFF_VBUF],rsi    ; vBuf
   mov   qword [rsp+.SOFF_BUF],rdi     ; buf

   .plot_loop:
   ; Load in the next triangle and convert to screen coords
   mov   rsi,qword [rsp+.SOFF_VBUF]
   call  .load_vertex
   mov   r8d,ecx
   call  .load_vertex
   mov   r9d,ecx
   call  .load_vertex
   mov   r10d,ecx

   ; Plot the triangle on screen
   ; This is done by looping for every screen pixel and
   ; seeing if each point is contained inside of the triangle.
   ; This is done by dividing up the main triangle into 3
   ; sub-triangles and getting the area of them.  If the area
   ; is the same as the original triangle, the point is bound.

   ; Get the area of the original triangle
   mov   eax,r8d
   mov   ecx,r9d
   mov   edx,r10d
   call  .tri_area
   mov   word [rsp+.SOFF_AREA_FULL],ax

   mov   r14b,C_SIZE_Y-1      ; y
   mov   r15d,C_CHARCOUNT-2   ; i
   .render_loop_col:
      mov   r13b,C_SIZE_X-1   ; x
      .render_loop_row:
      ; Combine x and y into the point (x,y)
      movzx ebp,r14b
      shl   ebp,16
      movzx bp,r13b

      ; Form 3 sub-triangles using (x,y) and get
      ; their areas
      
      ; p1, p2, ps
      mov   eax,r8d
      mov   ecx,r9d
      mov   edx,ebp
      call  .tri_area
      mov   word [rsp+.SOFF_AREA_PART],ax

      ; p1, ps, p3
      mov   eax,r8d
      mov   ecx,ebp
      mov   edx,r10d
      call  .tri_area
      add   word [rsp+.SOFF_AREA_PART],ax

      ; ps, p2, p3
      mov   eax,ebp
      mov   ecx,r9d
      mov   edx,r10d
      call  .tri_area
      add   ax,word [rsp+.SOFF_AREA_PART]

      ; Is the area non-zero and the same as the
      ; original triangle?
      jz    .not_bound
      cmp   ax,word [rsp+.SOFF_AREA_FULL]
      jne   .not_bound

      ; Fill in the pixel
      mov   rax,qword [rsp+.SOFF_BUF]
      mov   byte [rax+r15],C_FG_SHADE0

      ; Looping code
      .not_bound:
      dec   r15d
      dec   r13b
      jge   .render_loop_row
   dec   r15d
   dec   r14b
   jge   .render_loop_col

   ; Draw the next triangle
   dec   ebx
   jge   .plot_loop

   ; Wrap up and return
   add   rsp,.STACKSZ
   pop   r15
   pop   r14
   pop   r13
   pop   r12
   pop   rbp
   pop   rbx
   ret

   .load_vertex:
   ; Subroutine that loads in a vertex and increments the pointer
   ; It also converts the loaded vertex to screen coordinates
   ; rsi = Pointer to the vBuf
   ; ecx = Output vertex
   ; r12 = Current IB pointer
   
   ; Load the vertex
   movzx eax,byte [r12]
   inc   r12
   mov   eax,dword [rsi+rax*4]
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
   ret

   .tri_area:
   ; Subroutine that calculates the area of a given Triangle2D
   ; 
   ; Input registers:
   ;  eax - Point 1
   ;  ecx - Point 2
   ;  edx - Point 3
   ; 
   ; Output is in eax
   ; 
   ; Formula for calculating area * 2:
   ; a = |x1*(y2-y3) + x2*(y3-y1) + x3*(y1-y2)|

   push  rbp
   push  rbx

   ; Load y1, y2, y3
   mov   ebp,eax
   mov   edi,ecx
   mov   esi,edx
   shr   ebp,16
   shr   edi,16
   shr   esi,16

   ; x3*(y1-y2)
   mov   bx,bp
   sub   bx,di
   imul  dx,bx

   ; x1*(y2-y3)
   sub   di,si
   imul  ax,di

   ; x2*(y3-y1)
   sub   si,bp
   imul  cx,si

   ; Add together and absolute value
   add   ax,cx
   add   ax,dx
   jge   .no_abs
   not   eax   ; 32-bit versions save 2 bytes
   inc   eax

   .no_abs:
   pop   rbx
   pop   rbp
   ret

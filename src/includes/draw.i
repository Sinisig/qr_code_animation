%ifndef DRAW_I
%define DRAW_I
;------------;

%include "Shared.i"

struc Point2D
   .x resw 1
   .y resw 1
endstruc

struc Point3D
   .x resw 1
   .y resw 1
   .z resw 1
endstruc

struc Triangle2D
   .a resw 2
   .b resw 2
   .c resw 2
endstruc

struc Triangle3D
   .a resw 3
   .b resw 3
   .c resw 3
endstruc

%ifndef DRAW_S_IMPL
;=================;
extern print_str     ; void print_str(const char * str, u32 length)
extern clear_con     ; void clear_con(char * buf)
extern plot_triangle ; void plot_triangle(char * buf, const Triangle2D * t, char fillColor)
extern render_shape  ; void render_shape(char * buf, const Point2D * vBuf, const u8 * iBuf, u32 iCount)
;=================;
%endif

;------------;
%endif

%ifndef DRAW_I
%define DRAW_I
;------------;

%include "Shared.i"

struc Point2D
   .x resw 1
   .y resw 1
endstruc

struc Triangle2D
   .a resw 2
   .b resw 2
   .c resw 2
endstruc

%ifndef DRAW_S_IMPL
;=================;
extern print_str     ; void print_str(const char * str, u32 length)
extern render_shape  ; void render_shape(char * buf, const Point2D * vBuf, const u8 * iBuf, u32 iCount)
;=================;
%endif

;------------;
%endif

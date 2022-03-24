%ifndef DRAW_I
%define DRAW_I
;------------;

%include "Shared.i"


%macro PRINTSTR 2
   lea   rdi,[%1]
   mov   esi,%2
   call  print_str
%endmacro

%macro POINTDATA 2
   dd (%2 << 16) | %1
%endmacro

struc Tri
   .a       resd 1
   .b       resd 1
   .c       resd 1
endstruc

%ifndef DRAW_S_IMPL
;=================;
extern print_str     ; void print_str(const char * str, int length)
extern clear_con     ; void clear_con(char * buf)
extern plot_triangle ; void plot_triangle(char * buf, const Tri * t, char fillColor)
;=================;
%endif

;------------;
%endif

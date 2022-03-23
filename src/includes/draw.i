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
   dq (%2 << 32) | %1
%endmacro

struc Tri
   .a       resq 1
   .b       resq 1
   .c       resq 1
   .fill    resb 1
endstruc

%ifndef DRAW_S_IMPL
;=================;
extern print_str
extern clear_con
extern plot_triangle
;=================;
%endif

;------------;
%endif

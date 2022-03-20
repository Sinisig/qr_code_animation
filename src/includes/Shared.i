%ifndef SHARED_I
%define SHARED_I
;--------------;

; Assembler Directives
default  rel
segment  flat
bits     64

; Syscall IDs
SYS_EXIT        equ 3Ch
SYS_WRITE       equ 01h
SYS_NANOSLEEP   equ 23h

; Output Stream File Descriptors
STDOUT      equ 00h
STDIN       equ 01h
STDERR      equ 02h

; Special Characters
C_NULL      equ 00h
C_LF        equ 0Ah
C_ESC       equ 1Bh

;--------------;
%endif

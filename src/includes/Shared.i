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

; Console Window Parameters
; These must be between 0 and 255
%define  C_SIZE_X  43
%define  C_SIZE_Y  13

%defstr  C_SIZE_X_STR C_SIZE_X
%defstr  C_SIZE_Y_STR C_SIZE_Y

C_CHARCOUNT         equ (C_SIZE_X*C_SIZE_Y) + C_SIZE_Y
C_BUFSZ             equ C_CHARCOUNT + (16 - (C_CHARCOUNT % 16)) ; Aligned to 16 bytes
C_BG                equ ' '
C_FG_SHADE0         equ '#'
C_FG_SHADE1         equ 'x'
C_FG_SHADE2         equ 'o'
C_FG_SHADE3         equ '='
C_FG_SHADE4         equ '-'
C_FG_SHADE_COUNT    equ 5

; Animation Parameters
A_LENGTH equ 300  ; Frame count
A_RATE   equ 30   ; Frame rate (fps)

;--------------;
%endif

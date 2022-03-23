;----------------------------------------;
; init.s - Entrypoint of the application ;
; Sinisig 2021-2022                      ;
;----------------------------------------;

%include "Shared.i"

global _entry
extern main


section .text
_entry:
   ; Set up arguments for main (rdi = argc, rsi = argv, rdx = envp)
   mov   edi,[rsp]            ; argc
   lea   rsi,[rsp+08h]        ; argv
   lea   rdx,[rsp+rdi*8+10h]  ; envp

   ; Align the stack on a 16-byte boundary
   and   rsp,0xfffffffffffffff0

   ; Invoke main with argc, argv, and envp
   call  main

   ; Return to the OS with main's returned value (32-bit)
   mov   edi,eax
   xor   eax,eax
   mov   al,SYS_EXIT
   syscall

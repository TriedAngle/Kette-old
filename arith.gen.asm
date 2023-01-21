format ELF64 executable 3

segment readable executable

dump_uint:
mov     r8, -3689348814741910323
sub     rsp, 40
mov     BYTE [rsp+19], 10
lea     rcx, [rsp+18]
.L2:
mov     rax, rdi
mul     r8
mov     rax, rdi
shr     rdx, 3
lea     rsi, [rdx+rdx*4]
add     rsi, rsi
sub     rax, rsi
add     eax, 48
mov     BYTE [rcx], al
mov     rax, rdi
mov     rdi, rdx
mov     rdx, rcx
sub     rcx, 1
cmp     rax, 9
ja      .L2
lea     rax, [rsp+20]
mov     edi, 1
mov     rcx, rax
sub     rcx, rdx
sub     rdx, rax
lea     rsi, [rsp+20+rdx]
mov     rdx, rcx
mov     rax, 1
syscall
add     rsp, 40
ret

entry $
; -- STARTUP -- 
mov rax, RETURN_STACK_END
mov [RETURN_STACK_PTR], rax

; -- PROC DECLERATION --
; - skip -
jmp _Addr0
_Proc0:
; - prepare -
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; - body -
; -- PUSH --
push 69
; -- DUMP --
pop rdi
call dump_uint
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr0:
; -- PROC DECLERATION --
; - skip -
jmp _Addr1
_Proc1:
; - prepare -
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; - body -
; -- PUSH --
push 420
; -- DUMP --
pop rdi
call dump_uint
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr1:
; -- PROC DECLERATION --
; - skip -
jmp _Addr2
_Proc2:
; - prepare -
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; - body -
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc0
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc1
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; -- PUSH --
push 1
; -- DUMP --
pop rdi
call dump_uint
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr2:
; -- PUSH --
push 666
; -- DUMP --
pop rdi
call dump_uint
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc0
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; -- PUSH --
push 666
; -- DUMP --
pop rdi
call dump_uint
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc1
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; -- PUSH --
push 666
; -- DUMP --
pop rdi
call dump_uint
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc2
mov [RETURN_STACK_PTR], rsp
mov rsp, rax

mov rdi, 0
mov rax, 60
syscall

; -- CONST DATA --
segment readable

; -- MUTABLE DATA --
segment readable writable

; -- RETURN STACK --
RETURN_STACK_PTR rq 1
RETURN_STACK rq 512
RETURN_STACK_END:

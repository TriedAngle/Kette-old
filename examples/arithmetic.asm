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

mov rax, rsp
mov [ARGS_COUNT], rax
add rax, 8
mov [ARGS_PTR], rax

; -- PUSH --
push 5
; -- PUSH --
push 7
; -- ADD --
pop rbx
pop rax
add rax, rbx
push rax
; -- PUSH --
push 3
; -- ADD --
pop rbx
pop rax
add rax, rbx
push rax
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 5
; -- PUSH --
push 7
; -- PUSH --
push 3
; -- ADD --
pop rbx
pop rax
add rax, rbx
push rax
; -- ADD --
pop rbx
pop rax
add rax, rbx
push rax
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 19
; -- PUSH --
push 4
; -- MODIV --
pop rbx
pop rax
xor rdx, rdx
div rbx
push rdx
push rax
; -- DUMP --
pop rdi
call dump_uint
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 3
; -- PUSH --
push 1
; -- SUB --
pop rbx
pop rax
sub rax, rbx
push rax
; -- MUL --
pop rbx
pop rax
mul rbx
push rax
; -- PUSH --
push 100
; -- DUMP --
pop rdi
call dump_uint

mov rdi, 0
mov rax, 60
syscall

; -- CONST DATA --
segment readable



; -- MUTABLE DATA --
segment readable writable

; -- RETURN STACK --
RETURN_STACK_PTR rq 1
RETURN_STACK rq 1028
RETURN_STACK_END:
ARGS_COUNT rq 1
ARGS_PTR rq 1

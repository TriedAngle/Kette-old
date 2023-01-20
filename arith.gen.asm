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
; -- PROC DECLERATION --
jmp .Addr0
; -- PUSH --
push 1
; -- DUMP --
pop rdi
call dump_uint
; -- END --
.Addr0:
; -- PUSH --
push 69
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 420
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
RETURN_STACK rq 512
RETURN_STACK_INDEX rq 1

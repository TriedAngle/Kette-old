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
push 3
pop rax
push rax
push rax
pop rbx
pop rax
add rax, rbx
push rax
pop rdi
call dump_uint
push 55
push 3
pop rbx
pop rax
sub rax, rbx
push rax
pop rdi
call dump_uint
push 30
push 9
pop rbx
pop rax
mul rbx
push rax
pop rdi
call dump_uint
push 6
push 3
pop rbx
pop rax
xor rdx, rdx
div rbx
push rax
pop rdi
call dump_uint
push 7
push 4
pop rbx
pop rax
xor rdx, rdx
div rbx
push rdx
pop rdi
call dump_uint

mov rdi, 0
mov rax, 60
syscall

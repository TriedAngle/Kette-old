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
; -- PUSH --
push 100
; -- WHILE --
.Addr2:
; -- DUP --
pop rax
push rax
push rax
; -- PUSH --
push 0
; -- GREATER --
pop rbx
pop rax
xor rcx, rcx
cmp rax, rbx
mov rdx, 1
cmovg rcx, rdx
push rcx
; -- DO --
pop rax
cmp rax, 0
jz .Addr3
; -- DUP --
pop rax
push rax
push rax
; -- PUSH --
push 2
; -- MOD --
pop rbx
pop rax
xor rdx, rdx
div rbx
push rdx
; -- PUSH --
push 0
; -- EQUAL --
pop rbx
pop rax
xor rcx, rcx
cmp rax, rbx
mov rdx, 1
cmove rcx, rdx
push rcx
; -- IF --
pop rax
cmp rax, 0
jz .Addr0
; -- DUP --
pop rax
push rax
push rax
; -- DUMP --
pop rdi
call dump_uint
; -- ELSE --
jmp .Addr1
.Addr0:
; -- DUP --
pop rax
push rax
push rax
; -- PUSH --
push 2
; -- MUL --
pop rbx
pop rax
mul rbx
push rax
; -- DUMP --
pop rdi
call dump_uint
; -- END --
.Addr1:
; -- PUSH --
push 1
; -- SUB --
pop rbx
pop rax
sub rax, rbx
push rax
; -- END --
jmp .Addr2
.Addr3:
; -- PUSH --
push 99999
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 5
; -- PUSH --
push 2
; -- GREATER --
pop rbx
pop rax
xor rcx, rcx
cmp rax, rbx
mov rdx, 1
cmovg rcx, rdx
push rcx
; -- IF --
pop rax
cmp rax, 0
jz .Addr6
; -- PUSH --
push 2
; -- PUSH --
push 5
; -- GREATER --
pop rbx
pop rax
xor rcx, rcx
cmp rax, rbx
mov rdx, 1
cmovg rcx, rdx
push rcx
; -- IF --
pop rax
cmp rax, 0
jz .Addr4
; -- PUSH --
push 2
; -- DUMP --
pop rdi
call dump_uint
; -- ELSE --
jmp .Addr5
.Addr4:
; -- PUSH --
push 3
; -- DUMP --
pop rdi
call dump_uint
; -- END --
.Addr5:
; -- PUSH --
push 420
; -- DUMP --
pop rdi
call dump_uint
; -- ELSE --
jmp .Addr7
.Addr6:
; -- PUSH --
push 69
; -- DUMP --
pop rdi
call dump_uint
; -- END --
.Addr7:
; -- PUSH --
push 10
; -- DUMP --
pop rdi
call dump_uint

mov rdi, 0
mov rax, 60
syscall

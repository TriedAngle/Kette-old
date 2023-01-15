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
push 3
; -- DUP --
pop rax
push rax
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
push 3
; -- PUSH --
push 55
; -- SWAP --
pop rax
pop rbx
push rax
push rbx
; -- SUB --
pop rbx
pop rax
sub rax, rbx
push rax
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 30
; -- PUSH --
push 9
; -- PUSH --
push 3
; -- ROT --
pop rax
pop rbx
pop rcx
push rbx
push rax
push rcx
; -- MUL --
pop rbx
pop rax
mul rbx
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
push 6
; -- PUSH --
push 3
; -- PUSH --
push 7
; -- DROP --
pop r15
xor r15, r15
; -- DIV --
pop rbx
pop rax
xor rdx, rdx
div rbx
push rax
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 69
; -- PUSH --
push 3
; -- 2DUP --
pop rax
pop rbx
push rbx
push rax
push rbx
push rax
; -- DIV --
pop rbx
pop rax
xor rdx, rdx
div rbx
push rax
; -- DUMP --
pop rdi
call dump_uint
; -- DROP --
pop r15
xor r15, r15
; -- PUSH --
push 4
; -- MOD --
pop rbx
pop rax
xor rdx, rdx
div rbx
push rdx
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 5
; -- PUSH --
push 3
; -- 2DUP --
pop rax
pop rbx
push rbx
push rax
push rbx
push rax
; -- MUL --
pop rbx
pop rax
mul rbx
push rax
; -- DUP --
pop rax
push rax
push rax
; -- DUMP --
pop rdi
call dump_uint
; -- SWAP --
pop rax
pop rbx
push rax
push rbx
; -- SUB --
pop rbx
pop rax
sub rax, rbx
push rax
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 69
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 3
; -- PUSH --
push 6
; -- ADD --
pop rbx
pop rax
add rax, rbx
push rax
; -- DUP --
pop rax
push rax
push rax
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 3
; -- MUL --
pop rbx
pop rax
mul rbx
push rax
; -- DUP --
pop rax
push rax
push rax
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 3
; -- DIV --
pop rbx
pop rax
xor rdx, rdx
div rbx
push rax
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 69
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 5
; -- PUSH --
push 5
; -- EQUAL --
pop rbx
pop rax
xor rcx, rcx
cmp rax, rbx
mov rdx, 1
cmove rcx, rdx
push rcx
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 5
; -- PUSH --
push 4
; -- GREATER --
pop rbx
pop rax
xor rcx, rcx
cmp rax, rbx
mov rdx, 1
cmovg rcx, rdx
push rcx
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 5
; -- PUSH --
push 4
; -- LESSER --
pop rbx
pop rax
xor rcx, rcx
cmp rax, rbx
mov rdx, 1
cmovl rcx, rdx
push rcx
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 4
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
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 5
; -- PUSH --
push 4
; -- LESSER --
pop rbx
pop rax
xor rcx, rcx
cmp rax, rbx
mov rdx, 1
cmovl rcx, rdx
push rcx
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 5
; -- PUSH --
push 4
; -- GREATER EQUAL --
pop rbx
pop rax
xor rcx, rcx
cmp rax, rbx
mov rdx, 1
cmovge rcx, rdx
push rcx
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 5
; -- PUSH --
push 5
; -- GREATER EQUAL --
pop rbx
pop rax
xor rcx, rcx
cmp rax, rbx
mov rdx, 1
cmovge rcx, rdx
push rcx
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 4
; -- PUSH --
push 5
; -- LESSER EQUAL --
pop rbx
pop rax
xor rcx, rcx
cmp rax, rbx
mov rdx, 1
cmovle rcx, rdx
push rcx
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 5
; -- PUSH --
push 5
; -- LESSER EQUAL --
pop rbx
pop rax
xor rcx, rcx
cmp rax, rbx
mov rdx, 1
cmovle rcx, rdx
push rcx
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 4
; -- PUSH --
push 5
; -- GREATER EQUAL --
pop rbx
pop rax
xor rcx, rcx
cmp rax, rbx
mov rdx, 1
cmovge rcx, rdx
push rcx
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 5
; -- PUSH --
push 4
; -- LESSER EQUAL --
pop rbx
pop rax
xor rcx, rcx
cmp rax, rbx
mov rdx, 1
cmovle rcx, rdx
push rcx
; -- DUMP --
pop rdi
call dump_uint

mov rdi, 0
mov rax, 60
syscall

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
push 15
; -- WHILE --
.Addr4:
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
jz .Addr5
; -- DUP --
pop rax
push rax
push rax
; -- PUSH --
push 3
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
; -- OVER --
pop rax
pop rbx
push rbx
push rax
push rbx
; -- PUSH --
push 5
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
; -- AND --
pop rbx
pop rax
mov rcx, 1
mov rdx, 0
and rax, rbx
cmp rax, 0
cmovnz rdx, rcx
push rdx
; -- IF --
pop rax
cmp rax, 0
jz .Addr0
; -- PUSH STRING --
push CONST_STRING_1_LEN
push CONST_STRING_1
; -- PUSH --
push 1
; -- PUSH --
push 1
; -- SYSCALL3 --
pop rax
pop rdi
pop rsi
pop rdx
syscall
push rax
; -- DROP --
pop r15
xor r15, r15
; -- PUSH --
push 0
; -- DUMP --
pop rdi
call dump_uint
; -- ELSE --
jmp .Addr3
.Addr0:
; -- DUP --
pop rax
push rax
push rax
; -- PUSH --
push 3
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
jz .Addr1
; -- PUSH STRING --
push CONST_STRING_2_LEN
push CONST_STRING_2
; -- PUSH --
push 1
; -- PUSH --
push 1
; -- SYSCALL3 --
pop rax
pop rdi
pop rsi
pop rdx
syscall
push rax
; -- DROP --
pop r15
xor r15, r15
; -- PUSH --
push 0
; -- DUMP --
pop rdi
call dump_uint
; -- END --
.Addr1:
; -- DUP --
pop rax
push rax
push rax
; -- PUSH --
push 5
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
jz .Addr2
; -- PUSH STRING --
push CONST_STRING_3_LEN
push CONST_STRING_3
; -- PUSH --
push 1
; -- PUSH --
push 1
; -- SYSCALL3 --
pop rax
pop rdi
pop rsi
pop rdx
syscall
push rax
; -- DROP --
pop r15
xor r15, r15
; -- PUSH --
push 0
; -- DUMP --
pop rdi
call dump_uint
; -- END --
.Addr2:
; -- END --
.Addr3:
; -- DUP --
pop rax
push rax
push rax
; -- DUMP --
pop rdi
call dump_uint
; -- PUSH --
push 1
; -- SUB --
pop rbx
pop rax
sub rax, rbx
push rax
; -- END --
jmp .Addr4
.Addr5:

mov rdi, 0
mov rax, 60
syscall

; -- CONST DATA --
segment readable

CONST_STRING_1 db "FizzBuzz"
CONST_STRING_1_LEN = $ - CONST_STRING_1
CONST_STRING_2 db "Fizz"
CONST_STRING_2_LEN = $ - CONST_STRING_2
CONST_STRING_3 db "Buzz"
CONST_STRING_3_LEN = $ - CONST_STRING_3

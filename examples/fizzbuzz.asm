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

; -- PROC DECLERATION --
; - skip -
jmp _Addr0
_Proc0:
; - prepare -
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; - body -
; -- PUSH --
push 1
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
push 1
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
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr2:
; -- PROC DECLERATION --
; - skip -
jmp _Addr3
_Proc3:
; - prepare -
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; - body -
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc1
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc2
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr3:
; -- PUSH --
push 15
; -- WHILE --
_Addr8:
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
jz _Addr9
; -- IF --
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
; -- THEN -- 
pop rax
cmp rax, 0
jz _Addr4
; -- PUSH STRING --
push CONST_STRING_1_LEN
push CONST_STRING_1
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc3
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; -- PUSH --
push 0
; -- DUMP --
pop rdi
call dump_uint
; -- ELSE --
jmp _Addr7
_Addr4:
; -- IF --
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
; -- THEN -- 
pop rax
cmp rax, 0
jz _Addr5
; -- PUSH STRING --
push CONST_STRING_2_LEN
push CONST_STRING_2
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc3
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; -- PUSH --
push 0
; -- DUMP --
pop rdi
call dump_uint
; -- END --
_Addr5:
; -- IF --
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
; -- THEN -- 
pop rax
cmp rax, 0
jz _Addr6
; -- PUSH STRING --
push CONST_STRING_3_LEN
push CONST_STRING_3
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc3
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; -- PUSH --
push 0
; -- DUMP --
pop rdi
call dump_uint
; -- END --
_Addr6:
; -- END --
_Addr7:
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
jmp _Addr8
_Addr9:

mov rdi, 0
mov rax, 60
syscall

; -- CONST DATA --
segment readable

CONST_STRING_1 db "FizzBuzz", 0
CONST_STRING_1_LEN = $ - CONST_STRING_1 - 1
CONST_STRING_2 db "Fizz", 0
CONST_STRING_2_LEN = $ - CONST_STRING_2 - 1
CONST_STRING_3 db "Buzz", 0
CONST_STRING_3_LEN = $ - CONST_STRING_3 - 1


; -- MUTABLE DATA --
segment readable writable

; -- RETURN STACK --
RETURN_STACK_PTR rq 1
RETURN_STACK rq 1028
RETURN_STACK_END:
ARGS_COUNT rq 1
ARGS_PTR rq 1

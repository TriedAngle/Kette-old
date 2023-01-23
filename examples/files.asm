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
push 0
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
; -- PUSH --
push 2
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
; -- PUSH --
push 3
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr3:
; -- PROC DECLERATION --
; - skip -
jmp _Addr4
_Proc4:
; - prepare -
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; - body -
; -- PUSH --
push 8
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr4:
; -- PROC DECLERATION --
; - skip -
jmp _Addr5
_Proc5:
; - prepare -
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; - body -
; -- PUSH --
push 9
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr5:
; -- PROC DECLERATION --
; - skip -
jmp _Addr6
_Proc6:
; - prepare -
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; - body -
; -- PUSH --
push 0
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr6:
; -- PROC DECLERATION --
; - skip -
jmp _Addr7
_Proc7:
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
_Addr7:
; -- PROC DECLERATION --
; - skip -
jmp _Addr8
_Proc8:
; - prepare -
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; - body -
; -- PUSH --
push 64
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr8:
; -- PROC DECLERATION --
; - skip -
jmp _Addr9
_Proc9:
; - prepare -
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; - body -
; -- PUSH --
push 512
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr9:
; -- PROC DECLERATION --
; - skip -
jmp _Addr10
_Proc10:
; - prepare -
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; - body -
; -- PUSH --
push 0
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr10:
; -- PROC DECLERATION --
; - skip -
jmp _Addr11
_Proc11:
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
_Addr11:
; -- PROC DECLERATION --
; - skip -
jmp _Addr12
_Proc12:
; - prepare -
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; - body -
; -- PUSH --
push 2
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr12:
; -- PROC DECLERATION --
; - skip -
jmp _Addr13
_Proc13:
; - prepare -
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; - body -
; -- PUSH --
push 0
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr13:
; -- PROC DECLERATION --
; - skip -
jmp _Addr14
_Proc14:
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
_Addr14:
; -- PROC DECLERATION --
; - skip -
jmp _Addr15
_Proc15:
; - prepare -
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; - body -
; -- PUSH --
push 2
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr15:
; -- PROC DECLERATION --
; - skip -
jmp _Addr16
_Proc16:
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
_Addr16:
; -- PROC DECLERATION --
; - skip -
jmp _Addr17
_Proc17:
; - prepare -
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; - body -
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc14
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc16
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr17:
; -- PROC DECLERATION --
; - skip -
jmp _Addr18
_Proc18:
; - prepare -
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; - body -
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc2
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; -- SYSCALL3 --
pop rax
pop rdi
pop rsi
pop rdx
syscall
push rax
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr18:
; -- PROC DECLERATION --
; - skip -
jmp _Addr19
_Proc19:
; - prepare -
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; - body -
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc12
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; -- PUSH --
push 0
; -- ROT --
pop rax
pop rbx
pop rcx
push rbx
push rax
push rcx
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc4
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; -- SYSCALL3 --
pop rax
pop rdi
pop rsi
pop rdx
syscall
push rax
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr19:
; -- PROC DECLERATION --
; - skip -
jmp _Addr20
_Proc20:
; - prepare -
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; - body -
; -- PUSH --
push 0
; -- 2SWAP --
pop rax
pop rbx
pop rcx
pop rdx
push rbx
push rax
push rdx
push rcx
; -- SWAP --
pop rax
pop rbx
push rax
push rbx
; -- DROP --
pop r15
xor r15, r15
; -- ROT --
pop rax
pop rbx
pop rcx
push rbx
push rax
push rcx
; -- SWAP --
pop rax
pop rbx
push rax
push rbx
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc18
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; -- PROC END --
; - return - 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
ret
; - skip -
_Addr20:
; -- PUSH STRING --
push CONST_STRING_1_LEN
push CONST_STRING_1
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc6
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc20
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; -- DUP --
pop rax
push rax
push rax
; -- DUMP --
pop rdi
call dump_uint
; -- CALL PROC -- 
mov rax, rsp
mov rsp, [RETURN_STACK_PTR]
call _Proc19
mov [RETURN_STACK_PTR], rsp
mov rsp, rax
; -- DUMP --
pop rdi
call dump_uint

mov rdi, 0
mov rax, 60
syscall

; -- CONST DATA --
segment readable

CONST_STRING_1 db "examples/test.txt", 0
CONST_STRING_1_LEN = $ - CONST_STRING_1 - 1


; -- MUTABLE DATA --
segment readable writable

; -- RETURN STACK --
RETURN_STACK_PTR rq 1
RETURN_STACK rq 1028
RETURN_STACK_END:
ARGS_COUNT rq 1
ARGS_PTR rq 1

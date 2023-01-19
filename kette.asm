format ELF64 executable 3

include "linux.inc"

; Tokens
tkNoOp      = 0
tkAdd       = 1
tkSub       = 2
tkMul       = 3
tkDiv       = 4
tkMod       = 5
tkModiv     = 6

tkEqual     = 7
tkGreater   = 8
tkLesser    = 9
tkGEqual    = 10
tkLEqual    = 11
tkAnd       = 12
tkOr        = 13

tkPushInt   = 14
tkDump      = 15
tkDup       = 16
tkSwap      = 17
tkRot       = 18
tkOver      = 19
tkDrop      = 20

tk2Dup      = 21
tk2Swap     = 22
tk2Over     = 23
tk2Drop     = 24

tkIf        = 25
tkThen      = 26
tkElse      = 27
tkWhile     = 28
tkDo        = 29
tkProc      = 30
tkIn        = 31
tkEnd       = 32

tkIdent     = 33
tkPushStr   = 34

tkSys0      = 35
tkSys1      = 36
tkSys2      = 37
tkSys3      = 38
tkSys4      = 39
tkSys5      = 40
tkSys6      = 41

tkExit      = 255


varEndIf    = 1
varEndDo    = 2

segment readable executable

entry $
    push    rbp
    mov     rbp, rsp

    mov     rdi, file0
    call    open_file
    
    lea     r12, [rsp] ; "base pointer"
    push    rax ; ptr file mem  | rbp - 8
    push    rdx ; len file mem  | rbp - 16
    
    xor     rax, rax
    push    rax ; line counter  | rbp - 24
    push    rax ; col counter   | rbp - 32
    push    rax ; offset        | rbp - 40


    ; allocate memory for token loop
    ; start out with 128 bytes
    mov     rdi, 1024
    call    map_memory
    
    push    rax ; ptr token mem | rbp - 48
    push    rdi ; len token mem | rbp - 56

    ; allocate memory for strings
    mov     rdi, 1024
    call    map_memory

    push    rax ; ptr string mem | rbp - 64
    push    rdi ; len string mem | rbp - 72
    xor     rbx, rbx
    push    rbx ; offset string mem | rbp - 80
    mov     rbx, 1
    push    rbx ; string & proc counter | rbp - 88

    ; allocate memory for procs
    mov     rdi, 1024
    call    map_memory

    push    rax ; ptr proc mem | rbp - 96
    push    rdi ; len proc mem | rbp - 104
    xor     rbx, rbx
    push    rbx ; offset proc mem | rbp - 112

    xor     rbx, rbx ; tokenspace offset
    .token_loop:
        mov     rdi, r12
        call    next_string
        ; rax = ptr sub string | 0 = reached end
        ; rdx = len sub string
        cmp     rax, 0
        jz      .exit_token_loop;

        mov     r13, rax ; ptr sub string
        mov     r14, rdx
        
        mov     r15, -1
        ; checking for symbol
        ; cmov does not support consts lol, x86-64 moment!
        ; rax is used as an intermediate register bc of that
        ; this looks a bit dirty, but avoids branching :)
        mov     rax, tkAdd
        cmp     BYTE [r13], "+"
        cmovz   r15, rax

        mov     rax, tkSub
        cmp     BYTE [r13], "-"
        cmovz   r15, rax
        
        mov     rax, tkMul
        cmp     BYTE [r13], "*"
        cmovz   r15, rax
        
        mov     rax, tkDiv
        cmp     BYTE [r13], "/"
        cmovz   r15, rax

        mov     rax, tkMod
        cmp     BYTE [r13], "%"
        cmovz   r15, rax
        
        mov     rax, tkModiv
        cmp     WORD [r13], "/%"
        cmovz   r15, rax

        mov     rax, tkDump
        cmp     BYTE [r13], "."
        cmovz   r15, rax

        mov     rax, tkEqual
        cmp     BYTE [r13], "="
        cmovz   r15, rax

        mov     rax, tkGreater
        cmp     BYTE [r13], ">"
        cmovz   r15, rax

        mov     rax, tkLesser
        cmp     BYTE [r13], "<"
        cmovz   r15, rax

        mov     rax, tkGEqual
        cmp     WORD [r13], ">="
        cmovz   r15, rax

        mov     rax, tkLEqual
        cmp     WORD [r13], "<="
        cmovz   r15, rax

        cmp     BYTE [r13], 34  ; strings are already "checked" in word generation
        jz      .finalize_string

        ; if opcode was set (so not -1), jump to symbol handling
        ; if opcode was not set, continue checking what it is
        cmp     r15, -1
        jnz     .finalize_symbol
        jmp     .no_symbol

    
        .finalize_string:
        mov     rdi, [rbp - 48]
        mov     BYTE [rdi + rbx], tkPushStr
        mov     eax, DWORD [rbp - 24]
        mov     r8d, DWORD [rbp - 32]
        mov     DWORD [rdi + rbx + 1], eax
        mov     DWORD [rdi + rbx + 5], r8d
        ; skip "
        mov     r8, r14
        lea     rax, [r13]

        mov     rcx, [rbp - 64] ; ptr string mem
        mov     rdx, [rbp - 104] ; string mem offset
        
        mov     rdx, QWORD [rbp - 80]
        mov     r10, QWORD [rbp - 88]
        
        mov     QWORD [rdi + rbx + 9], r10 ; string id

        mov     QWORD [rcx + rdx], r10 ; string id
        mov     QWORD [rcx + rdx + 8], r8 ; string len
        mov     QWORD [rcx + rdx + 16], rax ; ptr string
        
        add     QWORD [rbp - 80], 24
        inc     QWORD [rbp - 88]

        jmp     .end_word


        .finalize_symbol:
        mov     rdi, [rbp - 48] ; ptr of token memory
        mov     BYTE [rdi + rbx], r15b
        mov     eax, DWORD [rbp - 24]
        mov     r8d, DWORD [rbp - 32]
        mov     DWORD [rdi + rbx + 1], eax
        mov     DWORD [rdi + rbx + 5], r8d
        jmp     .end_word

        .no_symbol:
        ; checking for keyword
        
       
        mov     rdi, r13
        lea     rsi, [KEY_DUP]
        mov     rdx, KEY_DUP_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkDup
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_SWAP]
        mov     rdx, KEY_SWAP_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkSwap
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_ROT]
        mov     rdx, KEY_ROT_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkRot
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_OVER]
        mov     rdx, KEY_OVER_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkOver
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_DROP]
        mov     rdx, KEY_DROP_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkDrop
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_2DUP]
        mov     rdx, KEY_2DUP_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tk2Dup
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_2SWAP]
        mov     rdx, KEY_2SWAP_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tk2Swap
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_2DROP]
        mov     rdx, KEY_2DROP_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tk2Drop
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_AND]
        mov     rdx, KEY_AND_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkAnd
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_OR]
        mov     rdx, KEY_OR_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkOr
        jz      .finalize_keyword_simple
        
        mov     rdi, r13
        lea     rsi, [KEY_IF]
        mov     rdx, KEY_IF_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkIf
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_THEN]
        mov     rdx, KEY_THEN_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkThen
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_ELSE]
        mov     rdx, KEY_ELSE_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkElse
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_WHILE]
        mov     rdx, KEY_WHILE_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkWhile
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_DO]
        mov     rdx, KEY_DO_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkDo
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_PROC]
        mov     rdx, KEY_PROC_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkProc
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_END]
        mov     rdx, KEY_END_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkEnd
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_SYS0]
        mov     rdx, KEY_SYS0_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkSys0
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_SYS1]
        mov     rdx, KEY_SYS1_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkSys1
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_SYS2]
        mov     rdx, KEY_SYS2_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkSys2
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_SYS3]
        mov     rdx, KEY_SYS3_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkSys3
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_SYS4]
        mov     rdx, KEY_SYS4_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkSys4
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_SYS5]
        mov     rdx, KEY_SYS5_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkSys5
        jz      .finalize_keyword_simple

        mov     rdi, r13
        lea     rsi, [KEY_SYS6]
        mov     rdx, KEY_SYS6_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     r15, tkSys6
        jz      .finalize_keyword_simple
        

        jmp     .no_keyword
        
        .finalize_keyword_simple:
        mov     rdi, [rbp - 48]
        mov     BYTE [rdi + rbx], r15b
        mov     eax, DWORD [rbp - 24]
        mov     r8d, DWORD [rbp - 32]
        mov     DWORD [rdi + rbx + 1], eax
        mov     DWORD [rdi + rbx + 5], r8d
        mov     QWORD [rdi + rbx + 9], 0
        mov     QWORD [rdi + rbx + 17], 0
        mov     WORD [rdi + rbx + 25], 0
        jmp     .end_word   

        .no_keyword:

        
        ; check if number
        xor     rcx, rcx
        xor     rax, rax
        .check_if_number_loop:
            cmp     BYTE [r13 + rcx], "0"
            jl      .parse_not_number

            cmp     BYTE [r13 + rcx], "_"
            jz      .check_if_number_loop_next

            cmp     BYTE [r13 + rcx], "9"
            jg      .parse_not_number

            .check_if_number_loop_next:
            inc     rcx
            cmp     rcx, r14
            jz      .parse_number
            jmp     .check_if_number_loop

        .parse_not_number:
        mov     rdi, [rbp - 48]
        mov     BYTE [rdi + rbx], tkIdent
        mov     r8d, DWORD [rbp - 24]
        mov     r9d, DWORD [rbp - 32]
        mov     DWORD [rdi + rbx + 1], r8d
        mov     DWORD [rdi + rbx + 5], r9d
        mov     QWORD [rdi + rbx + 9], r13 ; ptr start
        mov     QWORD [rdi + rbx + 17], r14 ; length
        jmp     .end_word

        .parse_number:
        xor     rax, rax ; number
        xor     rcx, rcx ; digit counter
        xor     rdi, rdi ; ascii translation 
        mov     r8 , 10
        .parse_number_loop:
            mul     r8
            mov     dil, BYTE [r13 + rcx]
            sub     dil, 48 
            add     rax, rdi
            inc     rcx
            cmp     rcx, r14
            ; TODO: check for number only whitespace sep,
            ; error on 47<x<57
            jz      .finish_number
            jmp     .parse_number_loop
        
        .finish_number:
            mov     rdi, [rbp - 48] ; ptr of token memory
            mov     BYTE [rdi + rbx], tkPushInt
            mov     r8d, DWORD [rbp - 24]
            mov     r9d, DWORD [rbp - 32]
            mov     DWORD [rdi + rbx + 1], r8d
            mov     DWORD [rdi + rbx + 5], r9d
            mov     QWORD [rdi + rbx + 9], rax

        .end_word:
        add     rbx, 32  
        jmp     .token_loop

    .exit_token_loop:
  
    
    ;   rbx -> r12 | token mem effective len
    mov     r12, rbx
 
    mov     rax, [rbp - 48]
    lea     r13, [rax]  ; token file ptr
 
    ; Cross Referencing control flows & detect missing
    xor     rbx, rbx
    xor     r14, r14; Count the stack size to find errors
    xor     r15, r15; address counter
    .loop_cross_reference:
        cmp     rbx, r12
        jz      .loop_cross_reference_stop 
   
        cmp     BYTE [r13 + rbx], tkIf
        jz      .cross_reference_if
        
        cmp     BYTE [r13 + rbx], tkElse
        jz      .cross_reference_else

        cmp     BYTE [r13 + rbx], tkWhile
        jz      .cross_reference_while

        cmp     BYTE [r13 + rbx], tkDo
        jz      .cross_reference_do
        
        cmp     BYTE [r13 + rbx], tkEnd
        jz      .cross_reference_end

        jmp     .loop_cross_reference_end

        .cross_reference_if:
        push    rbx
        inc     r14
        jmp     .loop_cross_reference_end

        .cross_reference_else:
        cmp     r14, 0
        je      error_else_without_if
        pop     rax
        mov     QWORD [r13 + rax + 9], r15
        mov     QWORD [r13 + rbx + 17], r15 ; for if to jump to if false
        inc     r15
        push    rbx
        jmp     .loop_cross_reference_end ; r14 stays the same


        .cross_reference_while:
        push    rbx
        inc     r14
        jmp     .loop_cross_reference_end

        .cross_reference_do:
        cmp     r14, 0
        je      error_do_without_while
        pop     rax
        mov     QWORD [r13 + rbx + 9], rax ; write while in do, so it can be referenced in end
        push    rbx
        jmp     .loop_cross_reference_end

        .cross_reference_end:
        cmp     r14, 0
        je      error_too_many_end
        ; pop the last if and write current jump counter in both
        pop     rax
        dec     r14

        cmp     BYTE [r13 + rax], tkDo
        jz      .cross_reference_end_do
        cmp     BYTE [r13 + rax], tkElse
        jz      .cross_reference_end_else
        
        .cross_reference_end_if:
            ; handle if
            mov     QWORD [r13 + rax + 9], r15 
            mov     BYTE  [r13 + rbx + 9], varEndIf ;
            mov     QWORD [r13 + rbx + 10], r15
            inc     r15
            jmp     .loop_cross_reference_end
        
        .cross_reference_end_do:
            ; rax = do
            ; rdi = while
            mov     rdi, [r13 + rax + 9]
            
            mov     [r13 + rdi + 9], r15 ; while label
            mov     BYTE [r13 + rbx + 9], varEndDo
            mov     [r13 + rbx + 10], r15 ; jmp while label
            
            inc     r15
            mov     [r13 + rax + 9], r15 ; jmp end label
            mov     [r13 + rbx + 18], r15 ; end label
            
            inc     r15
            jmp     .loop_cross_reference_end

        .cross_reference_end_else:
            mov     [r13 + rax + 9], r15
            mov     BYTE [r13 + rbx + 9], varEndIf ; should be able to reuse this
            mov     [r13 + rbx + 10], r15
            inc     r15
            jmp     .loop_cross_reference_end
    
        .loop_cross_reference_end:
        add     rbx, 32
            
        jmp     .loop_cross_reference

        
    .loop_cross_reference_stop:

    cmp     r14, 0
    jg     error_if_without_end


    ; allocate memory
    mov     rdi, 2048
    call    map_memory
    push    rax ; [rbp - 120] = ptr | output file
    push    rdi ; [rbp - 128] = len | output file
 
    xor     rbx, rbx ; tokenspace offset
    xor     r15, r15 ; output file offset 
    
    push    rbx ; [rbp - 136] = string data offset | 24 bytes aligned
    
    mov     rax, [rbp - 48]
    lea     r13, [rax]  ; token file ptr
    mov     rax, [rbp - 120]
    lea     r14, [rax]  ; output file ptr

    lea     rdi, [r14 + r15]
    mov     rsi, ASM_HEADER
    mov     rdx, ASM_HEADER_LEN
    call    mem_move
    add     r15, ASM_HEADER_LEN

    .loop_bytecode_to_asm:
        cmp     BYTE [r13 + rbx], tkPushInt
        jz      .output_push_int
        
        cmp     BYTE [r13 + rbx], tkAdd
        jz      .output_add

        cmp     BYTE [r13 + rbx], tkSub
        jz      .output_sub

        cmp     BYTE [r13 + rbx], tkMul
        jz      .output_mul

        cmp     BYTE [r13 + rbx], tkDiv
        jz      .output_div

        cmp     BYTE [r13 + rbx], tkMod
        jz      .output_mod
        
        cmp     BYTE [r13 + rbx], tkModiv
        jz      .output_modiv


        cmp     BYTE [r13 + rbx], tkEqual
        jz      .output_equal

        cmp     BYTE [r13 + rbx], tkGreater
        jz      .output_greater

        cmp     BYTE [r13 + rbx], tkLesser
        jz      .output_lesser

        cmp     BYTE [r13 + rbx], tkGEqual
        jz      .output_greater_equal

        cmp     BYTE [r13 + rbx], tkLEqual
        jz      .output_lesser_equal

        cmp     BYTE [r13 + rbx], tkAnd
        jz      .output_and

        cmp     BYTE [r13 + rbx], tkOr
        jz      .output_or


        cmp     BYTE [r13 + rbx], tkDump
        jz      .output_dump

        cmp     BYTE [r13 + rbx], tkDup
        jz      .output_dup

        cmp     BYTE [r13 + rbx], tkSwap
        jz      .output_swap

        cmp     BYTE [r13 + rbx], tkRot
        jz      .output_rot

        cmp     BYTE [r13 + rbx], tkOver
        jz      .output_over

        cmp     BYTE [r13 + rbx], tkDrop
        jz      .output_drop

        cmp     BYTE [r13 + rbx], tk2Dup
        jz      .output_2dup

        cmp     BYTE [r13 + rbx], tk2Swap
        jz      .output_2swap

        cmp     BYTE [r13 + rbx], tk2Drop
        jz      .output_2drop

        cmp     BYTE [r13 + rbx], tkIf
        jz      .output_if

        cmp     BYTE [r13 + rbx], tkElse
        jz      .output_else

        cmp     BYTE [r13 + rbx], tkWhile
        jz      .output_while

        cmp     BYTE [r13 + rbx], tkDo
        jz      .output_do
        
        cmp     BYTE [r13 + rbx], tkEnd
        jz      .output_end

        cmp     BYTE [r13 + rbx], tkSys0
        jz      .output_syscall0
        cmp     BYTE [r13 + rbx], tkSys1
        jz      .output_syscall1
        cmp     BYTE [r13 + rbx], tkSys2
        jz      .output_syscall2
        cmp     BYTE [r13 + rbx], tkSys3
        jz      .output_syscall3
        cmp     BYTE [r13 + rbx], tkSys4
        jz      .output_syscall4
        cmp     BYTE [r13 + rbx], tkSys5
        jz      .output_syscall5
        cmp     BYTE [r13 + rbx], tkSys6
        jz      .output_syscall6

        cmp     BYTE [r13 + rbx], tkPushStr
        jz      .output_push_string

        cmp     BYTE [r13 + rbx], tkNoOp
        jz      .output_jmp_end ; skip no ops

        ; TODO: handle unknown bytecode
        ; could also detect wrong offsetting
        jmp     .output_jmp_end

        .output_push_int:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_PUSH
            mov     rdx, ASM_PUSH_LEN
            call    mem_move
            add     r15, ASM_PUSH_LEN
        
            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 9]
            call    uitds ; rdx = len
        
            lea     rdi, [r14 + r15]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20 ; reset stack
            add     r15, rdx
            
            mov     BYTE [r14 + r15], 10
            add     r15, 1
            jmp    .output_jmp_end
        
        .output_push_string:
            ; - 64  = string mem
            ; layout: 8 byte id, 8 byte len, 8 byte ptr | 24 len
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_PUSH_STR_L
            mov     rdx, ASM_PUSH_STR_L_LEN
            call    mem_move
            add     r15, ASM_PUSH_STR_L_LEN

            lea     rdi, [r14 + r15]
            mov     rsi, ASM_PUSH_STR
            mov     rdx, ASM_PUSH_STR_LEN
            call    mem_move
            add     r15, ASM_PUSH_STR_LEN

            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 9]
            call    uitds

            lea     rdi, [r14 + r15]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r15, rdx

            lea     rdi, [r14 + r15]
            mov     rsi, ASM_CONST_STR_L
            mov     rdx, ASM_CONST_STR_L_LEN
            call    mem_move
            add     r15, ASM_CONST_STR_L_LEN
            
            lea     rdi, [r14 + r15]
            mov     rsi, newline
            mov     rdx, 1
            call    mem_move
            add     r15, 1

            lea     rdi, [r14 + r15]
            mov     rsi, ASM_PUSH_STR
            mov     rdx, ASM_PUSH_STR_LEN
            call    mem_move
            add     r15, ASM_PUSH_STR_LEN
            
            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 9]
            call    uitds

            lea     rdi, [r14 + r15]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r15, rdx

            lea     rdi, [r14 + r15]
            mov     rsi, newline
            mov     rdx, 1
            call    mem_move
            add     r15, 1

           
            jmp     .output_jmp_end

        .output_add:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_ADD
            mov     rdx, ASM_ADD_LEN
            call    mem_move
            add     r15, ASM_ADD_LEN
            jmp    .output_jmp_end

        .output_sub:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_SUB
            mov     rdx, ASM_SUB_LEN
            call    mem_move
            add     r15, ASM_SUB_LEN
            jmp    .output_jmp_end

        .output_mul:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_MUL
            mov     rdx, ASM_MUL_LEN
            call    mem_move
            add     r15, ASM_MUL_LEN
            jmp    .output_jmp_end

        .output_div:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_DIV
            mov     rdx, ASM_DIV_LEN
            call    mem_move
            add     r15, ASM_DIV_LEN
            jmp    .output_jmp_end

        .output_mod:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_MOD
            mov     rdx, ASM_MOD_LEN
            call    mem_move
            add     r15, ASM_MOD_LEN
            jmp    .output_jmp_end
        
        .output_modiv:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_MODIV
            mov     rdx, ASM_MODIV_LEN
            call    mem_move
            add     r15, ASM_MODIV_LEN
            jmp    .output_jmp_end

       .output_equal:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_EQUAL
            mov     rdx, ASM_EQUAL_LEN
            call    mem_move
            add     r15, ASM_EQUAL_LEN
            jmp    .output_jmp_end

       .output_greater:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_GREATER
            mov     rdx, ASM_GREATER_LEN
            call    mem_move
            add     r15, ASM_GREATER_LEN
            jmp    .output_jmp_end

       .output_lesser:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_LESSER
            mov     rdx, ASM_LESSER_LEN
            call    mem_move
            add     r15, ASM_LESSER_LEN
            jmp    .output_jmp_end

       .output_greater_equal:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_GEQUAL
            mov     rdx, ASM_GEQUAL_LEN
            call    mem_move
            add     r15, ASM_GEQUAL_LEN
            jmp    .output_jmp_end

       .output_lesser_equal:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_LEQUAL
            mov     rdx, ASM_LEQUAL_LEN
            call    mem_move
            add     r15, ASM_LEQUAL_LEN
            jmp    .output_jmp_end
       
       .output_and:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_AND
            mov     rdx, ASM_AND_LEN
            call    mem_move
            add     r15, ASM_AND_LEN
            jmp    .output_jmp_end

       .output_or:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_OR
            mov     rdx, ASM_OR_LEN
            call    mem_move
            add     r15, ASM_OR_LEN
            jmp    .output_jmp_end


        .output_dump:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_DUMP
            mov     rdx, ASM_DUMP_LEN
            call    mem_move
            add     r15, ASM_DUMP_LEN
            jmp    .output_jmp_end
        
        .output_dup:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_DUP
            mov     rdx, ASM_DUP_LEN
            call    mem_move
            add     r15, ASM_DUP_LEN
            jmp    .output_jmp_end
        
        .output_swap:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_SWAP
            mov     rdx, ASM_SWAP_LEN
            call    mem_move
            add     r15, ASM_SWAP_LEN
            jmp    .output_jmp_end
 
        .output_rot:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_ROT
            mov     rdx, ASM_ROT_LEN
            call    mem_move
            add     r15, ASM_ROT_LEN
            jmp    .output_jmp_end 
 
        .output_over:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_OVER
            mov     rdx, ASM_OVER_LEN
            call    mem_move
            add     r15, ASM_OVER_LEN
            jmp    .output_jmp_end
 
        .output_drop:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_DROP
            mov     rdx, ASM_DROP_LEN
            call    mem_move
            add     r15, ASM_DROP_LEN
            jmp    .output_jmp_end
 
        .output_2dup:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_2DUP
            mov     rdx, ASM_2DUP_LEN
            call    mem_move
            add     r15, ASM_2DUP_LEN
            jmp    .output_jmp_end
 
        .output_2swap:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_2SWAP
            mov     rdx, ASM_2SWAP_LEN
            call    mem_move
            add     r15, ASM_2SWAP_LEN
            jmp    .output_jmp_end
 
        .output_2drop:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_2SWAP
            mov     rdx, ASM_2SWAP_LEN
            call    mem_move
            add     r15, ASM_2SWAP_LEN
            jmp    .output_jmp_end
 
        
        .output_if:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_IF
            mov     rdx, ASM_IF_LEN
            call    mem_move
            add     r15, ASM_IF_LEN

            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 9]
            call    uitds
            lea     rdi, [r14 + r15]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r15, rdx

            mov     BYTE [r14 + r15], 10
            add     r15, 1
            jmp     .output_jmp_end
        

        .output_else:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_ELSE
            mov     rdx, ASM_ELSE_LEN
            call    mem_move
            add     r15, ASM_ELSE_LEN
            
            ; jump to end after if
            
            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 9]
            call    uitds
            lea     rdi, [r14 + r15]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r15, rdx

            mov     BYTE [r14 + r15], 10
            add     r15, 1
            
            ; jump for if
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_END_ADDR
            mov     rdx, ASM_END_ADDR_LEN
            call    mem_move
            add     r15, ASM_END_ADDR_LEN
            
            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 17]
            call    uitds
            lea     rdi, [r14 + r15]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r15, rdx
            

            lea     rdi, [r14 + r15]
            mov     rsi, ASM_END_AEND
            mov     rdx, ASM_END_AEND_LEN
            call    mem_move
            add     r15, ASM_END_AEND_LEN
            
            jmp     .output_jmp_end
            

        .output_while:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_WHILE
            mov     rdx, ASM_WHILE_LEN
            call    mem_move
            add     r15, ASM_WHILE_LEN

            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 9]
            call    uitds
            lea     rdi, [r14 + r15]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r15, rdx
            
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_END_AEND
            mov     rdx, ASM_END_AEND_LEN
            call    mem_move
            add     r15, ASM_END_AEND_LEN

            jmp     .output_jmp_end


        .output_do:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_DO
            mov     rdx, ASM_DO_LEN
            call    mem_move
            add     r15, ASM_DO_LEN

            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 9]
            call    uitds
            lea     rdi, [r14 + r15]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r15, rdx

            mov     BYTE [r14 + r15], 10
            add     r15, 1
            jmp     .output_jmp_end

        .output_end:
            cmp     BYTE [r13 + rbx + 9], varEndIf
            jz      .output_end_var_if
            cmp     BYTE [r13 + rbx + 9], varEndDo
            jz      .output_end_var_do

            ; TODO: HANDLE INVALID END VARIATION 
            
            .output_end_var_if: 
                lea     rdi, [r14 + r15]
                mov     rsi, ASM_END_L
                mov     rdx, ASM_END_L_LEN
                call    mem_move
                add     r15, ASM_END_L_LEN

                lea     rdi, [r14 + r15]
                mov     rsi, ASM_END_ADDR
                mov     rdx, ASM_END_ADDR_LEN
                call    mem_move
                add     r15, ASM_END_ADDR_LEN

                lea     rsi, [rsp]
                sub     rsp, 20
                mov     rdi, [r13 + rbx + 10]
                call    uitds

                lea     rdi, [r14 + r15]
                mov     rsi, rax
                call    mem_move
                add     rsp, 20
                add     r15, rdx
                
                lea     rdi, [r14 + r15]
                mov     rsi, ASM_END_AEND
                mov     rdx, ASM_END_AEND_LEN
                call    mem_move
                add     r15, ASM_END_AEND_LEN

                jmp     .output_jmp_end

            .output_end_var_do:
                lea     rdi, [r14 + r15]
                mov     rsi, ASM_END_L
                mov     rdx, ASM_END_L_LEN
                call    mem_move
                add     r15, ASM_END_L_LEN

                lea     rdi, [r14 + r15]
                mov     rsi, ASM_END_JMP
                mov     rdx, ASM_END_JMP_LEN
                call    mem_move
                add     r15, ASM_END_JMP_LEN
                
                lea     rsi, [rsp]
                sub     rsp, 20
                mov     rdi, [r13 + rbx + 10]
                call    uitds

                lea     rdi, [r14 + r15]
                mov     rsi, rax
                call    mem_move
                add     rsp, 20
                add     r15, rdx

                lea     rdi, [r14 + r15]
                mov     rsi, newline
                mov     rdx, 1
                call    mem_move
                add     r15, 1

                lea     rdi, [r14 + r15]
                mov     rsi, ASM_END_ADDR
                mov     rdx, ASM_END_ADDR_LEN
                call    mem_move
                add     r15, ASM_END_ADDR_LEN
                
                lea     rsi, [rsp]
                sub     rsp, 20
                mov     rdi, [r13 + rbx + 18]
                call    uitds

                lea     rdi, [r14 + r15]
                mov     rsi, rax
                call    mem_move
                add     rsp, 20
                add     r15, rdx
                
                lea     rdi, [r14 + r15]
                mov     rsi, ASM_END_AEND
                mov     rdx, ASM_END_AEND_LEN
                call    mem_move
                add     r15, ASM_END_AEND_LEN

                jmp     .output_jmp_end
 
        .output_syscall0:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_SYS0
            mov     rdx, ASM_SYS0_LEN
            call    mem_move
            add     r15, ASM_SYS0_LEN
            jmp     .output_jmp_end
     
        .output_syscall1:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_SYS1
            mov     rdx, ASM_SYS1_LEN
            call    mem_move
            add     r15, ASM_SYS1_LEN
            jmp     .output_jmp_end


        .output_syscall2:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_SYS2
            mov     rdx, ASM_SYS2_LEN
            call    mem_move
            add     r15, ASM_SYS2_LEN
            jmp     .output_jmp_end


        .output_syscall3:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_SYS3
            mov     rdx, ASM_SYS3_LEN
            call    mem_move
            add     r15, ASM_SYS3_LEN
            jmp     .output_jmp_end


        .output_syscall4:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_SYS4
            mov     rdx, ASM_SYS4_LEN
            call    mem_move
            add     r15, ASM_SYS4_LEN
            jmp     .output_jmp_end


        .output_syscall5:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_SYS5
            mov     rdx, ASM_SYS5_LEN
            call    mem_move
            add     r15, ASM_SYS5_LEN
            jmp     .output_jmp_end
 
        .output_syscall6:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_SYS6
            mov     rdx, ASM_SYS6_LEN
            call    mem_move
            add     r15, ASM_SYS6_LEN
            jmp     .output_jmp_end


        .output_jmp_end:
        add rbx, 32
        cmp rbx, r12
        jnz .loop_bytecode_to_asm
    
  
    lea     rdi, [r14 + r15]
    mov     rsi, ASM_ENDING
    mov     rdx, ASM_ENDING_LEN
    call    mem_move
    add     r15, ASM_ENDING_LEN

    lea     rdi, [r14 + r15]
    mov     rsi, ASM_CONST_DATA_SECTION
    mov     rdx, ASM_CONST_DATA_SECTION_LEN
    call    mem_move
    add     r15, ASM_CONST_DATA_SECTION_LEN

    ; CONST DATA:
    xor     rbx, rbx ; counter inc in 24
    mov     rax, [rbp - 64] ; ptr string mem
    lea     r13, [rax]
    .loop_add_const_strings:
        cmp     rbx, QWORD [rbp - 80]
        jz      .exit_loop_add_const_strings
        
        lea     rdi, [r14 + r15]
        mov     rsi, ASM_CONST_STR
        mov     rdx, ASM_CONST_STR_LEN
        call    mem_move
        add     r15, ASM_CONST_STR_LEN
    
        lea     rsi, [rsp]
        sub     rsp, 20
        mov     rdi, [r13 + rbx]
        call    uitds

        lea     rdi, [r14 + r15]
        mov     rsi, rax
        call    mem_move
        add     rsp, 20
        add     r15, rdx

        lea     rdi, [r14 + r15]
        mov     rsi, ASM_DB_WORD
        mov     rdx, ASM_DB_WORD_LEN
        call    mem_move
        add     r15, ASM_DB_WORD_LEN

        lea     rdi, [r14 + r15]
        mov     rsi, [r13 + rbx + 16]
        mov     rdx, [r13 + rbx + 8]
        call    mem_move
        add     r15, [r13 + rbx + 8]
        
        lea     rdi, [r14 + r15]
        mov     rsi, newline
        mov     rdx, 1
        call    mem_move
        add     r15, 1

        lea     rdi, [r14 + r15]
        mov     rsi, ASM_CONST_STR
        mov     rdx, ASM_CONST_STR_LEN
        call    mem_move
        add     r15, ASM_CONST_STR_LEN
        
        lea     rsi, [rsp]
        sub     rsp, 20
        mov     rdi, [r13 + rbx]
        call    uitds

        lea     rdi, [r14 + r15]
        mov     rsi, rax
        call    mem_move
        add     rsp, 20
        add     r15, rdx

        lea     rdi, [r14 + r15]
        mov     rsi, ASM_CONST_STR_L
        mov     rdx, ASM_CONST_STR_L_LEN
        call    mem_move
        add     r15, ASM_CONST_STR_L_LEN

        lea     rdi, [r14 + r15]
        mov     rsi, ASM_EQ_LEN_WORD
        mov     rdx, ASM_EQ_LEN_WORD_LEN
        call    mem_move
        add     r15, ASM_EQ_LEN_WORD_LEN

        lea     rdi, [r14 + r15]
        mov     rsi, ASM_CONST_STR
        mov     rdx, ASM_CONST_STR_LEN
        call    mem_move
        add     r15, ASM_CONST_STR_LEN

        lea     rsi, [rsp]
        sub     rsp, 20
        mov     rdi, [r13 + rbx]
        call    uitds

        lea     rdi, [r14 + r15]
        mov     rsi, rax
        call    mem_move
        add     rsp, 20
        add     r15, rdx

        lea     rdi, [r14 + r15]
        mov     rsi, newline
        mov     rdx, 1
        call    mem_move
        add     r15, 1

        add     rbx, 24
        jmp .loop_add_const_strings
    .exit_loop_add_const_strings:


    mov     rdi, file2
    mov     rsi, O_WRONLY or O_CREAT or O_TRUNC
    xor     rdx, rdx
    mov     rax, SYS_OPEN
    syscall

    ; write assembly
    mov     rdi, rax
    mov     rsi, [rbp - 120]
    mov     rdx, r15
    mov     rax, SYS_WRITE
    syscall

    ; dealloc file
    mov     rdi, [rbp - 8]
    mov     rsi, [rbp - 16]
    call unmap_memory

    ; dealloc tokenspace
    mov     rdi, [rbp - 48]
    mov     rsi, [rbp - 56]
    call unmap_memory

    mov     rsp, rbp
    pop     rbp

    mov     rdi, 0
    mov     rax, SYS_EXIT
    syscall


; input:
;   rdi: "base pointer"
;       ptr string     | - 8
;       len string     | - 16
;       line counter   | - 24
;       col counter    | - 32
;       sub index      | - 40
; output:
;   rax: ptr sub-string | ptr == null => over
;   rdx: len sub-string
next_string:
    push rbp
    mov rbp, rsp
    push r15
    push r14
    push r13
    push r12
    push rbx

    mov r12, rdi ; base pointer
    
    mov rax, [r12 - 8]   ; string ptr
    mov rbx, [r12 - 40]  ; offset
    lea r13, [rax + rbx] ; current iter start
    
    mov r14, rbx ; total offset
    
    cmp r14, [r12 - 16]
    jz .end_of_string

    xor rbx, rbx ; skipped whitespaces
    .loop_trim_left:
        cmp BYTE [r13 + rbx], 10
        jz .handle_whitespace
        cmp BYTE [r13 + rbx], 32
        jz .handle_newline
        
        cmp r14, [r12 - 16]
        jz .end_of_string

        jmp .found_word
        
        .handle_newline:
            inc QWORD [r12 - 24]
            mov QWORD [r12 - 32], 0 ; reset column counter
        .handle_whitespace:
            inc rbx
            inc r14
            jmp .loop_trim_left
 
    .found_word:
    lea r13, [r13 + rbx] ; first non whitespace
    xor rcx, rcx ; word len
  
    xor r15, r15 ; is in "

    .loop_until_whitespace:
        cmp r14, [r12 - 16] 
        jz .found_whitespace

        inc rcx
        inc r14

        cmp BYTE [r13 + rcx - 1], 34
        jz .found_quote
        jmp .move_on 

        .found_quote:
            cmp r15, 0
            mov rax, 1
            cmovz r15, rax
            mov rax, 0
            cmovnz r15, rax
        
        .move_on:
        cmp r15, 1
        jz .loop_until_whitespace

        cmp BYTE [r13 + rcx], 10
        jz .found_whitespace
        cmp BYTE [r13 + rcx], 32
        jz .found_whitespace
        jmp .loop_until_whitespace

    .found_whitespace:
    add [r12 - 40], rbx ; offset whitespaces
    add [r12 - 40], rcx ; offset word
    
    mov rax, r13 ; ptr of word
    mov rdx, rcx ; len of word

    jmp .return_word
    
    .end_of_string:
        mov rax, 0
        mov rdx, 0

    .return_word:

    pop rbx
    pop r12
    pop r13
    pop r14
    pop r15
    mov rsp, rbp
    pop rbp
    ret





; input
;   rdi: path   = ptr string (null term)
; modify
;   rax, rbx, rdi, rsi, r8, r9, r10
; output
;   rax: file   = ptr string (allocated heap)
;   rdx: len    = u64
open_file:
    mov     rsi, O_RDONLY
    mov     rax, SYS_OPEN
    syscall ; rax = file descriptor (fd)
    
    mov     r8 , rax

    cmp     rax, -1
    je      error_file_not_found

    sub     rsp, 144 ; place to allocate fstat
    
    mov     rdi, r8
    mov     rsi, rsp ; buffer start
    mov     rax, SYS_FSTAT
    syscall ; stack allocated fstat struct (144 bytes)
    
    mov     rbx, [rsp + 48] ; save len
    add     rsp, 144 ; free fstat 

    ; r8 is fd
    xor     rdi, rdi
    mov     rsi, rbx
    mov     rdx, PROT_READ
    mov     r10, MAP_PRIVATE 
    xor     r9 , r9
    mov     rax, SYS_MMAP
    syscall ; rax = ptr file buffer

    mov     rdx, rsi
    ret

; malloc but scuffed
; input:
;   rdi: u64 = size map 
; modify
;   rsi, rdx, r10, r8, r9, rax    
; output:
;   rax: ptr = addr to memory
;   rdi: u64 = size of memory (unchanged input)
map_memory:
    push    rdi
    mov     rsi, rdi ; memory size
    xor     rdi, rdi ; memory address (NULL)
    mov     rdx, PROT_READ or PROT_WRITE ; operations / protections
    mov     r10, MAP_PRIVATE or MAP_ANONYMOUS ; flags => map mem not file
    xor     r8 , r8 ; mem not file, no fd needed
    xor     r9 , r9 ; mem not file, no offsete needed
    mov     rax, SYS_MMAP
    syscall ; rax = ptr mem buffer
    pop rdi
    ret 
    
; input
;   rdi: addr   = ptr buffer
;   rsi: len    = u64
; modifies
;   rax
unmap_memory:
    mov     rax, SYS_MUNMAP
    syscall
    ret


; input
;   rdi: addr    = ptr buffer
;   rsi: old len = u64
;   rdx: new len = u64
remap_memory:
    mov     r10, MREMAP_MAYMOVE
    mov     rax, SYS_MREMAP
    syscall
    ret


; move memory
; input:
;   rdi: ptr destination
;   rsi: ptr source
;   rdx: len to move 
mem_move:
    xor     rcx, rcx
    .loop_mem_move:
        mov     al, BYTE [rsi + rcx] ; src byte
        mov     BYTE [rdi + rcx], al ; dst byte
        inc     rcx
        cmp     rcx, rdx
        jnz .loop_mem_move
    ret

; compare memory
; input:
;   rdi: ptr 1
;   rsi: ptr 2
;   rdx: len
; output: 
;   rax: 1 equal, 0 unequal
mem_cmp:
    xor     rcx, rcx
    .loop_mem_cmp:
        mov     r8l, BYTE [rdi + rcx]
        cmp     r8l, BYTE [rsi + rcx]
        jnz     .mem_cmp_exit_unequal
        inc     rcx
        cmp     rcx, rdx
        jnz     .loop_mem_cmp
        jmp     .mem_cmp_exit

    .mem_cmp_exit_unequal:
        mov     rax, 0
        ret
    .mem_cmp_exit:
        mov     rax, 1
        ret


; input:
;   rdi: ptr string
;   rsi: len string
print_string:
    push    rdi
    push    rax
    push    rdx
    push    rcx
    push    rsi

    mov     rdx, rsi
    mov     rsi, rdi
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall
    
    pop     rsi
    pop     rcx
    pop     rdx
    pop     rax
    pop     rdi
    ret

; print single char
; input:
;   rdi: ptr char
; modify:
;   rdi, rsi, rdx, rax, rcx (syscall changes rcx)
; output:
;   rdi: ptr char (unchanged)
print_char:
    push    rdi
    lea     rsi, [rsp]
    mov     rdi, STDOUT
    mov     rdx, 1
    mov     rax, SYS_WRITE
    syscall
    pop     rdi
    ret

; modify:
;   rsi, rdx, rax, (rcx as well XD)
print_newline:
    push    rsi
    push    rdx
    push    rdi
    push    rax
    push    rcx
    lea     rsi, [newline]
    mov     rdx, 1
    mov     rdi, 1
    mov     rax, 1
    syscall
    pop     rcx
    pop     rax
    pop     rdi
    pop     rdx
    pop     rsi
    ret


print_a:
    push    rsi
    push    rdx
    push    rdi
    push    rax
    push    rcx
    lea     rsi, [char_a]
    mov     rdx, 1
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall
    pop     rcx
    pop     rax
    pop     rdi
    pop     rdx
    pop     rsi
    ret

print_b:
    push    rsi
    push    rdx
    push    rdi
    push    rax
    push    rcx
    lea     rsi, [char_b]
    mov     rdx, 1
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall
    pop     rcx
    pop     rax
    pop     rdi
    pop     rdx
    pop     rsi

    ret

print_c:
    push    rsi
    push    rdx
    push    rdi
    push    rax
    lea     rsi, [char_c]
    mov     rdx, 1
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall
    pop     rax
    pop     rdi
    pop     rdx
    pop     rsi
    ret

print_space:
    push    rsi
    push    rdx
    push    rdi
    push    rax
    lea     rsi, [char_space]
    mov     rdx, 1
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall
    pop     rax
    pop     rdi
    pop     rdx
    pop     rsi
    ret

; prints uint
; input:
;   rdi: value
; output:
;   rdi: value (unchanged)
print_uint:
    push    rbp
    mov     rbp, rsp

    push    rdi

    lea     rsi, [rsp] ; save "base" addr for uitds
    sub     rsp, 20 ; max digits + new line

    call    uitds
    
    mov     r8, 20
    sub     r8, rdx
    add     rsp, r8

    mov     rsi, rax
    mov     rdx, rdx ; rdx is already len
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall

    pop     rdi
    mov     rsp, rbp
    pop     rbp
    ret

; input:
;   rdi: value
;   rsi: ptr string (only alloc)
; output:
;   rax: ptr string (modified)
;   rdx: uint = len
uitds:
    push    rdi ; save value for second loop
    mov     rax, rdi ; use for div
    mov     r8 , 10 ; use as divisor
    
    xor     rcx, rcx ; be sure rcx is 0
    .loop_uitds_count:
        xor     rdx, rdx ; reset rdx for div
        div     r8 ; rax / 10 = rax, rest: rdx
        inc     rcx
        test    rax, rax
        jnz     .loop_uitds_count

    pop     rax ; pop saved value for second loop
    sub     rsi, rcx ; "allocate memory" within stack
    push    rsi ; store pointer to string start
    push    rcx ; store string len

    .loop_uitds_write:
        xor     rdx, rdx
        div     r8
        add     rdx, 48 ; rest div = digit, num + 48 => ascii num
        ; move only a byte into the stack
        ; -1 because rcx is len not index
        mov     BYTE [rsi + rcx - 1], dl 
        dec     rcx
        jnz     .loop_uitds_write
    
    pop     rdx ; take string len
    pop     rax ; take string pointer
    ret


; ERRORS
error_file_not_found:
    mov     rdi, STDOUT
    mov     rsi, err0
    mov     rdx, err0len
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall

error_too_many_end:
    mov     rdi, STDOUT
    mov     rsi, err1
    mov     rdx, err1len
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall

error_if_without_end:
    mov     rdi, STDOUT
    mov     rsi, err2
    mov     rdx, err2len
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall

error_do_without_while:
    mov     rdi, STDOUT
    mov     rsi, err3
    mov     rdx, err3len
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall

error_else_without_if:
    mov     rdi, STDOUT
    mov     rsi, err4
    mov     rdx, err4len
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall


segment readable writable
buf         rb  80


segment readable
; ERRORS
err0        db  "File not found"
err0len     =   $ - err0

err1        db  "too many end"
err1len     =   $ - err1

err2        db  "missing closing end"
err2len     =   $ - err2

err3        db  "do without while"
err3len     =   $ - err3

err4        db  "else without if"
err4len     =   $ - err4

; LANGUAGE KEYWORDS
KEY_DUP         db  "dup"
KEY_DUP_LEN     =   $ - KEY_DUP

KEY_SWAP        db  "swap"
KEY_SWAP_LEN    =   $ - KEY_SWAP

KEY_ROT         db  "rot"
KEY_ROT_LEN     =   $ - KEY_ROT

KEY_OVER        db  "over"
KEY_OVER_LEN    =   $ - KEY_OVER

KEY_DROP        db  "drop"
KEY_DROP_LEN    =   $ - KEY_DROP

KEY_2DUP        db  "2dup"
KEY_2DUP_LEN    =   $ - KEY_2DUP

KEY_2SWAP       db  "2swap"
KEY_2SWAP_LEN   =   $ - KEY_2SWAP

KEY_2DROP       db  "2drop"
KEY_2DROP_LEN   =   $ - KEY_2DROP

KEY_AND         db  "and"
KEY_AND_LEN     =   $ - KEY_AND

KEY_OR          db  "or"
KEY_OR_LEN      =   $ - KEY_OR

KEY_IF          db  "if"
KEY_IF_LEN      =   $ - KEY_IF

KEY_THEN        db  "then"
KEY_THEN_LEN    =   $ - KEY_THEN

KEY_ELSE        db  "else"
KEY_ELSE_LEN    =   $ - KEY_ELSE

KEY_END         db  "end"
KEY_END_LEN     =   $ - KEY_END

KEY_WHILE       db  "while"
KEY_WHILE_LEN   =   $ - KEY_WHILE

KEY_DO          db  "do"
KEY_DO_LEN      =   $ - KEY_DO

KEY_PROC        db  "proc"
KEY_PROC_LEN    =   $ - KEY_PROC

KEY_IN          db  "in"
KEY_IN_LEN      =   $ - KEY_IN

KEY_SYS0        db  "syscall0"
KEY_SYS0_LEN    =   $ - KEY_SYS0

KEY_SYS1        db  "syscall1"
KEY_SYS1_LEN    =   $ - KEY_SYS1

KEY_SYS2        db  "syscall2"
KEY_SYS2_LEN    =   $ - KEY_SYS2

KEY_SYS3        db  "syscall3"
KEY_SYS3_LEN    =   $ - KEY_SYS3

KEY_SYS4        db  "syscall4"
KEY_SYS4_LEN    =   $ - KEY_SYS4

KEY_SYS5        db  "syscall5"
KEY_SYS5_LEN    =   $ - KEY_SYS5

KEY_SYS6        db  "syscall6"
KEY_SYS6_LEN    =   $ - KEY_SYS6

; ASSEMBLY OUTPUT
ASM_PUSH        db  "; -- PUSH --", 10, "push " ; insert number here
ASM_PUSH_LEN    =   $ - ASM_PUSH

ASM_ADD         db  "; -- ADD --", 10, "pop rbx", 10, "pop rax", 10, "add rax, rbx", 10, "push rax", 10
ASM_ADD_LEN     =   $ - ASM_ADD

ASM_SUB         db  "; -- SUB --", 10, "pop rbx", 10, "pop rax", 10, "sub rax, rbx", 10, "push rax", 10
ASM_SUB_LEN     =   $ - ASM_SUB

ASM_MUL         db  "; -- MUL --", 10, "pop rbx", 10, "pop rax", 10, "mul rbx", 10, "push rax", 10
ASM_MUL_LEN     =   $ - ASM_MUL

ASM_DIV         db  "; -- DIV --", 10, "pop rbx", 10, "pop rax", 10, "xor rdx, rdx", 10, "div rbx", 10, "push rax", 10
ASM_DIV_LEN     =   $ - ASM_DIV

ASM_MOD         db  "; -- MOD --", 10, "pop rbx", 10, "pop rax", 10, "xor rdx, rdx", 10, "div rbx", 10, "push rdx", 10
ASM_MOD_LEN     =   $ - ASM_MOD

ASM_MODIV       db  "; -- MODIV --", 10, "pop rbx", 10, "pop rax", 10, "xor rdx, rdx", 10, "div rbx", 10, "push rdx", 10, "push rax", 10
ASM_MODIV_LEN   =   $ - ASM_MODIV


ASM_EQUAL       db  "; -- EQUAL --", 10, "pop rbx", 10, "pop rax", 10, "xor rcx, rcx", 10, "cmp rax, rbx", 10, "mov rdx, 1", 10,"cmove rcx, rdx", 10, "push rcx", 10
ASM_EQUAL_LEN   =   $ - ASM_EQUAL

ASM_GREATER     db  "; -- GREATER --", 10, "pop rbx", 10, "pop rax", 10, "xor rcx, rcx", 10, "cmp rax, rbx", 10, "mov rdx, 1", 10,"cmovg rcx, rdx", 10, "push rcx", 10
ASM_GREATER_LEN =   $ - ASM_GREATER

ASM_LESSER      db  "; -- LESSER --", 10, "pop rbx", 10, "pop rax", 10, "xor rcx, rcx", 10, "cmp rax, rbx", 10, "mov rdx, 1", 10,"cmovl rcx, rdx", 10, "push rcx", 10
ASM_LESSER_LEN  =   $ - ASM_LESSER

ASM_GEQUAL      db  "; -- GREATER EQUAL --", 10, "pop rbx", 10, "pop rax", 10, "xor rcx, rcx", 10, "cmp rax, rbx", 10, "mov rdx, 1", 10,"cmovge rcx, rdx", 10, "push rcx", 10
ASM_GEQUAL_LEN  =   $ - ASM_GEQUAL

ASM_LEQUAL       db  "; -- LESSER EQUAL --", 10, "pop rbx", 10, "pop rax", 10, "xor rcx, rcx", 10, "cmp rax, rbx", 10, "mov rdx, 1", 10,"cmovle rcx, rdx", 10, "push rcx", 10
ASM_LEQUAL_LEN  =   $ - ASM_LEQUAL

ASM_AND         db  "; -- AND --", 10, "pop rbx", 10, "pop rax", 10, "mov rcx, 1", 10, "mov rdx, 0", 10, "and rax, rbx", 10, "cmp rax, 0", 10, "cmovnz rdx, rcx", 10, "push rdx", 10
ASM_AND_LEN     =   $ - ASM_AND

ASM_OR          db  "; -- OR --", 10, "pop rbx", 10, "pop rax", 10, "mov rcx, 1", 10, "mov rdx, 0", 10, "or rax, rbx", 10, "cmp rax, 0", 10, "cmovnz, rdx, rdx", 10, "push rdx", 10
ASM_OR_LEN      =   $ - ASM_OR


ASM_DUMP        db  "; -- DUMP --", 10, "pop rdi", 10, "call dump_uint", 10
ASM_DUMP_LEN    =   $ - ASM_DUMP

ASM_DUP         db  "; -- DUP --", 10, "pop rax", 10, "push rax", 10, "push rax", 10
ASM_DUP_LEN     =   $ - ASM_DUP

ASM_SWAP        db  "; -- SWAP --", 10, "pop rax", 10, "pop rbx", 10, "push rax", 10, "push rbx", 10
ASM_SWAP_LEN    =   $ - ASM_SWAP

ASM_ROT         db  "; -- ROT --", 10, "pop rax", 10, "pop rbx", 10, "pop rcx", 10, "push rbx", 10, "push rax", 10, "push rcx", 10
ASM_ROT_LEN     =   $ - ASM_ROT

ASM_OVER        db  "; -- OVER --", 10, "pop rax", 10, "pop rbx", 10, "push rbx", 10, "push rax", 10, "push rbx", 10
ASM_OVER_LEN    =   $ - ASM_OVER

ASM_DROP        db  "; -- DROP --", 10, "pop r15", 10, "xor r15, r15", 10
ASM_DROP_LEN    =   $ - ASM_DROP

ASM_2DUP        db  "; -- 2DUP --", 10, "pop rax", 10, "pop rbx", 10, "push rbx", 10, "push rax", 10, "push rbx", 10, "push rax", 10
ASM_2DUP_LEN    =   $ - ASM_2DUP

ASM_2SWAP       db  "; -- 2SWAP --", 10, "pop rax", 10, "pop rbx", 10, "pop rcx", 10, "pop rdx", 10, "push rbx", 10, "push rax", 10, "push rdx", 10, "push rcx", 10

ASM_2SWAP_LEN   =   $ - ASM_2SWAP

ASM_2DROP       db  "; -- 2DROP --", 10, "pop rax", 10, "pop rax", 10, "xor rax, rax", 10
ASM_2DROP_LEN   =   $ - ASM_2DROP

ASM_IF          db  "; -- IF --", 10, "pop rax", 10, "cmp rax, 0", 10, "jz .Addr" ; insert jmp label
ASM_IF_LEN      =   $ - ASM_IF

ASM_ELSE        db  "; -- ELSE --", 10, "jmp .Addr"
ASM_ELSE_LEN    =   $ - ASM_ELSE

ASM_WHILE       db  "; -- WHILE --", 10, ".Addr"
ASM_WHILE_LEN   =   $ - ASM_WHILE

ASM_DO          db  "; -- DO --", 10, "pop rax", 10, "cmp rax, 0", 10, "jz .Addr"
ASM_DO_LEN      =   $ - ASM_DO

ASM_END_L       db  "; -- END --", 10
ASM_END_L_LEN   =   $ - ASM_END_L

ASM_END_ADDR    db  ".Addr"
ASM_END_ADDR_LEN=   $ - ASM_END_ADDR

ASM_END_AEND    db  ":", 10
ASM_END_AEND_LEN=   $ - ASM_END_AEND

ASM_END_JMP     db  "jmp .Addr"
ASM_END_JMP_LEN =   $ - ASM_END_JMP


; SYSCALLS (WORKS GOOD ENOUGH FOR NOW)
ASM_SYS0        db  "; -- SYSCALL0 --", 10, "pop rax", 10, "syscall", 10, "push rax", 10
ASM_SYS0_LEN    =   $ - ASM_SYS0

ASM_SYS1        db  "; -- SYSCALL1 --", 10, "pop rax", 10, "pop rdi", 10, "syscall", 10, "push rax", 10
ASM_SYS1_LEN    =   $ - ASM_SYS1

ASM_SYS2        db  "; -- SYSCALL2 --", 10, "pop rax", 10, "pop rdi", 10, "pop rsi", 10, "syscall", 10, "push rax", 10
ASM_SYS2_LEN    =   $ - ASM_SYS2

ASM_SYS3        db  "; -- SYSCALL3 --", 10, "pop rax", 10, "pop rdi", 10, "pop rsi",  10, "pop rdx", 10, "syscall", 10, "push rax", 10
ASM_SYS3_LEN    =   $ - ASM_SYS3

ASM_SYS4        db  "; -- SYSCALL4 --", 10, "pop rax", 10, "pop rdi", 10, "pop rsi", 10, "pop rdx", 10, "pop r10", 10, "syscall", 10, "push rax", 10
ASM_SYS4_LEN    =   $ - ASM_SYS4

ASM_SYS5        db  "; -- SYSCALL5 --", 10, "pop rax", 10, "pop rdi", 10, "pop rsi", 10, "pop rdx", 10, "pop r10", 10, "pop r8", 10, "syscall", 10, "push rax", 10
ASM_SYS5_LEN    =   $ - ASM_SYS5

ASM_SYS6        db  "; -- SYSCALL6 --", 10, "pop rax", 10, "pop rdi", 10, "pop rsi", 10, "pop rdx", 10, "pop r10",10, "pop r8", 10, "pop r9", 10, "syscall", 10, "push rax", 10
ASM_SYS6_LEN    =   $ - ASM_SYS6

ASM_PUSH_STR_L      db  "; -- PUSH STRING --", 10
ASM_PUSH_STR_L_LEN  =   $ - ASM_PUSH_STR_L

ASM_PUSH_STR        db  "push CONST_STRING_"
ASM_PUSH_STR_LEN    =   $ - ASM_PUSH_STR

ASM_CONST_STR       db  "CONST_STRING_"
ASM_CONST_STR_LEN   =   $ - ASM_CONST_STR

ASM_CONST_STR_L     db  "_LEN"
ASM_CONST_STR_L_LEN =   $ - ASM_CONST_STR_L

ASM_DB_WORD         db  " db "
ASM_DB_WORD_LEN     =   $ - ASM_DB_WORD

ASM_EQ_LEN_WORD     db  " = $ - "
ASM_EQ_LEN_WORD_LEN =   $ - ASM_EQ_LEN_WORD

ASM_HEADER      db "format ELF64 executable 3", 10
    db 10
    db "segment readable executable", 10
    db 10
    db "dump_uint:", 10
    db "mov     r8, -3689348814741910323", 10
    db "sub     rsp, 40", 10
    db "mov     BYTE [rsp+19], 10", 10
    db "lea     rcx, [rsp+18]", 10
    db ".L2:", 10
    db "mov     rax, rdi", 10
    db "mul     r8", 10
    db "mov     rax, rdi", 10
    db "shr     rdx, 3", 10
    db "lea     rsi, [rdx+rdx*4]", 10
    db "add     rsi, rsi", 10
    db "sub     rax, rsi", 10
    db "add     eax, 48", 10
    db "mov     BYTE [rcx], al", 10
    db "mov     rax, rdi", 10
    db "mov     rdi, rdx", 10
    db "mov     rdx, rcx", 10
    db "sub     rcx, 1", 10
    db "cmp     rax, 9", 10
    db "ja      .L2", 10
    db "lea     rax, [rsp+20]", 10
    db "mov     edi, 1", 10
    db "mov     rcx, rax", 10
    db "sub     rcx, rdx", 10
    db "sub     rdx, rax", 10
    db "lea     rsi, [rsp+20+rdx]", 10
    db "mov     rdx, rcx", 10
    db "mov     rax, 1", 10
    db "syscall", 10
    db "add     rsp, 40", 10
    db "ret", 10
    db 10
    db "entry $", 10

ASM_HEADER_LEN = $ - ASM_HEADER

ASM_ENDING db 10, "mov rdi, 0", 10
    db "mov rax, 60", 10
    db "syscall", 10

ASM_ENDING_LEN = $ - ASM_ENDING


ASM_CONST_DATA_SECTION         db  10, "; -- CONST DATA --", 10, "segment readable", 10, 10
ASM_CONST_DATA_SECTION_LEN     =   $ - ASM_CONST_DATA_SECTION

; PRINTING
newline     db 10
char_space  db 32
char_a      db 65
char_b      db 66
char_c      db 67

; HARDCODED
file0       db  "arith.ff", 0
file0len    =   8
file1       db  "hexdump.XD", 0
file1len    =   10

file2       db   "arith.gen.asm", 0
file2len    =   13

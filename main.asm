format ELF64 executable 3

include "linux.inc"

; Tokens
tkAdd       = 0
tkSub       = 1
tkMul       = 2
tkDiv       = 3
tkMod       = 4
tkDump      = 5
tkPush      = 6
tkDup       = 7
tkExit      = 255

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
    mov     rdi, 128
    call    map_memory
    
    push    rax ; ptr token mem | rbp - 48
    push    rdi ; len token mem | rbp - 56

    xor     rbx, rbx ; tokenspace offset
    .token_loop:
        mov     rdi, r12
        call    next_string
        ; rax = ptr sub string | 0 = reached end
        ; rdx = len sub string
        cmp     rax, 0
        jz      .exit_token_loop;

        mov     rdi, rax
        mov     rsi, rdx
        call    print_string
        call    print_newline
       
        mov     r13, rax ; ptr sub string
        mov     r14, rdx ; len sub string
        
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
        
        mov     rax, tkDump
        cmp     BYTE [r13], "."
        cmovz   r15, rax

        ; if opcode was set (so not -1), jump to symbol handling
        ; if opcode was not set, continue checking what it is
        cmp     r15, -1
        jnz     .finalize_symbol
        jmp     .no_symbol

        .finalize_symbol:
        mov     rdi, [rbp - 48] ; ptr of token memory
        mov     BYTE [rdi + rbx], r15b
        mov     eax, DWORD [rbp - 24]
        mov     r8d, DWORD [rbp - 32]
        mov     DWORD [rdi + rbx + 1], eax
        mov     DWORD [rdi + rbx + 5], r8d
        add     rbx, 9
        jmp     .end_word

        .no_symbol:
        ; checking for keyword
        
       
        mov     rdi, r13
        lea     rsi, [KEY_DUP]
        mov     rdx, KEY_DUP_LEN
        call    mem_cmp
        cmp     rax, 1

        mov     rax, tkDup
        cmovz   r15, rax
        jz      .finalize_keyword_simple

        cmp     r15, -1
        jnz     .finalize_keyword_simple
        jmp     .no_keyword

        
        .finalize_keyword_simple:
        mov     rdi, [rbp - 48]
        mov     BYTE [rdi + rbx], r15b
        mov     eax, DWORD [rbp - 24]
        mov     r8d, DWORD [rbp - 32]
        mov     DWORD [rdi + rbx + 1], eax
        mov     DWORD [rdi + rbx + 5], r8d
        add     rbx, 9
        jmp     .end_word   
 
        .no_keyword:
        
        ; handle number

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
            mov     BYTE [rdi + rbx], tkPush
            mov     r8d, DWORD [rbp - 24]
            mov     r9d, DWORD [rbp - 32]
            mov     DWORD [rdi + rbx + 1], r8d
            mov     DWORD [rdi + rbx + 5], r9d
            mov     QWORD [rdi + rbx + 9], rax
            add     rbx, 17 

        .end_word:
 
        jmp .token_loop

    .exit_token_loop:
    
    ;   [rbp -  8] ptr | origin file (required for close)
    ;   [rbp - 16] len | origin file (junk)

    ;   [rbp - 24] line counter (junk)
    ;   [rbp - 32] col counter  (junk)
    ;   [rbp - 40] offset       (junk)

    ;   [rbp - 48] ptr | token mem
    ;   [rbp - 56] len | token mem


    ;   rbx -> r12 | token mem effective len
    mov     r12, rbx
    ;   
    ; allocate memory
    mov     rdi, 2048
    call    map_memory
    push    rax ; [rbp - 64] = ptr | output file
    push    rdi ; [rbp - 72] = len | output file
 
    xor     rbx, rbx ; tokenspace offset
    xor     r15, r15 ; output file offset 
    
    mov     rax, [rbp - 48]
    lea     r13, [rax]  ; token file ptr
    mov     rax, [rbp - 64]
    lea     r14, [rax]  ; output file ptr

    lea     rdi, [r14 + r15]
    mov     rsi, ASM_HEADER
    mov     rdx, ASM_HEADER_LEN
    call    mem_move
    add     r15, ASM_HEADER_LEN

    .loop_bytecode_to_asm:
        cmp     BYTE [r13 + rbx], tkPush
        jz      .output_push
        
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

        cmp     BYTE [r13 + rbx], tkDump
        jz      .output_dump

        cmp     BYTE [r13 + rbx], tkDup
        jz      .output_dup
        ; TODO: handle unknown bytecode
        ; could also detect wrong offsetting
        jmp     .output_end

        .output_push:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_PUSH
            mov     rdx, ASM_PUSH_LEN
            call    mem_move
            add     r15, ASM_PUSH_LEN
        
            lea     rsi, [rsp]
            sub     rsp, 20
            add     rbx, 9 ; op (1) + len & col (8)
            mov     rdi, [r13 + rbx]
            call    uitds ; rdx = len
        
            lea     rdi, [r14 + r15]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20 ; reset stack
            add     r15, rdx
            add     rbx, 8 ; number (8)
            
            mov     BYTE [r14 + r15], 10
            add     r15, 1
            jmp     .output_end

        .output_add:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_ADD
            mov     rdx, ASM_ADD_LEN
            call    mem_move
            add     r15, ASM_ADD_LEN
            add     rbx, 9
            call    .output_end
        .output_sub:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_SUB
            mov     rdx, ASM_SUB_LEN
            call    mem_move
            add     r15, ASM_SUB_LEN
            add     rbx, 9
            call    .output_end

        .output_mul:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_MUL
            mov     rdx, ASM_MUL_LEN
            call    mem_move
            add     r15, ASM_MUL_LEN
            add     rbx, 9
            call    .output_end

        .output_div:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_DIV
            mov     rdx, ASM_DIV_LEN
            call    mem_move
            add     r15, ASM_DIV_LEN
            add     rbx, 9
            call    .output_end

        .output_mod:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_MOD
            mov     rdx, ASM_MOD_LEN
            call    mem_move
            add     r15, ASM_MOD_LEN
            add     rbx, 9
            call    .output_end

        .output_dump:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_DUMP
            mov     rdx, ASM_DUMP_LEN
            call    mem_move
            add     r15, ASM_DUMP_LEN
            add     rbx, 9
            call    .output_end
        
        .output_dup:
            lea     rdi, [r14 + r15]
            mov     rsi, ASM_DUP
            mov     rdx, ASM_DUP_LEN
            call    mem_move
            add     r15, ASM_DUP_LEN
            add     rbx, 9
            call    .output_end

        .output_end:

        cmp rbx, r12
        jnz .loop_bytecode_to_asm
    
  
    lea     rdi, [r14 + r15]
    mov     rsi, ASM_ENDING
    mov     rdx, ASM_ENDING_LEN
    call    mem_move
    add     r15, ASM_ENDING_LEN

    mov     rdi, file2
    mov     rsi, O_WRONLY or O_CREAT or O_TRUNC
    xor     rdx, rdx
    mov     rax, SYS_OPEN
    syscall

    ; write assembly
    mov     rdi, rax
    mov     rsi, [rbp - 64]
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


segment readable writable
buf         rb  80


segment readable
; LANGUAGE KEYWORDS
KEY_DUP         db  "dup"
KEY_DUP_LEN     = $ - KEY_DUP

; ASSEMBLY OUTPUT
ASM_PUSH        db  "push "
ASM_PUSH_LEN    =   $ - ASM_PUSH

ASM_ADD         db  "pop rbx", 10, "pop rax", 10, "add rax, rbx", 10, "push rax", 10
ASM_ADD_LEN     =   $ - ASM_ADD

ASM_SUB         db  "pop rbx", 10, "pop rax", 10, "sub rax, rbx", 10, "push rax", 10
ASM_SUB_LEN     =   $ - ASM_SUB

ASM_MUL         db  "pop rbx", 10, "pop rax", 10, "mul rbx", 10, "push rax", 10
ASM_MUL_LEN     =   $ - ASM_MUL

ASM_DIV         db  "pop rbx", 10, "pop rax", 10, "xor rdx, rdx", 10, "div rbx", 10, "push rax", 10
ASM_DIV_LEN     =   $ - ASM_DIV

ASM_MOD         db  "pop rbx", 10, "pop rax", 10, "xor rdx, rdx", 10, "div rbx", 10, "push rdx", 10
ASM_MOD_LEN     =   $ - ASM_MOD

ASM_DUMP        db  "pop rdi", 10, "call dump_uint", 10
ASM_DUMP_LEN    =   $ - ASM_DUMP

ASM_DUP         db  "pop rax", 10, "push rax", 10, "push rax", 10
ASM_DUP_LEN     =   $ - ASM_DUP

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

; PRINTING
newline     db 10
char_space  db 32
char_a      db 65
char_b      db 66
char_c      db 67

; ERRORS
err0        db "File not found"
err0len     =   14

; HARDCODED
file0       db  "arith.ff", 0
file0len    =   8
file1       db  "hexdump.XD", 0
file1len    =   10

file2       db   "arith.gen.asm", 0
file2len    =   13

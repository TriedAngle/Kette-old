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

    push    rax ; ptr file mem | rbp - 8
    push    rdx ; len file mem | rbp - 16
     
    ; allocate memory for token loop
    ; start out with 128 bytes
    mov     rdi, 128
    call    map_memory
    
    push    rax ; ptr token mem | rbp - 24
    push    rdi ; len token mem | rbp - 32

    ; iterate lines
    xor     rbx, rbx
    ; TODO: for some reason using -8 causes [rbp - 44]
    ; to be partially overriden
    ; maybe syscalls expect 16byte alignment???
    sub     rsp, 16 ; t8 bytes all 0 but! we use 2x 4bytes
    mov     QWORD [rbp - 40], 0 ; line counter | rbp - 40
    mov     QWORD [rbp - 48], 0 ; col counter  | rbp - 48
    
    xor     r12, r12 ; tokenspace counter
    xor     rbx, rbx ; charactar counter
    .token_loop:
        ; check if new line
        mov     rax, [rbp - 8]
        cmp     BYTE [rax + rbx], 10
        jnz     .no_newline
        ; increase line counter & reset col counter
        inc     QWORD [rbp - 40]
        mov     QWORD [rbp - 48], 0

        .no_newline:
        
        ; ignore out whitespace
        mov     rax, [rbp - 8]
        cmp     BYTE [rax + rbx], 32 ; whitespace
        jz      .white_space
        cmp     BYTE [rax + rbx], 10 ; new line
        jz      .white_space
        ; code here     
        
        ; reset opcode register
        mov     r15, -1

        ; load address of current pos in file
        mov     rax, [rbp - 8]
        lea     r13, [rax + rbx]
        
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
        mov     rdi, [rbp - 24] ; ptr of token memory
        mov     BYTE [rdi + r12], r15b
        mov     eax, DWORD [rbp - 40]
        mov     r8d, DWORD [rbp - 48]
        mov     DWORD [rdi + r12 + 1], eax
        mov     DWORD [rdi + r12 + 5], r8d
        add     r12, 9
        jmp     .end_word

        .no_symbol:
        ; checking for keyword
        
        cmp     r15, -1
        jnz     .finalize_keyword
        jmp     .no_keyword
        .finalize_keyword:
        
        .no_keyword:
        
        ; handle number
        xor     rax, rax ; number
        xor     r14, r14 ; digit counter
        xor     rdi, rdi ; ascii translation 
        mov     r8 , 10
        .parse_number_loop:
            mul     r8
            mov     dil, BYTE [r13 + r14]
            sub     dil, 48 
            add     rax, rdi
            inc     r14
            cmp     BYTE [r13 + r14], 32
            jz      .finish_number
            cmp     BYTE [r13 + r14], 10
            ; TODO: check for number only whitespace sep,
            ; error on 47<x<57
            jz      .finish_number
            jmp     .parse_number_loop
        
        .finish_number:
            mov     rdi, [rbp - 24] ; ptr of token memory
            mov     BYTE [rdi + r12], tkPush
            mov     r8d, DWORD [rbp - 40]
            mov     r9d, DWORD [rbp - 48]
            mov     DWORD [rdi + r12 + 1], r8d
            mov     DWORD [rdi + r12 + 5], r9d
            mov     QWORD [rdi + r12 + 9], rax
            
            add     r12, 17 
            ; dec and add because end of loop does inc
            ; and to skip already parsed int
            dec     r14
            add     QWORD [rbp - 48], r14
            add     rbx, r14
            ; push line
            ; push col
            ; push to tokens

        ; code end
        jmp .end_word
        .white_space:
        ; TODO: maybe handle whitespace idk
        .end_word:
        
        inc     QWORD [rbp - 48]
        inc     rbx
        cmp     rbx, [rbp - 16]
        jnz     .token_loop
   
   

    ; write byteformat to file for hexdump checking (works :) )
    mov     rdi, file1
    mov     rsi, O_WRONLY or O_CREAT
    xor     rdx, rdx
    mov     rax, SYS_OPEN
    syscall

    mov     rdi, rax
    mov     rsi, [rbp - 24]
    mov     rdx, [rbp - 32]
    mov     rax, SYS_WRITE
    syscall

    ; dealloc file
    mov     rdi, [rbp - 8]
    mov     rsi, [rbp - 16]
    call unmap_memory

    ; dealloc tokenspace
    mov     rdi, [rbp - 24]
    mov     rsi, [rbp - 32]
    call unmap_memory

    mov     rsp, rbp
    pop     rbp

    mov     rdi, 0
    mov     rax, SYS_EXIT
    syscall


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


; print single char
; input:
;   rdi: ptr char
; modify:
;   rdi, rsi, rdx, rax, rcx (syscall changes rcx)
; output:
;   rdi: ptr char (unchanged)
print_char:
    mov     rsi, rdi
    mov     rdi, STDOUT
    mov     rdx, 1
    mov     rax, SYS_WRITE
    syscall
    ret

; modify:
;   rsi, rdx, rax, (rcx as well XD)
print_newline:
    push    rdi
    lea     rsi, [newline]
    mov     rdx, 1
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall
    pop     rdi
    ret

print_a:
    push    rsi
    push    rdx
    push    rdi
    push    rax
    lea     rsi, [char_a]
    mov     rdx, 1
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall
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
    lea     rsi, [char_b]
    mov     rdx, 1
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall
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

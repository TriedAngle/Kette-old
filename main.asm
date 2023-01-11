format ELF64 executable 3

include "linux.inc"

; Tokens
tkPush      = 0
tkAdd       = 1
tkSub       = 2
tkMul       = 3
tkDiv       = 4
tkMod       = 5
tkDup       = 6
tkDump      = 7
tkExit      = 100

segment readable executable

entry $
    mov     rdi, file0
    call    open_file

    ; store mmap'd file add and len
    mov     r12, rax ; ptr file mem
    mov     r13, rdx ; len file mem

    ; print the file
    ;mov     rdi, STDOUT
    ;mov     rsi, r12
    ;mov     rdx, r13
    ;mov     rax, SYS_WRITE
    ;syscall

    push    r11
    push    r12
    ; allocate memory for token loop
    ; assume less than 6x file size mem is needed
    mov     rax, r13
    mov     rdi, 6
    mul     rdi
    mov     rdi, rax
    call map_memory

    ; store mem add and len
    mov     r14, rax
    mov     r15, rdi

    ; token loop
    xor     rcx, rcx ; file index
    xor     rbx, r15 ; token index
    .token_loop:
        lea     rdi, [r12 + rcx]
        push    rcx
        call    print_char
        pop     rcx
        
        inc     rcx
        cmp     rcx, r13
        jnz     .token_loop
    
    ; dealloc file
    mov     rdi, r12
    mov     rsi, r13
    call unmap_memory

    ; dealloc tokenspace
    mov     rdi, r14
    mov     rsi, r15
    call unmap_memory

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
    push    rdi
    mov     rsi, rdi
    mov     rdi, STDOUT
    mov     rdx, 1
    mov     rax, SYS_WRITE
    syscall
    pop     rdi
    ret

; modify:
;   rdi, rsi, rdx, rax, (rcx as well XD)
print_newline:
    lea     rsi, [newline]
    mov     rdx, 1
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall
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

; ERRORS
err0        db "File not found"
err0len     =   14

; HARDCODED
file0       db  "arith.ff", 0
file0len    =   8

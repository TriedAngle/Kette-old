format ELF64 executable 3

segment readable executable
entry $
 	mov rdi, Sample
    mov rsi, Size
    call print_string

    mov rdi, 0
    mov rax, 60
    syscall


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
    mov     rdi, 1
    mov     rax, 1
    syscall
    
    pop     rsi
    pop     rcx
    pop     rdx
    pop     rax
    pop     rdi
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
    mov     rdi, 1
    mov     rax, 1
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


segment readable writable
Sample db "Sample text of mixed alphabets:",10
       DB "Éireannach (Eireannach in western European alphabet)",10
       DB "Čapek (Capek in central European alphabet)",10
       DB "Ørsted (Oersted in Nordic alphabet)",10
       DB "Aukštaičių (Aukshtaiciu in Baltic alphabet)",10
       DB "Ὅμηρος (Homer in Greek alphabet)",10
       DB "Yumuşak ğ (Yumushak g in Turkish aplhabet)",10
       DB "Maðkur (Mathkur in Icelandic alphabet)",10
       DB "דגבא (ABGD in Hebrew alphabet)",10
       DB "Достоевский (Dostoevsky in Cyrillic alphabet)",10, 0x00, 0xF1

Size = $ - Sample
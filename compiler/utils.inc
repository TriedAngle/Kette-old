; input:
;   rdi: string
; output:
;   rax: len
strlen:
  xor rax, rax
  .loop_strlen:
    inc rax
    cmp BYTE [rdi + rax], 0
    jnz .loop_strlen
  ret

; input:
;   rdi: ptr string
print_string_nullterm:
  push rdi
  push rax
  call strlen
  mov rsi, rax
  pop rax
  pop rdi

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

; rdi: ptr string
; rsi: len string
; rdx: stack pointer
; r10: argument count
printf:
  push rbp
  mov rbp, rsp

  push rdi
  push rsi
  push rdx
  push r10
  .loop:
    movzx eax, byte [rdi]
    cmp rsi, 0
    je .done

    cmp al, '%'
    jz .format
    cmp al, '\'
    jz .special
    jmp .print_char
    .format:
    inc rdi
    movzx eax, byte [rdi]
    cmp al, 'd'
    je .print_decimal
    cmp al, 's'
    je .print_string
    cmp al, 'c'
    je .print_char

    .special:
    inc rdi
    movzx eax, byte [rdi]
    cmp al, 'n'
    je .print_newline

  .print_char:
    push rdi
    push rsi
    push rdx
    mov rsi, rdi
    mov rdx, 1
    mov rdi, STDOUT
    mov rax, SYS_WRITE
    syscall
    pop rdx
    pop rsi
    pop rdi
    jmp .next

  .print_string:
    push rdi
    push rsi
    push rdx
    mov rsi, [rdx]
    mov rdx, [rdx - 8]
    mov rdi, STDOUT
    mov rax, SYS_WRITE
    syscall
    pop rdx
    pop rsi
    pop rdi
    dec rsi
    add rdx, 16
    jmp .next

  .print_decimal:
    push rdi
    push rsi
    push rdx
    mov rdi, [rdx]
    call print_uint
    pop rdx
    pop rsi
    pop rdi
    dec rsi
    dec r10
    add rdx, 8
    jmp .next

  .next:
    dec rsi
    inc rdi
    jmp .loop

  .print_newline:
    push    10
    mov     rsi, rsp
    mov     rdx, 1
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall
    pop     rax
  
  .done:
  pop r10
  pop rdx
  pop rsi
  pop rdi

  mov rsp, rbp
  pop rbp
  ret


print_newline:
  push 10
  mov rsi, rsp
  mov rdx, 1
  mov rdi, STDOUT
  mov rax, SYS_WRITE
  syscall
  pop rax
  ret


print_char:
  push    rdi
  mov     rsi, rsp
  mov     rdx, 1
  mov     rdi, STDOUT
  mov     rax, SYS_WRITE
  syscall
  pop     rdi
  ret


print_a:
  push rsi
  push rdx
  push rdi
  push rax
  push rcx
  push 65
  mov rsi, rsp
  mov rdx, 1
  mov rdi, STDOUT
  mov rax, SYS_WRITE
  syscall
  pop rax
  pop rcx
  pop rax
  pop rdi
  pop rdx
  pop rsi
  ret


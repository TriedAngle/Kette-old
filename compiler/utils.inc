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

print_newline:
  push    rsi
  push    rdx
  push    rdi
  push    rax
  push    rcx
  push    10
  mov     rsi, rsp
  mov     rdx, 1
  mov     rdi, 1
  mov     rax, 1
  syscall
  pop     rax
  pop     rcx
  pop     rax
  pop     rdi
  pop     rdx
  pop     rsi
  ret

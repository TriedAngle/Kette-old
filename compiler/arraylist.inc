INITIAL_CAPACITY = 20

struc ArrayListS {
  .allocation dq ? 
  .capacity dq ?
  .size dq ?
  .element_size dq ?
}

virtual at 0
  ArrayListS ArrayListS
  sizeof.ArrayList = $ - ArrayListS
end virtual

ArrayList:
; output:
;   rax: ptr
.new:
  push rdi
  mov rdi, sizeof.ArrayList
  call malloc
  pop rdi

  mov [rax + ArrayListS.element_size], 8
  mov [rax + ArrayListS.capacity], INITIAL_CAPACITY
  mov [rax + ArrayListS.size], 0

  push rax
  mov rax, 8
  mov rcx, INITIAL_CAPACITY
  mul rcx
  mov rdi, rax
  
  call malloc
  mov rsi, rax
  pop rax
  
  mov [rax + ArrayListS.allocation], rsi
  ret

.destroy:
  mov rdi, [r15 + ArrayListS.allocation]
  call free
  mov rdi, r15
  call free
  ret

; input:
;   rdi: value
.push_back:
  mov rax, [r15 + ArrayListS.capacity]
  cmp [r15 + ArrayListS.size], rax
  jne ArrayList._skip_resize
  push rdi

  ; capacity -> 2 * capacity
  mov rax, [r15 + ArrayListS.capacity]
  mov rcx, 2
  mul rcx
  mov [r15 + ArrayListS.capacity], rax

  ; 2 * capacity -> 2 * sizeof(e) * capacity 
  mov rcx, [r15 + ArrayListS.element_size]
  mul rcx

  mov rdi, [r15 + ArrayListS.allocation]
  mov rsi, rax
  call realloc
  mov [r15 + ArrayListS.allocation], rax

  pop rdi
  ._skip_resize:
  
  mov rax, [r15 + ArrayListS.size]
  mov rsi, [r15 + ArrayListS.element_size]
  mul rsi
  mov rsi, rax
  mov rax, [r15 + ArrayListS.allocation]
  lea rax, [rax + rsi]
  mov [rax], rdi
  inc [r15 + ArrayListS.size]
  ret

; output:
;   rax: value
.pop_back:
  ; TODO: ERROR
  ; cmp [r15 + ArrayListS.size], 0
  dec [r15 + ArrayListS.size]
  mov rax, [r15 + ArrayListS.size]
  mov rsi, [r15 + ArrayListS.element_size]
  mul rsi
  mov rsi, rax
  mov rax, [r15 + ArrayListS.allocation]
  lea rax, [rax + rsi]
  mov rax, [rax]
  push rax

  ; capacity -> capacity / 4
  mov rax, [r15 + ArrayListS.capacity]
  xor rdx, rdx
  mov rcx, 4
  div rcx

  cmp [r15 + ArrayListS.size], rax
  jge ArrayList.skip_shrink

  mov rax, [r15 + ArrayListS.capacity]
  xor rdx, rdx
  mov rcx, 2
  div rcx
  mov rcx, [r15 + ArrayListS.element_size] 
  mul rcx
  mov rsi, rax
  mov rdi, [r15 + ArrayListS.allocation]
  call realloc
  mov [r15 + ArrayListS.allocation], rax

  .skip_shrink:
  pop rax
  ret
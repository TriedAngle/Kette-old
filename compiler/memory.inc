LINUX_PAGE_SIZE = 4096
LINUX_PAGE_SIZE2 = LINUX_PAGE_SIZE * 2
LINUX_PAGE_SIZE4 = LINUX_PAGE_SIZE * 4

HEAP_SIZE_SMALL = 4 * LINUX_PAGE_SIZE
HEAP_SIZE_MEDIUM = 16 * LINUX_PAGE_SIZE

BLOCK_COUNT_SMALL = 128
BLOCK_COUNT_MEDIUM = 128

BLOCK_SIZE_SMALL = HEAP_SIZE_SMALL / BLOCK_COUNT_SMALL
BLOCK_SIZE_MEDIUM = HEAP_SIZE_MEDIUM / BLOCK_COUNT_MEDIUM

BLOCK_STORAGE_SMALL = BLOCK_SIZE_SMALL - sizeof.MemBlock
BLOCK_STORAGE_MEDIUM = BLOCK_SIZE_MEDIUM - sizeof.MemBlock

HEAP_INIT_COUNT_SMALL = 8
HEAP_INIT_COUNT_MEDIUM = 8

struc MemHeap {
  .prev dq ?
  .next dq ?
  .size dq ?
  .start dq ?
  .block_size dq ?
  .block_storage_size dq ?
  .blocks_count dq ?
  .blocks_free dq ?
  .locked dq ?
}

struc MemBlock {
  .heap dq ?
  .free dq ?
}

virtual at 0
  MemHeap MemHeap
  sizeof.MemHeap = $ - MemHeap
end virtual

virtual at 0
  MemBlock MemBlock
  sizeof.MemBlock = $ - MemBlock
end virtual

Memory:
; input:
;   rdi: ptr mem 1
;   rsi: len mem 1
;   rdx: ptr mem 2
;   rcx: len mem 2
.cmp:
  push r12
  mov r12, false
  mov rax, true
  cmp rsi, rcx
  cmovne rax, r12
  jne Memory.cmp_early_return
  push rbx
  push r13
  push rcx
  xor rbx, rbx
  .cmp_loop:
    cmp rbx, rsi
    je Memory.cmp_loop_end
    mov r13, [rdi + rbx]
    inc rbx
    cmp r13, [rdx + rcx]
    mov rcx, rbx
    je Memory.cmp_loop
    mov rax, r12
  .cmp_loop_end:
  pop rcx
  pop r13
  pop rbx
  .cmp_early_return:
  pop r12
  ret
   


.setup:
  push rbx
 
  mov rdi, 0
  call Memory.allocate_small_heap
  mov [heap_root], rax
  mov rdi, [heap_root]

  mov rbx, HEAP_INIT_COUNT_SMALL
  .setup_small_loop:
    push rdi
    call Memory.allocate_small_heap
    pop rdi
    mov [rdi + MemHeap.next], rax
    mov [rax + MemHeap.prev], rdi
    mov rdi, rax
    dec rbx
    jne Memory.setup_small_loop

  mov rbx, HEAP_INIT_COUNT_MEDIUM
  .setup_medium_loop:
    push rdi
    call Memory.allocate_medium_heap
    pop rdi
    mov [rdi + MemHeap.next], rax
    mov [rax + MemHeap.prev], rdi
    mov rdi, rax
    dec rbx
    jne Memory.setup_medium_loop
  
  pop rbx
  ret

.deallocFull:
  push rbx
  push r12
  mov rbx, [heap_root]
  .dealloc_full_loop:
    mov r12, [rbx + MemHeap.next]
    mov rdi, rbx
    mov rsi, [rbx + MemHeap.size]
    call Linux.munmap
    mov rbx, r12
    cmp rbx, null
    jne Memory.dealloc_full_loop
  
  pop r12
  pop rbx
  ret

; output:
;   rax: ptr heap
.get_last_heap:
  push rbx
  mov rbx, [heap_root]
  cmp rbx, null
  jne Memory.get_last_heap_loop
  call Memory.allocate_small_heap
  mov rbx, rax
  .get_last_heap_loop:
    cmp [rbx + MemHeap.next], null
    je Memory.found_last_heap
    mov rbx, [rbx + MemHeap.next]
    jmp Memory.get_last_heap_loop
  .found_last_heap:
  mov rax, rbx
  pop rbx
  ret

; output
;   rax: ptr
;   rdi: (unchanged)
.allocate_small_heap:
  mov rdi, HEAP_SIZE_SMALL
  mov rsi, BLOCK_COUNT_SMALL
  mov rdx, BLOCK_SIZE_SMALL
  mov rcx, BLOCK_SIZE_SMALL
  mov r8 , BLOCK_STORAGE_SMALL
  jmp Memory.allocate_heap

; output
;   rax: ptr
;   rdi: (unchanged)
.allocate_medium_heap:
  mov rdi, HEAP_SIZE_MEDIUM
  mov rsi, BLOCK_COUNT_MEDIUM
  mov rdx, BLOCK_SIZE_MEDIUM
  mov rcx, BLOCK_SIZE_MEDIUM
  mov r8 , BLOCK_STORAGE_MEDIUM 
  jmp Memory.allocate_heap

; input:
;   rdi: size
;   rsi: block count
;   rdx: block size
;   rcx: blocks start
;   r8 : block storage size
; output
;   rax: ptr
.allocate_heap:
  push rsi
  push rdx
  push rcx
  push r8
  call Linux.mmap_mem_default
  pop r8
  pop rcx
  pop r10
  pop rsi
  mov [rax + MemHeap.prev], null
  mov [rax + MemHeap.next], null
  mov [rax + MemHeap.size], rdx
  mov [rax + MemHeap.start], rcx
  mov [rax + MemHeap.block_size], r10
  mov [rax + MemHeap.block_storage_size], r8
  mov [rax + MemHeap.blocks_count], rsi
  dec rsi
  mov [rax + MemHeap.blocks_free], rsi
  mov [rax + MemHeap.locked], false

  .setup_blocks:
  mov rdi, rcx ; start (skip first block)
  .setup_blocks_loop:
    mov [rax + rdi + MemBlock.heap], rax
    mov [rax + rdi + MemBlock.free], true 
    add rdi, r10
    dec rsi
    cmp rsi, 0
    jne Memory.setup_blocks_loop
  ret
; input:
;   rdi: size
; output:
;   rax: ptr
.find_heap_free:
  push rbx
  mov rbx, [heap_root]
  .find_heap_loop:
    cmp rbx, 0
    je Memory.heap_not_found

    cmp [rbx + MemHeap.block_storage_size], rdi
    jl Memory.find_heap_next
    cmp [rbx + MemHeap.blocks_free], 0
    je Memory.find_heap_next

    jmp Memory.heap_found

    .find_heap_next:
      mov rbx, [rbx + MemHeap.next]
      jmp Memory.find_heap_loop
    
  .heap_not_found:
  cmp rdi, BLOCK_STORAGE_SMALL
  jl Memory.heap_not_found_allocate_small_heap
  cmp rdi, BLOCK_STORAGE_MEDIUM
  jl Memory.heap_not_found_allocate_medium_heap

  ; align to page size
  mov r11, rdi

  xor rdx, rdx
  mov rax, rdi
  mov rcx, LINUX_PAGE_SIZE
  div rcx
  mov r8, rdx
  mul rcx
  mov r10, rax
  add r10, LINUX_PAGE_SIZE
  cmp r8, 0
  cmovne rax, r10
  mov rdi, rax
  ; if allocation doesn't fit heap & block metadata, add another page
  mov r10, rax
  add r10, LINUX_PAGE_SIZE
  sub rax, sizeof.MemHeap + sizeof.MemBlock
  cmp rax, r11
  cmovl rdi, r10
  
  mov rsi, 2
  mov rdx, rdi
  sub rdx, sizeof.MemHeap
  mov rcx, sizeof.MemHeap
  mov r8, rdx
  sub r8, sizeof.MemBlock
  call Memory.allocate_heap
  
  jmp Memory.allocated_new_heap
  .heap_not_found_allocate_small_heap:
  call Memory.allocate_small_heap
  jmp Memory.allocated_new_heap
  
  .heap_not_found_allocate_medium_heap:
  call Memory.allocate_medium_heap

  .allocated_new_heap:
  mov rbx, rax
  call Memory.get_last_heap
  
  mov [rax + MemHeap.next], rbx
  mov [rbx + MemHeap.prev], rax
  
  .heap_found:
  mov rdi, rbx
  pop rbx
  .find_block_free:
    mov rcx, [rdi + MemHeap.block_size]
    mov rax, rdi
    add rax, [rdi + MemHeap.start]
    .find_free_block_loop:
      cmp [rax + MemBlock.free], true
      je Memory.found_free_block
      add rax, rcx
      jmp Memory.find_free_block_loop  
  
  .found_free_block:
  dec [rdi + MemHeap.blocks_free]
  mov rcx, [rdi + MemHeap.blocks_free]
  mov [rax + MemBlock.free], false
  add rax, 16
  ret


; input:
;   rdi: size (bytes)
; output:
;   rax: ptr
malloc:
  call Memory.find_heap_free
  ret

; input:
;   rdi: ptr
free:
  mov qword [rdi - 8], true ; mark as free 
  mov rax, [rdi - 16] ; heap
  inc [rax + MemHeap.blocks_free]
  ret

; input:
;   rdi: ptr
;   rsi: size
; output:
;   rax: ptr
realloc:
  mov rax, [rdi - 16] ; heap
  cmp [rax + MemHeap.block_storage_size], rsi
  mov rax, rdi
  jge realloc.skip
  push rdi
  mov rdi, rsi
  call malloc
  pop rdi
  push rax
  call free
  pop rax
  .skip:
  ret
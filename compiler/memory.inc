LINUX_PAGE_SIZE = 4096

HEAP_SIZE_SMALL = 4 * LINUX_PAGE_SIZE
HEAP_SIZE_MEDIUM = 16 * LINUX_PAGE_SIZE

BLOCK_COUNT_SMALL = 128
BLOCK_COUNT_MEDIUM = 128

BLOCK_SIZE_SMALL = HEAP_SIZE_SMALL / BLOCK_COUNT_SMALL
BLOCK_SIZE_MEDIUM = HEAP_SIZE_MEDIUM / BLOCK_COUNT_MEDIUM

HEAP_INIT_COUNT_SMALL = 8
HEAP_INIT_COUNT_MEDIUM = 8

struc MemHeap {
  .prev dq ?
  .next dq ?
  .size dq ?
  .block_size dq ?
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

; output
;   rax: ptr
;   rdi: (unchanged)
.allocate_small_heap:
  mov rdi, HEAP_SIZE_SMALL
  call Linux.mmap_mem_default
  mov rdi, rax
  mov rsi, rdx
  mov rdx, BLOCK_COUNT_SMALL
  mov rcx, BLOCK_SIZE_SMALL
  jmp Memory.allocate_heap
  
.allocate_medium_heap:
  mov rdi, HEAP_SIZE_MEDIUM
  call Linux.mmap_mem_default
  mov rdi, rax
  mov rsi, rdx
  mov rdx, BLOCK_COUNT_MEDIUM
  mov rcx, BLOCK_SIZE_MEDIUM
  jmp Memory.allocate_heap

; input:
;   rdi: ptr
;   rsi: size
;   rdx: block count
;   rcx: block size
; output
;   rax: ptr
.allocate_heap:
  mov rax, rdi
  mov [rax + MemHeap.prev], null
  mov [rax + MemHeap.next], null
  mov [rax + MemHeap.size], rsi
  mov [rax + MemHeap.block_size], rcx
  mov [rax + MemHeap.blocks_count], rdx
  dec rdx
  mov [rax + MemHeap.blocks_free], rdx
  mov [rax + MemHeap.locked], false
  
  .setup_blocks:
  mov rdi, rcx ; start (skip first block)
  .setup_blocks_loop:
    mov r13, rdx
    mov [rax + rdi + MemBlock.heap], rax
    mov [rax + rdi + MemBlock.free], true 
    add rdi, rcx
    dec rdx
    cmp rdx, 0
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

    cmp [rbx + MemHeap.block_size], rdi
    jl Memory.find_heap_next
    cmp [rbx + MemHeap.blocks_free], 0
    je Memory.find_heap_next

    jmp Memory.heap_found

    .find_heap_next:
      mov rbx, [rbx + MemHeap.next]
      jmp Memory.find_heap_loop
    
  .heap_not_found:
  printl valStr, 666
  .heap_found:
  mov rdi, rbx
  pop rbx
  .find_block_free:
    mov rcx, [rdi + MemHeap.block_size]
    mov rax, rdi
    add rax, rcx
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

realloc:
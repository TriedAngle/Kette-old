Linux:
; input:
;   rdi: size
.mmap_mem_default:
  mov rsi, MAP_PRIVATE
  mov rdx, PROT_READ or PROT_WRITE

; input
;   rdi: size
;   rsi: flags
;   rdx: protection
.mmap_mem:
  mov r10, rsi
  or  r10, MAP_ANONYMOUS 
  mov rsi, rdi
  xor rdi, rdi
  xor r8 , r8
  xor r9 , r9

; input:
;   rdi: address [null for mem]
;   rsi: size (will allocate pages)
;   rdx: protection
;   r10: mapping [ANONYMOUS for mem]
;   r8 : file discriptor [null for mem]
;   r9 : offset (null?)
; output:
;   rax: ptr mem / file
;   rdx: allocated size
.mmap:
  push rsi
  mov rax, SYS_MMAP
  syscall
  pop r10
  push rax

  xor rdx, rdx
  mov rax, r10
  mov r8 , LINUX_PAGE_SIZE
  div r8
  mov r8 , rax
  mov r9 , rdx
  
  mov rax, LINUX_PAGE_SIZE
  mul r8
  mov rdx, rax

  mov r10, rax
  add r10, LINUX_PAGE_SIZE
  cmp r9 , 0
  cmovnz rdx, r10
  
  pop rax
  ret

; input:
;   rdi: ptr
;   rsi: len
.munmap:
  mov rax, SYS_MUNMAP
  syscall
  ret
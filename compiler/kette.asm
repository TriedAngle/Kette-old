format ELF64 executable 3
segment readable executable

include "macros.inc"
include "linux.inc"

entry $
  ; call Parser.hello
  ; call Mem.allocate
  mov rdi, 5000
  call Linux.mmap_mem_default

  mov rdi, rdx
  call print_uint
  call print_newline

  mov rdi, 0
  mov rax, SYS_EXIT
  syscall



include "utils.inc"
include "memory.inc"
include "parser.inc"
include "syscalls.inc"

segment readable
include "constants.inc"

segment readable writable
include "variables.inc"


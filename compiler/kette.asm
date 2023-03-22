format ELF64 executable 3
segment readable executable

include "macros.inc"
include "linux.inc"

entry $
  call Memory.setup

  mov rdi, 4030
  call malloc
  mov rdi, rax

  mov r12, [rdi - 16]
  mov r13, [r12 + MemHeap.blocks_free]
  printlv r13
  mov r14, [r12 + MemHeap.block_size]
  printlv r14

  call free
  call free
  mov r13, [r12 + MemHeap.blocks_count]
  printlv r13

  call Memory.deallocFull
  
  exit0


include "utils.inc"
include "memory.inc"
include "parser.inc"
include "syscalls.inc"

segment readable
testing db "Hello %s world %d !", 0
testingLen = $ - testing

testing2 db "to kitten", 0
testing2Len = $ - testing2

include "constants.inc"

segment readable writable
include "variables.inc"


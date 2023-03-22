format ELF64 executable 3
segment readable executable

include "macros.inc"
include "linux.inc"

entry $
  call Memory.setup

  mov rdi, 5
  call malloc
  mov rdi, rax

  printlv rdi
  mov rsi, 200
  call realloc
  mov rdi, rax
  printlv rdi

  call free

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


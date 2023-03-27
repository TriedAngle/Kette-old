format ELF64 executable 3
segment readable executable

include "macros.inc"
include "linux.inc"

entry $
  call Memory.setup

  with ArrayList

  mov rdi, 10
  call ArrayList.push_back
  mov rdi, 66
  call ArrayList.push_back
  mov rdi, 73
  call ArrayList.push_back
  mov rdi, 100
  call ArrayList.push_back

  mov rdi, 0
  call ArrayList.get
  printlv rax

  mov rdi, 2
  call ArrayList.get
  printlv rax

  call ArrayList.pop_back
  printlv rax
  call ArrayList.pop_back
  printlv rax
  call ArrayList.pop_back
  printlv rax
  call ArrayList.pop_back
  printlv rax
  
  endwith

  call Memory.deallocFull
  
  exit0

include "syscalls.inc"
include "memory.inc"
include "utils.inc"
include "arraylist.inc"
include "parser.inc"


segment readable
testing db "Hello %s world %d !", 0
testingLen = $ - testing

testing2 db "to kitten", 0
testing2Len = $ - testing2

include "constants.inc"

segment readable writable
include "variables.inc"


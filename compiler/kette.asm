format ELF64 executable 3
segment readable executable

include "macros.inc"
include "linux.inc"

entry $
  mov rax, [rsp]
  mov [arg_count], rax
  mov rax, [rsp + 8]
  mov [arg_ptr], rax
  call Memory.setup

  getArgCount
  printlv rax

  mov rcx, 1
  getArg rcx
  mov rdi, rax
  call print_string_nullterm

  printlv tkString
  printlv tkNumber
  printlv tkSymbol
  printlv subString

  call Memory.deallocFull
  
  exit0

include "syscalls.inc"
include "memory.inc"
include "utils.inc"
include "arraylist.inc"
include "bytecode.inc"
include "parser.inc"


segment readable
include "constants.inc"

segment readable writable
include "variables.inc"


format ELF64 executable 3
segment readable executable

include "macros.inc"
include "linux.inc"

entry $
  call Parser.hello
  ; call Mem.allocate
  ; mov r10, 2
  ; mov rdi, testing2
  ; mov rsi, testing2Len
  ; call printf

  ; pop rax
  ; pop rcx
  ; pop rax
  printfmp "kitten count %d\n", 666420
  mov rax, 2345
  printfmp "kitten count %d\n", rax

  mov rdi, 0
  mov rax, SYS_EXIT
  syscall



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


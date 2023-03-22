format ELF64 executable 3
segment readable executable

include "macros.inc"
include "linux.inc"

entry $
  call Memory.setup

  with Parser
    printlt r15
    with Parser
      printlt r15
      call Parser.hello
    endwith
    printlt r15
    call Parser.hello
  endwith

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


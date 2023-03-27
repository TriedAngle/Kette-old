format ELF64 executable 3
segment readable executable

include "macros.inc"
include "linux.inc"

entry $
  call Memory.setup

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
testing db "Hello %s world %d !", 0
testingLen = $ - testing

testing2 db "to kitten", 0
testing2Len = $ - testing2

include "constants.inc"

segment readable writable
include "variables.inc"


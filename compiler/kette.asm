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

  mov rdi, programCode
  mov rsi, programCodeLen
  mov rdx, 0
  with Lexer
    call Lexer.next_word
    printlvs rax, rdx
    call Lexer.next_word
    printlvs rax, rdx
    call Lexer.next_word
    printlvs rax, rdx
    call Lexer.next_word
    printlvs rax, rdx
    call Lexer.next_word
    printlvs rax, rdx
    call Lexer.next_word
    printlvs rax, rdx
    call Lexer.next_word
    printlvs rax, rdx
    call Lexer.next_word
    printlvs rax, rdx
    call Lexer.next_word
    printlvs rax, rdx
    call Lexer.next_word
    printlvs rax, rdx
    call Lexer.next_word
    printlvs rax, rdx
    call Lexer.next_word
    printlvs rax, rdx
  endwith

  ; mov rdi, rax
  ; call strlen
  ; lea rdx, [rsp - 8]
  ; push rdi
  ; push rax

  ; mov rdi, valStrStr
  ; mov rsi, valStrStrLen
  ; call printf
  ; pop rax
  ; pop rax


  call Memory.deallocFull
  
  exit0

include "syscalls.inc"
include "memory.inc"
include "utils.inc"
include "arraylist.inc"
include "bytecode.inc"
include "lexer.inc"
include "parser.inc"


segment readable
include "constants.inc"

segment readable writable
include "variables.inc"


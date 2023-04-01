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


  with TokenStorage
    mov r14, r15
    mov rdi, programCode
    mov rsi, programCodeLen
    mov rdx, 0
    mov rcx, r15
    with Lexer 
      call Lexer.lex
    endwith
    push rbx
    call TokenStorage.size
    mov r12, rax
    mov rbx, 0
    loop_test:
      mov rdi, rbx
      call TokenStorage.get_token
      xor rcx, rcx
      xor rdx, rdx
      mov cl, [rax + CodeToken.type]
      mov dl, [rax + CodeToken.subtype]
      printlv rcx
      printlv rdx
      inc rbx
      cmp rbx, r12
      jne loop_test
    pop rbx
  endwith

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


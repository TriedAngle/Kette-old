struc Testing {
  .owo dq ?
  .uwu dq ?
}

virtual at 0
  Testing Testing
  sizeof.Testing = $ - Testing
end virtual

Parser:

.new:

.hello:
  mov rdi, 1
  mov rsi, helloParser
  mov rdx, helloParserLen
  mov rax, 1
  syscall

  mov rdi, sizeof.Testing
  call print_uint
  call print_newline

  mov rdi, Testing.owo
  call print_uint
  call print_newline

  mov rdi, Testing.uwu
  call print_uint
  call print_newline


  add rsp, sizeof.Testing

  mov rdi, 1
  mov rsi, helloParser
  mov rdx, helloParserLen
  mov rax, 1
  syscall

  mov rdi, 1
  mov rsi, helloParser
  mov rdx, helloParserLen
  mov rax, 1
  syscall
  ret

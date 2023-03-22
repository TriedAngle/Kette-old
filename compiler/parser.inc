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
  ret

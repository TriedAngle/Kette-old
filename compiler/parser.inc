struc ParserS {
  .cursor dq ?
  .string dq ?
  .length dq ?
  .line dq ?
  .col dq ?
  .output dq ? ; ptr [TokenStorage]
}

virtual at 0
  ParserS ParserS
  sizeof.Parser = $ - ParserS
end virtual

Parser:
; input:
;   rdi: source string
;   rsi: source length
;   rdx: output
; output:
;   rax: parser
.new:
  push rdi
  push rsi
  push rdx
  mov rdi, sizeof.Parser
  call malloc
  pop rdx
  pop rsi
  pop rdi
  mov [rax + ParserS.cursor], 0
  mov [rax + ParserS.string], rdi
  mov [rax + ParserS.length], rsi
  mov [rax + ParserS.line], 1
  mov [rax + ParserS.col], 1
  mov [rax + ParserS.output], rdx
  mov r15, rax
  ret

.destroy:
  mov rdi, r15
  call free
  ret

.hello:
  mov rdi, 1
  mov rsi, helloParser
  mov rdx, helloParserLen
  mov rax, 1
  syscall
  ret

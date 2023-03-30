struc LexerS {
  .cursor dq ?
  .string dq ?
  .length dq ?
  .source_id dq ?
  .line dd ?
  .col dd ?
  .output dq ? ; ptr [TokenStorage]
}

virtual at 0
  LexerS LexerS
  sizeof.LexerS = $ - LexerS
end virtual

Lexer:
; input:
;   rdi: source string
;   rsi: source length
;   rdx: source id
;   rcx: output ptr
.new:
  push rdi
  push rsi
  push rdx
  push rcx
  mov rdi, sizeof.LexerS
  call malloc
  pop rcx
  pop rdx
  pop rsi
  pop rdi
  mov [rax + LexerS.cursor], 0
  mov [rax + LexerS.string], rdi
  mov [rax + LexerS.length], rsi
  mov [rax + LexerS.source_id], rdx
  mov [rax + LexerS.line], 1
  mov [rax + LexerS.col], 1
  mov [rax + LexerS.output], rcx
  ret

.destroy:
  mov rdi, r15
  call free
  ret

; output:
;   rax: byte (char)
.current_char:
  push rcx
  push rdx
  mov rcx, [r15 + LexerS.cursor]
  mov rdx, [r15 + LexerS.string]
  xor rax, rax
  mov al, byte [rdx + rcx]
  pop rdx
  pop rcx
  ret


.is_done?:
  push rcx
  push rdx
  mov rax, false
  mov rcx, [r15 + LexerS.cursor] 
  cmp rcx, [r15 + LexerS.length]
  mov rdx, true
  cmove rax, rdx
  pop rdx
  pop rcx
  ret

.is_at_whitespace?:
  push rcx
  push rdx
  call Lexer.current_char
  mov rcx, rax
  mov rax, false
  mov rdx, true
  cmp cl, whitespace
  cmove rax, rdx
  cmp cl, horizontalTab
  cmove rax, rdx
  pop rdx
  pop rcx
  ret

.is_at_newline?:
  push rcx
  push rdx
  call Lexer.current_char
  mov rcx, rax
  mov rax, false
  mov rdx, true
  cmp cl, newline
  cmove rax, rdx
  pop rdx
  pop rcx
  ret


.increment_cursor:
  inc [r15 + LexerS.cursor]
  ret

.increment_line:
  inc [r15 + LexerS.line]
  mov [r15 + LexerS.col], 1
  ret

.increment_col:
  inc [r15 + LexerS.col]
  ret

.skip_whitespace:
  .skipping_loop:
    call Lexer.is_done?
    ifTrue Lexer.skipping_loop_end
    call Lexer.is_at_whitespace?
    ifTrue Lexer.skipping_loop_handle_whitespace
    call Lexer.is_at_newline?
    ifTrue Lexer.skipping_loop_handle_newline

    jmp Lexer.skipping_loop_end
    .skipping_loop_handle_whitespace:
      call Lexer.increment_col
      call Lexer.increment_cursor
      jmp Lexer.skipping_loop
    .skipping_loop_handle_newline:
      call Lexer.increment_line
      call Lexer.increment_cursor
      jmp Lexer.skipping_loop
  .skipping_loop_end:
  ret

; output:
;   rax: ptr
;   rdx: len
.move_until_whitespace:
  push r12
  push r13

  mov rax, [r15 + LexerS.cursor]
  mov rdx, [r15 + LexerS.string]
  lea r12, [rdx + rax] ; ptr
  xor r13, r13 ; counter
  .collect_loop:
    call Lexer.is_done?
    ifTrue Lexer.collect_loop_end
    call Lexer.is_at_whitespace?
    ifTrue Lexer.collect_loop_end
    call Lexer.is_at_newline?
    ifTrue Lexer.collect_loop_end
    
    inc r13
    call Lexer.increment_cursor
    call Lexer.increment_col
    jmp Lexer.collect_loop

  .collect_loop_end:
  mov rax, r12
  mov rdx, r13
  pop r13 
  pop r12
  ret

; output:
;   rax: ptr
;   rdx: len
.next_word:
  call Lexer.skip_whitespace

  call Lexer.is_done?
  cmp rax, true
  mov rax, 0
  je Lexer.next_word_skip

  call Lexer.move_until_whitespace
  .next_word_skip:
  ret

.lex:
  push r12
  push r13
  .lexing:
    call Lexer.next_word
    cmp rax, 0
    je Lexer.lexing_end
    mov r12, rax
    mov r13, rdx 
    
    mov rdi, sizeof.CodeToken
    call malloc
    mov rdx, rax
    push rdx
    push r15
    mov r15, [r15 + LexerS.output]
    call TokenStorage.add_token
    pop r15
    pop rdx

    xor rax, rax
    mov eax, [r15 + LexerS.line]
    mov [rdx + CodeToken.line], eax
    mov eax, [r15 + LexerS.col]
    sub rax, r13
    mov [rdx + CodeToken.col], eax

    mov rdi, r12
    mov rsi, r13

    call Lexer.match_symbol
    ifTrue Lexer.lexing_next
    call Lexer.match_number
    ifTrue Lexer.lexing_next

    .lexing_next:
    jmp Lexer.lexing
  .lexing_end:
  pop r13
  pop r12
  ret

macro testSymbol name, tk, tks=0 {
  mov rdx, name
  mov rcx, name#.len
  call Memory.cmp
  mov rcx, rax
  xor rax, rax
  xor rdx, rdx
  cmp rcx, true
  mov rcx, tk
  cmove rax, rcx
  mov rcx, tks
  cmove rdx, rcx
  je Lexer.finalize_symbol
}

; input:
;   rdi: ptr string
;   rsi: len string
;   rdx: ptr token
; output:
;   rax: bool
.match_symbol:
  push r12
  mov r12, rdx

  testSymbol symBO    , tkSymbolControl , tvControlBO
  testSymbol symBC    , tkSymbolControl , tvControlBC
  testSymbol symCol   , tkSymbolControl , tvControlCol
  testSymbol symSim   , tkSymbolControl , tvControlSim

  testSymbol symEq    , tkSymbolBool    , tvBoolEq
  testSymbol symEqLe  , tkSymbolBool    , tvBoolEqLe
  testSymbol symEqGr  , tkSymbolBool    , tvBoolEqGre
  testSymbol symLe    , tkSymbolBool    , tvBoolLe
  testSymbol symGr    , tkSymbolBool    , tvBoolGr

  testSymbol symAdd   , tkSymbolArith   , tvArithAdd
  testSymbol symSub   , tkSymbolArith   , tvArithSub
  testSymbol symMul   , tkSymbolArith   , tvArithMul
  testSymbol symDiv   , tkSymbolArith   , tvArithDiv
  testSymbol symMod   , tkSymbolArith   , tvArithMod
  testSymbol symModDiv, tkSymbolArith   , tvArithModDiv

  mov rax, false
  mov rdx, r12
  pop r12
  ret 
  .finalize_symbol:
  mov [r12 + CodeToken.type], al
  mov [r12 + CodeToken.subtype], dl
  
  mov rax, true
  mov rdx, r12
  pop r12
  ret


; input:
;   rdi: ptr
;   rsi: len
;   rdx: ptr token
; output:
;   rax: bool
.match_number:
  ret



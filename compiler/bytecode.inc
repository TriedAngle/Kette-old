newToken tkString
newToken tkNumber
newToken tkSymbol

; iota true
; newToken subString

struc CodeToken {
  .type db ?
  .subtype db ?
  .line dd ?
  .col dd ?
  .source_id dq ? ; index in array
  .slotw dw ?
  .slotd dd ?
  .slot0 dq ?
  .slot1 dq ?
  .slot2 dq ?
}

virtual at 0
  CodeToken CodeToken
  sizeof.CodeToken = $ - CodeToken
end virtual


struc TokenStorageS {
  .tokens dq ? ; ptr ArrayList
}

virtual at 0
  TokenStorageS TokenStorageS
  sizeof.TokenStorageS = $ - TokenStorageS
end virtual


TokenStorage:
.new:
  mov rdi, sizeof.TokenStorageS
  call malloc
  push rax
  call ArrayList.new
  pop rdi
  mov [rdi + TokenStorageS.tokens], rax 
  mov rax, rdi
  ret

.destroy:
  mov rdi, [r15 + TokenStorageS.tokens]
  call free
  mov rdi, r15
  call free
  ret


; input
;   rdi: ptr [Code]
.add_token:
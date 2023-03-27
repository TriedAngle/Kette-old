newToken tkString
newToken tkNumber
newToken tkSymbol

iota true
newToken subString

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


; struc TokenStorageS {
;   .
; }

TokenStorage:

.new:

; input
;   rdi: ptr [Code]
.add_token:
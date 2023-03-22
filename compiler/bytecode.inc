struc Code {
  .type dw ?
  .subtype dw ?
  .line dw ?
  .col dw ?
  .source_id dq ? ; index in array
  .slot0 dq ?
  .slot1 dq ?
  .slot2 dq ?
  .slot3 dq ?
}

virtual at 0
  Code Code
  sizeof.Code = $ - Code
end virtual


struc TokenStorageS {
  .storage dq ? ; ptr
  .storage_size dq ? ; 
  .add_offset dq ? ; ptr
}

TokenStorage:

.new:

; input
;   rdi: ptr [Code]
.add_code:
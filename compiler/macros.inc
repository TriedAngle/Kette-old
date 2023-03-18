; struct Point {
;   x dq ?
;   y dq ?
; }
; expand
;
; struc Point {
;   .x dq ?
;   .y dq ?
; }
; virtual at 0
;   Point Point
;   sizeof.Point = $ - Point
; end virtual
; macro structt name,[field] {
;   struc name
;     forward
;       .field dq ?
;   end struc

; }

macro printfm string, ptr {
  local format, len, behind
  jmp behind
  format db string, 0
  len = $ - format
  behind:
  lea rdx, [ptr]
  mov r10, 0
  mov rdi, format
  mov rsi, len
  call printf
}

macro printfmp string, [vars] {
  local format, len, behind
  jmp behind
  format db string, 0
  len = $ - format
  behind:
  lea rdx, [rsp - 8]
  forward
    push vars
  mov r10, 0
  mov rdi, format
  mov rsi, len
  call printf
  forward
    pop rax
}
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
macro structt name,[field] {
  struc name
    forward
      .field dq ?
  end struc

}
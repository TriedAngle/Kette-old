macro exit0 {
  mov rdi, 0
  mov rax, SYS_EXIT
  syscall
}

macro printl label, [vars] {
  push rdi 
  push rsi
  push rax
  push rcx
  push rdx
  push r8
  local len 
  len = $ - label
    lea r11, [rsp - 8]
  forward
    push vars
  mov r10, 0
  mov rdx, r11
  mov rdi, label
  mov rsi, len
  call printf
  forward
    pop rax
  pop r8
  pop rdx
  pop rcx
  pop rax
  pop rsi
  pop rdi
}

macro printlv var {
  printl valStr, var
}

macro printlt var {
  printl testStr, var
}

macro with [obj] { 
  forward 
    push r15
    call obj#.new
  common macro endwith \{
  reverse 
    call obj#.destroy
    pop r15
  common \} 
}

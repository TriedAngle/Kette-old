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

macro printlvc var {
  printl valCharStr, var
}

macro printlvsn var {
  push rdi
  push rax
  mov rdi, var
  call strlen
  printl valStrStr, rdi rax
  pop rax
  pop rdi
}

macro printlvs stringPtr, length {
  printl valStrStr, stringPtr length
}

macro with [obj] { 
  forward 
    push r15
    call obj#.new
    mov r15, rax
  common macro endwith \{
  reverse 
    call obj#.destroy
    pop r15
  common \} 
}

iota_n = 0
macro iota reset {
  if reset
    iota_n = 0
  else
    iota_n = iota_n + 1
  end if
}

macro newToken token {
  token = iota_n
  iota false
}

macro getArgCount {
  mov rax, [arg_count]
}

macro getArg n {
  mov rax, [arg_ptr]
  lea rax, [rax + n * 8]
}

macro ifTrue label {
  cmp rax, true
  je label
}
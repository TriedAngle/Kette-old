# Frozen Forth
forth implementation in x64 assembly

## 
assembly =(compiler)=> forth =(interpreter) => common lisp =(compiler)=> ice
### Notes
SysV ABI

Parameters:
1. rdi
2. rsi
3. rdx
4. rcx
5. r8
6. r9
7. stack

Return:
1. rax
2. rdx

Preserve:
1. rbx
2. rsp
3. rbp
4. r12
5. r13
6. r14
7. r15

Whatever:
(Parameters and RCX)
1. rax
2. rdi
3. rsi
4. rdx
5. rcx  
6. r8
7. r9
8. r10
9. r11

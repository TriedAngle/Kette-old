# Frozen Forth
forth implementation in x64 assembly

## 
assembly =(compiler)=> forth =(interpreter) => common lisp =(compiler)=> ice
## Notes
### Token Format
<bytes>
1 = opcode (max: 256) 
4 = line
4 = char in line
<...> data
[add, sub, mul, div] = none
[dump] = none
[dup, 2dup, swap] = none
[push] = 8 # number | address (TODO later)
[if] = 8 | jump label index
[end] = 17 | end subtype | jump label index | jump label 2
[while] = 8

### SysV ABI

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
2. rsp ; unusable 
3. rbp ; unusable
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

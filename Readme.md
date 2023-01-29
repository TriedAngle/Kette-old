# Kette
Concatenative Stack-Based Programming Language

## Usage
1. compile the compiler: `fasm kette.asm`
2. compile file to asm: `./kette <file> <output-fasm>`
3. compile asm: `fasm <output-fasm> <output>`
4. run code: `./<output>`


## Features & TODO list
** everything marked with prio 0 and 1 is "required" before selfhosting
- [x] if else
- [x] loops
- [x] procs
- [x] constants (constants are special case of procs in this lang lmao)
- [x] strings | constants work already | PRIO 0
- [ ] string formatting (\n & number / string insert & unicode) | PRIO 1
- [x] comments | PRIO 0
- [ ] single error handling | PRIO 1 | multi error handling will be added in self host
- [x] command line arguments
- [ ] command line arguments code | code in place, needs accessibility | PRIO 1
- [ ] ptr | PRIO 0
- [ ] mutable globals | PRIO 1
- [ ] syntax highlighting VSC + VIM | PRIO 2
- [ ] types (int, string, ptr)
- [ ] static typechecking
- [ ] arrays
- [x] syscalls
- [ ] match (on types & values) 
- [ ] modules | PRIO 1
- [ ] simple datastructures ex. HashMap, Dynamic Array
- [ ] self hosted | PRIO 2
- [ ] some optimizations
- [ ] proc options e.g. "inline", "c"
- [ ] memory management
- [ ] c-interop
- [ ] some OOP
- [ ] Stack Effects & Pure Functions
- [ ] multithreading
- [ ] REPL
- [ ] AArch64 Mac & Windows and x64 Windows backend
- [ ] javascript backend lol
- [ ] package manager

## Compiler Design
### 1. Lexing
1. loop through input string
2. return pointer to substring with length, skipping whitespaces
3. while looping, increment line and col counter, reset col counter when newline is reached
4. strings are parsed from " to ", keeping all newlines and spaces
5. substrings are matched in order by string, keyword, number, "word" and converted to the token format

#### Notes
- Too large numbers and non closing " can be detected here
- TODO: currently numbers are expected at the end -> change that and do symbols instead

### 2. Token Format
a single token is 40 bytes long and structured the following:
1. [1b] token kind
2. [4b] file
3. [4b] line
4. [4b] column
5. [27b] data

#### Notes
- index 9 may be used for subvariance that may be detected for some tokens later
- some spaces are reused e.g. a do writes last while in it first which is then being changed to end later
- most tokens are 9 bytes and 17 bytes long but for easier iteration they are all stretched to 32 bytes

### Primitive-Cross-Referencing
- references if with else and end
- references while with do and end
- references proc with end

#### Notes
- detects missing end, if and while

### Symbol Cross-Referencing
- references global variabls
- references procedure calls

#### Notes
- detects missing symbols

### Assembly Generation
- generates the assembly for x64 linux
- TODO: add assembly for Windows (probably only syscalls, or include Win32.h?)
- TODO: Add AArch64 support


## Assembly Notes

### SysV ABI
#### Parameters:
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
3. stack | preallocated in caller stack frame and passed as pointer

#### Preserve:
- rbx
- rsp | unusable, only for stack frames 
- rbp | unusable, only for stack frames
- rip | do not touch
- r12
- r13
- r14
- r15

#### Whatever:
(Parameters and RCX)
- rax
- rdi
- rsi
- rdx
- rcx  
- r8
- r9
- r10
- r11

### Linux
#### Notes
syscalls may override:
- rcx | rip of syscall
- r11 | RFLAGS

#### Parameter Order
1. rdi
2. rsi
3. rdx
4. r10
5. r8
6. r9
7. rax | which sycall

format ELF64 executable 3

include "linux.inc"

GROW_SIZE = 2
PAGE1_BYTES = 4096
PAGE2_BYTES = 8192
PAGE4_BYTES = 16384

; Tokens
tkNoOp      = 0
tkAdd       = 1
tkSub       = 2
tkMul       = 3
tkDiv       = 4
tkMod       = 5
tkModiv     = 6

tkEqual     = 7
tkGreater   = 8
tkLesser    = 9
tkGEqual    = 10
tkLEqual    = 11
tkAnd       = 12
tkOr        = 13

tkPushInt   = 14
tkDump      = 15
tkDup       = 16
tkSwap      = 17
tkRot       = 18
tkOver      = 19
tkDrop      = 20

tk2Dup      = 21
tk2Swap     = 22
tk2Over     = 23
tk2Drop     = 24

tkIf        = 25
tkThen      = 26
tkElse      = 27
tkElif      = 28
tkWhile     = 29
tkDo        = 30
tkProc      = 31
tkIn        = 32
tkEnd       = 33

tkIdent     = 34
tkPushStr   = 35

tkSys0      = 36
tkSys1      = 37
tkSys2      = 38
tkSys3      = 39
tkSys4      = 40
tkSys5      = 41
tkSys6      = 42

tkBitAnd    = 43
tkBitOr     = 44

tkUse       = 45

tkAnOpen    = 46
tkAnClose   = 47
tkCall      = 48

tkStackPtr  = 49
tkDerefPtr  = 50

tkExit      = 255


varEndIf    = 1
varEndDo    = 2
varEndProc  = 3

varIdentIgnore  = 1
varIdentProc    = 2

varStringIgnore = 1

segment readable executable

entry $
    mov     rax, rsp 
    mov     [arg_count], rax
    add     rax, 8
    mov     [arg_ptr], rax

    mov     r12, [arg_count]
    mov     r12, [r12]
    
    cmp     r12, 1
    jz      error_no_file_given

    cmp     r12, 2
    jz      error_no_output_given

    cmp     r12, 3
    jng     .no_extras
    mov     rbx, 3
    mov     r8, 8
    .cmd_loop:
        cmp     rbx, r12
        jz      .cmd_loop_end
        mov     r13, [arg_ptr]
        mov     r13, [r13 + rbx * 8]
        mov     rdi, r13
        mov     rsi, hexcommand
        mov     rdx, hexcommand_len
        call    mem_cmp
        cmp     rax, 1
        jz      .cmd_hex

        jmp     .next_command
        .cmd_hex:
        mov     [hexdump], 1
        jmp     .next_command
        
        .next_command:
        inc     rbx 
        jmp     .cmd_loop
    .cmd_loop_end:
    .no_extras:

    push    rbp
    mov     rbp, rsp

    xor     r12, r12

    lea     r15, [rbp - 8]
    ; allocate memory for token
    mov     rdi, PAGE2_BYTES
    call    map_memory
    push    rax ; ptr token mem | r15 - 0
    push    rdi ; len token mem | r15 - 8
    push    r12 ; off token mem | r15 - 16
    ; allocate memory for strings
    mov     rdi, PAGE1_BYTES
    call    map_memory
    push    rax ; ptr string mem | r15 - 24
    push    rdi ; len string mem | r15 - 32
    push    r12 ; off string mem | r15 - 40
    ; allocate memory for procs
    mov     rdi, PAGE1_BYTES
    call    map_memory
    push    rax ; ptr proc mem | r15 - 48
    push    rdi ; len proc mem | r15 - 56
    push    r12 ; off proc mem | r15 - 64
    ; allocate memory for includes
    mov     rdi, PAGE1_BYTES
    call    map_memory
    push    rax ; ptr incl mem | r15 - 72
    push    rdi ; len incl mem | r15 - 80
    push    r12 ; off incl mem | r15 - 88
    push    r12 ; cur incl mem | r15 - 96

    mov     rdi, PAGE1_BYTES
    call    map_memory
    push    rax ; ptr var mem | r15 - 104
    push    rdi ; len var mem | r15 - 112
    push    r12 ; off var mem | r15 - 120

    mov     rax, 1
    push    rax ; counter string | r15 - 128
    push    rax ; counter proc   | r15 - 136
    push    rax ; counter var    | r15 - 144
    mov     rax, 0
    push    rax ; counter pass   | r15 - 152

    ; includes:
    ;    0 : 8b [id]
    ;    8 : 8b [ptr]
    ;   16 : 8b [len]

    mov     rdi, [arg_ptr]
    mov     rdi, [rdi + 8]
    call    strlen ; rax = len, rdi = ptr

    mov     r12, [r15 - 72]
    mov     qword [r12 +  0], 0
    mov     [r12 +  8], rdi
    mov     [r12 + 16], rax
    mov     qword [r15 - 88], 24
    mov     qword [r15 - 96], 0

    mov     r12, 0
    xor     r14, r14 ; offset of tokens per file
    ; -- PASS 0 : Tokenization --
    .tokenize_all:
        ; no more files => end
        mov     rax, [r15 - 96] ; current
        cmp     rax, [r15 - 88] ; current == max + 1 => end
        jz      .tokenize_all_end

        mov     rdi, r15
        call    tokenize_file

        mov     rbx, r14
        mov     r13, [r15]
        .check_use:
            cmp     rbx, [r15 - 16]
            jz      .check_use_end

            cmp     byte [r13 + rbx], tkUse
            jnz     .check_use_next
            cmp     byte [r13 + rbx + 48], tkPushStr
            jnz     error_missing_path_after_use ; TODO: ERROR
            
            ; include memory (offsetted)
            mov     rdi, [r15 - 72]
            mov     rcx, [r15 - 88]
            
            mov     rsi, [r13 + rbx + 48 + 24]
            lea     rsi, [rsi + 1]
            mov     rdx, [r13 + rbx + 48 + 32]
            sub     rdx, 2

            xor     r10, r10
            .check_if_included:
                cmp     r10, [r15 - 88]
                jz      .check_if_included_end
               
                push    rdi
                push    rcx
                push    rsi
                push    rdx
                mov     rsi, rsi
                mov     rdx, rdx
                mov     rdi, [rdi + r10 + 8]
                call    mem_cmp
                pop     rdx
                pop     rsi
                pop     rcx
                pop     rdi
                cmp     rax, 0
                jz      .check_if_included_next
                ; file is already included
                mov     byte [r13 + rbx + 48], tkNoOp
                jmp     .check_use_next

                .check_if_included_next:
                add     r10, 24
                jmp     .check_if_included
            .check_if_included_end:

            inc     r12
            mov     [rdi + rcx + 0], r12
            mov     [rdi + rcx + 8], rsi
            mov     [rdi + rcx + 16], rdx

            mov     rax, [r13 + rbx + 48 + 16] ; string id
            mov     rdi, [r15 - 24]
            xor     r10, r10
            .find_string:
                cmp     r10, [r15 - 40]
                jz      .find_string_end
                cmp     [rdi + r10], rax
                jnz     .find_string_next
                mov     byte [rdi + r10 + 24], varStringIgnore
                .find_string_next:
                add     r10, 32
                jmp     .find_string
            .find_string_end:

            add     qword [r15 - 88], 24
            mov     byte [r13 + rbx + 48], tkNoOp

            .check_use_next:
            add     rbx, 48
            jmp     .check_use
        .check_use_end:

        mov     r14, rbx
        add     qword [r15 - 96], 24
        jmp     .tokenize_all
    .tokenize_all_end:

    ; TODO: investigate why rdi doens't work
    .hexdump_pass_0:
    cmp     [hexdump], 0
    jz      .no_hexdump_pass_0
    call    hexdump_file
    .no_hexdump_pass_0:

    ; -- PASS 1 : Cross Referencing --
    mov     rdi, r15
    call    cross_reference_tokens

    inc     qword [r15 - 152]

    .hexdump_pass_1:
    cmp     [hexdump], 0
    jz      .no_hexdump_pass_1
    call    hexdump_file
    .no_hexdump_pass_1:


    mov     rdi, PAGE4_BYTES
    call    map_memory
    lea     r14, [rsp - 8]
    push    rax ; ptr output | r15 - 160
    push    rdi ; len output | r15 - 168
    xor     rax, rax
    push    rax ; offset output | r15 - 176


    mov     rdi, r15
    mov     rsi, r14
    call    create_assembly

    lea     rdi, [r15 - 24]
    mov     rsi, r14
    call    assembly_add_string_constants

    lea     rdi, [r15 - 104]
    mov     rsi, r14
    call    assembly_add_mutable_constants

    mov     rdi, r14
    call    assembly_add_finish

    mov     rdi, [arg_ptr]
    mov     rdi, [rdi + 16]
    mov     rsi, O_WRONLY or O_CREAT or O_TRUNC
    xor     rdx, rdx
    mov     rax, SYS_OPEN
    syscall
    
    mov     rdi, rax
    mov     rsi, [r14]
    mov     rdx, [r14 - 16]
    mov     rax, SYS_WRITE
    syscall

    ; unmap token memory
    mov     rdi, [r15 -  0]
    mov     rsi, [r15 -  8]
    call    unmap_memory

    ; unmap string memory
    mov     rdi, [r15 - 24]
    mov     rsi, [r15 - 32]
    call    unmap_memory

    ; unmap procedure memory
    mov     rdi, [r15 - 48]
    mov     rsi, [r15 - 56]
    call    unmap_memory

    ; unmap include memory
    mov     rdi, [r15 - 72]
    mov     rsi, [r15 - 80]
    call    unmap_memory

    ; unmap variable memory
    mov     rdi, [r15 - 104]
    mov     rsi, [r15 - 112]
    call    unmap_memory

    ; unmap output assembly
    mov     rdi, [r15 -  160]
    mov     rsi, [r15 -  168]
    call    unmap_memory

    mov     rdi, 0
    mov     rax, SYS_EXIT
    syscall


; input:
;   rdi: data: [
;           token: (ptr 0, len -8, offset -16),
;           string: (ptr -24, len -32, offset -40)
;           proc: (ptr -48, len -56, offset -64)
;           include: (ptr -72, len -80, offset -88, current -96)
;           variable: (ptr -104, len -112, offset -120)
;           counter: (string: -128, proc: -136, var: -144)
;           ]
tokenize_file:
    push    rbp
    mov     rbp, rsp

    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r15, rdi ; store pointer

    ; -- open file --
    mov     rdi, [r15 - 72] ; include ptr
    mov     rdx, [r15 - 96] ; include current
    lea     rdi, [rdi + rdx]
    mov     r12, [rdi + 8] ; ptr
    mov     r13, [rdi + 16] ; len

    ; - null terminated ... -
    mov     rbx, r13
    inc     rbx
    sub     rsp, rbx
    mov     rdi, rsp
    mov     rsi, r12
    mov     rdx, rbx
    call    mem_move
    mov     byte [rsp + r13], 0
    mov     rdi, rsp
    call    open_file
    push    r8
    add     rsp, rbx
    mov     r14, rsp
    push    rax ; file string | - 8
    push    rdx ; file len | - 16

    mov     rax, 1
    push    rax   ; line counter | - 24
    push    rax   ; col counter | - 32 
    mov     rax, 0
    push    rax   ; offset | - 40

    ; -- file opened -- ;
    xor     rbx, rbx
    .tokenize:
        mov     rdi, r14
        call    next_word
        cmp     rax, 0
        jz      .tokenize_end
        mov     r12, rax ; ptr
        mov     r13, rdx ; len

        mov     rcx, -1
        ; checking for symbol
        ; cmov does not support consts lol, x86-64 moment!
        ; rax is used as an intermediate register bc of that
        ; this looks a bit dirty, but avoids branching :)

        ; checking length is a smol hacc but it works for now XD
        ; if no check, identifiers that start with those symbols
        ; will be wrongfully parsed as that symbol
        cmp     r13, 1
        jnz     .check_symbol_len2

        mov     rax, tkAdd
        cmp     BYTE [r12], "+"
        cmovz   rcx, rax

        mov     rax, tkSub
        cmp     BYTE [r12], "-"
        cmovz   rcx, rax
        
        mov     rax, tkMul
        cmp     BYTE [r12], "*"
        cmovz   rcx, rax
        
        mov     rax, tkDiv
        cmp     BYTE [r12], "/"
        cmovz   rcx, rax

        mov     rax, tkMod
        cmp     BYTE [r12], "%"
        cmovz   rcx, rax
        
        mov     rax, tkDump
        cmp     BYTE [r12], "."
        cmovz   rcx, rax

        mov     rax, tkEqual
        cmp     BYTE [r12], "="
        cmovz   rcx, rax

        mov     rax, tkGreater
        cmp     BYTE [r12], ">"
        cmovz   rcx, rax

        mov     rax, tkLesser
        cmp     BYTE [r12], "<"
        cmovz   rcx, rax
       
        mov     rax, tkBitAnd
        cmp     BYTE [r12], "&"
        cmovz   rcx, rax

        mov     rax, tkBitOr
        cmp     BYTE [r12], "|"
        cmovz   rcx, rax

        mov     rax, tkProc
        cmp     BYTE [r12], ":"
        cmovz   rcx, rax
        jz      .finalize_keyword_simple

        mov     rax, tkEnd
        cmp     BYTE [r12], ";"
        cmovz   rcx, rax
        jz      .finalize_keyword_simple

        mov     rax, tkAnOpen
        cmp     BYTE [r12], "["
        cmovz   rcx, rax
        jz      .finalize_keyword_simple

        mov     rax, tkAnClose
        cmp     BYTE [r12], "]"
        cmovz   rcx, rax
        jz      .finalize_keyword_simple

        .check_symbol_len2:
        cmp     r14, 2
        jnz     .not_symbol_len3

        mov     rax, tkGEqual
        cmp     WORD [r12], ">="
        cmovz   rcx, rax

        mov     rax, tkLEqual
        cmp     WORD [r12], "<="
        cmovz   rcx, rax

        mov     rax, tkModiv
        cmp     WORD [r12], "/%"
        cmovz   rcx, rax

        .not_symbol_len3:
        ; skip comments
        cmp     WORD [r12], "//"
        jz      .tokenize_next_skip
        mov     ax, WORD [KEY_CMMT_START]
        cmp     WORD [r12], ax
        jz      .tokenize_next_skip

        cmp     BYTE [r12], 34  ; strings are already "checked" in word generation
        jz      .finalize_string

        ; if opcode was set (so not -1), jump to symbol handling
        ; if opcode was not set, continue checking what it is
        cmp     rcx, -1
        jnz     .finalize_symbol
        jmp     .no_symbol
        
        .finalize_string:
            mov     rdi, [r15]
            mov     rsi, [r15 - 16]
            lea     rdi, [rdi + rsi]
            mov     BYTE [rdi + rbx], tkPushStr
            mov     eax, DWORD [r14 - 24]
            mov     r8d, DWORD [r14 - 32]
            sub     r8d, r13d
            mov     r9d, DWORD [r15 - 96] ; file id
            mov     DWORD [rdi + rbx + 1], eax
            mov     DWORD [rdi + rbx + 5], r8d
            mov     DWORD [rdi + rbx + 9], r9d

            mov     rcx, [r15 - 24] ; ptr string mem
            mov     rdx, [r15 - 40] ; string mem offset
            mov     r10, [r15 - 128] ; string counter
            
            ; some data duplication but makes life easier
            mov     QWORD [rdi + rbx + 16], r10 ; id string
            mov     QWORD [rdi + rbx + 24], r12 ; ptr string
            mov     QWORD [rdi + rbx + 32], r13 ; len string

            mov     QWORD [rcx + rdx], r10 ; id string
            mov     QWORD [rcx + rdx + 8], r12 ; ptr string
            mov     QWORD [rcx + rdx + 16], r13 ; len string

            add     QWORD [r15 - 40], 32
            inc     QWORD [r15 - 128]

            jmp     .tokenize_next


        .finalize_symbol:
            mov     rdi, [r15]
            mov     rsi, [r15 - 16]
            lea     rdi, [rdi + rsi]
            mov     BYTE [rdi + rbx], cl
            mov     eax, DWORD [r14 - 24]
            mov     r8d, DWORD [r14 - 32]
            sub     r8d, r13d
            mov     r9d, DWORD [r15 - 96] ; file id
            mov     DWORD [rdi + rbx + 1], eax
            mov     DWORD [rdi + rbx + 5], r8d
            mov     DWORD [rdi + rbx + 9], r9d
            jmp     .tokenize_next

        .no_symbol:
        ; checking for keyword
        
       
        mov     rdi, r12
        lea     rsi, [KEY_DUP]
        mov     rdx, KEY_DUP_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkDup
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_SWAP]
        mov     rdx, KEY_SWAP_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkSwap
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_ROT]
        mov     rdx, KEY_ROT_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkRot
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_OVER]
        mov     rdx, KEY_OVER_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkOver
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_DROP]
        mov     rdx, KEY_DROP_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkDrop
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_2DUP]
        mov     rdx, KEY_2DUP_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tk2Dup
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_2SWAP]
        mov     rdx, KEY_2SWAP_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tk2Swap
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_2DROP]
        mov     rdx, KEY_2DROP_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tk2Drop
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_AND]
        mov     rdx, KEY_AND_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkAnd
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_OR]
        mov     rdx, KEY_OR_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkOr
        jz      .finalize_keyword_simple
        
        mov     rdi, r12
        lea     rsi, [KEY_IF]
        mov     rdx, KEY_IF_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkIf
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_THEN]
        mov     rdx, KEY_THEN_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkThen
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_ELSE]
        mov     rdx, KEY_ELSE_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkElse
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_ELIF]
        mov     rdx, KEY_ELIF_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkElif
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_WHILE]
        mov     rdx, KEY_WHILE_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkWhile
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_DO]
        mov     rdx, KEY_DO_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkDo
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_PROC]
        mov     rdx, KEY_PROC_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkProc
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_IN]
        mov     rdx, KEY_IN_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkIn
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_END]
        mov     rdx, KEY_END_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkEnd
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_USE]
        mov     rdx, KEY_USE_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkUse
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_CALL]
        mov     rdx, KEY_CALL_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkCall
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_STACKPTR]
        mov     rdx, KEY_STACKPTR_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkStackPtr
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_DEREFPTR]
        mov     rdx, KEY_DEREFPTR_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkDerefPtr
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_SYS0]
        mov     rdx, KEY_SYS0_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkSys0
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_SYS1]
        mov     rdx, KEY_SYS1_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkSys1
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_SYS2]
        mov     rdx, KEY_SYS2_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkSys2
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_SYS3]
        mov     rdx, KEY_SYS3_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkSys3
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_SYS4]
        mov     rdx, KEY_SYS4_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkSys4
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_SYS5]
        mov     rdx, KEY_SYS5_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkSys5
        jz      .finalize_keyword_simple

        mov     rdi, r12
        lea     rsi, [KEY_SYS6]
        mov     rdx, KEY_SYS6_LEN
        call    mem_cmp
        cmp     rax, 1
        mov     rcx, tkSys6
        jz      .finalize_keyword_simple
        
        jmp     .no_keyword
        .finalize_keyword_simple:
            mov     rdi, [r15]
            mov     rsi, [r15 - 16]
            lea     rdi, [rdi + rsi]
            mov     BYTE [rdi + rbx], cl
            mov     eax, DWORD [r14 - 24]
            mov     r8d, DWORD [r14 - 32]
            sub     r8d, r13d
            mov     r9d, DWORD [r15 - 96]
            mov     DWORD [rdi + rbx + 1], eax
            mov     DWORD [rdi + rbx + 5], r8d
            mov     DWORD [rdi + rbx + 9], r9d

            jmp     .tokenize_next

        .no_keyword:

        ; check if number
        xor     rcx, rcx
        xor     rax, rax
        .check_if_number_loop:
            cmp     BYTE [r12 + rcx], "0"
            jl      .parse_not_number

            cmp     BYTE [r12 + rcx], "_"
            jz      .check_if_number_loop_next

            cmp     BYTE [r12 + rcx], "9"
            jg      .parse_not_number

            .check_if_number_loop_next:
            inc     rcx
            cmp     rcx, r13
            jz      .parse_number
            jmp     .check_if_number_loop

        .parse_not_number:
            mov     rdi, [r15]
            mov     rsi, [r15 - 16]
            lea     rdi, [rdi + rsi]
            mov     BYTE [rdi + rbx], tkIdent
            mov     eax, DWORD [r14 - 24]
            mov     r8d, DWORD [r14 - 32]
            sub     r8d, r13d
            mov     r9d, DWORD [r15 - 96] ; file id
            mov     DWORD [rdi + rbx + 1], eax
            mov     DWORD [rdi + rbx + 5], r8d
            mov     DWORD [rdi + rbx + 9], r9d
            mov     BYTE  [rdi + rbx + 13], 0
            mov     QWORD [rdi + rbx + 16], r12 ; ptr start
            mov     QWORD [rdi + rbx + 24], r13 ; length
            
            jmp     .tokenize_next

        .parse_number:
        xor     rax, rax ; number
        xor     rcx, rcx ; digit counter
        xor     rdi, rdi ; ascii translation 
        mov     r8 , 10
        .parse_number_loop:
            mul     r8
            mov     dil, BYTE [r12 + rcx]
            sub     dil, 48 
            add     rax, rdi
            inc     rcx
            cmp     rcx, r13
            ; TODO: check for number only whitespace sep,
            ; error on 47<x<57
            jz      .finish_number
            jmp     .parse_number_loop
        
        .finish_number:
            mov     rdi, [r15]
            mov     rsi, [r15 - 16]
            lea     rdi, [rdi + rsi]
            mov     BYTE [rdi + rbx], tkPushInt
            mov     r10d, DWORD [r14 - 24]
            mov     r8d, DWORD [r14 - 32]
            sub     r8d, r13d
            mov     r9d, DWORD [r15 - 96]
            mov     DWORD [rdi + rbx + 1], r10d
            mov     DWORD [rdi + rbx + 5], r8d
            mov     DWORD [rdi + rbx + 9], r9d
            mov     QWORD [rdi + rbx + 16], rax
            jmp     .tokenize_next
        
        .tokenize_next_skip:
        
        sub     rbx, 48
        .tokenize_next:

        ; - BUFFER TOKEN GROW -
        mov     rax, [r15 - 8] ; current max
        mov     rcx, GROW_SIZE ; divisor
        xor     rdx, rdx ; rest
        div     rcx ; rax => 50% of current
        cmp     rbx, rax 
        jg      .grow_token_buffer
        jmp     .not_grow_token_buffer
        .grow_token_buffer:
        mov     rdi, [r15 - 0]
        mov     rsi, [r15 - 8]
        mov     rax, rsi
        mov     rcx, GROW_SIZE
        mul     rcx
        mov     rdx, rax
        call    remap_memory
        mov     [r15 - 0], rax
        mov     [r15 - 8], rdx
        .not_grow_token_buffer:

        ; - BUFFER STRING GROW -
        mov     rax, [r15 - 32] ; current max
        mov     rcx, GROW_SIZE ; divisor
        xor     rdx, rdx ; rest
        div     rcx ; rax => 50% of current
        cmp     [r15 - 40], rax 
        jg      .grow_string_buffer
        jmp     .not_grow_string_buffer
        .grow_string_buffer:
        mov     rdi, [r15 - 24]
        mov     rsi, [r15 - 32]
        mov     rax, rsi
        mov     rcx, GROW_SIZE
        mul     rcx
        mov     rdx, rax
        call    remap_memory
        mov     [r15 - 24], rax
        mov     [r15 - 32], rdx
        .not_grow_string_buffer:

        add     rbx, 48
        jmp     .tokenize
    .tokenize_end:
    add     [r15 - 16], rbx

    ; -- pop & unmap file & close file --
    pop     rax
    pop     rax
    pop     rax
    pop     rdi
    pop     rsi
    call    unmap_memory
    pop     rdi
    mov     rax, SYS_CLOSE
    syscall

    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx

    mov     rsp, rbp
    pop     rbp
    ret



; input:
;   rdi: "base pointer"
;       ptr string     | - 8
;       len string     | - 16
;       line counter   | - 24
;       col counter    | - 32
;       sub index      | - 40
; output:
;   rax: ptr sub-string | ptr == null => over
;   rdx: len sub-string
next_word:
    push    rbp
    mov     rbp, rsp
    
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r15, rdi
    mov     r13, [r15 - 8]
    mov     rax, [r15 - 40]
    lea     r13, [r13 + rax]
    xor     rbx, rbx
    .skip_whitespaces:
        cmp     rbx, QWORD [r15 - 16]
        jz      .skip_whitespaces_exit
        cmp     BYTE [r13 + rbx], 0
        jz      .skip_whitespaces_exit
        cmp     BYTE [r13 + rbx], 32
        jz      .skip_whitespaces_whitespace
        cmp     BYTE [r13 + rbx], 10
        jz      .skip_whitespaces_newline

        jmp     .skip_whitespaces_end
        .skip_whitespaces_whitespace:
            inc     QWORD [r15 - 32]
            jmp     .skip_whitepsaces_next
        
        .skip_whitespaces_newline:
            inc     QWORD [r15 - 24]
            mov     QWORD [r15 - 32], 1
            jmp     .skip_whitepsaces_next

        .skip_whitepsaces_next:
        inc     rbx
        jmp     .skip_whitespaces
    .skip_whitespaces_end:
    mov     r12, rbx ; skipped whitespaces
    lea     r13, [r13 + rbx]
    xor     rbx, rbx
    .find_whitespace:
        cmp     rbx, QWORD [r15 - 16]
        jz      .find_whitespace_end
        cmp     BYTE [r13 + rbx], 10
        jz      .find_whitespace_end
        cmp     BYTE [r13 + rbx], 32
        jz      .find_whitespace_end

        cmp     BYTE [r13 + rbx], 34
        jz      .handle_string

        cmp     WORD [r13 + rbx], "//"
        jz      .handle_comment

        mov     ax, WORD [KEY_CMMT_START]
        cmp     WORD [r13 + rbx], ax
        jz      .handle_block_comment

        jmp     .find_whitespace_next
        .handle_comment:
            add     rbx, 2
            .move_until_comment_end:
                cmp     rbx, QWORD [r15 - 16]
                jz      .find_whitespace_end
                cmp     BYTE [r13 + rbx], 10
                jz      .found_comment
                jmp     .move_until_comment_end_next
                .found_comment:
                    jmp     .find_whitespace_end
                .move_until_comment_end_next:
                inc     rbx
                jmp     .move_until_comment_end

        .handle_block_comment:
            add     rbx, 2
            .move_until_block_comment_end:
                cmp     rbx, QWORD [r15 - 16]
                jz      .find_whitespace_end
                cmp     BYTE [r13 + rbx], 10
                jz      .block_comment_handle_newline
                cmp     BYTE [r13 + rbx], 32
                jz      .block_comment_handle_whitespace
                mov     ax, WORD [KEY_CMMT_END]
                cmp     WORD [r13 + rbx], ax
                jz      .found_block_comment
                jmp     .move_until_block_comment_end_next
                .block_comment_handle_newline:
                    inc     QWORD [r15 - 24]
                    mov     QWORD [r15 - 32], 1
                    jmp     .move_until_block_comment_end_next
                .block_comment_handle_whitespace:
                    inc     QWORD [r15 - 32]
                    jmp     .move_until_block_comment_end_next
                .found_block_comment:
                    add     rbx, 2
                    jmp     .find_whitespace_end
                .move_until_block_comment_end_next:
                inc     rbx
                jmp     .move_until_block_comment_end
        
        .handle_string:
            inc     rbx
            .move_until_string_end:
                cmp     rbx, QWORD [r15 - 16] ; TODO: ERROR
                jz      .find_whitespace_end
                cmp     BYTE [r13 + rbx], 10 ; TODO: ERROR
                cmp     BYTE [r13 + rbx], 34
                jz      .found_string
                jmp     .move_until_string_end_next
                .found_string:
                    inc     rbx
                    jmp     .find_whitespace_end
                .move_until_string_end_next:
                inc     rbx
                jmp     .move_until_string_end
        
        .find_whitespace_next:
        inc     rbx
        jmp     .find_whitespace

    .find_whitespace_end:
    add     r12, rbx
    add     QWORD [r15 - 32], rbx
    add     [r15 - 40], r12

    mov     rax, r13
    mov     rdx, rbx

    jmp     .skip_whitespaces_no_exit
    .skip_whitespaces_exit:
        mov     rax, 0
    .skip_whitespaces_no_exit:

    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx

    mov     rsp, rbp
    pop     rbp
    ret



; input:
;   rdi: data: [
;           token: (ptr 0, len -8, offset -16),
;           string: (ptr -24, len -32, offset -40)
;           proc: (ptr -48, len -56, offset -64)
;           include: (ptr -72, len -80, offset -88, current -96)
;           variable: (ptr -104, len -112, offset -120)
;           counter: (string: -128, proc: -136, var: -144)
;           ]
cross_reference_tokens:
    push    rbp
    mov     rbp, rsp

    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r15, rdi
    mov     r12, [r15]
    lea     r12, [r12]
    xor     r13, r13 ; addr counter
    xor     r14, r14 ; block counter
    xor     rbx, rbx
    .cross_reference:
        cmp     rbx, [r15 - 16]
        jz      .cross_refrence_end

        cmp     byte [r12 + rbx], tkIf
        jz      .cross_reference_if
        cmp     byte [r12 + rbx], tkThen
        jz      .cross_reference_then
        cmp     byte [r12 + rbx], tkElse
        jz      .cross_reference_else
        cmp     byte [r12 + rbx], tkElif
        jz      .cross_reference_elif
        cmp     byte [r12 + rbx], tkWhile
        jz      .cross_reference_while
        cmp     byte [r12 + rbx], tkDo
        jz      .cross_reference_do
        cmp     byte [r12 + rbx], tkProc
        jz      .cross_reference_proc
        cmp     byte [r12 + rbx], tkIn
        jz      .cross_reference_in
        cmp     byte [r12 + rbx], tkEnd
        jz      .cross_reference_end
        cmp     byte [r12 + rbx], tkAnOpen
        jz      .cross_reference_anonymous_open
        cmp     byte [r12 + rbx], tkAnClose
        jz      .cross_reference_anonymous_close

        jmp     .cross_reference_next

        .cross_reference_if:
            push    rbx
            inc     r14
            jmp     .cross_reference_next

        .cross_reference_then:
            cmp     r14, 0
            jz      error_then_without_if ; TODO: ERROR
            pop     rax
            mov     r8, 0
            cmp     byte [r12 + rax], tkIf
            mov     rcx, 1
            cmovnz  rcx, r8
            cmp     byte [r12 + rax], tkElif
            mov     rdx, 1
            cmovnz  rdx, r8
            cmp     rcx, rdx
            jz      error_then_without_if ; TODO: ERROR
            mov     [r12 + rbx + 32], rax
            push    rbx
            jmp     .cross_reference_next
        
        .cross_reference_elif:
            cmp     r14, 0
            jz      error_else_without_if ; TODO: ERROR
            pop     rax
            cmp     byte [r12 + rax], tkThen
            jnz     error_else_without_if ; TODO: ERROR

            mov     r10, [r12 + rax + 32] ; if / elif
            mov     [r12 + r10 + 24], r13
            mov     [r12 + rbx + 16], r13
            mov     [r12 + rbx + 24], r13 ; else -> end
            inc     r13
            mov     [r12 + rax + 24], r13 ; then -> else
            mov     [r12 + rbx + 32], r13 ; else -> end
            inc     r13
            push    rbx
            jmp     .cross_reference_next

        .cross_reference_else:
            cmp     r14, 0
            jz      error_else_without_if ; TODO: ERROR
            pop     rax
            cmp     byte [r12 + rax], tkThen
            jnz     error_else_without_if ; TODO: ERROR

            mov     r10, [r12 + rax + 32] ; if / elif
            mov     [r12 + r10 + 24], r13
            mov     [r12 + rbx + 16], r13
            mov     [r12 + rbx + 24], r13 ; else -> end
            inc     r13
            mov     [r12 + rax + 24], r13 ; then -> else
            mov     [r12 + rbx + 32], r13 ; else -> end
            inc     r13
            push    rbx
            jmp     .cross_reference_next

        .cross_reference_while:
            push    rbx
            inc     r14
            jmp     .cross_reference_next

        .cross_reference_do:
            cmp     r14, 0
            jz      error_do_without_while ; TODO: ERROR
            pop     rax
            mov     [r12 + rbx + 16], rax
            push    rbx
            jmp     .cross_reference_next

        ; TODO: retire in for ( )
        .cross_reference_proc:
            cmp     byte [r12 + rbx + 48], tkIdent
            jnz     error_no_ident_after_proc ; TODO: ERROR
            push    rbx
            inc     r14
            mov     byte [r12 + rbx + 48 + 13], varIdentIgnore
            
            jmp     .cross_reference_next

        .cross_reference_in:
            cmp     r14, 0
            jz      error_in_without_proc ; TODO: ERROR
            pop     rax
            cmp     byte [r12 + rax], tkProc
            jnz      error_in_without_proc ; TODO: ERROR (improve)
            mov     [r12 + rbx + 16], rax
            push    rbx
            
            jmp     .cross_reference_next

        .cross_reference_end:
            cmp     r14, 0
            jz      error_too_many_end ; TODO: ERROR
            
            pop     rax
            dec     r14

            cmp     byte [r12 + rax], tkThen
            jz      .cross_reference_end_then
            cmp     byte [r12 + rax], tkDo
            jz      .cross_reference_end_do
            cmp     byte [r12 + rax], tkElse
            jz      .cross_reference_end_else
            cmp     byte [r12 + rax], tkIn
            jz      .cross_reference_end_proc
            
            jmp     error_illegal ; TODO: ERROR
        
            .cross_reference_end_then:
                ; handle if
                mov     qword [r12 + rax + 16], r13 
                mov     byte  [r12 + rbx + 13], varEndIf ;
                mov     qword [r12 + rbx + 16], r13
                inc     r13
                jmp     .cross_reference_next
            
            .cross_reference_end_proc:
                mov     r9, [r12 + rax + 16]  ; proc entry
                      ; rbx                   ; end entry
                push    r13
                
                mov     r13, [r15 - 136]
                mov     qword [r12 + r9  + 16], r13
                mov     byte  [r12 + rbx + 13], varEndProc
                mov     qword [r12 + rbx + 16], r13 ; end addr
                
                lea     r10, [r12 + r9 + 48] ; identifier
            
                mov     r11, [r15 - 48] ; proc mem
                mov     r8, [r15 - 64] ; proc offset

                mov     [r11 + r8 +  0], r13
                mov     rax, [r10 + 16]
                mov     [r11 + r8 +  8], rax
                mov     rax, [r10 + 24]
                mov     [r11 + r8 + 16], rax

                add     qword [r15 - 64], 32
                inc     qword [r15 - 136]
                pop     r13
                jmp     .cross_reference_next

            .cross_reference_end_do:
                ; rax = do
                ; rdi = while
                mov     rdi, [r12 + rax + 16]
                mov     [r12 + rdi + 16], r13 ; while label
                mov     byte [r12 + rbx + 13], varEndDo
                mov     [r12 + rbx + 16], r13 ; jmp while label
                inc     r13
                mov     [r12 + rax + 16], r13 ; jmp end label
                mov     [r12 + rbx + 24], r13 ; end label
                inc     r13
                jmp     .cross_reference_next

            .cross_reference_end_else:
                mov     [r12 + rax + 24], r13
                mov     byte [r12 + rbx + 13], varEndIf ; should be able to reuse this
                mov     [r12 + rbx + 16], r13
                inc     r13
                jmp     .cross_reference_next

        .cross_reference_anonymous_open:
            push    rbx
            inc     r14
            jmp     .cross_reference_next
        
        .cross_reference_anonymous_close:
            cmp     r14, 0
            jz      error_missing_anonymous_close ; TODO: ERROR
            pop     rax
            cmp     byte [r12 + rax], tkAnOpen
            jnz     error_missing_anonymous_close ; TODO: ERROR
            
            push    r13
            mov     r13, [r15 - 136]
            mov     [r12 + rax + 16], rbx ; [ -> ]
            mov     [r12 + rbx + 16], rax ; ] -> [
            mov     [r12 + rax + 24], r13 ; push / jmp label
            mov     [r12 + rbx + 24], r13 ; push / jmp label
            inc     qword [r15 - 136]
            pop     r13
            dec     r14
            jmp     .cross_reference_next
        
        .cross_reference_next:

        ; - BUFFER PROC GROW -
        mov     rax, [r15 - 56] ; current max
        mov     rcx, GROW_SIZE ; divisor
        xor     rdx, rdx ; rest
        div     rcx ; rax => 50% of current
        cmp     [r15 - 64], rax 
        jg      .grow_proc_buffer
        jmp     .not_grow_proc_buffer
        .grow_proc_buffer:
        mov     rdi, [r15 - 48]
        mov     rsi, [r15 - 56]
        mov     rax, rsi
        mov     rcx, GROW_SIZE
        mul     rcx
        mov     rdx, rax
        call    remap_memory
        mov     [r15 - 48], rax
        mov     [r15 - 56], rdx
        .not_grow_proc_buffer:

        add     rbx, 48
        jmp     .cross_reference

    .cross_refrence_end:
    cmp     r14, 0
    jg     error_if_without_end ; TODO: ERR


    mov     r12, [r15]
    lea     r12, [r12]
    xor     rbx, rbx
    .cross_reference_calls:
        cmp     rbx, [r15 - 16]
        jz     .cross_reference_calls_end

        cmp     BYTE [r12 + rbx], tkIdent
        jz      .cross_reference_calls_ident
        jmp     .cross_reference_calls_next

        .cross_reference_calls_ident:
            cmp     BYTE [r12 + rbx + 13], 0
            jnz     .cross_reference_calls_next

            mov     r10, [r15 - 48]
            lea     r10, [r10]
            xor     r13, r13
            .find_call_id:
                cmp     r13, [r15 - 64]
                jz      .find_call_id_end
                
                mov     rdx, [r10 + r13 + 16]
                mov     rcx, [r12 + rbx + 24]
                cmp     rdx, rcx
                jnz     .find_call_id_next ; unequal length

                mov     rdi, [r10 + r13 +  8]
                mov     rsi, [r12 + rbx + 16]
                mov     rdx, [r10 + r13 + 16]
                call    mem_cmp
                cmp     rax, 0
                jz      .find_call_id_next

                mov     byte [r12 + rbx + 13], varIdentProc
                mov     rax, qword [r10 + r13]
                mov     qword [r12 + rbx + 16], rax ; override bc why not
                jmp     .find_call_id_end

                .find_call_id_next:
                add     r13, 32
                jmp     .find_call_id

            .find_call_id_end:

        .cross_reference_calls_next:
        add     rbx, 48
        jmp     .cross_reference_calls

    .cross_reference_calls_end:

    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx

    mov     rsp, rbp
    pop     rbp
    ret


; input:
;   rdi: tokens
;   rsi: output
create_assembly:
    push    rbp
    mov     rbp, rsp

    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r15, rdi
    mov     r14, rsi

    xor     rbx, rbx
    xor     r12, r12
    mov     r13, [r15]

    mov     r10, [r14]
    lea     rdi, [r10 + r12]
    mov     rsi, ASM_HEADER
    mov     rdx, ASM_HEADER_LEN
    call    mem_move
    add     r12, ASM_HEADER_LEN

    ; pseudo ast
    .assembly:
        cmp     rbx, [r15 - 16]
        jz      .assembly_end
        
        cmp     byte [r13 + rbx], tkPushInt
        jz      .output_push_int
        
        cmp     BYTE [r13 + rbx], tkAdd
        jz      .output_add

        cmp     BYTE [r13 + rbx], tkSub
        jz      .output_sub

        cmp     BYTE [r13 + rbx], tkMul
        jz      .output_mul

        cmp     BYTE [r13 + rbx], tkDiv
        jz      .output_div

        cmp     BYTE [r13 + rbx], tkMod
        jz      .output_mod
        
        cmp     BYTE [r13 + rbx], tkModiv
        jz      .output_modiv

        cmp     BYTE [r13 + rbx], tkEqual
        jz      .output_equal

        cmp     BYTE [r13 + rbx], tkGreater
        jz      .output_greater

        cmp     BYTE [r13 + rbx], tkLesser
        jz      .output_lesser

        cmp     BYTE [r13 + rbx], tkGEqual
        jz      .output_greater_equal

        cmp     BYTE [r13 + rbx], tkLEqual
        jz      .output_lesser_equal

        cmp     BYTE [r13 + rbx], tkBitAnd
        jz      .output_bit_and

        cmp     BYTE [r13 + rbx], tkBitOr
        jz      .output_bit_or

        cmp     BYTE [r13 + rbx], tkAnd
        jz      .output_and

        cmp     BYTE [r13 + rbx], tkOr
        jz      .output_or

        cmp     BYTE [r13 + rbx], tkDump
        jz      .output_dump

        cmp     BYTE [r13 + rbx], tkDup
        jz      .output_dup

        cmp     BYTE [r13 + rbx], tkSwap
        jz      .output_swap

        cmp     BYTE [r13 + rbx], tkRot
        jz      .output_rot

        cmp     BYTE [r13 + rbx], tkOver
        jz      .output_over

        cmp     BYTE [r13 + rbx], tkDrop
        jz      .output_drop

        cmp     BYTE [r13 + rbx], tk2Dup
        jz      .output_2dup

        cmp     BYTE [r13 + rbx], tk2Swap
        jz      .output_2swap

        cmp     BYTE [r13 + rbx], tk2Drop
        jz      .output_2drop

        cmp     BYTE [r13 + rbx], tkIf
        jz      .output_if

        cmp     BYTE [r13 + rbx], tkThen
        jz      .output_then

        cmp     BYTE [r13 + rbx], tkElse
        jz      .output_else

        cmp     BYTE [r13 + rbx], tkElif
        jz      .output_elif

        cmp     BYTE [r13 + rbx], tkWhile
        jz      .output_while

        cmp     BYTE [r13 + rbx], tkDo
        jz      .output_do
        
        cmp     BYTE [r13 + rbx], tkProc
        jz      .output_proc

        cmp     BYTE [r13 + rbx], tkEnd
        jz      .output_end

        cmp     BYTE [r13 + rbx], tkIdent
        jz      .output_ident

        cmp     BYTE [r13 + rbx], tkAnOpen
        jz      .output_anonymous_open

        cmp     BYTE [r13 + rbx], tkAnClose
        jz      .output_anonymous_close

        cmp     BYTE [r13 + rbx], tkCall
        jz      .output_call

        cmp     BYTE [r13 + rbx], tkStackPtr
        jz      .output_stackptr

        cmp     BYTE [r13 + rbx], tkDerefPtr
        jz      .output_derefptr

        cmp     BYTE [r13 + rbx], tkSys0
        jz      .output_syscall0
        
        cmp     BYTE [r13 + rbx], tkSys1
        jz      .output_syscall1
        
        cmp     BYTE [r13 + rbx], tkSys2
        jz      .output_syscall2
        
        cmp     BYTE [r13 + rbx], tkSys3
        jz      .output_syscall3
        
        cmp     BYTE [r13 + rbx], tkSys4
        jz      .output_syscall4
        
        cmp     BYTE [r13 + rbx], tkSys5
        jz      .output_syscall5
        
        cmp     BYTE [r13 + rbx], tkSys6
        jz      .output_syscall6

        cmp     BYTE [r13 + rbx], tkPushStr
        jz      .output_push_string

        cmp     BYTE [r13 + rbx], tkNoOp
        jz      .assembly_next ; skip no ops


        jmp     .assembly_next
        .output_push_int:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_PUSH
            mov     rdx, ASM_PUSH_LEN
            call    mem_move
            add     r12, ASM_PUSH_LEN

            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 16]
            call    uitds

            lea     rdi, [r10 + r12]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r12, rdx

            mov     byte [r10 + r12], 10
            add     r12, 1
            jmp     .assembly_next

        .output_push_string:

            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_PUSH_STR_L
            mov     rdx, ASM_PUSH_STR_L_LEN
            call    mem_move
            add     r12, ASM_PUSH_STR_L_LEN

            lea     rdi, [r10 + r12]
            mov     rsi, ASM_PUSH_STR
            mov     rdx, ASM_PUSH_STR_LEN
            call    mem_move
            add     r12, ASM_PUSH_STR_LEN

            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 16]
            call    uitds

            lea     rdi, [r10 + r12]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r12, rdx

            lea     rdi, [r10 + r12]
            mov     rsi, ASM_CONST_STR_L
            mov     rdx, ASM_CONST_STR_L_LEN
            call    mem_move
            add     r12, ASM_CONST_STR_L_LEN
            
            lea     rdi, [r10 + r12]
            mov     rsi, newline
            mov     rdx, 1
            call    mem_move
            add     r12, 1

            lea     rdi, [r10 + r12]
            mov     rsi, ASM_PUSH_STR
            mov     rdx, ASM_PUSH_STR_LEN
            call    mem_move
            add     r12, ASM_PUSH_STR_LEN
            
            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 16]
            call    uitds

            lea     rdi, [r10 + r12]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r12, rdx

            lea     rdi, [r10 + r12]
            mov     rsi, newline
            mov     rdx, 1
            call    mem_move
            add     r12, 1

            jmp     .assembly_next

        .output_add:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_ADD
            mov     rdx, ASM_ADD_LEN
            call    mem_move
            add     r12, ASM_ADD_LEN
            jmp     .assembly_next

        .output_sub:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_SUB
            mov     rdx, ASM_SUB_LEN
            call    mem_move
            add     r12, ASM_SUB_LEN
            jmp     .assembly_next

        .output_mul:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_MUL
            mov     rdx, ASM_MUL_LEN
            call    mem_move
            add     r12, ASM_MUL_LEN
            jmp     .assembly_next

        .output_div:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_DIV
            mov     rdx, ASM_DIV_LEN
            call    mem_move
            add     r12, ASM_DIV_LEN
            jmp     .assembly_next

        .output_mod:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_MOD
            mov     rdx, ASM_MOD_LEN
            call    mem_move
            add     r12, ASM_MOD_LEN
            jmp     .assembly_next
        
        .output_modiv:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_MODIV
            mov     rdx, ASM_MODIV_LEN
            call    mem_move
            add     r12, ASM_MODIV_LEN
            jmp     .assembly_next

        .output_equal:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_EQUAL
            mov     rdx, ASM_EQUAL_LEN
            call    mem_move
            add     r12, ASM_EQUAL_LEN
            jmp     .assembly_next

        .output_greater:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_GREATER
            mov     rdx, ASM_GREATER_LEN
            call    mem_move
            add     r12, ASM_GREATER_LEN
            jmp     .assembly_next

        .output_lesser:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_LESSER
            mov     rdx, ASM_LESSER_LEN
            call    mem_move
            add     r12, ASM_LESSER_LEN
            jmp     .assembly_next

        .output_greater_equal:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_GEQUAL
            mov     rdx, ASM_GEQUAL_LEN
            call    mem_move
            add     r12, ASM_GEQUAL_LEN
            jmp     .assembly_next

        .output_lesser_equal:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_LEQUAL
            mov     rdx, ASM_LEQUAL_LEN
            call    mem_move
            add     r12, ASM_LEQUAL_LEN
            jmp     .assembly_next
      
        .output_bit_and:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_BIT_AND
            mov     rdx, ASM_BIT_AND_LEN
            call    mem_move
            add     r12, ASM_BIT_AND_LEN
            jmp     .assembly_next

        .output_bit_or:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_BIT_OR
            mov     rdx, ASM_BIT_OR_LEN
            call    mem_move
            add     r12, ASM_BIT_OR_LEN
            jmp     .assembly_next

        .output_and:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_AND
            mov     rdx, ASM_AND_LEN
            call    mem_move
            add     r12, ASM_AND_LEN
            jmp     .assembly_next

        .output_or:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_OR
            mov     rdx, ASM_OR_LEN
            call    mem_move
            add     r12, ASM_OR_LEN
            jmp     .assembly_next


        .output_dump:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_DUMP
            mov     rdx, ASM_DUMP_LEN
            call    mem_move
            add     r12, ASM_DUMP_LEN
            jmp     .assembly_next
        
        .output_dup:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_DUP
            mov     rdx, ASM_DUP_LEN
            call    mem_move
            add     r12, ASM_DUP_LEN
            jmp    .assembly_next
        
        .output_swap:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_SWAP
            mov     rdx, ASM_SWAP_LEN
            call    mem_move
            add     r12, ASM_SWAP_LEN
            jmp    .assembly_next
 
        .output_rot:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_ROT
            mov     rdx, ASM_ROT_LEN
            call    mem_move
            add     r12, ASM_ROT_LEN
            jmp    .assembly_next 
 
        .output_over:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_OVER
            mov     rdx, ASM_OVER_LEN
            call    mem_move
            add     r12, ASM_OVER_LEN
            jmp    .assembly_next
 
        .output_drop:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_DROP
            mov     rdx, ASM_DROP_LEN
            call    mem_move
            add     r12, ASM_DROP_LEN
            jmp    .assembly_next
 
        .output_2dup:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_2DUP
            mov     rdx, ASM_2DUP_LEN
            call    mem_move
            add     r12, ASM_2DUP_LEN
            jmp    .assembly_next
 
        .output_2swap:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_2SWAP
            mov     rdx, ASM_2SWAP_LEN
            call    mem_move
            add     r12, ASM_2SWAP_LEN
            jmp    .assembly_next
 
        .output_2drop:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_2SWAP
            mov     rdx, ASM_2SWAP_LEN
            call    mem_move
            add     r12, ASM_2SWAP_LEN
            jmp    .assembly_next
 
        
        .output_if:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_IF
            mov     rdx, ASM_IF_LEN
            call    mem_move
            add     r12, ASM_IF_LEN
            jmp     .assembly_next
        
        .output_then:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_THEN
            mov     rdx, ASM_THEN_LEN
            call    mem_move
            add     r12, ASM_THEN_LEN

            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 24]
            call    uitds
            lea     rdi, [r10 + r12]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r12, rdx

            mov     BYTE [r10 + r12], 10
            add     r12, 1
            jmp     .assembly_next

        .output_else:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_ELSE
            mov     rdx, ASM_ELSE_LEN
            call    mem_move
            add     r12, ASM_ELSE_LEN
            
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_ADDR
            mov     rdx, ASM_ADDR_LEN
            call    mem_move
            add     r12, ASM_ADDR_LEN

            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 16]
            call    uitds
            lea     rdi, [r10 + r12]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r12, rdx

            lea     rdi, [r10 + r12]
            mov     rsi, ASM_COLON
            mov     rdx, ASM_COLON_LEN
            call    mem_move
            add     r12, ASM_COLON_LEN


            lea     rdi, [r10 + r12]
            mov     rsi, ASM_JMP
            mov     rdx, ASM_JMP_LEN
            call    mem_move
            add     r12, ASM_JMP_LEN

            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 24]
            call    uitds
            lea     rdi, [r10 + r12]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r12, rdx

            mov     BYTE [r10 + r12], 10
            add     r12, 1
            
            ; jump for if
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_ADDR
            mov     rdx, ASM_ADDR_LEN
            call    mem_move
            add     r12, ASM_ADDR_LEN
            
            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 32]
            call    uitds
            lea     rdi, [r10 + r12]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r12, rdx
            
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_COLON
            mov     rdx, ASM_COLON_LEN
            call    mem_move
            add     r12, ASM_COLON_LEN
            jmp     .assembly_next
            
        .output_elif:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_ELIF
            mov     rdx, ASM_ELIF_LEN
            call    mem_move
            add     r12, ASM_ELIF_LEN
            
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_ADDR
            mov     rdx, ASM_ADDR_LEN
            call    mem_move
            add     r12, ASM_ADDR_LEN

            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 16]
            call    uitds
            lea     rdi, [r10 + r12]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r12, rdx

            lea     rdi, [r10 + r12]
            mov     rsi, ASM_COLON
            mov     rdx, ASM_COLON_LEN
            call    mem_move
            add     r12, ASM_COLON_LEN


            lea     rdi, [r10 + r12]
            mov     rsi, ASM_JMP
            mov     rdx, ASM_JMP_LEN
            call    mem_move
            add     r12, ASM_JMP_LEN

            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 24]
            call    uitds
            lea     rdi, [r10 + r12]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r12, rdx

            mov     BYTE [r10 + r12], 10
            add     r12, 1
            
            ; jump for if
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_ADDR
            mov     rdx, ASM_ADDR_LEN
            call    mem_move
            add     r12, ASM_ADDR_LEN
            
            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 32]
            call    uitds
            lea     rdi, [r10 + r12]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r12, rdx
            
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_COLON
            mov     rdx, ASM_COLON_LEN
            call    mem_move
            add     r12, ASM_COLON_LEN
            jmp     .assembly_next


        .output_while:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_WHILE
            mov     rdx, ASM_WHILE_LEN
            call    mem_move
            add     r12, ASM_WHILE_LEN

            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 16]
            call    uitds
            lea     rdi, [r10 + r12]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r12, rdx
            
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_COLON
            mov     rdx, ASM_COLON_LEN
            call    mem_move
            add     r12, ASM_COLON_LEN

            jmp     .assembly_next


        .output_do:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_DO
            mov     rdx, ASM_DO_LEN
            call    mem_move
            add     r12, ASM_DO_LEN

            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 16]
            call    uitds
            lea     rdi, [r10 + r12]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r12, rdx

            mov     BYTE [r10 + r12], 10
            add     r12, 1
            jmp     .assembly_next


        .output_proc:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_PROC_DEC
            mov     rdx, ASM_PROC_DEC_LEN
            call    mem_move
            add     r12, ASM_PROC_DEC_LEN
            
            ; SKIPPING
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_SKIP_JMP
            mov     rdx, ASM_SKIP_JMP_LEN
            call    mem_move
            add     r12, ASM_SKIP_JMP_LEN
            
            
            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 16] ; addr end
            call    uitds
            lea     rdi, [r10 + r12]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r12, rdx

            mov     BYTE [r10 + r12], 10
            add     r12, 1

            ; DECL
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_PROC_L
            mov     rdx, ASM_PROC_L_LEN
            call    mem_move
            add     r12, ASM_PROC_L_LEN
            
            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 16] ; addr end
            call    uitds
            lea     rdi, [r10 + r12]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r12, rdx

            lea     rdi, [r10 + r12]
            mov     rsi, ASM_COLON
            mov     rdx, ASM_COLON_LEN
            call    mem_move
            add     r12, ASM_COLON_LEN

            ; PREPARATION
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_PROC_PREP
            mov     rdx, ASM_PROC_PREP_LEN
            call    mem_move
            add     r12, ASM_PROC_PREP_LEN

            jmp     .assembly_next

        .output_end:
            cmp     BYTE [r13 + rbx + 13], varEndIf
            jz      .output_end_var_if
            cmp     BYTE [r13 + rbx + 13], varEndDo
            jz      .output_end_var_do
            cmp     BYTE [r13 + rbx + 13], varEndProc
            jz      .output_end_var_proc

            jmp     error_illegal ; TODO: ERROR
            .output_end_var_if:
                mov     r10, [r14]
                lea     rdi, [r10 + r12]
                mov     rsi, ASM_END_L
                mov     rdx, ASM_END_L_LEN
                call    mem_move
                add     r12, ASM_END_L_LEN

                lea     rdi, [r10 + r12]
                mov     rsi, ASM_ADDR
                mov     rdx, ASM_ADDR_LEN
                call    mem_move
                add     r12, ASM_ADDR_LEN

                lea     rsi, [rsp]
                sub     rsp, 20
                mov     rdi, [r13 + rbx + 16]
                call    uitds
                lea     rdi, [r10 + r12]
                mov     rsi, rax
                call    mem_move
                add     rsp, 20
                add     r12, rdx
                
                lea     rdi, [r10 + r12]
                mov     rsi, ASM_COLON
                mov     rdx, ASM_COLON_LEN
                call    mem_move
                add     r12, ASM_COLON_LEN

                jmp     .assembly_next

            .output_end_var_do:
                mov     r10, [r14]
                lea     rdi, [r10 + r12]
                mov     rsi, ASM_END_L
                mov     rdx, ASM_END_L_LEN
                call    mem_move
                add     r12, ASM_END_L_LEN

                lea     rdi, [r10 + r12]
                mov     rsi, ASM_JMP
                mov     rdx, ASM_JMP_LEN
                call    mem_move
                add     r12, ASM_JMP_LEN
                
                lea     rsi, [rsp]
                sub     rsp, 20
                mov     rdi, [r13 + rbx + 16]
                call    uitds

                lea     rdi, [r10 + r12]
                mov     rsi, rax
                call    mem_move
                add     rsp, 20
                add     r12, rdx

                lea     rdi, [r10 + r12]
                mov     rsi, newline
                mov     rdx, 1
                call    mem_move
                add     r12, 1

                lea     rdi, [r10 + r12]
                mov     rsi, ASM_ADDR
                mov     rdx, ASM_ADDR_LEN
                call    mem_move
                add     r12, ASM_ADDR_LEN
                
                lea     rsi, [rsp]
                sub     rsp, 20
                mov     rdi, [r13 + rbx + 24]
                call    uitds

                lea     rdi, [r10 + r12]
                mov     rsi, rax
                call    mem_move
                add     rsp, 20
                add     r12, rdx
                
                lea     rdi, [r10 + r12]
                mov     rsi, ASM_COLON
                mov     rdx, ASM_COLON_LEN
                call    mem_move
                add     r12, ASM_COLON_LEN

                jmp     .assembly_next

            .output_end_var_proc:
                mov     r10, [r14]
                lea     rdi, [r10 + r12]
                mov     rsi, ASM_PROC_END
                mov     rdx, ASM_PROC_END_LEN
                call    mem_move
                add     r12, ASM_PROC_END_LEN

                lea     rdi, [r10 + r12]
                mov     rsi, ASM_SKIP_ADDR
                mov     rdx, ASM_SKIP_ADDR_LEN
                call    mem_move
                add     r12, ASM_SKIP_ADDR_LEN

                lea     rsi, [rsp]
                sub     rsp, 20
                mov     rdi, [r13 + rbx + 16]
                call    uitds
                lea     rdi, [r10 + r12]
                mov     rsi, rax
                call    mem_move
                add     rsp, 20
                add     r12, rdx
                
                lea     rdi, [r10 + r12]
                mov     rsi, ASM_COLON
                mov     rdx, ASM_COLON_LEN
                call    mem_move
                add     r12, ASM_COLON_LEN

                jmp     .assembly_next

        .output_ident:
            cmp     BYTE [r13 + rbx + 13], varIdentProc
            jz      .output_proc_call
            cmp     BYTE [r13 + rbx + 13], varIdentIgnore
            jz      .assembly_next
            ; TODO: use this to detect identifiers without decl
            jmp     error_illegal  ; TODO: ERROR

            .output_proc_call:
                mov     r10, [r14]
                lea     rdi, [r10 + r12]
                mov     rsi, ASM_PROC_CALL_L
                mov     rdx, ASM_PROC_CALL_L_LEN
                call    mem_move
                add     r12, ASM_PROC_CALL_L_LEN
                
                lea     rdi, [r10 + r12]
                mov     rsi, ASM_CALL_START
                mov     rdx, ASM_CALL_START_LEN
                call    mem_move
                add     r12, ASM_CALL_START_LEN

                lea     rdi, [r10 + r12]
                mov     rsi, ASM_CALL
                mov     rdx, ASM_CALL_LEN
                call    mem_move
                add     r12, ASM_CALL_LEN
            

                lea     rdi, [r10 + r12]
                mov     rsi, ASM_PROC_L
                mov     rdx, ASM_PROC_L_LEN
                call    mem_move
                add     r12, ASM_PROC_L_LEN

                lea     rsi, [rsp]
                sub     rsp, 20
                mov     rdi, [r13 + rbx + 16]
                call    uitds
                lea     rdi, [r10 + r12]
                mov     rsi, rax
                call    mem_move
                add     rsp, 20
                add     r12, rdx


                lea     rdi, [r10 + r12]
                mov     rsi, ASM_CALL_END
                mov     rdx, ASM_CALL_END_LEN
                call    mem_move
                add     r12, ASM_CALL_END_LEN

                jmp     .assembly_next

        .output_anonymous_open:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_ANON1
            mov     rdx, ASM_ANON1_LEN
            call    mem_move
            add     r12, ASM_ANON1_LEN

            lea     rdi, [r10 + r12]
            mov     rsi, ASM_ANON2
            mov     rdx, ASM_ANON2_LEN
            call    mem_move
            add     r12, ASM_ANON2_LEN

            ; SKIPPING
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_SKIP_JMP
            mov     rdx, ASM_SKIP_JMP_LEN
            call    mem_move
            add     r12, ASM_SKIP_JMP_LEN
            
            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 24] ; addr end
            call    uitds
            lea     rdi, [r10 + r12]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r12, rdx

            mov     BYTE [r10 + r12], 10
            add     r12, 1

            lea     rdi, [r10 + r12]
            mov     rsi, ASM_PROC_L
            mov     rdx, ASM_PROC_L_LEN
            call    mem_move
            add     r12, ASM_PROC_L_LEN
            
            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 24] ; addr end
            call    uitds
            lea     rdi, [r10 + r12]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r12, rdx

            lea     rdi, [r10 + r12]
            mov     rsi, ASM_COLON
            mov     rdx, ASM_COLON_LEN
            call    mem_move
            add     r12, ASM_COLON_LEN

            ; PREPARATION
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_PROC_PREP
            mov     rdx, ASM_PROC_PREP_LEN
            call    mem_move
            add     r12, ASM_PROC_PREP_LEN

            jmp     .assembly_next

        .output_anonymous_close:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_ANON_END
            mov     rdx, ASM_ANON_END_LEN
            call    mem_move
            add     r12, ASM_ANON_END_LEN

            lea     rdi, [r10 + r12]
            mov     rsi, ASM_SKIP_ADDR
            mov     rdx, ASM_SKIP_ADDR_LEN
            call    mem_move
            add     r12, ASM_SKIP_ADDR_LEN

            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 24]
            call    uitds
            lea     rdi, [r10 + r12]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r12, rdx
            
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_COLON
            mov     rdx, ASM_COLON_LEN
            call    mem_move
            add     r12, ASM_COLON_LEN

            lea     rdi, [r10 + r12]
            mov     rsi, ASM_ANON_PUSH
            mov     rdx, ASM_ANON_PUSH_LEN
            call    mem_move
            add     r12, ASM_ANON_PUSH_LEN

            lea     rsi, [rsp]
            sub     rsp, 20
            mov     rdi, [r13 + rbx + 24]
            call    uitds
            lea     rdi, [r10 + r12]
            mov     rsi, rax
            call    mem_move
            add     rsp, 20
            add     r12, rdx

            mov     BYTE [r10 + r12], 10
            add     r12, 1
            jmp     .assembly_next
        
        .output_call:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_ANON_CALL
            mov     rdx, ASM_ANON_CALL_LEN
            call    mem_move
            add     r12, ASM_ANON_CALL_LEN
            jmp     .assembly_next

        .output_stackptr:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_STACKPTR
            mov     rdx, ASM_STACKPTR_LEN
            call    mem_move
            add     r12, ASM_STACKPTR_LEN
            jmp     .assembly_next

        .output_derefptr:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_DEREFPTR
            mov     rdx, ASM_DEREFPTR_LEN
            call    mem_move
            add     r12, ASM_DEREFPTR_LEN
            jmp     .assembly_next

        .output_syscall0:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_SYS0
            mov     rdx, ASM_SYS0_LEN
            call    mem_move
            add     r12, ASM_SYS0_LEN
            jmp     .assembly_next
     
        .output_syscall1:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_SYS1
            mov     rdx, ASM_SYS1_LEN
            call    mem_move
            add     r12, ASM_SYS1_LEN
            jmp     .assembly_next


        .output_syscall2:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_SYS2
            mov     rdx, ASM_SYS2_LEN
            call    mem_move
            add     r12, ASM_SYS2_LEN
            jmp     .assembly_next


        .output_syscall3:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_SYS3
            mov     rdx, ASM_SYS3_LEN
            call    mem_move
            add     r12, ASM_SYS3_LEN
            jmp     .assembly_next


        .output_syscall4:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_SYS4
            mov     rdx, ASM_SYS4_LEN
            call    mem_move
            add     r12, ASM_SYS4_LEN
            jmp     .assembly_next


        .output_syscall5:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_SYS5
            mov     rdx, ASM_SYS5_LEN
            call    mem_move
            add     r12, ASM_SYS5_LEN
            jmp     .assembly_next
 
        .output_syscall6:
            mov     r10, [r14]
            lea     rdi, [r10 + r12]
            mov     rsi, ASM_SYS6
            mov     rdx, ASM_SYS6_LEN
            call    mem_move
            add     r12, ASM_SYS6_LEN
            jmp     .assembly_next

        
        .assembly_next:
        ; - BUFFER ASSEMBLY GROW -
        mov     rax, [r14 - 8] ; current max
        mov     rcx, GROW_SIZE ; divisor
        xor     rdx, rdx ; rest
        div     rcx ; rax => 50% of current
        cmp     r12, rax 
        jg      .grow_assembly_buffer
        jmp     .not_grow_assembly_buffer
        .grow_assembly_buffer:
        mov     rdi, [r14 - 0]
        mov     rsi, [r14 - 8]
        mov     rax, rsi
        mov     rcx, GROW_SIZE
        mul     rcx
        mov     rdx, rax
        call    remap_memory
        mov     [14 - 0], rax
        mov     [14 - 8], rdx
        .not_grow_assembly_buffer:
        add     rbx, 48
        jmp     .assembly
    
    .assembly_end:

    mov     r10, [r14]
    lea     rdi, [r10 + r12]
    mov     rsi, ASM_ENDING
    mov     rdx, ASM_ENDING_LEN
    call    mem_move
    add     r12, ASM_ENDING_LEN

    lea     rdi, [r10 + r12]
    mov     rsi, ASM_CONST_DATA_SECTION
    mov     rdx, ASM_CONST_DATA_SECTION_LEN
    call    mem_move
    add     r12, ASM_CONST_DATA_SECTION_LEN

    add     qword [r14 - 16], r12

    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx

    mov     rsp, rbp
    pop     rbp
    ret


; input:
;   rdi: strings
;   rsi: output
assembly_add_string_constants:
    push    rbp
    mov     rbp, rsp

    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r15, rdi
    mov     r14, rsi

    mov     r10, [r14]
    mov     r12, [r14 - 16] ; offset output
    
    mov     r13, [r15] ; strings

    xor     rbx, rbx
    .assembly_strings:
        cmp     rbx, qword [r15 - 16]
        jz      .assembly_strings_end
        cmp     byte [r13 + rbx + 24], varStringIgnore
        jz      .assembly_strings_next
        
        lea     rdi, [r10 + r12]
        mov     rsi, ASM_CONST_STR
        mov     rdx, ASM_CONST_STR_LEN
        call    mem_move
        add     r12, ASM_CONST_STR_LEN
    
        lea     rsi, [rsp]
        sub     rsp, 20
        mov     rdi, [r13 + rbx]
        call    uitds
        lea     rdi, [r10 + r12]
        mov     rsi, rax
        call    mem_move
        add     rsp, 20
        add     r12, rdx

        lea     rdi, [r10 + r12]
        mov     rsi, ASM_DB_WORD
        mov     rdx, ASM_DB_WORD_LEN
        call    mem_move
        add     r12, ASM_DB_WORD_LEN

        lea     rdi, [r10 + r12]
        mov     rsi, [r13 + rbx + 8]
        mov     rdx, [r13 + rbx + 16]
        call    mem_move
        add     r12, [r13 + rbx + 16]

        lea     rdi, [r10 + r12]
        mov     rsi, ASM_STR_END
        mov     rdx, ASM_STR_END_LEN
        call    mem_move
        add     r12, ASM_STR_END_LEN

        lea     rdi, [r10 + r12]
        mov     rsi, ASM_CONST_STR
        mov     rdx, ASM_CONST_STR_LEN
        call    mem_move
        add     r12, ASM_CONST_STR_LEN

        lea     rsi, [rsp]
        sub     rsp, 20
        mov     rdi, [r13 + rbx]
        call    uitds
        lea     rdi, [r10 + r12]
        mov     rsi, rax
        call    mem_move
        add     rsp, 20
        add     r12, rdx

        lea     rdi, [r10 + r12]
        mov     rsi, ASM_CONST_STR_L
        mov     rdx, ASM_CONST_STR_L_LEN
        call    mem_move
        add     r12, ASM_CONST_STR_L_LEN

        lea     rdi, [r10 + r12]
        mov     rsi, ASM_EQ_LEN_WORD
        mov     rdx, ASM_EQ_LEN_WORD_LEN
        call    mem_move
        add     r12, ASM_EQ_LEN_WORD_LEN

        lea     rdi, [r10 + r12]
        mov     rsi, ASM_CONST_STR
        mov     rdx, ASM_CONST_STR_LEN
        call    mem_move
        add     r12, ASM_CONST_STR_LEN

        lea     rsi, [rsp]
        sub     rsp, 20
        mov     rdi, [r13 + rbx]
        call    uitds
        lea     rdi, [r10 + r12]
        mov     rsi, rax
        call    mem_move
        add     rsp, 20
        add     r12, rdx

        lea     rdi, [r10 + r12]
        mov     rsi, ASM_STR_LEN_END
        mov     rdx, ASM_STR_LEN_END_LEN
        call    mem_move
        add     r12, ASM_STR_LEN_END_LEN

        .assembly_strings_next:
        ; - BUFFER ASSEMBLY GROW -
        mov     rax, [r14 - 8] ; current max
        mov     rcx, GROW_SIZE ; divisor
        xor     rdx, rdx ; rest
        div     rcx ; rax => 50% of current
        cmp     r12, rax 
        jg      .grow_assembly_buffer
        jmp     .not_grow_assembly_buffer
        .grow_assembly_buffer:
        mov     rdi, [r14 - 0]
        mov     rsi, [r14 - 8]
        mov     rax, rsi
        mov     rcx, GROW_SIZE
        mul     rcx
        mov     rdx, rax
        call    remap_memory
        mov     [14 - 0], rax
        mov     [14 - 8], rdx
        .not_grow_assembly_buffer:

        add     rbx, 32
        jmp     .assembly_strings

    .assembly_strings_end:
    mov     [r14 - 16], r12

    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx

    mov     rsp, rbp
    pop     rbp
    ret


; input:
;   rdi: strings
;   rsi: output
assembly_add_mutable_constants:
    push    rbp
    mov     rbp, rsp

    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r15, rdi
    mov     r14, rsi

    mov     r10, [r14]
    mov     r12, [r14 - 16] ; offset output

    xor     rbx, rbx

    lea     rdi, [r12 + r10]
    mov     rsi, ASM_MUTABLE_DATA_SECTION
    mov     rdx, ASM_MUTABLE_DATA_SECTION_LEN
    call    mem_move
    add     r12, ASM_MUTABLE_DATA_SECTION_LEN

    mov     [r14 - 16], r12

    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx

    mov     rsp, rbp
    pop     rbp
    ret


; input:
;   rdi: strings
;   rsi: output
assembly_add_finish:
    push    rbp
    mov     rbp, rsp

    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r14, rdi

    mov     r10, [r14]
    mov     r12, [r14 - 16]

    lea     rdi, [r12 + r10]
    mov     rsi, ASM_RETURN_STACK
    mov     rdx, ASM_RETURN_STACK_LEN
    call    mem_move
    add     r12, ASM_RETURN_STACK_LEN

    mov     [r14 - 16], r12

    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx

    mov     rsp, rbp
    pop     rbp
    ret


; input
;   rdi: path   = ptr string (null term)
; modify
;   rax, rbx, rdi, rsi, r8, r9, r10
; output
;   rax: file   = ptr string (allocated heap)
;   rdx: len    = u64
;    r8:  fd    = u64
open_file:
    push    rbp
    mov     rbp, rsp
    push    rbx
    push    r12

    mov     rsi, O_RDONLY
    mov     rax, SYS_OPEN
    syscall ; rax = file descriptor (fd)
    
    mov     r12 , rax
    
    cmp     r12, -1
    je      error_file_not_found

    sub     rsp, 144 ; place to allocate fstat
    
    mov     rdi, r12
    mov     rsi, rsp ; buffer start
    mov     rax, SYS_FSTAT
    syscall ; stack allocated fstat struct (144 bytes)
    
    mov     rbx, [rsp + 48] ; save len
    add     rsp, 144 ; free fstat 

    ; r8 is fd
    xor     rdi, rdi
    mov     rsi, rbx
    mov     rdx, PROT_READ
    mov     r10, MAP_PRIVATE 
    xor     r9 , r9
    mov     r8, r12
    mov     rax, SYS_MMAP
    syscall ; rax = ptr file buffer

    mov     rdx, rsi
    mov     r8, r12
    pop     r12
    pop     rbx
    mov     rsp, rbp
    pop     rbp
    ret


; checks if import is from std
; input
;   rdi: ptr
;   rsi: len (not really required but useful for safety)
; output
;   rax: 0 -> false, 1 -> true
is_std?:
    cmp     rsi, STD_START_LEN
    jle     .is_not_std
    mov     rsi, STD_START
    mov     rdx, STD_START_LEN
    call    mem_cmp ; result in rax already
    ret

    .is_not_std:
    mov     rax, 0
    ret

; takes a string and simply appends ktt at the end of it
; if it does not end with ktt
; input
;   rdi: ptr
;   rsi: len
; output
;   rsi: newlen
append_ktt_if_necessary:
    cmp     rsi, KTT_ENDING_LEN ; shorter => 100% no ktt ending
    mov     r9, rsi
    mov     r10, rsi
    jle     .append_ktt

    ; index of potential .ktt
    sub     r9, KTT_ENDING_LEN
    mov     r11, rdi ; store
    lea     rdi, [rdi + r9]

    mov     rsi, KTT_ENDING
    mov     rdx, KTT_ENDING_LEN
    call    mem_cmp
    cmp     rax, 1
    jz      .append_ktt_end ; has .ktt already


    .append_ktt:
    mov     rdi, r11
    lea     rdi, [rdi + r10]
    mov     rsi, KTT_ENDING
    mov     rdx, KTT_ENDING_LEN
    call    mem_move

    add     r10, KTT_ENDING_LEN
    .append_ktt_end:
    mov     rsi, r10
    ret
; input
;   rdi: hexfile index
hexdump_file:
    push    rbp
    mov     rbp, rsp

    push    r12
    push    r13
    push    r14
    ; push    r15

    ; mov     r15, rdi

    mov     r14, rsp
    sub     rsp, 1
    mov     byte [rsp], 0
    sub     rsp, hex_file_len
    mov     rdi, rsp
    mov     rsi, hex_file
    mov     rdx, hex_file_len
    call    mem_move

    sub     rsp, 1
    mov     r12, [r15 - 152]
    add     r12, 48
    mov     byte [rsp], r12b

    mov     r10, [arg_ptr]
    mov     r10, [r10 + 8]
    mov     rdi, r10
    call    strlen
    mov     r12, rax
    sub     rsp, r12

    mov     rdi, rsp
    mov     rsi, r10
    mov     rdx, r12
    call    mem_move

    mov     rdi, rsp
    mov     rsi, hex_file_len
    add     rsi, r12

    mov     rdi, rsp
    mov     rsi, O_WRONLY or O_CREAT or O_TRUNC
    xor     rdx, rdx
    mov     rax, SYS_OPEN
    syscall
    mov     r13, rax

    mov     rdi, r13
    mov     rsi, [r15]
    mov     rdx, [r15 - 16]
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, r13
    mov     rax, SYS_CLOSE
    syscall

    mov     rsp, r14

    
    ; pop     r15
    pop     r14
    pop     r13
    pop     r12

    mov     rsp, rbp
    pop     rbp
    ret

; malloc but scuffed
; input:
;   rdi: u64 = size map 
; modify
;   rsi, rdx, r10, r8, r9, rax    
; output:
;   rax: ptr = addr to memory
;   rdi: u64 = size of memory (unchanged input)
map_memory:
    push    rdi
    mov     rsi, rdi ; memory size
    xor     rdi, rdi ; memory address (NULL)
    mov     rdx, PROT_READ or PROT_WRITE ; operations / protections
    mov     r10, MAP_PRIVATE or MAP_ANONYMOUS ; flags => map mem not file
    xor     r8 , r8 ; mem not file, no fd needed
    xor     r9 , r9 ; mem not file, no offsete needed
    mov     rax, SYS_MMAP
    syscall ; rax = ptr mem buffer
    pop rdi
    ret 
    
; input
;   rdi: addr   = ptr buffer
;   rsi: len    = u64
; modifies
;   rax
unmap_memory:
    mov     rax, SYS_MUNMAP
    syscall
    ret


; input
;   rdi: addr    = ptr buffer
;   rsi: old len = u64
;   rdx: new len = u64
remap_memory:
    mov     r10, MREMAP_MAYMOVE
    mov     rax, SYS_MREMAP
    syscall
    ret


; move memory
; input:
;   rdi: ptr destination
;   rsi: ptr source
;   rdx: len to move 
mem_move:
    push    rcx
    xor     rcx, rcx
    .loop_mem_move:
        mov     al, BYTE [rsi + rcx] ; src byte
        mov     BYTE [rdi + rcx], al ; dst byte
        inc     rcx
        cmp     rcx, rdx
        jnz .loop_mem_move

    pop     rcx
    ret

; compare memory
; input:
;   rdi: ptr 1
;   rsi: ptr 2
;   rdx: len
; output: 
;   rax: 1 equal, 0 unequal
mem_cmp:
    xor     rcx, rcx
    .loop_mem_cmp:
        mov     r8l, BYTE [rdi + rcx]
        cmp     r8l, BYTE [rsi + rcx]
        jnz     .mem_cmp_exit_unequal
        inc     rcx
        cmp     rcx, rdx
        jnz     .loop_mem_cmp
        jmp     .mem_cmp_exit

    .mem_cmp_exit_unequal:
        mov     rax, 0
        ret
    .mem_cmp_exit:
        mov     rax, 1
        ret


; input:
;   rdi: ptr string
;   rsi: len string
print_string:
    push    rdi
    push    rax
    push    rdx
    push    rcx
    push    rsi

    mov     rdx, rsi
    mov     rsi, rdi
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall
    
    pop     rsi
    pop     rcx
    pop     rdx
    pop     rax
    pop     rdi
    ret

; print single char
; input:
;   rdi: ptr char
; modify:
;   rdi, rsi, rdx, rax, rcx (syscall changes rcx)
; output:
;   rdi: ptr char (unchanged)
print_char:
    push    rdi
    lea     rsi, [rsp]
    mov     rdi, STDOUT
    mov     rdx, 1
    mov     rax, SYS_WRITE
    syscall
    pop     rdi
    ret

; modify:
;   rsi, rdx, rax, (rcx as well XD)
print_newline:
    push    rsi
    push    rdx
    push    rdi
    push    rax
    push    rcx
    lea     rsi, [newline]
    mov     rdx, 1
    mov     rdi, 1
    mov     rax, 1
    syscall
    pop     rcx
    pop     rax
    pop     rdi
    pop     rdx
    pop     rsi
    ret


print_a:
    push    rsi
    push    rdx
    push    rdi
    push    rax
    push    rcx
    lea     rsi, [char_a]
    mov     rdx, 1
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall
    pop     rcx
    pop     rax
    pop     rdi
    pop     rdx
    pop     rsi
    ret

print_b:
    push    rsi
    push    rdx
    push    rdi
    push    rax
    push    rcx
    lea     rsi, [char_b]
    mov     rdx, 1
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall
    pop     rcx
    pop     rax
    pop     rdi
    pop     rdx
    pop     rsi

    ret

print_c:
    push    rsi
    push    rdx
    push    rdi
    push    rax
    push    rcx
    lea     rsi, [char_c]
    mov     rdx, 1
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall
    pop     rcx
    pop     rax
    pop     rdi
    pop     rdx
    pop     rsi
    ret

print_space:
    push    rsi
    push    rdx
    push    rdi
    push    rax
    lea     rsi, [char_space]
    mov     rdx, 1
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall
    pop     rax
    pop     rdi
    pop     rdx
    pop     rsi
    ret

; prints uint
; input:
;   rdi: value
; output:
;   rdi: value (unchanged)
print_uint:
    push    rbp
    mov     rbp, rsp

    push    rdi

    lea     rsi, [rsp] ; save "base" addr for uitds
    sub     rsp, 20 ; max digits + new line

    call    uitds
    
    mov     r8, 20
    sub     r8, rdx
    add     rsp, r8

    mov     rsi, rax
    mov     rdx, rdx ; rdx is already len
    mov     rdi, STDOUT
    mov     rax, SYS_WRITE
    syscall

    pop     rdi
    mov     rsp, rbp
    pop     rbp
    ret

; input:
;   rdi: value
;   rsi: ptr string (only alloc)
; output:
;   rax: ptr string (modified)
;   rdx: uint = len
uitds:
    push    rdi ; save value for second loop
    mov     rax, rdi ; use for div
    mov     r8 , 10 ; use as divisor
    
    xor     rcx, rcx ; be sure rcx is 0
    .loop_uitds_count:
        xor     rdx, rdx ; reset rdx for div
        div     r8 ; rax / 10 = rax, rest: rdx
        inc     rcx
        test    rax, rax
        jnz     .loop_uitds_count

    pop     rax ; pop saved value for second loop
    sub     rsi, rcx ; "allocate memory" within stack
    push    rsi ; store pointer to string start
    push    rcx ; store string len

    .loop_uitds_write:
        xor     rdx, rdx
        div     r8
        add     rdx, 48 ; rest div = digit, num + 48 => ascii num
        ; move only a byte into the stack
        ; -1 because rcx is len not index
        mov     BYTE [rsi + rcx - 1], dl 
        dec     rcx
        jnz     .loop_uitds_write
    
    pop     rdx ; take string len
    pop     rax ; take string pointer
    ret


; input:
;   rdi: string
; output:
;   rax: len
strlen:
    xor rax, rax
    .loop_strlen:
        inc rax
        cmp BYTE [rdi + rax], 0
        jnz .loop_strlen
    .strlen_end:
        ret


; ERRORS
error_file_not_found:
    mov     rdi, STDOUT
    mov     rsi, err0
    mov     rdx, err0len
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall

error_too_many_end:
    mov     rdi, STDOUT
    mov     rsi, err1
    mov     rdx, err1len
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall

error_if_without_end:
    mov     rdi, STDOUT
    mov     rsi, err2
    mov     rdx, err2len
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall

error_then_without_if:
    mov     rdi, STDOUT
    mov     rsi, err7
    mov     rdx, err7len
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall

error_do_without_while:
    mov     rdi, STDOUT
    mov     rsi, err3
    mov     rdx, err3len
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall

error_else_without_if:
    mov     rdi, STDOUT
    mov     rsi, err4
    mov     rdx, err4len
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall

error_no_ident_after_proc:
    mov     rdi, STDOUT
    mov     rsi, err5
    mov     rdx, err5len
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall

error_in_without_proc:
    mov     rdi, STDOUT
    mov     rsi, err6
    mov     rdx, err6len
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall

error_no_file_given:
    mov     rdi, STDOUT
    mov     rsi, err8
    mov     rdx, err8len
    mov     rax, SYS_WRITE
    syscall
    
    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall

error_no_output_given:
    mov     rdi, STDOUT
    mov     rsi, err9
    mov     rdx, err9len
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall

error_missing_path_after_use:
    mov     rdi, STDOUT
    mov     rsi, err10
    mov     rdx, err10len
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall

error_missing_anonymous_close:
    mov     rdi, STDOUT
    mov     rsi, err11
    mov     rdx, err11len
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall

error_illegal:
    mov     rdi, STDOUT
    mov     rsi, errminus1
    mov     rdx, errminus1len
    mov     rax, SYS_WRITE
    syscall

    mov     rdi, 1
    mov     rax, SYS_EXIT
    syscall

segment readable writable
    arg_count rq 1
    arg_ptr rq 1
    hexdump db 0

segment readable

; ERRORS
err0        db  "File not found"
err0len     =   $ - err0

err1        db  "too many end"
err1len     =   $ - err1

err2        db  "missing closing end"
err2len     =   $ - err2

err3        db  "do without while"
err3len     =   $ - err3

err4        db  "else without then"
err4len     =   $ - err4

err5        db  "expected identifier"
err5len     =   $ - err5

err6        db  "expected proc & symbol before in"
err6len     =   $ - err6

err7        db  "then without if"
err7len     =   $ - err7

err8        db  "No file given"
err8len     =   $ - err8

err9        db  "No output_given"
err9len     =   $ - err9

err10       db  "Missing path after use"
err10len    =   $ - err10

err11       db  "Expected closing ] to close anonymous function"
err11len    =   $ - err11

errminus1   db  "illegal error LOL, this is probably a parser error"
errminus1len=   $ - errminus1

; util
KTT_ENDING      db  ".ktt"
KTT_ENDING_LEN  =   $ - KTT_ENDING

STD_START       db  "std/"
STD_START_LEN   =   $ - STD_START

; LANGUAGE KEYWORDS
KEY_CMMT_START  db  "/", 42
KEY_CMMT_END    db  42, "/"
KEY_DUP         db  "dup"
KEY_DUP_LEN     =   $ - KEY_DUP

KEY_SWAP        db  "swap"
KEY_SWAP_LEN    =   $ - KEY_SWAP

KEY_ROT         db  "rot"
KEY_ROT_LEN     =   $ - KEY_ROT

KEY_OVER        db  "over"
KEY_OVER_LEN    =   $ - KEY_OVER

KEY_DROP        db  "drop"
KEY_DROP_LEN    =   $ - KEY_DROP

KEY_2DUP        db  "2dup"
KEY_2DUP_LEN    =   $ - KEY_2DUP

KEY_2SWAP       db  "2swap"
KEY_2SWAP_LEN   =   $ - KEY_2SWAP

KEY_2DROP       db  "2drop"
KEY_2DROP_LEN   =   $ - KEY_2DROP

KEY_AND         db  "and"
KEY_AND_LEN     =   $ - KEY_AND

KEY_OR          db  "or"
KEY_OR_LEN      =   $ - KEY_OR

KEY_IF          db  "if"
KEY_IF_LEN      =   $ - KEY_IF

KEY_THEN        db  "then"
KEY_THEN_LEN    =   $ - KEY_THEN

KEY_ELSE        db  "else"
KEY_ELSE_LEN    =   $ - KEY_ELSE

KEY_ELIF        db  "elif"
KEY_ELIF_LEN    =   $ - KEY_ELIF

KEY_WHILE       db  "while"
KEY_WHILE_LEN   =   $ - KEY_WHILE

KEY_DO          db  "do"
KEY_DO_LEN      =   $ - KEY_DO

KEY_PROC        db  "proc"
KEY_PROC_LEN    =   $ - KEY_PROC

KEY_IN          db  "in"
KEY_IN_LEN      =   $ - KEY_IN

KEY_END         db  "end"
KEY_END_LEN     =   $ - KEY_END

KEY_USE         db  "use"
KEY_USE_LEN     =   $ - KEY_USE

KEY_CALL        db  "call"
KEY_CALL_LEN    =   $ - KEY_CALL

KEY_STACKPTR    db  "stackptr"
KEY_STACKPTR_LEN=   $ - KEY_STACKPTR

KEY_DEREFPTR    db  "derefptr"
KEY_DEREFPTR_LEN=   $ - KEY_DEREFPTR

KEY_SYS0        db  "syscall0"
KEY_SYS0_LEN    =   $ - KEY_SYS0

KEY_SYS1        db  "syscall1"
KEY_SYS1_LEN    =   $ - KEY_SYS1

KEY_SYS2        db  "syscall2"
KEY_SYS2_LEN    =   $ - KEY_SYS2

KEY_SYS3        db  "syscall3"
KEY_SYS3_LEN    =   $ - KEY_SYS3

KEY_SYS4        db  "syscall4"
KEY_SYS4_LEN    =   $ - KEY_SYS4

KEY_SYS5        db  "syscall5"
KEY_SYS5_LEN    =   $ - KEY_SYS5

KEY_SYS6        db  "syscall6"
KEY_SYS6_LEN    =   $ - KEY_SYS6


; ASSEMBLY OUTPUT
ASM_PUSH        db  "; -- PUSH --", 10, "push " ; insert number here
ASM_PUSH_LEN    =   $ - ASM_PUSH

ASM_ADD         db  "; -- ADD --", 10, "pop rbx", 10, "pop rax", 10, "add rax, rbx", 10, "push rax", 10
ASM_ADD_LEN     =   $ - ASM_ADD

ASM_SUB         db  "; -- SUB --", 10, "pop rbx", 10, "pop rax", 10, "sub rax, rbx", 10, "push rax", 10
ASM_SUB_LEN     =   $ - ASM_SUB

ASM_MUL         db  "; -- MUL --", 10, "pop rbx", 10, "pop rax", 10, "mul rbx", 10, "push rax", 10
ASM_MUL_LEN     =   $ - ASM_MUL

ASM_DIV         db  "; -- DIV --", 10, "pop rbx", 10, "pop rax", 10, "xor rdx, rdx", 10, "div rbx", 10, "push rax", 10
ASM_DIV_LEN     =   $ - ASM_DIV

ASM_MOD         db  "; -- MOD --", 10, "pop rbx", 10, "pop rax", 10, "xor rdx, rdx", 10, "div rbx", 10, "push rdx", 10
ASM_MOD_LEN     =   $ - ASM_MOD

ASM_MODIV       db  "; -- MODIV --", 10, "pop rbx", 10, "pop rax", 10, "xor rdx, rdx", 10, "div rbx", 10, "push rdx", 10, "push rax", 10
ASM_MODIV_LEN   =   $ - ASM_MODIV


ASM_EQUAL       db  "; -- EQUAL --", 10, "pop rbx", 10, "pop rax", 10, "xor rcx, rcx", 10, "cmp rax, rbx", 10, "mov rdx, 1", 10,"cmove rcx, rdx", 10, "push rcx", 10
ASM_EQUAL_LEN   =   $ - ASM_EQUAL

ASM_GREATER     db  "; -- GREATER --", 10, "pop rbx", 10, "pop rax", 10, "xor rcx, rcx", 10, "cmp rax, rbx", 10, "mov rdx, 1", 10,"cmovg rcx, rdx", 10, "push rcx", 10
ASM_GREATER_LEN =   $ - ASM_GREATER

ASM_LESSER      db  "; -- LESSER --", 10, "pop rbx", 10, "pop rax", 10, "xor rcx, rcx", 10, "cmp rax, rbx", 10, "mov rdx, 1", 10,"cmovl rcx, rdx", 10, "push rcx", 10
ASM_LESSER_LEN  =   $ - ASM_LESSER

ASM_GEQUAL      db  "; -- GREATER EQUAL --", 10, "pop rbx", 10, "pop rax", 10, "xor rcx, rcx", 10, "cmp rax, rbx", 10, "mov rdx, 1", 10,"cmovge rcx, rdx", 10, "push rcx", 10
ASM_GEQUAL_LEN  =   $ - ASM_GEQUAL

ASM_LEQUAL      db  "; -- LESSER EQUAL --", 10, "pop rbx", 10, "pop rax", 10, "xor rcx, rcx", 10, "cmp rax, rbx", 10, "mov rdx, 1", 10,"cmovle rcx, rdx", 10, "push rcx", 10
ASM_LEQUAL_LEN  =   $ - ASM_LEQUAL

ASM_BIT_AND     db  "; -- BIT AND --", 10, "pop rbx", 10, "pop rax", 10, "and rax, rbx", 10, "push rax", 10
ASM_BIT_AND_LEN =   $ - ASM_BIT_AND


ASM_BIT_OR      db  "; -- BIT OR --", 10, "pop rbx", 10, "pop rax", 10, "or rax, rbx", 10, "push rbx", 10
ASM_BIT_OR_LEN  =   $ - ASM_BIT_OR

ASM_AND         db  "; -- AND --", 10, "pop rbx", 10, "pop rax", 10, "mov rcx, 1", 10, "mov rdx, 0", 10, "and rax, rbx", 10, "cmp rax, 0", 10, "cmovnz rdx, rcx", 10, "push rdx", 10
ASM_AND_LEN     =   $ - ASM_AND

ASM_OR          db  "; -- OR --", 10, "pop rbx", 10, "pop rax", 10, "mov rcx, 1", 10, "mov rdx, 0", 10, "or rax, rbx", 10, "cmp rax, 0", 10, "cmovnz, rdx, rdx", 10, "push rdx", 10
ASM_OR_LEN      =   $ - ASM_OR


ASM_DUMP        db  "; -- DUMP --", 10, "pop rdi", 10, "call dump_uint", 10
ASM_DUMP_LEN    =   $ - ASM_DUMP

ASM_DUP         db  "; -- DUP --", 10, "pop rax", 10, "push rax", 10, "push rax", 10
ASM_DUP_LEN     =   $ - ASM_DUP

ASM_SWAP        db  "; -- SWAP --", 10, "pop rax", 10, "pop rbx", 10, "push rax", 10, "push rbx", 10
ASM_SWAP_LEN    =   $ - ASM_SWAP

ASM_ROT         db  "; -- ROT --", 10, "pop rax", 10, "pop rbx", 10, "pop rcx", 10, "push rbx", 10, "push rax", 10, "push rcx", 10
ASM_ROT_LEN     =   $ - ASM_ROT

ASM_OVER        db  "; -- OVER --", 10, "pop rax", 10, "pop rbx", 10, "push rbx", 10, "push rax", 10, "push rbx", 10
ASM_OVER_LEN    =   $ - ASM_OVER

ASM_DROP        db  "; -- DROP --", 10, "pop r15", 10, "xor r15, r15", 10
ASM_DROP_LEN    =   $ - ASM_DROP

ASM_2DUP        db  "; -- 2DUP --", 10, "pop rax", 10, "pop rbx", 10, "push rbx", 10, "push rax", 10, "push rbx", 10, "push rax", 10
ASM_2DUP_LEN    =   $ - ASM_2DUP

ASM_2SWAP       db  "; -- 2SWAP --", 10, "pop rax", 10, "pop rbx", 10, "pop rcx", 10, "pop rdx", 10, "push rbx", 10, "push rax", 10, "push rdx", 10, "push rcx", 10

ASM_2SWAP_LEN   =   $ - ASM_2SWAP

ASM_2DROP       db  "; -- 2DROP --", 10, "pop rax", 10, "pop rax", 10, "xor rax, rax", 10
ASM_2DROP_LEN   =   $ - ASM_2DROP

ASM_IF          db  "; -- IF --", 10 ; only debug label
ASM_IF_LEN      =   $ - ASM_IF

ASM_THEN        db  "; -- THEN -- ", 10, "pop rax", 10, "cmp rax, 0", 10, "jz _Addr" ; insert jmp label 
ASM_THEN_LEN    =   $ - ASM_THEN

ASM_ELSE        db  "; -- ELSE --", 10
ASM_ELSE_LEN    =   $ - ASM_ELSE

ASM_ELIF        db  "; -- ELIF --", 10
ASM_ELIF_LEN    =   $ - ASM_ELIF

ASM_WHILE       db  "; -- WHILE --", 10, "_Addr"
ASM_WHILE_LEN   =   $ - ASM_WHILE

ASM_DO          db  "; -- DO --", 10, "pop rax", 10, "cmp rax, 0", 10, "jz _Addr"
ASM_DO_LEN      =   $ - ASM_DO

ASM_END_L       db  "; -- END --", 10
ASM_END_L_LEN   =   $ - ASM_END_L

ASM_ADDR        db  "_Addr"
ASM_ADDR_LEN    =   $ - ASM_ADDR

ASM_COLON       db  ":", 10
ASM_COLON_LEN   =   $ - ASM_COLON

ASM_JMP         db  "jmp _Addr"
ASM_JMP_LEN     =   $ - ASM_JMP

ASM_SKIP_JMP        db  "jmp _SkipAddr"
ASM_SKIP_JMP_LEN    =   $ - ASM_SKIP_JMP

ASM_SKIP_ADDR       db  "_SkipAddr"
ASM_SKIP_ADDR_LEN   =   $ - ASM_SKIP_ADDR

ASM_ANON1           db  "; -- ANONYMOUS PROC DECL --", 10
ASM_ANON1_LEN       =   $ - ASM_ANON1

ASM_ANON2           db  "; - skip & label -", 10
ASM_ANON2_LEN       =   $ - ASM_ANON2   

ASM_ANON_END        db  "; -- ANONYMOUS PROC END --", 10, "; - return - ", 10, "mov rax, rsp", 10, "mov rsp, [RETURN_STACK_PTR]", 10, "ret", 10, "; - skip -", 10
ASM_ANON_END_LEN    =   $ - ASM_ANON_END

ASM_ANON_PUSH       db  "; - push anonymous label - ", 10, "push _Proc"
ASM_ANON_PUSH_LEN   =   $ - ASM_ANON_PUSH

ASM_ANON_CALL       db  "; -- CALL ANONYMOUS PROC -- ", 10, "pop rcx", 10, "mov rax, rsp", 10, "mov rsp, [RETURN_STACK_PTR]", 10, "call rcx", 10, "mov [RETURN_STACK_PTR], rsp", 10, "mov rsp, rax", 10
ASM_ANON_CALL_LEN   =   $ - ASM_ANON_CALL

ASM_PROC_DEC        db  "; -- PROC DECLERATION --", 10, "; - skip & label -", 10
ASM_PROC_DEC_LEN    =   $ - ASM_PROC_DEC

ASM_PROC_PREP       db  "; - prepare -", 10, "mov [RETURN_STACK_PTR], rsp", 10, "mov rsp, rax", 10, "; - body -", 10
ASM_PROC_PREP_LEN   =   $ - ASM_PROC_PREP

ASM_PROC_L          db  "_Proc"
ASM_PROC_L_LEN      =   $ - ASM_PROC_L

ASM_PROC_END        db  "; -- PROC END --", 10, "; - return - ", 10, "mov rax, rsp", 10, "mov rsp, [RETURN_STACK_PTR]", 10, "ret", 10, "; - skip -", 10
ASM_PROC_END_LEN    =   $ - ASM_PROC_END

ASM_PROC_CALL_L     db  "; -- CALL PROC -- ", 10
ASM_PROC_CALL_L_LEN =   $ - ASM_PROC_CALL_L

ASM_CALL_START      db  "mov rax, rsp", 10, "mov rsp, [RETURN_STACK_PTR]", 10
ASM_CALL_START_LEN  =   $ - ASM_CALL_START

ASM_CALL_END        db  10, "mov [RETURN_STACK_PTR], rsp", 10, "mov rsp, rax", 10
ASM_CALL_END_LEN    =   $ - ASM_CALL_END

ASM_CALL            db  "call "
ASM_CALL_LEN        =   $ -  ASM_CALL

ASM_STACKPTR        db  "; -- STACKPTR --", 10, "pop rax", 10, "lea rax, [rsp + rax]", 10, "push rax", 10
ASM_STACKPTR_LEN    =   $ - ASM_STACKPTR

ASM_DEREFPTR        db  "; -- DEREFPTR --", 10, "pop rax", 10, "mov rax, [rax]", 10, "push rax", 10
ASM_DEREFPTR_LEN    =   $ - ASM_DEREFPTR

; SYSCALLS (WORKS GOOD ENOUGH FOR NOW)
ASM_SYS0        db  "; -- SYSCALL0 --", 10, "pop rax", 10, "syscall", 10, "push rax", 10
ASM_SYS0_LEN    =   $ - ASM_SYS0

ASM_SYS1        db  "; -- SYSCALL1 --", 10, "pop rax", 10, "pop rdi", 10, "syscall", 10, "push rax", 10
ASM_SYS1_LEN    =   $ - ASM_SYS1

ASM_SYS2        db  "; -- SYSCALL2 --", 10, "pop rax", 10, "pop rdi", 10, "pop rsi", 10, "syscall", 10, "push rax", 10
ASM_SYS2_LEN    =   $ - ASM_SYS2

ASM_SYS3        db  "; -- SYSCALL3 --", 10, "pop rax", 10, "pop rdi", 10, "pop rsi",  10, "pop rdx", 10, "syscall", 10, "push rax", 10
ASM_SYS3_LEN    =   $ - ASM_SYS3

ASM_SYS4        db  "; -- SYSCALL4 --", 10, "pop rax", 10, "pop rdi", 10, "pop rsi", 10, "pop rdx", 10, "pop r10", 10, "syscall", 10, "push rax", 10
ASM_SYS4_LEN    =   $ - ASM_SYS4

ASM_SYS5        db  "; -- SYSCALL5 --", 10, "pop rax", 10, "pop rdi", 10, "pop rsi", 10, "pop rdx", 10, "pop r10", 10, "pop r8", 10, "syscall", 10, "push rax", 10
ASM_SYS5_LEN    =   $ - ASM_SYS5

ASM_SYS6        db  "; -- SYSCALL6 --", 10, "pop rax", 10, "pop rdi", 10, "pop rsi", 10, "pop rdx", 10, "pop r10",10, "pop r8", 10, "pop r9", 10, "syscall", 10, "push rax", 10
ASM_SYS6_LEN    =   $ - ASM_SYS6

ASM_PUSH_STR_L      db  "; -- PUSH STRING --", 10
ASM_PUSH_STR_L_LEN  =   $ - ASM_PUSH_STR_L

ASM_PUSH_STR        db  "push CONST_STRING_"
ASM_PUSH_STR_LEN    =   $ - ASM_PUSH_STR

ASM_CONST_STR       db  "CONST_STRING_"
ASM_CONST_STR_LEN   =   $ - ASM_CONST_STR

ASM_CONST_STR_L     db  "_LEN"
ASM_CONST_STR_L_LEN =   $ - ASM_CONST_STR_L

ASM_DB_WORD         db  " db "
ASM_DB_WORD_LEN     =   $ - ASM_DB_WORD

ASM_EQ_LEN_WORD     db  " = $ - "
ASM_EQ_LEN_WORD_LEN =   $ - ASM_EQ_LEN_WORD

ASM_STR_LEN_END     db  " - 1", 10
ASM_STR_LEN_END_LEN =   $ - ASM_STR_LEN_END

ASM_STR_END         db  ", 0", 10
ASM_STR_END_LEN     =   $ - ASM_STR_END



ASM_HEADER      db "format ELF64 executable 3", 10
    db 10
    db "segment readable executable", 10
    db 10
    db "dump_uint:", 10
    db "mov     r8, -3689348814741910323", 10
    db "sub     rsp, 40", 10
    db "mov     BYTE [rsp+19], 10", 10
    db "lea     rcx, [rsp+18]", 10
    db ".L2:", 10
    db "mov     rax, rdi", 10
    db "mul     r8", 10
    db "mov     rax, rdi", 10
    db "shr     rdx, 3", 10
    db "lea     rsi, [rdx+rdx*4]", 10
    db "add     rsi, rsi", 10
    db "sub     rax, rsi", 10
    db "add     eax, 48", 10
    db "mov     BYTE [rcx], al", 10
    db "mov     rax, rdi", 10
    db "mov     rdi, rdx", 10
    db "mov     rdx, rcx", 10
    db "sub     rcx, 1", 10
    db "cmp     rax, 9", 10
    db "ja      .L2", 10
    db "lea     rax, [rsp+20]", 10
    db "mov     edi, 1", 10
    db "mov     rcx, rax", 10
    db "sub     rcx, rdx", 10
    db "sub     rdx, rax", 10
    db "lea     rsi, [rsp+20+rdx]", 10
    db "mov     rdx, rcx", 10
    db "mov     rax, 1", 10
    db "syscall", 10
    db "add     rsp, 40", 10
    db "ret", 10
    db 10
    db "entry $", 10
    db "; -- STARTUP -- ", 10
    db "mov rax, RETURN_STACK_END", 10
    db "mov [RETURN_STACK_PTR], rax", 10, 10
    db "mov rax, rsp", 10
    db "mov [ARGS_COUNT], rax", 10
    db "add rax, 8", 10
    db "mov [ARGS_PTR], rax", 10, 10


ASM_HEADER_LEN = $ - ASM_HEADER

ASM_ENDING db 10, "mov rdi, 0", 10
    db "mov rax, 60", 10
    db "syscall", 10

ASM_ENDING_LEN = $ - ASM_ENDING


ASM_CONST_DATA_SECTION          db  10, "; -- CONST DATA --", 10, "segment readable", 10, 10
ASM_CONST_DATA_SECTION_LEN      =   $ - ASM_CONST_DATA_SECTION

ASM_MUTABLE_DATA_SECTION        db  10, 10, "; -- MUTABLE DATA --", 10, "segment readable writable", 10, 10
ASM_MUTABLE_DATA_SECTION_LEN    =   $ - ASM_MUTABLE_DATA_SECTION

ASM_RETURN_STACK        db  "; -- RETURN STACK --", 10, "RETURN_STACK_PTR rq 1", 10, "RETURN_STACK rq 1028", 10, "RETURN_STACK_END:", 10, "ARGS_COUNT rq 1", 10, "ARGS_PTR rq 1", 10
ASM_RETURN_STACK_LEN    =   $ - ASM_RETURN_STACK

; PRINTING
newline     db 10
char_space  db 32
char_a      db 65
char_b      db 66
char_c      db 67

; HARDCODED
hexcommand      db  "-hex"
hexcommand_len  =   $ - hexcommand
hex_file        db  ".hex"
hex_file_len    =   $ - hex_file
heap_root dq ?

arg_count dq ?
arg_ptr dq ?

hello db "ok cool bro"
hello_len =  $ - hello

helloParser db "hello from parser",10, 0
helloParserLen = $ - helloParser
helloXD db "hello from XD",10, 0
helloXDLen = $ - helloXD


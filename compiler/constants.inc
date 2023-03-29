true = 1
false = 0
null = 0

whitespace = 32
newline = 10
horizontalTab = 9

testStr db "test: %d\n"
countStr db "count: %d\n"
valStr db "value: %d\n"
valStrStr db "string: %s\n"
valCharStr db "char: %c\n"

testingString db "hello world XD", 0

programCode db ""
  db "420 690 + .", 10
  db "666 66 66 - + .", 10

programCodeLen = $ - programCode
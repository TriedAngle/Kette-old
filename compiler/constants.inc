true = 1
false = 0
null = 0

whitespace = 32
newline = 10
horizontalTab = 9
double_quotes = 34

macro newString name, string {
  name db string
  name#.len = $ - name
}

newString symBO     , "["
newString symBC     , "]"
newString symPO     , "("
newString symPC     , ")"
newString symCol    , ":"
newString symSim    , ";"
newString symDot    , "."

newString builtinCall   , "kwCall"
newString builtinEval   , "kwEval"
newString builtinLoop   , "loop"
newString builtinWhile  , "while"
newString builtinGoto   , "goto"
newString builtinIf     , "if"
newString builtinMacro  , "macro:"
newString builtinVar    , "var:"
newString builtinIncl   , "include:"

newString builtinEq     , "="
newString builtinLeEq   , "<="
newString builtinGrEq   , ">="
newString builtinLe     , "<"
newString builtinGr     , ">"

newString builtinAdd    , "+"
newString builtinSub    , "-"
newString builtinMul    , "*"
newString builtinDiv    , "/"
newString builtinMod    , "%"
newString builtinModDiv , "/%"

newString builtinDrop   , "drop"
newString builtinDup    , "dup"
newString builtinSwap   , "swap"
newString builtinOver   , "over"
newString builtinRot    , "rot"
newString builtinCRot   , "-rot"
newString builtin2Drop  , "2drop"
newString builtin2Dup   , "2dup"
newString builtin2Swap  , "2swap"
newString builtin2Over  , "2over"
newString builtinDropd  , "dropd"
newString builtinDupd   , "dupd"
newString builtinSwapd  , "swapd"
newString builtinOverd  , "overd"
newString builtinRotd   , "rotd"
newString builtinNip    , "nip"
newString builtinPick   , "pick"
newString builtinPickd  , "pickd"
newString builtinDip    , "dip"

newString builtinBitAnd  , "bitand"
newString builtinBitOr   , "bitor"
newString builtinBitXor  , "bitxor"
newString builtinBitNot  , "bitnot"
newString builtinBitShift, "bitshift"


testStr db "test: %d\n"
countStr db "count: %d\n"
valStr db "value: %d\n"
valStrStr db "string: %s\n"
valCharStr db "char: %c\n"

valValStr db "value: %d, %d\n"

testingString db "hello world XD", 0

programCode db ""
  db "420 690 + .", 10
  db "666 66 66 - + .", 10

programCodeLen = $ - programCode

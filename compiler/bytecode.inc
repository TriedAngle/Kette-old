iota true
newToken tkString
newToken tkNumber
newToken tkSymbol
newToken tkBuiltinControl
newToken tkBuiltinStack
newToken tkBuiltinBool
newToken tkBuiltinArith

iota true
newToken tvSymbolBO
newToken tvSymbolBC
newToken tvSymbolPO
newToken tvSymbolPC
newToken tvSymbolCol
newToken tvSymbolSim

iota true
newToken tvControlCall 
newToken tvControlEval 
newToken tvControlLoop 
newToken tvControlWhile
newToken tvControlGoto 
newToken tvControlIf   
newToken tvControlMacro
newToken tvControlVar
newToken tvControlIncl

iota true
newToken tvBuiltinDrop 
newToken tvBuiltinDup  
newToken tvBuiltinSwap 
newToken tvBuiltinOver 
newToken tvBuiltinRot  
newToken tvBuiltinCRot 
newToken tvBuiltin2Drop
newToken tvBuiltin2Dup 
newToken tvBuiltin2Swap
newToken tvBuiltin2Over
newToken tvBuiltinDropd
newToken tvBuiltinDupd 
newToken tvBuiltinSwapd
newToken tvBuiltinOverd
newToken tvBuiltinRotd 
newToken tvBuiltinNip  
newToken tvBuiltinPick 
newToken tvBuiltinPickd
newToken tvBuiltinDip  

iota true
newToken tvBoolEq
newToken tvBoolLeEq
newToken tvBoolGrEq
newToken tvBoolLe
newToken tvBoolGr

iota true
newToken tvArithAdd
newToken tvArithSub
newToken tvArithMul
newToken tvArithDiv
newToken tvArithMod
newToken tvArithModDiv

iota true
newToken tvNumInt
newToken tvNumFloat
newToken tvNumExp
newToken tvNumFloatExp
; iota true
; newToken subString

struc CodeToken {
  .type db ?
  .subtype db ?
  .line dd ?
  .col dd ?
  .slotw dw ?
  .slotd dd ?
  .slot0 dq ?
  .slot1 dq ?
  .slot2 dq ?
}

virtual at 0
  CodeToken CodeToken
  sizeof.CodeToken = $ - CodeToken
end virtual


struc TokenStorageS {
  .tokens dq ? ; ptr ArrayList
}

virtual at 0
  TokenStorageS TokenStorageS
  sizeof.TokenStorageS = $ - TokenStorageS
end virtual


TokenStorage:
.new:
  mov rdi, sizeof.TokenStorageS
  call malloc
  push rax
  call ArrayList.new
  pop rdi
  mov [rdi + TokenStorageS.tokens], rax 
  mov rax, rdi
  ret

.destroy:
  mov rdi, [r15 + TokenStorageS.tokens]
  call free
  mov rdi, r15
  call free
  ret


.add_token:
  push r15
  mov r15, [r15 + TokenStorageS.tokens]
  call ArrayList.push_back
  pop r15
  ret
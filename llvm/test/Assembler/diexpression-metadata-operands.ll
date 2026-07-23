; The operations in these expressions use no metadata operands, so
; verification rejects the nonempty operand lists.
;
; RUN: not llvm-as -disable-output < %s 2>&1 | FileCheck %s --check-prefix=VERIFY
; RUN: llvm-as -disable-verify < %s | llvm-dis | FileCheck %s --check-prefix=ROUNDTRIP
; RUN: llvm-as -disable-verify < %s | llvm-bcanalyzer -dump | FileCheck %s --check-prefix=BITCODE

; VERIFY: assembly parsed, but does not verify as correct
; VERIFY: invalid expression

; ROUNDTRIP: !expressions = !{!0, !2, !3, !DIExpression(DW_OP_deref)}
; ROUNDTRIP: !0 = !DIExpression(48, operands: {!1, null, i32 7, !1})
; ROUNDTRIP: !1 = !{!"target"}
; ROUNDTRIP: !2 = !DIExpression(48, operands: {!1})
; ROUNDTRIP: !3 = distinct !DIExpression(48, operands: {!3})

; BITCODE: <EXPRESSION op0=9 op1=1 op2=48 op3=[[SELF:[0-9]+]]/>
; BITCODE: <EXPRESSION op0=8 op1=1 op2=48 op3=[[TARGET:[0-9]+]] op4=0
; BITCODE-SAME: op5=[[CONSTANT:[0-9]+]] op6=[[TARGET]]/>
; BITCODE: <EXPRESSION op0=8 op1=1 op2=48 op3=[[TARGET]]/>
; BITCODE: <EXPRESSION op0=6 op1=6/>

!expressions = !{!0, !1, !2, !3}

!0 = !DIExpression(DW_OP_lit0, operands: {!4, null, i32 7, !4})
!1 = !DIExpression(DW_OP_lit0, operands: {!4})
!2 = distinct !DIExpression(DW_OP_lit0, operands: {!2})
!3 = !DIExpression(DW_OP_deref)
!4 = !{!"target"}

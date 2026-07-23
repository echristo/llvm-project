; The expressions in this test are not valid because DW_OP_lit0 does not use
; metadata operands. Disable verification only to test that llvm-link preserves
; the metadata representation.
;
; RUN: split-file %s %t
; RUN: llvm-link -disable-verify -S %t/first.ll %t/second.ll | FileCheck %s

; CHECK: !first = !{!0}
; CHECK: !second = !{!2}
; CHECK: !0 = !DIExpression(48, operands: {!1, null, !1})
; CHECK: !1 = !{!"first target"}
; CHECK: !2 = !DIExpression(48, operands: {!3, !4, !3})
; CHECK: !3 = !{!"second target"}
; CHECK: !4 = !{!"middle"}

;--- first.ll
!first = !{!0}
!0 = !DIExpression(DW_OP_lit0, operands: {!1, null, !1})
!1 = !{!"first target"}

;--- second.ll
!second = !{!0}
!0 = !DIExpression(DW_OP_lit0, operands: {!1, !2, !1})
!1 = !{!"second target"}
!2 = !{!"middle"}

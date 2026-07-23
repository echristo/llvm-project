; Test parser diagnostics for malformed DIExpression operand fields.
;
; RUN: split-file %s %t
; RUN: not llvm-as %t/unknown-field.ll -o /dev/null 2>&1 | FileCheck %s --check-prefix=UNKNOWN
; RUN: not llvm-as %t/non-final-operands.ll -o /dev/null 2>&1 | FileCheck %s --check-prefix=FINAL
; RUN: not llvm-as %t/arg-list.ll -o /dev/null 2>&1 | FileCheck %s --check-prefix=ARG-LIST

; UNKNOWN: expected unsigned integer or 'operands:'
; FINAL: 'operands:' must be the final field
; ARG-LIST: DIArgList is only valid in a function

;--- unknown-field.ll
!named = !{!0}
!0 = !DIExpression(DW_OP_lit0, targets: {!1})
!1 = !{}

;--- non-final-operands.ll
!named = !{!0}
!0 = !DIExpression(operands: {!1}, DW_OP_lit0)
!1 = !{}

;--- arg-list.ll
!named = !{!0}
!0 = !DIExpression(DW_OP_lit0, operands: {!DIArgList(i32 7)})

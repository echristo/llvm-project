; RUN: not llvm-as -disable-output %s 2>&1 | FileCheck %s

; CHECK: DW_OP_LLVM_call_procedure invalid in procedure body
; CHECK: !DIDwarfProcedure

!named = !{!0}
!0 = !DIDwarfProcedure(expression: !DIExpression(DW_OP_LLVM_call_procedure, 0))

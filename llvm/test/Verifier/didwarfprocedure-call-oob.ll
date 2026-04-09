; RUN: llvm-as -disable-output %s 2>&1 | FileCheck %s

; call_procedure index out of range (only 1 procedure, index 5).
; CHECK: call_procedure index out of range
; CHECK: warning: ignoring invalid debug info

!llvm.dbg.cu = !{!3}
!llvm.module.flags = !{!5}

!0 = !DIDwarfProcedure(name: "bad", expression: !DIExpression(DW_OP_LLVM_call_procedure, 5))
!1 = !DIFile(filename: "test.c", directory: "/tmp")
!2 = !{!0}
!3 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, dwarfProcedures: !2)
!5 = !{i32 2, !"Debug Info Version", i32 3}

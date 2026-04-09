; RUN: llvm-as -disable-output %s 2>&1 | FileCheck %s --allow-empty

; DW_OP_LLVM_call_procedure is valid in procedure bodies when the call
; graph is acyclic and indices are in range.
; CHECK-NOT: error
; CHECK-NOT: invalid

!llvm.dbg.cu = !{!5}
!llvm.module.flags = !{!7}

; Procedure 0 calls procedure 1 (non-recursive, valid).
!0 = !DIDwarfProcedure(name: "caller", expression: !DIExpression(DW_OP_LLVM_call_procedure, 1, DW_OP_constu, 42, DW_OP_plus))
; Procedure 1 is a leaf (no calls).
!1 = !DIDwarfProcedure(name: "callee", expression: !DIExpression(DW_OP_deref, DW_OP_plus_uconst, 8))
; Procedure 2 calls both 0 and 1 in sequence (multiple calls from one body).
!10 = !DIDwarfProcedure(name: "multi", expression: !DIExpression(DW_OP_LLVM_call_procedure, 0, DW_OP_LLVM_call_procedure, 1))
!2 = !DIFile(filename: "test.c", directory: "/tmp")
!3 = !{!0, !1, !10}
!5 = distinct !DICompileUnit(language: DW_LANG_C99, file: !2, isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, dwarfProcedures: !3)
!7 = !{i32 2, !"Debug Info Version", i32 3}

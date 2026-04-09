; RUN: llvm-as -disable-output %s 2>&1 | FileCheck %s

; Mutual recursion: procedure 0 calls procedure 1, procedure 1 calls procedure 0.
; CHECK: cycle in DWARF procedure call graph
; CHECK: warning: ignoring invalid debug info

!llvm.dbg.cu = !{!4}
!llvm.module.flags = !{!8}

!0 = !DIDwarfProcedure(name: "A", expression: !DIExpression(DW_OP_LLVM_call_procedure, 1))
!1 = !DIDwarfProcedure(name: "B", expression: !DIExpression(DW_OP_LLVM_call_procedure, 0))
!2 = !DIFile(filename: "test.c", directory: "/tmp")
!3 = !{!0, !1}
!4 = distinct !DICompileUnit(language: DW_LANG_C99, file: !2, isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, dwarfProcedures: !3)
!8 = !{i32 2, !"Debug Info Version", i32 3}

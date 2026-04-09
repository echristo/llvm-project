; RUN: llvm-as -disable-output %s 2>&1 | FileCheck %s

; Self-recursion: procedure 0 calls itself.
; CHECK: cycle in DWARF procedure call graph
; CHECK: warning: ignoring invalid debug info

!llvm.dbg.cu = !{!3}
!llvm.module.flags = !{!5}

!0 = !DIDwarfProcedure(name: "self", expression: !DIExpression(DW_OP_LLVM_call_procedure, 0))
!1 = !DIFile(filename: "test.c", directory: "/tmp")
!2 = !{!0}
!3 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, dwarfProcedures: !2)
!5 = !{i32 2, !"Debug Info Version", i32 3}

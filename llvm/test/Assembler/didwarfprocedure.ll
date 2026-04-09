; RUN: llvm-as < %s | llvm-dis | llvm-as | llvm-dis | FileCheck %s
; RUN: verify-uselistorder %s

; CHECK: !named = !{!DIExpression(DW_OP_deref), !DIExpression(DW_OP_lit0), !DIExpression(DW_OP_LLVM_call_procedure, 0), !0, !1, !2, !5}
!named = !{!0, !1, !9, !2, !3, !4, !30}

!0 = !DIExpression(DW_OP_deref)
!1 = !DIExpression(DW_OP_lit0)

; Expression containing DW_OP_LLVM_call_procedure round-trips.
!9 = !DIExpression(DW_OP_LLVM_call_procedure, 0)

; Named procedure.
; CHECK: !0 = !DIDwarfProcedure(name: "container_size", expression: !DIExpression(DW_OP_deref))
!2 = !DIDwarfProcedure(name: "container_size", expression: !0)

; Anonymous procedure.
; CHECK: !1 = !DIDwarfProcedure(expression: !DIExpression(DW_OP_lit0))
!3 = !DIDwarfProcedure(expression: !1)

; CU with dwarfProcedures (includes caller that references procedure 0).
; CHECK: !2 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, dwarfProcedures: !4)
!4 = distinct !DICompileUnit(language: DW_LANG_C99, file: !5, isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, dwarfProcedures: !6)
!5 = !DIFile(filename: "test.c", directory: "/tmp")
!6 = !{!2, !3, !30}

; Procedure whose body calls another procedure (index 0) — round-trips.
; CHECK: !5 = !DIDwarfProcedure(name: "caller", expression: !DIExpression(DW_OP_LLVM_call_procedure, 0, DW_OP_constu, 42, DW_OP_plus))
!30 = !DIDwarfProcedure(name: "caller", expression: !DIExpression(DW_OP_LLVM_call_procedure, 0, DW_OP_constu, 42, DW_OP_plus))

; CU without dwarfProcedures — field should not appear.
; CHECK: !6 = distinct !DICompileUnit(language: DW_LANG_C99, file: !3, isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
; CHECK-NOT: dwarfProcedures
!7 = distinct !DICompileUnit(language: DW_LANG_C99, file: !5, isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)

!llvm.dbg.cu = !{!4, !7}
!llvm.module.flags = !{!8}
!8 = !{i32 2, !"Debug Info Version", i32 3}

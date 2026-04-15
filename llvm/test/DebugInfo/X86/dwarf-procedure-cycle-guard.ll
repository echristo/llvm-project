; Test that cyclic DWARF procedure call graphs are detected.
; The verifier catches cycles and drops the debug info as invalid.
; The emission-time report_fatal_error in emitDwarfProcedureBodyImpl
; is defense-in-depth for corrupted bitcode that bypasses verification.
;
; RUN: llc -mtriple=x86_64 -dwarf-version=4 -filetype=obj -O0 < %s \
; RUN:   -o /dev/null 2>&1 | FileCheck %s
;
; CHECK: cycle in DWARF procedure call graph

define void @cycle_test(ptr %p) !dbg !10 {
  call void @llvm.dbg.value(metadata ptr %p, metadata !13, metadata !14), !dbg !15
  ret void, !dbg !15
}

declare void @llvm.dbg.value(metadata, metadata, metadata) nounwind readnone

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!8, !9}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, dwarfProcedures: !2)
!1 = !DIFile(filename: "cycle.c", directory: "/tmp")
!2 = !{!3, !5}
!3 = !DIDwarfProcedure(name: "proc_a", expression: !4)
!4 = !DIExpression(DW_OP_LLVM_call_procedure, 1, DW_OP_lit0)
!5 = !DIDwarfProcedure(name: "proc_b", expression: !6)
!6 = !DIExpression(DW_OP_LLVM_call_procedure, 0, DW_OP_lit0)
!7 = !DISubroutineType(types: !{null, !11})
!8 = !{i32 2, !"Debug Info Version", i32 3}
!9 = !{i32 2, !"Dwarf Version", i32 4}
!10 = distinct !DISubprogram(name: "cycle_test", scope: !1, file: !1, line: 1, type: !7, spFlags: DISPFlagDefinition, unit: !0)
!11 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!13 = !DILocalVariable(name: "v", scope: !10, file: !1, line: 2, type: !16)
!14 = !DIExpression(DW_OP_LLVM_call_procedure, 0, DW_OP_stack_value)
!15 = !DILocation(line: 2, column: 1, scope: !10)
!16 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)

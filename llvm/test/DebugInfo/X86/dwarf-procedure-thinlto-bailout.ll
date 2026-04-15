; Test graceful bailout when DW_OP_LLVM_call_procedure references a CU
; whose dwarfProcedures array is null (simulates ThinLTO import where
; IRMover drops the procedure metadata).
;
; RUN: llc -mtriple=x86_64 -dwarf-version=4 -filetype=obj -O0 < %s \
; RUN:   -o %t.o
; RUN: llvm-dwarfdump --debug-info %t.o \
; RUN:   | FileCheck %s
; RUN: llvm-dwarfdump --verify %t.o | FileCheck %s --check-prefix=VERIFY

; VERIFY: No errors.

; The variable "v" should have no location (dropped by ThinLTO bailout)
; or its location should not contain DW_OP_call4 (procedure unavailable).
; CHECK: DW_TAG_variable
; CHECK:   DW_AT_name ("v")
; CHECK-NOT: DW_OP_call4

define void @imported_func(ptr %p) !dbg !10 {
  call void @llvm.dbg.value(metadata ptr %p, metadata !13, metadata !14), !dbg !15
  ret void, !dbg !15
}

declare void @llvm.dbg.value(metadata, metadata, metadata) nounwind readnone

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!8, !9}

; CU with NO dwarfProcedures operand — simulates ThinLTO import.
!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
!1 = !DIFile(filename: "imported.c", directory: "/tmp")
!7 = !DISubroutineType(types: !{null, !11})
!8 = !{i32 2, !"Debug Info Version", i32 3}
!9 = !{i32 2, !"Dwarf Version", i32 4}
!10 = distinct !DISubprogram(name: "imported_func", scope: !1, file: !1, line: 1, type: !7, spFlags: DISPFlagDefinition, unit: !0)
!11 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!13 = !DILocalVariable(name: "v", scope: !10, file: !1, line: 2, type: !16)
; Expression with call_procedure index 0, but CU has no dwarfProcedures.
!14 = !DIExpression(DW_OP_LLVM_call_procedure, 0, DW_OP_stack_value)
!15 = !DILocation(line: 2, column: 1, scope: !10)
!16 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)

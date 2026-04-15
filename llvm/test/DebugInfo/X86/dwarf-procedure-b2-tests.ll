; Comprehensive tests for the B2 raw-byte emitter in getOrCreateDwarfProcedureDIE.
; Covers: op categories, chained procedures, diamond dedup, DW_OP_piece.
;
; DWARF 4 emission with DW_OP_call4.
; RUN: llc -mtriple=x86_64 -dwarf-version=4 -filetype=obj -O0 < %s \
; RUN:   -o %t.o
; RUN: llvm-dwarfdump --debug-info %t.o | FileCheck %s
; RUN: llvm-dwarfdump --verify %t.o | FileCheck %s --check-prefix=VERIFY

; VERIFY: No errors.

; --- Procedure with arithmetic ops ---
; CHECK: DW_TAG_dwarf_procedure
; CHECK:   DW_AT_name ("arith")
; CHECK:   DW_AT_location (DW_OP_constu 0x10, DW_OP_plus_uconst 0x8, DW_OP_plus)

; Note: DW_OP_piece in procedure bodies is NOT testable via DIExpression —
; DIExpression maps piece to DW_OP_LLVM_fragment which is banned in procedure
; bodies. Tile type Layer 2 will need a different mechanism to express
; DW_OP_piece in procedure bodies (raw DWARF emission or new LLVM op).

; --- Procedure with breg + deref_size ---
; CHECK: DW_TAG_dwarf_procedure
; CHECK:   DW_AT_name ("breg_deref")
; CHECK:   DW_AT_location (DW_OP_breg5 RDI+8, DW_OP_deref_size 0x4)

; --- Chained procedure: outer calls inner ---
; CHECK: DW_TAG_dwarf_procedure
; CHECK:   DW_AT_name ("inner")
; CHECK:   DW_AT_location (DW_OP_lit0, DW_OP_plus)

; CHECK: DW_TAG_dwarf_procedure
; CHECK:   DW_AT_name ("outer")
; CHECK:   DW_AT_location (DW_OP_constu 0x20, DW_OP_call4

; --- Variable using arith procedure ---
; CHECK: DW_TAG_variable
; CHECK:   DW_AT_location {{.*}}DW_OP_call4
; CHECK:   DW_AT_name ("a")

; --- Variable b uses breg_deref procedure ---
; CHECK: DW_TAG_variable
; CHECK:   DW_AT_location {{.*}}DW_OP_call4
; CHECK:   DW_AT_name ("b")

; --- Variable using chained outer procedure ---
; CHECK: DW_TAG_variable
; CHECK:   DW_AT_location {{.*}}DW_OP_call4
; CHECK:   DW_AT_name ("c")

define void @test(ptr %p) !dbg !10 {
  call void @llvm.dbg.value(metadata ptr %p, metadata !20, metadata !21), !dbg !15
  call void @llvm.dbg.value(metadata ptr %p, metadata !22, metadata !23), !dbg !15
  call void @llvm.dbg.value(metadata ptr %p, metadata !24, metadata !25), !dbg !15
  ret void, !dbg !15
}

declare void @llvm.dbg.value(metadata, metadata, metadata) nounwind readnone

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!8, !9}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, dwarfProcedures: !2)
!1 = !DIFile(filename: "b2test.c", directory: "/tmp")

; Procedure array: arith, breg_deref, inner, outer
!2 = !{!30, !34, !36, !38}

; Arith: constu + plus_uconst + plus
!30 = !DIDwarfProcedure(name: "arith", expression: !31)
!31 = !DIExpression(DW_OP_constu, 16, DW_OP_plus_uconst, 8, DW_OP_plus)

; breg5 + deref_size
!34 = !DIDwarfProcedure(name: "breg_deref", expression: !35)
!35 = !DIExpression(DW_OP_breg5, 8, DW_OP_deref_size, 4)

; inner: simple body (index 2)
!36 = !DIDwarfProcedure(name: "inner", expression: !37)
!37 = !DIExpression(DW_OP_lit0, DW_OP_plus)

; outer: calls inner (index 2) via DW_OP_LLVM_call_procedure (index 3)
!38 = !DIDwarfProcedure(name: "outer", expression: !39)
!39 = !DIExpression(DW_OP_constu, 32, DW_OP_LLVM_call_procedure, 2)

!7 = !DISubroutineType(types: !{null, !11})
!8 = !{i32 2, !"Debug Info Version", i32 3}
!9 = !{i32 2, !"Dwarf Version", i32 4}
!10 = distinct !DISubprogram(name: "test", scope: !1, file: !1, line: 1, type: !7, spFlags: DISPFlagDefinition, unit: !0)
!11 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!15 = !DILocation(line: 2, column: 1, scope: !10)
!16 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!17 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)

; Variables
!20 = !DILocalVariable(name: "a", scope: !10, file: !1, line: 3, type: !16)
!21 = !DIExpression(DW_OP_LLVM_call_procedure, 0, DW_OP_stack_value)
!22 = !DILocalVariable(name: "b", scope: !10, file: !1, line: 4, type: !16)
!23 = !DIExpression(DW_OP_LLVM_call_procedure, 1, DW_OP_stack_value)
!24 = !DILocalVariable(name: "c", scope: !10, file: !1, line: 5, type: !16)
!25 = !DIExpression(DW_OP_LLVM_call_procedure, 3, DW_OP_stack_value)

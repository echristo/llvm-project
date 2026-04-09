; Test three-level procedure call chain: A calls B, B calls C.
; Models the tile type pattern: composition -> layout -> helper.
;
; DWARF 4: all three procedure DIEs emitted with DW_OP_call4 references.
; RUN: llc -mtriple=x86_64 -dwarf-version=4 -filetype=obj -O0 < %s \
; RUN:   -o - | llvm-dwarfdump - | FileCheck %s --check-prefixes=PROC,CALL4
;
; DWARF 3: all three procedure DIEs emitted.
; RUN: llc -mtriple=x86_64 -dwarf-version=3 -filetype=obj -O0 < %s \
; RUN:   -o - | llvm-dwarfdump - | FileCheck %s --check-prefix=PROC
;
; DWARF 2: no procedure DIEs, all bodies inlined.
; RUN: llc -mtriple=x86_64 -dwarf-version=2 -filetype=obj -O0 < %s \
; RUN:   -o - | llvm-dwarfdump - | FileCheck %s --check-prefix=NOVER
;
; Flag off: no procedure DIEs, three-level chain fully inlined.
; RUN: llc -mtriple=x86_64 -dwarf-version=4 -filetype=obj -O0 \
; RUN:   -use-dwarf-procedures=false < %s -o - | llvm-dwarfdump - \
; RUN:   | FileCheck %s --check-prefix=NOPROC
;
; Verify clean.
; RUN: llc -mtriple=x86_64 -dwarf-version=4 -filetype=obj -O0 < %s \
; RUN:   -o - | llvm-dwarfdump --verify - | FileCheck %s --check-prefix=VERIFY

; VERIFY: No errors.

; -- Procedure C (index 0): leaf helper — multiply by 4.
; PROC: DW_TAG_compile_unit
; PROC:   DW_TAG_dwarf_procedure
; PROC:     DW_AT_name ("helper")
; PROC:     DW_AT_location (DW_OP_constu 0x4, DW_OP_mul)

; -- Procedure B (index 1): layout — calls C, then adds 8.
; PROC:   DW_TAG_dwarf_procedure
; PROC:     DW_AT_name ("layout")
; CALL4:     DW_AT_location ({{.*}}DW_OP_call4{{.*}})

; -- Procedure A (index 2): composition — calls B, then derefs.
; PROC:   DW_TAG_dwarf_procedure
; PROC:     DW_AT_name ("compose")
; CALL4:     DW_AT_location ({{.*}}DW_OP_call4{{.*}})

; -- Variable uses composition procedure (A).
; CALL4:   DW_TAG_variable
; CALL4:     DW_AT_location ({{.*}}DW_OP_call4{{.*}})
; CALL4:     DW_AT_name ("val")

; NOVER-NOT: DW_TAG_dwarf_procedure

; Flag off: fully inlined — C's body, then B's remaining ops, then A's remaining ops.
; NOPROC-NOT: DW_TAG_dwarf_procedure
; NOPROC: DW_TAG_variable
; NOPROC:   DW_AT_location ({{.*}}DW_OP_constu 0x4, DW_OP_mul, DW_OP_plus_uconst 0x8, DW_OP_deref, DW_OP_stack_value)
; NOPROC:   DW_AT_name ("val")

define void @test(ptr %p) !dbg !10 {
  call void @llvm.dbg.value(metadata ptr %p, metadata !16, metadata !17), !dbg !15
  ret void, !dbg !15
}

declare void @llvm.dbg.value(metadata, metadata, metadata) nounwind readnone

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!8, !9}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, dwarfProcedures: !2)
!1 = !DIFile(filename: "test.c", directory: "/tmp")
!2 = !{!3, !5, !20}
; Procedure 0 (C): leaf helper — multiply by 4.
!3 = !DIDwarfProcedure(name: "helper", expression: !4)
!4 = !DIExpression(DW_OP_constu, 4, DW_OP_mul)
; Procedure 1 (B): layout — calls C (index 0), then adds 8.
!5 = !DIDwarfProcedure(name: "layout", expression: !6)
!6 = !DIExpression(DW_OP_LLVM_call_procedure, 0, DW_OP_plus_uconst, 8)
; Procedure 2 (A): composition — calls B (index 1), then derefs.
!20 = !DIDwarfProcedure(name: "compose", expression: !21)
!21 = !DIExpression(DW_OP_LLVM_call_procedure, 1, DW_OP_deref)
!7 = !DISubroutineType(types: !{!11})
!8 = !{i32 2, !"Debug Info Version", i32 3}
!9 = !{i32 2, !"Dwarf Version", i32 4}
!10 = distinct !DISubprogram(name: "test", scope: !1, file: !1, line: 1, type: !7, spFlags: DISPFlagDefinition, unit: !0)
!11 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!15 = !DILocation(line: 2, column: 1, scope: !10)
; Variable uses composition procedure (A, index 2).
!16 = !DILocalVariable(name: "val", scope: !10, file: !1, line: 3, type: !18)
!17 = !DIExpression(DW_OP_LLVM_call_procedure, 2, DW_OP_stack_value)
!18 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)

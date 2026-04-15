; Test DW_OP_call4 resolution in location lists (.debug_loclists).
; This exercises the emitDebugLocEntry resolution path for DW_OP_call4
; that was previously missing (B1 bug fix).
;
; The variable "result" has a DW_OP_LLVM_call_procedure expression
; and lives in different locations across basic blocks, forcing a
; location list instead of a single exprloc.
;
; DWARF 5: location lists in .debug_loclists with DW_OP_call4.
; RUN: llc -mtriple=x86_64 -dwarf-version=5 -filetype=obj -O0 < %s \
; RUN:   -o %t.o
; RUN: llvm-dwarfdump --debug-info --debug-loclists %t.o \
; RUN:   | FileCheck %s --check-prefix=LOCLIST
;
; DWARF 4: verify clean (DWARF 4 avoids the .debug_names issue with
; DW_TAG_dwarf_procedure).
; RUN: llc -mtriple=x86_64 -dwarf-version=4 -filetype=obj -O0 < %s \
; RUN:   -o %t4.o
; RUN: llvm-dwarfdump --verify %t4.o | FileCheck %s --check-prefix=VERIFY
;
; Split DWARF variant.
; RUN: llc -mtriple=x86_64 -dwarf-version=5 -filetype=obj -O0 \
; RUN:   -split-dwarf-file=%t.dwo -split-dwarf-output=%t.dwo < %s \
; RUN:   -o %t.split.o
; RUN: llvm-dwarfdump --debug-info --debug-loclists %t.dwo \
; RUN:   | FileCheck %s --check-prefix=SPLITLOC

; VERIFY: No errors.

; Check that the procedure DIE exists with the expected body.
; LOCLIST: DW_TAG_dwarf_procedure
; LOCLIST:   DW_AT_name ("deref_offset")
; LOCLIST:   DW_AT_location (DW_OP_deref, DW_OP_plus_uconst 0x10, DW_OP_deref)

; Check that "result" has a location list (indexed loclist), not a single
; exprloc, and that at least one entry contains a resolved DW_OP_call4.
; LOCLIST: DW_TAG_variable
; LOCLIST:   DW_AT_location (indexed (0x0) loclist =
; LOCLIST:     DW_OP_call4
; LOCLIST:   DW_AT_name ("result")

; The .debug_loclists section should also show the resolved DW_OP_call4.
; LOCLIST: .debug_loclists contents:
; LOCLIST: DW_OP_call4

; Split DWARF: procedure DIE should be in DWO.
; SPLITLOC: DW_TAG_dwarf_procedure
; SPLITLOC:   DW_AT_name ("deref_offset")

; Split DWARF: location list in .debug_loclists.dwo should have DW_OP_call4.
; SPLITLOC: .debug_loclists.dwo contents:
; SPLITLOC: DW_OP_call4

define i64 @multi_loc(ptr %p) !dbg !10 {
entry:
  call void @llvm.dbg.value(metadata ptr %p, metadata !13, metadata !DIExpression()), !dbg !15
  ; result = call procedure (deref_offset) on p
  call void @llvm.dbg.value(metadata ptr %p, metadata !16, metadata !17), !dbg !15
  %cond = icmp eq ptr %p, null, !dbg !15
  br i1 %cond, label %then, label %else, !dbg !15

then:
  ; In this block, result is described as zero (different location).
  call void @llvm.dbg.value(metadata i64 0, metadata !16, metadata !DIExpression(DW_OP_stack_value)), !dbg !20
  br label %merge, !dbg !20

else:
  ; Here result still uses the procedure.
  call void @llvm.dbg.value(metadata ptr %p, metadata !16, metadata !17), !dbg !21
  br label %merge, !dbg !21

merge:
  %r = phi i64 [ 0, %then ], [ 1, %else ]
  call void @llvm.dbg.value(metadata i64 %r, metadata !16, metadata !DIExpression(DW_OP_stack_value)), !dbg !22
  ret i64 %r, !dbg !22
}

declare void @llvm.dbg.value(metadata, metadata, metadata) nounwind readnone

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!8, !9}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, dwarfProcedures: !2)
!1 = !DIFile(filename: "loclist.c", directory: "/tmp")
!2 = !{!3}
!3 = !DIDwarfProcedure(name: "deref_offset", expression: !4)
!4 = !DIExpression(DW_OP_deref, DW_OP_plus_uconst, 16, DW_OP_deref)
!7 = !DISubroutineType(types: !{!18, !11})
!8 = !{i32 2, !"Debug Info Version", i32 3}
!9 = !{i32 2, !"Dwarf Version", i32 5}
!10 = distinct !DISubprogram(name: "multi_loc", scope: !1, file: !1, line: 1, type: !7, spFlags: DISPFlagDefinition, unit: !0)
!11 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
!13 = !DILocalVariable(name: "p", arg: 1, scope: !10, file: !1, line: 1, type: !11)
!15 = !DILocation(line: 2, column: 1, scope: !10)
!16 = !DILocalVariable(name: "result", scope: !10, file: !1, line: 3, type: !18)
!17 = !DIExpression(DW_OP_LLVM_call_procedure, 0, DW_OP_stack_value)
!18 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
!20 = !DILocation(line: 5, column: 1, scope: !10)
!21 = !DILocation(line: 7, column: 1, scope: !10)
!22 = !DILocation(line: 9, column: 1, scope: !10)

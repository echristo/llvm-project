; Test that a DWARF procedure whose body calls another procedure emits
; correctly: DW_OP_call4 in A's body references B's DIE at DWARF 3+,
; and B's body is inlined into A's at DWARF 2 / flag-off.
;
; DWARF 4: both procedure DIEs emitted, A's body contains DW_OP_call4.
; RUN: llc -mtriple=x86_64 -dwarf-version=4 -filetype=obj -O0 < %s \
; RUN:   -o - | llvm-dwarfdump - | FileCheck %s --check-prefixes=PROC,CALL4
;
; DWARF 3: both procedure DIEs emitted.
; RUN: llc -mtriple=x86_64 -dwarf-version=3 -filetype=obj -O0 < %s \
; RUN:   -o - | llvm-dwarfdump - | FileCheck %s --check-prefix=PROC
;
; DWARF 2: no procedure DIEs (version gate), bodies inlined.
; RUN: llc -mtriple=x86_64 -dwarf-version=2 -filetype=obj -O0 < %s \
; RUN:   -o - | llvm-dwarfdump - | FileCheck %s --check-prefix=NOVER
;
; Flag off: no procedure DIEs, nested body fully inlined.
; RUN: llc -mtriple=x86_64 -dwarf-version=4 -filetype=obj -O0 \
; RUN:   -use-dwarf-procedures=false < %s -o - | llvm-dwarfdump - \
; RUN:   | FileCheck %s --check-prefix=NOPROC
;
; Verify clean: no errors from llvm-dwarfdump --verify.
; RUN: llc -mtriple=x86_64 -dwarf-version=4 -filetype=obj -O0 < %s \
; RUN:   -o - | llvm-dwarfdump --verify - | FileCheck %s --check-prefix=VERIFY

; VERIFY: No errors.

; -- Procedure DIEs appear first under the CU, before the subprogram.

; -- Callee procedure (B): leaf, deref + offset.
; PROC: DW_TAG_compile_unit
; PROC:   DW_TAG_dwarf_procedure
; PROC:     DW_AT_name ("deref_offset")
; PROC:     DW_AT_location (DW_OP_deref, DW_OP_plus_uconst 0x10)

; -- Caller procedure (A): calls B then adds a constant.
; PROC:   DW_TAG_dwarf_procedure
; PROC:     DW_AT_name ("caller")
; CALL4:     DW_AT_location ({{.*}}DW_OP_call4{{.*}})

; -- Procedure that calls TWO procedures in sequence (multi-call).
; PROC:   DW_TAG_dwarf_procedure
; PROC:     DW_AT_name ("multi_caller")
; CALL4:     DW_AT_location ({{.*}}DW_OP_call4{{.*}}DW_OP_call4{{.*}})

; -- Variables appear inside the subprogram, after procedure DIEs.

; -- Variable uses caller procedure (A) via DW_OP_call4.
; CALL4:   DW_TAG_variable
; CALL4:     DW_AT_location ({{.*}}DW_OP_call4{{.*}})
; CALL4:     DW_AT_name ("result")

; -- Variable using the multi-call procedure.
; CALL4:   DW_TAG_variable
; CALL4:     DW_AT_location ({{.*}}DW_OP_call4{{.*}})
; CALL4:     DW_AT_name ("multi_result")

; NOVER-NOT: DW_TAG_dwarf_procedure

; Flag off: body of B inlined into A, then A inlined into variable.
; NOPROC-NOT: DW_TAG_dwarf_procedure
; NOPROC: DW_TAG_variable
; NOPROC:   DW_AT_location ({{.*}}DW_OP_deref, DW_OP_plus_uconst 0x10, DW_OP_constu 0x2a, DW_OP_plus, DW_OP_stack_value)
; NOPROC:   DW_AT_name ("result")

; Flag off: multi-call procedure bodies both inlined sequentially.
; NOPROC: DW_TAG_variable
; NOPROC:   DW_AT_location ({{.*}}DW_OP_deref, DW_OP_plus_uconst 0x10, DW_OP_constu 0x2a, DW_OP_plus, DW_OP_stack_value)
; NOPROC:   DW_AT_name ("multi_result")

define void @test(ptr %p) !dbg !10 {
  call void @llvm.dbg.value(metadata ptr %p, metadata !16, metadata !17), !dbg !15
  call void @llvm.dbg.value(metadata ptr %p, metadata !24, metadata !25), !dbg !15
  ret void, !dbg !15
}

declare void @llvm.dbg.value(metadata, metadata, metadata) nounwind readnone

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!8, !9}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, dwarfProcedures: !2)
!1 = !DIFile(filename: "test.c", directory: "/tmp")
!2 = !{!3, !5, !20}
; Procedure 0 (B): leaf — deref + offset.
!3 = !DIDwarfProcedure(name: "deref_offset", expression: !4)
!4 = !DIExpression(DW_OP_deref, DW_OP_plus_uconst, 16)
; Procedure 1 (A): calls procedure 0 (B), then adds 42.
!5 = !DIDwarfProcedure(name: "caller", expression: !6)
!6 = !DIExpression(DW_OP_LLVM_call_procedure, 0, DW_OP_constu, 42, DW_OP_plus)
!7 = !DISubroutineType(types: !{!11})
!8 = !{i32 2, !"Debug Info Version", i32 3}
!9 = !{i32 2, !"Dwarf Version", i32 4}
!10 = distinct !DISubprogram(name: "test", scope: !1, file: !1, line: 1, type: !7, spFlags: DISPFlagDefinition, unit: !0)
!11 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
; Variable that calls the caller procedure (A, index 1).
!15 = !DILocation(line: 2, column: 1, scope: !10)
!16 = !DILocalVariable(name: "result", scope: !10, file: !1, line: 3, type: !18)
!17 = !DIExpression(DW_OP_LLVM_call_procedure, 1, DW_OP_stack_value)
!18 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
; Procedure 2 (multi_caller): calls both B (index 0) and A (index 1) in sequence.
!20 = !DIDwarfProcedure(name: "multi_caller", expression: !21)
!21 = !DIExpression(DW_OP_LLVM_call_procedure, 0, DW_OP_LLVM_call_procedure, 1)
; Variable that uses multi_caller (index 2).
!24 = !DILocalVariable(name: "multi_result", scope: !10, file: !1, line: 4, type: !18)
!25 = !DIExpression(DW_OP_LLVM_call_procedure, 2, DW_OP_stack_value)

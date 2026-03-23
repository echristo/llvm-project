; Test DW_TAG_dwarf_procedure emission from IR metadata nodes, and
; DW_OP_LLVM_call_procedure referencing them from variable locations.
;
; Models a scenario where a frontend knows that accessing a container's
; size field requires dereferencing through an implementation pointer
; (offset 16) and reading a size_t (offset 8 from there). The procedure
; body captures this reusable access pattern. A local variable "x" with
; a real register location exists alongside the procedure to exercise
; coexistence with normal debug info. A second variable "size" uses
; DW_OP_LLVM_call_procedure to call the container_size procedure.
;
; DWARF 4: procedure DIEs emitted, variable references via DW_OP_call4.
; RUN: llc -mtriple=x86_64 -dwarf-version=4 -filetype=obj -O0 < %s \
; RUN:   -o - | llvm-dwarfdump - | FileCheck %s --check-prefixes=PROC,CALL4
;
; DWARF 3: procedure DIEs emitted.
; RUN: llc -mtriple=x86_64 -dwarf-version=3 -filetype=obj -O0 < %s \
; RUN:   -o - | llvm-dwarfdump - | FileCheck %s --check-prefix=PROC
;
; DWARF 2: no procedure DIEs (version gate).
; RUN: llc -mtriple=x86_64 -dwarf-version=2 -filetype=obj -O0 < %s \
; RUN:   -o - | llvm-dwarfdump - | FileCheck %s --check-prefix=NOVER
;
; Flag off: no procedure DIEs, call_procedure body inlined.
; RUN: llc -mtriple=x86_64 -dwarf-version=4 -filetype=obj -O0 \
; RUN:   -use-dwarf-procedures=false < %s -o - | llvm-dwarfdump - \
; RUN:   | FileCheck %s --check-prefix=NOPROC
;
; Verify clean: no errors from llvm-dwarfdump --verify.
; RUN: llc -mtriple=x86_64 -dwarf-version=4 -filetype=obj -O0 < %s \
; RUN:   -o - | llvm-dwarfdump --verify - | FileCheck %s --check-prefix=VERIFY

; VERIFY: No errors.

; -- Named procedure: multi-op body with ULEB128-encoded arguments.
; PROC: DW_TAG_compile_unit
; PROC:   DW_TAG_dwarf_procedure
; PROC:     DW_AT_name ("container_size")
; PROC:     DW_AT_location (DW_OP_deref, DW_OP_plus_uconst 0x10, DW_OP_deref, DW_OP_plus_uconst 0x8, DW_OP_deref)

; -- Anonymous procedure: single-op body.
; PROC:   DW_TAG_dwarf_procedure
; PROC-NOT: DW_AT_name
; PROC:     DW_AT_location (DW_OP_lit0)

; -- Procedure with breg and deref_size: tests SLEB128 and 1-byte arg encoding.
; PROC:   DW_TAG_dwarf_procedure
; PROC:     DW_AT_name ("field_access")
; PROC:     DW_AT_location (DW_OP_breg5 RDI+16, DW_OP_deref_size 0x4)

; -- Variable "x" gets a normal location alongside procedures.
; PROC:   DW_TAG_subprogram
; PROC:     DW_AT_name ("test")
; PROC:     DW_TAG_formal_parameter
; PROC:       DW_AT_location
; PROC:       DW_AT_name ("x")

; -- Variable "size" uses DW_OP_call4 to reference the procedure (DWARF 4).
; CALL4:     DW_TAG_variable
; CALL4:       DW_AT_location {{.*}}DW_OP_call4
; CALL4:       DW_AT_name ("size")

; -- Variable "field" also references a procedure via DW_OP_call4 (DWARF 4).
; CALL4:     DW_TAG_variable
; CALL4:       DW_AT_location {{.*}}DW_OP_call4
; CALL4:       DW_AT_name ("field")

; NOVER-NOT: DW_TAG_dwarf_procedure

; Flag off (DWARF 4): body inlined into the variable's location.
; NOPROC-NOT: DW_TAG_dwarf_procedure
; NOPROC: DW_TAG_variable
; NOPROC:   DW_AT_location ({{.*}}DW_OP_deref, DW_OP_plus_uconst 0x10, DW_OP_deref, DW_OP_plus_uconst 0x8, DW_OP_deref, DW_OP_stack_value)
; NOPROC:   DW_AT_name ("size")

; Flag off: field variable inlines breg+deref_size body.
; NOPROC: DW_TAG_variable
; NOPROC:   DW_AT_location ({{.*}}DW_OP_breg5 RDI+16, DW_OP_deref_size 0x4, DW_OP_stack_value)
; NOPROC:   DW_AT_name ("field")

define void @test(ptr %p) !dbg !10 {
  call void @llvm.dbg.value(metadata ptr %p, metadata !13, metadata !DIExpression()), !dbg !15
  call void @llvm.dbg.value(metadata ptr %p, metadata !16, metadata !17), !dbg !15
  call void @llvm.dbg.value(metadata ptr %p, metadata !21, metadata !22), !dbg !15
  ret void, !dbg !15
}

declare void @llvm.dbg.value(metadata, metadata, metadata) nounwind readnone

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!8, !9}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, dwarfProcedures: !2)
!1 = !DIFile(filename: "test.c", directory: "/tmp")
!2 = !{!3, !5, !19}
; Procedure body: deref impl pointer at offset 16, then read size at offset 8.
!3 = !DIDwarfProcedure(name: "container_size", expression: !4)
!4 = !DIExpression(DW_OP_deref, DW_OP_plus_uconst, 16, DW_OP_deref, DW_OP_plus_uconst, 8, DW_OP_deref)
; Trivial procedure: push zero.
!5 = !DIDwarfProcedure(expression: !6)
!6 = !DIExpression(DW_OP_lit0)
!7 = !DISubroutineType(types: !{!11})
!8 = !{i32 2, !"Debug Info Version", i32 3}
!9 = !{i32 2, !"Dwarf Version", i32 4}
!10 = distinct !DISubprogram(name: "test", scope: !1, file: !1, line: 1, type: !7, spFlags: DISPFlagDefinition, unit: !0)
!11 = !DIDerivedType(tag: DW_TAG_pointer_type, baseType: null, size: 64)
; Function parameter with a real location.
!13 = !DILocalVariable(name: "x", arg: 1, scope: !10, file: !1, line: 1, type: !11)
!15 = !DILocation(line: 2, column: 1, scope: !10)
; Variable that calls the container_size procedure via DW_OP_LLVM_call_procedure.
!16 = !DILocalVariable(name: "size", scope: !10, file: !1, line: 3, type: !18)
!17 = !DIExpression(DW_OP_LLVM_call_procedure, 0, DW_OP_stack_value)
!18 = !DIBasicType(name: "long", size: 64, encoding: DW_ATE_signed)
; Procedure with breg and deref_size: exercises SLEB128 and 1-byte arg encoding.
!19 = !DIDwarfProcedure(name: "field_access", expression: !20)
!20 = !DIExpression(DW_OP_breg5, 16, DW_OP_deref_size, 4)
; Variable that calls the field_access procedure (index 2).
!21 = !DILocalVariable(name: "field", scope: !10, file: !1, line: 4, type: !23)
!22 = !DIExpression(DW_OP_LLVM_call_procedure, 2, DW_OP_stack_value)
!23 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)

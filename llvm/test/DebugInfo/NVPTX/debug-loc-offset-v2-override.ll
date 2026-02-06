; RUN: llc -mtriple=nvptx64-nvidia-cuda -mattr=+ptx70 -dwarf-version=2 < %s | FileCheck %s

; Test that -dwarf-version=2 flag overrides the DWARF v4 specified in metadata.
; This verifies that location expressions in DWARF v2 do not include DW_OP_stack_value.

; CHECK: 	.section	.debug_loc
; CHECK-NEXT: 	{
; CHECK-NEXT: $L__debug_loc0:
; CHECK-NEXT: .b64 $L__func_begin0
; CHECK-NEXT: .b64 $L__tmp0
; CHECK-NEXT: .b8 2                                   // Loc expr size
; CHECK-NEXT: .b8 0
; CHECK-NEXT: .b8 17                                  // DW_OP_consts
; CHECK-NEXT: .b8 0                                   // 0
; CHECK-NEXT: .b64 $L__tmp0
; CHECK-NEXT: .b64 $L__func_end0
; CHECK-NEXT: .b8 2                                   // Loc expr size
; CHECK-NEXT: .b8 0
; CHECK-NEXT: .b8 17                                  // DW_OP_consts
; CHECK-NEXT: .b8 1                                   // 1

%struct.A = type { ptr, i32 }

define i32 @_Z3bari(i32 %b) #0 !dbg !4 {
entry:
  %b.addr = alloca i32, align 4
  store i32 %b, ptr %b.addr, align 4
  call void @llvm.dbg.value(metadata i32 0, metadata !21, metadata !DIExpression()), !dbg !22
  %0 = load i32, ptr %b.addr, align 4, !dbg !23
  call void @llvm.dbg.value(metadata i32 1, metadata !21, metadata !DIExpression()), !dbg !22
  %add = add nsw i32 %0, 4, !dbg !23
  ret i32 %add, !dbg !23
}

declare void @llvm.dbg.value(metadata, metadata, metadata) #1

attributes #0 = { nounwind }
attributes #1 = { nounwind readnone }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!18, !19}
!llvm.ident = !{!20}

!0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, producer: "clang version 3.5.0 (210479)", isOptimized: false, emissionKind: FullDebug, file: !1, enums: !2, retainedTypes: !2, globals: !2, imports: !2, nameTableKind: None)
!1 = !DIFile(filename: "debug-loc-offset1.cc", directory: "/llvm_cmake_gcc")
!2 = !{}
!4 = distinct !DISubprogram(name: "bar", linkageName: "_Z3bari", line: 1, isLocal: false, isDefinition: true, virtualIndex: 6, flags: DIFlagPrototyped, isOptimized: false, unit: !0, scopeLine: 1, file: !1, scope: !5, type: !6, retainedNodes: !35)
!5 = !DIFile(filename: "debug-loc-offset1.cc", directory: "/llvm_cmake_gcc")
!6 = !DISubroutineType(types: !7)
!7 = !{!8, !8}
!8 = !DIBasicType(tag: DW_TAG_base_type, name: "int", size: 32, align: 32, encoding: DW_ATE_signed)
!18 = !{i32 2, !"Dwarf Version", i32 4}
!19 = !{i32 2, !"Debug Info Version", i32 3}
!20 = !{!"clang version 3.5.0 (210479)"}
!21 = !DILocalVariable(name: "b", line: 1, arg: 1, scope: !4, file: !5, type: !8)
!22 = !DILocation(line: 1, scope: !4)
!23 = !DILocation(line: 2, scope: !4)
!35 = !{!21}

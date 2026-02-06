; RUN: llc -mtriple=nvptx64-nvidia-cuda -mattr=+ptx70 < %s | FileCheck %s --check-prefix=V2
; RUN: llc -mtriple=nvptx64-nvidia-cuda -mattr=+ptx70 -dwarf-version=2 < %s | FileCheck %s --check-prefix=V2
; RUN: llc -mtriple=nvptx64-nvidia-cuda -mattr=+ptx70 -dwarf-version=3 < %s | FileCheck %s --check-prefix=V3
; RUN: llc -mtriple=nvptx64-nvidia-cuda -mattr=+ptx70 -dwarf-version=4 < %s | FileCheck %s --check-prefix=V4
; RUN: llc -mtriple=nvptx64-nvidia-cuda -mattr=+ptx70 -dwarf-version=5 < %s | FileCheck %s --check-prefix=V5
; RUN: %if ptxas-isa-7.0 %{ llc -mtriple=nvptx64-nvidia-cuda < %s -mattr=+ptx70 | %ptxas-verify %}

; V2: .target sm_{{[0-9]+}}, debug
; V3: .target sm_{{[0-9]+}}, debug
; V4: .target sm_{{[0-9]+}}, debug
; V5: .target sm_{{[0-9]+}}, debug

%struct.A = type { ptr, i32 }

; Function Attrs: nounwind
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

; Function Attrs: nounwind readnone
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

declare void @llvm.dbg.value(metadata, metadata, metadata) #1

define void @_Z3baz1A(ptr %a) #2 !dbg !14 {
entry:
  %z = alloca i32, align 4
  call void @llvm.dbg.declare(metadata ptr %a, metadata !24, metadata !DIExpression(DW_OP_deref)), !dbg !25
  call void @llvm.dbg.declare(metadata ptr %z, metadata !26, metadata !DIExpression()), !dbg !27
  store i32 2, ptr %z, align 4, !dbg !27
  %var = getelementptr inbounds %struct.A, ptr %a, i32 0, i32 1, !dbg !28
  %0 = load i32, ptr %var, align 4, !dbg !28
  %cmp = icmp sgt i32 %0, 2, !dbg !28
  br i1 %cmp, label %if.then, label %if.end, !dbg !28

if.then:                                          ; preds = %entry
  %1 = load i32, ptr %z, align 4, !dbg !30
  %inc = add nsw i32 %1, 1, !dbg !30
  store i32 %inc, ptr %z, align 4, !dbg !30
  br label %if.end, !dbg !30

if.end:                                           ; preds = %if.then, %entry
  %call = call signext i8 @_ZN1A3fooEv(ptr %a), !dbg !31
  %conv = sext i8 %call to i32, !dbg !31
  %cmp1 = icmp eq i32 %conv, 97, !dbg !31
  br i1 %cmp1, label %if.then2, label %if.end4, !dbg !31

if.then2:                                         ; preds = %if.end
  %2 = load i32, ptr %z, align 4, !dbg !33
  %inc3 = add nsw i32 %2, 1, !dbg !33
  store i32 %inc3, ptr %z, align 4, !dbg !33
  br label %if.end4, !dbg !33

if.end4:                                          ; preds = %if.then2, %if.end
  ret void, !dbg !34
}

declare signext i8 @_ZN1A3fooEv(ptr) #2

attributes #0 = { nounwind "less-precise-fpmad"="false" "frame-pointer"="all" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "use-soft-float"="false" }
attributes #1 = { nounwind readnone }
attributes #2 = { "less-precise-fpmad"="false" "frame-pointer"="all" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "stack-protector-buffer-size"="8" "use-soft-float"="false" }

!llvm.dbg.cu = !{!0, !9}
!llvm.module.flags = !{!18, !19}
!llvm.ident = !{!20, !20}

!0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, producer: "clang version 3.5.0 (210479)", isOptimized: false, emissionKind: FullDebug, file: !1, enums: !2, retainedTypes: !2, globals: !2, imports: !2, nameTableKind: None)
!1 = !DIFile(filename: "debug-loc-offset1.cc", directory: "/llvm_cmake_gcc")
!2 = !{}
!4 = distinct !DISubprogram(name: "bar", linkageName: "_Z3bari", line: 1, isLocal: false, isDefinition: true, virtualIndex: 6, flags: DIFlagPrototyped, isOptimized: false, unit: !0, scopeLine: 1, file: !1, scope: !5, type: !6, retainedNodes: !35)
!5 = !DIFile(filename: "debug-loc-offset1.cc", directory: "/llvm_cmake_gcc")
!6 = !DISubroutineType(types: !7)
!7 = !{!8, !8}
!8 = !DIBasicType(tag: DW_TAG_base_type, name: "int", size: 32, align: 32, encoding: DW_ATE_signed)
!9 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus, producer: "clang version 3.5.0 (210479)", isOptimized: false, emissionKind: FullDebug, file: !10, enums: !2, retainedTypes: !11, globals: !2, imports: !2, nameTableKind: None)
!10 = !DIFile(filename: "debug-loc-offset2.cc", directory: "/llvm_cmake_gcc")
!11 = !{!12}
!12 = !DICompositeType(tag: DW_TAG_structure_type, name: "A", line: 1, flags: DIFlagFwdDecl, file: !10, identifier: "_ZTS1A")
!14 = distinct !DISubprogram(name: "baz", linkageName: "_Z3baz1A", line: 6, isLocal: false, isDefinition: true, virtualIndex: 6, flags: DIFlagPrototyped, isOptimized: false, unit: !9, scopeLine: 6, file: !10, scope: !15, type: !16, retainedNodes: !36)
!15 = !DIFile(filename: "debug-loc-offset2.cc", directory: "/llvm_cmake_gcc")
!16 = !DISubroutineType(types: !17)
!17 = !{null, !12}
!18 = !{i32 2, !"Dwarf Version", i32 2}
!19 = !{i32 2, !"Debug Info Version", i32 3}
!20 = !{!"clang version 3.5.0 (210479)"}
!21 = !DILocalVariable(name: "b", line: 1, arg: 1, scope: !4, file: !5, type: !8)
!22 = !DILocation(line: 1, scope: !4)
!23 = !DILocation(line: 2, scope: !4)
!24 = !DILocalVariable(name: "a", line: 6, arg: 1, scope: !14, file: !15, type: !12)
!25 = !DILocation(line: 6, scope: !14)
!26 = !DILocalVariable(name: "z", line: 7, scope: !14, file: !15, type: !8)
!27 = !DILocation(line: 7, scope: !14)
!28 = !DILocation(line: 8, scope: !29)
!29 = distinct !DILexicalBlock(line: 8, column: 0, file: !10, scope: !14)
!30 = !DILocation(line: 9, scope: !29)
!31 = !DILocation(line: 10, scope: !32)
!32 = distinct !DILexicalBlock(line: 10, column: 0, file: !10, scope: !14)
!33 = !DILocation(line: 11, scope: !32)
!34 = !DILocation(line: 12, scope: !14)
!35 = !{!21}
!36 = !{!24, !26}

; V2: 	.section	.debug_loc
; V2-NEXT: 	{
; V2-NEXT: $L__debug_loc0:
; V2-NEXT: .b64 $L__func_begin0
; V2-NEXT: .b64 $L__tmp0
; V2-NEXT: .b8 2                                   // Loc expr size
; V2-NEXT: .b8 0
; V2-NEXT: .b8 17                                  // DW_OP_consts
; V2-NEXT: .b8 0                                   // 0
; V2-NEXT: .b64 $L__tmp0
; V2-NEXT: .b64 $L__func_end0
; V2-NEXT: .b8 2                                   // Loc expr size
; V2-NEXT: .b8 0
; V2-NEXT: .b8 17                                  // DW_OP_consts
; V2-NEXT: .b8 1                                   // 1

; V3: 	.section	.debug_loc
; V3-NEXT: 	{
; V3-NEXT: $L__debug_loc0:
; V3-NEXT: .b64 $L__func_begin0
; V3-NEXT: .b64 $L__tmp0
; V3-NEXT: .b8 2                                   // Loc expr size
; V3-NEXT: .b8 0
; V3-NEXT: .b8 17                                  // DW_OP_consts
; V3-NEXT: .b8 0                                   // 0
; V3-NEXT: .b64 $L__tmp0
; V3-NEXT: .b64 $L__func_end0
; V3-NEXT: .b8 2                                   // Loc expr size
; V3-NEXT: .b8 0
; V3-NEXT: .b8 17                                  // DW_OP_consts
; V3-NEXT: .b8 1                                   // 1

; V4: 	.section	.debug_loc
; V4-NEXT: 	{
; V4-NEXT: $L__debug_loc0:
; V4-NEXT: .b64 $L__func_begin0
; V4-NEXT: .b64 $L__tmp0
; V4-NEXT: .b8 3                                   // Loc expr size
; V4-NEXT: .b8 0
; V4-NEXT: .b8 17                                  // DW_OP_consts
; V4-NEXT: .b8 0                                   // 0
; V4-NEXT: .b8 159                                 // DW_OP_stack_value
; V4-NEXT: .b64 $L__tmp0
; V4-NEXT: .b64 $L__func_end0
; V4-NEXT: .b8 3                                   // Loc expr size
; V4-NEXT: .b8 0
; V4-NEXT: .b8 17                                  // DW_OP_consts
; V4-NEXT: .b8 1                                   // 1
; V4-NEXT: .b8 159                                 // DW_OP_stack_value

; V5: $L__debug_loc0:
; V5-NEXT: .b8 3                                   // DW_LLE_startx_length
; V5-NEXT: .b8 0                                   //   start index
; V5-NEXT: 	.uleb128 $L__tmp0-$L__func_begin0       //   length
; V5-NEXT: .b8 3                                   // Loc expr size
; V5-NEXT: .b8 17                                  // DW_OP_consts
; V5-NEXT: .b8 0                                   // 0
; V5-NEXT: .b8 159                                 // DW_OP_stack_value
; V5-NEXT: .b8 3                                   // DW_LLE_startx_length
; V5-NEXT: .b8 2                                   //   start index
; V5-NEXT: 	.uleb128 $L__func_end0-$L__tmp0         //   length
; V5-NEXT: .b8 3                                   // Loc expr size
; V5-NEXT: .b8 17                                  // DW_OP_consts
; V5-NEXT: .b8 1                                   // 1
; V5-NEXT: .b8 159                                 // DW_OP_stack_value
; V5-NEXT: .b8 0                                   // DW_LLE_end_of_list

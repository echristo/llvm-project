; Verify that NVPTX defaults to DWARF v2 but respects -dwarf-version overrides.

; RUN: llc -mtriple=nvptx64-nvidia-cuda < %s | FileCheck %s --check-prefix=DWARF2
; RUN: llc -mtriple=nvptx-nvidia-cuda < %s | FileCheck %s --check-prefix=DWARF2
; RUN: llc -mtriple=nvptx64-nvidia-cuda -dwarf-version=4 < %s | FileCheck %s --check-prefix=DWARF4
; RUN: llc -mtriple=nvptx64-nvidia-cuda -dwarf-version=5 < %s | FileCheck %s --check-prefix=DWARF5

; DWARF2: .b8 2 // DWARF version number
; DWARF4: .b8 4 // DWARF version number
; DWARF5: .b8 5 // DWARF version number

define i32 @foo() !dbg !4 {
entry:
  ret i32 0
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!7, !8}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, producer: "clang version test", isOptimized: false, emissionKind: FullDebug, file: !1, enums: !2, globals: !2)
!1 = !DIFile(filename: "test.c", directory: "/tmp")
!2 = !{}
!4 = distinct !DISubprogram(name: "foo", line: 1, isLocal: false, isDefinition: true, unit: !0, scopeLine: 1, file: !1, scope: !1, type: !5)
!5 = !DISubroutineType(types: !6)
!6 = !{!9}
!7 = !{i32 2, !"Dwarf Version", i32 2}
!8 = !{i32 2, !"Debug Info Version", i32 3}
!9 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)

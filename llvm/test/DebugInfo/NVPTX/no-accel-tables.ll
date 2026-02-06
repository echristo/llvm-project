; Verify that accelerator tables and pub sections are not emitted for
; NVPTX targets.

; Configurations that would emit .debug_names without the NVPTX guard:
; RUN: llc -mtriple=nvptx64-nvidia-cuda -dwarf-version=5 < %s | FileCheck %s
; RUN: llc -mtriple=nvptx64-nvidia-cuda -debugger-tune=lldb < %s | FileCheck %s
; RUN: llc -mtriple=nvptx-nvidia-cuda -dwarf-version=5 < %s | FileCheck %s
; RUN: llc -mtriple=nvptx-nvidia-cuda -debugger-tune=lldb < %s | FileCheck %s

; Configurations that would emit .debug_pubnames/.debug_pubtypes without
; the NVPTX guard (default is GDB tuning with DWARF v2):
; RUN: llc -mtriple=nvptx64-nvidia-cuda < %s | FileCheck %s
; RUN: llc -mtriple=nvptx-nvidia-cuda < %s | FileCheck %s

; Configurations that would emit .debug_gnu_pubnames/.debug_gnu_pubtypes
; without the NVPTX guard (explicit GNU name table):
; RUN: sed 's/emissionKind: FullDebug/emissionKind: FullDebug, nameTableKind: GNU/' %s \
; RUN:   | llc -mtriple=nvptx64-nvidia-cuda | FileCheck %s
; RUN: sed 's/emissionKind: FullDebug/emissionKind: FullDebug, nameTableKind: GNU/' %s \
; RUN:   | llc -mtriple=nvptx-nvidia-cuda | FileCheck %s

; CHECK-NOT: .section .debug_names
; CHECK-NOT: .section .debug_pubnames
; CHECK-NOT: .section .debug_pubtypes
; CHECK-NOT: .section .debug_gnu_pubnames
; CHECK-NOT: .section .debug_gnu_pubtypes
; CHECK-NOT: .section .apple_names
; CHECK-NOT: .section .apple_types
; CHECK-NOT: .section .apple_namespaces
; CHECK-NOT: .section .apple_objc

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

; RUN: not llvm-as -disable-output %s 2>&1 | FileCheck %s

; CHECK: missing required field 'expression'
!0 = !DIDwarfProcedure(name: "bad")

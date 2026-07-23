; Check that metadata-free DIExpressions retain the version 3 bitcode layout.
;
; RUN: llvm-as < %s | llvm-bcanalyzer -dump | FileCheck %s

!expressions = !{!0}
!0 = !DIExpression(DW_OP_lit0)

; CHECK: <EXPRESSION op0=6 op1=48/>

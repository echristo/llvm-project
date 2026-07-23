set(LLVM_LINK_COMPONENTS Core)

add_mlir_unittest(MLIRDebugImporterTests
  DebugImporterTest.cpp
)

mlir_target_link_libraries(MLIRDebugImporterTests
  PRIVATE
  MLIRLLVMDialect
  MLIRTargetLLVMIRImport
)

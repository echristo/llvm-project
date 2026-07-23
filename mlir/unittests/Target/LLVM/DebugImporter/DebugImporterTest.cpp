//===- DebugImporterTest.cpp ----------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "../../../../lib/Target/LLVMIR/DebugImporter.h"
#include "mlir/Dialect/LLVMIR/LLVMDialect.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/OwningOpRef.h"
#include "llvm/BinaryFormat/Dwarf.h"
#include "llvm/IR/DebugInfoMetadata.h"
#include "llvm/IR/LLVMContext.h"
#include "gtest/gtest.h"

using namespace mlir;

namespace {

static llvm::DIExpression *
getExpressionWithMetadataOperands(llvm::LLVMContext &context) {
  llvm::Metadata *rawOperand = llvm::MDString::get(context, "raw operand");
  return llvm::DIExpression::get(context, {llvm::dwarf::DW_OP_lit0},
                                 llvm::ArrayRef<llvm::Metadata *>{rawOperand});
}

static void expectImportFailure(llvm::DINode *node) {
  MLIRContext Context;
  Context.loadDialect<LLVM::LLVMDialect>();
  OwningOpRef<ModuleOp> Module = ModuleOp::create(UnknownLoc::get(&Context));
  LLVM::detail::DebugImporter Importer(*Module,
                                       /*dropDICompositeTypeElements=*/false);

  EXPECT_FALSE(Importer.translate(node));
}

TEST(DebugImporterTest, DIExpressionMetadataOperandsAreUnsupported) {
  MLIRContext Context;
  Context.loadDialect<LLVM::LLVMDialect>();
  OwningOpRef<ModuleOp> Module = ModuleOp::create(UnknownLoc::get(&Context));
  LLVM::detail::DebugImporter Importer(*Module,
                                       /*dropDICompositeTypeElements=*/false);

  llvm::LLVMContext LLVMContext;
  auto *Expression = getExpressionWithMetadataOperands(LLVMContext);

  EXPECT_FALSE(Importer.translateExpression(Expression));
}

TEST(DebugImporterTest, DIExpressionMetadataOperandsInTypeSizeAreUnsupported) {
  llvm::LLVMContext LLVMContext;
  auto *Expression = getExpressionWithMetadataOperands(LLVMContext);
  auto *Type = llvm::DIBasicType::get(
      LLVMContext, llvm::dwarf::DW_TAG_base_type,
      llvm::MDString::get(LLVMContext, "int"), Expression, 0,
      llvm::dwarf::DW_ATE_signed, 0, 0, llvm::DINode::FlagZero);

  expectImportFailure(Type);
}

TEST(DebugImporterTest,
     DIExpressionMetadataOperandsInCompositeSizeAreUnsupported) {
  llvm::LLVMContext LLVMContext;
  auto *Expression = getExpressionWithMetadataOperands(LLVMContext);
  auto *Type = llvm::DICompositeType::get(
      LLVMContext, llvm::dwarf::DW_TAG_structure_type, "", nullptr, 0, nullptr,
      nullptr, Expression, 0, nullptr, llvm::DINode::FlagZero, nullptr, 0,
      std::nullopt, nullptr);

  expectImportFailure(Type);
}

TEST(DebugImporterTest,
     DIExpressionMetadataOperandsInDerivedSizeAreUnsupported) {
  llvm::LLVMContext LLVMContext;
  auto *Expression = getExpressionWithMetadataOperands(LLVMContext);
  auto *Type = llvm::DIDerivedType::get(
      LLVMContext, llvm::dwarf::DW_TAG_pointer_type, "", nullptr, 0, nullptr,
      nullptr, Expression, 0, nullptr, std::nullopt, std::nullopt,
      llvm::DINode::FlagZero);

  expectImportFailure(Type);
}

TEST(DebugImporterTest,
     DIExpressionMetadataOperandsInDerivedOffsetAreUnsupported) {
  llvm::LLVMContext LLVMContext;
  auto *Expression = getExpressionWithMetadataOperands(LLVMContext);
  auto *Type = llvm::DIDerivedType::get(
      LLVMContext, llvm::dwarf::DW_TAG_pointer_type, "", nullptr, 0, nullptr,
      nullptr, nullptr, 0, Expression, std::nullopt, std::nullopt,
      llvm::DINode::FlagZero);

  expectImportFailure(Type);
}

TEST(DebugImporterTest,
     DIExpressionMetadataOperandsInStringSizeAreUnsupported) {
  llvm::LLVMContext LLVMContext;
  auto *Expression = getExpressionWithMetadataOperands(LLVMContext);
  auto *Type =
      llvm::DIStringType::get(LLVMContext, llvm::dwarf::DW_TAG_string_type,
                              llvm::MDString::get(LLVMContext, "string"),
                              nullptr, nullptr, nullptr, Expression, 0, 0);

  expectImportFailure(Type);
}

TEST(DebugImporterTest,
     DIExpressionMetadataOperandsInCompositeExpressionAreUnsupported) {
  llvm::LLVMContext LLVMContext;
  auto *Expression = getExpressionWithMetadataOperands(LLVMContext);
  auto *Type = llvm::DICompositeType::get(
      LLVMContext, llvm::dwarf::DW_TAG_array_type, "", nullptr, 0, nullptr,
      nullptr, uint64_t{0}, uint32_t{0}, uint64_t{0}, llvm::DINode::FlagZero,
      nullptr, 0, std::nullopt, nullptr, nullptr, "", nullptr, Expression);

  expectImportFailure(Type);
}

TEST(DebugImporterTest, DIExpressionMetadataOperandsInSubrangeAreUnsupported) {
  llvm::LLVMContext LLVMContext;
  auto *Expression = getExpressionWithMetadataOperands(LLVMContext);
  auto *Subrange =
      llvm::DISubrange::get(LLVMContext, Expression, nullptr, nullptr, nullptr);

  expectImportFailure(Subrange);
}

TEST(DebugImporterTest,
     DIExpressionMetadataOperandsInGlobalExpressionAreUnsupported) {
  MLIRContext Context;
  Context.loadDialect<LLVM::LLVMDialect>();
  OwningOpRef<ModuleOp> Module = ModuleOp::create(UnknownLoc::get(&Context));
  LLVM::detail::DebugImporter Importer(*Module,
                                       /*dropDICompositeTypeElements=*/false);

  llvm::LLVMContext LLVMContext;
  auto *Expression = getExpressionWithMetadataOperands(LLVMContext);
  auto *GlobalExpression =
      llvm::DIGlobalVariableExpression::get(LLVMContext, nullptr, Expression);

  EXPECT_FALSE(Importer.translateGlobalVariableExpression(GlobalExpression));
}

} // namespace

//===- DXILBitcodeWriterTests.cpp -----------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "DXILWriter/DXILBitcodeWriter.h"
#include "DirectXIRPasses/DXILDebugInfo.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/BinaryFormat/Dwarf.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/DebugInfoMetadata.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/raw_ostream.h"
#include "gtest/gtest.h"

using namespace llvm;

namespace {

static DIExpression *getExpressionWithMetadataOperands(LLVMContext &Context,
                                                       Metadata *RawOperand) {
  return DIExpression::get(Context, {dwarf::DW_OP_lit0},
                           ArrayRef<Metadata *>{RawOperand});
}

static void expectWriteFailure(Module &M) {
  SmallVector<char> Buffer;
  raw_svector_ostream OS(Buffer);
  dxil::DXILDebugInfoMap DebugInfo;
  EXPECT_DEATH(dxil::WriteDXILToFile(M, OS, DebugInfo),
               "DXIL cannot contain a DIExpression with metadata operands");
}

TEST(DXILBitcodeWriterTest, DIExpressionMetadataOperandsAreRejected) {
  LLVMContext Context;
  Module M("test", Context);
  auto *Expression = getExpressionWithMetadataOperands(
      Context, DIAssignID::getDistinct(Context));
  M.getOrInsertNamedMetadata("test.expression")->addOperand(Expression);

  expectWriteFailure(M);
}

TEST(DXILBitcodeWriterTest, FunctionDIExpressionMetadataOperandsAreRejected) {
  LLVMContext Context;
  Module M("test", Context);
  auto *RawOperand = DIAssignID::getDistinct(Context);
  M.getOrInsertNamedMetadata("test.operand")->addOperand(RawOperand);

  FunctionType *FunctionTy = FunctionType::get(Type::getVoidTy(Context), false);
  Function *F = Function::Create(FunctionTy, Function::ExternalLinkage, "f", M);
  BasicBlock *Entry = BasicBlock::Create(Context, "entry", F);
  ReturnInst::Create(Context, Entry);
  F->setMetadata("test.expression",
                 getExpressionWithMetadataOperands(Context, RawOperand));

  expectWriteFailure(M);
}

} // namespace

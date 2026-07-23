//===- llvm/unittest/IR/AsmWriter.cpp - AsmWriter tests -------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
#include "llvm/AsmParser/Parser.h"
#include "llvm/BinaryFormat/Dwarf.h"
#include "llvm/IR/DebugInfoMetadata.h"
#include "llvm/IR/DebugProgramInstruction.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/MDBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/SourceMgr.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"

using namespace llvm;
using ::testing::HasSubstr;

namespace {

TEST(AsmWriterTest, DebugPrintDetachedInstruction) {

  // PR24852: Ensure that an instruction can be printed even when it
  // has metadata attached but no parent.
  LLVMContext Ctx;
  auto Ty = Type::getInt32Ty(Ctx);
  auto Poison = PoisonValue::get(Ty);
  std::unique_ptr<BinaryOperator> Add(BinaryOperator::CreateAdd(Poison, Poison));
  Add->setMetadata(
      "", MDNode::get(Ctx, {ConstantAsMetadata::get(ConstantInt::get(Ty, 1))}));
  std::string S;
  raw_string_ostream OS(S);
  Add->print(OS);
  EXPECT_THAT(S, HasSubstr("<badref> = add i32 poison, poison, !<empty"));
}

TEST(AsmWriterTest, DebugPrintDetachedArgument) {
  LLVMContext Ctx;
  auto Ty = Type::getInt32Ty(Ctx);
  auto Arg = new Argument(Ty);

  std::string S;
  raw_string_ostream OS(S);
  Arg->print(OS);
  EXPECT_EQ(S, "i32 <badref>");
  delete Arg;
}

TEST(AsmWriterTest, DumpDIExpression) {
  LLVMContext Ctx;
  uint64_t Ops[] = {
    dwarf::DW_OP_constu, 4,
    dwarf::DW_OP_minus,
    dwarf::DW_OP_deref,
  };
  DIExpression *Expr = DIExpression::get(Ctx, Ops);
  std::string S;
  raw_string_ostream OS(S);
  Expr->print(OS);
  EXPECT_EQ("!DIExpression(DW_OP_constu, 4, DW_OP_minus, DW_OP_deref)", S);
}

TEST(AsmWriterTest, PrintDbgRecordExpressionsWithMetadataOperands) {
  LLVMContext Ctx;
  SMDiagnostic Error;
  std::unique_ptr<Module> M = parseAssemblyString(R"(
    define void @f(i32 %value, ptr %address) !dbg !5 {
    entry:
      #dbg_assign(i32 %value, !9, !DIExpression(), !12, ptr %address, !DIExpression(), !11)
      ret void
    }

    !llvm.dbg.cu = !{!0}
    !llvm.module.flags = !{!3}

    !0 = distinct !DICompileUnit(language: DW_LANG_C, file: !1, producer: "test", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug)
    !1 = !DIFile(filename: "test.c", directory: "/")
    !3 = !{i32 2, !"Debug Info Version", i32 3}
    !5 = distinct !DISubprogram(name: "f", scope: !1, file: !1, line: 1, type: !6, scopeLine: 1, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !8)
    !6 = !DISubroutineType(types: !7)
    !7 = !{null}
    !8 = !{!9}
    !9 = !DILocalVariable(name: "value", scope: !5, file: !1, line: 1, type: !10)
    !10 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
    !11 = !DILocation(line: 1, column: 1, scope: !5)
    !12 = distinct !DIAssignID()
  )",
                                                  Error, Ctx);
  ASSERT_TRUE(M) << Error.getMessage().str();

  Function &F = *M->getFunction("f");
  auto Records = F.front().front().getDbgRecordRange();
  ASSERT_FALSE(Records.empty());
  auto &Assign = cast<DbgVariableRecord>(*Records.begin());
  ASSERT_TRUE(Assign.isDbgAssign());

  Metadata *Target = MDTuple::get(Ctx, MDString::get(Ctx, "target"));
  Assign.setExpression(DIExpression::get(Ctx, {dwarf::DW_OP_lit0},
                                         ArrayRef<Metadata *>{Target}));
  Metadata *AddressOperands[] = {Target, nullptr};
  Assign.setAddressExpression(
      DIExpression::get(Ctx, {dwarf::DW_OP_deref}, AddressOperands));

  std::string IR;
  raw_string_ostream OS(IR);
  M->print(OS, nullptr);

  auto GetDefinitionSlot = [&](StringRef Definition) {
    size_t DefinitionPos = IR.find(Definition.str());
    EXPECT_NE(std::string::npos, DefinitionPos) << IR;
    if (DefinitionPos == std::string::npos)
      return std::string();
    size_t LineStart = IR.rfind('\n', DefinitionPos);
    LineStart = LineStart == std::string::npos ? 0 : LineStart + 1;
    return IR.substr(LineStart, DefinitionPos - LineStart);
  };

  std::string ValueSlot = GetDefinitionSlot(" = !DIExpression(48, operands: {");
  std::string AddressSlot =
      GetDefinitionSlot(" = !DIExpression(6, operands: {");
  ASSERT_FALSE(ValueSlot.empty());
  ASSERT_FALSE(AddressSlot.empty());

  size_t RecordPos = IR.find("#dbg_assign");
  ASSERT_NE(std::string::npos, RecordPos) << IR;
  StringRef RecordLine =
      StringRef(IR).slice(RecordPos, IR.find('\n', RecordPos));
  EXPECT_NE(StringRef::npos, RecordLine.find(ValueSlot));
  EXPECT_NE(StringRef::npos, RecordLine.find(AddressSlot));
  EXPECT_EQ(StringRef::npos, RecordLine.find("DIExpression"));
  EXPECT_THAT(IR, HasSubstr(" = !{!\"target\"}"));
}

TEST(AsmWriterTest, PrintAddrspaceWithNullOperand) {
  LLVMContext Ctx;
  Module M("test module", Ctx);
  SmallVector<Type *, 3> FArgTypes;
  FArgTypes.push_back(Type::getInt64Ty(Ctx));
  FunctionType *FTy = FunctionType::get(Type::getVoidTy(Ctx), FArgTypes, false);
  Function *F = Function::Create(FTy, Function::ExternalLinkage, "", &M);
  Argument *Arg0 = F->getArg(0);
  Value *Args[] = {Arg0};
  std::unique_ptr<CallInst> Call(CallInst::Create(F, Args));
  // This will make Call's operand null.
  Call->dropAllReferences();

  std::string S;
  raw_string_ostream OS(S);
  Call->print(OS);
  EXPECT_THAT(S, HasSubstr("<cannot get addrspace!>"));
}

TEST(AsmWriterTest, PrintNullOperandBundle) {
  LLVMContext C;
  Type *Int32Ty = Type::getInt32Ty(C);
  FunctionType *FnTy = FunctionType::get(Int32Ty, Int32Ty, /*isVarArg=*/false);
  Value *Callee = Constant::getNullValue(PointerType::getUnqual(C));
  Value *Args[] = {ConstantInt::get(Int32Ty, 42)};
  std::unique_ptr<BasicBlock> NormalDest(BasicBlock::Create(C));
  std::unique_ptr<BasicBlock> UnwindDest(BasicBlock::Create(C));
  OperandBundleDef Bundle("bundle", UndefValue::get(Int32Ty));
  std::unique_ptr<InvokeInst> Invoke(
      InvokeInst::Create(FnTy, Callee, NormalDest.get(), UnwindDest.get(), Args,
                         Bundle, "result"));
  // Makes the operand bundle null.
  Invoke->dropAllReferences();
  Invoke->setNormalDest(NormalDest.get());
  Invoke->setUnwindDest(UnwindDest.get());

  std::string S;
  raw_string_ostream OS(S);
  Invoke->print(OS);
  EXPECT_THAT(S, HasSubstr("<null operand bundle!>"));
}
}

//===-- WebAssemblyDwarfDebug.cpp - Wasm DwarfDebug Implementation --------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements WebAssembly-specific DWARF debug information handling.
//
//===----------------------------------------------------------------------===//

#include "WebAssemblyDwarfDebug.h"
#include "../../CodeGen/AsmPrinter/DwarfExpression.h"
#include "WebAssembly.h"
#include "llvm/BinaryFormat/Wasm.h"
#include "llvm/CodeGen/DIE.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/MC/MCSymbolWasm.h"
#include "llvm/Target/TargetLoweringObjectFile.h"
#include "llvm/Target/TargetMachine.h"

using namespace llvm;

WebAssemblyDwarfDebug::WebAssemblyDwarfDebug(AsmPrinter *A) : DwarfDebug(A) {}

// Emit a Wasm global-based relocation into a DIE location expression.
// 'GlobalIndex' is used for split dwarf, which currently relies on a few
// assumptions that are not guaranteed in a formal way but work in practice.
void WebAssemblyDwarfDebug::addWasmRelocBaseGlobal(DwarfCompileUnit &CU,
                                                   DIELoc *Loc,
                                                   StringRef GlobalName,
                                                   uint64_t GlobalIndex) {
  unsigned PointerSize = Asm->getDataLayout().getPointerSize();
  auto *Sym =
      static_cast<MCSymbolWasm *>(Asm->GetExternalSymbolSymbol(GlobalName));
  // FIXME: this repeats what WebAssemblyMCInstLower::
  // GetExternalSymbolSymbol does, since if there's no code that
  // refers to this symbol, we have to set it here.
  Sym->setType(wasm::WASM_SYMBOL_TYPE_GLOBAL);
  Sym->setGlobalType(wasm::WasmGlobalType{
      static_cast<uint8_t>(PointerSize == 4 ? wasm::WASM_TYPE_I32
                                            : wasm::WASM_TYPE_I64),
      true});
  CU.addUInt(*Loc, dwarf::DW_FORM_data1, dwarf::DW_OP_WASM_location);
  CU.addSInt(*Loc, dwarf::DW_FORM_sdata, WebAssembly::TI_GLOBAL_RELOC);
  if (!(useSplitDwarf() && CU.getSkeleton())) {
    CU.addLabel(*Loc, dwarf::DW_FORM_data4, Sym);
  } else {
    // FIXME: when writing dwo, we need to avoid relocations. Probably
    // the "right" solution is to treat globals the way func and data
    // symbols are (with entries in .debug_addr).
    // For now we hardcode the indices in the callsites. Global indices are not
    // fixed, but in practice a few are fixed; for example, __stack_pointer is
    // always index 0.
    CU.addUInt(*Loc, dwarf::DW_FORM_data4, GlobalIndex);
  }
}

bool WebAssemblyDwarfDebug::addTargetGlobalVariableLocation(
    DwarfCompileUnit &CU, DIELoc *Loc, const GlobalVariable *Global,
    const MCSymbol *Sym) {
  if (Global->isThreadLocal()) {
    // FIXME This is not guaranteed, but in practice, in static linking,
    // if present, __tls_base's index is 1. This doesn't hold for dynamic
    // linking, so TLS variables used in dynamic linking won't have
    // correct debug info for now. See
    // https://github.com/llvm/llvm-project/blob/19afbfe33156d211fa959dadeea46cd17b9c723c/lld/wasm/Driver.cpp#L786-L823
    addWasmRelocBaseGlobal(CU, Loc, "__tls_base", 1);
    CU.addOpAddress(*Loc, Sym);
    CU.addUInt(*Loc, dwarf::DW_FORM_data1, dwarf::DW_OP_plus);
    return true;
  }
  if (Asm->TM.getRelocationModel() == Reloc::PIC_) {
    // FIXME This is not guaranteed, but in practice, if present,
    // __memory_base's index is 1. See
    // https://github.com/llvm/llvm-project/blob/19afbfe33156d211fa959dadeea46cd17b9c723c/lld/wasm/Driver.cpp#L786-L823
    addWasmRelocBaseGlobal(CU, Loc, "__memory_base", 1);
    CU.addOpAddress(*Loc, Sym);
    CU.addUInt(*Loc, dwarf::DW_FORM_data1, dwarf::DW_OP_plus);
    return true;
  }
  return false;
}

void WebAssemblyDwarfDebug::addTargetIndexLocation(
    DwarfExpression &DwarfExpr, const TargetIndexLocation &Loc) {
  DwarfExpr.addWasmLocation(Loc.Index, static_cast<uint64_t>(Loc.Offset));
}

void WebAssemblyDwarfDebug::emitTargetFrameBase(
    DwarfCompileUnit &CU, DIE &SPDie,
    const TargetFrameLowering::DwarfFrameBase &FrameBase) {
  if (FrameBase.Location.WasmLoc.Kind == WebAssembly::TI_GLOBAL_RELOC) {
    // These need to be relocatable.
    DIELoc *Loc = CU.getDIELoc();
    assert(FrameBase.Location.WasmLoc.Index == 0); // Only SP so far.
    // For now, since we only ever use index 0, this should work as-is.
    addWasmRelocBaseGlobal(CU, Loc, "__stack_pointer",
                           FrameBase.Location.WasmLoc.Index);
    CU.addUInt(*Loc, dwarf::DW_FORM_data1, dwarf::DW_OP_stack_value);
    CU.addBlock(SPDie, dwarf::DW_AT_frame_base, Loc);
  } else {
    DIELoc *Loc = CU.getDIELoc();
    DIEDwarfExpression DwarfExpr(*Asm, CU, *Loc);
    DIExpressionCursor Cursor({});
    DwarfExpr.addWasmLocation(FrameBase.Location.WasmLoc.Kind,
                              FrameBase.Location.WasmLoc.Index);
    DwarfExpr.addExpression(std::move(Cursor));
    CU.addBlock(SPDie, dwarf::DW_AT_frame_base, DwarfExpr.finalize());
  }
}

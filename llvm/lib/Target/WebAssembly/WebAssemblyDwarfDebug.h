//===-- WebAssemblyDwarfDebug.h - Wasm DwarfDebug Implementation -*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file declares a WebAssembly-specific DwarfDebug subclass that handles
// Wasm-specific DWARF emission: TLS/PIC global variable locations,
// TargetIndexLocation encoding, and WasmFrameBase emission.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_WEBASSEMBLY_WEBASSEMBLYDWARFDEBUG_H
#define LLVM_LIB_TARGET_WEBASSEMBLY_WEBASSEMBLYDWARFDEBUG_H

#include "../../CodeGen/AsmPrinter/DwarfCompileUnit.h"

namespace llvm {

/// WebAssemblyDwarfDebug - WebAssembly-specific DwarfDebug implementation.
/// Handles Wasm-specific DWARF patterns: TLS/PIC global variable location
/// expressions, TargetIndexLocation encoding via DW_OP_WASM_location, and
/// WasmFrameBase emission for DW_AT_frame_base.
class WebAssemblyDwarfDebug : public DwarfDebug {
  /// Emit a Wasm global-based relocation into a DIE location expression.
  void addWasmRelocBaseGlobal(DwarfCompileUnit &CU, DIELoc *Loc,
                              StringRef GlobalName, uint64_t GlobalIndex);

public:
  WebAssemblyDwarfDebug(AsmPrinter *A);

  bool addTargetGlobalVariableLocation(DwarfCompileUnit &CU, DIELoc *Loc,
                                       const GlobalVariable *Global,
                                       const MCSymbol *Sym) override;

  void addTargetIndexLocation(DwarfExpression &DwarfExpr,
                              const TargetIndexLocation &Loc) override;

  void emitTargetFrameBase(
      DwarfCompileUnit &CU, DIE &SPDie,
      const TargetFrameLowering::DwarfFrameBase &FrameBase) override;
};

} // end namespace llvm

#endif // LLVM_LIB_TARGET_WEBASSEMBLY_WEBASSEMBLYDWARFDEBUG_H

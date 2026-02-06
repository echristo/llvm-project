//===-- NVPTXDwarfDebug.h - NVPTX DwarfDebug Implementation ---*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file declares helper classes and functions for NVPTX-specific debug
// information processing, particularly for inlined function call sites and
// enhanced line information with inlined_at directives.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_NVPTX_NVPTXDWARFDEBUG_H
#define LLVM_LIB_TARGET_NVPTX_NVPTXDWARFDEBUG_H

#include "../../CodeGen/AsmPrinter/DwarfCompileUnit.h"
#include "llvm/ADT/DenseSet.h"

namespace llvm {

class DwarfUnit;

/// NVPTXDwarfDebug - NVPTX-specific DwarfDebug implementation.
/// Inherits from DwarfDebug to provide NVPTX-specific DWARF behavior:
/// enhanced line information with inlined_at support, DWARF version
/// defaults, address class handling for cuda-gdb, and suppression of
/// features not supported by PTX (accelerator tables, pub sections,
/// base addresses in debug sections).
class NVPTXDwarfDebug : public DwarfDebug {
private:
  /// Set of inlined_at locations that have already been emitted.
  /// Used to avoid redundant emission of parent chain .loc directives.
  DenseSet<const DILocation *> EmittedInlinedAtLocs;

public:
  /// Constructor - Pass through to DwarfDebug constructor.
  NVPTXDwarfDebug(AsmPrinter *A);

protected:
  /// Override to collect inlined_at locations.
  void initializeTargetDebugInfo(const MachineFunction &MF) override;
  /// Override to record source line information with inlined_at support.
  void recordTargetSourceLine(const DebugLoc &DL, unsigned Flags) override;

public:
  /// PTX cannot subtract labels in debug sections, so base addresses
  /// are not supported.
  bool useCompileUnitBaseAddress(const DwarfCompileUnit &CU) const override;

  /// NVPTX does not support .debug_pubnames/.debug_pubtypes.
  bool supportsPubSections() const override;

  /// Extract address class from a DIExpression.
  void extractAddressClass(
      const DIExpression *&Expr,
      std::optional<unsigned> &AddressSpace) const override;

  /// Map IR address space to DWARF address class.
  std::optional<unsigned>
  mapAddressSpaceToClass(unsigned IRAddressSpace) const override;

  /// Emit DW_AT_address_class on a DIE.
  void emitAddressClass(DwarfUnit &DU, DIE &Die,
                        std::optional<unsigned> AddressSpace,
                        unsigned DefaultClass) const override;
};

} // end namespace llvm

#endif // LLVM_LIB_TARGET_NVPTX_NVPTXDWARFDEBUG_H

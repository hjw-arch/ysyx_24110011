// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VLSU_OOO_WRAPPER__SYMS_H_
#define VERILATED_VLSU_OOO_WRAPPER__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "VLSU_ooo_wrapper.h"

// INCLUDE MODULE CLASSES
#include "VLSU_ooo_wrapper___024root.h"

// SYMS CLASS (contains all model state)
class VLSU_ooo_wrapper__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    VLSU_ooo_wrapper* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    VLSU_ooo_wrapper___024root     TOP;

    // CONSTRUCTORS
    VLSU_ooo_wrapper__Syms(VerilatedContext* contextp, const char* namep, VLSU_ooo_wrapper* modelp);
    ~VLSU_ooo_wrapper__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);

#endif  // guard

// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VTB_LSU_OOO_SIMPLE__SYMS_H_
#define VERILATED_VTB_LSU_OOO_SIMPLE__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vtb_lsu_ooo_simple.h"

// INCLUDE MODULE CLASSES
#include "Vtb_lsu_ooo_simple___024root.h"

// SYMS CLASS (contains all model state)
class Vtb_lsu_ooo_simple__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vtb_lsu_ooo_simple* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vtb_lsu_ooo_simple___024root   TOP;

    // CONSTRUCTORS
    Vtb_lsu_ooo_simple__Syms(VerilatedContext* contextp, const char* namep, Vtb_lsu_ooo_simple* modelp);
    ~Vtb_lsu_ooo_simple__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);

#endif  // guard

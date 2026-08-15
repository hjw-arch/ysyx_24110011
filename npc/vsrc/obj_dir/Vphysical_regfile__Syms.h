// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VPHYSICAL_REGFILE__SYMS_H_
#define VERILATED_VPHYSICAL_REGFILE__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vphysical_regfile.h"

// INCLUDE MODULE CLASSES
#include "Vphysical_regfile___024root.h"

// SYMS CLASS (contains all model state)
class Vphysical_regfile__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vphysical_regfile* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vphysical_regfile___024root    TOP;

    // CONSTRUCTORS
    Vphysical_regfile__Syms(VerilatedContext* contextp, const char* namep, Vphysical_regfile* modelp);
    ~Vphysical_regfile__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);

#endif  // guard

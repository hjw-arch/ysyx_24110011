// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VFREELIST__SYMS_H_
#define VERILATED_VFREELIST__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vfreelist.h"

// INCLUDE MODULE CLASSES
#include "Vfreelist___024root.h"

// SYMS CLASS (contains all model state)
class Vfreelist__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vfreelist* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vfreelist___024root            TOP;

    // CONSTRUCTORS
    Vfreelist__Syms(VerilatedContext* contextp, const char* namep, Vfreelist* modelp);
    ~Vfreelist__Syms();

    // METHODS
    const char* name() { return TOP.name(); }
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);

#endif  // guard

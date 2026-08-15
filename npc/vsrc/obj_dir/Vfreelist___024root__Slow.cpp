// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vfreelist.h for the primary calling header

#include "verilated.h"

#include "Vfreelist__Syms.h"
#include "Vfreelist___024root.h"

void Vfreelist___024root___ctor_var_reset(Vfreelist___024root* vlSelf);

Vfreelist___024root::Vfreelist___024root(Vfreelist__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vfreelist___024root___ctor_var_reset(this);
}

void Vfreelist___024root::__Vconfigure(bool first) {
    if (false && first) {}  // Prevent unused
}

Vfreelist___024root::~Vfreelist___024root() {
}

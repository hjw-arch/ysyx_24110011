// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VEXU_ooo.h for the primary calling header

#include "verilated.h"

#include "VEXU_ooo__Syms.h"
#include "VEXU_ooo___024root.h"

void VEXU_ooo___024root___ctor_var_reset(VEXU_ooo___024root* vlSelf);

VEXU_ooo___024root::VEXU_ooo___024root(VEXU_ooo__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    VEXU_ooo___024root___ctor_var_reset(this);
}

void VEXU_ooo___024root::__Vconfigure(bool first) {
    if (false && first) {}  // Prevent unused
}

VEXU_ooo___024root::~VEXU_ooo___024root() {
}

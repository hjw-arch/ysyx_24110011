// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_lsu_debug.h for the primary calling header

#include "verilated.h"

#include "Vtb_lsu_debug__Syms.h"
#include "Vtb_lsu_debug___024root.h"

void Vtb_lsu_debug___024root___ctor_var_reset(Vtb_lsu_debug___024root* vlSelf);

Vtb_lsu_debug___024root::Vtb_lsu_debug___024root(Vtb_lsu_debug__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , __VdlySched{*symsp->_vm_contextp__}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vtb_lsu_debug___024root___ctor_var_reset(this);
}

void Vtb_lsu_debug___024root::__Vconfigure(bool first) {
    if (false && first) {}  // Prevent unused
}

Vtb_lsu_debug___024root::~Vtb_lsu_debug___024root() {
}

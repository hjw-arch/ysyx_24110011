// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VLSU_ooo_wrapper.h for the primary calling header

#include "verilated.h"

#include "VLSU_ooo_wrapper__Syms.h"
#include "VLSU_ooo_wrapper___024root.h"

void VLSU_ooo_wrapper___024root___ctor_var_reset(VLSU_ooo_wrapper___024root* vlSelf);

VLSU_ooo_wrapper___024root::VLSU_ooo_wrapper___024root(VLSU_ooo_wrapper__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    VLSU_ooo_wrapper___024root___ctor_var_reset(this);
}

void VLSU_ooo_wrapper___024root::__Vconfigure(bool first) {
    if (false && first) {}  // Prevent unused
}

VLSU_ooo_wrapper___024root::~VLSU_ooo_wrapper___024root() {
}

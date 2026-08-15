// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtb_lsu_debug.h for the primary calling header

#ifndef VERILATED_VTB_LSU_DEBUG___024ROOT_H_
#define VERILATED_VTB_LSU_DEBUG___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"

class Vtb_lsu_debug__Syms;

class Vtb_lsu_debug___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ tb_lsu_debug__DOT__clk;
    CData/*0:0*/ __VactContinue;
    IData/*31:0*/ __VactIterCount;
    VlDelayScheduler __VdlySched;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vtb_lsu_debug__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vtb_lsu_debug___024root(Vtb_lsu_debug__Syms* symsp, const char* v__name);
    ~Vtb_lsu_debug___024root();
    VL_UNCOPYABLE(Vtb_lsu_debug___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);


#endif  // guard

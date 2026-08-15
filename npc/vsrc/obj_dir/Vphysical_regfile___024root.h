// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vphysical_regfile.h for the primary calling header

#ifndef VERILATED_VPHYSICAL_REGFILE___024ROOT_H_
#define VERILATED_VPHYSICAL_REGFILE___024ROOT_H_  // guard

#include "verilated.h"

class Vphysical_regfile__Syms;

class Vphysical_regfile___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    VL_IN8(rst,0,0);
    VL_IN8(raddr1_i,5,0);
    VL_IN8(raddr2_i,5,0);
    VL_IN8(wen1_i,0,0);
    VL_IN8(waddr1_i,5,0);
    VL_IN8(wen2_i,0,0);
    VL_IN8(waddr2_i,5,0);
    CData/*0:0*/ __Vtrigrprev__TOP__clk;
    CData/*0:0*/ __VactContinue;
    VL_OUT(rdata1_o,31,0);
    VL_OUT(rdata2_o,31,0);
    VL_IN(wdata1_i,31,0);
    VL_IN(wdata2_i,31,0);
    IData/*31:0*/ __VstlIterCount;
    IData/*31:0*/ __VicoIterCount;
    IData/*31:0*/ __VactIterCount;
    VlUnpacked<IData/*31:0*/, 64> physical_regfile__DOT__pregs;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vphysical_regfile__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vphysical_regfile___024root(Vphysical_regfile__Syms* symsp, const char* v__name);
    ~Vphysical_regfile___024root();
    VL_UNCOPYABLE(Vphysical_regfile___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);


#endif  // guard

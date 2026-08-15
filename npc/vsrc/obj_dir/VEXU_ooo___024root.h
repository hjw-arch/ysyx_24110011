// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See VEXU_ooo.h for the primary calling header

#ifndef VERILATED_VEXU_OOO___024ROOT_H_
#define VERILATED_VEXU_OOO___024ROOT_H_  // guard

#include "verilated.h"

class VEXU_ooo__Syms;

class VEXU_ooo___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    VL_IN8(rst,0,0);
    VL_IN8(valid_i,0,0);
    VL_OUT8(ready_o,0,0);
    VL_OUT8(complete_en_o,0,0);
    VL_OUT8(complete_idx_o,4,0);
    VL_OUT8(complete_exception_o,0,0);
    VL_OUT8(complete_cause_o,3,0);
    VL_OUT8(complete_redirect_valid_o,0,0);
    VL_OUT8(wakeup_en_o,0,0);
    VL_OUT8(wakeup_preg_o,5,0);
    VL_OUT8(redirect_valid_o,0,0);
    VL_OUT8(bpu_update_valid_o,0,0);
    VL_OUT8(bpu_update_btb_type_o,0,0);
    VL_OUT8(bpu_update_taken_o,0,0);
    CData/*0:0*/ __VactContinue;
    VL_OUT(complete_data_o,31,0);
    VL_OUT(complete_redirect_addr_o,31,0);
    VL_OUT(redirect_addr_o,31,0);
    VL_OUT(bpu_update_target_o,31,0);
    IData/*31:0*/ __VstlIterCount;
    IData/*31:0*/ __VicoIterCount;
    IData/*31:0*/ __VactIterCount;
    VL_INW(data_i,195,0,7);
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<0> __VactTriggered;
    VlTriggerVec<0> __VnbaTriggered;

    // INTERNAL VARIABLES
    VEXU_ooo__Syms* const vlSymsp;

    // CONSTRUCTORS
    VEXU_ooo___024root(VEXU_ooo__Syms* symsp, const char* v__name);
    ~VEXU_ooo___024root();
    VL_UNCOPYABLE(VEXU_ooo___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);


#endif  // guard

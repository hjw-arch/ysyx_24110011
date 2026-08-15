// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vfreelist.h for the primary calling header

#ifndef VERILATED_VFREELIST___024ROOT_H_
#define VERILATED_VFREELIST___024ROOT_H_  // guard

#include "verilated.h"

class Vfreelist__Syms;

class Vfreelist___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    VL_IN8(rst,0,0);
    VL_IN8(alloc_en_i,0,0);
    VL_OUT8(alloc_preg_o,5,0);
    VL_OUT8(alloc_valid_o,0,0);
    VL_IN8(free_en_i,0,0);
    VL_IN8(free_preg_i,5,0);
    VL_OUT8(empty_o,0,0);
    VL_OUT8(free_count_o,5,0);
    CData/*5:0*/ freelist__DOT__head;
    CData/*5:0*/ freelist__DOT__tail;
    CData/*5:0*/ freelist__DOT__count;
    CData/*0:0*/ freelist__DOT__queue_full;
    CData/*0:0*/ __Vtrigrprev__TOP__clk;
    CData/*0:0*/ __VactContinue;
    IData/*31:0*/ __VstlIterCount;
    IData/*31:0*/ __VicoIterCount;
    IData/*31:0*/ __VactIterCount;
    VlUnpacked<CData/*5:0*/, 32> freelist__DOT__freelist_queue;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vfreelist__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vfreelist___024root(Vfreelist__Syms* symsp, const char* v__name);
    ~Vfreelist___024root();
    VL_UNCOPYABLE(Vfreelist___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);


#endif  // guard

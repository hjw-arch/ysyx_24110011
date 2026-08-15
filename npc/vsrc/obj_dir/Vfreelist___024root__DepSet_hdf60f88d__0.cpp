// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vfreelist.h for the primary calling header

#include "verilated.h"

#include "Vfreelist__Syms.h"
#include "Vfreelist___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vfreelist___024root___dump_triggers__ico(Vfreelist___024root* vlSelf);
#endif  // VL_DEBUG

void Vfreelist___024root___eval_triggers__ico(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___eval_triggers__ico\n"); );
    // Body
    vlSelf->__VicoTriggered.at(0U) = (0U == vlSelf->__VicoIterCount);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vfreelist___024root___dump_triggers__ico(vlSelf);
    }
#endif
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vfreelist___024root___dump_triggers__act(Vfreelist___024root* vlSelf);
#endif  // VL_DEBUG

void Vfreelist___024root___eval_triggers__act(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___eval_triggers__act\n"); );
    // Body
    vlSelf->__VactTriggered.at(0U) = ((IData)(vlSelf->clk) 
                                      & (~ (IData)(vlSelf->__Vtrigrprev__TOP__clk)));
    vlSelf->__Vtrigrprev__TOP__clk = vlSelf->clk;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vfreelist___024root___dump_triggers__act(vlSelf);
    }
#endif
}

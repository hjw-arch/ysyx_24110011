// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_lsu_ooo_simple.h for the primary calling header

#include "verilated.h"

#include "Vtb_lsu_ooo_simple__Syms.h"
#include "Vtb_lsu_ooo_simple___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_lsu_ooo_simple___024root___dump_triggers__act(Vtb_lsu_ooo_simple___024root* vlSelf);
#endif  // VL_DEBUG

void Vtb_lsu_ooo_simple___024root___eval_triggers__act(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___eval_triggers__act\n"); );
    // Body
    vlSelf->__VactTriggered.at(0U) = ((IData)(vlSelf->tb_lsu_ooo_simple__DOT__clk) 
                                      & (~ (IData)(vlSelf->__Vtrigrprev__TOP__tb_lsu_ooo_simple__DOT__clk)));
    vlSelf->__VactTriggered.at(1U) = vlSelf->__VdlySched.awaitingCurrentTime();
    vlSelf->__Vtrigrprev__TOP__tb_lsu_ooo_simple__DOT__clk 
        = vlSelf->tb_lsu_ooo_simple__DOT__clk;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtb_lsu_ooo_simple___024root___dump_triggers__act(vlSelf);
    }
#endif
}

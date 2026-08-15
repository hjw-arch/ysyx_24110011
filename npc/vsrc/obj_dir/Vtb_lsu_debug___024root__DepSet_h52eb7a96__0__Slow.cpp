// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_lsu_debug.h for the primary calling header

#include "verilated.h"

#include "Vtb_lsu_debug___024root.h"

VL_ATTR_COLD void Vtb_lsu_debug___024root___eval_static__TOP(Vtb_lsu_debug___024root* vlSelf);

VL_ATTR_COLD void Vtb_lsu_debug___024root___eval_static(Vtb_lsu_debug___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_debug__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_debug___024root___eval_static\n"); );
    // Body
    Vtb_lsu_debug___024root___eval_static__TOP(vlSelf);
}

VL_ATTR_COLD void Vtb_lsu_debug___024root___eval_static__TOP(Vtb_lsu_debug___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_debug__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_debug___024root___eval_static__TOP\n"); );
    // Body
    vlSelf->tb_lsu_debug__DOT__clk = 0U;
}

VL_ATTR_COLD void Vtb_lsu_debug___024root___eval_final(Vtb_lsu_debug___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_debug__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_debug___024root___eval_final\n"); );
}

VL_ATTR_COLD void Vtb_lsu_debug___024root___eval_settle(Vtb_lsu_debug___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_debug__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_debug___024root___eval_settle\n"); );
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_lsu_debug___024root___dump_triggers__act(Vtb_lsu_debug___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_debug__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_debug___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VactTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if (vlSelf->__VactTriggered.at(0U)) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_lsu_debug___024root___dump_triggers__nba(Vtb_lsu_debug___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_debug__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_debug___024root___dump_triggers__nba\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VnbaTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if (vlSelf->__VnbaTriggered.at(0U)) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtb_lsu_debug___024root___ctor_var_reset(Vtb_lsu_debug___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_debug__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_debug___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->tb_lsu_debug__DOT__clk = VL_RAND_RESET_I(1);
    }

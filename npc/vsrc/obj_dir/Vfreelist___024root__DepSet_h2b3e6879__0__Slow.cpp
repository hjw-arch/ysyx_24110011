// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vfreelist.h for the primary calling header

#include "verilated.h"

#include "Vfreelist___024root.h"

VL_ATTR_COLD void Vfreelist___024root___eval_static(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___eval_static\n"); );
}

VL_ATTR_COLD void Vfreelist___024root___eval_initial(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___eval_initial\n"); );
    // Body
    vlSelf->__Vtrigrprev__TOP__clk = vlSelf->clk;
}

VL_ATTR_COLD void Vfreelist___024root___eval_final(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___eval_final\n"); );
}

VL_ATTR_COLD void Vfreelist___024root___eval_triggers__stl(Vfreelist___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void Vfreelist___024root___dump_triggers__stl(Vfreelist___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD void Vfreelist___024root___eval_stl(Vfreelist___024root* vlSelf);

VL_ATTR_COLD void Vfreelist___024root___eval_settle(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___eval_settle\n"); );
    // Init
    CData/*0:0*/ __VstlContinue;
    // Body
    vlSelf->__VstlIterCount = 0U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        __VstlContinue = 0U;
        Vfreelist___024root___eval_triggers__stl(vlSelf);
        if (vlSelf->__VstlTriggered.any()) {
            __VstlContinue = 1U;
            if (VL_UNLIKELY((0x64U < vlSelf->__VstlIterCount))) {
#ifdef VL_DEBUG
                Vfreelist___024root___dump_triggers__stl(vlSelf);
#endif
                VL_FATAL_MT("ooo/freelist.sv", 22, "", "Settle region did not converge.");
            }
            vlSelf->__VstlIterCount = ((IData)(1U) 
                                       + vlSelf->__VstlIterCount);
            Vfreelist___024root___eval_stl(vlSelf);
        }
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vfreelist___024root___dump_triggers__stl(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VstlTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if (vlSelf->__VstlTriggered.at(0U)) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vfreelist___024root___stl_sequent__TOP__0(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___stl_sequent__TOP__0\n"); );
    // Body
    vlSelf->free_count_o = vlSelf->freelist__DOT__count;
    vlSelf->freelist__DOT__queue_full = (0x20U == (IData)(vlSelf->freelist__DOT__count));
    vlSelf->empty_o = (0U == (IData)(vlSelf->freelist__DOT__count));
    vlSelf->alloc_valid_o = ((~ (IData)(vlSelf->empty_o)) 
                             & (IData)(vlSelf->alloc_en_i));
    vlSelf->alloc_preg_o = ((IData)(vlSelf->empty_o)
                             ? 0U : vlSelf->freelist__DOT__freelist_queue
                            [(0x1fU & (IData)(vlSelf->freelist__DOT__head))]);
}

VL_ATTR_COLD void Vfreelist___024root___eval_stl(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___eval_stl\n"); );
    // Body
    if (vlSelf->__VstlTriggered.at(0U)) {
        Vfreelist___024root___stl_sequent__TOP__0(vlSelf);
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vfreelist___024root___dump_triggers__ico(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___dump_triggers__ico\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VicoTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if (vlSelf->__VicoTriggered.at(0U)) {
        VL_DBG_MSGF("         'ico' region trigger index 0 is active: Internal 'ico' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vfreelist___024root___dump_triggers__act(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VactTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if (vlSelf->__VactTriggered.at(0U)) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge clk)\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vfreelist___024root___dump_triggers__nba(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___dump_triggers__nba\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VnbaTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if (vlSelf->__VnbaTriggered.at(0U)) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge clk)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vfreelist___024root___ctor_var_reset(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->clk = VL_RAND_RESET_I(1);
    vlSelf->rst = VL_RAND_RESET_I(1);
    vlSelf->alloc_en_i = VL_RAND_RESET_I(1);
    vlSelf->alloc_preg_o = VL_RAND_RESET_I(6);
    vlSelf->alloc_valid_o = VL_RAND_RESET_I(1);
    vlSelf->free_en_i = VL_RAND_RESET_I(1);
    vlSelf->free_preg_i = VL_RAND_RESET_I(6);
    vlSelf->empty_o = VL_RAND_RESET_I(1);
    vlSelf->free_count_o = VL_RAND_RESET_I(6);
    for (int __Vi0 = 0; __Vi0 < 32; ++__Vi0) {
        vlSelf->freelist__DOT__freelist_queue[__Vi0] = VL_RAND_RESET_I(6);
    }
    vlSelf->freelist__DOT__head = VL_RAND_RESET_I(6);
    vlSelf->freelist__DOT__tail = VL_RAND_RESET_I(6);
    vlSelf->freelist__DOT__count = VL_RAND_RESET_I(6);
    vlSelf->freelist__DOT__queue_full = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigrprev__TOP__clk = VL_RAND_RESET_I(1);
}

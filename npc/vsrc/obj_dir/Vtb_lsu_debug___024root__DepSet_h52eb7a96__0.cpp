// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_lsu_debug.h for the primary calling header

#include "verilated.h"

#include "Vtb_lsu_debug___024root.h"

VlCoroutine Vtb_lsu_debug___024root___eval_initial__TOP__0(Vtb_lsu_debug___024root* vlSelf);
VlCoroutine Vtb_lsu_debug___024root___eval_initial__TOP__1(Vtb_lsu_debug___024root* vlSelf);

void Vtb_lsu_debug___024root___eval_initial(Vtb_lsu_debug___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_debug__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_debug___024root___eval_initial\n"); );
    // Body
    Vtb_lsu_debug___024root___eval_initial__TOP__0(vlSelf);
    Vtb_lsu_debug___024root___eval_initial__TOP__1(vlSelf);
}

VL_INLINE_OPT VlCoroutine Vtb_lsu_debug___024root___eval_initial__TOP__0(Vtb_lsu_debug___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_debug__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_debug___024root___eval_initial__TOP__0\n"); );
    // Init
    VlWide<7>/*195:0*/ tb_lsu_debug__DOT__data_i;
    VL_ZERO_W(196, tb_lsu_debug__DOT__data_i);
    // Body
    tb_lsu_debug__DOT__data_i[0U] = 0U;
    tb_lsu_debug__DOT__data_i[1U] = 0U;
    tb_lsu_debug__DOT__data_i[2U] = 0U;
    tb_lsu_debug__DOT__data_i[3U] = 0U;
    tb_lsu_debug__DOT__data_i[4U] = 0U;
    tb_lsu_debug__DOT__data_i[5U] = 0U;
    tb_lsu_debug__DOT__data_i[6U] = 0U;
    co_await vlSelf->__VdlySched.delay(0x2710ULL, "/tmp/test_lsu_debug.sv", 
                                       15);
    tb_lsu_debug__DOT__data_i[3U] = (0x80000000U | 
                                     (0x7fffffffU & 
                                      tb_lsu_debug__DOT__data_i[3U]));
    tb_lsu_debug__DOT__data_i[4U] = (0xaU | (0xfffffff0U 
                                             & tb_lsu_debug__DOT__data_i[4U]));
    tb_lsu_debug__DOT__data_i[1U] = (0xffffff9fU & 
                                     tb_lsu_debug__DOT__data_i[1U]);
    co_await vlSelf->__VdlySched.delay(0x2710ULL, "/tmp/test_lsu_debug.sv", 
                                       20);
    VL_WRITEF("data_i.rob_idx = %b (%2#)\n",5,(0x1fU 
                                               & ((tb_lsu_debug__DOT__data_i[4U] 
                                                   << 1U) 
                                                  | (tb_lsu_debug__DOT__data_i[3U] 
                                                     >> 0x1fU))),
              5,(0x1fU & ((tb_lsu_debug__DOT__data_i[4U] 
                           << 1U) | (tb_lsu_debug__DOT__data_i[3U] 
                                     >> 0x1fU))));
    co_await vlSelf->__VdlySched.delay(0x2710ULL, "/tmp/test_lsu_debug.sv", 
                                       23);
    VL_FINISH_MT("/tmp/test_lsu_debug.sv", 24, "");
}

VL_INLINE_OPT VlCoroutine Vtb_lsu_debug___024root___eval_initial__TOP__1(Vtb_lsu_debug___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_debug__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_debug___024root___eval_initial__TOP__1\n"); );
    // Body
    while (1U) {
        co_await vlSelf->__VdlySched.delay(0x1388ULL, 
                                           "/tmp/test_lsu_debug.sv", 
                                           9);
        vlSelf->tb_lsu_debug__DOT__clk = (1U & (~ (IData)(vlSelf->tb_lsu_debug__DOT__clk)));
    }
}

void Vtb_lsu_debug___024root___eval_act(Vtb_lsu_debug___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_debug__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_debug___024root___eval_act\n"); );
}

void Vtb_lsu_debug___024root___eval_nba(Vtb_lsu_debug___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_debug__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_debug___024root___eval_nba\n"); );
}

void Vtb_lsu_debug___024root___eval_triggers__act(Vtb_lsu_debug___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_lsu_debug___024root___dump_triggers__act(Vtb_lsu_debug___024root* vlSelf);
#endif  // VL_DEBUG
void Vtb_lsu_debug___024root___timing_resume(Vtb_lsu_debug___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_lsu_debug___024root___dump_triggers__nba(Vtb_lsu_debug___024root* vlSelf);
#endif  // VL_DEBUG

void Vtb_lsu_debug___024root___eval(Vtb_lsu_debug___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_debug__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_debug___024root___eval\n"); );
    // Init
    VlTriggerVec<1> __VpreTriggered;
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        __VnbaContinue = 0U;
        vlSelf->__VnbaTriggered.clear();
        vlSelf->__VactIterCount = 0U;
        vlSelf->__VactContinue = 1U;
        while (vlSelf->__VactContinue) {
            vlSelf->__VactContinue = 0U;
            Vtb_lsu_debug___024root___eval_triggers__act(vlSelf);
            if (vlSelf->__VactTriggered.any()) {
                vlSelf->__VactContinue = 1U;
                if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                    Vtb_lsu_debug___024root___dump_triggers__act(vlSelf);
#endif
                    VL_FATAL_MT("/tmp/test_lsu_debug.sv", 4, "", "Active region did not converge.");
                }
                vlSelf->__VactIterCount = ((IData)(1U) 
                                           + vlSelf->__VactIterCount);
                __VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
                vlSelf->__VnbaTriggered.set(vlSelf->__VactTriggered);
                Vtb_lsu_debug___024root___timing_resume(vlSelf);
                Vtb_lsu_debug___024root___eval_act(vlSelf);
            }
        }
        if (vlSelf->__VnbaTriggered.any()) {
            __VnbaContinue = 1U;
            if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
                Vtb_lsu_debug___024root___dump_triggers__nba(vlSelf);
#endif
                VL_FATAL_MT("/tmp/test_lsu_debug.sv", 4, "", "NBA region did not converge.");
            }
            __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
            Vtb_lsu_debug___024root___eval_nba(vlSelf);
        }
    }
}

void Vtb_lsu_debug___024root___timing_resume(Vtb_lsu_debug___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_debug__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_debug___024root___timing_resume\n"); );
    // Body
    if (vlSelf->__VactTriggered.at(0U)) {
        vlSelf->__VdlySched.resume();
    }
}

#ifdef VL_DEBUG
void Vtb_lsu_debug___024root___eval_debug_assertions(Vtb_lsu_debug___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_debug__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_debug___024root___eval_debug_assertions\n"); );
}
#endif  // VL_DEBUG

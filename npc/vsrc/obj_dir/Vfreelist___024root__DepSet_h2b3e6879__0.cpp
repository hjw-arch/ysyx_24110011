// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vfreelist.h for the primary calling header

#include "verilated.h"

#include "Vfreelist___024root.h"

VL_INLINE_OPT void Vfreelist___024root___ico_sequent__TOP__0(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___ico_sequent__TOP__0\n"); );
    // Body
    vlSelf->alloc_valid_o = ((~ (IData)(vlSelf->empty_o)) 
                             & (IData)(vlSelf->alloc_en_i));
}

void Vfreelist___024root___eval_ico(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___eval_ico\n"); );
    // Body
    if (vlSelf->__VicoTriggered.at(0U)) {
        Vfreelist___024root___ico_sequent__TOP__0(vlSelf);
    }
}

void Vfreelist___024root___eval_act(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___eval_act\n"); );
}

VL_INLINE_OPT void Vfreelist___024root___nba_sequent__TOP__0(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___nba_sequent__TOP__0\n"); );
    // Init
    CData/*0:0*/ __Vdlyvset__freelist__DOT__freelist_queue__v0;
    __Vdlyvset__freelist__DOT__freelist_queue__v0 = 0;
    CData/*5:0*/ __Vdly__freelist__DOT__tail;
    __Vdly__freelist__DOT__tail = 0;
    CData/*0:0*/ __Vdlyvset__freelist__DOT__freelist_queue__v1;
    __Vdlyvset__freelist__DOT__freelist_queue__v1 = 0;
    CData/*4:0*/ __Vdlyvdim0__freelist__DOT__freelist_queue__v32;
    __Vdlyvdim0__freelist__DOT__freelist_queue__v32 = 0;
    CData/*5:0*/ __Vdlyvval__freelist__DOT__freelist_queue__v32;
    __Vdlyvval__freelist__DOT__freelist_queue__v32 = 0;
    CData/*0:0*/ __Vdlyvset__freelist__DOT__freelist_queue__v32;
    __Vdlyvset__freelist__DOT__freelist_queue__v32 = 0;
    CData/*4:0*/ __Vdlyvdim0__freelist__DOT__freelist_queue__v33;
    __Vdlyvdim0__freelist__DOT__freelist_queue__v33 = 0;
    CData/*5:0*/ __Vdlyvval__freelist__DOT__freelist_queue__v33;
    __Vdlyvval__freelist__DOT__freelist_queue__v33 = 0;
    CData/*0:0*/ __Vdlyvset__freelist__DOT__freelist_queue__v33;
    __Vdlyvset__freelist__DOT__freelist_queue__v33 = 0;
    CData/*5:0*/ __Vdly__freelist__DOT__head;
    __Vdly__freelist__DOT__head = 0;
    CData/*5:0*/ __Vdly__freelist__DOT__count;
    __Vdly__freelist__DOT__count = 0;
    // Body
    __Vdly__freelist__DOT__head = vlSelf->freelist__DOT__head;
    __Vdly__freelist__DOT__count = vlSelf->freelist__DOT__count;
    __Vdly__freelist__DOT__tail = vlSelf->freelist__DOT__tail;
    __Vdlyvset__freelist__DOT__freelist_queue__v0 = 0U;
    __Vdlyvset__freelist__DOT__freelist_queue__v1 = 0U;
    __Vdlyvset__freelist__DOT__freelist_queue__v32 = 0U;
    __Vdlyvset__freelist__DOT__freelist_queue__v33 = 0U;
    if (vlSelf->rst) {
        __Vdly__freelist__DOT__head = 0U;
        __Vdly__freelist__DOT__count = 0x20U;
        __Vdlyvset__freelist__DOT__freelist_queue__v0 = 1U;
        __Vdly__freelist__DOT__tail = 0x20U;
        __Vdlyvset__freelist__DOT__freelist_queue__v1 = 1U;
    } else {
        if ((2U == (((IData)(vlSelf->alloc_valid_o) 
                     << 1U) | (IData)(vlSelf->free_en_i)))) {
            __Vdly__freelist__DOT__head = (0x1fU & 
                                           ((IData)(1U) 
                                            + (IData)(vlSelf->freelist__DOT__head)));
            __Vdly__freelist__DOT__count = (0x3fU & 
                                            ((IData)(vlSelf->freelist__DOT__count) 
                                             - (IData)(1U)));
        } else {
            if ((1U != (((IData)(vlSelf->alloc_valid_o) 
                         << 1U) | (IData)(vlSelf->free_en_i)))) {
                if ((3U == (((IData)(vlSelf->alloc_valid_o) 
                             << 1U) | (IData)(vlSelf->free_en_i)))) {
                    __Vdly__freelist__DOT__head = (0x1fU 
                                                   & ((IData)(1U) 
                                                      + (IData)(vlSelf->freelist__DOT__head)));
                }
            }
            if ((1U == (((IData)(vlSelf->alloc_valid_o) 
                         << 1U) | (IData)(vlSelf->free_en_i)))) {
                if (((~ (IData)(vlSelf->freelist__DOT__queue_full)) 
                     & (0U != (IData)(vlSelf->free_preg_i)))) {
                    __Vdly__freelist__DOT__count = 
                        (0x3fU & ((IData)(1U) + (IData)(vlSelf->freelist__DOT__count)));
                }
            } else if ((3U == (((IData)(vlSelf->alloc_valid_o) 
                                << 1U) | (IData)(vlSelf->free_en_i)))) {
                if ((0U == (IData)(vlSelf->free_preg_i))) {
                    __Vdly__freelist__DOT__count = 
                        (0x3fU & ((IData)(vlSelf->freelist__DOT__count) 
                                  - (IData)(1U)));
                }
            }
        }
        if ((2U != (((IData)(vlSelf->alloc_valid_o) 
                     << 1U) | (IData)(vlSelf->free_en_i)))) {
            if ((1U == (((IData)(vlSelf->alloc_valid_o) 
                         << 1U) | (IData)(vlSelf->free_en_i)))) {
                if (((0x20U != (IData)(vlSelf->freelist__DOT__count)) 
                     & (0U != (IData)(vlSelf->free_preg_i)))) {
                    __Vdlyvval__freelist__DOT__freelist_queue__v32 
                        = vlSelf->free_preg_i;
                    __Vdlyvset__freelist__DOT__freelist_queue__v32 = 1U;
                    __Vdlyvdim0__freelist__DOT__freelist_queue__v32 
                        = (0x1fU & (IData)(vlSelf->freelist__DOT__tail));
                    __Vdly__freelist__DOT__tail = (0x1fU 
                                                   & ((IData)(1U) 
                                                      + (IData)(vlSelf->freelist__DOT__tail)));
                }
            } else if ((3U == (((IData)(vlSelf->alloc_valid_o) 
                                << 1U) | (IData)(vlSelf->free_en_i)))) {
                if ((0U != (IData)(vlSelf->free_preg_i))) {
                    __Vdlyvval__freelist__DOT__freelist_queue__v33 
                        = vlSelf->free_preg_i;
                    __Vdlyvset__freelist__DOT__freelist_queue__v33 = 1U;
                    __Vdlyvdim0__freelist__DOT__freelist_queue__v33 
                        = (0x1fU & (IData)(vlSelf->freelist__DOT__tail));
                    __Vdly__freelist__DOT__tail = (0x1fU 
                                                   & ((IData)(1U) 
                                                      + (IData)(vlSelf->freelist__DOT__tail)));
                }
            }
        }
    }
    vlSelf->freelist__DOT__head = __Vdly__freelist__DOT__head;
    vlSelf->freelist__DOT__tail = __Vdly__freelist__DOT__tail;
    if (__Vdlyvset__freelist__DOT__freelist_queue__v0) {
        vlSelf->freelist__DOT__freelist_queue[0U] = 0x20U;
    }
    if (__Vdlyvset__freelist__DOT__freelist_queue__v1) {
        vlSelf->freelist__DOT__freelist_queue[1U] = 0x21U;
        vlSelf->freelist__DOT__freelist_queue[2U] = 0x22U;
        vlSelf->freelist__DOT__freelist_queue[3U] = 0x23U;
        vlSelf->freelist__DOT__freelist_queue[4U] = 0x24U;
        vlSelf->freelist__DOT__freelist_queue[5U] = 0x25U;
        vlSelf->freelist__DOT__freelist_queue[6U] = 0x26U;
        vlSelf->freelist__DOT__freelist_queue[7U] = 0x27U;
        vlSelf->freelist__DOT__freelist_queue[8U] = 0x28U;
        vlSelf->freelist__DOT__freelist_queue[9U] = 0x29U;
        vlSelf->freelist__DOT__freelist_queue[0xaU] = 0x2aU;
        vlSelf->freelist__DOT__freelist_queue[0xbU] = 0x2bU;
        vlSelf->freelist__DOT__freelist_queue[0xcU] = 0x2cU;
        vlSelf->freelist__DOT__freelist_queue[0xdU] = 0x2dU;
        vlSelf->freelist__DOT__freelist_queue[0xeU] = 0x2eU;
        vlSelf->freelist__DOT__freelist_queue[0xfU] = 0x2fU;
        vlSelf->freelist__DOT__freelist_queue[0x10U] = 0x30U;
        vlSelf->freelist__DOT__freelist_queue[0x11U] = 0x31U;
        vlSelf->freelist__DOT__freelist_queue[0x12U] = 0x32U;
        vlSelf->freelist__DOT__freelist_queue[0x13U] = 0x33U;
        vlSelf->freelist__DOT__freelist_queue[0x14U] = 0x34U;
        vlSelf->freelist__DOT__freelist_queue[0x15U] = 0x35U;
        vlSelf->freelist__DOT__freelist_queue[0x16U] = 0x36U;
        vlSelf->freelist__DOT__freelist_queue[0x17U] = 0x37U;
        vlSelf->freelist__DOT__freelist_queue[0x18U] = 0x38U;
        vlSelf->freelist__DOT__freelist_queue[0x19U] = 0x39U;
        vlSelf->freelist__DOT__freelist_queue[0x1aU] = 0x3aU;
        vlSelf->freelist__DOT__freelist_queue[0x1bU] = 0x3bU;
        vlSelf->freelist__DOT__freelist_queue[0x1cU] = 0x3cU;
        vlSelf->freelist__DOT__freelist_queue[0x1dU] = 0x3dU;
        vlSelf->freelist__DOT__freelist_queue[0x1eU] = 0x3eU;
        vlSelf->freelist__DOT__freelist_queue[0x1fU] = 0x3fU;
    }
    if (__Vdlyvset__freelist__DOT__freelist_queue__v32) {
        vlSelf->freelist__DOT__freelist_queue[__Vdlyvdim0__freelist__DOT__freelist_queue__v32] 
            = __Vdlyvval__freelist__DOT__freelist_queue__v32;
    }
    if (__Vdlyvset__freelist__DOT__freelist_queue__v33) {
        vlSelf->freelist__DOT__freelist_queue[__Vdlyvdim0__freelist__DOT__freelist_queue__v33] 
            = __Vdlyvval__freelist__DOT__freelist_queue__v33;
    }
    vlSelf->freelist__DOT__count = __Vdly__freelist__DOT__count;
    vlSelf->free_count_o = vlSelf->freelist__DOT__count;
    vlSelf->freelist__DOT__queue_full = (0x20U == (IData)(vlSelf->freelist__DOT__count));
    vlSelf->empty_o = (0U == (IData)(vlSelf->freelist__DOT__count));
    vlSelf->alloc_valid_o = ((~ (IData)(vlSelf->empty_o)) 
                             & (IData)(vlSelf->alloc_en_i));
    vlSelf->alloc_preg_o = ((IData)(vlSelf->empty_o)
                             ? 0U : vlSelf->freelist__DOT__freelist_queue
                            [(0x1fU & (IData)(vlSelf->freelist__DOT__head))]);
}

void Vfreelist___024root___eval_nba(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___eval_nba\n"); );
    // Body
    if (vlSelf->__VnbaTriggered.at(0U)) {
        Vfreelist___024root___nba_sequent__TOP__0(vlSelf);
    }
}

void Vfreelist___024root___eval_triggers__ico(Vfreelist___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void Vfreelist___024root___dump_triggers__ico(Vfreelist___024root* vlSelf);
#endif  // VL_DEBUG
void Vfreelist___024root___eval_triggers__act(Vfreelist___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void Vfreelist___024root___dump_triggers__act(Vfreelist___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vfreelist___024root___dump_triggers__nba(Vfreelist___024root* vlSelf);
#endif  // VL_DEBUG

void Vfreelist___024root___eval(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___eval\n"); );
    // Init
    CData/*0:0*/ __VicoContinue;
    VlTriggerVec<1> __VpreTriggered;
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    vlSelf->__VicoIterCount = 0U;
    __VicoContinue = 1U;
    while (__VicoContinue) {
        __VicoContinue = 0U;
        Vfreelist___024root___eval_triggers__ico(vlSelf);
        if (vlSelf->__VicoTriggered.any()) {
            __VicoContinue = 1U;
            if (VL_UNLIKELY((0x64U < vlSelf->__VicoIterCount))) {
#ifdef VL_DEBUG
                Vfreelist___024root___dump_triggers__ico(vlSelf);
#endif
                VL_FATAL_MT("ooo/freelist.sv", 22, "", "Input combinational region did not converge.");
            }
            vlSelf->__VicoIterCount = ((IData)(1U) 
                                       + vlSelf->__VicoIterCount);
            Vfreelist___024root___eval_ico(vlSelf);
        }
    }
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        __VnbaContinue = 0U;
        vlSelf->__VnbaTriggered.clear();
        vlSelf->__VactIterCount = 0U;
        vlSelf->__VactContinue = 1U;
        while (vlSelf->__VactContinue) {
            vlSelf->__VactContinue = 0U;
            Vfreelist___024root___eval_triggers__act(vlSelf);
            if (vlSelf->__VactTriggered.any()) {
                vlSelf->__VactContinue = 1U;
                if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                    Vfreelist___024root___dump_triggers__act(vlSelf);
#endif
                    VL_FATAL_MT("ooo/freelist.sv", 22, "", "Active region did not converge.");
                }
                vlSelf->__VactIterCount = ((IData)(1U) 
                                           + vlSelf->__VactIterCount);
                __VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
                vlSelf->__VnbaTriggered.set(vlSelf->__VactTriggered);
                Vfreelist___024root___eval_act(vlSelf);
            }
        }
        if (vlSelf->__VnbaTriggered.any()) {
            __VnbaContinue = 1U;
            if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
                Vfreelist___024root___dump_triggers__nba(vlSelf);
#endif
                VL_FATAL_MT("ooo/freelist.sv", 22, "", "NBA region did not converge.");
            }
            __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
            Vfreelist___024root___eval_nba(vlSelf);
        }
    }
}

#ifdef VL_DEBUG
void Vfreelist___024root___eval_debug_assertions(Vfreelist___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vfreelist__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vfreelist___024root___eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((vlSelf->clk & 0xfeU))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY((vlSelf->rst & 0xfeU))) {
        Verilated::overWidthError("rst");}
    if (VL_UNLIKELY((vlSelf->alloc_en_i & 0xfeU))) {
        Verilated::overWidthError("alloc_en_i");}
    if (VL_UNLIKELY((vlSelf->free_en_i & 0xfeU))) {
        Verilated::overWidthError("free_en_i");}
    if (VL_UNLIKELY((vlSelf->free_preg_i & 0xc0U))) {
        Verilated::overWidthError("free_preg_i");}
}
#endif  // VL_DEBUG

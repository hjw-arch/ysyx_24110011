// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vphysical_regfile.h for the primary calling header

#include "verilated.h"

#include "Vphysical_regfile___024root.h"

VL_INLINE_OPT void Vphysical_regfile___024root___ico_sequent__TOP__0(Vphysical_regfile___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vphysical_regfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vphysical_regfile___024root___ico_sequent__TOP__0\n"); );
    // Body
    vlSelf->rdata1_o = ((0U == (IData)(vlSelf->raddr1_i))
                         ? 0U : (((((IData)(vlSelf->raddr1_i) 
                                    == (IData)(vlSelf->waddr1_i)) 
                                   & (IData)(vlSelf->wen1_i)) 
                                  & (0U != (IData)(vlSelf->waddr1_i)))
                                  ? vlSelf->wdata1_i
                                  : (((((IData)(vlSelf->raddr1_i) 
                                        == (IData)(vlSelf->waddr2_i)) 
                                       & (IData)(vlSelf->wen2_i)) 
                                      & (0U != (IData)(vlSelf->waddr2_i)))
                                      ? vlSelf->wdata2_i
                                      : vlSelf->physical_regfile__DOT__pregs
                                     [vlSelf->raddr1_i])));
    vlSelf->rdata2_o = ((0U == (IData)(vlSelf->raddr2_i))
                         ? 0U : (((((IData)(vlSelf->raddr2_i) 
                                    == (IData)(vlSelf->waddr1_i)) 
                                   & (IData)(vlSelf->wen1_i)) 
                                  & (0U != (IData)(vlSelf->waddr1_i)))
                                  ? vlSelf->wdata1_i
                                  : (((((IData)(vlSelf->raddr2_i) 
                                        == (IData)(vlSelf->waddr2_i)) 
                                       & (IData)(vlSelf->wen2_i)) 
                                      & (0U != (IData)(vlSelf->waddr2_i)))
                                      ? vlSelf->wdata2_i
                                      : vlSelf->physical_regfile__DOT__pregs
                                     [vlSelf->raddr2_i])));
}

void Vphysical_regfile___024root___eval_ico(Vphysical_regfile___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vphysical_regfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vphysical_regfile___024root___eval_ico\n"); );
    // Body
    if (vlSelf->__VicoTriggered.at(0U)) {
        Vphysical_regfile___024root___ico_sequent__TOP__0(vlSelf);
    }
}

void Vphysical_regfile___024root___eval_act(Vphysical_regfile___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vphysical_regfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vphysical_regfile___024root___eval_act\n"); );
}

VL_INLINE_OPT void Vphysical_regfile___024root___nba_sequent__TOP__0(Vphysical_regfile___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vphysical_regfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vphysical_regfile___024root___nba_sequent__TOP__0\n"); );
    // Init
    CData/*0:0*/ __Vdlyvset__physical_regfile__DOT__pregs__v0;
    __Vdlyvset__physical_regfile__DOT__pregs__v0 = 0;
    CData/*5:0*/ __Vdlyvdim0__physical_regfile__DOT__pregs__v64;
    __Vdlyvdim0__physical_regfile__DOT__pregs__v64 = 0;
    IData/*31:0*/ __Vdlyvval__physical_regfile__DOT__pregs__v64;
    __Vdlyvval__physical_regfile__DOT__pregs__v64 = 0;
    CData/*0:0*/ __Vdlyvset__physical_regfile__DOT__pregs__v64;
    __Vdlyvset__physical_regfile__DOT__pregs__v64 = 0;
    CData/*5:0*/ __Vdlyvdim0__physical_regfile__DOT__pregs__v65;
    __Vdlyvdim0__physical_regfile__DOT__pregs__v65 = 0;
    IData/*31:0*/ __Vdlyvval__physical_regfile__DOT__pregs__v65;
    __Vdlyvval__physical_regfile__DOT__pregs__v65 = 0;
    CData/*0:0*/ __Vdlyvset__physical_regfile__DOT__pregs__v65;
    __Vdlyvset__physical_regfile__DOT__pregs__v65 = 0;
    IData/*31:0*/ __Vilp;
    // Body
    __Vdlyvset__physical_regfile__DOT__pregs__v0 = 0U;
    __Vdlyvset__physical_regfile__DOT__pregs__v64 = 0U;
    __Vdlyvset__physical_regfile__DOT__pregs__v65 = 0U;
    if (vlSelf->rst) {
        __Vdlyvset__physical_regfile__DOT__pregs__v0 = 1U;
    } else {
        if (((IData)(vlSelf->wen1_i) & (0U != (IData)(vlSelf->waddr1_i)))) {
            __Vdlyvval__physical_regfile__DOT__pregs__v64 
                = vlSelf->wdata1_i;
            __Vdlyvset__physical_regfile__DOT__pregs__v64 = 1U;
            __Vdlyvdim0__physical_regfile__DOT__pregs__v64 
                = vlSelf->waddr1_i;
        }
        if ((((IData)(vlSelf->wen2_i) & (0U != (IData)(vlSelf->waddr2_i))) 
             & (~ ((IData)(vlSelf->wen1_i) & ((IData)(vlSelf->waddr1_i) 
                                              == (IData)(vlSelf->waddr2_i)))))) {
            __Vdlyvval__physical_regfile__DOT__pregs__v65 
                = vlSelf->wdata2_i;
            __Vdlyvset__physical_regfile__DOT__pregs__v65 = 1U;
            __Vdlyvdim0__physical_regfile__DOT__pregs__v65 
                = vlSelf->waddr2_i;
        }
    }
    if (__Vdlyvset__physical_regfile__DOT__pregs__v0) {
        __Vilp = 0U;
        while ((__Vilp <= 0x3fU)) {
            vlSelf->physical_regfile__DOT__pregs[__Vilp] = 0U;
            __Vilp = ((IData)(1U) + __Vilp);
        }
    }
    if (__Vdlyvset__physical_regfile__DOT__pregs__v64) {
        vlSelf->physical_regfile__DOT__pregs[__Vdlyvdim0__physical_regfile__DOT__pregs__v64] 
            = __Vdlyvval__physical_regfile__DOT__pregs__v64;
    }
    if (__Vdlyvset__physical_regfile__DOT__pregs__v65) {
        vlSelf->physical_regfile__DOT__pregs[__Vdlyvdim0__physical_regfile__DOT__pregs__v65] 
            = __Vdlyvval__physical_regfile__DOT__pregs__v65;
    }
    vlSelf->rdata1_o = ((0U == (IData)(vlSelf->raddr1_i))
                         ? 0U : (((((IData)(vlSelf->raddr1_i) 
                                    == (IData)(vlSelf->waddr1_i)) 
                                   & (IData)(vlSelf->wen1_i)) 
                                  & (0U != (IData)(vlSelf->waddr1_i)))
                                  ? vlSelf->wdata1_i
                                  : (((((IData)(vlSelf->raddr1_i) 
                                        == (IData)(vlSelf->waddr2_i)) 
                                       & (IData)(vlSelf->wen2_i)) 
                                      & (0U != (IData)(vlSelf->waddr2_i)))
                                      ? vlSelf->wdata2_i
                                      : vlSelf->physical_regfile__DOT__pregs
                                     [vlSelf->raddr1_i])));
    vlSelf->rdata2_o = ((0U == (IData)(vlSelf->raddr2_i))
                         ? 0U : (((((IData)(vlSelf->raddr2_i) 
                                    == (IData)(vlSelf->waddr1_i)) 
                                   & (IData)(vlSelf->wen1_i)) 
                                  & (0U != (IData)(vlSelf->waddr1_i)))
                                  ? vlSelf->wdata1_i
                                  : (((((IData)(vlSelf->raddr2_i) 
                                        == (IData)(vlSelf->waddr2_i)) 
                                       & (IData)(vlSelf->wen2_i)) 
                                      & (0U != (IData)(vlSelf->waddr2_i)))
                                      ? vlSelf->wdata2_i
                                      : vlSelf->physical_regfile__DOT__pregs
                                     [vlSelf->raddr2_i])));
}

void Vphysical_regfile___024root___eval_nba(Vphysical_regfile___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vphysical_regfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vphysical_regfile___024root___eval_nba\n"); );
    // Body
    if (vlSelf->__VnbaTriggered.at(0U)) {
        Vphysical_regfile___024root___nba_sequent__TOP__0(vlSelf);
    }
}

void Vphysical_regfile___024root___eval_triggers__ico(Vphysical_regfile___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void Vphysical_regfile___024root___dump_triggers__ico(Vphysical_regfile___024root* vlSelf);
#endif  // VL_DEBUG
void Vphysical_regfile___024root___eval_triggers__act(Vphysical_regfile___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void Vphysical_regfile___024root___dump_triggers__act(Vphysical_regfile___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vphysical_regfile___024root___dump_triggers__nba(Vphysical_regfile___024root* vlSelf);
#endif  // VL_DEBUG

void Vphysical_regfile___024root___eval(Vphysical_regfile___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vphysical_regfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vphysical_regfile___024root___eval\n"); );
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
        Vphysical_regfile___024root___eval_triggers__ico(vlSelf);
        if (vlSelf->__VicoTriggered.any()) {
            __VicoContinue = 1U;
            if (VL_UNLIKELY((0x64U < vlSelf->__VicoIterCount))) {
#ifdef VL_DEBUG
                Vphysical_regfile___024root___dump_triggers__ico(vlSelf);
#endif
                VL_FATAL_MT("ooo/physical_regfile.sv", 17, "", "Input combinational region did not converge.");
            }
            vlSelf->__VicoIterCount = ((IData)(1U) 
                                       + vlSelf->__VicoIterCount);
            Vphysical_regfile___024root___eval_ico(vlSelf);
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
            Vphysical_regfile___024root___eval_triggers__act(vlSelf);
            if (vlSelf->__VactTriggered.any()) {
                vlSelf->__VactContinue = 1U;
                if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                    Vphysical_regfile___024root___dump_triggers__act(vlSelf);
#endif
                    VL_FATAL_MT("ooo/physical_regfile.sv", 17, "", "Active region did not converge.");
                }
                vlSelf->__VactIterCount = ((IData)(1U) 
                                           + vlSelf->__VactIterCount);
                __VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
                vlSelf->__VnbaTriggered.set(vlSelf->__VactTriggered);
                Vphysical_regfile___024root___eval_act(vlSelf);
            }
        }
        if (vlSelf->__VnbaTriggered.any()) {
            __VnbaContinue = 1U;
            if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
                Vphysical_regfile___024root___dump_triggers__nba(vlSelf);
#endif
                VL_FATAL_MT("ooo/physical_regfile.sv", 17, "", "NBA region did not converge.");
            }
            __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
            Vphysical_regfile___024root___eval_nba(vlSelf);
        }
    }
}

#ifdef VL_DEBUG
void Vphysical_regfile___024root___eval_debug_assertions(Vphysical_regfile___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vphysical_regfile__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vphysical_regfile___024root___eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((vlSelf->clk & 0xfeU))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY((vlSelf->rst & 0xfeU))) {
        Verilated::overWidthError("rst");}
    if (VL_UNLIKELY((vlSelf->raddr1_i & 0xc0U))) {
        Verilated::overWidthError("raddr1_i");}
    if (VL_UNLIKELY((vlSelf->raddr2_i & 0xc0U))) {
        Verilated::overWidthError("raddr2_i");}
    if (VL_UNLIKELY((vlSelf->wen1_i & 0xfeU))) {
        Verilated::overWidthError("wen1_i");}
    if (VL_UNLIKELY((vlSelf->waddr1_i & 0xc0U))) {
        Verilated::overWidthError("waddr1_i");}
    if (VL_UNLIKELY((vlSelf->wen2_i & 0xfeU))) {
        Verilated::overWidthError("wen2_i");}
    if (VL_UNLIKELY((vlSelf->waddr2_i & 0xc0U))) {
        Verilated::overWidthError("waddr2_i");}
}
#endif  // VL_DEBUG

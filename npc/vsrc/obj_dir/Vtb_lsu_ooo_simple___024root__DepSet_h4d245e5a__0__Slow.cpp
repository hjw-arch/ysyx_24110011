// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_lsu_ooo_simple.h for the primary calling header

#include "verilated.h"

#include "Vtb_lsu_ooo_simple___024root.h"

VL_ATTR_COLD void Vtb_lsu_ooo_simple___024root___eval_static__TOP(Vtb_lsu_ooo_simple___024root* vlSelf);

VL_ATTR_COLD void Vtb_lsu_ooo_simple___024root___eval_static(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___eval_static\n"); );
    // Body
    Vtb_lsu_ooo_simple___024root___eval_static__TOP(vlSelf);
}

VL_ATTR_COLD void Vtb_lsu_ooo_simple___024root___eval_static__TOP(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___eval_static__TOP\n"); );
    // Body
    vlSelf->tb_lsu_ooo_simple__DOT__clk = 0U;
    vlSelf->tb_lsu_ooo_simple__DOT__rst = 1U;
    vlSelf->tb_lsu_ooo_simple__DOT__valid_i = 0U;
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[0U] = 0U;
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U] = 0U;
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[2U] = 0U;
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U] = 0U;
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U] = 0U;
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[5U] = 0U;
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[6U] = 0U;
    vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 0U;
    vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 0U;
}

VL_ATTR_COLD void Vtb_lsu_ooo_simple___024root___eval_final(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___eval_final\n"); );
}

VL_ATTR_COLD void Vtb_lsu_ooo_simple___024root___eval_triggers__stl(Vtb_lsu_ooo_simple___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_lsu_ooo_simple___024root___dump_triggers__stl(Vtb_lsu_ooo_simple___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD void Vtb_lsu_ooo_simple___024root___eval_stl(Vtb_lsu_ooo_simple___024root* vlSelf);

VL_ATTR_COLD void Vtb_lsu_ooo_simple___024root___eval_settle(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___eval_settle\n"); );
    // Init
    CData/*0:0*/ __VstlContinue;
    // Body
    vlSelf->__VstlIterCount = 0U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        __VstlContinue = 0U;
        Vtb_lsu_ooo_simple___024root___eval_triggers__stl(vlSelf);
        if (vlSelf->__VstlTriggered.any()) {
            __VstlContinue = 1U;
            if (VL_UNLIKELY((0x64U < vlSelf->__VstlIterCount))) {
#ifdef VL_DEBUG
                Vtb_lsu_ooo_simple___024root___dump_triggers__stl(vlSelf);
#endif
                VL_FATAL_MT("testbench/tb_lsu_ooo_simple.sv", 8, "", "Settle region did not converge.");
            }
            vlSelf->__VstlIterCount = ((IData)(1U) 
                                       + vlSelf->__VstlIterCount);
            Vtb_lsu_ooo_simple___024root___eval_stl(vlSelf);
        }
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_lsu_ooo_simple___024root___dump_triggers__stl(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VstlTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if (vlSelf->__VstlTriggered.at(0U)) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

extern const VlUnpacked<CData/*2:0*/, 32> Vtb_lsu_ooo_simple__ConstPool__TABLE_h947ad2ce_0;

VL_ATTR_COLD void Vtb_lsu_ooo_simple___024root___stl_sequent__TOP__0(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___stl_sequent__TOP__0\n"); );
    // Init
    CData/*0:0*/ tb_lsu_ooo_simple__DOT__dut__DOT__mem_req_fire;
    tb_lsu_ooo_simple__DOT__dut__DOT__mem_req_fire = 0;
    CData/*4:0*/ __Vtableidx1;
    __Vtableidx1 = 0;
    // Body
    vlSelf->tb_lsu_ooo_simple__DOT__complete_idx_o 
        = (0x1fU & ((vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U] 
                     << 1U) | (vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U] 
                               >> 0x1fU)));
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_resp_fire 
        = ((IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__state) 
           & (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__rdone));
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__is_mem 
        = ((1U == (3U & (vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U] 
                         >> 5U))) | (2U == (3U & (vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U] 
                                                  >> 5U))));
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_valid 
        = ((IData)(vlSelf->tb_lsu_ooo_simple__DOT__valid_i) 
           & (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__is_mem));
    vlSelf->tb_lsu_ooo_simple__DOT__complete_en_o = 
        (((~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__state)) 
          & ((~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__is_mem)) 
             & (IData)(vlSelf->tb_lsu_ooo_simple__DOT__valid_i))) 
         | (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_resp_fire));
    tb_lsu_ooo_simple__DOT__dut__DOT__mem_req_fire 
        = ((~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__state)) 
           & ((IData)(vlSelf->tb_lsu_ooo_simple__DOT__valid_i) 
              & (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__is_mem)));
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__nstate 
        = ((IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__state)
            ? ((IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__state) 
               & (~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_resp_fire)))
            : (IData)(tb_lsu_ooo_simple__DOT__dut__DOT__mem_req_fire));
    vlSelf->tb_lsu_ooo_simple__DOT__ARVALID = (((0U 
                                                 == (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__r_state)) 
                                                & ((IData)(tb_lsu_ooo_simple__DOT__dut__DOT__mem_req_fire) 
                                                   & (0x20U 
                                                      == 
                                                      (0x60U 
                                                       & vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U])))) 
                                               | (1U 
                                                  == (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__r_state)));
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT____VdfgTmp_hff04b70f__0 
        = ((0U == (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__w_state)) 
           & ((IData)(tb_lsu_ooo_simple__DOT__dut__DOT__mem_req_fire) 
              & (0x40U == (0x60U & vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U]))));
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__next_r_state 
        = ((0U == (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__r_state))
            ? ((3U == ((IData)(vlSelf->tb_lsu_ooo_simple__DOT__ARVALID) 
                       << 1U)) ? 2U : ((2U == ((IData)(vlSelf->tb_lsu_ooo_simple__DOT__ARVALID) 
                                               << 1U))
                                        ? 1U : (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__r_state)))
            : (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__r_state));
    __Vtableidx1 = ((((IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT____VdfgTmp_hff04b70f__0) 
                      | ((3U == (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__w_state)) 
                         | (1U == (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__w_state)))) 
                     << 4U) | ((((IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT____VdfgTmp_hff04b70f__0) 
                                 | ((2U == (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__w_state)) 
                                    | (1U == (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__w_state)))) 
                                << 3U) | (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__w_state)));
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__next_w_state 
        = Vtb_lsu_ooo_simple__ConstPool__TABLE_h947ad2ce_0
        [__Vtableidx1];
}

VL_ATTR_COLD void Vtb_lsu_ooo_simple___024root___eval_stl(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___eval_stl\n"); );
    // Body
    if (vlSelf->__VstlTriggered.at(0U)) {
        Vtb_lsu_ooo_simple___024root___stl_sequent__TOP__0(vlSelf);
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_lsu_ooo_simple___024root___dump_triggers__act(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VactTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if (vlSelf->__VactTriggered.at(0U)) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge tb_lsu_ooo_simple.clk)\n");
    }
    if (vlSelf->__VactTriggered.at(1U)) {
        VL_DBG_MSGF("         'act' region trigger index 1 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_lsu_ooo_simple___024root___dump_triggers__nba(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___dump_triggers__nba\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VnbaTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if (vlSelf->__VnbaTriggered.at(0U)) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge tb_lsu_ooo_simple.clk)\n");
    }
    if (vlSelf->__VnbaTriggered.at(1U)) {
        VL_DBG_MSGF("         'nba' region trigger index 1 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtb_lsu_ooo_simple___024root___ctor_var_reset(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->tb_lsu_ooo_simple__DOT__clk = VL_RAND_RESET_I(1);
    vlSelf->tb_lsu_ooo_simple__DOT__rst = VL_RAND_RESET_I(1);
    vlSelf->tb_lsu_ooo_simple__DOT__valid_i = VL_RAND_RESET_I(1);
    VL_RAND_RESET_W(196, vlSelf->tb_lsu_ooo_simple__DOT__data_i);
    vlSelf->tb_lsu_ooo_simple__DOT__complete_en_o = VL_RAND_RESET_I(1);
    vlSelf->tb_lsu_ooo_simple__DOT__complete_idx_o = VL_RAND_RESET_I(5);
    vlSelf->tb_lsu_ooo_simple__DOT__ARVALID = VL_RAND_RESET_I(1);
    vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 0;
    vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 0;
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__state = VL_RAND_RESET_I(1);
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__nstate = VL_RAND_RESET_I(1);
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__is_mem = VL_RAND_RESET_I(1);
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_valid = VL_RAND_RESET_I(1);
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_resp_fire = VL_RAND_RESET_I(1);
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__r_state = VL_RAND_RESET_I(2);
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__next_r_state = VL_RAND_RESET_I(2);
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__w_state = VL_RAND_RESET_I(3);
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__next_w_state = VL_RAND_RESET_I(3);
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__rdone = VL_RAND_RESET_I(1);
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT____VdfgTmp_hff04b70f__0 = 0;
    vlSelf->__Vtrigrprev__TOP__tb_lsu_ooo_simple__DOT__clk = VL_RAND_RESET_I(1);
}

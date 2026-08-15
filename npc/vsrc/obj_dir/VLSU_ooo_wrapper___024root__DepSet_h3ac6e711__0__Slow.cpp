// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VLSU_ooo_wrapper.h for the primary calling header

#include "verilated.h"

#include "VLSU_ooo_wrapper___024root.h"

VL_ATTR_COLD void VLSU_ooo_wrapper___024root___eval_static(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___eval_static\n"); );
}

VL_ATTR_COLD void VLSU_ooo_wrapper___024root___eval_initial__TOP(VLSU_ooo_wrapper___024root* vlSelf);

VL_ATTR_COLD void VLSU_ooo_wrapper___024root___eval_initial(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___eval_initial\n"); );
    // Body
    VLSU_ooo_wrapper___024root___eval_initial__TOP(vlSelf);
    vlSelf->__Vtrigrprev__TOP__clk = vlSelf->clk;
}

VL_ATTR_COLD void VLSU_ooo_wrapper___024root___eval_initial__TOP(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___eval_initial__TOP\n"); );
    // Body
    vlSelf->complete_exception_o = 0U;
    vlSelf->complete_cause_o = 0U;
    vlSelf->ARBURST = 1U;
    vlSelf->AWBURST = 1U;
    vlSelf->AWLEN = 0U;
    vlSelf->WLAST = 1U;
    vlSelf->ARID = 0U;
    vlSelf->AWID = 0U;
    vlSelf->ARLEN = 0U;
}

VL_ATTR_COLD void VLSU_ooo_wrapper___024root___eval_final(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___eval_final\n"); );
}

VL_ATTR_COLD void VLSU_ooo_wrapper___024root___eval_triggers__stl(VLSU_ooo_wrapper___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void VLSU_ooo_wrapper___024root___dump_triggers__stl(VLSU_ooo_wrapper___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD void VLSU_ooo_wrapper___024root___eval_stl(VLSU_ooo_wrapper___024root* vlSelf);

VL_ATTR_COLD void VLSU_ooo_wrapper___024root___eval_settle(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___eval_settle\n"); );
    // Init
    CData/*0:0*/ __VstlContinue;
    // Body
    vlSelf->__VstlIterCount = 0U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        __VstlContinue = 0U;
        VLSU_ooo_wrapper___024root___eval_triggers__stl(vlSelf);
        if (vlSelf->__VstlTriggered.any()) {
            __VstlContinue = 1U;
            if (VL_UNLIKELY((0x64U < vlSelf->__VstlIterCount))) {
#ifdef VL_DEBUG
                VLSU_ooo_wrapper___024root___dump_triggers__stl(vlSelf);
#endif
                VL_FATAL_MT("testbench/LSU_ooo_wrapper.sv", 5, "", "Settle region did not converge.");
            }
            vlSelf->__VstlIterCount = ((IData)(1U) 
                                       + vlSelf->__VstlIterCount);
            VLSU_ooo_wrapper___024root___eval_stl(vlSelf);
        }
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void VLSU_ooo_wrapper___024root___dump_triggers__stl(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VstlTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if (vlSelf->__VstlTriggered.at(0U)) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

extern const VlUnpacked<CData/*1:0*/, 128> VLSU_ooo_wrapper__ConstPool__TABLE_h755d45ba_0;
extern const VlUnpacked<CData/*2:0*/, 512> VLSU_ooo_wrapper__ConstPool__TABLE_hf15d7c38_0;

VL_ATTR_COLD void VLSU_ooo_wrapper___024root___stl_sequent__TOP__0(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___stl_sequent__TOP__0\n"); );
    // Init
    IData/*31:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__axi_rdata;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__axi_rdata = 0;
    CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_req_fire;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_req_fire = 0;
    CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hff04b70f__0;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hff04b70f__0 = 0;
    CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hfd404640__0;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hfd404640__0 = 0;
    CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_ha0ecd8ba__0;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_ha0ecd8ba__0 = 0;
    CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hc9a78090__0;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hc9a78090__0 = 0;
    CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h4ea27b40__0;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h4ea27b40__0 = 0;
    CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hdd5895cc__0;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hdd5895cc__0 = 0;
    CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h456086cc__0;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h456086cc__0 = 0;
    CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h48b503c5__0;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h48b503c5__0 = 0;
    CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hc060bdda__0;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hc060bdda__0 = 0;
    CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hb11ddb42__0;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hb11ddb42__0 = 0;
    CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h68c98547__0;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h68c98547__0 = 0;
    CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_he34aa593__0;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_he34aa593__0 = 0;
    CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h5a121f24__0;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h5a121f24__0 = 0;
    CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hca322947__0;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hca322947__0 = 0;
    CData/*6:0*/ __Vtableidx1;
    __Vtableidx1 = 0;
    SData/*8:0*/ __Vtableidx2;
    __Vtableidx2 = 0;
    // Body
    vlSelf->RREADY = (2U == (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__r_state));
    vlSelf->BREADY = (4U == (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__w_state));
    vlSelf->LSU_ooo_wrapper__DOT__data_packed[2U] = 
        ((0x1ffffffU & vlSelf->LSU_ooo_wrapper__DOT__data_packed[2U]) 
         | ((IData)((((QData)((IData)(vlSelf->rob_idx_i)) 
                      << 0x26U) | (((QData)((IData)(vlSelf->phys_rd_i)) 
                                    << 0x20U) | (QData)((IData)(vlSelf->rs1_data_i))))) 
            << 0x19U));
    vlSelf->LSU_ooo_wrapper__DOT__data_packed[3U] = 
        (((IData)((((QData)((IData)(vlSelf->rob_idx_i)) 
                    << 0x26U) | (((QData)((IData)(vlSelf->phys_rd_i)) 
                                  << 0x20U) | (QData)((IData)(vlSelf->rs1_data_i))))) 
          >> 7U) | ((IData)(((((QData)((IData)(vlSelf->rob_idx_i)) 
                               << 0x26U) | (((QData)((IData)(vlSelf->phys_rd_i)) 
                                             << 0x20U) 
                                            | (QData)((IData)(vlSelf->rs1_data_i)))) 
                             >> 0x20U)) << 0x19U));
    vlSelf->LSU_ooo_wrapper__DOT__data_packed[4U] = 
        (((0x1fffff0U & ((IData)((((QData)((IData)(vlSelf->pc_i)) 
                                   << 0x20U) | (QData)((IData)(vlSelf->inst_i)))) 
                         << 4U)) | ((IData)(((((QData)((IData)(vlSelf->rob_idx_i)) 
                                               << 0x26U) 
                                              | (((QData)((IData)(vlSelf->phys_rd_i)) 
                                                  << 0x20U) 
                                                 | (QData)((IData)(vlSelf->rs1_data_i)))) 
                                             >> 0x20U)) 
                                    >> 7U)) | (0xfe000000U 
                                               & ((IData)(
                                                          (((QData)((IData)(vlSelf->pc_i)) 
                                                            << 0x20U) 
                                                           | (QData)((IData)(vlSelf->inst_i)))) 
                                                  << 4U)));
    vlSelf->LSU_ooo_wrapper__DOT__data_packed[5U] = 
        ((((IData)((((QData)((IData)(vlSelf->pc_i)) 
                     << 0x20U) | (QData)((IData)(vlSelf->inst_i)))) 
           >> 0x1cU) | (0x1fffff0U & ((IData)(((((QData)((IData)(vlSelf->pc_i)) 
                                                 << 0x20U) 
                                                | (QData)((IData)(vlSelf->inst_i))) 
                                               >> 0x20U)) 
                                      << 4U))) | (0xfe000000U 
                                                  & ((IData)(
                                                             ((((QData)((IData)(vlSelf->pc_i)) 
                                                                << 0x20U) 
                                                               | (QData)((IData)(vlSelf->inst_i))) 
                                                              >> 0x20U)) 
                                                     << 4U)));
    vlSelf->LSU_ooo_wrapper__DOT__data_packed[6U] = 
        ((IData)(((((QData)((IData)(vlSelf->pc_i)) 
                    << 0x20U) | (QData)((IData)(vlSelf->inst_i))) 
                  >> 0x20U)) >> 0x1cU);
    vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U] = 
        ((0x7fffffU & vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U]) 
         | ((IData)((((QData)((IData)(vlSelf->rs2_data_i)) 
                      << 2U) | (QData)((IData)((((IData)(vlSelf->pred_taken_i) 
                                                 << 1U) 
                                                | (IData)(vlSelf->rd_wen_i)))))) 
            << 0x17U));
    vlSelf->LSU_ooo_wrapper__DOT__data_packed[2U] = 
        ((0xfe000000U & vlSelf->LSU_ooo_wrapper__DOT__data_packed[2U]) 
         | (((IData)((((QData)((IData)(vlSelf->rs2_data_i)) 
                       << 2U) | (QData)((IData)((((IData)(vlSelf->pred_taken_i) 
                                                  << 1U) 
                                                 | (IData)(vlSelf->rd_wen_i)))))) 
             >> 9U) | ((IData)(((((QData)((IData)(vlSelf->rs2_data_i)) 
                                  << 2U) | (QData)((IData)(
                                                           (((IData)(vlSelf->pred_taken_i) 
                                                             << 1U) 
                                                            | (IData)(vlSelf->rd_wen_i))))) 
                                >> 0x20U)) << 0x17U)));
    vlSelf->LSU_ooo_wrapper__DOT__data_packed[0U] = vlSelf->imm_i;
    vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U] = 
        ((0xfffe007fU & vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U]) 
         | (0xffffff80U & (((IData)(vlSelf->alu_op_i) 
                            << 0xdU) | (((IData)(vlSelf->alu_src_i) 
                                         << 0xbU) | 
                                        (((IData)(vlSelf->cfi_type_i) 
                                          << 9U) | 
                                         (0x180U & 
                                          ((IData)(vlSelf->br_cond_i) 
                                           << 7U)))))));
    vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U] = 
        (0xffe1ffffU & vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U]);
    vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U] = 
        ((0xffffff80U & vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U]) 
         | ((0x60U & ((IData)(vlSelf->mem_cmd_i) << 5U)) 
            | (((IData)(vlSelf->csr_cmd_i) << 3U) | 
               (((IData)(vlSelf->priv_redir_i) << 1U) 
                | (IData)(vlSelf->fence_i_i)))));
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_resp_fire 
        = (((IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__rdone) 
            | ((IData)(vlSelf->BVALID) & (IData)(vlSelf->BREADY))) 
           & (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__state));
    vlSelf->complete_idx_o = (0x1fU & ((vlSelf->LSU_ooo_wrapper__DOT__data_packed[4U] 
                                        << 1U) | (vlSelf->LSU_ooo_wrapper__DOT__data_packed[3U] 
                                                  >> 0x1fU)));
    vlSelf->ARSIZE = (3U & (vlSelf->LSU_ooo_wrapper__DOT__data_packed[4U] 
                            >> 0x10U));
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_he34aa593__0 
        = (IData)((0x20000U == (0x30000U & vlSelf->LSU_ooo_wrapper__DOT__data_packed[4U])));
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hb11ddb42__0 
        = (IData)((0x10000U == (0x30000U & vlSelf->LSU_ooo_wrapper__DOT__data_packed[4U])));
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__is_mem 
        = ((1U == (3U & (vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U] 
                         >> 5U))) | (2U == (3U & (vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U] 
                                                  >> 5U))));
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h48b503c5__0 
        = (IData)((0U == (0x30000U & vlSelf->LSU_ooo_wrapper__DOT__data_packed[4U])));
    vlSelf->ARADDR = (((vlSelf->LSU_ooo_wrapper__DOT__data_packed[3U] 
                        << 7U) | (vlSelf->LSU_ooo_wrapper__DOT__data_packed[2U] 
                                  >> 0x19U)) + vlSelf->LSU_ooo_wrapper__DOT__data_packed[0U]);
    vlSelf->AWSIZE = vlSelf->ARSIZE;
    vlSelf->complete_en_o = (((~ (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__state)) 
                              & ((~ (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__is_mem)) 
                                 & (IData)(vlSelf->valid_i))) 
                             | (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_resp_fire));
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_valid 
        = ((IData)(vlSelf->valid_i) & (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__is_mem));
    vlSelf->AWADDR = vlSelf->ARADDR;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__axi_rdata = (
                                                   (2U 
                                                    & (IData)(vlSelf->ARSIZE))
                                                    ? 
                                                   ((1U 
                                                     & (IData)(vlSelf->ARSIZE))
                                                     ? 0U
                                                     : 
                                                    ((2U 
                                                      & vlSelf->ARADDR)
                                                      ? 0U
                                                      : 
                                                     ((1U 
                                                       & vlSelf->ARADDR)
                                                       ? 0U
                                                       : vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__RDATA_TEMP)))
                                                    : 
                                                   ((1U 
                                                     & (IData)(vlSelf->ARSIZE))
                                                     ? 
                                                    ((2U 
                                                      & vlSelf->ARADDR)
                                                      ? 
                                                     ((1U 
                                                       & vlSelf->ARADDR)
                                                       ? 0U
                                                       : 
                                                      (vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__RDATA_TEMP 
                                                       >> 0x10U))
                                                      : 
                                                     ((1U 
                                                       & vlSelf->ARADDR)
                                                       ? 0U
                                                       : 
                                                      (0xffffU 
                                                       & vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__RDATA_TEMP)))
                                                     : 
                                                    ((2U 
                                                      & vlSelf->ARADDR)
                                                      ? 
                                                     ((1U 
                                                       & vlSelf->ARADDR)
                                                       ? 
                                                      (vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__RDATA_TEMP 
                                                       >> 0x18U)
                                                       : 
                                                      (0xffU 
                                                       & (vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__RDATA_TEMP 
                                                          >> 0x10U)))
                                                      : 
                                                     ((1U 
                                                       & vlSelf->ARADDR)
                                                       ? 
                                                      (0xffU 
                                                       & (vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__RDATA_TEMP 
                                                          >> 8U))
                                                       : 
                                                      (0xffU 
                                                       & vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__RDATA_TEMP)))));
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h68c98547__0 
        = ((~ (vlSelf->ARADDR >> 1U)) & (IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hb11ddb42__0));
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hca322947__0 
        = ((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hb11ddb42__0) 
           & (vlSelf->ARADDR >> 1U));
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hc060bdda__0 
        = ((~ (vlSelf->ARADDR >> 1U)) & (IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h48b503c5__0));
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h5a121f24__0 
        = ((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h48b503c5__0) 
           & (vlSelf->ARADDR >> 1U));
    vlSelf->ready_o = (1U & (((~ (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__state)) 
                              & (~ (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_valid))) 
                             | (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_resp_fire)));
    LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_req_fire 
        = ((~ (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__state)) 
           & (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_valid));
    vlSelf->complete_data_o = ((1U == (3U & (vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U] 
                                             >> 5U)))
                                ? ((0x40000U & vlSelf->LSU_ooo_wrapper__DOT__data_packed[4U])
                                    ? ((0x20000U & 
                                        vlSelf->LSU_ooo_wrapper__DOT__data_packed[4U])
                                        ? 0U : ((0x10000U 
                                                 & vlSelf->LSU_ooo_wrapper__DOT__data_packed[4U])
                                                 ? 
                                                (0xffffU 
                                                 & LSU_ooo_wrapper__DOT__u_lsu__DOT__axi_rdata)
                                                 : 
                                                (0xffU 
                                                 & LSU_ooo_wrapper__DOT__u_lsu__DOT__axi_rdata)))
                                    : ((0x20000U & 
                                        vlSelf->LSU_ooo_wrapper__DOT__data_packed[4U])
                                        ? ((0x10000U 
                                            & vlSelf->LSU_ooo_wrapper__DOT__data_packed[4U])
                                            ? 0U : LSU_ooo_wrapper__DOT__u_lsu__DOT__axi_rdata)
                                        : ((0x10000U 
                                            & vlSelf->LSU_ooo_wrapper__DOT__data_packed[4U])
                                            ? (((- (IData)(
                                                           (1U 
                                                            & (LSU_ooo_wrapper__DOT__u_lsu__DOT__axi_rdata 
                                                               >> 0xfU)))) 
                                                << 0x10U) 
                                               | (0xffffU 
                                                  & LSU_ooo_wrapper__DOT__u_lsu__DOT__axi_rdata))
                                            : (((- (IData)(
                                                           (1U 
                                                            & (LSU_ooo_wrapper__DOT__u_lsu__DOT__axi_rdata 
                                                               >> 7U)))) 
                                                << 8U) 
                                               | (0xffU 
                                                  & LSU_ooo_wrapper__DOT__u_lsu__DOT__axi_rdata)))))
                                : 0U);
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h456086cc__0 
        = ((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h68c98547__0) 
           | (IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_he34aa593__0));
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hdd5895cc__0 
        = ((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hca322947__0) 
           | (IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_he34aa593__0));
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hc9a78090__0 
        = ((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hc060bdda__0) 
           & vlSelf->ARADDR);
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h4ea27b40__0 
        = ((~ vlSelf->ARADDR) & (IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hc060bdda__0));
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hfd404640__0 
        = ((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h5a121f24__0) 
           & vlSelf->ARADDR);
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_ha0ecd8ba__0 
        = ((~ vlSelf->ARADDR) & (IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h5a121f24__0));
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__nstate 
        = ((IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__state)
            ? ((IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__state) 
               & (~ (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_resp_fire)))
            : (IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_req_fire));
    vlSelf->ARVALID = (((0U == (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__r_state)) 
                        & ((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_req_fire) 
                           & (0x20U == (0x60U & vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U])))) 
                       | (1U == (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__r_state)));
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hff04b70f__0 
        = ((0U == (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__w_state)) 
           & ((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_req_fire) 
              & (0x40U == (0x60U & vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U]))));
    vlSelf->WSTRB = ((((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hfd404640__0) 
                       | (IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hdd5895cc__0)) 
                      << 3U) | ((((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_ha0ecd8ba__0) 
                                  | (IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hdd5895cc__0)) 
                                 << 2U) | ((((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hc9a78090__0) 
                                             | (IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h456086cc__0)) 
                                            << 1U) 
                                           | ((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h4ea27b40__0) 
                                              | (IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h456086cc__0)))));
    vlSelf->WDATA = ((0xff000000U & ((((- (IData)((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hfd404640__0))) 
                                       << 0x18U) & 
                                      ((vlSelf->LSU_ooo_wrapper__DOT__data_packed[2U] 
                                        << 0x1fU) | 
                                       (0x7f000000U 
                                        & (vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U] 
                                           >> 1U)))) 
                                     | (0xff000000U 
                                        & ((((- (IData)((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hca322947__0))) 
                                             << 0x18U) 
                                            & (vlSelf->LSU_ooo_wrapper__DOT__data_packed[2U] 
                                               << 0x17U)) 
                                           | (((- (IData)((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_he34aa593__0))) 
                                               << 0x18U) 
                                              & (vlSelf->LSU_ooo_wrapper__DOT__data_packed[2U] 
                                                 << 7U)))))) 
                     | ((0xff0000U & ((((- (IData)((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_ha0ecd8ba__0))) 
                                        << 0x10U) & 
                                       ((vlSelf->LSU_ooo_wrapper__DOT__data_packed[2U] 
                                         << 0x17U) 
                                        | (0x7f0000U 
                                           & (vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U] 
                                              >> 9U)))) 
                                      | ((((- (IData)((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hca322947__0))) 
                                           << 0x10U) 
                                          & ((vlSelf->LSU_ooo_wrapper__DOT__data_packed[2U] 
                                              << 0x17U) 
                                             | (0x7f0000U 
                                                & (vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U] 
                                                   >> 9U)))) 
                                         | (0xffff0000U 
                                            & (((- (IData)((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_he34aa593__0))) 
                                                << 0x10U) 
                                               & (vlSelf->LSU_ooo_wrapper__DOT__data_packed[2U] 
                                                  << 7U)))))) 
                        | ((0xff00U & ((((- (IData)((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hc9a78090__0))) 
                                         << 8U) & (
                                                   (vlSelf->LSU_ooo_wrapper__DOT__data_packed[2U] 
                                                    << 0xfU) 
                                                   | (0x7f00U 
                                                      & (vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U] 
                                                         >> 0x11U)))) 
                                       | (0xffffff00U 
                                          & ((((- (IData)((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h68c98547__0))) 
                                               | (- (IData)((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_he34aa593__0)))) 
                                              << 8U) 
                                             & (vlSelf->LSU_ooo_wrapper__DOT__data_packed[2U] 
                                                << 7U))))) 
                           | (0xffU & (((- (IData)((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h4ea27b40__0))) 
                                        | ((- (IData)((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_h68c98547__0))) 
                                           | (- (IData)((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_he34aa593__0))))) 
                                       & ((vlSelf->LSU_ooo_wrapper__DOT__data_packed[2U] 
                                           << 7U) | 
                                          (vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U] 
                                           >> 0x19U)))))));
    __Vtableidx1 = (((IData)(vlSelf->RLAST) << 6U) 
                    | (((IData)(vlSelf->RREADY) << 5U) 
                       | (((IData)(vlSelf->RVALID) 
                           << 4U) | (((IData)(vlSelf->ARREADY) 
                                      << 3U) | (((IData)(vlSelf->ARVALID) 
                                                 << 2U) 
                                                | (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__r_state))))));
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__next_r_state 
        = VLSU_ooo_wrapper__ConstPool__TABLE_h755d45ba_0
        [__Vtableidx1];
    vlSelf->AWVALID = ((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hff04b70f__0) 
                       | ((2U == (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__w_state)) 
                          | (1U == (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__w_state))));
    vlSelf->WVALID = ((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hff04b70f__0) 
                      | ((3U == (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__w_state)) 
                         | (1U == (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__w_state))));
    __Vtableidx2 = (((IData)(vlSelf->WVALID) << 8U) 
                    | (((IData)(vlSelf->AWVALID) << 7U) 
                       | (((IData)(vlSelf->AWREADY) 
                           << 6U) | (((IData)(vlSelf->WREADY) 
                                      << 5U) | (((IData)(vlSelf->BREADY) 
                                                 << 4U) 
                                                | (((IData)(vlSelf->BVALID) 
                                                    << 3U) 
                                                   | (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__w_state)))))));
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__next_w_state 
        = VLSU_ooo_wrapper__ConstPool__TABLE_hf15d7c38_0
        [__Vtableidx2];
}

VL_ATTR_COLD void VLSU_ooo_wrapper___024root___eval_stl(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___eval_stl\n"); );
    // Body
    if (vlSelf->__VstlTriggered.at(0U)) {
        VLSU_ooo_wrapper___024root___stl_sequent__TOP__0(vlSelf);
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void VLSU_ooo_wrapper___024root___dump_triggers__ico(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___dump_triggers__ico\n"); );
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
VL_ATTR_COLD void VLSU_ooo_wrapper___024root___dump_triggers__act(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___dump_triggers__act\n"); );
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
VL_ATTR_COLD void VLSU_ooo_wrapper___024root___dump_triggers__nba(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___dump_triggers__nba\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VnbaTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if (vlSelf->__VnbaTriggered.at(0U)) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge clk)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void VLSU_ooo_wrapper___024root___ctor_var_reset(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->clk = VL_RAND_RESET_I(1);
    vlSelf->rst = VL_RAND_RESET_I(1);
    vlSelf->valid_i = VL_RAND_RESET_I(1);
    vlSelf->pc_i = VL_RAND_RESET_I(32);
    vlSelf->inst_i = VL_RAND_RESET_I(32);
    vlSelf->rob_idx_i = VL_RAND_RESET_I(5);
    vlSelf->phys_rd_i = VL_RAND_RESET_I(6);
    vlSelf->rs1_data_i = VL_RAND_RESET_I(32);
    vlSelf->rs2_data_i = VL_RAND_RESET_I(32);
    vlSelf->pred_taken_i = VL_RAND_RESET_I(1);
    vlSelf->rd_wen_i = VL_RAND_RESET_I(1);
    vlSelf->alu_op_i = VL_RAND_RESET_I(4);
    vlSelf->alu_src_i = VL_RAND_RESET_I(2);
    vlSelf->cfi_type_i = VL_RAND_RESET_I(2);
    vlSelf->br_cond_i = VL_RAND_RESET_I(3);
    vlSelf->mem_cmd_i = VL_RAND_RESET_I(3);
    vlSelf->csr_cmd_i = VL_RAND_RESET_I(2);
    vlSelf->priv_redir_i = VL_RAND_RESET_I(2);
    vlSelf->fence_i_i = VL_RAND_RESET_I(1);
    vlSelf->imm_i = VL_RAND_RESET_I(32);
    vlSelf->ready_o = VL_RAND_RESET_I(1);
    vlSelf->complete_en_o = VL_RAND_RESET_I(1);
    vlSelf->complete_idx_o = VL_RAND_RESET_I(5);
    vlSelf->complete_data_o = VL_RAND_RESET_I(32);
    vlSelf->complete_exception_o = VL_RAND_RESET_I(1);
    vlSelf->complete_cause_o = VL_RAND_RESET_I(4);
    vlSelf->ARADDR = VL_RAND_RESET_I(32);
    vlSelf->ARID = VL_RAND_RESET_I(4);
    vlSelf->ARLEN = VL_RAND_RESET_I(8);
    vlSelf->ARSIZE = VL_RAND_RESET_I(3);
    vlSelf->ARBURST = VL_RAND_RESET_I(2);
    vlSelf->ARVALID = VL_RAND_RESET_I(1);
    vlSelf->ARREADY = VL_RAND_RESET_I(1);
    vlSelf->RID = VL_RAND_RESET_I(4);
    vlSelf->RDATA = VL_RAND_RESET_I(32);
    vlSelf->RRESP = VL_RAND_RESET_I(2);
    vlSelf->RVALID = VL_RAND_RESET_I(1);
    vlSelf->RLAST = VL_RAND_RESET_I(1);
    vlSelf->RREADY = VL_RAND_RESET_I(1);
    vlSelf->AWADDR = VL_RAND_RESET_I(32);
    vlSelf->AWLEN = VL_RAND_RESET_I(8);
    vlSelf->AWSIZE = VL_RAND_RESET_I(3);
    vlSelf->AWID = VL_RAND_RESET_I(4);
    vlSelf->AWBURST = VL_RAND_RESET_I(2);
    vlSelf->AWVALID = VL_RAND_RESET_I(1);
    vlSelf->AWREADY = VL_RAND_RESET_I(1);
    vlSelf->WDATA = VL_RAND_RESET_I(32);
    vlSelf->WLAST = VL_RAND_RESET_I(1);
    vlSelf->WSTRB = VL_RAND_RESET_I(4);
    vlSelf->WVALID = VL_RAND_RESET_I(1);
    vlSelf->WREADY = VL_RAND_RESET_I(1);
    vlSelf->BID = VL_RAND_RESET_I(4);
    vlSelf->BRESP = VL_RAND_RESET_I(2);
    vlSelf->BVALID = VL_RAND_RESET_I(1);
    vlSelf->BREADY = VL_RAND_RESET_I(1);
    VL_RAND_RESET_W(196, vlSelf->LSU_ooo_wrapper__DOT__data_packed);
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__state = VL_RAND_RESET_I(1);
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__nstate = VL_RAND_RESET_I(1);
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__is_mem = VL_RAND_RESET_I(1);
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_valid = VL_RAND_RESET_I(1);
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_resp_fire = VL_RAND_RESET_I(1);
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__r_state = VL_RAND_RESET_I(2);
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__next_r_state = VL_RAND_RESET_I(2);
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__w_state = VL_RAND_RESET_I(3);
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__next_w_state = VL_RAND_RESET_I(3);
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__RDATA_TEMP = VL_RAND_RESET_I(32);
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__rdone = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigrprev__TOP__clk = VL_RAND_RESET_I(1);
}

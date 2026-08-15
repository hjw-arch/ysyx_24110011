// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VLSU_ooo_wrapper.h for the primary calling header

#include "verilated.h"

#include "VLSU_ooo_wrapper___024root.h"

extern const VlUnpacked<CData/*1:0*/, 128> VLSU_ooo_wrapper__ConstPool__TABLE_h755d45ba_0;
extern const VlUnpacked<CData/*2:0*/, 512> VLSU_ooo_wrapper__ConstPool__TABLE_hf15d7c38_0;

VL_INLINE_OPT void VLSU_ooo_wrapper___024root___ico_sequent__TOP__0(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___ico_sequent__TOP__0\n"); );
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
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_resp_fire 
        = (((IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__rdone) 
            | ((IData)(vlSelf->BVALID) & (IData)(vlSelf->BREADY))) 
           & (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__state));
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

void VLSU_ooo_wrapper___024root___eval_ico(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___eval_ico\n"); );
    // Body
    if (vlSelf->__VicoTriggered.at(0U)) {
        VLSU_ooo_wrapper___024root___ico_sequent__TOP__0(vlSelf);
    }
}

void VLSU_ooo_wrapper___024root___eval_act(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___eval_act\n"); );
}

VL_INLINE_OPT void VLSU_ooo_wrapper___024root___nba_sequent__TOP__0(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___nba_sequent__TOP__0\n"); );
    // Body
    if (((IData)(vlSelf->RVALID) & (IData)(vlSelf->RREADY))) {
        vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__RDATA_TEMP 
            = vlSelf->RDATA;
        vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__rdone 
            = vlSelf->RLAST;
    } else {
        vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__RDATA_TEMP 
            = vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__RDATA_TEMP;
        vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__rdone = 0U;
    }
    if (vlSelf->rst) {
        vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__r_state = 0U;
        vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__w_state = 0U;
    } else {
        vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__r_state 
            = vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__next_r_state;
        vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__w_state 
            = vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__next_w_state;
    }
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__state 
        = ((~ (IData)(vlSelf->rst)) & (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__nstate));
    vlSelf->RREADY = (2U == (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__r_state));
    vlSelf->BREADY = (4U == (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__w_state));
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_resp_fire 
        = (((IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__rdone) 
            | ((IData)(vlSelf->BVALID) & (IData)(vlSelf->BREADY))) 
           & (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__state));
}

VL_INLINE_OPT void VLSU_ooo_wrapper___024root___nba_sequent__TOP__1(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___nba_sequent__TOP__1\n"); );
    // Init
    IData/*31:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__axi_rdata;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__axi_rdata = 0;
    CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_req_fire;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_req_fire = 0;
    CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hff04b70f__0;
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hff04b70f__0 = 0;
    CData/*6:0*/ __Vtableidx1;
    __Vtableidx1 = 0;
    SData/*8:0*/ __Vtableidx2;
    __Vtableidx2 = 0;
    // Body
    vlSelf->complete_en_o = (((~ (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__state)) 
                              & ((~ (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__is_mem)) 
                                 & (IData)(vlSelf->valid_i))) 
                             | (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_resp_fire));
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
    LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_req_fire 
        = ((~ (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__state)) 
           & (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_valid));
    vlSelf->ready_o = (1U & (((~ (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__state)) 
                              & (~ (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_valid))) 
                             | (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_resp_fire)));
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
    vlSelf->ARVALID = (((0U == (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__r_state)) 
                        & ((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_req_fire) 
                           & (0x20U == (0x60U & vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U])))) 
                       | (1U == (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__r_state)));
    LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT____VdfgTmp_hff04b70f__0 
        = ((0U == (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__w_state)) 
           & ((IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_req_fire) 
              & (0x40U == (0x60U & vlSelf->LSU_ooo_wrapper__DOT__data_packed[1U]))));
    vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__nstate 
        = ((IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__state)
            ? ((IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__state) 
               & (~ (IData)(vlSelf->LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_resp_fire)))
            : (IData)(LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_req_fire));
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

void VLSU_ooo_wrapper___024root___eval_nba(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___eval_nba\n"); );
    // Body
    if (vlSelf->__VnbaTriggered.at(0U)) {
        VLSU_ooo_wrapper___024root___nba_sequent__TOP__0(vlSelf);
        VLSU_ooo_wrapper___024root___nba_sequent__TOP__1(vlSelf);
    }
}

void VLSU_ooo_wrapper___024root___eval_triggers__ico(VLSU_ooo_wrapper___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void VLSU_ooo_wrapper___024root___dump_triggers__ico(VLSU_ooo_wrapper___024root* vlSelf);
#endif  // VL_DEBUG
void VLSU_ooo_wrapper___024root___eval_triggers__act(VLSU_ooo_wrapper___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void VLSU_ooo_wrapper___024root___dump_triggers__act(VLSU_ooo_wrapper___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void VLSU_ooo_wrapper___024root___dump_triggers__nba(VLSU_ooo_wrapper___024root* vlSelf);
#endif  // VL_DEBUG

void VLSU_ooo_wrapper___024root___eval(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___eval\n"); );
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
        VLSU_ooo_wrapper___024root___eval_triggers__ico(vlSelf);
        if (vlSelf->__VicoTriggered.any()) {
            __VicoContinue = 1U;
            if (VL_UNLIKELY((0x64U < vlSelf->__VicoIterCount))) {
#ifdef VL_DEBUG
                VLSU_ooo_wrapper___024root___dump_triggers__ico(vlSelf);
#endif
                VL_FATAL_MT("testbench/LSU_ooo_wrapper.sv", 5, "", "Input combinational region did not converge.");
            }
            vlSelf->__VicoIterCount = ((IData)(1U) 
                                       + vlSelf->__VicoIterCount);
            VLSU_ooo_wrapper___024root___eval_ico(vlSelf);
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
            VLSU_ooo_wrapper___024root___eval_triggers__act(vlSelf);
            if (vlSelf->__VactTriggered.any()) {
                vlSelf->__VactContinue = 1U;
                if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                    VLSU_ooo_wrapper___024root___dump_triggers__act(vlSelf);
#endif
                    VL_FATAL_MT("testbench/LSU_ooo_wrapper.sv", 5, "", "Active region did not converge.");
                }
                vlSelf->__VactIterCount = ((IData)(1U) 
                                           + vlSelf->__VactIterCount);
                __VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
                vlSelf->__VnbaTriggered.set(vlSelf->__VactTriggered);
                VLSU_ooo_wrapper___024root___eval_act(vlSelf);
            }
        }
        if (vlSelf->__VnbaTriggered.any()) {
            __VnbaContinue = 1U;
            if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
                VLSU_ooo_wrapper___024root___dump_triggers__nba(vlSelf);
#endif
                VL_FATAL_MT("testbench/LSU_ooo_wrapper.sv", 5, "", "NBA region did not converge.");
            }
            __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
            VLSU_ooo_wrapper___024root___eval_nba(vlSelf);
        }
    }
}

#ifdef VL_DEBUG
void VLSU_ooo_wrapper___024root___eval_debug_assertions(VLSU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VLSU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VLSU_ooo_wrapper___024root___eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((vlSelf->clk & 0xfeU))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY((vlSelf->rst & 0xfeU))) {
        Verilated::overWidthError("rst");}
    if (VL_UNLIKELY((vlSelf->valid_i & 0xfeU))) {
        Verilated::overWidthError("valid_i");}
    if (VL_UNLIKELY((vlSelf->rob_idx_i & 0xe0U))) {
        Verilated::overWidthError("rob_idx_i");}
    if (VL_UNLIKELY((vlSelf->phys_rd_i & 0xc0U))) {
        Verilated::overWidthError("phys_rd_i");}
    if (VL_UNLIKELY((vlSelf->pred_taken_i & 0xfeU))) {
        Verilated::overWidthError("pred_taken_i");}
    if (VL_UNLIKELY((vlSelf->rd_wen_i & 0xfeU))) {
        Verilated::overWidthError("rd_wen_i");}
    if (VL_UNLIKELY((vlSelf->alu_op_i & 0xf0U))) {
        Verilated::overWidthError("alu_op_i");}
    if (VL_UNLIKELY((vlSelf->alu_src_i & 0xfcU))) {
        Verilated::overWidthError("alu_src_i");}
    if (VL_UNLIKELY((vlSelf->cfi_type_i & 0xfcU))) {
        Verilated::overWidthError("cfi_type_i");}
    if (VL_UNLIKELY((vlSelf->br_cond_i & 0xf8U))) {
        Verilated::overWidthError("br_cond_i");}
    if (VL_UNLIKELY((vlSelf->mem_cmd_i & 0xf8U))) {
        Verilated::overWidthError("mem_cmd_i");}
    if (VL_UNLIKELY((vlSelf->csr_cmd_i & 0xfcU))) {
        Verilated::overWidthError("csr_cmd_i");}
    if (VL_UNLIKELY((vlSelf->priv_redir_i & 0xfcU))) {
        Verilated::overWidthError("priv_redir_i");}
    if (VL_UNLIKELY((vlSelf->fence_i_i & 0xfeU))) {
        Verilated::overWidthError("fence_i_i");}
    if (VL_UNLIKELY((vlSelf->ARREADY & 0xfeU))) {
        Verilated::overWidthError("ARREADY");}
    if (VL_UNLIKELY((vlSelf->RID & 0xf0U))) {
        Verilated::overWidthError("RID");}
    if (VL_UNLIKELY((vlSelf->RRESP & 0xfcU))) {
        Verilated::overWidthError("RRESP");}
    if (VL_UNLIKELY((vlSelf->RVALID & 0xfeU))) {
        Verilated::overWidthError("RVALID");}
    if (VL_UNLIKELY((vlSelf->RLAST & 0xfeU))) {
        Verilated::overWidthError("RLAST");}
    if (VL_UNLIKELY((vlSelf->AWREADY & 0xfeU))) {
        Verilated::overWidthError("AWREADY");}
    if (VL_UNLIKELY((vlSelf->WREADY & 0xfeU))) {
        Verilated::overWidthError("WREADY");}
    if (VL_UNLIKELY((vlSelf->BID & 0xf0U))) {
        Verilated::overWidthError("BID");}
    if (VL_UNLIKELY((vlSelf->BRESP & 0xfcU))) {
        Verilated::overWidthError("BRESP");}
    if (VL_UNLIKELY((vlSelf->BVALID & 0xfeU))) {
        Verilated::overWidthError("BVALID");}
}
#endif  // VL_DEBUG

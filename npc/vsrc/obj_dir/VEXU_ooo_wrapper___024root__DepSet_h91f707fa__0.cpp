// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VEXU_ooo_wrapper.h for the primary calling header

#include "verilated.h"

#include "VEXU_ooo_wrapper___024root.h"

VL_INLINE_OPT void VEXU_ooo_wrapper___024root___ico_sequent__TOP__0(VEXU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VEXU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VEXU_ooo_wrapper___024root___ico_sequent__TOP__0\n"); );
    // Init
    IData/*31:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src1;
    EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src1 = 0;
    IData/*31:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src2;
    EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src2 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__redirect_is_branch;
    EXU_ooo_wrapper__DOT__u_exu__DOT__redirect_is_branch = 0;
    IData/*31:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__cfi_target_sum;
    EXU_ooo_wrapper__DOT__u_exu__DOT__cfi_target_sum = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__cin;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__cin = 0;
    IData/*31:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub_result;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub_result = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__cout;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__cout = 0;
    IData/*31:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT____Vcellinp__addsub__b;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT____Vcellinp__addsub__b = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__real_symbol;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__real_symbol = 0;
    IData/*31:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__result_comb;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__result_comb = 0;
    IData/*31:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p = 0;
    IData/*31:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C3_0____pinNumber6;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C3_0____pinNumber6 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C7_4____pinNumber6;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C7_4____pinNumber6 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C7_4____pinNumber3;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C7_4____pinNumber3 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C11_8____pinNumber6;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C11_8____pinNumber6 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C11_8____pinNumber3;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C11_8____pinNumber3 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C15_12____pinNumber6;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C15_12____pinNumber6 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C15_12____pinNumber3;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C15_12____pinNumber3 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C19_16____pinNumber6;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C19_16____pinNumber6 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C19_16____pinNumber3;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C19_16____pinNumber3 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C23_20____pinNumber6;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C23_20____pinNumber6 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C23_20____pinNumber3;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C23_20____pinNumber3 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C27_24____pinNumber6;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C27_24____pinNumber6 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C27_24____pinNumber3;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C27_24____pinNumber3 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C31_28____pinNumber6;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C31_28____pinNumber6 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C31_28____pinNumber3;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C31_28____pinNumber3 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C3_0__DOT____VdfgTmp_h89133af2__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C3_0__DOT____VdfgTmp_h89133af2__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C3_0__DOT____VdfgTmp_h31fb6fd7__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C3_0__DOT____VdfgTmp_h31fb6fd7__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C7_4__DOT____VdfgTmp_h89133af2__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C7_4__DOT____VdfgTmp_h89133af2__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C7_4__DOT____VdfgTmp_h31fb6fd7__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C7_4__DOT____VdfgTmp_h31fb6fd7__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C11_8__DOT____VdfgTmp_h89133af2__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C11_8__DOT____VdfgTmp_h89133af2__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C11_8__DOT____VdfgTmp_h31fb6fd7__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C11_8__DOT____VdfgTmp_h31fb6fd7__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C15_12__DOT____VdfgTmp_h89133af2__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C15_12__DOT____VdfgTmp_h89133af2__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C15_12__DOT____VdfgTmp_h31fb6fd7__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C15_12__DOT____VdfgTmp_h31fb6fd7__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_1__DOT____VdfgTmp_h741ea7ba__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_1__DOT____VdfgTmp_h741ea7ba__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_1__DOT____VdfgTmp_h89133af2__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_1__DOT____VdfgTmp_h89133af2__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C19_16__DOT____VdfgTmp_h89133af2__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C19_16__DOT____VdfgTmp_h89133af2__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C19_16__DOT____VdfgTmp_h31fb6fd7__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C19_16__DOT____VdfgTmp_h31fb6fd7__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C23_20__DOT____VdfgTmp_h89133af2__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C23_20__DOT____VdfgTmp_h89133af2__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C23_20__DOT____VdfgTmp_h31fb6fd7__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C23_20__DOT____VdfgTmp_h31fb6fd7__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C27_24__DOT____VdfgTmp_h89133af2__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C27_24__DOT____VdfgTmp_h89133af2__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C27_24__DOT____VdfgTmp_h31fb6fd7__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C27_24__DOT____VdfgTmp_h31fb6fd7__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C31_28__DOT____VdfgTmp_h89133af2__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C31_28__DOT____VdfgTmp_h89133af2__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C31_28__DOT____VdfgTmp_h31fb6fd7__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C31_28__DOT____VdfgTmp_h31fb6fd7__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_2__DOT____VdfgTmp_h741ea7ba__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_2__DOT____VdfgTmp_h741ea7ba__0 = 0;
    CData/*0:0*/ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_2__DOT____VdfgTmp_h89133af2__0;
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_2__DOT____VdfgTmp_h89133af2__0 = 0;
    // Body
    vlSelf->complete_en_o = vlSelf->valid_i;
    vlSelf->EXU_ooo_wrapper__DOT__data_packed[2U] = 
        ((0x1ffffffU & vlSelf->EXU_ooo_wrapper__DOT__data_packed[2U]) 
         | ((IData)((((QData)((IData)(vlSelf->rob_idx_i)) 
                      << 0x26U) | (((QData)((IData)(vlSelf->phys_rd_i)) 
                                    << 0x20U) | (QData)((IData)(vlSelf->rs1_data_i))))) 
            << 0x19U));
    vlSelf->EXU_ooo_wrapper__DOT__data_packed[3U] = 
        (((IData)((((QData)((IData)(vlSelf->rob_idx_i)) 
                    << 0x26U) | (((QData)((IData)(vlSelf->phys_rd_i)) 
                                  << 0x20U) | (QData)((IData)(vlSelf->rs1_data_i))))) 
          >> 7U) | ((IData)(((((QData)((IData)(vlSelf->rob_idx_i)) 
                               << 0x26U) | (((QData)((IData)(vlSelf->phys_rd_i)) 
                                             << 0x20U) 
                                            | (QData)((IData)(vlSelf->rs1_data_i)))) 
                             >> 0x20U)) << 0x19U));
    vlSelf->EXU_ooo_wrapper__DOT__data_packed[4U] = 
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
    vlSelf->EXU_ooo_wrapper__DOT__data_packed[5U] = 
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
    vlSelf->EXU_ooo_wrapper__DOT__data_packed[6U] = 
        ((IData)(((((QData)((IData)(vlSelf->pc_i)) 
                    << 0x20U) | (QData)((IData)(vlSelf->inst_i))) 
                  >> 0x20U)) >> 0x1cU);
    vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U] = 
        ((0x7fffffU & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U]) 
         | ((IData)((((QData)((IData)(vlSelf->rs2_data_i)) 
                      << 2U) | (QData)((IData)((((IData)(vlSelf->pred_taken_i) 
                                                 << 1U) 
                                                | (IData)(vlSelf->rd_wen_i)))))) 
            << 0x17U));
    vlSelf->EXU_ooo_wrapper__DOT__data_packed[2U] = 
        ((0xfe000000U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[2U]) 
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
    vlSelf->EXU_ooo_wrapper__DOT__data_packed[0U] = vlSelf->imm_i;
    vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U] = 
        ((0xfffe007fU & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U]) 
         | (0xffffff80U & (((IData)(vlSelf->alu_op_i) 
                            << 0xdU) | (((IData)(vlSelf->alu_src_i) 
                                         << 0xbU) | 
                                        (((IData)(vlSelf->cfi_type_i) 
                                          << 9U) | 
                                         (0x180U & 
                                          ((IData)(vlSelf->br_cond_i) 
                                           << 7U)))))));
    vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U] = 
        (0xffe1ffffU & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U]);
    vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U] = 
        ((0xffffff80U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U]) 
         | ((0x60U & ((IData)(vlSelf->mem_cmd_i) << 5U)) 
            | (((IData)(vlSelf->csr_cmd_i) << 3U) | 
               (((IData)(vlSelf->priv_redir_i) << 1U) 
                | (IData)(vlSelf->fence_i_i)))));
    vlSelf->complete_idx_o = (0x1fU & ((vlSelf->EXU_ooo_wrapper__DOT__data_packed[4U] 
                                        << 1U) | (vlSelf->EXU_ooo_wrapper__DOT__data_packed[3U] 
                                                  >> 0x1fU)));
    vlSelf->wakeup_preg_o = (0x3fU & (vlSelf->EXU_ooo_wrapper__DOT__data_packed[3U] 
                                      >> 0x19U));
    vlSelf->wakeup_en_o = ((IData)(vlSelf->valid_i) 
                           & (vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U] 
                              >> 0x17U));
    vlSelf->bpu_update_btb_type_o = (IData)((0x400U 
                                             == (0x600U 
                                                 & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])));
    EXU_ooo_wrapper__DOT__u_exu__DOT__cfi_target_sum 
        = (((3U == (3U & (vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U] 
                          >> 9U))) ? ((vlSelf->EXU_ooo_wrapper__DOT__data_packed[3U] 
                                       << 7U) | (vlSelf->EXU_ooo_wrapper__DOT__data_packed[2U] 
                                                 >> 0x19U))
             : ((vlSelf->EXU_ooo_wrapper__DOT__data_packed[6U] 
                 << 0x1cU) | (vlSelf->EXU_ooo_wrapper__DOT__data_packed[5U] 
                              >> 4U))) + vlSelf->EXU_ooo_wrapper__DOT__data_packed[0U]);
    EXU_ooo_wrapper__DOT__u_exu__DOT__redirect_is_branch 
        = (IData)((0x200U == (0x600U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])));
    if ((0x1000U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])) {
        if ((0x800U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])) {
            EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src1 
                = ((vlSelf->EXU_ooo_wrapper__DOT__data_packed[6U] 
                    << 0x1cU) | (vlSelf->EXU_ooo_wrapper__DOT__data_packed[5U] 
                                 >> 4U));
            EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src2 
                = vlSelf->EXU_ooo_wrapper__DOT__data_packed[0U];
        } else {
            EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src1 
                = ((vlSelf->EXU_ooo_wrapper__DOT__data_packed[6U] 
                    << 0x1cU) | (vlSelf->EXU_ooo_wrapper__DOT__data_packed[5U] 
                                 >> 4U));
            EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src2 = 4U;
        }
    } else if ((0x800U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])) {
        EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src1 
            = ((vlSelf->EXU_ooo_wrapper__DOT__data_packed[3U] 
                << 7U) | (vlSelf->EXU_ooo_wrapper__DOT__data_packed[2U] 
                          >> 0x19U));
        EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src2 
            = vlSelf->EXU_ooo_wrapper__DOT__data_packed[0U];
    } else {
        EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src1 
            = ((vlSelf->EXU_ooo_wrapper__DOT__data_packed[3U] 
                << 7U) | (vlSelf->EXU_ooo_wrapper__DOT__data_packed[2U] 
                          >> 0x19U));
        EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src2 
            = ((vlSelf->EXU_ooo_wrapper__DOT__data_packed[2U] 
                << 7U) | (vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U] 
                          >> 0x19U));
    }
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__cin 
        = (IData)((0U != (0x14000U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])));
    vlSelf->bpu_update_target_o = ((3U == (3U & (vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U] 
                                                 >> 9U)))
                                    ? (0xfffffffeU 
                                       & EXU_ooo_wrapper__DOT__u_exu__DOT__cfi_target_sum)
                                    : EXU_ooo_wrapper__DOT__u_exu__DOT__cfi_target_sum);
    vlSelf->bpu_update_valid_o = ((IData)(vlSelf->valid_i) 
                                  & ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__redirect_is_branch) 
                                     | (IData)(vlSelf->bpu_update_btb_type_o)));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__real_symbol 
        = ((EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src2 
            >> 0x1fU) ^ (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__cin));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT____Vcellinp__addsub__b 
        = (EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src2 
           ^ (- (IData)((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__cin))));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
        = (EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src1 
           & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT____Vcellinp__addsub__b);
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
        = (EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src1 
           | EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT____Vcellinp__addsub__b);
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_2__DOT____VdfgTmp_h741ea7ba__0 
        = (IData)((0xff000000U == (0xff000000U & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p)));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C3_0__DOT____VdfgTmp_h89133af2__0 
        = (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
           & (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__cin));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C31_28__DOT____VdfgTmp_h31fb6fd7__0 
        = (1U & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                  >> 0x1dU) & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                               >> 0x1cU)));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C27_24__DOT____VdfgTmp_h31fb6fd7__0 
        = (1U & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                  >> 0x19U) & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                               >> 0x18U)));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C23_20__DOT____VdfgTmp_h31fb6fd7__0 
        = (1U & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                  >> 0x15U) & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                               >> 0x14U)));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C19_16__DOT____VdfgTmp_h31fb6fd7__0 
        = (1U & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                  >> 0x11U) & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                               >> 0x10U)));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_1__DOT____VdfgTmp_h741ea7ba__0 
        = (IData)((0xff00U == (0xff00U & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p)));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C15_12__DOT____VdfgTmp_h31fb6fd7__0 
        = (1U & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                  >> 0xdU) & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                              >> 0xcU)));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C11_8__DOT____VdfgTmp_h31fb6fd7__0 
        = (1U & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                  >> 9U) & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                            >> 8U)));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C7_4__DOT____VdfgTmp_h31fb6fd7__0 
        = (1U & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                  >> 5U) & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                            >> 4U)));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_1__DOT____VdfgTmp_h89133af2__0 
        = ((0xfU == (0xfU & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p)) 
           & (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__cin));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C3_0__DOT____VdfgTmp_h31fb6fd7__0 
        = (1U & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                  >> 1U) & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C31_28____pinNumber6 
        = (1U & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                  >> 0x1fU) | (((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                 >> 0x1fU) & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                              >> 0x1eU)) 
                               | ((IData)((0xc0000000U 
                                           == (0xc0000000U 
                                               & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                                  & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                      >> 0x1dU) | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C31_28__DOT____VdfgTmp_h31fb6fd7__0))))));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C27_24____pinNumber6 
        = (1U & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                  >> 0x1bU) | (((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                 >> 0x1bU) & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                              >> 0x1aU)) 
                               | ((IData)((0xc000000U 
                                           == (0xc000000U 
                                               & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                                  & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                      >> 0x19U) | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C27_24__DOT____VdfgTmp_h31fb6fd7__0))))));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C23_20____pinNumber6 
        = (1U & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                  >> 0x17U) | (((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                 >> 0x17U) & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                              >> 0x16U)) 
                               | ((IData)((0xc00000U 
                                           == (0xc00000U 
                                               & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                                  & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                      >> 0x15U) | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C23_20__DOT____VdfgTmp_h31fb6fd7__0))))));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C19_16____pinNumber6 
        = (1U & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                  >> 0x13U) | (((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                 >> 0x13U) & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                              >> 0x12U)) 
                               | ((IData)((0xc0000U 
                                           == (0xc0000U 
                                               & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                                  & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                      >> 0x11U) | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C19_16__DOT____VdfgTmp_h31fb6fd7__0))))));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C15_12____pinNumber6 
        = (1U & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                  >> 0xfU) | (((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                >> 0xfU) & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                            >> 0xeU)) 
                              | ((IData)((0xc000U == 
                                          (0xc000U 
                                           & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                                 & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                     >> 0xdU) | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C15_12__DOT____VdfgTmp_h31fb6fd7__0))))));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C11_8____pinNumber6 
        = (1U & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                  >> 0xbU) | (((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                >> 0xbU) & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                            >> 0xaU)) 
                              | ((IData)((0xc00U == 
                                          (0xc00U & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                                 & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                     >> 9U) | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C11_8__DOT____VdfgTmp_h31fb6fd7__0))))));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C7_4____pinNumber6 
        = (1U & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                  >> 7U) | (((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                              >> 7U) & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                        >> 6U)) | ((IData)(
                                                           (0xc0U 
                                                            == 
                                                            (0xc0U 
                                                             & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                                                   & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                       >> 5U) 
                                                      | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C7_4__DOT____VdfgTmp_h31fb6fd7__0))))));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C3_0____pinNumber6 
        = (1U & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                  >> 3U) | (((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                              >> 3U) & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                        >> 2U)) | ((IData)(
                                                           (0xcU 
                                                            == 
                                                            (0xcU 
                                                             & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                                                   & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                       >> 1U) 
                                                      | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C3_0__DOT____VdfgTmp_h31fb6fd7__0))))));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C7_4____pinNumber3 
        = ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C3_0____pinNumber6) 
           | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_1__DOT____VdfgTmp_h89133af2__0));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C11_8____pinNumber3 
        = ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C7_4____pinNumber6) 
           | (IData)(((0xf0U == (0xf0U & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p)) 
                      & ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C3_0____pinNumber6) 
                         | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_1__DOT____VdfgTmp_h89133af2__0)))));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C15_12____pinNumber3 
        = ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C11_8____pinNumber6) 
           | ((IData)(((0xf00U == (0xf00U & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p)) 
                       & (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C7_4____pinNumber6))) 
              | ((IData)((0xff0U == (0xff0U & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                 & ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C3_0____pinNumber6) 
                    | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_1__DOT____VdfgTmp_h89133af2__0)))));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C19_16____pinNumber3 
        = ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C15_12____pinNumber6) 
           | ((IData)(((0xf000U == (0xf000U & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p)) 
                       & (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C11_8____pinNumber6))) 
              | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_1__DOT____VdfgTmp_h741ea7ba__0) 
                  & (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C7_4____pinNumber6)) 
                 | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_1__DOT____VdfgTmp_h741ea7ba__0) 
                     & (0xf0U == (0xf0U & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                    & ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C3_0____pinNumber6) 
                       | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_1__DOT____VdfgTmp_h89133af2__0))))));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C7_4__DOT____VdfgTmp_h89133af2__0 
        = ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
            >> 4U) & (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C7_4____pinNumber3));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C11_8__DOT____VdfgTmp_h89133af2__0 
        = ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
            >> 8U) & (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C11_8____pinNumber3));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C15_12__DOT____VdfgTmp_h89133af2__0 
        = ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
            >> 0xcU) & (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C15_12____pinNumber3));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C19_16__DOT____VdfgTmp_h89133af2__0 
        = ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
            >> 0x10U) & (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C19_16____pinNumber3));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_2__DOT____VdfgTmp_h89133af2__0 
        = (IData)(((0xf0000U == (0xf0000U & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p)) 
                   & (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C19_16____pinNumber3)));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__cout 
        = ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C31_28____pinNumber6) 
           | (((0xfU == (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                         >> 0x1cU)) & (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C27_24____pinNumber6)) 
              | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_2__DOT____VdfgTmp_h741ea7ba__0) 
                  & (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C23_20____pinNumber6)) 
                 | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_2__DOT____VdfgTmp_h741ea7ba__0) 
                     & (0xf00000U == (0xf00000U & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                    & ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C19_16____pinNumber6) 
                       | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_2__DOT____VdfgTmp_h89133af2__0))))));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C23_20____pinNumber3 
        = ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C19_16____pinNumber6) 
           | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_2__DOT____VdfgTmp_h89133af2__0));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C27_24____pinNumber3 
        = ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C23_20____pinNumber6) 
           | (IData)(((0xf00000U == (0xf00000U & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p)) 
                      & ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C19_16____pinNumber6) 
                         | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_2__DOT____VdfgTmp_h89133af2__0)))));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C31_28____pinNumber3 
        = ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C27_24____pinNumber6) 
           | ((IData)(((0xf000000U == (0xf000000U & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p)) 
                       & (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C23_20____pinNumber6))) 
              | ((IData)((0xff00000U == (0xff00000U 
                                         & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                 & ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellout__C19_16____pinNumber6) 
                    | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C_INTER_2_2__DOT____VdfgTmp_h89133af2__0)))));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C23_20__DOT____VdfgTmp_h89133af2__0 
        = ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
            >> 0x14U) & (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C23_20____pinNumber3));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C27_24__DOT____VdfgTmp_h89133af2__0 
        = ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
            >> 0x18U) & (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C27_24____pinNumber3));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C31_28__DOT____VdfgTmp_h89133af2__0 
        = ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
            >> 0x1cU) & (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C31_28____pinNumber3));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub_result 
        = (EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src1 
           ^ (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT____Vcellinp__addsub__b 
              ^ (((0x80000000U & ((0x80000000U & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                  << 1U)) 
                                  | ((0x80000000U & 
                                      ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                        << 1U) & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                  << 2U))) 
                                     | (((IData)((0x60000000U 
                                                  == 
                                                  (0x60000000U 
                                                   & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                                         << 0x1fU) 
                                        & ((0x80000000U 
                                            & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                               << 3U)) 
                                           | ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C31_28__DOT____VdfgTmp_h89133af2__0) 
                                              << 0x1fU)))))) 
                  | ((0x40000000U & ((0xc0000000U & 
                                      (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                       << 1U)) | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C31_28__DOT____VdfgTmp_h31fb6fd7__0) 
                                                   << 0x1eU) 
                                                  | (0xc0000000U 
                                                     & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                                         << 1U) 
                                                        & ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C31_28__DOT____VdfgTmp_h89133af2__0) 
                                                           << 0x1eU)))))) 
                     | (0x20000000U & ((0xe0000000U 
                                        & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                           << 1U)) 
                                       | ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C31_28__DOT____VdfgTmp_h89133af2__0) 
                                          << 0x1dU))))) 
                 | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C31_28____pinNumber3) 
                     << 0x1cU) | (((0x8000000U & ((0xf8000000U 
                                                   & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                      << 1U)) 
                                                  | ((0xf8000000U 
                                                      & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                                          << 1U) 
                                                         & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                            << 2U))) 
                                                     | (((IData)(
                                                                 (0x6000000U 
                                                                  == 
                                                                  (0x6000000U 
                                                                   & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                                                         << 0x1bU) 
                                                        & ((0xf8000000U 
                                                            & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                               << 3U)) 
                                                           | ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C27_24__DOT____VdfgTmp_h89133af2__0) 
                                                              << 0x1bU)))))) 
                                   | ((0x4000000U & 
                                       ((0xfc000000U 
                                         & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                            << 1U)) 
                                        | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C27_24__DOT____VdfgTmp_h31fb6fd7__0) 
                                            << 0x1aU) 
                                           | (0xfc000000U 
                                              & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                                  << 1U) 
                                                 & ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C27_24__DOT____VdfgTmp_h89133af2__0) 
                                                    << 0x1aU)))))) 
                                      | (0x2000000U 
                                         & ((0xfe000000U 
                                             & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                << 1U)) 
                                            | ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C27_24__DOT____VdfgTmp_h89133af2__0) 
                                               << 0x19U))))) 
                                  | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C27_24____pinNumber3) 
                                      << 0x18U) | (
                                                   ((0x800000U 
                                                     & ((0xff800000U 
                                                         & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                            << 1U)) 
                                                        | ((0xff800000U 
                                                            & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                                                << 1U) 
                                                               & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                  << 2U))) 
                                                           | (((IData)(
                                                                       (0x600000U 
                                                                        == 
                                                                        (0x600000U 
                                                                         & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                                                               << 0x17U) 
                                                              & ((0xff800000U 
                                                                  & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                     << 3U)) 
                                                                 | ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C23_20__DOT____VdfgTmp_h89133af2__0) 
                                                                    << 0x17U)))))) 
                                                    | ((0x400000U 
                                                        & ((0xffc00000U 
                                                            & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                               << 1U)) 
                                                           | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C23_20__DOT____VdfgTmp_h31fb6fd7__0) 
                                                               << 0x16U) 
                                                              | (0xffc00000U 
                                                                 & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                                                     << 1U) 
                                                                    & ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C23_20__DOT____VdfgTmp_h89133af2__0) 
                                                                       << 0x16U)))))) 
                                                       | (0x200000U 
                                                          & ((0xffe00000U 
                                                              & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                 << 1U)) 
                                                             | ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C23_20__DOT____VdfgTmp_h89133af2__0) 
                                                                << 0x15U))))) 
                                                   | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C23_20____pinNumber3) 
                                                       << 0x14U) 
                                                      | (((0x80000U 
                                                           & ((0xfff80000U 
                                                               & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                  << 1U)) 
                                                              | ((0xfff80000U 
                                                                  & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                                                      << 1U) 
                                                                     & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                        << 2U))) 
                                                                 | (((IData)(
                                                                             (0x60000U 
                                                                              == 
                                                                              (0x60000U 
                                                                               & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                                                                     << 0x13U) 
                                                                    & ((0xfff80000U 
                                                                        & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                           << 3U)) 
                                                                       | ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C19_16__DOT____VdfgTmp_h89133af2__0) 
                                                                          << 0x13U)))))) 
                                                          | ((0x40000U 
                                                              & ((0xfffc0000U 
                                                                  & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                     << 1U)) 
                                                                 | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C19_16__DOT____VdfgTmp_h31fb6fd7__0) 
                                                                     << 0x12U) 
                                                                    | (0xfffc0000U 
                                                                       & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                                                           << 1U) 
                                                                          & ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C19_16__DOT____VdfgTmp_h89133af2__0) 
                                                                             << 0x12U)))))) 
                                                             | (0x20000U 
                                                                & ((0xfffe0000U 
                                                                    & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                       << 1U)) 
                                                                   | ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C19_16__DOT____VdfgTmp_h89133af2__0) 
                                                                      << 0x11U))))) 
                                                         | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C19_16____pinNumber3) 
                                                             << 0x10U) 
                                                            | (((0x8000U 
                                                                 & ((0xffff8000U 
                                                                     & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                        << 1U)) 
                                                                    | ((0xffff8000U 
                                                                        & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                                                            << 1U) 
                                                                           & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                              << 2U))) 
                                                                       | (((IData)(
                                                                                (0x6000U 
                                                                                == 
                                                                                (0x6000U 
                                                                                & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                                                                           << 0xfU) 
                                                                          & ((0xffff8000U 
                                                                              & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                                << 3U)) 
                                                                             | ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C15_12__DOT____VdfgTmp_h89133af2__0) 
                                                                                << 0xfU)))))) 
                                                                | ((0x4000U 
                                                                    & ((0xffffc000U 
                                                                        & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                           << 1U)) 
                                                                       | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C15_12__DOT____VdfgTmp_h31fb6fd7__0) 
                                                                           << 0xeU) 
                                                                          | (0xffffc000U 
                                                                             & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                                                                << 1U) 
                                                                                & ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C15_12__DOT____VdfgTmp_h89133af2__0) 
                                                                                << 0xeU)))))) 
                                                                   | (0x2000U 
                                                                      & ((0xffffe000U 
                                                                          & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                             << 1U)) 
                                                                         | ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C15_12__DOT____VdfgTmp_h89133af2__0) 
                                                                            << 0xdU))))) 
                                                               | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C15_12____pinNumber3) 
                                                                   << 0xcU) 
                                                                  | (((0x800U 
                                                                       & ((0xfffff800U 
                                                                           & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                              << 1U)) 
                                                                          | ((0xfffff800U 
                                                                              & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                                                                << 1U) 
                                                                                & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                                << 2U))) 
                                                                             | (((IData)(
                                                                                (0x600U 
                                                                                == 
                                                                                (0x600U 
                                                                                & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                                                                                << 0xbU) 
                                                                                & ((0xfffff800U 
                                                                                & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                                << 3U)) 
                                                                                | ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C11_8__DOT____VdfgTmp_h89133af2__0) 
                                                                                << 0xbU)))))) 
                                                                      | ((0x400U 
                                                                          & ((0xfffffc00U 
                                                                              & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                                << 1U)) 
                                                                             | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C11_8__DOT____VdfgTmp_h31fb6fd7__0) 
                                                                                << 0xaU) 
                                                                                | (0xfffffc00U 
                                                                                & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                                                                << 1U) 
                                                                                & ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C11_8__DOT____VdfgTmp_h89133af2__0) 
                                                                                << 0xaU)))))) 
                                                                         | (0x200U 
                                                                            & ((0xfffffe00U 
                                                                                & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                                << 1U)) 
                                                                               | ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C11_8__DOT____VdfgTmp_h89133af2__0) 
                                                                                << 9U))))) 
                                                                     | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C11_8____pinNumber3) 
                                                                         << 8U) 
                                                                        | (((0x80U 
                                                                             & ((0xffffff80U 
                                                                                & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                                << 1U)) 
                                                                                | ((0xffffff80U 
                                                                                & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                                                                << 1U) 
                                                                                & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                                << 2U))) 
                                                                                | (((IData)(
                                                                                (0x60U 
                                                                                == 
                                                                                (0x60U 
                                                                                & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                                                                                << 7U) 
                                                                                & ((0xffffff80U 
                                                                                & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                                << 3U)) 
                                                                                | ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C7_4__DOT____VdfgTmp_h89133af2__0) 
                                                                                << 7U)))))) 
                                                                            | ((0x40U 
                                                                                & ((0xffffffc0U 
                                                                                & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                                << 1U)) 
                                                                                | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C7_4__DOT____VdfgTmp_h31fb6fd7__0) 
                                                                                << 6U) 
                                                                                | (0xffffffc0U 
                                                                                & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                                                                << 1U) 
                                                                                & ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C7_4__DOT____VdfgTmp_h89133af2__0) 
                                                                                << 6U)))))) 
                                                                               | (0x20U 
                                                                                & ((0xffffffe0U 
                                                                                & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                                << 1U)) 
                                                                                | ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C7_4__DOT____VdfgTmp_h89133af2__0) 
                                                                                << 5U))))) 
                                                                           | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT____Vcellinp__C7_4____pinNumber3) 
                                                                               << 4U) 
                                                                              | ((8U 
                                                                                & ((0xfffffff8U 
                                                                                & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                                << 1U)) 
                                                                                | ((0xfffffff8U 
                                                                                & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                                                                << 1U) 
                                                                                & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                                << 2U))) 
                                                                                | (((IData)(
                                                                                (6U 
                                                                                == 
                                                                                (6U 
                                                                                & EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p))) 
                                                                                & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                                | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C3_0__DOT____VdfgTmp_h89133af2__0))) 
                                                                                << 3U)))) 
                                                                                | ((4U 
                                                                                & ((0xfffffffcU 
                                                                                & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                                << 1U)) 
                                                                                | (((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C3_0__DOT____VdfgTmp_h31fb6fd7__0) 
                                                                                << 2U) 
                                                                                | (0xfffffffcU 
                                                                                & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__p 
                                                                                << 1U) 
                                                                                & ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C3_0__DOT____VdfgTmp_h89133af2__0) 
                                                                                << 2U)))))) 
                                                                                | ((2U 
                                                                                & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__g 
                                                                                | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub__DOT__C3_0__DOT____VdfgTmp_h89133af2__0)) 
                                                                                << 1U)) 
                                                                                | (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__cin))))))))))))))))))));
    EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__result_comb 
        = ((0x10000U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])
            ? ((0x8000U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])
                ? ((0x4000U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])
                    ? EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src2
                    : ((0x2000U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])
                        ? VL_SHIFTRS_III(32,32,5, EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src1, 
                                         (0x1fU & EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src2))
                        : EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src2))
                : ((0x4000U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])
                    ? EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src2
                    : ((0x2000U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])
                        ? EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src2
                        : EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub_result)))
            : ((0x8000U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])
                ? ((0x4000U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])
                    ? ((0x2000U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])
                        ? (EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src1 
                           & EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src2)
                        : (EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src1 
                           | EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src2))
                    : ((0x2000U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])
                        ? (EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src1 
                           >> (0x1fU & EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src2))
                        : (EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src1 
                           ^ EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src2)))
                : ((0x4000U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])
                    ? ((0x2000U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])
                        ? ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__cout) 
                           ^ (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__cin))
                        : (1U & ((EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub_result 
                                  >> 0x1fU) ^ (((EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src1 
                                                 >> 0x1fU) 
                                                & ((~ 
                                                    (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub_result 
                                                     >> 0x1fU)) 
                                                   & (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__real_symbol))) 
                                               | ((~ 
                                                   (EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src1 
                                                    >> 0x1fU)) 
                                                  & ((~ (IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__real_symbol)) 
                                                     & (EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub_result 
                                                        >> 0x1fU)))))))
                    : ((0x2000U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])
                        ? (EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src1 
                           << (0x1fU & EXU_ooo_wrapper__DOT__u_exu__DOT__alu_src2))
                        : EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub_result))));
    vlSelf->complete_data_o = ((0U == (3U & (vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U] 
                                             >> 3U)))
                                ? ((IData)((0U != (0x401U 
                                                   & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])))
                                    ? ((IData)(4U) 
                                       + ((vlSelf->EXU_ooo_wrapper__DOT__data_packed[6U] 
                                           << 0x1cU) 
                                          | (vlSelf->EXU_ooo_wrapper__DOT__data_packed[5U] 
                                             >> 4U)))
                                    : EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__result_comb)
                                : ((0x40000U & vlSelf->EXU_ooo_wrapper__DOT__data_packed[4U])
                                    ? vlSelf->EXU_ooo_wrapper__DOT__data_packed[0U]
                                    : ((vlSelf->EXU_ooo_wrapper__DOT__data_packed[3U] 
                                        << 7U) | (vlSelf->EXU_ooo_wrapper__DOT__data_packed[2U] 
                                                  >> 0x19U))));
    vlSelf->bpu_update_taken_o = (1U & ((vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U] 
                                         >> 0xaU) | 
                                        ((IData)(EXU_ooo_wrapper__DOT__u_exu__DOT__redirect_is_branch) 
                                         & ((0x100U 
                                             & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])
                                             ? ((0x80U 
                                                 & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])
                                                 ? 
                                                (~ EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__result_comb)
                                                 : EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__result_comb)
                                             : ((0x80U 
                                                 & vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U])
                                                 ? 
                                                (0U 
                                                 != EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub_result)
                                                 : 
                                                (~ (IData)(
                                                           (0U 
                                                            != EXU_ooo_wrapper__DOT__u_exu__DOT__u_ALU__DOT__addsub_result))))))));
    vlSelf->complete_redirect_valid_o = ((0U != (3U 
                                                 & (vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U] 
                                                    >> 9U))) 
                                         & ((IData)(vlSelf->bpu_update_taken_o) 
                                            ^ (vlSelf->EXU_ooo_wrapper__DOT__data_packed[1U] 
                                               >> 0x18U)));
    vlSelf->complete_redirect_addr_o = ((IData)(vlSelf->bpu_update_taken_o)
                                         ? vlSelf->bpu_update_target_o
                                         : ((IData)(4U) 
                                            + ((vlSelf->EXU_ooo_wrapper__DOT__data_packed[6U] 
                                                << 0x1cU) 
                                               | (vlSelf->EXU_ooo_wrapper__DOT__data_packed[5U] 
                                                  >> 4U))));
    vlSelf->redirect_valid_o = ((IData)(vlSelf->valid_i) 
                                & (IData)(vlSelf->complete_redirect_valid_o));
    vlSelf->redirect_addr_o = vlSelf->complete_redirect_addr_o;
}

void VEXU_ooo_wrapper___024root___eval_ico(VEXU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VEXU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VEXU_ooo_wrapper___024root___eval_ico\n"); );
    // Body
    if (vlSelf->__VicoTriggered.at(0U)) {
        VEXU_ooo_wrapper___024root___ico_sequent__TOP__0(vlSelf);
    }
}

void VEXU_ooo_wrapper___024root___eval_act(VEXU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VEXU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VEXU_ooo_wrapper___024root___eval_act\n"); );
}

void VEXU_ooo_wrapper___024root___eval_nba(VEXU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VEXU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VEXU_ooo_wrapper___024root___eval_nba\n"); );
}

void VEXU_ooo_wrapper___024root___eval_triggers__ico(VEXU_ooo_wrapper___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void VEXU_ooo_wrapper___024root___dump_triggers__ico(VEXU_ooo_wrapper___024root* vlSelf);
#endif  // VL_DEBUG
void VEXU_ooo_wrapper___024root___eval_triggers__act(VEXU_ooo_wrapper___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void VEXU_ooo_wrapper___024root___dump_triggers__act(VEXU_ooo_wrapper___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void VEXU_ooo_wrapper___024root___dump_triggers__nba(VEXU_ooo_wrapper___024root* vlSelf);
#endif  // VL_DEBUG

void VEXU_ooo_wrapper___024root___eval(VEXU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VEXU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VEXU_ooo_wrapper___024root___eval\n"); );
    // Init
    CData/*0:0*/ __VicoContinue;
    VlTriggerVec<0> __VpreTriggered;
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    vlSelf->__VicoIterCount = 0U;
    __VicoContinue = 1U;
    while (__VicoContinue) {
        __VicoContinue = 0U;
        VEXU_ooo_wrapper___024root___eval_triggers__ico(vlSelf);
        if (vlSelf->__VicoTriggered.any()) {
            __VicoContinue = 1U;
            if (VL_UNLIKELY((0x64U < vlSelf->__VicoIterCount))) {
#ifdef VL_DEBUG
                VEXU_ooo_wrapper___024root___dump_triggers__ico(vlSelf);
#endif
                VL_FATAL_MT("testbench/EXU_ooo_wrapper.sv", 5, "", "Input combinational region did not converge.");
            }
            vlSelf->__VicoIterCount = ((IData)(1U) 
                                       + vlSelf->__VicoIterCount);
            VEXU_ooo_wrapper___024root___eval_ico(vlSelf);
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
            VEXU_ooo_wrapper___024root___eval_triggers__act(vlSelf);
            if (vlSelf->__VactTriggered.any()) {
                vlSelf->__VactContinue = 1U;
                if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                    VEXU_ooo_wrapper___024root___dump_triggers__act(vlSelf);
#endif
                    VL_FATAL_MT("testbench/EXU_ooo_wrapper.sv", 5, "", "Active region did not converge.");
                }
                vlSelf->__VactIterCount = ((IData)(1U) 
                                           + vlSelf->__VactIterCount);
                __VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
                vlSelf->__VnbaTriggered.set(vlSelf->__VactTriggered);
                VEXU_ooo_wrapper___024root___eval_act(vlSelf);
            }
        }
        if (vlSelf->__VnbaTriggered.any()) {
            __VnbaContinue = 1U;
            if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
                VEXU_ooo_wrapper___024root___dump_triggers__nba(vlSelf);
#endif
                VL_FATAL_MT("testbench/EXU_ooo_wrapper.sv", 5, "", "NBA region did not converge.");
            }
            __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
            VEXU_ooo_wrapper___024root___eval_nba(vlSelf);
        }
    }
}

#ifdef VL_DEBUG
void VEXU_ooo_wrapper___024root___eval_debug_assertions(VEXU_ooo_wrapper___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    VEXU_ooo_wrapper__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    VEXU_ooo_wrapper___024root___eval_debug_assertions\n"); );
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
}
#endif  // VL_DEBUG

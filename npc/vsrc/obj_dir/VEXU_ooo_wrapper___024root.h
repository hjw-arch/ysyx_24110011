// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See VEXU_ooo_wrapper.h for the primary calling header

#ifndef VERILATED_VEXU_OOO_WRAPPER___024ROOT_H_
#define VERILATED_VEXU_OOO_WRAPPER___024ROOT_H_  // guard

#include "verilated.h"

class VEXU_ooo_wrapper__Syms;

class VEXU_ooo_wrapper___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    VL_IN8(rst,0,0);
    VL_IN8(valid_i,0,0);
    VL_IN8(rob_idx_i,4,0);
    VL_IN8(phys_rd_i,5,0);
    VL_IN8(pred_taken_i,0,0);
    VL_IN8(rd_wen_i,0,0);
    VL_IN8(alu_op_i,3,0);
    VL_IN8(alu_src_i,1,0);
    VL_IN8(cfi_type_i,1,0);
    VL_IN8(br_cond_i,2,0);
    VL_IN8(mem_cmd_i,2,0);
    VL_IN8(csr_cmd_i,1,0);
    VL_IN8(priv_redir_i,1,0);
    VL_IN8(fence_i_i,0,0);
    VL_OUT8(ready_o,0,0);
    VL_OUT8(complete_en_o,0,0);
    VL_OUT8(complete_idx_o,4,0);
    VL_OUT8(complete_exception_o,0,0);
    VL_OUT8(complete_cause_o,3,0);
    VL_OUT8(complete_redirect_valid_o,0,0);
    VL_OUT8(wakeup_en_o,0,0);
    VL_OUT8(wakeup_preg_o,5,0);
    VL_OUT8(redirect_valid_o,0,0);
    VL_OUT8(bpu_update_valid_o,0,0);
    VL_OUT8(bpu_update_btb_type_o,0,0);
    VL_OUT8(bpu_update_taken_o,0,0);
    CData/*0:0*/ __VactContinue;
    VL_IN(pc_i,31,0);
    VL_IN(inst_i,31,0);
    VL_IN(rs1_data_i,31,0);
    VL_IN(rs2_data_i,31,0);
    VL_IN(imm_i,31,0);
    VL_OUT(complete_data_o,31,0);
    VL_OUT(complete_redirect_addr_o,31,0);
    VL_OUT(redirect_addr_o,31,0);
    VL_OUT(bpu_update_target_o,31,0);
    IData/*31:0*/ __VstlIterCount;
    IData/*31:0*/ __VicoIterCount;
    IData/*31:0*/ __VactIterCount;
    VlWide<7>/*195:0*/ EXU_ooo_wrapper__DOT__data_packed;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<0> __VactTriggered;
    VlTriggerVec<0> __VnbaTriggered;

    // INTERNAL VARIABLES
    VEXU_ooo_wrapper__Syms* const vlSymsp;

    // CONSTRUCTORS
    VEXU_ooo_wrapper___024root(VEXU_ooo_wrapper__Syms* symsp, const char* v__name);
    ~VEXU_ooo_wrapper___024root();
    VL_UNCOPYABLE(VEXU_ooo_wrapper___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);


#endif  // guard

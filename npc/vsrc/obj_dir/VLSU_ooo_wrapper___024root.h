// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See VLSU_ooo_wrapper.h for the primary calling header

#ifndef VERILATED_VLSU_OOO_WRAPPER___024ROOT_H_
#define VERILATED_VLSU_OOO_WRAPPER___024ROOT_H_  // guard

#include "verilated.h"

class VLSU_ooo_wrapper__Syms;

class VLSU_ooo_wrapper___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    // Anonymous structures to workaround compiler member-count bugs
    struct {
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
        VL_OUT8(ARID,3,0);
        VL_OUT8(ARLEN,7,0);
        VL_OUT8(ARSIZE,2,0);
        VL_OUT8(ARBURST,1,0);
        VL_OUT8(ARVALID,0,0);
        VL_IN8(ARREADY,0,0);
        VL_IN8(RID,3,0);
        VL_IN8(RRESP,1,0);
        VL_IN8(RVALID,0,0);
        VL_IN8(RLAST,0,0);
        VL_OUT8(RREADY,0,0);
        VL_OUT8(AWLEN,7,0);
        VL_OUT8(AWSIZE,2,0);
        VL_OUT8(AWID,3,0);
        VL_OUT8(AWBURST,1,0);
        VL_OUT8(AWVALID,0,0);
        VL_IN8(AWREADY,0,0);
        VL_OUT8(WLAST,0,0);
        VL_OUT8(WSTRB,3,0);
        VL_OUT8(WVALID,0,0);
        VL_IN8(WREADY,0,0);
        VL_IN8(BID,3,0);
        VL_IN8(BRESP,1,0);
        VL_IN8(BVALID,0,0);
        VL_OUT8(BREADY,0,0);
        CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__state;
        CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__nstate;
        CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__is_mem;
        CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_valid;
        CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__mem_resp_fire;
        CData/*1:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__r_state;
        CData/*1:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__next_r_state;
        CData/*2:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__w_state;
        CData/*2:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__next_w_state;
        CData/*0:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__rdone;
        CData/*0:0*/ __Vtrigrprev__TOP__clk;
        CData/*0:0*/ __VactContinue;
        VL_IN(pc_i,31,0);
        VL_IN(inst_i,31,0);
        VL_IN(rs1_data_i,31,0);
        VL_IN(rs2_data_i,31,0);
        VL_IN(imm_i,31,0);
        VL_OUT(complete_data_o,31,0);
        VL_OUT(ARADDR,31,0);
    };
    struct {
        VL_IN(RDATA,31,0);
        VL_OUT(AWADDR,31,0);
        VL_OUT(WDATA,31,0);
        IData/*31:0*/ LSU_ooo_wrapper__DOT__u_lsu__DOT__u_axi4_full_master__DOT__RDATA_TEMP;
        IData/*31:0*/ __VstlIterCount;
        IData/*31:0*/ __VicoIterCount;
        IData/*31:0*/ __VactIterCount;
        VlWide<7>/*195:0*/ LSU_ooo_wrapper__DOT__data_packed;
    };
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    VLSU_ooo_wrapper__Syms* const vlSymsp;

    // CONSTRUCTORS
    VLSU_ooo_wrapper___024root(VLSU_ooo_wrapper__Syms* symsp, const char* v__name);
    ~VLSU_ooo_wrapper___024root();
    VL_UNCOPYABLE(VLSU_ooo_wrapper___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);


#endif  // guard

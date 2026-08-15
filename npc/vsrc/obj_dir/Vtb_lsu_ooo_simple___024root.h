// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtb_lsu_ooo_simple.h for the primary calling header

#ifndef VERILATED_VTB_LSU_OOO_SIMPLE___024ROOT_H_
#define VERILATED_VTB_LSU_OOO_SIMPLE___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"

class Vtb_lsu_ooo_simple__Syms;

class Vtb_lsu_ooo_simple___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ tb_lsu_ooo_simple__DOT__clk;
    CData/*0:0*/ tb_lsu_ooo_simple__DOT__rst;
    CData/*0:0*/ tb_lsu_ooo_simple__DOT__valid_i;
    CData/*0:0*/ tb_lsu_ooo_simple__DOT__complete_en_o;
    CData/*4:0*/ tb_lsu_ooo_simple__DOT__complete_idx_o;
    CData/*0:0*/ tb_lsu_ooo_simple__DOT__ARVALID;
    CData/*0:0*/ tb_lsu_ooo_simple__DOT__dut__DOT__state;
    CData/*0:0*/ tb_lsu_ooo_simple__DOT__dut__DOT__nstate;
    CData/*0:0*/ tb_lsu_ooo_simple__DOT__dut__DOT__is_mem;
    CData/*0:0*/ tb_lsu_ooo_simple__DOT__dut__DOT__mem_valid;
    CData/*0:0*/ tb_lsu_ooo_simple__DOT__dut__DOT__mem_resp_fire;
    CData/*1:0*/ tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__r_state;
    CData/*1:0*/ tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__next_r_state;
    CData/*2:0*/ tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__w_state;
    CData/*2:0*/ tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__next_w_state;
    CData/*0:0*/ tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__rdone;
    CData/*0:0*/ tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT____VdfgTmp_hff04b70f__0;
    CData/*0:0*/ __Vtrigrprev__TOP__tb_lsu_ooo_simple__DOT__clk;
    CData/*0:0*/ __VactContinue;
    IData/*31:0*/ tb_lsu_ooo_simple__DOT__pass_cnt;
    IData/*31:0*/ tb_lsu_ooo_simple__DOT__fail_cnt;
    IData/*31:0*/ __VstlIterCount;
    IData/*31:0*/ __VactIterCount;
    VlWide<7>/*195:0*/ tb_lsu_ooo_simple__DOT__data_i;
    VlDelayScheduler __VdlySched;
    VlTriggerScheduler __VtrigSched_hfc645c1e__0;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<2> __VactTriggered;
    VlTriggerVec<2> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vtb_lsu_ooo_simple__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vtb_lsu_ooo_simple___024root(Vtb_lsu_ooo_simple__Syms* symsp, const char* v__name);
    ~Vtb_lsu_ooo_simple___024root();
    VL_UNCOPYABLE(Vtb_lsu_ooo_simple___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);


#endif  // guard

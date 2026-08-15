// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_lsu_ooo_simple.h for the primary calling header

#include "verilated.h"

#include "Vtb_lsu_ooo_simple___024root.h"

VlCoroutine Vtb_lsu_ooo_simple___024root___eval_initial__TOP__0(Vtb_lsu_ooo_simple___024root* vlSelf);
VlCoroutine Vtb_lsu_ooo_simple___024root___eval_initial__TOP__1(Vtb_lsu_ooo_simple___024root* vlSelf);

void Vtb_lsu_ooo_simple___024root___eval_initial(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___eval_initial\n"); );
    // Body
    Vtb_lsu_ooo_simple___024root___eval_initial__TOP__0(vlSelf);
    Vtb_lsu_ooo_simple___024root___eval_initial__TOP__1(vlSelf);
    vlSelf->__Vtrigrprev__TOP__tb_lsu_ooo_simple__DOT__clk 
        = vlSelf->tb_lsu_ooo_simple__DOT__clk;
}

VL_INLINE_OPT VlCoroutine Vtb_lsu_ooo_simple___024root___eval_initial__TOP__0(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___eval_initial__TOP__0\n"); );
    // Init
    std::string __Vtask_tb_lsu_ooo_simple__DOT__chk__1__name;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__1__exp;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__1__exp = 0;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__1__act;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__1__act = 0;
    std::string __Vtask_tb_lsu_ooo_simple__DOT__chk__2__name;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__2__exp;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__2__exp = 0;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__2__act;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__2__act = 0;
    std::string __Vtask_tb_lsu_ooo_simple__DOT__chk32__3__name;
    IData/*31:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk32__3__exp;
    __Vtask_tb_lsu_ooo_simple__DOT__chk32__3__exp = 0;
    IData/*31:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk32__3__act;
    __Vtask_tb_lsu_ooo_simple__DOT__chk32__3__act = 0;
    std::string __Vtask_tb_lsu_ooo_simple__DOT__chk__5__name;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__5__exp;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__5__exp = 0;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__5__act;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__5__act = 0;
    std::string __Vtask_tb_lsu_ooo_simple__DOT__chk__6__name;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__6__exp;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__6__exp = 0;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__6__act;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__6__act = 0;
    std::string __Vtask_tb_lsu_ooo_simple__DOT__chk__7__name;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__7__exp;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__7__exp = 0;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__7__act;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__7__act = 0;
    std::string __Vtask_tb_lsu_ooo_simple__DOT__chk__9__name;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__9__exp;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__9__exp = 0;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__9__act;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__9__act = 0;
    std::string __Vtask_tb_lsu_ooo_simple__DOT__chk__11__name;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__11__exp;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__11__exp = 0;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__11__act;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__11__act = 0;
    std::string __Vtask_tb_lsu_ooo_simple__DOT__chk__12__name;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__12__exp;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__12__exp = 0;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__12__act;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__12__act = 0;
    std::string __Vtask_tb_lsu_ooo_simple__DOT__chk__13__name;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__13__exp;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__13__exp = 0;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__13__act;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__13__act = 0;
    std::string __Vtask_tb_lsu_ooo_simple__DOT__chk__15__name;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__15__exp;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__15__exp = 0;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__15__act;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__15__act = 0;
    std::string __Vtask_tb_lsu_ooo_simple__DOT__chk__16__name;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__16__exp;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__16__exp = 0;
    CData/*0:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk__16__act;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__16__act = 0;
    std::string __Vtask_tb_lsu_ooo_simple__DOT__chk32__17__name;
    IData/*31:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk32__17__exp;
    __Vtask_tb_lsu_ooo_simple__DOT__chk32__17__exp = 0;
    IData/*31:0*/ __Vtask_tb_lsu_ooo_simple__DOT__chk32__17__act;
    __Vtask_tb_lsu_ooo_simple__DOT__chk32__17__act = 0;
    // Body
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       66);
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       66);
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       66);
    vlSelf->tb_lsu_ooo_simple__DOT__rst = 0U;
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       68);
    co_await vlSelf->__VdlySched.delay(0x3e8ULL, "testbench/tb_lsu_ooo_simple.sv", 
                                       68);
    VL_WRITEF("\n=== LSU_ooo \347\256\200\345\215\225\346\265\213\350\257\225 ===\n\n[\346\265\213\350\257\2251] \351\235\236\350\256\277\345\255\230\346\214\207\344\273\244\345\272\224\350\257\245\347\233\264\346\216\245\351\200\217\344\274\240\n");
    vlSelf->tb_lsu_ooo_simple__DOT__valid_i = 1U;
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U] = (0x80000000U 
                                                  | (0x7fffffffU 
                                                     & vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U]));
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U] = (2U 
                                                  | (0xfffffff0U 
                                                     & vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U]));
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U] = (0xffffff9fU 
                                                  & vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U]);
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[2U] = (0xc8000000U 
                                                  | (0x1ffffffU 
                                                     & vlSelf->tb_lsu_ooo_simple__DOT__data_i[2U]));
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U] = (0xfe000000U 
                                                  & vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U]);
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[0U] = 0x32U;
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       62);
    co_await vlSelf->__VdlySched.delay(0x3e8ULL, "testbench/tb_lsu_ooo_simple.sv", 
                                       62);
    VL_WRITEF("  \350\260\203\350\257\225: data_i.rob_idx=%2#, complete_idx_o=%2#\n",
              5,(0x1fU & ((vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U] 
                           << 1U) | (vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U] 
                                     >> 0x1fU))),5,
              (IData)(vlSelf->tb_lsu_ooo_simple__DOT__complete_idx_o));
    __Vtask_tb_lsu_ooo_simple__DOT__chk__1__act = vlSelf->tb_lsu_ooo_simple__DOT__complete_en_o;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__1__exp = 1U;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__1__name = 
        std::string{"complete_en (\351\235\236\350\256\277\345\255\230\351\200\217\344\274\240)"};
    if (((IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__1__exp) 
         == (IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__1__act))) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__1__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=%b  \345\256\236\351\231\205=%b\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__1__name),
                  1,(IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__1__exp),
                  1,__Vtask_tb_lsu_ooo_simple__DOT__chk__1__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    __Vtask_tb_lsu_ooo_simple__DOT__chk__2__act = (1U 
                                                   & (((~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__state)) 
                                                       & (~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_valid))) 
                                                      | (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_resp_fire)));
    __Vtask_tb_lsu_ooo_simple__DOT__chk__2__exp = 1U;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__2__name = 
        std::string{"ready (\346\216\245\345\217\227\346\226\260\350\276\223\345\205\245)"};
    if (((IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__2__exp) 
         == (IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__2__act))) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__2__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=%b  \345\256\236\351\231\205=%b\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__2__name),
                  1,(IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__2__exp),
                  1,__Vtask_tb_lsu_ooo_simple__DOT__chk__2__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    __Vtask_tb_lsu_ooo_simple__DOT__chk32__3__act = vlSelf->tb_lsu_ooo_simple__DOT__complete_idx_o;
    __Vtask_tb_lsu_ooo_simple__DOT__chk32__3__exp = 5U;
    __Vtask_tb_lsu_ooo_simple__DOT__chk32__3__name = 
        std::string{"complete_idx"};
    if ((__Vtask_tb_lsu_ooo_simple__DOT__chk32__3__exp 
         == __Vtask_tb_lsu_ooo_simple__DOT__chk32__3__act)) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk32__3__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=0x%08x  \345\256\236\351\231\205=0x%08x\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk32__3__name),
                  32,__Vtask_tb_lsu_ooo_simple__DOT__chk32__3__exp,
                  32,__Vtask_tb_lsu_ooo_simple__DOT__chk32__3__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    VL_WRITEF("\n[\346\265\213\350\257\2252] Load \346\214\207\344\273\244\345\272\224\350\257\245\350\277\233\345\205\245\347\255\211\345\276\205\347\212\266\346\200\201\n");
    vlSelf->tb_lsu_ooo_simple__DOT__valid_i = 1U;
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U] = (0x7fffffffU 
                                                  & vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U]);
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U] = (3U 
                                                  | (0xfffffff0U 
                                                     & vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U]));
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U] = (0x20U 
                                                  | (0xffffff9fU 
                                                     & vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U]));
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[2U] = (0x1ffffffU 
                                                  & vlSelf->tb_lsu_ooo_simple__DOT__data_i[2U]);
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U] = (0x1000000U 
                                                  | (0xfe000000U 
                                                     & vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U]));
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[0U] = 0x100U;
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U] = (0x20000U 
                                                  | (0xfff8ffffU 
                                                     & vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U]));
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       62);
    co_await vlSelf->__VdlySched.delay(0x3e8ULL, "testbench/tb_lsu_ooo_simple.sv", 
                                       62);
    __Vtask_tb_lsu_ooo_simple__DOT__chk__5__act = vlSelf->tb_lsu_ooo_simple__DOT__ARVALID;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__5__exp = 1U;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__5__name = 
        std::string{"ARVALID (\345\217\221\345\207\272\350\257\273\350\257\267\346\261\202)"};
    if (((IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__5__exp) 
         == (IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__5__act))) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__5__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=%b  \345\256\236\351\231\205=%b\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__5__name),
                  1,(IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__5__exp),
                  1,__Vtask_tb_lsu_ooo_simple__DOT__chk__5__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    __Vtask_tb_lsu_ooo_simple__DOT__chk__6__act = (1U 
                                                   & (((~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__state)) 
                                                       & (~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_valid))) 
                                                      | (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_resp_fire)));
    __Vtask_tb_lsu_ooo_simple__DOT__chk__6__exp = 0U;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__6__name = 
        std::string{"ready (\344\270\215\346\216\245\345\217\227\346\226\260\350\276\223\345\205\245)"};
    if (((IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__6__exp) 
         == (IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__6__act))) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__6__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=%b  \345\256\236\351\231\205=%b\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__6__name),
                  1,(IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__6__exp),
                  1,__Vtask_tb_lsu_ooo_simple__DOT__chk__6__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    __Vtask_tb_lsu_ooo_simple__DOT__chk__7__act = vlSelf->tb_lsu_ooo_simple__DOT__complete_en_o;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__7__exp = 0U;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__7__name = 
        std::string{"complete_en (\346\234\252\345\256\214\346\210\220)"};
    if (((IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__7__exp) 
         == (IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__7__act))) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__7__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=%b  \345\256\236\351\231\205=%b\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__7__name),
                  1,(IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__7__exp),
                  1,__Vtask_tb_lsu_ooo_simple__DOT__chk__7__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       62);
    co_await vlSelf->__VdlySched.delay(0x3e8ULL, "testbench/tb_lsu_ooo_simple.sv", 
                                       62);
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       62);
    co_await vlSelf->__VdlySched.delay(0x3e8ULL, "testbench/tb_lsu_ooo_simple.sv", 
                                       62);
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       62);
    co_await vlSelf->__VdlySched.delay(0x3e8ULL, "testbench/tb_lsu_ooo_simple.sv", 
                                       62);
    __Vtask_tb_lsu_ooo_simple__DOT__chk__9__act = (1U 
                                                   & (((~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__state)) 
                                                       & (~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_valid))) 
                                                      | (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_resp_fire)));
    __Vtask_tb_lsu_ooo_simple__DOT__chk__9__exp = 0U;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__9__name = 
        std::string{"ready (\344\273\215\345\234\250\347\255\211\345\276\205)"};
    if (((IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__9__exp) 
         == (IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__9__act))) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__9__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=%b  \345\256\236\351\231\205=%b\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__9__name),
                  1,(IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__9__exp),
                  1,__Vtask_tb_lsu_ooo_simple__DOT__chk__9__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    VL_WRITEF("\n[\346\265\213\350\257\2253] Store \346\214\207\344\273\244\345\272\224\350\257\245\350\277\233\345\205\245\347\255\211\345\276\205\347\212\266\346\200\201\n");
    vlSelf->tb_lsu_ooo_simple__DOT__rst = 1U;
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       109);
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       109);
    vlSelf->tb_lsu_ooo_simple__DOT__rst = 0U;
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       111);
    co_await vlSelf->__VdlySched.delay(0x3e8ULL, "testbench/tb_lsu_ooo_simple.sv", 
                                       111);
    vlSelf->tb_lsu_ooo_simple__DOT__valid_i = 1U;
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U] = (0x80000000U 
                                                  | (0x7fffffffU 
                                                     & vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U]));
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U] = (3U 
                                                  | (0xfffffff0U 
                                                     & vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U]));
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U] = (0x40U 
                                                  | (0xffffff9fU 
                                                     & vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U]));
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U] = (0xde000000U 
                                                  | (0x1ffffffU 
                                                     & vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U]));
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[2U] = 0x1bd5b7dU;
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U] = (0x1000000U 
                                                  | (0xfe000000U 
                                                     & vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U]));
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[0U] = 0x200U;
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U] = (0x20000U 
                                                  | (0xfff8ffffU 
                                                     & vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U]));
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       62);
    co_await vlSelf->__VdlySched.delay(0x3e8ULL, "testbench/tb_lsu_ooo_simple.sv", 
                                       62);
    __Vtask_tb_lsu_ooo_simple__DOT__chk__11__act = 
        ((IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT____VdfgTmp_hff04b70f__0) 
         | ((2U == (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__w_state)) 
            | (1U == (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__w_state))));
    __Vtask_tb_lsu_ooo_simple__DOT__chk__11__exp = 1U;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__11__name = 
        std::string{"AWVALID (\345\217\221\345\207\272\345\206\231\345\234\260\345\235\200)"};
    if (((IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__11__exp) 
         == (IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__11__act))) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__11__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=%b  \345\256\236\351\231\205=%b\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__11__name),
                  1,(IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__11__exp),
                  1,__Vtask_tb_lsu_ooo_simple__DOT__chk__11__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    __Vtask_tb_lsu_ooo_simple__DOT__chk__12__act = 
        (1U & (((~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__state)) 
                & (~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_valid))) 
               | (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_resp_fire)));
    __Vtask_tb_lsu_ooo_simple__DOT__chk__12__exp = 0U;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__12__name = 
        std::string{"ready (\344\270\215\346\216\245\345\217\227\346\226\260\350\276\223\345\205\245)"};
    if (((IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__12__exp) 
         == (IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__12__act))) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__12__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=%b  \345\256\236\351\231\205=%b\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__12__name),
                  1,(IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__12__exp),
                  1,__Vtask_tb_lsu_ooo_simple__DOT__chk__12__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    __Vtask_tb_lsu_ooo_simple__DOT__chk__13__act = vlSelf->tb_lsu_ooo_simple__DOT__complete_en_o;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__13__exp = 0U;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__13__name = 
        std::string{"complete_en (\346\234\252\345\256\214\346\210\220)"};
    if (((IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__13__exp) 
         == (IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__13__act))) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__13__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=%b  \345\256\236\351\231\205=%b\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__13__name),
                  1,(IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__13__exp),
                  1,__Vtask_tb_lsu_ooo_simple__DOT__chk__13__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    VL_WRITEF("\n[\346\265\213\350\257\2254] \345\244\232\344\270\252\351\235\236\350\256\277\345\255\230\346\214\207\344\273\244\350\277\236\347\273\255\351\200\217\344\274\240\n");
    vlSelf->tb_lsu_ooo_simple__DOT__rst = 1U;
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       129);
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       129);
    vlSelf->tb_lsu_ooo_simple__DOT__rst = 0U;
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       131);
    co_await vlSelf->__VdlySched.delay(0x3e8ULL, "testbench/tb_lsu_ooo_simple.sv", 
                                       131);
    vlSelf->tb_lsu_ooo_simple__DOT__valid_i = 1U;
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U] = (0x7fffffffU 
                                                  & vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U]);
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U] = (5U 
                                                  | (0xfffffff0U 
                                                     & vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U]));
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U] = (0xffffff9fU 
                                                  & vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U]);
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       62);
    co_await vlSelf->__VdlySched.delay(0x3e8ULL, "testbench/tb_lsu_ooo_simple.sv", 
                                       62);
    __Vtask_tb_lsu_ooo_simple__DOT__chk__15__act = vlSelf->tb_lsu_ooo_simple__DOT__complete_en_o;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__15__exp = 1U;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__15__name = 
        std::string{"complete_en [0]"};
    if (((IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__15__exp) 
         == (IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__15__act))) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__15__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=%b  \345\256\236\351\231\205=%b\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__15__name),
                  1,(IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__15__exp),
                  1,__Vtask_tb_lsu_ooo_simple__DOT__chk__15__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    __Vtask_tb_lsu_ooo_simple__DOT__chk__16__act = 
        (1U & (((~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__state)) 
                & (~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_valid))) 
               | (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_resp_fire)));
    __Vtask_tb_lsu_ooo_simple__DOT__chk__16__exp = 1U;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__16__name = 
        std::string{"ready [0]"};
    if (((IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__16__exp) 
         == (IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__16__act))) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__16__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=%b  \345\256\236\351\231\205=%b\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__16__name),
                  1,(IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__16__exp),
                  1,__Vtask_tb_lsu_ooo_simple__DOT__chk__16__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    __Vtask_tb_lsu_ooo_simple__DOT__chk32__17__act 
        = vlSelf->tb_lsu_ooo_simple__DOT__complete_idx_o;
    __Vtask_tb_lsu_ooo_simple__DOT__chk32__17__exp = 0xaU;
    __Vtask_tb_lsu_ooo_simple__DOT__chk32__17__name = 
        std::string{"complete_idx [0]"};
    if ((__Vtask_tb_lsu_ooo_simple__DOT__chk32__17__exp 
         == __Vtask_tb_lsu_ooo_simple__DOT__chk32__17__act)) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk32__17__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=0x%08x  \345\256\236\351\231\205=0x%08x\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk32__17__name),
                  32,__Vtask_tb_lsu_ooo_simple__DOT__chk32__17__exp,
                  32,__Vtask_tb_lsu_ooo_simple__DOT__chk32__17__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    vlSelf->tb_lsu_ooo_simple__DOT__valid_i = 1U;
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U] = (0x80000000U 
                                                  | (0x7fffffffU 
                                                     & vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U]));
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U] = (5U 
                                                  | (0xfffffff0U 
                                                     & vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U]));
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U] = (0xffffff9fU 
                                                  & vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U]);
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       62);
    co_await vlSelf->__VdlySched.delay(0x3e8ULL, "testbench/tb_lsu_ooo_simple.sv", 
                                       62);
    __Vtask_tb_lsu_ooo_simple__DOT__chk__15__act = vlSelf->tb_lsu_ooo_simple__DOT__complete_en_o;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__15__exp = 1U;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__15__name = 
        std::string{"complete_en [1]"};
    if (((IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__15__exp) 
         == (IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__15__act))) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__15__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=%b  \345\256\236\351\231\205=%b\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__15__name),
                  1,(IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__15__exp),
                  1,__Vtask_tb_lsu_ooo_simple__DOT__chk__15__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    __Vtask_tb_lsu_ooo_simple__DOT__chk__16__act = 
        (1U & (((~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__state)) 
                & (~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_valid))) 
               | (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_resp_fire)));
    __Vtask_tb_lsu_ooo_simple__DOT__chk__16__exp = 1U;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__16__name = 
        std::string{"ready [1]"};
    if (((IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__16__exp) 
         == (IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__16__act))) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__16__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=%b  \345\256\236\351\231\205=%b\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__16__name),
                  1,(IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__16__exp),
                  1,__Vtask_tb_lsu_ooo_simple__DOT__chk__16__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    __Vtask_tb_lsu_ooo_simple__DOT__chk32__17__act 
        = vlSelf->tb_lsu_ooo_simple__DOT__complete_idx_o;
    __Vtask_tb_lsu_ooo_simple__DOT__chk32__17__exp = 0xbU;
    __Vtask_tb_lsu_ooo_simple__DOT__chk32__17__name = 
        std::string{"complete_idx [1]"};
    if ((__Vtask_tb_lsu_ooo_simple__DOT__chk32__17__exp 
         == __Vtask_tb_lsu_ooo_simple__DOT__chk32__17__act)) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk32__17__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=0x%08x  \345\256\236\351\231\205=0x%08x\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk32__17__name),
                  32,__Vtask_tb_lsu_ooo_simple__DOT__chk32__17__exp,
                  32,__Vtask_tb_lsu_ooo_simple__DOT__chk32__17__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    vlSelf->tb_lsu_ooo_simple__DOT__valid_i = 1U;
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U] = (0x7fffffffU 
                                                  & vlSelf->tb_lsu_ooo_simple__DOT__data_i[3U]);
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U] = (6U 
                                                  | (0xfffffff0U 
                                                     & vlSelf->tb_lsu_ooo_simple__DOT__data_i[4U]));
    vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U] = (0xffffff9fU 
                                                  & vlSelf->tb_lsu_ooo_simple__DOT__data_i[1U]);
    co_await vlSelf->__VtrigSched_hfc645c1e__0.trigger(
                                                       "@(posedge tb_lsu_ooo_simple.clk)", 
                                                       "testbench/tb_lsu_ooo_simple.sv", 
                                                       62);
    co_await vlSelf->__VdlySched.delay(0x3e8ULL, "testbench/tb_lsu_ooo_simple.sv", 
                                       62);
    __Vtask_tb_lsu_ooo_simple__DOT__chk__15__act = vlSelf->tb_lsu_ooo_simple__DOT__complete_en_o;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__15__exp = 1U;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__15__name = 
        std::string{"complete_en [2]"};
    if (((IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__15__exp) 
         == (IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__15__act))) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__15__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=%b  \345\256\236\351\231\205=%b\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__15__name),
                  1,(IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__15__exp),
                  1,__Vtask_tb_lsu_ooo_simple__DOT__chk__15__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    __Vtask_tb_lsu_ooo_simple__DOT__chk__16__act = 
        (1U & (((~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__state)) 
                & (~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_valid))) 
               | (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_resp_fire)));
    __Vtask_tb_lsu_ooo_simple__DOT__chk__16__exp = 1U;
    __Vtask_tb_lsu_ooo_simple__DOT__chk__16__name = 
        std::string{"ready [2]"};
    if (((IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__16__exp) 
         == (IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__16__act))) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__16__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=%b  \345\256\236\351\231\205=%b\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk__16__name),
                  1,(IData)(__Vtask_tb_lsu_ooo_simple__DOT__chk__16__exp),
                  1,__Vtask_tb_lsu_ooo_simple__DOT__chk__16__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    __Vtask_tb_lsu_ooo_simple__DOT__chk32__17__act 
        = vlSelf->tb_lsu_ooo_simple__DOT__complete_idx_o;
    __Vtask_tb_lsu_ooo_simple__DOT__chk32__17__exp = 0xcU;
    __Vtask_tb_lsu_ooo_simple__DOT__chk32__17__name = 
        std::string{"complete_idx [2]"};
    if ((__Vtask_tb_lsu_ooo_simple__DOT__chk32__17__exp 
         == __Vtask_tb_lsu_ooo_simple__DOT__chk32__17__act)) {
        VL_WRITEF("  [PASS] %@\n",-1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk32__17__name));
        vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt);
    } else {
        VL_WRITEF("  [FAIL] %@  \346\234\237\346\234\233=0x%08x  \345\256\236\351\231\205=0x%08x\n",
                  -1,&(__Vtask_tb_lsu_ooo_simple__DOT__chk32__17__name),
                  32,__Vtask_tb_lsu_ooo_simple__DOT__chk32__17__exp,
                  32,__Vtask_tb_lsu_ooo_simple__DOT__chk32__17__act);
        vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt = 
            ((IData)(1U) + vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    }
    VL_WRITEF("\n=== \346\265\213\350\257\225\346\261\207\346\200\273 ===\n\351\200\232\350\277\207: %0d\n\345\244\261\350\264\245: %0d\n",
              32,vlSelf->tb_lsu_ooo_simple__DOT__pass_cnt,
              32,vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt);
    if ((0U == vlSelf->tb_lsu_ooo_simple__DOT__fail_cnt)) {
        VL_WRITEF("\n\342\234\223 \346\211\200\346\234\211\346\265\213\350\257\225\351\200\232\350\277\207\357\274\201\n");
    } else {
        VL_WRITEF("\n\342\234\227 \346\234\211\346\265\213\350\257\225\345\244\261\350\264\245\n");
    }
    VL_FINISH_MT("testbench/tb_lsu_ooo_simple.sv", 152, "");
}

VL_INLINE_OPT VlCoroutine Vtb_lsu_ooo_simple___024root___eval_initial__TOP__1(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___eval_initial__TOP__1\n"); );
    // Body
    while (1U) {
        co_await vlSelf->__VdlySched.delay(0x1388ULL, 
                                           "testbench/tb_lsu_ooo_simple.sv", 
                                           13);
        vlSelf->tb_lsu_ooo_simple__DOT__clk = (1U & 
                                               (~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__clk)));
    }
}

extern const VlUnpacked<CData/*2:0*/, 32> Vtb_lsu_ooo_simple__ConstPool__TABLE_h947ad2ce_0;

VL_INLINE_OPT void Vtb_lsu_ooo_simple___024root___act_comb__TOP__0(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___act_comb__TOP__0\n"); );
    // Init
    CData/*0:0*/ tb_lsu_ooo_simple__DOT__dut__DOT__mem_req_fire;
    tb_lsu_ooo_simple__DOT__dut__DOT__mem_req_fire = 0;
    CData/*4:0*/ __Vtableidx1;
    __Vtableidx1 = 0;
    // Body
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

void Vtb_lsu_ooo_simple___024root___eval_act(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___eval_act\n"); );
    // Body
    if ((vlSelf->__VactTriggered.at(0U) | vlSelf->__VactTriggered.at(1U))) {
        Vtb_lsu_ooo_simple___024root___act_comb__TOP__0(vlSelf);
    }
}

VL_INLINE_OPT void Vtb_lsu_ooo_simple___024root___nba_sequent__TOP__0(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___nba_sequent__TOP__0\n"); );
    // Body
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__rdone = 0U;
    if (vlSelf->tb_lsu_ooo_simple__DOT__rst) {
        vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__r_state = 0U;
        vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__w_state = 0U;
    } else {
        vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__r_state 
            = vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__next_r_state;
        vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__w_state 
            = vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__next_w_state;
    }
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__state 
        = ((~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__rst)) 
           & (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__nstate));
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_resp_fire 
        = ((IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__state) 
           & (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__u_axi4_full_master__DOT__rdone));
}

VL_INLINE_OPT void Vtb_lsu_ooo_simple___024root___nba_comb__TOP__0(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___nba_comb__TOP__0\n"); );
    // Init
    CData/*0:0*/ tb_lsu_ooo_simple__DOT__dut__DOT__mem_req_fire;
    tb_lsu_ooo_simple__DOT__dut__DOT__mem_req_fire = 0;
    CData/*4:0*/ __Vtableidx1;
    __Vtableidx1 = 0;
    // Body
    vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_valid 
        = ((IData)(vlSelf->tb_lsu_ooo_simple__DOT__valid_i) 
           & (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__is_mem));
    tb_lsu_ooo_simple__DOT__dut__DOT__mem_req_fire 
        = ((~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__state)) 
           & ((IData)(vlSelf->tb_lsu_ooo_simple__DOT__valid_i) 
              & (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__is_mem)));
    vlSelf->tb_lsu_ooo_simple__DOT__complete_en_o = 
        (((~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__state)) 
          & ((~ (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__is_mem)) 
             & (IData)(vlSelf->tb_lsu_ooo_simple__DOT__valid_i))) 
         | (IData)(vlSelf->tb_lsu_ooo_simple__DOT__dut__DOT__mem_resp_fire));
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

void Vtb_lsu_ooo_simple___024root___eval_nba(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___eval_nba\n"); );
    // Body
    if (vlSelf->__VnbaTriggered.at(0U)) {
        Vtb_lsu_ooo_simple___024root___nba_sequent__TOP__0(vlSelf);
    }
    if ((vlSelf->__VnbaTriggered.at(0U) | vlSelf->__VnbaTriggered.at(1U))) {
        Vtb_lsu_ooo_simple___024root___nba_comb__TOP__0(vlSelf);
    }
}

void Vtb_lsu_ooo_simple___024root___eval_triggers__act(Vtb_lsu_ooo_simple___024root* vlSelf);
void Vtb_lsu_ooo_simple___024root___timing_commit(Vtb_lsu_ooo_simple___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_lsu_ooo_simple___024root___dump_triggers__act(Vtb_lsu_ooo_simple___024root* vlSelf);
#endif  // VL_DEBUG
void Vtb_lsu_ooo_simple___024root___timing_resume(Vtb_lsu_ooo_simple___024root* vlSelf);
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_lsu_ooo_simple___024root___dump_triggers__nba(Vtb_lsu_ooo_simple___024root* vlSelf);
#endif  // VL_DEBUG

void Vtb_lsu_ooo_simple___024root___eval(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___eval\n"); );
    // Init
    VlTriggerVec<2> __VpreTriggered;
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
            Vtb_lsu_ooo_simple___024root___eval_triggers__act(vlSelf);
            Vtb_lsu_ooo_simple___024root___timing_commit(vlSelf);
            if (vlSelf->__VactTriggered.any()) {
                vlSelf->__VactContinue = 1U;
                if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                    Vtb_lsu_ooo_simple___024root___dump_triggers__act(vlSelf);
#endif
                    VL_FATAL_MT("testbench/tb_lsu_ooo_simple.sv", 8, "", "Active region did not converge.");
                }
                vlSelf->__VactIterCount = ((IData)(1U) 
                                           + vlSelf->__VactIterCount);
                __VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
                vlSelf->__VnbaTriggered.set(vlSelf->__VactTriggered);
                Vtb_lsu_ooo_simple___024root___timing_resume(vlSelf);
                Vtb_lsu_ooo_simple___024root___eval_act(vlSelf);
            }
        }
        if (vlSelf->__VnbaTriggered.any()) {
            __VnbaContinue = 1U;
            if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
                Vtb_lsu_ooo_simple___024root___dump_triggers__nba(vlSelf);
#endif
                VL_FATAL_MT("testbench/tb_lsu_ooo_simple.sv", 8, "", "NBA region did not converge.");
            }
            __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
            Vtb_lsu_ooo_simple___024root___eval_nba(vlSelf);
        }
    }
}

void Vtb_lsu_ooo_simple___024root___timing_commit(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___timing_commit\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VactTriggered.at(0U))))) {
        vlSelf->__VtrigSched_hfc645c1e__0.commit("@(posedge tb_lsu_ooo_simple.clk)");
    }
}

void Vtb_lsu_ooo_simple___024root___timing_resume(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___timing_resume\n"); );
    // Body
    if (vlSelf->__VactTriggered.at(0U)) {
        vlSelf->__VtrigSched_hfc645c1e__0.resume("@(posedge tb_lsu_ooo_simple.clk)");
    }
    if (vlSelf->__VactTriggered.at(1U)) {
        vlSelf->__VdlySched.resume();
    }
}

#ifdef VL_DEBUG
void Vtb_lsu_ooo_simple___024root___eval_debug_assertions(Vtb_lsu_ooo_simple___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_lsu_ooo_simple__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_lsu_ooo_simple___024root___eval_debug_assertions\n"); );
}
#endif  // VL_DEBUG

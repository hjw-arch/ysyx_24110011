// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "VLSU_ooo_wrapper.h"
#include "VLSU_ooo_wrapper__Syms.h"

//============================================================
// Constructors

VLSU_ooo_wrapper::VLSU_ooo_wrapper(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new VLSU_ooo_wrapper__Syms(contextp(), _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , rst{vlSymsp->TOP.rst}
    , valid_i{vlSymsp->TOP.valid_i}
    , rob_idx_i{vlSymsp->TOP.rob_idx_i}
    , phys_rd_i{vlSymsp->TOP.phys_rd_i}
    , pred_taken_i{vlSymsp->TOP.pred_taken_i}
    , rd_wen_i{vlSymsp->TOP.rd_wen_i}
    , alu_op_i{vlSymsp->TOP.alu_op_i}
    , alu_src_i{vlSymsp->TOP.alu_src_i}
    , cfi_type_i{vlSymsp->TOP.cfi_type_i}
    , br_cond_i{vlSymsp->TOP.br_cond_i}
    , mem_cmd_i{vlSymsp->TOP.mem_cmd_i}
    , csr_cmd_i{vlSymsp->TOP.csr_cmd_i}
    , priv_redir_i{vlSymsp->TOP.priv_redir_i}
    , fence_i_i{vlSymsp->TOP.fence_i_i}
    , ready_o{vlSymsp->TOP.ready_o}
    , complete_en_o{vlSymsp->TOP.complete_en_o}
    , complete_idx_o{vlSymsp->TOP.complete_idx_o}
    , complete_exception_o{vlSymsp->TOP.complete_exception_o}
    , complete_cause_o{vlSymsp->TOP.complete_cause_o}
    , ARID{vlSymsp->TOP.ARID}
    , ARLEN{vlSymsp->TOP.ARLEN}
    , ARSIZE{vlSymsp->TOP.ARSIZE}
    , ARBURST{vlSymsp->TOP.ARBURST}
    , ARVALID{vlSymsp->TOP.ARVALID}
    , ARREADY{vlSymsp->TOP.ARREADY}
    , RID{vlSymsp->TOP.RID}
    , RRESP{vlSymsp->TOP.RRESP}
    , RVALID{vlSymsp->TOP.RVALID}
    , RLAST{vlSymsp->TOP.RLAST}
    , RREADY{vlSymsp->TOP.RREADY}
    , AWLEN{vlSymsp->TOP.AWLEN}
    , AWSIZE{vlSymsp->TOP.AWSIZE}
    , AWID{vlSymsp->TOP.AWID}
    , AWBURST{vlSymsp->TOP.AWBURST}
    , AWVALID{vlSymsp->TOP.AWVALID}
    , AWREADY{vlSymsp->TOP.AWREADY}
    , WLAST{vlSymsp->TOP.WLAST}
    , WSTRB{vlSymsp->TOP.WSTRB}
    , WVALID{vlSymsp->TOP.WVALID}
    , WREADY{vlSymsp->TOP.WREADY}
    , BID{vlSymsp->TOP.BID}
    , BRESP{vlSymsp->TOP.BRESP}
    , BVALID{vlSymsp->TOP.BVALID}
    , BREADY{vlSymsp->TOP.BREADY}
    , pc_i{vlSymsp->TOP.pc_i}
    , inst_i{vlSymsp->TOP.inst_i}
    , rs1_data_i{vlSymsp->TOP.rs1_data_i}
    , rs2_data_i{vlSymsp->TOP.rs2_data_i}
    , imm_i{vlSymsp->TOP.imm_i}
    , complete_data_o{vlSymsp->TOP.complete_data_o}
    , ARADDR{vlSymsp->TOP.ARADDR}
    , RDATA{vlSymsp->TOP.RDATA}
    , AWADDR{vlSymsp->TOP.AWADDR}
    , WDATA{vlSymsp->TOP.WDATA}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

VLSU_ooo_wrapper::VLSU_ooo_wrapper(const char* _vcname__)
    : VLSU_ooo_wrapper(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

VLSU_ooo_wrapper::~VLSU_ooo_wrapper() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void VLSU_ooo_wrapper___024root___eval_debug_assertions(VLSU_ooo_wrapper___024root* vlSelf);
#endif  // VL_DEBUG
void VLSU_ooo_wrapper___024root___eval_static(VLSU_ooo_wrapper___024root* vlSelf);
void VLSU_ooo_wrapper___024root___eval_initial(VLSU_ooo_wrapper___024root* vlSelf);
void VLSU_ooo_wrapper___024root___eval_settle(VLSU_ooo_wrapper___024root* vlSelf);
void VLSU_ooo_wrapper___024root___eval(VLSU_ooo_wrapper___024root* vlSelf);

void VLSU_ooo_wrapper::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate VLSU_ooo_wrapper::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    VLSU_ooo_wrapper___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        VLSU_ooo_wrapper___024root___eval_static(&(vlSymsp->TOP));
        VLSU_ooo_wrapper___024root___eval_initial(&(vlSymsp->TOP));
        VLSU_ooo_wrapper___024root___eval_settle(&(vlSymsp->TOP));
    }
    // MTask 0 start
    VL_DEBUG_IF(VL_DBG_MSGF("MTask0 starting\n"););
    Verilated::mtaskId(0);
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    VLSU_ooo_wrapper___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfThreadMTask(vlSymsp->__Vm_evalMsgQp);
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool VLSU_ooo_wrapper::eventsPending() { return false; }

uint64_t VLSU_ooo_wrapper::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "%Error: No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* VLSU_ooo_wrapper::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void VLSU_ooo_wrapper___024root___eval_final(VLSU_ooo_wrapper___024root* vlSelf);

VL_ATTR_COLD void VLSU_ooo_wrapper::final() {
    VLSU_ooo_wrapper___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* VLSU_ooo_wrapper::hierName() const { return vlSymsp->name(); }
const char* VLSU_ooo_wrapper::modelName() const { return "VLSU_ooo_wrapper"; }
unsigned VLSU_ooo_wrapper::threads() const { return 1; }

// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "VEXU_ooo_wrapper.h"
#include "VEXU_ooo_wrapper__Syms.h"

//============================================================
// Constructors

VEXU_ooo_wrapper::VEXU_ooo_wrapper(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new VEXU_ooo_wrapper__Syms(contextp(), _vcname__, this)}
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
    , complete_redirect_valid_o{vlSymsp->TOP.complete_redirect_valid_o}
    , wakeup_en_o{vlSymsp->TOP.wakeup_en_o}
    , wakeup_preg_o{vlSymsp->TOP.wakeup_preg_o}
    , redirect_valid_o{vlSymsp->TOP.redirect_valid_o}
    , bpu_update_valid_o{vlSymsp->TOP.bpu_update_valid_o}
    , bpu_update_btb_type_o{vlSymsp->TOP.bpu_update_btb_type_o}
    , bpu_update_taken_o{vlSymsp->TOP.bpu_update_taken_o}
    , pc_i{vlSymsp->TOP.pc_i}
    , inst_i{vlSymsp->TOP.inst_i}
    , rs1_data_i{vlSymsp->TOP.rs1_data_i}
    , rs2_data_i{vlSymsp->TOP.rs2_data_i}
    , imm_i{vlSymsp->TOP.imm_i}
    , complete_data_o{vlSymsp->TOP.complete_data_o}
    , complete_redirect_addr_o{vlSymsp->TOP.complete_redirect_addr_o}
    , redirect_addr_o{vlSymsp->TOP.redirect_addr_o}
    , bpu_update_target_o{vlSymsp->TOP.bpu_update_target_o}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

VEXU_ooo_wrapper::VEXU_ooo_wrapper(const char* _vcname__)
    : VEXU_ooo_wrapper(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

VEXU_ooo_wrapper::~VEXU_ooo_wrapper() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void VEXU_ooo_wrapper___024root___eval_debug_assertions(VEXU_ooo_wrapper___024root* vlSelf);
#endif  // VL_DEBUG
void VEXU_ooo_wrapper___024root___eval_static(VEXU_ooo_wrapper___024root* vlSelf);
void VEXU_ooo_wrapper___024root___eval_initial(VEXU_ooo_wrapper___024root* vlSelf);
void VEXU_ooo_wrapper___024root___eval_settle(VEXU_ooo_wrapper___024root* vlSelf);
void VEXU_ooo_wrapper___024root___eval(VEXU_ooo_wrapper___024root* vlSelf);

void VEXU_ooo_wrapper::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate VEXU_ooo_wrapper::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    VEXU_ooo_wrapper___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        VEXU_ooo_wrapper___024root___eval_static(&(vlSymsp->TOP));
        VEXU_ooo_wrapper___024root___eval_initial(&(vlSymsp->TOP));
        VEXU_ooo_wrapper___024root___eval_settle(&(vlSymsp->TOP));
    }
    // MTask 0 start
    VL_DEBUG_IF(VL_DBG_MSGF("MTask0 starting\n"););
    Verilated::mtaskId(0);
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    VEXU_ooo_wrapper___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfThreadMTask(vlSymsp->__Vm_evalMsgQp);
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool VEXU_ooo_wrapper::eventsPending() { return false; }

uint64_t VEXU_ooo_wrapper::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "%Error: No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* VEXU_ooo_wrapper::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void VEXU_ooo_wrapper___024root___eval_final(VEXU_ooo_wrapper___024root* vlSelf);

VL_ATTR_COLD void VEXU_ooo_wrapper::final() {
    VEXU_ooo_wrapper___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* VEXU_ooo_wrapper::hierName() const { return vlSymsp->name(); }
const char* VEXU_ooo_wrapper::modelName() const { return "VEXU_ooo_wrapper"; }
unsigned VEXU_ooo_wrapper::threads() const { return 1; }

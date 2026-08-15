// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "VEXU_ooo.h"
#include "VEXU_ooo__Syms.h"

//============================================================
// Constructors

VEXU_ooo::VEXU_ooo(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new VEXU_ooo__Syms(contextp(), _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , rst{vlSymsp->TOP.rst}
    , valid_i{vlSymsp->TOP.valid_i}
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
    , complete_data_o{vlSymsp->TOP.complete_data_o}
    , complete_redirect_addr_o{vlSymsp->TOP.complete_redirect_addr_o}
    , redirect_addr_o{vlSymsp->TOP.redirect_addr_o}
    , bpu_update_target_o{vlSymsp->TOP.bpu_update_target_o}
    , data_i{vlSymsp->TOP.data_i}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

VEXU_ooo::VEXU_ooo(const char* _vcname__)
    : VEXU_ooo(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

VEXU_ooo::~VEXU_ooo() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void VEXU_ooo___024root___eval_debug_assertions(VEXU_ooo___024root* vlSelf);
#endif  // VL_DEBUG
void VEXU_ooo___024root___eval_static(VEXU_ooo___024root* vlSelf);
void VEXU_ooo___024root___eval_initial(VEXU_ooo___024root* vlSelf);
void VEXU_ooo___024root___eval_settle(VEXU_ooo___024root* vlSelf);
void VEXU_ooo___024root___eval(VEXU_ooo___024root* vlSelf);

void VEXU_ooo::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate VEXU_ooo::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    VEXU_ooo___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        VEXU_ooo___024root___eval_static(&(vlSymsp->TOP));
        VEXU_ooo___024root___eval_initial(&(vlSymsp->TOP));
        VEXU_ooo___024root___eval_settle(&(vlSymsp->TOP));
    }
    // MTask 0 start
    VL_DEBUG_IF(VL_DBG_MSGF("MTask0 starting\n"););
    Verilated::mtaskId(0);
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    VEXU_ooo___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfThreadMTask(vlSymsp->__Vm_evalMsgQp);
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool VEXU_ooo::eventsPending() { return false; }

uint64_t VEXU_ooo::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "%Error: No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* VEXU_ooo::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void VEXU_ooo___024root___eval_final(VEXU_ooo___024root* vlSelf);

VL_ATTR_COLD void VEXU_ooo::final() {
    VEXU_ooo___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* VEXU_ooo::hierName() const { return vlSymsp->name(); }
const char* VEXU_ooo::modelName() const { return "VEXU_ooo"; }
unsigned VEXU_ooo::threads() const { return 1; }

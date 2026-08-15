// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vtb_lsu_ooo_simple.h"
#include "Vtb_lsu_ooo_simple__Syms.h"

//============================================================
// Constructors

Vtb_lsu_ooo_simple::Vtb_lsu_ooo_simple(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vtb_lsu_ooo_simple__Syms(contextp(), _vcname__, this)}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vtb_lsu_ooo_simple::Vtb_lsu_ooo_simple(const char* _vcname__)
    : Vtb_lsu_ooo_simple(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vtb_lsu_ooo_simple::~Vtb_lsu_ooo_simple() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vtb_lsu_ooo_simple___024root___eval_debug_assertions(Vtb_lsu_ooo_simple___024root* vlSelf);
#endif  // VL_DEBUG
void Vtb_lsu_ooo_simple___024root___eval_static(Vtb_lsu_ooo_simple___024root* vlSelf);
void Vtb_lsu_ooo_simple___024root___eval_initial(Vtb_lsu_ooo_simple___024root* vlSelf);
void Vtb_lsu_ooo_simple___024root___eval_settle(Vtb_lsu_ooo_simple___024root* vlSelf);
void Vtb_lsu_ooo_simple___024root___eval(Vtb_lsu_ooo_simple___024root* vlSelf);

void Vtb_lsu_ooo_simple::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vtb_lsu_ooo_simple::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vtb_lsu_ooo_simple___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vtb_lsu_ooo_simple___024root___eval_static(&(vlSymsp->TOP));
        Vtb_lsu_ooo_simple___024root___eval_initial(&(vlSymsp->TOP));
        Vtb_lsu_ooo_simple___024root___eval_settle(&(vlSymsp->TOP));
    }
    // MTask 0 start
    VL_DEBUG_IF(VL_DBG_MSGF("MTask0 starting\n"););
    Verilated::mtaskId(0);
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vtb_lsu_ooo_simple___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfThreadMTask(vlSymsp->__Vm_evalMsgQp);
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vtb_lsu_ooo_simple::eventsPending() { return !vlSymsp->TOP.__VdlySched.empty(); }

uint64_t Vtb_lsu_ooo_simple::nextTimeSlot() { return vlSymsp->TOP.__VdlySched.nextTimeSlot(); }

//============================================================
// Utilities

const char* Vtb_lsu_ooo_simple::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vtb_lsu_ooo_simple___024root___eval_final(Vtb_lsu_ooo_simple___024root* vlSelf);

VL_ATTR_COLD void Vtb_lsu_ooo_simple::final() {
    Vtb_lsu_ooo_simple___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vtb_lsu_ooo_simple::hierName() const { return vlSymsp->name(); }
const char* Vtb_lsu_ooo_simple::modelName() const { return "Vtb_lsu_ooo_simple"; }
unsigned Vtb_lsu_ooo_simple::threads() const { return 1; }

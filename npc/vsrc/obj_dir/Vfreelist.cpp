// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vfreelist.h"
#include "Vfreelist__Syms.h"

//============================================================
// Constructors

Vfreelist::Vfreelist(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vfreelist__Syms(contextp(), _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , rst{vlSymsp->TOP.rst}
    , alloc_en_i{vlSymsp->TOP.alloc_en_i}
    , alloc_preg_o{vlSymsp->TOP.alloc_preg_o}
    , alloc_valid_o{vlSymsp->TOP.alloc_valid_o}
    , free_en_i{vlSymsp->TOP.free_en_i}
    , free_preg_i{vlSymsp->TOP.free_preg_i}
    , empty_o{vlSymsp->TOP.empty_o}
    , free_count_o{vlSymsp->TOP.free_count_o}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vfreelist::Vfreelist(const char* _vcname__)
    : Vfreelist(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vfreelist::~Vfreelist() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vfreelist___024root___eval_debug_assertions(Vfreelist___024root* vlSelf);
#endif  // VL_DEBUG
void Vfreelist___024root___eval_static(Vfreelist___024root* vlSelf);
void Vfreelist___024root___eval_initial(Vfreelist___024root* vlSelf);
void Vfreelist___024root___eval_settle(Vfreelist___024root* vlSelf);
void Vfreelist___024root___eval(Vfreelist___024root* vlSelf);

void Vfreelist::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vfreelist::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vfreelist___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vfreelist___024root___eval_static(&(vlSymsp->TOP));
        Vfreelist___024root___eval_initial(&(vlSymsp->TOP));
        Vfreelist___024root___eval_settle(&(vlSymsp->TOP));
    }
    // MTask 0 start
    VL_DEBUG_IF(VL_DBG_MSGF("MTask0 starting\n"););
    Verilated::mtaskId(0);
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vfreelist___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfThreadMTask(vlSymsp->__Vm_evalMsgQp);
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vfreelist::eventsPending() { return false; }

uint64_t Vfreelist::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "%Error: No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vfreelist::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vfreelist___024root___eval_final(Vfreelist___024root* vlSelf);

VL_ATTR_COLD void Vfreelist::final() {
    Vfreelist___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vfreelist::hierName() const { return vlSymsp->name(); }
const char* Vfreelist::modelName() const { return "Vfreelist"; }
unsigned Vfreelist::threads() const { return 1; }

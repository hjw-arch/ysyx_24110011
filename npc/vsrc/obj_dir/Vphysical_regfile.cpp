// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vphysical_regfile.h"
#include "Vphysical_regfile__Syms.h"

//============================================================
// Constructors

Vphysical_regfile::Vphysical_regfile(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vphysical_regfile__Syms(contextp(), _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , rst{vlSymsp->TOP.rst}
    , raddr1_i{vlSymsp->TOP.raddr1_i}
    , raddr2_i{vlSymsp->TOP.raddr2_i}
    , wen1_i{vlSymsp->TOP.wen1_i}
    , waddr1_i{vlSymsp->TOP.waddr1_i}
    , wen2_i{vlSymsp->TOP.wen2_i}
    , waddr2_i{vlSymsp->TOP.waddr2_i}
    , rdata1_o{vlSymsp->TOP.rdata1_o}
    , rdata2_o{vlSymsp->TOP.rdata2_o}
    , wdata1_i{vlSymsp->TOP.wdata1_i}
    , wdata2_i{vlSymsp->TOP.wdata2_i}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vphysical_regfile::Vphysical_regfile(const char* _vcname__)
    : Vphysical_regfile(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vphysical_regfile::~Vphysical_regfile() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vphysical_regfile___024root___eval_debug_assertions(Vphysical_regfile___024root* vlSelf);
#endif  // VL_DEBUG
void Vphysical_regfile___024root___eval_static(Vphysical_regfile___024root* vlSelf);
void Vphysical_regfile___024root___eval_initial(Vphysical_regfile___024root* vlSelf);
void Vphysical_regfile___024root___eval_settle(Vphysical_regfile___024root* vlSelf);
void Vphysical_regfile___024root___eval(Vphysical_regfile___024root* vlSelf);

void Vphysical_regfile::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vphysical_regfile::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vphysical_regfile___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vphysical_regfile___024root___eval_static(&(vlSymsp->TOP));
        Vphysical_regfile___024root___eval_initial(&(vlSymsp->TOP));
        Vphysical_regfile___024root___eval_settle(&(vlSymsp->TOP));
    }
    // MTask 0 start
    VL_DEBUG_IF(VL_DBG_MSGF("MTask0 starting\n"););
    Verilated::mtaskId(0);
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vphysical_regfile___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfThreadMTask(vlSymsp->__Vm_evalMsgQp);
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vphysical_regfile::eventsPending() { return false; }

uint64_t Vphysical_regfile::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "%Error: No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vphysical_regfile::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vphysical_regfile___024root___eval_final(Vphysical_regfile___024root* vlSelf);

VL_ATTR_COLD void Vphysical_regfile::final() {
    Vphysical_regfile___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vphysical_regfile::hierName() const { return vlSymsp->name(); }
const char* Vphysical_regfile::modelName() const { return "Vphysical_regfile"; }
unsigned Vphysical_regfile::threads() const { return 1; }

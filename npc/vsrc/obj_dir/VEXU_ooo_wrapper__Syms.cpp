// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "VEXU_ooo_wrapper__Syms.h"
#include "VEXU_ooo_wrapper.h"
#include "VEXU_ooo_wrapper___024root.h"

// FUNCTIONS
VEXU_ooo_wrapper__Syms::~VEXU_ooo_wrapper__Syms()
{
}

VEXU_ooo_wrapper__Syms::VEXU_ooo_wrapper__Syms(VerilatedContext* contextp, const char* namep, VEXU_ooo_wrapper* modelp)
    : VerilatedSyms{contextp}
    // Setup internal state of the Syms class
    , __Vm_modelp{modelp}
    // Setup module instances
    , TOP{this, namep}
{
    // Configure time unit / time precision
    _vm_contextp__->timeunit(-12);
    _vm_contextp__->timeprecision(-12);
    // Setup each module's pointers to their submodules
    // Setup each module's pointer back to symbol table (for public functions)
    TOP.__Vconfigure(true);
}

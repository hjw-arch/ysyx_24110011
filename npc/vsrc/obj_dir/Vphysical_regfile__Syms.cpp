// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vphysical_regfile__Syms.h"
#include "Vphysical_regfile.h"
#include "Vphysical_regfile___024root.h"

// FUNCTIONS
Vphysical_regfile__Syms::~Vphysical_regfile__Syms()
{
}

Vphysical_regfile__Syms::Vphysical_regfile__Syms(VerilatedContext* contextp, const char* namep, Vphysical_regfile* modelp)
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

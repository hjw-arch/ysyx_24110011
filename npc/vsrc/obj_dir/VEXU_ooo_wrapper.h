// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Primary model header
//
// This header should be included by all source files instantiating the design.
// The class here is then constructed to instantiate the design.
// See the Verilator manual for examples.

#ifndef VERILATED_VEXU_OOO_WRAPPER_H_
#define VERILATED_VEXU_OOO_WRAPPER_H_  // guard

#include "verilated.h"

class VEXU_ooo_wrapper__Syms;
class VEXU_ooo_wrapper___024root;

// This class is the main interface to the Verilated model
class VEXU_ooo_wrapper VL_NOT_FINAL : public VerilatedModel {
  private:
    // Symbol table holding complete model state (owned by this class)
    VEXU_ooo_wrapper__Syms* const vlSymsp;

  public:

    // PORTS
    // The application code writes and reads these signals to
    // propagate new values into/out from the Verilated model.
    VL_IN8(&clk,0,0);
    VL_IN8(&rst,0,0);
    VL_IN8(&valid_i,0,0);
    VL_IN8(&rob_idx_i,4,0);
    VL_IN8(&phys_rd_i,5,0);
    VL_IN8(&pred_taken_i,0,0);
    VL_IN8(&rd_wen_i,0,0);
    VL_IN8(&alu_op_i,3,0);
    VL_IN8(&alu_src_i,1,0);
    VL_IN8(&cfi_type_i,1,0);
    VL_IN8(&br_cond_i,2,0);
    VL_IN8(&mem_cmd_i,2,0);
    VL_IN8(&csr_cmd_i,1,0);
    VL_IN8(&priv_redir_i,1,0);
    VL_IN8(&fence_i_i,0,0);
    VL_OUT8(&ready_o,0,0);
    VL_OUT8(&complete_en_o,0,0);
    VL_OUT8(&complete_idx_o,4,0);
    VL_OUT8(&complete_exception_o,0,0);
    VL_OUT8(&complete_cause_o,3,0);
    VL_OUT8(&complete_redirect_valid_o,0,0);
    VL_OUT8(&wakeup_en_o,0,0);
    VL_OUT8(&wakeup_preg_o,5,0);
    VL_OUT8(&redirect_valid_o,0,0);
    VL_OUT8(&bpu_update_valid_o,0,0);
    VL_OUT8(&bpu_update_btb_type_o,0,0);
    VL_OUT8(&bpu_update_taken_o,0,0);
    VL_IN(&pc_i,31,0);
    VL_IN(&inst_i,31,0);
    VL_IN(&rs1_data_i,31,0);
    VL_IN(&rs2_data_i,31,0);
    VL_IN(&imm_i,31,0);
    VL_OUT(&complete_data_o,31,0);
    VL_OUT(&complete_redirect_addr_o,31,0);
    VL_OUT(&redirect_addr_o,31,0);
    VL_OUT(&bpu_update_target_o,31,0);

    // CELLS
    // Public to allow access to /* verilator public */ items.
    // Otherwise the application code can consider these internals.

    // Root instance pointer to allow access to model internals,
    // including inlined /* verilator public_flat_* */ items.
    VEXU_ooo_wrapper___024root* const rootp;

    // CONSTRUCTORS
    /// Construct the model; called by application code
    /// If contextp is null, then the model will use the default global context
    /// If name is "", then makes a wrapper with a
    /// single model invisible with respect to DPI scope names.
    explicit VEXU_ooo_wrapper(VerilatedContext* contextp, const char* name = "TOP");
    explicit VEXU_ooo_wrapper(const char* name = "TOP");
    /// Destroy the model; called (often implicitly) by application code
    virtual ~VEXU_ooo_wrapper();
  private:
    VL_UNCOPYABLE(VEXU_ooo_wrapper);  ///< Copying not allowed

  public:
    // API METHODS
    /// Evaluate the model.  Application must call when inputs change.
    void eval() { eval_step(); }
    /// Evaluate when calling multiple units/models per time step.
    void eval_step();
    /// Evaluate at end of a timestep for tracing, when using eval_step().
    /// Application must call after all eval() and before time changes.
    void eval_end_step() {}
    /// Simulation complete, run final blocks.  Application must call on completion.
    void final();
    /// Are there scheduled events to handle?
    bool eventsPending();
    /// Returns time at next time slot. Aborts if !eventsPending()
    uint64_t nextTimeSlot();
    /// Retrieve name of this model instance (as passed to constructor).
    const char* name() const;

    // Abstract methods from VerilatedModel
    const char* hierName() const override final;
    const char* modelName() const override final;
    unsigned threads() const override final;
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);

#endif  // guard

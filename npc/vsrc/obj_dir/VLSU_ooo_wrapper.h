// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Primary model header
//
// This header should be included by all source files instantiating the design.
// The class here is then constructed to instantiate the design.
// See the Verilator manual for examples.

#ifndef VERILATED_VLSU_OOO_WRAPPER_H_
#define VERILATED_VLSU_OOO_WRAPPER_H_  // guard

#include "verilated.h"

class VLSU_ooo_wrapper__Syms;
class VLSU_ooo_wrapper___024root;

// This class is the main interface to the Verilated model
class VLSU_ooo_wrapper VL_NOT_FINAL : public VerilatedModel {
  private:
    // Symbol table holding complete model state (owned by this class)
    VLSU_ooo_wrapper__Syms* const vlSymsp;

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
    VL_OUT8(&ARID,3,0);
    VL_OUT8(&ARLEN,7,0);
    VL_OUT8(&ARSIZE,2,0);
    VL_OUT8(&ARBURST,1,0);
    VL_OUT8(&ARVALID,0,0);
    VL_IN8(&ARREADY,0,0);
    VL_IN8(&RID,3,0);
    VL_IN8(&RRESP,1,0);
    VL_IN8(&RVALID,0,0);
    VL_IN8(&RLAST,0,0);
    VL_OUT8(&RREADY,0,0);
    VL_OUT8(&AWLEN,7,0);
    VL_OUT8(&AWSIZE,2,0);
    VL_OUT8(&AWID,3,0);
    VL_OUT8(&AWBURST,1,0);
    VL_OUT8(&AWVALID,0,0);
    VL_IN8(&AWREADY,0,0);
    VL_OUT8(&WLAST,0,0);
    VL_OUT8(&WSTRB,3,0);
    VL_OUT8(&WVALID,0,0);
    VL_IN8(&WREADY,0,0);
    VL_IN8(&BID,3,0);
    VL_IN8(&BRESP,1,0);
    VL_IN8(&BVALID,0,0);
    VL_OUT8(&BREADY,0,0);
    VL_IN(&pc_i,31,0);
    VL_IN(&inst_i,31,0);
    VL_IN(&rs1_data_i,31,0);
    VL_IN(&rs2_data_i,31,0);
    VL_IN(&imm_i,31,0);
    VL_OUT(&complete_data_o,31,0);
    VL_OUT(&ARADDR,31,0);
    VL_IN(&RDATA,31,0);
    VL_OUT(&AWADDR,31,0);
    VL_OUT(&WDATA,31,0);

    // CELLS
    // Public to allow access to /* verilator public */ items.
    // Otherwise the application code can consider these internals.

    // Root instance pointer to allow access to model internals,
    // including inlined /* verilator public_flat_* */ items.
    VLSU_ooo_wrapper___024root* const rootp;

    // CONSTRUCTORS
    /// Construct the model; called by application code
    /// If contextp is null, then the model will use the default global context
    /// If name is "", then makes a wrapper with a
    /// single model invisible with respect to DPI scope names.
    explicit VLSU_ooo_wrapper(VerilatedContext* contextp, const char* name = "TOP");
    explicit VLSU_ooo_wrapper(const char* name = "TOP");
    /// Destroy the model; called (often implicitly) by application code
    virtual ~VLSU_ooo_wrapper();
  private:
    VL_UNCOPYABLE(VLSU_ooo_wrapper);  ///< Copying not allowed

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

package define_pkg;
`include "define.svh"
  //================= OPCODE Definitions =================//
  typedef enum logic [4:0] {
    OPCODE_LUI    = 5'b01101,
    OPCODE_AUIPC  = 5'b00101,
    OPCODE_JAL    = 5'b11011,
    OPCODE_JALR   = 5'b11001,
    OPCODE_BRANCH = 5'b11000,
    OPCODE_LOAD   = 5'b00000,
    OPCODE_STORE  = 5'b01000,
    OPCODE_FENCE  = 5'b00011,
    OPCODE_CAL_I  = 5'b00100,
    OPCODE_CAL_R  = 5'b01100,
    OPCODE_SYS    = 5'b11100
  } opcode_type_e;

  //================= FUNC3 Definitions =================//
  typedef enum logic [2:0] {
    FUNC3_SRA     = 3'b101
  } func3_type_e;

  //================= Branch Conditions =================//
  typedef enum logic [1:0] {
    BRANCH_EQ     = 2'b00,
    BRANCH_NE     = 2'b01,
    BRANCH_LT     = 2'b10,
    BRANCH_GE     = 2'b11
  } branch_cond_e;

  //================= Load Types =================//
  typedef enum logic [2:0] {
    LOAD_TYPE_LB   = 3'b000,
    LOAD_TYPE_LH   = 3'b001,
    LOAD_TYPE_LW   = 3'b010,
    LOAD_TYPE_LBU  = 3'b100,
    LOAD_TYPE_LHU  = 3'b101
  } load_type_e;

  //================= Macro-like Functions (Use functions or constants) =================//
  // 这些可以作为函数或参数化表达式使用，但 SV package 不支持宏定义。
  // 可以在模块中使用如下逻辑代替：
  //
  // 示例：
  // assign is_r_type = (opcode == OPCODE_CAL_R);
  // assign is_srai   = (opcode == OPCODE_CAL_I) && (func3 == FUNC3_SRA);

endpackage

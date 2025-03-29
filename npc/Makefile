BUILD_DIR           = ./build
OBJ_DIR             = $(BUILD_DIR)/obj_dir

$(shell mkdir -p $(OBJ_DIR))

# 本地仿真环境参数
TOP_NAME            ?= ysyx
SIM_CINC            = $(addprefix -I, $(abspath ./csrc/Include))
SIM_VINC            = $(abspath ./vsrc)
SIM_CLFAGS          = -O3 $(SIM_CINC)
SIM_LDFLAGS         = -lreadline -L/home/hjw-arch/ysyx-workbench/npc/ -lnemu
SIM_VSRC            = $(shell find $(abspath ./vsrc) -name "*.v" -or -name "*.sv")
SIM_VSRC_NO_PC		= $(filter-out %PC.sv %IFU.sv, $(SIM_VSRC))
SIM_CSRC            = $(shell find $(abspath ./csrc/src) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
## LLVM参数
LLVMCFLAGS          = $(shell llvm-config --cxxflags) -fPIE
LLVMCFLAGS          = $(echo $LLVMCFLAGS | sed 's/ -D__STDC_FORMAT_MACROS//')  # 去掉D__STDC_FORMAT_MACROS
LLVMLDFLAGS         = $(shell llvm-config --libs)

# SOC参数
SOC_VSRC            = $(shell find $(abspath ../ysyxSoC/perip) -type f -name "*.v")
SOC_VINC            = $(abspath ../ysyxSoC/perip/uart16550/rtl) $(abspath ../ysyxSoC/perip/spi/rtl)
SOC_VFLAGS          = --timescale "1ns/1ns" --no-timing
SOC_TOP_MOD_FILE    = $(abspath ../ysyxSoC/build/ysyxSoCFull.v)
TOP_NAME            = ysyxSoCFull        # 重写TOPNAME

# 可执行文件输入
NPCARGS             ?= -d ./libnemu.so
IMG                 ?= $(abspath ./ROM/bin/UART.bin)


# 整合
export ASAN_OPTIONS = verify_asan_link_order=0    # 关掉内存泄漏检测    开启设备会存在内存泄漏

TRACE_IS_ON ?= ON
ifeq ($(TRACE_IS_ON),ON)
    VERILATOR_FLAGS += --trace
endif

VERILATOR           = verilator
VERILATOR_SRC       = $(SIM_CSRC) $(SIM_VSRC_NO_PC) $(SOC_VSRC) $(SOC_TOP_MOD_FILE)
VERILATOR_LDFLAGS   = $(addprefix -LDFLAGS , $(SIM_LDFLAGS) $(LLVMLDFLAGS))
VERILATOR_CFLAGS    = $(addprefix -CFLAGS , $(LLVMCFLAGS) $(SIM_CLFAGS))
VERILATOR_VINC      = $(addprefix -y , $(SIM_VINC) $(SOC_VINC))
VERILATOR_WNO       = --Wno-UNUSEDSIGNAL --Wno-DECLFILENAME --Wno-NULLPORT --Wno-PINCONNECTEMPTY --Wno-ASSIGNDLY --Wno-DEFPARAM --Wno-UNDRIVEN --Wno-UNUSEDPARAM --Wno-SYNCASYNCNET --autoflush
VERILATOR_FLAGS     = -Mdir $(OBJ_DIR) -cc --exe --build -O3 --x-assign fast --x-initial fast -sv -Wall $(VERILATOR_VINC) \
                      $(SOC_VFLAGS)  $(VERILATOR_CFLAGS) $(VERILATOR_LDFLAGS) $(VERILATOR_WNO)  \
                      --top-module $(TOP_NAME)

default: run
all: run
run: $(VERILATOR_SRC)
	@echo
	@echo "---------------- Simulation start -----------------"
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_SRC) --public ./vsrc/PC.sv --public ./vsrc/IFU.sv
	@echo
	@echo
	@echo "---------------- Simulation running -----------------"
	@echo
	@$(OBJ_DIR)/V$(TOP_NAME) $(NPCARGS) $(IMG)
	@echo
	@(call git_commit, "sim RTL")
	@echo "-------------------- Finish -----------------------"




# --------------------- NVBOARD ----------------------------
# TODO








clean:
	rm -rf $(BUILD_DIR)

include ../Makefile

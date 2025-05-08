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

VERILATOR           = verilator
VERILATOR_SRC       = $(SIM_CSRC) $(SIM_VSRC_NO_PC) $(SOC_VSRC) $(SOC_TOP_MOD_FILE)
VERILATOR_LDFLAGS   = $(addprefix -LDFLAGS , $(SIM_LDFLAGS) $(LLVMLDFLAGS))
VERILATOR_CFLAGS    = $(addprefix -CFLAGS , $(LLVMCFLAGS) $(SIM_CLFAGS))
VERILATOR_VINC      = $(addprefix -y , $(SIM_VINC) $(SOC_VINC))
VERILATOR_WNO       = --Wno-UNUSEDSIGNAL --Wno-DECLFILENAME --Wno-NULLPORT --Wno-PINCONNECTEMPTY --Wno-ASSIGNDLY --Wno-DEFPARAM --Wno-UNDRIVEN --Wno-UNUSEDPARAM --Wno-SYNCASYNCNET --autoflush --Wno-EOFNEWLINE
VERILATOR_FLAGS     = -Mdir $(OBJ_DIR) -cc --exe --build -O3 --x-assign fast --x-initial fast -sv -Wall --trace $(VERILATOR_VINC) \
                      $(SOC_VFLAGS)  $(VERILATOR_CFLAGS) $(VERILATOR_LDFLAGS) $(VERILATOR_WNO)  \
                      --top-module $(TOP_NAME) -DSOC

default: run
all: run
run: $(VERILATOR_SRC)
	@echo
	@echo "---------------- Simulation start -----------------"
	$(VERILATOR) $(VERILATOR_FLAGS) -CFLAGS -DSOC $(VERILATOR_SRC) --public ./vsrc/PC.sv --public ./vsrc/IFU.sv
	@echo
	@echo
	@echo "---------------- Simulation running -----------------"
	@echo
	@$(OBJ_DIR)/V$(TOP_NAME) $(NPCARGS) $(IMG)
	@echo
	$(call git_commit, "sim RTL")
	@echo "-------------------- Finish -----------------------"



# ----------------------- NPC ----------------------------

TOP_NAME_FOR_NPC    	?= 	ysyx
VERILATOR_SRC_NPC   	= 	$(SIM_CSRC) $(SIM_VSRC_NO_PC)
VERILATOR_LDFLAGS_NPC 	= 	$(addprefix -LDFLAGS , $(SIM_LDFLAGS) $(LLVMLDFLAGS))
VERILATOR_CFLAGS_NPC  	= 	$(addprefix -CFLAGS , $(LLVMCFLAGS) $(SIM_CLFAGS))
VERILATOR_VINC_NPC    	= 	$(addprefix -y , $(SIM_VINC))

VERILATOR_FLAGS_NPC 	= -Mdir $(OBJ_DIR) -cc --exe --build -O3 --x-assign fast --x-initial fast -sv -Wall --trace \
                           $(VERILATOR_VINC_NPC) $(VERILATOR_CFLAGS_NPC) $(VERILATOR_LDFLAGS_NPC) $(VERILATOR_WNO) \
                           --top-module $(TOP_NAME_FOR_NPC) -DNPC # 注意这里没有 SOC_VFLAGS

npc: $(VERILATOR_SRC_NPC)
	@echo
	@echo "---------------- Simulation start -----------------"
	$(VERILATOR) $(VERILATOR_FLAGS_NPC) -CFLAGS -DNPC $(VERILATOR_SRC_NPC) --public ./vsrc/PC.sv --public ./vsrc/IFU.sv
	@echo
	@echo
	@echo "---------------- Simulation running -----------------"
	@echo
	@$(OBJ_DIR)/V$(TOP_NAME_FOR_NPC) $(NPCARGS) $(IMG)
	@echo
	$(call git_commit, "sim RTL")
	@echo "-------------------- Finish -----------------------"



# --------------------- NVBOARD ----------------------------

include $(NVBOARD_HOME)/scripts/nvboard.mk

NXDC_FILES = $(abspath ./constr/top.nxdc)
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
# 生成引脚绑定函数
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

NVBOARD_CSRC += $(SRC_AUTO_BIND) $(NVBOARD_ARCHIVE)

# INC_PATH += /home/hjw-arch/ysyx_workbench/nvboard/include

NVBOARD_CFLAGS = $(addprefix -CFLAGS , $(addprefix -I, $(INC_PATH)) $(CXXFLAGS))


sim: $(SRC_AUTO_BIND) $(NVBOARD_ARCHIVE)
	@echo
	@echo "---------------- Simulation start -----------------"
	$(VERILATOR) $(VERILATOR_FLAGS) $(NVBOARD_CFLAGS) $(VERILATOR_SRC) $(NVBOARD_CSRC) $(addprefix -LDFLAGS , $(LDFLAGS)) --public ./vsrc/PC.sv --public ./vsrc/IFU.sv
	@echo
	@echo
	@echo "---------------- Simulation running -----------------"
	@echo
	@$(OBJ_DIR)/V$(TOP_NAME) $(NPCARGS) $(IMG)
	@echo
	$(call git_commit, "sim RTL")
	@echo "-------------------- Finish -----------------------"


clean:
	rm -rf $(BUILD_DIR)

include ../Makefile

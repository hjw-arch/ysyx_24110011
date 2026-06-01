BUILD_DIR           = ./build
OBJ_DIR             = $(BUILD_DIR)/obj_dir

$(shell mkdir -p $(OBJ_DIR))





################################ 当make目标改变时，创造一个纯净的环境 ####################################
LAST_GOALS_FILE = $(OBJ_DIR)/last_make_goals.stamp

LAST_MAKED_GOALS := $(shell cat $(LAST_GOALS_FILE) 2>/dev/null)
CURRENT_MAKECMDGOALS = $(MAKECMDGOALS)

ifeq ($(strip $(CURRENT_MAKECMDGOALS)),)
    CURRENT_GOALS_TO_COMPARE = $(firstword $(DEFAULT_GOAL)) # 假设 DEFAULT_GOAL 是 'run' 或 'all'
else
    CURRENT_GOALS_TO_COMPARE = $(sort $(CURRENT_MAKECMDGOALS)) # 排序以确保 'run npc' 和 'npc run' 被视为相同
endif

# 标志位，指示是否因为目标改变而需要清理
NEEDS_CLEAN_DUE_TO_GOAL_CHANGE := false
ifneq ($(strip $(CURRENT_GOALS_TO_COMPARE)), $(strip $(LAST_MAKED_GOALS)))
    ifneq ($(strip $(LAST_MAKED_GOALS)),)
        NEEDS_CLEAN_DUE_TO_GOAL_CHANGE := true
    endif
endif


.PHONY: prepare_build
prepare_build:
	@echo "--- Preparing build (Current goals: [$(CURRENT_GOALS_TO_COMPARE)]) ---"
	@if $(NEEDS_CLEAN_DUE_TO_GOAL_CHANGE); then \
		rm -rf $(OBJ_DIR)/*; \
		$(shell mkdir -p $(OBJ_DIR)) \
	fi
	@echo "$(CURRENT_GOALS_TO_COMPARE)" > $(LAST_GOALS_FILE)







###########################################################################################################




# 本地仿真环境参数
TOP_NAME            ?= ysyx
SIM_CINC            = $(addprefix -I, $(abspath ./csrc/Include))
SIM_VINC            = $(abspath ./vsrc)
SIM_CLFAGS          = -O3 $(SIM_CINC)
SIM_LDFLAGS         = -lreadline -L/home/hjw-arch/ysyx-workbench/npc/ -lnemu
SOC_ISA             ?= RVE
NPC_ISA             ?= RVI
VALID_ISAS          = RVE RVI
ifeq ($(filter $(SOC_ISA),$(VALID_ISAS)),)
$(error SOC_ISA must be one of: $(VALID_ISAS))
endif
ifeq ($(filter $(NPC_ISA),$(VALID_ISAS)),)
$(error NPC_ISA must be one of: $(VALID_ISAS))
endif
SOC_ISA_CFLAG       = -DCONFIG_$(SOC_ISA)
SOC_ISA_VDEFINE     = +define+CONFIG_$(SOC_ISA)
NPC_ISA_CFLAG       = -DCONFIG_$(NPC_ISA)
NPC_ISA_VDEFINE     = +define+CONFIG_$(NPC_ISA)
SIM_PKG				= $(shell find $(abspath ./vsrc/include) -name "*.sv")			# pkg 需要被优先编译
SIM_VSRC            = $(SIM_PKG) $(shell find $(abspath ./vsrc) -name "*.v" -or -name "*.sv" ! -path "*/include/*")
SIM_VSRC_NO_PC		= $(filter-out %PC.sv %IFU.sv %define_pkg.sv, $(SIM_VSRC))
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
VERILATOR_CFLAGS    = $(addprefix -CFLAGS , $(LLVMCFLAGS) $(SIM_CLFAGS) -DSOC $(SOC_ISA_CFLAG))
VERILATOR_VINC      = $(addprefix -y , $(SIM_VINC) $(SOC_VINC))
VERILATOR_WNO       = --Wno-UNUSEDSIGNAL --Wno-DECLFILENAME --Wno-NULLPORT --Wno-PINCONNECTEMPTY --Wno-ASSIGNDLY --Wno-DEFPARAM --Wno-UNDRIVEN --Wno-UNUSEDPARAM --Wno-SYNCASYNCNET --autoflush --Wno-EOFNEWLINE
VERILATOR_FLAGS     = -Mdir $(OBJ_DIR) -cc --exe --build -O3 --x-assign fast --x-initial fast -sv -Wall --trace $(VERILATOR_VINC) \
                      $(SOC_VFLAGS)  $(VERILATOR_CFLAGS) $(VERILATOR_LDFLAGS) $(VERILATOR_WNO)  \
                      --top-module $(TOP_NAME) +define+SOC $(SOC_ISA_VDEFINE)

default: run
all: run
run: prepare_build $(VERILATOR_SRC)
	@echo
	@echo "---------------- Simulation start -----------------"
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_SRC) --public ./vsrc/IFU.sv
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
VERILATOR_CFLAGS_NPC  	= 	$(addprefix -CFLAGS , $(LLVMCFLAGS) $(SIM_CLFAGS) -DNPC $(NPC_ISA_CFLAG))
VERILATOR_VINC_NPC    	= 	$(addprefix -y , $(SIM_VINC))

# 注意这里没有 SOC_VFLAGS
VERILATOR_FLAGS_NPC 	= -Mdir $(OBJ_DIR) -cc --exe --build -O3 --x-assign fast --x-initial fast -sv -Wall --trace \
                           $(VERILATOR_VINC_NPC) $(VERILATOR_CFLAGS_NPC) $(VERILATOR_LDFLAGS_NPC) $(VERILATOR_WNO) \
                           --top-module $(TOP_NAME_FOR_NPC) +define+NPC $(NPC_ISA_VDEFINE)

npc: prepare_build $(VERILATOR_SRC_NPC)
	@echo
	@echo "---------------- Simulation start -----------------"
	$(VERILATOR) $(VERILATOR_FLAGS_NPC) $(VERILATOR_SRC_NPC) --public ./vsrc/IFU.sv
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


sim: $(SRC_AUTO_BIND) $(NVBOARD_ARCHIVE) prepare_build
	@echo
	@echo "---------------- Simulation start -----------------"
	$(VERILATOR) $(VERILATOR_FLAGS) $(NVBOARD_CFLAGS) $(VERILATOR_SRC) $(NVBOARD_CSRC) $(addprefix -LDFLAGS , $(LDFLAGS)) --public ./vsrc/IFU.sv
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

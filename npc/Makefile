BUILD_DIR           = ./build
OBJ_DIR_SOC         = $(BUILD_DIR)/obj-soc
OBJ_DIR_NPC         = $(BUILD_DIR)/obj-npc
OBJ_DIR_NVBOARD     = $(BUILD_DIR)/obj-nvboard

.PHONY: prepare_build
prepare_build:
	@mkdir -p $(OBJ_DIR_SOC) $(OBJ_DIR_NPC) $(OBJ_DIR_NVBOARD)


NPC_HOME := $(abspath .)

-include $(NPC_HOME)/include/config/auto.conf
-include $(NPC_HOME)/include/config/auto.conf.cmd



# 本地仿真环境参数
TOP_NAME            ?= ysyx
SIM_CINC            = $(addprefix -I, $(abspath ./csrc/Include) $(NPC_HOME)/include)
SIM_VINC            = $(abspath ./vsrc)
SIM_CFLAGS          = -O3 $(SIM_CINC)
SIM_LDFLAGS         = -lreadline -ldl

ISA_VDEFINE         =
ifeq ($(CONFIG_RVE),y)
ISA_VDEFINE         = +define+CONFIG_RVE
endif

ifeq ($(CONFIG_RVI),y)
ISA_VDEFINE         = +define+CONFIG_RVI
endif


DEVICE_CFLAGS       =
DEVICE_LDFLAGS      =
ifeq ($(CONFIG_DEVICE),y)
DEVICE_CFLAGS       = $(SDL_CFLAGS)
DEVICE_LDFLAGS      = $(SDL_LDFLAGS)
endif


VERILATOR_TRACE_FLAGS =
ifeq ($(CONFIG_VERILATOR_TRACE),y)
VERILATOR_TRACE_FLAGS = --trace
endif


SOC_VDEFINE         = +define+SOC $(ISA_VDEFINE)
ifeq ($(CONFIG_FAST_FLASH),y)
SOC_VDEFINE         += +define+FAST_FLASH
endif


NPC_VDEFINE         = +define+NPC $(ISA_VDEFINE)
SIM_PKG				= $(shell find $(abspath ./vsrc/include) -name "*.sv")			# pkg 需要被优先编译
SIM_VSRC            = $(SIM_PKG) $(shell find $(abspath ./vsrc) -name "*.v" -or -name "*.sv" ! -path "*/include/*")
SIM_VSRC_CORE		= $(filter-out %PC.sv %define_pkg.sv, $(SIM_VSRC))
SIM_CSRC            = $(shell find $(abspath ./csrc/src) -name "*.c" -or -name "*.cc" -or -name "*.cpp")
## LLVM参数
LLVMCFLAGS          = $(filter-out -D__STDC_FORMAT_MACROS,$(shell llvm-config --cxxflags)) -fPIE
LLVMLDFLAGS         = $(shell llvm-config --libs)
SDL_CFLAGS          = $(shell pkg-config --cflags sdl2)
SDL_LDFLAGS         = $(shell pkg-config --libs sdl2)

# SOC参数
SOC_VSRC            = $(shell find $(abspath ../ysyxSoC/perip) -type f -name "*.v")
SOC_VINC            = $(abspath ../ysyxSoC/perip/uart16550/rtl) $(abspath ../ysyxSoC/perip/spi/rtl)
SOC_VFLAGS          = --timescale "1ns/1ns" --no-timing
SOC_TOP_MOD_FILE    = $(abspath ../ysyxSoC/build/ysyxSoCFull.v)
TOP_NAME            = ysyxSoCFull        # 重写TOPNAME

# 可执行文件输入
ifeq ($(CONFIG_DIFFTEST),y)
NPCARGS             ?= -d ./libnemu.so
else
NPCARGS             ?=
endif
IMG                 ?= $(abspath ./ROM/bin/UART.bin)


# 整合
export ASAN_OPTIONS = verify_asan_link_order=0    # 关掉内存泄漏检测    开启设备会存在内存泄漏

VERILATOR           = verilator
VERILATOR_SRC       = $(SIM_CSRC) $(SIM_VSRC_CORE) $(SOC_VSRC) $(SOC_TOP_MOD_FILE)
VERILATOR_LDFLAGS   = $(addprefix -LDFLAGS , $(SIM_LDFLAGS) $(LLVMLDFLAGS) $(DEVICE_LDFLAGS))
VERILATOR_CFLAGS    = $(addprefix -CFLAGS , $(LLVMCFLAGS) $(SIM_CFLAGS) $(DEVICE_CFLAGS) -DSOC)
VERILATOR_VINC      = $(addprefix -y , $(SIM_VINC) $(SOC_VINC))
VERILATOR_WNO       = --Wno-UNUSEDSIGNAL --Wno-DECLFILENAME --Wno-NULLPORT --Wno-PINCONNECTEMPTY --Wno-ASSIGNDLY --Wno-DEFPARAM --Wno-UNDRIVEN --Wno-UNUSEDPARAM --Wno-SYNCASYNCNET --autoflush --Wno-EOFNEWLINE
VERILATOR_SOC_FLAGS = -cc --exe --build -O3 --x-assign fast --x-initial fast -sv -Wall $(VERILATOR_TRACE_FLAGS) $(VERILATOR_VINC) \
                      $(SOC_VFLAGS)  $(VERILATOR_CFLAGS) $(VERILATOR_LDFLAGS) $(VERILATOR_WNO)  \
                      --top-module $(TOP_NAME) $(SOC_VDEFINE)
VERILATOR_FLAGS     = -Mdir $(OBJ_DIR_SOC) $(VERILATOR_SOC_FLAGS)
VERILATOR_FLAGS_NVBOARD = -Mdir $(OBJ_DIR_NVBOARD) $(VERILATOR_SOC_FLAGS)

default: run
all: run
run: prepare_build $(VERILATOR_SRC)
	@echo
	@echo "---------------- Simulation start -----------------"
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_SRC)
	@echo
	@echo
	@echo "---------------- Simulation running -----------------"
	@echo
	@$(OBJ_DIR_SOC)/V$(TOP_NAME) $(NPCARGS) $(IMG)
	@echo
	$(call git_commit, "sim RTL")
	@echo "-------------------- Finish -----------------------"



# ----------------------- NPC ----------------------------

TOP_NAME_FOR_NPC    	?= 	ysyx
VERILATOR_SRC_NPC   	= 	$(SIM_CSRC) $(SIM_VSRC_CORE)
VERILATOR_LDFLAGS_NPC 	= 	$(addprefix -LDFLAGS , $(SIM_LDFLAGS) $(LLVMLDFLAGS) $(DEVICE_LDFLAGS))
VERILATOR_CFLAGS_NPC  	= 	$(addprefix -CFLAGS , $(LLVMCFLAGS) $(SIM_CFLAGS) $(DEVICE_CFLAGS) -DNPC)
VERILATOR_VINC_NPC    	= 	$(addprefix -y , $(SIM_VINC))

# 注意这里没有 SOC_VFLAGS
VERILATOR_FLAGS_NPC 	= -Mdir $(OBJ_DIR_NPC) -cc --exe --build -O3 --x-assign fast --x-initial fast -sv -Wall $(VERILATOR_TRACE_FLAGS) \
                           $(VERILATOR_VINC_NPC) $(VERILATOR_CFLAGS_NPC) $(VERILATOR_LDFLAGS_NPC) $(VERILATOR_WNO) \
                           --top-module $(TOP_NAME_FOR_NPC) $(NPC_VDEFINE)

npc: prepare_build $(VERILATOR_SRC_NPC)
	@echo
	@echo "---------------- Simulation start -----------------"
	$(VERILATOR) $(VERILATOR_FLAGS_NPC) $(VERILATOR_SRC_NPC)
	@echo
	@echo
	@echo "---------------- Simulation running -----------------"
	@echo
	@$(OBJ_DIR_NPC)/V$(TOP_NAME_FOR_NPC) $(NPCARGS) $(IMG)
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

NVBOARD_CFLAGS = $(addprefix -CFLAGS , $(addprefix -I, $(INC_PATH)) $(CXXFLAGS) -DNVBOARD)


sim: $(SRC_AUTO_BIND) $(NVBOARD_ARCHIVE) prepare_build
	@echo
	@echo "---------------- Simulation start -----------------"
	$(VERILATOR) $(VERILATOR_FLAGS_NVBOARD) $(NVBOARD_CFLAGS) $(VERILATOR_SRC) $(NVBOARD_CSRC) $(addprefix -LDFLAGS , $(LDFLAGS))
	@echo
	@echo
	@echo "---------------- Simulation running -----------------"
	@echo
	@$(OBJ_DIR_NVBOARD)/V$(TOP_NAME) $(NPCARGS) $(IMG)
	@echo
	$(call git_commit, "sim RTL")
	@echo "-------------------- Finish -----------------------"


clean:
	rm -rf $(BUILD_DIR)

include ../Makefile
include $(NPC_HOME)/scripts/config.mk

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir

$(shell mkdir -p $(OBJ_DIR))

TOP_NAME ?= ysyx
NPCARGS ?= 
IMG ?= 

VERILATOR = verilator

# 常规参数 将verilog代码翻译为C++代码后直接生成可执行文件
VERILATOR_FLAGS = -Mdir $(OBJ_DIR) -cc --exe --build -O3 --x-assign fast --x-initial fast -Wall --top-module $(TOP_NAME) -y $(abspath, ./vsrc)
INC_FLAGS = $(addprefix -I, $(abspath ./csrc/Include))
# 需要llvm
LLVMFLAGS = $(shell llvm-config --cxxflags) -fPIE
LLVMFLAGS = $(echo $LLVMFLAGS | sed 's/ -D__STDC_FORMAT_MACROS//')  # 去掉D__STDC_FORMAT_MACROS


LDFLAGS += $(shell llvm-config --libs) -lreadline -L/home/hjw-arch/ysyx-workbench/npc/ -lnemu
CFLAGS += -O3 $(INC_FLAGS) $(LLVMFLAGS)

# 是否开启trace
TRACE_IS_ON ?= ON
ifeq ($(TRACE_IS_ON),ON)
	VERILATOR_FLAGS += --trace
endif

vsrc ?= $(shell find $(abspath ./vsrc) -name "*.v" -or -name "*.sv")
csrc ?= $(shell find $(abspath ./csrc/src) -name "*.c" -or -name "*.cc" -or -name "*.cpp")

# 输入参数
VERILATOR_INPUTS = $(abspath $(vsrc)) $(abspath $(csrc))

export ASAN_OPTIONS = verify_asan_link_order=0

default: run
all: run

run:
	@echo
	# @echo "---------------- Verilator running -----------------"
	@$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INPUTS) \
		$(addprefix -CFLAGS , $(CFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS))\
		--Wno-UNUSEDSIGNAL -Wno-DECLFILENAME -Wno-NULLPORT
	@# 运行可执行程序
	@echo
	@echo "------------------- Simulation ---------------------"
	@echo
	@echo
	$(OBJ_DIR)/V$(TOP_NAME) $(NPCARGS) $(IMG)
	@echo
	$(call git_commit, "sim RTL")
	@echo "-------------------- Finish -----------------------"

# --------------------------- NVboard ----------------------------"
#

NXDC_FILES = constr/$(TOP_NAME).nxdc
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
# 生成引脚绑定函数
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

NVBOARD_INPUTS += $(SRC_AUTO_BIND)

# nvboard的构建规则
include $(NVBOARD_HOME)/scripts/nvboard.mk

INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS)

NVBOARD_INPUTS += $(NVBOARD_ARCHIVE)

sim: $(SRC_AUTO_BIND)
	@echo
	@echo "----------------------- Verilator running --------------------"
	$(VERILATOR) $(VERILATOR_FLAGS) $(VERILATOR_INPUTS) $(NVBOARD_INPUTS) $(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS))
	@echo
	@echo "----------------------- NVboard running ----------------------"
	@echo
	@echo
	$(OBJ_DIR)/V$(TOP_NAME)
	@echo
	@echo "--------------------------- Finish ---------------------------"
	@$(call git_commit, "sim RTL")

clean:
	rm -rf $(BUILD_DIR)



include ../Makefile

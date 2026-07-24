AM_SRCS := riscv/ysyxsoc/start.S \
           riscv/ysyxsoc/trm.c \
           riscv/ysyxsoc/cte.c \
           riscv/ysyxsoc/trap.S \
		   riscv/ysyxsoc/ioe/ioe.c \
		   riscv/ysyxsoc/ioe/uart.c \
		   riscv/ysyxsoc/ioe/input.c \
		   riscv/ysyxsoc/ioe/gpu.c \
		   riscv/ysyxsoc/ioe/timer.c \
           platform/dummy/vme.c \
           platform/dummy/mpe.c

CFLAGS    += -fdata-sections -ffunction-sections

ifeq ($(NAME), rtthread)
    LDFLAGS += -T $(AM_HOME)/scripts/ysyxsoc-rtt.ld
else
    LDFLAGS += -T $(AM_HOME)/scripts/ysyxsoc.ld
endif

LDFLAGS   += --gc-sections -e _start
CFLAGS += -DMAINARGS=\"$(mainargs)\"
CFLAGS += -I$(AM_HOME)/am/src/riscv/ysyxsoc/ioe -I$(AM_HOME)/am/src/riscv/
.PHONY: $(AM_HOME)/am/src/riscv/ysyxsoc/trm.c

NEMU_REF ?= $(NEMU_HOME)/build/riscv32-nemu-interpreter-soc-so
NPCARGS = -e $(IMAGE).elf -d $(NEMU_REF) -b

image: $(IMAGE).elf
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

run: image
	$(MAKE) -C $(NPC_HOME) NPCARGS="$(NPCARGS)" sim IMG=$(IMAGE).bin

AM_SRCS := riscv/ysyxsoc/start.S \
           riscv/ysyxsoc/trm.c \
           riscv/ysyxsoc/cte.c \
           riscv/ysyxsoc/trap.S \
		   riscv/ysyxsoc/ioe/ioe.c \
		   riscv/ysyxsoc/ioe/uart.c \
           platform/dummy/vme.c \
           platform/dummy/mpe.c

# CFLAGS    += -fdata-sections -ffunction-sections

ifeq ($(NAME), rtthread)
    LDFLAGS += -T $(AM_HOME)/scripts/ysyxsoc-rtt.ld
else
    LDFLAGS += -T $(AM_HOME)/scripts/ysyxsoc.ld
endif

LDFLAGS   += -e _start
CFLAGS += -DMAINARGS=\"$(mainargs)\"
CFLAGS += -I$(AM_HOME)/am/src/riscv/ysyxsoc/ioe -I$(AM_HOME)/am/src/riscv/
.PHONY: $(AM_HOME)/am/src/riscv/ysyxsoc/trm.c

NPCARGS = -e $(IMAGE).elf -d ./libnemu.so

image: $(IMAGE).elf
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

run: image
	$(MAKE) -C $(NPC_HOME) NPCARGS="$(NPCARGS)" sim IMG=$(IMAGE).bin

# nvboard: image
# 	$(MAKE) -C $(NPC_HOME) NPCARGS="$(NPCARGS)" nvboard IMG=$(IMAGE).bin
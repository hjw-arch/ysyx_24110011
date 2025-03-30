AM_SRCS := riscv/ysyxsoc/start.S \
           riscv/ysyxsoc/trm.c \
           riscv/ysyxsoc/cte.c \
           riscv/ysyxsoc/trap.S \
           platform/dummy/vme.c \
           platform/dummy/mpe.c

CFLAGS    += -ffunction-sections -O2
LDFLAGS   += -T $(AM_HOME)/scripts/ysyxsoc.ld
LDFLAGS   += --gc-sections -e _start
CFLAGS += -DMAINARGS=\"$(mainargs)\"
CFLAGS += -I$(AM_HOME)/am/src/riscv/npc/ioe -I$(AM_HOME)/am/src/riscv/
.PHONY: $(AM_HOME)/am/src/riscv/npc/trm.c

NPCARGS = -e $(IMAGE).elf -d ./libnemu.so

image: $(IMAGE).elf
	@$(OBJDUMP) -d $(IMAGE).elf > $(IMAGE).txt
	@echo + OBJCOPY "->" $(IMAGE_REL).bin
	@$(OBJCOPY) -S --set-section-flags .bss=alloc,contents -O binary $(IMAGE).elf $(IMAGE).bin

run: image
	$(MAKE) -C $(NPC_HOME) NPCARGS="$(NPCARGS)" run IMG=$(IMAGE).bin
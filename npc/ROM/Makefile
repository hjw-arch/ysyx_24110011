CROSS_COMPILE := riscv64-unknown-linux-gnu
COMMON_CFLAGS := -fno-pic -march=rv32i_zicsr -mabi=ilp32 -mcmodel=medany -mstrict-align -nostdlib
CFLAGS        += $(COMMON_CFLAGS) -static -fdata-sections -ffunction-sections -O2
ASFLAGS       += $(COMMON_CFLAGS) -O0
LDFLAGS       += -Wl,-melf32lriscv -Wl,--gc-sections -Wl,-e _start
LDFLAGS   	  += -Wl,-T ./linker.ld -Wl,--defsym=_pmem_start=0x20000000 -Wl,--defsym=_entry_offset=0x0

BINDIR		  = $(abspath ./bin)
$(shell mkdir -p $(BINDIR))


SRC			  = $(abspath ./SRC/UART.c)
ELF			  = $(BINDIR)/$(basename $(notdir $(SRC))).elf
BIN			  = $(BINDIR)/$(basename $(notdir $(SRC))).bin
TXT			  = $(BINDIR)/$(basename $(notdir $(SRC))).txt

elf: $(SRC)
	$(CROSS_COMPILE)-gcc $(CFLAGS) $(LDFLAGS) -Ttext=0x20000000 -o $(ELF) $(SRC)
	$(CROSS_COMPILE)-objcopy -O binary $(ELF) $(BIN)
	$(CROSS_COMPILE)-objdump -d $(ELF) > $(TXT)

clean:
	rm -rf ./bin/*

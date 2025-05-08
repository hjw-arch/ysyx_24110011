CC ?= gcc

TARGET = cachesim
SRC = $(abspath ./cachesim.c)
INC_PATH = $(abspath ./)

CFLAGS = -Wall -g -O2 $(addprefix -I, $(INC_PATH))
LDFLAGS = -lm

TRACE_PATH ?= /home/hjw-arch/ysyx-workbench/ITRACE.bin

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(LDFLAGS) $(SRC) -o $(TARGET)
	./$(TARGET) -s 64 -b 16 -a 2 -p PLRU -t $(TRACE_PATH)

clean:
	rm $(TARGET)

.PHONY: all clean
CC ?= gcc

TARGET = branchsim
SRC = $(abspath ./branchsim.c)
INC_PATH = $(abspath ./)

CFLAGS = -Wall -Wextra -std=gnu11 -O2 -g $(addprefix -I, $(INC_PATH))

TRACE_PATH ?= /home/hjw-arch/ysyx-workbench/BTRACE.bin

all: $(TARGET)

$(TARGET): $(SRC) log.h
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET)

run: $(TARGET)
	./$(TARGET) -f $(TRACE_PATH) -p btb -e 16

clean:
	rm -f $(TARGET)

.PHONY: all run clean

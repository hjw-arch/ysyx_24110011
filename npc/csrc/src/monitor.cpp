#include "VysyxSoCFull.h"
#include "verilated.h"
#include "../Include/common.h"
#include "../Include/log.h"
#include "../Include/ram.h"
#include "../Include/sdb.h"
#include "../Include/cpu_exec.h"
#include "../Include/config.h"
#include "../Include/difftest.h"
#include "../Include/device.h"
#include <stdio.h>
#include <stdint.h>
#include <getopt.h>
#include "VysyxSoCFull___024root.h"

VysyxSoCFull dut;

static char *diff_so_file = NULL;
static char *img_file = NULL;
static int difftest_port = 1234;
char *elf_file = NULL;
long img_size = 0;

static uint8_t test_img[] = {
    0x13, 0x00, 0xf0, 0xff,
    0x93, 0x00, 0xf0, 0xff,
    0x13, 0x01, 0xf0, 0xff,
    0x93, 0x01, 0xf0, 0xff,
    0x73, 0x00, 0x10, 0x00
};

long load_img() {
    if (img_file == NULL) {
        Log("No image is given. Use default image.");
        memcpy(guest_to_host(RESET_VECTOR), test_img, sizeof(test_img));
        return 20;
    }

    FILE *fp = fopen(img_file, "rb");
    Assert(fp, "Can not open '%s'.", img_file);

    fseek(fp, 0, SEEK_END);

    long size = ftell(fp);

    Log("The image is %s, size = %ld", img_file, size);

    rewind(fp);

    int ret = fread((uint8_t *)guest_to_host(RESET_VECTOR), size, 1, fp);
    Assert(ret == 1, "Read image file failed.");

    fclose(fp);

    return size;
}

static void welcome() {
  Log("Trace: %s", MUXDEF(CONFIG_TRACE, ANSI_FMT("ON", ANSI_FG_GREEN), ANSI_FMT("OFF", ANSI_FG_RED)));
  Log("Build time: %s, %s", __TIME__, __DATE__);    // 内置宏定义
  printf("Welcome to %s-NPC!\n", ANSI_FMT(str(__GUEST_ISA__), ANSI_FG_YELLOW ANSI_BG_RED));
  printf("For help, type \"help\"\n");
}

static int batch_mode_flag = 0;

void sdb_set_batch_mode() {
    batch_mode_flag = 1;
}

static int parse_args(int argc, char *argv[]) {
    const struct option table[] = {
        {"batch"    , no_argument      , NULL, 'b'},
        {"diff"     , required_argument, NULL, 'd'},
        {"port"     , required_argument, NULL, 'p'},
        {"elf"      , required_argument, NULL, 'e'},
        {"help"     , no_argument      , NULL, 'h'},
        {0          , 0                , NULL,  0 },
    };
    int o;
    while ( (o = getopt_long(argc, argv, "-bhd:p:e:", table, NULL)) != -1) {
        switch (o) {
            case 'b': sdb_set_batch_mode(); break;
            case 'p': sscanf(optarg, "%d", &difftest_port); break;
            case 'd': diff_so_file = optarg; break;
            case 'e': elf_file = optarg; break;
            case 1: img_file = optarg; return 0;
        default:
            printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
            printf("\t-b, --batch              run with batch mode\n");
            printf("\t-d, --diff=REF_SO        run DiffTest with reference REF_SO\n");
            printf("\t-e, --elf=elf_file       if you want to use 'ftrace', input a elf format file\n");
            printf("\n");
            exit(0);
    }
  }
  return 0;
}

#ifdef NVBOARD

#include "nvboard.h"
void nvboard_bind_all_pins(VysyxSoCFull* dut);

#endif

int main(int argc, char *argv[]) {
    Verilated::commandArgs(argc, argv);		// For SOC
#ifdef NVBOARD

	nvboard_bind_all_pins(&dut);
	nvboard_init();

#endif

    parse_args(argc, argv);
    init_disasm("riscv32" "-pc-linux-gnu");
    img_size = load_img();
    init_sdb();
    cpu_rst;
    IFDEF(CONFIG_FTRACE, decode_elf());
    IFDEF(CONFIG_DIFFTEST, init_difftest(diff_so_file, img_size, difftest_port));
    IFDEF(CONFIG_DEVICE, init_device());
    if (batch_mode_flag) {
        cpu_exec(-1);
        return 0;
    }
    welcome();
    sdb_cli_loop();
}



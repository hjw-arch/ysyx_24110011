#include "../Include/sdb.h"
#include "../Include/common.h"
#include "../Include/cpu_exec.h"
#include "../Include/macro.h"
#include "../Include/log.h"
#include <readline/readline.h>
#include <readline/history.h>

static char *rl_gets() {
    static char *line_read = NULL;

    if (line_read) {
        free(line_read);
        line_read = NULL;
    }

    line_read = readline("(npc) ");

    if (line_read && *line_read) {
        add_history(line_read);
    }

    return line_read;
}

static int cmd_c(char *args) {
    cpu_exec(-1);
    return 0;
}

static int cmd_q(char *args) {
    exit(0);
}

static int cmd_si(char *args) {
    char *num_p = strtok(args, " ");
    int num = (num_p == NULL) ? 1 : atoi(num_p);
    if (num > (0x7fffffff) || num < 0) {
        printf("The \"N\" is out of range, N ranges from 0 to 2,147,483,647\n");
        return 0;
    }

    cpu_exec(num);

    return 0;
}

static int cmd_info(char *args) {
    char *next_arg = strtok(args, " ");
    if (next_arg == NULL) {
        printf("Missing parameter\n");
        return 0;
    }

    if (*next_arg == 'r') {
        isa_reg_display();
        return 0;
    }

    if (*next_arg == 'w') {
#ifdef CONFIG_WATCHPOINT
        diaplay_wp();
#endif
        return 0;
    }

    else {
        printf("Error parameter\n");
        return 0;
    }
    
    return 0;
}

static int cmd_x(char *args) {
    char *N = strtok(args, " ");
    if (N == NULL) {
        printf("Missing parameter\n");
        return 0;
    }

    char *EXPR = strtok(NULL, " ");
    if (EXPR == NULL) {
        printf("Missing parameter\n");
        return 0;
    }

    int expr_result;
    sscanf(EXPR + 2, "%x", &expr_result);

    // if (expr_result > RAM_END_ADDR || expr_result < RAM_START_ADDR) {
    //     printf("Start address is out of range of memory size!\n");
    //     return 0;
    // }

    for (int i = 0; i < atoi(N); i++) {
        printf("0x%-10x", pmem_read(expr_result, 4));
        if ((i + 1) % 11 == 0)
            printf("\n");
        expr_result += 4;
        if (expr_result > RAM_END_ADDR)
            return 0;
    }

    printf("\n");
    return 0;
}

static int cmd_w(char *args) {
#ifdef CONFIG_WATCHPOINT
    if (args == NULL) {
        printf("Missing parameter\n");
        return 0;
    }

    new_wp(args);
#else
    printf("Function \"Watchpoint\" is not enabled\n");
#endif
    return 0;
}

static int cmd_d(char *args) {
#ifdef CONFIG_WATCHPOINT
    if (args == NULL) {
        printf("Missing parameter\n");
        return 0;
    }

    int i = atoi(args);

    if (i < 0 || i > 32) {
        printf("%s is out of range from 0 to 32\n", args);
        printf(ANSI_FG_RED "^\n" ANSI_NONE);
        return 0;
    }

    free_wp(i);
#else
    printf("Function \"Watchpoint\" is not enabled\n");
#endif

    return 0;
}

static int cmd_p(char *args) {
    if (args == NULL) {
        printf("Missing parameter\n");
        return 0;
    }

    uint32_t print_format = 0;
    char *expr_str = args;
    if ((*args == 'd' || *args == 'x' || *args == 'D' || *args == 'X')) {
        print_format = *args;
        strtok(NULL, " ");
        expr_str = strtok(NULL, "");
        if (expr_str == NULL) {
            printf("Missing parameter\n");
            return 0;
        }
    }

    bool is_success = true;
    uint32_t result = expr(expr_str, &is_success);

    if (is_success) {
        (print_format == 'x' || print_format == 'X') ? printf("0x%x\n", result) : printf("%d\n", result);
    }
    else {
        printf("Bad expression\n");
    }

    return 0;
}

static int cmd_ftrace(char *args) {
    if (args != NULL) {
        printf("Unknown command '%s'\n", args);
        return 0;
    }

    IFDEF(CONFIG_FTRACE, display_ftrace());

    return 0;
}

static int cmd_itrace(char *args) {
    if (args != NULL) {
        printf("Unknown command '%s'\n", args);
        return 0;
    }

    iringbuf_display();

    return 0;
}

static int cmd_help(char *args);

static struct {
    const char *name;
    const char *description;
    int (*handler)(char *);
} cmd_table[] = {
    {"help", "Display information about all supported commands", cmd_help},
    {"c", "Continue the execution of the program", cmd_c},
    {"q", "Exit NPC", cmd_q},
    {"si", "si [N] | Let the program step through N instructions, the default N is 1", cmd_si},
    {"info", "info r/w | Print registers/watchpoints status", cmd_info},
    {"x", "x N EXPR | Evaluate the expression EXPR and use the result as the starting memory, output N consecutive 4 bytes in hexadecimal form", cmd_x},
    {"p", "p [d/x] EXPR | Evaluate the expression EXPR", cmd_p},
    {"w", "w EXPR | When the value of the expression EXPR changes, program execution is stopped", cmd_w},
    {"d", "d NO | Delete a watchpoint with serial number N", cmd_d},
    {"itrace", "View lastest 16 instructions", cmd_itrace},
    {"ftrace", "View function trace", cmd_ftrace},
    /* TODO: Add more commands */

};

#define NR_CMD ARRLEN(cmd_table)

static int cmd_help(char *args) {
    /* extract the first argument */
    char *arg = strtok(NULL, " ");
    int i;

    if (arg == NULL) {
        /* no argument given */
        for (i = 0; i < NR_CMD; i++)
        {
            printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
        }
    } else {
        for (i = 0; i < NR_CMD; i++) {
            if (strcmp(arg, cmd_table[i].name) == 0) {
                printf("%s - %s\n", cmd_table[i].name, cmd_table[i].description);
                return 0;
            }
        }
        printf("Unknown command '%s'\n", arg);
    }
    return 0;
}


void sdb_cli_loop() {
    for (char *str; (str = rl_gets()) != NULL;) {
        char *str_end = str + strlen(str);

        /* extract the first token as the command */
        char *cmd = strtok(str, " ");
        if (cmd == NULL) {
            continue;
        }

        /* treat the remaining string as the arguments,
         * which may need further parsing
         */
        char *args = cmd + strlen(cmd) + 1;
        if (args >= str_end) {
            args = NULL;
        }

#ifdef CONFIG_DEVICE
        extern void sdl_clear_event_queue();
        sdl_clear_event_queue();
#endif

        int i;
        for (i = 0; i < NR_CMD; i++) {
            if (strcmp(cmd, cmd_table[i].name) == 0) {
                if (cmd_table[i].handler(args) < 0) {
                    return;
                }
                break;
            }
        }

        if (i == NR_CMD) {
            printf("Unknown command '%s'\n", cmd);
        }
    }
}

void init_sdb() {
    /* Compile the regular expressions. */
    init_regex();

    /* Initialize the watchpoint pool. */
    init_wp_pool();
}







/***************************************************************************************
 * Copyright (c) 2014-2022 Zihao Yu, Nanjing University
 *
 * NEMU is licensed under Mulan PSL v2.
 * You can use this software according to the terms and conditions of the Mulan PSL v2.
 * You may obtain a copy of Mulan PSL v2 at:
 *          http://license.coscl.org.cn/MulanPSL2
 *
 * THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
 * EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
 * MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
 *
 * See the Mulan PSL v2 for more details.
 ***************************************************************************************/

#include "../Include/sdb.h"
#include "../Include/macro.h"
#include "../Include/log.h"
#include "../Include/ram.h"
#include "../Include/cpu_exec.h"

#define NR_WP 32
#define LEN_WP_EXPR 128

typedef struct watchpoint {
    int NO;
    char expr_str[LEN_WP_EXPR];
    uint32_t result;
    struct watchpoint *next;

    /* TODO: Add more members if necessary */

} WP;

static WP wp_pool[NR_WP] = {};
static WP *head = NULL, *free_ = NULL;

void init_wp_pool() {
    int i;
    for (i = 0; i < NR_WP; i++) {
        wp_pool[i].NO = i;
        wp_pool[i].next = (i == NR_WP - 1 ? NULL : &wp_pool[i + 1]);
    }

    head = NULL;
    free_ = wp_pool;
}

#ifdef CONFIG_WATCHPOINT

// 设置一个新的监视点
void new_wp(char *expression) {

    if (strlen(expression) > 100) {
        printf("Expression is too long!\n");
        return;
    }

    if (free_ == NULL) {
        printf("No free watchpoint\n");
        Assert(0, "No free watchpoint");
        return;
    }

    // 计算表达式
    bool is_success = true;
    uint32_t result = expr(expression, &is_success);
    if (!is_success) {
        printf("Bad expression!\n");
        return;
    }

    // 置入数据
    strcpy(free_->expr_str, expression);
    free_->result = result;

    // 保存节点
    WP *wp = free_;

    // 断开链表
    free_ = free_->next;

    // 连接到head链表
    wp->next = head;
    head = wp;

    printf("NO %d watchponit, %s = 0x%x\n", wp->NO, wp->expr_str, result);
}

void free_wp(int NO) {
    if (head == NULL) {
        printf("\nNo watchpoint number: %d\n", NO);
        printf(ANSI_FG_RED "%-22s^\n" ANSI_NONE, "");
        return;
    }

    if (head->NO == NO) {   // 如果head头节点即是需要的节点
        // 数据置空
        memset(head->expr_str, 0, sizeof(head->expr_str));
        head->result = 0;

        WP *wp = head;
        // 断开连接
        head = head->next;
        // 连接到free_链表
        wp->next = free_;
        free_ = wp;
        return;
    }

    WP *front_wp = head, *wp = front_wp->next;
    while(wp != NULL) {
        if (wp->NO == NO) {
            // 数据清0
            memset(wp->expr_str, 0, sizeof(wp->expr_str));
            wp->result = 0;

            // 断开链表
            front_wp->next = wp->next;

            // 连接到free链表
            wp->next = free_;
            free_ = wp;
            return;
        }
        // 继续搜索下一个
        front_wp = wp;
        wp = wp->next;
    }

    printf("\nNo watchpoint number: %d\n", NO);
    printf(ANSI_FG_RED "%-22s^\n" ANSI_NONE, "");
    return;
}

int diff_wp(vaddr_t front_pc) {
    int flag = 0;
    for (WP *wp = head; wp != NULL; wp = wp->next) {
        bool is_success = true;
        uint32_t result = expr(wp->expr_str, &is_success);
        if (!is_success) {  // 几乎不可能
            printf("Bad expression\n");
            printf("%s\n", wp->expr_str);
            for (int i = 0; i < strlen(wp->expr_str) - 1; i++) printf(ANSI_FG_RED "~" ANSI_NONE);
            printf(ANSI_FG_RED "^\n" ANSI_NONE);
            flag = 1;
        }
        
        if (result != wp->result) {
            printf("Watchpoint %d: %s  at: 0x%x\nOld Value = 0x%x\nNew Value = 0x%x\n\n", wp->NO, wp->expr_str, front_pc, wp->result, result);
            wp->result = result;
            flag = 1;
        }
    }

    if (flag) npc_set_state(NPC_STOP, front_pc, 0);
    return flag;
}

void diaplay_wp() {
    if (head == NULL) {
        printf("No watchpoints.\n");
        return;
    }
    printf("Num\tType\t\tResult\t\tWhat\n");
    for (WP *wp = head; wp != NULL; wp = wp->next) {
        printf("%d\tWatchpoint\t0x%-14x%s\n", wp->NO, wp->result, wp->expr_str);
    }
    puts("");
}

#endif
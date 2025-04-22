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

#include <isa.h>
#include <memory/vaddr.h>
#include <memory/paddr.h>

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>

enum
{
    TK_NOTYPE = 256,
    TK_REG, // 寄存器引用
    TK_EQ,  // 等于
    TK_NEQ, // 不等于
    TK_NUM,
    TK_HEX,
    TK_UL,
    TK_AND,
    TK_DEREF,           // 解引用

    /* TODO: Add more token types */

};

// 优先级列表，用于判断运算符；也可通过上面的枚举类型来定义优先级，但编码时还需要考虑优先级一致的问题，导致代码编写变得臃肿难以维护
// 考虑到并不运行在一个对存储要求苛刻的环境下，因此采用优先级列表来维护优先级
static uint32_t priority_list[] = {
    [TK_AND] = 256,
    [TK_EQ] = 255,
    [TK_NEQ] = 255,
    ['+'] = 254,
    ['-'] = 254,
    ['*'] = 253,
    ['/'] = 253,
    [TK_DEREF] = 252,
};

static struct rule
{
    const char *regex;
    int token_type;
} rules[] = {

    /* TODO: Add more rules.
     * Pay attention to the precedence level of different rules.
     */

    {" +", TK_NOTYPE},  // spaces
    // {"\\$(0|ra|sp|gp|tp|t[0-6]|s([0-9]|1[0-1])|a[0-7]|[xX]([1-2]?[0-9]|3[0-1])|pc)", TK_REG},    // 完全匹配名称
    {"\\$([0-9a-zA-Z]+|\\$0)", TK_REG},
    {"0[xX][0-9a-fA-F]+", TK_HEX},  // 16进制数字
    {"[0-9]+", TK_NUM}, // 数字
    {"\\+", '+'},       // plus
    {"\\-", '-'},       // sub
    {"\\*", '*'},       // mul
    {"/", '/'},         // div
    {"\\(", '('},       // (
    {"\\)", ')'},       // )
    {"==", TK_EQ},      // equal
    {"!=", TK_NEQ},     // not equal
    {"&&", TK_AND},
    {"UL", TK_UL},
};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex()
{
    int i;
    char error_msg[128];
    int ret;

    for (i = 0; i < NR_REGEX; i++)
    {
        ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED); // 编译正则表达式
        if (ret != 0)
        {
            regerror(ret, &re[i], error_msg, 128);
            panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
        }
    }
}

typedef struct token
{
    int type;
    char str[32];
} Token;

static Token tokens[2048] __attribute__((used)) = {};
static int nr_token __attribute__((used)) = 0;

static bool make_token(char *e)
{
    int position = 0;
    int i;
    regmatch_t pmatch;

    nr_token = 0;

    while (e[position] != '\0')
    {
        /* Try all rules one by one. */
        for (i = 0; i < NR_REGEX; i++)
        {
            if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0)
            {
                if (nr_token >= 2048) {
                    printf("Expression is too long!\n");
                    return false;
                }
                
                char *substr_start = e + position;
                int substr_len = pmatch.rm_eo;

                // Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",
                //    i, rules[i].regex, position, substr_len, substr_len, substr_start);

                position += substr_len;

                /* TODO: Now a new token is recognized with rules[i]. Add codes
                 * to record the token in the array `tokens'. For certain types
                 * of tokens, some extra actions should be performed.
                 */

                switch (rules[i].token_type)
                {
                case '+':
                case '-':
                case '/':
                case '(':
                case ')':
                case TK_EQ:
                case TK_NEQ:
                case TK_AND:
                    tokens[nr_token++].type = rules[i].token_type;
                    break;
                case '*':
                    if(nr_token == 0 || (tokens[nr_token - 1].type != ')' && tokens[nr_token - 1].type != TK_NUM && 
                    tokens[nr_token - 1].type != TK_HEX)) {
                        tokens[nr_token++].type = TK_DEREF;
                    } else {
                        tokens[nr_token++].type = '*';
                    }
                    break;
                case TK_NUM:
                    tokens[nr_token].type = TK_NUM;
                    strncpy(tokens[nr_token++].str, substr_start, substr_len > 10 ? 10 : substr_len);
                    if ((substr_len > 10) || ((substr_len == 10) && ((uint64_t)atoll(tokens[nr_token - 1].str) > 4294967296)))
                    {
                        printf("Number out of range\n");
                        printf("%-.*s\n", substr_len, substr_start);
                        printf(ANSI_FG_RED "^" ANSI_NONE);
                        for (int i = 0; i < substr_len - 1; i++) {
                            printf(ANSI_FG_RED "~" ANSI_NONE);
                        }
                        puts("");
                        return false;
                    }
                    break;
                case TK_HEX:
                    tokens[nr_token].type = TK_HEX;
                    if (substr_len > 10) {
                        printf("Number out of range\n");
                        printf("%-.*s\n", substr_len, substr_start);
                        printf(ANSI_FG_RED "%*.s^\n" ANSI_NONE, substr_len - 1, "");
                        return false;
                    }
                    strncpy(tokens[nr_token++].str, substr_start + 2, substr_len - 2);  // 只保存数值，不保存0x
                    break;
                case TK_REG:    // 直接保存寄存器名称，不做判断
                    tokens[nr_token].type = TK_REG;
                    strncpy(tokens[nr_token++].str, substr_start + 1, substr_len - 1);  // 只保存名称，不保存$引用
                    break;
                case TK_UL:
                case TK_NOTYPE:
                default:
                    break;
                }
                break;
            }
        }

        if (i == NR_REGEX)
        {
            printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
            return false;
        }
    }

    return true;
}

// 检查表达式是否被括号包裹
bool check_parentheses(int p, int q)
{
    if (!(tokens[p].type == '(' && tokens[q].type == ')'))
    {
        return false;
    }

    int num_left_parenthese = 0, num_right_parenthese = 0;
    for (int i = p + 1; i < q; i++)
    {
        if (tokens[i].type == '(')
            num_left_parenthese++;
        if (tokens[i].type == ')')
            num_right_parenthese++;
        if (num_right_parenthese > num_left_parenthese)
            return false;
        if (num_right_parenthese > 0)
        {
            num_left_parenthese--;
            num_right_parenthese--;
        }
    }
    if (num_left_parenthese != num_right_parenthese)
        return false;
    return true;
}

// 寻找主运算符     可检查括号匹配的错误
int search_for_main_operator(int p, int q, bool *success)
{
    int temp_op = q;        // priority_list[tokens[q].type] = 0, 否则是错误表达式，没有运算符处于表达式的最右边

    for (int i = q; i >= p; i--)
    { // 从右往左遍历
        switch (tokens[i].type)
        {
        case ')':
            int left_parentheses = 0;
            int right_parentheses = 1;
            while (--i)
            {
                if (i < p) {
                    *success = false;
                    return 0; // 遍历到开头还没有找到匹配项，表达式错误！
                }

                if (tokens[i].type == ')') right_parentheses++; // 遍历到右括号，说明有嵌套括号，都不能要
                if (tokens[i].type == '(') left_parentheses++; // 遍历到左括号，需要消除与之匹配的左括号

                if (left_parentheses > right_parentheses) {
                    *success = false;
                    return 0; // 不可能出现右括号数量少于左括号，否则表达式错误！
                }

                if (left_parentheses > 0) { // 如果存在左括号，那么消除此右括号和与之匹配的左括号
                    left_parentheses--;
                    right_parentheses--;
                }

                if (right_parentheses == 0) { // 如果左括号被消除完毕，说明完成括号匹配，可以退出
                    break;
                }
            }
            break;

        case '(': // 先匹配到左括号，说明表达式错误
            *success = false;
            return 0;

        case TK_AND:    // 最高优先级，直接返回
            return i;
            break;
        case TK_EQ:     // 判断优先级，返回最高优先级，同优先级返回最右边的值
        case TK_NEQ:
        case '+':
        case '-':
        case '*':
        case '/':
        case TK_DEREF:
            if (priority_list[tokens[i].type] > priority_list[tokens[temp_op].type]) {
                temp_op = i;
            }

        default: // default处理的就是数字类型，直接跳过
            break;
        }
    }
    return temp_op;
}


uint64_t eval_expression(int p, int q, bool *success)
{
    if (!(*success)) return 0;

    if (p > q) {
        *success = false;
        return 0;
    } else if (p == q) {
        switch (tokens[p].type) {
            case TK_NUM:
                return (uint64_t)atol(tokens[p].str);
                break;

            case TK_HEX:
                return (uint64_t)strtol(tokens[p].str, NULL, 16);
                break;

            case TK_REG:
                return (uint64_t)isa_reg_str2val(tokens[p].str, success);
                break;

            default:
                *success = false;
                return 0;
                break;
        }
    } else if (check_parentheses(p, q) == true) {
        return eval_expression(p + 1, q - 1, success);
    } else {
        int pos_op = search_for_main_operator(p, q, success);

        switch (tokens[pos_op].type)
        {
            case '+': {
                // 使用val1 val2来存储是为了方便GDB查看
                uint64_t val1 = eval_expression(p, pos_op - 1, success);
                uint64_t val2 = eval_expression(pos_op + 1, q, success);
                return val1 + val2;
            }
                break;

            case '-': {
                uint64_t val1 = eval_expression(p, pos_op - 1, success);
                uint64_t val2 = eval_expression(pos_op + 1, q, success);
                return val1 - val2;
            }
                break;

            case '*': {
                uint64_t val1 = eval_expression(p, pos_op - 1, success);
                uint64_t val2 = eval_expression(pos_op + 1, q, success);
                return val1 * val2;
            }
                break;

            case '/': {
                uint64_t val1 = eval_expression(p, pos_op - 1, success);
                uint64_t val2 = eval_expression(pos_op + 1, q, success);

                if (val2 == 0) {
                    printf("ZeroDivisionError!\n");
                    *success = false;
                    return 0;
                }
                return val1 / val2;
            }
                break;
            
            case TK_AND: {
                uint64_t val1 = eval_expression(p, pos_op - 1, success);
                if (val1 == 0) return 0;    // 短路原则，如果val2有除零行为，gcc也不检测，这里需要与gcc保持一致，否则过不了测试
                uint64_t val2 = eval_expression(pos_op + 1, q, success);
                return val1 && val2;
            }
                break;
            
            case TK_EQ: {
                uint64_t val1 = eval_expression(p, pos_op - 1, success);
                uint64_t val2 = eval_expression(pos_op + 1, q, success);
                return val1 == val2;
            }
                break;
            
            case TK_NEQ: {
                uint64_t val1 = eval_expression(p, pos_op - 1, success);
                uint64_t val2 = eval_expression(pos_op + 1, q, success);
                return val1 != val2;
            }
                break;
            
            case TK_DEREF: {
                uint64_t val = eval_expression(pos_op + 1, q, success);
                if (!(val >= PMEM_LEFT && val < PMEM_RIGHT)) {
                    *success = false;
                    printf("Out of memory range\n");
                    return 0;
                }
                uint32_t derefer_val = vaddr_read(val, 4);  // 取该地址开始的连续四个字节内存数据
                return derefer_val;
            }
                break;

            default:
                *success = false;
                return 0;
        }
    }
    return 0;
}

word_t expr(char *e, bool *success)
{
    memset(tokens, 0, sizeof(tokens));
    nr_token = 0;
    if (!make_token(e))
    {
        *success = false;
        return 0;
    }

    /* TODO: Insert codes to evaluate the expression. */
    //    TODO();
    uint64_t result = eval_expression(0, nr_token - 1, success);

    if (result > 4294967296)
    {
        printf("result out of range\n");
        *success = false;
        return 0;
    }

    return (uint32_t)result;
}

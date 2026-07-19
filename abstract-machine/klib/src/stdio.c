#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

enum {
    normal = 0,
    h,
    hh,
    l,
    ll,
    j,
    z,
    t,
    L,
};

static bool leftAlign = false;
static bool showSymbol = false;
static bool replaceFormat = false; // TODO
static bool blankBeforePostiveNum = false;
static bool paddingCharZero = false;
static int width = 0;
static int precision = -1;  // TODO
static int length = normal; // TODO

// static int double2str(char *str, double num, int precision) {
//     int length = 0;  // 记录字符串长度

//     // 处理负数
//     if (num < 0) {
//         *str++ = '-';
//         num = -num;  // 将负数转为正数处理
//         length++;
//     }

//     // 处理整数部分
//     uint64_t int_part = (uint64_t)num;  // 整数部分
//     double decimal_part = num - int_part;  // 小数部分

//     // 将整数部分转换为字符串
//     char temp[50];  // 临时数组用于存储整数部分字符串
//     int i = 0;
//     if (int_part == 0) {
//         temp[i++] = '0';
//     } else {
//         while (int_part > 0) {
//             temp[i++] = (int_part % 10) + '0';
//             int_part /= 10;
//         }
//     }

//     // 反转整数部分
//     for (int j = 0; j < i; j++) {
//         str[length++] = temp[i - j - 1];
//     }

//     // 处理小数部分
//     if (precision > 0) {
//         str[length++] = '.';  // 添加小数点

//         // 将小数部分转换为字符串
//         for (int j = 0; j < precision; j++) {
//             decimal_part *= 10;
//             uint32_t decimal_digit = (uint32_t)decimal_part;
//             str[length++] = decimal_digit + '0';
//             decimal_part -= decimal_digit;
//         }
//     }

//     str[length] = '\0';  // 添加字符串结束符

//     return length;  // 返回字符串的长度
// }

static int num2string(char *out, uint64_t num, int base) {
    int ret = 0;

    // process zero
    if (num == 0) {
        out[ret] = '0';
        return 1;
    }


    int a[36];
    int i = 0;
    while(num != 0) {

        a[i++] = num % base;
        num /= base;

    }

    while(i-- > 0) {
        if (a[i] >= 10) {
            out[ret++] = (char)(a[i] - 10 + 'A');
        } else {
            out[ret++] = (char)(a[i] + '0');
        }
    }

    out[ret] = '\0';

    return ret;
}

static int handle_int(char *out, uint64_t num, bool isSigned) {
    bool isSatisfiedWidth = false;
    bool isNegative = false;
    int diffblank = 0;
    int ret = 0;

    // 处理有符号数

    // 判断正负，如果是负数会添加负号，占用一位宽度
    if (isSigned) {
        if (length == ll) {
            if ((int64_t)num < 0) {
                isNegative = true;
                num = -((int64_t)num);
                diffblank++;
            }
        } else {
            if ((int)num < 0) {
                isNegative = true;
                num = -((int)num);
                diffblank++;
            }
        }

        // 如果是负数并且不是用0补宽度，直接添加负号
        if (isNegative && paddingCharZero) {
            out[ret++] = '-';
        }

        if (isNegative) showSymbol = false, blankBeforePostiveNum = false;

        // 是否需要添加正号或者空格，如果添加，占一位宽度
        if (length == ll) {
            if (showSymbol && (int64_t)num > 0) out[ret++] = '+', diffblank++;
            if (blankBeforePostiveNum && (int64_t)num > 0) out[ret++] = ' ', diffblank++;
        } else {
            if (showSymbol && (int)num > 0) out[ret++] = '+', diffblank++;
            if (blankBeforePostiveNum && (int)num > 0) out[ret++] = ' ', diffblank++;
        }
    }

    // 数字转字符串
    char str[36];
    int len = num2string(str, num, 10);
    diffblank += len;

    // 计算需要补几位宽度
    diffblank = width - diffblank;

    if (diffblank > 0)
    {   // 如果是右对齐或者使用0补宽度，要在数字前面补
        if (!leftAlign || paddingCharZero)
        {
            for (int j = 0; j < diffblank; j++)
            {
                out[ret++] = (paddingCharZero ? '0' : ' ');
            }
            isSatisfiedWidth = true;
        }
    }

    // 之前没补负号的话现在补一下
    if (isNegative && !paddingCharZero) out[ret++] = '-';

    strncpy(&out[ret], str, len);
    ret += len;

    // 如果之前没补宽度，现在补一下
    if (diffblank > 0 && !isSatisfiedWidth)
    {
        for (int j = 0; j < diffblank; j++)
        {
            out[ret++] = ' ';
        }
    }

    return ret;
}

// static int handle_float(char *out, double num){
//     bool isSatisfiedWidth = false;
//     bool isNegative = false;
//     int diffblank = 0;
//     int ret = 0;

//     // 处理有符号数

//     // 判断正负，如果是负数会添加负号，占用一位宽度
//     if (num < 0) {
//         isNegative = true;
//         diffblank++;
//         num = -num;
//     }

//     // 如果是负数并且不是用0补宽度，直接添加负号
//     if (isNegative && paddingCharZero) {
//         out[ret++] = '-';
//     }

//     if (isNegative) showSymbol = false, blankBeforePostiveNum = false;

//     // 是否需要添加正号或者空格，如果添加，占一位宽度
//     if (length == ll || length == l) {
//         if (showSymbol && num > 0) out[ret++] = '+', diffblank++;
//         if (blankBeforePostiveNum && num > 0) out[ret++] = ' ', diffblank++;
//     } else {
//         if (showSymbol && num > 0) out[ret++] = '+', diffblank++;
//         if (blankBeforePostiveNum && num > 0) out[ret++] = ' ', diffblank++;
//     }

//     // 数字转字符串
//     char str[36];
//     int len = double2str(str, num, precision == -1 ? 6 : precision);
//     diffblank += len;

//     // 计算需要补几位宽度
//     diffblank = width - diffblank;

//     if (diffblank > 0)
//     {   // 如果是右对齐或者使用0补宽度，要在数字前面补
//         if (!leftAlign || paddingCharZero)
//         {
//             for (int j = 0; j < diffblank; j++)
//             {
//                 out[ret++] = (paddingCharZero ? '0' : ' ');
//             }
//             isSatisfiedWidth = true;
//         }
//     }

//     // 之前没补负号的话现在补一下
//     if (isNegative && !paddingCharZero) out[ret++] = '-';

//     strncpy(&out[ret], str, len);
//     ret += len;

//     // 如果之前没补宽度，现在补一下
//     if (diffblank > 0 && !isSatisfiedWidth)
//     {
//         for (int j = 0; j < diffblank; j++)
//         {
//             out[ret++] = ' ';
//         }
//     }

//     return ret;
// }

static int handle_x_o(char *out, uint64_t num, int base){
    bool isSatisfiedWidth = false;
    int diffblank = 0;
    int ret = 0;

    // 数字转字符串
    char str[36];
    int len = num2string(str, num, base);
    diffblank += len;

    if (replaceFormat) {
        if (base == 16) diffblank += 2;
        else diffblank++;
    }
    // 计算需要补几位宽度
    diffblank = width - diffblank;

    if (paddingCharZero && replaceFormat) {
        out[ret++] = '0';
        if (base == 16) {
            out[ret++] = 'X';
        }
    }

    if (diffblank > 0)
    {   // 如果是右对齐或者使用0补宽度，要在数字前面补
        if (!leftAlign || paddingCharZero)
        {
            for (int j = 0; j < diffblank; j++)
            {
                out[ret++] = (paddingCharZero ? '0' : ' ');
            }
            isSatisfiedWidth = true;
        }
    }

    if (!paddingCharZero && replaceFormat) {
        out[ret++] = '0';
        if (base == 16) {
            out[ret++] = 'x';
        }
    }

    strncpy(&out[ret], str, len);
    ret += len;

    // 如果之前没补宽度，现在补一下
    if (diffblank > 0 && !isSatisfiedWidth)
    {
        for (int j = 0; j < diffblank; j++)
        {
            out[ret++] = ' ';
        }
    }

    return ret;
}

static int simple_pow(int a, int b) {
    int result = 1;
    for (int i = 0; i < b; i++) {
        result *= a;
    }
    return result;
}

static void string2num(int *num, const char *string, int len) {
    *num = 0;
    for (int i = len - 1; i >= 0; i--) {
        if (string[i] > '9' || string[i] < '0') {
            *num = 0;
            return;
        }
        *num += (string[i] - '0') * simple_pow(10, len - i - 1);
    }
}

int vsprintf(char *out, const char *fmt, va_list ap);

int printf(const char *fmt, ...) {
    va_list list;
    va_start(list, fmt);
    char out[1024];
    int len = vsprintf(out, fmt, list);
    int i;
    for (i = 0; i < len; i++) {
        putch(out[i]);
    }
    va_end(list);
    return i;
}


int vsprintf(char *out, const char *fmt, va_list ap) {
    int ret = 0;
    for (int i = 0; i < strlen(fmt); ++i) {
        if (fmt[i] != '%') {
            out[ret++] = fmt[i];
        }
        else {
            i++;

            leftAlign = false;
            showSymbol = false;
            replaceFormat = false;
            blankBeforePostiveNum = false;
            paddingCharZero = false;
            width = 0;
            precision = -1;
            length = normal; // TODO

            // flags
            while(true) {
                switch (fmt[i]) {
                    case '-': {
                        leftAlign = true;
                        paddingCharZero = false;
                        i++;
                        break;
                    }

                    case '+': {
                        showSymbol = true;
                        blankBeforePostiveNum = false;
                        i++;
                        break;
                    }

                    case '0': {
                        if (!leftAlign) paddingCharZero = true;
                        i++;
                        break;
                    }

                    case '#': {
                        replaceFormat = true;
                        i++;
                        break;
                    }

                    case ' ': {
                        i++;
                        if (showSymbol) {
                            break;
                        }

                        blankBeforePostiveNum = true;

                        break;
                    }
                    
                    default:
                        goto br;
                }
            }

            // width
br:         int j;
            for (j = 0; fmt[i + j] <= '9' && fmt[i + j] >= '0'; j++) ;
            string2num(&width, &fmt[i], j);
            i += j;

            // precision
            if (fmt[i] == '.') {
                i++;
                for (j = 0; fmt[i + j] <= '9' && fmt[i + j] >= '0'; j++) ;
                string2num(&precision, &fmt[i], j);
                i += j;
            }

            // length
            switch (fmt[i])
            {
                case 'h': {
                    i++;
                    if (fmt[i] == 'h') {
                        i++;
                        length = hh;
                        break;
                    }
                    length = h;
                    break;
                }

                case 'l': {
                    i++;
                    if (fmt[i] == 'l') {
                        i++;
                        length = ll;
                        break;
                    }
                    length = l;
                    break;
                }

                // TODO
                case 'j':
                case 'z':
                case 't':
                case 'L':
                    length = normal;    // TODO;
                    i++;
                default:
                    break;
            }

            uint64_t num = 0;
            if (fmt[i] != 'c' && fmt[i] != 's' && fmt[i] != 'f') {
                if (length == ll) {
                    num = va_arg(ap, uint64_t);
                } else {
                    num = va_arg(ap, uint32_t);
                }
            }


            switch (fmt[i]) {
                case 'x':
                case 'X':
                case 'o':
                    ret += handle_x_o(&out[ret], num, fmt[i] == 'o' ? 8 : 16);
                    break;
                case 'u':
                case 'i':
                case 'd': {
                    int isSigned = fmt[i] == 'i' || fmt[i] == 'd';
                    ret += handle_int(&out[ret], num, isSigned);
                    break;
                }

                case 'f': {
                    // double float_num = va_arg(ap, double);
                    // ret += handle_float(&out[ret], float_num);
                    break;
                }

                case 's': {
                    char *str = va_arg(ap, char*);
                    int len = 0;
                    while(str[len++]);
                    len--;
                    if (!leftAlign) for (j = 0; j < width - len; j++) out[ret++] = ' ';
                    while (*str != '\0') {
                        out[ret++] = *(str++);
                    }
                    if (leftAlign) for (j = 0; j < width - len; j++) out[ret++] = ' ';
                    break;
                }

                case 'c': {
                    char ch = (char)va_arg(ap, int);
                    if (!leftAlign) for (j = 0; j < width - 1; j++) out[ret++] = ' ';
                    out[ret++] = ch;
                    if (leftAlign) for (j = 0; j < width - 1; j++) out[ret++] = ' ';
                    break;
                }


                case '%': {
                    out[ret++] = '%';
                }

                default:
                    break;
            }
        }
    }
    out[ret] = '\0';
    return ret;
}

int sprintf(char *out, const char *fmt, ...) {
    va_list list;
    va_start(list, fmt);

    int ret = vsprintf(out, fmt, list);

    va_end(list);
    return ret;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
    panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
    panic("Not implemented");
}

#endif

#ifndef CONFIG_H
#define CONFIG_H

#include <generated/autoconf.h>

#define __GUEST_ISA__     RISCV32

#if defined(CONFIG_RVE) && defined(CONFIG_RVI)
#error "CONFIG_RVE and CONFIG_RVI cannot both be defined"
#endif

#if !defined(CONFIG_RVE) && !defined(CONFIG_RVI)
#error "Base ISA is not configured. Run 'make fast_defconfig' or 'make menuconfig' first."
#endif

#endif

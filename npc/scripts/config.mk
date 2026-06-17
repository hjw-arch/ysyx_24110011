COLOR_RED := $(shell echo "\033[1;31m")
COLOR_END := $(shell echo "\033[0m")

NPC_HOME ?= $(abspath .)

CONFIG_FREE_GOALS := menuconfig savedefconfig clean distclean
CONFIG_FREE_GOALS += $(filter %defconfig,$(MAKECMDGOALS))
CONFIG_NEED_GOALS := $(filter-out $(CONFIG_FREE_GOALS),$(MAKECMDGOALS))
ifeq ($(strip $(MAKECMDGOALS)),)
CONFIG_NEED_GOALS := default
endif

ifeq ($(wildcard $(NPC_HOME)/.config),)
ifneq ($(strip $(CONFIG_NEED_GOALS)),)
$(error $(COLOR_RED).config does not exist. Run 'make fast_defconfig' or 'make menuconfig' first.$(COLOR_END))
endif
endif

Q := @

KCONFIG_PATH := $(NPC_HOME)/tools/kconfig
FIXDEP_PATH  := $(NPC_HOME)/tools/fixdep
Kconfig      := $(NPC_HOME)/Kconfig

rm-distclean += include/generated include/config .config .config.old

silent := -s

CONF   := $(KCONFIG_PATH)/build/conf
MCONF  := $(KCONFIG_PATH)/build/mconf
FIXDEP := $(FIXDEP_PATH)/build/fixdep
AUTOCONF_H := $(NPC_HOME)/include/generated/autoconf.h
AUTO_CONF  := $(NPC_HOME)/include/config/auto.conf

$(CONF):
	$(Q)$(MAKE) $(silent) -C $(KCONFIG_PATH) NAME=conf

$(MCONF):
	$(Q)$(MAKE) $(silent) -C $(KCONFIG_PATH) NAME=mconf

$(FIXDEP):
	$(Q)$(MAKE) $(silent) -C $(FIXDEP_PATH)

$(AUTOCONF_H) $(AUTO_CONF): $(CONF) $(Kconfig) $(NPC_HOME)/.config
	$(Q)$(CONF) $(silent) --syncconfig $(Kconfig)

prepare_build: $(AUTOCONF_H) $(AUTO_CONF)

menuconfig: $(MCONF) $(CONF) $(FIXDEP)
	$(Q)$(MCONF) $(Kconfig)
	$(Q)$(CONF) $(silent) --syncconfig $(Kconfig)

savedefconfig: $(CONF)
	$(Q)$< $(silent) --savedefconfig=configs/defconfig $(Kconfig)

%defconfig: $(CONF) $(FIXDEP)
	$(Q)$< $(silent) --defconfig=configs/$@ $(Kconfig)
	$(Q)$< $(silent) --syncconfig $(Kconfig)

distclean: clean
	-@rm -rf $(rm-distclean)

.PHONY: menuconfig savedefconfig distclean

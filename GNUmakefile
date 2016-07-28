
SUBDIRS = avr fpga tools

.DEFAULT_GOAL:=dummy

SRCDIR?=$(dir $(lastword $(MAKEFILE_LIST)))
ifeq ($(SRCDIR),./)
SUBDIR_SRC :=
else
SUB_SRCDIR := $(if $(filter /%,$(SRCDIR)),,../)$(SRCDIR)$$dir/
endif

ifeq ($(origin O),command line)
SUBDIR_DIR := $(O)/
SUBDIR_O := $(addprefix $(O)/,$(SUBDIRS))
SUB_SRCDIR := $(abspath $(SRCDIR))/$$dir/
else
SUBDIR_DIR :=
SUBDIR_O := $(SUBDIRS)
endif

$(SUBDIR_O): %:
	mkdir -p $@

%: | $(SUBDIR_O)
	@for dir in $(SUBDIRS); do $(MAKE) -C $(SUBDIR_DIR)$$dir -f $(SUB_SRCDIR)GNUmakefile O=obj $(if $(MAKECMDGOALS),$@,) ; done


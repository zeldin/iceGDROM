ifeq ($(origin _),command line)

SRC := $(SRCDIR)source

PM_INIT_DIR := ../../avr/obj

PM_INIT_LOW := $(PM_INIT_DIR)/pmem_low.hex
PM_INIT_HIGH := $(PM_INIT_DIR)/pmem_high.hex

gdrom_hw_emulator_DEVICE := 8k
gdrom_hw_emulator_CONSTRAINT_FILE := $(SRC)/top.pcf
gdrom_hw_emulator_SCRIPT := $(SRC)/top.yosys

gdrom_hw_emulator_VERILOG_DEFS := PM_INIT_LOW="$(CURDIR)/$(PM_INIT_LOW)"
gdrom_hw_emulator_VERILOG_DEFS += PM_INIT_HIGH="$(CURDIR)/$(PM_INIT_HIGH)"

gdrom_hw_emulator_EXTRA_DEPS := $(PM_INIT_LOW) $(PM_INIT_HIGH)

ICEPROG_DEVICE ?=
ICEPROG_INTERFACE ?=

add-verilog-define = -p 'verilog_defaults -add -D$(1)'

all : gdrom_hw_emulator.bin

flash : gdrom_hw_emulator.bin
	iceprog $(if $(ICEPROG_DEVICE),-d,) $(ICEPROG_DEVICE) $(if $(ICEPROG_INTERFACE),-I,) $(ICEPROG_INTERFACE) $<

upload :

tests :


.SECONDARY:

%.bin : %.txt
	icepack $< $@

.SECONDEXPANSION:

%.txt : %.blif $$($$*_CONSTRAINT_FILE)
	arachne-pnr -s 42 -d $($*_DEVICE) -p $($*_CONSTRAINT_FILE) -o $@ $<

%.blif : $$($$*_SCRIPT) $$($$*_EXTRA_DEPS) $$(shell find "$(SRC)" -name '*.v' -o -name '*.vh')
	cd "$(SRC)" && yosys -b 'blif -gates -attr -param' -o "$(CURDIR)"/$@ $(foreach def,$($*_VERILOG_DEFS),$(call add-verilog-define,$(def))) -p 'script $(<F)'

else

# Run make in object directory

SRCDIR?=$(dir $(lastword $(MAKEFILE_LIST)))
SUB_SRCDIR:=$(if $(filter /%,$(SRCDIR)),,../)$(SRCDIR)
O=obj
.DEFAULT_GOAL:=dummy

%: | $O
	@$(MAKE) --no-print-directory -C $O -f $(SUB_SRCDIR)/GNUmakefile SRCDIR=$(SUB_SRCDIR) _= $(if $(MAKECMDGOALS),$@,)

clean:
	rm -rf $O

$O:
	mkdir -p $@

endif


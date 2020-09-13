ifeq ($(origin _),command line)

SRC := $(SRCDIR)source

PM_INIT_DIR := ../../rv32/obj

PM_INIT := $(PM_INIT_DIR)/pmem.hex

PM_FAKE_FILES := $(foreach f, $(PM_INIT), $(notdir $(f)).fake)

gdrom_hw_emulator_DEVICE := --hx8k --package ct256
gdrom_hw_emulator_CONSTRAINT_FILE := $(SRC)/top.pcf
gdrom_hw_emulator_SCRIPT := $(SRC)/top.yosys

gdrom_hw_emulator_VERILOG_DEFS := PM_INIT="$(CURDIR)/pmem.hex.fake"

gdrom_hw_emulator_BRAM_FILES := $(PM_INIT)
gdrom_hw_emulator_EXTRA_DEPS := $(PM_FAKE_FILES)

ICEPROG_DEVICE ?=
ICEPROG_INTERFACE ?=

add-verilog-define = -p 'verilog_defaults -add -D$(1)'

all : gdrom_hw_emulator.bin

flash : gdrom_hw_emulator.bin
	iceprog $(if $(ICEPROG_DEVICE),-d,) $(ICEPROG_DEVICE) $(if $(ICEPROG_INTERFACE),-I,) $(ICEPROG_INTERFACE) $<

upload :

tests :


.SECONDARY:

$(PM_FAKE_FILES): %.hex.fake :
	icebram -g 32 3072 > $@

%.bin : %.txt
	icepack $< $@

.SECONDEXPANSION:

%.txt : %.txt_nobram $$($$*_BRAM_FILES)
	cat $< $(foreach bramfile,$($*_BRAM_FILES),| icebram $(notdir $(bramfile)).fake $(bramfile)) > $@

%.txt_nobram : %.json $$($$*_CONSTRAINT_FILE)
	nextpnr-ice40 --seed 1 $($*_DEVICE) --pcf $($*_CONSTRAINT_FILE) --asc $@ --json $<

%.json : $$($$*_SCRIPT) $$($$*_EXTRA_DEPS) $$(shell find "$(SRC)" -name '*.v' -o -name '*.vh')
	cd "$(SRC)" && yosys -b json -o "$(CURDIR)"/$@ $(foreach def,$($*_VERILOG_DEFS),$(call add-verilog-define,$(def))) -p 'script $(<F)'

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


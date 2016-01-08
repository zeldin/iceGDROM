ifeq ($(origin _),command line)

SRC := $(SRCDIR)source

gdrom_hw_emulator_DEVICE := 8k
gdrom_hw_emulator_CONSTRAINT_FILE := $(SRC)/top.pcf
gdrom_hw_emulator_SCRIPT := $(SRC)/top.yosys

ICEPROG_DEVICE ?=
ICEPROG_INTERFACE ?=

all : gdrom_hw_emulator.bin

flash : gdrom_hw_emulator.bin
	iceprog $(if $(ICEPROG_DEVICE),-d,) $(ICEPROG_DEVICE) $(if $(ICEPROG_INTERFACE),-I,) $(ICEPROG_INTERFACE) $<

clean :
	-rm -f *.bin *.txt *.blif

.SECONDARY:

%.bin : %.txt
	icepack $< $@

.SECONDEXPANSION:

%.txt : %.blif $$($$*_CONSTRAINT_FILE)
	arachne-pnr -d $($*_DEVICE) -p $($*_CONSTRAINT_FILE) -o $@ $<

%.blif : $$($$*_SCRIPT) $$(shell find "$(SRC)" -name '*.v' -o -name '*.vh')
	cd "$(SRC)" && yosys -b 'blif -gates -attr -param' -o "$(CURDIR)"/$@ -s $(<F)

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


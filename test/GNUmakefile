ifeq ($(origin _),command line)

SRC := $(SRCDIR)source

SOURCES_C = main.c cdops.c pseudorandom.c
SOURCES_S = video.s syscall.s
SOURCES_TEST = benchmark.c dmatest.c

OBJ = $(SOURCES_C:%.c=%.o) $(SOURCES_S:%.s=%.o)
OBJ_TEST = $(SOURCES_TEST:%.c=%.o)

SHCFLAGS ?= -O2 -std=c99

TOOLS_DIR = ../../tools/obj

SHCC = sh-elf-gcc -ml -m4-single-only -ffreestanding

all :


flash :


upload :


tests : BENCHMARK.GI0 DMATEST.GI0

BENCHMARK.GI0 : benchmark.gdi benchmark.isoa benchmark.isob testdata.bin dummydata.bin
	$(TOOLS_DIR)/makegdimg $< $@

DMATEST.GI0 : dmatest.gdi dmatest.isoa dmatest.isob testdata.bin dummydata.bin
	$(TOOLS_DIR)/makegdimg $< $@

%.gdi :
	( echo 4; echo 1 0 4 2048 dummydata.bin 0; echo 2 45000 4 2048 $*.isoa 0; echo 3 450016 4 2048 $*.isob 0; echo 4 500000 4 2048 testdata.bin 0 ) >$@

%.iso : %.ip %.bin
	mkisofs -l -C 0,450000 -G $*.ip -o $@ $*.bin

%.ip : $(SRC)/%.txt
	makeip $< $@

%.bin : %.elf
	sh-elf-objcopy -S -R .stack -O binary $< $@

%.elf : %.o $(OBJ) crt0.o
	$(SHCC) -Wl,-Ttext,0x8c010000 -nostartfiles crt0.o -o $@ $(OBJ) $*.o

%.isoa : %.iso
	dd if=$< of=$@ bs=2048 count=18

%.isob : %.iso
	dd if=$< of=$@ bs=2048 skip=16

%.o : $(SRC)/%.c
	$(SHCC) -MMD -c -I. $(SHCFLAGS) $< -o $@

%.o : $(SRC)/%.s
	$(SHCC) -MMD -c -I. $(SHCFLAGS) $< -o $@

crt0.o : $(SRC)/crt0.S
	$(SHCC) -c -x assembler-with-cpp -o $@ $<

testdata.bin : gentestdata
	./$^ > $@

dummydata.bin :
	dd if=/dev/zero of=$@ bs=2048 count=300

gentestdata : $(SRC)/pseudorandom.c $(SRC)/pseudorandom.h
	$(CC) -o $@ -DSTANDALONE_TOOL $<

-include $(OBJ:%.o=%.d) $(OBJ_TEST:%.o=%.d)

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


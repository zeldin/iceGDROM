ifeq ($(origin _),command line)

SRC := $(SRCDIR)source

SOURCES = main.c sdcard.c fatfs.c imgfile.c cdda.c ide.c debug.c timer.c
ASOURCES = start.S delay.S support.S

CC = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
ABI = ilp32e
ARCH = rv32emc_zicsr

CFLAGS = -Os -fomit-frame-pointer -msmall-data-limit=100
LDFLAGS = -Wl,--defsym,__stack=0x3000,-T,$(SRC)/main.lds,-Map,$@.map -nostartfiles -mrelax

ALL_CFLAGS = -mabi=$(ABI) -march=$(ARCH) -I. -I$(SRC) $(CFLAGS)
ALL_ASFLAGS = -mabi=$(ABI) -march=$(ARCH) -I. -I$(SRC) -x assembler-with-cpp $(ASFLAGS)

OBJ = $(SOURCES:%.c=%.o) $(ASOURCES:%.S=%.o)

AVRDUDE_PORT ?= /dev/ttyUSB1

all : rv32_main.hex pmem.hex

flash : pmem.hex

upload : rv32_main.hex
	avrdude -c butterfly_mk -p uc3a0512 -b 115200 $(if $(AVRDUDE_PORT),-P,) $(AVRDUDE_PORT) -D -U flash:w:$<

tests :

.SECONDARY:

rv32_main.elf: $(OBJ)
	$(CC) $(ALL_CFLAGS) $^ -o $@ $(LDFLAGS)

pmem.hex : rv32_main.bin
	od -v -An -tx4 --endian=little < $^ > $@

%.hex: %.elf
	$(OBJCOPY) -O ihex --change-addresses=0x80000000 $< $@

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

%.o : $(SRC)/%.c
	$(CC) -MMD -c $(ALL_CFLAGS) $< -o $@

%.o : $(SRC)/%.S
	$(CC) -MMD -c $(ALL_ASFLAGS) $< -o $@

-include $(OBJ:%.o=%.d)

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


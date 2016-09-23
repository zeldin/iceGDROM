ifeq ($(origin _),command line)

SRC := $(SRCDIR)source

SOURCES = main.c sdcard.c fatfs.c imgfile.c cdda.c ide.c timer.c debug.c
ASOURCES = delay.S

CC = avr-gcc
OBJCOPY = avr-objcopy
MCU = atmega64

CFLAGS = -Os -fomit-frame-pointer
LDFLAGS = -Wl,--defsym,__stack=0xfff -mrelax

ALL_CFLAGS = -mmcu=$(MCU) -I. -I$(SRC) $(CFLAGS)
ALL_ASFLAGS = -mmcu=$(MCU) -I. -I$(SRC) -x assembler-with-cpp $(ASFLAGS)

OBJ = $(SOURCES:%.c=%.o) $(ASOURCES:%.S=%.o) 

AVRDUDE_PORT ?= /dev/ttyUSB1

all : avr_main.hex pmem_high.hex pmem_low.hex

flash : pmem_high.hex pmem_low.hex

upload : avr_main.hex
	avrdude -c butterfly_mk -p ucr2 -b 115200 $(if $(AVRDUDE_PORT),-P,) $(AVRDUDE_PORT) -U flash:w:$<

tests :

.SECONDARY:

avr_main.elf: $(OBJ)
	$(CC) $(ALL_CFLAGS) $^ -o $@ $(LDFLAGS)

pmem_high.hex : avr_main.bin
	dd conv=sync ibs=4096 < $^ | od -v -An -tx2 --endian=little | sed -e 's/\([0-9a-fA-F]\{2\}\)[0-9a-fA-F]\{2\}/\1/g' | tr -s '[:blank:]' '\n' | sed -e '/^$$/d' > $@

pmem_low.hex : avr_main.bin
	dd conv=sync ibs=4096 < $^ | od -v -An -tx2 --endian=little | sed -e 's/[0-9a-fA-F]\{2\}\([0-9a-fA-F]\{2\}\)/\1/g' | tr -s '[:blank:]' '\n' | sed -e '/^$$/d' > $@

%.hex: %.elf
	$(OBJCOPY) -O ihex -R .eeprom -R .fuse -R .lock $< $@

%.bin: %.elf
	$(OBJCOPY) -O binary -R .eeprom -R .fuse -R .lock $< $@

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


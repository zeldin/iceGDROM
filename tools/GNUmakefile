ifeq ($(origin _),command line)

SRC := $(SRCDIR)source

SOURCES = main.c imgfile.c nrg.c gdi.c cdi.c track.c msg.c

OBJ = $(SOURCES:%.c=%.o)

CFLAGS ?= -O2 -std=c99

all : makegdimg


flash :


upload :


tests : makegdimg


makegdimg: $(OBJ)
	$(CC) $(CFLAGS) $^ -o $@ $(LDFLAGS)

%.o : $(SRC)/%.c
	$(CC) -MMD -c -I. $(CFLAGS) $< -o $@

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


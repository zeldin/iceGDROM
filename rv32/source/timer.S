#include "config.h"
#include "custom_ops.S"

	.global timer_init, centis

	.section .text
	
timer_init:
	li a0, CPU_FREQ/100
        picorv32_timer_insn(zero, a0)
	ret

	.section .sbss

	.balign 1
centis:
	.space 1


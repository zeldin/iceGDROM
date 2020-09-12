#include "config.h"
#include "hardware.h"

	.section .text
	.global _start, main, __stack, centis

		
_start:
	j init

	.org _start+4

exception:
	csrw mscratch,a0
	csrr a0, mcause
	bgtz a0, _start
	slli a0, a0, 1
	addi a0, a0, -(2*7)
	beqz a0, isTimer
	csrr a0, mscratch
	j IRQ3_vect
isTimer:
	lb a0, %lo(centis)(zero)
	addi a0, a0, 1
	sb a0, %lo(centis)(zero)
	li a0, _BV(OCF0)
	sw a0, TIFR(zero)
	csrr a0, mscratch
	mret


init:
	/* set stack pointer */
	lui sp, %hi(__stack)
	addi sp, sp, %lo(__stack)

	li a0, 0x880     //880 enable timer + external interrupts
	csrw mie,a0
	li a0, 0x1800
	csrw mstatus,a0

	/* call main */
	jal ra, main

	/* break */
	ebreak


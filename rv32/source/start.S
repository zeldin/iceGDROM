#include "config.h"
#include "custom_ops.S"

	.section .text
	.global _start, main, __stack, centis

#ifdef __riscv_32e
#define REGSAVE_SIZE 8*4
#else
#define REGSAVE_SIZE 14*4
#endif

		
_start:
	/* set stack pointer */
	lui sp, %hi(__stack)
	addi sp, sp, %lo(__stack)

	/* call main */
	jal ra, main

	/* break */
	ebreak

	
	.balign 16
irq_vec:
        picorv32_setq_insn(q2, a0)
        picorv32_setq_insn(q3, a1)

	picorv32_getq_insn(a0, q1)
	andi a1, a0, 1<<0
	beqz a1, notimer

	li a1, CPU_FREQ/100
        picorv32_timer_insn(zero, a1)
	lb a1, %lo(centis)(zero)
	addi a1, a1, 1
	sb a1, %lo(centis)(zero)

notimer:
	andi a0, a0, 1<<3
	beqz a0, noirq3
        picorv32_setq_insn(q1, sp)
	lui sp, %hi(irq_stack_regsave)
	addi sp, sp, %lo(irq_stack_regsave)
	sw ra, 0*4(sp)
	sw t0, 1*4(sp)
	sw t1, 2*4(sp)
	sw t2, 3*4(sp)
	sw a2, 4*4(sp)
	sw a3, 5*4(sp)
	sw a4, 6*4(sp)
	sw a5, 7*4(sp)
#ifndef __riscv_32e
	sw a6, 8*4(sp)
	sw a7, 9*4(sp)
	sw t3, 10*4(sp)
	sw t4, 11*4(sp)
	sw t5, 12*4(sp)
	sw t6, 13*4(sp)
#endif
	jal ra, IRQ3_vect
#ifndef __riscv_32e
	lw t6, 13*4(sp)
	lw t5, 12*4(sp)
	lw t4, 11*4(sp)
	lw t3, 10*4(sp)
	lw a7, 9*4(sp)
	lw a6, 8*4(sp)
#endif
	lw a5, 7*4(sp)
	lw a4, 6*4(sp)
	lw a3, 5*4(sp)
	lw a2, 4*4(sp)
	lw t2, 3*4(sp)
	lw t1, 2*4(sp)
	lw t0, 1*4(sp)
	lw ra, 0*4(sp)
        picorv32_getq_insn(sp, q1)
	
noirq3:
	picorv32_getq_insn(a0, q2)
	picorv32_getq_insn(a1, q3)
        picorv32_retirq_insn()


	.section .bss

	.balign 4
irq_stack:
	.space 64
irq_stack_regsave:
	.space REGSAVE_SIZE



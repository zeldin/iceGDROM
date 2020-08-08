#include "config.h"
#include "custom_ops.S"

	.global sei, cli, memcpy, memcmp

	.section .text

sei:
	li a0, -10
	picorv32_maskirq_insn(zero, a0)
	ret
	
cli:
	li a0, -1
	picorv32_maskirq_insn(zero, a0)
	ret

memcpy:
	add  a2,a2,a0
	mv   a4,a0
	bgeu a0,a2,2f
1:	
	lbu  a3,0(a1)
	addi a4,a4,1
	addi a1,a1,1
	sb   a3,-1(a4)
	bltu a4,a2,1b
2:
	ret

memcmp:
	add a2,a2,a0
	bgeu a0,a2,2f	
1:	
	lbu a3,0(a0)
	lbu a4,0(a1)
	addi a0,a0,1
	addi a1,a1,1
	bne a3,a4,3f
	bne a0,a2,1b
2:
	li  a0,0
	ret
3:
	sub a0,a3,a4
	ret


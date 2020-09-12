
#include "config.h"
	
	.section .text

	.global delay1ms, delayms, delaycycles

delay1ms:
	li	a0, 1
delayms:
2:	
	li	a1, CPU_FREQ/(5*1000)
1:
	addi	a1,a1,-1
	bnez	a1,1b
	addi	a0,a0,-1
	bnez	a0,2b
	ret

delaycycles:
1:
	addi	a0,a0,-5
	bge	a0,x0,1b
	ret

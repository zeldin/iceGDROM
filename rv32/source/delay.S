
#include "config.h"
	
	.section .text

	.global delay1ms, delayms, delaycycles

delay1ms:
	li	a0, 1
delayms:
2:	
	li	a1, CPU_FREQ/(10*1000)
1:
	addi	a1,a1,-1
	bne	a1,x0,1b
	addi	a0,a0,-1
	bne	a0,x0,2b
	ret

delaycycles:
1:
	addi	a0,a0,-11
	bge	a0,x0,1b
	ret

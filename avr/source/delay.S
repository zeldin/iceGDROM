
#define __SFR_OFFSET 0
#include "hardware.h"

	.global	delay1ms
	.global	delayms
	.global delaycycles

	.text

delay1ms:
	ldi	r24,1
delayms:
3:
	;; 22359 cycles
	ldi	r21,29
2:
	;; 768 cycles
	clr	r20
1:
	dec	r20
	brne	1b

	dec	r21
	brne	2b


	;; 219 cycles
	ldi	r20,73
1:
	dec	r20
	brne	1b

	dec	r24
	brne	3b

	ret

delaycycles:
1:
	subi	r24,3
	brcc	1b

	ret

	.end


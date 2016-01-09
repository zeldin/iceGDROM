
#define __SFR_OFFSET 0
#include "hardware.h"

	.global	delay1ms
	.global	delayms

	.text

delay1ms:
	ldi	r25,1
delayms:
3:
	;; 23901 cycles
	ldi	r21,31
2:
	;; 768 cycles
	clr	r20
1:
	dec	r20
	brne	1b

	dec	r21
	brne	2b


	;; 99 cycles
	ldi	r20,33
1:
	dec	r20
	brne	1b

	dec	r25
	brne	3b

	ret

	.end


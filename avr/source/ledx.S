
#define __SFR_OFFSET 0
#include "hardware.h"

	.text

	ldi	r24,0xf
	out	DDRA,r24
	ldi	r24,0x1
	ldi	r25,0x30
	ldi	r23,_BV(TXC)
	out	UCSR0A,r23
	ldi	r23,_BV(TXEN)|4
	out	UCSR0B,r23
	ldi	r23,(_BV(UCSZ1)|_BV(UCSZ0))>>1
	out	UCSR0C,r23
	ldi	r23,0x19
	out	UBRR0L,r23
9:	
	out	PORTA,r24
	
	;; 11842740 cycles (0.99s)
	ldi	r22,60
3:		
	;; 197376 cycles
	clr	r21
2:	
	;; 768 cycles
	clr	r20
1:
	dec	r20
	brne	1b
	
	dec	r21
	brne	2b

	dec	r22
	brne	3b

	clc
	rol	r24
	brcc	1f
	inc	r24
1:	

	inc	r25
	andi	r25,0xf
	ori	r25,0x30
	out	UDR0,r25
	
	rjmp	9b
	nop
		
	.end

	
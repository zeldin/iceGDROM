
	.text

	ldi	r24,0xf
	out	0x1a,r24
	ldi	r24,0x1
	ldi	r25,0x30
	ldi	r23,0x02
	out	0xb,r23
	ldi	r23,0x0c
	out	0x6/*0xa*/,r23
	ldi	r23,0x03
	out	0x7,r23
	ldi	r23,0x19
	out	0x9,r23
9:	
	;; out	0x1b,r24
	sts	0x3b,r24
	
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
	out	0xc,r25	
	
	rjmp	9b
	nop
		
	.end

	
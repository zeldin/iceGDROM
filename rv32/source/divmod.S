	.section .text
	.global divmod

divmod:
	mv a2,a1
	mv a1,a0
	li a3,1
	li a0,0
	bgeu a2,a1,2f
1:
	blez a2,2f
	slli a2,a2,1
	slli a3,a3,1
	bltu a2,a1,1b
2:
	bltu a1,a2,3f
	sub a1,a1,a2
	or a0,a0,a3
3:
	srli a3,a3,1
	srli a2,a2,1
	bnez a3,2b
	ret

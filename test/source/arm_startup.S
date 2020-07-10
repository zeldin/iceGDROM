#
# Generic startup and interrupt handler for ARM7 CPU.
#
# Note:	Stack is allocated at 0x3ff00, keep the binary short.  :-)
#
	
	.globl	_start

	.text


	# Exception vectors
_start:
	b	reset
	b	undef
	b	softint
	b	pref_abort
	b	data_abort
	b	rsrvd
	b	irq


	# "Fast interrupt" handler
fiq:
	subs	pc,r14,#4

	
	# No-op handlers for the remaining vectors

undef:
softint:
	movs	pc,r14

pref_abort:
irq:
rsrvd:
	subs	pc,r14,#4
	
data_abort:
	subs	pc,r14,#8


	# Reset entry point
	
reset:
	# Disable IRQ and disable FIQ
	mrs	r0,CPSR
	orr	r0,r0,#0xc0
	msr	CPSR,r0
	# Set stack
	ldr   sp,stack_base
	# Call main
	bl	main

	# Done.  Stay put.
done:	b	done


stack_base:	
	.long 0x3ff00
	
	.end


	.globl	start

	.section .text.startup

start:
	! First, make sure to run in the P2 area
	mova    setup_cache,r0
	mov.l   p2_mask,r1
	or      r1,r0
	jmp     @r0
	nop
	nop
	nop
	nop
setup_cache:
	! Now that we are in P2, it's safe
	! to disable the cache
	mov.l   ccr_addr,r1
	mov.w   ccr_0data,r2
	mov.l   r2,@r1
	! Check if we're where we want to be...
	mov.l   setup_cache_addr,r1
	mov.l   p2_mask,r2
	or      r2,r1
	cmp/eq  r1,r0
	bt      ok_place
	! Nope, need to copy...
	add     #-(setup_cache-start),r0
	add     #-(setup_cache-start),r1
	mov.l   bss_start_addr,r3
	mov.l   start_addr,r2
	sub     r2,r3
	add     #3,r3
	shlr2   r3
copyloop:
	mov.l   @r0+,r2
	dt      r3
	mov.l   r2,@r1
	bf/s    copyloop
	add     #4,r1

ok_place:
	! Reenable cache
	mov.l   ccr_addr,r0
	mov.w   ccr_data,r1
	mov.l   r1,@r0
	! After changing CCR, eight instructions
	! must be executed before it's safe to enter
	! a cached area such as P1
	mov.l   init_addr,r0    ! 1
	mov     #0,r1           ! 2
	nop                     ! 3
	nop                     ! 4
	nop                     ! 5
	nop                     ! 6
	nop                     ! 7
	nop                     ! 8
	jmp     @r0             ! go
	mov     r1,r0

init:
	mov.l   stack_pointer,r15
	mov.l   bss_start_addr,r0
	mov.l   bss_end_addr,r2
	sub     r0,r2
	shlr    r2
	shlr    r2
	mov     #0,r1
.loop:  dt      r2
	mov.l   r1,@r0
	bf/s    .loop
	add     #4,r0

	mov.l   main_addr,r0
	jmp     @r0
	nop


	.align  2
stack_pointer:
	.long   0x8cfffffc
p2_mask:
	.long   0xa0000000
setup_cache_addr:
	.long   setup_cache
init_addr:
	.long   init
main_addr:
	.long   _main
bss_start_addr:
	.long   __bss_start
bss_end_addr:
	.long   _end
start_addr:
	.long   start
ccr_addr:
	.long   0xff00001c
ccr_data:
	.word   0x0909
ccr_0data:
	.word   0x0808

	.end

	.globl	_check_cable, _init_video, _clrscr, _draw_string
	.globl	_draw_char12, _draw_char24, _get_font_address

	.text


	! Draw a text string on screen
	!
	! Assumes a 640*480 screen with RGB555 or RGB565 pixels

	! r4 = x
	! r5 = y
	! r6 = string
	! r7 = colour
_draw_string:
	mov.l	r14,@-r15
	sts	pr,r14
	mov.l	r13,@-r15
	mov.l	r12,@-r15
	mov.l	r11,@-r15
	mov.l	r10,@-r15
	mov	r4,r10
	mov	r5,r11
	mov	r6,r12
	mov	r7,r13
ds_loop:
	mov.b	@r12+,r6
	mov	r10,r4
	mov	r11,r5
	tst	r6,r6	! string is NUL terminated
	bt	ds_done
	extu.b	r6,r6	! undo sign-extension of char
	bsr	draw_ascii12
	mov	r13,r7
	bra	ds_loop
	add	#12,r10
ds_done:
	mov.l	@r15+,r10
	mov.l	@r15+,r11
	mov.l	@r15+,r12
	mov.l	@r15+,r13
	lds	r14,pr
	rts
	mov.l	@r15+,r14





	! Draw a "narrow" character on screen
	!
	! Assumes a 640*480 screen with RGB555 or RGB565 pixels

	! r4 = x
	! r5 = y
	! r6 = char
	! r7 = colour
_draw_char12:
	! First get the address of the ROM font
	sts	pr,r3
	mov.l	syscall_b4,r0
	mov.l	@r0,r0
	jsr	@r0
	mov	#0,r1
	lds	r3,pr
	mov	r0,r2

	! Then, compute the destination address
	shll	r4
	mov	r5,r0
	shll2	r0
	add	r5,r0
	shll8	r0
	add	r4,r0
	mov.l	vrambase,r1
	bra	decided
	add	r1,r0

draw_ascii12:
	! First get the address of the ROM font
	sts	pr,r3
	mov.l	syscall_b4,r0
	mov.l	@r0,r0
	jsr	@r0
	mov	#0,r1
	lds	r3,pr
	mov	r0,r2

	! Then, compute the destination address
	shll	r4
	mov	r5,r0
	shll2	r0
	add	r5,r0
	shll8	r0
	add	r4,r0
	mov.l	vrambase,r1
	add	r1,r0

	! Find right char in font
	mov	#32,r1
	cmp/gt	r1,r6
	bt	okchar1
	! <= 32 = space or unprintable
blank:
	mov	#72,r6	! Char # 288 in font is blank
	bra	decided
	shll2	r6
okchar1:
	mov	#127,r1
	cmp/ge	r1,r6
	bf/s	decided	! 33-126 = ASCII, Char # 1-94 in font
	add	#-32,r6
	cmp/gt	r1,r6
	bf	blank	! 127-159 = unprintable
	add	#-96,r6
	cmp/gt	r1,r6
	bt	blank	! 256- = ?
	! 160-255 = Latin 1, char # 96-191 in font
	add	#64,r6

	! Add offset of selected char to font addr
decided:
	mov	r6,r1
	shll2	r1
	shll	r1
	add	r6,r1
	shll2	r1
	add	r2,r1

	! Copy ROM data into cache so we can access it as bytes
	! Char data is 36 bytes, so we need to fetch two cache lines
	pref	@r1
	mov	r1,r2
	add	#32,r2
	pref	@r2

	mov	#24,r2	! char is 24 lines high
drawy:
	! Each pixel line is stored as 1½ bytes, so we'll load
	! 3 bytes into r4 and draw two lines in one go
	mov.b	@r1+,r4
	shll8	r4
	mov.b	@r1+,r5
	extu.b	r5,r5
	or	r5,r4
	shll8	r4
	mov.b	@r1+,r5
	extu.b	r5,r5
	or	r5,r4
	shll8	r4
	! Even line
	mov	#12,r3
drawx1:
	rotl	r4
	bf/s	nopixel1
	dt	r3
	mov.w	r7,@r0	! Set pixel
nopixel1:
	bf/s	drawx1
	add	#2,r0
	mov.w	drawmod,r3
	dt	r2
	add	r3,r0
	! Odd line
	mov	#12,r3
drawx2:
	rotl	r4
	bf/s	nopixel2
	dt	r3
	mov.w	r7,@r0	! Set pixel
nopixel2:
	bf/s	drawx2
	add	#2,r0
	mov.w	drawmod,r3
	dt	r2
	bf/s	drawy
	add	r3,r0

	rts
	nop


	! Draw a "wide" character on screen
	!
	! Assumes a 640*480 screen with RGB555 or RGB565 pixels

	! r4 = x
	! r5 = y
	! r6 = char
	! r7 = colour
_draw_char24:
	! First get the address of the ROM font
	sts	pr,r3
	mov.l	syscall_b4,r0
	mov.l	@r0,r0
	jsr	@r0
	mov	#0,r1
	mov.w	.n2880,r2
	lds	r3,pr
	add	r0,r2

	! Then, compute the destination address
	shll	r4
	mov	r5,r0
	shll2	r0
	add	r5,r0
	shll8	r0
	add	r4,r0
	mov.l	vrambase,r1
	add	r1,r0

	! Add offset of selected char to font addr

	mov	r6,r1
	shll2	r1
	shll	r1
	add	r6,r1
	shll2	r1
	shll	r1
	add	r2,r1

	! Copy ROM data into cache so we can access it as bytes
	! Char data is 72 bytes, so we need to fetch three cache lines
	pref	@r1
	mov	r1,r2
	add	#32,r2
	pref	@r2
	add	#32,r2
	pref	@r2

	mov	#24,r2	! char is 24 lines high
wdrawy:
	! Each pixel line is stored as 3 bytes, so we'll load
	! 3 bytes into r4 and draw one line
	mov.b	@r1+,r4
	shll8	r4
	mov.b	@r1+,r5
	extu.b	r5,r5
	or	r5,r4
	shll8	r4
	mov.b	@r1+,r5
	extu.b	r5,r5
	or	r5,r4
	shll8	r4

	mov	#24,r3
wdrawx:
	rotl	r4
	bf/s	wnopixel
	dt	r3
	mov.w	r7,@r0	! Set pixel
wnopixel:
	bf/s	wdrawx
	add	#2,r0
	dt	r2
	mov.w	wdrawmod,r3
	bf/s	wdrawy
	add	r3,r0

	rts
	nop



	.align	4
drawmod:
	.word	2*(640-12)
wdrawmod:
	.word	2*(640-24)
.n2880:
	.word	0x2880


	! Clear screen
	!
	! Assumes a 640*480 screen with RGB555 or RGB565 pixels

	! r4 = pixel colour
_clrscr:
	mov.l	vrambase,r0
	mov.l	clrcount,r1
clrloop:
	mov.w	r4,@r0	! clear one pixel
	dt	r1
	bf/s	clrloop
	add	#2,r0
	rts
	nop


	.align	4
vrambase:
	.long	0xa5000000
clrcount:
	.long	640*480



	! Set up video registers to the desired
	! video mode (only 640*480 supported right now)
	!
	! Note:	This function does not currently initialize
	!       all registers, but assume that the boot ROM
	!	has set up reasonable defaults for syncs etc.
	!
	! TODO:	PAL

	! r4 = cabletype (0=VGA, 2=RGB, 3=Composite)
	! r5 = pixel mode (0=RGB555, 1=RGB565, 3=RGB888)
_init_video:
	! Look up bytes per pixel as shift value
	mov	#3,r1
	and	r5,r1
	mova	bppshifttab,r0
	mov.b	@(r0,r1),r5
	! Get video HW address
	mov.l	videobase,r0
	mov	#0,r2
	mov.l	r2,@(8,r0)
	add	#0x40,r0
	! Set border colour
	mov	#0,r2
	mov.l	r2,@r0
	! Set pixel clock and colour mode
	shll2	r1
	mov	#240/2,r3	! Non-VGA screen has 240 display lines
	shll	r3
	mov	#2,r2
	tst	r2,r4
	bf/s	khz15
	add	#1,r1
	shll	r3		! Double # of display lines for VGA
	! Set double pixel clock
	mov	#1,r2
	rotr	r2
	shlr8	r2
	or	r2,r1
khz15:
	mov.l	r1,@(4,r0)
	! Set video base address
	mov	#0,r1
	mov.l	r1,@(0x10,r0)
	! Video base address for short fields should be offset by one line
	mov	#640/16,r1
	shll2	r1
	shll2	r1
	shld	r5,r1
	mov.l	r1,@(0x14,r0)
	! Set screen size and modulo, and interlace flag
	mov.l	r4,@-r15
	mov	#1,r2
	shll8	r2
	mov	#640/16,r1
	shll2	r1
	shld	r5,r1
	mov	#2,r5
	tst	r5,r4
	bt/s	nonlace	! VGA => no interlace
	mov	#1,r4
	add	r1,r4	! add one line to offset => display every other line
	add	#0x10,r2	! enable LACE
nonlace:
	shll8	r4
	shll2	r4
	add	r3,r4
	add	#-1,r4
	shll8	r4
	shll2	r4
	add	r1,r4
	add	#-1,r4
	mov.l	r4,@(0x1c,r0)
	mov.l	@r15+,r4
	add	#0x7c,r0
	mov.l	r2,@(0x14,r0)
	! Set vertical pos and border
	mov	#36,r1
	mov	r1,r2
	shll16	r1
	or	r2,r1
	mov.l	r1,@(0x34,r0)
	add	r3,r1
	mov.l	r1,@(0x20,r0)
	! Horizontal pos
	mov.w	hpos,r1
	mov.l	r1,@(0x30,r0)

	! Select RGB/CVBS
	mov.l	cvbsbase,r1
	rotr	r4
	bf/s	rgbmode
	mov	#0,r0
	mov	#3,r0
rgbmode:
	shll8	r0
	mov.l	r0,@r1

	rts
	nop

	.align	4
videobase:
	.long	0xa05f8000
cvbsbase:
	.long	0xa0702c00
bppshifttab:
	.byte	1,1,0,2
hpos:
	.word	0xa4



	! Check type of A/V cable connected
	!
	! 0 = VGA
	! 1 = ---
	! 2 = RGB
	! 3 = Composite

_check_cable:
	! set PORT8 and PORT9 to input
	mov.l	porta,r0
	mov.l	pctra_clr,r2
	mov.l	@r0,r1
	mov.l	pctra_set,r3
	and	r2,r1
	or	r3,r1
	mov.l	r1,@r0
	! read PORT8 and PORT9
	mov.w	@(4,r0),r0
	shlr8	r0
	rts
	and	#3,r0



	! Return base address of ROM font
	!

_get_font_address:
	mov.l	syscall_b4,r0
	mov.l	@r0,r0
	jmp	@r0
	mov	#0,r1



	.align 4
porta:
	.long	0xff80002c
pctra_clr:
	.long	0xfff0ffff
pctra_set:
	.long	0x000a0000
syscall_b4:
	.long	0x8c0000b4


	.end

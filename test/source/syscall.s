	.globl	_gdGdcReqCmd, _gdGdcGetCmdStat, _gdGdcExecServer
	.globl	_gdGdcInitSystem, _gdGdcGetDrvStat, _gdGdcG1DmaEnd
	.globl	_gdGdcReqDmaTrans, _gdGdcCheckDmaTrans, _gdGdcReadAbort
	.globl	_gdGdcReset, _gdGdcChangeDataType

	.text


_gdGdcReqCmd:
	bra	do_syscall
	mov	#0,r7

_gdGdcGetCmdStat:
	bra	do_syscall
	mov	#1,r7

_gdGdcExecServer:
	bra	do_syscall
	mov	#2,r7

_gdGdcInitSystem:
	bra	do_syscall
	mov	#3,r7

_gdGdcGetDrvStat:
	bra	do_syscall
	mov	#4,r7

_gdGdcG1DmaEnd:
	bra	do_syscall
	mov	#5,r7

_gdGdcReqDmaTrans:
	bra	do_syscall
	mov	#6,r7

_gdGdcCheckDmaTrans:
	bra	do_syscall
	mov	#7,r7

_gdGdcReadAbort:
	bra	do_syscall
	mov	#8,r7

_gdGdcReset:
	bra	do_syscall
	mov	#9,r7

_gdGdcChangeDataType:
	mov	#10,r7

do_syscall:
	mov.l	sysvec_bc,r0
	mov	#0,r6
	mov.l	@r0,r0
	jmp	@r0
	nop
	.align	4
sysvec_bc:
	.long	0x8c0000bc

	.end

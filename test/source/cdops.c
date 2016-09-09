#include "cdops.h"

extern void gdGdcInitSystem();
extern void gdGdcReset();
extern int gdGdcReqCmd(int command, unsigned int *parameterblock);
extern int gdGdcGetCmdStat(int reqid, unsigned int *status);
extern int gdGdcGetDrvStat(unsigned int *status);
extern void gdGdcExecServer();
extern int gdGdcChangeDataType(unsigned int *format);

extern void usleep(unsigned int usec);


#define GDROM(o)	(*(volatile unsigned char *)(0xa05f7000 + (o)))

#define DATA		(*(volatile short *) & GDROM(0x80))
#define FEATURES	GDROM(0x84)
#define SEC_NR		GDROM(0x8c)
#define CYL_LO		GDROM(0x90)
#define CYL_HI		GDROM(0x94)
#define COMMAND		GDROM(0x9c)
#define STATUS		GDROM(0x9c)
#define ALTSTATUS	GDROM(0x18)

void cdops_init()
{
  register unsigned long p, x;
  *((volatile unsigned long *)0xa05f74e4) = 0x1fffff;
  for(p=0; p<0x200000/4; p++)
    x = ((volatile unsigned long *)0xa0000000)[p];
  gdGdcInitSystem();
  gdGdcReset();
}

unsigned char cdops_disc_status()
{
  return SEC_NR;
}

static int cdops_send_cmd(int cmd, void *param)
{
  return gdGdcReqCmd(cmd, param);
}

static int cdops_check_cmd(int f)
{
  int blah[4];
  int n;
  gdGdcExecServer();
  if((n = gdGdcGetCmdStat(f, blah))==1)
    return 0;
  if(n == 2)
    return 1;
  else return -1;
}

static int cdops_wait_cmd(int f)
{
  int n;
  while(!(n = cdops_check_cmd(f)));
  return (n>0? 0 : n);
}

static int cdops_exec_cmd(int cmd, void *param)
{
  int f = cdops_send_cmd(cmd, param);
  return cdops_wait_cmd(f);
}

int cdops_init_drive()
{
  int i, r=0;
  unsigned int param[4];
  int cdxa;

  for(i=0; i<8; i++)
    if(!(r = cdops_exec_cmd(24, 0)))
      break;
  if(r)
    return r;

  gdGdcGetDrvStat(param);

  cdxa = (param[1] == 32);

  param[0] = 0; /* set data type */
  param[1] = 8192;
  param[2] = (cdxa? 2048 : 1024); /* mode 1/2 */
  param[3] = 2048; /* sector size */

  return gdGdcChangeDataType(param);
}

int cdops_read_toc(struct TOC *toc, int session)
{
  struct { int session; void *buffer; } param;
  param.session = session;
  param.buffer = toc;
  return cdops_exec_cmd(19, &param);
}

int cdops_read_sectors_pio(char *buf, int sec, int num)
{
  struct { int sec, num; void *buffer; int dunno; } param;
  param.sec = sec;
  param.num = num;
  param.buffer = buf;
  param.dunno = 0;
  return cdops_exec_cmd(16, &param);
}

int cdops_read_sectors_dma(char *buf, int sec, int num)
{
  struct { int sec, num; void *buffer; int dunno; } param;
  param.sec = sec;
  param.num = num;
  param.buffer = buf;
  param.dunno = 0;
  return cdops_exec_cmd(17, &param);
}

int cdops_packet(const unsigned short *packet, unsigned short size, void *buf)
{
  register unsigned int sr = 0;
  int i;
  unsigned short tot = 0;
  size &= ~1;
  while(ALTSTATUS & 0x88)
    ;
  __asm__("stc sr,%0" : "=r" (sr));
  __asm__("ldc %0,sr" : : "r" (sr|(1<<28)));
  CYL_LO = size & 0xff;
  CYL_HI = size >> 8;
  FEATURES = 0;
  COMMAND = 0xa0;
  while((ALTSTATUS & 0x88) != 8)
    ;
  for (i=0; i<6; i++)
    DATA = packet[i];
  usleep(10);
  for(;;) {
    unsigned char status = STATUS;
    if (status & 0x80)
      continue;
    if (status & 8) {
      unsigned short cnt = (CYL_HI << 8) | CYL_LO;
      if (cnt & 1)
	cnt++;
      tot += cnt;
      unsigned short xfer = (cnt > size? size : cnt);
      for (i=0; i<xfer; i+=2) {
	*(unsigned short *)buf = DATA;
	buf = ((unsigned short *)buf) + 1;
	cnt -= 2;
	size -= 2;
      }
      while (cnt > 0) {
	unsigned short discard = DATA;
	cnt -= 2;
      }
      usleep(10);
      continue;
    }
    if (status & 1) {
      __asm__("ldc %0,sr" : : "r" (sr));
      return -1;
    }
    break;
  }
  __asm__("ldc %0,sr" : : "r" (sr));
  return tot;
}

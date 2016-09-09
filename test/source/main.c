#include <stdarg.h>
#include <string.h>

#include "cdops.h"

extern int check_cable(void);
extern void init_video(int cabletype, int pixelmode);
extern void clrscr(int color);
extern void draw_string(int x, int y, const char *str, int color);
extern void draw_char12(int x, int y, int c, int color);
extern void draw_char24(int x, int y, int c, int color);

extern void run_test(void);

#define TMU_REG(n) ((volatile void *)(0xffd80000+(n)))
#define TOCR (*(volatile unsigned char *)TMU_REG(0))
#define TSTR (*(volatile unsigned char *)TMU_REG(4))
#define TCOR0 (*(volatile unsigned int *)TMU_REG(8))
#define TCNT0 (*(volatile unsigned int *)TMU_REG(12))
#define TCR0 (*(volatile unsigned short *)TMU_REG(16))

#define USEC_TO_TIMER(x) (((x)*100)>>11)

static void init_tmr0()
{
  TSTR = 0;
  TOCR = 0;
  TCOR0 = ~0;
  TCNT0 = ~0;
  TCR0 = 4;
  TSTR = 1;
}

unsigned long Timer( )
{
  return ~TCNT0;
}

void usleep(unsigned int usec)
{
  unsigned int t0 = Timer();
  unsigned int dly = USEC_TO_TIMER(usec);
  while( ((unsigned int)(Timer()-t0)) < dly );
}

char *itoa(int x)
{
  static char buf[30];
  int minus = 0;
  int ptr=29;
  buf[29]=0;

  if(!x) return "0";
  if( x < 0 )  {  minus=1;  x = -x; }
  while(x > 0)
  {
    buf[--ptr] = x%10 + '0';
    x/=10;
  }
  if( minus ) buf[--ptr] = '-';
  return buf+ptr;
}

void chrat(int x, int y, char c, int color)
{
  char buf[2];
  buf[0] = c;
  buf[1] = '\0';
  draw_string(x*12, y*24, buf, color);
}

void wideat(int x, int y, int c, int color)
{
  draw_char24(x*12, y*24, c, color);
}

int strat(int x, int y, char *s, int color)
{
  draw_string(x*12, y*24, s, color);
  return strlen(s);
}

int wstrat(int x, int y, char *s, int color)
{
  int x0=x, c;
  while((c=0xff&*s++))
    if(c<0x81) {
      if(c<0x21 || c>0x7e)
	c = 96;
      else if(c==0x5c)
	c = 95;
      else if(c==0x7e)
	c = 0;
      else
	c -= 32;
      draw_char12(x*12, y*24, c, color);
      x++;
    } else if(c>=0xa1 && c<=0xdf) {
      draw_char12(x*12, y*24, c+32, color);
      x++;
    } else {
      int row, col;
      if(!*s) break;
      c = (c<<8) | (0xff&*s++);
      if(c >= 0xa000) c -= 0x4000;
      if((c & 0xff) > 0x9e) {
	row = 2*(c>>8)-0x101;
	col = (c & 0xff)-0x9f;
      } else {
	row = 2*(c>>8)-0x102;
	col = (c & 0xff)-0x40;
	if(col >= 0x40) --col;
      }
      if(row<0 || col<0 || row>83 || col>93 || (row>6 && row<15))
	row = col = 0;
      else if(row>6)
	row -= 8;
      draw_char24(x*12, y*24, row*94+col, color);
      x += 2;
    }
  return x-x0;
}

static int last_x = 0, last_y = 0;

void vprintat(int x, int y, const char *fmt, va_list va)
{
  int p;
  int color = 0xffff;
  while((p = *fmt++))
    if(p=='\n') {
      x = 0;
      y++;
    } else if(p=='%')
      switch(*fmt++)
      {
       case '\0': --fmt;    break;

       case 's': x += strat(x, y, va_arg(va, char *), color );   break;
       case 'S': x += wstrat(x, y, va_arg(va, char *), color );   break;
       case 'c': chrat(x++, y, va_arg(va, int), color );   break;
       case 'W': color = 0xffff; break;
       case 'C': color = va_arg(va, int); break;
       case 'z': wideat(x, y, va_arg(va, int)+7056, 0xffe0); x+=2; break;
       case '%': chrat(x++, y, '%', color); break;
       case 'd': x += strat(x, y, itoa(va_arg(va, int)), color ); break;
       case 'p': x += strat(x, y, "(void *)0x", color);
       case 'x':
       {
	 char buf[9];
	 int i, d;
	 int n = va_arg( va, int );
	 for(i=0; i<8; i++)
	 {
	   d = n&15;
	   n>>=4;
	   if(d<10)
	     buf[7-i]='0'+d;
	   else
	     buf[7-i]='a'+(d-10);
	 }
	 buf[8]=0;
	 if(fmt[-1]=='p')
	   x += strat(x, y, buf, color);
	 else
	   x += strat(x, y, buf+6, color);
	 break;
       }
       case 'b':
       {
	 char bits[33];
	 int i, d = va_arg( va, int);
	 bits[32]=0;
	 for( i = 0; i<31; i++ )
	   if( d & (1<<i) )
	     bits[31-i] = '1';
	   else
	     bits[31-i] = '0';
	 x += strat(x, y, bits, color );
	 break;
       }
      }
    else
      chrat(x++, y, p, color);
  last_x = x;
  last_y = y;
}

void printat(int x, int y, const char *fmt, ...)
{
  va_list va;
  va_start(va, fmt);
  vprintat(x, y, fmt, va);
  va_end(va);
}

int printf(const char *fmt, ...)
{
  va_list va;
  va_start(va, fmt);
  vprintat(last_x, last_y, fmt, va);
  va_end(va);
  return 0;
}

int main()
{
  cdops_init();
  init_tmr0();
  clrscr(0x1f);
  init_video(check_cable(), 1);

  run_test();

  for(;;)
    ;
}

#include <stdint.h>

#include "hardware.h"
#include "debug.h"

#define CLKRATE 22579200
#define BAUDRATE 115200

#ifndef NDEBUG

int debug_init()
{
  UCSR0A = _BV(TXC)|_BV(U2X);
  UCSR0B = _BV(TXEN);
  UCSR0C = _BV(UCSZ1)|_BV(UCSZ0);
  UBRR0L = CLKRATE / 8 / BAUDRATE - 1;
}

void debug_putc(char c)
{
  if (c == '\n')
    debug_putc('\r');
  loop_until_bit_is_set(UCSR0A, UDRE);
  UDR0 = c;
}

static void debug_putx1(uint8_t x)
{
  if((x &= 0xf) < 10)
    debug_putc('0'+x);
  else
    debug_putc(('A'-10)+x);
}

void debug_putx(uint8_t x)
{
  debug_putx1(x>>4);
  debug_putx1(x);
}

void debug_puts_P(const char *str)
{
  char c;
  while ((c = pgm_read_byte(str++)))
    debug_putc(c);
}

#endif

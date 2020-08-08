#include <stdint.h>

#include "config.h"

#include "hardware.h"
#include "debug.h"

#ifndef NDEBUG

void debug_init()
{
  UBRR0 = CPU_FREQ / BAUDRATE - 1;
}

void debug_putc(char c)
{
  if (c == '\n')
    debug_putc('\r');
  loop_until_bit_is_set(UCSR0, UDRE);
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

void debug_puts(const char *str)
{
  char c;
  while ((c = *str++))
    debug_putc(c);
}

#endif

#include <stdint.h>

#include "hardware.h"
#include "debug.h"

#define CLKRATE 24000000
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

void debug_puts_P(const char *str)
{
  char c;
  while ((c = pgm_read_byte(str++)))
    debug_putc(c);
}

#endif

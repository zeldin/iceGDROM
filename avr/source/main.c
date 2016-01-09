#include <stdint.h>

#include "hardware.h"
#include "delay.h"

#define CLKRATE 24000000
#define BAUDRATE 115200

int main()
{
  DDRA = 0xff;
  UCSR0A = _BV(TXC)|_BV(U2X);
  UCSR0B = _BV(TXEN);
  UCSR0C = _BV(UCSZ1)|_BV(UCSZ0);
  UBRR0L = CLKRATE / 8 / BAUDRATE - 1;

  uint8_t leds = 1;
  uint8_t digit = 0;

  for (;;) {
    PORTA = leds;
    delayms(250);
    delayms(250);
    if (!(leds <<= 1))
	leds++;

    digit++;
    digit&=0xf;
    UDR0 = digit | 0x30;
  }

  return 0;
}

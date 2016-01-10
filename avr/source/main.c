#include <stdint.h>

#include "hardware.h"
#include "debug.h"
#include "delay.h"

int main()
{
  DDRA = 0xff;
  DEBUG_INIT();

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
    DEBUG_PUTC(digit | 0x30);
  }

  return 0;
}

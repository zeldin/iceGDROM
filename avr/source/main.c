#include <stdint.h>
#include <stdbool.h>
#include <avr/interrupt.h>

#include "hardware.h"
#include "debug.h"
#include "delay.h"
#include "sdcard.h"
#include "timer.h"

void handle_sdcard()
{
  static uint8_t buf[512];

  DEBUG_PUTS("[Card inserted]\n");

  if (sd_init() && sd_read_block(0, buf)) {
    uint8_t *p = buf;
    uint8_t i, j;
    for (i=0; i<32; i++) {
      for (j=0; j<16; j++) {
	uint8_t b = *p++;
	DEBUG_PUTX(b);
      }
      DEBUG_PUTC('\n');
    }
  }

  loop_until_bit_is_clear(SD_CD_PIN, SD_CD_BIT);
  DEBUG_PUTS("[Card extracted]\n");
}

int main()
{
  DDRA = 0xff;
  DDRB = 0x00;
  DEBUG_INIT();
  timer_init();
  sei();

  uint8_t leds = 1;

  for (;;) {
    PORTA = leds;
    delayms(250);
    delayms(250);
    if (!(leds <<= 1))
	leds++;

    if (bit_is_set(SD_CD_PIN, SD_CD_BIT))
      handle_sdcard();
  }

  return 0;
}

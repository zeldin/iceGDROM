#include <stdint.h>
#include <stdbool.h>

#include "hardware.h"
#include "debug.h"
#include "delay.h"
#include "sdcard.h"

void handle_sdcard()
{
  DEBUG_PUTS("[Card inserted]\n");

  sd_init();

  loop_until_bit_is_clear(SD_CD_PIN, SD_CD_BIT);
  DEBUG_PUTS("[Card extracted]\n");
}

int main()
{
  DDRA = 0xff;
  DDRB = 0x00;
  DEBUG_INIT();

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

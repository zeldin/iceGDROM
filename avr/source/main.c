#include <stdint.h>
#include <stdbool.h>
#include <avr/interrupt.h>

#include "hardware.h"
#include "debug.h"
#include "delay.h"
#include "sdcard.h"
#include "ide.h"
#include "fatfs.h"
#include "timer.h"

void handle_sdcard()
{

  DEBUG_PUTS("[Card inserted]\n");

  if (sd_init())
    if (fatfs_mount())
      fatfs_read_rootdir();

  while (bit_is_set(SD_CD_PIN, SD_CD_BIT))
    service_ide();

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

    service_ide();

    if (bit_is_set(SD_CD_PIN, SD_CD_BIT))
      handle_sdcard();
  }

  return 0;
}

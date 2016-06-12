#include <stdint.h>
#include <stdbool.h>
#include <avr/interrupt.h>

#include "hardware.h"
#include "debug.h"
#include "delay.h"
#include "sdcard.h"
#include "ide.h"
#include "cdda.h"
#include "fatfs.h"
#include "imgfile.h"
#include "timer.h"

void handle_sdcard()
{

  DEBUG_PUTS("[Card inserted]\n");

  if (sd_init())
    if (fatfs_mount())
      if (fatfs_read_rootdir())
	imgfile_init();

  while (bit_is_clear(SD_CD_PIN, SD_CD_BIT)) {
    service_ide();
    service_cdda();
  }

  DEBUG_PUTS("[Card extracted]\n");
  cdda_stop();
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

    if (bit_is_clear(SD_CD_PIN, SD_CD_BIT))
      handle_sdcard();
  }

  return 0;
}

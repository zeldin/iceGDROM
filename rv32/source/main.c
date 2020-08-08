#include <stdint.h>
#include <stdbool.h>

#include "config.h"

#include "hardware.h"
#include "debug.h"
#include "delay.h"
#include "sdcard.h"
#include "ide.h"
#include "cdda.h"
#include "fatfs.h"
#include "imgfile.h"
#include "timer.h"

#if SD_CD_PIN_ACTIVE_HIGH
#define SDCARD_INSERTED (bit_is_set(SD_CD_PIN, SD_CD_BIT))
#else
#define SDCARD_INSERTED (bit_is_clear(SD_CD_PIN, SD_CD_BIT))
#endif

static bool find_imgfile()
{
  if (fatfs_read_rootdir())
    return true;
  fatfs_reset_filename();
  return fatfs_read_rootdir();
}

void handle_sdcard()
{

  DEBUG_PUTS("[Card inserted]\n");

  if (sd_init())
    if (fatfs_mount())
      if (find_imgfile())
	if (imgfile_init()) {
	  set_disk_type(imgheader.disk_type);
	  PORTA = fatfs_filenumber;
	  fatfs_next_filename();
	} else {
	  fatfs_reset_filename();
	  PORTA = ~0;
	}

  while (SDCARD_INSERTED) {
    service_ide();
    service_cdda();
  }

  DEBUG_PUTS("[Card extracted]\n");
  cdda_stop();
  set_disk_type(0xff);
}

int main()
{
  DDRA = 0xff;
  DDRB = 0x00;
  PORTB = 0x00;
  DDRB |= _BV(EMPH_BIT);
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

    if (SDCARD_INSERTED)
      handle_sdcard();
  }

  return 0;
}

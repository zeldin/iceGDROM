#include <stdint.h>
#include <stdbool.h>

#include "debug.h"
#include "cdda.h"
#include "hardware.h"
#include "timer.h"
#include "imgfile.h"

static bool cdda_active = false;
static uint8_t cdda_next_index;
static uint8_t cdda_subframe;

static bool cdda_fill_buffer()
{
  if (!imgfile_read_next_sector_cdda(cdda_next_index))
    return false;

  CDDA_LIMIT = (cdda_next_index << 7)|0x7f;

  cdda_next_index ^= 1;

  if ((cdda_subframe += (512/16)) >= (2352/16)) {
    cdda_subframe -= (2352/16);
    /* Advance sector # */
  }

  return true;
}

void cdda_start()
{
  CDDA_CONTROL = 0x00;
  cdda_next_index = 0;
  cdda_subframe = 0;
  if (cdda_fill_buffer() && cdda_fill_buffer()) {
    DEBUG_PUTS("CDDA start ok\n");
    CDDA_READPOS = 0;
    CDDA_CONTROL = 0x03;
    cdda_active = true;
  } else {
    DEBUG_PUTS("CDDA start failed!\n");
    cdda_active = false;
  }
}

void cdda_stop()
{
  CDDA_CONTROL = 0x00;
  cdda_active = false;
}

void service_cdda()
{
  if (!cdda_active)
    return;

  uint8_t p = CDDA_READPOS >> 7;
  if (p == cdda_next_index)
    return;

  if (!cdda_fill_buffer()) {
    cdda_stop();
    return;
  }

  uint8_t c = CDDA_CONTROL;
  if (c&2) {
    DEBUG_PUTS("{UR ");
    DEBUG_PUTX(centis);
    DEBUG_PUTC('}');
    CDDA_CONTROL = c;
  }
}

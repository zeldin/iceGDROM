#include <stdint.h>
#include <stdbool.h>
#include <string.h>

#include "config.h"

#include "debug.h"
#include "cdda.h"
#include "hardware.h"
#include "timer.h"
#include "imgfile.h"
#include "ide.h"
#include "divmod.h"

uint8_t cdda_subcode_q[12];

bool cdda_active = false;
uint8_t cdda_toc = 0;
static uint8_t cdda_next_index;
static uint8_t cdda_subframe;

static uint32_t cdda_start_blk, cdda_end_blk, cdda_blk, cdda_next_track;
static uint8_t cdda_repeat;

#ifdef CDDA_SUBCHANNEL_Q
static void advance_msf(uint8_t *p)
{
  if ((p[2]&0xf) == 9) {
    p[2] += 7;
    return;
  }
  if (p[2] != 0x74) {
    p[2] ++;
    return;
  }
  p[2] = 0;
  if ((p[1]&0x0f) != 9) {
    p[1] ++;
    return;
  }
  if (p[1] != 0x59) {
    p[1] += 7;
    return;
  }
  p[1] = 0;
  if ((p[0]&0x0f) != 9) {
    p[0] ++;
    return;
  }
  p[0] += 7;
}

static uint32_t tobcd(uint32_t v)
{
  struct divmod_result divmod10 = divmod(v, 10);
  return (divmod10.quot << 4) | divmod10.rem;
}

static void set_msf(uint8_t *p, uint32_t blk)
{
  struct divmod_result divmod4500 = divmod(blk, 4500);
  p[0] = tobcd(divmod4500.quot);
  struct divmod_result divmod75 = divmod(divmod4500.rem, 75);
  p[1] = tobcd(divmod75.quot);
  p[2] = tobcd(divmod75.rem);
}
#endif

static void setup_subchannel_q()
{
#ifdef CDDA_SUBCHANNEL_Q
  cdda_subcode_q[1] = 0xaa;
  cdda_subcode_q[2] = 0x01;
  set_msf(&cdda_subcode_q[3], 0);
  set_msf(&cdda_subcode_q[7], cdda_blk);
#endif

  uint8_t tr;
  uint8_t emph = 0;
  const struct toc *t = (cdda_toc? &toc[1] : &toc[0]);
  const struct tocentry *e = &t->lead_out;
  {
      union { uint32_t fad; uint8_t b[4]; } u;
      u.b[0] = e->fad[2];
      u.b[1] = e->fad[1];
      u.b[2] = e->fad[0];
      u.b[3] = 0;
      cdda_next_track = u.fad;
  }
  e = &t->entry[0];
  for (tr=1; tr<100; tr++, e++)
    if (e->ctrl_adr != 0xff) {
      union { uint32_t fad; uint8_t b[4]; } u;
      u.b[0] = e->fad[2];
      u.b[1] = e->fad[1];
      u.b[2] = e->fad[0];
      u.b[3] = 0;
      if (u.fad > cdda_blk) {
	cdda_next_track = u.fad;
	break;
      }
#ifdef CDDA_SUBCHANNEL_Q
      cdda_subcode_q[1] = tobcd(tr);
      set_msf(&cdda_subcode_q[3], cdda_blk - u.fad);
#endif
      emph = e->ctrl_adr & 0x10;
    }
  if (emph)
    PORTB |= _BV(EMPH_BIT);
  else
    PORTB &= ~_BV(EMPH_BIT);
}

static bool cdda_fill_buffer()
{
  if (!imgfile_read_next_sector_cdda(cdda_next_index))
    return false;

  CDDA_LIMIT = (cdda_next_index << 7)|0x7f;

  cdda_next_index ^= 1;

  if ((cdda_subframe += (512/16)) >= (2352/16)) {
    cdda_subframe -= (2352/16);
    /* Advance sector # */
#ifdef CDDA_SUBCHANNEL_Q
    advance_msf(&cdda_subcode_q[3]);
    advance_msf(&cdda_subcode_q[7]);
#endif
    cdda_blk++;
    if (cdda_blk == cdda_next_track) {
      setup_subchannel_q();
    }
    if (cdda_blk == cdda_end_blk) {
      if (cdda_repeat) {
	if (cdda_repeat < 15)
	  --cdda_repeat;
	cdda_blk = cdda_start_blk;
	setup_subchannel_q();
	if (imgfile_seek_cdda(cdda_blk))
	  return true;
      }
      return false;
    }
  }

  return true;
}

void cdda_start(uint32_t start_blk, uint32_t end_blk, uint8_t repeat)
{
  CDDA_CONTROL = 0x00;
  cdda_blk = cdda_start_blk = start_blk;
  cdda_end_blk = end_blk;
  cdda_repeat = repeat;
  setup_subchannel_q();
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
  memset(cdda_subcode_q, 0, sizeof(cdda_subcode_q));
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
    set_secnr();
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

uint8_t cdda_get_status()
{
  return (cdda_active? 0x11 : 0x00);
}

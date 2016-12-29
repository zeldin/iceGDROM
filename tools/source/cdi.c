#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>

#include "msg.h"
#include "track.h"
#include "cdi.h"

#define CDI_VERSION_2   0x80000004UL
#define CDI_VERSION_3   0x80000005UL
#define CDI_VERSION_3_5 0x80000006UL

static uint32_t get_le32(const uint8_t *p)
{
  return (((uint32_t)p[3])<<24)|(((uint32_t)p[2])<<16)|(((uint32_t)p[1])<<8)|p[0];
}

static uint16_t get_le16(const uint8_t *p)
{
  return (((uint16_t)p[1])<<8)|p[0];
}

static bool cdi_parse_track(FILE *f, const char *fn, uint32_t version,
			    uint8_t track, uint8_t session, uint32_t *offs)
{
  static const uint8_t mark[10] = { 0, 0, 1, 0, 0, 0, ~0, ~0, ~0, ~0 };
  uint8_t buf[89];
  int i;
  if (fread(buf, 1, 4, f) != 4) {
    msg_perror(fn);
    return false;
  }
  if (get_le32(buf) != 0 &&
      fseek(f, 8, SEEK_CUR) < 0) {
    msg_perror(fn);
    return false;
  }
  if (fread(buf, 1, 25, f) != 25) {
    msg_perror(fn);
    return false;
  }
  if (memcmp(buf, mark, 10) || memcmp(buf+10, mark, 10)) {
    msg_error("Track start mark not identified\n");
    return false;
  }
  if (buf[24] > 0 &&
      fseek(f, buf[24], SEEK_CUR) < 0) {
    msg_perror(fn);
    return false;
  }
  if (fread(buf, 1, 23, f) != 23) {
    msg_perror(fn);
    return false;
  }
  if (get_le32(buf+19) == 0x80000000UL &&
      fseek(f, 8, SEEK_CUR) < 0) {
    msg_perror(fn);
    return false;
  }
  if (fread(buf, 1, 89, f) != 89) {
    msg_perror(fn);
    return false;
  }

  struct track *t = track_create();
  if (!t)
    return false;
  t->track_nr = track;
  t->session_nr = session - 1;
  t->track_ctl = buf[60];
  t->start_sector = get_le32(buf+32)+150;

  uint32_t pregap = get_le32(buf+2);
  uint32_t length = get_le32(buf+6);
  uint32_t tot_length = get_le32(buf+36);

  uint32_t secsize;
  switch (buf[56]) {
  case 0: secsize = 2048; break;
  case 1: secsize = 2336; break;
  case 2: secsize = 2352; break;
  default:
    msg_error("Unknown sector size encountered\n");
    return false;
  }

  enum track_type type;
  switch (buf[16]) {
  case 0:
    if (secsize != 2352) {
      msg_error("Invalid sector size for audio track\n");
      return false;
    }
    type = TRACK_RAW_2352;
    break;
  case 1:
    if (secsize != 2048) {
      msg_error("Invalid sector size for mode 1 track\n");
      return false;
    }
    type = TRACK_MODE_1_2048;
    break;
  case 2:
    if (secsize == 2336)
      type = TRACK_MODE_2_2336;
    else if (secsize == 2048)
      type = TRACK_XA_FORM_1_2048;
    else {
      msg_error("Invalid sector size for mode 2 track\n");
      return false;
    }
    break;
  default:
    msg_error("Invalid track mode\n");
    return false;
  }

  if (!track_data_from_file(t, type, secsize, f,
			    *offs + pregap * secsize,
			    length))
    return false;

  *offs += tot_length * secsize;

  if (version != CDI_VERSION_2) {
    if (fread(buf, 1, 9, f) != 9) {
      msg_perror(fn);
      return false;
    }
    if (get_le32(buf+5) == (uint32_t)(~0UL) &&
	fseek(f, 78, SEEK_CUR) < 0) {
      msg_perror(fn);
      return false;
    }
  }

  return true;
}

static bool cdi_check_footer(FILE *f, uint32_t *verp, uint32_t *offp)
{
  uint8_t buf[8];
  uint32_t ver, off;

  if (fseek(f, -8, SEEK_END) < 0 ||
      fread(buf, 1, 8, f) != 8)
    return false;

  ver = get_le32(buf+0);
  off = get_le32(buf+4);

  if (ver != CDI_VERSION_2 &&
      ver != CDI_VERSION_3 &&
      ver != CDI_VERSION_3_5)
    return false;

  if (!off)
    return false;

  if (ver == CDI_VERSION_3_5) {
    long file_end = ftell(f);
    if (file_end < 0)
      return false;
    off = file_end - off;
  }

  if (verp)
    *verp = ver;
  if (offp)
    *offp = off;
  return true;
}

bool cdi_check_file(FILE *f)
{
  return cdi_check_footer(f, NULL, NULL);
}

bool cdi_parse_and_add_tracks(FILE *f, const char *fn)
{
  uint32_t version, hdr_off, offs = 0;
  unsigned nses, ses_no, trk_no = 1;
  uint8_t buf[2];
  if (!cdi_check_footer(f, &version, &hdr_off)) {
    msg_error("Failed to parse CDI footer\n");
    return false;
  }
  if (fseek(f, hdr_off, SEEK_SET) < 0 ||
      fread(buf, 1, 2, f) != 2) {
    msg_perror(fn);
    return false;
  }
  nses = get_le16(buf);
  if (!nses) {
    msg_error("No sessions in image\n");
    return false;
  }
  msg_info("Image has %u session(s)\n", nses);
  for (ses_no = 1; ses_no <= nses; ses_no++) {
    unsigned ntrk;
    if (fread(buf, 1, 2, f) != 2) {
      msg_perror(fn);
      return false;
    }
    ntrk = get_le16(buf);
    if (!ntrk) {
      msg_error("No tracks in session %u\n", ses_no);
      return false;
    }
    msg_info("Session %u has %u track(s)\n", ses_no, ntrk);
    do {
      if (!cdi_parse_track(f, fn, version, trk_no, ses_no, &offs))
	return false;
      trk_no++;
    } while(--ntrk);
    if (fseek(f, (version == CDI_VERSION_2? 12 : 13), SEEK_CUR) < 0) {
      msg_perror(fn);
      return false;
    }
  }

  return true;
}


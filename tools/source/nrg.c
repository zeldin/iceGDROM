#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>

#include "msg.h"
#include "track.h"
#include "nrg.h"

#define CHUNK_ID(a,b,c,d) ((((uint32_t)a)<<24)|(((uint32_t)b)<<16)|(((uint32_t)c)<<8)|d)

static uint32_t get_be32(const uint8_t *p)
{
  return (((uint32_t)p[0])<<24)|(((uint32_t)p[1])<<16)|(((uint32_t)p[2])<<8)|p[3];
}

static uint16_t get_be16(const uint8_t *p)
{
  return (((uint16_t)p[0])<<8)|p[1];
}

static uint8_t from_bcd(uint8_t n)
{
  return (n>>4)*10+(n&15);
}

static bool nrg_parse_cuex(FILE *f, const char *fn, uint32_t len)
{
  uint32_t lead_out;
  if (len < 16 || (len&15)) {
    msg_error("Invalid CUEX length\n");
    return false;
  }
  len >>= 3;
  for (uint32_t n = 0; n < len; n++) {
    uint8_t entry[8];
    if (fread(entry, 1, 8, f) != 8) {
      msg_perror(fn);
      return false;
    }
    if (n == 0) {
      if (entry[1] != 0x00 || entry[2] != 0x00) {
	msg_error("Incorrect header of CUEX chunk\n");
	return false;
      }
    } else if (n == len-1) {
      if (entry[1] != 0xaa || entry[2] != 0x01) {
	msg_error("Incorrect footer of CUEX chunk\n");
	return false;
      }
    }
    uint32_t lba = get_be32(entry+4)+150;
    if (entry[2] == 1) {
      if (entry[1] == 0xaa)
	lead_out = lba;
      else {
	struct track *t = track_create();
	if (!t)
	  return false;
	t->track_nr = from_bcd(entry[1]);
	t->track_ctl = entry[0]>>4;
	t->start_sector = lba;
      }
    }
  }
  return true;
}

static bool nrg_parse_daox(FILE *f, const char *fn, uint32_t len)
{
  if (len < 22 || (len-22)%42) {
    msg_error("Invalid DAOX length\n");
    return false;
  }
  uint8_t entry[42];
  if (fread(entry, 1, 22, f) != 22) {
    msg_perror(fn);
    return false;
  }
  len -= 22;
  len /= 42;
  uint8_t first_track = entry[20], last_track = entry[21];
  if (last_track < first_track || len != last_track-first_track+1) {
    msg_error("Invalid length of DAOX chunk\n");
    return false;
  }
  struct track *t = track_get_first();
  while (len > 0) {
    if (fread(entry, 1, 42, f) != 42) {
      msg_perror(fn);
      return false;
    }
    while (t != NULL && t->track_nr != first_track)
      t = t->next;
    if (t == NULL) {
      msg_error("Found DAOX entry for non-existring track %u\n",
		(unsigned)first_track);
      return false;
    }
    uint16_t secsize = get_be16(entry+12);
    uint16_t mode = get_be16(entry+14);
    uint16_t unk = get_be16(entry+16);
    uint32_t i0_hi = get_be32(entry+18);
    uint32_t i0_lo = get_be32(entry+22);
    uint32_t i1_hi = get_be32(entry+26);
    uint32_t i1_lo = get_be32(entry+30);
    uint32_t e_hi = get_be32(entry+34);
    uint32_t e_lo = get_be32(entry+38);
    if (i0_hi || i1_hi || e_hi) {
      msg_error("Unexpected 64-bit value in DAOX\n");
      return false;
    }
    if (!secsize || e_lo < i1_lo) {
      msg_error("Invalid sector size / data length\n");
      return false;
    }
    enum track_type type;
    switch (mode) {
    case 0x0500:
    case 0x0600:
    case 0x0700:
    case 0x0f00:
    case 0x1000:
    case 0x1100:
      type = TRACK_RAW_2352;
      break;
    case 0x0000:
      type = TRACK_MODE_1_2048;
      break;
    case 0x0300:
      type = TRACK_MODE_2_2336;
      break;
    default:
      msg_error("Unknown track mode 0x%04x\n", (unsigned)mode);
      return false;
    }
    if (!track_data_from_file(t, type, secsize, f, i1_lo, (e_lo-i1_lo)/secsize))
      return false;
    first_track++;
    --len;
  }
  return true;
}

static int nrg_parse_sinf(FILE *f, const char *fn, uint32_t len, uint8_t nr, int prev)
{
  if (len != 4) {
    msg_error("Invalid SINF length\n");
    return -1;
  }
  uint8_t entry[4];
  if (fread(entry, 1, 4, f) != 4) {
    msg_perror(fn);
    return -1;
  }
  uint32_t sinf = get_be32(entry);
  uint32_t cnt = sinf;
  TRACK_FOREACH(t) {
    if (!cnt)
      break;
    if (prev)
      --prev;
    else {
      t->session_nr = nr;
      --cnt;
    }
  }
  if (cnt || prev) {
    msg_error("SINF specifies unexisting track(s)\n");
    return -1;
  }
  return (int)sinf;
}

static bool nrg_check_footer(FILE *f, uint32_t *offp)
{
  uint8_t buf[12];
  if (fseek(f, -12, SEEK_END) < 0 ||
      fread(buf, 1, 12, f) != 12)
    return false;

  if (memcmp(buf, "NER5", 4))
    return false;

  uint32_t off_hi = get_be32(buf+4);
  uint32_t off_lo = get_be32(buf+8);
  if (off_hi || !off_lo)
    return false;
  if (offp)
    *offp = off_lo;
  return true;
}

bool nrg_check_file(FILE *f)
{
  return nrg_check_footer(f, NULL);
}

bool nrg_parse_and_add_tracks(FILE *f, const char *fn)
{
  uint32_t hdr_off;
  if (!nrg_check_footer(f, &hdr_off)) {
    msg_error("Failed to parse NRG5 footer\n");
    return false;
  }
  long file_end = ftell(f);
  if (file_end < 0) {
    msg_perror(fn);
    return false;
  }
  uint8_t sess_nr = 0;
  int prev_sess_tracks = 0;
  for (;;) {
    uint8_t chdr[8];
    if (fseek(f, hdr_off, SEEK_SET) < 0 ||
	fread(chdr, 1, 8, f) != 8) {
      msg_perror(fn);
      return false;
    }
    if (!memcmp(chdr, "END!\0\0\0\0", 8))
      break;
    uint32_t chunklen = get_be32(chdr+4);
    hdr_off += 8;
    if (hdr_off + chunklen >= (uint32_t)file_end) {
      msg_error("Corrupt NRG5 footer\n");
      return false;
    }
    switch(get_be32(chdr)) {
    case CHUNK_ID('C','U','E','S'):
    case CHUNK_ID('D','A','O','I'):
      msg_error("CUES/DAOI chunk not supported");
      return false;
    case CHUNK_ID('C','U','E','X'):
      if (!nrg_parse_cuex(f, fn, chunklen))
	return false;
      break;
    case CHUNK_ID('D','A','O','X'):
      if (!nrg_parse_daox(f, fn, chunklen))
	return false;
      break;
    case CHUNK_ID('S','I','N','F'):
      {
	int sess_tracks = nrg_parse_sinf(f, fn, chunklen, sess_nr, prev_sess_tracks);
	if (sess_tracks < 0)
	  return false;
	prev_sess_tracks += sess_tracks;
	sess_nr++;
      }
      break;
    case CHUNK_ID('E','T','N','F'):
    case CHUNK_ID('E','T','N','2'):
    case CHUNK_ID('M','T','Y','P'):
      break;
    case CHUNK_ID('E','N','D','!'):
      msg_error("Broken END! chunk found\n");
      return false;
    }
    hdr_off += chunklen;
  }
  return true;
}

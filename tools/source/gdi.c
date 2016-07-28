#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <ctype.h>

#include "msg.h"
#include "track.h"
#include "gdi.h"

bool gdi_check_file(FILE *f)
{
  char buf[3];
  if (fread(buf, 1, sizeof(buf), f) != sizeof(buf))
    return false;
  return (isdigit(buf[0]) &&
	  (isspace(buf[1]) ||
	   (isdigit(buf[1]) && isspace(buf[2]))));
}

bool gdi_parse_and_add_tracks(FILE *f, const char *fn)
{
  unsigned num_tracks;
  const char *slash = strrchr(fn, '/');
  unsigned dirlen = (slash? slash-fn+1 : 0);
  if (1 != fscanf(f, "%u", &num_tracks)) {
    msg_error("Failed to parse GDI file (track number line)\n");
    return false;
  }
  for (unsigned i = 0; i < num_tracks; i++) {
    unsigned track_no, start, ctrl, secsize, offset;
    char fnc1, filename[dirlen+101];
    if (5 != fscanf(f, "%u %u %u %u %c",
		    &track_no, &start, &ctrl, &secsize, &fnc1)) {
      msg_error("Failed to parse GDI file (track %u)\n", i+1);
      return false;
    }
    const char *fmt;
    if (fnc1 == '"')
      fmt = "%100[^\"]\" %u";
    else {
      fmt = "%100s %u";
      ungetc(fnc1, f);
    }
    if (2 != fscanf(f, fmt, filename+dirlen, &offset)) {
      msg_error("Failed to parse GDI file (track %u)\n", i+1);
      return false;
    }
    if (dirlen)
      memcpy(filename, fn, dirlen);
    struct track *t = track_create();
    if (!t)
      return false;
    t->track_nr = track_no;
    t->track_ctl = ctrl;
    if (start >= 45000)
      t->toc_nr = 1;
    t->start_sector = start+150;
    enum track_type type;
    switch (secsize) {
    case 2048: type = TRACK_MODE_1_2048; break;
    case 2336: type = TRACK_MODE_2_2336; break;
    case 2352: type = TRACK_RAW_2352; break;
    case 2368:
    case 2448:
      /* Raw format with subchannels, use raw format and discard subchannels */
      type = TRACK_RAW_2352;
      break;
    default:
      msg_error("Unsupported sector size %u in GDI file (track %u)\n",
		secsize, i+1);
      return false;
    }
    if (!track_data_from_filename(t, type, secsize, filename, offset,
				  TRACK_SECTOR_COUNT_PROBE))
      return false;
  }
  return true;
}


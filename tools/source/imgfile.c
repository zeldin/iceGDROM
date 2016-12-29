#include <stdint.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>

#include "msg.h"
#include "track.h"
#include "nrg.h"
#include "gdi.h"
#include "cdi.h"
#include "imgfile.h"

static struct {
  const char *name;
  bool binary;
  bool (*check_file)(FILE*);
  bool (*parse_and_add_tracks)(FILE*, const char *);
} formats[] = {
  { "Nero", true, nrg_check_file, nrg_parse_and_add_tracks },
  { "DiscJuggler", true, cdi_check_file, cdi_parse_and_add_tracks },
  { "GDI", false, gdi_check_file, gdi_parse_and_add_tracks },
};

static struct imgheader imgheader;

static void set_le32(uint32_t *p, uint32_t v)
{
  union { uint32_t i; uint8_t b[4]; } u;
  u.b[0] = v&0xff;
  u.b[1] = (v>>8)&0xff;
  u.b[2] = (v>>16)&0xff;
  u.b[3] = (v>>24)&0xff;
  *p = u.i;
}

static bool imgfile_prepare(void)
{
  memset(&imgheader, 0, sizeof(imgheader));
  set_le32(&imgheader.magic, HEADER_MAGIC);
  struct track *prev_track = NULL, *first_track = track_get_first();
  if (!first_track) {
    msg_error("No tracks in image\n");
    return false;
  }
  if (first_track->toc_nr != 0) {
    msg_error("First track not in TOC 0\n");
    return false;
  }
  if (first_track->session_nr != 0) {
    msg_error("First track not in session 0\n");
    return false;
  }
  bool found_data = false;
  TRACK_FOREACH (t) {
    if (t->track_nr < 1 || t->track_nr > 99) {
      msg_error("Invalid track number\n");
      return false;
    }
    if (t->toc_nr > 1) {
      msg_error("Too many TOCs\n");
      return false;
    }
    if (t->session_nr >= MAX_SESSIONS-1) {
      msg_error("Too many sessions\n");
      return false;
    }
    if (t->toc_nr >= imgheader.num_tocs)
      imgheader.num_tocs = t->toc_nr+1;
    if (t->session_nr >= imgheader.num_sessions)
      imgheader.num_sessions = t->session_nr+1;
    if (prev_track) {
      if (t->toc_nr != prev_track->toc_nr && t->toc_nr != prev_track->toc_nr+1) {
	msg_error("Invalid TOC sequence\n");
	return false;
      }
      if (t->session_nr != prev_track->session_nr && t->session_nr != prev_track->session_nr+1) {
	msg_error("Invalid session sequence\n");
	return false;
      }
      if (t->start_sector < prev_track->start_sector) {
	msg_error("FAD goes backwards!\n");
	return false;
      }
      if (prev_track->data_count > t->start_sector - prev_track->start_sector) {
	prev_track->data_count = t->start_sector - prev_track->start_sector;
	msg_warning("Truncating track %u to %u sectors\n",
		    (unsigned)prev_track->track_nr,
		    (unsigned)prev_track->data_count);
      }
    }
    if (prev_track && t->track_ctl == prev_track->track_ctl &&
	t->start_sector == prev_track->start_sector+prev_track->data_count) {
      t->region_nr = prev_track->region_nr;
    } else {
      t->region_nr = imgheader.num_regions;
      if (++imgheader.num_regions > MAX_REGIONS) {
	msg_error("Too many regions\n");
	return false;
      }
    }
    if (prev_track == NULL || prev_track->session_nr != t->session_nr) {
      imgheader.sessions[t->session_nr+1][0] = t->session_nr+1;
      imgheader.sessions[t->session_nr+1][1] = (t->start_sector>>16)&0xff;
      imgheader.sessions[t->session_nr+1][2] = (t->start_sector>>8)&0xff;
      imgheader.sessions[t->session_nr+1][3] = t->start_sector&0xff;
    }
    if(t->track_ctl & 4)
      found_data = true;
    msg_progress_register_nr(t->track_nr, t->data_count);
    prev_track = t;
  }
  imgheader.sessions[0][0] = imgheader.num_sessions;
  if (prev_track) {
    imgheader.sessions[0][1] = ((prev_track->start_sector+prev_track->data_count)>>16)&0xff;
    imgheader.sessions[0][2] = ((prev_track->start_sector+prev_track->data_count)>>8)&0xff;
    imgheader.sessions[0][3] = (prev_track->start_sector+prev_track->data_count)&0xff;
  }
  if (imgheader.num_tocs > 1)
    imgheader.disk_type = 0x80;
  else if(imgheader.num_sessions > 1)
    imgheader.disk_type = 0x20;
  else if(found_data)
    imgheader.disk_type = 0x10;
  else
    imgheader.disk_type = 0x00;
  imgheader.num_sessions++;
  uint32_t data_offs = 1+imgheader.num_tocs, data_sectors = 0;
  prev_track = NULL;
  TRACK_FOREACH (t) {
    if (prev_track == NULL || t->region_nr != prev_track->region_nr) {
      data_offs += (data_sectors*2352+511)>>9;
      data_sectors = 0;
      uint32_t sat = t->start_sector;
      sat |= ((uint32_t)t->track_ctl) << 24;
      if (t->toc_nr > 0)
	sat |= ((uint32_t)1)<<31;
      set_le32(&imgheader.regions[t->region_nr].start_and_type, sat);
      set_le32(&imgheader.regions[t->region_nr].fileoffs, data_offs);
    }
    data_sectors += t->data_count;
    prev_track = t;
  }
  return true;
}

static bool imgfile_write_toc(FILE *f, uint8_t tnr)
{
  bool first_track = true;
  struct toc toc;
  uint8_t pad[512-sizeof(toc)];
  memset(&toc, 0xff, sizeof(toc));
  memset(pad, 0, sizeof(pad));
  toc.first_track.pad[0] = 0;
  toc.first_track.pad[1] = 0;
  toc.last_track.pad[0] = 0;
  toc.last_track.pad[1] = 0;
  TRACK_FOREACH (t)
    if (t->toc_nr == tnr) {
      toc.entry[t->track_nr-1].ctrl_adr = (t->track_ctl << 4) | 1;
      toc.entry[t->track_nr-1].fad[0] = (t->start_sector>>16)&0xff;
      toc.entry[t->track_nr-1].fad[1] = (t->start_sector>>8)&0xff;
      toc.entry[t->track_nr-1].fad[2] = t->start_sector&0xff;
      if (first_track) {
	toc.first_track.ctrl_adr = toc.entry[t->track_nr-1].ctrl_adr;
	toc.first_track.track_nr = t->track_nr;
	first_track = false;
      }
      toc.last_track.ctrl_adr = toc.entry[t->track_nr-1].ctrl_adr;
      toc.last_track.track_nr = t->track_nr;
      toc.lead_out.ctrl_adr = toc.entry[t->track_nr-1].ctrl_adr;
      toc.lead_out.fad[0] = ((t->start_sector+t->data_count)>>16)&0xff;
      toc.lead_out.fad[1] = ((t->start_sector+t->data_count)>>8)&0xff;
      toc.lead_out.fad[2] = (t->start_sector+t->data_count)&0xff;
    }
  if (first_track) {
    msg_error("No tracks in TOC %u\n", (unsigned)tnr);
    return false;
  }
  if (fwrite(&toc, 1, sizeof(toc), f) != sizeof(toc) ||
      fwrite(&pad, 1, sizeof(pad), f) != sizeof(pad)) {
    msg_error("Failed to write TOC\n");
    return false;
  }
  return true;
}

static bool pad_region(FILE *f)
{
  uint8_t pad[512];
  memset(pad, 0, sizeof(pad));
  long pos = ftell(f);
  if (pos < 0) {
    msg_perror("ftell");
    return false;
  }
  if (pos & 511) {
    int cnt = 512 - (pos & 511);
    if (fwrite(&pad, 1, cnt, f) != cnt) {
      msg_error("Failed to write region pad\n");
      return false;
    }
  }
  return true;
}

static bool imgfile_convert(FILE *f)
{
  uint8_t pad[512-sizeof(imgheader)];
  memset(pad, 0, sizeof(pad));
  if (fwrite(&imgheader, 1, sizeof(imgheader), f) != sizeof(imgheader) ||
      fwrite(&pad, 1, sizeof(pad), f) != sizeof(pad)) {
    msg_error("Failed to write image header\n");
    return false;
  }
  for (uint8_t toc = 0; toc < imgheader.num_tocs; toc++) {
    if (!imgfile_write_toc(f, toc))
      return false;
  }
  TRACK_FOREACH (t) {
    if (!track_convert(t, f))
      return false;
    if (!t->next || t->next->region_nr != t->region_nr)
      if (!pad_region(f))
	return false;
  }
  msg_info("Conversion complete\n");
  return true;
}

static bool imgfile_create(const char *filename_out)
{
  FILE *f = fopen(filename_out, "wb");
  if (!f) {
    msg_perror(filename_out);
    return false;
  }
  bool r = imgfile_convert(f);
  fclose(f);
  return r;
}

bool imgfile_create_from_source(const char *filename_in, const char *filename_out)
{
  unsigned fmt;
  FILE *f;
  for (fmt = 0; fmt < sizeof(formats)/sizeof(formats[0]); fmt ++) {
    if (!(f = fopen(filename_in, (formats[fmt].binary? "rb" : "r")))) {
      msg_perror(filename_in);
      return false;
    }
    if (formats[fmt].check_file(f)) {
      rewind(f);
      msg_info("Input appears to be a %s file\n", formats[fmt].name);
      bool r = formats[fmt].parse_and_add_tracks(f, filename_in);
      if (r)
	r = imgfile_prepare();
      if (r)
	r = imgfile_create(filename_out);
      track_delete_all();
      fclose(f);
      return r;
    }
    fclose(f);
  }
  msg_error("Unrecognized input file \"%s\"\n", filename_in);
  return false;
}

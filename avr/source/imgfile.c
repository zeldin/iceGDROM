#include <stdint.h>
#include <stdbool.h>

#include "config.h"

#include "imgfile.h"
#include "fatfs.h"
#include "hardware.h"
#include "debug.h"
#include "cdda.h"

struct imgheader imgheader;
struct toc toc[2];

static struct fatfs_handle read_handle;
static struct fatfs_handle cdda_handle;

uint8_t imgfile_data_offs;
uint8_t imgfile_data_len;
static uint8_t imgfile_skip_before, imgfile_skip_after;
static uint16_t imgfile_sector_size, imgfile_sector_completed;
static bool imgfile_need_to_read;

bool imgfile_init()
{
  if (!fatfs_read_header(&imgheader, sizeof(imgheader), 0) ||
      imgheader.magic != HEADER_MAGIC ||
      imgheader.num_tocs < 1 || imgheader.num_tocs > 2)
    return false;

  uint8_t i;
  for (i=0; i<imgheader.num_tocs; i++) {
    if (!fatfs_read_header(&toc[i], sizeof(toc[i]), i+1))
      return false;
  }

  return true;
}

bool imgfile_read_next_sector()
{
  if (!imgfile_sector_completed) {
    if (imgfile_skip_before > (uint8_t)~imgfile_data_offs) {
      if (imgfile_need_to_read)
	fatfs_read_next_sector(&read_handle, 0);
      imgfile_need_to_read = true;
    }
    imgfile_data_offs += imgfile_skip_before;
  }
  if (imgfile_need_to_read) {
    if (!fatfs_read_next_sector(&read_handle, &IDE_DATA_BUFFER[0]))
      return false;
    imgfile_need_to_read = false;
  }
  if (((uint8_t)~imgfile_data_offs) < (imgfile_sector_size - imgfile_sector_completed)) {
    imgfile_data_len = ((uint8_t)~imgfile_data_offs)+1;
  } else {
    imgfile_data_len = imgfile_sector_size - imgfile_sector_completed;
  }
  return true;
}

bool imgfile_sector_complete()
{
  imgfile_sector_completed += (imgfile_data_len? imgfile_data_len : 512/2);
  imgfile_data_offs += imgfile_data_len;
  if (!imgfile_data_offs)
    imgfile_need_to_read = true;
  if (imgfile_sector_completed >= imgfile_sector_size) {
    imgfile_sector_completed = 0;
    if (imgfile_skip_after > (uint8_t)~imgfile_data_offs) {
      if (imgfile_need_to_read)
	fatfs_read_next_sector(&read_handle, 0);
      imgfile_need_to_read = true;
    }
    imgfile_data_offs += imgfile_skip_after;
    return true;
  }
  return false;
}

bool imgfile_read_next_sector_cdda(uint8_t idx)
{
  return fatfs_read_next_sector(&cdda_handle, &CDDA_DATA_BUFFER[(idx? 512:0)]);
}

static bool imgfile_seek_internal(uint32_t sec, uint8_t mode, bool data)
{
  uint8_t i;
  uint32_t blk;
  uint8_t rmode = 0xff;
  uint8_t secoffs = 0;
  for(i=0; i<imgheader.num_regions; i++) {
    uint32_t start = imgheader.regions[i].start_and_type & 0xffffff;
    if (sec >= start) {
      rmode = imgheader.regions[i].start_and_type >> 24;
      blk = (sec-start)*147;
      secoffs = (((uint8_t)blk)&31)<<3;
      blk = (blk>>5)+imgheader.regions[i].fileoffs;
    } else {
      if (!i)
	return false;
      break;
    }
  }
  uint8_t skip_before = 0, skip_after = 0;
  switch((mode>>1)&7) {
  case 0:
    if(!(mode & 0x10)) {
      /* Data select with "Any type"; check for data track and assume
	 mode2/form1 for XA and mode1 otherwise */
      if (!(rmode & 4))
	return false;
      if (imgheader.disk_type == 0x20) {
	skip_after = 280/2;
	if (!(mode & 0x40))
	  skip_before = 8/2;
      } else
	skip_after = 288/2;
    }
    break;
  case 1:
    if (rmode & 4)
      return false;
    break;
  case 2:
    skip_after = 288/2;
  case 3:
    /* FALLTHRU */
    if (!(rmode & 4) || imgheader.disk_type == 0x20)
      return false;
    break;
  case 4:
    skip_after = 276/2;
    /* FALLTHRU */
  case 5:
    skip_after += 4/2;
    if (!(rmode & 4) || imgheader.disk_type != 0x20)
      return false;
    if (!(mode & 0x40))
      skip_before = 8/2;
    break;
  case 6:
    break;
  default:
    return false;
  }
  if (mode & 0x10) {
    skip_before = 0;
    skip_after = 0;
  } else if (!(mode & 0x20)) {
    return false;
  } else if (!(mode & 0x80)) {
    skip_before += 16/2;
  }
  if (data) {
    imgfile_sector_size = 2352/2;
    imgfile_sector_size -= skip_before;
    imgfile_sector_size -= skip_after;
    imgfile_data_offs = secoffs;
    imgfile_skip_before = skip_before;
    imgfile_skip_after = skip_after;
    imgfile_need_to_read = true;
    imgfile_sector_completed = 0;
  } else {
    cdda_subcode_q[0] = (rmode<<4)|1;
    cdda_toc = rmode & 0x80;
  }
  return fatfs_seek((data? &read_handle : &cdda_handle), blk);
}

bool imgfile_seek(uint32_t sec, uint8_t mode)
{
  if (!imgfile_seek_internal(sec, mode, true)) {
    DEBUG_PUTS("SEEK mode=");
    DEBUG_PUTX(mode);
    DEBUG_PUTS(" failed\n");
    return false;
  }
  return true;
}

bool imgfile_seek_cdda(uint32_t sec)
{
  return imgfile_seek_internal(sec, 0x12, false);
}


#include <stdint.h>
#include <stdbool.h>

#include "imgfile.h"
#include "fatfs.h"
#include "hardware.h"

struct imgheader imgheader;

static struct fatfs_handle read_handle;
static struct fatfs_handle cdda_handle;

bool imgfile_init()
{
  return fatfs_read_header(&imgheader, sizeof(imgheader)) &&
    imgheader.magic == HEADER_MAGIC;
}

bool imgfile_read_next_sector()
{
  return fatfs_read_next_sector(&read_handle, &IDE_DATA_BUFFER[0]);
}

bool imgfile_read_next_sector_cdda(uint8_t idx)
{
  return fatfs_read_next_sector(&cdda_handle, &CDDA_DATA_BUFFER[(idx? 512:0)]);
}

bool imgfile_read_toc(uint8_t select)
{
  return fatfs_seek(&read_handle, select+1) &&
    fatfs_read_next_sector(&read_handle, &IDE_DATA_BUFFER[0]);
}

static bool imgfile_seek_internal(uint32_t sec, uint8_t mode)
{
  uint8_t i;
  uint32_t blk;
  uint8_t rmode = 0xff;
  for(i=0; i<imgheader.num_regions; i++) {
    uint32_t start = imgheader.regions[i].start_and_type & 0xffffff;
    if (sec >= start) {
      rmode = imgheader.regions[i].start_and_type >> 24;
      blk = imgheader.regions[i].fileoffs;
      if (mode == 4)
	blk += (sec - start)<<2;
      else {
	blk += ((sec - start)*147)>>5;
      }
    } else {
      if (!i)
	return false;
      break;
    }
  }
  if (rmode != mode)
    return false;
  return fatfs_seek((mode? &read_handle : &cdda_handle), blk);
}

bool imgfile_seek(uint32_t sec)
{
  return imgfile_seek_internal(sec, 4);
}

bool imgfile_seek_cdda(uint32_t sec)
{
  return imgfile_seek_internal(sec, 0);
}


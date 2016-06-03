#include <stdint.h>
#include <stdbool.h>

#include "imgfile.h"
#include "fatfs.h"
#include "hardware.h"

struct imgheader imgheader;

static struct fatfs_handle read_handle;

bool imgfile_init()
{
  return fatfs_read_header(&imgheader, sizeof(imgheader)) &&
    imgheader.magic == HEADER_MAGIC;
}

bool imgfile_read_next_sector()
{
  return fatfs_read_next_sector(&read_handle, &IDE_DATA_BUFFER[0]);
}

bool imgfile_read_toc(uint8_t select)
{
  return fatfs_seek(&read_handle, select+1) &&
    fatfs_read_next_sector(&read_handle, &IDE_DATA_BUFFER[0]);
}

bool imgfile_seek(uint16_t sec)
{
  uint8_t i;
  uint32_t blk;
  for(i=0; i<imgheader.num_regions; i++) {
    uint32_t start = imgheader.regions[i].start_and_type & 0xffffff;
    if (sec >= start) {
      blk = ((sec - start)<<2) + imgheader.regions[i].fileoffs;
    } else {
      if (!i)
	return false;
      break;
    }
  }
  return fatfs_seek(&read_handle, blk);
}

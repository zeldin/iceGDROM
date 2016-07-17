#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include "sdcard.h"
#include "fatfs.h"
#include "debug.h"

static uint8_t cache[2][512];
static uint32_t cache_block_nr[2];
static uint32_t fat_start, data_start, root_dir_start;
static uint16_t root_dir_entries;
static uint8_t cluster_shift, blocks_per_cluster;
static bool fat32;
static uint32_t file_start_cluster;

#define data_block cache[0]
#define fat_block cache[1]

#define FAT_EOC   0x80000000
#define FAT_ERROR 0x40000000

char filename[11] = "DISC0000GI0";

static void reset_cache()
{
  cache_block_nr[0] = cache_block_nr[1] = ~0;
}

static bool read_block(uint32_t nr, uint8_t slot)
{
  if (nr == cache_block_nr[slot])
    return true;
  cache_block_nr[slot] = nr;
  if (sd_read_block(nr, cache[slot]))
    return true;
  cache_block_nr[slot] = ~0;
  return false;
}

static bool read_cluster_block(uint32_t nr, uint8_t sub)
{
  return read_block(data_start+(nr<<cluster_shift)+sub, 0);
}

static uint32_t get_fat_entry(uint32_t cluster)
{
  uint8_t n;
  if (fat32) {
    n = ((uint8_t)cluster)&0x7f;
    cluster >>= 7;
  } else {
    n = (uint8_t)cluster;
    cluster >>= 8;
  }
  if (!read_block(fat_start+cluster, 1))
    return FAT_ERROR|FAT_EOC;
  if (fat32) {
    cluster = (((uint32_t*)fat_block)[n])&0x0fffffff;
    if (cluster >= 0x0ffffff8)
      cluster |= FAT_EOC;
  } else {
    cluster = ((uint16_t*)fat_block)[n];
    if (((uint16_t)cluster) >= 0xfff8)
      cluster |= FAT_EOC;
  }
  if (cluster < 2)
    cluster |= FAT_ERROR|FAT_EOC;
  return cluster;
}

static bool check_root_block(uint32_t part_start)
{
  if (!read_block(part_start, 0))
    return false;

  if(data_block[0x1fe] != 0x55 ||
     data_block[0x1ff] != 0xaa)
    return false;

  /* Check file system type */
  if (data_block[82] != 'F' || data_block[83] != 'A' || data_block[84] != 'T')
    return false;

  /* Check required parameters */
  if (data_block[11] != 0 || data_block[12] != 2 || /* 512 bytes per sector */
      (data_block[14] == 0 && data_block[15] == 0) || /* reserved sectors > 0 */
      data_block[16] != 2) /* fat count */
    return false;

  uint8_t i = 0, n = 1;
  do {
    if (data_block[13] == n)
      break;
    i++;
    n<<=1;
  } while(n);
  if (!n)
    return false;
  cluster_shift=i;
  blocks_per_cluster = n;

  uint16_t rds = *(uint16_t*)(data_block+17); /* rootDirEntryCount */
  root_dir_entries = rds;
  rds = (rds >> 4) + ((((uint8_t)rds)&0xf)? 1:0);
  uint32_t bpf = *(uint16_t*)(data_block+22); /* sectorsPerFat16 */
  if (!(uint16_t)bpf)
    bpf = *(uint32_t*)(data_block+36); /* sectorsPerFat32 */
  uint32_t ds = *(uint16_t*)(data_block+14) + part_start;
  fat_start = ds;
  ds += bpf<<1;
  root_dir_start = ds;
  ds += rds;
  data_start = ds - (((uint16_t)2)<<i);
  uint32_t cc = *(uint16_t*)(data_block+19); /* totalSectors16 */
  if (!(uint16_t)cc)
    cc = *(uint32_t*)(data_block+32); /* totalSectors32 */
  cc -= (ds - part_start);
  cc >>= i;
  if (cc < 65525) {
    if (((uint16_t)cc) < 4085) {
      /* FAT12 not supported */
      return false;
    }
    fat32 = false;
  } else {
    fat32 = true;
    root_dir_start = *(uint32_t*)(data_block+44);
  }

  DEBUG_PUTS("Mounted fs with ");
  DEBUG_PUTX((uint8_t)(cc>>24));
  DEBUG_PUTX((uint8_t)(cc>>16));
  DEBUG_PUTX((uint8_t)(cc>>8));
  DEBUG_PUTX((uint8_t)cc);
  DEBUG_PUTS(" clusters\n");

  return true;
}

bool fatfs_mount()
{
  reset_cache();
  data_block[0x1ff] = 0;
  if (check_root_block(0))
    return true;
  /* Not a valid FAT root block at 0, check for partition table */
  if(data_block[0x1fe] != 0x55 ||
     data_block[0x1ff] != 0xaa)
    return false;
  if ((data_block[0x1be] & 0x7f) != 0)
    return false;
  uint32_t part_start = *(uint32_t*)(data_block+0x1c6);
  if (!part_start)
    return false;
  return check_root_block(part_start);
}

bool fatfs_read_rootdir()
{
  uint32_t blk = root_dir_start;
  uint16_t rde = root_dir_entries;
  uint8_t entry = 0, cnr = 0;
  const uint8_t *p;
  for (;;) {
    if (!fat32 && !rde)
      break;
    if (!entry) {
      p = data_block;
      if (fat32) {
	if (!read_cluster_block(blk, cnr++))
	  return false;
      } else {
	if (!read_block(blk++, 0))
	  return false;
      }
    }
    if (!*p)
      break;
    if (*p != 0xe5 && (p[11]&0x3f) != 0x0f) {
      DEBUG_PUTS("Entry ");
      int i;
      for(i=0; i<11; i++)
	DEBUG_PUTC(p[i]);
      DEBUG_PUTC('\n');
      if (!memcmp(p, filename, 11)) {
	DEBUG_PUTS("Found target at ");
	if (fat32) {
	  DEBUG_PUTX(p[21]);
	  DEBUG_PUTX(p[20]);
	}
	DEBUG_PUTX(p[27]);
	DEBUG_PUTX(p[26]);
	DEBUG_PUTC('\n');
	file_start_cluster = *(uint16_t *)(p+26);
	if (fat32) {
	  ((uint16_t *)&file_start_cluster)[1] = *(uint16_t *)(p+20);
	}
	return true;
      }
    }
    p += 32;
    --rde;
    if (++entry == 16) {
      entry = 0;
      if (fat32) {
	if (cnr == blocks_per_cluster) {
	  cnr = 0;
	  blk = get_fat_entry(blk);
	  if (blk & FAT_EOC)
	    break;
	}
      }
    }
  }
  return false;
}

bool fatfs_seek(struct fatfs_handle *handle, uint32_t sector_nr)
{
  handle->cluster_nr = file_start_cluster;
  handle->pos = 0;
  while((sector_nr ^ handle->pos) >= blocks_per_cluster) {
    if (handle->cluster_nr & FAT_EOC)
      break;
    handle->cluster_nr = get_fat_entry(handle->cluster_nr);
    handle->pos += blocks_per_cluster;
  }
  handle->pos = sector_nr;
  return true;
}

bool fatfs_read_next_sector(struct fatfs_handle *handle, uint8_t *buf)
{
  if (handle->cluster_nr & FAT_EOC)
    return false;
  uint8_t blk = (handle->pos&0xff)&(blocks_per_cluster-1);
  if (buf) {
    if (!sd_read_block(data_start+(handle->cluster_nr<<cluster_shift)+blk, buf))
      return false;
  }
  if (++blk == blocks_per_cluster)
    handle->cluster_nr = get_fat_entry(handle->cluster_nr);
  handle->pos++;
  return true;
}


bool fatfs_read_block(uint32_t cluster, uint16_t blk, uint8_t *buf)
{
  while(blk >= blocks_per_cluster) {
    cluster = get_fat_entry(cluster);
    if (cluster & FAT_EOC)
      return false;
    blk -= blocks_per_cluster;
  }
  return sd_read_block(data_start+(cluster<<cluster_shift)+blk, buf);
}

bool fatfs_read_header(void *buf, uint8_t size)
{
  if (!read_cluster_block(file_start_cluster, 0))
    return false;
  memcpy(buf, data_block, size);
  return true;
}

void fatfs_reset_filename()
{
  memset(filename+4, '0', 4);
}

void fatfs_next_filename()
{
  char *p = filename+8;
  while (*--p <= '9') {
    if (*p == '9') {
      *p = '0';
    } else {
      (*p)++;
      break;
    }
  }
}

#include <stdio.h>
#include <string.h>

#include "cdops.h"
#include "pseudorandom.h"

static struct TOC toc;
static unsigned int track_start;

static char bigbuf0[14*1024*1024] __attribute__((aligned(32)));
static char smallbuf[8192];

#define bigbuf ((char *)((((uint32_t)bigbuf0)&0x1fffffff)|0xa0000000))

static int select_track()
{
  unsigned char disc_status;
  if (cdops_init_drive() < 0) {
    printf("Failed to init drive%s!\n", ((cdops_disc_status()&0xf)==6? " (no disc in drive)":""));
    return 0;
  }
  disc_status = cdops_disc_status();
  if (cdops_read_toc(&toc, ((disc_status&0x80)? 1 : 0)) < 0) {
    printf("Failed to read TOC!\n");
    return 0;
  }
  unsigned i, first = TOC_TRACK(toc.first), last = TOC_TRACK(toc.last);
  if (first < 1) first = 1;
  for (i=last; i>=first; --i) {
    if (TOC_CTRL(toc.entry[i-1])&4) {
      track_start = TOC_LBA(toc.entry[i-1]);
      printf("Using track %d (in %s density region), LBA %d\n",
	     (int)i, ((disc_status&0x80)? "high" : "low"), (int)track_start);
      return 1;
    }
  }
  printf("No suitable track found\n");
  return 0;
}

static int check_bigbuf(int size)
{
  char *p = bigbuf;
  int offs = 0;
  while (size > 0) {
    int chunk = (size > sizeof(smallbuf)? sizeof(smallbuf) : size);
    pseudorandom_fill(smallbuf, chunk);
    if (memcmp(smallbuf, p, chunk)) {
      int pos;
      for(pos = 0; pos < chunk; pos++)
	if (smallbuf[pos] != p[pos]) {
	  return pos+offs;
	}
      printf("memcmp is broken?!\n");
      return offs;
    }
    p += chunk;
    size -= chunk;
    offs += chunk;
  }
  return -1;
}

static void test_dma(int size)
{
  int tot = 0, sec = track_start;
  printf("Testing %dM DMA reads...", size);
  pseudorandom_init(PSEUDORANDOM_SEED);
  while (tot < 32) {
    int sz = (tot + size > 32?  32 - tot : size);
    int r = cdops_read_sectors_dma(bigbuf, sec, sz<<9);
    if (r < 0) {
      printf(" Read failed!\n");
      return;
    }
    r = check_bigbuf(sz<<20);
    if (r >= 0) {
      int i, locoffs = r % sizeof(smallbuf);
      printf(" Bad data after %d bytes\n", (tot<<20)+r);
      printf("Expected:");
      for(i=0; i<12 && locoffs+i < sizeof(smallbuf); i++)
	printf(" %x", (unsigned)smallbuf[i+locoffs]);
      printf("\nReceived:");
      for(i=0; i<12 && locoffs+i < sizeof(smallbuf); i++)
	printf(" %x", (unsigned)bigbuf[i+r]);
      printf("\n");
      return;
    }
    sec += sz<<9;
    tot += sz;
  }
  printf("Ok\n");
}

void run_test()
{
  if (!select_track())
    return;

  test_dma(14);
  test_dma(8);
  test_dma(3);
  test_dma(1);
}

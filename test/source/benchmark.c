#include <stdio.h>

#include "cdops.h"

extern unsigned long Timer( );

static struct TOC toc;
static unsigned int track_start;

static char bigbuf[2048*1024];

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

static void test_read_performance(int dma, int size, int cnt)
{
  while(cnt--) {
    printf("Testing %dK %s read...", size, (dma? "DMA":"PIO"));
    unsigned long t0 = Timer();
    int r = (dma? cdops_read_sectors_dma(bigbuf, track_start, size>>1) :
	     cdops_read_sectors_pio(bigbuf, track_start, size>>1));
    unsigned long t1 = Timer();
    if (r < 0) {
      printf(" Read failed!\n");
      continue;
    }
    printf(" %d \xb5s\n", ((t1-t0)<<11)/100);
  }
}

void run_test()
{
  if (!select_track())
    return;

  test_read_performance(0, 16, 3);
  test_read_performance(0, 2048, 3);
  test_read_performance(1, 16, 3);
  test_read_performance(1, 2048, 3);
}

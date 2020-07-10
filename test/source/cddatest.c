#include <stdio.h>
#include <string.h>

#include "cdops.h"
#include "aica.h"

extern void clrscr(int color);
extern void usleep(unsigned int usec);
extern void printat(int x, int y, const char *fmt, ...);

static struct TOC toc;
static unsigned int track_start;

static short stereo_buffer[750*588*2];

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
    if (!(TOC_CTRL(toc.entry[i-1])&4)) {
      track_start = TOC_LBA(toc.entry[i-1]);
      printf("Using track %d (in %s density region), LBA %d\n",
	     (int)i, ((disc_status&0x80)? "high" : "low"), (int)track_start);
      return 1;
    }
  }
  printf("No suitable track found\n");
  return 0;
}

static void play_sectors_test()
{
  int i;
  printf("Playing 10 seconds using CD_PLAY...");
  if (cdops_play_cdda_sectors(track_start, track_start+750, 0) < 0) {
    printf("Failed!\n");
    return;
  }
  for(i=0; i<10; i++) {
    if ((cdops_disc_status()&0xf)!=3)
      break;
    printf("%d", i);
    usleep(1000000);
  }
  while ((cdops_disc_status()&0xf)==3)
    ;
  cdops_stop_cdda();
  printf("Done\n");
}

static void read_sectors_test()
{
  int i;
  printf("Playing 10 seconds using CD_READ...");
  if (cdops_set_audio_read_mode() < 0 ||
      cdops_read_sectors_pio((void *)stereo_buffer, track_start, 750) < 0) {
    printf("Failed!\n");
    return;
  }
  aica_play_stereo_sample(stereo_buffer, 441000);
  int oldp = -1;
  for(;;) {
    if ((cdops_disc_status()&0xf)>=6)
      break;
    int p = aica_check_sample_playback();
    if (p < 0)
      break;
    p = (441000 - p)/44100 - 1;
    if (p > oldp && p < 10)
      printf("%d", (oldp=p));
    usleep(100000);
  }
  aica_pause();
  printf("Done\n");
}

void run_cdda_test()
{
  if (!select_track())
    return;
  play_sectors_test();
  read_sectors_test();
}

void run_test()
{
  for(;;) {
    clrscr(0x1f);
    printat(0, 0, "");
    if ((cdops_disc_status()&0xf)>=6) {
      printf("Please insert an audio disc");
      while ((cdops_disc_status()&0xf)>=6)
	;
    } else {
      while((cdops_disc_status()&0xf)==0)
	;
      run_cdda_test();
      while ((cdops_disc_status()&0xf)<6)
	;
    }
  }
}

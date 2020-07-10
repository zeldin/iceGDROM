#include "soundcommon.h"
#include "aica.h"

extern void usleep(unsigned int usec);

#define SOUNDSTATUS ((volatile struct soundstatus *)(void *)(0xa0800000+SOUNDSTATUS_ADDR))

static const unsigned int arm_sound_code[] = {
#include "arm_sound_code.h"
};

static int last_soundpos;
static int samples_left;
static const short *sample_ptr;

static void *memcpy4(void *s1, const void *s2, unsigned int n)
{
  unsigned int *p1 = s1;
  const unsigned int *p2 = s2;
  n+=3;
  n>>=2;
  while(n--)
    *p1++ = *p2++;
  return s1;
}

static void *memset4(void *s, int c, unsigned int n)
{
  unsigned int *p = s;
  n+=3;
  n>>=2;
  while(n--)
    *p++ = c;
  return s;  
}

static int read_sound_int(volatile int *p)
{
  int r;
  while((*((volatile int *)(void *)0xa05f688c))&32);
  r = *p;
  return r;
}

static void write_sound_int(volatile int *p, int v)
{
  while((*((volatile int *)(void *)0xa05f688c))&32);
  *p = v;
}

static void wait_sound_command(int n)
{
  while(read_sound_int(&SOUNDSTATUS->cmdstatus)!=n)
    ;
}

static void do_sound_command(int cmd)
{
  wait_sound_command(0);
  write_sound_int(&SOUNDSTATUS->cmd, cmd);
  write_sound_int(&SOUNDSTATUS->cmdstatus, 1);
  wait_sound_command(2);
  write_sound_int(&SOUNDSTATUS->cmdstatus, 0);
  wait_sound_command(0);
}

void aica_pause()
{
  do_sound_command(MODE_PAUSE);
}

static int aica_get_sample_position()
{
  return read_sound_int(&SOUNDSTATUS->samplepos);
}

static void fill_samples(const short *samples, int cnt)
{
  int i;
  unsigned int *left = (void *)(0xa0800000 + SAMPLE_BASE_LEFT + 2*last_soundpos);
  unsigned int *right = (void *)(0xa0800000 + SAMPLE_BASE_RIGHT + 2*last_soundpos);
  samples_left -= cnt;
  last_soundpos += cnt;
  if (last_soundpos >= SAMPLE_DATA_LENGTH)
    last_soundpos -= SAMPLE_DATA_LENGTH;
  cnt >>= 1;
  if (samples)
    for (i=0; i<cnt; i++) {
      unsigned short left1 = *samples++;
      unsigned short right1 = *samples++;
      unsigned short left2 = *samples++;
      unsigned short right2 = *samples++;
      *left++ = left1 | (left2 << 16);
      *right++ = right1 | (right2 << 16);
    }
  else
    for (i=0; i<cnt; i++) {
      *left++ = 0;
      *right++ = 0;
    }
}

int aica_check_sample_playback()
{
  int delta = aica_get_sample_position() - last_soundpos;
  if (delta < 0)
    delta = SAMPLE_DATA_LENGTH - last_soundpos;
  if (delta >= 256) {
    delta &= ~255;
    if (samples_left > 0) {
      int n = (samples_left >= delta ? delta : samples_left);
      fill_samples(sample_ptr, n);
      sample_ptr += 2*n;
      delta -= n;
    }
    if (delta > 0)
      fill_samples(0, delta);
  }
  if (samples_left <= -SAMPLE_DATA_LENGTH)
    return -1;
  else if (samples_left > 0)
    return samples_left;
  else
    return 0;
}

void aica_play_stereo_sample(const short *stereo_buffer, int sample_cnt)
{
  do_sound_command(MODE_PAUSE);
  last_soundpos = 0;
  fill_samples(0, SAMPLE_DATA_LENGTH);
  sample_ptr = stereo_buffer;
  samples_left = sample_cnt;
  do_sound_command(MODE_PLAY);
}

void aica_init()
{
  *((volatile unsigned long *)(void *)0xa0702c00) |= 1;
  memset4((void*)0xa0800000, 0, 2*1024*1024);
  memcpy4((void*)0xa0800000, arm_sound_code, sizeof(arm_sound_code));
  *((volatile unsigned long *)(void *)0xa0702c00) &= ~1;
  usleep(10000);
}

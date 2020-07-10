#include "soundcommon.h"

#define AICA(n) ((volatile unsigned int *)(void*)(0x800000+(n)))
#define SOUNDSTATUS ((volatile struct soundstatus *)(void *)(SOUNDSTATUS_ADDR))

static void __gccmain() { }

void aica_reset()
{
  int i, j;
  volatile unsigned int *hwptr = AICA(0);

  *AICA(0x2800) = 0;

  /* Reset all 64 channels to a silent state */
  for(i=0; i<64; i++) {
    hwptr[0] = 0x8000;
    hwptr[5] = 0x1f;
    hwptr[1] = 0;
    hwptr[2] = 0;
    hwptr[3] = 0;
    hwptr[4] = 0;
    for(j=6; j<32; j++)
      hwptr[j] = 0;
    hwptr += 32;
  }

  /* Enable CDDA full volume, normal panning */
  *AICA(0x2040) = 0x0f0f;
  *AICA(0x2044) = 0x0f1f;

  *AICA(0x2800) = 15;
}

void init_channel(int channel, int pan, unsigned long dataptr, int len)
{
  volatile unsigned int *hwptr = AICA(channel<<7);

  /* Set sample format and buffer address */
  hwptr[0] = 0x4200 | (dataptr>>16);
  hwptr[1] = dataptr & 0xffff;
  /* Number of samples */
  hwptr[3] = len;
  /* Frequency */
  hwptr[6] = 0; /* 44100 Hz */
  /* Set volume, pan, and some other stuff */
  ((volatile unsigned char *)(hwptr+9))[4] = 0x24;
  ((volatile unsigned char *)(hwptr+9))[1] = 0xf;
  ((volatile unsigned char *)(hwptr+9))[5] = 0;
  ((volatile unsigned char *)(hwptr+9))[0] = pan;
  hwptr[4] = 0x1f;
}

int main()
{
  SOUNDSTATUS->mode = MODE_PAUSE;
  SOUNDSTATUS->samplepos = 0;

  aica_reset();

  for(;;) {

    if(SOUNDSTATUS->cmdstatus==1) {
      if (SOUNDSTATUS->cmd == MODE_PLAY) {
	/* Play */
	init_channel(0, 0x1f, SAMPLE_BASE_LEFT, SAMPLE_DATA_LENGTH);
	init_channel(1, 0x0f, SAMPLE_BASE_RIGHT, SAMPLE_DATA_LENGTH);
	SOUNDSTATUS->samplepos = 0;
	*AICA(0) |= 0xc000;
	*AICA(0x80) |= 0xc000;
	*(unsigned char *)AICA(0x280d) = 0;
	SOUNDSTATUS->mode = MODE_PLAY;
      } else {
	/* Pause */
	*AICA(0) = (*AICA(0) & ~0x4000) | 0x8000;
	*AICA(0x80) = (*AICA(0x80) & ~0x4000) | 0x8000;
	SOUNDSTATUS->samplepos = 0;
	SOUNDSTATUS->mode = MODE_PAUSE;
      }
      SOUNDSTATUS->cmdstatus = 2;
    }

    if(SOUNDSTATUS->mode == MODE_PLAY)
      SOUNDSTATUS->samplepos = *AICA(0x2814);
  }
}

struct TOC {
  unsigned int entry[99];
  unsigned int first, last;
  unsigned int leadout;
};

#define TOC_LBA(n) ((n)&0x00ffffff)
#define TOC_ADR(n) (((n)&0x0f000000)>>24)
#define TOC_CTRL(n) (((n)&0xf0000000)>>28)
#define TOC_TRACK(n) (((n)&0x00ff0000)>>16)

extern void cdops_init(void);
extern unsigned char cdops_disc_status();
extern int cdops_packet(const unsigned short *packet, unsigned short size, void *buf);
extern int cdops_init_drive();
extern int cdops_set_audio_read_mode();
extern int cdops_read_toc(struct TOC *toc, int session);
extern int cdops_read_sectors_pio(char *buf, int sec, int num);
extern int cdops_read_sectors_dma(char *buf, int sec, int num);
extern int cdops_play_cdda_sectors(int start, int stop, int reps);
extern int cdops_stop_cdda();

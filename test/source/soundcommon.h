#define MODE_PAUSE 0
#define MODE_PLAY  1

#define SOUNDSTATUS_ADDR   0x00ff80
#define SAMPLE_BASE_LEFT   0x040000
#define SAMPLE_BASE_RIGHT  0x120000

#define SAMPLE_DATA_LENGTH 32768

struct soundstatus {
  int mode;
  int cmd;
  int cmdstatus;
  int samplepos;
};

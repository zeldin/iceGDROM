
#define MAX_SESSIONS 6
#define MAX_REGIONS  8

#define HEADER_MAGIC 0xdc0001dc

struct region
{
  uint32_t start_and_type;
  uint32_t fileoffs;
};

struct imgheader
{
  uint32_t magic;
  uint8_t disk_type;
  uint8_t num_tocs;
  uint8_t num_sessions;
  uint8_t num_regions;
  uint8_t sessions[MAX_SESSIONS][4];
  struct region regions[MAX_REGIONS];
};

extern struct imgheader imgheader;

extern bool imgfile_init();
extern bool imgfile_read_next_sector();
extern bool imgfile_seek(uint16_t sec);
extern bool imgfile_read_toc(uint8_t select);


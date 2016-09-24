
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

struct tocentry
{
  uint8_t ctrl_adr;
  uint8_t fad[3];
};

struct tocindex
{
  uint8_t ctrl_adr;
  uint8_t track_nr;
  uint8_t pad[2];
};

struct toc
{
  struct tocentry entry[99];
  struct tocindex first_track;
  struct tocindex last_track;
  struct tocentry lead_out;
};

extern struct imgheader imgheader;
extern struct toc toc[2];

extern uint8_t imgfile_data_offs;
extern uint8_t imgfile_data_len;
extern bool imgfile_need_to_read;

extern bool imgfile_init();
extern bool imgfile_read_next_sector(uint8_t *ptr);
extern bool imgfile_read_next_sector_cdda(uint8_t index);
extern bool imgfile_seek(uint32_t sec, uint8_t mode);
extern bool imgfile_seek_cdda(uint32_t sec);
extern bool imgfile_sector_complete();

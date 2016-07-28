#include <stdint.h>
#include <stdbool.h>

enum track_type {
  TRACK_RAW_2352,       /* Raw 2352 byte sector image */
  TRACK_SWAP_2352,      /* Byteswapped audio */
  TRACK_MODE_1_2048,    /* Yellow Book 2048 byte data sector */
  TRACK_MODE_2_2336,    /* 2336 byte Mode 2 sectors */
  TRACK_XA_FORM_1_2048, /* 2048 byte XA Form 1 sectors */
  TRACK_XA_FORM_1_2056, /* 2048 byte XA Form 1 sectors with 8 byte subheader */
  TRACK_XA_FORM_2_2324, /* 2324 byte XA Form 2 sectors */
  TRACK_XA_FORM_2_2332, /* 2324 byte XA Form 2 sectors with 8 byte subheader */
};

struct track {
  struct track *next;
  enum track_type type;
  uint8_t track_nr;
  uint8_t track_ctl;
  uint8_t toc_nr;
  uint8_t session_nr;
  uint8_t region_nr;
  uint32_t start_sector;

  uint32_t data_count;
  uint32_t data_size;
  uint32_t data_offs;
  FILE *data_file;
  char *data_filename;
};

extern struct track *track_create(void);
extern void track_delete_all(void);
extern struct track *track_get_first(void);
extern bool track_data_from_filename(struct track *, enum track_type, uint32_t, const char *, uint32_t, uint32_t);
extern bool track_data_from_file(struct track *, enum track_type, uint32_t, FILE *, uint32_t, uint32_t);
extern bool track_convert(struct track *, FILE *);

#define TRACK_FOREACH(var) for(struct track *var = track_get_first(); var != NULL; var=var->next)

#define TRACK_SECTOR_COUNT_PROBE (UINT32_MAX)

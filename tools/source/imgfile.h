#include <stdint.h>
#include <stdbool.h>

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

extern bool imgfile_create_from_source(const char *, const char *);


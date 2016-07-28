#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <stdbool.h>
#include <errno.h>

#include "msg.h"

enum msg_level {
  MSG_INFO,
  MSG_WARNING,
  MSG_ERROR,
};

static bool progress_shown = false;
static uint32_t prog_complete = 0, prog_total = 0, prog_base = 0;
static uint8_t prog_nr = 0, prog_max_nr = 0, prog_percent = 0;

static void msg_hide_progress(void)
{
  if (!progress_shown)
    return;
  printf("\r                                                                 \r");
  fflush(stdout);
  progress_shown = false;
}

static void msg_show_progress(bool force)
{
  unsigned percent = (prog_total? 100 * prog_complete / prog_total : 100);
  if (!force && progress_shown && percent == prog_percent)
    return;
  unsigned half_percent = percent / 2;
  char bar[64];
  if (half_percent > 0)
    memset(bar, '=', half_percent);
  if (half_percent < 50)
    memset(bar+half_percent, '-', 50-half_percent);
  bar[50] = 0;
  printf("\r[%02d/%02d] [%s] %d%%", prog_nr, prog_max_nr, bar, percent);
  fflush(stdout);
  prog_percent = percent;
  progress_shown = true;
}

void msg_progress_register_nr(uint8_t nr, uint32_t total)
{
  if (nr > prog_max_nr)
    prog_max_nr = nr;
  prog_total += total;
}

void msg_progress_start_nr(uint8_t nr)
{
  prog_nr = nr;
  prog_base = prog_complete;
  msg_show_progress(true);
}

void msg_progress_update(uint32_t complete, uint32_t total)
{
  prog_complete = prog_base + complete;
  msg_show_progress(false);
}

static void msg_vmessage(enum msg_level level, const char *fmt, va_list va)
{
  if (progress_shown) {
    msg_hide_progress();
  }
  if (level >= MSG_WARNING)
    vfprintf(stderr, fmt, va);
  else
    vprintf(fmt, va);
}

void msg_error(const char *fmt, ...)
{
  va_list va;
  va_start(va, fmt);
  msg_vmessage(MSG_ERROR, fmt, va);
  va_end(va);
}

void msg_warning(const char *fmt, ...)
{
  va_list va;
  va_start(va, fmt);
  msg_vmessage(MSG_WARNING, fmt, va);
  va_end(va);
}

void msg_info(const char *fmt, ...)
{
  va_list va;
  va_start(va, fmt);
  msg_vmessage(MSG_INFO, fmt, va);
  va_end(va);
}

void msg_oom(void)
{
  msg_error("Out of memory!\n");
}

void msg_perror(const char *prefix)
{
  if (prefix && *prefix)
    msg_error("%s: %s\n", prefix, strerror(errno));
  else
    msg_error("%s\n", strerror(errno));
}


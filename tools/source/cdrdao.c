#include <stdint.h>
#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "msg.h"
#include "track.h"
#include "cdrdao.h"

/*
 The following directives are not supported:

 CATALOG
 CD_TEXT
 FIFO
 ISRC
 PREGAP

 The following directives are ignored:

 END
 INDEX
 START
 disk type (it is inferred from the track types instead)

*/

enum {
  TOK_CATALOG = 0,
  TOK_CD_DA,
  TOK_CD_I,
  TOK_CD_ROM,
  TOK_CD_ROM_XA,
  TOK_FIRST_TRACK_NO,

  TOK_CD_TEXT,
  TOK_TRACK,

  TOK_AUDIOFILE,
  TOK_COPY,
  TOK_DATAFILE,
  TOK_END,
  TOK_FIFO,
  TOK_FILE,
  TOK_FOUR_CHANNEL_AUDIO,
  TOK_INDEX,
  TOK_ISRC,
  TOK_NO,
  TOK_PREGAP,
  TOK_PRE_EMPHASIS,
  TOK_SILENCE,
  TOK_START,
  TOK_TWO_CHANNEL_AUDIO,
  TOK_ZERO,

  TOK_ARRANGER,
  TOK_AUDIO,
  TOK_COMPOSER,
  TOK_DISC_ID,
  TOK_EN,
  TOK_GENRE,
  TOK_LANGUAGE,
  TOK_LANGUAGE_MAP,
  TOK_MESSAGE,
  TOK_MODE0,
  TOK_MODE1,
  TOK_MODE1_RAW,
  TOK_MODE2,
  TOK_MODE2_FORM1,
  TOK_MODE2_FORM2,
  TOK_MODE2_FORM_MIX,
  TOK_MODE2_RAW,
  TOK_PERFORMER,
  TOK_RESERVED1,
  TOK_RESERVED2,
  TOK_RESERVED3,
  TOK_RESERVED4,
  TOK_RW,
  TOK_RW_RAW,
  TOK_SIZE_INFO,
  TOK_SONGWRITER,
  TOK_SWAP,
  TOK_TITLE,
  TOK_TOC_INFO1,
  TOK_TOC_INFO2,
  TOK_UPC_EAN,

  TOK_FIRST = TOK_CATALOG,
  TOK_LAST_VALID_TRACK_META = TOK_ZERO,
  TOK_LAST = TOK_UPC_EAN,

  TOK_NL = -1,
  TOK_EOF = -2,
  TOK_ERROR = -3,
  TOK_NOMEM = -4,
};

static const char *token_strings[] = {
  "CATALOG",
  "CD_DA",
  "CD_I",
  "CD_ROM",
  "CD_ROM_XA",
  "FIRST_TRACK_NO",
  "CD_TEXT",
  "TRACK",
  "AUDIOFILE",
  "COPY",
  "DATAFILE",
  "END",
  "FIFO",
  "FILE",
  "FOUR_CHANNEL_AUDIO",
  "INDEX",
  "ISRC",
  "NO",
  "PREGAP",
  "PRE_EMPHASIS",
  "SILENCE",
  "START",
  "TWO_CHANNEL_AUDIO",
  "ZERO",
  "ARRANGER",
  "AUDIO",
  "COMPOSER",
  "DISC_ID",
  "EN",
  "GENRE",
  "LANGUAGE",
  "LANGUAGE_MAP",
  "MESSAGE",
  "MODE0",
  "MODE1",
  "MODE1_RAW",
  "MODE2",
  "MODE2_FORM1",
  "MODE2_FORM2",
  "MODE2_FORM_MIX",
  "MODE2_RAW",
  "PERFORMER",
  "RESERVED1",
  "RESERVED2",
  "RESERVED3",
  "RESERVED4",
  "RW",
  "RW_RAW",
  "SIZE_INFO",
  "SONGWRITER",
  "SWAP",
  "TITLE",
  "TOC_INFO1",
  "TOC_INFO2",
  "UPC_EAN",
};

bool cdrdao_check_file(FILE *f)
{
  char buf[3];
  if (fread(buf, 1, sizeof(buf), f) != sizeof(buf))
    return false;
  return (buf[0] == 'C' && buf[1] == 'D' && buf[2] == '_') ||
    (buf[0] == 'C' && buf[1] == 'A' && buf[3] == 'T');
}

static int match_token(const char *t)
{
  int i;
  for (i=TOK_FIRST; i<=TOK_LAST; i++)
    if (!strcmp(t, token_strings[i]))
      return i;
  return TOK_ERROR;
}

static int skip_whitespace(FILE *f)
{
  int ch;
  do {
    ch = fgetc(f);
    if (ch == '/') {
      ch = fgetc(f);
      if (ch != '/') {
	if (ch != EOF)
	  ungetc(ch, f);
	return '/';
      }
      do {
	ch = fgetc(f);
      } while(ch != EOF && ch != '\n');
    }
  } while(ch != EOF && ch != '\n' && isspace(ch));
  return ch;
}

static int get_token(FILE *f)
{
  char tok[32];
  int l;
  int ch = skip_whitespace(f);
  if (ch == '\n')
    return TOK_NL;
  else if (ch == EOF)
    return TOK_EOF;
  else if (ch < 'A' || ch > 'Z')
    return TOK_ERROR;
  for (l = 0; l < sizeof(tok); l++) {
    if ((ch < 'A' || ch > 'Z') &&
	(ch < '0' || ch > '9') &&
	(ch != '_')) {
      tok[l] = 0;
      if (ch != EOF)
	ungetc(ch, f);
      return match_token(tok);
    }
    tok[l] = ch;
    ch = fgetc(f);
  }
  return TOK_ERROR;
}

static bool check_next(char match, FILE *f)
{
  int ch = skip_whitespace(f);
  if (ch == match)
    return true;
  if (ch != EOF)
    ungetc(ch, f);
  return false;
}

static int low_get_string(char **str, FILE *f, char *buf, size_t bufsz, size_t cnt)
{
  int ch = skip_whitespace(f);
  if (ch != '"') {
    if (buf)
      free(buf);
    if (ch == '\n')
      return TOK_NL;
    else if (ch == EOF)
      return TOK_EOF;
    ungetc(ch, f);
    return TOK_ERROR;
  }
  if (!buf) {
    msg_oom();
    return TOK_NOMEM;
  }
  while ((ch = fgetc(f)) != '"') {
    if (ch == EOF || (ch != ' ' && isspace(ch))) {
      free(buf);
      return TOK_ERROR;
    }
    if (cnt + 4 > bufsz) {
      char *newbuf = realloc(buf, bufsz += (bufsz >> 2));
      if (!newbuf) {
	free(buf);
	msg_oom();
	return TOK_NOMEM;
      }
      buf = newbuf;
    }
    if (ch == '\\') {
      char oct[4];
      int i;
      for (i=0; i<3; i++) {
	ch = fgetc(f);
	if (ch < '0' || ch > '9')
	  break;
	oct[i] = ch;
      }
      if (i == 3) {
	oct[3] = 0;
	buf[cnt++] = strtol(oct, NULL, 8);
      } else if (i == 0 && ch == '"') {
	buf[cnt++] = '"';
      } else {
	int j;
	if (ch == EOF) {
	  free(buf);
	  return TOK_ERROR;
	}
	buf[cnt++] = '\\';
	for (j=0; j<i; j++)
	  buf[cnt++] = oct[j];
	ungetc(ch, f);
      }
    } else {
      buf[cnt++] = ch;
    }
  }
  buf[cnt] = 0;
  *str = buf;
  return 0;
}

static int get_string(char **str, FILE *f)
{
  return low_get_string(str, f, malloc(32), 32, 0);
}

static int get_filename(char **str, FILE *f, const char *prefix, unsigned pfxlen)
{
  char *buf = malloc(pfxlen + 32);
  if (buf && prefix && pfxlen)
    memcpy(buf, prefix, pfxlen);
  return low_get_string(str, f, buf, pfxlen + 32, pfxlen);
}

int get_uint32(uint32_t *ret, FILE *f)
{
  uint32_t n;
  int ch = skip_whitespace(f);
  if (ch == '\n')
    return TOK_NL;
  else if (ch == EOF)
    return TOK_EOF;
  else if (ch < '0' || ch > '9')
    return TOK_ERROR;
  n = ch - '0';
  while ((ch = fgetc(f)) >= '0') {
    if (ch > '9')
      break;
    if (n > 0x19999999UL)
      return TOK_ERROR;
    n *= 10;
    if (n > 0xffffffffUL - (ch - '0'))
      return TOK_ERROR;
    n += (ch - '0');
  }
  if (ch != EOF)
    ungetc(ch, f);
  *ret = n;
  return 0;
}

int get_msf(uint32_t *ret, FILE *f)
{
  uint32_t m, s, fr;
  int tok;
  if ((tok = get_uint32(&m, f)) < 0)
    return tok;
  if (!check_next(':', f) ||
      get_uint32(&s, f) < 0 ||
      !check_next(':', f) ||
      get_uint32(&fr, f) < 0)
    return TOK_ERROR;
  *ret = m * 4500 + s * 75 + fr;
  return 0;
}

int get_msf_or_cnt(uint32_t *ret, FILE *f, uint32_t sectorcnt)
{
  uint32_t m, s, fr;
  int tok;
  if ((tok = get_uint32(&m, f)) < 0)
    return tok;
  if (check_next(':', f)) {
    if (get_uint32(&s, f) < 0 ||
	!check_next(':', f) ||
	get_uint32(&fr, f) < 0)
      return TOK_ERROR;
    *ret = (m * 4500 + s * 75 + fr) * sectorcnt;
  } else {
    *ret = m;
  }
  return 0;
}

bool cdrdao_parse_and_add_tracks(FILE *f, const char *fn)
{
  int line = 1;
  uint32_t trackno = 1;
  struct track *t = NULL;
  enum track_type ttype = TRACK_RAW_2352;
  uint32_t filesecsize = 2352;
  const char *slash = strrchr(fn, '/');
  unsigned dirlen = (slash? slash-fn+1 : 0);
  for (;;) {
    int tok = get_token(f);
    if (tok == TOK_NL) {
      line ++;
      continue;
    } else if (tok == TOK_EOF)
      break;
    else if (tok < 0) {
      fprintf(stderr, "Syntax error in TOC file line %d\n", line);
      return false;
    }

    if (tok == TOK_TRACK) {
      uint32_t start_sector = (t? t->start_sector + t->data_count : 150);
      t = track_create();
      if (!t)
	return false;
      if (trackno >= 100) {
	fprintf(stderr, "Track number too large on TOC file line %d\n", line);
	return false;
      }
      t->track_nr = trackno ++;
      t->start_sector = start_sector;
      switch ((tok = get_token(f))) {
      case TOK_AUDIO:
	ttype = TRACK_SWAP_2352;
	filesecsize = 2352;
	break;
      case TOK_MODE1_RAW:
      case TOK_MODE2_RAW:
	ttype = TRACK_RAW_2352;
	filesecsize = 2352;
	break;
      case TOK_MODE0:
	ttype = TRACK_MODE_0_2336;
	filesecsize = 2336;
	break;
      case TOK_MODE1:
	ttype = TRACK_MODE_1_2048;
	filesecsize = 2048;
	break;
      case TOK_MODE2:
      case TOK_MODE2_FORM_MIX:
	ttype = TRACK_MODE_2_2336;
	filesecsize = 2336;
	break;
      case TOK_MODE2_FORM1:
	ttype = TRACK_XA_FORM_1_2048;
	filesecsize = 2048;
	break;
      case TOK_MODE2_FORM2:
	ttype = TRACK_XA_FORM_2_2324;
	filesecsize = 2324;
	break;
      default:
	fprintf(stderr, "Syntax error in TOC file line %d\n", line);
	return false;
      }
      t->track_ctl = (tok == TOK_AUDIO? 0 : 4);
      tok = get_token(f);
      if (tok == TOK_RW || tok == TOK_RW_RAW) {
	if (filesecsize != 2352) {
	  fprintf(stderr, "Subchannel data not supported for non-raw tracks in TOC file line %d\n", line);
	  return false;
	}
	filesecsize += 96;
	tok = get_token(f);
      }
      if (tok == TOK_NL)
	line ++;
      else if (tok == TOK_EOF)
	break;
      else {
	fprintf(stderr, "Syntax error in TOC file line %d\n", line);
	return false;
      }
    } else if (t == NULL) {
      if (tok > TOK_CD_TEXT) {
	if (tok > TOK_LAST_VALID_TRACK_META)
	  fprintf(stderr, "Unexpected token %s on TOC file line %d\n",
		  token_strings[tok], line);
	else
	  fprintf(stderr, "Unexpected %s before first TRACK on TOC file line %d\n",
		  token_strings[tok], line);
	return false;
      }
      switch(tok) {
      case TOK_CD_DA:
      case TOK_CD_I:
      case TOK_CD_ROM:
      case TOK_CD_ROM_XA:
	/* Ignored, disk type is inferred from tracks */
	break;
      case TOK_FIRST_TRACK_NO:
	if (get_uint32(&trackno, f) < 0)
	  tok = TOK_ERROR;
	else if (trackno < 1 || trackno > 99) {
	  fprintf(stderr, "Illegal first track number on TOC file line %d\n", line);
	  return false;
	}
	break;
      default:
	fprintf(stderr, "Unimplemented global directive %s on TOC file line %d\n",
		token_strings[tok], line);
	return false;
      }
      if (tok >= 0)
	  tok = get_token(f);
      if (tok == TOK_NL)
	line ++;
      else if (tok == TOK_EOF)
	break;
      else {
	fprintf(stderr, "Syntax error in TOC file line %d\n", line);
	return false;
      }
    } else {
      if (tok < TOK_CD_TEXT) {
	fprintf(stderr, "Unexpected %s after first TRACK on TOC file line %d\n",
		token_strings[tok], line);
	return false;
      } else if (tok > TOK_LAST_VALID_TRACK_META) {
	fprintf(stderr, "Unexpected token %s on TOC file line %d\n",
		token_strings[tok], line);
	return false;
      } else switch(tok) {
      case TOK_NO:
	tok = get_token(f);
	switch (tok) {
	case TOK_COPY:
	  t->track_ctl &= ~2;
	  break;
	case TOK_PRE_EMPHASIS:
	  t->track_ctl &= ~1;
	  break;
	default:
	  tok = TOK_ERROR;
	}
	break;
      case TOK_COPY:
	t->track_ctl |= 2;
	break;
      case TOK_PRE_EMPHASIS:
	t->track_ctl |= 1;
	break;
      case TOK_TWO_CHANNEL_AUDIO:
	t->track_ctl &= ~0xc;
	break;
      case TOK_FOUR_CHANNEL_AUDIO:
	t->track_ctl &= ~0x4;
	t->track_ctl |= 0x8;
	break;
      case TOK_ZERO:
	{
	  uint32_t bytes, zsecsize = filesecsize;
	  int ch = skip_whitespace(f);
	  if (ch == EOF) {
	    tok = TOK_ERROR;
	    break;
	  }
	  ungetc(ch, f);
	  if (ch >= 'A' && ch <= 'Z') {
	    tok = get_token(f);
	    if (tok < 0)
	      tok = TOK_ERROR;
	    else switch(tok) {
	    case TOK_AUDIO:
	    case TOK_MODE1_RAW:
	    case TOK_MODE2_RAW:
	      zsecsize = 2352;
	      break;
	    case TOK_MODE0:
	    case TOK_MODE2:
	    case TOK_MODE2_FORM_MIX:
	      zsecsize = 2336;
	      break;
	    case TOK_MODE1:
	    case TOK_MODE2_FORM1:
	      zsecsize = 2048;
	      break;
	    case TOK_MODE2_FORM2:
	      zsecsize = 2324;
	      break;
	    case TOK_RW:
	    case TOK_RW_RAW:
	      if (zsecsize < 2352) {
		fprintf(stderr, "Subchannel data not supported for non-raw tracks in TOC file line %d\n", line);
		return false;
	      }
	      zsecsize = 2352 + 96;
	      break;
	    default:
	      tok = TOK_ERROR;
	      break;
	    }
	    if (tok < 0)
	      break;
	    if (tok != TOK_RW && tok != TOK_RW_RAW) {
	      ch = skip_whitespace(f);
	      if (ch == EOF) {
		tok = TOK_ERROR;
		break;
	      }
	      ungetc(ch, f);
	      if (ch >= 'A' && ch <= 'Z') {
		tok = get_token(f);
		if (tok == TOK_RW || tok == TOK_RW_RAW) {
		  if (zsecsize != 2352) {
		    fprintf(stderr, "Subchannel data not supported for non-raw tracks in TOC file line %d\n", line);
		    return false;
		  }
		  zsecsize = 2352 + 96;
		} else {
		  tok = TOK_ERROR;
		  break;
		}
	      }
	    }
	  }
	  if (get_msf_or_cnt(&bytes, f, zsecsize) < 0)
	    tok = TOK_ERROR;
	  else if (zsecsize < 2352) {
	    fprintf(stderr, "ZERO only supported for raw tracks, TOC file line %d\n", line);
	    return false;
	  } else if (t->data_filename) {
	    fprintf(stderr, "ZERO not supported after data file, TOC file line %d\n", line);
	    return false;
	  } else
	    t->start_sector += bytes / zsecsize;
	  break;
	}
      case TOK_SILENCE:
	{
	  uint32_t samples;
	  if (get_msf_or_cnt(&samples, f, 588) < 0)
	    tok = TOK_ERROR;
	  else if (t->track_ctl & 4) {
	    fprintf(stderr, "SILENCE only supported for audio tracks, TOC file line %d\n", line);
	    return false;
	  } else if (t->data_filename) {
	    fprintf(stderr, "SILENCE not supported after data file, TOC file line %d\n", line);
	    return false;
	  } else
	    t->start_sector += samples / 588;
	  break;
	}
      case TOK_DATAFILE:
	{
	  char *filename;
	  uint32_t offs = 0;
	  uint32_t len = 0;
	  if ((tok = get_filename(&filename, f, fn, dirlen)) < 0) {
	    if (tok == TOK_NOMEM)
	      return false;
	    tok = TOK_ERROR;
	    break;
	  }
	  if (check_next('#', f)) {
	    if (get_uint32(&offs, f) < 0) {
	      tok = TOK_ERROR;
	      free(filename);
	      break;
	    }
	  }
	  tok = get_msf_or_cnt(&len, f, filesecsize);
	  if (tok != TOK_ERROR &&
	      !track_data_from_filename(t, ttype, filesecsize, filename, offs, (tok < 0? TRACK_SECTOR_COUNT_PROBE : len / filesecsize))) {
	    free(filename);
	    return false;
	  }
	  free(filename);
	  break;
	}
      case TOK_FILE:
      case TOK_AUDIOFILE:
	{
	  char *filename;
	  uint32_t offs = 0;
	  uint32_t start = 0;
	  uint32_t len = 0;
	  if ((t->track_ctl & 4) || filesecsize != 2352) {
	    fprintf(stderr, "Audio files only allowed with audio tracks, TOC file line %d\n", line);
	    return false;
	  }
	  if ((tok = get_filename(&filename, f, fn, dirlen)) < 0) {
	    if (tok == TOK_NOMEM)
	      return false;
	    tok = TOK_ERROR;
	    break;
	  }
	  if (check_next('S', f)) {
	    ungetc('S', f);
	    if (get_token(f) != TOK_SWAP) {
	      free(filename);
	      tok = TOK_ERROR;
	      break;
	    }
	    ttype = TRACK_RAW_2352;
	  }
	  if (check_next('#', f)) {
	    if (get_uint32(&offs, f) < 0) {
	      tok = TOK_ERROR;
	      free(filename);
	      break;
	    }
	  }
	  if (get_msf_or_cnt(&start, f, 588) < 0) {
	      tok = TOK_ERROR;
	      free(filename);
	      break;
	  }
	  tok = get_msf_or_cnt(&len, f, 588);
	  if (tok != TOK_ERROR &&
	      !track_data_from_filename(t, ttype, filesecsize, filename, offs + start*4, (tok < 0? TRACK_SECTOR_COUNT_PROBE : len / 588))) {
	    free(filename);
	    return false;
	  }
	  free(filename);
	  break;
	}
      case TOK_START:
      case TOK_END:
      case TOK_INDEX:
	{
	  /* Ignored */
	  uint32_t pos;
	  tok = get_msf(&pos, f);
	  break;
	}
      default:
	fprintf(stderr, "Unimplemented track directive %s on TOC file line %d\n",
		token_strings[tok], line);
	return false;
      }
      if (tok >= 0)
	  tok = get_token(f);
      if (tok == TOK_NL)
	line ++;
      else if (tok == TOK_EOF)
	break;
      else {
	fprintf(stderr, "Syntax error in TOC file line %d\n", line);
	return false;
      }
    }
  }

  return true;
}

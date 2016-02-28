#include <stdint.h>
#include <stdbool.h>
#include <avr/interrupt.h>

#include "hardware.h"
#include "debug.h"

#define DATA_MODE_IDLE   0
#define DATA_MODE_PACKET 1
#define DATA_MODE_LAST   2

static uint8_t data_mode;

static void finish_packet(uint8_t error) __attribute__((noinline));
static void finish_packet(uint8_t error)
{
  IDE_ERROR = error;
  IDE_SECCNT = 0x03; /* I/O=1 C/D=1 REL=0 */
  IDE_STATUS = (error? 0x51 : 0x50); /* BSY=0 */
}

static void finish_packet_ok()
{
  finish_packet(0);
}

static void packet_data_last(uint16_t cnt) __attribute__((noinline));
static void packet_data_last(uint16_t cnt)
{

  IDE_SECCNT = 0x02; /* C/D=0 I/O=1 REL=0 */
  IDE_CYLHI = cnt>>8;
  IDE_CYLLO = cnt&0xff;

  data_mode = DATA_MODE_LAST;
  IDE_IOCONTROL = 0x02; /* PIO out */
  IDE_IOPOSITION = 0x00;
  IDE_IOTARGET = (cnt>>1)-1;
  IDE_STATUS = 0x58; /* DRQ = 1 BSY = 0 */
}

static const uint8_t gdrom_version[] PROGMEM = "Rev 5.07";

#ifdef AUDIOCD
static const uint8_t toc0[] PROGMEM = {
  0x01,  0x00,  0x00,  0x96,  0x01,  0x00,  0x28,  0x43,
  0x01,  0x00,  0x4c,  0x3e,  0x01,  0x00,  0x75,  0x6e,
  0x01,  0x00,  0x92,  0xf6,  0x01,  0x00,  0xc5,  0x2b,
  0x01,  0x00,  0xf8,  0x84,  0x01,  0x01,  0x4c,  0x45,
  0x01,  0x01,  0x73,  0x24,  0x01,  0x01,  0x91,  0x01,
  0x01,  0x01,  0xd2,  0x75,  0x01,  0x02,  0x03,  0xfd,
  0x01,  0x02,  0x40,  0x54,  0x01,  0x02,  0xa7,  0xf1,
  0x01,  0x02,  0xf1,  0xa9,  0x01,  0x03,  0x27,  0x3c,
  0x01,  0x03,  0x60,  0xd2,  0x01,  0x03,  0x88,  0x6c,
  0x01,  0x03,  0xb7,  0xae,  0x01,  0x03,  0xdb,  0xf8,
  0x01,  0x03,  0xf8,  0x8c
};

static const uint8_t toc1[] PROGMEM = {
  0x01, 0x01, 0x00, 0x00, 0x01, 0x15, 0x00, 0x00, 0x01, 0x04, 0x4e, 0x42
};
#else
static const uint8_t toc0[] PROGMEM = {
  0x01, 0x00, 0x00, 0x96, 0x41, 0x00, 0x2e, 0x4c
};

static const uint8_t toc1[] PROGMEM = {
  0x01, 0x01, 0x00, 0x00, 0x41, 0x02, 0x00, 0x00, 0x41, 0x02, 0x93, 0x28
};
#endif

static const uint8_t cmd71_reply[] PROGMEM = {
  0xba, 0x06, 0x0d, 0xca, 0x6a, 0x1f
};

static const uint8_t ses[3][4] PROGMEM = {
  { 0x02, 0x02, 0x93, 0x28 },
  { 0x01, 0x00, 0x00, 0x96 },
  { 0x02, 0x00, 0x2e, 0x4c },
};

static void do_read_toc()
{
  uint16_t i;
  IDE_IOCONTROL = 0x00;
  memset(IDE_DATA_BUFFER, 0xff, 408);

  memcpy_P(&IDE_DATA_BUFFER[0], toc0, sizeof(toc0));
  memcpy_P(&IDE_DATA_BUFFER[0x18c], toc1, sizeof(toc1));

#if 0
  DEBUG_PUTC('{');
  DEBUG_PUTX(IDE_CYLHI);
  DEBUG_PUTX(IDE_CYLLO);
  DEBUG_PUTS("}\n");
#endif

  packet_data_last(408);
}

static void do_req_ses()
{
  uint8_t s = IDE_DATA_BUFFER[2];
  IDE_IOCONTROL = 0x00;
  if (s > 2) {
    finish_packet(0x50);
    return;
  }
  IDE_DATA_BUFFER[0] = IDE_SECNR&0x0f;
  IDE_DATA_BUFFER[1] = 0;
  memcpy_P(&IDE_DATA_BUFFER[2], ses[s], sizeof(ses[s]));

  packet_data_last(6);
}

static void do_req_mode()
{
  uint8_t addr = IDE_DATA_BUFFER[2];
  uint8_t len = IDE_DATA_BUFFER[4];
  IDE_IOCONTROL = 0x00;
  if (addr == 18 && len == 8) {
    memcpy_P(&IDE_DATA_BUFFER[0], gdrom_version, sizeof(gdrom_version));
    packet_data_last(8);
  } else if(addr == 0 && len == 10) {
    memset(IDE_DATA_BUFFER, 0, 10); /* FIXME */
    packet_data_last(10);
  } else
    finish_packet(0x50);
}

static void do_set_mode()
{
  uint8_t addr = IDE_DATA_BUFFER[2];
  uint8_t len = IDE_DATA_BUFFER[4];
  if(addr == 0 && len == 10) {
    IDE_SECCNT = 0x00; /* C/D=0 I/O=0 REL=0 */
    IDE_CYLHI = 0;
    IDE_CYLLO = 10;

    data_mode = DATA_MODE_LAST; /* FIXME */
    IDE_IOCONTROL = 0x03; /* PIO in */
    IDE_IOPOSITION = 0x00;
    IDE_IOTARGET = 4;
    IDE_STATUS = 0x58; /* DRQ = 1 BSY = 0 */
  } else
    finish_packet(0x50);
}

static void do_cmd71()
{
  IDE_IOCONTROL = 0x00;
  memcpy_P(&IDE_DATA_BUFFER[0], cmd71_reply, sizeof(cmd71_reply));

  packet_data_last(sizeof(cmd71_reply));
}

static void do_req_error()
{
  uint8_t i;
  IDE_IOCONTROL = 0x00;
  memset(IDE_DATA_BUFFER, 0, 10); /* FIXME */

  packet_data_last(10);
}

static void process_packet()
{
  DEBUG_PUTS("[PKT ");
  uint8_t i;
  for (i=0; i<12; i++)
    DEBUG_PUTX(IDE_DATA_BUFFER[i]);
  DEBUG_PUTS("]\n");
  switch (IDE_DATA_BUFFER[0]) {
  case 0x71:
    do_cmd71();
    break;
  case 0x70:
  case 0: /* TEST_UNIT */
    finish_packet_ok();
    break;
  case 0x11: /* REQ_MODE */
    do_req_mode();
    break;
  case 0x12: /* SET_MODE */
    do_set_mode();
    break;
  case 0x13: /* REQ_ERROR */
    do_req_error();
    break;
  case 0x14: /* GET_TOC */
    do_read_toc();
    break;
  case 0x15: /* REQ_SES */
    do_req_ses();
    break;
  case 0x30: /* CD_READ */
    if (IDE_FEATURES & 1)
      DEBUG_PUTS("[DMA READ]\n");
    else
      DEBUG_PUTS("[PIO READ]\n");
    /* Fallthru */
  default:
    finish_packet(0x04); /* Abort */
    break;
  }
}

static void reset_irq()
{
  DEBUG_PUTS("[RST]\n");
  data_mode = DATA_MODE_IDLE;
#ifdef AUDIOCD
  IDE_SECNR = 0x02;
#else
  IDE_SECNR = 0x22;
#endif
  IDE_DEVCON = 0x01; /* Negate INTRQ */
  IDE_ALT_STATUS = 0x00; /* Clear BSY */
}

static void cmd_irq()
{
  DEBUG_PUTS("[CMD ");
  DEBUG_PUTX(IDE_COMMAND);
  DEBUG_PUTC(']');
  data_mode = DATA_MODE_IDLE;
  switch (IDE_COMMAND) {
  case 0xa0:
    /* Packet */
    data_mode = DATA_MODE_PACKET;
    IDE_SECCNT = 0x01; /* C/D=1 I/O=0 REL=0 */
    IDE_IOCONTROL = 0x03; /* PIO in */
    IDE_IOPOSITION = 0x00;
    IDE_IOTARGET = 0x05; /* transfer 6 words */
    IDE_ALT_STATUS = 0x58; /* DRQ = 1 BSY = 0 */
    break;
  case 0xef:
    /* Set features */
    if (IDE_FEATURES == 0x03) {
      uint8_t mode = IDE_SECCNT;
      if ((mode & 0xf8) == 0x08) {
	DEBUG_PUTS("[PIO MODE ");
	DEBUG_PUTX(mode & 0x07);
	DEBUG_PUTS("]\n");
      } else if ((mode & 0xf8) == 0x20) {
	DEBUG_PUTS("[DMA MODE ");
	DEBUG_PUTX(mode & 0x07);
	DEBUG_PUTS("]\n");
      }
      IDE_ERROR = 0x00;
      IDE_STATUS = 0x50;
      break;
    }
    /* Fallthrough to abort */
  default:
    DEBUG_PUTC('\n');
    /* Unknown command */
    IDE_ERROR = 0x04;  /* Error = Abort */
    IDE_STATUS = 0x51; /* Error, not busy, assert INTRQ */
    break;
  }
}

static void data_irq()
{
  IDE_ALT_STATUS = 0xd0; /* BSY=1, DRQ=0 */
  IDE_IOCONTROL = 0x00;
  switch(data_mode) {
  case DATA_MODE_PACKET:
    data_mode = DATA_MODE_IDLE;
    IDE_IOCONTROL = 0x01;
    process_packet();
    break;
  case DATA_MODE_LAST:
    data_mode = DATA_MODE_IDLE;
    DEBUG_PUTS("[END]");
    DEBUG_PUTX(IDE_IOPOSITION);
    DEBUG_PUTC('\n');
    finish_packet_ok();
    break;
  default:
    DEBUG_PUTS("[*DATA]\n");
    IDE_ALT_STATUS = 0x50;
  }
}

ISR(INT1_vect)
{
  uint8_t devcon = IDE_DEVCON & 0x3c;
  IDE_DEVCON = devcon;
  DEBUG_PUTS("[IRQ ");
  DEBUG_PUTX(devcon);
  DEBUG_PUTC(']');
  if (devcon & 0x0c)
    reset_irq();
  else if (devcon & 0x10)
    cmd_irq();
  else if (devcon & 0x20)
    data_irq();
}


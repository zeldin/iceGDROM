#include <stdint.h>
#include <stdbool.h>
#include <avr/interrupt.h>

#include "hardware.h"
#include "debug.h"
#include "fatfs.h"
#include "imgfile.h"

#define DATA_MODE_IDLE   0
#define DATA_MODE_PACKET 1
#define DATA_MODE_LAST   2
#define DATA_MODE_CONT   3

static uint8_t data_mode;

#define SERVICE_MODE_IDLE  0
#define SERVICE_MODE_RESET 1
#define SERVICE_MODE_CMD   2
#define SERVICE_MODE_DATA  3

static uint8_t service_mode;
static uint8_t service_dma;
static uint16_t service_sectors_left;

static union {
  uint8_t cmd;
  uint8_t data[12];
  struct {
    uint8_t cmd;
    uint8_t pad1;
    uint8_t start_addr;
    uint8_t pad2;
    uint8_t alloc_len;
  } req_stat, req_mode, set_mode;
  struct {
    uint8_t cmd;
    uint8_t pad[3];
    uint8_t alloc_len;
  } req_error;
  struct {
    uint8_t cmd;
    uint8_t select;
    uint8_t pad;
    uint8_t alloc_len_hi;
    uint8_t alloc_len_lo;
  } get_toc;
  struct {
    uint8_t cmd;
    uint8_t pad1;
    uint8_t session_nr;
    uint8_t pad2;
    uint8_t alloc_len;
  } req_ses;
  struct {
    uint8_t cmd;
    uint8_t ptype;
    uint8_t start_point[3];
    uint8_t pad1;
    uint8_t reptime;
    uint8_t pad2;
    uint8_t end_point[3];
  } cd_play;
  struct {
    uint8_t cmd;
    uint8_t ptype;
    uint8_t seek_point[3];
  } cd_seek;
  struct {
    uint8_t cmd;
    uint8_t pad;
    uint8_t dir;
    uint8_t speed;
  } cd_scan;
  struct {
    uint8_t cmd;
    uint8_t flags;
    uint8_t start_addr[3];
    uint8_t pad[3];
    uint8_t transfer_length[3];
  } cd_read;
  struct {
    uint8_t cmd;
    uint8_t flags;
    uint8_t start_addr[3];
    uint8_t pad;
    uint8_t transfer_length[2];
    uint8_t next_addr[3];
  } cd_read2;
  struct {
    uint8_t cmd;
    uint8_t format;
    uint8_t pad;
    uint8_t alloc_len_hi;
    uint8_t alloc_len_lo;
  } get_scd;
} packet;

static void finish_packet(uint8_t error) __attribute__((noinline));
static void finish_packet(uint8_t error)
{
  IDE_ERROR = error;
  IDE_SECCNT = 0x03; /* I/O=1 C/D=1 REL=0 */
  IDE_STATUS = (error? 0x51 : 0x50); /* BSY=0 */
}

static void service_finish_packet(uint8_t error)
{
  cli();
  if (service_mode == SERVICE_MODE_IDLE)
    finish_packet(error);
  sei();
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

static void packet_data_dma(uint16_t cnt) __attribute__((noinline));
static void packet_data_dma(uint16_t cnt)
{

  IDE_SECCNT = 0x02; /* C/D=0 I/O=1 REL=0 */
  IDE_CYLHI = cnt>>8;
  IDE_CYLLO = cnt&0xff;

  data_mode = DATA_MODE_CONT;
  IDE_IOPOSITION = 0x00;
  IDE_IOTARGET = (cnt>>1)-1;
  IDE_IOCONTROL = 0x04; /* DMA out */
}

static void service_packet_data_last(uint16_t cnt)
{
  cli();
  if (service_mode == SERVICE_MODE_IDLE)
    packet_data_last(cnt);
  sei();
}

static void service_packet_data_cont(uint16_t cnt)
{
  cli();
  if (service_mode == SERVICE_MODE_IDLE) {
    packet_data_last(cnt);
    data_mode = DATA_MODE_CONT;
  }
  sei();
}

static void service_packet_data_dma(uint16_t cnt)
{
  cli();
  if (service_mode == SERVICE_MODE_IDLE)
    packet_data_dma(cnt);
  sei();
}

static void service_packet_data_dma_full()
{
  service_packet_data_dma(512);
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
  0x01, 0x01, 0x00, 0x00, 0x41, 0x02, 0x00, 0x00, 0x41, 0x00, 0x2f, 0x7a
};
#endif

static const uint8_t cmd71_reply[] PROGMEM = {
  0xba, 0x06, 0x0d, 0xca, 0x6a, 0x1f
};

static const uint8_t ses[3][4] PROGMEM = {
  { 0x02, 0x00, 0x2f, 0x7a },
  { 0x01, 0x00, 0x00, 0x96 },
  { 0x02, 0x00, 0x2e, 0x4c },
};

static void do_req_mode()
{
  uint8_t addr = packet.req_mode.start_addr;
  uint8_t len = packet.req_mode.alloc_len;
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
  uint8_t addr = packet.set_mode.start_addr;
  uint8_t len = packet.set_mode.alloc_len;
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
  memcpy_P(&IDE_DATA_BUFFER[0], cmd71_reply, sizeof(cmd71_reply));

  packet_data_last(sizeof(cmd71_reply));
}

static void do_req_error()
{
  uint8_t i;
  memset(IDE_DATA_BUFFER, 0, 10); /* FIXME */

  packet_data_last(10);
}

static void process_packet()
{
  memcpy(&packet, IDE_DATA_BUFFER, 12);
  IDE_IOCONTROL = 0x00;
  DEBUG_PUTS("[PKT ");
  DEBUG_PUTX(packet.cmd);
  DEBUG_PUTS("]\n");
  switch (packet.cmd) {
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
  case 0x15: /* REQ_SES */
  case 0x30: /* CD_READ */
    service_dma = (IDE_FEATURES & 1);
    service_mode = SERVICE_MODE_CMD;
    break;

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
  service_mode = SERVICE_MODE_RESET;
}

static void cmd_irq()
{
  DEBUG_PUTS("[CMD ");
  DEBUG_PUTX(IDE_COMMAND);
  DEBUG_PUTC(']');
  data_mode = DATA_MODE_IDLE;
  IDE_IOCONTROL = 0x00;
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
  case DATA_MODE_CONT:
    service_mode = SERVICE_MODE_DATA;
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

static void service_get_toc()
{
  uint16_t i;
  memset(IDE_DATA_BUFFER, 0xff, 408);

  memcpy_P(&IDE_DATA_BUFFER[0], toc0, sizeof(toc0));
  memcpy_P(&IDE_DATA_BUFFER[0x18c], toc1, sizeof(toc1));

  service_packet_data_last(408);
}

static void service_req_ses()
{
  uint8_t s = packet.req_ses.session_nr;
  if (s > 2) {
    service_finish_packet(0x50);
    return;
  }
  IDE_DATA_BUFFER[0] = IDE_SECNR&0x0f;
  IDE_DATA_BUFFER[1] = 0;
  memcpy_P(&IDE_DATA_BUFFER[2], ses[s], sizeof(ses[s]));

  service_packet_data_last(6);
}

static void service_cd_read_cont()
{
  if (service_dma) {
    DEBUG_PUTS("[DMA READ CONT][");
  } else {
    DEBUG_PUTS("[PIO READ CONT][");
  }
  if (!service_sectors_left) {
    DEBUG_PUTS("COMPLETE]\n");
    service_finish_packet(0);
    return;
  }
  if (!imgfile_read_next_sector()) {
    DEBUG_PUTS("READ ERROR]\n");
    service_finish_packet(0x04); /* Abort */
    return;
  }
  --service_sectors_left;
  IDE_IOCONTROL = 0x01;
  uint8_t i;
  for(i=0; i<16; i++)
    DEBUG_PUTX(IDE_DATA_BUFFER[i]);
  IDE_IOCONTROL = 0x00;
  DEBUG_PUTS("]\n");
  if (service_dma) {
    service_packet_data_dma_full();
  } else if(service_sectors_left) {
    service_packet_data_cont(512);
  } else {
    service_packet_data_last(512);
  }
}

static void service_cd_read()
{
  if (service_dma) {
    DEBUG_PUTS("[DMA READ ");
  } else {
    DEBUG_PUTS("[PIO READ ");
  }
  DEBUG_PUTX(packet.cd_read.start_addr[0]);
  DEBUG_PUTX(packet.cd_read.start_addr[1]);
  DEBUG_PUTX(packet.cd_read.start_addr[2]);
  DEBUG_PUTC(' ');
  DEBUG_PUTX(packet.cd_read.transfer_length[1]);
  DEBUG_PUTX(packet.cd_read.transfer_length[2]);
#if 1
  DEBUG_PUTC(' ');
  DEBUG_PUTC('{');
  DEBUG_PUTX(IDE_CYLHI);
  DEBUG_PUTX(IDE_CYLLO);
  DEBUG_PUTS("}\n");
#endif
  DEBUG_PUTC(']');
  service_sectors_left = ((packet.cd_read.transfer_length[1]<<8)|packet.cd_read.transfer_length[2])<<2;
  uint16_t blk = (packet.cd_read.start_addr[1]<<8)|packet.cd_read.start_addr[2];
  if (!imgfile_seek(blk)) {
    DEBUG_PUTS("[SEEK ERROR]\n");
    service_finish_packet(0x04); /* Abort */
    return;
  }
  service_cd_read_cont();
}

static void service_reset()
{
}

static void service_cmd()
{
  DEBUG_PUTS("[SVC ");
  DEBUG_PUTX(packet.cmd);
  DEBUG_PUTS("]\n");
  switch(packet.cmd) {
  case 0x14: /* GET_TOC */
    service_get_toc();
    break;
  case 0x15: /* REQ_SES */
    service_req_ses();
    break;
  case 0x30: /* CD_READ */
    service_cd_read();
    break;
  default:
    service_finish_packet(0x04); /* Abort */
    break;
  }
}

static void service_data()
{
  DEBUG_PUTS("[SVC ");
  DEBUG_PUTX(packet.cmd);
  DEBUG_PUTS("]\n");
  switch(packet.cmd) {
    case 0x30: /* CD_READ */
      service_cd_read_cont();
      break;
  default:
    service_finish_packet(0x04); /* Abort */
    break;
  }
}

void service_ide()
{
  uint8_t mode;
  cli();
  mode = service_mode;
  service_mode = SERVICE_MODE_IDLE;
  if (mode == SERVICE_MODE_RESET)
    IDE_ALT_STATUS = 0x00; /* Clear BSY */
  sei();
  switch (mode) {
  case SERVICE_MODE_IDLE:
    return;
  case SERVICE_MODE_RESET:
    service_reset();
    break;
  case SERVICE_MODE_CMD:
    service_cmd();
    break;
  case SERVICE_MODE_DATA:
    service_data();
    break;
  }
}

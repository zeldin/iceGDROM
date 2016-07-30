#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>

#include "config.h"

#include "hardware.h"
#include "debug.h"
#include "fatfs.h"
#include "imgfile.h"
#include "cdda.h"

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
static uint8_t disk_type = 0xff;

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

static void packet_data_last(uint8_t cnt, uint8_t offs) __attribute__((noinline));
static void packet_data_last(uint8_t cnt, uint8_t offs)
{

  IDE_SECCNT = 0x02; /* C/D=0 I/O=1 REL=0 */
  IDE_CYLHI = (cnt? (cnt>>7) : 2);
  IDE_CYLLO = (cnt<<1)&0xff;

  data_mode = DATA_MODE_LAST;
  IDE_IOCONTROL = 0x02; /* PIO out */
  IDE_IOPOSITION = offs;
  IDE_IOTARGET = cnt-1+offs;
  IDE_STATUS = 0x58; /* DRQ = 1 BSY = 0 */
}

static void packet_data_last0(uint8_t cnt)
{
  packet_data_last(cnt, 0);
}

static void packet_data_dma(uint8_t cnt, uint8_t offs) __attribute__((noinline));
static void packet_data_dma(uint8_t cnt, uint8_t offs)
{

  IDE_SECCNT = 0x02; /* C/D=0 I/O=1 REL=0 */
  IDE_CYLHI = (cnt? (cnt>>7) : 2);
  IDE_CYLLO = (cnt<<1)&0xff;

  data_mode = DATA_MODE_CONT;
  IDE_IOPOSITION = offs;
  IDE_IOTARGET = cnt-1+offs;
  IDE_IOCONTROL = 0x04; /* DMA out */
}

static void service_packet_data_last(uint8_t cnt, uint8_t offs)
{
  cli();
  if (service_mode == SERVICE_MODE_IDLE)
    packet_data_last(cnt, offs);
  sei();
}

static void service_packet_data_last0(uint8_t cnt)
{
  service_packet_data_last(cnt, 0);
}

static void service_packet_data_cont(uint8_t cnt, uint8_t offs)
{
  cli();
  if (service_mode == SERVICE_MODE_IDLE) {
    packet_data_last(cnt, offs);
    data_mode = DATA_MODE_CONT;
  }
  sei();
}

static void service_packet_data_dma(uint8_t cnt, uint8_t offs)
{
  cli();
  if (service_mode == SERVICE_MODE_IDLE)
    packet_data_dma(cnt, offs);
  sei();
}

static const uint8_t gdrom_version[] PROGMEM = "Rev 5.07";

static const uint8_t cmd71_reply[] PROGMEM = {
  0xba, 0x06, 0x0d, 0xca, 0x6a, 0x1f
};


static void do_req_mode()
{
  uint8_t addr = packet.req_mode.start_addr;
  uint8_t len = packet.req_mode.alloc_len;
  if (addr == 18 && len == 8) {
    memcpy_P(&IDE_DATA_BUFFER[0], gdrom_version, sizeof(gdrom_version));
    packet_data_last0(8/2);
  } else if(addr == 0 && len == 10) {
    memset(IDE_DATA_BUFFER, 0, 10); /* FIXME */
    packet_data_last0(10/2);
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

  packet_data_last0(sizeof(cmd71_reply)/2);
}

static void do_req_error()
{
  uint8_t i;
  memset(IDE_DATA_BUFFER, 0, 10); /* FIXME */

  packet_data_last0(10/2);
}

static void process_packet()
{
  memcpy(&packet, IDE_DATA_BUFFER, 12);
  IDE_IOCONTROL = 0x00;
#ifdef IDEDEBUG
  DEBUG_PUTS("[PKT ");
  DEBUG_PUTX(packet.cmd);
  DEBUG_PUTS("]\n");
#endif
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
  case 0x20: /* CD_PLAY */
  case 0x21: /* CD_SEEK */
  case 0x30: /* CD_READ */
  case 0x40: /* CD_SCD */
    service_dma = (IDE_FEATURES & 1);
    service_mode = SERVICE_MODE_CMD;
    break;

  default:
    finish_packet(0x04); /* Abort */
    break;
  }
}

static void set_secnr()
{
  if (disk_type == 0xff)
    IDE_SECNR = 0x06;
  else
    IDE_SECNR = disk_type | (cdda_active? 0x03 : 0x02);
}

static void reset_irq()
{
#ifdef IDEDEBUG
  DEBUG_PUTS("[RST]\n");
#endif
  data_mode = DATA_MODE_IDLE;
  set_secnr();
  IDE_DEVCON = 0x01; /* Negate INTRQ */
  service_mode = SERVICE_MODE_RESET;
}

static void cmd_irq()
{
#ifdef IDEDEBUG
  DEBUG_PUTS("[CMD ");
  DEBUG_PUTX(IDE_COMMAND);
  DEBUG_PUTC(']');
#endif
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
#ifdef IDEDEBUG
	DEBUG_PUTS("[PIO MODE ");
	DEBUG_PUTX(mode & 0x07);
	DEBUG_PUTS("]\n");
#endif
      } else if ((mode & 0xf8) == 0x20) {
#ifdef IDEDEBUG
	DEBUG_PUTS("[DMA MODE ");
	DEBUG_PUTX(mode & 0x07);
	DEBUG_PUTS("]\n");
#endif
      }
      IDE_ERROR = 0x00;
      IDE_STATUS = 0x50;
      break;
    }
    /* Fallthrough to abort */
  default:
#ifdef IDEDEBUG
    DEBUG_PUTC('\n');
#endif
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
#ifdef IDEDEBUG
    DEBUG_PUTS("[END]");
    DEBUG_PUTX(IDE_IOPOSITION);
    DEBUG_PUTC('\n');
#endif
    finish_packet_ok();
    break;
  case DATA_MODE_CONT:
    service_mode = SERVICE_MODE_DATA;
    break;
  default:
#ifdef IDEDEBUG
    DEBUG_PUTS("[*DATA]\n");
#endif
    IDE_ALT_STATUS = 0x50;
  }
}

ISR(INT1_vect)
{
  uint8_t devcon = IDE_DEVCON & 0x3c;
  IDE_DEVCON = devcon;
#ifdef IDEDEBUG
  DEBUG_PUTS("[IRQ ");
  DEBUG_PUTX(devcon);
  DEBUG_PUTC(']');
#endif
  if (devcon & 0x0c)
    reset_irq();
  else if (devcon & 0x10)
    cmd_irq();
  else if (devcon & 0x20)
    data_irq();
}

static uint32_t get_fad(const uint8_t *bytes, bool msf)
{
  if (msf) {
    uint16_t sec = bytes[0]*60+bytes[1];
    return ((uint32_t)sec)*75+bytes[2];
  } else {
    union { uint32_t fad; uint8_t b[4]; } u;
    u.b[0] = bytes[2];
    u.b[1] = bytes[1];
    u.b[2] = bytes[0];
    u.b[3] = 0;
    return u.fad;
  }
}

static void service_get_toc()
{
  uint8_t s = packet.get_toc.select;
  if (s >= imgheader.num_tocs) {
    service_finish_packet(0x50);
    return;
  }
  memcpy(IDE_DATA_BUFFER, &toc[s], 408);
  service_packet_data_last0(408/2);
}

static void service_req_ses()
{
  uint8_t s = packet.req_ses.session_nr;
  if (s >= imgheader.num_sessions) {
    service_finish_packet(0x50);
    return;
  }
  IDE_DATA_BUFFER[0] = IDE_SECNR&0x0f;
  IDE_DATA_BUFFER[1] = 0;
  memcpy(&IDE_DATA_BUFFER[2], imgheader.sessions[s], sizeof(imgheader.sessions[s]));

  service_packet_data_last0(6/2);
}

static void service_cd_read_cont()
{
#ifdef IDEDEBUG
  if (service_dma) {
    DEBUG_PUTS("[DMA READ CONT][");
  } else {
    DEBUG_PUTS("[PIO READ CONT][");
  }
#endif
  if (!service_sectors_left) {
#ifdef IDEDEBUG
    DEBUG_PUTS("COMPLETE]\n");
#endif
    service_finish_packet(0);
    return;
  }
  if (!imgfile_read_next_sector()) {
#ifdef IDEDEBUG
    DEBUG_PUTS("READ ERROR]\n");
#endif
    service_finish_packet(0x04); /* Abort */
    return;
  }
  uint8_t offs = imgfile_data_offs;
  uint8_t len = imgfile_data_len;
  if (imgfile_sector_complete())
    --service_sectors_left;
#ifdef IDEDEBUG
  IDE_IOCONTROL = 0x01;
  uint8_t i = 0;
  do {
    DEBUG_PUTX(IDE_DATA_BUFFER[((uint16_t)(i+offs))*2]);
    DEBUG_PUTX(IDE_DATA_BUFFER[((uint16_t)(i+offs))*2+1]);
  } while(((uint8_t)(++i)) != len && i<16);
  IDE_IOCONTROL = 0x00;
  DEBUG_PUTS("]\n");
#endif
  if (service_dma) {
    service_packet_data_dma(len, offs);
  } else if(service_sectors_left) {
    service_packet_data_cont(len, offs);
  } else {
    service_packet_data_last(len, offs);
  }
}

static void service_cd_read()
{
#ifdef IDEDEBUG
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
  DEBUG_PUTC(']');
#endif
  service_sectors_left = ((packet.cd_read.transfer_length[1]<<8)|packet.cd_read.transfer_length[2]);
  uint32_t blk = get_fad(packet.cd_read.start_addr, packet.cd_read.flags&1);
  if (!imgfile_seek(blk, packet.cd_read.flags)) {
#ifdef IDEDEBUG
    DEBUG_PUTS("[SEEK ERROR]\n");
#endif
    service_finish_packet(0x04); /* Abort */
    return;
  }
  service_cd_read_cont();
}

static void service_cd_playseek()
{
  bool msf;
  switch (packet.cd_play.ptype) {
  case 1: msf=false; break;
  case 2: msf=true; break;
  default:
    service_finish_packet(0x04); /* Abort */
    return;
  }
  uint32_t blk = get_fad(packet.cd_play.start_point, msf);
  uint32_t eblk = get_fad(packet.cd_play.end_point, msf);

  if (!imgfile_seek_cdda(blk)) {
#ifdef IDEDEBUG
    DEBUG_PUTS("[SEEK ERROR]\n");
#endif
    service_finish_packet(0x04); /* Abort */
    return;
  }
  if (packet.cmd == 0x20) {
    cdda_start(blk, eblk, packet.cd_play.reptime&0x0f);
  } else {
    cdda_stop();
  }
  set_secnr();
  service_finish_packet(0);
}

static void service_cd_scd()
{
  memset(IDE_DATA_BUFFER, 0, 4);
  if (packet.get_scd.format == 1 &&
      packet.get_scd.alloc_len_hi == 0 &&
      packet.get_scd.alloc_len_lo == 14) {
    IDE_DATA_BUFFER[1] = cdda_get_status();
    IDE_DATA_BUFFER[3] = 14;
    memcpy(&IDE_DATA_BUFFER[4], cdda_subcode_q, 10);
    service_packet_data_last0(14/2);
  } else if (packet.get_scd.format == 0 &&
      packet.get_scd.alloc_len_hi == 0 &&
      packet.get_scd.alloc_len_lo == 100) {
    IDE_DATA_BUFFER[1] = cdda_get_status();
    IDE_DATA_BUFFER[3] = 100;
    uint8_t i, j, *p = &IDE_DATA_BUFFER[4];
    uint16_t crc = 0;
    for (i=0; i<12; i++) {
      uint8_t sc = cdda_subcode_q[i];
      for (j=0; j<8; j++) {
	if (sc&0x80) {
	  crc ^= 0x8000;
	  *p++ = 0x7f;
	} else {
	  *p++ = 0x3f;
	}
	if (crc & 0x8000)
	  crc = (crc << 1) ^ 0x1021;
	else
	  crc <<= 1;
	sc <<= 1;
      }
      if (i == 9) {
	cdda_subcode_q[10] = (~crc)>>8;
	cdda_subcode_q[11] = ~crc;
      }
    }
    service_packet_data_last0(100/2);
  } else
    service_finish_packet(0x04); /* Abort */
}

static void service_reset()
{
  cdda_stop();
}

static void service_cmd()
{
#ifdef IDEDEBUG
  DEBUG_PUTS("[SVC ");
  DEBUG_PUTX(packet.cmd);
  DEBUG_PUTS("]\n");
#endif
  switch(packet.cmd) {
  case 0x14: /* GET_TOC */
    service_get_toc();
    break;
  case 0x15: /* REQ_SES */
    service_req_ses();
    break;
  case 0x20: /* CD_PLAY */
  case 0x21: /* CD_SEEK */
    service_cd_playseek();
    break;
  case 0x30: /* CD_READ */
    service_cd_read();
    break;
  case 0x40: /* CD_SCD */
    service_cd_scd();
    break;
  default:
    service_finish_packet(0x04); /* Abort */
    break;
  }
}

static void service_data()
{
#ifdef IDEDEBUG
  DEBUG_PUTS("[SVC ");
  DEBUG_PUTX(packet.cmd);
  DEBUG_PUTS("]\n");
#endif
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

void set_disk_type(uint8_t type)
{
  disk_type = type;
  set_secnr();
}

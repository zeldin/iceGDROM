#include <stdint.h>
#include <stdbool.h>

#include "config.h"

#include "hardware.h"
#include "debug.h"
#include "delay.h"
#include "timer.h"
#include "sdcard.h"

#define SPI_CS    PB6
#define SPI_MISO  PB3
#define SPI_MOSI  PB2
#define SPI_SCK   PB1

#define INIT_TIMEOUT_CS 200
#define READ_TIMEOUT_CS 30

static bool is_hc;

static __inline void sd_spi_enable_init()
{
  PORTB |= _BV(SPI_CS);
  DDRB |= _BV(SPI_CS)|_BV(SPI_MOSI)|_BV(SPI_SCK);
  SDCARD_CONTROL = 7;
  SDCARD_DIVIDER = 135; /* 33.9MHz/136 = 249kHz */
  PORTB |= _BV(SPI_MOSI);
}

static __inline void sd_spi_enable()
{
  SDCARD_CONTROL = 7;
  SDCARD_DIVIDER = 2; /* 33.9MHz/3 = 11.3MHz */
  PORTB |= _BV(SPI_MOSI);
}

static __inline void sd_spi_disable()
{
  PORTB &= ~_BV(SPI_MOSI);
  SDCARD_CONTROL = 0;
}

static void spi_send_byte(uint8_t b)
{
  SDCARD_DATA = b;
  loop_until_bit_is_set(SDCARD_CONTROL, 7);
}

static uint8_t spi_recv_byte()
{
  spi_send_byte(0xff);
  return SDCARD_DATA;
}

static uint8_t sd_send_byte_crc7(uint8_t b, uint8_t crc) __attribute__((noinline));
static uint8_t sd_send_byte_crc7(uint8_t b, uint8_t crc)
{
  uint8_t i;
  spi_send_byte(b);
  for(i=0; i<8; i++) {
    crc <<= 1;
    if ((b^crc) & 0x80)
      crc ^= 9;
    b <<= 1;
  }
  return crc;
}

static uint8_t sd_send_cmd_param(uint8_t cmd, uint32_t param)
{
  uint8_t crc = 0;
  uint8_t r1, cnt;

  PORTB &= ~_BV(SPI_CS);
  spi_recv_byte();
  crc = sd_send_byte_crc7(0x40|cmd, crc);
  crc = sd_send_byte_crc7(param>>24, crc);
  crc = sd_send_byte_crc7(param>>16, crc);
  crc = sd_send_byte_crc7(param>>8, crc);
  crc = sd_send_byte_crc7(param, crc);
  spi_send_byte((crc<<1)|1);

  if (cmd == 12)
    spi_send_byte(0xff);

  SDCARD_CONTROL = 31;
  r1 = spi_recv_byte();
  SDCARD_CONTROL = 7;

  return r1;
}

static uint8_t sd_send_cmd(uint8_t cmd)
{
  return sd_send_cmd_param(cmd, 0);
}

bool sd_init()
{
  uint8_t i, r1;
  bool is_sd2 = false;
  uint8_t start = centis;

  is_hc = false;

  sd_spi_enable_init();
  for (i=0; i<10; i++)
    spi_send_byte(0xff);

  do {
    r1 = sd_send_cmd(0);
    if (r1 == 1)
      break;
  } while (((uint8_t)(centis - start)) < INIT_TIMEOUT_CS);
  DEBUG_PUTS("CMD0 sent, R1=0x");
  DEBUG_PUTX(r1);
  DEBUG_PUTC('\n');
  if (r1 != 1)
    goto fail;

  r1 = sd_send_cmd_param(8, 0x1aa);
  DEBUG_PUTS("CMD8 sent, R1=0x");
  DEBUG_PUTX(r1);
  DEBUG_PUTC('\n');

  if (!(r1 & 0x04)) {
    for (i=0; i<4; i++) {
      r1 = spi_recv_byte();
    }
    DEBUG_PUTS("  Pat=0x");
    DEBUG_PUTX(r1);
    DEBUG_PUTC('\n');
    if (r1 != 0xaa)
      goto fail;

    is_sd2 = true;
    DEBUG_PUTS("Card is SD2\n");
  } else
    DEBUG_PUTS("Card is SD1\n");

  uint16_t j;
  do {
    sd_send_cmd(55);
    r1 = sd_send_cmd_param(41, (is_sd2? 0x40000000 : 0));
    if (r1 == 0)
      break;
  } while (((uint8_t)(centis - start)) < INIT_TIMEOUT_CS);
  DEBUG_PUTS("ACMD41 sent, R1=0x");
  DEBUG_PUTX(r1);
  DEBUG_PUTC('\n');
  if (r1 != 0)
    goto fail;

  if (is_sd2) {
    r1 = sd_send_cmd(58);
    DEBUG_PUTS("CMD58 sent, R1=0x");
    DEBUG_PUTX(r1);
    DEBUG_PUTC('\n');
    if (r1 != 0)
      goto fail;
    r1 = spi_recv_byte();
    DEBUG_PUTS(" OCR=0x");
    DEBUG_PUTX(r1);
    DEBUG_PUTS("...\n");
    if ((r1 & 0xc0) == 0xc0)
	is_hc = true;
    for (i=0; i<3; i++)
      spi_recv_byte();
    if (is_hc)
      DEBUG_PUTS("Card is SDHC\n");
  }

  PORTB |= _BV(SPI_CS);
  sd_spi_disable();

  return true;

 fail:
  PORTB |= _BV(SPI_CS);
  sd_spi_disable();
  DEBUG_PUTS("Init failed\n");
  return false;
}

static void __inline sd_xfer_block_sw(uint8_t *ptr)
{
  uint16_t cnt = 512;
  do {
    *ptr++ = spi_recv_byte();
  } while(--cnt);
}

static void sd_xfer_block_hw()
{
  SDCARD_CONTROL = 0x40|7;
  loop_until_bit_is_clear(SDCARD_CONTROL, 6);
}

#define ADDR_HIGH(a) ((uint8_t)(((uint32_t)(void *)(a))>>8))

static void __inline sd_xfer_block(uint8_t *ptr)
{
  if (((uint8_t)(ADDR_HIGH(ptr)&0xfc)) == ADDR_HIGH(IDE_DATA_BUFFER)) {
    IDE_IOCONTROL = ADDR_HIGH(ptr)&0x46;
    sd_xfer_block_hw();
    IDE_IOCONTROL = 0x40;
  } else if (((uint8_t)(ADDR_HIGH(ptr)&0xfc)) == ADDR_HIGH(CDDA_DATA_BUFFER)) {
    CDDA_CONTROL = (CDDA_CONTROL & ~0xe)|4|(uint8_t)((ADDR_HIGH(ptr)&2)<<2);
    sd_xfer_block_hw();
    CDDA_CONTROL &= ~0xe;
  } else {
    sd_xfer_block_sw(ptr);
  }
}

static bool sd_try_read_block(uint32_t blk, uint8_t *ptr)
{
  PORTA |= 0x80;
  if (!is_hc)
    blk <<= 9;
  sd_spi_enable();
  if (sd_send_cmd_param(17, blk)) {
    goto fail;
  }
  uint8_t r, start = centis;
  do {
    if ((r = spi_recv_byte()) != 0xff)
      break;
  } while (((uint8_t)(centis - start)) < READ_TIMEOUT_CS);
  if (r != 0xfe) {
    goto fail;
  }
  SDCARD_CRC16HI = 0;
  SDCARD_CRC16LO = 0;
  sd_xfer_block(ptr);
  uint8_t crc1_hi = SDCARD_CRC16HI;
  uint8_t crc1_lo = SDCARD_CRC16LO;
  uint8_t crc2_hi = spi_recv_byte();
  uint8_t crc2_lo = spi_recv_byte();
  if (crc2_hi != crc1_hi || crc2_lo != crc1_lo)
    goto fail;
  PORTB |= _BV(SPI_CS);
  sd_spi_disable();
  PORTA &= ~0x80;
  return true;

 fail:
  PORTB |= _BV(SPI_CS);
  sd_spi_disable();
  PORTA &= ~0x80;
  DEBUG_PUTS("Block read failed\n");
  return false;
}

bool sd_read_block(uint32_t blk, uint8_t *ptr)
{
  uint8_t tries = 0;
  do {
    if (sd_try_read_block(blk, ptr))
      return true;
  } while(++tries < 5);
  return false;
}

#include <stdint.h>
#include <stdbool.h>

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
  PORTB = _BV(SPI_CS);
  DDRB = _BV(SPI_CS)|_BV(SPI_MOSI)|_BV(SPI_SCK);
  SPSR &= ~_BV(SPI2X);
  SPCR = _BV(SPE)|_BV(MSTR)|_BV(SPR1); /* 16.93MHz/64 = 264.6kHz */
  PORTB |= _BV(SPI_MOSI);
}

static __inline void sd_spi_enable()
{
  SPSR &= ~_BV(SPI2X);
 /* SPSR |= _BV(SPI2X); */
  SPCR = _BV(SPE)|_BV(MSTR); /* 16.93MHz/4 = 4.23MHz */
  PORTB |= _BV(SPI_MOSI);
}

static __inline void sd_spi_disable()
{
  PORTB &= ~_BV(SPI_MOSI);
  SPCR = 0;
}

static void spi_send_byte(uint8_t b)
{
  (void)SPSR;
  SPDR = b;
  loop_until_bit_is_set(SPSR, SPIF);
}

static uint8_t spi_recv_byte()
{
  spi_send_byte(0xff);
  return SPDR;
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

static uint8_t sd_send_cmd_param32(uint8_t cmd, uint32_t param)
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

  SPCR &= ~_BV(SPE);
  if (!(SPCR & _BV(SPR1))) {
    /* Fast path */
    for (cnt=0; (PINB & _BV(SPI_MISO)) && cnt<32; cnt++) {
      PORTB |= _BV(SPI_SCK);
      PORTB &= ~_BV(SPI_SCK);
    }
  } else {
    /* Slow path */
    for (cnt=0; (PINB & _BV(SPI_MISO)) && cnt<32; cnt++) {
      delaycycles(24);
      PORTB |= _BV(SPI_SCK);
      delaycycles(24);
      PORTB &= ~_BV(SPI_SCK);
    }
  }
  SPCR |= _BV(SPE);
  r1 = spi_recv_byte();

  return r1;
}

static uint8_t sd_send_cmd_param16(uint8_t cmd, uint16_t param) __attribute__((noinline));
static uint8_t sd_send_cmd_param16(uint8_t cmd, uint16_t param)
{
  return sd_send_cmd_param32(cmd, param);
}

static uint8_t sd_send_cmd_param8(uint8_t cmd, uint8_t param) __attribute__((noinline));
static uint8_t sd_send_cmd_param8(uint8_t cmd, uint8_t param)
{
  return sd_send_cmd_param16(cmd, param);
}

static uint8_t sd_send_cmd(uint8_t cmd) __attribute__((noinline));
static uint8_t sd_send_cmd(uint8_t cmd)
{
  return sd_send_cmd_param8(cmd, 0);
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

  r1 = sd_send_cmd_param16(8, 0x1aa);
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
    r1 = sd_send_cmd_param32(41, (is_sd2? 0x40000000 : 0));
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

bool sd_read_block(uint32_t blk, uint8_t *ptr)
{
  if (!is_hc)
    blk <<= 9;
  sd_spi_enable();
  if (sd_send_cmd_param32(17, blk)) {
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
  uint16_t cnt = 512;
  do {
    *ptr++ = spi_recv_byte();
  } while(--cnt);
  /* Discard CRC */
  spi_recv_byte();
  spi_recv_byte();
  PORTB |= _BV(SPI_CS);
  sd_spi_disable();
  return true;

 fail:
  PORTB |= _BV(SPI_CS);
  sd_spi_disable();
  DEBUG_PUTS("Block read failed\n");
  return false;
}

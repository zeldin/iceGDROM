#include <stdint.h>

#include "hardware.h"
#include "debug.h"
#include "delay.h"

void sd_spi_enable()
{
  SPCR = _BV(SPE)|_BV(MSTR);
  SPSR |= _BV(SPI2X); /* 22.6MHz/2 = 11.3MHz */
}

void sd_spi_disable()
{
  SPCR = 0;
}

void spi_send_byte(uint8_t b)
{
  (void)SPSR;
  SPDR = b;
  loop_until_bit_is_set(SPSR, SPIF);
}

void sd_init_spi_mode()
{
  uint8_t i;
  sd_spi_enable();
  for (i=0; i<10; i++)
    spi_send_byte(0xff);
  sd_spi_disable();
}

void sd_send_cmd0()
{
  uint8_t r1;

  sd_spi_enable();

  SPI_CS |= _BV(SPI_CS_SD);

  spi_send_byte(0x40);
  spi_send_byte(0x00);
  spi_send_byte(0x00);
  spi_send_byte(0x00);
  spi_send_byte(0x00);
  spi_send_byte(0x95);

  spi_send_byte(0xff);
  r1 = SPDR;
  if (r1 == 0xff) {
    spi_send_byte(0xff);
    r1 = SPDR;
  }

  SPI_CS &= ~_BV(SPI_CS_SD);

  sd_spi_disable();

  DEBUG_PUTS("CMD0 sent, R1=0x");
  DEBUG_PUTX(r1);
  DEBUG_PUTC('\n');
}

void handle_sdcard()
{
  DEBUG_PUTS("[Card inserted]\n");

  sd_init_spi_mode();
  sd_send_cmd0();

  loop_until_bit_is_clear(SD_CD_PIN, SD_CD_BIT);
  DEBUG_PUTS("[Card extracted]\n");
}

int main()
{
  DDRA = 0xff;
  DDRB = 0x00;
  DEBUG_INIT();

  uint8_t leds = 1;

  for (;;) {
    PORTA = leds;
    delayms(250);
    delayms(250);
    if (!(leds <<= 1))
	leds++;

    if (bit_is_set(SD_CD_PIN, SD_CD_BIT))
      handle_sdcard();
  }

  return 0;
}

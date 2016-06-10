
#include <avr/io.h>

#undef UCSR0C
#define UCSR0C _SFR_IO8(0x07)

#undef UBRR0H
#define UBRR0H _SFR_IO8(0x08)

#define SD_CD_PIN PINB
#define SD_CD_BIT PIN7


#define IDE_STATUS     _MMIO_BYTE(0xe000)
#define IDE_ERROR      _MMIO_BYTE(0xe001)
#define IDE_IOCONTROL  _MMIO_BYTE(0xe002)
#define IDE_IOPOSITION _MMIO_BYTE(0xe003)
#define IDE_ALT_STATUS _MMIO_BYTE(0xe004)
#define IDE_IOTARGET   _MMIO_BYTE(0xe005)
#define IDE_DEVCON     _MMIO_BYTE(0xe006)
#define IDE_FEATURES   _MMIO_BYTE(0xe009)
#define IDE_SECCNT     _MMIO_BYTE(0xe00a)
#define IDE_SECNR      _MMIO_BYTE(0xe00b)
#define IDE_CYLLO      _MMIO_BYTE(0xe00c)
#define IDE_CYLHI      _MMIO_BYTE(0xe00d)
#define IDE_DRVHEAD    _MMIO_BYTE(0xe00e)
#define IDE_COMMAND    _MMIO_BYTE(0xe00f)

#define IDE_DATA_BUFFER  ((volatile uint8_t *)0xe200)

#define CDDA_CONTROL   _MMIO_BYTE(0xe800)
#define CDDA_READPOS   _MMIO_BYTE(0xe801)
#define CDDA_LIMIT     _MMIO_BYTE(0xe802)
#define CDDA_SCRATCHPAD _MMIO_BYTE(0xe803)

#define CDDA_DATA_BUFFER ((volatile uint8_t *)0xec00)


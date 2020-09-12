#define SD_CD_PIN PINB
#define SD_CD_BIT PIN7

#define EMPH_BIT PIN0

#ifdef __ASSEMBLER__
#define _MMIO_BYTE(addr) addr
#define _MMIO_WORD(addr) addr
#else
#define _MMIO_BYTE(addr) (*(volatile uint8_t *)(void *)(addr))
#define _MMIO_WORD(addr) (*(volatile uint32_t *)(void *)(addr))
#endif

#define PORTA          _MMIO_BYTE(0xffffff00)
#define PINA           _MMIO_BYTE(0xffffff04)
#define DDRA           _MMIO_BYTE(0xffffff08)
#define PORTB          _MMIO_BYTE(0xffffff10)
#define PINB           _MMIO_BYTE(0xffffff14)
#define DDRB           _MMIO_BYTE(0xffffff18)
#define UDR0           _MMIO_WORD(0xffffff20)
#define UCSR0          _MMIO_WORD(0xffffff24)
#define UBRR0          _MMIO_WORD(0xffffff28)
#define TCNT0          _MMIO_WORD(0xffffff30)
#define OCR0           _MMIO_WORD(0xffffff34)
#define TIFR           _MMIO_WORD(0xffffff38)
#define TIMSK          _MMIO_WORD(0xffffff3c)

#define PIN0           0
#define PIN1           1
#define PIN2           2
#define PIN3           3
#define PIN4           4
#define PIN5           5
#define PIN6           6
#define PIN7	       7

#define PB0         PIN0
#define PB1         PIN1
#define PB2         PIN2
#define PB3         PIN3
#define PB4         PIN4
#define PB5         PIN5
#define PB6         PIN6
#define PB7         PIN7

#define RXC            7
#define TXC            6
#define UDRE           5
#define FE             4
#define DOR            3

#define OCIE0          0
#define OCF0           0

#define IDE_STATUS     _MMIO_BYTE(0xfffef000)
#define IDE_ERROR      _MMIO_BYTE(0xfffef004)
#define IDE_IOCONTROL  _MMIO_BYTE(0xfffef008)
#define IDE_IOPOSITION _MMIO_BYTE(0xfffef00c)
#define IDE_ALT_STATUS _MMIO_BYTE(0xfffef010)
#define IDE_IOTARGET   _MMIO_BYTE(0xfffef014)
#define IDE_DEVCON     _MMIO_BYTE(0xfffef018)
#define IDE_FEATURES   _MMIO_BYTE(0xfffef024)
#define IDE_SECCNT     _MMIO_BYTE(0xfffef028)
#define IDE_SECNR      _MMIO_BYTE(0xfffef02c)
#define IDE_CYLLO      _MMIO_BYTE(0xfffef030)
#define IDE_CYLHI      _MMIO_BYTE(0xfffef034)
#define IDE_DRVHEAD    _MMIO_BYTE(0xfffef038)
#define IDE_COMMAND    _MMIO_BYTE(0xfffef03c)

#define IDE_DATA_BUFFER  ((uint8_t *)0xfffef400)

#define SDCARD_CONTROL _MMIO_BYTE(0xfffee400)
#define SDCARD_DATA    _MMIO_BYTE(0xfffee404)
#define SDCARD_DIVIDER _MMIO_BYTE(0xfffee408)
#define SDCARD_CRC16LO _MMIO_BYTE(0xfffee410)
#define SDCARD_CRC16HI _MMIO_BYTE(0xfffee414)

#define CDDA_CONTROL   _MMIO_BYTE(0xfffee800)
#define CDDA_READPOS   _MMIO_BYTE(0xfffee804)
#define CDDA_LIMIT     _MMIO_BYTE(0xfffee808)
#define CDDA_SCRATCHPAD _MMIO_BYTE(0xfffee80c)

#define CDDA_DATA_BUFFER ((uint8_t *)0xfffeec00)

#ifdef __ASSEMBLER__
#define _BV(bit) (1<<(bit))
#else
#define _BV(bit) (1U<<(bit))
#endif

#define bit_is_clear(reg, bit) (!((reg) & _BV(bit)))
#define bit_is_set(reg, bit) (!bit_is_clear(reg, bit))
#define loop_until_bit_is_clear(reg, bit) do { } while(!bit_is_clear(reg, bit))
#define loop_until_bit_is_set(reg, bit) do { } while(!bit_is_set(reg, bit))

#define cli() asm volatile("csrrci zero,mstatus,8" ::: "memory")
#define sei() asm volatile("csrrsi zero,mstatus,8" ::: "memory")

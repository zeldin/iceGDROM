
#include <avr/io.h>

#undef UCSR0C
#define UCSR0C _SFR_IO8(0x07)

#undef UBRR0H
#define UBRR0H _SFR_IO8(0x08)

#define SD_CD_PIN PINB
#define SD_CD_BIT PIN0


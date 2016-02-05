#include <stdint.h>
#include <avr/interrupt.h>

#include "hardware.h"
#include "timer.h"

uint8_t centis;

ISR(TIMER0_COMP_vect)
{
  centis++;
}

void timer_init()
{
  OCR0 = 220;
  TCCR0 = _BV(WGM01)|_BV(CS02)|_BV(CS01)|_BV(CS00);
  TIMSK |= _BV(OCIE0);
}

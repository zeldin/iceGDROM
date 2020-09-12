#include <stdio.h>

#include "timer.h"
#include "config.h"
#include "hardware.h"

uint8_t centis;

void timer_init()
{
  OCR0 = (CPU_FREQ / 100) - 1;
  TCNT0 = 0;
  TIMSK |= _BV(OCIE0);
}

#include <stdint.h>

void pseudorandom_init(uint32_t seed);
void pseudorandom_fill(void *ptr, uint32_t nbytes);

#define PSEUDORANDOM_SEED 0xfeedd00d


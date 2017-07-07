#include "pseudorandom.h"

void Initialize(const uint32_t  seed);
uint32_t ExtractU32();

void pseudorandom_init(uint32_t seed)
{
  Initialize(seed);
}

void pseudorandom_fill(void *ptr, uint32_t nbytes)
{
  uint8_t *p = ptr;
  uint32_t v, n = nbytes>>2;
  while(n--) {
    v = ExtractU32();
    *p++ = v;
    *p++ = v>>8;
    *p++ = v>>16;
    *p++ = v>>24;
  }
  if((nbytes&=3)) {
    v = ExtractU32();
    while(nbytes--) {
      *p++ = v;
      v >>= 8;
    }
  }
}

#ifdef STANDALONE_TOOL

#include <stdio.h>

int main()
{
  uint8_t buf[8192];
  uint32_t total = 32*1024*1024;
  pseudorandom_init(PSEUDORANDOM_SEED);
  while(total > 0) {
    uint32_t chunk = (total > sizeof(buf)? sizeof(buf) : total);
    pseudorandom_fill(buf, chunk);
    if (fwrite(buf, sizeof(uint8_t), chunk, stdout) != chunk) {
      fprintf(stderr, "Write failed!\n");
      return 1;
    }
    total -= chunk;
  }
  return 0;
}

#endif

/* Mersenne Twister (https://en.wikipedia.org/wiki/Mersenne_Twister) */

// Define MT19937 constants (32-bit RNG)
enum
{
    // Assumes W = 32 (omitting this)
    N = 624,
    M = 397,
    R = 31,
    A = 0x9908B0DF,

    F = 1812433253,

    U = 11,
    // Assumes D = 0xFFFFFFFF (omitting this)

    S = 7,
    B = 0x9D2C5680,

    T = 15,
    C = 0xEFC60000,

    L = 18,

    MASK_LOWER = (1ull << R) - 1,
    MASK_UPPER = (1ull << R)
};

static uint32_t  mt[N];
static uint16_t  index;

// Re-init with a given seed
void Initialize(const uint32_t  seed)
{
    uint32_t  i;

    mt[0] = seed;

    for ( i = 1; i < N; i++ )
    {
        mt[i] = (F * (mt[i - 1] ^ (mt[i - 1] >> 30)) + i);
    }

    index = N;
}

static void Twist()
{
    uint32_t  i, x, xA;

    for ( i = 0; i < N; i++ )
    {
        x = (mt[i] & MASK_UPPER) + (mt[(i + 1) % N] & MASK_LOWER);

        xA = x >> 1;

        if ( x & 0x1 )
            xA ^= A;

        mt[i] = mt[(i + M) % N] ^ xA;
    }

    index = 0;
}

// Obtain a 32-bit random number
uint32_t ExtractU32()
{
    uint32_t  y;
    int       i = index;

    if ( index >= N )
    {
        Twist();
        i = index;
    }

    y = mt[i];
    index = i + 1;

    y ^= (mt[i] >> U);
    y ^= (y << S) & B;
    y ^= (y << T) & C;
    y ^= (y >> L);

    return y;
}

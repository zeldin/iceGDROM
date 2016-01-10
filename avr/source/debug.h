
#ifdef NDEBUG

#define DEBUG_INIT() do{}while(0)
#define DEBUG_PUTC(c) do{(void)(c);}while(0)
#define DEBUG_PUTS(s) do{}while(0)

#else

#include <avr/pgmspace.h>

#define DEBUG_INIT() debug_init()
#define DEBUG_PUTC(c) debug_putc(c)
#define DEBUG_PUTS(s) debug_puts_P(PSTR(s))

extern int debug_init();
extern void debug_putc(char c);
extern void debug_puts_P(const char *str);

#endif


#ifdef NDEBUG

#define DEBUG_INIT() do{}while(0)
#define DEBUG_PUTC(c) do{(void)(c);}while(0)
#define DEBUG_PUTX(x) do{(void)(x);}while(0)
#define DEBUG_PUTS(s) do{}while(0)

#else

#define DEBUG_INIT() debug_init()
#define DEBUG_PUTC(c) debug_putc(c)
#define DEBUG_PUTX(x) debug_putx(x)
#define DEBUG_PUTS(s) debug_puts(s)

extern void debug_init();
extern void debug_putc(char c);
extern void debug_putx(uint8_t x);
extern void debug_puts(const char *str);

#endif

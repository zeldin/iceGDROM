#include <stdint.h>

extern void msg_progress_register_nr(uint8_t, uint32_t);
extern void msg_progress_start_nr(uint8_t);
extern void msg_progress_update(uint32_t, uint32_t);
extern void msg_error(const char *, ...);
extern void msg_warning(const char *, ...);
extern void msg_info(const char *, ...);
extern void msg_perror(const char *);
extern void msg_oom(void);

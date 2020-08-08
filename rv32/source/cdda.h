
extern void cdda_start(uint32_t start_blk, uint32_t end_blk, uint8_t repeat);
extern void cdda_stop();
extern void service_cdda();
extern uint8_t cdda_get_status();

extern bool cdda_active;
extern uint8_t cdda_toc;
extern uint8_t cdda_subcode_q[12];


struct fatfs_handle {
  uint32_t cluster_nr;
  uint32_t pos;
};
extern bool fatfs_mount();
extern bool fatfs_read_rootdir();
extern bool fatfs_seek(struct fatfs_handle *handle, uint32_t sector_nr);
extern bool fatfs_read_next_sector(struct fatfs_handle *handle, uint8_t *buf);
extern bool fatfs_read_header(void *buf, uint8_t size);
extern void fatfs_reset_filename();
extern void fatfs_next_filename();

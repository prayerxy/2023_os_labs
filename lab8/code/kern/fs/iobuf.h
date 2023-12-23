#ifndef __KERN_FS_IOBUF_H__
#define __KERN_FS_IOBUF_H__

#include <defs.h>

/*
 * iobuf is a buffer Rd/Wr status record
 */
// 传递一个Io请求
struct iobuf {
    // 缓冲区的基地址
    void *io_base;     // the base addr of buffer (used for Rd/Wr)
    // 字节偏移量  最终得到文件inode内部的blocks的偏移量 
    off_t io_offset;   // current Rd/Wr position in buffer, will have been incremented by the amount transferred
    // 缓冲区长度
    size_t io_len;     // the length of buffer  (used for Rd/Wr)
    //当前可以读写的长度
    size_t io_resid;   // current resident length need to Rd/Wr, will have been decremented by the amount transferred.
};

#define iobuf_used(iob)                         ((size_t)((iob)->io_len - (iob)->io_resid))

struct iobuf *iobuf_init(struct iobuf *iob, void *base, size_t len, off_t offset);
int iobuf_move(struct iobuf *iob, void *data, size_t len, bool m2b, size_t *copiedp);
int iobuf_move_zeros(struct iobuf *iob, size_t len, size_t *copiedp);
void iobuf_skip(struct iobuf *iob, size_t n);

#endif /* !__KERN_FS_IOBUF_H__ */


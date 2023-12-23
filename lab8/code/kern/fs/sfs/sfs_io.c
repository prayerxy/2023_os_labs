#include <defs.h>
#include <string.h>
#include <dev.h>
#include <sfs.h>
#include <iobuf.h>
#include <bitmap.h>
#include <assert.h>

//Basic block-level I/O routines

/* sfs_rwblock_nolock - Basic block-level I/O routine for Rd/Wr one disk block,
 *                      without lock protect for mutex process on Rd/Wr disk block
 * @sfs:   sfs_fs which will be process
 * @buf:   the buffer uesed for Rd/Wr
 * @blkno: the NO. of disk block
 * @write: BOOL: Read or Write
 * @check: BOOL: if check (blono < sfs super.blocks)
 */
//读:把磁盘块读到buf
//写:把buf写到磁盘块
static int
sfs_rwblock_nolock(struct sfs_fs *sfs, void *buf, uint32_t blkno, bool write, bool check) {
    assert((blkno != 0 || !check) && blkno < sfs->super.blocks);
    //io_base是buf   io_offset是blkno * SFS_BLKSIZE 磁盘开始的字节偏移量
    struct iobuf __iob, *iob = iobuf_init(&__iob, buf, SFS_BLKSIZE, blkno * SFS_BLKSIZE);
    //iob是Io封装的请求，用于sfs->dev设备  向硬盘读取要用io请求
    //dop_io->disk0_io->
                        //disk0_read_blks_nolock/disk0_write_blks_nolock
                                                                        //ide_read_secs/ide_write_secs
    return dop_io(sfs->dev, iob, write);
}

/* sfs_rwblock - Basic block-level I/O routine for Rd/Wr N disk blocks ,
 *               with lock protect for mutex process on Rd/Wr disk block
 * @sfs:   sfs_fs which will be process
 * @buf:   the buffer uesed for Rd/Wr
 * @blkno: the NO. of disk block
 * @nblks: Rd/Wr number of disk block
 * @write: BOOL: Read - 0 or Write - 1
 */
//读写多个块 nbkls是读写的块数 从blkno开始的nblks个块
static int
sfs_rwblock(struct sfs_fs *sfs, void *buf, uint32_t blkno, uint32_t nblks, bool write) {
    int ret = 0;
    lock_sfs_io(sfs);
    {
        while (nblks != 0) {
            if ((ret = sfs_rwblock_nolock(sfs, buf, blkno, write, 1)) != 0) {
                break;
            }
            blkno ++, nblks --;
            buf += SFS_BLKSIZE;
        }
    }
    unlock_sfs_io(sfs);
    return ret;
}

/* sfs_rblock - The Wrap of sfs_rwblock function for Rd N disk blocks ,
 *
 * @sfs:   sfs_fs which will be process
 * @buf:   the buffer uesed for Rd/Wr
 * @blkno: the NO. of disk block
 * @nblks: Rd/Wr number of disk block
 */
//读多个块
int
sfs_rblock(struct sfs_fs *sfs, void *buf, uint32_t blkno, uint32_t nblks) {
    return sfs_rwblock(sfs, buf, blkno, nblks, 0);
}

/* sfs_wblock - The Wrap of sfs_rwblock function for Wr N disk blocks ,
 *
 * @sfs:   sfs_fs which will be process
 * @buf:   the buffer uesed for Rd/Wr
 * @blkno: the NO. of disk block
 * @nblks: Rd/Wr number of disk block
 */
//写多个块
int
sfs_wblock(struct sfs_fs *sfs, void *buf, uint32_t blkno, uint32_t nblks) {
    return sfs_rwblock(sfs, buf, blkno, nblks, 1);
}

/* sfs_rbuf - The Basic block-level I/O routine for  Rd( non-block & non-aligned io) one disk block(using sfs->sfs_buffer)
 *            with lock protect for mutex process on Rd/Wr disk block
 * @sfs:    sfs_fs which will be process
 * @buf:    the buffer uesed for Rd
 * @len:    the length need to Rd
 * @blkno:  the NO. of disk block
 * @offset: the offset in the content of disk block
 */
//读一个块
//offset是磁盘里面的字节偏移量
int
sfs_rbuf(struct sfs_fs *sfs, void *buf, size_t len, uint32_t blkno, off_t offset) {
    assert(offset >= 0 && offset < SFS_BLKSIZE && offset + len <= SFS_BLKSIZE);
    int ret;
    lock_sfs_io(sfs);
    {
        if ((ret = sfs_rwblock_nolock(sfs, sfs->sfs_buffer, blkno, 0, 1)) == 0) {
            //实际上我们是从磁盘里面偏移offset个字节开始的
            memcpy(buf, sfs->sfs_buffer + offset, len);
        }
    }
    unlock_sfs_io(sfs);
    return ret;
}

/* sfs_wbuf - The Basic block-level I/O routine for  Wr( non-block & non-aligned io) one disk block(using sfs->sfs_buffer)
 *            with lock protect for mutex process on Rd/Wr disk block
 * @sfs:    sfs_fs which will be process
 * @buf:    the buffer uesed for Wr
 * @len:    the length need to Wr
 * @blkno:  the NO. of disk block
 * @offset: the offset in the content of disk block
 */
int
sfs_wbuf(struct sfs_fs *sfs, void *buf, size_t len, uint32_t blkno, off_t offset) {
    assert(offset >= 0 && offset < SFS_BLKSIZE && offset + len <= SFS_BLKSIZE);
    int ret;
    lock_sfs_io(sfs);
    {
        if ((ret = sfs_rwblock_nolock(sfs, sfs->sfs_buffer, blkno, 0, 1)) == 0) {
            memcpy(sfs->sfs_buffer + offset, buf, len);
            ret = sfs_rwblock_nolock(sfs, sfs->sfs_buffer, blkno, 1, 1);
        }
    }
    unlock_sfs_io(sfs);
    return ret;
}

/*
 * sfs_sync_super - write sfs->super (in memory) into disk (SFS_BLKN_SUPER, 1) with lock protect.
 */
//dirty时，写回磁盘  super块dirty
int
sfs_sync_super(struct sfs_fs *sfs) {
    int ret;
    lock_sfs_io(sfs);
    {
        memset(sfs->sfs_buffer, 0, SFS_BLKSIZE);
        memcpy(sfs->sfs_buffer, &(sfs->super), sizeof(sfs->super));
        ret = sfs_rwblock_nolock(sfs, sfs->sfs_buffer, SFS_BLKN_SUPER, 1, 0);
    }
    unlock_sfs_io(sfs);
    return ret;
}

/*
 * sfs_sync_freemap - write sfs bitmap into disk (SFS_BLKN_FREEMAP, nblks)  without lock protect.
 */
int
sfs_sync_freemap(struct sfs_fs *sfs) {
    uint32_t nblks = sfs_freemap_blocks(&(sfs->super));//super->blocks记录了总块数，总bits数/一个块Bits=freemap占用的块数量
    return sfs_wblock(sfs, bitmap_getdata(sfs->freemap, NULL), SFS_BLKN_FREEMAP, nblks);
}

/*
 * sfs_clear_block - write zero info into disk (blkno, nblks)  with lock protect.
 * @sfs:   sfs_fs which will be process
 * @blkno: the NO. of disk block
 * @nblks: Rd/Wr number of disk block
 */
//将索引为blkno的磁盘块清空
int
sfs_clear_block(struct sfs_fs *sfs, uint32_t blkno, uint32_t nblks) {
    int ret;
    //避免同时访问sfs
    lock_sfs_io(sfs);
    {
        //首先把sfs的sfs_buffer置为0  把全0写入blkno对应的磁盘
        memset(sfs->sfs_buffer, 0, SFS_BLKSIZE);
        while (nblks != 0) {
            if ((ret = sfs_rwblock_nolock(sfs, sfs->sfs_buffer, blkno, 1, 1)) != 0) {
                break;
            }
            blkno ++, nblks --;
        }
    }
    unlock_sfs_io(sfs);
    return ret;
}


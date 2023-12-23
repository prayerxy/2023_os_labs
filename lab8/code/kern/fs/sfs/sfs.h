#ifndef __KERN_FS_SFS_SFS_H__
#define __KERN_FS_SFS_SFS_H__

#include <defs.h>
#include <mmu.h>
#include <list.h>
#include <sem.h>
#include <unistd.h>

/*
 * Simple FS (SFS) definitions visible to ucore. This covers the on-disk format
 * and is used by tools that work on SFS volumes, such as mksfs.
 */

#define SFS_MAGIC                                   0x2f8dbe2a              /* magic number for sfs */
#define SFS_BLKSIZE                                 PGSIZE                  /* size of block */
#define SFS_NDIRECT                                 12                      /* # of direct blocks in inode */
#define SFS_MAX_INFO_LEN                            31                      /* max length of infomation */
#define SFS_MAX_FNAME_LEN                           FS_MAX_FNAME_LEN        /* max length of filename */
#define SFS_MAX_FILE_SIZE                           (1024UL * 1024 * 128)   /* max file size (128M) */
#define SFS_BLKN_SUPER                              0                       /* block the superblock lives in */
#define SFS_BLKN_ROOT                               1                       /* location of the root dir inode */
#define SFS_BLKN_FREEMAP                            2                       /* 1st block of the freemap */

/* # of bits in a block */
#define SFS_BLKBITS                                 (SFS_BLKSIZE * CHAR_BIT)

/* # of entries in a block */
#define SFS_BLK_NENTRY                              (SFS_BLKSIZE / sizeof(uint32_t))

/* file types */
#define SFS_TYPE_INVAL                              0       /* Should not appear on disk */
#define SFS_TYPE_FILE                               1
#define SFS_TYPE_DIR                                2
#define SFS_TYPE_LINK                               3

/*
 * On-disk superblock
 */
//超级块的数据结构
struct sfs_super {
    uint32_t magic;                                 /* magic number, should be SFS_MAGIC */
    uint32_t blocks;                                /* 记录SFS中所有block的数量 */
    uint32_t unused_blocks;                         /* 记录SFS中还没有被使用的block数量 */
    char info[SFS_MAX_INFO_LEN + 1];                /* infomation for sfs  */
};

/* inode (on disk) */
//记录了文件或目录的内容储存的索引信息
//磁盘索引节点的数据结构
struct sfs_disk_inode {
    uint32_t size;                                  /* size of the file (in bytes) 文件大小 */
    uint16_t type;                                  /* one of SYS_TYPE_* above   inode文件类型 目录 文件 两者*/
    uint16_t nlinks;                                /* # of hard links to this file    硬链接数 */
    uint32_t blocks;                                /* # of blocks    此inode的数据块数的个数  文件占用的数据块*/
    uint32_t direct[SFS_NDIRECT];                   /* direct blocks */
    uint32_t indirect;                              /* indirect blocks */
//    uint32_t db_indirect;                           /* double indirect blocks */
//   unused
};

/* file entry (on disk) */
//sfs_disk_inode里面的索引对于目录，指的是这个结构体  一个sfs_disk_entry占用一个block
//索引值ino标识磁盘block编号，可以得到相应文件/文件夹下的inode
//name 标识目录下文件/文件夹的名称
struct sfs_disk_entry {
    uint32_t ino;                                   /* inode number    是目录索引节点所占的数据块的索引值 */
    char name[SFS_MAX_FNAME_LEN + 1];               /* 文件名*/
};

#define sfs_dentry_size                             \
    sizeof(((struct sfs_disk_entry *)0)->name)

/* inode for sfs */
//内存中的索引节点
//只有打开一个文件才会创建，而磁盘inode是保存在硬盘中，只有进程需要才会被读入内存
struct sfs_inode {
    struct sfs_disk_inode *din;                     /* sfs的磁盘inode信息 */
    uint32_t ino;                                   /* inode number  是din所占的磁盘块的索引  */
    bool dirty;                                     /* true if inode modified     dirty那么要进行写回 根据ino与din */
    int reclaim_count;                              /* kill inode if it hits zero */
    semaphore_t sem;                                /* semaphore for din */
    list_entry_t inode_link;                        /* entry for linked-list in sfs_fs */
    list_entry_t hash_link;                         /* entry for hash linked-list in sfs_fs */
};

#define le2sin(le, member)                          \
    to_struct((le), struct sfs_inode, member)

/* filesystem for sfs */
//内存中的文件系统
struct sfs_fs {
    //在sfs_do_mount函数中，完成了加载位于硬盘的sfs文件系统的superblock，freemap工作
    struct sfs_super super;                         /* on-disk superblock    超级块*/
    struct device *dev;                             /* device mounted on     设备 */
    struct bitmap *freemap;                         /* blocks in use are mared 0    位图*/
    bool super_dirty;                               /* true if super/freemap modified */
    void *sfs_buffer;                               /* buffer for non-block aligned io   内存内容的一个缓冲区*/
    semaphore_t fs_sem;                             /* semaphore for fs */
    semaphore_t io_sem;                             /* semaphore for io */
    semaphore_t mutex_sem;                          /* semaphore for link/unlink and rename */
    list_entry_t inode_list;                        /* inode linked-list    把sys_inode串起来*/
    list_entry_t *hash_list;                        /* inode hash linked-list */
};

/* hash for sfs */
#define SFS_HLIST_SHIFT                             10
#define SFS_HLIST_SIZE                              (1 << SFS_HLIST_SHIFT)
#define sin_hashfn(x)                               (hash32(x, SFS_HLIST_SHIFT))

/* size of freemap (in bits) */
#define sfs_freemap_bits(super)                     ROUNDUP((super)->blocks, SFS_BLKBITS)

/* size of freemap (in blocks) */
#define sfs_freemap_blocks(super)                   ROUNDUP_DIV((super)->blocks, SFS_BLKBITS)

struct fs;
struct inode;

void sfs_init(void);
int sfs_mount(const char *devname);

void lock_sfs_fs(struct sfs_fs *sfs);
void lock_sfs_io(struct sfs_fs *sfs);
void unlock_sfs_fs(struct sfs_fs *sfs);
void unlock_sfs_io(struct sfs_fs *sfs);

int sfs_rblock(struct sfs_fs *sfs, void *buf, uint32_t blkno, uint32_t nblks);
int sfs_wblock(struct sfs_fs *sfs, void *buf, uint32_t blkno, uint32_t nblks);
int sfs_rbuf(struct sfs_fs *sfs, void *buf, size_t len, uint32_t blkno, off_t offset);
int sfs_wbuf(struct sfs_fs *sfs, void *buf, size_t len, uint32_t blkno, off_t offset);
int sfs_sync_super(struct sfs_fs *sfs);
int sfs_sync_freemap(struct sfs_fs *sfs);
int sfs_clear_block(struct sfs_fs *sfs, uint32_t blkno, uint32_t nblks);

int sfs_load_inode(struct sfs_fs *sfs, struct inode **node_store, uint32_t ino);

#endif /* !__KERN_FS_SFS_SFS_H__ */


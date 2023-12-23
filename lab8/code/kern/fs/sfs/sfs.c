#include <defs.h>
#include <sfs.h>
#include <error.h>
#include <assert.h>

/*
 * sfs_init - mount sfs on disk0
 *
 * CALL GRAPH:
 *   kern_init-->fs_init-->sfs_init
 */
void
sfs_init(void) {
    //完成Simple FS文件系统的初始化
    //并且把此实例文件系统挂在虚拟文件系统vfs中
    //ucore其他部分可以通过访问虚拟文件系统的接口来进一步访问到SFS实例文件系统
    int ret;
    if ((ret = sfs_mount("disk0")) != 0) {
        panic("failed: sfs: sfs_mount: %e.\n", ret);
    }
}


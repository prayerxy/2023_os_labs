#include <defs.h>
#include <string.h>
#include <vfs.h>
#include <inode.h>
#include <error.h>
#include <assert.h>

/*
 * get_device- Common code to pull the device name, if any, off the front of a
 *             path and choose the inode to begin the name lookup relative to.
 */

static int
get_device(char *path, char **subpath, struct inode **node_store) {
    int i, slash = -1, colon = -1;
    for (i = 0; path[i] != '\0'; i ++) {
        //找到冒号，斜杠的位置，记录索引于两个变量中
        if (path[i] == ':') { colon = i; break; }
        if (path[i] == '/') { slash = i; break; }
    }
    if (colon < 0 && slash != 0) {
        /* *
         * No colon before a slash, so no device name specified, and the slash isn't leading
         * or is also absent, so this is a relative path or just a bare filename. Start from
         * the current directory, and use the whole thing as the subpath.
         * */
        //相对路径或者只是一个文件名   将整个路径作为子路径，并且调用vfs_get_curdir获取当前目录的inode
        *subpath = path;
        return vfs_get_curdir(node_store);
    }
    if (colon > 0) {
        /* device:path - get root of device's filesystem */
        path[colon] = '\0';

        /* device:/path - skip slash, treat as device:path */
        while (path[++ colon] == '/');
        *subpath = path + colon;
        return vfs_get_root(path, node_store);
    }

    /* *
     * we have either /path or :path
     * /path is a path relative to the root of the "boot filesystem"
     * :path is a path relative to the root of the current filesystem
     * */
    int ret;
    //表示路径是相对于引导文件系统的根目录的路径。代码会调用 vfs_get_bootfs 函数获取引导文件系统的根节点
    if (*path == '/') {
        //获取引导文件系统的根节点
        if ((ret = vfs_get_bootfs(node_store)) != 0) {
            return ret;
        }
    }
    else {
        //表示路径是相对于当前文件系统的根目录的路径。代码会调用 vfs_get_curdir 函数获取当前文件系统的根节点
        assert(*path == ':');
        struct inode *node;
        if ((ret = vfs_get_curdir(&node)) != 0) {
            return ret;
        }
        /* The current directory may not be a device, so it must have a fs. */
        assert(node->in_fs != NULL);
        *node_store = fsop_get_root(node->in_fs);
        vop_ref_dec(node);
    }

    /* ///... or :/... */
    while (*(++ path) == '/');
    *subpath = path;
    return 0;
}

/*
 * vfs_lookup - get the inode according to the path filename
 */
int
vfs_lookup(char *path, struct inode **node_store) {
    int ret;
    struct inode *node;
    //获取路径名与设备信息
    //找到根目录"/"对应的inode
    if ((ret = get_device(path, &path, &node)) != 0) {
        return ret;
    }
    //获取的Path路径名不为空，那么查找文件
    if (*path != '\0') {
        //node_store就是查找到的文件的inode
        //调用vop_lookup找到SFS文件系统中目录下的文件
        ret = vop_lookup(node, path, node_store);
        vop_ref_dec(node);
        return ret;
    }
    //路径名为空，那么返回之前get_device查找到的node即可
    *node_store = node;
    return 0;
}

/*
 * vfs_lookup_parent - Name-to-vnode translation.
 *  (In BSD, both of these are subsumed by namei().)
 */
int
vfs_lookup_parent(char *path, struct inode **node_store, char **endp){
    int ret;
    struct inode *node;
    if ((ret = get_device(path, &path, &node)) != 0) {
        return ret;
    }
    *endp = path;
    *node_store = node;
    return 0;
}

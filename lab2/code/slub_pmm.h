#ifndef __KERN_MM_SLUB_H__
#define  __KERN_MM_SLUB_H__

#include <pmm.h>
#include <list.h>



extern const struct pmm_manager slub_pmm_manager;

#define LEFT_LEAF(index) ((index) * 2 + 1)
#define RIGHT_LEAF(index) ((index) * 2 + 2)
#define PARENT(index) ( ( (index) + 1 ) / 2 - 1 )

#define IS_POWER_OF_2(x) (!( (x) & ((x) - 1) ))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

#define MAX_NUM_BUDDY_ZONE 10
//仓库结构体
struct cache_t {
    list_entry_t slabs_full;	// 全满Slab链表
    list_entry_t slabs_partial;	// 部分空闲Slab链表
    list_entry_t slabs_free;	// 全空闲Slab链表
    uint16_t objsize;		// 对象大小
    uint16_t num;			// 每个Slab保存的对象数目
    list_entry_t cache_link;	// 仓库链表
};
//slab结构
struct slab_t {
    int ref;                       
    struct cache_t *cachep;  //属于哪个仓库            
    uint16_t inuse;
    uint16_t free;
    list_entry_t slab_link;
};
//申请一页内存
void *
cache_grow(struct cache_t *cachep);
//将内存页归还。
void
slab_destroy(struct cache_t *cachep, struct slab_t *slab);


struct cache_t *
cache_create( size_t size);

void cache_destroy(struct cache_t *cachep);

//slab里面obj的分配
void *cache_alloc(struct cache_t *cachep);
//释放obj
void cache_free(struct cache_t *cachep, void *objp);



#endif /* ! __KERN_MM_SLUB_H__ */

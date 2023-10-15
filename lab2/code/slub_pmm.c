#include <pmm.h>
#include<slub_pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>

struct buddy {
    size_t size;
    uintptr_t *longest; //完全二叉树数组
    size_t longest_num_page;
    size_t total_num_page;
    size_t free_size;  
    struct Page *begin_page;
};

struct buddy mem_buddy[MAX_NUM_BUDDY_ZONE];
int num_buddyz = 0;


#define le2slab(le,link)    ((struct slab_t*)le2page((struct Page*)le,link))
#define slab2kva(slab)      (page2kva((struct Page*)slab))

static list_entry_t cache_chain;
static struct cache_t cache_cache;  //进行分配仓库的仓库


struct test_object {
    char test_member[2046];
};

struct test2_object{
    char test2_member[1022];
};

static void
system_init(void) {
     // Init cache for cache
     
    cache_cache.objsize = sizeof(struct cache_t);
    cache_cache.num = PGSIZE / (sizeof(int16_t) + sizeof(struct cache_t));

    list_init(&(cache_cache.slabs_full));
    list_init(&(cache_cache.slabs_partial));
    list_init(&(cache_cache.slabs_free));
    list_init(&(cache_chain));
    list_add(&(cache_chain), &(cache_cache.cache_link));
}

static size_t next_power_of_2(size_t size) {
    size-=1;//如果size恰好为幂次数，必须减一；如果size不是幂次数，减一无影响
    size |= size >> 1;
    size |= size >> 2;
    size |= size >> 4;
    size |= size >> 8;
    size |= size >> 16;
    return size + 1;
}

static void
buddy_system_init_memmap(struct Page *base, size_t n) { //注意这里base传的为页结构体的虚拟地址
    cprintf("n: %d\n", n);
    struct buddy *buddy = &mem_buddy[num_buddyz++];

    size_t v_size = next_power_of_2(n);//n的下一个2的幂次数
    size_t excess = v_size - n; //多出来的部分
    size_t v_alloced_size = next_power_of_2(excess); //将多出来的部分化为2的幂次数

    buddy->size = v_size;
    buddy->free_size = v_size - v_alloced_size; //实际可用的大小 有一些不是2的幂次方不能管理
    buddy->longest = page2kva(base); //将base页的地址转为页结构体映射的物理地址再转为虚拟地址
    //longest起始位置在base处
    //paddr 将虚拟变为物理地址 roundup按照页大小向上取整 最后将address成功转为对应页的存储地址(也是虚拟地址)
    buddy->begin_page = pa2page(PADDR(ROUNDUP(buddy->longest + 2 * v_size * sizeof(uintptr_t)+3*sizeof(size_t)+sizeof(struct Page*), PGSIZE))); //去除buddy里面longest动态分配内存的页号
    buddy->longest_num_page = buddy->begin_page - base; //Longest数组大小，物理地址相减
    buddy->total_num_page = n - buddy->longest_num_page;  //减去longest数组等之后拥有的页数量大小
    cprintf("longest虚拟地址: 0x%016lx\n",buddy->longest);

 
    size_t node_size = buddy->size * 2;

    for (int i = 0; i < 2 * buddy->size - 1; i++) {
        if (IS_POWER_OF_2(i + 1)) {
            node_size /= 2;
        }
        buddy->longest[i] = node_size;
        
    }
    int index = 0;
    while (1) {
        if (buddy->longest[index] == v_alloced_size) {
            buddy->longest[index] = 0;
            break;
        }
        index = RIGHT_LEAF(index); //实际的大小小于v_size，所以需要把右子树多的标记为不可分配
    }
    //这里只用把父节点更改，因为访问时遇到0不会访问子节点，所以子节点大小不为0没有影响
    while (index) {
        index = PARENT(index);
        buddy->longest[index] = MAX(buddy->longest[LEFT_LEAF(index)], buddy->longest[RIGHT_LEAF(index)]);
    }

    assert(buddy->total_num_page>=buddy->longest[0]);
    struct Page *p = buddy->begin_page; 
    for (; p != base + buddy->free_size; p ++) { //一共可以使用的大小 free_size，其他的不归buddy管理
        assert(PageReserved(p)); //判断之前是否为内核保留
        p->flags = p->property = 0; //设置为不被内核使用，property置0
        set_page_ref(p, 0);
    }
}

static struct Page *
buddy_system_alloc_pages(size_t n) {
   assert(n > 0);
    if (!IS_POWER_OF_2(n))
        n = next_power_of_2(n);//n的下一个最近的2幂次数

    size_t index = 0;
    size_t node_size;
    size_t offset = 0;

    struct buddy *buddy = NULL;//找到哪一个mem_buddy满足当前大小
    for (int i = 0; i < num_buddyz; i++) {
        if (mem_buddy[i].longest[index] >= n) {
            buddy = &mem_buddy[i];
            break;
        }
    }

    if (!buddy) {
        return NULL;
    }

    for (node_size = buddy->size; node_size != n; node_size /= 2) { 
        if (buddy->longest[LEFT_LEAF(index)] >= n)
            index = LEFT_LEAF(index);//当前节点的子节点大于去左边，我们分配左边优先
        else
            index = RIGHT_LEAF(index);
    }

    buddy->longest[index] = 0;
    offset = (index + 1) * node_size - buddy->size;//偏移量，相对于begin_page地址的
    //更改当前分配的节点的父节点
    while (index) {
        index = PARENT(index);
        buddy->longest[index] = MAX(buddy->longest[LEFT_LEAF(index)], buddy->longest[RIGHT_LEAF(index)]);
    }

    buddy->free_size -= n;

    return buddy->begin_page + offset;//我们的节点代表的是页，这里返回的是第几个，即从哪里开始花掉内存空间大小
}

static void
buddy_system_free_pages(struct Page *base, size_t n) { //这里的n没有用，只是统一接口
    struct buddy *buddy = NULL;

    for (int i = 0; i < num_buddyz; i++) {
        struct buddy *t = &mem_buddy[i];
        if (base >= t->begin_page && base < t->begin_page + t->size) {
            buddy = t;
            break;
        }
    }

    if (!buddy) return;

    unsigned node_size, index = 0;
    unsigned left_longest, right_longest;
    unsigned offset = base - buddy->begin_page;

    assert(offset >= 0 && offset < buddy->size);

    node_size = 1;
    index = offset + buddy->size - 1;//找到完全二叉树最底层的同样偏移量的节点，从该节点向上溯源

    for (; buddy->longest[index]; index = PARENT(index)) {
        node_size *= 2;
        if (index == 0)
            return;
    }//找到了要释放的那个节点 ,node_size是那个完全二叉树节点的大小

    buddy->longest[index] = node_size;
    buddy->free_size += node_size;//释放空间

    while (index) {
        index = PARENT(index);
        node_size *= 2;

        left_longest = buddy->longest[LEFT_LEAF(index)];
        right_longest = buddy->longest[RIGHT_LEAF(index)];

        if (left_longest + right_longest == node_size)
            buddy->longest[index] = node_size;
        else 
            buddy->longest[index] = MAX(left_longest, right_longest);
    }
}

static size_t
buddy_system_nr_free_pages(void) {
    size_t total_free_pages = 0;
    for (int i = 0; i < num_buddyz; i++) {
        total_free_pages += mem_buddy[i].free_size;
    }
    return total_free_pages; //总共有多少个free的页数量
}
static void
print_buddy_tree(int level, char *label) {
    cprintf("\nprint buddy tree: %s\n", label);

    int num = 1;
    int index = 0;
    int curlevel_num = 1;
    for (int i = 0; i < level; i++) {
        for(int j=0;j<curlevel_num;j++){
            if(i>=10&&j<=10){
                cprintf("%d ", mem_buddy[0].longest[index]);
            }
            index++;
        }
        curlevel_num*=2;
        if(i>=10){
            cprintf("\n");
        }
    }
    cprintf("print buddy tree end\n\n");
}




//申请一页内存，初始化空闲链表bufctl，构造buf中的对象，更新Slab元数据，最后将新的Slab加入到仓库的空闲Slab表中
void *
cache_grow(struct cache_t *cachep) {
    struct Page *page = alloc_page();
    void *kva = page2kva(page);//转为虚拟地址
    // Init slub meta data
    struct slab_t *slab = (struct slab_t *) page;
    slab->cachep = cachep;
    slab->inuse = slab->free = 0;
    list_add(&(cachep->slabs_free), &(slab->slab_link)); //仓库中链接此slab 一页
    // Init bufctl
    int16_t *bufctl = kva;
    for (int i = 1; i < cachep->num; i++)
        bufctl[i-1] = i;
    bufctl[cachep->num-1] = -1;
    // Init cache 
    //void *buf = bufctl + cachep->num;
    return slab;
}

//将内存页归还。
void
slab_destroy(struct cache_t *cachep, struct slab_t *slab) {
    struct Page *page = (struct Page *) slab;
    //  slab page 
    page->property = page->flags = 0;
    list_del(&(page->page_link));//把这个slab从仓库的链表中删除
    free_page(page);//释放，这里调用的是buddy里面的释放整页的函数
}




//创建仓库，size为对象的size。
// cache_create - create a cache
struct cache_t *
cache_create(size_t size) {
    assert(size <= (PGSIZE - 2));
    struct cache_t *cachep = cache_alloc(&(cache_cache));
    if (cachep != NULL) {
        cachep->objsize = size;
        cachep->num = PGSIZE / (sizeof(int16_t) + size);
        list_init(&(cachep->slabs_full));
        list_init(&(cachep->slabs_partial));
        list_init(&(cachep->slabs_free));
        list_add(&(cache_chain), &(cachep->cache_link));
    }
    return cachep;
}


//销毁仓库
void 
cache_destroy(struct cache_t *cachep) {
    list_entry_t *head, *le;
    // 销毁full slabs
    head = &(cachep->slabs_full);
    le = list_next(head);
    while (le != head) {
        list_entry_t *temp = le;
        le = list_next(le);
        slab_destroy(cachep, le2slab(temp, page_link));
    }
    // 销毁partial slabs 
    head = &(cachep->slabs_partial);
    le = list_next(head);
    while (le != head) {
        list_entry_t *temp = le;
        le = list_next(le);
        slab_destroy(cachep, le2slab(temp, page_link));
    }
    // 销毁free slabs 
    head = &(cachep->slabs_free);
    le = list_next(head);
    while (le != head) {
        list_entry_t *temp = le;
        le = list_next(le);
        slab_destroy(cachep, le2slab(temp, page_link));
    }
    // Free cache 这个仓库对于cache_cache来说也是一个obj,调用即可
    cache_free(&(cache_cache), cachep);
}   


//从当前仓库找一个slab分配一个obj
void *
cache_alloc(struct cache_t *cachep) {
    list_entry_t *le = NULL;
    // Find in partial list 
    if (!list_empty(&(cachep->slabs_partial)))
        le = list_next(&(cachep->slabs_partial));
    // Find in empty list 
    else {
        if (list_empty(&(cachep->slabs_free)) && cache_grow(cachep) == NULL)
            return NULL;
        le = list_next(&(cachep->slabs_free));
    }
    // Alloc 
    list_del(le);
    struct slab_t *slab = le2slab(le, page_link);
    void *kva = slab2kva(slab);
    int16_t *bufctl = kva;
    void *buf = bufctl + cachep->num;
    void *objp = buf + slab->free * cachep->objsize;
    // 更新 slab
    slab->inuse ++;
    slab->free = bufctl[slab->free];//free是当前可用第几个Obj对象
    if (slab->inuse == cachep->num)
        list_add(&(cachep->slabs_full), le);
    else 
        list_add(&(cachep->slabs_partial), le);
    return objp;
}

//从当前仓库里释放一个obj
void 
cache_free(struct cache_t *cachep, void *objp) {
    // Get slab of object 
    void *base = page2kva(pages);
    void *kva = ROUNDDOWN(objp, PGSIZE);//该objp属于哪一页
    struct slab_t *slab = (struct slab_t *) &pages[(kva-base)/PGSIZE];
    // Get offset in slab
    int16_t *bufctl = kva;
    void *buf = bufctl + cachep->num;
    int offset = (objp - buf) / cachep->objsize;
    // Update slab 
    list_del(&(slab->slab_link));
    bufctl[offset] = slab->free;
    slab->inuse --;
    slab->free = offset;
    if (slab->inuse == 0)
        list_add(&(cachep->slabs_free), &(slab->slab_link));
    else 
        list_add(&(cachep->slabs_partial), &(slab->slab_link));
}




static size_t 
list_length(list_entry_t *listelm) {
    size_t len = 0;
    list_entry_t *le = listelm;
    while ((le = list_next(le)) != listelm)
        len ++;
    return len;
}

void 
check_slub() {
    //这里我们复用page,将slab等价于page
    assert(sizeof(struct Page) == sizeof(struct slab_t));
    print_buddy_tree(16,"原先的内存情况");
    //创建一个仓库，大小为2046个字节
    struct cache_t *cp0 = cache_create(sizeof(struct test_object));
    assert(cp0 != NULL);
    print_buddy_tree(16,"产生cp0仓库后的内存情况");//cache里面分配了一个slub，里面存了一个仓库类型
    // Allocate six objects
    struct test_object *p0, *p1, *p2, *p3, *p4,*p5;

    //在cp0仓库里分配一个Obj
    assert((p0 = cache_alloc(cp0)) != NULL);
    assert((p1 = cache_alloc(cp0)) != NULL);
    assert((p2 = cache_alloc(cp0)) != NULL);
    assert((p3 = cache_alloc(cp0)) != NULL);
    assert((p4 = cache_alloc(cp0)) != NULL);
    assert((p5 = cache_alloc(cp0)) != NULL);//申请3个页
    print_buddy_tree(16,"申请6个2046字节后的内存情况");
 
    assert(list_empty(&(cp0->slabs_free))); //没有全空的slab
    assert(list_empty(&(cp0->slabs_partial)));//没有部分空的slab
    assert(list_length(&(cp0->slabs_full)) == 3);//6个结构体大小，用3个slab
    // Free three objects 
    cache_free(cp0, p3);
    cache_free(cp0, p4);
    cache_free(cp0, p5);
    assert(list_length(&(cp0->slabs_free)) == 1);
    assert(list_length(&(cp0->slabs_partial)) == 1);
    assert(list_length(&(cp0->slabs_full)) == 1);
    slab_destroy(cp0,le2slab(list_next(&(cp0->slabs_free)), page_link));
    assert(list_length(&(cp0->slabs_free))==0);
    print_buddy_tree(16,"释放一个slab后的内存情况");

    cache_destroy(cp0);
    print_buddy_tree(16,"销毁仓库cp0后的内存情况");


    struct cache_t *cp1 = cache_create(sizeof(struct test2_object));
    print_buddy_tree(16,"产生cp1仓库后的内存情况");//内存页情况没有变化，因为仓库类型很小
    struct test2_object *t0, *t1, *t2, *t3, *t4,*t5,*t6,*t7;//使用两个页
    assert((t0 = cache_alloc(cp1)) != NULL);
    assert((t1 = cache_alloc(cp1)) != NULL);
    assert((t2 = cache_alloc(cp1)) != NULL);
    assert((t3 = cache_alloc(cp1)) != NULL);
    assert((t4 = cache_alloc(cp1)) != NULL);
    assert((t5 = cache_alloc(cp1)) != NULL);
    assert((t6 = cache_alloc(cp1)) != NULL);
    assert((t7 = cache_alloc(cp1)) != NULL);

    print_buddy_tree(16,"申请8个1022字节后的内存情况");
    assert(list_empty(&(cp1->slabs_free))); //没有全空的slab
    assert(list_empty(&(cp1->slabs_partial)));//没有部分空的slab
    assert(list_length(&(cp1->slabs_full)) == 2);//用2个slab
    // Free three objects 
    cache_free(cp1, t3);
    cache_free(cp1, t4);
    cache_free(cp1, t5);
    cache_free(cp1, t6);
    cache_free(cp1, t7);
    assert(list_length(&(cp1->slabs_free))==1); //有全空的slab，释放4个全空。
    assert(list_length(&(cp1->slabs_partial))==1);//有部分空的slab
    assert(list_empty(&(cp1->slabs_full))); //没有全满的
    //释放全空的slab
    slab_destroy(cp1,le2slab(list_next(&(cp1->slabs_free)), page_link));
    print_buddy_tree(16,"释放一个slab后的内存情况");

    cprintf("check_slub() succeeded!\n");

}


//接口
const struct pmm_manager slub_pmm_manager = {
    .name = "slub_pmm_manager",
    .init = system_init,
    .init_memmap = buddy_system_init_memmap,
    .alloc_pages = buddy_system_alloc_pages,
    .free_pages = buddy_system_free_pages,
    .nr_free_pages = buddy_system_nr_free_pages,
    .check = check_slub,
};


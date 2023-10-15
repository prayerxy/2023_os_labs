#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_system_pmm.h>
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
int num_buddy_zone = 0;

static void
buddy_system_init(void) {

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
    struct buddy *buddy = &mem_buddy[num_buddy_zone++];

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
    for (int i = 0; i < num_buddy_zone; i++) {
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

    for (int i = 0; i < num_buddy_zone; i++) {
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
    for (int i = 0; i < num_buddy_zone; i++) {
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
            cprintf("%d ", mem_buddy[0].longest[index++]);
        }
        curlevel_num*=2;
        cprintf("\n");
    }
    cprintf("print buddy tree end\n\n");
}
static void
buddy_check(void) {
    size_t total = buddy_system_nr_free_pages();
    cprintf("mem_budy[0].size:%d\n",mem_buddy[0].size);
    cprintf("mem_budy[0].longest_num_page: %d\n", mem_buddy[0].longest_num_page);
    cprintf("num_buddy_zone:%d\n",num_buddy_zone);
    cprintf("total_buddy_free_pages: %d\n", total);

    struct Page *p0 = alloc_page();//分配1个页
    assert(p0 != NULL);
    assert(buddy_system_nr_free_pages() == total - 1);//判断是否分配成功
    assert(p0 == mem_buddy[0].begin_page);//判断分配的页的地址是否为mem_budy管理的页开始地址

    struct Page *p1 = alloc_page();
    assert(p1 != NULL);
    assert(buddy_system_nr_free_pages() == total - 2);
    assert(p1 == mem_buddy[0].begin_page + 1);

    assert(p1 == p0 + 1);

    buddy_system_free_pages(p0, 1);
    buddy_system_free_pages(p1, 1);  //释放两个页
    assert(buddy_system_nr_free_pages() == total);//是否释放成功

    p0 = buddy_system_alloc_pages(14); //分配14个
    assert(buddy_system_nr_free_pages() == total - 16); //14最近的为16，所以少16个页

    p1 = buddy_system_alloc_pages(100); //100最近的为128
    assert(buddy_system_nr_free_pages() == total - 144);  //128+16=144

    buddy_system_free_pages(p0, -100); //释放p0开始的16个页的节点
    buddy_system_free_pages(p1, -100);//释放p1开始的128个节点
    assert(buddy_system_nr_free_pages() == total);  //判断是否成功

    p0 = buddy_system_alloc_pages(total); //把所有的都分配，显然不成功
    assert(p0 == NULL);

    print_buddy_tree(8, "buddy_system使用的完全二叉树初始化");
    p0 = buddy_system_alloc_pages(256);
    print_buddy_tree(8, "分配256个页");
    assert(buddy_system_nr_free_pages() == total - 256);

    p1 = buddy_system_alloc_pages(1024);
    print_buddy_tree(8, "分配1024个页");
    assert(buddy_system_nr_free_pages() == total - 256 - 1024);

    struct Page *p2 = buddy_system_alloc_pages(2048);
    print_buddy_tree(8, "分配2048个页");
    assert(buddy_system_nr_free_pages() == total - 256 - 1024 - 2048);

    buddy_system_free_pages(p1, -100);
    print_buddy_tree(8,"回收1024个页");

    struct Page *p3 = buddy_system_alloc_pages(4096);
    print_buddy_tree(8, "分配4096个页");
    assert(buddy_system_nr_free_pages() == total - 256 - 2048 - 4096);

    struct Page *p4 = buddy_system_alloc_pages(8192);
    print_buddy_tree(8, "分配8192个页");
    assert(buddy_system_nr_free_pages() == total - 256  - 2048 - 4096 - 8192);
  
    buddy_system_free_pages(p3, -100);
    print_buddy_tree(8,"回收4096个页后");

    struct Page *p5 = buddy_system_alloc_pages(8000);
    print_buddy_tree(8, "试图分配8000个页后");
    assert(buddy_system_nr_free_pages() == total - 256 - 2048 - 8192 - 8192);

    buddy_system_free_pages(p0, -100);
    buddy_system_free_pages(p2, -100);
    buddy_system_free_pages(p4, -100);
    buddy_system_free_pages(p5, -100);

    assert(buddy_system_nr_free_pages() == total);
}

//接口
const struct pmm_manager buddy_system_pmm_manager = {
    .name = "buddy_system_pmm_manager",
    .init = buddy_system_init,
    .init_memmap = buddy_system_init_memmap,
    .alloc_pages = buddy_system_alloc_pages,
    .free_pages = buddy_system_free_pages,
    .nr_free_pages = buddy_system_nr_free_pages,
    .check = buddy_check,
};


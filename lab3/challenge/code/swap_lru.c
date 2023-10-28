#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_lru.h>
#include <list.h>

/* [wikipedia]The simplest Page Replacement Algorithm(PRA) is a lru algorithm. The first-in, first-out
 * page replacement algorithm is a low-overhead algorithm that requires little book-keeping on
 * the part of the operating system. The idea is obvious from the name - the operating system
 * keeps track of all the pages in memory in a queue, with the most recent arrival at the back,
 * and the earliest arrival in front. When a page needs to be replaced, the page at the front
 * of the queue (the oldest page) is selected. While lru is cheap and intuitive, it performs
 * poorly in practical application. Thus, it is rarely used in its unmodified form. This
 * algorithm experiences Belady's anomaly.
 *
 * Details of lru PRA
 * (1) Prepare: In order to implement lru PRA, we should manage all swappable pages, so we can
 *              link these pages into pra_list_head according the time order. At first you should
 *              be familiar to the struct list in list.h. struct list is a simple doubly linked list
 *              implementation. You should know howto USE: list_init, list_add(list_add_after),
 *              list_add_before, list_del, list_next, list_prev. Another tricky method is to transform
 *              a general list struct to a special struct (such as struct page). You can find some MACRO:
 *              le2page (in memlayout.h), (in future labs: le2vma (in vmm.h), le2proc (in proc.h),etc.
 */

list_entry_t pra_list_head;
/*
 * (2) _lru_init_mm: init pra_list_head and let  mm->sm_priv point to the addr of pra_list_head.
 *              Now, From the memory control struct mm_struct, we can access lru PRA
 */
//初始化pra_list_head链表，即可换出的页面链表
static int
_lru_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;//串联可换出页面的链表
     //cprintf(" mm->sm_priv %x in lru_init_mm\n",mm->sm_priv);
     return 0;
}
/*
 * (3)_lru_map_swappable: According lru PRA, we should link the most recent arrival page at the back of pra_list_head qeueue
 */
//将页面设置为为可换出
static int
_lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    list_entry_t *entry=&(page->pra_page_link);
 
    assert(entry != NULL && head != NULL);
    //record the page access situlation

    //(1)link the most recent arrival page at the back of the pra_list_head qeueue.
    list_add(head, entry);
    return 0;
}
/*
 *  (4)_lru_swap_out_victim: According lru PRA, we should unlink the  earliest arrival page in front of pra_list_head qeueue,
 *                            then set the addr of addr of this page to ptr_page.
 */
//寻找可换出页面，将page传给ptr_page，将此页面从sm_priv链表删除
static int
_lru_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
     /* Select the victim */
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  set the addr of addr of this page to ptr_page
    list_entry_t *entry = list_prev(head);
    struct Page *page = le2page(entry, pra_page_link);
    *ptr_page=page;
    list_del(entry);
    return 0;
}
static int
_lru_tick_event(struct mm_struct *mm)  //时间中断
{ 
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    assert(head != NULL);
    list_entry_t *entry = list_prev(head);
    while(entry != head) {
        struct Page *page = le2page(entry, pra_page_link);
        pte_t *ptep = get_pte(mm->pgdir, page->pra_vaddr, 0);
        if(*ptep & PTE_A||*ptep & PTE_D) {
            list_entry_t *temp = entry;
            entry = entry->prev;
            list_del(temp);
            list_add(head, temp);
            *ptep &= ~PTE_A;//清除访问位
            *ptep &= ~PTE_D;//清除修改位
            tlb_invalidate(mm->pgdir, page->pra_vaddr);
        }
        else{
            entry = entry->prev;
        }
    }
    //cprintf("_lru_tick_event is called!\n");
    return 0;
}


static void print_now_list(struct mm_struct *mm){
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    list_entry_t *entry = list_prev(head);
    cprintf("检查链表元素顺序: \n");
    cprintf("开始从新到老打印: \n");
    while(entry != head) {
        struct Page *page = le2page(entry, pra_page_link);
        cprintf("%x\n",page->pra_vaddr);
        entry = entry->prev;
    }
}
static int
_lru_check_swap(void) {
    
    //初始时需要时钟中断下
    _lru_tick_event(check_mm_struct);
    cprintf("初始时钟中断!\n");
    print_now_list(check_mm_struct);

    cprintf("访问0x3000后的情况: \n");
    *(unsigned char *)0x3000 = 0x0c;
    _lru_tick_event(check_mm_struct);
    assert(pgfault_num==4);
    print_now_list(check_mm_struct);

    cprintf("访问0x4000后的情况: \n");
    *(unsigned char *)0x4000 = 0x0d;
    _lru_tick_event(check_mm_struct);
    assert(pgfault_num==4);
    print_now_list(check_mm_struct);

    cprintf("访问0x5000后的情况: \n");
    *(unsigned char *)0x5000 = 0x0e;
    _lru_tick_event(check_mm_struct);
    assert(pgfault_num==5);
    print_now_list(check_mm_struct);

    cprintf("连续访问0x2000 0x4000 0x3000后的情况: \n");
    *(unsigned char *)0x2000 = 0x0b;
    _lru_tick_event(check_mm_struct);
    assert(pgfault_num==5);
    *(unsigned char *)0x4000 = 0x0d;
    _lru_tick_event(check_mm_struct);
    assert(pgfault_num==5);
    *(unsigned char *)0x3000 = 0x0c;
    _lru_tick_event(check_mm_struct);
    assert(pgfault_num==5);
    print_now_list(check_mm_struct);

    cprintf("访问0x1000后的情况: \n");
    *(unsigned char *)0x1000 = 0x0a;
    _lru_tick_event(check_mm_struct);
    assert(pgfault_num==6);
    print_now_list(check_mm_struct);

    cprintf("访问0x1000后的情况: \n");
    *(unsigned char *)0x1000 = 0x0a;
    _lru_tick_event(check_mm_struct);
    assert(pgfault_num==6);
    print_now_list(check_mm_struct);

    cprintf("访问0x2000后的情况: \n");
    *(unsigned char *)0x2000 = 0x0b;
    _lru_tick_event(check_mm_struct);
    assert(pgfault_num==6);
    print_now_list(check_mm_struct);

    cprintf("访问0x5000 0x4000 0x3000后的情况: \n");
    *(unsigned char *)0x5000 = 0x0e;
    _lru_tick_event(check_mm_struct);
    assert(pgfault_num==7);
    *(unsigned char *)0x4000 = 0x0d;
    _lru_tick_event(check_mm_struct);
    assert(pgfault_num==8);
    *(unsigned char *)0x3000 = 0x0c;
    _lru_tick_event(check_mm_struct);
    assert(pgfault_num==9);
    print_now_list(check_mm_struct);
    
    cprintf("访问0x2000 0x5000 0x4000 0x3000后的情况: \n");
    *(unsigned char *)0x2000 = 0x0b;
    _lru_tick_event(check_mm_struct);
    assert(pgfault_num==9);
    *(unsigned char *)0x5000 = 0x0e;
    _lru_tick_event(check_mm_struct);
    assert(pgfault_num==9);
    *(unsigned char *)0x4000 = 0x0d;
    _lru_tick_event(check_mm_struct);
    assert(pgfault_num==9);
    *(unsigned char *)0x3000 = 0x0c;
    _lru_tick_event(check_mm_struct);
    assert(pgfault_num==9);
    print_now_list(check_mm_struct);
    return 0;
}


static int
_lru_init(void)
{
    return 0;
}

static int
_lru_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}


//将页面置换算法接到swap中去。
struct swap_manager swap_manager_lru =
{
     .name            = "lru swap manager",
     .init            = &_lru_init,
     .init_mm         = &_lru_init_mm,
     .tick_event      = &_lru_tick_event,
     .map_swappable   = &_lru_map_swappable,   
     .set_unswappable = &_lru_set_unswappable,
     .swap_out_victim = &_lru_swap_out_victim,
     .check_swap      = &_lru_check_swap,
};

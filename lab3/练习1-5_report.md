# lab3 report

## [练习0]

**练习0：填写已有实验**

> 本实验依赖实验2。请把你做的实验2的代码填入本实验中代码中有“LAB2”的注释相应部分。（建议手动补充，不要直接使用merge）

---

本次实验的代码已经自动补充到了`lab3`里面，所以具体没有需要补充的代码。



## [练习1] 理解基于FIFO的页面替换算法

> 描述FIFO页面置换算法下，一个页面从被换入到被换出的过程中，会经过代码里哪些函数/宏的处理（或者说，需要调用哪些函数/宏），并用简单的一两句话描述每个函数在过程中做了什么？（为了方便同学们完成练习，所以实际上我们的项目代码和实验指导的还是略有不同，例如我们将FIFO页面置换算法头文件的大部分代码放在了`kern/mm/swap_fifo.c`文件中，这点请同学们注意）
>
> - 至少正确指出10个不同的函数分别做了什么？如果少于10个将酌情给分。我们认为只要函数原型不同，就算两个不同的函数。要求指出对执行过程有实际影响,删去后会导致输出结果不同的函数（例如assert）而不是cprintf这样的函数。如果你选择的函数不能完整地体现”从换入到换出“的过程，比如10个函数都是页面换入的时候调用的，或者解释功能的时候只解释了这10个函数在页面换入时的功能，那么也会扣除一定的分数

---

### 1 . FIFO页面置换算法步骤

FIFO页面置换算法下，一般会经过以下步骤：

1. 页面置换机制初始化：负责此过程的函数为`swap_init`；
   - 此函数内部的`swapfs_init`负责磁盘交换扇区的初始化，确定了磁盘内部的最大页偏移量`max_swap_offset`；
   - 再对页面置换机制管理结构体指针`sm`赋值为fifo算法管理器地址，并且对fifo算法管理机制进行了初始化。由`sm->init`函数实现。即对fifo的管理队列进行了初始化；
2. 页面被换入：当引发`page fault`异常时，即一个虚拟地址无法映射到指定的物理内存，系统会调用`do_pgfault`函数进行异常处理。这时分为两种情况：
   - 如果这个虚拟地址在页表中没有对应的页表项，那么在`do_pgfault`函数内部会调用`get_pte`函数(令**create**字段为**1**)为此虚拟地址新建页表项，并且分配物理页给其进行映射。此时再次分为两种情况：
     - 系统此时有空闲的物理页，系统直接分配物理页给此虚拟地址进行映射；
     - 系统此时无空闲的物理页，系统会依赖页面置换机制来将某些页换出，具体的实现在`swap_out`中。在`swap_out`调用的`swap_out_victim`用于从FIFO队列中寻找要换出的页，`swapfs_write`用于把换出的页上的内容写入磁盘，最后再把页表项修改，存放其对应的磁盘扇区页偏移量；
     - 执行完上述两种情况后，我们添加映射到页表，并且将`Page`结构体加入到队列中进行管理，最后把`Page`结构体的`pra_vaddr`字段修改为映射其对应物理页的虚拟地址。
   - 如果这个虚拟地址在页表中有对应的页表项，那么待寻找到这个页表项之后，系统会从磁盘中读取其相关内容，并将其写入到一个空闲的物理页。主要实现在`swap_in`函数中。在此函数中调用`swapfs_read`函数来对磁盘的相关内容进行读取。寻找此物理页的过程与上述对应的系统此时有空闲物理页和无空闲物理页的处理方式相同。寻找到物理页后，我们添加映射到页表，并且将其对应的`Page`结构体加入到队列之中。此过程主要是由`swap_map_swappable`实现，最后把`Page`结构体的`pra_vaddr`字段修改为映射其对应物理页的虚拟地址。
3. 页面被换出：此时一定是引发`page fault`异常后，系统没有空闲的物理页。系统会依赖页面置换机制来将某些页换出，具体的实现在`swap_out`中。在`swap_out`调用的`swap_out_victim`用于从FIFO队列中寻找要换出的页，`swapfs_write`用于把换出的页上的内容写入磁盘，最后再把页表项修改，存放其对应的磁盘扇区页偏移量。

### 2 . 具体函数功能

#### 页面置换机制初始化函数：

##### swap_init函数

```c
int
swap_init(void)
{
     swapfs_init();
     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     sm = &swap_manager_fifo;//use first in first out Page Replacement Algorithm
     int r = sm->init();
     
     if (r == 0)
     {
          swap_init_ok = 1;
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
```

在此函数中调用`swapfs_init`函数对磁盘扇区交换区进行了初始化，初始化了磁盘扇区最大页偏移量。还指明了使用`FIFO`算法管理器来进行页面置换机制的实现，并且调用了其`init`函数进行`FIFO`队列初始化。

如下我们对`swapfs_init`函数和`init`函数进行分析：

##### swapfs_init函数

```c
void
swapfs_init(void) {
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {   //ideno < MAX_IDE？
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);   //最大偏移多少个页
}
```

此函数对磁盘扇区中的最大页偏移量进行了计算，其中`ide_device_size(SWAP_DEV_NO)`指明了磁盘扇区总个数。`SECTSIZE`为512个字节，即磁盘扇区大小。经过上述计算便可以最终得出磁盘扇区的最大页偏移量。

##### _fifo_init_mm函数

```c
static int
_fifo_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
```

此函数首先初始化了队列`pra_list_head`，在这里其实我们是借助双向链表实现队列功能。然后我们把此队列接在了`mm`所指向的结构体的`sm_priv`中，以此来实现队列由`mm`来进行管理的功能。



#### 页面被换出时的函数：

##### get_pte函数

```c
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)];      //获取PD页表项指针
    if (!(*pdep1 & PTE_V)) {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);  //对应物理页起始的物理地址
        memset(KADDR(pa), 0, PGSIZE);
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);   //page2ppn为物理页号，设置为合法且用户态
    }
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];   //第二级页表页表项指针
//    pde_t *pdep0 = &((pde_t *)(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V)) {
    	struct Page *page;
    	if (!create || (page = alloc_page()) == NULL) {
    		return NULL;
    	}
    	set_page_ref(page, 1);
    	uintptr_t pa = page2pa(page);
    	memset(KADDR(pa), 0, PGSIZE);
 //   	memset(pa, 0, PGSIZE);
    	*pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];  //查找pt上的页表项
}

```

在触发`page fault`异常后，调用`get_pte`函数来寻找线性地址对应的`page table`的页表项。令`create`字段为1，则可以在不存在页表时创建相应的页表。此函数将查找和创建两种功能集于一身，用`create`字段区分，达到了高效的目的。

##### swap_out函数

此函数主要用于当触发`page fault`异常后，系统此时无空闲的物理页，需要依赖页面分配机制换出页来获取空闲的物理页进行分配。其功能为在其内部调用`swap_out_victim`函数从FIFO队列中寻找要换出的页，然后调用`swapfs_write`用于把换出的页上的内容写入磁盘，最后再把页表项修改，存放其对应的磁盘扇区页偏移量。以此来达到实现换页的完整操作。



如下是对于`swap_out`函数里面的两个重要函数`swap_out_victim`和`swapfs_write`的分析：



##### swap_out_victim函数

```c
static int
_fifo_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
    
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
     /* Select the victim */
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  set the addr of addr of this page to ptr_page
    list_entry_t* entry = list_prev(head);
    if (entry != head) {
        list_del(entry);
        *ptr_page = le2page(entry, pra_page_link);
    } else {
        *ptr_page = NULL;
    }
    return 0;
}
```

在FIFO算法中对应的**swap_out_victim**函数为如上所示的**_fifo_swap_out_victim**函数，明显可以看出它提取了最早加入到队列的`Page`，即队列头前向指针所指向的元素。将其从队列中删除代表着其已经被换出，获取的`Page`存入到了`ptr_page`当中。



##### swapfs_write函数

```c
int
swapfs_write(swap_entry_t entry, struct Page *page) {
    //swap_offset: 偏离页的个数，swap_offset(entry) * PAGE_NSECT为此时磁盘扇区编号，PAGE_NSECT为一页的磁盘扇区个数
    //开始把page对应的物理页一个页的内容写入到磁盘中
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
}

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src, size_t nsecs) {
    int iobase = secno * SECTSIZE;  //磁盘扇区编号*磁盘扇区大小
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);  //nsecs个扇区大小
    return 0;
}
```

此函数的目的便是通过以虚拟地址的虚拟页号来代替磁盘扇区页偏移量，将要换出的页的内容写入到对应的磁盘扇区。这样便实现了要换出的页的数据的保存。

#### 页面被换入时的函数

根据如上的分析，当虚拟地址对应的页表项不存在时且系统此时无空闲的物理页，系统会依赖页面置换机制来将某些页换出。此时的函数调用与上面页面被换出时调用的函数类似，主要为swap_out、swap_out_victim和swapfs_write函数。上面已经分析过着三个函数。

接下来我们重点分析虚拟地址在页表中有对应的页表项的这种情况。此时需要将页面换入，将磁盘中之前页面的数据进行恢复。这个过程主要是**swap_in**函数来实现。

##### swap_in函数

此函数首先会分配一个页面，然后通过页表项中存放的磁盘扇区页偏移量的信息来把磁盘中的数据重新写入到这个页面。最后将我们分配的页面对应的`Page`结构体进行存储。

如下我们分析`swap_in`函数中的一个重要函数`swapfs_read`：

##### swapfs_read函数

```c
int
swapfs_read(swap_entry_t entry, struct Page *page) {
    //swap_offset: 偏离页的个数，swap_offset(entry) * PAGE_NSECT为此时磁盘扇区编号，PAGE_NSECT为一页的磁盘扇区个数
    //开始从磁盘读一个页的内容到page对应的物理页中
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
}


int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst, size_t nsecs) {
    int iobase = secno * SECTSIZE;  //磁盘扇区编号*磁盘扇区大小
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);  //nsecs个扇区大小
    return 0;
}
```

此函数的目的便是通过以虚拟地址的虚拟页号来代替磁盘扇区页偏移量，将要磁盘扇区中存放的数据写入到指定的物理页中。这样便实现了页的换入，把之前磁盘的数据写入到了一个物理页。

##### page_insert函数

此函数主要是用在`swap_in`函数之后，当`swap_in`函数调用完成后，也就意味着我们已经成功获取到了物理页。接下来我们便要建设此物理页与虚拟地址之间的映射，此映射的建立便是通过`page_insert`函数建立。



##### swap_map_swappable函数

此函数在FIFO算法管理器中的实现为`_fifo_map_swappable`函数。

```c
static int
_fifo_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    list_entry_t *entry=&(page->pra_page_link);
 
    assert(entry != NULL && head != NULL);
    //record the page access situlation

    //(1)link the most recent arrival page at the back of the pra_list_head qeueue.
    list_add(head, entry);
    return 0;
}
```

此函数便是将物理页对应的`Page`结构体插入到FIFO队列之中，由于此队列从头开始顺着`next`指针指的顺序是由新到老，所以我们插入一个最新的页面便是直接插在头的后面就行。

## [练习2] 深入理解不同分页模式的工作原理

>get_pte()函数（位于`kern/mm/pmm.c`）用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统中的分页机制下，是实现虚拟内存与物理内存之间映射关系非常重要的内容。
>
>- get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。
>- 目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

### 1.问题1

```c
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)];
    if (!(*pdep1 & PTE_V)) {  //PTE_V是valid位 下一级页表不存在，新建一个页表
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);//物理页号
        memset(KADDR(pa), 0, PGSIZE);
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V); //页表项的组成：物理页号|低10位标记位，更新pdep1页表项
    }
    //kddr，用的是三级页表最后一项，直接映射到物理页
    //这里实际上三级页表最后一项是直接映射物理页面，而其他511项映射到下一级页表
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
//    pde_t *pdep0 = &((pde_t *)(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V)) {
    	struct Page *page;
        //注意这里alloc也有页面置换相关
    	if (!create || (page = alloc_page()) == NULL) {
    		return NULL;
    	}
    	set_page_ref(page, 1);
    	uintptr_t pa = page2pa(page);
    	memset(KADDR(pa), 0, PGSIZE);
 //   	memset(pa, 0, PGSIZE);
    	*pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
}
```

>get_pte()函数中有两段形式类似的代码， 结合sv32，sv39，sv48的异同，解释这两段代码为什么如此相像。

Sv32、Sv39 和 Sv48 的主要区别在于支持的虚拟地址空间大小和页表项的大小。

- Sv32 分页模式使用两级页表映射，包括一级页表和二级页表。Sv32 分页模式支持 32 位的虚拟地址空间，页表项大小为 32 位。在 Sv32 分页模式中，虚拟地址被分为三个部分：高 10 位表示页目录项的索引，中间 10 位表示页表项的索引，低 12 位表示页内偏移量。
- Sv39 分页模式使用三级页表映射，包括一级页表、二级页表和三级页表。Sv39 分页模式支持 39 位的虚拟地址空间，页表项大小为 64 位。在 Sv39 分页模式中，虚拟地址被分为四个部分：高 9 位表示页目录项的索引，中间 9 位表示二级页表项的索引，接下来的 9 位表示一级页表项的索引，低 12 位表示页内偏移量。
- Sv48 分页模式使用四级页表映射，包括一级页表、二级页表、三级页表和四级页表。Sv48 分页模式支持 48 位的虚拟地址空间，页表项大小为 64 位。在 Sv48 分页模式中，虚拟地址被分为五个部分：高 9 位表示页目录项的索引，接下来的 9 位表示二级页表项的索引，接下来的 9 位表示一级页表项的索引，接下来的 9 位表示顶级页表项的索引，低 12 位表示页内偏移量。

可以发现，由于我们现在使用的是sv39模式，需要经过三级页表、二级页表的映射，才能到达pte页表项，最终得到页表项。

第一段代码是，从现在的三级页表，利用高9位找到对应pdt1,如果此pdt1不存在，说明二级页表还不存在，需要新建一个二级页表；如果存在，直接可以利用pdt1获得二级页表的地址，再根据中间9位找到pdt0。

第二段代码是，从现在的二级页表，利用中间9位找到对应的pdt0，如果此pdt0不存在，说明对应的一级页表还不存在，需要新建页表，如果存在，直接可以利用pdt0获得一级页表的地址，再根据低9位找到pte。

---

### 2.问题2

>目前get_pte()函数将页表项的查找和页表项的分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？

将页表项的查找和分配合并在一个函数里可以提高代码的可读性和简洁性，让代码量变少了。可以注意到`get_pte(pde_t *pgdir, uintptr_t la, bool create)`中存在一个create位，可以正确的区分查找与分配。

然而，如果这两个功能在其他地方需要单独使用，或者有不同的使用场景和需求，拆分成两个函数可能更合适。

比如在我们的`do_pgfault`函数中

```c
 ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
                                         //PT(Page Table) isn't existed, then
                                         //create a PT.
  if (*ptep == 0) { //说明这个页表映射的物理页还不存在，要分配一个页给它映射
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) { //这里创建页面，建立关于addr虚拟地址的映射
        //注意这个创建页面alloc_page()都可能用到置换
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            goto failed;// 分配物理页失败，转到错误处理分支
        }
    } else { 
        if (swap_init_ok) {
            struct Page *page = NULL;//是准备读取进来的一个物理页
            swap_in(mm, addr, &page);  //这个里面有alloc_page可能缺页置换，然后把换出去的位于磁盘的页读取至新页page
            page_insert(mm->pgdir, page, addr, perm); //更新页表，插入新的页表项
           
            // setup the map of phy addr <---> virtual addr
            swap_map_swappable(mm, addr, page, 1);  //(3) make the page swappable.
            page->pra_vaddr = addr;
        } 
```

可以发现它们都要调用`page_insert`函数(第一个if是在`pgdir_alloc_page`中调用)，但是这个函数里面get_pte会创建映射关系。

但是显然在else分支里面，我们是存在映射关系，只需要进行更新addr之前映射里面对应的pte。所以这里实际上存在一定瑕疵，可以将查找pte与建立pte分开写，这样会更加清晰。

## 练习3 给未被映射的地址映射上物理页

>补充完成do_pgfault（mm/vmm.c）函数，给未被映射的地址映射上物理页。设置访问权限 的时候需要参考页面所在 VMA 的权限，同时需要注意映射物理页时需要操作内存控制 结构所指定的页表，而不是内核的页表。
>
>请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
>- 请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。
>- 如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？
> - 数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是啥？

---

### 1.设计实现过程

#### **函数参数:**

```c
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) 
```

第一个是一个`mm_struct`变量，其中保存了所使用的`PDT`，合法的虚拟地址空间（使用链表组织），以及与后文的swap机制相关的数据；

第二个参数是产生pagefault的时候硬件产生的`error code`，可以用于帮助判断发生page fault的原因

最后一个参数则是出现`page fault`的线性地址（保存在cr2寄存器中的线性地址）；

#### **函数的前期分析：**

```c
  int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);

    pgfault_num++;
    //If the addr is in the range of a mm's vma?
    //非法地址，或者地址不在vma的范围内
    if (vma == NULL || vma->vm_start > addr) {
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
        goto failed;
    }
    //考虑地址错误的情况
    /* IF (write an existed addr ) OR
     *    (write an non_existed addr && addr is writable) OR
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {//权限级别，即如果vma->vm_flags 中包含 VM_WRITE 标志位
        perm |= (PTE_R | PTE_W); 
    }
    addr = ROUNDDOWN(addr, PGSIZE);//向下取整，虚拟地址也要页对齐，与页表构造一致。

    ret = -E_NO_MEM;

    pte_t *ptep=NULL;
  //我们用到一个虚拟地址才会建立映射，为它分配物理页
   //这里有两种情况，一个是还没有分配物理页，另一个是已经分配了物理页，但是被换出去了
    ptep = get_pte(mm->pgdir, addr, 1);  //(1) try to find a pte, if pte's
                                         //PT(Page Table) isn't existed, then
                                         //create a PT.
    if (*ptep == 0) { //说明这个页表映射的物理页还不存在，要分配一个页给它映射
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) { //这里创建页面，建立关于addr虚拟地址的映射
        //注意这个创建页面alloc_page()都可能用到置换
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            goto failed;// 分配物理页失败，转到错误处理分支
        }
    }
```

- 首先在维护vma的mm_struct中查找，找到虚拟地址对应的vma(一段连续的虚拟地址)。
- 判断找到的vma与addr是否合法。
- 因为是处理缺页，所以之后会申请一个页，现在根据vma的权限级别，为之后设置页表项的标志位做准备。
- 开始查找addr在三级页表映射中对应的pte。
- 如果查找失败，说明是第一次访问该虚拟地址，要创建新的映射。在上面的if语句中调用`pgdir_alloc_page(mm->pgdir, addr, perm)`
  - `pgdir_alloc_page(mm->pgdir, addr, perm)`具体会先`alloc_page()`，在里面分配页的时候就会判断当前有无剩余空闲页，若无空闲页需要页的置换，而在置换的过程中，需要将某个页换出，在处理换出的页的时候，有`swap_out`函数的参与。
  - 然后会创建映射关系，`page_insert(pgdir, page, la, perm)`，在里面会首先用到`get_pte` 创建二级页表、一级页表，对应映射关系。在创建完后，这个时候获取的pte显然没有被赋值，这个时候需要将之前分配的物理页号设置给pte，将Pte相关值设置好，同时也要将物理页对应的page结构体的ref属性设置。

#### **练习3补全的代码：**

```c
else { 
        //说明有这个映射关系，但是物理页被换到磁盘了，需要读取进来
        /*LAB3 EXERCISE 3: 2113665
        * 请你根据以下信息提示，补充函数
        * 现在我们认为pte是一个交换条目，那我们应该从磁盘加载数据并放到带有phy addr的页面，
        * 并将phy addr与逻辑addr映射，触发交换管理器记录该页面的访问情况
        *
        *  一些有用的宏和定义，可能会对你接下来代码的编写产生帮助(显然是有帮助的)
        *  宏或函数:
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
            struct Page *page = NULL;//是准备读取进来的一个物理页
            swap_in(mm, addr, &page);  //这个里面有alloc_page可能缺页置换，然后把换出去的位于磁盘的页读取至新页page
            page_insert(mm->pgdir, page, addr, perm); //更新页表，插入新的页表项
           
            // setup the map of phy addr <---> virtual addr
            swap_map_swappable(mm, addr, page, 1); 
            page->pra_vaddr = addr;
        } else {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
}
```

上面的代码是需要补全的部分，这里可以看出来需要补全的else分支是——页表中存在映射但是被换入磁盘的情况。

所以这里的补全思路在于：

- 首先判断swap相关函数是否准备好
- 申请一个页，把之前换出去位于磁盘的页的数据读取进来，`swap_in(mm, addr, &page)`
  - 首先调用`alloc_page`，此函数的作用是分配一个新页。如果当前有空闲页，直接分配，如果没有，那么先换出一个页，释放空间后再分配。
  - 现在已经拿到一个页，进行换入操作，即把之前位于磁盘的数据读取至这个页，返回给Page。首先获取addr对应的Pte项，这个时候的Pte具有swap_entry_t结构，所以可以利用Pte找到磁盘的偏移，`swap_offset(pte) * PAGE_NSECT`，这里按照一扇区512字节大小。最后调用` swapfs_read`进行读取数据即可。
- 调用`page_insert`，将pte更新，pte的项的值更新为page的物理页号，以及物理页的一些位的标识(PTE_V|perm)。
- 最后，由于我们管理页的换出算法需要一个链表mm->sm_priv，所以调用` swap_map_swappable`，将该页链接到此链表。
- 设置page的pra_vaddr属性，作用是为页置换提供page指向的虚拟地址参数。

### 2.相关问题回答

#### 2.1  pde与pte对页替换算法用处

> 请描述页目录项（Page Directory Entry）和页表项（Page Table Entry）中组成部分对ucore实现页替换算法的潜在用处。

##### **1.综合而言：**

sv39中，页目录项中有对应的下一级页表的基址，以及一些标志位，与pte大致结构相同。

页表项（pte）有对应的物理页号，PTE_U，PTE_W，PTE_R，PTE_X;通过基址，ucore可以找到page table 的物理地址；PTE_U代表用户态是否可以通过页表项映射，PTE_W代表page table是否可写，然后W，X，R许可位，可以表示映射的下一级是页表的地址，还是虚拟地址所映射的物理页。通过PTE_U，PTE_W，PTE_R，PTE_X，ucore可以更好的管理页表系统。

- 此外PTE中还有dirty位，用于表示当前的页是否经过修改，这就使得OS可以使用这个位来判断是否可以省去某些已经在外存中存在着，内存中的数据与外存相一致的物理页面换出到外存这种多余的操作；
- 而PTE和PDE中均有表示是否被使用过的位(Access)，这就使得OS可以粗略地得知当前的页面是否具有着较大的被访问概率，使得OS可以利用程序的局部性原理来对也替换算法进行优化(时钟替换算法中使用)；

##### **2.具体来说：**

页替换算法，即实现缺页置换。其中，页目录项（pde）的结构与页表项(pte)的结构是一致的，如下。

```c
// Sv39 page table entry:
// +----26---+----9---+----9---+---2----+-------8-------+
// |  PPN[2] | PPN[1] | PPN[0] |Reserved|D|A|G|U|X|W|R|V|
// +---------+----+---+--------+--------+---------------+

```

但是它们存储的ppn显然含义不同。其中**pde的ppn存储的是下一级页表的物理页号**，通过该pde的值，我们可以找到下一级映射的页表的地址，从而获取下一级pde/pte的值；而**pte的ppn存储的是最后虚拟地址映射到的物理页的页号**。

**而当一个页被替换出去，pte的结构会发生改变，变为下面swap_entry_t的结构**，其中offset存储的是被替换在磁盘的页号/页索引((page->pra_vaddr/PGSIZE+1)<<8)。

```c
/* *
 * swap_entry_t
 * --------------------------------------------
 * |         offset        |   reserved   | 0 |
 * --------------------------------------------
 *           24 bits            7 bits    1 bit
 * */
```

在进行页替换算法时，有两种情况:

- 一种是新访问某合法虚拟地址，需要对他分配页进行映射关系的建立，这个时候调用`(pgdir_alloc_page(mm->pgdir, addr, perm)`。
  - 在其中首先会`alloc_page()`，在里面分配页的时候就会判断当前有无剩余空闲页，若无空闲页需要页的置换，而在置换的过程中，需要将某个页换出，在处理换出的页的时候，有`swap_out`函数的参与，它会用到pte。因为我们需要将换出的页所对应的Pte进行赋值，将其变为swap_entry_t，而在这个过程中会用到`get_pte`，通过pgdir三级页表地址，不停地用pde，将Pde转为下一级页表的地址，最终找到对应的Pte，而最后将pte变为上述swap_entry_t的结构。
  - 在分配完页后，我们要将对应的页建立好映射关系，在其中会用到`page_insert(pgdir, page, la, perm)`，在里面会首先用到`get_pte` 创建二级页表、一级页表，对应映射关系，显然在里面会用到pde，pde的值都设置为与下一级页表地址相关的信息。在创建完后，这个时候获取的pte显然没有被赋值，这个时候需要将之前分配的物理页号设置给pte，将Pte相关值设置好，便于我们之后正常的访问内存，mmu对虚拟地址的转换。
- 第二种是之前的虚拟地址对应的物理页被换出去了，Pte保存了其在磁盘中的位置信息，这个时候需要将其换进来。
  - 首先调用`swap_in(mm, addr, &page);`
    - 具体来说，在其中先`alloc_page()`，里面同第一种情况，也可能会换出某个页，在`swap_out`中会用到pte，即首先找到要换出去页的pte,显然是通过pdt找的，最后再将Pte设置为swap_entry_t的结构。
    - 然后查找到addr对应的pte,显然在`get_pte`会用到pdt的值，按照三级映射的关系，用Pdt查找到最后一级页表的pte项。
    - 由于被换出，此时查找到的pte是swap_entry_t结构，调用`swapfs_read((*ptep), result))`即可将之前换到磁盘的值复制给result物理页。
    - 最后实现了，将虚拟地址addr在磁盘的信息写入page对应的物理页。
  - 然后调用`page_insert(mm->pgdir, page, addr, perm)`，由于之前的映射关系仍然存在，所以只用将将pte的值进行更新，由于之前addr所映射的pte是磁盘信息，现在将其更改为所映射的物理页page的信息。具体也是先通过pgdir,pdt，按照三级映射的模式进行查找，找到pte，最后设置即可。
  - 最后完成其他设置即可。

---

#### 2.2 硬件在页访问异常时的作用

1. 问题1

> 如果ucore的缺页服务例程在执行过程中访问内存，出现了页访问异常，请问硬件要做哪些事情？

- 将发生错误的线性地址保存在控制寄存器2（CR2）中。其中CR2寄存器用于存储最近一次导致页访问异常的线性地址。
- 保存上下文。在中断栈中依次压入EFLAGS，CS, EIP，以及页访问异常码error code，其中scause保存的是error code。然后硬件会切换到内核态。
- 根据中断描述符表(stvec)查询到对应页访问异常的ISR(Interrupt Service Routine)，跳转到对应的ISR处执行，接下来将由软件进行处理，即相关缺页置换算法等。
- 最后恢复上下文，sret 指令把pc赋值为sepc，用于S态返回U态。

2. 问题2

>数据结构Page的全局变量（其实是一个数组）的每一项与页表中的页目录项和页表项有无对应关系？如果有，其对应关系是啥？

- 页目录表pd1中存放着数个页目录项pde，这些页目录项中存放了某个二级页表pd0所在物理页的物理页号。
- 页目录表pd0存放数个页目录项pde，这些页目录项存放着某个一级页表pt所在物理页的物理页号。
- 页表pt存放着数个页表项，这些页表项存放着某个物理页对应的物理页号。

可以发现，页表中的页目录项和页表项的值都是某个物理页的物理页号。这与page中是相关的。因为page管理的就是物理页。

```c
static inline struct Page *pte2page(pte_t pte) {
    if (!(pte & PTE_V)) {
        panic("pte2page called with invalid pte");
    }
    return pa2page(PTE_ADDR(pte));
}

static inline struct Page *pde2page(pde_t pde) {
    return pa2page(PDE_ADDR(pde));
}
```

如上面的代码，可以首先将pte/pde中的物理页号相关信息，转为物理页的地址，最后将物理地址转为page的地址，这样可以用page管理相关物理页。所以存在如上关系

## [练习4] 补充完成Clock页替换算法

> 通过之前的练习，相信大家对FIFO的页面替换算法有了更深入的了解，现在请在我们给出的框架上，填写代码，实现 Clock页替换算法（mm/swap_clock.c）。(提示:要输出curr_ptr的值才能通过make grade)
>
> 请在实验报告中简要说明你的设计实现过程。请回答如下问题：
>
> - 比较Clock页替换算法和FIFO算法的不同。

---

### 1 . 设计思路：

我们补充的代码主要基于三个部分，分别为`_clock_init_mm`，`_clock_map_swappable`，`_clock_swap_out_victim`。

#### 1) . 初始化链表 —— _clock_init_mm

首先是`_clock_init_mm`的补充与解释：

```c
static int
_clock_init_mm(struct mm_struct *mm)
{     
     /*LAB3 EXERCISE 4: 2113663*/ 
     // 初始化pra_list_head为空链表
     // 初始化当前指针curr_ptr指向pra_list_head，表示当前页面替换位置为链表头
     // 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     list_init(&pra_list_head);
     curr_ptr = &pra_list_head;
     mm->sm_priv = &pra_list_head;
     return 0;
}
```

这段代码是时钟置换算法的初始化部分的代码，其中`pra_list_head`为链表头，后面是用于存放我们可以换入换出的页的。`curr_ptr`是一个当前指针，时钟算法后面就是通过它来标记要换出的页面。`mm->sm_priv`用与存放链表。所以此段代码首先初始化存放页面的链表为空链表，然后把当前指针指向链表头的地址，并且把这个空链表交给`mm`结构体指针进行管理。

#### 2) . 把页面加入链表进行维护  ——  _clock_map_swappable

其次是`_clock_map_swappable`的补充与解释：

```c
static int
_clock_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *entry=&(page->pra_page_link);
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
    assert(entry != NULL && curr_ptr != NULL);
    //record the page access situlation
    /*LAB3 EXERCISE 4: 2113665*/ 
    // link the most recent arrival page at the back of the pra_list_head qeueue.
    // 将页面page插入到页面链表pra_list_head的末尾
    // 将页面的visited标志置为1，表示该页面已被访问
    assert(entry != NULL && head != NULL);
    list_add(head, entry);//插到末尾
    if(curr_ptr==head){ //刚开始初始化，要把curr_ptr更新为一个最老页的指针
        curr_ptr=entry;
    }
    page->visited=1;//该页已被访问
    return 0;
}
```

由于我们维护的链表中的页的顺序是从新到老，所以当我们向链表里面加入一个最新的页时我们只需把它加在链表头的后向即可，然后将其访问位置1。如果此链表在加入此页之前是个空链表，那么我们需要更新一下当前指针`curr_ptr`，将其更新为指向这个新的`Page`结构体，这便可以正确标记出了最老的页。



#### 3) . 寻找要被换出的页 —— _clock_swap_out_victim

最后是对`_clock_swap_out_victim`的补充和解释：

```c
static int
_clock_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
         assert(head != NULL);
     assert(in_tick==0);
     /* Select the victim */
     //(1)  unlink the  earliest arrival page in front of pra_list_head qeueue
     //(2)  set the addr of addr of this page to ptr_page
     list_entry_t *temp=curr_ptr;
     if(temp==head){
        *ptr_page=NULL;//如果等于head，说明不可以换
        return 0;
     }
    cprintf("curr_ptr %p\n",curr_ptr);
    while (1) {
        /*LAB3 EXERCISE 4: 2113665*/ 
        // 编写代码
        // 遍历页面链表pra_list_head，查找最早未被访问的页面
        // 获取当前页面对应的Page结构指针
        // 如果当前页面未被访问，则将该页面从页面链表中删除，并将该页面指针赋值给ptr_page作为换出页面
        // 如果当前页面已被访问，则将visited标志置为0，表示该页面已被重新访问
        //一直环形绕圈找，一定可以找到一个
        struct Page* temp_page=le2page(temp,pra_page_link);
        if(temp_page->visited==0){
            cprintf("curr_ptr %p\n",temp);  //打印选择的entry
            curr_ptr=list_prev(temp);//前一个作为新的最久未访问
            list_del(temp);//把temp删掉
            *ptr_page=temp_page;
            break;
        }
        else{
            temp_page->visited=0;//访问位置为0
            temp=list_prev(temp);//前移
        }
    }
    return 0;
}
```

此函数用于页面置换，需要从链表中挑选出一个页将其换出。我们从`curr_ptr`开始，一直前向遍历此链表寻找访问位为0的`Page`结构体。如果我们在遍历的过程中遇到当前页面已被访问，则将`visited`标志置为0，表示该页面已被重新访问。我们如果在访问第一圈没有找到访问位为0的页面，那么在第二圈必定能找到访问位为0的页面。因为第一圈之后所有页面的访问位必定会为0，然后根据链表中页面的新老关系便能找到要换出的页。



### 2 . Clock页替换算法和FIFO算法的不同

Clock页替换算法和FIFO算法的不同点主要集中体现在以下方面：

1.  对于页面的分配原理不同：FIFO算法根据先进先出的原则，每次分配最早进入队列的页面；时钟页替换算法根据页面的访问情况来进行页面分配，具体是每次从当前指针开始寻找访问位为0的页面；
2. 访问位是否使用：FIFO算法对访问位不考虑，只考虑页面进入链表的时间，每次寻找最早进入链表的页面；而时钟算法会根据页面的访问位来判断页面的使用情况，从而选择是否进行置换；
3. 实现难度：由于不涉及访问位，FIFO算法实现简单并且运行效率高，复杂度为O(1)；而时钟置换算法由于涉及访问位，实现较为复杂，运行的复杂度为O(n)，没有FIFO算法实现简单、运行效率高；
4. 选择的页面是否更符合实际情况：FIFO算法不能考虑页面的使用情况和重要性，可能会置换掉一些经常访问的页面。时钟算法虽然更为复杂，但是它能够根据页面的使用情况来进行置换，更加符合实际性；
5. 是否存在Belady现象：FIFO算法存在一个很大的问题就是Belady现象，其大大影响了操作系统的运行效率。而时钟置换算法却并不存在Belady现象。



## [练习5] 理解页表映射方式相关知识

> 如果我们采用”一个大页“ 的页表映射方式，相比分级页表，有什么好处、优势，有什么坏处、风险？

"**一个大页**"的映射方式即为将连续的虚拟地址空间映射到大尺寸的物理页上，它仅仅只有一个页表，一个页表项映射1GiB的物理内存；而多级页表的映射方式便是按照一定的层级结构来管理虚拟地址和物理地址映射关系，通过对虚拟地址分割和层次化来实现对虚拟地址空间的有效管理。

### 1 . 好处与优势

"**一个大页**"的映射方式相比于分级页表的好处与优势体现在：

1. 页表项的数量少，对内存需求更小。使用"一个大页"的映射方式，每个页表项可以映射1GiB的内存，所以页表所需要的页表项数量会减少。这也就减少了因为存储页表而耗费的内存需求；
2. TLB的命中率增加。TLB会存储最近访问的页表项，由于"一个大页"的映射方式每个页表项映射的内存大小更大，所以TLB的命中率会大大提高；
3. 降低了查找访问时间。"一个大页"的映射方式只有一级页表，所以查找访问页表项的时间大大降低；
4. 当对物理内存的访问权限相差不大时，"一个大页"的映射方式能够对这些平等的物理内存统筹管理，效率较高。



### 2 . 坏处和风险

"**一个大页**"的映射方式相比于分级页表的坏处和风险体现在：

1. 虚拟地址空间难以分割小块化。"一个大页"的映射方式在使用时要求连续的虚拟地址空间才能映射一个大页。这要求一个页表项必须要有1GiB的连续虚拟空间与之对应。这在很大程度上限制了我们对虚拟地址空间进行分割、精细化；
2. 访问权限难以划分。实际场景运用时，我们的物理内存的访问权限其实不都是相同的。比如说内核代码等是不能随便访问的，有些内存又是可以读写访问的。这也就导致了在一个页表项映射的高达1GiB的物理内存中，可能存在访问权限不统一的情况；
3. 页表项访问权限随意设置可能会导致内核代码等重要区域内容的修改，带来巨大风险。如果因为一个页表项权限的错误设置，导致内核代码等重要区域的内容被设置为可读写。那么极有可能会导致内核代码等重要区域内容的修改，造成无法估计的后果；
4. 遗留大量碎片，精细化管理不够。"一个大页"的映射方式会导致内存分配中最低就是以1GiB分配内存。可是往往我们不会用到如此大的内存。这就导致了每个我们分配出去的物理内存区域有大量的空闲区域没有使用，这是对内存的极大浪费。

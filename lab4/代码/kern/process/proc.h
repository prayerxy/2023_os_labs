#ifndef __KERN_PROCESS_PROC_H__
#define __KERN_PROCESS_PROC_H__

#include <defs.h>
#include <list.h>
#include <trap.h>
#include <memlayout.h>


// process's state in his life cycle
enum proc_state {
    PROC_UNINIT = 0,  // uninitialized  未初始化
    PROC_SLEEPING,    // sleeping  等待
    PROC_RUNNABLE,    // runnable(maybe running)  就绪
    PROC_ZOMBIE,      // almost dead, and wait parent proc to reclaim his resource 将死状态
};

//线程切换在一个函数中，编译器会自动保存调用者保存寄存器的代码，所以只需要保存被调用者保存寄存器的值
struct context {//关键寄存器的值的存储
    uintptr_t ra;
    uintptr_t sp;
    uintptr_t s0;
    uintptr_t s1;
    uintptr_t s2;
    uintptr_t s3;
    uintptr_t s4;
    uintptr_t s5;
    uintptr_t s6;
    uintptr_t s7;
    uintptr_t s8;
    uintptr_t s9;
    uintptr_t s10;
    uintptr_t s11;
};

#define PROC_NAME_LEN               15
#define MAX_PROCESS                 4096
#define MAX_PID                     (MAX_PROCESS * 2)

extern list_entry_t proc_list;

struct proc_struct {
    enum proc_state state;                      // Process state 进程所处状态
    int pid;                                    // Process ID  进程ID,用于确认线程身份
    int runs;                                   // the running times of Proces  此线程运行的次数
    uintptr_t kstack;                           // Process kernel stack 线程的内核栈的位置
    // 对于内核线程而言，该栈是运行时的程序使用的栈 Kstacksize为2个物理页
    volatile bool need_resched;                 // bool value: need to be rescheduled to release CPU?
    // 是否需要被重新调度，以使当前线程让出cpu
    struct proc_struct *parent;                 // the parent process 进程的父进程指针
    struct mm_struct *mm;                       // Process's memory management field
    struct context context;                     // Switch here to run process 保存进程执行的上下文
    struct trapframe *tf;                       // Trap frame for current interrupt 保存进程的中断帧
    uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
    // 页表的起始地址
    uint32_t flags;                             // Process flag
    char name[PROC_NAME_LEN + 1];               // Process name
    list_entry_t list_link;                     // Process link list 
    list_entry_t hash_link;                     // Process hash list
};

#define le2proc(le, member)         \
    to_struct((le), struct proc_struct, member)

extern struct proc_struct *idleproc, *initproc, *current;

void proc_init(void);
void proc_run(struct proc_struct *proc);
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);

char *set_proc_name(struct proc_struct *proc, const char *name);
char *get_proc_name(struct proc_struct *proc);
void cpu_idle(void) __attribute__((noreturn));

struct proc_struct *find_proc(int pid);
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);
int do_exit(int error_code);

#endif /* !__KERN_PROCESS_PROC_H__ */


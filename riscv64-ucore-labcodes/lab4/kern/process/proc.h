#ifndef __KERN_PROCESS_PROC_H__
#define __KERN_PROCESS_PROC_H__

#include <defs.h>
#include <list.h>
#include <trap.h>
#include <memlayout.h>

// 定义进程生命周期中的状态
enum proc_state {
    PROC_UNINIT = 0,  // 未初始化
    PROC_SLEEPING,    // 睡眠状态
    PROC_RUNNABLE,    // 可运行状态（可能正在运行）
    PROC_ZOMBIE,      // 僵尸状态，等待父进程回收资源
};

// 保存上下文切换时的寄存器信息
// 只需要保存被调用者保存寄存器
struct context {
    uintptr_t ra;    // 返回地址寄存器
    uintptr_t sp;    // 栈指针寄存器
    uintptr_t s0;    // 保存寄存器s0
    uintptr_t s1;    // 保存寄存器s1
    uintptr_t s2;    // 保存寄存器s2
    uintptr_t s3;    // 保存寄存器s3
    uintptr_t s4;    // 保存寄存器s4
    uintptr_t s5;    // 保存寄存器s5
    uintptr_t s6;    // 保存寄存器s6
    uintptr_t s7;    // 保存寄存器s7
    uintptr_t s8;    // 保存寄存器s8
    uintptr_t s9;    // 保存寄存器s9
    uintptr_t s10;   // 保存寄存器s10
    uintptr_t s11;   // 保存寄存器s11
};

#define PROC_NAME_LEN               15    // 进程名称的最大长度
#define MAX_PROCESS                 4096  // 最大进程数
#define MAX_PID                     (MAX_PROCESS * 2) // 最大进程ID

extern list_entry_t proc_list;            // 进程链表

// 定义进程结构体，包含进程的各个属性
struct proc_struct {
    enum proc_state state;                      // 进程状态
    int pid;                                    // 进程ID
    int runs;                                   // 进程的运行次数
    uintptr_t kstack;                           // 进程的内核栈指针
    volatile bool need_resched;                 // 是否需要重新调度（释放CPU）
    struct proc_struct *parent;                 // 父进程指针
    struct mm_struct *mm;                       // 进程的内存管理信息
    struct context context;                     // 上下文切换时使用的寄存器信息
    struct trapframe *tf;                       // 当前中断的trap frame
    uintptr_t cr3;                              // CR3寄存器：页目录表基地址
    uint32_t flags;                             // 进程标志
    char name[PROC_NAME_LEN + 1];               // 进程名称
    list_entry_t list_link;                     // 链表链接，用于在进程列表中存储
    list_entry_t hash_link;                     // 哈希链接，用于在哈希表中存储
};

// 将链表项转换为进程结构体的宏
#define le2proc(le, member)         \
    to_struct((le), struct proc_struct, member)

extern struct proc_struct *idleproc, *initproc, *current;  // 特殊的进程指针

// 进程初始化
void proc_init(void);
 
// 运行指定进程
void proc_run(struct proc_struct *proc);

// 创建一个内核线程
int kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags);

// 设置进程名称
char *set_proc_name(struct proc_struct *proc, const char *name);

// 获取进程名称
char *get_proc_name(struct proc_struct *proc);

// 进入空闲状态
void cpu_idle(void) __attribute__((noreturn));

// 根据进程ID查找进程
struct proc_struct *find_proc(int pid);

// 执行fork系统调用
int do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf);

// 退出当前进程
int do_exit(int error_code);

#endif /* !__KERN_PROCESS_PROC_H__ */

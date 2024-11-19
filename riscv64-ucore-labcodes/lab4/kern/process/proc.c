#include <proc.h>
#include <kmalloc.h>
#include <string.h>
#include <sync.h>
#include <pmm.h>
#include <error.h>
#include <sched.h>
#include <elf.h>
#include <vmm.h>
#include <trap.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

/* -----------------进程/线程机制设计与实现简介-----------------
(基于简化的Linux进程/线程机制)
简介:
ucore 实现了一个简单的进程/线程机制。
进程包含独立的内存空间、至少一个用于执行的线程、内核数据（用于管理）、处理器状态（用于上下文切换）、文件等（如lab6中实现）。
ucore 需要高效管理所有这些细节。在 ucore 中，线程是一种特殊的进程（共享进程的内存）。
-------------------------------------------------------------
进程状态：
    PROC_UNINIT     : 未初始化状态          -- 初始分配状态
    PROC_SLEEPING   : 休眠状态              -- 内存释放、等待、睡眠等
    PROC_RUNNABLE   : 可运行状态（可能正在运行） -- 初始化后、被唤醒等
    PROC_ZOMBIE     : 僵尸状态              -- 进程退出后

-------------------------------------------------------------
进程状态切换：
  alloc_proc                                 运行状态
      +                                   +--<----<--+
      +                                   + proc_run +
      V                                   +-->---->--+ 
PROC_UNINIT -- proc_init/wakeup_proc --> PROC_RUNNABLE -- try_free_pages/do_wait/do_sleep --> PROC_SLEEPING --
                                           A      +                                                           +
                                           |      +--- do_exit --> PROC_ZOMBIE                                +
                                           +                                                                  + 
                                           -----------------------wakeup_proc----------------------------------

-------------------------------------------------------------
进程关系：
父进程:           proc->parent  （当前进程是子进程）
子进程:           proc->cptr    （当前进程是父进程）
老兄弟:           proc->optr    （当前进程是较小的兄弟进程）
小兄弟:           proc->yptr    （当前进程是较大的兄弟进程）
-------------------------------------------------------------
进程相关的系统调用：
SYS_exit        : 进程退出                          --> do_exit
SYS_fork        : 创建子进程，复制内存              --> do_fork --> wakeup_proc
SYS_wait        : 等待子进程完成                    --> do_wait
SYS_exec        : 执行程序，刷新内存                --> 加载程序并刷新内存管理
SYS_clone       : 创建子线程                        --> do_fork --> wakeup_proc
SYS_yield       : 标记需要重新调度                  --> proc->need_sched = 1, 调度器将重新调度该进程
SYS_sleep       : 进程睡眠                          --> do_sleep
SYS_kill        : 杀死进程                          --> do_kill --> proc->flags |= PF_EXITING
                                                    --> wakeup_proc --> do_wait --> do_exit   
SYS_getpid      : 获取进程 ID
*/

// 全局进程列表，用于管理所有进程
list_entry_t proc_list;

#define HASH_SHIFT          10                        // 哈希位移量
#define HASH_LIST_SIZE      (1 << HASH_SHIFT)         // 哈希表大小
#define pid_hashfn(x)       (hash32(x, HASH_SHIFT))   // 哈希函数，生成 PID 的哈希值

// 基于 PID 的进程哈希表
static list_entry_t hash_list[HASH_LIST_SIZE];

// 空闲进程
struct proc_struct *idleproc = NULL;
// 初始化进程
struct proc_struct *initproc = NULL;
// 当前运行的进程
struct proc_struct *current = NULL;

static int nr_process = 0; // 当前进程数量

void kernel_thread_entry(void);                      // 内核线程入口
void forkrets(struct trapframe *tf);                 // fork 的返回点
void switch_to(struct context *from, struct context *to); // 上下文切换函数

// alloc_proc - 分配并初始化进程控制块（proc_struct）
static struct proc_struct *
alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct)); // 分配内存
    if (proc != NULL) {
        proc->state = PROC_UNINIT;                      // 初始状态：未初始化
        proc->pid = -1;                                 // PID 未分配
        proc->runs = 0;                                 // 运行次数为 0
        proc->kstack = 0;                               // 内核栈地址未分配
        proc->need_resched = 0;                         // 初始时不需要调度
        proc->parent = NULL;                            // 父进程为空
        proc->mm = NULL;                                // 内存管理未分配
        memset(&(proc->context), 0, sizeof(struct context)); // 清空上下文信息
        proc->tf = NULL;                                // 无中断帧
        proc->cr3 = boot_cr3;                           // 使用内核页目录表
        proc->flags = 0;                                // 标志位为 0
        memset(proc->name, 0, PROC_NAME_LEN+1);         // 进程名清空
    }
    return proc; // 返回已初始化的进程结构体
}

// set_proc_name - 设置进程名称
char *
set_proc_name(struct proc_struct *proc, const char *name) {
    memset(proc->name, 0, sizeof(proc->name));          // 清空原名称
    return memcpy(proc->name, name, PROC_NAME_LEN);     // 复制新名称
}

// get_proc_name - 获取进程名称
char *
get_proc_name(struct proc_struct *proc) {
    static char name[PROC_NAME_LEN + 1];                // 静态数组存储名称
    memset(name, 0, sizeof(name));                      // 清空
    return memcpy(name, proc->name, PROC_NAME_LEN);     // 复制名称
}

// get_pid - 分配唯一的 PID 给进程
static int
get_pid(void) {
    static_assert(MAX_PID > MAX_PROCESS); // 确保最大 PID 大于最大进程数
    struct proc_struct *proc;             // 临时进程指针
    list_entry_t *list = &proc_list, *le; // 指向进程列表的指针
    static int next_safe = MAX_PID, last_pid = MAX_PID; // 静态变量用于生成 PID
    if (++last_pid >= MAX_PID) {          // 如果超出最大值，重置为 1
        last_pid = 1;
        goto inside; 
    }
    if (last_pid >= next_safe) {
        inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        while ((le = list_next(le)) != list) {          // 遍历链表
            proc = le2proc(le, list_link);
            if (proc->pid == last_pid) { 
                if (++last_pid >= next_safe) {          // 遇到重复则递增 PID
                    if (last_pid >= MAX_PID) {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid) {
                next_safe = proc->pid;                 // 更新 next_safe
            }
        }
    }
    return last_pid;                                   // 返回分配的 PID
}
// proc_run - 将指定的进程 "proc" 设置为当前运行的进程
// 注意：在调用 switch_to 之前，应加载新进程的页目录表地址
void
proc_run(struct proc_struct *proc) {
    if (proc != current) { // 如果新进程不是当前正在运行的进程
        // 需要保存和恢复中断状态以确保安全
        bool intr_flag;
        local_intr_save(intr_flag); // 禁用中断并保存中断状态
        struct proc_struct *temp = current; // 保存当前进程
        current = proc;                    // 切换到新进程
        lcr3(current->cr3);                // 加载新进程的页目录表地址到 CR3 寄存器
        switch_to(&(temp->context), &(proc->context)); // 执行上下文切换
        local_intr_restore(intr_flag);     // 恢复中断状态
    }
}

// forkret - 新线程/进程的第一个内核入口点
// 注意：forkret 的地址在 copy_thread 函数中设置
//       在 switch_to 调用之后，当前进程将执行这里的代码
static void
forkret(void) {
    forkrets(current->tf); // 从当前进程的中断帧恢复上下文
}

// hash_proc - 将进程插入到进程哈希表中
static void
hash_proc(struct proc_struct *proc) {
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link)); // 根据 PID 哈希值插入哈希链表
}

// find_proc - 根据 PID 从进程哈希表中查找进程
struct proc_struct *
find_proc(int pid) {
    if (0 < pid && pid < MAX_PID) { // 确保 PID 合法
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
        while ((le = list_next(le)) != list) { // 遍历对应哈希链表
            struct proc_struct *proc = le2proc(le, hash_link); // 从链表节点获取进程结构体
            if (proc->pid == pid) { // 找到匹配的进程
                return proc;
            }
        }
    }
    return NULL; // 未找到匹配的进程
}

// kernel_thread - 创建一个内核线程，使用指定的函数 fn
// 注意：临时中断帧 tf 的内容将在 do_fork --> copy_thread 函数中复制到 proc->tf
int
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
    struct trapframe tf;
    memset(&tf, 0, sizeof(struct trapframe)); // 初始化中断帧
    tf.gpr.s0 = (uintptr_t)fn;               // 设置 s0 为函数入口地址
    tf.gpr.s1 = (uintptr_t)arg;              // 设置 s1 为函数参数
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE; // 设置状态寄存器
    tf.epc = (uintptr_t)kernel_thread_entry; // 设置 EPC 为内核线程入口点
    return do_fork(clone_flags | CLONE_VM, 0, &tf); // 调用 do_fork 创建线程
}

// setup_kstack - 为进程分配大小为 KSTACKPAGE 的内核栈
static int
setup_kstack(struct proc_struct *proc) {
    struct Page *page = alloc_pages(KSTACKPAGE); // 分配 KSTACKPAGE 页的内存
    if (page != NULL) { // 如果分配成功
        proc->kstack = (uintptr_t)page2kva(page); // 设置内核栈地址
        return 0;
    }
    return -E_NO_MEM; // 返回错误码，表示内存不足
}

// put_kstack - 释放进程的内核栈内存
static void
put_kstack(struct proc_struct *proc) {
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE); // 释放与内核栈对应的页
}

// copy_mm - 根据 clone_flags，复制或共享当前进程的内存管理结构
// 如果 clone_flags & CLONE_VM，则共享；否则复制
static int
copy_mm(uint32_t clone_flags, struct proc_struct *proc) {
    assert(current->mm == NULL); // 确保当前进程没有内存管理结构
    /* 在当前项目中不执行实际的操作 */
    return 0;
}

// copy_thread - 设置进程的内核栈和上下文
static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf) {
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe)); // 分配内核栈顶部用于保存中断帧
    *(proc->tf) = *tf; // 复制中断帧内容
    proc->tf->gpr.a0 = 0; // 设置 a0 为 0，表示这是子进程
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp; // 设置栈指针
    proc->context.ra = (uintptr_t)forkret; // 设置返回地址为 forkret
    proc->context.sp = (uintptr_t)(proc->tf); // 设置上下文的栈指针
}

/* do_fork - 为当前进程创建一个子进程
 * @clone_flags: 指导如何克隆子进程
 * @stack:       父进程的用户栈指针，如果为 0，则表示创建内核线程
 * @tf:          中断帧信息，将被复制到子进程的 proc->tf
 */
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC; // 错误码，表示没有空闲进程可用
    struct proc_struct *proc; // 子进程结构体指针

    if (nr_process >= MAX_PROCESS) { // 检查进程数量是否超过最大限制
        goto fork_out; // 如果超过，直接退出
    }

    ret = -E_NO_MEM; // 如果内存分配失败，返回内存不足错误
    proc = alloc_proc(); // 分配一个新的进程控制块
    if (proc == NULL) {
        goto fork_out; // 如果分配失败，退出
    }

    proc->parent = current; // 设置父进程为当前进程

    if (setup_kstack(proc) != 0) { // 为新进程分配内核栈
        goto bad_fork_cleanup_kstack; // 如果分配失败，清理资源
    }

    if (copy_mm(clone_flags, proc) != 0) { // 复制或共享内存管理结构
        goto bad_fork_cleanup_proc; // 如果失败，清理资源
    }

    copy_thread(proc, stack, tf); // 复制线程上下文

    bool intr_flag;
    local_intr_save(intr_flag); // 禁用中断
    proc->pid = get_pid(); // 分配唯一的 PID
    hash_proc(proc); // 将进程插入到哈希表中
    list_add(&proc_list, &(proc->list_link)); // 将进程插入到全局进程列表中
    nr_process++; // 增加进程计数
    local_intr_restore(intr_flag); // 恢复中断

    wakeup_proc(proc); // 唤醒子进程
    ret = proc->pid; // 返回子进程的 PID

fork_out:
    return ret;

bad_fork_cleanup_kstack: // 内核栈分配失败时的清理
    put_kstack(proc);
bad_fork_cleanup_proc: // 内存管理复制失败时的清理
    kfree(proc);
    goto fork_out;
}
// do_exit - 被 sys_exit 调用，用于处理进程退出
// 1. 调用 exit_mmap、put_pgdir 和 mm_destroy 来释放几乎所有的进程内存空间
// 2. 设置进程状态为 PROC_ZOMBIE，然后调用 wakeup_proc 通知父进程回收资源
// 3. 调用调度器切换到其他进程
int
do_exit(int error_code) {
    panic("process exit!!.\n"); // 暂未实现，直接触发内核错误
}

// init_main - 第二个内核线程，用于创建用户主线程 user_main
static int
init_main(void *arg) {
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current)); // 打印 initproc 的信息
    cprintf("To U: \"%s\".\n", (const char *)arg); // 输出传入的字符串参数
    cprintf("To U: \"en.., Bye, Bye. :)\"\n"); // 输出示例信息
    return 0; // 返回 0 表示线程成功运行
}

// proc_init - 创建并设置第一个内核线程 idleproc，同时创建第二个内核线程 init_main
void
proc_init(void) {
    int i;

    list_init(&proc_list); // 初始化全局进程链表
    for (i = 0; i < HASH_LIST_SIZE; i++) {
        list_init(hash_list + i); // 初始化进程哈希表的每个链表
    }

    if ((idleproc = alloc_proc()) == NULL) { // 分配第一个内核线程 idleproc
        panic("cannot alloc idleproc.\n"); // 如果分配失败，触发内核错误
    }

    // 校验 idleproc 结构体是否正确初始化
    int *context_mem = (int *)kmalloc(sizeof(struct context)); // 临时内存用于比较
    memset(context_mem, 0, sizeof(struct context)); // 清空临时内存
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context)); // 比较上下文初始化状态

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN); // 临时内存用于比较进程名
    memset(proc_name_mem, 0, PROC_NAME_LEN); // 清空临时内存
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN); // 比较进程名初始化状态

    // 如果所有字段都初始化正确，则打印验证信息
    if (idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
        && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0
        && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL
        && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag) {
        cprintf("alloc_proc() correct!\n");
    }
    
    // 初始化 idleproc 的字段
    idleproc->pid = 0; // 设置 PID 为 0
    idleproc->state = PROC_RUNNABLE; // 设置为可运行状态
    idleproc->kstack = (uintptr_t)bootstack; // 设置内核栈为内核启动栈
    idleproc->need_resched = 1; // 标记需要重新调度
    set_proc_name(idleproc, "idle"); // 设置进程名为 "idle"
    nr_process++; // 增加进程计数

    current = idleproc; // 当前运行的进程设置为 idleproc

    // 创建 init_main 线程
    int pid = kernel_thread(init_main, "Hello world!!", 0);
    if (pid <= 0) { // 如果线程创建失败，触发内核错误
        panic("create init_main failed.\n");
    }
    initproc = find_proc(pid); // 根据 PID 查找 init_main 线程的进程结构体
    set_proc_name(initproc, "init"); // 设置进程名为 "init"

    // 验证 idleproc 和 initproc 是否正确初始化
    assert(idleproc != NULL && idleproc->pid == 0);
    assert(initproc != NULL && initproc->pid == 1);
}

// cpu_idle - 在 kern_init 的最后，idleproc 执行该函数
void
cpu_idle(void) {
    while (1) { // 进入无限循环，确保 CPU 不空转
        if (current->need_resched) { // 如果需要重新调度
            schedule(); // 调用调度器进行任务切换
        }
    }
}

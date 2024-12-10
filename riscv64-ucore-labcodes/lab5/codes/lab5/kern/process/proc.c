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
#include <unistd.h>
#include <cow.h>
 
/* ------------- process/thread mechanism design&implementation -------------
(an simplified Linux process/thread mechanism )
introduction:
  ucore implements a simple process/thread mechanism. process contains the independent memory sapce, at least one threads
for execution, the kernel data(for management), processor state (for context switch), files(in lab6), etc. ucore needs to
manage all these details efficiently. In ucore, a thread is just a special kind of process(share process's memory).
------------------------------
process state       :     meaning               -- reason
    PROC_UNINIT     :   uninitialized           -- alloc_proc
    PROC_SLEEPING   :   sleeping                -- try_free_pages, do_wait, do_sleep
    PROC_RUNNABLE   :   runnable(maybe running) -- proc_init, wakeup_proc, 
    PROC_ZOMBIE     :   almost dead             -- do_exit

-----------------------------
process state changing:
                                            
  alloc_proc                                 RUNNING
      +                                   +--<----<--+
      +                                   + proc_run +
      V                                   +-->---->--+ 
PROC_UNINIT -- proc_init/wakeup_proc --> PROC_RUNNABLE -- try_free_pages/do_wait/do_sleep --> PROC_SLEEPING --
                                           A      +                                                           +
                                           |      +--- do_exit --> PROC_ZOMBIE                                +
                                           +                                                                  + 
                                           -----------------------wakeup_proc----------------------------------
-----------------------------
process relations
parent:           proc->parent  (proc is children)
children:         proc->cptr    (proc is parent)
older sibling:    proc->optr    (proc is younger sibling)
younger sibling:  proc->yptr    (proc is older sibling)
-----------------------------
related syscall for process:
SYS_exit        : process exit,                           -->do_exit
SYS_fork        : create child process, dup mm            -->do_fork-->wakeup_proc
SYS_wait        : wait process                            -->do_wait
SYS_exec        : after fork, process execute a program   -->load a program and refresh the mm
SYS_clone       : create child thread                     -->do_fork-->wakeup_proc
SYS_yield       : process flag itself need resecheduling, -- proc->need_sched=1, then scheduler will rescheule this process
SYS_sleep       : process sleep                           -->do_sleep 
SYS_kill        : kill process                            -->do_kill-->proc->flags |= PF_EXITING
                                                                 -->wakeup_proc-->do_wait-->do_exit   
SYS_getpid      : get the process's pid

*/

// the process set's list
list_entry_t proc_list;

#define HASH_SHIFT          10
#define HASH_LIST_SIZE      (1 << HASH_SHIFT)
#define pid_hashfn(x)       (hash32(x, HASH_SHIFT))

// has list for process set based on pid
static list_entry_t hash_list[HASH_LIST_SIZE];

// idle proc
struct proc_struct *idleproc = NULL;
// init proc
struct proc_struct *initproc = NULL;
// current proc
struct proc_struct *current = NULL;

static int nr_process = 0;

void kernel_thread_entry(void);
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
    //LAB4:EXERCISE1 YOUR CODE
    /*
     * below fields in proc_struct need to be initialized
     *       enum proc_state state;                      // Process state
     *       int pid;                                    // Process ID
     *       int runs;                                   // the running times of Proces
     *       uintptr_t kstack;                           // Process kernel stack
     *       volatile bool need_resched;                 // bool value: need to be rescheduled to release CPU?
     *       struct proc_struct *parent;                 // the parent process
     *       struct mm_struct *mm;                       // Process's memory management field
     *       struct context context;                     // Switch here to run process
     *       struct trapframe *tf;                       // Trap frame for current interrupt
     *       uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
     *       uint32_t flags;                             // Process flag
     *       char name[PROC_NAME_LEN + 1];               // Process name
     */

     //LAB5 YOUR CODE : (update LAB4 steps)
     /*
     * below fields(add in LAB5) in proc_struct need to be initialized  
     *       uint32_t wait_state;                        // waiting state
     *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
     */
        proc->state = PROC_UNINIT;
        proc->pid = -1;
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&(proc->context), 0, sizeof(struct context));
        proc->tf = NULL;
        proc->cr3 = boot_cr3;
        proc->flags = 0;
        memset(proc->name, 0, PROC_NAME_LEN);
        proc->wait_state = 0;
        proc->cptr = NULL;
        proc->optr = NULL;
        proc->yptr = NULL;
    }
    return proc;
}

// set_proc_name - set the name of proc
char *
set_proc_name(struct proc_struct *proc, const char *name) {
    memset(proc->name, 0, sizeof(proc->name));
    return memcpy(proc->name, name, PROC_NAME_LEN);
}

// get_proc_name - get the name of proc
char *
get_proc_name(struct proc_struct *proc) {
    static char name[PROC_NAME_LEN + 1];
    memset(name, 0, sizeof(name));
    return memcpy(name, proc->name, PROC_NAME_LEN);
}

// set_links - set the relation links of process
static void
set_links(struct proc_struct *proc) {
    list_add(&proc_list, &(proc->list_link));
    proc->yptr = NULL;
    if ((proc->optr = proc->parent->cptr) != NULL) {
        proc->optr->yptr = proc;
    }
    proc->parent->cptr = proc;
    nr_process ++;
}

// remove_links - clean the relation links of process
static void
remove_links(struct proc_struct *proc) {
    list_del(&(proc->list_link));
    if (proc->optr != NULL) {
        proc->optr->yptr = proc->yptr;
    }
    if (proc->yptr != NULL) {
        proc->yptr->optr = proc->optr;
    }
    else {
       proc->parent->cptr = proc->optr;
    }
    nr_process --;
}

// get_pid - alloc a unique pid for process
static int
get_pid(void) {
    static_assert(MAX_PID > MAX_PROCESS);
    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
    static int next_safe = MAX_PID, last_pid = MAX_PID;
    if (++ last_pid >= MAX_PID) {
        last_pid = 1;
        goto inside;
    }
    if (last_pid >= next_safe) {
    inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        while ((le = list_next(le)) != list) {
            proc = le2proc(le, list_link);
            if (proc->pid == last_pid) {
                if (++ last_pid >= next_safe) {
                    if (last_pid >= MAX_PID) {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid) {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}

// proc_run - make process "proc" running on cpu
// NOTE: before call switch_to, should load  base addr of "proc"'s new PDT
void
proc_run(struct proc_struct *proc) {
    if (proc != current) {
        // LAB4:EXERCISE3 YOUR CODE
        /*
        * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
        * MACROs or Functions:
        *   local_intr_save():        Disable interrupts
        *   local_intr_restore():     Enable Interrupts
        *   lcr3():                   Modify the value of CR3 register
        *   switch_to():              Context switching between two processes
        */
        bool intr_flag;
        struct proc_struct *prev = current, *next = proc;
        local_intr_save(intr_flag);
        {
            current = proc;
            lcr3(next->cr3);
            switch_to(&(prev->context), &(next->context));
        }
        local_intr_restore(intr_flag);

    }
}

// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
}

// hash_proc - add proc into proc hash_list
static void
hash_proc(struct proc_struct *proc) {
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
}

// unhash_proc - delete proc from proc hash_list
static void
unhash_proc(struct proc_struct *proc) {
    list_del(&(proc->hash_link));
}

// find_proc - find proc frome proc hash_list according to pid
struct proc_struct *
find_proc(int pid) {
    if (0 < pid && pid < MAX_PID) {
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
        while ((le = list_next(le)) != list) {
            struct proc_struct *proc = le2proc(le, hash_link);
            if (proc->pid == pid) {
                return proc;
            }
        }
    }
    return NULL;
}

// kernel_thread - create a kernel thread using "fn" function
// NOTE: the contents of temp trapframe tf will be copied to 
//       proc->tf in do_fork-->copy_thread function
int
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
    struct trapframe tf;
    memset(&tf, 0, sizeof(struct trapframe));
    tf.gpr.s0 = (uintptr_t)fn;
    tf.gpr.s1 = (uintptr_t)arg;
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
    tf.epc = (uintptr_t)kernel_thread_entry;
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
}

// setup_kstack - alloc pages with size KSTACKPAGE as process kernel stack
static int
setup_kstack(struct proc_struct *proc) {
    struct Page *page = alloc_pages(KSTACKPAGE);
    if (page != NULL) {
        proc->kstack = (uintptr_t)page2kva(page);
        return 0;
    }
    return -E_NO_MEM;
}

// put_kstack - free the memory space of process kernel stack
static void
put_kstack(struct proc_struct *proc) {
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
}

// setup_pgdir - alloc one page as PDT
static int
setup_pgdir(struct mm_struct *mm) {
    struct Page *page;
    if ((page = alloc_page()) == NULL) {
        return -E_NO_MEM;
    }
    pde_t *pgdir = page2kva(page);
    memcpy(pgdir, boot_pgdir, PGSIZE);

    mm->pgdir = pgdir;
    return 0;
}

// put_pgdir - free the memory space of PDT
static void
put_pgdir(struct mm_struct *mm) {
    free_page(kva2page(mm->pgdir));
}

// copy_mm - 进程 "proc" 根据 clone_flags 来复制或共享进程 "current" 的内存管理结构（mm）
//           - 如果 clone_flags & CLONE_VM，则共享内存；否则，复制内存
static int
copy_mm(uint32_t clone_flags, struct proc_struct *proc) {
    struct mm_struct *mm, *oldmm = current->mm;  // 获取当前进程的内存管理结构

    /* current is a kernel thread */
    if (oldmm == NULL) {  // 如果当前进程没有内存管理结构，说明它是一个内核线程
        return 0;  // 直接返回
    }

    // 如果 clone_flags 中包含 CLONE_VM，表示要共享内存
    if (clone_flags & CLONE_VM) {
        mm = oldmm;  // 直接共享当前进程的内存管理结构
        goto good_mm;  // 跳转到处理成功的部分
    }

    // 如果不共享内存，则需要复制内存管理结构
    int ret = -E_NO_MEM;  // 初始化错误代码，表示内存不足
    if ((mm = mm_create()) == NULL) {  // 创建新的内存管理结构
        goto bad_mm;  // 如果创建失败，跳转到错误处理
    }

    // 设置新进程的页目录
    if (setup_pgdir(mm) != 0) {  // 如果设置页目录失败
        goto bad_pgdir_cleanup_mm;  // 跳转到错误处理
    }

    // 锁住当前进程的内存管理结构，防止在复制过程中发生修改
    lock_mm(oldmm);
    {
        // 复制内存映射（mmap）
        ret = dup_mmap(mm, oldmm);  // 将当前进程的内存映射复制到新进程
    }
    unlock_mm(oldmm);  // 解锁当前进程的内存管理结构

    // 如果复制内存映射失败，进行清理
    if (ret != 0) {
        goto bad_dup_cleanup_mmap;  // 错误处理
    }

good_mm:
    mm_count_inc(mm);  // 增加内存管理结构的引用计数
    proc->mm = mm;  // 将新内存管理结构赋值给新进程
    proc->cr3 = PADDR(mm->pgdir);  // 设置新进程的页目录物理地址
    return 0;  // 返回成功

bad_dup_cleanup_mmap:
    exit_mmap(mm);  // 释放已复制的内存映射
    put_pgdir(mm);  // 释放页目录

bad_pgdir_cleanup_mm:
    mm_destroy(mm);  // 销毁内存管理结构

bad_mm:
    return ret;  // 返回错误代码
}

// copy_thread - setup the trapframe on the  process's kernel stack top and
//             - setup the kernel entry point and stack of process
static void
copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf) {
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
    *(proc->tf) = *tf;

    // Set a0 to 0 so a child process knows it's just forked
    proc->tf->gpr.a0 = 0;
    // proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf - 4 : esp;

    proc->context.ra = (uintptr_t)forkret;
    proc->context.sp = (uintptr_t)(proc->tf);
}

/* do_fork - 父进程为一个新的子进程创建一个副本
 * @clone_flags: 用于指导如何克隆子进程
 * @stack: 父进程的用户栈指针，如果 stack == 0，则表示要克隆一个内核线程
 * @tf: 子进程的 trapframe 信息，将会被复制到子进程的 proc->tf
 */
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
    int ret = -E_NO_FREE_PROC;  // 初始化返回值，表示没有空闲的进程
    struct proc_struct *proc;

    // 如果当前进程数量已达到最大限制，不能创建新的进程
    if (nr_process >= MAX_PROCESS) {
        goto fork_out;  // 跳转到函数结尾返回错误
    }

    ret = -E_NO_MEM;  // 初始化内存不足的错误代码

    // 创建子进程的相关操作，参考LAB4和LAB5的步骤
    /*
     * 使用下面的一些宏和函数来实现创建进程：
     * - alloc_proc: 分配并初始化一个 proc_struct
     * - setup_kstack: 为子进程分配内核栈
     * - copy_mm: 根据 clone_flags 克隆或共享当前进程的内存管理结构
     * - copy_thread: 设置子进程的 trapframe 和内核栈信息
     * - hash_proc: 将进程加入到进程哈希表
     * - get_pid: 为子进程分配一个唯一的 PID
     * - wakeup_proc: 将进程的状态设置为 PROC_RUNNABLE
     */

    // Step 1: 创建一个新的 proc_struct
    if((proc = alloc_proc()) == NULL) {
        goto fork_out;  // 创建失败，跳转到退出部分
    }

    // Step 2: 将父进程设置为新进程的父进程
    proc->parent = current;
    assert(current->wait_state == 0);  // 确保当前进程的 wait_state 为 0

    // Step 3: 为子进程分配内核栈
    if(setup_kstack(proc) != 0) {
        goto bad_fork_cleanup_proc;  // 内核栈分配失败，跳转到清理部分
    }

    // Step 4: 根据 clone_flags 克隆或共享内存管理结构
    if(copy_mm(clone_flags, proc) != 0) {
        goto bad_fork_cleanup_kstack;  // 内存管理复制失败，跳转到清理部分
    }

    // Step 5: 设置子进程的 trapframe 和上下文
    copy_thread(proc, stack, tf);

    // 关闭中断，防止在修改进程表时被打断
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        // Step 6: 分配唯一的 PID，加入进程哈希表，并设置进程间的关系链接
        proc->pid = get_pid();  // 分配 PID
        hash_proc(proc);         // 将进程加入哈希表
        set_links(proc);         // 设置进程间的关系链接
    }
    local_intr_restore(intr_flag);  // 恢复中断

    // Step 7: 将进程的状态设置为可运行
    wakeup_proc(proc);

    // 返回子进程的 PID
    ret = proc->pid;

fork_out:
    return ret;  // 返回子进程的 PID，或者错误代码

// 错误处理部分：清理操作
bad_fork_cleanup_kstack:
    put_kstack(proc);  // 释放内核栈

bad_fork_cleanup_proc:
    kfree(proc);  // 释放进程结构体

    goto fork_out;  // 跳转到退出部分
}


// do_exit - 由 sys_exit 调用，负责进程的退出处理
//   1. 调用 exit_mmap、put_pgdir 和 mm_destroy 来释放进程几乎所有的内存空间
//   2. 设置进程的状态为 PROC_ZOMBIE，然后调用 wakeup_proc(parent) 请求父进程回收其资源
//   3. 调用调度器切换到其他进程
int
do_exit(int error_code) {
    // 检查当前进程是否是空闲进程或初始化进程。如果是，它们不能退出
    if (current == idleproc) {
        panic("idleproc exit.\n");  // 空闲进程不能退出，发生异常
    }
    if (current == initproc) {
        panic("initproc exit.\n");  // 初始化进程不能退出，发生异常
    }

    // 获取当前进程的内存管理结构体（mm_struct）
    struct mm_struct *mm = current->mm;

    // 如果当前进程有内存管理结构体（即分配了虚拟内存）
    if (mm != NULL) {
        // 切换回内核页目录
        lcr3(boot_cr3);

        // 如果进程的内存管理结构的引用计数为0，说明当前进程是最后一个持有该内存管理结构的进程
        if (mm_count_dec(mm) == 0) {
            // 释放进程的虚拟内存映射
            exit_mmap(mm);
            // 释放页目录
            put_pgdir(mm);
            // 销毁内存管理结构
            mm_destroy(mm);
        }

        // 清空当前进程的内存管理结构
        current->mm = NULL;
    }

    // 设置当前进程的状态为僵尸状态（PROC_ZOMBIE），表示进程已退出，但父进程尚未回收
    current->state = PROC_ZOMBIE;
    // 设置进程的退出代码
    current->exit_code = error_code;

    // 保存中断状态
    bool intr_flag;
    struct proc_struct *proc;

    // 禁用中断，避免在进程退出过程中打断
    local_intr_save(intr_flag);
    {
        // 获取父进程
        proc = current->parent;

        // 如果父进程处于等待子进程状态（WT_CHILD），则唤醒父进程
        if (proc->wait_state == WT_CHILD) {
            wakeup_proc(proc);
        }

        // 处理当前进程的所有子进程
        while (current->cptr != NULL) {
            // 获取当前进程的一个子进程
            proc = current->cptr;
            current->cptr = proc->optr;  // 更新当前进程的下一个子进程

            // 清空子进程的父指针
            proc->yptr = NULL;
            // 将子进程的父进程指针指向 initproc
            if ((proc->optr = initproc->cptr) != NULL) {
                initproc->cptr->yptr = proc;
            }
            proc->parent = initproc;  // 设置子进程的新父进程为 initproc
            initproc->cptr = proc;  // 将子进程加入 initproc 的子进程链表

            // 如果子进程已经是僵尸状态（PROC_ZOMBIE），并且父进程是等待子进程的状态（WT_CHILD），则唤醒父进程
            if (proc->state == PROC_ZOMBIE) {
                if (initproc->wait_state == WT_CHILD) {
                    wakeup_proc(initproc);
                }
            }
        }
    }

    // 恢复中断
    local_intr_restore(intr_flag);

    // 调用调度器，切换到另一个进程
    schedule();

    // 如果程序执行到此，说明出现了问题，调用 panic 打印当前进程的 PID
    panic("do_exit will not return!! %d.\n", current->pid);
}

/* load_icode - 加载二进制程序（ELF格式）的内容作为当前进程的新内容
 * @binary:  二进制程序内容的内存地址
 * @size:    二进制程序内容的大小
 */
static int
load_icode(unsigned char *binary, size_t size) {
    // 如果当前进程已有地址空间（mm不为空），则触发 panic，不能重复加载
    if (current->mm != NULL) {
        panic("load_icode: current->mm must be empty.\n");
    }

    int ret = -E_NO_MEM;  // 默认返回错误代码：内存不足
    struct mm_struct *mm;
    
    //(1) 为当前进程创建一个新的内存管理结构（mm）
    if ((mm = mm_create()) == NULL) {
        goto bad_mm;  // 如果内存管理结构创建失败，跳转到清理代码
    }

    //(2) 创建新的页目录表（PDT），并将 mm->pgdir 指向该页目录的内核虚拟地址
    if (setup_pgdir(mm) != 0) {
        goto bad_pgdir_cleanup_mm;  // 如果页目录表设置失败，跳转到清理代码
    }

    //(3) 复制二进制程序的 TEXT/DATA 段内容，构建 BSS 部分到进程的内存空间
    struct Page *page;
    
    //(3.1) 获取 ELF 二进制文件的文件头
    struct elfhdr *elf = (struct elfhdr *)binary;
    
    //(3.2) 获取程序头表（program header table），它描述了程序的各个段
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);

    //(3.3) 检查 ELF 文件的有效性
    if (elf->e_magic != ELF_MAGIC) {
        ret = -E_INVAL_ELF;  // 如果 ELF 魔数不匹配，返回无效 ELF 错误
        goto bad_elf_cleanup_pgdir;  // 清理页目录
    }

    uint32_t vm_flags, perm;
    struct proghdr *ph_end = ph + elf->e_phnum;
    
    // 遍历程序头表，处理每个程序段
    for (; ph < ph_end; ph++) {
        //(3.4) 找到每个类型为 ELF_PT_LOAD 的程序段（载入到内存的段）
        if (ph->p_type != ELF_PT_LOAD) {
            continue;
        }

        // 检查段的文件大小和内存大小是否合理
        if (ph->p_filesz > ph->p_memsz) {
            ret = -E_INVAL_ELF;  // 文件大小大于内存大小无效
            goto bad_cleanup_mmap;
        }

        // 如果段的文件大小为 0，继续处理
        if (ph->p_filesz == 0) {
            // continue ;
        }

        //(3.5) 调用 mm_map 函数设置新的虚拟内存区域（VMA），对应段的虚拟地址和大小
        vm_flags = 0, perm = PTE_U | PTE_V;  // 默认用户可访问、有效
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;  // 如果该段可执行
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE; // 如果该段可写
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;  // 如果该段可读

        // 根据 RISC-V 的权限设置修改权限位
        if (vm_flags & VM_READ) perm |= PTE_R;
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
        if (vm_flags & VM_EXEC) perm |= PTE_X;

        // 调用 mm_map 映射段到内存，分配虚拟内存区域
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) {
            goto bad_cleanup_mmap;
        }

        unsigned char *from = binary + ph->p_offset;
        size_t off, size;
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);

        ret = -E_NO_MEM;

        //(3.6) 为程序段分配内存，并将程序段内容从二进制文件复制到进程的内存空间
        end = ph->p_va + ph->p_filesz;

        //(3.6.1) 复制程序的 TEXT/DATA 段
        while (start < end) {
            // 为程序段分配内存页面
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
                goto bad_cleanup_mmap;  // 分配失败，跳转到清理代码
            }
            off = start - la, size = PGSIZE - off, la += PGSIZE;
            if (end < la) {
                size -= la - end;
            }
            // 将文件内容复制到内存
            memcpy(page2kva(page) + off, from, size);
            start += size, from += size;
        }

        //(3.6.2) 构建 BSS 段（未初始化数据段），并初始化为 0
        end = ph->p_va + ph->p_memsz;
        if (start < la) {
            if (start == end) {
                continue;
            }
            off = start + PGSIZE - la, size = PGSIZE - off;
            if (end < la) {
                size -= la - end;
            }
            // 将内存区域清零（初始化为 BSS 段）
            memset(page2kva(page) + off, 0, size);
            start += size;
            assert((end < la && start == end) || (end >= la && start == la));
        }

        // 分配 BSS 段剩余内存并清零
        while (start < end) {
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
                goto bad_cleanup_mmap;
            }
            off = start - la, size = PGSIZE - off, la += PGSIZE;
            if (end < la) {
                size -= la - end;
            }
            // 清空 BSS 部分
            memset(page2kva(page) + off, 0, size);
            start += size;
        }
    }

    //(4) 为用户栈分配内存
    vm_flags = VM_READ | VM_WRITE | VM_STACK;
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) {
        goto bad_cleanup_mmap;
    }
    
    // 为用户栈的几个页分配内存
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE , PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2*PGSIZE , PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3*PGSIZE , PTE_USER) != NULL);
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4*PGSIZE , PTE_USER) != NULL);

    //(5) 设置当前进程的 mm 和 cr3 寄存器，将 CR3 设置为页目录的物理地址
    mm_count_inc(mm);
    current->mm = mm;
    current->cr3 = PADDR(mm->pgdir);
    lcr3(PADDR(mm->pgdir));  // 更新页目录的 CR3 寄存器

    //(6) 设置用户环境的 trapframe
    struct trapframe *tf = current->tf;
    uintptr_t sstatus = tf->status;

    // 清空 trapframe，并根据程序入口设置适当的值
    memset(tf, 0, sizeof(struct trapframe));
    tf->gpr.sp = USTACKTOP;  // 设置用户栈顶
    tf->epc = elf->e_entry;  // 设置程序入口点
    // 清除 SPP 和 SPIE 标志，设置为用户态
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);

    ret = 0;  // 成功返回 0

out:
    return ret;  // 返回处理结果

bad_cleanup_mmap:
    exit_mmap(mm);  // 清理内存映射
bad_elf_cleanup_pgdir:
    put_pgdir(mm);  // 清理页目录
bad_pgdir_cleanup_mm:
    mm_destroy(mm);  // 销毁内存管理结构
bad_mm:
    goto out;  // 出错时跳转到结束，返回错误代码
}


// do_execve - 调用 exit_mmap(mm) 和 put_pgdir(mm) 来回收当前进程的内存空间
//            - 调用 load_icode 来根据二进制程序设置新的内存空间
int
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
    struct mm_struct *mm = current->mm;

    // 检查用户传入的程序名是否在进程的可访问内存范围内
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
        return -E_INVAL;  // 如果程序名无效，返回无效参数错误
    }

    // 限制程序名的长度不超过最大长度
    if (len > PROC_NAME_LEN) {
        len = PROC_NAME_LEN;  // 如果程序名过长，截断为最大长度
    }

    // 为程序名分配一个局部缓冲区，并将程序名复制到其中
    char local_name[PROC_NAME_LEN + 1];
    memset(local_name, 0, sizeof(local_name));  // 清空缓冲区
    memcpy(local_name, name, len);  // 将传入的程序名复制到 local_name 中

    // 如果当前进程已拥有内存管理结构体（mm），则回收其占用的内存
    if (mm != NULL) {
        cputs("mm != NULL");  // 调试输出，显示当前进程有内存管理结构体
        lcr3(boot_cr3);  // 切换回内核页目录（以确保访问内核空间）
        
        // 将当前进程的内存管理引用计数减 1
        if (mm_count_dec(mm) == 0) {
            // 如果引用计数为 0，说明没有其他进程使用该内存管理结构体，回收资源
            exit_mmap(mm);   // 释放内存映射
            put_pgdir(mm);   // 释放页目录
            mm_destroy(mm);  // 销毁内存管理结构体
        }
        
        current->mm = NULL;  // 清空当前进程的内存管理结构体指针
    }

    int ret;
    // 调用 load_icode 加载新的二进制程序，设置新的内存空间
    if ((ret = load_icode(binary, size)) != 0) {
        goto execve_exit;  // 如果加载失败，跳转到退出处理
    }

    // 设置当前进程的程序名
    set_proc_name(current, local_name);

    return 0;  // 执行成功，返回 0

execve_exit:
    // 如果执行失败，调用 do_exit 退出当前进程，并且抛出异常
    do_exit(ret);
    panic("already exit: %e.\n", ret);  // 如果调用 do_exit 后没有退出，则抛出异常
}

// do_yield - 请求调度器重新调度当前进程
int
do_yield(void) {
    current->need_resched = 1;  // 设置当前进程需要重新调度
    return 0;  // 返回 0，表示操作成功
}

// do_wait - 等待一个或多个处于 PROC_ZOMBIE 状态的子进程，并回收该进程的内核栈和进程结构体的内存空间
// NOTE: 只有在 do_wait 函数调用后，子进程的所有资源才会被释放。
int
do_wait(int pid, int *code_store) {
    struct mm_struct *mm = current->mm;

    // 如果提供了 code_store，则检查该指针是否在当前进程可访问的内存范围内
    if (code_store != NULL) {
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1)) {
            return -E_INVAL;  // 如果访问内存不合法，返回错误
        }
    }

    struct proc_struct *proc;
    bool intr_flag, haskid;
repeat:
    haskid = 0;  // 初始化标记，表示当前进程是否有子进程
    // 如果指定了 pid，则查找指定 pid 的进程
    if (pid != 0) {
        proc = find_proc(pid);  // 查找指定 pid 的进程
        if (proc != NULL && proc->parent == current) {  // 如果该进程的父进程是当前进程
            haskid = 1;  // 标记当前进程有子进程
            if (proc->state == PROC_ZOMBIE) {  // 如果子进程的状态为 ZOMBIE，表示它已经结束
                goto found;  // 跳转到清理资源的部分
            }
        }
    }
    else {
        // 如果 pid 为 0，则等待所有的子进程
        proc = current->cptr;  // 获取当前进程的第一个子进程
        for (; proc != NULL; proc = proc->optr) {
            haskid = 1;  // 标记当前进程有子进程
            if (proc->state == PROC_ZOMBIE) {  // 如果子进程的状态为 ZOMBIE
                goto found;  // 跳转到清理资源的部分
            }
        }
    }

    if (haskid) {
        // 如果当前进程有子进程但都未结束，则进入睡眠状态，等待子进程结束
        current->state = PROC_SLEEPING;  // 设置进程状态为睡眠
        current->wait_state = WT_CHILD;  // 设置当前进程的等待状态为等待子进程
        schedule();  // 调用调度器进行进程切换
        
        // 如果当前进程的 flags 标记为 PF_EXITING，表示当前进程正在退出
        if (current->flags & PF_EXITING) {
            do_exit(-E_KILLED);  // 如果进程正在退出，调用 do_exit 函数退出当前进程
        }
        goto repeat;  // 如果没有找到已经结束的子进程，重新检查
    }

    return -E_BAD_PROC;  // 如果没有符合条件的子进程，返回错误

found:
    // 如果待等待的子进程是 idleproc 或 initproc，则抛出异常
    if (proc == idleproc || proc == initproc) {
        panic("wait idleproc or initproc.\n");  // 不能等待这两个特殊进程
    }

    // 如果 code_store 不为 NULL，存储子进程的退出码
    if (code_store != NULL) {
        *code_store = proc->exit_code;
    }

    // 禁用中断，修改进程状态并清理资源
    local_intr_save(intr_flag);
    {
        unhash_proc(proc);  // 从进程哈希表中移除该进程
        remove_links(proc);  // 从父子链表中移除该进程
    }
    local_intr_restore(intr_flag);  // 恢复中断

    // 释放该进程的内核栈和进程结构体内存
    put_kstack(proc);
    kfree(proc);
    return 0;  // 返回 0，表示成功回收资源
}

// do_kill - 终止指定 pid 的进程，将该进程的 flags 标记为 PF_EXITING
int
do_kill(int pid) {
    struct proc_struct *proc;
    // 查找指定 pid 的进程
    if ((proc = find_proc(pid)) != NULL) {
        // 如果进程没有标记为 PF_EXITING（表示尚未退出）
        if (!(proc->flags & PF_EXITING)) {
            proc->flags |= PF_EXITING;  // 将该进程的 flags 设置为 PF_EXITING，标记为退出中
            // 如果该进程的 wait_state 为 WT_INTERRUPTED，表示进程被中断，唤醒该进程
            if (proc->wait_state & WT_INTERRUPTED) {
                wakeup_proc(proc);
            }
            return 0;  // 返回 0，表示成功标记进程为退出状态
        }
        return -E_KILLED;  // 如果进程已经在退出状态，返回进程已终止错误
    }
    return -E_INVAL;  // 如果未找到该进程，返回无效的 pid 错误
}

// kernel_execve - 调用 SYS_exec 系统调用来执行一个用户程序，
//                 该函数由 user_main 内核线程调用。
// name: 要执行的用户程序的名称。
// binary: 用户程序的二进制文件内容。
// size: 用户程序二进制文件的大小。
static int
kernel_execve(const char *name, unsigned char *binary, size_t size) {
    int64_t ret = 0, len = strlen(name);  // 存储返回值并获取程序名称的长度

    // 使用内联汇编发起系统调用
    asm volatile(
        "li a0, %1\n"          // 将 SYS_exec 的值加载到寄存器 a0 中
        "lw a1, %2\n"          // 将程序名称（指针）加载到寄存器 a1 中
        "lw a2, %3\n"          // 将程序名称长度加载到寄存器 a2 中
        "lw a3, %4\n"          // 将程序二进制文件的指针加载到寄存器 a3 中
        "lw a4, %5\n"          // 将程序二进制文件的大小加载到寄存器 a4 中
        "li a7, 10\n"          // 将系统调用号 10 (SYS_exec) 加载到寄存器 a7 中
        "ebreak\n"             // 发出 ebreak 指令，触发系统调用
        "sw a0, %0\n"          // 将返回值 (a0) 存储到变量 ret 中
        : "=m"(ret)            // 输出操作数，存储返回值
        : "i"(SYS_exec),       // 输入操作数：系统调用号 SYS_exec
          "m"(name),           // 输入操作数：程序名称指针
          "m"(len),            // 输入操作数：程序名称长度
          "m"(binary),         // 输入操作数：程序二进制文件指针
          "m"(size)            // 输入操作数：程序二进制文件大小
        : "memory");           // 告诉编译器内存可能被修改，防止优化

    // 打印返回值，检查执行的结果
    cprintf("ret = %d\n", ret);
    return ret;  // 返回系统调用的结果
}

// __KERNEL_EXECVE - 内部宏，简化对 kernel_execve 函数的调用。
// 该宏将当前进程 ID 和程序名称作为调试信息输出，并调用 kernel_execve 执行用户程序。
#define __KERNEL_EXECVE(name, binary, size) ({                          \
            cprintf("kernel_execve: pid = %d, name = \"%s\".\n",        \
                    current->pid, name);                                \
            kernel_execve(name, binary, (size_t)(size));                \
        })

// KERNEL_EXECVE - 通过该宏，传入具体的程序名 (x)，并从外部变量中获取该程序的二进制数据及大小，
// 调用 __KERNEL_EXECVE 宏来执行该程序。
#define KERNEL_EXECVE(x) ({                                             \
            extern unsigned char _binary_obj___user_##x##_out_start[],  \
                _binary_obj___user_##x##_out_size[];                    \
            __KERNEL_EXECVE(#x, _binary_obj___user_##x##_out_start,     \
                            _binary_obj___user_##x##_out_size);         \
        })

// __KERNEL_EXECVE2 - 该宏用于接受程序二进制数据的起始地址和大小，
// 调用 __KERNEL_EXECVE 来执行该用户程序。
// xstart 和 xsize 分别表示程序的起始地址和大小。
#define __KERNEL_EXECVE2(x, xstart, xsize) ({                           \
            extern unsigned char xstart[], xsize[];                     \
            __KERNEL_EXECVE(#x, xstart, (size_t)xsize);                 \
        })

// KERNEL_EXECVE2 - 通过该宏，传入指定的程序名 (x) 以及该程序的二进制数据和大小，
// 调用 __KERNEL_EXECVE2 宏来执行该程序。
#define KERNEL_EXECVE2(x, xstart, xsize)        __KERNEL_EXECVE2(x, xstart, xsize)

// user_main - 由内核线程执行的用户程序执行函数
// 该函数启动时执行一个用户程序。
// 通过调用 `KERNEL_EXECVE2` 来加载并执行指定的用户程序，
// 如果没有定义 TEST，则会执行名为 "exit" 的程序。
// 如果执行失败，会触发 panic。
static int
user_main(void *arg) {
#ifdef TEST
    // 如果定义了 TEST，执行 TEST 程序
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
#else
    // 否则执行名为 "exit" 的程序
    KERNEL_EXECVE(exit);
#endif
    // 如果 execve 执行失败，触发 panic
    panic("user_main execve failed.\n");
}

// init_main - 用于创建 `user_main` 内核线程的第二个内核线程
// 该函数会先记录当前的空闲内存页面数和已分配的内存数，
// 然后创建一个名为 `user_main` 的内核线程，
// 最后等待所有用户态进程结束并进行一些内存和进程的检查。
// 检查通过后，打印相关信息。
static int
init_main(void *arg) {
    // 记录当前的空闲页面数和内核分配的内存
    size_t nr_free_pages_store = nr_free_pages();
    size_t kernel_allocated_store = kallocated();

    // 创建 `user_main` 内核线程，启动用户程序
    int pid = kernel_thread(user_main, NULL, 0);
    if (pid <= 0) {
        // 创建失败，触发 panic
        panic("create user_main failed.\n");
    }

    // 等待所有子进程结束（如果 pid == 0，等待任何子进程）
    while (do_wait(0, NULL) == 0) {
        schedule();  // 调度其他进程
    }

    // 打印所有用户态进程已经退出
    cprintf("all user-mode processes have quit.\n");

    // 检查 initproc 的子进程和父进程链表是否为空
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
    // 检查进程数应该为 2（包括 init 进程和 idle 进程）
    assert(nr_process == 2);
    // 确保进程链表中仅有 initproc
    assert(list_next(&proc_list) == &(initproc->list_link));
    assert(list_prev(&proc_list) == &(initproc->list_link));

    // 打印内存检查通过的信息
    cprintf("init check memory pass.\n");
    return 0;
}

// proc_init - 初始化进程管理结构，创建第一个内核线程 idleproc 和第二个内核线程 init_main
// 该函数负责设置进程管理系统并启动内核线程。它包括以下步骤：
// 1. 初始化进程链表。
// 2. 创建一个名为 idleproc 的内核线程作为系统空闲线程。
// 3. 启动 init_main 内核线程，进一步启动用户进程。
void
proc_init(void) {
    int i;

    // 初始化进程链表
    list_init(&proc_list);
    // 初始化散列表
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
        list_init(hash_list + i);
    }

    // 为 idleproc 分配进程结构
    if ((idleproc = alloc_proc()) == NULL) {
        panic("cannot alloc idleproc.\n");
    }

    // 设置 idleproc 的属性
    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
    idleproc->kstack = (uintptr_t)bootstack;  // 设置空闲进程的内核栈
    idleproc->need_resched = 1;  // 标记需要调度
    set_proc_name(idleproc, "idle");  // 设置进程名称为 "idle"
    nr_process ++;  // 系统进程数加 1

    // 当前进程是 idleproc
    current = idleproc;

    // 创建 init_main 内核线程
    int pid = kernel_thread(init_main, NULL, 0);
    if (pid <= 0) {
        panic("create init_main failed.\n");
    }

    // 获取 initproc 对应的进程结构，并设置进程名
    initproc = find_proc(pid);
    set_proc_name(initproc, "init");

    // 检查 idleproc 和 initproc 是否正确初始化
    assert(idleproc != NULL && idleproc->pid == 0);
    assert(initproc != NULL && initproc->pid == 1);
}

// cpu_idle - 当 kern_init 函数执行完成后，空闲进程 idleproc 将持续调用该函数。
// 该函数会在无限循环中等待调度，如果当前进程需要调度，则调用 `schedule`。
void
cpu_idle(void) {
    while (1) {
        if (current->need_resched) {  // 如果需要调度，调用调度函数
            schedule();
        }
    }
}


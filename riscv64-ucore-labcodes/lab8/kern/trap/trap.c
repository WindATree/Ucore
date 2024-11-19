#include <defs.h>
#include <mmu.h>
#include <memlayout.h>
#include <clock.h>
#include <trap.h>
#include <riscv.h>
#include <stdio.h>
#include <assert.h>
#include <console.h>
#include <vmm.h>
#include <swap.h>
#include <kdebug.h>
#include <unistd.h>
#include <syscall.h>
#include <error.h>
#include <sched.h>
#include <sync.h>
#include <sbi.h>
#include <proc.h>

// 定义一个宏，表示ticks的数量
#define TICK_NUM 2

// 静态函数，用于打印ticks数量
static void print_ticks() {
    cprintf("%d ticks\n",TICK_NUM);
#ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
#endif
}

/*
 * idt_init - 初始化中断描述符表（IDT）到kern/trap/vectors.S中的每个入口点
 */
void
idt_init(void) {
    extern void __alltraps(void);
    /* 将sscratch寄存器设置为0，表示我们当前在内核中执行 */
    write_csr(sscratch, 0);
    /* 设置异常向量地址 */
    write_csr(stvec, &__alltraps);
    /* 允许内核访问用户内存 */
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - 测试陷阱是否发生在内核中 */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
}

void
print_trapframe(struct trapframe *tf) {
    cprintf("trapframe at %p\n", tf);
    print_regs(&tf->gpr);
    cprintf("  status   0x%08x\n", tf->status);
    cprintf("  epc      0x%08x\n", tf->epc);
    cprintf("  tval 0x%08x\n", tf->tval);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs* gpr) {
    // 打印通用寄存器的值
    cprintf("  zero     0x%08x\n", gpr->zero);
    cprintf("  ra       0x%08x\n", gpr->ra);
    cprintf("  sp       0x%08x\n", gpr->sp);
    cprintf("  gp       0x%08x\n", gpr->gp);
    cprintf("  tp       0x%08x\n", gpr->tp);
    cprintf("  t0       0x%08x\n", gpr->t0);
    cprintf("  t1       0x%08x\n", gpr->t1);
    cprintf("  t2       0x%08x\n", gpr->t2);
    cprintf("  s0       0x%08x\n", gpr->s0);
    cprintf("  s1       0x%08x\n", gpr->s1);
    cprintf("  a0       0x%08x\n", gpr->a0);
    cprintf("  a1       0x%08x\n", gpr->a1);
    cprintf("  a2       0x%08x\n", gpr->a2);
    cprintf("  a3       0x%08x\n", gpr->a3);
    cprintf("  a4       0x%08x\n", gpr->a4);
    cprintf("  a5       0x%08x\n", gpr->a5);
    cprintf("  a6       0x%08x\n", gpr->a6);
    cprintf("  a7       0x%08x\n", gpr->a7);
    cprintf("  s2       0x%08x\n", gpr->s2);
    cprintf("  s3       0x%08x\n", gpr->s3);
    cprintf("  s4       0x%08x\n", gpr->s4);
    cprintf("  s5       0x%08x\n", gpr->s5);
    cprintf("  s6       0x%08x\n", gpr->s6);
    cprintf("  s7       0x%08x\n", gpr->s7);
    cprintf("  s8       0x%08x\n", gpr->s8);
    cprintf("  s9       0x%08x\n", gpr->s9);
    cprintf("  s10      0x%08x\n", gpr->s10);
    cprintf("  s11      0x%08x\n", gpr->s11);
    cprintf("  t3       0x%08x\n", gpr->t3);
    cprintf("  t4       0x%08x\n", gpr->t4);
    cprintf("  t5       0x%08x\n", gpr->t5);
    cprintf("  t6       0x%08x\n", gpr->t6);
}

static inline void print_pgfault(struct trapframe *tf) {
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

/**
 * 处理页面错误（Page Fault）的函数。
 * 
 * @param tf 指向trapframe结构体的指针，包含了中断发生时的上下文信息。
 * @return 返回值由do_pgfault函数决定。
 */
static int
pgfault_handler(struct trapframe *tf) {
    // 外部声明的mm_struct结构体指针，用于测试检查swap。
    extern struct mm_struct *check_mm_struct;
    // 如果check_mm_struct不为空，则用于测试检查swap。
    if(check_mm_struct != NULL) { 
        print_pgfault(tf);
    }
    
    // 定义一个mm_struct结构体指针，用于存储进程的内存管理信息。
    struct mm_struct *mm;
    // 如果check_mm_struct不为空，则断言当前进程是idleproc，并使用check_mm_struct。
    if (check_mm_struct != NULL) {
        assert(current == idleproc);
        mm = check_mm_struct;
    }
    // 如果check_mm_struct为空，则检查当前进程是否为空。
    else {
        // 如果当前进程为空，则打印trapframe和页面错误信息，并触发panic。
        if (current == NULL) {
            print_trapframe(tf);
            print_pgfault(tf);
            panic("unhandled page fault.\n");
        }
        // 如果当前进程不为空，则使用当前进程的mm。
        mm = current->mm;
    }
    // 调用do_pgfault函数来实际处理页面错误，并返回其返回值。
    return do_pgfault(mm, tf->cause, tf->tval);
}

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
    switch (cause) {
        // 处理不同的中断类型
        case IRQ_U_SOFT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_SOFT:
            cprintf("Supervisor software interrupt\n");
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
            break;
        case IRQ_U_TIMER:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_TIMER:
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
            ++ticks;
            run_timer_list();
            dev_stdin_write(cons_getc());
            break;
        case IRQ_H_TIMER:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_TIMER:
            cprintf("Machine software interrupt\n");
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
            break;
        case IRQ_H_EXT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_EXT:
            cprintf("Machine software interrupt\n");
            break;
        default:
            print_trapframe(tf);
            break;
    }
}

void kernel_execve_ret(struct trapframe *tf,uintptr_t kstacktop);
void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
        // 处理不同的异常类型
        case CAUSE_MISALIGNED_FETCH:
            cprintf("Instruction address misaligned\n");
            break;
        case CAUSE_FETCH_ACCESS:
            cprintf("Instruction access fault\n");
            break;
        case CAUSE_ILLEGAL_INSTRUCTION:
            cprintf("Illegal instruction\n");
            break;
        case CAUSE_BREAKPOINT:
            cprintf("Breakpoint\n");
            if(tf->gpr.a7 == 10){
                tf->epc += 4;
                syscall();
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
            }
            break;
        case CAUSE_MISALIGNED_LOAD:
            cprintf("Load address misaligned\n");
            break;
        case CAUSE_LOAD_ACCESS:
            cprintf("Load access fault\n");
            if ((ret = pgfault_handler(tf)) != 0) {
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_MISALIGNED_STORE:
            panic("AMO address misaligned\n");
            break;
        case CAUSE_STORE_ACCESS:
            cprintf("Store/AMO access fault\n");
            if ((ret = pgfault_handler(tf)) != 0) {
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_USER_ECALL:
            //cprintf("Environment call from U-mode\n");
            tf->epc += 4;
            syscall();
            break;
        case CAUSE_SUPERVISOR_ECALL:
            cprintf("Environment call from S-mode\n");
            tf->epc += 4;
            syscall();
            break;
        case CAUSE_HYPERVISOR_ECALL:
            cprintf("Environment call from H-mode\n");
            break;
        case CAUSE_MACHINE_ECALL:
            cprintf("Environment call from M-mode\n");
            break;
        case CAUSE_FETCH_PAGE_FAULT:
            cprintf("Instruction page fault\n");
            break;
        case CAUSE_LOAD_PAGE_FAULT:
            cprintf("Load page fault\n");
            if ((ret = pgfault_handler(tf)) != 0) {
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_STORE_PAGE_FAULT:
            cprintf("Store/AMO page fault\n");
            if ((ret = pgfault_handler(tf)) != 0) {
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        default:
            print_trapframe(tf);
            break;
    }
}

static inline void trap_dispatch(struct trapframe* tf) {
    if ((intptr_t)tf->cause < 0) {
        // 中断处理
        interrupt_handler(tf);
    } else {
        // 异常处理
        exception_handler(tf);
    }
}

/* 
 * trap - 处理或分派一个异常/中断。如果trap()返回，
 * kern/trap/trapentry.S中的代码将恢复旧的CPU状态，并使用iret指令从异常中返回。
 */
void
trap(struct trapframe *tf) {
    // 根据发生的陷阱类型进行分派
    if (current == NULL) {
        trap_dispatch(tf);
    } else {
        struct trapframe *otf = current->tf;
        current->tf = tf;

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
        if (!in_kernel) {
            if (current->flags & PF_EXITING) {
                do_exit(-E_KILLED);
            }
            if (current->need_resched) {
                schedule();
            }
        }
    }
}
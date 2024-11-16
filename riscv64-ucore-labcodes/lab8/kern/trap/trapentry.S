#include <riscv.h>

// 使用.altmacro指令允许使用局部宏。
.altmacro
// 确保指令对齐，以便于加载到缓存。
.align 2

// 定义一个宏SAVE_ALL，用于保存所有寄存器到栈上。
.macro SAVE_ALL
LOCAL _restore_kernel_sp
LOCAL _save_context

    // 如果从用户空间来，保存用户栈指针并加载内核栈指针。
    // 如果我们从内核来，sscratch将包含0，我们应该继续使用当前栈。
    csrrw sp, sscratch, sp // 将sscratch寄存器的值与sp寄存器的值交换
    bnez sp, _save_context // 如果sp非零，跳转到_save_context

_restore_kernel_sp:
    csrr sp, sscratch // 从sscratch寄存器加载值到sp
_save_context:
    addi sp, sp, -36 * REGBYTES // 为保存寄存器值预留空间
    // 保存x寄存器
    STORE x0, 0*REGBYTES(sp)
    STORE x1, 1*REGBYTES(sp)
    STORE x3, 3*REGBYTES(sp)
    STORE x4, 4*REGBYTES(sp)
    STORE x5, 5*REGBYTES(sp)
    STORE x6, 6*REGBYTES(sp)
    STORE x7, 7*REGBYTES(sp)
    STORE x8, 8*REGBYTES(sp)
    STORE x9, 9*REGBYTES(sp)
    STORE x10, 10*REGBYTES(sp)
    STORE x11, 11*REGBYTES(sp)
    STORE x12, 12*REGBYTES(sp)
    STORE x13, 13*REGBYTES(sp)
    STORE x14, 14*REGBYTES(sp)
    STORE x15, 15*REGBYTES(sp)
    STORE x16, 16*REGBYTES(sp)
    STORE x17, 17*REGBYTES(sp)
    STORE x18, 18*REGBYTES(sp)
    STORE x19, 19*REGBYTES(sp)
    STORE x20, 20*REGBYTES(sp)
    STORE x21, 21*REGBYTES(sp)
    STORE x22, 22*REGBYTES(sp)
    STORE x23, 23*REGBYTES(sp)
    STORE x24, 24*REGBYTES(sp)
    STORE x25, 25*REGBYTES(sp)
    STORE x26, 26*REGBYTES(sp)
    STORE x27, 27*REGBYTES(sp)
    STORE x28, 28*REGBYTES(sp)
    STORE x29, 29*REGBYTES(sp)
    STORE x30, 30*REGBYTES(sp)
    STORE x31, 31*REGBYTES(sp)

    // 获取sr, epc, tval, cause
    // 设置sscratch寄存器为0，以便如果发生递归异常，异常向量知道它来自内核
    csrrw s0, sscratch, x0
    csrr s1, sstatus
    csrr s2, sepc
    csrr s3, 0x143 // 假设这是一个特定的CSR寄存器地址
    csrr s4, scause

    STORE s0, 2*REGBYTES(sp)
    STORE s1, 32*REGBYTES(sp)
    STORE s2, 33*REGBYTES(sp)
    STORE s3, 34*REGBYTES(sp)
    STORE s4, 35*REGBYTES(sp)
.endm

// 定义一个宏RESTORE_ALL，用于从栈上恢复所有寄存器。
.macro RESTORE_ALL
LOCAL _save_kernel_sp
LOCAL _restore_context

    LOAD s1, 32*REGBYTES(sp)
    LOAD s2, 33*REGBYTES(sp)

    andi s0, s1, SSTATUS_SPP // 检查sstatus寄存器的SPP位
    bnez s0, _restore_context // 如果SPP位为1，跳转到_restore_context

_save_kernel_sp:
    // 保存未展开的内核栈指针在sscratch
    addi s0, sp, 36 * REGBYTES
    csrw sscratch, s0
_restore_context:
    csrw sstatus, s1
    csrw sepc, s2

    // 恢复x寄存器
    LOAD x1, 1*REGBYTES(sp)
    LOAD x3, 3*REGBYTES(sp)
    LOAD x4, 4*REGBYTES(sp)
    LOAD x5, 5*REGBYTES(sp)
    LOAD x6, 6*REGBYTES(sp)
    LOAD x7, 7*REGBYTES(sp)
    LOAD x8, 8*REGBYTES(sp)
    LOAD x9, 9*REGBYTES(sp)
    LOAD x10, 10*REGBYTES(sp)
    LOAD x11, 11*REGBYTES(sp)
    LOAD x12, 12*REGBYTES(sp)
    LOAD x13, 13*REGBYTES(sp)
    LOAD x14, 14*REGBYTES(sp)
    LOAD x15, 15*REGBYTES(sp)
    LOAD x16, 16*REGBYTES(sp)
    LOAD x17, 17*REGBYTES(sp)
    LOAD x18, 18*REGBYTES(sp)
    LOAD x19, 19*REGBYTES(sp)
    LOAD x20, 20*REGBYTES(sp)
    LOAD x21, 21*REGBYTES(sp)
    LOAD x22, 22*REGBYTES(sp)
    LOAD x23, 23*REGBYTES(sp)
    LOAD x24, 24*REGBYTES(sp)
    LOAD x25, 25*REGBYTES(sp)
    LOAD x26, 26*REGBYTES(sp)
    LOAD x27, 27*REGBYTES(sp)
    LOAD x28, 28*REGBYTES(sp)
    LOAD x29, 29*REGBYTES(sp)
    LOAD x30, 30*REGBYTES(sp)
    LOAD x31, 31*REGBYTES(sp)
    // 最后恢复sp
    LOAD x2, 2*REGBYTES(sp)
.endm

// 全局标签，用于所有陷阱的入口点
.globl __alltraps
__alltraps:
    SAVE_ALL

    move a0, sp // 将当前栈指针移动到a0寄存器
    jal trap // 跳转到trap处理函数
    // sp应该与"jal trap"之前相同

// 全局标签，用于从陷阱返回
.globl __trapret
__trapret:
    RESTORE_ALL
    // 从超级用户调用返回
    sret

// 全局标签，用于fork系统调用的返回
.globl forkrets
forkrets:
    // 将栈设置为这个新进程的trapframe
    move sp, a0
    j __trapret

// 全局标签，用于kernel_execve系统调用的返回
.global kernel_execve_ret
kernel_execve_ret:
    // 调整sp到当前进程的kstacktop之下
    addi a1, a1, -36*REGBYTES

    // 从上一个trapframe复制到新的trapframe
    LOAD s1, 35*REGBYTES(a0)
    STORE s1, 35*REGBYTES(a1)
    LOAD s1, 34*REGBYTES(a0)
    STORE s1, 34*REGBYTES(a1)
    LOAD s1, 33*REGBYTES(a0)
    STORE s1, 33*REGBYTES(a1)
    LOAD s1, 32*REGBYTES(a0)
    STORE s1, 32*REGBYTES(a1)
    LOAD s1, 31*REGBYTES(a0)
    STORE s1, 31*REGBYTES(a1)
    LOAD s1, 30*REGBYTES(a0)
    STORE s1, 30*REGBYTES(a1)
    LOAD s1, 29*REGBYTES(a0)
    STORE s1, 29*REGBYTES(a1)
    LOAD s1, 28*REGBYTES(a0)
    STORE s1, 28*REGBYTES(a1)
    LOAD s1, 27*REGBYTES(a0)
    STORE s1, 27*REGBYTES(a1)
    LOAD s1, 26*REGBYTES(a0)
    STORE s1, 26*REGBYTES(a1)
    LOAD s1, 25*REGBYTES(a0)
    STORE s1, 25*REGBYTES(a1)
    LOAD s1, 24*REGBYTES(a0)
    STORE s1, 24*REGBYTES(a1)
    LOAD s1, 23*REGBYTES(a0)
    STORE s1, 23*REGBYTES(a1)
    LOAD s1, 22*REGBYTES(a0)
    STORE s1, 22*REGBYTES(a1)
    LOAD s1, 21*REGBYTES(a0)
    STORE s1, 21*REGBYTES(a1)
    LOAD s1, 20*REGBYTES(a0)
    STORE s1, 20*REGBYTES(a1)
    LOAD s1, 19*REGBYTES(a0)
    STORE s1, 19*REGBYTES(a1)
    LOAD s1, 18*REGBYTES(a0)
    STORE s1, 18*REGBYTES(a1)
    LOAD s1, 17*REGBYTES(a0)
    STORE s1, 17*REGBYTES(a1)
    LOAD s1, 16*REGBYTES(a0)
    STORE s1, 16*REGBYTES(a1)
    LOAD s1, 15*REGBYTES(a0)
    STORE s1, 15*REGBYTES(a1)
    LOAD s1, 14*REGBYTES(a0)
    STORE s1, 14*REGBYTES(a1)
    LOAD s1, 13*REGBYTES(a0)
    STORE s1, 13*REGBYTES(a1)
    LOAD s1, 12*REGBYTES(a0)
    STORE s1, 12*REGBYTES(a1)
    LOAD s1, 11*REGBYTES(a0)
    STORE s1, 11*REGBYTES(a1)
    LOAD s1, 10*REGBYTES(a0)
    STORE s1, 10*REGBYTES(a1)
    LOAD s1, 9*REGBYTES(a0)
    STORE s1, 9*REGBYTES(a1)
    LOAD s1, 8*REGBYTES(a0)
    STORE s1, 8*REGBYTES(a1)
    LOAD s1, 7*REGBYTES(a0)
    STORE s1, 7*REGBYTES(a1)
    LOAD s1, 6*REGBYTES(a0)
    STORE s1, 6*REGBYTES(a1)
    LOAD s1, 5*REGBYTES(a0)
    STORE s1, 5*REGBYTES(a1)
    LOAD s1, 4*REGBYTES(a0)
    STORE s1, 4*REGBYTES(a1)
    LOAD s1, 3*REGBYTES(a0)
    STORE s1, 3*REGBYTES(a1)
    LOAD s1, 2*REGBYTES(a0)
    STORE s1, 2*REGBYTES(a1)
    LOAD s1, 1*REGBYTES(a0)
    STORE s1, 1*REGBYTES(a1)
    LOAD s1, 0*REGBYTES(a0)
    STORE s1, 0*REGBYTES(a1)

    // 实际调整sp
    move sp, a1
    j __trapret
#ifndef __KERN_MM_MEMLAYOUT_H__
#define __KERN_MM_MEMLAYOUT_H__
/* 本文件包含了操作系统内存管理的定义 */

/* *
 * 虚拟内存映射：                                          权限
 *                                                              内核/用户
 * 
 *     4G ------------------> +---------------------------------+
 *                            |                                 |
 *                            |         空闲内存 (*)            |
 *                            |                                 |
 *                            +---------------------------------+ 0xFB000000
 *                            |   当前页表 (内核, 读写)         | 读/写 -- PTSIZE
 *     VPT -----------------> +---------------------------------+ 0xFAC00000
 *                            |        无效内存 (*)            | --/--
 *     KERNTOP -------------> +---------------------------------+ 0xF8000000
 *                            |                                 |
 *                            |    重新映射的物理内存          | 读/写 -- KMEMSIZE
 *                            |                                 |
 *     KERNBASE ------------> +---------------------------------+ 0xC0000000
 *                            |        无效内存 (*)            | --/--
 *     USERTOP -------------> +---------------------------------+ 0xB0000000
 *                            |           用户栈               |
 *                            +---------------------------------+
 *                            |                                 |
 *                            :                                 :
 *                            |         ~~~~~~~~~~~~~~~~        |
 *                            :                                 :
 *                            |                                 |
 *                            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *                            |       用户程序和堆区           |
 *     UTEXT ---------------> +---------------------------------+ 0x00800000
 *                            |        无效内存 (*)            | --/--
 *                            |  - - - - - - - - - - - - - - -  |
 *                            |    用户 STAB 数据 (可选)       |
 *     USERBASE, USTAB------> +---------------------------------+ 0x00200000
 *                            |        无效内存 (*)            | --/--
 *     0 -------------------> +---------------------------------+ 0x00000000
 * (*) 注意：内核确保 "无效内存" *永远* 不会被映射。
 *     "空闲内存"通常是未映射的，但用户程序可以根据需要将其映射到页面。
 * */

/* 所有物理内存映射到此地址 */
#define KERNBASE            0xFFFFFFFFC0200000  // 内核基址
#define KMEMSIZE            0x7E00000           // 物理内存的最大大小
#define KERNTOP             (KERNBASE + KMEMSIZE) // 内核顶部

#define KERNEL_BEGIN_PADDR 0x80200000    // 内核起始物理地址
#define KERNEL_BEGIN_VADDR 0xFFFFFFFFC0200000  // 内核起始虚拟地址
#define PHYSICAL_MEMORY_END 0x88000000  // 物理内存结束地址

/* *
 * 虚拟页表。页目录 (PD) 中的条目 PDX[VPT] 指向页目录本身，
 * 通过此方式将页目录转化为页表，映射包含整个虚拟地址空间映射的页表项（PTE），
 * 并将其映射到从 VPT 开始的 4MB 区域。
 * */

#define KSTACKPAGE          2                          // 内核栈的页面数
#define KSTACKSIZE          (KSTACKPAGE * PGSIZE)      // 内核栈的大小

#define USERTOP             0x80000000    // 用户空间的顶部
#define USTACKTOP           USERTOP       // 用户栈顶（与 USERTOP 相同）
#define USTACKPAGE          256           // 用户栈的页面数
#define USTACKSIZE          (USTACKPAGE * PGSIZE)    // 用户栈的大小

#define USERBASE            0x00200000    // 用户空间基地址
#define UTEXT               0x00800000    // 用户程序的起始地址
#define USTAB               USERBASE      // 用户 STABS 数据结构的存储位置

#define USER_ACCESS(start, end)                     \
(USERBASE <= (start) && (start) < (end) && (end) <= USERTOP)  // 判断内存区间是否属于用户空间

#define KERN_ACCESS(start, end)                     \
(KERNBASE <= (start) && (start) < (end) && (end) <= KERNTOP)  // 判断内存区间是否属于内核空间

#ifndef __ASSEMBLER__

#include <defs.h>
#include <atomic.h>
#include <list.h>

typedef uintptr_t pte_t;  // 页面表项类型
typedef uintptr_t pde_t;  // 页目录项类型
typedef pte_t swap_entry_t;  // 页表项也可作为交换区条目

/* *
 * struct Page - 页面描述符结构。每个页面描述一个物理页面。
 * 在 kern/mm/pmm.h 中，你可以找到将 Page 转换为其他数据类型的有用函数，
 * 例如物理地址。
 * */
struct Page {
    int ref;                        // 页面帧的引用计数
    uint64_t flags;                 // 描述页面帧状态的标志位
    unsigned int property;          // 空闲内存块的数量，供“首次适配”页面管理使用
    list_entry_t page_link;         // 空闲链表的链接
    list_entry_t pra_page_link;     // 用于页面替换算法的链接
    uintptr_t pra_vaddr;            // 用于页面替换算法的虚拟地址
};

/* 页面帧状态标志位 */
#define PG_reserved                 0       // 如果该位为1，表示页面保留给内核，不能被分配或释放；否则为0
#define PG_property                 1       // 如果该位为1，表示该页面为自由内存块的头页面，可用于分配；否则为0

#define SetPageReserved(page)       set_bit(PG_reserved, &((page)->flags))  // 设置页面为保留状态
#define ClearPageReserved(page)     clear_bit(PG_reserved, &((page)->flags))  // 清除页面的保留状态
#define PageReserved(page)          test_bit(PG_reserved, &((page)->flags))  // 检查页面是否为保留状态
#define SetPageProperty(page)       set_bit(PG_property, &((page)->flags))  // 设置页面的属性状态
#define ClearPageProperty(page)     clear_bit(PG_property, &((page)->flags))  // 清除页面的属性状态
#define PageProperty(page)          test_bit(PG_property, &((page)->flags))  // 检查页面的属性状态

// 将链表条目转换为页面结构体
#define le2page(le, member)                 \
    to_struct((le), struct Page, member)

/* free_area_t - 维护一个双向链表，用于记录空闲（未使用）页面 */
typedef struct {
    list_entry_t free_list;         // 空闲链表头
    unsigned int nr_free;           // 该链表中空闲页面的数量
} free_area_t;



#endif /* !__ASSEMBLER__ */

#endif /* !__KERN_MM_MEMLAYOUT_H__ */


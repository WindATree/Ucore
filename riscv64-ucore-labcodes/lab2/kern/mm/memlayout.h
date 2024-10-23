// 定义一个宏，防止这个头文件被重复包含
#ifndef __KERN_MM_MEMLAYOUT_H__
#define __KERN_MM_MEMLAYOUT_H__

// 定义内核基地址，所有物理内存都映射到这个地址
#define KERNBASE            0xFFFFFFFFC0200000 // = 0x80200000(物理内存里内核的起始位置, KERN_BEGIN_PADDR) + 0xFFFFFFFF40000000(偏移量, PHYSICAL_MEMORY_OFFSET)
// 定义内核可以使用的最大物理内存大小
#define KMEMSIZE            0x7E00000          // the maximum amount of physical memory
// 0x7E00000 = 0x8000000 - 0x200000
// QEMU 默认的RAM为 0x80000000到0x88000000, 128MiB, 0x80000000到0x80200000被OpenSBI占用
// 定义内核顶部的虚拟地址
#define KERNTOP             (KERNBASE + KMEMSIZE) // 0x88000000对应的虚拟地址

// 定义物理内存的结束地址
#define PHYSICAL_MEMORY_END         0x88000000
// 定义物理内存的偏移量
#define PHYSICAL_MEMORY_OFFSET      0xFFFFFFFF40000000
// 定义内核在物理内存中的起始地址
#define KERNEL_BEGIN_PADDR          0x80200000
// 定义内核在虚拟内存中的起始地址
#define KERNEL_BEGIN_VADDR          0xFFFFFFFFC0200000

// 定义内核栈的页数
#define KSTACKPAGE          2
// 定义内核栈的大小
#define KSTACKSIZE          (KSTACKPAGE * PGSIZE)       // sizeof kernel stack,PGSIZE=4096  ,mmu.h

// 如果不是汇编语言环境
#ifndef __ASSEMBLER__

#include <defs.h>
#include <atomic.h>
#include <list.h>

// 定义页表条目和页目录条目的类型
typedef uintptr_t pte_t;
typedef uintptr_t pde_t;

/* *
 * struct Page - 页描述符结构体。每个Page描述一个物理页。
 * 在kern/mm/pmm.h中，你可以找到许多有用的函数，将Page转换为其他数据类型，比如物理地址。
 * */
struct Page {
    int ref;                        // 页面的引用计数
    uint64_t flags;                 // 描述页面状态的标志数组
    unsigned int property;          // 在首次适应的物理内存管理器中使用的空闲块数量
    list_entry_t page_link;         // 空闲列表链接
};

/* 描述页面状态的标志 */
#define PG_reserved                 0       
// 如果这个位=1: 页面被内核保留，不能在alloc/free_pages中使用; 否则，这个位=0 
#define PG_property                 1       
// 如果这个位=1: 页面是空闲内存块的头页面(包含一些连续的物理页面)，并且可以在alloc_pages中使用; 
// 如果这个位=0: 如果页面是空闲内存块的头页面，那么这个页面和内存块已经被分配。或者这个页面不是头页面。

#define SetPageReserved(page)       set_bit(PG_reserved, &((page)->flags))
#define ClearPageReserved(page)     clear_bit(PG_reserved, &((page)->flags))
#define PageReserved(page)          test_bit(PG_reserved, &((page)->flags))
#define SetPageProperty(page)       set_bit(PG_property, &((page)->flags))
#define ClearPageProperty(page)     clear_bit(PG_property, &((page)->flags))
#define PageProperty(page)          test_bit(PG_property, &((page)->flags))

// 将链表入口转换为页面
/* *
 * to_struct - 从指针中获取结构体
 * @ptr:    成员的结构体指针
 * @type:   该结构体嵌入的类型
 * @member: 结构体内部成员的名称
 * */
#define le2page(le, member)                 \
    to_struct((le), struct Page, member)

/* free_area_t - 维护一个双向链表来记录空闲(未使用)的页面 */
typedef struct {
    list_entry_t free_list;         // 链表头
    unsigned int nr_free;           // 这个空闲列表中的空闲页面数量
} free_area_t;

#endif /* !__ASSEMBLER__ */

#endif /* !__KERN_MM_MEMLAYOUT_H__ */
#ifndef __KERN_MM_MMU_H__
#define __KERN_MM_MMU_H__

#ifndef __ASSEMBLER__
#include <defs.h>
#endif /* !__ASSEMBLER__ */

// A linear address 'la' has a four-part structure as follows:
//
// +--------9-------+-------9--------+-------9--------+---------12----------+
// | Page Directory | Page Directory |   Page Table   | Offset within Page  |
// |     Index 1    |    Index 2     |                |                     |
// +----------------+----------------+----------------+---------------------+
//  \-- PDX1(la) --/ \-- PDX0(la) --/ \--- PTX(la) --/ \---- PGOFF(la) ----/
//  \-------------------PPN(la)----------------------/
//
// The PDX1, PDX0, PTX, PGOFF, and PPN macros decompose linear addresses as shown.
// To construct a linear address la from PDX(la), PTX(la), and PGOFF(la),
// use PGADDR(PDX(la), PTX(la), PGOFF(la)).

// RISC-V uses 39-bit virtual address to access 56-bit physical address!
// Sv39 virtual address:
// +----9----+----9---+----9---+---12--+
// |  VPN[2] | VPN[1] | VPN[0] | PGOFF |
// +---------+----+---+--------+-------+
//
// Sv39 physical address:
// +----26---+----9---+----9---+---12--+
// |  PPN[2] | PPN[1] | PPN[0] | PGOFF |
// +---------+----+---+--------+-------+
//
// Sv39 page table entry:
// +----26---+----9---+----9---+---2----+-------8-------+
// |  PPN[2] | PPN[1] | PPN[0] |Reserved|D|A|G|U|X|W|R|V|
// +---------+----+---+--------+--------+---------------+


// 线性地址（Linear Address）是虚拟地址到物理地址转换过程的中间形式。
// 转换过程：虚拟地址 →（分段）→ 线性地址 →（分页）→ 物理地址。
// 虚拟地址先经分段机制变为线性地址，再由页表映射到物理地址。
// 物理地址是真实内存地址，线性地址是虚拟化的中间地址，不直接对应物理内存。


// & can remain 9 bits
// page directory index
#define PDX1(la) ((((uintptr_t)(la)) >> PDX1SHIFT) & 0x1FF) // 提取线性地址 la 中的第一级页目录索引
#define PDX0(la) ((((uintptr_t)(la)) >> PDX0SHIFT) & 0x1FF) // 提取线性地址 la 中的第二级页目录索引

// page table index
#define PTX(la) ((((uintptr_t)(la)) >> PTXSHIFT) & 0x1FF) // 从 la 提取页表索引

// page number field of address
#define PPN(la) (((uintptr_t)(la)) >> PTXSHIFT) // 提取线性地址 la 中的页号字段（页帧号）

// offset in page
#define PGOFF(la) (((uintptr_t)(la)) & 0xFFF) // 提取线性地址 la 的页内偏移（即12位的页面偏移量）

// construct linear address from indexes and offset, by the or
#define PGADDR(d1, d0, t, o) ((uintptr_t)((d1) << PDX1SHIFT | (d0) << PDX0SHIFT | (t) << PTXSHIFT | (o))) 
// 由第一级页目录索引 d1、第二级页目录索引 d0、页表索引 t 和页内偏移 o 构造出线性地址

// address in page table or page directory entry
// 将 pte 与 ~0x3FF 相与，清除低 10 位标志位，保留页帧号部分
#define PTE_ADDR(pte)   (((uintptr_t)(pte) & ~0x3FF) << (PTXSHIFT - PTE_PPN_SHIFT))
// 从页表项 pte 中提取页面的基地址，去掉低10位的标志位，并左移以得到物理地址中的页帧号字段
#define PDE_ADDR(pde)   PTE_ADDR(pde) // 从页目录项 pde 中提取页面的基地址

/* page directory and page table constants */
#define NPDEENTRY       512                    // 每个页目录的页目录项数
#define NPTEENTRY       512                    // 每个页表的页表项数

#define PGSIZE          4096                    // 每页的大小（以字节为单位）
#define PGSHIFT         12                      // PGSIZE 的对数（log2(PGSIZE)），即页面偏移量的位数
#define PTSIZE          (PGSIZE * NPTEENTRY)    // 每个页目录项映射的字节数
#define PTSHIFT         21                      // PTSIZE 的对数（log2(PTSIZE)），即页目录偏移量的位数

#define PTXSHIFT        12                      // 线性地址中页表索引的位移量
#define PDX0SHIFT       21                      // 线性地址中第二级页目录索引的位移量
#define PDX1SHIFT       30                      // 线性地址中第一级页目录索引的位移量
#define PTE_PPN_SHIFT   10                      // 物理地址中页帧号的位移量

// page table entry (PTE) fields
#define PTE_V     0x001 // 有效位（Valid），表示此页表项是否有效
#define PTE_R     0x002 // 读权限（Read），允许此页被读取
#define PTE_W     0x004 // 写权限（Write），允许此页被写入
#define PTE_X     0x008 // 执行权限（Execute），允许此页被执行
#define PTE_U     0x010 // 用户模式（User），允许用户态访问此页
#define PTE_G     0x020 // 全局位（Global），表示此页表项在所有进程中共享
#define PTE_A     0x040 // 已访问位（Accessed），表示此页是否被访问过
#define PTE_D     0x080 // 已修改位（Dirty），表示此页是否被写过
#define PTE_SOFT  0x300 // 软件保留位（Reserved for Software），供操作系统或软件使用

// 访问权限配置的宏定义
#define PAGE_TABLE_DIR (PTE_V) // 页表目录项，仅设置为有效
#define READ_ONLY (PTE_R | PTE_V) // 只读页，允许读取且有效
#define READ_WRITE (PTE_R | PTE_W | PTE_V) // 读写页，允许读取和写入且有效
#define EXEC_ONLY (PTE_X | PTE_V) // 仅执行页，允许执行且有效
#define READ_EXEC (PTE_R | PTE_X | PTE_V) // 读+执行页，允许读取和执行且有效
#define READ_WRITE_EXEC (PTE_R | PTE_W | PTE_X | PTE_V) // 读写执行页，允许读取、写入和执行且有效

#define PTE_USER (PTE_R | PTE_W | PTE_X | PTE_U | PTE_V) // 用户模式下完全访问的页，允许读写执行和用户态访问且有效


#endif /* !__KERN_MM_MMU_H__ */


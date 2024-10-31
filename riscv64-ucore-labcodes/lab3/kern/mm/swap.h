#ifndef __KERN_MM_SWAP_H__ // 如果没有定义__KERN_MM_SWAP_H__，则执行以下代码
#define __KERN_MM_SWAP_H__  // 定义__KERN_MM_SWAP_H__，防止头文件被重复包含

#include <defs.h>           // 包含定义库，可能包含一些基本类型和宏定义
#include <memlayout.h>      // 包含内存布局相关的头文件
#include <pmm.h>            // 包含物理内存管理相关的头文件
#include <vmm.h>            // 包含虚拟内存管理相关的头文件

/* *
 * swap_entry_t
 * --------------------------------------------
 * |         offset        |   reserved   | 0 |
 * --------------------------------------------
 *           24 bits            7 bits    1 bit
 * */

#define MAX_SWAP_OFFSET_LIMIT                   (1 << 24) // 定义最大交换偏移量限制为2^24

extern size_t max_swap_offset; // 声明外部变量max_swap_offset，表示最大交换偏移量

/* *
 * swap_offset - takes a swap_entry (saved in pte), and returns
 * the corresponding offset in swap mem_map.
 * */
#define swap_offset(entry) ({                                       \
               size_t __offset = (entry >> 8);                        \
               if (!(__offset > 0 && __offset < max_swap_offset)) {    \
                    panic("invalid swap_entry_t = %08x.\n", entry);    \
               }                                                    \
               __offset;                                            \
          })

struct swap_manager
{
     const char *name; // 交换管理器的名称
     /* Global initialization for the swap manager */
     int (*init)            (void); // 初始化交换管理器
     /* Initialize the priv data inside mm_struct */
     int (*init_mm)         (struct mm_struct *mm); // 初始化mm_struct中的私有数据
     /* Called when tick interrupt occured */
     int (*tick_event)      (struct mm_struct *mm); // 每次时钟中断调用
     /* Called when map a swappable page into the mm_struct */
     int (*map_swappable)   (struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in); // 将可交换页面映射到mm_struct
     /* When a page is marked as shared, this routine is called to
      * delete the addr entry from the swap manager */
     int (*set_unswappable) (struct mm_struct *mm, uintptr_t addr); // 将页面标记为不可交换
     /* Try to swap out a page, return then victim */
     int (*swap_out_victim) (struct mm_struct *mm, struct Page **ptr_page, int in_tick); // 尝试交换出一个页面
     /* check the page relpacement algorithm */
     int (*check_swap)(void); // 检查页面替换算法
};

extern volatile int swap_init_ok; // 声明外部变量swap_init_ok，表示交换初始化是否成功
extern list_entry_t pra_list_head;
int swap_init(void); // 交换初始化函数
int swap_init_mm(struct mm_struct *mm); // 初始化mm_struct中的交换数据
int swap_tick_event(struct mm_struct *mm); // 时钟中断事件处理
int swap_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in); // 映射可交换页面
int swap_set_unswappable(struct mm_struct *mm, uintptr_t addr); // 设置页面为不可交换
int swap_out(struct mm_struct *mm, int n, int in_tick); // 交换出n个页面
int swap_in(struct mm_struct *mm, uintptr_t addr, struct Page **ptr_result); // 交换入指定地址的页面

//#define MEMBER_OFFSET(m,t) ((int)(&((t *)0)->m)) // 获取成员在结构体中的偏移量
//#define FROM_MEMBER(m,t,a) ((t *)((char *)(a) - MEMBER_OFFSET(m,t))) // 根据成员和成员地址获取结构体的指针

#endif /* !__KERN_MM_SWAP_H__ */

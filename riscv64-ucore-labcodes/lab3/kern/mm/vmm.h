#ifndef __KERN_MM_VMM_H__ // 如果没有定义__KERN_MM_VMM_H__，则执行以下代码
#define __KERN_MM_VMM_H__  // 定义__KERN_MM_VMM_H__，防止头文件被重复包含

#include <defs.h>          // 包含定义库，可能包含一些基本类型和宏定义
#include <list.h>          // 包含链表操作相关的头文件
#include <memlayout.h>     // 包含内存布局相关的头文件
#include <sync.h>          // 包含同步原语，如锁等

// 预定义
struct mm_struct;

// 定义虚拟内存区域（vma），[vma.vm_start, vm_end)，属于某个vma的地址意味着 vm_start <= addr < vm_end
struct vma_struct {
    struct mm_struct *vm_mm;   // 使用相同页目录表（PDT）的一组vma
    uintptr_t vm_start;        // vma的起始地址
    uintptr_t vm_end;          // vma的结束地址，不包括vm_end本身
    uint_t vm_flags;           // vma的标志
    list_entry_t list_link;    // 按vma的起始地址排序的线性链表链接
};

#define le2vma(le, member)                      \
    to_struct((le), struct vma_struct, member)  // 宏，用于从链表条目获取vma结构体指针

#define VM_READ       0x00000001               // vma可读
#define VM_WRITE      0x00000002               // vma可写
#define VM_EXEC       0x00000004               // vma可执行

// 定义控制一组使用相同页目录表（PDT）的vma的结构体
struct mm_struct {
    list_entry_t mmap_list;   // 按vma的起始地址排序的线性链表链接
    struct vma_struct *mmap_cache; // 最近访问的vma，用于加速目的
    pde_t *pgdir;             // 这些vma的页目录表
    int map_count;            // 这些vma的数量
    void *sm_priv;            // 交换管理器的私有数据
};

// 函数声明
struct vma_struct *find_vma(struct mm_struct *mm, uintptr_t addr); // 在mm中查找包含addr的vma
struct vma_struct *vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags); // 创建一个新的vma
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma); // 将vma插入到mm中

struct mm_struct *mm_create(void); // 创建一个新的mm结构体
void mm_destroy(struct mm_struct *mm); // 销毁mm结构体

void vmm_init(void); // 初始化虚拟内存管理模块

int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr); // 处理缺页异常

extern volatile unsigned int pgfault_num; // 外部定义的缺页异常次数
extern struct mm_struct *check_mm_struct; // 外部定义的用于检查的mm结构体指针

#endif /* !__KERN_MM_VMM_H__ */
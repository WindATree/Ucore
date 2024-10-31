#ifndef __KERN_MM_VMM_H__ // 如果没有定义 __KERN_MM_VMM_H__，则执行以下代码
#define __KERN_MM_VMM_H__  // 定义 __KERN_MM_VMM_H__，防止头文件被重复包含

#include <defs.h>          // 包含一些基础定义，可能包括基本类型和宏定义
#include <list.h>          // 包含链表操作相关的头文件
#include <memlayout.h>     // 包含内存布局相关的定义
#include <sync.h>          // 包含同步机制的定义，如锁等

// 预定义结构体 mm_struct
struct mm_struct;

// 定义虚拟内存区域（vma）结构体
// [vma.vm_start, vma.vm_end)，属于该 vma 的地址满足条件 vm_start <= addr < vm_end
struct vma_struct {
    struct mm_struct *vm_mm;   // 指向使用相同页目录表（PDT）的一组 vma
    uintptr_t vm_start;        // vma 的起始地址
    uintptr_t vm_end;          // vma 的结束地址（不包含 vm_end 本身）
    uint_t vm_flags;           // vma 的权限标志
    list_entry_t list_link;    // 链表链接，用于按 vma 的起始地址排序
};

// 宏 le2vma，将链表条目转换为 vma 结构体指针
#define le2vma(le, member)                      \
    to_struct((le), struct vma_struct, member) 

// vma 的权限标志
#define VM_READ       0x00000001               // vma 可读权限
#define VM_WRITE      0x00000002               // vma 可写权限
#define VM_EXEC       0x00000004               // vma 可执行权限

// 定义 mm_struct 结构体，用于管理一组使用相同页目录表（PDT）的 vma
//一个 mm_struct 管理一个进程的所有 vma_struct，每个进程的内存空间可能包含多个 vma
struct mm_struct {
    list_entry_t mmap_list;       // 按 vma 起始地址排序的链表链接
    struct vma_struct *mmap_cache; // 最近访问的 vma，用于加速查找
    pde_t *pgdir;                 // 页目录表的指针，供该组 vma 使用
    int map_count;                // 当前 mm 中的 vma 数量
    void *sm_priv;                // 交换管理器的私有数据指针
};

// 函数声明
struct vma_struct *find_vma(struct mm_struct *mm, uintptr_t addr); // 查找包含 addr 的 vma
struct vma_struct *vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags); // 创建新的 vma
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma); // 将 vma 插入到 mm 的链表中

struct mm_struct *mm_create(void); // 创建一个新的 mm 结构体
void mm_destroy(struct mm_struct *mm); // 销毁 mm 结构体

void vmm_init(void); // 初始化虚拟内存管理模块

int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr); // 处理缺页异常

// 外部变量声明
extern volatile unsigned int pgfault_num; // 外部定义的缺页异常次数计数器
extern struct mm_struct *check_mm_struct; // 外部定义的 mm 结构体指针，用于测试和检查

#endif /* !__KERN_MM_VMM_H__ */ // 结束条件编译

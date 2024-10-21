#ifndef __KERN_MM_VMM_H__
#define __KERN_MM_VMM_H__

#include <defs.h>
#include <list.h>
#include <memlayout.h>
#include <sync.h>
#include <sem.h>
#include <proc.h>
// 预先定义
struct mm_struct;

// 虚拟连续内存区域(vma)，[vma.vm_start, vm_end)，属于某个vma的地址意味着 vm_start <= addr < vm_end
struct vma_struct {
    struct mm_struct *vm_mm; // 使用相同页目录表的vma集合
    uintptr_t vm_start;      // vma的起始地址      
    uintptr_t vm_end;        // vma的结束地址，不包括vm_end本身
    uint32_t vm_flags;       // vma的标志
    list_entry_t list_link;  // 按vma的起始地址排序的线性列表链接
};

#define le2vma(le, member)                  \
    to_struct((le), struct vma_struct, member)

#define VM_READ                 0x00000001  // 可读权限
#define VM_WRITE                0x00000002  // 可写权限
#define VM_EXEC                 0x00000004  // 可执行权限
#define VM_STACK                0x00000008  // 栈内存区域

// 使用相同页目录表的一组vma的控制结构
struct mm_struct {
    list_entry_t mmap_list;        // 按vma的起始地址排序的线性列表链接
    struct vma_struct *mmap_cache; // 当前访问的vma，用于加速
    pde_t *pgdir;                  // 这些vma的页目录表
    int map_count;                 // 这些vma的数量
    void *sm_priv;                 // 交换空间管理器的私有数据
    int mm_count;                  // 共享该mm的进程数量
    semaphore_t mm_sem;            // 用于复制mm的dup_mmap函数的互斥锁
    int locked_by;                 // 当前锁定该mm的进程PID
};

// 查找给定地址的vma结构
struct vma_struct *find_vma(struct mm_struct *mm, uintptr_t addr);
// 创建一个新的vma结构
struct vma_struct *vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags);
// 将vma结构插入到mm_struct中
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma);

// 创建一个新的mm_struct
struct mm_struct *mm_create(void);
// 销毁一个mm_struct
void mm_destroy(struct mm_struct *mm);

// 初始化虚拟内存管理器
void vmm_init(void);
// 映射内存
int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store);
// 处理缺页
int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr);

// 解除映射内存
int mm_unmap(struct mm_struct *mm, uintptr_t addr, size_t len);
// 复制内存映射
int dup_mmap(struct mm_struct *to, struct mm_struct *from);
// 进程退出时清理内存映射
void exit_mmap(struct mm_struct *mm);
// 获取未映射区域
uintptr_t get_unmapped_area(struct mm_struct *mm, size_t len);
// 内存分配的break操作
int mm_brk(struct mm_struct *mm, uintptr_t addr, size_t len);

// 跟踪缺页数量的外部变量
extern volatile unsigned int pgfault_num;
// 检查mm_struct的外部变量
extern struct mm_struct *check_mm_struct;

// 用户内存检查和复制函数
bool user_mem_check(struct mm_struct *mm, uintptr_t start, size_t len, bool write);
bool copy_from_user(struct mm_struct *mm, void *dst, const void *src, size_t len, bool writable);
bool copy_to_user(struct mm_struct *mm, void *dst, const void *src, size_t len);
bool copy_string(struct mm_struct *mm, char *dst, const char *src, size_t maxn);

// 管理mm_struct中的mm_count字段的内联函数
static inline int
mm_count(struct mm_struct *mm) {
    return mm->mm_count;
}

static inline void
set_mm_count(struct mm_struct *mm, int val) {
    mm->mm_count = val;
}

static inline int
mm_count_inc(struct mm_struct *mm) {
    mm->mm_count += 1;
    return mm->mm_count;
}

static inline int
mm_count_dec(struct mm_struct *mm) {
    mm->mm_count -= 1;
    return mm->mm_count;
}

// 锁定和解锁mm_struct的内联函数
static inline void
lock_mm(struct mm_struct *mm) {
    if (mm != NULL) {
        down(&(mm->mm_sem));
        if (current != NULL) {
            mm->locked_by = current->pid;
        }
    }
}

static inline void
unlock_mm(struct mm_struct *mm) {
    if (mm != NULL) {
        up(&(mm->mm_sem));
        mm->locked_by = 0;
    }
}

#endif /* !__KERN_MM_VMM_H__ */
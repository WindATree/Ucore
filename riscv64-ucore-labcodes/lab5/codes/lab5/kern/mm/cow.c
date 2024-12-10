#include <cow.h>
#include <kmalloc.h>
#include <string.h>
#include <sync.h>
#include <pmm.h>
#include <error.h>
#include <sched.h>
#include <elf.h>
#include <vmm.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <unistd.h>

// 设置进程的页目录，并初始化为内核页目录的副本
static int
setup_pgdir(struct mm_struct *mm) {
    struct Page *page;
    // 分配一页内存
    if ((page = alloc_page()) == NULL) {
        return -E_NO_MEM;  // 分配失败，返回内存不足错误
    }
    pde_t *pgdir = page2kva(page);
    // 将内核页目录的内容复制到新分配的页目录
    memcpy(pgdir, boot_pgdir, PGSIZE);

    mm->pgdir = pgdir;  // 将新页目录指针赋值给进程的mm结构体
    return 0;  // 返回成功
}

// 释放进程的页目录
static void
put_pgdir(struct mm_struct *mm) {
    free_page(kva2page(mm->pgdir));  // 释放页目录所占的内存
}

// COW复制内存映射
// 该函数用于将当前进程的内存映射复制到新进程中
int
cow_copy_mm(struct proc_struct *proc) {
    struct mm_struct *mm, *oldmm = current->mm;

    // 如果当前进程没有内存管理结构，则直接返回
    if (oldmm == NULL) {
        return 0;
    }

    int ret = 0;
    // 创建新的内存管理结构
    if ((mm = mm_create()) == NULL) {
        goto bad_mm;  // 如果创建失败，跳转到错误处理
    }

    // 设置页目录
    if (setup_pgdir(mm) != 0) {
        goto bad_pgdir_cleanup_mm;  // 如果页目录设置失败，跳转到错误处理
    }

    // 锁住源进程的内存管理结构
    lock_mm(oldmm);
    {
        // 复制内存映射
        ret = cow_copy_mmap(mm, oldmm);
    }
    unlock_mm(oldmm);

    // 如果内存映射复制失败，进行清理
    if (ret != 0) {
        goto bad_dup_cleanup_mmap;
    }

good_mm:
    mm_count_inc(mm);  // 增加内存管理结构的引用计数
    proc->mm = mm;  // 将新创建的内存管理结构赋值给新进程
    proc->cr3 = PADDR(mm->pgdir);  // 设置新进程的页目录物理地址
    return 0;  // 返回成功

bad_dup_cleanup_mmap:
    exit_mmap(mm);  // 释放内存映射
    put_pgdir(mm);  // 释放页目录

bad_pgdir_cleanup_mm:
    mm_destroy(mm);  // 销毁内存管理结构

bad_mm:
    return ret;  // 返回错误代码
}

// 复制进程的内存映射
int
cow_copy_mmap(struct mm_struct *to, struct mm_struct *from) {
    assert(to != NULL && from != NULL);  // 确保源和目标内存管理结构有效
    list_entry_t *list = &(from->mmap_list), *le = list;
    while ((le = list_prev(le)) != list) {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);  // 获取源进程的内存区域
        // 创建目标进程的对应内存区域
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL) {
            return -E_NO_MEM;  // 如果创建失败，返回内存不足错误
        }
        insert_vma_struct(to, nvma);  // 将新内存区域插入目标进程
        // 复制该内存区域的内容
        if (cow_copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end) != 0) {
            return -E_NO_MEM;  // 如果复制失败，返回内存不足错误
        }
    }
    return 0;  // 返回成功
}

// 复制内存范围，基于写时复制（COW）
int cow_copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end) {
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);  // 确保地址对齐
    assert(USER_ACCESS(start, end));  // 检查是否为用户访问地址
    do {
        // 获取源进程的页表项
        pte_t *ptep = get_pte(from, start, 0);
        if (ptep == NULL) {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
            continue;  // 如果没有页表项，跳过当前页，检查下一个页面
        }

        if (*ptep & PTE_V) {  // 如果该页表项有效
            *ptep &= ~PTE_W;  // 清除写权限，标记为只读（COW）
            uint32_t perm = (*ptep & PTE_USER & ~PTE_W);  // 获取源页面的权限
            struct Page *page = pte2page(*ptep);  // 获取源页面的物理页
            assert(page != NULL);  // 确保页面有效
            int ret = 0;
            // 在目标进程的页表中插入相同的物理页面
            ret = page_insert(to, page, start, perm);
            assert(ret == 0);  // 确保插入成功
        }
        start += PGSIZE;  // 移动到下一个页面
    } while (start != 0 && start < end);  // 遍历整个地址范围

    return 0;  // 返回成功
}

// 处理COW页错误（写时复制的页面错误）
int 
cow_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
    cprintf("COW page fault at 0x%x\n", addr);  // 打印COW页错误信息
    int ret = 0;
    // 获取出错地址的页表项
    pte_t *ptep = get_pte(mm->pgdir, addr, 0);
    // 设置写权限
    uint32_t perm = (*ptep & PTE_USER) | PTE_W;
    struct Page *page = pte2page(*ptep);  // 获取页面的物理页
    struct Page *npage = alloc_page();  // 分配新的物理页面
    assert(page != NULL);  // 确保原页面有效
    assert(npage != NULL);  // 确保新页面有效
    uintptr_t* src = page2kva(page);  // 获取源页面的内核虚拟地址
    uintptr_t* dst = page2kva(npage);  // 获取目标页面的内核虚拟地址
    memcpy(dst, src, PGSIZE);  // 复制源页面到目标页面

    uintptr_t start = ROUNDDOWN(addr, PGSIZE);  // 对地址进行页对齐
    *ptep = 0;  // 清除旧的页表项
    // 在目标进程的页表中插入新的页面
    ret = page_insert(mm->pgdir, npage, start, perm);
    ptep = get_pte(mm->pgdir, addr, 0);  // 更新页表项
    return ret;  // 返回处理结果
}

#include <default_pmm.h>
#include <defs.h>
#include <error.h>
#include <kmalloc.h>
#include <memlayout.h>
#include <mmu.h>
#include <pmm.h>
#include <sbi.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <sync.h>
#include <vmm.h>
#include <riscv.h>

 
// virtual address of physical page array
struct Page *pages;
// amount of physical memory (in pages)
size_t npage = 0;
// The kernel image is mapped at VA=KERNBASE and PA=info.base
uint_t va_pa_offset;
// memory starts at 0x80000000 in RISC-V
const size_t nbase = DRAM_BASE / PGSIZE;

// virtual address of boot-time page directory
pde_t *boot_pgdir = NULL;
// physical address of boot-time page directory
uintptr_t boot_cr3;

// physical memory management
const struct pmm_manager *pmm_manager;

static void check_alloc_page(void);
static void check_pgdir(void);
static void check_boot_pgdir(void);

// init_pmm_manager - initialize a pmm_manager instance
static void init_pmm_manager(void) {
    pmm_manager = &default_pmm_manager;
    cprintf("memory management: %s\n", pmm_manager->name);
    pmm_manager->init();
}

// init_memmap - call pmm->init_memmap to build Page struct for free memory
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;

    while (1) {
        local_intr_save(intr_flag);
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
    }
    local_intr_restore(intr_flag);
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
    }
    local_intr_restore(intr_flag);
    return ret;
}

/* pmm_init - initialize the physical memory management */
static void page_init(void) {
    extern char kern_entry[];

    va_pa_offset = KERNBASE - 0x80200000;

    uint_t mem_begin = KERNEL_BEGIN_PADDR;
    uint_t mem_size = PHYSICAL_MEMORY_END - KERNEL_BEGIN_PADDR;
    uint_t mem_end = PHYSICAL_MEMORY_END;

    cprintf("physcial memory map:\n");
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
            mem_end - 1);

    uint64_t maxpa = mem_end;

    if (maxpa > KERNTOP) {
        maxpa = KERNTOP;
    }

    extern char end[];

    npage = maxpa / PGSIZE;
    // BBL has put the initial page table at the first available page after the
    // kernel
    // so stay away from it by adding extra offset to end
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);

    for (size_t i = 0; i < npage - nbase; i++) {
        SetPageReserved(pages + i);
    }

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));

    mem_begin = ROUNDUP(freemem, PGSIZE);
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
    if (freemem < mem_end) {
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
    cprintf("vapaofset is %llu\n",va_pa_offset);
}

/* 
 * boot_map_segment - 设置并启用分页机制
 * 
 * 功能：该函数将指定的物理内存区域映射到内核的虚拟地址空间。
 * 参数：
 *   pgdir  - 页目录指针，用于管理虚拟地址到物理地址的映射
 *   la     - 线性地址（映射后的虚拟地址）
 *   size   - 需要映射的内存大小
 *   pa     - 物理地址（待映射的物理内存地址）
 *   perm   - 权限标志，表示对该内存区域的访问权限
 */
static void boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size,
                             uintptr_t pa, uint32_t perm) {
    // 检查线性地址和物理地址的偏移是否一致
    assert(PGOFF(la) == PGOFF(pa));  // 确保虚拟地址和物理地址的页偏移一致

    // 计算需要映射的页数，round up size，并按页对齐
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;

    // 对线性地址和物理地址进行页对齐处理
    la = ROUNDDOWN(la, PGSIZE);  // 将虚拟地址对齐到页边界
    pa = ROUNDDOWN(pa, PGSIZE);  // 将物理地址对齐到页边界

    // 遍历每一页，进行映射
    for (; n > 0; n--, la += PGSIZE, pa += PGSIZE) {
        // 获取该线性地址对应的页表项，如果不存在则创建
        pte_t *ptep = get_pte(pgdir, la, 1);  
        assert(ptep != NULL);  // 确保页表项非空

        // 设置该页表项，将物理地址和权限写入页表项
        *ptep = pte_create(pa >> PGSHIFT, PTE_V | perm);  // 物理地址右移，设置权限标志
    }
}

/* 
 * boot_alloc_page - 分配一个页面并返回该页面的内核虚拟地址
 * 
 * 功能：该函数使用 `alloc_page()` 分配一页物理内存，并返回该页的内核虚拟地址。
 * 返回值：
 *   - 返回分配的内核虚拟地址
 * 注意：此函数通常用于为页目录（PDT）和页表（PT）分配内存
 */
static void *boot_alloc_page(void) {
    // 使用物理内存管理器分配一页内存
    struct Page *p = alloc_page();
    
    // 如果分配失败，则触发 panic
    if (p == NULL) {
        panic("boot_alloc_page failed.\n");  // 分配失败，打印错误信息并停止系统
    }
    
    // 将分配的物理页面转换为内核虚拟地址并返回
    return page2kva(p);  // 返回该页的内核虚拟地址
}


// pmm_init - setup a pmm to manage physical memory, build PDT&PT to setup
// paging mechanism
//         - check the correctness of pmm & paging mechanism, print PDT&PT
void pmm_init(void) {
    // We need to alloc/free the physical memory (granularity is 4KB or other
    // size).
    // So a framework of physical memory manager (struct pmm_manager)is defined
    // in pmm.h
    // First we should init a physical memory manager(pmm) based on the
    // framework.
    // Then pmm can alloc/free the physical memory.
    // Now the first_fit/best_fit/worst_fit/buddy_system pmm are available.
    init_pmm_manager();

    // detect physical memory space, reserve already used memory,
    // then use pmm->init_memmap to create free page list
    page_init();

    // use pmm->check to verify the correctness of the alloc/free function in a
    // pmm
    check_alloc_page();

    // create boot_pgdir, an initial page directory(Page Directory Table, PDT)
    extern char boot_page_table_sv39[];
    boot_pgdir = (pte_t*)boot_page_table_sv39;
    boot_cr3 = PADDR(boot_pgdir);

    check_pgdir();

    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);

    // now the basic virtual memory map(see memalyout.h) is established.
    // check the correctness of the basic virtual memory map.
    check_boot_pgdir();


    kmalloc_init();
}

// get_pte - get pte and return the kernel virtual address of this pte for la
//        - if the PT contians this pte didn't exist, alloc a page for PT
// parameter:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)];
    if (!(*pdep1 & PTE_V)) {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V)) {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
        }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
}

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
    pte_t *ptep = get_pte(pgdir, la, 0);
    if (ptep_store != NULL) {
        *ptep_store = ptep;
    }
    if (ptep != NULL && *ptep & PTE_V) {
        return pte2page(*ptep);
    }
    return NULL;
}

// page_remove_pte - free an Page sturct which is related linear address la
//                - and clean(invalidate) pte which is related linear address la
// note: PT is changed, so the TLB need to be invalidate
static inline void page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
        struct Page *page =
            pte2page(*ptep);  //(2) find corresponding page to pte
        page_ref_dec(page);   //(3) decrease page reference
        if (page_ref(page) ==
            0) {  //(4) and free this page when page reference reachs 0
            free_page(page);
        }
        *ptep = 0;                  //(5) clear second page table entry
        tlb_invalidate(pgdir, la);  //(6) flush tlb
    }
}

/* 
 * unmap_range - 解除一段地址范围的映射
 * 
 * 功能：解除指定虚拟地址范围内的所有内存页的映射。
 * 参数：
 *   pgdir  - 页目录指针
 *   start  - 起始虚拟地址
 *   end    - 结束虚拟地址
 */
void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
    // 检查起始地址和结束地址是否对齐到页面边界
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    
    // 检查地址范围是否在用户空间内
    assert(USER_ACCESS(start, end));

    do {
        // 获取当前虚拟地址对应的页表项，如果不存在则跳过
        pte_t *ptep = get_pte(pgdir, start, 0);
        if (ptep == NULL) {
            // 如果页表项为空，移动到下一个页目录并继续
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
            continue;
        }

        // 如果页表项有效（即映射存在），解除映射
        if (*ptep != 0) {
            page_remove_pte(pgdir, start, ptep);
        }

        // 继续处理下一个页面
        start += PGSIZE;
    } while (start != 0 && start < end);  // 直到遍历完整个地址范围
}

/* 
 * exit_range - 释放指定地址范围的页面和相关资源
 * 
 * 功能：释放指定虚拟地址范围内的所有页面及其对应的页表。
 * 参数：
 *   pgdir  - 页目录指针
 *   start  - 起始虚拟地址
 *   end    - 结束虚拟地址
 */
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
    // 检查起始地址和结束地址是否对齐到页面边界
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    
    // 检查地址范围是否在用户空间内
    assert(USER_ACCESS(start, end));

    uintptr_t d1start, d0start;
    int free_pt, free_pd0;
    pde_t *pd0, *pt, pde1, pde0;

    // 将起始地址按页目录大小对齐
    d1start = ROUNDDOWN(start, PDSIZE);
    d0start = ROUNDDOWN(start, PTSIZE);

    do {
        // 获取第一级页目录项
        pde1 = pgdir[PDX1(d1start)];
        
        // 如果该页目录项有效，继续处理
        if (pde1 & PTE_V) {
            // 获取第二级页目录（页表）
            pd0 = page2kva(pde2page(pde1));
            // 尝试释放所有指向的页表
            free_pd0 = 1;
            
            do {
                // 获取当前页表项
                pde0 = pd0[PDX0(d0start)];

                // 如果该页表项有效，检查页表项是否可以释放
                if (pde0 & PTE_V) {
                    pt = page2kva(pde2page(pde0));
                    // 尝试释放页表
                    free_pt = 1;
                    for (int i = 0; i < NPTEENTRY; i++) {
                        if (pt[i] & PTE_V) {
                            // 如果有任何一个页表项有效，表示页表不能释放
                            free_pt = 0;
                            break;
                        }
                    }

                    // 如果所有页表项都无效，释放页表
                    if (free_pt) {
                        free_page(pde2page(pde0));  // 释放页表的物理页面
                        pd0[PDX0(d0start)] = 0;     // 清除该页目录项
                    }
                } else {
                    free_pd0 = 0;  // 如果该页目录项无效，表示不需要释放该页目录
                }

                // 处理下一个页表项
                d0start += PTSIZE;
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);

            // 如果该二级页目录所有项都已无效，释放该二级页目录
            if (free_pd0) {
                free_page(pde2page(pde1));  // 释放二级页目录
                pgdir[PDX1(d1start)] = 0;   // 清除一级页目录项
            }
        }

        // 处理下一个一级页目录项
        d1start += PDSIZE;
        d0start = d1start;
    } while (d1start != 0 && d1start < end);  // 遍历整个地址范围
}
/* 
 * copy_range - 将进程A的内存内容从[start, end]复制到进程B的对应内存范围
 * 
 * 功能：将进程A的指定内存区域内容复制到进程B的指定内存区域。通常用于进程的内存映射复制，
 *       比如在创建新进程时，复制其父进程的内存映射。
 * 
 * 参数：
 *   to    - 目标进程B的页目录地址
 *   from  - 源进程A的页目录地址
 *   start - 要复制的起始地址
 *   end   - 要复制的结束地址
 *   share - 标志，指示是复制还是共享。在这里我们使用复制方法，因此该标志并未使用。
 *
 * 调用图：copy_mm --> dup_mmap --> copy_range
 */
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end,
               bool share) {
    // 确保起始地址和结束地址对齐到页面边界
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    
    // 检查地址范围是否在用户空间内
    assert(USER_ACCESS(start, end));

    // 以页面为单位复制内存内容
    do {
        // 获取源进程A中，虚拟地址start对应的页表项
        pte_t *ptep = get_pte(from, start, 0), *nptep;
        
        // 如果该页表项为空，则跳过当前页并继续
        if (ptep == NULL) {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
            continue;
        }
        
        // 如果源进程的页表项有效，尝试获取目标进程B的页表项，如果该页表项为空，则分配新的页表
        if (*ptep & PTE_V) {
            if ((nptep = get_pte(to, start, 1)) == NULL) {
                // 如果分配页表失败，返回内存不足错误
                return -E_NO_MEM;
            }
            
            // 获取源页的权限标志（如用户权限）
            uint32_t perm = (*ptep & PTE_USER);
            
            // 获取源页面的物理页面结构
            struct Page *page = pte2page(*ptep);
            
            // 为目标进程B分配一个新的页面
            struct Page *npage = alloc_page();
            assert(page != NULL);  // 确保源页面有效
            assert(npage != NULL); // 确保为目标进程分配的页面有效

            int ret = 0;
            /* LAB5:EXERCISE2 YOUR CODE
             * 复制源页面的内容到目标页面，并建立物理地址和线性地址的映射关系
             *
             * 可以使用以下宏和函数来帮助实现：
             *  - page2kva(struct Page *page): 获取页面管理的内核虚拟地址（参见 pmm.h）
             *  - page_insert: 将物理页面映射到目标进程的线性地址
             *  - memcpy: 常规内存复制函数
             *
             * 复制过程步骤：
             * (1) 查找源页面的内核虚拟地址 src_kvaddr
             * (2) 查找目标页面的内核虚拟地址 dst_kvaddr
             * (3) 从 src_kvaddr 复制到 dst_kvaddr，复制的大小为一个页面大小
             * (4) 使用 page_insert 建立目标进程的物理地址映射
             */

            // 获取源页面的内核虚拟地址
            uintptr_t* src = page2kva(page);
            
            // 获取目标页面的内核虚拟地址
            uintptr_t* dst = page2kva(npage);
            
            // 复制页面内容
            memcpy(dst, src, PGSIZE);

            // 为目标进程B建立物理页面与线性地址的映射
            ret = page_insert(to, npage, start, perm);

            // 确保页插入成功
            assert(ret == 0);
        }

        // 移动到下一个页面
        start += PGSIZE;
    } while (start != 0 && start < end);  // 遍历整个地址范围

    return 0;  // 返回成功
}


// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la) {
    pte_t *ptep = get_pte(pgdir, la, 0);
    if (ptep != NULL) {
        page_remove_pte(pgdir, la, ptep);
    }
}

// page_insert - build the map of phy addr of an Page with the linear addr la
// paramemters:
//  pgdir: the kernel virtual base address of PDT
//  page:  the Page which need to map
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
// note: PT is changed, so the TLB need to be invalidate
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
    pte_t *ptep = get_pte(pgdir, la, 1);
    if (ptep == NULL) {
        return -E_NO_MEM;
    }
    page_ref_inc(page);
    if (*ptep & PTE_V) {
        struct Page *p = pte2page(*ptep);
        if (p == page) {
            page_ref_dec(page);
        } else {
            page_remove_pte(pgdir, la, ptep);
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
    tlb_invalidate(pgdir, la);
    return 0;
}

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    asm volatile("sfence.vma %0" : : "r"(la));
}

// pgdir_alloc_page - call alloc_page & page_insert functions to
//                  - allocate a page size memory & setup an addr map
//                  - pa<->la with linear address la and the PDT pgdir
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
    struct Page *page = alloc_page();
    if (page != NULL) {
        if (page_insert(pgdir, page, la, perm) != 0) {
            free_page(page);
            return NULL;
        }
        if (swap_init_ok) {
            if (check_mm_struct != NULL) {
                swap_map_swappable(check_mm_struct, la, page, 0);
                page->pra_vaddr = la;
                assert(page_ref(page) == 1);
                // cprintf("get No. %d  page: pra_vaddr %x, pra_link.prev %x,
                // pra_link_next %x in pgdir_alloc_page\n", (page-pages),
                // page->pra_vaddr,page->pra_page_link.prev,
                // page->pra_page_link.next);
            } else {  // now current is existed, should fix it in the future
                // swap_map_swappable(current->mm, la, page, 0);
                // page->pra_vaddr=la;
                // assert(page_ref(page) == 1);
                // panic("pgdir_alloc_page: no pages. now current is existed,
                // should fix it in the future\n");
            }
        }
    }

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
    cprintf("check_alloc_page() succeeded!\n");
}

static void check_pgdir(void) {
    // assert(npage <= KMEMSIZE / PGSIZE);
    // The memory starts at 2GB in RISC-V
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
    assert(pte2page(*ptep) == p1);
    assert(page_ref(p1) == 1);

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);

    p2 = alloc_page();
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
    assert(*ptep & PTE_U);
    assert(*ptep & PTE_W);
    assert(boot_pgdir[0] & PTE_U);
    assert(page_ref(p2) == 1);

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
    assert(page_ref(p1) == 2);
    assert(page_ref(p2) == 0);
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
    assert(pte2page(*ptep) == p1);
    assert((*ptep & PTE_U) == 0);

    page_remove(boot_pgdir, 0x0);
    assert(page_ref(p1) == 1);
    assert(page_ref(p2) == 0);

    page_remove(boot_pgdir, PGSIZE);
    assert(page_ref(p1) == 0);
    assert(page_ref(p2) == 0);

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
    flush_tlb();

    assert(nr_free_store==nr_free_pages());

    cprintf("check_pgdir() succeeded!\n");
}

static void check_boot_pgdir(void) {
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
    }


    assert(boot_pgdir[0] == 0);

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
    assert(page_ref(p) == 1);
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
    assert(page_ref(p) == 2);

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);

    *(char *)(page2kva(p) + 0x100) = '\0';
    assert(strlen((const char *)0x100) == 0);

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
    flush_tlb();

    assert(nr_free_store==nr_free_pages());

    cprintf("check_boot_pgdir() succeeded!\n");
}

// perm2str - use string 'u,r,w,-' to present the permission
static const char *perm2str(int perm) {
    static char str[4];
    str[0] = (perm & PTE_U) ? 'u' : '-';
    str[1] = 'r';
    str[2] = (perm & PTE_W) ? 'w' : '-';
    str[3] = '\0';
    return str;
}

// get_pgtable_items - In [left, right] range of PDT or PT, find a continuous
// linear addr space
//                  - (left_store*X_SIZE~right_store*X_SIZE) for PDT or PT
//                  - X_SIZE=PTSIZE=4M, if PDT; X_SIZE=PGSIZE=4K, if PT
// paramemters:
//  left:        no use ???
//  right:       the high side of table's range
//  start:       the low side of table's range
//  table:       the beginning addr of table
//  left_store:  the pointer of the high side of table's next range
//  right_store: the pointer of the low side of table's next range
// return value: 0 - not a invalid item range, perm - a valid item range with
// perm permission
static int get_pgtable_items(size_t left, size_t right, size_t start,
                             uintptr_t *table, size_t *left_store,
                             size_t *right_store) {
    if (start >= right) {
        return 0;
    }
    while (start < right && !(table[start] & PTE_V)) {
        start++;
    }
    if (start < right) {
        if (left_store != NULL) {
            *left_store = start;
        }
        int perm = (table[start++] & PTE_USER);
        while (start < right && (table[start] & PTE_USER) == perm) {
            start++;
        }
        if (right_store != NULL) {
            *right_store = start;
        }
        return perm;
    }
    return 0;
}


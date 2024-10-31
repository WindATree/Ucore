#include <default_pmm.h>
#include <defs.h>
#include <error.h>
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

// 物理页数组的虚拟地址
struct Page *pages; // 用于管理物理页数组，每个 Page 结构体对应一个物理页

// 物理内存页数量（以页为单位）
size_t npage = 0; // 系统中的物理内存页数量

// 内核镜像映射在 VA=KERNBASE 和 PA=info.base 之间的偏移量
uint_t va_pa_offset; // 内核虚拟地址和物理地址的偏移量，用于虚拟地址到物理地址的转换

// RISC-V 中内存起始地址为 0x80000000
const size_t nbase = DRAM_BASE / PGSIZE; // RISC-V 架构下物理内存的起始页帧号

// 启动时页目录的虚拟地址
pde_t *boot_pgdir = NULL; // 内核启动时的页目录的虚拟地址

// 启动时页目录的物理地址
uintptr_t boot_cr3; // 启动时页目录的物理地址（通常加载到 CR3 寄存器以启动分页）

// 物理内存管理
const struct pmm_manager *pmm_manager; // 指向物理内存管理器结构体，定义物理内存管理的具体操作


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

// alloc_pages - 调用 pmm_manager->alloc_pages 分配连续的 n * PAGESIZE 大小的内存
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL; // 用于保存分配得到的 Page 指针
    bool intr_flag; // 保存中断状态

    while (1) { // 无限循环，直到成功分配内存或退出
        local_intr_save(intr_flag); // 关闭中断并保存当前中断状态
        { 
            page = pmm_manager->alloc_pages(n); // 调用内存管理器的分配函数
        }
        local_intr_restore(intr_flag); // 恢复中断状态

        if (page != NULL || n > 1 || swap_init_ok == 0) break; // 成功分配到内存或不需要交换则退出循环

        extern struct mm_struct *check_mm_struct; // 引用当前内存管理结构体
        swap_out(check_mm_struct, n, 0); // 调用 swap_out 函数进行页面置换，尝试释放内存
    }
    return page; // 返回分配得到的 Page 指针
}

// free_pages - 调用 pmm_manager->free_pages 释放连续的 n * PAGESIZE 大小的内存
void free_pages(struct Page *base, size_t n) {
    bool intr_flag; // 保存中断状态

    local_intr_save(intr_flag); // 关闭中断并保存当前中断状态
    { 
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
    }
    local_intr_restore(intr_flag); // 恢复中断状态
}


// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    { ret = pmm_manager->nr_free_pages(); }
    local_intr_restore(intr_flag);
    return ret;
}

/* page_init - 初始化物理内存管理 */
static void page_init(void) {
    extern char kern_entry[]; // 内核入口地址

    va_pa_offset = KERNBASE - 0x80200000; // 设置内核虚拟地址与物理地址之间的偏移量
    uint64_t mem_begin = KERNEL_BEGIN_PADDR; // 内核起始物理地址
    uint64_t mem_size = PHYSICAL_MEMORY_END - KERNEL_BEGIN_PADDR; // 内核使用的物理内存大小
    uint64_t mem_end = PHYSICAL_MEMORY_END; // 物理内存结束地址（硬编码值取代 sbi_query_memory() 接口查询）
    
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size); // 打印物理内存信息
    cprintf("physcial memory map:\n"); 
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin, mem_end - 1); // 打印物理内存范围

    uint64_t maxpa = mem_end; // 设置最大物理地址为物理内存结束地址

    if (maxpa > KERNTOP) { // 若最大物理地址超出内核的顶部，则限制为 KERNTOP
        maxpa = KERNTOP;
    }

    extern char end[]; // 内核代码和数据的结束地址

    npage = maxpa / PGSIZE; // 计算系统物理页总数

    // BBL 已将初始页表放在内核后面的第一个可用页面，添加偏移量以避开它
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE); // 将 pages 数组放置在内核结束地址之后的第一个页对齐位置
    for (size_t i = 0; i < npage - nbase; i++) {
        SetPageReserved(pages + i); // 标记每页为保留状态，防止被分配
    }

    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 获取 pages 数组后面第一个空闲物理地址
    mem_begin = ROUNDUP(freemem, PGSIZE); // 对齐到页边界
    mem_end = ROUNDDOWN(mem_end, PGSIZE); // 物理内存结束地址对齐到页边界

    if (freemem < mem_end) { // 如果存在空闲的物理内存区域，则初始化空闲内存页面
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE); // 初始化空闲页的内存映射
    }
}

/* enable_paging - 启用分页 */
static void enable_paging(void) {
    write_csr(satp, (0x8000000000000000) | (boot_cr3 >> RISCV_PGSHIFT)); 
    // 设置 satp 寄存器以启动分页，将页表基地址写入 satp 寄存器，并设置最高位以启用分页
}


/**
 * boot_map_segment - 设置并启用分页机制，将指定的线性地址映射到物理地址
 *
 * @param pgdir  页目录指针
 * @param la     要映射的内存的线性地址
 * @param size   内存大小
 * @param pa     要映射的物理地址
 * @param perm   该内存的权限标志
 */
static void boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size,
                             uintptr_t pa, uint32_t perm) {
    assert(PGOFF(la) == PGOFF(pa)); // 检查线性地址和物理地址的页内偏移是否一致
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE; // 计算需要的页数
    la = ROUNDDOWN(la, PGSIZE); // 对齐线性地址到页边界
    pa = ROUNDDOWN(pa, PGSIZE); // 对齐物理地址到页边界
    for (; n > 0; n--, la += PGSIZE, pa += PGSIZE) { // 遍历每一页进行映射
        pte_t *ptep = get_pte(pgdir, la, 1); // 获取对应线性地址的页表项指针
        assert(ptep != NULL); // 检查页表项是否有效
        *ptep = pte_create(pa >> PGSHIFT, PTE_V | perm); // 设置页表项，存入物理地址和权限
    }
}

/**
 * boot_alloc_page - 使用 pmm->alloc_pages(1) 分配一个页
 * 返回值：分配的页面的内核虚拟地址
 * 说明：用于获取 PDT（页目录表）和 PT（页表）所需的内存
 */
static void *boot_alloc_page(void) {
    struct Page *p = alloc_page(); // 调用 alloc_page 分配一页内存
    if (p == NULL) {
        panic("boot_alloc_page failed.\n"); // 分配失败时触发 panic
    }
    return page2kva(p); // 返回分配的页面的内核虚拟地址
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

    // map all physical memory to linear memory with base linear addr KERNBASE
    // linear_addr KERNBASE~KERNBASE+KMEMSIZE = phy_addr 0~KMEMSIZE
    // But shouldn't use this map until enable_paging() & gdt_init() finished.
    //boot_map_segment(boot_pgdir, KERNBASE, KMEMSIZE, PADDR(KERNBASE),
     //                READ_WRITE_EXEC);

    // temporary map:
    // virtual_addr 3G~3G+4M = linear_addr 0~4M = linear_addr 3G~3G+4M =
    // phy_addr 0~4M
    // boot_pgdir[0] = boot_pgdir[PDX(KERNBASE)];

    //    enable_paging();

    // now the basic virtual memory map(see memalyout.h) is established.
    // check the correctness of the basic virtual memory map.
    check_boot_pgdir();

}

// get_pte - 获取线性地址 la 对应的页表项指针（返回该页表项的内核虚拟地址）
// 如果页表项所在的页表不存在且 create 为真，则分配一个新页以存放页表项
// 参数：
//  pgdir: 页目录的内核虚拟基地址
//  la:    需要映射的线性地址
//  create: 指示是否在缺少页表时创建一个新页表
// 返回值：返回页表项的内核虚拟地址
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    // 获取第一级页目录项（PDX1(la) 获取第一级页目录索引）
    pde_t *pdep1 = &pgdir[PDX1(la)];
    if (!(*pdep1 & PTE_V)) { // 如果第一级页目录项无效
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) { // 若 create 为假或分配失败，返回 NULL
            return NULL;
        }
        set_page_ref(page, 1); // 设置页面的引用计数为 1
        uintptr_t pa = page2pa(page); // 获取物理地址
        memset(KADDR(pa), 0, PGSIZE); // 将该页表清零
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V); // 创建页目录项，设置为用户和有效
    }
    // 获取第二级页目录项，使用 PDX0(la) 索引到正确位置
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
    if (!(*pdep0 & PTE_V)) { // 如果第二级页目录项无效
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) { // 若 create 为假或分配失败，返回 NULL
            return NULL;
        }
        set_page_ref(page, 1); // 设置页面的引用计数为 1
        uintptr_t pa = page2pa(page); // 获取物理地址
        memset(KADDR(pa), 0, PGSIZE); // 将该页表清零
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V); // 创建页目录项，设置为用户和有效
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)]; // 返回最终页表项指针的内核虚拟地址
}

// get_page - 根据页目录 pgdir 获取线性地址 la 对应的 Page 结构体指针
// 若 pte 存在且有效，则返回对应 Page，否则返回 NULL
// 参数：
//  pgdir: 页目录指针
//  la:    线性地址
//  ptep_store: 若不为 NULL，存储指向页表项的指针
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
    pte_t *ptep = get_pte(pgdir, la, 0); // 获取对应的页表项指针
    if (ptep_store != NULL) {
        *ptep_store = ptep; // 将页表项指针存储到 ptep_store
    }
    if (ptep != NULL && *ptep & PTE_V) { // 如果页表项有效
        return pte2page(*ptep); // 返回对应的 Page 结构体指针
    }
    return NULL; // 如果页表项无效，返回 NULL
}

// page_remove_pte - 释放与线性地址 la 关联的 Page 结构体，并清除页表项
// 注意：页表项被修改后，需要手动刷新 TLB
// 参数：
//  pgdir: 页目录指针
//  la:    线性地址
//  ptep:  页表项指针
static inline void page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
    if (*ptep & PTE_V) { // 检查页表项是否有效
        struct Page *page = pte2page(*ptep); // 获取对应的 Page 结构体
        page_ref_dec(page); // 将页面的引用计数减一
        if (page_ref(page) == 0) { // 如果引用计数为0，释放页面
            free_page(page);
        }
        *ptep = 0; // 清除页表项
        tlb_invalidate(pgdir, la); // 刷新 TLB，确保无效映射被清除
    }
}

// page_remove - 释放与线性地址 la 关联的 Page 结构体，并清除对应的页表项
// 参数：
//  pgdir: 页目录指针
//  la:    线性地址
void page_remove(pde_t *pgdir, uintptr_t la) {
    pte_t *ptep = get_pte(pgdir, la, 0); // 获取对应的页表项
    if (ptep != NULL) {
        page_remove_pte(pgdir, la, ptep); // 调用 page_remove_pte 清除页表项并释放页面
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
    pte_t *ptep = get_pte(pgdir, la, 1); // 获取页表项，如果不存在则创建
    if (ptep == NULL) {
        return -E_NO_MEM; // 如果分配失败，返回内存错误
    }
    page_ref_inc(page); // 增加物理页面的引用计数

    if (*ptep & PTE_V) { // 如果页表项已经有效
        struct Page *p = pte2page(*ptep); // 获取当前映射的物理页面
        if (p == page) { // 如果已经是正确的映射
            page_ref_dec(page); // 引用计数减少（因为之前增加了一次）
        } else { // 如果映射的是另一个页面
            page_remove_pte(pgdir, la, ptep); // 删除旧的映射
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm); // 设置新的页表项
    tlb_invalidate(pgdir, la); // 使TLB无效，以确保CPU的缓存与新的页表项同步

    return 0; // 成功返回
}
// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) { flush_tlb(); }

// pgdir_alloc_page - 调用 alloc_page 和 page_insert 函数来分配一个页大小的内存
//                  - 并在页目录 pgdir 中设置从线性地址 la 到物理地址 pa 的映射
// 参数：
//  pgdir: 页目录指针
//  la:    需要映射的线性地址
//  perm:  权限标志
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
    struct Page *page = alloc_page(); // 分配一个物理页
    if (page != NULL) {
        if (page_insert(pgdir, page, la, perm) != 0) { // 插入页表映射，若失败则释放页面并返回 NULL
            free_page(page);
            return NULL;
        }
        if (swap_init_ok) { // 若启用交换功能
            swap_map_swappable(check_mm_struct, la, page, 0); // 将页面标记为可交换
            page->pra_vaddr = la; // 设置页面的虚拟地址
            assert(page_ref(page) == 1); // 确保页面的引用计数为1
        }
    }
    return page; // 返回分配并映射的页面指针
}

// check_alloc_page - 检查内存管理器的分配页面功能
static void check_alloc_page(void) {
    pmm_manager->check(); // 调用物理内存管理器的 check 函数进行自检
    cprintf("check_alloc_page() succeeded!\n"); // 若自检通过，打印成功信息
}

// check_pgdir - 验证页目录 boot_pgdir 的操作是否正确
static void check_pgdir(void) {
    size_t nr_free_store;
    nr_free_store = nr_free_pages(); // 记录当前的空闲页数

    // 检查内核页数和 boot_pgdir 的有效性
    assert(npage <= KERNTOP / PGSIZE);
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL); // 确保虚拟地址 0x0 没有映射

    // 分配物理页面 p1，并将其映射到 0x0 虚拟地址
    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL); // 获取页表项并检查是否正确映射
    assert(pte2page(*ptep) == p1);
    assert(page_ref(p1) == 1);

    // 获取页目录中的页表项，检查虚拟地址 PGSIZE 是否映射正确
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);

    // 分配第二个页面 p2，将其映射到虚拟地址 PGSIZE，赋予用户和写权限
    p2 = alloc_page();
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
    assert(*ptep & PTE_U);
    assert(*ptep & PTE_W);
    assert(boot_pgdir[0] & PTE_U);
    assert(page_ref(p2) == 1);

    // 重新将 p1 映射到 PGSIZE，检查引用计数变化
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
    assert(page_ref(p1) == 2);
    assert(page_ref(p2) == 0);
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
    assert(pte2page(*ptep) == p1);
    assert((*ptep & PTE_U) == 0);

    // 移除 0x0 和 PGSIZE 的映射，检查引用计数
    page_remove(boot_pgdir, 0x0);
    assert(page_ref(p1) == 1);
    assert(page_ref(p2) == 0);
    page_remove(boot_pgdir, PGSIZE);
    assert(page_ref(p1) == 0);
    assert(page_ref(p2) == 0);

    // 确保所有页面的引用计数为0，并释放页目录页面
    pde_t *pd1 = boot_pgdir, *pd0 = page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;

    assert(nr_free_store == nr_free_pages()); // 验证空闲页数是否与之前一致

    cprintf("check_pgdir() succeeded!\n");
}

// check_boot_pgdir - 验证内核页目录 boot_pgdir 是否正确映射
static void check_boot_pgdir(void) {
    size_t nr_free_store;
    pte_t *ptep;
    int i;
    nr_free_store = nr_free_pages(); // 记录当前的空闲页数

    // 验证 boot_pgdir 中是否正确映射内核虚拟地址
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
    }

    assert(boot_pgdir[0] == 0);

    // 分配页面 p，设置映射并检查内容复制和字符串操作的正确性
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

    // 释放分配的页面和页表
    pde_t *pd1 = boot_pgdir, *pd0 = page2kva(pde2page(boot_pgdir[0]));
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;

    assert(nr_free_store == nr_free_pages()); // 确保空闲页数一致

    cprintf("check_boot_pgdir() succeeded!\n");
}

// kmalloc - 内核内存分配函数，分配 n 字节的内存并返回内核虚拟地址
void *kmalloc(size_t n) {
    void *ptr = NULL;
    struct Page *base = NULL;
    assert(n > 0 && n < 1024 * 0124); // 确保分配字节数在范围内
    int num_pages = (n + PGSIZE - 1) / PGSIZE; // 计算所需的页面数
    base = alloc_pages(num_pages); // 分配页面
    assert(base != NULL);
    ptr = page2kva(base); // 将页面转换为内核虚拟地址
    return ptr;
}

// kfree - 内核内存释放函数，释放 ptr 开始的 n 字节内存
void kfree(void *ptr, size_t n) {
    assert(n > 0 && n < 1024 * 0124); // 确保释放字节数在范围内
    assert(ptr != NULL);
    struct Page *base = NULL;
    int num_pages = (n + PGSIZE - 1) / PGSIZE; // 计算所需的页面数
    base = kva2page(ptr); // 获取页面指针
    free_pages(base, num_pages); // 释放页面
}


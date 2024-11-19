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

// 定义了一个指向物理页面数组的虚拟地址指针
struct Page *pages;

// 定义了物理内存的大小（以页面为单位）
size_t npage = 0;

// 内核映像映射在虚拟地址KERNBASE和物理地址info.base
uint_t va_pa_offset;

// 在RISC-V中，内存从0x80000000开始
const size_t nbase = DRAM_BASE / PGSIZE;

// 定义了启动时页目录的虚拟地址
pde_t *boot_pgdir = NULL;

// 定义了启动时页目录的物理地址
uintptr_t boot_cr3;

// 物理内存管理的接口
const struct pmm_manager *pmm_manager;

// 以下三个函数用于检查内存分配、页目录和启动时页目录的有效性
static void check_alloc_page(void);
static void check_pgdir(void);
static void check_boot_pgdir(void);

// init_pmm_manager - 初始化pmm_manager实例
static void init_pmm_manager(void) {
    // 设置pmm_manager为默认的物理内存管理器
    pmm_manager = &default_pmm_manager;
    // 打印内存管理器的名称
    cprintf("memory management: %s\n", pmm_manager->name);
    // 调用内存管理器的初始化函数
    pmm_manager->init();
}

// init_memmap - 调用pmm->init_memmap来为空闲内存构建Page结构
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - 调用pmm->alloc_pages来分配连续的n*PAGESIZE内存
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;

    // 循环直到分配成功或无法分配更多页面
    while (1) {
        // 保存并禁用中断
        local_intr_save(intr_flag);
        {
            // 调用内存管理器的分配页面函数
            page = pmm_manager->alloc_pages(n);
        }
        // 恢复中断状态
        local_intr_restore(intr_flag);

        // 如果页面分配成功，或者请求的页面数超过1，或者交换空间未初始化，则跳出循环
        if (page != NULL || n > 1 || swap_init_ok == 0) break;

        // 如果页面分配失败，且请求的页面数为1，且交换空间已初始化，则尝试交换内存
        extern struct mm_struct *check_mm_struct;
        // swap_out(check_mm_struct, n, 0);
    }
    // 返回分配的页面
    return page;
}

// free_pages - 调用pmm->free_pages来释放连续的n*PAGESIZE内存
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    // 保存并禁用中断
    local_intr_save(intr_flag);
    {
        // 调用内存管理器的释放页面函数
        pmm_manager->free_pages(base, n);
    }
    // 恢复中断状态
    local_intr_restore(intr_flag);
}

// nr_free_pages - 调用pmm->nr_free_pages来获取当前空闲内存的大小（nr*PAGESIZE）
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    // 保存并禁用中断
    local_intr_save(intr_flag);
    {
        // 调用内存管理器的获取空闲页面数函数
        ret = pmm_manager->nr_free_pages();
    }
    // 恢复中断状态
    local_intr_restore(intr_flag);
    // 返回空闲页面数
    return ret;
}

/* pmm_init - 初始化物理内存管理 */
static void page_init(void) {
    extern char kern_entry[];

    // 计算虚拟地址到物理地址的偏移量
    va_pa_offset = KERNBASE - 0x80200000;

    // 初始化内存的开始地址和大小
    uint_t mem_begin = KERNEL_BEGIN_PADDR;
    uint_t mem_size = PHYSICAL_MEMORY_END - KERNEL_BEGIN_PADDR;
    uint_t mem_end = PHYSICAL_MEMORY_END;

    // 打印物理内存映射信息
    cprintf("physcial memory map:\n");
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
            mem_end - 1);

    // 计算最大的物理地址
    uint64_t maxpa = mem_end;

    // 如果最大物理地址超过了内核的顶部地址，则将其设置为内核顶部地址
    if (maxpa > KERNTOP) {
        maxpa = KERNTOP;
    }

    extern char end[];

    // 计算总页数
    npage = maxpa / PGSIZE;
    // BBL将初始页表放置在内核之后的第一个可用页面
    // 因此，通过在end添加额外的偏移量来避开它
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);

    // 将页面标记为保留
    for (size_t i = 0; i < npage - nbase; i++) {
        SetPageReserved(pages + i);
    }

    // 计算可用内存的起始地址
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));

    // 将内存开始和结束地址对齐到页面大小
    mem_begin = ROUNDUP(freemem, PGSIZE);
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
    if (freemem < mem_end) {
        // 初始化内存映射
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
    // 打印虚拟地址到物理地址的偏移量
    cprintf("vapaofset is %llu\n",va_pa_offset);
}

// boot_map_segment - 设置并启用分页机制
// 参数
//  la: 需要映射的线性地址（x86段映射之后）
//  size: 内存大小
//  pa: 内存的物理地址
//  perm: 内存的权限
static void boot_map_segment(pde_t *pgdir, uintptr_t la, size_t size,
                             uintptr_t pa, uint32_t perm) {
    // 断言线性地址和物理地址对齐
    assert(PGOFF(la) == PGOFF(pa));
    // 计算需要映射的页数
    size_t n = ROUNDUP(size + PGOFF(la), PGSIZE) / PGSIZE;
    la = ROUNDDOWN(la, PGSIZE);
    pa = ROUNDDOWN(pa, PGSIZE);
    for (; n > 0; n--, la += PGSIZE, pa += PGSIZE) {
        // 获取页表条目
        pte_t *ptep = get_pte(pgdir, la, 1);
        assert(ptep != NULL);
        // 设置页表条目
        *ptep = pte_create(pa >> PGSHIFT, PTE_V | perm);
    }
}

// boot_alloc_page - 使用pmm->alloc_pages(1)分配一个页面
// 返回值：分配页面的内核虚拟地址
// 注意：此函数用于获取PDT（页目录表）和PT（页表）的内存
static void *boot_alloc_page(void) {
    struct Page *p = alloc_page();
    if (p == NULL) {
        panic("boot_alloc_page failed.\n");
    }
    return page2kva(p);
}

/**
 * 从临时启动页目录切换到新的页目录，并添加一些保护
 * 1. 切换页目录
 * 2. 设置精细的权限(rx, rw...)
 * 3. 将之前的临时启动页目录和另一个专用页面
 *   设置为内核栈的守护页面
 */
static void
switch_kernel_memorylayout(){
    /**
     * 这里不需要释放中间页面，因为最初我们使用
     * 大页面，因此没有中间页面被占用
     */

    // 新的页目录
    pde_t *kern_pgdir = (pde_t *)boot_alloc_page();
    memset(kern_pgdir,0,PGSIZE);

    // 插入内核映射
    extern const char etext[];
    uintptr_t retext = ROUNDUP((uintptr_t)etext,PGSIZE);
    boot_map_segment(kern_pgdir,KERNBASE,retext-KERNBASE,PADDR(KERNBASE),PTE_R|PTE_X);
    boot_map_segment(kern_pgdir,retext,KERNTOP-retext,PADDR(retext),PTE_R|PTE_W);

    // 执行切换
    boot_pgdir = kern_pgdir;
    boot_cr3 = PADDR(boot_pgdir);
    lcr3(boot_cr3);
    flush_tlb();
    cprintf("Page table directory switch succeeded!\n");

    /**
     * 设置内核栈守护页面
     */
    extern char bootstackguard[],boot_page_table_sv39[];
    if ((bootstackguard + PGSIZE == bootstack) && (bootstacktop == boot_page_table_sv39)){
        // 检查可写性并设置为0
        memset(boot_page_table_sv39,0,PGSIZE);
        bootstack[-1] = 0;
        bootstack[-PGSIZE] = 0;

        // 将内核栈下方和上方的页面设置为守护页面
        boot_map_segment(boot_pgdir,bootstackguard,PGSIZE,PADDR(bootstackguard),0);
        boot_map_segment(boot_pgdir,boot_page_table_sv39,PGSIZE,PADDR(boot_page_table_sv39),0);
        flush_tlb();

        // 以下四条语句都应该导致崩溃
        // bootstack[-1] = 0;
        // bootstack[-PGSIZE] = 0;
        // bootstacktop[0] = 0;
        // bootstacktop[PGSIZE-1] = 0;

        cprintf("Kernel stack guardians set succeeded!\n");
    }
}

// pmm_init - 设置pmm来管理物理内存，构建PDT和PT来设置分页机制
//         - 检查pmm和分页机制的正确性，打印PDT和PT
void pmm_init(void) {
    // 我们需要分配/释放物理内存（粒度为4KB或其他大小）。
    // 因此，在pmm.h中定义了一个物理内存管理器（struct pmm_manager）的框架。
    // 首先，我们应该基于这个框架初始化一个物理内存管理器（pmm）。
    // 然后pmm可以分配/释放物理内存。
    // 现在，first_fit/best_fit/worst_fit/buddy_system pmm是可用的。
    init_pmm_manager();

    // 检测物理内存空间，保留已经使用的内存，
    // 然后使用pmm->init_memmap创建空闲页面列表
    page_init();

    // 使用pmm->check验证pmm中alloc/free函数的正确性
    check_alloc_page();

    // 从临时启动页目录切换到精细的内核页目录
    switch_kernel_memorylayout();

    check_pgdir();

    static_assert(KERNBASE % PTSIZE == 0 && KERNTOP % PTSIZE == 0);

    // 现在基本的虚拟内存映射（见memalyout.h）已经建立。
    // 检查基本虚拟内存映射的正确性。
    check_boot_pgdir();


    kmalloc_init();
}

// get_pte - 获取页表项pte，并返回该pte的内核虚拟地址
//        - 如果包含该pte的页表PT不存在，则为PT分配一个页面
// 参数：
//  pgdir: PDT的内核虚拟基地址
//  la:    需要映射的线性地址
//  create: 逻辑值，决定是否为PT分配页面
// 返回值：该pte的内核虚拟地址
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    /*
     * 如果需要访问物理地址，请使用KADDR()函数
     * 请阅读pmm.h了解有用的宏定义
     *
     * 也许你需要帮助注释，以下注释可以帮助你完成代码
     *
     * 一些有用的宏定义和定义，你可以在下面的实现中使用它们。
     * 宏定义或函数：
     *   PDX(la) = 虚拟地址la的页目录项索引。
     *   KADDR(pa) : 接受一个物理地址并返回相应的内核虚拟地址。
     *   set_page_ref(page,1) : 表示页面被引用了一次
     *   page2pa(page): 获取(struct Page *) page管理的内存的物理地址
     *   struct Page * alloc_page() : 分配一个页面
     *   memset(void *s, char c, size_t n) : 将s指向的内存区域的前n个字节
     *                                      设置为指定值c。
     * 定义：
     *   PTE_P           0x001                   // 页表/目录项标志位：存在
     *   PTE_W           0x002                   // 页表/目录项标志位：可写
     *   PTE_U           0x004                   // 页表/目录项标志位：用户可访问
     */
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

// get_page - 使用PDT pgdir获取与线性地址la相关的Page结构
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

// page_remove_pte - 释放与线性地址la相关的Page结构
//                - 并清除（使无效）与线性地址la相关的pte
// 注意：PT已更改，因此需要手动更新TLB
static inline void page_remove_pte(pde_t *pgdir, uintptr_t la, pte_t *ptep) {
    /*LAB2 EXERCISE 3: YOUR CODE
     * 请检查ptep是否有效，如果映射已更新，则必须手动更新tlb
     *
     * 也许你需要帮助注释，以下注释可以帮助你完成代码
     *
     * 一些有用的宏定义和定义，你可以在下面的实现中使用它们。
     * 宏定义或函数：
     *   struct Page *page pte2page(*ptep): 根据ptep的值获取相应的页面
     *   free_page : 释放一个页面
     *   page_ref_dec(page) : 减少page->ref。注意：如果page->ref == 0，
     * 那么这个页面应该被释放。
     *   tlb_invalidate(pde_t *pgdir, uintptr_t la) : 使一个TLB条目无效，
     * 但只有在当前正在编辑的页表是处理器当前使用的页表时。
     * 定义：
     *   PTE_P           0x001                   // 页表/目录项标志位：存在
     */
    if (*ptep & PTE_V) {  //(1)检查这个页表项是否存在
        struct Page *page =
            pte2page(*ptep);  //(2)找到与pte对应的页面
        page_ref_dec(page);   //(3)减少页面引用
        if (page_ref(page) ==
            0) {  //(4)当页面引用数达到0时释放这个页面
            free_page(page);
        }
        *ptep = 0;                  //(5)清除第二页表项
        tlb_invalidate(pgdir, la);  //(6)刷新tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    assert(USER_ACCESS(start, end));

    do {
        pte_t *ptep = get_pte(pgdir, start, 0);
        if (ptep == NULL) {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
            continue;
        }
        if (*ptep != 0) {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
    } while (start != 0 && start < end);
}

void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    assert(USER_ACCESS(start, end));

    uintptr_t d1start, d0start;
    int free_pt, free_pd0;
    pde_t *pd0, *pt, pde1, pde0;
    d1start = ROUNDDOWN(start, PDSIZE);
    d0start = ROUNDDOWN(start, PTSIZE);
    do {
        // 一级页目录项
        pde1 = pgdir[PDX1(d1start)];
        // 如果存在有效项，则进入0级
        // 并尝试释放0级页目录中所有有效项指向的所有页表，
        // 然后尝试释放这个0级页目录并更新一级项
        if (pde1&PTE_V){
            pd0 = page2kva(pde2page(pde1));
            // 尝试释放所有页表
            free_pd0 = 1;
            do {
                pde0 = pd0[PDX0(d0start)];
                if (pde0&PTE_V) {
                    pt = page2kva(pde2page(pde0));
                    free_pt = 1;
                    for (int i = 0;i <NPTEENTRY;i++)
                        if (pt[i]&PTE_V){
                            free_pt = 0;
                            break;
                        }
                    // 只有在所有项都已无效时才释放
                    if (free_pt) {
                        free_page(pde2page(pde0));
                        pd0[PDX0(d0start)] = 0;
                    }
                } else
                    free_pd0 = 0;
                d0start += PTSIZE;
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
            // 只有在所有pde0都已无效时才释放0级页目录
            if (free_pd0) {
                free_page(pde2page(pde1));
                pgdir[PDX1(d1start)] = 0;
            }
        }
        d1start += PDSIZE;
        d0start = d1start;
    } while (d1start != 0 && d1start < end);
}

/* copy_range - 将一个进程A的内存内容（start, end）复制到另一个进程B
 * @to:    进程B的页目录地址
 * @from:  进程A的页目录地址
 * @share: 标志位，指示复制或共享。我们只使用复制方法，所以它没有被使用。
 *
 * 调用图：copy_mm-->dup_mmap-->copy_range
 */
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end,
               bool share) {
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    assert(USER_ACCESS(start, end));
    // 按页面单位复制内容。
    do {
        // 调用get_pte找到进程A的pte
        pte_t *ptep = get_pte(from, start, 0), *nptep;
        if (ptep == NULL) {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
            continue;
        }
        // 调用get_pte找到进程B的pte。如果pte为NULL，则分配一个PT
        if (*ptep & PTE_V) {
            if ((nptep = get_pte(to, start, 1)) == NULL) {
                return -E_NO_MEM;
            }
            uint32_t perm = (*ptep & PTE_USER);
            // 从ptep获取页面
            struct Page *page = pte2page(*ptep);
            // 为进程B分配页面
            struct Page *npage = alloc_page();
            assert(page != NULL);
            assert(npage != NULL);
            int ret = 0;
            /* LAB5:EXERCISE2 YOUR CODE
             * 复制页面内容到npage，建立nage的物理地址与线性地址start的映射
             *
             * 一些有用的宏定义和定义，你可以在下面的实现中使用它们。
             * 宏定义或函数：
             *    page2kva(struct Page *page): 返回页面管理的内存的内核虚拟地址（参见pmm.h）
             *    page_insert: 建立一个Page的物理地址与线性地址la的映射
             *    memcpy: 典型的内存复制函数
             *
             * (1) 找到src_kvaddr: 页面的内核虚拟地址
             * (2) 找到dst_kvaddr: npage的内核虚拟地址
             * (3) 从src_kvaddr到dst_kvaddr复制内存，大小为PGSIZE
             * (4) 建立nage的物理地址与线性地址start的映射
             */
            assert(ret == 0);
        }
        start += PGSIZE;
    } while (start != 0 && start < end);
    return 0;
}


// page_remove - 释放与线性地址la相关的页面，并验证pte
void page_remove(pde_t *pgdir, uintptr_t la) {
    pte_t *ptep = get_pte(pgdir, la, 0); // 获取页面表项
    if (ptep != NULL) { // 如果页面表项存在
        page_remove_pte(pgdir, la, ptep); // 移除页面表项
    }
}

// page_insert - 建立物理地址的页面与线性地址la的映射
// 参数：
//  pgdir: PDT的内核虚拟基地址
//  page: 需要映射的页面
//  la: 需要映射的线性地址
//  perm: 设置在相关pte中的页面权限
// 返回值：总是0
// 注意：PT已更改，因此需要使TLB失效
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
    pte_t *ptep = get_pte(pgdir, la, 1); // 获取页面表项
    if (ptep == NULL) { // 如果页面表项不存在
        return -E_NO_MEM; // 返回内存不足错误
    }
    page_ref_inc(page); // 页面引用计数增加
    if (*ptep & PTE_V) { // 如果页面表项已验证
        struct Page *p = pte2page(*ptep); // 获取当前页面
        if (p == page) { // 如果当前页面与要插入的页面相同
            page_ref_dec(page); // 页面引用计数减少
        } else { // 如果不同
            page_remove_pte(pgdir, la, ptep); // 移除页面表项
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm); // 创建新的页面表项
    tlb_invalidate(pgdir, la); // 使TLB失效
    return 0;
}

// tlb_invalidate - 使TLB项失效，但只有在编辑的页表是处理器当前使用的页表时
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    asm volatile("sfence.vma %0" : : "r"(la)); // 执行sfence.vma指令
}

// pgdir_alloc_page - 调用alloc_page和page_insert函数
// 分配一页大小的内存，并设置线性地址la与PDT pgdir之间的地址映射
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
    struct Page *page = alloc_page(); // 分配页面
    if (page != NULL) { // 如果页面分配成功
        if (page_insert(pgdir, page, la, perm) != 0) { // 如果页面插入失败
            free_page(page); // 释放页面
            return NULL;
        }
        if (swap_init_ok) { // 如果交换空间初始化成功
            if (check_mm_struct != NULL) { // 如果检查的mm结构不为空
                swap_map_swappable(check_mm_struct, la, page, 0); // 映射可交换页面
                page->pra_vaddr = la; // 设置页面的虚拟地址
                assert(page_ref(page) == 1); // 断言页面引用计数为1
                // cprintf("get No. %d  page: pra_vaddr %x, pra_link.prev %x,
                // pra_link_next %x in pgdir_alloc_page\n", (page-pages),
                // page->pra_vaddr,page->pra_page_link.prev,
                // page->pra_page_link.next);
            } else {  // 现在当前进程已存在，将来应该修复
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
    pmm_manager->check(); // 检查物理内存管理器
    cprintf("check_alloc_page() succeeded!\n"); // 打印成功信息
}

static void check_pgdir(void) {
    // assert(npage <= KMEMSIZE / PGSIZE);
    // 内存从RISC-V的2GB开始
    // 因此npage总是大于KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages(); // 获取当前空闲页面数

    assert(npage <= KERNTOP / PGSIZE); // 断言页面数不超过内核空间大小
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0); // 断言启动页目录不为空且偏移为0
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL); // 断言获取页面为空

    struct Page *p1, *p2;
    p1 = alloc_page(); // 分配页面
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0); // 断言页面插入成功

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL); // 断言获取页面表项成功
    assert(pte2page(*ptep) == p1); // 断言页面表项指向正确的页面
    assert(page_ref(p1) == 1); // 断言页面引用计数为1

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0])); // 获取PDE的物理地址
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1; // 获取PTE的物理地址
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep); // 断言获取页面表项成功

    p2 = alloc_page(); // 分配页面
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0); // 断言页面插入成功
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL); // 断言获取页面表项成功
    assert(*ptep & PTE_U); // 断言页面表项具有用户权限
    assert(*ptep & PTE_W); // 断言页面表项具有写权限
    assert(boot_pgdir[0] & PTE_U); // 断言PDE具有用户权限
    assert(page_ref(p2) == 1); // 断言页面引用计数为1

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0); // 断言页面插入成功
    assert(page_ref(p1) == 2); // 断言页面引用计数为2
    assert(page_ref(p2) == 0); // 断言页面引用计数为0
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL); // 断言获取页面表项成功
    assert(pte2page(*ptep) == p1); // 断言页面表项指向正确的页面
    assert((*ptep & PTE_U) == 0); // 断言页面表项不具有用户权限

    page_remove(boot_pgdir, 0x0); // 移除页面
    assert(page_ref(p1) == 1); // 断言页面引用计数为1
    assert(page_ref(p2) == 0); // 断言页面引用计数为0

    page_remove(boot_pgdir, PGSIZE); // 移除页面
    assert(page_ref(p1) == 0); // 断言页面引用计数为0
    assert(page_ref(p2) == 0); // 断言页面引用计数为0

    assert(page_ref(pde2page(boot_pgdir[0])) == 1); // 断言PDE页面引用计数为1

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0])); // 获取PDE和PDE页面的虚拟地址
    free_page(pde2page(pd0[0])); // 释放页面
    free_page(pde2page(pd1[0])); // 释放页面
    boot_pgdir[0] = 0; // 清空启动页目录
    flush_tlb(); // 刷新TLB

    assert(nr_free_store==nr_free_pages()); // 断言空闲页面数不变

    cprintf("check_pgdir() succeeded!\n"); // 打印成功信息
}

static void check_boot_pgdir(void) {
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages(); // 获取当前空闲页面数

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) { // 遍历内核空间
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL); // 断言获取页面表项成功
        assert(PTE_ADDR(*ptep) == i); // 断言页面表项地址正确
    }

    assert(boot_pgdir[0] == 0); // 断言启动页目录项为0

    struct Page *p;
    p = alloc_page(); // 分配页面
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0); // 断言页面插入成功
    assert(page_ref(p) == 1); // 断言页面引用计数为1
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0); // 断言页面插入成功
    assert(page_ref(p) == 2); // 断言页面引用计数为2

    const char *str = "ucore: Hello world!!"; // 定义字符串
    strcpy((void *)0x100, str); // 复制字符串到虚拟地址0x100
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0); // 断言两个地址的字符串相同

    *(char *)(page2kva(p) + 0x100) = '\0'; // 设置字符串结束符
    assert(strlen((const char *)0x100) == 0); // 断言字符串长度为0

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0])); // 获取PDE和PDE页面的虚拟地址
    free_page(p); // 释放页面
    free_page(pde2page(pd0[0])); // 释放页面
    free_page(pde2page(pd1[0])); // 释放页面
    boot_pgdir[0] = 0; // 清空启动页目录
    flush_tlb(); // 刷新TLB

    assert(nr_free_store==nr_free_pages()); // 断言空闲页面数不变

    cprintf("check_boot_pgdir() succeeded!\n"); // 打印成功信息
}

// perm2str - 使用字符串'u,r,w,-'表示权限
static const char *perm2str(int perm) {
    static char str[4];
    str[0] = (perm & PTE_U) ? 'u' : '-'; // 用户权限
    str[1] = 'r'; // 读权限
    str[2] = (perm & PTE_W) ? 'w' : '-'; // 写权限
    str[3] = '\0'; // 字符串结束符
    return str;
}

// get_pgtable_items - 在PDT或PT的[left, right]范围内，找到连续的线性地址空间
//                  - (left_store*X_SIZE~right_store*X_SIZE)用于PDT或PT
//                  - X_SIZE=PTSIZE=4M，如果是PDT；X_SIZE=PGSIZE=4K，如果是PT
// 参数：
//  left:        未使用
//  right:       表的范围的高侧
//  start:       表的范围的低侧
//  table:       表的起始地址
//  left_store:  表的下一个范围的高侧指针
//  right_store: 表的下一个范围的低侧指针
// 返回值：0 - 没有无效的项目范围，perm - 一个有效的项目范围，具有perm权限
static int get_pgtable_items(size_t left, size_t right, size_t start,
                             uintptr_t *table, size_t *left_store,
                             size_t *right_store) {
    if (start >= right) { // 如果开始地址超出范围
        return 0;
    }
    while (start < right && !(table[start] & PTE_V)) { // 遍历表项直到找到验证的项
        start++;
    }
    if (start < right) { // 如果找到验证的项
        if (left_store != NULL) { // 如果需要存储下一个范围的高侧
            *left_store = start;
        }
        int perm = (table[start++] & PTE_USER); // 获取权限
        while (start < right && (table[start] & PTE_USER) == perm) { // 找到连续的项
            start++;
        }
        if (right_store != NULL) { // 如果需要存储下一个范围的低侧
            *right_store = start;
        }
        return perm; // 返回权限
    }
    return 0; // 没有找到验证的项
}

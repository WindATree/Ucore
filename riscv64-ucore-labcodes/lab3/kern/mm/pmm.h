#ifndef __KERN_MM_PMM_H__
#define __KERN_MM_PMM_H__

#include <assert.h>
#include <atomic.h>
#include <defs.h>
#include <memlayout.h>
#include <mmu.h>

// pmm_manager is a physical memory management class. A special pmm manager -
// XXX_pmm_manager
// only needs to implement the methods in pmm_manager class, then
// XXX_pmm_manager can be used
// by ucore to manage the total physical memory space.
struct pmm_manager {
    const char *name;  // XXX_pmm_manager's name
    void (*init)(
        void);  // initialize internal description&management data structure
                // (free block list, number of free block) of XXX_pmm_manager
    void (*init_memmap)(
        struct Page *base,
        size_t n);  // setup description&management data structcure according to
                    // the initial free physical memory space
    struct Page *(*alloc_pages)(
        size_t n);  // allocate >=n pages, depend on the allocation algorithm
    void (*free_pages)(struct Page *base, size_t n);  // free >=n pages with
                                                      // "base" addr of Page
                                                      // descriptor
                                                      // structures(memlayout.h)
    size_t (*nr_free_pages)(void);  // return the number of free pages
    void (*check)(void);            // check the correctness of XXX_pmm_manager
};

extern const struct pmm_manager *pmm_manager;
extern pde_t *boot_pgdir;
extern const size_t nbase;
extern uintptr_t boot_cr3;

void pmm_init(void);

struct Page *alloc_pages(size_t n);
void free_pages(struct Page *base, size_t n);
size_t nr_free_pages(void);

#define alloc_page() alloc_pages(1)
#define free_page(page) free_pages(page, 1)

pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create);
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store);
void page_remove(pde_t *pgdir, uintptr_t la);
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm);

void tlb_invalidate(pde_t *pgdir, uintptr_t la);
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm);


/* *
 * PADDR - 将内核虚拟地址转换为对应的物理地址
 * @kva: 内核虚拟地址，假设指向高于 KERNBASE 的地址空间，
 *       即机器的物理内存（最多 256MB）被映射到的范围。
 * 如果传入的地址不是内核虚拟地址（即低于 KERNBASE），则会触发 panic。
 */
#define PADDR(kva)                                                 \
    ({                                                             \
        uintptr_t __m_kva = (uintptr_t)(kva);                      /* 将 kva 转换为 uintptr_t 类型以便处理 */ \
        if (__m_kva < KERNBASE) {                                  /* 如果 kva 小于 KERNBASE，则表示它不在内核虚拟地址空间中 */ \
            panic("PADDR called with invalid kva %08lx", __m_kva); /* 调用 panic 终止程序并输出错误信息 */ \
        }                                                          \
        __m_kva - va_pa_offset;                                    /* 内核虚拟地址减去偏移量 va_pa_offset 得到对应的物理地址 */ \
    })



//用户空间：用于运行用户程序，程序的虚拟地址主要在用户空间，通常从低地址开始。
//内核空间：操作系统内核所在的空间，通常分配在虚拟地址的高地址范围。
//内核虚拟地址：内核用来映射物理内存的虚拟地址范围，即将物理内存映射到某个内核虚拟地址区域（例如从 KERNBASE 开始）。
//这让内核能直接操作物理内存，但这部分地址不会对用户空间程序开放。
/* *
 * KADDR - 将物理地址转换为对应的内核虚拟地址
 * @pa: 物理地址，将被映射到内核虚拟地址空间。
 * 如果传入的物理地址不合法（即超出实际物理内存的范围），则会触发 panic。
 */
#define KADDR(pa)                                                \
    ({                                                           \
        uintptr_t __m_pa = (pa);                                 /* 将 pa 转换为 uintptr_t 类型以便处理 */ \
        size_t __m_ppn = PPN(__m_pa);                            /* 提取物理页帧号（PPN），用于验证物理地址的有效性 */ \
        if (__m_ppn >= npage) {                                  /* 如果页帧号超出系统页数，则表示 pa 不在有效物理内存范围内 */ \
            panic("KADDR called with invalid pa %08lx", __m_pa); /* 调用 panic 终止程序并输出错误信息 */ \
        }                                                        \
        (void *)(__m_pa + va_pa_offset);                         /* 将物理地址加上 va_pa_offset 得到对应的内核虚拟地址 */ \
    })


extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint_t va_pa_offset;

// 从 Page 结构体的指针计算页帧号（Page Frame Number, PPN）
static inline ppn_t page2ppn(struct Page *page) { 
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
}

// 根据 Page 结构体指针返回物理地址
static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
}

// 将物理地址转换为 Page 结构体指针
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
        panic("pa2page called with invalid pa"); // 如果无效，触发 panic
    }
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
}

// 将 Page 结构体指针转换为内核虚拟地址
static inline void *page2kva(struct Page *page) { 
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
}

// 将内核虚拟地址转换为 Page 结构体指针
static inline struct Page *kva2page(void *kva) { 
    return pa2page(PADDR(kva)); // 先获取物理地址，再调用 pa2page 返回对应的 Page 结构体
}

// 根据页表项 (PTE) 获取对应的 Page 结构体指针
static inline struct Page *pte2page(pte_t pte) {
    if (!(pte & PTE_V)) { // 检查 PTE 是否有效
        panic("pte2page called with invalid pte"); // 无效时触发 panic
    }
    return pa2page(PTE_ADDR(pte)); // 提取页表项的物理地址并转换为 Page 结构体指针
}

// 根据页目录项 (PDE) 获取对应的 Page 结构体指针
static inline struct Page *pde2page(pde_t pde) {
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
}

// 获取 Page 的引用计数
static inline int page_ref(struct Page *page) { 
    return page->ref; 
}

// 设置 Page 的引用计数
static inline void set_page_ref(struct Page *page, int val) { 
    page->ref = val; 
}

// 增加 Page 的引用计数
static inline int page_ref_inc(struct Page *page) {
    page->ref += 1; // 引用计数加 1
    return page->ref;
}

// 减少 Page 的引用计数
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1; // 引用计数减 1
    return page->ref;
}

// 刷新 TLB（Translation Lookaside Buffer），使用 RISC-V 的 sfence.vma 指令
static inline void flush_tlb() { 
    asm volatile("sfence.vma"); // 刷新 TLB 中的地址映射
}

// 从页帧号和权限位构造页表项 (PTE)
static inline pte_t pte_create(uintptr_t ppn, int type) {
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type; // 将页帧号和权限位组合成 PTE
}

// 从页帧号创建页目录项 (PDE)，设置有效位
static inline pte_t ptd_create(uintptr_t ppn) { 
    return pte_create(ppn, PTE_V); // 只包含有效位的页目录项
}

// 内核栈底部和顶部的标识符
extern char bootstack[], bootstacktop[];

// 内核分配和释放内存的函数
extern void *kmalloc(size_t n); // 内核内存分配函数
extern void kfree(void *ptr, size_t n); // 内核内存释放函数




#endif /* !__KERN_MM_PMM_H__ */

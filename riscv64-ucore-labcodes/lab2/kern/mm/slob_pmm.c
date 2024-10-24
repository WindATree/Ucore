#include "slob_pmm.h"
#include <pmm.h>
#include "buddy_system.h"
#include <stdio.h>

slob_manager_t slob_manager;
//13 8=16
uint32_t ALIGNUP(uint32_t x, uint32_t a) {
    return (x + (a - 1)) & ~(a - 1);
}
void buddy_init(void){
    buddy_pmm_manager.init();
}

void buddy_init_memmap(struct Page *base, size_t n){
    buddy_pmm_manager.init_memmap(base, n);
}

struct Page *buddy_alloc_pages(size_t n){
    return buddy_pmm_manager.alloc_pages(n);
}

void buddy_free_pages(struct Page *base, size_t n){
    buddy_pmm_manager.free_pages(base, n);
}

size_t buddy_nr_free_pages(void){
    return buddy_pmm_manager.nr_free_pages();
}

static void slob_debug(void) {
    struct Page *page = NULL;
    list_entry_t *le = NULL;
    cprintf(">>>[slob_debug] go through the page list...\n");
    list_entry_t *head = &slob_manager.free_slob_small.free_list;
    for (le = list_next(head); le != head; le = list_next(le)) {
        page = le2page(le, page_link);  
        cprintf("Page at address: %p\n", page);     
    }
    cprintf(">>>[slob_debug] end of page list.\n");
}

static void slob_init(void) {
    cprintf("[debug] Initializing SLOB...\n");
    buddy_init();
    cprintf("[debug] Buddy system initialized.\n");
    // init slob manager
    // init all three free_area_t as empty
    list_init(&slob_manager.free_slob_small.free_list);
    slob_manager.free_slob_small.nr_free = 0;
    list_init(&slob_manager.free_slob_medium.free_list);
    slob_manager.free_slob_medium.nr_free = 0;
    list_init(&slob_manager.free_slob_large.free_list);
    slob_manager.free_slob_large.nr_free = 0;
    cprintf("[debug] SLOB manager initialized.\n");
}

static void slob_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);

    // init buddy system
    buddy_init_memmap(base, n);

    struct Page *p = base;
    for (; p != base + n; p++) {
        p->virtual_addr = (void *)(page2pa(p) + va_pa_offset);
        p->slob_units_left = 2048;
    }
}

static struct Page *slob_alloc_pages(size_t n) {
    return buddy_alloc_pages(n);
}

static void slob_free_pages(struct Page *base, size_t n) {
    buddy_free_pages(base, n);
}

static size_t slob_nr_free_pages(void) {
    return buddy_nr_free_pages();
}

static void *slob_alloc_bytes_from_page(struct Page *page, size_t n) {
    // 计算需要多少个 SLOB 单元来满足 n 字节的分配请求
    uint32_t slob_units = (n + SLOB_UNIT - 1) / SLOB_UNIT;  // 对齐并计算所需 SLOB 单元数

    slob_t *prev = NULL;  // 前一个 SLOB 单元指针，初始为 NULL
    slob_t *cur = (slob_t *)page->virtual_addr;  // 当前 SLOB 单元指针，从页面的虚拟地址开始

    cprintf("[slob_debug] Attempting to allocate %u bytes, requiring %u slob units.\n", n, slob_units);

    // 遍历页面中的 SLOB 单元链表
    for (; ; prev = cur, cur = (slob_t *)((uintptr_t)cur + cur->slob_next_offset)) {
        // 调试信息，打印当前遍历到的 SLOB 单元信息
        cprintf("[slob_debug] Checking slob unit at address %p, slob_units_left: %u, slob_next_offset: %u\n",
                cur, cur->slob_units_left, cur->slob_next_offset);

        // 如果当前 SLOB 单元剩余的单元数足够大，满足分配请求
        if (cur->slob_units_left >= slob_units) {
            // 如果当前单元恰好等于所需单元数
            if (cur->slob_units_left == slob_units) {
                if (prev) {
                    // 如果存在前一个单元，将前一个单元的 next_offset 指向下一个单元
                    prev->slob_next_offset += cur->slob_next_offset;
                } else {
                    // 否则，将页面的虚拟地址更新为当前单元的下一个单元
                    page->virtual_addr = (slob_t *)((uintptr_t)cur + cur->slob_next_offset);
                }
                cprintf("[slob_debug] Perfect fit found at %p, fully allocated.\n", cur);
            } else {
                // 当前单元剩余的空间大于所需的 SLOB 单元数，需要拆分
                if (prev) {
                    // 更新前一个单元的 next_offset，跳过已分配的单元
                    prev->slob_next_offset += slob_units * SLOB_UNIT;
                } else {
                    // 更新页面的虚拟地址，使其指向分配后的剩余单元
                    page->virtual_addr = (slob_t *)((uintptr_t)cur + slob_units * SLOB_UNIT);
                }
                
                // 创建一个新的 SLOB 单元，代表剩余的空间
                slob_t *next = (slob_t *)((uintptr_t)cur + slob_units * SLOB_UNIT);
                next->slob_units_left = cur->slob_units_left - slob_units;  // 更新剩余的单元数
                next->slob_next_offset = cur->slob_next_offset - slob_units * SLOB_UNIT;  // 更新下一个偏移量

                cprintf("[slob_debug] Splitting slob unit at %p. New slob unit at %p with %u slob units left.\n",
                        cur, next, next->slob_units_left);
            }

            // 更新当前单元的 SLOB 单元数为 0，表示它已完全分配
            cur->slob_units_left = 0;
            page->slob_units_left -= slob_units;  // 更新页面的剩余 SLOB 单元数

            // 如果页面中没有剩余的 SLOB 单元，移出空闲列表
            if (page->slob_units_left == 0) {
                list_del(&page->slob_link);
                cprintf("[slob_debug] Page at %p is full, removing from free list.\n", page);
            }

            // 返回分配的 SLOB 单元的地址
            return (void *)cur;
        }

        // 如果下一个 SLOB 单元超出了页面边界，分配失败
        if (cur->slob_next_offset + (uintptr_t)cur >= page2pa(page) + PGSIZE) {
            cprintf("[slob_debug] End of page reached at %p, allocation failed.\n", cur);
            return NULL;
        }
    }

    cprintf("[slob_debug]: reached end of slob_alloc_bytes_from_page without successful allocation.\n");
    return NULL;
}

static void *slob_alloc_bytes(size_t n) {
    // 输出调试信息，显示请求分配的字节数
    cprintf("[slob_debug] Allocating 0x%lx bytes using SLOB...\n", n);

    // 确保请求的字节数大于0
    assert(n > 0);

    // 如果请求的内存大小（包括 SLOB 管理元数据）超过一页的大小，直接使用伙伴系统分配
    if (n + sizeof(slob_t) > PGSIZE) {
        // 使用伙伴系统分配大于一页的内存块
        struct Page *p = buddy_alloc_pages(n / PGSIZE + 1);
        // 输出调试信息，显示分配的页面地址
        cprintf("[slob -> buddy] Bytes allocated on buddy at address %p.\n", (void *)p->virtual_addr);
        return p->virtual_addr;
    } else {
        // 如果请求的内存大小较小，使用 SLOB 分配器
        // 确定要分配的内存区域（小、中、大块）
        free_area_t *slob_free_area = NULL;
        if (n <= SLOB_SMALL) {
            cprintf("[slob_debug] Allocating small size.\n");
            slob_free_area = &slob_manager.free_slob_small;
        } else if (n <= SLOB_MEDIUM) {
            cprintf("[slob_debug] Allocating medium size.\n");
            slob_free_area = &slob_manager.free_slob_medium;
        } else {
            cprintf("[slob_debug] Allocating large size.\n");
            slob_free_area = &slob_manager.free_slob_large;
        }
        
        // 计算需要多少个 SLOB 单元来分配指定大小的内存
        uint32_t slob_units = (n + SLOB_UNIT-1) / SLOB_UNIT ; // 包括对齐和管理元数据的额外空间
        slob_t *allocated_slob = NULL;
        
        // 遍历 free_area_t 链表，寻找可以容纳该大小的页面
        list_entry_t *le = &slob_free_area->free_list;
        while ((le = list_next(le)) != &slob_free_area->free_list) {
            struct Page *page = le2page(le, slob_link);
            // 如果页面的剩余 SLOB 单元不足，跳过该页面
            if (page->slob_units_left < slob_units) {
                continue;
            }
            
            // 尝试从页面中分配指定大小的内存
            list_entry_t *prev = list_prev(le);
            allocated_slob = slob_alloc_bytes_from_page(page, n);
            page->slob_units_left -= slob_units; // 更新页面的剩余单元数
            if (page->slob_units_left == 0) {
                // 如果页面满了，从空闲列表中移除
                list_del(&page->slob_link);
                slob_free_area->nr_free--;
                cprintf("[slob_debug] Page is full, removing from free list...\n");
            }

            if (allocated_slob) {
                break; // 分配成功，跳出循环
            }  
        }

        if (allocated_slob == NULL) {
            // 如果没有合适的页面可以分配，则从伙伴系统分配新页面
            cprintf("[slob_debug] No page can hold the size, allocating a new page...\n");
            struct Page *p = buddy_alloc_pages(1); // 从伙伴系统分配一个页面
            if (p == NULL) {
                return NULL; // 如果内存不足，返回 NULL
            }

            cprintf("[slob_debug] New page allocated at address %p.\n", (void *)p->virtual_addr);

            // 初始化新分配页面的元数据
            p->slob_units_left = 2048; // 假设每个页面包含 2048 个 SLOB 单元
            p->virtual_addr = (void *)(page2pa(p) + va_pa_offset);

            // 将新页面添加到 SLOB 分配器的空闲链表中
            list_add_after(&slob_free_area->free_list, &(p->slob_link));
            slob_free_area->nr_free++;

            // 初始化页面中的第一个 SLOB 单元
            slob_t *slob = (slob_t *)p->virtual_addr;
            slob->slob_units_left = 2048;
            slob->slob_next_offset = 4096;

            // 再次尝试从新页面中分配
            allocated_slob = slob_alloc_bytes_from_page(p, n);
            if (allocated_slob == NULL) {
                cprintf("[slob_debug] Failed to allocate from new page.\n");
                return NULL; // 如果分配失败，返回 NULL
            }

            // 更新页面的剩余单元数
            p->slob_units_left -= slob_units;
            if (p->slob_units_left == 0) {
                // 如果页面满了，移出空闲列表
                cprintf("[slob_debug] Page is full, removing from free list...\n");
                list_del(&p->slob_link);
                slob_free_area->nr_free--;
            }

            // 输出调试信息，分配成功
            cprintf("[slob_debug] Bytes allocated at address %p on new page.\n", (void *)allocated_slob);
            return (void *)allocated_slob;
        } else {
            // 如果在已有页面中成功分配，输出调试信息
            cprintf("[slob_debug] Bytes allocated at address %p on exist page.\n", (void *)allocated_slob);
            return (void *)allocated_slob;
        }
        
        // 输出调试信息，分配结束
        cprintf("[slob_debug]: allocated_slob = %p reached end of slob_alloc_bytes\n", allocated_slob);
        return NULL;
    }
}

static void slob_free_bytes(void *ptr, size_t n) {
    // 输出调试信息，显示正在释放的字节数和地址
    cprintf("[slob_debug] Freeing 0x%lx bytes from address %p... using SLOB\n", n, ptr);

    // 确保指针和大小有效
    assert(ptr);
    assert(n > 0);

    // 如果请求释放的内存大小（包括 SLOB 元数据）大于一个页面，使用伙伴系统释放
    if (n + sizeof(slob_t) > PGSIZE) {
        cprintf("[slob -> buddy] Freeing bytes on buddy...\n");
        // 使用伙伴系统释放内存
        struct Page *p = pa2page((uintptr_t)ptr - va_pa_offset);
        buddy_free_pages(p, (n / PGSIZE) + ((n % PGSIZE) ? 1 : 0));
        return;
    }

    // 根据大小确定要从哪个 free_area_t 中释放
    free_area_t *slob_free_area = NULL;
    if (n <= SLOB_SMALL) {
        cprintf("[slob_debug] Freeing small size.\n");
        slob_free_area = &slob_manager.free_slob_small;
    } else if (n <= SLOB_MEDIUM) {
        cprintf("[slob_debug] Freeing medium size.\n");
        slob_free_area = &slob_manager.free_slob_medium;
    } else {
        cprintf("[slob_debug] Freeing large size.\n");
        slob_free_area = &slob_manager.free_slob_large;
    }

    // 找到对应的 SLOB 单元和页面
    slob_t *slob = (slob_t *)ptr;
    struct Page *page = pa2page((uintptr_t)slob - va_pa_offset);
    uint32_t slob_units = (n + SLOB_UNIT) / SLOB_UNIT - 1 + 2; // 计算需要释放的 SLOB 单元数

    // 如果释放的内存单元使页面完全空闲，则释放整个页面
    if (page->slob_units_left + slob_units == 2048) {
        cprintf("[slob_debug] The page is completely free, freeing the page instead...\n");
        list_del(&page->slob_link);  // 从空闲列表中删除页面
        slob_manager.free_slob_small.nr_free--;  // 更新空闲计数
        buddy_free_pages(page, 1);  // 释放页面
        return;
    }

    // 初始化 SLOB 单元指针
    slob_t *cur = (slob_t *)page->virtual_addr;
    slob_t *prev = NULL, *next = NULL;

    // 如果页面在之前是满的，现在需要将它重新加入到空闲列表中
    if (page->slob_units_left == 0) {
        cprintf("[slob_debug] The page was full before, adding it to the free list...\n");
        list_add_after(&slob_free_area->free_list, &page->slob_link);  // 加入空闲链表
        slob_free_area->nr_free++;  // 更新空闲页面计数
        page->slob_units_left = slob_units;  // 更新页面的剩余 SLOB 单元数
        page->virtual_addr = (void *)slob;  // 更新页面的虚拟地址
        slob->slob_units_left = slob_units;  // 更新 SLOB 单元的剩余数
        slob->slob_next_offset = 2048 - slob_units;  // 设置下一个 SLOB 单元的偏移
        return;
    }

    // 页面之前部分空闲，继续释放 SLOB 单元
    cprintf("[slob_debug] The page partially free before, freeing the slob...\n");
    page->slob_units_left += slob_units;  // 更新页面的剩余 SLOB 单元数

    // 如果释放的 SLOB 单元位于页面开头，处理它
    if ((void *)slob < page->virtual_addr) {
        // 如果可以与后面的 SLOB 单元合并
        if ((void *)slob + slob_units * SLOB_UNIT == page->virtual_addr) {
            cprintf("[slob_debug] Merging with next slob...\n");
            slob->slob_units_left += ((slob_t *)page->virtual_addr)->slob_units_left;  // 合并
            slob->slob_next_offset = ((slob_t *)page->virtual_addr)->slob_next_offset;  // 更新偏移
            page->virtual_addr = (void *)slob;  // 更新虚拟地址指向
        } else {
            // 无法合并，将其插入到第一个 SLOB 单元之前
            cprintf("[slob_debug] Inserting before the first slob...\n");
            slob->slob_units_left = slob_units;
            slob->slob_next_offset = (uintptr_t)page->virtual_addr - (uintptr_t)slob;  // 更新偏移
            page->virtual_addr = (void *)slob;  // 更新虚拟地址指向
        }
    } else {
        // 在 SLOB 单元链表中找到适合的位置
        slob_t *prev = page->virtual_addr;
        next = (slob_t *)((uintptr_t)prev + prev->slob_next_offset);
        
        // 找到要释放的 SLOB 单元的前后单元
        while (next < slob) {
            prev = next;
            next = (slob_t *)((uintptr_t)next + next->slob_next_offset);
            if (next->slob_next_offset == 0) return;  // 如果到达链表末尾
        }

        // 如果可以与前一个 SLOB 单元合并
        if ((void *)prev + prev->slob_units_left * SLOB_UNIT == (void *)slob) {
            cprintf("[slob_debug] Merging with the previous slob...\n");
            prev->slob_units_left += slob_units;  // 合并
        } 
        // 如果可以与后一个 SLOB 单元合并
        else if ((void *)slob + slob_units * SLOB_UNIT == (void *)next) {
            cprintf("[slob_debug] Merging with the next slob...\n");
            slob->slob_units_left = next->slob_units_left + slob_units;  // 合并
            slob->slob_next_offset = next->slob_next_offset + (uintptr_t)next - (uintptr_t)slob;  // 更新偏移
            prev->slob_next_offset = (uintptr_t)slob - (uintptr_t)prev;  // 更新前一个单元的偏移
        } else {
            // 无法合并，将其插入到前一个 SLOB 单元之后
            cprintf("[slob_debug] Inserting after the previous slob...\n");
            slob->slob_units_left = slob_units;
            slob->slob_next_offset = (uintptr_t)next - (uintptr_t)slob;  // 更新偏移
            prev->slob_next_offset = (uintptr_t)slob - (uintptr_t)prev;  // 更新前一个单元的偏移
        }
    }

    cprintf("[slob_debug] Slob freed.\n");
    return;
}

static void slob_check(void) {
    cprintf("[slob_check]: >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");

    // 定义不同大小的内存块大小数组
    size_t sizes[] = {16, 32, 64, 128, 256, 512, 1024, 2048, 4096};
    void *ptrs[sizeof(sizes)/sizeof(size_t)];  // 用于存储分配的指针

    cprintf(">>>[slob_check]: Test case 1: Basic allocation.<<<\n");
    // 测试用例 1：基本的内存分配
    for (int i = 0; i < sizeof(sizes)/sizeof(size_t); i++) {
        // 调用 slob_alloc_bytes 分配指定大小的内存
        ptrs[i] = slob_alloc_bytes(sizes[i]);
        assert(ptrs[i]);  // 检查分配是否成功
        cprintf("[slob_test] Successfully allocated %lx bytes at address %p.\n", sizes[i], ptrs[i]);
    }

    cprintf(">>>[slob_check]: Test case 2: Basic deallocation.<<<\n");
    // 测试用例 2：基本的内存释放
    for (int i = 0; i < sizeof(sizes)/sizeof(size_t); i++) {
        // 释放之前分配的内存
        slob_free_bytes(ptrs[i], sizes[i]);
        cprintf("[slob_test] Successfully deallocated memory at address %p.\n", ptrs[i]);
    }

    cprintf(">>>[slob_check]: Test case 3: Allocate and partially deallocate memory blocks.<<<\n");
    // 测试用例 3：部分释放内存块
    for (int i = 0; i < sizeof(sizes)/sizeof(size_t); i++) {
        // 再次分配内存块
        ptrs[i] = slob_alloc_bytes(sizes[i]);
        assert(ptrs[i]);  // 检查分配是否成功
        cprintf("[slob_test] Successfully allocated %lx bytes at address %p.\n", sizes[i], ptrs[i]);
    }

    // 部分释放内存块，隔一个释放一个
    for (int i = 0; i < sizeof(sizes)/sizeof(size_t); i += 2) {
        slob_free_bytes(ptrs[i], sizes[i]);
        cprintf("[slob_test] Successfully deallocated memory at address %p.\n", ptrs[i]);
        ptrs[i] = NULL;  // 释放后将指针标记为 NULL
    }

    cprintf(">>>[slob_check]: Test case 4: Fragmentation test.<<<\n");
    // 测试用例 4：碎片化测试
    // 分配更小的内存块，检查它们是否有效占用之前释放的内存空间
    for (int i = 0; i < sizeof(sizes)/sizeof(size_t); i += 2) {
        ptrs[i] = slob_alloc_bytes(sizes[i] / 2);  // 分配一半大小的内存
        assert(ptrs[i]);
        cprintf("[slob_test] Successfully allocated %lx bytes at address %p.\n", sizes[i]/2, ptrs[i]);
    }

    cprintf(">>>[slob_check]: Test case 5: Complete deallocation.<<<\n");
    // 测试用例 5：完全释放所有内存
    for (int i = 0; i < sizeof(sizes)/sizeof(size_t); i++) {
        if (ptrs[i]) {
            // 释放之前分配的内存，如果是部分分配的，释放相应大小
            slob_free_bytes(ptrs[i], (i % 2 == 0) ? sizes[i]/2 : sizes[i]);
            cprintf("[slob_test] Successfully deallocated memory at address %p.\n", ptrs[i]);
        }
    }

    cprintf(">>>[slob_check]: Test case 6: Allocate memory blocks larger than a page.<<<\n");
    // 测试用例 6：分配大于页面大小的内存块
    for (int i = 0; i < sizeof(sizes)/sizeof(size_t); i++) {
        size_t large_size = sizes[i] + PGSIZE;  // 分配一个比页面大的块
        ptrs[i] = slob_alloc_bytes(large_size);
        assert(ptrs[i]);  // 检查分配是否成功
        cprintf("[slob_test] Successfully allocated %lx bytes at address %p.\n", large_size, ptrs[i]);
        slob_free_bytes(ptrs[i], large_size);  // 立即释放分配的内存
        cprintf("[slob_test] Successfully deallocated memory at address %p.\n", ptrs[i]);
    }

    cprintf("[slob_check]: <<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
}

const struct pmm_manager slob_pmm_manager = {
    .name = "slob_pmm_manager",
    .init = slob_init,
    .init_memmap = slob_init_memmap,
    .alloc_pages = slob_alloc_pages,
    .free_pages = slob_free_pages,
    .nr_free_pages = slob_nr_free_pages,
    .alloc_bytes = slob_alloc_bytes,
    .free_bytes = slob_free_bytes,
    .check = slob_check,
};
#include <pmm.h>
#include <list.h>
#include <string.h>
#include <default_pmm.h>

/* In the first fit algorithm, the allocator keeps a list of free blocks (known as the free list) and,
   on receiving a request for memory, scans along the list for the first block that is large enough to
   satisfy the request. If the chosen block is significantly larger than that requested, then it is 
   usually split, and the remainder added to the list as another free block.
   Please see Page 196~198, Section 8.2 of Yan Wei Min's chinese book "Data Structure -- C programming language"
*/
// you should rewrite functions: default_init,default_init_memmap,default_alloc_pages, default_free_pages.
/*
 * Details of FFMA
 * (1) Prepare: In order to implement the First-Fit Mem Alloc (FFMA), we should manage the free mem block use some list.
 *              The struct free_area_t is used for the management of free mem blocks. At first you should
 *              be familiar to the struct list in list.h. struct list is a simple doubly linked list implementation.
 *              You should know howto USE: list_init, list_add(list_add_after), list_add_before, list_del, list_next, list_prev
 *              Another tricky method is to transform a general list struct to a special struct (such as struct page):
 *              you can find some MACRO: le2page (in memlayout.h), (in future labs: le2vma (in vmm.h), le2proc (in proc.h),etc.)
 * (2) default_init: you can reuse the  demo default_init fun to init the free_list and set nr_free to 0.
 *              free_list is used to record the free mem blocks. nr_free is the total number for free mem blocks.
 * (3) default_init_memmap:  CALL GRAPH: kern_init --> pmm_init-->page_init-->init_memmap--> pmm_manager->init_memmap
 *              This fun is used to init a free block (with parameter: addr_base, page_number).
 *              First you should init each page (in memlayout.h) in this free block, include:
 *                  p->flags should be set bit PG_property (means this page is valid. In pmm_init fun (in pmm.c),
 *                  the bit PG_reserved is setted in p->flags)
 *                  if this page  is free and is not the first page of free block, p->property should be set to 0.
 *                  if this page  is free and is the first page of free block, p->property should be set to total num of block.
 *                  p->ref should be 0, because now p is free and no reference.
 *                  We can use p->page_link to link this page to free_list, (such as: list_add_before(&free_list, &(p->page_link)); )
 *              Finally, we should sum the number of free mem block: nr_free+=n
 * (4) default_alloc_pages: search find a first free block (block size >=n) in free list and reszie the free block, return the addr
 *              of malloced block.
 *              (4.1) So you should search freelist like this:
 *                       list_entry_t le = &free_list;
 *                       while((le=list_next(le)) != &free_list) {
 *                       ....
 *                 (4.1.1) In while loop, get the struct page and check the p->property (record the num of free block) >=n?
 *                       struct Page *p = le2page(le, page_link);
 *                       if(p->property >= n){ ...
 *                 (4.1.2) If we find this p, then it' means we find a free block(block size >=n), and the first n pages can be malloced.
 *                     Some flag bits of this page should be setted: PG_reserved =1, PG_property =0
 *                     unlink the pages from free_list
 *                     (4.1.2.1) If (p->property >n), we should re-caluclate number of the the rest of this free block,
 *                           (such as: le2page(le,page_link))->property = p->property - n;)
 *                 (4.1.3)  re-caluclate nr_free (number of the the rest of all free block)
 *                 (4.1.4)  return p
 *               (4.2) If we can not find a free block (block size >=n), then return NULL
 * (5) default_free_pages: relink the pages into  free list, maybe merge small free blocks into big free blocks.
 *               (5.1) according the base addr of withdrawed blocks, search free list, find the correct position
 *                     (from low to high addr), and insert the pages. (may use list_next, le2page, list_add_before)
 *               (5.2) reset the fields of pages, such as p->ref, p->flags (PageProperty)
 *               (5.3) try to merge low addr or high addr blocks. Notice: should change some pages's p->property correctly.
 */

// 首次适应算法（FFMA）概述：

// 算法维护一个空闲块列表（称为空闲列表），当收到内存请求时，它会扫描这个列表，寻找第一个足够大的空闲块来满足请求。
// 如果找到的块比请求的内存大很多，通常会将其分割，并将剩余的部分作为另一个空闲块添加到列表中。
// 参考书籍：

// 这段注释提到了参考书籍《数据结构——C语言》，作者是严蔚敏，具体内容在第196至198页，第8.2节。
// 需要重写的函数：

// default_init：初始化内存管理相关的数据结构。
// default_init_memmap：初始化内存映射。
// default_alloc_pages：分配页面。
// default_free_pages：释放页面。
// FFMA的详细说明：

// (1) 准备：为了实现FFMA，需要使用某种列表来管理空闲内存块。这里提到了struct free_area_t用于管理空闲内存块，并且需要熟悉list.h中的struct list，这是一个简单的双向链表实现。
// (2) default_init：使用这个函数来初始化空闲列表和空闲块的总数nr_free。
// (3) default_init_memmap：这个函数用于初始化一个空闲块，包括设置页面的属性和将页面链接到空闲列表。
// (4) default_alloc_pages：搜索空闲列表，找到第一个足够大的空闲块，调整空闲块的大小，并返回分配的内存块地址。
// (4.1) 搜索空闲列表，检查每个块的大小是否满足请求。
// (4.1.1) 如果找到合适的块，设置页面的标志位，并从空闲列表中移除这些页面。
// (4.1.2) 如果块的大小大于请求的大小，需要重新计算剩余空闲块的大小。
// (4.1.3) 重新计算空闲块的总数。
// (4.1.4) 返回找到的页面。
// (4.2) 如果没有找到合适的空闲块，返回NULL。
// (5) default_free_pages：将释放的页面重新链接到空闲列表中，并尝试合并小的空闲块成为大的空闲块。
// (5.1) 根据释放块的基地址，在空闲列表中找到正确的位置并插入页面。
// (5.2) 重置页面的字段，如引用计数和标志位。
// (5.3) 尝试合并低地址或高地址的块，并正确更新页面的属性。

// 定义一个全局的空闲区域结构体，用于跟踪空闲内存页
free_area_t free_area;

// 定义两个宏，用于简化对全局变量的访问
#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

// 初始化内存管理器，设置空闲列表为空，空闲页数为0
static void
default_init(void) {
    list_init(&free_list); // 初始化空闲列表
    nr_free = 0;          // 设置空闲页数为0
}

// 初始化内存映射，将给定的内存页标记为未分配，并添加到空闲列表
static void
default_init_memmap(struct Page *base, size_t n) {
    assert(n > 0); // 确保页数大于0
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(PageReserved(p)); // 确保页面是保留的
        p->flags = p->property = 0; // 清除页面标志和属性
        set_page_ref(p, 0);        // 设置页面引用计数为0
    }
    base->property = n;            // 设置基础页面的属性为页数
    SetPageProperty(base);        // 设置页面属性
    nr_free += n;                 // 更新空闲页数
    if (list_empty(&free_list)) { // 如果空闲列表为空
        list_add(&free_list, &(base->page_link)); // 将基础页面添加到空闲列表
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link); // 获取链表条目的页面
            if (base < page) {
                list_add_before(le, &(base->page_link)); // 在找到的位置之前插入
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link)); // 在列表末尾插入
            }
        }
    }
}

// 分配指定数量的内存页，如果有足够的空闲页，则分配并返回页面指针，否则返回NULL
static struct Page *
default_alloc_pages(size_t n) {
    assert(n > 0); // 确保页数大于0
    if (n > nr_free) { // 如果请求的页数超过空闲页数
        return NULL;   // 返回NULL
    }
    struct Page *page = NULL;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link); // 获取链表条目的页面
        if (p->property >= n) { // 如果页面的属性（页数）足够
            page = p;              // 设置页面为当前页面
            break;                 // 跳出循环
        }
    }
    if (page != NULL) { // 如果找到了页面
        list_entry_t* prev = list_prev(&(page->page_link)); // 获取前一个链表条目
        list_del(&(page->page_link)); // 从空闲列表中删除页面
        if (page->property > n) { // 如果页面的属性大于请求的页数
            struct Page *p = page + n; // 计算剩余页面的起始地址
            p->property = page->property - n; // 设置剩余页面的属性
            SetPageProperty(p);               // 设置剩余页面的属性
            list_add(prev, &(p->page_link)); // 将剩余页面添加到空闲列表
        }
        nr_free -= n; // 更新空闲页数
        ClearPageProperty(page); // 清除页面属性
    }
    return page; // 返回分配的页面
}

// 释放指定的内存页，将它们添加回空闲列表
static void
default_free_pages(struct Page *base, size_t n) {
    assert(n > 0); // 确保页数大于0
    struct Page *p = base;
    for (; p != base + n; p++) {
        assert(!PageReserved(p) && !PageProperty(p)); // 确保页面未被保留且没有属性
        p->flags = 0; // 清除页面标志
        set_page_ref(p, 0); // 设置页面引用计数为0
    }
    base->property = n; // 设置基础页面的属性为页数
    SetPageProperty(base); // 设置页面属性
    nr_free += n; // 更新空闲页数

    if (list_empty(&free_list)) { // 如果空闲列表为空
        list_add(&free_list, &(base->page_link)); // 将基础页面添加到空闲列表
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link); // 获取链表条目的页面
            if (base < page) {
                list_add_before(le, &(base->page_link)); // 在找到的位置之前插入
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link)); // 在列表末尾插入
            }
        }
    }

    // 尝试合并相邻的空闲页面
    list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property; // 合并页面
            ClearPageProperty(base);        // 清除被合并页面的属性
            list_del(&(base->page_link));   // 从空闲列表中删除被合并页面
            base = p;                       // 更新基础页面
        }
    }

    le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property; // 合并页面
            ClearPageProperty(p);           // 清除被合并页面的属性
            list_del(&(p->page_link));      // 从空闲列表中删除被合并页面
        }
    }
}

// 返回当前空闲的内存页数
static size_t
default_nr_free_pages(void) {
    return nr_free;
}

// 定义一个测试函数，用于检查内存管理器的基本功能
static void
basic_check(void) {
    struct Page *p0, *p1, *p2; // 定义三个页面指针变量
    p0 = p1 = p2 = NULL; // 初始化为NULL

    // 分配三页内存，并断言分配成功
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    // 断言分配的页面指针不相等，且引用计数为0
    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);

    // 断言分配的页面在有效的物理地址范围内
    assert(page2pa(p0) < npage * PGSIZE);
    assert(page2pa(p1) < npage * PGSIZE);
    assert(page2pa(p2) < npage * PGSIZE);

    // 保存当前的空闲列表和空闲页数
    list_entry_t free_list_store = free_list;
    list_init(&free_list); // 初始化空闲列表
    assert(list_empty(&free_list)); // 断言空闲列表应该为空

    unsigned int nr_free_store = nr_free; // 保存当前的空闲页数
    nr_free = 0; // 将空闲页数设置为0，模拟内存耗尽的情况

    // 断言在内存耗尽的情况下无法分配页面
    assert(alloc_page() == NULL);

    // 释放之前分配的三页内存
    free_page(p0);
    free_page(p1);
    free_page(p2);
    assert(nr_free == 3); // 断言空闲页数应该为3

    // 重新分配三页内存，并断言分配成功
    assert((p0 = alloc_page()) != NULL);
    assert((p1 = alloc_page()) != NULL);
    assert((p2 = alloc_page()) != NULL);

    // 断言在所有页面都被分配后无法再分配页面
    assert(alloc_page() == NULL);

    // 释放一页内存，并断言空闲列表不为空
    free_page(p0);
    assert(!list_empty(&free_list));

    // 再次分配一页内存，并断言分配的页面是之前释放的p0页面
    struct Page *p;
    assert((p = alloc_page()) == p0);
    assert(alloc_page() == NULL); // 断言在所有页面都被分配后无法再分配页面

    // 断言空闲页数为0
    assert(nr_free == 0);

    // 恢复空闲列表和空闲页数到初始状态
    free_list = free_list_store;
    nr_free = nr_free_store;

    // 释放剩余的两页内存
    free_page(p);
    free_page(p1);
    free_page(p2);
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
//LAB2：以下代码用于检查第一次拟合分配算法
//注意：您不应更改basic_check、default_check功能！
// 定义一个测试函数，用于检查首次适应分配算法的正确性
static void
default_check(void) {
    int count = 0, total = 0; // 初始化计数器和总数变量
    list_entry_t *le = &free_list; // 获取空闲列表的头节点
    // 遍历空闲列表，统计空闲页面的数量和总页数
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link); // 将链表条目转换为页面结构体
        assert(PageProperty(p)); // 断言页面应该有属性（即它是空闲的）
        count ++, total += p->property; // 更新计数器和总页数
    }
    assert(total == nr_free_pages()); // 断言统计的空闲页数应该与实际空闲页数相等

    basic_check(); // 调用基本检查函数，进行一些基本的内存管理器功能测试

    // 分配5页内存
    struct Page *p0 = alloc_pages(5), *p1, *p2;
    assert(p0 != NULL); // 断言分配成功
    assert(!PageProperty(p0)); // 断言分配的页面不应该有属性

    // 保存当前的空闲列表，并重置空闲列表和空闲页数
    list_entry_t free_list_store = free_list;
    list_init(&free_list); // 初始化空闲列表
    assert(list_empty(&free_list)); // 断言空闲列表应该为空
    assert(alloc_page() == NULL); // 断言现在应该无法分配页面，因为所有页面都被分配了

    unsigned int nr_free_store = nr_free; // 保存当前的空闲页数
    nr_free = 0; // 将空闲页数设置为0，模拟内存耗尽的情况

    // 释放p0 + 2开始的3页内存
    free_pages(p0 + 2, 3);
    assert(alloc_pages(4) == NULL); // 断言现在应该无法分配4页内存
    assert(PageProperty(p0 + 2) && p0[2].property == 3); // 断言p0 + 2页面应该有属性，且属性值为3
    assert((p1 = alloc_pages(3)) != NULL); // 分配3页内存，并断言分配成功
    assert(alloc_page() == NULL); // 断言现在应该无法分配单页内存
    assert(p0 + 2 == p1); // 断言分配的页面应该是p0 + 2

    // 释放p0和p1页面
    p2 = p0 + 1; // p2指向p0 + 1
    free_page(p0); // 释放p0页面
    free_pages(p1, 3); // 释放p1页面
    assert(PageProperty(p0) && p0->property == 1); // 断言p0页面应该有属性，且属性值为1
    assert(PageProperty(p1) && p1->property == 3); // 断言p1页面应该有属性，且属性值为3

    // 分配和释放页面，测试内存管理器的行为
    assert((p0 = alloc_page()) == p2 - 1); // 分配一页内存，并断言分配的页面应该是p2 - 1
    free_page(p0); // 释放p0页面
    assert((p0 = alloc_pages(2)) == p2 + 1); // 分配两页内存，并断言分配的页面应该是p2 + 1

    free_pages(p0, 2); // 释放p0页面
    free_page(p2); // 释放p2页面

    // 再次分配5页内存，并断言分配成功
    assert((p0 = alloc_pages(5)) != NULL);
    assert(alloc_page() == NULL); // 断言现在应该无法分配单页内存

    // 恢复空闲页数，并释放p0页面
    assert(nr_free == 0); // 断言空闲页数应该为0
    nr_free = nr_free_store; // 恢复空闲页数

    free_list = free_list_store; // 恢复空闲列表
    free_pages(p0, 5); // 释放p0页面

    // 再次遍历空闲列表，确保所有页面都被正确地标记为空闲
    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link); // 将链表条目转换为页面结构体
        count --, total -= p->property; // 更新计数器和总页数
    }
    assert(count == 0); // 断言计数器应该为0
    assert(total == 0); // 断言总页数应该为0
}
// 定义默认的内存管理器结构体，包含初始化、分配、释放、检查等函数
//这个结构体在pmm.h中定义了
const struct pmm_manager default_pmm_manager = {
    .name = "default_pmm_manager",
    .init = default_init,
    .init_memmap = default_init_memmap,
    .alloc_pages = default_alloc_pages,
    .free_pages = default_free_pages,
    .nr_free_pages = default_nr_free_pages,
    .check = default_check,
};


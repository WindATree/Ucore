#include <pmm.h> // 包含内存管理相关的头文件
#include <list.h> // 包含链表操作相关的头文件
#include <string.h> // 包含字符串操作相关的头文件
#include <best_fit_pmm.h> // 包含最佳适应算法内存管理器的头文件
#include <stdio.h> // 包含标准输入输出的头文件


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

/* 最佳适应算法（Best-Fit）的描述
 * 该算法维护一个空闲块列表（free list），在接收到内存请求时，会扫描列表以找到第一个足够大的空闲块来满足请求。
 * 如果选定的块比请求的大很多，则通常会将其分割，并将剩余的部分作为另一个空闲块添加到列表中。
 * 详细信息请参考严蔚敏的《数据结构 -- C语言》第8章第2节，第196~198页。
*/

// 以下是需要重写的函数：default_init, default_init_memmap, default_alloc_pages, default_free_pages。

/*
 * 最佳适应算法（Best-Fit）的详细信息
 * (1) 准备：为了实现最佳适应内存分配（Best-Fit），我们需要使用链表来管理空闲内存块。
 *      struct free_area_t用于管理空闲内存块。首先，你需要熟悉list.h中的struct list，它是一个简单的双向链表实现。
 *      你需要知道如何使用：list_init, list_add(list_add_after), list_add_before, list_del, list_next, list_prev
 *      另一个技巧是将一个通用的链表结构转换为特殊的结构（例如struct page）：
 *      你可以在memlayout.h中找到一些宏：le2page（在memlayout.h中），（在未来的实验中：le2vma（在vmm.h中），le2proc（在proc.h）等。）
 * (2) default_init：你可以重用demo default_init函数来初始化free_list并将nr_free设置为0。
 *      free_list用于记录空闲内存块。nr_free是空闲内存块的总数。
 * (3) default_init_memmap：调用图：kern_init --> pmm_init-->page_init-->init_memmap-->pmm_manager->init_memmap
 *      这个函数用于初始化一个空闲块（参数：addr_base, page_number）。
 *      首先，你应该初始化这个空闲块中的每个页面（在memlayout.h中），包括：
 *          p->flags应该设置PG_property（表示这个页面是有效的。在pmm_init函数（在pmm.c中），PG_reserved位被设置在p->flags中）
 *          如果这个页面是空闲的并且不是空闲块的第一个页面，p->property应该设置为0。
 *          如果这个页面是空闲的并且是空闲块的第一个页面，p->property应该设置为块的总数。
 *          p->ref应该为0，因为现在p是空闲的，没有引用。
 *          我们可以使用p->page_link将这个页面链接到free_list（例如：list_add_before(&free_list, &(p->page_link));）
 *      最后，我们应该计算空闲内存块的数量：nr_free+=n
 * (4) default_alloc_pages：在free list中搜索找到第一个足够大的空闲块（块大小 >= n）并调整空闲块的大小，返回malloced块的地址。
 *      (4.1) 所以你应该这样搜索freelist：
 *               list_entry_t le = &free_list;
 *               while((le=list_next(le)) != &free_list) {
 *               .....
 *      (4.1.1) 在while循环中，获取struct page并检查p->property（记录空闲块的数量） >= n？
 *              struct Page *p = le2page(le, page_link);
 *              if(p->property >= n){ ...
 *      (4.1.2) 如果我们找到了这个p，那么意味着我们找到了一个空闲块（块大小 >= n），并且前n个页面可以被malloced。
 *             这个页面的一些标志位应该被设置：PG_reserved =1, PG_property =0
 *             从free_list中解除这些页面的链接
 *             (4.1.2.1) 如果（p->property > n），我们应该重新计算这个空闲块剩余的数量，
 *                    （例如：le2page(le,page_link))->property = p->property - n;）
 *      (4.1.3)  重新计算nr_free（所有空闲块剩余的数量）
 *      (4.1.4)  返回p
 *      (4.2) 如果我们找不到一个足够大的空闲块（块大小 >= n），那么返回NULL
 * (5) default_free_pages：将页面重新链接到free list，可能将小的空闲块合并成大的空闲块。
 *      (5.1) 根据撤回块的基地址，搜索free list，找到正确的位置（从低到高地址），并插入页面。（可能使用list_next, le2page, list_add_before）
 *      (5.2) 重置页面的字段，例如p->ref, p->flags（PageProperty）
 *      (5.3) 尝试合并低地址或高地址块。注意：应该正确更改一些页面的p->property。
 */

extern free_area_t free_area; // 声明一个全局的空闲区域结构体

#define free_list (free_area.free_list) // 定义宏，指向空闲链表的头部
#define nr_free (free_area.nr_free) // 定义宏，指向空闲内存块的数量

// 初始化最佳适应算法的内存管理器
static void
best_fit_init(void) {
    list_init(&free_list); // 初始化空闲链表
    nr_free = 0; // 初始化空闲内存块的数量为0
}

// 初始化内存映射
static void
best_fit_init_memmap(struct Page *base, size_t n) {
    assert(n > 0); // 确保n大于0
    struct Page *p = base; // 从base开始初始化
    for (; p != base + n; p ++) {
        assert(PageReserved(p)); // 确保页面被保留

        // 清空当前页框的标志和属性信息，并将页框的引用计数设置为0
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    base->property = n; // 设置基地址的属性为n
    SetPageProperty(base); // 设置页面属性
    nr_free += n; // 增加空闲内存块的数量
    if (list_empty(&free_list)) { // 如果空闲链表为空
        list_add(&free_list, &(base->page_link)); // 将基地址添加到空闲链表
    } else {
        list_entry_t* le = &free_list; // 遍历空闲链表
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link); // 获取当前链表项对应的页面
            // 当base小于page时，找到第一个大于base的页，将base插入到它前面，并退出循环
            if(base->property < page->property){
                list_add_before(le, &(base->page_link));
                break;
            } else if(list_next(le) == &free_list){ // 如果已经到达链表结尾，将base插入到链表尾部
                list_add(le, &(base->page_link));
            }
        }
    }
}

// 最佳适应算法分配内存页
static struct Page *
best_fit_alloc_pages(size_t n) {
    assert(n > 0); // 确保n大于0
    if (n > nr_free) { // 如果请求的页数大于空闲页数
        return NULL; // 返回NULL
    }
    struct Page *page = NULL; // 初始化page为NULL
    list_entry_t *le = &free_list; // 从空闲链表的头部开始遍历
    size_t min_size = nr_free + 1; // 初始化最小大小为nr_free + 1
    struct Page *temp = NULL; // 临时变量，用于记录找到的最小空闲块
    // 遍历空闲链表，查找满足需求的空闲页框
    // 如果找到满足需求的页面，记录该页面以及当前找到的最小连续空闲页框数量
    int y=0;
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link); // 获取当前链表项对应的页面
        if (p->property >= n && p->property < min_size) { // 如果页面的属性大于等于n且小于当前最小大小
            min_size = p->property; // 更新最小大小
            temp = p; // 更新临时变量
            y++;
            cprintf("y===============%d\n",y);
            //break;
        }
    }
    page = temp; // 将找到的最小空闲块赋值给page
    if (page != NULL) { // 如果找到了合适的空闲块
        list_entry_t* prev = list_prev(&(page->page_link)); // 获取前一个链表项
        list_del(&(page->page_link)); // 从空闲链表中删除该空闲块
        if (page->property > n) { // 如果空闲块的大小大于请求的大小
            struct Page *p = page + n; // 计算剩余空闲块的起始地址
            p->property = page->property - n; // 更新剩余空闲块的大小
            SetPageProperty(p); // 设置剩余空闲块的属性
            list_add(prev, &(p->page_link)); // 将剩余空闲块添加到空闲链表
        }
        nr_free -= n; // 更新空闲内存块的数量
        ClearPageProperty(page); // 清除页面属性
    }
    return page; // 返回分配的内存页
}
static void best_fit_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    struct Page *p = base;

    // 设置释放页面的状态
    for (; p != base + n; p++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0; // 清除标志
        set_page_ref(p, 0); // 设置引用计数为0
    }

    base->property = n; // 设置新释放块的属性
    SetPageProperty(base);
    nr_free += n;

    // 查找插入位置并插入
    list_entry_t* le = &free_list;
    while ((le = list_next(le)) != &free_list) {
        struct Page *page = le2page(le, page_link);
        if (base->property < page->property) {
            list_add_before(le, &(base->page_link));
            break;
        }
    }
    if (le == &free_list) {
        list_add(le, &(base->page_link));
    }

    // 尝试合并相邻块
    le = list_prev(&(base->page_link));
    if (le != &free_list) {
        struct Page *prev_page = le2page(le, page_link);
        if (prev_page + prev_page->property == base) {
            prev_page->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = prev_page; // 合并后更新base指向合并后的块
        }
    }

    le = list_next(&(base->page_link));
    if (le != &free_list) {
        struct Page *next_page = le2page(le, page_link);
        if (base + base->property == next_page) {
            base->property += next_page->property;
            ClearPageProperty(next_page);
            list_del(&(next_page->page_link));
        }
    }
}

// 最佳适应算法释放内存页
// static void
// best_fit_free_pages(struct Page *base, size_t n) {
//     assert(n > 0); // 确保n大于0
//     struct Page *p = base; // 从base开始释放
//     for (; p != base + n; p ++) {
//         assert(!PageReserved(p) && !PageProperty(p)); // 确保页面未被保留且没有属性
//         p->flags = 0; // 清除页面的标志
//         set_page_ref(p, 0); // 将页面的引用计数设置为0
//     }
//     // 设置当前页块的属性为释放的页块数、并将当前页块标记为已分配状态、最后增加nr_free的值
//     base->property = n;
//     SetPageProperty(base);
//     nr_free += n;
//     if (list_empty(&free_list)) { // 如果空闲链表为空
//         list_add(&free_list, &(base->page_link)); // 将基地址添加到空闲链表
//     } else {
//         list_entry_t* le = &free_list; // 遍历空闲链表
//         while ((le = list_next(le)) != &free_list) {
//             struct Page* page = le2page(le, page_link); // 获取当前链表项对应的页面
//             if (base->property < page->property) { // 如果base小于page
//                 list_add_before(le, &(base->page_link)); // 将base插入到page前面
//                 break;
//             } else if (list_next(le) == &free_list) { // 如果已经到达链表结尾
//                 list_add(le, &(base->page_link)); // 将base插入到链表尾部
//             }
//         }
//     }

//     list_entry_t* le = list_prev(&(base->page_link)); // 获取前一个链表项
//     if (le != &free_list) { // 如果前一个链表项不是空闲链表的头部
//         p = le2page(le, page_link); // 获取前一个链表项对应的页面
//         // 判断前面的空闲页块是否与当前页块是连续的，如果是连续的，则将当前页块合并到前面的空闲页块中
//         if(p + p->property == base){
//             p->property += base->property; // 更新前一个空闲页块的大小
//             ClearPageProperty(base); // 清除当前页块的属性标记
//             list_del(&(base->page_link)); // 从链表中删除当前页块
//             base = p; // 将指针指向前一个空闲页块
//         }
//     }

//     le = list_next(&(base->page_link)); // 获取后一个链表项
//     if (le != &free_list) { // 如果后一个链表项不是空闲链表的头部
//         p = le2page(le, page_link); // 获取后一个链表项对应的页面
//         if (base + base->property == p) { // 如果当前页块与后一个页块是连续的
//             base->property += p->property; // 更新当前页块的大小
//             ClearPageProperty(p); // 清除后一个页块的属性标记
//             list_del(&(p->page_link)); // 从链表中删除后一个页块
//         }
//     }
// }

// 获取空闲内存页的数量
static size_t
best_fit_nr_free_pages(void) {
    return nr_free; // 返回空闲内存块的数量
}

// 基本检查函数
static void
basic_check(void) {
    struct Page *p0, *p1, *p2; // 定义三个页面指针
    p0 = p1 = p2 = NULL; // 初始化为NULL
    assert((p0 = alloc_page()) != NULL); // 分配一个页面
    assert((p1 = alloc_page()) != NULL); // 分配一个页面
    assert((p2 = alloc_page()) != NULL); // 分配一个页面

    assert(p0 != p1 && p0 != p2 && p1 != p2); // 确保分配的页面地址不同
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0); // 确保页面的引用计数为0

    assert(page2pa(p0) < npage * PGSIZE); // 确保页面地址在有效范围内
    assert(page2pa(p1) < npage * PGSIZE); // 确保页面地址在有效范围内
    assert(page2pa(p2) < npage * PGSIZE); // 确保页面地址在有效范围内

    list_entry_t free_list_store = free_list; // 保存当前的空闲链表
    list_init(&free_list); // 初始化空闲链表
    assert(list_empty(&free_list)); // 确保空闲链表为空

    unsigned int nr_free_store = nr_free; // 保存当前的空闲内存块数量
    nr_free = 0; // 将空闲内存块数量设置为0

    assert(alloc_page() == NULL); // 确保没有更多的页面可以分配

    free_page(p0); // 释放页面p0
    free_page(p1); // 释放页面p1
    free_page(p2); // 释放页面p2
    assert(nr_free == 3); // 确保空闲内存块数量为3

    assert((p0 = alloc_page()) != NULL); // 分配一个页面
    assert((p1 = alloc_page()) != NULL); // 分配一个页面
    assert((p2 = alloc_page()) != NULL); // 分配一个页面

    assert(alloc_page() == NULL); // 确保没有更多的页面可以分配

    free_page(p0); // 释放页面p0
    assert(!list_empty(&free_list)); // 确保空闲链表不为空

    struct Page *p; // 定义一个页面指针
    assert((p = alloc_page()) == p0); // 分配一个页面，确保是之前释放的p0
    assert(alloc_page() == NULL); // 确保没有更多的页面可以分配

    assert(nr_free == 0); // 确保空闲内存块数量为0
    free_list = free_list_store; // 恢复之前的空闲链表
    nr_free = nr_free_store; // 恢复之前的空闲内存块数量

    free_page(p); // 释放页面p
    free_page(p1); // 释放页面p1
    free_page(p2); // 释放页面p2
}

// 检查最佳适应算法
static void
best_fit_check(void) {
    int score = 0, sumscore = 6; // 初始化分数和总分
    int count = 0, total = 0; // 初始化计数器和总数
    list_entry_t *le = &free_list; // 遍历空闲链表
    while ((le = list_next(le)) != &free_list) { // 遍历空闲链表
        struct Page *p = le2page(le, page_link); // 获取当前链表项对应的页面
        assert(PageProperty(p)); // 确保页面有属性
        count ++, total += p->property; // 更新计数器和总数
    }
    assert(total == nr_free_pages()); // 确保总数等于空闲页面的数量

    basic_check(); // 执行基本检查

    #ifdef ucore_test // 如果定义了ucore_test
    score += 1; // 更新分数
    cprintf("grading: %d / %d points\n", score, sumscore); // 打印分数
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2; // 分配5个页面
    assert(p0 != NULL); // 确保分配成功
    assert(!PageProperty(p0)); // 确保页面没有属性

    #ifdef ucore_test // 如果定义了ucore_test
    score += 1; // 更新分数
    cprintf("grading: %d / %d points\n", score, sumscore); // 打印分数
    #endif
    list_entry_t free_list_store = free_list; // 保存当前的空闲链表
    list_init(&free_list); // 初始化空闲链表
    assert(list_empty(&free_list)); // 确保空闲链表为空
    assert(alloc_page() == NULL); // 确保没有更多的页面可以分配

    #ifdef ucore_test // 如果定义了ucore_test
    score += 1; // 更新分数
    cprintf("grading: %d / %d points\n", score, sumscore); // 打印分数

    #endif
    unsigned int nr_free_store = nr_free; // 保存当前的空闲内存块数量
    nr_free = 0; // 将空闲内存块数量设置为0

    // 释放页面p0的后两个页面
    free_pages(p0 + 1, 2);
    // 释放页面p0的第四个页面
    free_pages(p0 + 4, 1);
    assert(alloc_pages(4) == NULL); // 确保没有足够的连续页面可以分配
    assert(PageProperty(p0 + 1) && p0[1].property == 2); // 确保页面p0 + 1有属性且大小为2

    // 分配一个页面
    assert((p1 = alloc_pages(1)) != NULL); 
    assert(alloc_pages(2) != NULL); // 最佳适应特征
    assert(p0 + 4 == p1); // 确保分配的页面是p0 + 4

    #ifdef ucore_test // 如果定义了ucore_test
    score += 1; // 更新分数
    cprintf("grading: %d / %d points\n", score, sumscore); // 打印分数
    #endif
    p2 = p0 + 1; // 将p2指向p0 + 1
    free_pages(p0, 5); // 释放p0的5个页面
    assert((p0 = alloc_pages(5)) != NULL); // 分配5个页面
    assert(alloc_page() == NULL); // 确保没有更多的页面可以分配

    #ifdef ucore_test // 如果定义了ucore_test
    score += 1; // 更新分数
    cprintf("grading: %d / %d points\n", score, sumscore); // 打印分数
    #endif
    assert(nr_free == 0); // 确保空闲内存块数量为0
    nr_free = nr_free_store; // 恢复之前的空闲内存块数量

    free_list = free_list_store; // 恢复之前的空闲链表
    free_pages(p0, 5); // 释放p0的5个页面

    le = &free_list; // 遍历空闲链表
    while ((le = list_next(le)) != &free_list) { // 遍历空闲链表
        struct Page *p = le2page(le, page_link); // 获取当前链表项对应的页面
        count --, total -= p->property; // 更新计数器和总数
    }
    assert(count == 0); // 确保计数器为0
    assert(total == 0); // 确保总数为0
    #ifdef ucore_test // 如果定义了ucore_test
    score += 1; // 更新分数
    cprintf("grading: %d / %d points\n", score, sumscore); // 打印分数
    #endif
}

// 定义最佳适应算法内存管理器的结构体
const struct pmm_manager best_fit_pmm_manager = {
    .name = "best_fit_pmm_manager", // 内存管理器的名称
    .init = best_fit_init, // 初始化函数
    .init_memmap = best_fit_init_memmap, // 初始化内存映射函数
    .alloc_pages = best_fit_alloc_pages, // 分配内存页函数
    .free_pages = best_fit_free_pages, // 释放内存页函数
    .nr_free_pages = best_fit_nr_free_pages, // 获取空闲内存页数量函数
    .check = best_fit_check, // 检查函数
};


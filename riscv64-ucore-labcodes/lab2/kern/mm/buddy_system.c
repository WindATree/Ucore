#include "buddy_system.h"
#include <pmm.h>
#include <list.h>
#include <string.h>
#include <stdio.h>
#include <memlayout.h>

free_buddy_t free_buddy;
#define free_list (free_buddy.buddy_list)
#define order (free_buddy.order)
#define nr_free (free_buddy.nr_free)
extern ppn_t fppn;
//check is 2^n
static uint32_t Is_Power_Of_2(uint32_t x){
    if(x>0&&(x&(x-1))==0){
        return 1;
    }
    return 0;
}

//return log 2 x,suf
static uint32_t Get_Power_Of_2(uint32_t x){
    uint32_t count=0;
    while(x>1){
        x=x>>1;
        count++;
    }
    return count;
}

static void buddy_system_init(void){
    for(int i=0;i<16;i++){
        list_init(free_list+i);
    }
    nr_free=0;
    order=0;
}
static void buddy_show(void){
    for(int i=0;i<16;i++){
        cprintf("%d,layer",i);
        list_entry_t *le=&free_list[i];
        while((le=list_next(le))!=&(free_list[i])){
            struct Page *p = le2page(le, page_link);
            cprintf("%d,free_page is ",1<<p->property);
        }
        cprintf("\n");
    }
    return;
}

void buddy_system_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    //cprintf("Initializing buddy system memmap for %lu pages starting at %p\n", n, base);

    struct Page *p = base;

    order = Get_Power_Of_2(n);

    uint32_t real_n = 1 << order;

    nr_free += real_n;

    //cprintf("Order: %d, Real number of pages: %d\n", order, real_n);

    for (; p != base + real_n; p += 1) {
        //cprintf("Initializing page at %p\n", p);
        assert(PageReserved(p));  // 确保页面已保留
        p->property = p->flags = 0;  // 清除属性和标志
        set_page_ref(p, 0);  // 设置页面引用计数
    }

    //cprintf("Adding page block to free list at order %d\n", order);
    list_add(&free_list[order], &base->page_link);  // 将块加入到空闲链表
    base->property = real_n;
    SetPageProperty(base);  // 设置块为已使用
}
//get the ppn of buddy
static struct Page* Get_buddy(struct Page*page){
    uint32_t power=page->property; 
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));
    return page+(ppn-page2ppn(page));
}

static size_t buddy_nr_free_pages(void){
    return nr_free;
}
static struct Page * buddy_alloc_pages(size_t real_n) {
    assert(real_n > 0);

    if (real_n > nr_free) {
        cprintf("buddy_alloc_pages: Not enough free pages. Needed: %lu, Available: %d\n", real_n, nr_free);
        return NULL;
    }

    struct Page *page = NULL;
    order = Is_Power_Of_2(real_n) ? Get_Power_Of_2(real_n) : Get_Power_Of_2(real_n) + 1;
    size_t n = 1 << order;
    cprintf("buddy_alloc_pages: Request for %lu pages, calculated order: %u, n: %lu\n", real_n, order, n);

    while (1) {
        if (!list_empty(&(free_list[order]))) {
            page = le2page(list_next(&(free_list[order])), page_link);
            list_del(list_next(&(free_list[order])));
            SetPageProperty(page);
            nr_free -= n;
            cprintf("buddy_alloc_pages: Allocated %lu pages from free_list[%u] at address %p\n", n, order, page);
            break;
        }

        for (int i = order; i < 16; i++) {
            if (!list_empty(&(free_list[i]))) {
                struct Page *page1 = le2page(list_next(&(free_list[i])), page_link);
                struct Page *page2 = page1 + (1 << (i - 1));
                page1->property = i - 1;
                page2->property = i - 1;
                list_del(list_next(&(free_list[i])));
                list_add(&(free_list[i-1]), &(page2->page_link));
                list_add(&(free_list[i-1]), &(page1->page_link));
                cprintf("buddy_alloc_pages: Split block from free_list[%d] into two blocks of size %lu pages (power %d)\n", i, (1 << (i - 1)), i - 1);
                break;
            }
        }
    }

    return page;
}

static void buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);

    nr_free += 1 << base->property;
    struct Page *free_page = base;
    struct Page *free_page_buddy = Get_buddy(free_page);

    cprintf("buddy_free_pages: Releasing %lu pages starting at address %p with property %u\n", n, free_page, free_page->property);

    list_add(&(free_list[free_page->property]), &(free_page->page_link));

    while (!PageProperty(free_page_buddy) && free_page->property < 14) {
        if (free_page_buddy < free_page) {
            struct Page *temp;
            free_page->property = 0;
            ClearPageProperty(free_page);
            temp = free_page;
            free_page = free_page_buddy;
            free_page_buddy = temp;
            cprintf("buddy_free_pages: Swapped free_page and free_page_buddy\n");
        }

        list_del(&(free_page->page_link));
        list_del(&(free_page_buddy->page_link));

        free_page->property += 1;
        list_add(&(free_list[free_page->property]), &(free_page->page_link));
        cprintf("buddy_free_pages: Merged block, new property: %u, added to free_list[%u]\n", free_page->property, free_page->property);

        free_page_buddy = Get_buddy(free_page);
    }

    ClearPageProperty(free_page);
    cprintf("buddy_free_pages: Pages successfully released\n");
}

static void buddy_check_0(void) {

#define ALLOC_PAGE_NUM 100

    cprintf("[buddy_check_0] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");

    size_t initial_nr_free_pages = nr_free_pages();

    cprintf("[buddy_check_0] before alloc: ");
    //buddy_show();

    cprintf("[buddy_check_0] trying to alloc %d * 1 pages\n", ALLOC_PAGE_NUM);

    struct Page *pages[ALLOC_PAGE_NUM];


    for (int i = 0; i < ALLOC_PAGE_NUM; i++) {
        pages[i] = alloc_pages(1);
        for (int j = 0; j < i; j++) {
            if (pages[i] == pages[j]) {
                cprintf("Error: Duplicate page pointer at %p (pages[%d] and pages[%d])\n", pages[i], i, j);
            }   
        }
        assert(pages[i] != NULL);
    }

    assert(nr_free_pages() == initial_nr_free_pages - ALLOC_PAGE_NUM);

    cprintf("[buddy_check_0] after alloc:  ");
    //buddy_show();

    for (int i = 0; i < ALLOC_PAGE_NUM; i++) {
        free_pages(pages[i], 1);
    }
    assert(nr_free_pages() == initial_nr_free_pages);

    cprintf("[buddy_check_0] after free:   ");
    //buddy_show();

    cprintf("[buddy_check_0] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");    
}

static void buddy_check_1(void) {
    cprintf("[buddy_check_1] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");

    size_t initial_nr_free_pages = nr_free_pages();

    cprintf("[buddy_check_0] before alloc:          ");
    //buddy_show();

    struct Page* p0 = alloc_pages(512);

    assert(p0 != NULL);

    assert(p0->property == 9);

    cprintf("[buddy_check_1] after alloc 512 pages: ");
    //buddy_show();

    struct Page* p1 = alloc_pages(513);
    assert(p1 != NULL);
    assert(p1->property == 10);
    cprintf("[buddy_check_1] after alloc 513 pages: ");
    //buddy_show();

    struct Page* p2 = alloc_pages(79);
    assert(p2 != NULL);
    assert(p2->property == 7);
    cprintf("[buddy_check_1] after alloc 79 pages:  ");
    //buddy_show();

    struct Page* p3 = alloc_pages(37);
    assert(p3 != NULL);
    assert(p3->property == 6);
    cprintf("[buddy_check_1] after alloc 37 pages:  ");
    //buddy_show();

    struct Page* p4 = alloc_pages(3);
    assert(p4 != NULL);
    assert(p4->property == 2);
    cprintf("[buddy_check_1] after alloc 3 pages:   ");
    //buddy_show();

    struct Page* p5 = alloc_pages(196);
    assert(p5 != NULL);
    assert(p5->property == 8);
    cprintf("[buddy_check_1] after alloc 196 pages: ");
    //buddy_show();

    free_pages(p4, 3);
    free_pages(p0, 512);
    free_pages(p2, 79);
    free_pages(p3, 37);
    free_pages(p5, 196);
    free_pages(p1, 513);

    cprintf("[buddy_check_1] after free:            ");
    //buddy_show();

    assert(nr_free_pages() == initial_nr_free_pages);

    cprintf("[buddy_check_1] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
}
static void buddy_check(){
    //buddy_show();
    buddy_check_0();
    buddy_check_1();
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_system_init,
    .init_memmap = buddy_system_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};

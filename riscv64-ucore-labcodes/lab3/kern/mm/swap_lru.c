#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_lru.h>
#include <list.h>

/* 
 * _lru_init_mm - 初始化链表用于 LRU 缺页管理
 * @mm: 管理虚拟内存区域的 mm_struct 结构体
 */
static int _lru_init_mm(struct mm_struct *mm)
{
    list_init(&pra_list_head); // 初始化全局链表头
    mm->sm_priv = &pra_list_head; // 将链表头指针存入 mm 结构体中
    return 0;
}

/*
 * _lru_map_swappable - 将页面标记为可交换
 * @mm: 管理虚拟内存区域的 mm_struct 结构体
 * @addr: 页面的虚拟地址
 * @page: 要标记的 Page 结构体
 * @swap_in: 表示是否为交换入
 */
static int _lru_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head = (list_entry_t *) mm->sm_priv;
    list_entry_t *entry = &(page->pra_page_link);

    assert(entry != NULL && head != NULL);
    list_add((list_entry_t*) mm->sm_priv, entry); // 将页面链接至链表头部
    return 0;
}

/*
 * _lru_swap_out_victim - 选择要替换的页面
 * @mm: 管理虚拟内存区域的 mm_struct 结构体
 * @ptr_page: 返回的替换页面指针
 * @in_tick: 时间片标志，为0表示立即替换
 */
static int _lru_swap_out_victim(struct mm_struct *mm, struct Page **ptr_page, int in_tick)
{
    list_entry_t *head = (list_entry_t *) mm->sm_priv;
    assert(head != NULL);
    assert(in_tick == 0);
    list_entry_t* entry = list_prev(head); // 获取最久未使用的页面，即链表尾部页面
    if (entry != head) {
        list_del(entry); // 从链表中删除该页面
        *ptr_page = le2page(entry, pra_page_link); // 更新 ptr_page
    } else {
        *ptr_page = NULL;
    }
    return 0;
}

/*
 * print_mm_list - 打印链表中的页面信息（用于调试）
 */
static void print_mm_list() {
    cprintf("--------begin----------\n");
    list_entry_t *head = &pra_list_head, *le = head;
    while ((le = list_next(le)) != head) {
        struct Page* page = le2page(le, pra_page_link);
        cprintf("vaddr: 0x%x\n", page->pra_vaddr); // 输出页面虚拟地址
    }
    cprintf("---------end-----------\n");
}

/*
 * _lru_check_swap - 测试并检查 LRU 缺页管理功能
 */
static int _lru_check_swap(void) {
    print_mm_list();
    cprintf("write Virt Page c in lru_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    print_mm_list();
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    print_mm_list();
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    print_mm_list();
    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    print_mm_list();
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    print_mm_list();
    cprintf("write Virt Page a in lru_check_swap\n");
    *(unsigned char *)0x1000 = 0x0a;
    print_mm_list();
    cprintf("write Virt Page b in lru_check_swap\n");
    *(unsigned char *)0x2000 = 0x0b;
    print_mm_list();
    cprintf("write Virt Page c in lru_check_swap\n");
    *(unsigned char *)0x3000 = 0x0c;
    print_mm_list();
    cprintf("write Virt Page d in lru_check_swap\n");
    *(unsigned char *)0x4000 = 0x0d;
    print_mm_list();
    cprintf("write Virt Page e in lru_check_swap\n");
    *(unsigned char *)0x5000 = 0x0e;
    print_mm_list();
    cprintf("write Virt Page a in lru_check_swap\n");
    assert(*(unsigned char *)0x1000 == 0x0a);
    *(unsigned char *)0x1000 = 0x0a;
    print_mm_list();
    return 0;
}

/*
 * _lru_init - 初始化 LRU 缺页管理器
 */
static int _lru_init(void) {
    return 0;
}

/*
 * _lru_set_unswappable - 将页面标记为不可交换
 */
static int _lru_set_unswappable(struct mm_struct *mm, uintptr_t addr) {
    return 0;
}

/*
 * _lru_tick_event - 用于响应时间片事件（此处未实现）
 */
static int _lru_tick_event(struct mm_struct *mm) {
    return 0;
}

/*
 * unable_page_read - 设置所有页面为不可读
 */
static int unable_page_read(struct mm_struct *mm) {
    list_entry_t *head = (list_entry_t *) mm->sm_priv, *le = head;
    while ((le = list_prev(le)) != head) {
        struct Page* page = le2page(le, pra_page_link);
        pte_t* ptep = NULL;
        ptep = get_pte(mm->pgdir, page->pra_vaddr, 0);
        *ptep &= ~PTE_R; // 清除读权限
    }
    return 0;
}

/*
 * lru_pgfault - 处理 LRU 缺页异常
 * @mm: 管理虚拟内存区域的 mm_struct 结构体
 * @error_code: 错误代码
 * @addr: 触发异常的地址
 */
int lru_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
    cprintf("lru page fault at 0x%x\n", addr);
    if (swap_init_ok) 
        unable_page_read(mm); // 设置所有页面不可读

    pte_t* ptep = get_pte(mm->pgdir, addr, 0);
    *ptep |= PTE_R; // 将需要的页面设置为可读

    if (!swap_init_ok) 
        return 0;
    
    struct Page* page = pte2page(*ptep);
    list_entry_t *head = (list_entry_t*) mm->sm_priv, *le = head;
    while ((le = list_prev(le)) != head) {
        struct Page* curr = le2page(le, pra_page_link);
        if (page == curr) {
            list_del(le); // 从链表中删除该页面
            list_add(head, le); // 将页面移到链表头部
            break;
        }
    }
    return 0;
}

// 定义全局变量 swap_manager_lru 用于管理 LRU 替换算法
struct swap_manager swap_manager_lru = {
    .name            = "lru swap manager", // 管理器名称
    .init            = &_lru_init, // 初始化函数
    .init_mm         = &_lru_init_mm, // 初始化 mm 结构体
    .tick_event      = &_lru_tick_event, // 响应时间片事件
    .map_swappable   = &_lru_map_swappable, // 标记页面为可交换
    .set_unswappable = &_lru_set_unswappable, // 标记页面为不可交换
    .swap_out_victim = &_lru_swap_out_victim, // 选择替换页面
    .check_swap      = &_lru_check_swap, // 测试缺页管理
};

#include <swap.h>
#include <swapfs.h>
#include <swap_fifo.h>
#include <swap_clock.h>
#include <swap_lru.h>
#include <stdio.h>
#include <string.h>
#include <memlayout.h>
#include <pmm.h>
#include <mmu.h>

// 定义检查时有效的虚拟地址范围为0到CHECK_VALID_VADDR-1
#define CHECK_VALID_VIR_PAGE_NUM 5
#define BEING_CHECK_VALID_VADDR 0X1000
#define CHECK_VALID_VADDR (CHECK_VALID_VIR_PAGE_NUM+1)*0x1000
// 定义检查时有效的物理页面的最大数量
#define CHECK_VALID_PHY_PAGE_NUM 4
// 定义最大访问序列编号
#define MAX_SEQ_NO 10

static struct swap_manager *sm; // 指向交换管理器的指针
size_t max_swap_offset;         // 定义最大交换偏移量

volatile int swap_init_ok = 0;  // 定义交换初始化是否成功的全局变量

unsigned int swap_page[CHECK_VALID_VIR_PAGE_NUM]; // 定义用于检查的交换页面数组

unsigned int swap_in_seq_no[MAX_SEQ_NO], swap_out_seq_no[MAX_SEQ_NO]; // 定义交换进出序列编号数组

static void check_swap(void); // 声明检查交换的静态函数

int
swap_init(void)
{
     swapfs_init(); // 初始化交换文件系统

     // 检查交换偏移量是否能够在模拟的IDE中存储至少7个页面以通过测试
     if (!(7 <= max_swap_offset &&
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset); // 如果不在预期范围内，触发panic
     }

     sm = &swap_manager_clock; // 设置交换管理器为clock替换算法
     int r = sm->init(); // 调用交换管理器的初始化函数
     
     if (r == 0) // 如果初始化成功
     {
          swap_init_ok = 1; // 设置交换初始化成功的全局标志
          cprintf("SWAP: manager = %s\n", sm->name); // 打印交换管理器的名称
          check_swap(); // 调用检查交换的函数
     }

     return r; // 返回初始化结果
}

int
swap_init_mm(struct mm_struct *mm)
{
     return sm->init_mm(mm);
}

int
swap_tick_event(struct mm_struct *mm)
{
     return sm->tick_event(mm);
}

int
swap_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
     return sm->map_swappable(mm, addr, page, swap_in);
}

int
swap_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
     return sm->set_unswappable(mm, addr);
}

volatile unsigned int swap_out_num=0;

// 将指定数量的页面从物理内存交换到磁盘上
int
swap_out(struct mm_struct *mm, int n, int in_tick) {
    int i;
    for (i = 0; i != n; ++i) {
        uintptr_t v;
        struct Page *page;
        // 调用交换管理器的swap_out_victim函数选择一个牺牲页面
        int r = sm->swap_out_victim(mm, &page, in_tick);
        if (r != 0) {
            cprintf("i %d, swap_out: call swap_out_victim failed\n", i);
            break;
        }
        // 获得页面的虚拟地址
        v = page->pra_vaddr; 
        pte_t *ptep = get_pte(mm->pgdir, v, 0);
        assert((*ptep & PTE_V) != 0); // 确保页表条目有效

        // 尝试将页面写入交换文件系统
        if (swapfs_write((page->pra_vaddr / PGSIZE + 1) << 8, page) != 0) {
            cprintf("SWAP: failed to save\n");
            sm->map_swappable(mm, v, page, 0); // 如果失败，重新映射为可交换
            continue;
        } else {
            cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
            *ptep = (page->pra_vaddr / PGSIZE + 1) << 8; // 更新页表条目
            free_page(page); // 释放页面
        }
        
        tlb_invalidate(mm->pgdir, v); // 使TLB无效，确保CPU的缓存与内存管理单元同步
    }
    return i; // 返回实际交换出的页面数量
}

// 从磁盘上交换页面到物理内存
int
swap_in(struct mm_struct *mm, uintptr_t addr, struct Page **ptr_result) {
    struct Page *result = alloc_page(); // 分配一个新页面
    assert(result != NULL); // 确保分配成功

    pte_t *ptep = get_pte(mm->pgdir, addr, 0); // 获取页表条目
    // 从交换文件系统读取数据到页面
    int r;
    if ((r = swapfs_read((*ptep), result)) != 0) {
        assert(r != 0); // 如果读取失败，断言失败
    }
    cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep) >> 8, addr);
    *ptr_result = result; // 设置函数返回的页面
    return 0; // 成功返回
}



// 定义一个内联函数，用于设置特定虚拟地址的内容，并触发页面错误以验证页面错误次数
static inline void
check_content_set(void) {
    // 将地址0x1000处的内容设置为0x0a，并期望此时发生第一次页面错误
    *(unsigned char *)0x1000 = 0x0a;
    assert(pgfault_num==1);
    // 再次访问地址0x1010处，确保页面错误次数仍为1次
    *(unsigned char *)0x1010 = 0x0a;
    assert(pgfault_num==1);
    // 将地址0x2000处的内容设置为0x0b，并期望此时发生第二次页面错误
    *(unsigned char *)0x2000 = 0x0b;
    assert(pgfault_num==2);
    // 再次访问地址0x2010处，确保页面错误次数仍为2次
    *(unsigned char *)0x2010 = 0x0b;
    assert(pgfault_num==2);
    // 将地址0x3000处的内容设置为0x0c，并期望此时发生第三次页面错误
    *(unsigned char *)0x3000 = 0x0c;
    assert(pgfault_num==3);
    // 再次访问地址0x3010处，确保页面错误次数仍为3次
    *(unsigned char *)0x3010 = 0x0c;
    assert(pgfault_num==3);
    // 将地址0x4000处的内容设置为0x0d，并期望此时发生第四次页面错误
    *(unsigned char *)0x4000 = 0x0d;
    assert(pgfault_num==4);
    // 再次访问地址0x4010处，确保页面错误次数仍为4次
    *(unsigned char *)0x4010 = 0x0d;
    assert(pgfault_num==4);
}

// 定义一个内联函数，用于访问内容并检查页面替换算法是否正确
static inline int
check_content_access(void) {
    int ret = sm->check_swap(); // 调用交换管理器的check_swap函数进行页面替换检查
    return ret; // 返回检查结果
}


struct Page * check_rp[CHECK_VALID_PHY_PAGE_NUM];
pte_t * check_ptep[CHECK_VALID_PHY_PAGE_NUM];
unsigned int check_swap_addr[CHECK_VALID_VIR_PAGE_NUM];

extern free_area_t free_area;

#define free_list (free_area.free_list)
#define nr_free (free_area.nr_free)

// 定义一个静态函数，用于检查页面交换机制是否正常工作
static void
check_swap(void) {
    // 备份当前内存环境
    int ret, count = 0, total = 0, i;
    list_entry_t *le = &free_list; // 指向空闲页面链表的头部
    while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p)); // 确保页面属性正确
        count ++, total += p->property;
    }
    assert(total == nr_free_pages()); // 确保空闲页面总数正确
    cprintf("BEGIN check_swap: count %d, total %d\n", count, total);
     
    // 设置物理页面环境
    struct mm_struct *mm = mm_create(); // 创建内存管理结构
    assert(mm != NULL);

    extern struct mm_struct *check_mm_struct;
    assert(check_mm_struct == NULL); // 确保之前没有设置过检查用的内存管理结构

    check_mm_struct = mm; // 设置当前的内存管理结构为检查用的内存管理结构

    pde_t *pgdir = mm->pgdir = boot_pgdir; // 设置页目录
    assert(pgdir[0] == 0); // 确保页目录的第一项是空的

    struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ); // 创建虚拟内存区域
    assert(vma != NULL);

    insert_vma_struct(mm, vma); // 将虚拟内存区域插入内存管理结构

    // 设置临时页表，用于虚拟地址0~4MB
    cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
    pte_t *temp_ptep = NULL;
    temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1); // 获取页表条目
    assert(temp_ptep != NULL); // 确保页表条目获取成功
    cprintf("setup Page Table vaddr 0~4MB OVER!\n");
     
    for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
        check_rp[i] = alloc_page(); // 分配检查用的物理页面
        assert(check_rp[i] != NULL);
        assert(!PageProperty(check_rp[i])); // 确保页面属性正确
    }
    list_entry_t free_list_store = free_list; // 备份当前的空闲页面链表
    list_init(&free_list); // 初始化一个新的空闲页面链表
    assert(list_empty(&free_list)); // 确保新的空闲页面链表为空
     
     unsigned int nr_free_store = nr_free; // 备份当前的空闲页面数量
     nr_free = 0; // 设置当前的空闲页面数量为0
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
        free_pages(check_rp[i], 1); // 将检查用的物理页面标记为空闲
     }
     assert(nr_free == CHECK_VALID_PHY_PAGE_NUM); // 确保空闲页面数量正确
     
     cprintf("set up init env for check_swap begin!\n");
     // 设置初始的虚拟页面<->物理页面环境，用于页面替换算法的测试

     pgfault_num = 0; // 页面错误次数置0
     
     check_content_set(); // 设置页面内容，触发页面错误
     assert(nr_free == 0); // 确保没有空闲页面
         
     for(i = 0; i < MAX_SEQ_NO; i++) // 初始化交换进出序列编号数组
         swap_out_seq_no[i] = swap_in_seq_no[i] = -1;
     
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
         check_ptep[i] = 0;
         check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0); // 获取页表条目
         assert(check_ptep[i] != NULL); // 确保页表条目获取成功
         assert(pte2page(*check_ptep[i]) == check_rp[i]); // 确保页表条目指向正确的物理页面
         assert((*check_ptep[i] & PTE_V)); // 确保页表条目有效          
     }
     cprintf("set up init env for check_swap over!\n");
     // 现在访问虚拟页面，测试页面替换算法
     ret = check_content_access(); // 访问内容并检查页面替换
     assert(ret == 0); // 确保页面替换检查成功
     
     // 恢复内核内存环境
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
         free_pages(check_rp[i], 1); // 将检查用的物理页面标记为空闲
     } 

     // free_page(pte2page(*temp_ptep)); // 释放临时分配的页面（如果有必要）

     mm_destroy(mm); // 销毁内存管理结构
         
     nr_free = nr_free_store; // 恢复之前的空闲页面数量
     free_list = free_list_store; // 恢复之前的空闲页面链表

     le = &free_list; // 重新初始化le为空闲页面链表的头部
     while ((le = list_next(le)) != &free_list) {
         struct Page *p = le2page(le, page_link);
         count--, total -= p->property; // 更新计数和总页数
     }
     cprintf("count is %d, total is %d\n", count, total); // 打印最终的计数和总页数
     // assert(count == 0); // 确保所有页面都被正确释放
     
     cprintf("check_swap() succeeded!\n"); // 打印检查成功的消息
}

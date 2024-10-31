#include <defs.h>
#include <riscv.h>
#include <stdio.h>
#include <string.h>
#include <swap.h>
#include <swap_fifo.h>
#include <list.h>

/* [维基百科] 最简单的页面替换算法（PRA）是先进先出（FIFO）算法。先进先出页面替换算法是一种低开销算法，它要求操作系统进行很少的记录工作。
从名字就可以看出这个想法——操作系统会跟踪所有内存中的页面，并将其按照时间顺序排列在一个队列中，最新的页面在队列的末尾，最早的页面在队列的前面。
当需要替换页面时，会选择队列最前面的页面（最旧的页面）。虽然FIFO算法成本低且直观，但在实际应用中表现不佳。因此，它很少以未修改的形式使用。
这个算法经历了Belady异常。

FIFO PRA的详细信息
(1) 准备：为了实现FIFO PRA，我们应该管理所有的可交换页面，以便我们可以将这些页面根据时间顺序链接到pra_list_head。
首先，你应该熟悉list.h中的struct list。struct list是一个简单的双向链表实现。你应该知道如何使用：
list_init, list_add(list_add_after), list_add_before, list_del, list_next, list_prev。
另一个技巧是将一个通用的链表结构转换为一个特殊的结构（例如struct page）。你可以在memlayout.h中找到一些宏：
le2page，（在未来的实验中：le2vma (in vmm.h), le2proc (in proc.h)等。
 */

list_entry_t pra_list_head;
/*
  * (2)_fifo_init_mm：初始化pra_list_head并让mm->sm_priv指向pra_list_head的地址。
  *              现在，从内存控制结构mm_struct，我们可以访问FIFO PRA
  */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head); // 初始化页面链表头
     mm->sm_priv = &pra_list_head; // 将mm结构的sm_priv指向链表头，以便后续操作
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
/*
  * (3)_fifo_map_swappable：根据FIFO PRA，我们应该将最近到达的页面链接在pra_list_head队列的末尾
  */
static int
_fifo_map_swappable(struct mm_struct *mm, uintptr_t addr, struct Page *page, int swap_in)
{
    list_entry_t *head=(list_entry_t*) mm->sm_priv; // 获取链表头
    list_entry_t *entry=&(page->pra_page_link); // 获取页面的链表项
  
    assert(entry != NULL && head != NULL);
    //记录页面访问情况

    //(1)将最近到达的页面链接在pra_list_head队列的末尾。
    list_add(head, entry); // 将新页面添加到链表尾部
    return 0;
}
/*
  * (4)_fifo_swap_out_victim：根据FIFO PRA，我们应该从pra_list_head队列的前面解链最早的页面，
  *                            然后设置这个页面的地址到ptr_page。
  */
static int
_fifo_swap_out_victim(struct mm_struct *mm, struct Page ** ptr_page, int in_tick)
{
     list_entry_t *head=(list_entry_t*) mm->sm_priv; // 获取链表头
         assert(head != NULL);
     assert(in_tick==0);
     /* 选择受害者 */
     //(1) 从pra_list_head队列的前面解链最早的页面
     //(2) 将这个页面的地址设置到ptr_page
    list_entry_t* entry = list_prev(head); // 获取链表头部的前一个元素，即最早进入的页面
    if (entry != head) {
        list_del(entry); // 从链表中删除该页面
        *ptr_page = le2page(entry, pra_page_link); // 将页面地址设置到ptr_page
    } else {
        *ptr_page = NULL; // 如果链表为空，则设置ptr_page为NULL
    }
    return 0;
}

static int
_fifo_check_swap(void) {
    cprintf("在fifo_check_swap中写入虚拟页面c\n");
    *(unsigned char *)0x3000 = 0x0c; // 写入虚拟页面c
    assert(pgfault_num==4); // 断言页面错误次数为4
    cprintf("在fifo_check_swap中写入虚拟页面a\n");
    *(unsigned char *)0x1000 = 0x0a; // 写入虚拟页面a
    assert(pgfault_num==4); // 断言页面错误次数为4
    cprintf("在fifo_check_swap中写入虚拟页面d\n");
    *(unsigned char *)0x4000 = 0x0d; // 写入虚拟页面d
    assert(pgfault_num==4); // 断言页面错误次数为4
    cprintf("在fifo_check_swap中写入虚拟页面b\n");
    *(unsigned char *)0x2000 = 0x0b; // 写入虚拟页面b
    assert(pgfault_num==4); // 断言页面错误次数为4
    cprintf("在fifo_check_swap中写入虚拟页面e\n");
    *(unsigned char *)0x5000 = 0x0e; // 写入虚拟页面e
    assert(pgfault_num==5); // 断言页面错误次数为5
    cprintf("在fifo_check_swap中再次写入虚拟页面b\n");
    *(unsigned char *)0x2000 = 0x0b; // 再次写入虚拟页面b
    assert(pgfault_num==5); // 断言页面错误次数为5
    cprintf("在fifo_check_swap中再次写入虚拟页面a\n");
    *(unsigned char *)0x1000 = 0x0a; // 再次写入虚拟页面a
    assert(pgfault_num==6); // 断言页面错误次数为6
    cprintf("在fifo_check_swap中再次写入虚拟页面b\n");
    *(unsigned char *)0x2000 = 0x0b; // 再次写入虚拟页面b
    assert(pgfault_num==7); // 断言页面错误次数为7
    cprintf("在fifo_check_swap中再次写入虚拟页面c\n");
    *(unsigned char *)0x3000 = 0x0c; // 再次写入虚拟页面c
    assert(pgfault_num==8); // 断言页面错误次数为8
    cprintf("在fifo_check_swap中再次写入虚拟页面d\n");
    *(unsigned char *)0x4000 = 0x0d; // 再次写入虚拟页面d
    assert(pgfault_num==9); // 断言页面错误次数为9
    cprintf("在fifo_check_swap中再次写入虚拟页面e\n");
    *(unsigned char *)0x5000 = 0x0e; // 再次写入虚拟页面e
    assert(pgfault_num==10); // 断言页面错误次数为10
    cprintf("在fifo_check_swap中再次写入虚拟页面a\n");
    assert(*(unsigned char *)0x1000 == 0x0a); // 断言虚拟页面a的值为0x0a
    *(unsigned char *)0x1000 = 0x0a; // 再次写入虚拟页面a
    assert(pgfault_num==11); // 断言页面错误次数为11
    return 0;
}


static int
_fifo_init(void)
{
    return 0;
}

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }


struct swap_manager swap_manager_fifo =
{
     .name            = "fifo swap manager", // FIFO页面替换管理器名称
     .init            = &_fifo_init, // 初始化函数
     .init_mm         = &_fifo_init_mm, // 初始化mm结构函数
     .tick_event      = &_fifo_tick_event, // 时钟事件处理函数
     .map_swappable   = &_fifo_map_swappable, // 映射可交换页面函数
     .set_unswappable = &_fifo_set_unswappable, // 设置不可交换页面函数
     .swap_out_victim = &_fifo_swap_out_victim, // 选择并交换出受害者页面函数
     .check_swap      = &_fifo_check_swap, // 检查页面替换函数
};
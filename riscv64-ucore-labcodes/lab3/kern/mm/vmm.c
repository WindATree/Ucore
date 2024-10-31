#include <vmm.h>
#include <sync.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <error.h>
#include <pmm.h>
#include <riscv.h>
#include <swap.h>

/*
  虚拟内存管理（VMM）设计包括两个部分：mm_struct（mm）和vma_struct（vma）
  mm 是一组具有相同页目录表（PDT）的连续虚拟内存区域的内存管理器。
  vma 是一个连续的虚拟内存区域。
  在 mm 中，vma 有一个线性链表和一个红黑树链表。
-----------------
  与 mm 相关的函数：
  全局函数
    struct mm_struct * mm_create(void)
    void mm_destroy(struct mm_struct *mm)
    int do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr)
-----------------
  与 vma 相关的函数：
  全局函数
    struct vma_struct * vma_create (uintptr_t vm_start, uintptr_t vm_end, ...)
    void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
    struct vma_struct * find_vma(struct mm_struct *mm, uintptr_t addr)
  局部函数
    inline void check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
-----------------
  检查正确性的函数
    void check_vmm(void);
    void check_vma_struct(void);
    void check_pgfault(void);
*/

// szx 函数：print_vma 和 print_mm
void print_vma(char *name, struct vma_struct *vma){
    cprintf("-- %s print_vma --\n", name);
    cprintf("   mm_struct: %p\n",vma->vm_mm);
    cprintf("   vm_start,vm_end: %x,%x\n",vma->vm_start,vma->vm_end);
    cprintf("   vm_flags: %x\n",vma->vm_flags);
    cprintf("   list_entry_t: %p\n",&vma->list_link);
}

void print_mm(char *name, struct mm_struct *mm){
    cprintf("-- %s print_mm --\n",name);
    cprintf("   mmap_list: %p\n",&mm->mmap_list);
    cprintf("   map_count: %d\n",mm->map_count);
    list_entry_t *list = &mm->mmap_list;
    for(int i=0;i<mm->map_count;i++){
        list = list_next(list);
        print_vma(name, le2vma(list,list_link));
    }
}

static void check_vmm(void);
static void check_vma_struct(void);
static void check_pgfault(void);

// mm_create - 分配一个 mm_struct 并初始化它。
struct mm_struct *
mm_create(void) {
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));

    if (mm != NULL) {
        list_init(&(mm->mmap_list)); // 初始化线性链表
        mm->mmap_cache = NULL; // 初始化缓存指针
        mm->pgdir = NULL; // 初始化页目录指针
        mm->map_count = 0; // 初始化映射计数器

        if (swap_init_ok) swap_init_mm(mm); // 如果启用了交换空间，则初始化 mm 的交换空间
        else mm->sm_priv = NULL; // 否则设置私有数据指针为 NULL
    }
    return mm;
}

// vma_create - 分配一个 vma_struct 并初始化它。（地址范围：vm_start~vm_end）
struct vma_struct *
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));

    if (vma != NULL) {
        vma->vm_start = vm_start; // 设置起始地址
        vma->vm_end = vm_end; // 设置结束地址
        vma->vm_flags = vm_flags; // 设置标志
    }
    return vma;
}


// find_vma - 查找一个 vma（vma->vm_start <= addr <= vma_vm_end）
struct vma_struct *
find_vma(struct mm_struct *mm, uintptr_t addr) {
    struct vma_struct *vma = NULL;
    if (mm != NULL) {
        vma = mm->mmap_cache; // 获取缓存的 vma
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) { // 如果缓存的 vma 不包含地址
                bool found = 0;
                list_entry_t *list = &(mm->mmap_list), *le = list;
                while ((le = list_next(le)) != list) { // 遍历线性链表
                    vma = le2vma(le, list_link);
                    if (vma->vm_start <= addr && addr < vma->vm_end) { // 如果找到包含地址的 vma
                        found = 1;
                        break;
                    }
                }
                if (!found) {
                    vma = NULL; // 如果没有找到，返回 NULL
                }
        }
        if (vma != NULL) {
            mm->mmap_cache = vma; // 更新缓存的 vma
        }
    }
    return vma;
}


// check_vma_overlap - 检查 vma1 是否与 vma2 重叠？
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
    assert(prev->vm_start < prev->vm_end); // 断言 prev 的起始地址小于结束地址
    assert(prev->vm_end <= next->vm_start); // 断言 prev 的结束地址小于等于 next 的起始地址
    assert(next->vm_start < next->vm_end); // 断言 next 的起始地址小于结束地址
}


// insert_vma_struct - 在 mm 的列表链接中插入 vma
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    // 确保 vma 的起始地址小于结束地址
    assert(vma->vm_start < vma->vm_end);
    
    // 获取 mm 的映射列表的头节点
    list_entry_t *list = &(mm->mmap_list);
    // 初始化 le_prev 为头节点，用于追踪当前遍历到的节点的前一个节点
    list_entry_t *le_prev = list, *le_next;
    
    // 遍历 mm 的映射列表，找到应该插入 vma 的位置
    list_entry_t *le = list;
    while ((le = list_next(le)) != list) {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        // 如果当前遍历到的 vma 的起始地址大于要插入的 vma 的起始地址，则停止遍历
        if (mmap_prev->vm_start > vma->vm_start) {
            break;
        }
        le_prev = le; // 更新前一个节点
    }
    
    // 获取 le_prev 的下一个节点，即插入位置的后一个节点
    le_next = list_next(le_prev);
    
    // 检查重叠
    // 如果前一个节点不是头节点，检查与前一个 vma 是否重叠
    if (le_prev != list) {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
    }
    // 如果后一个节点不是头节点，检查与后一个 vma 是否重叠
    if (le_next != list) {
        check_vma_overlap(vma, le2vma(le_next, list_link));
    }
    
    // 设置 vma 的 mm 指针，表示 vma 属于这个 mm
    vma->vm_mm = mm;
    // 在 le_prev 之后插入 vma
    list_add_after(le_prev, &(vma->list_link));
    
    // 更新 mm 中的映射计数器
    mm->map_count ++;
}

// mm_destroy - 释放 mm 及其内部字段
void
mm_destroy(struct mm_struct *mm) {
    // 获取 mm 的映射列表的头节点
    list_entry_t *list = &(mm->mmap_list), *le;
    // 遍历映射列表，释放每一个 vma
    while ((le = list_next(list)) != list) {
        list_del(le); // 从列表中删除当前节点
        // 释放 vma 所占用的内存
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  
    }
    // 释放 mm 所占用的内存
    kfree(mm, sizeof(struct mm_struct)); 
    // 将 mm 设置为 NULL，防止产生野指针
    mm=NULL;
}

// vmm_init - 初始化虚拟内存管理
//          - 目前只是调用 check_vmm 来检查 vmm 的正确性
void
vmm_init(void) {
    check_vmm();
}

// check_vmm - 检查 vmm 的正确性
static void
check_vmm(void) {
    // 存储当前的空闲页面数
    size_t nr_free_pages_store = nr_free_pages();
    // 检查 vma 结构的正确性
    check_vma_struct();
    // 检查缺页处理的正确性
    check_pgfault();

    // Szx: Sv39 三级页表多占用一个内存页，因此执行此操作
    nr_free_pages_store--;	
    // 断言空闲页面数没有变化，确保上面的操作没有影响内存分配
    assert(nr_free_pages_store == nr_free_pages());

    // 打印检查成功的消息
    cprintf("check_vmm() succeeded.\n");
}

static void
check_vma_struct(void) {
    // 存储当前的空闲页面数
    size_t nr_free_pages_store = nr_free_pages();

    // 创建一个新的 mm 结构体实例
    struct mm_struct *mm = mm_create();
    // 断言 mm 创建成功
    assert(mm != NULL);

    // 定义步长，用于创建测试用的 vma
    int step1 = 10, step2 = step1 * 10;

    int i;
    // 从后向前创建并插入 vma
    for (i = step1; i >= 1; i --) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        // 断言 vma 创建成功
        assert(vma != NULL);
        // 将 vma 插入到 mm 的映射列表中
        insert_vma_struct(mm, vma);
    }

    // 从前向后创建并插入 vma
    for (i = step1 + 1; i <= step2; i ++) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        // 断言 vma 创建成功
        assert(vma != NULL);
        // 将 vma 插入到 mm 的映射列表中
        insert_vma_struct(mm, vma);
    }

    // 遍历 mm 的映射列表，检查 vma 的顺序和属性
    list_entry_t *le = list_next(&(mm->mmap_list));
    for (i = 1; i <= step2; i ++) {
        // 断言当前节点不是头节点
        assert(le != &(mm->mmap_list));
        struct vma_struct *mmap = le2vma(le, list_link);
        // 断言 vma 的起始地址和结束地址正确
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
        le = list_next(le);
    }

    // 检查 find_vma 函数的正确性
    for (i = 5; i <= 5 * step2; i +=5) {
        struct vma_struct *vma1 = find_vma(mm, i);
        assert(vma1 != NULL);
        struct vma_struct *vma2 = find_vma(mm, i+1);
        assert(vma2 != NULL);
        struct vma_struct *vma3 = find_vma(mm, i+2);
        assert(vma3 == NULL);
        struct vma_struct *vma4 = find_vma(mm, i+3);
        assert(vma4 == NULL);
        struct vma_struct *vma5 = find_vma(mm, i+4);
        assert(vma5 == NULL);

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
    }

    // 检查 find_vma 函数在边界情况下的正确性
    for (i =4; i>=0; i--) {
        struct vma_struct *vma_below_5= find_vma(mm,i);
        if (vma_below_5 != NULL ) {
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
        }
        assert(vma_below_5 == NULL);
    }

    // 释放 mm 及其所有 vma
    mm_destroy(mm);

    // 断言空闲页面数没有变化，确保上面的操作没有影响内存分配
    assert(nr_free_pages_store == nr_free_pages());

    // 打印检查成功的消息
    cprintf("check_vma_struct() succeeded!\n");
}

struct mm_struct *check_mm_struct;

// check_pgfault - 检查缺页处理程序的正确性
static void
check_pgfault(void) {
    // 存储当前的空闲页面数
    size_t nr_free_pages_store = nr_free_pages();

    // 创建一个新的内存管理结构体实例
    check_mm_struct = mm_create();
    // 断言内存管理结构体创建成功
    assert(check_mm_struct != NULL);
    struct mm_struct *mm = check_mm_struct;
    // 为 mm 分配页目录，并将其设置为启动时的页目录
    pde_t *pgdir = mm->pgdir = boot_pgdir;
    // 断言页目录的第一个条目是空的
    assert(pgdir[0] == 0);

    // 创建一个新的虚拟内存区域结构体实例，表示从地址0开始的4KB内存区域，具有写权限
    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    // 断言虚拟内存区域结构体创建成功
    assert(vma != NULL);

    // 将虚拟内存区域结构体插入到内存管理结构体的映射列表中
    insert_vma_struct(mm, vma);

    // 定义一个测试地址
    uintptr_t addr = 0x100;
    // 断言找到的虚拟内存区域是预期的区域
    assert(find_vma(mm, addr) == vma);

    // 测试写入和读取内存
    int i, sum = 0;
    for (i = 0; i < 100; i ++) {
        *(char *)(addr + i) = i;
        sum += i;
    }
    for (i = 0; i < 100; i ++) {
        sum -= *(char *)(addr + i);
    }
    // 断言读取和写入操作是正确的
    assert(sum == 0);

    // 从页目录中移除页面
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));

    // 释放页目录中的第一个页表页面
    free_page(pde2page(pgdir[0]));

    // 将页目录的第一个条目设置为0
    pgdir[0] = 0;

    // 将内存管理结构体的页目录指针设置为NULL
    mm->pgdir = NULL;
    // 销毁内存管理结构体
    mm_destroy(mm);

    // 将检查用的内存管理结构体指针设置为NULL
    check_mm_struct = NULL;
    // Szx: Sv39第二级页表多占用了一个内存页，因此执行此操作
    nr_free_pages_store--;

    // 断言空闲页面数没有变化，确保上面的操作没有影响内存分配
    assert(nr_free_pages_store == nr_free_pages());

    // 打印检查成功的消息
    cprintf("check_pgfault() succeeded!\n");
}

// 缺页次数计数器
volatile unsigned int pgfault_num=0;

/*
 * do_pgfault - 处理缺页异常的核心函数
 * @mm         : 管理一组使用相同页目录表的 vma（虚拟内存区域）控制结构
 * @error_code : 错误码，记录在 trapframe->tf_err 中，标识页错误的原因
 * @addr       : 触发异常的线性地址（即 CR2 寄存器的内容）
 *
 * 处理过程：trap --> trap_dispatch --> pgfault_handler --> do_pgfault
 * do_pgfault 从处理器获得以下信息，用于诊断异常并尝试恢复：
 *   - CR2 寄存器的内容：记录异常的线性地址
 *   - 错误码：指出异常的具体原因，包括页面不存在、访问权限错误等。
 * 
 * 错误码的格式：
 *   - P 位（位 0）：表示页面不在（0）或访问权限错误（1）
 *   - W/R 位（位 1）：标识引发异常的内存访问是读取（0）还是写入（1）
 *   - U/S 位（位 2）：标识异常发生时是否在用户模式（1）或 supervisor 模式（0）
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
    int ret = -E_INVAL;
    // 尝试找到一个包含 addr 的 vma
    struct vma_struct *vma = find_vma(mm, addr);

    pgfault_num++;
    // 如果 addr 在 mm 的某个 vma 范围内？
    if (vma == NULL || vma->vm_start > addr) {
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
        goto failed;
    }

    /*
     * 根据 vma 的标志，设置页表权限位 perm
     * 若 vma 可写，则权限包含 PTE_W；否则仅包含 PTE_R 和 PTE_U
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
        perm |= (PTE_R | PTE_W);
    }
    addr = ROUNDDOWN(addr, PGSIZE);// 将 addr 对齐到页边界

    ret = -E_NO_MEM; // 若内存不足时返回该错误

    pte_t *ptep=NULL;
    /*
    * 一些有用的宏和定义，你可以在下面的实现中使用它们。
    * 宏或函数：
    *   get_pte : 获取一个 pte 并返回这个 pte 的内核虚拟地址，对于 la,
    *             如果包含这个 pte 的 PT 不存在，则分配一个页面给 PT（注意第三个参数 '1'）
    *   pgdir_alloc_page : 调用 alloc_page & page_insert 函数来分配页面大小的内存 & 设置
    *             一个 addr 映射 pa<--->la，其中线性地址 la 和 PDT pgdir
    * 定义：
    *   VM_WRITE  : 如果 vma->vm_flags & VM_WRITE 等于 1/0，则 vma 是可写/不可写
    *   PTE_W           0x002                   // 页表/目录项标志位：可写
    *   PTE_U           0x004                   // 页表/目录项标志位：用户可访问
    * 变量：
    *   mm->pgdir : 这些 vma 的 PDT
    */

    ptep = get_pte(mm->pgdir, addr, 1); //尝试找到一个 pte，如果 pte 的PT（页表）不存在，则创建一个 PT。
    if (*ptep == 0) {// 如果 pte 尚未映射任何页面
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) { // 分配新页面并映射
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            goto failed;
        }
    } else {
        /* LAB3 EXERCISE 3: YOUR CODE  2213050
        * 请你根据以下信息提示，补充函数
        * 现在我们认为 pte 是一个交换条目，那我们应该从磁盘加载数据并放到带有 phy addr 的页面，
        * 并将 phy addr 与逻辑 addr 映射，触发交换管理器记录该页面的访问情况
        * 宏或函数：
        *    swap_in(mm, addr, &page) : 分配一个内存页，从PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个 Page 的 phy addr 与线性 addr la 的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
            struct Page *page = NULL;
            // 你要编写的内容在这里
            // (1) 根据 mm 和 addr，尝试加载磁盘页的内容到由 page 管理的内存中。
            swap_in(mm,addr,&page);//调用swap_in函数从磁盘上读取数据
            // (2) 根据 mm，addr 和 page，设置物理地址 phy addr 与逻辑地址的映射
            // (3) 使页面可交换。交换成功，则建立物理地址<--->虚拟地址映射，并将页设置为可交换的
            page_insert(mm->pgdir, page, addr, perm);
            swap_map_swappable(mm, addr, page, 1);//将物理页设置为可交换状态
            page->pra_vaddr = addr;
        } else {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
    }
    ret = 0;
failed:
    return ret;
}


#include <vmm.h>
#include <sync.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <error.h>
#include <pmm.h>
#include <riscv.h>
#include <swap.h>
#include <kmalloc.h>
#include <cow.h>

/*  
  vmm design include two parts: mm_struct (mm) & vma_struct (vma)
  mm is the memory manager for the set of continuous virtual memory  
  area which have the same PDT. vma is a continuous virtual memory area.
  There a linear link list for vma & a redblack link list for vma in mm.
---------------
  mm related functions:
   golbal functions
     struct mm_struct * mm_create(void)
     void mm_destroy(struct mm_struct *mm)
     int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
--------------
  vma related functions:
   global functions
     struct vma_struct * vma_create (uintptr_t vm_start, uintptr_t vm_end,...)
     void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
     struct vma_struct * find_vma(struct mm_struct *mm, uintptr_t addr)
   local functions
     inline void check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
---------------
   check correctness functions
     void check_vmm(void);
     void check_vma_struct(void);
     void check_pgfault(void);
*/

static void check_vmm(void);
static void check_vma_struct(void);
static void check_pgfault(void);

// mm_create -  alloc a mm_struct & initialize it.
struct mm_struct *
mm_create(void) {
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));

    if (mm != NULL) {
        list_init(&(mm->mmap_list));
        mm->mmap_cache = NULL;
        mm->pgdir = NULL;
        mm->map_count = 0;

        if (swap_init_ok) swap_init_mm(mm);
        else mm->sm_priv = NULL;
        
        set_mm_count(mm, 0);
        lock_init(&(mm->mm_lock));
    }    
    return mm;
}

// vma_create - alloc a vma_struct & initialize it. (addr range: vm_start~vm_end)
struct vma_struct *
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));

    if (vma != NULL) {
        vma->vm_start = vm_start;
        vma->vm_end = vm_end;
        vma->vm_flags = vm_flags;
    }
    return vma;
}


// find_vma - find a vma  (vma->vm_start <= addr <= vma_vm_end)
struct vma_struct *
find_vma(struct mm_struct *mm, uintptr_t addr) {
    struct vma_struct *vma = NULL;
    if (mm != NULL) {
        vma = mm->mmap_cache;
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
                bool found = 0;
                list_entry_t *list = &(mm->mmap_list), *le = list;
                while ((le = list_next(le)) != list) {
                    vma = le2vma(le, list_link);
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
                        found = 1;
                        break;
                    }
                }
                if (!found) {
                    vma = NULL;
                }
        }
        if (vma != NULL) {
            mm->mmap_cache = vma;
        }
    }
    return vma;
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
}


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
    list_entry_t *list = &(mm->mmap_list);
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
                break;
            }
            le_prev = le;
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
    }
    if (le_next != list) {
        check_vma_overlap(vma, le2vma(le_next, list_link));
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
}

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
    assert(mm_count(mm) == 0);

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
    }
    kfree(mm); //kfree mm
    mm=NULL;
}

/* 
 * mm_map - 将一段虚拟内存区间映射到进程的地址空间
 * 
 * 功能：将指定的内存区间映射到进程的虚拟地址空间中，创建相应的虚拟内存区域（VMA）。
 * 参数：
 *   mm         - 进程的内存描述符 (mm_struct)
 *   addr       - 要映射的内存起始地址
 *   len        - 要映射的内存长度
 *   vm_flags   - 映射区的权限标志
 *   vma_store  - 如果非空，存储新创建的虚拟内存区域
 * 返回值：
 *   - 成功时返回 0
 *   - 如果地址无效或无法创建 VMA，返回 -E_INVAL 或 -E_NO_MEM
 */
int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store) {
    // 将地址对齐到页边界
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);

    // 检查是否在用户空间地址范围内
    if (!USER_ACCESS(start, end)) {
        return -E_INVAL;  // 无效的用户地址范围
    }

    assert(mm != NULL);  // 确保 mm 指针非空

    int ret = -E_INVAL;

    struct vma_struct *vma;
    // 查找起始地址所在的虚拟内存区域，如果找不到或区域无效，跳转到 out
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start) {
        goto out;
    }
    ret = -E_NO_MEM;

    // 创建新的虚拟内存区域 (VMA)，如果失败返回错误
    if ((vma = vma_create(start, end, vm_flags)) == NULL) {
        goto out;
    }

    // 将新的虚拟内存区域插入到进程的内存映射列表中
    insert_vma_struct(mm, vma);

    // 如果传入 vma_store 指针，存储新创建的 VMA
    if (vma_store != NULL) {
        *vma_store = vma;
    }

    ret = 0;  // 成功

out:
    return ret;  // 返回结果
}

/* 
 * dup_mmap - 复制进程的内存映射
 * 
 * 功能：复制源进程（from）的内存映射到目标进程（to）。
 * 参数：
 *   to   - 目标进程的内存描述符
 *   from - 源进程的内存描述符
 * 返回值：
 *   - 成功时返回 0
 *   - 如果内存分配失败或复制失败，返回 -E_NO_MEM
 */
int dup_mmap(struct mm_struct *to, struct mm_struct *from) {
    assert(to != NULL && from != NULL);  // 确保目标和源进程非空

    list_entry_t *list = &(from->mmap_list), *le = list;
    while ((le = list_prev(le)) != list) {  // 遍历源进程的内存映射列表
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);  // 获取当前 VMA
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);  // 创建新的 VMA

        if (nvma == NULL) {
            return -E_NO_MEM;  // 创建 VMA 失败，返回错误
        }

        insert_vma_struct(to, nvma);  // 将新的 VMA 插入到目标进程的内存映射列表中

        bool share = 0;  // 共享标志
        // 复制页表范围内的数据，注意是否为共享内存
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0) {
            return -E_NO_MEM;  // 复制内存失败
        }
    }

    return 0;  // 成功
}

/* 
 * exit_mmap - 释放进程的内存映射
 * 
 * 功能：当进程退出时，释放所有的虚拟内存区域。
 * 参数：
 *   mm - 进程的内存描述符 (mm_struct)
 */
void exit_mmap(struct mm_struct *mm) {
    assert(mm != NULL && mm_count(mm) == 0);  // 确保进程内存描述符非空，且进程内存计数为 0

    pde_t *pgdir = mm->pgdir;
    list_entry_t *list = &(mm->mmap_list), *le = list;

    // 遍历并解除映射所有的虚拟内存区域
    while ((le = list_next(le)) != list) {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);  // 解除虚拟地址区间的映射
    }

    // 清理并释放资源
    while ((le = list_next(le)) != list) {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);  // 退出并释放内存区域
    }
}

/* 
 * copy_from_user - 从用户空间复制数据到内核空间
 * 
 * 功能：将数据从用户空间复制到内核空间的指定地址。
 * 参数：
 *   mm        - 当前进程的内存描述符
 *   dst       - 目标内核空间地址
 *   src       - 源用户空间地址
 *   len       - 复制的字节数
 *   writable  - 源内存是否可写
 * 返回值：
 *   - 如果内存访问检查通过，返回 1
 *   - 如果检查失败，返回 0
 */
bool copy_from_user(struct mm_struct *mm, void *dst, const void *src, size_t len, bool writable) {
    if (!user_mem_check(mm, (uintptr_t)src, len, writable)) {
        return 0;  // 用户内存访问检查失败，返回 0
    }
    memcpy(dst, src, len);  // 从用户空间复制数据
    return 1;  // 成功
}

/* 
 * copy_to_user - 从内核空间复制数据到用户空间
 * 
 * 功能：将数据从内核空间复制到用户空间的指定地址。
 * 参数：
 *   mm        - 当前进程的内存描述符
 *   dst       - 目标用户空间地址
 *   src       - 源内核空间地址
 *   len       - 复制的字节数
 * 返回值：
 *   - 如果内存访问检查通过，返回 1
 *   - 如果检查失败，返回 0
 */
bool copy_to_user(struct mm_struct *mm, void *dst, const void *src, size_t len) {
    if (!user_mem_check(mm, (uintptr_t)dst, len, 1)) {
        return 0;  // 用户内存访问检查失败，返回 0
    }
    memcpy(dst, src, len);  // 从内核空间复制数据
    return 1;  // 成功
}


// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
    check_vmm();
}

// check_vmm - check correctness of vmm
static void
check_vmm(void) {
    // size_t nr_free_pages_store = nr_free_pages();
    
    check_vma_struct();
    check_pgfault();

    cprintf("check_vmm() succeeded.\n");
}

static void
check_vma_struct(void) {
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    for (i = step1 + 1; i <= step2; i ++) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
        assert(le != &(mm->mmap_list));
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
        le = list_next(le);
    }

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

    for (i =4; i>=0; i--) {
        struct vma_struct *vma_below_5= find_vma(mm,i);
        if (vma_below_5 != NULL ) {
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
}

struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();

    check_mm_struct = mm_create();
    assert(check_mm_struct != NULL);

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
    assert(pgdir[0] == 0);

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);

    int i, sum = 0;

    for (i = 0; i < 100; i ++) {
        *(char *)(addr + i) = i;
        sum += i;
    }
    for (i = 0; i < 100; i ++) {
        sum -= *(char *)(addr + i);
    }

    assert(sum == 0);

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    pgdir[0] = 0;
    flush_tlb();

    mm->pgdir = NULL;
    mm_destroy(mm);
    check_mm_struct = NULL;

    assert(nr_free_pages_store == nr_free_pages());

    cprintf("check_pgfault() succeeded!\n");
}
//page fault number
volatile unsigned int pgfault_num=0;

/* do_pgfault - interrupt handler to process the page fault execption
 * @mm         : the control struct for a set of vma using the same PDT
 * @error_code : the error code recorded in trapframe->tf_err which is setted by x86 hardware
 * @addr       : the addr which causes a memory access exception, (the contents of the CR2 register)
 *
 * CALL GRAPH: trap--> trap_dispatch-->pgfault_handler-->do_pgfault
 * The processor provides ucore's do_pgfault function with two items of information to aid in diagnosing
 * the exception and recovering from it.
 *   (1) The contents of the CR2 register. The processor loads the CR2 register with the
 *       32-bit linear address that generated the exception. The do_pgfault fun can
 *       use this address to locate the corresponding page directory and page-table
 *       entries.
 *   (2) An error code on the kernel stack. The error code for a page fault has a format different from
 *       that for other exceptions. The error code tells the exception handler three things:
 *         -- The P flag   (bit 0) indicates whether the exception was due to a not-present page (0)
 *            or to either an access rights violation or the use of a reserved bit (1).
 *         -- The W/R flag (bit 1) indicates whether the memory access that caused the exception
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);

    pgfault_num++;
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
        goto failed;
    }

    /* IF (write an existed addr ) OR
     *    (write an non_existed addr && addr is writable) OR
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
        perm |= READ_WRITE;
    }
    addr = ROUNDDOWN(addr, PGSIZE);

    ret = -E_NO_MEM;

    pte_t *ptep=NULL;
    
    // 判断页表项权限，如果有效但是不可写，跳转到COW
    // if ((ptep = get_pte(mm->pgdir, addr, 0)) != NULL) {
    //     if((*ptep & PTE_V) & ~(*ptep & PTE_W)) {
    //         return cow_pgfault(mm, error_code, addr);
    //     }
    // }


    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            goto failed;
        }
    } else {
        /*LAB3 EXERCISE 3: YOUR CODE
        * 请你根据以下信息提示，补充函数
        * 现在我们认为pte是一个交换条目，那我们应该从磁盘加载数据并放到带有phy addr的页面，
        * 并将phy addr与逻辑addr映射，触发交换管理器记录该页面的访问情况
        *
        *  一些有用的宏和定义，可能会对你接下来代码的编写产生帮助(显然是有帮助的)
        *  宏或函数:
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
            struct Page *page = NULL;
            // 你要编写的内容在这里，请基于上文说明以及下文的英文注释完成代码编写
            //(1）According to the mm AND addr, try
            //to load the content of right disk page
            //into the memory which page managed.
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
            // cprintf("do_pgfault called!!!\n");
            if((ret = swap_in(mm,addr,&page)) != 0) {
                goto failed;
            }
            page_insert(mm->pgdir,page,addr,perm);
            swap_map_swappable(mm,addr,page,1);
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

/* 
 * user_mem_check - 检查用户内存访问权限
 * 
 * 功能：该函数用于检查在用户空间中访问指定内存地址区间是否符合访问权限要求。
 * 参数：
 *   mm    - 当前进程的内存描述符 (mm_struct)，用于查找进程的虚拟内存区域 (VMA)
 *   addr  - 要访问的内存起始地址
 *   len   - 访问的内存长度
 *   write - 是否进行写操作的标志。若为 true，表示写操作；若为 false，表示读操作
 * 返回值：
 *   - 若用户空间访问的内存区域有效且权限允许，返回 1（允许访问）
 *   - 若用户空间访问的内存区域无效或权限不允许，返回 0（拒绝访问）
 *   - 若是内核空间地址，则调用 `KERN_ACCESS` 进行检查
 */
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write) {
    if (mm != NULL) {  // 如果是用户进程，检查用户空间内存访问
        // 检查指定地址范围是否在用户地址空间内
        if (!USER_ACCESS(addr, addr + len)) {
            return 0;  // 如果不在用户空间内，返回 0（拒绝访问）
        }
        struct vma_struct *vma;
        uintptr_t start = addr, end = addr + len;
        
        // 循环检查整个地址范围内的每一段虚拟内存区域
        while (start < end) {
            // 查找指定地址所在的虚拟内存区域 (vma)，若没有找到，或者起始地址小于 vma 的起始地址，拒绝访问
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start) {
                return 0;
            }
            
            // 检查该虚拟内存区域的访问权限是否允许访问（根据操作类型，读或写）
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
                return 0;  // 如果权限不匹配，返回 0（拒绝访问）
            }
            
            // 如果是写操作且是栈区域，检查是否越过栈的起始地址（栈的第一页禁止写）
            if (write && (vma->vm_flags & VM_STACK)) {
                if (start < vma->vm_start + PGSIZE) {  // 检查是否栈的开始部分，且大小为页面大小
                    return 0;  // 如果写操作超出栈的允许范围，返回 0（拒绝访问）
                }
            }
            
            // 更新起始地址为当前虚拟内存区域的结束地址，继续检查剩余区域
            start = vma->vm_end;
        }
        return 1;  // 如果所有检查通过，返回 1（允许访问）
    }

    // 如果是内核地址空间，使用内核空间访问权限检查
    return KERN_ACCESS(addr, addr + len);
}



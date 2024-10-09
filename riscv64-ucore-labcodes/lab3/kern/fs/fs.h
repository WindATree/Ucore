#ifndef __KERN_FS_FS_H__
#define __KERN_FS_FS_H__

#include <mmu.h>

#define SECTSIZE            512 // 定义扇区大小为512字节
#define PAGE_NSECT          (PGSIZE / SECTSIZE) // 定义每页包含的扇区数，PGSIZE通常为一页的大小

#define SWAP_DEV_NO         1 // 定义交换设备的设备号为1

#endif /* !__KERN_FS_FS_H__ */


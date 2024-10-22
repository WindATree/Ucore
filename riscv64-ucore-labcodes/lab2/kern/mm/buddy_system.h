#ifndef __KERN_MM_BUDDY_SYSTEM_H__
#define __KERN_MM_BUDDY_SYSTEM_H__
#include <pmm.h>

extern const struct pmm_manager buddy_system_pmm_manager;

typedef struct{
    uint32_t order;
    list_entry_t buddy_list[16];
    uint32_t nr_free;
}free_buddy_t;
extern const struct pmm_manager buddy_pmm_manager;
#endif
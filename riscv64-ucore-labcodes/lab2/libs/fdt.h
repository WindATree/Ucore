#ifndef __LIBS_FDT_H__
#define __LIBS_FDT_H__

#include <assert.h>
#include <defs.h>
#include <stdio.h>
#include <string.h>

/// 设备树头部结构体，按大端格式存储
/// 设备树包含几个部分：头部、保留内存块、结构块、字符串块等。
typedef struct {
    /// 魔数，固定为0xd00dfeed，用于标识设备树
    uint32_t magic;
    /// 设备树总大小，包括头部的总字节数
    uint32_t totalsize;
    /// 结构块的偏移量，从头部开始计算
    uint32_t off_dt_struct;
    /// 字符串块的偏移量，从头部开始计算
    uint32_t off_dt_strings;
    /// 保留内存块的偏移量，从头部开始计算
    uint32_t off_mem_rsvmap;
    /// 设备树版本
    uint32_t version;
    /// 设备树版本向后兼容的最小版本
    uint32_t last_comp_version;
    /// 启动CPU的物理ID
    uint32_t boot_cpuid_phys;
    /// 字符串块的大小，单位字节
    uint32_t size_dt_strings;
    /// 结构块的大小，单位字节
    uint32_t size_dt_struct;
} fdt_header_t;

/// 保留内存块的条目
/// 当地址和大小都为零时，意味着该保留内存块结束
typedef struct {
    /// 保留内存的物理地址
    uint64_t address;
    /// 保留内存的大小
    uint64_t size;
} fdt_reserve_entry_t;

/// 设备树结构标记，用于表示节点的开始
#define FDT_BEGIN_NODE 0x01000000

/// 设备树结构标记，用于表示节点的结束
#define FDT_END_NODE 0x02000000

/// 设备树属性的标记，表示属性的开始
#define FDT_PROP 0x03000000

/// 设备树属性的数据结构，存储属性值和名称偏移量
typedef struct {
    /// 属性值的长度，单位字节
    uint32_t len;
    /// 属性名称在字符串块中的偏移量
    uint32_t nameoff;
} fdt_prop_data_t;

/// 空操作标记，无额外数据
#define FDT_NOP 0x04000000

/// 结构块的结束标记
#define FDT_END 0x09000000

/// 字节序转换函数，将32位大端数据转换为小端
uint32_t switch_endian(uint32_t val) {
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
}

/// 打印缩进，用于美观输出设备树结构
void print_indent(size_t indent) {
    for (size_t i = 0; i < indent; i++) {
        cprintf("  ");
    }
}

/// 遍历并打印设备树结构
void walk_print_device_tree(fdt_header_t* fdt_header) {
    // 检查魔数，0xd00dfeed，确保字节序正确
    assert(switch_endian(fdt_header->magic) == 0xd00dfeed);

    // 计算设备树的结束地址
    uint64_t fdt_end_addr =
        (uint64_t)fdt_header + switch_endian(fdt_header->totalsize);
    // 计算结构块的起始地址
    uint64_t structure_block_addr =
        (uint64_t)fdt_header + switch_endian(fdt_header->off_dt_struct);
    // 计算字符串块的起始地址
    uint64_t strings_block_addr =
        (uint64_t)fdt_header + switch_endian(fdt_header->off_dt_strings);

    size_t node_depth = 0; // 用于记录当前节点的深度

    uint32_t* p = (uint32_t*)structure_block_addr; // 指向结构块的指针

    for (;;) {
        // 读取当前标记
        uint32_t marker = switch_endian(*p);

        switch (marker) {
            case FDT_NOP: { // 无操作标记，跳过
                p++;
                break;
            }
            case FDT_BEGIN_NODE: { // 开始节点标记
                p++;
                print_indent(node_depth); // 打印缩进
                node_depth++; // 节点深度增加

                // 打印节点名称，如果名称为空，表示根节点
                if (strlen((char*)p) == 0) {
                    cprintf("devicetree {\n");
                } else {
                    cprintf("%s {\n", (char*)p);
                }

                // 移动到下一个4字节对齐的位置
                p += (strlen((char*)p) + 4) / 4;
                break;
            }
            case FDT_END_NODE: { // 结束节点标记
                p++;
                node_depth--; // 节点深度减少
                print_indent(node_depth); // 打印缩进
                cprintf("}\n");
                break;
            }
            case FDT_PROP: { // 属性标记
                p++;
                // 获取属性数据
                fdt_prop_data_t* prop_data = (fdt_prop_data_t*)p;
                p += sizeof(fdt_prop_data_t) / sizeof(uint32_t); // 跳过属性数据头

                print_indent(node_depth); // 打印缩进

                // 通过字符串块中的偏移量获取属性名称
                const char* prop_name = (char*)(strings_block_addr + switch_endian(prop_data->nameoff));
                cprintf("%s: ", prop_name);

                // 打印属性值，按16进制打印
                uint8_t* prop_value = (uint8_t*)p;
                for (size_t i = 0; i < switch_endian(prop_data->len); i++) {
                    cprintf("%02x", prop_value[i]);
                    if (i % 4 == 3) cprintf(" ");
                }

                // 对齐到下一个4字节边界
                p += (switch_endian(prop_data->len) + 3) / 4;
                cprintf("\n");
                break;
            }
            case FDT_END: { // 结束标记，返回
                return;
            }
            default: { // 未知标记，输出错误信息
                cprintf("unknown marker: 0x%08x\n", marker);
                assert(0); // 触发断言，停止程序
                return;
            }
        }

        // 检查是否遍历完结构块或节点深度回到根节点
        if (node_depth == 0) return;

        // 检查是否超出设备树的结束地址
        if ((uint64_t)p >= fdt_end_addr) return;
    }
}

#endif /* __LIBS_FDT_H__ */

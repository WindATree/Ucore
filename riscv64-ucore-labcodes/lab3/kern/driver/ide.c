#include <assert.h> // 包含断言库，用于验证代码逻辑
#include <defs.h>   // 包含定义库，可能包含一些基本类型和宏定义
#include <fs.h>     // 文件系统相关的头文件
#include <ide.h>    // IDE接口相关的头文件
#include <stdio.h>  // 标准输入输出库
#include <string.h> // 字符串操作库
#include <trap.h>   // 陷阱处理库，可能包含异常和中断处理
#include <riscv.h>  // RISC-V架构相关的库

// 初始化IDE接口，当前为空实现
void ide_init(void) {}

// 定义最大IDE设备数量
#define MAX_IDE 2
// 定义每个磁盘的最大扇区数
#define MAX_DISK_NSECS 56
// 静态分配一个字符数组用于模拟磁盘存储
static char ide[MAX_DISK_NSECS * SECTSIZE];

// 验证IDE设备号是否有效
bool ide_device_valid(unsigned short ideno) {
    return ideno < MAX_IDE; // 如果设备号小于最大设备数，则有效
}

// 获取IDE设备的总扇区数
size_t ide_device_size(unsigned short ideno) {
    return MAX_DISK_NSECS; // 返回定义的最大扇区数
}

// 从IDE设备读取扇区
int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    //ideno: 假设挂载了多块磁盘，选择哪一块磁盘 这里我们其实只有一块“磁盘”，这个参数就没用到
    // 计算起始偏移量
    int iobase = secno * SECTSIZE;
    // 从模拟磁盘中复制数据到目标地址
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
    return 0; // 返回0表示成功
}

// 向IDE设备写入扇区
int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    // 计算起始偏移量
    int iobase = secno * SECTSIZE;
    // 从源地址复制数据到模拟磁盘
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
    return 0; // 返回0表示成功
}

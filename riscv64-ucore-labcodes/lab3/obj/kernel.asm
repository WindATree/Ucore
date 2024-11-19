
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02092b7          	lui	t0,0xc0209
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200024:	c0209137          	lui	sp,0xc0209

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:


int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	0000a517          	auipc	a0,0xa
ffffffffc0200036:	00e50513          	addi	a0,a0,14 # ffffffffc020a040 <ide>
ffffffffc020003a:	00011617          	auipc	a2,0x11
ffffffffc020003e:	52e60613          	addi	a2,a2,1326 # ffffffffc0211568 <end>
kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	777030ef          	jal	ra,ffffffffc0203fc0 <memset>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020004e:	00004597          	auipc	a1,0x4
ffffffffc0200052:	44258593          	addi	a1,a1,1090 # ffffffffc0204490 <etext+0x4>
ffffffffc0200056:	00004517          	auipc	a0,0x4
ffffffffc020005a:	45a50513          	addi	a0,a0,1114 # ffffffffc02044b0 <etext+0x24>
ffffffffc020005e:	05c000ef          	jal	ra,ffffffffc02000ba <cprintf>

    print_kerninfo();
ffffffffc0200062:	0fc000ef          	jal	ra,ffffffffc020015e <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc0200066:	741020ef          	jal	ra,ffffffffc0202fa6 <pmm_init>

    idt_init();                 // init interrupt descriptor table
ffffffffc020006a:	4fa000ef          	jal	ra,ffffffffc0200564 <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc020006e:	07c010ef          	jal	ra,ffffffffc02010ea <vmm_init>

    ide_init();                 // init ide devices
ffffffffc0200072:	35e000ef          	jal	ra,ffffffffc02003d0 <ide_init>
    swap_init();                // init swap
ffffffffc0200076:	71a010ef          	jal	ra,ffffffffc0201790 <swap_init>

    clock_init();               // init clock interrupt
ffffffffc020007a:	3ac000ef          	jal	ra,ffffffffc0200426 <clock_init>
    // intr_enable();              // enable irq interrupt



    /* do nothing */
    while (1);
ffffffffc020007e:	a001                	j	ffffffffc020007e <kern_init+0x4c>

ffffffffc0200080 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200080:	1141                	addi	sp,sp,-16
ffffffffc0200082:	e022                	sd	s0,0(sp)
ffffffffc0200084:	e406                	sd	ra,8(sp)
ffffffffc0200086:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200088:	3f0000ef          	jal	ra,ffffffffc0200478 <cons_putc>
    (*cnt) ++;
ffffffffc020008c:	401c                	lw	a5,0(s0)
}
ffffffffc020008e:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200090:	2785                	addiw	a5,a5,1
ffffffffc0200092:	c01c                	sw	a5,0(s0)
}
ffffffffc0200094:	6402                	ld	s0,0(sp)
ffffffffc0200096:	0141                	addi	sp,sp,16
ffffffffc0200098:	8082                	ret

ffffffffc020009a <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020009a:	1101                	addi	sp,sp,-32
ffffffffc020009c:	862a                	mv	a2,a0
ffffffffc020009e:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a0:	00000517          	auipc	a0,0x0
ffffffffc02000a4:	fe050513          	addi	a0,a0,-32 # ffffffffc0200080 <cputch>
ffffffffc02000a8:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000aa:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ac:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000ae:	7a9030ef          	jal	ra,ffffffffc0204056 <vprintfmt>
    return cnt;
}
ffffffffc02000b2:	60e2                	ld	ra,24(sp)
ffffffffc02000b4:	4532                	lw	a0,12(sp)
ffffffffc02000b6:	6105                	addi	sp,sp,32
ffffffffc02000b8:	8082                	ret

ffffffffc02000ba <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000ba:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000bc:	02810313          	addi	t1,sp,40 # ffffffffc0209028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000c0:	8e2a                	mv	t3,a0
ffffffffc02000c2:	f42e                	sd	a1,40(sp)
ffffffffc02000c4:	f832                	sd	a2,48(sp)
ffffffffc02000c6:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c8:	00000517          	auipc	a0,0x0
ffffffffc02000cc:	fb850513          	addi	a0,a0,-72 # ffffffffc0200080 <cputch>
ffffffffc02000d0:	004c                	addi	a1,sp,4
ffffffffc02000d2:	869a                	mv	a3,t1
ffffffffc02000d4:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000d6:	ec06                	sd	ra,24(sp)
ffffffffc02000d8:	e0ba                	sd	a4,64(sp)
ffffffffc02000da:	e4be                	sd	a5,72(sp)
ffffffffc02000dc:	e8c2                	sd	a6,80(sp)
ffffffffc02000de:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000e0:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000e2:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e4:	773030ef          	jal	ra,ffffffffc0204056 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e8:	60e2                	ld	ra,24(sp)
ffffffffc02000ea:	4512                	lw	a0,4(sp)
ffffffffc02000ec:	6125                	addi	sp,sp,96
ffffffffc02000ee:	8082                	ret

ffffffffc02000f0 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000f0:	a661                	j	ffffffffc0200478 <cons_putc>

ffffffffc02000f2 <getchar>:
    return cnt;
}

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc02000f2:	1141                	addi	sp,sp,-16
ffffffffc02000f4:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc02000f6:	3b6000ef          	jal	ra,ffffffffc02004ac <cons_getc>
ffffffffc02000fa:	dd75                	beqz	a0,ffffffffc02000f6 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc02000fc:	60a2                	ld	ra,8(sp)
ffffffffc02000fe:	0141                	addi	sp,sp,16
ffffffffc0200100:	8082                	ret

ffffffffc0200102 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200102:	00011317          	auipc	t1,0x11
ffffffffc0200106:	3f630313          	addi	t1,t1,1014 # ffffffffc02114f8 <is_panic>
ffffffffc020010a:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020010e:	715d                	addi	sp,sp,-80
ffffffffc0200110:	ec06                	sd	ra,24(sp)
ffffffffc0200112:	e822                	sd	s0,16(sp)
ffffffffc0200114:	f436                	sd	a3,40(sp)
ffffffffc0200116:	f83a                	sd	a4,48(sp)
ffffffffc0200118:	fc3e                	sd	a5,56(sp)
ffffffffc020011a:	e0c2                	sd	a6,64(sp)
ffffffffc020011c:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020011e:	020e1a63          	bnez	t3,ffffffffc0200152 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200122:	4785                	li	a5,1
ffffffffc0200124:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200128:	8432                	mv	s0,a2
ffffffffc020012a:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020012c:	862e                	mv	a2,a1
ffffffffc020012e:	85aa                	mv	a1,a0
ffffffffc0200130:	00004517          	auipc	a0,0x4
ffffffffc0200134:	38850513          	addi	a0,a0,904 # ffffffffc02044b8 <etext+0x2c>
    va_start(ap, fmt);
ffffffffc0200138:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020013a:	f81ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    vcprintf(fmt, ap);
ffffffffc020013e:	65a2                	ld	a1,8(sp)
ffffffffc0200140:	8522                	mv	a0,s0
ffffffffc0200142:	f59ff0ef          	jal	ra,ffffffffc020009a <vcprintf>
    cprintf("\n");
ffffffffc0200146:	00006517          	auipc	a0,0x6
ffffffffc020014a:	d4a50513          	addi	a0,a0,-694 # ffffffffc0205e90 <default_pmm_manager+0x400>
ffffffffc020014e:	f6dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200152:	39c000ef          	jal	ra,ffffffffc02004ee <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200156:	4501                	li	a0,0
ffffffffc0200158:	130000ef          	jal	ra,ffffffffc0200288 <kmonitor>
    while (1) {
ffffffffc020015c:	bfed                	j	ffffffffc0200156 <__panic+0x54>

ffffffffc020015e <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020015e:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200160:	00004517          	auipc	a0,0x4
ffffffffc0200164:	37850513          	addi	a0,a0,888 # ffffffffc02044d8 <etext+0x4c>
void print_kerninfo(void) {
ffffffffc0200168:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020016a:	f51ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020016e:	00000597          	auipc	a1,0x0
ffffffffc0200172:	ec458593          	addi	a1,a1,-316 # ffffffffc0200032 <kern_init>
ffffffffc0200176:	00004517          	auipc	a0,0x4
ffffffffc020017a:	38250513          	addi	a0,a0,898 # ffffffffc02044f8 <etext+0x6c>
ffffffffc020017e:	f3dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200182:	00004597          	auipc	a1,0x4
ffffffffc0200186:	30a58593          	addi	a1,a1,778 # ffffffffc020448c <etext>
ffffffffc020018a:	00004517          	auipc	a0,0x4
ffffffffc020018e:	38e50513          	addi	a0,a0,910 # ffffffffc0204518 <etext+0x8c>
ffffffffc0200192:	f29ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200196:	0000a597          	auipc	a1,0xa
ffffffffc020019a:	eaa58593          	addi	a1,a1,-342 # ffffffffc020a040 <ide>
ffffffffc020019e:	00004517          	auipc	a0,0x4
ffffffffc02001a2:	39a50513          	addi	a0,a0,922 # ffffffffc0204538 <etext+0xac>
ffffffffc02001a6:	f15ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc02001aa:	00011597          	auipc	a1,0x11
ffffffffc02001ae:	3be58593          	addi	a1,a1,958 # ffffffffc0211568 <end>
ffffffffc02001b2:	00004517          	auipc	a0,0x4
ffffffffc02001b6:	3a650513          	addi	a0,a0,934 # ffffffffc0204558 <etext+0xcc>
ffffffffc02001ba:	f01ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001be:	00011597          	auipc	a1,0x11
ffffffffc02001c2:	7a958593          	addi	a1,a1,1961 # ffffffffc0211967 <end+0x3ff>
ffffffffc02001c6:	00000797          	auipc	a5,0x0
ffffffffc02001ca:	e6c78793          	addi	a5,a5,-404 # ffffffffc0200032 <kern_init>
ffffffffc02001ce:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001d2:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001d6:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001d8:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001dc:	95be                	add	a1,a1,a5
ffffffffc02001de:	85a9                	srai	a1,a1,0xa
ffffffffc02001e0:	00004517          	auipc	a0,0x4
ffffffffc02001e4:	39850513          	addi	a0,a0,920 # ffffffffc0204578 <etext+0xec>
}
ffffffffc02001e8:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ea:	bdc1                	j	ffffffffc02000ba <cprintf>

ffffffffc02001ec <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001ec:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc02001ee:	00004617          	auipc	a2,0x4
ffffffffc02001f2:	3ba60613          	addi	a2,a2,954 # ffffffffc02045a8 <etext+0x11c>
ffffffffc02001f6:	04e00593          	li	a1,78
ffffffffc02001fa:	00004517          	auipc	a0,0x4
ffffffffc02001fe:	3c650513          	addi	a0,a0,966 # ffffffffc02045c0 <etext+0x134>
void print_stackframe(void) {
ffffffffc0200202:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200204:	effff0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0200208 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200208:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020020a:	00004617          	auipc	a2,0x4
ffffffffc020020e:	3ce60613          	addi	a2,a2,974 # ffffffffc02045d8 <etext+0x14c>
ffffffffc0200212:	00004597          	auipc	a1,0x4
ffffffffc0200216:	3e658593          	addi	a1,a1,998 # ffffffffc02045f8 <etext+0x16c>
ffffffffc020021a:	00004517          	auipc	a0,0x4
ffffffffc020021e:	3e650513          	addi	a0,a0,998 # ffffffffc0204600 <etext+0x174>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200222:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200224:	e97ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200228:	00004617          	auipc	a2,0x4
ffffffffc020022c:	3e860613          	addi	a2,a2,1000 # ffffffffc0204610 <etext+0x184>
ffffffffc0200230:	00004597          	auipc	a1,0x4
ffffffffc0200234:	40858593          	addi	a1,a1,1032 # ffffffffc0204638 <etext+0x1ac>
ffffffffc0200238:	00004517          	auipc	a0,0x4
ffffffffc020023c:	3c850513          	addi	a0,a0,968 # ffffffffc0204600 <etext+0x174>
ffffffffc0200240:	e7bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200244:	00004617          	auipc	a2,0x4
ffffffffc0200248:	40460613          	addi	a2,a2,1028 # ffffffffc0204648 <etext+0x1bc>
ffffffffc020024c:	00004597          	auipc	a1,0x4
ffffffffc0200250:	41c58593          	addi	a1,a1,1052 # ffffffffc0204668 <etext+0x1dc>
ffffffffc0200254:	00004517          	auipc	a0,0x4
ffffffffc0200258:	3ac50513          	addi	a0,a0,940 # ffffffffc0204600 <etext+0x174>
ffffffffc020025c:	e5fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    }
    return 0;
}
ffffffffc0200260:	60a2                	ld	ra,8(sp)
ffffffffc0200262:	4501                	li	a0,0
ffffffffc0200264:	0141                	addi	sp,sp,16
ffffffffc0200266:	8082                	ret

ffffffffc0200268 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200268:	1141                	addi	sp,sp,-16
ffffffffc020026a:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020026c:	ef3ff0ef          	jal	ra,ffffffffc020015e <print_kerninfo>
    return 0;
}
ffffffffc0200270:	60a2                	ld	ra,8(sp)
ffffffffc0200272:	4501                	li	a0,0
ffffffffc0200274:	0141                	addi	sp,sp,16
ffffffffc0200276:	8082                	ret

ffffffffc0200278 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200278:	1141                	addi	sp,sp,-16
ffffffffc020027a:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020027c:	f71ff0ef          	jal	ra,ffffffffc02001ec <print_stackframe>
    return 0;
}
ffffffffc0200280:	60a2                	ld	ra,8(sp)
ffffffffc0200282:	4501                	li	a0,0
ffffffffc0200284:	0141                	addi	sp,sp,16
ffffffffc0200286:	8082                	ret

ffffffffc0200288 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200288:	7115                	addi	sp,sp,-224
ffffffffc020028a:	ed5e                	sd	s7,152(sp)
ffffffffc020028c:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020028e:	00004517          	auipc	a0,0x4
ffffffffc0200292:	3ea50513          	addi	a0,a0,1002 # ffffffffc0204678 <etext+0x1ec>
kmonitor(struct trapframe *tf) {
ffffffffc0200296:	ed86                	sd	ra,216(sp)
ffffffffc0200298:	e9a2                	sd	s0,208(sp)
ffffffffc020029a:	e5a6                	sd	s1,200(sp)
ffffffffc020029c:	e1ca                	sd	s2,192(sp)
ffffffffc020029e:	fd4e                	sd	s3,184(sp)
ffffffffc02002a0:	f952                	sd	s4,176(sp)
ffffffffc02002a2:	f556                	sd	s5,168(sp)
ffffffffc02002a4:	f15a                	sd	s6,160(sp)
ffffffffc02002a6:	e962                	sd	s8,144(sp)
ffffffffc02002a8:	e566                	sd	s9,136(sp)
ffffffffc02002aa:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002ac:	e0fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002b0:	00004517          	auipc	a0,0x4
ffffffffc02002b4:	3f050513          	addi	a0,a0,1008 # ffffffffc02046a0 <etext+0x214>
ffffffffc02002b8:	e03ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    if (tf != NULL) {
ffffffffc02002bc:	000b8563          	beqz	s7,ffffffffc02002c6 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002c0:	855e                	mv	a0,s7
ffffffffc02002c2:	48c000ef          	jal	ra,ffffffffc020074e <print_trapframe>
ffffffffc02002c6:	00004c17          	auipc	s8,0x4
ffffffffc02002ca:	442c0c13          	addi	s8,s8,1090 # ffffffffc0204708 <commands>
        if ((buf = readline("")) != NULL) {
ffffffffc02002ce:	00005917          	auipc	s2,0x5
ffffffffc02002d2:	36290913          	addi	s2,s2,866 # ffffffffc0205630 <commands+0xf28>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002d6:	00004497          	auipc	s1,0x4
ffffffffc02002da:	3f248493          	addi	s1,s1,1010 # ffffffffc02046c8 <etext+0x23c>
        if (argc == MAXARGS - 1) {
ffffffffc02002de:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002e0:	00004b17          	auipc	s6,0x4
ffffffffc02002e4:	3f0b0b13          	addi	s6,s6,1008 # ffffffffc02046d0 <etext+0x244>
        argv[argc ++] = buf;
ffffffffc02002e8:	00004a17          	auipc	s4,0x4
ffffffffc02002ec:	310a0a13          	addi	s4,s4,784 # ffffffffc02045f8 <etext+0x16c>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f0:	4a8d                	li	s5,3
        if ((buf = readline("")) != NULL) {
ffffffffc02002f2:	854a                	mv	a0,s2
ffffffffc02002f4:	0e4040ef          	jal	ra,ffffffffc02043d8 <readline>
ffffffffc02002f8:	842a                	mv	s0,a0
ffffffffc02002fa:	dd65                	beqz	a0,ffffffffc02002f2 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002fc:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200300:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200302:	e1bd                	bnez	a1,ffffffffc0200368 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc0200304:	fe0c87e3          	beqz	s9,ffffffffc02002f2 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200308:	6582                	ld	a1,0(sp)
ffffffffc020030a:	00004d17          	auipc	s10,0x4
ffffffffc020030e:	3fed0d13          	addi	s10,s10,1022 # ffffffffc0204708 <commands>
        argv[argc ++] = buf;
ffffffffc0200312:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200314:	4401                	li	s0,0
ffffffffc0200316:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200318:	475030ef          	jal	ra,ffffffffc0203f8c <strcmp>
ffffffffc020031c:	c919                	beqz	a0,ffffffffc0200332 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020031e:	2405                	addiw	s0,s0,1
ffffffffc0200320:	0b540063          	beq	s0,s5,ffffffffc02003c0 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200324:	000d3503          	ld	a0,0(s10)
ffffffffc0200328:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032a:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020032c:	461030ef          	jal	ra,ffffffffc0203f8c <strcmp>
ffffffffc0200330:	f57d                	bnez	a0,ffffffffc020031e <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200332:	00141793          	slli	a5,s0,0x1
ffffffffc0200336:	97a2                	add	a5,a5,s0
ffffffffc0200338:	078e                	slli	a5,a5,0x3
ffffffffc020033a:	97e2                	add	a5,a5,s8
ffffffffc020033c:	6b9c                	ld	a5,16(a5)
ffffffffc020033e:	865e                	mv	a2,s7
ffffffffc0200340:	002c                	addi	a1,sp,8
ffffffffc0200342:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200346:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200348:	fa0555e3          	bgez	a0,ffffffffc02002f2 <kmonitor+0x6a>
}
ffffffffc020034c:	60ee                	ld	ra,216(sp)
ffffffffc020034e:	644e                	ld	s0,208(sp)
ffffffffc0200350:	64ae                	ld	s1,200(sp)
ffffffffc0200352:	690e                	ld	s2,192(sp)
ffffffffc0200354:	79ea                	ld	s3,184(sp)
ffffffffc0200356:	7a4a                	ld	s4,176(sp)
ffffffffc0200358:	7aaa                	ld	s5,168(sp)
ffffffffc020035a:	7b0a                	ld	s6,160(sp)
ffffffffc020035c:	6bea                	ld	s7,152(sp)
ffffffffc020035e:	6c4a                	ld	s8,144(sp)
ffffffffc0200360:	6caa                	ld	s9,136(sp)
ffffffffc0200362:	6d0a                	ld	s10,128(sp)
ffffffffc0200364:	612d                	addi	sp,sp,224
ffffffffc0200366:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200368:	8526                	mv	a0,s1
ffffffffc020036a:	441030ef          	jal	ra,ffffffffc0203faa <strchr>
ffffffffc020036e:	c901                	beqz	a0,ffffffffc020037e <kmonitor+0xf6>
ffffffffc0200370:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200374:	00040023          	sb	zero,0(s0)
ffffffffc0200378:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020037a:	d5c9                	beqz	a1,ffffffffc0200304 <kmonitor+0x7c>
ffffffffc020037c:	b7f5                	j	ffffffffc0200368 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc020037e:	00044783          	lbu	a5,0(s0)
ffffffffc0200382:	d3c9                	beqz	a5,ffffffffc0200304 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200384:	033c8963          	beq	s9,s3,ffffffffc02003b6 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc0200388:	003c9793          	slli	a5,s9,0x3
ffffffffc020038c:	0118                	addi	a4,sp,128
ffffffffc020038e:	97ba                	add	a5,a5,a4
ffffffffc0200390:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200394:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200398:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020039a:	e591                	bnez	a1,ffffffffc02003a6 <kmonitor+0x11e>
ffffffffc020039c:	b7b5                	j	ffffffffc0200308 <kmonitor+0x80>
ffffffffc020039e:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003a2:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a4:	d1a5                	beqz	a1,ffffffffc0200304 <kmonitor+0x7c>
ffffffffc02003a6:	8526                	mv	a0,s1
ffffffffc02003a8:	403030ef          	jal	ra,ffffffffc0203faa <strchr>
ffffffffc02003ac:	d96d                	beqz	a0,ffffffffc020039e <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003ae:	00044583          	lbu	a1,0(s0)
ffffffffc02003b2:	d9a9                	beqz	a1,ffffffffc0200304 <kmonitor+0x7c>
ffffffffc02003b4:	bf55                	j	ffffffffc0200368 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003b6:	45c1                	li	a1,16
ffffffffc02003b8:	855a                	mv	a0,s6
ffffffffc02003ba:	d01ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc02003be:	b7e9                	j	ffffffffc0200388 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003c0:	6582                	ld	a1,0(sp)
ffffffffc02003c2:	00004517          	auipc	a0,0x4
ffffffffc02003c6:	32e50513          	addi	a0,a0,814 # ffffffffc02046f0 <etext+0x264>
ffffffffc02003ca:	cf1ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    return 0;
ffffffffc02003ce:	b715                	j	ffffffffc02002f2 <kmonitor+0x6a>

ffffffffc02003d0 <ide_init>:
#include <string.h> // 字符串操作库
#include <trap.h>   // 陷阱处理库，可能包含异常和中断处理
#include <riscv.h>  // RISC-V架构相关的库

// 初始化IDE接口，当前为空实现
void ide_init(void) {}
ffffffffc02003d0:	8082                	ret

ffffffffc02003d2 <ide_device_valid>:
static char ide[MAX_DISK_NSECS * SECTSIZE];

// 验证IDE设备号是否有效
bool ide_device_valid(unsigned short ideno) {
    return ideno < MAX_IDE; // 如果设备号小于最大设备数，则有效
}
ffffffffc02003d2:	00253513          	sltiu	a0,a0,2
ffffffffc02003d6:	8082                	ret

ffffffffc02003d8 <ide_device_size>:

// 获取IDE设备的总扇区数
size_t ide_device_size(unsigned short ideno) {
    return MAX_DISK_NSECS; // 返回定义的最大扇区数
}
ffffffffc02003d8:	03800513          	li	a0,56
ffffffffc02003dc:	8082                	ret

ffffffffc02003de <ide_read_secs>:
                  size_t nsecs) {
    //ideno: 假设挂载了多块磁盘，选择哪一块磁盘 这里我们其实只有一块“磁盘”，这个参数就没用到
    // 计算起始偏移量
    int iobase = secno * SECTSIZE;
    // 从模拟磁盘中复制数据到目标地址
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02003de:	0000a797          	auipc	a5,0xa
ffffffffc02003e2:	c6278793          	addi	a5,a5,-926 # ffffffffc020a040 <ide>
    int iobase = secno * SECTSIZE;
ffffffffc02003e6:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc02003ea:	1141                	addi	sp,sp,-16
ffffffffc02003ec:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02003ee:	95be                	add	a1,a1,a5
ffffffffc02003f0:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc02003f4:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02003f6:	3dd030ef          	jal	ra,ffffffffc0203fd2 <memcpy>
    return 0; // 返回0表示成功
}
ffffffffc02003fa:	60a2                	ld	ra,8(sp)
ffffffffc02003fc:	4501                	li	a0,0
ffffffffc02003fe:	0141                	addi	sp,sp,16
ffffffffc0200400:	8082                	ret

ffffffffc0200402 <ide_write_secs>:

// 向IDE设备写入扇区
int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    // 计算起始偏移量
    int iobase = secno * SECTSIZE;
ffffffffc0200402:	0095979b          	slliw	a5,a1,0x9
    // 从源地址复制数据到模拟磁盘
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200406:	0000a517          	auipc	a0,0xa
ffffffffc020040a:	c3a50513          	addi	a0,a0,-966 # ffffffffc020a040 <ide>
                   size_t nsecs) {
ffffffffc020040e:	1141                	addi	sp,sp,-16
ffffffffc0200410:	85b2                	mv	a1,a2
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200412:	953e                	add	a0,a0,a5
ffffffffc0200414:	00969613          	slli	a2,a3,0x9
                   size_t nsecs) {
ffffffffc0200418:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020041a:	3b9030ef          	jal	ra,ffffffffc0203fd2 <memcpy>
    return 0; // 返回0表示成功
}
ffffffffc020041e:	60a2                	ld	ra,8(sp)
ffffffffc0200420:	4501                	li	a0,0
ffffffffc0200422:	0141                	addi	sp,sp,16
ffffffffc0200424:	8082                	ret

ffffffffc0200426 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200426:	67e1                	lui	a5,0x18
ffffffffc0200428:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020042c:	00011717          	auipc	a4,0x11
ffffffffc0200430:	0cf73e23          	sd	a5,220(a4) # ffffffffc0211508 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200434:	c0102573          	rdtime	a0
static inline void sbi_set_timer(uint64_t stime_value)
{
#if __riscv_xlen == 32
	SBI_CALL_2(SBI_SET_TIMER, stime_value, stime_value >> 32);
#else
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200438:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043a:	953e                	add	a0,a0,a5
ffffffffc020043c:	4601                	li	a2,0
ffffffffc020043e:	4881                	li	a7,0
ffffffffc0200440:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200444:	02000793          	li	a5,32
ffffffffc0200448:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020044c:	00004517          	auipc	a0,0x4
ffffffffc0200450:	30450513          	addi	a0,a0,772 # ffffffffc0204750 <commands+0x48>
    ticks = 0;
ffffffffc0200454:	00011797          	auipc	a5,0x11
ffffffffc0200458:	0a07b623          	sd	zero,172(a5) # ffffffffc0211500 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020045c:	b9b9                	j	ffffffffc02000ba <cprintf>

ffffffffc020045e <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020045e:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200462:	00011797          	auipc	a5,0x11
ffffffffc0200466:	0a67b783          	ld	a5,166(a5) # ffffffffc0211508 <timebase>
ffffffffc020046a:	953e                	add	a0,a0,a5
ffffffffc020046c:	4581                	li	a1,0
ffffffffc020046e:	4601                	li	a2,0
ffffffffc0200470:	4881                	li	a7,0
ffffffffc0200472:	00000073          	ecall
ffffffffc0200476:	8082                	ret

ffffffffc0200478 <cons_putc>:
#include <intr.h>
#include <mmu.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200478:	100027f3          	csrr	a5,sstatus
ffffffffc020047c:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc020047e:	0ff57513          	zext.b	a0,a0
ffffffffc0200482:	e799                	bnez	a5,ffffffffc0200490 <cons_putc+0x18>
ffffffffc0200484:	4581                	li	a1,0
ffffffffc0200486:	4601                	li	a2,0
ffffffffc0200488:	4885                	li	a7,1
ffffffffc020048a:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc020048e:	8082                	ret

/* cons_init - initializes the console devices */
void cons_init(void) {}

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200490:	1101                	addi	sp,sp,-32
ffffffffc0200492:	ec06                	sd	ra,24(sp)
ffffffffc0200494:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200496:	058000ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc020049a:	6522                	ld	a0,8(sp)
ffffffffc020049c:	4581                	li	a1,0
ffffffffc020049e:	4601                	li	a2,0
ffffffffc02004a0:	4885                	li	a7,1
ffffffffc02004a2:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02004a6:	60e2                	ld	ra,24(sp)
ffffffffc02004a8:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02004aa:	a83d                	j	ffffffffc02004e8 <intr_enable>

ffffffffc02004ac <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02004ac:	100027f3          	csrr	a5,sstatus
ffffffffc02004b0:	8b89                	andi	a5,a5,2
ffffffffc02004b2:	eb89                	bnez	a5,ffffffffc02004c4 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02004b4:	4501                	li	a0,0
ffffffffc02004b6:	4581                	li	a1,0
ffffffffc02004b8:	4601                	li	a2,0
ffffffffc02004ba:	4889                	li	a7,2
ffffffffc02004bc:	00000073          	ecall
ffffffffc02004c0:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02004c2:	8082                	ret
int cons_getc(void) {
ffffffffc02004c4:	1101                	addi	sp,sp,-32
ffffffffc02004c6:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02004c8:	026000ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc02004cc:	4501                	li	a0,0
ffffffffc02004ce:	4581                	li	a1,0
ffffffffc02004d0:	4601                	li	a2,0
ffffffffc02004d2:	4889                	li	a7,2
ffffffffc02004d4:	00000073          	ecall
ffffffffc02004d8:	2501                	sext.w	a0,a0
ffffffffc02004da:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02004dc:	00c000ef          	jal	ra,ffffffffc02004e8 <intr_enable>
}
ffffffffc02004e0:	60e2                	ld	ra,24(sp)
ffffffffc02004e2:	6522                	ld	a0,8(sp)
ffffffffc02004e4:	6105                	addi	sp,sp,32
ffffffffc02004e6:	8082                	ret

ffffffffc02004e8 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004e8:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02004ec:	8082                	ret

ffffffffc02004ee <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004ee:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02004f2:	8082                	ret

ffffffffc02004f4 <pgfault_handler>:
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02004f4:	10053783          	ld	a5,256(a0)
            trap_in_kernel(tf) ? 'K' : 'U', // 打印发生异常的代码是在内核态还是用户态
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R'); // 打印是读还是写操作导致的异常
}

// 缺页异常的处理函数
static int pgfault_handler(struct trapframe *tf) {
ffffffffc02004f8:	1141                	addi	sp,sp,-16
ffffffffc02004fa:	e022                	sd	s0,0(sp)
ffffffffc02004fc:	e406                	sd	ra,8(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02004fe:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr, // 打印发生异常的虚拟地址
ffffffffc0200502:	11053583          	ld	a1,272(a0)
static int pgfault_handler(struct trapframe *tf) {
ffffffffc0200506:	842a                	mv	s0,a0
    cprintf("page fault at 0x%08x: %c/%c\n", tf->badvaddr, // 打印发生异常的虚拟地址
ffffffffc0200508:	05500613          	li	a2,85
ffffffffc020050c:	c399                	beqz	a5,ffffffffc0200512 <pgfault_handler+0x1e>
ffffffffc020050e:	04b00613          	li	a2,75
ffffffffc0200512:	11843703          	ld	a4,280(s0)
ffffffffc0200516:	47bd                	li	a5,15
ffffffffc0200518:	05700693          	li	a3,87
ffffffffc020051c:	00f70463          	beq	a4,a5,ffffffffc0200524 <pgfault_handler+0x30>
ffffffffc0200520:	05200693          	li	a3,82
ffffffffc0200524:	00004517          	auipc	a0,0x4
ffffffffc0200528:	24c50513          	addi	a0,a0,588 # ffffffffc0204770 <commands+0x68>
ffffffffc020052c:	b8fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    extern struct mm_struct *check_mm_struct; // 外部定义的内存管理结构
    print_pgfault(tf); // 打印缺页异常信息
    if (check_mm_struct != NULL) { // 如果有有效的内存管理结构
ffffffffc0200530:	00011517          	auipc	a0,0x11
ffffffffc0200534:	fe053503          	ld	a0,-32(a0) # ffffffffc0211510 <check_mm_struct>
ffffffffc0200538:	c911                	beqz	a0,ffffffffc020054c <pgfault_handler+0x58>
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr); // 调用do_pgfault处理缺页异常
ffffffffc020053a:	11043603          	ld	a2,272(s0)
ffffffffc020053e:	11843583          	ld	a1,280(s0)
    }
    panic("unhandled page fault.\n"); // 如果没有有效的内存管理结构，触发panic
}
ffffffffc0200542:	6402                	ld	s0,0(sp)
ffffffffc0200544:	60a2                	ld	ra,8(sp)
ffffffffc0200546:	0141                	addi	sp,sp,16
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr); // 调用do_pgfault处理缺页异常
ffffffffc0200548:	17a0106f          	j	ffffffffc02016c2 <do_pgfault>
    panic("unhandled page fault.\n"); // 如果没有有效的内存管理结构，触发panic
ffffffffc020054c:	00004617          	auipc	a2,0x4
ffffffffc0200550:	24460613          	addi	a2,a2,580 # ffffffffc0204790 <commands+0x88>
ffffffffc0200554:	07a00593          	li	a1,122
ffffffffc0200558:	00004517          	auipc	a0,0x4
ffffffffc020055c:	25050513          	addi	a0,a0,592 # ffffffffc02047a8 <commands+0xa0>
ffffffffc0200560:	ba3ff0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0200564 <idt_init>:
    write_csr(sscratch, 0);
ffffffffc0200564:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc0200568:	00000797          	auipc	a5,0x0
ffffffffc020056c:	48878793          	addi	a5,a5,1160 # ffffffffc02009f0 <__alltraps>
ffffffffc0200570:	10579073          	csrw	stvec,a5
    set_csr(sstatus, SSTATUS_SIE);
ffffffffc0200574:	100167f3          	csrrsi	a5,sstatus,2
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200578:	000407b7          	lui	a5,0x40
ffffffffc020057c:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200580:	8082                	ret

ffffffffc0200582 <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200582:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200584:	1141                	addi	sp,sp,-16
ffffffffc0200586:	e022                	sd	s0,0(sp)
ffffffffc0200588:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020058a:	00004517          	auipc	a0,0x4
ffffffffc020058e:	23650513          	addi	a0,a0,566 # ffffffffc02047c0 <commands+0xb8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200592:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200594:	b27ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200598:	640c                	ld	a1,8(s0)
ffffffffc020059a:	00004517          	auipc	a0,0x4
ffffffffc020059e:	23e50513          	addi	a0,a0,574 # ffffffffc02047d8 <commands+0xd0>
ffffffffc02005a2:	b19ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02005a6:	680c                	ld	a1,16(s0)
ffffffffc02005a8:	00004517          	auipc	a0,0x4
ffffffffc02005ac:	24850513          	addi	a0,a0,584 # ffffffffc02047f0 <commands+0xe8>
ffffffffc02005b0:	b0bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02005b4:	6c0c                	ld	a1,24(s0)
ffffffffc02005b6:	00004517          	auipc	a0,0x4
ffffffffc02005ba:	25250513          	addi	a0,a0,594 # ffffffffc0204808 <commands+0x100>
ffffffffc02005be:	afdff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02005c2:	700c                	ld	a1,32(s0)
ffffffffc02005c4:	00004517          	auipc	a0,0x4
ffffffffc02005c8:	25c50513          	addi	a0,a0,604 # ffffffffc0204820 <commands+0x118>
ffffffffc02005cc:	aefff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02005d0:	740c                	ld	a1,40(s0)
ffffffffc02005d2:	00004517          	auipc	a0,0x4
ffffffffc02005d6:	26650513          	addi	a0,a0,614 # ffffffffc0204838 <commands+0x130>
ffffffffc02005da:	ae1ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02005de:	780c                	ld	a1,48(s0)
ffffffffc02005e0:	00004517          	auipc	a0,0x4
ffffffffc02005e4:	27050513          	addi	a0,a0,624 # ffffffffc0204850 <commands+0x148>
ffffffffc02005e8:	ad3ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02005ec:	7c0c                	ld	a1,56(s0)
ffffffffc02005ee:	00004517          	auipc	a0,0x4
ffffffffc02005f2:	27a50513          	addi	a0,a0,634 # ffffffffc0204868 <commands+0x160>
ffffffffc02005f6:	ac5ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02005fa:	602c                	ld	a1,64(s0)
ffffffffc02005fc:	00004517          	auipc	a0,0x4
ffffffffc0200600:	28450513          	addi	a0,a0,644 # ffffffffc0204880 <commands+0x178>
ffffffffc0200604:	ab7ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200608:	642c                	ld	a1,72(s0)
ffffffffc020060a:	00004517          	auipc	a0,0x4
ffffffffc020060e:	28e50513          	addi	a0,a0,654 # ffffffffc0204898 <commands+0x190>
ffffffffc0200612:	aa9ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200616:	682c                	ld	a1,80(s0)
ffffffffc0200618:	00004517          	auipc	a0,0x4
ffffffffc020061c:	29850513          	addi	a0,a0,664 # ffffffffc02048b0 <commands+0x1a8>
ffffffffc0200620:	a9bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200624:	6c2c                	ld	a1,88(s0)
ffffffffc0200626:	00004517          	auipc	a0,0x4
ffffffffc020062a:	2a250513          	addi	a0,a0,674 # ffffffffc02048c8 <commands+0x1c0>
ffffffffc020062e:	a8dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200632:	702c                	ld	a1,96(s0)
ffffffffc0200634:	00004517          	auipc	a0,0x4
ffffffffc0200638:	2ac50513          	addi	a0,a0,684 # ffffffffc02048e0 <commands+0x1d8>
ffffffffc020063c:	a7fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200640:	742c                	ld	a1,104(s0)
ffffffffc0200642:	00004517          	auipc	a0,0x4
ffffffffc0200646:	2b650513          	addi	a0,a0,694 # ffffffffc02048f8 <commands+0x1f0>
ffffffffc020064a:	a71ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020064e:	782c                	ld	a1,112(s0)
ffffffffc0200650:	00004517          	auipc	a0,0x4
ffffffffc0200654:	2c050513          	addi	a0,a0,704 # ffffffffc0204910 <commands+0x208>
ffffffffc0200658:	a63ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020065c:	7c2c                	ld	a1,120(s0)
ffffffffc020065e:	00004517          	auipc	a0,0x4
ffffffffc0200662:	2ca50513          	addi	a0,a0,714 # ffffffffc0204928 <commands+0x220>
ffffffffc0200666:	a55ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020066a:	604c                	ld	a1,128(s0)
ffffffffc020066c:	00004517          	auipc	a0,0x4
ffffffffc0200670:	2d450513          	addi	a0,a0,724 # ffffffffc0204940 <commands+0x238>
ffffffffc0200674:	a47ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200678:	644c                	ld	a1,136(s0)
ffffffffc020067a:	00004517          	auipc	a0,0x4
ffffffffc020067e:	2de50513          	addi	a0,a0,734 # ffffffffc0204958 <commands+0x250>
ffffffffc0200682:	a39ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200686:	684c                	ld	a1,144(s0)
ffffffffc0200688:	00004517          	auipc	a0,0x4
ffffffffc020068c:	2e850513          	addi	a0,a0,744 # ffffffffc0204970 <commands+0x268>
ffffffffc0200690:	a2bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200694:	6c4c                	ld	a1,152(s0)
ffffffffc0200696:	00004517          	auipc	a0,0x4
ffffffffc020069a:	2f250513          	addi	a0,a0,754 # ffffffffc0204988 <commands+0x280>
ffffffffc020069e:	a1dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02006a2:	704c                	ld	a1,160(s0)
ffffffffc02006a4:	00004517          	auipc	a0,0x4
ffffffffc02006a8:	2fc50513          	addi	a0,a0,764 # ffffffffc02049a0 <commands+0x298>
ffffffffc02006ac:	a0fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02006b0:	744c                	ld	a1,168(s0)
ffffffffc02006b2:	00004517          	auipc	a0,0x4
ffffffffc02006b6:	30650513          	addi	a0,a0,774 # ffffffffc02049b8 <commands+0x2b0>
ffffffffc02006ba:	a01ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02006be:	784c                	ld	a1,176(s0)
ffffffffc02006c0:	00004517          	auipc	a0,0x4
ffffffffc02006c4:	31050513          	addi	a0,a0,784 # ffffffffc02049d0 <commands+0x2c8>
ffffffffc02006c8:	9f3ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02006cc:	7c4c                	ld	a1,184(s0)
ffffffffc02006ce:	00004517          	auipc	a0,0x4
ffffffffc02006d2:	31a50513          	addi	a0,a0,794 # ffffffffc02049e8 <commands+0x2e0>
ffffffffc02006d6:	9e5ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02006da:	606c                	ld	a1,192(s0)
ffffffffc02006dc:	00004517          	auipc	a0,0x4
ffffffffc02006e0:	32450513          	addi	a0,a0,804 # ffffffffc0204a00 <commands+0x2f8>
ffffffffc02006e4:	9d7ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02006e8:	646c                	ld	a1,200(s0)
ffffffffc02006ea:	00004517          	auipc	a0,0x4
ffffffffc02006ee:	32e50513          	addi	a0,a0,814 # ffffffffc0204a18 <commands+0x310>
ffffffffc02006f2:	9c9ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02006f6:	686c                	ld	a1,208(s0)
ffffffffc02006f8:	00004517          	auipc	a0,0x4
ffffffffc02006fc:	33850513          	addi	a0,a0,824 # ffffffffc0204a30 <commands+0x328>
ffffffffc0200700:	9bbff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200704:	6c6c                	ld	a1,216(s0)
ffffffffc0200706:	00004517          	auipc	a0,0x4
ffffffffc020070a:	34250513          	addi	a0,a0,834 # ffffffffc0204a48 <commands+0x340>
ffffffffc020070e:	9adff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200712:	706c                	ld	a1,224(s0)
ffffffffc0200714:	00004517          	auipc	a0,0x4
ffffffffc0200718:	34c50513          	addi	a0,a0,844 # ffffffffc0204a60 <commands+0x358>
ffffffffc020071c:	99fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200720:	746c                	ld	a1,232(s0)
ffffffffc0200722:	00004517          	auipc	a0,0x4
ffffffffc0200726:	35650513          	addi	a0,a0,854 # ffffffffc0204a78 <commands+0x370>
ffffffffc020072a:	991ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020072e:	786c                	ld	a1,240(s0)
ffffffffc0200730:	00004517          	auipc	a0,0x4
ffffffffc0200734:	36050513          	addi	a0,a0,864 # ffffffffc0204a90 <commands+0x388>
ffffffffc0200738:	983ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020073c:	7c6c                	ld	a1,248(s0)
}
ffffffffc020073e:	6402                	ld	s0,0(sp)
ffffffffc0200740:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200742:	00004517          	auipc	a0,0x4
ffffffffc0200746:	36650513          	addi	a0,a0,870 # ffffffffc0204aa8 <commands+0x3a0>
}
ffffffffc020074a:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020074c:	b2bd                	j	ffffffffc02000ba <cprintf>

ffffffffc020074e <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc020074e:	1141                	addi	sp,sp,-16
ffffffffc0200750:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200752:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200754:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200756:	00004517          	auipc	a0,0x4
ffffffffc020075a:	36a50513          	addi	a0,a0,874 # ffffffffc0204ac0 <commands+0x3b8>
void print_trapframe(struct trapframe *tf) {
ffffffffc020075e:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200760:	95bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200764:	8522                	mv	a0,s0
ffffffffc0200766:	e1dff0ef          	jal	ra,ffffffffc0200582 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020076a:	10043583          	ld	a1,256(s0)
ffffffffc020076e:	00004517          	auipc	a0,0x4
ffffffffc0200772:	36a50513          	addi	a0,a0,874 # ffffffffc0204ad8 <commands+0x3d0>
ffffffffc0200776:	945ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020077a:	10843583          	ld	a1,264(s0)
ffffffffc020077e:	00004517          	auipc	a0,0x4
ffffffffc0200782:	37250513          	addi	a0,a0,882 # ffffffffc0204af0 <commands+0x3e8>
ffffffffc0200786:	935ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020078a:	11043583          	ld	a1,272(s0)
ffffffffc020078e:	00004517          	auipc	a0,0x4
ffffffffc0200792:	37a50513          	addi	a0,a0,890 # ffffffffc0204b08 <commands+0x400>
ffffffffc0200796:	925ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020079a:	11843583          	ld	a1,280(s0)
}
ffffffffc020079e:	6402                	ld	s0,0(sp)
ffffffffc02007a0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007a2:	00004517          	auipc	a0,0x4
ffffffffc02007a6:	37e50513          	addi	a0,a0,894 # ffffffffc0204b20 <commands+0x418>
}
ffffffffc02007aa:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007ac:	90fff06f          	j	ffffffffc02000ba <cprintf>

ffffffffc02007b0 <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02007b0:	11853783          	ld	a5,280(a0)
ffffffffc02007b4:	472d                	li	a4,11
ffffffffc02007b6:	0786                	slli	a5,a5,0x1
ffffffffc02007b8:	8385                	srli	a5,a5,0x1
ffffffffc02007ba:	06f76c63          	bltu	a4,a5,ffffffffc0200832 <interrupt_handler+0x82>
ffffffffc02007be:	00004717          	auipc	a4,0x4
ffffffffc02007c2:	42a70713          	addi	a4,a4,1066 # ffffffffc0204be8 <commands+0x4e0>
ffffffffc02007c6:	078a                	slli	a5,a5,0x2
ffffffffc02007c8:	97ba                	add	a5,a5,a4
ffffffffc02007ca:	439c                	lw	a5,0(a5)
ffffffffc02007cc:	97ba                	add	a5,a5,a4
ffffffffc02007ce:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02007d0:	00004517          	auipc	a0,0x4
ffffffffc02007d4:	3c850513          	addi	a0,a0,968 # ffffffffc0204b98 <commands+0x490>
ffffffffc02007d8:	8e3ff06f          	j	ffffffffc02000ba <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02007dc:	00004517          	auipc	a0,0x4
ffffffffc02007e0:	39c50513          	addi	a0,a0,924 # ffffffffc0204b78 <commands+0x470>
ffffffffc02007e4:	8d7ff06f          	j	ffffffffc02000ba <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02007e8:	00004517          	auipc	a0,0x4
ffffffffc02007ec:	35050513          	addi	a0,a0,848 # ffffffffc0204b38 <commands+0x430>
ffffffffc02007f0:	8cbff06f          	j	ffffffffc02000ba <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02007f4:	00004517          	auipc	a0,0x4
ffffffffc02007f8:	36450513          	addi	a0,a0,868 # ffffffffc0204b58 <commands+0x450>
ffffffffc02007fc:	8bfff06f          	j	ffffffffc02000ba <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200800:	1141                	addi	sp,sp,-16
ffffffffc0200802:	e406                	sd	ra,8(sp)
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc0200804:	c5bff0ef          	jal	ra,ffffffffc020045e <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200808:	00011697          	auipc	a3,0x11
ffffffffc020080c:	cf868693          	addi	a3,a3,-776 # ffffffffc0211500 <ticks>
ffffffffc0200810:	629c                	ld	a5,0(a3)
ffffffffc0200812:	06400713          	li	a4,100
ffffffffc0200816:	0785                	addi	a5,a5,1
ffffffffc0200818:	02e7f733          	remu	a4,a5,a4
ffffffffc020081c:	e29c                	sd	a5,0(a3)
ffffffffc020081e:	cb19                	beqz	a4,ffffffffc0200834 <interrupt_handler+0x84>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200820:	60a2                	ld	ra,8(sp)
ffffffffc0200822:	0141                	addi	sp,sp,16
ffffffffc0200824:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200826:	00004517          	auipc	a0,0x4
ffffffffc020082a:	3a250513          	addi	a0,a0,930 # ffffffffc0204bc8 <commands+0x4c0>
ffffffffc020082e:	88dff06f          	j	ffffffffc02000ba <cprintf>
            print_trapframe(tf);
ffffffffc0200832:	bf31                	j	ffffffffc020074e <print_trapframe>
}
ffffffffc0200834:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200836:	06400593          	li	a1,100
ffffffffc020083a:	00004517          	auipc	a0,0x4
ffffffffc020083e:	37e50513          	addi	a0,a0,894 # ffffffffc0204bb8 <commands+0x4b0>
}
ffffffffc0200842:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200844:	877ff06f          	j	ffffffffc02000ba <cprintf>

ffffffffc0200848 <exception_handler>:


void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200848:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc020084c:	1101                	addi	sp,sp,-32
ffffffffc020084e:	e822                	sd	s0,16(sp)
ffffffffc0200850:	ec06                	sd	ra,24(sp)
ffffffffc0200852:	e426                	sd	s1,8(sp)
ffffffffc0200854:	473d                	li	a4,15
ffffffffc0200856:	842a                	mv	s0,a0
ffffffffc0200858:	14f76a63          	bltu	a4,a5,ffffffffc02009ac <exception_handler+0x164>
ffffffffc020085c:	00004717          	auipc	a4,0x4
ffffffffc0200860:	57470713          	addi	a4,a4,1396 # ffffffffc0204dd0 <commands+0x6c8>
ffffffffc0200864:	078a                	slli	a5,a5,0x2
ffffffffc0200866:	97ba                	add	a5,a5,a4
ffffffffc0200868:	439c                	lw	a5,0(a5)
ffffffffc020086a:	97ba                	add	a5,a5,a4
ffffffffc020086c:	8782                	jr	a5
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_STORE_PAGE_FAULT:
            cprintf("Store/AMO page fault\n");
ffffffffc020086e:	00004517          	auipc	a0,0x4
ffffffffc0200872:	54a50513          	addi	a0,a0,1354 # ffffffffc0204db8 <commands+0x6b0>
ffffffffc0200876:	845ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {//do_pgfault()页面置换成功时返回0
ffffffffc020087a:	8522                	mv	a0,s0
ffffffffc020087c:	c79ff0ef          	jal	ra,ffffffffc02004f4 <pgfault_handler>
ffffffffc0200880:	84aa                	mv	s1,a0
ffffffffc0200882:	12051b63          	bnez	a0,ffffffffc02009b8 <exception_handler+0x170>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200886:	60e2                	ld	ra,24(sp)
ffffffffc0200888:	6442                	ld	s0,16(sp)
ffffffffc020088a:	64a2                	ld	s1,8(sp)
ffffffffc020088c:	6105                	addi	sp,sp,32
ffffffffc020088e:	8082                	ret
            cprintf("Instruction address misaligned\n");
ffffffffc0200890:	00004517          	auipc	a0,0x4
ffffffffc0200894:	38850513          	addi	a0,a0,904 # ffffffffc0204c18 <commands+0x510>
}
ffffffffc0200898:	6442                	ld	s0,16(sp)
ffffffffc020089a:	60e2                	ld	ra,24(sp)
ffffffffc020089c:	64a2                	ld	s1,8(sp)
ffffffffc020089e:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc02008a0:	81bff06f          	j	ffffffffc02000ba <cprintf>
ffffffffc02008a4:	00004517          	auipc	a0,0x4
ffffffffc02008a8:	39450513          	addi	a0,a0,916 # ffffffffc0204c38 <commands+0x530>
ffffffffc02008ac:	b7f5                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc02008ae:	00004517          	auipc	a0,0x4
ffffffffc02008b2:	3aa50513          	addi	a0,a0,938 # ffffffffc0204c58 <commands+0x550>
ffffffffc02008b6:	b7cd                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc02008b8:	00004517          	auipc	a0,0x4
ffffffffc02008bc:	3b850513          	addi	a0,a0,952 # ffffffffc0204c70 <commands+0x568>
ffffffffc02008c0:	bfe1                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Load address misaligned\n");
ffffffffc02008c2:	00004517          	auipc	a0,0x4
ffffffffc02008c6:	3be50513          	addi	a0,a0,958 # ffffffffc0204c80 <commands+0x578>
ffffffffc02008ca:	b7f9                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc02008cc:	00004517          	auipc	a0,0x4
ffffffffc02008d0:	3d450513          	addi	a0,a0,980 # ffffffffc0204ca0 <commands+0x598>
ffffffffc02008d4:	fe6ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02008d8:	8522                	mv	a0,s0
ffffffffc02008da:	c1bff0ef          	jal	ra,ffffffffc02004f4 <pgfault_handler>
ffffffffc02008de:	84aa                	mv	s1,a0
ffffffffc02008e0:	d15d                	beqz	a0,ffffffffc0200886 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02008e2:	8522                	mv	a0,s0
ffffffffc02008e4:	e6bff0ef          	jal	ra,ffffffffc020074e <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02008e8:	86a6                	mv	a3,s1
ffffffffc02008ea:	00004617          	auipc	a2,0x4
ffffffffc02008ee:	3ce60613          	addi	a2,a2,974 # ffffffffc0204cb8 <commands+0x5b0>
ffffffffc02008f2:	0cc00593          	li	a1,204
ffffffffc02008f6:	00004517          	auipc	a0,0x4
ffffffffc02008fa:	eb250513          	addi	a0,a0,-334 # ffffffffc02047a8 <commands+0xa0>
ffffffffc02008fe:	805ff0ef          	jal	ra,ffffffffc0200102 <__panic>
            cprintf("AMO address misaligned\n");
ffffffffc0200902:	00004517          	auipc	a0,0x4
ffffffffc0200906:	3d650513          	addi	a0,a0,982 # ffffffffc0204cd8 <commands+0x5d0>
ffffffffc020090a:	b779                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Store/AMO access fault\n");
ffffffffc020090c:	00004517          	auipc	a0,0x4
ffffffffc0200910:	3e450513          	addi	a0,a0,996 # ffffffffc0204cf0 <commands+0x5e8>
ffffffffc0200914:	fa6ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200918:	8522                	mv	a0,s0
ffffffffc020091a:	bdbff0ef          	jal	ra,ffffffffc02004f4 <pgfault_handler>
ffffffffc020091e:	84aa                	mv	s1,a0
ffffffffc0200920:	d13d                	beqz	a0,ffffffffc0200886 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc0200922:	8522                	mv	a0,s0
ffffffffc0200924:	e2bff0ef          	jal	ra,ffffffffc020074e <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200928:	86a6                	mv	a3,s1
ffffffffc020092a:	00004617          	auipc	a2,0x4
ffffffffc020092e:	38e60613          	addi	a2,a2,910 # ffffffffc0204cb8 <commands+0x5b0>
ffffffffc0200932:	0d600593          	li	a1,214
ffffffffc0200936:	00004517          	auipc	a0,0x4
ffffffffc020093a:	e7250513          	addi	a0,a0,-398 # ffffffffc02047a8 <commands+0xa0>
ffffffffc020093e:	fc4ff0ef          	jal	ra,ffffffffc0200102 <__panic>
            cprintf("Environment call from U-mode\n");
ffffffffc0200942:	00004517          	auipc	a0,0x4
ffffffffc0200946:	3c650513          	addi	a0,a0,966 # ffffffffc0204d08 <commands+0x600>
ffffffffc020094a:	b7b9                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Environment call from S-mode\n");
ffffffffc020094c:	00004517          	auipc	a0,0x4
ffffffffc0200950:	3dc50513          	addi	a0,a0,988 # ffffffffc0204d28 <commands+0x620>
ffffffffc0200954:	b791                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Environment call from H-mode\n");
ffffffffc0200956:	00004517          	auipc	a0,0x4
ffffffffc020095a:	3f250513          	addi	a0,a0,1010 # ffffffffc0204d48 <commands+0x640>
ffffffffc020095e:	bf2d                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Environment call from M-mode\n");
ffffffffc0200960:	00004517          	auipc	a0,0x4
ffffffffc0200964:	40850513          	addi	a0,a0,1032 # ffffffffc0204d68 <commands+0x660>
ffffffffc0200968:	bf05                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc020096a:	00004517          	auipc	a0,0x4
ffffffffc020096e:	41e50513          	addi	a0,a0,1054 # ffffffffc0204d88 <commands+0x680>
ffffffffc0200972:	b71d                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200974:	00004517          	auipc	a0,0x4
ffffffffc0200978:	42c50513          	addi	a0,a0,1068 # ffffffffc0204da0 <commands+0x698>
ffffffffc020097c:	f3eff0ef          	jal	ra,ffffffffc02000ba <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200980:	8522                	mv	a0,s0
ffffffffc0200982:	b73ff0ef          	jal	ra,ffffffffc02004f4 <pgfault_handler>
ffffffffc0200986:	84aa                	mv	s1,a0
ffffffffc0200988:	ee050fe3          	beqz	a0,ffffffffc0200886 <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc020098c:	8522                	mv	a0,s0
ffffffffc020098e:	dc1ff0ef          	jal	ra,ffffffffc020074e <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200992:	86a6                	mv	a3,s1
ffffffffc0200994:	00004617          	auipc	a2,0x4
ffffffffc0200998:	32460613          	addi	a2,a2,804 # ffffffffc0204cb8 <commands+0x5b0>
ffffffffc020099c:	0ec00593          	li	a1,236
ffffffffc02009a0:	00004517          	auipc	a0,0x4
ffffffffc02009a4:	e0850513          	addi	a0,a0,-504 # ffffffffc02047a8 <commands+0xa0>
ffffffffc02009a8:	f5aff0ef          	jal	ra,ffffffffc0200102 <__panic>
            print_trapframe(tf);
ffffffffc02009ac:	8522                	mv	a0,s0
}
ffffffffc02009ae:	6442                	ld	s0,16(sp)
ffffffffc02009b0:	60e2                	ld	ra,24(sp)
ffffffffc02009b2:	64a2                	ld	s1,8(sp)
ffffffffc02009b4:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc02009b6:	bb61                	j	ffffffffc020074e <print_trapframe>
                print_trapframe(tf);
ffffffffc02009b8:	8522                	mv	a0,s0
ffffffffc02009ba:	d95ff0ef          	jal	ra,ffffffffc020074e <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009be:	86a6                	mv	a3,s1
ffffffffc02009c0:	00004617          	auipc	a2,0x4
ffffffffc02009c4:	2f860613          	addi	a2,a2,760 # ffffffffc0204cb8 <commands+0x5b0>
ffffffffc02009c8:	0f300593          	li	a1,243
ffffffffc02009cc:	00004517          	auipc	a0,0x4
ffffffffc02009d0:	ddc50513          	addi	a0,a0,-548 # ffffffffc02047a8 <commands+0xa0>
ffffffffc02009d4:	f2eff0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc02009d8 <trap>:
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0) {
ffffffffc02009d8:	11853783          	ld	a5,280(a0)
ffffffffc02009dc:	0007c363          	bltz	a5,ffffffffc02009e2 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc02009e0:	b5a5                	j	ffffffffc0200848 <exception_handler>
        interrupt_handler(tf);
ffffffffc02009e2:	b3f9                	j	ffffffffc02007b0 <interrupt_handler>
	...

ffffffffc02009f0 <__alltraps>:
    .endm

    .align 4
    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc02009f0:	14011073          	csrw	sscratch,sp
ffffffffc02009f4:	712d                	addi	sp,sp,-288
ffffffffc02009f6:	e406                	sd	ra,8(sp)
ffffffffc02009f8:	ec0e                	sd	gp,24(sp)
ffffffffc02009fa:	f012                	sd	tp,32(sp)
ffffffffc02009fc:	f416                	sd	t0,40(sp)
ffffffffc02009fe:	f81a                	sd	t1,48(sp)
ffffffffc0200a00:	fc1e                	sd	t2,56(sp)
ffffffffc0200a02:	e0a2                	sd	s0,64(sp)
ffffffffc0200a04:	e4a6                	sd	s1,72(sp)
ffffffffc0200a06:	e8aa                	sd	a0,80(sp)
ffffffffc0200a08:	ecae                	sd	a1,88(sp)
ffffffffc0200a0a:	f0b2                	sd	a2,96(sp)
ffffffffc0200a0c:	f4b6                	sd	a3,104(sp)
ffffffffc0200a0e:	f8ba                	sd	a4,112(sp)
ffffffffc0200a10:	fcbe                	sd	a5,120(sp)
ffffffffc0200a12:	e142                	sd	a6,128(sp)
ffffffffc0200a14:	e546                	sd	a7,136(sp)
ffffffffc0200a16:	e94a                	sd	s2,144(sp)
ffffffffc0200a18:	ed4e                	sd	s3,152(sp)
ffffffffc0200a1a:	f152                	sd	s4,160(sp)
ffffffffc0200a1c:	f556                	sd	s5,168(sp)
ffffffffc0200a1e:	f95a                	sd	s6,176(sp)
ffffffffc0200a20:	fd5e                	sd	s7,184(sp)
ffffffffc0200a22:	e1e2                	sd	s8,192(sp)
ffffffffc0200a24:	e5e6                	sd	s9,200(sp)
ffffffffc0200a26:	e9ea                	sd	s10,208(sp)
ffffffffc0200a28:	edee                	sd	s11,216(sp)
ffffffffc0200a2a:	f1f2                	sd	t3,224(sp)
ffffffffc0200a2c:	f5f6                	sd	t4,232(sp)
ffffffffc0200a2e:	f9fa                	sd	t5,240(sp)
ffffffffc0200a30:	fdfe                	sd	t6,248(sp)
ffffffffc0200a32:	14002473          	csrr	s0,sscratch
ffffffffc0200a36:	100024f3          	csrr	s1,sstatus
ffffffffc0200a3a:	14102973          	csrr	s2,sepc
ffffffffc0200a3e:	143029f3          	csrr	s3,stval
ffffffffc0200a42:	14202a73          	csrr	s4,scause
ffffffffc0200a46:	e822                	sd	s0,16(sp)
ffffffffc0200a48:	e226                	sd	s1,256(sp)
ffffffffc0200a4a:	e64a                	sd	s2,264(sp)
ffffffffc0200a4c:	ea4e                	sd	s3,272(sp)
ffffffffc0200a4e:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200a50:	850a                	mv	a0,sp
    jal trap
ffffffffc0200a52:	f87ff0ef          	jal	ra,ffffffffc02009d8 <trap>

ffffffffc0200a56 <__trapret>:
    // sp should be the same as before "jal trap"
    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200a56:	6492                	ld	s1,256(sp)
ffffffffc0200a58:	6932                	ld	s2,264(sp)
ffffffffc0200a5a:	10049073          	csrw	sstatus,s1
ffffffffc0200a5e:	14191073          	csrw	sepc,s2
ffffffffc0200a62:	60a2                	ld	ra,8(sp)
ffffffffc0200a64:	61e2                	ld	gp,24(sp)
ffffffffc0200a66:	7202                	ld	tp,32(sp)
ffffffffc0200a68:	72a2                	ld	t0,40(sp)
ffffffffc0200a6a:	7342                	ld	t1,48(sp)
ffffffffc0200a6c:	73e2                	ld	t2,56(sp)
ffffffffc0200a6e:	6406                	ld	s0,64(sp)
ffffffffc0200a70:	64a6                	ld	s1,72(sp)
ffffffffc0200a72:	6546                	ld	a0,80(sp)
ffffffffc0200a74:	65e6                	ld	a1,88(sp)
ffffffffc0200a76:	7606                	ld	a2,96(sp)
ffffffffc0200a78:	76a6                	ld	a3,104(sp)
ffffffffc0200a7a:	7746                	ld	a4,112(sp)
ffffffffc0200a7c:	77e6                	ld	a5,120(sp)
ffffffffc0200a7e:	680a                	ld	a6,128(sp)
ffffffffc0200a80:	68aa                	ld	a7,136(sp)
ffffffffc0200a82:	694a                	ld	s2,144(sp)
ffffffffc0200a84:	69ea                	ld	s3,152(sp)
ffffffffc0200a86:	7a0a                	ld	s4,160(sp)
ffffffffc0200a88:	7aaa                	ld	s5,168(sp)
ffffffffc0200a8a:	7b4a                	ld	s6,176(sp)
ffffffffc0200a8c:	7bea                	ld	s7,184(sp)
ffffffffc0200a8e:	6c0e                	ld	s8,192(sp)
ffffffffc0200a90:	6cae                	ld	s9,200(sp)
ffffffffc0200a92:	6d4e                	ld	s10,208(sp)
ffffffffc0200a94:	6dee                	ld	s11,216(sp)
ffffffffc0200a96:	7e0e                	ld	t3,224(sp)
ffffffffc0200a98:	7eae                	ld	t4,232(sp)
ffffffffc0200a9a:	7f4e                	ld	t5,240(sp)
ffffffffc0200a9c:	7fee                	ld	t6,248(sp)
ffffffffc0200a9e:	6142                	ld	sp,16(sp)
    // go back from supervisor call
    sret
ffffffffc0200aa0:	10200073          	sret
	...

ffffffffc0200ab0 <_lru_init_mm>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200ab0:	00010797          	auipc	a5,0x10
ffffffffc0200ab4:	59078793          	addi	a5,a5,1424 # ffffffffc0211040 <pra_list_head>
 * @mm: 管理虚拟内存区域的 mm_struct 结构体
 */
static int _lru_init_mm(struct mm_struct *mm)
{
    list_init(&pra_list_head); // 初始化全局链表头
    mm->sm_priv = &pra_list_head; // 将链表头指针存入 mm 结构体中
ffffffffc0200ab8:	f51c                	sd	a5,40(a0)
ffffffffc0200aba:	e79c                	sd	a5,8(a5)
ffffffffc0200abc:	e39c                	sd	a5,0(a5)
    return 0;
}
ffffffffc0200abe:	4501                	li	a0,0
ffffffffc0200ac0:	8082                	ret

ffffffffc0200ac2 <_lru_init>:
/*
 * _lru_init - 初始化 LRU 缺页管理器
 */
static int _lru_init(void) {
    return 0;
}
ffffffffc0200ac2:	4501                	li	a0,0
ffffffffc0200ac4:	8082                	ret

ffffffffc0200ac6 <_lru_set_unswappable>:
/*
 * _lru_set_unswappable - 将页面标记为不可交换
 */
static int _lru_set_unswappable(struct mm_struct *mm, uintptr_t addr) {
    return 0;
}
ffffffffc0200ac6:	4501                	li	a0,0
ffffffffc0200ac8:	8082                	ret

ffffffffc0200aca <_lru_tick_event>:
/*
 * _lru_tick_event - 用于响应时间片事件（此处未实现）
 */
static int _lru_tick_event(struct mm_struct *mm) {
    return 0;
}
ffffffffc0200aca:	4501                	li	a0,0
ffffffffc0200acc:	8082                	ret

ffffffffc0200ace <_lru_swap_out_victim>:
    list_entry_t *head = (list_entry_t *) mm->sm_priv;
ffffffffc0200ace:	7518                	ld	a4,40(a0)
{
ffffffffc0200ad0:	1141                	addi	sp,sp,-16
ffffffffc0200ad2:	e406                	sd	ra,8(sp)
    assert(head != NULL);
ffffffffc0200ad4:	c731                	beqz	a4,ffffffffc0200b20 <_lru_swap_out_victim+0x52>
    assert(in_tick == 0);
ffffffffc0200ad6:	e60d                	bnez	a2,ffffffffc0200b00 <_lru_swap_out_victim+0x32>
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200ad8:	631c                	ld	a5,0(a4)
    if (entry != head) {
ffffffffc0200ada:	00f70d63          	beq	a4,a5,ffffffffc0200af4 <_lru_swap_out_victim+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200ade:	6394                	ld	a3,0(a5)
ffffffffc0200ae0:	6798                	ld	a4,8(a5)
}
ffffffffc0200ae2:	60a2                	ld	ra,8(sp)
        *ptr_page = le2page(entry, pra_page_link); // 更新 ptr_page
ffffffffc0200ae4:	fd078793          	addi	a5,a5,-48
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200ae8:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0200aea:	e314                	sd	a3,0(a4)
ffffffffc0200aec:	e19c                	sd	a5,0(a1)
}
ffffffffc0200aee:	4501                	li	a0,0
ffffffffc0200af0:	0141                	addi	sp,sp,16
ffffffffc0200af2:	8082                	ret
ffffffffc0200af4:	60a2                	ld	ra,8(sp)
        *ptr_page = NULL;
ffffffffc0200af6:	0005b023          	sd	zero,0(a1)
}
ffffffffc0200afa:	4501                	li	a0,0
ffffffffc0200afc:	0141                	addi	sp,sp,16
ffffffffc0200afe:	8082                	ret
    assert(in_tick == 0);
ffffffffc0200b00:	00004697          	auipc	a3,0x4
ffffffffc0200b04:	35068693          	addi	a3,a3,848 # ffffffffc0204e50 <commands+0x748>
ffffffffc0200b08:	00004617          	auipc	a2,0x4
ffffffffc0200b0c:	31860613          	addi	a2,a2,792 # ffffffffc0204e20 <commands+0x718>
ffffffffc0200b10:	02f00593          	li	a1,47
ffffffffc0200b14:	00004517          	auipc	a0,0x4
ffffffffc0200b18:	32450513          	addi	a0,a0,804 # ffffffffc0204e38 <commands+0x730>
ffffffffc0200b1c:	de6ff0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(head != NULL);
ffffffffc0200b20:	00004697          	auipc	a3,0x4
ffffffffc0200b24:	2f068693          	addi	a3,a3,752 # ffffffffc0204e10 <commands+0x708>
ffffffffc0200b28:	00004617          	auipc	a2,0x4
ffffffffc0200b2c:	2f860613          	addi	a2,a2,760 # ffffffffc0204e20 <commands+0x718>
ffffffffc0200b30:	02e00593          	li	a1,46
ffffffffc0200b34:	00004517          	auipc	a0,0x4
ffffffffc0200b38:	30450513          	addi	a0,a0,772 # ffffffffc0204e38 <commands+0x730>
ffffffffc0200b3c:	dc6ff0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0200b40 <_lru_map_swappable>:
    list_entry_t *head = (list_entry_t *) mm->sm_priv;
ffffffffc0200b40:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc0200b42:	cb91                	beqz	a5,ffffffffc0200b56 <_lru_map_swappable+0x16>
    __list_add(elm, listelm, listelm->next);
ffffffffc0200b44:	6794                	ld	a3,8(a5)
ffffffffc0200b46:	03060713          	addi	a4,a2,48
}
ffffffffc0200b4a:	4501                	li	a0,0
    prev->next = next->prev = elm;
ffffffffc0200b4c:	e298                	sd	a4,0(a3)
ffffffffc0200b4e:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0200b50:	fe14                	sd	a3,56(a2)
    elm->prev = prev;
ffffffffc0200b52:	fa1c                	sd	a5,48(a2)
ffffffffc0200b54:	8082                	ret
{
ffffffffc0200b56:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc0200b58:	00004697          	auipc	a3,0x4
ffffffffc0200b5c:	30868693          	addi	a3,a3,776 # ffffffffc0204e60 <commands+0x758>
ffffffffc0200b60:	00004617          	auipc	a2,0x4
ffffffffc0200b64:	2c060613          	addi	a2,a2,704 # ffffffffc0204e20 <commands+0x718>
ffffffffc0200b68:	02000593          	li	a1,32
ffffffffc0200b6c:	00004517          	auipc	a0,0x4
ffffffffc0200b70:	2cc50513          	addi	a0,a0,716 # ffffffffc0204e38 <commands+0x730>
{
ffffffffc0200b74:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc0200b76:	d8cff0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0200b7a <_lru_check_swap>:
static int _lru_check_swap(void) {
ffffffffc0200b7a:	1101                	addi	sp,sp,-32
ffffffffc0200b7c:	e822                	sd	s0,16(sp)
    cprintf("--------begin----------\n");
ffffffffc0200b7e:	00004517          	auipc	a0,0x4
ffffffffc0200b82:	30250513          	addi	a0,a0,770 # ffffffffc0204e80 <commands+0x778>
    return listelm->next;
ffffffffc0200b86:	00010417          	auipc	s0,0x10
ffffffffc0200b8a:	4ba40413          	addi	s0,s0,1210 # ffffffffc0211040 <pra_list_head>
static int _lru_check_swap(void) {
ffffffffc0200b8e:	e426                	sd	s1,8(sp)
ffffffffc0200b90:	ec06                	sd	ra,24(sp)
ffffffffc0200b92:	e04a                	sd	s2,0(sp)
    cprintf("--------begin----------\n");
ffffffffc0200b94:	d26ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200b98:	6404                	ld	s1,8(s0)
    while ((le = list_next(le)) != head) {
ffffffffc0200b9a:	00848d63          	beq	s1,s0,ffffffffc0200bb4 <_lru_check_swap+0x3a>
        cprintf("vaddr: 0x%x\n", page->pra_vaddr); // 输出页面虚拟地址
ffffffffc0200b9e:	00004917          	auipc	s2,0x4
ffffffffc0200ba2:	30290913          	addi	s2,s2,770 # ffffffffc0204ea0 <commands+0x798>
ffffffffc0200ba6:	688c                	ld	a1,16(s1)
ffffffffc0200ba8:	854a                	mv	a0,s2
ffffffffc0200baa:	d10ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200bae:	6484                	ld	s1,8(s1)
    while ((le = list_next(le)) != head) {
ffffffffc0200bb0:	fe849be3          	bne	s1,s0,ffffffffc0200ba6 <_lru_check_swap+0x2c>
    cprintf("---------end-----------\n");
ffffffffc0200bb4:	00004517          	auipc	a0,0x4
ffffffffc0200bb8:	2fc50513          	addi	a0,a0,764 # ffffffffc0204eb0 <commands+0x7a8>
ffffffffc0200bbc:	cfeff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("write Virt Page c in lru_check_swap\n");
ffffffffc0200bc0:	00004517          	auipc	a0,0x4
ffffffffc0200bc4:	31050513          	addi	a0,a0,784 # ffffffffc0204ed0 <commands+0x7c8>
ffffffffc0200bc8:	cf2ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0200bcc:	678d                	lui	a5,0x3
ffffffffc0200bce:	4731                	li	a4,12
ffffffffc0200bd0:	00e78023          	sb	a4,0(a5) # 3000 <kern_entry-0xffffffffc01fd000>
    cprintf("--------begin----------\n");
ffffffffc0200bd4:	00004517          	auipc	a0,0x4
ffffffffc0200bd8:	2ac50513          	addi	a0,a0,684 # ffffffffc0204e80 <commands+0x778>
ffffffffc0200bdc:	cdeff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200be0:	6404                	ld	s1,8(s0)
    while ((le = list_next(le)) != head) {
ffffffffc0200be2:	00848d63          	beq	s1,s0,ffffffffc0200bfc <_lru_check_swap+0x82>
        cprintf("vaddr: 0x%x\n", page->pra_vaddr); // 输出页面虚拟地址
ffffffffc0200be6:	00004917          	auipc	s2,0x4
ffffffffc0200bea:	2ba90913          	addi	s2,s2,698 # ffffffffc0204ea0 <commands+0x798>
ffffffffc0200bee:	688c                	ld	a1,16(s1)
ffffffffc0200bf0:	854a                	mv	a0,s2
ffffffffc0200bf2:	cc8ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200bf6:	6484                	ld	s1,8(s1)
    while ((le = list_next(le)) != head) {
ffffffffc0200bf8:	fe849be3          	bne	s1,s0,ffffffffc0200bee <_lru_check_swap+0x74>
    cprintf("---------end-----------\n");
ffffffffc0200bfc:	00004517          	auipc	a0,0x4
ffffffffc0200c00:	2b450513          	addi	a0,a0,692 # ffffffffc0204eb0 <commands+0x7a8>
ffffffffc0200c04:	cb6ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("write Virt Page a in lru_check_swap\n");
ffffffffc0200c08:	00004517          	auipc	a0,0x4
ffffffffc0200c0c:	2f050513          	addi	a0,a0,752 # ffffffffc0204ef8 <commands+0x7f0>
ffffffffc0200c10:	caaff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0200c14:	6785                	lui	a5,0x1
ffffffffc0200c16:	4729                	li	a4,10
ffffffffc0200c18:	00e78023          	sb	a4,0(a5) # 1000 <kern_entry-0xffffffffc01ff000>
    cprintf("--------begin----------\n");
ffffffffc0200c1c:	00004517          	auipc	a0,0x4
ffffffffc0200c20:	26450513          	addi	a0,a0,612 # ffffffffc0204e80 <commands+0x778>
ffffffffc0200c24:	c96ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200c28:	6404                	ld	s1,8(s0)
    while ((le = list_next(le)) != head) {
ffffffffc0200c2a:	00848d63          	beq	s1,s0,ffffffffc0200c44 <_lru_check_swap+0xca>
        cprintf("vaddr: 0x%x\n", page->pra_vaddr); // 输出页面虚拟地址
ffffffffc0200c2e:	00004917          	auipc	s2,0x4
ffffffffc0200c32:	27290913          	addi	s2,s2,626 # ffffffffc0204ea0 <commands+0x798>
ffffffffc0200c36:	688c                	ld	a1,16(s1)
ffffffffc0200c38:	854a                	mv	a0,s2
ffffffffc0200c3a:	c80ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200c3e:	6484                	ld	s1,8(s1)
    while ((le = list_next(le)) != head) {
ffffffffc0200c40:	fe849be3          	bne	s1,s0,ffffffffc0200c36 <_lru_check_swap+0xbc>
    cprintf("---------end-----------\n");
ffffffffc0200c44:	00004517          	auipc	a0,0x4
ffffffffc0200c48:	26c50513          	addi	a0,a0,620 # ffffffffc0204eb0 <commands+0x7a8>
ffffffffc0200c4c:	c6eff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("write Virt Page b in lru_check_swap\n");
ffffffffc0200c50:	00004517          	auipc	a0,0x4
ffffffffc0200c54:	2d050513          	addi	a0,a0,720 # ffffffffc0204f20 <commands+0x818>
ffffffffc0200c58:	c62ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0200c5c:	6789                	lui	a5,0x2
ffffffffc0200c5e:	472d                	li	a4,11
ffffffffc0200c60:	00e78023          	sb	a4,0(a5) # 2000 <kern_entry-0xffffffffc01fe000>
    cprintf("--------begin----------\n");
ffffffffc0200c64:	00004517          	auipc	a0,0x4
ffffffffc0200c68:	21c50513          	addi	a0,a0,540 # ffffffffc0204e80 <commands+0x778>
ffffffffc0200c6c:	c4eff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200c70:	6404                	ld	s1,8(s0)
    while ((le = list_next(le)) != head) {
ffffffffc0200c72:	00848d63          	beq	s1,s0,ffffffffc0200c8c <_lru_check_swap+0x112>
        cprintf("vaddr: 0x%x\n", page->pra_vaddr); // 输出页面虚拟地址
ffffffffc0200c76:	00004917          	auipc	s2,0x4
ffffffffc0200c7a:	22a90913          	addi	s2,s2,554 # ffffffffc0204ea0 <commands+0x798>
ffffffffc0200c7e:	688c                	ld	a1,16(s1)
ffffffffc0200c80:	854a                	mv	a0,s2
ffffffffc0200c82:	c38ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200c86:	6484                	ld	s1,8(s1)
    while ((le = list_next(le)) != head) {
ffffffffc0200c88:	fe849be3          	bne	s1,s0,ffffffffc0200c7e <_lru_check_swap+0x104>
    cprintf("---------end-----------\n");
ffffffffc0200c8c:	00004517          	auipc	a0,0x4
ffffffffc0200c90:	22450513          	addi	a0,a0,548 # ffffffffc0204eb0 <commands+0x7a8>
ffffffffc0200c94:	c26ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("write Virt Page e in lru_check_swap\n");
ffffffffc0200c98:	00004517          	auipc	a0,0x4
ffffffffc0200c9c:	2b050513          	addi	a0,a0,688 # ffffffffc0204f48 <commands+0x840>
ffffffffc0200ca0:	c1aff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0200ca4:	6795                	lui	a5,0x5
ffffffffc0200ca6:	4739                	li	a4,14
ffffffffc0200ca8:	00e78023          	sb	a4,0(a5) # 5000 <kern_entry-0xffffffffc01fb000>
    cprintf("--------begin----------\n");
ffffffffc0200cac:	00004517          	auipc	a0,0x4
ffffffffc0200cb0:	1d450513          	addi	a0,a0,468 # ffffffffc0204e80 <commands+0x778>
ffffffffc0200cb4:	c06ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200cb8:	6404                	ld	s1,8(s0)
    while ((le = list_next(le)) != head) {
ffffffffc0200cba:	00848d63          	beq	s1,s0,ffffffffc0200cd4 <_lru_check_swap+0x15a>
        cprintf("vaddr: 0x%x\n", page->pra_vaddr); // 输出页面虚拟地址
ffffffffc0200cbe:	00004917          	auipc	s2,0x4
ffffffffc0200cc2:	1e290913          	addi	s2,s2,482 # ffffffffc0204ea0 <commands+0x798>
ffffffffc0200cc6:	688c                	ld	a1,16(s1)
ffffffffc0200cc8:	854a                	mv	a0,s2
ffffffffc0200cca:	bf0ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200cce:	6484                	ld	s1,8(s1)
    while ((le = list_next(le)) != head) {
ffffffffc0200cd0:	fe849be3          	bne	s1,s0,ffffffffc0200cc6 <_lru_check_swap+0x14c>
    cprintf("---------end-----------\n");
ffffffffc0200cd4:	00004517          	auipc	a0,0x4
ffffffffc0200cd8:	1dc50513          	addi	a0,a0,476 # ffffffffc0204eb0 <commands+0x7a8>
ffffffffc0200cdc:	bdeff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("write Virt Page b in lru_check_swap\n");
ffffffffc0200ce0:	00004517          	auipc	a0,0x4
ffffffffc0200ce4:	24050513          	addi	a0,a0,576 # ffffffffc0204f20 <commands+0x818>
ffffffffc0200ce8:	bd2ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0200cec:	6789                	lui	a5,0x2
ffffffffc0200cee:	472d                	li	a4,11
ffffffffc0200cf0:	00e78023          	sb	a4,0(a5) # 2000 <kern_entry-0xffffffffc01fe000>
    cprintf("--------begin----------\n");
ffffffffc0200cf4:	00004517          	auipc	a0,0x4
ffffffffc0200cf8:	18c50513          	addi	a0,a0,396 # ffffffffc0204e80 <commands+0x778>
ffffffffc0200cfc:	bbeff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200d00:	6404                	ld	s1,8(s0)
    while ((le = list_next(le)) != head) {
ffffffffc0200d02:	00848d63          	beq	s1,s0,ffffffffc0200d1c <_lru_check_swap+0x1a2>
        cprintf("vaddr: 0x%x\n", page->pra_vaddr); // 输出页面虚拟地址
ffffffffc0200d06:	00004917          	auipc	s2,0x4
ffffffffc0200d0a:	19a90913          	addi	s2,s2,410 # ffffffffc0204ea0 <commands+0x798>
ffffffffc0200d0e:	688c                	ld	a1,16(s1)
ffffffffc0200d10:	854a                	mv	a0,s2
ffffffffc0200d12:	ba8ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200d16:	6484                	ld	s1,8(s1)
    while ((le = list_next(le)) != head) {
ffffffffc0200d18:	fe849be3          	bne	s1,s0,ffffffffc0200d0e <_lru_check_swap+0x194>
    cprintf("---------end-----------\n");
ffffffffc0200d1c:	00004517          	auipc	a0,0x4
ffffffffc0200d20:	19450513          	addi	a0,a0,404 # ffffffffc0204eb0 <commands+0x7a8>
ffffffffc0200d24:	b96ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("write Virt Page a in lru_check_swap\n");
ffffffffc0200d28:	00004517          	auipc	a0,0x4
ffffffffc0200d2c:	1d050513          	addi	a0,a0,464 # ffffffffc0204ef8 <commands+0x7f0>
ffffffffc0200d30:	b8aff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0200d34:	6785                	lui	a5,0x1
ffffffffc0200d36:	4729                	li	a4,10
ffffffffc0200d38:	00e78023          	sb	a4,0(a5) # 1000 <kern_entry-0xffffffffc01ff000>
    cprintf("--------begin----------\n");
ffffffffc0200d3c:	00004517          	auipc	a0,0x4
ffffffffc0200d40:	14450513          	addi	a0,a0,324 # ffffffffc0204e80 <commands+0x778>
ffffffffc0200d44:	b76ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200d48:	6404                	ld	s1,8(s0)
    while ((le = list_next(le)) != head) {
ffffffffc0200d4a:	00848d63          	beq	s1,s0,ffffffffc0200d64 <_lru_check_swap+0x1ea>
        cprintf("vaddr: 0x%x\n", page->pra_vaddr); // 输出页面虚拟地址
ffffffffc0200d4e:	00004917          	auipc	s2,0x4
ffffffffc0200d52:	15290913          	addi	s2,s2,338 # ffffffffc0204ea0 <commands+0x798>
ffffffffc0200d56:	688c                	ld	a1,16(s1)
ffffffffc0200d58:	854a                	mv	a0,s2
ffffffffc0200d5a:	b60ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200d5e:	6484                	ld	s1,8(s1)
    while ((le = list_next(le)) != head) {
ffffffffc0200d60:	fe849be3          	bne	s1,s0,ffffffffc0200d56 <_lru_check_swap+0x1dc>
    cprintf("---------end-----------\n");
ffffffffc0200d64:	00004517          	auipc	a0,0x4
ffffffffc0200d68:	14c50513          	addi	a0,a0,332 # ffffffffc0204eb0 <commands+0x7a8>
ffffffffc0200d6c:	b4eff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("write Virt Page b in lru_check_swap\n");
ffffffffc0200d70:	00004517          	auipc	a0,0x4
ffffffffc0200d74:	1b050513          	addi	a0,a0,432 # ffffffffc0204f20 <commands+0x818>
ffffffffc0200d78:	b42ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0200d7c:	6789                	lui	a5,0x2
ffffffffc0200d7e:	472d                	li	a4,11
ffffffffc0200d80:	00e78023          	sb	a4,0(a5) # 2000 <kern_entry-0xffffffffc01fe000>
    cprintf("--------begin----------\n");
ffffffffc0200d84:	00004517          	auipc	a0,0x4
ffffffffc0200d88:	0fc50513          	addi	a0,a0,252 # ffffffffc0204e80 <commands+0x778>
ffffffffc0200d8c:	b2eff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200d90:	6404                	ld	s1,8(s0)
    while ((le = list_next(le)) != head) {
ffffffffc0200d92:	00848d63          	beq	s1,s0,ffffffffc0200dac <_lru_check_swap+0x232>
        cprintf("vaddr: 0x%x\n", page->pra_vaddr); // 输出页面虚拟地址
ffffffffc0200d96:	00004917          	auipc	s2,0x4
ffffffffc0200d9a:	10a90913          	addi	s2,s2,266 # ffffffffc0204ea0 <commands+0x798>
ffffffffc0200d9e:	688c                	ld	a1,16(s1)
ffffffffc0200da0:	854a                	mv	a0,s2
ffffffffc0200da2:	b18ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200da6:	6484                	ld	s1,8(s1)
    while ((le = list_next(le)) != head) {
ffffffffc0200da8:	fe849be3          	bne	s1,s0,ffffffffc0200d9e <_lru_check_swap+0x224>
    cprintf("---------end-----------\n");
ffffffffc0200dac:	00004517          	auipc	a0,0x4
ffffffffc0200db0:	10450513          	addi	a0,a0,260 # ffffffffc0204eb0 <commands+0x7a8>
ffffffffc0200db4:	b06ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("write Virt Page c in lru_check_swap\n");
ffffffffc0200db8:	00004517          	auipc	a0,0x4
ffffffffc0200dbc:	11850513          	addi	a0,a0,280 # ffffffffc0204ed0 <commands+0x7c8>
ffffffffc0200dc0:	afaff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0200dc4:	678d                	lui	a5,0x3
ffffffffc0200dc6:	4731                	li	a4,12
ffffffffc0200dc8:	00e78023          	sb	a4,0(a5) # 3000 <kern_entry-0xffffffffc01fd000>
    cprintf("--------begin----------\n");
ffffffffc0200dcc:	00004517          	auipc	a0,0x4
ffffffffc0200dd0:	0b450513          	addi	a0,a0,180 # ffffffffc0204e80 <commands+0x778>
ffffffffc0200dd4:	ae6ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200dd8:	6404                	ld	s1,8(s0)
    while ((le = list_next(le)) != head) {
ffffffffc0200dda:	00848d63          	beq	s1,s0,ffffffffc0200df4 <_lru_check_swap+0x27a>
        cprintf("vaddr: 0x%x\n", page->pra_vaddr); // 输出页面虚拟地址
ffffffffc0200dde:	00004917          	auipc	s2,0x4
ffffffffc0200de2:	0c290913          	addi	s2,s2,194 # ffffffffc0204ea0 <commands+0x798>
ffffffffc0200de6:	688c                	ld	a1,16(s1)
ffffffffc0200de8:	854a                	mv	a0,s2
ffffffffc0200dea:	ad0ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200dee:	6484                	ld	s1,8(s1)
    while ((le = list_next(le)) != head) {
ffffffffc0200df0:	fe849be3          	bne	s1,s0,ffffffffc0200de6 <_lru_check_swap+0x26c>
    cprintf("---------end-----------\n");
ffffffffc0200df4:	00004517          	auipc	a0,0x4
ffffffffc0200df8:	0bc50513          	addi	a0,a0,188 # ffffffffc0204eb0 <commands+0x7a8>
ffffffffc0200dfc:	abeff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("write Virt Page d in lru_check_swap\n");
ffffffffc0200e00:	00004517          	auipc	a0,0x4
ffffffffc0200e04:	17050513          	addi	a0,a0,368 # ffffffffc0204f70 <commands+0x868>
ffffffffc0200e08:	ab2ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0200e0c:	6791                	lui	a5,0x4
ffffffffc0200e0e:	4735                	li	a4,13
ffffffffc0200e10:	00e78023          	sb	a4,0(a5) # 4000 <kern_entry-0xffffffffc01fc000>
    cprintf("--------begin----------\n");
ffffffffc0200e14:	00004517          	auipc	a0,0x4
ffffffffc0200e18:	06c50513          	addi	a0,a0,108 # ffffffffc0204e80 <commands+0x778>
ffffffffc0200e1c:	a9eff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200e20:	6404                	ld	s1,8(s0)
    while ((le = list_next(le)) != head) {
ffffffffc0200e22:	00848d63          	beq	s1,s0,ffffffffc0200e3c <_lru_check_swap+0x2c2>
        cprintf("vaddr: 0x%x\n", page->pra_vaddr); // 输出页面虚拟地址
ffffffffc0200e26:	00004917          	auipc	s2,0x4
ffffffffc0200e2a:	07a90913          	addi	s2,s2,122 # ffffffffc0204ea0 <commands+0x798>
ffffffffc0200e2e:	688c                	ld	a1,16(s1)
ffffffffc0200e30:	854a                	mv	a0,s2
ffffffffc0200e32:	a88ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200e36:	6484                	ld	s1,8(s1)
    while ((le = list_next(le)) != head) {
ffffffffc0200e38:	fe849be3          	bne	s1,s0,ffffffffc0200e2e <_lru_check_swap+0x2b4>
    cprintf("---------end-----------\n");
ffffffffc0200e3c:	00004517          	auipc	a0,0x4
ffffffffc0200e40:	07450513          	addi	a0,a0,116 # ffffffffc0204eb0 <commands+0x7a8>
ffffffffc0200e44:	a76ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("write Virt Page e in lru_check_swap\n");
ffffffffc0200e48:	00004517          	auipc	a0,0x4
ffffffffc0200e4c:	10050513          	addi	a0,a0,256 # ffffffffc0204f48 <commands+0x840>
ffffffffc0200e50:	a6aff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0200e54:	6795                	lui	a5,0x5
ffffffffc0200e56:	4739                	li	a4,14
ffffffffc0200e58:	00e78023          	sb	a4,0(a5) # 5000 <kern_entry-0xffffffffc01fb000>
    cprintf("--------begin----------\n");
ffffffffc0200e5c:	00004517          	auipc	a0,0x4
ffffffffc0200e60:	02450513          	addi	a0,a0,36 # ffffffffc0204e80 <commands+0x778>
ffffffffc0200e64:	a56ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200e68:	6404                	ld	s1,8(s0)
    while ((le = list_next(le)) != head) {
ffffffffc0200e6a:	00848d63          	beq	s1,s0,ffffffffc0200e84 <_lru_check_swap+0x30a>
        cprintf("vaddr: 0x%x\n", page->pra_vaddr); // 输出页面虚拟地址
ffffffffc0200e6e:	00004917          	auipc	s2,0x4
ffffffffc0200e72:	03290913          	addi	s2,s2,50 # ffffffffc0204ea0 <commands+0x798>
ffffffffc0200e76:	688c                	ld	a1,16(s1)
ffffffffc0200e78:	854a                	mv	a0,s2
ffffffffc0200e7a:	a40ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200e7e:	6484                	ld	s1,8(s1)
    while ((le = list_next(le)) != head) {
ffffffffc0200e80:	fe849be3          	bne	s1,s0,ffffffffc0200e76 <_lru_check_swap+0x2fc>
    cprintf("---------end-----------\n");
ffffffffc0200e84:	00004517          	auipc	a0,0x4
ffffffffc0200e88:	02c50513          	addi	a0,a0,44 # ffffffffc0204eb0 <commands+0x7a8>
ffffffffc0200e8c:	a2eff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("write Virt Page a in lru_check_swap\n");
ffffffffc0200e90:	00004517          	auipc	a0,0x4
ffffffffc0200e94:	06850513          	addi	a0,a0,104 # ffffffffc0204ef8 <commands+0x7f0>
ffffffffc0200e98:	a22ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0200e9c:	6785                	lui	a5,0x1
ffffffffc0200e9e:	0007c703          	lbu	a4,0(a5) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0200ea2:	47a9                	li	a5,10
ffffffffc0200ea4:	04f71363          	bne	a4,a5,ffffffffc0200eea <_lru_check_swap+0x370>
    cprintf("--------begin----------\n");
ffffffffc0200ea8:	00004517          	auipc	a0,0x4
ffffffffc0200eac:	fd850513          	addi	a0,a0,-40 # ffffffffc0204e80 <commands+0x778>
ffffffffc0200eb0:	a0aff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200eb4:	6404                	ld	s1,8(s0)
    while ((le = list_next(le)) != head) {
ffffffffc0200eb6:	00848d63          	beq	s1,s0,ffffffffc0200ed0 <_lru_check_swap+0x356>
        cprintf("vaddr: 0x%x\n", page->pra_vaddr); // 输出页面虚拟地址
ffffffffc0200eba:	00004917          	auipc	s2,0x4
ffffffffc0200ebe:	fe690913          	addi	s2,s2,-26 # ffffffffc0204ea0 <commands+0x798>
ffffffffc0200ec2:	688c                	ld	a1,16(s1)
ffffffffc0200ec4:	854a                	mv	a0,s2
ffffffffc0200ec6:	9f4ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200eca:	6484                	ld	s1,8(s1)
    while ((le = list_next(le)) != head) {
ffffffffc0200ecc:	fe849be3          	bne	s1,s0,ffffffffc0200ec2 <_lru_check_swap+0x348>
    cprintf("---------end-----------\n");
ffffffffc0200ed0:	00004517          	auipc	a0,0x4
ffffffffc0200ed4:	fe050513          	addi	a0,a0,-32 # ffffffffc0204eb0 <commands+0x7a8>
ffffffffc0200ed8:	9e2ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
}
ffffffffc0200edc:	60e2                	ld	ra,24(sp)
ffffffffc0200ede:	6442                	ld	s0,16(sp)
ffffffffc0200ee0:	64a2                	ld	s1,8(sp)
ffffffffc0200ee2:	6902                	ld	s2,0(sp)
ffffffffc0200ee4:	4501                	li	a0,0
ffffffffc0200ee6:	6105                	addi	sp,sp,32
ffffffffc0200ee8:	8082                	ret
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0200eea:	00004697          	auipc	a3,0x4
ffffffffc0200eee:	0ae68693          	addi	a3,a3,174 # ffffffffc0204f98 <commands+0x890>
ffffffffc0200ef2:	00004617          	auipc	a2,0x4
ffffffffc0200ef6:	f2e60613          	addi	a2,a2,-210 # ffffffffc0204e20 <commands+0x718>
ffffffffc0200efa:	06b00593          	li	a1,107
ffffffffc0200efe:	00004517          	auipc	a0,0x4
ffffffffc0200f02:	f3a50513          	addi	a0,a0,-198 # ffffffffc0204e38 <commands+0x730>
ffffffffc0200f06:	9fcff0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0200f0a <check_vma_overlap.part.0>:
}


// check_vma_overlap - 检查 vma1 是否与 vma2 重叠？
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0200f0a:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end); // 断言 prev 的起始地址小于结束地址
    assert(prev->vm_end <= next->vm_start); // 断言 prev 的结束地址小于等于 next 的起始地址
    assert(next->vm_start < next->vm_end); // 断言 next 的起始地址小于结束地址
ffffffffc0200f0c:	00004697          	auipc	a3,0x4
ffffffffc0200f10:	0cc68693          	addi	a3,a3,204 # ffffffffc0204fd8 <commands+0x8d0>
ffffffffc0200f14:	00004617          	auipc	a2,0x4
ffffffffc0200f18:	f0c60613          	addi	a2,a2,-244 # ffffffffc0204e20 <commands+0x718>
ffffffffc0200f1c:	07d00593          	li	a1,125
ffffffffc0200f20:	00004517          	auipc	a0,0x4
ffffffffc0200f24:	0d850513          	addi	a0,a0,216 # ffffffffc0204ff8 <commands+0x8f0>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0200f28:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end); // 断言 next 的起始地址小于结束地址
ffffffffc0200f2a:	9d8ff0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0200f2e <mm_create>:
mm_create(void) {
ffffffffc0200f2e:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0200f30:	03000513          	li	a0,48
mm_create(void) {
ffffffffc0200f34:	e022                	sd	s0,0(sp)
ffffffffc0200f36:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0200f38:	4ff020ef          	jal	ra,ffffffffc0203c36 <kmalloc>
ffffffffc0200f3c:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0200f3e:	c105                	beqz	a0,ffffffffc0200f5e <mm_create+0x30>
    elm->prev = elm->next = elm;
ffffffffc0200f40:	e408                	sd	a0,8(s0)
ffffffffc0200f42:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL; // 初始化缓存指针
ffffffffc0200f44:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL; // 初始化页目录指针
ffffffffc0200f48:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0; // 初始化映射计数器
ffffffffc0200f4c:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm); // 如果启用了交换空间，则初始化 mm 的交换空间
ffffffffc0200f50:	00010797          	auipc	a5,0x10
ffffffffc0200f54:	5e07a783          	lw	a5,1504(a5) # ffffffffc0211530 <swap_init_ok>
ffffffffc0200f58:	eb81                	bnez	a5,ffffffffc0200f68 <mm_create+0x3a>
        else mm->sm_priv = NULL; // 否则设置私有数据指针为 NULL
ffffffffc0200f5a:	02053423          	sd	zero,40(a0)
}
ffffffffc0200f5e:	60a2                	ld	ra,8(sp)
ffffffffc0200f60:	8522                	mv	a0,s0
ffffffffc0200f62:	6402                	ld	s0,0(sp)
ffffffffc0200f64:	0141                	addi	sp,sp,16
ffffffffc0200f66:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm); // 如果启用了交换空间，则初始化 mm 的交换空间
ffffffffc0200f68:	693000ef          	jal	ra,ffffffffc0201dfa <swap_init_mm>
}
ffffffffc0200f6c:	60a2                	ld	ra,8(sp)
ffffffffc0200f6e:	8522                	mv	a0,s0
ffffffffc0200f70:	6402                	ld	s0,0(sp)
ffffffffc0200f72:	0141                	addi	sp,sp,16
ffffffffc0200f74:	8082                	ret

ffffffffc0200f76 <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
ffffffffc0200f76:	1101                	addi	sp,sp,-32
ffffffffc0200f78:	e04a                	sd	s2,0(sp)
ffffffffc0200f7a:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200f7c:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
ffffffffc0200f80:	e822                	sd	s0,16(sp)
ffffffffc0200f82:	e426                	sd	s1,8(sp)
ffffffffc0200f84:	ec06                	sd	ra,24(sp)
ffffffffc0200f86:	84ae                	mv	s1,a1
ffffffffc0200f88:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200f8a:	4ad020ef          	jal	ra,ffffffffc0203c36 <kmalloc>
    if (vma != NULL) {
ffffffffc0200f8e:	c509                	beqz	a0,ffffffffc0200f98 <vma_create+0x22>
        vma->vm_start = vm_start; // 设置起始地址
ffffffffc0200f90:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end; // 设置结束地址
ffffffffc0200f94:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags; // 设置标志
ffffffffc0200f96:	ed00                	sd	s0,24(a0)
}
ffffffffc0200f98:	60e2                	ld	ra,24(sp)
ffffffffc0200f9a:	6442                	ld	s0,16(sp)
ffffffffc0200f9c:	64a2                	ld	s1,8(sp)
ffffffffc0200f9e:	6902                	ld	s2,0(sp)
ffffffffc0200fa0:	6105                	addi	sp,sp,32
ffffffffc0200fa2:	8082                	ret

ffffffffc0200fa4 <find_vma>:
find_vma(struct mm_struct *mm, uintptr_t addr) {
ffffffffc0200fa4:	86aa                	mv	a3,a0
    if (mm != NULL) {
ffffffffc0200fa6:	c505                	beqz	a0,ffffffffc0200fce <find_vma+0x2a>
        vma = mm->mmap_cache; // 获取缓存的 vma
ffffffffc0200fa8:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) { // 如果缓存的 vma 不包含地址
ffffffffc0200faa:	c501                	beqz	a0,ffffffffc0200fb2 <find_vma+0xe>
ffffffffc0200fac:	651c                	ld	a5,8(a0)
ffffffffc0200fae:	02f5f263          	bgeu	a1,a5,ffffffffc0200fd2 <find_vma+0x2e>
    return listelm->next;
ffffffffc0200fb2:	669c                	ld	a5,8(a3)
                while ((le = list_next(le)) != list) { // 遍历线性链表
ffffffffc0200fb4:	00f68d63          	beq	a3,a5,ffffffffc0200fce <find_vma+0x2a>
                    if (vma->vm_start <= addr && addr < vma->vm_end) { // 如果找到包含地址的 vma
ffffffffc0200fb8:	fe87b703          	ld	a4,-24(a5)
ffffffffc0200fbc:	00e5e663          	bltu	a1,a4,ffffffffc0200fc8 <find_vma+0x24>
ffffffffc0200fc0:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200fc4:	00e5ec63          	bltu	a1,a4,ffffffffc0200fdc <find_vma+0x38>
ffffffffc0200fc8:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) { // 遍历线性链表
ffffffffc0200fca:	fef697e3          	bne	a3,a5,ffffffffc0200fb8 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0200fce:	4501                	li	a0,0
}
ffffffffc0200fd0:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) { // 如果缓存的 vma 不包含地址
ffffffffc0200fd2:	691c                	ld	a5,16(a0)
ffffffffc0200fd4:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0200fb2 <find_vma+0xe>
            mm->mmap_cache = vma; // 更新缓存的 vma
ffffffffc0200fd8:	ea88                	sd	a0,16(a3)
ffffffffc0200fda:	8082                	ret
                    vma = le2vma(le, list_link);
ffffffffc0200fdc:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma; // 更新缓存的 vma
ffffffffc0200fe0:	ea88                	sd	a0,16(a3)
ffffffffc0200fe2:	8082                	ret

ffffffffc0200fe4 <insert_vma_struct>:

// insert_vma_struct - 在 mm 的列表链接中插入 vma
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    // 确保 vma 的起始地址小于结束地址
    assert(vma->vm_start < vma->vm_end);
ffffffffc0200fe4:	6590                	ld	a2,8(a1)
ffffffffc0200fe6:	0105b803          	ld	a6,16(a1)
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc0200fea:	1141                	addi	sp,sp,-16
ffffffffc0200fec:	e406                	sd	ra,8(sp)
ffffffffc0200fee:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0200ff0:	01066763          	bltu	a2,a6,ffffffffc0200ffe <insert_vma_struct+0x1a>
ffffffffc0200ff4:	a085                	j	ffffffffc0201054 <insert_vma_struct+0x70>
    // 遍历 mm 的映射列表，找到应该插入 vma 的位置
    list_entry_t *le = list;
    while ((le = list_next(le)) != list) {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        // 如果当前遍历到的 vma 的起始地址大于要插入的 vma 的起始地址，则停止遍历
        if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0200ff6:	fe87b703          	ld	a4,-24(a5)
ffffffffc0200ffa:	04e66863          	bltu	a2,a4,ffffffffc020104a <insert_vma_struct+0x66>
ffffffffc0200ffe:	86be                	mv	a3,a5
ffffffffc0201000:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list) {
ffffffffc0201002:	fef51ae3          	bne	a0,a5,ffffffffc0200ff6 <insert_vma_struct+0x12>
    // 获取 le_prev 的下一个节点，即插入位置的后一个节点
    le_next = list_next(le_prev);
    
    // 检查重叠
    // 如果前一个节点不是头节点，检查与前一个 vma 是否重叠
    if (le_prev != list) {
ffffffffc0201006:	02a68463          	beq	a3,a0,ffffffffc020102e <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc020100a:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end); // 断言 prev 的起始地址小于结束地址
ffffffffc020100e:	fe86b883          	ld	a7,-24(a3)
ffffffffc0201012:	08e8f163          	bgeu	a7,a4,ffffffffc0201094 <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start); // 断言 prev 的结束地址小于等于 next 的起始地址
ffffffffc0201016:	04e66f63          	bltu	a2,a4,ffffffffc0201074 <insert_vma_struct+0x90>
    }
    // 如果后一个节点不是头节点，检查与后一个 vma 是否重叠
    if (le_next != list) {
ffffffffc020101a:	00f50a63          	beq	a0,a5,ffffffffc020102e <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc020101e:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start); // 断言 prev 的结束地址小于等于 next 的起始地址
ffffffffc0201022:	05076963          	bltu	a4,a6,ffffffffc0201074 <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end); // 断言 next 的起始地址小于结束地址
ffffffffc0201026:	ff07b603          	ld	a2,-16(a5)
ffffffffc020102a:	02c77363          	bgeu	a4,a2,ffffffffc0201050 <insert_vma_struct+0x6c>
    vma->vm_mm = mm;
    // 在 le_prev 之后插入 vma
    list_add_after(le_prev, &(vma->list_link));
    
    // 更新 mm 中的映射计数器
    mm->map_count ++;
ffffffffc020102e:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0201030:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0201032:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0201036:	e390                	sd	a2,0(a5)
ffffffffc0201038:	e690                	sd	a2,8(a3)
}
ffffffffc020103a:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020103c:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020103e:	f194                	sd	a3,32(a1)
    mm->map_count ++;
ffffffffc0201040:	0017079b          	addiw	a5,a4,1
ffffffffc0201044:	d11c                	sw	a5,32(a0)
}
ffffffffc0201046:	0141                	addi	sp,sp,16
ffffffffc0201048:	8082                	ret
    if (le_prev != list) {
ffffffffc020104a:	fca690e3          	bne	a3,a0,ffffffffc020100a <insert_vma_struct+0x26>
ffffffffc020104e:	bfd1                	j	ffffffffc0201022 <insert_vma_struct+0x3e>
ffffffffc0201050:	ebbff0ef          	jal	ra,ffffffffc0200f0a <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0201054:	00004697          	auipc	a3,0x4
ffffffffc0201058:	fb468693          	addi	a3,a3,-76 # ffffffffc0205008 <commands+0x900>
ffffffffc020105c:	00004617          	auipc	a2,0x4
ffffffffc0201060:	dc460613          	addi	a2,a2,-572 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201064:	08500593          	li	a1,133
ffffffffc0201068:	00004517          	auipc	a0,0x4
ffffffffc020106c:	f9050513          	addi	a0,a0,-112 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc0201070:	892ff0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(prev->vm_end <= next->vm_start); // 断言 prev 的结束地址小于等于 next 的起始地址
ffffffffc0201074:	00004697          	auipc	a3,0x4
ffffffffc0201078:	fd468693          	addi	a3,a3,-44 # ffffffffc0205048 <commands+0x940>
ffffffffc020107c:	00004617          	auipc	a2,0x4
ffffffffc0201080:	da460613          	addi	a2,a2,-604 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201084:	07c00593          	li	a1,124
ffffffffc0201088:	00004517          	auipc	a0,0x4
ffffffffc020108c:	f7050513          	addi	a0,a0,-144 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc0201090:	872ff0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(prev->vm_start < prev->vm_end); // 断言 prev 的起始地址小于结束地址
ffffffffc0201094:	00004697          	auipc	a3,0x4
ffffffffc0201098:	f9468693          	addi	a3,a3,-108 # ffffffffc0205028 <commands+0x920>
ffffffffc020109c:	00004617          	auipc	a2,0x4
ffffffffc02010a0:	d8460613          	addi	a2,a2,-636 # ffffffffc0204e20 <commands+0x718>
ffffffffc02010a4:	07b00593          	li	a1,123
ffffffffc02010a8:	00004517          	auipc	a0,0x4
ffffffffc02010ac:	f5050513          	addi	a0,a0,-176 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc02010b0:	852ff0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc02010b4 <mm_destroy>:

// mm_destroy - 释放 mm 及其内部字段
void
mm_destroy(struct mm_struct *mm) {
ffffffffc02010b4:	1141                	addi	sp,sp,-16
ffffffffc02010b6:	e022                	sd	s0,0(sp)
ffffffffc02010b8:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02010ba:	6508                	ld	a0,8(a0)
ffffffffc02010bc:	e406                	sd	ra,8(sp)
    // 获取 mm 的映射列表的头节点
    list_entry_t *list = &(mm->mmap_list), *le;
    // 遍历映射列表，释放每一个 vma
    while ((le = list_next(list)) != list) {
ffffffffc02010be:	00a40e63          	beq	s0,a0,ffffffffc02010da <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02010c2:	6118                	ld	a4,0(a0)
ffffffffc02010c4:	651c                	ld	a5,8(a0)
        list_del(le); // 从列表中删除当前节点
        // 释放 vma 所占用的内存
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  
ffffffffc02010c6:	03000593          	li	a1,48
ffffffffc02010ca:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02010cc:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02010ce:	e398                	sd	a4,0(a5)
ffffffffc02010d0:	421020ef          	jal	ra,ffffffffc0203cf0 <kfree>
    return listelm->next;
ffffffffc02010d4:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc02010d6:	fea416e3          	bne	s0,a0,ffffffffc02010c2 <mm_destroy+0xe>
    }
    // 释放 mm 所占用的内存
    kfree(mm, sizeof(struct mm_struct)); 
ffffffffc02010da:	8522                	mv	a0,s0
    // 将 mm 设置为 NULL，防止产生野指针
    mm=NULL;
}
ffffffffc02010dc:	6402                	ld	s0,0(sp)
ffffffffc02010de:	60a2                	ld	ra,8(sp)
    kfree(mm, sizeof(struct mm_struct)); 
ffffffffc02010e0:	03000593          	li	a1,48
}
ffffffffc02010e4:	0141                	addi	sp,sp,16
    kfree(mm, sizeof(struct mm_struct)); 
ffffffffc02010e6:	40b0206f          	j	ffffffffc0203cf0 <kfree>

ffffffffc02010ea <vmm_init>:

// vmm_init - 初始化虚拟内存管理
//          - 目前只是调用 check_vmm 来检查 vmm 的正确性
void
vmm_init(void) {
ffffffffc02010ea:	715d                	addi	sp,sp,-80
ffffffffc02010ec:	e486                	sd	ra,72(sp)
ffffffffc02010ee:	f44e                	sd	s3,40(sp)
ffffffffc02010f0:	f052                	sd	s4,32(sp)
ffffffffc02010f2:	e0a2                	sd	s0,64(sp)
ffffffffc02010f4:	fc26                	sd	s1,56(sp)
ffffffffc02010f6:	f84a                	sd	s2,48(sp)
ffffffffc02010f8:	ec56                	sd	s5,24(sp)
ffffffffc02010fa:	e85a                	sd	s6,16(sp)
ffffffffc02010fc:	e45e                	sd	s7,8(sp)

// check_vmm - 检查 vmm 的正确性
static void
check_vmm(void) {
    // 存储当前的空闲页面数
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02010fe:	285010ef          	jal	ra,ffffffffc0202b82 <nr_free_pages>
ffffffffc0201102:	89aa                	mv	s3,a0
}

static void
check_vma_struct(void) {
    // 存储当前的空闲页面数
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0201104:	27f010ef          	jal	ra,ffffffffc0202b82 <nr_free_pages>
ffffffffc0201108:	8a2a                	mv	s4,a0
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020110a:	03000513          	li	a0,48
ffffffffc020110e:	329020ef          	jal	ra,ffffffffc0203c36 <kmalloc>
    if (mm != NULL) {
ffffffffc0201112:	56050863          	beqz	a0,ffffffffc0201682 <vmm_init+0x598>
    elm->prev = elm->next = elm;
ffffffffc0201116:	e508                	sd	a0,8(a0)
ffffffffc0201118:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL; // 初始化缓存指针
ffffffffc020111a:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL; // 初始化页目录指针
ffffffffc020111e:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0; // 初始化映射计数器
ffffffffc0201122:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm); // 如果启用了交换空间，则初始化 mm 的交换空间
ffffffffc0201126:	00010797          	auipc	a5,0x10
ffffffffc020112a:	40a7a783          	lw	a5,1034(a5) # ffffffffc0211530 <swap_init_ok>
ffffffffc020112e:	84aa                	mv	s1,a0
ffffffffc0201130:	e7b9                	bnez	a5,ffffffffc020117e <vmm_init+0x94>
        else mm->sm_priv = NULL; // 否则设置私有数据指针为 NULL
ffffffffc0201132:	02053423          	sd	zero,40(a0)
vmm_init(void) {
ffffffffc0201136:	03200413          	li	s0,50
ffffffffc020113a:	a811                	j	ffffffffc020114e <vmm_init+0x64>
        vma->vm_start = vm_start; // 设置起始地址
ffffffffc020113c:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end; // 设置结束地址
ffffffffc020113e:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags; // 设置标志
ffffffffc0201140:	00053c23          	sd	zero,24(a0)
    // 定义步长，用于创建测试用的 vma
    int step1 = 10, step2 = step1 * 10;

    int i;
    // 从后向前创建并插入 vma
    for (i = step1; i >= 1; i --) {
ffffffffc0201144:	146d                	addi	s0,s0,-5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        // 断言 vma 创建成功
        assert(vma != NULL);
        // 将 vma 插入到 mm 的映射列表中
        insert_vma_struct(mm, vma);
ffffffffc0201146:	8526                	mv	a0,s1
ffffffffc0201148:	e9dff0ef          	jal	ra,ffffffffc0200fe4 <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc020114c:	cc05                	beqz	s0,ffffffffc0201184 <vmm_init+0x9a>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020114e:	03000513          	li	a0,48
ffffffffc0201152:	2e5020ef          	jal	ra,ffffffffc0203c36 <kmalloc>
ffffffffc0201156:	85aa                	mv	a1,a0
ffffffffc0201158:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc020115c:	f165                	bnez	a0,ffffffffc020113c <vmm_init+0x52>
        assert(vma != NULL);
ffffffffc020115e:	00004697          	auipc	a3,0x4
ffffffffc0201162:	13a68693          	addi	a3,a3,314 # ffffffffc0205298 <commands+0xb90>
ffffffffc0201166:	00004617          	auipc	a2,0x4
ffffffffc020116a:	cba60613          	addi	a2,a2,-838 # ffffffffc0204e20 <commands+0x718>
ffffffffc020116e:	0ea00593          	li	a1,234
ffffffffc0201172:	00004517          	auipc	a0,0x4
ffffffffc0201176:	e8650513          	addi	a0,a0,-378 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc020117a:	f89fe0ef          	jal	ra,ffffffffc0200102 <__panic>
        if (swap_init_ok) swap_init_mm(mm); // 如果启用了交换空间，则初始化 mm 的交换空间
ffffffffc020117e:	47d000ef          	jal	ra,ffffffffc0201dfa <swap_init_mm>
ffffffffc0201182:	bf55                	j	ffffffffc0201136 <vmm_init+0x4c>
ffffffffc0201184:	03700413          	li	s0,55
    }

    // 从前向后创建并插入 vma
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0201188:	1f900913          	li	s2,505
ffffffffc020118c:	a819                	j	ffffffffc02011a2 <vmm_init+0xb8>
        vma->vm_start = vm_start; // 设置起始地址
ffffffffc020118e:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end; // 设置结束地址
ffffffffc0201190:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags; // 设置标志
ffffffffc0201192:	00053c23          	sd	zero,24(a0)
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0201196:	0415                	addi	s0,s0,5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        // 断言 vma 创建成功
        assert(vma != NULL);
        // 将 vma 插入到 mm 的映射列表中
        insert_vma_struct(mm, vma);
ffffffffc0201198:	8526                	mv	a0,s1
ffffffffc020119a:	e4bff0ef          	jal	ra,ffffffffc0200fe4 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc020119e:	03240a63          	beq	s0,s2,ffffffffc02011d2 <vmm_init+0xe8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02011a2:	03000513          	li	a0,48
ffffffffc02011a6:	291020ef          	jal	ra,ffffffffc0203c36 <kmalloc>
ffffffffc02011aa:	85aa                	mv	a1,a0
ffffffffc02011ac:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc02011b0:	fd79                	bnez	a0,ffffffffc020118e <vmm_init+0xa4>
        assert(vma != NULL);
ffffffffc02011b2:	00004697          	auipc	a3,0x4
ffffffffc02011b6:	0e668693          	addi	a3,a3,230 # ffffffffc0205298 <commands+0xb90>
ffffffffc02011ba:	00004617          	auipc	a2,0x4
ffffffffc02011be:	c6660613          	addi	a2,a2,-922 # ffffffffc0204e20 <commands+0x718>
ffffffffc02011c2:	0f300593          	li	a1,243
ffffffffc02011c6:	00004517          	auipc	a0,0x4
ffffffffc02011ca:	e3250513          	addi	a0,a0,-462 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc02011ce:	f35fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    return listelm->next;
ffffffffc02011d2:	649c                	ld	a5,8(s1)
ffffffffc02011d4:	471d                	li	a4,7
    }

    // 遍历 mm 的映射列表，检查 vma 的顺序和属性
    list_entry_t *le = list_next(&(mm->mmap_list));
    for (i = 1; i <= step2; i ++) {
ffffffffc02011d6:	1fb00593          	li	a1,507
        // 断言当前节点不是头节点
        assert(le != &(mm->mmap_list));
ffffffffc02011da:	2ef48463          	beq	s1,a5,ffffffffc02014c2 <vmm_init+0x3d8>
        struct vma_struct *mmap = le2vma(le, list_link);
        // 断言 vma 的起始地址和结束地址正确
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02011de:	fe87b603          	ld	a2,-24(a5)
ffffffffc02011e2:	ffe70693          	addi	a3,a4,-2
ffffffffc02011e6:	26d61e63          	bne	a2,a3,ffffffffc0201462 <vmm_init+0x378>
ffffffffc02011ea:	ff07b683          	ld	a3,-16(a5)
ffffffffc02011ee:	26e69a63          	bne	a3,a4,ffffffffc0201462 <vmm_init+0x378>
    for (i = 1; i <= step2; i ++) {
ffffffffc02011f2:	0715                	addi	a4,a4,5
ffffffffc02011f4:	679c                	ld	a5,8(a5)
ffffffffc02011f6:	feb712e3          	bne	a4,a1,ffffffffc02011da <vmm_init+0xf0>
ffffffffc02011fa:	4b1d                	li	s6,7
ffffffffc02011fc:	4415                	li	s0,5
        le = list_next(le);
    }

    // 检查 find_vma 函数的正确性
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc02011fe:	1f900b93          	li	s7,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0201202:	85a2                	mv	a1,s0
ffffffffc0201204:	8526                	mv	a0,s1
ffffffffc0201206:	d9fff0ef          	jal	ra,ffffffffc0200fa4 <find_vma>
ffffffffc020120a:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc020120c:	2c050b63          	beqz	a0,ffffffffc02014e2 <vmm_init+0x3f8>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0201210:	00140593          	addi	a1,s0,1
ffffffffc0201214:	8526                	mv	a0,s1
ffffffffc0201216:	d8fff0ef          	jal	ra,ffffffffc0200fa4 <find_vma>
ffffffffc020121a:	8aaa                	mv	s5,a0
        assert(vma2 != NULL);
ffffffffc020121c:	2e050363          	beqz	a0,ffffffffc0201502 <vmm_init+0x418>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0201220:	85da                	mv	a1,s6
ffffffffc0201222:	8526                	mv	a0,s1
ffffffffc0201224:	d81ff0ef          	jal	ra,ffffffffc0200fa4 <find_vma>
        assert(vma3 == NULL);
ffffffffc0201228:	2e051d63          	bnez	a0,ffffffffc0201522 <vmm_init+0x438>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc020122c:	00340593          	addi	a1,s0,3
ffffffffc0201230:	8526                	mv	a0,s1
ffffffffc0201232:	d73ff0ef          	jal	ra,ffffffffc0200fa4 <find_vma>
        assert(vma4 == NULL);
ffffffffc0201236:	30051663          	bnez	a0,ffffffffc0201542 <vmm_init+0x458>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc020123a:	00440593          	addi	a1,s0,4
ffffffffc020123e:	8526                	mv	a0,s1
ffffffffc0201240:	d65ff0ef          	jal	ra,ffffffffc0200fa4 <find_vma>
        assert(vma5 == NULL);
ffffffffc0201244:	30051f63          	bnez	a0,ffffffffc0201562 <vmm_init+0x478>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0201248:	00893783          	ld	a5,8(s2)
ffffffffc020124c:	24879b63          	bne	a5,s0,ffffffffc02014a2 <vmm_init+0x3b8>
ffffffffc0201250:	01093783          	ld	a5,16(s2)
ffffffffc0201254:	25679763          	bne	a5,s6,ffffffffc02014a2 <vmm_init+0x3b8>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0201258:	008ab783          	ld	a5,8(s5)
ffffffffc020125c:	22879363          	bne	a5,s0,ffffffffc0201482 <vmm_init+0x398>
ffffffffc0201260:	010ab783          	ld	a5,16(s5)
ffffffffc0201264:	21679f63          	bne	a5,s6,ffffffffc0201482 <vmm_init+0x398>
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0201268:	0415                	addi	s0,s0,5
ffffffffc020126a:	0b15                	addi	s6,s6,5
ffffffffc020126c:	f9741be3          	bne	s0,s7,ffffffffc0201202 <vmm_init+0x118>
ffffffffc0201270:	4411                	li	s0,4
    }

    // 检查 find_vma 函数在边界情况下的正确性
    for (i =4; i>=0; i--) {
ffffffffc0201272:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc0201274:	85a2                	mv	a1,s0
ffffffffc0201276:	8526                	mv	a0,s1
ffffffffc0201278:	d2dff0ef          	jal	ra,ffffffffc0200fa4 <find_vma>
ffffffffc020127c:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL ) {
ffffffffc0201280:	c90d                	beqz	a0,ffffffffc02012b2 <vmm_init+0x1c8>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0201282:	6914                	ld	a3,16(a0)
ffffffffc0201284:	6510                	ld	a2,8(a0)
ffffffffc0201286:	00004517          	auipc	a0,0x4
ffffffffc020128a:	ee250513          	addi	a0,a0,-286 # ffffffffc0205168 <commands+0xa60>
ffffffffc020128e:	e2dfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0201292:	00004697          	auipc	a3,0x4
ffffffffc0201296:	efe68693          	addi	a3,a3,-258 # ffffffffc0205190 <commands+0xa88>
ffffffffc020129a:	00004617          	auipc	a2,0x4
ffffffffc020129e:	b8660613          	addi	a2,a2,-1146 # ffffffffc0204e20 <commands+0x718>
ffffffffc02012a2:	11a00593          	li	a1,282
ffffffffc02012a6:	00004517          	auipc	a0,0x4
ffffffffc02012aa:	d5250513          	addi	a0,a0,-686 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc02012ae:	e55fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    for (i =4; i>=0; i--) {
ffffffffc02012b2:	147d                	addi	s0,s0,-1
ffffffffc02012b4:	fd2410e3          	bne	s0,s2,ffffffffc0201274 <vmm_init+0x18a>
ffffffffc02012b8:	a811                	j	ffffffffc02012cc <vmm_init+0x1e2>
    __list_del(listelm->prev, listelm->next);
ffffffffc02012ba:	6118                	ld	a4,0(a0)
ffffffffc02012bc:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  
ffffffffc02012be:	03000593          	li	a1,48
ffffffffc02012c2:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02012c4:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02012c6:	e398                	sd	a4,0(a5)
ffffffffc02012c8:	229020ef          	jal	ra,ffffffffc0203cf0 <kfree>
    return listelm->next;
ffffffffc02012cc:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list) {
ffffffffc02012ce:	fea496e3          	bne	s1,a0,ffffffffc02012ba <vmm_init+0x1d0>
    kfree(mm, sizeof(struct mm_struct)); 
ffffffffc02012d2:	03000593          	li	a1,48
ffffffffc02012d6:	8526                	mv	a0,s1
ffffffffc02012d8:	219020ef          	jal	ra,ffffffffc0203cf0 <kfree>

    // 释放 mm 及其所有 vma
    mm_destroy(mm);

    // 断言空闲页面数没有变化，确保上面的操作没有影响内存分配
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02012dc:	0a7010ef          	jal	ra,ffffffffc0202b82 <nr_free_pages>
ffffffffc02012e0:	3caa1163          	bne	s4,a0,ffffffffc02016a2 <vmm_init+0x5b8>

    // 打印检查成功的消息
    cprintf("check_vma_struct() succeeded!\n");
ffffffffc02012e4:	00004517          	auipc	a0,0x4
ffffffffc02012e8:	eec50513          	addi	a0,a0,-276 # ffffffffc02051d0 <commands+0xac8>
ffffffffc02012ec:	dcffe0ef          	jal	ra,ffffffffc02000ba <cprintf>

// check_pgfault - 检查缺页处理程序的正确性
static void
check_pgfault(void) {
    // 存储当前的空闲页面数
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02012f0:	093010ef          	jal	ra,ffffffffc0202b82 <nr_free_pages>
ffffffffc02012f4:	84aa                	mv	s1,a0
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02012f6:	03000513          	li	a0,48
ffffffffc02012fa:	13d020ef          	jal	ra,ffffffffc0203c36 <kmalloc>
ffffffffc02012fe:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0201300:	2a050163          	beqz	a0,ffffffffc02015a2 <vmm_init+0x4b8>
        if (swap_init_ok) swap_init_mm(mm); // 如果启用了交换空间，则初始化 mm 的交换空间
ffffffffc0201304:	00010797          	auipc	a5,0x10
ffffffffc0201308:	22c7a783          	lw	a5,556(a5) # ffffffffc0211530 <swap_init_ok>
    elm->prev = elm->next = elm;
ffffffffc020130c:	e508                	sd	a0,8(a0)
ffffffffc020130e:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL; // 初始化缓存指针
ffffffffc0201310:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL; // 初始化页目录指针
ffffffffc0201314:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0; // 初始化映射计数器
ffffffffc0201318:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm); // 如果启用了交换空间，则初始化 mm 的交换空间
ffffffffc020131c:	14079063          	bnez	a5,ffffffffc020145c <vmm_init+0x372>
        else mm->sm_priv = NULL; // 否则设置私有数据指针为 NULL
ffffffffc0201320:	02053423          	sd	zero,40(a0)
    check_mm_struct = mm_create();
    // 断言内存管理结构体创建成功
    assert(check_mm_struct != NULL);
    struct mm_struct *mm = check_mm_struct;
    // 为 mm 分配页目录，并将其设置为启动时的页目录
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0201324:	00010917          	auipc	s2,0x10
ffffffffc0201328:	21c93903          	ld	s2,540(s2) # ffffffffc0211540 <boot_pgdir>
    // 断言页目录的第一个条目是空的
    assert(pgdir[0] == 0);
ffffffffc020132c:	00093783          	ld	a5,0(s2)
    check_mm_struct = mm_create();
ffffffffc0201330:	00010717          	auipc	a4,0x10
ffffffffc0201334:	1e873023          	sd	s0,480(a4) # ffffffffc0211510 <check_mm_struct>
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0201338:	01243c23          	sd	s2,24(s0)
    assert(pgdir[0] == 0);
ffffffffc020133c:	24079363          	bnez	a5,ffffffffc0201582 <vmm_init+0x498>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0201340:	03000513          	li	a0,48
ffffffffc0201344:	0f3020ef          	jal	ra,ffffffffc0203c36 <kmalloc>
ffffffffc0201348:	8a2a                	mv	s4,a0
    if (vma != NULL) {
ffffffffc020134a:	28050063          	beqz	a0,ffffffffc02015ca <vmm_init+0x4e0>
        vma->vm_end = vm_end; // 设置结束地址
ffffffffc020134e:	002007b7          	lui	a5,0x200
ffffffffc0201352:	00fa3823          	sd	a5,16(s4)
        vma->vm_flags = vm_flags; // 设置标志
ffffffffc0201356:	4789                	li	a5,2
    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    // 断言虚拟内存区域结构体创建成功
    assert(vma != NULL);

    // 将虚拟内存区域结构体插入到内存管理结构体的映射列表中
    insert_vma_struct(mm, vma);
ffffffffc0201358:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags; // 设置标志
ffffffffc020135a:	00fa3c23          	sd	a5,24(s4)
    insert_vma_struct(mm, vma);
ffffffffc020135e:	8522                	mv	a0,s0
        vma->vm_start = vm_start; // 设置起始地址
ffffffffc0201360:	000a3423          	sd	zero,8(s4)
    insert_vma_struct(mm, vma);
ffffffffc0201364:	c81ff0ef          	jal	ra,ffffffffc0200fe4 <insert_vma_struct>

    // 定义一个测试地址
    uintptr_t addr = 0x100;
    // 断言找到的虚拟内存区域是预期的区域
    assert(find_vma(mm, addr) == vma);
ffffffffc0201368:	10000593          	li	a1,256
ffffffffc020136c:	8522                	mv	a0,s0
ffffffffc020136e:	c37ff0ef          	jal	ra,ffffffffc0200fa4 <find_vma>
ffffffffc0201372:	10000793          	li	a5,256

    // 测试写入和读取内存
    int i, sum = 0;
    for (i = 0; i < 100; i ++) {
ffffffffc0201376:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc020137a:	26aa1863          	bne	s4,a0,ffffffffc02015ea <vmm_init+0x500>
        *(char *)(addr + i) = i;
ffffffffc020137e:	00f78023          	sb	a5,0(a5) # 200000 <kern_entry-0xffffffffc0000000>
    for (i = 0; i < 100; i ++) {
ffffffffc0201382:	0785                	addi	a5,a5,1
ffffffffc0201384:	fee79de3          	bne	a5,a4,ffffffffc020137e <vmm_init+0x294>
        sum += i;
ffffffffc0201388:	6705                	lui	a4,0x1
ffffffffc020138a:	10000793          	li	a5,256
ffffffffc020138e:	35670713          	addi	a4,a4,854 # 1356 <kern_entry-0xffffffffc01fecaa>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc0201392:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc0201396:	0007c683          	lbu	a3,0(a5)
    for (i = 0; i < 100; i ++) {
ffffffffc020139a:	0785                	addi	a5,a5,1
        sum -= *(char *)(addr + i);
ffffffffc020139c:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc020139e:	fec79ce3          	bne	a5,a2,ffffffffc0201396 <vmm_init+0x2ac>
    }
    // 断言读取和写入操作是正确的
    assert(sum == 0);
ffffffffc02013a2:	26071463          	bnez	a4,ffffffffc020160a <vmm_init+0x520>

    // 从页目录中移除页面
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc02013a6:	4581                	li	a1,0
ffffffffc02013a8:	854a                	mv	a0,s2
ffffffffc02013aa:	263010ef          	jal	ra,ffffffffc0202e0c <page_remove>
    return pa2page(PTE_ADDR(pte)); // 提取页表项的物理地址并转换为 Page 结构体指针
}

// 根据页目录项 (PDE) 获取对应的 Page 结构体指针
static inline struct Page *pde2page(pde_t pde) {
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc02013ae:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc02013b2:	00010717          	auipc	a4,0x10
ffffffffc02013b6:	19673703          	ld	a4,406(a4) # ffffffffc0211548 <npage>
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc02013ba:	078a                	slli	a5,a5,0x2
ffffffffc02013bc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc02013be:	26e7f663          	bgeu	a5,a4,ffffffffc020162a <vmm_init+0x540>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc02013c2:	00005717          	auipc	a4,0x5
ffffffffc02013c6:	f8673703          	ld	a4,-122(a4) # ffffffffc0206348 <nbase>
ffffffffc02013ca:	8f99                	sub	a5,a5,a4
ffffffffc02013cc:	00379713          	slli	a4,a5,0x3
ffffffffc02013d0:	97ba                	add	a5,a5,a4
ffffffffc02013d2:	078e                	slli	a5,a5,0x3

    // 释放页目录中的第一个页表页面
    free_page(pde2page(pgdir[0]));
ffffffffc02013d4:	00010517          	auipc	a0,0x10
ffffffffc02013d8:	17c53503          	ld	a0,380(a0) # ffffffffc0211550 <pages>
ffffffffc02013dc:	953e                	add	a0,a0,a5
ffffffffc02013de:	4585                	li	a1,1
ffffffffc02013e0:	762010ef          	jal	ra,ffffffffc0202b42 <free_pages>
    return listelm->next;
ffffffffc02013e4:	6408                	ld	a0,8(s0)

    // 将页目录的第一个条目设置为0
    pgdir[0] = 0;
ffffffffc02013e6:	00093023          	sd	zero,0(s2)

    // 将内存管理结构体的页目录指针设置为NULL
    mm->pgdir = NULL;
ffffffffc02013ea:	00043c23          	sd	zero,24(s0)
    while ((le = list_next(list)) != list) {
ffffffffc02013ee:	00a40e63          	beq	s0,a0,ffffffffc020140a <vmm_init+0x320>
    __list_del(listelm->prev, listelm->next);
ffffffffc02013f2:	6118                	ld	a4,0(a0)
ffffffffc02013f4:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  
ffffffffc02013f6:	03000593          	li	a1,48
ffffffffc02013fa:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02013fc:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02013fe:	e398                	sd	a4,0(a5)
ffffffffc0201400:	0f1020ef          	jal	ra,ffffffffc0203cf0 <kfree>
    return listelm->next;
ffffffffc0201404:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0201406:	fea416e3          	bne	s0,a0,ffffffffc02013f2 <vmm_init+0x308>
    kfree(mm, sizeof(struct mm_struct)); 
ffffffffc020140a:	03000593          	li	a1,48
ffffffffc020140e:	8522                	mv	a0,s0
ffffffffc0201410:	0e1020ef          	jal	ra,ffffffffc0203cf0 <kfree>
    mm_destroy(mm);

    // 将检查用的内存管理结构体指针设置为NULL
    check_mm_struct = NULL;
    // Szx: Sv39第二级页表多占用了一个内存页，因此执行此操作
    nr_free_pages_store--;
ffffffffc0201414:	14fd                	addi	s1,s1,-1
    check_mm_struct = NULL;
ffffffffc0201416:	00010797          	auipc	a5,0x10
ffffffffc020141a:	0e07bd23          	sd	zero,250(a5) # ffffffffc0211510 <check_mm_struct>

    // 断言空闲页面数没有变化，确保上面的操作没有影响内存分配
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc020141e:	764010ef          	jal	ra,ffffffffc0202b82 <nr_free_pages>
ffffffffc0201422:	22a49063          	bne	s1,a0,ffffffffc0201642 <vmm_init+0x558>

    // 打印检查成功的消息
    cprintf("check_pgfault() succeeded!\n");
ffffffffc0201426:	00004517          	auipc	a0,0x4
ffffffffc020142a:	e3a50513          	addi	a0,a0,-454 # ffffffffc0205260 <commands+0xb58>
ffffffffc020142e:	c8dfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0201432:	750010ef          	jal	ra,ffffffffc0202b82 <nr_free_pages>
    nr_free_pages_store--;	
ffffffffc0201436:	19fd                	addi	s3,s3,-1
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0201438:	22a99563          	bne	s3,a0,ffffffffc0201662 <vmm_init+0x578>
}
ffffffffc020143c:	6406                	ld	s0,64(sp)
ffffffffc020143e:	60a6                	ld	ra,72(sp)
ffffffffc0201440:	74e2                	ld	s1,56(sp)
ffffffffc0201442:	7942                	ld	s2,48(sp)
ffffffffc0201444:	79a2                	ld	s3,40(sp)
ffffffffc0201446:	7a02                	ld	s4,32(sp)
ffffffffc0201448:	6ae2                	ld	s5,24(sp)
ffffffffc020144a:	6b42                	ld	s6,16(sp)
ffffffffc020144c:	6ba2                	ld	s7,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc020144e:	00004517          	auipc	a0,0x4
ffffffffc0201452:	e3250513          	addi	a0,a0,-462 # ffffffffc0205280 <commands+0xb78>
}
ffffffffc0201456:	6161                	addi	sp,sp,80
    cprintf("check_vmm() succeeded.\n");
ffffffffc0201458:	c63fe06f          	j	ffffffffc02000ba <cprintf>
        if (swap_init_ok) swap_init_mm(mm); // 如果启用了交换空间，则初始化 mm 的交换空间
ffffffffc020145c:	19f000ef          	jal	ra,ffffffffc0201dfa <swap_init_mm>
ffffffffc0201460:	b5d1                	j	ffffffffc0201324 <vmm_init+0x23a>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0201462:	00004697          	auipc	a3,0x4
ffffffffc0201466:	c1e68693          	addi	a3,a3,-994 # ffffffffc0205080 <commands+0x978>
ffffffffc020146a:	00004617          	auipc	a2,0x4
ffffffffc020146e:	9b660613          	addi	a2,a2,-1610 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201472:	0ff00593          	li	a1,255
ffffffffc0201476:	00004517          	auipc	a0,0x4
ffffffffc020147a:	b8250513          	addi	a0,a0,-1150 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc020147e:	c85fe0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0201482:	00004697          	auipc	a3,0x4
ffffffffc0201486:	cb668693          	addi	a3,a3,-842 # ffffffffc0205138 <commands+0xa30>
ffffffffc020148a:	00004617          	auipc	a2,0x4
ffffffffc020148e:	99660613          	addi	a2,a2,-1642 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201492:	11100593          	li	a1,273
ffffffffc0201496:	00004517          	auipc	a0,0x4
ffffffffc020149a:	b6250513          	addi	a0,a0,-1182 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc020149e:	c65fe0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc02014a2:	00004697          	auipc	a3,0x4
ffffffffc02014a6:	c6668693          	addi	a3,a3,-922 # ffffffffc0205108 <commands+0xa00>
ffffffffc02014aa:	00004617          	auipc	a2,0x4
ffffffffc02014ae:	97660613          	addi	a2,a2,-1674 # ffffffffc0204e20 <commands+0x718>
ffffffffc02014b2:	11000593          	li	a1,272
ffffffffc02014b6:	00004517          	auipc	a0,0x4
ffffffffc02014ba:	b4250513          	addi	a0,a0,-1214 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc02014be:	c45fe0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc02014c2:	00004697          	auipc	a3,0x4
ffffffffc02014c6:	ba668693          	addi	a3,a3,-1114 # ffffffffc0205068 <commands+0x960>
ffffffffc02014ca:	00004617          	auipc	a2,0x4
ffffffffc02014ce:	95660613          	addi	a2,a2,-1706 # ffffffffc0204e20 <commands+0x718>
ffffffffc02014d2:	0fc00593          	li	a1,252
ffffffffc02014d6:	00004517          	auipc	a0,0x4
ffffffffc02014da:	b2250513          	addi	a0,a0,-1246 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc02014de:	c25fe0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma1 != NULL);
ffffffffc02014e2:	00004697          	auipc	a3,0x4
ffffffffc02014e6:	bd668693          	addi	a3,a3,-1066 # ffffffffc02050b8 <commands+0x9b0>
ffffffffc02014ea:	00004617          	auipc	a2,0x4
ffffffffc02014ee:	93660613          	addi	a2,a2,-1738 # ffffffffc0204e20 <commands+0x718>
ffffffffc02014f2:	10600593          	li	a1,262
ffffffffc02014f6:	00004517          	auipc	a0,0x4
ffffffffc02014fa:	b0250513          	addi	a0,a0,-1278 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc02014fe:	c05fe0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma2 != NULL);
ffffffffc0201502:	00004697          	auipc	a3,0x4
ffffffffc0201506:	bc668693          	addi	a3,a3,-1082 # ffffffffc02050c8 <commands+0x9c0>
ffffffffc020150a:	00004617          	auipc	a2,0x4
ffffffffc020150e:	91660613          	addi	a2,a2,-1770 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201512:	10800593          	li	a1,264
ffffffffc0201516:	00004517          	auipc	a0,0x4
ffffffffc020151a:	ae250513          	addi	a0,a0,-1310 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc020151e:	be5fe0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma3 == NULL);
ffffffffc0201522:	00004697          	auipc	a3,0x4
ffffffffc0201526:	bb668693          	addi	a3,a3,-1098 # ffffffffc02050d8 <commands+0x9d0>
ffffffffc020152a:	00004617          	auipc	a2,0x4
ffffffffc020152e:	8f660613          	addi	a2,a2,-1802 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201532:	10a00593          	li	a1,266
ffffffffc0201536:	00004517          	auipc	a0,0x4
ffffffffc020153a:	ac250513          	addi	a0,a0,-1342 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc020153e:	bc5fe0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma4 == NULL);
ffffffffc0201542:	00004697          	auipc	a3,0x4
ffffffffc0201546:	ba668693          	addi	a3,a3,-1114 # ffffffffc02050e8 <commands+0x9e0>
ffffffffc020154a:	00004617          	auipc	a2,0x4
ffffffffc020154e:	8d660613          	addi	a2,a2,-1834 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201552:	10c00593          	li	a1,268
ffffffffc0201556:	00004517          	auipc	a0,0x4
ffffffffc020155a:	aa250513          	addi	a0,a0,-1374 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc020155e:	ba5fe0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma5 == NULL);
ffffffffc0201562:	00004697          	auipc	a3,0x4
ffffffffc0201566:	b9668693          	addi	a3,a3,-1130 # ffffffffc02050f8 <commands+0x9f0>
ffffffffc020156a:	00004617          	auipc	a2,0x4
ffffffffc020156e:	8b660613          	addi	a2,a2,-1866 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201572:	10e00593          	li	a1,270
ffffffffc0201576:	00004517          	auipc	a0,0x4
ffffffffc020157a:	a8250513          	addi	a0,a0,-1406 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc020157e:	b85fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0201582:	00004697          	auipc	a3,0x4
ffffffffc0201586:	c6e68693          	addi	a3,a3,-914 # ffffffffc02051f0 <commands+0xae8>
ffffffffc020158a:	00004617          	auipc	a2,0x4
ffffffffc020158e:	89660613          	addi	a2,a2,-1898 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201592:	13700593          	li	a1,311
ffffffffc0201596:	00004517          	auipc	a0,0x4
ffffffffc020159a:	a6250513          	addi	a0,a0,-1438 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc020159e:	b65fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc02015a2:	00004697          	auipc	a3,0x4
ffffffffc02015a6:	d0668693          	addi	a3,a3,-762 # ffffffffc02052a8 <commands+0xba0>
ffffffffc02015aa:	00004617          	auipc	a2,0x4
ffffffffc02015ae:	87660613          	addi	a2,a2,-1930 # ffffffffc0204e20 <commands+0x718>
ffffffffc02015b2:	13200593          	li	a1,306
ffffffffc02015b6:	00004517          	auipc	a0,0x4
ffffffffc02015ba:	a4250513          	addi	a0,a0,-1470 # ffffffffc0204ff8 <commands+0x8f0>
    check_mm_struct = mm_create();
ffffffffc02015be:	00010797          	auipc	a5,0x10
ffffffffc02015c2:	f407b923          	sd	zero,-174(a5) # ffffffffc0211510 <check_mm_struct>
    assert(check_mm_struct != NULL);
ffffffffc02015c6:	b3dfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(vma != NULL);
ffffffffc02015ca:	00004697          	auipc	a3,0x4
ffffffffc02015ce:	cce68693          	addi	a3,a3,-818 # ffffffffc0205298 <commands+0xb90>
ffffffffc02015d2:	00004617          	auipc	a2,0x4
ffffffffc02015d6:	84e60613          	addi	a2,a2,-1970 # ffffffffc0204e20 <commands+0x718>
ffffffffc02015da:	13c00593          	li	a1,316
ffffffffc02015de:	00004517          	auipc	a0,0x4
ffffffffc02015e2:	a1a50513          	addi	a0,a0,-1510 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc02015e6:	b1dfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc02015ea:	00004697          	auipc	a3,0x4
ffffffffc02015ee:	c1668693          	addi	a3,a3,-1002 # ffffffffc0205200 <commands+0xaf8>
ffffffffc02015f2:	00004617          	auipc	a2,0x4
ffffffffc02015f6:	82e60613          	addi	a2,a2,-2002 # ffffffffc0204e20 <commands+0x718>
ffffffffc02015fa:	14400593          	li	a1,324
ffffffffc02015fe:	00004517          	auipc	a0,0x4
ffffffffc0201602:	9fa50513          	addi	a0,a0,-1542 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc0201606:	afdfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(sum == 0);
ffffffffc020160a:	00004697          	auipc	a3,0x4
ffffffffc020160e:	c1668693          	addi	a3,a3,-1002 # ffffffffc0205220 <commands+0xb18>
ffffffffc0201612:	00004617          	auipc	a2,0x4
ffffffffc0201616:	80e60613          	addi	a2,a2,-2034 # ffffffffc0204e20 <commands+0x718>
ffffffffc020161a:	15000593          	li	a1,336
ffffffffc020161e:	00004517          	auipc	a0,0x4
ffffffffc0201622:	9da50513          	addi	a0,a0,-1574 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc0201626:	addfe0ef          	jal	ra,ffffffffc0200102 <__panic>
        panic("pa2page called with invalid pa"); // 如果无效，触发 panic
ffffffffc020162a:	00004617          	auipc	a2,0x4
ffffffffc020162e:	c0660613          	addi	a2,a2,-1018 # ffffffffc0205230 <commands+0xb28>
ffffffffc0201632:	07000593          	li	a1,112
ffffffffc0201636:	00004517          	auipc	a0,0x4
ffffffffc020163a:	c1a50513          	addi	a0,a0,-998 # ffffffffc0205250 <commands+0xb48>
ffffffffc020163e:	ac5fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0201642:	00004697          	auipc	a3,0x4
ffffffffc0201646:	b6668693          	addi	a3,a3,-1178 # ffffffffc02051a8 <commands+0xaa0>
ffffffffc020164a:	00003617          	auipc	a2,0x3
ffffffffc020164e:	7d660613          	addi	a2,a2,2006 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201652:	16600593          	li	a1,358
ffffffffc0201656:	00004517          	auipc	a0,0x4
ffffffffc020165a:	9a250513          	addi	a0,a0,-1630 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc020165e:	aa5fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0201662:	00004697          	auipc	a3,0x4
ffffffffc0201666:	b4668693          	addi	a3,a3,-1210 # ffffffffc02051a8 <commands+0xaa0>
ffffffffc020166a:	00003617          	auipc	a2,0x3
ffffffffc020166e:	7b660613          	addi	a2,a2,1974 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201672:	0d200593          	li	a1,210
ffffffffc0201676:	00004517          	auipc	a0,0x4
ffffffffc020167a:	98250513          	addi	a0,a0,-1662 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc020167e:	a85fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(mm != NULL);
ffffffffc0201682:	00004697          	auipc	a3,0x4
ffffffffc0201686:	c3e68693          	addi	a3,a3,-962 # ffffffffc02052c0 <commands+0xbb8>
ffffffffc020168a:	00003617          	auipc	a2,0x3
ffffffffc020168e:	79660613          	addi	a2,a2,1942 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201692:	0e000593          	li	a1,224
ffffffffc0201696:	00004517          	auipc	a0,0x4
ffffffffc020169a:	96250513          	addi	a0,a0,-1694 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc020169e:	a65fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02016a2:	00004697          	auipc	a3,0x4
ffffffffc02016a6:	b0668693          	addi	a3,a3,-1274 # ffffffffc02051a8 <commands+0xaa0>
ffffffffc02016aa:	00003617          	auipc	a2,0x3
ffffffffc02016ae:	77660613          	addi	a2,a2,1910 # ffffffffc0204e20 <commands+0x718>
ffffffffc02016b2:	12100593          	li	a1,289
ffffffffc02016b6:	00004517          	auipc	a0,0x4
ffffffffc02016ba:	94250513          	addi	a0,a0,-1726 # ffffffffc0204ff8 <commands+0x8f0>
ffffffffc02016be:	a45fe0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc02016c2 <do_pgfault>:
 *   - P 位（位 0）：表示页面不在（0）或访问权限错误（1）
 *   - W/R 位（位 1）：标识引发异常的内存访问是读取（0）还是写入（1）
 *   - U/S 位（位 2）：标识异常发生时是否在用户模式（1）或 supervisor 模式（0）
 */ 
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc02016c2:	7179                	addi	sp,sp,-48
    int ret = -E_INVAL;
    // 尝试找到一个包含 addr 的 vma
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc02016c4:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc02016c6:	f022                	sd	s0,32(sp)
ffffffffc02016c8:	ec26                	sd	s1,24(sp)
ffffffffc02016ca:	f406                	sd	ra,40(sp)
ffffffffc02016cc:	e84a                	sd	s2,16(sp)
ffffffffc02016ce:	8432                	mv	s0,a2
ffffffffc02016d0:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc02016d2:	8d3ff0ef          	jal	ra,ffffffffc0200fa4 <find_vma>

    pgfault_num++;
ffffffffc02016d6:	00010797          	auipc	a5,0x10
ffffffffc02016da:	e427a783          	lw	a5,-446(a5) # ffffffffc0211518 <pgfault_num>
ffffffffc02016de:	2785                	addiw	a5,a5,1
ffffffffc02016e0:	00010717          	auipc	a4,0x10
ffffffffc02016e4:	e2f72c23          	sw	a5,-456(a4) # ffffffffc0211518 <pgfault_num>
    // 如果 addr 在 mm 的某个 vma 范围内？
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc02016e8:	c159                	beqz	a0,ffffffffc020176e <do_pgfault+0xac>
ffffffffc02016ea:	651c                	ld	a5,8(a0)
ffffffffc02016ec:	08f46163          	bltu	s0,a5,ffffffffc020176e <do_pgfault+0xac>
    /*
     * 根据 vma 的标志，设置页表权限位 perm
     * 若 vma 可写，则权限包含 PTE_W；否则仅包含 PTE_R 和 PTE_U
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc02016f0:	6d1c                	ld	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc02016f2:	4941                	li	s2,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc02016f4:	8b89                	andi	a5,a5,2
ffffffffc02016f6:	ebb1                	bnez	a5,ffffffffc020174a <do_pgfault+0x88>
        perm |= (PTE_R | PTE_W);
    }
    addr = ROUNDDOWN(addr, PGSIZE);// 将 addr 对齐到页边界
ffffffffc02016f8:	75fd                	lui	a1,0xfffff
    *   PTE_U           0x004                   // 页表/目录项标志位：用户可访问
    * 变量：
    *   mm->pgdir : 这些 vma 的 PDT
    */

    ptep = get_pte(mm->pgdir, addr, 1); //尝试找到一个 pte，如果 pte 的PT（页表）不存在，则创建一个 PT。
ffffffffc02016fa:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);// 将 addr 对齐到页边界
ffffffffc02016fc:	8c6d                	and	s0,s0,a1
    ptep = get_pte(mm->pgdir, addr, 1); //尝试找到一个 pte，如果 pte 的PT（页表）不存在，则创建一个 PT。
ffffffffc02016fe:	85a2                	mv	a1,s0
ffffffffc0201700:	4605                	li	a2,1
ffffffffc0201702:	4ba010ef          	jal	ra,ffffffffc0202bbc <get_pte>
    if (*ptep == 0) {// 如果 pte 尚未映射任何页面
ffffffffc0201706:	610c                	ld	a1,0(a0)
ffffffffc0201708:	c1b9                	beqz	a1,ffffffffc020174e <do_pgfault+0x8c>
        * 宏或函数：
        *    swap_in(mm, addr, &page) : 分配一个内存页，从PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个 Page 的 phy addr 与线性 addr la 的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc020170a:	00010797          	auipc	a5,0x10
ffffffffc020170e:	e267a783          	lw	a5,-474(a5) # ffffffffc0211530 <swap_init_ok>
ffffffffc0201712:	c7bd                	beqz	a5,ffffffffc0201780 <do_pgfault+0xbe>
            struct Page *page = NULL;
            // 你要编写的内容在这里
            // (1) 根据 mm 和 addr，尝试加载磁盘页的内容到由 page 管理的内存中。
            swap_in(mm,addr,&page);//调用swap_in函数从磁盘上读取数据
ffffffffc0201714:	85a2                	mv	a1,s0
ffffffffc0201716:	0030                	addi	a2,sp,8
ffffffffc0201718:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc020171a:	e402                	sd	zero,8(sp)
            swap_in(mm,addr,&page);//调用swap_in函数从磁盘上读取数据
ffffffffc020171c:	00b000ef          	jal	ra,ffffffffc0201f26 <swap_in>
            // (2) 根据 mm，addr 和 page，设置物理地址 phy addr 与逻辑地址的映射
            // (3) 使页面可交换。交换成功，则建立物理地址<--->虚拟地址映射，并将页设置为可交换的
            page_insert(mm->pgdir, page, addr, perm);
ffffffffc0201720:	65a2                	ld	a1,8(sp)
ffffffffc0201722:	6c88                	ld	a0,24(s1)
ffffffffc0201724:	86ca                	mv	a3,s2
ffffffffc0201726:	8622                	mv	a2,s0
ffffffffc0201728:	77e010ef          	jal	ra,ffffffffc0202ea6 <page_insert>
            swap_map_swappable(mm, addr, page, 1);//将物理页设置为可交换状态
ffffffffc020172c:	6622                	ld	a2,8(sp)
ffffffffc020172e:	4685                	li	a3,1
ffffffffc0201730:	85a2                	mv	a1,s0
ffffffffc0201732:	8526                	mv	a0,s1
ffffffffc0201734:	6d2000ef          	jal	ra,ffffffffc0201e06 <swap_map_swappable>
            page->pra_vaddr = addr;
ffffffffc0201738:	67a2                	ld	a5,8(sp)
        } else {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
    } 
    ret = 0;
ffffffffc020173a:	4501                	li	a0,0
            page->pra_vaddr = addr;
ffffffffc020173c:	e3a0                	sd	s0,64(a5)
failed:
    return ret;
}
ffffffffc020173e:	70a2                	ld	ra,40(sp)
ffffffffc0201740:	7402                	ld	s0,32(sp)
ffffffffc0201742:	64e2                	ld	s1,24(sp)
ffffffffc0201744:	6942                	ld	s2,16(sp)
ffffffffc0201746:	6145                	addi	sp,sp,48
ffffffffc0201748:	8082                	ret
        perm |= (PTE_R | PTE_W);
ffffffffc020174a:	4959                	li	s2,22
ffffffffc020174c:	b775                	j	ffffffffc02016f8 <do_pgfault+0x36>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) { // 分配新页面并映射
ffffffffc020174e:	6c88                	ld	a0,24(s1)
ffffffffc0201750:	864a                	mv	a2,s2
ffffffffc0201752:	85a2                	mv	a1,s0
ffffffffc0201754:	42a020ef          	jal	ra,ffffffffc0203b7e <pgdir_alloc_page>
ffffffffc0201758:	87aa                	mv	a5,a0
    ret = 0;
ffffffffc020175a:	4501                	li	a0,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) { // 分配新页面并映射
ffffffffc020175c:	f3ed                	bnez	a5,ffffffffc020173e <do_pgfault+0x7c>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc020175e:	00004517          	auipc	a0,0x4
ffffffffc0201762:	ba250513          	addi	a0,a0,-1118 # ffffffffc0205300 <commands+0xbf8>
ffffffffc0201766:	955fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    ret = -E_NO_MEM; // 若内存不足时返回该错误
ffffffffc020176a:	5571                	li	a0,-4
            goto failed;
ffffffffc020176c:	bfc9                	j	ffffffffc020173e <do_pgfault+0x7c>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc020176e:	85a2                	mv	a1,s0
ffffffffc0201770:	00004517          	auipc	a0,0x4
ffffffffc0201774:	b6050513          	addi	a0,a0,-1184 # ffffffffc02052d0 <commands+0xbc8>
ffffffffc0201778:	943fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    int ret = -E_INVAL;
ffffffffc020177c:	5575                	li	a0,-3
        goto failed;
ffffffffc020177e:	b7c1                	j	ffffffffc020173e <do_pgfault+0x7c>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0201780:	00004517          	auipc	a0,0x4
ffffffffc0201784:	ba850513          	addi	a0,a0,-1112 # ffffffffc0205328 <commands+0xc20>
ffffffffc0201788:	933fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    ret = -E_NO_MEM; // 若内存不足时返回该错误
ffffffffc020178c:	5571                	li	a0,-4
            goto failed;
ffffffffc020178e:	bf45                	j	ffffffffc020173e <do_pgfault+0x7c>

ffffffffc0201790 <swap_init>:

static void check_swap(void); // 声明检查交换的静态函数

int
swap_init(void)
{
ffffffffc0201790:	7135                	addi	sp,sp,-160
ffffffffc0201792:	ed06                	sd	ra,152(sp)
ffffffffc0201794:	e922                	sd	s0,144(sp)
ffffffffc0201796:	e526                	sd	s1,136(sp)
ffffffffc0201798:	e14a                	sd	s2,128(sp)
ffffffffc020179a:	fcce                	sd	s3,120(sp)
ffffffffc020179c:	f8d2                	sd	s4,112(sp)
ffffffffc020179e:	f4d6                	sd	s5,104(sp)
ffffffffc02017a0:	f0da                	sd	s6,96(sp)
ffffffffc02017a2:	ecde                	sd	s7,88(sp)
ffffffffc02017a4:	e8e2                	sd	s8,80(sp)
ffffffffc02017a6:	e4e6                	sd	s9,72(sp)
ffffffffc02017a8:	e0ea                	sd	s10,64(sp)
ffffffffc02017aa:	fc6e                	sd	s11,56(sp)
     swapfs_init(); // 初始化交换文件系统
ffffffffc02017ac:	62c020ef          	jal	ra,ffffffffc0203dd8 <swapfs_init>

     // 检查交换偏移量是否能够在模拟的IDE中存储至少7个页面以通过测试
     if (!(7 <= max_swap_offset &&
ffffffffc02017b0:	00010697          	auipc	a3,0x10
ffffffffc02017b4:	d706b683          	ld	a3,-656(a3) # ffffffffc0211520 <max_swap_offset>
ffffffffc02017b8:	010007b7          	lui	a5,0x1000
ffffffffc02017bc:	ff968713          	addi	a4,a3,-7
ffffffffc02017c0:	17e1                	addi	a5,a5,-8
ffffffffc02017c2:	3ee7e063          	bltu	a5,a4,ffffffffc0201ba2 <swap_init+0x412>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset); // 如果不在预期范围内，触发panic
     }

     sm = &swap_manager_lru; // 设置交换管理器为clock替换算法
ffffffffc02017c6:	00009797          	auipc	a5,0x9
ffffffffc02017ca:	83a78793          	addi	a5,a5,-1990 # ffffffffc020a000 <swap_manager_lru>
     int r = sm->init(); // 调用交换管理器的初始化函数
ffffffffc02017ce:	6798                	ld	a4,8(a5)
     sm = &swap_manager_lru; // 设置交换管理器为clock替换算法
ffffffffc02017d0:	00010b17          	auipc	s6,0x10
ffffffffc02017d4:	d58b0b13          	addi	s6,s6,-680 # ffffffffc0211528 <sm>
ffffffffc02017d8:	00fb3023          	sd	a5,0(s6)
     int r = sm->init(); // 调用交换管理器的初始化函数
ffffffffc02017dc:	9702                	jalr	a4
ffffffffc02017de:	89aa                	mv	s3,a0
     
     if (r == 0) // 如果初始化成功
ffffffffc02017e0:	c10d                	beqz	a0,ffffffffc0201802 <swap_init+0x72>
          cprintf("SWAP: manager = %s\n", sm->name); // 打印交换管理器的名称
          check_swap(); // 调用检查交换的函数
     }

     return r; // 返回初始化结果
}
ffffffffc02017e2:	60ea                	ld	ra,152(sp)
ffffffffc02017e4:	644a                	ld	s0,144(sp)
ffffffffc02017e6:	64aa                	ld	s1,136(sp)
ffffffffc02017e8:	690a                	ld	s2,128(sp)
ffffffffc02017ea:	7a46                	ld	s4,112(sp)
ffffffffc02017ec:	7aa6                	ld	s5,104(sp)
ffffffffc02017ee:	7b06                	ld	s6,96(sp)
ffffffffc02017f0:	6be6                	ld	s7,88(sp)
ffffffffc02017f2:	6c46                	ld	s8,80(sp)
ffffffffc02017f4:	6ca6                	ld	s9,72(sp)
ffffffffc02017f6:	6d06                	ld	s10,64(sp)
ffffffffc02017f8:	7de2                	ld	s11,56(sp)
ffffffffc02017fa:	854e                	mv	a0,s3
ffffffffc02017fc:	79e6                	ld	s3,120(sp)
ffffffffc02017fe:	610d                	addi	sp,sp,160
ffffffffc0201800:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name); // 打印交换管理器的名称
ffffffffc0201802:	000b3783          	ld	a5,0(s6)
ffffffffc0201806:	00004517          	auipc	a0,0x4
ffffffffc020180a:	b7a50513          	addi	a0,a0,-1158 # ffffffffc0205380 <commands+0xc78>
ffffffffc020180e:	00010497          	auipc	s1,0x10
ffffffffc0201812:	8d248493          	addi	s1,s1,-1838 # ffffffffc02110e0 <free_area>
ffffffffc0201816:	638c                	ld	a1,0(a5)
          swap_init_ok = 1; // 设置交换初始化成功的全局标志
ffffffffc0201818:	4785                	li	a5,1
ffffffffc020181a:	00010717          	auipc	a4,0x10
ffffffffc020181e:	d0f72b23          	sw	a5,-746(a4) # ffffffffc0211530 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name); // 打印交换管理器的名称
ffffffffc0201822:	899fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0201826:	649c                	ld	a5,8(s1)

// 定义一个静态函数，用于检查页面交换机制是否正常工作
static void
check_swap(void) {
    // 备份当前内存环境
    int ret, count = 0, total = 0, i;
ffffffffc0201828:	4401                	li	s0,0
ffffffffc020182a:	4d01                	li	s10,0
    list_entry_t *le = &free_list; // 指向空闲页面链表的头部
    while ((le = list_next(le)) != &free_list) {
ffffffffc020182c:	2c978163          	beq	a5,s1,ffffffffc0201aee <swap_init+0x35e>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201830:	fe87b703          	ld	a4,-24(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p)); // 确保页面属性正确
ffffffffc0201834:	8b09                	andi	a4,a4,2
ffffffffc0201836:	2a070e63          	beqz	a4,ffffffffc0201af2 <swap_init+0x362>
        count ++, total += p->property;
ffffffffc020183a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020183e:	679c                	ld	a5,8(a5)
ffffffffc0201840:	2d05                	addiw	s10,s10,1
ffffffffc0201842:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201844:	fe9796e3          	bne	a5,s1,ffffffffc0201830 <swap_init+0xa0>
    }
    assert(total == nr_free_pages()); // 确保空闲页面总数正确
ffffffffc0201848:	8922                	mv	s2,s0
ffffffffc020184a:	338010ef          	jal	ra,ffffffffc0202b82 <nr_free_pages>
ffffffffc020184e:	47251663          	bne	a0,s2,ffffffffc0201cba <swap_init+0x52a>
    cprintf("BEGIN check_swap: count %d, total %d\n", count, total);
ffffffffc0201852:	8622                	mv	a2,s0
ffffffffc0201854:	85ea                	mv	a1,s10
ffffffffc0201856:	00004517          	auipc	a0,0x4
ffffffffc020185a:	b7250513          	addi	a0,a0,-1166 # ffffffffc02053c8 <commands+0xcc0>
ffffffffc020185e:	85dfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
     
    // 设置物理页面环境
    struct mm_struct *mm = mm_create(); // 创建内存管理结构
ffffffffc0201862:	eccff0ef          	jal	ra,ffffffffc0200f2e <mm_create>
ffffffffc0201866:	8aaa                	mv	s5,a0
    assert(mm != NULL);
ffffffffc0201868:	52050963          	beqz	a0,ffffffffc0201d9a <swap_init+0x60a>

    extern struct mm_struct *check_mm_struct;
    assert(check_mm_struct == NULL); // 确保之前没有设置过检查用的内存管理结构
ffffffffc020186c:	00010797          	auipc	a5,0x10
ffffffffc0201870:	ca478793          	addi	a5,a5,-860 # ffffffffc0211510 <check_mm_struct>
ffffffffc0201874:	6398                	ld	a4,0(a5)
ffffffffc0201876:	54071263          	bnez	a4,ffffffffc0201dba <swap_init+0x62a>

    check_mm_struct = mm; // 设置当前的内存管理结构为检查用的内存管理结构

    pde_t *pgdir = mm->pgdir = boot_pgdir; // 设置页目录
ffffffffc020187a:	00010b97          	auipc	s7,0x10
ffffffffc020187e:	cc6bbb83          	ld	s7,-826(s7) # ffffffffc0211540 <boot_pgdir>
    assert(pgdir[0] == 0); // 确保页目录的第一项是空的
ffffffffc0201882:	000bb703          	ld	a4,0(s7)
    check_mm_struct = mm; // 设置当前的内存管理结构为检查用的内存管理结构
ffffffffc0201886:	e388                	sd	a0,0(a5)
    pde_t *pgdir = mm->pgdir = boot_pgdir; // 设置页目录
ffffffffc0201888:	01753c23          	sd	s7,24(a0)
    assert(pgdir[0] == 0); // 确保页目录的第一项是空的
ffffffffc020188c:	3c071763          	bnez	a4,ffffffffc0201c5a <swap_init+0x4ca>

    struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ); // 创建虚拟内存区域
ffffffffc0201890:	6599                	lui	a1,0x6
ffffffffc0201892:	460d                	li	a2,3
ffffffffc0201894:	6505                	lui	a0,0x1
ffffffffc0201896:	ee0ff0ef          	jal	ra,ffffffffc0200f76 <vma_create>
ffffffffc020189a:	85aa                	mv	a1,a0
    assert(vma != NULL);
ffffffffc020189c:	3c050f63          	beqz	a0,ffffffffc0201c7a <swap_init+0x4ea>

    insert_vma_struct(mm, vma); // 将虚拟内存区域插入内存管理结构
ffffffffc02018a0:	8556                	mv	a0,s5
ffffffffc02018a2:	f42ff0ef          	jal	ra,ffffffffc0200fe4 <insert_vma_struct>

    // 设置临时页表，用于虚拟地址0~4MB
    cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc02018a6:	00004517          	auipc	a0,0x4
ffffffffc02018aa:	b6250513          	addi	a0,a0,-1182 # ffffffffc0205408 <commands+0xd00>
ffffffffc02018ae:	80dfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    pte_t *temp_ptep = NULL;
    temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1); // 获取页表条目
ffffffffc02018b2:	018ab503          	ld	a0,24(s5)
ffffffffc02018b6:	4605                	li	a2,1
ffffffffc02018b8:	6585                	lui	a1,0x1
ffffffffc02018ba:	302010ef          	jal	ra,ffffffffc0202bbc <get_pte>
    assert(temp_ptep != NULL); // 确保页表条目获取成功
ffffffffc02018be:	3c050e63          	beqz	a0,ffffffffc0201c9a <swap_init+0x50a>
    cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02018c2:	00004517          	auipc	a0,0x4
ffffffffc02018c6:	b9650513          	addi	a0,a0,-1130 # ffffffffc0205458 <commands+0xd50>
ffffffffc02018ca:	0000f917          	auipc	s2,0xf
ffffffffc02018ce:	7a690913          	addi	s2,s2,1958 # ffffffffc0211070 <check_rp>
ffffffffc02018d2:	fe8fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
     
    for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
ffffffffc02018d6:	0000fa17          	auipc	s4,0xf
ffffffffc02018da:	7baa0a13          	addi	s4,s4,1978 # ffffffffc0211090 <swap_in_seq_no>
    cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02018de:	8c4a                	mv	s8,s2
        check_rp[i] = alloc_page(); // 分配检查用的物理页面
ffffffffc02018e0:	4505                	li	a0,1
ffffffffc02018e2:	1ce010ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc02018e6:	00ac3023          	sd	a0,0(s8)
        assert(check_rp[i] != NULL);
ffffffffc02018ea:	28050c63          	beqz	a0,ffffffffc0201b82 <swap_init+0x3f2>
ffffffffc02018ee:	651c                	ld	a5,8(a0)
        assert(!PageProperty(check_rp[i])); // 确保页面属性正确
ffffffffc02018f0:	8b89                	andi	a5,a5,2
ffffffffc02018f2:	26079863          	bnez	a5,ffffffffc0201b62 <swap_init+0x3d2>
    for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
ffffffffc02018f6:	0c21                	addi	s8,s8,8
ffffffffc02018f8:	ff4c14e3          	bne	s8,s4,ffffffffc02018e0 <swap_init+0x150>
    }
    list_entry_t free_list_store = free_list; // 备份当前的空闲页面链表
ffffffffc02018fc:	609c                	ld	a5,0(s1)
ffffffffc02018fe:	0084bd83          	ld	s11,8(s1)
    elm->prev = elm->next = elm;
ffffffffc0201902:	e084                	sd	s1,0(s1)
ffffffffc0201904:	f03e                	sd	a5,32(sp)
    list_init(&free_list); // 初始化一个新的空闲页面链表
    assert(list_empty(&free_list)); // 确保新的空闲页面链表为空
     
     unsigned int nr_free_store = nr_free; // 备份当前的空闲页面数量
ffffffffc0201906:	489c                	lw	a5,16(s1)
ffffffffc0201908:	e484                	sd	s1,8(s1)
     nr_free = 0; // 设置当前的空闲页面数量为0
ffffffffc020190a:	0000fc17          	auipc	s8,0xf
ffffffffc020190e:	766c0c13          	addi	s8,s8,1894 # ffffffffc0211070 <check_rp>
     unsigned int nr_free_store = nr_free; // 备份当前的空闲页面数量
ffffffffc0201912:	f43e                	sd	a5,40(sp)
     nr_free = 0; // 设置当前的空闲页面数量为0
ffffffffc0201914:	0000f797          	auipc	a5,0xf
ffffffffc0201918:	7c07ae23          	sw	zero,2012(a5) # ffffffffc02110f0 <free_area+0x10>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
        free_pages(check_rp[i], 1); // 将检查用的物理页面标记为空闲
ffffffffc020191c:	000c3503          	ld	a0,0(s8)
ffffffffc0201920:	4585                	li	a1,1
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
ffffffffc0201922:	0c21                	addi	s8,s8,8
        free_pages(check_rp[i], 1); // 将检查用的物理页面标记为空闲
ffffffffc0201924:	21e010ef          	jal	ra,ffffffffc0202b42 <free_pages>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
ffffffffc0201928:	ff4c1ae3          	bne	s8,s4,ffffffffc020191c <swap_init+0x18c>
     }
     assert(nr_free == CHECK_VALID_PHY_PAGE_NUM); // 确保空闲页面数量正确
ffffffffc020192c:	0104ac03          	lw	s8,16(s1)
ffffffffc0201930:	4791                	li	a5,4
ffffffffc0201932:	4afc1463          	bne	s8,a5,ffffffffc0201dda <swap_init+0x64a>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc0201936:	00004517          	auipc	a0,0x4
ffffffffc020193a:	baa50513          	addi	a0,a0,-1110 # ffffffffc02054e0 <commands+0xdd8>
ffffffffc020193e:	f7cfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201942:	6605                	lui	a2,0x1
     // 设置初始的虚拟页面<->物理页面环境，用于页面替换算法的测试

     pgfault_num = 0; // 页面错误次数置0
ffffffffc0201944:	00010797          	auipc	a5,0x10
ffffffffc0201948:	bc07aa23          	sw	zero,-1068(a5) # ffffffffc0211518 <pgfault_num>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc020194c:	4529                	li	a0,10
ffffffffc020194e:	00a60023          	sb	a0,0(a2) # 1000 <kern_entry-0xffffffffc01ff000>
    assert(pgfault_num==1);
ffffffffc0201952:	00010597          	auipc	a1,0x10
ffffffffc0201956:	bc65a583          	lw	a1,-1082(a1) # ffffffffc0211518 <pgfault_num>
ffffffffc020195a:	4805                	li	a6,1
ffffffffc020195c:	00010797          	auipc	a5,0x10
ffffffffc0201960:	bbc78793          	addi	a5,a5,-1092 # ffffffffc0211518 <pgfault_num>
ffffffffc0201964:	3f059b63          	bne	a1,a6,ffffffffc0201d5a <swap_init+0x5ca>
    *(unsigned char *)0x1010 = 0x0a;
ffffffffc0201968:	00a60823          	sb	a0,16(a2)
    assert(pgfault_num==1);
ffffffffc020196c:	4390                	lw	a2,0(a5)
ffffffffc020196e:	2601                	sext.w	a2,a2
ffffffffc0201970:	40b61563          	bne	a2,a1,ffffffffc0201d7a <swap_init+0x5ea>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201974:	6589                	lui	a1,0x2
ffffffffc0201976:	452d                	li	a0,11
ffffffffc0201978:	00a58023          	sb	a0,0(a1) # 2000 <kern_entry-0xffffffffc01fe000>
    assert(pgfault_num==2);
ffffffffc020197c:	4390                	lw	a2,0(a5)
ffffffffc020197e:	4809                	li	a6,2
ffffffffc0201980:	2601                	sext.w	a2,a2
ffffffffc0201982:	35061c63          	bne	a2,a6,ffffffffc0201cda <swap_init+0x54a>
    *(unsigned char *)0x2010 = 0x0b;
ffffffffc0201986:	00a58823          	sb	a0,16(a1)
    assert(pgfault_num==2);
ffffffffc020198a:	438c                	lw	a1,0(a5)
ffffffffc020198c:	2581                	sext.w	a1,a1
ffffffffc020198e:	36c59663          	bne	a1,a2,ffffffffc0201cfa <swap_init+0x56a>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0201992:	658d                	lui	a1,0x3
ffffffffc0201994:	4531                	li	a0,12
ffffffffc0201996:	00a58023          	sb	a0,0(a1) # 3000 <kern_entry-0xffffffffc01fd000>
    assert(pgfault_num==3);
ffffffffc020199a:	4390                	lw	a2,0(a5)
ffffffffc020199c:	480d                	li	a6,3
ffffffffc020199e:	2601                	sext.w	a2,a2
ffffffffc02019a0:	37061d63          	bne	a2,a6,ffffffffc0201d1a <swap_init+0x58a>
    *(unsigned char *)0x3010 = 0x0c;
ffffffffc02019a4:	00a58823          	sb	a0,16(a1)
    assert(pgfault_num==3);
ffffffffc02019a8:	438c                	lw	a1,0(a5)
ffffffffc02019aa:	2581                	sext.w	a1,a1
ffffffffc02019ac:	38c59763          	bne	a1,a2,ffffffffc0201d3a <swap_init+0x5aa>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02019b0:	6591                	lui	a1,0x4
ffffffffc02019b2:	4535                	li	a0,13
ffffffffc02019b4:	00a58023          	sb	a0,0(a1) # 4000 <kern_entry-0xffffffffc01fc000>
    assert(pgfault_num==4);
ffffffffc02019b8:	4390                	lw	a2,0(a5)
ffffffffc02019ba:	2601                	sext.w	a2,a2
ffffffffc02019bc:	21861f63          	bne	a2,s8,ffffffffc0201bda <swap_init+0x44a>
    *(unsigned char *)0x4010 = 0x0d;
ffffffffc02019c0:	00a58823          	sb	a0,16(a1)
    assert(pgfault_num==4);
ffffffffc02019c4:	439c                	lw	a5,0(a5)
ffffffffc02019c6:	2781                	sext.w	a5,a5
ffffffffc02019c8:	22c79963          	bne	a5,a2,ffffffffc0201bfa <swap_init+0x46a>
     
     check_content_set(); // 设置页面内容，触发页面错误
     assert(nr_free == 0); // 确保没有空闲页面
ffffffffc02019cc:	489c                	lw	a5,16(s1)
ffffffffc02019ce:	24079663          	bnez	a5,ffffffffc0201c1a <swap_init+0x48a>
ffffffffc02019d2:	0000f797          	auipc	a5,0xf
ffffffffc02019d6:	6be78793          	addi	a5,a5,1726 # ffffffffc0211090 <swap_in_seq_no>
ffffffffc02019da:	0000f617          	auipc	a2,0xf
ffffffffc02019de:	6de60613          	addi	a2,a2,1758 # ffffffffc02110b8 <swap_out_seq_no>
ffffffffc02019e2:	0000f517          	auipc	a0,0xf
ffffffffc02019e6:	6d650513          	addi	a0,a0,1750 # ffffffffc02110b8 <swap_out_seq_no>
         
     for(i = 0; i < MAX_SEQ_NO; i++) // 初始化交换进出序列编号数组
         swap_out_seq_no[i] = swap_in_seq_no[i] = -1;
ffffffffc02019ea:	55fd                	li	a1,-1
ffffffffc02019ec:	c38c                	sw	a1,0(a5)
ffffffffc02019ee:	c20c                	sw	a1,0(a2)
     for(i = 0; i < MAX_SEQ_NO; i++) // 初始化交换进出序列编号数组
ffffffffc02019f0:	0791                	addi	a5,a5,4
ffffffffc02019f2:	0611                	addi	a2,a2,4
ffffffffc02019f4:	fef51ce3          	bne	a0,a5,ffffffffc02019ec <swap_init+0x25c>
ffffffffc02019f8:	0000f817          	auipc	a6,0xf
ffffffffc02019fc:	65880813          	addi	a6,a6,1624 # ffffffffc0211050 <check_ptep>
ffffffffc0201a00:	0000f897          	auipc	a7,0xf
ffffffffc0201a04:	67088893          	addi	a7,a7,1648 # ffffffffc0211070 <check_rp>
ffffffffc0201a08:	6585                	lui	a1,0x1
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc0201a0a:	00010c97          	auipc	s9,0x10
ffffffffc0201a0e:	b46c8c93          	addi	s9,s9,-1210 # ffffffffc0211550 <pages>
ffffffffc0201a12:	00005c17          	auipc	s8,0x5
ffffffffc0201a16:	936c0c13          	addi	s8,s8,-1738 # ffffffffc0206348 <nbase>
     
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
         check_ptep[i] = 0;
ffffffffc0201a1a:	00083023          	sd	zero,0(a6)
         check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0); // 获取页表条目
ffffffffc0201a1e:	4601                	li	a2,0
ffffffffc0201a20:	855e                	mv	a0,s7
ffffffffc0201a22:	ec46                	sd	a7,24(sp)
ffffffffc0201a24:	e82e                	sd	a1,16(sp)
         check_ptep[i] = 0;
ffffffffc0201a26:	e442                	sd	a6,8(sp)
         check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0); // 获取页表条目
ffffffffc0201a28:	194010ef          	jal	ra,ffffffffc0202bbc <get_pte>
ffffffffc0201a2c:	6822                	ld	a6,8(sp)
         assert(check_ptep[i] != NULL); // 确保页表条目获取成功
ffffffffc0201a2e:	65c2                	ld	a1,16(sp)
ffffffffc0201a30:	68e2                	ld	a7,24(sp)
         check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0); // 获取页表条目
ffffffffc0201a32:	00a83023          	sd	a0,0(a6)
         assert(check_ptep[i] != NULL); // 确保页表条目获取成功
ffffffffc0201a36:	00010317          	auipc	t1,0x10
ffffffffc0201a3a:	b1230313          	addi	t1,t1,-1262 # ffffffffc0211548 <npage>
ffffffffc0201a3e:	16050e63          	beqz	a0,ffffffffc0201bba <swap_init+0x42a>
         assert(pte2page(*check_ptep[i]) == check_rp[i]); // 确保页表条目指向正确的物理页面
ffffffffc0201a42:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) { // 检查 PTE 是否有效
ffffffffc0201a44:	0017f613          	andi	a2,a5,1
ffffffffc0201a48:	0e060563          	beqz	a2,ffffffffc0201b32 <swap_init+0x3a2>
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0201a4c:	00033603          	ld	a2,0(t1)
    return pa2page(PTE_ADDR(pte)); // 提取页表项的物理地址并转换为 Page 结构体指针
ffffffffc0201a50:	078a                	slli	a5,a5,0x2
ffffffffc0201a52:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0201a54:	0ec7fb63          	bgeu	a5,a2,ffffffffc0201b4a <swap_init+0x3ba>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc0201a58:	000c3603          	ld	a2,0(s8)
ffffffffc0201a5c:	000cb503          	ld	a0,0(s9)
ffffffffc0201a60:	0008bf03          	ld	t5,0(a7)
ffffffffc0201a64:	8f91                	sub	a5,a5,a2
ffffffffc0201a66:	00379613          	slli	a2,a5,0x3
ffffffffc0201a6a:	97b2                	add	a5,a5,a2
ffffffffc0201a6c:	078e                	slli	a5,a5,0x3
ffffffffc0201a6e:	97aa                	add	a5,a5,a0
ffffffffc0201a70:	0aff1163          	bne	t5,a5,ffffffffc0201b12 <swap_init+0x382>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
ffffffffc0201a74:	6785                	lui	a5,0x1
ffffffffc0201a76:	95be                	add	a1,a1,a5
ffffffffc0201a78:	6795                	lui	a5,0x5
ffffffffc0201a7a:	0821                	addi	a6,a6,8
ffffffffc0201a7c:	08a1                	addi	a7,a7,8
ffffffffc0201a7e:	f8f59ee3          	bne	a1,a5,ffffffffc0201a1a <swap_init+0x28a>
         assert((*check_ptep[i] & PTE_V)); // 确保页表条目有效          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0201a82:	00004517          	auipc	a0,0x4
ffffffffc0201a86:	b3e50513          	addi	a0,a0,-1218 # ffffffffc02055c0 <commands+0xeb8>
ffffffffc0201a8a:	e30fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    int ret = sm->check_swap(); // 调用交换管理器的check_swap函数进行页面替换检查
ffffffffc0201a8e:	000b3783          	ld	a5,0(s6)
ffffffffc0201a92:	7f9c                	ld	a5,56(a5)
ffffffffc0201a94:	9782                	jalr	a5
     // 现在访问虚拟页面，测试页面替换算法
     ret = check_content_access(); // 访问内容并检查页面替换
     assert(ret == 0); // 确保页面替换检查成功
ffffffffc0201a96:	1a051263          	bnez	a0,ffffffffc0201c3a <swap_init+0x4aa>
     
     // 恢复内核内存环境
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
         free_pages(check_rp[i], 1); // 将检查用的物理页面标记为空闲
ffffffffc0201a9a:	00093503          	ld	a0,0(s2)
ffffffffc0201a9e:	4585                	li	a1,1
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
ffffffffc0201aa0:	0921                	addi	s2,s2,8
         free_pages(check_rp[i], 1); // 将检查用的物理页面标记为空闲
ffffffffc0201aa2:	0a0010ef          	jal	ra,ffffffffc0202b42 <free_pages>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
ffffffffc0201aa6:	ff491ae3          	bne	s2,s4,ffffffffc0201a9a <swap_init+0x30a>
     } 

     // free_page(pte2page(*temp_ptep)); // 释放临时分配的页面（如果有必要）

     mm_destroy(mm); // 销毁内存管理结构
ffffffffc0201aaa:	8556                	mv	a0,s5
ffffffffc0201aac:	e08ff0ef          	jal	ra,ffffffffc02010b4 <mm_destroy>
         
     nr_free = nr_free_store; // 恢复之前的空闲页面数量
ffffffffc0201ab0:	77a2                	ld	a5,40(sp)
     free_list = free_list_store; // 恢复之前的空闲页面链表
ffffffffc0201ab2:	01b4b423          	sd	s11,8(s1)
     nr_free = nr_free_store; // 恢复之前的空闲页面数量
ffffffffc0201ab6:	c89c                	sw	a5,16(s1)
     free_list = free_list_store; // 恢复之前的空闲页面链表
ffffffffc0201ab8:	7782                	ld	a5,32(sp)
ffffffffc0201aba:	e09c                	sd	a5,0(s1)

     le = &free_list; // 重新初始化le为空闲页面链表的头部
     while ((le = list_next(le)) != &free_list) {
ffffffffc0201abc:	009d8a63          	beq	s11,s1,ffffffffc0201ad0 <swap_init+0x340>
         struct Page *p = le2page(le, page_link);
         count--, total -= p->property; // 更新计数和总页数
ffffffffc0201ac0:	ff8da783          	lw	a5,-8(s11)
    return listelm->next;
ffffffffc0201ac4:	008dbd83          	ld	s11,8(s11)
ffffffffc0201ac8:	3d7d                	addiw	s10,s10,-1
ffffffffc0201aca:	9c1d                	subw	s0,s0,a5
     while ((le = list_next(le)) != &free_list) {
ffffffffc0201acc:	fe9d9ae3          	bne	s11,s1,ffffffffc0201ac0 <swap_init+0x330>
     }
     cprintf("count is %d, total is %d\n", count, total); // 打印最终的计数和总页数
ffffffffc0201ad0:	8622                	mv	a2,s0
ffffffffc0201ad2:	85ea                	mv	a1,s10
ffffffffc0201ad4:	00004517          	auipc	a0,0x4
ffffffffc0201ad8:	b2450513          	addi	a0,a0,-1244 # ffffffffc02055f8 <commands+0xef0>
ffffffffc0201adc:	ddefe0ef          	jal	ra,ffffffffc02000ba <cprintf>
     // assert(count == 0); // 确保所有页面都被正确释放
     
     cprintf("check_swap() succeeded!\n"); // 打印检查成功的消息
ffffffffc0201ae0:	00004517          	auipc	a0,0x4
ffffffffc0201ae4:	b3850513          	addi	a0,a0,-1224 # ffffffffc0205618 <commands+0xf10>
ffffffffc0201ae8:	dd2fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
}
ffffffffc0201aec:	b9dd                	j	ffffffffc02017e2 <swap_init+0x52>
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201aee:	4901                	li	s2,0
ffffffffc0201af0:	bba9                	j	ffffffffc020184a <swap_init+0xba>
        assert(PageProperty(p)); // 确保页面属性正确
ffffffffc0201af2:	00004697          	auipc	a3,0x4
ffffffffc0201af6:	8a668693          	addi	a3,a3,-1882 # ffffffffc0205398 <commands+0xc90>
ffffffffc0201afa:	00003617          	auipc	a2,0x3
ffffffffc0201afe:	32660613          	addi	a2,a2,806 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201b02:	0bd00593          	li	a1,189
ffffffffc0201b06:	00004517          	auipc	a0,0x4
ffffffffc0201b0a:	86a50513          	addi	a0,a0,-1942 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201b0e:	df4fe0ef          	jal	ra,ffffffffc0200102 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]); // 确保页表条目指向正确的物理页面
ffffffffc0201b12:	00004697          	auipc	a3,0x4
ffffffffc0201b16:	a8668693          	addi	a3,a3,-1402 # ffffffffc0205598 <commands+0xe90>
ffffffffc0201b1a:	00003617          	auipc	a2,0x3
ffffffffc0201b1e:	30660613          	addi	a2,a2,774 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201b22:	0fa00593          	li	a1,250
ffffffffc0201b26:	00004517          	auipc	a0,0x4
ffffffffc0201b2a:	84a50513          	addi	a0,a0,-1974 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201b2e:	dd4fe0ef          	jal	ra,ffffffffc0200102 <__panic>
        panic("pte2page called with invalid pte"); // 无效时触发 panic
ffffffffc0201b32:	00004617          	auipc	a2,0x4
ffffffffc0201b36:	a3e60613          	addi	a2,a2,-1474 # ffffffffc0205570 <commands+0xe68>
ffffffffc0201b3a:	08200593          	li	a1,130
ffffffffc0201b3e:	00003517          	auipc	a0,0x3
ffffffffc0201b42:	71250513          	addi	a0,a0,1810 # ffffffffc0205250 <commands+0xb48>
ffffffffc0201b46:	dbcfe0ef          	jal	ra,ffffffffc0200102 <__panic>
        panic("pa2page called with invalid pa"); // 如果无效，触发 panic
ffffffffc0201b4a:	00003617          	auipc	a2,0x3
ffffffffc0201b4e:	6e660613          	addi	a2,a2,1766 # ffffffffc0205230 <commands+0xb28>
ffffffffc0201b52:	07000593          	li	a1,112
ffffffffc0201b56:	00003517          	auipc	a0,0x3
ffffffffc0201b5a:	6fa50513          	addi	a0,a0,1786 # ffffffffc0205250 <commands+0xb48>
ffffffffc0201b5e:	da4fe0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(!PageProperty(check_rp[i])); // 确保页面属性正确
ffffffffc0201b62:	00004697          	auipc	a3,0x4
ffffffffc0201b66:	93668693          	addi	a3,a3,-1738 # ffffffffc0205498 <commands+0xd90>
ffffffffc0201b6a:	00003617          	auipc	a2,0x3
ffffffffc0201b6e:	2b660613          	addi	a2,a2,694 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201b72:	0de00593          	li	a1,222
ffffffffc0201b76:	00003517          	auipc	a0,0x3
ffffffffc0201b7a:	7fa50513          	addi	a0,a0,2042 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201b7e:	d84fe0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(check_rp[i] != NULL);
ffffffffc0201b82:	00004697          	auipc	a3,0x4
ffffffffc0201b86:	8fe68693          	addi	a3,a3,-1794 # ffffffffc0205480 <commands+0xd78>
ffffffffc0201b8a:	00003617          	auipc	a2,0x3
ffffffffc0201b8e:	29660613          	addi	a2,a2,662 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201b92:	0dd00593          	li	a1,221
ffffffffc0201b96:	00003517          	auipc	a0,0x3
ffffffffc0201b9a:	7da50513          	addi	a0,a0,2010 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201b9e:	d64fe0ef          	jal	ra,ffffffffc0200102 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset); // 如果不在预期范围内，触发panic
ffffffffc0201ba2:	00003617          	auipc	a2,0x3
ffffffffc0201ba6:	7ae60613          	addi	a2,a2,1966 # ffffffffc0205350 <commands+0xc48>
ffffffffc0201baa:	02800593          	li	a1,40
ffffffffc0201bae:	00003517          	auipc	a0,0x3
ffffffffc0201bb2:	7c250513          	addi	a0,a0,1986 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201bb6:	d4cfe0ef          	jal	ra,ffffffffc0200102 <__panic>
         assert(check_ptep[i] != NULL); // 确保页表条目获取成功
ffffffffc0201bba:	00004697          	auipc	a3,0x4
ffffffffc0201bbe:	99e68693          	addi	a3,a3,-1634 # ffffffffc0205558 <commands+0xe50>
ffffffffc0201bc2:	00003617          	auipc	a2,0x3
ffffffffc0201bc6:	25e60613          	addi	a2,a2,606 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201bca:	0f900593          	li	a1,249
ffffffffc0201bce:	00003517          	auipc	a0,0x3
ffffffffc0201bd2:	7a250513          	addi	a0,a0,1954 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201bd6:	d2cfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==4);
ffffffffc0201bda:	00004697          	auipc	a3,0x4
ffffffffc0201bde:	95e68693          	addi	a3,a3,-1698 # ffffffffc0205538 <commands+0xe30>
ffffffffc0201be2:	00003617          	auipc	a2,0x3
ffffffffc0201be6:	23e60613          	addi	a2,a2,574 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201bea:	09e00593          	li	a1,158
ffffffffc0201bee:	00003517          	auipc	a0,0x3
ffffffffc0201bf2:	78250513          	addi	a0,a0,1922 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201bf6:	d0cfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==4);
ffffffffc0201bfa:	00004697          	auipc	a3,0x4
ffffffffc0201bfe:	93e68693          	addi	a3,a3,-1730 # ffffffffc0205538 <commands+0xe30>
ffffffffc0201c02:	00003617          	auipc	a2,0x3
ffffffffc0201c06:	21e60613          	addi	a2,a2,542 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201c0a:	0a100593          	li	a1,161
ffffffffc0201c0e:	00003517          	auipc	a0,0x3
ffffffffc0201c12:	76250513          	addi	a0,a0,1890 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201c16:	cecfe0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(nr_free == 0); // 确保没有空闲页面
ffffffffc0201c1a:	00004697          	auipc	a3,0x4
ffffffffc0201c1e:	92e68693          	addi	a3,a3,-1746 # ffffffffc0205548 <commands+0xe40>
ffffffffc0201c22:	00003617          	auipc	a2,0x3
ffffffffc0201c26:	1fe60613          	addi	a2,a2,510 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201c2a:	0f100593          	li	a1,241
ffffffffc0201c2e:	00003517          	auipc	a0,0x3
ffffffffc0201c32:	74250513          	addi	a0,a0,1858 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201c36:	cccfe0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(ret == 0); // 确保页面替换检查成功
ffffffffc0201c3a:	00004697          	auipc	a3,0x4
ffffffffc0201c3e:	9ae68693          	addi	a3,a3,-1618 # ffffffffc02055e8 <commands+0xee0>
ffffffffc0201c42:	00003617          	auipc	a2,0x3
ffffffffc0201c46:	1de60613          	addi	a2,a2,478 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201c4a:	10000593          	li	a1,256
ffffffffc0201c4e:	00003517          	auipc	a0,0x3
ffffffffc0201c52:	72250513          	addi	a0,a0,1826 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201c56:	cacfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgdir[0] == 0); // 确保页目录的第一项是空的
ffffffffc0201c5a:	00003697          	auipc	a3,0x3
ffffffffc0201c5e:	59668693          	addi	a3,a3,1430 # ffffffffc02051f0 <commands+0xae8>
ffffffffc0201c62:	00003617          	auipc	a2,0x3
ffffffffc0201c66:	1be60613          	addi	a2,a2,446 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201c6a:	0cd00593          	li	a1,205
ffffffffc0201c6e:	00003517          	auipc	a0,0x3
ffffffffc0201c72:	70250513          	addi	a0,a0,1794 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201c76:	c8cfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(vma != NULL);
ffffffffc0201c7a:	00003697          	auipc	a3,0x3
ffffffffc0201c7e:	61e68693          	addi	a3,a3,1566 # ffffffffc0205298 <commands+0xb90>
ffffffffc0201c82:	00003617          	auipc	a2,0x3
ffffffffc0201c86:	19e60613          	addi	a2,a2,414 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201c8a:	0d000593          	li	a1,208
ffffffffc0201c8e:	00003517          	auipc	a0,0x3
ffffffffc0201c92:	6e250513          	addi	a0,a0,1762 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201c96:	c6cfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(temp_ptep != NULL); // 确保页表条目获取成功
ffffffffc0201c9a:	00003697          	auipc	a3,0x3
ffffffffc0201c9e:	7a668693          	addi	a3,a3,1958 # ffffffffc0205440 <commands+0xd38>
ffffffffc0201ca2:	00003617          	auipc	a2,0x3
ffffffffc0201ca6:	17e60613          	addi	a2,a2,382 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201caa:	0d800593          	li	a1,216
ffffffffc0201cae:	00003517          	auipc	a0,0x3
ffffffffc0201cb2:	6c250513          	addi	a0,a0,1730 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201cb6:	c4cfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(total == nr_free_pages()); // 确保空闲页面总数正确
ffffffffc0201cba:	00003697          	auipc	a3,0x3
ffffffffc0201cbe:	6ee68693          	addi	a3,a3,1774 # ffffffffc02053a8 <commands+0xca0>
ffffffffc0201cc2:	00003617          	auipc	a2,0x3
ffffffffc0201cc6:	15e60613          	addi	a2,a2,350 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201cca:	0c000593          	li	a1,192
ffffffffc0201cce:	00003517          	auipc	a0,0x3
ffffffffc0201cd2:	6a250513          	addi	a0,a0,1698 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201cd6:	c2cfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==2);
ffffffffc0201cda:	00004697          	auipc	a3,0x4
ffffffffc0201cde:	83e68693          	addi	a3,a3,-1986 # ffffffffc0205518 <commands+0xe10>
ffffffffc0201ce2:	00003617          	auipc	a2,0x3
ffffffffc0201ce6:	13e60613          	addi	a2,a2,318 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201cea:	09200593          	li	a1,146
ffffffffc0201cee:	00003517          	auipc	a0,0x3
ffffffffc0201cf2:	68250513          	addi	a0,a0,1666 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201cf6:	c0cfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==2);
ffffffffc0201cfa:	00004697          	auipc	a3,0x4
ffffffffc0201cfe:	81e68693          	addi	a3,a3,-2018 # ffffffffc0205518 <commands+0xe10>
ffffffffc0201d02:	00003617          	auipc	a2,0x3
ffffffffc0201d06:	11e60613          	addi	a2,a2,286 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201d0a:	09500593          	li	a1,149
ffffffffc0201d0e:	00003517          	auipc	a0,0x3
ffffffffc0201d12:	66250513          	addi	a0,a0,1634 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201d16:	becfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==3);
ffffffffc0201d1a:	00004697          	auipc	a3,0x4
ffffffffc0201d1e:	80e68693          	addi	a3,a3,-2034 # ffffffffc0205528 <commands+0xe20>
ffffffffc0201d22:	00003617          	auipc	a2,0x3
ffffffffc0201d26:	0fe60613          	addi	a2,a2,254 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201d2a:	09800593          	li	a1,152
ffffffffc0201d2e:	00003517          	auipc	a0,0x3
ffffffffc0201d32:	64250513          	addi	a0,a0,1602 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201d36:	bccfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==3);
ffffffffc0201d3a:	00003697          	auipc	a3,0x3
ffffffffc0201d3e:	7ee68693          	addi	a3,a3,2030 # ffffffffc0205528 <commands+0xe20>
ffffffffc0201d42:	00003617          	auipc	a2,0x3
ffffffffc0201d46:	0de60613          	addi	a2,a2,222 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201d4a:	09b00593          	li	a1,155
ffffffffc0201d4e:	00003517          	auipc	a0,0x3
ffffffffc0201d52:	62250513          	addi	a0,a0,1570 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201d56:	bacfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==1);
ffffffffc0201d5a:	00003697          	auipc	a3,0x3
ffffffffc0201d5e:	7ae68693          	addi	a3,a3,1966 # ffffffffc0205508 <commands+0xe00>
ffffffffc0201d62:	00003617          	auipc	a2,0x3
ffffffffc0201d66:	0be60613          	addi	a2,a2,190 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201d6a:	08c00593          	li	a1,140
ffffffffc0201d6e:	00003517          	auipc	a0,0x3
ffffffffc0201d72:	60250513          	addi	a0,a0,1538 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201d76:	b8cfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==1);
ffffffffc0201d7a:	00003697          	auipc	a3,0x3
ffffffffc0201d7e:	78e68693          	addi	a3,a3,1934 # ffffffffc0205508 <commands+0xe00>
ffffffffc0201d82:	00003617          	auipc	a2,0x3
ffffffffc0201d86:	09e60613          	addi	a2,a2,158 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201d8a:	08f00593          	li	a1,143
ffffffffc0201d8e:	00003517          	auipc	a0,0x3
ffffffffc0201d92:	5e250513          	addi	a0,a0,1506 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201d96:	b6cfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(mm != NULL);
ffffffffc0201d9a:	00003697          	auipc	a3,0x3
ffffffffc0201d9e:	52668693          	addi	a3,a3,1318 # ffffffffc02052c0 <commands+0xbb8>
ffffffffc0201da2:	00003617          	auipc	a2,0x3
ffffffffc0201da6:	07e60613          	addi	a2,a2,126 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201daa:	0c500593          	li	a1,197
ffffffffc0201dae:	00003517          	auipc	a0,0x3
ffffffffc0201db2:	5c250513          	addi	a0,a0,1474 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201db6:	b4cfe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(check_mm_struct == NULL); // 确保之前没有设置过检查用的内存管理结构
ffffffffc0201dba:	00003697          	auipc	a3,0x3
ffffffffc0201dbe:	63668693          	addi	a3,a3,1590 # ffffffffc02053f0 <commands+0xce8>
ffffffffc0201dc2:	00003617          	auipc	a2,0x3
ffffffffc0201dc6:	05e60613          	addi	a2,a2,94 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201dca:	0c800593          	li	a1,200
ffffffffc0201dce:	00003517          	auipc	a0,0x3
ffffffffc0201dd2:	5a250513          	addi	a0,a0,1442 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201dd6:	b2cfe0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(nr_free == CHECK_VALID_PHY_PAGE_NUM); // 确保空闲页面数量正确
ffffffffc0201dda:	00003697          	auipc	a3,0x3
ffffffffc0201dde:	6de68693          	addi	a3,a3,1758 # ffffffffc02054b8 <commands+0xdb0>
ffffffffc0201de2:	00003617          	auipc	a2,0x3
ffffffffc0201de6:	03e60613          	addi	a2,a2,62 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201dea:	0e900593          	li	a1,233
ffffffffc0201dee:	00003517          	auipc	a0,0x3
ffffffffc0201df2:	58250513          	addi	a0,a0,1410 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201df6:	b0cfe0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0201dfa <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0201dfa:	0000f797          	auipc	a5,0xf
ffffffffc0201dfe:	72e7b783          	ld	a5,1838(a5) # ffffffffc0211528 <sm>
ffffffffc0201e02:	6b9c                	ld	a5,16(a5)
ffffffffc0201e04:	8782                	jr	a5

ffffffffc0201e06 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0201e06:	0000f797          	auipc	a5,0xf
ffffffffc0201e0a:	7227b783          	ld	a5,1826(a5) # ffffffffc0211528 <sm>
ffffffffc0201e0e:	739c                	ld	a5,32(a5)
ffffffffc0201e10:	8782                	jr	a5

ffffffffc0201e12 <swap_out>:
swap_out(struct mm_struct *mm, int n, int in_tick) {
ffffffffc0201e12:	711d                	addi	sp,sp,-96
ffffffffc0201e14:	ec86                	sd	ra,88(sp)
ffffffffc0201e16:	e8a2                	sd	s0,80(sp)
ffffffffc0201e18:	e4a6                	sd	s1,72(sp)
ffffffffc0201e1a:	e0ca                	sd	s2,64(sp)
ffffffffc0201e1c:	fc4e                	sd	s3,56(sp)
ffffffffc0201e1e:	f852                	sd	s4,48(sp)
ffffffffc0201e20:	f456                	sd	s5,40(sp)
ffffffffc0201e22:	f05a                	sd	s6,32(sp)
ffffffffc0201e24:	ec5e                	sd	s7,24(sp)
ffffffffc0201e26:	e862                	sd	s8,16(sp)
    for (i = 0; i != n; ++i) {
ffffffffc0201e28:	cde9                	beqz	a1,ffffffffc0201f02 <swap_out+0xf0>
ffffffffc0201e2a:	8a2e                	mv	s4,a1
ffffffffc0201e2c:	892a                	mv	s2,a0
ffffffffc0201e2e:	8ab2                	mv	s5,a2
ffffffffc0201e30:	4401                	li	s0,0
ffffffffc0201e32:	0000f997          	auipc	s3,0xf
ffffffffc0201e36:	6f698993          	addi	s3,s3,1782 # ffffffffc0211528 <sm>
            cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
ffffffffc0201e3a:	00004b17          	auipc	s6,0x4
ffffffffc0201e3e:	85eb0b13          	addi	s6,s6,-1954 # ffffffffc0205698 <commands+0xf90>
            cprintf("SWAP: failed to save\n");
ffffffffc0201e42:	00004b97          	auipc	s7,0x4
ffffffffc0201e46:	83eb8b93          	addi	s7,s7,-1986 # ffffffffc0205680 <commands+0xf78>
ffffffffc0201e4a:	a825                	j	ffffffffc0201e82 <swap_out+0x70>
            cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
ffffffffc0201e4c:	67a2                	ld	a5,8(sp)
ffffffffc0201e4e:	8626                	mv	a2,s1
ffffffffc0201e50:	85a2                	mv	a1,s0
ffffffffc0201e52:	63b4                	ld	a3,64(a5)
ffffffffc0201e54:	855a                	mv	a0,s6
    for (i = 0; i != n; ++i) {
ffffffffc0201e56:	2405                	addiw	s0,s0,1
            cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
ffffffffc0201e58:	82b1                	srli	a3,a3,0xc
ffffffffc0201e5a:	0685                	addi	a3,a3,1
ffffffffc0201e5c:	a5efe0ef          	jal	ra,ffffffffc02000ba <cprintf>
            *ptep = (page->pra_vaddr / PGSIZE + 1) << 8; // 更新页表条目
ffffffffc0201e60:	6522                	ld	a0,8(sp)
            free_page(page); // 释放页面
ffffffffc0201e62:	4585                	li	a1,1
            *ptep = (page->pra_vaddr / PGSIZE + 1) << 8; // 更新页表条目
ffffffffc0201e64:	613c                	ld	a5,64(a0)
ffffffffc0201e66:	83b1                	srli	a5,a5,0xc
ffffffffc0201e68:	0785                	addi	a5,a5,1
ffffffffc0201e6a:	07a2                	slli	a5,a5,0x8
ffffffffc0201e6c:	00fc3023          	sd	a5,0(s8)
            free_page(page); // 释放页面
ffffffffc0201e70:	4d3000ef          	jal	ra,ffffffffc0202b42 <free_pages>
        tlb_invalidate(mm->pgdir, v); // 使TLB无效，确保CPU的缓存与内存管理单元同步
ffffffffc0201e74:	01893503          	ld	a0,24(s2)
ffffffffc0201e78:	85a6                	mv	a1,s1
ffffffffc0201e7a:	4ff010ef          	jal	ra,ffffffffc0203b78 <tlb_invalidate>
    for (i = 0; i != n; ++i) {
ffffffffc0201e7e:	048a0d63          	beq	s4,s0,ffffffffc0201ed8 <swap_out+0xc6>
        int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc0201e82:	0009b783          	ld	a5,0(s3)
ffffffffc0201e86:	8656                	mv	a2,s5
ffffffffc0201e88:	002c                	addi	a1,sp,8
ffffffffc0201e8a:	7b9c                	ld	a5,48(a5)
ffffffffc0201e8c:	854a                	mv	a0,s2
ffffffffc0201e8e:	9782                	jalr	a5
        if (r != 0) {
ffffffffc0201e90:	e12d                	bnez	a0,ffffffffc0201ef2 <swap_out+0xe0>
        v = page->pra_vaddr; 
ffffffffc0201e92:	67a2                	ld	a5,8(sp)
        pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0201e94:	01893503          	ld	a0,24(s2)
ffffffffc0201e98:	4601                	li	a2,0
        v = page->pra_vaddr; 
ffffffffc0201e9a:	63a4                	ld	s1,64(a5)
        pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0201e9c:	85a6                	mv	a1,s1
ffffffffc0201e9e:	51f000ef          	jal	ra,ffffffffc0202bbc <get_pte>
        assert((*ptep & PTE_V) != 0); // 确保页表条目有效
ffffffffc0201ea2:	611c                	ld	a5,0(a0)
        pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0201ea4:	8c2a                	mv	s8,a0
        assert((*ptep & PTE_V) != 0); // 确保页表条目有效
ffffffffc0201ea6:	8b85                	andi	a5,a5,1
ffffffffc0201ea8:	cfb9                	beqz	a5,ffffffffc0201f06 <swap_out+0xf4>
        if (swapfs_write((page->pra_vaddr / PGSIZE + 1) << 8, page) != 0) {
ffffffffc0201eaa:	65a2                	ld	a1,8(sp)
ffffffffc0201eac:	61bc                	ld	a5,64(a1)
ffffffffc0201eae:	83b1                	srli	a5,a5,0xc
ffffffffc0201eb0:	0785                	addi	a5,a5,1
ffffffffc0201eb2:	00879513          	slli	a0,a5,0x8
ffffffffc0201eb6:	7f5010ef          	jal	ra,ffffffffc0203eaa <swapfs_write>
ffffffffc0201eba:	d949                	beqz	a0,ffffffffc0201e4c <swap_out+0x3a>
            cprintf("SWAP: failed to save\n");
ffffffffc0201ebc:	855e                	mv	a0,s7
ffffffffc0201ebe:	9fcfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
            sm->map_swappable(mm, v, page, 0); // 如果失败，重新映射为可交换
ffffffffc0201ec2:	0009b783          	ld	a5,0(s3)
ffffffffc0201ec6:	6622                	ld	a2,8(sp)
ffffffffc0201ec8:	4681                	li	a3,0
ffffffffc0201eca:	739c                	ld	a5,32(a5)
ffffffffc0201ecc:	85a6                	mv	a1,s1
ffffffffc0201ece:	854a                	mv	a0,s2
    for (i = 0; i != n; ++i) {
ffffffffc0201ed0:	2405                	addiw	s0,s0,1
            sm->map_swappable(mm, v, page, 0); // 如果失败，重新映射为可交换
ffffffffc0201ed2:	9782                	jalr	a5
    for (i = 0; i != n; ++i) {
ffffffffc0201ed4:	fa8a17e3          	bne	s4,s0,ffffffffc0201e82 <swap_out+0x70>
}
ffffffffc0201ed8:	60e6                	ld	ra,88(sp)
ffffffffc0201eda:	8522                	mv	a0,s0
ffffffffc0201edc:	6446                	ld	s0,80(sp)
ffffffffc0201ede:	64a6                	ld	s1,72(sp)
ffffffffc0201ee0:	6906                	ld	s2,64(sp)
ffffffffc0201ee2:	79e2                	ld	s3,56(sp)
ffffffffc0201ee4:	7a42                	ld	s4,48(sp)
ffffffffc0201ee6:	7aa2                	ld	s5,40(sp)
ffffffffc0201ee8:	7b02                	ld	s6,32(sp)
ffffffffc0201eea:	6be2                	ld	s7,24(sp)
ffffffffc0201eec:	6c42                	ld	s8,16(sp)
ffffffffc0201eee:	6125                	addi	sp,sp,96
ffffffffc0201ef0:	8082                	ret
            cprintf("i %d, swap_out: call swap_out_victim failed\n", i);
ffffffffc0201ef2:	85a2                	mv	a1,s0
ffffffffc0201ef4:	00003517          	auipc	a0,0x3
ffffffffc0201ef8:	74450513          	addi	a0,a0,1860 # ffffffffc0205638 <commands+0xf30>
ffffffffc0201efc:	9befe0ef          	jal	ra,ffffffffc02000ba <cprintf>
            break;
ffffffffc0201f00:	bfe1                	j	ffffffffc0201ed8 <swap_out+0xc6>
    for (i = 0; i != n; ++i) {
ffffffffc0201f02:	4401                	li	s0,0
ffffffffc0201f04:	bfd1                	j	ffffffffc0201ed8 <swap_out+0xc6>
        assert((*ptep & PTE_V) != 0); // 确保页表条目有效
ffffffffc0201f06:	00003697          	auipc	a3,0x3
ffffffffc0201f0a:	76268693          	addi	a3,a3,1890 # ffffffffc0205668 <commands+0xf60>
ffffffffc0201f0e:	00003617          	auipc	a2,0x3
ffffffffc0201f12:	f1260613          	addi	a2,a2,-238 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201f16:	06200593          	li	a1,98
ffffffffc0201f1a:	00003517          	auipc	a0,0x3
ffffffffc0201f1e:	45650513          	addi	a0,a0,1110 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201f22:	9e0fe0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0201f26 <swap_in>:
swap_in(struct mm_struct *mm, uintptr_t addr, struct Page **ptr_result) {
ffffffffc0201f26:	7179                	addi	sp,sp,-48
ffffffffc0201f28:	e84a                	sd	s2,16(sp)
ffffffffc0201f2a:	892a                	mv	s2,a0
    struct Page *result = alloc_page(); // 分配一个新页面
ffffffffc0201f2c:	4505                	li	a0,1
swap_in(struct mm_struct *mm, uintptr_t addr, struct Page **ptr_result) {
ffffffffc0201f2e:	ec26                	sd	s1,24(sp)
ffffffffc0201f30:	e44e                	sd	s3,8(sp)
ffffffffc0201f32:	f406                	sd	ra,40(sp)
ffffffffc0201f34:	f022                	sd	s0,32(sp)
ffffffffc0201f36:	84ae                	mv	s1,a1
ffffffffc0201f38:	89b2                	mv	s3,a2
    struct Page *result = alloc_page(); // 分配一个新页面
ffffffffc0201f3a:	377000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
    assert(result != NULL); // 确保分配成功
ffffffffc0201f3e:	c129                	beqz	a0,ffffffffc0201f80 <swap_in+0x5a>
    pte_t *ptep = get_pte(mm->pgdir, addr, 0); // 获取页表条目
ffffffffc0201f40:	842a                	mv	s0,a0
ffffffffc0201f42:	01893503          	ld	a0,24(s2)
ffffffffc0201f46:	4601                	li	a2,0
ffffffffc0201f48:	85a6                	mv	a1,s1
ffffffffc0201f4a:	473000ef          	jal	ra,ffffffffc0202bbc <get_pte>
ffffffffc0201f4e:	892a                	mv	s2,a0
    if ((r = swapfs_read((*ptep), result)) != 0) {
ffffffffc0201f50:	6108                	ld	a0,0(a0)
ffffffffc0201f52:	85a2                	mv	a1,s0
ffffffffc0201f54:	6bd010ef          	jal	ra,ffffffffc0203e10 <swapfs_read>
    cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep) >> 8, addr);
ffffffffc0201f58:	00093583          	ld	a1,0(s2)
ffffffffc0201f5c:	8626                	mv	a2,s1
ffffffffc0201f5e:	00003517          	auipc	a0,0x3
ffffffffc0201f62:	78a50513          	addi	a0,a0,1930 # ffffffffc02056e8 <commands+0xfe0>
ffffffffc0201f66:	81a1                	srli	a1,a1,0x8
ffffffffc0201f68:	952fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
}
ffffffffc0201f6c:	70a2                	ld	ra,40(sp)
    *ptr_result = result; // 设置函数返回的页面
ffffffffc0201f6e:	0089b023          	sd	s0,0(s3)
}
ffffffffc0201f72:	7402                	ld	s0,32(sp)
ffffffffc0201f74:	64e2                	ld	s1,24(sp)
ffffffffc0201f76:	6942                	ld	s2,16(sp)
ffffffffc0201f78:	69a2                	ld	s3,8(sp)
ffffffffc0201f7a:	4501                	li	a0,0
ffffffffc0201f7c:	6145                	addi	sp,sp,48
ffffffffc0201f7e:	8082                	ret
    assert(result != NULL); // 确保分配成功
ffffffffc0201f80:	00003697          	auipc	a3,0x3
ffffffffc0201f84:	75868693          	addi	a3,a3,1880 # ffffffffc02056d8 <commands+0xfd0>
ffffffffc0201f88:	00003617          	auipc	a2,0x3
ffffffffc0201f8c:	e9860613          	addi	a2,a2,-360 # ffffffffc0204e20 <commands+0x718>
ffffffffc0201f90:	07800593          	li	a1,120
ffffffffc0201f94:	00003517          	auipc	a0,0x3
ffffffffc0201f98:	3dc50513          	addi	a0,a0,988 # ffffffffc0205370 <commands+0xc68>
ffffffffc0201f9c:	966fe0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0201fa0 <default_init>:
    elm->prev = elm->next = elm;
ffffffffc0201fa0:	0000f797          	auipc	a5,0xf
ffffffffc0201fa4:	14078793          	addi	a5,a5,320 # ffffffffc02110e0 <free_area>
ffffffffc0201fa8:	e79c                	sd	a5,8(a5)
ffffffffc0201faa:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0201fac:	0007a823          	sw	zero,16(a5)
}
ffffffffc0201fb0:	8082                	ret

ffffffffc0201fb2 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0201fb2:	0000f517          	auipc	a0,0xf
ffffffffc0201fb6:	13e56503          	lwu	a0,318(a0) # ffffffffc02110f0 <free_area+0x10>
ffffffffc0201fba:	8082                	ret

ffffffffc0201fbc <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0201fbc:	715d                	addi	sp,sp,-80
ffffffffc0201fbe:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0201fc0:	0000f417          	auipc	s0,0xf
ffffffffc0201fc4:	12040413          	addi	s0,s0,288 # ffffffffc02110e0 <free_area>
ffffffffc0201fc8:	641c                	ld	a5,8(s0)
ffffffffc0201fca:	e486                	sd	ra,72(sp)
ffffffffc0201fcc:	fc26                	sd	s1,56(sp)
ffffffffc0201fce:	f84a                	sd	s2,48(sp)
ffffffffc0201fd0:	f44e                	sd	s3,40(sp)
ffffffffc0201fd2:	f052                	sd	s4,32(sp)
ffffffffc0201fd4:	ec56                	sd	s5,24(sp)
ffffffffc0201fd6:	e85a                	sd	s6,16(sp)
ffffffffc0201fd8:	e45e                	sd	s7,8(sp)
ffffffffc0201fda:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201fdc:	2c878763          	beq	a5,s0,ffffffffc02022aa <default_check+0x2ee>
    int count = 0, total = 0;
ffffffffc0201fe0:	4481                	li	s1,0
ffffffffc0201fe2:	4901                	li	s2,0
ffffffffc0201fe4:	fe87b703          	ld	a4,-24(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0201fe8:	8b09                	andi	a4,a4,2
ffffffffc0201fea:	2c070463          	beqz	a4,ffffffffc02022b2 <default_check+0x2f6>
        count ++, total += p->property;
ffffffffc0201fee:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201ff2:	679c                	ld	a5,8(a5)
ffffffffc0201ff4:	2905                	addiw	s2,s2,1
ffffffffc0201ff6:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201ff8:	fe8796e3          	bne	a5,s0,ffffffffc0201fe4 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0201ffc:	89a6                	mv	s3,s1
ffffffffc0201ffe:	385000ef          	jal	ra,ffffffffc0202b82 <nr_free_pages>
ffffffffc0202002:	71351863          	bne	a0,s3,ffffffffc0202712 <default_check+0x756>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202006:	4505                	li	a0,1
ffffffffc0202008:	2a9000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc020200c:	8a2a                	mv	s4,a0
ffffffffc020200e:	44050263          	beqz	a0,ffffffffc0202452 <default_check+0x496>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202012:	4505                	li	a0,1
ffffffffc0202014:	29d000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc0202018:	89aa                	mv	s3,a0
ffffffffc020201a:	70050c63          	beqz	a0,ffffffffc0202732 <default_check+0x776>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020201e:	4505                	li	a0,1
ffffffffc0202020:	291000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc0202024:	8aaa                	mv	s5,a0
ffffffffc0202026:	4a050663          	beqz	a0,ffffffffc02024d2 <default_check+0x516>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020202a:	2b3a0463          	beq	s4,s3,ffffffffc02022d2 <default_check+0x316>
ffffffffc020202e:	2aaa0263          	beq	s4,a0,ffffffffc02022d2 <default_check+0x316>
ffffffffc0202032:	2aa98063          	beq	s3,a0,ffffffffc02022d2 <default_check+0x316>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0202036:	000a2783          	lw	a5,0(s4)
ffffffffc020203a:	2a079c63          	bnez	a5,ffffffffc02022f2 <default_check+0x336>
ffffffffc020203e:	0009a783          	lw	a5,0(s3)
ffffffffc0202042:	2a079863          	bnez	a5,ffffffffc02022f2 <default_check+0x336>
ffffffffc0202046:	411c                	lw	a5,0(a0)
ffffffffc0202048:	2a079563          	bnez	a5,ffffffffc02022f2 <default_check+0x336>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc020204c:	0000f797          	auipc	a5,0xf
ffffffffc0202050:	5047b783          	ld	a5,1284(a5) # ffffffffc0211550 <pages>
ffffffffc0202054:	40fa0733          	sub	a4,s4,a5
ffffffffc0202058:	870d                	srai	a4,a4,0x3
ffffffffc020205a:	00004597          	auipc	a1,0x4
ffffffffc020205e:	2e65b583          	ld	a1,742(a1) # ffffffffc0206340 <error_string+0x38>
ffffffffc0202062:	02b70733          	mul	a4,a4,a1
ffffffffc0202066:	00004617          	auipc	a2,0x4
ffffffffc020206a:	2e263603          	ld	a2,738(a2) # ffffffffc0206348 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020206e:	0000f697          	auipc	a3,0xf
ffffffffc0202072:	4da6b683          	ld	a3,1242(a3) # ffffffffc0211548 <npage>
ffffffffc0202076:	06b2                	slli	a3,a3,0xc
ffffffffc0202078:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc020207a:	0732                	slli	a4,a4,0xc
ffffffffc020207c:	28d77b63          	bgeu	a4,a3,ffffffffc0202312 <default_check+0x356>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0202080:	40f98733          	sub	a4,s3,a5
ffffffffc0202084:	870d                	srai	a4,a4,0x3
ffffffffc0202086:	02b70733          	mul	a4,a4,a1
ffffffffc020208a:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc020208c:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020208e:	4cd77263          	bgeu	a4,a3,ffffffffc0202552 <default_check+0x596>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0202092:	40f507b3          	sub	a5,a0,a5
ffffffffc0202096:	878d                	srai	a5,a5,0x3
ffffffffc0202098:	02b787b3          	mul	a5,a5,a1
ffffffffc020209c:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc020209e:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02020a0:	30d7f963          	bgeu	a5,a3,ffffffffc02023b2 <default_check+0x3f6>
    assert(alloc_page() == NULL);
ffffffffc02020a4:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02020a6:	00043c03          	ld	s8,0(s0)
ffffffffc02020aa:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02020ae:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02020b2:	e400                	sd	s0,8(s0)
ffffffffc02020b4:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02020b6:	0000f797          	auipc	a5,0xf
ffffffffc02020ba:	0207ad23          	sw	zero,58(a5) # ffffffffc02110f0 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02020be:	1f3000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc02020c2:	2c051863          	bnez	a0,ffffffffc0202392 <default_check+0x3d6>
    free_page(p0);
ffffffffc02020c6:	4585                	li	a1,1
ffffffffc02020c8:	8552                	mv	a0,s4
ffffffffc02020ca:	279000ef          	jal	ra,ffffffffc0202b42 <free_pages>
    free_page(p1);
ffffffffc02020ce:	4585                	li	a1,1
ffffffffc02020d0:	854e                	mv	a0,s3
ffffffffc02020d2:	271000ef          	jal	ra,ffffffffc0202b42 <free_pages>
    free_page(p2);
ffffffffc02020d6:	4585                	li	a1,1
ffffffffc02020d8:	8556                	mv	a0,s5
ffffffffc02020da:	269000ef          	jal	ra,ffffffffc0202b42 <free_pages>
    assert(nr_free == 3);
ffffffffc02020de:	4818                	lw	a4,16(s0)
ffffffffc02020e0:	478d                	li	a5,3
ffffffffc02020e2:	28f71863          	bne	a4,a5,ffffffffc0202372 <default_check+0x3b6>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02020e6:	4505                	li	a0,1
ffffffffc02020e8:	1c9000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc02020ec:	89aa                	mv	s3,a0
ffffffffc02020ee:	26050263          	beqz	a0,ffffffffc0202352 <default_check+0x396>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02020f2:	4505                	li	a0,1
ffffffffc02020f4:	1bd000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc02020f8:	8aaa                	mv	s5,a0
ffffffffc02020fa:	3a050c63          	beqz	a0,ffffffffc02024b2 <default_check+0x4f6>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02020fe:	4505                	li	a0,1
ffffffffc0202100:	1b1000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc0202104:	8a2a                	mv	s4,a0
ffffffffc0202106:	38050663          	beqz	a0,ffffffffc0202492 <default_check+0x4d6>
    assert(alloc_page() == NULL);
ffffffffc020210a:	4505                	li	a0,1
ffffffffc020210c:	1a5000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc0202110:	36051163          	bnez	a0,ffffffffc0202472 <default_check+0x4b6>
    free_page(p0);
ffffffffc0202114:	4585                	li	a1,1
ffffffffc0202116:	854e                	mv	a0,s3
ffffffffc0202118:	22b000ef          	jal	ra,ffffffffc0202b42 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020211c:	641c                	ld	a5,8(s0)
ffffffffc020211e:	20878a63          	beq	a5,s0,ffffffffc0202332 <default_check+0x376>
    assert((p = alloc_page()) == p0);
ffffffffc0202122:	4505                	li	a0,1
ffffffffc0202124:	18d000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc0202128:	30a99563          	bne	s3,a0,ffffffffc0202432 <default_check+0x476>
    assert(alloc_page() == NULL);
ffffffffc020212c:	4505                	li	a0,1
ffffffffc020212e:	183000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc0202132:	2e051063          	bnez	a0,ffffffffc0202412 <default_check+0x456>
    assert(nr_free == 0);
ffffffffc0202136:	481c                	lw	a5,16(s0)
ffffffffc0202138:	2a079d63          	bnez	a5,ffffffffc02023f2 <default_check+0x436>
    free_page(p);
ffffffffc020213c:	854e                	mv	a0,s3
ffffffffc020213e:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0202140:	01843023          	sd	s8,0(s0)
ffffffffc0202144:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0202148:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc020214c:	1f7000ef          	jal	ra,ffffffffc0202b42 <free_pages>
    free_page(p1);
ffffffffc0202150:	4585                	li	a1,1
ffffffffc0202152:	8556                	mv	a0,s5
ffffffffc0202154:	1ef000ef          	jal	ra,ffffffffc0202b42 <free_pages>
    free_page(p2);
ffffffffc0202158:	4585                	li	a1,1
ffffffffc020215a:	8552                	mv	a0,s4
ffffffffc020215c:	1e7000ef          	jal	ra,ffffffffc0202b42 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0202160:	4515                	li	a0,5
ffffffffc0202162:	14f000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc0202166:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0202168:	26050563          	beqz	a0,ffffffffc02023d2 <default_check+0x416>
ffffffffc020216c:	651c                	ld	a5,8(a0)
ffffffffc020216e:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0202170:	8b85                	andi	a5,a5,1
ffffffffc0202172:	54079063          	bnez	a5,ffffffffc02026b2 <default_check+0x6f6>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0202176:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0202178:	00043b03          	ld	s6,0(s0)
ffffffffc020217c:	00843a83          	ld	s5,8(s0)
ffffffffc0202180:	e000                	sd	s0,0(s0)
ffffffffc0202182:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0202184:	12d000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc0202188:	50051563          	bnez	a0,ffffffffc0202692 <default_check+0x6d6>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc020218c:	09098a13          	addi	s4,s3,144
ffffffffc0202190:	8552                	mv	a0,s4
ffffffffc0202192:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0202194:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0202198:	0000f797          	auipc	a5,0xf
ffffffffc020219c:	f407ac23          	sw	zero,-168(a5) # ffffffffc02110f0 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02021a0:	1a3000ef          	jal	ra,ffffffffc0202b42 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02021a4:	4511                	li	a0,4
ffffffffc02021a6:	10b000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc02021aa:	4c051463          	bnez	a0,ffffffffc0202672 <default_check+0x6b6>
ffffffffc02021ae:	0989b783          	ld	a5,152(s3)
ffffffffc02021b2:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02021b4:	8b85                	andi	a5,a5,1
ffffffffc02021b6:	48078e63          	beqz	a5,ffffffffc0202652 <default_check+0x696>
ffffffffc02021ba:	0a89a703          	lw	a4,168(s3)
ffffffffc02021be:	478d                	li	a5,3
ffffffffc02021c0:	48f71963          	bne	a4,a5,ffffffffc0202652 <default_check+0x696>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02021c4:	450d                	li	a0,3
ffffffffc02021c6:	0eb000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc02021ca:	8c2a                	mv	s8,a0
ffffffffc02021cc:	46050363          	beqz	a0,ffffffffc0202632 <default_check+0x676>
    assert(alloc_page() == NULL);
ffffffffc02021d0:	4505                	li	a0,1
ffffffffc02021d2:	0df000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc02021d6:	42051e63          	bnez	a0,ffffffffc0202612 <default_check+0x656>
    assert(p0 + 2 == p1);
ffffffffc02021da:	418a1c63          	bne	s4,s8,ffffffffc02025f2 <default_check+0x636>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02021de:	4585                	li	a1,1
ffffffffc02021e0:	854e                	mv	a0,s3
ffffffffc02021e2:	161000ef          	jal	ra,ffffffffc0202b42 <free_pages>
    free_pages(p1, 3);
ffffffffc02021e6:	458d                	li	a1,3
ffffffffc02021e8:	8552                	mv	a0,s4
ffffffffc02021ea:	159000ef          	jal	ra,ffffffffc0202b42 <free_pages>
ffffffffc02021ee:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02021f2:	04898c13          	addi	s8,s3,72
ffffffffc02021f6:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02021f8:	8b85                	andi	a5,a5,1
ffffffffc02021fa:	3c078c63          	beqz	a5,ffffffffc02025d2 <default_check+0x616>
ffffffffc02021fe:	0189a703          	lw	a4,24(s3)
ffffffffc0202202:	4785                	li	a5,1
ffffffffc0202204:	3cf71763          	bne	a4,a5,ffffffffc02025d2 <default_check+0x616>
ffffffffc0202208:	008a3783          	ld	a5,8(s4)
ffffffffc020220c:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc020220e:	8b85                	andi	a5,a5,1
ffffffffc0202210:	3a078163          	beqz	a5,ffffffffc02025b2 <default_check+0x5f6>
ffffffffc0202214:	018a2703          	lw	a4,24(s4)
ffffffffc0202218:	478d                	li	a5,3
ffffffffc020221a:	38f71c63          	bne	a4,a5,ffffffffc02025b2 <default_check+0x5f6>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc020221e:	4505                	li	a0,1
ffffffffc0202220:	091000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc0202224:	36a99763          	bne	s3,a0,ffffffffc0202592 <default_check+0x5d6>
    free_page(p0);
ffffffffc0202228:	4585                	li	a1,1
ffffffffc020222a:	119000ef          	jal	ra,ffffffffc0202b42 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc020222e:	4509                	li	a0,2
ffffffffc0202230:	081000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc0202234:	32aa1f63          	bne	s4,a0,ffffffffc0202572 <default_check+0x5b6>

    free_pages(p0, 2);
ffffffffc0202238:	4589                	li	a1,2
ffffffffc020223a:	109000ef          	jal	ra,ffffffffc0202b42 <free_pages>
    free_page(p2);
ffffffffc020223e:	4585                	li	a1,1
ffffffffc0202240:	8562                	mv	a0,s8
ffffffffc0202242:	101000ef          	jal	ra,ffffffffc0202b42 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0202246:	4515                	li	a0,5
ffffffffc0202248:	069000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc020224c:	89aa                	mv	s3,a0
ffffffffc020224e:	48050263          	beqz	a0,ffffffffc02026d2 <default_check+0x716>
    assert(alloc_page() == NULL);
ffffffffc0202252:	4505                	li	a0,1
ffffffffc0202254:	05d000ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc0202258:	2c051d63          	bnez	a0,ffffffffc0202532 <default_check+0x576>

    assert(nr_free == 0);
ffffffffc020225c:	481c                	lw	a5,16(s0)
ffffffffc020225e:	2a079a63          	bnez	a5,ffffffffc0202512 <default_check+0x556>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0202262:	4595                	li	a1,5
ffffffffc0202264:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0202266:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc020226a:	01643023          	sd	s6,0(s0)
ffffffffc020226e:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0202272:	0d1000ef          	jal	ra,ffffffffc0202b42 <free_pages>
    return listelm->next;
ffffffffc0202276:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202278:	00878963          	beq	a5,s0,ffffffffc020228a <default_check+0x2ce>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc020227c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202280:	679c                	ld	a5,8(a5)
ffffffffc0202282:	397d                	addiw	s2,s2,-1
ffffffffc0202284:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202286:	fe879be3          	bne	a5,s0,ffffffffc020227c <default_check+0x2c0>
    }
    assert(count == 0);
ffffffffc020228a:	26091463          	bnez	s2,ffffffffc02024f2 <default_check+0x536>
    assert(total == 0);
ffffffffc020228e:	46049263          	bnez	s1,ffffffffc02026f2 <default_check+0x736>
}
ffffffffc0202292:	60a6                	ld	ra,72(sp)
ffffffffc0202294:	6406                	ld	s0,64(sp)
ffffffffc0202296:	74e2                	ld	s1,56(sp)
ffffffffc0202298:	7942                	ld	s2,48(sp)
ffffffffc020229a:	79a2                	ld	s3,40(sp)
ffffffffc020229c:	7a02                	ld	s4,32(sp)
ffffffffc020229e:	6ae2                	ld	s5,24(sp)
ffffffffc02022a0:	6b42                	ld	s6,16(sp)
ffffffffc02022a2:	6ba2                	ld	s7,8(sp)
ffffffffc02022a4:	6c02                	ld	s8,0(sp)
ffffffffc02022a6:	6161                	addi	sp,sp,80
ffffffffc02022a8:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc02022aa:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02022ac:	4481                	li	s1,0
ffffffffc02022ae:	4901                	li	s2,0
ffffffffc02022b0:	b3b9                	j	ffffffffc0201ffe <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02022b2:	00003697          	auipc	a3,0x3
ffffffffc02022b6:	0e668693          	addi	a3,a3,230 # ffffffffc0205398 <commands+0xc90>
ffffffffc02022ba:	00003617          	auipc	a2,0x3
ffffffffc02022be:	b6660613          	addi	a2,a2,-1178 # ffffffffc0204e20 <commands+0x718>
ffffffffc02022c2:	0f000593          	li	a1,240
ffffffffc02022c6:	00003517          	auipc	a0,0x3
ffffffffc02022ca:	46250513          	addi	a0,a0,1122 # ffffffffc0205728 <commands+0x1020>
ffffffffc02022ce:	e35fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02022d2:	00003697          	auipc	a3,0x3
ffffffffc02022d6:	4ce68693          	addi	a3,a3,1230 # ffffffffc02057a0 <commands+0x1098>
ffffffffc02022da:	00003617          	auipc	a2,0x3
ffffffffc02022de:	b4660613          	addi	a2,a2,-1210 # ffffffffc0204e20 <commands+0x718>
ffffffffc02022e2:	0bd00593          	li	a1,189
ffffffffc02022e6:	00003517          	auipc	a0,0x3
ffffffffc02022ea:	44250513          	addi	a0,a0,1090 # ffffffffc0205728 <commands+0x1020>
ffffffffc02022ee:	e15fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02022f2:	00003697          	auipc	a3,0x3
ffffffffc02022f6:	4d668693          	addi	a3,a3,1238 # ffffffffc02057c8 <commands+0x10c0>
ffffffffc02022fa:	00003617          	auipc	a2,0x3
ffffffffc02022fe:	b2660613          	addi	a2,a2,-1242 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202302:	0be00593          	li	a1,190
ffffffffc0202306:	00003517          	auipc	a0,0x3
ffffffffc020230a:	42250513          	addi	a0,a0,1058 # ffffffffc0205728 <commands+0x1020>
ffffffffc020230e:	df5fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0202312:	00003697          	auipc	a3,0x3
ffffffffc0202316:	4f668693          	addi	a3,a3,1270 # ffffffffc0205808 <commands+0x1100>
ffffffffc020231a:	00003617          	auipc	a2,0x3
ffffffffc020231e:	b0660613          	addi	a2,a2,-1274 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202322:	0c000593          	li	a1,192
ffffffffc0202326:	00003517          	auipc	a0,0x3
ffffffffc020232a:	40250513          	addi	a0,a0,1026 # ffffffffc0205728 <commands+0x1020>
ffffffffc020232e:	dd5fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0202332:	00003697          	auipc	a3,0x3
ffffffffc0202336:	55e68693          	addi	a3,a3,1374 # ffffffffc0205890 <commands+0x1188>
ffffffffc020233a:	00003617          	auipc	a2,0x3
ffffffffc020233e:	ae660613          	addi	a2,a2,-1306 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202342:	0d900593          	li	a1,217
ffffffffc0202346:	00003517          	auipc	a0,0x3
ffffffffc020234a:	3e250513          	addi	a0,a0,994 # ffffffffc0205728 <commands+0x1020>
ffffffffc020234e:	db5fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202352:	00003697          	auipc	a3,0x3
ffffffffc0202356:	3ee68693          	addi	a3,a3,1006 # ffffffffc0205740 <commands+0x1038>
ffffffffc020235a:	00003617          	auipc	a2,0x3
ffffffffc020235e:	ac660613          	addi	a2,a2,-1338 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202362:	0d200593          	li	a1,210
ffffffffc0202366:	00003517          	auipc	a0,0x3
ffffffffc020236a:	3c250513          	addi	a0,a0,962 # ffffffffc0205728 <commands+0x1020>
ffffffffc020236e:	d95fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free == 3);
ffffffffc0202372:	00003697          	auipc	a3,0x3
ffffffffc0202376:	50e68693          	addi	a3,a3,1294 # ffffffffc0205880 <commands+0x1178>
ffffffffc020237a:	00003617          	auipc	a2,0x3
ffffffffc020237e:	aa660613          	addi	a2,a2,-1370 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202382:	0d000593          	li	a1,208
ffffffffc0202386:	00003517          	auipc	a0,0x3
ffffffffc020238a:	3a250513          	addi	a0,a0,930 # ffffffffc0205728 <commands+0x1020>
ffffffffc020238e:	d75fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202392:	00003697          	auipc	a3,0x3
ffffffffc0202396:	4d668693          	addi	a3,a3,1238 # ffffffffc0205868 <commands+0x1160>
ffffffffc020239a:	00003617          	auipc	a2,0x3
ffffffffc020239e:	a8660613          	addi	a2,a2,-1402 # ffffffffc0204e20 <commands+0x718>
ffffffffc02023a2:	0cb00593          	li	a1,203
ffffffffc02023a6:	00003517          	auipc	a0,0x3
ffffffffc02023aa:	38250513          	addi	a0,a0,898 # ffffffffc0205728 <commands+0x1020>
ffffffffc02023ae:	d55fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02023b2:	00003697          	auipc	a3,0x3
ffffffffc02023b6:	49668693          	addi	a3,a3,1174 # ffffffffc0205848 <commands+0x1140>
ffffffffc02023ba:	00003617          	auipc	a2,0x3
ffffffffc02023be:	a6660613          	addi	a2,a2,-1434 # ffffffffc0204e20 <commands+0x718>
ffffffffc02023c2:	0c200593          	li	a1,194
ffffffffc02023c6:	00003517          	auipc	a0,0x3
ffffffffc02023ca:	36250513          	addi	a0,a0,866 # ffffffffc0205728 <commands+0x1020>
ffffffffc02023ce:	d35fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(p0 != NULL);
ffffffffc02023d2:	00003697          	auipc	a3,0x3
ffffffffc02023d6:	4f668693          	addi	a3,a3,1270 # ffffffffc02058c8 <commands+0x11c0>
ffffffffc02023da:	00003617          	auipc	a2,0x3
ffffffffc02023de:	a4660613          	addi	a2,a2,-1466 # ffffffffc0204e20 <commands+0x718>
ffffffffc02023e2:	0f800593          	li	a1,248
ffffffffc02023e6:	00003517          	auipc	a0,0x3
ffffffffc02023ea:	34250513          	addi	a0,a0,834 # ffffffffc0205728 <commands+0x1020>
ffffffffc02023ee:	d15fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free == 0);
ffffffffc02023f2:	00003697          	auipc	a3,0x3
ffffffffc02023f6:	15668693          	addi	a3,a3,342 # ffffffffc0205548 <commands+0xe40>
ffffffffc02023fa:	00003617          	auipc	a2,0x3
ffffffffc02023fe:	a2660613          	addi	a2,a2,-1498 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202402:	0df00593          	li	a1,223
ffffffffc0202406:	00003517          	auipc	a0,0x3
ffffffffc020240a:	32250513          	addi	a0,a0,802 # ffffffffc0205728 <commands+0x1020>
ffffffffc020240e:	cf5fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202412:	00003697          	auipc	a3,0x3
ffffffffc0202416:	45668693          	addi	a3,a3,1110 # ffffffffc0205868 <commands+0x1160>
ffffffffc020241a:	00003617          	auipc	a2,0x3
ffffffffc020241e:	a0660613          	addi	a2,a2,-1530 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202422:	0dd00593          	li	a1,221
ffffffffc0202426:	00003517          	auipc	a0,0x3
ffffffffc020242a:	30250513          	addi	a0,a0,770 # ffffffffc0205728 <commands+0x1020>
ffffffffc020242e:	cd5fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0202432:	00003697          	auipc	a3,0x3
ffffffffc0202436:	47668693          	addi	a3,a3,1142 # ffffffffc02058a8 <commands+0x11a0>
ffffffffc020243a:	00003617          	auipc	a2,0x3
ffffffffc020243e:	9e660613          	addi	a2,a2,-1562 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202442:	0dc00593          	li	a1,220
ffffffffc0202446:	00003517          	auipc	a0,0x3
ffffffffc020244a:	2e250513          	addi	a0,a0,738 # ffffffffc0205728 <commands+0x1020>
ffffffffc020244e:	cb5fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202452:	00003697          	auipc	a3,0x3
ffffffffc0202456:	2ee68693          	addi	a3,a3,750 # ffffffffc0205740 <commands+0x1038>
ffffffffc020245a:	00003617          	auipc	a2,0x3
ffffffffc020245e:	9c660613          	addi	a2,a2,-1594 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202462:	0b900593          	li	a1,185
ffffffffc0202466:	00003517          	auipc	a0,0x3
ffffffffc020246a:	2c250513          	addi	a0,a0,706 # ffffffffc0205728 <commands+0x1020>
ffffffffc020246e:	c95fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202472:	00003697          	auipc	a3,0x3
ffffffffc0202476:	3f668693          	addi	a3,a3,1014 # ffffffffc0205868 <commands+0x1160>
ffffffffc020247a:	00003617          	auipc	a2,0x3
ffffffffc020247e:	9a660613          	addi	a2,a2,-1626 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202482:	0d600593          	li	a1,214
ffffffffc0202486:	00003517          	auipc	a0,0x3
ffffffffc020248a:	2a250513          	addi	a0,a0,674 # ffffffffc0205728 <commands+0x1020>
ffffffffc020248e:	c75fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202492:	00003697          	auipc	a3,0x3
ffffffffc0202496:	2ee68693          	addi	a3,a3,750 # ffffffffc0205780 <commands+0x1078>
ffffffffc020249a:	00003617          	auipc	a2,0x3
ffffffffc020249e:	98660613          	addi	a2,a2,-1658 # ffffffffc0204e20 <commands+0x718>
ffffffffc02024a2:	0d400593          	li	a1,212
ffffffffc02024a6:	00003517          	auipc	a0,0x3
ffffffffc02024aa:	28250513          	addi	a0,a0,642 # ffffffffc0205728 <commands+0x1020>
ffffffffc02024ae:	c55fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02024b2:	00003697          	auipc	a3,0x3
ffffffffc02024b6:	2ae68693          	addi	a3,a3,686 # ffffffffc0205760 <commands+0x1058>
ffffffffc02024ba:	00003617          	auipc	a2,0x3
ffffffffc02024be:	96660613          	addi	a2,a2,-1690 # ffffffffc0204e20 <commands+0x718>
ffffffffc02024c2:	0d300593          	li	a1,211
ffffffffc02024c6:	00003517          	auipc	a0,0x3
ffffffffc02024ca:	26250513          	addi	a0,a0,610 # ffffffffc0205728 <commands+0x1020>
ffffffffc02024ce:	c35fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02024d2:	00003697          	auipc	a3,0x3
ffffffffc02024d6:	2ae68693          	addi	a3,a3,686 # ffffffffc0205780 <commands+0x1078>
ffffffffc02024da:	00003617          	auipc	a2,0x3
ffffffffc02024de:	94660613          	addi	a2,a2,-1722 # ffffffffc0204e20 <commands+0x718>
ffffffffc02024e2:	0bb00593          	li	a1,187
ffffffffc02024e6:	00003517          	auipc	a0,0x3
ffffffffc02024ea:	24250513          	addi	a0,a0,578 # ffffffffc0205728 <commands+0x1020>
ffffffffc02024ee:	c15fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(count == 0);
ffffffffc02024f2:	00003697          	auipc	a3,0x3
ffffffffc02024f6:	52668693          	addi	a3,a3,1318 # ffffffffc0205a18 <commands+0x1310>
ffffffffc02024fa:	00003617          	auipc	a2,0x3
ffffffffc02024fe:	92660613          	addi	a2,a2,-1754 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202502:	12500593          	li	a1,293
ffffffffc0202506:	00003517          	auipc	a0,0x3
ffffffffc020250a:	22250513          	addi	a0,a0,546 # ffffffffc0205728 <commands+0x1020>
ffffffffc020250e:	bf5fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free == 0);
ffffffffc0202512:	00003697          	auipc	a3,0x3
ffffffffc0202516:	03668693          	addi	a3,a3,54 # ffffffffc0205548 <commands+0xe40>
ffffffffc020251a:	00003617          	auipc	a2,0x3
ffffffffc020251e:	90660613          	addi	a2,a2,-1786 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202522:	11a00593          	li	a1,282
ffffffffc0202526:	00003517          	auipc	a0,0x3
ffffffffc020252a:	20250513          	addi	a0,a0,514 # ffffffffc0205728 <commands+0x1020>
ffffffffc020252e:	bd5fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202532:	00003697          	auipc	a3,0x3
ffffffffc0202536:	33668693          	addi	a3,a3,822 # ffffffffc0205868 <commands+0x1160>
ffffffffc020253a:	00003617          	auipc	a2,0x3
ffffffffc020253e:	8e660613          	addi	a2,a2,-1818 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202542:	11800593          	li	a1,280
ffffffffc0202546:	00003517          	auipc	a0,0x3
ffffffffc020254a:	1e250513          	addi	a0,a0,482 # ffffffffc0205728 <commands+0x1020>
ffffffffc020254e:	bb5fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0202552:	00003697          	auipc	a3,0x3
ffffffffc0202556:	2d668693          	addi	a3,a3,726 # ffffffffc0205828 <commands+0x1120>
ffffffffc020255a:	00003617          	auipc	a2,0x3
ffffffffc020255e:	8c660613          	addi	a2,a2,-1850 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202562:	0c100593          	li	a1,193
ffffffffc0202566:	00003517          	auipc	a0,0x3
ffffffffc020256a:	1c250513          	addi	a0,a0,450 # ffffffffc0205728 <commands+0x1020>
ffffffffc020256e:	b95fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0202572:	00003697          	auipc	a3,0x3
ffffffffc0202576:	46668693          	addi	a3,a3,1126 # ffffffffc02059d8 <commands+0x12d0>
ffffffffc020257a:	00003617          	auipc	a2,0x3
ffffffffc020257e:	8a660613          	addi	a2,a2,-1882 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202582:	11200593          	li	a1,274
ffffffffc0202586:	00003517          	auipc	a0,0x3
ffffffffc020258a:	1a250513          	addi	a0,a0,418 # ffffffffc0205728 <commands+0x1020>
ffffffffc020258e:	b75fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0202592:	00003697          	auipc	a3,0x3
ffffffffc0202596:	42668693          	addi	a3,a3,1062 # ffffffffc02059b8 <commands+0x12b0>
ffffffffc020259a:	00003617          	auipc	a2,0x3
ffffffffc020259e:	88660613          	addi	a2,a2,-1914 # ffffffffc0204e20 <commands+0x718>
ffffffffc02025a2:	11000593          	li	a1,272
ffffffffc02025a6:	00003517          	auipc	a0,0x3
ffffffffc02025aa:	18250513          	addi	a0,a0,386 # ffffffffc0205728 <commands+0x1020>
ffffffffc02025ae:	b55fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02025b2:	00003697          	auipc	a3,0x3
ffffffffc02025b6:	3de68693          	addi	a3,a3,990 # ffffffffc0205990 <commands+0x1288>
ffffffffc02025ba:	00003617          	auipc	a2,0x3
ffffffffc02025be:	86660613          	addi	a2,a2,-1946 # ffffffffc0204e20 <commands+0x718>
ffffffffc02025c2:	10e00593          	li	a1,270
ffffffffc02025c6:	00003517          	auipc	a0,0x3
ffffffffc02025ca:	16250513          	addi	a0,a0,354 # ffffffffc0205728 <commands+0x1020>
ffffffffc02025ce:	b35fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02025d2:	00003697          	auipc	a3,0x3
ffffffffc02025d6:	39668693          	addi	a3,a3,918 # ffffffffc0205968 <commands+0x1260>
ffffffffc02025da:	00003617          	auipc	a2,0x3
ffffffffc02025de:	84660613          	addi	a2,a2,-1978 # ffffffffc0204e20 <commands+0x718>
ffffffffc02025e2:	10d00593          	li	a1,269
ffffffffc02025e6:	00003517          	auipc	a0,0x3
ffffffffc02025ea:	14250513          	addi	a0,a0,322 # ffffffffc0205728 <commands+0x1020>
ffffffffc02025ee:	b15fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02025f2:	00003697          	auipc	a3,0x3
ffffffffc02025f6:	36668693          	addi	a3,a3,870 # ffffffffc0205958 <commands+0x1250>
ffffffffc02025fa:	00003617          	auipc	a2,0x3
ffffffffc02025fe:	82660613          	addi	a2,a2,-2010 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202602:	10800593          	li	a1,264
ffffffffc0202606:	00003517          	auipc	a0,0x3
ffffffffc020260a:	12250513          	addi	a0,a0,290 # ffffffffc0205728 <commands+0x1020>
ffffffffc020260e:	af5fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202612:	00003697          	auipc	a3,0x3
ffffffffc0202616:	25668693          	addi	a3,a3,598 # ffffffffc0205868 <commands+0x1160>
ffffffffc020261a:	00003617          	auipc	a2,0x3
ffffffffc020261e:	80660613          	addi	a2,a2,-2042 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202622:	10700593          	li	a1,263
ffffffffc0202626:	00003517          	auipc	a0,0x3
ffffffffc020262a:	10250513          	addi	a0,a0,258 # ffffffffc0205728 <commands+0x1020>
ffffffffc020262e:	ad5fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0202632:	00003697          	auipc	a3,0x3
ffffffffc0202636:	30668693          	addi	a3,a3,774 # ffffffffc0205938 <commands+0x1230>
ffffffffc020263a:	00002617          	auipc	a2,0x2
ffffffffc020263e:	7e660613          	addi	a2,a2,2022 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202642:	10600593          	li	a1,262
ffffffffc0202646:	00003517          	auipc	a0,0x3
ffffffffc020264a:	0e250513          	addi	a0,a0,226 # ffffffffc0205728 <commands+0x1020>
ffffffffc020264e:	ab5fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0202652:	00003697          	auipc	a3,0x3
ffffffffc0202656:	2b668693          	addi	a3,a3,694 # ffffffffc0205908 <commands+0x1200>
ffffffffc020265a:	00002617          	auipc	a2,0x2
ffffffffc020265e:	7c660613          	addi	a2,a2,1990 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202662:	10500593          	li	a1,261
ffffffffc0202666:	00003517          	auipc	a0,0x3
ffffffffc020266a:	0c250513          	addi	a0,a0,194 # ffffffffc0205728 <commands+0x1020>
ffffffffc020266e:	a95fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0202672:	00003697          	auipc	a3,0x3
ffffffffc0202676:	27e68693          	addi	a3,a3,638 # ffffffffc02058f0 <commands+0x11e8>
ffffffffc020267a:	00002617          	auipc	a2,0x2
ffffffffc020267e:	7a660613          	addi	a2,a2,1958 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202682:	10400593          	li	a1,260
ffffffffc0202686:	00003517          	auipc	a0,0x3
ffffffffc020268a:	0a250513          	addi	a0,a0,162 # ffffffffc0205728 <commands+0x1020>
ffffffffc020268e:	a75fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202692:	00003697          	auipc	a3,0x3
ffffffffc0202696:	1d668693          	addi	a3,a3,470 # ffffffffc0205868 <commands+0x1160>
ffffffffc020269a:	00002617          	auipc	a2,0x2
ffffffffc020269e:	78660613          	addi	a2,a2,1926 # ffffffffc0204e20 <commands+0x718>
ffffffffc02026a2:	0fe00593          	li	a1,254
ffffffffc02026a6:	00003517          	auipc	a0,0x3
ffffffffc02026aa:	08250513          	addi	a0,a0,130 # ffffffffc0205728 <commands+0x1020>
ffffffffc02026ae:	a55fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(!PageProperty(p0));
ffffffffc02026b2:	00003697          	auipc	a3,0x3
ffffffffc02026b6:	22668693          	addi	a3,a3,550 # ffffffffc02058d8 <commands+0x11d0>
ffffffffc02026ba:	00002617          	auipc	a2,0x2
ffffffffc02026be:	76660613          	addi	a2,a2,1894 # ffffffffc0204e20 <commands+0x718>
ffffffffc02026c2:	0f900593          	li	a1,249
ffffffffc02026c6:	00003517          	auipc	a0,0x3
ffffffffc02026ca:	06250513          	addi	a0,a0,98 # ffffffffc0205728 <commands+0x1020>
ffffffffc02026ce:	a35fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02026d2:	00003697          	auipc	a3,0x3
ffffffffc02026d6:	32668693          	addi	a3,a3,806 # ffffffffc02059f8 <commands+0x12f0>
ffffffffc02026da:	00002617          	auipc	a2,0x2
ffffffffc02026de:	74660613          	addi	a2,a2,1862 # ffffffffc0204e20 <commands+0x718>
ffffffffc02026e2:	11700593          	li	a1,279
ffffffffc02026e6:	00003517          	auipc	a0,0x3
ffffffffc02026ea:	04250513          	addi	a0,a0,66 # ffffffffc0205728 <commands+0x1020>
ffffffffc02026ee:	a15fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(total == 0);
ffffffffc02026f2:	00003697          	auipc	a3,0x3
ffffffffc02026f6:	33668693          	addi	a3,a3,822 # ffffffffc0205a28 <commands+0x1320>
ffffffffc02026fa:	00002617          	auipc	a2,0x2
ffffffffc02026fe:	72660613          	addi	a2,a2,1830 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202702:	12600593          	li	a1,294
ffffffffc0202706:	00003517          	auipc	a0,0x3
ffffffffc020270a:	02250513          	addi	a0,a0,34 # ffffffffc0205728 <commands+0x1020>
ffffffffc020270e:	9f5fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(total == nr_free_pages());
ffffffffc0202712:	00003697          	auipc	a3,0x3
ffffffffc0202716:	c9668693          	addi	a3,a3,-874 # ffffffffc02053a8 <commands+0xca0>
ffffffffc020271a:	00002617          	auipc	a2,0x2
ffffffffc020271e:	70660613          	addi	a2,a2,1798 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202722:	0f300593          	li	a1,243
ffffffffc0202726:	00003517          	auipc	a0,0x3
ffffffffc020272a:	00250513          	addi	a0,a0,2 # ffffffffc0205728 <commands+0x1020>
ffffffffc020272e:	9d5fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202732:	00003697          	auipc	a3,0x3
ffffffffc0202736:	02e68693          	addi	a3,a3,46 # ffffffffc0205760 <commands+0x1058>
ffffffffc020273a:	00002617          	auipc	a2,0x2
ffffffffc020273e:	6e660613          	addi	a2,a2,1766 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202742:	0ba00593          	li	a1,186
ffffffffc0202746:	00003517          	auipc	a0,0x3
ffffffffc020274a:	fe250513          	addi	a0,a0,-30 # ffffffffc0205728 <commands+0x1020>
ffffffffc020274e:	9b5fd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0202752 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0202752:	1141                	addi	sp,sp,-16
ffffffffc0202754:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0202756:	14058a63          	beqz	a1,ffffffffc02028aa <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc020275a:	00359693          	slli	a3,a1,0x3
ffffffffc020275e:	96ae                	add	a3,a3,a1
ffffffffc0202760:	068e                	slli	a3,a3,0x3
ffffffffc0202762:	96aa                	add	a3,a3,a0
ffffffffc0202764:	87aa                	mv	a5,a0
ffffffffc0202766:	02d50263          	beq	a0,a3,ffffffffc020278a <default_free_pages+0x38>
ffffffffc020276a:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020276c:	8b05                	andi	a4,a4,1
ffffffffc020276e:	10071e63          	bnez	a4,ffffffffc020288a <default_free_pages+0x138>
ffffffffc0202772:	6798                	ld	a4,8(a5)
ffffffffc0202774:	8b09                	andi	a4,a4,2
ffffffffc0202776:	10071a63          	bnez	a4,ffffffffc020288a <default_free_pages+0x138>
        p->flags = 0;
ffffffffc020277a:	0007b423          	sd	zero,8(a5)
    return page->ref; 
}

// 设置 Page 的引用计数
static inline void set_page_ref(struct Page *page, int val) { 
    page->ref = val; 
ffffffffc020277e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0202782:	04878793          	addi	a5,a5,72
ffffffffc0202786:	fed792e3          	bne	a5,a3,ffffffffc020276a <default_free_pages+0x18>
    base->property = n;
ffffffffc020278a:	2581                	sext.w	a1,a1
ffffffffc020278c:	cd0c                	sw	a1,24(a0)
    SetPageProperty(base);
ffffffffc020278e:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0202792:	4789                	li	a5,2
ffffffffc0202794:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0202798:	0000f697          	auipc	a3,0xf
ffffffffc020279c:	94868693          	addi	a3,a3,-1720 # ffffffffc02110e0 <free_area>
ffffffffc02027a0:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02027a2:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02027a4:	02050613          	addi	a2,a0,32
    nr_free += n;
ffffffffc02027a8:	9db9                	addw	a1,a1,a4
ffffffffc02027aa:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02027ac:	0ad78863          	beq	a5,a3,ffffffffc020285c <default_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc02027b0:	fe078713          	addi	a4,a5,-32
ffffffffc02027b4:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02027b8:	4581                	li	a1,0
            if (base < page) {
ffffffffc02027ba:	00e56a63          	bltu	a0,a4,ffffffffc02027ce <default_free_pages+0x7c>
    return listelm->next;
ffffffffc02027be:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02027c0:	06d70263          	beq	a4,a3,ffffffffc0202824 <default_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc02027c4:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02027c6:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc02027ca:	fee57ae3          	bgeu	a0,a4,ffffffffc02027be <default_free_pages+0x6c>
ffffffffc02027ce:	c199                	beqz	a1,ffffffffc02027d4 <default_free_pages+0x82>
ffffffffc02027d0:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02027d4:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc02027d6:	e390                	sd	a2,0(a5)
ffffffffc02027d8:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02027da:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02027dc:	f118                	sd	a4,32(a0)
    if (le != &free_list) {
ffffffffc02027de:	02d70063          	beq	a4,a3,ffffffffc02027fe <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc02027e2:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc02027e6:	fe070593          	addi	a1,a4,-32
        if (p + p->property == base) {
ffffffffc02027ea:	02081613          	slli	a2,a6,0x20
ffffffffc02027ee:	9201                	srli	a2,a2,0x20
ffffffffc02027f0:	00361793          	slli	a5,a2,0x3
ffffffffc02027f4:	97b2                	add	a5,a5,a2
ffffffffc02027f6:	078e                	slli	a5,a5,0x3
ffffffffc02027f8:	97ae                	add	a5,a5,a1
ffffffffc02027fa:	02f50f63          	beq	a0,a5,ffffffffc0202838 <default_free_pages+0xe6>
    return listelm->next;
ffffffffc02027fe:	7518                	ld	a4,40(a0)
    if (le != &free_list) {
ffffffffc0202800:	00d70f63          	beq	a4,a3,ffffffffc020281e <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc0202804:	4d0c                	lw	a1,24(a0)
        p = le2page(le, page_link);
ffffffffc0202806:	fe070693          	addi	a3,a4,-32
        if (base + base->property == p) {
ffffffffc020280a:	02059613          	slli	a2,a1,0x20
ffffffffc020280e:	9201                	srli	a2,a2,0x20
ffffffffc0202810:	00361793          	slli	a5,a2,0x3
ffffffffc0202814:	97b2                	add	a5,a5,a2
ffffffffc0202816:	078e                	slli	a5,a5,0x3
ffffffffc0202818:	97aa                	add	a5,a5,a0
ffffffffc020281a:	04f68863          	beq	a3,a5,ffffffffc020286a <default_free_pages+0x118>
}
ffffffffc020281e:	60a2                	ld	ra,8(sp)
ffffffffc0202820:	0141                	addi	sp,sp,16
ffffffffc0202822:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0202824:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202826:	f514                	sd	a3,40(a0)
    return listelm->next;
ffffffffc0202828:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020282a:	f11c                	sd	a5,32(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020282c:	02d70563          	beq	a4,a3,ffffffffc0202856 <default_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc0202830:	8832                	mv	a6,a2
ffffffffc0202832:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0202834:	87ba                	mv	a5,a4
ffffffffc0202836:	bf41                	j	ffffffffc02027c6 <default_free_pages+0x74>
            p->property += base->property;
ffffffffc0202838:	4d1c                	lw	a5,24(a0)
ffffffffc020283a:	0107883b          	addw	a6,a5,a6
ffffffffc020283e:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0202842:	57f5                	li	a5,-3
ffffffffc0202844:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0202848:	7110                	ld	a2,32(a0)
ffffffffc020284a:	751c                	ld	a5,40(a0)
            base = p;
ffffffffc020284c:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc020284e:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc0202850:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0202852:	e390                	sd	a2,0(a5)
ffffffffc0202854:	b775                	j	ffffffffc0202800 <default_free_pages+0xae>
ffffffffc0202856:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0202858:	873e                	mv	a4,a5
ffffffffc020285a:	b761                	j	ffffffffc02027e2 <default_free_pages+0x90>
}
ffffffffc020285c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020285e:	e390                	sd	a2,0(a5)
ffffffffc0202860:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202862:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0202864:	f11c                	sd	a5,32(a0)
ffffffffc0202866:	0141                	addi	sp,sp,16
ffffffffc0202868:	8082                	ret
            base->property += p->property;
ffffffffc020286a:	ff872783          	lw	a5,-8(a4)
ffffffffc020286e:	fe870693          	addi	a3,a4,-24
ffffffffc0202872:	9dbd                	addw	a1,a1,a5
ffffffffc0202874:	cd0c                	sw	a1,24(a0)
ffffffffc0202876:	57f5                	li	a5,-3
ffffffffc0202878:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020287c:	6314                	ld	a3,0(a4)
ffffffffc020287e:	671c                	ld	a5,8(a4)
}
ffffffffc0202880:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0202882:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0202884:	e394                	sd	a3,0(a5)
ffffffffc0202886:	0141                	addi	sp,sp,16
ffffffffc0202888:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020288a:	00003697          	auipc	a3,0x3
ffffffffc020288e:	1b668693          	addi	a3,a3,438 # ffffffffc0205a40 <commands+0x1338>
ffffffffc0202892:	00002617          	auipc	a2,0x2
ffffffffc0202896:	58e60613          	addi	a2,a2,1422 # ffffffffc0204e20 <commands+0x718>
ffffffffc020289a:	08300593          	li	a1,131
ffffffffc020289e:	00003517          	auipc	a0,0x3
ffffffffc02028a2:	e8a50513          	addi	a0,a0,-374 # ffffffffc0205728 <commands+0x1020>
ffffffffc02028a6:	85dfd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(n > 0);
ffffffffc02028aa:	00003697          	auipc	a3,0x3
ffffffffc02028ae:	18e68693          	addi	a3,a3,398 # ffffffffc0205a38 <commands+0x1330>
ffffffffc02028b2:	00002617          	auipc	a2,0x2
ffffffffc02028b6:	56e60613          	addi	a2,a2,1390 # ffffffffc0204e20 <commands+0x718>
ffffffffc02028ba:	08000593          	li	a1,128
ffffffffc02028be:	00003517          	auipc	a0,0x3
ffffffffc02028c2:	e6a50513          	addi	a0,a0,-406 # ffffffffc0205728 <commands+0x1020>
ffffffffc02028c6:	83dfd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc02028ca <default_alloc_pages>:
    assert(n > 0);
ffffffffc02028ca:	c959                	beqz	a0,ffffffffc0202960 <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc02028cc:	0000f597          	auipc	a1,0xf
ffffffffc02028d0:	81458593          	addi	a1,a1,-2028 # ffffffffc02110e0 <free_area>
ffffffffc02028d4:	0105a803          	lw	a6,16(a1)
ffffffffc02028d8:	862a                	mv	a2,a0
ffffffffc02028da:	02081793          	slli	a5,a6,0x20
ffffffffc02028de:	9381                	srli	a5,a5,0x20
ffffffffc02028e0:	00a7ee63          	bltu	a5,a0,ffffffffc02028fc <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02028e4:	87ae                	mv	a5,a1
ffffffffc02028e6:	a801                	j	ffffffffc02028f6 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc02028e8:	ff87a703          	lw	a4,-8(a5)
ffffffffc02028ec:	02071693          	slli	a3,a4,0x20
ffffffffc02028f0:	9281                	srli	a3,a3,0x20
ffffffffc02028f2:	00c6f763          	bgeu	a3,a2,ffffffffc0202900 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02028f6:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02028f8:	feb798e3          	bne	a5,a1,ffffffffc02028e8 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02028fc:	4501                	li	a0,0
}
ffffffffc02028fe:	8082                	ret
    return listelm->prev;
ffffffffc0202900:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0202904:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0202908:	fe078513          	addi	a0,a5,-32
            p->property = page->property - n;
ffffffffc020290c:	00060e1b          	sext.w	t3,a2
    prev->next = next;
ffffffffc0202910:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0202914:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0202918:	02d67b63          	bgeu	a2,a3,ffffffffc020294e <default_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc020291c:	00361693          	slli	a3,a2,0x3
ffffffffc0202920:	96b2                	add	a3,a3,a2
ffffffffc0202922:	068e                	slli	a3,a3,0x3
ffffffffc0202924:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc0202926:	41c7073b          	subw	a4,a4,t3
ffffffffc020292a:	ce98                	sw	a4,24(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020292c:	00868613          	addi	a2,a3,8
ffffffffc0202930:	4709                	li	a4,2
ffffffffc0202932:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0202936:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc020293a:	02068613          	addi	a2,a3,32
        nr_free -= n;
ffffffffc020293e:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0202942:	e310                	sd	a2,0(a4)
ffffffffc0202944:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0202948:	f698                	sd	a4,40(a3)
    elm->prev = prev;
ffffffffc020294a:	0316b023          	sd	a7,32(a3)
ffffffffc020294e:	41c8083b          	subw	a6,a6,t3
ffffffffc0202952:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0202956:	5775                	li	a4,-3
ffffffffc0202958:	17a1                	addi	a5,a5,-24
ffffffffc020295a:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020295e:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0202960:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0202962:	00003697          	auipc	a3,0x3
ffffffffc0202966:	0d668693          	addi	a3,a3,214 # ffffffffc0205a38 <commands+0x1330>
ffffffffc020296a:	00002617          	auipc	a2,0x2
ffffffffc020296e:	4b660613          	addi	a2,a2,1206 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202972:	06200593          	li	a1,98
ffffffffc0202976:	00003517          	auipc	a0,0x3
ffffffffc020297a:	db250513          	addi	a0,a0,-590 # ffffffffc0205728 <commands+0x1020>
default_alloc_pages(size_t n) {
ffffffffc020297e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0202980:	f82fd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0202984 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0202984:	1141                	addi	sp,sp,-16
ffffffffc0202986:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0202988:	c9e1                	beqz	a1,ffffffffc0202a58 <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc020298a:	00359693          	slli	a3,a1,0x3
ffffffffc020298e:	96ae                	add	a3,a3,a1
ffffffffc0202990:	068e                	slli	a3,a3,0x3
ffffffffc0202992:	96aa                	add	a3,a3,a0
ffffffffc0202994:	87aa                	mv	a5,a0
ffffffffc0202996:	00d50f63          	beq	a0,a3,ffffffffc02029b4 <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020299a:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc020299c:	8b05                	andi	a4,a4,1
ffffffffc020299e:	cf49                	beqz	a4,ffffffffc0202a38 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc02029a0:	0007ac23          	sw	zero,24(a5)
ffffffffc02029a4:	0007b423          	sd	zero,8(a5)
ffffffffc02029a8:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02029ac:	04878793          	addi	a5,a5,72
ffffffffc02029b0:	fed795e3          	bne	a5,a3,ffffffffc020299a <default_init_memmap+0x16>
    base->property = n;
ffffffffc02029b4:	2581                	sext.w	a1,a1
ffffffffc02029b6:	cd0c                	sw	a1,24(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02029b8:	4789                	li	a5,2
ffffffffc02029ba:	00850713          	addi	a4,a0,8
ffffffffc02029be:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02029c2:	0000e697          	auipc	a3,0xe
ffffffffc02029c6:	71e68693          	addi	a3,a3,1822 # ffffffffc02110e0 <free_area>
ffffffffc02029ca:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02029cc:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02029ce:	02050613          	addi	a2,a0,32
    nr_free += n;
ffffffffc02029d2:	9db9                	addw	a1,a1,a4
ffffffffc02029d4:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02029d6:	04d78a63          	beq	a5,a3,ffffffffc0202a2a <default_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc02029da:	fe078713          	addi	a4,a5,-32
ffffffffc02029de:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02029e2:	4581                	li	a1,0
            if (base < page) {
ffffffffc02029e4:	00e56a63          	bltu	a0,a4,ffffffffc02029f8 <default_init_memmap+0x74>
    return listelm->next;
ffffffffc02029e8:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02029ea:	02d70263          	beq	a4,a3,ffffffffc0202a0e <default_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc02029ee:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02029f0:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc02029f4:	fee57ae3          	bgeu	a0,a4,ffffffffc02029e8 <default_init_memmap+0x64>
ffffffffc02029f8:	c199                	beqz	a1,ffffffffc02029fe <default_init_memmap+0x7a>
ffffffffc02029fa:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02029fe:	6398                	ld	a4,0(a5)
}
ffffffffc0202a00:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0202a02:	e390                	sd	a2,0(a5)
ffffffffc0202a04:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0202a06:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0202a08:	f118                	sd	a4,32(a0)
ffffffffc0202a0a:	0141                	addi	sp,sp,16
ffffffffc0202a0c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0202a0e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202a10:	f514                	sd	a3,40(a0)
    return listelm->next;
ffffffffc0202a12:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0202a14:	f11c                	sd	a5,32(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0202a16:	00d70663          	beq	a4,a3,ffffffffc0202a22 <default_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc0202a1a:	8832                	mv	a6,a2
ffffffffc0202a1c:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0202a1e:	87ba                	mv	a5,a4
ffffffffc0202a20:	bfc1                	j	ffffffffc02029f0 <default_init_memmap+0x6c>
}
ffffffffc0202a22:	60a2                	ld	ra,8(sp)
ffffffffc0202a24:	e290                	sd	a2,0(a3)
ffffffffc0202a26:	0141                	addi	sp,sp,16
ffffffffc0202a28:	8082                	ret
ffffffffc0202a2a:	60a2                	ld	ra,8(sp)
ffffffffc0202a2c:	e390                	sd	a2,0(a5)
ffffffffc0202a2e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202a30:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0202a32:	f11c                	sd	a5,32(a0)
ffffffffc0202a34:	0141                	addi	sp,sp,16
ffffffffc0202a36:	8082                	ret
        assert(PageReserved(p));
ffffffffc0202a38:	00003697          	auipc	a3,0x3
ffffffffc0202a3c:	03068693          	addi	a3,a3,48 # ffffffffc0205a68 <commands+0x1360>
ffffffffc0202a40:	00002617          	auipc	a2,0x2
ffffffffc0202a44:	3e060613          	addi	a2,a2,992 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202a48:	04900593          	li	a1,73
ffffffffc0202a4c:	00003517          	auipc	a0,0x3
ffffffffc0202a50:	cdc50513          	addi	a0,a0,-804 # ffffffffc0205728 <commands+0x1020>
ffffffffc0202a54:	eaefd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(n > 0);
ffffffffc0202a58:	00003697          	auipc	a3,0x3
ffffffffc0202a5c:	fe068693          	addi	a3,a3,-32 # ffffffffc0205a38 <commands+0x1330>
ffffffffc0202a60:	00002617          	auipc	a2,0x2
ffffffffc0202a64:	3c060613          	addi	a2,a2,960 # ffffffffc0204e20 <commands+0x718>
ffffffffc0202a68:	04600593          	li	a1,70
ffffffffc0202a6c:	00003517          	auipc	a0,0x3
ffffffffc0202a70:	cbc50513          	addi	a0,a0,-836 # ffffffffc0205728 <commands+0x1020>
ffffffffc0202a74:	e8efd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0202a78 <pa2page.part.0>:
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc0202a78:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa"); // 如果无效，触发 panic
ffffffffc0202a7a:	00002617          	auipc	a2,0x2
ffffffffc0202a7e:	7b660613          	addi	a2,a2,1974 # ffffffffc0205230 <commands+0xb28>
ffffffffc0202a82:	07000593          	li	a1,112
ffffffffc0202a86:	00002517          	auipc	a0,0x2
ffffffffc0202a8a:	7ca50513          	addi	a0,a0,1994 # ffffffffc0205250 <commands+0xb48>
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc0202a8e:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa"); // 如果无效，触发 panic
ffffffffc0202a90:	e72fd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0202a94 <pte2page.part.0>:
static inline struct Page *pte2page(pte_t pte) {
ffffffffc0202a94:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte"); // 无效时触发 panic
ffffffffc0202a96:	00003617          	auipc	a2,0x3
ffffffffc0202a9a:	ada60613          	addi	a2,a2,-1318 # ffffffffc0205570 <commands+0xe68>
ffffffffc0202a9e:	08200593          	li	a1,130
ffffffffc0202aa2:	00002517          	auipc	a0,0x2
ffffffffc0202aa6:	7ae50513          	addi	a0,a0,1966 # ffffffffc0205250 <commands+0xb48>
static inline struct Page *pte2page(pte_t pte) {
ffffffffc0202aaa:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte"); // 无效时触发 panic
ffffffffc0202aac:	e56fd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0202ab0 <alloc_pages>:
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - 调用 pmm_manager->alloc_pages 分配连续的 n * PAGESIZE 大小的内存
struct Page *alloc_pages(size_t n) {
ffffffffc0202ab0:	7139                	addi	sp,sp,-64
ffffffffc0202ab2:	f426                	sd	s1,40(sp)
ffffffffc0202ab4:	f04a                	sd	s2,32(sp)
ffffffffc0202ab6:	ec4e                	sd	s3,24(sp)
ffffffffc0202ab8:	e852                	sd	s4,16(sp)
ffffffffc0202aba:	e456                	sd	s5,8(sp)
ffffffffc0202abc:	e05a                	sd	s6,0(sp)
ffffffffc0202abe:	fc06                	sd	ra,56(sp)
ffffffffc0202ac0:	f822                	sd	s0,48(sp)
ffffffffc0202ac2:	84aa                	mv	s1,a0
ffffffffc0202ac4:	0000f917          	auipc	s2,0xf
ffffffffc0202ac8:	a9490913          	addi	s2,s2,-1388 # ffffffffc0211558 <pmm_manager>
        { 
            page = pmm_manager->alloc_pages(n); // 调用内存管理器的分配函数
        }
        local_intr_restore(intr_flag); // 恢复中断状态

        if (page != NULL || n > 1 || swap_init_ok == 0) break; // 成功分配到内存或不需要交换则退出循环
ffffffffc0202acc:	4a05                	li	s4,1
ffffffffc0202ace:	0000fa97          	auipc	s5,0xf
ffffffffc0202ad2:	a62a8a93          	addi	s5,s5,-1438 # ffffffffc0211530 <swap_init_ok>

        extern struct mm_struct *check_mm_struct; // 引用当前内存管理结构体
        swap_out(check_mm_struct, n, 0); // 调用 swap_out 函数进行页面置换，尝试释放内存
ffffffffc0202ad6:	0005099b          	sext.w	s3,a0
ffffffffc0202ada:	0000fb17          	auipc	s6,0xf
ffffffffc0202ade:	a36b0b13          	addi	s6,s6,-1482 # ffffffffc0211510 <check_mm_struct>
ffffffffc0202ae2:	a01d                	j	ffffffffc0202b08 <alloc_pages+0x58>
            page = pmm_manager->alloc_pages(n); // 调用内存管理器的分配函数
ffffffffc0202ae4:	00093783          	ld	a5,0(s2)
ffffffffc0202ae8:	6f9c                	ld	a5,24(a5)
ffffffffc0202aea:	9782                	jalr	a5
ffffffffc0202aec:	842a                	mv	s0,a0
        swap_out(check_mm_struct, n, 0); // 调用 swap_out 函数进行页面置换，尝试释放内存
ffffffffc0202aee:	4601                	li	a2,0
ffffffffc0202af0:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break; // 成功分配到内存或不需要交换则退出循环
ffffffffc0202af2:	ec0d                	bnez	s0,ffffffffc0202b2c <alloc_pages+0x7c>
ffffffffc0202af4:	029a6c63          	bltu	s4,s1,ffffffffc0202b2c <alloc_pages+0x7c>
ffffffffc0202af8:	000aa783          	lw	a5,0(s5)
ffffffffc0202afc:	2781                	sext.w	a5,a5
ffffffffc0202afe:	c79d                	beqz	a5,ffffffffc0202b2c <alloc_pages+0x7c>
        swap_out(check_mm_struct, n, 0); // 调用 swap_out 函数进行页面置换，尝试释放内存
ffffffffc0202b00:	000b3503          	ld	a0,0(s6)
ffffffffc0202b04:	b0eff0ef          	jal	ra,ffffffffc0201e12 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202b08:	100027f3          	csrr	a5,sstatus
ffffffffc0202b0c:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n); // 调用内存管理器的分配函数
ffffffffc0202b0e:	8526                	mv	a0,s1
ffffffffc0202b10:	dbf1                	beqz	a5,ffffffffc0202ae4 <alloc_pages+0x34>
        intr_disable();
ffffffffc0202b12:	9ddfd0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc0202b16:	00093783          	ld	a5,0(s2)
ffffffffc0202b1a:	8526                	mv	a0,s1
ffffffffc0202b1c:	6f9c                	ld	a5,24(a5)
ffffffffc0202b1e:	9782                	jalr	a5
ffffffffc0202b20:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202b22:	9c7fd0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
        swap_out(check_mm_struct, n, 0); // 调用 swap_out 函数进行页面置换，尝试释放内存
ffffffffc0202b26:	4601                	li	a2,0
ffffffffc0202b28:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break; // 成功分配到内存或不需要交换则退出循环
ffffffffc0202b2a:	d469                	beqz	s0,ffffffffc0202af4 <alloc_pages+0x44>
    }
    return page; // 返回分配得到的 Page 指针
}
ffffffffc0202b2c:	70e2                	ld	ra,56(sp)
ffffffffc0202b2e:	8522                	mv	a0,s0
ffffffffc0202b30:	7442                	ld	s0,48(sp)
ffffffffc0202b32:	74a2                	ld	s1,40(sp)
ffffffffc0202b34:	7902                	ld	s2,32(sp)
ffffffffc0202b36:	69e2                	ld	s3,24(sp)
ffffffffc0202b38:	6a42                	ld	s4,16(sp)
ffffffffc0202b3a:	6aa2                	ld	s5,8(sp)
ffffffffc0202b3c:	6b02                	ld	s6,0(sp)
ffffffffc0202b3e:	6121                	addi	sp,sp,64
ffffffffc0202b40:	8082                	ret

ffffffffc0202b42 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202b42:	100027f3          	csrr	a5,sstatus
ffffffffc0202b46:	8b89                	andi	a5,a5,2
ffffffffc0202b48:	e799                	bnez	a5,ffffffffc0202b56 <free_pages+0x14>
void free_pages(struct Page *base, size_t n) {
    bool intr_flag; // 保存中断状态

    local_intr_save(intr_flag); // 关闭中断并保存当前中断状态
    { 
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0202b4a:	0000f797          	auipc	a5,0xf
ffffffffc0202b4e:	a0e7b783          	ld	a5,-1522(a5) # ffffffffc0211558 <pmm_manager>
ffffffffc0202b52:	739c                	ld	a5,32(a5)
ffffffffc0202b54:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0202b56:	1101                	addi	sp,sp,-32
ffffffffc0202b58:	ec06                	sd	ra,24(sp)
ffffffffc0202b5a:	e822                	sd	s0,16(sp)
ffffffffc0202b5c:	e426                	sd	s1,8(sp)
ffffffffc0202b5e:	842a                	mv	s0,a0
ffffffffc0202b60:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0202b62:	98dfd0ef          	jal	ra,ffffffffc02004ee <intr_disable>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0202b66:	0000f797          	auipc	a5,0xf
ffffffffc0202b6a:	9f27b783          	ld	a5,-1550(a5) # ffffffffc0211558 <pmm_manager>
ffffffffc0202b6e:	739c                	ld	a5,32(a5)
ffffffffc0202b70:	85a6                	mv	a1,s1
ffffffffc0202b72:	8522                	mv	a0,s0
ffffffffc0202b74:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag); // 恢复中断状态
}
ffffffffc0202b76:	6442                	ld	s0,16(sp)
ffffffffc0202b78:	60e2                	ld	ra,24(sp)
ffffffffc0202b7a:	64a2                	ld	s1,8(sp)
ffffffffc0202b7c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0202b7e:	96bfd06f          	j	ffffffffc02004e8 <intr_enable>

ffffffffc0202b82 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202b82:	100027f3          	csrr	a5,sstatus
ffffffffc0202b86:	8b89                	andi	a5,a5,2
ffffffffc0202b88:	e799                	bnez	a5,ffffffffc0202b96 <nr_free_pages+0x14>
// of current free memory
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0202b8a:	0000f797          	auipc	a5,0xf
ffffffffc0202b8e:	9ce7b783          	ld	a5,-1586(a5) # ffffffffc0211558 <pmm_manager>
ffffffffc0202b92:	779c                	ld	a5,40(a5)
ffffffffc0202b94:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0202b96:	1141                	addi	sp,sp,-16
ffffffffc0202b98:	e406                	sd	ra,8(sp)
ffffffffc0202b9a:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0202b9c:	953fd0ef          	jal	ra,ffffffffc02004ee <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0202ba0:	0000f797          	auipc	a5,0xf
ffffffffc0202ba4:	9b87b783          	ld	a5,-1608(a5) # ffffffffc0211558 <pmm_manager>
ffffffffc0202ba8:	779c                	ld	a5,40(a5)
ffffffffc0202baa:	9782                	jalr	a5
ffffffffc0202bac:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202bae:	93bfd0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0202bb2:	60a2                	ld	ra,8(sp)
ffffffffc0202bb4:	8522                	mv	a0,s0
ffffffffc0202bb6:	6402                	ld	s0,0(sp)
ffffffffc0202bb8:	0141                	addi	sp,sp,16
ffffffffc0202bba:	8082                	ret

ffffffffc0202bbc <get_pte>:
//  la:    需要映射的线性地址
//  create: 指示是否在缺少页表时创建一个新页表
// 返回值：返回页表项的内核虚拟地址
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    // 获取第一级页目录项（PDX1(la) 获取第一级页目录索引）
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0202bbc:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0202bc0:	1ff7f793          	andi	a5,a5,511
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0202bc4:	715d                	addi	sp,sp,-80
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0202bc6:	078e                	slli	a5,a5,0x3
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0202bc8:	fc26                	sd	s1,56(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0202bca:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V)) { // 如果第一级页目录项无效
ffffffffc0202bce:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0202bd0:	f84a                	sd	s2,48(sp)
ffffffffc0202bd2:	f44e                	sd	s3,40(sp)
ffffffffc0202bd4:	f052                	sd	s4,32(sp)
ffffffffc0202bd6:	e486                	sd	ra,72(sp)
ffffffffc0202bd8:	e0a2                	sd	s0,64(sp)
ffffffffc0202bda:	ec56                	sd	s5,24(sp)
ffffffffc0202bdc:	e85a                	sd	s6,16(sp)
ffffffffc0202bde:	e45e                	sd	s7,8(sp)
    if (!(*pdep1 & PTE_V)) { // 如果第一级页目录项无效
ffffffffc0202be0:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0202be4:	892e                	mv	s2,a1
ffffffffc0202be6:	8a32                	mv	s4,a2
ffffffffc0202be8:	0000f997          	auipc	s3,0xf
ffffffffc0202bec:	96098993          	addi	s3,s3,-1696 # ffffffffc0211548 <npage>
    if (!(*pdep1 & PTE_V)) { // 如果第一级页目录项无效
ffffffffc0202bf0:	efb5                	bnez	a5,ffffffffc0202c6c <get_pte+0xb0>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) { // 若 create 为假或分配失败，返回 NULL
ffffffffc0202bf2:	14060c63          	beqz	a2,ffffffffc0202d4a <get_pte+0x18e>
ffffffffc0202bf6:	4505                	li	a0,1
ffffffffc0202bf8:	eb9ff0ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc0202bfc:	842a                	mv	s0,a0
ffffffffc0202bfe:	14050663          	beqz	a0,ffffffffc0202d4a <get_pte+0x18e>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0202c02:	0000fb97          	auipc	s7,0xf
ffffffffc0202c06:	94eb8b93          	addi	s7,s7,-1714 # ffffffffc0211550 <pages>
ffffffffc0202c0a:	000bb503          	ld	a0,0(s7)
ffffffffc0202c0e:	00003b17          	auipc	s6,0x3
ffffffffc0202c12:	732b3b03          	ld	s6,1842(s6) # ffffffffc0206340 <error_string+0x38>
ffffffffc0202c16:	00080ab7          	lui	s5,0x80
ffffffffc0202c1a:	40a40533          	sub	a0,s0,a0
ffffffffc0202c1e:	850d                	srai	a0,a0,0x3
ffffffffc0202c20:	03650533          	mul	a0,a0,s6
            return NULL;
        }
        set_page_ref(page, 1); // 设置页面的引用计数为 1
        uintptr_t pa = page2pa(page); // 获取物理地址
        memset(KADDR(pa), 0, PGSIZE); // 将该页表清零
ffffffffc0202c24:	0000f997          	auipc	s3,0xf
ffffffffc0202c28:	92498993          	addi	s3,s3,-1756 # ffffffffc0211548 <npage>
    page->ref = val; 
ffffffffc0202c2c:	4785                	li	a5,1
ffffffffc0202c2e:	0009b703          	ld	a4,0(s3)
ffffffffc0202c32:	c01c                	sw	a5,0(s0)
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0202c34:	9556                	add	a0,a0,s5
ffffffffc0202c36:	00c51793          	slli	a5,a0,0xc
ffffffffc0202c3a:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc0202c3c:	0532                	slli	a0,a0,0xc
ffffffffc0202c3e:	14e7fd63          	bgeu	a5,a4,ffffffffc0202d98 <get_pte+0x1dc>
ffffffffc0202c42:	0000f797          	auipc	a5,0xf
ffffffffc0202c46:	91e7b783          	ld	a5,-1762(a5) # ffffffffc0211560 <va_pa_offset>
ffffffffc0202c4a:	6605                	lui	a2,0x1
ffffffffc0202c4c:	4581                	li	a1,0
ffffffffc0202c4e:	953e                	add	a0,a0,a5
ffffffffc0202c50:	370010ef          	jal	ra,ffffffffc0203fc0 <memset>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0202c54:	000bb683          	ld	a3,0(s7)
ffffffffc0202c58:	40d406b3          	sub	a3,s0,a3
ffffffffc0202c5c:	868d                	srai	a3,a3,0x3
ffffffffc0202c5e:	036686b3          	mul	a3,a3,s6
ffffffffc0202c62:	96d6                	add	a3,a3,s5
    asm volatile("sfence.vma"); // 刷新 TLB 中的地址映射
}

// 从页帧号和权限位构造页表项 (PTE)
static inline pte_t pte_create(uintptr_t ppn, int type) {
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type; // 将页帧号和权限位组合成 PTE
ffffffffc0202c64:	06aa                	slli	a3,a3,0xa
ffffffffc0202c66:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V); // 创建页目录项，设置为用户和有效
ffffffffc0202c6a:	e094                	sd	a3,0(s1)
    }
    // 获取第二级页目录项，使用 PDX0(la) 索引到正确位置
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202c6c:	77fd                	lui	a5,0xfffff
ffffffffc0202c6e:	068a                	slli	a3,a3,0x2
ffffffffc0202c70:	0009b703          	ld	a4,0(s3)
ffffffffc0202c74:	8efd                	and	a3,a3,a5
ffffffffc0202c76:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202c7a:	0ce7fa63          	bgeu	a5,a4,ffffffffc0202d4e <get_pte+0x192>
ffffffffc0202c7e:	0000fa97          	auipc	s5,0xf
ffffffffc0202c82:	8e2a8a93          	addi	s5,s5,-1822 # ffffffffc0211560 <va_pa_offset>
ffffffffc0202c86:	000ab403          	ld	s0,0(s5)
ffffffffc0202c8a:	01595793          	srli	a5,s2,0x15
ffffffffc0202c8e:	1ff7f793          	andi	a5,a5,511
ffffffffc0202c92:	96a2                	add	a3,a3,s0
ffffffffc0202c94:	00379413          	slli	s0,a5,0x3
ffffffffc0202c98:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) { // 如果第二级页目录项无效
ffffffffc0202c9a:	6014                	ld	a3,0(s0)
ffffffffc0202c9c:	0016f793          	andi	a5,a3,1
ffffffffc0202ca0:	ebad                	bnez	a5,ffffffffc0202d12 <get_pte+0x156>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) { // 若 create 为假或分配失败，返回 NULL
ffffffffc0202ca2:	0a0a0463          	beqz	s4,ffffffffc0202d4a <get_pte+0x18e>
ffffffffc0202ca6:	4505                	li	a0,1
ffffffffc0202ca8:	e09ff0ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc0202cac:	84aa                	mv	s1,a0
ffffffffc0202cae:	cd51                	beqz	a0,ffffffffc0202d4a <get_pte+0x18e>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0202cb0:	0000fb97          	auipc	s7,0xf
ffffffffc0202cb4:	8a0b8b93          	addi	s7,s7,-1888 # ffffffffc0211550 <pages>
ffffffffc0202cb8:	000bb503          	ld	a0,0(s7)
ffffffffc0202cbc:	00003b17          	auipc	s6,0x3
ffffffffc0202cc0:	684b3b03          	ld	s6,1668(s6) # ffffffffc0206340 <error_string+0x38>
ffffffffc0202cc4:	00080a37          	lui	s4,0x80
ffffffffc0202cc8:	40a48533          	sub	a0,s1,a0
ffffffffc0202ccc:	850d                	srai	a0,a0,0x3
ffffffffc0202cce:	03650533          	mul	a0,a0,s6
    page->ref = val; 
ffffffffc0202cd2:	4785                	li	a5,1
            return NULL;
        }
        set_page_ref(page, 1); // 设置页面的引用计数为 1
        uintptr_t pa = page2pa(page); // 获取物理地址
        memset(KADDR(pa), 0, PGSIZE); // 将该页表清零
ffffffffc0202cd4:	0009b703          	ld	a4,0(s3)
ffffffffc0202cd8:	c09c                	sw	a5,0(s1)
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0202cda:	9552                	add	a0,a0,s4
ffffffffc0202cdc:	00c51793          	slli	a5,a0,0xc
ffffffffc0202ce0:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc0202ce2:	0532                	slli	a0,a0,0xc
ffffffffc0202ce4:	08e7fd63          	bgeu	a5,a4,ffffffffc0202d7e <get_pte+0x1c2>
ffffffffc0202ce8:	000ab783          	ld	a5,0(s5)
ffffffffc0202cec:	6605                	lui	a2,0x1
ffffffffc0202cee:	4581                	li	a1,0
ffffffffc0202cf0:	953e                	add	a0,a0,a5
ffffffffc0202cf2:	2ce010ef          	jal	ra,ffffffffc0203fc0 <memset>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0202cf6:	000bb683          	ld	a3,0(s7)
ffffffffc0202cfa:	40d486b3          	sub	a3,s1,a3
ffffffffc0202cfe:	868d                	srai	a3,a3,0x3
ffffffffc0202d00:	036686b3          	mul	a3,a3,s6
ffffffffc0202d04:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type; // 将页帧号和权限位组合成 PTE
ffffffffc0202d06:	06aa                	slli	a3,a3,0xa
ffffffffc0202d08:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V); // 创建页目录项，设置为用户和有效
ffffffffc0202d0c:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)]; // 返回最终页表项指针的内核虚拟地址
ffffffffc0202d0e:	0009b703          	ld	a4,0(s3)
ffffffffc0202d12:	068a                	slli	a3,a3,0x2
ffffffffc0202d14:	757d                	lui	a0,0xfffff
ffffffffc0202d16:	8ee9                	and	a3,a3,a0
ffffffffc0202d18:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202d1c:	04e7f563          	bgeu	a5,a4,ffffffffc0202d66 <get_pte+0x1aa>
ffffffffc0202d20:	000ab503          	ld	a0,0(s5)
ffffffffc0202d24:	00c95913          	srli	s2,s2,0xc
ffffffffc0202d28:	1ff97913          	andi	s2,s2,511
ffffffffc0202d2c:	96aa                	add	a3,a3,a0
ffffffffc0202d2e:	00391513          	slli	a0,s2,0x3
ffffffffc0202d32:	9536                	add	a0,a0,a3
}
ffffffffc0202d34:	60a6                	ld	ra,72(sp)
ffffffffc0202d36:	6406                	ld	s0,64(sp)
ffffffffc0202d38:	74e2                	ld	s1,56(sp)
ffffffffc0202d3a:	7942                	ld	s2,48(sp)
ffffffffc0202d3c:	79a2                	ld	s3,40(sp)
ffffffffc0202d3e:	7a02                	ld	s4,32(sp)
ffffffffc0202d40:	6ae2                	ld	s5,24(sp)
ffffffffc0202d42:	6b42                	ld	s6,16(sp)
ffffffffc0202d44:	6ba2                	ld	s7,8(sp)
ffffffffc0202d46:	6161                	addi	sp,sp,80
ffffffffc0202d48:	8082                	ret
            return NULL;
ffffffffc0202d4a:	4501                	li	a0,0
ffffffffc0202d4c:	b7e5                	j	ffffffffc0202d34 <get_pte+0x178>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202d4e:	00003617          	auipc	a2,0x3
ffffffffc0202d52:	d7a60613          	addi	a2,a2,-646 # ffffffffc0205ac8 <default_pmm_manager+0x38>
ffffffffc0202d56:	0f500593          	li	a1,245
ffffffffc0202d5a:	00003517          	auipc	a0,0x3
ffffffffc0202d5e:	d9650513          	addi	a0,a0,-618 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0202d62:	ba0fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)]; // 返回最终页表项指针的内核虚拟地址
ffffffffc0202d66:	00003617          	auipc	a2,0x3
ffffffffc0202d6a:	d6260613          	addi	a2,a2,-670 # ffffffffc0205ac8 <default_pmm_manager+0x38>
ffffffffc0202d6e:	10000593          	li	a1,256
ffffffffc0202d72:	00003517          	auipc	a0,0x3
ffffffffc0202d76:	d7e50513          	addi	a0,a0,-642 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0202d7a:	b88fd0ef          	jal	ra,ffffffffc0200102 <__panic>
        memset(KADDR(pa), 0, PGSIZE); // 将该页表清零
ffffffffc0202d7e:	86aa                	mv	a3,a0
ffffffffc0202d80:	00003617          	auipc	a2,0x3
ffffffffc0202d84:	d4860613          	addi	a2,a2,-696 # ffffffffc0205ac8 <default_pmm_manager+0x38>
ffffffffc0202d88:	0fd00593          	li	a1,253
ffffffffc0202d8c:	00003517          	auipc	a0,0x3
ffffffffc0202d90:	d6450513          	addi	a0,a0,-668 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0202d94:	b6efd0ef          	jal	ra,ffffffffc0200102 <__panic>
        memset(KADDR(pa), 0, PGSIZE); // 将该页表清零
ffffffffc0202d98:	86aa                	mv	a3,a0
ffffffffc0202d9a:	00003617          	auipc	a2,0x3
ffffffffc0202d9e:	d2e60613          	addi	a2,a2,-722 # ffffffffc0205ac8 <default_pmm_manager+0x38>
ffffffffc0202da2:	0f100593          	li	a1,241
ffffffffc0202da6:	00003517          	auipc	a0,0x3
ffffffffc0202daa:	d4a50513          	addi	a0,a0,-694 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0202dae:	b54fd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0202db2 <get_page>:
// 若 pte 存在且有效，则返回对应 Page，否则返回 NULL
// 参数：
//  pgdir: 页目录指针
//  la:    线性地址
//  ptep_store: 若不为 NULL，存储指向页表项的指针
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0202db2:	1141                	addi	sp,sp,-16
ffffffffc0202db4:	e022                	sd	s0,0(sp)
ffffffffc0202db6:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0); // 获取对应的页表项指针
ffffffffc0202db8:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0202dba:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0); // 获取对应的页表项指针
ffffffffc0202dbc:	e01ff0ef          	jal	ra,ffffffffc0202bbc <get_pte>
    if (ptep_store != NULL) {
ffffffffc0202dc0:	c011                	beqz	s0,ffffffffc0202dc4 <get_page+0x12>
        *ptep_store = ptep; // 将页表项指针存储到 ptep_store
ffffffffc0202dc2:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) { // 如果页表项有效
ffffffffc0202dc4:	c511                	beqz	a0,ffffffffc0202dd0 <get_page+0x1e>
ffffffffc0202dc6:	611c                	ld	a5,0(a0)
        return pte2page(*ptep); // 返回对应的 Page 结构体指针
    }
    return NULL; // 如果页表项无效，返回 NULL
ffffffffc0202dc8:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) { // 如果页表项有效
ffffffffc0202dca:	0017f713          	andi	a4,a5,1
ffffffffc0202dce:	e709                	bnez	a4,ffffffffc0202dd8 <get_page+0x26>
}
ffffffffc0202dd0:	60a2                	ld	ra,8(sp)
ffffffffc0202dd2:	6402                	ld	s0,0(sp)
ffffffffc0202dd4:	0141                	addi	sp,sp,16
ffffffffc0202dd6:	8082                	ret
    return pa2page(PTE_ADDR(pte)); // 提取页表项的物理地址并转换为 Page 结构体指针
ffffffffc0202dd8:	078a                	slli	a5,a5,0x2
ffffffffc0202dda:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0202ddc:	0000e717          	auipc	a4,0xe
ffffffffc0202de0:	76c73703          	ld	a4,1900(a4) # ffffffffc0211548 <npage>
ffffffffc0202de4:	02e7f263          	bgeu	a5,a4,ffffffffc0202e08 <get_page+0x56>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc0202de8:	fff80537          	lui	a0,0xfff80
ffffffffc0202dec:	97aa                	add	a5,a5,a0
ffffffffc0202dee:	60a2                	ld	ra,8(sp)
ffffffffc0202df0:	6402                	ld	s0,0(sp)
ffffffffc0202df2:	00379513          	slli	a0,a5,0x3
ffffffffc0202df6:	97aa                	add	a5,a5,a0
ffffffffc0202df8:	078e                	slli	a5,a5,0x3
ffffffffc0202dfa:	0000e517          	auipc	a0,0xe
ffffffffc0202dfe:	75653503          	ld	a0,1878(a0) # ffffffffc0211550 <pages>
ffffffffc0202e02:	953e                	add	a0,a0,a5
ffffffffc0202e04:	0141                	addi	sp,sp,16
ffffffffc0202e06:	8082                	ret
ffffffffc0202e08:	c71ff0ef          	jal	ra,ffffffffc0202a78 <pa2page.part.0>

ffffffffc0202e0c <page_remove>:

// page_remove - 释放与线性地址 la 关联的 Page 结构体，并清除对应的页表项
// 参数：
//  pgdir: 页目录指针
//  la:    线性地址
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0202e0c:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0); // 获取对应的页表项
ffffffffc0202e0e:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0202e10:	ec06                	sd	ra,24(sp)
ffffffffc0202e12:	e822                	sd	s0,16(sp)
    pte_t *ptep = get_pte(pgdir, la, 0); // 获取对应的页表项
ffffffffc0202e14:	da9ff0ef          	jal	ra,ffffffffc0202bbc <get_pte>
    if (ptep != NULL) {
ffffffffc0202e18:	c511                	beqz	a0,ffffffffc0202e24 <page_remove+0x18>
    if (*ptep & PTE_V) { // 检查页表项是否有效
ffffffffc0202e1a:	611c                	ld	a5,0(a0)
ffffffffc0202e1c:	842a                	mv	s0,a0
ffffffffc0202e1e:	0017f713          	andi	a4,a5,1
ffffffffc0202e22:	e709                	bnez	a4,ffffffffc0202e2c <page_remove+0x20>
        page_remove_pte(pgdir, la, ptep); // 调用 page_remove_pte 清除页表项并释放页面
    }
}
ffffffffc0202e24:	60e2                	ld	ra,24(sp)
ffffffffc0202e26:	6442                	ld	s0,16(sp)
ffffffffc0202e28:	6105                	addi	sp,sp,32
ffffffffc0202e2a:	8082                	ret
    return pa2page(PTE_ADDR(pte)); // 提取页表项的物理地址并转换为 Page 结构体指针
ffffffffc0202e2c:	078a                	slli	a5,a5,0x2
ffffffffc0202e2e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0202e30:	0000e717          	auipc	a4,0xe
ffffffffc0202e34:	71873703          	ld	a4,1816(a4) # ffffffffc0211548 <npage>
ffffffffc0202e38:	06e7f563          	bgeu	a5,a4,ffffffffc0202ea2 <page_remove+0x96>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc0202e3c:	fff80737          	lui	a4,0xfff80
ffffffffc0202e40:	97ba                	add	a5,a5,a4
ffffffffc0202e42:	00379513          	slli	a0,a5,0x3
ffffffffc0202e46:	97aa                	add	a5,a5,a0
ffffffffc0202e48:	078e                	slli	a5,a5,0x3
ffffffffc0202e4a:	0000e517          	auipc	a0,0xe
ffffffffc0202e4e:	70653503          	ld	a0,1798(a0) # ffffffffc0211550 <pages>
ffffffffc0202e52:	953e                	add	a0,a0,a5
    page->ref -= 1; // 引用计数减 1
ffffffffc0202e54:	411c                	lw	a5,0(a0)
ffffffffc0202e56:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202e5a:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0) { // 如果引用计数为0，释放页面
ffffffffc0202e5c:	cb09                	beqz	a4,ffffffffc0202e6e <page_remove+0x62>
        *ptep = 0; // 清除页表项
ffffffffc0202e5e:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma"); // 刷新 TLB 中的地址映射
ffffffffc0202e62:	12000073          	sfence.vma
}
ffffffffc0202e66:	60e2                	ld	ra,24(sp)
ffffffffc0202e68:	6442                	ld	s0,16(sp)
ffffffffc0202e6a:	6105                	addi	sp,sp,32
ffffffffc0202e6c:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202e6e:	100027f3          	csrr	a5,sstatus
ffffffffc0202e72:	8b89                	andi	a5,a5,2
ffffffffc0202e74:	eb89                	bnez	a5,ffffffffc0202e86 <page_remove+0x7a>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0202e76:	0000e797          	auipc	a5,0xe
ffffffffc0202e7a:	6e27b783          	ld	a5,1762(a5) # ffffffffc0211558 <pmm_manager>
ffffffffc0202e7e:	739c                	ld	a5,32(a5)
ffffffffc0202e80:	4585                	li	a1,1
ffffffffc0202e82:	9782                	jalr	a5
    if (flag) {
ffffffffc0202e84:	bfe9                	j	ffffffffc0202e5e <page_remove+0x52>
        intr_disable();
ffffffffc0202e86:	e42a                	sd	a0,8(sp)
ffffffffc0202e88:	e66fd0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc0202e8c:	0000e797          	auipc	a5,0xe
ffffffffc0202e90:	6cc7b783          	ld	a5,1740(a5) # ffffffffc0211558 <pmm_manager>
ffffffffc0202e94:	739c                	ld	a5,32(a5)
ffffffffc0202e96:	6522                	ld	a0,8(sp)
ffffffffc0202e98:	4585                	li	a1,1
ffffffffc0202e9a:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e9c:	e4cfd0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0202ea0:	bf7d                	j	ffffffffc0202e5e <page_remove+0x52>
ffffffffc0202ea2:	bd7ff0ef          	jal	ra,ffffffffc0202a78 <pa2page.part.0>

ffffffffc0202ea6 <page_insert>:
//  page:  the Page which need to map
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
// note: PT is changed, so the TLB need to be invalidate
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202ea6:	7179                	addi	sp,sp,-48
ffffffffc0202ea8:	87b2                	mv	a5,a2
ffffffffc0202eaa:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1); // 获取页表项，如果不存在则创建
ffffffffc0202eac:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202eae:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1); // 获取页表项，如果不存在则创建
ffffffffc0202eb0:	85be                	mv	a1,a5
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202eb2:	ec26                	sd	s1,24(sp)
ffffffffc0202eb4:	f406                	sd	ra,40(sp)
ffffffffc0202eb6:	e84a                	sd	s2,16(sp)
ffffffffc0202eb8:	e44e                	sd	s3,8(sp)
ffffffffc0202eba:	e052                	sd	s4,0(sp)
ffffffffc0202ebc:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1); // 获取页表项，如果不存在则创建
ffffffffc0202ebe:	cffff0ef          	jal	ra,ffffffffc0202bbc <get_pte>
    if (ptep == NULL) {
ffffffffc0202ec2:	cd71                	beqz	a0,ffffffffc0202f9e <page_insert+0xf8>
    page->ref += 1; // 引用计数加 1
ffffffffc0202ec4:	4014                	lw	a3,0(s0)
        return -E_NO_MEM; // 如果分配失败，返回内存错误
    }
    page_ref_inc(page); // 增加物理页面的引用计数

    if (*ptep & PTE_V) { // 如果页表项已经有效
ffffffffc0202ec6:	611c                	ld	a5,0(a0)
ffffffffc0202ec8:	89aa                	mv	s3,a0
ffffffffc0202eca:	0016871b          	addiw	a4,a3,1
ffffffffc0202ece:	c018                	sw	a4,0(s0)
ffffffffc0202ed0:	0017f713          	andi	a4,a5,1
ffffffffc0202ed4:	e331                	bnez	a4,ffffffffc0202f18 <page_insert+0x72>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0202ed6:	0000e797          	auipc	a5,0xe
ffffffffc0202eda:	67a7b783          	ld	a5,1658(a5) # ffffffffc0211550 <pages>
ffffffffc0202ede:	40f407b3          	sub	a5,s0,a5
ffffffffc0202ee2:	878d                	srai	a5,a5,0x3
ffffffffc0202ee4:	00003417          	auipc	s0,0x3
ffffffffc0202ee8:	45c43403          	ld	s0,1116(s0) # ffffffffc0206340 <error_string+0x38>
ffffffffc0202eec:	028787b3          	mul	a5,a5,s0
ffffffffc0202ef0:	00080437          	lui	s0,0x80
ffffffffc0202ef4:	97a2                	add	a5,a5,s0
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type; // 将页帧号和权限位组合成 PTE
ffffffffc0202ef6:	07aa                	slli	a5,a5,0xa
ffffffffc0202ef8:	8cdd                	or	s1,s1,a5
ffffffffc0202efa:	0014e493          	ori	s1,s1,1
            page_ref_dec(page); // 引用计数减少（因为之前增加了一次）
        } else { // 如果映射的是另一个页面
            page_remove_pte(pgdir, la, ptep); // 删除旧的映射
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm); // 设置新的页表项
ffffffffc0202efe:	0099b023          	sd	s1,0(s3)
    asm volatile("sfence.vma"); // 刷新 TLB 中的地址映射
ffffffffc0202f02:	12000073          	sfence.vma
    tlb_invalidate(pgdir, la); // 使TLB无效，以确保CPU的缓存与新的页表项同步

    return 0; // 成功返回
ffffffffc0202f06:	4501                	li	a0,0
}
ffffffffc0202f08:	70a2                	ld	ra,40(sp)
ffffffffc0202f0a:	7402                	ld	s0,32(sp)
ffffffffc0202f0c:	64e2                	ld	s1,24(sp)
ffffffffc0202f0e:	6942                	ld	s2,16(sp)
ffffffffc0202f10:	69a2                	ld	s3,8(sp)
ffffffffc0202f12:	6a02                	ld	s4,0(sp)
ffffffffc0202f14:	6145                	addi	sp,sp,48
ffffffffc0202f16:	8082                	ret
    return pa2page(PTE_ADDR(pte)); // 提取页表项的物理地址并转换为 Page 结构体指针
ffffffffc0202f18:	00279713          	slli	a4,a5,0x2
ffffffffc0202f1c:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0202f1e:	0000e797          	auipc	a5,0xe
ffffffffc0202f22:	62a7b783          	ld	a5,1578(a5) # ffffffffc0211548 <npage>
ffffffffc0202f26:	06f77e63          	bgeu	a4,a5,ffffffffc0202fa2 <page_insert+0xfc>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc0202f2a:	fff807b7          	lui	a5,0xfff80
ffffffffc0202f2e:	973e                	add	a4,a4,a5
ffffffffc0202f30:	0000ea17          	auipc	s4,0xe
ffffffffc0202f34:	620a0a13          	addi	s4,s4,1568 # ffffffffc0211550 <pages>
ffffffffc0202f38:	000a3783          	ld	a5,0(s4)
ffffffffc0202f3c:	00371913          	slli	s2,a4,0x3
ffffffffc0202f40:	993a                	add	s2,s2,a4
ffffffffc0202f42:	090e                	slli	s2,s2,0x3
ffffffffc0202f44:	993e                	add	s2,s2,a5
        if (p == page) { // 如果已经是正确的映射
ffffffffc0202f46:	03240063          	beq	s0,s2,ffffffffc0202f66 <page_insert+0xc0>
    page->ref -= 1; // 引用计数减 1
ffffffffc0202f4a:	00092783          	lw	a5,0(s2)
ffffffffc0202f4e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202f52:	00e92023          	sw	a4,0(s2)
        if (page_ref(page) == 0) { // 如果引用计数为0，释放页面
ffffffffc0202f56:	cb11                	beqz	a4,ffffffffc0202f6a <page_insert+0xc4>
        *ptep = 0; // 清除页表项
ffffffffc0202f58:	0009b023          	sd	zero,0(s3)
    asm volatile("sfence.vma"); // 刷新 TLB 中的地址映射
ffffffffc0202f5c:	12000073          	sfence.vma
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0202f60:	000a3783          	ld	a5,0(s4)
}
ffffffffc0202f64:	bfad                	j	ffffffffc0202ede <page_insert+0x38>
    page->ref -= 1; // 引用计数减 1
ffffffffc0202f66:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202f68:	bf9d                	j	ffffffffc0202ede <page_insert+0x38>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202f6a:	100027f3          	csrr	a5,sstatus
ffffffffc0202f6e:	8b89                	andi	a5,a5,2
ffffffffc0202f70:	eb91                	bnez	a5,ffffffffc0202f84 <page_insert+0xde>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0202f72:	0000e797          	auipc	a5,0xe
ffffffffc0202f76:	5e67b783          	ld	a5,1510(a5) # ffffffffc0211558 <pmm_manager>
ffffffffc0202f7a:	739c                	ld	a5,32(a5)
ffffffffc0202f7c:	4585                	li	a1,1
ffffffffc0202f7e:	854a                	mv	a0,s2
ffffffffc0202f80:	9782                	jalr	a5
    if (flag) {
ffffffffc0202f82:	bfd9                	j	ffffffffc0202f58 <page_insert+0xb2>
        intr_disable();
ffffffffc0202f84:	d6afd0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc0202f88:	0000e797          	auipc	a5,0xe
ffffffffc0202f8c:	5d07b783          	ld	a5,1488(a5) # ffffffffc0211558 <pmm_manager>
ffffffffc0202f90:	739c                	ld	a5,32(a5)
ffffffffc0202f92:	4585                	li	a1,1
ffffffffc0202f94:	854a                	mv	a0,s2
ffffffffc0202f96:	9782                	jalr	a5
        intr_enable();
ffffffffc0202f98:	d50fd0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0202f9c:	bf75                	j	ffffffffc0202f58 <page_insert+0xb2>
        return -E_NO_MEM; // 如果分配失败，返回内存错误
ffffffffc0202f9e:	5571                	li	a0,-4
ffffffffc0202fa0:	b7a5                	j	ffffffffc0202f08 <page_insert+0x62>
ffffffffc0202fa2:	ad7ff0ef          	jal	ra,ffffffffc0202a78 <pa2page.part.0>

ffffffffc0202fa6 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202fa6:	00003797          	auipc	a5,0x3
ffffffffc0202faa:	aea78793          	addi	a5,a5,-1302 # ffffffffc0205a90 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202fae:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0202fb0:	7159                	addi	sp,sp,-112
ffffffffc0202fb2:	f45e                	sd	s7,40(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202fb4:	00003517          	auipc	a0,0x3
ffffffffc0202fb8:	b4c50513          	addi	a0,a0,-1204 # ffffffffc0205b00 <default_pmm_manager+0x70>
    pmm_manager = &default_pmm_manager;
ffffffffc0202fbc:	0000eb97          	auipc	s7,0xe
ffffffffc0202fc0:	59cb8b93          	addi	s7,s7,1436 # ffffffffc0211558 <pmm_manager>
void pmm_init(void) {
ffffffffc0202fc4:	f486                	sd	ra,104(sp)
ffffffffc0202fc6:	f0a2                	sd	s0,96(sp)
ffffffffc0202fc8:	eca6                	sd	s1,88(sp)
ffffffffc0202fca:	e8ca                	sd	s2,80(sp)
ffffffffc0202fcc:	e4ce                	sd	s3,72(sp)
ffffffffc0202fce:	f85a                	sd	s6,48(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202fd0:	00fbb023          	sd	a5,0(s7)
void pmm_init(void) {
ffffffffc0202fd4:	e0d2                	sd	s4,64(sp)
ffffffffc0202fd6:	fc56                	sd	s5,56(sp)
ffffffffc0202fd8:	f062                	sd	s8,32(sp)
ffffffffc0202fda:	ec66                	sd	s9,24(sp)
ffffffffc0202fdc:	e86a                	sd	s10,16(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202fde:	8dcfd0ef          	jal	ra,ffffffffc02000ba <cprintf>
    pmm_manager->init();
ffffffffc0202fe2:	000bb783          	ld	a5,0(s7)
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size); // 打印物理内存信息
ffffffffc0202fe6:	4445                	li	s0,17
ffffffffc0202fe8:	40100913          	li	s2,1025
    pmm_manager->init();
ffffffffc0202fec:	679c                	ld	a5,8(a5)
    va_pa_offset = KERNBASE - 0x80200000; // 设置内核虚拟地址与物理地址之间的偏移量
ffffffffc0202fee:	0000e997          	auipc	s3,0xe
ffffffffc0202ff2:	57298993          	addi	s3,s3,1394 # ffffffffc0211560 <va_pa_offset>
    npage = maxpa / PGSIZE; // 计算系统物理页总数
ffffffffc0202ff6:	0000e497          	auipc	s1,0xe
ffffffffc0202ffa:	55248493          	addi	s1,s1,1362 # ffffffffc0211548 <npage>
    pmm_manager->init();
ffffffffc0202ffe:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000; // 设置内核虚拟地址与物理地址之间的偏移量
ffffffffc0203000:	57f5                	li	a5,-3
ffffffffc0203002:	07fa                	slli	a5,a5,0x1e
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size); // 打印物理内存信息
ffffffffc0203004:	07e006b7          	lui	a3,0x7e00
ffffffffc0203008:	01b41613          	slli	a2,s0,0x1b
ffffffffc020300c:	01591593          	slli	a1,s2,0x15
ffffffffc0203010:	00003517          	auipc	a0,0x3
ffffffffc0203014:	b0850513          	addi	a0,a0,-1272 # ffffffffc0205b18 <default_pmm_manager+0x88>
    va_pa_offset = KERNBASE - 0x80200000; // 设置内核虚拟地址与物理地址之间的偏移量
ffffffffc0203018:	00f9b023          	sd	a5,0(s3)
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size); // 打印物理内存信息
ffffffffc020301c:	89efd0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("physcial memory map:\n"); 
ffffffffc0203020:	00003517          	auipc	a0,0x3
ffffffffc0203024:	b2850513          	addi	a0,a0,-1240 # ffffffffc0205b48 <default_pmm_manager+0xb8>
ffffffffc0203028:	892fd0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin, mem_end - 1); // 打印物理内存范围
ffffffffc020302c:	01b41693          	slli	a3,s0,0x1b
ffffffffc0203030:	16fd                	addi	a3,a3,-1
ffffffffc0203032:	07e005b7          	lui	a1,0x7e00
ffffffffc0203036:	01591613          	slli	a2,s2,0x15
ffffffffc020303a:	00003517          	auipc	a0,0x3
ffffffffc020303e:	b2650513          	addi	a0,a0,-1242 # ffffffffc0205b60 <default_pmm_manager+0xd0>
ffffffffc0203042:	878fd0ef          	jal	ra,ffffffffc02000ba <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE); // 将 pages 数组放置在内核结束地址之后的第一个页对齐位置
ffffffffc0203046:	777d                	lui	a4,0xfffff
ffffffffc0203048:	0000f797          	auipc	a5,0xf
ffffffffc020304c:	51f78793          	addi	a5,a5,1311 # ffffffffc0212567 <end+0xfff>
ffffffffc0203050:	8ff9                	and	a5,a5,a4
ffffffffc0203052:	0000eb17          	auipc	s6,0xe
ffffffffc0203056:	4feb0b13          	addi	s6,s6,1278 # ffffffffc0211550 <pages>
    npage = maxpa / PGSIZE; // 计算系统物理页总数
ffffffffc020305a:	00088737          	lui	a4,0x88
ffffffffc020305e:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE); // 将 pages 数组放置在内核结束地址之后的第一个页对齐位置
ffffffffc0203060:	00fb3023          	sd	a5,0(s6)
ffffffffc0203064:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0203066:	4701                	li	a4,0
ffffffffc0203068:	4505                	li	a0,1
ffffffffc020306a:	fff805b7          	lui	a1,0xfff80
ffffffffc020306e:	a019                	j	ffffffffc0203074 <pmm_init+0xce>
        SetPageReserved(pages + i); // 标记每页为保留状态，防止被分配
ffffffffc0203070:	000b3783          	ld	a5,0(s6)
ffffffffc0203074:	97b6                	add	a5,a5,a3
ffffffffc0203076:	07a1                	addi	a5,a5,8
ffffffffc0203078:	40a7b02f          	amoor.d	zero,a0,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020307c:	609c                	ld	a5,0(s1)
ffffffffc020307e:	0705                	addi	a4,a4,1
ffffffffc0203080:	04868693          	addi	a3,a3,72 # 7e00048 <kern_entry-0xffffffffb83fffb8>
ffffffffc0203084:	00b78633          	add	a2,a5,a1
ffffffffc0203088:	fec764e3          	bltu	a4,a2,ffffffffc0203070 <pmm_init+0xca>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 获取 pages 数组后面第一个空闲物理地址
ffffffffc020308c:	000b3503          	ld	a0,0(s6)
ffffffffc0203090:	00379693          	slli	a3,a5,0x3
ffffffffc0203094:	96be                	add	a3,a3,a5
ffffffffc0203096:	fdc00737          	lui	a4,0xfdc00
ffffffffc020309a:	972a                	add	a4,a4,a0
ffffffffc020309c:	068e                	slli	a3,a3,0x3
ffffffffc020309e:	96ba                	add	a3,a3,a4
ffffffffc02030a0:	c0200737          	lui	a4,0xc0200
ffffffffc02030a4:	0ee6e9e3          	bltu	a3,a4,ffffffffc0203996 <pmm_init+0x9f0>
ffffffffc02030a8:	0009b703          	ld	a4,0(s3)
    if (freemem < mem_end) { // 如果存在空闲的物理内存区域，则初始化空闲内存页面
ffffffffc02030ac:	4645                	li	a2,17
ffffffffc02030ae:	066e                	slli	a2,a2,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 获取 pages 数组后面第一个空闲物理地址
ffffffffc02030b0:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) { // 如果存在空闲的物理内存区域，则初始化空闲内存页面
ffffffffc02030b2:	4cc6e963          	bltu	a3,a2,ffffffffc0203584 <pmm_init+0x5de>
    return page; // 返回分配并映射的页面指针
}

// check_alloc_page - 检查内存管理器的分配页面功能
static void check_alloc_page(void) {
    pmm_manager->check(); // 调用物理内存管理器的 check 函数进行自检
ffffffffc02030b6:	000bb783          	ld	a5,0(s7)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc02030ba:	0000e917          	auipc	s2,0xe
ffffffffc02030be:	48690913          	addi	s2,s2,1158 # ffffffffc0211540 <boot_pgdir>
    pmm_manager->check(); // 调用物理内存管理器的 check 函数进行自检
ffffffffc02030c2:	7b9c                	ld	a5,48(a5)
ffffffffc02030c4:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n"); // 若自检通过，打印成功信息
ffffffffc02030c6:	00003517          	auipc	a0,0x3
ffffffffc02030ca:	aea50513          	addi	a0,a0,-1302 # ffffffffc0205bb0 <default_pmm_manager+0x120>
ffffffffc02030ce:	fedfc0ef          	jal	ra,ffffffffc02000ba <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc02030d2:	00006697          	auipc	a3,0x6
ffffffffc02030d6:	f2e68693          	addi	a3,a3,-210 # ffffffffc0209000 <boot_page_table_sv39>
ffffffffc02030da:	00d93023          	sd	a3,0(s2)
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02030de:	c02007b7          	lui	a5,0xc0200
ffffffffc02030e2:	24f6efe3          	bltu	a3,a5,ffffffffc0203b40 <pmm_init+0xb9a>
ffffffffc02030e6:	0009b783          	ld	a5,0(s3)
ffffffffc02030ea:	8e9d                	sub	a3,a3,a5
ffffffffc02030ec:	0000e797          	auipc	a5,0xe
ffffffffc02030f0:	44d7b623          	sd	a3,1100(a5) # ffffffffc0211538 <boot_cr3>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02030f4:	100027f3          	csrr	a5,sstatus
ffffffffc02030f8:	8b89                	andi	a5,a5,2
ffffffffc02030fa:	4a079e63          	bnez	a5,ffffffffc02035b6 <pmm_init+0x610>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc02030fe:	000bb783          	ld	a5,0(s7)
ffffffffc0203102:	779c                	ld	a5,40(a5)
ffffffffc0203104:	9782                	jalr	a5
ffffffffc0203106:	842a                	mv	s0,a0
static void check_pgdir(void) {
    size_t nr_free_store;
    nr_free_store = nr_free_pages(); // 记录当前的空闲页数

    // 检查内核页数和 boot_pgdir 的有效性
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0203108:	6098                	ld	a4,0(s1)
ffffffffc020310a:	c80007b7          	lui	a5,0xc8000
ffffffffc020310e:	83b1                	srli	a5,a5,0xc
ffffffffc0203110:	10e7ebe3          	bltu	a5,a4,ffffffffc0203a26 <pmm_init+0xa80>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0203114:	00093503          	ld	a0,0(s2)
ffffffffc0203118:	0e0507e3          	beqz	a0,ffffffffc0203a06 <pmm_init+0xa60>
ffffffffc020311c:	03451793          	slli	a5,a0,0x34
ffffffffc0203120:	0e0793e3          	bnez	a5,ffffffffc0203a06 <pmm_init+0xa60>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL); // 确保虚拟地址 0x0 没有映射
ffffffffc0203124:	4601                	li	a2,0
ffffffffc0203126:	4581                	li	a1,0
ffffffffc0203128:	c8bff0ef          	jal	ra,ffffffffc0202db2 <get_page>
ffffffffc020312c:	74051963          	bnez	a0,ffffffffc020387e <pmm_init+0x8d8>

    // 分配物理页面 p1，并将其映射到 0x0 虚拟地址
    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc0203130:	4505                	li	a0,1
ffffffffc0203132:	97fff0ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc0203136:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0203138:	00093503          	ld	a0,0(s2)
ffffffffc020313c:	4681                	li	a3,0
ffffffffc020313e:	4601                	li	a2,0
ffffffffc0203140:	85d2                	mv	a1,s4
ffffffffc0203142:	d65ff0ef          	jal	ra,ffffffffc0202ea6 <page_insert>
ffffffffc0203146:	70051c63          	bnez	a0,ffffffffc020385e <pmm_init+0x8b8>
    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL); // 获取页表项并检查是否正确映射
ffffffffc020314a:	00093503          	ld	a0,0(s2)
ffffffffc020314e:	4601                	li	a2,0
ffffffffc0203150:	4581                	li	a1,0
ffffffffc0203152:	a6bff0ef          	jal	ra,ffffffffc0202bbc <get_pte>
ffffffffc0203156:	6e050463          	beqz	a0,ffffffffc020383e <pmm_init+0x898>
    assert(pte2page(*ptep) == p1);
ffffffffc020315a:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) { // 检查 PTE 是否有效
ffffffffc020315c:	0017f713          	andi	a4,a5,1
ffffffffc0203160:	6c070d63          	beqz	a4,ffffffffc020383a <pmm_init+0x894>
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0203164:	6090                	ld	a2,0(s1)
    return pa2page(PTE_ADDR(pte)); // 提取页表项的物理地址并转换为 Page 结构体指针
ffffffffc0203166:	078a                	slli	a5,a5,0x2
ffffffffc0203168:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc020316a:	56c7f663          	bgeu	a5,a2,ffffffffc02036d6 <pmm_init+0x730>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc020316e:	fff80737          	lui	a4,0xfff80
ffffffffc0203172:	97ba                	add	a5,a5,a4
ffffffffc0203174:	000b3683          	ld	a3,0(s6)
ffffffffc0203178:	00379713          	slli	a4,a5,0x3
ffffffffc020317c:	97ba                	add	a5,a5,a4
ffffffffc020317e:	078e                	slli	a5,a5,0x3
ffffffffc0203180:	97b6                	add	a5,a5,a3
ffffffffc0203182:	54fa1c63          	bne	s4,a5,ffffffffc02036da <pmm_init+0x734>
    assert(page_ref(p1) == 1);
ffffffffc0203186:	000a2703          	lw	a4,0(s4)
ffffffffc020318a:	4785                	li	a5,1
ffffffffc020318c:	7ef71563          	bne	a4,a5,ffffffffc0203976 <pmm_init+0x9d0>

    // 获取页目录中的页表项，检查虚拟地址 PGSIZE 是否映射正确
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0203190:	00093503          	ld	a0,0(s2)
ffffffffc0203194:	77fd                	lui	a5,0xfffff
ffffffffc0203196:	6114                	ld	a3,0(a0)
ffffffffc0203198:	068a                	slli	a3,a3,0x2
ffffffffc020319a:	8efd                	and	a3,a3,a5
ffffffffc020319c:	00c6d713          	srli	a4,a3,0xc
ffffffffc02031a0:	7ac77f63          	bgeu	a4,a2,ffffffffc020395e <pmm_init+0x9b8>
ffffffffc02031a4:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02031a8:	96e2                	add	a3,a3,s8
ffffffffc02031aa:	0006ba83          	ld	s5,0(a3)
ffffffffc02031ae:	0a8a                	slli	s5,s5,0x2
ffffffffc02031b0:	00fafab3          	and	s5,s5,a5
ffffffffc02031b4:	00cad793          	srli	a5,s5,0xc
ffffffffc02031b8:	0ac7f7e3          	bgeu	a5,a2,ffffffffc0203a66 <pmm_init+0xac0>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02031bc:	4601                	li	a2,0
ffffffffc02031be:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02031c0:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02031c2:	9fbff0ef          	jal	ra,ffffffffc0202bbc <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02031c6:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02031c8:	07551fe3          	bne	a0,s5,ffffffffc0203a46 <pmm_init+0xaa0>

    // 分配第二个页面 p2，将其映射到虚拟地址 PGSIZE，赋予用户和写权限
    p2 = alloc_page();
ffffffffc02031cc:	4505                	li	a0,1
ffffffffc02031ce:	8e3ff0ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc02031d2:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02031d4:	00093503          	ld	a0,0(s2)
ffffffffc02031d8:	46d1                	li	a3,20
ffffffffc02031da:	6605                	lui	a2,0x1
ffffffffc02031dc:	85d6                	mv	a1,s5
ffffffffc02031de:	cc9ff0ef          	jal	ra,ffffffffc0202ea6 <page_insert>
ffffffffc02031e2:	56051c63          	bnez	a0,ffffffffc020375a <pmm_init+0x7b4>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02031e6:	00093503          	ld	a0,0(s2)
ffffffffc02031ea:	4601                	li	a2,0
ffffffffc02031ec:	6585                	lui	a1,0x1
ffffffffc02031ee:	9cfff0ef          	jal	ra,ffffffffc0202bbc <get_pte>
ffffffffc02031f2:	54050463          	beqz	a0,ffffffffc020373a <pmm_init+0x794>
    assert(*ptep & PTE_U);
ffffffffc02031f6:	611c                	ld	a5,0(a0)
ffffffffc02031f8:	0107f713          	andi	a4,a5,16
ffffffffc02031fc:	50070f63          	beqz	a4,ffffffffc020371a <pmm_init+0x774>
    assert(*ptep & PTE_W);
ffffffffc0203200:	8b91                	andi	a5,a5,4
ffffffffc0203202:	4e078c63          	beqz	a5,ffffffffc02036fa <pmm_init+0x754>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0203206:	00093503          	ld	a0,0(s2)
ffffffffc020320a:	611c                	ld	a5,0(a0)
ffffffffc020320c:	8bc1                	andi	a5,a5,16
ffffffffc020320e:	100789e3          	beqz	a5,ffffffffc0203b20 <pmm_init+0xb7a>
    assert(page_ref(p2) == 1);
ffffffffc0203212:	000aa703          	lw	a4,0(s5)
ffffffffc0203216:	4785                	li	a5,1
ffffffffc0203218:	0ef714e3          	bne	a4,a5,ffffffffc0203b00 <pmm_init+0xb5a>

    // 重新将 p1 映射到 PGSIZE，检查引用计数变化
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc020321c:	4681                	li	a3,0
ffffffffc020321e:	6605                	lui	a2,0x1
ffffffffc0203220:	85d2                	mv	a1,s4
ffffffffc0203222:	c85ff0ef          	jal	ra,ffffffffc0202ea6 <page_insert>
ffffffffc0203226:	0a051de3          	bnez	a0,ffffffffc0203ae0 <pmm_init+0xb3a>
    assert(page_ref(p1) == 2);
ffffffffc020322a:	000a2703          	lw	a4,0(s4)
ffffffffc020322e:	4789                	li	a5,2
ffffffffc0203230:	08f718e3          	bne	a4,a5,ffffffffc0203ac0 <pmm_init+0xb1a>
    assert(page_ref(p2) == 0);
ffffffffc0203234:	000aa783          	lw	a5,0(s5)
ffffffffc0203238:	060794e3          	bnez	a5,ffffffffc0203aa0 <pmm_init+0xafa>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc020323c:	00093503          	ld	a0,0(s2)
ffffffffc0203240:	4601                	li	a2,0
ffffffffc0203242:	6585                	lui	a1,0x1
ffffffffc0203244:	979ff0ef          	jal	ra,ffffffffc0202bbc <get_pte>
ffffffffc0203248:	02050ce3          	beqz	a0,ffffffffc0203a80 <pmm_init+0xada>
    assert(pte2page(*ptep) == p1);
ffffffffc020324c:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) { // 检查 PTE 是否有效
ffffffffc020324e:	00177793          	andi	a5,a4,1
ffffffffc0203252:	5e078463          	beqz	a5,ffffffffc020383a <pmm_init+0x894>
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0203256:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte)); // 提取页表项的物理地址并转换为 Page 结构体指针
ffffffffc0203258:	00271793          	slli	a5,a4,0x2
ffffffffc020325c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc020325e:	46d7fc63          	bgeu	a5,a3,ffffffffc02036d6 <pmm_init+0x730>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc0203262:	fff806b7          	lui	a3,0xfff80
ffffffffc0203266:	97b6                	add	a5,a5,a3
ffffffffc0203268:	000b3603          	ld	a2,0(s6)
ffffffffc020326c:	00379693          	slli	a3,a5,0x3
ffffffffc0203270:	97b6                	add	a5,a5,a3
ffffffffc0203272:	078e                	slli	a5,a5,0x3
ffffffffc0203274:	97b2                	add	a5,a5,a2
ffffffffc0203276:	5afa1263          	bne	s4,a5,ffffffffc020381a <pmm_init+0x874>
    assert((*ptep & PTE_U) == 0);
ffffffffc020327a:	8b41                	andi	a4,a4,16
ffffffffc020327c:	56071f63          	bnez	a4,ffffffffc02037fa <pmm_init+0x854>

    // 移除 0x0 和 PGSIZE 的映射，检查引用计数
    page_remove(boot_pgdir, 0x0);
ffffffffc0203280:	00093503          	ld	a0,0(s2)
ffffffffc0203284:	4581                	li	a1,0
ffffffffc0203286:	b87ff0ef          	jal	ra,ffffffffc0202e0c <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc020328a:	000a2703          	lw	a4,0(s4)
ffffffffc020328e:	4785                	li	a5,1
ffffffffc0203290:	54f71563          	bne	a4,a5,ffffffffc02037da <pmm_init+0x834>
    assert(page_ref(p2) == 0);
ffffffffc0203294:	000aa783          	lw	a5,0(s5)
ffffffffc0203298:	52079163          	bnez	a5,ffffffffc02037ba <pmm_init+0x814>
    page_remove(boot_pgdir, PGSIZE);
ffffffffc020329c:	00093503          	ld	a0,0(s2)
ffffffffc02032a0:	6585                	lui	a1,0x1
ffffffffc02032a2:	b6bff0ef          	jal	ra,ffffffffc0202e0c <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc02032a6:	000a2783          	lw	a5,0(s4)
ffffffffc02032aa:	60079a63          	bnez	a5,ffffffffc02038be <pmm_init+0x918>
    assert(page_ref(p2) == 0);
ffffffffc02032ae:	000aa783          	lw	a5,0(s5)
ffffffffc02032b2:	5e079663          	bnez	a5,ffffffffc020389e <pmm_init+0x8f8>

    // 确保所有页面的引用计数为0，并释放页目录页面
    pde_t *pd1 = boot_pgdir, *pd0 = page2kva(pde2page(boot_pgdir[0]));
ffffffffc02032b6:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc02032ba:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc02032bc:	000a3683          	ld	a3,0(s4)
ffffffffc02032c0:	068a                	slli	a3,a3,0x2
ffffffffc02032c2:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc02032c4:	40e6f963          	bgeu	a3,a4,ffffffffc02036d6 <pmm_init+0x730>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc02032c8:	fff807b7          	lui	a5,0xfff80
ffffffffc02032cc:	97b6                	add	a5,a5,a3
ffffffffc02032ce:	00379693          	slli	a3,a5,0x3
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc02032d2:	96be                	add	a3,a3,a5
ffffffffc02032d4:	00003c97          	auipc	s9,0x3
ffffffffc02032d8:	06ccbc83          	ld	s9,108(s9) # ffffffffc0206340 <error_string+0x38>
ffffffffc02032dc:	039686b3          	mul	a3,a3,s9
ffffffffc02032e0:	000805b7          	lui	a1,0x80
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc02032e4:	000b3503          	ld	a0,0(s6)
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc02032e8:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc02032ea:	00c69613          	slli	a2,a3,0xc
ffffffffc02032ee:	8231                	srli	a2,a2,0xc
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc02032f0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc02032f2:	6ce67e63          	bgeu	a2,a4,ffffffffc02039ce <pmm_init+0xa28>
    free_page(pde2page(pd0[0]));
ffffffffc02032f6:	0009b603          	ld	a2,0(s3)
ffffffffc02032fa:	96b2                	add	a3,a3,a2
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc02032fc:	629c                	ld	a5,0(a3)
ffffffffc02032fe:	078a                	slli	a5,a5,0x2
ffffffffc0203300:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0203302:	3ce7fa63          	bgeu	a5,a4,ffffffffc02036d6 <pmm_init+0x730>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc0203306:	8f8d                	sub	a5,a5,a1
ffffffffc0203308:	00379713          	slli	a4,a5,0x3
ffffffffc020330c:	97ba                	add	a5,a5,a4
ffffffffc020330e:	078e                	slli	a5,a5,0x3
ffffffffc0203310:	953e                	add	a0,a0,a5
ffffffffc0203312:	100027f3          	csrr	a5,sstatus
ffffffffc0203316:	8b89                	andi	a5,a5,2
ffffffffc0203318:	2e079963          	bnez	a5,ffffffffc020360a <pmm_init+0x664>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc020331c:	000bb783          	ld	a5,0(s7)
ffffffffc0203320:	4585                	li	a1,1
ffffffffc0203322:	739c                	ld	a5,32(a5)
ffffffffc0203324:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc0203326:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc020332a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc020332c:	078a                	slli	a5,a5,0x2
ffffffffc020332e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0203330:	3ae7f363          	bgeu	a5,a4,ffffffffc02036d6 <pmm_init+0x730>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc0203334:	fff80737          	lui	a4,0xfff80
ffffffffc0203338:	97ba                	add	a5,a5,a4
ffffffffc020333a:	000b3503          	ld	a0,0(s6)
ffffffffc020333e:	00379713          	slli	a4,a5,0x3
ffffffffc0203342:	97ba                	add	a5,a5,a4
ffffffffc0203344:	078e                	slli	a5,a5,0x3
ffffffffc0203346:	953e                	add	a0,a0,a5
ffffffffc0203348:	100027f3          	csrr	a5,sstatus
ffffffffc020334c:	8b89                	andi	a5,a5,2
ffffffffc020334e:	2a079263          	bnez	a5,ffffffffc02035f2 <pmm_init+0x64c>
ffffffffc0203352:	000bb783          	ld	a5,0(s7)
ffffffffc0203356:	4585                	li	a1,1
ffffffffc0203358:	739c                	ld	a5,32(a5)
ffffffffc020335a:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc020335c:	00093783          	ld	a5,0(s2)
ffffffffc0203360:	0007b023          	sd	zero,0(a5) # fffffffffff80000 <end+0x3fd6ea98>
ffffffffc0203364:	100027f3          	csrr	a5,sstatus
ffffffffc0203368:	8b89                	andi	a5,a5,2
ffffffffc020336a:	26079a63          	bnez	a5,ffffffffc02035de <pmm_init+0x638>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc020336e:	000bb783          	ld	a5,0(s7)
ffffffffc0203372:	779c                	ld	a5,40(a5)
ffffffffc0203374:	9782                	jalr	a5
ffffffffc0203376:	8a2a                	mv	s4,a0

    assert(nr_free_store == nr_free_pages()); // 验证空闲页数是否与之前一致
ffffffffc0203378:	7f441063          	bne	s0,s4,ffffffffc0203b58 <pmm_init+0xbb2>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc020337c:	00003517          	auipc	a0,0x3
ffffffffc0203380:	afc50513          	addi	a0,a0,-1284 # ffffffffc0205e78 <default_pmm_manager+0x3e8>
ffffffffc0203384:	d37fc0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0203388:	100027f3          	csrr	a5,sstatus
ffffffffc020338c:	8b89                	andi	a5,a5,2
ffffffffc020338e:	22079e63          	bnez	a5,ffffffffc02035ca <pmm_init+0x624>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0203392:	000bb783          	ld	a5,0(s7)
ffffffffc0203396:	779c                	ld	a5,40(a5)
ffffffffc0203398:	9782                	jalr	a5
ffffffffc020339a:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;
    nr_free_store = nr_free_pages(); // 记录当前的空闲页数

    // 验证 boot_pgdir 中是否正确映射内核虚拟地址
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc020339c:	6098                	ld	a4,0(s1)
ffffffffc020339e:	c0200437          	lui	s0,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02033a2:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02033a4:	00c71793          	slli	a5,a4,0xc
ffffffffc02033a8:	6a05                	lui	s4,0x1
ffffffffc02033aa:	02f47c63          	bgeu	s0,a5,ffffffffc02033e2 <pmm_init+0x43c>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02033ae:	00c45793          	srli	a5,s0,0xc
ffffffffc02033b2:	00093503          	ld	a0,0(s2)
ffffffffc02033b6:	30e7f363          	bgeu	a5,a4,ffffffffc02036bc <pmm_init+0x716>
ffffffffc02033ba:	0009b583          	ld	a1,0(s3)
ffffffffc02033be:	4601                	li	a2,0
ffffffffc02033c0:	95a2                	add	a1,a1,s0
ffffffffc02033c2:	ffaff0ef          	jal	ra,ffffffffc0202bbc <get_pte>
ffffffffc02033c6:	2c050b63          	beqz	a0,ffffffffc020369c <pmm_init+0x6f6>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02033ca:	611c                	ld	a5,0(a0)
ffffffffc02033cc:	078a                	slli	a5,a5,0x2
ffffffffc02033ce:	0157f7b3          	and	a5,a5,s5
ffffffffc02033d2:	2a879563          	bne	a5,s0,ffffffffc020367c <pmm_init+0x6d6>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02033d6:	6098                	ld	a4,0(s1)
ffffffffc02033d8:	9452                	add	s0,s0,s4
ffffffffc02033da:	00c71793          	slli	a5,a4,0xc
ffffffffc02033de:	fcf468e3          	bltu	s0,a5,ffffffffc02033ae <pmm_init+0x408>
    }

    assert(boot_pgdir[0] == 0);
ffffffffc02033e2:	00093783          	ld	a5,0(s2)
ffffffffc02033e6:	639c                	ld	a5,0(a5)
ffffffffc02033e8:	5e079f63          	bnez	a5,ffffffffc02039e6 <pmm_init+0xa40>

    // 分配页面 p，设置映射并检查内容复制和字符串操作的正确性
    struct Page *p;
    p = alloc_page();
ffffffffc02033ec:	4505                	li	a0,1
ffffffffc02033ee:	ec2ff0ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc02033f2:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02033f4:	00093503          	ld	a0,0(s2)
ffffffffc02033f8:	4699                	li	a3,6
ffffffffc02033fa:	10000613          	li	a2,256
ffffffffc02033fe:	85d6                	mv	a1,s5
ffffffffc0203400:	aa7ff0ef          	jal	ra,ffffffffc0202ea6 <page_insert>
ffffffffc0203404:	38051b63          	bnez	a0,ffffffffc020379a <pmm_init+0x7f4>
    assert(page_ref(p) == 1);
ffffffffc0203408:	000aa703          	lw	a4,0(s5) # fffffffffffff000 <end+0x3fdeda98>
ffffffffc020340c:	4785                	li	a5,1
ffffffffc020340e:	36f71663          	bne	a4,a5,ffffffffc020377a <pmm_init+0x7d4>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0203412:	00093503          	ld	a0,0(s2)
ffffffffc0203416:	6405                	lui	s0,0x1
ffffffffc0203418:	4699                	li	a3,6
ffffffffc020341a:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc020341e:	85d6                	mv	a1,s5
ffffffffc0203420:	a87ff0ef          	jal	ra,ffffffffc0202ea6 <page_insert>
ffffffffc0203424:	50051d63          	bnez	a0,ffffffffc020393e <pmm_init+0x998>
    assert(page_ref(p) == 2);
ffffffffc0203428:	000aa703          	lw	a4,0(s5)
ffffffffc020342c:	4789                	li	a5,2
ffffffffc020342e:	4ef71863          	bne	a4,a5,ffffffffc020391e <pmm_init+0x978>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0203432:	00003597          	auipc	a1,0x3
ffffffffc0203436:	b7e58593          	addi	a1,a1,-1154 # ffffffffc0205fb0 <default_pmm_manager+0x520>
ffffffffc020343a:	10000513          	li	a0,256
ffffffffc020343e:	33d000ef          	jal	ra,ffffffffc0203f7a <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0203442:	10040593          	addi	a1,s0,256
ffffffffc0203446:	10000513          	li	a0,256
ffffffffc020344a:	343000ef          	jal	ra,ffffffffc0203f8c <strcmp>
ffffffffc020344e:	4a051863          	bnez	a0,ffffffffc02038fe <pmm_init+0x958>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0203452:	000b3683          	ld	a3,0(s6)
ffffffffc0203456:	00080d37          	lui	s10,0x80
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc020345a:	547d                	li	s0,-1
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc020345c:	40da86b3          	sub	a3,s5,a3
ffffffffc0203460:	868d                	srai	a3,a3,0x3
ffffffffc0203462:	039686b3          	mul	a3,a3,s9
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203466:	609c                	ld	a5,0(s1)
ffffffffc0203468:	8031                	srli	s0,s0,0xc
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc020346a:	96ea                	add	a3,a3,s10
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc020346c:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc0203470:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203472:	54f77e63          	bgeu	a4,a5,ffffffffc02039ce <pmm_init+0xa28>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0203476:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc020347a:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020347e:	96be                	add	a3,a3,a5
ffffffffc0203480:	10068023          	sb	zero,256(a3) # fffffffffff80100 <end+0x3fd6eb98>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203484:	2c1000ef          	jal	ra,ffffffffc0203f44 <strlen>
ffffffffc0203488:	44051b63          	bnez	a0,ffffffffc02038de <pmm_init+0x938>

    // 释放分配的页面和页表
    pde_t *pd1 = boot_pgdir, *pd0 = page2kva(pde2page(boot_pgdir[0]));
ffffffffc020348c:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0203490:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc0203492:	000a3783          	ld	a5,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0203496:	078a                	slli	a5,a5,0x2
ffffffffc0203498:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc020349a:	22e7fe63          	bgeu	a5,a4,ffffffffc02036d6 <pmm_init+0x730>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc020349e:	41a787b3          	sub	a5,a5,s10
ffffffffc02034a2:	00379693          	slli	a3,a5,0x3
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc02034a6:	96be                	add	a3,a3,a5
ffffffffc02034a8:	03968cb3          	mul	s9,a3,s9
ffffffffc02034ac:	01ac86b3          	add	a3,s9,s10
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc02034b0:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc02034b2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc02034b4:	50e47d63          	bgeu	s0,a4,ffffffffc02039ce <pmm_init+0xa28>
ffffffffc02034b8:	0009b403          	ld	s0,0(s3)
ffffffffc02034bc:	9436                	add	s0,s0,a3
ffffffffc02034be:	100027f3          	csrr	a5,sstatus
ffffffffc02034c2:	8b89                	andi	a5,a5,2
ffffffffc02034c4:	16079b63          	bnez	a5,ffffffffc020363a <pmm_init+0x694>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc02034c8:	000bb783          	ld	a5,0(s7)
ffffffffc02034cc:	4585                	li	a1,1
ffffffffc02034ce:	8556                	mv	a0,s5
ffffffffc02034d0:	739c                	ld	a5,32(a5)
ffffffffc02034d2:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc02034d4:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc02034d6:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc02034d8:	078a                	slli	a5,a5,0x2
ffffffffc02034da:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc02034dc:	1ee7fd63          	bgeu	a5,a4,ffffffffc02036d6 <pmm_init+0x730>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc02034e0:	fff80737          	lui	a4,0xfff80
ffffffffc02034e4:	97ba                	add	a5,a5,a4
ffffffffc02034e6:	000b3503          	ld	a0,0(s6)
ffffffffc02034ea:	00379713          	slli	a4,a5,0x3
ffffffffc02034ee:	97ba                	add	a5,a5,a4
ffffffffc02034f0:	078e                	slli	a5,a5,0x3
ffffffffc02034f2:	953e                	add	a0,a0,a5
ffffffffc02034f4:	100027f3          	csrr	a5,sstatus
ffffffffc02034f8:	8b89                	andi	a5,a5,2
ffffffffc02034fa:	12079463          	bnez	a5,ffffffffc0203622 <pmm_init+0x67c>
ffffffffc02034fe:	000bb783          	ld	a5,0(s7)
ffffffffc0203502:	4585                	li	a1,1
ffffffffc0203504:	739c                	ld	a5,32(a5)
ffffffffc0203506:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc0203508:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc020350c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc020350e:	078a                	slli	a5,a5,0x2
ffffffffc0203510:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0203512:	1ce7f263          	bgeu	a5,a4,ffffffffc02036d6 <pmm_init+0x730>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc0203516:	fff80737          	lui	a4,0xfff80
ffffffffc020351a:	97ba                	add	a5,a5,a4
ffffffffc020351c:	000b3503          	ld	a0,0(s6)
ffffffffc0203520:	00379713          	slli	a4,a5,0x3
ffffffffc0203524:	97ba                	add	a5,a5,a4
ffffffffc0203526:	078e                	slli	a5,a5,0x3
ffffffffc0203528:	953e                	add	a0,a0,a5
ffffffffc020352a:	100027f3          	csrr	a5,sstatus
ffffffffc020352e:	8b89                	andi	a5,a5,2
ffffffffc0203530:	12079a63          	bnez	a5,ffffffffc0203664 <pmm_init+0x6be>
ffffffffc0203534:	000bb783          	ld	a5,0(s7)
ffffffffc0203538:	4585                	li	a1,1
ffffffffc020353a:	739c                	ld	a5,32(a5)
ffffffffc020353c:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc020353e:	00093783          	ld	a5,0(s2)
ffffffffc0203542:	0007b023          	sd	zero,0(a5)
ffffffffc0203546:	100027f3          	csrr	a5,sstatus
ffffffffc020354a:	8b89                	andi	a5,a5,2
ffffffffc020354c:	10079263          	bnez	a5,ffffffffc0203650 <pmm_init+0x6aa>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0203550:	000bb783          	ld	a5,0(s7)
ffffffffc0203554:	779c                	ld	a5,40(a5)
ffffffffc0203556:	9782                	jalr	a5
ffffffffc0203558:	842a                	mv	s0,a0

    assert(nr_free_store == nr_free_pages()); // 确保空闲页数一致
ffffffffc020355a:	448c1a63          	bne	s8,s0,ffffffffc02039ae <pmm_init+0xa08>
}
ffffffffc020355e:	7406                	ld	s0,96(sp)
ffffffffc0203560:	70a6                	ld	ra,104(sp)
ffffffffc0203562:	64e6                	ld	s1,88(sp)
ffffffffc0203564:	6946                	ld	s2,80(sp)
ffffffffc0203566:	69a6                	ld	s3,72(sp)
ffffffffc0203568:	6a06                	ld	s4,64(sp)
ffffffffc020356a:	7ae2                	ld	s5,56(sp)
ffffffffc020356c:	7b42                	ld	s6,48(sp)
ffffffffc020356e:	7ba2                	ld	s7,40(sp)
ffffffffc0203570:	7c02                	ld	s8,32(sp)
ffffffffc0203572:	6ce2                	ld	s9,24(sp)
ffffffffc0203574:	6d42                	ld	s10,16(sp)

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0203576:	00003517          	auipc	a0,0x3
ffffffffc020357a:	ab250513          	addi	a0,a0,-1358 # ffffffffc0206028 <default_pmm_manager+0x598>
}
ffffffffc020357e:	6165                	addi	sp,sp,112
    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0203580:	b3bfc06f          	j	ffffffffc02000ba <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE); // 对齐到页边界
ffffffffc0203584:	6705                	lui	a4,0x1
ffffffffc0203586:	177d                	addi	a4,a4,-1
ffffffffc0203588:	96ba                	add	a3,a3,a4
ffffffffc020358a:	777d                	lui	a4,0xfffff
ffffffffc020358c:	8f75                	and	a4,a4,a3
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc020358e:	00c75693          	srli	a3,a4,0xc
ffffffffc0203592:	14f6f263          	bgeu	a3,a5,ffffffffc02036d6 <pmm_init+0x730>
    pmm_manager->init_memmap(base, n);
ffffffffc0203596:	000bb803          	ld	a6,0(s7)
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc020359a:	95b6                	add	a1,a1,a3
ffffffffc020359c:	00359793          	slli	a5,a1,0x3
ffffffffc02035a0:	97ae                	add	a5,a5,a1
ffffffffc02035a2:	01083683          	ld	a3,16(a6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE); // 初始化空闲页的内存映射
ffffffffc02035a6:	40e60733          	sub	a4,a2,a4
ffffffffc02035aa:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02035ac:	00c75593          	srli	a1,a4,0xc
ffffffffc02035b0:	953e                	add	a0,a0,a5
ffffffffc02035b2:	9682                	jalr	a3
}
ffffffffc02035b4:	b609                	j	ffffffffc02030b6 <pmm_init+0x110>
        intr_disable();
ffffffffc02035b6:	f39fc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc02035ba:	000bb783          	ld	a5,0(s7)
ffffffffc02035be:	779c                	ld	a5,40(a5)
ffffffffc02035c0:	9782                	jalr	a5
ffffffffc02035c2:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02035c4:	f25fc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc02035c8:	b681                	j	ffffffffc0203108 <pmm_init+0x162>
        intr_disable();
ffffffffc02035ca:	f25fc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc02035ce:	000bb783          	ld	a5,0(s7)
ffffffffc02035d2:	779c                	ld	a5,40(a5)
ffffffffc02035d4:	9782                	jalr	a5
ffffffffc02035d6:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02035d8:	f11fc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc02035dc:	b3c1                	j	ffffffffc020339c <pmm_init+0x3f6>
        intr_disable();
ffffffffc02035de:	f11fc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc02035e2:	000bb783          	ld	a5,0(s7)
ffffffffc02035e6:	779c                	ld	a5,40(a5)
ffffffffc02035e8:	9782                	jalr	a5
ffffffffc02035ea:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02035ec:	efdfc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc02035f0:	b361                	j	ffffffffc0203378 <pmm_init+0x3d2>
ffffffffc02035f2:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02035f4:	efbfc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc02035f8:	000bb783          	ld	a5,0(s7)
ffffffffc02035fc:	6522                	ld	a0,8(sp)
ffffffffc02035fe:	4585                	li	a1,1
ffffffffc0203600:	739c                	ld	a5,32(a5)
ffffffffc0203602:	9782                	jalr	a5
        intr_enable();
ffffffffc0203604:	ee5fc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0203608:	bb91                	j	ffffffffc020335c <pmm_init+0x3b6>
ffffffffc020360a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020360c:	ee3fc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc0203610:	000bb783          	ld	a5,0(s7)
ffffffffc0203614:	6522                	ld	a0,8(sp)
ffffffffc0203616:	4585                	li	a1,1
ffffffffc0203618:	739c                	ld	a5,32(a5)
ffffffffc020361a:	9782                	jalr	a5
        intr_enable();
ffffffffc020361c:	ecdfc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0203620:	b319                	j	ffffffffc0203326 <pmm_init+0x380>
ffffffffc0203622:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203624:	ecbfc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc0203628:	000bb783          	ld	a5,0(s7)
ffffffffc020362c:	6522                	ld	a0,8(sp)
ffffffffc020362e:	4585                	li	a1,1
ffffffffc0203630:	739c                	ld	a5,32(a5)
ffffffffc0203632:	9782                	jalr	a5
        intr_enable();
ffffffffc0203634:	eb5fc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0203638:	bdc1                	j	ffffffffc0203508 <pmm_init+0x562>
        intr_disable();
ffffffffc020363a:	eb5fc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc020363e:	000bb783          	ld	a5,0(s7)
ffffffffc0203642:	4585                	li	a1,1
ffffffffc0203644:	8556                	mv	a0,s5
ffffffffc0203646:	739c                	ld	a5,32(a5)
ffffffffc0203648:	9782                	jalr	a5
        intr_enable();
ffffffffc020364a:	e9ffc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc020364e:	b559                	j	ffffffffc02034d4 <pmm_init+0x52e>
        intr_disable();
ffffffffc0203650:	e9ffc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0203654:	000bb783          	ld	a5,0(s7)
ffffffffc0203658:	779c                	ld	a5,40(a5)
ffffffffc020365a:	9782                	jalr	a5
ffffffffc020365c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020365e:	e8bfc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0203662:	bde5                	j	ffffffffc020355a <pmm_init+0x5b4>
ffffffffc0203664:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203666:	e89fc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc020366a:	000bb783          	ld	a5,0(s7)
ffffffffc020366e:	6522                	ld	a0,8(sp)
ffffffffc0203670:	4585                	li	a1,1
ffffffffc0203672:	739c                	ld	a5,32(a5)
ffffffffc0203674:	9782                	jalr	a5
        intr_enable();
ffffffffc0203676:	e73fc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc020367a:	b5d1                	j	ffffffffc020353e <pmm_init+0x598>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020367c:	00003697          	auipc	a3,0x3
ffffffffc0203680:	85c68693          	addi	a3,a3,-1956 # ffffffffc0205ed8 <default_pmm_manager+0x448>
ffffffffc0203684:	00001617          	auipc	a2,0x1
ffffffffc0203688:	79c60613          	addi	a2,a2,1948 # ffffffffc0204e20 <commands+0x718>
ffffffffc020368c:	1b400593          	li	a1,436
ffffffffc0203690:	00002517          	auipc	a0,0x2
ffffffffc0203694:	46050513          	addi	a0,a0,1120 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203698:	a6bfc0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020369c:	00002697          	auipc	a3,0x2
ffffffffc02036a0:	7fc68693          	addi	a3,a3,2044 # ffffffffc0205e98 <default_pmm_manager+0x408>
ffffffffc02036a4:	00001617          	auipc	a2,0x1
ffffffffc02036a8:	77c60613          	addi	a2,a2,1916 # ffffffffc0204e20 <commands+0x718>
ffffffffc02036ac:	1b300593          	li	a1,435
ffffffffc02036b0:	00002517          	auipc	a0,0x2
ffffffffc02036b4:	44050513          	addi	a0,a0,1088 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc02036b8:	a4bfc0ef          	jal	ra,ffffffffc0200102 <__panic>
ffffffffc02036bc:	86a2                	mv	a3,s0
ffffffffc02036be:	00002617          	auipc	a2,0x2
ffffffffc02036c2:	40a60613          	addi	a2,a2,1034 # ffffffffc0205ac8 <default_pmm_manager+0x38>
ffffffffc02036c6:	1b300593          	li	a1,435
ffffffffc02036ca:	00002517          	auipc	a0,0x2
ffffffffc02036ce:	42650513          	addi	a0,a0,1062 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc02036d2:	a31fc0ef          	jal	ra,ffffffffc0200102 <__panic>
ffffffffc02036d6:	ba2ff0ef          	jal	ra,ffffffffc0202a78 <pa2page.part.0>
    assert(pte2page(*ptep) == p1);
ffffffffc02036da:	00002697          	auipc	a3,0x2
ffffffffc02036de:	5d668693          	addi	a3,a3,1494 # ffffffffc0205cb0 <default_pmm_manager+0x220>
ffffffffc02036e2:	00001617          	auipc	a2,0x1
ffffffffc02036e6:	73e60613          	addi	a2,a2,1854 # ffffffffc0204e20 <commands+0x718>
ffffffffc02036ea:	17e00593          	li	a1,382
ffffffffc02036ee:	00002517          	auipc	a0,0x2
ffffffffc02036f2:	40250513          	addi	a0,a0,1026 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc02036f6:	a0dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(*ptep & PTE_W);
ffffffffc02036fa:	00002697          	auipc	a3,0x2
ffffffffc02036fe:	68668693          	addi	a3,a3,1670 # ffffffffc0205d80 <default_pmm_manager+0x2f0>
ffffffffc0203702:	00001617          	auipc	a2,0x1
ffffffffc0203706:	71e60613          	addi	a2,a2,1822 # ffffffffc0204e20 <commands+0x718>
ffffffffc020370a:	18b00593          	li	a1,395
ffffffffc020370e:	00002517          	auipc	a0,0x2
ffffffffc0203712:	3e250513          	addi	a0,a0,994 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203716:	9edfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(*ptep & PTE_U);
ffffffffc020371a:	00002697          	auipc	a3,0x2
ffffffffc020371e:	65668693          	addi	a3,a3,1622 # ffffffffc0205d70 <default_pmm_manager+0x2e0>
ffffffffc0203722:	00001617          	auipc	a2,0x1
ffffffffc0203726:	6fe60613          	addi	a2,a2,1790 # ffffffffc0204e20 <commands+0x718>
ffffffffc020372a:	18a00593          	li	a1,394
ffffffffc020372e:	00002517          	auipc	a0,0x2
ffffffffc0203732:	3c250513          	addi	a0,a0,962 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203736:	9cdfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc020373a:	00002697          	auipc	a3,0x2
ffffffffc020373e:	60668693          	addi	a3,a3,1542 # ffffffffc0205d40 <default_pmm_manager+0x2b0>
ffffffffc0203742:	00001617          	auipc	a2,0x1
ffffffffc0203746:	6de60613          	addi	a2,a2,1758 # ffffffffc0204e20 <commands+0x718>
ffffffffc020374a:	18900593          	li	a1,393
ffffffffc020374e:	00002517          	auipc	a0,0x2
ffffffffc0203752:	3a250513          	addi	a0,a0,930 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203756:	9adfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020375a:	00002697          	auipc	a3,0x2
ffffffffc020375e:	5ae68693          	addi	a3,a3,1454 # ffffffffc0205d08 <default_pmm_manager+0x278>
ffffffffc0203762:	00001617          	auipc	a2,0x1
ffffffffc0203766:	6be60613          	addi	a2,a2,1726 # ffffffffc0204e20 <commands+0x718>
ffffffffc020376a:	18800593          	li	a1,392
ffffffffc020376e:	00002517          	auipc	a0,0x2
ffffffffc0203772:	38250513          	addi	a0,a0,898 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203776:	98dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p) == 1);
ffffffffc020377a:	00002697          	auipc	a3,0x2
ffffffffc020377e:	7c668693          	addi	a3,a3,1990 # ffffffffc0205f40 <default_pmm_manager+0x4b0>
ffffffffc0203782:	00001617          	auipc	a2,0x1
ffffffffc0203786:	69e60613          	addi	a2,a2,1694 # ffffffffc0204e20 <commands+0x718>
ffffffffc020378a:	1bd00593          	li	a1,445
ffffffffc020378e:	00002517          	auipc	a0,0x2
ffffffffc0203792:	36250513          	addi	a0,a0,866 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203796:	96dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc020379a:	00002697          	auipc	a3,0x2
ffffffffc020379e:	76e68693          	addi	a3,a3,1902 # ffffffffc0205f08 <default_pmm_manager+0x478>
ffffffffc02037a2:	00001617          	auipc	a2,0x1
ffffffffc02037a6:	67e60613          	addi	a2,a2,1662 # ffffffffc0204e20 <commands+0x718>
ffffffffc02037aa:	1bc00593          	li	a1,444
ffffffffc02037ae:	00002517          	auipc	a0,0x2
ffffffffc02037b2:	34250513          	addi	a0,a0,834 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc02037b6:	94dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02037ba:	00002697          	auipc	a3,0x2
ffffffffc02037be:	64e68693          	addi	a3,a3,1614 # ffffffffc0205e08 <default_pmm_manager+0x378>
ffffffffc02037c2:	00001617          	auipc	a2,0x1
ffffffffc02037c6:	65e60613          	addi	a2,a2,1630 # ffffffffc0204e20 <commands+0x718>
ffffffffc02037ca:	19a00593          	li	a1,410
ffffffffc02037ce:	00002517          	auipc	a0,0x2
ffffffffc02037d2:	32250513          	addi	a0,a0,802 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc02037d6:	92dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02037da:	00002697          	auipc	a3,0x2
ffffffffc02037de:	4ee68693          	addi	a3,a3,1262 # ffffffffc0205cc8 <default_pmm_manager+0x238>
ffffffffc02037e2:	00001617          	auipc	a2,0x1
ffffffffc02037e6:	63e60613          	addi	a2,a2,1598 # ffffffffc0204e20 <commands+0x718>
ffffffffc02037ea:	19900593          	li	a1,409
ffffffffc02037ee:	00002517          	auipc	a0,0x2
ffffffffc02037f2:	30250513          	addi	a0,a0,770 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc02037f6:	90dfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc02037fa:	00002697          	auipc	a3,0x2
ffffffffc02037fe:	62668693          	addi	a3,a3,1574 # ffffffffc0205e20 <default_pmm_manager+0x390>
ffffffffc0203802:	00001617          	auipc	a2,0x1
ffffffffc0203806:	61e60613          	addi	a2,a2,1566 # ffffffffc0204e20 <commands+0x718>
ffffffffc020380a:	19500593          	li	a1,405
ffffffffc020380e:	00002517          	auipc	a0,0x2
ffffffffc0203812:	2e250513          	addi	a0,a0,738 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203816:	8edfc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc020381a:	00002697          	auipc	a3,0x2
ffffffffc020381e:	49668693          	addi	a3,a3,1174 # ffffffffc0205cb0 <default_pmm_manager+0x220>
ffffffffc0203822:	00001617          	auipc	a2,0x1
ffffffffc0203826:	5fe60613          	addi	a2,a2,1534 # ffffffffc0204e20 <commands+0x718>
ffffffffc020382a:	19400593          	li	a1,404
ffffffffc020382e:	00002517          	auipc	a0,0x2
ffffffffc0203832:	2c250513          	addi	a0,a0,706 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203836:	8cdfc0ef          	jal	ra,ffffffffc0200102 <__panic>
ffffffffc020383a:	a5aff0ef          	jal	ra,ffffffffc0202a94 <pte2page.part.0>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL); // 获取页表项并检查是否正确映射
ffffffffc020383e:	00002697          	auipc	a3,0x2
ffffffffc0203842:	44268693          	addi	a3,a3,1090 # ffffffffc0205c80 <default_pmm_manager+0x1f0>
ffffffffc0203846:	00001617          	auipc	a2,0x1
ffffffffc020384a:	5da60613          	addi	a2,a2,1498 # ffffffffc0204e20 <commands+0x718>
ffffffffc020384e:	17d00593          	li	a1,381
ffffffffc0203852:	00002517          	auipc	a0,0x2
ffffffffc0203856:	29e50513          	addi	a0,a0,670 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc020385a:	8a9fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc020385e:	00002697          	auipc	a3,0x2
ffffffffc0203862:	3f268693          	addi	a3,a3,1010 # ffffffffc0205c50 <default_pmm_manager+0x1c0>
ffffffffc0203866:	00001617          	auipc	a2,0x1
ffffffffc020386a:	5ba60613          	addi	a2,a2,1466 # ffffffffc0204e20 <commands+0x718>
ffffffffc020386e:	17b00593          	li	a1,379
ffffffffc0203872:	00002517          	auipc	a0,0x2
ffffffffc0203876:	27e50513          	addi	a0,a0,638 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc020387a:	889fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL); // 确保虚拟地址 0x0 没有映射
ffffffffc020387e:	00002697          	auipc	a3,0x2
ffffffffc0203882:	3aa68693          	addi	a3,a3,938 # ffffffffc0205c28 <default_pmm_manager+0x198>
ffffffffc0203886:	00001617          	auipc	a2,0x1
ffffffffc020388a:	59a60613          	addi	a2,a2,1434 # ffffffffc0204e20 <commands+0x718>
ffffffffc020388e:	17600593          	li	a1,374
ffffffffc0203892:	00002517          	auipc	a0,0x2
ffffffffc0203896:	25e50513          	addi	a0,a0,606 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc020389a:	869fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020389e:	00002697          	auipc	a3,0x2
ffffffffc02038a2:	56a68693          	addi	a3,a3,1386 # ffffffffc0205e08 <default_pmm_manager+0x378>
ffffffffc02038a6:	00001617          	auipc	a2,0x1
ffffffffc02038aa:	57a60613          	addi	a2,a2,1402 # ffffffffc0204e20 <commands+0x718>
ffffffffc02038ae:	19d00593          	li	a1,413
ffffffffc02038b2:	00002517          	auipc	a0,0x2
ffffffffc02038b6:	23e50513          	addi	a0,a0,574 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc02038ba:	849fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02038be:	00002697          	auipc	a3,0x2
ffffffffc02038c2:	57a68693          	addi	a3,a3,1402 # ffffffffc0205e38 <default_pmm_manager+0x3a8>
ffffffffc02038c6:	00001617          	auipc	a2,0x1
ffffffffc02038ca:	55a60613          	addi	a2,a2,1370 # ffffffffc0204e20 <commands+0x718>
ffffffffc02038ce:	19c00593          	li	a1,412
ffffffffc02038d2:	00002517          	auipc	a0,0x2
ffffffffc02038d6:	21e50513          	addi	a0,a0,542 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc02038da:	829fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02038de:	00002697          	auipc	a3,0x2
ffffffffc02038e2:	72268693          	addi	a3,a3,1826 # ffffffffc0206000 <default_pmm_manager+0x570>
ffffffffc02038e6:	00001617          	auipc	a2,0x1
ffffffffc02038ea:	53a60613          	addi	a2,a2,1338 # ffffffffc0204e20 <commands+0x718>
ffffffffc02038ee:	1c600593          	li	a1,454
ffffffffc02038f2:	00002517          	auipc	a0,0x2
ffffffffc02038f6:	1fe50513          	addi	a0,a0,510 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc02038fa:	809fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02038fe:	00002697          	auipc	a3,0x2
ffffffffc0203902:	6ca68693          	addi	a3,a3,1738 # ffffffffc0205fc8 <default_pmm_manager+0x538>
ffffffffc0203906:	00001617          	auipc	a2,0x1
ffffffffc020390a:	51a60613          	addi	a2,a2,1306 # ffffffffc0204e20 <commands+0x718>
ffffffffc020390e:	1c300593          	li	a1,451
ffffffffc0203912:	00002517          	auipc	a0,0x2
ffffffffc0203916:	1de50513          	addi	a0,a0,478 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc020391a:	fe8fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p) == 2);
ffffffffc020391e:	00002697          	auipc	a3,0x2
ffffffffc0203922:	67a68693          	addi	a3,a3,1658 # ffffffffc0205f98 <default_pmm_manager+0x508>
ffffffffc0203926:	00001617          	auipc	a2,0x1
ffffffffc020392a:	4fa60613          	addi	a2,a2,1274 # ffffffffc0204e20 <commands+0x718>
ffffffffc020392e:	1bf00593          	li	a1,447
ffffffffc0203932:	00002517          	auipc	a0,0x2
ffffffffc0203936:	1be50513          	addi	a0,a0,446 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc020393a:	fc8fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020393e:	00002697          	auipc	a3,0x2
ffffffffc0203942:	61a68693          	addi	a3,a3,1562 # ffffffffc0205f58 <default_pmm_manager+0x4c8>
ffffffffc0203946:	00001617          	auipc	a2,0x1
ffffffffc020394a:	4da60613          	addi	a2,a2,1242 # ffffffffc0204e20 <commands+0x718>
ffffffffc020394e:	1be00593          	li	a1,446
ffffffffc0203952:	00002517          	auipc	a0,0x2
ffffffffc0203956:	19e50513          	addi	a0,a0,414 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc020395a:	fa8fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc020395e:	00002617          	auipc	a2,0x2
ffffffffc0203962:	16a60613          	addi	a2,a2,362 # ffffffffc0205ac8 <default_pmm_manager+0x38>
ffffffffc0203966:	18200593          	li	a1,386
ffffffffc020396a:	00002517          	auipc	a0,0x2
ffffffffc020396e:	18650513          	addi	a0,a0,390 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203972:	f90fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203976:	00002697          	auipc	a3,0x2
ffffffffc020397a:	35268693          	addi	a3,a3,850 # ffffffffc0205cc8 <default_pmm_manager+0x238>
ffffffffc020397e:	00001617          	auipc	a2,0x1
ffffffffc0203982:	4a260613          	addi	a2,a2,1186 # ffffffffc0204e20 <commands+0x718>
ffffffffc0203986:	17f00593          	li	a1,383
ffffffffc020398a:	00002517          	auipc	a0,0x2
ffffffffc020398e:	16650513          	addi	a0,a0,358 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203992:	f70fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 获取 pages 数组后面第一个空闲物理地址
ffffffffc0203996:	00002617          	auipc	a2,0x2
ffffffffc020399a:	1f260613          	addi	a2,a2,498 # ffffffffc0205b88 <default_pmm_manager+0xf8>
ffffffffc020399e:	07d00593          	li	a1,125
ffffffffc02039a2:	00002517          	auipc	a0,0x2
ffffffffc02039a6:	14e50513          	addi	a0,a0,334 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc02039aa:	f58fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free_store == nr_free_pages()); // 确保空闲页数一致
ffffffffc02039ae:	00002697          	auipc	a3,0x2
ffffffffc02039b2:	4a268693          	addi	a3,a3,1186 # ffffffffc0205e50 <default_pmm_manager+0x3c0>
ffffffffc02039b6:	00001617          	auipc	a2,0x1
ffffffffc02039ba:	46a60613          	addi	a2,a2,1130 # ffffffffc0204e20 <commands+0x718>
ffffffffc02039be:	1cf00593          	li	a1,463
ffffffffc02039c2:	00002517          	auipc	a0,0x2
ffffffffc02039c6:	12e50513          	addi	a0,a0,302 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc02039ca:	f38fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc02039ce:	00002617          	auipc	a2,0x2
ffffffffc02039d2:	0fa60613          	addi	a2,a2,250 # ffffffffc0205ac8 <default_pmm_manager+0x38>
ffffffffc02039d6:	07700593          	li	a1,119
ffffffffc02039da:	00002517          	auipc	a0,0x2
ffffffffc02039de:	87650513          	addi	a0,a0,-1930 # ffffffffc0205250 <commands+0xb48>
ffffffffc02039e2:	f20fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc02039e6:	00002697          	auipc	a3,0x2
ffffffffc02039ea:	50a68693          	addi	a3,a3,1290 # ffffffffc0205ef0 <default_pmm_manager+0x460>
ffffffffc02039ee:	00001617          	auipc	a2,0x1
ffffffffc02039f2:	43260613          	addi	a2,a2,1074 # ffffffffc0204e20 <commands+0x718>
ffffffffc02039f6:	1b700593          	li	a1,439
ffffffffc02039fa:	00002517          	auipc	a0,0x2
ffffffffc02039fe:	0f650513          	addi	a0,a0,246 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203a02:	f00fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0203a06:	00002697          	auipc	a3,0x2
ffffffffc0203a0a:	1ea68693          	addi	a3,a3,490 # ffffffffc0205bf0 <default_pmm_manager+0x160>
ffffffffc0203a0e:	00001617          	auipc	a2,0x1
ffffffffc0203a12:	41260613          	addi	a2,a2,1042 # ffffffffc0204e20 <commands+0x718>
ffffffffc0203a16:	17500593          	li	a1,373
ffffffffc0203a1a:	00002517          	auipc	a0,0x2
ffffffffc0203a1e:	0d650513          	addi	a0,a0,214 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203a22:	ee0fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0203a26:	00002697          	auipc	a3,0x2
ffffffffc0203a2a:	1aa68693          	addi	a3,a3,426 # ffffffffc0205bd0 <default_pmm_manager+0x140>
ffffffffc0203a2e:	00001617          	auipc	a2,0x1
ffffffffc0203a32:	3f260613          	addi	a2,a2,1010 # ffffffffc0204e20 <commands+0x718>
ffffffffc0203a36:	17400593          	li	a1,372
ffffffffc0203a3a:	00002517          	auipc	a0,0x2
ffffffffc0203a3e:	0b650513          	addi	a0,a0,182 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203a42:	ec0fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0203a46:	00002697          	auipc	a3,0x2
ffffffffc0203a4a:	29a68693          	addi	a3,a3,666 # ffffffffc0205ce0 <default_pmm_manager+0x250>
ffffffffc0203a4e:	00001617          	auipc	a2,0x1
ffffffffc0203a52:	3d260613          	addi	a2,a2,978 # ffffffffc0204e20 <commands+0x718>
ffffffffc0203a56:	18400593          	li	a1,388
ffffffffc0203a5a:	00002517          	auipc	a0,0x2
ffffffffc0203a5e:	09650513          	addi	a0,a0,150 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203a62:	ea0fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203a66:	86d6                	mv	a3,s5
ffffffffc0203a68:	00002617          	auipc	a2,0x2
ffffffffc0203a6c:	06060613          	addi	a2,a2,96 # ffffffffc0205ac8 <default_pmm_manager+0x38>
ffffffffc0203a70:	18300593          	li	a1,387
ffffffffc0203a74:	00002517          	auipc	a0,0x2
ffffffffc0203a78:	07c50513          	addi	a0,a0,124 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203a7c:	e86fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0203a80:	00002697          	auipc	a3,0x2
ffffffffc0203a84:	2c068693          	addi	a3,a3,704 # ffffffffc0205d40 <default_pmm_manager+0x2b0>
ffffffffc0203a88:	00001617          	auipc	a2,0x1
ffffffffc0203a8c:	39860613          	addi	a2,a2,920 # ffffffffc0204e20 <commands+0x718>
ffffffffc0203a90:	19300593          	li	a1,403
ffffffffc0203a94:	00002517          	auipc	a0,0x2
ffffffffc0203a98:	05c50513          	addi	a0,a0,92 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203a9c:	e66fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203aa0:	00002697          	auipc	a3,0x2
ffffffffc0203aa4:	36868693          	addi	a3,a3,872 # ffffffffc0205e08 <default_pmm_manager+0x378>
ffffffffc0203aa8:	00001617          	auipc	a2,0x1
ffffffffc0203aac:	37860613          	addi	a2,a2,888 # ffffffffc0204e20 <commands+0x718>
ffffffffc0203ab0:	19200593          	li	a1,402
ffffffffc0203ab4:	00002517          	auipc	a0,0x2
ffffffffc0203ab8:	03c50513          	addi	a0,a0,60 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203abc:	e46fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203ac0:	00002697          	auipc	a3,0x2
ffffffffc0203ac4:	33068693          	addi	a3,a3,816 # ffffffffc0205df0 <default_pmm_manager+0x360>
ffffffffc0203ac8:	00001617          	auipc	a2,0x1
ffffffffc0203acc:	35860613          	addi	a2,a2,856 # ffffffffc0204e20 <commands+0x718>
ffffffffc0203ad0:	19100593          	li	a1,401
ffffffffc0203ad4:	00002517          	auipc	a0,0x2
ffffffffc0203ad8:	01c50513          	addi	a0,a0,28 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203adc:	e26fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0203ae0:	00002697          	auipc	a3,0x2
ffffffffc0203ae4:	2e068693          	addi	a3,a3,736 # ffffffffc0205dc0 <default_pmm_manager+0x330>
ffffffffc0203ae8:	00001617          	auipc	a2,0x1
ffffffffc0203aec:	33860613          	addi	a2,a2,824 # ffffffffc0204e20 <commands+0x718>
ffffffffc0203af0:	19000593          	li	a1,400
ffffffffc0203af4:	00002517          	auipc	a0,0x2
ffffffffc0203af8:	ffc50513          	addi	a0,a0,-4 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203afc:	e06fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203b00:	00002697          	auipc	a3,0x2
ffffffffc0203b04:	2a868693          	addi	a3,a3,680 # ffffffffc0205da8 <default_pmm_manager+0x318>
ffffffffc0203b08:	00001617          	auipc	a2,0x1
ffffffffc0203b0c:	31860613          	addi	a2,a2,792 # ffffffffc0204e20 <commands+0x718>
ffffffffc0203b10:	18d00593          	li	a1,397
ffffffffc0203b14:	00002517          	auipc	a0,0x2
ffffffffc0203b18:	fdc50513          	addi	a0,a0,-36 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203b1c:	de6fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0203b20:	00002697          	auipc	a3,0x2
ffffffffc0203b24:	27068693          	addi	a3,a3,624 # ffffffffc0205d90 <default_pmm_manager+0x300>
ffffffffc0203b28:	00001617          	auipc	a2,0x1
ffffffffc0203b2c:	2f860613          	addi	a2,a2,760 # ffffffffc0204e20 <commands+0x718>
ffffffffc0203b30:	18c00593          	li	a1,396
ffffffffc0203b34:	00002517          	auipc	a0,0x2
ffffffffc0203b38:	fbc50513          	addi	a0,a0,-68 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203b3c:	dc6fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0203b40:	00002617          	auipc	a2,0x2
ffffffffc0203b44:	04860613          	addi	a2,a2,72 # ffffffffc0205b88 <default_pmm_manager+0xf8>
ffffffffc0203b48:	0c900593          	li	a1,201
ffffffffc0203b4c:	00002517          	auipc	a0,0x2
ffffffffc0203b50:	fa450513          	addi	a0,a0,-92 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203b54:	daefc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free_store == nr_free_pages()); // 验证空闲页数是否与之前一致
ffffffffc0203b58:	00002697          	auipc	a3,0x2
ffffffffc0203b5c:	2f868693          	addi	a3,a3,760 # ffffffffc0205e50 <default_pmm_manager+0x3c0>
ffffffffc0203b60:	00001617          	auipc	a2,0x1
ffffffffc0203b64:	2c060613          	addi	a2,a2,704 # ffffffffc0204e20 <commands+0x718>
ffffffffc0203b68:	1a500593          	li	a1,421
ffffffffc0203b6c:	00002517          	auipc	a0,0x2
ffffffffc0203b70:	f8450513          	addi	a0,a0,-124 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203b74:	d8efc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203b78 <tlb_invalidate>:
    asm volatile("sfence.vma"); // 刷新 TLB 中的地址映射
ffffffffc0203b78:	12000073          	sfence.vma
void tlb_invalidate(pde_t *pgdir, uintptr_t la) { flush_tlb(); }
ffffffffc0203b7c:	8082                	ret

ffffffffc0203b7e <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0203b7e:	7179                	addi	sp,sp,-48
ffffffffc0203b80:	e84a                	sd	s2,16(sp)
ffffffffc0203b82:	892a                	mv	s2,a0
    struct Page *page = alloc_page(); // 分配一个物理页
ffffffffc0203b84:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0203b86:	f022                	sd	s0,32(sp)
ffffffffc0203b88:	ec26                	sd	s1,24(sp)
ffffffffc0203b8a:	e44e                	sd	s3,8(sp)
ffffffffc0203b8c:	f406                	sd	ra,40(sp)
ffffffffc0203b8e:	84ae                	mv	s1,a1
ffffffffc0203b90:	89b2                	mv	s3,a2
    struct Page *page = alloc_page(); // 分配一个物理页
ffffffffc0203b92:	f1ffe0ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
ffffffffc0203b96:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0203b98:	cd09                	beqz	a0,ffffffffc0203bb2 <pgdir_alloc_page+0x34>
        if (page_insert(pgdir, page, la, perm) != 0) { // 插入页表映射，若失败则释放页面并返回 NULL
ffffffffc0203b9a:	85aa                	mv	a1,a0
ffffffffc0203b9c:	86ce                	mv	a3,s3
ffffffffc0203b9e:	8626                	mv	a2,s1
ffffffffc0203ba0:	854a                	mv	a0,s2
ffffffffc0203ba2:	b04ff0ef          	jal	ra,ffffffffc0202ea6 <page_insert>
ffffffffc0203ba6:	ed21                	bnez	a0,ffffffffc0203bfe <pgdir_alloc_page+0x80>
        if (swap_init_ok) { // 若启用交换功能
ffffffffc0203ba8:	0000e797          	auipc	a5,0xe
ffffffffc0203bac:	9887a783          	lw	a5,-1656(a5) # ffffffffc0211530 <swap_init_ok>
ffffffffc0203bb0:	eb89                	bnez	a5,ffffffffc0203bc2 <pgdir_alloc_page+0x44>
}
ffffffffc0203bb2:	70a2                	ld	ra,40(sp)
ffffffffc0203bb4:	8522                	mv	a0,s0
ffffffffc0203bb6:	7402                	ld	s0,32(sp)
ffffffffc0203bb8:	64e2                	ld	s1,24(sp)
ffffffffc0203bba:	6942                	ld	s2,16(sp)
ffffffffc0203bbc:	69a2                	ld	s3,8(sp)
ffffffffc0203bbe:	6145                	addi	sp,sp,48
ffffffffc0203bc0:	8082                	ret
            swap_map_swappable(check_mm_struct, la, page, 0); // 将页面标记为可交换
ffffffffc0203bc2:	4681                	li	a3,0
ffffffffc0203bc4:	8622                	mv	a2,s0
ffffffffc0203bc6:	85a6                	mv	a1,s1
ffffffffc0203bc8:	0000e517          	auipc	a0,0xe
ffffffffc0203bcc:	94853503          	ld	a0,-1720(a0) # ffffffffc0211510 <check_mm_struct>
ffffffffc0203bd0:	a36fe0ef          	jal	ra,ffffffffc0201e06 <swap_map_swappable>
            assert(page_ref(page) == 1); // 确保页面的引用计数为1
ffffffffc0203bd4:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la; // 设置页面的虚拟地址
ffffffffc0203bd6:	e024                	sd	s1,64(s0)
            assert(page_ref(page) == 1); // 确保页面的引用计数为1
ffffffffc0203bd8:	4785                	li	a5,1
ffffffffc0203bda:	fcf70ce3          	beq	a4,a5,ffffffffc0203bb2 <pgdir_alloc_page+0x34>
ffffffffc0203bde:	00002697          	auipc	a3,0x2
ffffffffc0203be2:	46a68693          	addi	a3,a3,1130 # ffffffffc0206048 <default_pmm_manager+0x5b8>
ffffffffc0203be6:	00001617          	auipc	a2,0x1
ffffffffc0203bea:	23a60613          	addi	a2,a2,570 # ffffffffc0204e20 <commands+0x718>
ffffffffc0203bee:	16200593          	li	a1,354
ffffffffc0203bf2:	00002517          	auipc	a0,0x2
ffffffffc0203bf6:	efe50513          	addi	a0,a0,-258 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203bfa:	d08fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203bfe:	100027f3          	csrr	a5,sstatus
ffffffffc0203c02:	8b89                	andi	a5,a5,2
ffffffffc0203c04:	eb99                	bnez	a5,ffffffffc0203c1a <pgdir_alloc_page+0x9c>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0203c06:	0000e797          	auipc	a5,0xe
ffffffffc0203c0a:	9527b783          	ld	a5,-1710(a5) # ffffffffc0211558 <pmm_manager>
ffffffffc0203c0e:	739c                	ld	a5,32(a5)
ffffffffc0203c10:	8522                	mv	a0,s0
ffffffffc0203c12:	4585                	li	a1,1
ffffffffc0203c14:	9782                	jalr	a5
            return NULL;
ffffffffc0203c16:	4401                	li	s0,0
ffffffffc0203c18:	bf69                	j	ffffffffc0203bb2 <pgdir_alloc_page+0x34>
        intr_disable();
ffffffffc0203c1a:	8d5fc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0203c1e:	0000e797          	auipc	a5,0xe
ffffffffc0203c22:	93a7b783          	ld	a5,-1734(a5) # ffffffffc0211558 <pmm_manager>
ffffffffc0203c26:	739c                	ld	a5,32(a5)
ffffffffc0203c28:	8522                	mv	a0,s0
ffffffffc0203c2a:	4585                	li	a1,1
ffffffffc0203c2c:	9782                	jalr	a5
            return NULL;
ffffffffc0203c2e:	4401                	li	s0,0
        intr_enable();
ffffffffc0203c30:	8b9fc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0203c34:	bfbd                	j	ffffffffc0203bb2 <pgdir_alloc_page+0x34>

ffffffffc0203c36 <kmalloc>:
}

// kmalloc - 内核内存分配函数，分配 n 字节的内存并返回内核虚拟地址
void *kmalloc(size_t n) {
ffffffffc0203c36:	1141                	addi	sp,sp,-16
    void *ptr = NULL;
    struct Page *base = NULL;
    assert(n > 0 && n < 1024 * 0124); // 确保分配字节数在范围内
ffffffffc0203c38:	67d5                	lui	a5,0x15
void *kmalloc(size_t n) {
ffffffffc0203c3a:	e406                	sd	ra,8(sp)
    assert(n > 0 && n < 1024 * 0124); // 确保分配字节数在范围内
ffffffffc0203c3c:	fff50713          	addi	a4,a0,-1
ffffffffc0203c40:	17f9                	addi	a5,a5,-2
ffffffffc0203c42:	04e7ea63          	bltu	a5,a4,ffffffffc0203c96 <kmalloc+0x60>
    int num_pages = (n + PGSIZE - 1) / PGSIZE; // 计算所需的页面数
ffffffffc0203c46:	6785                	lui	a5,0x1
ffffffffc0203c48:	17fd                	addi	a5,a5,-1
ffffffffc0203c4a:	953e                	add	a0,a0,a5
    base = alloc_pages(num_pages); // 分配页面
ffffffffc0203c4c:	8131                	srli	a0,a0,0xc
ffffffffc0203c4e:	e63fe0ef          	jal	ra,ffffffffc0202ab0 <alloc_pages>
    assert(base != NULL);
ffffffffc0203c52:	cd3d                	beqz	a0,ffffffffc0203cd0 <kmalloc+0x9a>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0203c54:	0000e797          	auipc	a5,0xe
ffffffffc0203c58:	8fc7b783          	ld	a5,-1796(a5) # ffffffffc0211550 <pages>
ffffffffc0203c5c:	8d1d                	sub	a0,a0,a5
ffffffffc0203c5e:	00002697          	auipc	a3,0x2
ffffffffc0203c62:	6e26b683          	ld	a3,1762(a3) # ffffffffc0206340 <error_string+0x38>
ffffffffc0203c66:	850d                	srai	a0,a0,0x3
ffffffffc0203c68:	02d50533          	mul	a0,a0,a3
ffffffffc0203c6c:	000806b7          	lui	a3,0x80
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203c70:	0000e717          	auipc	a4,0xe
ffffffffc0203c74:	8d873703          	ld	a4,-1832(a4) # ffffffffc0211548 <npage>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0203c78:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203c7a:	00c51793          	slli	a5,a0,0xc
ffffffffc0203c7e:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc0203c80:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203c82:	02e7fa63          	bgeu	a5,a4,ffffffffc0203cb6 <kmalloc+0x80>
    ptr = page2kva(base); // 将页面转换为内核虚拟地址
    return ptr;
}
ffffffffc0203c86:	60a2                	ld	ra,8(sp)
ffffffffc0203c88:	0000e797          	auipc	a5,0xe
ffffffffc0203c8c:	8d87b783          	ld	a5,-1832(a5) # ffffffffc0211560 <va_pa_offset>
ffffffffc0203c90:	953e                	add	a0,a0,a5
ffffffffc0203c92:	0141                	addi	sp,sp,16
ffffffffc0203c94:	8082                	ret
    assert(n > 0 && n < 1024 * 0124); // 确保分配字节数在范围内
ffffffffc0203c96:	00002697          	auipc	a3,0x2
ffffffffc0203c9a:	3ca68693          	addi	a3,a3,970 # ffffffffc0206060 <default_pmm_manager+0x5d0>
ffffffffc0203c9e:	00001617          	auipc	a2,0x1
ffffffffc0203ca2:	18260613          	addi	a2,a2,386 # ffffffffc0204e20 <commands+0x718>
ffffffffc0203ca6:	1d800593          	li	a1,472
ffffffffc0203caa:	00002517          	auipc	a0,0x2
ffffffffc0203cae:	e4650513          	addi	a0,a0,-442 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203cb2:	c50fc0ef          	jal	ra,ffffffffc0200102 <__panic>
ffffffffc0203cb6:	86aa                	mv	a3,a0
ffffffffc0203cb8:	00002617          	auipc	a2,0x2
ffffffffc0203cbc:	e1060613          	addi	a2,a2,-496 # ffffffffc0205ac8 <default_pmm_manager+0x38>
ffffffffc0203cc0:	07700593          	li	a1,119
ffffffffc0203cc4:	00001517          	auipc	a0,0x1
ffffffffc0203cc8:	58c50513          	addi	a0,a0,1420 # ffffffffc0205250 <commands+0xb48>
ffffffffc0203ccc:	c36fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(base != NULL);
ffffffffc0203cd0:	00002697          	auipc	a3,0x2
ffffffffc0203cd4:	3b068693          	addi	a3,a3,944 # ffffffffc0206080 <default_pmm_manager+0x5f0>
ffffffffc0203cd8:	00001617          	auipc	a2,0x1
ffffffffc0203cdc:	14860613          	addi	a2,a2,328 # ffffffffc0204e20 <commands+0x718>
ffffffffc0203ce0:	1db00593          	li	a1,475
ffffffffc0203ce4:	00002517          	auipc	a0,0x2
ffffffffc0203ce8:	e0c50513          	addi	a0,a0,-500 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203cec:	c16fc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203cf0 <kfree>:

// kfree - 内核内存释放函数，释放 ptr 开始的 n 字节内存
void kfree(void *ptr, size_t n) {
ffffffffc0203cf0:	1101                	addi	sp,sp,-32
    assert(n > 0 && n < 1024 * 0124); // 确保释放字节数在范围内
ffffffffc0203cf2:	67d5                	lui	a5,0x15
void kfree(void *ptr, size_t n) {
ffffffffc0203cf4:	ec06                	sd	ra,24(sp)
    assert(n > 0 && n < 1024 * 0124); // 确保释放字节数在范围内
ffffffffc0203cf6:	fff58713          	addi	a4,a1,-1
ffffffffc0203cfa:	17f9                	addi	a5,a5,-2
ffffffffc0203cfc:	0ae7ee63          	bltu	a5,a4,ffffffffc0203db8 <kfree+0xc8>
    assert(ptr != NULL);
ffffffffc0203d00:	cd41                	beqz	a0,ffffffffc0203d98 <kfree+0xa8>
    struct Page *base = NULL;
    int num_pages = (n + PGSIZE - 1) / PGSIZE; // 计算所需的页面数
ffffffffc0203d02:	6785                	lui	a5,0x1
ffffffffc0203d04:	17fd                	addi	a5,a5,-1
ffffffffc0203d06:	95be                	add	a1,a1,a5
    return pa2page(PADDR(kva)); // 先获取物理地址，再调用 pa2page 返回对应的 Page 结构体
ffffffffc0203d08:	c02007b7          	lui	a5,0xc0200
ffffffffc0203d0c:	81b1                	srli	a1,a1,0xc
ffffffffc0203d0e:	06f56863          	bltu	a0,a5,ffffffffc0203d7e <kfree+0x8e>
ffffffffc0203d12:	0000e697          	auipc	a3,0xe
ffffffffc0203d16:	84e6b683          	ld	a3,-1970(a3) # ffffffffc0211560 <va_pa_offset>
ffffffffc0203d1a:	8d15                	sub	a0,a0,a3
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0203d1c:	8131                	srli	a0,a0,0xc
ffffffffc0203d1e:	0000e797          	auipc	a5,0xe
ffffffffc0203d22:	82a7b783          	ld	a5,-2006(a5) # ffffffffc0211548 <npage>
ffffffffc0203d26:	04f57a63          	bgeu	a0,a5,ffffffffc0203d7a <kfree+0x8a>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc0203d2a:	fff806b7          	lui	a3,0xfff80
ffffffffc0203d2e:	9536                	add	a0,a0,a3
ffffffffc0203d30:	00351793          	slli	a5,a0,0x3
ffffffffc0203d34:	953e                	add	a0,a0,a5
ffffffffc0203d36:	050e                	slli	a0,a0,0x3
ffffffffc0203d38:	0000e797          	auipc	a5,0xe
ffffffffc0203d3c:	8187b783          	ld	a5,-2024(a5) # ffffffffc0211550 <pages>
ffffffffc0203d40:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203d42:	100027f3          	csrr	a5,sstatus
ffffffffc0203d46:	8b89                	andi	a5,a5,2
ffffffffc0203d48:	eb89                	bnez	a5,ffffffffc0203d5a <kfree+0x6a>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0203d4a:	0000e797          	auipc	a5,0xe
ffffffffc0203d4e:	80e7b783          	ld	a5,-2034(a5) # ffffffffc0211558 <pmm_manager>
    base = kva2page(ptr); // 获取页面指针
    free_pages(base, num_pages); // 释放页面
}
ffffffffc0203d52:	60e2                	ld	ra,24(sp)
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0203d54:	739c                	ld	a5,32(a5)
}
ffffffffc0203d56:	6105                	addi	sp,sp,32
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0203d58:	8782                	jr	a5
        intr_disable();
ffffffffc0203d5a:	e42a                	sd	a0,8(sp)
ffffffffc0203d5c:	e02e                	sd	a1,0(sp)
ffffffffc0203d5e:	f90fc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc0203d62:	0000d797          	auipc	a5,0xd
ffffffffc0203d66:	7f67b783          	ld	a5,2038(a5) # ffffffffc0211558 <pmm_manager>
ffffffffc0203d6a:	6582                	ld	a1,0(sp)
ffffffffc0203d6c:	6522                	ld	a0,8(sp)
ffffffffc0203d6e:	739c                	ld	a5,32(a5)
ffffffffc0203d70:	9782                	jalr	a5
}
ffffffffc0203d72:	60e2                	ld	ra,24(sp)
ffffffffc0203d74:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0203d76:	f72fc06f          	j	ffffffffc02004e8 <intr_enable>
ffffffffc0203d7a:	cfffe0ef          	jal	ra,ffffffffc0202a78 <pa2page.part.0>
    return pa2page(PADDR(kva)); // 先获取物理地址，再调用 pa2page 返回对应的 Page 结构体
ffffffffc0203d7e:	86aa                	mv	a3,a0
ffffffffc0203d80:	00002617          	auipc	a2,0x2
ffffffffc0203d84:	e0860613          	addi	a2,a2,-504 # ffffffffc0205b88 <default_pmm_manager+0xf8>
ffffffffc0203d88:	07c00593          	li	a1,124
ffffffffc0203d8c:	00001517          	auipc	a0,0x1
ffffffffc0203d90:	4c450513          	addi	a0,a0,1220 # ffffffffc0205250 <commands+0xb48>
ffffffffc0203d94:	b6efc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(ptr != NULL);
ffffffffc0203d98:	00002697          	auipc	a3,0x2
ffffffffc0203d9c:	2f868693          	addi	a3,a3,760 # ffffffffc0206090 <default_pmm_manager+0x600>
ffffffffc0203da0:	00001617          	auipc	a2,0x1
ffffffffc0203da4:	08060613          	addi	a2,a2,128 # ffffffffc0204e20 <commands+0x718>
ffffffffc0203da8:	1e300593          	li	a1,483
ffffffffc0203dac:	00002517          	auipc	a0,0x2
ffffffffc0203db0:	d4450513          	addi	a0,a0,-700 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203db4:	b4efc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(n > 0 && n < 1024 * 0124); // 确保释放字节数在范围内
ffffffffc0203db8:	00002697          	auipc	a3,0x2
ffffffffc0203dbc:	2a868693          	addi	a3,a3,680 # ffffffffc0206060 <default_pmm_manager+0x5d0>
ffffffffc0203dc0:	00001617          	auipc	a2,0x1
ffffffffc0203dc4:	06060613          	addi	a2,a2,96 # ffffffffc0204e20 <commands+0x718>
ffffffffc0203dc8:	1e200593          	li	a1,482
ffffffffc0203dcc:	00002517          	auipc	a0,0x2
ffffffffc0203dd0:	d2450513          	addi	a0,a0,-732 # ffffffffc0205af0 <default_pmm_manager+0x60>
ffffffffc0203dd4:	b2efc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203dd8 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0203dd8:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203dda:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0203ddc:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203dde:	df4fc0ef          	jal	ra,ffffffffc02003d2 <ide_device_valid>
ffffffffc0203de2:	cd01                	beqz	a0,ffffffffc0203dfa <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203de4:	4505                	li	a0,1
ffffffffc0203de6:	df2fc0ef          	jal	ra,ffffffffc02003d8 <ide_device_size>
}
ffffffffc0203dea:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203dec:	810d                	srli	a0,a0,0x3
ffffffffc0203dee:	0000d797          	auipc	a5,0xd
ffffffffc0203df2:	72a7b923          	sd	a0,1842(a5) # ffffffffc0211520 <max_swap_offset>
}
ffffffffc0203df6:	0141                	addi	sp,sp,16
ffffffffc0203df8:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0203dfa:	00002617          	auipc	a2,0x2
ffffffffc0203dfe:	2a660613          	addi	a2,a2,678 # ffffffffc02060a0 <default_pmm_manager+0x610>
ffffffffc0203e02:	45b5                	li	a1,13
ffffffffc0203e04:	00002517          	auipc	a0,0x2
ffffffffc0203e08:	2bc50513          	addi	a0,a0,700 # ffffffffc02060c0 <default_pmm_manager+0x630>
ffffffffc0203e0c:	af6fc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203e10 <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0203e10:	1141                	addi	sp,sp,-16
ffffffffc0203e12:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203e14:	00855793          	srli	a5,a0,0x8
ffffffffc0203e18:	c3a5                	beqz	a5,ffffffffc0203e78 <swapfs_read+0x68>
ffffffffc0203e1a:	0000d717          	auipc	a4,0xd
ffffffffc0203e1e:	70673703          	ld	a4,1798(a4) # ffffffffc0211520 <max_swap_offset>
ffffffffc0203e22:	04e7fb63          	bgeu	a5,a4,ffffffffc0203e78 <swapfs_read+0x68>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0203e26:	0000d617          	auipc	a2,0xd
ffffffffc0203e2a:	72a63603          	ld	a2,1834(a2) # ffffffffc0211550 <pages>
ffffffffc0203e2e:	8d91                	sub	a1,a1,a2
ffffffffc0203e30:	4035d613          	srai	a2,a1,0x3
ffffffffc0203e34:	00002597          	auipc	a1,0x2
ffffffffc0203e38:	50c5b583          	ld	a1,1292(a1) # ffffffffc0206340 <error_string+0x38>
ffffffffc0203e3c:	02b60633          	mul	a2,a2,a1
ffffffffc0203e40:	0037959b          	slliw	a1,a5,0x3
ffffffffc0203e44:	00002797          	auipc	a5,0x2
ffffffffc0203e48:	5047b783          	ld	a5,1284(a5) # ffffffffc0206348 <nbase>
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203e4c:	0000d717          	auipc	a4,0xd
ffffffffc0203e50:	6fc73703          	ld	a4,1788(a4) # ffffffffc0211548 <npage>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0203e54:	963e                	add	a2,a2,a5
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203e56:	00c61793          	slli	a5,a2,0xc
ffffffffc0203e5a:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc0203e5c:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203e5e:	02e7f963          	bgeu	a5,a4,ffffffffc0203e90 <swapfs_read+0x80>
}
ffffffffc0203e62:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203e64:	0000d797          	auipc	a5,0xd
ffffffffc0203e68:	6fc7b783          	ld	a5,1788(a5) # ffffffffc0211560 <va_pa_offset>
ffffffffc0203e6c:	46a1                	li	a3,8
ffffffffc0203e6e:	963e                	add	a2,a2,a5
ffffffffc0203e70:	4505                	li	a0,1
}
ffffffffc0203e72:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203e74:	d6afc06f          	j	ffffffffc02003de <ide_read_secs>
ffffffffc0203e78:	86aa                	mv	a3,a0
ffffffffc0203e7a:	00002617          	auipc	a2,0x2
ffffffffc0203e7e:	25e60613          	addi	a2,a2,606 # ffffffffc02060d8 <default_pmm_manager+0x648>
ffffffffc0203e82:	45d1                	li	a1,20
ffffffffc0203e84:	00002517          	auipc	a0,0x2
ffffffffc0203e88:	23c50513          	addi	a0,a0,572 # ffffffffc02060c0 <default_pmm_manager+0x630>
ffffffffc0203e8c:	a76fc0ef          	jal	ra,ffffffffc0200102 <__panic>
ffffffffc0203e90:	86b2                	mv	a3,a2
ffffffffc0203e92:	07700593          	li	a1,119
ffffffffc0203e96:	00002617          	auipc	a2,0x2
ffffffffc0203e9a:	c3260613          	addi	a2,a2,-974 # ffffffffc0205ac8 <default_pmm_manager+0x38>
ffffffffc0203e9e:	00001517          	auipc	a0,0x1
ffffffffc0203ea2:	3b250513          	addi	a0,a0,946 # ffffffffc0205250 <commands+0xb48>
ffffffffc0203ea6:	a5cfc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203eaa <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0203eaa:	1141                	addi	sp,sp,-16
ffffffffc0203eac:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203eae:	00855793          	srli	a5,a0,0x8
ffffffffc0203eb2:	c3a5                	beqz	a5,ffffffffc0203f12 <swapfs_write+0x68>
ffffffffc0203eb4:	0000d717          	auipc	a4,0xd
ffffffffc0203eb8:	66c73703          	ld	a4,1644(a4) # ffffffffc0211520 <max_swap_offset>
ffffffffc0203ebc:	04e7fb63          	bgeu	a5,a4,ffffffffc0203f12 <swapfs_write+0x68>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0203ec0:	0000d617          	auipc	a2,0xd
ffffffffc0203ec4:	69063603          	ld	a2,1680(a2) # ffffffffc0211550 <pages>
ffffffffc0203ec8:	8d91                	sub	a1,a1,a2
ffffffffc0203eca:	4035d613          	srai	a2,a1,0x3
ffffffffc0203ece:	00002597          	auipc	a1,0x2
ffffffffc0203ed2:	4725b583          	ld	a1,1138(a1) # ffffffffc0206340 <error_string+0x38>
ffffffffc0203ed6:	02b60633          	mul	a2,a2,a1
ffffffffc0203eda:	0037959b          	slliw	a1,a5,0x3
ffffffffc0203ede:	00002797          	auipc	a5,0x2
ffffffffc0203ee2:	46a7b783          	ld	a5,1130(a5) # ffffffffc0206348 <nbase>
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203ee6:	0000d717          	auipc	a4,0xd
ffffffffc0203eea:	66273703          	ld	a4,1634(a4) # ffffffffc0211548 <npage>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0203eee:	963e                	add	a2,a2,a5
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203ef0:	00c61793          	slli	a5,a2,0xc
ffffffffc0203ef4:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc0203ef6:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203ef8:	02e7f963          	bgeu	a5,a4,ffffffffc0203f2a <swapfs_write+0x80>
}
ffffffffc0203efc:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203efe:	0000d797          	auipc	a5,0xd
ffffffffc0203f02:	6627b783          	ld	a5,1634(a5) # ffffffffc0211560 <va_pa_offset>
ffffffffc0203f06:	46a1                	li	a3,8
ffffffffc0203f08:	963e                	add	a2,a2,a5
ffffffffc0203f0a:	4505                	li	a0,1
}
ffffffffc0203f0c:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203f0e:	cf4fc06f          	j	ffffffffc0200402 <ide_write_secs>
ffffffffc0203f12:	86aa                	mv	a3,a0
ffffffffc0203f14:	00002617          	auipc	a2,0x2
ffffffffc0203f18:	1c460613          	addi	a2,a2,452 # ffffffffc02060d8 <default_pmm_manager+0x648>
ffffffffc0203f1c:	45e5                	li	a1,25
ffffffffc0203f1e:	00002517          	auipc	a0,0x2
ffffffffc0203f22:	1a250513          	addi	a0,a0,418 # ffffffffc02060c0 <default_pmm_manager+0x630>
ffffffffc0203f26:	9dcfc0ef          	jal	ra,ffffffffc0200102 <__panic>
ffffffffc0203f2a:	86b2                	mv	a3,a2
ffffffffc0203f2c:	07700593          	li	a1,119
ffffffffc0203f30:	00002617          	auipc	a2,0x2
ffffffffc0203f34:	b9860613          	addi	a2,a2,-1128 # ffffffffc0205ac8 <default_pmm_manager+0x38>
ffffffffc0203f38:	00001517          	auipc	a0,0x1
ffffffffc0203f3c:	31850513          	addi	a0,a0,792 # ffffffffc0205250 <commands+0xb48>
ffffffffc0203f40:	9c2fc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203f44 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203f44:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0203f48:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0203f4a:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0203f4c:	cb81                	beqz	a5,ffffffffc0203f5c <strlen+0x18>
        cnt ++;
ffffffffc0203f4e:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0203f50:	00a707b3          	add	a5,a4,a0
ffffffffc0203f54:	0007c783          	lbu	a5,0(a5)
ffffffffc0203f58:	fbfd                	bnez	a5,ffffffffc0203f4e <strlen+0xa>
ffffffffc0203f5a:	8082                	ret
    }
    return cnt;
}
ffffffffc0203f5c:	8082                	ret

ffffffffc0203f5e <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0203f5e:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203f60:	e589                	bnez	a1,ffffffffc0203f6a <strnlen+0xc>
ffffffffc0203f62:	a811                	j	ffffffffc0203f76 <strnlen+0x18>
        cnt ++;
ffffffffc0203f64:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203f66:	00f58863          	beq	a1,a5,ffffffffc0203f76 <strnlen+0x18>
ffffffffc0203f6a:	00f50733          	add	a4,a0,a5
ffffffffc0203f6e:	00074703          	lbu	a4,0(a4)
ffffffffc0203f72:	fb6d                	bnez	a4,ffffffffc0203f64 <strnlen+0x6>
ffffffffc0203f74:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203f76:	852e                	mv	a0,a1
ffffffffc0203f78:	8082                	ret

ffffffffc0203f7a <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203f7a:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203f7c:	0005c703          	lbu	a4,0(a1)
ffffffffc0203f80:	0785                	addi	a5,a5,1
ffffffffc0203f82:	0585                	addi	a1,a1,1
ffffffffc0203f84:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203f88:	fb75                	bnez	a4,ffffffffc0203f7c <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203f8a:	8082                	ret

ffffffffc0203f8c <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203f8c:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203f90:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203f94:	cb89                	beqz	a5,ffffffffc0203fa6 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0203f96:	0505                	addi	a0,a0,1
ffffffffc0203f98:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203f9a:	fee789e3          	beq	a5,a4,ffffffffc0203f8c <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203f9e:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203fa2:	9d19                	subw	a0,a0,a4
ffffffffc0203fa4:	8082                	ret
ffffffffc0203fa6:	4501                	li	a0,0
ffffffffc0203fa8:	bfed                	j	ffffffffc0203fa2 <strcmp+0x16>

ffffffffc0203faa <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203faa:	00054783          	lbu	a5,0(a0)
ffffffffc0203fae:	c799                	beqz	a5,ffffffffc0203fbc <strchr+0x12>
        if (*s == c) {
ffffffffc0203fb0:	00f58763          	beq	a1,a5,ffffffffc0203fbe <strchr+0x14>
    while (*s != '\0') {
ffffffffc0203fb4:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0203fb8:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203fba:	fbfd                	bnez	a5,ffffffffc0203fb0 <strchr+0x6>
    }
    return NULL;
ffffffffc0203fbc:	4501                	li	a0,0
}
ffffffffc0203fbe:	8082                	ret

ffffffffc0203fc0 <memset>:
     * 通用 C 实现：
     * - 使用一个字符指针 p 遍历内存区域。
     * - 循环 n 次，每次设置内存中的一个字节为值 c。
     */
    char *p = s;             // 转换目标地址为字符指针，方便逐字节操作
    while (n-- > 0) {        // 每次操作一个字节，直到 n 减为 0
ffffffffc0203fc0:	ca01                	beqz	a2,ffffffffc0203fd0 <memset+0x10>
ffffffffc0203fc2:	962a                	add	a2,a2,a0
    char *p = s;             // 转换目标地址为字符指针，方便逐字节操作
ffffffffc0203fc4:	87aa                	mv	a5,a0
        *p++ = c;            // 设置当前字节为 c，并移动指针到下一个字节
ffffffffc0203fc6:	0785                	addi	a5,a5,1
ffffffffc0203fc8:	feb78fa3          	sb	a1,-1(a5)
    while (n-- > 0) {        // 每次操作一个字节，直到 n 减为 0
ffffffffc0203fcc:	fec79de3          	bne	a5,a2,ffffffffc0203fc6 <memset+0x6>
    }
    return s;                // 返回目标内存区域的起始指针
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203fd0:	8082                	ret

ffffffffc0203fd2 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203fd2:	ca19                	beqz	a2,ffffffffc0203fe8 <memcpy+0x16>
ffffffffc0203fd4:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203fd6:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203fd8:	0005c703          	lbu	a4,0(a1)
ffffffffc0203fdc:	0585                	addi	a1,a1,1
ffffffffc0203fde:	0785                	addi	a5,a5,1
ffffffffc0203fe0:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203fe4:	fec59ae3          	bne	a1,a2,ffffffffc0203fd8 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203fe8:	8082                	ret

ffffffffc0203fea <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203fea:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203fee:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203ff0:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203ff4:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203ff6:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203ffa:	f022                	sd	s0,32(sp)
ffffffffc0203ffc:	ec26                	sd	s1,24(sp)
ffffffffc0203ffe:	e84a                	sd	s2,16(sp)
ffffffffc0204000:	f406                	sd	ra,40(sp)
ffffffffc0204002:	e44e                	sd	s3,8(sp)
ffffffffc0204004:	84aa                	mv	s1,a0
ffffffffc0204006:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0204008:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020400c:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc020400e:	03067e63          	bgeu	a2,a6,ffffffffc020404a <printnum+0x60>
ffffffffc0204012:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0204014:	00805763          	blez	s0,ffffffffc0204022 <printnum+0x38>
ffffffffc0204018:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020401a:	85ca                	mv	a1,s2
ffffffffc020401c:	854e                	mv	a0,s3
ffffffffc020401e:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0204020:	fc65                	bnez	s0,ffffffffc0204018 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204022:	1a02                	slli	s4,s4,0x20
ffffffffc0204024:	00002797          	auipc	a5,0x2
ffffffffc0204028:	0d478793          	addi	a5,a5,212 # ffffffffc02060f8 <default_pmm_manager+0x668>
ffffffffc020402c:	020a5a13          	srli	s4,s4,0x20
ffffffffc0204030:	9a3e                	add	s4,s4,a5
}
ffffffffc0204032:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204034:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0204038:	70a2                	ld	ra,40(sp)
ffffffffc020403a:	69a2                	ld	s3,8(sp)
ffffffffc020403c:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020403e:	85ca                	mv	a1,s2
ffffffffc0204040:	87a6                	mv	a5,s1
}
ffffffffc0204042:	6942                	ld	s2,16(sp)
ffffffffc0204044:	64e2                	ld	s1,24(sp)
ffffffffc0204046:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204048:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020404a:	03065633          	divu	a2,a2,a6
ffffffffc020404e:	8722                	mv	a4,s0
ffffffffc0204050:	f9bff0ef          	jal	ra,ffffffffc0203fea <printnum>
ffffffffc0204054:	b7f9                	j	ffffffffc0204022 <printnum+0x38>

ffffffffc0204056 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0204056:	7119                	addi	sp,sp,-128
ffffffffc0204058:	f4a6                	sd	s1,104(sp)
ffffffffc020405a:	f0ca                	sd	s2,96(sp)
ffffffffc020405c:	ecce                	sd	s3,88(sp)
ffffffffc020405e:	e8d2                	sd	s4,80(sp)
ffffffffc0204060:	e4d6                	sd	s5,72(sp)
ffffffffc0204062:	e0da                	sd	s6,64(sp)
ffffffffc0204064:	fc5e                	sd	s7,56(sp)
ffffffffc0204066:	f06a                	sd	s10,32(sp)
ffffffffc0204068:	fc86                	sd	ra,120(sp)
ffffffffc020406a:	f8a2                	sd	s0,112(sp)
ffffffffc020406c:	f862                	sd	s8,48(sp)
ffffffffc020406e:	f466                	sd	s9,40(sp)
ffffffffc0204070:	ec6e                	sd	s11,24(sp)
ffffffffc0204072:	892a                	mv	s2,a0
ffffffffc0204074:	84ae                	mv	s1,a1
ffffffffc0204076:	8d32                	mv	s10,a2
ffffffffc0204078:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020407a:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020407e:	5b7d                	li	s6,-1
ffffffffc0204080:	00002a97          	auipc	s5,0x2
ffffffffc0204084:	0aca8a93          	addi	s5,s5,172 # ffffffffc020612c <default_pmm_manager+0x69c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204088:	00002b97          	auipc	s7,0x2
ffffffffc020408c:	280b8b93          	addi	s7,s7,640 # ffffffffc0206308 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204090:	000d4503          	lbu	a0,0(s10) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc0204094:	001d0413          	addi	s0,s10,1
ffffffffc0204098:	01350a63          	beq	a0,s3,ffffffffc02040ac <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc020409c:	c121                	beqz	a0,ffffffffc02040dc <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc020409e:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02040a0:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02040a2:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02040a4:	fff44503          	lbu	a0,-1(s0)
ffffffffc02040a8:	ff351ae3          	bne	a0,s3,ffffffffc020409c <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02040ac:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02040b0:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02040b4:	4c81                	li	s9,0
ffffffffc02040b6:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02040b8:	5c7d                	li	s8,-1
ffffffffc02040ba:	5dfd                	li	s11,-1
ffffffffc02040bc:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02040c0:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02040c2:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02040c6:	0ff5f593          	zext.b	a1,a1
ffffffffc02040ca:	00140d13          	addi	s10,s0,1
ffffffffc02040ce:	04b56263          	bltu	a0,a1,ffffffffc0204112 <vprintfmt+0xbc>
ffffffffc02040d2:	058a                	slli	a1,a1,0x2
ffffffffc02040d4:	95d6                	add	a1,a1,s5
ffffffffc02040d6:	4194                	lw	a3,0(a1)
ffffffffc02040d8:	96d6                	add	a3,a3,s5
ffffffffc02040da:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02040dc:	70e6                	ld	ra,120(sp)
ffffffffc02040de:	7446                	ld	s0,112(sp)
ffffffffc02040e0:	74a6                	ld	s1,104(sp)
ffffffffc02040e2:	7906                	ld	s2,96(sp)
ffffffffc02040e4:	69e6                	ld	s3,88(sp)
ffffffffc02040e6:	6a46                	ld	s4,80(sp)
ffffffffc02040e8:	6aa6                	ld	s5,72(sp)
ffffffffc02040ea:	6b06                	ld	s6,64(sp)
ffffffffc02040ec:	7be2                	ld	s7,56(sp)
ffffffffc02040ee:	7c42                	ld	s8,48(sp)
ffffffffc02040f0:	7ca2                	ld	s9,40(sp)
ffffffffc02040f2:	7d02                	ld	s10,32(sp)
ffffffffc02040f4:	6de2                	ld	s11,24(sp)
ffffffffc02040f6:	6109                	addi	sp,sp,128
ffffffffc02040f8:	8082                	ret
            padc = '0';
ffffffffc02040fa:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02040fc:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204100:	846a                	mv	s0,s10
ffffffffc0204102:	00140d13          	addi	s10,s0,1
ffffffffc0204106:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020410a:	0ff5f593          	zext.b	a1,a1
ffffffffc020410e:	fcb572e3          	bgeu	a0,a1,ffffffffc02040d2 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0204112:	85a6                	mv	a1,s1
ffffffffc0204114:	02500513          	li	a0,37
ffffffffc0204118:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020411a:	fff44783          	lbu	a5,-1(s0)
ffffffffc020411e:	8d22                	mv	s10,s0
ffffffffc0204120:	f73788e3          	beq	a5,s3,ffffffffc0204090 <vprintfmt+0x3a>
ffffffffc0204124:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0204128:	1d7d                	addi	s10,s10,-1
ffffffffc020412a:	ff379de3          	bne	a5,s3,ffffffffc0204124 <vprintfmt+0xce>
ffffffffc020412e:	b78d                	j	ffffffffc0204090 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0204130:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0204134:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204138:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020413a:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020413e:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0204142:	02d86463          	bltu	a6,a3,ffffffffc020416a <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0204146:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020414a:	002c169b          	slliw	a3,s8,0x2
ffffffffc020414e:	0186873b          	addw	a4,a3,s8
ffffffffc0204152:	0017171b          	slliw	a4,a4,0x1
ffffffffc0204156:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0204158:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc020415c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020415e:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0204162:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0204166:	fed870e3          	bgeu	a6,a3,ffffffffc0204146 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc020416a:	f40ddce3          	bgez	s11,ffffffffc02040c2 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc020416e:	8de2                	mv	s11,s8
ffffffffc0204170:	5c7d                	li	s8,-1
ffffffffc0204172:	bf81                	j	ffffffffc02040c2 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0204174:	fffdc693          	not	a3,s11
ffffffffc0204178:	96fd                	srai	a3,a3,0x3f
ffffffffc020417a:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020417e:	00144603          	lbu	a2,1(s0)
ffffffffc0204182:	2d81                	sext.w	s11,s11
ffffffffc0204184:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204186:	bf35                	j	ffffffffc02040c2 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0204188:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020418c:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0204190:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204192:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0204194:	bfd9                	j	ffffffffc020416a <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0204196:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204198:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020419c:	01174463          	blt	a4,a7,ffffffffc02041a4 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02041a0:	1a088e63          	beqz	a7,ffffffffc020435c <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02041a4:	000a3603          	ld	a2,0(s4)
ffffffffc02041a8:	46c1                	li	a3,16
ffffffffc02041aa:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02041ac:	2781                	sext.w	a5,a5
ffffffffc02041ae:	876e                	mv	a4,s11
ffffffffc02041b0:	85a6                	mv	a1,s1
ffffffffc02041b2:	854a                	mv	a0,s2
ffffffffc02041b4:	e37ff0ef          	jal	ra,ffffffffc0203fea <printnum>
            break;
ffffffffc02041b8:	bde1                	j	ffffffffc0204090 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02041ba:	000a2503          	lw	a0,0(s4)
ffffffffc02041be:	85a6                	mv	a1,s1
ffffffffc02041c0:	0a21                	addi	s4,s4,8
ffffffffc02041c2:	9902                	jalr	s2
            break;
ffffffffc02041c4:	b5f1                	j	ffffffffc0204090 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02041c6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02041c8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02041cc:	01174463          	blt	a4,a7,ffffffffc02041d4 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02041d0:	18088163          	beqz	a7,ffffffffc0204352 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02041d4:	000a3603          	ld	a2,0(s4)
ffffffffc02041d8:	46a9                	li	a3,10
ffffffffc02041da:	8a2e                	mv	s4,a1
ffffffffc02041dc:	bfc1                	j	ffffffffc02041ac <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02041de:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02041e2:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02041e4:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02041e6:	bdf1                	j	ffffffffc02040c2 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02041e8:	85a6                	mv	a1,s1
ffffffffc02041ea:	02500513          	li	a0,37
ffffffffc02041ee:	9902                	jalr	s2
            break;
ffffffffc02041f0:	b545                	j	ffffffffc0204090 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02041f2:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02041f6:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02041f8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02041fa:	b5e1                	j	ffffffffc02040c2 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02041fc:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02041fe:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0204202:	01174463          	blt	a4,a7,ffffffffc020420a <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0204206:	14088163          	beqz	a7,ffffffffc0204348 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc020420a:	000a3603          	ld	a2,0(s4)
ffffffffc020420e:	46a1                	li	a3,8
ffffffffc0204210:	8a2e                	mv	s4,a1
ffffffffc0204212:	bf69                	j	ffffffffc02041ac <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0204214:	03000513          	li	a0,48
ffffffffc0204218:	85a6                	mv	a1,s1
ffffffffc020421a:	e03e                	sd	a5,0(sp)
ffffffffc020421c:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc020421e:	85a6                	mv	a1,s1
ffffffffc0204220:	07800513          	li	a0,120
ffffffffc0204224:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204226:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0204228:	6782                	ld	a5,0(sp)
ffffffffc020422a:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020422c:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0204230:	bfb5                	j	ffffffffc02041ac <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204232:	000a3403          	ld	s0,0(s4)
ffffffffc0204236:	008a0713          	addi	a4,s4,8
ffffffffc020423a:	e03a                	sd	a4,0(sp)
ffffffffc020423c:	14040263          	beqz	s0,ffffffffc0204380 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0204240:	0fb05763          	blez	s11,ffffffffc020432e <vprintfmt+0x2d8>
ffffffffc0204244:	02d00693          	li	a3,45
ffffffffc0204248:	0cd79163          	bne	a5,a3,ffffffffc020430a <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020424c:	00044783          	lbu	a5,0(s0)
ffffffffc0204250:	0007851b          	sext.w	a0,a5
ffffffffc0204254:	cf85                	beqz	a5,ffffffffc020428c <vprintfmt+0x236>
ffffffffc0204256:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020425a:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020425e:	000c4563          	bltz	s8,ffffffffc0204268 <vprintfmt+0x212>
ffffffffc0204262:	3c7d                	addiw	s8,s8,-1
ffffffffc0204264:	036c0263          	beq	s8,s6,ffffffffc0204288 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0204268:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020426a:	0e0c8e63          	beqz	s9,ffffffffc0204366 <vprintfmt+0x310>
ffffffffc020426e:	3781                	addiw	a5,a5,-32
ffffffffc0204270:	0ef47b63          	bgeu	s0,a5,ffffffffc0204366 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0204274:	03f00513          	li	a0,63
ffffffffc0204278:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020427a:	000a4783          	lbu	a5,0(s4)
ffffffffc020427e:	3dfd                	addiw	s11,s11,-1
ffffffffc0204280:	0a05                	addi	s4,s4,1
ffffffffc0204282:	0007851b          	sext.w	a0,a5
ffffffffc0204286:	ffe1                	bnez	a5,ffffffffc020425e <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0204288:	01b05963          	blez	s11,ffffffffc020429a <vprintfmt+0x244>
ffffffffc020428c:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020428e:	85a6                	mv	a1,s1
ffffffffc0204290:	02000513          	li	a0,32
ffffffffc0204294:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0204296:	fe0d9be3          	bnez	s11,ffffffffc020428c <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020429a:	6a02                	ld	s4,0(sp)
ffffffffc020429c:	bbd5                	j	ffffffffc0204090 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020429e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02042a0:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02042a4:	01174463          	blt	a4,a7,ffffffffc02042ac <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02042a8:	08088d63          	beqz	a7,ffffffffc0204342 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02042ac:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02042b0:	0a044d63          	bltz	s0,ffffffffc020436a <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02042b4:	8622                	mv	a2,s0
ffffffffc02042b6:	8a66                	mv	s4,s9
ffffffffc02042b8:	46a9                	li	a3,10
ffffffffc02042ba:	bdcd                	j	ffffffffc02041ac <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02042bc:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02042c0:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02042c2:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02042c4:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02042c8:	8fb5                	xor	a5,a5,a3
ffffffffc02042ca:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02042ce:	02d74163          	blt	a4,a3,ffffffffc02042f0 <vprintfmt+0x29a>
ffffffffc02042d2:	00369793          	slli	a5,a3,0x3
ffffffffc02042d6:	97de                	add	a5,a5,s7
ffffffffc02042d8:	639c                	ld	a5,0(a5)
ffffffffc02042da:	cb99                	beqz	a5,ffffffffc02042f0 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02042dc:	86be                	mv	a3,a5
ffffffffc02042de:	00002617          	auipc	a2,0x2
ffffffffc02042e2:	e4a60613          	addi	a2,a2,-438 # ffffffffc0206128 <default_pmm_manager+0x698>
ffffffffc02042e6:	85a6                	mv	a1,s1
ffffffffc02042e8:	854a                	mv	a0,s2
ffffffffc02042ea:	0ce000ef          	jal	ra,ffffffffc02043b8 <printfmt>
ffffffffc02042ee:	b34d                	j	ffffffffc0204090 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02042f0:	00002617          	auipc	a2,0x2
ffffffffc02042f4:	e2860613          	addi	a2,a2,-472 # ffffffffc0206118 <default_pmm_manager+0x688>
ffffffffc02042f8:	85a6                	mv	a1,s1
ffffffffc02042fa:	854a                	mv	a0,s2
ffffffffc02042fc:	0bc000ef          	jal	ra,ffffffffc02043b8 <printfmt>
ffffffffc0204300:	bb41                	j	ffffffffc0204090 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0204302:	00002417          	auipc	s0,0x2
ffffffffc0204306:	e0e40413          	addi	s0,s0,-498 # ffffffffc0206110 <default_pmm_manager+0x680>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020430a:	85e2                	mv	a1,s8
ffffffffc020430c:	8522                	mv	a0,s0
ffffffffc020430e:	e43e                	sd	a5,8(sp)
ffffffffc0204310:	c4fff0ef          	jal	ra,ffffffffc0203f5e <strnlen>
ffffffffc0204314:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0204318:	01b05b63          	blez	s11,ffffffffc020432e <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc020431c:	67a2                	ld	a5,8(sp)
ffffffffc020431e:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204322:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0204324:	85a6                	mv	a1,s1
ffffffffc0204326:	8552                	mv	a0,s4
ffffffffc0204328:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020432a:	fe0d9ce3          	bnez	s11,ffffffffc0204322 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020432e:	00044783          	lbu	a5,0(s0)
ffffffffc0204332:	00140a13          	addi	s4,s0,1
ffffffffc0204336:	0007851b          	sext.w	a0,a5
ffffffffc020433a:	d3a5                	beqz	a5,ffffffffc020429a <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020433c:	05e00413          	li	s0,94
ffffffffc0204340:	bf39                	j	ffffffffc020425e <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0204342:	000a2403          	lw	s0,0(s4)
ffffffffc0204346:	b7ad                	j	ffffffffc02042b0 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0204348:	000a6603          	lwu	a2,0(s4)
ffffffffc020434c:	46a1                	li	a3,8
ffffffffc020434e:	8a2e                	mv	s4,a1
ffffffffc0204350:	bdb1                	j	ffffffffc02041ac <vprintfmt+0x156>
ffffffffc0204352:	000a6603          	lwu	a2,0(s4)
ffffffffc0204356:	46a9                	li	a3,10
ffffffffc0204358:	8a2e                	mv	s4,a1
ffffffffc020435a:	bd89                	j	ffffffffc02041ac <vprintfmt+0x156>
ffffffffc020435c:	000a6603          	lwu	a2,0(s4)
ffffffffc0204360:	46c1                	li	a3,16
ffffffffc0204362:	8a2e                	mv	s4,a1
ffffffffc0204364:	b5a1                	j	ffffffffc02041ac <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0204366:	9902                	jalr	s2
ffffffffc0204368:	bf09                	j	ffffffffc020427a <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc020436a:	85a6                	mv	a1,s1
ffffffffc020436c:	02d00513          	li	a0,45
ffffffffc0204370:	e03e                	sd	a5,0(sp)
ffffffffc0204372:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0204374:	6782                	ld	a5,0(sp)
ffffffffc0204376:	8a66                	mv	s4,s9
ffffffffc0204378:	40800633          	neg	a2,s0
ffffffffc020437c:	46a9                	li	a3,10
ffffffffc020437e:	b53d                	j	ffffffffc02041ac <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0204380:	03b05163          	blez	s11,ffffffffc02043a2 <vprintfmt+0x34c>
ffffffffc0204384:	02d00693          	li	a3,45
ffffffffc0204388:	f6d79de3          	bne	a5,a3,ffffffffc0204302 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc020438c:	00002417          	auipc	s0,0x2
ffffffffc0204390:	d8440413          	addi	s0,s0,-636 # ffffffffc0206110 <default_pmm_manager+0x680>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204394:	02800793          	li	a5,40
ffffffffc0204398:	02800513          	li	a0,40
ffffffffc020439c:	00140a13          	addi	s4,s0,1
ffffffffc02043a0:	bd6d                	j	ffffffffc020425a <vprintfmt+0x204>
ffffffffc02043a2:	00002a17          	auipc	s4,0x2
ffffffffc02043a6:	d6fa0a13          	addi	s4,s4,-657 # ffffffffc0206111 <default_pmm_manager+0x681>
ffffffffc02043aa:	02800513          	li	a0,40
ffffffffc02043ae:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02043b2:	05e00413          	li	s0,94
ffffffffc02043b6:	b565                	j	ffffffffc020425e <vprintfmt+0x208>

ffffffffc02043b8 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02043b8:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02043ba:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02043be:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02043c0:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02043c2:	ec06                	sd	ra,24(sp)
ffffffffc02043c4:	f83a                	sd	a4,48(sp)
ffffffffc02043c6:	fc3e                	sd	a5,56(sp)
ffffffffc02043c8:	e0c2                	sd	a6,64(sp)
ffffffffc02043ca:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02043cc:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02043ce:	c89ff0ef          	jal	ra,ffffffffc0204056 <vprintfmt>
}
ffffffffc02043d2:	60e2                	ld	ra,24(sp)
ffffffffc02043d4:	6161                	addi	sp,sp,80
ffffffffc02043d6:	8082                	ret

ffffffffc02043d8 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02043d8:	715d                	addi	sp,sp,-80
ffffffffc02043da:	e486                	sd	ra,72(sp)
ffffffffc02043dc:	e0a6                	sd	s1,64(sp)
ffffffffc02043de:	fc4a                	sd	s2,56(sp)
ffffffffc02043e0:	f84e                	sd	s3,48(sp)
ffffffffc02043e2:	f452                	sd	s4,40(sp)
ffffffffc02043e4:	f056                	sd	s5,32(sp)
ffffffffc02043e6:	ec5a                	sd	s6,24(sp)
ffffffffc02043e8:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02043ea:	c901                	beqz	a0,ffffffffc02043fa <readline+0x22>
ffffffffc02043ec:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02043ee:	00002517          	auipc	a0,0x2
ffffffffc02043f2:	d3a50513          	addi	a0,a0,-710 # ffffffffc0206128 <default_pmm_manager+0x698>
ffffffffc02043f6:	cc5fb0ef          	jal	ra,ffffffffc02000ba <cprintf>
readline(const char *prompt) {
ffffffffc02043fa:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02043fc:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02043fe:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0204400:	4aa9                	li	s5,10
ffffffffc0204402:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0204404:	0000db97          	auipc	s7,0xd
ffffffffc0204408:	cf4b8b93          	addi	s7,s7,-780 # ffffffffc02110f8 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020440c:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0204410:	ce3fb0ef          	jal	ra,ffffffffc02000f2 <getchar>
        if (c < 0) {
ffffffffc0204414:	00054a63          	bltz	a0,ffffffffc0204428 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204418:	00a95a63          	bge	s2,a0,ffffffffc020442c <readline+0x54>
ffffffffc020441c:	029a5263          	bge	s4,s1,ffffffffc0204440 <readline+0x68>
        c = getchar();
ffffffffc0204420:	cd3fb0ef          	jal	ra,ffffffffc02000f2 <getchar>
        if (c < 0) {
ffffffffc0204424:	fe055ae3          	bgez	a0,ffffffffc0204418 <readline+0x40>
            return NULL;
ffffffffc0204428:	4501                	li	a0,0
ffffffffc020442a:	a091                	j	ffffffffc020446e <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc020442c:	03351463          	bne	a0,s3,ffffffffc0204454 <readline+0x7c>
ffffffffc0204430:	e8a9                	bnez	s1,ffffffffc0204482 <readline+0xaa>
        c = getchar();
ffffffffc0204432:	cc1fb0ef          	jal	ra,ffffffffc02000f2 <getchar>
        if (c < 0) {
ffffffffc0204436:	fe0549e3          	bltz	a0,ffffffffc0204428 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020443a:	fea959e3          	bge	s2,a0,ffffffffc020442c <readline+0x54>
ffffffffc020443e:	4481                	li	s1,0
            cputchar(c);
ffffffffc0204440:	e42a                	sd	a0,8(sp)
ffffffffc0204442:	caffb0ef          	jal	ra,ffffffffc02000f0 <cputchar>
            buf[i ++] = c;
ffffffffc0204446:	6522                	ld	a0,8(sp)
ffffffffc0204448:	009b87b3          	add	a5,s7,s1
ffffffffc020444c:	2485                	addiw	s1,s1,1
ffffffffc020444e:	00a78023          	sb	a0,0(a5)
ffffffffc0204452:	bf7d                	j	ffffffffc0204410 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0204454:	01550463          	beq	a0,s5,ffffffffc020445c <readline+0x84>
ffffffffc0204458:	fb651ce3          	bne	a0,s6,ffffffffc0204410 <readline+0x38>
            cputchar(c);
ffffffffc020445c:	c95fb0ef          	jal	ra,ffffffffc02000f0 <cputchar>
            buf[i] = '\0';
ffffffffc0204460:	0000d517          	auipc	a0,0xd
ffffffffc0204464:	c9850513          	addi	a0,a0,-872 # ffffffffc02110f8 <buf>
ffffffffc0204468:	94aa                	add	s1,s1,a0
ffffffffc020446a:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc020446e:	60a6                	ld	ra,72(sp)
ffffffffc0204470:	6486                	ld	s1,64(sp)
ffffffffc0204472:	7962                	ld	s2,56(sp)
ffffffffc0204474:	79c2                	ld	s3,48(sp)
ffffffffc0204476:	7a22                	ld	s4,40(sp)
ffffffffc0204478:	7a82                	ld	s5,32(sp)
ffffffffc020447a:	6b62                	ld	s6,24(sp)
ffffffffc020447c:	6bc2                	ld	s7,16(sp)
ffffffffc020447e:	6161                	addi	sp,sp,80
ffffffffc0204480:	8082                	ret
            cputchar(c);
ffffffffc0204482:	4521                	li	a0,8
ffffffffc0204484:	c6dfb0ef          	jal	ra,ffffffffc02000f0 <cputchar>
            i --;
ffffffffc0204488:	34fd                	addiw	s1,s1,-1
ffffffffc020448a:	b759                	j	ffffffffc0204410 <readline+0x38>

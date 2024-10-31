
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
ffffffffc020003e:	53660613          	addi	a2,a2,1334 # ffffffffc0211570 <end>
kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	68f030ef          	jal	ra,ffffffffc0203ed8 <memset>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020004e:	00004597          	auipc	a1,0x4
ffffffffc0200052:	35a58593          	addi	a1,a1,858 # ffffffffc02043a8 <etext+0x4>
ffffffffc0200056:	00004517          	auipc	a0,0x4
ffffffffc020005a:	37250513          	addi	a0,a0,882 # ffffffffc02043c8 <etext+0x24>
ffffffffc020005e:	05c000ef          	jal	ra,ffffffffc02000ba <cprintf>

    print_kerninfo();
ffffffffc0200062:	0fc000ef          	jal	ra,ffffffffc020015e <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc0200066:	659020ef          	jal	ra,ffffffffc0202ebe <pmm_init>

    idt_init();                 // init interrupt descriptor table
ffffffffc020006a:	4fa000ef          	jal	ra,ffffffffc0200564 <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc020006e:	423000ef          	jal	ra,ffffffffc0200c90 <vmm_init>

    ide_init();                 // init ide devices
ffffffffc0200072:	35e000ef          	jal	ra,ffffffffc02003d0 <ide_init>
    swap_init();                // init swap
ffffffffc0200076:	2c0010ef          	jal	ra,ffffffffc0201336 <swap_init>

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
ffffffffc02000ae:	6c1030ef          	jal	ra,ffffffffc0203f6e <vprintfmt>
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
ffffffffc02000e4:	68b030ef          	jal	ra,ffffffffc0203f6e <vprintfmt>
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
ffffffffc0200134:	2a050513          	addi	a0,a0,672 # ffffffffc02043d0 <etext+0x2c>
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
ffffffffc020014a:	b8250513          	addi	a0,a0,-1150 # ffffffffc0205cc8 <default_pmm_manager+0x4d0>
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
ffffffffc0200164:	29050513          	addi	a0,a0,656 # ffffffffc02043f0 <etext+0x4c>
void print_kerninfo(void) {
ffffffffc0200168:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020016a:	f51ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc020016e:	00000597          	auipc	a1,0x0
ffffffffc0200172:	ec458593          	addi	a1,a1,-316 # ffffffffc0200032 <kern_init>
ffffffffc0200176:	00004517          	auipc	a0,0x4
ffffffffc020017a:	29a50513          	addi	a0,a0,666 # ffffffffc0204410 <etext+0x6c>
ffffffffc020017e:	f3dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200182:	00004597          	auipc	a1,0x4
ffffffffc0200186:	22258593          	addi	a1,a1,546 # ffffffffc02043a4 <etext>
ffffffffc020018a:	00004517          	auipc	a0,0x4
ffffffffc020018e:	2a650513          	addi	a0,a0,678 # ffffffffc0204430 <etext+0x8c>
ffffffffc0200192:	f29ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc0200196:	0000a597          	auipc	a1,0xa
ffffffffc020019a:	eaa58593          	addi	a1,a1,-342 # ffffffffc020a040 <ide>
ffffffffc020019e:	00004517          	auipc	a0,0x4
ffffffffc02001a2:	2b250513          	addi	a0,a0,690 # ffffffffc0204450 <etext+0xac>
ffffffffc02001a6:	f15ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc02001aa:	00011597          	auipc	a1,0x11
ffffffffc02001ae:	3c658593          	addi	a1,a1,966 # ffffffffc0211570 <end>
ffffffffc02001b2:	00004517          	auipc	a0,0x4
ffffffffc02001b6:	2be50513          	addi	a0,a0,702 # ffffffffc0204470 <etext+0xcc>
ffffffffc02001ba:	f01ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001be:	00011597          	auipc	a1,0x11
ffffffffc02001c2:	7b158593          	addi	a1,a1,1969 # ffffffffc021196f <end+0x3ff>
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
ffffffffc02001e4:	2b050513          	addi	a0,a0,688 # ffffffffc0204490 <etext+0xec>
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
ffffffffc02001f2:	2d260613          	addi	a2,a2,722 # ffffffffc02044c0 <etext+0x11c>
ffffffffc02001f6:	04e00593          	li	a1,78
ffffffffc02001fa:	00004517          	auipc	a0,0x4
ffffffffc02001fe:	2de50513          	addi	a0,a0,734 # ffffffffc02044d8 <etext+0x134>
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
ffffffffc020020e:	2e660613          	addi	a2,a2,742 # ffffffffc02044f0 <etext+0x14c>
ffffffffc0200212:	00004597          	auipc	a1,0x4
ffffffffc0200216:	2fe58593          	addi	a1,a1,766 # ffffffffc0204510 <etext+0x16c>
ffffffffc020021a:	00004517          	auipc	a0,0x4
ffffffffc020021e:	2fe50513          	addi	a0,a0,766 # ffffffffc0204518 <etext+0x174>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200222:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200224:	e97ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200228:	00004617          	auipc	a2,0x4
ffffffffc020022c:	30060613          	addi	a2,a2,768 # ffffffffc0204528 <etext+0x184>
ffffffffc0200230:	00004597          	auipc	a1,0x4
ffffffffc0200234:	32058593          	addi	a1,a1,800 # ffffffffc0204550 <etext+0x1ac>
ffffffffc0200238:	00004517          	auipc	a0,0x4
ffffffffc020023c:	2e050513          	addi	a0,a0,736 # ffffffffc0204518 <etext+0x174>
ffffffffc0200240:	e7bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc0200244:	00004617          	auipc	a2,0x4
ffffffffc0200248:	31c60613          	addi	a2,a2,796 # ffffffffc0204560 <etext+0x1bc>
ffffffffc020024c:	00004597          	auipc	a1,0x4
ffffffffc0200250:	33458593          	addi	a1,a1,820 # ffffffffc0204580 <etext+0x1dc>
ffffffffc0200254:	00004517          	auipc	a0,0x4
ffffffffc0200258:	2c450513          	addi	a0,a0,708 # ffffffffc0204518 <etext+0x174>
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
ffffffffc0200292:	30250513          	addi	a0,a0,770 # ffffffffc0204590 <etext+0x1ec>
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
ffffffffc02002b4:	30850513          	addi	a0,a0,776 # ffffffffc02045b8 <etext+0x214>
ffffffffc02002b8:	e03ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    if (tf != NULL) {
ffffffffc02002bc:	000b8563          	beqz	s7,ffffffffc02002c6 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002c0:	855e                	mv	a0,s7
ffffffffc02002c2:	48c000ef          	jal	ra,ffffffffc020074e <print_trapframe>
ffffffffc02002c6:	00004c17          	auipc	s8,0x4
ffffffffc02002ca:	35ac0c13          	addi	s8,s8,858 # ffffffffc0204620 <commands>
        if ((buf = readline("")) != NULL) {
ffffffffc02002ce:	00005917          	auipc	s2,0x5
ffffffffc02002d2:	0ca90913          	addi	s2,s2,202 # ffffffffc0205398 <commands+0xd78>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002d6:	00004497          	auipc	s1,0x4
ffffffffc02002da:	30a48493          	addi	s1,s1,778 # ffffffffc02045e0 <etext+0x23c>
        if (argc == MAXARGS - 1) {
ffffffffc02002de:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002e0:	00004b17          	auipc	s6,0x4
ffffffffc02002e4:	308b0b13          	addi	s6,s6,776 # ffffffffc02045e8 <etext+0x244>
        argv[argc ++] = buf;
ffffffffc02002e8:	00004a17          	auipc	s4,0x4
ffffffffc02002ec:	228a0a13          	addi	s4,s4,552 # ffffffffc0204510 <etext+0x16c>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f0:	4a8d                	li	s5,3
        if ((buf = readline("")) != NULL) {
ffffffffc02002f2:	854a                	mv	a0,s2
ffffffffc02002f4:	7fd030ef          	jal	ra,ffffffffc02042f0 <readline>
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
ffffffffc020030e:	316d0d13          	addi	s10,s10,790 # ffffffffc0204620 <commands>
        argv[argc ++] = buf;
ffffffffc0200312:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200314:	4401                	li	s0,0
ffffffffc0200316:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200318:	38d030ef          	jal	ra,ffffffffc0203ea4 <strcmp>
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
ffffffffc020032c:	379030ef          	jal	ra,ffffffffc0203ea4 <strcmp>
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
ffffffffc020036a:	359030ef          	jal	ra,ffffffffc0203ec2 <strchr>
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
ffffffffc02003a8:	31b030ef          	jal	ra,ffffffffc0203ec2 <strchr>
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
ffffffffc02003c6:	24650513          	addi	a0,a0,582 # ffffffffc0204608 <etext+0x264>
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
ffffffffc02003f6:	2f5030ef          	jal	ra,ffffffffc0203eea <memcpy>
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
ffffffffc020041a:	2d1030ef          	jal	ra,ffffffffc0203eea <memcpy>
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
ffffffffc0200450:	21c50513          	addi	a0,a0,540 # ffffffffc0204668 <commands+0x48>
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
ffffffffc0200528:	16450513          	addi	a0,a0,356 # ffffffffc0204688 <commands+0x68>
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
ffffffffc0200548:	5210006f          	j	ffffffffc0201268 <do_pgfault>
    panic("unhandled page fault.\n"); // 如果没有有效的内存管理结构，触发panic
ffffffffc020054c:	00004617          	auipc	a2,0x4
ffffffffc0200550:	15c60613          	addi	a2,a2,348 # ffffffffc02046a8 <commands+0x88>
ffffffffc0200554:	07a00593          	li	a1,122
ffffffffc0200558:	00004517          	auipc	a0,0x4
ffffffffc020055c:	16850513          	addi	a0,a0,360 # ffffffffc02046c0 <commands+0xa0>
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
ffffffffc020058e:	14e50513          	addi	a0,a0,334 # ffffffffc02046d8 <commands+0xb8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200592:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200594:	b27ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200598:	640c                	ld	a1,8(s0)
ffffffffc020059a:	00004517          	auipc	a0,0x4
ffffffffc020059e:	15650513          	addi	a0,a0,342 # ffffffffc02046f0 <commands+0xd0>
ffffffffc02005a2:	b19ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02005a6:	680c                	ld	a1,16(s0)
ffffffffc02005a8:	00004517          	auipc	a0,0x4
ffffffffc02005ac:	16050513          	addi	a0,a0,352 # ffffffffc0204708 <commands+0xe8>
ffffffffc02005b0:	b0bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02005b4:	6c0c                	ld	a1,24(s0)
ffffffffc02005b6:	00004517          	auipc	a0,0x4
ffffffffc02005ba:	16a50513          	addi	a0,a0,362 # ffffffffc0204720 <commands+0x100>
ffffffffc02005be:	afdff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02005c2:	700c                	ld	a1,32(s0)
ffffffffc02005c4:	00004517          	auipc	a0,0x4
ffffffffc02005c8:	17450513          	addi	a0,a0,372 # ffffffffc0204738 <commands+0x118>
ffffffffc02005cc:	aefff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02005d0:	740c                	ld	a1,40(s0)
ffffffffc02005d2:	00004517          	auipc	a0,0x4
ffffffffc02005d6:	17e50513          	addi	a0,a0,382 # ffffffffc0204750 <commands+0x130>
ffffffffc02005da:	ae1ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02005de:	780c                	ld	a1,48(s0)
ffffffffc02005e0:	00004517          	auipc	a0,0x4
ffffffffc02005e4:	18850513          	addi	a0,a0,392 # ffffffffc0204768 <commands+0x148>
ffffffffc02005e8:	ad3ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02005ec:	7c0c                	ld	a1,56(s0)
ffffffffc02005ee:	00004517          	auipc	a0,0x4
ffffffffc02005f2:	19250513          	addi	a0,a0,402 # ffffffffc0204780 <commands+0x160>
ffffffffc02005f6:	ac5ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02005fa:	602c                	ld	a1,64(s0)
ffffffffc02005fc:	00004517          	auipc	a0,0x4
ffffffffc0200600:	19c50513          	addi	a0,a0,412 # ffffffffc0204798 <commands+0x178>
ffffffffc0200604:	ab7ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200608:	642c                	ld	a1,72(s0)
ffffffffc020060a:	00004517          	auipc	a0,0x4
ffffffffc020060e:	1a650513          	addi	a0,a0,422 # ffffffffc02047b0 <commands+0x190>
ffffffffc0200612:	aa9ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200616:	682c                	ld	a1,80(s0)
ffffffffc0200618:	00004517          	auipc	a0,0x4
ffffffffc020061c:	1b050513          	addi	a0,a0,432 # ffffffffc02047c8 <commands+0x1a8>
ffffffffc0200620:	a9bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200624:	6c2c                	ld	a1,88(s0)
ffffffffc0200626:	00004517          	auipc	a0,0x4
ffffffffc020062a:	1ba50513          	addi	a0,a0,442 # ffffffffc02047e0 <commands+0x1c0>
ffffffffc020062e:	a8dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200632:	702c                	ld	a1,96(s0)
ffffffffc0200634:	00004517          	auipc	a0,0x4
ffffffffc0200638:	1c450513          	addi	a0,a0,452 # ffffffffc02047f8 <commands+0x1d8>
ffffffffc020063c:	a7fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200640:	742c                	ld	a1,104(s0)
ffffffffc0200642:	00004517          	auipc	a0,0x4
ffffffffc0200646:	1ce50513          	addi	a0,a0,462 # ffffffffc0204810 <commands+0x1f0>
ffffffffc020064a:	a71ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc020064e:	782c                	ld	a1,112(s0)
ffffffffc0200650:	00004517          	auipc	a0,0x4
ffffffffc0200654:	1d850513          	addi	a0,a0,472 # ffffffffc0204828 <commands+0x208>
ffffffffc0200658:	a63ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020065c:	7c2c                	ld	a1,120(s0)
ffffffffc020065e:	00004517          	auipc	a0,0x4
ffffffffc0200662:	1e250513          	addi	a0,a0,482 # ffffffffc0204840 <commands+0x220>
ffffffffc0200666:	a55ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020066a:	604c                	ld	a1,128(s0)
ffffffffc020066c:	00004517          	auipc	a0,0x4
ffffffffc0200670:	1ec50513          	addi	a0,a0,492 # ffffffffc0204858 <commands+0x238>
ffffffffc0200674:	a47ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200678:	644c                	ld	a1,136(s0)
ffffffffc020067a:	00004517          	auipc	a0,0x4
ffffffffc020067e:	1f650513          	addi	a0,a0,502 # ffffffffc0204870 <commands+0x250>
ffffffffc0200682:	a39ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200686:	684c                	ld	a1,144(s0)
ffffffffc0200688:	00004517          	auipc	a0,0x4
ffffffffc020068c:	20050513          	addi	a0,a0,512 # ffffffffc0204888 <commands+0x268>
ffffffffc0200690:	a2bff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200694:	6c4c                	ld	a1,152(s0)
ffffffffc0200696:	00004517          	auipc	a0,0x4
ffffffffc020069a:	20a50513          	addi	a0,a0,522 # ffffffffc02048a0 <commands+0x280>
ffffffffc020069e:	a1dff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02006a2:	704c                	ld	a1,160(s0)
ffffffffc02006a4:	00004517          	auipc	a0,0x4
ffffffffc02006a8:	21450513          	addi	a0,a0,532 # ffffffffc02048b8 <commands+0x298>
ffffffffc02006ac:	a0fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02006b0:	744c                	ld	a1,168(s0)
ffffffffc02006b2:	00004517          	auipc	a0,0x4
ffffffffc02006b6:	21e50513          	addi	a0,a0,542 # ffffffffc02048d0 <commands+0x2b0>
ffffffffc02006ba:	a01ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02006be:	784c                	ld	a1,176(s0)
ffffffffc02006c0:	00004517          	auipc	a0,0x4
ffffffffc02006c4:	22850513          	addi	a0,a0,552 # ffffffffc02048e8 <commands+0x2c8>
ffffffffc02006c8:	9f3ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02006cc:	7c4c                	ld	a1,184(s0)
ffffffffc02006ce:	00004517          	auipc	a0,0x4
ffffffffc02006d2:	23250513          	addi	a0,a0,562 # ffffffffc0204900 <commands+0x2e0>
ffffffffc02006d6:	9e5ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02006da:	606c                	ld	a1,192(s0)
ffffffffc02006dc:	00004517          	auipc	a0,0x4
ffffffffc02006e0:	23c50513          	addi	a0,a0,572 # ffffffffc0204918 <commands+0x2f8>
ffffffffc02006e4:	9d7ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02006e8:	646c                	ld	a1,200(s0)
ffffffffc02006ea:	00004517          	auipc	a0,0x4
ffffffffc02006ee:	24650513          	addi	a0,a0,582 # ffffffffc0204930 <commands+0x310>
ffffffffc02006f2:	9c9ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02006f6:	686c                	ld	a1,208(s0)
ffffffffc02006f8:	00004517          	auipc	a0,0x4
ffffffffc02006fc:	25050513          	addi	a0,a0,592 # ffffffffc0204948 <commands+0x328>
ffffffffc0200700:	9bbff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200704:	6c6c                	ld	a1,216(s0)
ffffffffc0200706:	00004517          	auipc	a0,0x4
ffffffffc020070a:	25a50513          	addi	a0,a0,602 # ffffffffc0204960 <commands+0x340>
ffffffffc020070e:	9adff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200712:	706c                	ld	a1,224(s0)
ffffffffc0200714:	00004517          	auipc	a0,0x4
ffffffffc0200718:	26450513          	addi	a0,a0,612 # ffffffffc0204978 <commands+0x358>
ffffffffc020071c:	99fff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200720:	746c                	ld	a1,232(s0)
ffffffffc0200722:	00004517          	auipc	a0,0x4
ffffffffc0200726:	26e50513          	addi	a0,a0,622 # ffffffffc0204990 <commands+0x370>
ffffffffc020072a:	991ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc020072e:	786c                	ld	a1,240(s0)
ffffffffc0200730:	00004517          	auipc	a0,0x4
ffffffffc0200734:	27850513          	addi	a0,a0,632 # ffffffffc02049a8 <commands+0x388>
ffffffffc0200738:	983ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020073c:	7c6c                	ld	a1,248(s0)
}
ffffffffc020073e:	6402                	ld	s0,0(sp)
ffffffffc0200740:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200742:	00004517          	auipc	a0,0x4
ffffffffc0200746:	27e50513          	addi	a0,a0,638 # ffffffffc02049c0 <commands+0x3a0>
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
ffffffffc020075a:	28250513          	addi	a0,a0,642 # ffffffffc02049d8 <commands+0x3b8>
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
ffffffffc0200772:	28250513          	addi	a0,a0,642 # ffffffffc02049f0 <commands+0x3d0>
ffffffffc0200776:	945ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020077a:	10843583          	ld	a1,264(s0)
ffffffffc020077e:	00004517          	auipc	a0,0x4
ffffffffc0200782:	28a50513          	addi	a0,a0,650 # ffffffffc0204a08 <commands+0x3e8>
ffffffffc0200786:	935ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020078a:	11043583          	ld	a1,272(s0)
ffffffffc020078e:	00004517          	auipc	a0,0x4
ffffffffc0200792:	29250513          	addi	a0,a0,658 # ffffffffc0204a20 <commands+0x400>
ffffffffc0200796:	925ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020079a:	11843583          	ld	a1,280(s0)
}
ffffffffc020079e:	6402                	ld	s0,0(sp)
ffffffffc02007a0:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02007a2:	00004517          	auipc	a0,0x4
ffffffffc02007a6:	29650513          	addi	a0,a0,662 # ffffffffc0204a38 <commands+0x418>
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
ffffffffc02007c2:	34270713          	addi	a4,a4,834 # ffffffffc0204b00 <commands+0x4e0>
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
ffffffffc02007d4:	2e050513          	addi	a0,a0,736 # ffffffffc0204ab0 <commands+0x490>
ffffffffc02007d8:	8e3ff06f          	j	ffffffffc02000ba <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02007dc:	00004517          	auipc	a0,0x4
ffffffffc02007e0:	2b450513          	addi	a0,a0,692 # ffffffffc0204a90 <commands+0x470>
ffffffffc02007e4:	8d7ff06f          	j	ffffffffc02000ba <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02007e8:	00004517          	auipc	a0,0x4
ffffffffc02007ec:	26850513          	addi	a0,a0,616 # ffffffffc0204a50 <commands+0x430>
ffffffffc02007f0:	8cbff06f          	j	ffffffffc02000ba <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02007f4:	00004517          	auipc	a0,0x4
ffffffffc02007f8:	27c50513          	addi	a0,a0,636 # ffffffffc0204a70 <commands+0x450>
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
ffffffffc020082a:	2ba50513          	addi	a0,a0,698 # ffffffffc0204ae0 <commands+0x4c0>
ffffffffc020082e:	88dff06f          	j	ffffffffc02000ba <cprintf>
            print_trapframe(tf);
ffffffffc0200832:	bf31                	j	ffffffffc020074e <print_trapframe>
}
ffffffffc0200834:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200836:	06400593          	li	a1,100
ffffffffc020083a:	00004517          	auipc	a0,0x4
ffffffffc020083e:	29650513          	addi	a0,a0,662 # ffffffffc0204ad0 <commands+0x4b0>
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
ffffffffc0200860:	48c70713          	addi	a4,a4,1164 # ffffffffc0204ce8 <commands+0x6c8>
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
ffffffffc0200872:	46250513          	addi	a0,a0,1122 # ffffffffc0204cd0 <commands+0x6b0>
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
ffffffffc0200894:	2a050513          	addi	a0,a0,672 # ffffffffc0204b30 <commands+0x510>
}
ffffffffc0200898:	6442                	ld	s0,16(sp)
ffffffffc020089a:	60e2                	ld	ra,24(sp)
ffffffffc020089c:	64a2                	ld	s1,8(sp)
ffffffffc020089e:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc02008a0:	81bff06f          	j	ffffffffc02000ba <cprintf>
ffffffffc02008a4:	00004517          	auipc	a0,0x4
ffffffffc02008a8:	2ac50513          	addi	a0,a0,684 # ffffffffc0204b50 <commands+0x530>
ffffffffc02008ac:	b7f5                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc02008ae:	00004517          	auipc	a0,0x4
ffffffffc02008b2:	2c250513          	addi	a0,a0,706 # ffffffffc0204b70 <commands+0x550>
ffffffffc02008b6:	b7cd                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc02008b8:	00004517          	auipc	a0,0x4
ffffffffc02008bc:	2d050513          	addi	a0,a0,720 # ffffffffc0204b88 <commands+0x568>
ffffffffc02008c0:	bfe1                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Load address misaligned\n");
ffffffffc02008c2:	00004517          	auipc	a0,0x4
ffffffffc02008c6:	2d650513          	addi	a0,a0,726 # ffffffffc0204b98 <commands+0x578>
ffffffffc02008ca:	b7f9                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc02008cc:	00004517          	auipc	a0,0x4
ffffffffc02008d0:	2ec50513          	addi	a0,a0,748 # ffffffffc0204bb8 <commands+0x598>
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
ffffffffc02008ee:	2e660613          	addi	a2,a2,742 # ffffffffc0204bd0 <commands+0x5b0>
ffffffffc02008f2:	0cc00593          	li	a1,204
ffffffffc02008f6:	00004517          	auipc	a0,0x4
ffffffffc02008fa:	dca50513          	addi	a0,a0,-566 # ffffffffc02046c0 <commands+0xa0>
ffffffffc02008fe:	805ff0ef          	jal	ra,ffffffffc0200102 <__panic>
            cprintf("AMO address misaligned\n");
ffffffffc0200902:	00004517          	auipc	a0,0x4
ffffffffc0200906:	2ee50513          	addi	a0,a0,750 # ffffffffc0204bf0 <commands+0x5d0>
ffffffffc020090a:	b779                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Store/AMO access fault\n");
ffffffffc020090c:	00004517          	auipc	a0,0x4
ffffffffc0200910:	2fc50513          	addi	a0,a0,764 # ffffffffc0204c08 <commands+0x5e8>
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
ffffffffc020092e:	2a660613          	addi	a2,a2,678 # ffffffffc0204bd0 <commands+0x5b0>
ffffffffc0200932:	0d600593          	li	a1,214
ffffffffc0200936:	00004517          	auipc	a0,0x4
ffffffffc020093a:	d8a50513          	addi	a0,a0,-630 # ffffffffc02046c0 <commands+0xa0>
ffffffffc020093e:	fc4ff0ef          	jal	ra,ffffffffc0200102 <__panic>
            cprintf("Environment call from U-mode\n");
ffffffffc0200942:	00004517          	auipc	a0,0x4
ffffffffc0200946:	2de50513          	addi	a0,a0,734 # ffffffffc0204c20 <commands+0x600>
ffffffffc020094a:	b7b9                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Environment call from S-mode\n");
ffffffffc020094c:	00004517          	auipc	a0,0x4
ffffffffc0200950:	2f450513          	addi	a0,a0,756 # ffffffffc0204c40 <commands+0x620>
ffffffffc0200954:	b791                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Environment call from H-mode\n");
ffffffffc0200956:	00004517          	auipc	a0,0x4
ffffffffc020095a:	30a50513          	addi	a0,a0,778 # ffffffffc0204c60 <commands+0x640>
ffffffffc020095e:	bf2d                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Environment call from M-mode\n");
ffffffffc0200960:	00004517          	auipc	a0,0x4
ffffffffc0200964:	32050513          	addi	a0,a0,800 # ffffffffc0204c80 <commands+0x660>
ffffffffc0200968:	bf05                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc020096a:	00004517          	auipc	a0,0x4
ffffffffc020096e:	33650513          	addi	a0,a0,822 # ffffffffc0204ca0 <commands+0x680>
ffffffffc0200972:	b71d                	j	ffffffffc0200898 <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200974:	00004517          	auipc	a0,0x4
ffffffffc0200978:	34450513          	addi	a0,a0,836 # ffffffffc0204cb8 <commands+0x698>
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
ffffffffc0200998:	23c60613          	addi	a2,a2,572 # ffffffffc0204bd0 <commands+0x5b0>
ffffffffc020099c:	0ec00593          	li	a1,236
ffffffffc02009a0:	00004517          	auipc	a0,0x4
ffffffffc02009a4:	d2050513          	addi	a0,a0,-736 # ffffffffc02046c0 <commands+0xa0>
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
ffffffffc02009c4:	21060613          	addi	a2,a2,528 # ffffffffc0204bd0 <commands+0x5b0>
ffffffffc02009c8:	0f300593          	li	a1,243
ffffffffc02009cc:	00004517          	auipc	a0,0x4
ffffffffc02009d0:	cf450513          	addi	a0,a0,-780 # ffffffffc02046c0 <commands+0xa0>
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

ffffffffc0200ab0 <check_vma_overlap.part.0>:
}


// check_vma_overlap - 检查 vma1 是否与 vma2 重叠？
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0200ab0:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end); // 断言 prev 的起始地址小于结束地址
    assert(prev->vm_end <= next->vm_start); // 断言 prev 的结束地址小于等于 next 的起始地址
    assert(next->vm_start < next->vm_end); // 断言 next 的起始地址小于结束地址
ffffffffc0200ab2:	00004697          	auipc	a3,0x4
ffffffffc0200ab6:	27668693          	addi	a3,a3,630 # ffffffffc0204d28 <commands+0x708>
ffffffffc0200aba:	00004617          	auipc	a2,0x4
ffffffffc0200abe:	28e60613          	addi	a2,a2,654 # ffffffffc0204d48 <commands+0x728>
ffffffffc0200ac2:	07d00593          	li	a1,125
ffffffffc0200ac6:	00004517          	auipc	a0,0x4
ffffffffc0200aca:	29a50513          	addi	a0,a0,666 # ffffffffc0204d60 <commands+0x740>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0200ace:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end); // 断言 next 的起始地址小于结束地址
ffffffffc0200ad0:	e32ff0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0200ad4 <mm_create>:
mm_create(void) {
ffffffffc0200ad4:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0200ad6:	03000513          	li	a0,48
mm_create(void) {
ffffffffc0200ada:	e022                	sd	s0,0(sp)
ffffffffc0200adc:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0200ade:	070030ef          	jal	ra,ffffffffc0203b4e <kmalloc>
ffffffffc0200ae2:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0200ae4:	c105                	beqz	a0,ffffffffc0200b04 <mm_create+0x30>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200ae6:	e408                	sd	a0,8(s0)
ffffffffc0200ae8:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL; // 初始化缓存指针
ffffffffc0200aea:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL; // 初始化页目录指针
ffffffffc0200aee:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0; // 初始化映射计数器
ffffffffc0200af2:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm); // 如果启用了交换空间，则初始化 mm 的交换空间
ffffffffc0200af6:	00011797          	auipc	a5,0x11
ffffffffc0200afa:	a3a7a783          	lw	a5,-1478(a5) # ffffffffc0211530 <swap_init_ok>
ffffffffc0200afe:	eb81                	bnez	a5,ffffffffc0200b0e <mm_create+0x3a>
        else mm->sm_priv = NULL; // 否则设置私有数据指针为 NULL
ffffffffc0200b00:	02053423          	sd	zero,40(a0)
}
ffffffffc0200b04:	60a2                	ld	ra,8(sp)
ffffffffc0200b06:	8522                	mv	a0,s0
ffffffffc0200b08:	6402                	ld	s0,0(sp)
ffffffffc0200b0a:	0141                	addi	sp,sp,16
ffffffffc0200b0c:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm); // 如果启用了交换空间，则初始化 mm 的交换空间
ffffffffc0200b0e:	693000ef          	jal	ra,ffffffffc02019a0 <swap_init_mm>
}
ffffffffc0200b12:	60a2                	ld	ra,8(sp)
ffffffffc0200b14:	8522                	mv	a0,s0
ffffffffc0200b16:	6402                	ld	s0,0(sp)
ffffffffc0200b18:	0141                	addi	sp,sp,16
ffffffffc0200b1a:	8082                	ret

ffffffffc0200b1c <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
ffffffffc0200b1c:	1101                	addi	sp,sp,-32
ffffffffc0200b1e:	e04a                	sd	s2,0(sp)
ffffffffc0200b20:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200b22:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint_t vm_flags) {
ffffffffc0200b26:	e822                	sd	s0,16(sp)
ffffffffc0200b28:	e426                	sd	s1,8(sp)
ffffffffc0200b2a:	ec06                	sd	ra,24(sp)
ffffffffc0200b2c:	84ae                	mv	s1,a1
ffffffffc0200b2e:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200b30:	01e030ef          	jal	ra,ffffffffc0203b4e <kmalloc>
    if (vma != NULL) {
ffffffffc0200b34:	c509                	beqz	a0,ffffffffc0200b3e <vma_create+0x22>
        vma->vm_start = vm_start; // 设置起始地址
ffffffffc0200b36:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end; // 设置结束地址
ffffffffc0200b3a:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags; // 设置标志
ffffffffc0200b3c:	ed00                	sd	s0,24(a0)
}
ffffffffc0200b3e:	60e2                	ld	ra,24(sp)
ffffffffc0200b40:	6442                	ld	s0,16(sp)
ffffffffc0200b42:	64a2                	ld	s1,8(sp)
ffffffffc0200b44:	6902                	ld	s2,0(sp)
ffffffffc0200b46:	6105                	addi	sp,sp,32
ffffffffc0200b48:	8082                	ret

ffffffffc0200b4a <find_vma>:
find_vma(struct mm_struct *mm, uintptr_t addr) {
ffffffffc0200b4a:	86aa                	mv	a3,a0
    if (mm != NULL) {
ffffffffc0200b4c:	c505                	beqz	a0,ffffffffc0200b74 <find_vma+0x2a>
        vma = mm->mmap_cache; // 获取缓存的 vma
ffffffffc0200b4e:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) { // 如果缓存的 vma 不包含地址
ffffffffc0200b50:	c501                	beqz	a0,ffffffffc0200b58 <find_vma+0xe>
ffffffffc0200b52:	651c                	ld	a5,8(a0)
ffffffffc0200b54:	02f5f263          	bgeu	a1,a5,ffffffffc0200b78 <find_vma+0x2e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200b58:	669c                	ld	a5,8(a3)
                while ((le = list_next(le)) != list) { // 遍历线性链表
ffffffffc0200b5a:	00f68d63          	beq	a3,a5,ffffffffc0200b74 <find_vma+0x2a>
                    if (vma->vm_start <= addr && addr < vma->vm_end) { // 如果找到包含地址的 vma
ffffffffc0200b5e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0200b62:	00e5e663          	bltu	a1,a4,ffffffffc0200b6e <find_vma+0x24>
ffffffffc0200b66:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200b6a:	00e5ec63          	bltu	a1,a4,ffffffffc0200b82 <find_vma+0x38>
ffffffffc0200b6e:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) { // 遍历线性链表
ffffffffc0200b70:	fef697e3          	bne	a3,a5,ffffffffc0200b5e <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0200b74:	4501                	li	a0,0
}
ffffffffc0200b76:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) { // 如果缓存的 vma 不包含地址
ffffffffc0200b78:	691c                	ld	a5,16(a0)
ffffffffc0200b7a:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0200b58 <find_vma+0xe>
            mm->mmap_cache = vma; // 更新缓存的 vma
ffffffffc0200b7e:	ea88                	sd	a0,16(a3)
ffffffffc0200b80:	8082                	ret
                    vma = le2vma(le, list_link);
ffffffffc0200b82:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma; // 更新缓存的 vma
ffffffffc0200b86:	ea88                	sd	a0,16(a3)
ffffffffc0200b88:	8082                	ret

ffffffffc0200b8a <insert_vma_struct>:

// insert_vma_struct - 在 mm 的列表链接中插入 vma
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    // 确保 vma 的起始地址小于结束地址
    assert(vma->vm_start < vma->vm_end);
ffffffffc0200b8a:	6590                	ld	a2,8(a1)
ffffffffc0200b8c:	0105b803          	ld	a6,16(a1)
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc0200b90:	1141                	addi	sp,sp,-16
ffffffffc0200b92:	e406                	sd	ra,8(sp)
ffffffffc0200b94:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0200b96:	01066763          	bltu	a2,a6,ffffffffc0200ba4 <insert_vma_struct+0x1a>
ffffffffc0200b9a:	a085                	j	ffffffffc0200bfa <insert_vma_struct+0x70>
    // 遍历 mm 的映射列表，找到应该插入 vma 的位置
    list_entry_t *le = list;
    while ((le = list_next(le)) != list) {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        // 如果当前遍历到的 vma 的起始地址大于要插入的 vma 的起始地址，则停止遍历
        if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0200b9c:	fe87b703          	ld	a4,-24(a5)
ffffffffc0200ba0:	04e66863          	bltu	a2,a4,ffffffffc0200bf0 <insert_vma_struct+0x66>
ffffffffc0200ba4:	86be                	mv	a3,a5
ffffffffc0200ba6:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list) {
ffffffffc0200ba8:	fef51ae3          	bne	a0,a5,ffffffffc0200b9c <insert_vma_struct+0x12>
    // 获取 le_prev 的下一个节点，即插入位置的后一个节点
    le_next = list_next(le_prev);
    
    // 检查重叠
    // 如果前一个节点不是头节点，检查与前一个 vma 是否重叠
    if (le_prev != list) {
ffffffffc0200bac:	02a68463          	beq	a3,a0,ffffffffc0200bd4 <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0200bb0:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end); // 断言 prev 的起始地址小于结束地址
ffffffffc0200bb4:	fe86b883          	ld	a7,-24(a3)
ffffffffc0200bb8:	08e8f163          	bgeu	a7,a4,ffffffffc0200c3a <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start); // 断言 prev 的结束地址小于等于 next 的起始地址
ffffffffc0200bbc:	04e66f63          	bltu	a2,a4,ffffffffc0200c1a <insert_vma_struct+0x90>
    }
    // 如果后一个节点不是头节点，检查与后一个 vma 是否重叠
    if (le_next != list) {
ffffffffc0200bc0:	00f50a63          	beq	a0,a5,ffffffffc0200bd4 <insert_vma_struct+0x4a>
        if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0200bc4:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start); // 断言 prev 的结束地址小于等于 next 的起始地址
ffffffffc0200bc8:	05076963          	bltu	a4,a6,ffffffffc0200c1a <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end); // 断言 next 的起始地址小于结束地址
ffffffffc0200bcc:	ff07b603          	ld	a2,-16(a5)
ffffffffc0200bd0:	02c77363          	bgeu	a4,a2,ffffffffc0200bf6 <insert_vma_struct+0x6c>
    vma->vm_mm = mm;
    // 在 le_prev 之后插入 vma
    list_add_after(le_prev, &(vma->list_link));
    
    // 更新 mm 中的映射计数器
    mm->map_count ++;
ffffffffc0200bd4:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0200bd6:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0200bd8:	02058613          	addi	a2,a1,32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0200bdc:	e390                	sd	a2,0(a5)
ffffffffc0200bde:	e690                	sd	a2,8(a3)
}
ffffffffc0200be0:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0200be2:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0200be4:	f194                	sd	a3,32(a1)
    mm->map_count ++;
ffffffffc0200be6:	0017079b          	addiw	a5,a4,1
ffffffffc0200bea:	d11c                	sw	a5,32(a0)
}
ffffffffc0200bec:	0141                	addi	sp,sp,16
ffffffffc0200bee:	8082                	ret
    if (le_prev != list) {
ffffffffc0200bf0:	fca690e3          	bne	a3,a0,ffffffffc0200bb0 <insert_vma_struct+0x26>
ffffffffc0200bf4:	bfd1                	j	ffffffffc0200bc8 <insert_vma_struct+0x3e>
ffffffffc0200bf6:	ebbff0ef          	jal	ra,ffffffffc0200ab0 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0200bfa:	00004697          	auipc	a3,0x4
ffffffffc0200bfe:	17668693          	addi	a3,a3,374 # ffffffffc0204d70 <commands+0x750>
ffffffffc0200c02:	00004617          	auipc	a2,0x4
ffffffffc0200c06:	14660613          	addi	a2,a2,326 # ffffffffc0204d48 <commands+0x728>
ffffffffc0200c0a:	08500593          	li	a1,133
ffffffffc0200c0e:	00004517          	auipc	a0,0x4
ffffffffc0200c12:	15250513          	addi	a0,a0,338 # ffffffffc0204d60 <commands+0x740>
ffffffffc0200c16:	cecff0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(prev->vm_end <= next->vm_start); // 断言 prev 的结束地址小于等于 next 的起始地址
ffffffffc0200c1a:	00004697          	auipc	a3,0x4
ffffffffc0200c1e:	19668693          	addi	a3,a3,406 # ffffffffc0204db0 <commands+0x790>
ffffffffc0200c22:	00004617          	auipc	a2,0x4
ffffffffc0200c26:	12660613          	addi	a2,a2,294 # ffffffffc0204d48 <commands+0x728>
ffffffffc0200c2a:	07c00593          	li	a1,124
ffffffffc0200c2e:	00004517          	auipc	a0,0x4
ffffffffc0200c32:	13250513          	addi	a0,a0,306 # ffffffffc0204d60 <commands+0x740>
ffffffffc0200c36:	cccff0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(prev->vm_start < prev->vm_end); // 断言 prev 的起始地址小于结束地址
ffffffffc0200c3a:	00004697          	auipc	a3,0x4
ffffffffc0200c3e:	15668693          	addi	a3,a3,342 # ffffffffc0204d90 <commands+0x770>
ffffffffc0200c42:	00004617          	auipc	a2,0x4
ffffffffc0200c46:	10660613          	addi	a2,a2,262 # ffffffffc0204d48 <commands+0x728>
ffffffffc0200c4a:	07b00593          	li	a1,123
ffffffffc0200c4e:	00004517          	auipc	a0,0x4
ffffffffc0200c52:	11250513          	addi	a0,a0,274 # ffffffffc0204d60 <commands+0x740>
ffffffffc0200c56:	cacff0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0200c5a <mm_destroy>:

// mm_destroy - 释放 mm 及其内部字段
void
mm_destroy(struct mm_struct *mm) {
ffffffffc0200c5a:	1141                	addi	sp,sp,-16
ffffffffc0200c5c:	e022                	sd	s0,0(sp)
ffffffffc0200c5e:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0200c60:	6508                	ld	a0,8(a0)
ffffffffc0200c62:	e406                	sd	ra,8(sp)
    // 获取 mm 的映射列表的头节点
    list_entry_t *list = &(mm->mmap_list), *le;
    // 遍历映射列表，释放每一个 vma
    while ((le = list_next(list)) != list) {
ffffffffc0200c64:	00a40e63          	beq	s0,a0,ffffffffc0200c80 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200c68:	6118                	ld	a4,0(a0)
ffffffffc0200c6a:	651c                	ld	a5,8(a0)
        list_del(le); // 从列表中删除当前节点
        // 释放 vma 所占用的内存
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  
ffffffffc0200c6c:	03000593          	li	a1,48
ffffffffc0200c70:	1501                	addi	a0,a0,-32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200c72:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200c74:	e398                	sd	a4,0(a5)
ffffffffc0200c76:	793020ef          	jal	ra,ffffffffc0203c08 <kfree>
    return listelm->next;
ffffffffc0200c7a:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0200c7c:	fea416e3          	bne	s0,a0,ffffffffc0200c68 <mm_destroy+0xe>
    }
    // 释放 mm 所占用的内存
    kfree(mm, sizeof(struct mm_struct)); 
ffffffffc0200c80:	8522                	mv	a0,s0
    // 将 mm 设置为 NULL，防止产生野指针
    mm=NULL;
}
ffffffffc0200c82:	6402                	ld	s0,0(sp)
ffffffffc0200c84:	60a2                	ld	ra,8(sp)
    kfree(mm, sizeof(struct mm_struct)); 
ffffffffc0200c86:	03000593          	li	a1,48
}
ffffffffc0200c8a:	0141                	addi	sp,sp,16
    kfree(mm, sizeof(struct mm_struct)); 
ffffffffc0200c8c:	77d0206f          	j	ffffffffc0203c08 <kfree>

ffffffffc0200c90 <vmm_init>:

// vmm_init - 初始化虚拟内存管理
//          - 目前只是调用 check_vmm 来检查 vmm 的正确性
void
vmm_init(void) {
ffffffffc0200c90:	715d                	addi	sp,sp,-80
ffffffffc0200c92:	e486                	sd	ra,72(sp)
ffffffffc0200c94:	f44e                	sd	s3,40(sp)
ffffffffc0200c96:	f052                	sd	s4,32(sp)
ffffffffc0200c98:	e0a2                	sd	s0,64(sp)
ffffffffc0200c9a:	fc26                	sd	s1,56(sp)
ffffffffc0200c9c:	f84a                	sd	s2,48(sp)
ffffffffc0200c9e:	ec56                	sd	s5,24(sp)
ffffffffc0200ca0:	e85a                	sd	s6,16(sp)
ffffffffc0200ca2:	e45e                	sd	s7,8(sp)

// check_vmm - 检查 vmm 的正确性
static void
check_vmm(void) {
    // 存储当前的空闲页面数
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0200ca4:	5f7010ef          	jal	ra,ffffffffc0202a9a <nr_free_pages>
ffffffffc0200ca8:	89aa                	mv	s3,a0
}

static void
check_vma_struct(void) {
    // 存储当前的空闲页面数
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0200caa:	5f1010ef          	jal	ra,ffffffffc0202a9a <nr_free_pages>
ffffffffc0200cae:	8a2a                	mv	s4,a0
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0200cb0:	03000513          	li	a0,48
ffffffffc0200cb4:	69b020ef          	jal	ra,ffffffffc0203b4e <kmalloc>
    if (mm != NULL) {
ffffffffc0200cb8:	56050863          	beqz	a0,ffffffffc0201228 <vmm_init+0x598>
    elm->prev = elm->next = elm;
ffffffffc0200cbc:	e508                	sd	a0,8(a0)
ffffffffc0200cbe:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL; // 初始化缓存指针
ffffffffc0200cc0:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL; // 初始化页目录指针
ffffffffc0200cc4:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0; // 初始化映射计数器
ffffffffc0200cc8:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm); // 如果启用了交换空间，则初始化 mm 的交换空间
ffffffffc0200ccc:	00011797          	auipc	a5,0x11
ffffffffc0200cd0:	8647a783          	lw	a5,-1948(a5) # ffffffffc0211530 <swap_init_ok>
ffffffffc0200cd4:	84aa                	mv	s1,a0
ffffffffc0200cd6:	e7b9                	bnez	a5,ffffffffc0200d24 <vmm_init+0x94>
        else mm->sm_priv = NULL; // 否则设置私有数据指针为 NULL
ffffffffc0200cd8:	02053423          	sd	zero,40(a0)
vmm_init(void) {
ffffffffc0200cdc:	03200413          	li	s0,50
ffffffffc0200ce0:	a811                	j	ffffffffc0200cf4 <vmm_init+0x64>
        vma->vm_start = vm_start; // 设置起始地址
ffffffffc0200ce2:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end; // 设置结束地址
ffffffffc0200ce4:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags; // 设置标志
ffffffffc0200ce6:	00053c23          	sd	zero,24(a0)
    // 定义步长，用于创建测试用的 vma
    int step1 = 10, step2 = step1 * 10;

    int i;
    // 从后向前创建并插入 vma
    for (i = step1; i >= 1; i --) {
ffffffffc0200cea:	146d                	addi	s0,s0,-5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        // 断言 vma 创建成功
        assert(vma != NULL);
        // 将 vma 插入到 mm 的映射列表中
        insert_vma_struct(mm, vma);
ffffffffc0200cec:	8526                	mv	a0,s1
ffffffffc0200cee:	e9dff0ef          	jal	ra,ffffffffc0200b8a <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc0200cf2:	cc05                	beqz	s0,ffffffffc0200d2a <vmm_init+0x9a>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200cf4:	03000513          	li	a0,48
ffffffffc0200cf8:	657020ef          	jal	ra,ffffffffc0203b4e <kmalloc>
ffffffffc0200cfc:	85aa                	mv	a1,a0
ffffffffc0200cfe:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc0200d02:	f165                	bnez	a0,ffffffffc0200ce2 <vmm_init+0x52>
        assert(vma != NULL);
ffffffffc0200d04:	00004697          	auipc	a3,0x4
ffffffffc0200d08:	2fc68693          	addi	a3,a3,764 # ffffffffc0205000 <commands+0x9e0>
ffffffffc0200d0c:	00004617          	auipc	a2,0x4
ffffffffc0200d10:	03c60613          	addi	a2,a2,60 # ffffffffc0204d48 <commands+0x728>
ffffffffc0200d14:	0ea00593          	li	a1,234
ffffffffc0200d18:	00004517          	auipc	a0,0x4
ffffffffc0200d1c:	04850513          	addi	a0,a0,72 # ffffffffc0204d60 <commands+0x740>
ffffffffc0200d20:	be2ff0ef          	jal	ra,ffffffffc0200102 <__panic>
        if (swap_init_ok) swap_init_mm(mm); // 如果启用了交换空间，则初始化 mm 的交换空间
ffffffffc0200d24:	47d000ef          	jal	ra,ffffffffc02019a0 <swap_init_mm>
ffffffffc0200d28:	bf55                	j	ffffffffc0200cdc <vmm_init+0x4c>
ffffffffc0200d2a:	03700413          	li	s0,55
    }

    // 从前向后创建并插入 vma
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0200d2e:	1f900913          	li	s2,505
ffffffffc0200d32:	a819                	j	ffffffffc0200d48 <vmm_init+0xb8>
        vma->vm_start = vm_start; // 设置起始地址
ffffffffc0200d34:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end; // 设置结束地址
ffffffffc0200d36:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags; // 设置标志
ffffffffc0200d38:	00053c23          	sd	zero,24(a0)
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0200d3c:	0415                	addi	s0,s0,5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        // 断言 vma 创建成功
        assert(vma != NULL);
        // 将 vma 插入到 mm 的映射列表中
        insert_vma_struct(mm, vma);
ffffffffc0200d3e:	8526                	mv	a0,s1
ffffffffc0200d40:	e4bff0ef          	jal	ra,ffffffffc0200b8a <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0200d44:	03240a63          	beq	s0,s2,ffffffffc0200d78 <vmm_init+0xe8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200d48:	03000513          	li	a0,48
ffffffffc0200d4c:	603020ef          	jal	ra,ffffffffc0203b4e <kmalloc>
ffffffffc0200d50:	85aa                	mv	a1,a0
ffffffffc0200d52:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc0200d56:	fd79                	bnez	a0,ffffffffc0200d34 <vmm_init+0xa4>
        assert(vma != NULL);
ffffffffc0200d58:	00004697          	auipc	a3,0x4
ffffffffc0200d5c:	2a868693          	addi	a3,a3,680 # ffffffffc0205000 <commands+0x9e0>
ffffffffc0200d60:	00004617          	auipc	a2,0x4
ffffffffc0200d64:	fe860613          	addi	a2,a2,-24 # ffffffffc0204d48 <commands+0x728>
ffffffffc0200d68:	0f300593          	li	a1,243
ffffffffc0200d6c:	00004517          	auipc	a0,0x4
ffffffffc0200d70:	ff450513          	addi	a0,a0,-12 # ffffffffc0204d60 <commands+0x740>
ffffffffc0200d74:	b8eff0ef          	jal	ra,ffffffffc0200102 <__panic>
    return listelm->next;
ffffffffc0200d78:	649c                	ld	a5,8(s1)
ffffffffc0200d7a:	471d                	li	a4,7
    }

    // 遍历 mm 的映射列表，检查 vma 的顺序和属性
    list_entry_t *le = list_next(&(mm->mmap_list));
    for (i = 1; i <= step2; i ++) {
ffffffffc0200d7c:	1fb00593          	li	a1,507
        // 断言当前节点不是头节点
        assert(le != &(mm->mmap_list));
ffffffffc0200d80:	2ef48463          	beq	s1,a5,ffffffffc0201068 <vmm_init+0x3d8>
        struct vma_struct *mmap = le2vma(le, list_link);
        // 断言 vma 的起始地址和结束地址正确
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0200d84:	fe87b603          	ld	a2,-24(a5)
ffffffffc0200d88:	ffe70693          	addi	a3,a4,-2
ffffffffc0200d8c:	26d61e63          	bne	a2,a3,ffffffffc0201008 <vmm_init+0x378>
ffffffffc0200d90:	ff07b683          	ld	a3,-16(a5)
ffffffffc0200d94:	26e69a63          	bne	a3,a4,ffffffffc0201008 <vmm_init+0x378>
    for (i = 1; i <= step2; i ++) {
ffffffffc0200d98:	0715                	addi	a4,a4,5
ffffffffc0200d9a:	679c                	ld	a5,8(a5)
ffffffffc0200d9c:	feb712e3          	bne	a4,a1,ffffffffc0200d80 <vmm_init+0xf0>
ffffffffc0200da0:	4b1d                	li	s6,7
ffffffffc0200da2:	4415                	li	s0,5
        le = list_next(le);
    }

    // 检查 find_vma 函数的正确性
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0200da4:	1f900b93          	li	s7,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0200da8:	85a2                	mv	a1,s0
ffffffffc0200daa:	8526                	mv	a0,s1
ffffffffc0200dac:	d9fff0ef          	jal	ra,ffffffffc0200b4a <find_vma>
ffffffffc0200db0:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0200db2:	2c050b63          	beqz	a0,ffffffffc0201088 <vmm_init+0x3f8>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0200db6:	00140593          	addi	a1,s0,1
ffffffffc0200dba:	8526                	mv	a0,s1
ffffffffc0200dbc:	d8fff0ef          	jal	ra,ffffffffc0200b4a <find_vma>
ffffffffc0200dc0:	8aaa                	mv	s5,a0
        assert(vma2 != NULL);
ffffffffc0200dc2:	2e050363          	beqz	a0,ffffffffc02010a8 <vmm_init+0x418>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0200dc6:	85da                	mv	a1,s6
ffffffffc0200dc8:	8526                	mv	a0,s1
ffffffffc0200dca:	d81ff0ef          	jal	ra,ffffffffc0200b4a <find_vma>
        assert(vma3 == NULL);
ffffffffc0200dce:	2e051d63          	bnez	a0,ffffffffc02010c8 <vmm_init+0x438>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc0200dd2:	00340593          	addi	a1,s0,3
ffffffffc0200dd6:	8526                	mv	a0,s1
ffffffffc0200dd8:	d73ff0ef          	jal	ra,ffffffffc0200b4a <find_vma>
        assert(vma4 == NULL);
ffffffffc0200ddc:	30051663          	bnez	a0,ffffffffc02010e8 <vmm_init+0x458>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc0200de0:	00440593          	addi	a1,s0,4
ffffffffc0200de4:	8526                	mv	a0,s1
ffffffffc0200de6:	d65ff0ef          	jal	ra,ffffffffc0200b4a <find_vma>
        assert(vma5 == NULL);
ffffffffc0200dea:	30051f63          	bnez	a0,ffffffffc0201108 <vmm_init+0x478>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0200dee:	00893783          	ld	a5,8(s2)
ffffffffc0200df2:	24879b63          	bne	a5,s0,ffffffffc0201048 <vmm_init+0x3b8>
ffffffffc0200df6:	01093783          	ld	a5,16(s2)
ffffffffc0200dfa:	25679763          	bne	a5,s6,ffffffffc0201048 <vmm_init+0x3b8>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0200dfe:	008ab783          	ld	a5,8(s5)
ffffffffc0200e02:	22879363          	bne	a5,s0,ffffffffc0201028 <vmm_init+0x398>
ffffffffc0200e06:	010ab783          	ld	a5,16(s5)
ffffffffc0200e0a:	21679f63          	bne	a5,s6,ffffffffc0201028 <vmm_init+0x398>
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0200e0e:	0415                	addi	s0,s0,5
ffffffffc0200e10:	0b15                	addi	s6,s6,5
ffffffffc0200e12:	f9741be3          	bne	s0,s7,ffffffffc0200da8 <vmm_init+0x118>
ffffffffc0200e16:	4411                	li	s0,4
    }

    // 检查 find_vma 函数在边界情况下的正确性
    for (i =4; i>=0; i--) {
ffffffffc0200e18:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc0200e1a:	85a2                	mv	a1,s0
ffffffffc0200e1c:	8526                	mv	a0,s1
ffffffffc0200e1e:	d2dff0ef          	jal	ra,ffffffffc0200b4a <find_vma>
ffffffffc0200e22:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL ) {
ffffffffc0200e26:	c90d                	beqz	a0,ffffffffc0200e58 <vmm_init+0x1c8>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0200e28:	6914                	ld	a3,16(a0)
ffffffffc0200e2a:	6510                	ld	a2,8(a0)
ffffffffc0200e2c:	00004517          	auipc	a0,0x4
ffffffffc0200e30:	0a450513          	addi	a0,a0,164 # ffffffffc0204ed0 <commands+0x8b0>
ffffffffc0200e34:	a86ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0200e38:	00004697          	auipc	a3,0x4
ffffffffc0200e3c:	0c068693          	addi	a3,a3,192 # ffffffffc0204ef8 <commands+0x8d8>
ffffffffc0200e40:	00004617          	auipc	a2,0x4
ffffffffc0200e44:	f0860613          	addi	a2,a2,-248 # ffffffffc0204d48 <commands+0x728>
ffffffffc0200e48:	11a00593          	li	a1,282
ffffffffc0200e4c:	00004517          	auipc	a0,0x4
ffffffffc0200e50:	f1450513          	addi	a0,a0,-236 # ffffffffc0204d60 <commands+0x740>
ffffffffc0200e54:	aaeff0ef          	jal	ra,ffffffffc0200102 <__panic>
    for (i =4; i>=0; i--) {
ffffffffc0200e58:	147d                	addi	s0,s0,-1
ffffffffc0200e5a:	fd2410e3          	bne	s0,s2,ffffffffc0200e1a <vmm_init+0x18a>
ffffffffc0200e5e:	a811                	j	ffffffffc0200e72 <vmm_init+0x1e2>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200e60:	6118                	ld	a4,0(a0)
ffffffffc0200e62:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  
ffffffffc0200e64:	03000593          	li	a1,48
ffffffffc0200e68:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0200e6a:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200e6c:	e398                	sd	a4,0(a5)
ffffffffc0200e6e:	59b020ef          	jal	ra,ffffffffc0203c08 <kfree>
    return listelm->next;
ffffffffc0200e72:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list) {
ffffffffc0200e74:	fea496e3          	bne	s1,a0,ffffffffc0200e60 <vmm_init+0x1d0>
    kfree(mm, sizeof(struct mm_struct)); 
ffffffffc0200e78:	03000593          	li	a1,48
ffffffffc0200e7c:	8526                	mv	a0,s1
ffffffffc0200e7e:	58b020ef          	jal	ra,ffffffffc0203c08 <kfree>

    // 释放 mm 及其所有 vma
    mm_destroy(mm);

    // 断言空闲页面数没有变化，确保上面的操作没有影响内存分配
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0200e82:	419010ef          	jal	ra,ffffffffc0202a9a <nr_free_pages>
ffffffffc0200e86:	3caa1163          	bne	s4,a0,ffffffffc0201248 <vmm_init+0x5b8>

    // 打印检查成功的消息
    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0200e8a:	00004517          	auipc	a0,0x4
ffffffffc0200e8e:	0ae50513          	addi	a0,a0,174 # ffffffffc0204f38 <commands+0x918>
ffffffffc0200e92:	a28ff0ef          	jal	ra,ffffffffc02000ba <cprintf>

// check_pgfault - 检查缺页处理程序的正确性
static void
check_pgfault(void) {
    // 存储当前的空闲页面数
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0200e96:	405010ef          	jal	ra,ffffffffc0202a9a <nr_free_pages>
ffffffffc0200e9a:	84aa                	mv	s1,a0
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0200e9c:	03000513          	li	a0,48
ffffffffc0200ea0:	4af020ef          	jal	ra,ffffffffc0203b4e <kmalloc>
ffffffffc0200ea4:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0200ea6:	2a050163          	beqz	a0,ffffffffc0201148 <vmm_init+0x4b8>
        if (swap_init_ok) swap_init_mm(mm); // 如果启用了交换空间，则初始化 mm 的交换空间
ffffffffc0200eaa:	00010797          	auipc	a5,0x10
ffffffffc0200eae:	6867a783          	lw	a5,1670(a5) # ffffffffc0211530 <swap_init_ok>
    elm->prev = elm->next = elm;
ffffffffc0200eb2:	e508                	sd	a0,8(a0)
ffffffffc0200eb4:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL; // 初始化缓存指针
ffffffffc0200eb6:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL; // 初始化页目录指针
ffffffffc0200eba:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0; // 初始化映射计数器
ffffffffc0200ebe:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm); // 如果启用了交换空间，则初始化 mm 的交换空间
ffffffffc0200ec2:	14079063          	bnez	a5,ffffffffc0201002 <vmm_init+0x372>
        else mm->sm_priv = NULL; // 否则设置私有数据指针为 NULL
ffffffffc0200ec6:	02053423          	sd	zero,40(a0)
    check_mm_struct = mm_create();
    // 断言内存管理结构体创建成功
    assert(check_mm_struct != NULL);
    struct mm_struct *mm = check_mm_struct;
    // 为 mm 分配页目录，并将其设置为启动时的页目录
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0200eca:	00010917          	auipc	s2,0x10
ffffffffc0200ece:	67e93903          	ld	s2,1662(s2) # ffffffffc0211548 <boot_pgdir>
    // 断言页目录的第一个条目是空的
    assert(pgdir[0] == 0);
ffffffffc0200ed2:	00093783          	ld	a5,0(s2)
    check_mm_struct = mm_create();
ffffffffc0200ed6:	00010717          	auipc	a4,0x10
ffffffffc0200eda:	62873d23          	sd	s0,1594(a4) # ffffffffc0211510 <check_mm_struct>
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0200ede:	01243c23          	sd	s2,24(s0)
    assert(pgdir[0] == 0);
ffffffffc0200ee2:	24079363          	bnez	a5,ffffffffc0201128 <vmm_init+0x498>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200ee6:	03000513          	li	a0,48
ffffffffc0200eea:	465020ef          	jal	ra,ffffffffc0203b4e <kmalloc>
ffffffffc0200eee:	8a2a                	mv	s4,a0
    if (vma != NULL) {
ffffffffc0200ef0:	28050063          	beqz	a0,ffffffffc0201170 <vmm_init+0x4e0>
        vma->vm_end = vm_end; // 设置结束地址
ffffffffc0200ef4:	002007b7          	lui	a5,0x200
ffffffffc0200ef8:	00fa3823          	sd	a5,16(s4)
        vma->vm_flags = vm_flags; // 设置标志
ffffffffc0200efc:	4789                	li	a5,2
    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    // 断言虚拟内存区域结构体创建成功
    assert(vma != NULL);

    // 将虚拟内存区域结构体插入到内存管理结构体的映射列表中
    insert_vma_struct(mm, vma);
ffffffffc0200efe:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags; // 设置标志
ffffffffc0200f00:	00fa3c23          	sd	a5,24(s4)
    insert_vma_struct(mm, vma);
ffffffffc0200f04:	8522                	mv	a0,s0
        vma->vm_start = vm_start; // 设置起始地址
ffffffffc0200f06:	000a3423          	sd	zero,8(s4)
    insert_vma_struct(mm, vma);
ffffffffc0200f0a:	c81ff0ef          	jal	ra,ffffffffc0200b8a <insert_vma_struct>

    // 定义一个测试地址
    uintptr_t addr = 0x100;
    // 断言找到的虚拟内存区域是预期的区域
    assert(find_vma(mm, addr) == vma);
ffffffffc0200f0e:	10000593          	li	a1,256
ffffffffc0200f12:	8522                	mv	a0,s0
ffffffffc0200f14:	c37ff0ef          	jal	ra,ffffffffc0200b4a <find_vma>
ffffffffc0200f18:	10000793          	li	a5,256

    // 测试写入和读取内存
    int i, sum = 0;
    for (i = 0; i < 100; i ++) {
ffffffffc0200f1c:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0200f20:	26aa1863          	bne	s4,a0,ffffffffc0201190 <vmm_init+0x500>
        *(char *)(addr + i) = i;
ffffffffc0200f24:	00f78023          	sb	a5,0(a5) # 200000 <kern_entry-0xffffffffc0000000>
    for (i = 0; i < 100; i ++) {
ffffffffc0200f28:	0785                	addi	a5,a5,1
ffffffffc0200f2a:	fee79de3          	bne	a5,a4,ffffffffc0200f24 <vmm_init+0x294>
        sum += i;
ffffffffc0200f2e:	6705                	lui	a4,0x1
ffffffffc0200f30:	10000793          	li	a5,256
ffffffffc0200f34:	35670713          	addi	a4,a4,854 # 1356 <kern_entry-0xffffffffc01fecaa>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc0200f38:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc0200f3c:	0007c683          	lbu	a3,0(a5)
    for (i = 0; i < 100; i ++) {
ffffffffc0200f40:	0785                	addi	a5,a5,1
        sum -= *(char *)(addr + i);
ffffffffc0200f42:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc0200f44:	fec79ce3          	bne	a5,a2,ffffffffc0200f3c <vmm_init+0x2ac>
    }
    // 断言读取和写入操作是正确的
    assert(sum == 0);
ffffffffc0200f48:	26071463          	bnez	a4,ffffffffc02011b0 <vmm_init+0x520>

    // 从页目录中移除页面
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc0200f4c:	4581                	li	a1,0
ffffffffc0200f4e:	854a                	mv	a0,s2
ffffffffc0200f50:	5d5010ef          	jal	ra,ffffffffc0202d24 <page_remove>
    return pa2page(PTE_ADDR(pte)); // 提取页表项的物理地址并转换为 Page 结构体指针
}

// 根据页目录项 (PDE) 获取对应的 Page 结构体指针
static inline struct Page *pde2page(pde_t pde) {
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc0200f54:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0200f58:	00010717          	auipc	a4,0x10
ffffffffc0200f5c:	5f873703          	ld	a4,1528(a4) # ffffffffc0211550 <npage>
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc0200f60:	078a                	slli	a5,a5,0x2
ffffffffc0200f62:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0200f64:	26e7f663          	bgeu	a5,a4,ffffffffc02011d0 <vmm_init+0x540>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc0200f68:	00005717          	auipc	a4,0x5
ffffffffc0200f6c:	21873703          	ld	a4,536(a4) # ffffffffc0206180 <nbase>
ffffffffc0200f70:	8f99                	sub	a5,a5,a4
ffffffffc0200f72:	00379713          	slli	a4,a5,0x3
ffffffffc0200f76:	97ba                	add	a5,a5,a4
ffffffffc0200f78:	078e                	slli	a5,a5,0x3

    // 释放页目录中的第一个页表页面
    free_page(pde2page(pgdir[0]));
ffffffffc0200f7a:	00010517          	auipc	a0,0x10
ffffffffc0200f7e:	5de53503          	ld	a0,1502(a0) # ffffffffc0211558 <pages>
ffffffffc0200f82:	953e                	add	a0,a0,a5
ffffffffc0200f84:	4585                	li	a1,1
ffffffffc0200f86:	2d5010ef          	jal	ra,ffffffffc0202a5a <free_pages>
    return listelm->next;
ffffffffc0200f8a:	6408                	ld	a0,8(s0)

    // 将页目录的第一个条目设置为0
    pgdir[0] = 0;
ffffffffc0200f8c:	00093023          	sd	zero,0(s2)

    // 将内存管理结构体的页目录指针设置为NULL
    mm->pgdir = NULL;
ffffffffc0200f90:	00043c23          	sd	zero,24(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0200f94:	00a40e63          	beq	s0,a0,ffffffffc0200fb0 <vmm_init+0x320>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200f98:	6118                	ld	a4,0(a0)
ffffffffc0200f9a:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link),sizeof(struct vma_struct));  
ffffffffc0200f9c:	03000593          	li	a1,48
ffffffffc0200fa0:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0200fa2:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200fa4:	e398                	sd	a4,0(a5)
ffffffffc0200fa6:	463020ef          	jal	ra,ffffffffc0203c08 <kfree>
    return listelm->next;
ffffffffc0200faa:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0200fac:	fea416e3          	bne	s0,a0,ffffffffc0200f98 <vmm_init+0x308>
    kfree(mm, sizeof(struct mm_struct)); 
ffffffffc0200fb0:	03000593          	li	a1,48
ffffffffc0200fb4:	8522                	mv	a0,s0
ffffffffc0200fb6:	453020ef          	jal	ra,ffffffffc0203c08 <kfree>
    mm_destroy(mm);

    // 将检查用的内存管理结构体指针设置为NULL
    check_mm_struct = NULL;
    // Szx: Sv39第二级页表多占用了一个内存页，因此执行此操作
    nr_free_pages_store--;
ffffffffc0200fba:	14fd                	addi	s1,s1,-1
    check_mm_struct = NULL;
ffffffffc0200fbc:	00010797          	auipc	a5,0x10
ffffffffc0200fc0:	5407ba23          	sd	zero,1364(a5) # ffffffffc0211510 <check_mm_struct>

    // 断言空闲页面数没有变化，确保上面的操作没有影响内存分配
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0200fc4:	2d7010ef          	jal	ra,ffffffffc0202a9a <nr_free_pages>
ffffffffc0200fc8:	22a49063          	bne	s1,a0,ffffffffc02011e8 <vmm_init+0x558>

    // 打印检查成功的消息
    cprintf("check_pgfault() succeeded!\n");
ffffffffc0200fcc:	00004517          	auipc	a0,0x4
ffffffffc0200fd0:	ffc50513          	addi	a0,a0,-4 # ffffffffc0204fc8 <commands+0x9a8>
ffffffffc0200fd4:	8e6ff0ef          	jal	ra,ffffffffc02000ba <cprintf>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0200fd8:	2c3010ef          	jal	ra,ffffffffc0202a9a <nr_free_pages>
    nr_free_pages_store--;	
ffffffffc0200fdc:	19fd                	addi	s3,s3,-1
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0200fde:	22a99563          	bne	s3,a0,ffffffffc0201208 <vmm_init+0x578>
}
ffffffffc0200fe2:	6406                	ld	s0,64(sp)
ffffffffc0200fe4:	60a6                	ld	ra,72(sp)
ffffffffc0200fe6:	74e2                	ld	s1,56(sp)
ffffffffc0200fe8:	7942                	ld	s2,48(sp)
ffffffffc0200fea:	79a2                	ld	s3,40(sp)
ffffffffc0200fec:	7a02                	ld	s4,32(sp)
ffffffffc0200fee:	6ae2                	ld	s5,24(sp)
ffffffffc0200ff0:	6b42                	ld	s6,16(sp)
ffffffffc0200ff2:	6ba2                	ld	s7,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0200ff4:	00004517          	auipc	a0,0x4
ffffffffc0200ff8:	ff450513          	addi	a0,a0,-12 # ffffffffc0204fe8 <commands+0x9c8>
}
ffffffffc0200ffc:	6161                	addi	sp,sp,80
    cprintf("check_vmm() succeeded.\n");
ffffffffc0200ffe:	8bcff06f          	j	ffffffffc02000ba <cprintf>
        if (swap_init_ok) swap_init_mm(mm); // 如果启用了交换空间，则初始化 mm 的交换空间
ffffffffc0201002:	19f000ef          	jal	ra,ffffffffc02019a0 <swap_init_mm>
ffffffffc0201006:	b5d1                	j	ffffffffc0200eca <vmm_init+0x23a>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0201008:	00004697          	auipc	a3,0x4
ffffffffc020100c:	de068693          	addi	a3,a3,-544 # ffffffffc0204de8 <commands+0x7c8>
ffffffffc0201010:	00004617          	auipc	a2,0x4
ffffffffc0201014:	d3860613          	addi	a2,a2,-712 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201018:	0ff00593          	li	a1,255
ffffffffc020101c:	00004517          	auipc	a0,0x4
ffffffffc0201020:	d4450513          	addi	a0,a0,-700 # ffffffffc0204d60 <commands+0x740>
ffffffffc0201024:	8deff0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0201028:	00004697          	auipc	a3,0x4
ffffffffc020102c:	e7868693          	addi	a3,a3,-392 # ffffffffc0204ea0 <commands+0x880>
ffffffffc0201030:	00004617          	auipc	a2,0x4
ffffffffc0201034:	d1860613          	addi	a2,a2,-744 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201038:	11100593          	li	a1,273
ffffffffc020103c:	00004517          	auipc	a0,0x4
ffffffffc0201040:	d2450513          	addi	a0,a0,-732 # ffffffffc0204d60 <commands+0x740>
ffffffffc0201044:	8beff0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0201048:	00004697          	auipc	a3,0x4
ffffffffc020104c:	e2868693          	addi	a3,a3,-472 # ffffffffc0204e70 <commands+0x850>
ffffffffc0201050:	00004617          	auipc	a2,0x4
ffffffffc0201054:	cf860613          	addi	a2,a2,-776 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201058:	11000593          	li	a1,272
ffffffffc020105c:	00004517          	auipc	a0,0x4
ffffffffc0201060:	d0450513          	addi	a0,a0,-764 # ffffffffc0204d60 <commands+0x740>
ffffffffc0201064:	89eff0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0201068:	00004697          	auipc	a3,0x4
ffffffffc020106c:	d6868693          	addi	a3,a3,-664 # ffffffffc0204dd0 <commands+0x7b0>
ffffffffc0201070:	00004617          	auipc	a2,0x4
ffffffffc0201074:	cd860613          	addi	a2,a2,-808 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201078:	0fc00593          	li	a1,252
ffffffffc020107c:	00004517          	auipc	a0,0x4
ffffffffc0201080:	ce450513          	addi	a0,a0,-796 # ffffffffc0204d60 <commands+0x740>
ffffffffc0201084:	87eff0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma1 != NULL);
ffffffffc0201088:	00004697          	auipc	a3,0x4
ffffffffc020108c:	d9868693          	addi	a3,a3,-616 # ffffffffc0204e20 <commands+0x800>
ffffffffc0201090:	00004617          	auipc	a2,0x4
ffffffffc0201094:	cb860613          	addi	a2,a2,-840 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201098:	10600593          	li	a1,262
ffffffffc020109c:	00004517          	auipc	a0,0x4
ffffffffc02010a0:	cc450513          	addi	a0,a0,-828 # ffffffffc0204d60 <commands+0x740>
ffffffffc02010a4:	85eff0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma2 != NULL);
ffffffffc02010a8:	00004697          	auipc	a3,0x4
ffffffffc02010ac:	d8868693          	addi	a3,a3,-632 # ffffffffc0204e30 <commands+0x810>
ffffffffc02010b0:	00004617          	auipc	a2,0x4
ffffffffc02010b4:	c9860613          	addi	a2,a2,-872 # ffffffffc0204d48 <commands+0x728>
ffffffffc02010b8:	10800593          	li	a1,264
ffffffffc02010bc:	00004517          	auipc	a0,0x4
ffffffffc02010c0:	ca450513          	addi	a0,a0,-860 # ffffffffc0204d60 <commands+0x740>
ffffffffc02010c4:	83eff0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma3 == NULL);
ffffffffc02010c8:	00004697          	auipc	a3,0x4
ffffffffc02010cc:	d7868693          	addi	a3,a3,-648 # ffffffffc0204e40 <commands+0x820>
ffffffffc02010d0:	00004617          	auipc	a2,0x4
ffffffffc02010d4:	c7860613          	addi	a2,a2,-904 # ffffffffc0204d48 <commands+0x728>
ffffffffc02010d8:	10a00593          	li	a1,266
ffffffffc02010dc:	00004517          	auipc	a0,0x4
ffffffffc02010e0:	c8450513          	addi	a0,a0,-892 # ffffffffc0204d60 <commands+0x740>
ffffffffc02010e4:	81eff0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma4 == NULL);
ffffffffc02010e8:	00004697          	auipc	a3,0x4
ffffffffc02010ec:	d6868693          	addi	a3,a3,-664 # ffffffffc0204e50 <commands+0x830>
ffffffffc02010f0:	00004617          	auipc	a2,0x4
ffffffffc02010f4:	c5860613          	addi	a2,a2,-936 # ffffffffc0204d48 <commands+0x728>
ffffffffc02010f8:	10c00593          	li	a1,268
ffffffffc02010fc:	00004517          	auipc	a0,0x4
ffffffffc0201100:	c6450513          	addi	a0,a0,-924 # ffffffffc0204d60 <commands+0x740>
ffffffffc0201104:	ffffe0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(vma5 == NULL);
ffffffffc0201108:	00004697          	auipc	a3,0x4
ffffffffc020110c:	d5868693          	addi	a3,a3,-680 # ffffffffc0204e60 <commands+0x840>
ffffffffc0201110:	00004617          	auipc	a2,0x4
ffffffffc0201114:	c3860613          	addi	a2,a2,-968 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201118:	10e00593          	li	a1,270
ffffffffc020111c:	00004517          	auipc	a0,0x4
ffffffffc0201120:	c4450513          	addi	a0,a0,-956 # ffffffffc0204d60 <commands+0x740>
ffffffffc0201124:	fdffe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0201128:	00004697          	auipc	a3,0x4
ffffffffc020112c:	e3068693          	addi	a3,a3,-464 # ffffffffc0204f58 <commands+0x938>
ffffffffc0201130:	00004617          	auipc	a2,0x4
ffffffffc0201134:	c1860613          	addi	a2,a2,-1000 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201138:	13700593          	li	a1,311
ffffffffc020113c:	00004517          	auipc	a0,0x4
ffffffffc0201140:	c2450513          	addi	a0,a0,-988 # ffffffffc0204d60 <commands+0x740>
ffffffffc0201144:	fbffe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc0201148:	00004697          	auipc	a3,0x4
ffffffffc020114c:	ec868693          	addi	a3,a3,-312 # ffffffffc0205010 <commands+0x9f0>
ffffffffc0201150:	00004617          	auipc	a2,0x4
ffffffffc0201154:	bf860613          	addi	a2,a2,-1032 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201158:	13200593          	li	a1,306
ffffffffc020115c:	00004517          	auipc	a0,0x4
ffffffffc0201160:	c0450513          	addi	a0,a0,-1020 # ffffffffc0204d60 <commands+0x740>
    check_mm_struct = mm_create();
ffffffffc0201164:	00010797          	auipc	a5,0x10
ffffffffc0201168:	3a07b623          	sd	zero,940(a5) # ffffffffc0211510 <check_mm_struct>
    assert(check_mm_struct != NULL);
ffffffffc020116c:	f97fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(vma != NULL);
ffffffffc0201170:	00004697          	auipc	a3,0x4
ffffffffc0201174:	e9068693          	addi	a3,a3,-368 # ffffffffc0205000 <commands+0x9e0>
ffffffffc0201178:	00004617          	auipc	a2,0x4
ffffffffc020117c:	bd060613          	addi	a2,a2,-1072 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201180:	13c00593          	li	a1,316
ffffffffc0201184:	00004517          	auipc	a0,0x4
ffffffffc0201188:	bdc50513          	addi	a0,a0,-1060 # ffffffffc0204d60 <commands+0x740>
ffffffffc020118c:	f77fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0201190:	00004697          	auipc	a3,0x4
ffffffffc0201194:	dd868693          	addi	a3,a3,-552 # ffffffffc0204f68 <commands+0x948>
ffffffffc0201198:	00004617          	auipc	a2,0x4
ffffffffc020119c:	bb060613          	addi	a2,a2,-1104 # ffffffffc0204d48 <commands+0x728>
ffffffffc02011a0:	14400593          	li	a1,324
ffffffffc02011a4:	00004517          	auipc	a0,0x4
ffffffffc02011a8:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0204d60 <commands+0x740>
ffffffffc02011ac:	f57fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(sum == 0);
ffffffffc02011b0:	00004697          	auipc	a3,0x4
ffffffffc02011b4:	dd868693          	addi	a3,a3,-552 # ffffffffc0204f88 <commands+0x968>
ffffffffc02011b8:	00004617          	auipc	a2,0x4
ffffffffc02011bc:	b9060613          	addi	a2,a2,-1136 # ffffffffc0204d48 <commands+0x728>
ffffffffc02011c0:	15000593          	li	a1,336
ffffffffc02011c4:	00004517          	auipc	a0,0x4
ffffffffc02011c8:	b9c50513          	addi	a0,a0,-1124 # ffffffffc0204d60 <commands+0x740>
ffffffffc02011cc:	f37fe0ef          	jal	ra,ffffffffc0200102 <__panic>
        panic("pa2page called with invalid pa"); // 如果无效，触发 panic
ffffffffc02011d0:	00004617          	auipc	a2,0x4
ffffffffc02011d4:	dc860613          	addi	a2,a2,-568 # ffffffffc0204f98 <commands+0x978>
ffffffffc02011d8:	07000593          	li	a1,112
ffffffffc02011dc:	00004517          	auipc	a0,0x4
ffffffffc02011e0:	ddc50513          	addi	a0,a0,-548 # ffffffffc0204fb8 <commands+0x998>
ffffffffc02011e4:	f1ffe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02011e8:	00004697          	auipc	a3,0x4
ffffffffc02011ec:	d2868693          	addi	a3,a3,-728 # ffffffffc0204f10 <commands+0x8f0>
ffffffffc02011f0:	00004617          	auipc	a2,0x4
ffffffffc02011f4:	b5860613          	addi	a2,a2,-1192 # ffffffffc0204d48 <commands+0x728>
ffffffffc02011f8:	16600593          	li	a1,358
ffffffffc02011fc:	00004517          	auipc	a0,0x4
ffffffffc0201200:	b6450513          	addi	a0,a0,-1180 # ffffffffc0204d60 <commands+0x740>
ffffffffc0201204:	efffe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0201208:	00004697          	auipc	a3,0x4
ffffffffc020120c:	d0868693          	addi	a3,a3,-760 # ffffffffc0204f10 <commands+0x8f0>
ffffffffc0201210:	00004617          	auipc	a2,0x4
ffffffffc0201214:	b3860613          	addi	a2,a2,-1224 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201218:	0d200593          	li	a1,210
ffffffffc020121c:	00004517          	auipc	a0,0x4
ffffffffc0201220:	b4450513          	addi	a0,a0,-1212 # ffffffffc0204d60 <commands+0x740>
ffffffffc0201224:	edffe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(mm != NULL);
ffffffffc0201228:	00004697          	auipc	a3,0x4
ffffffffc020122c:	e0068693          	addi	a3,a3,-512 # ffffffffc0205028 <commands+0xa08>
ffffffffc0201230:	00004617          	auipc	a2,0x4
ffffffffc0201234:	b1860613          	addi	a2,a2,-1256 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201238:	0e000593          	li	a1,224
ffffffffc020123c:	00004517          	auipc	a0,0x4
ffffffffc0201240:	b2450513          	addi	a0,a0,-1244 # ffffffffc0204d60 <commands+0x740>
ffffffffc0201244:	ebffe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0201248:	00004697          	auipc	a3,0x4
ffffffffc020124c:	cc868693          	addi	a3,a3,-824 # ffffffffc0204f10 <commands+0x8f0>
ffffffffc0201250:	00004617          	auipc	a2,0x4
ffffffffc0201254:	af860613          	addi	a2,a2,-1288 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201258:	12100593          	li	a1,289
ffffffffc020125c:	00004517          	auipc	a0,0x4
ffffffffc0201260:	b0450513          	addi	a0,a0,-1276 # ffffffffc0204d60 <commands+0x740>
ffffffffc0201264:	e9ffe0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0201268 <do_pgfault>:
 *   - P 位（位 0）：表示页面不在（0）或访问权限错误（1）
 *   - W/R 位（位 1）：标识引发异常的内存访问是读取（0）还是写入（1）
 *   - U/S 位（位 2）：标识异常发生时是否在用户模式（1）或 supervisor 模式（0）
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc0201268:	7179                	addi	sp,sp,-48
    int ret = -E_INVAL;
    // 尝试找到一个包含 addr 的 vma
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc020126a:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc020126c:	f022                	sd	s0,32(sp)
ffffffffc020126e:	ec26                	sd	s1,24(sp)
ffffffffc0201270:	f406                	sd	ra,40(sp)
ffffffffc0201272:	e84a                	sd	s2,16(sp)
ffffffffc0201274:	8432                	mv	s0,a2
ffffffffc0201276:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0201278:	8d3ff0ef          	jal	ra,ffffffffc0200b4a <find_vma>

    pgfault_num++;
ffffffffc020127c:	00010797          	auipc	a5,0x10
ffffffffc0201280:	29c7a783          	lw	a5,668(a5) # ffffffffc0211518 <pgfault_num>
ffffffffc0201284:	2785                	addiw	a5,a5,1
ffffffffc0201286:	00010717          	auipc	a4,0x10
ffffffffc020128a:	28f72923          	sw	a5,658(a4) # ffffffffc0211518 <pgfault_num>
    // 如果 addr 在 mm 的某个 vma 范围内？
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc020128e:	c159                	beqz	a0,ffffffffc0201314 <do_pgfault+0xac>
ffffffffc0201290:	651c                	ld	a5,8(a0)
ffffffffc0201292:	08f46163          	bltu	s0,a5,ffffffffc0201314 <do_pgfault+0xac>
    /*
     * 根据 vma 的标志，设置页表权限位 perm
     * 若 vma 可写，则权限包含 PTE_W；否则仅包含 PTE_R 和 PTE_U
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0201296:	6d1c                	ld	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc0201298:	4941                	li	s2,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc020129a:	8b89                	andi	a5,a5,2
ffffffffc020129c:	ebb1                	bnez	a5,ffffffffc02012f0 <do_pgfault+0x88>
        perm |= (PTE_R | PTE_W);
    }
    addr = ROUNDDOWN(addr, PGSIZE);// 将 addr 对齐到页边界
ffffffffc020129e:	75fd                	lui	a1,0xfffff
    *   PTE_U           0x004                   // 页表/目录项标志位：用户可访问
    * 变量：
    *   mm->pgdir : 这些 vma 的 PDT
    */

    ptep = get_pte(mm->pgdir, addr, 1); //尝试找到一个 pte，如果 pte 的PT（页表）不存在，则创建一个 PT。
ffffffffc02012a0:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);// 将 addr 对齐到页边界
ffffffffc02012a2:	8c6d                	and	s0,s0,a1
    ptep = get_pte(mm->pgdir, addr, 1); //尝试找到一个 pte，如果 pte 的PT（页表）不存在，则创建一个 PT。
ffffffffc02012a4:	85a2                	mv	a1,s0
ffffffffc02012a6:	4605                	li	a2,1
ffffffffc02012a8:	02d010ef          	jal	ra,ffffffffc0202ad4 <get_pte>
    if (*ptep == 0) {// 如果 pte 尚未映射任何页面
ffffffffc02012ac:	610c                	ld	a1,0(a0)
ffffffffc02012ae:	c1b9                	beqz	a1,ffffffffc02012f4 <do_pgfault+0x8c>
        * 宏或函数：
        *    swap_in(mm, addr, &page) : 分配一个内存页，从PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个 Page 的 phy addr 与线性 addr la 的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc02012b0:	00010797          	auipc	a5,0x10
ffffffffc02012b4:	2807a783          	lw	a5,640(a5) # ffffffffc0211530 <swap_init_ok>
ffffffffc02012b8:	c7bd                	beqz	a5,ffffffffc0201326 <do_pgfault+0xbe>
            struct Page *page = NULL;
            // 你要编写的内容在这里
            // (1) 根据 mm 和 addr，尝试加载磁盘页的内容到由 page 管理的内存中。
            swap_in(mm,addr,&page);//调用swap_in函数从磁盘上读取数据
ffffffffc02012ba:	85a2                	mv	a1,s0
ffffffffc02012bc:	0030                	addi	a2,sp,8
ffffffffc02012be:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc02012c0:	e402                	sd	zero,8(sp)
            swap_in(mm,addr,&page);//调用swap_in函数从磁盘上读取数据
ffffffffc02012c2:	00b000ef          	jal	ra,ffffffffc0201acc <swap_in>
            // (2) 根据 mm，addr 和 page，设置物理地址 phy addr 与逻辑地址的映射
            // (3) 使页面可交换。交换成功，则建立物理地址<--->虚拟地址映射，并将页设置为可交换的
            page_insert(mm->pgdir, page, addr, perm);
ffffffffc02012c6:	65a2                	ld	a1,8(sp)
ffffffffc02012c8:	6c88                	ld	a0,24(s1)
ffffffffc02012ca:	86ca                	mv	a3,s2
ffffffffc02012cc:	8622                	mv	a2,s0
ffffffffc02012ce:	2f1010ef          	jal	ra,ffffffffc0202dbe <page_insert>
            swap_map_swappable(mm, addr, page, 1);//将物理页设置为可交换状态
ffffffffc02012d2:	6622                	ld	a2,8(sp)
ffffffffc02012d4:	4685                	li	a3,1
ffffffffc02012d6:	85a2                	mv	a1,s0
ffffffffc02012d8:	8526                	mv	a0,s1
ffffffffc02012da:	6d2000ef          	jal	ra,ffffffffc02019ac <swap_map_swappable>
            page->pra_vaddr = addr;
ffffffffc02012de:	67a2                	ld	a5,8(sp)
        } else {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
    }
    ret = 0;
ffffffffc02012e0:	4501                	li	a0,0
            page->pra_vaddr = addr;
ffffffffc02012e2:	e3a0                	sd	s0,64(a5)
failed:
    return ret;
}
ffffffffc02012e4:	70a2                	ld	ra,40(sp)
ffffffffc02012e6:	7402                	ld	s0,32(sp)
ffffffffc02012e8:	64e2                	ld	s1,24(sp)
ffffffffc02012ea:	6942                	ld	s2,16(sp)
ffffffffc02012ec:	6145                	addi	sp,sp,48
ffffffffc02012ee:	8082                	ret
        perm |= (PTE_R | PTE_W);
ffffffffc02012f0:	4959                	li	s2,22
ffffffffc02012f2:	b775                	j	ffffffffc020129e <do_pgfault+0x36>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) { // 分配新页面并映射
ffffffffc02012f4:	6c88                	ld	a0,24(s1)
ffffffffc02012f6:	864a                	mv	a2,s2
ffffffffc02012f8:	85a2                	mv	a1,s0
ffffffffc02012fa:	79c020ef          	jal	ra,ffffffffc0203a96 <pgdir_alloc_page>
ffffffffc02012fe:	87aa                	mv	a5,a0
    ret = 0;
ffffffffc0201300:	4501                	li	a0,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) { // 分配新页面并映射
ffffffffc0201302:	f3ed                	bnez	a5,ffffffffc02012e4 <do_pgfault+0x7c>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0201304:	00004517          	auipc	a0,0x4
ffffffffc0201308:	d6450513          	addi	a0,a0,-668 # ffffffffc0205068 <commands+0xa48>
ffffffffc020130c:	daffe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    ret = -E_NO_MEM; // 若内存不足时返回该错误
ffffffffc0201310:	5571                	li	a0,-4
            goto failed;
ffffffffc0201312:	bfc9                	j	ffffffffc02012e4 <do_pgfault+0x7c>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc0201314:	85a2                	mv	a1,s0
ffffffffc0201316:	00004517          	auipc	a0,0x4
ffffffffc020131a:	d2250513          	addi	a0,a0,-734 # ffffffffc0205038 <commands+0xa18>
ffffffffc020131e:	d9dfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    int ret = -E_INVAL;
ffffffffc0201322:	5575                	li	a0,-3
        goto failed;
ffffffffc0201324:	b7c1                	j	ffffffffc02012e4 <do_pgfault+0x7c>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0201326:	00004517          	auipc	a0,0x4
ffffffffc020132a:	d6a50513          	addi	a0,a0,-662 # ffffffffc0205090 <commands+0xa70>
ffffffffc020132e:	d8dfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    ret = -E_NO_MEM; // 若内存不足时返回该错误
ffffffffc0201332:	5571                	li	a0,-4
            goto failed;
ffffffffc0201334:	bf45                	j	ffffffffc02012e4 <do_pgfault+0x7c>

ffffffffc0201336 <swap_init>:

static void check_swap(void); // 声明检查交换的静态函数

int
swap_init(void)
{
ffffffffc0201336:	7135                	addi	sp,sp,-160
ffffffffc0201338:	ed06                	sd	ra,152(sp)
ffffffffc020133a:	e922                	sd	s0,144(sp)
ffffffffc020133c:	e526                	sd	s1,136(sp)
ffffffffc020133e:	e14a                	sd	s2,128(sp)
ffffffffc0201340:	fcce                	sd	s3,120(sp)
ffffffffc0201342:	f8d2                	sd	s4,112(sp)
ffffffffc0201344:	f4d6                	sd	s5,104(sp)
ffffffffc0201346:	f0da                	sd	s6,96(sp)
ffffffffc0201348:	ecde                	sd	s7,88(sp)
ffffffffc020134a:	e8e2                	sd	s8,80(sp)
ffffffffc020134c:	e4e6                	sd	s9,72(sp)
ffffffffc020134e:	e0ea                	sd	s10,64(sp)
ffffffffc0201350:	fc6e                	sd	s11,56(sp)
     swapfs_init(); // 初始化交换文件系统
ffffffffc0201352:	19f020ef          	jal	ra,ffffffffc0203cf0 <swapfs_init>

     // 检查交换偏移量是否能够在模拟的IDE中存储至少7个页面以通过测试
     if (!(7 <= max_swap_offset &&
ffffffffc0201356:	00010697          	auipc	a3,0x10
ffffffffc020135a:	1ca6b683          	ld	a3,458(a3) # ffffffffc0211520 <max_swap_offset>
ffffffffc020135e:	010007b7          	lui	a5,0x1000
ffffffffc0201362:	ff968713          	addi	a4,a3,-7
ffffffffc0201366:	17e1                	addi	a5,a5,-8
ffffffffc0201368:	3ee7e063          	bltu	a5,a4,ffffffffc0201748 <swap_init+0x412>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset); // 如果不在预期范围内，触发panic
     }

     sm = &swap_manager_clock; // 设置交换管理器为clock替换算法
ffffffffc020136c:	00009797          	auipc	a5,0x9
ffffffffc0201370:	c9478793          	addi	a5,a5,-876 # ffffffffc020a000 <swap_manager_clock>
     int r = sm->init(); // 调用交换管理器的初始化函数
ffffffffc0201374:	6798                	ld	a4,8(a5)
     sm = &swap_manager_clock; // 设置交换管理器为clock替换算法
ffffffffc0201376:	00010b17          	auipc	s6,0x10
ffffffffc020137a:	1b2b0b13          	addi	s6,s6,434 # ffffffffc0211528 <sm>
ffffffffc020137e:	00fb3023          	sd	a5,0(s6)
     int r = sm->init(); // 调用交换管理器的初始化函数
ffffffffc0201382:	9702                	jalr	a4
ffffffffc0201384:	89aa                	mv	s3,a0
     
     if (r == 0) // 如果初始化成功
ffffffffc0201386:	c10d                	beqz	a0,ffffffffc02013a8 <swap_init+0x72>
          cprintf("SWAP: manager = %s\n", sm->name); // 打印交换管理器的名称
          check_swap(); // 调用检查交换的函数
     }

     return r; // 返回初始化结果
}
ffffffffc0201388:	60ea                	ld	ra,152(sp)
ffffffffc020138a:	644a                	ld	s0,144(sp)
ffffffffc020138c:	64aa                	ld	s1,136(sp)
ffffffffc020138e:	690a                	ld	s2,128(sp)
ffffffffc0201390:	7a46                	ld	s4,112(sp)
ffffffffc0201392:	7aa6                	ld	s5,104(sp)
ffffffffc0201394:	7b06                	ld	s6,96(sp)
ffffffffc0201396:	6be6                	ld	s7,88(sp)
ffffffffc0201398:	6c46                	ld	s8,80(sp)
ffffffffc020139a:	6ca6                	ld	s9,72(sp)
ffffffffc020139c:	6d06                	ld	s10,64(sp)
ffffffffc020139e:	7de2                	ld	s11,56(sp)
ffffffffc02013a0:	854e                	mv	a0,s3
ffffffffc02013a2:	79e6                	ld	s3,120(sp)
ffffffffc02013a4:	610d                	addi	sp,sp,160
ffffffffc02013a6:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name); // 打印交换管理器的名称
ffffffffc02013a8:	000b3783          	ld	a5,0(s6)
ffffffffc02013ac:	00004517          	auipc	a0,0x4
ffffffffc02013b0:	d3c50513          	addi	a0,a0,-708 # ffffffffc02050e8 <commands+0xac8>
ffffffffc02013b4:	00010497          	auipc	s1,0x10
ffffffffc02013b8:	d2c48493          	addi	s1,s1,-724 # ffffffffc02110e0 <free_area>
ffffffffc02013bc:	638c                	ld	a1,0(a5)
          swap_init_ok = 1; // 设置交换初始化成功的全局标志
ffffffffc02013be:	4785                	li	a5,1
ffffffffc02013c0:	00010717          	auipc	a4,0x10
ffffffffc02013c4:	16f72823          	sw	a5,368(a4) # ffffffffc0211530 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name); // 打印交换管理器的名称
ffffffffc02013c8:	cf3fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc02013cc:	649c                	ld	a5,8(s1)

// 定义一个静态函数，用于检查页面交换机制是否正常工作
static void
check_swap(void) {
    // 备份当前内存环境
    int ret, count = 0, total = 0, i;
ffffffffc02013ce:	4401                	li	s0,0
ffffffffc02013d0:	4d01                	li	s10,0
    list_entry_t *le = &free_list; // 指向空闲页面链表的头部
    while ((le = list_next(le)) != &free_list) {
ffffffffc02013d2:	2c978163          	beq	a5,s1,ffffffffc0201694 <swap_init+0x35e>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02013d6:	fe87b703          	ld	a4,-24(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p)); // 确保页面属性正确
ffffffffc02013da:	8b09                	andi	a4,a4,2
ffffffffc02013dc:	2a070e63          	beqz	a4,ffffffffc0201698 <swap_init+0x362>
        count ++, total += p->property;
ffffffffc02013e0:	ff87a703          	lw	a4,-8(a5)
ffffffffc02013e4:	679c                	ld	a5,8(a5)
ffffffffc02013e6:	2d05                	addiw	s10,s10,1
ffffffffc02013e8:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02013ea:	fe9796e3          	bne	a5,s1,ffffffffc02013d6 <swap_init+0xa0>
    }
    assert(total == nr_free_pages()); // 确保空闲页面总数正确
ffffffffc02013ee:	8922                	mv	s2,s0
ffffffffc02013f0:	6aa010ef          	jal	ra,ffffffffc0202a9a <nr_free_pages>
ffffffffc02013f4:	47251663          	bne	a0,s2,ffffffffc0201860 <swap_init+0x52a>
    cprintf("BEGIN check_swap: count %d, total %d\n", count, total);
ffffffffc02013f8:	8622                	mv	a2,s0
ffffffffc02013fa:	85ea                	mv	a1,s10
ffffffffc02013fc:	00004517          	auipc	a0,0x4
ffffffffc0201400:	d3450513          	addi	a0,a0,-716 # ffffffffc0205130 <commands+0xb10>
ffffffffc0201404:	cb7fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
     
    // 设置物理页面环境
    struct mm_struct *mm = mm_create(); // 创建内存管理结构
ffffffffc0201408:	eccff0ef          	jal	ra,ffffffffc0200ad4 <mm_create>
ffffffffc020140c:	8aaa                	mv	s5,a0
    assert(mm != NULL);
ffffffffc020140e:	52050963          	beqz	a0,ffffffffc0201940 <swap_init+0x60a>

    extern struct mm_struct *check_mm_struct;
    assert(check_mm_struct == NULL); // 确保之前没有设置过检查用的内存管理结构
ffffffffc0201412:	00010797          	auipc	a5,0x10
ffffffffc0201416:	0fe78793          	addi	a5,a5,254 # ffffffffc0211510 <check_mm_struct>
ffffffffc020141a:	6398                	ld	a4,0(a5)
ffffffffc020141c:	54071263          	bnez	a4,ffffffffc0201960 <swap_init+0x62a>

    check_mm_struct = mm; // 设置当前的内存管理结构为检查用的内存管理结构

    pde_t *pgdir = mm->pgdir = boot_pgdir; // 设置页目录
ffffffffc0201420:	00010b97          	auipc	s7,0x10
ffffffffc0201424:	128bbb83          	ld	s7,296(s7) # ffffffffc0211548 <boot_pgdir>
    assert(pgdir[0] == 0); // 确保页目录的第一项是空的
ffffffffc0201428:	000bb703          	ld	a4,0(s7)
    check_mm_struct = mm; // 设置当前的内存管理结构为检查用的内存管理结构
ffffffffc020142c:	e388                	sd	a0,0(a5)
    pde_t *pgdir = mm->pgdir = boot_pgdir; // 设置页目录
ffffffffc020142e:	01753c23          	sd	s7,24(a0)
    assert(pgdir[0] == 0); // 确保页目录的第一项是空的
ffffffffc0201432:	3c071763          	bnez	a4,ffffffffc0201800 <swap_init+0x4ca>

    struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ); // 创建虚拟内存区域
ffffffffc0201436:	6599                	lui	a1,0x6
ffffffffc0201438:	460d                	li	a2,3
ffffffffc020143a:	6505                	lui	a0,0x1
ffffffffc020143c:	ee0ff0ef          	jal	ra,ffffffffc0200b1c <vma_create>
ffffffffc0201440:	85aa                	mv	a1,a0
    assert(vma != NULL);
ffffffffc0201442:	3c050f63          	beqz	a0,ffffffffc0201820 <swap_init+0x4ea>

    insert_vma_struct(mm, vma); // 将虚拟内存区域插入内存管理结构
ffffffffc0201446:	8556                	mv	a0,s5
ffffffffc0201448:	f42ff0ef          	jal	ra,ffffffffc0200b8a <insert_vma_struct>

    // 设置临时页表，用于虚拟地址0~4MB
    cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc020144c:	00004517          	auipc	a0,0x4
ffffffffc0201450:	d2450513          	addi	a0,a0,-732 # ffffffffc0205170 <commands+0xb50>
ffffffffc0201454:	c67fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    pte_t *temp_ptep = NULL;
    temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1); // 获取页表条目
ffffffffc0201458:	018ab503          	ld	a0,24(s5)
ffffffffc020145c:	4605                	li	a2,1
ffffffffc020145e:	6585                	lui	a1,0x1
ffffffffc0201460:	674010ef          	jal	ra,ffffffffc0202ad4 <get_pte>
    assert(temp_ptep != NULL); // 确保页表条目获取成功
ffffffffc0201464:	3c050e63          	beqz	a0,ffffffffc0201840 <swap_init+0x50a>
    cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0201468:	00004517          	auipc	a0,0x4
ffffffffc020146c:	d5850513          	addi	a0,a0,-680 # ffffffffc02051c0 <commands+0xba0>
ffffffffc0201470:	00010917          	auipc	s2,0x10
ffffffffc0201474:	c0090913          	addi	s2,s2,-1024 # ffffffffc0211070 <check_rp>
ffffffffc0201478:	c43fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
     
    for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
ffffffffc020147c:	00010a17          	auipc	s4,0x10
ffffffffc0201480:	c14a0a13          	addi	s4,s4,-1004 # ffffffffc0211090 <swap_in_seq_no>
    cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0201484:	8c4a                	mv	s8,s2
        check_rp[i] = alloc_page(); // 分配检查用的物理页面
ffffffffc0201486:	4505                	li	a0,1
ffffffffc0201488:	540010ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc020148c:	00ac3023          	sd	a0,0(s8)
        assert(check_rp[i] != NULL);
ffffffffc0201490:	28050c63          	beqz	a0,ffffffffc0201728 <swap_init+0x3f2>
ffffffffc0201494:	651c                	ld	a5,8(a0)
        assert(!PageProperty(check_rp[i])); // 确保页面属性正确
ffffffffc0201496:	8b89                	andi	a5,a5,2
ffffffffc0201498:	26079863          	bnez	a5,ffffffffc0201708 <swap_init+0x3d2>
    for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
ffffffffc020149c:	0c21                	addi	s8,s8,8
ffffffffc020149e:	ff4c14e3          	bne	s8,s4,ffffffffc0201486 <swap_init+0x150>
    }
    list_entry_t free_list_store = free_list; // 备份当前的空闲页面链表
ffffffffc02014a2:	609c                	ld	a5,0(s1)
ffffffffc02014a4:	0084bd83          	ld	s11,8(s1)
    elm->prev = elm->next = elm;
ffffffffc02014a8:	e084                	sd	s1,0(s1)
ffffffffc02014aa:	f03e                	sd	a5,32(sp)
    list_init(&free_list); // 初始化一个新的空闲页面链表
    assert(list_empty(&free_list)); // 确保新的空闲页面链表为空
     
     unsigned int nr_free_store = nr_free; // 备份当前的空闲页面数量
ffffffffc02014ac:	489c                	lw	a5,16(s1)
ffffffffc02014ae:	e484                	sd	s1,8(s1)
     nr_free = 0; // 设置当前的空闲页面数量为0
ffffffffc02014b0:	00010c17          	auipc	s8,0x10
ffffffffc02014b4:	bc0c0c13          	addi	s8,s8,-1088 # ffffffffc0211070 <check_rp>
     unsigned int nr_free_store = nr_free; // 备份当前的空闲页面数量
ffffffffc02014b8:	f43e                	sd	a5,40(sp)
     nr_free = 0; // 设置当前的空闲页面数量为0
ffffffffc02014ba:	00010797          	auipc	a5,0x10
ffffffffc02014be:	c207ab23          	sw	zero,-970(a5) # ffffffffc02110f0 <free_area+0x10>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
        free_pages(check_rp[i], 1); // 将检查用的物理页面标记为空闲
ffffffffc02014c2:	000c3503          	ld	a0,0(s8)
ffffffffc02014c6:	4585                	li	a1,1
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
ffffffffc02014c8:	0c21                	addi	s8,s8,8
        free_pages(check_rp[i], 1); // 将检查用的物理页面标记为空闲
ffffffffc02014ca:	590010ef          	jal	ra,ffffffffc0202a5a <free_pages>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
ffffffffc02014ce:	ff4c1ae3          	bne	s8,s4,ffffffffc02014c2 <swap_init+0x18c>
     }
     assert(nr_free == CHECK_VALID_PHY_PAGE_NUM); // 确保空闲页面数量正确
ffffffffc02014d2:	0104ac03          	lw	s8,16(s1)
ffffffffc02014d6:	4791                	li	a5,4
ffffffffc02014d8:	4afc1463          	bne	s8,a5,ffffffffc0201980 <swap_init+0x64a>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc02014dc:	00004517          	auipc	a0,0x4
ffffffffc02014e0:	d6c50513          	addi	a0,a0,-660 # ffffffffc0205248 <commands+0xc28>
ffffffffc02014e4:	bd7fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc02014e8:	6605                	lui	a2,0x1
     // 设置初始的虚拟页面<->物理页面环境，用于页面替换算法的测试

     pgfault_num = 0; // 页面错误次数置0
ffffffffc02014ea:	00010797          	auipc	a5,0x10
ffffffffc02014ee:	0207a723          	sw	zero,46(a5) # ffffffffc0211518 <pgfault_num>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc02014f2:	4529                	li	a0,10
ffffffffc02014f4:	00a60023          	sb	a0,0(a2) # 1000 <kern_entry-0xffffffffc01ff000>
    assert(pgfault_num==1);
ffffffffc02014f8:	00010597          	auipc	a1,0x10
ffffffffc02014fc:	0205a583          	lw	a1,32(a1) # ffffffffc0211518 <pgfault_num>
ffffffffc0201500:	4805                	li	a6,1
ffffffffc0201502:	00010797          	auipc	a5,0x10
ffffffffc0201506:	01678793          	addi	a5,a5,22 # ffffffffc0211518 <pgfault_num>
ffffffffc020150a:	3f059b63          	bne	a1,a6,ffffffffc0201900 <swap_init+0x5ca>
    *(unsigned char *)0x1010 = 0x0a;
ffffffffc020150e:	00a60823          	sb	a0,16(a2)
    assert(pgfault_num==1);
ffffffffc0201512:	4390                	lw	a2,0(a5)
ffffffffc0201514:	2601                	sext.w	a2,a2
ffffffffc0201516:	40b61563          	bne	a2,a1,ffffffffc0201920 <swap_init+0x5ea>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc020151a:	6589                	lui	a1,0x2
ffffffffc020151c:	452d                	li	a0,11
ffffffffc020151e:	00a58023          	sb	a0,0(a1) # 2000 <kern_entry-0xffffffffc01fe000>
    assert(pgfault_num==2);
ffffffffc0201522:	4390                	lw	a2,0(a5)
ffffffffc0201524:	4809                	li	a6,2
ffffffffc0201526:	2601                	sext.w	a2,a2
ffffffffc0201528:	35061c63          	bne	a2,a6,ffffffffc0201880 <swap_init+0x54a>
    *(unsigned char *)0x2010 = 0x0b;
ffffffffc020152c:	00a58823          	sb	a0,16(a1)
    assert(pgfault_num==2);
ffffffffc0201530:	438c                	lw	a1,0(a5)
ffffffffc0201532:	2581                	sext.w	a1,a1
ffffffffc0201534:	36c59663          	bne	a1,a2,ffffffffc02018a0 <swap_init+0x56a>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0201538:	658d                	lui	a1,0x3
ffffffffc020153a:	4531                	li	a0,12
ffffffffc020153c:	00a58023          	sb	a0,0(a1) # 3000 <kern_entry-0xffffffffc01fd000>
    assert(pgfault_num==3);
ffffffffc0201540:	4390                	lw	a2,0(a5)
ffffffffc0201542:	480d                	li	a6,3
ffffffffc0201544:	2601                	sext.w	a2,a2
ffffffffc0201546:	37061d63          	bne	a2,a6,ffffffffc02018c0 <swap_init+0x58a>
    *(unsigned char *)0x3010 = 0x0c;
ffffffffc020154a:	00a58823          	sb	a0,16(a1)
    assert(pgfault_num==3);
ffffffffc020154e:	438c                	lw	a1,0(a5)
ffffffffc0201550:	2581                	sext.w	a1,a1
ffffffffc0201552:	38c59763          	bne	a1,a2,ffffffffc02018e0 <swap_init+0x5aa>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0201556:	6591                	lui	a1,0x4
ffffffffc0201558:	4535                	li	a0,13
ffffffffc020155a:	00a58023          	sb	a0,0(a1) # 4000 <kern_entry-0xffffffffc01fc000>
    assert(pgfault_num==4);
ffffffffc020155e:	4390                	lw	a2,0(a5)
ffffffffc0201560:	2601                	sext.w	a2,a2
ffffffffc0201562:	21861f63          	bne	a2,s8,ffffffffc0201780 <swap_init+0x44a>
    *(unsigned char *)0x4010 = 0x0d;
ffffffffc0201566:	00a58823          	sb	a0,16(a1)
    assert(pgfault_num==4);
ffffffffc020156a:	439c                	lw	a5,0(a5)
ffffffffc020156c:	2781                	sext.w	a5,a5
ffffffffc020156e:	22c79963          	bne	a5,a2,ffffffffc02017a0 <swap_init+0x46a>
     
     check_content_set(); // 设置页面内容，触发页面错误
     assert(nr_free == 0); // 确保没有空闲页面
ffffffffc0201572:	489c                	lw	a5,16(s1)
ffffffffc0201574:	24079663          	bnez	a5,ffffffffc02017c0 <swap_init+0x48a>
ffffffffc0201578:	00010797          	auipc	a5,0x10
ffffffffc020157c:	b1878793          	addi	a5,a5,-1256 # ffffffffc0211090 <swap_in_seq_no>
ffffffffc0201580:	00010617          	auipc	a2,0x10
ffffffffc0201584:	b3860613          	addi	a2,a2,-1224 # ffffffffc02110b8 <swap_out_seq_no>
ffffffffc0201588:	00010517          	auipc	a0,0x10
ffffffffc020158c:	b3050513          	addi	a0,a0,-1232 # ffffffffc02110b8 <swap_out_seq_no>
         
     for(i = 0; i < MAX_SEQ_NO; i++) // 初始化交换进出序列编号数组
         swap_out_seq_no[i] = swap_in_seq_no[i] = -1;
ffffffffc0201590:	55fd                	li	a1,-1
ffffffffc0201592:	c38c                	sw	a1,0(a5)
ffffffffc0201594:	c20c                	sw	a1,0(a2)
     for(i = 0; i < MAX_SEQ_NO; i++) // 初始化交换进出序列编号数组
ffffffffc0201596:	0791                	addi	a5,a5,4
ffffffffc0201598:	0611                	addi	a2,a2,4
ffffffffc020159a:	fef51ce3          	bne	a0,a5,ffffffffc0201592 <swap_init+0x25c>
ffffffffc020159e:	00010817          	auipc	a6,0x10
ffffffffc02015a2:	ab280813          	addi	a6,a6,-1358 # ffffffffc0211050 <check_ptep>
ffffffffc02015a6:	00010897          	auipc	a7,0x10
ffffffffc02015aa:	aca88893          	addi	a7,a7,-1334 # ffffffffc0211070 <check_rp>
ffffffffc02015ae:	6585                	lui	a1,0x1
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc02015b0:	00010c97          	auipc	s9,0x10
ffffffffc02015b4:	fa8c8c93          	addi	s9,s9,-88 # ffffffffc0211558 <pages>
ffffffffc02015b8:	00005c17          	auipc	s8,0x5
ffffffffc02015bc:	bc8c0c13          	addi	s8,s8,-1080 # ffffffffc0206180 <nbase>
     
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
         check_ptep[i] = 0;
ffffffffc02015c0:	00083023          	sd	zero,0(a6)
         check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0); // 获取页表条目
ffffffffc02015c4:	4601                	li	a2,0
ffffffffc02015c6:	855e                	mv	a0,s7
ffffffffc02015c8:	ec46                	sd	a7,24(sp)
ffffffffc02015ca:	e82e                	sd	a1,16(sp)
         check_ptep[i] = 0;
ffffffffc02015cc:	e442                	sd	a6,8(sp)
         check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0); // 获取页表条目
ffffffffc02015ce:	506010ef          	jal	ra,ffffffffc0202ad4 <get_pte>
ffffffffc02015d2:	6822                	ld	a6,8(sp)
         assert(check_ptep[i] != NULL); // 确保页表条目获取成功
ffffffffc02015d4:	65c2                	ld	a1,16(sp)
ffffffffc02015d6:	68e2                	ld	a7,24(sp)
         check_ptep[i] = get_pte(pgdir, (i + 1) * 0x1000, 0); // 获取页表条目
ffffffffc02015d8:	00a83023          	sd	a0,0(a6)
         assert(check_ptep[i] != NULL); // 确保页表条目获取成功
ffffffffc02015dc:	00010317          	auipc	t1,0x10
ffffffffc02015e0:	f7430313          	addi	t1,t1,-140 # ffffffffc0211550 <npage>
ffffffffc02015e4:	16050e63          	beqz	a0,ffffffffc0201760 <swap_init+0x42a>
         assert(pte2page(*check_ptep[i]) == check_rp[i]); // 确保页表条目指向正确的物理页面
ffffffffc02015e8:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) { // 检查 PTE 是否有效
ffffffffc02015ea:	0017f613          	andi	a2,a5,1
ffffffffc02015ee:	0e060563          	beqz	a2,ffffffffc02016d8 <swap_init+0x3a2>
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc02015f2:	00033603          	ld	a2,0(t1)
    return pa2page(PTE_ADDR(pte)); // 提取页表项的物理地址并转换为 Page 结构体指针
ffffffffc02015f6:	078a                	slli	a5,a5,0x2
ffffffffc02015f8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc02015fa:	0ec7fb63          	bgeu	a5,a2,ffffffffc02016f0 <swap_init+0x3ba>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc02015fe:	000c3603          	ld	a2,0(s8)
ffffffffc0201602:	000cb503          	ld	a0,0(s9)
ffffffffc0201606:	0008bf03          	ld	t5,0(a7)
ffffffffc020160a:	8f91                	sub	a5,a5,a2
ffffffffc020160c:	00379613          	slli	a2,a5,0x3
ffffffffc0201610:	97b2                	add	a5,a5,a2
ffffffffc0201612:	078e                	slli	a5,a5,0x3
ffffffffc0201614:	97aa                	add	a5,a5,a0
ffffffffc0201616:	0aff1163          	bne	t5,a5,ffffffffc02016b8 <swap_init+0x382>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
ffffffffc020161a:	6785                	lui	a5,0x1
ffffffffc020161c:	95be                	add	a1,a1,a5
ffffffffc020161e:	6795                	lui	a5,0x5
ffffffffc0201620:	0821                	addi	a6,a6,8
ffffffffc0201622:	08a1                	addi	a7,a7,8
ffffffffc0201624:	f8f59ee3          	bne	a1,a5,ffffffffc02015c0 <swap_init+0x28a>
         assert((*check_ptep[i] & PTE_V)); // 确保页表条目有效          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0201628:	00004517          	auipc	a0,0x4
ffffffffc020162c:	d0050513          	addi	a0,a0,-768 # ffffffffc0205328 <commands+0xd08>
ffffffffc0201630:	a8bfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
    int ret = sm->check_swap(); // 调用交换管理器的check_swap函数进行页面替换检查
ffffffffc0201634:	000b3783          	ld	a5,0(s6)
ffffffffc0201638:	7f9c                	ld	a5,56(a5)
ffffffffc020163a:	9782                	jalr	a5
     // 现在访问虚拟页面，测试页面替换算法
     ret = check_content_access(); // 访问内容并检查页面替换
     assert(ret == 0); // 确保页面替换检查成功
ffffffffc020163c:	1a051263          	bnez	a0,ffffffffc02017e0 <swap_init+0x4aa>
     
     // 恢复内核内存环境
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
         free_pages(check_rp[i], 1); // 将检查用的物理页面标记为空闲
ffffffffc0201640:	00093503          	ld	a0,0(s2)
ffffffffc0201644:	4585                	li	a1,1
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
ffffffffc0201646:	0921                	addi	s2,s2,8
         free_pages(check_rp[i], 1); // 将检查用的物理页面标记为空闲
ffffffffc0201648:	412010ef          	jal	ra,ffffffffc0202a5a <free_pages>
     for (i = 0; i < CHECK_VALID_PHY_PAGE_NUM; i++) {
ffffffffc020164c:	ff491ae3          	bne	s2,s4,ffffffffc0201640 <swap_init+0x30a>
     } 

     // free_page(pte2page(*temp_ptep)); // 释放临时分配的页面（如果有必要）

     mm_destroy(mm); // 销毁内存管理结构
ffffffffc0201650:	8556                	mv	a0,s5
ffffffffc0201652:	e08ff0ef          	jal	ra,ffffffffc0200c5a <mm_destroy>
         
     nr_free = nr_free_store; // 恢复之前的空闲页面数量
ffffffffc0201656:	77a2                	ld	a5,40(sp)
     free_list = free_list_store; // 恢复之前的空闲页面链表
ffffffffc0201658:	01b4b423          	sd	s11,8(s1)
     nr_free = nr_free_store; // 恢复之前的空闲页面数量
ffffffffc020165c:	c89c                	sw	a5,16(s1)
     free_list = free_list_store; // 恢复之前的空闲页面链表
ffffffffc020165e:	7782                	ld	a5,32(sp)
ffffffffc0201660:	e09c                	sd	a5,0(s1)

     le = &free_list; // 重新初始化le为空闲页面链表的头部
     while ((le = list_next(le)) != &free_list) {
ffffffffc0201662:	009d8a63          	beq	s11,s1,ffffffffc0201676 <swap_init+0x340>
         struct Page *p = le2page(le, page_link);
         count--, total -= p->property; // 更新计数和总页数
ffffffffc0201666:	ff8da783          	lw	a5,-8(s11)
    return listelm->next;
ffffffffc020166a:	008dbd83          	ld	s11,8(s11)
ffffffffc020166e:	3d7d                	addiw	s10,s10,-1
ffffffffc0201670:	9c1d                	subw	s0,s0,a5
     while ((le = list_next(le)) != &free_list) {
ffffffffc0201672:	fe9d9ae3          	bne	s11,s1,ffffffffc0201666 <swap_init+0x330>
     }
     cprintf("count is %d, total is %d\n", count, total); // 打印最终的计数和总页数
ffffffffc0201676:	8622                	mv	a2,s0
ffffffffc0201678:	85ea                	mv	a1,s10
ffffffffc020167a:	00004517          	auipc	a0,0x4
ffffffffc020167e:	ce650513          	addi	a0,a0,-794 # ffffffffc0205360 <commands+0xd40>
ffffffffc0201682:	a39fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
     // assert(count == 0); // 确保所有页面都被正确释放
     
     cprintf("check_swap() succeeded!\n"); // 打印检查成功的消息
ffffffffc0201686:	00004517          	auipc	a0,0x4
ffffffffc020168a:	cfa50513          	addi	a0,a0,-774 # ffffffffc0205380 <commands+0xd60>
ffffffffc020168e:	a2dfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
}
ffffffffc0201692:	b9dd                	j	ffffffffc0201388 <swap_init+0x52>
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201694:	4901                	li	s2,0
ffffffffc0201696:	bba9                	j	ffffffffc02013f0 <swap_init+0xba>
        assert(PageProperty(p)); // 确保页面属性正确
ffffffffc0201698:	00004697          	auipc	a3,0x4
ffffffffc020169c:	a6868693          	addi	a3,a3,-1432 # ffffffffc0205100 <commands+0xae0>
ffffffffc02016a0:	00003617          	auipc	a2,0x3
ffffffffc02016a4:	6a860613          	addi	a2,a2,1704 # ffffffffc0204d48 <commands+0x728>
ffffffffc02016a8:	0bd00593          	li	a1,189
ffffffffc02016ac:	00004517          	auipc	a0,0x4
ffffffffc02016b0:	a2c50513          	addi	a0,a0,-1492 # ffffffffc02050d8 <commands+0xab8>
ffffffffc02016b4:	a4ffe0ef          	jal	ra,ffffffffc0200102 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]); // 确保页表条目指向正确的物理页面
ffffffffc02016b8:	00004697          	auipc	a3,0x4
ffffffffc02016bc:	c4868693          	addi	a3,a3,-952 # ffffffffc0205300 <commands+0xce0>
ffffffffc02016c0:	00003617          	auipc	a2,0x3
ffffffffc02016c4:	68860613          	addi	a2,a2,1672 # ffffffffc0204d48 <commands+0x728>
ffffffffc02016c8:	0fa00593          	li	a1,250
ffffffffc02016cc:	00004517          	auipc	a0,0x4
ffffffffc02016d0:	a0c50513          	addi	a0,a0,-1524 # ffffffffc02050d8 <commands+0xab8>
ffffffffc02016d4:	a2ffe0ef          	jal	ra,ffffffffc0200102 <__panic>
        panic("pte2page called with invalid pte"); // 无效时触发 panic
ffffffffc02016d8:	00004617          	auipc	a2,0x4
ffffffffc02016dc:	c0060613          	addi	a2,a2,-1024 # ffffffffc02052d8 <commands+0xcb8>
ffffffffc02016e0:	08200593          	li	a1,130
ffffffffc02016e4:	00004517          	auipc	a0,0x4
ffffffffc02016e8:	8d450513          	addi	a0,a0,-1836 # ffffffffc0204fb8 <commands+0x998>
ffffffffc02016ec:	a17fe0ef          	jal	ra,ffffffffc0200102 <__panic>
        panic("pa2page called with invalid pa"); // 如果无效，触发 panic
ffffffffc02016f0:	00004617          	auipc	a2,0x4
ffffffffc02016f4:	8a860613          	addi	a2,a2,-1880 # ffffffffc0204f98 <commands+0x978>
ffffffffc02016f8:	07000593          	li	a1,112
ffffffffc02016fc:	00004517          	auipc	a0,0x4
ffffffffc0201700:	8bc50513          	addi	a0,a0,-1860 # ffffffffc0204fb8 <commands+0x998>
ffffffffc0201704:	9fffe0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(!PageProperty(check_rp[i])); // 确保页面属性正确
ffffffffc0201708:	00004697          	auipc	a3,0x4
ffffffffc020170c:	af868693          	addi	a3,a3,-1288 # ffffffffc0205200 <commands+0xbe0>
ffffffffc0201710:	00003617          	auipc	a2,0x3
ffffffffc0201714:	63860613          	addi	a2,a2,1592 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201718:	0de00593          	li	a1,222
ffffffffc020171c:	00004517          	auipc	a0,0x4
ffffffffc0201720:	9bc50513          	addi	a0,a0,-1604 # ffffffffc02050d8 <commands+0xab8>
ffffffffc0201724:	9dffe0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert(check_rp[i] != NULL);
ffffffffc0201728:	00004697          	auipc	a3,0x4
ffffffffc020172c:	ac068693          	addi	a3,a3,-1344 # ffffffffc02051e8 <commands+0xbc8>
ffffffffc0201730:	00003617          	auipc	a2,0x3
ffffffffc0201734:	61860613          	addi	a2,a2,1560 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201738:	0dd00593          	li	a1,221
ffffffffc020173c:	00004517          	auipc	a0,0x4
ffffffffc0201740:	99c50513          	addi	a0,a0,-1636 # ffffffffc02050d8 <commands+0xab8>
ffffffffc0201744:	9bffe0ef          	jal	ra,ffffffffc0200102 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset); // 如果不在预期范围内，触发panic
ffffffffc0201748:	00004617          	auipc	a2,0x4
ffffffffc020174c:	97060613          	addi	a2,a2,-1680 # ffffffffc02050b8 <commands+0xa98>
ffffffffc0201750:	02800593          	li	a1,40
ffffffffc0201754:	00004517          	auipc	a0,0x4
ffffffffc0201758:	98450513          	addi	a0,a0,-1660 # ffffffffc02050d8 <commands+0xab8>
ffffffffc020175c:	9a7fe0ef          	jal	ra,ffffffffc0200102 <__panic>
         assert(check_ptep[i] != NULL); // 确保页表条目获取成功
ffffffffc0201760:	00004697          	auipc	a3,0x4
ffffffffc0201764:	b6068693          	addi	a3,a3,-1184 # ffffffffc02052c0 <commands+0xca0>
ffffffffc0201768:	00003617          	auipc	a2,0x3
ffffffffc020176c:	5e060613          	addi	a2,a2,1504 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201770:	0f900593          	li	a1,249
ffffffffc0201774:	00004517          	auipc	a0,0x4
ffffffffc0201778:	96450513          	addi	a0,a0,-1692 # ffffffffc02050d8 <commands+0xab8>
ffffffffc020177c:	987fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==4);
ffffffffc0201780:	00004697          	auipc	a3,0x4
ffffffffc0201784:	b2068693          	addi	a3,a3,-1248 # ffffffffc02052a0 <commands+0xc80>
ffffffffc0201788:	00003617          	auipc	a2,0x3
ffffffffc020178c:	5c060613          	addi	a2,a2,1472 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201790:	09e00593          	li	a1,158
ffffffffc0201794:	00004517          	auipc	a0,0x4
ffffffffc0201798:	94450513          	addi	a0,a0,-1724 # ffffffffc02050d8 <commands+0xab8>
ffffffffc020179c:	967fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==4);
ffffffffc02017a0:	00004697          	auipc	a3,0x4
ffffffffc02017a4:	b0068693          	addi	a3,a3,-1280 # ffffffffc02052a0 <commands+0xc80>
ffffffffc02017a8:	00003617          	auipc	a2,0x3
ffffffffc02017ac:	5a060613          	addi	a2,a2,1440 # ffffffffc0204d48 <commands+0x728>
ffffffffc02017b0:	0a100593          	li	a1,161
ffffffffc02017b4:	00004517          	auipc	a0,0x4
ffffffffc02017b8:	92450513          	addi	a0,a0,-1756 # ffffffffc02050d8 <commands+0xab8>
ffffffffc02017bc:	947fe0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(nr_free == 0); // 确保没有空闲页面
ffffffffc02017c0:	00004697          	auipc	a3,0x4
ffffffffc02017c4:	af068693          	addi	a3,a3,-1296 # ffffffffc02052b0 <commands+0xc90>
ffffffffc02017c8:	00003617          	auipc	a2,0x3
ffffffffc02017cc:	58060613          	addi	a2,a2,1408 # ffffffffc0204d48 <commands+0x728>
ffffffffc02017d0:	0f100593          	li	a1,241
ffffffffc02017d4:	00004517          	auipc	a0,0x4
ffffffffc02017d8:	90450513          	addi	a0,a0,-1788 # ffffffffc02050d8 <commands+0xab8>
ffffffffc02017dc:	927fe0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(ret == 0); // 确保页面替换检查成功
ffffffffc02017e0:	00004697          	auipc	a3,0x4
ffffffffc02017e4:	b7068693          	addi	a3,a3,-1168 # ffffffffc0205350 <commands+0xd30>
ffffffffc02017e8:	00003617          	auipc	a2,0x3
ffffffffc02017ec:	56060613          	addi	a2,a2,1376 # ffffffffc0204d48 <commands+0x728>
ffffffffc02017f0:	10000593          	li	a1,256
ffffffffc02017f4:	00004517          	auipc	a0,0x4
ffffffffc02017f8:	8e450513          	addi	a0,a0,-1820 # ffffffffc02050d8 <commands+0xab8>
ffffffffc02017fc:	907fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgdir[0] == 0); // 确保页目录的第一项是空的
ffffffffc0201800:	00003697          	auipc	a3,0x3
ffffffffc0201804:	75868693          	addi	a3,a3,1880 # ffffffffc0204f58 <commands+0x938>
ffffffffc0201808:	00003617          	auipc	a2,0x3
ffffffffc020180c:	54060613          	addi	a2,a2,1344 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201810:	0cd00593          	li	a1,205
ffffffffc0201814:	00004517          	auipc	a0,0x4
ffffffffc0201818:	8c450513          	addi	a0,a0,-1852 # ffffffffc02050d8 <commands+0xab8>
ffffffffc020181c:	8e7fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(vma != NULL);
ffffffffc0201820:	00003697          	auipc	a3,0x3
ffffffffc0201824:	7e068693          	addi	a3,a3,2016 # ffffffffc0205000 <commands+0x9e0>
ffffffffc0201828:	00003617          	auipc	a2,0x3
ffffffffc020182c:	52060613          	addi	a2,a2,1312 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201830:	0d000593          	li	a1,208
ffffffffc0201834:	00004517          	auipc	a0,0x4
ffffffffc0201838:	8a450513          	addi	a0,a0,-1884 # ffffffffc02050d8 <commands+0xab8>
ffffffffc020183c:	8c7fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(temp_ptep != NULL); // 确保页表条目获取成功
ffffffffc0201840:	00004697          	auipc	a3,0x4
ffffffffc0201844:	96868693          	addi	a3,a3,-1688 # ffffffffc02051a8 <commands+0xb88>
ffffffffc0201848:	00003617          	auipc	a2,0x3
ffffffffc020184c:	50060613          	addi	a2,a2,1280 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201850:	0d800593          	li	a1,216
ffffffffc0201854:	00004517          	auipc	a0,0x4
ffffffffc0201858:	88450513          	addi	a0,a0,-1916 # ffffffffc02050d8 <commands+0xab8>
ffffffffc020185c:	8a7fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(total == nr_free_pages()); // 确保空闲页面总数正确
ffffffffc0201860:	00004697          	auipc	a3,0x4
ffffffffc0201864:	8b068693          	addi	a3,a3,-1872 # ffffffffc0205110 <commands+0xaf0>
ffffffffc0201868:	00003617          	auipc	a2,0x3
ffffffffc020186c:	4e060613          	addi	a2,a2,1248 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201870:	0c000593          	li	a1,192
ffffffffc0201874:	00004517          	auipc	a0,0x4
ffffffffc0201878:	86450513          	addi	a0,a0,-1948 # ffffffffc02050d8 <commands+0xab8>
ffffffffc020187c:	887fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==2);
ffffffffc0201880:	00004697          	auipc	a3,0x4
ffffffffc0201884:	a0068693          	addi	a3,a3,-1536 # ffffffffc0205280 <commands+0xc60>
ffffffffc0201888:	00003617          	auipc	a2,0x3
ffffffffc020188c:	4c060613          	addi	a2,a2,1216 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201890:	09200593          	li	a1,146
ffffffffc0201894:	00004517          	auipc	a0,0x4
ffffffffc0201898:	84450513          	addi	a0,a0,-1980 # ffffffffc02050d8 <commands+0xab8>
ffffffffc020189c:	867fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==2);
ffffffffc02018a0:	00004697          	auipc	a3,0x4
ffffffffc02018a4:	9e068693          	addi	a3,a3,-1568 # ffffffffc0205280 <commands+0xc60>
ffffffffc02018a8:	00003617          	auipc	a2,0x3
ffffffffc02018ac:	4a060613          	addi	a2,a2,1184 # ffffffffc0204d48 <commands+0x728>
ffffffffc02018b0:	09500593          	li	a1,149
ffffffffc02018b4:	00004517          	auipc	a0,0x4
ffffffffc02018b8:	82450513          	addi	a0,a0,-2012 # ffffffffc02050d8 <commands+0xab8>
ffffffffc02018bc:	847fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==3);
ffffffffc02018c0:	00004697          	auipc	a3,0x4
ffffffffc02018c4:	9d068693          	addi	a3,a3,-1584 # ffffffffc0205290 <commands+0xc70>
ffffffffc02018c8:	00003617          	auipc	a2,0x3
ffffffffc02018cc:	48060613          	addi	a2,a2,1152 # ffffffffc0204d48 <commands+0x728>
ffffffffc02018d0:	09800593          	li	a1,152
ffffffffc02018d4:	00004517          	auipc	a0,0x4
ffffffffc02018d8:	80450513          	addi	a0,a0,-2044 # ffffffffc02050d8 <commands+0xab8>
ffffffffc02018dc:	827fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==3);
ffffffffc02018e0:	00004697          	auipc	a3,0x4
ffffffffc02018e4:	9b068693          	addi	a3,a3,-1616 # ffffffffc0205290 <commands+0xc70>
ffffffffc02018e8:	00003617          	auipc	a2,0x3
ffffffffc02018ec:	46060613          	addi	a2,a2,1120 # ffffffffc0204d48 <commands+0x728>
ffffffffc02018f0:	09b00593          	li	a1,155
ffffffffc02018f4:	00003517          	auipc	a0,0x3
ffffffffc02018f8:	7e450513          	addi	a0,a0,2020 # ffffffffc02050d8 <commands+0xab8>
ffffffffc02018fc:	807fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==1);
ffffffffc0201900:	00004697          	auipc	a3,0x4
ffffffffc0201904:	97068693          	addi	a3,a3,-1680 # ffffffffc0205270 <commands+0xc50>
ffffffffc0201908:	00003617          	auipc	a2,0x3
ffffffffc020190c:	44060613          	addi	a2,a2,1088 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201910:	08c00593          	li	a1,140
ffffffffc0201914:	00003517          	auipc	a0,0x3
ffffffffc0201918:	7c450513          	addi	a0,a0,1988 # ffffffffc02050d8 <commands+0xab8>
ffffffffc020191c:	fe6fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==1);
ffffffffc0201920:	00004697          	auipc	a3,0x4
ffffffffc0201924:	95068693          	addi	a3,a3,-1712 # ffffffffc0205270 <commands+0xc50>
ffffffffc0201928:	00003617          	auipc	a2,0x3
ffffffffc020192c:	42060613          	addi	a2,a2,1056 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201930:	08f00593          	li	a1,143
ffffffffc0201934:	00003517          	auipc	a0,0x3
ffffffffc0201938:	7a450513          	addi	a0,a0,1956 # ffffffffc02050d8 <commands+0xab8>
ffffffffc020193c:	fc6fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(mm != NULL);
ffffffffc0201940:	00003697          	auipc	a3,0x3
ffffffffc0201944:	6e868693          	addi	a3,a3,1768 # ffffffffc0205028 <commands+0xa08>
ffffffffc0201948:	00003617          	auipc	a2,0x3
ffffffffc020194c:	40060613          	addi	a2,a2,1024 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201950:	0c500593          	li	a1,197
ffffffffc0201954:	00003517          	auipc	a0,0x3
ffffffffc0201958:	78450513          	addi	a0,a0,1924 # ffffffffc02050d8 <commands+0xab8>
ffffffffc020195c:	fa6fe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(check_mm_struct == NULL); // 确保之前没有设置过检查用的内存管理结构
ffffffffc0201960:	00003697          	auipc	a3,0x3
ffffffffc0201964:	7f868693          	addi	a3,a3,2040 # ffffffffc0205158 <commands+0xb38>
ffffffffc0201968:	00003617          	auipc	a2,0x3
ffffffffc020196c:	3e060613          	addi	a2,a2,992 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201970:	0c800593          	li	a1,200
ffffffffc0201974:	00003517          	auipc	a0,0x3
ffffffffc0201978:	76450513          	addi	a0,a0,1892 # ffffffffc02050d8 <commands+0xab8>
ffffffffc020197c:	f86fe0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(nr_free == CHECK_VALID_PHY_PAGE_NUM); // 确保空闲页面数量正确
ffffffffc0201980:	00004697          	auipc	a3,0x4
ffffffffc0201984:	8a068693          	addi	a3,a3,-1888 # ffffffffc0205220 <commands+0xc00>
ffffffffc0201988:	00003617          	auipc	a2,0x3
ffffffffc020198c:	3c060613          	addi	a2,a2,960 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201990:	0e900593          	li	a1,233
ffffffffc0201994:	00003517          	auipc	a0,0x3
ffffffffc0201998:	74450513          	addi	a0,a0,1860 # ffffffffc02050d8 <commands+0xab8>
ffffffffc020199c:	f66fe0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc02019a0 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc02019a0:	00010797          	auipc	a5,0x10
ffffffffc02019a4:	b887b783          	ld	a5,-1144(a5) # ffffffffc0211528 <sm>
ffffffffc02019a8:	6b9c                	ld	a5,16(a5)
ffffffffc02019aa:	8782                	jr	a5

ffffffffc02019ac <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc02019ac:	00010797          	auipc	a5,0x10
ffffffffc02019b0:	b7c7b783          	ld	a5,-1156(a5) # ffffffffc0211528 <sm>
ffffffffc02019b4:	739c                	ld	a5,32(a5)
ffffffffc02019b6:	8782                	jr	a5

ffffffffc02019b8 <swap_out>:
swap_out(struct mm_struct *mm, int n, int in_tick) {
ffffffffc02019b8:	711d                	addi	sp,sp,-96
ffffffffc02019ba:	ec86                	sd	ra,88(sp)
ffffffffc02019bc:	e8a2                	sd	s0,80(sp)
ffffffffc02019be:	e4a6                	sd	s1,72(sp)
ffffffffc02019c0:	e0ca                	sd	s2,64(sp)
ffffffffc02019c2:	fc4e                	sd	s3,56(sp)
ffffffffc02019c4:	f852                	sd	s4,48(sp)
ffffffffc02019c6:	f456                	sd	s5,40(sp)
ffffffffc02019c8:	f05a                	sd	s6,32(sp)
ffffffffc02019ca:	ec5e                	sd	s7,24(sp)
ffffffffc02019cc:	e862                	sd	s8,16(sp)
    for (i = 0; i != n; ++i) {
ffffffffc02019ce:	cde9                	beqz	a1,ffffffffc0201aa8 <swap_out+0xf0>
ffffffffc02019d0:	8a2e                	mv	s4,a1
ffffffffc02019d2:	892a                	mv	s2,a0
ffffffffc02019d4:	8ab2                	mv	s5,a2
ffffffffc02019d6:	4401                	li	s0,0
ffffffffc02019d8:	00010997          	auipc	s3,0x10
ffffffffc02019dc:	b5098993          	addi	s3,s3,-1200 # ffffffffc0211528 <sm>
            cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
ffffffffc02019e0:	00004b17          	auipc	s6,0x4
ffffffffc02019e4:	a20b0b13          	addi	s6,s6,-1504 # ffffffffc0205400 <commands+0xde0>
            cprintf("SWAP: failed to save\n");
ffffffffc02019e8:	00004b97          	auipc	s7,0x4
ffffffffc02019ec:	a00b8b93          	addi	s7,s7,-1536 # ffffffffc02053e8 <commands+0xdc8>
ffffffffc02019f0:	a825                	j	ffffffffc0201a28 <swap_out+0x70>
            cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
ffffffffc02019f2:	67a2                	ld	a5,8(sp)
ffffffffc02019f4:	8626                	mv	a2,s1
ffffffffc02019f6:	85a2                	mv	a1,s0
ffffffffc02019f8:	63b4                	ld	a3,64(a5)
ffffffffc02019fa:	855a                	mv	a0,s6
    for (i = 0; i != n; ++i) {
ffffffffc02019fc:	2405                	addiw	s0,s0,1
            cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr / PGSIZE + 1);
ffffffffc02019fe:	82b1                	srli	a3,a3,0xc
ffffffffc0201a00:	0685                	addi	a3,a3,1
ffffffffc0201a02:	eb8fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
            *ptep = (page->pra_vaddr / PGSIZE + 1) << 8; // 更新页表条目
ffffffffc0201a06:	6522                	ld	a0,8(sp)
            free_page(page); // 释放页面
ffffffffc0201a08:	4585                	li	a1,1
            *ptep = (page->pra_vaddr / PGSIZE + 1) << 8; // 更新页表条目
ffffffffc0201a0a:	613c                	ld	a5,64(a0)
ffffffffc0201a0c:	83b1                	srli	a5,a5,0xc
ffffffffc0201a0e:	0785                	addi	a5,a5,1
ffffffffc0201a10:	07a2                	slli	a5,a5,0x8
ffffffffc0201a12:	00fc3023          	sd	a5,0(s8)
            free_page(page); // 释放页面
ffffffffc0201a16:	044010ef          	jal	ra,ffffffffc0202a5a <free_pages>
        tlb_invalidate(mm->pgdir, v); // 使TLB无效，确保CPU的缓存与内存管理单元同步
ffffffffc0201a1a:	01893503          	ld	a0,24(s2)
ffffffffc0201a1e:	85a6                	mv	a1,s1
ffffffffc0201a20:	070020ef          	jal	ra,ffffffffc0203a90 <tlb_invalidate>
    for (i = 0; i != n; ++i) {
ffffffffc0201a24:	048a0d63          	beq	s4,s0,ffffffffc0201a7e <swap_out+0xc6>
        int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc0201a28:	0009b783          	ld	a5,0(s3)
ffffffffc0201a2c:	8656                	mv	a2,s5
ffffffffc0201a2e:	002c                	addi	a1,sp,8
ffffffffc0201a30:	7b9c                	ld	a5,48(a5)
ffffffffc0201a32:	854a                	mv	a0,s2
ffffffffc0201a34:	9782                	jalr	a5
        if (r != 0) {
ffffffffc0201a36:	e12d                	bnez	a0,ffffffffc0201a98 <swap_out+0xe0>
        v = page->pra_vaddr; 
ffffffffc0201a38:	67a2                	ld	a5,8(sp)
        pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0201a3a:	01893503          	ld	a0,24(s2)
ffffffffc0201a3e:	4601                	li	a2,0
        v = page->pra_vaddr; 
ffffffffc0201a40:	63a4                	ld	s1,64(a5)
        pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0201a42:	85a6                	mv	a1,s1
ffffffffc0201a44:	090010ef          	jal	ra,ffffffffc0202ad4 <get_pte>
        assert((*ptep & PTE_V) != 0); // 确保页表条目有效
ffffffffc0201a48:	611c                	ld	a5,0(a0)
        pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0201a4a:	8c2a                	mv	s8,a0
        assert((*ptep & PTE_V) != 0); // 确保页表条目有效
ffffffffc0201a4c:	8b85                	andi	a5,a5,1
ffffffffc0201a4e:	cfb9                	beqz	a5,ffffffffc0201aac <swap_out+0xf4>
        if (swapfs_write((page->pra_vaddr / PGSIZE + 1) << 8, page) != 0) {
ffffffffc0201a50:	65a2                	ld	a1,8(sp)
ffffffffc0201a52:	61bc                	ld	a5,64(a1)
ffffffffc0201a54:	83b1                	srli	a5,a5,0xc
ffffffffc0201a56:	0785                	addi	a5,a5,1
ffffffffc0201a58:	00879513          	slli	a0,a5,0x8
ffffffffc0201a5c:	366020ef          	jal	ra,ffffffffc0203dc2 <swapfs_write>
ffffffffc0201a60:	d949                	beqz	a0,ffffffffc02019f2 <swap_out+0x3a>
            cprintf("SWAP: failed to save\n");
ffffffffc0201a62:	855e                	mv	a0,s7
ffffffffc0201a64:	e56fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
            sm->map_swappable(mm, v, page, 0); // 如果失败，重新映射为可交换
ffffffffc0201a68:	0009b783          	ld	a5,0(s3)
ffffffffc0201a6c:	6622                	ld	a2,8(sp)
ffffffffc0201a6e:	4681                	li	a3,0
ffffffffc0201a70:	739c                	ld	a5,32(a5)
ffffffffc0201a72:	85a6                	mv	a1,s1
ffffffffc0201a74:	854a                	mv	a0,s2
    for (i = 0; i != n; ++i) {
ffffffffc0201a76:	2405                	addiw	s0,s0,1
            sm->map_swappable(mm, v, page, 0); // 如果失败，重新映射为可交换
ffffffffc0201a78:	9782                	jalr	a5
    for (i = 0; i != n; ++i) {
ffffffffc0201a7a:	fa8a17e3          	bne	s4,s0,ffffffffc0201a28 <swap_out+0x70>
}
ffffffffc0201a7e:	60e6                	ld	ra,88(sp)
ffffffffc0201a80:	8522                	mv	a0,s0
ffffffffc0201a82:	6446                	ld	s0,80(sp)
ffffffffc0201a84:	64a6                	ld	s1,72(sp)
ffffffffc0201a86:	6906                	ld	s2,64(sp)
ffffffffc0201a88:	79e2                	ld	s3,56(sp)
ffffffffc0201a8a:	7a42                	ld	s4,48(sp)
ffffffffc0201a8c:	7aa2                	ld	s5,40(sp)
ffffffffc0201a8e:	7b02                	ld	s6,32(sp)
ffffffffc0201a90:	6be2                	ld	s7,24(sp)
ffffffffc0201a92:	6c42                	ld	s8,16(sp)
ffffffffc0201a94:	6125                	addi	sp,sp,96
ffffffffc0201a96:	8082                	ret
            cprintf("i %d, swap_out: call swap_out_victim failed\n", i);
ffffffffc0201a98:	85a2                	mv	a1,s0
ffffffffc0201a9a:	00004517          	auipc	a0,0x4
ffffffffc0201a9e:	90650513          	addi	a0,a0,-1786 # ffffffffc02053a0 <commands+0xd80>
ffffffffc0201aa2:	e18fe0ef          	jal	ra,ffffffffc02000ba <cprintf>
            break;
ffffffffc0201aa6:	bfe1                	j	ffffffffc0201a7e <swap_out+0xc6>
    for (i = 0; i != n; ++i) {
ffffffffc0201aa8:	4401                	li	s0,0
ffffffffc0201aaa:	bfd1                	j	ffffffffc0201a7e <swap_out+0xc6>
        assert((*ptep & PTE_V) != 0); // 确保页表条目有效
ffffffffc0201aac:	00004697          	auipc	a3,0x4
ffffffffc0201ab0:	92468693          	addi	a3,a3,-1756 # ffffffffc02053d0 <commands+0xdb0>
ffffffffc0201ab4:	00003617          	auipc	a2,0x3
ffffffffc0201ab8:	29460613          	addi	a2,a2,660 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201abc:	06200593          	li	a1,98
ffffffffc0201ac0:	00003517          	auipc	a0,0x3
ffffffffc0201ac4:	61850513          	addi	a0,a0,1560 # ffffffffc02050d8 <commands+0xab8>
ffffffffc0201ac8:	e3afe0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0201acc <swap_in>:
swap_in(struct mm_struct *mm, uintptr_t addr, struct Page **ptr_result) {
ffffffffc0201acc:	7179                	addi	sp,sp,-48
ffffffffc0201ace:	e84a                	sd	s2,16(sp)
ffffffffc0201ad0:	892a                	mv	s2,a0
    struct Page *result = alloc_page(); // 分配一个新页面
ffffffffc0201ad2:	4505                	li	a0,1
swap_in(struct mm_struct *mm, uintptr_t addr, struct Page **ptr_result) {
ffffffffc0201ad4:	ec26                	sd	s1,24(sp)
ffffffffc0201ad6:	e44e                	sd	s3,8(sp)
ffffffffc0201ad8:	f406                	sd	ra,40(sp)
ffffffffc0201ada:	f022                	sd	s0,32(sp)
ffffffffc0201adc:	84ae                	mv	s1,a1
ffffffffc0201ade:	89b2                	mv	s3,a2
    struct Page *result = alloc_page(); // 分配一个新页面
ffffffffc0201ae0:	6e9000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
    assert(result != NULL); // 确保分配成功
ffffffffc0201ae4:	c129                	beqz	a0,ffffffffc0201b26 <swap_in+0x5a>
    pte_t *ptep = get_pte(mm->pgdir, addr, 0); // 获取页表条目
ffffffffc0201ae6:	842a                	mv	s0,a0
ffffffffc0201ae8:	01893503          	ld	a0,24(s2)
ffffffffc0201aec:	4601                	li	a2,0
ffffffffc0201aee:	85a6                	mv	a1,s1
ffffffffc0201af0:	7e5000ef          	jal	ra,ffffffffc0202ad4 <get_pte>
ffffffffc0201af4:	892a                	mv	s2,a0
    if ((r = swapfs_read((*ptep), result)) != 0) {
ffffffffc0201af6:	6108                	ld	a0,0(a0)
ffffffffc0201af8:	85a2                	mv	a1,s0
ffffffffc0201afa:	22e020ef          	jal	ra,ffffffffc0203d28 <swapfs_read>
    cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep) >> 8, addr);
ffffffffc0201afe:	00093583          	ld	a1,0(s2)
ffffffffc0201b02:	8626                	mv	a2,s1
ffffffffc0201b04:	00004517          	auipc	a0,0x4
ffffffffc0201b08:	94c50513          	addi	a0,a0,-1716 # ffffffffc0205450 <commands+0xe30>
ffffffffc0201b0c:	81a1                	srli	a1,a1,0x8
ffffffffc0201b0e:	dacfe0ef          	jal	ra,ffffffffc02000ba <cprintf>
}
ffffffffc0201b12:	70a2                	ld	ra,40(sp)
    *ptr_result = result; // 设置函数返回的页面
ffffffffc0201b14:	0089b023          	sd	s0,0(s3)
}
ffffffffc0201b18:	7402                	ld	s0,32(sp)
ffffffffc0201b1a:	64e2                	ld	s1,24(sp)
ffffffffc0201b1c:	6942                	ld	s2,16(sp)
ffffffffc0201b1e:	69a2                	ld	s3,8(sp)
ffffffffc0201b20:	4501                	li	a0,0
ffffffffc0201b22:	6145                	addi	sp,sp,48
ffffffffc0201b24:	8082                	ret
    assert(result != NULL); // 确保分配成功
ffffffffc0201b26:	00004697          	auipc	a3,0x4
ffffffffc0201b2a:	91a68693          	addi	a3,a3,-1766 # ffffffffc0205440 <commands+0xe20>
ffffffffc0201b2e:	00003617          	auipc	a2,0x3
ffffffffc0201b32:	21a60613          	addi	a2,a2,538 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201b36:	07800593          	li	a1,120
ffffffffc0201b3a:	00003517          	auipc	a0,0x3
ffffffffc0201b3e:	59e50513          	addi	a0,a0,1438 # ffffffffc02050d8 <commands+0xab8>
ffffffffc0201b42:	dc0fe0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0201b46 <default_init>:
    elm->prev = elm->next = elm;
ffffffffc0201b46:	0000f797          	auipc	a5,0xf
ffffffffc0201b4a:	59a78793          	addi	a5,a5,1434 # ffffffffc02110e0 <free_area>
ffffffffc0201b4e:	e79c                	sd	a5,8(a5)
ffffffffc0201b50:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0201b52:	0007a823          	sw	zero,16(a5)
}
ffffffffc0201b56:	8082                	ret

ffffffffc0201b58 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0201b58:	0000f517          	auipc	a0,0xf
ffffffffc0201b5c:	59856503          	lwu	a0,1432(a0) # ffffffffc02110f0 <free_area+0x10>
ffffffffc0201b60:	8082                	ret

ffffffffc0201b62 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0201b62:	715d                	addi	sp,sp,-80
ffffffffc0201b64:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0201b66:	0000f417          	auipc	s0,0xf
ffffffffc0201b6a:	57a40413          	addi	s0,s0,1402 # ffffffffc02110e0 <free_area>
ffffffffc0201b6e:	641c                	ld	a5,8(s0)
ffffffffc0201b70:	e486                	sd	ra,72(sp)
ffffffffc0201b72:	fc26                	sd	s1,56(sp)
ffffffffc0201b74:	f84a                	sd	s2,48(sp)
ffffffffc0201b76:	f44e                	sd	s3,40(sp)
ffffffffc0201b78:	f052                	sd	s4,32(sp)
ffffffffc0201b7a:	ec56                	sd	s5,24(sp)
ffffffffc0201b7c:	e85a                	sd	s6,16(sp)
ffffffffc0201b7e:	e45e                	sd	s7,8(sp)
ffffffffc0201b80:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201b82:	2c878763          	beq	a5,s0,ffffffffc0201e50 <default_check+0x2ee>
    int count = 0, total = 0;
ffffffffc0201b86:	4481                	li	s1,0
ffffffffc0201b88:	4901                	li	s2,0
ffffffffc0201b8a:	fe87b703          	ld	a4,-24(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0201b8e:	8b09                	andi	a4,a4,2
ffffffffc0201b90:	2c070463          	beqz	a4,ffffffffc0201e58 <default_check+0x2f6>
        count ++, total += p->property;
ffffffffc0201b94:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201b98:	679c                	ld	a5,8(a5)
ffffffffc0201b9a:	2905                	addiw	s2,s2,1
ffffffffc0201b9c:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201b9e:	fe8796e3          	bne	a5,s0,ffffffffc0201b8a <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0201ba2:	89a6                	mv	s3,s1
ffffffffc0201ba4:	6f7000ef          	jal	ra,ffffffffc0202a9a <nr_free_pages>
ffffffffc0201ba8:	71351863          	bne	a0,s3,ffffffffc02022b8 <default_check+0x756>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201bac:	4505                	li	a0,1
ffffffffc0201bae:	61b000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201bb2:	8a2a                	mv	s4,a0
ffffffffc0201bb4:	44050263          	beqz	a0,ffffffffc0201ff8 <default_check+0x496>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201bb8:	4505                	li	a0,1
ffffffffc0201bba:	60f000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201bbe:	89aa                	mv	s3,a0
ffffffffc0201bc0:	70050c63          	beqz	a0,ffffffffc02022d8 <default_check+0x776>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201bc4:	4505                	li	a0,1
ffffffffc0201bc6:	603000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201bca:	8aaa                	mv	s5,a0
ffffffffc0201bcc:	4a050663          	beqz	a0,ffffffffc0202078 <default_check+0x516>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201bd0:	2b3a0463          	beq	s4,s3,ffffffffc0201e78 <default_check+0x316>
ffffffffc0201bd4:	2aaa0263          	beq	s4,a0,ffffffffc0201e78 <default_check+0x316>
ffffffffc0201bd8:	2aa98063          	beq	s3,a0,ffffffffc0201e78 <default_check+0x316>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201bdc:	000a2783          	lw	a5,0(s4)
ffffffffc0201be0:	2a079c63          	bnez	a5,ffffffffc0201e98 <default_check+0x336>
ffffffffc0201be4:	0009a783          	lw	a5,0(s3)
ffffffffc0201be8:	2a079863          	bnez	a5,ffffffffc0201e98 <default_check+0x336>
ffffffffc0201bec:	411c                	lw	a5,0(a0)
ffffffffc0201bee:	2a079563          	bnez	a5,ffffffffc0201e98 <default_check+0x336>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0201bf2:	00010797          	auipc	a5,0x10
ffffffffc0201bf6:	9667b783          	ld	a5,-1690(a5) # ffffffffc0211558 <pages>
ffffffffc0201bfa:	40fa0733          	sub	a4,s4,a5
ffffffffc0201bfe:	870d                	srai	a4,a4,0x3
ffffffffc0201c00:	00004597          	auipc	a1,0x4
ffffffffc0201c04:	5785b583          	ld	a1,1400(a1) # ffffffffc0206178 <error_string+0x38>
ffffffffc0201c08:	02b70733          	mul	a4,a4,a1
ffffffffc0201c0c:	00004617          	auipc	a2,0x4
ffffffffc0201c10:	57463603          	ld	a2,1396(a2) # ffffffffc0206180 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201c14:	00010697          	auipc	a3,0x10
ffffffffc0201c18:	93c6b683          	ld	a3,-1732(a3) # ffffffffc0211550 <npage>
ffffffffc0201c1c:	06b2                	slli	a3,a3,0xc
ffffffffc0201c1e:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc0201c20:	0732                	slli	a4,a4,0xc
ffffffffc0201c22:	28d77b63          	bgeu	a4,a3,ffffffffc0201eb8 <default_check+0x356>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0201c26:	40f98733          	sub	a4,s3,a5
ffffffffc0201c2a:	870d                	srai	a4,a4,0x3
ffffffffc0201c2c:	02b70733          	mul	a4,a4,a1
ffffffffc0201c30:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc0201c32:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201c34:	4cd77263          	bgeu	a4,a3,ffffffffc02020f8 <default_check+0x596>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0201c38:	40f507b3          	sub	a5,a0,a5
ffffffffc0201c3c:	878d                	srai	a5,a5,0x3
ffffffffc0201c3e:	02b787b3          	mul	a5,a5,a1
ffffffffc0201c42:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc0201c44:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201c46:	30d7f963          	bgeu	a5,a3,ffffffffc0201f58 <default_check+0x3f6>
    assert(alloc_page() == NULL);
ffffffffc0201c4a:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201c4c:	00043c03          	ld	s8,0(s0)
ffffffffc0201c50:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0201c54:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0201c58:	e400                	sd	s0,8(s0)
ffffffffc0201c5a:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0201c5c:	0000f797          	auipc	a5,0xf
ffffffffc0201c60:	4807aa23          	sw	zero,1172(a5) # ffffffffc02110f0 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0201c64:	565000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201c68:	2c051863          	bnez	a0,ffffffffc0201f38 <default_check+0x3d6>
    free_page(p0);
ffffffffc0201c6c:	4585                	li	a1,1
ffffffffc0201c6e:	8552                	mv	a0,s4
ffffffffc0201c70:	5eb000ef          	jal	ra,ffffffffc0202a5a <free_pages>
    free_page(p1);
ffffffffc0201c74:	4585                	li	a1,1
ffffffffc0201c76:	854e                	mv	a0,s3
ffffffffc0201c78:	5e3000ef          	jal	ra,ffffffffc0202a5a <free_pages>
    free_page(p2);
ffffffffc0201c7c:	4585                	li	a1,1
ffffffffc0201c7e:	8556                	mv	a0,s5
ffffffffc0201c80:	5db000ef          	jal	ra,ffffffffc0202a5a <free_pages>
    assert(nr_free == 3);
ffffffffc0201c84:	4818                	lw	a4,16(s0)
ffffffffc0201c86:	478d                	li	a5,3
ffffffffc0201c88:	28f71863          	bne	a4,a5,ffffffffc0201f18 <default_check+0x3b6>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201c8c:	4505                	li	a0,1
ffffffffc0201c8e:	53b000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201c92:	89aa                	mv	s3,a0
ffffffffc0201c94:	26050263          	beqz	a0,ffffffffc0201ef8 <default_check+0x396>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201c98:	4505                	li	a0,1
ffffffffc0201c9a:	52f000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201c9e:	8aaa                	mv	s5,a0
ffffffffc0201ca0:	3a050c63          	beqz	a0,ffffffffc0202058 <default_check+0x4f6>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201ca4:	4505                	li	a0,1
ffffffffc0201ca6:	523000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201caa:	8a2a                	mv	s4,a0
ffffffffc0201cac:	38050663          	beqz	a0,ffffffffc0202038 <default_check+0x4d6>
    assert(alloc_page() == NULL);
ffffffffc0201cb0:	4505                	li	a0,1
ffffffffc0201cb2:	517000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201cb6:	36051163          	bnez	a0,ffffffffc0202018 <default_check+0x4b6>
    free_page(p0);
ffffffffc0201cba:	4585                	li	a1,1
ffffffffc0201cbc:	854e                	mv	a0,s3
ffffffffc0201cbe:	59d000ef          	jal	ra,ffffffffc0202a5a <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0201cc2:	641c                	ld	a5,8(s0)
ffffffffc0201cc4:	20878a63          	beq	a5,s0,ffffffffc0201ed8 <default_check+0x376>
    assert((p = alloc_page()) == p0);
ffffffffc0201cc8:	4505                	li	a0,1
ffffffffc0201cca:	4ff000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201cce:	30a99563          	bne	s3,a0,ffffffffc0201fd8 <default_check+0x476>
    assert(alloc_page() == NULL);
ffffffffc0201cd2:	4505                	li	a0,1
ffffffffc0201cd4:	4f5000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201cd8:	2e051063          	bnez	a0,ffffffffc0201fb8 <default_check+0x456>
    assert(nr_free == 0);
ffffffffc0201cdc:	481c                	lw	a5,16(s0)
ffffffffc0201cde:	2a079d63          	bnez	a5,ffffffffc0201f98 <default_check+0x436>
    free_page(p);
ffffffffc0201ce2:	854e                	mv	a0,s3
ffffffffc0201ce4:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201ce6:	01843023          	sd	s8,0(s0)
ffffffffc0201cea:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0201cee:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0201cf2:	569000ef          	jal	ra,ffffffffc0202a5a <free_pages>
    free_page(p1);
ffffffffc0201cf6:	4585                	li	a1,1
ffffffffc0201cf8:	8556                	mv	a0,s5
ffffffffc0201cfa:	561000ef          	jal	ra,ffffffffc0202a5a <free_pages>
    free_page(p2);
ffffffffc0201cfe:	4585                	li	a1,1
ffffffffc0201d00:	8552                	mv	a0,s4
ffffffffc0201d02:	559000ef          	jal	ra,ffffffffc0202a5a <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201d06:	4515                	li	a0,5
ffffffffc0201d08:	4c1000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201d0c:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201d0e:	26050563          	beqz	a0,ffffffffc0201f78 <default_check+0x416>
ffffffffc0201d12:	651c                	ld	a5,8(a0)
ffffffffc0201d14:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0201d16:	8b85                	andi	a5,a5,1
ffffffffc0201d18:	54079063          	bnez	a5,ffffffffc0202258 <default_check+0x6f6>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201d1c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201d1e:	00043b03          	ld	s6,0(s0)
ffffffffc0201d22:	00843a83          	ld	s5,8(s0)
ffffffffc0201d26:	e000                	sd	s0,0(s0)
ffffffffc0201d28:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0201d2a:	49f000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201d2e:	50051563          	bnez	a0,ffffffffc0202238 <default_check+0x6d6>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0201d32:	09098a13          	addi	s4,s3,144
ffffffffc0201d36:	8552                	mv	a0,s4
ffffffffc0201d38:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201d3a:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0201d3e:	0000f797          	auipc	a5,0xf
ffffffffc0201d42:	3a07a923          	sw	zero,946(a5) # ffffffffc02110f0 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0201d46:	515000ef          	jal	ra,ffffffffc0202a5a <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201d4a:	4511                	li	a0,4
ffffffffc0201d4c:	47d000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201d50:	4c051463          	bnez	a0,ffffffffc0202218 <default_check+0x6b6>
ffffffffc0201d54:	0989b783          	ld	a5,152(s3)
ffffffffc0201d58:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201d5a:	8b85                	andi	a5,a5,1
ffffffffc0201d5c:	48078e63          	beqz	a5,ffffffffc02021f8 <default_check+0x696>
ffffffffc0201d60:	0a89a703          	lw	a4,168(s3)
ffffffffc0201d64:	478d                	li	a5,3
ffffffffc0201d66:	48f71963          	bne	a4,a5,ffffffffc02021f8 <default_check+0x696>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201d6a:	450d                	li	a0,3
ffffffffc0201d6c:	45d000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201d70:	8c2a                	mv	s8,a0
ffffffffc0201d72:	46050363          	beqz	a0,ffffffffc02021d8 <default_check+0x676>
    assert(alloc_page() == NULL);
ffffffffc0201d76:	4505                	li	a0,1
ffffffffc0201d78:	451000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201d7c:	42051e63          	bnez	a0,ffffffffc02021b8 <default_check+0x656>
    assert(p0 + 2 == p1);
ffffffffc0201d80:	418a1c63          	bne	s4,s8,ffffffffc0202198 <default_check+0x636>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0201d84:	4585                	li	a1,1
ffffffffc0201d86:	854e                	mv	a0,s3
ffffffffc0201d88:	4d3000ef          	jal	ra,ffffffffc0202a5a <free_pages>
    free_pages(p1, 3);
ffffffffc0201d8c:	458d                	li	a1,3
ffffffffc0201d8e:	8552                	mv	a0,s4
ffffffffc0201d90:	4cb000ef          	jal	ra,ffffffffc0202a5a <free_pages>
ffffffffc0201d94:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0201d98:	04898c13          	addi	s8,s3,72
ffffffffc0201d9c:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201d9e:	8b85                	andi	a5,a5,1
ffffffffc0201da0:	3c078c63          	beqz	a5,ffffffffc0202178 <default_check+0x616>
ffffffffc0201da4:	0189a703          	lw	a4,24(s3)
ffffffffc0201da8:	4785                	li	a5,1
ffffffffc0201daa:	3cf71763          	bne	a4,a5,ffffffffc0202178 <default_check+0x616>
ffffffffc0201dae:	008a3783          	ld	a5,8(s4)
ffffffffc0201db2:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201db4:	8b85                	andi	a5,a5,1
ffffffffc0201db6:	3a078163          	beqz	a5,ffffffffc0202158 <default_check+0x5f6>
ffffffffc0201dba:	018a2703          	lw	a4,24(s4)
ffffffffc0201dbe:	478d                	li	a5,3
ffffffffc0201dc0:	38f71c63          	bne	a4,a5,ffffffffc0202158 <default_check+0x5f6>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201dc4:	4505                	li	a0,1
ffffffffc0201dc6:	403000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201dca:	36a99763          	bne	s3,a0,ffffffffc0202138 <default_check+0x5d6>
    free_page(p0);
ffffffffc0201dce:	4585                	li	a1,1
ffffffffc0201dd0:	48b000ef          	jal	ra,ffffffffc0202a5a <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201dd4:	4509                	li	a0,2
ffffffffc0201dd6:	3f3000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201dda:	32aa1f63          	bne	s4,a0,ffffffffc0202118 <default_check+0x5b6>

    free_pages(p0, 2);
ffffffffc0201dde:	4589                	li	a1,2
ffffffffc0201de0:	47b000ef          	jal	ra,ffffffffc0202a5a <free_pages>
    free_page(p2);
ffffffffc0201de4:	4585                	li	a1,1
ffffffffc0201de6:	8562                	mv	a0,s8
ffffffffc0201de8:	473000ef          	jal	ra,ffffffffc0202a5a <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201dec:	4515                	li	a0,5
ffffffffc0201dee:	3db000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201df2:	89aa                	mv	s3,a0
ffffffffc0201df4:	48050263          	beqz	a0,ffffffffc0202278 <default_check+0x716>
    assert(alloc_page() == NULL);
ffffffffc0201df8:	4505                	li	a0,1
ffffffffc0201dfa:	3cf000ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0201dfe:	2c051d63          	bnez	a0,ffffffffc02020d8 <default_check+0x576>

    assert(nr_free == 0);
ffffffffc0201e02:	481c                	lw	a5,16(s0)
ffffffffc0201e04:	2a079a63          	bnez	a5,ffffffffc02020b8 <default_check+0x556>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201e08:	4595                	li	a1,5
ffffffffc0201e0a:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0201e0c:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0201e10:	01643023          	sd	s6,0(s0)
ffffffffc0201e14:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0201e18:	443000ef          	jal	ra,ffffffffc0202a5a <free_pages>
    return listelm->next;
ffffffffc0201e1c:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201e1e:	00878963          	beq	a5,s0,ffffffffc0201e30 <default_check+0x2ce>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0201e22:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201e26:	679c                	ld	a5,8(a5)
ffffffffc0201e28:	397d                	addiw	s2,s2,-1
ffffffffc0201e2a:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201e2c:	fe879be3          	bne	a5,s0,ffffffffc0201e22 <default_check+0x2c0>
    }
    assert(count == 0);
ffffffffc0201e30:	26091463          	bnez	s2,ffffffffc0202098 <default_check+0x536>
    assert(total == 0);
ffffffffc0201e34:	46049263          	bnez	s1,ffffffffc0202298 <default_check+0x736>
}
ffffffffc0201e38:	60a6                	ld	ra,72(sp)
ffffffffc0201e3a:	6406                	ld	s0,64(sp)
ffffffffc0201e3c:	74e2                	ld	s1,56(sp)
ffffffffc0201e3e:	7942                	ld	s2,48(sp)
ffffffffc0201e40:	79a2                	ld	s3,40(sp)
ffffffffc0201e42:	7a02                	ld	s4,32(sp)
ffffffffc0201e44:	6ae2                	ld	s5,24(sp)
ffffffffc0201e46:	6b42                	ld	s6,16(sp)
ffffffffc0201e48:	6ba2                	ld	s7,8(sp)
ffffffffc0201e4a:	6c02                	ld	s8,0(sp)
ffffffffc0201e4c:	6161                	addi	sp,sp,80
ffffffffc0201e4e:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201e50:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201e52:	4481                	li	s1,0
ffffffffc0201e54:	4901                	li	s2,0
ffffffffc0201e56:	b3b9                	j	ffffffffc0201ba4 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0201e58:	00003697          	auipc	a3,0x3
ffffffffc0201e5c:	2a868693          	addi	a3,a3,680 # ffffffffc0205100 <commands+0xae0>
ffffffffc0201e60:	00003617          	auipc	a2,0x3
ffffffffc0201e64:	ee860613          	addi	a2,a2,-280 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201e68:	0f000593          	li	a1,240
ffffffffc0201e6c:	00003517          	auipc	a0,0x3
ffffffffc0201e70:	62450513          	addi	a0,a0,1572 # ffffffffc0205490 <commands+0xe70>
ffffffffc0201e74:	a8efe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201e78:	00003697          	auipc	a3,0x3
ffffffffc0201e7c:	69068693          	addi	a3,a3,1680 # ffffffffc0205508 <commands+0xee8>
ffffffffc0201e80:	00003617          	auipc	a2,0x3
ffffffffc0201e84:	ec860613          	addi	a2,a2,-312 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201e88:	0bd00593          	li	a1,189
ffffffffc0201e8c:	00003517          	auipc	a0,0x3
ffffffffc0201e90:	60450513          	addi	a0,a0,1540 # ffffffffc0205490 <commands+0xe70>
ffffffffc0201e94:	a6efe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201e98:	00003697          	auipc	a3,0x3
ffffffffc0201e9c:	69868693          	addi	a3,a3,1688 # ffffffffc0205530 <commands+0xf10>
ffffffffc0201ea0:	00003617          	auipc	a2,0x3
ffffffffc0201ea4:	ea860613          	addi	a2,a2,-344 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201ea8:	0be00593          	li	a1,190
ffffffffc0201eac:	00003517          	auipc	a0,0x3
ffffffffc0201eb0:	5e450513          	addi	a0,a0,1508 # ffffffffc0205490 <commands+0xe70>
ffffffffc0201eb4:	a4efe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201eb8:	00003697          	auipc	a3,0x3
ffffffffc0201ebc:	6b868693          	addi	a3,a3,1720 # ffffffffc0205570 <commands+0xf50>
ffffffffc0201ec0:	00003617          	auipc	a2,0x3
ffffffffc0201ec4:	e8860613          	addi	a2,a2,-376 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201ec8:	0c000593          	li	a1,192
ffffffffc0201ecc:	00003517          	auipc	a0,0x3
ffffffffc0201ed0:	5c450513          	addi	a0,a0,1476 # ffffffffc0205490 <commands+0xe70>
ffffffffc0201ed4:	a2efe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201ed8:	00003697          	auipc	a3,0x3
ffffffffc0201edc:	72068693          	addi	a3,a3,1824 # ffffffffc02055f8 <commands+0xfd8>
ffffffffc0201ee0:	00003617          	auipc	a2,0x3
ffffffffc0201ee4:	e6860613          	addi	a2,a2,-408 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201ee8:	0d900593          	li	a1,217
ffffffffc0201eec:	00003517          	auipc	a0,0x3
ffffffffc0201ef0:	5a450513          	addi	a0,a0,1444 # ffffffffc0205490 <commands+0xe70>
ffffffffc0201ef4:	a0efe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201ef8:	00003697          	auipc	a3,0x3
ffffffffc0201efc:	5b068693          	addi	a3,a3,1456 # ffffffffc02054a8 <commands+0xe88>
ffffffffc0201f00:	00003617          	auipc	a2,0x3
ffffffffc0201f04:	e4860613          	addi	a2,a2,-440 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201f08:	0d200593          	li	a1,210
ffffffffc0201f0c:	00003517          	auipc	a0,0x3
ffffffffc0201f10:	58450513          	addi	a0,a0,1412 # ffffffffc0205490 <commands+0xe70>
ffffffffc0201f14:	9eefe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free == 3);
ffffffffc0201f18:	00003697          	auipc	a3,0x3
ffffffffc0201f1c:	6d068693          	addi	a3,a3,1744 # ffffffffc02055e8 <commands+0xfc8>
ffffffffc0201f20:	00003617          	auipc	a2,0x3
ffffffffc0201f24:	e2860613          	addi	a2,a2,-472 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201f28:	0d000593          	li	a1,208
ffffffffc0201f2c:	00003517          	auipc	a0,0x3
ffffffffc0201f30:	56450513          	addi	a0,a0,1380 # ffffffffc0205490 <commands+0xe70>
ffffffffc0201f34:	9cefe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201f38:	00003697          	auipc	a3,0x3
ffffffffc0201f3c:	69868693          	addi	a3,a3,1688 # ffffffffc02055d0 <commands+0xfb0>
ffffffffc0201f40:	00003617          	auipc	a2,0x3
ffffffffc0201f44:	e0860613          	addi	a2,a2,-504 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201f48:	0cb00593          	li	a1,203
ffffffffc0201f4c:	00003517          	auipc	a0,0x3
ffffffffc0201f50:	54450513          	addi	a0,a0,1348 # ffffffffc0205490 <commands+0xe70>
ffffffffc0201f54:	9aefe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201f58:	00003697          	auipc	a3,0x3
ffffffffc0201f5c:	65868693          	addi	a3,a3,1624 # ffffffffc02055b0 <commands+0xf90>
ffffffffc0201f60:	00003617          	auipc	a2,0x3
ffffffffc0201f64:	de860613          	addi	a2,a2,-536 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201f68:	0c200593          	li	a1,194
ffffffffc0201f6c:	00003517          	auipc	a0,0x3
ffffffffc0201f70:	52450513          	addi	a0,a0,1316 # ffffffffc0205490 <commands+0xe70>
ffffffffc0201f74:	98efe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(p0 != NULL);
ffffffffc0201f78:	00003697          	auipc	a3,0x3
ffffffffc0201f7c:	6b868693          	addi	a3,a3,1720 # ffffffffc0205630 <commands+0x1010>
ffffffffc0201f80:	00003617          	auipc	a2,0x3
ffffffffc0201f84:	dc860613          	addi	a2,a2,-568 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201f88:	0f800593          	li	a1,248
ffffffffc0201f8c:	00003517          	auipc	a0,0x3
ffffffffc0201f90:	50450513          	addi	a0,a0,1284 # ffffffffc0205490 <commands+0xe70>
ffffffffc0201f94:	96efe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free == 0);
ffffffffc0201f98:	00003697          	auipc	a3,0x3
ffffffffc0201f9c:	31868693          	addi	a3,a3,792 # ffffffffc02052b0 <commands+0xc90>
ffffffffc0201fa0:	00003617          	auipc	a2,0x3
ffffffffc0201fa4:	da860613          	addi	a2,a2,-600 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201fa8:	0df00593          	li	a1,223
ffffffffc0201fac:	00003517          	auipc	a0,0x3
ffffffffc0201fb0:	4e450513          	addi	a0,a0,1252 # ffffffffc0205490 <commands+0xe70>
ffffffffc0201fb4:	94efe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201fb8:	00003697          	auipc	a3,0x3
ffffffffc0201fbc:	61868693          	addi	a3,a3,1560 # ffffffffc02055d0 <commands+0xfb0>
ffffffffc0201fc0:	00003617          	auipc	a2,0x3
ffffffffc0201fc4:	d8860613          	addi	a2,a2,-632 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201fc8:	0dd00593          	li	a1,221
ffffffffc0201fcc:	00003517          	auipc	a0,0x3
ffffffffc0201fd0:	4c450513          	addi	a0,a0,1220 # ffffffffc0205490 <commands+0xe70>
ffffffffc0201fd4:	92efe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201fd8:	00003697          	auipc	a3,0x3
ffffffffc0201fdc:	63868693          	addi	a3,a3,1592 # ffffffffc0205610 <commands+0xff0>
ffffffffc0201fe0:	00003617          	auipc	a2,0x3
ffffffffc0201fe4:	d6860613          	addi	a2,a2,-664 # ffffffffc0204d48 <commands+0x728>
ffffffffc0201fe8:	0dc00593          	li	a1,220
ffffffffc0201fec:	00003517          	auipc	a0,0x3
ffffffffc0201ff0:	4a450513          	addi	a0,a0,1188 # ffffffffc0205490 <commands+0xe70>
ffffffffc0201ff4:	90efe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201ff8:	00003697          	auipc	a3,0x3
ffffffffc0201ffc:	4b068693          	addi	a3,a3,1200 # ffffffffc02054a8 <commands+0xe88>
ffffffffc0202000:	00003617          	auipc	a2,0x3
ffffffffc0202004:	d4860613          	addi	a2,a2,-696 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202008:	0b900593          	li	a1,185
ffffffffc020200c:	00003517          	auipc	a0,0x3
ffffffffc0202010:	48450513          	addi	a0,a0,1156 # ffffffffc0205490 <commands+0xe70>
ffffffffc0202014:	8eefe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202018:	00003697          	auipc	a3,0x3
ffffffffc020201c:	5b868693          	addi	a3,a3,1464 # ffffffffc02055d0 <commands+0xfb0>
ffffffffc0202020:	00003617          	auipc	a2,0x3
ffffffffc0202024:	d2860613          	addi	a2,a2,-728 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202028:	0d600593          	li	a1,214
ffffffffc020202c:	00003517          	auipc	a0,0x3
ffffffffc0202030:	46450513          	addi	a0,a0,1124 # ffffffffc0205490 <commands+0xe70>
ffffffffc0202034:	8cefe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202038:	00003697          	auipc	a3,0x3
ffffffffc020203c:	4b068693          	addi	a3,a3,1200 # ffffffffc02054e8 <commands+0xec8>
ffffffffc0202040:	00003617          	auipc	a2,0x3
ffffffffc0202044:	d0860613          	addi	a2,a2,-760 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202048:	0d400593          	li	a1,212
ffffffffc020204c:	00003517          	auipc	a0,0x3
ffffffffc0202050:	44450513          	addi	a0,a0,1092 # ffffffffc0205490 <commands+0xe70>
ffffffffc0202054:	8aefe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202058:	00003697          	auipc	a3,0x3
ffffffffc020205c:	47068693          	addi	a3,a3,1136 # ffffffffc02054c8 <commands+0xea8>
ffffffffc0202060:	00003617          	auipc	a2,0x3
ffffffffc0202064:	ce860613          	addi	a2,a2,-792 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202068:	0d300593          	li	a1,211
ffffffffc020206c:	00003517          	auipc	a0,0x3
ffffffffc0202070:	42450513          	addi	a0,a0,1060 # ffffffffc0205490 <commands+0xe70>
ffffffffc0202074:	88efe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202078:	00003697          	auipc	a3,0x3
ffffffffc020207c:	47068693          	addi	a3,a3,1136 # ffffffffc02054e8 <commands+0xec8>
ffffffffc0202080:	00003617          	auipc	a2,0x3
ffffffffc0202084:	cc860613          	addi	a2,a2,-824 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202088:	0bb00593          	li	a1,187
ffffffffc020208c:	00003517          	auipc	a0,0x3
ffffffffc0202090:	40450513          	addi	a0,a0,1028 # ffffffffc0205490 <commands+0xe70>
ffffffffc0202094:	86efe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(count == 0);
ffffffffc0202098:	00003697          	auipc	a3,0x3
ffffffffc020209c:	6e868693          	addi	a3,a3,1768 # ffffffffc0205780 <commands+0x1160>
ffffffffc02020a0:	00003617          	auipc	a2,0x3
ffffffffc02020a4:	ca860613          	addi	a2,a2,-856 # ffffffffc0204d48 <commands+0x728>
ffffffffc02020a8:	12500593          	li	a1,293
ffffffffc02020ac:	00003517          	auipc	a0,0x3
ffffffffc02020b0:	3e450513          	addi	a0,a0,996 # ffffffffc0205490 <commands+0xe70>
ffffffffc02020b4:	84efe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free == 0);
ffffffffc02020b8:	00003697          	auipc	a3,0x3
ffffffffc02020bc:	1f868693          	addi	a3,a3,504 # ffffffffc02052b0 <commands+0xc90>
ffffffffc02020c0:	00003617          	auipc	a2,0x3
ffffffffc02020c4:	c8860613          	addi	a2,a2,-888 # ffffffffc0204d48 <commands+0x728>
ffffffffc02020c8:	11a00593          	li	a1,282
ffffffffc02020cc:	00003517          	auipc	a0,0x3
ffffffffc02020d0:	3c450513          	addi	a0,a0,964 # ffffffffc0205490 <commands+0xe70>
ffffffffc02020d4:	82efe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02020d8:	00003697          	auipc	a3,0x3
ffffffffc02020dc:	4f868693          	addi	a3,a3,1272 # ffffffffc02055d0 <commands+0xfb0>
ffffffffc02020e0:	00003617          	auipc	a2,0x3
ffffffffc02020e4:	c6860613          	addi	a2,a2,-920 # ffffffffc0204d48 <commands+0x728>
ffffffffc02020e8:	11800593          	li	a1,280
ffffffffc02020ec:	00003517          	auipc	a0,0x3
ffffffffc02020f0:	3a450513          	addi	a0,a0,932 # ffffffffc0205490 <commands+0xe70>
ffffffffc02020f4:	80efe0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02020f8:	00003697          	auipc	a3,0x3
ffffffffc02020fc:	49868693          	addi	a3,a3,1176 # ffffffffc0205590 <commands+0xf70>
ffffffffc0202100:	00003617          	auipc	a2,0x3
ffffffffc0202104:	c4860613          	addi	a2,a2,-952 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202108:	0c100593          	li	a1,193
ffffffffc020210c:	00003517          	auipc	a0,0x3
ffffffffc0202110:	38450513          	addi	a0,a0,900 # ffffffffc0205490 <commands+0xe70>
ffffffffc0202114:	feffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0202118:	00003697          	auipc	a3,0x3
ffffffffc020211c:	62868693          	addi	a3,a3,1576 # ffffffffc0205740 <commands+0x1120>
ffffffffc0202120:	00003617          	auipc	a2,0x3
ffffffffc0202124:	c2860613          	addi	a2,a2,-984 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202128:	11200593          	li	a1,274
ffffffffc020212c:	00003517          	auipc	a0,0x3
ffffffffc0202130:	36450513          	addi	a0,a0,868 # ffffffffc0205490 <commands+0xe70>
ffffffffc0202134:	fcffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0202138:	00003697          	auipc	a3,0x3
ffffffffc020213c:	5e868693          	addi	a3,a3,1512 # ffffffffc0205720 <commands+0x1100>
ffffffffc0202140:	00003617          	auipc	a2,0x3
ffffffffc0202144:	c0860613          	addi	a2,a2,-1016 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202148:	11000593          	li	a1,272
ffffffffc020214c:	00003517          	auipc	a0,0x3
ffffffffc0202150:	34450513          	addi	a0,a0,836 # ffffffffc0205490 <commands+0xe70>
ffffffffc0202154:	faffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0202158:	00003697          	auipc	a3,0x3
ffffffffc020215c:	5a068693          	addi	a3,a3,1440 # ffffffffc02056f8 <commands+0x10d8>
ffffffffc0202160:	00003617          	auipc	a2,0x3
ffffffffc0202164:	be860613          	addi	a2,a2,-1048 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202168:	10e00593          	li	a1,270
ffffffffc020216c:	00003517          	auipc	a0,0x3
ffffffffc0202170:	32450513          	addi	a0,a0,804 # ffffffffc0205490 <commands+0xe70>
ffffffffc0202174:	f8ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0202178:	00003697          	auipc	a3,0x3
ffffffffc020217c:	55868693          	addi	a3,a3,1368 # ffffffffc02056d0 <commands+0x10b0>
ffffffffc0202180:	00003617          	auipc	a2,0x3
ffffffffc0202184:	bc860613          	addi	a2,a2,-1080 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202188:	10d00593          	li	a1,269
ffffffffc020218c:	00003517          	auipc	a0,0x3
ffffffffc0202190:	30450513          	addi	a0,a0,772 # ffffffffc0205490 <commands+0xe70>
ffffffffc0202194:	f6ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0202198:	00003697          	auipc	a3,0x3
ffffffffc020219c:	52868693          	addi	a3,a3,1320 # ffffffffc02056c0 <commands+0x10a0>
ffffffffc02021a0:	00003617          	auipc	a2,0x3
ffffffffc02021a4:	ba860613          	addi	a2,a2,-1112 # ffffffffc0204d48 <commands+0x728>
ffffffffc02021a8:	10800593          	li	a1,264
ffffffffc02021ac:	00003517          	auipc	a0,0x3
ffffffffc02021b0:	2e450513          	addi	a0,a0,740 # ffffffffc0205490 <commands+0xe70>
ffffffffc02021b4:	f4ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02021b8:	00003697          	auipc	a3,0x3
ffffffffc02021bc:	41868693          	addi	a3,a3,1048 # ffffffffc02055d0 <commands+0xfb0>
ffffffffc02021c0:	00003617          	auipc	a2,0x3
ffffffffc02021c4:	b8860613          	addi	a2,a2,-1144 # ffffffffc0204d48 <commands+0x728>
ffffffffc02021c8:	10700593          	li	a1,263
ffffffffc02021cc:	00003517          	auipc	a0,0x3
ffffffffc02021d0:	2c450513          	addi	a0,a0,708 # ffffffffc0205490 <commands+0xe70>
ffffffffc02021d4:	f2ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02021d8:	00003697          	auipc	a3,0x3
ffffffffc02021dc:	4c868693          	addi	a3,a3,1224 # ffffffffc02056a0 <commands+0x1080>
ffffffffc02021e0:	00003617          	auipc	a2,0x3
ffffffffc02021e4:	b6860613          	addi	a2,a2,-1176 # ffffffffc0204d48 <commands+0x728>
ffffffffc02021e8:	10600593          	li	a1,262
ffffffffc02021ec:	00003517          	auipc	a0,0x3
ffffffffc02021f0:	2a450513          	addi	a0,a0,676 # ffffffffc0205490 <commands+0xe70>
ffffffffc02021f4:	f0ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02021f8:	00003697          	auipc	a3,0x3
ffffffffc02021fc:	47868693          	addi	a3,a3,1144 # ffffffffc0205670 <commands+0x1050>
ffffffffc0202200:	00003617          	auipc	a2,0x3
ffffffffc0202204:	b4860613          	addi	a2,a2,-1208 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202208:	10500593          	li	a1,261
ffffffffc020220c:	00003517          	auipc	a0,0x3
ffffffffc0202210:	28450513          	addi	a0,a0,644 # ffffffffc0205490 <commands+0xe70>
ffffffffc0202214:	eeffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0202218:	00003697          	auipc	a3,0x3
ffffffffc020221c:	44068693          	addi	a3,a3,1088 # ffffffffc0205658 <commands+0x1038>
ffffffffc0202220:	00003617          	auipc	a2,0x3
ffffffffc0202224:	b2860613          	addi	a2,a2,-1240 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202228:	10400593          	li	a1,260
ffffffffc020222c:	00003517          	auipc	a0,0x3
ffffffffc0202230:	26450513          	addi	a0,a0,612 # ffffffffc0205490 <commands+0xe70>
ffffffffc0202234:	ecffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202238:	00003697          	auipc	a3,0x3
ffffffffc020223c:	39868693          	addi	a3,a3,920 # ffffffffc02055d0 <commands+0xfb0>
ffffffffc0202240:	00003617          	auipc	a2,0x3
ffffffffc0202244:	b0860613          	addi	a2,a2,-1272 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202248:	0fe00593          	li	a1,254
ffffffffc020224c:	00003517          	auipc	a0,0x3
ffffffffc0202250:	24450513          	addi	a0,a0,580 # ffffffffc0205490 <commands+0xe70>
ffffffffc0202254:	eaffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(!PageProperty(p0));
ffffffffc0202258:	00003697          	auipc	a3,0x3
ffffffffc020225c:	3e868693          	addi	a3,a3,1000 # ffffffffc0205640 <commands+0x1020>
ffffffffc0202260:	00003617          	auipc	a2,0x3
ffffffffc0202264:	ae860613          	addi	a2,a2,-1304 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202268:	0f900593          	li	a1,249
ffffffffc020226c:	00003517          	auipc	a0,0x3
ffffffffc0202270:	22450513          	addi	a0,a0,548 # ffffffffc0205490 <commands+0xe70>
ffffffffc0202274:	e8ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0202278:	00003697          	auipc	a3,0x3
ffffffffc020227c:	4e868693          	addi	a3,a3,1256 # ffffffffc0205760 <commands+0x1140>
ffffffffc0202280:	00003617          	auipc	a2,0x3
ffffffffc0202284:	ac860613          	addi	a2,a2,-1336 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202288:	11700593          	li	a1,279
ffffffffc020228c:	00003517          	auipc	a0,0x3
ffffffffc0202290:	20450513          	addi	a0,a0,516 # ffffffffc0205490 <commands+0xe70>
ffffffffc0202294:	e6ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(total == 0);
ffffffffc0202298:	00003697          	auipc	a3,0x3
ffffffffc020229c:	4f868693          	addi	a3,a3,1272 # ffffffffc0205790 <commands+0x1170>
ffffffffc02022a0:	00003617          	auipc	a2,0x3
ffffffffc02022a4:	aa860613          	addi	a2,a2,-1368 # ffffffffc0204d48 <commands+0x728>
ffffffffc02022a8:	12600593          	li	a1,294
ffffffffc02022ac:	00003517          	auipc	a0,0x3
ffffffffc02022b0:	1e450513          	addi	a0,a0,484 # ffffffffc0205490 <commands+0xe70>
ffffffffc02022b4:	e4ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(total == nr_free_pages());
ffffffffc02022b8:	00003697          	auipc	a3,0x3
ffffffffc02022bc:	e5868693          	addi	a3,a3,-424 # ffffffffc0205110 <commands+0xaf0>
ffffffffc02022c0:	00003617          	auipc	a2,0x3
ffffffffc02022c4:	a8860613          	addi	a2,a2,-1400 # ffffffffc0204d48 <commands+0x728>
ffffffffc02022c8:	0f300593          	li	a1,243
ffffffffc02022cc:	00003517          	auipc	a0,0x3
ffffffffc02022d0:	1c450513          	addi	a0,a0,452 # ffffffffc0205490 <commands+0xe70>
ffffffffc02022d4:	e2ffd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02022d8:	00003697          	auipc	a3,0x3
ffffffffc02022dc:	1f068693          	addi	a3,a3,496 # ffffffffc02054c8 <commands+0xea8>
ffffffffc02022e0:	00003617          	auipc	a2,0x3
ffffffffc02022e4:	a6860613          	addi	a2,a2,-1432 # ffffffffc0204d48 <commands+0x728>
ffffffffc02022e8:	0ba00593          	li	a1,186
ffffffffc02022ec:	00003517          	auipc	a0,0x3
ffffffffc02022f0:	1a450513          	addi	a0,a0,420 # ffffffffc0205490 <commands+0xe70>
ffffffffc02022f4:	e0ffd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc02022f8 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc02022f8:	1141                	addi	sp,sp,-16
ffffffffc02022fa:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02022fc:	14058a63          	beqz	a1,ffffffffc0202450 <default_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc0202300:	00359693          	slli	a3,a1,0x3
ffffffffc0202304:	96ae                	add	a3,a3,a1
ffffffffc0202306:	068e                	slli	a3,a3,0x3
ffffffffc0202308:	96aa                	add	a3,a3,a0
ffffffffc020230a:	87aa                	mv	a5,a0
ffffffffc020230c:	02d50263          	beq	a0,a3,ffffffffc0202330 <default_free_pages+0x38>
ffffffffc0202310:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0202312:	8b05                	andi	a4,a4,1
ffffffffc0202314:	10071e63          	bnez	a4,ffffffffc0202430 <default_free_pages+0x138>
ffffffffc0202318:	6798                	ld	a4,8(a5)
ffffffffc020231a:	8b09                	andi	a4,a4,2
ffffffffc020231c:	10071a63          	bnez	a4,ffffffffc0202430 <default_free_pages+0x138>
        p->flags = 0;
ffffffffc0202320:	0007b423          	sd	zero,8(a5)
    return page->ref; 
}

// 设置 Page 的引用计数
static inline void set_page_ref(struct Page *page, int val) { 
    page->ref = val; 
ffffffffc0202324:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0202328:	04878793          	addi	a5,a5,72
ffffffffc020232c:	fed792e3          	bne	a5,a3,ffffffffc0202310 <default_free_pages+0x18>
    base->property = n;
ffffffffc0202330:	2581                	sext.w	a1,a1
ffffffffc0202332:	cd0c                	sw	a1,24(a0)
    SetPageProperty(base);
ffffffffc0202334:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0202338:	4789                	li	a5,2
ffffffffc020233a:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020233e:	0000f697          	auipc	a3,0xf
ffffffffc0202342:	da268693          	addi	a3,a3,-606 # ffffffffc02110e0 <free_area>
ffffffffc0202346:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0202348:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020234a:	02050613          	addi	a2,a0,32
    nr_free += n;
ffffffffc020234e:	9db9                	addw	a1,a1,a4
ffffffffc0202350:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0202352:	0ad78863          	beq	a5,a3,ffffffffc0202402 <default_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc0202356:	fe078713          	addi	a4,a5,-32
ffffffffc020235a:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020235e:	4581                	li	a1,0
            if (base < page) {
ffffffffc0202360:	00e56a63          	bltu	a0,a4,ffffffffc0202374 <default_free_pages+0x7c>
    return listelm->next;
ffffffffc0202364:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0202366:	06d70263          	beq	a4,a3,ffffffffc02023ca <default_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc020236a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020236c:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc0202370:	fee57ae3          	bgeu	a0,a4,ffffffffc0202364 <default_free_pages+0x6c>
ffffffffc0202374:	c199                	beqz	a1,ffffffffc020237a <default_free_pages+0x82>
ffffffffc0202376:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020237a:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc020237c:	e390                	sd	a2,0(a5)
ffffffffc020237e:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0202380:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc0202382:	f118                	sd	a4,32(a0)
    if (le != &free_list) {
ffffffffc0202384:	02d70063          	beq	a4,a3,ffffffffc02023a4 <default_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc0202388:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc020238c:	fe070593          	addi	a1,a4,-32
        if (p + p->property == base) {
ffffffffc0202390:	02081613          	slli	a2,a6,0x20
ffffffffc0202394:	9201                	srli	a2,a2,0x20
ffffffffc0202396:	00361793          	slli	a5,a2,0x3
ffffffffc020239a:	97b2                	add	a5,a5,a2
ffffffffc020239c:	078e                	slli	a5,a5,0x3
ffffffffc020239e:	97ae                	add	a5,a5,a1
ffffffffc02023a0:	02f50f63          	beq	a0,a5,ffffffffc02023de <default_free_pages+0xe6>
    return listelm->next;
ffffffffc02023a4:	7518                	ld	a4,40(a0)
    if (le != &free_list) {
ffffffffc02023a6:	00d70f63          	beq	a4,a3,ffffffffc02023c4 <default_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc02023aa:	4d0c                	lw	a1,24(a0)
        p = le2page(le, page_link);
ffffffffc02023ac:	fe070693          	addi	a3,a4,-32
        if (base + base->property == p) {
ffffffffc02023b0:	02059613          	slli	a2,a1,0x20
ffffffffc02023b4:	9201                	srli	a2,a2,0x20
ffffffffc02023b6:	00361793          	slli	a5,a2,0x3
ffffffffc02023ba:	97b2                	add	a5,a5,a2
ffffffffc02023bc:	078e                	slli	a5,a5,0x3
ffffffffc02023be:	97aa                	add	a5,a5,a0
ffffffffc02023c0:	04f68863          	beq	a3,a5,ffffffffc0202410 <default_free_pages+0x118>
}
ffffffffc02023c4:	60a2                	ld	ra,8(sp)
ffffffffc02023c6:	0141                	addi	sp,sp,16
ffffffffc02023c8:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02023ca:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02023cc:	f514                	sd	a3,40(a0)
    return listelm->next;
ffffffffc02023ce:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02023d0:	f11c                	sd	a5,32(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02023d2:	02d70563          	beq	a4,a3,ffffffffc02023fc <default_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc02023d6:	8832                	mv	a6,a2
ffffffffc02023d8:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02023da:	87ba                	mv	a5,a4
ffffffffc02023dc:	bf41                	j	ffffffffc020236c <default_free_pages+0x74>
            p->property += base->property;
ffffffffc02023de:	4d1c                	lw	a5,24(a0)
ffffffffc02023e0:	0107883b          	addw	a6,a5,a6
ffffffffc02023e4:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02023e8:	57f5                	li	a5,-3
ffffffffc02023ea:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02023ee:	7110                	ld	a2,32(a0)
ffffffffc02023f0:	751c                	ld	a5,40(a0)
            base = p;
ffffffffc02023f2:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc02023f4:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc02023f6:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc02023f8:	e390                	sd	a2,0(a5)
ffffffffc02023fa:	b775                	j	ffffffffc02023a6 <default_free_pages+0xae>
ffffffffc02023fc:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02023fe:	873e                	mv	a4,a5
ffffffffc0202400:	b761                	j	ffffffffc0202388 <default_free_pages+0x90>
}
ffffffffc0202402:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0202404:	e390                	sd	a2,0(a5)
ffffffffc0202406:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202408:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc020240a:	f11c                	sd	a5,32(a0)
ffffffffc020240c:	0141                	addi	sp,sp,16
ffffffffc020240e:	8082                	ret
            base->property += p->property;
ffffffffc0202410:	ff872783          	lw	a5,-8(a4)
ffffffffc0202414:	fe870693          	addi	a3,a4,-24
ffffffffc0202418:	9dbd                	addw	a1,a1,a5
ffffffffc020241a:	cd0c                	sw	a1,24(a0)
ffffffffc020241c:	57f5                	li	a5,-3
ffffffffc020241e:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0202422:	6314                	ld	a3,0(a4)
ffffffffc0202424:	671c                	ld	a5,8(a4)
}
ffffffffc0202426:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0202428:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc020242a:	e394                	sd	a3,0(a5)
ffffffffc020242c:	0141                	addi	sp,sp,16
ffffffffc020242e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0202430:	00003697          	auipc	a3,0x3
ffffffffc0202434:	37868693          	addi	a3,a3,888 # ffffffffc02057a8 <commands+0x1188>
ffffffffc0202438:	00003617          	auipc	a2,0x3
ffffffffc020243c:	91060613          	addi	a2,a2,-1776 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202440:	08300593          	li	a1,131
ffffffffc0202444:	00003517          	auipc	a0,0x3
ffffffffc0202448:	04c50513          	addi	a0,a0,76 # ffffffffc0205490 <commands+0xe70>
ffffffffc020244c:	cb7fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(n > 0);
ffffffffc0202450:	00003697          	auipc	a3,0x3
ffffffffc0202454:	35068693          	addi	a3,a3,848 # ffffffffc02057a0 <commands+0x1180>
ffffffffc0202458:	00003617          	auipc	a2,0x3
ffffffffc020245c:	8f060613          	addi	a2,a2,-1808 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202460:	08000593          	li	a1,128
ffffffffc0202464:	00003517          	auipc	a0,0x3
ffffffffc0202468:	02c50513          	addi	a0,a0,44 # ffffffffc0205490 <commands+0xe70>
ffffffffc020246c:	c97fd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0202470 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0202470:	c959                	beqz	a0,ffffffffc0202506 <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc0202472:	0000f597          	auipc	a1,0xf
ffffffffc0202476:	c6e58593          	addi	a1,a1,-914 # ffffffffc02110e0 <free_area>
ffffffffc020247a:	0105a803          	lw	a6,16(a1)
ffffffffc020247e:	862a                	mv	a2,a0
ffffffffc0202480:	02081793          	slli	a5,a6,0x20
ffffffffc0202484:	9381                	srli	a5,a5,0x20
ffffffffc0202486:	00a7ee63          	bltu	a5,a0,ffffffffc02024a2 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc020248a:	87ae                	mv	a5,a1
ffffffffc020248c:	a801                	j	ffffffffc020249c <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc020248e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202492:	02071693          	slli	a3,a4,0x20
ffffffffc0202496:	9281                	srli	a3,a3,0x20
ffffffffc0202498:	00c6f763          	bgeu	a3,a2,ffffffffc02024a6 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc020249c:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020249e:	feb798e3          	bne	a5,a1,ffffffffc020248e <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02024a2:	4501                	li	a0,0
}
ffffffffc02024a4:	8082                	ret
    return listelm->prev;
ffffffffc02024a6:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02024aa:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02024ae:	fe078513          	addi	a0,a5,-32
            p->property = page->property - n;
ffffffffc02024b2:	00060e1b          	sext.w	t3,a2
    prev->next = next;
ffffffffc02024b6:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02024ba:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc02024be:	02d67b63          	bgeu	a2,a3,ffffffffc02024f4 <default_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc02024c2:	00361693          	slli	a3,a2,0x3
ffffffffc02024c6:	96b2                	add	a3,a3,a2
ffffffffc02024c8:	068e                	slli	a3,a3,0x3
ffffffffc02024ca:	96aa                	add	a3,a3,a0
            p->property = page->property - n;
ffffffffc02024cc:	41c7073b          	subw	a4,a4,t3
ffffffffc02024d0:	ce98                	sw	a4,24(a3)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02024d2:	00868613          	addi	a2,a3,8
ffffffffc02024d6:	4709                	li	a4,2
ffffffffc02024d8:	40e6302f          	amoor.d	zero,a4,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02024dc:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02024e0:	02068613          	addi	a2,a3,32
        nr_free -= n;
ffffffffc02024e4:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02024e8:	e310                	sd	a2,0(a4)
ffffffffc02024ea:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02024ee:	f698                	sd	a4,40(a3)
    elm->prev = prev;
ffffffffc02024f0:	0316b023          	sd	a7,32(a3)
ffffffffc02024f4:	41c8083b          	subw	a6,a6,t3
ffffffffc02024f8:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02024fc:	5775                	li	a4,-3
ffffffffc02024fe:	17a1                	addi	a5,a5,-24
ffffffffc0202500:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0202504:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0202506:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0202508:	00003697          	auipc	a3,0x3
ffffffffc020250c:	29868693          	addi	a3,a3,664 # ffffffffc02057a0 <commands+0x1180>
ffffffffc0202510:	00003617          	auipc	a2,0x3
ffffffffc0202514:	83860613          	addi	a2,a2,-1992 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202518:	06200593          	li	a1,98
ffffffffc020251c:	00003517          	auipc	a0,0x3
ffffffffc0202520:	f7450513          	addi	a0,a0,-140 # ffffffffc0205490 <commands+0xe70>
default_alloc_pages(size_t n) {
ffffffffc0202524:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0202526:	bddfd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc020252a <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc020252a:	1141                	addi	sp,sp,-16
ffffffffc020252c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020252e:	c9e1                	beqz	a1,ffffffffc02025fe <default_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc0202530:	00359693          	slli	a3,a1,0x3
ffffffffc0202534:	96ae                	add	a3,a3,a1
ffffffffc0202536:	068e                	slli	a3,a3,0x3
ffffffffc0202538:	96aa                	add	a3,a3,a0
ffffffffc020253a:	87aa                	mv	a5,a0
ffffffffc020253c:	00d50f63          	beq	a0,a3,ffffffffc020255a <default_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0202540:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0202542:	8b05                	andi	a4,a4,1
ffffffffc0202544:	cf49                	beqz	a4,ffffffffc02025de <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0202546:	0007ac23          	sw	zero,24(a5)
ffffffffc020254a:	0007b423          	sd	zero,8(a5)
ffffffffc020254e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0202552:	04878793          	addi	a5,a5,72
ffffffffc0202556:	fed795e3          	bne	a5,a3,ffffffffc0202540 <default_init_memmap+0x16>
    base->property = n;
ffffffffc020255a:	2581                	sext.w	a1,a1
ffffffffc020255c:	cd0c                	sw	a1,24(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020255e:	4789                	li	a5,2
ffffffffc0202560:	00850713          	addi	a4,a0,8
ffffffffc0202564:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0202568:	0000f697          	auipc	a3,0xf
ffffffffc020256c:	b7868693          	addi	a3,a3,-1160 # ffffffffc02110e0 <free_area>
ffffffffc0202570:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0202572:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0202574:	02050613          	addi	a2,a0,32
    nr_free += n;
ffffffffc0202578:	9db9                	addw	a1,a1,a4
ffffffffc020257a:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020257c:	04d78a63          	beq	a5,a3,ffffffffc02025d0 <default_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc0202580:	fe078713          	addi	a4,a5,-32
ffffffffc0202584:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0202588:	4581                	li	a1,0
            if (base < page) {
ffffffffc020258a:	00e56a63          	bltu	a0,a4,ffffffffc020259e <default_init_memmap+0x74>
    return listelm->next;
ffffffffc020258e:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0202590:	02d70263          	beq	a4,a3,ffffffffc02025b4 <default_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc0202594:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0202596:	fe078713          	addi	a4,a5,-32
            if (base < page) {
ffffffffc020259a:	fee57ae3          	bgeu	a0,a4,ffffffffc020258e <default_init_memmap+0x64>
ffffffffc020259e:	c199                	beqz	a1,ffffffffc02025a4 <default_init_memmap+0x7a>
ffffffffc02025a0:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02025a4:	6398                	ld	a4,0(a5)
}
ffffffffc02025a6:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02025a8:	e390                	sd	a2,0(a5)
ffffffffc02025aa:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02025ac:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02025ae:	f118                	sd	a4,32(a0)
ffffffffc02025b0:	0141                	addi	sp,sp,16
ffffffffc02025b2:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02025b4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02025b6:	f514                	sd	a3,40(a0)
    return listelm->next;
ffffffffc02025b8:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02025ba:	f11c                	sd	a5,32(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02025bc:	00d70663          	beq	a4,a3,ffffffffc02025c8 <default_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc02025c0:	8832                	mv	a6,a2
ffffffffc02025c2:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02025c4:	87ba                	mv	a5,a4
ffffffffc02025c6:	bfc1                	j	ffffffffc0202596 <default_init_memmap+0x6c>
}
ffffffffc02025c8:	60a2                	ld	ra,8(sp)
ffffffffc02025ca:	e290                	sd	a2,0(a3)
ffffffffc02025cc:	0141                	addi	sp,sp,16
ffffffffc02025ce:	8082                	ret
ffffffffc02025d0:	60a2                	ld	ra,8(sp)
ffffffffc02025d2:	e390                	sd	a2,0(a5)
ffffffffc02025d4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02025d6:	f51c                	sd	a5,40(a0)
    elm->prev = prev;
ffffffffc02025d8:	f11c                	sd	a5,32(a0)
ffffffffc02025da:	0141                	addi	sp,sp,16
ffffffffc02025dc:	8082                	ret
        assert(PageReserved(p));
ffffffffc02025de:	00003697          	auipc	a3,0x3
ffffffffc02025e2:	1f268693          	addi	a3,a3,498 # ffffffffc02057d0 <commands+0x11b0>
ffffffffc02025e6:	00002617          	auipc	a2,0x2
ffffffffc02025ea:	76260613          	addi	a2,a2,1890 # ffffffffc0204d48 <commands+0x728>
ffffffffc02025ee:	04900593          	li	a1,73
ffffffffc02025f2:	00003517          	auipc	a0,0x3
ffffffffc02025f6:	e9e50513          	addi	a0,a0,-354 # ffffffffc0205490 <commands+0xe70>
ffffffffc02025fa:	b09fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(n > 0);
ffffffffc02025fe:	00003697          	auipc	a3,0x3
ffffffffc0202602:	1a268693          	addi	a3,a3,418 # ffffffffc02057a0 <commands+0x1180>
ffffffffc0202606:	00002617          	auipc	a2,0x2
ffffffffc020260a:	74260613          	addi	a2,a2,1858 # ffffffffc0204d48 <commands+0x728>
ffffffffc020260e:	04600593          	li	a1,70
ffffffffc0202612:	00003517          	auipc	a0,0x3
ffffffffc0202616:	e7e50513          	addi	a0,a0,-386 # ffffffffc0205490 <commands+0xe70>
ffffffffc020261a:	ae9fd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc020261e <_clock_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc020261e:	0000f797          	auipc	a5,0xf
ffffffffc0202622:	a2278793          	addi	a5,a5,-1502 # ffffffffc0211040 <pra_list_head>
     // 将mm的私有成员指针指向pra_list_head，用于后续的页面替换算法操作
     

     list_init(&pra_list_head);
     curr_ptr=&pra_list_head;
     mm->sm_priv=&pra_list_head;
ffffffffc0202626:	f51c                	sd	a5,40(a0)
ffffffffc0202628:	e79c                	sd	a5,8(a5)
ffffffffc020262a:	e39c                	sd	a5,0(a5)
     curr_ptr=&pra_list_head;
ffffffffc020262c:	0000f717          	auipc	a4,0xf
ffffffffc0202630:	f0f73623          	sd	a5,-244(a4) # ffffffffc0211538 <curr_ptr>
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc0202634:	4501                	li	a0,0
ffffffffc0202636:	8082                	ret

ffffffffc0202638 <_clock_init>:

static int
_clock_init(void)
{
    return 0;
}
ffffffffc0202638:	4501                	li	a0,0
ffffffffc020263a:	8082                	ret

ffffffffc020263c <_clock_set_unswappable>:

static int
_clock_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc020263c:	4501                	li	a0,0
ffffffffc020263e:	8082                	ret

ffffffffc0202640 <_clock_tick_event>:

static int
_clock_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc0202640:	4501                	li	a0,0
ffffffffc0202642:	8082                	ret

ffffffffc0202644 <_clock_check_swap>:
_clock_check_swap(void) {
ffffffffc0202644:	1141                	addi	sp,sp,-16
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202646:	4731                	li	a4,12
_clock_check_swap(void) {
ffffffffc0202648:	e406                	sd	ra,8(sp)
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc020264a:	678d                	lui	a5,0x3
ffffffffc020264c:	00e78023          	sb	a4,0(a5) # 3000 <kern_entry-0xffffffffc01fd000>
    assert(pgfault_num==4);
ffffffffc0202650:	0000f697          	auipc	a3,0xf
ffffffffc0202654:	ec86a683          	lw	a3,-312(a3) # ffffffffc0211518 <pgfault_num>
ffffffffc0202658:	4711                	li	a4,4
ffffffffc020265a:	0ae69363          	bne	a3,a4,ffffffffc0202700 <_clock_check_swap+0xbc>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc020265e:	6705                	lui	a4,0x1
ffffffffc0202660:	4629                	li	a2,10
ffffffffc0202662:	0000f797          	auipc	a5,0xf
ffffffffc0202666:	eb678793          	addi	a5,a5,-330 # ffffffffc0211518 <pgfault_num>
ffffffffc020266a:	00c70023          	sb	a2,0(a4) # 1000 <kern_entry-0xffffffffc01ff000>
    assert(pgfault_num==4);
ffffffffc020266e:	4398                	lw	a4,0(a5)
ffffffffc0202670:	2701                	sext.w	a4,a4
ffffffffc0202672:	20d71763          	bne	a4,a3,ffffffffc0202880 <_clock_check_swap+0x23c>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0202676:	6691                	lui	a3,0x4
ffffffffc0202678:	4635                	li	a2,13
ffffffffc020267a:	00c68023          	sb	a2,0(a3) # 4000 <kern_entry-0xffffffffc01fc000>
    assert(pgfault_num==4);
ffffffffc020267e:	4394                	lw	a3,0(a5)
ffffffffc0202680:	2681                	sext.w	a3,a3
ffffffffc0202682:	1ce69f63          	bne	a3,a4,ffffffffc0202860 <_clock_check_swap+0x21c>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202686:	6709                	lui	a4,0x2
ffffffffc0202688:	462d                	li	a2,11
ffffffffc020268a:	00c70023          	sb	a2,0(a4) # 2000 <kern_entry-0xffffffffc01fe000>
    assert(pgfault_num==4);
ffffffffc020268e:	4398                	lw	a4,0(a5)
ffffffffc0202690:	2701                	sext.w	a4,a4
ffffffffc0202692:	1ad71763          	bne	a4,a3,ffffffffc0202840 <_clock_check_swap+0x1fc>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0202696:	6715                	lui	a4,0x5
ffffffffc0202698:	46b9                	li	a3,14
ffffffffc020269a:	00d70023          	sb	a3,0(a4) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc020269e:	4398                	lw	a4,0(a5)
ffffffffc02026a0:	4695                	li	a3,5
ffffffffc02026a2:	2701                	sext.w	a4,a4
ffffffffc02026a4:	16d71e63          	bne	a4,a3,ffffffffc0202820 <_clock_check_swap+0x1dc>
    assert(pgfault_num==5);
ffffffffc02026a8:	4394                	lw	a3,0(a5)
ffffffffc02026aa:	2681                	sext.w	a3,a3
ffffffffc02026ac:	14e69a63          	bne	a3,a4,ffffffffc0202800 <_clock_check_swap+0x1bc>
    assert(pgfault_num==5);
ffffffffc02026b0:	4398                	lw	a4,0(a5)
ffffffffc02026b2:	2701                	sext.w	a4,a4
ffffffffc02026b4:	12d71663          	bne	a4,a3,ffffffffc02027e0 <_clock_check_swap+0x19c>
    assert(pgfault_num==5);
ffffffffc02026b8:	4394                	lw	a3,0(a5)
ffffffffc02026ba:	2681                	sext.w	a3,a3
ffffffffc02026bc:	10e69263          	bne	a3,a4,ffffffffc02027c0 <_clock_check_swap+0x17c>
    assert(pgfault_num==5);
ffffffffc02026c0:	4398                	lw	a4,0(a5)
ffffffffc02026c2:	2701                	sext.w	a4,a4
ffffffffc02026c4:	0cd71e63          	bne	a4,a3,ffffffffc02027a0 <_clock_check_swap+0x15c>
    assert(pgfault_num==5);
ffffffffc02026c8:	4394                	lw	a3,0(a5)
ffffffffc02026ca:	2681                	sext.w	a3,a3
ffffffffc02026cc:	0ae69a63          	bne	a3,a4,ffffffffc0202780 <_clock_check_swap+0x13c>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc02026d0:	6715                	lui	a4,0x5
ffffffffc02026d2:	46b9                	li	a3,14
ffffffffc02026d4:	00d70023          	sb	a3,0(a4) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc02026d8:	4398                	lw	a4,0(a5)
ffffffffc02026da:	4695                	li	a3,5
ffffffffc02026dc:	2701                	sext.w	a4,a4
ffffffffc02026de:	08d71163          	bne	a4,a3,ffffffffc0202760 <_clock_check_swap+0x11c>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc02026e2:	6705                	lui	a4,0x1
ffffffffc02026e4:	00074683          	lbu	a3,0(a4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc02026e8:	4729                	li	a4,10
ffffffffc02026ea:	04e69b63          	bne	a3,a4,ffffffffc0202740 <_clock_check_swap+0xfc>
    assert(pgfault_num==6);
ffffffffc02026ee:	439c                	lw	a5,0(a5)
ffffffffc02026f0:	4719                	li	a4,6
ffffffffc02026f2:	2781                	sext.w	a5,a5
ffffffffc02026f4:	02e79663          	bne	a5,a4,ffffffffc0202720 <_clock_check_swap+0xdc>
}
ffffffffc02026f8:	60a2                	ld	ra,8(sp)
ffffffffc02026fa:	4501                	li	a0,0
ffffffffc02026fc:	0141                	addi	sp,sp,16
ffffffffc02026fe:	8082                	ret
    assert(pgfault_num==4);
ffffffffc0202700:	00003697          	auipc	a3,0x3
ffffffffc0202704:	ba068693          	addi	a3,a3,-1120 # ffffffffc02052a0 <commands+0xc80>
ffffffffc0202708:	00002617          	auipc	a2,0x2
ffffffffc020270c:	64060613          	addi	a2,a2,1600 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202710:	08200593          	li	a1,130
ffffffffc0202714:	00003517          	auipc	a0,0x3
ffffffffc0202718:	11c50513          	addi	a0,a0,284 # ffffffffc0205830 <default_pmm_manager+0x38>
ffffffffc020271c:	9e7fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==6);
ffffffffc0202720:	00003697          	auipc	a3,0x3
ffffffffc0202724:	16068693          	addi	a3,a3,352 # ffffffffc0205880 <default_pmm_manager+0x88>
ffffffffc0202728:	00002617          	auipc	a2,0x2
ffffffffc020272c:	62060613          	addi	a2,a2,1568 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202730:	09900593          	li	a1,153
ffffffffc0202734:	00003517          	auipc	a0,0x3
ffffffffc0202738:	0fc50513          	addi	a0,a0,252 # ffffffffc0205830 <default_pmm_manager+0x38>
ffffffffc020273c:	9c7fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0202740:	00003697          	auipc	a3,0x3
ffffffffc0202744:	11868693          	addi	a3,a3,280 # ffffffffc0205858 <default_pmm_manager+0x60>
ffffffffc0202748:	00002617          	auipc	a2,0x2
ffffffffc020274c:	60060613          	addi	a2,a2,1536 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202750:	09700593          	li	a1,151
ffffffffc0202754:	00003517          	auipc	a0,0x3
ffffffffc0202758:	0dc50513          	addi	a0,a0,220 # ffffffffc0205830 <default_pmm_manager+0x38>
ffffffffc020275c:	9a7fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==5);
ffffffffc0202760:	00003697          	auipc	a3,0x3
ffffffffc0202764:	0e868693          	addi	a3,a3,232 # ffffffffc0205848 <default_pmm_manager+0x50>
ffffffffc0202768:	00002617          	auipc	a2,0x2
ffffffffc020276c:	5e060613          	addi	a2,a2,1504 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202770:	09600593          	li	a1,150
ffffffffc0202774:	00003517          	auipc	a0,0x3
ffffffffc0202778:	0bc50513          	addi	a0,a0,188 # ffffffffc0205830 <default_pmm_manager+0x38>
ffffffffc020277c:	987fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==5);
ffffffffc0202780:	00003697          	auipc	a3,0x3
ffffffffc0202784:	0c868693          	addi	a3,a3,200 # ffffffffc0205848 <default_pmm_manager+0x50>
ffffffffc0202788:	00002617          	auipc	a2,0x2
ffffffffc020278c:	5c060613          	addi	a2,a2,1472 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202790:	09400593          	li	a1,148
ffffffffc0202794:	00003517          	auipc	a0,0x3
ffffffffc0202798:	09c50513          	addi	a0,a0,156 # ffffffffc0205830 <default_pmm_manager+0x38>
ffffffffc020279c:	967fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==5);
ffffffffc02027a0:	00003697          	auipc	a3,0x3
ffffffffc02027a4:	0a868693          	addi	a3,a3,168 # ffffffffc0205848 <default_pmm_manager+0x50>
ffffffffc02027a8:	00002617          	auipc	a2,0x2
ffffffffc02027ac:	5a060613          	addi	a2,a2,1440 # ffffffffc0204d48 <commands+0x728>
ffffffffc02027b0:	09200593          	li	a1,146
ffffffffc02027b4:	00003517          	auipc	a0,0x3
ffffffffc02027b8:	07c50513          	addi	a0,a0,124 # ffffffffc0205830 <default_pmm_manager+0x38>
ffffffffc02027bc:	947fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==5);
ffffffffc02027c0:	00003697          	auipc	a3,0x3
ffffffffc02027c4:	08868693          	addi	a3,a3,136 # ffffffffc0205848 <default_pmm_manager+0x50>
ffffffffc02027c8:	00002617          	auipc	a2,0x2
ffffffffc02027cc:	58060613          	addi	a2,a2,1408 # ffffffffc0204d48 <commands+0x728>
ffffffffc02027d0:	09000593          	li	a1,144
ffffffffc02027d4:	00003517          	auipc	a0,0x3
ffffffffc02027d8:	05c50513          	addi	a0,a0,92 # ffffffffc0205830 <default_pmm_manager+0x38>
ffffffffc02027dc:	927fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==5);
ffffffffc02027e0:	00003697          	auipc	a3,0x3
ffffffffc02027e4:	06868693          	addi	a3,a3,104 # ffffffffc0205848 <default_pmm_manager+0x50>
ffffffffc02027e8:	00002617          	auipc	a2,0x2
ffffffffc02027ec:	56060613          	addi	a2,a2,1376 # ffffffffc0204d48 <commands+0x728>
ffffffffc02027f0:	08e00593          	li	a1,142
ffffffffc02027f4:	00003517          	auipc	a0,0x3
ffffffffc02027f8:	03c50513          	addi	a0,a0,60 # ffffffffc0205830 <default_pmm_manager+0x38>
ffffffffc02027fc:	907fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==5);
ffffffffc0202800:	00003697          	auipc	a3,0x3
ffffffffc0202804:	04868693          	addi	a3,a3,72 # ffffffffc0205848 <default_pmm_manager+0x50>
ffffffffc0202808:	00002617          	auipc	a2,0x2
ffffffffc020280c:	54060613          	addi	a2,a2,1344 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202810:	08c00593          	li	a1,140
ffffffffc0202814:	00003517          	auipc	a0,0x3
ffffffffc0202818:	01c50513          	addi	a0,a0,28 # ffffffffc0205830 <default_pmm_manager+0x38>
ffffffffc020281c:	8e7fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==5);
ffffffffc0202820:	00003697          	auipc	a3,0x3
ffffffffc0202824:	02868693          	addi	a3,a3,40 # ffffffffc0205848 <default_pmm_manager+0x50>
ffffffffc0202828:	00002617          	auipc	a2,0x2
ffffffffc020282c:	52060613          	addi	a2,a2,1312 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202830:	08a00593          	li	a1,138
ffffffffc0202834:	00003517          	auipc	a0,0x3
ffffffffc0202838:	ffc50513          	addi	a0,a0,-4 # ffffffffc0205830 <default_pmm_manager+0x38>
ffffffffc020283c:	8c7fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==4);
ffffffffc0202840:	00003697          	auipc	a3,0x3
ffffffffc0202844:	a6068693          	addi	a3,a3,-1440 # ffffffffc02052a0 <commands+0xc80>
ffffffffc0202848:	00002617          	auipc	a2,0x2
ffffffffc020284c:	50060613          	addi	a2,a2,1280 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202850:	08800593          	li	a1,136
ffffffffc0202854:	00003517          	auipc	a0,0x3
ffffffffc0202858:	fdc50513          	addi	a0,a0,-36 # ffffffffc0205830 <default_pmm_manager+0x38>
ffffffffc020285c:	8a7fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==4);
ffffffffc0202860:	00003697          	auipc	a3,0x3
ffffffffc0202864:	a4068693          	addi	a3,a3,-1472 # ffffffffc02052a0 <commands+0xc80>
ffffffffc0202868:	00002617          	auipc	a2,0x2
ffffffffc020286c:	4e060613          	addi	a2,a2,1248 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202870:	08600593          	li	a1,134
ffffffffc0202874:	00003517          	auipc	a0,0x3
ffffffffc0202878:	fbc50513          	addi	a0,a0,-68 # ffffffffc0205830 <default_pmm_manager+0x38>
ffffffffc020287c:	887fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pgfault_num==4);
ffffffffc0202880:	00003697          	auipc	a3,0x3
ffffffffc0202884:	a2068693          	addi	a3,a3,-1504 # ffffffffc02052a0 <commands+0xc80>
ffffffffc0202888:	00002617          	auipc	a2,0x2
ffffffffc020288c:	4c060613          	addi	a2,a2,1216 # ffffffffc0204d48 <commands+0x728>
ffffffffc0202890:	08400593          	li	a1,132
ffffffffc0202894:	00003517          	auipc	a0,0x3
ffffffffc0202898:	f9c50513          	addi	a0,a0,-100 # ffffffffc0205830 <default_pmm_manager+0x38>
ffffffffc020289c:	867fd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc02028a0 <_clock_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc02028a0:	7514                	ld	a3,40(a0)
{
ffffffffc02028a2:	1141                	addi	sp,sp,-16
ffffffffc02028a4:	e406                	sd	ra,8(sp)
     assert(head != NULL);
ffffffffc02028a6:	c2d1                	beqz	a3,ffffffffc020292a <_clock_swap_out_victim+0x8a>
     assert(in_tick==0);
ffffffffc02028a8:	e22d                	bnez	a2,ffffffffc020290a <_clock_swap_out_victim+0x6a>
    return listelm->next;
ffffffffc02028aa:	0000f617          	auipc	a2,0xf
ffffffffc02028ae:	c8e60613          	addi	a2,a2,-882 # ffffffffc0211538 <curr_ptr>
ffffffffc02028b2:	621c                	ld	a5,0(a2)
ffffffffc02028b4:	852e                	mv	a0,a1
ffffffffc02028b6:	678c                	ld	a1,8(a5)
ffffffffc02028b8:	a039                	j	ffffffffc02028c6 <_clock_swap_out_victim+0x26>
        if(!page->visited) {
ffffffffc02028ba:	fe05b703          	ld	a4,-32(a1)
ffffffffc02028be:	cf11                	beqz	a4,ffffffffc02028da <_clock_swap_out_victim+0x3a>
            page->visited = 0;
ffffffffc02028c0:	fe05b023          	sd	zero,-32(a1)
    while (1) {
ffffffffc02028c4:	85be                	mv	a1,a5
ffffffffc02028c6:	659c                	ld	a5,8(a1)
        if(curr_ptr == head) {
ffffffffc02028c8:	feb699e3          	bne	a3,a1,ffffffffc02028ba <_clock_swap_out_victim+0x1a>
            if(curr_ptr == head) {
ffffffffc02028cc:	02d78863          	beq	a5,a3,ffffffffc02028fc <_clock_swap_out_victim+0x5c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02028d0:	85be                	mv	a1,a5
        if(!page->visited) {
ffffffffc02028d2:	fe05b703          	ld	a4,-32(a1)
ffffffffc02028d6:	679c                	ld	a5,8(a5)
ffffffffc02028d8:	f765                	bnez	a4,ffffffffc02028c0 <_clock_swap_out_victim+0x20>
ffffffffc02028da:	6198                	ld	a4,0(a1)
        struct Page* page = le2page(curr_ptr, pra_page_link);
ffffffffc02028dc:	fd058693          	addi	a3,a1,-48
ffffffffc02028e0:	e20c                	sd	a1,0(a2)
            *ptr_page = page;
ffffffffc02028e2:	e114                	sd	a3,0(a0)
    prev->next = next;
ffffffffc02028e4:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02028e6:	e398                	sd	a4,0(a5)
            cprintf("curr_ptr %p\n",curr_ptr);
ffffffffc02028e8:	00003517          	auipc	a0,0x3
ffffffffc02028ec:	fc850513          	addi	a0,a0,-56 # ffffffffc02058b0 <default_pmm_manager+0xb8>
ffffffffc02028f0:	fcafd0ef          	jal	ra,ffffffffc02000ba <cprintf>
}
ffffffffc02028f4:	60a2                	ld	ra,8(sp)
ffffffffc02028f6:	4501                	li	a0,0
ffffffffc02028f8:	0141                	addi	sp,sp,16
ffffffffc02028fa:	8082                	ret
ffffffffc02028fc:	60a2                	ld	ra,8(sp)
ffffffffc02028fe:	e214                	sd	a3,0(a2)
                *ptr_page = NULL;
ffffffffc0202900:	00053023          	sd	zero,0(a0)
}
ffffffffc0202904:	4501                	li	a0,0
ffffffffc0202906:	0141                	addi	sp,sp,16
ffffffffc0202908:	8082                	ret
     assert(in_tick==0);
ffffffffc020290a:	00003697          	auipc	a3,0x3
ffffffffc020290e:	f9668693          	addi	a3,a3,-106 # ffffffffc02058a0 <default_pmm_manager+0xa8>
ffffffffc0202912:	00002617          	auipc	a2,0x2
ffffffffc0202916:	43660613          	addi	a2,a2,1078 # ffffffffc0204d48 <commands+0x728>
ffffffffc020291a:	03b00593          	li	a1,59
ffffffffc020291e:	00003517          	auipc	a0,0x3
ffffffffc0202922:	f1250513          	addi	a0,a0,-238 # ffffffffc0205830 <default_pmm_manager+0x38>
ffffffffc0202926:	fdcfd0ef          	jal	ra,ffffffffc0200102 <__panic>
     assert(head != NULL);
ffffffffc020292a:	00003697          	auipc	a3,0x3
ffffffffc020292e:	f6668693          	addi	a3,a3,-154 # ffffffffc0205890 <default_pmm_manager+0x98>
ffffffffc0202932:	00002617          	auipc	a2,0x2
ffffffffc0202936:	41660613          	addi	a2,a2,1046 # ffffffffc0204d48 <commands+0x728>
ffffffffc020293a:	03a00593          	li	a1,58
ffffffffc020293e:	00003517          	auipc	a0,0x3
ffffffffc0202942:	ef250513          	addi	a0,a0,-270 # ffffffffc0205830 <default_pmm_manager+0x38>
ffffffffc0202946:	fbcfd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc020294a <_clock_map_swappable>:
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc020294a:	0000f697          	auipc	a3,0xf
ffffffffc020294e:	bee6b683          	ld	a3,-1042(a3) # ffffffffc0211538 <curr_ptr>
    list_entry_t *head=mm->sm_priv; // 获取链表头
ffffffffc0202952:	751c                	ld	a5,40(a0)
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc0202954:	ce81                	beqz	a3,ffffffffc020296c <_clock_map_swappable+0x22>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0202956:	6394                	ld	a3,0(a5)
ffffffffc0202958:	03060713          	addi	a4,a2,48
    prev->next = next->prev = elm;
ffffffffc020295c:	e398                	sd	a4,0(a5)
ffffffffc020295e:	e698                	sd	a4,8(a3)
    elm->next = next;
ffffffffc0202960:	fe1c                	sd	a5,56(a2)
    page->visited = 1;
ffffffffc0202962:	4785                	li	a5,1
    elm->prev = prev;
ffffffffc0202964:	fa14                	sd	a3,48(a2)
ffffffffc0202966:	ea1c                	sd	a5,16(a2)
}
ffffffffc0202968:	4501                	li	a0,0
ffffffffc020296a:	8082                	ret
{
ffffffffc020296c:	1141                	addi	sp,sp,-16
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc020296e:	00003697          	auipc	a3,0x3
ffffffffc0202972:	f5268693          	addi	a3,a3,-174 # ffffffffc02058c0 <default_pmm_manager+0xc8>
ffffffffc0202976:	00002617          	auipc	a2,0x2
ffffffffc020297a:	3d260613          	addi	a2,a2,978 # ffffffffc0204d48 <commands+0x728>
ffffffffc020297e:	02700593          	li	a1,39
ffffffffc0202982:	00003517          	auipc	a0,0x3
ffffffffc0202986:	eae50513          	addi	a0,a0,-338 # ffffffffc0205830 <default_pmm_manager+0x38>
{
ffffffffc020298a:	e406                	sd	ra,8(sp)
    assert(entry != NULL && curr_ptr != NULL);
ffffffffc020298c:	f76fd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0202990 <pa2page.part.0>:
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc0202990:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa"); // 如果无效，触发 panic
ffffffffc0202992:	00002617          	auipc	a2,0x2
ffffffffc0202996:	60660613          	addi	a2,a2,1542 # ffffffffc0204f98 <commands+0x978>
ffffffffc020299a:	07000593          	li	a1,112
ffffffffc020299e:	00002517          	auipc	a0,0x2
ffffffffc02029a2:	61a50513          	addi	a0,a0,1562 # ffffffffc0204fb8 <commands+0x998>
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc02029a6:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa"); // 如果无效，触发 panic
ffffffffc02029a8:	f5afd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc02029ac <pte2page.part.0>:
static inline struct Page *pte2page(pte_t pte) {
ffffffffc02029ac:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte"); // 无效时触发 panic
ffffffffc02029ae:	00003617          	auipc	a2,0x3
ffffffffc02029b2:	92a60613          	addi	a2,a2,-1750 # ffffffffc02052d8 <commands+0xcb8>
ffffffffc02029b6:	08200593          	li	a1,130
ffffffffc02029ba:	00002517          	auipc	a0,0x2
ffffffffc02029be:	5fe50513          	addi	a0,a0,1534 # ffffffffc0204fb8 <commands+0x998>
static inline struct Page *pte2page(pte_t pte) {
ffffffffc02029c2:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte"); // 无效时触发 panic
ffffffffc02029c4:	f3efd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc02029c8 <alloc_pages>:
static void init_memmap(struct Page *base, size_t n) {
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - 调用 pmm_manager->alloc_pages 分配连续的 n * PAGESIZE 大小的内存
struct Page *alloc_pages(size_t n) {
ffffffffc02029c8:	7139                	addi	sp,sp,-64
ffffffffc02029ca:	f426                	sd	s1,40(sp)
ffffffffc02029cc:	f04a                	sd	s2,32(sp)
ffffffffc02029ce:	ec4e                	sd	s3,24(sp)
ffffffffc02029d0:	e852                	sd	s4,16(sp)
ffffffffc02029d2:	e456                	sd	s5,8(sp)
ffffffffc02029d4:	e05a                	sd	s6,0(sp)
ffffffffc02029d6:	fc06                	sd	ra,56(sp)
ffffffffc02029d8:	f822                	sd	s0,48(sp)
ffffffffc02029da:	84aa                	mv	s1,a0
ffffffffc02029dc:	0000f917          	auipc	s2,0xf
ffffffffc02029e0:	b8490913          	addi	s2,s2,-1148 # ffffffffc0211560 <pmm_manager>
        { 
            page = pmm_manager->alloc_pages(n); // 调用内存管理器的分配函数
        }
        local_intr_restore(intr_flag); // 恢复中断状态

        if (page != NULL || n > 1 || swap_init_ok == 0) break; // 成功分配到内存或不需要交换则退出循环
ffffffffc02029e4:	4a05                	li	s4,1
ffffffffc02029e6:	0000fa97          	auipc	s5,0xf
ffffffffc02029ea:	b4aa8a93          	addi	s5,s5,-1206 # ffffffffc0211530 <swap_init_ok>

        extern struct mm_struct *check_mm_struct; // 引用当前内存管理结构体
        swap_out(check_mm_struct, n, 0); // 调用 swap_out 函数进行页面置换，尝试释放内存
ffffffffc02029ee:	0005099b          	sext.w	s3,a0
ffffffffc02029f2:	0000fb17          	auipc	s6,0xf
ffffffffc02029f6:	b1eb0b13          	addi	s6,s6,-1250 # ffffffffc0211510 <check_mm_struct>
ffffffffc02029fa:	a01d                	j	ffffffffc0202a20 <alloc_pages+0x58>
            page = pmm_manager->alloc_pages(n); // 调用内存管理器的分配函数
ffffffffc02029fc:	00093783          	ld	a5,0(s2)
ffffffffc0202a00:	6f9c                	ld	a5,24(a5)
ffffffffc0202a02:	9782                	jalr	a5
ffffffffc0202a04:	842a                	mv	s0,a0
        swap_out(check_mm_struct, n, 0); // 调用 swap_out 函数进行页面置换，尝试释放内存
ffffffffc0202a06:	4601                	li	a2,0
ffffffffc0202a08:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break; // 成功分配到内存或不需要交换则退出循环
ffffffffc0202a0a:	ec0d                	bnez	s0,ffffffffc0202a44 <alloc_pages+0x7c>
ffffffffc0202a0c:	029a6c63          	bltu	s4,s1,ffffffffc0202a44 <alloc_pages+0x7c>
ffffffffc0202a10:	000aa783          	lw	a5,0(s5)
ffffffffc0202a14:	2781                	sext.w	a5,a5
ffffffffc0202a16:	c79d                	beqz	a5,ffffffffc0202a44 <alloc_pages+0x7c>
        swap_out(check_mm_struct, n, 0); // 调用 swap_out 函数进行页面置换，尝试释放内存
ffffffffc0202a18:	000b3503          	ld	a0,0(s6)
ffffffffc0202a1c:	f9dfe0ef          	jal	ra,ffffffffc02019b8 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202a20:	100027f3          	csrr	a5,sstatus
ffffffffc0202a24:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n); // 调用内存管理器的分配函数
ffffffffc0202a26:	8526                	mv	a0,s1
ffffffffc0202a28:	dbf1                	beqz	a5,ffffffffc02029fc <alloc_pages+0x34>
        intr_disable();
ffffffffc0202a2a:	ac5fd0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc0202a2e:	00093783          	ld	a5,0(s2)
ffffffffc0202a32:	8526                	mv	a0,s1
ffffffffc0202a34:	6f9c                	ld	a5,24(a5)
ffffffffc0202a36:	9782                	jalr	a5
ffffffffc0202a38:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202a3a:	aaffd0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
        swap_out(check_mm_struct, n, 0); // 调用 swap_out 函数进行页面置换，尝试释放内存
ffffffffc0202a3e:	4601                	li	a2,0
ffffffffc0202a40:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break; // 成功分配到内存或不需要交换则退出循环
ffffffffc0202a42:	d469                	beqz	s0,ffffffffc0202a0c <alloc_pages+0x44>
    }
    return page; // 返回分配得到的 Page 指针
}
ffffffffc0202a44:	70e2                	ld	ra,56(sp)
ffffffffc0202a46:	8522                	mv	a0,s0
ffffffffc0202a48:	7442                	ld	s0,48(sp)
ffffffffc0202a4a:	74a2                	ld	s1,40(sp)
ffffffffc0202a4c:	7902                	ld	s2,32(sp)
ffffffffc0202a4e:	69e2                	ld	s3,24(sp)
ffffffffc0202a50:	6a42                	ld	s4,16(sp)
ffffffffc0202a52:	6aa2                	ld	s5,8(sp)
ffffffffc0202a54:	6b02                	ld	s6,0(sp)
ffffffffc0202a56:	6121                	addi	sp,sp,64
ffffffffc0202a58:	8082                	ret

ffffffffc0202a5a <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202a5a:	100027f3          	csrr	a5,sstatus
ffffffffc0202a5e:	8b89                	andi	a5,a5,2
ffffffffc0202a60:	e799                	bnez	a5,ffffffffc0202a6e <free_pages+0x14>
void free_pages(struct Page *base, size_t n) {
    bool intr_flag; // 保存中断状态

    local_intr_save(intr_flag); // 关闭中断并保存当前中断状态
    { 
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0202a62:	0000f797          	auipc	a5,0xf
ffffffffc0202a66:	afe7b783          	ld	a5,-1282(a5) # ffffffffc0211560 <pmm_manager>
ffffffffc0202a6a:	739c                	ld	a5,32(a5)
ffffffffc0202a6c:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0202a6e:	1101                	addi	sp,sp,-32
ffffffffc0202a70:	ec06                	sd	ra,24(sp)
ffffffffc0202a72:	e822                	sd	s0,16(sp)
ffffffffc0202a74:	e426                	sd	s1,8(sp)
ffffffffc0202a76:	842a                	mv	s0,a0
ffffffffc0202a78:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0202a7a:	a75fd0ef          	jal	ra,ffffffffc02004ee <intr_disable>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0202a7e:	0000f797          	auipc	a5,0xf
ffffffffc0202a82:	ae27b783          	ld	a5,-1310(a5) # ffffffffc0211560 <pmm_manager>
ffffffffc0202a86:	739c                	ld	a5,32(a5)
ffffffffc0202a88:	85a6                	mv	a1,s1
ffffffffc0202a8a:	8522                	mv	a0,s0
ffffffffc0202a8c:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag); // 恢复中断状态
}
ffffffffc0202a8e:	6442                	ld	s0,16(sp)
ffffffffc0202a90:	60e2                	ld	ra,24(sp)
ffffffffc0202a92:	64a2                	ld	s1,8(sp)
ffffffffc0202a94:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0202a96:	a53fd06f          	j	ffffffffc02004e8 <intr_enable>

ffffffffc0202a9a <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202a9a:	100027f3          	csrr	a5,sstatus
ffffffffc0202a9e:	8b89                	andi	a5,a5,2
ffffffffc0202aa0:	e799                	bnez	a5,ffffffffc0202aae <nr_free_pages+0x14>
// of current free memory
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0202aa2:	0000f797          	auipc	a5,0xf
ffffffffc0202aa6:	abe7b783          	ld	a5,-1346(a5) # ffffffffc0211560 <pmm_manager>
ffffffffc0202aaa:	779c                	ld	a5,40(a5)
ffffffffc0202aac:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0202aae:	1141                	addi	sp,sp,-16
ffffffffc0202ab0:	e406                	sd	ra,8(sp)
ffffffffc0202ab2:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0202ab4:	a3bfd0ef          	jal	ra,ffffffffc02004ee <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0202ab8:	0000f797          	auipc	a5,0xf
ffffffffc0202abc:	aa87b783          	ld	a5,-1368(a5) # ffffffffc0211560 <pmm_manager>
ffffffffc0202ac0:	779c                	ld	a5,40(a5)
ffffffffc0202ac2:	9782                	jalr	a5
ffffffffc0202ac4:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202ac6:	a23fd0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0202aca:	60a2                	ld	ra,8(sp)
ffffffffc0202acc:	8522                	mv	a0,s0
ffffffffc0202ace:	6402                	ld	s0,0(sp)
ffffffffc0202ad0:	0141                	addi	sp,sp,16
ffffffffc0202ad2:	8082                	ret

ffffffffc0202ad4 <get_pte>:
//  la:    需要映射的线性地址
//  create: 指示是否在缺少页表时创建一个新页表
// 返回值：返回页表项的内核虚拟地址
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    // 获取第一级页目录项（PDX1(la) 获取第一级页目录索引）
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0202ad4:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0202ad8:	1ff7f793          	andi	a5,a5,511
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0202adc:	715d                	addi	sp,sp,-80
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0202ade:	078e                	slli	a5,a5,0x3
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0202ae0:	fc26                	sd	s1,56(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0202ae2:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V)) { // 如果第一级页目录项无效
ffffffffc0202ae6:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0202ae8:	f84a                	sd	s2,48(sp)
ffffffffc0202aea:	f44e                	sd	s3,40(sp)
ffffffffc0202aec:	f052                	sd	s4,32(sp)
ffffffffc0202aee:	e486                	sd	ra,72(sp)
ffffffffc0202af0:	e0a2                	sd	s0,64(sp)
ffffffffc0202af2:	ec56                	sd	s5,24(sp)
ffffffffc0202af4:	e85a                	sd	s6,16(sp)
ffffffffc0202af6:	e45e                	sd	s7,8(sp)
    if (!(*pdep1 & PTE_V)) { // 如果第一级页目录项无效
ffffffffc0202af8:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0202afc:	892e                	mv	s2,a1
ffffffffc0202afe:	8a32                	mv	s4,a2
ffffffffc0202b00:	0000f997          	auipc	s3,0xf
ffffffffc0202b04:	a5098993          	addi	s3,s3,-1456 # ffffffffc0211550 <npage>
    if (!(*pdep1 & PTE_V)) { // 如果第一级页目录项无效
ffffffffc0202b08:	efb5                	bnez	a5,ffffffffc0202b84 <get_pte+0xb0>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) { // 若 create 为假或分配失败，返回 NULL
ffffffffc0202b0a:	14060c63          	beqz	a2,ffffffffc0202c62 <get_pte+0x18e>
ffffffffc0202b0e:	4505                	li	a0,1
ffffffffc0202b10:	eb9ff0ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0202b14:	842a                	mv	s0,a0
ffffffffc0202b16:	14050663          	beqz	a0,ffffffffc0202c62 <get_pte+0x18e>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0202b1a:	0000fb97          	auipc	s7,0xf
ffffffffc0202b1e:	a3eb8b93          	addi	s7,s7,-1474 # ffffffffc0211558 <pages>
ffffffffc0202b22:	000bb503          	ld	a0,0(s7)
ffffffffc0202b26:	00003b17          	auipc	s6,0x3
ffffffffc0202b2a:	652b3b03          	ld	s6,1618(s6) # ffffffffc0206178 <error_string+0x38>
ffffffffc0202b2e:	00080ab7          	lui	s5,0x80
ffffffffc0202b32:	40a40533          	sub	a0,s0,a0
ffffffffc0202b36:	850d                	srai	a0,a0,0x3
ffffffffc0202b38:	03650533          	mul	a0,a0,s6
            return NULL;
        }
        set_page_ref(page, 1); // 设置页面的引用计数为 1
        uintptr_t pa = page2pa(page); // 获取物理地址
        memset(KADDR(pa), 0, PGSIZE); // 将该页表清零
ffffffffc0202b3c:	0000f997          	auipc	s3,0xf
ffffffffc0202b40:	a1498993          	addi	s3,s3,-1516 # ffffffffc0211550 <npage>
    page->ref = val; 
ffffffffc0202b44:	4785                	li	a5,1
ffffffffc0202b46:	0009b703          	ld	a4,0(s3)
ffffffffc0202b4a:	c01c                	sw	a5,0(s0)
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0202b4c:	9556                	add	a0,a0,s5
ffffffffc0202b4e:	00c51793          	slli	a5,a0,0xc
ffffffffc0202b52:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc0202b54:	0532                	slli	a0,a0,0xc
ffffffffc0202b56:	14e7fd63          	bgeu	a5,a4,ffffffffc0202cb0 <get_pte+0x1dc>
ffffffffc0202b5a:	0000f797          	auipc	a5,0xf
ffffffffc0202b5e:	a0e7b783          	ld	a5,-1522(a5) # ffffffffc0211568 <va_pa_offset>
ffffffffc0202b62:	6605                	lui	a2,0x1
ffffffffc0202b64:	4581                	li	a1,0
ffffffffc0202b66:	953e                	add	a0,a0,a5
ffffffffc0202b68:	370010ef          	jal	ra,ffffffffc0203ed8 <memset>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0202b6c:	000bb683          	ld	a3,0(s7)
ffffffffc0202b70:	40d406b3          	sub	a3,s0,a3
ffffffffc0202b74:	868d                	srai	a3,a3,0x3
ffffffffc0202b76:	036686b3          	mul	a3,a3,s6
ffffffffc0202b7a:	96d6                	add	a3,a3,s5
    asm volatile("sfence.vma"); // 刷新 TLB 中的地址映射
}

// 从页帧号和权限位构造页表项 (PTE)
static inline pte_t pte_create(uintptr_t ppn, int type) {
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type; // 将页帧号和权限位组合成 PTE
ffffffffc0202b7c:	06aa                	slli	a3,a3,0xa
ffffffffc0202b7e:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V); // 创建页目录项，设置为用户和有效
ffffffffc0202b82:	e094                	sd	a3,0(s1)
    }
    // 获取第二级页目录项，使用 PDX0(la) 索引到正确位置
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202b84:	77fd                	lui	a5,0xfffff
ffffffffc0202b86:	068a                	slli	a3,a3,0x2
ffffffffc0202b88:	0009b703          	ld	a4,0(s3)
ffffffffc0202b8c:	8efd                	and	a3,a3,a5
ffffffffc0202b8e:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202b92:	0ce7fa63          	bgeu	a5,a4,ffffffffc0202c66 <get_pte+0x192>
ffffffffc0202b96:	0000fa97          	auipc	s5,0xf
ffffffffc0202b9a:	9d2a8a93          	addi	s5,s5,-1582 # ffffffffc0211568 <va_pa_offset>
ffffffffc0202b9e:	000ab403          	ld	s0,0(s5)
ffffffffc0202ba2:	01595793          	srli	a5,s2,0x15
ffffffffc0202ba6:	1ff7f793          	andi	a5,a5,511
ffffffffc0202baa:	96a2                	add	a3,a3,s0
ffffffffc0202bac:	00379413          	slli	s0,a5,0x3
ffffffffc0202bb0:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) { // 如果第二级页目录项无效
ffffffffc0202bb2:	6014                	ld	a3,0(s0)
ffffffffc0202bb4:	0016f793          	andi	a5,a3,1
ffffffffc0202bb8:	ebad                	bnez	a5,ffffffffc0202c2a <get_pte+0x156>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) { // 若 create 为假或分配失败，返回 NULL
ffffffffc0202bba:	0a0a0463          	beqz	s4,ffffffffc0202c62 <get_pte+0x18e>
ffffffffc0202bbe:	4505                	li	a0,1
ffffffffc0202bc0:	e09ff0ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0202bc4:	84aa                	mv	s1,a0
ffffffffc0202bc6:	cd51                	beqz	a0,ffffffffc0202c62 <get_pte+0x18e>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0202bc8:	0000fb97          	auipc	s7,0xf
ffffffffc0202bcc:	990b8b93          	addi	s7,s7,-1648 # ffffffffc0211558 <pages>
ffffffffc0202bd0:	000bb503          	ld	a0,0(s7)
ffffffffc0202bd4:	00003b17          	auipc	s6,0x3
ffffffffc0202bd8:	5a4b3b03          	ld	s6,1444(s6) # ffffffffc0206178 <error_string+0x38>
ffffffffc0202bdc:	00080a37          	lui	s4,0x80
ffffffffc0202be0:	40a48533          	sub	a0,s1,a0
ffffffffc0202be4:	850d                	srai	a0,a0,0x3
ffffffffc0202be6:	03650533          	mul	a0,a0,s6
    page->ref = val; 
ffffffffc0202bea:	4785                	li	a5,1
            return NULL;
        }
        set_page_ref(page, 1); // 设置页面的引用计数为 1
        uintptr_t pa = page2pa(page); // 获取物理地址
        memset(KADDR(pa), 0, PGSIZE); // 将该页表清零
ffffffffc0202bec:	0009b703          	ld	a4,0(s3)
ffffffffc0202bf0:	c09c                	sw	a5,0(s1)
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0202bf2:	9552                	add	a0,a0,s4
ffffffffc0202bf4:	00c51793          	slli	a5,a0,0xc
ffffffffc0202bf8:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc0202bfa:	0532                	slli	a0,a0,0xc
ffffffffc0202bfc:	08e7fd63          	bgeu	a5,a4,ffffffffc0202c96 <get_pte+0x1c2>
ffffffffc0202c00:	000ab783          	ld	a5,0(s5)
ffffffffc0202c04:	6605                	lui	a2,0x1
ffffffffc0202c06:	4581                	li	a1,0
ffffffffc0202c08:	953e                	add	a0,a0,a5
ffffffffc0202c0a:	2ce010ef          	jal	ra,ffffffffc0203ed8 <memset>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0202c0e:	000bb683          	ld	a3,0(s7)
ffffffffc0202c12:	40d486b3          	sub	a3,s1,a3
ffffffffc0202c16:	868d                	srai	a3,a3,0x3
ffffffffc0202c18:	036686b3          	mul	a3,a3,s6
ffffffffc0202c1c:	96d2                	add	a3,a3,s4
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type; // 将页帧号和权限位组合成 PTE
ffffffffc0202c1e:	06aa                	slli	a3,a3,0xa
ffffffffc0202c20:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V); // 创建页目录项，设置为用户和有效
ffffffffc0202c24:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)]; // 返回最终页表项指针的内核虚拟地址
ffffffffc0202c26:	0009b703          	ld	a4,0(s3)
ffffffffc0202c2a:	068a                	slli	a3,a3,0x2
ffffffffc0202c2c:	757d                	lui	a0,0xfffff
ffffffffc0202c2e:	8ee9                	and	a3,a3,a0
ffffffffc0202c30:	00c6d793          	srli	a5,a3,0xc
ffffffffc0202c34:	04e7f563          	bgeu	a5,a4,ffffffffc0202c7e <get_pte+0x1aa>
ffffffffc0202c38:	000ab503          	ld	a0,0(s5)
ffffffffc0202c3c:	00c95913          	srli	s2,s2,0xc
ffffffffc0202c40:	1ff97913          	andi	s2,s2,511
ffffffffc0202c44:	96aa                	add	a3,a3,a0
ffffffffc0202c46:	00391513          	slli	a0,s2,0x3
ffffffffc0202c4a:	9536                	add	a0,a0,a3
}
ffffffffc0202c4c:	60a6                	ld	ra,72(sp)
ffffffffc0202c4e:	6406                	ld	s0,64(sp)
ffffffffc0202c50:	74e2                	ld	s1,56(sp)
ffffffffc0202c52:	7942                	ld	s2,48(sp)
ffffffffc0202c54:	79a2                	ld	s3,40(sp)
ffffffffc0202c56:	7a02                	ld	s4,32(sp)
ffffffffc0202c58:	6ae2                	ld	s5,24(sp)
ffffffffc0202c5a:	6b42                	ld	s6,16(sp)
ffffffffc0202c5c:	6ba2                	ld	s7,8(sp)
ffffffffc0202c5e:	6161                	addi	sp,sp,80
ffffffffc0202c60:	8082                	ret
            return NULL;
ffffffffc0202c62:	4501                	li	a0,0
ffffffffc0202c64:	b7e5                	j	ffffffffc0202c4c <get_pte+0x178>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202c66:	00003617          	auipc	a2,0x3
ffffffffc0202c6a:	c9a60613          	addi	a2,a2,-870 # ffffffffc0205900 <default_pmm_manager+0x108>
ffffffffc0202c6e:	0f500593          	li	a1,245
ffffffffc0202c72:	00003517          	auipc	a0,0x3
ffffffffc0202c76:	cb650513          	addi	a0,a0,-842 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0202c7a:	c88fd0ef          	jal	ra,ffffffffc0200102 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)]; // 返回最终页表项指针的内核虚拟地址
ffffffffc0202c7e:	00003617          	auipc	a2,0x3
ffffffffc0202c82:	c8260613          	addi	a2,a2,-894 # ffffffffc0205900 <default_pmm_manager+0x108>
ffffffffc0202c86:	10000593          	li	a1,256
ffffffffc0202c8a:	00003517          	auipc	a0,0x3
ffffffffc0202c8e:	c9e50513          	addi	a0,a0,-866 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0202c92:	c70fd0ef          	jal	ra,ffffffffc0200102 <__panic>
        memset(KADDR(pa), 0, PGSIZE); // 将该页表清零
ffffffffc0202c96:	86aa                	mv	a3,a0
ffffffffc0202c98:	00003617          	auipc	a2,0x3
ffffffffc0202c9c:	c6860613          	addi	a2,a2,-920 # ffffffffc0205900 <default_pmm_manager+0x108>
ffffffffc0202ca0:	0fd00593          	li	a1,253
ffffffffc0202ca4:	00003517          	auipc	a0,0x3
ffffffffc0202ca8:	c8450513          	addi	a0,a0,-892 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0202cac:	c56fd0ef          	jal	ra,ffffffffc0200102 <__panic>
        memset(KADDR(pa), 0, PGSIZE); // 将该页表清零
ffffffffc0202cb0:	86aa                	mv	a3,a0
ffffffffc0202cb2:	00003617          	auipc	a2,0x3
ffffffffc0202cb6:	c4e60613          	addi	a2,a2,-946 # ffffffffc0205900 <default_pmm_manager+0x108>
ffffffffc0202cba:	0f100593          	li	a1,241
ffffffffc0202cbe:	00003517          	auipc	a0,0x3
ffffffffc0202cc2:	c6a50513          	addi	a0,a0,-918 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0202cc6:	c3cfd0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0202cca <get_page>:
// 若 pte 存在且有效，则返回对应 Page，否则返回 NULL
// 参数：
//  pgdir: 页目录指针
//  la:    线性地址
//  ptep_store: 若不为 NULL，存储指向页表项的指针
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0202cca:	1141                	addi	sp,sp,-16
ffffffffc0202ccc:	e022                	sd	s0,0(sp)
ffffffffc0202cce:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0); // 获取对应的页表项指针
ffffffffc0202cd0:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0202cd2:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0); // 获取对应的页表项指针
ffffffffc0202cd4:	e01ff0ef          	jal	ra,ffffffffc0202ad4 <get_pte>
    if (ptep_store != NULL) {
ffffffffc0202cd8:	c011                	beqz	s0,ffffffffc0202cdc <get_page+0x12>
        *ptep_store = ptep; // 将页表项指针存储到 ptep_store
ffffffffc0202cda:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) { // 如果页表项有效
ffffffffc0202cdc:	c511                	beqz	a0,ffffffffc0202ce8 <get_page+0x1e>
ffffffffc0202cde:	611c                	ld	a5,0(a0)
        return pte2page(*ptep); // 返回对应的 Page 结构体指针
    }
    return NULL; // 如果页表项无效，返回 NULL
ffffffffc0202ce0:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) { // 如果页表项有效
ffffffffc0202ce2:	0017f713          	andi	a4,a5,1
ffffffffc0202ce6:	e709                	bnez	a4,ffffffffc0202cf0 <get_page+0x26>
}
ffffffffc0202ce8:	60a2                	ld	ra,8(sp)
ffffffffc0202cea:	6402                	ld	s0,0(sp)
ffffffffc0202cec:	0141                	addi	sp,sp,16
ffffffffc0202cee:	8082                	ret
    return pa2page(PTE_ADDR(pte)); // 提取页表项的物理地址并转换为 Page 结构体指针
ffffffffc0202cf0:	078a                	slli	a5,a5,0x2
ffffffffc0202cf2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0202cf4:	0000f717          	auipc	a4,0xf
ffffffffc0202cf8:	85c73703          	ld	a4,-1956(a4) # ffffffffc0211550 <npage>
ffffffffc0202cfc:	02e7f263          	bgeu	a5,a4,ffffffffc0202d20 <get_page+0x56>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc0202d00:	fff80537          	lui	a0,0xfff80
ffffffffc0202d04:	97aa                	add	a5,a5,a0
ffffffffc0202d06:	60a2                	ld	ra,8(sp)
ffffffffc0202d08:	6402                	ld	s0,0(sp)
ffffffffc0202d0a:	00379513          	slli	a0,a5,0x3
ffffffffc0202d0e:	97aa                	add	a5,a5,a0
ffffffffc0202d10:	078e                	slli	a5,a5,0x3
ffffffffc0202d12:	0000f517          	auipc	a0,0xf
ffffffffc0202d16:	84653503          	ld	a0,-1978(a0) # ffffffffc0211558 <pages>
ffffffffc0202d1a:	953e                	add	a0,a0,a5
ffffffffc0202d1c:	0141                	addi	sp,sp,16
ffffffffc0202d1e:	8082                	ret
ffffffffc0202d20:	c71ff0ef          	jal	ra,ffffffffc0202990 <pa2page.part.0>

ffffffffc0202d24 <page_remove>:

// page_remove - 释放与线性地址 la 关联的 Page 结构体，并清除对应的页表项
// 参数：
//  pgdir: 页目录指针
//  la:    线性地址
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0202d24:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0); // 获取对应的页表项
ffffffffc0202d26:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0202d28:	ec06                	sd	ra,24(sp)
ffffffffc0202d2a:	e822                	sd	s0,16(sp)
    pte_t *ptep = get_pte(pgdir, la, 0); // 获取对应的页表项
ffffffffc0202d2c:	da9ff0ef          	jal	ra,ffffffffc0202ad4 <get_pte>
    if (ptep != NULL) {
ffffffffc0202d30:	c511                	beqz	a0,ffffffffc0202d3c <page_remove+0x18>
    if (*ptep & PTE_V) { // 检查页表项是否有效
ffffffffc0202d32:	611c                	ld	a5,0(a0)
ffffffffc0202d34:	842a                	mv	s0,a0
ffffffffc0202d36:	0017f713          	andi	a4,a5,1
ffffffffc0202d3a:	e709                	bnez	a4,ffffffffc0202d44 <page_remove+0x20>
        page_remove_pte(pgdir, la, ptep); // 调用 page_remove_pte 清除页表项并释放页面
    }
}
ffffffffc0202d3c:	60e2                	ld	ra,24(sp)
ffffffffc0202d3e:	6442                	ld	s0,16(sp)
ffffffffc0202d40:	6105                	addi	sp,sp,32
ffffffffc0202d42:	8082                	ret
    return pa2page(PTE_ADDR(pte)); // 提取页表项的物理地址并转换为 Page 结构体指针
ffffffffc0202d44:	078a                	slli	a5,a5,0x2
ffffffffc0202d46:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0202d48:	0000f717          	auipc	a4,0xf
ffffffffc0202d4c:	80873703          	ld	a4,-2040(a4) # ffffffffc0211550 <npage>
ffffffffc0202d50:	06e7f563          	bgeu	a5,a4,ffffffffc0202dba <page_remove+0x96>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc0202d54:	fff80737          	lui	a4,0xfff80
ffffffffc0202d58:	97ba                	add	a5,a5,a4
ffffffffc0202d5a:	00379513          	slli	a0,a5,0x3
ffffffffc0202d5e:	97aa                	add	a5,a5,a0
ffffffffc0202d60:	078e                	slli	a5,a5,0x3
ffffffffc0202d62:	0000e517          	auipc	a0,0xe
ffffffffc0202d66:	7f653503          	ld	a0,2038(a0) # ffffffffc0211558 <pages>
ffffffffc0202d6a:	953e                	add	a0,a0,a5
    page->ref -= 1; // 引用计数减 1
ffffffffc0202d6c:	411c                	lw	a5,0(a0)
ffffffffc0202d6e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202d72:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0) { // 如果引用计数为0，释放页面
ffffffffc0202d74:	cb09                	beqz	a4,ffffffffc0202d86 <page_remove+0x62>
        *ptep = 0; // 清除页表项
ffffffffc0202d76:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma"); // 刷新 TLB 中的地址映射
ffffffffc0202d7a:	12000073          	sfence.vma
}
ffffffffc0202d7e:	60e2                	ld	ra,24(sp)
ffffffffc0202d80:	6442                	ld	s0,16(sp)
ffffffffc0202d82:	6105                	addi	sp,sp,32
ffffffffc0202d84:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202d86:	100027f3          	csrr	a5,sstatus
ffffffffc0202d8a:	8b89                	andi	a5,a5,2
ffffffffc0202d8c:	eb89                	bnez	a5,ffffffffc0202d9e <page_remove+0x7a>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0202d8e:	0000e797          	auipc	a5,0xe
ffffffffc0202d92:	7d27b783          	ld	a5,2002(a5) # ffffffffc0211560 <pmm_manager>
ffffffffc0202d96:	739c                	ld	a5,32(a5)
ffffffffc0202d98:	4585                	li	a1,1
ffffffffc0202d9a:	9782                	jalr	a5
    if (flag) {
ffffffffc0202d9c:	bfe9                	j	ffffffffc0202d76 <page_remove+0x52>
        intr_disable();
ffffffffc0202d9e:	e42a                	sd	a0,8(sp)
ffffffffc0202da0:	f4efd0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc0202da4:	0000e797          	auipc	a5,0xe
ffffffffc0202da8:	7bc7b783          	ld	a5,1980(a5) # ffffffffc0211560 <pmm_manager>
ffffffffc0202dac:	739c                	ld	a5,32(a5)
ffffffffc0202dae:	6522                	ld	a0,8(sp)
ffffffffc0202db0:	4585                	li	a1,1
ffffffffc0202db2:	9782                	jalr	a5
        intr_enable();
ffffffffc0202db4:	f34fd0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0202db8:	bf7d                	j	ffffffffc0202d76 <page_remove+0x52>
ffffffffc0202dba:	bd7ff0ef          	jal	ra,ffffffffc0202990 <pa2page.part.0>

ffffffffc0202dbe <page_insert>:
//  page:  the Page which need to map
//  la:    the linear address need to map
//  perm:  the permission of this Page which is setted in related pte
// return value: always 0
// note: PT is changed, so the TLB need to be invalidate
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202dbe:	7179                	addi	sp,sp,-48
ffffffffc0202dc0:	87b2                	mv	a5,a2
ffffffffc0202dc2:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1); // 获取页表项，如果不存在则创建
ffffffffc0202dc4:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202dc6:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1); // 获取页表项，如果不存在则创建
ffffffffc0202dc8:	85be                	mv	a1,a5
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202dca:	ec26                	sd	s1,24(sp)
ffffffffc0202dcc:	f406                	sd	ra,40(sp)
ffffffffc0202dce:	e84a                	sd	s2,16(sp)
ffffffffc0202dd0:	e44e                	sd	s3,8(sp)
ffffffffc0202dd2:	e052                	sd	s4,0(sp)
ffffffffc0202dd4:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1); // 获取页表项，如果不存在则创建
ffffffffc0202dd6:	cffff0ef          	jal	ra,ffffffffc0202ad4 <get_pte>
    if (ptep == NULL) {
ffffffffc0202dda:	cd71                	beqz	a0,ffffffffc0202eb6 <page_insert+0xf8>
    page->ref += 1; // 引用计数加 1
ffffffffc0202ddc:	4014                	lw	a3,0(s0)
        return -E_NO_MEM; // 如果分配失败，返回内存错误
    }
    page_ref_inc(page); // 增加物理页面的引用计数

    if (*ptep & PTE_V) { // 如果页表项已经有效
ffffffffc0202dde:	611c                	ld	a5,0(a0)
ffffffffc0202de0:	89aa                	mv	s3,a0
ffffffffc0202de2:	0016871b          	addiw	a4,a3,1
ffffffffc0202de6:	c018                	sw	a4,0(s0)
ffffffffc0202de8:	0017f713          	andi	a4,a5,1
ffffffffc0202dec:	e331                	bnez	a4,ffffffffc0202e30 <page_insert+0x72>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0202dee:	0000e797          	auipc	a5,0xe
ffffffffc0202df2:	76a7b783          	ld	a5,1898(a5) # ffffffffc0211558 <pages>
ffffffffc0202df6:	40f407b3          	sub	a5,s0,a5
ffffffffc0202dfa:	878d                	srai	a5,a5,0x3
ffffffffc0202dfc:	00003417          	auipc	s0,0x3
ffffffffc0202e00:	37c43403          	ld	s0,892(s0) # ffffffffc0206178 <error_string+0x38>
ffffffffc0202e04:	028787b3          	mul	a5,a5,s0
ffffffffc0202e08:	00080437          	lui	s0,0x80
ffffffffc0202e0c:	97a2                	add	a5,a5,s0
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type; // 将页帧号和权限位组合成 PTE
ffffffffc0202e0e:	07aa                	slli	a5,a5,0xa
ffffffffc0202e10:	8cdd                	or	s1,s1,a5
ffffffffc0202e12:	0014e493          	ori	s1,s1,1
            page_ref_dec(page); // 引用计数减少（因为之前增加了一次）
        } else { // 如果映射的是另一个页面
            page_remove_pte(pgdir, la, ptep); // 删除旧的映射
        }
    }
    *ptep = pte_create(page2ppn(page), PTE_V | perm); // 设置新的页表项
ffffffffc0202e16:	0099b023          	sd	s1,0(s3)
    asm volatile("sfence.vma"); // 刷新 TLB 中的地址映射
ffffffffc0202e1a:	12000073          	sfence.vma
    tlb_invalidate(pgdir, la); // 使TLB无效，以确保CPU的缓存与新的页表项同步

    return 0; // 成功返回
ffffffffc0202e1e:	4501                	li	a0,0
}
ffffffffc0202e20:	70a2                	ld	ra,40(sp)
ffffffffc0202e22:	7402                	ld	s0,32(sp)
ffffffffc0202e24:	64e2                	ld	s1,24(sp)
ffffffffc0202e26:	6942                	ld	s2,16(sp)
ffffffffc0202e28:	69a2                	ld	s3,8(sp)
ffffffffc0202e2a:	6a02                	ld	s4,0(sp)
ffffffffc0202e2c:	6145                	addi	sp,sp,48
ffffffffc0202e2e:	8082                	ret
    return pa2page(PTE_ADDR(pte)); // 提取页表项的物理地址并转换为 Page 结构体指针
ffffffffc0202e30:	00279713          	slli	a4,a5,0x2
ffffffffc0202e34:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0202e36:	0000e797          	auipc	a5,0xe
ffffffffc0202e3a:	71a7b783          	ld	a5,1818(a5) # ffffffffc0211550 <npage>
ffffffffc0202e3e:	06f77e63          	bgeu	a4,a5,ffffffffc0202eba <page_insert+0xfc>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc0202e42:	fff807b7          	lui	a5,0xfff80
ffffffffc0202e46:	973e                	add	a4,a4,a5
ffffffffc0202e48:	0000ea17          	auipc	s4,0xe
ffffffffc0202e4c:	710a0a13          	addi	s4,s4,1808 # ffffffffc0211558 <pages>
ffffffffc0202e50:	000a3783          	ld	a5,0(s4)
ffffffffc0202e54:	00371913          	slli	s2,a4,0x3
ffffffffc0202e58:	993a                	add	s2,s2,a4
ffffffffc0202e5a:	090e                	slli	s2,s2,0x3
ffffffffc0202e5c:	993e                	add	s2,s2,a5
        if (p == page) { // 如果已经是正确的映射
ffffffffc0202e5e:	03240063          	beq	s0,s2,ffffffffc0202e7e <page_insert+0xc0>
    page->ref -= 1; // 引用计数减 1
ffffffffc0202e62:	00092783          	lw	a5,0(s2)
ffffffffc0202e66:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202e6a:	00e92023          	sw	a4,0(s2)
        if (page_ref(page) == 0) { // 如果引用计数为0，释放页面
ffffffffc0202e6e:	cb11                	beqz	a4,ffffffffc0202e82 <page_insert+0xc4>
        *ptep = 0; // 清除页表项
ffffffffc0202e70:	0009b023          	sd	zero,0(s3)
    asm volatile("sfence.vma"); // 刷新 TLB 中的地址映射
ffffffffc0202e74:	12000073          	sfence.vma
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0202e78:	000a3783          	ld	a5,0(s4)
}
ffffffffc0202e7c:	bfad                	j	ffffffffc0202df6 <page_insert+0x38>
    page->ref -= 1; // 引用计数减 1
ffffffffc0202e7e:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0202e80:	bf9d                	j	ffffffffc0202df6 <page_insert+0x38>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0202e82:	100027f3          	csrr	a5,sstatus
ffffffffc0202e86:	8b89                	andi	a5,a5,2
ffffffffc0202e88:	eb91                	bnez	a5,ffffffffc0202e9c <page_insert+0xde>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0202e8a:	0000e797          	auipc	a5,0xe
ffffffffc0202e8e:	6d67b783          	ld	a5,1750(a5) # ffffffffc0211560 <pmm_manager>
ffffffffc0202e92:	739c                	ld	a5,32(a5)
ffffffffc0202e94:	4585                	li	a1,1
ffffffffc0202e96:	854a                	mv	a0,s2
ffffffffc0202e98:	9782                	jalr	a5
    if (flag) {
ffffffffc0202e9a:	bfd9                	j	ffffffffc0202e70 <page_insert+0xb2>
        intr_disable();
ffffffffc0202e9c:	e52fd0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc0202ea0:	0000e797          	auipc	a5,0xe
ffffffffc0202ea4:	6c07b783          	ld	a5,1728(a5) # ffffffffc0211560 <pmm_manager>
ffffffffc0202ea8:	739c                	ld	a5,32(a5)
ffffffffc0202eaa:	4585                	li	a1,1
ffffffffc0202eac:	854a                	mv	a0,s2
ffffffffc0202eae:	9782                	jalr	a5
        intr_enable();
ffffffffc0202eb0:	e38fd0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0202eb4:	bf75                	j	ffffffffc0202e70 <page_insert+0xb2>
        return -E_NO_MEM; // 如果分配失败，返回内存错误
ffffffffc0202eb6:	5571                	li	a0,-4
ffffffffc0202eb8:	b7a5                	j	ffffffffc0202e20 <page_insert+0x62>
ffffffffc0202eba:	ad7ff0ef          	jal	ra,ffffffffc0202990 <pa2page.part.0>

ffffffffc0202ebe <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202ebe:	00003797          	auipc	a5,0x3
ffffffffc0202ec2:	93a78793          	addi	a5,a5,-1734 # ffffffffc02057f8 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202ec6:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0202ec8:	7159                	addi	sp,sp,-112
ffffffffc0202eca:	f45e                	sd	s7,40(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202ecc:	00003517          	auipc	a0,0x3
ffffffffc0202ed0:	a6c50513          	addi	a0,a0,-1428 # ffffffffc0205938 <default_pmm_manager+0x140>
    pmm_manager = &default_pmm_manager;
ffffffffc0202ed4:	0000eb97          	auipc	s7,0xe
ffffffffc0202ed8:	68cb8b93          	addi	s7,s7,1676 # ffffffffc0211560 <pmm_manager>
void pmm_init(void) {
ffffffffc0202edc:	f486                	sd	ra,104(sp)
ffffffffc0202ede:	f0a2                	sd	s0,96(sp)
ffffffffc0202ee0:	eca6                	sd	s1,88(sp)
ffffffffc0202ee2:	e8ca                	sd	s2,80(sp)
ffffffffc0202ee4:	e4ce                	sd	s3,72(sp)
ffffffffc0202ee6:	f85a                	sd	s6,48(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202ee8:	00fbb023          	sd	a5,0(s7)
void pmm_init(void) {
ffffffffc0202eec:	e0d2                	sd	s4,64(sp)
ffffffffc0202eee:	fc56                	sd	s5,56(sp)
ffffffffc0202ef0:	f062                	sd	s8,32(sp)
ffffffffc0202ef2:	ec66                	sd	s9,24(sp)
ffffffffc0202ef4:	e86a                	sd	s10,16(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202ef6:	9c4fd0ef          	jal	ra,ffffffffc02000ba <cprintf>
    pmm_manager->init();
ffffffffc0202efa:	000bb783          	ld	a5,0(s7)
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size); // 打印物理内存信息
ffffffffc0202efe:	4445                	li	s0,17
ffffffffc0202f00:	40100913          	li	s2,1025
    pmm_manager->init();
ffffffffc0202f04:	679c                	ld	a5,8(a5)
    va_pa_offset = KERNBASE - 0x80200000; // 设置内核虚拟地址与物理地址之间的偏移量
ffffffffc0202f06:	0000e997          	auipc	s3,0xe
ffffffffc0202f0a:	66298993          	addi	s3,s3,1634 # ffffffffc0211568 <va_pa_offset>
    npage = maxpa / PGSIZE; // 计算系统物理页总数
ffffffffc0202f0e:	0000e497          	auipc	s1,0xe
ffffffffc0202f12:	64248493          	addi	s1,s1,1602 # ffffffffc0211550 <npage>
    pmm_manager->init();
ffffffffc0202f16:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000; // 设置内核虚拟地址与物理地址之间的偏移量
ffffffffc0202f18:	57f5                	li	a5,-3
ffffffffc0202f1a:	07fa                	slli	a5,a5,0x1e
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size); // 打印物理内存信息
ffffffffc0202f1c:	07e006b7          	lui	a3,0x7e00
ffffffffc0202f20:	01b41613          	slli	a2,s0,0x1b
ffffffffc0202f24:	01591593          	slli	a1,s2,0x15
ffffffffc0202f28:	00003517          	auipc	a0,0x3
ffffffffc0202f2c:	a2850513          	addi	a0,a0,-1496 # ffffffffc0205950 <default_pmm_manager+0x158>
    va_pa_offset = KERNBASE - 0x80200000; // 设置内核虚拟地址与物理地址之间的偏移量
ffffffffc0202f30:	00f9b023          	sd	a5,0(s3)
    cprintf("membegin %llx memend %llx mem_size %llx\n", mem_begin, mem_end, mem_size); // 打印物理内存信息
ffffffffc0202f34:	986fd0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("physcial memory map:\n"); 
ffffffffc0202f38:	00003517          	auipc	a0,0x3
ffffffffc0202f3c:	a4850513          	addi	a0,a0,-1464 # ffffffffc0205980 <default_pmm_manager+0x188>
ffffffffc0202f40:	97afd0ef          	jal	ra,ffffffffc02000ba <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin, mem_end - 1); // 打印物理内存范围
ffffffffc0202f44:	01b41693          	slli	a3,s0,0x1b
ffffffffc0202f48:	16fd                	addi	a3,a3,-1
ffffffffc0202f4a:	07e005b7          	lui	a1,0x7e00
ffffffffc0202f4e:	01591613          	slli	a2,s2,0x15
ffffffffc0202f52:	00003517          	auipc	a0,0x3
ffffffffc0202f56:	a4650513          	addi	a0,a0,-1466 # ffffffffc0205998 <default_pmm_manager+0x1a0>
ffffffffc0202f5a:	960fd0ef          	jal	ra,ffffffffc02000ba <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE); // 将 pages 数组放置在内核结束地址之后的第一个页对齐位置
ffffffffc0202f5e:	777d                	lui	a4,0xfffff
ffffffffc0202f60:	0000f797          	auipc	a5,0xf
ffffffffc0202f64:	60f78793          	addi	a5,a5,1551 # ffffffffc021256f <end+0xfff>
ffffffffc0202f68:	8ff9                	and	a5,a5,a4
ffffffffc0202f6a:	0000eb17          	auipc	s6,0xe
ffffffffc0202f6e:	5eeb0b13          	addi	s6,s6,1518 # ffffffffc0211558 <pages>
    npage = maxpa / PGSIZE; // 计算系统物理页总数
ffffffffc0202f72:	00088737          	lui	a4,0x88
ffffffffc0202f76:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE); // 将 pages 数组放置在内核结束地址之后的第一个页对齐位置
ffffffffc0202f78:	00fb3023          	sd	a5,0(s6)
ffffffffc0202f7c:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0202f7e:	4701                	li	a4,0
ffffffffc0202f80:	4505                	li	a0,1
ffffffffc0202f82:	fff805b7          	lui	a1,0xfff80
ffffffffc0202f86:	a019                	j	ffffffffc0202f8c <pmm_init+0xce>
        SetPageReserved(pages + i); // 标记每页为保留状态，防止被分配
ffffffffc0202f88:	000b3783          	ld	a5,0(s6)
ffffffffc0202f8c:	97b6                	add	a5,a5,a3
ffffffffc0202f8e:	07a1                	addi	a5,a5,8
ffffffffc0202f90:	40a7b02f          	amoor.d	zero,a0,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0202f94:	609c                	ld	a5,0(s1)
ffffffffc0202f96:	0705                	addi	a4,a4,1
ffffffffc0202f98:	04868693          	addi	a3,a3,72 # 7e00048 <kern_entry-0xffffffffb83fffb8>
ffffffffc0202f9c:	00b78633          	add	a2,a5,a1
ffffffffc0202fa0:	fec764e3          	bltu	a4,a2,ffffffffc0202f88 <pmm_init+0xca>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 获取 pages 数组后面第一个空闲物理地址
ffffffffc0202fa4:	000b3503          	ld	a0,0(s6)
ffffffffc0202fa8:	00379693          	slli	a3,a5,0x3
ffffffffc0202fac:	96be                	add	a3,a3,a5
ffffffffc0202fae:	fdc00737          	lui	a4,0xfdc00
ffffffffc0202fb2:	972a                	add	a4,a4,a0
ffffffffc0202fb4:	068e                	slli	a3,a3,0x3
ffffffffc0202fb6:	96ba                	add	a3,a3,a4
ffffffffc0202fb8:	c0200737          	lui	a4,0xc0200
ffffffffc0202fbc:	0ee6e9e3          	bltu	a3,a4,ffffffffc02038ae <pmm_init+0x9f0>
ffffffffc0202fc0:	0009b703          	ld	a4,0(s3)
    if (freemem < mem_end) { // 如果存在空闲的物理内存区域，则初始化空闲内存页面
ffffffffc0202fc4:	4645                	li	a2,17
ffffffffc0202fc6:	066e                	slli	a2,a2,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 获取 pages 数组后面第一个空闲物理地址
ffffffffc0202fc8:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) { // 如果存在空闲的物理内存区域，则初始化空闲内存页面
ffffffffc0202fca:	4cc6e963          	bltu	a3,a2,ffffffffc020349c <pmm_init+0x5de>
    return page; // 返回分配并映射的页面指针
}

// check_alloc_page - 检查内存管理器的分配页面功能
static void check_alloc_page(void) {
    pmm_manager->check(); // 调用物理内存管理器的 check 函数进行自检
ffffffffc0202fce:	000bb783          	ld	a5,0(s7)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0202fd2:	0000e917          	auipc	s2,0xe
ffffffffc0202fd6:	57690913          	addi	s2,s2,1398 # ffffffffc0211548 <boot_pgdir>
    pmm_manager->check(); // 调用物理内存管理器的 check 函数进行自检
ffffffffc0202fda:	7b9c                	ld	a5,48(a5)
ffffffffc0202fdc:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n"); // 若自检通过，打印成功信息
ffffffffc0202fde:	00003517          	auipc	a0,0x3
ffffffffc0202fe2:	a0a50513          	addi	a0,a0,-1526 # ffffffffc02059e8 <default_pmm_manager+0x1f0>
ffffffffc0202fe6:	8d4fd0ef          	jal	ra,ffffffffc02000ba <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0202fea:	00006697          	auipc	a3,0x6
ffffffffc0202fee:	01668693          	addi	a3,a3,22 # ffffffffc0209000 <boot_page_table_sv39>
ffffffffc0202ff2:	00d93023          	sd	a3,0(s2)
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0202ff6:	c02007b7          	lui	a5,0xc0200
ffffffffc0202ffa:	24f6efe3          	bltu	a3,a5,ffffffffc0203a58 <pmm_init+0xb9a>
ffffffffc0202ffe:	0009b783          	ld	a5,0(s3)
ffffffffc0203002:	8e9d                	sub	a3,a3,a5
ffffffffc0203004:	0000e797          	auipc	a5,0xe
ffffffffc0203008:	52d7be23          	sd	a3,1340(a5) # ffffffffc0211540 <boot_cr3>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020300c:	100027f3          	csrr	a5,sstatus
ffffffffc0203010:	8b89                	andi	a5,a5,2
ffffffffc0203012:	4a079e63          	bnez	a5,ffffffffc02034ce <pmm_init+0x610>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0203016:	000bb783          	ld	a5,0(s7)
ffffffffc020301a:	779c                	ld	a5,40(a5)
ffffffffc020301c:	9782                	jalr	a5
ffffffffc020301e:	842a                	mv	s0,a0
static void check_pgdir(void) {
    size_t nr_free_store;
    nr_free_store = nr_free_pages(); // 记录当前的空闲页数

    // 检查内核页数和 boot_pgdir 的有效性
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0203020:	6098                	ld	a4,0(s1)
ffffffffc0203022:	c80007b7          	lui	a5,0xc8000
ffffffffc0203026:	83b1                	srli	a5,a5,0xc
ffffffffc0203028:	10e7ebe3          	bltu	a5,a4,ffffffffc020393e <pmm_init+0xa80>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc020302c:	00093503          	ld	a0,0(s2)
ffffffffc0203030:	0e0507e3          	beqz	a0,ffffffffc020391e <pmm_init+0xa60>
ffffffffc0203034:	03451793          	slli	a5,a0,0x34
ffffffffc0203038:	0e0793e3          	bnez	a5,ffffffffc020391e <pmm_init+0xa60>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL); // 确保虚拟地址 0x0 没有映射
ffffffffc020303c:	4601                	li	a2,0
ffffffffc020303e:	4581                	li	a1,0
ffffffffc0203040:	c8bff0ef          	jal	ra,ffffffffc0202cca <get_page>
ffffffffc0203044:	74051963          	bnez	a0,ffffffffc0203796 <pmm_init+0x8d8>

    // 分配物理页面 p1，并将其映射到 0x0 虚拟地址
    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc0203048:	4505                	li	a0,1
ffffffffc020304a:	97fff0ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc020304e:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0203050:	00093503          	ld	a0,0(s2)
ffffffffc0203054:	4681                	li	a3,0
ffffffffc0203056:	4601                	li	a2,0
ffffffffc0203058:	85d2                	mv	a1,s4
ffffffffc020305a:	d65ff0ef          	jal	ra,ffffffffc0202dbe <page_insert>
ffffffffc020305e:	70051c63          	bnez	a0,ffffffffc0203776 <pmm_init+0x8b8>
    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL); // 获取页表项并检查是否正确映射
ffffffffc0203062:	00093503          	ld	a0,0(s2)
ffffffffc0203066:	4601                	li	a2,0
ffffffffc0203068:	4581                	li	a1,0
ffffffffc020306a:	a6bff0ef          	jal	ra,ffffffffc0202ad4 <get_pte>
ffffffffc020306e:	6e050463          	beqz	a0,ffffffffc0203756 <pmm_init+0x898>
    assert(pte2page(*ptep) == p1);
ffffffffc0203072:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) { // 检查 PTE 是否有效
ffffffffc0203074:	0017f713          	andi	a4,a5,1
ffffffffc0203078:	6c070d63          	beqz	a4,ffffffffc0203752 <pmm_init+0x894>
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc020307c:	6090                	ld	a2,0(s1)
    return pa2page(PTE_ADDR(pte)); // 提取页表项的物理地址并转换为 Page 结构体指针
ffffffffc020307e:	078a                	slli	a5,a5,0x2
ffffffffc0203080:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0203082:	56c7f663          	bgeu	a5,a2,ffffffffc02035ee <pmm_init+0x730>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc0203086:	fff80737          	lui	a4,0xfff80
ffffffffc020308a:	97ba                	add	a5,a5,a4
ffffffffc020308c:	000b3683          	ld	a3,0(s6)
ffffffffc0203090:	00379713          	slli	a4,a5,0x3
ffffffffc0203094:	97ba                	add	a5,a5,a4
ffffffffc0203096:	078e                	slli	a5,a5,0x3
ffffffffc0203098:	97b6                	add	a5,a5,a3
ffffffffc020309a:	54fa1c63          	bne	s4,a5,ffffffffc02035f2 <pmm_init+0x734>
    assert(page_ref(p1) == 1);
ffffffffc020309e:	000a2703          	lw	a4,0(s4)
ffffffffc02030a2:	4785                	li	a5,1
ffffffffc02030a4:	7ef71563          	bne	a4,a5,ffffffffc020388e <pmm_init+0x9d0>

    // 获取页目录中的页表项，检查虚拟地址 PGSIZE 是否映射正确
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc02030a8:	00093503          	ld	a0,0(s2)
ffffffffc02030ac:	77fd                	lui	a5,0xfffff
ffffffffc02030ae:	6114                	ld	a3,0(a0)
ffffffffc02030b0:	068a                	slli	a3,a3,0x2
ffffffffc02030b2:	8efd                	and	a3,a3,a5
ffffffffc02030b4:	00c6d713          	srli	a4,a3,0xc
ffffffffc02030b8:	7ac77f63          	bgeu	a4,a2,ffffffffc0203876 <pmm_init+0x9b8>
ffffffffc02030bc:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02030c0:	96e2                	add	a3,a3,s8
ffffffffc02030c2:	0006ba83          	ld	s5,0(a3)
ffffffffc02030c6:	0a8a                	slli	s5,s5,0x2
ffffffffc02030c8:	00fafab3          	and	s5,s5,a5
ffffffffc02030cc:	00cad793          	srli	a5,s5,0xc
ffffffffc02030d0:	0ac7f7e3          	bgeu	a5,a2,ffffffffc020397e <pmm_init+0xac0>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02030d4:	4601                	li	a2,0
ffffffffc02030d6:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02030d8:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02030da:	9fbff0ef          	jal	ra,ffffffffc0202ad4 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc02030de:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02030e0:	07551fe3          	bne	a0,s5,ffffffffc020395e <pmm_init+0xaa0>

    // 分配第二个页面 p2，将其映射到虚拟地址 PGSIZE，赋予用户和写权限
    p2 = alloc_page();
ffffffffc02030e4:	4505                	li	a0,1
ffffffffc02030e6:	8e3ff0ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc02030ea:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02030ec:	00093503          	ld	a0,0(s2)
ffffffffc02030f0:	46d1                	li	a3,20
ffffffffc02030f2:	6605                	lui	a2,0x1
ffffffffc02030f4:	85d6                	mv	a1,s5
ffffffffc02030f6:	cc9ff0ef          	jal	ra,ffffffffc0202dbe <page_insert>
ffffffffc02030fa:	56051c63          	bnez	a0,ffffffffc0203672 <pmm_init+0x7b4>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02030fe:	00093503          	ld	a0,0(s2)
ffffffffc0203102:	4601                	li	a2,0
ffffffffc0203104:	6585                	lui	a1,0x1
ffffffffc0203106:	9cfff0ef          	jal	ra,ffffffffc0202ad4 <get_pte>
ffffffffc020310a:	54050463          	beqz	a0,ffffffffc0203652 <pmm_init+0x794>
    assert(*ptep & PTE_U);
ffffffffc020310e:	611c                	ld	a5,0(a0)
ffffffffc0203110:	0107f713          	andi	a4,a5,16
ffffffffc0203114:	50070f63          	beqz	a4,ffffffffc0203632 <pmm_init+0x774>
    assert(*ptep & PTE_W);
ffffffffc0203118:	8b91                	andi	a5,a5,4
ffffffffc020311a:	4e078c63          	beqz	a5,ffffffffc0203612 <pmm_init+0x754>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc020311e:	00093503          	ld	a0,0(s2)
ffffffffc0203122:	611c                	ld	a5,0(a0)
ffffffffc0203124:	8bc1                	andi	a5,a5,16
ffffffffc0203126:	100789e3          	beqz	a5,ffffffffc0203a38 <pmm_init+0xb7a>
    assert(page_ref(p2) == 1);
ffffffffc020312a:	000aa703          	lw	a4,0(s5)
ffffffffc020312e:	4785                	li	a5,1
ffffffffc0203130:	0ef714e3          	bne	a4,a5,ffffffffc0203a18 <pmm_init+0xb5a>

    // 重新将 p1 映射到 PGSIZE，检查引用计数变化
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0203134:	4681                	li	a3,0
ffffffffc0203136:	6605                	lui	a2,0x1
ffffffffc0203138:	85d2                	mv	a1,s4
ffffffffc020313a:	c85ff0ef          	jal	ra,ffffffffc0202dbe <page_insert>
ffffffffc020313e:	0a051de3          	bnez	a0,ffffffffc02039f8 <pmm_init+0xb3a>
    assert(page_ref(p1) == 2);
ffffffffc0203142:	000a2703          	lw	a4,0(s4)
ffffffffc0203146:	4789                	li	a5,2
ffffffffc0203148:	08f718e3          	bne	a4,a5,ffffffffc02039d8 <pmm_init+0xb1a>
    assert(page_ref(p2) == 0);
ffffffffc020314c:	000aa783          	lw	a5,0(s5)
ffffffffc0203150:	060794e3          	bnez	a5,ffffffffc02039b8 <pmm_init+0xafa>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0203154:	00093503          	ld	a0,0(s2)
ffffffffc0203158:	4601                	li	a2,0
ffffffffc020315a:	6585                	lui	a1,0x1
ffffffffc020315c:	979ff0ef          	jal	ra,ffffffffc0202ad4 <get_pte>
ffffffffc0203160:	02050ce3          	beqz	a0,ffffffffc0203998 <pmm_init+0xada>
    assert(pte2page(*ptep) == p1);
ffffffffc0203164:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) { // 检查 PTE 是否有效
ffffffffc0203166:	00177793          	andi	a5,a4,1
ffffffffc020316a:	5e078463          	beqz	a5,ffffffffc0203752 <pmm_init+0x894>
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc020316e:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte)); // 提取页表项的物理地址并转换为 Page 结构体指针
ffffffffc0203170:	00271793          	slli	a5,a4,0x2
ffffffffc0203174:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0203176:	46d7fc63          	bgeu	a5,a3,ffffffffc02035ee <pmm_init+0x730>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc020317a:	fff806b7          	lui	a3,0xfff80
ffffffffc020317e:	97b6                	add	a5,a5,a3
ffffffffc0203180:	000b3603          	ld	a2,0(s6)
ffffffffc0203184:	00379693          	slli	a3,a5,0x3
ffffffffc0203188:	97b6                	add	a5,a5,a3
ffffffffc020318a:	078e                	slli	a5,a5,0x3
ffffffffc020318c:	97b2                	add	a5,a5,a2
ffffffffc020318e:	5afa1263          	bne	s4,a5,ffffffffc0203732 <pmm_init+0x874>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203192:	8b41                	andi	a4,a4,16
ffffffffc0203194:	56071f63          	bnez	a4,ffffffffc0203712 <pmm_init+0x854>

    // 移除 0x0 和 PGSIZE 的映射，检查引用计数
    page_remove(boot_pgdir, 0x0);
ffffffffc0203198:	00093503          	ld	a0,0(s2)
ffffffffc020319c:	4581                	li	a1,0
ffffffffc020319e:	b87ff0ef          	jal	ra,ffffffffc0202d24 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc02031a2:	000a2703          	lw	a4,0(s4)
ffffffffc02031a6:	4785                	li	a5,1
ffffffffc02031a8:	54f71563          	bne	a4,a5,ffffffffc02036f2 <pmm_init+0x834>
    assert(page_ref(p2) == 0);
ffffffffc02031ac:	000aa783          	lw	a5,0(s5)
ffffffffc02031b0:	52079163          	bnez	a5,ffffffffc02036d2 <pmm_init+0x814>
    page_remove(boot_pgdir, PGSIZE);
ffffffffc02031b4:	00093503          	ld	a0,0(s2)
ffffffffc02031b8:	6585                	lui	a1,0x1
ffffffffc02031ba:	b6bff0ef          	jal	ra,ffffffffc0202d24 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc02031be:	000a2783          	lw	a5,0(s4)
ffffffffc02031c2:	60079a63          	bnez	a5,ffffffffc02037d6 <pmm_init+0x918>
    assert(page_ref(p2) == 0);
ffffffffc02031c6:	000aa783          	lw	a5,0(s5)
ffffffffc02031ca:	5e079663          	bnez	a5,ffffffffc02037b6 <pmm_init+0x8f8>

    // 确保所有页面的引用计数为0，并释放页目录页面
    pde_t *pd1 = boot_pgdir, *pd0 = page2kva(pde2page(boot_pgdir[0]));
ffffffffc02031ce:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc02031d2:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc02031d4:	000a3683          	ld	a3,0(s4)
ffffffffc02031d8:	068a                	slli	a3,a3,0x2
ffffffffc02031da:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc02031dc:	40e6f963          	bgeu	a3,a4,ffffffffc02035ee <pmm_init+0x730>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc02031e0:	fff807b7          	lui	a5,0xfff80
ffffffffc02031e4:	97b6                	add	a5,a5,a3
ffffffffc02031e6:	00379693          	slli	a3,a5,0x3
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc02031ea:	96be                	add	a3,a3,a5
ffffffffc02031ec:	00003c97          	auipc	s9,0x3
ffffffffc02031f0:	f8ccbc83          	ld	s9,-116(s9) # ffffffffc0206178 <error_string+0x38>
ffffffffc02031f4:	039686b3          	mul	a3,a3,s9
ffffffffc02031f8:	000805b7          	lui	a1,0x80
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc02031fc:	000b3503          	ld	a0,0(s6)
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0203200:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203202:	00c69613          	slli	a2,a3,0xc
ffffffffc0203206:	8231                	srli	a2,a2,0xc
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc0203208:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc020320a:	6ce67e63          	bgeu	a2,a4,ffffffffc02038e6 <pmm_init+0xa28>
    free_page(pde2page(pd0[0]));
ffffffffc020320e:	0009b603          	ld	a2,0(s3)
ffffffffc0203212:	96b2                	add	a3,a3,a2
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc0203214:	629c                	ld	a5,0(a3)
ffffffffc0203216:	078a                	slli	a5,a5,0x2
ffffffffc0203218:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc020321a:	3ce7fa63          	bgeu	a5,a4,ffffffffc02035ee <pmm_init+0x730>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc020321e:	8f8d                	sub	a5,a5,a1
ffffffffc0203220:	00379713          	slli	a4,a5,0x3
ffffffffc0203224:	97ba                	add	a5,a5,a4
ffffffffc0203226:	078e                	slli	a5,a5,0x3
ffffffffc0203228:	953e                	add	a0,a0,a5
ffffffffc020322a:	100027f3          	csrr	a5,sstatus
ffffffffc020322e:	8b89                	andi	a5,a5,2
ffffffffc0203230:	2e079963          	bnez	a5,ffffffffc0203522 <pmm_init+0x664>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0203234:	000bb783          	ld	a5,0(s7)
ffffffffc0203238:	4585                	li	a1,1
ffffffffc020323a:	739c                	ld	a5,32(a5)
ffffffffc020323c:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc020323e:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0203242:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc0203244:	078a                	slli	a5,a5,0x2
ffffffffc0203246:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0203248:	3ae7f363          	bgeu	a5,a4,ffffffffc02035ee <pmm_init+0x730>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc020324c:	fff80737          	lui	a4,0xfff80
ffffffffc0203250:	97ba                	add	a5,a5,a4
ffffffffc0203252:	000b3503          	ld	a0,0(s6)
ffffffffc0203256:	00379713          	slli	a4,a5,0x3
ffffffffc020325a:	97ba                	add	a5,a5,a4
ffffffffc020325c:	078e                	slli	a5,a5,0x3
ffffffffc020325e:	953e                	add	a0,a0,a5
ffffffffc0203260:	100027f3          	csrr	a5,sstatus
ffffffffc0203264:	8b89                	andi	a5,a5,2
ffffffffc0203266:	2a079263          	bnez	a5,ffffffffc020350a <pmm_init+0x64c>
ffffffffc020326a:	000bb783          	ld	a5,0(s7)
ffffffffc020326e:	4585                	li	a1,1
ffffffffc0203270:	739c                	ld	a5,32(a5)
ffffffffc0203272:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0203274:	00093783          	ld	a5,0(s2)
ffffffffc0203278:	0007b023          	sd	zero,0(a5) # fffffffffff80000 <end+0x3fd6ea90>
ffffffffc020327c:	100027f3          	csrr	a5,sstatus
ffffffffc0203280:	8b89                	andi	a5,a5,2
ffffffffc0203282:	26079a63          	bnez	a5,ffffffffc02034f6 <pmm_init+0x638>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0203286:	000bb783          	ld	a5,0(s7)
ffffffffc020328a:	779c                	ld	a5,40(a5)
ffffffffc020328c:	9782                	jalr	a5
ffffffffc020328e:	8a2a                	mv	s4,a0

    assert(nr_free_store == nr_free_pages()); // 验证空闲页数是否与之前一致
ffffffffc0203290:	7f441063          	bne	s0,s4,ffffffffc0203a70 <pmm_init+0xbb2>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0203294:	00003517          	auipc	a0,0x3
ffffffffc0203298:	a1c50513          	addi	a0,a0,-1508 # ffffffffc0205cb0 <default_pmm_manager+0x4b8>
ffffffffc020329c:	e1ffc0ef          	jal	ra,ffffffffc02000ba <cprintf>
ffffffffc02032a0:	100027f3          	csrr	a5,sstatus
ffffffffc02032a4:	8b89                	andi	a5,a5,2
ffffffffc02032a6:	22079e63          	bnez	a5,ffffffffc02034e2 <pmm_init+0x624>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc02032aa:	000bb783          	ld	a5,0(s7)
ffffffffc02032ae:	779c                	ld	a5,40(a5)
ffffffffc02032b0:	9782                	jalr	a5
ffffffffc02032b2:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;
    nr_free_store = nr_free_pages(); // 记录当前的空闲页数

    // 验证 boot_pgdir 中是否正确映射内核虚拟地址
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02032b4:	6098                	ld	a4,0(s1)
ffffffffc02032b6:	c0200437          	lui	s0,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02032ba:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02032bc:	00c71793          	slli	a5,a4,0xc
ffffffffc02032c0:	6a05                	lui	s4,0x1
ffffffffc02032c2:	02f47c63          	bgeu	s0,a5,ffffffffc02032fa <pmm_init+0x43c>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02032c6:	00c45793          	srli	a5,s0,0xc
ffffffffc02032ca:	00093503          	ld	a0,0(s2)
ffffffffc02032ce:	30e7f363          	bgeu	a5,a4,ffffffffc02035d4 <pmm_init+0x716>
ffffffffc02032d2:	0009b583          	ld	a1,0(s3)
ffffffffc02032d6:	4601                	li	a2,0
ffffffffc02032d8:	95a2                	add	a1,a1,s0
ffffffffc02032da:	ffaff0ef          	jal	ra,ffffffffc0202ad4 <get_pte>
ffffffffc02032de:	2c050b63          	beqz	a0,ffffffffc02035b4 <pmm_init+0x6f6>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02032e2:	611c                	ld	a5,0(a0)
ffffffffc02032e4:	078a                	slli	a5,a5,0x2
ffffffffc02032e6:	0157f7b3          	and	a5,a5,s5
ffffffffc02032ea:	2a879563          	bne	a5,s0,ffffffffc0203594 <pmm_init+0x6d6>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02032ee:	6098                	ld	a4,0(s1)
ffffffffc02032f0:	9452                	add	s0,s0,s4
ffffffffc02032f2:	00c71793          	slli	a5,a4,0xc
ffffffffc02032f6:	fcf468e3          	bltu	s0,a5,ffffffffc02032c6 <pmm_init+0x408>
    }

    assert(boot_pgdir[0] == 0);
ffffffffc02032fa:	00093783          	ld	a5,0(s2)
ffffffffc02032fe:	639c                	ld	a5,0(a5)
ffffffffc0203300:	5e079f63          	bnez	a5,ffffffffc02038fe <pmm_init+0xa40>

    // 分配页面 p，设置映射并检查内容复制和字符串操作的正确性
    struct Page *p;
    p = alloc_page();
ffffffffc0203304:	4505                	li	a0,1
ffffffffc0203306:	ec2ff0ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc020330a:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc020330c:	00093503          	ld	a0,0(s2)
ffffffffc0203310:	4699                	li	a3,6
ffffffffc0203312:	10000613          	li	a2,256
ffffffffc0203316:	85d6                	mv	a1,s5
ffffffffc0203318:	aa7ff0ef          	jal	ra,ffffffffc0202dbe <page_insert>
ffffffffc020331c:	38051b63          	bnez	a0,ffffffffc02036b2 <pmm_init+0x7f4>
    assert(page_ref(p) == 1);
ffffffffc0203320:	000aa703          	lw	a4,0(s5) # fffffffffffff000 <end+0x3fdeda90>
ffffffffc0203324:	4785                	li	a5,1
ffffffffc0203326:	36f71663          	bne	a4,a5,ffffffffc0203692 <pmm_init+0x7d4>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020332a:	00093503          	ld	a0,0(s2)
ffffffffc020332e:	6405                	lui	s0,0x1
ffffffffc0203330:	4699                	li	a3,6
ffffffffc0203332:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc0203336:	85d6                	mv	a1,s5
ffffffffc0203338:	a87ff0ef          	jal	ra,ffffffffc0202dbe <page_insert>
ffffffffc020333c:	50051d63          	bnez	a0,ffffffffc0203856 <pmm_init+0x998>
    assert(page_ref(p) == 2);
ffffffffc0203340:	000aa703          	lw	a4,0(s5)
ffffffffc0203344:	4789                	li	a5,2
ffffffffc0203346:	4ef71863          	bne	a4,a5,ffffffffc0203836 <pmm_init+0x978>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc020334a:	00003597          	auipc	a1,0x3
ffffffffc020334e:	a9e58593          	addi	a1,a1,-1378 # ffffffffc0205de8 <default_pmm_manager+0x5f0>
ffffffffc0203352:	10000513          	li	a0,256
ffffffffc0203356:	33d000ef          	jal	ra,ffffffffc0203e92 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020335a:	10040593          	addi	a1,s0,256
ffffffffc020335e:	10000513          	li	a0,256
ffffffffc0203362:	343000ef          	jal	ra,ffffffffc0203ea4 <strcmp>
ffffffffc0203366:	4a051863          	bnez	a0,ffffffffc0203816 <pmm_init+0x958>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc020336a:	000b3683          	ld	a3,0(s6)
ffffffffc020336e:	00080d37          	lui	s10,0x80
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203372:	547d                	li	s0,-1
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0203374:	40da86b3          	sub	a3,s5,a3
ffffffffc0203378:	868d                	srai	a3,a3,0x3
ffffffffc020337a:	039686b3          	mul	a3,a3,s9
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc020337e:	609c                	ld	a5,0(s1)
ffffffffc0203380:	8031                	srli	s0,s0,0xc
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0203382:	96ea                	add	a3,a3,s10
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203384:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc0203388:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc020338a:	54f77e63          	bgeu	a4,a5,ffffffffc02038e6 <pmm_init+0xa28>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020338e:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203392:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0203396:	96be                	add	a3,a3,a5
ffffffffc0203398:	10068023          	sb	zero,256(a3) # fffffffffff80100 <end+0x3fd6eb90>
    assert(strlen((const char *)0x100) == 0);
ffffffffc020339c:	2c1000ef          	jal	ra,ffffffffc0203e5c <strlen>
ffffffffc02033a0:	44051b63          	bnez	a0,ffffffffc02037f6 <pmm_init+0x938>

    // 释放分配的页面和页表
    pde_t *pd1 = boot_pgdir, *pd0 = page2kva(pde2page(boot_pgdir[0]));
ffffffffc02033a4:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc02033a8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc02033aa:	000a3783          	ld	a5,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc02033ae:	078a                	slli	a5,a5,0x2
ffffffffc02033b0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc02033b2:	22e7fe63          	bgeu	a5,a4,ffffffffc02035ee <pmm_init+0x730>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc02033b6:	41a787b3          	sub	a5,a5,s10
ffffffffc02033ba:	00379693          	slli	a3,a5,0x3
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc02033be:	96be                	add	a3,a3,a5
ffffffffc02033c0:	03968cb3          	mul	s9,a3,s9
ffffffffc02033c4:	01ac86b3          	add	a3,s9,s10
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc02033c8:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc02033ca:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc02033cc:	50e47d63          	bgeu	s0,a4,ffffffffc02038e6 <pmm_init+0xa28>
ffffffffc02033d0:	0009b403          	ld	s0,0(s3)
ffffffffc02033d4:	9436                	add	s0,s0,a3
ffffffffc02033d6:	100027f3          	csrr	a5,sstatus
ffffffffc02033da:	8b89                	andi	a5,a5,2
ffffffffc02033dc:	16079b63          	bnez	a5,ffffffffc0203552 <pmm_init+0x694>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc02033e0:	000bb783          	ld	a5,0(s7)
ffffffffc02033e4:	4585                	li	a1,1
ffffffffc02033e6:	8556                	mv	a0,s5
ffffffffc02033e8:	739c                	ld	a5,32(a5)
ffffffffc02033ea:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc02033ec:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc02033ee:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc02033f0:	078a                	slli	a5,a5,0x2
ffffffffc02033f2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc02033f4:	1ee7fd63          	bgeu	a5,a4,ffffffffc02035ee <pmm_init+0x730>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc02033f8:	fff80737          	lui	a4,0xfff80
ffffffffc02033fc:	97ba                	add	a5,a5,a4
ffffffffc02033fe:	000b3503          	ld	a0,0(s6)
ffffffffc0203402:	00379713          	slli	a4,a5,0x3
ffffffffc0203406:	97ba                	add	a5,a5,a4
ffffffffc0203408:	078e                	slli	a5,a5,0x3
ffffffffc020340a:	953e                	add	a0,a0,a5
ffffffffc020340c:	100027f3          	csrr	a5,sstatus
ffffffffc0203410:	8b89                	andi	a5,a5,2
ffffffffc0203412:	12079463          	bnez	a5,ffffffffc020353a <pmm_init+0x67c>
ffffffffc0203416:	000bb783          	ld	a5,0(s7)
ffffffffc020341a:	4585                	li	a1,1
ffffffffc020341c:	739c                	ld	a5,32(a5)
ffffffffc020341e:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc0203420:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0203424:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde)); // 提取页目录项的物理地址并转换为 Page 结构体指针
ffffffffc0203426:	078a                	slli	a5,a5,0x2
ffffffffc0203428:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc020342a:	1ce7f263          	bgeu	a5,a4,ffffffffc02035ee <pmm_init+0x730>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc020342e:	fff80737          	lui	a4,0xfff80
ffffffffc0203432:	97ba                	add	a5,a5,a4
ffffffffc0203434:	000b3503          	ld	a0,0(s6)
ffffffffc0203438:	00379713          	slli	a4,a5,0x3
ffffffffc020343c:	97ba                	add	a5,a5,a4
ffffffffc020343e:	078e                	slli	a5,a5,0x3
ffffffffc0203440:	953e                	add	a0,a0,a5
ffffffffc0203442:	100027f3          	csrr	a5,sstatus
ffffffffc0203446:	8b89                	andi	a5,a5,2
ffffffffc0203448:	12079a63          	bnez	a5,ffffffffc020357c <pmm_init+0x6be>
ffffffffc020344c:	000bb783          	ld	a5,0(s7)
ffffffffc0203450:	4585                	li	a1,1
ffffffffc0203452:	739c                	ld	a5,32(a5)
ffffffffc0203454:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0203456:	00093783          	ld	a5,0(s2)
ffffffffc020345a:	0007b023          	sd	zero,0(a5)
ffffffffc020345e:	100027f3          	csrr	a5,sstatus
ffffffffc0203462:	8b89                	andi	a5,a5,2
ffffffffc0203464:	10079263          	bnez	a5,ffffffffc0203568 <pmm_init+0x6aa>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc0203468:	000bb783          	ld	a5,0(s7)
ffffffffc020346c:	779c                	ld	a5,40(a5)
ffffffffc020346e:	9782                	jalr	a5
ffffffffc0203470:	842a                	mv	s0,a0

    assert(nr_free_store == nr_free_pages()); // 确保空闲页数一致
ffffffffc0203472:	448c1a63          	bne	s8,s0,ffffffffc02038c6 <pmm_init+0xa08>
}
ffffffffc0203476:	7406                	ld	s0,96(sp)
ffffffffc0203478:	70a6                	ld	ra,104(sp)
ffffffffc020347a:	64e6                	ld	s1,88(sp)
ffffffffc020347c:	6946                	ld	s2,80(sp)
ffffffffc020347e:	69a6                	ld	s3,72(sp)
ffffffffc0203480:	6a06                	ld	s4,64(sp)
ffffffffc0203482:	7ae2                	ld	s5,56(sp)
ffffffffc0203484:	7b42                	ld	s6,48(sp)
ffffffffc0203486:	7ba2                	ld	s7,40(sp)
ffffffffc0203488:	7c02                	ld	s8,32(sp)
ffffffffc020348a:	6ce2                	ld	s9,24(sp)
ffffffffc020348c:	6d42                	ld	s10,16(sp)

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc020348e:	00003517          	auipc	a0,0x3
ffffffffc0203492:	9d250513          	addi	a0,a0,-1582 # ffffffffc0205e60 <default_pmm_manager+0x668>
}
ffffffffc0203496:	6165                	addi	sp,sp,112
    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0203498:	c23fc06f          	j	ffffffffc02000ba <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE); // 对齐到页边界
ffffffffc020349c:	6705                	lui	a4,0x1
ffffffffc020349e:	177d                	addi	a4,a4,-1
ffffffffc02034a0:	96ba                	add	a3,a3,a4
ffffffffc02034a2:	777d                	lui	a4,0xfffff
ffffffffc02034a4:	8f75                	and	a4,a4,a3
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc02034a6:	00c75693          	srli	a3,a4,0xc
ffffffffc02034aa:	14f6f263          	bgeu	a3,a5,ffffffffc02035ee <pmm_init+0x730>
    pmm_manager->init_memmap(base, n);
ffffffffc02034ae:	000bb803          	ld	a6,0(s7)
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc02034b2:	95b6                	add	a1,a1,a3
ffffffffc02034b4:	00359793          	slli	a5,a1,0x3
ffffffffc02034b8:	97ae                	add	a5,a5,a1
ffffffffc02034ba:	01083683          	ld	a3,16(a6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE); // 初始化空闲页的内存映射
ffffffffc02034be:	40e60733          	sub	a4,a2,a4
ffffffffc02034c2:	078e                	slli	a5,a5,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02034c4:	00c75593          	srli	a1,a4,0xc
ffffffffc02034c8:	953e                	add	a0,a0,a5
ffffffffc02034ca:	9682                	jalr	a3
}
ffffffffc02034cc:	b609                	j	ffffffffc0202fce <pmm_init+0x110>
        intr_disable();
ffffffffc02034ce:	820fd0ef          	jal	ra,ffffffffc02004ee <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc02034d2:	000bb783          	ld	a5,0(s7)
ffffffffc02034d6:	779c                	ld	a5,40(a5)
ffffffffc02034d8:	9782                	jalr	a5
ffffffffc02034da:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02034dc:	80cfd0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc02034e0:	b681                	j	ffffffffc0203020 <pmm_init+0x162>
        intr_disable();
ffffffffc02034e2:	80cfd0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc02034e6:	000bb783          	ld	a5,0(s7)
ffffffffc02034ea:	779c                	ld	a5,40(a5)
ffffffffc02034ec:	9782                	jalr	a5
ffffffffc02034ee:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02034f0:	ff9fc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc02034f4:	b3c1                	j	ffffffffc02032b4 <pmm_init+0x3f6>
        intr_disable();
ffffffffc02034f6:	ff9fc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc02034fa:	000bb783          	ld	a5,0(s7)
ffffffffc02034fe:	779c                	ld	a5,40(a5)
ffffffffc0203500:	9782                	jalr	a5
ffffffffc0203502:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0203504:	fe5fc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0203508:	b361                	j	ffffffffc0203290 <pmm_init+0x3d2>
ffffffffc020350a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020350c:	fe3fc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0203510:	000bb783          	ld	a5,0(s7)
ffffffffc0203514:	6522                	ld	a0,8(sp)
ffffffffc0203516:	4585                	li	a1,1
ffffffffc0203518:	739c                	ld	a5,32(a5)
ffffffffc020351a:	9782                	jalr	a5
        intr_enable();
ffffffffc020351c:	fcdfc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0203520:	bb91                	j	ffffffffc0203274 <pmm_init+0x3b6>
ffffffffc0203522:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203524:	fcbfc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc0203528:	000bb783          	ld	a5,0(s7)
ffffffffc020352c:	6522                	ld	a0,8(sp)
ffffffffc020352e:	4585                	li	a1,1
ffffffffc0203530:	739c                	ld	a5,32(a5)
ffffffffc0203532:	9782                	jalr	a5
        intr_enable();
ffffffffc0203534:	fb5fc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0203538:	b319                	j	ffffffffc020323e <pmm_init+0x380>
ffffffffc020353a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020353c:	fb3fc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc0203540:	000bb783          	ld	a5,0(s7)
ffffffffc0203544:	6522                	ld	a0,8(sp)
ffffffffc0203546:	4585                	li	a1,1
ffffffffc0203548:	739c                	ld	a5,32(a5)
ffffffffc020354a:	9782                	jalr	a5
        intr_enable();
ffffffffc020354c:	f9dfc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0203550:	bdc1                	j	ffffffffc0203420 <pmm_init+0x562>
        intr_disable();
ffffffffc0203552:	f9dfc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc0203556:	000bb783          	ld	a5,0(s7)
ffffffffc020355a:	4585                	li	a1,1
ffffffffc020355c:	8556                	mv	a0,s5
ffffffffc020355e:	739c                	ld	a5,32(a5)
ffffffffc0203560:	9782                	jalr	a5
        intr_enable();
ffffffffc0203562:	f87fc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0203566:	b559                	j	ffffffffc02033ec <pmm_init+0x52e>
        intr_disable();
ffffffffc0203568:	f87fc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
    { ret = pmm_manager->nr_free_pages(); }
ffffffffc020356c:	000bb783          	ld	a5,0(s7)
ffffffffc0203570:	779c                	ld	a5,40(a5)
ffffffffc0203572:	9782                	jalr	a5
ffffffffc0203574:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203576:	f73fc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc020357a:	bde5                	j	ffffffffc0203472 <pmm_init+0x5b4>
ffffffffc020357c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020357e:	f71fc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0203582:	000bb783          	ld	a5,0(s7)
ffffffffc0203586:	6522                	ld	a0,8(sp)
ffffffffc0203588:	4585                	li	a1,1
ffffffffc020358a:	739c                	ld	a5,32(a5)
ffffffffc020358c:	9782                	jalr	a5
        intr_enable();
ffffffffc020358e:	f5bfc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0203592:	b5d1                	j	ffffffffc0203456 <pmm_init+0x598>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0203594:	00002697          	auipc	a3,0x2
ffffffffc0203598:	77c68693          	addi	a3,a3,1916 # ffffffffc0205d10 <default_pmm_manager+0x518>
ffffffffc020359c:	00001617          	auipc	a2,0x1
ffffffffc02035a0:	7ac60613          	addi	a2,a2,1964 # ffffffffc0204d48 <commands+0x728>
ffffffffc02035a4:	1b400593          	li	a1,436
ffffffffc02035a8:	00002517          	auipc	a0,0x2
ffffffffc02035ac:	38050513          	addi	a0,a0,896 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc02035b0:	b53fc0ef          	jal	ra,ffffffffc0200102 <__panic>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02035b4:	00002697          	auipc	a3,0x2
ffffffffc02035b8:	71c68693          	addi	a3,a3,1820 # ffffffffc0205cd0 <default_pmm_manager+0x4d8>
ffffffffc02035bc:	00001617          	auipc	a2,0x1
ffffffffc02035c0:	78c60613          	addi	a2,a2,1932 # ffffffffc0204d48 <commands+0x728>
ffffffffc02035c4:	1b300593          	li	a1,435
ffffffffc02035c8:	00002517          	auipc	a0,0x2
ffffffffc02035cc:	36050513          	addi	a0,a0,864 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc02035d0:	b33fc0ef          	jal	ra,ffffffffc0200102 <__panic>
ffffffffc02035d4:	86a2                	mv	a3,s0
ffffffffc02035d6:	00002617          	auipc	a2,0x2
ffffffffc02035da:	32a60613          	addi	a2,a2,810 # ffffffffc0205900 <default_pmm_manager+0x108>
ffffffffc02035de:	1b300593          	li	a1,435
ffffffffc02035e2:	00002517          	auipc	a0,0x2
ffffffffc02035e6:	34650513          	addi	a0,a0,838 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc02035ea:	b19fc0ef          	jal	ra,ffffffffc0200102 <__panic>
ffffffffc02035ee:	ba2ff0ef          	jal	ra,ffffffffc0202990 <pa2page.part.0>
    assert(pte2page(*ptep) == p1);
ffffffffc02035f2:	00002697          	auipc	a3,0x2
ffffffffc02035f6:	4f668693          	addi	a3,a3,1270 # ffffffffc0205ae8 <default_pmm_manager+0x2f0>
ffffffffc02035fa:	00001617          	auipc	a2,0x1
ffffffffc02035fe:	74e60613          	addi	a2,a2,1870 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203602:	17e00593          	li	a1,382
ffffffffc0203606:	00002517          	auipc	a0,0x2
ffffffffc020360a:	32250513          	addi	a0,a0,802 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc020360e:	af5fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203612:	00002697          	auipc	a3,0x2
ffffffffc0203616:	5a668693          	addi	a3,a3,1446 # ffffffffc0205bb8 <default_pmm_manager+0x3c0>
ffffffffc020361a:	00001617          	auipc	a2,0x1
ffffffffc020361e:	72e60613          	addi	a2,a2,1838 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203622:	18b00593          	li	a1,395
ffffffffc0203626:	00002517          	auipc	a0,0x2
ffffffffc020362a:	30250513          	addi	a0,a0,770 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc020362e:	ad5fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203632:	00002697          	auipc	a3,0x2
ffffffffc0203636:	57668693          	addi	a3,a3,1398 # ffffffffc0205ba8 <default_pmm_manager+0x3b0>
ffffffffc020363a:	00001617          	auipc	a2,0x1
ffffffffc020363e:	70e60613          	addi	a2,a2,1806 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203642:	18a00593          	li	a1,394
ffffffffc0203646:	00002517          	auipc	a0,0x2
ffffffffc020364a:	2e250513          	addi	a0,a0,738 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc020364e:	ab5fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0203652:	00002697          	auipc	a3,0x2
ffffffffc0203656:	52668693          	addi	a3,a3,1318 # ffffffffc0205b78 <default_pmm_manager+0x380>
ffffffffc020365a:	00001617          	auipc	a2,0x1
ffffffffc020365e:	6ee60613          	addi	a2,a2,1774 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203662:	18900593          	li	a1,393
ffffffffc0203666:	00002517          	auipc	a0,0x2
ffffffffc020366a:	2c250513          	addi	a0,a0,706 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc020366e:	a95fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203672:	00002697          	auipc	a3,0x2
ffffffffc0203676:	4ce68693          	addi	a3,a3,1230 # ffffffffc0205b40 <default_pmm_manager+0x348>
ffffffffc020367a:	00001617          	auipc	a2,0x1
ffffffffc020367e:	6ce60613          	addi	a2,a2,1742 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203682:	18800593          	li	a1,392
ffffffffc0203686:	00002517          	auipc	a0,0x2
ffffffffc020368a:	2a250513          	addi	a0,a0,674 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc020368e:	a75fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0203692:	00002697          	auipc	a3,0x2
ffffffffc0203696:	6e668693          	addi	a3,a3,1766 # ffffffffc0205d78 <default_pmm_manager+0x580>
ffffffffc020369a:	00001617          	auipc	a2,0x1
ffffffffc020369e:	6ae60613          	addi	a2,a2,1710 # ffffffffc0204d48 <commands+0x728>
ffffffffc02036a2:	1bd00593          	li	a1,445
ffffffffc02036a6:	00002517          	auipc	a0,0x2
ffffffffc02036aa:	28250513          	addi	a0,a0,642 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc02036ae:	a55fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02036b2:	00002697          	auipc	a3,0x2
ffffffffc02036b6:	68e68693          	addi	a3,a3,1678 # ffffffffc0205d40 <default_pmm_manager+0x548>
ffffffffc02036ba:	00001617          	auipc	a2,0x1
ffffffffc02036be:	68e60613          	addi	a2,a2,1678 # ffffffffc0204d48 <commands+0x728>
ffffffffc02036c2:	1bc00593          	li	a1,444
ffffffffc02036c6:	00002517          	auipc	a0,0x2
ffffffffc02036ca:	26250513          	addi	a0,a0,610 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc02036ce:	a35fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02036d2:	00002697          	auipc	a3,0x2
ffffffffc02036d6:	56e68693          	addi	a3,a3,1390 # ffffffffc0205c40 <default_pmm_manager+0x448>
ffffffffc02036da:	00001617          	auipc	a2,0x1
ffffffffc02036de:	66e60613          	addi	a2,a2,1646 # ffffffffc0204d48 <commands+0x728>
ffffffffc02036e2:	19a00593          	li	a1,410
ffffffffc02036e6:	00002517          	auipc	a0,0x2
ffffffffc02036ea:	24250513          	addi	a0,a0,578 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc02036ee:	a15fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02036f2:	00002697          	auipc	a3,0x2
ffffffffc02036f6:	40e68693          	addi	a3,a3,1038 # ffffffffc0205b00 <default_pmm_manager+0x308>
ffffffffc02036fa:	00001617          	auipc	a2,0x1
ffffffffc02036fe:	64e60613          	addi	a2,a2,1614 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203702:	19900593          	li	a1,409
ffffffffc0203706:	00002517          	auipc	a0,0x2
ffffffffc020370a:	22250513          	addi	a0,a0,546 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc020370e:	9f5fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203712:	00002697          	auipc	a3,0x2
ffffffffc0203716:	54668693          	addi	a3,a3,1350 # ffffffffc0205c58 <default_pmm_manager+0x460>
ffffffffc020371a:	00001617          	auipc	a2,0x1
ffffffffc020371e:	62e60613          	addi	a2,a2,1582 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203722:	19500593          	li	a1,405
ffffffffc0203726:	00002517          	auipc	a0,0x2
ffffffffc020372a:	20250513          	addi	a0,a0,514 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc020372e:	9d5fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203732:	00002697          	auipc	a3,0x2
ffffffffc0203736:	3b668693          	addi	a3,a3,950 # ffffffffc0205ae8 <default_pmm_manager+0x2f0>
ffffffffc020373a:	00001617          	auipc	a2,0x1
ffffffffc020373e:	60e60613          	addi	a2,a2,1550 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203742:	19400593          	li	a1,404
ffffffffc0203746:	00002517          	auipc	a0,0x2
ffffffffc020374a:	1e250513          	addi	a0,a0,482 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc020374e:	9b5fc0ef          	jal	ra,ffffffffc0200102 <__panic>
ffffffffc0203752:	a5aff0ef          	jal	ra,ffffffffc02029ac <pte2page.part.0>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL); // 获取页表项并检查是否正确映射
ffffffffc0203756:	00002697          	auipc	a3,0x2
ffffffffc020375a:	36268693          	addi	a3,a3,866 # ffffffffc0205ab8 <default_pmm_manager+0x2c0>
ffffffffc020375e:	00001617          	auipc	a2,0x1
ffffffffc0203762:	5ea60613          	addi	a2,a2,1514 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203766:	17d00593          	li	a1,381
ffffffffc020376a:	00002517          	auipc	a0,0x2
ffffffffc020376e:	1be50513          	addi	a0,a0,446 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0203772:	991fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0203776:	00002697          	auipc	a3,0x2
ffffffffc020377a:	31268693          	addi	a3,a3,786 # ffffffffc0205a88 <default_pmm_manager+0x290>
ffffffffc020377e:	00001617          	auipc	a2,0x1
ffffffffc0203782:	5ca60613          	addi	a2,a2,1482 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203786:	17b00593          	li	a1,379
ffffffffc020378a:	00002517          	auipc	a0,0x2
ffffffffc020378e:	19e50513          	addi	a0,a0,414 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0203792:	971fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL); // 确保虚拟地址 0x0 没有映射
ffffffffc0203796:	00002697          	auipc	a3,0x2
ffffffffc020379a:	2ca68693          	addi	a3,a3,714 # ffffffffc0205a60 <default_pmm_manager+0x268>
ffffffffc020379e:	00001617          	auipc	a2,0x1
ffffffffc02037a2:	5aa60613          	addi	a2,a2,1450 # ffffffffc0204d48 <commands+0x728>
ffffffffc02037a6:	17600593          	li	a1,374
ffffffffc02037aa:	00002517          	auipc	a0,0x2
ffffffffc02037ae:	17e50513          	addi	a0,a0,382 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc02037b2:	951fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02037b6:	00002697          	auipc	a3,0x2
ffffffffc02037ba:	48a68693          	addi	a3,a3,1162 # ffffffffc0205c40 <default_pmm_manager+0x448>
ffffffffc02037be:	00001617          	auipc	a2,0x1
ffffffffc02037c2:	58a60613          	addi	a2,a2,1418 # ffffffffc0204d48 <commands+0x728>
ffffffffc02037c6:	19d00593          	li	a1,413
ffffffffc02037ca:	00002517          	auipc	a0,0x2
ffffffffc02037ce:	15e50513          	addi	a0,a0,350 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc02037d2:	931fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02037d6:	00002697          	auipc	a3,0x2
ffffffffc02037da:	49a68693          	addi	a3,a3,1178 # ffffffffc0205c70 <default_pmm_manager+0x478>
ffffffffc02037de:	00001617          	auipc	a2,0x1
ffffffffc02037e2:	56a60613          	addi	a2,a2,1386 # ffffffffc0204d48 <commands+0x728>
ffffffffc02037e6:	19c00593          	li	a1,412
ffffffffc02037ea:	00002517          	auipc	a0,0x2
ffffffffc02037ee:	13e50513          	addi	a0,a0,318 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc02037f2:	911fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02037f6:	00002697          	auipc	a3,0x2
ffffffffc02037fa:	64268693          	addi	a3,a3,1602 # ffffffffc0205e38 <default_pmm_manager+0x640>
ffffffffc02037fe:	00001617          	auipc	a2,0x1
ffffffffc0203802:	54a60613          	addi	a2,a2,1354 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203806:	1c600593          	li	a1,454
ffffffffc020380a:	00002517          	auipc	a0,0x2
ffffffffc020380e:	11e50513          	addi	a0,a0,286 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0203812:	8f1fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0203816:	00002697          	auipc	a3,0x2
ffffffffc020381a:	5ea68693          	addi	a3,a3,1514 # ffffffffc0205e00 <default_pmm_manager+0x608>
ffffffffc020381e:	00001617          	auipc	a2,0x1
ffffffffc0203822:	52a60613          	addi	a2,a2,1322 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203826:	1c300593          	li	a1,451
ffffffffc020382a:	00002517          	auipc	a0,0x2
ffffffffc020382e:	0fe50513          	addi	a0,a0,254 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0203832:	8d1fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0203836:	00002697          	auipc	a3,0x2
ffffffffc020383a:	59a68693          	addi	a3,a3,1434 # ffffffffc0205dd0 <default_pmm_manager+0x5d8>
ffffffffc020383e:	00001617          	auipc	a2,0x1
ffffffffc0203842:	50a60613          	addi	a2,a2,1290 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203846:	1bf00593          	li	a1,447
ffffffffc020384a:	00002517          	auipc	a0,0x2
ffffffffc020384e:	0de50513          	addi	a0,a0,222 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0203852:	8b1fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0203856:	00002697          	auipc	a3,0x2
ffffffffc020385a:	53a68693          	addi	a3,a3,1338 # ffffffffc0205d90 <default_pmm_manager+0x598>
ffffffffc020385e:	00001617          	auipc	a2,0x1
ffffffffc0203862:	4ea60613          	addi	a2,a2,1258 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203866:	1be00593          	li	a1,446
ffffffffc020386a:	00002517          	auipc	a0,0x2
ffffffffc020386e:	0be50513          	addi	a0,a0,190 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0203872:	891fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0203876:	00002617          	auipc	a2,0x2
ffffffffc020387a:	08a60613          	addi	a2,a2,138 # ffffffffc0205900 <default_pmm_manager+0x108>
ffffffffc020387e:	18200593          	li	a1,386
ffffffffc0203882:	00002517          	auipc	a0,0x2
ffffffffc0203886:	0a650513          	addi	a0,a0,166 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc020388a:	879fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc020388e:	00002697          	auipc	a3,0x2
ffffffffc0203892:	27268693          	addi	a3,a3,626 # ffffffffc0205b00 <default_pmm_manager+0x308>
ffffffffc0203896:	00001617          	auipc	a2,0x1
ffffffffc020389a:	4b260613          	addi	a2,a2,1202 # ffffffffc0204d48 <commands+0x728>
ffffffffc020389e:	17f00593          	li	a1,383
ffffffffc02038a2:	00002517          	auipc	a0,0x2
ffffffffc02038a6:	08650513          	addi	a0,a0,134 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc02038aa:	859fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase)); // 获取 pages 数组后面第一个空闲物理地址
ffffffffc02038ae:	00002617          	auipc	a2,0x2
ffffffffc02038b2:	11260613          	addi	a2,a2,274 # ffffffffc02059c0 <default_pmm_manager+0x1c8>
ffffffffc02038b6:	07d00593          	li	a1,125
ffffffffc02038ba:	00002517          	auipc	a0,0x2
ffffffffc02038be:	06e50513          	addi	a0,a0,110 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc02038c2:	841fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free_store == nr_free_pages()); // 确保空闲页数一致
ffffffffc02038c6:	00002697          	auipc	a3,0x2
ffffffffc02038ca:	3c268693          	addi	a3,a3,962 # ffffffffc0205c88 <default_pmm_manager+0x490>
ffffffffc02038ce:	00001617          	auipc	a2,0x1
ffffffffc02038d2:	47a60613          	addi	a2,a2,1146 # ffffffffc0204d48 <commands+0x728>
ffffffffc02038d6:	1cf00593          	li	a1,463
ffffffffc02038da:	00002517          	auipc	a0,0x2
ffffffffc02038de:	04e50513          	addi	a0,a0,78 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc02038e2:	821fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc02038e6:	00002617          	auipc	a2,0x2
ffffffffc02038ea:	01a60613          	addi	a2,a2,26 # ffffffffc0205900 <default_pmm_manager+0x108>
ffffffffc02038ee:	07700593          	li	a1,119
ffffffffc02038f2:	00001517          	auipc	a0,0x1
ffffffffc02038f6:	6c650513          	addi	a0,a0,1734 # ffffffffc0204fb8 <commands+0x998>
ffffffffc02038fa:	809fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc02038fe:	00002697          	auipc	a3,0x2
ffffffffc0203902:	42a68693          	addi	a3,a3,1066 # ffffffffc0205d28 <default_pmm_manager+0x530>
ffffffffc0203906:	00001617          	auipc	a2,0x1
ffffffffc020390a:	44260613          	addi	a2,a2,1090 # ffffffffc0204d48 <commands+0x728>
ffffffffc020390e:	1b700593          	li	a1,439
ffffffffc0203912:	00002517          	auipc	a0,0x2
ffffffffc0203916:	01650513          	addi	a0,a0,22 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc020391a:	fe8fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc020391e:	00002697          	auipc	a3,0x2
ffffffffc0203922:	10a68693          	addi	a3,a3,266 # ffffffffc0205a28 <default_pmm_manager+0x230>
ffffffffc0203926:	00001617          	auipc	a2,0x1
ffffffffc020392a:	42260613          	addi	a2,a2,1058 # ffffffffc0204d48 <commands+0x728>
ffffffffc020392e:	17500593          	li	a1,373
ffffffffc0203932:	00002517          	auipc	a0,0x2
ffffffffc0203936:	ff650513          	addi	a0,a0,-10 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc020393a:	fc8fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc020393e:	00002697          	auipc	a3,0x2
ffffffffc0203942:	0ca68693          	addi	a3,a3,202 # ffffffffc0205a08 <default_pmm_manager+0x210>
ffffffffc0203946:	00001617          	auipc	a2,0x1
ffffffffc020394a:	40260613          	addi	a2,a2,1026 # ffffffffc0204d48 <commands+0x728>
ffffffffc020394e:	17400593          	li	a1,372
ffffffffc0203952:	00002517          	auipc	a0,0x2
ffffffffc0203956:	fd650513          	addi	a0,a0,-42 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc020395a:	fa8fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc020395e:	00002697          	auipc	a3,0x2
ffffffffc0203962:	1ba68693          	addi	a3,a3,442 # ffffffffc0205b18 <default_pmm_manager+0x320>
ffffffffc0203966:	00001617          	auipc	a2,0x1
ffffffffc020396a:	3e260613          	addi	a2,a2,994 # ffffffffc0204d48 <commands+0x728>
ffffffffc020396e:	18400593          	li	a1,388
ffffffffc0203972:	00002517          	auipc	a0,0x2
ffffffffc0203976:	fb650513          	addi	a0,a0,-74 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc020397a:	f88fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020397e:	86d6                	mv	a3,s5
ffffffffc0203980:	00002617          	auipc	a2,0x2
ffffffffc0203984:	f8060613          	addi	a2,a2,-128 # ffffffffc0205900 <default_pmm_manager+0x108>
ffffffffc0203988:	18300593          	li	a1,387
ffffffffc020398c:	00002517          	auipc	a0,0x2
ffffffffc0203990:	f9c50513          	addi	a0,a0,-100 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0203994:	f6efc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0203998:	00002697          	auipc	a3,0x2
ffffffffc020399c:	1e068693          	addi	a3,a3,480 # ffffffffc0205b78 <default_pmm_manager+0x380>
ffffffffc02039a0:	00001617          	auipc	a2,0x1
ffffffffc02039a4:	3a860613          	addi	a2,a2,936 # ffffffffc0204d48 <commands+0x728>
ffffffffc02039a8:	19300593          	li	a1,403
ffffffffc02039ac:	00002517          	auipc	a0,0x2
ffffffffc02039b0:	f7c50513          	addi	a0,a0,-132 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc02039b4:	f4efc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02039b8:	00002697          	auipc	a3,0x2
ffffffffc02039bc:	28868693          	addi	a3,a3,648 # ffffffffc0205c40 <default_pmm_manager+0x448>
ffffffffc02039c0:	00001617          	auipc	a2,0x1
ffffffffc02039c4:	38860613          	addi	a2,a2,904 # ffffffffc0204d48 <commands+0x728>
ffffffffc02039c8:	19200593          	li	a1,402
ffffffffc02039cc:	00002517          	auipc	a0,0x2
ffffffffc02039d0:	f5c50513          	addi	a0,a0,-164 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc02039d4:	f2efc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02039d8:	00002697          	auipc	a3,0x2
ffffffffc02039dc:	25068693          	addi	a3,a3,592 # ffffffffc0205c28 <default_pmm_manager+0x430>
ffffffffc02039e0:	00001617          	auipc	a2,0x1
ffffffffc02039e4:	36860613          	addi	a2,a2,872 # ffffffffc0204d48 <commands+0x728>
ffffffffc02039e8:	19100593          	li	a1,401
ffffffffc02039ec:	00002517          	auipc	a0,0x2
ffffffffc02039f0:	f3c50513          	addi	a0,a0,-196 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc02039f4:	f0efc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02039f8:	00002697          	auipc	a3,0x2
ffffffffc02039fc:	20068693          	addi	a3,a3,512 # ffffffffc0205bf8 <default_pmm_manager+0x400>
ffffffffc0203a00:	00001617          	auipc	a2,0x1
ffffffffc0203a04:	34860613          	addi	a2,a2,840 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203a08:	19000593          	li	a1,400
ffffffffc0203a0c:	00002517          	auipc	a0,0x2
ffffffffc0203a10:	f1c50513          	addi	a0,a0,-228 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0203a14:	eeefc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203a18:	00002697          	auipc	a3,0x2
ffffffffc0203a1c:	1c868693          	addi	a3,a3,456 # ffffffffc0205be0 <default_pmm_manager+0x3e8>
ffffffffc0203a20:	00001617          	auipc	a2,0x1
ffffffffc0203a24:	32860613          	addi	a2,a2,808 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203a28:	18d00593          	li	a1,397
ffffffffc0203a2c:	00002517          	auipc	a0,0x2
ffffffffc0203a30:	efc50513          	addi	a0,a0,-260 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0203a34:	ecefc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0203a38:	00002697          	auipc	a3,0x2
ffffffffc0203a3c:	19068693          	addi	a3,a3,400 # ffffffffc0205bc8 <default_pmm_manager+0x3d0>
ffffffffc0203a40:	00001617          	auipc	a2,0x1
ffffffffc0203a44:	30860613          	addi	a2,a2,776 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203a48:	18c00593          	li	a1,396
ffffffffc0203a4c:	00002517          	auipc	a0,0x2
ffffffffc0203a50:	edc50513          	addi	a0,a0,-292 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0203a54:	eaefc0ef          	jal	ra,ffffffffc0200102 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0203a58:	00002617          	auipc	a2,0x2
ffffffffc0203a5c:	f6860613          	addi	a2,a2,-152 # ffffffffc02059c0 <default_pmm_manager+0x1c8>
ffffffffc0203a60:	0c900593          	li	a1,201
ffffffffc0203a64:	00002517          	auipc	a0,0x2
ffffffffc0203a68:	ec450513          	addi	a0,a0,-316 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0203a6c:	e96fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(nr_free_store == nr_free_pages()); // 验证空闲页数是否与之前一致
ffffffffc0203a70:	00002697          	auipc	a3,0x2
ffffffffc0203a74:	21868693          	addi	a3,a3,536 # ffffffffc0205c88 <default_pmm_manager+0x490>
ffffffffc0203a78:	00001617          	auipc	a2,0x1
ffffffffc0203a7c:	2d060613          	addi	a2,a2,720 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203a80:	1a500593          	li	a1,421
ffffffffc0203a84:	00002517          	auipc	a0,0x2
ffffffffc0203a88:	ea450513          	addi	a0,a0,-348 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0203a8c:	e76fc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203a90 <tlb_invalidate>:
    asm volatile("sfence.vma"); // 刷新 TLB 中的地址映射
ffffffffc0203a90:	12000073          	sfence.vma
void tlb_invalidate(pde_t *pgdir, uintptr_t la) { flush_tlb(); }
ffffffffc0203a94:	8082                	ret

ffffffffc0203a96 <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0203a96:	7179                	addi	sp,sp,-48
ffffffffc0203a98:	e84a                	sd	s2,16(sp)
ffffffffc0203a9a:	892a                	mv	s2,a0
    struct Page *page = alloc_page(); // 分配一个物理页
ffffffffc0203a9c:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0203a9e:	f022                	sd	s0,32(sp)
ffffffffc0203aa0:	ec26                	sd	s1,24(sp)
ffffffffc0203aa2:	e44e                	sd	s3,8(sp)
ffffffffc0203aa4:	f406                	sd	ra,40(sp)
ffffffffc0203aa6:	84ae                	mv	s1,a1
ffffffffc0203aa8:	89b2                	mv	s3,a2
    struct Page *page = alloc_page(); // 分配一个物理页
ffffffffc0203aaa:	f1ffe0ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
ffffffffc0203aae:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0203ab0:	cd09                	beqz	a0,ffffffffc0203aca <pgdir_alloc_page+0x34>
        if (page_insert(pgdir, page, la, perm) != 0) { // 插入页表映射，若失败则释放页面并返回 NULL
ffffffffc0203ab2:	85aa                	mv	a1,a0
ffffffffc0203ab4:	86ce                	mv	a3,s3
ffffffffc0203ab6:	8626                	mv	a2,s1
ffffffffc0203ab8:	854a                	mv	a0,s2
ffffffffc0203aba:	b04ff0ef          	jal	ra,ffffffffc0202dbe <page_insert>
ffffffffc0203abe:	ed21                	bnez	a0,ffffffffc0203b16 <pgdir_alloc_page+0x80>
        if (swap_init_ok) { // 若启用交换功能
ffffffffc0203ac0:	0000e797          	auipc	a5,0xe
ffffffffc0203ac4:	a707a783          	lw	a5,-1424(a5) # ffffffffc0211530 <swap_init_ok>
ffffffffc0203ac8:	eb89                	bnez	a5,ffffffffc0203ada <pgdir_alloc_page+0x44>
}
ffffffffc0203aca:	70a2                	ld	ra,40(sp)
ffffffffc0203acc:	8522                	mv	a0,s0
ffffffffc0203ace:	7402                	ld	s0,32(sp)
ffffffffc0203ad0:	64e2                	ld	s1,24(sp)
ffffffffc0203ad2:	6942                	ld	s2,16(sp)
ffffffffc0203ad4:	69a2                	ld	s3,8(sp)
ffffffffc0203ad6:	6145                	addi	sp,sp,48
ffffffffc0203ad8:	8082                	ret
            swap_map_swappable(check_mm_struct, la, page, 0); // 将页面标记为可交换
ffffffffc0203ada:	4681                	li	a3,0
ffffffffc0203adc:	8622                	mv	a2,s0
ffffffffc0203ade:	85a6                	mv	a1,s1
ffffffffc0203ae0:	0000e517          	auipc	a0,0xe
ffffffffc0203ae4:	a3053503          	ld	a0,-1488(a0) # ffffffffc0211510 <check_mm_struct>
ffffffffc0203ae8:	ec5fd0ef          	jal	ra,ffffffffc02019ac <swap_map_swappable>
            assert(page_ref(page) == 1); // 确保页面的引用计数为1
ffffffffc0203aec:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la; // 设置页面的虚拟地址
ffffffffc0203aee:	e024                	sd	s1,64(s0)
            assert(page_ref(page) == 1); // 确保页面的引用计数为1
ffffffffc0203af0:	4785                	li	a5,1
ffffffffc0203af2:	fcf70ce3          	beq	a4,a5,ffffffffc0203aca <pgdir_alloc_page+0x34>
ffffffffc0203af6:	00002697          	auipc	a3,0x2
ffffffffc0203afa:	38a68693          	addi	a3,a3,906 # ffffffffc0205e80 <default_pmm_manager+0x688>
ffffffffc0203afe:	00001617          	auipc	a2,0x1
ffffffffc0203b02:	24a60613          	addi	a2,a2,586 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203b06:	16200593          	li	a1,354
ffffffffc0203b0a:	00002517          	auipc	a0,0x2
ffffffffc0203b0e:	e1e50513          	addi	a0,a0,-482 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0203b12:	df0fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203b16:	100027f3          	csrr	a5,sstatus
ffffffffc0203b1a:	8b89                	andi	a5,a5,2
ffffffffc0203b1c:	eb99                	bnez	a5,ffffffffc0203b32 <pgdir_alloc_page+0x9c>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0203b1e:	0000e797          	auipc	a5,0xe
ffffffffc0203b22:	a427b783          	ld	a5,-1470(a5) # ffffffffc0211560 <pmm_manager>
ffffffffc0203b26:	739c                	ld	a5,32(a5)
ffffffffc0203b28:	8522                	mv	a0,s0
ffffffffc0203b2a:	4585                	li	a1,1
ffffffffc0203b2c:	9782                	jalr	a5
            return NULL;
ffffffffc0203b2e:	4401                	li	s0,0
ffffffffc0203b30:	bf69                	j	ffffffffc0203aca <pgdir_alloc_page+0x34>
        intr_disable();
ffffffffc0203b32:	9bdfc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0203b36:	0000e797          	auipc	a5,0xe
ffffffffc0203b3a:	a2a7b783          	ld	a5,-1494(a5) # ffffffffc0211560 <pmm_manager>
ffffffffc0203b3e:	739c                	ld	a5,32(a5)
ffffffffc0203b40:	8522                	mv	a0,s0
ffffffffc0203b42:	4585                	li	a1,1
ffffffffc0203b44:	9782                	jalr	a5
            return NULL;
ffffffffc0203b46:	4401                	li	s0,0
        intr_enable();
ffffffffc0203b48:	9a1fc0ef          	jal	ra,ffffffffc02004e8 <intr_enable>
ffffffffc0203b4c:	bfbd                	j	ffffffffc0203aca <pgdir_alloc_page+0x34>

ffffffffc0203b4e <kmalloc>:
}

// kmalloc - 内核内存分配函数，分配 n 字节的内存并返回内核虚拟地址
void *kmalloc(size_t n) {
ffffffffc0203b4e:	1141                	addi	sp,sp,-16
    void *ptr = NULL;
    struct Page *base = NULL;
    assert(n > 0 && n < 1024 * 0124); // 确保分配字节数在范围内
ffffffffc0203b50:	67d5                	lui	a5,0x15
void *kmalloc(size_t n) {
ffffffffc0203b52:	e406                	sd	ra,8(sp)
    assert(n > 0 && n < 1024 * 0124); // 确保分配字节数在范围内
ffffffffc0203b54:	fff50713          	addi	a4,a0,-1
ffffffffc0203b58:	17f9                	addi	a5,a5,-2
ffffffffc0203b5a:	04e7ea63          	bltu	a5,a4,ffffffffc0203bae <kmalloc+0x60>
    int num_pages = (n + PGSIZE - 1) / PGSIZE; // 计算所需的页面数
ffffffffc0203b5e:	6785                	lui	a5,0x1
ffffffffc0203b60:	17fd                	addi	a5,a5,-1
ffffffffc0203b62:	953e                	add	a0,a0,a5
    base = alloc_pages(num_pages); // 分配页面
ffffffffc0203b64:	8131                	srli	a0,a0,0xc
ffffffffc0203b66:	e63fe0ef          	jal	ra,ffffffffc02029c8 <alloc_pages>
    assert(base != NULL);
ffffffffc0203b6a:	cd3d                	beqz	a0,ffffffffc0203be8 <kmalloc+0x9a>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0203b6c:	0000e797          	auipc	a5,0xe
ffffffffc0203b70:	9ec7b783          	ld	a5,-1556(a5) # ffffffffc0211558 <pages>
ffffffffc0203b74:	8d1d                	sub	a0,a0,a5
ffffffffc0203b76:	00002697          	auipc	a3,0x2
ffffffffc0203b7a:	6026b683          	ld	a3,1538(a3) # ffffffffc0206178 <error_string+0x38>
ffffffffc0203b7e:	850d                	srai	a0,a0,0x3
ffffffffc0203b80:	02d50533          	mul	a0,a0,a3
ffffffffc0203b84:	000806b7          	lui	a3,0x80
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203b88:	0000e717          	auipc	a4,0xe
ffffffffc0203b8c:	9c873703          	ld	a4,-1592(a4) # ffffffffc0211550 <npage>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0203b90:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203b92:	00c51793          	slli	a5,a0,0xc
ffffffffc0203b96:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc0203b98:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203b9a:	02e7fa63          	bgeu	a5,a4,ffffffffc0203bce <kmalloc+0x80>
    ptr = page2kva(base); // 将页面转换为内核虚拟地址
    return ptr;
}
ffffffffc0203b9e:	60a2                	ld	ra,8(sp)
ffffffffc0203ba0:	0000e797          	auipc	a5,0xe
ffffffffc0203ba4:	9c87b783          	ld	a5,-1592(a5) # ffffffffc0211568 <va_pa_offset>
ffffffffc0203ba8:	953e                	add	a0,a0,a5
ffffffffc0203baa:	0141                	addi	sp,sp,16
ffffffffc0203bac:	8082                	ret
    assert(n > 0 && n < 1024 * 0124); // 确保分配字节数在范围内
ffffffffc0203bae:	00002697          	auipc	a3,0x2
ffffffffc0203bb2:	2ea68693          	addi	a3,a3,746 # ffffffffc0205e98 <default_pmm_manager+0x6a0>
ffffffffc0203bb6:	00001617          	auipc	a2,0x1
ffffffffc0203bba:	19260613          	addi	a2,a2,402 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203bbe:	1d800593          	li	a1,472
ffffffffc0203bc2:	00002517          	auipc	a0,0x2
ffffffffc0203bc6:	d6650513          	addi	a0,a0,-666 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0203bca:	d38fc0ef          	jal	ra,ffffffffc0200102 <__panic>
ffffffffc0203bce:	86aa                	mv	a3,a0
ffffffffc0203bd0:	00002617          	auipc	a2,0x2
ffffffffc0203bd4:	d3060613          	addi	a2,a2,-720 # ffffffffc0205900 <default_pmm_manager+0x108>
ffffffffc0203bd8:	07700593          	li	a1,119
ffffffffc0203bdc:	00001517          	auipc	a0,0x1
ffffffffc0203be0:	3dc50513          	addi	a0,a0,988 # ffffffffc0204fb8 <commands+0x998>
ffffffffc0203be4:	d1efc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(base != NULL);
ffffffffc0203be8:	00002697          	auipc	a3,0x2
ffffffffc0203bec:	2d068693          	addi	a3,a3,720 # ffffffffc0205eb8 <default_pmm_manager+0x6c0>
ffffffffc0203bf0:	00001617          	auipc	a2,0x1
ffffffffc0203bf4:	15860613          	addi	a2,a2,344 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203bf8:	1db00593          	li	a1,475
ffffffffc0203bfc:	00002517          	auipc	a0,0x2
ffffffffc0203c00:	d2c50513          	addi	a0,a0,-724 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0203c04:	cfefc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203c08 <kfree>:

// kfree - 内核内存释放函数，释放 ptr 开始的 n 字节内存
void kfree(void *ptr, size_t n) {
ffffffffc0203c08:	1101                	addi	sp,sp,-32
    assert(n > 0 && n < 1024 * 0124); // 确保释放字节数在范围内
ffffffffc0203c0a:	67d5                	lui	a5,0x15
void kfree(void *ptr, size_t n) {
ffffffffc0203c0c:	ec06                	sd	ra,24(sp)
    assert(n > 0 && n < 1024 * 0124); // 确保释放字节数在范围内
ffffffffc0203c0e:	fff58713          	addi	a4,a1,-1
ffffffffc0203c12:	17f9                	addi	a5,a5,-2
ffffffffc0203c14:	0ae7ee63          	bltu	a5,a4,ffffffffc0203cd0 <kfree+0xc8>
    assert(ptr != NULL);
ffffffffc0203c18:	cd41                	beqz	a0,ffffffffc0203cb0 <kfree+0xa8>
    struct Page *base = NULL;
    int num_pages = (n + PGSIZE - 1) / PGSIZE; // 计算所需的页面数
ffffffffc0203c1a:	6785                	lui	a5,0x1
ffffffffc0203c1c:	17fd                	addi	a5,a5,-1
ffffffffc0203c1e:	95be                	add	a1,a1,a5
    return pa2page(PADDR(kva)); // 先获取物理地址，再调用 pa2page 返回对应的 Page 结构体
ffffffffc0203c20:	c02007b7          	lui	a5,0xc0200
ffffffffc0203c24:	81b1                	srli	a1,a1,0xc
ffffffffc0203c26:	06f56863          	bltu	a0,a5,ffffffffc0203c96 <kfree+0x8e>
ffffffffc0203c2a:	0000e697          	auipc	a3,0xe
ffffffffc0203c2e:	93e6b683          	ld	a3,-1730(a3) # ffffffffc0211568 <va_pa_offset>
ffffffffc0203c32:	8d15                	sub	a0,a0,a3
    if (PPN(pa) >= npage) { // 检查物理页号是否在有效范围内
ffffffffc0203c34:	8131                	srli	a0,a0,0xc
ffffffffc0203c36:	0000e797          	auipc	a5,0xe
ffffffffc0203c3a:	91a7b783          	ld	a5,-1766(a5) # ffffffffc0211550 <npage>
ffffffffc0203c3e:	04f57a63          	bgeu	a0,a5,ffffffffc0203c92 <kfree+0x8a>
    return &pages[PPN(pa) - nbase]; // 返回物理地址对应的 Page 结构体指针
ffffffffc0203c42:	fff806b7          	lui	a3,0xfff80
ffffffffc0203c46:	9536                	add	a0,a0,a3
ffffffffc0203c48:	00351793          	slli	a5,a0,0x3
ffffffffc0203c4c:	953e                	add	a0,a0,a5
ffffffffc0203c4e:	050e                	slli	a0,a0,0x3
ffffffffc0203c50:	0000e797          	auipc	a5,0xe
ffffffffc0203c54:	9087b783          	ld	a5,-1784(a5) # ffffffffc0211558 <pages>
ffffffffc0203c58:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203c5a:	100027f3          	csrr	a5,sstatus
ffffffffc0203c5e:	8b89                	andi	a5,a5,2
ffffffffc0203c60:	eb89                	bnez	a5,ffffffffc0203c72 <kfree+0x6a>
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0203c62:	0000e797          	auipc	a5,0xe
ffffffffc0203c66:	8fe7b783          	ld	a5,-1794(a5) # ffffffffc0211560 <pmm_manager>
    base = kva2page(ptr); // 获取页面指针
    free_pages(base, num_pages); // 释放页面
}
ffffffffc0203c6a:	60e2                	ld	ra,24(sp)
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0203c6c:	739c                	ld	a5,32(a5)
}
ffffffffc0203c6e:	6105                	addi	sp,sp,32
        pmm_manager->free_pages(base, n); // 调用内存管理器的释放函数
ffffffffc0203c70:	8782                	jr	a5
        intr_disable();
ffffffffc0203c72:	e42a                	sd	a0,8(sp)
ffffffffc0203c74:	e02e                	sd	a1,0(sp)
ffffffffc0203c76:	879fc0ef          	jal	ra,ffffffffc02004ee <intr_disable>
ffffffffc0203c7a:	0000e797          	auipc	a5,0xe
ffffffffc0203c7e:	8e67b783          	ld	a5,-1818(a5) # ffffffffc0211560 <pmm_manager>
ffffffffc0203c82:	6582                	ld	a1,0(sp)
ffffffffc0203c84:	6522                	ld	a0,8(sp)
ffffffffc0203c86:	739c                	ld	a5,32(a5)
ffffffffc0203c88:	9782                	jalr	a5
}
ffffffffc0203c8a:	60e2                	ld	ra,24(sp)
ffffffffc0203c8c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0203c8e:	85bfc06f          	j	ffffffffc02004e8 <intr_enable>
ffffffffc0203c92:	cfffe0ef          	jal	ra,ffffffffc0202990 <pa2page.part.0>
    return pa2page(PADDR(kva)); // 先获取物理地址，再调用 pa2page 返回对应的 Page 结构体
ffffffffc0203c96:	86aa                	mv	a3,a0
ffffffffc0203c98:	00002617          	auipc	a2,0x2
ffffffffc0203c9c:	d2860613          	addi	a2,a2,-728 # ffffffffc02059c0 <default_pmm_manager+0x1c8>
ffffffffc0203ca0:	07c00593          	li	a1,124
ffffffffc0203ca4:	00001517          	auipc	a0,0x1
ffffffffc0203ca8:	31450513          	addi	a0,a0,788 # ffffffffc0204fb8 <commands+0x998>
ffffffffc0203cac:	c56fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(ptr != NULL);
ffffffffc0203cb0:	00002697          	auipc	a3,0x2
ffffffffc0203cb4:	21868693          	addi	a3,a3,536 # ffffffffc0205ec8 <default_pmm_manager+0x6d0>
ffffffffc0203cb8:	00001617          	auipc	a2,0x1
ffffffffc0203cbc:	09060613          	addi	a2,a2,144 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203cc0:	1e300593          	li	a1,483
ffffffffc0203cc4:	00002517          	auipc	a0,0x2
ffffffffc0203cc8:	c6450513          	addi	a0,a0,-924 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0203ccc:	c36fc0ef          	jal	ra,ffffffffc0200102 <__panic>
    assert(n > 0 && n < 1024 * 0124); // 确保释放字节数在范围内
ffffffffc0203cd0:	00002697          	auipc	a3,0x2
ffffffffc0203cd4:	1c868693          	addi	a3,a3,456 # ffffffffc0205e98 <default_pmm_manager+0x6a0>
ffffffffc0203cd8:	00001617          	auipc	a2,0x1
ffffffffc0203cdc:	07060613          	addi	a2,a2,112 # ffffffffc0204d48 <commands+0x728>
ffffffffc0203ce0:	1e200593          	li	a1,482
ffffffffc0203ce4:	00002517          	auipc	a0,0x2
ffffffffc0203ce8:	c4450513          	addi	a0,a0,-956 # ffffffffc0205928 <default_pmm_manager+0x130>
ffffffffc0203cec:	c16fc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203cf0 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0203cf0:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203cf2:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0203cf4:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0203cf6:	edcfc0ef          	jal	ra,ffffffffc02003d2 <ide_device_valid>
ffffffffc0203cfa:	cd01                	beqz	a0,ffffffffc0203d12 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203cfc:	4505                	li	a0,1
ffffffffc0203cfe:	edafc0ef          	jal	ra,ffffffffc02003d8 <ide_device_size>
}
ffffffffc0203d02:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0203d04:	810d                	srli	a0,a0,0x3
ffffffffc0203d06:	0000e797          	auipc	a5,0xe
ffffffffc0203d0a:	80a7bd23          	sd	a0,-2022(a5) # ffffffffc0211520 <max_swap_offset>
}
ffffffffc0203d0e:	0141                	addi	sp,sp,16
ffffffffc0203d10:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0203d12:	00002617          	auipc	a2,0x2
ffffffffc0203d16:	1c660613          	addi	a2,a2,454 # ffffffffc0205ed8 <default_pmm_manager+0x6e0>
ffffffffc0203d1a:	45b5                	li	a1,13
ffffffffc0203d1c:	00002517          	auipc	a0,0x2
ffffffffc0203d20:	1dc50513          	addi	a0,a0,476 # ffffffffc0205ef8 <default_pmm_manager+0x700>
ffffffffc0203d24:	bdefc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203d28 <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0203d28:	1141                	addi	sp,sp,-16
ffffffffc0203d2a:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d2c:	00855793          	srli	a5,a0,0x8
ffffffffc0203d30:	c3a5                	beqz	a5,ffffffffc0203d90 <swapfs_read+0x68>
ffffffffc0203d32:	0000d717          	auipc	a4,0xd
ffffffffc0203d36:	7ee73703          	ld	a4,2030(a4) # ffffffffc0211520 <max_swap_offset>
ffffffffc0203d3a:	04e7fb63          	bgeu	a5,a4,ffffffffc0203d90 <swapfs_read+0x68>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0203d3e:	0000e617          	auipc	a2,0xe
ffffffffc0203d42:	81a63603          	ld	a2,-2022(a2) # ffffffffc0211558 <pages>
ffffffffc0203d46:	8d91                	sub	a1,a1,a2
ffffffffc0203d48:	4035d613          	srai	a2,a1,0x3
ffffffffc0203d4c:	00002597          	auipc	a1,0x2
ffffffffc0203d50:	42c5b583          	ld	a1,1068(a1) # ffffffffc0206178 <error_string+0x38>
ffffffffc0203d54:	02b60633          	mul	a2,a2,a1
ffffffffc0203d58:	0037959b          	slliw	a1,a5,0x3
ffffffffc0203d5c:	00002797          	auipc	a5,0x2
ffffffffc0203d60:	4247b783          	ld	a5,1060(a5) # ffffffffc0206180 <nbase>
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203d64:	0000d717          	auipc	a4,0xd
ffffffffc0203d68:	7ec73703          	ld	a4,2028(a4) # ffffffffc0211550 <npage>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0203d6c:	963e                	add	a2,a2,a5
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203d6e:	00c61793          	slli	a5,a2,0xc
ffffffffc0203d72:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc0203d74:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203d76:	02e7f963          	bgeu	a5,a4,ffffffffc0203da8 <swapfs_read+0x80>
}
ffffffffc0203d7a:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d7c:	0000d797          	auipc	a5,0xd
ffffffffc0203d80:	7ec7b783          	ld	a5,2028(a5) # ffffffffc0211568 <va_pa_offset>
ffffffffc0203d84:	46a1                	li	a3,8
ffffffffc0203d86:	963e                	add	a2,a2,a5
ffffffffc0203d88:	4505                	li	a0,1
}
ffffffffc0203d8a:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203d8c:	e52fc06f          	j	ffffffffc02003de <ide_read_secs>
ffffffffc0203d90:	86aa                	mv	a3,a0
ffffffffc0203d92:	00002617          	auipc	a2,0x2
ffffffffc0203d96:	17e60613          	addi	a2,a2,382 # ffffffffc0205f10 <default_pmm_manager+0x718>
ffffffffc0203d9a:	45d1                	li	a1,20
ffffffffc0203d9c:	00002517          	auipc	a0,0x2
ffffffffc0203da0:	15c50513          	addi	a0,a0,348 # ffffffffc0205ef8 <default_pmm_manager+0x700>
ffffffffc0203da4:	b5efc0ef          	jal	ra,ffffffffc0200102 <__panic>
ffffffffc0203da8:	86b2                	mv	a3,a2
ffffffffc0203daa:	07700593          	li	a1,119
ffffffffc0203dae:	00002617          	auipc	a2,0x2
ffffffffc0203db2:	b5260613          	addi	a2,a2,-1198 # ffffffffc0205900 <default_pmm_manager+0x108>
ffffffffc0203db6:	00001517          	auipc	a0,0x1
ffffffffc0203dba:	20250513          	addi	a0,a0,514 # ffffffffc0204fb8 <commands+0x998>
ffffffffc0203dbe:	b44fc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203dc2 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0203dc2:	1141                	addi	sp,sp,-16
ffffffffc0203dc4:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203dc6:	00855793          	srli	a5,a0,0x8
ffffffffc0203dca:	c3a5                	beqz	a5,ffffffffc0203e2a <swapfs_write+0x68>
ffffffffc0203dcc:	0000d717          	auipc	a4,0xd
ffffffffc0203dd0:	75473703          	ld	a4,1876(a4) # ffffffffc0211520 <max_swap_offset>
ffffffffc0203dd4:	04e7fb63          	bgeu	a5,a4,ffffffffc0203e2a <swapfs_write+0x68>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0203dd8:	0000d617          	auipc	a2,0xd
ffffffffc0203ddc:	78063603          	ld	a2,1920(a2) # ffffffffc0211558 <pages>
ffffffffc0203de0:	8d91                	sub	a1,a1,a2
ffffffffc0203de2:	4035d613          	srai	a2,a1,0x3
ffffffffc0203de6:	00002597          	auipc	a1,0x2
ffffffffc0203dea:	3925b583          	ld	a1,914(a1) # ffffffffc0206178 <error_string+0x38>
ffffffffc0203dee:	02b60633          	mul	a2,a2,a1
ffffffffc0203df2:	0037959b          	slliw	a1,a5,0x3
ffffffffc0203df6:	00002797          	auipc	a5,0x2
ffffffffc0203dfa:	38a7b783          	ld	a5,906(a5) # ffffffffc0206180 <nbase>
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203dfe:	0000d717          	auipc	a4,0xd
ffffffffc0203e02:	75273703          	ld	a4,1874(a4) # ffffffffc0211550 <npage>
    return page - pages + nbase; // 返回当前 page 相对于 pages 的偏移量，加上 nbase 得到页帧号
ffffffffc0203e06:	963e                	add	a2,a2,a5
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203e08:	00c61793          	slli	a5,a2,0xc
ffffffffc0203e0c:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT; // 将页帧号左移 PGSHIFT 位转换为物理地址
ffffffffc0203e0e:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page)); // 先获取物理地址，再调用 KADDR 映射到内核虚拟地址
ffffffffc0203e10:	02e7f963          	bgeu	a5,a4,ffffffffc0203e42 <swapfs_write+0x80>
}
ffffffffc0203e14:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203e16:	0000d797          	auipc	a5,0xd
ffffffffc0203e1a:	7527b783          	ld	a5,1874(a5) # ffffffffc0211568 <va_pa_offset>
ffffffffc0203e1e:	46a1                	li	a3,8
ffffffffc0203e20:	963e                	add	a2,a2,a5
ffffffffc0203e22:	4505                	li	a0,1
}
ffffffffc0203e24:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0203e26:	ddcfc06f          	j	ffffffffc0200402 <ide_write_secs>
ffffffffc0203e2a:	86aa                	mv	a3,a0
ffffffffc0203e2c:	00002617          	auipc	a2,0x2
ffffffffc0203e30:	0e460613          	addi	a2,a2,228 # ffffffffc0205f10 <default_pmm_manager+0x718>
ffffffffc0203e34:	45e5                	li	a1,25
ffffffffc0203e36:	00002517          	auipc	a0,0x2
ffffffffc0203e3a:	0c250513          	addi	a0,a0,194 # ffffffffc0205ef8 <default_pmm_manager+0x700>
ffffffffc0203e3e:	ac4fc0ef          	jal	ra,ffffffffc0200102 <__panic>
ffffffffc0203e42:	86b2                	mv	a3,a2
ffffffffc0203e44:	07700593          	li	a1,119
ffffffffc0203e48:	00002617          	auipc	a2,0x2
ffffffffc0203e4c:	ab860613          	addi	a2,a2,-1352 # ffffffffc0205900 <default_pmm_manager+0x108>
ffffffffc0203e50:	00001517          	auipc	a0,0x1
ffffffffc0203e54:	16850513          	addi	a0,a0,360 # ffffffffc0204fb8 <commands+0x998>
ffffffffc0203e58:	aaafc0ef          	jal	ra,ffffffffc0200102 <__panic>

ffffffffc0203e5c <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0203e5c:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0203e60:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0203e62:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0203e64:	cb81                	beqz	a5,ffffffffc0203e74 <strlen+0x18>
        cnt ++;
ffffffffc0203e66:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0203e68:	00a707b3          	add	a5,a4,a0
ffffffffc0203e6c:	0007c783          	lbu	a5,0(a5)
ffffffffc0203e70:	fbfd                	bnez	a5,ffffffffc0203e66 <strlen+0xa>
ffffffffc0203e72:	8082                	ret
    }
    return cnt;
}
ffffffffc0203e74:	8082                	ret

ffffffffc0203e76 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0203e76:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203e78:	e589                	bnez	a1,ffffffffc0203e82 <strnlen+0xc>
ffffffffc0203e7a:	a811                	j	ffffffffc0203e8e <strnlen+0x18>
        cnt ++;
ffffffffc0203e7c:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0203e7e:	00f58863          	beq	a1,a5,ffffffffc0203e8e <strnlen+0x18>
ffffffffc0203e82:	00f50733          	add	a4,a0,a5
ffffffffc0203e86:	00074703          	lbu	a4,0(a4)
ffffffffc0203e8a:	fb6d                	bnez	a4,ffffffffc0203e7c <strnlen+0x6>
ffffffffc0203e8c:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0203e8e:	852e                	mv	a0,a1
ffffffffc0203e90:	8082                	ret

ffffffffc0203e92 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0203e92:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0203e94:	0005c703          	lbu	a4,0(a1)
ffffffffc0203e98:	0785                	addi	a5,a5,1
ffffffffc0203e9a:	0585                	addi	a1,a1,1
ffffffffc0203e9c:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0203ea0:	fb75                	bnez	a4,ffffffffc0203e94 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0203ea2:	8082                	ret

ffffffffc0203ea4 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203ea4:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203ea8:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203eac:	cb89                	beqz	a5,ffffffffc0203ebe <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0203eae:	0505                	addi	a0,a0,1
ffffffffc0203eb0:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0203eb2:	fee789e3          	beq	a5,a4,ffffffffc0203ea4 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0203eb6:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0203eba:	9d19                	subw	a0,a0,a4
ffffffffc0203ebc:	8082                	ret
ffffffffc0203ebe:	4501                	li	a0,0
ffffffffc0203ec0:	bfed                	j	ffffffffc0203eba <strcmp+0x16>

ffffffffc0203ec2 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0203ec2:	00054783          	lbu	a5,0(a0)
ffffffffc0203ec6:	c799                	beqz	a5,ffffffffc0203ed4 <strchr+0x12>
        if (*s == c) {
ffffffffc0203ec8:	00f58763          	beq	a1,a5,ffffffffc0203ed6 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0203ecc:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0203ed0:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0203ed2:	fbfd                	bnez	a5,ffffffffc0203ec8 <strchr+0x6>
    }
    return NULL;
ffffffffc0203ed4:	4501                	li	a0,0
}
ffffffffc0203ed6:	8082                	ret

ffffffffc0203ed8 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0203ed8:	ca01                	beqz	a2,ffffffffc0203ee8 <memset+0x10>
ffffffffc0203eda:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0203edc:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0203ede:	0785                	addi	a5,a5,1
ffffffffc0203ee0:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0203ee4:	fec79de3          	bne	a5,a2,ffffffffc0203ede <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0203ee8:	8082                	ret

ffffffffc0203eea <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0203eea:	ca19                	beqz	a2,ffffffffc0203f00 <memcpy+0x16>
ffffffffc0203eec:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0203eee:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0203ef0:	0005c703          	lbu	a4,0(a1)
ffffffffc0203ef4:	0585                	addi	a1,a1,1
ffffffffc0203ef6:	0785                	addi	a5,a5,1
ffffffffc0203ef8:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0203efc:	fec59ae3          	bne	a1,a2,ffffffffc0203ef0 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0203f00:	8082                	ret

ffffffffc0203f02 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0203f02:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203f06:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0203f08:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203f0c:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0203f0e:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0203f12:	f022                	sd	s0,32(sp)
ffffffffc0203f14:	ec26                	sd	s1,24(sp)
ffffffffc0203f16:	e84a                	sd	s2,16(sp)
ffffffffc0203f18:	f406                	sd	ra,40(sp)
ffffffffc0203f1a:	e44e                	sd	s3,8(sp)
ffffffffc0203f1c:	84aa                	mv	s1,a0
ffffffffc0203f1e:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0203f20:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0203f24:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0203f26:	03067e63          	bgeu	a2,a6,ffffffffc0203f62 <printnum+0x60>
ffffffffc0203f2a:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0203f2c:	00805763          	blez	s0,ffffffffc0203f3a <printnum+0x38>
ffffffffc0203f30:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0203f32:	85ca                	mv	a1,s2
ffffffffc0203f34:	854e                	mv	a0,s3
ffffffffc0203f36:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0203f38:	fc65                	bnez	s0,ffffffffc0203f30 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203f3a:	1a02                	slli	s4,s4,0x20
ffffffffc0203f3c:	00002797          	auipc	a5,0x2
ffffffffc0203f40:	ff478793          	addi	a5,a5,-12 # ffffffffc0205f30 <default_pmm_manager+0x738>
ffffffffc0203f44:	020a5a13          	srli	s4,s4,0x20
ffffffffc0203f48:	9a3e                	add	s4,s4,a5
}
ffffffffc0203f4a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203f4c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0203f50:	70a2                	ld	ra,40(sp)
ffffffffc0203f52:	69a2                	ld	s3,8(sp)
ffffffffc0203f54:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203f56:	85ca                	mv	a1,s2
ffffffffc0203f58:	87a6                	mv	a5,s1
}
ffffffffc0203f5a:	6942                	ld	s2,16(sp)
ffffffffc0203f5c:	64e2                	ld	s1,24(sp)
ffffffffc0203f5e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0203f60:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0203f62:	03065633          	divu	a2,a2,a6
ffffffffc0203f66:	8722                	mv	a4,s0
ffffffffc0203f68:	f9bff0ef          	jal	ra,ffffffffc0203f02 <printnum>
ffffffffc0203f6c:	b7f9                	j	ffffffffc0203f3a <printnum+0x38>

ffffffffc0203f6e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0203f6e:	7119                	addi	sp,sp,-128
ffffffffc0203f70:	f4a6                	sd	s1,104(sp)
ffffffffc0203f72:	f0ca                	sd	s2,96(sp)
ffffffffc0203f74:	ecce                	sd	s3,88(sp)
ffffffffc0203f76:	e8d2                	sd	s4,80(sp)
ffffffffc0203f78:	e4d6                	sd	s5,72(sp)
ffffffffc0203f7a:	e0da                	sd	s6,64(sp)
ffffffffc0203f7c:	fc5e                	sd	s7,56(sp)
ffffffffc0203f7e:	f06a                	sd	s10,32(sp)
ffffffffc0203f80:	fc86                	sd	ra,120(sp)
ffffffffc0203f82:	f8a2                	sd	s0,112(sp)
ffffffffc0203f84:	f862                	sd	s8,48(sp)
ffffffffc0203f86:	f466                	sd	s9,40(sp)
ffffffffc0203f88:	ec6e                	sd	s11,24(sp)
ffffffffc0203f8a:	892a                	mv	s2,a0
ffffffffc0203f8c:	84ae                	mv	s1,a1
ffffffffc0203f8e:	8d32                	mv	s10,a2
ffffffffc0203f90:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203f92:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0203f96:	5b7d                	li	s6,-1
ffffffffc0203f98:	00002a97          	auipc	s5,0x2
ffffffffc0203f9c:	fcca8a93          	addi	s5,s5,-52 # ffffffffc0205f64 <default_pmm_manager+0x76c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0203fa0:	00002b97          	auipc	s7,0x2
ffffffffc0203fa4:	1a0b8b93          	addi	s7,s7,416 # ffffffffc0206140 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203fa8:	000d4503          	lbu	a0,0(s10) # 80000 <kern_entry-0xffffffffc0180000>
ffffffffc0203fac:	001d0413          	addi	s0,s10,1
ffffffffc0203fb0:	01350a63          	beq	a0,s3,ffffffffc0203fc4 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0203fb4:	c121                	beqz	a0,ffffffffc0203ff4 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0203fb6:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203fb8:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0203fba:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0203fbc:	fff44503          	lbu	a0,-1(s0)
ffffffffc0203fc0:	ff351ae3          	bne	a0,s3,ffffffffc0203fb4 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203fc4:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0203fc8:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0203fcc:	4c81                	li	s9,0
ffffffffc0203fce:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0203fd0:	5c7d                	li	s8,-1
ffffffffc0203fd2:	5dfd                	li	s11,-1
ffffffffc0203fd4:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0203fd8:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0203fda:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0203fde:	0ff5f593          	zext.b	a1,a1
ffffffffc0203fe2:	00140d13          	addi	s10,s0,1
ffffffffc0203fe6:	04b56263          	bltu	a0,a1,ffffffffc020402a <vprintfmt+0xbc>
ffffffffc0203fea:	058a                	slli	a1,a1,0x2
ffffffffc0203fec:	95d6                	add	a1,a1,s5
ffffffffc0203fee:	4194                	lw	a3,0(a1)
ffffffffc0203ff0:	96d6                	add	a3,a3,s5
ffffffffc0203ff2:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0203ff4:	70e6                	ld	ra,120(sp)
ffffffffc0203ff6:	7446                	ld	s0,112(sp)
ffffffffc0203ff8:	74a6                	ld	s1,104(sp)
ffffffffc0203ffa:	7906                	ld	s2,96(sp)
ffffffffc0203ffc:	69e6                	ld	s3,88(sp)
ffffffffc0203ffe:	6a46                	ld	s4,80(sp)
ffffffffc0204000:	6aa6                	ld	s5,72(sp)
ffffffffc0204002:	6b06                	ld	s6,64(sp)
ffffffffc0204004:	7be2                	ld	s7,56(sp)
ffffffffc0204006:	7c42                	ld	s8,48(sp)
ffffffffc0204008:	7ca2                	ld	s9,40(sp)
ffffffffc020400a:	7d02                	ld	s10,32(sp)
ffffffffc020400c:	6de2                	ld	s11,24(sp)
ffffffffc020400e:	6109                	addi	sp,sp,128
ffffffffc0204010:	8082                	ret
            padc = '0';
ffffffffc0204012:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0204014:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204018:	846a                	mv	s0,s10
ffffffffc020401a:	00140d13          	addi	s10,s0,1
ffffffffc020401e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0204022:	0ff5f593          	zext.b	a1,a1
ffffffffc0204026:	fcb572e3          	bgeu	a0,a1,ffffffffc0203fea <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020402a:	85a6                	mv	a1,s1
ffffffffc020402c:	02500513          	li	a0,37
ffffffffc0204030:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0204032:	fff44783          	lbu	a5,-1(s0)
ffffffffc0204036:	8d22                	mv	s10,s0
ffffffffc0204038:	f73788e3          	beq	a5,s3,ffffffffc0203fa8 <vprintfmt+0x3a>
ffffffffc020403c:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0204040:	1d7d                	addi	s10,s10,-1
ffffffffc0204042:	ff379de3          	bne	a5,s3,ffffffffc020403c <vprintfmt+0xce>
ffffffffc0204046:	b78d                	j	ffffffffc0203fa8 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0204048:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020404c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204050:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0204052:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0204056:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020405a:	02d86463          	bltu	a6,a3,ffffffffc0204082 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020405e:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0204062:	002c169b          	slliw	a3,s8,0x2
ffffffffc0204066:	0186873b          	addw	a4,a3,s8
ffffffffc020406a:	0017171b          	slliw	a4,a4,0x1
ffffffffc020406e:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0204070:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0204074:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0204076:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc020407a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020407e:	fed870e3          	bgeu	a6,a3,ffffffffc020405e <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0204082:	f40ddce3          	bgez	s11,ffffffffc0203fda <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0204086:	8de2                	mv	s11,s8
ffffffffc0204088:	5c7d                	li	s8,-1
ffffffffc020408a:	bf81                	j	ffffffffc0203fda <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020408c:	fffdc693          	not	a3,s11
ffffffffc0204090:	96fd                	srai	a3,a3,0x3f
ffffffffc0204092:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204096:	00144603          	lbu	a2,1(s0)
ffffffffc020409a:	2d81                	sext.w	s11,s11
ffffffffc020409c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020409e:	bf35                	j	ffffffffc0203fda <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02040a0:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02040a4:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02040a8:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02040aa:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02040ac:	bfd9                	j	ffffffffc0204082 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02040ae:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02040b0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02040b4:	01174463          	blt	a4,a7,ffffffffc02040bc <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02040b8:	1a088e63          	beqz	a7,ffffffffc0204274 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02040bc:	000a3603          	ld	a2,0(s4)
ffffffffc02040c0:	46c1                	li	a3,16
ffffffffc02040c2:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02040c4:	2781                	sext.w	a5,a5
ffffffffc02040c6:	876e                	mv	a4,s11
ffffffffc02040c8:	85a6                	mv	a1,s1
ffffffffc02040ca:	854a                	mv	a0,s2
ffffffffc02040cc:	e37ff0ef          	jal	ra,ffffffffc0203f02 <printnum>
            break;
ffffffffc02040d0:	bde1                	j	ffffffffc0203fa8 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02040d2:	000a2503          	lw	a0,0(s4)
ffffffffc02040d6:	85a6                	mv	a1,s1
ffffffffc02040d8:	0a21                	addi	s4,s4,8
ffffffffc02040da:	9902                	jalr	s2
            break;
ffffffffc02040dc:	b5f1                	j	ffffffffc0203fa8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02040de:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02040e0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02040e4:	01174463          	blt	a4,a7,ffffffffc02040ec <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02040e8:	18088163          	beqz	a7,ffffffffc020426a <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02040ec:	000a3603          	ld	a2,0(s4)
ffffffffc02040f0:	46a9                	li	a3,10
ffffffffc02040f2:	8a2e                	mv	s4,a1
ffffffffc02040f4:	bfc1                	j	ffffffffc02040c4 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02040f6:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02040fa:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02040fc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02040fe:	bdf1                	j	ffffffffc0203fda <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0204100:	85a6                	mv	a1,s1
ffffffffc0204102:	02500513          	li	a0,37
ffffffffc0204106:	9902                	jalr	s2
            break;
ffffffffc0204108:	b545                	j	ffffffffc0203fa8 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020410a:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020410e:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204110:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204112:	b5e1                	j	ffffffffc0203fda <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0204114:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204116:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020411a:	01174463          	blt	a4,a7,ffffffffc0204122 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020411e:	14088163          	beqz	a7,ffffffffc0204260 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0204122:	000a3603          	ld	a2,0(s4)
ffffffffc0204126:	46a1                	li	a3,8
ffffffffc0204128:	8a2e                	mv	s4,a1
ffffffffc020412a:	bf69                	j	ffffffffc02040c4 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020412c:	03000513          	li	a0,48
ffffffffc0204130:	85a6                	mv	a1,s1
ffffffffc0204132:	e03e                	sd	a5,0(sp)
ffffffffc0204134:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0204136:	85a6                	mv	a1,s1
ffffffffc0204138:	07800513          	li	a0,120
ffffffffc020413c:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020413e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0204140:	6782                	ld	a5,0(sp)
ffffffffc0204142:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204144:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0204148:	bfb5                	j	ffffffffc02040c4 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020414a:	000a3403          	ld	s0,0(s4)
ffffffffc020414e:	008a0713          	addi	a4,s4,8
ffffffffc0204152:	e03a                	sd	a4,0(sp)
ffffffffc0204154:	14040263          	beqz	s0,ffffffffc0204298 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0204158:	0fb05763          	blez	s11,ffffffffc0204246 <vprintfmt+0x2d8>
ffffffffc020415c:	02d00693          	li	a3,45
ffffffffc0204160:	0cd79163          	bne	a5,a3,ffffffffc0204222 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204164:	00044783          	lbu	a5,0(s0)
ffffffffc0204168:	0007851b          	sext.w	a0,a5
ffffffffc020416c:	cf85                	beqz	a5,ffffffffc02041a4 <vprintfmt+0x236>
ffffffffc020416e:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204172:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204176:	000c4563          	bltz	s8,ffffffffc0204180 <vprintfmt+0x212>
ffffffffc020417a:	3c7d                	addiw	s8,s8,-1
ffffffffc020417c:	036c0263          	beq	s8,s6,ffffffffc02041a0 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0204180:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204182:	0e0c8e63          	beqz	s9,ffffffffc020427e <vprintfmt+0x310>
ffffffffc0204186:	3781                	addiw	a5,a5,-32
ffffffffc0204188:	0ef47b63          	bgeu	s0,a5,ffffffffc020427e <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020418c:	03f00513          	li	a0,63
ffffffffc0204190:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204192:	000a4783          	lbu	a5,0(s4)
ffffffffc0204196:	3dfd                	addiw	s11,s11,-1
ffffffffc0204198:	0a05                	addi	s4,s4,1
ffffffffc020419a:	0007851b          	sext.w	a0,a5
ffffffffc020419e:	ffe1                	bnez	a5,ffffffffc0204176 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02041a0:	01b05963          	blez	s11,ffffffffc02041b2 <vprintfmt+0x244>
ffffffffc02041a4:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02041a6:	85a6                	mv	a1,s1
ffffffffc02041a8:	02000513          	li	a0,32
ffffffffc02041ac:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02041ae:	fe0d9be3          	bnez	s11,ffffffffc02041a4 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02041b2:	6a02                	ld	s4,0(sp)
ffffffffc02041b4:	bbd5                	j	ffffffffc0203fa8 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02041b6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02041b8:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02041bc:	01174463          	blt	a4,a7,ffffffffc02041c4 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02041c0:	08088d63          	beqz	a7,ffffffffc020425a <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02041c4:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02041c8:	0a044d63          	bltz	s0,ffffffffc0204282 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02041cc:	8622                	mv	a2,s0
ffffffffc02041ce:	8a66                	mv	s4,s9
ffffffffc02041d0:	46a9                	li	a3,10
ffffffffc02041d2:	bdcd                	j	ffffffffc02040c4 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02041d4:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02041d8:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02041da:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02041dc:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02041e0:	8fb5                	xor	a5,a5,a3
ffffffffc02041e2:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02041e6:	02d74163          	blt	a4,a3,ffffffffc0204208 <vprintfmt+0x29a>
ffffffffc02041ea:	00369793          	slli	a5,a3,0x3
ffffffffc02041ee:	97de                	add	a5,a5,s7
ffffffffc02041f0:	639c                	ld	a5,0(a5)
ffffffffc02041f2:	cb99                	beqz	a5,ffffffffc0204208 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02041f4:	86be                	mv	a3,a5
ffffffffc02041f6:	00002617          	auipc	a2,0x2
ffffffffc02041fa:	d6a60613          	addi	a2,a2,-662 # ffffffffc0205f60 <default_pmm_manager+0x768>
ffffffffc02041fe:	85a6                	mv	a1,s1
ffffffffc0204200:	854a                	mv	a0,s2
ffffffffc0204202:	0ce000ef          	jal	ra,ffffffffc02042d0 <printfmt>
ffffffffc0204206:	b34d                	j	ffffffffc0203fa8 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0204208:	00002617          	auipc	a2,0x2
ffffffffc020420c:	d4860613          	addi	a2,a2,-696 # ffffffffc0205f50 <default_pmm_manager+0x758>
ffffffffc0204210:	85a6                	mv	a1,s1
ffffffffc0204212:	854a                	mv	a0,s2
ffffffffc0204214:	0bc000ef          	jal	ra,ffffffffc02042d0 <printfmt>
ffffffffc0204218:	bb41                	j	ffffffffc0203fa8 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020421a:	00002417          	auipc	s0,0x2
ffffffffc020421e:	d2e40413          	addi	s0,s0,-722 # ffffffffc0205f48 <default_pmm_manager+0x750>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204222:	85e2                	mv	a1,s8
ffffffffc0204224:	8522                	mv	a0,s0
ffffffffc0204226:	e43e                	sd	a5,8(sp)
ffffffffc0204228:	c4fff0ef          	jal	ra,ffffffffc0203e76 <strnlen>
ffffffffc020422c:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0204230:	01b05b63          	blez	s11,ffffffffc0204246 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0204234:	67a2                	ld	a5,8(sp)
ffffffffc0204236:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020423a:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020423c:	85a6                	mv	a1,s1
ffffffffc020423e:	8552                	mv	a0,s4
ffffffffc0204240:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204242:	fe0d9ce3          	bnez	s11,ffffffffc020423a <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204246:	00044783          	lbu	a5,0(s0)
ffffffffc020424a:	00140a13          	addi	s4,s0,1
ffffffffc020424e:	0007851b          	sext.w	a0,a5
ffffffffc0204252:	d3a5                	beqz	a5,ffffffffc02041b2 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204254:	05e00413          	li	s0,94
ffffffffc0204258:	bf39                	j	ffffffffc0204176 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc020425a:	000a2403          	lw	s0,0(s4)
ffffffffc020425e:	b7ad                	j	ffffffffc02041c8 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0204260:	000a6603          	lwu	a2,0(s4)
ffffffffc0204264:	46a1                	li	a3,8
ffffffffc0204266:	8a2e                	mv	s4,a1
ffffffffc0204268:	bdb1                	j	ffffffffc02040c4 <vprintfmt+0x156>
ffffffffc020426a:	000a6603          	lwu	a2,0(s4)
ffffffffc020426e:	46a9                	li	a3,10
ffffffffc0204270:	8a2e                	mv	s4,a1
ffffffffc0204272:	bd89                	j	ffffffffc02040c4 <vprintfmt+0x156>
ffffffffc0204274:	000a6603          	lwu	a2,0(s4)
ffffffffc0204278:	46c1                	li	a3,16
ffffffffc020427a:	8a2e                	mv	s4,a1
ffffffffc020427c:	b5a1                	j	ffffffffc02040c4 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020427e:	9902                	jalr	s2
ffffffffc0204280:	bf09                	j	ffffffffc0204192 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0204282:	85a6                	mv	a1,s1
ffffffffc0204284:	02d00513          	li	a0,45
ffffffffc0204288:	e03e                	sd	a5,0(sp)
ffffffffc020428a:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020428c:	6782                	ld	a5,0(sp)
ffffffffc020428e:	8a66                	mv	s4,s9
ffffffffc0204290:	40800633          	neg	a2,s0
ffffffffc0204294:	46a9                	li	a3,10
ffffffffc0204296:	b53d                	j	ffffffffc02040c4 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0204298:	03b05163          	blez	s11,ffffffffc02042ba <vprintfmt+0x34c>
ffffffffc020429c:	02d00693          	li	a3,45
ffffffffc02042a0:	f6d79de3          	bne	a5,a3,ffffffffc020421a <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02042a4:	00002417          	auipc	s0,0x2
ffffffffc02042a8:	ca440413          	addi	s0,s0,-860 # ffffffffc0205f48 <default_pmm_manager+0x750>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02042ac:	02800793          	li	a5,40
ffffffffc02042b0:	02800513          	li	a0,40
ffffffffc02042b4:	00140a13          	addi	s4,s0,1
ffffffffc02042b8:	bd6d                	j	ffffffffc0204172 <vprintfmt+0x204>
ffffffffc02042ba:	00002a17          	auipc	s4,0x2
ffffffffc02042be:	c8fa0a13          	addi	s4,s4,-881 # ffffffffc0205f49 <default_pmm_manager+0x751>
ffffffffc02042c2:	02800513          	li	a0,40
ffffffffc02042c6:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02042ca:	05e00413          	li	s0,94
ffffffffc02042ce:	b565                	j	ffffffffc0204176 <vprintfmt+0x208>

ffffffffc02042d0 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02042d0:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02042d2:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02042d6:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02042d8:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02042da:	ec06                	sd	ra,24(sp)
ffffffffc02042dc:	f83a                	sd	a4,48(sp)
ffffffffc02042de:	fc3e                	sd	a5,56(sp)
ffffffffc02042e0:	e0c2                	sd	a6,64(sp)
ffffffffc02042e2:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02042e4:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02042e6:	c89ff0ef          	jal	ra,ffffffffc0203f6e <vprintfmt>
}
ffffffffc02042ea:	60e2                	ld	ra,24(sp)
ffffffffc02042ec:	6161                	addi	sp,sp,80
ffffffffc02042ee:	8082                	ret

ffffffffc02042f0 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02042f0:	715d                	addi	sp,sp,-80
ffffffffc02042f2:	e486                	sd	ra,72(sp)
ffffffffc02042f4:	e0a6                	sd	s1,64(sp)
ffffffffc02042f6:	fc4a                	sd	s2,56(sp)
ffffffffc02042f8:	f84e                	sd	s3,48(sp)
ffffffffc02042fa:	f452                	sd	s4,40(sp)
ffffffffc02042fc:	f056                	sd	s5,32(sp)
ffffffffc02042fe:	ec5a                	sd	s6,24(sp)
ffffffffc0204300:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0204302:	c901                	beqz	a0,ffffffffc0204312 <readline+0x22>
ffffffffc0204304:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0204306:	00002517          	auipc	a0,0x2
ffffffffc020430a:	c5a50513          	addi	a0,a0,-934 # ffffffffc0205f60 <default_pmm_manager+0x768>
ffffffffc020430e:	dadfb0ef          	jal	ra,ffffffffc02000ba <cprintf>
readline(const char *prompt) {
ffffffffc0204312:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204314:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0204316:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0204318:	4aa9                	li	s5,10
ffffffffc020431a:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc020431c:	0000db97          	auipc	s7,0xd
ffffffffc0204320:	ddcb8b93          	addi	s7,s7,-548 # ffffffffc02110f8 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204324:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0204328:	dcbfb0ef          	jal	ra,ffffffffc02000f2 <getchar>
        if (c < 0) {
ffffffffc020432c:	00054a63          	bltz	a0,ffffffffc0204340 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204330:	00a95a63          	bge	s2,a0,ffffffffc0204344 <readline+0x54>
ffffffffc0204334:	029a5263          	bge	s4,s1,ffffffffc0204358 <readline+0x68>
        c = getchar();
ffffffffc0204338:	dbbfb0ef          	jal	ra,ffffffffc02000f2 <getchar>
        if (c < 0) {
ffffffffc020433c:	fe055ae3          	bgez	a0,ffffffffc0204330 <readline+0x40>
            return NULL;
ffffffffc0204340:	4501                	li	a0,0
ffffffffc0204342:	a091                	j	ffffffffc0204386 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0204344:	03351463          	bne	a0,s3,ffffffffc020436c <readline+0x7c>
ffffffffc0204348:	e8a9                	bnez	s1,ffffffffc020439a <readline+0xaa>
        c = getchar();
ffffffffc020434a:	da9fb0ef          	jal	ra,ffffffffc02000f2 <getchar>
        if (c < 0) {
ffffffffc020434e:	fe0549e3          	bltz	a0,ffffffffc0204340 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0204352:	fea959e3          	bge	s2,a0,ffffffffc0204344 <readline+0x54>
ffffffffc0204356:	4481                	li	s1,0
            cputchar(c);
ffffffffc0204358:	e42a                	sd	a0,8(sp)
ffffffffc020435a:	d97fb0ef          	jal	ra,ffffffffc02000f0 <cputchar>
            buf[i ++] = c;
ffffffffc020435e:	6522                	ld	a0,8(sp)
ffffffffc0204360:	009b87b3          	add	a5,s7,s1
ffffffffc0204364:	2485                	addiw	s1,s1,1
ffffffffc0204366:	00a78023          	sb	a0,0(a5)
ffffffffc020436a:	bf7d                	j	ffffffffc0204328 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc020436c:	01550463          	beq	a0,s5,ffffffffc0204374 <readline+0x84>
ffffffffc0204370:	fb651ce3          	bne	a0,s6,ffffffffc0204328 <readline+0x38>
            cputchar(c);
ffffffffc0204374:	d7dfb0ef          	jal	ra,ffffffffc02000f0 <cputchar>
            buf[i] = '\0';
ffffffffc0204378:	0000d517          	auipc	a0,0xd
ffffffffc020437c:	d8050513          	addi	a0,a0,-640 # ffffffffc02110f8 <buf>
ffffffffc0204380:	94aa                	add	s1,s1,a0
ffffffffc0204382:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0204386:	60a6                	ld	ra,72(sp)
ffffffffc0204388:	6486                	ld	s1,64(sp)
ffffffffc020438a:	7962                	ld	s2,56(sp)
ffffffffc020438c:	79c2                	ld	s3,48(sp)
ffffffffc020438e:	7a22                	ld	s4,40(sp)
ffffffffc0204390:	7a82                	ld	s5,32(sp)
ffffffffc0204392:	6b62                	ld	s6,24(sp)
ffffffffc0204394:	6bc2                	ld	s7,16(sp)
ffffffffc0204396:	6161                	addi	sp,sp,80
ffffffffc0204398:	8082                	ret
            cputchar(c);
ffffffffc020439a:	4521                	li	a0,8
ffffffffc020439c:	d55fb0ef          	jal	ra,ffffffffc02000f0 <cputchar>
            i --;
ffffffffc02043a0:	34fd                	addiw	s1,s1,-1
ffffffffc02043a2:	b759                	j	ffffffffc0204328 <readline+0x38>

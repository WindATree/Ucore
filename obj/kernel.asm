
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    #a代表段是可访问的（allocatable），x代表段是可执行的（executable）
    #progbits：指示符，告诉汇编器这个段包含的是程序的正文（code），而不是其他类型的内容，如符号表或字符串表。
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02052b7          	lui	t0,0xc0205
    #%hi：伪操作，用于获取一个符号的高位部分。地址是64位的，%hi会获取符号地址的高位。
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号,because page offset is 12 bit
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    #t1=1000....0000
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
ffffffffc0200024:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	03228293          	addi	t0,t0,50 # ffffffffc0200032 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <kern_init>:
void grade_backtrace(void);


int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	00006517          	auipc	a0,0x6
ffffffffc0200036:	fde50513          	addi	a0,a0,-34 # ffffffffc0206010 <free_area>
ffffffffc020003a:	00006617          	auipc	a2,0x6
ffffffffc020003e:	43e60613          	addi	a2,a2,1086 # ffffffffc0206478 <end>
int kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
int kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	574010ef          	jal	ra,ffffffffc02015be <memset>
    cons_init();  // init the console
ffffffffc020004e:	3fc000ef          	jal	ra,ffffffffc020044a <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00002517          	auipc	a0,0x2
ffffffffc0200056:	a7650513          	addi	a0,a0,-1418 # ffffffffc0201ac8 <etext+0x6>
ffffffffc020005a:	090000ef          	jal	ra,ffffffffc02000ea <cputs>

    print_kerninfo();
ffffffffc020005e:	138000ef          	jal	ra,ffffffffc0200196 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200062:	402000ef          	jal	ra,ffffffffc0200464 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc0200066:	053000ef          	jal	ra,ffffffffc02008b8 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc020006a:	3fa000ef          	jal	ra,ffffffffc0200464 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc020006e:	39a000ef          	jal	ra,ffffffffc0200408 <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200072:	3e6000ef          	jal	ra,ffffffffc0200458 <intr_enable>



    /* do nothing */
    while (1)
ffffffffc0200076:	a001                	j	ffffffffc0200076 <kern_init+0x44>

ffffffffc0200078 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200078:	1141                	addi	sp,sp,-16
ffffffffc020007a:	e022                	sd	s0,0(sp)
ffffffffc020007c:	e406                	sd	ra,8(sp)
ffffffffc020007e:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200080:	3cc000ef          	jal	ra,ffffffffc020044c <cons_putc>
    (*cnt) ++;
ffffffffc0200084:	401c                	lw	a5,0(s0)
}
ffffffffc0200086:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200088:	2785                	addiw	a5,a5,1
ffffffffc020008a:	c01c                	sw	a5,0(s0)
}
ffffffffc020008c:	6402                	ld	s0,0(sp)
ffffffffc020008e:	0141                	addi	sp,sp,16
ffffffffc0200090:	8082                	ret

ffffffffc0200092 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200092:	1101                	addi	sp,sp,-32
ffffffffc0200094:	862a                	mv	a2,a0
ffffffffc0200096:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200098:	00000517          	auipc	a0,0x0
ffffffffc020009c:	fe050513          	addi	a0,a0,-32 # ffffffffc0200078 <cputch>
ffffffffc02000a0:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000a2:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000a4:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000a6:	596010ef          	jal	ra,ffffffffc020163c <vprintfmt>
    return cnt;
}
ffffffffc02000aa:	60e2                	ld	ra,24(sp)
ffffffffc02000ac:	4532                	lw	a0,12(sp)
ffffffffc02000ae:	6105                	addi	sp,sp,32
ffffffffc02000b0:	8082                	ret

ffffffffc02000b2 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000b2:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000b4:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000b8:	8e2a                	mv	t3,a0
ffffffffc02000ba:	f42e                	sd	a1,40(sp)
ffffffffc02000bc:	f832                	sd	a2,48(sp)
ffffffffc02000be:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c0:	00000517          	auipc	a0,0x0
ffffffffc02000c4:	fb850513          	addi	a0,a0,-72 # ffffffffc0200078 <cputch>
ffffffffc02000c8:	004c                	addi	a1,sp,4
ffffffffc02000ca:	869a                	mv	a3,t1
ffffffffc02000cc:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000ce:	ec06                	sd	ra,24(sp)
ffffffffc02000d0:	e0ba                	sd	a4,64(sp)
ffffffffc02000d2:	e4be                	sd	a5,72(sp)
ffffffffc02000d4:	e8c2                	sd	a6,80(sp)
ffffffffc02000d6:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000d8:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000da:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000dc:	560010ef          	jal	ra,ffffffffc020163c <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000e0:	60e2                	ld	ra,24(sp)
ffffffffc02000e2:	4512                	lw	a0,4(sp)
ffffffffc02000e4:	6125                	addi	sp,sp,96
ffffffffc02000e6:	8082                	ret

ffffffffc02000e8 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02000e8:	a695                	j	ffffffffc020044c <cons_putc>

ffffffffc02000ea <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02000ea:	1101                	addi	sp,sp,-32
ffffffffc02000ec:	e822                	sd	s0,16(sp)
ffffffffc02000ee:	ec06                	sd	ra,24(sp)
ffffffffc02000f0:	e426                	sd	s1,8(sp)
ffffffffc02000f2:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02000f4:	00054503          	lbu	a0,0(a0)
ffffffffc02000f8:	c51d                	beqz	a0,ffffffffc0200126 <cputs+0x3c>
ffffffffc02000fa:	0405                	addi	s0,s0,1
ffffffffc02000fc:	4485                	li	s1,1
ffffffffc02000fe:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200100:	34c000ef          	jal	ra,ffffffffc020044c <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200104:	00044503          	lbu	a0,0(s0)
ffffffffc0200108:	008487bb          	addw	a5,s1,s0
ffffffffc020010c:	0405                	addi	s0,s0,1
ffffffffc020010e:	f96d                	bnez	a0,ffffffffc0200100 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200110:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200114:	4529                	li	a0,10
ffffffffc0200116:	336000ef          	jal	ra,ffffffffc020044c <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc020011a:	60e2                	ld	ra,24(sp)
ffffffffc020011c:	8522                	mv	a0,s0
ffffffffc020011e:	6442                	ld	s0,16(sp)
ffffffffc0200120:	64a2                	ld	s1,8(sp)
ffffffffc0200122:	6105                	addi	sp,sp,32
ffffffffc0200124:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200126:	4405                	li	s0,1
ffffffffc0200128:	b7f5                	j	ffffffffc0200114 <cputs+0x2a>

ffffffffc020012a <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc020012a:	1141                	addi	sp,sp,-16
ffffffffc020012c:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020012e:	326000ef          	jal	ra,ffffffffc0200454 <cons_getc>
ffffffffc0200132:	dd75                	beqz	a0,ffffffffc020012e <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200134:	60a2                	ld	ra,8(sp)
ffffffffc0200136:	0141                	addi	sp,sp,16
ffffffffc0200138:	8082                	ret

ffffffffc020013a <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc020013a:	00006317          	auipc	t1,0x6
ffffffffc020013e:	2ee30313          	addi	t1,t1,750 # ffffffffc0206428 <is_panic>
ffffffffc0200142:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200146:	715d                	addi	sp,sp,-80
ffffffffc0200148:	ec06                	sd	ra,24(sp)
ffffffffc020014a:	e822                	sd	s0,16(sp)
ffffffffc020014c:	f436                	sd	a3,40(sp)
ffffffffc020014e:	f83a                	sd	a4,48(sp)
ffffffffc0200150:	fc3e                	sd	a5,56(sp)
ffffffffc0200152:	e0c2                	sd	a6,64(sp)
ffffffffc0200154:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200156:	020e1a63          	bnez	t3,ffffffffc020018a <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc020015a:	4785                	li	a5,1
ffffffffc020015c:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200160:	8432                	mv	s0,a2
ffffffffc0200162:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200164:	862e                	mv	a2,a1
ffffffffc0200166:	85aa                	mv	a1,a0
ffffffffc0200168:	00002517          	auipc	a0,0x2
ffffffffc020016c:	98050513          	addi	a0,a0,-1664 # ffffffffc0201ae8 <etext+0x26>
    va_start(ap, fmt);
ffffffffc0200170:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200172:	f41ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200176:	65a2                	ld	a1,8(sp)
ffffffffc0200178:	8522                	mv	a0,s0
ffffffffc020017a:	f19ff0ef          	jal	ra,ffffffffc0200092 <vcprintf>
    cprintf("\n");
ffffffffc020017e:	00002517          	auipc	a0,0x2
ffffffffc0200182:	a5250513          	addi	a0,a0,-1454 # ffffffffc0201bd0 <etext+0x10e>
ffffffffc0200186:	f2dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc020018a:	2d4000ef          	jal	ra,ffffffffc020045e <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020018e:	4501                	li	a0,0
ffffffffc0200190:	130000ef          	jal	ra,ffffffffc02002c0 <kmonitor>
    while (1) {
ffffffffc0200194:	bfed                	j	ffffffffc020018e <__panic+0x54>

ffffffffc0200196 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200196:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200198:	00002517          	auipc	a0,0x2
ffffffffc020019c:	97050513          	addi	a0,a0,-1680 # ffffffffc0201b08 <etext+0x46>
void print_kerninfo(void) {
ffffffffc02001a0:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001a2:	f11ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc02001a6:	00000597          	auipc	a1,0x0
ffffffffc02001aa:	e8c58593          	addi	a1,a1,-372 # ffffffffc0200032 <kern_init>
ffffffffc02001ae:	00002517          	auipc	a0,0x2
ffffffffc02001b2:	97a50513          	addi	a0,a0,-1670 # ffffffffc0201b28 <etext+0x66>
ffffffffc02001b6:	efdff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02001ba:	00002597          	auipc	a1,0x2
ffffffffc02001be:	90858593          	addi	a1,a1,-1784 # ffffffffc0201ac2 <etext>
ffffffffc02001c2:	00002517          	auipc	a0,0x2
ffffffffc02001c6:	98650513          	addi	a0,a0,-1658 # ffffffffc0201b48 <etext+0x86>
ffffffffc02001ca:	ee9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001ce:	00006597          	auipc	a1,0x6
ffffffffc02001d2:	e4258593          	addi	a1,a1,-446 # ffffffffc0206010 <free_area>
ffffffffc02001d6:	00002517          	auipc	a0,0x2
ffffffffc02001da:	99250513          	addi	a0,a0,-1646 # ffffffffc0201b68 <etext+0xa6>
ffffffffc02001de:	ed5ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001e2:	00006597          	auipc	a1,0x6
ffffffffc02001e6:	29658593          	addi	a1,a1,662 # ffffffffc0206478 <end>
ffffffffc02001ea:	00002517          	auipc	a0,0x2
ffffffffc02001ee:	99e50513          	addi	a0,a0,-1634 # ffffffffc0201b88 <etext+0xc6>
ffffffffc02001f2:	ec1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001f6:	00006597          	auipc	a1,0x6
ffffffffc02001fa:	68158593          	addi	a1,a1,1665 # ffffffffc0206877 <end+0x3ff>
ffffffffc02001fe:	00000797          	auipc	a5,0x0
ffffffffc0200202:	e3478793          	addi	a5,a5,-460 # ffffffffc0200032 <kern_init>
ffffffffc0200206:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020020a:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020020e:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200210:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200214:	95be                	add	a1,a1,a5
ffffffffc0200216:	85a9                	srai	a1,a1,0xa
ffffffffc0200218:	00002517          	auipc	a0,0x2
ffffffffc020021c:	99050513          	addi	a0,a0,-1648 # ffffffffc0201ba8 <etext+0xe6>
}
ffffffffc0200220:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200222:	bd41                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200224 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200224:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc0200226:	00002617          	auipc	a2,0x2
ffffffffc020022a:	9b260613          	addi	a2,a2,-1614 # ffffffffc0201bd8 <etext+0x116>
ffffffffc020022e:	04e00593          	li	a1,78
ffffffffc0200232:	00002517          	auipc	a0,0x2
ffffffffc0200236:	9be50513          	addi	a0,a0,-1602 # ffffffffc0201bf0 <etext+0x12e>
void print_stackframe(void) {
ffffffffc020023a:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020023c:	effff0ef          	jal	ra,ffffffffc020013a <__panic>

ffffffffc0200240 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200240:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200242:	00002617          	auipc	a2,0x2
ffffffffc0200246:	9c660613          	addi	a2,a2,-1594 # ffffffffc0201c08 <etext+0x146>
ffffffffc020024a:	00002597          	auipc	a1,0x2
ffffffffc020024e:	9de58593          	addi	a1,a1,-1570 # ffffffffc0201c28 <etext+0x166>
ffffffffc0200252:	00002517          	auipc	a0,0x2
ffffffffc0200256:	9de50513          	addi	a0,a0,-1570 # ffffffffc0201c30 <etext+0x16e>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025a:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020025c:	e57ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200260:	00002617          	auipc	a2,0x2
ffffffffc0200264:	9e060613          	addi	a2,a2,-1568 # ffffffffc0201c40 <etext+0x17e>
ffffffffc0200268:	00002597          	auipc	a1,0x2
ffffffffc020026c:	a0058593          	addi	a1,a1,-1536 # ffffffffc0201c68 <etext+0x1a6>
ffffffffc0200270:	00002517          	auipc	a0,0x2
ffffffffc0200274:	9c050513          	addi	a0,a0,-1600 # ffffffffc0201c30 <etext+0x16e>
ffffffffc0200278:	e3bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020027c:	00002617          	auipc	a2,0x2
ffffffffc0200280:	9fc60613          	addi	a2,a2,-1540 # ffffffffc0201c78 <etext+0x1b6>
ffffffffc0200284:	00002597          	auipc	a1,0x2
ffffffffc0200288:	a1458593          	addi	a1,a1,-1516 # ffffffffc0201c98 <etext+0x1d6>
ffffffffc020028c:	00002517          	auipc	a0,0x2
ffffffffc0200290:	9a450513          	addi	a0,a0,-1628 # ffffffffc0201c30 <etext+0x16e>
ffffffffc0200294:	e1fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    }
    return 0;
}
ffffffffc0200298:	60a2                	ld	ra,8(sp)
ffffffffc020029a:	4501                	li	a0,0
ffffffffc020029c:	0141                	addi	sp,sp,16
ffffffffc020029e:	8082                	ret

ffffffffc02002a0 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002a0:	1141                	addi	sp,sp,-16
ffffffffc02002a2:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02002a4:	ef3ff0ef          	jal	ra,ffffffffc0200196 <print_kerninfo>
    return 0;
}
ffffffffc02002a8:	60a2                	ld	ra,8(sp)
ffffffffc02002aa:	4501                	li	a0,0
ffffffffc02002ac:	0141                	addi	sp,sp,16
ffffffffc02002ae:	8082                	ret

ffffffffc02002b0 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002b0:	1141                	addi	sp,sp,-16
ffffffffc02002b2:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02002b4:	f71ff0ef          	jal	ra,ffffffffc0200224 <print_stackframe>
    return 0;
}
ffffffffc02002b8:	60a2                	ld	ra,8(sp)
ffffffffc02002ba:	4501                	li	a0,0
ffffffffc02002bc:	0141                	addi	sp,sp,16
ffffffffc02002be:	8082                	ret

ffffffffc02002c0 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02002c0:	7115                	addi	sp,sp,-224
ffffffffc02002c2:	ed5e                	sd	s7,152(sp)
ffffffffc02002c4:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002c6:	00002517          	auipc	a0,0x2
ffffffffc02002ca:	9e250513          	addi	a0,a0,-1566 # ffffffffc0201ca8 <etext+0x1e6>
kmonitor(struct trapframe *tf) {
ffffffffc02002ce:	ed86                	sd	ra,216(sp)
ffffffffc02002d0:	e9a2                	sd	s0,208(sp)
ffffffffc02002d2:	e5a6                	sd	s1,200(sp)
ffffffffc02002d4:	e1ca                	sd	s2,192(sp)
ffffffffc02002d6:	fd4e                	sd	s3,184(sp)
ffffffffc02002d8:	f952                	sd	s4,176(sp)
ffffffffc02002da:	f556                	sd	s5,168(sp)
ffffffffc02002dc:	f15a                	sd	s6,160(sp)
ffffffffc02002de:	e962                	sd	s8,144(sp)
ffffffffc02002e0:	e566                	sd	s9,136(sp)
ffffffffc02002e2:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002e4:	dcfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002e8:	00002517          	auipc	a0,0x2
ffffffffc02002ec:	9e850513          	addi	a0,a0,-1560 # ffffffffc0201cd0 <etext+0x20e>
ffffffffc02002f0:	dc3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (tf != NULL) {
ffffffffc02002f4:	000b8563          	beqz	s7,ffffffffc02002fe <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002f8:	855e                	mv	a0,s7
ffffffffc02002fa:	348000ef          	jal	ra,ffffffffc0200642 <print_trapframe>
ffffffffc02002fe:	00002c17          	auipc	s8,0x2
ffffffffc0200302:	a42c0c13          	addi	s8,s8,-1470 # ffffffffc0201d40 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200306:	00002917          	auipc	s2,0x2
ffffffffc020030a:	9f290913          	addi	s2,s2,-1550 # ffffffffc0201cf8 <etext+0x236>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020030e:	00002497          	auipc	s1,0x2
ffffffffc0200312:	9f248493          	addi	s1,s1,-1550 # ffffffffc0201d00 <etext+0x23e>
        if (argc == MAXARGS - 1) {
ffffffffc0200316:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200318:	00002b17          	auipc	s6,0x2
ffffffffc020031c:	9f0b0b13          	addi	s6,s6,-1552 # ffffffffc0201d08 <etext+0x246>
        argv[argc ++] = buf;
ffffffffc0200320:	00002a17          	auipc	s4,0x2
ffffffffc0200324:	908a0a13          	addi	s4,s4,-1784 # ffffffffc0201c28 <etext+0x166>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200328:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020032a:	854a                	mv	a0,s2
ffffffffc020032c:	692010ef          	jal	ra,ffffffffc02019be <readline>
ffffffffc0200330:	842a                	mv	s0,a0
ffffffffc0200332:	dd65                	beqz	a0,ffffffffc020032a <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200334:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200338:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020033a:	e1bd                	bnez	a1,ffffffffc02003a0 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc020033c:	fe0c87e3          	beqz	s9,ffffffffc020032a <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200340:	6582                	ld	a1,0(sp)
ffffffffc0200342:	00002d17          	auipc	s10,0x2
ffffffffc0200346:	9fed0d13          	addi	s10,s10,-1538 # ffffffffc0201d40 <commands>
        argv[argc ++] = buf;
ffffffffc020034a:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020034c:	4401                	li	s0,0
ffffffffc020034e:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200350:	23a010ef          	jal	ra,ffffffffc020158a <strcmp>
ffffffffc0200354:	c919                	beqz	a0,ffffffffc020036a <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200356:	2405                	addiw	s0,s0,1
ffffffffc0200358:	0b540063          	beq	s0,s5,ffffffffc02003f8 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020035c:	000d3503          	ld	a0,0(s10)
ffffffffc0200360:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200362:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200364:	226010ef          	jal	ra,ffffffffc020158a <strcmp>
ffffffffc0200368:	f57d                	bnez	a0,ffffffffc0200356 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020036a:	00141793          	slli	a5,s0,0x1
ffffffffc020036e:	97a2                	add	a5,a5,s0
ffffffffc0200370:	078e                	slli	a5,a5,0x3
ffffffffc0200372:	97e2                	add	a5,a5,s8
ffffffffc0200374:	6b9c                	ld	a5,16(a5)
ffffffffc0200376:	865e                	mv	a2,s7
ffffffffc0200378:	002c                	addi	a1,sp,8
ffffffffc020037a:	fffc851b          	addiw	a0,s9,-1
ffffffffc020037e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200380:	fa0555e3          	bgez	a0,ffffffffc020032a <kmonitor+0x6a>
}
ffffffffc0200384:	60ee                	ld	ra,216(sp)
ffffffffc0200386:	644e                	ld	s0,208(sp)
ffffffffc0200388:	64ae                	ld	s1,200(sp)
ffffffffc020038a:	690e                	ld	s2,192(sp)
ffffffffc020038c:	79ea                	ld	s3,184(sp)
ffffffffc020038e:	7a4a                	ld	s4,176(sp)
ffffffffc0200390:	7aaa                	ld	s5,168(sp)
ffffffffc0200392:	7b0a                	ld	s6,160(sp)
ffffffffc0200394:	6bea                	ld	s7,152(sp)
ffffffffc0200396:	6c4a                	ld	s8,144(sp)
ffffffffc0200398:	6caa                	ld	s9,136(sp)
ffffffffc020039a:	6d0a                	ld	s10,128(sp)
ffffffffc020039c:	612d                	addi	sp,sp,224
ffffffffc020039e:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003a0:	8526                	mv	a0,s1
ffffffffc02003a2:	206010ef          	jal	ra,ffffffffc02015a8 <strchr>
ffffffffc02003a6:	c901                	beqz	a0,ffffffffc02003b6 <kmonitor+0xf6>
ffffffffc02003a8:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02003ac:	00040023          	sb	zero,0(s0)
ffffffffc02003b0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b2:	d5c9                	beqz	a1,ffffffffc020033c <kmonitor+0x7c>
ffffffffc02003b4:	b7f5                	j	ffffffffc02003a0 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc02003b6:	00044783          	lbu	a5,0(s0)
ffffffffc02003ba:	d3c9                	beqz	a5,ffffffffc020033c <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc02003bc:	033c8963          	beq	s9,s3,ffffffffc02003ee <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc02003c0:	003c9793          	slli	a5,s9,0x3
ffffffffc02003c4:	0118                	addi	a4,sp,128
ffffffffc02003c6:	97ba                	add	a5,a5,a4
ffffffffc02003c8:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003cc:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02003d0:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003d2:	e591                	bnez	a1,ffffffffc02003de <kmonitor+0x11e>
ffffffffc02003d4:	b7b5                	j	ffffffffc0200340 <kmonitor+0x80>
ffffffffc02003d6:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003da:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003dc:	d1a5                	beqz	a1,ffffffffc020033c <kmonitor+0x7c>
ffffffffc02003de:	8526                	mv	a0,s1
ffffffffc02003e0:	1c8010ef          	jal	ra,ffffffffc02015a8 <strchr>
ffffffffc02003e4:	d96d                	beqz	a0,ffffffffc02003d6 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003e6:	00044583          	lbu	a1,0(s0)
ffffffffc02003ea:	d9a9                	beqz	a1,ffffffffc020033c <kmonitor+0x7c>
ffffffffc02003ec:	bf55                	j	ffffffffc02003a0 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003ee:	45c1                	li	a1,16
ffffffffc02003f0:	855a                	mv	a0,s6
ffffffffc02003f2:	cc1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc02003f6:	b7e9                	j	ffffffffc02003c0 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003f8:	6582                	ld	a1,0(sp)
ffffffffc02003fa:	00002517          	auipc	a0,0x2
ffffffffc02003fe:	92e50513          	addi	a0,a0,-1746 # ffffffffc0201d28 <etext+0x266>
ffffffffc0200402:	cb1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    return 0;
ffffffffc0200406:	b715                	j	ffffffffc020032a <kmonitor+0x6a>

ffffffffc0200408 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200408:	1141                	addi	sp,sp,-16
ffffffffc020040a:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc020040c:	02000793          	li	a5,32
ffffffffc0200410:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200414:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200418:	67e1                	lui	a5,0x18
ffffffffc020041a:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020041e:	953e                	add	a0,a0,a5
ffffffffc0200420:	66c010ef          	jal	ra,ffffffffc0201a8c <sbi_set_timer>
}
ffffffffc0200424:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200426:	00006797          	auipc	a5,0x6
ffffffffc020042a:	0007b523          	sd	zero,10(a5) # ffffffffc0206430 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020042e:	00002517          	auipc	a0,0x2
ffffffffc0200432:	95a50513          	addi	a0,a0,-1702 # ffffffffc0201d88 <commands+0x48>
}
ffffffffc0200436:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200438:	b9ad                	j	ffffffffc02000b2 <cprintf>

ffffffffc020043a <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043a:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043e:	67e1                	lui	a5,0x18
ffffffffc0200440:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200444:	953e                	add	a0,a0,a5
ffffffffc0200446:	6460106f          	j	ffffffffc0201a8c <sbi_set_timer>

ffffffffc020044a <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020044a:	8082                	ret

ffffffffc020044c <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020044c:	0ff57513          	zext.b	a0,a0
ffffffffc0200450:	6220106f          	j	ffffffffc0201a72 <sbi_console_putchar>

ffffffffc0200454 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200454:	6520106f          	j	ffffffffc0201aa6 <sbi_console_getchar>

ffffffffc0200458 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200458:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc020045c:	8082                	ret

ffffffffc020045e <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020045e:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200462:	8082                	ret

ffffffffc0200464 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200464:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200468:	00000797          	auipc	a5,0x0
ffffffffc020046c:	2e478793          	addi	a5,a5,740 # ffffffffc020074c <__alltraps>
ffffffffc0200470:	10579073          	csrw	stvec,a5
}
ffffffffc0200474:	8082                	ret

ffffffffc0200476 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200476:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200478:	1141                	addi	sp,sp,-16
ffffffffc020047a:	e022                	sd	s0,0(sp)
ffffffffc020047c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020047e:	00002517          	auipc	a0,0x2
ffffffffc0200482:	92a50513          	addi	a0,a0,-1750 # ffffffffc0201da8 <commands+0x68>
void print_regs(struct pushregs *gpr) {
ffffffffc0200486:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200488:	c2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020048c:	640c                	ld	a1,8(s0)
ffffffffc020048e:	00002517          	auipc	a0,0x2
ffffffffc0200492:	93250513          	addi	a0,a0,-1742 # ffffffffc0201dc0 <commands+0x80>
ffffffffc0200496:	c1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020049a:	680c                	ld	a1,16(s0)
ffffffffc020049c:	00002517          	auipc	a0,0x2
ffffffffc02004a0:	93c50513          	addi	a0,a0,-1732 # ffffffffc0201dd8 <commands+0x98>
ffffffffc02004a4:	c0fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004a8:	6c0c                	ld	a1,24(s0)
ffffffffc02004aa:	00002517          	auipc	a0,0x2
ffffffffc02004ae:	94650513          	addi	a0,a0,-1722 # ffffffffc0201df0 <commands+0xb0>
ffffffffc02004b2:	c01ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004b6:	700c                	ld	a1,32(s0)
ffffffffc02004b8:	00002517          	auipc	a0,0x2
ffffffffc02004bc:	95050513          	addi	a0,a0,-1712 # ffffffffc0201e08 <commands+0xc8>
ffffffffc02004c0:	bf3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004c4:	740c                	ld	a1,40(s0)
ffffffffc02004c6:	00002517          	auipc	a0,0x2
ffffffffc02004ca:	95a50513          	addi	a0,a0,-1702 # ffffffffc0201e20 <commands+0xe0>
ffffffffc02004ce:	be5ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d2:	780c                	ld	a1,48(s0)
ffffffffc02004d4:	00002517          	auipc	a0,0x2
ffffffffc02004d8:	96450513          	addi	a0,a0,-1692 # ffffffffc0201e38 <commands+0xf8>
ffffffffc02004dc:	bd7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e0:	7c0c                	ld	a1,56(s0)
ffffffffc02004e2:	00002517          	auipc	a0,0x2
ffffffffc02004e6:	96e50513          	addi	a0,a0,-1682 # ffffffffc0201e50 <commands+0x110>
ffffffffc02004ea:	bc9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004ee:	602c                	ld	a1,64(s0)
ffffffffc02004f0:	00002517          	auipc	a0,0x2
ffffffffc02004f4:	97850513          	addi	a0,a0,-1672 # ffffffffc0201e68 <commands+0x128>
ffffffffc02004f8:	bbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02004fc:	642c                	ld	a1,72(s0)
ffffffffc02004fe:	00002517          	auipc	a0,0x2
ffffffffc0200502:	98250513          	addi	a0,a0,-1662 # ffffffffc0201e80 <commands+0x140>
ffffffffc0200506:	badff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020050a:	682c                	ld	a1,80(s0)
ffffffffc020050c:	00002517          	auipc	a0,0x2
ffffffffc0200510:	98c50513          	addi	a0,a0,-1652 # ffffffffc0201e98 <commands+0x158>
ffffffffc0200514:	b9fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200518:	6c2c                	ld	a1,88(s0)
ffffffffc020051a:	00002517          	auipc	a0,0x2
ffffffffc020051e:	99650513          	addi	a0,a0,-1642 # ffffffffc0201eb0 <commands+0x170>
ffffffffc0200522:	b91ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200526:	702c                	ld	a1,96(s0)
ffffffffc0200528:	00002517          	auipc	a0,0x2
ffffffffc020052c:	9a050513          	addi	a0,a0,-1632 # ffffffffc0201ec8 <commands+0x188>
ffffffffc0200530:	b83ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200534:	742c                	ld	a1,104(s0)
ffffffffc0200536:	00002517          	auipc	a0,0x2
ffffffffc020053a:	9aa50513          	addi	a0,a0,-1622 # ffffffffc0201ee0 <commands+0x1a0>
ffffffffc020053e:	b75ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200542:	782c                	ld	a1,112(s0)
ffffffffc0200544:	00002517          	auipc	a0,0x2
ffffffffc0200548:	9b450513          	addi	a0,a0,-1612 # ffffffffc0201ef8 <commands+0x1b8>
ffffffffc020054c:	b67ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200550:	7c2c                	ld	a1,120(s0)
ffffffffc0200552:	00002517          	auipc	a0,0x2
ffffffffc0200556:	9be50513          	addi	a0,a0,-1602 # ffffffffc0201f10 <commands+0x1d0>
ffffffffc020055a:	b59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020055e:	604c                	ld	a1,128(s0)
ffffffffc0200560:	00002517          	auipc	a0,0x2
ffffffffc0200564:	9c850513          	addi	a0,a0,-1592 # ffffffffc0201f28 <commands+0x1e8>
ffffffffc0200568:	b4bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020056c:	644c                	ld	a1,136(s0)
ffffffffc020056e:	00002517          	auipc	a0,0x2
ffffffffc0200572:	9d250513          	addi	a0,a0,-1582 # ffffffffc0201f40 <commands+0x200>
ffffffffc0200576:	b3dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020057a:	684c                	ld	a1,144(s0)
ffffffffc020057c:	00002517          	auipc	a0,0x2
ffffffffc0200580:	9dc50513          	addi	a0,a0,-1572 # ffffffffc0201f58 <commands+0x218>
ffffffffc0200584:	b2fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200588:	6c4c                	ld	a1,152(s0)
ffffffffc020058a:	00002517          	auipc	a0,0x2
ffffffffc020058e:	9e650513          	addi	a0,a0,-1562 # ffffffffc0201f70 <commands+0x230>
ffffffffc0200592:	b21ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200596:	704c                	ld	a1,160(s0)
ffffffffc0200598:	00002517          	auipc	a0,0x2
ffffffffc020059c:	9f050513          	addi	a0,a0,-1552 # ffffffffc0201f88 <commands+0x248>
ffffffffc02005a0:	b13ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005a4:	744c                	ld	a1,168(s0)
ffffffffc02005a6:	00002517          	auipc	a0,0x2
ffffffffc02005aa:	9fa50513          	addi	a0,a0,-1542 # ffffffffc0201fa0 <commands+0x260>
ffffffffc02005ae:	b05ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b2:	784c                	ld	a1,176(s0)
ffffffffc02005b4:	00002517          	auipc	a0,0x2
ffffffffc02005b8:	a0450513          	addi	a0,a0,-1532 # ffffffffc0201fb8 <commands+0x278>
ffffffffc02005bc:	af7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c0:	7c4c                	ld	a1,184(s0)
ffffffffc02005c2:	00002517          	auipc	a0,0x2
ffffffffc02005c6:	a0e50513          	addi	a0,a0,-1522 # ffffffffc0201fd0 <commands+0x290>
ffffffffc02005ca:	ae9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005ce:	606c                	ld	a1,192(s0)
ffffffffc02005d0:	00002517          	auipc	a0,0x2
ffffffffc02005d4:	a1850513          	addi	a0,a0,-1512 # ffffffffc0201fe8 <commands+0x2a8>
ffffffffc02005d8:	adbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005dc:	646c                	ld	a1,200(s0)
ffffffffc02005de:	00002517          	auipc	a0,0x2
ffffffffc02005e2:	a2250513          	addi	a0,a0,-1502 # ffffffffc0202000 <commands+0x2c0>
ffffffffc02005e6:	acdff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005ea:	686c                	ld	a1,208(s0)
ffffffffc02005ec:	00002517          	auipc	a0,0x2
ffffffffc02005f0:	a2c50513          	addi	a0,a0,-1492 # ffffffffc0202018 <commands+0x2d8>
ffffffffc02005f4:	abfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005f8:	6c6c                	ld	a1,216(s0)
ffffffffc02005fa:	00002517          	auipc	a0,0x2
ffffffffc02005fe:	a3650513          	addi	a0,a0,-1482 # ffffffffc0202030 <commands+0x2f0>
ffffffffc0200602:	ab1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200606:	706c                	ld	a1,224(s0)
ffffffffc0200608:	00002517          	auipc	a0,0x2
ffffffffc020060c:	a4050513          	addi	a0,a0,-1472 # ffffffffc0202048 <commands+0x308>
ffffffffc0200610:	aa3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200614:	746c                	ld	a1,232(s0)
ffffffffc0200616:	00002517          	auipc	a0,0x2
ffffffffc020061a:	a4a50513          	addi	a0,a0,-1462 # ffffffffc0202060 <commands+0x320>
ffffffffc020061e:	a95ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200622:	786c                	ld	a1,240(s0)
ffffffffc0200624:	00002517          	auipc	a0,0x2
ffffffffc0200628:	a5450513          	addi	a0,a0,-1452 # ffffffffc0202078 <commands+0x338>
ffffffffc020062c:	a87ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200630:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200632:	6402                	ld	s0,0(sp)
ffffffffc0200634:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	00002517          	auipc	a0,0x2
ffffffffc020063a:	a5a50513          	addi	a0,a0,-1446 # ffffffffc0202090 <commands+0x350>
}
ffffffffc020063e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200640:	bc8d                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200642 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200642:	1141                	addi	sp,sp,-16
ffffffffc0200644:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200646:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200648:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc020064a:	00002517          	auipc	a0,0x2
ffffffffc020064e:	a5e50513          	addi	a0,a0,-1442 # ffffffffc02020a8 <commands+0x368>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200652:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200654:	a5fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200658:	8522                	mv	a0,s0
ffffffffc020065a:	e1dff0ef          	jal	ra,ffffffffc0200476 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020065e:	10043583          	ld	a1,256(s0)
ffffffffc0200662:	00002517          	auipc	a0,0x2
ffffffffc0200666:	a5e50513          	addi	a0,a0,-1442 # ffffffffc02020c0 <commands+0x380>
ffffffffc020066a:	a49ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020066e:	10843583          	ld	a1,264(s0)
ffffffffc0200672:	00002517          	auipc	a0,0x2
ffffffffc0200676:	a6650513          	addi	a0,a0,-1434 # ffffffffc02020d8 <commands+0x398>
ffffffffc020067a:	a39ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020067e:	11043583          	ld	a1,272(s0)
ffffffffc0200682:	00002517          	auipc	a0,0x2
ffffffffc0200686:	a6e50513          	addi	a0,a0,-1426 # ffffffffc02020f0 <commands+0x3b0>
ffffffffc020068a:	a29ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020068e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200692:	6402                	ld	s0,0(sp)
ffffffffc0200694:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	00002517          	auipc	a0,0x2
ffffffffc020069a:	a7250513          	addi	a0,a0,-1422 # ffffffffc0202108 <commands+0x3c8>
}
ffffffffc020069e:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006a0:	bc09                	j	ffffffffc02000b2 <cprintf>

ffffffffc02006a2 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02006a2:	11853783          	ld	a5,280(a0)
ffffffffc02006a6:	472d                	li	a4,11
ffffffffc02006a8:	0786                	slli	a5,a5,0x1
ffffffffc02006aa:	8385                	srli	a5,a5,0x1
ffffffffc02006ac:	06f76c63          	bltu	a4,a5,ffffffffc0200724 <interrupt_handler+0x82>
ffffffffc02006b0:	00002717          	auipc	a4,0x2
ffffffffc02006b4:	b3870713          	addi	a4,a4,-1224 # ffffffffc02021e8 <commands+0x4a8>
ffffffffc02006b8:	078a                	slli	a5,a5,0x2
ffffffffc02006ba:	97ba                	add	a5,a5,a4
ffffffffc02006bc:	439c                	lw	a5,0(a5)
ffffffffc02006be:	97ba                	add	a5,a5,a4
ffffffffc02006c0:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02006c2:	00002517          	auipc	a0,0x2
ffffffffc02006c6:	abe50513          	addi	a0,a0,-1346 # ffffffffc0202180 <commands+0x440>
ffffffffc02006ca:	b2e5                	j	ffffffffc02000b2 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006cc:	00002517          	auipc	a0,0x2
ffffffffc02006d0:	a9450513          	addi	a0,a0,-1388 # ffffffffc0202160 <commands+0x420>
ffffffffc02006d4:	baf9                	j	ffffffffc02000b2 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006d6:	00002517          	auipc	a0,0x2
ffffffffc02006da:	a4a50513          	addi	a0,a0,-1462 # ffffffffc0202120 <commands+0x3e0>
ffffffffc02006de:	bad1                	j	ffffffffc02000b2 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006e0:	00002517          	auipc	a0,0x2
ffffffffc02006e4:	ac050513          	addi	a0,a0,-1344 # ffffffffc02021a0 <commands+0x460>
ffffffffc02006e8:	b2e9                	j	ffffffffc02000b2 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02006ea:	1141                	addi	sp,sp,-16
ffffffffc02006ec:	e406                	sd	ra,8(sp)
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            // "sip寄存器中除了SSIP和USIP之外的所有位都是只读的。" 
	    // 实际上，调用sbi_set_timer函数将会清除STIP,或者你可以直接清除它。
            clock_set_next_event();
ffffffffc02006ee:	d4dff0ef          	jal	ra,ffffffffc020043a <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02006f2:	00006697          	auipc	a3,0x6
ffffffffc02006f6:	d3e68693          	addi	a3,a3,-706 # ffffffffc0206430 <ticks>
ffffffffc02006fa:	629c                	ld	a5,0(a3)
ffffffffc02006fc:	06400713          	li	a4,100
ffffffffc0200700:	0785                	addi	a5,a5,1
ffffffffc0200702:	02e7f733          	remu	a4,a5,a4
ffffffffc0200706:	e29c                	sd	a5,0(a3)
ffffffffc0200708:	cf19                	beqz	a4,ffffffffc0200726 <interrupt_handler+0x84>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc020070a:	60a2                	ld	ra,8(sp)
ffffffffc020070c:	0141                	addi	sp,sp,16
ffffffffc020070e:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200710:	00002517          	auipc	a0,0x2
ffffffffc0200714:	ab850513          	addi	a0,a0,-1352 # ffffffffc02021c8 <commands+0x488>
ffffffffc0200718:	ba69                	j	ffffffffc02000b2 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc020071a:	00002517          	auipc	a0,0x2
ffffffffc020071e:	a2650513          	addi	a0,a0,-1498 # ffffffffc0202140 <commands+0x400>
ffffffffc0200722:	ba41                	j	ffffffffc02000b2 <cprintf>
            print_trapframe(tf);
ffffffffc0200724:	bf39                	j	ffffffffc0200642 <print_trapframe>
}
ffffffffc0200726:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200728:	06400593          	li	a1,100
ffffffffc020072c:	00002517          	auipc	a0,0x2
ffffffffc0200730:	a8c50513          	addi	a0,a0,-1396 # ffffffffc02021b8 <commands+0x478>
}
ffffffffc0200734:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200736:	bab5                	j	ffffffffc02000b2 <cprintf>

ffffffffc0200738 <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200738:	11853783          	ld	a5,280(a0)
ffffffffc020073c:	0007c763          	bltz	a5,ffffffffc020074a <trap+0x12>
    switch (tf->cause) {
ffffffffc0200740:	472d                	li	a4,11
ffffffffc0200742:	00f76363          	bltu	a4,a5,ffffffffc0200748 <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200746:	8082                	ret
            print_trapframe(tf);
ffffffffc0200748:	bded                	j	ffffffffc0200642 <print_trapframe>
        interrupt_handler(tf);
ffffffffc020074a:	bfa1                	j	ffffffffc02006a2 <interrupt_handler>

ffffffffc020074c <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc020074c:	14011073          	csrw	sscratch,sp
ffffffffc0200750:	712d                	addi	sp,sp,-288
ffffffffc0200752:	e002                	sd	zero,0(sp)
ffffffffc0200754:	e406                	sd	ra,8(sp)
ffffffffc0200756:	ec0e                	sd	gp,24(sp)
ffffffffc0200758:	f012                	sd	tp,32(sp)
ffffffffc020075a:	f416                	sd	t0,40(sp)
ffffffffc020075c:	f81a                	sd	t1,48(sp)
ffffffffc020075e:	fc1e                	sd	t2,56(sp)
ffffffffc0200760:	e0a2                	sd	s0,64(sp)
ffffffffc0200762:	e4a6                	sd	s1,72(sp)
ffffffffc0200764:	e8aa                	sd	a0,80(sp)
ffffffffc0200766:	ecae                	sd	a1,88(sp)
ffffffffc0200768:	f0b2                	sd	a2,96(sp)
ffffffffc020076a:	f4b6                	sd	a3,104(sp)
ffffffffc020076c:	f8ba                	sd	a4,112(sp)
ffffffffc020076e:	fcbe                	sd	a5,120(sp)
ffffffffc0200770:	e142                	sd	a6,128(sp)
ffffffffc0200772:	e546                	sd	a7,136(sp)
ffffffffc0200774:	e94a                	sd	s2,144(sp)
ffffffffc0200776:	ed4e                	sd	s3,152(sp)
ffffffffc0200778:	f152                	sd	s4,160(sp)
ffffffffc020077a:	f556                	sd	s5,168(sp)
ffffffffc020077c:	f95a                	sd	s6,176(sp)
ffffffffc020077e:	fd5e                	sd	s7,184(sp)
ffffffffc0200780:	e1e2                	sd	s8,192(sp)
ffffffffc0200782:	e5e6                	sd	s9,200(sp)
ffffffffc0200784:	e9ea                	sd	s10,208(sp)
ffffffffc0200786:	edee                	sd	s11,216(sp)
ffffffffc0200788:	f1f2                	sd	t3,224(sp)
ffffffffc020078a:	f5f6                	sd	t4,232(sp)
ffffffffc020078c:	f9fa                	sd	t5,240(sp)
ffffffffc020078e:	fdfe                	sd	t6,248(sp)
ffffffffc0200790:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200794:	100024f3          	csrr	s1,sstatus
ffffffffc0200798:	14102973          	csrr	s2,sepc
ffffffffc020079c:	143029f3          	csrr	s3,stval
ffffffffc02007a0:	14202a73          	csrr	s4,scause
ffffffffc02007a4:	e822                	sd	s0,16(sp)
ffffffffc02007a6:	e226                	sd	s1,256(sp)
ffffffffc02007a8:	e64a                	sd	s2,264(sp)
ffffffffc02007aa:	ea4e                	sd	s3,272(sp)
ffffffffc02007ac:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc02007ae:	850a                	mv	a0,sp
    jal trap
ffffffffc02007b0:	f89ff0ef          	jal	ra,ffffffffc0200738 <trap>

ffffffffc02007b4 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc02007b4:	6492                	ld	s1,256(sp)
ffffffffc02007b6:	6932                	ld	s2,264(sp)
ffffffffc02007b8:	10049073          	csrw	sstatus,s1
ffffffffc02007bc:	14191073          	csrw	sepc,s2
ffffffffc02007c0:	60a2                	ld	ra,8(sp)
ffffffffc02007c2:	61e2                	ld	gp,24(sp)
ffffffffc02007c4:	7202                	ld	tp,32(sp)
ffffffffc02007c6:	72a2                	ld	t0,40(sp)
ffffffffc02007c8:	7342                	ld	t1,48(sp)
ffffffffc02007ca:	73e2                	ld	t2,56(sp)
ffffffffc02007cc:	6406                	ld	s0,64(sp)
ffffffffc02007ce:	64a6                	ld	s1,72(sp)
ffffffffc02007d0:	6546                	ld	a0,80(sp)
ffffffffc02007d2:	65e6                	ld	a1,88(sp)
ffffffffc02007d4:	7606                	ld	a2,96(sp)
ffffffffc02007d6:	76a6                	ld	a3,104(sp)
ffffffffc02007d8:	7746                	ld	a4,112(sp)
ffffffffc02007da:	77e6                	ld	a5,120(sp)
ffffffffc02007dc:	680a                	ld	a6,128(sp)
ffffffffc02007de:	68aa                	ld	a7,136(sp)
ffffffffc02007e0:	694a                	ld	s2,144(sp)
ffffffffc02007e2:	69ea                	ld	s3,152(sp)
ffffffffc02007e4:	7a0a                	ld	s4,160(sp)
ffffffffc02007e6:	7aaa                	ld	s5,168(sp)
ffffffffc02007e8:	7b4a                	ld	s6,176(sp)
ffffffffc02007ea:	7bea                	ld	s7,184(sp)
ffffffffc02007ec:	6c0e                	ld	s8,192(sp)
ffffffffc02007ee:	6cae                	ld	s9,200(sp)
ffffffffc02007f0:	6d4e                	ld	s10,208(sp)
ffffffffc02007f2:	6dee                	ld	s11,216(sp)
ffffffffc02007f4:	7e0e                	ld	t3,224(sp)
ffffffffc02007f6:	7eae                	ld	t4,232(sp)
ffffffffc02007f8:	7f4e                	ld	t5,240(sp)
ffffffffc02007fa:	7fee                	ld	t6,248(sp)
ffffffffc02007fc:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc02007fe:	10200073          	sret

ffffffffc0200802 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200802:	100027f3          	csrr	a5,sstatus
ffffffffc0200806:	8b89                	andi	a5,a5,2
ffffffffc0200808:	e799                	bnez	a5,ffffffffc0200816 <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc020080a:	00006797          	auipc	a5,0x6
ffffffffc020080e:	c467b783          	ld	a5,-954(a5) # ffffffffc0206450 <pmm_manager>
ffffffffc0200812:	6f9c                	ld	a5,24(a5)
ffffffffc0200814:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0200816:	1141                	addi	sp,sp,-16
ffffffffc0200818:	e406                	sd	ra,8(sp)
ffffffffc020081a:	e022                	sd	s0,0(sp)
ffffffffc020081c:	842a                	mv	s0,a0
        intr_disable();
ffffffffc020081e:	c41ff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200822:	00006797          	auipc	a5,0x6
ffffffffc0200826:	c2e7b783          	ld	a5,-978(a5) # ffffffffc0206450 <pmm_manager>
ffffffffc020082a:	6f9c                	ld	a5,24(a5)
ffffffffc020082c:	8522                	mv	a0,s0
ffffffffc020082e:	9782                	jalr	a5
ffffffffc0200830:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0200832:	c27ff0ef          	jal	ra,ffffffffc0200458 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0200836:	60a2                	ld	ra,8(sp)
ffffffffc0200838:	8522                	mv	a0,s0
ffffffffc020083a:	6402                	ld	s0,0(sp)
ffffffffc020083c:	0141                	addi	sp,sp,16
ffffffffc020083e:	8082                	ret

ffffffffc0200840 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200840:	100027f3          	csrr	a5,sstatus
ffffffffc0200844:	8b89                	andi	a5,a5,2
ffffffffc0200846:	e799                	bnez	a5,ffffffffc0200854 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200848:	00006797          	auipc	a5,0x6
ffffffffc020084c:	c087b783          	ld	a5,-1016(a5) # ffffffffc0206450 <pmm_manager>
ffffffffc0200850:	739c                	ld	a5,32(a5)
ffffffffc0200852:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0200854:	1101                	addi	sp,sp,-32
ffffffffc0200856:	ec06                	sd	ra,24(sp)
ffffffffc0200858:	e822                	sd	s0,16(sp)
ffffffffc020085a:	e426                	sd	s1,8(sp)
ffffffffc020085c:	842a                	mv	s0,a0
ffffffffc020085e:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200860:	bffff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200864:	00006797          	auipc	a5,0x6
ffffffffc0200868:	bec7b783          	ld	a5,-1044(a5) # ffffffffc0206450 <pmm_manager>
ffffffffc020086c:	739c                	ld	a5,32(a5)
ffffffffc020086e:	85a6                	mv	a1,s1
ffffffffc0200870:	8522                	mv	a0,s0
ffffffffc0200872:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200874:	6442                	ld	s0,16(sp)
ffffffffc0200876:	60e2                	ld	ra,24(sp)
ffffffffc0200878:	64a2                	ld	s1,8(sp)
ffffffffc020087a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020087c:	bef1                	j	ffffffffc0200458 <intr_enable>

ffffffffc020087e <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020087e:	100027f3          	csrr	a5,sstatus
ffffffffc0200882:	8b89                	andi	a5,a5,2
ffffffffc0200884:	e799                	bnez	a5,ffffffffc0200892 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200886:	00006797          	auipc	a5,0x6
ffffffffc020088a:	bca7b783          	ld	a5,-1078(a5) # ffffffffc0206450 <pmm_manager>
ffffffffc020088e:	779c                	ld	a5,40(a5)
ffffffffc0200890:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0200892:	1141                	addi	sp,sp,-16
ffffffffc0200894:	e406                	sd	ra,8(sp)
ffffffffc0200896:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200898:	bc7ff0ef          	jal	ra,ffffffffc020045e <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020089c:	00006797          	auipc	a5,0x6
ffffffffc02008a0:	bb47b783          	ld	a5,-1100(a5) # ffffffffc0206450 <pmm_manager>
ffffffffc02008a4:	779c                	ld	a5,40(a5)
ffffffffc02008a6:	9782                	jalr	a5
ffffffffc02008a8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02008aa:	bafff0ef          	jal	ra,ffffffffc0200458 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02008ae:	60a2                	ld	ra,8(sp)
ffffffffc02008b0:	8522                	mv	a0,s0
ffffffffc02008b2:	6402                	ld	s0,0(sp)
ffffffffc02008b4:	0141                	addi	sp,sp,16
ffffffffc02008b6:	8082                	ret

ffffffffc02008b8 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02008b8:	00002797          	auipc	a5,0x2
ffffffffc02008bc:	e8078793          	addi	a5,a5,-384 # ffffffffc0202738 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02008c0:	638c                	ld	a1,0(a5)
        fppn=pa2page(mem_begin)-pages+nbase;
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02008c2:	715d                	addi	sp,sp,-80
ffffffffc02008c4:	f44e                	sd	s3,40(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02008c6:	00002517          	auipc	a0,0x2
ffffffffc02008ca:	95250513          	addi	a0,a0,-1710 # ffffffffc0202218 <commands+0x4d8>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02008ce:	00006997          	auipc	s3,0x6
ffffffffc02008d2:	b8298993          	addi	s3,s3,-1150 # ffffffffc0206450 <pmm_manager>
void pmm_init(void) {
ffffffffc02008d6:	e486                	sd	ra,72(sp)
ffffffffc02008d8:	e0a2                	sd	s0,64(sp)
ffffffffc02008da:	f84a                	sd	s2,48(sp)
ffffffffc02008dc:	ec56                	sd	s5,24(sp)
ffffffffc02008de:	e85a                	sd	s6,16(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02008e0:	00f9b023          	sd	a5,0(s3)
void pmm_init(void) {
ffffffffc02008e4:	fc26                	sd	s1,56(sp)
ffffffffc02008e6:	f052                	sd	s4,32(sp)
ffffffffc02008e8:	e45e                	sd	s7,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02008ea:	fc8ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pmm_manager->init();
ffffffffc02008ee:	0009b783          	ld	a5,0(s3)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02008f2:	00006917          	auipc	s2,0x6
ffffffffc02008f6:	b7690913          	addi	s2,s2,-1162 # ffffffffc0206468 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc02008fa:	00006a97          	auipc	s5,0x6
ffffffffc02008fe:	b46a8a93          	addi	s5,s5,-1210 # ffffffffc0206440 <npage>
    pmm_manager->init();
ffffffffc0200902:	679c                	ld	a5,8(a5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200904:	00006417          	auipc	s0,0x6
ffffffffc0200908:	b4440413          	addi	s0,s0,-1212 # ffffffffc0206448 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020090c:	fff80b37          	lui	s6,0xfff80
    pmm_manager->init();
ffffffffc0200910:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200912:	57f5                	li	a5,-3
ffffffffc0200914:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0200916:	00002517          	auipc	a0,0x2
ffffffffc020091a:	91a50513          	addi	a0,a0,-1766 # ffffffffc0202230 <commands+0x4f0>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020091e:	00f93023          	sd	a5,0(s2)
    cprintf("physcial memory map:\n");
ffffffffc0200922:	f90ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200926:	46c5                	li	a3,17
ffffffffc0200928:	06ee                	slli	a3,a3,0x1b
ffffffffc020092a:	40100613          	li	a2,1025
ffffffffc020092e:	16fd                	addi	a3,a3,-1
ffffffffc0200930:	07e005b7          	lui	a1,0x7e00
ffffffffc0200934:	0656                	slli	a2,a2,0x15
ffffffffc0200936:	00002517          	auipc	a0,0x2
ffffffffc020093a:	91250513          	addi	a0,a0,-1774 # ffffffffc0202248 <commands+0x508>
ffffffffc020093e:	f74ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200942:	777d                	lui	a4,0xfffff
ffffffffc0200944:	00007797          	auipc	a5,0x7
ffffffffc0200948:	b3378793          	addi	a5,a5,-1229 # ffffffffc0207477 <end+0xfff>
ffffffffc020094c:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc020094e:	00088737          	lui	a4,0x88
ffffffffc0200952:	00eab023          	sd	a4,0(s5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200956:	00006597          	auipc	a1,0x6
ffffffffc020095a:	b2258593          	addi	a1,a1,-1246 # ffffffffc0206478 <end>
ffffffffc020095e:	e01c                	sd	a5,0(s0)
ffffffffc0200960:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200962:	4701                	li	a4,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200964:	4505                	li	a0,1
ffffffffc0200966:	a011                	j	ffffffffc020096a <pmm_init+0xb2>
        SetPageReserved(pages + i);
ffffffffc0200968:	601c                	ld	a5,0(s0)
ffffffffc020096a:	97b6                	add	a5,a5,a3
ffffffffc020096c:	07a1                	addi	a5,a5,8
ffffffffc020096e:	40a7b02f          	amoor.d	zero,a0,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200972:	000ab783          	ld	a5,0(s5)
ffffffffc0200976:	0705                	addi	a4,a4,1
ffffffffc0200978:	04868693          	addi	a3,a3,72
ffffffffc020097c:	01678633          	add	a2,a5,s6
ffffffffc0200980:	fec764e3          	bltu	a4,a2,ffffffffc0200968 <pmm_init+0xb0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200984:	6004                	ld	s1,0(s0)
ffffffffc0200986:	00379693          	slli	a3,a5,0x3
ffffffffc020098a:	97b6                	add	a5,a5,a3
ffffffffc020098c:	fdc006b7          	lui	a3,0xfdc00
ffffffffc0200990:	94b6                	add	s1,s1,a3
ffffffffc0200992:	078e                	slli	a5,a5,0x3
ffffffffc0200994:	94be                	add	s1,s1,a5
ffffffffc0200996:	c0200bb7          	lui	s7,0xc0200
ffffffffc020099a:	1974ea63          	bltu	s1,s7,ffffffffc0200b2e <pmm_init+0x276>
ffffffffc020099e:	00093783          	ld	a5,0(s2)
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02009a2:	6a05                	lui	s4,0x1
ffffffffc02009a4:	1a7d                	addi	s4,s4,-1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02009a6:	8c9d                	sub	s1,s1,a5
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02009a8:	9a26                	add	s4,s4,s1
ffffffffc02009aa:	777d                	lui	a4,0xfffff
ffffffffc02009ac:	00ea7a33          	and	s4,s4,a4
    cprintf("kern_end:  0x%016lx\n", (uint64_t)PADDR(end));
ffffffffc02009b0:	1575ef63          	bltu	a1,s7,ffffffffc0200b0e <pmm_init+0x256>
ffffffffc02009b4:	8d9d                	sub	a1,a1,a5
ffffffffc02009b6:	00002517          	auipc	a0,0x2
ffffffffc02009ba:	8fa50513          	addi	a0,a0,-1798 # ffffffffc02022b0 <commands+0x570>
ffffffffc02009be:	ef4ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("pages:     0x%016lx\n", (uint64_t)PADDR(pages));
ffffffffc02009c2:	6014                	ld	a3,0(s0)
ffffffffc02009c4:	1376e963          	bltu	a3,s7,ffffffffc0200af6 <pmm_init+0x23e>
ffffffffc02009c8:	00093583          	ld	a1,0(s2)
ffffffffc02009cc:	00002517          	auipc	a0,0x2
ffffffffc02009d0:	8fc50513          	addi	a0,a0,-1796 # ffffffffc02022c8 <commands+0x588>
    cprintf("mem_end:   0x%016lx\n", mem_end);
ffffffffc02009d4:	4bc5                	li	s7,17
    cprintf("pages:     0x%016lx\n", (uint64_t)PADDR(pages));
ffffffffc02009d6:	40b685b3          	sub	a1,a3,a1
ffffffffc02009da:	ed8ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("freemem:   0x%016lx\n", freemem);
ffffffffc02009de:	85a6                	mv	a1,s1
ffffffffc02009e0:	00002517          	auipc	a0,0x2
ffffffffc02009e4:	90050513          	addi	a0,a0,-1792 # ffffffffc02022e0 <commands+0x5a0>
ffffffffc02009e8:	ecaff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("mem_begin: 0x%016lx\n", mem_begin);
ffffffffc02009ec:	85d2                	mv	a1,s4
ffffffffc02009ee:	00002517          	auipc	a0,0x2
ffffffffc02009f2:	90a50513          	addi	a0,a0,-1782 # ffffffffc02022f8 <commands+0x5b8>
ffffffffc02009f6:	ebcff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("mem_end:   0x%016lx\n", mem_end);
ffffffffc02009fa:	01bb9593          	slli	a1,s7,0x1b
    if (freemem < mem_end) {
ffffffffc02009fe:	8bae                	mv	s7,a1
    cprintf("mem_end:   0x%016lx\n", mem_end);
ffffffffc0200a00:	00002517          	auipc	a0,0x2
ffffffffc0200a04:	91050513          	addi	a0,a0,-1776 # ffffffffc0202310 <commands+0x5d0>
ffffffffc0200a08:	eaaff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (freemem < mem_end) {
ffffffffc0200a0c:	0774e063          	bltu	s1,s7,ffffffffc0200a6c <pmm_init+0x1b4>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200a10:	0009b783          	ld	a5,0(s3)
ffffffffc0200a14:	63bc                	ld	a5,64(a5)
ffffffffc0200a16:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200a18:	00002517          	auipc	a0,0x2
ffffffffc0200a1c:	97850513          	addi	a0,a0,-1672 # ffffffffc0202390 <commands+0x650>
ffffffffc0200a20:	e92ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200a24:	00004597          	auipc	a1,0x4
ffffffffc0200a28:	5dc58593          	addi	a1,a1,1500 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0200a2c:	00006797          	auipc	a5,0x6
ffffffffc0200a30:	a2b7ba23          	sd	a1,-1484(a5) # ffffffffc0206460 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200a34:	c02007b7          	lui	a5,0xc0200
ffffffffc0200a38:	10f5e863          	bltu	a1,a5,ffffffffc0200b48 <pmm_init+0x290>
ffffffffc0200a3c:	00093603          	ld	a2,0(s2)
}
ffffffffc0200a40:	6406                	ld	s0,64(sp)
ffffffffc0200a42:	60a6                	ld	ra,72(sp)
ffffffffc0200a44:	74e2                	ld	s1,56(sp)
ffffffffc0200a46:	7942                	ld	s2,48(sp)
ffffffffc0200a48:	79a2                	ld	s3,40(sp)
ffffffffc0200a4a:	7a02                	ld	s4,32(sp)
ffffffffc0200a4c:	6ae2                	ld	s5,24(sp)
ffffffffc0200a4e:	6b42                	ld	s6,16(sp)
ffffffffc0200a50:	6ba2                	ld	s7,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200a52:	40c58633          	sub	a2,a1,a2
ffffffffc0200a56:	00006797          	auipc	a5,0x6
ffffffffc0200a5a:	a0c7b123          	sd	a2,-1534(a5) # ffffffffc0206458 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200a5e:	00002517          	auipc	a0,0x2
ffffffffc0200a62:	95250513          	addi	a0,a0,-1710 # ffffffffc02023b0 <commands+0x670>
}
ffffffffc0200a66:	6161                	addi	sp,sp,80
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200a68:	e4aff06f          	j	ffffffffc02000b2 <cprintf>
        cprintf("Checkpoint reached: freemem < mem_end\n");
ffffffffc0200a6c:	00002517          	auipc	a0,0x2
ffffffffc0200a70:	8bc50513          	addi	a0,a0,-1860 # ffffffffc0202328 <commands+0x5e8>
ffffffffc0200a74:	e3eff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200a78:	000ab783          	ld	a5,0(s5)
ffffffffc0200a7c:	00ca5493          	srli	s1,s4,0xc
ffffffffc0200a80:	04f4ff63          	bgeu	s1,a5,ffffffffc0200ade <pmm_init+0x226>
    pmm_manager->init_memmap(base, n);
ffffffffc0200a84:	0009b703          	ld	a4,0(s3)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200a88:	016487b3          	add	a5,s1,s6
ffffffffc0200a8c:	6008                	ld	a0,0(s0)
ffffffffc0200a8e:	00379413          	slli	s0,a5,0x3
ffffffffc0200a92:	97a2                	add	a5,a5,s0
ffffffffc0200a94:	6b18                	ld	a4,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200a96:	414b8a33          	sub	s4,s7,s4
ffffffffc0200a9a:	00379413          	slli	s0,a5,0x3
ffffffffc0200a9e:	00ca5a13          	srli	s4,s4,0xc
    pmm_manager->init_memmap(base, n);
ffffffffc0200aa2:	9522                	add	a0,a0,s0
ffffffffc0200aa4:	85d2                	mv	a1,s4
ffffffffc0200aa6:	9702                	jalr	a4
        cprintf("size_t n is %d",(mem_end - mem_begin) / PGSIZE);
ffffffffc0200aa8:	85d2                	mv	a1,s4
ffffffffc0200aaa:	00002517          	auipc	a0,0x2
ffffffffc0200aae:	8d650513          	addi	a0,a0,-1834 # ffffffffc0202380 <commands+0x640>
ffffffffc0200ab2:	e00ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (PPN(pa) >= npage) {
ffffffffc0200ab6:	000ab783          	ld	a5,0(s5)
ffffffffc0200aba:	02f4f263          	bgeu	s1,a5,ffffffffc0200ade <pmm_init+0x226>
        fppn=pa2page(mem_begin)-pages+nbase;
ffffffffc0200abe:	40345793          	srai	a5,s0,0x3
ffffffffc0200ac2:	00002417          	auipc	s0,0x2
ffffffffc0200ac6:	f0643403          	ld	s0,-250(s0) # ffffffffc02029c8 <error_string+0x38>
ffffffffc0200aca:	028787b3          	mul	a5,a5,s0
ffffffffc0200ace:	00080737          	lui	a4,0x80
ffffffffc0200ad2:	97ba                	add	a5,a5,a4
ffffffffc0200ad4:	00006717          	auipc	a4,0x6
ffffffffc0200ad8:	96f73223          	sd	a5,-1692(a4) # ffffffffc0206438 <fppn>
ffffffffc0200adc:	bf15                	j	ffffffffc0200a10 <pmm_init+0x158>
        panic("pa2page called with invalid pa");
ffffffffc0200ade:	00002617          	auipc	a2,0x2
ffffffffc0200ae2:	87260613          	addi	a2,a2,-1934 # ffffffffc0202350 <commands+0x610>
ffffffffc0200ae6:	06b00593          	li	a1,107
ffffffffc0200aea:	00002517          	auipc	a0,0x2
ffffffffc0200aee:	88650513          	addi	a0,a0,-1914 # ffffffffc0202370 <commands+0x630>
ffffffffc0200af2:	e48ff0ef          	jal	ra,ffffffffc020013a <__panic>
    cprintf("pages:     0x%016lx\n", (uint64_t)PADDR(pages));
ffffffffc0200af6:	00001617          	auipc	a2,0x1
ffffffffc0200afa:	78260613          	addi	a2,a2,1922 # ffffffffc0202278 <commands+0x538>
ffffffffc0200afe:	09300593          	li	a1,147
ffffffffc0200b02:	00001517          	auipc	a0,0x1
ffffffffc0200b06:	79e50513          	addi	a0,a0,1950 # ffffffffc02022a0 <commands+0x560>
ffffffffc0200b0a:	e30ff0ef          	jal	ra,ffffffffc020013a <__panic>
    cprintf("kern_end:  0x%016lx\n", (uint64_t)PADDR(end));
ffffffffc0200b0e:	00006697          	auipc	a3,0x6
ffffffffc0200b12:	96a68693          	addi	a3,a3,-1686 # ffffffffc0206478 <end>
ffffffffc0200b16:	00001617          	auipc	a2,0x1
ffffffffc0200b1a:	76260613          	addi	a2,a2,1890 # ffffffffc0202278 <commands+0x538>
ffffffffc0200b1e:	09200593          	li	a1,146
ffffffffc0200b22:	00001517          	auipc	a0,0x1
ffffffffc0200b26:	77e50513          	addi	a0,a0,1918 # ffffffffc02022a0 <commands+0x560>
ffffffffc0200b2a:	e10ff0ef          	jal	ra,ffffffffc020013a <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200b2e:	86a6                	mv	a3,s1
ffffffffc0200b30:	00001617          	auipc	a2,0x1
ffffffffc0200b34:	74860613          	addi	a2,a2,1864 # ffffffffc0202278 <commands+0x538>
ffffffffc0200b38:	08d00593          	li	a1,141
ffffffffc0200b3c:	00001517          	auipc	a0,0x1
ffffffffc0200b40:	76450513          	addi	a0,a0,1892 # ffffffffc02022a0 <commands+0x560>
ffffffffc0200b44:	df6ff0ef          	jal	ra,ffffffffc020013a <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200b48:	86ae                	mv	a3,a1
ffffffffc0200b4a:	00001617          	auipc	a2,0x1
ffffffffc0200b4e:	72e60613          	addi	a2,a2,1838 # ffffffffc0202278 <commands+0x538>
ffffffffc0200b52:	0b100593          	li	a1,177
ffffffffc0200b56:	00001517          	auipc	a0,0x1
ffffffffc0200b5a:	74a50513          	addi	a0,a0,1866 # ffffffffc02022a0 <commands+0x560>
ffffffffc0200b5e:	ddcff0ef          	jal	ra,ffffffffc020013a <__panic>

ffffffffc0200b62 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200b62:	00005797          	auipc	a5,0x5
ffffffffc0200b66:	4ae78793          	addi	a5,a5,1198 # ffffffffc0206010 <free_area>
ffffffffc0200b6a:	e79c                	sd	a5,8(a5)
ffffffffc0200b6c:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200b6e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200b72:	8082                	ret

ffffffffc0200b74 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200b74:	00005517          	auipc	a0,0x5
ffffffffc0200b78:	4ac56503          	lwu	a0,1196(a0) # ffffffffc0206020 <free_area+0x10>
ffffffffc0200b7c:	8082                	ret

ffffffffc0200b7e <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200b7e:	c14d                	beqz	a0,ffffffffc0200c20 <best_fit_alloc_pages+0xa2>
    if (n > nr_free) {
ffffffffc0200b80:	00005617          	auipc	a2,0x5
ffffffffc0200b84:	49060613          	addi	a2,a2,1168 # ffffffffc0206010 <free_area>
ffffffffc0200b88:	01062803          	lw	a6,16(a2)
ffffffffc0200b8c:	86aa                	mv	a3,a0
ffffffffc0200b8e:	02081793          	slli	a5,a6,0x20
ffffffffc0200b92:	9381                	srli	a5,a5,0x20
ffffffffc0200b94:	08a7e463          	bltu	a5,a0,ffffffffc0200c1c <best_fit_alloc_pages+0x9e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200b98:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc0200b9a:	0018059b          	addiw	a1,a6,1
ffffffffc0200b9e:	1582                	slli	a1,a1,0x20
ffffffffc0200ba0:	9181                	srli	a1,a1,0x20
    struct Page *temp = NULL;
ffffffffc0200ba2:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ba4:	06c78b63          	beq	a5,a2,ffffffffc0200c1a <best_fit_alloc_pages+0x9c>
        if (p->property >= n && p->property<min_size) {
ffffffffc0200ba8:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200bac:	00d76763          	bltu	a4,a3,ffffffffc0200bba <best_fit_alloc_pages+0x3c>
ffffffffc0200bb0:	00b77563          	bgeu	a4,a1,ffffffffc0200bba <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc0200bb4:	fe878513          	addi	a0,a5,-24
ffffffffc0200bb8:	85ba                	mv	a1,a4
ffffffffc0200bba:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200bbc:	fec796e3          	bne	a5,a2,ffffffffc0200ba8 <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc0200bc0:	cd29                	beqz	a0,ffffffffc0200c1a <best_fit_alloc_pages+0x9c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200bc2:	711c                	ld	a5,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200bc4:	6d18                	ld	a4,24(a0)
        if (page->property > n) {
ffffffffc0200bc6:	490c                	lw	a1,16(a0)
            p->property = page->property - n;
ffffffffc0200bc8:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200bcc:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200bce:	e398                	sd	a4,0(a5)
        if (page->property > n) {
ffffffffc0200bd0:	02059793          	slli	a5,a1,0x20
ffffffffc0200bd4:	9381                	srli	a5,a5,0x20
ffffffffc0200bd6:	02f6f863          	bgeu	a3,a5,ffffffffc0200c06 <best_fit_alloc_pages+0x88>
            struct Page *p = page + n;
ffffffffc0200bda:	00369793          	slli	a5,a3,0x3
ffffffffc0200bde:	97b6                	add	a5,a5,a3
ffffffffc0200be0:	078e                	slli	a5,a5,0x3
ffffffffc0200be2:	97aa                	add	a5,a5,a0
            p->property = page->property - n;
ffffffffc0200be4:	411585bb          	subw	a1,a1,a7
ffffffffc0200be8:	cb8c                	sw	a1,16(a5)
ffffffffc0200bea:	4689                	li	a3,2
ffffffffc0200bec:	00878593          	addi	a1,a5,8
ffffffffc0200bf0:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200bf4:	6714                	ld	a3,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc0200bf6:	01878593          	addi	a1,a5,24
        nr_free -= n;
ffffffffc0200bfa:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc0200bfe:	e28c                	sd	a1,0(a3)
ffffffffc0200c00:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc0200c02:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc0200c04:	ef98                	sd	a4,24(a5)
ffffffffc0200c06:	4118083b          	subw	a6,a6,a7
ffffffffc0200c0a:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200c0e:	57f5                	li	a5,-3
ffffffffc0200c10:	00850713          	addi	a4,a0,8
ffffffffc0200c14:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc0200c18:	8082                	ret
}
ffffffffc0200c1a:	8082                	ret
        return NULL;
ffffffffc0200c1c:	4501                	li	a0,0
ffffffffc0200c1e:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200c20:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200c22:	00001697          	auipc	a3,0x1
ffffffffc0200c26:	7ce68693          	addi	a3,a3,1998 # ffffffffc02023f0 <commands+0x6b0>
ffffffffc0200c2a:	00001617          	auipc	a2,0x1
ffffffffc0200c2e:	7ce60613          	addi	a2,a2,1998 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0200c32:	06b00593          	li	a1,107
ffffffffc0200c36:	00001517          	auipc	a0,0x1
ffffffffc0200c3a:	7da50513          	addi	a0,a0,2010 # ffffffffc0202410 <commands+0x6d0>
best_fit_alloc_pages(size_t n) {
ffffffffc0200c3e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200c40:	cfaff0ef          	jal	ra,ffffffffc020013a <__panic>

ffffffffc0200c44 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0200c44:	715d                	addi	sp,sp,-80
ffffffffc0200c46:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0200c48:	00005417          	auipc	s0,0x5
ffffffffc0200c4c:	3c840413          	addi	s0,s0,968 # ffffffffc0206010 <free_area>
ffffffffc0200c50:	641c                	ld	a5,8(s0)
ffffffffc0200c52:	e486                	sd	ra,72(sp)
ffffffffc0200c54:	fc26                	sd	s1,56(sp)
ffffffffc0200c56:	f84a                	sd	s2,48(sp)
ffffffffc0200c58:	f44e                	sd	s3,40(sp)
ffffffffc0200c5a:	f052                	sd	s4,32(sp)
ffffffffc0200c5c:	ec56                	sd	s5,24(sp)
ffffffffc0200c5e:	e85a                	sd	s6,16(sp)
ffffffffc0200c60:	e45e                	sd	s7,8(sp)
ffffffffc0200c62:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c64:	26878b63          	beq	a5,s0,ffffffffc0200eda <best_fit_check+0x296>
    int count = 0, total = 0;
ffffffffc0200c68:	4481                	li	s1,0
ffffffffc0200c6a:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200c6c:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200c70:	8b09                	andi	a4,a4,2
ffffffffc0200c72:	26070863          	beqz	a4,ffffffffc0200ee2 <best_fit_check+0x29e>
        count ++, total += p->property;
ffffffffc0200c76:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200c7a:	679c                	ld	a5,8(a5)
ffffffffc0200c7c:	2905                	addiw	s2,s2,1
ffffffffc0200c7e:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c80:	fe8796e3          	bne	a5,s0,ffffffffc0200c6c <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc0200c84:	89a6                	mv	s3,s1
ffffffffc0200c86:	bf9ff0ef          	jal	ra,ffffffffc020087e <nr_free_pages>
ffffffffc0200c8a:	33351c63          	bne	a0,s3,ffffffffc0200fc2 <best_fit_check+0x37e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200c8e:	4505                	li	a0,1
ffffffffc0200c90:	b73ff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200c94:	8a2a                	mv	s4,a0
ffffffffc0200c96:	36050663          	beqz	a0,ffffffffc0201002 <best_fit_check+0x3be>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200c9a:	4505                	li	a0,1
ffffffffc0200c9c:	b67ff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200ca0:	89aa                	mv	s3,a0
ffffffffc0200ca2:	34050063          	beqz	a0,ffffffffc0200fe2 <best_fit_check+0x39e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ca6:	4505                	li	a0,1
ffffffffc0200ca8:	b5bff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200cac:	8aaa                	mv	s5,a0
ffffffffc0200cae:	2c050a63          	beqz	a0,ffffffffc0200f82 <best_fit_check+0x33e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200cb2:	253a0863          	beq	s4,s3,ffffffffc0200f02 <best_fit_check+0x2be>
ffffffffc0200cb6:	24aa0663          	beq	s4,a0,ffffffffc0200f02 <best_fit_check+0x2be>
ffffffffc0200cba:	24a98463          	beq	s3,a0,ffffffffc0200f02 <best_fit_check+0x2be>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200cbe:	000a2783          	lw	a5,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0200cc2:	26079063          	bnez	a5,ffffffffc0200f22 <best_fit_check+0x2de>
ffffffffc0200cc6:	0009a783          	lw	a5,0(s3)
ffffffffc0200cca:	24079c63          	bnez	a5,ffffffffc0200f22 <best_fit_check+0x2de>
ffffffffc0200cce:	411c                	lw	a5,0(a0)
ffffffffc0200cd0:	24079963          	bnez	a5,ffffffffc0200f22 <best_fit_check+0x2de>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200cd4:	00005797          	auipc	a5,0x5
ffffffffc0200cd8:	7747b783          	ld	a5,1908(a5) # ffffffffc0206448 <pages>
ffffffffc0200cdc:	40fa0733          	sub	a4,s4,a5
ffffffffc0200ce0:	870d                	srai	a4,a4,0x3
ffffffffc0200ce2:	00002597          	auipc	a1,0x2
ffffffffc0200ce6:	ce65b583          	ld	a1,-794(a1) # ffffffffc02029c8 <error_string+0x38>
ffffffffc0200cea:	02b70733          	mul	a4,a4,a1
ffffffffc0200cee:	00002617          	auipc	a2,0x2
ffffffffc0200cf2:	ce263603          	ld	a2,-798(a2) # ffffffffc02029d0 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200cf6:	00005697          	auipc	a3,0x5
ffffffffc0200cfa:	74a6b683          	ld	a3,1866(a3) # ffffffffc0206440 <npage>
ffffffffc0200cfe:	06b2                	slli	a3,a3,0xc
ffffffffc0200d00:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d02:	0732                	slli	a4,a4,0xc
ffffffffc0200d04:	22d77f63          	bgeu	a4,a3,ffffffffc0200f42 <best_fit_check+0x2fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d08:	40f98733          	sub	a4,s3,a5
ffffffffc0200d0c:	870d                	srai	a4,a4,0x3
ffffffffc0200d0e:	02b70733          	mul	a4,a4,a1
ffffffffc0200d12:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d14:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200d16:	3ed77663          	bgeu	a4,a3,ffffffffc0201102 <best_fit_check+0x4be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200d1a:	40f507b3          	sub	a5,a0,a5
ffffffffc0200d1e:	878d                	srai	a5,a5,0x3
ffffffffc0200d20:	02b787b3          	mul	a5,a5,a1
ffffffffc0200d24:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200d26:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200d28:	3ad7fd63          	bgeu	a5,a3,ffffffffc02010e2 <best_fit_check+0x49e>
    assert(alloc_page() == NULL);
ffffffffc0200d2c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200d2e:	00043c03          	ld	s8,0(s0)
ffffffffc0200d32:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200d36:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200d3a:	e400                	sd	s0,8(s0)
ffffffffc0200d3c:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200d3e:	00005797          	auipc	a5,0x5
ffffffffc0200d42:	2e07a123          	sw	zero,738(a5) # ffffffffc0206020 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200d46:	abdff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200d4a:	36051c63          	bnez	a0,ffffffffc02010c2 <best_fit_check+0x47e>
    free_page(p0);
ffffffffc0200d4e:	4585                	li	a1,1
ffffffffc0200d50:	8552                	mv	a0,s4
ffffffffc0200d52:	aefff0ef          	jal	ra,ffffffffc0200840 <free_pages>
    free_page(p1);
ffffffffc0200d56:	4585                	li	a1,1
ffffffffc0200d58:	854e                	mv	a0,s3
ffffffffc0200d5a:	ae7ff0ef          	jal	ra,ffffffffc0200840 <free_pages>
    free_page(p2);
ffffffffc0200d5e:	4585                	li	a1,1
ffffffffc0200d60:	8556                	mv	a0,s5
ffffffffc0200d62:	adfff0ef          	jal	ra,ffffffffc0200840 <free_pages>
    assert(nr_free == 3);
ffffffffc0200d66:	4818                	lw	a4,16(s0)
ffffffffc0200d68:	478d                	li	a5,3
ffffffffc0200d6a:	32f71c63          	bne	a4,a5,ffffffffc02010a2 <best_fit_check+0x45e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d6e:	4505                	li	a0,1
ffffffffc0200d70:	a93ff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200d74:	89aa                	mv	s3,a0
ffffffffc0200d76:	30050663          	beqz	a0,ffffffffc0201082 <best_fit_check+0x43e>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d7a:	4505                	li	a0,1
ffffffffc0200d7c:	a87ff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200d80:	8aaa                	mv	s5,a0
ffffffffc0200d82:	2e050063          	beqz	a0,ffffffffc0201062 <best_fit_check+0x41e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d86:	4505                	li	a0,1
ffffffffc0200d88:	a7bff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200d8c:	8a2a                	mv	s4,a0
ffffffffc0200d8e:	2a050a63          	beqz	a0,ffffffffc0201042 <best_fit_check+0x3fe>
    assert(alloc_page() == NULL);
ffffffffc0200d92:	4505                	li	a0,1
ffffffffc0200d94:	a6fff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200d98:	28051563          	bnez	a0,ffffffffc0201022 <best_fit_check+0x3de>
    free_page(p0);
ffffffffc0200d9c:	4585                	li	a1,1
ffffffffc0200d9e:	854e                	mv	a0,s3
ffffffffc0200da0:	aa1ff0ef          	jal	ra,ffffffffc0200840 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200da4:	641c                	ld	a5,8(s0)
ffffffffc0200da6:	1a878e63          	beq	a5,s0,ffffffffc0200f62 <best_fit_check+0x31e>
    assert((p = alloc_page()) == p0);
ffffffffc0200daa:	4505                	li	a0,1
ffffffffc0200dac:	a57ff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200db0:	52a99963          	bne	s3,a0,ffffffffc02012e2 <best_fit_check+0x69e>
    assert(alloc_page() == NULL);
ffffffffc0200db4:	4505                	li	a0,1
ffffffffc0200db6:	a4dff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200dba:	50051463          	bnez	a0,ffffffffc02012c2 <best_fit_check+0x67e>
    assert(nr_free == 0);
ffffffffc0200dbe:	481c                	lw	a5,16(s0)
ffffffffc0200dc0:	4e079163          	bnez	a5,ffffffffc02012a2 <best_fit_check+0x65e>
    free_page(p);
ffffffffc0200dc4:	854e                	mv	a0,s3
ffffffffc0200dc6:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200dc8:	01843023          	sd	s8,0(s0)
ffffffffc0200dcc:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200dd0:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200dd4:	a6dff0ef          	jal	ra,ffffffffc0200840 <free_pages>
    free_page(p1);
ffffffffc0200dd8:	4585                	li	a1,1
ffffffffc0200dda:	8556                	mv	a0,s5
ffffffffc0200ddc:	a65ff0ef          	jal	ra,ffffffffc0200840 <free_pages>
    free_page(p2);
ffffffffc0200de0:	4585                	li	a1,1
ffffffffc0200de2:	8552                	mv	a0,s4
ffffffffc0200de4:	a5dff0ef          	jal	ra,ffffffffc0200840 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200de8:	4515                	li	a0,5
ffffffffc0200dea:	a19ff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200dee:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200df0:	48050963          	beqz	a0,ffffffffc0201282 <best_fit_check+0x63e>
ffffffffc0200df4:	651c                	ld	a5,8(a0)
ffffffffc0200df6:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200df8:	8b85                	andi	a5,a5,1
ffffffffc0200dfa:	46079463          	bnez	a5,ffffffffc0201262 <best_fit_check+0x61e>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200dfe:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e00:	00043a83          	ld	s5,0(s0)
ffffffffc0200e04:	00843a03          	ld	s4,8(s0)
ffffffffc0200e08:	e000                	sd	s0,0(s0)
ffffffffc0200e0a:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200e0c:	9f7ff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200e10:	42051963          	bnez	a0,ffffffffc0201242 <best_fit_check+0x5fe>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200e14:	4589                	li	a1,2
ffffffffc0200e16:	04898513          	addi	a0,s3,72
    unsigned int nr_free_store = nr_free;
ffffffffc0200e1a:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200e1e:	12098c13          	addi	s8,s3,288
    nr_free = 0;
ffffffffc0200e22:	00005797          	auipc	a5,0x5
ffffffffc0200e26:	1e07af23          	sw	zero,510(a5) # ffffffffc0206020 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200e2a:	a17ff0ef          	jal	ra,ffffffffc0200840 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200e2e:	8562                	mv	a0,s8
ffffffffc0200e30:	4585                	li	a1,1
ffffffffc0200e32:	a0fff0ef          	jal	ra,ffffffffc0200840 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200e36:	4511                	li	a0,4
ffffffffc0200e38:	9cbff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200e3c:	3e051363          	bnez	a0,ffffffffc0201222 <best_fit_check+0x5de>
ffffffffc0200e40:	0509b783          	ld	a5,80(s3)
ffffffffc0200e44:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200e46:	8b85                	andi	a5,a5,1
ffffffffc0200e48:	3a078d63          	beqz	a5,ffffffffc0201202 <best_fit_check+0x5be>
ffffffffc0200e4c:	0589a703          	lw	a4,88(s3)
ffffffffc0200e50:	4789                	li	a5,2
ffffffffc0200e52:	3af71863          	bne	a4,a5,ffffffffc0201202 <best_fit_check+0x5be>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200e56:	4505                	li	a0,1
ffffffffc0200e58:	9abff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200e5c:	8baa                	mv	s7,a0
ffffffffc0200e5e:	38050263          	beqz	a0,ffffffffc02011e2 <best_fit_check+0x59e>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200e62:	4509                	li	a0,2
ffffffffc0200e64:	99fff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200e68:	34050d63          	beqz	a0,ffffffffc02011c2 <best_fit_check+0x57e>
    assert(p0 + 4 == p1);
ffffffffc0200e6c:	337c1b63          	bne	s8,s7,ffffffffc02011a2 <best_fit_check+0x55e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200e70:	854e                	mv	a0,s3
ffffffffc0200e72:	4595                	li	a1,5
ffffffffc0200e74:	9cdff0ef          	jal	ra,ffffffffc0200840 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200e78:	4515                	li	a0,5
ffffffffc0200e7a:	989ff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200e7e:	89aa                	mv	s3,a0
ffffffffc0200e80:	30050163          	beqz	a0,ffffffffc0201182 <best_fit_check+0x53e>
    assert(alloc_page() == NULL);
ffffffffc0200e84:	4505                	li	a0,1
ffffffffc0200e86:	97dff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200e8a:	2c051c63          	bnez	a0,ffffffffc0201162 <best_fit_check+0x51e>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200e8e:	481c                	lw	a5,16(s0)
ffffffffc0200e90:	2a079963          	bnez	a5,ffffffffc0201142 <best_fit_check+0x4fe>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200e94:	4595                	li	a1,5
ffffffffc0200e96:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200e98:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc0200e9c:	01543023          	sd	s5,0(s0)
ffffffffc0200ea0:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc0200ea4:	99dff0ef          	jal	ra,ffffffffc0200840 <free_pages>
    return listelm->next;
ffffffffc0200ea8:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200eaa:	00878963          	beq	a5,s0,ffffffffc0200ebc <best_fit_check+0x278>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200eae:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200eb2:	679c                	ld	a5,8(a5)
ffffffffc0200eb4:	397d                	addiw	s2,s2,-1
ffffffffc0200eb6:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200eb8:	fe879be3          	bne	a5,s0,ffffffffc0200eae <best_fit_check+0x26a>
    }
    assert(count == 0);
ffffffffc0200ebc:	26091363          	bnez	s2,ffffffffc0201122 <best_fit_check+0x4de>
    assert(total == 0);
ffffffffc0200ec0:	e0ed                	bnez	s1,ffffffffc0200fa2 <best_fit_check+0x35e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200ec2:	60a6                	ld	ra,72(sp)
ffffffffc0200ec4:	6406                	ld	s0,64(sp)
ffffffffc0200ec6:	74e2                	ld	s1,56(sp)
ffffffffc0200ec8:	7942                	ld	s2,48(sp)
ffffffffc0200eca:	79a2                	ld	s3,40(sp)
ffffffffc0200ecc:	7a02                	ld	s4,32(sp)
ffffffffc0200ece:	6ae2                	ld	s5,24(sp)
ffffffffc0200ed0:	6b42                	ld	s6,16(sp)
ffffffffc0200ed2:	6ba2                	ld	s7,8(sp)
ffffffffc0200ed4:	6c02                	ld	s8,0(sp)
ffffffffc0200ed6:	6161                	addi	sp,sp,80
ffffffffc0200ed8:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200eda:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200edc:	4481                	li	s1,0
ffffffffc0200ede:	4901                	li	s2,0
ffffffffc0200ee0:	b35d                	j	ffffffffc0200c86 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200ee2:	00001697          	auipc	a3,0x1
ffffffffc0200ee6:	54668693          	addi	a3,a3,1350 # ffffffffc0202428 <commands+0x6e8>
ffffffffc0200eea:	00001617          	auipc	a2,0x1
ffffffffc0200eee:	50e60613          	addi	a2,a2,1294 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0200ef2:	10a00593          	li	a1,266
ffffffffc0200ef6:	00001517          	auipc	a0,0x1
ffffffffc0200efa:	51a50513          	addi	a0,a0,1306 # ffffffffc0202410 <commands+0x6d0>
ffffffffc0200efe:	a3cff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200f02:	00001697          	auipc	a3,0x1
ffffffffc0200f06:	5b668693          	addi	a3,a3,1462 # ffffffffc02024b8 <commands+0x778>
ffffffffc0200f0a:	00001617          	auipc	a2,0x1
ffffffffc0200f0e:	4ee60613          	addi	a2,a2,1262 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0200f12:	0d600593          	li	a1,214
ffffffffc0200f16:	00001517          	auipc	a0,0x1
ffffffffc0200f1a:	4fa50513          	addi	a0,a0,1274 # ffffffffc0202410 <commands+0x6d0>
ffffffffc0200f1e:	a1cff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200f22:	00001697          	auipc	a3,0x1
ffffffffc0200f26:	5be68693          	addi	a3,a3,1470 # ffffffffc02024e0 <commands+0x7a0>
ffffffffc0200f2a:	00001617          	auipc	a2,0x1
ffffffffc0200f2e:	4ce60613          	addi	a2,a2,1230 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0200f32:	0d700593          	li	a1,215
ffffffffc0200f36:	00001517          	auipc	a0,0x1
ffffffffc0200f3a:	4da50513          	addi	a0,a0,1242 # ffffffffc0202410 <commands+0x6d0>
ffffffffc0200f3e:	9fcff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f42:	00001697          	auipc	a3,0x1
ffffffffc0200f46:	5de68693          	addi	a3,a3,1502 # ffffffffc0202520 <commands+0x7e0>
ffffffffc0200f4a:	00001617          	auipc	a2,0x1
ffffffffc0200f4e:	4ae60613          	addi	a2,a2,1198 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0200f52:	0d900593          	li	a1,217
ffffffffc0200f56:	00001517          	auipc	a0,0x1
ffffffffc0200f5a:	4ba50513          	addi	a0,a0,1210 # ffffffffc0202410 <commands+0x6d0>
ffffffffc0200f5e:	9dcff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200f62:	00001697          	auipc	a3,0x1
ffffffffc0200f66:	64668693          	addi	a3,a3,1606 # ffffffffc02025a8 <commands+0x868>
ffffffffc0200f6a:	00001617          	auipc	a2,0x1
ffffffffc0200f6e:	48e60613          	addi	a2,a2,1166 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0200f72:	0f200593          	li	a1,242
ffffffffc0200f76:	00001517          	auipc	a0,0x1
ffffffffc0200f7a:	49a50513          	addi	a0,a0,1178 # ffffffffc0202410 <commands+0x6d0>
ffffffffc0200f7e:	9bcff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200f82:	00001697          	auipc	a3,0x1
ffffffffc0200f86:	51668693          	addi	a3,a3,1302 # ffffffffc0202498 <commands+0x758>
ffffffffc0200f8a:	00001617          	auipc	a2,0x1
ffffffffc0200f8e:	46e60613          	addi	a2,a2,1134 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0200f92:	0d400593          	li	a1,212
ffffffffc0200f96:	00001517          	auipc	a0,0x1
ffffffffc0200f9a:	47a50513          	addi	a0,a0,1146 # ffffffffc0202410 <commands+0x6d0>
ffffffffc0200f9e:	99cff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(total == 0);
ffffffffc0200fa2:	00001697          	auipc	a3,0x1
ffffffffc0200fa6:	73668693          	addi	a3,a3,1846 # ffffffffc02026d8 <commands+0x998>
ffffffffc0200faa:	00001617          	auipc	a2,0x1
ffffffffc0200fae:	44e60613          	addi	a2,a2,1102 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0200fb2:	14c00593          	li	a1,332
ffffffffc0200fb6:	00001517          	auipc	a0,0x1
ffffffffc0200fba:	45a50513          	addi	a0,a0,1114 # ffffffffc0202410 <commands+0x6d0>
ffffffffc0200fbe:	97cff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(total == nr_free_pages());
ffffffffc0200fc2:	00001697          	auipc	a3,0x1
ffffffffc0200fc6:	47668693          	addi	a3,a3,1142 # ffffffffc0202438 <commands+0x6f8>
ffffffffc0200fca:	00001617          	auipc	a2,0x1
ffffffffc0200fce:	42e60613          	addi	a2,a2,1070 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0200fd2:	10d00593          	li	a1,269
ffffffffc0200fd6:	00001517          	auipc	a0,0x1
ffffffffc0200fda:	43a50513          	addi	a0,a0,1082 # ffffffffc0202410 <commands+0x6d0>
ffffffffc0200fde:	95cff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fe2:	00001697          	auipc	a3,0x1
ffffffffc0200fe6:	49668693          	addi	a3,a3,1174 # ffffffffc0202478 <commands+0x738>
ffffffffc0200fea:	00001617          	auipc	a2,0x1
ffffffffc0200fee:	40e60613          	addi	a2,a2,1038 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0200ff2:	0d300593          	li	a1,211
ffffffffc0200ff6:	00001517          	auipc	a0,0x1
ffffffffc0200ffa:	41a50513          	addi	a0,a0,1050 # ffffffffc0202410 <commands+0x6d0>
ffffffffc0200ffe:	93cff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201002:	00001697          	auipc	a3,0x1
ffffffffc0201006:	45668693          	addi	a3,a3,1110 # ffffffffc0202458 <commands+0x718>
ffffffffc020100a:	00001617          	auipc	a2,0x1
ffffffffc020100e:	3ee60613          	addi	a2,a2,1006 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0201012:	0d200593          	li	a1,210
ffffffffc0201016:	00001517          	auipc	a0,0x1
ffffffffc020101a:	3fa50513          	addi	a0,a0,1018 # ffffffffc0202410 <commands+0x6d0>
ffffffffc020101e:	91cff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201022:	00001697          	auipc	a3,0x1
ffffffffc0201026:	55e68693          	addi	a3,a3,1374 # ffffffffc0202580 <commands+0x840>
ffffffffc020102a:	00001617          	auipc	a2,0x1
ffffffffc020102e:	3ce60613          	addi	a2,a2,974 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0201032:	0ef00593          	li	a1,239
ffffffffc0201036:	00001517          	auipc	a0,0x1
ffffffffc020103a:	3da50513          	addi	a0,a0,986 # ffffffffc0202410 <commands+0x6d0>
ffffffffc020103e:	8fcff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201042:	00001697          	auipc	a3,0x1
ffffffffc0201046:	45668693          	addi	a3,a3,1110 # ffffffffc0202498 <commands+0x758>
ffffffffc020104a:	00001617          	auipc	a2,0x1
ffffffffc020104e:	3ae60613          	addi	a2,a2,942 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0201052:	0ed00593          	li	a1,237
ffffffffc0201056:	00001517          	auipc	a0,0x1
ffffffffc020105a:	3ba50513          	addi	a0,a0,954 # ffffffffc0202410 <commands+0x6d0>
ffffffffc020105e:	8dcff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201062:	00001697          	auipc	a3,0x1
ffffffffc0201066:	41668693          	addi	a3,a3,1046 # ffffffffc0202478 <commands+0x738>
ffffffffc020106a:	00001617          	auipc	a2,0x1
ffffffffc020106e:	38e60613          	addi	a2,a2,910 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0201072:	0ec00593          	li	a1,236
ffffffffc0201076:	00001517          	auipc	a0,0x1
ffffffffc020107a:	39a50513          	addi	a0,a0,922 # ffffffffc0202410 <commands+0x6d0>
ffffffffc020107e:	8bcff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201082:	00001697          	auipc	a3,0x1
ffffffffc0201086:	3d668693          	addi	a3,a3,982 # ffffffffc0202458 <commands+0x718>
ffffffffc020108a:	00001617          	auipc	a2,0x1
ffffffffc020108e:	36e60613          	addi	a2,a2,878 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0201092:	0eb00593          	li	a1,235
ffffffffc0201096:	00001517          	auipc	a0,0x1
ffffffffc020109a:	37a50513          	addi	a0,a0,890 # ffffffffc0202410 <commands+0x6d0>
ffffffffc020109e:	89cff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(nr_free == 3);
ffffffffc02010a2:	00001697          	auipc	a3,0x1
ffffffffc02010a6:	4f668693          	addi	a3,a3,1270 # ffffffffc0202598 <commands+0x858>
ffffffffc02010aa:	00001617          	auipc	a2,0x1
ffffffffc02010ae:	34e60613          	addi	a2,a2,846 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc02010b2:	0e900593          	li	a1,233
ffffffffc02010b6:	00001517          	auipc	a0,0x1
ffffffffc02010ba:	35a50513          	addi	a0,a0,858 # ffffffffc0202410 <commands+0x6d0>
ffffffffc02010be:	87cff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02010c2:	00001697          	auipc	a3,0x1
ffffffffc02010c6:	4be68693          	addi	a3,a3,1214 # ffffffffc0202580 <commands+0x840>
ffffffffc02010ca:	00001617          	auipc	a2,0x1
ffffffffc02010ce:	32e60613          	addi	a2,a2,814 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc02010d2:	0e400593          	li	a1,228
ffffffffc02010d6:	00001517          	auipc	a0,0x1
ffffffffc02010da:	33a50513          	addi	a0,a0,826 # ffffffffc0202410 <commands+0x6d0>
ffffffffc02010de:	85cff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02010e2:	00001697          	auipc	a3,0x1
ffffffffc02010e6:	47e68693          	addi	a3,a3,1150 # ffffffffc0202560 <commands+0x820>
ffffffffc02010ea:	00001617          	auipc	a2,0x1
ffffffffc02010ee:	30e60613          	addi	a2,a2,782 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc02010f2:	0db00593          	li	a1,219
ffffffffc02010f6:	00001517          	auipc	a0,0x1
ffffffffc02010fa:	31a50513          	addi	a0,a0,794 # ffffffffc0202410 <commands+0x6d0>
ffffffffc02010fe:	83cff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201102:	00001697          	auipc	a3,0x1
ffffffffc0201106:	43e68693          	addi	a3,a3,1086 # ffffffffc0202540 <commands+0x800>
ffffffffc020110a:	00001617          	auipc	a2,0x1
ffffffffc020110e:	2ee60613          	addi	a2,a2,750 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0201112:	0da00593          	li	a1,218
ffffffffc0201116:	00001517          	auipc	a0,0x1
ffffffffc020111a:	2fa50513          	addi	a0,a0,762 # ffffffffc0202410 <commands+0x6d0>
ffffffffc020111e:	81cff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(count == 0);
ffffffffc0201122:	00001697          	auipc	a3,0x1
ffffffffc0201126:	5a668693          	addi	a3,a3,1446 # ffffffffc02026c8 <commands+0x988>
ffffffffc020112a:	00001617          	auipc	a2,0x1
ffffffffc020112e:	2ce60613          	addi	a2,a2,718 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0201132:	14b00593          	li	a1,331
ffffffffc0201136:	00001517          	auipc	a0,0x1
ffffffffc020113a:	2da50513          	addi	a0,a0,730 # ffffffffc0202410 <commands+0x6d0>
ffffffffc020113e:	ffdfe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(nr_free == 0);
ffffffffc0201142:	00001697          	auipc	a3,0x1
ffffffffc0201146:	49e68693          	addi	a3,a3,1182 # ffffffffc02025e0 <commands+0x8a0>
ffffffffc020114a:	00001617          	auipc	a2,0x1
ffffffffc020114e:	2ae60613          	addi	a2,a2,686 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0201152:	14000593          	li	a1,320
ffffffffc0201156:	00001517          	auipc	a0,0x1
ffffffffc020115a:	2ba50513          	addi	a0,a0,698 # ffffffffc0202410 <commands+0x6d0>
ffffffffc020115e:	fddfe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201162:	00001697          	auipc	a3,0x1
ffffffffc0201166:	41e68693          	addi	a3,a3,1054 # ffffffffc0202580 <commands+0x840>
ffffffffc020116a:	00001617          	auipc	a2,0x1
ffffffffc020116e:	28e60613          	addi	a2,a2,654 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0201172:	13a00593          	li	a1,314
ffffffffc0201176:	00001517          	auipc	a0,0x1
ffffffffc020117a:	29a50513          	addi	a0,a0,666 # ffffffffc0202410 <commands+0x6d0>
ffffffffc020117e:	fbdfe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201182:	00001697          	auipc	a3,0x1
ffffffffc0201186:	52668693          	addi	a3,a3,1318 # ffffffffc02026a8 <commands+0x968>
ffffffffc020118a:	00001617          	auipc	a2,0x1
ffffffffc020118e:	26e60613          	addi	a2,a2,622 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0201192:	13900593          	li	a1,313
ffffffffc0201196:	00001517          	auipc	a0,0x1
ffffffffc020119a:	27a50513          	addi	a0,a0,634 # ffffffffc0202410 <commands+0x6d0>
ffffffffc020119e:	f9dfe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(p0 + 4 == p1);
ffffffffc02011a2:	00001697          	auipc	a3,0x1
ffffffffc02011a6:	4f668693          	addi	a3,a3,1270 # ffffffffc0202698 <commands+0x958>
ffffffffc02011aa:	00001617          	auipc	a2,0x1
ffffffffc02011ae:	24e60613          	addi	a2,a2,590 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc02011b2:	13100593          	li	a1,305
ffffffffc02011b6:	00001517          	auipc	a0,0x1
ffffffffc02011ba:	25a50513          	addi	a0,a0,602 # ffffffffc0202410 <commands+0x6d0>
ffffffffc02011be:	f7dfe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc02011c2:	00001697          	auipc	a3,0x1
ffffffffc02011c6:	4be68693          	addi	a3,a3,1214 # ffffffffc0202680 <commands+0x940>
ffffffffc02011ca:	00001617          	auipc	a2,0x1
ffffffffc02011ce:	22e60613          	addi	a2,a2,558 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc02011d2:	13000593          	li	a1,304
ffffffffc02011d6:	00001517          	auipc	a0,0x1
ffffffffc02011da:	23a50513          	addi	a0,a0,570 # ffffffffc0202410 <commands+0x6d0>
ffffffffc02011de:	f5dfe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02011e2:	00001697          	auipc	a3,0x1
ffffffffc02011e6:	47e68693          	addi	a3,a3,1150 # ffffffffc0202660 <commands+0x920>
ffffffffc02011ea:	00001617          	auipc	a2,0x1
ffffffffc02011ee:	20e60613          	addi	a2,a2,526 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc02011f2:	12f00593          	li	a1,303
ffffffffc02011f6:	00001517          	auipc	a0,0x1
ffffffffc02011fa:	21a50513          	addi	a0,a0,538 # ffffffffc0202410 <commands+0x6d0>
ffffffffc02011fe:	f3dfe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0201202:	00001697          	auipc	a3,0x1
ffffffffc0201206:	42e68693          	addi	a3,a3,1070 # ffffffffc0202630 <commands+0x8f0>
ffffffffc020120a:	00001617          	auipc	a2,0x1
ffffffffc020120e:	1ee60613          	addi	a2,a2,494 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0201212:	12d00593          	li	a1,301
ffffffffc0201216:	00001517          	auipc	a0,0x1
ffffffffc020121a:	1fa50513          	addi	a0,a0,506 # ffffffffc0202410 <commands+0x6d0>
ffffffffc020121e:	f1dfe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201222:	00001697          	auipc	a3,0x1
ffffffffc0201226:	3f668693          	addi	a3,a3,1014 # ffffffffc0202618 <commands+0x8d8>
ffffffffc020122a:	00001617          	auipc	a2,0x1
ffffffffc020122e:	1ce60613          	addi	a2,a2,462 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0201232:	12c00593          	li	a1,300
ffffffffc0201236:	00001517          	auipc	a0,0x1
ffffffffc020123a:	1da50513          	addi	a0,a0,474 # ffffffffc0202410 <commands+0x6d0>
ffffffffc020123e:	efdfe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201242:	00001697          	auipc	a3,0x1
ffffffffc0201246:	33e68693          	addi	a3,a3,830 # ffffffffc0202580 <commands+0x840>
ffffffffc020124a:	00001617          	auipc	a2,0x1
ffffffffc020124e:	1ae60613          	addi	a2,a2,430 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0201252:	12000593          	li	a1,288
ffffffffc0201256:	00001517          	auipc	a0,0x1
ffffffffc020125a:	1ba50513          	addi	a0,a0,442 # ffffffffc0202410 <commands+0x6d0>
ffffffffc020125e:	eddfe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(!PageProperty(p0));
ffffffffc0201262:	00001697          	auipc	a3,0x1
ffffffffc0201266:	39e68693          	addi	a3,a3,926 # ffffffffc0202600 <commands+0x8c0>
ffffffffc020126a:	00001617          	auipc	a2,0x1
ffffffffc020126e:	18e60613          	addi	a2,a2,398 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0201272:	11700593          	li	a1,279
ffffffffc0201276:	00001517          	auipc	a0,0x1
ffffffffc020127a:	19a50513          	addi	a0,a0,410 # ffffffffc0202410 <commands+0x6d0>
ffffffffc020127e:	ebdfe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(p0 != NULL);
ffffffffc0201282:	00001697          	auipc	a3,0x1
ffffffffc0201286:	36e68693          	addi	a3,a3,878 # ffffffffc02025f0 <commands+0x8b0>
ffffffffc020128a:	00001617          	auipc	a2,0x1
ffffffffc020128e:	16e60613          	addi	a2,a2,366 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc0201292:	11600593          	li	a1,278
ffffffffc0201296:	00001517          	auipc	a0,0x1
ffffffffc020129a:	17a50513          	addi	a0,a0,378 # ffffffffc0202410 <commands+0x6d0>
ffffffffc020129e:	e9dfe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(nr_free == 0);
ffffffffc02012a2:	00001697          	auipc	a3,0x1
ffffffffc02012a6:	33e68693          	addi	a3,a3,830 # ffffffffc02025e0 <commands+0x8a0>
ffffffffc02012aa:	00001617          	auipc	a2,0x1
ffffffffc02012ae:	14e60613          	addi	a2,a2,334 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc02012b2:	0f800593          	li	a1,248
ffffffffc02012b6:	00001517          	auipc	a0,0x1
ffffffffc02012ba:	15a50513          	addi	a0,a0,346 # ffffffffc0202410 <commands+0x6d0>
ffffffffc02012be:	e7dfe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(alloc_page() == NULL);
ffffffffc02012c2:	00001697          	auipc	a3,0x1
ffffffffc02012c6:	2be68693          	addi	a3,a3,702 # ffffffffc0202580 <commands+0x840>
ffffffffc02012ca:	00001617          	auipc	a2,0x1
ffffffffc02012ce:	12e60613          	addi	a2,a2,302 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc02012d2:	0f600593          	li	a1,246
ffffffffc02012d6:	00001517          	auipc	a0,0x1
ffffffffc02012da:	13a50513          	addi	a0,a0,314 # ffffffffc0202410 <commands+0x6d0>
ffffffffc02012de:	e5dfe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02012e2:	00001697          	auipc	a3,0x1
ffffffffc02012e6:	2de68693          	addi	a3,a3,734 # ffffffffc02025c0 <commands+0x880>
ffffffffc02012ea:	00001617          	auipc	a2,0x1
ffffffffc02012ee:	10e60613          	addi	a2,a2,270 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc02012f2:	0f500593          	li	a1,245
ffffffffc02012f6:	00001517          	auipc	a0,0x1
ffffffffc02012fa:	11a50513          	addi	a0,a0,282 # ffffffffc0202410 <commands+0x6d0>
ffffffffc02012fe:	e3dfe0ef          	jal	ra,ffffffffc020013a <__panic>

ffffffffc0201302 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0201302:	1141                	addi	sp,sp,-16
ffffffffc0201304:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201306:	14058a63          	beqz	a1,ffffffffc020145a <best_fit_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc020130a:	00359693          	slli	a3,a1,0x3
ffffffffc020130e:	96ae                	add	a3,a3,a1
ffffffffc0201310:	068e                	slli	a3,a3,0x3
ffffffffc0201312:	96aa                	add	a3,a3,a0
ffffffffc0201314:	87aa                	mv	a5,a0
ffffffffc0201316:	02d50263          	beq	a0,a3,ffffffffc020133a <best_fit_free_pages+0x38>
ffffffffc020131a:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020131c:	8b05                	andi	a4,a4,1
ffffffffc020131e:	10071e63          	bnez	a4,ffffffffc020143a <best_fit_free_pages+0x138>
ffffffffc0201322:	6798                	ld	a4,8(a5)
ffffffffc0201324:	8b09                	andi	a4,a4,2
ffffffffc0201326:	10071a63          	bnez	a4,ffffffffc020143a <best_fit_free_pages+0x138>
        p->flags = 0;
ffffffffc020132a:	0007b423          	sd	zero,8(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc020132e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201332:	04878793          	addi	a5,a5,72
ffffffffc0201336:	fed792e3          	bne	a5,a3,ffffffffc020131a <best_fit_free_pages+0x18>
    base->property=n;
ffffffffc020133a:	2581                	sext.w	a1,a1
ffffffffc020133c:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020133e:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201342:	4789                	li	a5,2
ffffffffc0201344:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free+=n;
ffffffffc0201348:	00005697          	auipc	a3,0x5
ffffffffc020134c:	cc868693          	addi	a3,a3,-824 # ffffffffc0206010 <free_area>
ffffffffc0201350:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201352:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0201354:	01850613          	addi	a2,a0,24
    nr_free+=n;
ffffffffc0201358:	9db9                	addw	a1,a1,a4
ffffffffc020135a:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020135c:	0ad78863          	beq	a5,a3,ffffffffc020140c <best_fit_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201360:	fe878713          	addi	a4,a5,-24
ffffffffc0201364:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201368:	4581                	li	a1,0
            if (base < page) {
ffffffffc020136a:	00e56a63          	bltu	a0,a4,ffffffffc020137e <best_fit_free_pages+0x7c>
    return listelm->next;
ffffffffc020136e:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201370:	06d70263          	beq	a4,a3,ffffffffc02013d4 <best_fit_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc0201374:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201376:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc020137a:	fee57ae3          	bgeu	a0,a4,ffffffffc020136e <best_fit_free_pages+0x6c>
ffffffffc020137e:	c199                	beqz	a1,ffffffffc0201384 <best_fit_free_pages+0x82>
ffffffffc0201380:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201384:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0201386:	e390                	sd	a2,0(a5)
ffffffffc0201388:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020138a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020138c:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc020138e:	02d70063          	beq	a4,a3,ffffffffc02013ae <best_fit_free_pages+0xac>
        if(p+p->property==base){
ffffffffc0201392:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc0201396:	fe870593          	addi	a1,a4,-24
        if(p+p->property==base){
ffffffffc020139a:	02081613          	slli	a2,a6,0x20
ffffffffc020139e:	9201                	srli	a2,a2,0x20
ffffffffc02013a0:	00361793          	slli	a5,a2,0x3
ffffffffc02013a4:	97b2                	add	a5,a5,a2
ffffffffc02013a6:	078e                	slli	a5,a5,0x3
ffffffffc02013a8:	97ae                	add	a5,a5,a1
ffffffffc02013aa:	02f50f63          	beq	a0,a5,ffffffffc02013e8 <best_fit_free_pages+0xe6>
    return listelm->next;
ffffffffc02013ae:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc02013b0:	00d70f63          	beq	a4,a3,ffffffffc02013ce <best_fit_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc02013b4:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc02013b6:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc02013ba:	02059613          	slli	a2,a1,0x20
ffffffffc02013be:	9201                	srli	a2,a2,0x20
ffffffffc02013c0:	00361793          	slli	a5,a2,0x3
ffffffffc02013c4:	97b2                	add	a5,a5,a2
ffffffffc02013c6:	078e                	slli	a5,a5,0x3
ffffffffc02013c8:	97aa                	add	a5,a5,a0
ffffffffc02013ca:	04f68863          	beq	a3,a5,ffffffffc020141a <best_fit_free_pages+0x118>
}
ffffffffc02013ce:	60a2                	ld	ra,8(sp)
ffffffffc02013d0:	0141                	addi	sp,sp,16
ffffffffc02013d2:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02013d4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02013d6:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02013d8:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02013da:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02013dc:	02d70563          	beq	a4,a3,ffffffffc0201406 <best_fit_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc02013e0:	8832                	mv	a6,a2
ffffffffc02013e2:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02013e4:	87ba                	mv	a5,a4
ffffffffc02013e6:	bf41                	j	ffffffffc0201376 <best_fit_free_pages+0x74>
            p->property+=base->property;
ffffffffc02013e8:	491c                	lw	a5,16(a0)
ffffffffc02013ea:	0107883b          	addw	a6,a5,a6
ffffffffc02013ee:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02013f2:	57f5                	li	a5,-3
ffffffffc02013f4:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02013f8:	6d10                	ld	a2,24(a0)
ffffffffc02013fa:	711c                	ld	a5,32(a0)
            base=p;
ffffffffc02013fc:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc02013fe:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc0201400:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc0201402:	e390                	sd	a2,0(a5)
ffffffffc0201404:	b775                	j	ffffffffc02013b0 <best_fit_free_pages+0xae>
ffffffffc0201406:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201408:	873e                	mv	a4,a5
ffffffffc020140a:	b761                	j	ffffffffc0201392 <best_fit_free_pages+0x90>
}
ffffffffc020140c:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020140e:	e390                	sd	a2,0(a5)
ffffffffc0201410:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201412:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201414:	ed1c                	sd	a5,24(a0)
ffffffffc0201416:	0141                	addi	sp,sp,16
ffffffffc0201418:	8082                	ret
            base->property += p->property;
ffffffffc020141a:	ff872783          	lw	a5,-8(a4)
ffffffffc020141e:	ff070693          	addi	a3,a4,-16
ffffffffc0201422:	9dbd                	addw	a1,a1,a5
ffffffffc0201424:	c90c                	sw	a1,16(a0)
ffffffffc0201426:	57f5                	li	a5,-3
ffffffffc0201428:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc020142c:	6314                	ld	a3,0(a4)
ffffffffc020142e:	671c                	ld	a5,8(a4)
}
ffffffffc0201430:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201432:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0201434:	e394                	sd	a3,0(a5)
ffffffffc0201436:	0141                	addi	sp,sp,16
ffffffffc0201438:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020143a:	00001697          	auipc	a3,0x1
ffffffffc020143e:	2ae68693          	addi	a3,a3,686 # ffffffffc02026e8 <commands+0x9a8>
ffffffffc0201442:	00001617          	auipc	a2,0x1
ffffffffc0201446:	fb660613          	addi	a2,a2,-74 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc020144a:	09300593          	li	a1,147
ffffffffc020144e:	00001517          	auipc	a0,0x1
ffffffffc0201452:	fc250513          	addi	a0,a0,-62 # ffffffffc0202410 <commands+0x6d0>
ffffffffc0201456:	ce5fe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(n > 0);
ffffffffc020145a:	00001697          	auipc	a3,0x1
ffffffffc020145e:	f9668693          	addi	a3,a3,-106 # ffffffffc02023f0 <commands+0x6b0>
ffffffffc0201462:	00001617          	auipc	a2,0x1
ffffffffc0201466:	f9660613          	addi	a2,a2,-106 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc020146a:	09000593          	li	a1,144
ffffffffc020146e:	00001517          	auipc	a0,0x1
ffffffffc0201472:	fa250513          	addi	a0,a0,-94 # ffffffffc0202410 <commands+0x6d0>
ffffffffc0201476:	cc5fe0ef          	jal	ra,ffffffffc020013a <__panic>

ffffffffc020147a <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc020147a:	1141                	addi	sp,sp,-16
ffffffffc020147c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020147e:	c9e1                	beqz	a1,ffffffffc020154e <best_fit_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc0201480:	00359693          	slli	a3,a1,0x3
ffffffffc0201484:	96ae                	add	a3,a3,a1
ffffffffc0201486:	068e                	slli	a3,a3,0x3
ffffffffc0201488:	96aa                	add	a3,a3,a0
ffffffffc020148a:	87aa                	mv	a5,a0
ffffffffc020148c:	00d50f63          	beq	a0,a3,ffffffffc02014aa <best_fit_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201490:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201492:	8b05                	andi	a4,a4,1
ffffffffc0201494:	cf49                	beqz	a4,ffffffffc020152e <best_fit_init_memmap+0xb4>
        p->flags=p->property=0;
ffffffffc0201496:	0007a823          	sw	zero,16(a5)
ffffffffc020149a:	0007b423          	sd	zero,8(a5)
ffffffffc020149e:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02014a2:	04878793          	addi	a5,a5,72
ffffffffc02014a6:	fed795e3          	bne	a5,a3,ffffffffc0201490 <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc02014aa:	2581                	sext.w	a1,a1
ffffffffc02014ac:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02014ae:	4789                	li	a5,2
ffffffffc02014b0:	00850713          	addi	a4,a0,8
ffffffffc02014b4:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02014b8:	00005697          	auipc	a3,0x5
ffffffffc02014bc:	b5868693          	addi	a3,a3,-1192 # ffffffffc0206010 <free_area>
ffffffffc02014c0:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02014c2:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02014c4:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02014c8:	9db9                	addw	a1,a1,a4
ffffffffc02014ca:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02014cc:	04d78a63          	beq	a5,a3,ffffffffc0201520 <best_fit_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc02014d0:	fe878713          	addi	a4,a5,-24
ffffffffc02014d4:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02014d8:	4581                	li	a1,0
            if(base<page){
ffffffffc02014da:	00e56a63          	bltu	a0,a4,ffffffffc02014ee <best_fit_init_memmap+0x74>
    return listelm->next;
ffffffffc02014de:	6798                	ld	a4,8(a5)
            }else if(list_next(le) == &free_list){
ffffffffc02014e0:	02d70263          	beq	a4,a3,ffffffffc0201504 <best_fit_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc02014e4:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02014e6:	fe878713          	addi	a4,a5,-24
            if(base<page){
ffffffffc02014ea:	fee57ae3          	bgeu	a0,a4,ffffffffc02014de <best_fit_init_memmap+0x64>
ffffffffc02014ee:	c199                	beqz	a1,ffffffffc02014f4 <best_fit_init_memmap+0x7a>
ffffffffc02014f0:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02014f4:	6398                	ld	a4,0(a5)
}
ffffffffc02014f6:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02014f8:	e390                	sd	a2,0(a5)
ffffffffc02014fa:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02014fc:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02014fe:	ed18                	sd	a4,24(a0)
ffffffffc0201500:	0141                	addi	sp,sp,16
ffffffffc0201502:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201504:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201506:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201508:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020150a:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020150c:	00d70663          	beq	a4,a3,ffffffffc0201518 <best_fit_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc0201510:	8832                	mv	a6,a2
ffffffffc0201512:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0201514:	87ba                	mv	a5,a4
ffffffffc0201516:	bfc1                	j	ffffffffc02014e6 <best_fit_init_memmap+0x6c>
}
ffffffffc0201518:	60a2                	ld	ra,8(sp)
ffffffffc020151a:	e290                	sd	a2,0(a3)
ffffffffc020151c:	0141                	addi	sp,sp,16
ffffffffc020151e:	8082                	ret
ffffffffc0201520:	60a2                	ld	ra,8(sp)
ffffffffc0201522:	e390                	sd	a2,0(a5)
ffffffffc0201524:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201526:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201528:	ed1c                	sd	a5,24(a0)
ffffffffc020152a:	0141                	addi	sp,sp,16
ffffffffc020152c:	8082                	ret
        assert(PageReserved(p));
ffffffffc020152e:	00001697          	auipc	a3,0x1
ffffffffc0201532:	1e268693          	addi	a3,a3,482 # ffffffffc0202710 <commands+0x9d0>
ffffffffc0201536:	00001617          	auipc	a2,0x1
ffffffffc020153a:	ec260613          	addi	a2,a2,-318 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc020153e:	04b00593          	li	a1,75
ffffffffc0201542:	00001517          	auipc	a0,0x1
ffffffffc0201546:	ece50513          	addi	a0,a0,-306 # ffffffffc0202410 <commands+0x6d0>
ffffffffc020154a:	bf1fe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(n > 0);
ffffffffc020154e:	00001697          	auipc	a3,0x1
ffffffffc0201552:	ea268693          	addi	a3,a3,-350 # ffffffffc02023f0 <commands+0x6b0>
ffffffffc0201556:	00001617          	auipc	a2,0x1
ffffffffc020155a:	ea260613          	addi	a2,a2,-350 # ffffffffc02023f8 <commands+0x6b8>
ffffffffc020155e:	04800593          	li	a1,72
ffffffffc0201562:	00001517          	auipc	a0,0x1
ffffffffc0201566:	eae50513          	addi	a0,a0,-338 # ffffffffc0202410 <commands+0x6d0>
ffffffffc020156a:	bd1fe0ef          	jal	ra,ffffffffc020013a <__panic>

ffffffffc020156e <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc020156e:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201570:	e589                	bnez	a1,ffffffffc020157a <strnlen+0xc>
ffffffffc0201572:	a811                	j	ffffffffc0201586 <strnlen+0x18>
        cnt ++;
ffffffffc0201574:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201576:	00f58863          	beq	a1,a5,ffffffffc0201586 <strnlen+0x18>
ffffffffc020157a:	00f50733          	add	a4,a0,a5
ffffffffc020157e:	00074703          	lbu	a4,0(a4)
ffffffffc0201582:	fb6d                	bnez	a4,ffffffffc0201574 <strnlen+0x6>
ffffffffc0201584:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201586:	852e                	mv	a0,a1
ffffffffc0201588:	8082                	ret

ffffffffc020158a <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020158a:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020158e:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201592:	cb89                	beqz	a5,ffffffffc02015a4 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201594:	0505                	addi	a0,a0,1
ffffffffc0201596:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201598:	fee789e3          	beq	a5,a4,ffffffffc020158a <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020159c:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02015a0:	9d19                	subw	a0,a0,a4
ffffffffc02015a2:	8082                	ret
ffffffffc02015a4:	4501                	li	a0,0
ffffffffc02015a6:	bfed                	j	ffffffffc02015a0 <strcmp+0x16>

ffffffffc02015a8 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02015a8:	00054783          	lbu	a5,0(a0)
ffffffffc02015ac:	c799                	beqz	a5,ffffffffc02015ba <strchr+0x12>
        if (*s == c) {
ffffffffc02015ae:	00f58763          	beq	a1,a5,ffffffffc02015bc <strchr+0x14>
    while (*s != '\0') {
ffffffffc02015b2:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02015b6:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02015b8:	fbfd                	bnez	a5,ffffffffc02015ae <strchr+0x6>
    }
    return NULL;
ffffffffc02015ba:	4501                	li	a0,0
}
ffffffffc02015bc:	8082                	ret

ffffffffc02015be <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02015be:	ca01                	beqz	a2,ffffffffc02015ce <memset+0x10>
ffffffffc02015c0:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02015c2:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02015c4:	0785                	addi	a5,a5,1
ffffffffc02015c6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02015ca:	fec79de3          	bne	a5,a2,ffffffffc02015c4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02015ce:	8082                	ret

ffffffffc02015d0 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02015d0:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02015d4:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02015d6:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02015da:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02015dc:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02015e0:	f022                	sd	s0,32(sp)
ffffffffc02015e2:	ec26                	sd	s1,24(sp)
ffffffffc02015e4:	e84a                	sd	s2,16(sp)
ffffffffc02015e6:	f406                	sd	ra,40(sp)
ffffffffc02015e8:	e44e                	sd	s3,8(sp)
ffffffffc02015ea:	84aa                	mv	s1,a0
ffffffffc02015ec:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02015ee:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02015f2:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02015f4:	03067e63          	bgeu	a2,a6,ffffffffc0201630 <printnum+0x60>
ffffffffc02015f8:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02015fa:	00805763          	blez	s0,ffffffffc0201608 <printnum+0x38>
ffffffffc02015fe:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201600:	85ca                	mv	a1,s2
ffffffffc0201602:	854e                	mv	a0,s3
ffffffffc0201604:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201606:	fc65                	bnez	s0,ffffffffc02015fe <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201608:	1a02                	slli	s4,s4,0x20
ffffffffc020160a:	00001797          	auipc	a5,0x1
ffffffffc020160e:	17678793          	addi	a5,a5,374 # ffffffffc0202780 <best_fit_pmm_manager+0x48>
ffffffffc0201612:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201616:	9a3e                	add	s4,s4,a5
}
ffffffffc0201618:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020161a:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020161e:	70a2                	ld	ra,40(sp)
ffffffffc0201620:	69a2                	ld	s3,8(sp)
ffffffffc0201622:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201624:	85ca                	mv	a1,s2
ffffffffc0201626:	87a6                	mv	a5,s1
}
ffffffffc0201628:	6942                	ld	s2,16(sp)
ffffffffc020162a:	64e2                	ld	s1,24(sp)
ffffffffc020162c:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020162e:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201630:	03065633          	divu	a2,a2,a6
ffffffffc0201634:	8722                	mv	a4,s0
ffffffffc0201636:	f9bff0ef          	jal	ra,ffffffffc02015d0 <printnum>
ffffffffc020163a:	b7f9                	j	ffffffffc0201608 <printnum+0x38>

ffffffffc020163c <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020163c:	7119                	addi	sp,sp,-128
ffffffffc020163e:	f4a6                	sd	s1,104(sp)
ffffffffc0201640:	f0ca                	sd	s2,96(sp)
ffffffffc0201642:	ecce                	sd	s3,88(sp)
ffffffffc0201644:	e8d2                	sd	s4,80(sp)
ffffffffc0201646:	e4d6                	sd	s5,72(sp)
ffffffffc0201648:	e0da                	sd	s6,64(sp)
ffffffffc020164a:	fc5e                	sd	s7,56(sp)
ffffffffc020164c:	f06a                	sd	s10,32(sp)
ffffffffc020164e:	fc86                	sd	ra,120(sp)
ffffffffc0201650:	f8a2                	sd	s0,112(sp)
ffffffffc0201652:	f862                	sd	s8,48(sp)
ffffffffc0201654:	f466                	sd	s9,40(sp)
ffffffffc0201656:	ec6e                	sd	s11,24(sp)
ffffffffc0201658:	892a                	mv	s2,a0
ffffffffc020165a:	84ae                	mv	s1,a1
ffffffffc020165c:	8d32                	mv	s10,a2
ffffffffc020165e:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201660:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201664:	5b7d                	li	s6,-1
ffffffffc0201666:	00001a97          	auipc	s5,0x1
ffffffffc020166a:	14ea8a93          	addi	s5,s5,334 # ffffffffc02027b4 <best_fit_pmm_manager+0x7c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020166e:	00001b97          	auipc	s7,0x1
ffffffffc0201672:	322b8b93          	addi	s7,s7,802 # ffffffffc0202990 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201676:	000d4503          	lbu	a0,0(s10)
ffffffffc020167a:	001d0413          	addi	s0,s10,1
ffffffffc020167e:	01350a63          	beq	a0,s3,ffffffffc0201692 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201682:	c121                	beqz	a0,ffffffffc02016c2 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201684:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201686:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201688:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020168a:	fff44503          	lbu	a0,-1(s0)
ffffffffc020168e:	ff351ae3          	bne	a0,s3,ffffffffc0201682 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201692:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201696:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020169a:	4c81                	li	s9,0
ffffffffc020169c:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020169e:	5c7d                	li	s8,-1
ffffffffc02016a0:	5dfd                	li	s11,-1
ffffffffc02016a2:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02016a6:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016a8:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02016ac:	0ff5f593          	zext.b	a1,a1
ffffffffc02016b0:	00140d13          	addi	s10,s0,1
ffffffffc02016b4:	04b56263          	bltu	a0,a1,ffffffffc02016f8 <vprintfmt+0xbc>
ffffffffc02016b8:	058a                	slli	a1,a1,0x2
ffffffffc02016ba:	95d6                	add	a1,a1,s5
ffffffffc02016bc:	4194                	lw	a3,0(a1)
ffffffffc02016be:	96d6                	add	a3,a3,s5
ffffffffc02016c0:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02016c2:	70e6                	ld	ra,120(sp)
ffffffffc02016c4:	7446                	ld	s0,112(sp)
ffffffffc02016c6:	74a6                	ld	s1,104(sp)
ffffffffc02016c8:	7906                	ld	s2,96(sp)
ffffffffc02016ca:	69e6                	ld	s3,88(sp)
ffffffffc02016cc:	6a46                	ld	s4,80(sp)
ffffffffc02016ce:	6aa6                	ld	s5,72(sp)
ffffffffc02016d0:	6b06                	ld	s6,64(sp)
ffffffffc02016d2:	7be2                	ld	s7,56(sp)
ffffffffc02016d4:	7c42                	ld	s8,48(sp)
ffffffffc02016d6:	7ca2                	ld	s9,40(sp)
ffffffffc02016d8:	7d02                	ld	s10,32(sp)
ffffffffc02016da:	6de2                	ld	s11,24(sp)
ffffffffc02016dc:	6109                	addi	sp,sp,128
ffffffffc02016de:	8082                	ret
            padc = '0';
ffffffffc02016e0:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02016e2:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016e6:	846a                	mv	s0,s10
ffffffffc02016e8:	00140d13          	addi	s10,s0,1
ffffffffc02016ec:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02016f0:	0ff5f593          	zext.b	a1,a1
ffffffffc02016f4:	fcb572e3          	bgeu	a0,a1,ffffffffc02016b8 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02016f8:	85a6                	mv	a1,s1
ffffffffc02016fa:	02500513          	li	a0,37
ffffffffc02016fe:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201700:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201704:	8d22                	mv	s10,s0
ffffffffc0201706:	f73788e3          	beq	a5,s3,ffffffffc0201676 <vprintfmt+0x3a>
ffffffffc020170a:	ffed4783          	lbu	a5,-2(s10)
ffffffffc020170e:	1d7d                	addi	s10,s10,-1
ffffffffc0201710:	ff379de3          	bne	a5,s3,ffffffffc020170a <vprintfmt+0xce>
ffffffffc0201714:	b78d                	j	ffffffffc0201676 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201716:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020171a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020171e:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201720:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201724:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201728:	02d86463          	bltu	a6,a3,ffffffffc0201750 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020172c:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201730:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201734:	0186873b          	addw	a4,a3,s8
ffffffffc0201738:	0017171b          	slliw	a4,a4,0x1
ffffffffc020173c:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc020173e:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201742:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201744:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201748:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020174c:	fed870e3          	bgeu	a6,a3,ffffffffc020172c <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201750:	f40ddce3          	bgez	s11,ffffffffc02016a8 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201754:	8de2                	mv	s11,s8
ffffffffc0201756:	5c7d                	li	s8,-1
ffffffffc0201758:	bf81                	j	ffffffffc02016a8 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020175a:	fffdc693          	not	a3,s11
ffffffffc020175e:	96fd                	srai	a3,a3,0x3f
ffffffffc0201760:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201764:	00144603          	lbu	a2,1(s0)
ffffffffc0201768:	2d81                	sext.w	s11,s11
ffffffffc020176a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020176c:	bf35                	j	ffffffffc02016a8 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc020176e:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201772:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201776:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201778:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc020177a:	bfd9                	j	ffffffffc0201750 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc020177c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020177e:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201782:	01174463          	blt	a4,a7,ffffffffc020178a <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201786:	1a088e63          	beqz	a7,ffffffffc0201942 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc020178a:	000a3603          	ld	a2,0(s4)
ffffffffc020178e:	46c1                	li	a3,16
ffffffffc0201790:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201792:	2781                	sext.w	a5,a5
ffffffffc0201794:	876e                	mv	a4,s11
ffffffffc0201796:	85a6                	mv	a1,s1
ffffffffc0201798:	854a                	mv	a0,s2
ffffffffc020179a:	e37ff0ef          	jal	ra,ffffffffc02015d0 <printnum>
            break;
ffffffffc020179e:	bde1                	j	ffffffffc0201676 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02017a0:	000a2503          	lw	a0,0(s4)
ffffffffc02017a4:	85a6                	mv	a1,s1
ffffffffc02017a6:	0a21                	addi	s4,s4,8
ffffffffc02017a8:	9902                	jalr	s2
            break;
ffffffffc02017aa:	b5f1                	j	ffffffffc0201676 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02017ac:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02017ae:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02017b2:	01174463          	blt	a4,a7,ffffffffc02017ba <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02017b6:	18088163          	beqz	a7,ffffffffc0201938 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02017ba:	000a3603          	ld	a2,0(s4)
ffffffffc02017be:	46a9                	li	a3,10
ffffffffc02017c0:	8a2e                	mv	s4,a1
ffffffffc02017c2:	bfc1                	j	ffffffffc0201792 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017c4:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02017c8:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017ca:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02017cc:	bdf1                	j	ffffffffc02016a8 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02017ce:	85a6                	mv	a1,s1
ffffffffc02017d0:	02500513          	li	a0,37
ffffffffc02017d4:	9902                	jalr	s2
            break;
ffffffffc02017d6:	b545                	j	ffffffffc0201676 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017d8:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02017dc:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02017de:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02017e0:	b5e1                	j	ffffffffc02016a8 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02017e2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02017e4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02017e8:	01174463          	blt	a4,a7,ffffffffc02017f0 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02017ec:	14088163          	beqz	a7,ffffffffc020192e <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02017f0:	000a3603          	ld	a2,0(s4)
ffffffffc02017f4:	46a1                	li	a3,8
ffffffffc02017f6:	8a2e                	mv	s4,a1
ffffffffc02017f8:	bf69                	j	ffffffffc0201792 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02017fa:	03000513          	li	a0,48
ffffffffc02017fe:	85a6                	mv	a1,s1
ffffffffc0201800:	e03e                	sd	a5,0(sp)
ffffffffc0201802:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201804:	85a6                	mv	a1,s1
ffffffffc0201806:	07800513          	li	a0,120
ffffffffc020180a:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020180c:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020180e:	6782                	ld	a5,0(sp)
ffffffffc0201810:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201812:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201816:	bfb5                	j	ffffffffc0201792 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201818:	000a3403          	ld	s0,0(s4)
ffffffffc020181c:	008a0713          	addi	a4,s4,8
ffffffffc0201820:	e03a                	sd	a4,0(sp)
ffffffffc0201822:	14040263          	beqz	s0,ffffffffc0201966 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201826:	0fb05763          	blez	s11,ffffffffc0201914 <vprintfmt+0x2d8>
ffffffffc020182a:	02d00693          	li	a3,45
ffffffffc020182e:	0cd79163          	bne	a5,a3,ffffffffc02018f0 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201832:	00044783          	lbu	a5,0(s0)
ffffffffc0201836:	0007851b          	sext.w	a0,a5
ffffffffc020183a:	cf85                	beqz	a5,ffffffffc0201872 <vprintfmt+0x236>
ffffffffc020183c:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201840:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201844:	000c4563          	bltz	s8,ffffffffc020184e <vprintfmt+0x212>
ffffffffc0201848:	3c7d                	addiw	s8,s8,-1
ffffffffc020184a:	036c0263          	beq	s8,s6,ffffffffc020186e <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc020184e:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201850:	0e0c8e63          	beqz	s9,ffffffffc020194c <vprintfmt+0x310>
ffffffffc0201854:	3781                	addiw	a5,a5,-32
ffffffffc0201856:	0ef47b63          	bgeu	s0,a5,ffffffffc020194c <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020185a:	03f00513          	li	a0,63
ffffffffc020185e:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201860:	000a4783          	lbu	a5,0(s4)
ffffffffc0201864:	3dfd                	addiw	s11,s11,-1
ffffffffc0201866:	0a05                	addi	s4,s4,1
ffffffffc0201868:	0007851b          	sext.w	a0,a5
ffffffffc020186c:	ffe1                	bnez	a5,ffffffffc0201844 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc020186e:	01b05963          	blez	s11,ffffffffc0201880 <vprintfmt+0x244>
ffffffffc0201872:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201874:	85a6                	mv	a1,s1
ffffffffc0201876:	02000513          	li	a0,32
ffffffffc020187a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020187c:	fe0d9be3          	bnez	s11,ffffffffc0201872 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201880:	6a02                	ld	s4,0(sp)
ffffffffc0201882:	bbd5                	j	ffffffffc0201676 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201884:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201886:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc020188a:	01174463          	blt	a4,a7,ffffffffc0201892 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc020188e:	08088d63          	beqz	a7,ffffffffc0201928 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201892:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201896:	0a044d63          	bltz	s0,ffffffffc0201950 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc020189a:	8622                	mv	a2,s0
ffffffffc020189c:	8a66                	mv	s4,s9
ffffffffc020189e:	46a9                	li	a3,10
ffffffffc02018a0:	bdcd                	j	ffffffffc0201792 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02018a2:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02018a6:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02018a8:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02018aa:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02018ae:	8fb5                	xor	a5,a5,a3
ffffffffc02018b0:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02018b4:	02d74163          	blt	a4,a3,ffffffffc02018d6 <vprintfmt+0x29a>
ffffffffc02018b8:	00369793          	slli	a5,a3,0x3
ffffffffc02018bc:	97de                	add	a5,a5,s7
ffffffffc02018be:	639c                	ld	a5,0(a5)
ffffffffc02018c0:	cb99                	beqz	a5,ffffffffc02018d6 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02018c2:	86be                	mv	a3,a5
ffffffffc02018c4:	00001617          	auipc	a2,0x1
ffffffffc02018c8:	eec60613          	addi	a2,a2,-276 # ffffffffc02027b0 <best_fit_pmm_manager+0x78>
ffffffffc02018cc:	85a6                	mv	a1,s1
ffffffffc02018ce:	854a                	mv	a0,s2
ffffffffc02018d0:	0ce000ef          	jal	ra,ffffffffc020199e <printfmt>
ffffffffc02018d4:	b34d                	j	ffffffffc0201676 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02018d6:	00001617          	auipc	a2,0x1
ffffffffc02018da:	eca60613          	addi	a2,a2,-310 # ffffffffc02027a0 <best_fit_pmm_manager+0x68>
ffffffffc02018de:	85a6                	mv	a1,s1
ffffffffc02018e0:	854a                	mv	a0,s2
ffffffffc02018e2:	0bc000ef          	jal	ra,ffffffffc020199e <printfmt>
ffffffffc02018e6:	bb41                	j	ffffffffc0201676 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02018e8:	00001417          	auipc	s0,0x1
ffffffffc02018ec:	eb040413          	addi	s0,s0,-336 # ffffffffc0202798 <best_fit_pmm_manager+0x60>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02018f0:	85e2                	mv	a1,s8
ffffffffc02018f2:	8522                	mv	a0,s0
ffffffffc02018f4:	e43e                	sd	a5,8(sp)
ffffffffc02018f6:	c79ff0ef          	jal	ra,ffffffffc020156e <strnlen>
ffffffffc02018fa:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02018fe:	01b05b63          	blez	s11,ffffffffc0201914 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201902:	67a2                	ld	a5,8(sp)
ffffffffc0201904:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201908:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020190a:	85a6                	mv	a1,s1
ffffffffc020190c:	8552                	mv	a0,s4
ffffffffc020190e:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201910:	fe0d9ce3          	bnez	s11,ffffffffc0201908 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201914:	00044783          	lbu	a5,0(s0)
ffffffffc0201918:	00140a13          	addi	s4,s0,1
ffffffffc020191c:	0007851b          	sext.w	a0,a5
ffffffffc0201920:	d3a5                	beqz	a5,ffffffffc0201880 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201922:	05e00413          	li	s0,94
ffffffffc0201926:	bf39                	j	ffffffffc0201844 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201928:	000a2403          	lw	s0,0(s4)
ffffffffc020192c:	b7ad                	j	ffffffffc0201896 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020192e:	000a6603          	lwu	a2,0(s4)
ffffffffc0201932:	46a1                	li	a3,8
ffffffffc0201934:	8a2e                	mv	s4,a1
ffffffffc0201936:	bdb1                	j	ffffffffc0201792 <vprintfmt+0x156>
ffffffffc0201938:	000a6603          	lwu	a2,0(s4)
ffffffffc020193c:	46a9                	li	a3,10
ffffffffc020193e:	8a2e                	mv	s4,a1
ffffffffc0201940:	bd89                	j	ffffffffc0201792 <vprintfmt+0x156>
ffffffffc0201942:	000a6603          	lwu	a2,0(s4)
ffffffffc0201946:	46c1                	li	a3,16
ffffffffc0201948:	8a2e                	mv	s4,a1
ffffffffc020194a:	b5a1                	j	ffffffffc0201792 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020194c:	9902                	jalr	s2
ffffffffc020194e:	bf09                	j	ffffffffc0201860 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201950:	85a6                	mv	a1,s1
ffffffffc0201952:	02d00513          	li	a0,45
ffffffffc0201956:	e03e                	sd	a5,0(sp)
ffffffffc0201958:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020195a:	6782                	ld	a5,0(sp)
ffffffffc020195c:	8a66                	mv	s4,s9
ffffffffc020195e:	40800633          	neg	a2,s0
ffffffffc0201962:	46a9                	li	a3,10
ffffffffc0201964:	b53d                	j	ffffffffc0201792 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201966:	03b05163          	blez	s11,ffffffffc0201988 <vprintfmt+0x34c>
ffffffffc020196a:	02d00693          	li	a3,45
ffffffffc020196e:	f6d79de3          	bne	a5,a3,ffffffffc02018e8 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201972:	00001417          	auipc	s0,0x1
ffffffffc0201976:	e2640413          	addi	s0,s0,-474 # ffffffffc0202798 <best_fit_pmm_manager+0x60>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020197a:	02800793          	li	a5,40
ffffffffc020197e:	02800513          	li	a0,40
ffffffffc0201982:	00140a13          	addi	s4,s0,1
ffffffffc0201986:	bd6d                	j	ffffffffc0201840 <vprintfmt+0x204>
ffffffffc0201988:	00001a17          	auipc	s4,0x1
ffffffffc020198c:	e11a0a13          	addi	s4,s4,-495 # ffffffffc0202799 <best_fit_pmm_manager+0x61>
ffffffffc0201990:	02800513          	li	a0,40
ffffffffc0201994:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201998:	05e00413          	li	s0,94
ffffffffc020199c:	b565                	j	ffffffffc0201844 <vprintfmt+0x208>

ffffffffc020199e <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020199e:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02019a0:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02019a4:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02019a6:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02019a8:	ec06                	sd	ra,24(sp)
ffffffffc02019aa:	f83a                	sd	a4,48(sp)
ffffffffc02019ac:	fc3e                	sd	a5,56(sp)
ffffffffc02019ae:	e0c2                	sd	a6,64(sp)
ffffffffc02019b0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02019b2:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02019b4:	c89ff0ef          	jal	ra,ffffffffc020163c <vprintfmt>
}
ffffffffc02019b8:	60e2                	ld	ra,24(sp)
ffffffffc02019ba:	6161                	addi	sp,sp,80
ffffffffc02019bc:	8082                	ret

ffffffffc02019be <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02019be:	715d                	addi	sp,sp,-80
ffffffffc02019c0:	e486                	sd	ra,72(sp)
ffffffffc02019c2:	e0a6                	sd	s1,64(sp)
ffffffffc02019c4:	fc4a                	sd	s2,56(sp)
ffffffffc02019c6:	f84e                	sd	s3,48(sp)
ffffffffc02019c8:	f452                	sd	s4,40(sp)
ffffffffc02019ca:	f056                	sd	s5,32(sp)
ffffffffc02019cc:	ec5a                	sd	s6,24(sp)
ffffffffc02019ce:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02019d0:	c901                	beqz	a0,ffffffffc02019e0 <readline+0x22>
ffffffffc02019d2:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02019d4:	00001517          	auipc	a0,0x1
ffffffffc02019d8:	ddc50513          	addi	a0,a0,-548 # ffffffffc02027b0 <best_fit_pmm_manager+0x78>
ffffffffc02019dc:	ed6fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
readline(const char *prompt) {
ffffffffc02019e0:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02019e2:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02019e4:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02019e6:	4aa9                	li	s5,10
ffffffffc02019e8:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02019ea:	00004b97          	auipc	s7,0x4
ffffffffc02019ee:	63eb8b93          	addi	s7,s7,1598 # ffffffffc0206028 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02019f2:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02019f6:	f34fe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc02019fa:	00054a63          	bltz	a0,ffffffffc0201a0e <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02019fe:	00a95a63          	bge	s2,a0,ffffffffc0201a12 <readline+0x54>
ffffffffc0201a02:	029a5263          	bge	s4,s1,ffffffffc0201a26 <readline+0x68>
        c = getchar();
ffffffffc0201a06:	f24fe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201a0a:	fe055ae3          	bgez	a0,ffffffffc02019fe <readline+0x40>
            return NULL;
ffffffffc0201a0e:	4501                	li	a0,0
ffffffffc0201a10:	a091                	j	ffffffffc0201a54 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201a12:	03351463          	bne	a0,s3,ffffffffc0201a3a <readline+0x7c>
ffffffffc0201a16:	e8a9                	bnez	s1,ffffffffc0201a68 <readline+0xaa>
        c = getchar();
ffffffffc0201a18:	f12fe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201a1c:	fe0549e3          	bltz	a0,ffffffffc0201a0e <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201a20:	fea959e3          	bge	s2,a0,ffffffffc0201a12 <readline+0x54>
ffffffffc0201a24:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201a26:	e42a                	sd	a0,8(sp)
ffffffffc0201a28:	ec0fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i ++] = c;
ffffffffc0201a2c:	6522                	ld	a0,8(sp)
ffffffffc0201a2e:	009b87b3          	add	a5,s7,s1
ffffffffc0201a32:	2485                	addiw	s1,s1,1
ffffffffc0201a34:	00a78023          	sb	a0,0(a5)
ffffffffc0201a38:	bf7d                	j	ffffffffc02019f6 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201a3a:	01550463          	beq	a0,s5,ffffffffc0201a42 <readline+0x84>
ffffffffc0201a3e:	fb651ce3          	bne	a0,s6,ffffffffc02019f6 <readline+0x38>
            cputchar(c);
ffffffffc0201a42:	ea6fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i] = '\0';
ffffffffc0201a46:	00004517          	auipc	a0,0x4
ffffffffc0201a4a:	5e250513          	addi	a0,a0,1506 # ffffffffc0206028 <buf>
ffffffffc0201a4e:	94aa                	add	s1,s1,a0
ffffffffc0201a50:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201a54:	60a6                	ld	ra,72(sp)
ffffffffc0201a56:	6486                	ld	s1,64(sp)
ffffffffc0201a58:	7962                	ld	s2,56(sp)
ffffffffc0201a5a:	79c2                	ld	s3,48(sp)
ffffffffc0201a5c:	7a22                	ld	s4,40(sp)
ffffffffc0201a5e:	7a82                	ld	s5,32(sp)
ffffffffc0201a60:	6b62                	ld	s6,24(sp)
ffffffffc0201a62:	6bc2                	ld	s7,16(sp)
ffffffffc0201a64:	6161                	addi	sp,sp,80
ffffffffc0201a66:	8082                	ret
            cputchar(c);
ffffffffc0201a68:	4521                	li	a0,8
ffffffffc0201a6a:	e7efe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            i --;
ffffffffc0201a6e:	34fd                	addiw	s1,s1,-1
ffffffffc0201a70:	b759                	j	ffffffffc02019f6 <readline+0x38>

ffffffffc0201a72 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201a72:	4781                	li	a5,0
ffffffffc0201a74:	00004717          	auipc	a4,0x4
ffffffffc0201a78:	59473703          	ld	a4,1428(a4) # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201a7c:	88ba                	mv	a7,a4
ffffffffc0201a7e:	852a                	mv	a0,a0
ffffffffc0201a80:	85be                	mv	a1,a5
ffffffffc0201a82:	863e                	mv	a2,a5
ffffffffc0201a84:	00000073          	ecall
ffffffffc0201a88:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201a8a:	8082                	ret

ffffffffc0201a8c <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201a8c:	4781                	li	a5,0
ffffffffc0201a8e:	00005717          	auipc	a4,0x5
ffffffffc0201a92:	9e273703          	ld	a4,-1566(a4) # ffffffffc0206470 <SBI_SET_TIMER>
ffffffffc0201a96:	88ba                	mv	a7,a4
ffffffffc0201a98:	852a                	mv	a0,a0
ffffffffc0201a9a:	85be                	mv	a1,a5
ffffffffc0201a9c:	863e                	mv	a2,a5
ffffffffc0201a9e:	00000073          	ecall
ffffffffc0201aa2:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201aa4:	8082                	ret

ffffffffc0201aa6 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201aa6:	4501                	li	a0,0
ffffffffc0201aa8:	00004797          	auipc	a5,0x4
ffffffffc0201aac:	5587b783          	ld	a5,1368(a5) # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
ffffffffc0201ab0:	88be                	mv	a7,a5
ffffffffc0201ab2:	852a                	mv	a0,a0
ffffffffc0201ab4:	85aa                	mv	a1,a0
ffffffffc0201ab6:	862a                	mv	a2,a0
ffffffffc0201ab8:	00000073          	ecall
ffffffffc0201abc:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201abe:	2501                	sext.w	a0,a0
ffffffffc0201ac0:	8082                	ret

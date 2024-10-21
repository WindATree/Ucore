
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
ffffffffc0200036:	fde50513          	addi	a0,a0,-34 # ffffffffc0206010 <free_buddy>
ffffffffc020003a:	00006617          	auipc	a2,0x6
ffffffffc020003e:	53660613          	addi	a2,a2,1334 # ffffffffc0206570 <end>
int kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
int kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	4e2010ef          	jal	ra,ffffffffc020152c <memset>
    cons_init();  // init the console
ffffffffc020004e:	3fc000ef          	jal	ra,ffffffffc020044a <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200052:	00002517          	auipc	a0,0x2
ffffffffc0200056:	9de50513          	addi	a0,a0,-1570 # ffffffffc0201a30 <etext>
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
ffffffffc02000a6:	504010ef          	jal	ra,ffffffffc02015aa <vprintfmt>
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
ffffffffc02000dc:	4ce010ef          	jal	ra,ffffffffc02015aa <vprintfmt>
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
ffffffffc020013e:	3e630313          	addi	t1,t1,998 # ffffffffc0206520 <is_panic>
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
ffffffffc020016c:	8e850513          	addi	a0,a0,-1816 # ffffffffc0201a50 <etext+0x20>
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
ffffffffc0200182:	55250513          	addi	a0,a0,1362 # ffffffffc02026d0 <commands+0xa28>
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
ffffffffc020019c:	8d850513          	addi	a0,a0,-1832 # ffffffffc0201a70 <etext+0x40>
void print_kerninfo(void) {
ffffffffc02001a0:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02001a2:	f11ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc02001a6:	00000597          	auipc	a1,0x0
ffffffffc02001aa:	e8c58593          	addi	a1,a1,-372 # ffffffffc0200032 <kern_init>
ffffffffc02001ae:	00002517          	auipc	a0,0x2
ffffffffc02001b2:	8e250513          	addi	a0,a0,-1822 # ffffffffc0201a90 <etext+0x60>
ffffffffc02001b6:	efdff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02001ba:	00002597          	auipc	a1,0x2
ffffffffc02001be:	87658593          	addi	a1,a1,-1930 # ffffffffc0201a30 <etext>
ffffffffc02001c2:	00002517          	auipc	a0,0x2
ffffffffc02001c6:	8ee50513          	addi	a0,a0,-1810 # ffffffffc0201ab0 <etext+0x80>
ffffffffc02001ca:	ee9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02001ce:	00006597          	auipc	a1,0x6
ffffffffc02001d2:	e4258593          	addi	a1,a1,-446 # ffffffffc0206010 <free_buddy>
ffffffffc02001d6:	00002517          	auipc	a0,0x2
ffffffffc02001da:	8fa50513          	addi	a0,a0,-1798 # ffffffffc0201ad0 <etext+0xa0>
ffffffffc02001de:	ed5ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001e2:	00006597          	auipc	a1,0x6
ffffffffc02001e6:	38e58593          	addi	a1,a1,910 # ffffffffc0206570 <end>
ffffffffc02001ea:	00002517          	auipc	a0,0x2
ffffffffc02001ee:	90650513          	addi	a0,a0,-1786 # ffffffffc0201af0 <etext+0xc0>
ffffffffc02001f2:	ec1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001f6:	00006597          	auipc	a1,0x6
ffffffffc02001fa:	77958593          	addi	a1,a1,1913 # ffffffffc020696f <end+0x3ff>
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
ffffffffc020021c:	8f850513          	addi	a0,a0,-1800 # ffffffffc0201b10 <etext+0xe0>
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
ffffffffc020022a:	91a60613          	addi	a2,a2,-1766 # ffffffffc0201b40 <etext+0x110>
ffffffffc020022e:	04e00593          	li	a1,78
ffffffffc0200232:	00002517          	auipc	a0,0x2
ffffffffc0200236:	92650513          	addi	a0,a0,-1754 # ffffffffc0201b58 <etext+0x128>
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
ffffffffc0200246:	92e60613          	addi	a2,a2,-1746 # ffffffffc0201b70 <etext+0x140>
ffffffffc020024a:	00002597          	auipc	a1,0x2
ffffffffc020024e:	94658593          	addi	a1,a1,-1722 # ffffffffc0201b90 <etext+0x160>
ffffffffc0200252:	00002517          	auipc	a0,0x2
ffffffffc0200256:	94650513          	addi	a0,a0,-1722 # ffffffffc0201b98 <etext+0x168>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020025a:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020025c:	e57ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc0200260:	00002617          	auipc	a2,0x2
ffffffffc0200264:	94860613          	addi	a2,a2,-1720 # ffffffffc0201ba8 <etext+0x178>
ffffffffc0200268:	00002597          	auipc	a1,0x2
ffffffffc020026c:	96858593          	addi	a1,a1,-1688 # ffffffffc0201bd0 <etext+0x1a0>
ffffffffc0200270:	00002517          	auipc	a0,0x2
ffffffffc0200274:	92850513          	addi	a0,a0,-1752 # ffffffffc0201b98 <etext+0x168>
ffffffffc0200278:	e3bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020027c:	00002617          	auipc	a2,0x2
ffffffffc0200280:	96460613          	addi	a2,a2,-1692 # ffffffffc0201be0 <etext+0x1b0>
ffffffffc0200284:	00002597          	auipc	a1,0x2
ffffffffc0200288:	97c58593          	addi	a1,a1,-1668 # ffffffffc0201c00 <etext+0x1d0>
ffffffffc020028c:	00002517          	auipc	a0,0x2
ffffffffc0200290:	90c50513          	addi	a0,a0,-1780 # ffffffffc0201b98 <etext+0x168>
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
ffffffffc02002ca:	94a50513          	addi	a0,a0,-1718 # ffffffffc0201c10 <etext+0x1e0>
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
ffffffffc02002ec:	95050513          	addi	a0,a0,-1712 # ffffffffc0201c38 <etext+0x208>
ffffffffc02002f0:	dc3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (tf != NULL) {
ffffffffc02002f4:	000b8563          	beqz	s7,ffffffffc02002fe <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002f8:	855e                	mv	a0,s7
ffffffffc02002fa:	348000ef          	jal	ra,ffffffffc0200642 <print_trapframe>
ffffffffc02002fe:	00002c17          	auipc	s8,0x2
ffffffffc0200302:	9aac0c13          	addi	s8,s8,-1622 # ffffffffc0201ca8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200306:	00002917          	auipc	s2,0x2
ffffffffc020030a:	95a90913          	addi	s2,s2,-1702 # ffffffffc0201c60 <etext+0x230>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020030e:	00002497          	auipc	s1,0x2
ffffffffc0200312:	95a48493          	addi	s1,s1,-1702 # ffffffffc0201c68 <etext+0x238>
        if (argc == MAXARGS - 1) {
ffffffffc0200316:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200318:	00002b17          	auipc	s6,0x2
ffffffffc020031c:	958b0b13          	addi	s6,s6,-1704 # ffffffffc0201c70 <etext+0x240>
        argv[argc ++] = buf;
ffffffffc0200320:	00002a17          	auipc	s4,0x2
ffffffffc0200324:	870a0a13          	addi	s4,s4,-1936 # ffffffffc0201b90 <etext+0x160>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200328:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020032a:	854a                	mv	a0,s2
ffffffffc020032c:	600010ef          	jal	ra,ffffffffc020192c <readline>
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
ffffffffc0200346:	966d0d13          	addi	s10,s10,-1690 # ffffffffc0201ca8 <commands>
        argv[argc ++] = buf;
ffffffffc020034a:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020034c:	4401                	li	s0,0
ffffffffc020034e:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200350:	1a8010ef          	jal	ra,ffffffffc02014f8 <strcmp>
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
ffffffffc0200364:	194010ef          	jal	ra,ffffffffc02014f8 <strcmp>
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
ffffffffc02003a2:	174010ef          	jal	ra,ffffffffc0201516 <strchr>
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
ffffffffc02003e0:	136010ef          	jal	ra,ffffffffc0201516 <strchr>
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
ffffffffc02003fe:	89650513          	addi	a0,a0,-1898 # ffffffffc0201c90 <etext+0x260>
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
ffffffffc0200420:	5da010ef          	jal	ra,ffffffffc02019fa <sbi_set_timer>
}
ffffffffc0200424:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc0200426:	00006797          	auipc	a5,0x6
ffffffffc020042a:	1007b123          	sd	zero,258(a5) # ffffffffc0206528 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020042e:	00002517          	auipc	a0,0x2
ffffffffc0200432:	8c250513          	addi	a0,a0,-1854 # ffffffffc0201cf0 <commands+0x48>
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
ffffffffc0200446:	5b40106f          	j	ffffffffc02019fa <sbi_set_timer>

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
ffffffffc0200450:	5900106f          	j	ffffffffc02019e0 <sbi_console_putchar>

ffffffffc0200454 <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc0200454:	5c00106f          	j	ffffffffc0201a14 <sbi_console_getchar>

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
ffffffffc0200482:	89250513          	addi	a0,a0,-1902 # ffffffffc0201d10 <commands+0x68>
void print_regs(struct pushregs *gpr) {
ffffffffc0200486:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200488:	c2bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020048c:	640c                	ld	a1,8(s0)
ffffffffc020048e:	00002517          	auipc	a0,0x2
ffffffffc0200492:	89a50513          	addi	a0,a0,-1894 # ffffffffc0201d28 <commands+0x80>
ffffffffc0200496:	c1dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020049a:	680c                	ld	a1,16(s0)
ffffffffc020049c:	00002517          	auipc	a0,0x2
ffffffffc02004a0:	8a450513          	addi	a0,a0,-1884 # ffffffffc0201d40 <commands+0x98>
ffffffffc02004a4:	c0fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02004a8:	6c0c                	ld	a1,24(s0)
ffffffffc02004aa:	00002517          	auipc	a0,0x2
ffffffffc02004ae:	8ae50513          	addi	a0,a0,-1874 # ffffffffc0201d58 <commands+0xb0>
ffffffffc02004b2:	c01ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02004b6:	700c                	ld	a1,32(s0)
ffffffffc02004b8:	00002517          	auipc	a0,0x2
ffffffffc02004bc:	8b850513          	addi	a0,a0,-1864 # ffffffffc0201d70 <commands+0xc8>
ffffffffc02004c0:	bf3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02004c4:	740c                	ld	a1,40(s0)
ffffffffc02004c6:	00002517          	auipc	a0,0x2
ffffffffc02004ca:	8c250513          	addi	a0,a0,-1854 # ffffffffc0201d88 <commands+0xe0>
ffffffffc02004ce:	be5ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02004d2:	780c                	ld	a1,48(s0)
ffffffffc02004d4:	00002517          	auipc	a0,0x2
ffffffffc02004d8:	8cc50513          	addi	a0,a0,-1844 # ffffffffc0201da0 <commands+0xf8>
ffffffffc02004dc:	bd7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02004e0:	7c0c                	ld	a1,56(s0)
ffffffffc02004e2:	00002517          	auipc	a0,0x2
ffffffffc02004e6:	8d650513          	addi	a0,a0,-1834 # ffffffffc0201db8 <commands+0x110>
ffffffffc02004ea:	bc9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02004ee:	602c                	ld	a1,64(s0)
ffffffffc02004f0:	00002517          	auipc	a0,0x2
ffffffffc02004f4:	8e050513          	addi	a0,a0,-1824 # ffffffffc0201dd0 <commands+0x128>
ffffffffc02004f8:	bbbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02004fc:	642c                	ld	a1,72(s0)
ffffffffc02004fe:	00002517          	auipc	a0,0x2
ffffffffc0200502:	8ea50513          	addi	a0,a0,-1814 # ffffffffc0201de8 <commands+0x140>
ffffffffc0200506:	badff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020050a:	682c                	ld	a1,80(s0)
ffffffffc020050c:	00002517          	auipc	a0,0x2
ffffffffc0200510:	8f450513          	addi	a0,a0,-1804 # ffffffffc0201e00 <commands+0x158>
ffffffffc0200514:	b9fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200518:	6c2c                	ld	a1,88(s0)
ffffffffc020051a:	00002517          	auipc	a0,0x2
ffffffffc020051e:	8fe50513          	addi	a0,a0,-1794 # ffffffffc0201e18 <commands+0x170>
ffffffffc0200522:	b91ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200526:	702c                	ld	a1,96(s0)
ffffffffc0200528:	00002517          	auipc	a0,0x2
ffffffffc020052c:	90850513          	addi	a0,a0,-1784 # ffffffffc0201e30 <commands+0x188>
ffffffffc0200530:	b83ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200534:	742c                	ld	a1,104(s0)
ffffffffc0200536:	00002517          	auipc	a0,0x2
ffffffffc020053a:	91250513          	addi	a0,a0,-1774 # ffffffffc0201e48 <commands+0x1a0>
ffffffffc020053e:	b75ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200542:	782c                	ld	a1,112(s0)
ffffffffc0200544:	00002517          	auipc	a0,0x2
ffffffffc0200548:	91c50513          	addi	a0,a0,-1764 # ffffffffc0201e60 <commands+0x1b8>
ffffffffc020054c:	b67ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200550:	7c2c                	ld	a1,120(s0)
ffffffffc0200552:	00002517          	auipc	a0,0x2
ffffffffc0200556:	92650513          	addi	a0,a0,-1754 # ffffffffc0201e78 <commands+0x1d0>
ffffffffc020055a:	b59ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020055e:	604c                	ld	a1,128(s0)
ffffffffc0200560:	00002517          	auipc	a0,0x2
ffffffffc0200564:	93050513          	addi	a0,a0,-1744 # ffffffffc0201e90 <commands+0x1e8>
ffffffffc0200568:	b4bff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020056c:	644c                	ld	a1,136(s0)
ffffffffc020056e:	00002517          	auipc	a0,0x2
ffffffffc0200572:	93a50513          	addi	a0,a0,-1734 # ffffffffc0201ea8 <commands+0x200>
ffffffffc0200576:	b3dff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020057a:	684c                	ld	a1,144(s0)
ffffffffc020057c:	00002517          	auipc	a0,0x2
ffffffffc0200580:	94450513          	addi	a0,a0,-1724 # ffffffffc0201ec0 <commands+0x218>
ffffffffc0200584:	b2fff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200588:	6c4c                	ld	a1,152(s0)
ffffffffc020058a:	00002517          	auipc	a0,0x2
ffffffffc020058e:	94e50513          	addi	a0,a0,-1714 # ffffffffc0201ed8 <commands+0x230>
ffffffffc0200592:	b21ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200596:	704c                	ld	a1,160(s0)
ffffffffc0200598:	00002517          	auipc	a0,0x2
ffffffffc020059c:	95850513          	addi	a0,a0,-1704 # ffffffffc0201ef0 <commands+0x248>
ffffffffc02005a0:	b13ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02005a4:	744c                	ld	a1,168(s0)
ffffffffc02005a6:	00002517          	auipc	a0,0x2
ffffffffc02005aa:	96250513          	addi	a0,a0,-1694 # ffffffffc0201f08 <commands+0x260>
ffffffffc02005ae:	b05ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02005b2:	784c                	ld	a1,176(s0)
ffffffffc02005b4:	00002517          	auipc	a0,0x2
ffffffffc02005b8:	96c50513          	addi	a0,a0,-1684 # ffffffffc0201f20 <commands+0x278>
ffffffffc02005bc:	af7ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02005c0:	7c4c                	ld	a1,184(s0)
ffffffffc02005c2:	00002517          	auipc	a0,0x2
ffffffffc02005c6:	97650513          	addi	a0,a0,-1674 # ffffffffc0201f38 <commands+0x290>
ffffffffc02005ca:	ae9ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02005ce:	606c                	ld	a1,192(s0)
ffffffffc02005d0:	00002517          	auipc	a0,0x2
ffffffffc02005d4:	98050513          	addi	a0,a0,-1664 # ffffffffc0201f50 <commands+0x2a8>
ffffffffc02005d8:	adbff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02005dc:	646c                	ld	a1,200(s0)
ffffffffc02005de:	00002517          	auipc	a0,0x2
ffffffffc02005e2:	98a50513          	addi	a0,a0,-1654 # ffffffffc0201f68 <commands+0x2c0>
ffffffffc02005e6:	acdff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02005ea:	686c                	ld	a1,208(s0)
ffffffffc02005ec:	00002517          	auipc	a0,0x2
ffffffffc02005f0:	99450513          	addi	a0,a0,-1644 # ffffffffc0201f80 <commands+0x2d8>
ffffffffc02005f4:	abfff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02005f8:	6c6c                	ld	a1,216(s0)
ffffffffc02005fa:	00002517          	auipc	a0,0x2
ffffffffc02005fe:	99e50513          	addi	a0,a0,-1634 # ffffffffc0201f98 <commands+0x2f0>
ffffffffc0200602:	ab1ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200606:	706c                	ld	a1,224(s0)
ffffffffc0200608:	00002517          	auipc	a0,0x2
ffffffffc020060c:	9a850513          	addi	a0,a0,-1624 # ffffffffc0201fb0 <commands+0x308>
ffffffffc0200610:	aa3ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200614:	746c                	ld	a1,232(s0)
ffffffffc0200616:	00002517          	auipc	a0,0x2
ffffffffc020061a:	9b250513          	addi	a0,a0,-1614 # ffffffffc0201fc8 <commands+0x320>
ffffffffc020061e:	a95ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200622:	786c                	ld	a1,240(s0)
ffffffffc0200624:	00002517          	auipc	a0,0x2
ffffffffc0200628:	9bc50513          	addi	a0,a0,-1604 # ffffffffc0201fe0 <commands+0x338>
ffffffffc020062c:	a87ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200630:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200632:	6402                	ld	s0,0(sp)
ffffffffc0200634:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200636:	00002517          	auipc	a0,0x2
ffffffffc020063a:	9c250513          	addi	a0,a0,-1598 # ffffffffc0201ff8 <commands+0x350>
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
ffffffffc020064e:	9c650513          	addi	a0,a0,-1594 # ffffffffc0202010 <commands+0x368>
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
ffffffffc0200666:	9c650513          	addi	a0,a0,-1594 # ffffffffc0202028 <commands+0x380>
ffffffffc020066a:	a49ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020066e:	10843583          	ld	a1,264(s0)
ffffffffc0200672:	00002517          	auipc	a0,0x2
ffffffffc0200676:	9ce50513          	addi	a0,a0,-1586 # ffffffffc0202040 <commands+0x398>
ffffffffc020067a:	a39ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020067e:	11043583          	ld	a1,272(s0)
ffffffffc0200682:	00002517          	auipc	a0,0x2
ffffffffc0200686:	9d650513          	addi	a0,a0,-1578 # ffffffffc0202058 <commands+0x3b0>
ffffffffc020068a:	a29ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020068e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200692:	6402                	ld	s0,0(sp)
ffffffffc0200694:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200696:	00002517          	auipc	a0,0x2
ffffffffc020069a:	9da50513          	addi	a0,a0,-1574 # ffffffffc0202070 <commands+0x3c8>
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
ffffffffc02006b4:	aa070713          	addi	a4,a4,-1376 # ffffffffc0202150 <commands+0x4a8>
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
ffffffffc02006c6:	a2650513          	addi	a0,a0,-1498 # ffffffffc02020e8 <commands+0x440>
ffffffffc02006ca:	b2e5                	j	ffffffffc02000b2 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02006cc:	00002517          	auipc	a0,0x2
ffffffffc02006d0:	9fc50513          	addi	a0,a0,-1540 # ffffffffc02020c8 <commands+0x420>
ffffffffc02006d4:	baf9                	j	ffffffffc02000b2 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02006d6:	00002517          	auipc	a0,0x2
ffffffffc02006da:	9b250513          	addi	a0,a0,-1614 # ffffffffc0202088 <commands+0x3e0>
ffffffffc02006de:	bad1                	j	ffffffffc02000b2 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc02006e0:	00002517          	auipc	a0,0x2
ffffffffc02006e4:	a2850513          	addi	a0,a0,-1496 # ffffffffc0202108 <commands+0x460>
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
ffffffffc02006f6:	e3668693          	addi	a3,a3,-458 # ffffffffc0206528 <ticks>
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
ffffffffc0200714:	a2050513          	addi	a0,a0,-1504 # ffffffffc0202130 <commands+0x488>
ffffffffc0200718:	ba69                	j	ffffffffc02000b2 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc020071a:	00002517          	auipc	a0,0x2
ffffffffc020071e:	98e50513          	addi	a0,a0,-1650 # ffffffffc02020a8 <commands+0x400>
ffffffffc0200722:	ba41                	j	ffffffffc02000b2 <cprintf>
            print_trapframe(tf);
ffffffffc0200724:	bf39                	j	ffffffffc0200642 <print_trapframe>
}
ffffffffc0200726:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200728:	06400593          	li	a1,100
ffffffffc020072c:	00002517          	auipc	a0,0x2
ffffffffc0200730:	9f450513          	addi	a0,a0,-1548 # ffffffffc0202120 <commands+0x478>
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
ffffffffc020080e:	d3e7b783          	ld	a5,-706(a5) # ffffffffc0206548 <pmm_manager>
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
ffffffffc0200826:	d267b783          	ld	a5,-730(a5) # ffffffffc0206548 <pmm_manager>
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
ffffffffc020084c:	d007b783          	ld	a5,-768(a5) # ffffffffc0206548 <pmm_manager>
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
ffffffffc0200868:	ce47b783          	ld	a5,-796(a5) # ffffffffc0206548 <pmm_manager>
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
ffffffffc020088a:	cc27b783          	ld	a5,-830(a5) # ffffffffc0206548 <pmm_manager>
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
ffffffffc02008a0:	cac7b783          	ld	a5,-852(a5) # ffffffffc0206548 <pmm_manager>
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
    pmm_manager = &buddy_pmm_manager;
ffffffffc02008b8:	00002797          	auipc	a5,0x2
ffffffffc02008bc:	20878793          	addi	a5,a5,520 # ffffffffc0202ac0 <buddy_pmm_manager>
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
ffffffffc02008ca:	8ba50513          	addi	a0,a0,-1862 # ffffffffc0202180 <commands+0x4d8>
    pmm_manager = &buddy_pmm_manager;
ffffffffc02008ce:	00006997          	auipc	s3,0x6
ffffffffc02008d2:	c7a98993          	addi	s3,s3,-902 # ffffffffc0206548 <pmm_manager>
void pmm_init(void) {
ffffffffc02008d6:	e486                	sd	ra,72(sp)
ffffffffc02008d8:	e0a2                	sd	s0,64(sp)
ffffffffc02008da:	f84a                	sd	s2,48(sp)
ffffffffc02008dc:	ec56                	sd	s5,24(sp)
ffffffffc02008de:	e85a                	sd	s6,16(sp)
    pmm_manager = &buddy_pmm_manager;
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
ffffffffc02008f6:	c6e90913          	addi	s2,s2,-914 # ffffffffc0206560 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc02008fa:	00006a97          	auipc	s5,0x6
ffffffffc02008fe:	c3ea8a93          	addi	s5,s5,-962 # ffffffffc0206538 <npage>
    pmm_manager->init();
ffffffffc0200902:	679c                	ld	a5,8(a5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200904:	00006417          	auipc	s0,0x6
ffffffffc0200908:	c3c40413          	addi	s0,s0,-964 # ffffffffc0206540 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020090c:	fff80b37          	lui	s6,0xfff80
    pmm_manager->init();
ffffffffc0200910:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200912:	57f5                	li	a5,-3
ffffffffc0200914:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0200916:	00002517          	auipc	a0,0x2
ffffffffc020091a:	88250513          	addi	a0,a0,-1918 # ffffffffc0202198 <commands+0x4f0>
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
ffffffffc020093a:	87a50513          	addi	a0,a0,-1926 # ffffffffc02021b0 <commands+0x508>
ffffffffc020093e:	f74ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200942:	777d                	lui	a4,0xfffff
ffffffffc0200944:	00007797          	auipc	a5,0x7
ffffffffc0200948:	c2b78793          	addi	a5,a5,-981 # ffffffffc020756f <end+0xfff>
ffffffffc020094c:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc020094e:	00088737          	lui	a4,0x88
ffffffffc0200952:	00eab023          	sd	a4,0(s5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200956:	00006597          	auipc	a1,0x6
ffffffffc020095a:	c1a58593          	addi	a1,a1,-998 # ffffffffc0206570 <end>
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
ffffffffc0200978:	02868693          	addi	a3,a3,40
ffffffffc020097c:	01678633          	add	a2,a5,s6
ffffffffc0200980:	fec764e3          	bltu	a4,a2,ffffffffc0200968 <pmm_init+0xb0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200984:	6004                	ld	s1,0(s0)
ffffffffc0200986:	00279693          	slli	a3,a5,0x2
ffffffffc020098a:	97b6                	add	a5,a5,a3
ffffffffc020098c:	fec006b7          	lui	a3,0xfec00
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
ffffffffc02009ba:	86250513          	addi	a0,a0,-1950 # ffffffffc0202218 <commands+0x570>
ffffffffc02009be:	ef4ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("pages:     0x%016lx\n", (uint64_t)PADDR(pages));
ffffffffc02009c2:	6014                	ld	a3,0(s0)
ffffffffc02009c4:	1376e963          	bltu	a3,s7,ffffffffc0200af6 <pmm_init+0x23e>
ffffffffc02009c8:	00093583          	ld	a1,0(s2)
ffffffffc02009cc:	00002517          	auipc	a0,0x2
ffffffffc02009d0:	86450513          	addi	a0,a0,-1948 # ffffffffc0202230 <commands+0x588>
    cprintf("mem_end:   0x%016lx\n", mem_end);
ffffffffc02009d4:	4bc5                	li	s7,17
    cprintf("pages:     0x%016lx\n", (uint64_t)PADDR(pages));
ffffffffc02009d6:	40b685b3          	sub	a1,a3,a1
ffffffffc02009da:	ed8ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("freemem:   0x%016lx\n", freemem);
ffffffffc02009de:	85a6                	mv	a1,s1
ffffffffc02009e0:	00002517          	auipc	a0,0x2
ffffffffc02009e4:	86850513          	addi	a0,a0,-1944 # ffffffffc0202248 <commands+0x5a0>
ffffffffc02009e8:	ecaff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("mem_begin: 0x%016lx\n", mem_begin);
ffffffffc02009ec:	85d2                	mv	a1,s4
ffffffffc02009ee:	00002517          	auipc	a0,0x2
ffffffffc02009f2:	87250513          	addi	a0,a0,-1934 # ffffffffc0202260 <commands+0x5b8>
ffffffffc02009f6:	ebcff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    cprintf("mem_end:   0x%016lx\n", mem_end);
ffffffffc02009fa:	01bb9593          	slli	a1,s7,0x1b
    if (freemem < mem_end) {
ffffffffc02009fe:	8bae                	mv	s7,a1
    cprintf("mem_end:   0x%016lx\n", mem_end);
ffffffffc0200a00:	00002517          	auipc	a0,0x2
ffffffffc0200a04:	87850513          	addi	a0,a0,-1928 # ffffffffc0202278 <commands+0x5d0>
ffffffffc0200a08:	eaaff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (freemem < mem_end) {
ffffffffc0200a0c:	0774e063          	bltu	s1,s7,ffffffffc0200a6c <pmm_init+0x1b4>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200a10:	0009b783          	ld	a5,0(s3)
ffffffffc0200a14:	7b9c                	ld	a5,48(a5)
ffffffffc0200a16:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200a18:	00002517          	auipc	a0,0x2
ffffffffc0200a1c:	8e050513          	addi	a0,a0,-1824 # ffffffffc02022f8 <commands+0x650>
ffffffffc0200a20:	e92ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200a24:	00004597          	auipc	a1,0x4
ffffffffc0200a28:	5dc58593          	addi	a1,a1,1500 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0200a2c:	00006797          	auipc	a5,0x6
ffffffffc0200a30:	b2b7b623          	sd	a1,-1236(a5) # ffffffffc0206558 <satp_virtual>
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
ffffffffc0200a5a:	aec7bd23          	sd	a2,-1286(a5) # ffffffffc0206550 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200a5e:	00002517          	auipc	a0,0x2
ffffffffc0200a62:	8ba50513          	addi	a0,a0,-1862 # ffffffffc0202318 <commands+0x670>
}
ffffffffc0200a66:	6161                	addi	sp,sp,80
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200a68:	e4aff06f          	j	ffffffffc02000b2 <cprintf>
        cprintf("Checkpoint reached: freemem < mem_end\n");
ffffffffc0200a6c:	00002517          	auipc	a0,0x2
ffffffffc0200a70:	82450513          	addi	a0,a0,-2012 # ffffffffc0202290 <commands+0x5e8>
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
ffffffffc0200a8e:	00279413          	slli	s0,a5,0x2
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
ffffffffc0200aae:	83e50513          	addi	a0,a0,-1986 # ffffffffc02022e8 <commands+0x640>
ffffffffc0200ab2:	e00ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    if (PPN(pa) >= npage) {
ffffffffc0200ab6:	000ab783          	ld	a5,0(s5)
ffffffffc0200aba:	02f4f263          	bgeu	s1,a5,ffffffffc0200ade <pmm_init+0x226>
        fppn=pa2page(mem_begin)-pages+nbase;
ffffffffc0200abe:	40345793          	srai	a5,s0,0x3
ffffffffc0200ac2:	00002417          	auipc	s0,0x2
ffffffffc0200ac6:	27e43403          	ld	s0,638(s0) # ffffffffc0202d40 <error_string+0x38>
ffffffffc0200aca:	028787b3          	mul	a5,a5,s0
ffffffffc0200ace:	00080737          	lui	a4,0x80
ffffffffc0200ad2:	97ba                	add	a5,a5,a4
ffffffffc0200ad4:	00006717          	auipc	a4,0x6
ffffffffc0200ad8:	a4f73e23          	sd	a5,-1444(a4) # ffffffffc0206530 <fppn>
ffffffffc0200adc:	bf15                	j	ffffffffc0200a10 <pmm_init+0x158>
        panic("pa2page called with invalid pa");
ffffffffc0200ade:	00001617          	auipc	a2,0x1
ffffffffc0200ae2:	7da60613          	addi	a2,a2,2010 # ffffffffc02022b8 <commands+0x610>
ffffffffc0200ae6:	06b00593          	li	a1,107
ffffffffc0200aea:	00001517          	auipc	a0,0x1
ffffffffc0200aee:	7ee50513          	addi	a0,a0,2030 # ffffffffc02022d8 <commands+0x630>
ffffffffc0200af2:	e48ff0ef          	jal	ra,ffffffffc020013a <__panic>
    cprintf("pages:     0x%016lx\n", (uint64_t)PADDR(pages));
ffffffffc0200af6:	00001617          	auipc	a2,0x1
ffffffffc0200afa:	6ea60613          	addi	a2,a2,1770 # ffffffffc02021e0 <commands+0x538>
ffffffffc0200afe:	09300593          	li	a1,147
ffffffffc0200b02:	00001517          	auipc	a0,0x1
ffffffffc0200b06:	70650513          	addi	a0,a0,1798 # ffffffffc0202208 <commands+0x560>
ffffffffc0200b0a:	e30ff0ef          	jal	ra,ffffffffc020013a <__panic>
    cprintf("kern_end:  0x%016lx\n", (uint64_t)PADDR(end));
ffffffffc0200b0e:	00006697          	auipc	a3,0x6
ffffffffc0200b12:	a6268693          	addi	a3,a3,-1438 # ffffffffc0206570 <end>
ffffffffc0200b16:	00001617          	auipc	a2,0x1
ffffffffc0200b1a:	6ca60613          	addi	a2,a2,1738 # ffffffffc02021e0 <commands+0x538>
ffffffffc0200b1e:	09200593          	li	a1,146
ffffffffc0200b22:	00001517          	auipc	a0,0x1
ffffffffc0200b26:	6e650513          	addi	a0,a0,1766 # ffffffffc0202208 <commands+0x560>
ffffffffc0200b2a:	e10ff0ef          	jal	ra,ffffffffc020013a <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200b2e:	86a6                	mv	a3,s1
ffffffffc0200b30:	00001617          	auipc	a2,0x1
ffffffffc0200b34:	6b060613          	addi	a2,a2,1712 # ffffffffc02021e0 <commands+0x538>
ffffffffc0200b38:	08d00593          	li	a1,141
ffffffffc0200b3c:	00001517          	auipc	a0,0x1
ffffffffc0200b40:	6cc50513          	addi	a0,a0,1740 # ffffffffc0202208 <commands+0x560>
ffffffffc0200b44:	df6ff0ef          	jal	ra,ffffffffc020013a <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200b48:	86ae                	mv	a3,a1
ffffffffc0200b4a:	00001617          	auipc	a2,0x1
ffffffffc0200b4e:	69660613          	addi	a2,a2,1686 # ffffffffc02021e0 <commands+0x538>
ffffffffc0200b52:	0b100593          	li	a1,177
ffffffffc0200b56:	00001517          	auipc	a0,0x1
ffffffffc0200b5a:	6b250513          	addi	a0,a0,1714 # ffffffffc0202208 <commands+0x560>
ffffffffc0200b5e:	ddcff0ef          	jal	ra,ffffffffc020013a <__panic>

ffffffffc0200b62 <buddy_system_init>:
    }
    return count;
}

static void buddy_system_init(void){
    for(int i=0;i<16;i++){
ffffffffc0200b62:	00005797          	auipc	a5,0x5
ffffffffc0200b66:	4b678793          	addi	a5,a5,1206 # ffffffffc0206018 <free_buddy+0x8>
ffffffffc0200b6a:	00005717          	auipc	a4,0x5
ffffffffc0200b6e:	5ae70713          	addi	a4,a4,1454 # ffffffffc0206118 <free_buddy+0x108>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200b72:	e79c                	sd	a5,8(a5)
ffffffffc0200b74:	e39c                	sd	a5,0(a5)
ffffffffc0200b76:	07c1                	addi	a5,a5,16
ffffffffc0200b78:	fee79de3          	bne	a5,a4,ffffffffc0200b72 <buddy_system_init+0x10>
        list_init(free_list+i);
    }
    nr_free=0;
ffffffffc0200b7c:	00005797          	auipc	a5,0x5
ffffffffc0200b80:	5807ae23          	sw	zero,1436(a5) # ffffffffc0206118 <free_buddy+0x108>
    order=0;
ffffffffc0200b84:	00005797          	auipc	a5,0x5
ffffffffc0200b88:	4807a623          	sw	zero,1164(a5) # ffffffffc0206010 <free_buddy>
}
ffffffffc0200b8c:	8082                	ret

ffffffffc0200b8e <buddy_nr_free_pages>:
    return page+(ppn-page2ppn(page));
}

static size_t buddy_nr_free_pages(void){
    return nr_free;
}
ffffffffc0200b8e:	00005517          	auipc	a0,0x5
ffffffffc0200b92:	58a56503          	lwu	a0,1418(a0) # ffffffffc0206118 <free_buddy+0x108>
ffffffffc0200b96:	8082                	ret

ffffffffc0200b98 <buddy_system_memmap>:
void buddy_system_memmap(struct Page *base, size_t n) {
ffffffffc0200b98:	1141                	addi	sp,sp,-16
ffffffffc0200b9a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200b9c:	cdc5                	beqz	a1,ffffffffc0200c54 <buddy_system_memmap+0xbc>
    order = Get_Power_Of_2(n);
ffffffffc0200b9e:	0005879b          	sext.w	a5,a1
    while(x>1){
ffffffffc0200ba2:	4705                	li	a4,1
ffffffffc0200ba4:	08f77363          	bgeu	a4,a5,ffffffffc0200c2a <buddy_system_memmap+0x92>
    uint32_t count=0;
ffffffffc0200ba8:	4681                	li	a3,0
        x=x>>1;
ffffffffc0200baa:	0017d79b          	srliw	a5,a5,0x1
        count++;
ffffffffc0200bae:	2685                	addiw	a3,a3,1
    while(x>1){
ffffffffc0200bb0:	fee79de3          	bne	a5,a4,ffffffffc0200baa <buddy_system_memmap+0x12>
    uint32_t real_n = 1 << order;
ffffffffc0200bb4:	4585                	li	a1,1
ffffffffc0200bb6:	00d595bb          	sllw	a1,a1,a3
    for (; p != base + real_n; p += 1) {
ffffffffc0200bba:	02059793          	slli	a5,a1,0x20
ffffffffc0200bbe:	9381                	srli	a5,a5,0x20
ffffffffc0200bc0:	00279613          	slli	a2,a5,0x2
ffffffffc0200bc4:	963e                	add	a2,a2,a5
ffffffffc0200bc6:	060e                	slli	a2,a2,0x3
    order = Get_Power_Of_2(n);
ffffffffc0200bc8:	00005817          	auipc	a6,0x5
ffffffffc0200bcc:	44880813          	addi	a6,a6,1096 # ffffffffc0206010 <free_buddy>
ffffffffc0200bd0:	00d82023          	sw	a3,0(a6)
    nr_free = real_n;
ffffffffc0200bd4:	10b82423          	sw	a1,264(a6)
    for (; p != base + real_n; p += 1) {
ffffffffc0200bd8:	962a                	add	a2,a2,a0
ffffffffc0200bda:	87aa                	mv	a5,a0
ffffffffc0200bdc:	00c50f63          	beq	a0,a2,ffffffffc0200bfa <buddy_system_memmap+0x62>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200be0:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));  // 确保页面已保留
ffffffffc0200be2:	8b05                	andi	a4,a4,1
ffffffffc0200be4:	cb21                	beqz	a4,ffffffffc0200c34 <buddy_system_memmap+0x9c>
        p->property = p->flags = 0;  // 清除属性和标志
ffffffffc0200be6:	0007b423          	sd	zero,8(a5)
ffffffffc0200bea:	0007a823          	sw	zero,16(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200bee:	0007a023          	sw	zero,0(a5)
    for (; p != base + real_n; p += 1) {
ffffffffc0200bf2:	02878793          	addi	a5,a5,40
ffffffffc0200bf6:	fec795e3          	bne	a5,a2,ffffffffc0200be0 <buddy_system_memmap+0x48>
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
ffffffffc0200bfa:	02069793          	slli	a5,a3,0x20
ffffffffc0200bfe:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0200c02:	00d80733          	add	a4,a6,a3
ffffffffc0200c06:	6b1c                	ld	a5,16(a4)
    list_add(&free_list[order], &base->page_link);  // 将块加入到空闲链表
ffffffffc0200c08:	01850613          	addi	a2,a0,24
ffffffffc0200c0c:	06a1                	addi	a3,a3,8
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0200c0e:	e390                	sd	a2,0(a5)
ffffffffc0200c10:	eb10                	sd	a2,16(a4)
ffffffffc0200c12:	96c2                	add	a3,a3,a6
    elm->next = next;
ffffffffc0200c14:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200c16:	ed14                	sd	a3,24(a0)
    base->property = real_n;
ffffffffc0200c18:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200c1a:	4789                	li	a5,2
ffffffffc0200c1c:	00850713          	addi	a4,a0,8
ffffffffc0200c20:	40f7302f          	amoor.d	zero,a5,(a4)
}
ffffffffc0200c24:	60a2                	ld	ra,8(sp)
ffffffffc0200c26:	0141                	addi	sp,sp,16
ffffffffc0200c28:	8082                	ret
    while(x>1){
ffffffffc0200c2a:	02800613          	li	a2,40
ffffffffc0200c2e:	4585                	li	a1,1
    uint32_t count=0;
ffffffffc0200c30:	4681                	li	a3,0
ffffffffc0200c32:	bf59                	j	ffffffffc0200bc8 <buddy_system_memmap+0x30>
        assert(PageReserved(p));  // 确保页面已保留
ffffffffc0200c34:	00001697          	auipc	a3,0x1
ffffffffc0200c38:	75c68693          	addi	a3,a3,1884 # ffffffffc0202390 <commands+0x6e8>
ffffffffc0200c3c:	00001617          	auipc	a2,0x1
ffffffffc0200c40:	72460613          	addi	a2,a2,1828 # ffffffffc0202360 <commands+0x6b8>
ffffffffc0200c44:	04300593          	li	a1,67
ffffffffc0200c48:	00001517          	auipc	a0,0x1
ffffffffc0200c4c:	73050513          	addi	a0,a0,1840 # ffffffffc0202378 <commands+0x6d0>
ffffffffc0200c50:	ceaff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(n > 0);
ffffffffc0200c54:	00001697          	auipc	a3,0x1
ffffffffc0200c58:	70468693          	addi	a3,a3,1796 # ffffffffc0202358 <commands+0x6b0>
ffffffffc0200c5c:	00001617          	auipc	a2,0x1
ffffffffc0200c60:	70460613          	addi	a2,a2,1796 # ffffffffc0202360 <commands+0x6b8>
ffffffffc0200c64:	03400593          	li	a1,52
ffffffffc0200c68:	00001517          	auipc	a0,0x1
ffffffffc0200c6c:	71050513          	addi	a0,a0,1808 # ffffffffc0202378 <commands+0x6d0>
ffffffffc0200c70:	ccaff0ef          	jal	ra,ffffffffc020013a <__panic>

ffffffffc0200c74 <buddy_alloc_pages>:
static struct Page * buddy_alloc_pages(size_t real_n) {
ffffffffc0200c74:	7139                	addi	sp,sp,-64
ffffffffc0200c76:	fc06                	sd	ra,56(sp)
ffffffffc0200c78:	f822                	sd	s0,48(sp)
ffffffffc0200c7a:	f426                	sd	s1,40(sp)
ffffffffc0200c7c:	f04a                	sd	s2,32(sp)
ffffffffc0200c7e:	ec4e                	sd	s3,24(sp)
ffffffffc0200c80:	e852                	sd	s4,16(sp)
ffffffffc0200c82:	e456                	sd	s5,8(sp)
ffffffffc0200c84:	e05a                	sd	s6,0(sp)
    assert(real_n > 0);
ffffffffc0200c86:	18050b63          	beqz	a0,ffffffffc0200e1c <buddy_alloc_pages+0x1a8>

    if (real_n > nr_free) {
ffffffffc0200c8a:	00005b17          	auipc	s6,0x5
ffffffffc0200c8e:	386b0b13          	addi	s6,s6,902 # ffffffffc0206010 <free_buddy>
ffffffffc0200c92:	108b2603          	lw	a2,264(s6)
ffffffffc0200c96:	85aa                	mv	a1,a0
ffffffffc0200c98:	02061793          	slli	a5,a2,0x20
ffffffffc0200c9c:	9381                	srli	a5,a5,0x20
ffffffffc0200c9e:	16a7e463          	bltu	a5,a0,ffffffffc0200e06 <buddy_alloc_pages+0x192>
        cprintf("buddy_alloc_pages: Not enough free pages. Needed: %lu, Available: %d\n", real_n, nr_free);
        return NULL;
    }

    struct Page *page = NULL;
    order = Is_Power_Of_2(real_n) ? Get_Power_Of_2(real_n) : Get_Power_Of_2(real_n) + 1;
ffffffffc0200ca2:	0005079b          	sext.w	a5,a0
    if(x>0&&(x&(x-1))==0){
ffffffffc0200ca6:	fff5061b          	addiw	a2,a0,-1
ffffffffc0200caa:	8e7d                	and	a2,a2,a5
ffffffffc0200cac:	2601                	sext.w	a2,a2
ffffffffc0200cae:	14060363          	beqz	a2,ffffffffc0200df4 <buddy_alloc_pages+0x180>
    while(x>1){
ffffffffc0200cb2:	4605                	li	a2,1
ffffffffc0200cb4:	4701                	li	a4,0
ffffffffc0200cb6:	4685                	li	a3,1
ffffffffc0200cb8:	4a89                	li	s5,2
ffffffffc0200cba:	4a09                	li	s4,2
ffffffffc0200cbc:	00c78e63          	beq	a5,a2,ffffffffc0200cd8 <buddy_alloc_pages+0x64>
        x=x>>1;
ffffffffc0200cc0:	0017d79b          	srliw	a5,a5,0x1
        count++;
ffffffffc0200cc4:	0007061b          	sext.w	a2,a4
ffffffffc0200cc8:	2705                	addiw	a4,a4,1
    while(x>1){
ffffffffc0200cca:	fed79be3          	bne	a5,a3,ffffffffc0200cc0 <buddy_alloc_pages+0x4c>
    order = Is_Power_Of_2(real_n) ? Get_Power_Of_2(real_n) : Get_Power_Of_2(real_n) + 1;
ffffffffc0200cce:	2609                	addiw	a2,a2,2
    size_t n = 1 << order;
ffffffffc0200cd0:	4a05                	li	s4,1
ffffffffc0200cd2:	00ca1a3b          	sllw	s4,s4,a2
    while (1) {
        if (!list_empty(&(free_list[order]))) {
            page = le2page(list_next(&(free_list[order])), page_link);
            list_del(list_next(&(free_list[order])));
            SetPageProperty(page);
            nr_free -= n;
ffffffffc0200cd6:	8ad2                	mv	s5,s4
    cprintf("buddy_alloc_pages: Request for %lu pages, calculated order: %u, n: %lu\n", real_n, order, n);
ffffffffc0200cd8:	86d2                	mv	a3,s4
ffffffffc0200cda:	00001517          	auipc	a0,0x1
ffffffffc0200cde:	71e50513          	addi	a0,a0,1822 # ffffffffc02023f8 <commands+0x750>
    order = Is_Power_Of_2(real_n) ? Get_Power_Of_2(real_n) : Get_Power_Of_2(real_n) + 1;
ffffffffc0200ce2:	00cb2023          	sw	a2,0(s6)
    cprintf("buddy_alloc_pages: Request for %lu pages, calculated order: %u, n: %lu\n", real_n, order, n);
ffffffffc0200ce6:	bccff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
        if (!list_empty(&(free_list[order]))) {
ffffffffc0200cea:	000b2603          	lw	a2,0(s6)
            cprintf("buddy_alloc_pages: Allocated %lu pages from free_list[%u] at address %p\n", n, order, page);
            break;
        }

        for (int i = order; i < 16; i++) {
ffffffffc0200cee:	44bd                	li	s1,15
ffffffffc0200cf0:	4441                	li	s0,16
    return list->next == list;
ffffffffc0200cf2:	02061713          	slli	a4,a2,0x20
ffffffffc0200cf6:	01c75793          	srli	a5,a4,0x1c
ffffffffc0200cfa:	00fb0733          	add	a4,s6,a5
ffffffffc0200cfe:	6b18                	ld	a4,16(a4)
        if (!list_empty(&(free_list[order]))) {
ffffffffc0200d00:	07a1                	addi	a5,a5,8
ffffffffc0200d02:	97da                	add	a5,a5,s6
            if (!list_empty(&(free_list[i]))) {
                struct Page *page1 = le2page(list_next(&(free_list[i])), page_link);
                struct Page *page2 = page1 + (1 << (i - 1));
ffffffffc0200d04:	4985                	li	s3,1
                page1->property = i - 1;
                page2->property = i - 1;
                list_del(list_next(&(free_list[i])));
                list_add(&(free_list[i-1]), &(page2->page_link));
                list_add(&(free_list[i-1]), &(page1->page_link));
                cprintf("buddy_alloc_pages: Split block from free_list[%d] into two blocks of size %lu pages (power %d)\n", i, (1 << (i - 1)), i - 1);
ffffffffc0200d06:	00001917          	auipc	s2,0x1
ffffffffc0200d0a:	78a90913          	addi	s2,s2,1930 # ffffffffc0202490 <commands+0x7e8>
        if (!list_empty(&(free_list[order]))) {
ffffffffc0200d0e:	0af71063          	bne	a4,a5,ffffffffc0200dae <buddy_alloc_pages+0x13a>
ffffffffc0200d12:	00461693          	slli	a3,a2,0x4
ffffffffc0200d16:	06a1                	addi	a3,a3,8
        for (int i = order; i < 16; i++) {
ffffffffc0200d18:	2601                	sext.w	a2,a2
ffffffffc0200d1a:	96da                	add	a3,a3,s6
ffffffffc0200d1c:	00c4c063          	blt	s1,a2,ffffffffc0200d1c <buddy_alloc_pages+0xa8>
ffffffffc0200d20:	87b6                	mv	a5,a3
ffffffffc0200d22:	85b2                	mv	a1,a2
ffffffffc0200d24:	a029                	j	ffffffffc0200d2e <buddy_alloc_pages+0xba>
ffffffffc0200d26:	2585                	addiw	a1,a1,1
ffffffffc0200d28:	07c1                	addi	a5,a5,16
ffffffffc0200d2a:	fe8589e3          	beq	a1,s0,ffffffffc0200d1c <buddy_alloc_pages+0xa8>
ffffffffc0200d2e:	6798                	ld	a4,8(a5)
            if (!list_empty(&(free_list[i]))) {
ffffffffc0200d30:	fef70be3          	beq	a4,a5,ffffffffc0200d26 <buddy_alloc_pages+0xb2>
                struct Page *page2 = page1 + (1 << (i - 1));
ffffffffc0200d34:	fff5869b          	addiw	a3,a1,-1
ffffffffc0200d38:	00d9963b          	sllw	a2,s3,a3
ffffffffc0200d3c:	00261793          	slli	a5,a2,0x2
ffffffffc0200d40:	97b2                	add	a5,a5,a2
ffffffffc0200d42:	078e                	slli	a5,a5,0x3
    __list_del(listelm->prev, listelm->next);
ffffffffc0200d44:	00073883          	ld	a7,0(a4)
ffffffffc0200d48:	00873803          	ld	a6,8(a4)
ffffffffc0200d4c:	17a1                	addi	a5,a5,-24
                page1->property = i - 1;
ffffffffc0200d4e:	fed72c23          	sw	a3,-8(a4)
                struct Page *page2 = page1 + (1 << (i - 1));
ffffffffc0200d52:	97ba                	add	a5,a5,a4
                page2->property = i - 1;
ffffffffc0200d54:	cb94                	sw	a3,16(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200d56:	0108b423          	sd	a6,8(a7)
                list_add(&(free_list[i-1]), &(page2->page_link));
ffffffffc0200d5a:	00469513          	slli	a0,a3,0x4
    next->prev = prev;
ffffffffc0200d5e:	01183023          	sd	a7,0(a6)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200d62:	00ab0833          	add	a6,s6,a0
ffffffffc0200d66:	01083883          	ld	a7,16(a6)
ffffffffc0200d6a:	01878313          	addi	t1,a5,24
ffffffffc0200d6e:	0521                	addi	a0,a0,8
    prev->next = next->prev = elm;
ffffffffc0200d70:	0068b023          	sd	t1,0(a7)
ffffffffc0200d74:	00683823          	sd	t1,16(a6)
ffffffffc0200d78:	955a                	add	a0,a0,s6
    elm->prev = prev;
ffffffffc0200d7a:	ef88                	sd	a0,24(a5)
    elm->next = next;
ffffffffc0200d7c:	0317b023          	sd	a7,32(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200d80:	01083783          	ld	a5,16(a6)
    prev->next = next->prev = elm;
ffffffffc0200d84:	e398                	sd	a4,0(a5)
ffffffffc0200d86:	00e83823          	sd	a4,16(a6)
    elm->next = next;
ffffffffc0200d8a:	e71c                	sd	a5,8(a4)
    elm->prev = prev;
ffffffffc0200d8c:	e308                	sd	a0,0(a4)
                cprintf("buddy_alloc_pages: Split block from free_list[%d] into two blocks of size %lu pages (power %d)\n", i, (1 << (i - 1)), i - 1);
ffffffffc0200d8e:	854a                	mv	a0,s2
ffffffffc0200d90:	b22ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
        if (!list_empty(&(free_list[order]))) {
ffffffffc0200d94:	000b2603          	lw	a2,0(s6)
    return list->next == list;
ffffffffc0200d98:	02061713          	slli	a4,a2,0x20
ffffffffc0200d9c:	01c75793          	srli	a5,a4,0x1c
ffffffffc0200da0:	00fb0733          	add	a4,s6,a5
ffffffffc0200da4:	6b18                	ld	a4,16(a4)
ffffffffc0200da6:	07a1                	addi	a5,a5,8
ffffffffc0200da8:	97da                	add	a5,a5,s6
ffffffffc0200daa:	f6f704e3          	beq	a4,a5,ffffffffc0200d12 <buddy_alloc_pages+0x9e>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200dae:	671c                	ld	a5,8(a4)
ffffffffc0200db0:	6314                	ld	a3,0(a4)
            page = le2page(list_next(&(free_list[order])), page_link);
ffffffffc0200db2:	fe870413          	addi	s0,a4,-24
ffffffffc0200db6:	1741                	addi	a4,a4,-16
    prev->next = next;
ffffffffc0200db8:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc0200dba:	e394                	sd	a3,0(a5)
ffffffffc0200dbc:	4789                	li	a5,2
ffffffffc0200dbe:	40f7302f          	amoor.d	zero,a5,(a4)
            nr_free -= n;
ffffffffc0200dc2:	108b2783          	lw	a5,264(s6)
            cprintf("buddy_alloc_pages: Allocated %lu pages from free_list[%u] at address %p\n", n, order, page);
ffffffffc0200dc6:	86a2                	mv	a3,s0
ffffffffc0200dc8:	85d2                	mv	a1,s4
            nr_free -= n;
ffffffffc0200dca:	41578abb          	subw	s5,a5,s5
            cprintf("buddy_alloc_pages: Allocated %lu pages from free_list[%u] at address %p\n", n, order, page);
ffffffffc0200dce:	00001517          	auipc	a0,0x1
ffffffffc0200dd2:	67250513          	addi	a0,a0,1650 # ffffffffc0202440 <commands+0x798>
            nr_free -= n;
ffffffffc0200dd6:	115b2423          	sw	s5,264(s6)
            cprintf("buddy_alloc_pages: Allocated %lu pages from free_list[%u] at address %p\n", n, order, page);
ffffffffc0200dda:	ad8ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
            }
        }
    }

    return page;
}
ffffffffc0200dde:	70e2                	ld	ra,56(sp)
ffffffffc0200de0:	8522                	mv	a0,s0
ffffffffc0200de2:	7442                	ld	s0,48(sp)
ffffffffc0200de4:	74a2                	ld	s1,40(sp)
ffffffffc0200de6:	7902                	ld	s2,32(sp)
ffffffffc0200de8:	69e2                	ld	s3,24(sp)
ffffffffc0200dea:	6a42                	ld	s4,16(sp)
ffffffffc0200dec:	6aa2                	ld	s5,8(sp)
ffffffffc0200dee:	6b02                	ld	s6,0(sp)
ffffffffc0200df0:	6121                	addi	sp,sp,64
ffffffffc0200df2:	8082                	ret
    while(x>1){
ffffffffc0200df4:	4705                	li	a4,1
ffffffffc0200df6:	02e50063          	beq	a0,a4,ffffffffc0200e16 <buddy_alloc_pages+0x1a2>
        x=x>>1;
ffffffffc0200dfa:	0017d79b          	srliw	a5,a5,0x1
        count++;
ffffffffc0200dfe:	2605                	addiw	a2,a2,1
    while(x>1){
ffffffffc0200e00:	fee79de3          	bne	a5,a4,ffffffffc0200dfa <buddy_alloc_pages+0x186>
ffffffffc0200e04:	b5f1                	j	ffffffffc0200cd0 <buddy_alloc_pages+0x5c>
        cprintf("buddy_alloc_pages: Not enough free pages. Needed: %lu, Available: %d\n", real_n, nr_free);
ffffffffc0200e06:	00001517          	auipc	a0,0x1
ffffffffc0200e0a:	5aa50513          	addi	a0,a0,1450 # ffffffffc02023b0 <commands+0x708>
ffffffffc0200e0e:	aa4ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
        return NULL;
ffffffffc0200e12:	4401                	li	s0,0
ffffffffc0200e14:	b7e9                	j	ffffffffc0200dde <buddy_alloc_pages+0x16a>
    while(x>1){
ffffffffc0200e16:	4a05                	li	s4,1
ffffffffc0200e18:	4a85                	li	s5,1
ffffffffc0200e1a:	bd7d                	j	ffffffffc0200cd8 <buddy_alloc_pages+0x64>
    assert(real_n > 0);
ffffffffc0200e1c:	00001697          	auipc	a3,0x1
ffffffffc0200e20:	58468693          	addi	a3,a3,1412 # ffffffffc02023a0 <commands+0x6f8>
ffffffffc0200e24:	00001617          	auipc	a2,0x1
ffffffffc0200e28:	53c60613          	addi	a2,a2,1340 # ffffffffc0202360 <commands+0x6b8>
ffffffffc0200e2c:	05800593          	li	a1,88
ffffffffc0200e30:	00001517          	auipc	a0,0x1
ffffffffc0200e34:	54850513          	addi	a0,a0,1352 # ffffffffc0202378 <commands+0x6d0>
ffffffffc0200e38:	b02ff0ef          	jal	ra,ffffffffc020013a <__panic>

ffffffffc0200e3c <buddy_check_0>:

    ClearPageProperty(free_page);
    cprintf("buddy_free_pages: Pages successfully released\n");
}

static void buddy_check_0(void) {
ffffffffc0200e3c:	c8010113          	addi	sp,sp,-896

#define ALLOC_PAGE_NUM 100

    cprintf("[buddy_check_0] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
ffffffffc0200e40:	00001517          	auipc	a0,0x1
ffffffffc0200e44:	6b050513          	addi	a0,a0,1712 # ffffffffc02024f0 <commands+0x848>
static void buddy_check_0(void) {
ffffffffc0200e48:	36113c23          	sd	ra,888(sp)
ffffffffc0200e4c:	37213023          	sd	s2,864(sp)
ffffffffc0200e50:	35313c23          	sd	s3,856(sp)
ffffffffc0200e54:	35413823          	sd	s4,848(sp)
ffffffffc0200e58:	35513423          	sd	s5,840(sp)
ffffffffc0200e5c:	35613023          	sd	s6,832(sp)
ffffffffc0200e60:	33713c23          	sd	s7,824(sp)
ffffffffc0200e64:	33813823          	sd	s8,816(sp)
ffffffffc0200e68:	33913423          	sd	s9,808(sp)
ffffffffc0200e6c:	36813823          	sd	s0,880(sp)
ffffffffc0200e70:	36913423          	sd	s1,872(sp)
ffffffffc0200e74:	33a13023          	sd	s10,800(sp)
    cprintf("[buddy_check_0] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
ffffffffc0200e78:	a3aff0ef          	jal	ra,ffffffffc02000b2 <cprintf>

    size_t initial_nr_free_pages = nr_free_pages();
ffffffffc0200e7c:	a03ff0ef          	jal	ra,ffffffffc020087e <nr_free_pages>
ffffffffc0200e80:	8c2a                	mv	s8,a0

    cprintf("[buddy_check_0] before alloc: ");
ffffffffc0200e82:	00001517          	auipc	a0,0x1
ffffffffc0200e86:	6b650513          	addi	a0,a0,1718 # ffffffffc0202538 <commands+0x890>
ffffffffc0200e8a:	a28ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    //buddy_show();

    cprintf("[buddy_check_0] trying to alloc %d * 1 pages\n", ALLOC_PAGE_NUM);
ffffffffc0200e8e:	06400593          	li	a1,100
ffffffffc0200e92:	00001517          	auipc	a0,0x1
ffffffffc0200e96:	6c650513          	addi	a0,a0,1734 # ffffffffc0202558 <commands+0x8b0>
ffffffffc0200e9a:	a18ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>

    struct Page *pages[ALLOC_PAGE_NUM];


    for (int i = 0; i < ALLOC_PAGE_NUM; i++) {
        pages[i] = alloc_pages(1);
ffffffffc0200e9e:	4505                	li	a0,1
ffffffffc0200ea0:	963ff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200ea4:	00810993          	addi	s3,sp,8
ffffffffc0200ea8:	8a2a                	mv	s4,a0
ffffffffc0200eaa:	8ace                	mv	s5,s3
ffffffffc0200eac:	892a                	mv	s2,a0
    for (int i = 0; i < ALLOC_PAGE_NUM; i++) {
ffffffffc0200eae:	4c81                	li	s9,0
ffffffffc0200eb0:	06400b93          	li	s7,100
        for (int j = 0; j < i; j++) {
            if (pages[i] == pages[j]) {
                cprintf("Error: Duplicate page pointer at %p (pages[%d] and pages[%d])\n", pages[i], i, j);
ffffffffc0200eb4:	00001b17          	auipc	s6,0x1
ffffffffc0200eb8:	6d4b0b13          	addi	s6,s6,1748 # ffffffffc0202588 <commands+0x8e0>
            }   
        }
        assert(pages[i] != NULL);
ffffffffc0200ebc:	0c090863          	beqz	s2,ffffffffc0200f8c <buddy_check_0+0x150>
    for (int i = 0; i < ALLOC_PAGE_NUM; i++) {
ffffffffc0200ec0:	001c8d1b          	addiw	s10,s9,1
ffffffffc0200ec4:	057d0363          	beq	s10,s7,ffffffffc0200f0a <buddy_check_0+0xce>
        pages[i] = alloc_pages(1);
ffffffffc0200ec8:	4505                	li	a0,1
ffffffffc0200eca:	939ff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc0200ece:	892a                	mv	s2,a0
ffffffffc0200ed0:	00aab023          	sd	a0,0(s5)
ffffffffc0200ed4:	87d2                	mv	a5,s4
ffffffffc0200ed6:	84ce                	mv	s1,s3
        for (int j = 0; j < i; j++) {
ffffffffc0200ed8:	4401                	li	s0,0
            if (pages[i] == pages[j]) {
ffffffffc0200eda:	00f90b63          	beq	s2,a5,ffffffffc0200ef0 <buddy_check_0+0xb4>
        for (int j = 0; j < i; j++) {
ffffffffc0200ede:	0014071b          	addiw	a4,s0,1
ffffffffc0200ee2:	028c8163          	beq	s9,s0,ffffffffc0200f04 <buddy_check_0+0xc8>
            if (pages[i] == pages[j]) {
ffffffffc0200ee6:	609c                	ld	a5,0(s1)
ffffffffc0200ee8:	843a                	mv	s0,a4
ffffffffc0200eea:	04a1                	addi	s1,s1,8
ffffffffc0200eec:	fef919e3          	bne	s2,a5,ffffffffc0200ede <buddy_check_0+0xa2>
                cprintf("Error: Duplicate page pointer at %p (pages[%d] and pages[%d])\n", pages[i], i, j);
ffffffffc0200ef0:	86a2                	mv	a3,s0
ffffffffc0200ef2:	866a                	mv	a2,s10
ffffffffc0200ef4:	85ca                	mv	a1,s2
ffffffffc0200ef6:	855a                	mv	a0,s6
ffffffffc0200ef8:	9baff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
        for (int j = 0; j < i; j++) {
ffffffffc0200efc:	0014071b          	addiw	a4,s0,1
ffffffffc0200f00:	fe8c93e3          	bne	s9,s0,ffffffffc0200ee6 <buddy_check_0+0xaa>
ffffffffc0200f04:	0aa1                	addi	s5,s5,8
ffffffffc0200f06:	8cea                	mv	s9,s10
ffffffffc0200f08:	bf55                	j	ffffffffc0200ebc <buddy_check_0+0x80>
    }

    assert(nr_free_pages() == initial_nr_free_pages - ALLOC_PAGE_NUM);
ffffffffc0200f0a:	975ff0ef          	jal	ra,ffffffffc020087e <nr_free_pages>
ffffffffc0200f0e:	f9cc0793          	addi	a5,s8,-100
ffffffffc0200f12:	0af51d63          	bne	a0,a5,ffffffffc0200fcc <buddy_check_0+0x190>

    cprintf("[buddy_check_0] after alloc:  ");
ffffffffc0200f16:	00001517          	auipc	a0,0x1
ffffffffc0200f1a:	70a50513          	addi	a0,a0,1802 # ffffffffc0202620 <commands+0x978>
ffffffffc0200f1e:	994ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    //buddy_show();

    for (int i = 0; i < ALLOC_PAGE_NUM; i++) {
ffffffffc0200f22:	1600                	addi	s0,sp,800
ffffffffc0200f24:	a021                	j	ffffffffc0200f2c <buddy_check_0+0xf0>
        free_pages(pages[i], 1);
ffffffffc0200f26:	0009ba03          	ld	s4,0(s3)
ffffffffc0200f2a:	09a1                	addi	s3,s3,8
ffffffffc0200f2c:	4585                	li	a1,1
ffffffffc0200f2e:	8552                	mv	a0,s4
ffffffffc0200f30:	911ff0ef          	jal	ra,ffffffffc0200840 <free_pages>
    for (int i = 0; i < ALLOC_PAGE_NUM; i++) {
ffffffffc0200f34:	fe8999e3          	bne	s3,s0,ffffffffc0200f26 <buddy_check_0+0xea>
    }
    assert(nr_free_pages() == initial_nr_free_pages);
ffffffffc0200f38:	947ff0ef          	jal	ra,ffffffffc020087e <nr_free_pages>
ffffffffc0200f3c:	07851863          	bne	a0,s8,ffffffffc0200fac <buddy_check_0+0x170>

    cprintf("[buddy_check_0] after free:   ");
ffffffffc0200f40:	00001517          	auipc	a0,0x1
ffffffffc0200f44:	73050513          	addi	a0,a0,1840 # ffffffffc0202670 <commands+0x9c8>
ffffffffc0200f48:	96aff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    //buddy_show();

    cprintf("[buddy_check_0] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");    
}
ffffffffc0200f4c:	37013403          	ld	s0,880(sp)
ffffffffc0200f50:	37813083          	ld	ra,888(sp)
ffffffffc0200f54:	36813483          	ld	s1,872(sp)
ffffffffc0200f58:	36013903          	ld	s2,864(sp)
ffffffffc0200f5c:	35813983          	ld	s3,856(sp)
ffffffffc0200f60:	35013a03          	ld	s4,848(sp)
ffffffffc0200f64:	34813a83          	ld	s5,840(sp)
ffffffffc0200f68:	34013b03          	ld	s6,832(sp)
ffffffffc0200f6c:	33813b83          	ld	s7,824(sp)
ffffffffc0200f70:	33013c03          	ld	s8,816(sp)
ffffffffc0200f74:	32813c83          	ld	s9,808(sp)
ffffffffc0200f78:	32013d03          	ld	s10,800(sp)
    cprintf("[buddy_check_0] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");    
ffffffffc0200f7c:	00001517          	auipc	a0,0x1
ffffffffc0200f80:	71450513          	addi	a0,a0,1812 # ffffffffc0202690 <commands+0x9e8>
}
ffffffffc0200f84:	38010113          	addi	sp,sp,896
    cprintf("[buddy_check_0] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");    
ffffffffc0200f88:	92aff06f          	j	ffffffffc02000b2 <cprintf>
        assert(pages[i] != NULL);
ffffffffc0200f8c:	00001697          	auipc	a3,0x1
ffffffffc0200f90:	63c68693          	addi	a3,a3,1596 # ffffffffc02025c8 <commands+0x920>
ffffffffc0200f94:	00001617          	auipc	a2,0x1
ffffffffc0200f98:	3cc60613          	addi	a2,a2,972 # ffffffffc0202360 <commands+0x6b8>
ffffffffc0200f9c:	0bb00593          	li	a1,187
ffffffffc0200fa0:	00001517          	auipc	a0,0x1
ffffffffc0200fa4:	3d850513          	addi	a0,a0,984 # ffffffffc0202378 <commands+0x6d0>
ffffffffc0200fa8:	992ff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(nr_free_pages() == initial_nr_free_pages);
ffffffffc0200fac:	00001697          	auipc	a3,0x1
ffffffffc0200fb0:	69468693          	addi	a3,a3,1684 # ffffffffc0202640 <commands+0x998>
ffffffffc0200fb4:	00001617          	auipc	a2,0x1
ffffffffc0200fb8:	3ac60613          	addi	a2,a2,940 # ffffffffc0202360 <commands+0x6b8>
ffffffffc0200fbc:	0c600593          	li	a1,198
ffffffffc0200fc0:	00001517          	auipc	a0,0x1
ffffffffc0200fc4:	3b850513          	addi	a0,a0,952 # ffffffffc0202378 <commands+0x6d0>
ffffffffc0200fc8:	972ff0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(nr_free_pages() == initial_nr_free_pages - ALLOC_PAGE_NUM);
ffffffffc0200fcc:	00001697          	auipc	a3,0x1
ffffffffc0200fd0:	61468693          	addi	a3,a3,1556 # ffffffffc02025e0 <commands+0x938>
ffffffffc0200fd4:	00001617          	auipc	a2,0x1
ffffffffc0200fd8:	38c60613          	addi	a2,a2,908 # ffffffffc0202360 <commands+0x6b8>
ffffffffc0200fdc:	0be00593          	li	a1,190
ffffffffc0200fe0:	00001517          	auipc	a0,0x1
ffffffffc0200fe4:	39850513          	addi	a0,a0,920 # ffffffffc0202378 <commands+0x6d0>
ffffffffc0200fe8:	952ff0ef          	jal	ra,ffffffffc020013a <__panic>

ffffffffc0200fec <buddy_check>:

    assert(nr_free_pages() == initial_nr_free_pages);

    cprintf("[buddy_check_1] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
}
static void buddy_check(){
ffffffffc0200fec:	7139                	addi	sp,sp,-64
ffffffffc0200fee:	fc06                	sd	ra,56(sp)
ffffffffc0200ff0:	e05a                	sd	s6,0(sp)
ffffffffc0200ff2:	f822                	sd	s0,48(sp)
ffffffffc0200ff4:	f426                	sd	s1,40(sp)
ffffffffc0200ff6:	f04a                	sd	s2,32(sp)
ffffffffc0200ff8:	ec4e                	sd	s3,24(sp)
ffffffffc0200ffa:	e852                	sd	s4,16(sp)
ffffffffc0200ffc:	e456                	sd	s5,8(sp)
    //buddy_show();
    buddy_check_0();
ffffffffc0200ffe:	e3fff0ef          	jal	ra,ffffffffc0200e3c <buddy_check_0>
    cprintf("[buddy_check_1] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
ffffffffc0201002:	00001517          	auipc	a0,0x1
ffffffffc0201006:	6d650513          	addi	a0,a0,1750 # ffffffffc02026d8 <commands+0xa30>
ffffffffc020100a:	8a8ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    size_t initial_nr_free_pages = nr_free_pages();
ffffffffc020100e:	871ff0ef          	jal	ra,ffffffffc020087e <nr_free_pages>
ffffffffc0201012:	8b2a                	mv	s6,a0
    cprintf("[buddy_check_0] before alloc:          ");
ffffffffc0201014:	00001517          	auipc	a0,0x1
ffffffffc0201018:	70c50513          	addi	a0,a0,1804 # ffffffffc0202720 <commands+0xa78>
ffffffffc020101c:	896ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    struct Page* p0 = alloc_pages(512);
ffffffffc0201020:	20000513          	li	a0,512
ffffffffc0201024:	fdeff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
    assert(p0 != NULL);
ffffffffc0201028:	12050763          	beqz	a0,ffffffffc0201156 <buddy_check+0x16a>
    assert(p0->property == 9);
ffffffffc020102c:	4918                	lw	a4,16(a0)
ffffffffc020102e:	47a5                	li	a5,9
ffffffffc0201030:	842a                	mv	s0,a0
ffffffffc0201032:	2af71263          	bne	a4,a5,ffffffffc02012d6 <buddy_check+0x2ea>
    cprintf("[buddy_check_1] after alloc 512 pages: ");
ffffffffc0201036:	00001517          	auipc	a0,0x1
ffffffffc020103a:	73a50513          	addi	a0,a0,1850 # ffffffffc0202770 <commands+0xac8>
ffffffffc020103e:	874ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    struct Page* p1 = alloc_pages(513);
ffffffffc0201042:	20100513          	li	a0,513
ffffffffc0201046:	fbcff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc020104a:	84aa                	mv	s1,a0
    assert(p1 != NULL);
ffffffffc020104c:	26050563          	beqz	a0,ffffffffc02012b6 <buddy_check+0x2ca>
    assert(p1->property == 10);
ffffffffc0201050:	4918                	lw	a4,16(a0)
ffffffffc0201052:	47a9                	li	a5,10
ffffffffc0201054:	24f71163          	bne	a4,a5,ffffffffc0201296 <buddy_check+0x2aa>
    cprintf("[buddy_check_1] after alloc 513 pages: ");
ffffffffc0201058:	00001517          	auipc	a0,0x1
ffffffffc020105c:	76850513          	addi	a0,a0,1896 # ffffffffc02027c0 <commands+0xb18>
ffffffffc0201060:	852ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    struct Page* p2 = alloc_pages(79);
ffffffffc0201064:	04f00513          	li	a0,79
ffffffffc0201068:	f9aff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc020106c:	892a                	mv	s2,a0
    assert(p2 != NULL);
ffffffffc020106e:	20050463          	beqz	a0,ffffffffc0201276 <buddy_check+0x28a>
    assert(p2->property == 7);
ffffffffc0201072:	4918                	lw	a4,16(a0)
ffffffffc0201074:	479d                	li	a5,7
ffffffffc0201076:	1ef71063          	bne	a4,a5,ffffffffc0201256 <buddy_check+0x26a>
    cprintf("[buddy_check_1] after alloc 79 pages:  ");
ffffffffc020107a:	00001517          	auipc	a0,0x1
ffffffffc020107e:	79650513          	addi	a0,a0,1942 # ffffffffc0202810 <commands+0xb68>
ffffffffc0201082:	830ff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    struct Page* p3 = alloc_pages(37);
ffffffffc0201086:	02500513          	li	a0,37
ffffffffc020108a:	f78ff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc020108e:	89aa                	mv	s3,a0
    assert(p3 != NULL);
ffffffffc0201090:	1a050363          	beqz	a0,ffffffffc0201236 <buddy_check+0x24a>
    assert(p3->property == 6);
ffffffffc0201094:	4918                	lw	a4,16(a0)
ffffffffc0201096:	4799                	li	a5,6
ffffffffc0201098:	16f71f63          	bne	a4,a5,ffffffffc0201216 <buddy_check+0x22a>
    cprintf("[buddy_check_1] after alloc 37 pages:  ");
ffffffffc020109c:	00001517          	auipc	a0,0x1
ffffffffc02010a0:	7c450513          	addi	a0,a0,1988 # ffffffffc0202860 <commands+0xbb8>
ffffffffc02010a4:	80eff0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    struct Page* p4 = alloc_pages(3);
ffffffffc02010a8:	450d                	li	a0,3
ffffffffc02010aa:	f58ff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc02010ae:	8a2a                	mv	s4,a0
    assert(p4 != NULL);
ffffffffc02010b0:	14050363          	beqz	a0,ffffffffc02011f6 <buddy_check+0x20a>
    assert(p4->property == 2);
ffffffffc02010b4:	4918                	lw	a4,16(a0)
ffffffffc02010b6:	4789                	li	a5,2
ffffffffc02010b8:	10f71f63          	bne	a4,a5,ffffffffc02011d6 <buddy_check+0x1ea>
    cprintf("[buddy_check_1] after alloc 3 pages:   ");
ffffffffc02010bc:	00001517          	auipc	a0,0x1
ffffffffc02010c0:	7f450513          	addi	a0,a0,2036 # ffffffffc02028b0 <commands+0xc08>
ffffffffc02010c4:	feffe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    struct Page* p5 = alloc_pages(196);
ffffffffc02010c8:	0c400513          	li	a0,196
ffffffffc02010cc:	f36ff0ef          	jal	ra,ffffffffc0200802 <alloc_pages>
ffffffffc02010d0:	8aaa                	mv	s5,a0
    assert(p5 != NULL);
ffffffffc02010d2:	0e050263          	beqz	a0,ffffffffc02011b6 <buddy_check+0x1ca>
    assert(p5->property == 8);
ffffffffc02010d6:	4918                	lw	a4,16(a0)
ffffffffc02010d8:	47a1                	li	a5,8
ffffffffc02010da:	0af71e63          	bne	a4,a5,ffffffffc0201196 <buddy_check+0x1aa>
    cprintf("[buddy_check_1] after alloc 196 pages: ");
ffffffffc02010de:	00002517          	auipc	a0,0x2
ffffffffc02010e2:	82250513          	addi	a0,a0,-2014 # ffffffffc0202900 <commands+0xc58>
ffffffffc02010e6:	fcdfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    free_pages(p4, 3);
ffffffffc02010ea:	458d                	li	a1,3
ffffffffc02010ec:	8552                	mv	a0,s4
ffffffffc02010ee:	f52ff0ef          	jal	ra,ffffffffc0200840 <free_pages>
    free_pages(p0, 512);
ffffffffc02010f2:	20000593          	li	a1,512
ffffffffc02010f6:	8522                	mv	a0,s0
ffffffffc02010f8:	f48ff0ef          	jal	ra,ffffffffc0200840 <free_pages>
    free_pages(p2, 79);
ffffffffc02010fc:	04f00593          	li	a1,79
ffffffffc0201100:	854a                	mv	a0,s2
ffffffffc0201102:	f3eff0ef          	jal	ra,ffffffffc0200840 <free_pages>
    free_pages(p3, 37);
ffffffffc0201106:	02500593          	li	a1,37
ffffffffc020110a:	854e                	mv	a0,s3
ffffffffc020110c:	f34ff0ef          	jal	ra,ffffffffc0200840 <free_pages>
    free_pages(p5, 196);
ffffffffc0201110:	0c400593          	li	a1,196
ffffffffc0201114:	8556                	mv	a0,s5
ffffffffc0201116:	f2aff0ef          	jal	ra,ffffffffc0200840 <free_pages>
    free_pages(p1, 513);
ffffffffc020111a:	20100593          	li	a1,513
ffffffffc020111e:	8526                	mv	a0,s1
ffffffffc0201120:	f20ff0ef          	jal	ra,ffffffffc0200840 <free_pages>
    cprintf("[buddy_check_1] after free:            ");
ffffffffc0201124:	00002517          	auipc	a0,0x2
ffffffffc0201128:	80450513          	addi	a0,a0,-2044 # ffffffffc0202928 <commands+0xc80>
ffffffffc020112c:	f87fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    assert(nr_free_pages() == initial_nr_free_pages);
ffffffffc0201130:	f4eff0ef          	jal	ra,ffffffffc020087e <nr_free_pages>
ffffffffc0201134:	04ab1163          	bne	s6,a0,ffffffffc0201176 <buddy_check+0x18a>
    buddy_check_1();
}
ffffffffc0201138:	7442                	ld	s0,48(sp)
ffffffffc020113a:	70e2                	ld	ra,56(sp)
ffffffffc020113c:	74a2                	ld	s1,40(sp)
ffffffffc020113e:	7902                	ld	s2,32(sp)
ffffffffc0201140:	69e2                	ld	s3,24(sp)
ffffffffc0201142:	6a42                	ld	s4,16(sp)
ffffffffc0201144:	6aa2                	ld	s5,8(sp)
ffffffffc0201146:	6b02                	ld	s6,0(sp)
    cprintf("[buddy_check_1] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
ffffffffc0201148:	00002517          	auipc	a0,0x2
ffffffffc020114c:	80850513          	addi	a0,a0,-2040 # ffffffffc0202950 <commands+0xca8>
}
ffffffffc0201150:	6121                	addi	sp,sp,64
    cprintf("[buddy_check_1] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
ffffffffc0201152:	f61fe06f          	j	ffffffffc02000b2 <cprintf>
    assert(p0 != NULL);
ffffffffc0201156:	00001697          	auipc	a3,0x1
ffffffffc020115a:	5f268693          	addi	a3,a3,1522 # ffffffffc0202748 <commands+0xaa0>
ffffffffc020115e:	00001617          	auipc	a2,0x1
ffffffffc0201162:	20260613          	addi	a2,a2,514 # ffffffffc0202360 <commands+0x6b8>
ffffffffc0201166:	0d800593          	li	a1,216
ffffffffc020116a:	00001517          	auipc	a0,0x1
ffffffffc020116e:	20e50513          	addi	a0,a0,526 # ffffffffc0202378 <commands+0x6d0>
ffffffffc0201172:	fc9fe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(nr_free_pages() == initial_nr_free_pages);
ffffffffc0201176:	00001697          	auipc	a3,0x1
ffffffffc020117a:	4ca68693          	addi	a3,a3,1226 # ffffffffc0202640 <commands+0x998>
ffffffffc020117e:	00001617          	auipc	a2,0x1
ffffffffc0201182:	1e260613          	addi	a2,a2,482 # ffffffffc0202360 <commands+0x6b8>
ffffffffc0201186:	10700593          	li	a1,263
ffffffffc020118a:	00001517          	auipc	a0,0x1
ffffffffc020118e:	1ee50513          	addi	a0,a0,494 # ffffffffc0202378 <commands+0x6d0>
ffffffffc0201192:	fa9fe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(p5->property == 8);
ffffffffc0201196:	00001697          	auipc	a3,0x1
ffffffffc020119a:	75268693          	addi	a3,a3,1874 # ffffffffc02028e8 <commands+0xc40>
ffffffffc020119e:	00001617          	auipc	a2,0x1
ffffffffc02011a2:	1c260613          	addi	a2,a2,450 # ffffffffc0202360 <commands+0x6b8>
ffffffffc02011a6:	0f900593          	li	a1,249
ffffffffc02011aa:	00001517          	auipc	a0,0x1
ffffffffc02011ae:	1ce50513          	addi	a0,a0,462 # ffffffffc0202378 <commands+0x6d0>
ffffffffc02011b2:	f89fe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(p5 != NULL);
ffffffffc02011b6:	00001697          	auipc	a3,0x1
ffffffffc02011ba:	72268693          	addi	a3,a3,1826 # ffffffffc02028d8 <commands+0xc30>
ffffffffc02011be:	00001617          	auipc	a2,0x1
ffffffffc02011c2:	1a260613          	addi	a2,a2,418 # ffffffffc0202360 <commands+0x6b8>
ffffffffc02011c6:	0f800593          	li	a1,248
ffffffffc02011ca:	00001517          	auipc	a0,0x1
ffffffffc02011ce:	1ae50513          	addi	a0,a0,430 # ffffffffc0202378 <commands+0x6d0>
ffffffffc02011d2:	f69fe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(p4->property == 2);
ffffffffc02011d6:	00001697          	auipc	a3,0x1
ffffffffc02011da:	6c268693          	addi	a3,a3,1730 # ffffffffc0202898 <commands+0xbf0>
ffffffffc02011de:	00001617          	auipc	a2,0x1
ffffffffc02011e2:	18260613          	addi	a2,a2,386 # ffffffffc0202360 <commands+0x6b8>
ffffffffc02011e6:	0f300593          	li	a1,243
ffffffffc02011ea:	00001517          	auipc	a0,0x1
ffffffffc02011ee:	18e50513          	addi	a0,a0,398 # ffffffffc0202378 <commands+0x6d0>
ffffffffc02011f2:	f49fe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(p4 != NULL);
ffffffffc02011f6:	00001697          	auipc	a3,0x1
ffffffffc02011fa:	69268693          	addi	a3,a3,1682 # ffffffffc0202888 <commands+0xbe0>
ffffffffc02011fe:	00001617          	auipc	a2,0x1
ffffffffc0201202:	16260613          	addi	a2,a2,354 # ffffffffc0202360 <commands+0x6b8>
ffffffffc0201206:	0f200593          	li	a1,242
ffffffffc020120a:	00001517          	auipc	a0,0x1
ffffffffc020120e:	16e50513          	addi	a0,a0,366 # ffffffffc0202378 <commands+0x6d0>
ffffffffc0201212:	f29fe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(p3->property == 6);
ffffffffc0201216:	00001697          	auipc	a3,0x1
ffffffffc020121a:	63268693          	addi	a3,a3,1586 # ffffffffc0202848 <commands+0xba0>
ffffffffc020121e:	00001617          	auipc	a2,0x1
ffffffffc0201222:	14260613          	addi	a2,a2,322 # ffffffffc0202360 <commands+0x6b8>
ffffffffc0201226:	0ed00593          	li	a1,237
ffffffffc020122a:	00001517          	auipc	a0,0x1
ffffffffc020122e:	14e50513          	addi	a0,a0,334 # ffffffffc0202378 <commands+0x6d0>
ffffffffc0201232:	f09fe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(p3 != NULL);
ffffffffc0201236:	00001697          	auipc	a3,0x1
ffffffffc020123a:	60268693          	addi	a3,a3,1538 # ffffffffc0202838 <commands+0xb90>
ffffffffc020123e:	00001617          	auipc	a2,0x1
ffffffffc0201242:	12260613          	addi	a2,a2,290 # ffffffffc0202360 <commands+0x6b8>
ffffffffc0201246:	0ec00593          	li	a1,236
ffffffffc020124a:	00001517          	auipc	a0,0x1
ffffffffc020124e:	12e50513          	addi	a0,a0,302 # ffffffffc0202378 <commands+0x6d0>
ffffffffc0201252:	ee9fe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(p2->property == 7);
ffffffffc0201256:	00001697          	auipc	a3,0x1
ffffffffc020125a:	5a268693          	addi	a3,a3,1442 # ffffffffc02027f8 <commands+0xb50>
ffffffffc020125e:	00001617          	auipc	a2,0x1
ffffffffc0201262:	10260613          	addi	a2,a2,258 # ffffffffc0202360 <commands+0x6b8>
ffffffffc0201266:	0e700593          	li	a1,231
ffffffffc020126a:	00001517          	auipc	a0,0x1
ffffffffc020126e:	10e50513          	addi	a0,a0,270 # ffffffffc0202378 <commands+0x6d0>
ffffffffc0201272:	ec9fe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(p2 != NULL);
ffffffffc0201276:	00001697          	auipc	a3,0x1
ffffffffc020127a:	57268693          	addi	a3,a3,1394 # ffffffffc02027e8 <commands+0xb40>
ffffffffc020127e:	00001617          	auipc	a2,0x1
ffffffffc0201282:	0e260613          	addi	a2,a2,226 # ffffffffc0202360 <commands+0x6b8>
ffffffffc0201286:	0e600593          	li	a1,230
ffffffffc020128a:	00001517          	auipc	a0,0x1
ffffffffc020128e:	0ee50513          	addi	a0,a0,238 # ffffffffc0202378 <commands+0x6d0>
ffffffffc0201292:	ea9fe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(p1->property == 10);
ffffffffc0201296:	00001697          	auipc	a3,0x1
ffffffffc020129a:	51268693          	addi	a3,a3,1298 # ffffffffc02027a8 <commands+0xb00>
ffffffffc020129e:	00001617          	auipc	a2,0x1
ffffffffc02012a2:	0c260613          	addi	a2,a2,194 # ffffffffc0202360 <commands+0x6b8>
ffffffffc02012a6:	0e100593          	li	a1,225
ffffffffc02012aa:	00001517          	auipc	a0,0x1
ffffffffc02012ae:	0ce50513          	addi	a0,a0,206 # ffffffffc0202378 <commands+0x6d0>
ffffffffc02012b2:	e89fe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(p1 != NULL);
ffffffffc02012b6:	00001697          	auipc	a3,0x1
ffffffffc02012ba:	4e268693          	addi	a3,a3,1250 # ffffffffc0202798 <commands+0xaf0>
ffffffffc02012be:	00001617          	auipc	a2,0x1
ffffffffc02012c2:	0a260613          	addi	a2,a2,162 # ffffffffc0202360 <commands+0x6b8>
ffffffffc02012c6:	0e000593          	li	a1,224
ffffffffc02012ca:	00001517          	auipc	a0,0x1
ffffffffc02012ce:	0ae50513          	addi	a0,a0,174 # ffffffffc0202378 <commands+0x6d0>
ffffffffc02012d2:	e69fe0ef          	jal	ra,ffffffffc020013a <__panic>
    assert(p0->property == 9);
ffffffffc02012d6:	00001697          	auipc	a3,0x1
ffffffffc02012da:	48268693          	addi	a3,a3,1154 # ffffffffc0202758 <commands+0xab0>
ffffffffc02012de:	00001617          	auipc	a2,0x1
ffffffffc02012e2:	08260613          	addi	a2,a2,130 # ffffffffc0202360 <commands+0x6b8>
ffffffffc02012e6:	0da00593          	li	a1,218
ffffffffc02012ea:	00001517          	auipc	a0,0x1
ffffffffc02012ee:	08e50513          	addi	a0,a0,142 # ffffffffc0202378 <commands+0x6d0>
ffffffffc02012f2:	e49fe0ef          	jal	ra,ffffffffc020013a <__panic>

ffffffffc02012f6 <buddy_free_pages>:
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc02012f6:	7159                	addi	sp,sp,-112
ffffffffc02012f8:	f486                	sd	ra,104(sp)
ffffffffc02012fa:	f0a2                	sd	s0,96(sp)
ffffffffc02012fc:	eca6                	sd	s1,88(sp)
ffffffffc02012fe:	e8ca                	sd	s2,80(sp)
ffffffffc0201300:	e4ce                	sd	s3,72(sp)
ffffffffc0201302:	e0d2                	sd	s4,64(sp)
ffffffffc0201304:	fc56                	sd	s5,56(sp)
ffffffffc0201306:	f85a                	sd	s6,48(sp)
ffffffffc0201308:	f45e                	sd	s7,40(sp)
ffffffffc020130a:	f062                	sd	s8,32(sp)
ffffffffc020130c:	ec66                	sd	s9,24(sp)
ffffffffc020130e:	e86a                	sd	s10,16(sp)
ffffffffc0201310:	e46e                	sd	s11,8(sp)
    assert(n > 0);
ffffffffc0201312:	1a058563          	beqz	a1,ffffffffc02014bc <buddy_free_pages+0x1c6>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0201316:	00005a97          	auipc	s5,0x5
ffffffffc020131a:	22aa8a93          	addi	s5,s5,554 # ffffffffc0206540 <pages>
ffffffffc020131e:	000ab703          	ld	a4,0(s5)
ffffffffc0201322:	00002b17          	auipc	s6,0x2
ffffffffc0201326:	a1eb3b03          	ld	s6,-1506(s6) # ffffffffc0202d40 <error_string+0x38>
ffffffffc020132a:	00002997          	auipc	s3,0x2
ffffffffc020132e:	a1e98993          	addi	s3,s3,-1506 # ffffffffc0202d48 <nbase>
ffffffffc0201332:	40e50733          	sub	a4,a0,a4
ffffffffc0201336:	870d                	srai	a4,a4,0x3
ffffffffc0201338:	03670733          	mul	a4,a4,s6
ffffffffc020133c:	0009b303          	ld	t1,0(s3)
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));
ffffffffc0201340:	00005a17          	auipc	s4,0x5
ffffffffc0201344:	1f0a0a13          	addi	s4,s4,496 # ffffffffc0206530 <fppn>
ffffffffc0201348:	8daa                	mv	s11,a0
    nr_free += 1 << base->property;
ffffffffc020134a:	4914                	lw	a3,16(a0)
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));
ffffffffc020134c:	000a3503          	ld	a0,0(s4)
    nr_free += 1 << base->property;
ffffffffc0201350:	4605                	li	a2,1
ffffffffc0201352:	00d618bb          	sllw	a7,a2,a3
ffffffffc0201356:	00005497          	auipc	s1,0x5
ffffffffc020135a:	cba48493          	addi	s1,s1,-838 # ffffffffc0206010 <free_buddy>
ffffffffc020135e:	1084a803          	lw	a6,264(s1)
ffffffffc0201362:	971a                	add	a4,a4,t1
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));
ffffffffc0201364:	40a70433          	sub	s0,a4,a0
ffffffffc0201368:	01144433          	xor	s0,s0,a7
    return page+(ppn-page2ppn(page));
ffffffffc020136c:	40e50733          	sub	a4,a0,a4
ffffffffc0201370:	9722                	add	a4,a4,s0
ffffffffc0201372:	00271413          	slli	s0,a4,0x2
ffffffffc0201376:	943a                	add	s0,s0,a4
    cprintf("buddy_free_pages: Releasing %lu pages starting at address %p with property %u\n", n, free_page, free_page->property);
ffffffffc0201378:	866e                	mv	a2,s11
    nr_free += 1 << base->property;
ffffffffc020137a:	0118073b          	addw	a4,a6,a7
    cprintf("buddy_free_pages: Releasing %lu pages starting at address %p with property %u\n", n, free_page, free_page->property);
ffffffffc020137e:	00001517          	auipc	a0,0x1
ffffffffc0201382:	61a50513          	addi	a0,a0,1562 # ffffffffc0202998 <commands+0xcf0>
    nr_free += 1 << base->property;
ffffffffc0201386:	10e4a423          	sw	a4,264(s1)
    cprintf("buddy_free_pages: Releasing %lu pages starting at address %p with property %u\n", n, free_page, free_page->property);
ffffffffc020138a:	d29fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    list_add(&(free_list[free_page->property]), &(free_page->page_link));
ffffffffc020138e:	010da603          	lw	a2,16(s11)
    return page+(ppn-page2ppn(page));
ffffffffc0201392:	040e                	slli	s0,s0,0x3
ffffffffc0201394:	946e                	add	s0,s0,s11
    __list_add(elm, listelm, listelm->next);
ffffffffc0201396:	02061793          	slli	a5,a2,0x20
ffffffffc020139a:	01c7d713          	srli	a4,a5,0x1c
ffffffffc020139e:	00e48833          	add	a6,s1,a4
ffffffffc02013a2:	01083503          	ld	a0,16(a6)
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02013a6:	640c                	ld	a1,8(s0)
    list_add(&(free_list[free_page->property]), &(free_page->page_link));
ffffffffc02013a8:	018d8d13          	addi	s10,s11,24
    prev->next = next->prev = elm;
ffffffffc02013ac:	01a53023          	sd	s10,0(a0)
ffffffffc02013b0:	0721                	addi	a4,a4,8
ffffffffc02013b2:	9726                	add	a4,a4,s1
ffffffffc02013b4:	01a83823          	sd	s10,16(a6)
ffffffffc02013b8:	8185                	srli	a1,a1,0x1
    elm->prev = prev;
ffffffffc02013ba:	00edbc23          	sd	a4,24(s11)
    elm->next = next;
ffffffffc02013be:	02adb023          	sd	a0,32(s11)
    while (!PageProperty(free_page_buddy) && free_page->property < 14) {
ffffffffc02013c2:	0015f713          	andi	a4,a1,1
            ClearPageProperty(free_page);
ffffffffc02013c6:	008d8913          	addi	s2,s11,8
    while (!PageProperty(free_page_buddy) && free_page->property < 14) {
ffffffffc02013ca:	ef51                	bnez	a4,ffffffffc0201466 <buddy_free_pages+0x170>
ffffffffc02013cc:	4bb5                	li	s7,13
        cprintf("buddy_free_pages: Merged block, new property: %u, added to free_list[%u]\n", free_page->property, free_page->property);
ffffffffc02013ce:	00001c97          	auipc	s9,0x1
ffffffffc02013d2:	65ac8c93          	addi	s9,s9,1626 # ffffffffc0202a28 <commands+0xd80>
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));
ffffffffc02013d6:	4c05                	li	s8,1
    while (!PageProperty(free_page_buddy) && free_page->property < 14) {
ffffffffc02013d8:	08cbe763          	bltu	s7,a2,ffffffffc0201466 <buddy_free_pages+0x170>
        if (free_page_buddy < free_page) {
ffffffffc02013dc:	0bb46c63          	bltu	s0,s11,ffffffffc0201494 <buddy_free_pages+0x19e>
    __list_del(listelm->prev, listelm->next);
ffffffffc02013e0:	018db503          	ld	a0,24(s11)
ffffffffc02013e4:	020db583          	ld	a1,32(s11)
        free_page->property += 1;
ffffffffc02013e8:	2605                	addiw	a2,a2,1
    __list_add(elm, listelm, listelm->next);
ffffffffc02013ea:	02061793          	slli	a5,a2,0x20
    prev->next = next;
ffffffffc02013ee:	e50c                	sd	a1,8(a0)
    next->prev = prev;
ffffffffc02013f0:	e188                	sd	a0,0(a1)
    __list_del(listelm->prev, listelm->next);
ffffffffc02013f2:	01843803          	ld	a6,24(s0)
ffffffffc02013f6:	700c                	ld	a1,32(s0)
    __list_add(elm, listelm, listelm->next);
ffffffffc02013f8:	01c7d713          	srli	a4,a5,0x1c
ffffffffc02013fc:	00e48533          	add	a0,s1,a4
    prev->next = next;
ffffffffc0201400:	00b83423          	sd	a1,8(a6)
    next->prev = prev;
ffffffffc0201404:	0105b023          	sd	a6,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201408:	690c                	ld	a1,16(a0)
ffffffffc020140a:	00cda823          	sw	a2,16(s11)
        list_add(&(free_list[free_page->property]), &(free_page->page_link));
ffffffffc020140e:	0721                	addi	a4,a4,8
    prev->next = next->prev = elm;
ffffffffc0201410:	01a5b023          	sd	s10,0(a1)
ffffffffc0201414:	01a53823          	sd	s10,16(a0)
ffffffffc0201418:	9726                	add	a4,a4,s1
    elm->next = next;
ffffffffc020141a:	02bdb023          	sd	a1,32(s11)
    elm->prev = prev;
ffffffffc020141e:	00edbc23          	sd	a4,24(s11)
        cprintf("buddy_free_pages: Merged block, new property: %u, added to free_list[%u]\n", free_page->property, free_page->property);
ffffffffc0201422:	85b2                	mv	a1,a2
ffffffffc0201424:	8566                	mv	a0,s9
ffffffffc0201426:	c8dfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
ffffffffc020142a:	000ab703          	ld	a4,0(s5)
ffffffffc020142e:	0009b503          	ld	a0,0(s3)
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));
ffffffffc0201432:	000a3583          	ld	a1,0(s4)
ffffffffc0201436:	40ed8733          	sub	a4,s11,a4
ffffffffc020143a:	870d                	srai	a4,a4,0x3
ffffffffc020143c:	03670733          	mul	a4,a4,s6
    uint32_t power=page->property; 
ffffffffc0201440:	010da603          	lw	a2,16(s11)
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));
ffffffffc0201444:	00cc143b          	sllw	s0,s8,a2
ffffffffc0201448:	972a                	add	a4,a4,a0
ffffffffc020144a:	40b70533          	sub	a0,a4,a1
ffffffffc020144e:	8c29                	xor	s0,s0,a0
    return page+(ppn-page2ppn(page));
ffffffffc0201450:	40e58733          	sub	a4,a1,a4
ffffffffc0201454:	9722                	add	a4,a4,s0
ffffffffc0201456:	00271413          	slli	s0,a4,0x2
ffffffffc020145a:	943a                	add	s0,s0,a4
ffffffffc020145c:	040e                	slli	s0,s0,0x3
ffffffffc020145e:	946e                	add	s0,s0,s11
ffffffffc0201460:	6418                	ld	a4,8(s0)
    while (!PageProperty(free_page_buddy) && free_page->property < 14) {
ffffffffc0201462:	8b09                	andi	a4,a4,2
ffffffffc0201464:	db35                	beqz	a4,ffffffffc02013d8 <buddy_free_pages+0xe2>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201466:	57f5                	li	a5,-3
ffffffffc0201468:	60f9302f          	amoand.d	zero,a5,(s2)
}
ffffffffc020146c:	7406                	ld	s0,96(sp)
ffffffffc020146e:	70a6                	ld	ra,104(sp)
ffffffffc0201470:	64e6                	ld	s1,88(sp)
ffffffffc0201472:	6946                	ld	s2,80(sp)
ffffffffc0201474:	69a6                	ld	s3,72(sp)
ffffffffc0201476:	6a06                	ld	s4,64(sp)
ffffffffc0201478:	7ae2                	ld	s5,56(sp)
ffffffffc020147a:	7b42                	ld	s6,48(sp)
ffffffffc020147c:	7ba2                	ld	s7,40(sp)
ffffffffc020147e:	7c02                	ld	s8,32(sp)
ffffffffc0201480:	6ce2                	ld	s9,24(sp)
ffffffffc0201482:	6d42                	ld	s10,16(sp)
ffffffffc0201484:	6da2                	ld	s11,8(sp)
    cprintf("buddy_free_pages: Pages successfully released\n");
ffffffffc0201486:	00001517          	auipc	a0,0x1
ffffffffc020148a:	5f250513          	addi	a0,a0,1522 # ffffffffc0202a78 <commands+0xdd0>
}
ffffffffc020148e:	6165                	addi	sp,sp,112
    cprintf("buddy_free_pages: Pages successfully released\n");
ffffffffc0201490:	c23fe06f          	j	ffffffffc02000b2 <cprintf>
            free_page->property = 0;
ffffffffc0201494:	000da823          	sw	zero,16(s11)
ffffffffc0201498:	57f5                	li	a5,-3
ffffffffc020149a:	60f9302f          	amoand.d	zero,a5,(s2)
            cprintf("buddy_free_pages: Swapped free_page and free_page_buddy\n");
ffffffffc020149e:	00001517          	auipc	a0,0x1
ffffffffc02014a2:	54a50513          	addi	a0,a0,1354 # ffffffffc02029e8 <commands+0xd40>
ffffffffc02014a6:	c0dfe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
    ClearPageProperty(free_page);
ffffffffc02014aa:	876e                	mv	a4,s11
        free_page->property += 1;
ffffffffc02014ac:	4810                	lw	a2,16(s0)
    ClearPageProperty(free_page);
ffffffffc02014ae:	8da2                	mv	s11,s0
ffffffffc02014b0:	00840913          	addi	s2,s0,8
ffffffffc02014b4:	01840d13          	addi	s10,s0,24
ffffffffc02014b8:	843a                	mv	s0,a4
ffffffffc02014ba:	b71d                	j	ffffffffc02013e0 <buddy_free_pages+0xea>
    assert(n > 0);
ffffffffc02014bc:	00001697          	auipc	a3,0x1
ffffffffc02014c0:	e9c68693          	addi	a3,a3,-356 # ffffffffc0202358 <commands+0x6b0>
ffffffffc02014c4:	00001617          	auipc	a2,0x1
ffffffffc02014c8:	e9c60613          	addi	a2,a2,-356 # ffffffffc0202360 <commands+0x6b8>
ffffffffc02014cc:	08100593          	li	a1,129
ffffffffc02014d0:	00001517          	auipc	a0,0x1
ffffffffc02014d4:	ea850513          	addi	a0,a0,-344 # ffffffffc0202378 <commands+0x6d0>
ffffffffc02014d8:	c63fe0ef          	jal	ra,ffffffffc020013a <__panic>

ffffffffc02014dc <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02014dc:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02014de:	e589                	bnez	a1,ffffffffc02014e8 <strnlen+0xc>
ffffffffc02014e0:	a811                	j	ffffffffc02014f4 <strnlen+0x18>
        cnt ++;
ffffffffc02014e2:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02014e4:	00f58863          	beq	a1,a5,ffffffffc02014f4 <strnlen+0x18>
ffffffffc02014e8:	00f50733          	add	a4,a0,a5
ffffffffc02014ec:	00074703          	lbu	a4,0(a4)
ffffffffc02014f0:	fb6d                	bnez	a4,ffffffffc02014e2 <strnlen+0x6>
ffffffffc02014f2:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02014f4:	852e                	mv	a0,a1
ffffffffc02014f6:	8082                	ret

ffffffffc02014f8 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02014f8:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02014fc:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201500:	cb89                	beqz	a5,ffffffffc0201512 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201502:	0505                	addi	a0,a0,1
ffffffffc0201504:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201506:	fee789e3          	beq	a5,a4,ffffffffc02014f8 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020150a:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020150e:	9d19                	subw	a0,a0,a4
ffffffffc0201510:	8082                	ret
ffffffffc0201512:	4501                	li	a0,0
ffffffffc0201514:	bfed                	j	ffffffffc020150e <strcmp+0x16>

ffffffffc0201516 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201516:	00054783          	lbu	a5,0(a0)
ffffffffc020151a:	c799                	beqz	a5,ffffffffc0201528 <strchr+0x12>
        if (*s == c) {
ffffffffc020151c:	00f58763          	beq	a1,a5,ffffffffc020152a <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201520:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201524:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201526:	fbfd                	bnez	a5,ffffffffc020151c <strchr+0x6>
    }
    return NULL;
ffffffffc0201528:	4501                	li	a0,0
}
ffffffffc020152a:	8082                	ret

ffffffffc020152c <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc020152c:	ca01                	beqz	a2,ffffffffc020153c <memset+0x10>
ffffffffc020152e:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201530:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201532:	0785                	addi	a5,a5,1
ffffffffc0201534:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201538:	fec79de3          	bne	a5,a2,ffffffffc0201532 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc020153c:	8082                	ret

ffffffffc020153e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020153e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201542:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201544:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201548:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020154a:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020154e:	f022                	sd	s0,32(sp)
ffffffffc0201550:	ec26                	sd	s1,24(sp)
ffffffffc0201552:	e84a                	sd	s2,16(sp)
ffffffffc0201554:	f406                	sd	ra,40(sp)
ffffffffc0201556:	e44e                	sd	s3,8(sp)
ffffffffc0201558:	84aa                	mv	s1,a0
ffffffffc020155a:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020155c:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201560:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201562:	03067e63          	bgeu	a2,a6,ffffffffc020159e <printnum+0x60>
ffffffffc0201566:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201568:	00805763          	blez	s0,ffffffffc0201576 <printnum+0x38>
ffffffffc020156c:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020156e:	85ca                	mv	a1,s2
ffffffffc0201570:	854e                	mv	a0,s3
ffffffffc0201572:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201574:	fc65                	bnez	s0,ffffffffc020156c <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201576:	1a02                	slli	s4,s4,0x20
ffffffffc0201578:	00001797          	auipc	a5,0x1
ffffffffc020157c:	58078793          	addi	a5,a5,1408 # ffffffffc0202af8 <buddy_pmm_manager+0x38>
ffffffffc0201580:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201584:	9a3e                	add	s4,s4,a5
}
ffffffffc0201586:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201588:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020158c:	70a2                	ld	ra,40(sp)
ffffffffc020158e:	69a2                	ld	s3,8(sp)
ffffffffc0201590:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201592:	85ca                	mv	a1,s2
ffffffffc0201594:	87a6                	mv	a5,s1
}
ffffffffc0201596:	6942                	ld	s2,16(sp)
ffffffffc0201598:	64e2                	ld	s1,24(sp)
ffffffffc020159a:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020159c:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020159e:	03065633          	divu	a2,a2,a6
ffffffffc02015a2:	8722                	mv	a4,s0
ffffffffc02015a4:	f9bff0ef          	jal	ra,ffffffffc020153e <printnum>
ffffffffc02015a8:	b7f9                	j	ffffffffc0201576 <printnum+0x38>

ffffffffc02015aa <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02015aa:	7119                	addi	sp,sp,-128
ffffffffc02015ac:	f4a6                	sd	s1,104(sp)
ffffffffc02015ae:	f0ca                	sd	s2,96(sp)
ffffffffc02015b0:	ecce                	sd	s3,88(sp)
ffffffffc02015b2:	e8d2                	sd	s4,80(sp)
ffffffffc02015b4:	e4d6                	sd	s5,72(sp)
ffffffffc02015b6:	e0da                	sd	s6,64(sp)
ffffffffc02015b8:	fc5e                	sd	s7,56(sp)
ffffffffc02015ba:	f06a                	sd	s10,32(sp)
ffffffffc02015bc:	fc86                	sd	ra,120(sp)
ffffffffc02015be:	f8a2                	sd	s0,112(sp)
ffffffffc02015c0:	f862                	sd	s8,48(sp)
ffffffffc02015c2:	f466                	sd	s9,40(sp)
ffffffffc02015c4:	ec6e                	sd	s11,24(sp)
ffffffffc02015c6:	892a                	mv	s2,a0
ffffffffc02015c8:	84ae                	mv	s1,a1
ffffffffc02015ca:	8d32                	mv	s10,a2
ffffffffc02015cc:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02015ce:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02015d2:	5b7d                	li	s6,-1
ffffffffc02015d4:	00001a97          	auipc	s5,0x1
ffffffffc02015d8:	558a8a93          	addi	s5,s5,1368 # ffffffffc0202b2c <buddy_pmm_manager+0x6c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02015dc:	00001b97          	auipc	s7,0x1
ffffffffc02015e0:	72cb8b93          	addi	s7,s7,1836 # ffffffffc0202d08 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02015e4:	000d4503          	lbu	a0,0(s10)
ffffffffc02015e8:	001d0413          	addi	s0,s10,1
ffffffffc02015ec:	01350a63          	beq	a0,s3,ffffffffc0201600 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc02015f0:	c121                	beqz	a0,ffffffffc0201630 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc02015f2:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02015f4:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02015f6:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02015f8:	fff44503          	lbu	a0,-1(s0)
ffffffffc02015fc:	ff351ae3          	bne	a0,s3,ffffffffc02015f0 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201600:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201604:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201608:	4c81                	li	s9,0
ffffffffc020160a:	4881                	li	a7,0
        width = precision = -1;
ffffffffc020160c:	5c7d                	li	s8,-1
ffffffffc020160e:	5dfd                	li	s11,-1
ffffffffc0201610:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201614:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201616:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020161a:	0ff5f593          	zext.b	a1,a1
ffffffffc020161e:	00140d13          	addi	s10,s0,1
ffffffffc0201622:	04b56263          	bltu	a0,a1,ffffffffc0201666 <vprintfmt+0xbc>
ffffffffc0201626:	058a                	slli	a1,a1,0x2
ffffffffc0201628:	95d6                	add	a1,a1,s5
ffffffffc020162a:	4194                	lw	a3,0(a1)
ffffffffc020162c:	96d6                	add	a3,a3,s5
ffffffffc020162e:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201630:	70e6                	ld	ra,120(sp)
ffffffffc0201632:	7446                	ld	s0,112(sp)
ffffffffc0201634:	74a6                	ld	s1,104(sp)
ffffffffc0201636:	7906                	ld	s2,96(sp)
ffffffffc0201638:	69e6                	ld	s3,88(sp)
ffffffffc020163a:	6a46                	ld	s4,80(sp)
ffffffffc020163c:	6aa6                	ld	s5,72(sp)
ffffffffc020163e:	6b06                	ld	s6,64(sp)
ffffffffc0201640:	7be2                	ld	s7,56(sp)
ffffffffc0201642:	7c42                	ld	s8,48(sp)
ffffffffc0201644:	7ca2                	ld	s9,40(sp)
ffffffffc0201646:	7d02                	ld	s10,32(sp)
ffffffffc0201648:	6de2                	ld	s11,24(sp)
ffffffffc020164a:	6109                	addi	sp,sp,128
ffffffffc020164c:	8082                	ret
            padc = '0';
ffffffffc020164e:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201650:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201654:	846a                	mv	s0,s10
ffffffffc0201656:	00140d13          	addi	s10,s0,1
ffffffffc020165a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020165e:	0ff5f593          	zext.b	a1,a1
ffffffffc0201662:	fcb572e3          	bgeu	a0,a1,ffffffffc0201626 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201666:	85a6                	mv	a1,s1
ffffffffc0201668:	02500513          	li	a0,37
ffffffffc020166c:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020166e:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201672:	8d22                	mv	s10,s0
ffffffffc0201674:	f73788e3          	beq	a5,s3,ffffffffc02015e4 <vprintfmt+0x3a>
ffffffffc0201678:	ffed4783          	lbu	a5,-2(s10)
ffffffffc020167c:	1d7d                	addi	s10,s10,-1
ffffffffc020167e:	ff379de3          	bne	a5,s3,ffffffffc0201678 <vprintfmt+0xce>
ffffffffc0201682:	b78d                	j	ffffffffc02015e4 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201684:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201688:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020168c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020168e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201692:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201696:	02d86463          	bltu	a6,a3,ffffffffc02016be <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020169a:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020169e:	002c169b          	slliw	a3,s8,0x2
ffffffffc02016a2:	0186873b          	addw	a4,a3,s8
ffffffffc02016a6:	0017171b          	slliw	a4,a4,0x1
ffffffffc02016aa:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc02016ac:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02016b0:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02016b2:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc02016b6:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc02016ba:	fed870e3          	bgeu	a6,a3,ffffffffc020169a <vprintfmt+0xf0>
            if (width < 0)
ffffffffc02016be:	f40ddce3          	bgez	s11,ffffffffc0201616 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc02016c2:	8de2                	mv	s11,s8
ffffffffc02016c4:	5c7d                	li	s8,-1
ffffffffc02016c6:	bf81                	j	ffffffffc0201616 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc02016c8:	fffdc693          	not	a3,s11
ffffffffc02016cc:	96fd                	srai	a3,a3,0x3f
ffffffffc02016ce:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016d2:	00144603          	lbu	a2,1(s0)
ffffffffc02016d6:	2d81                	sext.w	s11,s11
ffffffffc02016d8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02016da:	bf35                	j	ffffffffc0201616 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc02016dc:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016e0:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02016e4:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016e6:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc02016e8:	bfd9                	j	ffffffffc02016be <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc02016ea:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02016ec:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02016f0:	01174463          	blt	a4,a7,ffffffffc02016f8 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc02016f4:	1a088e63          	beqz	a7,ffffffffc02018b0 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc02016f8:	000a3603          	ld	a2,0(s4)
ffffffffc02016fc:	46c1                	li	a3,16
ffffffffc02016fe:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201700:	2781                	sext.w	a5,a5
ffffffffc0201702:	876e                	mv	a4,s11
ffffffffc0201704:	85a6                	mv	a1,s1
ffffffffc0201706:	854a                	mv	a0,s2
ffffffffc0201708:	e37ff0ef          	jal	ra,ffffffffc020153e <printnum>
            break;
ffffffffc020170c:	bde1                	j	ffffffffc02015e4 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc020170e:	000a2503          	lw	a0,0(s4)
ffffffffc0201712:	85a6                	mv	a1,s1
ffffffffc0201714:	0a21                	addi	s4,s4,8
ffffffffc0201716:	9902                	jalr	s2
            break;
ffffffffc0201718:	b5f1                	j	ffffffffc02015e4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020171a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020171c:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201720:	01174463          	blt	a4,a7,ffffffffc0201728 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201724:	18088163          	beqz	a7,ffffffffc02018a6 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201728:	000a3603          	ld	a2,0(s4)
ffffffffc020172c:	46a9                	li	a3,10
ffffffffc020172e:	8a2e                	mv	s4,a1
ffffffffc0201730:	bfc1                	j	ffffffffc0201700 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201732:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201736:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201738:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020173a:	bdf1                	j	ffffffffc0201616 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc020173c:	85a6                	mv	a1,s1
ffffffffc020173e:	02500513          	li	a0,37
ffffffffc0201742:	9902                	jalr	s2
            break;
ffffffffc0201744:	b545                	j	ffffffffc02015e4 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201746:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc020174a:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020174c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020174e:	b5e1                	j	ffffffffc0201616 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201750:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201752:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201756:	01174463          	blt	a4,a7,ffffffffc020175e <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc020175a:	14088163          	beqz	a7,ffffffffc020189c <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc020175e:	000a3603          	ld	a2,0(s4)
ffffffffc0201762:	46a1                	li	a3,8
ffffffffc0201764:	8a2e                	mv	s4,a1
ffffffffc0201766:	bf69                	j	ffffffffc0201700 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201768:	03000513          	li	a0,48
ffffffffc020176c:	85a6                	mv	a1,s1
ffffffffc020176e:	e03e                	sd	a5,0(sp)
ffffffffc0201770:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201772:	85a6                	mv	a1,s1
ffffffffc0201774:	07800513          	li	a0,120
ffffffffc0201778:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020177a:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc020177c:	6782                	ld	a5,0(sp)
ffffffffc020177e:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201780:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201784:	bfb5                	j	ffffffffc0201700 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201786:	000a3403          	ld	s0,0(s4)
ffffffffc020178a:	008a0713          	addi	a4,s4,8
ffffffffc020178e:	e03a                	sd	a4,0(sp)
ffffffffc0201790:	14040263          	beqz	s0,ffffffffc02018d4 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201794:	0fb05763          	blez	s11,ffffffffc0201882 <vprintfmt+0x2d8>
ffffffffc0201798:	02d00693          	li	a3,45
ffffffffc020179c:	0cd79163          	bne	a5,a3,ffffffffc020185e <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02017a0:	00044783          	lbu	a5,0(s0)
ffffffffc02017a4:	0007851b          	sext.w	a0,a5
ffffffffc02017a8:	cf85                	beqz	a5,ffffffffc02017e0 <vprintfmt+0x236>
ffffffffc02017aa:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02017ae:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02017b2:	000c4563          	bltz	s8,ffffffffc02017bc <vprintfmt+0x212>
ffffffffc02017b6:	3c7d                	addiw	s8,s8,-1
ffffffffc02017b8:	036c0263          	beq	s8,s6,ffffffffc02017dc <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc02017bc:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02017be:	0e0c8e63          	beqz	s9,ffffffffc02018ba <vprintfmt+0x310>
ffffffffc02017c2:	3781                	addiw	a5,a5,-32
ffffffffc02017c4:	0ef47b63          	bgeu	s0,a5,ffffffffc02018ba <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc02017c8:	03f00513          	li	a0,63
ffffffffc02017cc:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02017ce:	000a4783          	lbu	a5,0(s4)
ffffffffc02017d2:	3dfd                	addiw	s11,s11,-1
ffffffffc02017d4:	0a05                	addi	s4,s4,1
ffffffffc02017d6:	0007851b          	sext.w	a0,a5
ffffffffc02017da:	ffe1                	bnez	a5,ffffffffc02017b2 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc02017dc:	01b05963          	blez	s11,ffffffffc02017ee <vprintfmt+0x244>
ffffffffc02017e0:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02017e2:	85a6                	mv	a1,s1
ffffffffc02017e4:	02000513          	li	a0,32
ffffffffc02017e8:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02017ea:	fe0d9be3          	bnez	s11,ffffffffc02017e0 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02017ee:	6a02                	ld	s4,0(sp)
ffffffffc02017f0:	bbd5                	j	ffffffffc02015e4 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02017f2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02017f4:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc02017f8:	01174463          	blt	a4,a7,ffffffffc0201800 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02017fc:	08088d63          	beqz	a7,ffffffffc0201896 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201800:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201804:	0a044d63          	bltz	s0,ffffffffc02018be <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201808:	8622                	mv	a2,s0
ffffffffc020180a:	8a66                	mv	s4,s9
ffffffffc020180c:	46a9                	li	a3,10
ffffffffc020180e:	bdcd                	j	ffffffffc0201700 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201810:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201814:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201816:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201818:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc020181c:	8fb5                	xor	a5,a5,a3
ffffffffc020181e:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201822:	02d74163          	blt	a4,a3,ffffffffc0201844 <vprintfmt+0x29a>
ffffffffc0201826:	00369793          	slli	a5,a3,0x3
ffffffffc020182a:	97de                	add	a5,a5,s7
ffffffffc020182c:	639c                	ld	a5,0(a5)
ffffffffc020182e:	cb99                	beqz	a5,ffffffffc0201844 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201830:	86be                	mv	a3,a5
ffffffffc0201832:	00001617          	auipc	a2,0x1
ffffffffc0201836:	2f660613          	addi	a2,a2,758 # ffffffffc0202b28 <buddy_pmm_manager+0x68>
ffffffffc020183a:	85a6                	mv	a1,s1
ffffffffc020183c:	854a                	mv	a0,s2
ffffffffc020183e:	0ce000ef          	jal	ra,ffffffffc020190c <printfmt>
ffffffffc0201842:	b34d                	j	ffffffffc02015e4 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201844:	00001617          	auipc	a2,0x1
ffffffffc0201848:	2d460613          	addi	a2,a2,724 # ffffffffc0202b18 <buddy_pmm_manager+0x58>
ffffffffc020184c:	85a6                	mv	a1,s1
ffffffffc020184e:	854a                	mv	a0,s2
ffffffffc0201850:	0bc000ef          	jal	ra,ffffffffc020190c <printfmt>
ffffffffc0201854:	bb41                	j	ffffffffc02015e4 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201856:	00001417          	auipc	s0,0x1
ffffffffc020185a:	2ba40413          	addi	s0,s0,698 # ffffffffc0202b10 <buddy_pmm_manager+0x50>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020185e:	85e2                	mv	a1,s8
ffffffffc0201860:	8522                	mv	a0,s0
ffffffffc0201862:	e43e                	sd	a5,8(sp)
ffffffffc0201864:	c79ff0ef          	jal	ra,ffffffffc02014dc <strnlen>
ffffffffc0201868:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020186c:	01b05b63          	blez	s11,ffffffffc0201882 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201870:	67a2                	ld	a5,8(sp)
ffffffffc0201872:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201876:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201878:	85a6                	mv	a1,s1
ffffffffc020187a:	8552                	mv	a0,s4
ffffffffc020187c:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020187e:	fe0d9ce3          	bnez	s11,ffffffffc0201876 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201882:	00044783          	lbu	a5,0(s0)
ffffffffc0201886:	00140a13          	addi	s4,s0,1
ffffffffc020188a:	0007851b          	sext.w	a0,a5
ffffffffc020188e:	d3a5                	beqz	a5,ffffffffc02017ee <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201890:	05e00413          	li	s0,94
ffffffffc0201894:	bf39                	j	ffffffffc02017b2 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201896:	000a2403          	lw	s0,0(s4)
ffffffffc020189a:	b7ad                	j	ffffffffc0201804 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc020189c:	000a6603          	lwu	a2,0(s4)
ffffffffc02018a0:	46a1                	li	a3,8
ffffffffc02018a2:	8a2e                	mv	s4,a1
ffffffffc02018a4:	bdb1                	j	ffffffffc0201700 <vprintfmt+0x156>
ffffffffc02018a6:	000a6603          	lwu	a2,0(s4)
ffffffffc02018aa:	46a9                	li	a3,10
ffffffffc02018ac:	8a2e                	mv	s4,a1
ffffffffc02018ae:	bd89                	j	ffffffffc0201700 <vprintfmt+0x156>
ffffffffc02018b0:	000a6603          	lwu	a2,0(s4)
ffffffffc02018b4:	46c1                	li	a3,16
ffffffffc02018b6:	8a2e                	mv	s4,a1
ffffffffc02018b8:	b5a1                	j	ffffffffc0201700 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc02018ba:	9902                	jalr	s2
ffffffffc02018bc:	bf09                	j	ffffffffc02017ce <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc02018be:	85a6                	mv	a1,s1
ffffffffc02018c0:	02d00513          	li	a0,45
ffffffffc02018c4:	e03e                	sd	a5,0(sp)
ffffffffc02018c6:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02018c8:	6782                	ld	a5,0(sp)
ffffffffc02018ca:	8a66                	mv	s4,s9
ffffffffc02018cc:	40800633          	neg	a2,s0
ffffffffc02018d0:	46a9                	li	a3,10
ffffffffc02018d2:	b53d                	j	ffffffffc0201700 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc02018d4:	03b05163          	blez	s11,ffffffffc02018f6 <vprintfmt+0x34c>
ffffffffc02018d8:	02d00693          	li	a3,45
ffffffffc02018dc:	f6d79de3          	bne	a5,a3,ffffffffc0201856 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc02018e0:	00001417          	auipc	s0,0x1
ffffffffc02018e4:	23040413          	addi	s0,s0,560 # ffffffffc0202b10 <buddy_pmm_manager+0x50>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02018e8:	02800793          	li	a5,40
ffffffffc02018ec:	02800513          	li	a0,40
ffffffffc02018f0:	00140a13          	addi	s4,s0,1
ffffffffc02018f4:	bd6d                	j	ffffffffc02017ae <vprintfmt+0x204>
ffffffffc02018f6:	00001a17          	auipc	s4,0x1
ffffffffc02018fa:	21ba0a13          	addi	s4,s4,539 # ffffffffc0202b11 <buddy_pmm_manager+0x51>
ffffffffc02018fe:	02800513          	li	a0,40
ffffffffc0201902:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201906:	05e00413          	li	s0,94
ffffffffc020190a:	b565                	j	ffffffffc02017b2 <vprintfmt+0x208>

ffffffffc020190c <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020190c:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020190e:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201912:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201914:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201916:	ec06                	sd	ra,24(sp)
ffffffffc0201918:	f83a                	sd	a4,48(sp)
ffffffffc020191a:	fc3e                	sd	a5,56(sp)
ffffffffc020191c:	e0c2                	sd	a6,64(sp)
ffffffffc020191e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201920:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201922:	c89ff0ef          	jal	ra,ffffffffc02015aa <vprintfmt>
}
ffffffffc0201926:	60e2                	ld	ra,24(sp)
ffffffffc0201928:	6161                	addi	sp,sp,80
ffffffffc020192a:	8082                	ret

ffffffffc020192c <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc020192c:	715d                	addi	sp,sp,-80
ffffffffc020192e:	e486                	sd	ra,72(sp)
ffffffffc0201930:	e0a6                	sd	s1,64(sp)
ffffffffc0201932:	fc4a                	sd	s2,56(sp)
ffffffffc0201934:	f84e                	sd	s3,48(sp)
ffffffffc0201936:	f452                	sd	s4,40(sp)
ffffffffc0201938:	f056                	sd	s5,32(sp)
ffffffffc020193a:	ec5a                	sd	s6,24(sp)
ffffffffc020193c:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc020193e:	c901                	beqz	a0,ffffffffc020194e <readline+0x22>
ffffffffc0201940:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201942:	00001517          	auipc	a0,0x1
ffffffffc0201946:	1e650513          	addi	a0,a0,486 # ffffffffc0202b28 <buddy_pmm_manager+0x68>
ffffffffc020194a:	f68fe0ef          	jal	ra,ffffffffc02000b2 <cprintf>
readline(const char *prompt) {
ffffffffc020194e:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201950:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201952:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201954:	4aa9                	li	s5,10
ffffffffc0201956:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201958:	00004b97          	auipc	s7,0x4
ffffffffc020195c:	7c8b8b93          	addi	s7,s7,1992 # ffffffffc0206120 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201960:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201964:	fc6fe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201968:	00054a63          	bltz	a0,ffffffffc020197c <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020196c:	00a95a63          	bge	s2,a0,ffffffffc0201980 <readline+0x54>
ffffffffc0201970:	029a5263          	bge	s4,s1,ffffffffc0201994 <readline+0x68>
        c = getchar();
ffffffffc0201974:	fb6fe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc0201978:	fe055ae3          	bgez	a0,ffffffffc020196c <readline+0x40>
            return NULL;
ffffffffc020197c:	4501                	li	a0,0
ffffffffc020197e:	a091                	j	ffffffffc02019c2 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201980:	03351463          	bne	a0,s3,ffffffffc02019a8 <readline+0x7c>
ffffffffc0201984:	e8a9                	bnez	s1,ffffffffc02019d6 <readline+0xaa>
        c = getchar();
ffffffffc0201986:	fa4fe0ef          	jal	ra,ffffffffc020012a <getchar>
        if (c < 0) {
ffffffffc020198a:	fe0549e3          	bltz	a0,ffffffffc020197c <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc020198e:	fea959e3          	bge	s2,a0,ffffffffc0201980 <readline+0x54>
ffffffffc0201992:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201994:	e42a                	sd	a0,8(sp)
ffffffffc0201996:	f52fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i ++] = c;
ffffffffc020199a:	6522                	ld	a0,8(sp)
ffffffffc020199c:	009b87b3          	add	a5,s7,s1
ffffffffc02019a0:	2485                	addiw	s1,s1,1
ffffffffc02019a2:	00a78023          	sb	a0,0(a5)
ffffffffc02019a6:	bf7d                	j	ffffffffc0201964 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02019a8:	01550463          	beq	a0,s5,ffffffffc02019b0 <readline+0x84>
ffffffffc02019ac:	fb651ce3          	bne	a0,s6,ffffffffc0201964 <readline+0x38>
            cputchar(c);
ffffffffc02019b0:	f38fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            buf[i] = '\0';
ffffffffc02019b4:	00004517          	auipc	a0,0x4
ffffffffc02019b8:	76c50513          	addi	a0,a0,1900 # ffffffffc0206120 <buf>
ffffffffc02019bc:	94aa                	add	s1,s1,a0
ffffffffc02019be:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02019c2:	60a6                	ld	ra,72(sp)
ffffffffc02019c4:	6486                	ld	s1,64(sp)
ffffffffc02019c6:	7962                	ld	s2,56(sp)
ffffffffc02019c8:	79c2                	ld	s3,48(sp)
ffffffffc02019ca:	7a22                	ld	s4,40(sp)
ffffffffc02019cc:	7a82                	ld	s5,32(sp)
ffffffffc02019ce:	6b62                	ld	s6,24(sp)
ffffffffc02019d0:	6bc2                	ld	s7,16(sp)
ffffffffc02019d2:	6161                	addi	sp,sp,80
ffffffffc02019d4:	8082                	ret
            cputchar(c);
ffffffffc02019d6:	4521                	li	a0,8
ffffffffc02019d8:	f10fe0ef          	jal	ra,ffffffffc02000e8 <cputchar>
            i --;
ffffffffc02019dc:	34fd                	addiw	s1,s1,-1
ffffffffc02019de:	b759                	j	ffffffffc0201964 <readline+0x38>

ffffffffc02019e0 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc02019e0:	4781                	li	a5,0
ffffffffc02019e2:	00004717          	auipc	a4,0x4
ffffffffc02019e6:	62673703          	ld	a4,1574(a4) # ffffffffc0206008 <SBI_CONSOLE_PUTCHAR>
ffffffffc02019ea:	88ba                	mv	a7,a4
ffffffffc02019ec:	852a                	mv	a0,a0
ffffffffc02019ee:	85be                	mv	a1,a5
ffffffffc02019f0:	863e                	mv	a2,a5
ffffffffc02019f2:	00000073          	ecall
ffffffffc02019f6:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02019f8:	8082                	ret

ffffffffc02019fa <sbi_set_timer>:
    __asm__ volatile (
ffffffffc02019fa:	4781                	li	a5,0
ffffffffc02019fc:	00005717          	auipc	a4,0x5
ffffffffc0201a00:	b6c73703          	ld	a4,-1172(a4) # ffffffffc0206568 <SBI_SET_TIMER>
ffffffffc0201a04:	88ba                	mv	a7,a4
ffffffffc0201a06:	852a                	mv	a0,a0
ffffffffc0201a08:	85be                	mv	a1,a5
ffffffffc0201a0a:	863e                	mv	a2,a5
ffffffffc0201a0c:	00000073          	ecall
ffffffffc0201a10:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201a12:	8082                	ret

ffffffffc0201a14 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201a14:	4501                	li	a0,0
ffffffffc0201a16:	00004797          	auipc	a5,0x4
ffffffffc0201a1a:	5ea7b783          	ld	a5,1514(a5) # ffffffffc0206000 <SBI_CONSOLE_GETCHAR>
ffffffffc0201a1e:	88be                	mv	a7,a5
ffffffffc0201a20:	852a                	mv	a0,a0
ffffffffc0201a22:	85aa                	mv	a1,a0
ffffffffc0201a24:	862a                	mv	a2,a0
ffffffffc0201a26:	00000073          	ecall
ffffffffc0201a2a:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201a2c:	2501                	sext.w	a0,a0
ffffffffc0201a2e:	8082                	ret

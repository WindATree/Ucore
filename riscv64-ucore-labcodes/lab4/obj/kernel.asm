
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c020a2b7          	lui	t0,0xc020a
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
ffffffffc0200024:	c020a137          	lui	sp,0xc020a

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

int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200032:	0000b517          	auipc	a0,0xb
ffffffffc0200036:	02e50513          	addi	a0,a0,46 # ffffffffc020b060 <buf>
ffffffffc020003a:	00016617          	auipc	a2,0x16
ffffffffc020003e:	59260613          	addi	a2,a2,1426 # ffffffffc02165cc <end>
kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	2af040ef          	jal	ra,ffffffffc0204af8 <memset>

    cons_init();                // init the console
ffffffffc020004e:	4fc000ef          	jal	ra,ffffffffc020054a <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200052:	00005597          	auipc	a1,0x5
ffffffffc0200056:	efe58593          	addi	a1,a1,-258 # ffffffffc0204f50 <etext+0x6>
ffffffffc020005a:	00005517          	auipc	a0,0x5
ffffffffc020005e:	f1650513          	addi	a0,a0,-234 # ffffffffc0204f70 <etext+0x26>
ffffffffc0200062:	06a000ef          	jal	ra,ffffffffc02000cc <cprintf>

    print_kerninfo();
ffffffffc0200066:	1be000ef          	jal	ra,ffffffffc0200224 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006a:	41e030ef          	jal	ra,ffffffffc0203488 <pmm_init>

    pic_init();                 // init interrupt controller
ffffffffc020006e:	54e000ef          	jal	ra,ffffffffc02005bc <pic_init>
    idt_init();                 // init interrupt descriptor table
ffffffffc0200072:	5c8000ef          	jal	ra,ffffffffc020063a <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc0200076:	4d5000ef          	jal	ra,ffffffffc0200d4a <vmm_init>
    proc_init();                // init process table
ffffffffc020007a:	6d2040ef          	jal	ra,ffffffffc020474c <proc_init>
    
    ide_init();                 // init ide devices
ffffffffc020007e:	424000ef          	jal	ra,ffffffffc02004a2 <ide_init>
    swap_init();                // init swap
ffffffffc0200082:	37d010ef          	jal	ra,ffffffffc0201bfe <swap_init>

    clock_init();               // init clock interrupt
ffffffffc0200086:	472000ef          	jal	ra,ffffffffc02004f8 <clock_init>
    intr_enable();              // enable irq interrupt
ffffffffc020008a:	534000ef          	jal	ra,ffffffffc02005be <intr_enable>

    cpu_idle();                 // run idle process
ffffffffc020008e:	10d040ef          	jal	ra,ffffffffc020499a <cpu_idle>

ffffffffc0200092 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200092:	1141                	addi	sp,sp,-16
ffffffffc0200094:	e022                	sd	s0,0(sp)
ffffffffc0200096:	e406                	sd	ra,8(sp)
ffffffffc0200098:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020009a:	4b2000ef          	jal	ra,ffffffffc020054c <cons_putc>
    (*cnt) ++;
ffffffffc020009e:	401c                	lw	a5,0(s0)
}
ffffffffc02000a0:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000a2:	2785                	addiw	a5,a5,1
ffffffffc02000a4:	c01c                	sw	a5,0(s0)
}
ffffffffc02000a6:	6402                	ld	s0,0(sp)
ffffffffc02000a8:	0141                	addi	sp,sp,16
ffffffffc02000aa:	8082                	ret

ffffffffc02000ac <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000ac:	1101                	addi	sp,sp,-32
ffffffffc02000ae:	862a                	mv	a2,a0
ffffffffc02000b0:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000b2:	00000517          	auipc	a0,0x0
ffffffffc02000b6:	fe050513          	addi	a0,a0,-32 # ffffffffc0200092 <cputch>
ffffffffc02000ba:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000bc:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000be:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000c0:	2f3040ef          	jal	ra,ffffffffc0204bb2 <vprintfmt>
    return cnt;
}
ffffffffc02000c4:	60e2                	ld	ra,24(sp)
ffffffffc02000c6:	4532                	lw	a0,12(sp)
ffffffffc02000c8:	6105                	addi	sp,sp,32
ffffffffc02000ca:	8082                	ret

ffffffffc02000cc <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000cc:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000ce:	02810313          	addi	t1,sp,40 # ffffffffc020a028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000d2:	8e2a                	mv	t3,a0
ffffffffc02000d4:	f42e                	sd	a1,40(sp)
ffffffffc02000d6:	f832                	sd	a2,48(sp)
ffffffffc02000d8:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000da:	00000517          	auipc	a0,0x0
ffffffffc02000de:	fb850513          	addi	a0,a0,-72 # ffffffffc0200092 <cputch>
ffffffffc02000e2:	004c                	addi	a1,sp,4
ffffffffc02000e4:	869a                	mv	a3,t1
ffffffffc02000e6:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000e8:	ec06                	sd	ra,24(sp)
ffffffffc02000ea:	e0ba                	sd	a4,64(sp)
ffffffffc02000ec:	e4be                	sd	a5,72(sp)
ffffffffc02000ee:	e8c2                	sd	a6,80(sp)
ffffffffc02000f0:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000f2:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02000f4:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000f6:	2bd040ef          	jal	ra,ffffffffc0204bb2 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02000fa:	60e2                	ld	ra,24(sp)
ffffffffc02000fc:	4512                	lw	a0,4(sp)
ffffffffc02000fe:	6125                	addi	sp,sp,96
ffffffffc0200100:	8082                	ret

ffffffffc0200102 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200102:	a1a9                	j	ffffffffc020054c <cons_putc>

ffffffffc0200104 <getchar>:
    return cnt;
}

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200104:	1141                	addi	sp,sp,-16
ffffffffc0200106:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200108:	478000ef          	jal	ra,ffffffffc0200580 <cons_getc>
ffffffffc020010c:	dd75                	beqz	a0,ffffffffc0200108 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020010e:	60a2                	ld	ra,8(sp)
ffffffffc0200110:	0141                	addi	sp,sp,16
ffffffffc0200112:	8082                	ret

ffffffffc0200114 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0200114:	715d                	addi	sp,sp,-80
ffffffffc0200116:	e486                	sd	ra,72(sp)
ffffffffc0200118:	e0a6                	sd	s1,64(sp)
ffffffffc020011a:	fc4a                	sd	s2,56(sp)
ffffffffc020011c:	f84e                	sd	s3,48(sp)
ffffffffc020011e:	f452                	sd	s4,40(sp)
ffffffffc0200120:	f056                	sd	s5,32(sp)
ffffffffc0200122:	ec5a                	sd	s6,24(sp)
ffffffffc0200124:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0200126:	c901                	beqz	a0,ffffffffc0200136 <readline+0x22>
ffffffffc0200128:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc020012a:	00005517          	auipc	a0,0x5
ffffffffc020012e:	e4e50513          	addi	a0,a0,-434 # ffffffffc0204f78 <etext+0x2e>
ffffffffc0200132:	f9bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
readline(const char *prompt) {
ffffffffc0200136:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200138:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc020013a:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc020013c:	4aa9                	li	s5,10
ffffffffc020013e:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0200140:	0000bb97          	auipc	s7,0xb
ffffffffc0200144:	f20b8b93          	addi	s7,s7,-224 # ffffffffc020b060 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200148:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc020014c:	fb9ff0ef          	jal	ra,ffffffffc0200104 <getchar>
        if (c < 0) {
ffffffffc0200150:	00054a63          	bltz	a0,ffffffffc0200164 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200154:	00a95a63          	bge	s2,a0,ffffffffc0200168 <readline+0x54>
ffffffffc0200158:	029a5263          	bge	s4,s1,ffffffffc020017c <readline+0x68>
        c = getchar();
ffffffffc020015c:	fa9ff0ef          	jal	ra,ffffffffc0200104 <getchar>
        if (c < 0) {
ffffffffc0200160:	fe055ae3          	bgez	a0,ffffffffc0200154 <readline+0x40>
            return NULL;
ffffffffc0200164:	4501                	li	a0,0
ffffffffc0200166:	a091                	j	ffffffffc02001aa <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0200168:	03351463          	bne	a0,s3,ffffffffc0200190 <readline+0x7c>
ffffffffc020016c:	e8a9                	bnez	s1,ffffffffc02001be <readline+0xaa>
        c = getchar();
ffffffffc020016e:	f97ff0ef          	jal	ra,ffffffffc0200104 <getchar>
        if (c < 0) {
ffffffffc0200172:	fe0549e3          	bltz	a0,ffffffffc0200164 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200176:	fea959e3          	bge	s2,a0,ffffffffc0200168 <readline+0x54>
ffffffffc020017a:	4481                	li	s1,0
            cputchar(c);
ffffffffc020017c:	e42a                	sd	a0,8(sp)
ffffffffc020017e:	f85ff0ef          	jal	ra,ffffffffc0200102 <cputchar>
            buf[i ++] = c;
ffffffffc0200182:	6522                	ld	a0,8(sp)
ffffffffc0200184:	009b87b3          	add	a5,s7,s1
ffffffffc0200188:	2485                	addiw	s1,s1,1
ffffffffc020018a:	00a78023          	sb	a0,0(a5)
ffffffffc020018e:	bf7d                	j	ffffffffc020014c <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0200190:	01550463          	beq	a0,s5,ffffffffc0200198 <readline+0x84>
ffffffffc0200194:	fb651ce3          	bne	a0,s6,ffffffffc020014c <readline+0x38>
            cputchar(c);
ffffffffc0200198:	f6bff0ef          	jal	ra,ffffffffc0200102 <cputchar>
            buf[i] = '\0';
ffffffffc020019c:	0000b517          	auipc	a0,0xb
ffffffffc02001a0:	ec450513          	addi	a0,a0,-316 # ffffffffc020b060 <buf>
ffffffffc02001a4:	94aa                	add	s1,s1,a0
ffffffffc02001a6:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02001aa:	60a6                	ld	ra,72(sp)
ffffffffc02001ac:	6486                	ld	s1,64(sp)
ffffffffc02001ae:	7962                	ld	s2,56(sp)
ffffffffc02001b0:	79c2                	ld	s3,48(sp)
ffffffffc02001b2:	7a22                	ld	s4,40(sp)
ffffffffc02001b4:	7a82                	ld	s5,32(sp)
ffffffffc02001b6:	6b62                	ld	s6,24(sp)
ffffffffc02001b8:	6bc2                	ld	s7,16(sp)
ffffffffc02001ba:	6161                	addi	sp,sp,80
ffffffffc02001bc:	8082                	ret
            cputchar(c);
ffffffffc02001be:	4521                	li	a0,8
ffffffffc02001c0:	f43ff0ef          	jal	ra,ffffffffc0200102 <cputchar>
            i --;
ffffffffc02001c4:	34fd                	addiw	s1,s1,-1
ffffffffc02001c6:	b759                	j	ffffffffc020014c <readline+0x38>

ffffffffc02001c8 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c8:	00016317          	auipc	t1,0x16
ffffffffc02001cc:	37030313          	addi	t1,t1,880 # ffffffffc0216538 <is_panic>
ffffffffc02001d0:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d4:	715d                	addi	sp,sp,-80
ffffffffc02001d6:	ec06                	sd	ra,24(sp)
ffffffffc02001d8:	e822                	sd	s0,16(sp)
ffffffffc02001da:	f436                	sd	a3,40(sp)
ffffffffc02001dc:	f83a                	sd	a4,48(sp)
ffffffffc02001de:	fc3e                	sd	a5,56(sp)
ffffffffc02001e0:	e0c2                	sd	a6,64(sp)
ffffffffc02001e2:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e4:	020e1a63          	bnez	t3,ffffffffc0200218 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02001e8:	4785                	li	a5,1
ffffffffc02001ea:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02001ee:	8432                	mv	s0,a2
ffffffffc02001f0:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f2:	862e                	mv	a2,a1
ffffffffc02001f4:	85aa                	mv	a1,a0
ffffffffc02001f6:	00005517          	auipc	a0,0x5
ffffffffc02001fa:	d8a50513          	addi	a0,a0,-630 # ffffffffc0204f80 <etext+0x36>
    va_start(ap, fmt);
ffffffffc02001fe:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200200:	ecdff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200204:	65a2                	ld	a1,8(sp)
ffffffffc0200206:	8522                	mv	a0,s0
ffffffffc0200208:	ea5ff0ef          	jal	ra,ffffffffc02000ac <vcprintf>
    cprintf("\n");
ffffffffc020020c:	00007517          	auipc	a0,0x7
ffffffffc0200210:	81450513          	addi	a0,a0,-2028 # ffffffffc0206a20 <default_pmm_manager+0x3b8>
ffffffffc0200214:	eb9ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200218:	3ac000ef          	jal	ra,ffffffffc02005c4 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc020021c:	4501                	li	a0,0
ffffffffc020021e:	130000ef          	jal	ra,ffffffffc020034e <kmonitor>
    while (1) {
ffffffffc0200222:	bfed                	j	ffffffffc020021c <__panic+0x54>

ffffffffc0200224 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200224:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200226:	00005517          	auipc	a0,0x5
ffffffffc020022a:	d7a50513          	addi	a0,a0,-646 # ffffffffc0204fa0 <etext+0x56>
void print_kerninfo(void) {
ffffffffc020022e:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200230:	e9dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200234:	00000597          	auipc	a1,0x0
ffffffffc0200238:	dfe58593          	addi	a1,a1,-514 # ffffffffc0200032 <kern_init>
ffffffffc020023c:	00005517          	auipc	a0,0x5
ffffffffc0200240:	d8450513          	addi	a0,a0,-636 # ffffffffc0204fc0 <etext+0x76>
ffffffffc0200244:	e89ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc0200248:	00005597          	auipc	a1,0x5
ffffffffc020024c:	d0258593          	addi	a1,a1,-766 # ffffffffc0204f4a <etext>
ffffffffc0200250:	00005517          	auipc	a0,0x5
ffffffffc0200254:	d9050513          	addi	a0,a0,-624 # ffffffffc0204fe0 <etext+0x96>
ffffffffc0200258:	e75ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020025c:	0000b597          	auipc	a1,0xb
ffffffffc0200260:	e0458593          	addi	a1,a1,-508 # ffffffffc020b060 <buf>
ffffffffc0200264:	00005517          	auipc	a0,0x5
ffffffffc0200268:	d9c50513          	addi	a0,a0,-612 # ffffffffc0205000 <etext+0xb6>
ffffffffc020026c:	e61ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200270:	00016597          	auipc	a1,0x16
ffffffffc0200274:	35c58593          	addi	a1,a1,860 # ffffffffc02165cc <end>
ffffffffc0200278:	00005517          	auipc	a0,0x5
ffffffffc020027c:	da850513          	addi	a0,a0,-600 # ffffffffc0205020 <etext+0xd6>
ffffffffc0200280:	e4dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200284:	00016597          	auipc	a1,0x16
ffffffffc0200288:	74758593          	addi	a1,a1,1863 # ffffffffc02169cb <end+0x3ff>
ffffffffc020028c:	00000797          	auipc	a5,0x0
ffffffffc0200290:	da678793          	addi	a5,a5,-602 # ffffffffc0200032 <kern_init>
ffffffffc0200294:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200298:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020029c:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029e:	3ff5f593          	andi	a1,a1,1023
ffffffffc02002a2:	95be                	add	a1,a1,a5
ffffffffc02002a4:	85a9                	srai	a1,a1,0xa
ffffffffc02002a6:	00005517          	auipc	a0,0x5
ffffffffc02002aa:	d9a50513          	addi	a0,a0,-614 # ffffffffc0205040 <etext+0xf6>
}
ffffffffc02002ae:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002b0:	bd31                	j	ffffffffc02000cc <cprintf>

ffffffffc02002b2 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002b2:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002b4:	00005617          	auipc	a2,0x5
ffffffffc02002b8:	dbc60613          	addi	a2,a2,-580 # ffffffffc0205070 <etext+0x126>
ffffffffc02002bc:	04d00593          	li	a1,77
ffffffffc02002c0:	00005517          	auipc	a0,0x5
ffffffffc02002c4:	dc850513          	addi	a0,a0,-568 # ffffffffc0205088 <etext+0x13e>
void print_stackframe(void) {
ffffffffc02002c8:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002ca:	effff0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02002ce <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002ce:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002d0:	00005617          	auipc	a2,0x5
ffffffffc02002d4:	dd060613          	addi	a2,a2,-560 # ffffffffc02050a0 <etext+0x156>
ffffffffc02002d8:	00005597          	auipc	a1,0x5
ffffffffc02002dc:	de858593          	addi	a1,a1,-536 # ffffffffc02050c0 <etext+0x176>
ffffffffc02002e0:	00005517          	auipc	a0,0x5
ffffffffc02002e4:	de850513          	addi	a0,a0,-536 # ffffffffc02050c8 <etext+0x17e>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002e8:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002ea:	de3ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc02002ee:	00005617          	auipc	a2,0x5
ffffffffc02002f2:	dea60613          	addi	a2,a2,-534 # ffffffffc02050d8 <etext+0x18e>
ffffffffc02002f6:	00005597          	auipc	a1,0x5
ffffffffc02002fa:	e0a58593          	addi	a1,a1,-502 # ffffffffc0205100 <etext+0x1b6>
ffffffffc02002fe:	00005517          	auipc	a0,0x5
ffffffffc0200302:	dca50513          	addi	a0,a0,-566 # ffffffffc02050c8 <etext+0x17e>
ffffffffc0200306:	dc7ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc020030a:	00005617          	auipc	a2,0x5
ffffffffc020030e:	e0660613          	addi	a2,a2,-506 # ffffffffc0205110 <etext+0x1c6>
ffffffffc0200312:	00005597          	auipc	a1,0x5
ffffffffc0200316:	e1e58593          	addi	a1,a1,-482 # ffffffffc0205130 <etext+0x1e6>
ffffffffc020031a:	00005517          	auipc	a0,0x5
ffffffffc020031e:	dae50513          	addi	a0,a0,-594 # ffffffffc02050c8 <etext+0x17e>
ffffffffc0200322:	dabff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    }
    return 0;
}
ffffffffc0200326:	60a2                	ld	ra,8(sp)
ffffffffc0200328:	4501                	li	a0,0
ffffffffc020032a:	0141                	addi	sp,sp,16
ffffffffc020032c:	8082                	ret

ffffffffc020032e <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020032e:	1141                	addi	sp,sp,-16
ffffffffc0200330:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200332:	ef3ff0ef          	jal	ra,ffffffffc0200224 <print_kerninfo>
    return 0;
}
ffffffffc0200336:	60a2                	ld	ra,8(sp)
ffffffffc0200338:	4501                	li	a0,0
ffffffffc020033a:	0141                	addi	sp,sp,16
ffffffffc020033c:	8082                	ret

ffffffffc020033e <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020033e:	1141                	addi	sp,sp,-16
ffffffffc0200340:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200342:	f71ff0ef          	jal	ra,ffffffffc02002b2 <print_stackframe>
    return 0;
}
ffffffffc0200346:	60a2                	ld	ra,8(sp)
ffffffffc0200348:	4501                	li	a0,0
ffffffffc020034a:	0141                	addi	sp,sp,16
ffffffffc020034c:	8082                	ret

ffffffffc020034e <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020034e:	7115                	addi	sp,sp,-224
ffffffffc0200350:	ed5e                	sd	s7,152(sp)
ffffffffc0200352:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200354:	00005517          	auipc	a0,0x5
ffffffffc0200358:	dec50513          	addi	a0,a0,-532 # ffffffffc0205140 <etext+0x1f6>
kmonitor(struct trapframe *tf) {
ffffffffc020035c:	ed86                	sd	ra,216(sp)
ffffffffc020035e:	e9a2                	sd	s0,208(sp)
ffffffffc0200360:	e5a6                	sd	s1,200(sp)
ffffffffc0200362:	e1ca                	sd	s2,192(sp)
ffffffffc0200364:	fd4e                	sd	s3,184(sp)
ffffffffc0200366:	f952                	sd	s4,176(sp)
ffffffffc0200368:	f556                	sd	s5,168(sp)
ffffffffc020036a:	f15a                	sd	s6,160(sp)
ffffffffc020036c:	e962                	sd	s8,144(sp)
ffffffffc020036e:	e566                	sd	s9,136(sp)
ffffffffc0200370:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200372:	d5bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200376:	00005517          	auipc	a0,0x5
ffffffffc020037a:	df250513          	addi	a0,a0,-526 # ffffffffc0205168 <etext+0x21e>
ffffffffc020037e:	d4fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    if (tf != NULL) {
ffffffffc0200382:	000b8563          	beqz	s7,ffffffffc020038c <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200386:	855e                	mv	a0,s7
ffffffffc0200388:	49a000ef          	jal	ra,ffffffffc0200822 <print_trapframe>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc020038c:	4501                	li	a0,0
ffffffffc020038e:	4581                	li	a1,0
ffffffffc0200390:	4601                	li	a2,0
ffffffffc0200392:	48a1                	li	a7,8
ffffffffc0200394:	00000073          	ecall
ffffffffc0200398:	00005c17          	auipc	s8,0x5
ffffffffc020039c:	e40c0c13          	addi	s8,s8,-448 # ffffffffc02051d8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003a0:	00005917          	auipc	s2,0x5
ffffffffc02003a4:	df090913          	addi	s2,s2,-528 # ffffffffc0205190 <etext+0x246>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003a8:	00005497          	auipc	s1,0x5
ffffffffc02003ac:	df048493          	addi	s1,s1,-528 # ffffffffc0205198 <etext+0x24e>
        if (argc == MAXARGS - 1) {
ffffffffc02003b0:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003b2:	00005b17          	auipc	s6,0x5
ffffffffc02003b6:	deeb0b13          	addi	s6,s6,-530 # ffffffffc02051a0 <etext+0x256>
        argv[argc ++] = buf;
ffffffffc02003ba:	00005a17          	auipc	s4,0x5
ffffffffc02003be:	d06a0a13          	addi	s4,s4,-762 # ffffffffc02050c0 <etext+0x176>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003c2:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003c4:	854a                	mv	a0,s2
ffffffffc02003c6:	d4fff0ef          	jal	ra,ffffffffc0200114 <readline>
ffffffffc02003ca:	842a                	mv	s0,a0
ffffffffc02003cc:	dd65                	beqz	a0,ffffffffc02003c4 <kmonitor+0x76>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003ce:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003d2:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003d4:	e1bd                	bnez	a1,ffffffffc020043a <kmonitor+0xec>
    if (argc == 0) {
ffffffffc02003d6:	fe0c87e3          	beqz	s9,ffffffffc02003c4 <kmonitor+0x76>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003da:	6582                	ld	a1,0(sp)
ffffffffc02003dc:	00005d17          	auipc	s10,0x5
ffffffffc02003e0:	dfcd0d13          	addi	s10,s10,-516 # ffffffffc02051d8 <commands>
        argv[argc ++] = buf;
ffffffffc02003e4:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003e6:	4401                	li	s0,0
ffffffffc02003e8:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003ea:	6da040ef          	jal	ra,ffffffffc0204ac4 <strcmp>
ffffffffc02003ee:	c919                	beqz	a0,ffffffffc0200404 <kmonitor+0xb6>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003f0:	2405                	addiw	s0,s0,1
ffffffffc02003f2:	0b540063          	beq	s0,s5,ffffffffc0200492 <kmonitor+0x144>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003f6:	000d3503          	ld	a0,0(s10)
ffffffffc02003fa:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003fc:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003fe:	6c6040ef          	jal	ra,ffffffffc0204ac4 <strcmp>
ffffffffc0200402:	f57d                	bnez	a0,ffffffffc02003f0 <kmonitor+0xa2>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200404:	00141793          	slli	a5,s0,0x1
ffffffffc0200408:	97a2                	add	a5,a5,s0
ffffffffc020040a:	078e                	slli	a5,a5,0x3
ffffffffc020040c:	97e2                	add	a5,a5,s8
ffffffffc020040e:	6b9c                	ld	a5,16(a5)
ffffffffc0200410:	865e                	mv	a2,s7
ffffffffc0200412:	002c                	addi	a1,sp,8
ffffffffc0200414:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200418:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020041a:	fa0555e3          	bgez	a0,ffffffffc02003c4 <kmonitor+0x76>
}
ffffffffc020041e:	60ee                	ld	ra,216(sp)
ffffffffc0200420:	644e                	ld	s0,208(sp)
ffffffffc0200422:	64ae                	ld	s1,200(sp)
ffffffffc0200424:	690e                	ld	s2,192(sp)
ffffffffc0200426:	79ea                	ld	s3,184(sp)
ffffffffc0200428:	7a4a                	ld	s4,176(sp)
ffffffffc020042a:	7aaa                	ld	s5,168(sp)
ffffffffc020042c:	7b0a                	ld	s6,160(sp)
ffffffffc020042e:	6bea                	ld	s7,152(sp)
ffffffffc0200430:	6c4a                	ld	s8,144(sp)
ffffffffc0200432:	6caa                	ld	s9,136(sp)
ffffffffc0200434:	6d0a                	ld	s10,128(sp)
ffffffffc0200436:	612d                	addi	sp,sp,224
ffffffffc0200438:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020043a:	8526                	mv	a0,s1
ffffffffc020043c:	6a6040ef          	jal	ra,ffffffffc0204ae2 <strchr>
ffffffffc0200440:	c901                	beqz	a0,ffffffffc0200450 <kmonitor+0x102>
ffffffffc0200442:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200446:	00040023          	sb	zero,0(s0)
ffffffffc020044a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020044c:	d5c9                	beqz	a1,ffffffffc02003d6 <kmonitor+0x88>
ffffffffc020044e:	b7f5                	j	ffffffffc020043a <kmonitor+0xec>
        if (*buf == '\0') {
ffffffffc0200450:	00044783          	lbu	a5,0(s0)
ffffffffc0200454:	d3c9                	beqz	a5,ffffffffc02003d6 <kmonitor+0x88>
        if (argc == MAXARGS - 1) {
ffffffffc0200456:	033c8963          	beq	s9,s3,ffffffffc0200488 <kmonitor+0x13a>
        argv[argc ++] = buf;
ffffffffc020045a:	003c9793          	slli	a5,s9,0x3
ffffffffc020045e:	0118                	addi	a4,sp,128
ffffffffc0200460:	97ba                	add	a5,a5,a4
ffffffffc0200462:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200466:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020046a:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020046c:	e591                	bnez	a1,ffffffffc0200478 <kmonitor+0x12a>
ffffffffc020046e:	b7b5                	j	ffffffffc02003da <kmonitor+0x8c>
ffffffffc0200470:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc0200474:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200476:	d1a5                	beqz	a1,ffffffffc02003d6 <kmonitor+0x88>
ffffffffc0200478:	8526                	mv	a0,s1
ffffffffc020047a:	668040ef          	jal	ra,ffffffffc0204ae2 <strchr>
ffffffffc020047e:	d96d                	beqz	a0,ffffffffc0200470 <kmonitor+0x122>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200480:	00044583          	lbu	a1,0(s0)
ffffffffc0200484:	d9a9                	beqz	a1,ffffffffc02003d6 <kmonitor+0x88>
ffffffffc0200486:	bf55                	j	ffffffffc020043a <kmonitor+0xec>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200488:	45c1                	li	a1,16
ffffffffc020048a:	855a                	mv	a0,s6
ffffffffc020048c:	c41ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0200490:	b7e9                	j	ffffffffc020045a <kmonitor+0x10c>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200492:	6582                	ld	a1,0(sp)
ffffffffc0200494:	00005517          	auipc	a0,0x5
ffffffffc0200498:	d2c50513          	addi	a0,a0,-724 # ffffffffc02051c0 <etext+0x276>
ffffffffc020049c:	c31ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    return 0;
ffffffffc02004a0:	b715                	j	ffffffffc02003c4 <kmonitor+0x76>

ffffffffc02004a2 <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc02004a2:	8082                	ret

ffffffffc02004a4 <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc02004a4:	00253513          	sltiu	a0,a0,2
ffffffffc02004a8:	8082                	ret

ffffffffc02004aa <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc02004aa:	03800513          	li	a0,56
ffffffffc02004ae:	8082                	ret

ffffffffc02004b0 <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004b0:	0000b797          	auipc	a5,0xb
ffffffffc02004b4:	fb078793          	addi	a5,a5,-80 # ffffffffc020b460 <ide>
    int iobase = secno * SECTSIZE;
ffffffffc02004b8:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc02004bc:	1141                	addi	sp,sp,-16
ffffffffc02004be:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004c0:	95be                	add	a1,a1,a5
ffffffffc02004c2:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc02004c6:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc02004c8:	642040ef          	jal	ra,ffffffffc0204b0a <memcpy>
    return 0;
}
ffffffffc02004cc:	60a2                	ld	ra,8(sp)
ffffffffc02004ce:	4501                	li	a0,0
ffffffffc02004d0:	0141                	addi	sp,sp,16
ffffffffc02004d2:	8082                	ret

ffffffffc02004d4 <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    int iobase = secno * SECTSIZE;
ffffffffc02004d4:	0095979b          	slliw	a5,a1,0x9
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004d8:	0000b517          	auipc	a0,0xb
ffffffffc02004dc:	f8850513          	addi	a0,a0,-120 # ffffffffc020b460 <ide>
                   size_t nsecs) {
ffffffffc02004e0:	1141                	addi	sp,sp,-16
ffffffffc02004e2:	85b2                	mv	a1,a2
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004e4:	953e                	add	a0,a0,a5
ffffffffc02004e6:	00969613          	slli	a2,a3,0x9
                   size_t nsecs) {
ffffffffc02004ea:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc02004ec:	61e040ef          	jal	ra,ffffffffc0204b0a <memcpy>
    return 0;
}
ffffffffc02004f0:	60a2                	ld	ra,8(sp)
ffffffffc02004f2:	4501                	li	a0,0
ffffffffc02004f4:	0141                	addi	sp,sp,16
ffffffffc02004f6:	8082                	ret

ffffffffc02004f8 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004f8:	67e1                	lui	a5,0x18
ffffffffc02004fa:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc02004fe:	00016717          	auipc	a4,0x16
ffffffffc0200502:	04f73523          	sd	a5,74(a4) # ffffffffc0216548 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200506:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020050a:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020050c:	953e                	add	a0,a0,a5
ffffffffc020050e:	4601                	li	a2,0
ffffffffc0200510:	4881                	li	a7,0
ffffffffc0200512:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200516:	02000793          	li	a5,32
ffffffffc020051a:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020051e:	00005517          	auipc	a0,0x5
ffffffffc0200522:	d0250513          	addi	a0,a0,-766 # ffffffffc0205220 <commands+0x48>
    ticks = 0;
ffffffffc0200526:	00016797          	auipc	a5,0x16
ffffffffc020052a:	0007bd23          	sd	zero,26(a5) # ffffffffc0216540 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020052e:	be79                	j	ffffffffc02000cc <cprintf>

ffffffffc0200530 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200530:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200534:	00016797          	auipc	a5,0x16
ffffffffc0200538:	0147b783          	ld	a5,20(a5) # ffffffffc0216548 <timebase>
ffffffffc020053c:	953e                	add	a0,a0,a5
ffffffffc020053e:	4581                	li	a1,0
ffffffffc0200540:	4601                	li	a2,0
ffffffffc0200542:	4881                	li	a7,0
ffffffffc0200544:	00000073          	ecall
ffffffffc0200548:	8082                	ret

ffffffffc020054a <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020054a:	8082                	ret

ffffffffc020054c <cons_putc>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020054c:	100027f3          	csrr	a5,sstatus
ffffffffc0200550:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200552:	0ff57513          	zext.b	a0,a0
ffffffffc0200556:	e799                	bnez	a5,ffffffffc0200564 <cons_putc+0x18>
ffffffffc0200558:	4581                	li	a1,0
ffffffffc020055a:	4601                	li	a2,0
ffffffffc020055c:	4885                	li	a7,1
ffffffffc020055e:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc0200562:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200564:	1101                	addi	sp,sp,-32
ffffffffc0200566:	ec06                	sd	ra,24(sp)
ffffffffc0200568:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020056a:	05a000ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc020056e:	6522                	ld	a0,8(sp)
ffffffffc0200570:	4581                	li	a1,0
ffffffffc0200572:	4601                	li	a2,0
ffffffffc0200574:	4885                	li	a7,1
ffffffffc0200576:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc020057a:	60e2                	ld	ra,24(sp)
ffffffffc020057c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020057e:	a081                	j	ffffffffc02005be <intr_enable>

ffffffffc0200580 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200580:	100027f3          	csrr	a5,sstatus
ffffffffc0200584:	8b89                	andi	a5,a5,2
ffffffffc0200586:	eb89                	bnez	a5,ffffffffc0200598 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200588:	4501                	li	a0,0
ffffffffc020058a:	4581                	li	a1,0
ffffffffc020058c:	4601                	li	a2,0
ffffffffc020058e:	4889                	li	a7,2
ffffffffc0200590:	00000073          	ecall
ffffffffc0200594:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200596:	8082                	ret
int cons_getc(void) {
ffffffffc0200598:	1101                	addi	sp,sp,-32
ffffffffc020059a:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc020059c:	028000ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc02005a0:	4501                	li	a0,0
ffffffffc02005a2:	4581                	li	a1,0
ffffffffc02005a4:	4601                	li	a2,0
ffffffffc02005a6:	4889                	li	a7,2
ffffffffc02005a8:	00000073          	ecall
ffffffffc02005ac:	2501                	sext.w	a0,a0
ffffffffc02005ae:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005b0:	00e000ef          	jal	ra,ffffffffc02005be <intr_enable>
}
ffffffffc02005b4:	60e2                	ld	ra,24(sp)
ffffffffc02005b6:	6522                	ld	a0,8(sp)
ffffffffc02005b8:	6105                	addi	sp,sp,32
ffffffffc02005ba:	8082                	ret

ffffffffc02005bc <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc02005bc:	8082                	ret

ffffffffc02005be <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02005be:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02005c2:	8082                	ret

ffffffffc02005c4 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02005c4:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02005c8:	8082                	ret

ffffffffc02005ca <pgfault_handler>:
    set_csr(sstatus, SSTATUS_SUM);
}

/* trap_in_kernel - test if trap happened in kernel */
bool trap_in_kernel(struct trapframe *tf) {
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02005ca:	10053783          	ld	a5,256(a0)
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr,
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int pgfault_handler(struct trapframe *tf) {
ffffffffc02005ce:	1141                	addi	sp,sp,-16
ffffffffc02005d0:	e022                	sd	s0,0(sp)
ffffffffc02005d2:	e406                	sd	ra,8(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02005d4:	1007f793          	andi	a5,a5,256
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc02005d8:	11053583          	ld	a1,272(a0)
static int pgfault_handler(struct trapframe *tf) {
ffffffffc02005dc:	842a                	mv	s0,a0
    cprintf("page falut at 0x%08x: %c/%c\n", tf->badvaddr,
ffffffffc02005de:	05500613          	li	a2,85
ffffffffc02005e2:	c399                	beqz	a5,ffffffffc02005e8 <pgfault_handler+0x1e>
ffffffffc02005e4:	04b00613          	li	a2,75
ffffffffc02005e8:	11843703          	ld	a4,280(s0)
ffffffffc02005ec:	47bd                	li	a5,15
ffffffffc02005ee:	05700693          	li	a3,87
ffffffffc02005f2:	00f70463          	beq	a4,a5,ffffffffc02005fa <pgfault_handler+0x30>
ffffffffc02005f6:	05200693          	li	a3,82
ffffffffc02005fa:	00005517          	auipc	a0,0x5
ffffffffc02005fe:	c4650513          	addi	a0,a0,-954 # ffffffffc0205240 <commands+0x68>
ffffffffc0200602:	acbff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    extern struct mm_struct *check_mm_struct;
    print_pgfault(tf);
    if (check_mm_struct != NULL) {
ffffffffc0200606:	00016517          	auipc	a0,0x16
ffffffffc020060a:	f4a53503          	ld	a0,-182(a0) # ffffffffc0216550 <check_mm_struct>
ffffffffc020060e:	c911                	beqz	a0,ffffffffc0200622 <pgfault_handler+0x58>
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc0200610:	11043603          	ld	a2,272(s0)
ffffffffc0200614:	11842583          	lw	a1,280(s0)
    }
    panic("unhandled page fault.\n");
}
ffffffffc0200618:	6402                	ld	s0,0(sp)
ffffffffc020061a:	60a2                	ld	ra,8(sp)
ffffffffc020061c:	0141                	addi	sp,sp,16
        return do_pgfault(check_mm_struct, tf->cause, tf->badvaddr);
ffffffffc020061e:	5010006f          	j	ffffffffc020131e <do_pgfault>
    panic("unhandled page fault.\n");
ffffffffc0200622:	00005617          	auipc	a2,0x5
ffffffffc0200626:	c3e60613          	addi	a2,a2,-962 # ffffffffc0205260 <commands+0x88>
ffffffffc020062a:	06200593          	li	a1,98
ffffffffc020062e:	00005517          	auipc	a0,0x5
ffffffffc0200632:	c4a50513          	addi	a0,a0,-950 # ffffffffc0205278 <commands+0xa0>
ffffffffc0200636:	b93ff0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc020063a <idt_init>:
    write_csr(sscratch, 0);
ffffffffc020063a:	14005073          	csrwi	sscratch,0
    write_csr(stvec, &__alltraps);
ffffffffc020063e:	00000797          	auipc	a5,0x0
ffffffffc0200642:	47a78793          	addi	a5,a5,1146 # ffffffffc0200ab8 <__alltraps>
ffffffffc0200646:	10579073          	csrw	stvec,a5
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020064a:	000407b7          	lui	a5,0x40
ffffffffc020064e:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200652:	8082                	ret

ffffffffc0200654 <print_regs>:
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200654:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200656:	1141                	addi	sp,sp,-16
ffffffffc0200658:	e022                	sd	s0,0(sp)
ffffffffc020065a:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020065c:	00005517          	auipc	a0,0x5
ffffffffc0200660:	c3450513          	addi	a0,a0,-972 # ffffffffc0205290 <commands+0xb8>
void print_regs(struct pushregs *gpr) {
ffffffffc0200664:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200666:	a67ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020066a:	640c                	ld	a1,8(s0)
ffffffffc020066c:	00005517          	auipc	a0,0x5
ffffffffc0200670:	c3c50513          	addi	a0,a0,-964 # ffffffffc02052a8 <commands+0xd0>
ffffffffc0200674:	a59ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200678:	680c                	ld	a1,16(s0)
ffffffffc020067a:	00005517          	auipc	a0,0x5
ffffffffc020067e:	c4650513          	addi	a0,a0,-954 # ffffffffc02052c0 <commands+0xe8>
ffffffffc0200682:	a4bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200686:	6c0c                	ld	a1,24(s0)
ffffffffc0200688:	00005517          	auipc	a0,0x5
ffffffffc020068c:	c5050513          	addi	a0,a0,-944 # ffffffffc02052d8 <commands+0x100>
ffffffffc0200690:	a3dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200694:	700c                	ld	a1,32(s0)
ffffffffc0200696:	00005517          	auipc	a0,0x5
ffffffffc020069a:	c5a50513          	addi	a0,a0,-934 # ffffffffc02052f0 <commands+0x118>
ffffffffc020069e:	a2fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02006a2:	740c                	ld	a1,40(s0)
ffffffffc02006a4:	00005517          	auipc	a0,0x5
ffffffffc02006a8:	c6450513          	addi	a0,a0,-924 # ffffffffc0205308 <commands+0x130>
ffffffffc02006ac:	a21ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02006b0:	780c                	ld	a1,48(s0)
ffffffffc02006b2:	00005517          	auipc	a0,0x5
ffffffffc02006b6:	c6e50513          	addi	a0,a0,-914 # ffffffffc0205320 <commands+0x148>
ffffffffc02006ba:	a13ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006be:	7c0c                	ld	a1,56(s0)
ffffffffc02006c0:	00005517          	auipc	a0,0x5
ffffffffc02006c4:	c7850513          	addi	a0,a0,-904 # ffffffffc0205338 <commands+0x160>
ffffffffc02006c8:	a05ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006cc:	602c                	ld	a1,64(s0)
ffffffffc02006ce:	00005517          	auipc	a0,0x5
ffffffffc02006d2:	c8250513          	addi	a0,a0,-894 # ffffffffc0205350 <commands+0x178>
ffffffffc02006d6:	9f7ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02006da:	642c                	ld	a1,72(s0)
ffffffffc02006dc:	00005517          	auipc	a0,0x5
ffffffffc02006e0:	c8c50513          	addi	a0,a0,-884 # ffffffffc0205368 <commands+0x190>
ffffffffc02006e4:	9e9ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02006e8:	682c                	ld	a1,80(s0)
ffffffffc02006ea:	00005517          	auipc	a0,0x5
ffffffffc02006ee:	c9650513          	addi	a0,a0,-874 # ffffffffc0205380 <commands+0x1a8>
ffffffffc02006f2:	9dbff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02006f6:	6c2c                	ld	a1,88(s0)
ffffffffc02006f8:	00005517          	auipc	a0,0x5
ffffffffc02006fc:	ca050513          	addi	a0,a0,-864 # ffffffffc0205398 <commands+0x1c0>
ffffffffc0200700:	9cdff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200704:	702c                	ld	a1,96(s0)
ffffffffc0200706:	00005517          	auipc	a0,0x5
ffffffffc020070a:	caa50513          	addi	a0,a0,-854 # ffffffffc02053b0 <commands+0x1d8>
ffffffffc020070e:	9bfff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200712:	742c                	ld	a1,104(s0)
ffffffffc0200714:	00005517          	auipc	a0,0x5
ffffffffc0200718:	cb450513          	addi	a0,a0,-844 # ffffffffc02053c8 <commands+0x1f0>
ffffffffc020071c:	9b1ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200720:	782c                	ld	a1,112(s0)
ffffffffc0200722:	00005517          	auipc	a0,0x5
ffffffffc0200726:	cbe50513          	addi	a0,a0,-834 # ffffffffc02053e0 <commands+0x208>
ffffffffc020072a:	9a3ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc020072e:	7c2c                	ld	a1,120(s0)
ffffffffc0200730:	00005517          	auipc	a0,0x5
ffffffffc0200734:	cc850513          	addi	a0,a0,-824 # ffffffffc02053f8 <commands+0x220>
ffffffffc0200738:	995ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc020073c:	604c                	ld	a1,128(s0)
ffffffffc020073e:	00005517          	auipc	a0,0x5
ffffffffc0200742:	cd250513          	addi	a0,a0,-814 # ffffffffc0205410 <commands+0x238>
ffffffffc0200746:	987ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020074a:	644c                	ld	a1,136(s0)
ffffffffc020074c:	00005517          	auipc	a0,0x5
ffffffffc0200750:	cdc50513          	addi	a0,a0,-804 # ffffffffc0205428 <commands+0x250>
ffffffffc0200754:	979ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200758:	684c                	ld	a1,144(s0)
ffffffffc020075a:	00005517          	auipc	a0,0x5
ffffffffc020075e:	ce650513          	addi	a0,a0,-794 # ffffffffc0205440 <commands+0x268>
ffffffffc0200762:	96bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200766:	6c4c                	ld	a1,152(s0)
ffffffffc0200768:	00005517          	auipc	a0,0x5
ffffffffc020076c:	cf050513          	addi	a0,a0,-784 # ffffffffc0205458 <commands+0x280>
ffffffffc0200770:	95dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200774:	704c                	ld	a1,160(s0)
ffffffffc0200776:	00005517          	auipc	a0,0x5
ffffffffc020077a:	cfa50513          	addi	a0,a0,-774 # ffffffffc0205470 <commands+0x298>
ffffffffc020077e:	94fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200782:	744c                	ld	a1,168(s0)
ffffffffc0200784:	00005517          	auipc	a0,0x5
ffffffffc0200788:	d0450513          	addi	a0,a0,-764 # ffffffffc0205488 <commands+0x2b0>
ffffffffc020078c:	941ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200790:	784c                	ld	a1,176(s0)
ffffffffc0200792:	00005517          	auipc	a0,0x5
ffffffffc0200796:	d0e50513          	addi	a0,a0,-754 # ffffffffc02054a0 <commands+0x2c8>
ffffffffc020079a:	933ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc020079e:	7c4c                	ld	a1,184(s0)
ffffffffc02007a0:	00005517          	auipc	a0,0x5
ffffffffc02007a4:	d1850513          	addi	a0,a0,-744 # ffffffffc02054b8 <commands+0x2e0>
ffffffffc02007a8:	925ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02007ac:	606c                	ld	a1,192(s0)
ffffffffc02007ae:	00005517          	auipc	a0,0x5
ffffffffc02007b2:	d2250513          	addi	a0,a0,-734 # ffffffffc02054d0 <commands+0x2f8>
ffffffffc02007b6:	917ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007ba:	646c                	ld	a1,200(s0)
ffffffffc02007bc:	00005517          	auipc	a0,0x5
ffffffffc02007c0:	d2c50513          	addi	a0,a0,-724 # ffffffffc02054e8 <commands+0x310>
ffffffffc02007c4:	909ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007c8:	686c                	ld	a1,208(s0)
ffffffffc02007ca:	00005517          	auipc	a0,0x5
ffffffffc02007ce:	d3650513          	addi	a0,a0,-714 # ffffffffc0205500 <commands+0x328>
ffffffffc02007d2:	8fbff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007d6:	6c6c                	ld	a1,216(s0)
ffffffffc02007d8:	00005517          	auipc	a0,0x5
ffffffffc02007dc:	d4050513          	addi	a0,a0,-704 # ffffffffc0205518 <commands+0x340>
ffffffffc02007e0:	8edff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02007e4:	706c                	ld	a1,224(s0)
ffffffffc02007e6:	00005517          	auipc	a0,0x5
ffffffffc02007ea:	d4a50513          	addi	a0,a0,-694 # ffffffffc0205530 <commands+0x358>
ffffffffc02007ee:	8dfff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc02007f2:	746c                	ld	a1,232(s0)
ffffffffc02007f4:	00005517          	auipc	a0,0x5
ffffffffc02007f8:	d5450513          	addi	a0,a0,-684 # ffffffffc0205548 <commands+0x370>
ffffffffc02007fc:	8d1ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200800:	786c                	ld	a1,240(s0)
ffffffffc0200802:	00005517          	auipc	a0,0x5
ffffffffc0200806:	d5e50513          	addi	a0,a0,-674 # ffffffffc0205560 <commands+0x388>
ffffffffc020080a:	8c3ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020080e:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200810:	6402                	ld	s0,0(sp)
ffffffffc0200812:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200814:	00005517          	auipc	a0,0x5
ffffffffc0200818:	d6450513          	addi	a0,a0,-668 # ffffffffc0205578 <commands+0x3a0>
}
ffffffffc020081c:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020081e:	8afff06f          	j	ffffffffc02000cc <cprintf>

ffffffffc0200822 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200822:	1141                	addi	sp,sp,-16
ffffffffc0200824:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200826:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200828:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc020082a:	00005517          	auipc	a0,0x5
ffffffffc020082e:	d6650513          	addi	a0,a0,-666 # ffffffffc0205590 <commands+0x3b8>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200832:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200834:	899ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200838:	8522                	mv	a0,s0
ffffffffc020083a:	e1bff0ef          	jal	ra,ffffffffc0200654 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc020083e:	10043583          	ld	a1,256(s0)
ffffffffc0200842:	00005517          	auipc	a0,0x5
ffffffffc0200846:	d6650513          	addi	a0,a0,-666 # ffffffffc02055a8 <commands+0x3d0>
ffffffffc020084a:	883ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc020084e:	10843583          	ld	a1,264(s0)
ffffffffc0200852:	00005517          	auipc	a0,0x5
ffffffffc0200856:	d6e50513          	addi	a0,a0,-658 # ffffffffc02055c0 <commands+0x3e8>
ffffffffc020085a:	873ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc020085e:	11043583          	ld	a1,272(s0)
ffffffffc0200862:	00005517          	auipc	a0,0x5
ffffffffc0200866:	d7650513          	addi	a0,a0,-650 # ffffffffc02055d8 <commands+0x400>
ffffffffc020086a:	863ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020086e:	11843583          	ld	a1,280(s0)
}
ffffffffc0200872:	6402                	ld	s0,0(sp)
ffffffffc0200874:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200876:	00005517          	auipc	a0,0x5
ffffffffc020087a:	d7a50513          	addi	a0,a0,-646 # ffffffffc02055f0 <commands+0x418>
}
ffffffffc020087e:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200880:	84dff06f          	j	ffffffffc02000cc <cprintf>

ffffffffc0200884 <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200884:	11853783          	ld	a5,280(a0)
ffffffffc0200888:	472d                	li	a4,11
ffffffffc020088a:	0786                	slli	a5,a5,0x1
ffffffffc020088c:	8385                	srli	a5,a5,0x1
ffffffffc020088e:	06f76c63          	bltu	a4,a5,ffffffffc0200906 <interrupt_handler+0x82>
ffffffffc0200892:	00005717          	auipc	a4,0x5
ffffffffc0200896:	e2670713          	addi	a4,a4,-474 # ffffffffc02056b8 <commands+0x4e0>
ffffffffc020089a:	078a                	slli	a5,a5,0x2
ffffffffc020089c:	97ba                	add	a5,a5,a4
ffffffffc020089e:	439c                	lw	a5,0(a5)
ffffffffc02008a0:	97ba                	add	a5,a5,a4
ffffffffc02008a2:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02008a4:	00005517          	auipc	a0,0x5
ffffffffc02008a8:	dc450513          	addi	a0,a0,-572 # ffffffffc0205668 <commands+0x490>
ffffffffc02008ac:	821ff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02008b0:	00005517          	auipc	a0,0x5
ffffffffc02008b4:	d9850513          	addi	a0,a0,-616 # ffffffffc0205648 <commands+0x470>
ffffffffc02008b8:	815ff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02008bc:	00005517          	auipc	a0,0x5
ffffffffc02008c0:	d4c50513          	addi	a0,a0,-692 # ffffffffc0205608 <commands+0x430>
ffffffffc02008c4:	809ff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02008c8:	00005517          	auipc	a0,0x5
ffffffffc02008cc:	d6050513          	addi	a0,a0,-672 # ffffffffc0205628 <commands+0x450>
ffffffffc02008d0:	ffcff06f          	j	ffffffffc02000cc <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc02008d4:	1141                	addi	sp,sp,-16
ffffffffc02008d6:	e406                	sd	ra,8(sp)
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc02008d8:	c59ff0ef          	jal	ra,ffffffffc0200530 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc02008dc:	00016697          	auipc	a3,0x16
ffffffffc02008e0:	c6468693          	addi	a3,a3,-924 # ffffffffc0216540 <ticks>
ffffffffc02008e4:	629c                	ld	a5,0(a3)
ffffffffc02008e6:	06400713          	li	a4,100
ffffffffc02008ea:	0785                	addi	a5,a5,1
ffffffffc02008ec:	02e7f733          	remu	a4,a5,a4
ffffffffc02008f0:	e29c                	sd	a5,0(a3)
ffffffffc02008f2:	cb19                	beqz	a4,ffffffffc0200908 <interrupt_handler+0x84>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc02008f4:	60a2                	ld	ra,8(sp)
ffffffffc02008f6:	0141                	addi	sp,sp,16
ffffffffc02008f8:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc02008fa:	00005517          	auipc	a0,0x5
ffffffffc02008fe:	d9e50513          	addi	a0,a0,-610 # ffffffffc0205698 <commands+0x4c0>
ffffffffc0200902:	fcaff06f          	j	ffffffffc02000cc <cprintf>
            print_trapframe(tf);
ffffffffc0200906:	bf31                	j	ffffffffc0200822 <print_trapframe>
}
ffffffffc0200908:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020090a:	06400593          	li	a1,100
ffffffffc020090e:	00005517          	auipc	a0,0x5
ffffffffc0200912:	d7a50513          	addi	a0,a0,-646 # ffffffffc0205688 <commands+0x4b0>
}
ffffffffc0200916:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200918:	fb4ff06f          	j	ffffffffc02000cc <cprintf>

ffffffffc020091c <exception_handler>:

void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc020091c:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200920:	1101                	addi	sp,sp,-32
ffffffffc0200922:	e822                	sd	s0,16(sp)
ffffffffc0200924:	ec06                	sd	ra,24(sp)
ffffffffc0200926:	e426                	sd	s1,8(sp)
ffffffffc0200928:	473d                	li	a4,15
ffffffffc020092a:	842a                	mv	s0,a0
ffffffffc020092c:	14f76a63          	bltu	a4,a5,ffffffffc0200a80 <exception_handler+0x164>
ffffffffc0200930:	00005717          	auipc	a4,0x5
ffffffffc0200934:	f7070713          	addi	a4,a4,-144 # ffffffffc02058a0 <commands+0x6c8>
ffffffffc0200938:	078a                	slli	a5,a5,0x2
ffffffffc020093a:	97ba                	add	a5,a5,a4
ffffffffc020093c:	439c                	lw	a5,0(a5)
ffffffffc020093e:	97ba                	add	a5,a5,a4
ffffffffc0200940:	8782                	jr	a5
                print_trapframe(tf);
                panic("handle pgfault failed. %e\n", ret);
            }
            break;
        case CAUSE_STORE_PAGE_FAULT:
            cprintf("Store/AMO page fault\n");
ffffffffc0200942:	00005517          	auipc	a0,0x5
ffffffffc0200946:	f4650513          	addi	a0,a0,-186 # ffffffffc0205888 <commands+0x6b0>
ffffffffc020094a:	f82ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc020094e:	8522                	mv	a0,s0
ffffffffc0200950:	c7bff0ef          	jal	ra,ffffffffc02005ca <pgfault_handler>
ffffffffc0200954:	84aa                	mv	s1,a0
ffffffffc0200956:	12051b63          	bnez	a0,ffffffffc0200a8c <exception_handler+0x170>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc020095a:	60e2                	ld	ra,24(sp)
ffffffffc020095c:	6442                	ld	s0,16(sp)
ffffffffc020095e:	64a2                	ld	s1,8(sp)
ffffffffc0200960:	6105                	addi	sp,sp,32
ffffffffc0200962:	8082                	ret
            cprintf("Instruction address misaligned\n");
ffffffffc0200964:	00005517          	auipc	a0,0x5
ffffffffc0200968:	d8450513          	addi	a0,a0,-636 # ffffffffc02056e8 <commands+0x510>
}
ffffffffc020096c:	6442                	ld	s0,16(sp)
ffffffffc020096e:	60e2                	ld	ra,24(sp)
ffffffffc0200970:	64a2                	ld	s1,8(sp)
ffffffffc0200972:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc0200974:	f58ff06f          	j	ffffffffc02000cc <cprintf>
ffffffffc0200978:	00005517          	auipc	a0,0x5
ffffffffc020097c:	d9050513          	addi	a0,a0,-624 # ffffffffc0205708 <commands+0x530>
ffffffffc0200980:	b7f5                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc0200982:	00005517          	auipc	a0,0x5
ffffffffc0200986:	da650513          	addi	a0,a0,-602 # ffffffffc0205728 <commands+0x550>
ffffffffc020098a:	b7cd                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc020098c:	00005517          	auipc	a0,0x5
ffffffffc0200990:	db450513          	addi	a0,a0,-588 # ffffffffc0205740 <commands+0x568>
ffffffffc0200994:	bfe1                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Load address misaligned\n");
ffffffffc0200996:	00005517          	auipc	a0,0x5
ffffffffc020099a:	dba50513          	addi	a0,a0,-582 # ffffffffc0205750 <commands+0x578>
ffffffffc020099e:	b7f9                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc02009a0:	00005517          	auipc	a0,0x5
ffffffffc02009a4:	dd050513          	addi	a0,a0,-560 # ffffffffc0205770 <commands+0x598>
ffffffffc02009a8:	f24ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02009ac:	8522                	mv	a0,s0
ffffffffc02009ae:	c1dff0ef          	jal	ra,ffffffffc02005ca <pgfault_handler>
ffffffffc02009b2:	84aa                	mv	s1,a0
ffffffffc02009b4:	d15d                	beqz	a0,ffffffffc020095a <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02009b6:	8522                	mv	a0,s0
ffffffffc02009b8:	e6bff0ef          	jal	ra,ffffffffc0200822 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009bc:	86a6                	mv	a3,s1
ffffffffc02009be:	00005617          	auipc	a2,0x5
ffffffffc02009c2:	dca60613          	addi	a2,a2,-566 # ffffffffc0205788 <commands+0x5b0>
ffffffffc02009c6:	0b300593          	li	a1,179
ffffffffc02009ca:	00005517          	auipc	a0,0x5
ffffffffc02009ce:	8ae50513          	addi	a0,a0,-1874 # ffffffffc0205278 <commands+0xa0>
ffffffffc02009d2:	ff6ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
            cprintf("AMO address misaligned\n");
ffffffffc02009d6:	00005517          	auipc	a0,0x5
ffffffffc02009da:	dd250513          	addi	a0,a0,-558 # ffffffffc02057a8 <commands+0x5d0>
ffffffffc02009de:	b779                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Store/AMO access fault\n");
ffffffffc02009e0:	00005517          	auipc	a0,0x5
ffffffffc02009e4:	de050513          	addi	a0,a0,-544 # ffffffffc02057c0 <commands+0x5e8>
ffffffffc02009e8:	ee4ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc02009ec:	8522                	mv	a0,s0
ffffffffc02009ee:	bddff0ef          	jal	ra,ffffffffc02005ca <pgfault_handler>
ffffffffc02009f2:	84aa                	mv	s1,a0
ffffffffc02009f4:	d13d                	beqz	a0,ffffffffc020095a <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc02009f6:	8522                	mv	a0,s0
ffffffffc02009f8:	e2bff0ef          	jal	ra,ffffffffc0200822 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc02009fc:	86a6                	mv	a3,s1
ffffffffc02009fe:	00005617          	auipc	a2,0x5
ffffffffc0200a02:	d8a60613          	addi	a2,a2,-630 # ffffffffc0205788 <commands+0x5b0>
ffffffffc0200a06:	0bd00593          	li	a1,189
ffffffffc0200a0a:	00005517          	auipc	a0,0x5
ffffffffc0200a0e:	86e50513          	addi	a0,a0,-1938 # ffffffffc0205278 <commands+0xa0>
ffffffffc0200a12:	fb6ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
            cprintf("Environment call from U-mode\n");
ffffffffc0200a16:	00005517          	auipc	a0,0x5
ffffffffc0200a1a:	dc250513          	addi	a0,a0,-574 # ffffffffc02057d8 <commands+0x600>
ffffffffc0200a1e:	b7b9                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Environment call from S-mode\n");
ffffffffc0200a20:	00005517          	auipc	a0,0x5
ffffffffc0200a24:	dd850513          	addi	a0,a0,-552 # ffffffffc02057f8 <commands+0x620>
ffffffffc0200a28:	b791                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Environment call from H-mode\n");
ffffffffc0200a2a:	00005517          	auipc	a0,0x5
ffffffffc0200a2e:	dee50513          	addi	a0,a0,-530 # ffffffffc0205818 <commands+0x640>
ffffffffc0200a32:	bf2d                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Environment call from M-mode\n");
ffffffffc0200a34:	00005517          	auipc	a0,0x5
ffffffffc0200a38:	e0450513          	addi	a0,a0,-508 # ffffffffc0205838 <commands+0x660>
ffffffffc0200a3c:	bf05                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200a3e:	00005517          	auipc	a0,0x5
ffffffffc0200a42:	e1a50513          	addi	a0,a0,-486 # ffffffffc0205858 <commands+0x680>
ffffffffc0200a46:	b71d                	j	ffffffffc020096c <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200a48:	00005517          	auipc	a0,0x5
ffffffffc0200a4c:	e2850513          	addi	a0,a0,-472 # ffffffffc0205870 <commands+0x698>
ffffffffc0200a50:	e7cff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200a54:	8522                	mv	a0,s0
ffffffffc0200a56:	b75ff0ef          	jal	ra,ffffffffc02005ca <pgfault_handler>
ffffffffc0200a5a:	84aa                	mv	s1,a0
ffffffffc0200a5c:	ee050fe3          	beqz	a0,ffffffffc020095a <exception_handler+0x3e>
                print_trapframe(tf);
ffffffffc0200a60:	8522                	mv	a0,s0
ffffffffc0200a62:	dc1ff0ef          	jal	ra,ffffffffc0200822 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200a66:	86a6                	mv	a3,s1
ffffffffc0200a68:	00005617          	auipc	a2,0x5
ffffffffc0200a6c:	d2060613          	addi	a2,a2,-736 # ffffffffc0205788 <commands+0x5b0>
ffffffffc0200a70:	0d300593          	li	a1,211
ffffffffc0200a74:	00005517          	auipc	a0,0x5
ffffffffc0200a78:	80450513          	addi	a0,a0,-2044 # ffffffffc0205278 <commands+0xa0>
ffffffffc0200a7c:	f4cff0ef          	jal	ra,ffffffffc02001c8 <__panic>
            print_trapframe(tf);
ffffffffc0200a80:	8522                	mv	a0,s0
}
ffffffffc0200a82:	6442                	ld	s0,16(sp)
ffffffffc0200a84:	60e2                	ld	ra,24(sp)
ffffffffc0200a86:	64a2                	ld	s1,8(sp)
ffffffffc0200a88:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200a8a:	bb61                	j	ffffffffc0200822 <print_trapframe>
                print_trapframe(tf);
ffffffffc0200a8c:	8522                	mv	a0,s0
ffffffffc0200a8e:	d95ff0ef          	jal	ra,ffffffffc0200822 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200a92:	86a6                	mv	a3,s1
ffffffffc0200a94:	00005617          	auipc	a2,0x5
ffffffffc0200a98:	cf460613          	addi	a2,a2,-780 # ffffffffc0205788 <commands+0x5b0>
ffffffffc0200a9c:	0da00593          	li	a1,218
ffffffffc0200aa0:	00004517          	auipc	a0,0x4
ffffffffc0200aa4:	7d850513          	addi	a0,a0,2008 # ffffffffc0205278 <commands+0xa0>
ffffffffc0200aa8:	f20ff0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0200aac <trap>:
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200aac:	11853783          	ld	a5,280(a0)
ffffffffc0200ab0:	0007c363          	bltz	a5,ffffffffc0200ab6 <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200ab4:	b5a5                	j	ffffffffc020091c <exception_handler>
        interrupt_handler(tf);
ffffffffc0200ab6:	b3f9                	j	ffffffffc0200884 <interrupt_handler>

ffffffffc0200ab8 <__alltraps>:
    LOAD  x2,2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200ab8:	14011073          	csrw	sscratch,sp
ffffffffc0200abc:	712d                	addi	sp,sp,-288
ffffffffc0200abe:	e406                	sd	ra,8(sp)
ffffffffc0200ac0:	ec0e                	sd	gp,24(sp)
ffffffffc0200ac2:	f012                	sd	tp,32(sp)
ffffffffc0200ac4:	f416                	sd	t0,40(sp)
ffffffffc0200ac6:	f81a                	sd	t1,48(sp)
ffffffffc0200ac8:	fc1e                	sd	t2,56(sp)
ffffffffc0200aca:	e0a2                	sd	s0,64(sp)
ffffffffc0200acc:	e4a6                	sd	s1,72(sp)
ffffffffc0200ace:	e8aa                	sd	a0,80(sp)
ffffffffc0200ad0:	ecae                	sd	a1,88(sp)
ffffffffc0200ad2:	f0b2                	sd	a2,96(sp)
ffffffffc0200ad4:	f4b6                	sd	a3,104(sp)
ffffffffc0200ad6:	f8ba                	sd	a4,112(sp)
ffffffffc0200ad8:	fcbe                	sd	a5,120(sp)
ffffffffc0200ada:	e142                	sd	a6,128(sp)
ffffffffc0200adc:	e546                	sd	a7,136(sp)
ffffffffc0200ade:	e94a                	sd	s2,144(sp)
ffffffffc0200ae0:	ed4e                	sd	s3,152(sp)
ffffffffc0200ae2:	f152                	sd	s4,160(sp)
ffffffffc0200ae4:	f556                	sd	s5,168(sp)
ffffffffc0200ae6:	f95a                	sd	s6,176(sp)
ffffffffc0200ae8:	fd5e                	sd	s7,184(sp)
ffffffffc0200aea:	e1e2                	sd	s8,192(sp)
ffffffffc0200aec:	e5e6                	sd	s9,200(sp)
ffffffffc0200aee:	e9ea                	sd	s10,208(sp)
ffffffffc0200af0:	edee                	sd	s11,216(sp)
ffffffffc0200af2:	f1f2                	sd	t3,224(sp)
ffffffffc0200af4:	f5f6                	sd	t4,232(sp)
ffffffffc0200af6:	f9fa                	sd	t5,240(sp)
ffffffffc0200af8:	fdfe                	sd	t6,248(sp)
ffffffffc0200afa:	14002473          	csrr	s0,sscratch
ffffffffc0200afe:	100024f3          	csrr	s1,sstatus
ffffffffc0200b02:	14102973          	csrr	s2,sepc
ffffffffc0200b06:	143029f3          	csrr	s3,stval
ffffffffc0200b0a:	14202a73          	csrr	s4,scause
ffffffffc0200b0e:	e822                	sd	s0,16(sp)
ffffffffc0200b10:	e226                	sd	s1,256(sp)
ffffffffc0200b12:	e64a                	sd	s2,264(sp)
ffffffffc0200b14:	ea4e                	sd	s3,272(sp)
ffffffffc0200b16:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200b18:	850a                	mv	a0,sp
    jal trap
ffffffffc0200b1a:	f93ff0ef          	jal	ra,ffffffffc0200aac <trap>

ffffffffc0200b1e <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200b1e:	6492                	ld	s1,256(sp)
ffffffffc0200b20:	6932                	ld	s2,264(sp)
ffffffffc0200b22:	10049073          	csrw	sstatus,s1
ffffffffc0200b26:	14191073          	csrw	sepc,s2
ffffffffc0200b2a:	60a2                	ld	ra,8(sp)
ffffffffc0200b2c:	61e2                	ld	gp,24(sp)
ffffffffc0200b2e:	7202                	ld	tp,32(sp)
ffffffffc0200b30:	72a2                	ld	t0,40(sp)
ffffffffc0200b32:	7342                	ld	t1,48(sp)
ffffffffc0200b34:	73e2                	ld	t2,56(sp)
ffffffffc0200b36:	6406                	ld	s0,64(sp)
ffffffffc0200b38:	64a6                	ld	s1,72(sp)
ffffffffc0200b3a:	6546                	ld	a0,80(sp)
ffffffffc0200b3c:	65e6                	ld	a1,88(sp)
ffffffffc0200b3e:	7606                	ld	a2,96(sp)
ffffffffc0200b40:	76a6                	ld	a3,104(sp)
ffffffffc0200b42:	7746                	ld	a4,112(sp)
ffffffffc0200b44:	77e6                	ld	a5,120(sp)
ffffffffc0200b46:	680a                	ld	a6,128(sp)
ffffffffc0200b48:	68aa                	ld	a7,136(sp)
ffffffffc0200b4a:	694a                	ld	s2,144(sp)
ffffffffc0200b4c:	69ea                	ld	s3,152(sp)
ffffffffc0200b4e:	7a0a                	ld	s4,160(sp)
ffffffffc0200b50:	7aaa                	ld	s5,168(sp)
ffffffffc0200b52:	7b4a                	ld	s6,176(sp)
ffffffffc0200b54:	7bea                	ld	s7,184(sp)
ffffffffc0200b56:	6c0e                	ld	s8,192(sp)
ffffffffc0200b58:	6cae                	ld	s9,200(sp)
ffffffffc0200b5a:	6d4e                	ld	s10,208(sp)
ffffffffc0200b5c:	6dee                	ld	s11,216(sp)
ffffffffc0200b5e:	7e0e                	ld	t3,224(sp)
ffffffffc0200b60:	7eae                	ld	t4,232(sp)
ffffffffc0200b62:	7f4e                	ld	t5,240(sp)
ffffffffc0200b64:	7fee                	ld	t6,248(sp)
ffffffffc0200b66:	6142                	ld	sp,16(sp)
    # go back from supervisor call
    sret
ffffffffc0200b68:	10200073          	sret

ffffffffc0200b6c <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200b6c:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200b6e:	bf45                	j	ffffffffc0200b1e <__trapret>
	...

ffffffffc0200b72 <check_vma_overlap.part.0>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0200b72:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0200b74:	00005697          	auipc	a3,0x5
ffffffffc0200b78:	d6c68693          	addi	a3,a3,-660 # ffffffffc02058e0 <commands+0x708>
ffffffffc0200b7c:	00005617          	auipc	a2,0x5
ffffffffc0200b80:	d8460613          	addi	a2,a2,-636 # ffffffffc0205900 <commands+0x728>
ffffffffc0200b84:	07e00593          	li	a1,126
ffffffffc0200b88:	00005517          	auipc	a0,0x5
ffffffffc0200b8c:	d9050513          	addi	a0,a0,-624 # ffffffffc0205918 <commands+0x740>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0200b90:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0200b92:	e36ff0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0200b96 <mm_create>:
mm_create(void) {
ffffffffc0200b96:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0200b98:	03000513          	li	a0,48
mm_create(void) {
ffffffffc0200b9c:	e022                	sd	s0,0(sp)
ffffffffc0200b9e:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0200ba0:	69d000ef          	jal	ra,ffffffffc0201a3c <kmalloc>
ffffffffc0200ba4:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0200ba6:	c105                	beqz	a0,ffffffffc0200bc6 <mm_create+0x30>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200ba8:	e408                	sd	a0,8(s0)
ffffffffc0200baa:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc0200bac:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0200bb0:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0200bb4:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0200bb8:	00016797          	auipc	a5,0x16
ffffffffc0200bbc:	9c07a783          	lw	a5,-1600(a5) # ffffffffc0216578 <swap_init_ok>
ffffffffc0200bc0:	eb81                	bnez	a5,ffffffffc0200bd0 <mm_create+0x3a>
        else mm->sm_priv = NULL;
ffffffffc0200bc2:	02053423          	sd	zero,40(a0)
}
ffffffffc0200bc6:	60a2                	ld	ra,8(sp)
ffffffffc0200bc8:	8522                	mv	a0,s0
ffffffffc0200bca:	6402                	ld	s0,0(sp)
ffffffffc0200bcc:	0141                	addi	sp,sp,16
ffffffffc0200bce:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0200bd0:	768010ef          	jal	ra,ffffffffc0202338 <swap_init_mm>
}
ffffffffc0200bd4:	60a2                	ld	ra,8(sp)
ffffffffc0200bd6:	8522                	mv	a0,s0
ffffffffc0200bd8:	6402                	ld	s0,0(sp)
ffffffffc0200bda:	0141                	addi	sp,sp,16
ffffffffc0200bdc:	8082                	ret

ffffffffc0200bde <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0200bde:	1101                	addi	sp,sp,-32
ffffffffc0200be0:	e04a                	sd	s2,0(sp)
ffffffffc0200be2:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200be4:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0200be8:	e822                	sd	s0,16(sp)
ffffffffc0200bea:	e426                	sd	s1,8(sp)
ffffffffc0200bec:	ec06                	sd	ra,24(sp)
ffffffffc0200bee:	84ae                	mv	s1,a1
ffffffffc0200bf0:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200bf2:	64b000ef          	jal	ra,ffffffffc0201a3c <kmalloc>
    if (vma != NULL) {
ffffffffc0200bf6:	c509                	beqz	a0,ffffffffc0200c00 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc0200bf8:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc0200bfc:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0200bfe:	cd00                	sw	s0,24(a0)
}
ffffffffc0200c00:	60e2                	ld	ra,24(sp)
ffffffffc0200c02:	6442                	ld	s0,16(sp)
ffffffffc0200c04:	64a2                	ld	s1,8(sp)
ffffffffc0200c06:	6902                	ld	s2,0(sp)
ffffffffc0200c08:	6105                	addi	sp,sp,32
ffffffffc0200c0a:	8082                	ret

ffffffffc0200c0c <find_vma>:
find_vma(struct mm_struct *mm, uintptr_t addr) {
ffffffffc0200c0c:	86aa                	mv	a3,a0
    if (mm != NULL) {
ffffffffc0200c0e:	c505                	beqz	a0,ffffffffc0200c36 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc0200c10:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0200c12:	c501                	beqz	a0,ffffffffc0200c1a <find_vma+0xe>
ffffffffc0200c14:	651c                	ld	a5,8(a0)
ffffffffc0200c16:	02f5f263          	bgeu	a1,a5,ffffffffc0200c3a <find_vma+0x2e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200c1a:	669c                	ld	a5,8(a3)
                while ((le = list_next(le)) != list) {
ffffffffc0200c1c:	00f68d63          	beq	a3,a5,ffffffffc0200c36 <find_vma+0x2a>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc0200c20:	fe87b703          	ld	a4,-24(a5)
ffffffffc0200c24:	00e5e663          	bltu	a1,a4,ffffffffc0200c30 <find_vma+0x24>
ffffffffc0200c28:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200c2c:	00e5ec63          	bltu	a1,a4,ffffffffc0200c44 <find_vma+0x38>
ffffffffc0200c30:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc0200c32:	fef697e3          	bne	a3,a5,ffffffffc0200c20 <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc0200c36:	4501                	li	a0,0
}
ffffffffc0200c38:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0200c3a:	691c                	ld	a5,16(a0)
ffffffffc0200c3c:	fcf5ffe3          	bgeu	a1,a5,ffffffffc0200c1a <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc0200c40:	ea88                	sd	a0,16(a3)
ffffffffc0200c42:	8082                	ret
                    vma = le2vma(le, list_link);
ffffffffc0200c44:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc0200c48:	ea88                	sd	a0,16(a3)
ffffffffc0200c4a:	8082                	ret

ffffffffc0200c4c <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc0200c4c:	6590                	ld	a2,8(a1)
ffffffffc0200c4e:	0105b803          	ld	a6,16(a1)
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc0200c52:	1141                	addi	sp,sp,-16
ffffffffc0200c54:	e406                	sd	ra,8(sp)
ffffffffc0200c56:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0200c58:	01066763          	bltu	a2,a6,ffffffffc0200c66 <insert_vma_struct+0x1a>
ffffffffc0200c5c:	a085                	j	ffffffffc0200cbc <insert_vma_struct+0x70>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0200c5e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0200c62:	04e66863          	bltu	a2,a4,ffffffffc0200cb2 <insert_vma_struct+0x66>
ffffffffc0200c66:	86be                	mv	a3,a5
ffffffffc0200c68:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0200c6a:	fef51ae3          	bne	a0,a5,ffffffffc0200c5e <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc0200c6e:	02a68463          	beq	a3,a0,ffffffffc0200c96 <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0200c72:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0200c76:	fe86b883          	ld	a7,-24(a3)
ffffffffc0200c7a:	08e8f163          	bgeu	a7,a4,ffffffffc0200cfc <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0200c7e:	04e66f63          	bltu	a2,a4,ffffffffc0200cdc <insert_vma_struct+0x90>
    }
    if (le_next != list) {
ffffffffc0200c82:	00f50a63          	beq	a0,a5,ffffffffc0200c96 <insert_vma_struct+0x4a>
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0200c86:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0200c8a:	05076963          	bltu	a4,a6,ffffffffc0200cdc <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc0200c8e:	ff07b603          	ld	a2,-16(a5)
ffffffffc0200c92:	02c77363          	bgeu	a4,a2,ffffffffc0200cb8 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc0200c96:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0200c98:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0200c9a:	02058613          	addi	a2,a1,32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0200c9e:	e390                	sd	a2,0(a5)
ffffffffc0200ca0:	e690                	sd	a2,8(a3)
}
ffffffffc0200ca2:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0200ca4:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0200ca6:	f194                	sd	a3,32(a1)
    mm->map_count ++;
ffffffffc0200ca8:	0017079b          	addiw	a5,a4,1
ffffffffc0200cac:	d11c                	sw	a5,32(a0)
}
ffffffffc0200cae:	0141                	addi	sp,sp,16
ffffffffc0200cb0:	8082                	ret
    if (le_prev != list) {
ffffffffc0200cb2:	fca690e3          	bne	a3,a0,ffffffffc0200c72 <insert_vma_struct+0x26>
ffffffffc0200cb6:	bfd1                	j	ffffffffc0200c8a <insert_vma_struct+0x3e>
ffffffffc0200cb8:	ebbff0ef          	jal	ra,ffffffffc0200b72 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0200cbc:	00005697          	auipc	a3,0x5
ffffffffc0200cc0:	c6c68693          	addi	a3,a3,-916 # ffffffffc0205928 <commands+0x750>
ffffffffc0200cc4:	00005617          	auipc	a2,0x5
ffffffffc0200cc8:	c3c60613          	addi	a2,a2,-964 # ffffffffc0205900 <commands+0x728>
ffffffffc0200ccc:	08500593          	li	a1,133
ffffffffc0200cd0:	00005517          	auipc	a0,0x5
ffffffffc0200cd4:	c4850513          	addi	a0,a0,-952 # ffffffffc0205918 <commands+0x740>
ffffffffc0200cd8:	cf0ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0200cdc:	00005697          	auipc	a3,0x5
ffffffffc0200ce0:	c8c68693          	addi	a3,a3,-884 # ffffffffc0205968 <commands+0x790>
ffffffffc0200ce4:	00005617          	auipc	a2,0x5
ffffffffc0200ce8:	c1c60613          	addi	a2,a2,-996 # ffffffffc0205900 <commands+0x728>
ffffffffc0200cec:	07d00593          	li	a1,125
ffffffffc0200cf0:	00005517          	auipc	a0,0x5
ffffffffc0200cf4:	c2850513          	addi	a0,a0,-984 # ffffffffc0205918 <commands+0x740>
ffffffffc0200cf8:	cd0ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0200cfc:	00005697          	auipc	a3,0x5
ffffffffc0200d00:	c4c68693          	addi	a3,a3,-948 # ffffffffc0205948 <commands+0x770>
ffffffffc0200d04:	00005617          	auipc	a2,0x5
ffffffffc0200d08:	bfc60613          	addi	a2,a2,-1028 # ffffffffc0205900 <commands+0x728>
ffffffffc0200d0c:	07c00593          	li	a1,124
ffffffffc0200d10:	00005517          	auipc	a0,0x5
ffffffffc0200d14:	c0850513          	addi	a0,a0,-1016 # ffffffffc0205918 <commands+0x740>
ffffffffc0200d18:	cb0ff0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0200d1c <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
ffffffffc0200d1c:	1141                	addi	sp,sp,-16
ffffffffc0200d1e:	e022                	sd	s0,0(sp)
ffffffffc0200d20:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0200d22:	6508                	ld	a0,8(a0)
ffffffffc0200d24:	e406                	sd	ra,8(sp)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc0200d26:	00a40c63          	beq	s0,a0,ffffffffc0200d3e <mm_destroy+0x22>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200d2a:	6118                	ld	a4,0(a0)
ffffffffc0200d2c:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc0200d2e:	1501                	addi	a0,a0,-32
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200d30:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200d32:	e398                	sd	a4,0(a5)
ffffffffc0200d34:	5b9000ef          	jal	ra,ffffffffc0201aec <kfree>
    return listelm->next;
ffffffffc0200d38:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0200d3a:	fea418e3          	bne	s0,a0,ffffffffc0200d2a <mm_destroy+0xe>
    }
    kfree(mm); //kfree mm
ffffffffc0200d3e:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc0200d40:	6402                	ld	s0,0(sp)
ffffffffc0200d42:	60a2                	ld	ra,8(sp)
ffffffffc0200d44:	0141                	addi	sp,sp,16
    kfree(mm); //kfree mm
ffffffffc0200d46:	5a70006f          	j	ffffffffc0201aec <kfree>

ffffffffc0200d4a <vmm_init>:

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc0200d4a:	7139                	addi	sp,sp,-64
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0200d4c:	03000513          	li	a0,48
vmm_init(void) {
ffffffffc0200d50:	fc06                	sd	ra,56(sp)
ffffffffc0200d52:	f822                	sd	s0,48(sp)
ffffffffc0200d54:	f426                	sd	s1,40(sp)
ffffffffc0200d56:	f04a                	sd	s2,32(sp)
ffffffffc0200d58:	ec4e                	sd	s3,24(sp)
ffffffffc0200d5a:	e852                	sd	s4,16(sp)
ffffffffc0200d5c:	e456                	sd	s5,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0200d5e:	4df000ef          	jal	ra,ffffffffc0201a3c <kmalloc>
    if (mm != NULL) {
ffffffffc0200d62:	58050e63          	beqz	a0,ffffffffc02012fe <vmm_init+0x5b4>
    elm->prev = elm->next = elm;
ffffffffc0200d66:	e508                	sd	a0,8(a0)
ffffffffc0200d68:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0200d6a:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0200d6e:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0200d72:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0200d76:	00016797          	auipc	a5,0x16
ffffffffc0200d7a:	8027a783          	lw	a5,-2046(a5) # ffffffffc0216578 <swap_init_ok>
ffffffffc0200d7e:	84aa                	mv	s1,a0
ffffffffc0200d80:	e7b9                	bnez	a5,ffffffffc0200dce <vmm_init+0x84>
        else mm->sm_priv = NULL;
ffffffffc0200d82:	02053423          	sd	zero,40(a0)
vmm_init(void) {
ffffffffc0200d86:	03200413          	li	s0,50
ffffffffc0200d8a:	a811                	j	ffffffffc0200d9e <vmm_init+0x54>
        vma->vm_start = vm_start;
ffffffffc0200d8c:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0200d8e:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0200d90:	00052c23          	sw	zero,24(a0)
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
ffffffffc0200d94:	146d                	addi	s0,s0,-5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0200d96:	8526                	mv	a0,s1
ffffffffc0200d98:	eb5ff0ef          	jal	ra,ffffffffc0200c4c <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc0200d9c:	cc05                	beqz	s0,ffffffffc0200dd4 <vmm_init+0x8a>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200d9e:	03000513          	li	a0,48
ffffffffc0200da2:	49b000ef          	jal	ra,ffffffffc0201a3c <kmalloc>
ffffffffc0200da6:	85aa                	mv	a1,a0
ffffffffc0200da8:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc0200dac:	f165                	bnez	a0,ffffffffc0200d8c <vmm_init+0x42>
        assert(vma != NULL);
ffffffffc0200dae:	00005697          	auipc	a3,0x5
ffffffffc0200db2:	e3268693          	addi	a3,a3,-462 # ffffffffc0205be0 <commands+0xa08>
ffffffffc0200db6:	00005617          	auipc	a2,0x5
ffffffffc0200dba:	b4a60613          	addi	a2,a2,-1206 # ffffffffc0205900 <commands+0x728>
ffffffffc0200dbe:	0c900593          	li	a1,201
ffffffffc0200dc2:	00005517          	auipc	a0,0x5
ffffffffc0200dc6:	b5650513          	addi	a0,a0,-1194 # ffffffffc0205918 <commands+0x740>
ffffffffc0200dca:	bfeff0ef          	jal	ra,ffffffffc02001c8 <__panic>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0200dce:	56a010ef          	jal	ra,ffffffffc0202338 <swap_init_mm>
ffffffffc0200dd2:	bf55                	j	ffffffffc0200d86 <vmm_init+0x3c>
ffffffffc0200dd4:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0200dd8:	1f900913          	li	s2,505
ffffffffc0200ddc:	a819                	j	ffffffffc0200df2 <vmm_init+0xa8>
        vma->vm_start = vm_start;
ffffffffc0200dde:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0200de0:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0200de2:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0200de6:	0415                	addi	s0,s0,5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0200de8:	8526                	mv	a0,s1
ffffffffc0200dea:	e63ff0ef          	jal	ra,ffffffffc0200c4c <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0200dee:	03240a63          	beq	s0,s2,ffffffffc0200e22 <vmm_init+0xd8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200df2:	03000513          	li	a0,48
ffffffffc0200df6:	447000ef          	jal	ra,ffffffffc0201a3c <kmalloc>
ffffffffc0200dfa:	85aa                	mv	a1,a0
ffffffffc0200dfc:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc0200e00:	fd79                	bnez	a0,ffffffffc0200dde <vmm_init+0x94>
        assert(vma != NULL);
ffffffffc0200e02:	00005697          	auipc	a3,0x5
ffffffffc0200e06:	dde68693          	addi	a3,a3,-546 # ffffffffc0205be0 <commands+0xa08>
ffffffffc0200e0a:	00005617          	auipc	a2,0x5
ffffffffc0200e0e:	af660613          	addi	a2,a2,-1290 # ffffffffc0205900 <commands+0x728>
ffffffffc0200e12:	0cf00593          	li	a1,207
ffffffffc0200e16:	00005517          	auipc	a0,0x5
ffffffffc0200e1a:	b0250513          	addi	a0,a0,-1278 # ffffffffc0205918 <commands+0x740>
ffffffffc0200e1e:	baaff0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return listelm->next;
ffffffffc0200e22:	649c                	ld	a5,8(s1)
ffffffffc0200e24:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
ffffffffc0200e26:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc0200e2a:	30f48e63          	beq	s1,a5,ffffffffc0201146 <vmm_init+0x3fc>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0200e2e:	fe87b683          	ld	a3,-24(a5)
ffffffffc0200e32:	ffe70613          	addi	a2,a4,-2
ffffffffc0200e36:	2ad61863          	bne	a2,a3,ffffffffc02010e6 <vmm_init+0x39c>
ffffffffc0200e3a:	ff07b683          	ld	a3,-16(a5)
ffffffffc0200e3e:	2ae69463          	bne	a3,a4,ffffffffc02010e6 <vmm_init+0x39c>
    for (i = 1; i <= step2; i ++) {
ffffffffc0200e42:	0715                	addi	a4,a4,5
ffffffffc0200e44:	679c                	ld	a5,8(a5)
ffffffffc0200e46:	feb712e3          	bne	a4,a1,ffffffffc0200e2a <vmm_init+0xe0>
ffffffffc0200e4a:	4a1d                	li	s4,7
ffffffffc0200e4c:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0200e4e:	1f900a93          	li	s5,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0200e52:	85a2                	mv	a1,s0
ffffffffc0200e54:	8526                	mv	a0,s1
ffffffffc0200e56:	db7ff0ef          	jal	ra,ffffffffc0200c0c <find_vma>
ffffffffc0200e5a:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc0200e5c:	34050563          	beqz	a0,ffffffffc02011a6 <vmm_init+0x45c>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0200e60:	00140593          	addi	a1,s0,1
ffffffffc0200e64:	8526                	mv	a0,s1
ffffffffc0200e66:	da7ff0ef          	jal	ra,ffffffffc0200c0c <find_vma>
ffffffffc0200e6a:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0200e6c:	34050d63          	beqz	a0,ffffffffc02011c6 <vmm_init+0x47c>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0200e70:	85d2                	mv	a1,s4
ffffffffc0200e72:	8526                	mv	a0,s1
ffffffffc0200e74:	d99ff0ef          	jal	ra,ffffffffc0200c0c <find_vma>
        assert(vma3 == NULL);
ffffffffc0200e78:	36051763          	bnez	a0,ffffffffc02011e6 <vmm_init+0x49c>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc0200e7c:	00340593          	addi	a1,s0,3
ffffffffc0200e80:	8526                	mv	a0,s1
ffffffffc0200e82:	d8bff0ef          	jal	ra,ffffffffc0200c0c <find_vma>
        assert(vma4 == NULL);
ffffffffc0200e86:	2e051063          	bnez	a0,ffffffffc0201166 <vmm_init+0x41c>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc0200e8a:	00440593          	addi	a1,s0,4
ffffffffc0200e8e:	8526                	mv	a0,s1
ffffffffc0200e90:	d7dff0ef          	jal	ra,ffffffffc0200c0c <find_vma>
        assert(vma5 == NULL);
ffffffffc0200e94:	2e051963          	bnez	a0,ffffffffc0201186 <vmm_init+0x43c>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0200e98:	00893783          	ld	a5,8(s2)
ffffffffc0200e9c:	26879563          	bne	a5,s0,ffffffffc0201106 <vmm_init+0x3bc>
ffffffffc0200ea0:	01093783          	ld	a5,16(s2)
ffffffffc0200ea4:	27479163          	bne	a5,s4,ffffffffc0201106 <vmm_init+0x3bc>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0200ea8:	0089b783          	ld	a5,8(s3)
ffffffffc0200eac:	26879d63          	bne	a5,s0,ffffffffc0201126 <vmm_init+0x3dc>
ffffffffc0200eb0:	0109b783          	ld	a5,16(s3)
ffffffffc0200eb4:	27479963          	bne	a5,s4,ffffffffc0201126 <vmm_init+0x3dc>
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0200eb8:	0415                	addi	s0,s0,5
ffffffffc0200eba:	0a15                	addi	s4,s4,5
ffffffffc0200ebc:	f9541be3          	bne	s0,s5,ffffffffc0200e52 <vmm_init+0x108>
ffffffffc0200ec0:	4411                	li	s0,4
    }

    for (i =4; i>=0; i--) {
ffffffffc0200ec2:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc0200ec4:	85a2                	mv	a1,s0
ffffffffc0200ec6:	8526                	mv	a0,s1
ffffffffc0200ec8:	d45ff0ef          	jal	ra,ffffffffc0200c0c <find_vma>
ffffffffc0200ecc:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL ) {
ffffffffc0200ed0:	c90d                	beqz	a0,ffffffffc0200f02 <vmm_init+0x1b8>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0200ed2:	6914                	ld	a3,16(a0)
ffffffffc0200ed4:	6510                	ld	a2,8(a0)
ffffffffc0200ed6:	00005517          	auipc	a0,0x5
ffffffffc0200eda:	bb250513          	addi	a0,a0,-1102 # ffffffffc0205a88 <commands+0x8b0>
ffffffffc0200ede:	9eeff0ef          	jal	ra,ffffffffc02000cc <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0200ee2:	00005697          	auipc	a3,0x5
ffffffffc0200ee6:	bce68693          	addi	a3,a3,-1074 # ffffffffc0205ab0 <commands+0x8d8>
ffffffffc0200eea:	00005617          	auipc	a2,0x5
ffffffffc0200eee:	a1660613          	addi	a2,a2,-1514 # ffffffffc0205900 <commands+0x728>
ffffffffc0200ef2:	0f100593          	li	a1,241
ffffffffc0200ef6:	00005517          	auipc	a0,0x5
ffffffffc0200efa:	a2250513          	addi	a0,a0,-1502 # ffffffffc0205918 <commands+0x740>
ffffffffc0200efe:	acaff0ef          	jal	ra,ffffffffc02001c8 <__panic>
    for (i =4; i>=0; i--) {
ffffffffc0200f02:	147d                	addi	s0,s0,-1
ffffffffc0200f04:	fd2410e3          	bne	s0,s2,ffffffffc0200ec4 <vmm_init+0x17a>
ffffffffc0200f08:	a801                	j	ffffffffc0200f18 <vmm_init+0x1ce>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200f0a:	6118                	ld	a4,0(a0)
ffffffffc0200f0c:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc0200f0e:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0200f10:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0200f12:	e398                	sd	a4,0(a5)
ffffffffc0200f14:	3d9000ef          	jal	ra,ffffffffc0201aec <kfree>
    return listelm->next;
ffffffffc0200f18:	6488                	ld	a0,8(s1)
    while ((le = list_next(list)) != list) {
ffffffffc0200f1a:	fea498e3          	bne	s1,a0,ffffffffc0200f0a <vmm_init+0x1c0>
    kfree(mm); //kfree mm
ffffffffc0200f1e:	8526                	mv	a0,s1
ffffffffc0200f20:	3cd000ef          	jal	ra,ffffffffc0201aec <kfree>
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0200f24:	00005517          	auipc	a0,0x5
ffffffffc0200f28:	ba450513          	addi	a0,a0,-1116 # ffffffffc0205ac8 <commands+0x8f0>
ffffffffc0200f2c:	9a0ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0200f30:	166020ef          	jal	ra,ffffffffc0203096 <nr_free_pages>
ffffffffc0200f34:	84aa                	mv	s1,a0
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0200f36:	03000513          	li	a0,48
ffffffffc0200f3a:	303000ef          	jal	ra,ffffffffc0201a3c <kmalloc>
ffffffffc0200f3e:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0200f40:	2c050363          	beqz	a0,ffffffffc0201206 <vmm_init+0x4bc>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0200f44:	00015797          	auipc	a5,0x15
ffffffffc0200f48:	6347a783          	lw	a5,1588(a5) # ffffffffc0216578 <swap_init_ok>
    elm->prev = elm->next = elm;
ffffffffc0200f4c:	e508                	sd	a0,8(a0)
ffffffffc0200f4e:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0200f50:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0200f54:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0200f58:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0200f5c:	18079263          	bnez	a5,ffffffffc02010e0 <vmm_init+0x396>
        else mm->sm_priv = NULL;
ffffffffc0200f60:	02053423          	sd	zero,40(a0)

    check_mm_struct = mm_create();
    assert(check_mm_struct != NULL);

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0200f64:	00015917          	auipc	s2,0x15
ffffffffc0200f68:	62493903          	ld	s2,1572(s2) # ffffffffc0216588 <boot_pgdir>
    assert(pgdir[0] == 0);
ffffffffc0200f6c:	00093783          	ld	a5,0(s2)
    check_mm_struct = mm_create();
ffffffffc0200f70:	00015717          	auipc	a4,0x15
ffffffffc0200f74:	5e873023          	sd	s0,1504(a4) # ffffffffc0216550 <check_mm_struct>
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0200f78:	01243c23          	sd	s2,24(s0)
    assert(pgdir[0] == 0);
ffffffffc0200f7c:	36079163          	bnez	a5,ffffffffc02012de <vmm_init+0x594>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0200f80:	03000513          	li	a0,48
ffffffffc0200f84:	2b9000ef          	jal	ra,ffffffffc0201a3c <kmalloc>
ffffffffc0200f88:	89aa                	mv	s3,a0
    if (vma != NULL) {
ffffffffc0200f8a:	2a050263          	beqz	a0,ffffffffc020122e <vmm_init+0x4e4>
        vma->vm_end = vm_end;
ffffffffc0200f8e:	002007b7          	lui	a5,0x200
ffffffffc0200f92:	00f9b823          	sd	a5,16(s3)
        vma->vm_flags = vm_flags;
ffffffffc0200f96:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0200f98:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc0200f9a:	00f9ac23          	sw	a5,24(s3)
    insert_vma_struct(mm, vma);
ffffffffc0200f9e:	8522                	mv	a0,s0
        vma->vm_start = vm_start;
ffffffffc0200fa0:	0009b423          	sd	zero,8(s3)
    insert_vma_struct(mm, vma);
ffffffffc0200fa4:	ca9ff0ef          	jal	ra,ffffffffc0200c4c <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0200fa8:	10000593          	li	a1,256
ffffffffc0200fac:	8522                	mv	a0,s0
ffffffffc0200fae:	c5fff0ef          	jal	ra,ffffffffc0200c0c <find_vma>
ffffffffc0200fb2:	10000793          	li	a5,256

    int i, sum = 0;
    for (i = 0; i < 100; i ++) {
ffffffffc0200fb6:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0200fba:	28a99a63          	bne	s3,a0,ffffffffc020124e <vmm_init+0x504>
        *(char *)(addr + i) = i;
ffffffffc0200fbe:	00f78023          	sb	a5,0(a5) # 200000 <kern_entry-0xffffffffc0000000>
    for (i = 0; i < 100; i ++) {
ffffffffc0200fc2:	0785                	addi	a5,a5,1
ffffffffc0200fc4:	fee79de3          	bne	a5,a4,ffffffffc0200fbe <vmm_init+0x274>
        sum += i;
ffffffffc0200fc8:	6705                	lui	a4,0x1
ffffffffc0200fca:	10000793          	li	a5,256
ffffffffc0200fce:	35670713          	addi	a4,a4,854 # 1356 <kern_entry-0xffffffffc01fecaa>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc0200fd2:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc0200fd6:	0007c683          	lbu	a3,0(a5)
    for (i = 0; i < 100; i ++) {
ffffffffc0200fda:	0785                	addi	a5,a5,1
        sum -= *(char *)(addr + i);
ffffffffc0200fdc:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc0200fde:	fec79ce3          	bne	a5,a2,ffffffffc0200fd6 <vmm_init+0x28c>
    }
    assert(sum == 0);
ffffffffc0200fe2:	28071663          	bnez	a4,ffffffffc020126e <vmm_init+0x524>
    return pa2page(PTE_ADDR(pte));
}

static inline struct Page *
pde2page(pde_t pde) {
    return pa2page(PDE_ADDR(pde));
ffffffffc0200fe6:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0200fea:	00015a97          	auipc	s5,0x15
ffffffffc0200fee:	5a6a8a93          	addi	s5,s5,1446 # ffffffffc0216590 <npage>
ffffffffc0200ff2:	000ab603          	ld	a2,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0200ff6:	078a                	slli	a5,a5,0x2
ffffffffc0200ff8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0200ffa:	28c7fa63          	bgeu	a5,a2,ffffffffc020128e <vmm_init+0x544>
    return &pages[PPN(pa) - nbase];
ffffffffc0200ffe:	00006a17          	auipc	s4,0x6
ffffffffc0201002:	042a3a03          	ld	s4,66(s4) # ffffffffc0207040 <nbase>
ffffffffc0201006:	414787b3          	sub	a5,a5,s4
ffffffffc020100a:	079a                	slli	a5,a5,0x6
    return page - pages + nbase;
ffffffffc020100c:	8799                	srai	a5,a5,0x6
ffffffffc020100e:	97d2                	add	a5,a5,s4
    return KADDR(page2pa(page));
ffffffffc0201010:	00c79713          	slli	a4,a5,0xc
ffffffffc0201014:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201016:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc020101a:	28c77663          	bgeu	a4,a2,ffffffffc02012a6 <vmm_init+0x55c>
ffffffffc020101e:	00015997          	auipc	s3,0x15
ffffffffc0201022:	58a9b983          	ld	s3,1418(s3) # ffffffffc02165a8 <va_pa_offset>

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc0201026:	4581                	li	a1,0
ffffffffc0201028:	854a                	mv	a0,s2
ffffffffc020102a:	99b6                	add	s3,s3,a3
ffffffffc020102c:	2ca020ef          	jal	ra,ffffffffc02032f6 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc0201030:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0201034:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201038:	078a                	slli	a5,a5,0x2
ffffffffc020103a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020103c:	24e7f963          	bgeu	a5,a4,ffffffffc020128e <vmm_init+0x544>
    return &pages[PPN(pa) - nbase];
ffffffffc0201040:	00015997          	auipc	s3,0x15
ffffffffc0201044:	55898993          	addi	s3,s3,1368 # ffffffffc0216598 <pages>
ffffffffc0201048:	0009b503          	ld	a0,0(s3)
ffffffffc020104c:	414787b3          	sub	a5,a5,s4
ffffffffc0201050:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc0201052:	953e                	add	a0,a0,a5
ffffffffc0201054:	4585                	li	a1,1
ffffffffc0201056:	000020ef          	jal	ra,ffffffffc0203056 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc020105a:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc020105e:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201062:	078a                	slli	a5,a5,0x2
ffffffffc0201064:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201066:	22e7f463          	bgeu	a5,a4,ffffffffc020128e <vmm_init+0x544>
    return &pages[PPN(pa) - nbase];
ffffffffc020106a:	0009b503          	ld	a0,0(s3)
ffffffffc020106e:	414787b3          	sub	a5,a5,s4
ffffffffc0201072:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0201074:	4585                	li	a1,1
ffffffffc0201076:	953e                	add	a0,a0,a5
ffffffffc0201078:	7df010ef          	jal	ra,ffffffffc0203056 <free_pages>
    pgdir[0] = 0;
ffffffffc020107c:	00093023          	sd	zero,0(s2)
    page->ref -= 1;
    return page->ref;
}

static inline void flush_tlb() {
  asm volatile("sfence.vma");
ffffffffc0201080:	12000073          	sfence.vma
    return listelm->next;
ffffffffc0201084:	6408                	ld	a0,8(s0)
    flush_tlb();

    mm->pgdir = NULL;
ffffffffc0201086:	00043c23          	sd	zero,24(s0)
    while ((le = list_next(list)) != list) {
ffffffffc020108a:	00a40c63          	beq	s0,a0,ffffffffc02010a2 <vmm_init+0x358>
    __list_del(listelm->prev, listelm->next);
ffffffffc020108e:	6118                	ld	a4,0(a0)
ffffffffc0201090:	651c                	ld	a5,8(a0)
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc0201092:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0201094:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201096:	e398                	sd	a4,0(a5)
ffffffffc0201098:	255000ef          	jal	ra,ffffffffc0201aec <kfree>
    return listelm->next;
ffffffffc020109c:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc020109e:	fea418e3          	bne	s0,a0,ffffffffc020108e <vmm_init+0x344>
    kfree(mm); //kfree mm
ffffffffc02010a2:	8522                	mv	a0,s0
ffffffffc02010a4:	249000ef          	jal	ra,ffffffffc0201aec <kfree>
    mm_destroy(mm);
    check_mm_struct = NULL;
ffffffffc02010a8:	00015797          	auipc	a5,0x15
ffffffffc02010ac:	4a07b423          	sd	zero,1192(a5) # ffffffffc0216550 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02010b0:	7e7010ef          	jal	ra,ffffffffc0203096 <nr_free_pages>
ffffffffc02010b4:	20a49563          	bne	s1,a0,ffffffffc02012be <vmm_init+0x574>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc02010b8:	00005517          	auipc	a0,0x5
ffffffffc02010bc:	af050513          	addi	a0,a0,-1296 # ffffffffc0205ba8 <commands+0x9d0>
ffffffffc02010c0:	80cff0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc02010c4:	7442                	ld	s0,48(sp)
ffffffffc02010c6:	70e2                	ld	ra,56(sp)
ffffffffc02010c8:	74a2                	ld	s1,40(sp)
ffffffffc02010ca:	7902                	ld	s2,32(sp)
ffffffffc02010cc:	69e2                	ld	s3,24(sp)
ffffffffc02010ce:	6a42                	ld	s4,16(sp)
ffffffffc02010d0:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc02010d2:	00005517          	auipc	a0,0x5
ffffffffc02010d6:	af650513          	addi	a0,a0,-1290 # ffffffffc0205bc8 <commands+0x9f0>
}
ffffffffc02010da:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc02010dc:	ff1fe06f          	j	ffffffffc02000cc <cprintf>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02010e0:	258010ef          	jal	ra,ffffffffc0202338 <swap_init_mm>
ffffffffc02010e4:	b541                	j	ffffffffc0200f64 <vmm_init+0x21a>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02010e6:	00005697          	auipc	a3,0x5
ffffffffc02010ea:	8ba68693          	addi	a3,a3,-1862 # ffffffffc02059a0 <commands+0x7c8>
ffffffffc02010ee:	00005617          	auipc	a2,0x5
ffffffffc02010f2:	81260613          	addi	a2,a2,-2030 # ffffffffc0205900 <commands+0x728>
ffffffffc02010f6:	0d800593          	li	a1,216
ffffffffc02010fa:	00005517          	auipc	a0,0x5
ffffffffc02010fe:	81e50513          	addi	a0,a0,-2018 # ffffffffc0205918 <commands+0x740>
ffffffffc0201102:	8c6ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc0201106:	00005697          	auipc	a3,0x5
ffffffffc020110a:	92268693          	addi	a3,a3,-1758 # ffffffffc0205a28 <commands+0x850>
ffffffffc020110e:	00004617          	auipc	a2,0x4
ffffffffc0201112:	7f260613          	addi	a2,a2,2034 # ffffffffc0205900 <commands+0x728>
ffffffffc0201116:	0e800593          	li	a1,232
ffffffffc020111a:	00004517          	auipc	a0,0x4
ffffffffc020111e:	7fe50513          	addi	a0,a0,2046 # ffffffffc0205918 <commands+0x740>
ffffffffc0201122:	8a6ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0201126:	00005697          	auipc	a3,0x5
ffffffffc020112a:	93268693          	addi	a3,a3,-1742 # ffffffffc0205a58 <commands+0x880>
ffffffffc020112e:	00004617          	auipc	a2,0x4
ffffffffc0201132:	7d260613          	addi	a2,a2,2002 # ffffffffc0205900 <commands+0x728>
ffffffffc0201136:	0e900593          	li	a1,233
ffffffffc020113a:	00004517          	auipc	a0,0x4
ffffffffc020113e:	7de50513          	addi	a0,a0,2014 # ffffffffc0205918 <commands+0x740>
ffffffffc0201142:	886ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0201146:	00005697          	auipc	a3,0x5
ffffffffc020114a:	84268693          	addi	a3,a3,-1982 # ffffffffc0205988 <commands+0x7b0>
ffffffffc020114e:	00004617          	auipc	a2,0x4
ffffffffc0201152:	7b260613          	addi	a2,a2,1970 # ffffffffc0205900 <commands+0x728>
ffffffffc0201156:	0d600593          	li	a1,214
ffffffffc020115a:	00004517          	auipc	a0,0x4
ffffffffc020115e:	7be50513          	addi	a0,a0,1982 # ffffffffc0205918 <commands+0x740>
ffffffffc0201162:	866ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(vma4 == NULL);
ffffffffc0201166:	00005697          	auipc	a3,0x5
ffffffffc020116a:	8a268693          	addi	a3,a3,-1886 # ffffffffc0205a08 <commands+0x830>
ffffffffc020116e:	00004617          	auipc	a2,0x4
ffffffffc0201172:	79260613          	addi	a2,a2,1938 # ffffffffc0205900 <commands+0x728>
ffffffffc0201176:	0e400593          	li	a1,228
ffffffffc020117a:	00004517          	auipc	a0,0x4
ffffffffc020117e:	79e50513          	addi	a0,a0,1950 # ffffffffc0205918 <commands+0x740>
ffffffffc0201182:	846ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(vma5 == NULL);
ffffffffc0201186:	00005697          	auipc	a3,0x5
ffffffffc020118a:	89268693          	addi	a3,a3,-1902 # ffffffffc0205a18 <commands+0x840>
ffffffffc020118e:	00004617          	auipc	a2,0x4
ffffffffc0201192:	77260613          	addi	a2,a2,1906 # ffffffffc0205900 <commands+0x728>
ffffffffc0201196:	0e600593          	li	a1,230
ffffffffc020119a:	00004517          	auipc	a0,0x4
ffffffffc020119e:	77e50513          	addi	a0,a0,1918 # ffffffffc0205918 <commands+0x740>
ffffffffc02011a2:	826ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(vma1 != NULL);
ffffffffc02011a6:	00005697          	auipc	a3,0x5
ffffffffc02011aa:	83268693          	addi	a3,a3,-1998 # ffffffffc02059d8 <commands+0x800>
ffffffffc02011ae:	00004617          	auipc	a2,0x4
ffffffffc02011b2:	75260613          	addi	a2,a2,1874 # ffffffffc0205900 <commands+0x728>
ffffffffc02011b6:	0de00593          	li	a1,222
ffffffffc02011ba:	00004517          	auipc	a0,0x4
ffffffffc02011be:	75e50513          	addi	a0,a0,1886 # ffffffffc0205918 <commands+0x740>
ffffffffc02011c2:	806ff0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(vma2 != NULL);
ffffffffc02011c6:	00005697          	auipc	a3,0x5
ffffffffc02011ca:	82268693          	addi	a3,a3,-2014 # ffffffffc02059e8 <commands+0x810>
ffffffffc02011ce:	00004617          	auipc	a2,0x4
ffffffffc02011d2:	73260613          	addi	a2,a2,1842 # ffffffffc0205900 <commands+0x728>
ffffffffc02011d6:	0e000593          	li	a1,224
ffffffffc02011da:	00004517          	auipc	a0,0x4
ffffffffc02011de:	73e50513          	addi	a0,a0,1854 # ffffffffc0205918 <commands+0x740>
ffffffffc02011e2:	fe7fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert(vma3 == NULL);
ffffffffc02011e6:	00005697          	auipc	a3,0x5
ffffffffc02011ea:	81268693          	addi	a3,a3,-2030 # ffffffffc02059f8 <commands+0x820>
ffffffffc02011ee:	00004617          	auipc	a2,0x4
ffffffffc02011f2:	71260613          	addi	a2,a2,1810 # ffffffffc0205900 <commands+0x728>
ffffffffc02011f6:	0e200593          	li	a1,226
ffffffffc02011fa:	00004517          	auipc	a0,0x4
ffffffffc02011fe:	71e50513          	addi	a0,a0,1822 # ffffffffc0205918 <commands+0x740>
ffffffffc0201202:	fc7fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc0201206:	00005697          	auipc	a3,0x5
ffffffffc020120a:	9ea68693          	addi	a3,a3,-1558 # ffffffffc0205bf0 <commands+0xa18>
ffffffffc020120e:	00004617          	auipc	a2,0x4
ffffffffc0201212:	6f260613          	addi	a2,a2,1778 # ffffffffc0205900 <commands+0x728>
ffffffffc0201216:	10100593          	li	a1,257
ffffffffc020121a:	00004517          	auipc	a0,0x4
ffffffffc020121e:	6fe50513          	addi	a0,a0,1790 # ffffffffc0205918 <commands+0x740>
    check_mm_struct = mm_create();
ffffffffc0201222:	00015797          	auipc	a5,0x15
ffffffffc0201226:	3207b723          	sd	zero,814(a5) # ffffffffc0216550 <check_mm_struct>
    assert(check_mm_struct != NULL);
ffffffffc020122a:	f9ffe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(vma != NULL);
ffffffffc020122e:	00005697          	auipc	a3,0x5
ffffffffc0201232:	9b268693          	addi	a3,a3,-1614 # ffffffffc0205be0 <commands+0xa08>
ffffffffc0201236:	00004617          	auipc	a2,0x4
ffffffffc020123a:	6ca60613          	addi	a2,a2,1738 # ffffffffc0205900 <commands+0x728>
ffffffffc020123e:	10800593          	li	a1,264
ffffffffc0201242:	00004517          	auipc	a0,0x4
ffffffffc0201246:	6d650513          	addi	a0,a0,1750 # ffffffffc0205918 <commands+0x740>
ffffffffc020124a:	f7ffe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc020124e:	00005697          	auipc	a3,0x5
ffffffffc0201252:	8aa68693          	addi	a3,a3,-1878 # ffffffffc0205af8 <commands+0x920>
ffffffffc0201256:	00004617          	auipc	a2,0x4
ffffffffc020125a:	6aa60613          	addi	a2,a2,1706 # ffffffffc0205900 <commands+0x728>
ffffffffc020125e:	10d00593          	li	a1,269
ffffffffc0201262:	00004517          	auipc	a0,0x4
ffffffffc0201266:	6b650513          	addi	a0,a0,1718 # ffffffffc0205918 <commands+0x740>
ffffffffc020126a:	f5ffe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(sum == 0);
ffffffffc020126e:	00005697          	auipc	a3,0x5
ffffffffc0201272:	8aa68693          	addi	a3,a3,-1878 # ffffffffc0205b18 <commands+0x940>
ffffffffc0201276:	00004617          	auipc	a2,0x4
ffffffffc020127a:	68a60613          	addi	a2,a2,1674 # ffffffffc0205900 <commands+0x728>
ffffffffc020127e:	11700593          	li	a1,279
ffffffffc0201282:	00004517          	auipc	a0,0x4
ffffffffc0201286:	69650513          	addi	a0,a0,1686 # ffffffffc0205918 <commands+0x740>
ffffffffc020128a:	f3ffe0ef          	jal	ra,ffffffffc02001c8 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020128e:	00005617          	auipc	a2,0x5
ffffffffc0201292:	89a60613          	addi	a2,a2,-1894 # ffffffffc0205b28 <commands+0x950>
ffffffffc0201296:	06200593          	li	a1,98
ffffffffc020129a:	00005517          	auipc	a0,0x5
ffffffffc020129e:	8ae50513          	addi	a0,a0,-1874 # ffffffffc0205b48 <commands+0x970>
ffffffffc02012a2:	f27fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return KADDR(page2pa(page));
ffffffffc02012a6:	00005617          	auipc	a2,0x5
ffffffffc02012aa:	8b260613          	addi	a2,a2,-1870 # ffffffffc0205b58 <commands+0x980>
ffffffffc02012ae:	06900593          	li	a1,105
ffffffffc02012b2:	00005517          	auipc	a0,0x5
ffffffffc02012b6:	89650513          	addi	a0,a0,-1898 # ffffffffc0205b48 <commands+0x970>
ffffffffc02012ba:	f0ffe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02012be:	00005697          	auipc	a3,0x5
ffffffffc02012c2:	8c268693          	addi	a3,a3,-1854 # ffffffffc0205b80 <commands+0x9a8>
ffffffffc02012c6:	00004617          	auipc	a2,0x4
ffffffffc02012ca:	63a60613          	addi	a2,a2,1594 # ffffffffc0205900 <commands+0x728>
ffffffffc02012ce:	12400593          	li	a1,292
ffffffffc02012d2:	00004517          	auipc	a0,0x4
ffffffffc02012d6:	64650513          	addi	a0,a0,1606 # ffffffffc0205918 <commands+0x740>
ffffffffc02012da:	eeffe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgdir[0] == 0);
ffffffffc02012de:	00005697          	auipc	a3,0x5
ffffffffc02012e2:	80a68693          	addi	a3,a3,-2038 # ffffffffc0205ae8 <commands+0x910>
ffffffffc02012e6:	00004617          	auipc	a2,0x4
ffffffffc02012ea:	61a60613          	addi	a2,a2,1562 # ffffffffc0205900 <commands+0x728>
ffffffffc02012ee:	10500593          	li	a1,261
ffffffffc02012f2:	00004517          	auipc	a0,0x4
ffffffffc02012f6:	62650513          	addi	a0,a0,1574 # ffffffffc0205918 <commands+0x740>
ffffffffc02012fa:	ecffe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(mm != NULL);
ffffffffc02012fe:	00005697          	auipc	a3,0x5
ffffffffc0201302:	90a68693          	addi	a3,a3,-1782 # ffffffffc0205c08 <commands+0xa30>
ffffffffc0201306:	00004617          	auipc	a2,0x4
ffffffffc020130a:	5fa60613          	addi	a2,a2,1530 # ffffffffc0205900 <commands+0x728>
ffffffffc020130e:	0c200593          	li	a1,194
ffffffffc0201312:	00004517          	auipc	a0,0x4
ffffffffc0201316:	60650513          	addi	a0,a0,1542 # ffffffffc0205918 <commands+0x740>
ffffffffc020131a:	eaffe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc020131e <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
ffffffffc020131e:	7139                	addi	sp,sp,-64
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0201320:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr) {
ffffffffc0201322:	f822                	sd	s0,48(sp)
ffffffffc0201324:	f426                	sd	s1,40(sp)
ffffffffc0201326:	fc06                	sd	ra,56(sp)
ffffffffc0201328:	f04a                	sd	s2,32(sp)
ffffffffc020132a:	ec4e                	sd	s3,24(sp)
ffffffffc020132c:	8432                	mv	s0,a2
ffffffffc020132e:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0201330:	8ddff0ef          	jal	ra,ffffffffc0200c0c <find_vma>

    pgfault_num++;
ffffffffc0201334:	00015797          	auipc	a5,0x15
ffffffffc0201338:	2247a783          	lw	a5,548(a5) # ffffffffc0216558 <pgfault_num>
ffffffffc020133c:	2785                	addiw	a5,a5,1
ffffffffc020133e:	00015717          	auipc	a4,0x15
ffffffffc0201342:	20f72d23          	sw	a5,538(a4) # ffffffffc0216558 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc0201346:	c545                	beqz	a0,ffffffffc02013ee <do_pgfault+0xd0>
ffffffffc0201348:	651c                	ld	a5,8(a0)
ffffffffc020134a:	0af46263          	bltu	s0,a5,ffffffffc02013ee <do_pgfault+0xd0>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc020134e:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc0201350:	49c1                	li	s3,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0201352:	8b89                	andi	a5,a5,2
ffffffffc0201354:	efb1                	bnez	a5,ffffffffc02013b0 <do_pgfault+0x92>
        perm |= READ_WRITE;
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0201356:	75fd                	lui	a1,0xfffff

    pte_t *ptep=NULL;
  
    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0201358:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc020135a:	8c6d                	and	s0,s0,a1
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc020135c:	4605                	li	a2,1
ffffffffc020135e:	85a2                	mv	a1,s0
ffffffffc0201360:	571010ef          	jal	ra,ffffffffc02030d0 <get_pte>
ffffffffc0201364:	c555                	beqz	a0,ffffffffc0201410 <do_pgfault+0xf2>
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
ffffffffc0201366:	610c                	ld	a1,0(a0)
ffffffffc0201368:	c5a5                	beqz	a1,ffffffffc02013d0 <do_pgfault+0xb2>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc020136a:	00015797          	auipc	a5,0x15
ffffffffc020136e:	20e7a783          	lw	a5,526(a5) # ffffffffc0216578 <swap_init_ok>
ffffffffc0201372:	c7d9                	beqz	a5,ffffffffc0201400 <do_pgfault+0xe2>
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
            ret=swap_in(mm,addr,&page);//调用swap_in函数从磁盘上读取数据
ffffffffc0201374:	0030                	addi	a2,sp,8
ffffffffc0201376:	85a2                	mv	a1,s0
ffffffffc0201378:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc020137a:	e402                	sd	zero,8(sp)
            ret=swap_in(mm,addr,&page);//调用swap_in函数从磁盘上读取数据
ffffffffc020137c:	0e8010ef          	jal	ra,ffffffffc0202464 <swap_in>
ffffffffc0201380:	892a                	mv	s2,a0
            if(ret!=0)
ffffffffc0201382:	e90d                	bnez	a0,ffffffffc02013b4 <do_pgfault+0x96>
            {
                cprintf("swap_in failed\n");
               goto failed;                 
            }
            // 交换成功，则建立物理地址<--->虚拟地址映射，并将页设置为可交换的
            page_insert(mm->pgdir, page, addr, perm);
ffffffffc0201384:	65a2                	ld	a1,8(sp)
ffffffffc0201386:	6c88                	ld	a0,24(s1)
ffffffffc0201388:	86ce                	mv	a3,s3
ffffffffc020138a:	8622                	mv	a2,s0
ffffffffc020138c:	006020ef          	jal	ra,ffffffffc0203392 <page_insert>
            swap_map_swappable(mm, addr, page, 1);//将物理页设置为可交换状态
ffffffffc0201390:	6622                	ld	a2,8(sp)
ffffffffc0201392:	4685                	li	a3,1
ffffffffc0201394:	85a2                	mv	a1,s0
ffffffffc0201396:	8526                	mv	a0,s1
ffffffffc0201398:	7ad000ef          	jal	ra,ffffffffc0202344 <swap_map_swappable>
            page->pra_vaddr = addr;
ffffffffc020139c:	67a2                	ld	a5,8(sp)
ffffffffc020139e:	ff80                	sd	s0,56(a5)
   }

   ret = 0;
failed:
    return ret;
ffffffffc02013a0:	70e2                	ld	ra,56(sp)
ffffffffc02013a2:	7442                	ld	s0,48(sp)
ffffffffc02013a4:	74a2                	ld	s1,40(sp)
ffffffffc02013a6:	69e2                	ld	s3,24(sp)
ffffffffc02013a8:	854a                	mv	a0,s2
ffffffffc02013aa:	7902                	ld	s2,32(sp)
ffffffffc02013ac:	6121                	addi	sp,sp,64
ffffffffc02013ae:	8082                	ret
        perm |= READ_WRITE;
ffffffffc02013b0:	49dd                	li	s3,23
ffffffffc02013b2:	b755                	j	ffffffffc0201356 <do_pgfault+0x38>
                cprintf("swap_in failed\n");
ffffffffc02013b4:	00005517          	auipc	a0,0x5
ffffffffc02013b8:	8dc50513          	addi	a0,a0,-1828 # ffffffffc0205c90 <commands+0xab8>
ffffffffc02013bc:	d11fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc02013c0:	70e2                	ld	ra,56(sp)
ffffffffc02013c2:	7442                	ld	s0,48(sp)
ffffffffc02013c4:	74a2                	ld	s1,40(sp)
ffffffffc02013c6:	69e2                	ld	s3,24(sp)
ffffffffc02013c8:	854a                	mv	a0,s2
ffffffffc02013ca:	7902                	ld	s2,32(sp)
ffffffffc02013cc:	6121                	addi	sp,sp,64
ffffffffc02013ce:	8082                	ret
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc02013d0:	6c88                	ld	a0,24(s1)
ffffffffc02013d2:	864e                	mv	a2,s3
ffffffffc02013d4:	85a2                	mv	a1,s0
ffffffffc02013d6:	453020ef          	jal	ra,ffffffffc0204028 <pgdir_alloc_page>
   ret = 0;
ffffffffc02013da:	4901                	li	s2,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc02013dc:	f171                	bnez	a0,ffffffffc02013a0 <do_pgfault+0x82>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc02013de:	00005517          	auipc	a0,0x5
ffffffffc02013e2:	88a50513          	addi	a0,a0,-1910 # ffffffffc0205c68 <commands+0xa90>
ffffffffc02013e6:	ce7fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM;
ffffffffc02013ea:	5971                	li	s2,-4
            goto failed;
ffffffffc02013ec:	bf55                	j	ffffffffc02013a0 <do_pgfault+0x82>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc02013ee:	85a2                	mv	a1,s0
ffffffffc02013f0:	00005517          	auipc	a0,0x5
ffffffffc02013f4:	82850513          	addi	a0,a0,-2008 # ffffffffc0205c18 <commands+0xa40>
ffffffffc02013f8:	cd5fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    int ret = -E_INVAL;
ffffffffc02013fc:	5975                	li	s2,-3
        goto failed;
ffffffffc02013fe:	b74d                	j	ffffffffc02013a0 <do_pgfault+0x82>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0201400:	00005517          	auipc	a0,0x5
ffffffffc0201404:	8a050513          	addi	a0,a0,-1888 # ffffffffc0205ca0 <commands+0xac8>
ffffffffc0201408:	cc5fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM;
ffffffffc020140c:	5971                	li	s2,-4
            goto failed;
ffffffffc020140e:	bf49                	j	ffffffffc02013a0 <do_pgfault+0x82>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc0201410:	00005517          	auipc	a0,0x5
ffffffffc0201414:	83850513          	addi	a0,a0,-1992 # ffffffffc0205c48 <commands+0xa70>
ffffffffc0201418:	cb5fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM;
ffffffffc020141c:	5971                	li	s2,-4
        goto failed;
ffffffffc020141e:	b749                	j	ffffffffc02013a0 <do_pgfault+0x82>

ffffffffc0201420 <_fifo_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc0201420:	00011797          	auipc	a5,0x11
ffffffffc0201424:	04078793          	addi	a5,a5,64 # ffffffffc0212460 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
ffffffffc0201428:	f51c                	sd	a5,40(a0)
ffffffffc020142a:	e79c                	sd	a5,8(a5)
ffffffffc020142c:	e39c                	sd	a5,0(a5)
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc020142e:	4501                	li	a0,0
ffffffffc0201430:	8082                	ret

ffffffffc0201432 <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0201432:	4501                	li	a0,0
ffffffffc0201434:	8082                	ret

ffffffffc0201436 <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0201436:	4501                	li	a0,0
ffffffffc0201438:	8082                	ret

ffffffffc020143a <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc020143a:	4501                	li	a0,0
ffffffffc020143c:	8082                	ret

ffffffffc020143e <_fifo_check_swap>:
_fifo_check_swap(void) {
ffffffffc020143e:	711d                	addi	sp,sp,-96
ffffffffc0201440:	fc4e                	sd	s3,56(sp)
ffffffffc0201442:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0201444:	00005517          	auipc	a0,0x5
ffffffffc0201448:	88450513          	addi	a0,a0,-1916 # ffffffffc0205cc8 <commands+0xaf0>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc020144c:	698d                	lui	s3,0x3
ffffffffc020144e:	4a31                	li	s4,12
_fifo_check_swap(void) {
ffffffffc0201450:	e0ca                	sd	s2,64(sp)
ffffffffc0201452:	ec86                	sd	ra,88(sp)
ffffffffc0201454:	e8a2                	sd	s0,80(sp)
ffffffffc0201456:	e4a6                	sd	s1,72(sp)
ffffffffc0201458:	f456                	sd	s5,40(sp)
ffffffffc020145a:	f05a                	sd	s6,32(sp)
ffffffffc020145c:	ec5e                	sd	s7,24(sp)
ffffffffc020145e:	e862                	sd	s8,16(sp)
ffffffffc0201460:	e466                	sd	s9,8(sp)
ffffffffc0201462:	e06a                	sd	s10,0(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0201464:	c69fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0201468:	01498023          	sb	s4,0(s3) # 3000 <kern_entry-0xffffffffc01fd000>
    assert(pgfault_num==4);
ffffffffc020146c:	00015917          	auipc	s2,0x15
ffffffffc0201470:	0ec92903          	lw	s2,236(s2) # ffffffffc0216558 <pgfault_num>
ffffffffc0201474:	4791                	li	a5,4
ffffffffc0201476:	14f91e63          	bne	s2,a5,ffffffffc02015d2 <_fifo_check_swap+0x194>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc020147a:	00005517          	auipc	a0,0x5
ffffffffc020147e:	89e50513          	addi	a0,a0,-1890 # ffffffffc0205d18 <commands+0xb40>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201482:	6a85                	lui	s5,0x1
ffffffffc0201484:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0201486:	c47fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc020148a:	00015417          	auipc	s0,0x15
ffffffffc020148e:	0ce40413          	addi	s0,s0,206 # ffffffffc0216558 <pgfault_num>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201492:	016a8023          	sb	s6,0(s5) # 1000 <kern_entry-0xffffffffc01ff000>
    assert(pgfault_num==4);
ffffffffc0201496:	4004                	lw	s1,0(s0)
ffffffffc0201498:	2481                	sext.w	s1,s1
ffffffffc020149a:	2b249c63          	bne	s1,s2,ffffffffc0201752 <_fifo_check_swap+0x314>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc020149e:	00005517          	auipc	a0,0x5
ffffffffc02014a2:	8a250513          	addi	a0,a0,-1886 # ffffffffc0205d40 <commands+0xb68>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02014a6:	6b91                	lui	s7,0x4
ffffffffc02014a8:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc02014aa:	c23fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc02014ae:	018b8023          	sb	s8,0(s7) # 4000 <kern_entry-0xffffffffc01fc000>
    assert(pgfault_num==4);
ffffffffc02014b2:	00042903          	lw	s2,0(s0)
ffffffffc02014b6:	2901                	sext.w	s2,s2
ffffffffc02014b8:	26991d63          	bne	s2,s1,ffffffffc0201732 <_fifo_check_swap+0x2f4>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc02014bc:	00005517          	auipc	a0,0x5
ffffffffc02014c0:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0205d68 <commands+0xb90>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc02014c4:	6c89                	lui	s9,0x2
ffffffffc02014c6:	4d2d                	li	s10,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc02014c8:	c05fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc02014cc:	01ac8023          	sb	s10,0(s9) # 2000 <kern_entry-0xffffffffc01fe000>
    assert(pgfault_num==4);
ffffffffc02014d0:	401c                	lw	a5,0(s0)
ffffffffc02014d2:	2781                	sext.w	a5,a5
ffffffffc02014d4:	23279f63          	bne	a5,s2,ffffffffc0201712 <_fifo_check_swap+0x2d4>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc02014d8:	00005517          	auipc	a0,0x5
ffffffffc02014dc:	8b850513          	addi	a0,a0,-1864 # ffffffffc0205d90 <commands+0xbb8>
ffffffffc02014e0:	bedfe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc02014e4:	6795                	lui	a5,0x5
ffffffffc02014e6:	4739                	li	a4,14
ffffffffc02014e8:	00e78023          	sb	a4,0(a5) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==5);
ffffffffc02014ec:	4004                	lw	s1,0(s0)
ffffffffc02014ee:	4795                	li	a5,5
ffffffffc02014f0:	2481                	sext.w	s1,s1
ffffffffc02014f2:	20f49063          	bne	s1,a5,ffffffffc02016f2 <_fifo_check_swap+0x2b4>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc02014f6:	00005517          	auipc	a0,0x5
ffffffffc02014fa:	87250513          	addi	a0,a0,-1934 # ffffffffc0205d68 <commands+0xb90>
ffffffffc02014fe:	bcffe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201502:	01ac8023          	sb	s10,0(s9)
    assert(pgfault_num==5);
ffffffffc0201506:	401c                	lw	a5,0(s0)
ffffffffc0201508:	2781                	sext.w	a5,a5
ffffffffc020150a:	1c979463          	bne	a5,s1,ffffffffc02016d2 <_fifo_check_swap+0x294>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc020150e:	00005517          	auipc	a0,0x5
ffffffffc0201512:	80a50513          	addi	a0,a0,-2038 # ffffffffc0205d18 <commands+0xb40>
ffffffffc0201516:	bb7fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc020151a:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num==6);
ffffffffc020151e:	401c                	lw	a5,0(s0)
ffffffffc0201520:	4719                	li	a4,6
ffffffffc0201522:	2781                	sext.w	a5,a5
ffffffffc0201524:	18e79763          	bne	a5,a4,ffffffffc02016b2 <_fifo_check_swap+0x274>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0201528:	00005517          	auipc	a0,0x5
ffffffffc020152c:	84050513          	addi	a0,a0,-1984 # ffffffffc0205d68 <commands+0xb90>
ffffffffc0201530:	b9dfe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201534:	01ac8023          	sb	s10,0(s9)
    assert(pgfault_num==7);
ffffffffc0201538:	401c                	lw	a5,0(s0)
ffffffffc020153a:	471d                	li	a4,7
ffffffffc020153c:	2781                	sext.w	a5,a5
ffffffffc020153e:	14e79a63          	bne	a5,a4,ffffffffc0201692 <_fifo_check_swap+0x254>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0201542:	00004517          	auipc	a0,0x4
ffffffffc0201546:	78650513          	addi	a0,a0,1926 # ffffffffc0205cc8 <commands+0xaf0>
ffffffffc020154a:	b83fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc020154e:	01498023          	sb	s4,0(s3)
    assert(pgfault_num==8);
ffffffffc0201552:	401c                	lw	a5,0(s0)
ffffffffc0201554:	4721                	li	a4,8
ffffffffc0201556:	2781                	sext.w	a5,a5
ffffffffc0201558:	10e79d63          	bne	a5,a4,ffffffffc0201672 <_fifo_check_swap+0x234>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc020155c:	00004517          	auipc	a0,0x4
ffffffffc0201560:	7e450513          	addi	a0,a0,2020 # ffffffffc0205d40 <commands+0xb68>
ffffffffc0201564:	b69fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0201568:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num==9);
ffffffffc020156c:	401c                	lw	a5,0(s0)
ffffffffc020156e:	4725                	li	a4,9
ffffffffc0201570:	2781                	sext.w	a5,a5
ffffffffc0201572:	0ee79063          	bne	a5,a4,ffffffffc0201652 <_fifo_check_swap+0x214>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0201576:	00005517          	auipc	a0,0x5
ffffffffc020157a:	81a50513          	addi	a0,a0,-2022 # ffffffffc0205d90 <commands+0xbb8>
ffffffffc020157e:	b4ffe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0201582:	6795                	lui	a5,0x5
ffffffffc0201584:	4739                	li	a4,14
ffffffffc0201586:	00e78023          	sb	a4,0(a5) # 5000 <kern_entry-0xffffffffc01fb000>
    assert(pgfault_num==10);
ffffffffc020158a:	4004                	lw	s1,0(s0)
ffffffffc020158c:	47a9                	li	a5,10
ffffffffc020158e:	2481                	sext.w	s1,s1
ffffffffc0201590:	0af49163          	bne	s1,a5,ffffffffc0201632 <_fifo_check_swap+0x1f4>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0201594:	00004517          	auipc	a0,0x4
ffffffffc0201598:	78450513          	addi	a0,a0,1924 # ffffffffc0205d18 <commands+0xb40>
ffffffffc020159c:	b31fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc02015a0:	6785                	lui	a5,0x1
ffffffffc02015a2:	0007c783          	lbu	a5,0(a5) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc02015a6:	06979663          	bne	a5,s1,ffffffffc0201612 <_fifo_check_swap+0x1d4>
    assert(pgfault_num==11);
ffffffffc02015aa:	401c                	lw	a5,0(s0)
ffffffffc02015ac:	472d                	li	a4,11
ffffffffc02015ae:	2781                	sext.w	a5,a5
ffffffffc02015b0:	04e79163          	bne	a5,a4,ffffffffc02015f2 <_fifo_check_swap+0x1b4>
}
ffffffffc02015b4:	60e6                	ld	ra,88(sp)
ffffffffc02015b6:	6446                	ld	s0,80(sp)
ffffffffc02015b8:	64a6                	ld	s1,72(sp)
ffffffffc02015ba:	6906                	ld	s2,64(sp)
ffffffffc02015bc:	79e2                	ld	s3,56(sp)
ffffffffc02015be:	7a42                	ld	s4,48(sp)
ffffffffc02015c0:	7aa2                	ld	s5,40(sp)
ffffffffc02015c2:	7b02                	ld	s6,32(sp)
ffffffffc02015c4:	6be2                	ld	s7,24(sp)
ffffffffc02015c6:	6c42                	ld	s8,16(sp)
ffffffffc02015c8:	6ca2                	ld	s9,8(sp)
ffffffffc02015ca:	6d02                	ld	s10,0(sp)
ffffffffc02015cc:	4501                	li	a0,0
ffffffffc02015ce:	6125                	addi	sp,sp,96
ffffffffc02015d0:	8082                	ret
    assert(pgfault_num==4);
ffffffffc02015d2:	00004697          	auipc	a3,0x4
ffffffffc02015d6:	71e68693          	addi	a3,a3,1822 # ffffffffc0205cf0 <commands+0xb18>
ffffffffc02015da:	00004617          	auipc	a2,0x4
ffffffffc02015de:	32660613          	addi	a2,a2,806 # ffffffffc0205900 <commands+0x728>
ffffffffc02015e2:	05100593          	li	a1,81
ffffffffc02015e6:	00004517          	auipc	a0,0x4
ffffffffc02015ea:	71a50513          	addi	a0,a0,1818 # ffffffffc0205d00 <commands+0xb28>
ffffffffc02015ee:	bdbfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==11);
ffffffffc02015f2:	00005697          	auipc	a3,0x5
ffffffffc02015f6:	84e68693          	addi	a3,a3,-1970 # ffffffffc0205e40 <commands+0xc68>
ffffffffc02015fa:	00004617          	auipc	a2,0x4
ffffffffc02015fe:	30660613          	addi	a2,a2,774 # ffffffffc0205900 <commands+0x728>
ffffffffc0201602:	07300593          	li	a1,115
ffffffffc0201606:	00004517          	auipc	a0,0x4
ffffffffc020160a:	6fa50513          	addi	a0,a0,1786 # ffffffffc0205d00 <commands+0xb28>
ffffffffc020160e:	bbbfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0201612:	00005697          	auipc	a3,0x5
ffffffffc0201616:	80668693          	addi	a3,a3,-2042 # ffffffffc0205e18 <commands+0xc40>
ffffffffc020161a:	00004617          	auipc	a2,0x4
ffffffffc020161e:	2e660613          	addi	a2,a2,742 # ffffffffc0205900 <commands+0x728>
ffffffffc0201622:	07100593          	li	a1,113
ffffffffc0201626:	00004517          	auipc	a0,0x4
ffffffffc020162a:	6da50513          	addi	a0,a0,1754 # ffffffffc0205d00 <commands+0xb28>
ffffffffc020162e:	b9bfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==10);
ffffffffc0201632:	00004697          	auipc	a3,0x4
ffffffffc0201636:	7d668693          	addi	a3,a3,2006 # ffffffffc0205e08 <commands+0xc30>
ffffffffc020163a:	00004617          	auipc	a2,0x4
ffffffffc020163e:	2c660613          	addi	a2,a2,710 # ffffffffc0205900 <commands+0x728>
ffffffffc0201642:	06f00593          	li	a1,111
ffffffffc0201646:	00004517          	auipc	a0,0x4
ffffffffc020164a:	6ba50513          	addi	a0,a0,1722 # ffffffffc0205d00 <commands+0xb28>
ffffffffc020164e:	b7bfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==9);
ffffffffc0201652:	00004697          	auipc	a3,0x4
ffffffffc0201656:	7a668693          	addi	a3,a3,1958 # ffffffffc0205df8 <commands+0xc20>
ffffffffc020165a:	00004617          	auipc	a2,0x4
ffffffffc020165e:	2a660613          	addi	a2,a2,678 # ffffffffc0205900 <commands+0x728>
ffffffffc0201662:	06c00593          	li	a1,108
ffffffffc0201666:	00004517          	auipc	a0,0x4
ffffffffc020166a:	69a50513          	addi	a0,a0,1690 # ffffffffc0205d00 <commands+0xb28>
ffffffffc020166e:	b5bfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==8);
ffffffffc0201672:	00004697          	auipc	a3,0x4
ffffffffc0201676:	77668693          	addi	a3,a3,1910 # ffffffffc0205de8 <commands+0xc10>
ffffffffc020167a:	00004617          	auipc	a2,0x4
ffffffffc020167e:	28660613          	addi	a2,a2,646 # ffffffffc0205900 <commands+0x728>
ffffffffc0201682:	06900593          	li	a1,105
ffffffffc0201686:	00004517          	auipc	a0,0x4
ffffffffc020168a:	67a50513          	addi	a0,a0,1658 # ffffffffc0205d00 <commands+0xb28>
ffffffffc020168e:	b3bfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==7);
ffffffffc0201692:	00004697          	auipc	a3,0x4
ffffffffc0201696:	74668693          	addi	a3,a3,1862 # ffffffffc0205dd8 <commands+0xc00>
ffffffffc020169a:	00004617          	auipc	a2,0x4
ffffffffc020169e:	26660613          	addi	a2,a2,614 # ffffffffc0205900 <commands+0x728>
ffffffffc02016a2:	06600593          	li	a1,102
ffffffffc02016a6:	00004517          	auipc	a0,0x4
ffffffffc02016aa:	65a50513          	addi	a0,a0,1626 # ffffffffc0205d00 <commands+0xb28>
ffffffffc02016ae:	b1bfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==6);
ffffffffc02016b2:	00004697          	auipc	a3,0x4
ffffffffc02016b6:	71668693          	addi	a3,a3,1814 # ffffffffc0205dc8 <commands+0xbf0>
ffffffffc02016ba:	00004617          	auipc	a2,0x4
ffffffffc02016be:	24660613          	addi	a2,a2,582 # ffffffffc0205900 <commands+0x728>
ffffffffc02016c2:	06300593          	li	a1,99
ffffffffc02016c6:	00004517          	auipc	a0,0x4
ffffffffc02016ca:	63a50513          	addi	a0,a0,1594 # ffffffffc0205d00 <commands+0xb28>
ffffffffc02016ce:	afbfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==5);
ffffffffc02016d2:	00004697          	auipc	a3,0x4
ffffffffc02016d6:	6e668693          	addi	a3,a3,1766 # ffffffffc0205db8 <commands+0xbe0>
ffffffffc02016da:	00004617          	auipc	a2,0x4
ffffffffc02016de:	22660613          	addi	a2,a2,550 # ffffffffc0205900 <commands+0x728>
ffffffffc02016e2:	06000593          	li	a1,96
ffffffffc02016e6:	00004517          	auipc	a0,0x4
ffffffffc02016ea:	61a50513          	addi	a0,a0,1562 # ffffffffc0205d00 <commands+0xb28>
ffffffffc02016ee:	adbfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==5);
ffffffffc02016f2:	00004697          	auipc	a3,0x4
ffffffffc02016f6:	6c668693          	addi	a3,a3,1734 # ffffffffc0205db8 <commands+0xbe0>
ffffffffc02016fa:	00004617          	auipc	a2,0x4
ffffffffc02016fe:	20660613          	addi	a2,a2,518 # ffffffffc0205900 <commands+0x728>
ffffffffc0201702:	05d00593          	li	a1,93
ffffffffc0201706:	00004517          	auipc	a0,0x4
ffffffffc020170a:	5fa50513          	addi	a0,a0,1530 # ffffffffc0205d00 <commands+0xb28>
ffffffffc020170e:	abbfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==4);
ffffffffc0201712:	00004697          	auipc	a3,0x4
ffffffffc0201716:	5de68693          	addi	a3,a3,1502 # ffffffffc0205cf0 <commands+0xb18>
ffffffffc020171a:	00004617          	auipc	a2,0x4
ffffffffc020171e:	1e660613          	addi	a2,a2,486 # ffffffffc0205900 <commands+0x728>
ffffffffc0201722:	05a00593          	li	a1,90
ffffffffc0201726:	00004517          	auipc	a0,0x4
ffffffffc020172a:	5da50513          	addi	a0,a0,1498 # ffffffffc0205d00 <commands+0xb28>
ffffffffc020172e:	a9bfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==4);
ffffffffc0201732:	00004697          	auipc	a3,0x4
ffffffffc0201736:	5be68693          	addi	a3,a3,1470 # ffffffffc0205cf0 <commands+0xb18>
ffffffffc020173a:	00004617          	auipc	a2,0x4
ffffffffc020173e:	1c660613          	addi	a2,a2,454 # ffffffffc0205900 <commands+0x728>
ffffffffc0201742:	05700593          	li	a1,87
ffffffffc0201746:	00004517          	auipc	a0,0x4
ffffffffc020174a:	5ba50513          	addi	a0,a0,1466 # ffffffffc0205d00 <commands+0xb28>
ffffffffc020174e:	a7bfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pgfault_num==4);
ffffffffc0201752:	00004697          	auipc	a3,0x4
ffffffffc0201756:	59e68693          	addi	a3,a3,1438 # ffffffffc0205cf0 <commands+0xb18>
ffffffffc020175a:	00004617          	auipc	a2,0x4
ffffffffc020175e:	1a660613          	addi	a2,a2,422 # ffffffffc0205900 <commands+0x728>
ffffffffc0201762:	05400593          	li	a1,84
ffffffffc0201766:	00004517          	auipc	a0,0x4
ffffffffc020176a:	59a50513          	addi	a0,a0,1434 # ffffffffc0205d00 <commands+0xb28>
ffffffffc020176e:	a5bfe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0201772 <_fifo_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc0201772:	751c                	ld	a5,40(a0)
{
ffffffffc0201774:	1141                	addi	sp,sp,-16
ffffffffc0201776:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc0201778:	cf91                	beqz	a5,ffffffffc0201794 <_fifo_swap_out_victim+0x22>
     assert(in_tick==0);
ffffffffc020177a:	ee0d                	bnez	a2,ffffffffc02017b4 <_fifo_swap_out_victim+0x42>
    return listelm->next;
ffffffffc020177c:	679c                	ld	a5,8(a5)
}
ffffffffc020177e:	60a2                	ld	ra,8(sp)
ffffffffc0201780:	4501                	li	a0,0
    __list_del(listelm->prev, listelm->next);
ffffffffc0201782:	6394                	ld	a3,0(a5)
ffffffffc0201784:	6798                	ld	a4,8(a5)
    *ptr_page = le2page(entry, pra_page_link);
ffffffffc0201786:	fd878793          	addi	a5,a5,-40
    prev->next = next;
ffffffffc020178a:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc020178c:	e314                	sd	a3,0(a4)
ffffffffc020178e:	e19c                	sd	a5,0(a1)
}
ffffffffc0201790:	0141                	addi	sp,sp,16
ffffffffc0201792:	8082                	ret
         assert(head != NULL);
ffffffffc0201794:	00004697          	auipc	a3,0x4
ffffffffc0201798:	6bc68693          	addi	a3,a3,1724 # ffffffffc0205e50 <commands+0xc78>
ffffffffc020179c:	00004617          	auipc	a2,0x4
ffffffffc02017a0:	16460613          	addi	a2,a2,356 # ffffffffc0205900 <commands+0x728>
ffffffffc02017a4:	04100593          	li	a1,65
ffffffffc02017a8:	00004517          	auipc	a0,0x4
ffffffffc02017ac:	55850513          	addi	a0,a0,1368 # ffffffffc0205d00 <commands+0xb28>
ffffffffc02017b0:	a19fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(in_tick==0);
ffffffffc02017b4:	00004697          	auipc	a3,0x4
ffffffffc02017b8:	6ac68693          	addi	a3,a3,1708 # ffffffffc0205e60 <commands+0xc88>
ffffffffc02017bc:	00004617          	auipc	a2,0x4
ffffffffc02017c0:	14460613          	addi	a2,a2,324 # ffffffffc0205900 <commands+0x728>
ffffffffc02017c4:	04200593          	li	a1,66
ffffffffc02017c8:	00004517          	auipc	a0,0x4
ffffffffc02017cc:	53850513          	addi	a0,a0,1336 # ffffffffc0205d00 <commands+0xb28>
ffffffffc02017d0:	9f9fe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02017d4 <_fifo_map_swappable>:
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc02017d4:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc02017d6:	cb91                	beqz	a5,ffffffffc02017ea <_fifo_map_swappable+0x16>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02017d8:	6394                	ld	a3,0(a5)
ffffffffc02017da:	02860713          	addi	a4,a2,40
    prev->next = next->prev = elm;
ffffffffc02017de:	e398                	sd	a4,0(a5)
ffffffffc02017e0:	e698                	sd	a4,8(a3)
}
ffffffffc02017e2:	4501                	li	a0,0
    elm->next = next;
ffffffffc02017e4:	fa1c                	sd	a5,48(a2)
    elm->prev = prev;
ffffffffc02017e6:	f614                	sd	a3,40(a2)
ffffffffc02017e8:	8082                	ret
{
ffffffffc02017ea:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc02017ec:	00004697          	auipc	a3,0x4
ffffffffc02017f0:	68468693          	addi	a3,a3,1668 # ffffffffc0205e70 <commands+0xc98>
ffffffffc02017f4:	00004617          	auipc	a2,0x4
ffffffffc02017f8:	10c60613          	addi	a2,a2,268 # ffffffffc0205900 <commands+0x728>
ffffffffc02017fc:	03200593          	li	a1,50
ffffffffc0201800:	00004517          	auipc	a0,0x4
ffffffffc0201804:	50050513          	addi	a0,a0,1280 # ffffffffc0205d00 <commands+0xb28>
{
ffffffffc0201808:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc020180a:	9bffe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc020180e <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc020180e:	c94d                	beqz	a0,ffffffffc02018c0 <slob_free+0xb2>
{
ffffffffc0201810:	1141                	addi	sp,sp,-16
ffffffffc0201812:	e022                	sd	s0,0(sp)
ffffffffc0201814:	e406                	sd	ra,8(sp)
ffffffffc0201816:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201818:	e9c1                	bnez	a1,ffffffffc02018a8 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020181a:	100027f3          	csrr	a5,sstatus
ffffffffc020181e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201820:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201822:	ebd9                	bnez	a5,ffffffffc02018b8 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201824:	0000a617          	auipc	a2,0xa
ffffffffc0201828:	82c60613          	addi	a2,a2,-2004 # ffffffffc020b050 <slobfree>
ffffffffc020182c:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020182e:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201830:	679c                	ld	a5,8(a5)
ffffffffc0201832:	02877a63          	bgeu	a4,s0,ffffffffc0201866 <slob_free+0x58>
ffffffffc0201836:	00f46463          	bltu	s0,a5,ffffffffc020183e <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc020183a:	fef76ae3          	bltu	a4,a5,ffffffffc020182e <slob_free+0x20>
			break;

	if (b + b->units == cur->next) {
ffffffffc020183e:	400c                	lw	a1,0(s0)
ffffffffc0201840:	00459693          	slli	a3,a1,0x4
ffffffffc0201844:	96a2                	add	a3,a3,s0
ffffffffc0201846:	02d78a63          	beq	a5,a3,ffffffffc020187a <slob_free+0x6c>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc020184a:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc020184c:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) {
ffffffffc020184e:	00469793          	slli	a5,a3,0x4
ffffffffc0201852:	97ba                	add	a5,a5,a4
ffffffffc0201854:	02f40e63          	beq	s0,a5,ffffffffc0201890 <slob_free+0x82>
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;
ffffffffc0201858:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc020185a:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc020185c:	e129                	bnez	a0,ffffffffc020189e <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc020185e:	60a2                	ld	ra,8(sp)
ffffffffc0201860:	6402                	ld	s0,0(sp)
ffffffffc0201862:	0141                	addi	sp,sp,16
ffffffffc0201864:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201866:	fcf764e3          	bltu	a4,a5,ffffffffc020182e <slob_free+0x20>
ffffffffc020186a:	fcf472e3          	bgeu	s0,a5,ffffffffc020182e <slob_free+0x20>
	if (b + b->units == cur->next) {
ffffffffc020186e:	400c                	lw	a1,0(s0)
ffffffffc0201870:	00459693          	slli	a3,a1,0x4
ffffffffc0201874:	96a2                	add	a3,a3,s0
ffffffffc0201876:	fcd79ae3          	bne	a5,a3,ffffffffc020184a <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc020187a:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc020187c:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc020187e:	9db5                	addw	a1,a1,a3
ffffffffc0201880:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b) {
ffffffffc0201882:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201884:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) {
ffffffffc0201886:	00469793          	slli	a5,a3,0x4
ffffffffc020188a:	97ba                	add	a5,a5,a4
ffffffffc020188c:	fcf416e3          	bne	s0,a5,ffffffffc0201858 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201890:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201892:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201894:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201896:	9ebd                	addw	a3,a3,a5
ffffffffc0201898:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc020189a:	e70c                	sd	a1,8(a4)
ffffffffc020189c:	d169                	beqz	a0,ffffffffc020185e <slob_free+0x50>
}
ffffffffc020189e:	6402                	ld	s0,0(sp)
ffffffffc02018a0:	60a2                	ld	ra,8(sp)
ffffffffc02018a2:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc02018a4:	d1bfe06f          	j	ffffffffc02005be <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc02018a8:	25bd                	addiw	a1,a1,15
ffffffffc02018aa:	8191                	srli	a1,a1,0x4
ffffffffc02018ac:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018ae:	100027f3          	csrr	a5,sstatus
ffffffffc02018b2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02018b4:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02018b6:	d7bd                	beqz	a5,ffffffffc0201824 <slob_free+0x16>
        intr_disable();
ffffffffc02018b8:	d0dfe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        return 1;
ffffffffc02018bc:	4505                	li	a0,1
ffffffffc02018be:	b79d                	j	ffffffffc0201824 <slob_free+0x16>
ffffffffc02018c0:	8082                	ret

ffffffffc02018c2 <__slob_get_free_pages.constprop.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc02018c2:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02018c4:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc02018c6:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc02018ca:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc02018cc:	6f8010ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
  if(!page)
ffffffffc02018d0:	c91d                	beqz	a0,ffffffffc0201906 <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc02018d2:	00015697          	auipc	a3,0x15
ffffffffc02018d6:	cc66b683          	ld	a3,-826(a3) # ffffffffc0216598 <pages>
ffffffffc02018da:	8d15                	sub	a0,a0,a3
ffffffffc02018dc:	8519                	srai	a0,a0,0x6
ffffffffc02018de:	00005697          	auipc	a3,0x5
ffffffffc02018e2:	7626b683          	ld	a3,1890(a3) # ffffffffc0207040 <nbase>
ffffffffc02018e6:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc02018e8:	00c51793          	slli	a5,a0,0xc
ffffffffc02018ec:	83b1                	srli	a5,a5,0xc
ffffffffc02018ee:	00015717          	auipc	a4,0x15
ffffffffc02018f2:	ca273703          	ld	a4,-862(a4) # ffffffffc0216590 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc02018f6:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc02018f8:	00e7fa63          	bgeu	a5,a4,ffffffffc020190c <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc02018fc:	00015697          	auipc	a3,0x15
ffffffffc0201900:	cac6b683          	ld	a3,-852(a3) # ffffffffc02165a8 <va_pa_offset>
ffffffffc0201904:	9536                	add	a0,a0,a3
}
ffffffffc0201906:	60a2                	ld	ra,8(sp)
ffffffffc0201908:	0141                	addi	sp,sp,16
ffffffffc020190a:	8082                	ret
ffffffffc020190c:	86aa                	mv	a3,a0
ffffffffc020190e:	00004617          	auipc	a2,0x4
ffffffffc0201912:	24a60613          	addi	a2,a2,586 # ffffffffc0205b58 <commands+0x980>
ffffffffc0201916:	06900593          	li	a1,105
ffffffffc020191a:	00004517          	auipc	a0,0x4
ffffffffc020191e:	22e50513          	addi	a0,a0,558 # ffffffffc0205b48 <commands+0x970>
ffffffffc0201922:	8a7fe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0201926 <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201926:	1101                	addi	sp,sp,-32
ffffffffc0201928:	ec06                	sd	ra,24(sp)
ffffffffc020192a:	e822                	sd	s0,16(sp)
ffffffffc020192c:	e426                	sd	s1,8(sp)
ffffffffc020192e:	e04a                	sd	s2,0(sp)
	assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201930:	01050713          	addi	a4,a0,16
ffffffffc0201934:	6785                	lui	a5,0x1
ffffffffc0201936:	0cf77363          	bgeu	a4,a5,ffffffffc02019fc <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc020193a:	00f50493          	addi	s1,a0,15
ffffffffc020193e:	8091                	srli	s1,s1,0x4
ffffffffc0201940:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201942:	10002673          	csrr	a2,sstatus
ffffffffc0201946:	8a09                	andi	a2,a2,2
ffffffffc0201948:	e25d                	bnez	a2,ffffffffc02019ee <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc020194a:	00009917          	auipc	s2,0x9
ffffffffc020194e:	70690913          	addi	s2,s2,1798 # ffffffffc020b050 <slobfree>
ffffffffc0201952:	00093683          	ld	a3,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201956:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201958:	4398                	lw	a4,0(a5)
ffffffffc020195a:	08975e63          	bge	a4,s1,ffffffffc02019f6 <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree) {
ffffffffc020195e:	00d78b63          	beq	a5,a3,ffffffffc0201974 <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201962:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201964:	4018                	lw	a4,0(s0)
ffffffffc0201966:	02975a63          	bge	a4,s1,ffffffffc020199a <slob_alloc.constprop.0+0x74>
		if (cur == slobfree) {
ffffffffc020196a:	00093683          	ld	a3,0(s2)
ffffffffc020196e:	87a2                	mv	a5,s0
ffffffffc0201970:	fed799e3          	bne	a5,a3,ffffffffc0201962 <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc0201974:	ee31                	bnez	a2,ffffffffc02019d0 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201976:	4501                	li	a0,0
ffffffffc0201978:	f4bff0ef          	jal	ra,ffffffffc02018c2 <__slob_get_free_pages.constprop.0>
ffffffffc020197c:	842a                	mv	s0,a0
			if (!cur)
ffffffffc020197e:	cd05                	beqz	a0,ffffffffc02019b6 <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201980:	6585                	lui	a1,0x1
ffffffffc0201982:	e8dff0ef          	jal	ra,ffffffffc020180e <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201986:	10002673          	csrr	a2,sstatus
ffffffffc020198a:	8a09                	andi	a2,a2,2
ffffffffc020198c:	ee05                	bnez	a2,ffffffffc02019c4 <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc020198e:	00093783          	ld	a5,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201992:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201994:	4018                	lw	a4,0(s0)
ffffffffc0201996:	fc974ae3          	blt	a4,s1,ffffffffc020196a <slob_alloc.constprop.0+0x44>
			if (cur->units == units) /* exact fit? */
ffffffffc020199a:	04e48763          	beq	s1,a4,ffffffffc02019e8 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc020199e:	00449693          	slli	a3,s1,0x4
ffffffffc02019a2:	96a2                	add	a3,a3,s0
ffffffffc02019a4:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc02019a6:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc02019a8:	9f05                	subw	a4,a4,s1
ffffffffc02019aa:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc02019ac:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc02019ae:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc02019b0:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc02019b4:	e20d                	bnez	a2,ffffffffc02019d6 <slob_alloc.constprop.0+0xb0>
}
ffffffffc02019b6:	60e2                	ld	ra,24(sp)
ffffffffc02019b8:	8522                	mv	a0,s0
ffffffffc02019ba:	6442                	ld	s0,16(sp)
ffffffffc02019bc:	64a2                	ld	s1,8(sp)
ffffffffc02019be:	6902                	ld	s2,0(sp)
ffffffffc02019c0:	6105                	addi	sp,sp,32
ffffffffc02019c2:	8082                	ret
        intr_disable();
ffffffffc02019c4:	c01fe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
			cur = slobfree;
ffffffffc02019c8:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc02019cc:	4605                	li	a2,1
ffffffffc02019ce:	b7d1                	j	ffffffffc0201992 <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc02019d0:	beffe0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc02019d4:	b74d                	j	ffffffffc0201976 <slob_alloc.constprop.0+0x50>
ffffffffc02019d6:	be9fe0ef          	jal	ra,ffffffffc02005be <intr_enable>
}
ffffffffc02019da:	60e2                	ld	ra,24(sp)
ffffffffc02019dc:	8522                	mv	a0,s0
ffffffffc02019de:	6442                	ld	s0,16(sp)
ffffffffc02019e0:	64a2                	ld	s1,8(sp)
ffffffffc02019e2:	6902                	ld	s2,0(sp)
ffffffffc02019e4:	6105                	addi	sp,sp,32
ffffffffc02019e6:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc02019e8:	6418                	ld	a4,8(s0)
ffffffffc02019ea:	e798                	sd	a4,8(a5)
ffffffffc02019ec:	b7d1                	j	ffffffffc02019b0 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc02019ee:	bd7fe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        return 1;
ffffffffc02019f2:	4605                	li	a2,1
ffffffffc02019f4:	bf99                	j	ffffffffc020194a <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc02019f6:	843e                	mv	s0,a5
ffffffffc02019f8:	87b6                	mv	a5,a3
ffffffffc02019fa:	b745                	j	ffffffffc020199a <slob_alloc.constprop.0+0x74>
	assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc02019fc:	00004697          	auipc	a3,0x4
ffffffffc0201a00:	4ac68693          	addi	a3,a3,1196 # ffffffffc0205ea8 <commands+0xcd0>
ffffffffc0201a04:	00004617          	auipc	a2,0x4
ffffffffc0201a08:	efc60613          	addi	a2,a2,-260 # ffffffffc0205900 <commands+0x728>
ffffffffc0201a0c:	06300593          	li	a1,99
ffffffffc0201a10:	00004517          	auipc	a0,0x4
ffffffffc0201a14:	4b850513          	addi	a0,a0,1208 # ffffffffc0205ec8 <commands+0xcf0>
ffffffffc0201a18:	fb0fe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0201a1c <kmalloc_init>:
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
ffffffffc0201a1c:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc0201a1e:	00004517          	auipc	a0,0x4
ffffffffc0201a22:	4c250513          	addi	a0,a0,1218 # ffffffffc0205ee0 <commands+0xd08>
kmalloc_init(void) {
ffffffffc0201a26:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc0201a28:	ea4fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201a2c:	60a2                	ld	ra,8(sp)
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a2e:	00004517          	auipc	a0,0x4
ffffffffc0201a32:	4ca50513          	addi	a0,a0,1226 # ffffffffc0205ef8 <commands+0xd20>
}
ffffffffc0201a36:	0141                	addi	sp,sp,16
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201a38:	e94fe06f          	j	ffffffffc02000cc <cprintf>

ffffffffc0201a3c <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201a3c:	1101                	addi	sp,sp,-32
ffffffffc0201a3e:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201a40:	6905                	lui	s2,0x1
{
ffffffffc0201a42:	e822                	sd	s0,16(sp)
ffffffffc0201a44:	ec06                	sd	ra,24(sp)
ffffffffc0201a46:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201a48:	fef90793          	addi	a5,s2,-17 # fef <kern_entry-0xffffffffc01ff011>
{
ffffffffc0201a4c:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201a4e:	04a7f963          	bgeu	a5,a0,ffffffffc0201aa0 <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201a52:	4561                	li	a0,24
ffffffffc0201a54:	ed3ff0ef          	jal	ra,ffffffffc0201926 <slob_alloc.constprop.0>
ffffffffc0201a58:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201a5a:	c929                	beqz	a0,ffffffffc0201aac <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201a5c:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201a60:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201a62:	00f95763          	bge	s2,a5,ffffffffc0201a70 <kmalloc+0x34>
ffffffffc0201a66:	6705                	lui	a4,0x1
ffffffffc0201a68:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201a6a:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201a6c:	fef74ee3          	blt	a4,a5,ffffffffc0201a68 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201a70:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201a72:	e51ff0ef          	jal	ra,ffffffffc02018c2 <__slob_get_free_pages.constprop.0>
ffffffffc0201a76:	e488                	sd	a0,8(s1)
ffffffffc0201a78:	842a                	mv	s0,a0
	if (bb->pages) {
ffffffffc0201a7a:	c525                	beqz	a0,ffffffffc0201ae2 <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a7c:	100027f3          	csrr	a5,sstatus
ffffffffc0201a80:	8b89                	andi	a5,a5,2
ffffffffc0201a82:	ef8d                	bnez	a5,ffffffffc0201abc <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201a84:	00015797          	auipc	a5,0x15
ffffffffc0201a88:	adc78793          	addi	a5,a5,-1316 # ffffffffc0216560 <bigblocks>
ffffffffc0201a8c:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201a8e:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201a90:	e898                	sd	a4,16(s1)
  return __kmalloc(size, 0);
}
ffffffffc0201a92:	60e2                	ld	ra,24(sp)
ffffffffc0201a94:	8522                	mv	a0,s0
ffffffffc0201a96:	6442                	ld	s0,16(sp)
ffffffffc0201a98:	64a2                	ld	s1,8(sp)
ffffffffc0201a9a:	6902                	ld	s2,0(sp)
ffffffffc0201a9c:	6105                	addi	sp,sp,32
ffffffffc0201a9e:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201aa0:	0541                	addi	a0,a0,16
ffffffffc0201aa2:	e85ff0ef          	jal	ra,ffffffffc0201926 <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201aa6:	01050413          	addi	s0,a0,16
ffffffffc0201aaa:	f565                	bnez	a0,ffffffffc0201a92 <kmalloc+0x56>
ffffffffc0201aac:	4401                	li	s0,0
}
ffffffffc0201aae:	60e2                	ld	ra,24(sp)
ffffffffc0201ab0:	8522                	mv	a0,s0
ffffffffc0201ab2:	6442                	ld	s0,16(sp)
ffffffffc0201ab4:	64a2                	ld	s1,8(sp)
ffffffffc0201ab6:	6902                	ld	s2,0(sp)
ffffffffc0201ab8:	6105                	addi	sp,sp,32
ffffffffc0201aba:	8082                	ret
        intr_disable();
ffffffffc0201abc:	b09fe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201ac0:	00015797          	auipc	a5,0x15
ffffffffc0201ac4:	aa078793          	addi	a5,a5,-1376 # ffffffffc0216560 <bigblocks>
ffffffffc0201ac8:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201aca:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201acc:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201ace:	af1fe0ef          	jal	ra,ffffffffc02005be <intr_enable>
		return bb->pages;
ffffffffc0201ad2:	6480                	ld	s0,8(s1)
}
ffffffffc0201ad4:	60e2                	ld	ra,24(sp)
ffffffffc0201ad6:	64a2                	ld	s1,8(sp)
ffffffffc0201ad8:	8522                	mv	a0,s0
ffffffffc0201ada:	6442                	ld	s0,16(sp)
ffffffffc0201adc:	6902                	ld	s2,0(sp)
ffffffffc0201ade:	6105                	addi	sp,sp,32
ffffffffc0201ae0:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201ae2:	45e1                	li	a1,24
ffffffffc0201ae4:	8526                	mv	a0,s1
ffffffffc0201ae6:	d29ff0ef          	jal	ra,ffffffffc020180e <slob_free>
  return __kmalloc(size, 0);
ffffffffc0201aea:	b765                	j	ffffffffc0201a92 <kmalloc+0x56>

ffffffffc0201aec <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201aec:	c169                	beqz	a0,ffffffffc0201bae <kfree+0xc2>
{
ffffffffc0201aee:	1101                	addi	sp,sp,-32
ffffffffc0201af0:	e822                	sd	s0,16(sp)
ffffffffc0201af2:	ec06                	sd	ra,24(sp)
ffffffffc0201af4:	e426                	sd	s1,8(sp)
		return;
	//检查传入的指针block是否与页面大小-1的按位与为0，即检查是否是页面对齐的指针
	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc0201af6:	03451793          	slli	a5,a0,0x34
ffffffffc0201afa:	842a                	mv	s0,a0
ffffffffc0201afc:	e3d9                	bnez	a5,ffffffffc0201b82 <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201afe:	100027f3          	csrr	a5,sstatus
ffffffffc0201b02:	8b89                	andi	a5,a5,2
ffffffffc0201b04:	e7d9                	bnez	a5,ffffffffc0201b92 <kfree+0xa6>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);//// 获取自旋锁并保存当前中断状态到flags变量
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201b06:	00015797          	auipc	a5,0x15
ffffffffc0201b0a:	a5a7b783          	ld	a5,-1446(a5) # ffffffffc0216560 <bigblocks>
    return 0;
ffffffffc0201b0e:	4601                	li	a2,0
ffffffffc0201b10:	cbad                	beqz	a5,ffffffffc0201b82 <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201b12:	00015697          	auipc	a3,0x15
ffffffffc0201b16:	a4e68693          	addi	a3,a3,-1458 # ffffffffc0216560 <bigblocks>
ffffffffc0201b1a:	a021                	j	ffffffffc0201b22 <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201b1c:	01048693          	addi	a3,s1,16
ffffffffc0201b20:	c3a5                	beqz	a5,ffffffffc0201b80 <kfree+0x94>
			if (bb->pages == block) {//// 如果当前bigblock_t结构体中的pages字段等于block指针
ffffffffc0201b22:	6798                	ld	a4,8(a5)
ffffffffc0201b24:	84be                	mv	s1,a5
				*last = bb->next;// 将上一个bigblock_t结构体的next指针指向当前bigblock_t结构体的下一个指针
ffffffffc0201b26:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block) {//// 如果当前bigblock_t结构体中的pages字段等于block指针
ffffffffc0201b28:	fe871ae3          	bne	a4,s0,ffffffffc0201b1c <kfree+0x30>
				*last = bb->next;// 将上一个bigblock_t结构体的next指针指向当前bigblock_t结构体的下一个指针
ffffffffc0201b2c:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201b2e:	ee2d                	bnez	a2,ffffffffc0201ba8 <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201b30:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);  // 释放自旋锁并恢复之前的中断状态
				__slob_free_pages((unsigned long)block, bb->order);//释放对应的页面
ffffffffc0201b34:	4098                	lw	a4,0(s1)
ffffffffc0201b36:	08f46963          	bltu	s0,a5,ffffffffc0201bc8 <kfree+0xdc>
ffffffffc0201b3a:	00015697          	auipc	a3,0x15
ffffffffc0201b3e:	a6e6b683          	ld	a3,-1426(a3) # ffffffffc02165a8 <va_pa_offset>
ffffffffc0201b42:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage) {
ffffffffc0201b44:	8031                	srli	s0,s0,0xc
ffffffffc0201b46:	00015797          	auipc	a5,0x15
ffffffffc0201b4a:	a4a7b783          	ld	a5,-1462(a5) # ffffffffc0216590 <npage>
ffffffffc0201b4e:	06f47163          	bgeu	s0,a5,ffffffffc0201bb0 <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201b52:	00005517          	auipc	a0,0x5
ffffffffc0201b56:	4ee53503          	ld	a0,1262(a0) # ffffffffc0207040 <nbase>
ffffffffc0201b5a:	8c09                	sub	s0,s0,a0
ffffffffc0201b5c:	041a                	slli	s0,s0,0x6
  free_pages(kva2page(kva), 1 << order);
ffffffffc0201b5e:	00015517          	auipc	a0,0x15
ffffffffc0201b62:	a3a53503          	ld	a0,-1478(a0) # ffffffffc0216598 <pages>
ffffffffc0201b66:	4585                	li	a1,1
ffffffffc0201b68:	9522                	add	a0,a0,s0
ffffffffc0201b6a:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201b6e:	4e8010ef          	jal	ra,ffffffffc0203056 <free_pages>
		spin_unlock_irqrestore(&block_lock, flags); // 释放自旋锁并恢复之前的中断状态
	}

	slob_free((slob_t *)block - 1, 0); //释放内存块
	return;
}
ffffffffc0201b72:	6442                	ld	s0,16(sp)
ffffffffc0201b74:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));// 释放bigblock_t结构体占用的内存空间
ffffffffc0201b76:	8526                	mv	a0,s1
}
ffffffffc0201b78:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));// 释放bigblock_t结构体占用的内存空间
ffffffffc0201b7a:	45e1                	li	a1,24
}
ffffffffc0201b7c:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0); //释放内存块
ffffffffc0201b7e:	b941                	j	ffffffffc020180e <slob_free>
ffffffffc0201b80:	e20d                	bnez	a2,ffffffffc0201ba2 <kfree+0xb6>
ffffffffc0201b82:	ff040513          	addi	a0,s0,-16
}
ffffffffc0201b86:	6442                	ld	s0,16(sp)
ffffffffc0201b88:	60e2                	ld	ra,24(sp)
ffffffffc0201b8a:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0); //释放内存块
ffffffffc0201b8c:	4581                	li	a1,0
}
ffffffffc0201b8e:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0); //释放内存块
ffffffffc0201b90:	b9bd                	j	ffffffffc020180e <slob_free>
        intr_disable();
ffffffffc0201b92:	a33fe0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201b96:	00015797          	auipc	a5,0x15
ffffffffc0201b9a:	9ca7b783          	ld	a5,-1590(a5) # ffffffffc0216560 <bigblocks>
        return 1;
ffffffffc0201b9e:	4605                	li	a2,1
ffffffffc0201ba0:	fbad                	bnez	a5,ffffffffc0201b12 <kfree+0x26>
        intr_enable();
ffffffffc0201ba2:	a1dfe0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0201ba6:	bff1                	j	ffffffffc0201b82 <kfree+0x96>
ffffffffc0201ba8:	a17fe0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0201bac:	b751                	j	ffffffffc0201b30 <kfree+0x44>
ffffffffc0201bae:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201bb0:	00004617          	auipc	a2,0x4
ffffffffc0201bb4:	f7860613          	addi	a2,a2,-136 # ffffffffc0205b28 <commands+0x950>
ffffffffc0201bb8:	06200593          	li	a1,98
ffffffffc0201bbc:	00004517          	auipc	a0,0x4
ffffffffc0201bc0:	f8c50513          	addi	a0,a0,-116 # ffffffffc0205b48 <commands+0x970>
ffffffffc0201bc4:	e04fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201bc8:	86a2                	mv	a3,s0
ffffffffc0201bca:	00004617          	auipc	a2,0x4
ffffffffc0201bce:	34e60613          	addi	a2,a2,846 # ffffffffc0205f18 <commands+0xd40>
ffffffffc0201bd2:	06e00593          	li	a1,110
ffffffffc0201bd6:	00004517          	auipc	a0,0x4
ffffffffc0201bda:	f7250513          	addi	a0,a0,-142 # ffffffffc0205b48 <commands+0x970>
ffffffffc0201bde:	deafe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0201be2 <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc0201be2:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201be4:	00004617          	auipc	a2,0x4
ffffffffc0201be8:	f4460613          	addi	a2,a2,-188 # ffffffffc0205b28 <commands+0x950>
ffffffffc0201bec:	06200593          	li	a1,98
ffffffffc0201bf0:	00004517          	auipc	a0,0x4
ffffffffc0201bf4:	f5850513          	addi	a0,a0,-168 # ffffffffc0205b48 <commands+0x970>
pa2page(uintptr_t pa) {
ffffffffc0201bf8:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201bfa:	dcefe0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0201bfe <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc0201bfe:	7135                	addi	sp,sp,-160
ffffffffc0201c00:	ed06                	sd	ra,152(sp)
ffffffffc0201c02:	e922                	sd	s0,144(sp)
ffffffffc0201c04:	e526                	sd	s1,136(sp)
ffffffffc0201c06:	e14a                	sd	s2,128(sp)
ffffffffc0201c08:	fcce                	sd	s3,120(sp)
ffffffffc0201c0a:	f8d2                	sd	s4,112(sp)
ffffffffc0201c0c:	f4d6                	sd	s5,104(sp)
ffffffffc0201c0e:	f0da                	sd	s6,96(sp)
ffffffffc0201c10:	ecde                	sd	s7,88(sp)
ffffffffc0201c12:	e8e2                	sd	s8,80(sp)
ffffffffc0201c14:	e4e6                	sd	s9,72(sp)
ffffffffc0201c16:	e0ea                	sd	s10,64(sp)
ffffffffc0201c18:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc0201c1a:	4c6020ef          	jal	ra,ffffffffc02040e0 <swapfs_init>
     // if (!(1024 <= max_swap_offset && max_swap_offset < MAX_SWAP_OFFSET_LIMIT))
     // {
     //      panic("bad max_swap_offset %08x.\n", max_swap_offset);
     // }
     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc0201c1e:	00015697          	auipc	a3,0x15
ffffffffc0201c22:	94a6b683          	ld	a3,-1718(a3) # ffffffffc0216568 <max_swap_offset>
ffffffffc0201c26:	010007b7          	lui	a5,0x1000
ffffffffc0201c2a:	ff968713          	addi	a4,a3,-7
ffffffffc0201c2e:	17e1                	addi	a5,a5,-8
ffffffffc0201c30:	42e7e063          	bltu	a5,a4,ffffffffc0202050 <swap_init+0x452>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }

     sm = &swap_manager_fifo;
ffffffffc0201c34:	00009797          	auipc	a5,0x9
ffffffffc0201c38:	3cc78793          	addi	a5,a5,972 # ffffffffc020b000 <swap_manager_fifo>
     int r = sm->init();
ffffffffc0201c3c:	6798                	ld	a4,8(a5)
     sm = &swap_manager_fifo;
ffffffffc0201c3e:	00015b97          	auipc	s7,0x15
ffffffffc0201c42:	932b8b93          	addi	s7,s7,-1742 # ffffffffc0216570 <sm>
ffffffffc0201c46:	00fbb023          	sd	a5,0(s7)
     int r = sm->init();
ffffffffc0201c4a:	9702                	jalr	a4
ffffffffc0201c4c:	892a                	mv	s2,a0
     
     if (r == 0)
ffffffffc0201c4e:	c10d                	beqz	a0,ffffffffc0201c70 <swap_init+0x72>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc0201c50:	60ea                	ld	ra,152(sp)
ffffffffc0201c52:	644a                	ld	s0,144(sp)
ffffffffc0201c54:	64aa                	ld	s1,136(sp)
ffffffffc0201c56:	79e6                	ld	s3,120(sp)
ffffffffc0201c58:	7a46                	ld	s4,112(sp)
ffffffffc0201c5a:	7aa6                	ld	s5,104(sp)
ffffffffc0201c5c:	7b06                	ld	s6,96(sp)
ffffffffc0201c5e:	6be6                	ld	s7,88(sp)
ffffffffc0201c60:	6c46                	ld	s8,80(sp)
ffffffffc0201c62:	6ca6                	ld	s9,72(sp)
ffffffffc0201c64:	6d06                	ld	s10,64(sp)
ffffffffc0201c66:	7de2                	ld	s11,56(sp)
ffffffffc0201c68:	854a                	mv	a0,s2
ffffffffc0201c6a:	690a                	ld	s2,128(sp)
ffffffffc0201c6c:	610d                	addi	sp,sp,160
ffffffffc0201c6e:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0201c70:	000bb783          	ld	a5,0(s7)
ffffffffc0201c74:	00004517          	auipc	a0,0x4
ffffffffc0201c78:	2fc50513          	addi	a0,a0,764 # ffffffffc0205f70 <commands+0xd98>
    return listelm->next;
ffffffffc0201c7c:	00011417          	auipc	s0,0x11
ffffffffc0201c80:	88440413          	addi	s0,s0,-1916 # ffffffffc0212500 <free_area>
ffffffffc0201c84:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc0201c86:	4785                	li	a5,1
ffffffffc0201c88:	00015717          	auipc	a4,0x15
ffffffffc0201c8c:	8ef72823          	sw	a5,-1808(a4) # ffffffffc0216578 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0201c90:	c3cfe0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0201c94:	641c                	ld	a5,8(s0)

static void
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
ffffffffc0201c96:	4d01                	li	s10,0
ffffffffc0201c98:	4d81                	li	s11,0
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0201c9a:	32878b63          	beq	a5,s0,ffffffffc0201fd0 <swap_init+0x3d2>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201c9e:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0201ca2:	8b09                	andi	a4,a4,2
ffffffffc0201ca4:	32070863          	beqz	a4,ffffffffc0201fd4 <swap_init+0x3d6>
        count ++, total += p->property;
ffffffffc0201ca8:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201cac:	679c                	ld	a5,8(a5)
ffffffffc0201cae:	2d85                	addiw	s11,s11,1
ffffffffc0201cb0:	01a70d3b          	addw	s10,a4,s10
     while ((le = list_next(le)) != &free_list) {
ffffffffc0201cb4:	fe8795e3          	bne	a5,s0,ffffffffc0201c9e <swap_init+0xa0>
     }
     assert(total == nr_free_pages());
ffffffffc0201cb8:	84ea                	mv	s1,s10
ffffffffc0201cba:	3dc010ef          	jal	ra,ffffffffc0203096 <nr_free_pages>
ffffffffc0201cbe:	42951163          	bne	a0,s1,ffffffffc02020e0 <swap_init+0x4e2>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0201cc2:	866a                	mv	a2,s10
ffffffffc0201cc4:	85ee                	mv	a1,s11
ffffffffc0201cc6:	00004517          	auipc	a0,0x4
ffffffffc0201cca:	2f250513          	addi	a0,a0,754 # ffffffffc0205fb8 <commands+0xde0>
ffffffffc0201cce:	bfefe0ef          	jal	ra,ffffffffc02000cc <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc0201cd2:	ec5fe0ef          	jal	ra,ffffffffc0200b96 <mm_create>
ffffffffc0201cd6:	8aaa                	mv	s5,a0
     assert(mm != NULL);
ffffffffc0201cd8:	46050463          	beqz	a0,ffffffffc0202140 <swap_init+0x542>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc0201cdc:	00015797          	auipc	a5,0x15
ffffffffc0201ce0:	87478793          	addi	a5,a5,-1932 # ffffffffc0216550 <check_mm_struct>
ffffffffc0201ce4:	6398                	ld	a4,0(a5)
ffffffffc0201ce6:	3c071d63          	bnez	a4,ffffffffc02020c0 <swap_init+0x4c2>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0201cea:	00015717          	auipc	a4,0x15
ffffffffc0201cee:	89e70713          	addi	a4,a4,-1890 # ffffffffc0216588 <boot_pgdir>
ffffffffc0201cf2:	00073b03          	ld	s6,0(a4)
     check_mm_struct = mm;
ffffffffc0201cf6:	e388                	sd	a0,0(a5)
     assert(pgdir[0] == 0);
ffffffffc0201cf8:	000b3783          	ld	a5,0(s6)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0201cfc:	01653c23          	sd	s6,24(a0)
     assert(pgdir[0] == 0);
ffffffffc0201d00:	42079063          	bnez	a5,ffffffffc0202120 <swap_init+0x522>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0201d04:	6599                	lui	a1,0x6
ffffffffc0201d06:	460d                	li	a2,3
ffffffffc0201d08:	6505                	lui	a0,0x1
ffffffffc0201d0a:	ed5fe0ef          	jal	ra,ffffffffc0200bde <vma_create>
ffffffffc0201d0e:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0201d10:	52050463          	beqz	a0,ffffffffc0202238 <swap_init+0x63a>

     insert_vma_struct(mm, vma);
ffffffffc0201d14:	8556                	mv	a0,s5
ffffffffc0201d16:	f37fe0ef          	jal	ra,ffffffffc0200c4c <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc0201d1a:	00004517          	auipc	a0,0x4
ffffffffc0201d1e:	2de50513          	addi	a0,a0,734 # ffffffffc0205ff8 <commands+0xe20>
ffffffffc0201d22:	baafe0ef          	jal	ra,ffffffffc02000cc <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc0201d26:	018ab503          	ld	a0,24(s5)
ffffffffc0201d2a:	4605                	li	a2,1
ffffffffc0201d2c:	6585                	lui	a1,0x1
ffffffffc0201d2e:	3a2010ef          	jal	ra,ffffffffc02030d0 <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc0201d32:	4c050363          	beqz	a0,ffffffffc02021f8 <swap_init+0x5fa>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0201d36:	00004517          	auipc	a0,0x4
ffffffffc0201d3a:	31250513          	addi	a0,a0,786 # ffffffffc0206048 <commands+0xe70>
ffffffffc0201d3e:	00010497          	auipc	s1,0x10
ffffffffc0201d42:	75248493          	addi	s1,s1,1874 # ffffffffc0212490 <check_rp>
ffffffffc0201d46:	b86fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0201d4a:	00010997          	auipc	s3,0x10
ffffffffc0201d4e:	76698993          	addi	s3,s3,1894 # ffffffffc02124b0 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc0201d52:	8a26                	mv	s4,s1
          check_rp[i] = alloc_page();
ffffffffc0201d54:	4505                	li	a0,1
ffffffffc0201d56:	26e010ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc0201d5a:	00aa3023          	sd	a0,0(s4)
          assert(check_rp[i] != NULL );
ffffffffc0201d5e:	2c050963          	beqz	a0,ffffffffc0202030 <swap_init+0x432>
ffffffffc0201d62:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc0201d64:	8b89                	andi	a5,a5,2
ffffffffc0201d66:	32079d63          	bnez	a5,ffffffffc02020a0 <swap_init+0x4a2>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0201d6a:	0a21                	addi	s4,s4,8
ffffffffc0201d6c:	ff3a14e3          	bne	s4,s3,ffffffffc0201d54 <swap_init+0x156>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0201d70:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc0201d72:	00010a17          	auipc	s4,0x10
ffffffffc0201d76:	71ea0a13          	addi	s4,s4,1822 # ffffffffc0212490 <check_rp>
    elm->prev = elm->next = elm;
ffffffffc0201d7a:	e000                	sd	s0,0(s0)
     list_entry_t free_list_store = free_list;
ffffffffc0201d7c:	ec3e                	sd	a5,24(sp)
ffffffffc0201d7e:	641c                	ld	a5,8(s0)
ffffffffc0201d80:	e400                	sd	s0,8(s0)
ffffffffc0201d82:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc0201d84:	481c                	lw	a5,16(s0)
ffffffffc0201d86:	f43e                	sd	a5,40(sp)
     nr_free = 0;
ffffffffc0201d88:	00010797          	auipc	a5,0x10
ffffffffc0201d8c:	7807a423          	sw	zero,1928(a5) # ffffffffc0212510 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0201d90:	000a3503          	ld	a0,0(s4)
ffffffffc0201d94:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0201d96:	0a21                	addi	s4,s4,8
        free_pages(check_rp[i],1);
ffffffffc0201d98:	2be010ef          	jal	ra,ffffffffc0203056 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0201d9c:	ff3a1ae3          	bne	s4,s3,ffffffffc0201d90 <swap_init+0x192>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0201da0:	01042a03          	lw	s4,16(s0)
ffffffffc0201da4:	4791                	li	a5,4
ffffffffc0201da6:	42fa1963          	bne	s4,a5,ffffffffc02021d8 <swap_init+0x5da>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc0201daa:	00004517          	auipc	a0,0x4
ffffffffc0201dae:	32650513          	addi	a0,a0,806 # ffffffffc02060d0 <commands+0xef8>
ffffffffc0201db2:	b1afe0ef          	jal	ra,ffffffffc02000cc <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201db6:	6705                	lui	a4,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0201db8:	00014797          	auipc	a5,0x14
ffffffffc0201dbc:	7a07a023          	sw	zero,1952(a5) # ffffffffc0216558 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0201dc0:	4629                	li	a2,10
ffffffffc0201dc2:	00c70023          	sb	a2,0(a4) # 1000 <kern_entry-0xffffffffc01ff000>
     assert(pgfault_num==1);
ffffffffc0201dc6:	00014697          	auipc	a3,0x14
ffffffffc0201dca:	7926a683          	lw	a3,1938(a3) # ffffffffc0216558 <pgfault_num>
ffffffffc0201dce:	4585                	li	a1,1
ffffffffc0201dd0:	00014797          	auipc	a5,0x14
ffffffffc0201dd4:	78878793          	addi	a5,a5,1928 # ffffffffc0216558 <pgfault_num>
ffffffffc0201dd8:	54b69063          	bne	a3,a1,ffffffffc0202318 <swap_init+0x71a>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0201ddc:	00c70823          	sb	a2,16(a4)
     assert(pgfault_num==1);
ffffffffc0201de0:	4398                	lw	a4,0(a5)
ffffffffc0201de2:	2701                	sext.w	a4,a4
ffffffffc0201de4:	3cd71a63          	bne	a4,a3,ffffffffc02021b8 <swap_init+0x5ba>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0201de8:	6689                	lui	a3,0x2
ffffffffc0201dea:	462d                	li	a2,11
ffffffffc0201dec:	00c68023          	sb	a2,0(a3) # 2000 <kern_entry-0xffffffffc01fe000>
     assert(pgfault_num==2);
ffffffffc0201df0:	4398                	lw	a4,0(a5)
ffffffffc0201df2:	4589                	li	a1,2
ffffffffc0201df4:	2701                	sext.w	a4,a4
ffffffffc0201df6:	4ab71163          	bne	a4,a1,ffffffffc0202298 <swap_init+0x69a>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc0201dfa:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc0201dfe:	4394                	lw	a3,0(a5)
ffffffffc0201e00:	2681                	sext.w	a3,a3
ffffffffc0201e02:	4ae69b63          	bne	a3,a4,ffffffffc02022b8 <swap_init+0x6ba>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0201e06:	668d                	lui	a3,0x3
ffffffffc0201e08:	4631                	li	a2,12
ffffffffc0201e0a:	00c68023          	sb	a2,0(a3) # 3000 <kern_entry-0xffffffffc01fd000>
     assert(pgfault_num==3);
ffffffffc0201e0e:	4398                	lw	a4,0(a5)
ffffffffc0201e10:	458d                	li	a1,3
ffffffffc0201e12:	2701                	sext.w	a4,a4
ffffffffc0201e14:	4cb71263          	bne	a4,a1,ffffffffc02022d8 <swap_init+0x6da>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc0201e18:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc0201e1c:	4394                	lw	a3,0(a5)
ffffffffc0201e1e:	2681                	sext.w	a3,a3
ffffffffc0201e20:	4ce69c63          	bne	a3,a4,ffffffffc02022f8 <swap_init+0x6fa>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0201e24:	6691                	lui	a3,0x4
ffffffffc0201e26:	4635                	li	a2,13
ffffffffc0201e28:	00c68023          	sb	a2,0(a3) # 4000 <kern_entry-0xffffffffc01fc000>
     assert(pgfault_num==4);
ffffffffc0201e2c:	4398                	lw	a4,0(a5)
ffffffffc0201e2e:	2701                	sext.w	a4,a4
ffffffffc0201e30:	43471463          	bne	a4,s4,ffffffffc0202258 <swap_init+0x65a>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0201e34:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc0201e38:	439c                	lw	a5,0(a5)
ffffffffc0201e3a:	2781                	sext.w	a5,a5
ffffffffc0201e3c:	42e79e63          	bne	a5,a4,ffffffffc0202278 <swap_init+0x67a>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0201e40:	481c                	lw	a5,16(s0)
ffffffffc0201e42:	2a079f63          	bnez	a5,ffffffffc0202100 <swap_init+0x502>
ffffffffc0201e46:	00010797          	auipc	a5,0x10
ffffffffc0201e4a:	66a78793          	addi	a5,a5,1642 # ffffffffc02124b0 <swap_in_seq_no>
ffffffffc0201e4e:	00010717          	auipc	a4,0x10
ffffffffc0201e52:	68a70713          	addi	a4,a4,1674 # ffffffffc02124d8 <swap_out_seq_no>
ffffffffc0201e56:	00010617          	auipc	a2,0x10
ffffffffc0201e5a:	68260613          	addi	a2,a2,1666 # ffffffffc02124d8 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc0201e5e:	56fd                	li	a3,-1
ffffffffc0201e60:	c394                	sw	a3,0(a5)
ffffffffc0201e62:	c314                	sw	a3,0(a4)
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0201e64:	0791                	addi	a5,a5,4
ffffffffc0201e66:	0711                	addi	a4,a4,4
ffffffffc0201e68:	fec79ce3          	bne	a5,a2,ffffffffc0201e60 <swap_init+0x262>
ffffffffc0201e6c:	00010717          	auipc	a4,0x10
ffffffffc0201e70:	60470713          	addi	a4,a4,1540 # ffffffffc0212470 <check_ptep>
ffffffffc0201e74:	00010697          	auipc	a3,0x10
ffffffffc0201e78:	61c68693          	addi	a3,a3,1564 # ffffffffc0212490 <check_rp>
ffffffffc0201e7c:	6585                	lui	a1,0x1
    if (PPN(pa) >= npage) {
ffffffffc0201e7e:	00014c17          	auipc	s8,0x14
ffffffffc0201e82:	712c0c13          	addi	s8,s8,1810 # ffffffffc0216590 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0201e86:	00014c97          	auipc	s9,0x14
ffffffffc0201e8a:	712c8c93          	addi	s9,s9,1810 # ffffffffc0216598 <pages>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc0201e8e:	00073023          	sd	zero,0(a4)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0201e92:	4601                	li	a2,0
ffffffffc0201e94:	855a                	mv	a0,s6
ffffffffc0201e96:	e836                	sd	a3,16(sp)
ffffffffc0201e98:	e42e                	sd	a1,8(sp)
         check_ptep[i]=0;
ffffffffc0201e9a:	e03a                	sd	a4,0(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0201e9c:	234010ef          	jal	ra,ffffffffc02030d0 <get_pte>
ffffffffc0201ea0:	6702                	ld	a4,0(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc0201ea2:	65a2                	ld	a1,8(sp)
ffffffffc0201ea4:	66c2                	ld	a3,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0201ea6:	e308                	sd	a0,0(a4)
         assert(check_ptep[i] != NULL);
ffffffffc0201ea8:	1c050063          	beqz	a0,ffffffffc0202068 <swap_init+0x46a>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0201eac:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0201eae:	0017f613          	andi	a2,a5,1
ffffffffc0201eb2:	1c060b63          	beqz	a2,ffffffffc0202088 <swap_init+0x48a>
    if (PPN(pa) >= npage) {
ffffffffc0201eb6:	000c3603          	ld	a2,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0201eba:	078a                	slli	a5,a5,0x2
ffffffffc0201ebc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201ebe:	12c7fd63          	bgeu	a5,a2,ffffffffc0201ff8 <swap_init+0x3fa>
    return &pages[PPN(pa) - nbase];
ffffffffc0201ec2:	00005617          	auipc	a2,0x5
ffffffffc0201ec6:	17e60613          	addi	a2,a2,382 # ffffffffc0207040 <nbase>
ffffffffc0201eca:	00063a03          	ld	s4,0(a2)
ffffffffc0201ece:	000cb603          	ld	a2,0(s9)
ffffffffc0201ed2:	6288                	ld	a0,0(a3)
ffffffffc0201ed4:	414787b3          	sub	a5,a5,s4
ffffffffc0201ed8:	079a                	slli	a5,a5,0x6
ffffffffc0201eda:	97b2                	add	a5,a5,a2
ffffffffc0201edc:	12f51a63          	bne	a0,a5,ffffffffc0202010 <swap_init+0x412>
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0201ee0:	6785                	lui	a5,0x1
ffffffffc0201ee2:	95be                	add	a1,a1,a5
ffffffffc0201ee4:	6795                	lui	a5,0x5
ffffffffc0201ee6:	0721                	addi	a4,a4,8
ffffffffc0201ee8:	06a1                	addi	a3,a3,8
ffffffffc0201eea:	faf592e3          	bne	a1,a5,ffffffffc0201e8e <swap_init+0x290>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc0201eee:	00004517          	auipc	a0,0x4
ffffffffc0201ef2:	2b250513          	addi	a0,a0,690 # ffffffffc02061a0 <commands+0xfc8>
ffffffffc0201ef6:	9d6fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    int ret = sm->check_swap();
ffffffffc0201efa:	000bb783          	ld	a5,0(s7)
ffffffffc0201efe:	7f9c                	ld	a5,56(a5)
ffffffffc0201f00:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc0201f02:	30051b63          	bnez	a0,ffffffffc0202218 <swap_init+0x61a>

     nr_free = nr_free_store;
ffffffffc0201f06:	77a2                	ld	a5,40(sp)
ffffffffc0201f08:	c81c                	sw	a5,16(s0)
     free_list = free_list_store;
ffffffffc0201f0a:	67e2                	ld	a5,24(sp)
ffffffffc0201f0c:	e01c                	sd	a5,0(s0)
ffffffffc0201f0e:	7782                	ld	a5,32(sp)
ffffffffc0201f10:	e41c                	sd	a5,8(s0)

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc0201f12:	6088                	ld	a0,0(s1)
ffffffffc0201f14:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0201f16:	04a1                	addi	s1,s1,8
         free_pages(check_rp[i],1);
ffffffffc0201f18:	13e010ef          	jal	ra,ffffffffc0203056 <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0201f1c:	ff349be3          	bne	s1,s3,ffffffffc0201f12 <swap_init+0x314>
     } 

     //free_page(pte2page(*temp_ptep));
     
     mm_destroy(mm);
ffffffffc0201f20:	8556                	mv	a0,s5
ffffffffc0201f22:	dfbfe0ef          	jal	ra,ffffffffc0200d1c <mm_destroy>

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0201f26:	00014797          	auipc	a5,0x14
ffffffffc0201f2a:	66278793          	addi	a5,a5,1634 # ffffffffc0216588 <boot_pgdir>
ffffffffc0201f2e:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0201f30:	000c3703          	ld	a4,0(s8)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201f34:	639c                	ld	a5,0(a5)
ffffffffc0201f36:	078a                	slli	a5,a5,0x2
ffffffffc0201f38:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201f3a:	0ae7fd63          	bgeu	a5,a4,ffffffffc0201ff4 <swap_init+0x3f6>
    return &pages[PPN(pa) - nbase];
ffffffffc0201f3e:	414786b3          	sub	a3,a5,s4
ffffffffc0201f42:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc0201f44:	8699                	srai	a3,a3,0x6
ffffffffc0201f46:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc0201f48:	00c69793          	slli	a5,a3,0xc
ffffffffc0201f4c:	83b1                	srli	a5,a5,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0201f4e:	000cb503          	ld	a0,0(s9)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201f52:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201f54:	22e7f663          	bgeu	a5,a4,ffffffffc0202180 <swap_init+0x582>
     free_page(pde2page(pd0[0]));
ffffffffc0201f58:	00014797          	auipc	a5,0x14
ffffffffc0201f5c:	6507b783          	ld	a5,1616(a5) # ffffffffc02165a8 <va_pa_offset>
ffffffffc0201f60:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0201f62:	629c                	ld	a5,0(a3)
ffffffffc0201f64:	078a                	slli	a5,a5,0x2
ffffffffc0201f66:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201f68:	08e7f663          	bgeu	a5,a4,ffffffffc0201ff4 <swap_init+0x3f6>
    return &pages[PPN(pa) - nbase];
ffffffffc0201f6c:	414787b3          	sub	a5,a5,s4
ffffffffc0201f70:	079a                	slli	a5,a5,0x6
ffffffffc0201f72:	953e                	add	a0,a0,a5
ffffffffc0201f74:	4585                	li	a1,1
ffffffffc0201f76:	0e0010ef          	jal	ra,ffffffffc0203056 <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0201f7a:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc0201f7e:	000c3703          	ld	a4,0(s8)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201f82:	078a                	slli	a5,a5,0x2
ffffffffc0201f84:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201f86:	06e7f763          	bgeu	a5,a4,ffffffffc0201ff4 <swap_init+0x3f6>
    return &pages[PPN(pa) - nbase];
ffffffffc0201f8a:	000cb503          	ld	a0,0(s9)
ffffffffc0201f8e:	414787b3          	sub	a5,a5,s4
ffffffffc0201f92:	079a                	slli	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc0201f94:	4585                	li	a1,1
ffffffffc0201f96:	953e                	add	a0,a0,a5
ffffffffc0201f98:	0be010ef          	jal	ra,ffffffffc0203056 <free_pages>
     pgdir[0] = 0;
ffffffffc0201f9c:	000b3023          	sd	zero,0(s6)
  asm volatile("sfence.vma");
ffffffffc0201fa0:	12000073          	sfence.vma
    return listelm->next;
ffffffffc0201fa4:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0201fa6:	00878a63          	beq	a5,s0,ffffffffc0201fba <swap_init+0x3bc>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0201faa:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201fae:	679c                	ld	a5,8(a5)
ffffffffc0201fb0:	3dfd                	addiw	s11,s11,-1
ffffffffc0201fb2:	40ed0d3b          	subw	s10,s10,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0201fb6:	fe879ae3          	bne	a5,s0,ffffffffc0201faa <swap_init+0x3ac>
     }
     assert(count==0);
ffffffffc0201fba:	1c0d9f63          	bnez	s11,ffffffffc0202198 <swap_init+0x59a>
     assert(total==0);
ffffffffc0201fbe:	1a0d1163          	bnez	s10,ffffffffc0202160 <swap_init+0x562>

     cprintf("check_swap() succeeded!\n");
ffffffffc0201fc2:	00004517          	auipc	a0,0x4
ffffffffc0201fc6:	22e50513          	addi	a0,a0,558 # ffffffffc02061f0 <commands+0x1018>
ffffffffc0201fca:	902fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc0201fce:	b149                	j	ffffffffc0201c50 <swap_init+0x52>
     while ((le = list_next(le)) != &free_list) {
ffffffffc0201fd0:	4481                	li	s1,0
ffffffffc0201fd2:	b1e5                	j	ffffffffc0201cba <swap_init+0xbc>
        assert(PageProperty(p));
ffffffffc0201fd4:	00004697          	auipc	a3,0x4
ffffffffc0201fd8:	fb468693          	addi	a3,a3,-76 # ffffffffc0205f88 <commands+0xdb0>
ffffffffc0201fdc:	00004617          	auipc	a2,0x4
ffffffffc0201fe0:	92460613          	addi	a2,a2,-1756 # ffffffffc0205900 <commands+0x728>
ffffffffc0201fe4:	0bd00593          	li	a1,189
ffffffffc0201fe8:	00004517          	auipc	a0,0x4
ffffffffc0201fec:	f7850513          	addi	a0,a0,-136 # ffffffffc0205f60 <commands+0xd88>
ffffffffc0201ff0:	9d8fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
ffffffffc0201ff4:	befff0ef          	jal	ra,ffffffffc0201be2 <pa2page.part.0>
        panic("pa2page called with invalid pa");
ffffffffc0201ff8:	00004617          	auipc	a2,0x4
ffffffffc0201ffc:	b3060613          	addi	a2,a2,-1232 # ffffffffc0205b28 <commands+0x950>
ffffffffc0202000:	06200593          	li	a1,98
ffffffffc0202004:	00004517          	auipc	a0,0x4
ffffffffc0202008:	b4450513          	addi	a0,a0,-1212 # ffffffffc0205b48 <commands+0x970>
ffffffffc020200c:	9bcfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202010:	00004697          	auipc	a3,0x4
ffffffffc0202014:	16868693          	addi	a3,a3,360 # ffffffffc0206178 <commands+0xfa0>
ffffffffc0202018:	00004617          	auipc	a2,0x4
ffffffffc020201c:	8e860613          	addi	a2,a2,-1816 # ffffffffc0205900 <commands+0x728>
ffffffffc0202020:	0fd00593          	li	a1,253
ffffffffc0202024:	00004517          	auipc	a0,0x4
ffffffffc0202028:	f3c50513          	addi	a0,a0,-196 # ffffffffc0205f60 <commands+0xd88>
ffffffffc020202c:	99cfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc0202030:	00004697          	auipc	a3,0x4
ffffffffc0202034:	04068693          	addi	a3,a3,64 # ffffffffc0206070 <commands+0xe98>
ffffffffc0202038:	00004617          	auipc	a2,0x4
ffffffffc020203c:	8c860613          	addi	a2,a2,-1848 # ffffffffc0205900 <commands+0x728>
ffffffffc0202040:	0dd00593          	li	a1,221
ffffffffc0202044:	00004517          	auipc	a0,0x4
ffffffffc0202048:	f1c50513          	addi	a0,a0,-228 # ffffffffc0205f60 <commands+0xd88>
ffffffffc020204c:	97cfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0202050:	00004617          	auipc	a2,0x4
ffffffffc0202054:	ef060613          	addi	a2,a2,-272 # ffffffffc0205f40 <commands+0xd68>
ffffffffc0202058:	02a00593          	li	a1,42
ffffffffc020205c:	00004517          	auipc	a0,0x4
ffffffffc0202060:	f0450513          	addi	a0,a0,-252 # ffffffffc0205f60 <commands+0xd88>
ffffffffc0202064:	964fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc0202068:	00004697          	auipc	a3,0x4
ffffffffc020206c:	0d068693          	addi	a3,a3,208 # ffffffffc0206138 <commands+0xf60>
ffffffffc0202070:	00004617          	auipc	a2,0x4
ffffffffc0202074:	89060613          	addi	a2,a2,-1904 # ffffffffc0205900 <commands+0x728>
ffffffffc0202078:	0fc00593          	li	a1,252
ffffffffc020207c:	00004517          	auipc	a0,0x4
ffffffffc0202080:	ee450513          	addi	a0,a0,-284 # ffffffffc0205f60 <commands+0xd88>
ffffffffc0202084:	944fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202088:	00004617          	auipc	a2,0x4
ffffffffc020208c:	0c860613          	addi	a2,a2,200 # ffffffffc0206150 <commands+0xf78>
ffffffffc0202090:	07400593          	li	a1,116
ffffffffc0202094:	00004517          	auipc	a0,0x4
ffffffffc0202098:	ab450513          	addi	a0,a0,-1356 # ffffffffc0205b48 <commands+0x970>
ffffffffc020209c:	92cfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc02020a0:	00004697          	auipc	a3,0x4
ffffffffc02020a4:	fe868693          	addi	a3,a3,-24 # ffffffffc0206088 <commands+0xeb0>
ffffffffc02020a8:	00004617          	auipc	a2,0x4
ffffffffc02020ac:	85860613          	addi	a2,a2,-1960 # ffffffffc0205900 <commands+0x728>
ffffffffc02020b0:	0de00593          	li	a1,222
ffffffffc02020b4:	00004517          	auipc	a0,0x4
ffffffffc02020b8:	eac50513          	addi	a0,a0,-340 # ffffffffc0205f60 <commands+0xd88>
ffffffffc02020bc:	90cfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc02020c0:	00004697          	auipc	a3,0x4
ffffffffc02020c4:	f2068693          	addi	a3,a3,-224 # ffffffffc0205fe0 <commands+0xe08>
ffffffffc02020c8:	00004617          	auipc	a2,0x4
ffffffffc02020cc:	83860613          	addi	a2,a2,-1992 # ffffffffc0205900 <commands+0x728>
ffffffffc02020d0:	0c800593          	li	a1,200
ffffffffc02020d4:	00004517          	auipc	a0,0x4
ffffffffc02020d8:	e8c50513          	addi	a0,a0,-372 # ffffffffc0205f60 <commands+0xd88>
ffffffffc02020dc:	8ecfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(total == nr_free_pages());
ffffffffc02020e0:	00004697          	auipc	a3,0x4
ffffffffc02020e4:	eb868693          	addi	a3,a3,-328 # ffffffffc0205f98 <commands+0xdc0>
ffffffffc02020e8:	00004617          	auipc	a2,0x4
ffffffffc02020ec:	81860613          	addi	a2,a2,-2024 # ffffffffc0205900 <commands+0x728>
ffffffffc02020f0:	0c000593          	li	a1,192
ffffffffc02020f4:	00004517          	auipc	a0,0x4
ffffffffc02020f8:	e6c50513          	addi	a0,a0,-404 # ffffffffc0205f60 <commands+0xd88>
ffffffffc02020fc:	8ccfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert( nr_free == 0);         
ffffffffc0202100:	00004697          	auipc	a3,0x4
ffffffffc0202104:	02868693          	addi	a3,a3,40 # ffffffffc0206128 <commands+0xf50>
ffffffffc0202108:	00003617          	auipc	a2,0x3
ffffffffc020210c:	7f860613          	addi	a2,a2,2040 # ffffffffc0205900 <commands+0x728>
ffffffffc0202110:	0f400593          	li	a1,244
ffffffffc0202114:	00004517          	auipc	a0,0x4
ffffffffc0202118:	e4c50513          	addi	a0,a0,-436 # ffffffffc0205f60 <commands+0xd88>
ffffffffc020211c:	8acfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0202120:	00004697          	auipc	a3,0x4
ffffffffc0202124:	9c868693          	addi	a3,a3,-1592 # ffffffffc0205ae8 <commands+0x910>
ffffffffc0202128:	00003617          	auipc	a2,0x3
ffffffffc020212c:	7d860613          	addi	a2,a2,2008 # ffffffffc0205900 <commands+0x728>
ffffffffc0202130:	0cd00593          	li	a1,205
ffffffffc0202134:	00004517          	auipc	a0,0x4
ffffffffc0202138:	e2c50513          	addi	a0,a0,-468 # ffffffffc0205f60 <commands+0xd88>
ffffffffc020213c:	88cfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(mm != NULL);
ffffffffc0202140:	00004697          	auipc	a3,0x4
ffffffffc0202144:	ac868693          	addi	a3,a3,-1336 # ffffffffc0205c08 <commands+0xa30>
ffffffffc0202148:	00003617          	auipc	a2,0x3
ffffffffc020214c:	7b860613          	addi	a2,a2,1976 # ffffffffc0205900 <commands+0x728>
ffffffffc0202150:	0c500593          	li	a1,197
ffffffffc0202154:	00004517          	auipc	a0,0x4
ffffffffc0202158:	e0c50513          	addi	a0,a0,-500 # ffffffffc0205f60 <commands+0xd88>
ffffffffc020215c:	86cfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(total==0);
ffffffffc0202160:	00004697          	auipc	a3,0x4
ffffffffc0202164:	08068693          	addi	a3,a3,128 # ffffffffc02061e0 <commands+0x1008>
ffffffffc0202168:	00003617          	auipc	a2,0x3
ffffffffc020216c:	79860613          	addi	a2,a2,1944 # ffffffffc0205900 <commands+0x728>
ffffffffc0202170:	11d00593          	li	a1,285
ffffffffc0202174:	00004517          	auipc	a0,0x4
ffffffffc0202178:	dec50513          	addi	a0,a0,-532 # ffffffffc0205f60 <commands+0xd88>
ffffffffc020217c:	84cfe0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202180:	00004617          	auipc	a2,0x4
ffffffffc0202184:	9d860613          	addi	a2,a2,-1576 # ffffffffc0205b58 <commands+0x980>
ffffffffc0202188:	06900593          	li	a1,105
ffffffffc020218c:	00004517          	auipc	a0,0x4
ffffffffc0202190:	9bc50513          	addi	a0,a0,-1604 # ffffffffc0205b48 <commands+0x970>
ffffffffc0202194:	834fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(count==0);
ffffffffc0202198:	00004697          	auipc	a3,0x4
ffffffffc020219c:	03868693          	addi	a3,a3,56 # ffffffffc02061d0 <commands+0xff8>
ffffffffc02021a0:	00003617          	auipc	a2,0x3
ffffffffc02021a4:	76060613          	addi	a2,a2,1888 # ffffffffc0205900 <commands+0x728>
ffffffffc02021a8:	11c00593          	li	a1,284
ffffffffc02021ac:	00004517          	auipc	a0,0x4
ffffffffc02021b0:	db450513          	addi	a0,a0,-588 # ffffffffc0205f60 <commands+0xd88>
ffffffffc02021b4:	814fe0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==1);
ffffffffc02021b8:	00004697          	auipc	a3,0x4
ffffffffc02021bc:	f4068693          	addi	a3,a3,-192 # ffffffffc02060f8 <commands+0xf20>
ffffffffc02021c0:	00003617          	auipc	a2,0x3
ffffffffc02021c4:	74060613          	addi	a2,a2,1856 # ffffffffc0205900 <commands+0x728>
ffffffffc02021c8:	09600593          	li	a1,150
ffffffffc02021cc:	00004517          	auipc	a0,0x4
ffffffffc02021d0:	d9450513          	addi	a0,a0,-620 # ffffffffc0205f60 <commands+0xd88>
ffffffffc02021d4:	ff5fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc02021d8:	00004697          	auipc	a3,0x4
ffffffffc02021dc:	ed068693          	addi	a3,a3,-304 # ffffffffc02060a8 <commands+0xed0>
ffffffffc02021e0:	00003617          	auipc	a2,0x3
ffffffffc02021e4:	72060613          	addi	a2,a2,1824 # ffffffffc0205900 <commands+0x728>
ffffffffc02021e8:	0eb00593          	li	a1,235
ffffffffc02021ec:	00004517          	auipc	a0,0x4
ffffffffc02021f0:	d7450513          	addi	a0,a0,-652 # ffffffffc0205f60 <commands+0xd88>
ffffffffc02021f4:	fd5fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc02021f8:	00004697          	auipc	a3,0x4
ffffffffc02021fc:	e3868693          	addi	a3,a3,-456 # ffffffffc0206030 <commands+0xe58>
ffffffffc0202200:	00003617          	auipc	a2,0x3
ffffffffc0202204:	70060613          	addi	a2,a2,1792 # ffffffffc0205900 <commands+0x728>
ffffffffc0202208:	0d800593          	li	a1,216
ffffffffc020220c:	00004517          	auipc	a0,0x4
ffffffffc0202210:	d5450513          	addi	a0,a0,-684 # ffffffffc0205f60 <commands+0xd88>
ffffffffc0202214:	fb5fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(ret==0);
ffffffffc0202218:	00004697          	auipc	a3,0x4
ffffffffc020221c:	fb068693          	addi	a3,a3,-80 # ffffffffc02061c8 <commands+0xff0>
ffffffffc0202220:	00003617          	auipc	a2,0x3
ffffffffc0202224:	6e060613          	addi	a2,a2,1760 # ffffffffc0205900 <commands+0x728>
ffffffffc0202228:	10300593          	li	a1,259
ffffffffc020222c:	00004517          	auipc	a0,0x4
ffffffffc0202230:	d3450513          	addi	a0,a0,-716 # ffffffffc0205f60 <commands+0xd88>
ffffffffc0202234:	f95fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(vma != NULL);
ffffffffc0202238:	00004697          	auipc	a3,0x4
ffffffffc020223c:	9a868693          	addi	a3,a3,-1624 # ffffffffc0205be0 <commands+0xa08>
ffffffffc0202240:	00003617          	auipc	a2,0x3
ffffffffc0202244:	6c060613          	addi	a2,a2,1728 # ffffffffc0205900 <commands+0x728>
ffffffffc0202248:	0d000593          	li	a1,208
ffffffffc020224c:	00004517          	auipc	a0,0x4
ffffffffc0202250:	d1450513          	addi	a0,a0,-748 # ffffffffc0205f60 <commands+0xd88>
ffffffffc0202254:	f75fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==4);
ffffffffc0202258:	00004697          	auipc	a3,0x4
ffffffffc020225c:	a9868693          	addi	a3,a3,-1384 # ffffffffc0205cf0 <commands+0xb18>
ffffffffc0202260:	00003617          	auipc	a2,0x3
ffffffffc0202264:	6a060613          	addi	a2,a2,1696 # ffffffffc0205900 <commands+0x728>
ffffffffc0202268:	0a000593          	li	a1,160
ffffffffc020226c:	00004517          	auipc	a0,0x4
ffffffffc0202270:	cf450513          	addi	a0,a0,-780 # ffffffffc0205f60 <commands+0xd88>
ffffffffc0202274:	f55fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==4);
ffffffffc0202278:	00004697          	auipc	a3,0x4
ffffffffc020227c:	a7868693          	addi	a3,a3,-1416 # ffffffffc0205cf0 <commands+0xb18>
ffffffffc0202280:	00003617          	auipc	a2,0x3
ffffffffc0202284:	68060613          	addi	a2,a2,1664 # ffffffffc0205900 <commands+0x728>
ffffffffc0202288:	0a200593          	li	a1,162
ffffffffc020228c:	00004517          	auipc	a0,0x4
ffffffffc0202290:	cd450513          	addi	a0,a0,-812 # ffffffffc0205f60 <commands+0xd88>
ffffffffc0202294:	f35fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==2);
ffffffffc0202298:	00004697          	auipc	a3,0x4
ffffffffc020229c:	e7068693          	addi	a3,a3,-400 # ffffffffc0206108 <commands+0xf30>
ffffffffc02022a0:	00003617          	auipc	a2,0x3
ffffffffc02022a4:	66060613          	addi	a2,a2,1632 # ffffffffc0205900 <commands+0x728>
ffffffffc02022a8:	09800593          	li	a1,152
ffffffffc02022ac:	00004517          	auipc	a0,0x4
ffffffffc02022b0:	cb450513          	addi	a0,a0,-844 # ffffffffc0205f60 <commands+0xd88>
ffffffffc02022b4:	f15fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==2);
ffffffffc02022b8:	00004697          	auipc	a3,0x4
ffffffffc02022bc:	e5068693          	addi	a3,a3,-432 # ffffffffc0206108 <commands+0xf30>
ffffffffc02022c0:	00003617          	auipc	a2,0x3
ffffffffc02022c4:	64060613          	addi	a2,a2,1600 # ffffffffc0205900 <commands+0x728>
ffffffffc02022c8:	09a00593          	li	a1,154
ffffffffc02022cc:	00004517          	auipc	a0,0x4
ffffffffc02022d0:	c9450513          	addi	a0,a0,-876 # ffffffffc0205f60 <commands+0xd88>
ffffffffc02022d4:	ef5fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==3);
ffffffffc02022d8:	00004697          	auipc	a3,0x4
ffffffffc02022dc:	e4068693          	addi	a3,a3,-448 # ffffffffc0206118 <commands+0xf40>
ffffffffc02022e0:	00003617          	auipc	a2,0x3
ffffffffc02022e4:	62060613          	addi	a2,a2,1568 # ffffffffc0205900 <commands+0x728>
ffffffffc02022e8:	09c00593          	li	a1,156
ffffffffc02022ec:	00004517          	auipc	a0,0x4
ffffffffc02022f0:	c7450513          	addi	a0,a0,-908 # ffffffffc0205f60 <commands+0xd88>
ffffffffc02022f4:	ed5fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==3);
ffffffffc02022f8:	00004697          	auipc	a3,0x4
ffffffffc02022fc:	e2068693          	addi	a3,a3,-480 # ffffffffc0206118 <commands+0xf40>
ffffffffc0202300:	00003617          	auipc	a2,0x3
ffffffffc0202304:	60060613          	addi	a2,a2,1536 # ffffffffc0205900 <commands+0x728>
ffffffffc0202308:	09e00593          	li	a1,158
ffffffffc020230c:	00004517          	auipc	a0,0x4
ffffffffc0202310:	c5450513          	addi	a0,a0,-940 # ffffffffc0205f60 <commands+0xd88>
ffffffffc0202314:	eb5fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
     assert(pgfault_num==1);
ffffffffc0202318:	00004697          	auipc	a3,0x4
ffffffffc020231c:	de068693          	addi	a3,a3,-544 # ffffffffc02060f8 <commands+0xf20>
ffffffffc0202320:	00003617          	auipc	a2,0x3
ffffffffc0202324:	5e060613          	addi	a2,a2,1504 # ffffffffc0205900 <commands+0x728>
ffffffffc0202328:	09400593          	li	a1,148
ffffffffc020232c:	00004517          	auipc	a0,0x4
ffffffffc0202330:	c3450513          	addi	a0,a0,-972 # ffffffffc0205f60 <commands+0xd88>
ffffffffc0202334:	e95fd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202338 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0202338:	00014797          	auipc	a5,0x14
ffffffffc020233c:	2387b783          	ld	a5,568(a5) # ffffffffc0216570 <sm>
ffffffffc0202340:	6b9c                	ld	a5,16(a5)
ffffffffc0202342:	8782                	jr	a5

ffffffffc0202344 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0202344:	00014797          	auipc	a5,0x14
ffffffffc0202348:	22c7b783          	ld	a5,556(a5) # ffffffffc0216570 <sm>
ffffffffc020234c:	739c                	ld	a5,32(a5)
ffffffffc020234e:	8782                	jr	a5

ffffffffc0202350 <swap_out>:
{
ffffffffc0202350:	711d                	addi	sp,sp,-96
ffffffffc0202352:	ec86                	sd	ra,88(sp)
ffffffffc0202354:	e8a2                	sd	s0,80(sp)
ffffffffc0202356:	e4a6                	sd	s1,72(sp)
ffffffffc0202358:	e0ca                	sd	s2,64(sp)
ffffffffc020235a:	fc4e                	sd	s3,56(sp)
ffffffffc020235c:	f852                	sd	s4,48(sp)
ffffffffc020235e:	f456                	sd	s5,40(sp)
ffffffffc0202360:	f05a                	sd	s6,32(sp)
ffffffffc0202362:	ec5e                	sd	s7,24(sp)
ffffffffc0202364:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc0202366:	cde9                	beqz	a1,ffffffffc0202440 <swap_out+0xf0>
ffffffffc0202368:	8a2e                	mv	s4,a1
ffffffffc020236a:	892a                	mv	s2,a0
ffffffffc020236c:	8ab2                	mv	s5,a2
ffffffffc020236e:	4401                	li	s0,0
ffffffffc0202370:	00014997          	auipc	s3,0x14
ffffffffc0202374:	20098993          	addi	s3,s3,512 # ffffffffc0216570 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0202378:	00004b17          	auipc	s6,0x4
ffffffffc020237c:	ef8b0b13          	addi	s6,s6,-264 # ffffffffc0206270 <commands+0x1098>
                    cprintf("SWAP: failed to save\n");
ffffffffc0202380:	00004b97          	auipc	s7,0x4
ffffffffc0202384:	ed8b8b93          	addi	s7,s7,-296 # ffffffffc0206258 <commands+0x1080>
ffffffffc0202388:	a825                	j	ffffffffc02023c0 <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc020238a:	67a2                	ld	a5,8(sp)
ffffffffc020238c:	8626                	mv	a2,s1
ffffffffc020238e:	85a2                	mv	a1,s0
ffffffffc0202390:	7f94                	ld	a3,56(a5)
ffffffffc0202392:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0202394:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0202396:	82b1                	srli	a3,a3,0xc
ffffffffc0202398:	0685                	addi	a3,a3,1
ffffffffc020239a:	d33fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc020239e:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc02023a0:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc02023a2:	7d1c                	ld	a5,56(a0)
ffffffffc02023a4:	83b1                	srli	a5,a5,0xc
ffffffffc02023a6:	0785                	addi	a5,a5,1
ffffffffc02023a8:	07a2                	slli	a5,a5,0x8
ffffffffc02023aa:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc02023ae:	4a9000ef          	jal	ra,ffffffffc0203056 <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc02023b2:	01893503          	ld	a0,24(s2)
ffffffffc02023b6:	85a6                	mv	a1,s1
ffffffffc02023b8:	46b010ef          	jal	ra,ffffffffc0204022 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc02023bc:	048a0d63          	beq	s4,s0,ffffffffc0202416 <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc02023c0:	0009b783          	ld	a5,0(s3)
ffffffffc02023c4:	8656                	mv	a2,s5
ffffffffc02023c6:	002c                	addi	a1,sp,8
ffffffffc02023c8:	7b9c                	ld	a5,48(a5)
ffffffffc02023ca:	854a                	mv	a0,s2
ffffffffc02023cc:	9782                	jalr	a5
          if (r != 0) {
ffffffffc02023ce:	e12d                	bnez	a0,ffffffffc0202430 <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc02023d0:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02023d2:	01893503          	ld	a0,24(s2)
ffffffffc02023d6:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc02023d8:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02023da:	85a6                	mv	a1,s1
ffffffffc02023dc:	4f5000ef          	jal	ra,ffffffffc02030d0 <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc02023e0:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc02023e2:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc02023e4:	8b85                	andi	a5,a5,1
ffffffffc02023e6:	cfb9                	beqz	a5,ffffffffc0202444 <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc02023e8:	65a2                	ld	a1,8(sp)
ffffffffc02023ea:	7d9c                	ld	a5,56(a1)
ffffffffc02023ec:	83b1                	srli	a5,a5,0xc
ffffffffc02023ee:	0785                	addi	a5,a5,1
ffffffffc02023f0:	00879513          	slli	a0,a5,0x8
ffffffffc02023f4:	5b3010ef          	jal	ra,ffffffffc02041a6 <swapfs_write>
ffffffffc02023f8:	d949                	beqz	a0,ffffffffc020238a <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc02023fa:	855e                	mv	a0,s7
ffffffffc02023fc:	cd1fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0202400:	0009b783          	ld	a5,0(s3)
ffffffffc0202404:	6622                	ld	a2,8(sp)
ffffffffc0202406:	4681                	li	a3,0
ffffffffc0202408:	739c                	ld	a5,32(a5)
ffffffffc020240a:	85a6                	mv	a1,s1
ffffffffc020240c:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc020240e:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0202410:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc0202412:	fa8a17e3          	bne	s4,s0,ffffffffc02023c0 <swap_out+0x70>
}
ffffffffc0202416:	60e6                	ld	ra,88(sp)
ffffffffc0202418:	8522                	mv	a0,s0
ffffffffc020241a:	6446                	ld	s0,80(sp)
ffffffffc020241c:	64a6                	ld	s1,72(sp)
ffffffffc020241e:	6906                	ld	s2,64(sp)
ffffffffc0202420:	79e2                	ld	s3,56(sp)
ffffffffc0202422:	7a42                	ld	s4,48(sp)
ffffffffc0202424:	7aa2                	ld	s5,40(sp)
ffffffffc0202426:	7b02                	ld	s6,32(sp)
ffffffffc0202428:	6be2                	ld	s7,24(sp)
ffffffffc020242a:	6c42                	ld	s8,16(sp)
ffffffffc020242c:	6125                	addi	sp,sp,96
ffffffffc020242e:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0202430:	85a2                	mv	a1,s0
ffffffffc0202432:	00004517          	auipc	a0,0x4
ffffffffc0202436:	dde50513          	addi	a0,a0,-546 # ffffffffc0206210 <commands+0x1038>
ffffffffc020243a:	c93fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
                  break;
ffffffffc020243e:	bfe1                	j	ffffffffc0202416 <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc0202440:	4401                	li	s0,0
ffffffffc0202442:	bfd1                	j	ffffffffc0202416 <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0202444:	00004697          	auipc	a3,0x4
ffffffffc0202448:	dfc68693          	addi	a3,a3,-516 # ffffffffc0206240 <commands+0x1068>
ffffffffc020244c:	00003617          	auipc	a2,0x3
ffffffffc0202450:	4b460613          	addi	a2,a2,1204 # ffffffffc0205900 <commands+0x728>
ffffffffc0202454:	06900593          	li	a1,105
ffffffffc0202458:	00004517          	auipc	a0,0x4
ffffffffc020245c:	b0850513          	addi	a0,a0,-1272 # ffffffffc0205f60 <commands+0xd88>
ffffffffc0202460:	d69fd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202464 <swap_in>:
{
ffffffffc0202464:	7179                	addi	sp,sp,-48
ffffffffc0202466:	e84a                	sd	s2,16(sp)
ffffffffc0202468:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc020246a:	4505                	li	a0,1
{
ffffffffc020246c:	ec26                	sd	s1,24(sp)
ffffffffc020246e:	e44e                	sd	s3,8(sp)
ffffffffc0202470:	f406                	sd	ra,40(sp)
ffffffffc0202472:	f022                	sd	s0,32(sp)
ffffffffc0202474:	84ae                	mv	s1,a1
ffffffffc0202476:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc0202478:	34d000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
     assert(result!=NULL);
ffffffffc020247c:	c129                	beqz	a0,ffffffffc02024be <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc020247e:	842a                	mv	s0,a0
ffffffffc0202480:	01893503          	ld	a0,24(s2)
ffffffffc0202484:	4601                	li	a2,0
ffffffffc0202486:	85a6                	mv	a1,s1
ffffffffc0202488:	449000ef          	jal	ra,ffffffffc02030d0 <get_pte>
ffffffffc020248c:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc020248e:	6108                	ld	a0,0(a0)
ffffffffc0202490:	85a2                	mv	a1,s0
ffffffffc0202492:	487010ef          	jal	ra,ffffffffc0204118 <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc0202496:	00093583          	ld	a1,0(s2)
ffffffffc020249a:	8626                	mv	a2,s1
ffffffffc020249c:	00004517          	auipc	a0,0x4
ffffffffc02024a0:	e2450513          	addi	a0,a0,-476 # ffffffffc02062c0 <commands+0x10e8>
ffffffffc02024a4:	81a1                	srli	a1,a1,0x8
ffffffffc02024a6:	c27fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc02024aa:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc02024ac:	0089b023          	sd	s0,0(s3)
}
ffffffffc02024b0:	7402                	ld	s0,32(sp)
ffffffffc02024b2:	64e2                	ld	s1,24(sp)
ffffffffc02024b4:	6942                	ld	s2,16(sp)
ffffffffc02024b6:	69a2                	ld	s3,8(sp)
ffffffffc02024b8:	4501                	li	a0,0
ffffffffc02024ba:	6145                	addi	sp,sp,48
ffffffffc02024bc:	8082                	ret
     assert(result!=NULL);
ffffffffc02024be:	00004697          	auipc	a3,0x4
ffffffffc02024c2:	df268693          	addi	a3,a3,-526 # ffffffffc02062b0 <commands+0x10d8>
ffffffffc02024c6:	00003617          	auipc	a2,0x3
ffffffffc02024ca:	43a60613          	addi	a2,a2,1082 # ffffffffc0205900 <commands+0x728>
ffffffffc02024ce:	07f00593          	li	a1,127
ffffffffc02024d2:	00004517          	auipc	a0,0x4
ffffffffc02024d6:	a8e50513          	addi	a0,a0,-1394 # ffffffffc0205f60 <commands+0xd88>
ffffffffc02024da:	ceffd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02024de <default_init>:
    elm->prev = elm->next = elm;
ffffffffc02024de:	00010797          	auipc	a5,0x10
ffffffffc02024e2:	02278793          	addi	a5,a5,34 # ffffffffc0212500 <free_area>
ffffffffc02024e6:	e79c                	sd	a5,8(a5)
ffffffffc02024e8:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc02024ea:	0007a823          	sw	zero,16(a5)
}
ffffffffc02024ee:	8082                	ret

ffffffffc02024f0 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc02024f0:	00010517          	auipc	a0,0x10
ffffffffc02024f4:	02056503          	lwu	a0,32(a0) # ffffffffc0212510 <free_area+0x10>
ffffffffc02024f8:	8082                	ret

ffffffffc02024fa <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc02024fa:	715d                	addi	sp,sp,-80
ffffffffc02024fc:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02024fe:	00010417          	auipc	s0,0x10
ffffffffc0202502:	00240413          	addi	s0,s0,2 # ffffffffc0212500 <free_area>
ffffffffc0202506:	641c                	ld	a5,8(s0)
ffffffffc0202508:	e486                	sd	ra,72(sp)
ffffffffc020250a:	fc26                	sd	s1,56(sp)
ffffffffc020250c:	f84a                	sd	s2,48(sp)
ffffffffc020250e:	f44e                	sd	s3,40(sp)
ffffffffc0202510:	f052                	sd	s4,32(sp)
ffffffffc0202512:	ec56                	sd	s5,24(sp)
ffffffffc0202514:	e85a                	sd	s6,16(sp)
ffffffffc0202516:	e45e                	sd	s7,8(sp)
ffffffffc0202518:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020251a:	2a878d63          	beq	a5,s0,ffffffffc02027d4 <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc020251e:	4481                	li	s1,0
ffffffffc0202520:	4901                	li	s2,0
ffffffffc0202522:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0202526:	8b09                	andi	a4,a4,2
ffffffffc0202528:	2a070a63          	beqz	a4,ffffffffc02027dc <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc020252c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202530:	679c                	ld	a5,8(a5)
ffffffffc0202532:	2905                	addiw	s2,s2,1
ffffffffc0202534:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202536:	fe8796e3          	bne	a5,s0,ffffffffc0202522 <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc020253a:	89a6                	mv	s3,s1
ffffffffc020253c:	35b000ef          	jal	ra,ffffffffc0203096 <nr_free_pages>
ffffffffc0202540:	6f351e63          	bne	a0,s3,ffffffffc0202c3c <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202544:	4505                	li	a0,1
ffffffffc0202546:	27f000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc020254a:	8aaa                	mv	s5,a0
ffffffffc020254c:	42050863          	beqz	a0,ffffffffc020297c <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202550:	4505                	li	a0,1
ffffffffc0202552:	273000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc0202556:	89aa                	mv	s3,a0
ffffffffc0202558:	70050263          	beqz	a0,ffffffffc0202c5c <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc020255c:	4505                	li	a0,1
ffffffffc020255e:	267000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc0202562:	8a2a                	mv	s4,a0
ffffffffc0202564:	48050c63          	beqz	a0,ffffffffc02029fc <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0202568:	293a8a63          	beq	s5,s3,ffffffffc02027fc <default_check+0x302>
ffffffffc020256c:	28aa8863          	beq	s5,a0,ffffffffc02027fc <default_check+0x302>
ffffffffc0202570:	28a98663          	beq	s3,a0,ffffffffc02027fc <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0202574:	000aa783          	lw	a5,0(s5)
ffffffffc0202578:	2a079263          	bnez	a5,ffffffffc020281c <default_check+0x322>
ffffffffc020257c:	0009a783          	lw	a5,0(s3)
ffffffffc0202580:	28079e63          	bnez	a5,ffffffffc020281c <default_check+0x322>
ffffffffc0202584:	411c                	lw	a5,0(a0)
ffffffffc0202586:	28079b63          	bnez	a5,ffffffffc020281c <default_check+0x322>
    return page - pages + nbase;
ffffffffc020258a:	00014797          	auipc	a5,0x14
ffffffffc020258e:	00e7b783          	ld	a5,14(a5) # ffffffffc0216598 <pages>
ffffffffc0202592:	40fa8733          	sub	a4,s5,a5
ffffffffc0202596:	00005617          	auipc	a2,0x5
ffffffffc020259a:	aaa63603          	ld	a2,-1366(a2) # ffffffffc0207040 <nbase>
ffffffffc020259e:	8719                	srai	a4,a4,0x6
ffffffffc02025a0:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02025a2:	00014697          	auipc	a3,0x14
ffffffffc02025a6:	fee6b683          	ld	a3,-18(a3) # ffffffffc0216590 <npage>
ffffffffc02025aa:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02025ac:	0732                	slli	a4,a4,0xc
ffffffffc02025ae:	28d77763          	bgeu	a4,a3,ffffffffc020283c <default_check+0x342>
    return page - pages + nbase;
ffffffffc02025b2:	40f98733          	sub	a4,s3,a5
ffffffffc02025b6:	8719                	srai	a4,a4,0x6
ffffffffc02025b8:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02025ba:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02025bc:	4cd77063          	bgeu	a4,a3,ffffffffc0202a7c <default_check+0x582>
    return page - pages + nbase;
ffffffffc02025c0:	40f507b3          	sub	a5,a0,a5
ffffffffc02025c4:	8799                	srai	a5,a5,0x6
ffffffffc02025c6:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc02025c8:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02025ca:	30d7f963          	bgeu	a5,a3,ffffffffc02028dc <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc02025ce:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02025d0:	00043c03          	ld	s8,0(s0)
ffffffffc02025d4:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02025d8:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02025dc:	e400                	sd	s0,8(s0)
ffffffffc02025de:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02025e0:	00010797          	auipc	a5,0x10
ffffffffc02025e4:	f207a823          	sw	zero,-208(a5) # ffffffffc0212510 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02025e8:	1dd000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc02025ec:	2c051863          	bnez	a0,ffffffffc02028bc <default_check+0x3c2>
    free_page(p0);
ffffffffc02025f0:	4585                	li	a1,1
ffffffffc02025f2:	8556                	mv	a0,s5
ffffffffc02025f4:	263000ef          	jal	ra,ffffffffc0203056 <free_pages>
    free_page(p1);
ffffffffc02025f8:	4585                	li	a1,1
ffffffffc02025fa:	854e                	mv	a0,s3
ffffffffc02025fc:	25b000ef          	jal	ra,ffffffffc0203056 <free_pages>
    free_page(p2);
ffffffffc0202600:	4585                	li	a1,1
ffffffffc0202602:	8552                	mv	a0,s4
ffffffffc0202604:	253000ef          	jal	ra,ffffffffc0203056 <free_pages>
    assert(nr_free == 3);
ffffffffc0202608:	4818                	lw	a4,16(s0)
ffffffffc020260a:	478d                	li	a5,3
ffffffffc020260c:	28f71863          	bne	a4,a5,ffffffffc020289c <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202610:	4505                	li	a0,1
ffffffffc0202612:	1b3000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc0202616:	89aa                	mv	s3,a0
ffffffffc0202618:	26050263          	beqz	a0,ffffffffc020287c <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc020261c:	4505                	li	a0,1
ffffffffc020261e:	1a7000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc0202622:	8aaa                	mv	s5,a0
ffffffffc0202624:	3a050c63          	beqz	a0,ffffffffc02029dc <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202628:	4505                	li	a0,1
ffffffffc020262a:	19b000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc020262e:	8a2a                	mv	s4,a0
ffffffffc0202630:	38050663          	beqz	a0,ffffffffc02029bc <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0202634:	4505                	li	a0,1
ffffffffc0202636:	18f000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc020263a:	36051163          	bnez	a0,ffffffffc020299c <default_check+0x4a2>
    free_page(p0);
ffffffffc020263e:	4585                	li	a1,1
ffffffffc0202640:	854e                	mv	a0,s3
ffffffffc0202642:	215000ef          	jal	ra,ffffffffc0203056 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0202646:	641c                	ld	a5,8(s0)
ffffffffc0202648:	20878a63          	beq	a5,s0,ffffffffc020285c <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc020264c:	4505                	li	a0,1
ffffffffc020264e:	177000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc0202652:	30a99563          	bne	s3,a0,ffffffffc020295c <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0202656:	4505                	li	a0,1
ffffffffc0202658:	16d000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc020265c:	2e051063          	bnez	a0,ffffffffc020293c <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0202660:	481c                	lw	a5,16(s0)
ffffffffc0202662:	2a079d63          	bnez	a5,ffffffffc020291c <default_check+0x422>
    free_page(p);
ffffffffc0202666:	854e                	mv	a0,s3
ffffffffc0202668:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020266a:	01843023          	sd	s8,0(s0)
ffffffffc020266e:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0202672:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0202676:	1e1000ef          	jal	ra,ffffffffc0203056 <free_pages>
    free_page(p1);
ffffffffc020267a:	4585                	li	a1,1
ffffffffc020267c:	8556                	mv	a0,s5
ffffffffc020267e:	1d9000ef          	jal	ra,ffffffffc0203056 <free_pages>
    free_page(p2);
ffffffffc0202682:	4585                	li	a1,1
ffffffffc0202684:	8552                	mv	a0,s4
ffffffffc0202686:	1d1000ef          	jal	ra,ffffffffc0203056 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020268a:	4515                	li	a0,5
ffffffffc020268c:	139000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc0202690:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0202692:	26050563          	beqz	a0,ffffffffc02028fc <default_check+0x402>
ffffffffc0202696:	651c                	ld	a5,8(a0)
ffffffffc0202698:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc020269a:	8b85                	andi	a5,a5,1
ffffffffc020269c:	54079063          	bnez	a5,ffffffffc0202bdc <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc02026a0:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02026a2:	00043b03          	ld	s6,0(s0)
ffffffffc02026a6:	00843a83          	ld	s5,8(s0)
ffffffffc02026aa:	e000                	sd	s0,0(s0)
ffffffffc02026ac:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc02026ae:	117000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc02026b2:	50051563          	bnez	a0,ffffffffc0202bbc <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc02026b6:	08098a13          	addi	s4,s3,128
ffffffffc02026ba:	8552                	mv	a0,s4
ffffffffc02026bc:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc02026be:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc02026c2:	00010797          	auipc	a5,0x10
ffffffffc02026c6:	e407a723          	sw	zero,-434(a5) # ffffffffc0212510 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc02026ca:	18d000ef          	jal	ra,ffffffffc0203056 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02026ce:	4511                	li	a0,4
ffffffffc02026d0:	0f5000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc02026d4:	4c051463          	bnez	a0,ffffffffc0202b9c <default_check+0x6a2>
ffffffffc02026d8:	0889b783          	ld	a5,136(s3)
ffffffffc02026dc:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc02026de:	8b85                	andi	a5,a5,1
ffffffffc02026e0:	48078e63          	beqz	a5,ffffffffc0202b7c <default_check+0x682>
ffffffffc02026e4:	0909a703          	lw	a4,144(s3)
ffffffffc02026e8:	478d                	li	a5,3
ffffffffc02026ea:	48f71963          	bne	a4,a5,ffffffffc0202b7c <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02026ee:	450d                	li	a0,3
ffffffffc02026f0:	0d5000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc02026f4:	8c2a                	mv	s8,a0
ffffffffc02026f6:	46050363          	beqz	a0,ffffffffc0202b5c <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc02026fa:	4505                	li	a0,1
ffffffffc02026fc:	0c9000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc0202700:	42051e63          	bnez	a0,ffffffffc0202b3c <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0202704:	418a1c63          	bne	s4,s8,ffffffffc0202b1c <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0202708:	4585                	li	a1,1
ffffffffc020270a:	854e                	mv	a0,s3
ffffffffc020270c:	14b000ef          	jal	ra,ffffffffc0203056 <free_pages>
    free_pages(p1, 3);
ffffffffc0202710:	458d                	li	a1,3
ffffffffc0202712:	8552                	mv	a0,s4
ffffffffc0202714:	143000ef          	jal	ra,ffffffffc0203056 <free_pages>
ffffffffc0202718:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc020271c:	04098c13          	addi	s8,s3,64
ffffffffc0202720:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0202722:	8b85                	andi	a5,a5,1
ffffffffc0202724:	3c078c63          	beqz	a5,ffffffffc0202afc <default_check+0x602>
ffffffffc0202728:	0109a703          	lw	a4,16(s3)
ffffffffc020272c:	4785                	li	a5,1
ffffffffc020272e:	3cf71763          	bne	a4,a5,ffffffffc0202afc <default_check+0x602>
ffffffffc0202732:	008a3783          	ld	a5,8(s4)
ffffffffc0202736:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0202738:	8b85                	andi	a5,a5,1
ffffffffc020273a:	3a078163          	beqz	a5,ffffffffc0202adc <default_check+0x5e2>
ffffffffc020273e:	010a2703          	lw	a4,16(s4)
ffffffffc0202742:	478d                	li	a5,3
ffffffffc0202744:	38f71c63          	bne	a4,a5,ffffffffc0202adc <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0202748:	4505                	li	a0,1
ffffffffc020274a:	07b000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc020274e:	36a99763          	bne	s3,a0,ffffffffc0202abc <default_check+0x5c2>
    free_page(p0);
ffffffffc0202752:	4585                	li	a1,1
ffffffffc0202754:	103000ef          	jal	ra,ffffffffc0203056 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0202758:	4509                	li	a0,2
ffffffffc020275a:	06b000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc020275e:	32aa1f63          	bne	s4,a0,ffffffffc0202a9c <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0202762:	4589                	li	a1,2
ffffffffc0202764:	0f3000ef          	jal	ra,ffffffffc0203056 <free_pages>
    free_page(p2);
ffffffffc0202768:	4585                	li	a1,1
ffffffffc020276a:	8562                	mv	a0,s8
ffffffffc020276c:	0eb000ef          	jal	ra,ffffffffc0203056 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0202770:	4515                	li	a0,5
ffffffffc0202772:	053000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc0202776:	89aa                	mv	s3,a0
ffffffffc0202778:	48050263          	beqz	a0,ffffffffc0202bfc <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc020277c:	4505                	li	a0,1
ffffffffc020277e:	047000ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc0202782:	2c051d63          	bnez	a0,ffffffffc0202a5c <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0202786:	481c                	lw	a5,16(s0)
ffffffffc0202788:	2a079a63          	bnez	a5,ffffffffc0202a3c <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020278c:	4595                	li	a1,5
ffffffffc020278e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0202790:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0202794:	01643023          	sd	s6,0(s0)
ffffffffc0202798:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc020279c:	0bb000ef          	jal	ra,ffffffffc0203056 <free_pages>
    return listelm->next;
ffffffffc02027a0:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02027a2:	00878963          	beq	a5,s0,ffffffffc02027b4 <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc02027a6:	ff87a703          	lw	a4,-8(a5)
ffffffffc02027aa:	679c                	ld	a5,8(a5)
ffffffffc02027ac:	397d                	addiw	s2,s2,-1
ffffffffc02027ae:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02027b0:	fe879be3          	bne	a5,s0,ffffffffc02027a6 <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc02027b4:	26091463          	bnez	s2,ffffffffc0202a1c <default_check+0x522>
    assert(total == 0);
ffffffffc02027b8:	46049263          	bnez	s1,ffffffffc0202c1c <default_check+0x722>
}
ffffffffc02027bc:	60a6                	ld	ra,72(sp)
ffffffffc02027be:	6406                	ld	s0,64(sp)
ffffffffc02027c0:	74e2                	ld	s1,56(sp)
ffffffffc02027c2:	7942                	ld	s2,48(sp)
ffffffffc02027c4:	79a2                	ld	s3,40(sp)
ffffffffc02027c6:	7a02                	ld	s4,32(sp)
ffffffffc02027c8:	6ae2                	ld	s5,24(sp)
ffffffffc02027ca:	6b42                	ld	s6,16(sp)
ffffffffc02027cc:	6ba2                	ld	s7,8(sp)
ffffffffc02027ce:	6c02                	ld	s8,0(sp)
ffffffffc02027d0:	6161                	addi	sp,sp,80
ffffffffc02027d2:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc02027d4:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc02027d6:	4481                	li	s1,0
ffffffffc02027d8:	4901                	li	s2,0
ffffffffc02027da:	b38d                	j	ffffffffc020253c <default_check+0x42>
        assert(PageProperty(p));
ffffffffc02027dc:	00003697          	auipc	a3,0x3
ffffffffc02027e0:	7ac68693          	addi	a3,a3,1964 # ffffffffc0205f88 <commands+0xdb0>
ffffffffc02027e4:	00003617          	auipc	a2,0x3
ffffffffc02027e8:	11c60613          	addi	a2,a2,284 # ffffffffc0205900 <commands+0x728>
ffffffffc02027ec:	0f000593          	li	a1,240
ffffffffc02027f0:	00004517          	auipc	a0,0x4
ffffffffc02027f4:	b1050513          	addi	a0,a0,-1264 # ffffffffc0206300 <commands+0x1128>
ffffffffc02027f8:	9d1fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02027fc:	00004697          	auipc	a3,0x4
ffffffffc0202800:	b7c68693          	addi	a3,a3,-1156 # ffffffffc0206378 <commands+0x11a0>
ffffffffc0202804:	00003617          	auipc	a2,0x3
ffffffffc0202808:	0fc60613          	addi	a2,a2,252 # ffffffffc0205900 <commands+0x728>
ffffffffc020280c:	0bd00593          	li	a1,189
ffffffffc0202810:	00004517          	auipc	a0,0x4
ffffffffc0202814:	af050513          	addi	a0,a0,-1296 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202818:	9b1fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020281c:	00004697          	auipc	a3,0x4
ffffffffc0202820:	b8468693          	addi	a3,a3,-1148 # ffffffffc02063a0 <commands+0x11c8>
ffffffffc0202824:	00003617          	auipc	a2,0x3
ffffffffc0202828:	0dc60613          	addi	a2,a2,220 # ffffffffc0205900 <commands+0x728>
ffffffffc020282c:	0be00593          	li	a1,190
ffffffffc0202830:	00004517          	auipc	a0,0x4
ffffffffc0202834:	ad050513          	addi	a0,a0,-1328 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202838:	991fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020283c:	00004697          	auipc	a3,0x4
ffffffffc0202840:	ba468693          	addi	a3,a3,-1116 # ffffffffc02063e0 <commands+0x1208>
ffffffffc0202844:	00003617          	auipc	a2,0x3
ffffffffc0202848:	0bc60613          	addi	a2,a2,188 # ffffffffc0205900 <commands+0x728>
ffffffffc020284c:	0c000593          	li	a1,192
ffffffffc0202850:	00004517          	auipc	a0,0x4
ffffffffc0202854:	ab050513          	addi	a0,a0,-1360 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202858:	971fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(!list_empty(&free_list));
ffffffffc020285c:	00004697          	auipc	a3,0x4
ffffffffc0202860:	c0c68693          	addi	a3,a3,-1012 # ffffffffc0206468 <commands+0x1290>
ffffffffc0202864:	00003617          	auipc	a2,0x3
ffffffffc0202868:	09c60613          	addi	a2,a2,156 # ffffffffc0205900 <commands+0x728>
ffffffffc020286c:	0d900593          	li	a1,217
ffffffffc0202870:	00004517          	auipc	a0,0x4
ffffffffc0202874:	a9050513          	addi	a0,a0,-1392 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202878:	951fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020287c:	00004697          	auipc	a3,0x4
ffffffffc0202880:	a9c68693          	addi	a3,a3,-1380 # ffffffffc0206318 <commands+0x1140>
ffffffffc0202884:	00003617          	auipc	a2,0x3
ffffffffc0202888:	07c60613          	addi	a2,a2,124 # ffffffffc0205900 <commands+0x728>
ffffffffc020288c:	0d200593          	li	a1,210
ffffffffc0202890:	00004517          	auipc	a0,0x4
ffffffffc0202894:	a7050513          	addi	a0,a0,-1424 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202898:	931fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(nr_free == 3);
ffffffffc020289c:	00004697          	auipc	a3,0x4
ffffffffc02028a0:	bbc68693          	addi	a3,a3,-1092 # ffffffffc0206458 <commands+0x1280>
ffffffffc02028a4:	00003617          	auipc	a2,0x3
ffffffffc02028a8:	05c60613          	addi	a2,a2,92 # ffffffffc0205900 <commands+0x728>
ffffffffc02028ac:	0d000593          	li	a1,208
ffffffffc02028b0:	00004517          	auipc	a0,0x4
ffffffffc02028b4:	a5050513          	addi	a0,a0,-1456 # ffffffffc0206300 <commands+0x1128>
ffffffffc02028b8:	911fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02028bc:	00004697          	auipc	a3,0x4
ffffffffc02028c0:	b8468693          	addi	a3,a3,-1148 # ffffffffc0206440 <commands+0x1268>
ffffffffc02028c4:	00003617          	auipc	a2,0x3
ffffffffc02028c8:	03c60613          	addi	a2,a2,60 # ffffffffc0205900 <commands+0x728>
ffffffffc02028cc:	0cb00593          	li	a1,203
ffffffffc02028d0:	00004517          	auipc	a0,0x4
ffffffffc02028d4:	a3050513          	addi	a0,a0,-1488 # ffffffffc0206300 <commands+0x1128>
ffffffffc02028d8:	8f1fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02028dc:	00004697          	auipc	a3,0x4
ffffffffc02028e0:	b4468693          	addi	a3,a3,-1212 # ffffffffc0206420 <commands+0x1248>
ffffffffc02028e4:	00003617          	auipc	a2,0x3
ffffffffc02028e8:	01c60613          	addi	a2,a2,28 # ffffffffc0205900 <commands+0x728>
ffffffffc02028ec:	0c200593          	li	a1,194
ffffffffc02028f0:	00004517          	auipc	a0,0x4
ffffffffc02028f4:	a1050513          	addi	a0,a0,-1520 # ffffffffc0206300 <commands+0x1128>
ffffffffc02028f8:	8d1fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(p0 != NULL);
ffffffffc02028fc:	00004697          	auipc	a3,0x4
ffffffffc0202900:	ba468693          	addi	a3,a3,-1116 # ffffffffc02064a0 <commands+0x12c8>
ffffffffc0202904:	00003617          	auipc	a2,0x3
ffffffffc0202908:	ffc60613          	addi	a2,a2,-4 # ffffffffc0205900 <commands+0x728>
ffffffffc020290c:	0f800593          	li	a1,248
ffffffffc0202910:	00004517          	auipc	a0,0x4
ffffffffc0202914:	9f050513          	addi	a0,a0,-1552 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202918:	8b1fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(nr_free == 0);
ffffffffc020291c:	00004697          	auipc	a3,0x4
ffffffffc0202920:	80c68693          	addi	a3,a3,-2036 # ffffffffc0206128 <commands+0xf50>
ffffffffc0202924:	00003617          	auipc	a2,0x3
ffffffffc0202928:	fdc60613          	addi	a2,a2,-36 # ffffffffc0205900 <commands+0x728>
ffffffffc020292c:	0df00593          	li	a1,223
ffffffffc0202930:	00004517          	auipc	a0,0x4
ffffffffc0202934:	9d050513          	addi	a0,a0,-1584 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202938:	891fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020293c:	00004697          	auipc	a3,0x4
ffffffffc0202940:	b0468693          	addi	a3,a3,-1276 # ffffffffc0206440 <commands+0x1268>
ffffffffc0202944:	00003617          	auipc	a2,0x3
ffffffffc0202948:	fbc60613          	addi	a2,a2,-68 # ffffffffc0205900 <commands+0x728>
ffffffffc020294c:	0dd00593          	li	a1,221
ffffffffc0202950:	00004517          	auipc	a0,0x4
ffffffffc0202954:	9b050513          	addi	a0,a0,-1616 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202958:	871fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc020295c:	00004697          	auipc	a3,0x4
ffffffffc0202960:	b2468693          	addi	a3,a3,-1244 # ffffffffc0206480 <commands+0x12a8>
ffffffffc0202964:	00003617          	auipc	a2,0x3
ffffffffc0202968:	f9c60613          	addi	a2,a2,-100 # ffffffffc0205900 <commands+0x728>
ffffffffc020296c:	0dc00593          	li	a1,220
ffffffffc0202970:	00004517          	auipc	a0,0x4
ffffffffc0202974:	99050513          	addi	a0,a0,-1648 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202978:	851fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020297c:	00004697          	auipc	a3,0x4
ffffffffc0202980:	99c68693          	addi	a3,a3,-1636 # ffffffffc0206318 <commands+0x1140>
ffffffffc0202984:	00003617          	auipc	a2,0x3
ffffffffc0202988:	f7c60613          	addi	a2,a2,-132 # ffffffffc0205900 <commands+0x728>
ffffffffc020298c:	0b900593          	li	a1,185
ffffffffc0202990:	00004517          	auipc	a0,0x4
ffffffffc0202994:	97050513          	addi	a0,a0,-1680 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202998:	831fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc020299c:	00004697          	auipc	a3,0x4
ffffffffc02029a0:	aa468693          	addi	a3,a3,-1372 # ffffffffc0206440 <commands+0x1268>
ffffffffc02029a4:	00003617          	auipc	a2,0x3
ffffffffc02029a8:	f5c60613          	addi	a2,a2,-164 # ffffffffc0205900 <commands+0x728>
ffffffffc02029ac:	0d600593          	li	a1,214
ffffffffc02029b0:	00004517          	auipc	a0,0x4
ffffffffc02029b4:	95050513          	addi	a0,a0,-1712 # ffffffffc0206300 <commands+0x1128>
ffffffffc02029b8:	811fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02029bc:	00004697          	auipc	a3,0x4
ffffffffc02029c0:	99c68693          	addi	a3,a3,-1636 # ffffffffc0206358 <commands+0x1180>
ffffffffc02029c4:	00003617          	auipc	a2,0x3
ffffffffc02029c8:	f3c60613          	addi	a2,a2,-196 # ffffffffc0205900 <commands+0x728>
ffffffffc02029cc:	0d400593          	li	a1,212
ffffffffc02029d0:	00004517          	auipc	a0,0x4
ffffffffc02029d4:	93050513          	addi	a0,a0,-1744 # ffffffffc0206300 <commands+0x1128>
ffffffffc02029d8:	ff0fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02029dc:	00004697          	auipc	a3,0x4
ffffffffc02029e0:	95c68693          	addi	a3,a3,-1700 # ffffffffc0206338 <commands+0x1160>
ffffffffc02029e4:	00003617          	auipc	a2,0x3
ffffffffc02029e8:	f1c60613          	addi	a2,a2,-228 # ffffffffc0205900 <commands+0x728>
ffffffffc02029ec:	0d300593          	li	a1,211
ffffffffc02029f0:	00004517          	auipc	a0,0x4
ffffffffc02029f4:	91050513          	addi	a0,a0,-1776 # ffffffffc0206300 <commands+0x1128>
ffffffffc02029f8:	fd0fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02029fc:	00004697          	auipc	a3,0x4
ffffffffc0202a00:	95c68693          	addi	a3,a3,-1700 # ffffffffc0206358 <commands+0x1180>
ffffffffc0202a04:	00003617          	auipc	a2,0x3
ffffffffc0202a08:	efc60613          	addi	a2,a2,-260 # ffffffffc0205900 <commands+0x728>
ffffffffc0202a0c:	0bb00593          	li	a1,187
ffffffffc0202a10:	00004517          	auipc	a0,0x4
ffffffffc0202a14:	8f050513          	addi	a0,a0,-1808 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202a18:	fb0fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(count == 0);
ffffffffc0202a1c:	00004697          	auipc	a3,0x4
ffffffffc0202a20:	bd468693          	addi	a3,a3,-1068 # ffffffffc02065f0 <commands+0x1418>
ffffffffc0202a24:	00003617          	auipc	a2,0x3
ffffffffc0202a28:	edc60613          	addi	a2,a2,-292 # ffffffffc0205900 <commands+0x728>
ffffffffc0202a2c:	12500593          	li	a1,293
ffffffffc0202a30:	00004517          	auipc	a0,0x4
ffffffffc0202a34:	8d050513          	addi	a0,a0,-1840 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202a38:	f90fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(nr_free == 0);
ffffffffc0202a3c:	00003697          	auipc	a3,0x3
ffffffffc0202a40:	6ec68693          	addi	a3,a3,1772 # ffffffffc0206128 <commands+0xf50>
ffffffffc0202a44:	00003617          	auipc	a2,0x3
ffffffffc0202a48:	ebc60613          	addi	a2,a2,-324 # ffffffffc0205900 <commands+0x728>
ffffffffc0202a4c:	11a00593          	li	a1,282
ffffffffc0202a50:	00004517          	auipc	a0,0x4
ffffffffc0202a54:	8b050513          	addi	a0,a0,-1872 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202a58:	f70fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202a5c:	00004697          	auipc	a3,0x4
ffffffffc0202a60:	9e468693          	addi	a3,a3,-1564 # ffffffffc0206440 <commands+0x1268>
ffffffffc0202a64:	00003617          	auipc	a2,0x3
ffffffffc0202a68:	e9c60613          	addi	a2,a2,-356 # ffffffffc0205900 <commands+0x728>
ffffffffc0202a6c:	11800593          	li	a1,280
ffffffffc0202a70:	00004517          	auipc	a0,0x4
ffffffffc0202a74:	89050513          	addi	a0,a0,-1904 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202a78:	f50fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0202a7c:	00004697          	auipc	a3,0x4
ffffffffc0202a80:	98468693          	addi	a3,a3,-1660 # ffffffffc0206400 <commands+0x1228>
ffffffffc0202a84:	00003617          	auipc	a2,0x3
ffffffffc0202a88:	e7c60613          	addi	a2,a2,-388 # ffffffffc0205900 <commands+0x728>
ffffffffc0202a8c:	0c100593          	li	a1,193
ffffffffc0202a90:	00004517          	auipc	a0,0x4
ffffffffc0202a94:	87050513          	addi	a0,a0,-1936 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202a98:	f30fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0202a9c:	00004697          	auipc	a3,0x4
ffffffffc0202aa0:	b1468693          	addi	a3,a3,-1260 # ffffffffc02065b0 <commands+0x13d8>
ffffffffc0202aa4:	00003617          	auipc	a2,0x3
ffffffffc0202aa8:	e5c60613          	addi	a2,a2,-420 # ffffffffc0205900 <commands+0x728>
ffffffffc0202aac:	11200593          	li	a1,274
ffffffffc0202ab0:	00004517          	auipc	a0,0x4
ffffffffc0202ab4:	85050513          	addi	a0,a0,-1968 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202ab8:	f10fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0202abc:	00004697          	auipc	a3,0x4
ffffffffc0202ac0:	ad468693          	addi	a3,a3,-1324 # ffffffffc0206590 <commands+0x13b8>
ffffffffc0202ac4:	00003617          	auipc	a2,0x3
ffffffffc0202ac8:	e3c60613          	addi	a2,a2,-452 # ffffffffc0205900 <commands+0x728>
ffffffffc0202acc:	11000593          	li	a1,272
ffffffffc0202ad0:	00004517          	auipc	a0,0x4
ffffffffc0202ad4:	83050513          	addi	a0,a0,-2000 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202ad8:	ef0fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0202adc:	00004697          	auipc	a3,0x4
ffffffffc0202ae0:	a8c68693          	addi	a3,a3,-1396 # ffffffffc0206568 <commands+0x1390>
ffffffffc0202ae4:	00003617          	auipc	a2,0x3
ffffffffc0202ae8:	e1c60613          	addi	a2,a2,-484 # ffffffffc0205900 <commands+0x728>
ffffffffc0202aec:	10e00593          	li	a1,270
ffffffffc0202af0:	00004517          	auipc	a0,0x4
ffffffffc0202af4:	81050513          	addi	a0,a0,-2032 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202af8:	ed0fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0202afc:	00004697          	auipc	a3,0x4
ffffffffc0202b00:	a4468693          	addi	a3,a3,-1468 # ffffffffc0206540 <commands+0x1368>
ffffffffc0202b04:	00003617          	auipc	a2,0x3
ffffffffc0202b08:	dfc60613          	addi	a2,a2,-516 # ffffffffc0205900 <commands+0x728>
ffffffffc0202b0c:	10d00593          	li	a1,269
ffffffffc0202b10:	00003517          	auipc	a0,0x3
ffffffffc0202b14:	7f050513          	addi	a0,a0,2032 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202b18:	eb0fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0202b1c:	00004697          	auipc	a3,0x4
ffffffffc0202b20:	a1468693          	addi	a3,a3,-1516 # ffffffffc0206530 <commands+0x1358>
ffffffffc0202b24:	00003617          	auipc	a2,0x3
ffffffffc0202b28:	ddc60613          	addi	a2,a2,-548 # ffffffffc0205900 <commands+0x728>
ffffffffc0202b2c:	10800593          	li	a1,264
ffffffffc0202b30:	00003517          	auipc	a0,0x3
ffffffffc0202b34:	7d050513          	addi	a0,a0,2000 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202b38:	e90fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202b3c:	00004697          	auipc	a3,0x4
ffffffffc0202b40:	90468693          	addi	a3,a3,-1788 # ffffffffc0206440 <commands+0x1268>
ffffffffc0202b44:	00003617          	auipc	a2,0x3
ffffffffc0202b48:	dbc60613          	addi	a2,a2,-580 # ffffffffc0205900 <commands+0x728>
ffffffffc0202b4c:	10700593          	li	a1,263
ffffffffc0202b50:	00003517          	auipc	a0,0x3
ffffffffc0202b54:	7b050513          	addi	a0,a0,1968 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202b58:	e70fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0202b5c:	00004697          	auipc	a3,0x4
ffffffffc0202b60:	9b468693          	addi	a3,a3,-1612 # ffffffffc0206510 <commands+0x1338>
ffffffffc0202b64:	00003617          	auipc	a2,0x3
ffffffffc0202b68:	d9c60613          	addi	a2,a2,-612 # ffffffffc0205900 <commands+0x728>
ffffffffc0202b6c:	10600593          	li	a1,262
ffffffffc0202b70:	00003517          	auipc	a0,0x3
ffffffffc0202b74:	79050513          	addi	a0,a0,1936 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202b78:	e50fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0202b7c:	00004697          	auipc	a3,0x4
ffffffffc0202b80:	96468693          	addi	a3,a3,-1692 # ffffffffc02064e0 <commands+0x1308>
ffffffffc0202b84:	00003617          	auipc	a2,0x3
ffffffffc0202b88:	d7c60613          	addi	a2,a2,-644 # ffffffffc0205900 <commands+0x728>
ffffffffc0202b8c:	10500593          	li	a1,261
ffffffffc0202b90:	00003517          	auipc	a0,0x3
ffffffffc0202b94:	77050513          	addi	a0,a0,1904 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202b98:	e30fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0202b9c:	00004697          	auipc	a3,0x4
ffffffffc0202ba0:	92c68693          	addi	a3,a3,-1748 # ffffffffc02064c8 <commands+0x12f0>
ffffffffc0202ba4:	00003617          	auipc	a2,0x3
ffffffffc0202ba8:	d5c60613          	addi	a2,a2,-676 # ffffffffc0205900 <commands+0x728>
ffffffffc0202bac:	10400593          	li	a1,260
ffffffffc0202bb0:	00003517          	auipc	a0,0x3
ffffffffc0202bb4:	75050513          	addi	a0,a0,1872 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202bb8:	e10fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202bbc:	00004697          	auipc	a3,0x4
ffffffffc0202bc0:	88468693          	addi	a3,a3,-1916 # ffffffffc0206440 <commands+0x1268>
ffffffffc0202bc4:	00003617          	auipc	a2,0x3
ffffffffc0202bc8:	d3c60613          	addi	a2,a2,-708 # ffffffffc0205900 <commands+0x728>
ffffffffc0202bcc:	0fe00593          	li	a1,254
ffffffffc0202bd0:	00003517          	auipc	a0,0x3
ffffffffc0202bd4:	73050513          	addi	a0,a0,1840 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202bd8:	df0fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(!PageProperty(p0));
ffffffffc0202bdc:	00004697          	auipc	a3,0x4
ffffffffc0202be0:	8d468693          	addi	a3,a3,-1836 # ffffffffc02064b0 <commands+0x12d8>
ffffffffc0202be4:	00003617          	auipc	a2,0x3
ffffffffc0202be8:	d1c60613          	addi	a2,a2,-740 # ffffffffc0205900 <commands+0x728>
ffffffffc0202bec:	0f900593          	li	a1,249
ffffffffc0202bf0:	00003517          	auipc	a0,0x3
ffffffffc0202bf4:	71050513          	addi	a0,a0,1808 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202bf8:	dd0fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0202bfc:	00004697          	auipc	a3,0x4
ffffffffc0202c00:	9d468693          	addi	a3,a3,-1580 # ffffffffc02065d0 <commands+0x13f8>
ffffffffc0202c04:	00003617          	auipc	a2,0x3
ffffffffc0202c08:	cfc60613          	addi	a2,a2,-772 # ffffffffc0205900 <commands+0x728>
ffffffffc0202c0c:	11700593          	li	a1,279
ffffffffc0202c10:	00003517          	auipc	a0,0x3
ffffffffc0202c14:	6f050513          	addi	a0,a0,1776 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202c18:	db0fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(total == 0);
ffffffffc0202c1c:	00004697          	auipc	a3,0x4
ffffffffc0202c20:	9e468693          	addi	a3,a3,-1564 # ffffffffc0206600 <commands+0x1428>
ffffffffc0202c24:	00003617          	auipc	a2,0x3
ffffffffc0202c28:	cdc60613          	addi	a2,a2,-804 # ffffffffc0205900 <commands+0x728>
ffffffffc0202c2c:	12600593          	li	a1,294
ffffffffc0202c30:	00003517          	auipc	a0,0x3
ffffffffc0202c34:	6d050513          	addi	a0,a0,1744 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202c38:	d90fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(total == nr_free_pages());
ffffffffc0202c3c:	00003697          	auipc	a3,0x3
ffffffffc0202c40:	35c68693          	addi	a3,a3,860 # ffffffffc0205f98 <commands+0xdc0>
ffffffffc0202c44:	00003617          	auipc	a2,0x3
ffffffffc0202c48:	cbc60613          	addi	a2,a2,-836 # ffffffffc0205900 <commands+0x728>
ffffffffc0202c4c:	0f300593          	li	a1,243
ffffffffc0202c50:	00003517          	auipc	a0,0x3
ffffffffc0202c54:	6b050513          	addi	a0,a0,1712 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202c58:	d70fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202c5c:	00003697          	auipc	a3,0x3
ffffffffc0202c60:	6dc68693          	addi	a3,a3,1756 # ffffffffc0206338 <commands+0x1160>
ffffffffc0202c64:	00003617          	auipc	a2,0x3
ffffffffc0202c68:	c9c60613          	addi	a2,a2,-868 # ffffffffc0205900 <commands+0x728>
ffffffffc0202c6c:	0ba00593          	li	a1,186
ffffffffc0202c70:	00003517          	auipc	a0,0x3
ffffffffc0202c74:	69050513          	addi	a0,a0,1680 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202c78:	d50fd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202c7c <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0202c7c:	1141                	addi	sp,sp,-16
ffffffffc0202c7e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0202c80:	14058463          	beqz	a1,ffffffffc0202dc8 <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc0202c84:	00659693          	slli	a3,a1,0x6
ffffffffc0202c88:	96aa                	add	a3,a3,a0
ffffffffc0202c8a:	87aa                	mv	a5,a0
ffffffffc0202c8c:	02d50263          	beq	a0,a3,ffffffffc0202cb0 <default_free_pages+0x34>
ffffffffc0202c90:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0202c92:	8b05                	andi	a4,a4,1
ffffffffc0202c94:	10071a63          	bnez	a4,ffffffffc0202da8 <default_free_pages+0x12c>
ffffffffc0202c98:	6798                	ld	a4,8(a5)
ffffffffc0202c9a:	8b09                	andi	a4,a4,2
ffffffffc0202c9c:	10071663          	bnez	a4,ffffffffc0202da8 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0202ca0:	0007b423          	sd	zero,8(a5)
    page->ref = val;
ffffffffc0202ca4:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0202ca8:	04078793          	addi	a5,a5,64
ffffffffc0202cac:	fed792e3          	bne	a5,a3,ffffffffc0202c90 <default_free_pages+0x14>
    base->property = n;
ffffffffc0202cb0:	2581                	sext.w	a1,a1
ffffffffc0202cb2:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0202cb4:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0202cb8:	4789                	li	a5,2
ffffffffc0202cba:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0202cbe:	00010697          	auipc	a3,0x10
ffffffffc0202cc2:	84268693          	addi	a3,a3,-1982 # ffffffffc0212500 <free_area>
ffffffffc0202cc6:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0202cc8:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0202cca:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0202cce:	9db9                	addw	a1,a1,a4
ffffffffc0202cd0:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0202cd2:	0ad78463          	beq	a5,a3,ffffffffc0202d7a <default_free_pages+0xfe>
            struct Page* page = le2page(le, page_link);
ffffffffc0202cd6:	fe878713          	addi	a4,a5,-24
ffffffffc0202cda:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0202cde:	4581                	li	a1,0
            if (base < page) {
ffffffffc0202ce0:	00e56a63          	bltu	a0,a4,ffffffffc0202cf4 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0202ce4:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0202ce6:	04d70c63          	beq	a4,a3,ffffffffc0202d3e <default_free_pages+0xc2>
    for (; p != base + n; p ++) {
ffffffffc0202cea:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0202cec:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0202cf0:	fee57ae3          	bgeu	a0,a4,ffffffffc0202ce4 <default_free_pages+0x68>
ffffffffc0202cf4:	c199                	beqz	a1,ffffffffc0202cfa <default_free_pages+0x7e>
ffffffffc0202cf6:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0202cfa:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0202cfc:	e390                	sd	a2,0(a5)
ffffffffc0202cfe:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0202d00:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0202d02:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0202d04:	00d70d63          	beq	a4,a3,ffffffffc0202d1e <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc0202d08:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc0202d0c:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc0202d10:	02059813          	slli	a6,a1,0x20
ffffffffc0202d14:	01a85793          	srli	a5,a6,0x1a
ffffffffc0202d18:	97b2                	add	a5,a5,a2
ffffffffc0202d1a:	02f50c63          	beq	a0,a5,ffffffffc0202d52 <default_free_pages+0xd6>
    return listelm->next;
ffffffffc0202d1e:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc0202d20:	00d78c63          	beq	a5,a3,ffffffffc0202d38 <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc0202d24:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc0202d26:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc0202d2a:	02061593          	slli	a1,a2,0x20
ffffffffc0202d2e:	01a5d713          	srli	a4,a1,0x1a
ffffffffc0202d32:	972a                	add	a4,a4,a0
ffffffffc0202d34:	04e68a63          	beq	a3,a4,ffffffffc0202d88 <default_free_pages+0x10c>
}
ffffffffc0202d38:	60a2                	ld	ra,8(sp)
ffffffffc0202d3a:	0141                	addi	sp,sp,16
ffffffffc0202d3c:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0202d3e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202d40:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0202d42:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0202d44:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0202d46:	02d70763          	beq	a4,a3,ffffffffc0202d74 <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc0202d4a:	8832                	mv	a6,a2
ffffffffc0202d4c:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0202d4e:	87ba                	mv	a5,a4
ffffffffc0202d50:	bf71                	j	ffffffffc0202cec <default_free_pages+0x70>
            p->property += base->property;
ffffffffc0202d52:	491c                	lw	a5,16(a0)
ffffffffc0202d54:	9dbd                	addw	a1,a1,a5
ffffffffc0202d56:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0202d5a:	57f5                	li	a5,-3
ffffffffc0202d5c:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0202d60:	01853803          	ld	a6,24(a0)
ffffffffc0202d64:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0202d66:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc0202d68:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0202d6c:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0202d6e:	0105b023          	sd	a6,0(a1) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc0202d72:	b77d                	j	ffffffffc0202d20 <default_free_pages+0xa4>
ffffffffc0202d74:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0202d76:	873e                	mv	a4,a5
ffffffffc0202d78:	bf41                	j	ffffffffc0202d08 <default_free_pages+0x8c>
}
ffffffffc0202d7a:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0202d7c:	e390                	sd	a2,0(a5)
ffffffffc0202d7e:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202d80:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0202d82:	ed1c                	sd	a5,24(a0)
ffffffffc0202d84:	0141                	addi	sp,sp,16
ffffffffc0202d86:	8082                	ret
            base->property += p->property;
ffffffffc0202d88:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202d8c:	ff078693          	addi	a3,a5,-16
ffffffffc0202d90:	9e39                	addw	a2,a2,a4
ffffffffc0202d92:	c910                	sw	a2,16(a0)
ffffffffc0202d94:	5775                	li	a4,-3
ffffffffc0202d96:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0202d9a:	6398                	ld	a4,0(a5)
ffffffffc0202d9c:	679c                	ld	a5,8(a5)
}
ffffffffc0202d9e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0202da0:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0202da2:	e398                	sd	a4,0(a5)
ffffffffc0202da4:	0141                	addi	sp,sp,16
ffffffffc0202da6:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0202da8:	00004697          	auipc	a3,0x4
ffffffffc0202dac:	87068693          	addi	a3,a3,-1936 # ffffffffc0206618 <commands+0x1440>
ffffffffc0202db0:	00003617          	auipc	a2,0x3
ffffffffc0202db4:	b5060613          	addi	a2,a2,-1200 # ffffffffc0205900 <commands+0x728>
ffffffffc0202db8:	08300593          	li	a1,131
ffffffffc0202dbc:	00003517          	auipc	a0,0x3
ffffffffc0202dc0:	54450513          	addi	a0,a0,1348 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202dc4:	c04fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc0202dc8:	00004697          	auipc	a3,0x4
ffffffffc0202dcc:	84868693          	addi	a3,a3,-1976 # ffffffffc0206610 <commands+0x1438>
ffffffffc0202dd0:	00003617          	auipc	a2,0x3
ffffffffc0202dd4:	b3060613          	addi	a2,a2,-1232 # ffffffffc0205900 <commands+0x728>
ffffffffc0202dd8:	08000593          	li	a1,128
ffffffffc0202ddc:	00003517          	auipc	a0,0x3
ffffffffc0202de0:	52450513          	addi	a0,a0,1316 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202de4:	be4fd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202de8 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0202de8:	c941                	beqz	a0,ffffffffc0202e78 <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc0202dea:	0000f597          	auipc	a1,0xf
ffffffffc0202dee:	71658593          	addi	a1,a1,1814 # ffffffffc0212500 <free_area>
ffffffffc0202df2:	0105a803          	lw	a6,16(a1)
ffffffffc0202df6:	872a                	mv	a4,a0
ffffffffc0202df8:	02081793          	slli	a5,a6,0x20
ffffffffc0202dfc:	9381                	srli	a5,a5,0x20
ffffffffc0202dfe:	00a7ee63          	bltu	a5,a0,ffffffffc0202e1a <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc0202e02:	87ae                	mv	a5,a1
ffffffffc0202e04:	a801                	j	ffffffffc0202e14 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0202e06:	ff87a683          	lw	a3,-8(a5)
ffffffffc0202e0a:	02069613          	slli	a2,a3,0x20
ffffffffc0202e0e:	9201                	srli	a2,a2,0x20
ffffffffc0202e10:	00e67763          	bgeu	a2,a4,ffffffffc0202e1e <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0202e14:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202e16:	feb798e3          	bne	a5,a1,ffffffffc0202e06 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0202e1a:	4501                	li	a0,0
}
ffffffffc0202e1c:	8082                	ret
    return listelm->prev;
ffffffffc0202e1e:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0202e22:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc0202e26:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc0202e2a:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc0202e2e:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0202e32:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0202e36:	02c77863          	bgeu	a4,a2,ffffffffc0202e66 <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc0202e3a:	071a                	slli	a4,a4,0x6
ffffffffc0202e3c:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0202e3e:	41c686bb          	subw	a3,a3,t3
ffffffffc0202e42:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0202e44:	00870613          	addi	a2,a4,8
ffffffffc0202e48:	4689                	li	a3,2
ffffffffc0202e4a:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc0202e4e:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0202e52:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc0202e56:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc0202e5a:	e290                	sd	a2,0(a3)
ffffffffc0202e5c:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc0202e60:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc0202e62:	01173c23          	sd	a7,24(a4)
ffffffffc0202e66:	41c8083b          	subw	a6,a6,t3
ffffffffc0202e6a:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0202e6e:	5775                	li	a4,-3
ffffffffc0202e70:	17c1                	addi	a5,a5,-16
ffffffffc0202e72:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc0202e76:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0202e78:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0202e7a:	00003697          	auipc	a3,0x3
ffffffffc0202e7e:	79668693          	addi	a3,a3,1942 # ffffffffc0206610 <commands+0x1438>
ffffffffc0202e82:	00003617          	auipc	a2,0x3
ffffffffc0202e86:	a7e60613          	addi	a2,a2,-1410 # ffffffffc0205900 <commands+0x728>
ffffffffc0202e8a:	06200593          	li	a1,98
ffffffffc0202e8e:	00003517          	auipc	a0,0x3
ffffffffc0202e92:	47250513          	addi	a0,a0,1138 # ffffffffc0206300 <commands+0x1128>
default_alloc_pages(size_t n) {
ffffffffc0202e96:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0202e98:	b30fd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202e9c <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0202e9c:	1141                	addi	sp,sp,-16
ffffffffc0202e9e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0202ea0:	c5f1                	beqz	a1,ffffffffc0202f6c <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc0202ea2:	00659693          	slli	a3,a1,0x6
ffffffffc0202ea6:	96aa                	add	a3,a3,a0
ffffffffc0202ea8:	87aa                	mv	a5,a0
ffffffffc0202eaa:	00d50f63          	beq	a0,a3,ffffffffc0202ec8 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0202eae:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0202eb0:	8b05                	andi	a4,a4,1
ffffffffc0202eb2:	cf49                	beqz	a4,ffffffffc0202f4c <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc0202eb4:	0007a823          	sw	zero,16(a5)
ffffffffc0202eb8:	0007b423          	sd	zero,8(a5)
ffffffffc0202ebc:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0202ec0:	04078793          	addi	a5,a5,64
ffffffffc0202ec4:	fed795e3          	bne	a5,a3,ffffffffc0202eae <default_init_memmap+0x12>
    base->property = n;
ffffffffc0202ec8:	2581                	sext.w	a1,a1
ffffffffc0202eca:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0202ecc:	4789                	li	a5,2
ffffffffc0202ece:	00850713          	addi	a4,a0,8
ffffffffc0202ed2:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0202ed6:	0000f697          	auipc	a3,0xf
ffffffffc0202eda:	62a68693          	addi	a3,a3,1578 # ffffffffc0212500 <free_area>
ffffffffc0202ede:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0202ee0:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0202ee2:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0202ee6:	9db9                	addw	a1,a1,a4
ffffffffc0202ee8:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0202eea:	04d78a63          	beq	a5,a3,ffffffffc0202f3e <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc0202eee:	fe878713          	addi	a4,a5,-24
ffffffffc0202ef2:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0202ef6:	4581                	li	a1,0
            if (base < page) {
ffffffffc0202ef8:	00e56a63          	bltu	a0,a4,ffffffffc0202f0c <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0202efc:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0202efe:	02d70263          	beq	a4,a3,ffffffffc0202f22 <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc0202f02:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0202f04:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0202f08:	fee57ae3          	bgeu	a0,a4,ffffffffc0202efc <default_init_memmap+0x60>
ffffffffc0202f0c:	c199                	beqz	a1,ffffffffc0202f12 <default_init_memmap+0x76>
ffffffffc0202f0e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0202f12:	6398                	ld	a4,0(a5)
}
ffffffffc0202f14:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0202f16:	e390                	sd	a2,0(a5)
ffffffffc0202f18:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0202f1a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0202f1c:	ed18                	sd	a4,24(a0)
ffffffffc0202f1e:	0141                	addi	sp,sp,16
ffffffffc0202f20:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0202f22:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202f24:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0202f26:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0202f28:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0202f2a:	00d70663          	beq	a4,a3,ffffffffc0202f36 <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc0202f2e:	8832                	mv	a6,a2
ffffffffc0202f30:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0202f32:	87ba                	mv	a5,a4
ffffffffc0202f34:	bfc1                	j	ffffffffc0202f04 <default_init_memmap+0x68>
}
ffffffffc0202f36:	60a2                	ld	ra,8(sp)
ffffffffc0202f38:	e290                	sd	a2,0(a3)
ffffffffc0202f3a:	0141                	addi	sp,sp,16
ffffffffc0202f3c:	8082                	ret
ffffffffc0202f3e:	60a2                	ld	ra,8(sp)
ffffffffc0202f40:	e390                	sd	a2,0(a5)
ffffffffc0202f42:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0202f44:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0202f46:	ed1c                	sd	a5,24(a0)
ffffffffc0202f48:	0141                	addi	sp,sp,16
ffffffffc0202f4a:	8082                	ret
        assert(PageReserved(p));
ffffffffc0202f4c:	00003697          	auipc	a3,0x3
ffffffffc0202f50:	6f468693          	addi	a3,a3,1780 # ffffffffc0206640 <commands+0x1468>
ffffffffc0202f54:	00003617          	auipc	a2,0x3
ffffffffc0202f58:	9ac60613          	addi	a2,a2,-1620 # ffffffffc0205900 <commands+0x728>
ffffffffc0202f5c:	04900593          	li	a1,73
ffffffffc0202f60:	00003517          	auipc	a0,0x3
ffffffffc0202f64:	3a050513          	addi	a0,a0,928 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202f68:	a60fd0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(n > 0);
ffffffffc0202f6c:	00003697          	auipc	a3,0x3
ffffffffc0202f70:	6a468693          	addi	a3,a3,1700 # ffffffffc0206610 <commands+0x1438>
ffffffffc0202f74:	00003617          	auipc	a2,0x3
ffffffffc0202f78:	98c60613          	addi	a2,a2,-1652 # ffffffffc0205900 <commands+0x728>
ffffffffc0202f7c:	04600593          	li	a1,70
ffffffffc0202f80:	00003517          	auipc	a0,0x3
ffffffffc0202f84:	38050513          	addi	a0,a0,896 # ffffffffc0206300 <commands+0x1128>
ffffffffc0202f88:	a40fd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202f8c <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc0202f8c:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0202f8e:	00003617          	auipc	a2,0x3
ffffffffc0202f92:	b9a60613          	addi	a2,a2,-1126 # ffffffffc0205b28 <commands+0x950>
ffffffffc0202f96:	06200593          	li	a1,98
ffffffffc0202f9a:	00003517          	auipc	a0,0x3
ffffffffc0202f9e:	bae50513          	addi	a0,a0,-1106 # ffffffffc0205b48 <commands+0x970>
pa2page(uintptr_t pa) {
ffffffffc0202fa2:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0202fa4:	a24fd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202fa8 <pte2page.part.0>:
pte2page(pte_t pte) {
ffffffffc0202fa8:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0202faa:	00003617          	auipc	a2,0x3
ffffffffc0202fae:	1a660613          	addi	a2,a2,422 # ffffffffc0206150 <commands+0xf78>
ffffffffc0202fb2:	07400593          	li	a1,116
ffffffffc0202fb6:	00003517          	auipc	a0,0x3
ffffffffc0202fba:	b9250513          	addi	a0,a0,-1134 # ffffffffc0205b48 <commands+0x970>
pte2page(pte_t pte) {
ffffffffc0202fbe:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0202fc0:	a08fd0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0202fc4 <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0202fc4:	7139                	addi	sp,sp,-64
ffffffffc0202fc6:	f426                	sd	s1,40(sp)
ffffffffc0202fc8:	f04a                	sd	s2,32(sp)
ffffffffc0202fca:	ec4e                	sd	s3,24(sp)
ffffffffc0202fcc:	e852                	sd	s4,16(sp)
ffffffffc0202fce:	e456                	sd	s5,8(sp)
ffffffffc0202fd0:	e05a                	sd	s6,0(sp)
ffffffffc0202fd2:	fc06                	sd	ra,56(sp)
ffffffffc0202fd4:	f822                	sd	s0,48(sp)
ffffffffc0202fd6:	84aa                	mv	s1,a0
ffffffffc0202fd8:	00013917          	auipc	s2,0x13
ffffffffc0202fdc:	5c890913          	addi	s2,s2,1480 # ffffffffc02165a0 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0202fe0:	4a05                	li	s4,1
ffffffffc0202fe2:	00013a97          	auipc	s5,0x13
ffffffffc0202fe6:	596a8a93          	addi	s5,s5,1430 # ffffffffc0216578 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0202fea:	0005099b          	sext.w	s3,a0
ffffffffc0202fee:	00013b17          	auipc	s6,0x13
ffffffffc0202ff2:	562b0b13          	addi	s6,s6,1378 # ffffffffc0216550 <check_mm_struct>
ffffffffc0202ff6:	a01d                	j	ffffffffc020301c <alloc_pages+0x58>
            page = pmm_manager->alloc_pages(n);
ffffffffc0202ff8:	00093783          	ld	a5,0(s2)
ffffffffc0202ffc:	6f9c                	ld	a5,24(a5)
ffffffffc0202ffe:	9782                	jalr	a5
ffffffffc0203000:	842a                	mv	s0,a0
        swap_out(check_mm_struct, n, 0);
ffffffffc0203002:	4601                	li	a2,0
ffffffffc0203004:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0203006:	ec0d                	bnez	s0,ffffffffc0203040 <alloc_pages+0x7c>
ffffffffc0203008:	029a6c63          	bltu	s4,s1,ffffffffc0203040 <alloc_pages+0x7c>
ffffffffc020300c:	000aa783          	lw	a5,0(s5)
ffffffffc0203010:	2781                	sext.w	a5,a5
ffffffffc0203012:	c79d                	beqz	a5,ffffffffc0203040 <alloc_pages+0x7c>
        swap_out(check_mm_struct, n, 0);
ffffffffc0203014:	000b3503          	ld	a0,0(s6)
ffffffffc0203018:	b38ff0ef          	jal	ra,ffffffffc0202350 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020301c:	100027f3          	csrr	a5,sstatus
ffffffffc0203020:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0203022:	8526                	mv	a0,s1
ffffffffc0203024:	dbf1                	beqz	a5,ffffffffc0202ff8 <alloc_pages+0x34>
        intr_disable();
ffffffffc0203026:	d9efd0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc020302a:	00093783          	ld	a5,0(s2)
ffffffffc020302e:	8526                	mv	a0,s1
ffffffffc0203030:	6f9c                	ld	a5,24(a5)
ffffffffc0203032:	9782                	jalr	a5
ffffffffc0203034:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203036:	d88fd0ef          	jal	ra,ffffffffc02005be <intr_enable>
        swap_out(check_mm_struct, n, 0);
ffffffffc020303a:	4601                	li	a2,0
ffffffffc020303c:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc020303e:	d469                	beqz	s0,ffffffffc0203008 <alloc_pages+0x44>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0203040:	70e2                	ld	ra,56(sp)
ffffffffc0203042:	8522                	mv	a0,s0
ffffffffc0203044:	7442                	ld	s0,48(sp)
ffffffffc0203046:	74a2                	ld	s1,40(sp)
ffffffffc0203048:	7902                	ld	s2,32(sp)
ffffffffc020304a:	69e2                	ld	s3,24(sp)
ffffffffc020304c:	6a42                	ld	s4,16(sp)
ffffffffc020304e:	6aa2                	ld	s5,8(sp)
ffffffffc0203050:	6b02                	ld	s6,0(sp)
ffffffffc0203052:	6121                	addi	sp,sp,64
ffffffffc0203054:	8082                	ret

ffffffffc0203056 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203056:	100027f3          	csrr	a5,sstatus
ffffffffc020305a:	8b89                	andi	a5,a5,2
ffffffffc020305c:	e799                	bnez	a5,ffffffffc020306a <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc020305e:	00013797          	auipc	a5,0x13
ffffffffc0203062:	5427b783          	ld	a5,1346(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc0203066:	739c                	ld	a5,32(a5)
ffffffffc0203068:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc020306a:	1101                	addi	sp,sp,-32
ffffffffc020306c:	ec06                	sd	ra,24(sp)
ffffffffc020306e:	e822                	sd	s0,16(sp)
ffffffffc0203070:	e426                	sd	s1,8(sp)
ffffffffc0203072:	842a                	mv	s0,a0
ffffffffc0203074:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0203076:	d4efd0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020307a:	00013797          	auipc	a5,0x13
ffffffffc020307e:	5267b783          	ld	a5,1318(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc0203082:	739c                	ld	a5,32(a5)
ffffffffc0203084:	85a6                	mv	a1,s1
ffffffffc0203086:	8522                	mv	a0,s0
ffffffffc0203088:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc020308a:	6442                	ld	s0,16(sp)
ffffffffc020308c:	60e2                	ld	ra,24(sp)
ffffffffc020308e:	64a2                	ld	s1,8(sp)
ffffffffc0203090:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0203092:	d2cfd06f          	j	ffffffffc02005be <intr_enable>

ffffffffc0203096 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203096:	100027f3          	csrr	a5,sstatus
ffffffffc020309a:	8b89                	andi	a5,a5,2
ffffffffc020309c:	e799                	bnez	a5,ffffffffc02030aa <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc020309e:	00013797          	auipc	a5,0x13
ffffffffc02030a2:	5027b783          	ld	a5,1282(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc02030a6:	779c                	ld	a5,40(a5)
ffffffffc02030a8:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc02030aa:	1141                	addi	sp,sp,-16
ffffffffc02030ac:	e406                	sd	ra,8(sp)
ffffffffc02030ae:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc02030b0:	d14fd0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02030b4:	00013797          	auipc	a5,0x13
ffffffffc02030b8:	4ec7b783          	ld	a5,1260(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc02030bc:	779c                	ld	a5,40(a5)
ffffffffc02030be:	9782                	jalr	a5
ffffffffc02030c0:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02030c2:	cfcfd0ef          	jal	ra,ffffffffc02005be <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc02030c6:	60a2                	ld	ra,8(sp)
ffffffffc02030c8:	8522                	mv	a0,s0
ffffffffc02030ca:	6402                	ld	s0,0(sp)
ffffffffc02030cc:	0141                	addi	sp,sp,16
ffffffffc02030ce:	8082                	ret

ffffffffc02030d0 <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02030d0:	01e5d793          	srli	a5,a1,0x1e
ffffffffc02030d4:	1ff7f793          	andi	a5,a5,511
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02030d8:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02030da:	078e                	slli	a5,a5,0x3
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02030dc:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc02030de:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V)) {
ffffffffc02030e2:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02030e4:	f04a                	sd	s2,32(sp)
ffffffffc02030e6:	ec4e                	sd	s3,24(sp)
ffffffffc02030e8:	e852                	sd	s4,16(sp)
ffffffffc02030ea:	fc06                	sd	ra,56(sp)
ffffffffc02030ec:	f822                	sd	s0,48(sp)
ffffffffc02030ee:	e456                	sd	s5,8(sp)
ffffffffc02030f0:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc02030f2:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc02030f6:	892e                	mv	s2,a1
ffffffffc02030f8:	89b2                	mv	s3,a2
ffffffffc02030fa:	00013a17          	auipc	s4,0x13
ffffffffc02030fe:	496a0a13          	addi	s4,s4,1174 # ffffffffc0216590 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0203102:	e7b5                	bnez	a5,ffffffffc020316e <get_pte+0x9e>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0203104:	12060b63          	beqz	a2,ffffffffc020323a <get_pte+0x16a>
ffffffffc0203108:	4505                	li	a0,1
ffffffffc020310a:	ebbff0ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc020310e:	842a                	mv	s0,a0
ffffffffc0203110:	12050563          	beqz	a0,ffffffffc020323a <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0203114:	00013b17          	auipc	s6,0x13
ffffffffc0203118:	484b0b13          	addi	s6,s6,1156 # ffffffffc0216598 <pages>
ffffffffc020311c:	000b3503          	ld	a0,0(s6)
ffffffffc0203120:	00080ab7          	lui	s5,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0203124:	00013a17          	auipc	s4,0x13
ffffffffc0203128:	46ca0a13          	addi	s4,s4,1132 # ffffffffc0216590 <npage>
ffffffffc020312c:	40a40533          	sub	a0,s0,a0
ffffffffc0203130:	8519                	srai	a0,a0,0x6
ffffffffc0203132:	9556                	add	a0,a0,s5
ffffffffc0203134:	000a3703          	ld	a4,0(s4)
ffffffffc0203138:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc020313c:	4685                	li	a3,1
ffffffffc020313e:	c014                	sw	a3,0(s0)
ffffffffc0203140:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203142:	0532                	slli	a0,a0,0xc
ffffffffc0203144:	14e7f263          	bgeu	a5,a4,ffffffffc0203288 <get_pte+0x1b8>
ffffffffc0203148:	00013797          	auipc	a5,0x13
ffffffffc020314c:	4607b783          	ld	a5,1120(a5) # ffffffffc02165a8 <va_pa_offset>
ffffffffc0203150:	6605                	lui	a2,0x1
ffffffffc0203152:	4581                	li	a1,0
ffffffffc0203154:	953e                	add	a0,a0,a5
ffffffffc0203156:	1a3010ef          	jal	ra,ffffffffc0204af8 <memset>
    return page - pages + nbase;
ffffffffc020315a:	000b3683          	ld	a3,0(s6)
ffffffffc020315e:	40d406b3          	sub	a3,s0,a3
ffffffffc0203162:	8699                	srai	a3,a3,0x6
ffffffffc0203164:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0203166:	06aa                	slli	a3,a3,0xa
ffffffffc0203168:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc020316c:	e094                	sd	a3,0(s1)
    }
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc020316e:	77fd                	lui	a5,0xfffff
ffffffffc0203170:	068a                	slli	a3,a3,0x2
ffffffffc0203172:	000a3703          	ld	a4,0(s4)
ffffffffc0203176:	8efd                	and	a3,a3,a5
ffffffffc0203178:	00c6d793          	srli	a5,a3,0xc
ffffffffc020317c:	0ce7f163          	bgeu	a5,a4,ffffffffc020323e <get_pte+0x16e>
ffffffffc0203180:	00013a97          	auipc	s5,0x13
ffffffffc0203184:	428a8a93          	addi	s5,s5,1064 # ffffffffc02165a8 <va_pa_offset>
ffffffffc0203188:	000ab403          	ld	s0,0(s5)
ffffffffc020318c:	01595793          	srli	a5,s2,0x15
ffffffffc0203190:	1ff7f793          	andi	a5,a5,511
ffffffffc0203194:	96a2                	add	a3,a3,s0
ffffffffc0203196:	00379413          	slli	s0,a5,0x3
ffffffffc020319a:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) {
ffffffffc020319c:	6014                	ld	a3,0(s0)
ffffffffc020319e:	0016f793          	andi	a5,a3,1
ffffffffc02031a2:	e3ad                	bnez	a5,ffffffffc0203204 <get_pte+0x134>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc02031a4:	08098b63          	beqz	s3,ffffffffc020323a <get_pte+0x16a>
ffffffffc02031a8:	4505                	li	a0,1
ffffffffc02031aa:	e1bff0ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc02031ae:	84aa                	mv	s1,a0
ffffffffc02031b0:	c549                	beqz	a0,ffffffffc020323a <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc02031b2:	00013b17          	auipc	s6,0x13
ffffffffc02031b6:	3e6b0b13          	addi	s6,s6,998 # ffffffffc0216598 <pages>
ffffffffc02031ba:	000b3503          	ld	a0,0(s6)
ffffffffc02031be:	000809b7          	lui	s3,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02031c2:	000a3703          	ld	a4,0(s4)
ffffffffc02031c6:	40a48533          	sub	a0,s1,a0
ffffffffc02031ca:	8519                	srai	a0,a0,0x6
ffffffffc02031cc:	954e                	add	a0,a0,s3
ffffffffc02031ce:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc02031d2:	4685                	li	a3,1
ffffffffc02031d4:	c094                	sw	a3,0(s1)
ffffffffc02031d6:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02031d8:	0532                	slli	a0,a0,0xc
ffffffffc02031da:	08e7fa63          	bgeu	a5,a4,ffffffffc020326e <get_pte+0x19e>
ffffffffc02031de:	000ab783          	ld	a5,0(s5)
ffffffffc02031e2:	6605                	lui	a2,0x1
ffffffffc02031e4:	4581                	li	a1,0
ffffffffc02031e6:	953e                	add	a0,a0,a5
ffffffffc02031e8:	111010ef          	jal	ra,ffffffffc0204af8 <memset>
    return page - pages + nbase;
ffffffffc02031ec:	000b3683          	ld	a3,0(s6)
ffffffffc02031f0:	40d486b3          	sub	a3,s1,a3
ffffffffc02031f4:	8699                	srai	a3,a3,0x6
ffffffffc02031f6:	96ce                	add	a3,a3,s3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02031f8:	06aa                	slli	a3,a3,0xa
ffffffffc02031fa:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc02031fe:	e014                	sd	a3,0(s0)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0203200:	000a3703          	ld	a4,0(s4)
ffffffffc0203204:	068a                	slli	a3,a3,0x2
ffffffffc0203206:	757d                	lui	a0,0xfffff
ffffffffc0203208:	8ee9                	and	a3,a3,a0
ffffffffc020320a:	00c6d793          	srli	a5,a3,0xc
ffffffffc020320e:	04e7f463          	bgeu	a5,a4,ffffffffc0203256 <get_pte+0x186>
ffffffffc0203212:	000ab503          	ld	a0,0(s5)
ffffffffc0203216:	00c95913          	srli	s2,s2,0xc
ffffffffc020321a:	1ff97913          	andi	s2,s2,511
ffffffffc020321e:	96aa                	add	a3,a3,a0
ffffffffc0203220:	00391513          	slli	a0,s2,0x3
ffffffffc0203224:	9536                	add	a0,a0,a3
}
ffffffffc0203226:	70e2                	ld	ra,56(sp)
ffffffffc0203228:	7442                	ld	s0,48(sp)
ffffffffc020322a:	74a2                	ld	s1,40(sp)
ffffffffc020322c:	7902                	ld	s2,32(sp)
ffffffffc020322e:	69e2                	ld	s3,24(sp)
ffffffffc0203230:	6a42                	ld	s4,16(sp)
ffffffffc0203232:	6aa2                	ld	s5,8(sp)
ffffffffc0203234:	6b02                	ld	s6,0(sp)
ffffffffc0203236:	6121                	addi	sp,sp,64
ffffffffc0203238:	8082                	ret
            return NULL;
ffffffffc020323a:	4501                	li	a0,0
ffffffffc020323c:	b7ed                	j	ffffffffc0203226 <get_pte+0x156>
    pde_t *pdep0 = &((pte_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc020323e:	00003617          	auipc	a2,0x3
ffffffffc0203242:	91a60613          	addi	a2,a2,-1766 # ffffffffc0205b58 <commands+0x980>
ffffffffc0203246:	0e400593          	li	a1,228
ffffffffc020324a:	00003517          	auipc	a0,0x3
ffffffffc020324e:	45650513          	addi	a0,a0,1110 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203252:	f77fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0203256:	00003617          	auipc	a2,0x3
ffffffffc020325a:	90260613          	addi	a2,a2,-1790 # ffffffffc0205b58 <commands+0x980>
ffffffffc020325e:	0ef00593          	li	a1,239
ffffffffc0203262:	00003517          	auipc	a0,0x3
ffffffffc0203266:	43e50513          	addi	a0,a0,1086 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc020326a:	f5ffc0ef          	jal	ra,ffffffffc02001c8 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020326e:	86aa                	mv	a3,a0
ffffffffc0203270:	00003617          	auipc	a2,0x3
ffffffffc0203274:	8e860613          	addi	a2,a2,-1816 # ffffffffc0205b58 <commands+0x980>
ffffffffc0203278:	0ec00593          	li	a1,236
ffffffffc020327c:	00003517          	auipc	a0,0x3
ffffffffc0203280:	42450513          	addi	a0,a0,1060 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203284:	f45fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0203288:	86aa                	mv	a3,a0
ffffffffc020328a:	00003617          	auipc	a2,0x3
ffffffffc020328e:	8ce60613          	addi	a2,a2,-1842 # ffffffffc0205b58 <commands+0x980>
ffffffffc0203292:	0e100593          	li	a1,225
ffffffffc0203296:	00003517          	auipc	a0,0x3
ffffffffc020329a:	40a50513          	addi	a0,a0,1034 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc020329e:	f2bfc0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02032a2 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc02032a2:	1141                	addi	sp,sp,-16
ffffffffc02032a4:	e022                	sd	s0,0(sp)
ffffffffc02032a6:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02032a8:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc02032aa:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02032ac:	e25ff0ef          	jal	ra,ffffffffc02030d0 <get_pte>
    if (ptep_store != NULL) {
ffffffffc02032b0:	c011                	beqz	s0,ffffffffc02032b4 <get_page+0x12>
        *ptep_store = ptep;
ffffffffc02032b2:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc02032b4:	c511                	beqz	a0,ffffffffc02032c0 <get_page+0x1e>
ffffffffc02032b6:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc02032b8:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc02032ba:	0017f713          	andi	a4,a5,1
ffffffffc02032be:	e709                	bnez	a4,ffffffffc02032c8 <get_page+0x26>
}
ffffffffc02032c0:	60a2                	ld	ra,8(sp)
ffffffffc02032c2:	6402                	ld	s0,0(sp)
ffffffffc02032c4:	0141                	addi	sp,sp,16
ffffffffc02032c6:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02032c8:	078a                	slli	a5,a5,0x2
ffffffffc02032ca:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02032cc:	00013717          	auipc	a4,0x13
ffffffffc02032d0:	2c473703          	ld	a4,708(a4) # ffffffffc0216590 <npage>
ffffffffc02032d4:	00e7ff63          	bgeu	a5,a4,ffffffffc02032f2 <get_page+0x50>
ffffffffc02032d8:	60a2                	ld	ra,8(sp)
ffffffffc02032da:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc02032dc:	fff80537          	lui	a0,0xfff80
ffffffffc02032e0:	97aa                	add	a5,a5,a0
ffffffffc02032e2:	079a                	slli	a5,a5,0x6
ffffffffc02032e4:	00013517          	auipc	a0,0x13
ffffffffc02032e8:	2b453503          	ld	a0,692(a0) # ffffffffc0216598 <pages>
ffffffffc02032ec:	953e                	add	a0,a0,a5
ffffffffc02032ee:	0141                	addi	sp,sp,16
ffffffffc02032f0:	8082                	ret
ffffffffc02032f2:	c9bff0ef          	jal	ra,ffffffffc0202f8c <pa2page.part.0>

ffffffffc02032f6 <page_remove>:
    }
}

// page_remove - free an Page which is related linear address la and has an
// validated pte
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc02032f6:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02032f8:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc02032fa:	ec26                	sd	s1,24(sp)
ffffffffc02032fc:	f406                	sd	ra,40(sp)
ffffffffc02032fe:	f022                	sd	s0,32(sp)
ffffffffc0203300:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0203302:	dcfff0ef          	jal	ra,ffffffffc02030d0 <get_pte>
    if (ptep != NULL) {
ffffffffc0203306:	c511                	beqz	a0,ffffffffc0203312 <page_remove+0x1c>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0203308:	611c                	ld	a5,0(a0)
ffffffffc020330a:	842a                	mv	s0,a0
ffffffffc020330c:	0017f713          	andi	a4,a5,1
ffffffffc0203310:	e711                	bnez	a4,ffffffffc020331c <page_remove+0x26>
        page_remove_pte(pgdir, la, ptep);
    }
}
ffffffffc0203312:	70a2                	ld	ra,40(sp)
ffffffffc0203314:	7402                	ld	s0,32(sp)
ffffffffc0203316:	64e2                	ld	s1,24(sp)
ffffffffc0203318:	6145                	addi	sp,sp,48
ffffffffc020331a:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc020331c:	078a                	slli	a5,a5,0x2
ffffffffc020331e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203320:	00013717          	auipc	a4,0x13
ffffffffc0203324:	27073703          	ld	a4,624(a4) # ffffffffc0216590 <npage>
ffffffffc0203328:	06e7f363          	bgeu	a5,a4,ffffffffc020338e <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc020332c:	fff80537          	lui	a0,0xfff80
ffffffffc0203330:	97aa                	add	a5,a5,a0
ffffffffc0203332:	079a                	slli	a5,a5,0x6
ffffffffc0203334:	00013517          	auipc	a0,0x13
ffffffffc0203338:	26453503          	ld	a0,612(a0) # ffffffffc0216598 <pages>
ffffffffc020333c:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020333e:	411c                	lw	a5,0(a0)
ffffffffc0203340:	fff7871b          	addiw	a4,a5,-1
ffffffffc0203344:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0203346:	cb11                	beqz	a4,ffffffffc020335a <page_remove+0x64>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0203348:	00043023          	sd	zero,0(s0)
// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    // flush_tlb();
    // The flush_tlb flush the entire TLB, is there any better way?
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020334c:	12048073          	sfence.vma	s1
}
ffffffffc0203350:	70a2                	ld	ra,40(sp)
ffffffffc0203352:	7402                	ld	s0,32(sp)
ffffffffc0203354:	64e2                	ld	s1,24(sp)
ffffffffc0203356:	6145                	addi	sp,sp,48
ffffffffc0203358:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020335a:	100027f3          	csrr	a5,sstatus
ffffffffc020335e:	8b89                	andi	a5,a5,2
ffffffffc0203360:	eb89                	bnez	a5,ffffffffc0203372 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0203362:	00013797          	auipc	a5,0x13
ffffffffc0203366:	23e7b783          	ld	a5,574(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc020336a:	739c                	ld	a5,32(a5)
ffffffffc020336c:	4585                	li	a1,1
ffffffffc020336e:	9782                	jalr	a5
    if (flag) {
ffffffffc0203370:	bfe1                	j	ffffffffc0203348 <page_remove+0x52>
        intr_disable();
ffffffffc0203372:	e42a                	sd	a0,8(sp)
ffffffffc0203374:	a50fd0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc0203378:	00013797          	auipc	a5,0x13
ffffffffc020337c:	2287b783          	ld	a5,552(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc0203380:	739c                	ld	a5,32(a5)
ffffffffc0203382:	6522                	ld	a0,8(sp)
ffffffffc0203384:	4585                	li	a1,1
ffffffffc0203386:	9782                	jalr	a5
        intr_enable();
ffffffffc0203388:	a36fd0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc020338c:	bf75                	j	ffffffffc0203348 <page_remove+0x52>
ffffffffc020338e:	bffff0ef          	jal	ra,ffffffffc0202f8c <pa2page.part.0>

ffffffffc0203392 <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0203392:	7139                	addi	sp,sp,-64
ffffffffc0203394:	e852                	sd	s4,16(sp)
ffffffffc0203396:	8a32                	mv	s4,a2
ffffffffc0203398:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020339a:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc020339c:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020339e:	85d2                	mv	a1,s4
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc02033a0:	f426                	sd	s1,40(sp)
ffffffffc02033a2:	fc06                	sd	ra,56(sp)
ffffffffc02033a4:	f04a                	sd	s2,32(sp)
ffffffffc02033a6:	ec4e                	sd	s3,24(sp)
ffffffffc02033a8:	e456                	sd	s5,8(sp)
ffffffffc02033aa:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc02033ac:	d25ff0ef          	jal	ra,ffffffffc02030d0 <get_pte>
    if (ptep == NULL) {
ffffffffc02033b0:	c961                	beqz	a0,ffffffffc0203480 <page_insert+0xee>
    page->ref += 1;
ffffffffc02033b2:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) {
ffffffffc02033b4:	611c                	ld	a5,0(a0)
ffffffffc02033b6:	89aa                	mv	s3,a0
ffffffffc02033b8:	0016871b          	addiw	a4,a3,1
ffffffffc02033bc:	c018                	sw	a4,0(s0)
ffffffffc02033be:	0017f713          	andi	a4,a5,1
ffffffffc02033c2:	ef05                	bnez	a4,ffffffffc02033fa <page_insert+0x68>
    return page - pages + nbase;
ffffffffc02033c4:	00013717          	auipc	a4,0x13
ffffffffc02033c8:	1d473703          	ld	a4,468(a4) # ffffffffc0216598 <pages>
ffffffffc02033cc:	8c19                	sub	s0,s0,a4
ffffffffc02033ce:	000807b7          	lui	a5,0x80
ffffffffc02033d2:	8419                	srai	s0,s0,0x6
ffffffffc02033d4:	943e                	add	s0,s0,a5
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02033d6:	042a                	slli	s0,s0,0xa
ffffffffc02033d8:	8cc1                	or	s1,s1,s0
ffffffffc02033da:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02033de:	0099b023          	sd	s1,0(s3) # 80000 <kern_entry-0xffffffffc0180000>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02033e2:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc02033e6:	4501                	li	a0,0
}
ffffffffc02033e8:	70e2                	ld	ra,56(sp)
ffffffffc02033ea:	7442                	ld	s0,48(sp)
ffffffffc02033ec:	74a2                	ld	s1,40(sp)
ffffffffc02033ee:	7902                	ld	s2,32(sp)
ffffffffc02033f0:	69e2                	ld	s3,24(sp)
ffffffffc02033f2:	6a42                	ld	s4,16(sp)
ffffffffc02033f4:	6aa2                	ld	s5,8(sp)
ffffffffc02033f6:	6121                	addi	sp,sp,64
ffffffffc02033f8:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc02033fa:	078a                	slli	a5,a5,0x2
ffffffffc02033fc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02033fe:	00013717          	auipc	a4,0x13
ffffffffc0203402:	19273703          	ld	a4,402(a4) # ffffffffc0216590 <npage>
ffffffffc0203406:	06e7ff63          	bgeu	a5,a4,ffffffffc0203484 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc020340a:	00013a97          	auipc	s5,0x13
ffffffffc020340e:	18ea8a93          	addi	s5,s5,398 # ffffffffc0216598 <pages>
ffffffffc0203412:	000ab703          	ld	a4,0(s5)
ffffffffc0203416:	fff80937          	lui	s2,0xfff80
ffffffffc020341a:	993e                	add	s2,s2,a5
ffffffffc020341c:	091a                	slli	s2,s2,0x6
ffffffffc020341e:	993a                	add	s2,s2,a4
        if (p == page) {
ffffffffc0203420:	01240c63          	beq	s0,s2,ffffffffc0203438 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0203424:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fd69a34>
ffffffffc0203428:	fff7869b          	addiw	a3,a5,-1
ffffffffc020342c:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc0203430:	c691                	beqz	a3,ffffffffc020343c <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203432:	120a0073          	sfence.vma	s4
}
ffffffffc0203436:	bf59                	j	ffffffffc02033cc <page_insert+0x3a>
ffffffffc0203438:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc020343a:	bf49                	j	ffffffffc02033cc <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020343c:	100027f3          	csrr	a5,sstatus
ffffffffc0203440:	8b89                	andi	a5,a5,2
ffffffffc0203442:	ef91                	bnez	a5,ffffffffc020345e <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0203444:	00013797          	auipc	a5,0x13
ffffffffc0203448:	15c7b783          	ld	a5,348(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc020344c:	739c                	ld	a5,32(a5)
ffffffffc020344e:	4585                	li	a1,1
ffffffffc0203450:	854a                	mv	a0,s2
ffffffffc0203452:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0203454:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203458:	120a0073          	sfence.vma	s4
ffffffffc020345c:	bf85                	j	ffffffffc02033cc <page_insert+0x3a>
        intr_disable();
ffffffffc020345e:	966fd0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203462:	00013797          	auipc	a5,0x13
ffffffffc0203466:	13e7b783          	ld	a5,318(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc020346a:	739c                	ld	a5,32(a5)
ffffffffc020346c:	4585                	li	a1,1
ffffffffc020346e:	854a                	mv	a0,s2
ffffffffc0203470:	9782                	jalr	a5
        intr_enable();
ffffffffc0203472:	94cfd0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203476:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020347a:	120a0073          	sfence.vma	s4
ffffffffc020347e:	b7b9                	j	ffffffffc02033cc <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0203480:	5571                	li	a0,-4
ffffffffc0203482:	b79d                	j	ffffffffc02033e8 <page_insert+0x56>
ffffffffc0203484:	b09ff0ef          	jal	ra,ffffffffc0202f8c <pa2page.part.0>

ffffffffc0203488 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0203488:	00003797          	auipc	a5,0x3
ffffffffc020348c:	1e078793          	addi	a5,a5,480 # ffffffffc0206668 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0203490:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0203492:	711d                	addi	sp,sp,-96
ffffffffc0203494:	ec5e                	sd	s7,24(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0203496:	00003517          	auipc	a0,0x3
ffffffffc020349a:	21a50513          	addi	a0,a0,538 # ffffffffc02066b0 <default_pmm_manager+0x48>
    pmm_manager = &default_pmm_manager;
ffffffffc020349e:	00013b97          	auipc	s7,0x13
ffffffffc02034a2:	102b8b93          	addi	s7,s7,258 # ffffffffc02165a0 <pmm_manager>
void pmm_init(void) {
ffffffffc02034a6:	ec86                	sd	ra,88(sp)
ffffffffc02034a8:	e4a6                	sd	s1,72(sp)
ffffffffc02034aa:	fc4e                	sd	s3,56(sp)
ffffffffc02034ac:	f05a                	sd	s6,32(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc02034ae:	00fbb023          	sd	a5,0(s7)
void pmm_init(void) {
ffffffffc02034b2:	e8a2                	sd	s0,80(sp)
ffffffffc02034b4:	e0ca                	sd	s2,64(sp)
ffffffffc02034b6:	f852                	sd	s4,48(sp)
ffffffffc02034b8:	f456                	sd	s5,40(sp)
ffffffffc02034ba:	e862                	sd	s8,16(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02034bc:	c11fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    pmm_manager->init();
ffffffffc02034c0:	000bb783          	ld	a5,0(s7)
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02034c4:	00013997          	auipc	s3,0x13
ffffffffc02034c8:	0e498993          	addi	s3,s3,228 # ffffffffc02165a8 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc02034cc:	00013497          	auipc	s1,0x13
ffffffffc02034d0:	0c448493          	addi	s1,s1,196 # ffffffffc0216590 <npage>
    pmm_manager->init();
ffffffffc02034d4:	679c                	ld	a5,8(a5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02034d6:	00013b17          	auipc	s6,0x13
ffffffffc02034da:	0c2b0b13          	addi	s6,s6,194 # ffffffffc0216598 <pages>
    pmm_manager->init();
ffffffffc02034de:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02034e0:	57f5                	li	a5,-3
ffffffffc02034e2:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc02034e4:	00003517          	auipc	a0,0x3
ffffffffc02034e8:	1e450513          	addi	a0,a0,484 # ffffffffc02066c8 <default_pmm_manager+0x60>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc02034ec:	00f9b023          	sd	a5,0(s3)
    cprintf("physcial memory map:\n");
ffffffffc02034f0:	bddfc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02034f4:	46c5                	li	a3,17
ffffffffc02034f6:	06ee                	slli	a3,a3,0x1b
ffffffffc02034f8:	40100613          	li	a2,1025
ffffffffc02034fc:	07e005b7          	lui	a1,0x7e00
ffffffffc0203500:	16fd                	addi	a3,a3,-1
ffffffffc0203502:	0656                	slli	a2,a2,0x15
ffffffffc0203504:	00003517          	auipc	a0,0x3
ffffffffc0203508:	1dc50513          	addi	a0,a0,476 # ffffffffc02066e0 <default_pmm_manager+0x78>
ffffffffc020350c:	bc1fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0203510:	777d                	lui	a4,0xfffff
ffffffffc0203512:	00014797          	auipc	a5,0x14
ffffffffc0203516:	0b978793          	addi	a5,a5,185 # ffffffffc02175cb <end+0xfff>
ffffffffc020351a:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc020351c:	00088737          	lui	a4,0x88
ffffffffc0203520:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0203522:	00fb3023          	sd	a5,0(s6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0203526:	4701                	li	a4,0
ffffffffc0203528:	4585                	li	a1,1
ffffffffc020352a:	fff80837          	lui	a6,0xfff80
ffffffffc020352e:	a019                	j	ffffffffc0203534 <pmm_init+0xac>
        SetPageReserved(pages + i);
ffffffffc0203530:	000b3783          	ld	a5,0(s6)
ffffffffc0203534:	00671693          	slli	a3,a4,0x6
ffffffffc0203538:	97b6                	add	a5,a5,a3
ffffffffc020353a:	07a1                	addi	a5,a5,8
ffffffffc020353c:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0203540:	6090                	ld	a2,0(s1)
ffffffffc0203542:	0705                	addi	a4,a4,1
ffffffffc0203544:	010607b3          	add	a5,a2,a6
ffffffffc0203548:	fef764e3          	bltu	a4,a5,ffffffffc0203530 <pmm_init+0xa8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020354c:	000b3503          	ld	a0,0(s6)
ffffffffc0203550:	079a                	slli	a5,a5,0x6
ffffffffc0203552:	c0200737          	lui	a4,0xc0200
ffffffffc0203556:	00f506b3          	add	a3,a0,a5
ffffffffc020355a:	60e6e563          	bltu	a3,a4,ffffffffc0203b64 <pmm_init+0x6dc>
ffffffffc020355e:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) {
ffffffffc0203562:	4745                	li	a4,17
ffffffffc0203564:	076e                	slli	a4,a4,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0203566:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) {
ffffffffc0203568:	4ae6e563          	bltu	a3,a4,ffffffffc0203a12 <pmm_init+0x58a>
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc020356c:	00003517          	auipc	a0,0x3
ffffffffc0203570:	19c50513          	addi	a0,a0,412 # ffffffffc0206708 <default_pmm_manager+0xa0>
ffffffffc0203574:	b59fc0ef          	jal	ra,ffffffffc02000cc <cprintf>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0203578:	000bb783          	ld	a5,0(s7)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc020357c:	00013917          	auipc	s2,0x13
ffffffffc0203580:	00c90913          	addi	s2,s2,12 # ffffffffc0216588 <boot_pgdir>
    pmm_manager->check();
ffffffffc0203584:	7b9c                	ld	a5,48(a5)
ffffffffc0203586:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0203588:	00003517          	auipc	a0,0x3
ffffffffc020358c:	19850513          	addi	a0,a0,408 # ffffffffc0206720 <default_pmm_manager+0xb8>
ffffffffc0203590:	b3dfc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0203594:	00007697          	auipc	a3,0x7
ffffffffc0203598:	a6c68693          	addi	a3,a3,-1428 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc020359c:	00d93023          	sd	a3,0(s2)
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02035a0:	c02007b7          	lui	a5,0xc0200
ffffffffc02035a4:	5cf6ec63          	bltu	a3,a5,ffffffffc0203b7c <pmm_init+0x6f4>
ffffffffc02035a8:	0009b783          	ld	a5,0(s3)
ffffffffc02035ac:	8e9d                	sub	a3,a3,a5
ffffffffc02035ae:	00013797          	auipc	a5,0x13
ffffffffc02035b2:	fcd7b923          	sd	a3,-46(a5) # ffffffffc0216580 <boot_cr3>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02035b6:	100027f3          	csrr	a5,sstatus
ffffffffc02035ba:	8b89                	andi	a5,a5,2
ffffffffc02035bc:	48079263          	bnez	a5,ffffffffc0203a40 <pmm_init+0x5b8>
        ret = pmm_manager->nr_free_pages();
ffffffffc02035c0:	000bb783          	ld	a5,0(s7)
ffffffffc02035c4:	779c                	ld	a5,40(a5)
ffffffffc02035c6:	9782                	jalr	a5
ffffffffc02035c8:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02035ca:	6098                	ld	a4,0(s1)
ffffffffc02035cc:	c80007b7          	lui	a5,0xc8000
ffffffffc02035d0:	83b1                	srli	a5,a5,0xc
ffffffffc02035d2:	5ee7e163          	bltu	a5,a4,ffffffffc0203bb4 <pmm_init+0x72c>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02035d6:	00093503          	ld	a0,0(s2)
ffffffffc02035da:	5a050d63          	beqz	a0,ffffffffc0203b94 <pmm_init+0x70c>
ffffffffc02035de:	03451793          	slli	a5,a0,0x34
ffffffffc02035e2:	5a079963          	bnez	a5,ffffffffc0203b94 <pmm_init+0x70c>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02035e6:	4601                	li	a2,0
ffffffffc02035e8:	4581                	li	a1,0
ffffffffc02035ea:	cb9ff0ef          	jal	ra,ffffffffc02032a2 <get_page>
ffffffffc02035ee:	62051563          	bnez	a0,ffffffffc0203c18 <pmm_init+0x790>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc02035f2:	4505                	li	a0,1
ffffffffc02035f4:	9d1ff0ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc02035f8:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc02035fa:	00093503          	ld	a0,0(s2)
ffffffffc02035fe:	4681                	li	a3,0
ffffffffc0203600:	4601                	li	a2,0
ffffffffc0203602:	85d2                	mv	a1,s4
ffffffffc0203604:	d8fff0ef          	jal	ra,ffffffffc0203392 <page_insert>
ffffffffc0203608:	5e051863          	bnez	a0,ffffffffc0203bf8 <pmm_init+0x770>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc020360c:	00093503          	ld	a0,0(s2)
ffffffffc0203610:	4601                	li	a2,0
ffffffffc0203612:	4581                	li	a1,0
ffffffffc0203614:	abdff0ef          	jal	ra,ffffffffc02030d0 <get_pte>
ffffffffc0203618:	5c050063          	beqz	a0,ffffffffc0203bd8 <pmm_init+0x750>
    assert(pte2page(*ptep) == p1);
ffffffffc020361c:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc020361e:	0017f713          	andi	a4,a5,1
ffffffffc0203622:	5a070963          	beqz	a4,ffffffffc0203bd4 <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc0203626:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203628:	078a                	slli	a5,a5,0x2
ffffffffc020362a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020362c:	52e7fa63          	bgeu	a5,a4,ffffffffc0203b60 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0203630:	000b3683          	ld	a3,0(s6)
ffffffffc0203634:	fff80637          	lui	a2,0xfff80
ffffffffc0203638:	97b2                	add	a5,a5,a2
ffffffffc020363a:	079a                	slli	a5,a5,0x6
ffffffffc020363c:	97b6                	add	a5,a5,a3
ffffffffc020363e:	10fa16e3          	bne	s4,a5,ffffffffc0203f4a <pmm_init+0xac2>
    assert(page_ref(p1) == 1);
ffffffffc0203642:	000a2683          	lw	a3,0(s4)
ffffffffc0203646:	4785                	li	a5,1
ffffffffc0203648:	12f69de3          	bne	a3,a5,ffffffffc0203f82 <pmm_init+0xafa>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc020364c:	00093503          	ld	a0,0(s2)
ffffffffc0203650:	77fd                	lui	a5,0xfffff
ffffffffc0203652:	6114                	ld	a3,0(a0)
ffffffffc0203654:	068a                	slli	a3,a3,0x2
ffffffffc0203656:	8efd                	and	a3,a3,a5
ffffffffc0203658:	00c6d613          	srli	a2,a3,0xc
ffffffffc020365c:	10e677e3          	bgeu	a2,a4,ffffffffc0203f6a <pmm_init+0xae2>
ffffffffc0203660:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203664:	96e2                	add	a3,a3,s8
ffffffffc0203666:	0006ba83          	ld	s5,0(a3)
ffffffffc020366a:	0a8a                	slli	s5,s5,0x2
ffffffffc020366c:	00fafab3          	and	s5,s5,a5
ffffffffc0203670:	00cad793          	srli	a5,s5,0xc
ffffffffc0203674:	62e7f263          	bgeu	a5,a4,ffffffffc0203c98 <pmm_init+0x810>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0203678:	4601                	li	a2,0
ffffffffc020367a:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020367c:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc020367e:	a53ff0ef          	jal	ra,ffffffffc02030d0 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203682:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0203684:	5f551a63          	bne	a0,s5,ffffffffc0203c78 <pmm_init+0x7f0>

    p2 = alloc_page();
ffffffffc0203688:	4505                	li	a0,1
ffffffffc020368a:	93bff0ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc020368e:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203690:	00093503          	ld	a0,0(s2)
ffffffffc0203694:	46d1                	li	a3,20
ffffffffc0203696:	6605                	lui	a2,0x1
ffffffffc0203698:	85d6                	mv	a1,s5
ffffffffc020369a:	cf9ff0ef          	jal	ra,ffffffffc0203392 <page_insert>
ffffffffc020369e:	58051d63          	bnez	a0,ffffffffc0203c38 <pmm_init+0x7b0>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02036a2:	00093503          	ld	a0,0(s2)
ffffffffc02036a6:	4601                	li	a2,0
ffffffffc02036a8:	6585                	lui	a1,0x1
ffffffffc02036aa:	a27ff0ef          	jal	ra,ffffffffc02030d0 <get_pte>
ffffffffc02036ae:	0e050ae3          	beqz	a0,ffffffffc0203fa2 <pmm_init+0xb1a>
    assert(*ptep & PTE_U);
ffffffffc02036b2:	611c                	ld	a5,0(a0)
ffffffffc02036b4:	0107f713          	andi	a4,a5,16
ffffffffc02036b8:	6e070d63          	beqz	a4,ffffffffc0203db2 <pmm_init+0x92a>
    assert(*ptep & PTE_W);
ffffffffc02036bc:	8b91                	andi	a5,a5,4
ffffffffc02036be:	6a078a63          	beqz	a5,ffffffffc0203d72 <pmm_init+0x8ea>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc02036c2:	00093503          	ld	a0,0(s2)
ffffffffc02036c6:	611c                	ld	a5,0(a0)
ffffffffc02036c8:	8bc1                	andi	a5,a5,16
ffffffffc02036ca:	68078463          	beqz	a5,ffffffffc0203d52 <pmm_init+0x8ca>
    assert(page_ref(p2) == 1);
ffffffffc02036ce:	000aa703          	lw	a4,0(s5)
ffffffffc02036d2:	4785                	li	a5,1
ffffffffc02036d4:	58f71263          	bne	a4,a5,ffffffffc0203c58 <pmm_init+0x7d0>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02036d8:	4681                	li	a3,0
ffffffffc02036da:	6605                	lui	a2,0x1
ffffffffc02036dc:	85d2                	mv	a1,s4
ffffffffc02036de:	cb5ff0ef          	jal	ra,ffffffffc0203392 <page_insert>
ffffffffc02036e2:	62051863          	bnez	a0,ffffffffc0203d12 <pmm_init+0x88a>
    assert(page_ref(p1) == 2);
ffffffffc02036e6:	000a2703          	lw	a4,0(s4)
ffffffffc02036ea:	4789                	li	a5,2
ffffffffc02036ec:	60f71363          	bne	a4,a5,ffffffffc0203cf2 <pmm_init+0x86a>
    assert(page_ref(p2) == 0);
ffffffffc02036f0:	000aa783          	lw	a5,0(s5)
ffffffffc02036f4:	5c079f63          	bnez	a5,ffffffffc0203cd2 <pmm_init+0x84a>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02036f8:	00093503          	ld	a0,0(s2)
ffffffffc02036fc:	4601                	li	a2,0
ffffffffc02036fe:	6585                	lui	a1,0x1
ffffffffc0203700:	9d1ff0ef          	jal	ra,ffffffffc02030d0 <get_pte>
ffffffffc0203704:	5a050763          	beqz	a0,ffffffffc0203cb2 <pmm_init+0x82a>
    assert(pte2page(*ptep) == p1);
ffffffffc0203708:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc020370a:	00177793          	andi	a5,a4,1
ffffffffc020370e:	4c078363          	beqz	a5,ffffffffc0203bd4 <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc0203712:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203714:	00271793          	slli	a5,a4,0x2
ffffffffc0203718:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020371a:	44d7f363          	bgeu	a5,a3,ffffffffc0203b60 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc020371e:	000b3683          	ld	a3,0(s6)
ffffffffc0203722:	fff80637          	lui	a2,0xfff80
ffffffffc0203726:	97b2                	add	a5,a5,a2
ffffffffc0203728:	079a                	slli	a5,a5,0x6
ffffffffc020372a:	97b6                	add	a5,a5,a3
ffffffffc020372c:	6efa1363          	bne	s4,a5,ffffffffc0203e12 <pmm_init+0x98a>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203730:	8b41                	andi	a4,a4,16
ffffffffc0203732:	6c071063          	bnez	a4,ffffffffc0203df2 <pmm_init+0x96a>

    page_remove(boot_pgdir, 0x0);
ffffffffc0203736:	00093503          	ld	a0,0(s2)
ffffffffc020373a:	4581                	li	a1,0
ffffffffc020373c:	bbbff0ef          	jal	ra,ffffffffc02032f6 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0203740:	000a2703          	lw	a4,0(s4)
ffffffffc0203744:	4785                	li	a5,1
ffffffffc0203746:	68f71663          	bne	a4,a5,ffffffffc0203dd2 <pmm_init+0x94a>
    assert(page_ref(p2) == 0);
ffffffffc020374a:	000aa783          	lw	a5,0(s5)
ffffffffc020374e:	74079e63          	bnez	a5,ffffffffc0203eaa <pmm_init+0xa22>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0203752:	00093503          	ld	a0,0(s2)
ffffffffc0203756:	6585                	lui	a1,0x1
ffffffffc0203758:	b9fff0ef          	jal	ra,ffffffffc02032f6 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc020375c:	000a2783          	lw	a5,0(s4)
ffffffffc0203760:	72079563          	bnez	a5,ffffffffc0203e8a <pmm_init+0xa02>
    assert(page_ref(p2) == 0);
ffffffffc0203764:	000aa783          	lw	a5,0(s5)
ffffffffc0203768:	70079163          	bnez	a5,ffffffffc0203e6a <pmm_init+0x9e2>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc020376c:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0203770:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203772:	000a3683          	ld	a3,0(s4)
ffffffffc0203776:	068a                	slli	a3,a3,0x2
ffffffffc0203778:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc020377a:	3ee6f363          	bgeu	a3,a4,ffffffffc0203b60 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc020377e:	fff807b7          	lui	a5,0xfff80
ffffffffc0203782:	000b3503          	ld	a0,0(s6)
ffffffffc0203786:	96be                	add	a3,a3,a5
ffffffffc0203788:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc020378a:	00d507b3          	add	a5,a0,a3
ffffffffc020378e:	4390                	lw	a2,0(a5)
ffffffffc0203790:	4785                	li	a5,1
ffffffffc0203792:	6af61c63          	bne	a2,a5,ffffffffc0203e4a <pmm_init+0x9c2>
    return page - pages + nbase;
ffffffffc0203796:	8699                	srai	a3,a3,0x6
ffffffffc0203798:	000805b7          	lui	a1,0x80
ffffffffc020379c:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc020379e:	00c69613          	slli	a2,a3,0xc
ffffffffc02037a2:	8231                	srli	a2,a2,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02037a4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02037a6:	68e67663          	bgeu	a2,a4,ffffffffc0203e32 <pmm_init+0x9aa>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc02037aa:	0009b603          	ld	a2,0(s3)
ffffffffc02037ae:	96b2                	add	a3,a3,a2
    return pa2page(PDE_ADDR(pde));
ffffffffc02037b0:	629c                	ld	a5,0(a3)
ffffffffc02037b2:	078a                	slli	a5,a5,0x2
ffffffffc02037b4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02037b6:	3ae7f563          	bgeu	a5,a4,ffffffffc0203b60 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc02037ba:	8f8d                	sub	a5,a5,a1
ffffffffc02037bc:	079a                	slli	a5,a5,0x6
ffffffffc02037be:	953e                	add	a0,a0,a5
ffffffffc02037c0:	100027f3          	csrr	a5,sstatus
ffffffffc02037c4:	8b89                	andi	a5,a5,2
ffffffffc02037c6:	2c079763          	bnez	a5,ffffffffc0203a94 <pmm_init+0x60c>
        pmm_manager->free_pages(base, n);
ffffffffc02037ca:	000bb783          	ld	a5,0(s7)
ffffffffc02037ce:	4585                	li	a1,1
ffffffffc02037d0:	739c                	ld	a5,32(a5)
ffffffffc02037d2:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02037d4:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc02037d8:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02037da:	078a                	slli	a5,a5,0x2
ffffffffc02037dc:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02037de:	38e7f163          	bgeu	a5,a4,ffffffffc0203b60 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc02037e2:	000b3503          	ld	a0,0(s6)
ffffffffc02037e6:	fff80737          	lui	a4,0xfff80
ffffffffc02037ea:	97ba                	add	a5,a5,a4
ffffffffc02037ec:	079a                	slli	a5,a5,0x6
ffffffffc02037ee:	953e                	add	a0,a0,a5
ffffffffc02037f0:	100027f3          	csrr	a5,sstatus
ffffffffc02037f4:	8b89                	andi	a5,a5,2
ffffffffc02037f6:	28079363          	bnez	a5,ffffffffc0203a7c <pmm_init+0x5f4>
ffffffffc02037fa:	000bb783          	ld	a5,0(s7)
ffffffffc02037fe:	4585                	li	a1,1
ffffffffc0203800:	739c                	ld	a5,32(a5)
ffffffffc0203802:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0203804:	00093783          	ld	a5,0(s2)
ffffffffc0203808:	0007b023          	sd	zero,0(a5) # fffffffffff80000 <end+0x3fd69a34>
  asm volatile("sfence.vma");
ffffffffc020380c:	12000073          	sfence.vma
ffffffffc0203810:	100027f3          	csrr	a5,sstatus
ffffffffc0203814:	8b89                	andi	a5,a5,2
ffffffffc0203816:	24079963          	bnez	a5,ffffffffc0203a68 <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc020381a:	000bb783          	ld	a5,0(s7)
ffffffffc020381e:	779c                	ld	a5,40(a5)
ffffffffc0203820:	9782                	jalr	a5
ffffffffc0203822:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0203824:	71441363          	bne	s0,s4,ffffffffc0203f2a <pmm_init+0xaa2>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0203828:	00003517          	auipc	a0,0x3
ffffffffc020382c:	1e050513          	addi	a0,a0,480 # ffffffffc0206a08 <default_pmm_manager+0x3a0>
ffffffffc0203830:	89dfc0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0203834:	100027f3          	csrr	a5,sstatus
ffffffffc0203838:	8b89                	andi	a5,a5,2
ffffffffc020383a:	20079d63          	bnez	a5,ffffffffc0203a54 <pmm_init+0x5cc>
        ret = pmm_manager->nr_free_pages();
ffffffffc020383e:	000bb783          	ld	a5,0(s7)
ffffffffc0203842:	779c                	ld	a5,40(a5)
ffffffffc0203844:	9782                	jalr	a5
ffffffffc0203846:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0203848:	6098                	ld	a4,0(s1)
ffffffffc020384a:	c0200437          	lui	s0,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc020384e:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0203850:	00c71793          	slli	a5,a4,0xc
ffffffffc0203854:	6a05                	lui	s4,0x1
ffffffffc0203856:	02f47c63          	bgeu	s0,a5,ffffffffc020388e <pmm_init+0x406>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc020385a:	00c45793          	srli	a5,s0,0xc
ffffffffc020385e:	00093503          	ld	a0,0(s2)
ffffffffc0203862:	2ee7f263          	bgeu	a5,a4,ffffffffc0203b46 <pmm_init+0x6be>
ffffffffc0203866:	0009b583          	ld	a1,0(s3)
ffffffffc020386a:	4601                	li	a2,0
ffffffffc020386c:	95a2                	add	a1,a1,s0
ffffffffc020386e:	863ff0ef          	jal	ra,ffffffffc02030d0 <get_pte>
ffffffffc0203872:	2a050a63          	beqz	a0,ffffffffc0203b26 <pmm_init+0x69e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0203876:	611c                	ld	a5,0(a0)
ffffffffc0203878:	078a                	slli	a5,a5,0x2
ffffffffc020387a:	0157f7b3          	and	a5,a5,s5
ffffffffc020387e:	28879463          	bne	a5,s0,ffffffffc0203b06 <pmm_init+0x67e>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0203882:	6098                	ld	a4,0(s1)
ffffffffc0203884:	9452                	add	s0,s0,s4
ffffffffc0203886:	00c71793          	slli	a5,a4,0xc
ffffffffc020388a:	fcf468e3          	bltu	s0,a5,ffffffffc020385a <pmm_init+0x3d2>
    }

    assert(boot_pgdir[0] == 0);
ffffffffc020388e:	00093783          	ld	a5,0(s2)
ffffffffc0203892:	639c                	ld	a5,0(a5)
ffffffffc0203894:	66079b63          	bnez	a5,ffffffffc0203f0a <pmm_init+0xa82>

    struct Page *p;
    p = alloc_page();
ffffffffc0203898:	4505                	li	a0,1
ffffffffc020389a:	f2aff0ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc020389e:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc02038a0:	00093503          	ld	a0,0(s2)
ffffffffc02038a4:	4699                	li	a3,6
ffffffffc02038a6:	10000613          	li	a2,256
ffffffffc02038aa:	85d6                	mv	a1,s5
ffffffffc02038ac:	ae7ff0ef          	jal	ra,ffffffffc0203392 <page_insert>
ffffffffc02038b0:	62051d63          	bnez	a0,ffffffffc0203eea <pmm_init+0xa62>
    assert(page_ref(p) == 1);
ffffffffc02038b4:	000aa703          	lw	a4,0(s5) # fffffffffffff000 <end+0x3fde8a34>
ffffffffc02038b8:	4785                	li	a5,1
ffffffffc02038ba:	60f71863          	bne	a4,a5,ffffffffc0203eca <pmm_init+0xa42>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02038be:	00093503          	ld	a0,0(s2)
ffffffffc02038c2:	6405                	lui	s0,0x1
ffffffffc02038c4:	4699                	li	a3,6
ffffffffc02038c6:	10040613          	addi	a2,s0,256 # 1100 <kern_entry-0xffffffffc01fef00>
ffffffffc02038ca:	85d6                	mv	a1,s5
ffffffffc02038cc:	ac7ff0ef          	jal	ra,ffffffffc0203392 <page_insert>
ffffffffc02038d0:	46051163          	bnez	a0,ffffffffc0203d32 <pmm_init+0x8aa>
    assert(page_ref(p) == 2);
ffffffffc02038d4:	000aa703          	lw	a4,0(s5)
ffffffffc02038d8:	4789                	li	a5,2
ffffffffc02038da:	72f71463          	bne	a4,a5,ffffffffc0204002 <pmm_init+0xb7a>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc02038de:	00003597          	auipc	a1,0x3
ffffffffc02038e2:	26258593          	addi	a1,a1,610 # ffffffffc0206b40 <default_pmm_manager+0x4d8>
ffffffffc02038e6:	10000513          	li	a0,256
ffffffffc02038ea:	1c8010ef          	jal	ra,ffffffffc0204ab2 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02038ee:	10040593          	addi	a1,s0,256
ffffffffc02038f2:	10000513          	li	a0,256
ffffffffc02038f6:	1ce010ef          	jal	ra,ffffffffc0204ac4 <strcmp>
ffffffffc02038fa:	6e051463          	bnez	a0,ffffffffc0203fe2 <pmm_init+0xb5a>
    return page - pages + nbase;
ffffffffc02038fe:	000b3683          	ld	a3,0(s6)
ffffffffc0203902:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0203906:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0203908:	40da86b3          	sub	a3,s5,a3
ffffffffc020390c:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020390e:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0203910:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0203912:	8031                	srli	s0,s0,0xc
ffffffffc0203914:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203918:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020391a:	50f77c63          	bgeu	a4,a5,ffffffffc0203e32 <pmm_init+0x9aa>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020391e:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203922:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0203926:	96be                	add	a3,a3,a5
ffffffffc0203928:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc020392c:	150010ef          	jal	ra,ffffffffc0204a7c <strlen>
ffffffffc0203930:	68051963          	bnez	a0,ffffffffc0203fc2 <pmm_init+0xb3a>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0203934:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0203938:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020393a:	000a3683          	ld	a3,0(s4) # 1000 <kern_entry-0xffffffffc01ff000>
ffffffffc020393e:	068a                	slli	a3,a3,0x2
ffffffffc0203940:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203942:	20f6ff63          	bgeu	a3,a5,ffffffffc0203b60 <pmm_init+0x6d8>
    return KADDR(page2pa(page));
ffffffffc0203946:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0203948:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020394a:	4ef47463          	bgeu	s0,a5,ffffffffc0203e32 <pmm_init+0x9aa>
ffffffffc020394e:	0009b403          	ld	s0,0(s3)
ffffffffc0203952:	9436                	add	s0,s0,a3
ffffffffc0203954:	100027f3          	csrr	a5,sstatus
ffffffffc0203958:	8b89                	andi	a5,a5,2
ffffffffc020395a:	18079b63          	bnez	a5,ffffffffc0203af0 <pmm_init+0x668>
        pmm_manager->free_pages(base, n);
ffffffffc020395e:	000bb783          	ld	a5,0(s7)
ffffffffc0203962:	4585                	li	a1,1
ffffffffc0203964:	8556                	mv	a0,s5
ffffffffc0203966:	739c                	ld	a5,32(a5)
ffffffffc0203968:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020396a:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc020396c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020396e:	078a                	slli	a5,a5,0x2
ffffffffc0203970:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203972:	1ee7f763          	bgeu	a5,a4,ffffffffc0203b60 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0203976:	000b3503          	ld	a0,0(s6)
ffffffffc020397a:	fff80737          	lui	a4,0xfff80
ffffffffc020397e:	97ba                	add	a5,a5,a4
ffffffffc0203980:	079a                	slli	a5,a5,0x6
ffffffffc0203982:	953e                	add	a0,a0,a5
ffffffffc0203984:	100027f3          	csrr	a5,sstatus
ffffffffc0203988:	8b89                	andi	a5,a5,2
ffffffffc020398a:	14079763          	bnez	a5,ffffffffc0203ad8 <pmm_init+0x650>
ffffffffc020398e:	000bb783          	ld	a5,0(s7)
ffffffffc0203992:	4585                	li	a1,1
ffffffffc0203994:	739c                	ld	a5,32(a5)
ffffffffc0203996:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0203998:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc020399c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020399e:	078a                	slli	a5,a5,0x2
ffffffffc02039a0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02039a2:	1ae7ff63          	bgeu	a5,a4,ffffffffc0203b60 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc02039a6:	000b3503          	ld	a0,0(s6)
ffffffffc02039aa:	fff80737          	lui	a4,0xfff80
ffffffffc02039ae:	97ba                	add	a5,a5,a4
ffffffffc02039b0:	079a                	slli	a5,a5,0x6
ffffffffc02039b2:	953e                	add	a0,a0,a5
ffffffffc02039b4:	100027f3          	csrr	a5,sstatus
ffffffffc02039b8:	8b89                	andi	a5,a5,2
ffffffffc02039ba:	10079363          	bnez	a5,ffffffffc0203ac0 <pmm_init+0x638>
ffffffffc02039be:	000bb783          	ld	a5,0(s7)
ffffffffc02039c2:	4585                	li	a1,1
ffffffffc02039c4:	739c                	ld	a5,32(a5)
ffffffffc02039c6:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc02039c8:	00093783          	ld	a5,0(s2)
ffffffffc02039cc:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc02039d0:	12000073          	sfence.vma
ffffffffc02039d4:	100027f3          	csrr	a5,sstatus
ffffffffc02039d8:	8b89                	andi	a5,a5,2
ffffffffc02039da:	0c079963          	bnez	a5,ffffffffc0203aac <pmm_init+0x624>
        ret = pmm_manager->nr_free_pages();
ffffffffc02039de:	000bb783          	ld	a5,0(s7)
ffffffffc02039e2:	779c                	ld	a5,40(a5)
ffffffffc02039e4:	9782                	jalr	a5
ffffffffc02039e6:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc02039e8:	3a8c1563          	bne	s8,s0,ffffffffc0203d92 <pmm_init+0x90a>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc02039ec:	00003517          	auipc	a0,0x3
ffffffffc02039f0:	1cc50513          	addi	a0,a0,460 # ffffffffc0206bb8 <default_pmm_manager+0x550>
ffffffffc02039f4:	ed8fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc02039f8:	6446                	ld	s0,80(sp)
ffffffffc02039fa:	60e6                	ld	ra,88(sp)
ffffffffc02039fc:	64a6                	ld	s1,72(sp)
ffffffffc02039fe:	6906                	ld	s2,64(sp)
ffffffffc0203a00:	79e2                	ld	s3,56(sp)
ffffffffc0203a02:	7a42                	ld	s4,48(sp)
ffffffffc0203a04:	7aa2                	ld	s5,40(sp)
ffffffffc0203a06:	7b02                	ld	s6,32(sp)
ffffffffc0203a08:	6be2                	ld	s7,24(sp)
ffffffffc0203a0a:	6c42                	ld	s8,16(sp)
ffffffffc0203a0c:	6125                	addi	sp,sp,96
    kmalloc_init();
ffffffffc0203a0e:	80efe06f          	j	ffffffffc0201a1c <kmalloc_init>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0203a12:	6785                	lui	a5,0x1
ffffffffc0203a14:	17fd                	addi	a5,a5,-1
ffffffffc0203a16:	96be                	add	a3,a3,a5
ffffffffc0203a18:	77fd                	lui	a5,0xfffff
ffffffffc0203a1a:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage) {
ffffffffc0203a1c:	00c7d693          	srli	a3,a5,0xc
ffffffffc0203a20:	14c6f063          	bgeu	a3,a2,ffffffffc0203b60 <pmm_init+0x6d8>
    pmm_manager->init_memmap(base, n);
ffffffffc0203a24:	000bb603          	ld	a2,0(s7)
    return &pages[PPN(pa) - nbase];
ffffffffc0203a28:	96c2                	add	a3,a3,a6
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0203a2a:	40f707b3          	sub	a5,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0203a2e:	6a10                	ld	a2,16(a2)
ffffffffc0203a30:	069a                	slli	a3,a3,0x6
ffffffffc0203a32:	00c7d593          	srli	a1,a5,0xc
ffffffffc0203a36:	9536                	add	a0,a0,a3
ffffffffc0203a38:	9602                	jalr	a2
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0203a3a:	0009b583          	ld	a1,0(s3)
}
ffffffffc0203a3e:	b63d                	j	ffffffffc020356c <pmm_init+0xe4>
        intr_disable();
ffffffffc0203a40:	b85fc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0203a44:	000bb783          	ld	a5,0(s7)
ffffffffc0203a48:	779c                	ld	a5,40(a5)
ffffffffc0203a4a:	9782                	jalr	a5
ffffffffc0203a4c:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203a4e:	b71fc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203a52:	bea5                	j	ffffffffc02035ca <pmm_init+0x142>
        intr_disable();
ffffffffc0203a54:	b71fc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc0203a58:	000bb783          	ld	a5,0(s7)
ffffffffc0203a5c:	779c                	ld	a5,40(a5)
ffffffffc0203a5e:	9782                	jalr	a5
ffffffffc0203a60:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0203a62:	b5dfc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203a66:	b3cd                	j	ffffffffc0203848 <pmm_init+0x3c0>
        intr_disable();
ffffffffc0203a68:	b5dfc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc0203a6c:	000bb783          	ld	a5,0(s7)
ffffffffc0203a70:	779c                	ld	a5,40(a5)
ffffffffc0203a72:	9782                	jalr	a5
ffffffffc0203a74:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0203a76:	b49fc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203a7a:	b36d                	j	ffffffffc0203824 <pmm_init+0x39c>
ffffffffc0203a7c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203a7e:	b47fc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203a82:	000bb783          	ld	a5,0(s7)
ffffffffc0203a86:	6522                	ld	a0,8(sp)
ffffffffc0203a88:	4585                	li	a1,1
ffffffffc0203a8a:	739c                	ld	a5,32(a5)
ffffffffc0203a8c:	9782                	jalr	a5
        intr_enable();
ffffffffc0203a8e:	b31fc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203a92:	bb8d                	j	ffffffffc0203804 <pmm_init+0x37c>
ffffffffc0203a94:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203a96:	b2ffc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc0203a9a:	000bb783          	ld	a5,0(s7)
ffffffffc0203a9e:	6522                	ld	a0,8(sp)
ffffffffc0203aa0:	4585                	li	a1,1
ffffffffc0203aa2:	739c                	ld	a5,32(a5)
ffffffffc0203aa4:	9782                	jalr	a5
        intr_enable();
ffffffffc0203aa6:	b19fc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203aaa:	b32d                	j	ffffffffc02037d4 <pmm_init+0x34c>
        intr_disable();
ffffffffc0203aac:	b19fc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0203ab0:	000bb783          	ld	a5,0(s7)
ffffffffc0203ab4:	779c                	ld	a5,40(a5)
ffffffffc0203ab6:	9782                	jalr	a5
ffffffffc0203ab8:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0203aba:	b05fc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203abe:	b72d                	j	ffffffffc02039e8 <pmm_init+0x560>
ffffffffc0203ac0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203ac2:	b03fc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203ac6:	000bb783          	ld	a5,0(s7)
ffffffffc0203aca:	6522                	ld	a0,8(sp)
ffffffffc0203acc:	4585                	li	a1,1
ffffffffc0203ace:	739c                	ld	a5,32(a5)
ffffffffc0203ad0:	9782                	jalr	a5
        intr_enable();
ffffffffc0203ad2:	aedfc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203ad6:	bdcd                	j	ffffffffc02039c8 <pmm_init+0x540>
ffffffffc0203ad8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0203ada:	aebfc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc0203ade:	000bb783          	ld	a5,0(s7)
ffffffffc0203ae2:	6522                	ld	a0,8(sp)
ffffffffc0203ae4:	4585                	li	a1,1
ffffffffc0203ae6:	739c                	ld	a5,32(a5)
ffffffffc0203ae8:	9782                	jalr	a5
        intr_enable();
ffffffffc0203aea:	ad5fc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203aee:	b56d                	j	ffffffffc0203998 <pmm_init+0x510>
        intr_disable();
ffffffffc0203af0:	ad5fc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
ffffffffc0203af4:	000bb783          	ld	a5,0(s7)
ffffffffc0203af8:	4585                	li	a1,1
ffffffffc0203afa:	8556                	mv	a0,s5
ffffffffc0203afc:	739c                	ld	a5,32(a5)
ffffffffc0203afe:	9782                	jalr	a5
        intr_enable();
ffffffffc0203b00:	abffc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0203b04:	b59d                	j	ffffffffc020396a <pmm_init+0x4e2>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0203b06:	00003697          	auipc	a3,0x3
ffffffffc0203b0a:	f6268693          	addi	a3,a3,-158 # ffffffffc0206a68 <default_pmm_manager+0x400>
ffffffffc0203b0e:	00002617          	auipc	a2,0x2
ffffffffc0203b12:	df260613          	addi	a2,a2,-526 # ffffffffc0205900 <commands+0x728>
ffffffffc0203b16:	19e00593          	li	a1,414
ffffffffc0203b1a:	00003517          	auipc	a0,0x3
ffffffffc0203b1e:	b8650513          	addi	a0,a0,-1146 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203b22:	ea6fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0203b26:	00003697          	auipc	a3,0x3
ffffffffc0203b2a:	f0268693          	addi	a3,a3,-254 # ffffffffc0206a28 <default_pmm_manager+0x3c0>
ffffffffc0203b2e:	00002617          	auipc	a2,0x2
ffffffffc0203b32:	dd260613          	addi	a2,a2,-558 # ffffffffc0205900 <commands+0x728>
ffffffffc0203b36:	19d00593          	li	a1,413
ffffffffc0203b3a:	00003517          	auipc	a0,0x3
ffffffffc0203b3e:	b6650513          	addi	a0,a0,-1178 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203b42:	e86fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
ffffffffc0203b46:	86a2                	mv	a3,s0
ffffffffc0203b48:	00002617          	auipc	a2,0x2
ffffffffc0203b4c:	01060613          	addi	a2,a2,16 # ffffffffc0205b58 <commands+0x980>
ffffffffc0203b50:	19d00593          	li	a1,413
ffffffffc0203b54:	00003517          	auipc	a0,0x3
ffffffffc0203b58:	b4c50513          	addi	a0,a0,-1204 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203b5c:	e6cfc0ef          	jal	ra,ffffffffc02001c8 <__panic>
ffffffffc0203b60:	c2cff0ef          	jal	ra,ffffffffc0202f8c <pa2page.part.0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0203b64:	00002617          	auipc	a2,0x2
ffffffffc0203b68:	3b460613          	addi	a2,a2,948 # ffffffffc0205f18 <commands+0xd40>
ffffffffc0203b6c:	07f00593          	li	a1,127
ffffffffc0203b70:	00003517          	auipc	a0,0x3
ffffffffc0203b74:	b3050513          	addi	a0,a0,-1232 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203b78:	e50fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0203b7c:	00002617          	auipc	a2,0x2
ffffffffc0203b80:	39c60613          	addi	a2,a2,924 # ffffffffc0205f18 <commands+0xd40>
ffffffffc0203b84:	0c300593          	li	a1,195
ffffffffc0203b88:	00003517          	auipc	a0,0x3
ffffffffc0203b8c:	b1850513          	addi	a0,a0,-1256 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203b90:	e38fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0203b94:	00003697          	auipc	a3,0x3
ffffffffc0203b98:	bcc68693          	addi	a3,a3,-1076 # ffffffffc0206760 <default_pmm_manager+0xf8>
ffffffffc0203b9c:	00002617          	auipc	a2,0x2
ffffffffc0203ba0:	d6460613          	addi	a2,a2,-668 # ffffffffc0205900 <commands+0x728>
ffffffffc0203ba4:	16100593          	li	a1,353
ffffffffc0203ba8:	00003517          	auipc	a0,0x3
ffffffffc0203bac:	af850513          	addi	a0,a0,-1288 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203bb0:	e18fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0203bb4:	00003697          	auipc	a3,0x3
ffffffffc0203bb8:	b8c68693          	addi	a3,a3,-1140 # ffffffffc0206740 <default_pmm_manager+0xd8>
ffffffffc0203bbc:	00002617          	auipc	a2,0x2
ffffffffc0203bc0:	d4460613          	addi	a2,a2,-700 # ffffffffc0205900 <commands+0x728>
ffffffffc0203bc4:	16000593          	li	a1,352
ffffffffc0203bc8:	00003517          	auipc	a0,0x3
ffffffffc0203bcc:	ad850513          	addi	a0,a0,-1320 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203bd0:	df8fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
ffffffffc0203bd4:	bd4ff0ef          	jal	ra,ffffffffc0202fa8 <pte2page.part.0>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0203bd8:	00003697          	auipc	a3,0x3
ffffffffc0203bdc:	c1868693          	addi	a3,a3,-1000 # ffffffffc02067f0 <default_pmm_manager+0x188>
ffffffffc0203be0:	00002617          	auipc	a2,0x2
ffffffffc0203be4:	d2060613          	addi	a2,a2,-736 # ffffffffc0205900 <commands+0x728>
ffffffffc0203be8:	16900593          	li	a1,361
ffffffffc0203bec:	00003517          	auipc	a0,0x3
ffffffffc0203bf0:	ab450513          	addi	a0,a0,-1356 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203bf4:	dd4fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0203bf8:	00003697          	auipc	a3,0x3
ffffffffc0203bfc:	bc868693          	addi	a3,a3,-1080 # ffffffffc02067c0 <default_pmm_manager+0x158>
ffffffffc0203c00:	00002617          	auipc	a2,0x2
ffffffffc0203c04:	d0060613          	addi	a2,a2,-768 # ffffffffc0205900 <commands+0x728>
ffffffffc0203c08:	16600593          	li	a1,358
ffffffffc0203c0c:	00003517          	auipc	a0,0x3
ffffffffc0203c10:	a9450513          	addi	a0,a0,-1388 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203c14:	db4fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0203c18:	00003697          	auipc	a3,0x3
ffffffffc0203c1c:	b8068693          	addi	a3,a3,-1152 # ffffffffc0206798 <default_pmm_manager+0x130>
ffffffffc0203c20:	00002617          	auipc	a2,0x2
ffffffffc0203c24:	ce060613          	addi	a2,a2,-800 # ffffffffc0205900 <commands+0x728>
ffffffffc0203c28:	16200593          	li	a1,354
ffffffffc0203c2c:	00003517          	auipc	a0,0x3
ffffffffc0203c30:	a7450513          	addi	a0,a0,-1420 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203c34:	d94fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203c38:	00003697          	auipc	a3,0x3
ffffffffc0203c3c:	c4068693          	addi	a3,a3,-960 # ffffffffc0206878 <default_pmm_manager+0x210>
ffffffffc0203c40:	00002617          	auipc	a2,0x2
ffffffffc0203c44:	cc060613          	addi	a2,a2,-832 # ffffffffc0205900 <commands+0x728>
ffffffffc0203c48:	17200593          	li	a1,370
ffffffffc0203c4c:	00003517          	auipc	a0,0x3
ffffffffc0203c50:	a5450513          	addi	a0,a0,-1452 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203c54:	d74fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203c58:	00003697          	auipc	a3,0x3
ffffffffc0203c5c:	cc068693          	addi	a3,a3,-832 # ffffffffc0206918 <default_pmm_manager+0x2b0>
ffffffffc0203c60:	00002617          	auipc	a2,0x2
ffffffffc0203c64:	ca060613          	addi	a2,a2,-864 # ffffffffc0205900 <commands+0x728>
ffffffffc0203c68:	17700593          	li	a1,375
ffffffffc0203c6c:	00003517          	auipc	a0,0x3
ffffffffc0203c70:	a3450513          	addi	a0,a0,-1484 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203c74:	d54fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0203c78:	00003697          	auipc	a3,0x3
ffffffffc0203c7c:	bd868693          	addi	a3,a3,-1064 # ffffffffc0206850 <default_pmm_manager+0x1e8>
ffffffffc0203c80:	00002617          	auipc	a2,0x2
ffffffffc0203c84:	c8060613          	addi	a2,a2,-896 # ffffffffc0205900 <commands+0x728>
ffffffffc0203c88:	16f00593          	li	a1,367
ffffffffc0203c8c:	00003517          	auipc	a0,0x3
ffffffffc0203c90:	a1450513          	addi	a0,a0,-1516 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203c94:	d34fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203c98:	86d6                	mv	a3,s5
ffffffffc0203c9a:	00002617          	auipc	a2,0x2
ffffffffc0203c9e:	ebe60613          	addi	a2,a2,-322 # ffffffffc0205b58 <commands+0x980>
ffffffffc0203ca2:	16e00593          	li	a1,366
ffffffffc0203ca6:	00003517          	auipc	a0,0x3
ffffffffc0203caa:	9fa50513          	addi	a0,a0,-1542 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203cae:	d1afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0203cb2:	00003697          	auipc	a3,0x3
ffffffffc0203cb6:	bfe68693          	addi	a3,a3,-1026 # ffffffffc02068b0 <default_pmm_manager+0x248>
ffffffffc0203cba:	00002617          	auipc	a2,0x2
ffffffffc0203cbe:	c4660613          	addi	a2,a2,-954 # ffffffffc0205900 <commands+0x728>
ffffffffc0203cc2:	17c00593          	li	a1,380
ffffffffc0203cc6:	00003517          	auipc	a0,0x3
ffffffffc0203cca:	9da50513          	addi	a0,a0,-1574 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203cce:	cfafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203cd2:	00003697          	auipc	a3,0x3
ffffffffc0203cd6:	ca668693          	addi	a3,a3,-858 # ffffffffc0206978 <default_pmm_manager+0x310>
ffffffffc0203cda:	00002617          	auipc	a2,0x2
ffffffffc0203cde:	c2660613          	addi	a2,a2,-986 # ffffffffc0205900 <commands+0x728>
ffffffffc0203ce2:	17b00593          	li	a1,379
ffffffffc0203ce6:	00003517          	auipc	a0,0x3
ffffffffc0203cea:	9ba50513          	addi	a0,a0,-1606 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203cee:	cdafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0203cf2:	00003697          	auipc	a3,0x3
ffffffffc0203cf6:	c6e68693          	addi	a3,a3,-914 # ffffffffc0206960 <default_pmm_manager+0x2f8>
ffffffffc0203cfa:	00002617          	auipc	a2,0x2
ffffffffc0203cfe:	c0660613          	addi	a2,a2,-1018 # ffffffffc0205900 <commands+0x728>
ffffffffc0203d02:	17a00593          	li	a1,378
ffffffffc0203d06:	00003517          	auipc	a0,0x3
ffffffffc0203d0a:	99a50513          	addi	a0,a0,-1638 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203d0e:	cbafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0203d12:	00003697          	auipc	a3,0x3
ffffffffc0203d16:	c1e68693          	addi	a3,a3,-994 # ffffffffc0206930 <default_pmm_manager+0x2c8>
ffffffffc0203d1a:	00002617          	auipc	a2,0x2
ffffffffc0203d1e:	be660613          	addi	a2,a2,-1050 # ffffffffc0205900 <commands+0x728>
ffffffffc0203d22:	17900593          	li	a1,377
ffffffffc0203d26:	00003517          	auipc	a0,0x3
ffffffffc0203d2a:	97a50513          	addi	a0,a0,-1670 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203d2e:	c9afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0203d32:	00003697          	auipc	a3,0x3
ffffffffc0203d36:	db668693          	addi	a3,a3,-586 # ffffffffc0206ae8 <default_pmm_manager+0x480>
ffffffffc0203d3a:	00002617          	auipc	a2,0x2
ffffffffc0203d3e:	bc660613          	addi	a2,a2,-1082 # ffffffffc0205900 <commands+0x728>
ffffffffc0203d42:	1a700593          	li	a1,423
ffffffffc0203d46:	00003517          	auipc	a0,0x3
ffffffffc0203d4a:	95a50513          	addi	a0,a0,-1702 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203d4e:	c7afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0203d52:	00003697          	auipc	a3,0x3
ffffffffc0203d56:	bae68693          	addi	a3,a3,-1106 # ffffffffc0206900 <default_pmm_manager+0x298>
ffffffffc0203d5a:	00002617          	auipc	a2,0x2
ffffffffc0203d5e:	ba660613          	addi	a2,a2,-1114 # ffffffffc0205900 <commands+0x728>
ffffffffc0203d62:	17600593          	li	a1,374
ffffffffc0203d66:	00003517          	auipc	a0,0x3
ffffffffc0203d6a:	93a50513          	addi	a0,a0,-1734 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203d6e:	c5afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203d72:	00003697          	auipc	a3,0x3
ffffffffc0203d76:	b7e68693          	addi	a3,a3,-1154 # ffffffffc02068f0 <default_pmm_manager+0x288>
ffffffffc0203d7a:	00002617          	auipc	a2,0x2
ffffffffc0203d7e:	b8660613          	addi	a2,a2,-1146 # ffffffffc0205900 <commands+0x728>
ffffffffc0203d82:	17500593          	li	a1,373
ffffffffc0203d86:	00003517          	auipc	a0,0x3
ffffffffc0203d8a:	91a50513          	addi	a0,a0,-1766 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203d8e:	c3afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0203d92:	00003697          	auipc	a3,0x3
ffffffffc0203d96:	c5668693          	addi	a3,a3,-938 # ffffffffc02069e8 <default_pmm_manager+0x380>
ffffffffc0203d9a:	00002617          	auipc	a2,0x2
ffffffffc0203d9e:	b6660613          	addi	a2,a2,-1178 # ffffffffc0205900 <commands+0x728>
ffffffffc0203da2:	1b800593          	li	a1,440
ffffffffc0203da6:	00003517          	auipc	a0,0x3
ffffffffc0203daa:	8fa50513          	addi	a0,a0,-1798 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203dae:	c1afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203db2:	00003697          	auipc	a3,0x3
ffffffffc0203db6:	b2e68693          	addi	a3,a3,-1234 # ffffffffc02068e0 <default_pmm_manager+0x278>
ffffffffc0203dba:	00002617          	auipc	a2,0x2
ffffffffc0203dbe:	b4660613          	addi	a2,a2,-1210 # ffffffffc0205900 <commands+0x728>
ffffffffc0203dc2:	17400593          	li	a1,372
ffffffffc0203dc6:	00003517          	auipc	a0,0x3
ffffffffc0203dca:	8da50513          	addi	a0,a0,-1830 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203dce:	bfafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203dd2:	00003697          	auipc	a3,0x3
ffffffffc0203dd6:	a6668693          	addi	a3,a3,-1434 # ffffffffc0206838 <default_pmm_manager+0x1d0>
ffffffffc0203dda:	00002617          	auipc	a2,0x2
ffffffffc0203dde:	b2660613          	addi	a2,a2,-1242 # ffffffffc0205900 <commands+0x728>
ffffffffc0203de2:	18100593          	li	a1,385
ffffffffc0203de6:	00003517          	auipc	a0,0x3
ffffffffc0203dea:	8ba50513          	addi	a0,a0,-1862 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203dee:	bdafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203df2:	00003697          	auipc	a3,0x3
ffffffffc0203df6:	b9e68693          	addi	a3,a3,-1122 # ffffffffc0206990 <default_pmm_manager+0x328>
ffffffffc0203dfa:	00002617          	auipc	a2,0x2
ffffffffc0203dfe:	b0660613          	addi	a2,a2,-1274 # ffffffffc0205900 <commands+0x728>
ffffffffc0203e02:	17e00593          	li	a1,382
ffffffffc0203e06:	00003517          	auipc	a0,0x3
ffffffffc0203e0a:	89a50513          	addi	a0,a0,-1894 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203e0e:	bbafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203e12:	00003697          	auipc	a3,0x3
ffffffffc0203e16:	a0e68693          	addi	a3,a3,-1522 # ffffffffc0206820 <default_pmm_manager+0x1b8>
ffffffffc0203e1a:	00002617          	auipc	a2,0x2
ffffffffc0203e1e:	ae660613          	addi	a2,a2,-1306 # ffffffffc0205900 <commands+0x728>
ffffffffc0203e22:	17d00593          	li	a1,381
ffffffffc0203e26:	00003517          	auipc	a0,0x3
ffffffffc0203e2a:	87a50513          	addi	a0,a0,-1926 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203e2e:	b9afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203e32:	00002617          	auipc	a2,0x2
ffffffffc0203e36:	d2660613          	addi	a2,a2,-730 # ffffffffc0205b58 <commands+0x980>
ffffffffc0203e3a:	06900593          	li	a1,105
ffffffffc0203e3e:	00002517          	auipc	a0,0x2
ffffffffc0203e42:	d0a50513          	addi	a0,a0,-758 # ffffffffc0205b48 <commands+0x970>
ffffffffc0203e46:	b82fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0203e4a:	00003697          	auipc	a3,0x3
ffffffffc0203e4e:	b7668693          	addi	a3,a3,-1162 # ffffffffc02069c0 <default_pmm_manager+0x358>
ffffffffc0203e52:	00002617          	auipc	a2,0x2
ffffffffc0203e56:	aae60613          	addi	a2,a2,-1362 # ffffffffc0205900 <commands+0x728>
ffffffffc0203e5a:	18800593          	li	a1,392
ffffffffc0203e5e:	00003517          	auipc	a0,0x3
ffffffffc0203e62:	84250513          	addi	a0,a0,-1982 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203e66:	b62fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203e6a:	00003697          	auipc	a3,0x3
ffffffffc0203e6e:	b0e68693          	addi	a3,a3,-1266 # ffffffffc0206978 <default_pmm_manager+0x310>
ffffffffc0203e72:	00002617          	auipc	a2,0x2
ffffffffc0203e76:	a8e60613          	addi	a2,a2,-1394 # ffffffffc0205900 <commands+0x728>
ffffffffc0203e7a:	18600593          	li	a1,390
ffffffffc0203e7e:	00003517          	auipc	a0,0x3
ffffffffc0203e82:	82250513          	addi	a0,a0,-2014 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203e86:	b42fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0203e8a:	00003697          	auipc	a3,0x3
ffffffffc0203e8e:	b1e68693          	addi	a3,a3,-1250 # ffffffffc02069a8 <default_pmm_manager+0x340>
ffffffffc0203e92:	00002617          	auipc	a2,0x2
ffffffffc0203e96:	a6e60613          	addi	a2,a2,-1426 # ffffffffc0205900 <commands+0x728>
ffffffffc0203e9a:	18500593          	li	a1,389
ffffffffc0203e9e:	00003517          	auipc	a0,0x3
ffffffffc0203ea2:	80250513          	addi	a0,a0,-2046 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203ea6:	b22fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203eaa:	00003697          	auipc	a3,0x3
ffffffffc0203eae:	ace68693          	addi	a3,a3,-1330 # ffffffffc0206978 <default_pmm_manager+0x310>
ffffffffc0203eb2:	00002617          	auipc	a2,0x2
ffffffffc0203eb6:	a4e60613          	addi	a2,a2,-1458 # ffffffffc0205900 <commands+0x728>
ffffffffc0203eba:	18200593          	li	a1,386
ffffffffc0203ebe:	00002517          	auipc	a0,0x2
ffffffffc0203ec2:	7e250513          	addi	a0,a0,2018 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203ec6:	b02fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0203eca:	00003697          	auipc	a3,0x3
ffffffffc0203ece:	c0668693          	addi	a3,a3,-1018 # ffffffffc0206ad0 <default_pmm_manager+0x468>
ffffffffc0203ed2:	00002617          	auipc	a2,0x2
ffffffffc0203ed6:	a2e60613          	addi	a2,a2,-1490 # ffffffffc0205900 <commands+0x728>
ffffffffc0203eda:	1a600593          	li	a1,422
ffffffffc0203ede:	00002517          	auipc	a0,0x2
ffffffffc0203ee2:	7c250513          	addi	a0,a0,1986 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203ee6:	ae2fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0203eea:	00003697          	auipc	a3,0x3
ffffffffc0203eee:	bae68693          	addi	a3,a3,-1106 # ffffffffc0206a98 <default_pmm_manager+0x430>
ffffffffc0203ef2:	00002617          	auipc	a2,0x2
ffffffffc0203ef6:	a0e60613          	addi	a2,a2,-1522 # ffffffffc0205900 <commands+0x728>
ffffffffc0203efa:	1a500593          	li	a1,421
ffffffffc0203efe:	00002517          	auipc	a0,0x2
ffffffffc0203f02:	7a250513          	addi	a0,a0,1954 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203f06:	ac2fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0203f0a:	00003697          	auipc	a3,0x3
ffffffffc0203f0e:	b7668693          	addi	a3,a3,-1162 # ffffffffc0206a80 <default_pmm_manager+0x418>
ffffffffc0203f12:	00002617          	auipc	a2,0x2
ffffffffc0203f16:	9ee60613          	addi	a2,a2,-1554 # ffffffffc0205900 <commands+0x728>
ffffffffc0203f1a:	1a100593          	li	a1,417
ffffffffc0203f1e:	00002517          	auipc	a0,0x2
ffffffffc0203f22:	78250513          	addi	a0,a0,1922 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203f26:	aa2fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0203f2a:	00003697          	auipc	a3,0x3
ffffffffc0203f2e:	abe68693          	addi	a3,a3,-1346 # ffffffffc02069e8 <default_pmm_manager+0x380>
ffffffffc0203f32:	00002617          	auipc	a2,0x2
ffffffffc0203f36:	9ce60613          	addi	a2,a2,-1586 # ffffffffc0205900 <commands+0x728>
ffffffffc0203f3a:	19000593          	li	a1,400
ffffffffc0203f3e:	00002517          	auipc	a0,0x2
ffffffffc0203f42:	76250513          	addi	a0,a0,1890 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203f46:	a82fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203f4a:	00003697          	auipc	a3,0x3
ffffffffc0203f4e:	8d668693          	addi	a3,a3,-1834 # ffffffffc0206820 <default_pmm_manager+0x1b8>
ffffffffc0203f52:	00002617          	auipc	a2,0x2
ffffffffc0203f56:	9ae60613          	addi	a2,a2,-1618 # ffffffffc0205900 <commands+0x728>
ffffffffc0203f5a:	16a00593          	li	a1,362
ffffffffc0203f5e:	00002517          	auipc	a0,0x2
ffffffffc0203f62:	74250513          	addi	a0,a0,1858 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203f66:	a62fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0203f6a:	00002617          	auipc	a2,0x2
ffffffffc0203f6e:	bee60613          	addi	a2,a2,-1042 # ffffffffc0205b58 <commands+0x980>
ffffffffc0203f72:	16d00593          	li	a1,365
ffffffffc0203f76:	00002517          	auipc	a0,0x2
ffffffffc0203f7a:	72a50513          	addi	a0,a0,1834 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203f7e:	a4afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203f82:	00003697          	auipc	a3,0x3
ffffffffc0203f86:	8b668693          	addi	a3,a3,-1866 # ffffffffc0206838 <default_pmm_manager+0x1d0>
ffffffffc0203f8a:	00002617          	auipc	a2,0x2
ffffffffc0203f8e:	97660613          	addi	a2,a2,-1674 # ffffffffc0205900 <commands+0x728>
ffffffffc0203f92:	16b00593          	li	a1,363
ffffffffc0203f96:	00002517          	auipc	a0,0x2
ffffffffc0203f9a:	70a50513          	addi	a0,a0,1802 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203f9e:	a2afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0203fa2:	00003697          	auipc	a3,0x3
ffffffffc0203fa6:	90e68693          	addi	a3,a3,-1778 # ffffffffc02068b0 <default_pmm_manager+0x248>
ffffffffc0203faa:	00002617          	auipc	a2,0x2
ffffffffc0203fae:	95660613          	addi	a2,a2,-1706 # ffffffffc0205900 <commands+0x728>
ffffffffc0203fb2:	17300593          	li	a1,371
ffffffffc0203fb6:	00002517          	auipc	a0,0x2
ffffffffc0203fba:	6ea50513          	addi	a0,a0,1770 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203fbe:	a0afc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203fc2:	00003697          	auipc	a3,0x3
ffffffffc0203fc6:	bce68693          	addi	a3,a3,-1074 # ffffffffc0206b90 <default_pmm_manager+0x528>
ffffffffc0203fca:	00002617          	auipc	a2,0x2
ffffffffc0203fce:	93660613          	addi	a2,a2,-1738 # ffffffffc0205900 <commands+0x728>
ffffffffc0203fd2:	1af00593          	li	a1,431
ffffffffc0203fd6:	00002517          	auipc	a0,0x2
ffffffffc0203fda:	6ca50513          	addi	a0,a0,1738 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203fde:	9eafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0203fe2:	00003697          	auipc	a3,0x3
ffffffffc0203fe6:	b7668693          	addi	a3,a3,-1162 # ffffffffc0206b58 <default_pmm_manager+0x4f0>
ffffffffc0203fea:	00002617          	auipc	a2,0x2
ffffffffc0203fee:	91660613          	addi	a2,a2,-1770 # ffffffffc0205900 <commands+0x728>
ffffffffc0203ff2:	1ac00593          	li	a1,428
ffffffffc0203ff6:	00002517          	auipc	a0,0x2
ffffffffc0203ffa:	6aa50513          	addi	a0,a0,1706 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc0203ffe:	9cafc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0204002:	00003697          	auipc	a3,0x3
ffffffffc0204006:	b2668693          	addi	a3,a3,-1242 # ffffffffc0206b28 <default_pmm_manager+0x4c0>
ffffffffc020400a:	00002617          	auipc	a2,0x2
ffffffffc020400e:	8f660613          	addi	a2,a2,-1802 # ffffffffc0205900 <commands+0x728>
ffffffffc0204012:	1a800593          	li	a1,424
ffffffffc0204016:	00002517          	auipc	a0,0x2
ffffffffc020401a:	68a50513          	addi	a0,a0,1674 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc020401e:	9aafc0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0204022 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0204022:	12058073          	sfence.vma	a1
}
ffffffffc0204026:	8082                	ret

ffffffffc0204028 <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0204028:	7179                	addi	sp,sp,-48
ffffffffc020402a:	e84a                	sd	s2,16(sp)
ffffffffc020402c:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc020402e:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0204030:	f022                	sd	s0,32(sp)
ffffffffc0204032:	ec26                	sd	s1,24(sp)
ffffffffc0204034:	e44e                	sd	s3,8(sp)
ffffffffc0204036:	f406                	sd	ra,40(sp)
ffffffffc0204038:	84ae                	mv	s1,a1
ffffffffc020403a:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc020403c:	f89fe0ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
ffffffffc0204040:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0204042:	cd09                	beqz	a0,ffffffffc020405c <pgdir_alloc_page+0x34>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0204044:	85aa                	mv	a1,a0
ffffffffc0204046:	86ce                	mv	a3,s3
ffffffffc0204048:	8626                	mv	a2,s1
ffffffffc020404a:	854a                	mv	a0,s2
ffffffffc020404c:	b46ff0ef          	jal	ra,ffffffffc0203392 <page_insert>
ffffffffc0204050:	ed21                	bnez	a0,ffffffffc02040a8 <pgdir_alloc_page+0x80>
        if (swap_init_ok) {
ffffffffc0204052:	00012797          	auipc	a5,0x12
ffffffffc0204056:	5267a783          	lw	a5,1318(a5) # ffffffffc0216578 <swap_init_ok>
ffffffffc020405a:	eb89                	bnez	a5,ffffffffc020406c <pgdir_alloc_page+0x44>
}
ffffffffc020405c:	70a2                	ld	ra,40(sp)
ffffffffc020405e:	8522                	mv	a0,s0
ffffffffc0204060:	7402                	ld	s0,32(sp)
ffffffffc0204062:	64e2                	ld	s1,24(sp)
ffffffffc0204064:	6942                	ld	s2,16(sp)
ffffffffc0204066:	69a2                	ld	s3,8(sp)
ffffffffc0204068:	6145                	addi	sp,sp,48
ffffffffc020406a:	8082                	ret
            swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc020406c:	4681                	li	a3,0
ffffffffc020406e:	8622                	mv	a2,s0
ffffffffc0204070:	85a6                	mv	a1,s1
ffffffffc0204072:	00012517          	auipc	a0,0x12
ffffffffc0204076:	4de53503          	ld	a0,1246(a0) # ffffffffc0216550 <check_mm_struct>
ffffffffc020407a:	acafe0ef          	jal	ra,ffffffffc0202344 <swap_map_swappable>
            assert(page_ref(page) == 1);
ffffffffc020407e:	4018                	lw	a4,0(s0)
            page->pra_vaddr = la;
ffffffffc0204080:	fc04                	sd	s1,56(s0)
            assert(page_ref(page) == 1);
ffffffffc0204082:	4785                	li	a5,1
ffffffffc0204084:	fcf70ce3          	beq	a4,a5,ffffffffc020405c <pgdir_alloc_page+0x34>
ffffffffc0204088:	00003697          	auipc	a3,0x3
ffffffffc020408c:	b5068693          	addi	a3,a3,-1200 # ffffffffc0206bd8 <default_pmm_manager+0x570>
ffffffffc0204090:	00002617          	auipc	a2,0x2
ffffffffc0204094:	87060613          	addi	a2,a2,-1936 # ffffffffc0205900 <commands+0x728>
ffffffffc0204098:	14800593          	li	a1,328
ffffffffc020409c:	00002517          	auipc	a0,0x2
ffffffffc02040a0:	60450513          	addi	a0,a0,1540 # ffffffffc02066a0 <default_pmm_manager+0x38>
ffffffffc02040a4:	924fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02040a8:	100027f3          	csrr	a5,sstatus
ffffffffc02040ac:	8b89                	andi	a5,a5,2
ffffffffc02040ae:	eb99                	bnez	a5,ffffffffc02040c4 <pgdir_alloc_page+0x9c>
        pmm_manager->free_pages(base, n);
ffffffffc02040b0:	00012797          	auipc	a5,0x12
ffffffffc02040b4:	4f07b783          	ld	a5,1264(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc02040b8:	739c                	ld	a5,32(a5)
ffffffffc02040ba:	8522                	mv	a0,s0
ffffffffc02040bc:	4585                	li	a1,1
ffffffffc02040be:	9782                	jalr	a5
            return NULL;
ffffffffc02040c0:	4401                	li	s0,0
ffffffffc02040c2:	bf69                	j	ffffffffc020405c <pgdir_alloc_page+0x34>
        intr_disable();
ffffffffc02040c4:	d00fc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02040c8:	00012797          	auipc	a5,0x12
ffffffffc02040cc:	4d87b783          	ld	a5,1240(a5) # ffffffffc02165a0 <pmm_manager>
ffffffffc02040d0:	739c                	ld	a5,32(a5)
ffffffffc02040d2:	8522                	mv	a0,s0
ffffffffc02040d4:	4585                	li	a1,1
ffffffffc02040d6:	9782                	jalr	a5
            return NULL;
ffffffffc02040d8:	4401                	li	s0,0
        intr_enable();
ffffffffc02040da:	ce4fc0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc02040de:	bfbd                	j	ffffffffc020405c <pgdir_alloc_page+0x34>

ffffffffc02040e0 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc02040e0:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc02040e2:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc02040e4:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc02040e6:	bbefc0ef          	jal	ra,ffffffffc02004a4 <ide_device_valid>
ffffffffc02040ea:	cd01                	beqz	a0,ffffffffc0204102 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc02040ec:	4505                	li	a0,1
ffffffffc02040ee:	bbcfc0ef          	jal	ra,ffffffffc02004aa <ide_device_size>
}
ffffffffc02040f2:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc02040f4:	810d                	srli	a0,a0,0x3
ffffffffc02040f6:	00012797          	auipc	a5,0x12
ffffffffc02040fa:	46a7b923          	sd	a0,1138(a5) # ffffffffc0216568 <max_swap_offset>
}
ffffffffc02040fe:	0141                	addi	sp,sp,16
ffffffffc0204100:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0204102:	00003617          	auipc	a2,0x3
ffffffffc0204106:	aee60613          	addi	a2,a2,-1298 # ffffffffc0206bf0 <default_pmm_manager+0x588>
ffffffffc020410a:	45b5                	li	a1,13
ffffffffc020410c:	00003517          	auipc	a0,0x3
ffffffffc0204110:	b0450513          	addi	a0,a0,-1276 # ffffffffc0206c10 <default_pmm_manager+0x5a8>
ffffffffc0204114:	8b4fc0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0204118 <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0204118:	1141                	addi	sp,sp,-16
ffffffffc020411a:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc020411c:	00855793          	srli	a5,a0,0x8
ffffffffc0204120:	cbb1                	beqz	a5,ffffffffc0204174 <swapfs_read+0x5c>
ffffffffc0204122:	00012717          	auipc	a4,0x12
ffffffffc0204126:	44673703          	ld	a4,1094(a4) # ffffffffc0216568 <max_swap_offset>
ffffffffc020412a:	04e7f563          	bgeu	a5,a4,ffffffffc0204174 <swapfs_read+0x5c>
    return page - pages + nbase;
ffffffffc020412e:	00012617          	auipc	a2,0x12
ffffffffc0204132:	46a63603          	ld	a2,1130(a2) # ffffffffc0216598 <pages>
ffffffffc0204136:	8d91                	sub	a1,a1,a2
ffffffffc0204138:	4065d613          	srai	a2,a1,0x6
ffffffffc020413c:	00003717          	auipc	a4,0x3
ffffffffc0204140:	f0473703          	ld	a4,-252(a4) # ffffffffc0207040 <nbase>
ffffffffc0204144:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc0204146:	00c61713          	slli	a4,a2,0xc
ffffffffc020414a:	8331                	srli	a4,a4,0xc
ffffffffc020414c:	00012697          	auipc	a3,0x12
ffffffffc0204150:	4446b683          	ld	a3,1092(a3) # ffffffffc0216590 <npage>
ffffffffc0204154:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204158:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc020415a:	02d77963          	bgeu	a4,a3,ffffffffc020418c <swapfs_read+0x74>
}
ffffffffc020415e:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204160:	00012797          	auipc	a5,0x12
ffffffffc0204164:	4487b783          	ld	a5,1096(a5) # ffffffffc02165a8 <va_pa_offset>
ffffffffc0204168:	46a1                	li	a3,8
ffffffffc020416a:	963e                	add	a2,a2,a5
ffffffffc020416c:	4505                	li	a0,1
}
ffffffffc020416e:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204170:	b40fc06f          	j	ffffffffc02004b0 <ide_read_secs>
ffffffffc0204174:	86aa                	mv	a3,a0
ffffffffc0204176:	00003617          	auipc	a2,0x3
ffffffffc020417a:	ab260613          	addi	a2,a2,-1358 # ffffffffc0206c28 <default_pmm_manager+0x5c0>
ffffffffc020417e:	45d1                	li	a1,20
ffffffffc0204180:	00003517          	auipc	a0,0x3
ffffffffc0204184:	a9050513          	addi	a0,a0,-1392 # ffffffffc0206c10 <default_pmm_manager+0x5a8>
ffffffffc0204188:	840fc0ef          	jal	ra,ffffffffc02001c8 <__panic>
ffffffffc020418c:	86b2                	mv	a3,a2
ffffffffc020418e:	06900593          	li	a1,105
ffffffffc0204192:	00002617          	auipc	a2,0x2
ffffffffc0204196:	9c660613          	addi	a2,a2,-1594 # ffffffffc0205b58 <commands+0x980>
ffffffffc020419a:	00002517          	auipc	a0,0x2
ffffffffc020419e:	9ae50513          	addi	a0,a0,-1618 # ffffffffc0205b48 <commands+0x970>
ffffffffc02041a2:	826fc0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02041a6 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc02041a6:	1141                	addi	sp,sp,-16
ffffffffc02041a8:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc02041aa:	00855793          	srli	a5,a0,0x8
ffffffffc02041ae:	cbb1                	beqz	a5,ffffffffc0204202 <swapfs_write+0x5c>
ffffffffc02041b0:	00012717          	auipc	a4,0x12
ffffffffc02041b4:	3b873703          	ld	a4,952(a4) # ffffffffc0216568 <max_swap_offset>
ffffffffc02041b8:	04e7f563          	bgeu	a5,a4,ffffffffc0204202 <swapfs_write+0x5c>
    return page - pages + nbase;
ffffffffc02041bc:	00012617          	auipc	a2,0x12
ffffffffc02041c0:	3dc63603          	ld	a2,988(a2) # ffffffffc0216598 <pages>
ffffffffc02041c4:	8d91                	sub	a1,a1,a2
ffffffffc02041c6:	4065d613          	srai	a2,a1,0x6
ffffffffc02041ca:	00003717          	auipc	a4,0x3
ffffffffc02041ce:	e7673703          	ld	a4,-394(a4) # ffffffffc0207040 <nbase>
ffffffffc02041d2:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc02041d4:	00c61713          	slli	a4,a2,0xc
ffffffffc02041d8:	8331                	srli	a4,a4,0xc
ffffffffc02041da:	00012697          	auipc	a3,0x12
ffffffffc02041de:	3b66b683          	ld	a3,950(a3) # ffffffffc0216590 <npage>
ffffffffc02041e2:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc02041e6:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc02041e8:	02d77963          	bgeu	a4,a3,ffffffffc020421a <swapfs_write+0x74>
}
ffffffffc02041ec:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc02041ee:	00012797          	auipc	a5,0x12
ffffffffc02041f2:	3ba7b783          	ld	a5,954(a5) # ffffffffc02165a8 <va_pa_offset>
ffffffffc02041f6:	46a1                	li	a3,8
ffffffffc02041f8:	963e                	add	a2,a2,a5
ffffffffc02041fa:	4505                	li	a0,1
}
ffffffffc02041fc:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc02041fe:	ad6fc06f          	j	ffffffffc02004d4 <ide_write_secs>
ffffffffc0204202:	86aa                	mv	a3,a0
ffffffffc0204204:	00003617          	auipc	a2,0x3
ffffffffc0204208:	a2460613          	addi	a2,a2,-1500 # ffffffffc0206c28 <default_pmm_manager+0x5c0>
ffffffffc020420c:	45e5                	li	a1,25
ffffffffc020420e:	00003517          	auipc	a0,0x3
ffffffffc0204212:	a0250513          	addi	a0,a0,-1534 # ffffffffc0206c10 <default_pmm_manager+0x5a8>
ffffffffc0204216:	fb3fb0ef          	jal	ra,ffffffffc02001c8 <__panic>
ffffffffc020421a:	86b2                	mv	a3,a2
ffffffffc020421c:	06900593          	li	a1,105
ffffffffc0204220:	00002617          	auipc	a2,0x2
ffffffffc0204224:	93860613          	addi	a2,a2,-1736 # ffffffffc0205b58 <commands+0x980>
ffffffffc0204228:	00002517          	auipc	a0,0x2
ffffffffc020422c:	92050513          	addi	a0,a0,-1760 # ffffffffc0205b48 <commands+0x970>
ffffffffc0204230:	f99fb0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc0204234 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204234:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204236:	9402                	jalr	s0

	jal do_exit
ffffffffc0204238:	4f8000ef          	jal	ra,ffffffffc0204730 <do_exit>

ffffffffc020423c <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc020423c:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204240:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204244:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204246:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204248:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc020424c:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204250:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204254:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204258:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc020425c:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204260:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204264:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204268:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc020426c:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204270:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204274:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204278:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc020427a:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc020427c:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0204280:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0204284:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0204288:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc020428c:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0204290:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0204294:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0204298:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc020429c:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc02042a0:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc02042a4:	8082                	ret

ffffffffc02042a6 <alloc_proc>:
void forkrets(struct trapframe *tf);                 // fork 的返回点
void switch_to(struct context *from, struct context *to); // 上下文切换函数

// alloc_proc - 分配并初始化进程控制块（proc_struct）
static struct proc_struct *
alloc_proc(void) {
ffffffffc02042a6:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct)); // 分配内存
ffffffffc02042a8:	0e800513          	li	a0,232
alloc_proc(void) {
ffffffffc02042ac:	e022                	sd	s0,0(sp)
ffffffffc02042ae:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct)); // 分配内存
ffffffffc02042b0:	f8cfd0ef          	jal	ra,ffffffffc0201a3c <kmalloc>
ffffffffc02042b4:	842a                	mv	s0,a0
    if (proc != NULL) {
ffffffffc02042b6:	c521                	beqz	a0,ffffffffc02042fe <alloc_proc+0x58>
        proc->state = PROC_UNINIT;                      // 初始状态：未初始化
ffffffffc02042b8:	57fd                	li	a5,-1
ffffffffc02042ba:	1782                	slli	a5,a5,0x20
ffffffffc02042bc:	e11c                	sd	a5,0(a0)
        proc->runs = 0;                                 // 运行次数为 0
        proc->kstack = 0;                               // 内核栈地址未分配
        proc->need_resched = 0;                         // 初始时不需要调度
        proc->parent = NULL;                            // 父进程为空
        proc->mm = NULL;                                // 内存管理未分配
        memset(&(proc->context), 0, sizeof(struct context)); // 清空上下文信息
ffffffffc02042be:	07000613          	li	a2,112
ffffffffc02042c2:	4581                	li	a1,0
        proc->runs = 0;                                 // 运行次数为 0
ffffffffc02042c4:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;                               // 内核栈地址未分配
ffffffffc02042c8:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;                         // 初始时不需要调度
ffffffffc02042cc:	00052c23          	sw	zero,24(a0)
        proc->parent = NULL;                            // 父进程为空
ffffffffc02042d0:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;                                // 内存管理未分配
ffffffffc02042d4:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context)); // 清空上下文信息
ffffffffc02042d8:	03050513          	addi	a0,a0,48
ffffffffc02042dc:	01d000ef          	jal	ra,ffffffffc0204af8 <memset>
        proc->tf = NULL;                                // 无中断帧
        proc->cr3 = boot_cr3;                           // 使用内核页目录表
ffffffffc02042e0:	00012797          	auipc	a5,0x12
ffffffffc02042e4:	2a07b783          	ld	a5,672(a5) # ffffffffc0216580 <boot_cr3>
        proc->tf = NULL;                                // 无中断帧
ffffffffc02042e8:	0a043023          	sd	zero,160(s0)
        proc->cr3 = boot_cr3;                           // 使用内核页目录表
ffffffffc02042ec:	f45c                	sd	a5,168(s0)
        proc->flags = 0;                                // 标志位为 0
ffffffffc02042ee:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN+1);         // 进程名清空
ffffffffc02042f2:	4641                	li	a2,16
ffffffffc02042f4:	4581                	li	a1,0
ffffffffc02042f6:	0b440513          	addi	a0,s0,180
ffffffffc02042fa:	7fe000ef          	jal	ra,ffffffffc0204af8 <memset>
    }
    return proc; // 返回已初始化的进程结构体
}
ffffffffc02042fe:	60a2                	ld	ra,8(sp)
ffffffffc0204300:	8522                	mv	a0,s0
ffffffffc0204302:	6402                	ld	s0,0(sp)
ffffffffc0204304:	0141                	addi	sp,sp,16
ffffffffc0204306:	8082                	ret

ffffffffc0204308 <forkret>:
// forkret - 新线程/进程的第一个内核入口点
// 注意：forkret 的地址在 copy_thread 函数中设置
//       在 switch_to 调用之后，当前进程将执行这里的代码
static void
forkret(void) {
    forkrets(current->tf); // 从当前进程的中断帧恢复上下文
ffffffffc0204308:	00012797          	auipc	a5,0x12
ffffffffc020430c:	2a87b783          	ld	a5,680(a5) # ffffffffc02165b0 <current>
ffffffffc0204310:	73c8                	ld	a0,160(a5)
ffffffffc0204312:	85bfc06f          	j	ffffffffc0200b6c <forkrets>

ffffffffc0204316 <init_main>:
    panic("process exit!!.\n"); // 暂未实现，直接触发内核错误
}

// init_main - 第二个内核线程，用于创建用户主线程 user_main
static int
init_main(void *arg) {
ffffffffc0204316:	7179                	addi	sp,sp,-48
ffffffffc0204318:	ec26                	sd	s1,24(sp)
    memset(name, 0, sizeof(name));                      // 清空
ffffffffc020431a:	00012497          	auipc	s1,0x12
ffffffffc020431e:	1fe48493          	addi	s1,s1,510 # ffffffffc0216518 <name.2>
init_main(void *arg) {
ffffffffc0204322:	f022                	sd	s0,32(sp)
ffffffffc0204324:	e84a                	sd	s2,16(sp)
ffffffffc0204326:	842a                	mv	s0,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current)); // 打印 initproc 的信息
ffffffffc0204328:	00012917          	auipc	s2,0x12
ffffffffc020432c:	28893903          	ld	s2,648(s2) # ffffffffc02165b0 <current>
    memset(name, 0, sizeof(name));                      // 清空
ffffffffc0204330:	4641                	li	a2,16
ffffffffc0204332:	4581                	li	a1,0
ffffffffc0204334:	8526                	mv	a0,s1
init_main(void *arg) {
ffffffffc0204336:	f406                	sd	ra,40(sp)
ffffffffc0204338:	e44e                	sd	s3,8(sp)
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current)); // 打印 initproc 的信息
ffffffffc020433a:	00492983          	lw	s3,4(s2)
    memset(name, 0, sizeof(name));                      // 清空
ffffffffc020433e:	7ba000ef          	jal	ra,ffffffffc0204af8 <memset>
    return memcpy(name, proc->name, PROC_NAME_LEN);     // 复制名称
ffffffffc0204342:	0b490593          	addi	a1,s2,180
ffffffffc0204346:	463d                	li	a2,15
ffffffffc0204348:	8526                	mv	a0,s1
ffffffffc020434a:	7c0000ef          	jal	ra,ffffffffc0204b0a <memcpy>
ffffffffc020434e:	862a                	mv	a2,a0
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current)); // 打印 initproc 的信息
ffffffffc0204350:	85ce                	mv	a1,s3
ffffffffc0204352:	00003517          	auipc	a0,0x3
ffffffffc0204356:	8f650513          	addi	a0,a0,-1802 # ffffffffc0206c48 <default_pmm_manager+0x5e0>
ffffffffc020435a:	d73fb0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("To U: \"%s\".\n", (const char *)arg); // 输出传入的字符串参数
ffffffffc020435e:	85a2                	mv	a1,s0
ffffffffc0204360:	00003517          	auipc	a0,0x3
ffffffffc0204364:	91050513          	addi	a0,a0,-1776 # ffffffffc0206c70 <default_pmm_manager+0x608>
ffffffffc0204368:	d65fb0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("To U: \"en.., Bye, Bye. :)\"\n"); // 输出示例信息
ffffffffc020436c:	00003517          	auipc	a0,0x3
ffffffffc0204370:	91450513          	addi	a0,a0,-1772 # ffffffffc0206c80 <default_pmm_manager+0x618>
ffffffffc0204374:	d59fb0ef          	jal	ra,ffffffffc02000cc <cprintf>
    return 0; // 返回 0 表示线程成功运行
}
ffffffffc0204378:	70a2                	ld	ra,40(sp)
ffffffffc020437a:	7402                	ld	s0,32(sp)
ffffffffc020437c:	64e2                	ld	s1,24(sp)
ffffffffc020437e:	6942                	ld	s2,16(sp)
ffffffffc0204380:	69a2                	ld	s3,8(sp)
ffffffffc0204382:	4501                	li	a0,0
ffffffffc0204384:	6145                	addi	sp,sp,48
ffffffffc0204386:	8082                	ret

ffffffffc0204388 <proc_run>:
proc_run(struct proc_struct *proc) {
ffffffffc0204388:	7179                	addi	sp,sp,-48
ffffffffc020438a:	f026                	sd	s1,32(sp)
    if (proc != current) { // 如果新进程不是当前正在运行的进程
ffffffffc020438c:	00012497          	auipc	s1,0x12
ffffffffc0204390:	22448493          	addi	s1,s1,548 # ffffffffc02165b0 <current>
ffffffffc0204394:	6098                	ld	a4,0(s1)
proc_run(struct proc_struct *proc) {
ffffffffc0204396:	f406                	sd	ra,40(sp)
ffffffffc0204398:	ec4a                	sd	s2,24(sp)
    if (proc != current) { // 如果新进程不是当前正在运行的进程
ffffffffc020439a:	02a70863          	beq	a4,a0,ffffffffc02043ca <proc_run+0x42>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020439e:	100027f3          	csrr	a5,sstatus
ffffffffc02043a2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02043a4:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02043a6:	ef8d                	bnez	a5,ffffffffc02043e0 <proc_run+0x58>
        lcr3(current->cr3);                // 加载新进程的页目录表地址到 CR3 寄存器
ffffffffc02043a8:	755c                	ld	a5,168(a0)

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned int cr3) {
    write_csr(sptbr, SATP32_MODE | (cr3 >> RISCV_PGSHIFT));
ffffffffc02043aa:	800006b7          	lui	a3,0x80000
        current = proc;                    // 切换到新进程
ffffffffc02043ae:	e088                	sd	a0,0(s1)
ffffffffc02043b0:	00c7d79b          	srliw	a5,a5,0xc
ffffffffc02043b4:	8fd5                	or	a5,a5,a3
ffffffffc02043b6:	18079073          	csrw	satp,a5
        switch_to(&(temp->context), &(proc->context)); // 执行上下文切换
ffffffffc02043ba:	03050593          	addi	a1,a0,48
ffffffffc02043be:	03070513          	addi	a0,a4,48
ffffffffc02043c2:	e7bff0ef          	jal	ra,ffffffffc020423c <switch_to>
    if (flag) {
ffffffffc02043c6:	00091763          	bnez	s2,ffffffffc02043d4 <proc_run+0x4c>
}
ffffffffc02043ca:	70a2                	ld	ra,40(sp)
ffffffffc02043cc:	7482                	ld	s1,32(sp)
ffffffffc02043ce:	6962                	ld	s2,24(sp)
ffffffffc02043d0:	6145                	addi	sp,sp,48
ffffffffc02043d2:	8082                	ret
ffffffffc02043d4:	70a2                	ld	ra,40(sp)
ffffffffc02043d6:	7482                	ld	s1,32(sp)
ffffffffc02043d8:	6962                	ld	s2,24(sp)
ffffffffc02043da:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc02043dc:	9e2fc06f          	j	ffffffffc02005be <intr_enable>
ffffffffc02043e0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02043e2:	9e2fc0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        struct proc_struct *temp = current; // 保存当前进程
ffffffffc02043e6:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc02043e8:	6522                	ld	a0,8(sp)
ffffffffc02043ea:	4905                	li	s2,1
ffffffffc02043ec:	bf75                	j	ffffffffc02043a8 <proc_run+0x20>

ffffffffc02043ee <do_fork>:
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc02043ee:	7179                	addi	sp,sp,-48
ffffffffc02043f0:	ec26                	sd	s1,24(sp)
    if (nr_process >= MAX_PROCESS) { // 检查进程数量是否超过最大限制
ffffffffc02043f2:	00012497          	auipc	s1,0x12
ffffffffc02043f6:	1d648493          	addi	s1,s1,470 # ffffffffc02165c8 <nr_process>
ffffffffc02043fa:	4098                	lw	a4,0(s1)
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc02043fc:	f406                	sd	ra,40(sp)
ffffffffc02043fe:	f022                	sd	s0,32(sp)
ffffffffc0204400:	e84a                	sd	s2,16(sp)
ffffffffc0204402:	e44e                	sd	s3,8(sp)
ffffffffc0204404:	e052                	sd	s4,0(sp)
    if (nr_process >= MAX_PROCESS) { // 检查进程数量是否超过最大限制
ffffffffc0204406:	6785                	lui	a5,0x1
ffffffffc0204408:	26f75163          	bge	a4,a5,ffffffffc020466a <do_fork+0x27c>
ffffffffc020440c:	892e                	mv	s2,a1
ffffffffc020440e:	8432                	mv	s0,a2
    proc = alloc_proc(); // 分配一个新的进程控制块
ffffffffc0204410:	e97ff0ef          	jal	ra,ffffffffc02042a6 <alloc_proc>
ffffffffc0204414:	89aa                	mv	s3,a0
    if (proc == NULL) {
ffffffffc0204416:	24050f63          	beqz	a0,ffffffffc0204674 <do_fork+0x286>
    proc->parent = current; // 设置父进程为当前进程
ffffffffc020441a:	00012a17          	auipc	s4,0x12
ffffffffc020441e:	196a0a13          	addi	s4,s4,406 # ffffffffc02165b0 <current>
ffffffffc0204422:	000a3783          	ld	a5,0(s4)
    struct Page *page = alloc_pages(KSTACKPAGE); // 分配 KSTACKPAGE 页的内存
ffffffffc0204426:	4509                	li	a0,2
    proc->parent = current; // 设置父进程为当前进程
ffffffffc0204428:	02f9b023          	sd	a5,32(s3)
    struct Page *page = alloc_pages(KSTACKPAGE); // 分配 KSTACKPAGE 页的内存
ffffffffc020442c:	b99fe0ef          	jal	ra,ffffffffc0202fc4 <alloc_pages>
    if (page != NULL) { // 如果分配成功
ffffffffc0204430:	1e050763          	beqz	a0,ffffffffc020461e <do_fork+0x230>
    return page - pages + nbase;
ffffffffc0204434:	00012697          	auipc	a3,0x12
ffffffffc0204438:	1646b683          	ld	a3,356(a3) # ffffffffc0216598 <pages>
ffffffffc020443c:	40d506b3          	sub	a3,a0,a3
ffffffffc0204440:	8699                	srai	a3,a3,0x6
ffffffffc0204442:	00003517          	auipc	a0,0x3
ffffffffc0204446:	bfe53503          	ld	a0,-1026(a0) # ffffffffc0207040 <nbase>
ffffffffc020444a:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc020444c:	00c69793          	slli	a5,a3,0xc
ffffffffc0204450:	83b1                	srli	a5,a5,0xc
ffffffffc0204452:	00012717          	auipc	a4,0x12
ffffffffc0204456:	13e73703          	ld	a4,318(a4) # ffffffffc0216590 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc020445a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020445c:	22e7fe63          	bgeu	a5,a4,ffffffffc0204698 <do_fork+0x2aa>
    assert(current->mm == NULL); // 确保当前进程没有内存管理结构
ffffffffc0204460:	000a3783          	ld	a5,0(s4)
ffffffffc0204464:	00012717          	auipc	a4,0x12
ffffffffc0204468:	14473703          	ld	a4,324(a4) # ffffffffc02165a8 <va_pa_offset>
ffffffffc020446c:	96ba                	add	a3,a3,a4
ffffffffc020446e:	779c                	ld	a5,40(a5)
        proc->kstack = (uintptr_t)page2kva(page); // 设置内核栈地址
ffffffffc0204470:	00d9b823          	sd	a3,16(s3)
    assert(current->mm == NULL); // 确保当前进程没有内存管理结构
ffffffffc0204474:	20079263          	bnez	a5,ffffffffc0204678 <do_fork+0x28a>
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe)); // 分配内核栈顶部用于保存中断帧
ffffffffc0204478:	6789                	lui	a5,0x2
ffffffffc020447a:	ee078793          	addi	a5,a5,-288 # 1ee0 <kern_entry-0xffffffffc01fe120>
ffffffffc020447e:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf; // 复制中断帧内容
ffffffffc0204480:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe)); // 分配内核栈顶部用于保存中断帧
ffffffffc0204482:	0ad9b023          	sd	a3,160(s3)
    *(proc->tf) = *tf; // 复制中断帧内容
ffffffffc0204486:	87b6                	mv	a5,a3
ffffffffc0204488:	12040893          	addi	a7,s0,288
ffffffffc020448c:	00063803          	ld	a6,0(a2)
ffffffffc0204490:	6608                	ld	a0,8(a2)
ffffffffc0204492:	6a0c                	ld	a1,16(a2)
ffffffffc0204494:	6e18                	ld	a4,24(a2)
ffffffffc0204496:	0107b023          	sd	a6,0(a5)
ffffffffc020449a:	e788                	sd	a0,8(a5)
ffffffffc020449c:	eb8c                	sd	a1,16(a5)
ffffffffc020449e:	ef98                	sd	a4,24(a5)
ffffffffc02044a0:	02060613          	addi	a2,a2,32
ffffffffc02044a4:	02078793          	addi	a5,a5,32
ffffffffc02044a8:	ff1612e3          	bne	a2,a7,ffffffffc020448c <do_fork+0x9e>
    proc->tf->gpr.a0 = 0; // 设置 a0 为 0，表示这是子进程
ffffffffc02044ac:	0406b823          	sd	zero,80(a3)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp; // 设置栈指针
ffffffffc02044b0:	12090563          	beqz	s2,ffffffffc02045da <do_fork+0x1ec>
ffffffffc02044b4:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret; // 设置返回地址为 forkret
ffffffffc02044b8:	00000797          	auipc	a5,0x0
ffffffffc02044bc:	e5078793          	addi	a5,a5,-432 # ffffffffc0204308 <forkret>
ffffffffc02044c0:	02f9b823          	sd	a5,48(s3)
    proc->context.sp = (uintptr_t)(proc->tf); // 设置上下文的栈指针
ffffffffc02044c4:	02d9bc23          	sd	a3,56(s3)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02044c8:	100027f3          	csrr	a5,sstatus
ffffffffc02044cc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02044ce:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02044d0:	12079663          	bnez	a5,ffffffffc02045fc <do_fork+0x20e>
    if (++last_pid >= MAX_PID) {          // 如果超出最大值，重置为 1
ffffffffc02044d4:	00007817          	auipc	a6,0x7
ffffffffc02044d8:	b8480813          	addi	a6,a6,-1148 # ffffffffc020b058 <last_pid.1>
ffffffffc02044dc:	00082783          	lw	a5,0(a6)
ffffffffc02044e0:	6709                	lui	a4,0x2
ffffffffc02044e2:	0017851b          	addiw	a0,a5,1
ffffffffc02044e6:	00a82023          	sw	a0,0(a6)
ffffffffc02044ea:	08e55163          	bge	a0,a4,ffffffffc020456c <do_fork+0x17e>
    if (last_pid >= next_safe) {
ffffffffc02044ee:	00007317          	auipc	t1,0x7
ffffffffc02044f2:	b6e30313          	addi	t1,t1,-1170 # ffffffffc020b05c <next_safe.0>
ffffffffc02044f6:	00032783          	lw	a5,0(t1)
ffffffffc02044fa:	00012417          	auipc	s0,0x12
ffffffffc02044fe:	02e40413          	addi	s0,s0,46 # ffffffffc0216528 <proc_list>
ffffffffc0204502:	06f55d63          	bge	a0,a5,ffffffffc020457c <do_fork+0x18e>
    proc->pid = get_pid(); // 分配唯一的 PID
ffffffffc0204506:	00a9a223          	sw	a0,4(s3)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link)); // 根据 PID 哈希值插入哈希链表
ffffffffc020450a:	45a9                	li	a1,10
ffffffffc020450c:	2501                	sext.w	a0,a0
ffffffffc020450e:	227000ef          	jal	ra,ffffffffc0204f34 <hash32>
ffffffffc0204512:	02051793          	slli	a5,a0,0x20
ffffffffc0204516:	01c7d513          	srli	a0,a5,0x1c
ffffffffc020451a:	0000e797          	auipc	a5,0xe
ffffffffc020451e:	ffe78793          	addi	a5,a5,-2 # ffffffffc0212518 <hash_list>
ffffffffc0204522:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0204524:	6510                	ld	a2,8(a0)
ffffffffc0204526:	0d898793          	addi	a5,s3,216
ffffffffc020452a:	6414                	ld	a3,8(s0)
    nr_process++; // 增加进程计数
ffffffffc020452c:	4098                	lw	a4,0(s1)
    prev->next = next->prev = elm;
ffffffffc020452e:	e21c                	sd	a5,0(a2)
ffffffffc0204530:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc0204532:	0ec9b023          	sd	a2,224(s3)
    list_add(&proc_list, &(proc->list_link)); // 将进程插入到全局进程列表中
ffffffffc0204536:	0c898793          	addi	a5,s3,200
    elm->prev = prev;
ffffffffc020453a:	0ca9bc23          	sd	a0,216(s3)
    prev->next = next->prev = elm;
ffffffffc020453e:	e29c                	sd	a5,0(a3)
    nr_process++; // 增加进程计数
ffffffffc0204540:	2705                	addiw	a4,a4,1
ffffffffc0204542:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc0204544:	0cd9b823          	sd	a3,208(s3)
    elm->prev = prev;
ffffffffc0204548:	0c89b423          	sd	s0,200(s3)
ffffffffc020454c:	c098                	sw	a4,0(s1)
    if (flag) {
ffffffffc020454e:	0a091b63          	bnez	s2,ffffffffc0204604 <do_fork+0x216>
    wakeup_proc(proc); // 唤醒子进程
ffffffffc0204552:	854e                	mv	a0,s3
ffffffffc0204554:	462000ef          	jal	ra,ffffffffc02049b6 <wakeup_proc>
    ret = proc->pid; // 返回子进程的 PID
ffffffffc0204558:	0049a503          	lw	a0,4(s3)
}
ffffffffc020455c:	70a2                	ld	ra,40(sp)
ffffffffc020455e:	7402                	ld	s0,32(sp)
ffffffffc0204560:	64e2                	ld	s1,24(sp)
ffffffffc0204562:	6942                	ld	s2,16(sp)
ffffffffc0204564:	69a2                	ld	s3,8(sp)
ffffffffc0204566:	6a02                	ld	s4,0(sp)
ffffffffc0204568:	6145                	addi	sp,sp,48
ffffffffc020456a:	8082                	ret
        last_pid = 1;
ffffffffc020456c:	4785                	li	a5,1
ffffffffc020456e:	00f82023          	sw	a5,0(a6)
        goto inside; 
ffffffffc0204572:	4505                	li	a0,1
ffffffffc0204574:	00007317          	auipc	t1,0x7
ffffffffc0204578:	ae830313          	addi	t1,t1,-1304 # ffffffffc020b05c <next_safe.0>
    return listelm->next;
ffffffffc020457c:	00012417          	auipc	s0,0x12
ffffffffc0204580:	fac40413          	addi	s0,s0,-84 # ffffffffc0216528 <proc_list>
ffffffffc0204584:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc0204588:	6789                	lui	a5,0x2
ffffffffc020458a:	00f32023          	sw	a5,0(t1)
ffffffffc020458e:	86aa                	mv	a3,a0
ffffffffc0204590:	4581                	li	a1,0
        while ((le = list_next(le)) != list) {          // 遍历链表
ffffffffc0204592:	6e89                	lui	t4,0x2
ffffffffc0204594:	088e0063          	beq	t3,s0,ffffffffc0204614 <do_fork+0x226>
ffffffffc0204598:	88ae                	mv	a7,a1
ffffffffc020459a:	87f2                	mv	a5,t3
ffffffffc020459c:	6609                	lui	a2,0x2
ffffffffc020459e:	a811                	j	ffffffffc02045b2 <do_fork+0x1c4>
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc02045a0:	00e6d663          	bge	a3,a4,ffffffffc02045ac <do_fork+0x1be>
ffffffffc02045a4:	00c75463          	bge	a4,a2,ffffffffc02045ac <do_fork+0x1be>
ffffffffc02045a8:	863a                	mv	a2,a4
ffffffffc02045aa:	4885                	li	a7,1
ffffffffc02045ac:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {          // 遍历链表
ffffffffc02045ae:	00878d63          	beq	a5,s0,ffffffffc02045c8 <do_fork+0x1da>
            if (proc->pid == last_pid) { 
ffffffffc02045b2:	f3c7a703          	lw	a4,-196(a5) # 1f3c <kern_entry-0xffffffffc01fe0c4>
ffffffffc02045b6:	fed715e3          	bne	a4,a3,ffffffffc02045a0 <do_fork+0x1b2>
                if (++last_pid >= next_safe) {          // 遇到重复则递增 PID
ffffffffc02045ba:	2685                	addiw	a3,a3,1
ffffffffc02045bc:	04c6d763          	bge	a3,a2,ffffffffc020460a <do_fork+0x21c>
ffffffffc02045c0:	679c                	ld	a5,8(a5)
ffffffffc02045c2:	4585                	li	a1,1
        while ((le = list_next(le)) != list) {          // 遍历链表
ffffffffc02045c4:	fe8797e3          	bne	a5,s0,ffffffffc02045b2 <do_fork+0x1c4>
ffffffffc02045c8:	c581                	beqz	a1,ffffffffc02045d0 <do_fork+0x1e2>
ffffffffc02045ca:	00d82023          	sw	a3,0(a6)
ffffffffc02045ce:	8536                	mv	a0,a3
ffffffffc02045d0:	f2088be3          	beqz	a7,ffffffffc0204506 <do_fork+0x118>
ffffffffc02045d4:	00c32023          	sw	a2,0(t1)
ffffffffc02045d8:	b73d                	j	ffffffffc0204506 <do_fork+0x118>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp; // 设置栈指针
ffffffffc02045da:	8936                	mv	s2,a3
ffffffffc02045dc:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret; // 设置返回地址为 forkret
ffffffffc02045e0:	00000797          	auipc	a5,0x0
ffffffffc02045e4:	d2878793          	addi	a5,a5,-728 # ffffffffc0204308 <forkret>
ffffffffc02045e8:	02f9b823          	sd	a5,48(s3)
    proc->context.sp = (uintptr_t)(proc->tf); // 设置上下文的栈指针
ffffffffc02045ec:	02d9bc23          	sd	a3,56(s3)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02045f0:	100027f3          	csrr	a5,sstatus
ffffffffc02045f4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02045f6:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02045f8:	ec078ee3          	beqz	a5,ffffffffc02044d4 <do_fork+0xe6>
        intr_disable();
ffffffffc02045fc:	fc9fb0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        return 1;
ffffffffc0204600:	4905                	li	s2,1
ffffffffc0204602:	bdc9                	j	ffffffffc02044d4 <do_fork+0xe6>
        intr_enable();
ffffffffc0204604:	fbbfb0ef          	jal	ra,ffffffffc02005be <intr_enable>
ffffffffc0204608:	b7a9                	j	ffffffffc0204552 <do_fork+0x164>
                    if (last_pid >= MAX_PID) {
ffffffffc020460a:	01d6c363          	blt	a3,t4,ffffffffc0204610 <do_fork+0x222>
                        last_pid = 1;
ffffffffc020460e:	4685                	li	a3,1
                    goto repeat;
ffffffffc0204610:	4585                	li	a1,1
ffffffffc0204612:	b749                	j	ffffffffc0204594 <do_fork+0x1a6>
ffffffffc0204614:	cda9                	beqz	a1,ffffffffc020466e <do_fork+0x280>
ffffffffc0204616:	00d82023          	sw	a3,0(a6)
    return last_pid;                                   // 返回分配的 PID
ffffffffc020461a:	8536                	mv	a0,a3
ffffffffc020461c:	b5ed                	j	ffffffffc0204506 <do_fork+0x118>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE); // 释放与内核栈对应的页
ffffffffc020461e:	0109b683          	ld	a3,16(s3)
    return pa2page(PADDR(kva));
ffffffffc0204622:	c02007b7          	lui	a5,0xc0200
ffffffffc0204626:	0af6e163          	bltu	a3,a5,ffffffffc02046c8 <do_fork+0x2da>
ffffffffc020462a:	00012797          	auipc	a5,0x12
ffffffffc020462e:	f7e7b783          	ld	a5,-130(a5) # ffffffffc02165a8 <va_pa_offset>
ffffffffc0204632:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc0204636:	83b1                	srli	a5,a5,0xc
ffffffffc0204638:	00012717          	auipc	a4,0x12
ffffffffc020463c:	f5873703          	ld	a4,-168(a4) # ffffffffc0216590 <npage>
ffffffffc0204640:	06e7f863          	bgeu	a5,a4,ffffffffc02046b0 <do_fork+0x2c2>
    return &pages[PPN(pa) - nbase];
ffffffffc0204644:	00003717          	auipc	a4,0x3
ffffffffc0204648:	9fc73703          	ld	a4,-1540(a4) # ffffffffc0207040 <nbase>
ffffffffc020464c:	8f99                	sub	a5,a5,a4
ffffffffc020464e:	079a                	slli	a5,a5,0x6
ffffffffc0204650:	00012517          	auipc	a0,0x12
ffffffffc0204654:	f4853503          	ld	a0,-184(a0) # ffffffffc0216598 <pages>
ffffffffc0204658:	953e                	add	a0,a0,a5
ffffffffc020465a:	4589                	li	a1,2
ffffffffc020465c:	9fbfe0ef          	jal	ra,ffffffffc0203056 <free_pages>
    kfree(proc);
ffffffffc0204660:	854e                	mv	a0,s3
ffffffffc0204662:	c8afd0ef          	jal	ra,ffffffffc0201aec <kfree>
    ret = -E_NO_MEM; // 如果内存分配失败，返回内存不足错误
ffffffffc0204666:	5571                	li	a0,-4
    goto fork_out;
ffffffffc0204668:	bdd5                	j	ffffffffc020455c <do_fork+0x16e>
    int ret = -E_NO_FREE_PROC; // 错误码，表示没有空闲进程可用
ffffffffc020466a:	556d                	li	a0,-5
ffffffffc020466c:	bdc5                	j	ffffffffc020455c <do_fork+0x16e>
    return last_pid;                                   // 返回分配的 PID
ffffffffc020466e:	00082503          	lw	a0,0(a6)
ffffffffc0204672:	bd51                	j	ffffffffc0204506 <do_fork+0x118>
    ret = -E_NO_MEM; // 如果内存分配失败，返回内存不足错误
ffffffffc0204674:	5571                	li	a0,-4
    return ret;
ffffffffc0204676:	b5dd                	j	ffffffffc020455c <do_fork+0x16e>
    assert(current->mm == NULL); // 确保当前进程没有内存管理结构
ffffffffc0204678:	00002697          	auipc	a3,0x2
ffffffffc020467c:	62868693          	addi	a3,a3,1576 # ffffffffc0206ca0 <default_pmm_manager+0x638>
ffffffffc0204680:	00001617          	auipc	a2,0x1
ffffffffc0204684:	28060613          	addi	a2,a2,640 # ffffffffc0205900 <commands+0x728>
ffffffffc0204688:	0e800593          	li	a1,232
ffffffffc020468c:	00002517          	auipc	a0,0x2
ffffffffc0204690:	62c50513          	addi	a0,a0,1580 # ffffffffc0206cb8 <default_pmm_manager+0x650>
ffffffffc0204694:	b35fb0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return KADDR(page2pa(page));
ffffffffc0204698:	00001617          	auipc	a2,0x1
ffffffffc020469c:	4c060613          	addi	a2,a2,1216 # ffffffffc0205b58 <commands+0x980>
ffffffffc02046a0:	06900593          	li	a1,105
ffffffffc02046a4:	00001517          	auipc	a0,0x1
ffffffffc02046a8:	4a450513          	addi	a0,a0,1188 # ffffffffc0205b48 <commands+0x970>
ffffffffc02046ac:	b1dfb0ef          	jal	ra,ffffffffc02001c8 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02046b0:	00001617          	auipc	a2,0x1
ffffffffc02046b4:	47860613          	addi	a2,a2,1144 # ffffffffc0205b28 <commands+0x950>
ffffffffc02046b8:	06200593          	li	a1,98
ffffffffc02046bc:	00001517          	auipc	a0,0x1
ffffffffc02046c0:	48c50513          	addi	a0,a0,1164 # ffffffffc0205b48 <commands+0x970>
ffffffffc02046c4:	b05fb0ef          	jal	ra,ffffffffc02001c8 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02046c8:	00002617          	auipc	a2,0x2
ffffffffc02046cc:	85060613          	addi	a2,a2,-1968 # ffffffffc0205f18 <commands+0xd40>
ffffffffc02046d0:	06e00593          	li	a1,110
ffffffffc02046d4:	00001517          	auipc	a0,0x1
ffffffffc02046d8:	47450513          	addi	a0,a0,1140 # ffffffffc0205b48 <commands+0x970>
ffffffffc02046dc:	aedfb0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02046e0 <kernel_thread>:
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02046e0:	7129                	addi	sp,sp,-320
ffffffffc02046e2:	fa22                	sd	s0,304(sp)
ffffffffc02046e4:	f626                	sd	s1,296(sp)
ffffffffc02046e6:	f24a                	sd	s2,288(sp)
ffffffffc02046e8:	84ae                	mv	s1,a1
ffffffffc02046ea:	892a                	mv	s2,a0
ffffffffc02046ec:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe)); // 初始化中断帧
ffffffffc02046ee:	4581                	li	a1,0
ffffffffc02046f0:	12000613          	li	a2,288
ffffffffc02046f4:	850a                	mv	a0,sp
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02046f6:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe)); // 初始化中断帧
ffffffffc02046f8:	400000ef          	jal	ra,ffffffffc0204af8 <memset>
    tf.gpr.s0 = (uintptr_t)fn;               // 设置 s0 为函数入口地址
ffffffffc02046fc:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;              // 设置 s1 为函数参数
ffffffffc02046fe:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE; // 设置状态寄存器
ffffffffc0204700:	100027f3          	csrr	a5,sstatus
ffffffffc0204704:	edd7f793          	andi	a5,a5,-291
ffffffffc0204708:	1207e793          	ori	a5,a5,288
ffffffffc020470c:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf); // 调用 do_fork 创建线程
ffffffffc020470e:	860a                	mv	a2,sp
ffffffffc0204710:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry; // 设置 EPC 为内核线程入口点
ffffffffc0204714:	00000797          	auipc	a5,0x0
ffffffffc0204718:	b2078793          	addi	a5,a5,-1248 # ffffffffc0204234 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf); // 调用 do_fork 创建线程
ffffffffc020471c:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry; // 设置 EPC 为内核线程入口点
ffffffffc020471e:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf); // 调用 do_fork 创建线程
ffffffffc0204720:	ccfff0ef          	jal	ra,ffffffffc02043ee <do_fork>
}
ffffffffc0204724:	70f2                	ld	ra,312(sp)
ffffffffc0204726:	7452                	ld	s0,304(sp)
ffffffffc0204728:	74b2                	ld	s1,296(sp)
ffffffffc020472a:	7912                	ld	s2,288(sp)
ffffffffc020472c:	6131                	addi	sp,sp,320
ffffffffc020472e:	8082                	ret

ffffffffc0204730 <do_exit>:
do_exit(int error_code) {
ffffffffc0204730:	1141                	addi	sp,sp,-16
    panic("process exit!!.\n"); // 暂未实现，直接触发内核错误
ffffffffc0204732:	00002617          	auipc	a2,0x2
ffffffffc0204736:	59e60613          	addi	a2,a2,1438 # ffffffffc0206cd0 <default_pmm_manager+0x668>
ffffffffc020473a:	13200593          	li	a1,306
ffffffffc020473e:	00002517          	auipc	a0,0x2
ffffffffc0204742:	57a50513          	addi	a0,a0,1402 # ffffffffc0206cb8 <default_pmm_manager+0x650>
do_exit(int error_code) {
ffffffffc0204746:	e406                	sd	ra,8(sp)
    panic("process exit!!.\n"); // 暂未实现，直接触发内核错误
ffffffffc0204748:	a81fb0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc020474c <proc_init>:

// proc_init - 创建并设置第一个内核线程 idleproc，同时创建第二个内核线程 init_main
void
proc_init(void) {
ffffffffc020474c:	7179                	addi	sp,sp,-48
ffffffffc020474e:	ec26                	sd	s1,24(sp)
    elm->prev = elm->next = elm;
ffffffffc0204750:	00012797          	auipc	a5,0x12
ffffffffc0204754:	dd878793          	addi	a5,a5,-552 # ffffffffc0216528 <proc_list>
ffffffffc0204758:	f406                	sd	ra,40(sp)
ffffffffc020475a:	f022                	sd	s0,32(sp)
ffffffffc020475c:	e84a                	sd	s2,16(sp)
ffffffffc020475e:	e44e                	sd	s3,8(sp)
ffffffffc0204760:	0000e497          	auipc	s1,0xe
ffffffffc0204764:	db848493          	addi	s1,s1,-584 # ffffffffc0212518 <hash_list>
ffffffffc0204768:	e79c                	sd	a5,8(a5)
ffffffffc020476a:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list); // 初始化全局进程链表
    for (i = 0; i < HASH_LIST_SIZE; i++) {
ffffffffc020476c:	00012717          	auipc	a4,0x12
ffffffffc0204770:	dac70713          	addi	a4,a4,-596 # ffffffffc0216518 <name.2>
ffffffffc0204774:	87a6                	mv	a5,s1
ffffffffc0204776:	e79c                	sd	a5,8(a5)
ffffffffc0204778:	e39c                	sd	a5,0(a5)
ffffffffc020477a:	07c1                	addi	a5,a5,16
ffffffffc020477c:	fef71de3          	bne	a4,a5,ffffffffc0204776 <proc_init+0x2a>
        list_init(hash_list + i); // 初始化进程哈希表的每个链表
    }

    if ((idleproc = alloc_proc()) == NULL) { // 分配第一个内核线程 idleproc
ffffffffc0204780:	b27ff0ef          	jal	ra,ffffffffc02042a6 <alloc_proc>
ffffffffc0204784:	00012917          	auipc	s2,0x12
ffffffffc0204788:	e3490913          	addi	s2,s2,-460 # ffffffffc02165b8 <idleproc>
ffffffffc020478c:	00a93023          	sd	a0,0(s2)
ffffffffc0204790:	18050d63          	beqz	a0,ffffffffc020492a <proc_init+0x1de>
        panic("cannot alloc idleproc.\n"); // 如果分配失败，触发内核错误
    }

    // 校验 idleproc 结构体是否正确初始化
    int *context_mem = (int *)kmalloc(sizeof(struct context)); // 临时内存用于比较
ffffffffc0204794:	07000513          	li	a0,112
ffffffffc0204798:	aa4fd0ef          	jal	ra,ffffffffc0201a3c <kmalloc>
    memset(context_mem, 0, sizeof(struct context)); // 清空临时内存
ffffffffc020479c:	07000613          	li	a2,112
ffffffffc02047a0:	4581                	li	a1,0
    int *context_mem = (int *)kmalloc(sizeof(struct context)); // 临时内存用于比较
ffffffffc02047a2:	842a                	mv	s0,a0
    memset(context_mem, 0, sizeof(struct context)); // 清空临时内存
ffffffffc02047a4:	354000ef          	jal	ra,ffffffffc0204af8 <memset>
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context)); // 比较上下文初始化状态
ffffffffc02047a8:	00093503          	ld	a0,0(s2)
ffffffffc02047ac:	85a2                	mv	a1,s0
ffffffffc02047ae:	07000613          	li	a2,112
ffffffffc02047b2:	03050513          	addi	a0,a0,48
ffffffffc02047b6:	36c000ef          	jal	ra,ffffffffc0204b22 <memcmp>
ffffffffc02047ba:	89aa                	mv	s3,a0

    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN); // 临时内存用于比较进程名
ffffffffc02047bc:	453d                	li	a0,15
ffffffffc02047be:	a7efd0ef          	jal	ra,ffffffffc0201a3c <kmalloc>
    memset(proc_name_mem, 0, PROC_NAME_LEN); // 清空临时内存
ffffffffc02047c2:	463d                	li	a2,15
ffffffffc02047c4:	4581                	li	a1,0
    int *proc_name_mem = (int *)kmalloc(PROC_NAME_LEN); // 临时内存用于比较进程名
ffffffffc02047c6:	842a                	mv	s0,a0
    memset(proc_name_mem, 0, PROC_NAME_LEN); // 清空临时内存
ffffffffc02047c8:	330000ef          	jal	ra,ffffffffc0204af8 <memset>
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN); // 比较进程名初始化状态
ffffffffc02047cc:	00093503          	ld	a0,0(s2)
ffffffffc02047d0:	463d                	li	a2,15
ffffffffc02047d2:	85a2                	mv	a1,s0
ffffffffc02047d4:	0b450513          	addi	a0,a0,180
ffffffffc02047d8:	34a000ef          	jal	ra,ffffffffc0204b22 <memcmp>

    // 如果所有字段都初始化正确，则打印验证信息
    if (idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
ffffffffc02047dc:	00093783          	ld	a5,0(s2)
ffffffffc02047e0:	00012717          	auipc	a4,0x12
ffffffffc02047e4:	da073703          	ld	a4,-608(a4) # ffffffffc0216580 <boot_cr3>
ffffffffc02047e8:	77d4                	ld	a3,168(a5)
ffffffffc02047ea:	0ee68463          	beq	a3,a4,ffffffffc02048d2 <proc_init+0x186>
        cprintf("alloc_proc() correct!\n");
    }
    
    // 初始化 idleproc 的字段
    idleproc->pid = 0; // 设置 PID 为 0
    idleproc->state = PROC_RUNNABLE; // 设置为可运行状态
ffffffffc02047ee:	4709                	li	a4,2
ffffffffc02047f0:	e398                	sd	a4,0(a5)
    idleproc->kstack = (uintptr_t)bootstack; // 设置内核栈为内核启动栈
ffffffffc02047f2:	00004717          	auipc	a4,0x4
ffffffffc02047f6:	80e70713          	addi	a4,a4,-2034 # ffffffffc0208000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));          // 清空原名称
ffffffffc02047fa:	0b478413          	addi	s0,a5,180
    idleproc->kstack = (uintptr_t)bootstack; // 设置内核栈为内核启动栈
ffffffffc02047fe:	eb98                	sd	a4,16(a5)
    idleproc->need_resched = 1; // 标记需要重新调度
ffffffffc0204800:	4705                	li	a4,1
ffffffffc0204802:	cf98                	sw	a4,24(a5)
    memset(proc->name, 0, sizeof(proc->name));          // 清空原名称
ffffffffc0204804:	4641                	li	a2,16
ffffffffc0204806:	4581                	li	a1,0
ffffffffc0204808:	8522                	mv	a0,s0
ffffffffc020480a:	2ee000ef          	jal	ra,ffffffffc0204af8 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);     // 复制新名称
ffffffffc020480e:	463d                	li	a2,15
ffffffffc0204810:	00002597          	auipc	a1,0x2
ffffffffc0204814:	50858593          	addi	a1,a1,1288 # ffffffffc0206d18 <default_pmm_manager+0x6b0>
ffffffffc0204818:	8522                	mv	a0,s0
ffffffffc020481a:	2f0000ef          	jal	ra,ffffffffc0204b0a <memcpy>
    set_proc_name(idleproc, "idle"); // 设置进程名为 "idle"
    nr_process++; // 增加进程计数
ffffffffc020481e:	00012717          	auipc	a4,0x12
ffffffffc0204822:	daa70713          	addi	a4,a4,-598 # ffffffffc02165c8 <nr_process>
ffffffffc0204826:	431c                	lw	a5,0(a4)

    current = idleproc; // 当前运行的进程设置为 idleproc
ffffffffc0204828:	00093683          	ld	a3,0(s2)

    // 创建 init_main 线程
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020482c:	4601                	li	a2,0
    nr_process++; // 增加进程计数
ffffffffc020482e:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc0204830:	00002597          	auipc	a1,0x2
ffffffffc0204834:	4f058593          	addi	a1,a1,1264 # ffffffffc0206d20 <default_pmm_manager+0x6b8>
ffffffffc0204838:	00000517          	auipc	a0,0x0
ffffffffc020483c:	ade50513          	addi	a0,a0,-1314 # ffffffffc0204316 <init_main>
    nr_process++; // 增加进程计数
ffffffffc0204840:	c31c                	sw	a5,0(a4)
    current = idleproc; // 当前运行的进程设置为 idleproc
ffffffffc0204842:	00012797          	auipc	a5,0x12
ffffffffc0204846:	d6d7b723          	sd	a3,-658(a5) # ffffffffc02165b0 <current>
    int pid = kernel_thread(init_main, "Hello world!!", 0);
ffffffffc020484a:	e97ff0ef          	jal	ra,ffffffffc02046e0 <kernel_thread>
ffffffffc020484e:	842a                	mv	s0,a0
    if (pid <= 0) { // 如果线程创建失败，触发内核错误
ffffffffc0204850:	0ea05963          	blez	a0,ffffffffc0204942 <proc_init+0x1f6>
    if (0 < pid && pid < MAX_PID) { // 确保 PID 合法
ffffffffc0204854:	6789                	lui	a5,0x2
ffffffffc0204856:	fff5071b          	addiw	a4,a0,-1
ffffffffc020485a:	17f9                	addi	a5,a5,-2
ffffffffc020485c:	2501                	sext.w	a0,a0
ffffffffc020485e:	02e7e363          	bltu	a5,a4,ffffffffc0204884 <proc_init+0x138>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204862:	45a9                	li	a1,10
ffffffffc0204864:	6d0000ef          	jal	ra,ffffffffc0204f34 <hash32>
ffffffffc0204868:	02051793          	slli	a5,a0,0x20
ffffffffc020486c:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204870:	96a6                	add	a3,a3,s1
ffffffffc0204872:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list) { // 遍历对应哈希链表
ffffffffc0204874:	a029                	j	ffffffffc020487e <proc_init+0x132>
            if (proc->pid == pid) { // 找到匹配的进程
ffffffffc0204876:	f2c7a703          	lw	a4,-212(a5) # 1f2c <kern_entry-0xffffffffc01fe0d4>
ffffffffc020487a:	0a870563          	beq	a4,s0,ffffffffc0204924 <proc_init+0x1d8>
    return listelm->next;
ffffffffc020487e:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) { // 遍历对应哈希链表
ffffffffc0204880:	fef69be3          	bne	a3,a5,ffffffffc0204876 <proc_init+0x12a>
    return NULL; // 未找到匹配的进程
ffffffffc0204884:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));          // 清空原名称
ffffffffc0204886:	0b478493          	addi	s1,a5,180
ffffffffc020488a:	4641                	li	a2,16
ffffffffc020488c:	4581                	li	a1,0
        panic("create init_main failed.\n");
    }
    initproc = find_proc(pid); // 根据 PID 查找 init_main 线程的进程结构体
ffffffffc020488e:	00012417          	auipc	s0,0x12
ffffffffc0204892:	d3240413          	addi	s0,s0,-718 # ffffffffc02165c0 <initproc>
    memset(proc->name, 0, sizeof(proc->name));          // 清空原名称
ffffffffc0204896:	8526                	mv	a0,s1
    initproc = find_proc(pid); // 根据 PID 查找 init_main 线程的进程结构体
ffffffffc0204898:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));          // 清空原名称
ffffffffc020489a:	25e000ef          	jal	ra,ffffffffc0204af8 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);     // 复制新名称
ffffffffc020489e:	463d                	li	a2,15
ffffffffc02048a0:	00002597          	auipc	a1,0x2
ffffffffc02048a4:	4b058593          	addi	a1,a1,1200 # ffffffffc0206d50 <default_pmm_manager+0x6e8>
ffffffffc02048a8:	8526                	mv	a0,s1
ffffffffc02048aa:	260000ef          	jal	ra,ffffffffc0204b0a <memcpy>
    set_proc_name(initproc, "init"); // 设置进程名为 "init"

    // 验证 idleproc 和 initproc 是否正确初始化
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02048ae:	00093783          	ld	a5,0(s2)
ffffffffc02048b2:	c7e1                	beqz	a5,ffffffffc020497a <proc_init+0x22e>
ffffffffc02048b4:	43dc                	lw	a5,4(a5)
ffffffffc02048b6:	e3f1                	bnez	a5,ffffffffc020497a <proc_init+0x22e>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc02048b8:	601c                	ld	a5,0(s0)
ffffffffc02048ba:	c3c5                	beqz	a5,ffffffffc020495a <proc_init+0x20e>
ffffffffc02048bc:	43d8                	lw	a4,4(a5)
ffffffffc02048be:	4785                	li	a5,1
ffffffffc02048c0:	08f71d63          	bne	a4,a5,ffffffffc020495a <proc_init+0x20e>
}
ffffffffc02048c4:	70a2                	ld	ra,40(sp)
ffffffffc02048c6:	7402                	ld	s0,32(sp)
ffffffffc02048c8:	64e2                	ld	s1,24(sp)
ffffffffc02048ca:	6942                	ld	s2,16(sp)
ffffffffc02048cc:	69a2                	ld	s3,8(sp)
ffffffffc02048ce:	6145                	addi	sp,sp,48
ffffffffc02048d0:	8082                	ret
    if (idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
ffffffffc02048d2:	73d8                	ld	a4,160(a5)
ffffffffc02048d4:	ff09                	bnez	a4,ffffffffc02047ee <proc_init+0xa2>
ffffffffc02048d6:	f0099ce3          	bnez	s3,ffffffffc02047ee <proc_init+0xa2>
        && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0
ffffffffc02048da:	6394                	ld	a3,0(a5)
ffffffffc02048dc:	577d                	li	a4,-1
ffffffffc02048de:	1702                	slli	a4,a4,0x20
ffffffffc02048e0:	f0e697e3          	bne	a3,a4,ffffffffc02047ee <proc_init+0xa2>
ffffffffc02048e4:	4798                	lw	a4,8(a5)
ffffffffc02048e6:	f00714e3          	bnez	a4,ffffffffc02047ee <proc_init+0xa2>
        && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL
ffffffffc02048ea:	6b98                	ld	a4,16(a5)
ffffffffc02048ec:	f00711e3          	bnez	a4,ffffffffc02047ee <proc_init+0xa2>
ffffffffc02048f0:	4f98                	lw	a4,24(a5)
ffffffffc02048f2:	2701                	sext.w	a4,a4
ffffffffc02048f4:	ee071de3          	bnez	a4,ffffffffc02047ee <proc_init+0xa2>
ffffffffc02048f8:	7398                	ld	a4,32(a5)
ffffffffc02048fa:	ee071ae3          	bnez	a4,ffffffffc02047ee <proc_init+0xa2>
        && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag) {
ffffffffc02048fe:	7798                	ld	a4,40(a5)
ffffffffc0204900:	ee0717e3          	bnez	a4,ffffffffc02047ee <proc_init+0xa2>
ffffffffc0204904:	0b07a703          	lw	a4,176(a5)
ffffffffc0204908:	8d59                	or	a0,a0,a4
ffffffffc020490a:	0005071b          	sext.w	a4,a0
ffffffffc020490e:	ee0710e3          	bnez	a4,ffffffffc02047ee <proc_init+0xa2>
        cprintf("alloc_proc() correct!\n");
ffffffffc0204912:	00002517          	auipc	a0,0x2
ffffffffc0204916:	3ee50513          	addi	a0,a0,1006 # ffffffffc0206d00 <default_pmm_manager+0x698>
ffffffffc020491a:	fb2fb0ef          	jal	ra,ffffffffc02000cc <cprintf>
    idleproc->pid = 0; // 设置 PID 为 0
ffffffffc020491e:	00093783          	ld	a5,0(s2)
ffffffffc0204922:	b5f1                	j	ffffffffc02047ee <proc_init+0xa2>
            struct proc_struct *proc = le2proc(le, hash_link); // 从链表节点获取进程结构体
ffffffffc0204924:	f2878793          	addi	a5,a5,-216
ffffffffc0204928:	bfb9                	j	ffffffffc0204886 <proc_init+0x13a>
        panic("cannot alloc idleproc.\n"); // 如果分配失败，触发内核错误
ffffffffc020492a:	00002617          	auipc	a2,0x2
ffffffffc020492e:	3be60613          	addi	a2,a2,958 # ffffffffc0206ce8 <default_pmm_manager+0x680>
ffffffffc0204932:	14900593          	li	a1,329
ffffffffc0204936:	00002517          	auipc	a0,0x2
ffffffffc020493a:	38250513          	addi	a0,a0,898 # ffffffffc0206cb8 <default_pmm_manager+0x650>
ffffffffc020493e:	88bfb0ef          	jal	ra,ffffffffc02001c8 <__panic>
        panic("create init_main failed.\n");
ffffffffc0204942:	00002617          	auipc	a2,0x2
ffffffffc0204946:	3ee60613          	addi	a2,a2,1006 # ffffffffc0206d30 <default_pmm_manager+0x6c8>
ffffffffc020494a:	16a00593          	li	a1,362
ffffffffc020494e:	00002517          	auipc	a0,0x2
ffffffffc0204952:	36a50513          	addi	a0,a0,874 # ffffffffc0206cb8 <default_pmm_manager+0x650>
ffffffffc0204956:	873fb0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc020495a:	00002697          	auipc	a3,0x2
ffffffffc020495e:	42668693          	addi	a3,a3,1062 # ffffffffc0206d80 <default_pmm_manager+0x718>
ffffffffc0204962:	00001617          	auipc	a2,0x1
ffffffffc0204966:	f9e60613          	addi	a2,a2,-98 # ffffffffc0205900 <commands+0x728>
ffffffffc020496a:	17100593          	li	a1,369
ffffffffc020496e:	00002517          	auipc	a0,0x2
ffffffffc0204972:	34a50513          	addi	a0,a0,842 # ffffffffc0206cb8 <default_pmm_manager+0x650>
ffffffffc0204976:	853fb0ef          	jal	ra,ffffffffc02001c8 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020497a:	00002697          	auipc	a3,0x2
ffffffffc020497e:	3de68693          	addi	a3,a3,990 # ffffffffc0206d58 <default_pmm_manager+0x6f0>
ffffffffc0204982:	00001617          	auipc	a2,0x1
ffffffffc0204986:	f7e60613          	addi	a2,a2,-130 # ffffffffc0205900 <commands+0x728>
ffffffffc020498a:	17000593          	li	a1,368
ffffffffc020498e:	00002517          	auipc	a0,0x2
ffffffffc0204992:	32a50513          	addi	a0,a0,810 # ffffffffc0206cb8 <default_pmm_manager+0x650>
ffffffffc0204996:	833fb0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc020499a <cpu_idle>:

// cpu_idle - 在 kern_init 的最后，idleproc 执行该函数
void
cpu_idle(void) {
ffffffffc020499a:	1141                	addi	sp,sp,-16
ffffffffc020499c:	e022                	sd	s0,0(sp)
ffffffffc020499e:	e406                	sd	ra,8(sp)
ffffffffc02049a0:	00012417          	auipc	s0,0x12
ffffffffc02049a4:	c1040413          	addi	s0,s0,-1008 # ffffffffc02165b0 <current>
    while (1) { // 进入无限循环，确保 CPU 不空转
        if (current->need_resched) { // 如果需要重新调度
ffffffffc02049a8:	6018                	ld	a4,0(s0)
ffffffffc02049aa:	4f1c                	lw	a5,24(a4)
ffffffffc02049ac:	2781                	sext.w	a5,a5
ffffffffc02049ae:	dff5                	beqz	a5,ffffffffc02049aa <cpu_idle+0x10>
            schedule(); // 调用调度器进行任务切换
ffffffffc02049b0:	038000ef          	jal	ra,ffffffffc02049e8 <schedule>
ffffffffc02049b4:	bfd5                	j	ffffffffc02049a8 <cpu_idle+0xe>

ffffffffc02049b6 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02049b6:	411c                	lw	a5,0(a0)
ffffffffc02049b8:	4705                	li	a4,1
ffffffffc02049ba:	37f9                	addiw	a5,a5,-2
ffffffffc02049bc:	00f77563          	bgeu	a4,a5,ffffffffc02049c6 <wakeup_proc+0x10>
    proc->state = PROC_RUNNABLE;
ffffffffc02049c0:	4789                	li	a5,2
ffffffffc02049c2:	c11c                	sw	a5,0(a0)
ffffffffc02049c4:	8082                	ret
wakeup_proc(struct proc_struct *proc) {
ffffffffc02049c6:	1141                	addi	sp,sp,-16
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02049c8:	00002697          	auipc	a3,0x2
ffffffffc02049cc:	3e068693          	addi	a3,a3,992 # ffffffffc0206da8 <default_pmm_manager+0x740>
ffffffffc02049d0:	00001617          	auipc	a2,0x1
ffffffffc02049d4:	f3060613          	addi	a2,a2,-208 # ffffffffc0205900 <commands+0x728>
ffffffffc02049d8:	45a5                	li	a1,9
ffffffffc02049da:	00002517          	auipc	a0,0x2
ffffffffc02049de:	40e50513          	addi	a0,a0,1038 # ffffffffc0206de8 <default_pmm_manager+0x780>
wakeup_proc(struct proc_struct *proc) {
ffffffffc02049e2:	e406                	sd	ra,8(sp)
    assert(proc->state != PROC_ZOMBIE && proc->state != PROC_RUNNABLE);
ffffffffc02049e4:	fe4fb0ef          	jal	ra,ffffffffc02001c8 <__panic>

ffffffffc02049e8 <schedule>:
}

void
schedule(void) {
ffffffffc02049e8:	1141                	addi	sp,sp,-16
ffffffffc02049ea:	e406                	sd	ra,8(sp)
ffffffffc02049ec:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02049ee:	100027f3          	csrr	a5,sstatus
ffffffffc02049f2:	8b89                	andi	a5,a5,2
ffffffffc02049f4:	4401                	li	s0,0
ffffffffc02049f6:	efbd                	bnez	a5,ffffffffc0204a74 <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;//设置当前进程为不需要调度
ffffffffc02049f8:	00012897          	auipc	a7,0x12
ffffffffc02049fc:	bb88b883          	ld	a7,-1096(a7) # ffffffffc02165b0 <current>
ffffffffc0204a00:	0008ac23          	sw	zero,24(a7)
        //判断last是否为idle进程，是则从头开始搜索链表，否则获取下一链表
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0204a04:	00012517          	auipc	a0,0x12
ffffffffc0204a08:	bb453503          	ld	a0,-1100(a0) # ffffffffc02165b8 <idleproc>
ffffffffc0204a0c:	04a88e63          	beq	a7,a0,ffffffffc0204a68 <schedule+0x80>
ffffffffc0204a10:	0c888693          	addi	a3,a7,200
ffffffffc0204a14:	00012617          	auipc	a2,0x12
ffffffffc0204a18:	b1460613          	addi	a2,a2,-1260 # ffffffffc0216528 <proc_list>
        le = last;
ffffffffc0204a1c:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0204a1e:	4581                	li	a1,0
        do {//循环找到可调度的进程
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc0204a20:	4809                	li	a6,2
ffffffffc0204a22:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0204a24:	00c78863          	beq	a5,a2,ffffffffc0204a34 <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0204a28:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0204a2c:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc0204a30:	03070163          	beq	a4,a6,ffffffffc0204a52 <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc0204a34:	fef697e3          	bne	a3,a5,ffffffffc0204a22 <schedule+0x3a>
        //未找到则继续idle进程
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0204a38:	ed89                	bnez	a1,ffffffffc0204a52 <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;//运行次数++
ffffffffc0204a3a:	451c                	lw	a5,8(a0)
ffffffffc0204a3c:	2785                	addiw	a5,a5,1
ffffffffc0204a3e:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc0204a40:	00a88463          	beq	a7,a0,ffffffffc0204a48 <schedule+0x60>
            //新进程，则运行
            proc_run(next);
ffffffffc0204a44:	945ff0ef          	jal	ra,ffffffffc0204388 <proc_run>
    if (flag) {
ffffffffc0204a48:	e819                	bnez	s0,ffffffffc0204a5e <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
ffffffffc0204a4a:	60a2                	ld	ra,8(sp)
ffffffffc0204a4c:	6402                	ld	s0,0(sp)
ffffffffc0204a4e:	0141                	addi	sp,sp,16
ffffffffc0204a50:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0204a52:	4198                	lw	a4,0(a1)
ffffffffc0204a54:	4789                	li	a5,2
ffffffffc0204a56:	fef712e3          	bne	a4,a5,ffffffffc0204a3a <schedule+0x52>
ffffffffc0204a5a:	852e                	mv	a0,a1
ffffffffc0204a5c:	bff9                	j	ffffffffc0204a3a <schedule+0x52>
ffffffffc0204a5e:	6402                	ld	s0,0(sp)
ffffffffc0204a60:	60a2                	ld	ra,8(sp)
ffffffffc0204a62:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0204a64:	b5bfb06f          	j	ffffffffc02005be <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0204a68:	00012617          	auipc	a2,0x12
ffffffffc0204a6c:	ac060613          	addi	a2,a2,-1344 # ffffffffc0216528 <proc_list>
ffffffffc0204a70:	86b2                	mv	a3,a2
ffffffffc0204a72:	b76d                	j	ffffffffc0204a1c <schedule+0x34>
        intr_disable();
ffffffffc0204a74:	b51fb0ef          	jal	ra,ffffffffc02005c4 <intr_disable>
        return 1;
ffffffffc0204a78:	4405                	li	s0,1
ffffffffc0204a7a:	bfbd                	j	ffffffffc02049f8 <schedule+0x10>

ffffffffc0204a7c <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0204a7c:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0204a80:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0204a82:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0204a84:	cb81                	beqz	a5,ffffffffc0204a94 <strlen+0x18>
        cnt ++;
ffffffffc0204a86:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0204a88:	00a707b3          	add	a5,a4,a0
ffffffffc0204a8c:	0007c783          	lbu	a5,0(a5)
ffffffffc0204a90:	fbfd                	bnez	a5,ffffffffc0204a86 <strlen+0xa>
ffffffffc0204a92:	8082                	ret
    }
    return cnt;
}
ffffffffc0204a94:	8082                	ret

ffffffffc0204a96 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0204a96:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0204a98:	e589                	bnez	a1,ffffffffc0204aa2 <strnlen+0xc>
ffffffffc0204a9a:	a811                	j	ffffffffc0204aae <strnlen+0x18>
        cnt ++;
ffffffffc0204a9c:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0204a9e:	00f58863          	beq	a1,a5,ffffffffc0204aae <strnlen+0x18>
ffffffffc0204aa2:	00f50733          	add	a4,a0,a5
ffffffffc0204aa6:	00074703          	lbu	a4,0(a4)
ffffffffc0204aaa:	fb6d                	bnez	a4,ffffffffc0204a9c <strnlen+0x6>
ffffffffc0204aac:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0204aae:	852e                	mv	a0,a1
ffffffffc0204ab0:	8082                	ret

ffffffffc0204ab2 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0204ab2:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0204ab4:	0005c703          	lbu	a4,0(a1)
ffffffffc0204ab8:	0785                	addi	a5,a5,1
ffffffffc0204aba:	0585                	addi	a1,a1,1
ffffffffc0204abc:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0204ac0:	fb75                	bnez	a4,ffffffffc0204ab4 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0204ac2:	8082                	ret

ffffffffc0204ac4 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204ac4:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204ac8:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204acc:	cb89                	beqz	a5,ffffffffc0204ade <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0204ace:	0505                	addi	a0,a0,1
ffffffffc0204ad0:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0204ad2:	fee789e3          	beq	a5,a4,ffffffffc0204ac4 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204ad6:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0204ada:	9d19                	subw	a0,a0,a4
ffffffffc0204adc:	8082                	ret
ffffffffc0204ade:	4501                	li	a0,0
ffffffffc0204ae0:	bfed                	j	ffffffffc0204ada <strcmp+0x16>

ffffffffc0204ae2 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0204ae2:	00054783          	lbu	a5,0(a0)
ffffffffc0204ae6:	c799                	beqz	a5,ffffffffc0204af4 <strchr+0x12>
        if (*s == c) {
ffffffffc0204ae8:	00f58763          	beq	a1,a5,ffffffffc0204af6 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0204aec:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0204af0:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0204af2:	fbfd                	bnez	a5,ffffffffc0204ae8 <strchr+0x6>
    }
    return NULL;
ffffffffc0204af4:	4501                	li	a0,0
}
ffffffffc0204af6:	8082                	ret

ffffffffc0204af8 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0204af8:	ca01                	beqz	a2,ffffffffc0204b08 <memset+0x10>
ffffffffc0204afa:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0204afc:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0204afe:	0785                	addi	a5,a5,1
ffffffffc0204b00:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0204b04:	fec79de3          	bne	a5,a2,ffffffffc0204afe <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0204b08:	8082                	ret

ffffffffc0204b0a <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0204b0a:	ca19                	beqz	a2,ffffffffc0204b20 <memcpy+0x16>
ffffffffc0204b0c:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0204b0e:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0204b10:	0005c703          	lbu	a4,0(a1)
ffffffffc0204b14:	0585                	addi	a1,a1,1
ffffffffc0204b16:	0785                	addi	a5,a5,1
ffffffffc0204b18:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0204b1c:	fec59ae3          	bne	a1,a2,ffffffffc0204b10 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0204b20:	8082                	ret

ffffffffc0204b22 <memcmp>:
 * */
int
memcmp(const void *v1, const void *v2, size_t n) {
    const char *s1 = (const char *)v1;
    const char *s2 = (const char *)v2;
    while (n -- > 0) {
ffffffffc0204b22:	c205                	beqz	a2,ffffffffc0204b42 <memcmp+0x20>
ffffffffc0204b24:	962e                	add	a2,a2,a1
ffffffffc0204b26:	a019                	j	ffffffffc0204b2c <memcmp+0xa>
ffffffffc0204b28:	00c58d63          	beq	a1,a2,ffffffffc0204b42 <memcmp+0x20>
        if (*s1 != *s2) {
ffffffffc0204b2c:	00054783          	lbu	a5,0(a0)
ffffffffc0204b30:	0005c703          	lbu	a4,0(a1)
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
        }
        s1 ++, s2 ++;
ffffffffc0204b34:	0505                	addi	a0,a0,1
ffffffffc0204b36:	0585                	addi	a1,a1,1
        if (*s1 != *s2) {
ffffffffc0204b38:	fee788e3          	beq	a5,a4,ffffffffc0204b28 <memcmp+0x6>
            return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0204b3c:	40e7853b          	subw	a0,a5,a4
ffffffffc0204b40:	8082                	ret
    }
    return 0;
ffffffffc0204b42:	4501                	li	a0,0
}
ffffffffc0204b44:	8082                	ret

ffffffffc0204b46 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0204b46:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204b4a:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0204b4c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204b50:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0204b52:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0204b56:	f022                	sd	s0,32(sp)
ffffffffc0204b58:	ec26                	sd	s1,24(sp)
ffffffffc0204b5a:	e84a                	sd	s2,16(sp)
ffffffffc0204b5c:	f406                	sd	ra,40(sp)
ffffffffc0204b5e:	e44e                	sd	s3,8(sp)
ffffffffc0204b60:	84aa                	mv	s1,a0
ffffffffc0204b62:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0204b64:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0204b68:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0204b6a:	03067e63          	bgeu	a2,a6,ffffffffc0204ba6 <printnum+0x60>
ffffffffc0204b6e:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0204b70:	00805763          	blez	s0,ffffffffc0204b7e <printnum+0x38>
ffffffffc0204b74:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0204b76:	85ca                	mv	a1,s2
ffffffffc0204b78:	854e                	mv	a0,s3
ffffffffc0204b7a:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0204b7c:	fc65                	bnez	s0,ffffffffc0204b74 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204b7e:	1a02                	slli	s4,s4,0x20
ffffffffc0204b80:	00002797          	auipc	a5,0x2
ffffffffc0204b84:	28078793          	addi	a5,a5,640 # ffffffffc0206e00 <default_pmm_manager+0x798>
ffffffffc0204b88:	020a5a13          	srli	s4,s4,0x20
ffffffffc0204b8c:	9a3e                	add	s4,s4,a5
}
ffffffffc0204b8e:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204b90:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0204b94:	70a2                	ld	ra,40(sp)
ffffffffc0204b96:	69a2                	ld	s3,8(sp)
ffffffffc0204b98:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204b9a:	85ca                	mv	a1,s2
ffffffffc0204b9c:	87a6                	mv	a5,s1
}
ffffffffc0204b9e:	6942                	ld	s2,16(sp)
ffffffffc0204ba0:	64e2                	ld	s1,24(sp)
ffffffffc0204ba2:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0204ba4:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0204ba6:	03065633          	divu	a2,a2,a6
ffffffffc0204baa:	8722                	mv	a4,s0
ffffffffc0204bac:	f9bff0ef          	jal	ra,ffffffffc0204b46 <printnum>
ffffffffc0204bb0:	b7f9                	j	ffffffffc0204b7e <printnum+0x38>

ffffffffc0204bb2 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0204bb2:	7119                	addi	sp,sp,-128
ffffffffc0204bb4:	f4a6                	sd	s1,104(sp)
ffffffffc0204bb6:	f0ca                	sd	s2,96(sp)
ffffffffc0204bb8:	ecce                	sd	s3,88(sp)
ffffffffc0204bba:	e8d2                	sd	s4,80(sp)
ffffffffc0204bbc:	e4d6                	sd	s5,72(sp)
ffffffffc0204bbe:	e0da                	sd	s6,64(sp)
ffffffffc0204bc0:	fc5e                	sd	s7,56(sp)
ffffffffc0204bc2:	f06a                	sd	s10,32(sp)
ffffffffc0204bc4:	fc86                	sd	ra,120(sp)
ffffffffc0204bc6:	f8a2                	sd	s0,112(sp)
ffffffffc0204bc8:	f862                	sd	s8,48(sp)
ffffffffc0204bca:	f466                	sd	s9,40(sp)
ffffffffc0204bcc:	ec6e                	sd	s11,24(sp)
ffffffffc0204bce:	892a                	mv	s2,a0
ffffffffc0204bd0:	84ae                	mv	s1,a1
ffffffffc0204bd2:	8d32                	mv	s10,a2
ffffffffc0204bd4:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204bd6:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0204bda:	5b7d                	li	s6,-1
ffffffffc0204bdc:	00002a97          	auipc	s5,0x2
ffffffffc0204be0:	250a8a93          	addi	s5,s5,592 # ffffffffc0206e2c <default_pmm_manager+0x7c4>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204be4:	00002b97          	auipc	s7,0x2
ffffffffc0204be8:	424b8b93          	addi	s7,s7,1060 # ffffffffc0207008 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204bec:	000d4503          	lbu	a0,0(s10)
ffffffffc0204bf0:	001d0413          	addi	s0,s10,1
ffffffffc0204bf4:	01350a63          	beq	a0,s3,ffffffffc0204c08 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0204bf8:	c121                	beqz	a0,ffffffffc0204c38 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0204bfa:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204bfc:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0204bfe:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0204c00:	fff44503          	lbu	a0,-1(s0)
ffffffffc0204c04:	ff351ae3          	bne	a0,s3,ffffffffc0204bf8 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204c08:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0204c0c:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0204c10:	4c81                	li	s9,0
ffffffffc0204c12:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0204c14:	5c7d                	li	s8,-1
ffffffffc0204c16:	5dfd                	li	s11,-1
ffffffffc0204c18:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0204c1c:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204c1e:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0204c22:	0ff5f593          	zext.b	a1,a1
ffffffffc0204c26:	00140d13          	addi	s10,s0,1
ffffffffc0204c2a:	04b56263          	bltu	a0,a1,ffffffffc0204c6e <vprintfmt+0xbc>
ffffffffc0204c2e:	058a                	slli	a1,a1,0x2
ffffffffc0204c30:	95d6                	add	a1,a1,s5
ffffffffc0204c32:	4194                	lw	a3,0(a1)
ffffffffc0204c34:	96d6                	add	a3,a3,s5
ffffffffc0204c36:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0204c38:	70e6                	ld	ra,120(sp)
ffffffffc0204c3a:	7446                	ld	s0,112(sp)
ffffffffc0204c3c:	74a6                	ld	s1,104(sp)
ffffffffc0204c3e:	7906                	ld	s2,96(sp)
ffffffffc0204c40:	69e6                	ld	s3,88(sp)
ffffffffc0204c42:	6a46                	ld	s4,80(sp)
ffffffffc0204c44:	6aa6                	ld	s5,72(sp)
ffffffffc0204c46:	6b06                	ld	s6,64(sp)
ffffffffc0204c48:	7be2                	ld	s7,56(sp)
ffffffffc0204c4a:	7c42                	ld	s8,48(sp)
ffffffffc0204c4c:	7ca2                	ld	s9,40(sp)
ffffffffc0204c4e:	7d02                	ld	s10,32(sp)
ffffffffc0204c50:	6de2                	ld	s11,24(sp)
ffffffffc0204c52:	6109                	addi	sp,sp,128
ffffffffc0204c54:	8082                	ret
            padc = '0';
ffffffffc0204c56:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0204c58:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204c5c:	846a                	mv	s0,s10
ffffffffc0204c5e:	00140d13          	addi	s10,s0,1
ffffffffc0204c62:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0204c66:	0ff5f593          	zext.b	a1,a1
ffffffffc0204c6a:	fcb572e3          	bgeu	a0,a1,ffffffffc0204c2e <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0204c6e:	85a6                	mv	a1,s1
ffffffffc0204c70:	02500513          	li	a0,37
ffffffffc0204c74:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0204c76:	fff44783          	lbu	a5,-1(s0)
ffffffffc0204c7a:	8d22                	mv	s10,s0
ffffffffc0204c7c:	f73788e3          	beq	a5,s3,ffffffffc0204bec <vprintfmt+0x3a>
ffffffffc0204c80:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0204c84:	1d7d                	addi	s10,s10,-1
ffffffffc0204c86:	ff379de3          	bne	a5,s3,ffffffffc0204c80 <vprintfmt+0xce>
ffffffffc0204c8a:	b78d                	j	ffffffffc0204bec <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0204c8c:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0204c90:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204c94:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0204c96:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0204c9a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0204c9e:	02d86463          	bltu	a6,a3,ffffffffc0204cc6 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0204ca2:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0204ca6:	002c169b          	slliw	a3,s8,0x2
ffffffffc0204caa:	0186873b          	addw	a4,a3,s8
ffffffffc0204cae:	0017171b          	slliw	a4,a4,0x1
ffffffffc0204cb2:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0204cb4:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0204cb8:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0204cba:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0204cbe:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0204cc2:	fed870e3          	bgeu	a6,a3,ffffffffc0204ca2 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0204cc6:	f40ddce3          	bgez	s11,ffffffffc0204c1e <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0204cca:	8de2                	mv	s11,s8
ffffffffc0204ccc:	5c7d                	li	s8,-1
ffffffffc0204cce:	bf81                	j	ffffffffc0204c1e <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0204cd0:	fffdc693          	not	a3,s11
ffffffffc0204cd4:	96fd                	srai	a3,a3,0x3f
ffffffffc0204cd6:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204cda:	00144603          	lbu	a2,1(s0)
ffffffffc0204cde:	2d81                	sext.w	s11,s11
ffffffffc0204ce0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204ce2:	bf35                	j	ffffffffc0204c1e <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0204ce4:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204ce8:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0204cec:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204cee:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0204cf0:	bfd9                	j	ffffffffc0204cc6 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0204cf2:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204cf4:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0204cf8:	01174463          	blt	a4,a7,ffffffffc0204d00 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0204cfc:	1a088e63          	beqz	a7,ffffffffc0204eb8 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0204d00:	000a3603          	ld	a2,0(s4)
ffffffffc0204d04:	46c1                	li	a3,16
ffffffffc0204d06:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0204d08:	2781                	sext.w	a5,a5
ffffffffc0204d0a:	876e                	mv	a4,s11
ffffffffc0204d0c:	85a6                	mv	a1,s1
ffffffffc0204d0e:	854a                	mv	a0,s2
ffffffffc0204d10:	e37ff0ef          	jal	ra,ffffffffc0204b46 <printnum>
            break;
ffffffffc0204d14:	bde1                	j	ffffffffc0204bec <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0204d16:	000a2503          	lw	a0,0(s4)
ffffffffc0204d1a:	85a6                	mv	a1,s1
ffffffffc0204d1c:	0a21                	addi	s4,s4,8
ffffffffc0204d1e:	9902                	jalr	s2
            break;
ffffffffc0204d20:	b5f1                	j	ffffffffc0204bec <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204d22:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204d24:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0204d28:	01174463          	blt	a4,a7,ffffffffc0204d30 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0204d2c:	18088163          	beqz	a7,ffffffffc0204eae <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0204d30:	000a3603          	ld	a2,0(s4)
ffffffffc0204d34:	46a9                	li	a3,10
ffffffffc0204d36:	8a2e                	mv	s4,a1
ffffffffc0204d38:	bfc1                	j	ffffffffc0204d08 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204d3a:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0204d3e:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204d40:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204d42:	bdf1                	j	ffffffffc0204c1e <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0204d44:	85a6                	mv	a1,s1
ffffffffc0204d46:	02500513          	li	a0,37
ffffffffc0204d4a:	9902                	jalr	s2
            break;
ffffffffc0204d4c:	b545                	j	ffffffffc0204bec <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204d4e:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0204d52:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0204d54:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0204d56:	b5e1                	j	ffffffffc0204c1e <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0204d58:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204d5a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0204d5e:	01174463          	blt	a4,a7,ffffffffc0204d66 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0204d62:	14088163          	beqz	a7,ffffffffc0204ea4 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0204d66:	000a3603          	ld	a2,0(s4)
ffffffffc0204d6a:	46a1                	li	a3,8
ffffffffc0204d6c:	8a2e                	mv	s4,a1
ffffffffc0204d6e:	bf69                	j	ffffffffc0204d08 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0204d70:	03000513          	li	a0,48
ffffffffc0204d74:	85a6                	mv	a1,s1
ffffffffc0204d76:	e03e                	sd	a5,0(sp)
ffffffffc0204d78:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0204d7a:	85a6                	mv	a1,s1
ffffffffc0204d7c:	07800513          	li	a0,120
ffffffffc0204d80:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204d82:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0204d84:	6782                	ld	a5,0(sp)
ffffffffc0204d86:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0204d88:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0204d8c:	bfb5                	j	ffffffffc0204d08 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204d8e:	000a3403          	ld	s0,0(s4)
ffffffffc0204d92:	008a0713          	addi	a4,s4,8
ffffffffc0204d96:	e03a                	sd	a4,0(sp)
ffffffffc0204d98:	14040263          	beqz	s0,ffffffffc0204edc <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0204d9c:	0fb05763          	blez	s11,ffffffffc0204e8a <vprintfmt+0x2d8>
ffffffffc0204da0:	02d00693          	li	a3,45
ffffffffc0204da4:	0cd79163          	bne	a5,a3,ffffffffc0204e66 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204da8:	00044783          	lbu	a5,0(s0)
ffffffffc0204dac:	0007851b          	sext.w	a0,a5
ffffffffc0204db0:	cf85                	beqz	a5,ffffffffc0204de8 <vprintfmt+0x236>
ffffffffc0204db2:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204db6:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204dba:	000c4563          	bltz	s8,ffffffffc0204dc4 <vprintfmt+0x212>
ffffffffc0204dbe:	3c7d                	addiw	s8,s8,-1
ffffffffc0204dc0:	036c0263          	beq	s8,s6,ffffffffc0204de4 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0204dc4:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204dc6:	0e0c8e63          	beqz	s9,ffffffffc0204ec2 <vprintfmt+0x310>
ffffffffc0204dca:	3781                	addiw	a5,a5,-32
ffffffffc0204dcc:	0ef47b63          	bgeu	s0,a5,ffffffffc0204ec2 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0204dd0:	03f00513          	li	a0,63
ffffffffc0204dd4:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204dd6:	000a4783          	lbu	a5,0(s4)
ffffffffc0204dda:	3dfd                	addiw	s11,s11,-1
ffffffffc0204ddc:	0a05                	addi	s4,s4,1
ffffffffc0204dde:	0007851b          	sext.w	a0,a5
ffffffffc0204de2:	ffe1                	bnez	a5,ffffffffc0204dba <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0204de4:	01b05963          	blez	s11,ffffffffc0204df6 <vprintfmt+0x244>
ffffffffc0204de8:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0204dea:	85a6                	mv	a1,s1
ffffffffc0204dec:	02000513          	li	a0,32
ffffffffc0204df0:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0204df2:	fe0d9be3          	bnez	s11,ffffffffc0204de8 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0204df6:	6a02                	ld	s4,0(sp)
ffffffffc0204df8:	bbd5                	j	ffffffffc0204bec <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0204dfa:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0204dfc:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0204e00:	01174463          	blt	a4,a7,ffffffffc0204e08 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0204e04:	08088d63          	beqz	a7,ffffffffc0204e9e <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0204e08:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0204e0c:	0a044d63          	bltz	s0,ffffffffc0204ec6 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0204e10:	8622                	mv	a2,s0
ffffffffc0204e12:	8a66                	mv	s4,s9
ffffffffc0204e14:	46a9                	li	a3,10
ffffffffc0204e16:	bdcd                	j	ffffffffc0204d08 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0204e18:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204e1c:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0204e1e:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0204e20:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0204e24:	8fb5                	xor	a5,a5,a3
ffffffffc0204e26:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0204e2a:	02d74163          	blt	a4,a3,ffffffffc0204e4c <vprintfmt+0x29a>
ffffffffc0204e2e:	00369793          	slli	a5,a3,0x3
ffffffffc0204e32:	97de                	add	a5,a5,s7
ffffffffc0204e34:	639c                	ld	a5,0(a5)
ffffffffc0204e36:	cb99                	beqz	a5,ffffffffc0204e4c <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0204e38:	86be                	mv	a3,a5
ffffffffc0204e3a:	00000617          	auipc	a2,0x0
ffffffffc0204e3e:	13e60613          	addi	a2,a2,318 # ffffffffc0204f78 <etext+0x2e>
ffffffffc0204e42:	85a6                	mv	a1,s1
ffffffffc0204e44:	854a                	mv	a0,s2
ffffffffc0204e46:	0ce000ef          	jal	ra,ffffffffc0204f14 <printfmt>
ffffffffc0204e4a:	b34d                	j	ffffffffc0204bec <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0204e4c:	00002617          	auipc	a2,0x2
ffffffffc0204e50:	fd460613          	addi	a2,a2,-44 # ffffffffc0206e20 <default_pmm_manager+0x7b8>
ffffffffc0204e54:	85a6                	mv	a1,s1
ffffffffc0204e56:	854a                	mv	a0,s2
ffffffffc0204e58:	0bc000ef          	jal	ra,ffffffffc0204f14 <printfmt>
ffffffffc0204e5c:	bb41                	j	ffffffffc0204bec <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0204e5e:	00002417          	auipc	s0,0x2
ffffffffc0204e62:	fba40413          	addi	s0,s0,-70 # ffffffffc0206e18 <default_pmm_manager+0x7b0>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204e66:	85e2                	mv	a1,s8
ffffffffc0204e68:	8522                	mv	a0,s0
ffffffffc0204e6a:	e43e                	sd	a5,8(sp)
ffffffffc0204e6c:	c2bff0ef          	jal	ra,ffffffffc0204a96 <strnlen>
ffffffffc0204e70:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0204e74:	01b05b63          	blez	s11,ffffffffc0204e8a <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0204e78:	67a2                	ld	a5,8(sp)
ffffffffc0204e7a:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204e7e:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0204e80:	85a6                	mv	a1,s1
ffffffffc0204e82:	8552                	mv	a0,s4
ffffffffc0204e84:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0204e86:	fe0d9ce3          	bnez	s11,ffffffffc0204e7e <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204e8a:	00044783          	lbu	a5,0(s0)
ffffffffc0204e8e:	00140a13          	addi	s4,s0,1
ffffffffc0204e92:	0007851b          	sext.w	a0,a5
ffffffffc0204e96:	d3a5                	beqz	a5,ffffffffc0204df6 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204e98:	05e00413          	li	s0,94
ffffffffc0204e9c:	bf39                	j	ffffffffc0204dba <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0204e9e:	000a2403          	lw	s0,0(s4)
ffffffffc0204ea2:	b7ad                	j	ffffffffc0204e0c <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0204ea4:	000a6603          	lwu	a2,0(s4)
ffffffffc0204ea8:	46a1                	li	a3,8
ffffffffc0204eaa:	8a2e                	mv	s4,a1
ffffffffc0204eac:	bdb1                	j	ffffffffc0204d08 <vprintfmt+0x156>
ffffffffc0204eae:	000a6603          	lwu	a2,0(s4)
ffffffffc0204eb2:	46a9                	li	a3,10
ffffffffc0204eb4:	8a2e                	mv	s4,a1
ffffffffc0204eb6:	bd89                	j	ffffffffc0204d08 <vprintfmt+0x156>
ffffffffc0204eb8:	000a6603          	lwu	a2,0(s4)
ffffffffc0204ebc:	46c1                	li	a3,16
ffffffffc0204ebe:	8a2e                	mv	s4,a1
ffffffffc0204ec0:	b5a1                	j	ffffffffc0204d08 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0204ec2:	9902                	jalr	s2
ffffffffc0204ec4:	bf09                	j	ffffffffc0204dd6 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0204ec6:	85a6                	mv	a1,s1
ffffffffc0204ec8:	02d00513          	li	a0,45
ffffffffc0204ecc:	e03e                	sd	a5,0(sp)
ffffffffc0204ece:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0204ed0:	6782                	ld	a5,0(sp)
ffffffffc0204ed2:	8a66                	mv	s4,s9
ffffffffc0204ed4:	40800633          	neg	a2,s0
ffffffffc0204ed8:	46a9                	li	a3,10
ffffffffc0204eda:	b53d                	j	ffffffffc0204d08 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0204edc:	03b05163          	blez	s11,ffffffffc0204efe <vprintfmt+0x34c>
ffffffffc0204ee0:	02d00693          	li	a3,45
ffffffffc0204ee4:	f6d79de3          	bne	a5,a3,ffffffffc0204e5e <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0204ee8:	00002417          	auipc	s0,0x2
ffffffffc0204eec:	f3040413          	addi	s0,s0,-208 # ffffffffc0206e18 <default_pmm_manager+0x7b0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0204ef0:	02800793          	li	a5,40
ffffffffc0204ef4:	02800513          	li	a0,40
ffffffffc0204ef8:	00140a13          	addi	s4,s0,1
ffffffffc0204efc:	bd6d                	j	ffffffffc0204db6 <vprintfmt+0x204>
ffffffffc0204efe:	00002a17          	auipc	s4,0x2
ffffffffc0204f02:	f1ba0a13          	addi	s4,s4,-229 # ffffffffc0206e19 <default_pmm_manager+0x7b1>
ffffffffc0204f06:	02800513          	li	a0,40
ffffffffc0204f0a:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0204f0e:	05e00413          	li	s0,94
ffffffffc0204f12:	b565                	j	ffffffffc0204dba <vprintfmt+0x208>

ffffffffc0204f14 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204f14:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0204f16:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204f1a:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204f1c:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0204f1e:	ec06                	sd	ra,24(sp)
ffffffffc0204f20:	f83a                	sd	a4,48(sp)
ffffffffc0204f22:	fc3e                	sd	a5,56(sp)
ffffffffc0204f24:	e0c2                	sd	a6,64(sp)
ffffffffc0204f26:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0204f28:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0204f2a:	c89ff0ef          	jal	ra,ffffffffc0204bb2 <vprintfmt>
}
ffffffffc0204f2e:	60e2                	ld	ra,24(sp)
ffffffffc0204f30:	6161                	addi	sp,sp,80
ffffffffc0204f32:	8082                	ret

ffffffffc0204f34 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0204f34:	9e3707b7          	lui	a5,0x9e370
ffffffffc0204f38:	2785                	addiw	a5,a5,1
ffffffffc0204f3a:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc0204f3e:	02000793          	li	a5,32
ffffffffc0204f42:	9f8d                	subw	a5,a5,a1
}
ffffffffc0204f44:	00f5553b          	srlw	a0,a0,a5
ffffffffc0204f48:	8082                	ret

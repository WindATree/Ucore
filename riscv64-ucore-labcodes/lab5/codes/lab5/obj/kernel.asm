
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c020b2b7          	lui	t0,0xc020b
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
ffffffffc0200024:	c020b137          	lui	sp,0xc020b

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
ffffffffc0200032:	000a7517          	auipc	a0,0xa7
ffffffffc0200036:	4ae50513          	addi	a0,a0,1198 # ffffffffc02a74e0 <buf>
ffffffffc020003a:	000b3617          	auipc	a2,0xb3
ffffffffc020003e:	a0260613          	addi	a2,a2,-1534 # ffffffffc02b2a3c <end>
kern_init(void) {
ffffffffc0200042:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200044:	8e09                	sub	a2,a2,a0
ffffffffc0200046:	4581                	li	a1,0
kern_init(void) {
ffffffffc0200048:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004a:	170060ef          	jal	ra,ffffffffc02061ba <memset>
    cons_init();                // init the console
ffffffffc020004e:	580000ef          	jal	ra,ffffffffc02005ce <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200052:	00006597          	auipc	a1,0x6
ffffffffc0200056:	59658593          	addi	a1,a1,1430 # ffffffffc02065e8 <etext>
ffffffffc020005a:	00006517          	auipc	a0,0x6
ffffffffc020005e:	5ae50513          	addi	a0,a0,1454 # ffffffffc0206608 <etext+0x20>
ffffffffc0200062:	06a000ef          	jal	ra,ffffffffc02000cc <cprintf>

    print_kerninfo();
ffffffffc0200066:	24e000ef          	jal	ra,ffffffffc02002b4 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006a:	48f030ef          	jal	ra,ffffffffc0203cf8 <pmm_init>

    pic_init();                 // init interrupt controller
ffffffffc020006e:	5d2000ef          	jal	ra,ffffffffc0200640 <pic_init>
    idt_init();                 // init interrupt descriptor table
ffffffffc0200072:	5dc000ef          	jal	ra,ffffffffc020064e <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc0200076:	556010ef          	jal	ra,ffffffffc02015cc <vmm_init>
    proc_init();                // init process table
ffffffffc020007a:	527050ef          	jal	ra,ffffffffc0205da0 <proc_init>
    
    ide_init();                 // init ide devices
ffffffffc020007e:	4a8000ef          	jal	ra,ffffffffc0200526 <ide_init>
    swap_init();                // init swap
ffffffffc0200082:	008020ef          	jal	ra,ffffffffc020208a <swap_init>

    clock_init();               // init clock interrupt
ffffffffc0200086:	4f6000ef          	jal	ra,ffffffffc020057c <clock_init>
    intr_enable();              // enable irq interrupt
ffffffffc020008a:	5b8000ef          	jal	ra,ffffffffc0200642 <intr_enable>
    
    cpu_idle();                 // run idle process
ffffffffc020008e:	6ab050ef          	jal	ra,ffffffffc0205f38 <cpu_idle>

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
ffffffffc020009a:	536000ef          	jal	ra,ffffffffc02005d0 <cons_putc>
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
ffffffffc02000c0:	190060ef          	jal	ra,ffffffffc0206250 <vprintfmt>
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
ffffffffc02000ce:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
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
ffffffffc02000f6:	15a060ef          	jal	ra,ffffffffc0206250 <vprintfmt>
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
ffffffffc0200102:	a1f9                	j	ffffffffc02005d0 <cons_putc>

ffffffffc0200104 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200104:	1101                	addi	sp,sp,-32
ffffffffc0200106:	e822                	sd	s0,16(sp)
ffffffffc0200108:	ec06                	sd	ra,24(sp)
ffffffffc020010a:	e426                	sd	s1,8(sp)
ffffffffc020010c:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020010e:	00054503          	lbu	a0,0(a0)
ffffffffc0200112:	c51d                	beqz	a0,ffffffffc0200140 <cputs+0x3c>
ffffffffc0200114:	0405                	addi	s0,s0,1
ffffffffc0200116:	4485                	li	s1,1
ffffffffc0200118:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc020011a:	4b6000ef          	jal	ra,ffffffffc02005d0 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020011e:	00044503          	lbu	a0,0(s0)
ffffffffc0200122:	008487bb          	addw	a5,s1,s0
ffffffffc0200126:	0405                	addi	s0,s0,1
ffffffffc0200128:	f96d                	bnez	a0,ffffffffc020011a <cputs+0x16>
    (*cnt) ++;
ffffffffc020012a:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020012e:	4529                	li	a0,10
ffffffffc0200130:	4a0000ef          	jal	ra,ffffffffc02005d0 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200134:	60e2                	ld	ra,24(sp)
ffffffffc0200136:	8522                	mv	a0,s0
ffffffffc0200138:	6442                	ld	s0,16(sp)
ffffffffc020013a:	64a2                	ld	s1,8(sp)
ffffffffc020013c:	6105                	addi	sp,sp,32
ffffffffc020013e:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200140:	4405                	li	s0,1
ffffffffc0200142:	b7f5                	j	ffffffffc020012e <cputs+0x2a>

ffffffffc0200144 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200144:	1141                	addi	sp,sp,-16
ffffffffc0200146:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200148:	4bc000ef          	jal	ra,ffffffffc0200604 <cons_getc>
ffffffffc020014c:	dd75                	beqz	a0,ffffffffc0200148 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020014e:	60a2                	ld	ra,8(sp)
ffffffffc0200150:	0141                	addi	sp,sp,16
ffffffffc0200152:	8082                	ret

ffffffffc0200154 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0200154:	715d                	addi	sp,sp,-80
ffffffffc0200156:	e486                	sd	ra,72(sp)
ffffffffc0200158:	e0a6                	sd	s1,64(sp)
ffffffffc020015a:	fc4a                	sd	s2,56(sp)
ffffffffc020015c:	f84e                	sd	s3,48(sp)
ffffffffc020015e:	f452                	sd	s4,40(sp)
ffffffffc0200160:	f056                	sd	s5,32(sp)
ffffffffc0200162:	ec5a                	sd	s6,24(sp)
ffffffffc0200164:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0200166:	c901                	beqz	a0,ffffffffc0200176 <readline+0x22>
ffffffffc0200168:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc020016a:	00006517          	auipc	a0,0x6
ffffffffc020016e:	4a650513          	addi	a0,a0,1190 # ffffffffc0206610 <etext+0x28>
ffffffffc0200172:	f5bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
readline(const char *prompt) {
ffffffffc0200176:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200178:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc020017a:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc020017c:	4aa9                	li	s5,10
ffffffffc020017e:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0200180:	000a7b97          	auipc	s7,0xa7
ffffffffc0200184:	360b8b93          	addi	s7,s7,864 # ffffffffc02a74e0 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200188:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc020018c:	fb9ff0ef          	jal	ra,ffffffffc0200144 <getchar>
        if (c < 0) {
ffffffffc0200190:	00054a63          	bltz	a0,ffffffffc02001a4 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200194:	00a95a63          	bge	s2,a0,ffffffffc02001a8 <readline+0x54>
ffffffffc0200198:	029a5263          	bge	s4,s1,ffffffffc02001bc <readline+0x68>
        c = getchar();
ffffffffc020019c:	fa9ff0ef          	jal	ra,ffffffffc0200144 <getchar>
        if (c < 0) {
ffffffffc02001a0:	fe055ae3          	bgez	a0,ffffffffc0200194 <readline+0x40>
            return NULL;
ffffffffc02001a4:	4501                	li	a0,0
ffffffffc02001a6:	a091                	j	ffffffffc02001ea <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc02001a8:	03351463          	bne	a0,s3,ffffffffc02001d0 <readline+0x7c>
ffffffffc02001ac:	e8a9                	bnez	s1,ffffffffc02001fe <readline+0xaa>
        c = getchar();
ffffffffc02001ae:	f97ff0ef          	jal	ra,ffffffffc0200144 <getchar>
        if (c < 0) {
ffffffffc02001b2:	fe0549e3          	bltz	a0,ffffffffc02001a4 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02001b6:	fea959e3          	bge	s2,a0,ffffffffc02001a8 <readline+0x54>
ffffffffc02001ba:	4481                	li	s1,0
            cputchar(c);
ffffffffc02001bc:	e42a                	sd	a0,8(sp)
ffffffffc02001be:	f45ff0ef          	jal	ra,ffffffffc0200102 <cputchar>
            buf[i ++] = c;
ffffffffc02001c2:	6522                	ld	a0,8(sp)
ffffffffc02001c4:	009b87b3          	add	a5,s7,s1
ffffffffc02001c8:	2485                	addiw	s1,s1,1
ffffffffc02001ca:	00a78023          	sb	a0,0(a5)
ffffffffc02001ce:	bf7d                	j	ffffffffc020018c <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc02001d0:	01550463          	beq	a0,s5,ffffffffc02001d8 <readline+0x84>
ffffffffc02001d4:	fb651ce3          	bne	a0,s6,ffffffffc020018c <readline+0x38>
            cputchar(c);
ffffffffc02001d8:	f2bff0ef          	jal	ra,ffffffffc0200102 <cputchar>
            buf[i] = '\0';
ffffffffc02001dc:	000a7517          	auipc	a0,0xa7
ffffffffc02001e0:	30450513          	addi	a0,a0,772 # ffffffffc02a74e0 <buf>
ffffffffc02001e4:	94aa                	add	s1,s1,a0
ffffffffc02001e6:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc02001ea:	60a6                	ld	ra,72(sp)
ffffffffc02001ec:	6486                	ld	s1,64(sp)
ffffffffc02001ee:	7962                	ld	s2,56(sp)
ffffffffc02001f0:	79c2                	ld	s3,48(sp)
ffffffffc02001f2:	7a22                	ld	s4,40(sp)
ffffffffc02001f4:	7a82                	ld	s5,32(sp)
ffffffffc02001f6:	6b62                	ld	s6,24(sp)
ffffffffc02001f8:	6bc2                	ld	s7,16(sp)
ffffffffc02001fa:	6161                	addi	sp,sp,80
ffffffffc02001fc:	8082                	ret
            cputchar(c);
ffffffffc02001fe:	4521                	li	a0,8
ffffffffc0200200:	f03ff0ef          	jal	ra,ffffffffc0200102 <cputchar>
            i --;
ffffffffc0200204:	34fd                	addiw	s1,s1,-1
ffffffffc0200206:	b759                	j	ffffffffc020018c <readline+0x38>

ffffffffc0200208 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200208:	000b2317          	auipc	t1,0xb2
ffffffffc020020c:	7a030313          	addi	t1,t1,1952 # ffffffffc02b29a8 <is_panic>
ffffffffc0200210:	00033e03          	ld	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200214:	715d                	addi	sp,sp,-80
ffffffffc0200216:	ec06                	sd	ra,24(sp)
ffffffffc0200218:	e822                	sd	s0,16(sp)
ffffffffc020021a:	f436                	sd	a3,40(sp)
ffffffffc020021c:	f83a                	sd	a4,48(sp)
ffffffffc020021e:	fc3e                	sd	a5,56(sp)
ffffffffc0200220:	e0c2                	sd	a6,64(sp)
ffffffffc0200222:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc0200224:	020e1a63          	bnez	t3,ffffffffc0200258 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200228:	4785                	li	a5,1
ffffffffc020022a:	00f33023          	sd	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc020022e:	8432                	mv	s0,a2
ffffffffc0200230:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200232:	862e                	mv	a2,a1
ffffffffc0200234:	85aa                	mv	a1,a0
ffffffffc0200236:	00006517          	auipc	a0,0x6
ffffffffc020023a:	3e250513          	addi	a0,a0,994 # ffffffffc0206618 <etext+0x30>
    va_start(ap, fmt);
ffffffffc020023e:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200240:	e8dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200244:	65a2                	ld	a1,8(sp)
ffffffffc0200246:	8522                	mv	a0,s0
ffffffffc0200248:	e65ff0ef          	jal	ra,ffffffffc02000ac <vcprintf>
    cprintf("\n");
ffffffffc020024c:	00008517          	auipc	a0,0x8
ffffffffc0200250:	efc50513          	addi	a0,a0,-260 # ffffffffc0208148 <default_pmm_manager+0x400>
ffffffffc0200254:	e79ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200258:	4501                	li	a0,0
ffffffffc020025a:	4581                	li	a1,0
ffffffffc020025c:	4601                	li	a2,0
ffffffffc020025e:	48a1                	li	a7,8
ffffffffc0200260:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc0200264:	3e4000ef          	jal	ra,ffffffffc0200648 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200268:	4501                	li	a0,0
ffffffffc020026a:	174000ef          	jal	ra,ffffffffc02003de <kmonitor>
    while (1) {
ffffffffc020026e:	bfed                	j	ffffffffc0200268 <__panic+0x60>

ffffffffc0200270 <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200270:	715d                	addi	sp,sp,-80
ffffffffc0200272:	832e                	mv	t1,a1
ffffffffc0200274:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200276:	85aa                	mv	a1,a0
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200278:	8432                	mv	s0,a2
ffffffffc020027a:	fc3e                	sd	a5,56(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc020027c:	861a                	mv	a2,t1
    va_start(ap, fmt);
ffffffffc020027e:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200280:	00006517          	auipc	a0,0x6
ffffffffc0200284:	3b850513          	addi	a0,a0,952 # ffffffffc0206638 <etext+0x50>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200288:	ec06                	sd	ra,24(sp)
ffffffffc020028a:	f436                	sd	a3,40(sp)
ffffffffc020028c:	f83a                	sd	a4,48(sp)
ffffffffc020028e:	e0c2                	sd	a6,64(sp)
ffffffffc0200290:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200292:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200294:	e39ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200298:	65a2                	ld	a1,8(sp)
ffffffffc020029a:	8522                	mv	a0,s0
ffffffffc020029c:	e11ff0ef          	jal	ra,ffffffffc02000ac <vcprintf>
    cprintf("\n");
ffffffffc02002a0:	00008517          	auipc	a0,0x8
ffffffffc02002a4:	ea850513          	addi	a0,a0,-344 # ffffffffc0208148 <default_pmm_manager+0x400>
ffffffffc02002a8:	e25ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    va_end(ap);
}
ffffffffc02002ac:	60e2                	ld	ra,24(sp)
ffffffffc02002ae:	6442                	ld	s0,16(sp)
ffffffffc02002b0:	6161                	addi	sp,sp,80
ffffffffc02002b2:	8082                	ret

ffffffffc02002b4 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02002b4:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02002b6:	00006517          	auipc	a0,0x6
ffffffffc02002ba:	3a250513          	addi	a0,a0,930 # ffffffffc0206658 <etext+0x70>
void print_kerninfo(void) {
ffffffffc02002be:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02002c0:	e0dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc02002c4:	00000597          	auipc	a1,0x0
ffffffffc02002c8:	d6e58593          	addi	a1,a1,-658 # ffffffffc0200032 <kern_init>
ffffffffc02002cc:	00006517          	auipc	a0,0x6
ffffffffc02002d0:	3ac50513          	addi	a0,a0,940 # ffffffffc0206678 <etext+0x90>
ffffffffc02002d4:	df9ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc02002d8:	00006597          	auipc	a1,0x6
ffffffffc02002dc:	31058593          	addi	a1,a1,784 # ffffffffc02065e8 <etext>
ffffffffc02002e0:	00006517          	auipc	a0,0x6
ffffffffc02002e4:	3b850513          	addi	a0,a0,952 # ffffffffc0206698 <etext+0xb0>
ffffffffc02002e8:	de5ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc02002ec:	000a7597          	auipc	a1,0xa7
ffffffffc02002f0:	1f458593          	addi	a1,a1,500 # ffffffffc02a74e0 <buf>
ffffffffc02002f4:	00006517          	auipc	a0,0x6
ffffffffc02002f8:	3c450513          	addi	a0,a0,964 # ffffffffc02066b8 <etext+0xd0>
ffffffffc02002fc:	dd1ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200300:	000b2597          	auipc	a1,0xb2
ffffffffc0200304:	73c58593          	addi	a1,a1,1852 # ffffffffc02b2a3c <end>
ffffffffc0200308:	00006517          	auipc	a0,0x6
ffffffffc020030c:	3d050513          	addi	a0,a0,976 # ffffffffc02066d8 <etext+0xf0>
ffffffffc0200310:	dbdff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200314:	000b3597          	auipc	a1,0xb3
ffffffffc0200318:	b2758593          	addi	a1,a1,-1241 # ffffffffc02b2e3b <end+0x3ff>
ffffffffc020031c:	00000797          	auipc	a5,0x0
ffffffffc0200320:	d1678793          	addi	a5,a5,-746 # ffffffffc0200032 <kern_init>
ffffffffc0200324:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200328:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020032c:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020032e:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200332:	95be                	add	a1,a1,a5
ffffffffc0200334:	85a9                	srai	a1,a1,0xa
ffffffffc0200336:	00006517          	auipc	a0,0x6
ffffffffc020033a:	3c250513          	addi	a0,a0,962 # ffffffffc02066f8 <etext+0x110>
}
ffffffffc020033e:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200340:	b371                	j	ffffffffc02000cc <cprintf>

ffffffffc0200342 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc0200342:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc0200344:	00006617          	auipc	a2,0x6
ffffffffc0200348:	3e460613          	addi	a2,a2,996 # ffffffffc0206728 <etext+0x140>
ffffffffc020034c:	04d00593          	li	a1,77
ffffffffc0200350:	00006517          	auipc	a0,0x6
ffffffffc0200354:	3f050513          	addi	a0,a0,1008 # ffffffffc0206740 <etext+0x158>
void print_stackframe(void) {
ffffffffc0200358:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc020035a:	eafff0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc020035e <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020035e:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200360:	00006617          	auipc	a2,0x6
ffffffffc0200364:	3f860613          	addi	a2,a2,1016 # ffffffffc0206758 <etext+0x170>
ffffffffc0200368:	00006597          	auipc	a1,0x6
ffffffffc020036c:	41058593          	addi	a1,a1,1040 # ffffffffc0206778 <etext+0x190>
ffffffffc0200370:	00006517          	auipc	a0,0x6
ffffffffc0200374:	41050513          	addi	a0,a0,1040 # ffffffffc0206780 <etext+0x198>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200378:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020037a:	d53ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc020037e:	00006617          	auipc	a2,0x6
ffffffffc0200382:	41260613          	addi	a2,a2,1042 # ffffffffc0206790 <etext+0x1a8>
ffffffffc0200386:	00006597          	auipc	a1,0x6
ffffffffc020038a:	43258593          	addi	a1,a1,1074 # ffffffffc02067b8 <etext+0x1d0>
ffffffffc020038e:	00006517          	auipc	a0,0x6
ffffffffc0200392:	3f250513          	addi	a0,a0,1010 # ffffffffc0206780 <etext+0x198>
ffffffffc0200396:	d37ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc020039a:	00006617          	auipc	a2,0x6
ffffffffc020039e:	42e60613          	addi	a2,a2,1070 # ffffffffc02067c8 <etext+0x1e0>
ffffffffc02003a2:	00006597          	auipc	a1,0x6
ffffffffc02003a6:	44658593          	addi	a1,a1,1094 # ffffffffc02067e8 <etext+0x200>
ffffffffc02003aa:	00006517          	auipc	a0,0x6
ffffffffc02003ae:	3d650513          	addi	a0,a0,982 # ffffffffc0206780 <etext+0x198>
ffffffffc02003b2:	d1bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    }
    return 0;
}
ffffffffc02003b6:	60a2                	ld	ra,8(sp)
ffffffffc02003b8:	4501                	li	a0,0
ffffffffc02003ba:	0141                	addi	sp,sp,16
ffffffffc02003bc:	8082                	ret

ffffffffc02003be <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02003be:	1141                	addi	sp,sp,-16
ffffffffc02003c0:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02003c2:	ef3ff0ef          	jal	ra,ffffffffc02002b4 <print_kerninfo>
    return 0;
}
ffffffffc02003c6:	60a2                	ld	ra,8(sp)
ffffffffc02003c8:	4501                	li	a0,0
ffffffffc02003ca:	0141                	addi	sp,sp,16
ffffffffc02003cc:	8082                	ret

ffffffffc02003ce <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02003ce:	1141                	addi	sp,sp,-16
ffffffffc02003d0:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02003d2:	f71ff0ef          	jal	ra,ffffffffc0200342 <print_stackframe>
    return 0;
}
ffffffffc02003d6:	60a2                	ld	ra,8(sp)
ffffffffc02003d8:	4501                	li	a0,0
ffffffffc02003da:	0141                	addi	sp,sp,16
ffffffffc02003dc:	8082                	ret

ffffffffc02003de <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02003de:	7115                	addi	sp,sp,-224
ffffffffc02003e0:	ed5e                	sd	s7,152(sp)
ffffffffc02003e2:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02003e4:	00006517          	auipc	a0,0x6
ffffffffc02003e8:	41450513          	addi	a0,a0,1044 # ffffffffc02067f8 <etext+0x210>
kmonitor(struct trapframe *tf) {
ffffffffc02003ec:	ed86                	sd	ra,216(sp)
ffffffffc02003ee:	e9a2                	sd	s0,208(sp)
ffffffffc02003f0:	e5a6                	sd	s1,200(sp)
ffffffffc02003f2:	e1ca                	sd	s2,192(sp)
ffffffffc02003f4:	fd4e                	sd	s3,184(sp)
ffffffffc02003f6:	f952                	sd	s4,176(sp)
ffffffffc02003f8:	f556                	sd	s5,168(sp)
ffffffffc02003fa:	f15a                	sd	s6,160(sp)
ffffffffc02003fc:	e962                	sd	s8,144(sp)
ffffffffc02003fe:	e566                	sd	s9,136(sp)
ffffffffc0200400:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200402:	ccbff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200406:	00006517          	auipc	a0,0x6
ffffffffc020040a:	41a50513          	addi	a0,a0,1050 # ffffffffc0206820 <etext+0x238>
ffffffffc020040e:	cbfff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    if (tf != NULL) {
ffffffffc0200412:	000b8563          	beqz	s7,ffffffffc020041c <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200416:	855e                	mv	a0,s7
ffffffffc0200418:	41e000ef          	jal	ra,ffffffffc0200836 <print_trapframe>
ffffffffc020041c:	00006c17          	auipc	s8,0x6
ffffffffc0200420:	474c0c13          	addi	s8,s8,1140 # ffffffffc0206890 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200424:	00006917          	auipc	s2,0x6
ffffffffc0200428:	42490913          	addi	s2,s2,1060 # ffffffffc0206848 <etext+0x260>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020042c:	00006497          	auipc	s1,0x6
ffffffffc0200430:	42448493          	addi	s1,s1,1060 # ffffffffc0206850 <etext+0x268>
        if (argc == MAXARGS - 1) {
ffffffffc0200434:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200436:	00006b17          	auipc	s6,0x6
ffffffffc020043a:	422b0b13          	addi	s6,s6,1058 # ffffffffc0206858 <etext+0x270>
        argv[argc ++] = buf;
ffffffffc020043e:	00006a17          	auipc	s4,0x6
ffffffffc0200442:	33aa0a13          	addi	s4,s4,826 # ffffffffc0206778 <etext+0x190>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200446:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200448:	854a                	mv	a0,s2
ffffffffc020044a:	d0bff0ef          	jal	ra,ffffffffc0200154 <readline>
ffffffffc020044e:	842a                	mv	s0,a0
ffffffffc0200450:	dd65                	beqz	a0,ffffffffc0200448 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200452:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200456:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200458:	e1bd                	bnez	a1,ffffffffc02004be <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc020045a:	fe0c87e3          	beqz	s9,ffffffffc0200448 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020045e:	6582                	ld	a1,0(sp)
ffffffffc0200460:	00006d17          	auipc	s10,0x6
ffffffffc0200464:	430d0d13          	addi	s10,s10,1072 # ffffffffc0206890 <commands>
        argv[argc ++] = buf;
ffffffffc0200468:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020046a:	4401                	li	s0,0
ffffffffc020046c:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020046e:	519050ef          	jal	ra,ffffffffc0206186 <strcmp>
ffffffffc0200472:	c919                	beqz	a0,ffffffffc0200488 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200474:	2405                	addiw	s0,s0,1
ffffffffc0200476:	0b540063          	beq	s0,s5,ffffffffc0200516 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020047a:	000d3503          	ld	a0,0(s10)
ffffffffc020047e:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200480:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200482:	505050ef          	jal	ra,ffffffffc0206186 <strcmp>
ffffffffc0200486:	f57d                	bnez	a0,ffffffffc0200474 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200488:	00141793          	slli	a5,s0,0x1
ffffffffc020048c:	97a2                	add	a5,a5,s0
ffffffffc020048e:	078e                	slli	a5,a5,0x3
ffffffffc0200490:	97e2                	add	a5,a5,s8
ffffffffc0200492:	6b9c                	ld	a5,16(a5)
ffffffffc0200494:	865e                	mv	a2,s7
ffffffffc0200496:	002c                	addi	a1,sp,8
ffffffffc0200498:	fffc851b          	addiw	a0,s9,-1
ffffffffc020049c:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020049e:	fa0555e3          	bgez	a0,ffffffffc0200448 <kmonitor+0x6a>
}
ffffffffc02004a2:	60ee                	ld	ra,216(sp)
ffffffffc02004a4:	644e                	ld	s0,208(sp)
ffffffffc02004a6:	64ae                	ld	s1,200(sp)
ffffffffc02004a8:	690e                	ld	s2,192(sp)
ffffffffc02004aa:	79ea                	ld	s3,184(sp)
ffffffffc02004ac:	7a4a                	ld	s4,176(sp)
ffffffffc02004ae:	7aaa                	ld	s5,168(sp)
ffffffffc02004b0:	7b0a                	ld	s6,160(sp)
ffffffffc02004b2:	6bea                	ld	s7,152(sp)
ffffffffc02004b4:	6c4a                	ld	s8,144(sp)
ffffffffc02004b6:	6caa                	ld	s9,136(sp)
ffffffffc02004b8:	6d0a                	ld	s10,128(sp)
ffffffffc02004ba:	612d                	addi	sp,sp,224
ffffffffc02004bc:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02004be:	8526                	mv	a0,s1
ffffffffc02004c0:	4e5050ef          	jal	ra,ffffffffc02061a4 <strchr>
ffffffffc02004c4:	c901                	beqz	a0,ffffffffc02004d4 <kmonitor+0xf6>
ffffffffc02004c6:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02004ca:	00040023          	sb	zero,0(s0)
ffffffffc02004ce:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02004d0:	d5c9                	beqz	a1,ffffffffc020045a <kmonitor+0x7c>
ffffffffc02004d2:	b7f5                	j	ffffffffc02004be <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc02004d4:	00044783          	lbu	a5,0(s0)
ffffffffc02004d8:	d3c9                	beqz	a5,ffffffffc020045a <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc02004da:	033c8963          	beq	s9,s3,ffffffffc020050c <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc02004de:	003c9793          	slli	a5,s9,0x3
ffffffffc02004e2:	0118                	addi	a4,sp,128
ffffffffc02004e4:	97ba                	add	a5,a5,a4
ffffffffc02004e6:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02004ea:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02004ee:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02004f0:	e591                	bnez	a1,ffffffffc02004fc <kmonitor+0x11e>
ffffffffc02004f2:	b7b5                	j	ffffffffc020045e <kmonitor+0x80>
ffffffffc02004f4:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02004f8:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02004fa:	d1a5                	beqz	a1,ffffffffc020045a <kmonitor+0x7c>
ffffffffc02004fc:	8526                	mv	a0,s1
ffffffffc02004fe:	4a7050ef          	jal	ra,ffffffffc02061a4 <strchr>
ffffffffc0200502:	d96d                	beqz	a0,ffffffffc02004f4 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200504:	00044583          	lbu	a1,0(s0)
ffffffffc0200508:	d9a9                	beqz	a1,ffffffffc020045a <kmonitor+0x7c>
ffffffffc020050a:	bf55                	j	ffffffffc02004be <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020050c:	45c1                	li	a1,16
ffffffffc020050e:	855a                	mv	a0,s6
ffffffffc0200510:	bbdff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0200514:	b7e9                	j	ffffffffc02004de <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200516:	6582                	ld	a1,0(sp)
ffffffffc0200518:	00006517          	auipc	a0,0x6
ffffffffc020051c:	36050513          	addi	a0,a0,864 # ffffffffc0206878 <etext+0x290>
ffffffffc0200520:	badff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    return 0;
ffffffffc0200524:	b715                	j	ffffffffc0200448 <kmonitor+0x6a>

ffffffffc0200526 <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc0200526:	8082                	ret

ffffffffc0200528 <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc0200528:	00253513          	sltiu	a0,a0,2
ffffffffc020052c:	8082                	ret

ffffffffc020052e <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc020052e:	03800513          	li	a0,56
ffffffffc0200532:	8082                	ret

ffffffffc0200534 <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200534:	000a7797          	auipc	a5,0xa7
ffffffffc0200538:	3ac78793          	addi	a5,a5,940 # ffffffffc02a78e0 <ide>
    int iobase = secno * SECTSIZE;
ffffffffc020053c:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc0200540:	1141                	addi	sp,sp,-16
ffffffffc0200542:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200544:	95be                	add	a1,a1,a5
ffffffffc0200546:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc020054a:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc020054c:	481050ef          	jal	ra,ffffffffc02061cc <memcpy>
    return 0;
}
ffffffffc0200550:	60a2                	ld	ra,8(sp)
ffffffffc0200552:	4501                	li	a0,0
ffffffffc0200554:	0141                	addi	sp,sp,16
ffffffffc0200556:	8082                	ret

ffffffffc0200558 <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
    int iobase = secno * SECTSIZE;
ffffffffc0200558:	0095979b          	slliw	a5,a1,0x9
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020055c:	000a7517          	auipc	a0,0xa7
ffffffffc0200560:	38450513          	addi	a0,a0,900 # ffffffffc02a78e0 <ide>
                   size_t nsecs) {
ffffffffc0200564:	1141                	addi	sp,sp,-16
ffffffffc0200566:	85b2                	mv	a1,a2
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200568:	953e                	add	a0,a0,a5
ffffffffc020056a:	00969613          	slli	a2,a3,0x9
                   size_t nsecs) {
ffffffffc020056e:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200570:	45d050ef          	jal	ra,ffffffffc02061cc <memcpy>
    return 0;
}
ffffffffc0200574:	60a2                	ld	ra,8(sp)
ffffffffc0200576:	4501                	li	a0,0
ffffffffc0200578:	0141                	addi	sp,sp,16
ffffffffc020057a:	8082                	ret

ffffffffc020057c <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc020057c:	67e1                	lui	a5,0x18
ffffffffc020057e:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xd560>
ffffffffc0200582:	000b2717          	auipc	a4,0xb2
ffffffffc0200586:	42f73b23          	sd	a5,1078(a4) # ffffffffc02b29b8 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020058a:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc020058e:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200590:	953e                	add	a0,a0,a5
ffffffffc0200592:	4601                	li	a2,0
ffffffffc0200594:	4881                	li	a7,0
ffffffffc0200596:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc020059a:	02000793          	li	a5,32
ffffffffc020059e:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc02005a2:	00006517          	auipc	a0,0x6
ffffffffc02005a6:	33650513          	addi	a0,a0,822 # ffffffffc02068d8 <commands+0x48>
    ticks = 0;
ffffffffc02005aa:	000b2797          	auipc	a5,0xb2
ffffffffc02005ae:	4007b323          	sd	zero,1030(a5) # ffffffffc02b29b0 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc02005b2:	be29                	j	ffffffffc02000cc <cprintf>

ffffffffc02005b4 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc02005b4:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc02005b8:	000b2797          	auipc	a5,0xb2
ffffffffc02005bc:	4007b783          	ld	a5,1024(a5) # ffffffffc02b29b8 <timebase>
ffffffffc02005c0:	953e                	add	a0,a0,a5
ffffffffc02005c2:	4581                	li	a1,0
ffffffffc02005c4:	4601                	li	a2,0
ffffffffc02005c6:	4881                	li	a7,0
ffffffffc02005c8:	00000073          	ecall
ffffffffc02005cc:	8082                	ret

ffffffffc02005ce <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02005ce:	8082                	ret

ffffffffc02005d0 <cons_putc>:
#include <sched.h>
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02005d0:	100027f3          	csrr	a5,sstatus
ffffffffc02005d4:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc02005d6:	0ff57513          	zext.b	a0,a0
ffffffffc02005da:	e799                	bnez	a5,ffffffffc02005e8 <cons_putc+0x18>
ffffffffc02005dc:	4581                	li	a1,0
ffffffffc02005de:	4601                	li	a2,0
ffffffffc02005e0:	4885                	li	a7,1
ffffffffc02005e2:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02005e6:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005e8:	1101                	addi	sp,sp,-32
ffffffffc02005ea:	ec06                	sd	ra,24(sp)
ffffffffc02005ec:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005ee:	05a000ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc02005f2:	6522                	ld	a0,8(sp)
ffffffffc02005f4:	4581                	li	a1,0
ffffffffc02005f6:	4601                	li	a2,0
ffffffffc02005f8:	4885                	li	a7,1
ffffffffc02005fa:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005fe:	60e2                	ld	ra,24(sp)
ffffffffc0200600:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200602:	a081                	j	ffffffffc0200642 <intr_enable>

ffffffffc0200604 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200604:	100027f3          	csrr	a5,sstatus
ffffffffc0200608:	8b89                	andi	a5,a5,2
ffffffffc020060a:	eb89                	bnez	a5,ffffffffc020061c <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc020060c:	4501                	li	a0,0
ffffffffc020060e:	4581                	li	a1,0
ffffffffc0200610:	4601                	li	a2,0
ffffffffc0200612:	4889                	li	a7,2
ffffffffc0200614:	00000073          	ecall
ffffffffc0200618:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc020061a:	8082                	ret
int cons_getc(void) {
ffffffffc020061c:	1101                	addi	sp,sp,-32
ffffffffc020061e:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200620:	028000ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc0200624:	4501                	li	a0,0
ffffffffc0200626:	4581                	li	a1,0
ffffffffc0200628:	4601                	li	a2,0
ffffffffc020062a:	4889                	li	a7,2
ffffffffc020062c:	00000073          	ecall
ffffffffc0200630:	2501                	sext.w	a0,a0
ffffffffc0200632:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0200634:	00e000ef          	jal	ra,ffffffffc0200642 <intr_enable>
}
ffffffffc0200638:	60e2                	ld	ra,24(sp)
ffffffffc020063a:	6522                	ld	a0,8(sp)
ffffffffc020063c:	6105                	addi	sp,sp,32
ffffffffc020063e:	8082                	ret

ffffffffc0200640 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200640:	8082                	ret

ffffffffc0200642 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200642:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200646:	8082                	ret

ffffffffc0200648 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200648:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020064c:	8082                	ret

ffffffffc020064e <idt_init>:
void
idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020064e:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200652:	00000797          	auipc	a5,0x0
ffffffffc0200656:	65a78793          	addi	a5,a5,1626 # ffffffffc0200cac <__alltraps>
ffffffffc020065a:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020065e:	000407b7          	lui	a5,0x40
ffffffffc0200662:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200666:	8082                	ret

ffffffffc0200668 <print_regs>:
    cprintf("  tval 0x%08x\n", tf->tval);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs* gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200668:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs* gpr) {
ffffffffc020066a:	1141                	addi	sp,sp,-16
ffffffffc020066c:	e022                	sd	s0,0(sp)
ffffffffc020066e:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200670:	00006517          	auipc	a0,0x6
ffffffffc0200674:	28850513          	addi	a0,a0,648 # ffffffffc02068f8 <commands+0x68>
void print_regs(struct pushregs* gpr) {
ffffffffc0200678:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020067a:	a53ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020067e:	640c                	ld	a1,8(s0)
ffffffffc0200680:	00006517          	auipc	a0,0x6
ffffffffc0200684:	29050513          	addi	a0,a0,656 # ffffffffc0206910 <commands+0x80>
ffffffffc0200688:	a45ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020068c:	680c                	ld	a1,16(s0)
ffffffffc020068e:	00006517          	auipc	a0,0x6
ffffffffc0200692:	29a50513          	addi	a0,a0,666 # ffffffffc0206928 <commands+0x98>
ffffffffc0200696:	a37ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc020069a:	6c0c                	ld	a1,24(s0)
ffffffffc020069c:	00006517          	auipc	a0,0x6
ffffffffc02006a0:	2a450513          	addi	a0,a0,676 # ffffffffc0206940 <commands+0xb0>
ffffffffc02006a4:	a29ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02006a8:	700c                	ld	a1,32(s0)
ffffffffc02006aa:	00006517          	auipc	a0,0x6
ffffffffc02006ae:	2ae50513          	addi	a0,a0,686 # ffffffffc0206958 <commands+0xc8>
ffffffffc02006b2:	a1bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02006b6:	740c                	ld	a1,40(s0)
ffffffffc02006b8:	00006517          	auipc	a0,0x6
ffffffffc02006bc:	2b850513          	addi	a0,a0,696 # ffffffffc0206970 <commands+0xe0>
ffffffffc02006c0:	a0dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02006c4:	780c                	ld	a1,48(s0)
ffffffffc02006c6:	00006517          	auipc	a0,0x6
ffffffffc02006ca:	2c250513          	addi	a0,a0,706 # ffffffffc0206988 <commands+0xf8>
ffffffffc02006ce:	9ffff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006d2:	7c0c                	ld	a1,56(s0)
ffffffffc02006d4:	00006517          	auipc	a0,0x6
ffffffffc02006d8:	2cc50513          	addi	a0,a0,716 # ffffffffc02069a0 <commands+0x110>
ffffffffc02006dc:	9f1ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006e0:	602c                	ld	a1,64(s0)
ffffffffc02006e2:	00006517          	auipc	a0,0x6
ffffffffc02006e6:	2d650513          	addi	a0,a0,726 # ffffffffc02069b8 <commands+0x128>
ffffffffc02006ea:	9e3ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02006ee:	642c                	ld	a1,72(s0)
ffffffffc02006f0:	00006517          	auipc	a0,0x6
ffffffffc02006f4:	2e050513          	addi	a0,a0,736 # ffffffffc02069d0 <commands+0x140>
ffffffffc02006f8:	9d5ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02006fc:	682c                	ld	a1,80(s0)
ffffffffc02006fe:	00006517          	auipc	a0,0x6
ffffffffc0200702:	2ea50513          	addi	a0,a0,746 # ffffffffc02069e8 <commands+0x158>
ffffffffc0200706:	9c7ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020070a:	6c2c                	ld	a1,88(s0)
ffffffffc020070c:	00006517          	auipc	a0,0x6
ffffffffc0200710:	2f450513          	addi	a0,a0,756 # ffffffffc0206a00 <commands+0x170>
ffffffffc0200714:	9b9ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200718:	702c                	ld	a1,96(s0)
ffffffffc020071a:	00006517          	auipc	a0,0x6
ffffffffc020071e:	2fe50513          	addi	a0,a0,766 # ffffffffc0206a18 <commands+0x188>
ffffffffc0200722:	9abff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200726:	742c                	ld	a1,104(s0)
ffffffffc0200728:	00006517          	auipc	a0,0x6
ffffffffc020072c:	30850513          	addi	a0,a0,776 # ffffffffc0206a30 <commands+0x1a0>
ffffffffc0200730:	99dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200734:	782c                	ld	a1,112(s0)
ffffffffc0200736:	00006517          	auipc	a0,0x6
ffffffffc020073a:	31250513          	addi	a0,a0,786 # ffffffffc0206a48 <commands+0x1b8>
ffffffffc020073e:	98fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200742:	7c2c                	ld	a1,120(s0)
ffffffffc0200744:	00006517          	auipc	a0,0x6
ffffffffc0200748:	31c50513          	addi	a0,a0,796 # ffffffffc0206a60 <commands+0x1d0>
ffffffffc020074c:	981ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200750:	604c                	ld	a1,128(s0)
ffffffffc0200752:	00006517          	auipc	a0,0x6
ffffffffc0200756:	32650513          	addi	a0,a0,806 # ffffffffc0206a78 <commands+0x1e8>
ffffffffc020075a:	973ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc020075e:	644c                	ld	a1,136(s0)
ffffffffc0200760:	00006517          	auipc	a0,0x6
ffffffffc0200764:	33050513          	addi	a0,a0,816 # ffffffffc0206a90 <commands+0x200>
ffffffffc0200768:	965ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc020076c:	684c                	ld	a1,144(s0)
ffffffffc020076e:	00006517          	auipc	a0,0x6
ffffffffc0200772:	33a50513          	addi	a0,a0,826 # ffffffffc0206aa8 <commands+0x218>
ffffffffc0200776:	957ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020077a:	6c4c                	ld	a1,152(s0)
ffffffffc020077c:	00006517          	auipc	a0,0x6
ffffffffc0200780:	34450513          	addi	a0,a0,836 # ffffffffc0206ac0 <commands+0x230>
ffffffffc0200784:	949ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200788:	704c                	ld	a1,160(s0)
ffffffffc020078a:	00006517          	auipc	a0,0x6
ffffffffc020078e:	34e50513          	addi	a0,a0,846 # ffffffffc0206ad8 <commands+0x248>
ffffffffc0200792:	93bff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200796:	744c                	ld	a1,168(s0)
ffffffffc0200798:	00006517          	auipc	a0,0x6
ffffffffc020079c:	35850513          	addi	a0,a0,856 # ffffffffc0206af0 <commands+0x260>
ffffffffc02007a0:	92dff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02007a4:	784c                	ld	a1,176(s0)
ffffffffc02007a6:	00006517          	auipc	a0,0x6
ffffffffc02007aa:	36250513          	addi	a0,a0,866 # ffffffffc0206b08 <commands+0x278>
ffffffffc02007ae:	91fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02007b2:	7c4c                	ld	a1,184(s0)
ffffffffc02007b4:	00006517          	auipc	a0,0x6
ffffffffc02007b8:	36c50513          	addi	a0,a0,876 # ffffffffc0206b20 <commands+0x290>
ffffffffc02007bc:	911ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02007c0:	606c                	ld	a1,192(s0)
ffffffffc02007c2:	00006517          	auipc	a0,0x6
ffffffffc02007c6:	37650513          	addi	a0,a0,886 # ffffffffc0206b38 <commands+0x2a8>
ffffffffc02007ca:	903ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007ce:	646c                	ld	a1,200(s0)
ffffffffc02007d0:	00006517          	auipc	a0,0x6
ffffffffc02007d4:	38050513          	addi	a0,a0,896 # ffffffffc0206b50 <commands+0x2c0>
ffffffffc02007d8:	8f5ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007dc:	686c                	ld	a1,208(s0)
ffffffffc02007de:	00006517          	auipc	a0,0x6
ffffffffc02007e2:	38a50513          	addi	a0,a0,906 # ffffffffc0206b68 <commands+0x2d8>
ffffffffc02007e6:	8e7ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007ea:	6c6c                	ld	a1,216(s0)
ffffffffc02007ec:	00006517          	auipc	a0,0x6
ffffffffc02007f0:	39450513          	addi	a0,a0,916 # ffffffffc0206b80 <commands+0x2f0>
ffffffffc02007f4:	8d9ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc02007f8:	706c                	ld	a1,224(s0)
ffffffffc02007fa:	00006517          	auipc	a0,0x6
ffffffffc02007fe:	39e50513          	addi	a0,a0,926 # ffffffffc0206b98 <commands+0x308>
ffffffffc0200802:	8cbff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200806:	746c                	ld	a1,232(s0)
ffffffffc0200808:	00006517          	auipc	a0,0x6
ffffffffc020080c:	3a850513          	addi	a0,a0,936 # ffffffffc0206bb0 <commands+0x320>
ffffffffc0200810:	8bdff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200814:	786c                	ld	a1,240(s0)
ffffffffc0200816:	00006517          	auipc	a0,0x6
ffffffffc020081a:	3b250513          	addi	a0,a0,946 # ffffffffc0206bc8 <commands+0x338>
ffffffffc020081e:	8afff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200822:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200824:	6402                	ld	s0,0(sp)
ffffffffc0200826:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200828:	00006517          	auipc	a0,0x6
ffffffffc020082c:	3b850513          	addi	a0,a0,952 # ffffffffc0206be0 <commands+0x350>
}
ffffffffc0200830:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200832:	89bff06f          	j	ffffffffc02000cc <cprintf>

ffffffffc0200836 <print_trapframe>:
print_trapframe(struct trapframe *tf) {
ffffffffc0200836:	1141                	addi	sp,sp,-16
ffffffffc0200838:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020083a:	85aa                	mv	a1,a0
print_trapframe(struct trapframe *tf) {
ffffffffc020083c:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc020083e:	00006517          	auipc	a0,0x6
ffffffffc0200842:	3ba50513          	addi	a0,a0,954 # ffffffffc0206bf8 <commands+0x368>
print_trapframe(struct trapframe *tf) {
ffffffffc0200846:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200848:	885ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    print_regs(&tf->gpr);
ffffffffc020084c:	8522                	mv	a0,s0
ffffffffc020084e:	e1bff0ef          	jal	ra,ffffffffc0200668 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200852:	10043583          	ld	a1,256(s0)
ffffffffc0200856:	00006517          	auipc	a0,0x6
ffffffffc020085a:	3ba50513          	addi	a0,a0,954 # ffffffffc0206c10 <commands+0x380>
ffffffffc020085e:	86fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200862:	10843583          	ld	a1,264(s0)
ffffffffc0200866:	00006517          	auipc	a0,0x6
ffffffffc020086a:	3c250513          	addi	a0,a0,962 # ffffffffc0206c28 <commands+0x398>
ffffffffc020086e:	85fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200872:	11043583          	ld	a1,272(s0)
ffffffffc0200876:	00006517          	auipc	a0,0x6
ffffffffc020087a:	3ca50513          	addi	a0,a0,970 # ffffffffc0206c40 <commands+0x3b0>
ffffffffc020087e:	84fff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200882:	11843583          	ld	a1,280(s0)
}
ffffffffc0200886:	6402                	ld	s0,0(sp)
ffffffffc0200888:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020088a:	00006517          	auipc	a0,0x6
ffffffffc020088e:	3c650513          	addi	a0,a0,966 # ffffffffc0206c50 <commands+0x3c0>
}
ffffffffc0200892:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200894:	839ff06f          	j	ffffffffc02000cc <cprintf>

ffffffffc0200898 <pgfault_handler>:
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int
pgfault_handler(struct trapframe *tf) {
ffffffffc0200898:	1101                	addi	sp,sp,-32
ffffffffc020089a:	e426                	sd	s1,8(sp)
    extern struct mm_struct *check_mm_struct;
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc020089c:	000b2497          	auipc	s1,0xb2
ffffffffc02008a0:	12448493          	addi	s1,s1,292 # ffffffffc02b29c0 <check_mm_struct>
ffffffffc02008a4:	609c                	ld	a5,0(s1)
pgfault_handler(struct trapframe *tf) {
ffffffffc02008a6:	e822                	sd	s0,16(sp)
ffffffffc02008a8:	ec06                	sd	ra,24(sp)
ffffffffc02008aa:	842a                	mv	s0,a0
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc02008ac:	cbad                	beqz	a5,ffffffffc020091e <pgfault_handler+0x86>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008ae:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008b2:	11053583          	ld	a1,272(a0)
ffffffffc02008b6:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008ba:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008be:	c7b1                	beqz	a5,ffffffffc020090a <pgfault_handler+0x72>
ffffffffc02008c0:	11843703          	ld	a4,280(s0)
ffffffffc02008c4:	47bd                	li	a5,15
ffffffffc02008c6:	05700693          	li	a3,87
ffffffffc02008ca:	00f70463          	beq	a4,a5,ffffffffc02008d2 <pgfault_handler+0x3a>
ffffffffc02008ce:	05200693          	li	a3,82
ffffffffc02008d2:	00006517          	auipc	a0,0x6
ffffffffc02008d6:	39650513          	addi	a0,a0,918 # ffffffffc0206c68 <commands+0x3d8>
ffffffffc02008da:	ff2ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            print_pgfault(tf);
        }
    struct mm_struct *mm;
    if (check_mm_struct != NULL) {
ffffffffc02008de:	6088                	ld	a0,0(s1)
ffffffffc02008e0:	cd1d                	beqz	a0,ffffffffc020091e <pgfault_handler+0x86>
        assert(current == idleproc);
ffffffffc02008e2:	000b2717          	auipc	a4,0xb2
ffffffffc02008e6:	13e73703          	ld	a4,318(a4) # ffffffffc02b2a20 <current>
ffffffffc02008ea:	000b2797          	auipc	a5,0xb2
ffffffffc02008ee:	13e7b783          	ld	a5,318(a5) # ffffffffc02b2a28 <idleproc>
ffffffffc02008f2:	04f71663          	bne	a4,a5,ffffffffc020093e <pgfault_handler+0xa6>
            print_pgfault(tf);
            panic("unhandled page fault.\n");
        }
        mm = current->mm;
    }
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc02008f6:	11043603          	ld	a2,272(s0)
ffffffffc02008fa:	11843583          	ld	a1,280(s0)
}
ffffffffc02008fe:	6442                	ld	s0,16(sp)
ffffffffc0200900:	60e2                	ld	ra,24(sp)
ffffffffc0200902:	64a2                	ld	s1,8(sp)
ffffffffc0200904:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200906:	2060106f          	j	ffffffffc0201b0c <do_pgfault>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc020090a:	11843703          	ld	a4,280(s0)
ffffffffc020090e:	47bd                	li	a5,15
ffffffffc0200910:	05500613          	li	a2,85
ffffffffc0200914:	05700693          	li	a3,87
ffffffffc0200918:	faf71be3          	bne	a4,a5,ffffffffc02008ce <pgfault_handler+0x36>
ffffffffc020091c:	bf5d                	j	ffffffffc02008d2 <pgfault_handler+0x3a>
        if (current == NULL) {
ffffffffc020091e:	000b2797          	auipc	a5,0xb2
ffffffffc0200922:	1027b783          	ld	a5,258(a5) # ffffffffc02b2a20 <current>
ffffffffc0200926:	cf85                	beqz	a5,ffffffffc020095e <pgfault_handler+0xc6>
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200928:	11043603          	ld	a2,272(s0)
ffffffffc020092c:	11843583          	ld	a1,280(s0)
}
ffffffffc0200930:	6442                	ld	s0,16(sp)
ffffffffc0200932:	60e2                	ld	ra,24(sp)
ffffffffc0200934:	64a2                	ld	s1,8(sp)
        mm = current->mm;
ffffffffc0200936:	7788                	ld	a0,40(a5)
}
ffffffffc0200938:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc020093a:	1d20106f          	j	ffffffffc0201b0c <do_pgfault>
        assert(current == idleproc);
ffffffffc020093e:	00006697          	auipc	a3,0x6
ffffffffc0200942:	34a68693          	addi	a3,a3,842 # ffffffffc0206c88 <commands+0x3f8>
ffffffffc0200946:	00006617          	auipc	a2,0x6
ffffffffc020094a:	35a60613          	addi	a2,a2,858 # ffffffffc0206ca0 <commands+0x410>
ffffffffc020094e:	06b00593          	li	a1,107
ffffffffc0200952:	00006517          	auipc	a0,0x6
ffffffffc0200956:	36650513          	addi	a0,a0,870 # ffffffffc0206cb8 <commands+0x428>
ffffffffc020095a:	8afff0ef          	jal	ra,ffffffffc0200208 <__panic>
            print_trapframe(tf);
ffffffffc020095e:	8522                	mv	a0,s0
ffffffffc0200960:	ed7ff0ef          	jal	ra,ffffffffc0200836 <print_trapframe>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200964:	10043783          	ld	a5,256(s0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200968:	11043583          	ld	a1,272(s0)
ffffffffc020096c:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200970:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200974:	e399                	bnez	a5,ffffffffc020097a <pgfault_handler+0xe2>
ffffffffc0200976:	05500613          	li	a2,85
ffffffffc020097a:	11843703          	ld	a4,280(s0)
ffffffffc020097e:	47bd                	li	a5,15
ffffffffc0200980:	02f70663          	beq	a4,a5,ffffffffc02009ac <pgfault_handler+0x114>
ffffffffc0200984:	05200693          	li	a3,82
ffffffffc0200988:	00006517          	auipc	a0,0x6
ffffffffc020098c:	2e050513          	addi	a0,a0,736 # ffffffffc0206c68 <commands+0x3d8>
ffffffffc0200990:	f3cff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            panic("unhandled page fault.\n");
ffffffffc0200994:	00006617          	auipc	a2,0x6
ffffffffc0200998:	33c60613          	addi	a2,a2,828 # ffffffffc0206cd0 <commands+0x440>
ffffffffc020099c:	07200593          	li	a1,114
ffffffffc02009a0:	00006517          	auipc	a0,0x6
ffffffffc02009a4:	31850513          	addi	a0,a0,792 # ffffffffc0206cb8 <commands+0x428>
ffffffffc02009a8:	861ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02009ac:	05700693          	li	a3,87
ffffffffc02009b0:	bfe1                	j	ffffffffc0200988 <pgfault_handler+0xf0>

ffffffffc02009b2 <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02009b2:	11853783          	ld	a5,280(a0)
ffffffffc02009b6:	472d                	li	a4,11
ffffffffc02009b8:	0786                	slli	a5,a5,0x1
ffffffffc02009ba:	8385                	srli	a5,a5,0x1
ffffffffc02009bc:	08f76363          	bltu	a4,a5,ffffffffc0200a42 <interrupt_handler+0x90>
ffffffffc02009c0:	00006717          	auipc	a4,0x6
ffffffffc02009c4:	3c870713          	addi	a4,a4,968 # ffffffffc0206d88 <commands+0x4f8>
ffffffffc02009c8:	078a                	slli	a5,a5,0x2
ffffffffc02009ca:	97ba                	add	a5,a5,a4
ffffffffc02009cc:	439c                	lw	a5,0(a5)
ffffffffc02009ce:	97ba                	add	a5,a5,a4
ffffffffc02009d0:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02009d2:	00006517          	auipc	a0,0x6
ffffffffc02009d6:	37650513          	addi	a0,a0,886 # ffffffffc0206d48 <commands+0x4b8>
ffffffffc02009da:	ef2ff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02009de:	00006517          	auipc	a0,0x6
ffffffffc02009e2:	34a50513          	addi	a0,a0,842 # ffffffffc0206d28 <commands+0x498>
ffffffffc02009e6:	ee6ff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("User software interrupt\n");
ffffffffc02009ea:	00006517          	auipc	a0,0x6
ffffffffc02009ee:	2fe50513          	addi	a0,a0,766 # ffffffffc0206ce8 <commands+0x458>
ffffffffc02009f2:	edaff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc02009f6:	00006517          	auipc	a0,0x6
ffffffffc02009fa:	31250513          	addi	a0,a0,786 # ffffffffc0206d08 <commands+0x478>
ffffffffc02009fe:	eceff06f          	j	ffffffffc02000cc <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a02:	1141                	addi	sp,sp,-16
ffffffffc0200a04:	e406                	sd	ra,8(sp)
            // "All bits besides SSIP and USIP in the sip register are
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc0200a06:	bafff0ef          	jal	ra,ffffffffc02005b4 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0 && current) {
ffffffffc0200a0a:	000b2697          	auipc	a3,0xb2
ffffffffc0200a0e:	fa668693          	addi	a3,a3,-90 # ffffffffc02b29b0 <ticks>
ffffffffc0200a12:	629c                	ld	a5,0(a3)
ffffffffc0200a14:	06400713          	li	a4,100
ffffffffc0200a18:	0785                	addi	a5,a5,1
ffffffffc0200a1a:	02e7f733          	remu	a4,a5,a4
ffffffffc0200a1e:	e29c                	sd	a5,0(a3)
ffffffffc0200a20:	eb01                	bnez	a4,ffffffffc0200a30 <interrupt_handler+0x7e>
ffffffffc0200a22:	000b2797          	auipc	a5,0xb2
ffffffffc0200a26:	ffe7b783          	ld	a5,-2(a5) # ffffffffc02b2a20 <current>
ffffffffc0200a2a:	c399                	beqz	a5,ffffffffc0200a30 <interrupt_handler+0x7e>
                // print_ticks();
                current->need_resched = 1;
ffffffffc0200a2c:	4705                	li	a4,1
ffffffffc0200a2e:	ef98                	sd	a4,24(a5)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a30:	60a2                	ld	ra,8(sp)
ffffffffc0200a32:	0141                	addi	sp,sp,16
ffffffffc0200a34:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200a36:	00006517          	auipc	a0,0x6
ffffffffc0200a3a:	33250513          	addi	a0,a0,818 # ffffffffc0206d68 <commands+0x4d8>
ffffffffc0200a3e:	e8eff06f          	j	ffffffffc02000cc <cprintf>
            print_trapframe(tf);
ffffffffc0200a42:	bbd5                	j	ffffffffc0200836 <print_trapframe>

ffffffffc0200a44 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf,uintptr_t kstacktop);
void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200a44:	11853783          	ld	a5,280(a0)
void exception_handler(struct trapframe *tf) {
ffffffffc0200a48:	1101                	addi	sp,sp,-32
ffffffffc0200a4a:	e822                	sd	s0,16(sp)
ffffffffc0200a4c:	ec06                	sd	ra,24(sp)
ffffffffc0200a4e:	e426                	sd	s1,8(sp)
ffffffffc0200a50:	473d                	li	a4,15
ffffffffc0200a52:	842a                	mv	s0,a0
ffffffffc0200a54:	18f76563          	bltu	a4,a5,ffffffffc0200bde <exception_handler+0x19a>
ffffffffc0200a58:	00006717          	auipc	a4,0x6
ffffffffc0200a5c:	4f870713          	addi	a4,a4,1272 # ffffffffc0206f50 <commands+0x6c0>
ffffffffc0200a60:	078a                	slli	a5,a5,0x2
ffffffffc0200a62:	97ba                	add	a5,a5,a4
ffffffffc0200a64:	439c                	lw	a5,0(a5)
ffffffffc0200a66:	97ba                	add	a5,a5,a4
ffffffffc0200a68:	8782                	jr	a5
            //cprintf("Environment call from U-mode\n");
            tf->epc += 4;
            syscall();
            break;
        case CAUSE_SUPERVISOR_ECALL:
            cprintf("Environment call from S-mode\n");
ffffffffc0200a6a:	00006517          	auipc	a0,0x6
ffffffffc0200a6e:	43e50513          	addi	a0,a0,1086 # ffffffffc0206ea8 <commands+0x618>
ffffffffc0200a72:	e5aff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            tf->epc += 4;
ffffffffc0200a76:	10843783          	ld	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a7a:	60e2                	ld	ra,24(sp)
ffffffffc0200a7c:	64a2                	ld	s1,8(sp)
            tf->epc += 4;
ffffffffc0200a7e:	0791                	addi	a5,a5,4
ffffffffc0200a80:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200a84:	6442                	ld	s0,16(sp)
ffffffffc0200a86:	6105                	addi	sp,sp,32
            syscall();
ffffffffc0200a88:	6360506f          	j	ffffffffc02060be <syscall>
            cprintf("Environment call from H-mode\n");
ffffffffc0200a8c:	00006517          	auipc	a0,0x6
ffffffffc0200a90:	43c50513          	addi	a0,a0,1084 # ffffffffc0206ec8 <commands+0x638>
}
ffffffffc0200a94:	6442                	ld	s0,16(sp)
ffffffffc0200a96:	60e2                	ld	ra,24(sp)
ffffffffc0200a98:	64a2                	ld	s1,8(sp)
ffffffffc0200a9a:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc0200a9c:	e30ff06f          	j	ffffffffc02000cc <cprintf>
            cprintf("Environment call from M-mode\n");
ffffffffc0200aa0:	00006517          	auipc	a0,0x6
ffffffffc0200aa4:	44850513          	addi	a0,a0,1096 # ffffffffc0206ee8 <commands+0x658>
ffffffffc0200aa8:	b7f5                	j	ffffffffc0200a94 <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200aaa:	00006517          	auipc	a0,0x6
ffffffffc0200aae:	45e50513          	addi	a0,a0,1118 # ffffffffc0206f08 <commands+0x678>
ffffffffc0200ab2:	b7cd                	j	ffffffffc0200a94 <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200ab4:	00006517          	auipc	a0,0x6
ffffffffc0200ab8:	46c50513          	addi	a0,a0,1132 # ffffffffc0206f20 <commands+0x690>
ffffffffc0200abc:	e10ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200ac0:	8522                	mv	a0,s0
ffffffffc0200ac2:	dd7ff0ef          	jal	ra,ffffffffc0200898 <pgfault_handler>
ffffffffc0200ac6:	84aa                	mv	s1,a0
ffffffffc0200ac8:	12051d63          	bnez	a0,ffffffffc0200c02 <exception_handler+0x1be>
}
ffffffffc0200acc:	60e2                	ld	ra,24(sp)
ffffffffc0200ace:	6442                	ld	s0,16(sp)
ffffffffc0200ad0:	64a2                	ld	s1,8(sp)
ffffffffc0200ad2:	6105                	addi	sp,sp,32
ffffffffc0200ad4:	8082                	ret
            cprintf("Store/AMO page fault\n");
ffffffffc0200ad6:	00006517          	auipc	a0,0x6
ffffffffc0200ada:	46250513          	addi	a0,a0,1122 # ffffffffc0206f38 <commands+0x6a8>
ffffffffc0200ade:	deeff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200ae2:	8522                	mv	a0,s0
ffffffffc0200ae4:	db5ff0ef          	jal	ra,ffffffffc0200898 <pgfault_handler>
ffffffffc0200ae8:	84aa                	mv	s1,a0
ffffffffc0200aea:	d16d                	beqz	a0,ffffffffc0200acc <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200aec:	8522                	mv	a0,s0
ffffffffc0200aee:	d49ff0ef          	jal	ra,ffffffffc0200836 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200af2:	86a6                	mv	a3,s1
ffffffffc0200af4:	00006617          	auipc	a2,0x6
ffffffffc0200af8:	36460613          	addi	a2,a2,868 # ffffffffc0206e58 <commands+0x5c8>
ffffffffc0200afc:	0f800593          	li	a1,248
ffffffffc0200b00:	00006517          	auipc	a0,0x6
ffffffffc0200b04:	1b850513          	addi	a0,a0,440 # ffffffffc0206cb8 <commands+0x428>
ffffffffc0200b08:	f00ff0ef          	jal	ra,ffffffffc0200208 <__panic>
            cprintf("Instruction address misaligned\n");
ffffffffc0200b0c:	00006517          	auipc	a0,0x6
ffffffffc0200b10:	2ac50513          	addi	a0,a0,684 # ffffffffc0206db8 <commands+0x528>
ffffffffc0200b14:	b741                	j	ffffffffc0200a94 <exception_handler+0x50>
            cprintf("Instruction access fault\n");
ffffffffc0200b16:	00006517          	auipc	a0,0x6
ffffffffc0200b1a:	2c250513          	addi	a0,a0,706 # ffffffffc0206dd8 <commands+0x548>
ffffffffc0200b1e:	bf9d                	j	ffffffffc0200a94 <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc0200b20:	00006517          	auipc	a0,0x6
ffffffffc0200b24:	2d850513          	addi	a0,a0,728 # ffffffffc0206df8 <commands+0x568>
ffffffffc0200b28:	b7b5                	j	ffffffffc0200a94 <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc0200b2a:	00006517          	auipc	a0,0x6
ffffffffc0200b2e:	2e650513          	addi	a0,a0,742 # ffffffffc0206e10 <commands+0x580>
ffffffffc0200b32:	d9aff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if(tf->gpr.a7 == 10){
ffffffffc0200b36:	6458                	ld	a4,136(s0)
ffffffffc0200b38:	47a9                	li	a5,10
ffffffffc0200b3a:	f8f719e3          	bne	a4,a5,ffffffffc0200acc <exception_handler+0x88>
                tf->epc += 4;
ffffffffc0200b3e:	10843783          	ld	a5,264(s0)
ffffffffc0200b42:	0791                	addi	a5,a5,4
ffffffffc0200b44:	10f43423          	sd	a5,264(s0)
                syscall();
ffffffffc0200b48:	576050ef          	jal	ra,ffffffffc02060be <syscall>
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b4c:	000b2797          	auipc	a5,0xb2
ffffffffc0200b50:	ed47b783          	ld	a5,-300(a5) # ffffffffc02b2a20 <current>
ffffffffc0200b54:	6b9c                	ld	a5,16(a5)
ffffffffc0200b56:	8522                	mv	a0,s0
}
ffffffffc0200b58:	6442                	ld	s0,16(sp)
ffffffffc0200b5a:	60e2                	ld	ra,24(sp)
ffffffffc0200b5c:	64a2                	ld	s1,8(sp)
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b5e:	6589                	lui	a1,0x2
ffffffffc0200b60:	95be                	add	a1,a1,a5
}
ffffffffc0200b62:	6105                	addi	sp,sp,32
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b64:	ac19                	j	ffffffffc0200d7a <kernel_execve_ret>
            cprintf("Load address misaligned\n");
ffffffffc0200b66:	00006517          	auipc	a0,0x6
ffffffffc0200b6a:	2ba50513          	addi	a0,a0,698 # ffffffffc0206e20 <commands+0x590>
ffffffffc0200b6e:	b71d                	j	ffffffffc0200a94 <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc0200b70:	00006517          	auipc	a0,0x6
ffffffffc0200b74:	2d050513          	addi	a0,a0,720 # ffffffffc0206e40 <commands+0x5b0>
ffffffffc0200b78:	d54ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200b7c:	8522                	mv	a0,s0
ffffffffc0200b7e:	d1bff0ef          	jal	ra,ffffffffc0200898 <pgfault_handler>
ffffffffc0200b82:	84aa                	mv	s1,a0
ffffffffc0200b84:	d521                	beqz	a0,ffffffffc0200acc <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200b86:	8522                	mv	a0,s0
ffffffffc0200b88:	cafff0ef          	jal	ra,ffffffffc0200836 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200b8c:	86a6                	mv	a3,s1
ffffffffc0200b8e:	00006617          	auipc	a2,0x6
ffffffffc0200b92:	2ca60613          	addi	a2,a2,714 # ffffffffc0206e58 <commands+0x5c8>
ffffffffc0200b96:	0cd00593          	li	a1,205
ffffffffc0200b9a:	00006517          	auipc	a0,0x6
ffffffffc0200b9e:	11e50513          	addi	a0,a0,286 # ffffffffc0206cb8 <commands+0x428>
ffffffffc0200ba2:	e66ff0ef          	jal	ra,ffffffffc0200208 <__panic>
            cprintf("Store/AMO access fault\n");
ffffffffc0200ba6:	00006517          	auipc	a0,0x6
ffffffffc0200baa:	2ea50513          	addi	a0,a0,746 # ffffffffc0206e90 <commands+0x600>
ffffffffc0200bae:	d1eff0ef          	jal	ra,ffffffffc02000cc <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200bb2:	8522                	mv	a0,s0
ffffffffc0200bb4:	ce5ff0ef          	jal	ra,ffffffffc0200898 <pgfault_handler>
ffffffffc0200bb8:	84aa                	mv	s1,a0
ffffffffc0200bba:	f00509e3          	beqz	a0,ffffffffc0200acc <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200bbe:	8522                	mv	a0,s0
ffffffffc0200bc0:	c77ff0ef          	jal	ra,ffffffffc0200836 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200bc4:	86a6                	mv	a3,s1
ffffffffc0200bc6:	00006617          	auipc	a2,0x6
ffffffffc0200bca:	29260613          	addi	a2,a2,658 # ffffffffc0206e58 <commands+0x5c8>
ffffffffc0200bce:	0d700593          	li	a1,215
ffffffffc0200bd2:	00006517          	auipc	a0,0x6
ffffffffc0200bd6:	0e650513          	addi	a0,a0,230 # ffffffffc0206cb8 <commands+0x428>
ffffffffc0200bda:	e2eff0ef          	jal	ra,ffffffffc0200208 <__panic>
            print_trapframe(tf);
ffffffffc0200bde:	8522                	mv	a0,s0
}
ffffffffc0200be0:	6442                	ld	s0,16(sp)
ffffffffc0200be2:	60e2                	ld	ra,24(sp)
ffffffffc0200be4:	64a2                	ld	s1,8(sp)
ffffffffc0200be6:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200be8:	b1b9                	j	ffffffffc0200836 <print_trapframe>
            panic("AMO address misaligned\n");
ffffffffc0200bea:	00006617          	auipc	a2,0x6
ffffffffc0200bee:	28e60613          	addi	a2,a2,654 # ffffffffc0206e78 <commands+0x5e8>
ffffffffc0200bf2:	0d100593          	li	a1,209
ffffffffc0200bf6:	00006517          	auipc	a0,0x6
ffffffffc0200bfa:	0c250513          	addi	a0,a0,194 # ffffffffc0206cb8 <commands+0x428>
ffffffffc0200bfe:	e0aff0ef          	jal	ra,ffffffffc0200208 <__panic>
                print_trapframe(tf);
ffffffffc0200c02:	8522                	mv	a0,s0
ffffffffc0200c04:	c33ff0ef          	jal	ra,ffffffffc0200836 <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200c08:	86a6                	mv	a3,s1
ffffffffc0200c0a:	00006617          	auipc	a2,0x6
ffffffffc0200c0e:	24e60613          	addi	a2,a2,590 # ffffffffc0206e58 <commands+0x5c8>
ffffffffc0200c12:	0f100593          	li	a1,241
ffffffffc0200c16:	00006517          	auipc	a0,0x6
ffffffffc0200c1a:	0a250513          	addi	a0,a0,162 # ffffffffc0206cb8 <commands+0x428>
ffffffffc0200c1e:	deaff0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0200c22 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
ffffffffc0200c22:	1101                	addi	sp,sp,-32
ffffffffc0200c24:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
//    cputs("some trap");
    if (current == NULL) {
ffffffffc0200c26:	000b2417          	auipc	s0,0xb2
ffffffffc0200c2a:	dfa40413          	addi	s0,s0,-518 # ffffffffc02b2a20 <current>
ffffffffc0200c2e:	6018                	ld	a4,0(s0)
trap(struct trapframe *tf) {
ffffffffc0200c30:	ec06                	sd	ra,24(sp)
ffffffffc0200c32:	e426                	sd	s1,8(sp)
ffffffffc0200c34:	e04a                	sd	s2,0(sp)
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c36:	11853683          	ld	a3,280(a0)
    if (current == NULL) {
ffffffffc0200c3a:	cf1d                	beqz	a4,ffffffffc0200c78 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c3c:	10053483          	ld	s1,256(a0)
        trap_dispatch(tf);
    } else {
        struct trapframe *otf = current->tf;
ffffffffc0200c40:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200c44:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c46:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c4a:	0206c463          	bltz	a3,ffffffffc0200c72 <trap+0x50>
        exception_handler(tf);
ffffffffc0200c4e:	df7ff0ef          	jal	ra,ffffffffc0200a44 <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200c52:	601c                	ld	a5,0(s0)
ffffffffc0200c54:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel) {
ffffffffc0200c58:	e499                	bnez	s1,ffffffffc0200c66 <trap+0x44>
            if (current->flags & PF_EXITING) {
ffffffffc0200c5a:	0b07a703          	lw	a4,176(a5)
ffffffffc0200c5e:	8b05                	andi	a4,a4,1
ffffffffc0200c60:	e329                	bnez	a4,ffffffffc0200ca2 <trap+0x80>
                do_exit(-E_KILLED);
            }
            if (current->need_resched) {
ffffffffc0200c62:	6f9c                	ld	a5,24(a5)
ffffffffc0200c64:	eb85                	bnez	a5,ffffffffc0200c94 <trap+0x72>
                schedule();
            }
        }
    }
}
ffffffffc0200c66:	60e2                	ld	ra,24(sp)
ffffffffc0200c68:	6442                	ld	s0,16(sp)
ffffffffc0200c6a:	64a2                	ld	s1,8(sp)
ffffffffc0200c6c:	6902                	ld	s2,0(sp)
ffffffffc0200c6e:	6105                	addi	sp,sp,32
ffffffffc0200c70:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200c72:	d41ff0ef          	jal	ra,ffffffffc02009b2 <interrupt_handler>
ffffffffc0200c76:	bff1                	j	ffffffffc0200c52 <trap+0x30>
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c78:	0006c863          	bltz	a3,ffffffffc0200c88 <trap+0x66>
}
ffffffffc0200c7c:	6442                	ld	s0,16(sp)
ffffffffc0200c7e:	60e2                	ld	ra,24(sp)
ffffffffc0200c80:	64a2                	ld	s1,8(sp)
ffffffffc0200c82:	6902                	ld	s2,0(sp)
ffffffffc0200c84:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200c86:	bb7d                	j	ffffffffc0200a44 <exception_handler>
}
ffffffffc0200c88:	6442                	ld	s0,16(sp)
ffffffffc0200c8a:	60e2                	ld	ra,24(sp)
ffffffffc0200c8c:	64a2                	ld	s1,8(sp)
ffffffffc0200c8e:	6902                	ld	s2,0(sp)
ffffffffc0200c90:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200c92:	b305                	j	ffffffffc02009b2 <interrupt_handler>
}
ffffffffc0200c94:	6442                	ld	s0,16(sp)
ffffffffc0200c96:	60e2                	ld	ra,24(sp)
ffffffffc0200c98:	64a2                	ld	s1,8(sp)
ffffffffc0200c9a:	6902                	ld	s2,0(sp)
ffffffffc0200c9c:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200c9e:	3340506f          	j	ffffffffc0205fd2 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200ca2:	555d                	li	a0,-9
ffffffffc0200ca4:	6e2040ef          	jal	ra,ffffffffc0205386 <do_exit>
            if (current->need_resched) {
ffffffffc0200ca8:	601c                	ld	a5,0(s0)
ffffffffc0200caa:	bf65                	j	ffffffffc0200c62 <trap+0x40>

ffffffffc0200cac <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200cac:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200cb0:	00011463          	bnez	sp,ffffffffc0200cb8 <__alltraps+0xc>
ffffffffc0200cb4:	14002173          	csrr	sp,sscratch
ffffffffc0200cb8:	712d                	addi	sp,sp,-288
ffffffffc0200cba:	e002                	sd	zero,0(sp)
ffffffffc0200cbc:	e406                	sd	ra,8(sp)
ffffffffc0200cbe:	ec0e                	sd	gp,24(sp)
ffffffffc0200cc0:	f012                	sd	tp,32(sp)
ffffffffc0200cc2:	f416                	sd	t0,40(sp)
ffffffffc0200cc4:	f81a                	sd	t1,48(sp)
ffffffffc0200cc6:	fc1e                	sd	t2,56(sp)
ffffffffc0200cc8:	e0a2                	sd	s0,64(sp)
ffffffffc0200cca:	e4a6                	sd	s1,72(sp)
ffffffffc0200ccc:	e8aa                	sd	a0,80(sp)
ffffffffc0200cce:	ecae                	sd	a1,88(sp)
ffffffffc0200cd0:	f0b2                	sd	a2,96(sp)
ffffffffc0200cd2:	f4b6                	sd	a3,104(sp)
ffffffffc0200cd4:	f8ba                	sd	a4,112(sp)
ffffffffc0200cd6:	fcbe                	sd	a5,120(sp)
ffffffffc0200cd8:	e142                	sd	a6,128(sp)
ffffffffc0200cda:	e546                	sd	a7,136(sp)
ffffffffc0200cdc:	e94a                	sd	s2,144(sp)
ffffffffc0200cde:	ed4e                	sd	s3,152(sp)
ffffffffc0200ce0:	f152                	sd	s4,160(sp)
ffffffffc0200ce2:	f556                	sd	s5,168(sp)
ffffffffc0200ce4:	f95a                	sd	s6,176(sp)
ffffffffc0200ce6:	fd5e                	sd	s7,184(sp)
ffffffffc0200ce8:	e1e2                	sd	s8,192(sp)
ffffffffc0200cea:	e5e6                	sd	s9,200(sp)
ffffffffc0200cec:	e9ea                	sd	s10,208(sp)
ffffffffc0200cee:	edee                	sd	s11,216(sp)
ffffffffc0200cf0:	f1f2                	sd	t3,224(sp)
ffffffffc0200cf2:	f5f6                	sd	t4,232(sp)
ffffffffc0200cf4:	f9fa                	sd	t5,240(sp)
ffffffffc0200cf6:	fdfe                	sd	t6,248(sp)
ffffffffc0200cf8:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200cfc:	100024f3          	csrr	s1,sstatus
ffffffffc0200d00:	14102973          	csrr	s2,sepc
ffffffffc0200d04:	143029f3          	csrr	s3,stval
ffffffffc0200d08:	14202a73          	csrr	s4,scause
ffffffffc0200d0c:	e822                	sd	s0,16(sp)
ffffffffc0200d0e:	e226                	sd	s1,256(sp)
ffffffffc0200d10:	e64a                	sd	s2,264(sp)
ffffffffc0200d12:	ea4e                	sd	s3,272(sp)
ffffffffc0200d14:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d16:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d18:	f0bff0ef          	jal	ra,ffffffffc0200c22 <trap>

ffffffffc0200d1c <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d1c:	6492                	ld	s1,256(sp)
ffffffffc0200d1e:	6932                	ld	s2,264(sp)
ffffffffc0200d20:	1004f413          	andi	s0,s1,256
ffffffffc0200d24:	e401                	bnez	s0,ffffffffc0200d2c <__trapret+0x10>
ffffffffc0200d26:	1200                	addi	s0,sp,288
ffffffffc0200d28:	14041073          	csrw	sscratch,s0
ffffffffc0200d2c:	10049073          	csrw	sstatus,s1
ffffffffc0200d30:	14191073          	csrw	sepc,s2
ffffffffc0200d34:	60a2                	ld	ra,8(sp)
ffffffffc0200d36:	61e2                	ld	gp,24(sp)
ffffffffc0200d38:	7202                	ld	tp,32(sp)
ffffffffc0200d3a:	72a2                	ld	t0,40(sp)
ffffffffc0200d3c:	7342                	ld	t1,48(sp)
ffffffffc0200d3e:	73e2                	ld	t2,56(sp)
ffffffffc0200d40:	6406                	ld	s0,64(sp)
ffffffffc0200d42:	64a6                	ld	s1,72(sp)
ffffffffc0200d44:	6546                	ld	a0,80(sp)
ffffffffc0200d46:	65e6                	ld	a1,88(sp)
ffffffffc0200d48:	7606                	ld	a2,96(sp)
ffffffffc0200d4a:	76a6                	ld	a3,104(sp)
ffffffffc0200d4c:	7746                	ld	a4,112(sp)
ffffffffc0200d4e:	77e6                	ld	a5,120(sp)
ffffffffc0200d50:	680a                	ld	a6,128(sp)
ffffffffc0200d52:	68aa                	ld	a7,136(sp)
ffffffffc0200d54:	694a                	ld	s2,144(sp)
ffffffffc0200d56:	69ea                	ld	s3,152(sp)
ffffffffc0200d58:	7a0a                	ld	s4,160(sp)
ffffffffc0200d5a:	7aaa                	ld	s5,168(sp)
ffffffffc0200d5c:	7b4a                	ld	s6,176(sp)
ffffffffc0200d5e:	7bea                	ld	s7,184(sp)
ffffffffc0200d60:	6c0e                	ld	s8,192(sp)
ffffffffc0200d62:	6cae                	ld	s9,200(sp)
ffffffffc0200d64:	6d4e                	ld	s10,208(sp)
ffffffffc0200d66:	6dee                	ld	s11,216(sp)
ffffffffc0200d68:	7e0e                	ld	t3,224(sp)
ffffffffc0200d6a:	7eae                	ld	t4,232(sp)
ffffffffc0200d6c:	7f4e                	ld	t5,240(sp)
ffffffffc0200d6e:	7fee                	ld	t6,248(sp)
ffffffffc0200d70:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200d72:	10200073          	sret

ffffffffc0200d76 <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200d76:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200d78:	b755                	j	ffffffffc0200d1c <__trapret>

ffffffffc0200d7a <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200d7a:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cf0>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200d7e:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200d82:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200d86:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200d8a:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200d8e:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200d92:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200d96:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200d9a:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200d9e:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200da0:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200da2:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200da4:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200da6:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200da8:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200daa:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200dac:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200dae:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200db0:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200db2:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200db4:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200db6:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200db8:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200dba:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200dbc:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200dbe:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200dc0:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200dc2:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200dc4:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200dc6:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200dc8:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200dca:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200dcc:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200dce:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200dd0:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200dd2:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200dd4:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200dd6:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200dd8:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200dda:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200ddc:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200dde:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200de0:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200de2:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200de4:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200de6:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200de8:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200dea:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200dec:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200dee:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200df0:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200df2:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200df4:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200df6:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200df8:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200dfa:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200dfc:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200dfe:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200e00:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200e02:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200e04:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200e06:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200e08:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200e0a:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200e0c:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200e0e:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200e10:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200e12:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200e14:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200e16:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200e18:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200e1a:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200e1c:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200e1e:	812e                	mv	sp,a1
ffffffffc0200e20:	bdf5                	j	ffffffffc0200d1c <__trapret>

ffffffffc0200e22 <_fifo_init_mm>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200e22:	000ae797          	auipc	a5,0xae
ffffffffc0200e26:	abe78793          	addi	a5,a5,-1346 # ffffffffc02ae8e0 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
ffffffffc0200e2a:	f51c                	sd	a5,40(a0)
ffffffffc0200e2c:	e79c                	sd	a5,8(a5)
ffffffffc0200e2e:	e39c                	sd	a5,0(a5)
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc0200e30:	4501                	li	a0,0
ffffffffc0200e32:	8082                	ret

ffffffffc0200e34 <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0200e34:	4501                	li	a0,0
ffffffffc0200e36:	8082                	ret

ffffffffc0200e38 <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0200e38:	4501                	li	a0,0
ffffffffc0200e3a:	8082                	ret

ffffffffc0200e3c <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc0200e3c:	4501                	li	a0,0
ffffffffc0200e3e:	8082                	ret

ffffffffc0200e40 <_fifo_check_swap>:
_fifo_check_swap(void) {
ffffffffc0200e40:	711d                	addi	sp,sp,-96
ffffffffc0200e42:	fc4e                	sd	s3,56(sp)
ffffffffc0200e44:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0200e46:	00006517          	auipc	a0,0x6
ffffffffc0200e4a:	14a50513          	addi	a0,a0,330 # ffffffffc0206f90 <commands+0x700>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0200e4e:	698d                	lui	s3,0x3
ffffffffc0200e50:	4a31                	li	s4,12
_fifo_check_swap(void) {
ffffffffc0200e52:	e0ca                	sd	s2,64(sp)
ffffffffc0200e54:	ec86                	sd	ra,88(sp)
ffffffffc0200e56:	e8a2                	sd	s0,80(sp)
ffffffffc0200e58:	e4a6                	sd	s1,72(sp)
ffffffffc0200e5a:	f456                	sd	s5,40(sp)
ffffffffc0200e5c:	f05a                	sd	s6,32(sp)
ffffffffc0200e5e:	ec5e                	sd	s7,24(sp)
ffffffffc0200e60:	e862                	sd	s8,16(sp)
ffffffffc0200e62:	e466                	sd	s9,8(sp)
ffffffffc0200e64:	e06a                	sd	s10,0(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0200e66:	a66ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0200e6a:	01498023          	sb	s4,0(s3) # 3000 <_binary_obj___user_faultread_out_size-0x6bd0>
    assert(pgfault_num==4);
ffffffffc0200e6e:	000b2917          	auipc	s2,0xb2
ffffffffc0200e72:	b5a92903          	lw	s2,-1190(s2) # ffffffffc02b29c8 <pgfault_num>
ffffffffc0200e76:	4791                	li	a5,4
ffffffffc0200e78:	14f91e63          	bne	s2,a5,ffffffffc0200fd4 <_fifo_check_swap+0x194>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0200e7c:	00006517          	auipc	a0,0x6
ffffffffc0200e80:	16450513          	addi	a0,a0,356 # ffffffffc0206fe0 <commands+0x750>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0200e84:	6a85                	lui	s5,0x1
ffffffffc0200e86:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0200e88:	a44ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0200e8c:	000b2417          	auipc	s0,0xb2
ffffffffc0200e90:	b3c40413          	addi	s0,s0,-1220 # ffffffffc02b29c8 <pgfault_num>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0200e94:	016a8023          	sb	s6,0(s5) # 1000 <_binary_obj___user_faultread_out_size-0x8bd0>
    assert(pgfault_num==4);
ffffffffc0200e98:	4004                	lw	s1,0(s0)
ffffffffc0200e9a:	2481                	sext.w	s1,s1
ffffffffc0200e9c:	2b249c63          	bne	s1,s2,ffffffffc0201154 <_fifo_check_swap+0x314>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0200ea0:	00006517          	auipc	a0,0x6
ffffffffc0200ea4:	16850513          	addi	a0,a0,360 # ffffffffc0207008 <commands+0x778>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0200ea8:	6b91                	lui	s7,0x4
ffffffffc0200eaa:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0200eac:	a20ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0200eb0:	018b8023          	sb	s8,0(s7) # 4000 <_binary_obj___user_faultread_out_size-0x5bd0>
    assert(pgfault_num==4);
ffffffffc0200eb4:	00042903          	lw	s2,0(s0)
ffffffffc0200eb8:	2901                	sext.w	s2,s2
ffffffffc0200eba:	26991d63          	bne	s2,s1,ffffffffc0201134 <_fifo_check_swap+0x2f4>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0200ebe:	00006517          	auipc	a0,0x6
ffffffffc0200ec2:	17250513          	addi	a0,a0,370 # ffffffffc0207030 <commands+0x7a0>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0200ec6:	6c89                	lui	s9,0x2
ffffffffc0200ec8:	4d2d                	li	s10,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0200eca:	a02ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0200ece:	01ac8023          	sb	s10,0(s9) # 2000 <_binary_obj___user_faultread_out_size-0x7bd0>
    assert(pgfault_num==4);
ffffffffc0200ed2:	401c                	lw	a5,0(s0)
ffffffffc0200ed4:	2781                	sext.w	a5,a5
ffffffffc0200ed6:	23279f63          	bne	a5,s2,ffffffffc0201114 <_fifo_check_swap+0x2d4>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0200eda:	00006517          	auipc	a0,0x6
ffffffffc0200ede:	17e50513          	addi	a0,a0,382 # ffffffffc0207058 <commands+0x7c8>
ffffffffc0200ee2:	9eaff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0200ee6:	6795                	lui	a5,0x5
ffffffffc0200ee8:	4739                	li	a4,14
ffffffffc0200eea:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4bd0>
    assert(pgfault_num==5);
ffffffffc0200eee:	4004                	lw	s1,0(s0)
ffffffffc0200ef0:	4795                	li	a5,5
ffffffffc0200ef2:	2481                	sext.w	s1,s1
ffffffffc0200ef4:	20f49063          	bne	s1,a5,ffffffffc02010f4 <_fifo_check_swap+0x2b4>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0200ef8:	00006517          	auipc	a0,0x6
ffffffffc0200efc:	13850513          	addi	a0,a0,312 # ffffffffc0207030 <commands+0x7a0>
ffffffffc0200f00:	9ccff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0200f04:	01ac8023          	sb	s10,0(s9)
    assert(pgfault_num==5);
ffffffffc0200f08:	401c                	lw	a5,0(s0)
ffffffffc0200f0a:	2781                	sext.w	a5,a5
ffffffffc0200f0c:	1c979463          	bne	a5,s1,ffffffffc02010d4 <_fifo_check_swap+0x294>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0200f10:	00006517          	auipc	a0,0x6
ffffffffc0200f14:	0d050513          	addi	a0,a0,208 # ffffffffc0206fe0 <commands+0x750>
ffffffffc0200f18:	9b4ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0200f1c:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num==6);
ffffffffc0200f20:	401c                	lw	a5,0(s0)
ffffffffc0200f22:	4719                	li	a4,6
ffffffffc0200f24:	2781                	sext.w	a5,a5
ffffffffc0200f26:	18e79763          	bne	a5,a4,ffffffffc02010b4 <_fifo_check_swap+0x274>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0200f2a:	00006517          	auipc	a0,0x6
ffffffffc0200f2e:	10650513          	addi	a0,a0,262 # ffffffffc0207030 <commands+0x7a0>
ffffffffc0200f32:	99aff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0200f36:	01ac8023          	sb	s10,0(s9)
    assert(pgfault_num==7);
ffffffffc0200f3a:	401c                	lw	a5,0(s0)
ffffffffc0200f3c:	471d                	li	a4,7
ffffffffc0200f3e:	2781                	sext.w	a5,a5
ffffffffc0200f40:	14e79a63          	bne	a5,a4,ffffffffc0201094 <_fifo_check_swap+0x254>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0200f44:	00006517          	auipc	a0,0x6
ffffffffc0200f48:	04c50513          	addi	a0,a0,76 # ffffffffc0206f90 <commands+0x700>
ffffffffc0200f4c:	980ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0200f50:	01498023          	sb	s4,0(s3)
    assert(pgfault_num==8);
ffffffffc0200f54:	401c                	lw	a5,0(s0)
ffffffffc0200f56:	4721                	li	a4,8
ffffffffc0200f58:	2781                	sext.w	a5,a5
ffffffffc0200f5a:	10e79d63          	bne	a5,a4,ffffffffc0201074 <_fifo_check_swap+0x234>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0200f5e:	00006517          	auipc	a0,0x6
ffffffffc0200f62:	0aa50513          	addi	a0,a0,170 # ffffffffc0207008 <commands+0x778>
ffffffffc0200f66:	966ff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0200f6a:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num==9);
ffffffffc0200f6e:	401c                	lw	a5,0(s0)
ffffffffc0200f70:	4725                	li	a4,9
ffffffffc0200f72:	2781                	sext.w	a5,a5
ffffffffc0200f74:	0ee79063          	bne	a5,a4,ffffffffc0201054 <_fifo_check_swap+0x214>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0200f78:	00006517          	auipc	a0,0x6
ffffffffc0200f7c:	0e050513          	addi	a0,a0,224 # ffffffffc0207058 <commands+0x7c8>
ffffffffc0200f80:	94cff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0200f84:	6795                	lui	a5,0x5
ffffffffc0200f86:	4739                	li	a4,14
ffffffffc0200f88:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4bd0>
    assert(pgfault_num==10);
ffffffffc0200f8c:	4004                	lw	s1,0(s0)
ffffffffc0200f8e:	47a9                	li	a5,10
ffffffffc0200f90:	2481                	sext.w	s1,s1
ffffffffc0200f92:	0af49163          	bne	s1,a5,ffffffffc0201034 <_fifo_check_swap+0x1f4>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0200f96:	00006517          	auipc	a0,0x6
ffffffffc0200f9a:	04a50513          	addi	a0,a0,74 # ffffffffc0206fe0 <commands+0x750>
ffffffffc0200f9e:	92eff0ef          	jal	ra,ffffffffc02000cc <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0200fa2:	6785                	lui	a5,0x1
ffffffffc0200fa4:	0007c783          	lbu	a5,0(a5) # 1000 <_binary_obj___user_faultread_out_size-0x8bd0>
ffffffffc0200fa8:	06979663          	bne	a5,s1,ffffffffc0201014 <_fifo_check_swap+0x1d4>
    assert(pgfault_num==11);
ffffffffc0200fac:	401c                	lw	a5,0(s0)
ffffffffc0200fae:	472d                	li	a4,11
ffffffffc0200fb0:	2781                	sext.w	a5,a5
ffffffffc0200fb2:	04e79163          	bne	a5,a4,ffffffffc0200ff4 <_fifo_check_swap+0x1b4>
}
ffffffffc0200fb6:	60e6                	ld	ra,88(sp)
ffffffffc0200fb8:	6446                	ld	s0,80(sp)
ffffffffc0200fba:	64a6                	ld	s1,72(sp)
ffffffffc0200fbc:	6906                	ld	s2,64(sp)
ffffffffc0200fbe:	79e2                	ld	s3,56(sp)
ffffffffc0200fc0:	7a42                	ld	s4,48(sp)
ffffffffc0200fc2:	7aa2                	ld	s5,40(sp)
ffffffffc0200fc4:	7b02                	ld	s6,32(sp)
ffffffffc0200fc6:	6be2                	ld	s7,24(sp)
ffffffffc0200fc8:	6c42                	ld	s8,16(sp)
ffffffffc0200fca:	6ca2                	ld	s9,8(sp)
ffffffffc0200fcc:	6d02                	ld	s10,0(sp)
ffffffffc0200fce:	4501                	li	a0,0
ffffffffc0200fd0:	6125                	addi	sp,sp,96
ffffffffc0200fd2:	8082                	ret
    assert(pgfault_num==4);
ffffffffc0200fd4:	00006697          	auipc	a3,0x6
ffffffffc0200fd8:	fe468693          	addi	a3,a3,-28 # ffffffffc0206fb8 <commands+0x728>
ffffffffc0200fdc:	00006617          	auipc	a2,0x6
ffffffffc0200fe0:	cc460613          	addi	a2,a2,-828 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0200fe4:	05100593          	li	a1,81
ffffffffc0200fe8:	00006517          	auipc	a0,0x6
ffffffffc0200fec:	fe050513          	addi	a0,a0,-32 # ffffffffc0206fc8 <commands+0x738>
ffffffffc0200ff0:	a18ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==11);
ffffffffc0200ff4:	00006697          	auipc	a3,0x6
ffffffffc0200ff8:	11468693          	addi	a3,a3,276 # ffffffffc0207108 <commands+0x878>
ffffffffc0200ffc:	00006617          	auipc	a2,0x6
ffffffffc0201000:	ca460613          	addi	a2,a2,-860 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201004:	07300593          	li	a1,115
ffffffffc0201008:	00006517          	auipc	a0,0x6
ffffffffc020100c:	fc050513          	addi	a0,a0,-64 # ffffffffc0206fc8 <commands+0x738>
ffffffffc0201010:	9f8ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0201014:	00006697          	auipc	a3,0x6
ffffffffc0201018:	0cc68693          	addi	a3,a3,204 # ffffffffc02070e0 <commands+0x850>
ffffffffc020101c:	00006617          	auipc	a2,0x6
ffffffffc0201020:	c8460613          	addi	a2,a2,-892 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201024:	07100593          	li	a1,113
ffffffffc0201028:	00006517          	auipc	a0,0x6
ffffffffc020102c:	fa050513          	addi	a0,a0,-96 # ffffffffc0206fc8 <commands+0x738>
ffffffffc0201030:	9d8ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==10);
ffffffffc0201034:	00006697          	auipc	a3,0x6
ffffffffc0201038:	09c68693          	addi	a3,a3,156 # ffffffffc02070d0 <commands+0x840>
ffffffffc020103c:	00006617          	auipc	a2,0x6
ffffffffc0201040:	c6460613          	addi	a2,a2,-924 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201044:	06f00593          	li	a1,111
ffffffffc0201048:	00006517          	auipc	a0,0x6
ffffffffc020104c:	f8050513          	addi	a0,a0,-128 # ffffffffc0206fc8 <commands+0x738>
ffffffffc0201050:	9b8ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==9);
ffffffffc0201054:	00006697          	auipc	a3,0x6
ffffffffc0201058:	06c68693          	addi	a3,a3,108 # ffffffffc02070c0 <commands+0x830>
ffffffffc020105c:	00006617          	auipc	a2,0x6
ffffffffc0201060:	c4460613          	addi	a2,a2,-956 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201064:	06c00593          	li	a1,108
ffffffffc0201068:	00006517          	auipc	a0,0x6
ffffffffc020106c:	f6050513          	addi	a0,a0,-160 # ffffffffc0206fc8 <commands+0x738>
ffffffffc0201070:	998ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==8);
ffffffffc0201074:	00006697          	auipc	a3,0x6
ffffffffc0201078:	03c68693          	addi	a3,a3,60 # ffffffffc02070b0 <commands+0x820>
ffffffffc020107c:	00006617          	auipc	a2,0x6
ffffffffc0201080:	c2460613          	addi	a2,a2,-988 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201084:	06900593          	li	a1,105
ffffffffc0201088:	00006517          	auipc	a0,0x6
ffffffffc020108c:	f4050513          	addi	a0,a0,-192 # ffffffffc0206fc8 <commands+0x738>
ffffffffc0201090:	978ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==7);
ffffffffc0201094:	00006697          	auipc	a3,0x6
ffffffffc0201098:	00c68693          	addi	a3,a3,12 # ffffffffc02070a0 <commands+0x810>
ffffffffc020109c:	00006617          	auipc	a2,0x6
ffffffffc02010a0:	c0460613          	addi	a2,a2,-1020 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02010a4:	06600593          	li	a1,102
ffffffffc02010a8:	00006517          	auipc	a0,0x6
ffffffffc02010ac:	f2050513          	addi	a0,a0,-224 # ffffffffc0206fc8 <commands+0x738>
ffffffffc02010b0:	958ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==6);
ffffffffc02010b4:	00006697          	auipc	a3,0x6
ffffffffc02010b8:	fdc68693          	addi	a3,a3,-36 # ffffffffc0207090 <commands+0x800>
ffffffffc02010bc:	00006617          	auipc	a2,0x6
ffffffffc02010c0:	be460613          	addi	a2,a2,-1052 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02010c4:	06300593          	li	a1,99
ffffffffc02010c8:	00006517          	auipc	a0,0x6
ffffffffc02010cc:	f0050513          	addi	a0,a0,-256 # ffffffffc0206fc8 <commands+0x738>
ffffffffc02010d0:	938ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==5);
ffffffffc02010d4:	00006697          	auipc	a3,0x6
ffffffffc02010d8:	fac68693          	addi	a3,a3,-84 # ffffffffc0207080 <commands+0x7f0>
ffffffffc02010dc:	00006617          	auipc	a2,0x6
ffffffffc02010e0:	bc460613          	addi	a2,a2,-1084 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02010e4:	06000593          	li	a1,96
ffffffffc02010e8:	00006517          	auipc	a0,0x6
ffffffffc02010ec:	ee050513          	addi	a0,a0,-288 # ffffffffc0206fc8 <commands+0x738>
ffffffffc02010f0:	918ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==5);
ffffffffc02010f4:	00006697          	auipc	a3,0x6
ffffffffc02010f8:	f8c68693          	addi	a3,a3,-116 # ffffffffc0207080 <commands+0x7f0>
ffffffffc02010fc:	00006617          	auipc	a2,0x6
ffffffffc0201100:	ba460613          	addi	a2,a2,-1116 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201104:	05d00593          	li	a1,93
ffffffffc0201108:	00006517          	auipc	a0,0x6
ffffffffc020110c:	ec050513          	addi	a0,a0,-320 # ffffffffc0206fc8 <commands+0x738>
ffffffffc0201110:	8f8ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==4);
ffffffffc0201114:	00006697          	auipc	a3,0x6
ffffffffc0201118:	ea468693          	addi	a3,a3,-348 # ffffffffc0206fb8 <commands+0x728>
ffffffffc020111c:	00006617          	auipc	a2,0x6
ffffffffc0201120:	b8460613          	addi	a2,a2,-1148 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201124:	05a00593          	li	a1,90
ffffffffc0201128:	00006517          	auipc	a0,0x6
ffffffffc020112c:	ea050513          	addi	a0,a0,-352 # ffffffffc0206fc8 <commands+0x738>
ffffffffc0201130:	8d8ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==4);
ffffffffc0201134:	00006697          	auipc	a3,0x6
ffffffffc0201138:	e8468693          	addi	a3,a3,-380 # ffffffffc0206fb8 <commands+0x728>
ffffffffc020113c:	00006617          	auipc	a2,0x6
ffffffffc0201140:	b6460613          	addi	a2,a2,-1180 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201144:	05700593          	li	a1,87
ffffffffc0201148:	00006517          	auipc	a0,0x6
ffffffffc020114c:	e8050513          	addi	a0,a0,-384 # ffffffffc0206fc8 <commands+0x738>
ffffffffc0201150:	8b8ff0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgfault_num==4);
ffffffffc0201154:	00006697          	auipc	a3,0x6
ffffffffc0201158:	e6468693          	addi	a3,a3,-412 # ffffffffc0206fb8 <commands+0x728>
ffffffffc020115c:	00006617          	auipc	a2,0x6
ffffffffc0201160:	b4460613          	addi	a2,a2,-1212 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201164:	05400593          	li	a1,84
ffffffffc0201168:	00006517          	auipc	a0,0x6
ffffffffc020116c:	e6050513          	addi	a0,a0,-416 # ffffffffc0206fc8 <commands+0x738>
ffffffffc0201170:	898ff0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0201174 <_fifo_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc0201174:	751c                	ld	a5,40(a0)
{
ffffffffc0201176:	1141                	addi	sp,sp,-16
ffffffffc0201178:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc020117a:	cf91                	beqz	a5,ffffffffc0201196 <_fifo_swap_out_victim+0x22>
     assert(in_tick==0);
ffffffffc020117c:	ee0d                	bnez	a2,ffffffffc02011b6 <_fifo_swap_out_victim+0x42>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc020117e:	679c                	ld	a5,8(a5)
}
ffffffffc0201180:	60a2                	ld	ra,8(sp)
ffffffffc0201182:	4501                	li	a0,0
    __list_del(listelm->prev, listelm->next);
ffffffffc0201184:	6394                	ld	a3,0(a5)
ffffffffc0201186:	6798                	ld	a4,8(a5)
    *ptr_page = le2page(entry, pra_page_link);
ffffffffc0201188:	fd878793          	addi	a5,a5,-40
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020118c:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc020118e:	e314                	sd	a3,0(a4)
ffffffffc0201190:	e19c                	sd	a5,0(a1)
}
ffffffffc0201192:	0141                	addi	sp,sp,16
ffffffffc0201194:	8082                	ret
         assert(head != NULL);
ffffffffc0201196:	00006697          	auipc	a3,0x6
ffffffffc020119a:	f8268693          	addi	a3,a3,-126 # ffffffffc0207118 <commands+0x888>
ffffffffc020119e:	00006617          	auipc	a2,0x6
ffffffffc02011a2:	b0260613          	addi	a2,a2,-1278 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02011a6:	04100593          	li	a1,65
ffffffffc02011aa:	00006517          	auipc	a0,0x6
ffffffffc02011ae:	e1e50513          	addi	a0,a0,-482 # ffffffffc0206fc8 <commands+0x738>
ffffffffc02011b2:	856ff0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(in_tick==0);
ffffffffc02011b6:	00006697          	auipc	a3,0x6
ffffffffc02011ba:	f7268693          	addi	a3,a3,-142 # ffffffffc0207128 <commands+0x898>
ffffffffc02011be:	00006617          	auipc	a2,0x6
ffffffffc02011c2:	ae260613          	addi	a2,a2,-1310 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02011c6:	04200593          	li	a1,66
ffffffffc02011ca:	00006517          	auipc	a0,0x6
ffffffffc02011ce:	dfe50513          	addi	a0,a0,-514 # ffffffffc0206fc8 <commands+0x738>
ffffffffc02011d2:	836ff0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02011d6 <_fifo_map_swappable>:
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc02011d6:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc02011d8:	cb91                	beqz	a5,ffffffffc02011ec <_fifo_map_swappable+0x16>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02011da:	6394                	ld	a3,0(a5)
ffffffffc02011dc:	02860713          	addi	a4,a2,40
    prev->next = next->prev = elm;
ffffffffc02011e0:	e398                	sd	a4,0(a5)
ffffffffc02011e2:	e698                	sd	a4,8(a3)
}
ffffffffc02011e4:	4501                	li	a0,0
    elm->next = next;
ffffffffc02011e6:	fa1c                	sd	a5,48(a2)
    elm->prev = prev;
ffffffffc02011e8:	f614                	sd	a3,40(a2)
ffffffffc02011ea:	8082                	ret
{
ffffffffc02011ec:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc02011ee:	00006697          	auipc	a3,0x6
ffffffffc02011f2:	f4a68693          	addi	a3,a3,-182 # ffffffffc0207138 <commands+0x8a8>
ffffffffc02011f6:	00006617          	auipc	a2,0x6
ffffffffc02011fa:	aaa60613          	addi	a2,a2,-1366 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02011fe:	03200593          	li	a1,50
ffffffffc0201202:	00006517          	auipc	a0,0x6
ffffffffc0201206:	dc650513          	addi	a0,a0,-570 # ffffffffc0206fc8 <commands+0x738>
{
ffffffffc020120a:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc020120c:	ffdfe0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0201210 <check_vma_overlap.part.0>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0201210:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0201212:	00006697          	auipc	a3,0x6
ffffffffc0201216:	f5e68693          	addi	a3,a3,-162 # ffffffffc0207170 <commands+0x8e0>
ffffffffc020121a:	00006617          	auipc	a2,0x6
ffffffffc020121e:	a8660613          	addi	a2,a2,-1402 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201222:	06e00593          	li	a1,110
ffffffffc0201226:	00006517          	auipc	a0,0x6
ffffffffc020122a:	f6a50513          	addi	a0,a0,-150 # ffffffffc0207190 <commands+0x900>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc020122e:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0201230:	fd9fe0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0201234 <mm_create>:
mm_create(void) {
ffffffffc0201234:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0201236:	04000513          	li	a0,64
mm_create(void) {
ffffffffc020123a:	e022                	sd	s0,0(sp)
ffffffffc020123c:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020123e:	48b000ef          	jal	ra,ffffffffc0201ec8 <kmalloc>
ffffffffc0201242:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc0201244:	c505                	beqz	a0,ffffffffc020126c <mm_create+0x38>
    elm->prev = elm->next = elm;
ffffffffc0201246:	e408                	sd	a0,8(s0)
ffffffffc0201248:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc020124a:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020124e:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0201252:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0201256:	000b1797          	auipc	a5,0xb1
ffffffffc020125a:	7927a783          	lw	a5,1938(a5) # ffffffffc02b29e8 <swap_init_ok>
ffffffffc020125e:	ef81                	bnez	a5,ffffffffc0201276 <mm_create+0x42>
        else mm->sm_priv = NULL;
ffffffffc0201260:	02053423          	sd	zero,40(a0)
    return mm->mm_count;
}

static inline void
set_mm_count(struct mm_struct *mm, int val) {
    mm->mm_count = val;
ffffffffc0201264:	02042823          	sw	zero,48(s0)

typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock) {
    *lock = 0;
ffffffffc0201268:	02043c23          	sd	zero,56(s0)
}
ffffffffc020126c:	60a2                	ld	ra,8(sp)
ffffffffc020126e:	8522                	mv	a0,s0
ffffffffc0201270:	6402                	ld	s0,0(sp)
ffffffffc0201272:	0141                	addi	sp,sp,16
ffffffffc0201274:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0201276:	55a010ef          	jal	ra,ffffffffc02027d0 <swap_init_mm>
ffffffffc020127a:	b7ed                	j	ffffffffc0201264 <mm_create+0x30>

ffffffffc020127c <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc020127c:	1101                	addi	sp,sp,-32
ffffffffc020127e:	e04a                	sd	s2,0(sp)
ffffffffc0201280:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0201282:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0201286:	e822                	sd	s0,16(sp)
ffffffffc0201288:	e426                	sd	s1,8(sp)
ffffffffc020128a:	ec06                	sd	ra,24(sp)
ffffffffc020128c:	84ae                	mv	s1,a1
ffffffffc020128e:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0201290:	439000ef          	jal	ra,ffffffffc0201ec8 <kmalloc>
    if (vma != NULL) {
ffffffffc0201294:	c509                	beqz	a0,ffffffffc020129e <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc0201296:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc020129a:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020129c:	cd00                	sw	s0,24(a0)
}
ffffffffc020129e:	60e2                	ld	ra,24(sp)
ffffffffc02012a0:	6442                	ld	s0,16(sp)
ffffffffc02012a2:	64a2                	ld	s1,8(sp)
ffffffffc02012a4:	6902                	ld	s2,0(sp)
ffffffffc02012a6:	6105                	addi	sp,sp,32
ffffffffc02012a8:	8082                	ret

ffffffffc02012aa <find_vma>:
find_vma(struct mm_struct *mm, uintptr_t addr) {
ffffffffc02012aa:	86aa                	mv	a3,a0
    if (mm != NULL) {
ffffffffc02012ac:	c505                	beqz	a0,ffffffffc02012d4 <find_vma+0x2a>
        vma = mm->mmap_cache;
ffffffffc02012ae:	6908                	ld	a0,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc02012b0:	c501                	beqz	a0,ffffffffc02012b8 <find_vma+0xe>
ffffffffc02012b2:	651c                	ld	a5,8(a0)
ffffffffc02012b4:	02f5f263          	bgeu	a1,a5,ffffffffc02012d8 <find_vma+0x2e>
    return listelm->next;
ffffffffc02012b8:	669c                	ld	a5,8(a3)
                while ((le = list_next(le)) != list) {
ffffffffc02012ba:	00f68d63          	beq	a3,a5,ffffffffc02012d4 <find_vma+0x2a>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc02012be:	fe87b703          	ld	a4,-24(a5)
ffffffffc02012c2:	00e5e663          	bltu	a1,a4,ffffffffc02012ce <find_vma+0x24>
ffffffffc02012c6:	ff07b703          	ld	a4,-16(a5)
ffffffffc02012ca:	00e5ec63          	bltu	a1,a4,ffffffffc02012e2 <find_vma+0x38>
ffffffffc02012ce:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc02012d0:	fef697e3          	bne	a3,a5,ffffffffc02012be <find_vma+0x14>
    struct vma_struct *vma = NULL;
ffffffffc02012d4:	4501                	li	a0,0
}
ffffffffc02012d6:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc02012d8:	691c                	ld	a5,16(a0)
ffffffffc02012da:	fcf5ffe3          	bgeu	a1,a5,ffffffffc02012b8 <find_vma+0xe>
            mm->mmap_cache = vma;
ffffffffc02012de:	ea88                	sd	a0,16(a3)
ffffffffc02012e0:	8082                	ret
                    vma = le2vma(le, list_link);
ffffffffc02012e2:	fe078513          	addi	a0,a5,-32
            mm->mmap_cache = vma;
ffffffffc02012e6:	ea88                	sd	a0,16(a3)
ffffffffc02012e8:	8082                	ret

ffffffffc02012ea <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc02012ea:	6590                	ld	a2,8(a1)
ffffffffc02012ec:	0105b803          	ld	a6,16(a1)
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc02012f0:	1141                	addi	sp,sp,-16
ffffffffc02012f2:	e406                	sd	ra,8(sp)
ffffffffc02012f4:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc02012f6:	01066763          	bltu	a2,a6,ffffffffc0201304 <insert_vma_struct+0x1a>
ffffffffc02012fa:	a085                	j	ffffffffc020135a <insert_vma_struct+0x70>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc02012fc:	fe87b703          	ld	a4,-24(a5)
ffffffffc0201300:	04e66863          	bltu	a2,a4,ffffffffc0201350 <insert_vma_struct+0x66>
ffffffffc0201304:	86be                	mv	a3,a5
ffffffffc0201306:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0201308:	fef51ae3          	bne	a0,a5,ffffffffc02012fc <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc020130c:	02a68463          	beq	a3,a0,ffffffffc0201334 <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0201310:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0201314:	fe86b883          	ld	a7,-24(a3)
ffffffffc0201318:	08e8f163          	bgeu	a7,a4,ffffffffc020139a <insert_vma_struct+0xb0>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020131c:	04e66f63          	bltu	a2,a4,ffffffffc020137a <insert_vma_struct+0x90>
    }
    if (le_next != list) {
ffffffffc0201320:	00f50a63          	beq	a0,a5,ffffffffc0201334 <insert_vma_struct+0x4a>
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0201324:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0201328:	05076963          	bltu	a4,a6,ffffffffc020137a <insert_vma_struct+0x90>
    assert(next->vm_start < next->vm_end);
ffffffffc020132c:	ff07b603          	ld	a2,-16(a5)
ffffffffc0201330:	02c77363          	bgeu	a4,a2,ffffffffc0201356 <insert_vma_struct+0x6c>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc0201334:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0201336:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0201338:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc020133c:	e390                	sd	a2,0(a5)
ffffffffc020133e:	e690                	sd	a2,8(a3)
}
ffffffffc0201340:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc0201342:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc0201344:	f194                	sd	a3,32(a1)
    mm->map_count ++;
ffffffffc0201346:	0017079b          	addiw	a5,a4,1
ffffffffc020134a:	d11c                	sw	a5,32(a0)
}
ffffffffc020134c:	0141                	addi	sp,sp,16
ffffffffc020134e:	8082                	ret
    if (le_prev != list) {
ffffffffc0201350:	fca690e3          	bne	a3,a0,ffffffffc0201310 <insert_vma_struct+0x26>
ffffffffc0201354:	bfd1                	j	ffffffffc0201328 <insert_vma_struct+0x3e>
ffffffffc0201356:	ebbff0ef          	jal	ra,ffffffffc0201210 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc020135a:	00006697          	auipc	a3,0x6
ffffffffc020135e:	e4668693          	addi	a3,a3,-442 # ffffffffc02071a0 <commands+0x910>
ffffffffc0201362:	00006617          	auipc	a2,0x6
ffffffffc0201366:	93e60613          	addi	a2,a2,-1730 # ffffffffc0206ca0 <commands+0x410>
ffffffffc020136a:	07500593          	li	a1,117
ffffffffc020136e:	00006517          	auipc	a0,0x6
ffffffffc0201372:	e2250513          	addi	a0,a0,-478 # ffffffffc0207190 <commands+0x900>
ffffffffc0201376:	e93fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020137a:	00006697          	auipc	a3,0x6
ffffffffc020137e:	e6668693          	addi	a3,a3,-410 # ffffffffc02071e0 <commands+0x950>
ffffffffc0201382:	00006617          	auipc	a2,0x6
ffffffffc0201386:	91e60613          	addi	a2,a2,-1762 # ffffffffc0206ca0 <commands+0x410>
ffffffffc020138a:	06d00593          	li	a1,109
ffffffffc020138e:	00006517          	auipc	a0,0x6
ffffffffc0201392:	e0250513          	addi	a0,a0,-510 # ffffffffc0207190 <commands+0x900>
ffffffffc0201396:	e73fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc020139a:	00006697          	auipc	a3,0x6
ffffffffc020139e:	e2668693          	addi	a3,a3,-474 # ffffffffc02071c0 <commands+0x930>
ffffffffc02013a2:	00006617          	auipc	a2,0x6
ffffffffc02013a6:	8fe60613          	addi	a2,a2,-1794 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02013aa:	06c00593          	li	a1,108
ffffffffc02013ae:	00006517          	auipc	a0,0x6
ffffffffc02013b2:	de250513          	addi	a0,a0,-542 # ffffffffc0207190 <commands+0x900>
ffffffffc02013b6:	e53fe0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02013ba <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
    assert(mm_count(mm) == 0);
ffffffffc02013ba:	591c                	lw	a5,48(a0)
mm_destroy(struct mm_struct *mm) {
ffffffffc02013bc:	1141                	addi	sp,sp,-16
ffffffffc02013be:	e406                	sd	ra,8(sp)
ffffffffc02013c0:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02013c2:	e78d                	bnez	a5,ffffffffc02013ec <mm_destroy+0x32>
ffffffffc02013c4:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02013c6:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc02013c8:	00a40c63          	beq	s0,a0,ffffffffc02013e0 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02013cc:	6118                	ld	a4,0(a0)
ffffffffc02013ce:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc02013d0:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02013d2:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02013d4:	e398                	sd	a4,0(a5)
ffffffffc02013d6:	3a3000ef          	jal	ra,ffffffffc0201f78 <kfree>
    return listelm->next;
ffffffffc02013da:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc02013dc:	fea418e3          	bne	s0,a0,ffffffffc02013cc <mm_destroy+0x12>
    }
    kfree(mm); //kfree mm
ffffffffc02013e0:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc02013e2:	6402                	ld	s0,0(sp)
ffffffffc02013e4:	60a2                	ld	ra,8(sp)
ffffffffc02013e6:	0141                	addi	sp,sp,16
    kfree(mm); //kfree mm
ffffffffc02013e8:	3910006f          	j	ffffffffc0201f78 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02013ec:	00006697          	auipc	a3,0x6
ffffffffc02013f0:	e1468693          	addi	a3,a3,-492 # ffffffffc0207200 <commands+0x970>
ffffffffc02013f4:	00006617          	auipc	a2,0x6
ffffffffc02013f8:	8ac60613          	addi	a2,a2,-1876 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02013fc:	09500593          	li	a1,149
ffffffffc0201400:	00006517          	auipc	a0,0x6
ffffffffc0201404:	d9050513          	addi	a0,a0,-624 # ffffffffc0207190 <commands+0x900>
ffffffffc0201408:	e01fe0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc020140c <mm_map>:
 * 返回值：
 *   - 成功时返回 0
 *   - 如果地址无效或无法创建 VMA，返回 -E_INVAL 或 -E_NO_MEM
 */
int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store) {
ffffffffc020140c:	7139                	addi	sp,sp,-64
ffffffffc020140e:	f822                	sd	s0,48(sp)
    // 将地址对齐到页边界
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0201410:	6405                	lui	s0,0x1
ffffffffc0201412:	147d                	addi	s0,s0,-1
ffffffffc0201414:	77fd                	lui	a5,0xfffff
ffffffffc0201416:	9622                	add	a2,a2,s0
ffffffffc0201418:	962e                	add	a2,a2,a1
           struct vma_struct **vma_store) {
ffffffffc020141a:	f426                	sd	s1,40(sp)
ffffffffc020141c:	fc06                	sd	ra,56(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020141e:	00f5f4b3          	and	s1,a1,a5
           struct vma_struct **vma_store) {
ffffffffc0201422:	f04a                	sd	s2,32(sp)
ffffffffc0201424:	ec4e                	sd	s3,24(sp)
ffffffffc0201426:	e852                	sd	s4,16(sp)
ffffffffc0201428:	e456                	sd	s5,8(sp)

    // 检查是否在用户空间地址范围内
    if (!USER_ACCESS(start, end)) {
ffffffffc020142a:	002005b7          	lui	a1,0x200
ffffffffc020142e:	00f67433          	and	s0,a2,a5
ffffffffc0201432:	06b4e363          	bltu	s1,a1,ffffffffc0201498 <mm_map+0x8c>
ffffffffc0201436:	0684f163          	bgeu	s1,s0,ffffffffc0201498 <mm_map+0x8c>
ffffffffc020143a:	4785                	li	a5,1
ffffffffc020143c:	07fe                	slli	a5,a5,0x1f
ffffffffc020143e:	0487ed63          	bltu	a5,s0,ffffffffc0201498 <mm_map+0x8c>
ffffffffc0201442:	89aa                	mv	s3,a0
        return -E_INVAL;  // 无效的用户地址范围
    }

    assert(mm != NULL);  // 确保 mm 指针非空
ffffffffc0201444:	cd21                	beqz	a0,ffffffffc020149c <mm_map+0x90>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    // 查找起始地址所在的虚拟内存区域，如果找不到或区域无效，跳转到 out
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start) {
ffffffffc0201446:	85a6                	mv	a1,s1
ffffffffc0201448:	8ab6                	mv	s5,a3
ffffffffc020144a:	8a3a                	mv	s4,a4
ffffffffc020144c:	e5fff0ef          	jal	ra,ffffffffc02012aa <find_vma>
ffffffffc0201450:	c501                	beqz	a0,ffffffffc0201458 <mm_map+0x4c>
ffffffffc0201452:	651c                	ld	a5,8(a0)
ffffffffc0201454:	0487e263          	bltu	a5,s0,ffffffffc0201498 <mm_map+0x8c>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0201458:	03000513          	li	a0,48
ffffffffc020145c:	26d000ef          	jal	ra,ffffffffc0201ec8 <kmalloc>
ffffffffc0201460:	892a                	mv	s2,a0
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc0201462:	5571                	li	a0,-4
    if (vma != NULL) {
ffffffffc0201464:	02090163          	beqz	s2,ffffffffc0201486 <mm_map+0x7a>
    if ((vma = vma_create(start, end, vm_flags)) == NULL) {
        goto out;
    }

    // 将新的虚拟内存区域插入到进程的内存映射列表中
    insert_vma_struct(mm, vma);
ffffffffc0201468:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc020146a:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc020146e:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc0201472:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc0201476:	85ca                	mv	a1,s2
ffffffffc0201478:	e73ff0ef          	jal	ra,ffffffffc02012ea <insert_vma_struct>
    // 如果传入 vma_store 指针，存储新创建的 VMA
    if (vma_store != NULL) {
        *vma_store = vma;
    }

    ret = 0;  // 成功
ffffffffc020147c:	4501                	li	a0,0
    if (vma_store != NULL) {
ffffffffc020147e:	000a0463          	beqz	s4,ffffffffc0201486 <mm_map+0x7a>
        *vma_store = vma;
ffffffffc0201482:	012a3023          	sd	s2,0(s4)

out:
    return ret;  // 返回结果
}
ffffffffc0201486:	70e2                	ld	ra,56(sp)
ffffffffc0201488:	7442                	ld	s0,48(sp)
ffffffffc020148a:	74a2                	ld	s1,40(sp)
ffffffffc020148c:	7902                	ld	s2,32(sp)
ffffffffc020148e:	69e2                	ld	s3,24(sp)
ffffffffc0201490:	6a42                	ld	s4,16(sp)
ffffffffc0201492:	6aa2                	ld	s5,8(sp)
ffffffffc0201494:	6121                	addi	sp,sp,64
ffffffffc0201496:	8082                	ret
        return -E_INVAL;  // 无效的用户地址范围
ffffffffc0201498:	5575                	li	a0,-3
ffffffffc020149a:	b7f5                	j	ffffffffc0201486 <mm_map+0x7a>
    assert(mm != NULL);  // 确保 mm 指针非空
ffffffffc020149c:	00006697          	auipc	a3,0x6
ffffffffc02014a0:	d7c68693          	addi	a3,a3,-644 # ffffffffc0207218 <commands+0x988>
ffffffffc02014a4:	00005617          	auipc	a2,0x5
ffffffffc02014a8:	7fc60613          	addi	a2,a2,2044 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02014ac:	0b800593          	li	a1,184
ffffffffc02014b0:	00006517          	auipc	a0,0x6
ffffffffc02014b4:	ce050513          	addi	a0,a0,-800 # ffffffffc0207190 <commands+0x900>
ffffffffc02014b8:	d51fe0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02014bc <dup_mmap>:
 *   from - 源进程的内存描述符
 * 返回值：
 *   - 成功时返回 0
 *   - 如果内存分配失败或复制失败，返回 -E_NO_MEM
 */
int dup_mmap(struct mm_struct *to, struct mm_struct *from) {
ffffffffc02014bc:	7139                	addi	sp,sp,-64
ffffffffc02014be:	fc06                	sd	ra,56(sp)
ffffffffc02014c0:	f822                	sd	s0,48(sp)
ffffffffc02014c2:	f426                	sd	s1,40(sp)
ffffffffc02014c4:	f04a                	sd	s2,32(sp)
ffffffffc02014c6:	ec4e                	sd	s3,24(sp)
ffffffffc02014c8:	e852                	sd	s4,16(sp)
ffffffffc02014ca:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);  // 确保目标和源进程非空
ffffffffc02014cc:	c52d                	beqz	a0,ffffffffc0201536 <dup_mmap+0x7a>
ffffffffc02014ce:	892a                	mv	s2,a0
ffffffffc02014d0:	84ae                	mv	s1,a1

    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02014d2:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);  // 确保目标和源进程非空
ffffffffc02014d4:	e595                	bnez	a1,ffffffffc0201500 <dup_mmap+0x44>
ffffffffc02014d6:	a085                	j	ffffffffc0201536 <dup_mmap+0x7a>

        if (nvma == NULL) {
            return -E_NO_MEM;  // 创建 VMA 失败，返回错误
        }

        insert_vma_struct(to, nvma);  // 将新的 VMA 插入到目标进程的内存映射列表中
ffffffffc02014d8:	854a                	mv	a0,s2
        vma->vm_start = vm_start;
ffffffffc02014da:	0155b423          	sd	s5,8(a1) # 200008 <_binary_obj___user_exit_out_size+0x1f4ec8>
        vma->vm_end = vm_end;
ffffffffc02014de:	0145b823          	sd	s4,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc02014e2:	0135ac23          	sw	s3,24(a1)
        insert_vma_struct(to, nvma);  // 将新的 VMA 插入到目标进程的内存映射列表中
ffffffffc02014e6:	e05ff0ef          	jal	ra,ffffffffc02012ea <insert_vma_struct>

        bool share = 0;  // 共享标志
        // 复制页表范围内的数据，注意是否为共享内存
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0) {
ffffffffc02014ea:	ff043683          	ld	a3,-16(s0) # ff0 <_binary_obj___user_faultread_out_size-0x8be0>
ffffffffc02014ee:	fe843603          	ld	a2,-24(s0)
ffffffffc02014f2:	6c8c                	ld	a1,24(s1)
ffffffffc02014f4:	01893503          	ld	a0,24(s2)
ffffffffc02014f8:	4701                	li	a4,0
ffffffffc02014fa:	398030ef          	jal	ra,ffffffffc0204892 <copy_range>
ffffffffc02014fe:	e105                	bnez	a0,ffffffffc020151e <dup_mmap+0x62>
    return listelm->prev;
ffffffffc0201500:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list) {  // 遍历源进程的内存映射列表
ffffffffc0201502:	02848863          	beq	s1,s0,ffffffffc0201532 <dup_mmap+0x76>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0201506:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);  // 创建新的 VMA
ffffffffc020150a:	fe843a83          	ld	s5,-24(s0)
ffffffffc020150e:	ff043a03          	ld	s4,-16(s0)
ffffffffc0201512:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0201516:	1b3000ef          	jal	ra,ffffffffc0201ec8 <kmalloc>
ffffffffc020151a:	85aa                	mv	a1,a0
    if (vma != NULL) {
ffffffffc020151c:	fd55                	bnez	a0,ffffffffc02014d8 <dup_mmap+0x1c>
            return -E_NO_MEM;  // 创建 VMA 失败，返回错误
ffffffffc020151e:	5571                	li	a0,-4
            return -E_NO_MEM;  // 复制内存失败
        }
    }

    return 0;  // 成功
}
ffffffffc0201520:	70e2                	ld	ra,56(sp)
ffffffffc0201522:	7442                	ld	s0,48(sp)
ffffffffc0201524:	74a2                	ld	s1,40(sp)
ffffffffc0201526:	7902                	ld	s2,32(sp)
ffffffffc0201528:	69e2                	ld	s3,24(sp)
ffffffffc020152a:	6a42                	ld	s4,16(sp)
ffffffffc020152c:	6aa2                	ld	s5,8(sp)
ffffffffc020152e:	6121                	addi	sp,sp,64
ffffffffc0201530:	8082                	ret
    return 0;  // 成功
ffffffffc0201532:	4501                	li	a0,0
ffffffffc0201534:	b7f5                	j	ffffffffc0201520 <dup_mmap+0x64>
    assert(to != NULL && from != NULL);  // 确保目标和源进程非空
ffffffffc0201536:	00006697          	auipc	a3,0x6
ffffffffc020153a:	cf268693          	addi	a3,a3,-782 # ffffffffc0207228 <commands+0x998>
ffffffffc020153e:	00005617          	auipc	a2,0x5
ffffffffc0201542:	76260613          	addi	a2,a2,1890 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201546:	0e200593          	li	a1,226
ffffffffc020154a:	00006517          	auipc	a0,0x6
ffffffffc020154e:	c4650513          	addi	a0,a0,-954 # ffffffffc0207190 <commands+0x900>
ffffffffc0201552:	cb7fe0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0201556 <exit_mmap>:
 * 
 * 功能：当进程退出时，释放所有的虚拟内存区域。
 * 参数：
 *   mm - 进程的内存描述符 (mm_struct)
 */
void exit_mmap(struct mm_struct *mm) {
ffffffffc0201556:	1101                	addi	sp,sp,-32
ffffffffc0201558:	ec06                	sd	ra,24(sp)
ffffffffc020155a:	e822                	sd	s0,16(sp)
ffffffffc020155c:	e426                	sd	s1,8(sp)
ffffffffc020155e:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);  // 确保进程内存描述符非空，且进程内存计数为 0
ffffffffc0201560:	c531                	beqz	a0,ffffffffc02015ac <exit_mmap+0x56>
ffffffffc0201562:	591c                	lw	a5,48(a0)
ffffffffc0201564:	84aa                	mv	s1,a0
ffffffffc0201566:	e3b9                	bnez	a5,ffffffffc02015ac <exit_mmap+0x56>
    return listelm->next;
ffffffffc0201568:	6500                	ld	s0,8(a0)

    pde_t *pgdir = mm->pgdir;
ffffffffc020156a:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;

    // 遍历并解除映射所有的虚拟内存区域
    while ((le = list_next(le)) != list) {
ffffffffc020156e:	02850663          	beq	a0,s0,ffffffffc020159a <exit_mmap+0x44>
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);  // 解除虚拟地址区间的映射
ffffffffc0201572:	ff043603          	ld	a2,-16(s0)
ffffffffc0201576:	fe843583          	ld	a1,-24(s0)
ffffffffc020157a:	854a                	mv	a0,s2
ffffffffc020157c:	212020ef          	jal	ra,ffffffffc020378e <unmap_range>
ffffffffc0201580:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc0201582:	fe8498e3          	bne	s1,s0,ffffffffc0201572 <exit_mmap+0x1c>
ffffffffc0201586:	6400                	ld	s0,8(s0)
    }

    // 清理并释放资源
    while ((le = list_next(le)) != list) {
ffffffffc0201588:	00848c63          	beq	s1,s0,ffffffffc02015a0 <exit_mmap+0x4a>
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);  // 退出并释放内存区域
ffffffffc020158c:	ff043603          	ld	a2,-16(s0)
ffffffffc0201590:	fe843583          	ld	a1,-24(s0)
ffffffffc0201594:	854a                	mv	a0,s2
ffffffffc0201596:	33e020ef          	jal	ra,ffffffffc02038d4 <exit_range>
ffffffffc020159a:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc020159c:	fe8498e3          	bne	s1,s0,ffffffffc020158c <exit_mmap+0x36>
    }
}
ffffffffc02015a0:	60e2                	ld	ra,24(sp)
ffffffffc02015a2:	6442                	ld	s0,16(sp)
ffffffffc02015a4:	64a2                	ld	s1,8(sp)
ffffffffc02015a6:	6902                	ld	s2,0(sp)
ffffffffc02015a8:	6105                	addi	sp,sp,32
ffffffffc02015aa:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);  // 确保进程内存描述符非空，且进程内存计数为 0
ffffffffc02015ac:	00006697          	auipc	a3,0x6
ffffffffc02015b0:	c9c68693          	addi	a3,a3,-868 # ffffffffc0207248 <commands+0x9b8>
ffffffffc02015b4:	00005617          	auipc	a2,0x5
ffffffffc02015b8:	6ec60613          	addi	a2,a2,1772 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02015bc:	10200593          	li	a1,258
ffffffffc02015c0:	00006517          	auipc	a0,0x6
ffffffffc02015c4:	bd050513          	addi	a0,a0,-1072 # ffffffffc0207190 <commands+0x900>
ffffffffc02015c8:	c41fe0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02015cc <vmm_init>:


// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc02015cc:	7139                	addi	sp,sp,-64
ffffffffc02015ce:	f822                	sd	s0,48(sp)
ffffffffc02015d0:	f426                	sd	s1,40(sp)
ffffffffc02015d2:	fc06                	sd	ra,56(sp)
ffffffffc02015d4:	f04a                	sd	s2,32(sp)
ffffffffc02015d6:	ec4e                	sd	s3,24(sp)
ffffffffc02015d8:	e852                	sd	s4,16(sp)
ffffffffc02015da:	e456                	sd	s5,8(sp)

static void
check_vma_struct(void) {
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
ffffffffc02015dc:	c59ff0ef          	jal	ra,ffffffffc0201234 <mm_create>
    assert(mm != NULL);
ffffffffc02015e0:	84aa                	mv	s1,a0
ffffffffc02015e2:	03200413          	li	s0,50
ffffffffc02015e6:	e919                	bnez	a0,ffffffffc02015fc <vmm_init+0x30>
ffffffffc02015e8:	a991                	j	ffffffffc0201a3c <vmm_init+0x470>
        vma->vm_start = vm_start;
ffffffffc02015ea:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc02015ec:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02015ee:	00052c23          	sw	zero,24(a0)

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i --) {
ffffffffc02015f2:	146d                	addi	s0,s0,-5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02015f4:	8526                	mv	a0,s1
ffffffffc02015f6:	cf5ff0ef          	jal	ra,ffffffffc02012ea <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc02015fa:	c80d                	beqz	s0,ffffffffc020162c <vmm_init+0x60>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02015fc:	03000513          	li	a0,48
ffffffffc0201600:	0c9000ef          	jal	ra,ffffffffc0201ec8 <kmalloc>
ffffffffc0201604:	85aa                	mv	a1,a0
ffffffffc0201606:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc020160a:	f165                	bnez	a0,ffffffffc02015ea <vmm_init+0x1e>
        assert(vma != NULL);
ffffffffc020160c:	00006697          	auipc	a3,0x6
ffffffffc0201610:	ecc68693          	addi	a3,a3,-308 # ffffffffc02074d8 <commands+0xc48>
ffffffffc0201614:	00005617          	auipc	a2,0x5
ffffffffc0201618:	68c60613          	addi	a2,a2,1676 # ffffffffc0206ca0 <commands+0x410>
ffffffffc020161c:	15e00593          	li	a1,350
ffffffffc0201620:	00006517          	auipc	a0,0x6
ffffffffc0201624:	b7050513          	addi	a0,a0,-1168 # ffffffffc0207190 <commands+0x900>
ffffffffc0201628:	be1fe0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc020162c:	03700413          	li	s0,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0201630:	1f900913          	li	s2,505
ffffffffc0201634:	a819                	j	ffffffffc020164a <vmm_init+0x7e>
        vma->vm_start = vm_start;
ffffffffc0201636:	e500                	sd	s0,8(a0)
        vma->vm_end = vm_end;
ffffffffc0201638:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc020163a:	00052c23          	sw	zero,24(a0)
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc020163e:	0415                	addi	s0,s0,5
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0201640:	8526                	mv	a0,s1
ffffffffc0201642:	ca9ff0ef          	jal	ra,ffffffffc02012ea <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0201646:	03240a63          	beq	s0,s2,ffffffffc020167a <vmm_init+0xae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020164a:	03000513          	li	a0,48
ffffffffc020164e:	07b000ef          	jal	ra,ffffffffc0201ec8 <kmalloc>
ffffffffc0201652:	85aa                	mv	a1,a0
ffffffffc0201654:	00240793          	addi	a5,s0,2
    if (vma != NULL) {
ffffffffc0201658:	fd79                	bnez	a0,ffffffffc0201636 <vmm_init+0x6a>
        assert(vma != NULL);
ffffffffc020165a:	00006697          	auipc	a3,0x6
ffffffffc020165e:	e7e68693          	addi	a3,a3,-386 # ffffffffc02074d8 <commands+0xc48>
ffffffffc0201662:	00005617          	auipc	a2,0x5
ffffffffc0201666:	63e60613          	addi	a2,a2,1598 # ffffffffc0206ca0 <commands+0x410>
ffffffffc020166a:	16400593          	li	a1,356
ffffffffc020166e:	00006517          	auipc	a0,0x6
ffffffffc0201672:	b2250513          	addi	a0,a0,-1246 # ffffffffc0207190 <commands+0x900>
ffffffffc0201676:	b93fe0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc020167a:	649c                	ld	a5,8(s1)
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
        assert(le != &(mm->mmap_list));
ffffffffc020167c:	471d                	li	a4,7
    for (i = 1; i <= step2; i ++) {
ffffffffc020167e:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc0201682:	2cf48d63          	beq	s1,a5,ffffffffc020195c <vmm_init+0x390>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0201686:	fe87b683          	ld	a3,-24(a5) # ffffffffffffefe8 <end+0x3fd4c5ac>
ffffffffc020168a:	ffe70613          	addi	a2,a4,-2
ffffffffc020168e:	24d61763          	bne	a2,a3,ffffffffc02018dc <vmm_init+0x310>
ffffffffc0201692:	ff07b683          	ld	a3,-16(a5)
ffffffffc0201696:	24e69363          	bne	a3,a4,ffffffffc02018dc <vmm_init+0x310>
    for (i = 1; i <= step2; i ++) {
ffffffffc020169a:	0715                	addi	a4,a4,5
ffffffffc020169c:	679c                	ld	a5,8(a5)
ffffffffc020169e:	feb712e3          	bne	a4,a1,ffffffffc0201682 <vmm_init+0xb6>
ffffffffc02016a2:	4a1d                	li	s4,7
ffffffffc02016a4:	4415                	li	s0,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc02016a6:	1f900a93          	li	s5,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc02016aa:	85a2                	mv	a1,s0
ffffffffc02016ac:	8526                	mv	a0,s1
ffffffffc02016ae:	bfdff0ef          	jal	ra,ffffffffc02012aa <find_vma>
ffffffffc02016b2:	892a                	mv	s2,a0
        assert(vma1 != NULL);
ffffffffc02016b4:	30050463          	beqz	a0,ffffffffc02019bc <vmm_init+0x3f0>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc02016b8:	00140593          	addi	a1,s0,1
ffffffffc02016bc:	8526                	mv	a0,s1
ffffffffc02016be:	bedff0ef          	jal	ra,ffffffffc02012aa <find_vma>
ffffffffc02016c2:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc02016c4:	2c050c63          	beqz	a0,ffffffffc020199c <vmm_init+0x3d0>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc02016c8:	85d2                	mv	a1,s4
ffffffffc02016ca:	8526                	mv	a0,s1
ffffffffc02016cc:	bdfff0ef          	jal	ra,ffffffffc02012aa <find_vma>
        assert(vma3 == NULL);
ffffffffc02016d0:	2a051663          	bnez	a0,ffffffffc020197c <vmm_init+0x3b0>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc02016d4:	00340593          	addi	a1,s0,3
ffffffffc02016d8:	8526                	mv	a0,s1
ffffffffc02016da:	bd1ff0ef          	jal	ra,ffffffffc02012aa <find_vma>
        assert(vma4 == NULL);
ffffffffc02016de:	30051f63          	bnez	a0,ffffffffc02019fc <vmm_init+0x430>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc02016e2:	00440593          	addi	a1,s0,4
ffffffffc02016e6:	8526                	mv	a0,s1
ffffffffc02016e8:	bc3ff0ef          	jal	ra,ffffffffc02012aa <find_vma>
        assert(vma5 == NULL);
ffffffffc02016ec:	2e051863          	bnez	a0,ffffffffc02019dc <vmm_init+0x410>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc02016f0:	00893783          	ld	a5,8(s2)
ffffffffc02016f4:	20879463          	bne	a5,s0,ffffffffc02018fc <vmm_init+0x330>
ffffffffc02016f8:	01093783          	ld	a5,16(s2)
ffffffffc02016fc:	20fa1063          	bne	s4,a5,ffffffffc02018fc <vmm_init+0x330>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc0201700:	0089b783          	ld	a5,8(s3)
ffffffffc0201704:	20879c63          	bne	a5,s0,ffffffffc020191c <vmm_init+0x350>
ffffffffc0201708:	0109b783          	ld	a5,16(s3)
ffffffffc020170c:	20fa1863          	bne	s4,a5,ffffffffc020191c <vmm_init+0x350>
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0201710:	0415                	addi	s0,s0,5
ffffffffc0201712:	0a15                	addi	s4,s4,5
ffffffffc0201714:	f9541be3          	bne	s0,s5,ffffffffc02016aa <vmm_init+0xde>
ffffffffc0201718:	4411                	li	s0,4
    }

    for (i =4; i>=0; i--) {
ffffffffc020171a:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc020171c:	85a2                	mv	a1,s0
ffffffffc020171e:	8526                	mv	a0,s1
ffffffffc0201720:	b8bff0ef          	jal	ra,ffffffffc02012aa <find_vma>
ffffffffc0201724:	0004059b          	sext.w	a1,s0
        if (vma_below_5 != NULL ) {
ffffffffc0201728:	c90d                	beqz	a0,ffffffffc020175a <vmm_init+0x18e>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc020172a:	6914                	ld	a3,16(a0)
ffffffffc020172c:	6510                	ld	a2,8(a0)
ffffffffc020172e:	00006517          	auipc	a0,0x6
ffffffffc0201732:	c3a50513          	addi	a0,a0,-966 # ffffffffc0207368 <commands+0xad8>
ffffffffc0201736:	997fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc020173a:	00006697          	auipc	a3,0x6
ffffffffc020173e:	c5668693          	addi	a3,a3,-938 # ffffffffc0207390 <commands+0xb00>
ffffffffc0201742:	00005617          	auipc	a2,0x5
ffffffffc0201746:	55e60613          	addi	a2,a2,1374 # ffffffffc0206ca0 <commands+0x410>
ffffffffc020174a:	18600593          	li	a1,390
ffffffffc020174e:	00006517          	auipc	a0,0x6
ffffffffc0201752:	a4250513          	addi	a0,a0,-1470 # ffffffffc0207190 <commands+0x900>
ffffffffc0201756:	ab3fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    for (i =4; i>=0; i--) {
ffffffffc020175a:	147d                	addi	s0,s0,-1
ffffffffc020175c:	fd2410e3          	bne	s0,s2,ffffffffc020171c <vmm_init+0x150>
    }

    mm_destroy(mm);
ffffffffc0201760:	8526                	mv	a0,s1
ffffffffc0201762:	c59ff0ef          	jal	ra,ffffffffc02013ba <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0201766:	00006517          	auipc	a0,0x6
ffffffffc020176a:	c4250513          	addi	a0,a0,-958 # ffffffffc02073a8 <commands+0xb18>
ffffffffc020176e:	95ffe0ef          	jal	ra,ffffffffc02000cc <cprintf>
struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0201772:	5bd010ef          	jal	ra,ffffffffc020352e <nr_free_pages>
ffffffffc0201776:	892a                	mv	s2,a0

    check_mm_struct = mm_create();
ffffffffc0201778:	abdff0ef          	jal	ra,ffffffffc0201234 <mm_create>
ffffffffc020177c:	000b1797          	auipc	a5,0xb1
ffffffffc0201780:	24a7b223          	sd	a0,580(a5) # ffffffffc02b29c0 <check_mm_struct>
ffffffffc0201784:	842a                	mv	s0,a0
    assert(check_mm_struct != NULL);
ffffffffc0201786:	28050b63          	beqz	a0,ffffffffc0201a1c <vmm_init+0x450>

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020178a:	000b1497          	auipc	s1,0xb1
ffffffffc020178e:	26e4b483          	ld	s1,622(s1) # ffffffffc02b29f8 <boot_pgdir>
    assert(pgdir[0] == 0);
ffffffffc0201792:	609c                	ld	a5,0(s1)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0201794:	ed04                	sd	s1,24(a0)
    assert(pgdir[0] == 0);
ffffffffc0201796:	2e079f63          	bnez	a5,ffffffffc0201a94 <vmm_init+0x4c8>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020179a:	03000513          	li	a0,48
ffffffffc020179e:	72a000ef          	jal	ra,ffffffffc0201ec8 <kmalloc>
ffffffffc02017a2:	89aa                	mv	s3,a0
    if (vma != NULL) {
ffffffffc02017a4:	18050c63          	beqz	a0,ffffffffc020193c <vmm_init+0x370>
        vma->vm_end = vm_end;
ffffffffc02017a8:	002007b7          	lui	a5,0x200
ffffffffc02017ac:	00f9b823          	sd	a5,16(s3)
        vma->vm_flags = vm_flags;
ffffffffc02017b0:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc02017b2:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc02017b4:	00f9ac23          	sw	a5,24(s3)
    insert_vma_struct(mm, vma);
ffffffffc02017b8:	8522                	mv	a0,s0
        vma->vm_start = vm_start;
ffffffffc02017ba:	0009b423          	sd	zero,8(s3)
    insert_vma_struct(mm, vma);
ffffffffc02017be:	b2dff0ef          	jal	ra,ffffffffc02012ea <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc02017c2:	10000593          	li	a1,256
ffffffffc02017c6:	8522                	mv	a0,s0
ffffffffc02017c8:	ae3ff0ef          	jal	ra,ffffffffc02012aa <find_vma>
ffffffffc02017cc:	10000793          	li	a5,256

    int i, sum = 0;

    for (i = 0; i < 100; i ++) {
ffffffffc02017d0:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc02017d4:	2ea99063          	bne	s3,a0,ffffffffc0201ab4 <vmm_init+0x4e8>
        *(char *)(addr + i) = i;
ffffffffc02017d8:	00f78023          	sb	a5,0(a5) # 200000 <_binary_obj___user_exit_out_size+0x1f4ec0>
    for (i = 0; i < 100; i ++) {
ffffffffc02017dc:	0785                	addi	a5,a5,1
ffffffffc02017de:	fee79de3          	bne	a5,a4,ffffffffc02017d8 <vmm_init+0x20c>
        sum += i;
ffffffffc02017e2:	6705                	lui	a4,0x1
ffffffffc02017e4:	10000793          	li	a5,256
ffffffffc02017e8:	35670713          	addi	a4,a4,854 # 1356 <_binary_obj___user_faultread_out_size-0x887a>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc02017ec:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc02017f0:	0007c683          	lbu	a3,0(a5)
    for (i = 0; i < 100; i ++) {
ffffffffc02017f4:	0785                	addi	a5,a5,1
        sum -= *(char *)(addr + i);
ffffffffc02017f6:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc02017f8:	fec79ce3          	bne	a5,a2,ffffffffc02017f0 <vmm_init+0x224>
    }

    assert(sum == 0);
ffffffffc02017fc:	2e071863          	bnez	a4,ffffffffc0201aec <vmm_init+0x520>
    return pa2page(PTE_ADDR(pte));
}

static inline struct Page *
pde2page(pde_t pde) {
    return pa2page(PDE_ADDR(pde));
ffffffffc0201800:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc0201802:	000b1a97          	auipc	s5,0xb1
ffffffffc0201806:	1fea8a93          	addi	s5,s5,510 # ffffffffc02b2a00 <npage>
ffffffffc020180a:	000ab603          	ld	a2,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020180e:	078a                	slli	a5,a5,0x2
ffffffffc0201810:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201812:	2cc7f163          	bgeu	a5,a2,ffffffffc0201ad4 <vmm_init+0x508>
    return &pages[PPN(pa) - nbase];
ffffffffc0201816:	00007a17          	auipc	s4,0x7
ffffffffc020181a:	4aaa3a03          	ld	s4,1194(s4) # ffffffffc0208cc0 <nbase>
ffffffffc020181e:	414787b3          	sub	a5,a5,s4
ffffffffc0201822:	079a                	slli	a5,a5,0x6
    return page - pages + nbase;
ffffffffc0201824:	8799                	srai	a5,a5,0x6
ffffffffc0201826:	97d2                	add	a5,a5,s4
    return KADDR(page2pa(page));
ffffffffc0201828:	00c79713          	slli	a4,a5,0xc
ffffffffc020182c:	8331                	srli	a4,a4,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc020182e:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0201832:	24c77563          	bgeu	a4,a2,ffffffffc0201a7c <vmm_init+0x4b0>
ffffffffc0201836:	000b1997          	auipc	s3,0xb1
ffffffffc020183a:	1e29b983          	ld	s3,482(s3) # ffffffffc02b2a18 <va_pa_offset>

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc020183e:	4581                	li	a1,0
ffffffffc0201840:	8526                	mv	a0,s1
ffffffffc0201842:	99b6                	add	s3,s3,a3
ffffffffc0201844:	322020ef          	jal	ra,ffffffffc0203b66 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc0201848:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc020184c:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201850:	078a                	slli	a5,a5,0x2
ffffffffc0201852:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0201854:	28e7f063          	bgeu	a5,a4,ffffffffc0201ad4 <vmm_init+0x508>
    return &pages[PPN(pa) - nbase];
ffffffffc0201858:	000b1997          	auipc	s3,0xb1
ffffffffc020185c:	1b098993          	addi	s3,s3,432 # ffffffffc02b2a08 <pages>
ffffffffc0201860:	0009b503          	ld	a0,0(s3)
ffffffffc0201864:	414787b3          	sub	a5,a5,s4
ffffffffc0201868:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc020186a:	953e                	add	a0,a0,a5
ffffffffc020186c:	4585                	li	a1,1
ffffffffc020186e:	481010ef          	jal	ra,ffffffffc02034ee <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0201872:	609c                	ld	a5,0(s1)
    if (PPN(pa) >= npage) {
ffffffffc0201874:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0201878:	078a                	slli	a5,a5,0x2
ffffffffc020187a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020187c:	24e7fc63          	bgeu	a5,a4,ffffffffc0201ad4 <vmm_init+0x508>
    return &pages[PPN(pa) - nbase];
ffffffffc0201880:	0009b503          	ld	a0,0(s3)
ffffffffc0201884:	414787b3          	sub	a5,a5,s4
ffffffffc0201888:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc020188a:	4585                	li	a1,1
ffffffffc020188c:	953e                	add	a0,a0,a5
ffffffffc020188e:	461010ef          	jal	ra,ffffffffc02034ee <free_pages>
    pgdir[0] = 0;
ffffffffc0201892:	0004b023          	sd	zero,0(s1)
    page->ref -= 1;
    return page->ref;
}

static inline void flush_tlb() {
  asm volatile("sfence.vma");
ffffffffc0201896:	12000073          	sfence.vma
    flush_tlb();

    mm->pgdir = NULL;
    mm_destroy(mm);
ffffffffc020189a:	8522                	mv	a0,s0
    mm->pgdir = NULL;
ffffffffc020189c:	00043c23          	sd	zero,24(s0)
    mm_destroy(mm);
ffffffffc02018a0:	b1bff0ef          	jal	ra,ffffffffc02013ba <mm_destroy>
    check_mm_struct = NULL;
ffffffffc02018a4:	000b1797          	auipc	a5,0xb1
ffffffffc02018a8:	1007be23          	sd	zero,284(a5) # ffffffffc02b29c0 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02018ac:	483010ef          	jal	ra,ffffffffc020352e <nr_free_pages>
ffffffffc02018b0:	1aa91663          	bne	s2,a0,ffffffffc0201a5c <vmm_init+0x490>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc02018b4:	00006517          	auipc	a0,0x6
ffffffffc02018b8:	bec50513          	addi	a0,a0,-1044 # ffffffffc02074a0 <commands+0xc10>
ffffffffc02018bc:	811fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc02018c0:	7442                	ld	s0,48(sp)
ffffffffc02018c2:	70e2                	ld	ra,56(sp)
ffffffffc02018c4:	74a2                	ld	s1,40(sp)
ffffffffc02018c6:	7902                	ld	s2,32(sp)
ffffffffc02018c8:	69e2                	ld	s3,24(sp)
ffffffffc02018ca:	6a42                	ld	s4,16(sp)
ffffffffc02018cc:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc02018ce:	00006517          	auipc	a0,0x6
ffffffffc02018d2:	bf250513          	addi	a0,a0,-1038 # ffffffffc02074c0 <commands+0xc30>
}
ffffffffc02018d6:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc02018d8:	ff4fe06f          	j	ffffffffc02000cc <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02018dc:	00006697          	auipc	a3,0x6
ffffffffc02018e0:	9a468693          	addi	a3,a3,-1628 # ffffffffc0207280 <commands+0x9f0>
ffffffffc02018e4:	00005617          	auipc	a2,0x5
ffffffffc02018e8:	3bc60613          	addi	a2,a2,956 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02018ec:	16d00593          	li	a1,365
ffffffffc02018f0:	00006517          	auipc	a0,0x6
ffffffffc02018f4:	8a050513          	addi	a0,a0,-1888 # ffffffffc0207190 <commands+0x900>
ffffffffc02018f8:	911fe0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc02018fc:	00006697          	auipc	a3,0x6
ffffffffc0201900:	a0c68693          	addi	a3,a3,-1524 # ffffffffc0207308 <commands+0xa78>
ffffffffc0201904:	00005617          	auipc	a2,0x5
ffffffffc0201908:	39c60613          	addi	a2,a2,924 # ffffffffc0206ca0 <commands+0x410>
ffffffffc020190c:	17d00593          	li	a1,381
ffffffffc0201910:	00006517          	auipc	a0,0x6
ffffffffc0201914:	88050513          	addi	a0,a0,-1920 # ffffffffc0207190 <commands+0x900>
ffffffffc0201918:	8f1fe0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc020191c:	00006697          	auipc	a3,0x6
ffffffffc0201920:	a1c68693          	addi	a3,a3,-1508 # ffffffffc0207338 <commands+0xaa8>
ffffffffc0201924:	00005617          	auipc	a2,0x5
ffffffffc0201928:	37c60613          	addi	a2,a2,892 # ffffffffc0206ca0 <commands+0x410>
ffffffffc020192c:	17e00593          	li	a1,382
ffffffffc0201930:	00006517          	auipc	a0,0x6
ffffffffc0201934:	86050513          	addi	a0,a0,-1952 # ffffffffc0207190 <commands+0x900>
ffffffffc0201938:	8d1fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(vma != NULL);
ffffffffc020193c:	00006697          	auipc	a3,0x6
ffffffffc0201940:	b9c68693          	addi	a3,a3,-1124 # ffffffffc02074d8 <commands+0xc48>
ffffffffc0201944:	00005617          	auipc	a2,0x5
ffffffffc0201948:	35c60613          	addi	a2,a2,860 # ffffffffc0206ca0 <commands+0x410>
ffffffffc020194c:	19d00593          	li	a1,413
ffffffffc0201950:	00006517          	auipc	a0,0x6
ffffffffc0201954:	84050513          	addi	a0,a0,-1984 # ffffffffc0207190 <commands+0x900>
ffffffffc0201958:	8b1fe0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc020195c:	00006697          	auipc	a3,0x6
ffffffffc0201960:	90c68693          	addi	a3,a3,-1780 # ffffffffc0207268 <commands+0x9d8>
ffffffffc0201964:	00005617          	auipc	a2,0x5
ffffffffc0201968:	33c60613          	addi	a2,a2,828 # ffffffffc0206ca0 <commands+0x410>
ffffffffc020196c:	16b00593          	li	a1,363
ffffffffc0201970:	00006517          	auipc	a0,0x6
ffffffffc0201974:	82050513          	addi	a0,a0,-2016 # ffffffffc0207190 <commands+0x900>
ffffffffc0201978:	891fe0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma3 == NULL);
ffffffffc020197c:	00006697          	auipc	a3,0x6
ffffffffc0201980:	95c68693          	addi	a3,a3,-1700 # ffffffffc02072d8 <commands+0xa48>
ffffffffc0201984:	00005617          	auipc	a2,0x5
ffffffffc0201988:	31c60613          	addi	a2,a2,796 # ffffffffc0206ca0 <commands+0x410>
ffffffffc020198c:	17700593          	li	a1,375
ffffffffc0201990:	00006517          	auipc	a0,0x6
ffffffffc0201994:	80050513          	addi	a0,a0,-2048 # ffffffffc0207190 <commands+0x900>
ffffffffc0201998:	871fe0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma2 != NULL);
ffffffffc020199c:	00006697          	auipc	a3,0x6
ffffffffc02019a0:	92c68693          	addi	a3,a3,-1748 # ffffffffc02072c8 <commands+0xa38>
ffffffffc02019a4:	00005617          	auipc	a2,0x5
ffffffffc02019a8:	2fc60613          	addi	a2,a2,764 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02019ac:	17500593          	li	a1,373
ffffffffc02019b0:	00005517          	auipc	a0,0x5
ffffffffc02019b4:	7e050513          	addi	a0,a0,2016 # ffffffffc0207190 <commands+0x900>
ffffffffc02019b8:	851fe0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma1 != NULL);
ffffffffc02019bc:	00006697          	auipc	a3,0x6
ffffffffc02019c0:	8fc68693          	addi	a3,a3,-1796 # ffffffffc02072b8 <commands+0xa28>
ffffffffc02019c4:	00005617          	auipc	a2,0x5
ffffffffc02019c8:	2dc60613          	addi	a2,a2,732 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02019cc:	17300593          	li	a1,371
ffffffffc02019d0:	00005517          	auipc	a0,0x5
ffffffffc02019d4:	7c050513          	addi	a0,a0,1984 # ffffffffc0207190 <commands+0x900>
ffffffffc02019d8:	831fe0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma5 == NULL);
ffffffffc02019dc:	00006697          	auipc	a3,0x6
ffffffffc02019e0:	91c68693          	addi	a3,a3,-1764 # ffffffffc02072f8 <commands+0xa68>
ffffffffc02019e4:	00005617          	auipc	a2,0x5
ffffffffc02019e8:	2bc60613          	addi	a2,a2,700 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02019ec:	17b00593          	li	a1,379
ffffffffc02019f0:	00005517          	auipc	a0,0x5
ffffffffc02019f4:	7a050513          	addi	a0,a0,1952 # ffffffffc0207190 <commands+0x900>
ffffffffc02019f8:	811fe0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert(vma4 == NULL);
ffffffffc02019fc:	00006697          	auipc	a3,0x6
ffffffffc0201a00:	8ec68693          	addi	a3,a3,-1812 # ffffffffc02072e8 <commands+0xa58>
ffffffffc0201a04:	00005617          	auipc	a2,0x5
ffffffffc0201a08:	29c60613          	addi	a2,a2,668 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201a0c:	17900593          	li	a1,377
ffffffffc0201a10:	00005517          	auipc	a0,0x5
ffffffffc0201a14:	78050513          	addi	a0,a0,1920 # ffffffffc0207190 <commands+0x900>
ffffffffc0201a18:	ff0fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc0201a1c:	00006697          	auipc	a3,0x6
ffffffffc0201a20:	9ac68693          	addi	a3,a3,-1620 # ffffffffc02073c8 <commands+0xb38>
ffffffffc0201a24:	00005617          	auipc	a2,0x5
ffffffffc0201a28:	27c60613          	addi	a2,a2,636 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201a2c:	19600593          	li	a1,406
ffffffffc0201a30:	00005517          	auipc	a0,0x5
ffffffffc0201a34:	76050513          	addi	a0,a0,1888 # ffffffffc0207190 <commands+0x900>
ffffffffc0201a38:	fd0fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(mm != NULL);
ffffffffc0201a3c:	00005697          	auipc	a3,0x5
ffffffffc0201a40:	7dc68693          	addi	a3,a3,2012 # ffffffffc0207218 <commands+0x988>
ffffffffc0201a44:	00005617          	auipc	a2,0x5
ffffffffc0201a48:	25c60613          	addi	a2,a2,604 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201a4c:	15700593          	li	a1,343
ffffffffc0201a50:	00005517          	auipc	a0,0x5
ffffffffc0201a54:	74050513          	addi	a0,a0,1856 # ffffffffc0207190 <commands+0x900>
ffffffffc0201a58:	fb0fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0201a5c:	00006697          	auipc	a3,0x6
ffffffffc0201a60:	a1c68693          	addi	a3,a3,-1508 # ffffffffc0207478 <commands+0xbe8>
ffffffffc0201a64:	00005617          	auipc	a2,0x5
ffffffffc0201a68:	23c60613          	addi	a2,a2,572 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201a6c:	1bb00593          	li	a1,443
ffffffffc0201a70:	00005517          	auipc	a0,0x5
ffffffffc0201a74:	72050513          	addi	a0,a0,1824 # ffffffffc0207190 <commands+0x900>
ffffffffc0201a78:	f90fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    return KADDR(page2pa(page));
ffffffffc0201a7c:	00006617          	auipc	a2,0x6
ffffffffc0201a80:	9d460613          	addi	a2,a2,-1580 # ffffffffc0207450 <commands+0xbc0>
ffffffffc0201a84:	06a00593          	li	a1,106
ffffffffc0201a88:	00006517          	auipc	a0,0x6
ffffffffc0201a8c:	9b850513          	addi	a0,a0,-1608 # ffffffffc0207440 <commands+0xbb0>
ffffffffc0201a90:	f78fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0201a94:	00006697          	auipc	a3,0x6
ffffffffc0201a98:	94c68693          	addi	a3,a3,-1716 # ffffffffc02073e0 <commands+0xb50>
ffffffffc0201a9c:	00005617          	auipc	a2,0x5
ffffffffc0201aa0:	20460613          	addi	a2,a2,516 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201aa4:	19a00593          	li	a1,410
ffffffffc0201aa8:	00005517          	auipc	a0,0x5
ffffffffc0201aac:	6e850513          	addi	a0,a0,1768 # ffffffffc0207190 <commands+0x900>
ffffffffc0201ab0:	f58fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0201ab4:	00006697          	auipc	a3,0x6
ffffffffc0201ab8:	93c68693          	addi	a3,a3,-1732 # ffffffffc02073f0 <commands+0xb60>
ffffffffc0201abc:	00005617          	auipc	a2,0x5
ffffffffc0201ac0:	1e460613          	addi	a2,a2,484 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201ac4:	1a200593          	li	a1,418
ffffffffc0201ac8:	00005517          	auipc	a0,0x5
ffffffffc0201acc:	6c850513          	addi	a0,a0,1736 # ffffffffc0207190 <commands+0x900>
ffffffffc0201ad0:	f38fe0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201ad4:	00006617          	auipc	a2,0x6
ffffffffc0201ad8:	94c60613          	addi	a2,a2,-1716 # ffffffffc0207420 <commands+0xb90>
ffffffffc0201adc:	06300593          	li	a1,99
ffffffffc0201ae0:	00006517          	auipc	a0,0x6
ffffffffc0201ae4:	96050513          	addi	a0,a0,-1696 # ffffffffc0207440 <commands+0xbb0>
ffffffffc0201ae8:	f20fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(sum == 0);
ffffffffc0201aec:	00006697          	auipc	a3,0x6
ffffffffc0201af0:	92468693          	addi	a3,a3,-1756 # ffffffffc0207410 <commands+0xb80>
ffffffffc0201af4:	00005617          	auipc	a2,0x5
ffffffffc0201af8:	1ac60613          	addi	a2,a2,428 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201afc:	1ae00593          	li	a1,430
ffffffffc0201b00:	00005517          	auipc	a0,0x5
ffffffffc0201b04:	69050513          	addi	a0,a0,1680 # ffffffffc0207190 <commands+0x900>
ffffffffc0201b08:	f00fe0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0201b0c <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc0201b0c:	7139                	addi	sp,sp,-64
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0201b0e:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc0201b10:	f822                	sd	s0,48(sp)
ffffffffc0201b12:	f426                	sd	s1,40(sp)
ffffffffc0201b14:	fc06                	sd	ra,56(sp)
ffffffffc0201b16:	f04a                	sd	s2,32(sp)
ffffffffc0201b18:	ec4e                	sd	s3,24(sp)
ffffffffc0201b1a:	8432                	mv	s0,a2
ffffffffc0201b1c:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0201b1e:	f8cff0ef          	jal	ra,ffffffffc02012aa <find_vma>

    pgfault_num++;
ffffffffc0201b22:	000b1797          	auipc	a5,0xb1
ffffffffc0201b26:	ea67a783          	lw	a5,-346(a5) # ffffffffc02b29c8 <pgfault_num>
ffffffffc0201b2a:	2785                	addiw	a5,a5,1
ffffffffc0201b2c:	000b1717          	auipc	a4,0xb1
ffffffffc0201b30:	e8f72e23          	sw	a5,-356(a4) # ffffffffc02b29c8 <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc0201b34:	cd51                	beqz	a0,ffffffffc0201bd0 <do_pgfault+0xc4>
ffffffffc0201b36:	651c                	ld	a5,8(a0)
ffffffffc0201b38:	08f46c63          	bltu	s0,a5,ffffffffc0201bd0 <do_pgfault+0xc4>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0201b3c:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc0201b3e:	49c1                	li	s3,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0201b40:	8b89                	andi	a5,a5,2
ffffffffc0201b42:	e3a1                	bnez	a5,ffffffffc0201b82 <do_pgfault+0x76>
        perm |= READ_WRITE;
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0201b44:	75fd                	lui	a1,0xfffff
    // }


    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0201b46:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0201b48:	8c6d                	and	s0,s0,a1
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0201b4a:	4605                	li	a2,1
ffffffffc0201b4c:	85a2                	mv	a1,s0
ffffffffc0201b4e:	21b010ef          	jal	ra,ffffffffc0203568 <get_pte>
ffffffffc0201b52:	c145                	beqz	a0,ffffffffc0201bf2 <do_pgfault+0xe6>
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
ffffffffc0201b54:	610c                	ld	a1,0(a0)
ffffffffc0201b56:	cdb1                	beqz	a1,ffffffffc0201bb2 <do_pgfault+0xa6>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc0201b58:	000b1797          	auipc	a5,0xb1
ffffffffc0201b5c:	e907a783          	lw	a5,-368(a5) # ffffffffc02b29e8 <swap_init_ok>
ffffffffc0201b60:	c3c9                	beqz	a5,ffffffffc0201be2 <do_pgfault+0xd6>
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
            // cprintf("do_pgfault called!!!\n");
            if((ret = swap_in(mm,addr,&page)) != 0) {
ffffffffc0201b62:	0030                	addi	a2,sp,8
ffffffffc0201b64:	85a2                	mv	a1,s0
ffffffffc0201b66:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc0201b68:	e402                	sd	zero,8(sp)
            if((ret = swap_in(mm,addr,&page)) != 0) {
ffffffffc0201b6a:	593000ef          	jal	ra,ffffffffc02028fc <swap_in>
ffffffffc0201b6e:	892a                	mv	s2,a0
ffffffffc0201b70:	c919                	beqz	a0,ffffffffc0201b86 <do_pgfault+0x7a>
        }
   }
   ret = 0;
failed:
    return ret;
}
ffffffffc0201b72:	70e2                	ld	ra,56(sp)
ffffffffc0201b74:	7442                	ld	s0,48(sp)
ffffffffc0201b76:	74a2                	ld	s1,40(sp)
ffffffffc0201b78:	69e2                	ld	s3,24(sp)
ffffffffc0201b7a:	854a                	mv	a0,s2
ffffffffc0201b7c:	7902                	ld	s2,32(sp)
ffffffffc0201b7e:	6121                	addi	sp,sp,64
ffffffffc0201b80:	8082                	ret
        perm |= READ_WRITE;
ffffffffc0201b82:	49dd                	li	s3,23
ffffffffc0201b84:	b7c1                	j	ffffffffc0201b44 <do_pgfault+0x38>
            page_insert(mm->pgdir,page,addr,perm);
ffffffffc0201b86:	65a2                	ld	a1,8(sp)
ffffffffc0201b88:	6c88                	ld	a0,24(s1)
ffffffffc0201b8a:	86ce                	mv	a3,s3
ffffffffc0201b8c:	8622                	mv	a2,s0
ffffffffc0201b8e:	074020ef          	jal	ra,ffffffffc0203c02 <page_insert>
            swap_map_swappable(mm,addr,page,1);
ffffffffc0201b92:	6622                	ld	a2,8(sp)
ffffffffc0201b94:	85a2                	mv	a1,s0
ffffffffc0201b96:	8526                	mv	a0,s1
ffffffffc0201b98:	4685                	li	a3,1
ffffffffc0201b9a:	443000ef          	jal	ra,ffffffffc02027dc <swap_map_swappable>
            page->pra_vaddr = addr;
ffffffffc0201b9e:	67a2                	ld	a5,8(sp)
}
ffffffffc0201ba0:	70e2                	ld	ra,56(sp)
ffffffffc0201ba2:	74a2                	ld	s1,40(sp)
            page->pra_vaddr = addr;
ffffffffc0201ba4:	ff80                	sd	s0,56(a5)
}
ffffffffc0201ba6:	7442                	ld	s0,48(sp)
ffffffffc0201ba8:	69e2                	ld	s3,24(sp)
ffffffffc0201baa:	854a                	mv	a0,s2
ffffffffc0201bac:	7902                	ld	s2,32(sp)
ffffffffc0201bae:	6121                	addi	sp,sp,64
ffffffffc0201bb0:	8082                	ret
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0201bb2:	6c88                	ld	a0,24(s1)
ffffffffc0201bb4:	864e                	mv	a2,s3
ffffffffc0201bb6:	85a2                	mv	a1,s0
ffffffffc0201bb8:	711020ef          	jal	ra,ffffffffc0204ac8 <pgdir_alloc_page>
   ret = 0;
ffffffffc0201bbc:	4901                	li	s2,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0201bbe:	f955                	bnez	a0,ffffffffc0201b72 <do_pgfault+0x66>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0201bc0:	00006517          	auipc	a0,0x6
ffffffffc0201bc4:	97850513          	addi	a0,a0,-1672 # ffffffffc0207538 <commands+0xca8>
ffffffffc0201bc8:	d04fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM;
ffffffffc0201bcc:	5971                	li	s2,-4
            goto failed;
ffffffffc0201bce:	b755                	j	ffffffffc0201b72 <do_pgfault+0x66>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc0201bd0:	85a2                	mv	a1,s0
ffffffffc0201bd2:	00006517          	auipc	a0,0x6
ffffffffc0201bd6:	91650513          	addi	a0,a0,-1770 # ffffffffc02074e8 <commands+0xc58>
ffffffffc0201bda:	cf2fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    int ret = -E_INVAL;
ffffffffc0201bde:	5975                	li	s2,-3
        goto failed;
ffffffffc0201be0:	bf49                	j	ffffffffc0201b72 <do_pgfault+0x66>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0201be2:	00006517          	auipc	a0,0x6
ffffffffc0201be6:	97e50513          	addi	a0,a0,-1666 # ffffffffc0207560 <commands+0xcd0>
ffffffffc0201bea:	ce2fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM;
ffffffffc0201bee:	5971                	li	s2,-4
            goto failed;
ffffffffc0201bf0:	b749                	j	ffffffffc0201b72 <do_pgfault+0x66>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc0201bf2:	00006517          	auipc	a0,0x6
ffffffffc0201bf6:	92650513          	addi	a0,a0,-1754 # ffffffffc0207518 <commands+0xc88>
ffffffffc0201bfa:	cd2fe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    ret = -E_NO_MEM;
ffffffffc0201bfe:	5971                	li	s2,-4
        goto failed;
ffffffffc0201c00:	bf8d                	j	ffffffffc0201b72 <do_pgfault+0x66>

ffffffffc0201c02 <user_mem_check>:
 * 返回值：
 *   - 若用户空间访问的内存区域有效且权限允许，返回 1（允许访问）
 *   - 若用户空间访问的内存区域无效或权限不允许，返回 0（拒绝访问）
 *   - 若是内核空间地址，则调用 `KERN_ACCESS` 进行检查
 */
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write) {
ffffffffc0201c02:	7179                	addi	sp,sp,-48
ffffffffc0201c04:	f022                	sd	s0,32(sp)
ffffffffc0201c06:	f406                	sd	ra,40(sp)
ffffffffc0201c08:	ec26                	sd	s1,24(sp)
ffffffffc0201c0a:	e84a                	sd	s2,16(sp)
ffffffffc0201c0c:	e44e                	sd	s3,8(sp)
ffffffffc0201c0e:	e052                	sd	s4,0(sp)
ffffffffc0201c10:	842e                	mv	s0,a1
    if (mm != NULL) {  // 如果是用户进程，检查用户空间内存访问
ffffffffc0201c12:	c135                	beqz	a0,ffffffffc0201c76 <user_mem_check+0x74>
        // 检查指定地址范围是否在用户地址空间内
        if (!USER_ACCESS(addr, addr + len)) {
ffffffffc0201c14:	002007b7          	lui	a5,0x200
ffffffffc0201c18:	04f5e663          	bltu	a1,a5,ffffffffc0201c64 <user_mem_check+0x62>
ffffffffc0201c1c:	00c584b3          	add	s1,a1,a2
ffffffffc0201c20:	0495f263          	bgeu	a1,s1,ffffffffc0201c64 <user_mem_check+0x62>
ffffffffc0201c24:	4785                	li	a5,1
ffffffffc0201c26:	07fe                	slli	a5,a5,0x1f
ffffffffc0201c28:	0297ee63          	bltu	a5,s1,ffffffffc0201c64 <user_mem_check+0x62>
ffffffffc0201c2c:	892a                	mv	s2,a0
ffffffffc0201c2e:	89b6                	mv	s3,a3
                return 0;  // 如果权限不匹配，返回 0（拒绝访问）
            }
            
            // 如果是写操作且是栈区域，检查是否越过栈的起始地址（栈的第一页禁止写）
            if (write && (vma->vm_flags & VM_STACK)) {
                if (start < vma->vm_start + PGSIZE) {  // 检查是否栈的开始部分，且大小为页面大小
ffffffffc0201c30:	6a05                	lui	s4,0x1
ffffffffc0201c32:	a821                	j	ffffffffc0201c4a <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0201c34:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE) {  // 检查是否栈的开始部分，且大小为页面大小
ffffffffc0201c38:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc0201c3a:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0201c3c:	c685                	beqz	a3,ffffffffc0201c64 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc0201c3e:	c399                	beqz	a5,ffffffffc0201c44 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE) {  // 检查是否栈的开始部分，且大小为页面大小
ffffffffc0201c40:	02e46263          	bltu	s0,a4,ffffffffc0201c64 <user_mem_check+0x62>
                    return 0;  // 如果写操作超出栈的允许范围，返回 0（拒绝访问）
                }
            }
            
            // 更新起始地址为当前虚拟内存区域的结束地址，继续检查剩余区域
            start = vma->vm_end;
ffffffffc0201c44:	6900                	ld	s0,16(a0)
        while (start < end) {
ffffffffc0201c46:	04947663          	bgeu	s0,s1,ffffffffc0201c92 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start) {
ffffffffc0201c4a:	85a2                	mv	a1,s0
ffffffffc0201c4c:	854a                	mv	a0,s2
ffffffffc0201c4e:	e5cff0ef          	jal	ra,ffffffffc02012aa <find_vma>
ffffffffc0201c52:	c909                	beqz	a0,ffffffffc0201c64 <user_mem_check+0x62>
ffffffffc0201c54:	6518                	ld	a4,8(a0)
ffffffffc0201c56:	00e46763          	bltu	s0,a4,ffffffffc0201c64 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0201c5a:	4d1c                	lw	a5,24(a0)
ffffffffc0201c5c:	fc099ce3          	bnez	s3,ffffffffc0201c34 <user_mem_check+0x32>
ffffffffc0201c60:	8b85                	andi	a5,a5,1
ffffffffc0201c62:	f3ed                	bnez	a5,ffffffffc0201c44 <user_mem_check+0x42>
            return 0;  // 如果不在用户空间内，返回 0（拒绝访问）
ffffffffc0201c64:	4501                	li	a0,0
        return 1;  // 如果所有检查通过，返回 1（允许访问）
    }

    // 如果是内核地址空间，使用内核空间访问权限检查
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0201c66:	70a2                	ld	ra,40(sp)
ffffffffc0201c68:	7402                	ld	s0,32(sp)
ffffffffc0201c6a:	64e2                	ld	s1,24(sp)
ffffffffc0201c6c:	6942                	ld	s2,16(sp)
ffffffffc0201c6e:	69a2                	ld	s3,8(sp)
ffffffffc0201c70:	6a02                	ld	s4,0(sp)
ffffffffc0201c72:	6145                	addi	sp,sp,48
ffffffffc0201c74:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0201c76:	c02007b7          	lui	a5,0xc0200
ffffffffc0201c7a:	4501                	li	a0,0
ffffffffc0201c7c:	fef5e5e3          	bltu	a1,a5,ffffffffc0201c66 <user_mem_check+0x64>
ffffffffc0201c80:	962e                	add	a2,a2,a1
ffffffffc0201c82:	fec5f2e3          	bgeu	a1,a2,ffffffffc0201c66 <user_mem_check+0x64>
ffffffffc0201c86:	c8000537          	lui	a0,0xc8000
ffffffffc0201c8a:	0505                	addi	a0,a0,1
ffffffffc0201c8c:	00a63533          	sltu	a0,a2,a0
ffffffffc0201c90:	bfd9                	j	ffffffffc0201c66 <user_mem_check+0x64>
        return 1;  // 如果所有检查通过，返回 1（允许访问）
ffffffffc0201c92:	4505                	li	a0,1
ffffffffc0201c94:	bfc9                	j	ffffffffc0201c66 <user_mem_check+0x64>

ffffffffc0201c96 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201c96:	c94d                	beqz	a0,ffffffffc0201d48 <slob_free+0xb2>
{
ffffffffc0201c98:	1141                	addi	sp,sp,-16
ffffffffc0201c9a:	e022                	sd	s0,0(sp)
ffffffffc0201c9c:	e406                	sd	ra,8(sp)
ffffffffc0201c9e:	842a                	mv	s0,a0
		return;

	if (size)
ffffffffc0201ca0:	e9c1                	bnez	a1,ffffffffc0201d30 <slob_free+0x9a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ca2:	100027f3          	csrr	a5,sstatus
ffffffffc0201ca6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201ca8:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201caa:	ebd9                	bnez	a5,ffffffffc0201d40 <slob_free+0xaa>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201cac:	000a6617          	auipc	a2,0xa6
ffffffffc0201cb0:	82460613          	addi	a2,a2,-2012 # ffffffffc02a74d0 <slobfree>
ffffffffc0201cb4:	621c                	ld	a5,0(a2)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201cb6:	873e                	mv	a4,a5
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201cb8:	679c                	ld	a5,8(a5)
ffffffffc0201cba:	02877a63          	bgeu	a4,s0,ffffffffc0201cee <slob_free+0x58>
ffffffffc0201cbe:	00f46463          	bltu	s0,a5,ffffffffc0201cc6 <slob_free+0x30>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201cc2:	fef76ae3          	bltu	a4,a5,ffffffffc0201cb6 <slob_free+0x20>
			break;

	if (b + b->units == cur->next) {
ffffffffc0201cc6:	400c                	lw	a1,0(s0)
ffffffffc0201cc8:	00459693          	slli	a3,a1,0x4
ffffffffc0201ccc:	96a2                	add	a3,a3,s0
ffffffffc0201cce:	02d78a63          	beq	a5,a3,ffffffffc0201d02 <slob_free+0x6c>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc0201cd2:	4314                	lw	a3,0(a4)
		b->next = cur->next;
ffffffffc0201cd4:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) {
ffffffffc0201cd6:	00469793          	slli	a5,a3,0x4
ffffffffc0201cda:	97ba                	add	a5,a5,a4
ffffffffc0201cdc:	02f40e63          	beq	s0,a5,ffffffffc0201d18 <slob_free+0x82>
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;
ffffffffc0201ce0:	e700                	sd	s0,8(a4)

	slobfree = cur;
ffffffffc0201ce2:	e218                	sd	a4,0(a2)
    if (flag) {
ffffffffc0201ce4:	e129                	bnez	a0,ffffffffc0201d26 <slob_free+0x90>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201ce6:	60a2                	ld	ra,8(sp)
ffffffffc0201ce8:	6402                	ld	s0,0(sp)
ffffffffc0201cea:	0141                	addi	sp,sp,16
ffffffffc0201cec:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201cee:	fcf764e3          	bltu	a4,a5,ffffffffc0201cb6 <slob_free+0x20>
ffffffffc0201cf2:	fcf472e3          	bgeu	s0,a5,ffffffffc0201cb6 <slob_free+0x20>
	if (b + b->units == cur->next) {
ffffffffc0201cf6:	400c                	lw	a1,0(s0)
ffffffffc0201cf8:	00459693          	slli	a3,a1,0x4
ffffffffc0201cfc:	96a2                	add	a3,a3,s0
ffffffffc0201cfe:	fcd79ae3          	bne	a5,a3,ffffffffc0201cd2 <slob_free+0x3c>
		b->units += cur->next->units;
ffffffffc0201d02:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201d04:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201d06:	9db5                	addw	a1,a1,a3
ffffffffc0201d08:	c00c                	sw	a1,0(s0)
	if (cur + cur->units == b) {
ffffffffc0201d0a:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201d0c:	e41c                	sd	a5,8(s0)
	if (cur + cur->units == b) {
ffffffffc0201d0e:	00469793          	slli	a5,a3,0x4
ffffffffc0201d12:	97ba                	add	a5,a5,a4
ffffffffc0201d14:	fcf416e3          	bne	s0,a5,ffffffffc0201ce0 <slob_free+0x4a>
		cur->units += b->units;
ffffffffc0201d18:	401c                	lw	a5,0(s0)
		cur->next = b->next;
ffffffffc0201d1a:	640c                	ld	a1,8(s0)
	slobfree = cur;
ffffffffc0201d1c:	e218                	sd	a4,0(a2)
		cur->units += b->units;
ffffffffc0201d1e:	9ebd                	addw	a3,a3,a5
ffffffffc0201d20:	c314                	sw	a3,0(a4)
		cur->next = b->next;
ffffffffc0201d22:	e70c                	sd	a1,8(a4)
ffffffffc0201d24:	d169                	beqz	a0,ffffffffc0201ce6 <slob_free+0x50>
}
ffffffffc0201d26:	6402                	ld	s0,0(sp)
ffffffffc0201d28:	60a2                	ld	ra,8(sp)
ffffffffc0201d2a:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0201d2c:	917fe06f          	j	ffffffffc0200642 <intr_enable>
		b->units = SLOB_UNITS(size);
ffffffffc0201d30:	25bd                	addiw	a1,a1,15
ffffffffc0201d32:	8191                	srli	a1,a1,0x4
ffffffffc0201d34:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d36:	100027f3          	csrr	a5,sstatus
ffffffffc0201d3a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201d3c:	4501                	li	a0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d3e:	d7bd                	beqz	a5,ffffffffc0201cac <slob_free+0x16>
        intr_disable();
ffffffffc0201d40:	909fe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc0201d44:	4505                	li	a0,1
ffffffffc0201d46:	b79d                	j	ffffffffc0201cac <slob_free+0x16>
ffffffffc0201d48:	8082                	ret

ffffffffc0201d4a <__slob_get_free_pages.constprop.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201d4a:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201d4c:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201d4e:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201d52:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201d54:	708010ef          	jal	ra,ffffffffc020345c <alloc_pages>
  if(!page)
ffffffffc0201d58:	c91d                	beqz	a0,ffffffffc0201d8e <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201d5a:	000b1697          	auipc	a3,0xb1
ffffffffc0201d5e:	cae6b683          	ld	a3,-850(a3) # ffffffffc02b2a08 <pages>
ffffffffc0201d62:	8d15                	sub	a0,a0,a3
ffffffffc0201d64:	8519                	srai	a0,a0,0x6
ffffffffc0201d66:	00007697          	auipc	a3,0x7
ffffffffc0201d6a:	f5a6b683          	ld	a3,-166(a3) # ffffffffc0208cc0 <nbase>
ffffffffc0201d6e:	9536                	add	a0,a0,a3
    return KADDR(page2pa(page));
ffffffffc0201d70:	00c51793          	slli	a5,a0,0xc
ffffffffc0201d74:	83b1                	srli	a5,a5,0xc
ffffffffc0201d76:	000b1717          	auipc	a4,0xb1
ffffffffc0201d7a:	c8a73703          	ld	a4,-886(a4) # ffffffffc02b2a00 <npage>
    return page2ppn(page) << PGSHIFT;
ffffffffc0201d7e:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201d80:	00e7fa63          	bgeu	a5,a4,ffffffffc0201d94 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201d84:	000b1697          	auipc	a3,0xb1
ffffffffc0201d88:	c946b683          	ld	a3,-876(a3) # ffffffffc02b2a18 <va_pa_offset>
ffffffffc0201d8c:	9536                	add	a0,a0,a3
}
ffffffffc0201d8e:	60a2                	ld	ra,8(sp)
ffffffffc0201d90:	0141                	addi	sp,sp,16
ffffffffc0201d92:	8082                	ret
ffffffffc0201d94:	86aa                	mv	a3,a0
ffffffffc0201d96:	00005617          	auipc	a2,0x5
ffffffffc0201d9a:	6ba60613          	addi	a2,a2,1722 # ffffffffc0207450 <commands+0xbc0>
ffffffffc0201d9e:	06a00593          	li	a1,106
ffffffffc0201da2:	00005517          	auipc	a0,0x5
ffffffffc0201da6:	69e50513          	addi	a0,a0,1694 # ffffffffc0207440 <commands+0xbb0>
ffffffffc0201daa:	c5efe0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0201dae <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201dae:	1101                	addi	sp,sp,-32
ffffffffc0201db0:	ec06                	sd	ra,24(sp)
ffffffffc0201db2:	e822                	sd	s0,16(sp)
ffffffffc0201db4:	e426                	sd	s1,8(sp)
ffffffffc0201db6:	e04a                	sd	s2,0(sp)
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201db8:	01050713          	addi	a4,a0,16
ffffffffc0201dbc:	6785                	lui	a5,0x1
ffffffffc0201dbe:	0cf77363          	bgeu	a4,a5,ffffffffc0201e84 <slob_alloc.constprop.0+0xd6>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201dc2:	00f50493          	addi	s1,a0,15
ffffffffc0201dc6:	8091                	srli	s1,s1,0x4
ffffffffc0201dc8:	2481                	sext.w	s1,s1
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201dca:	10002673          	csrr	a2,sstatus
ffffffffc0201dce:	8a09                	andi	a2,a2,2
ffffffffc0201dd0:	e25d                	bnez	a2,ffffffffc0201e76 <slob_alloc.constprop.0+0xc8>
	prev = slobfree;
ffffffffc0201dd2:	000a5917          	auipc	s2,0xa5
ffffffffc0201dd6:	6fe90913          	addi	s2,s2,1790 # ffffffffc02a74d0 <slobfree>
ffffffffc0201dda:	00093683          	ld	a3,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201dde:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201de0:	4398                	lw	a4,0(a5)
ffffffffc0201de2:	08975e63          	bge	a4,s1,ffffffffc0201e7e <slob_alloc.constprop.0+0xd0>
		if (cur == slobfree) {
ffffffffc0201de6:	00f68b63          	beq	a3,a5,ffffffffc0201dfc <slob_alloc.constprop.0+0x4e>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201dea:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201dec:	4018                	lw	a4,0(s0)
ffffffffc0201dee:	02975a63          	bge	a4,s1,ffffffffc0201e22 <slob_alloc.constprop.0+0x74>
		if (cur == slobfree) {
ffffffffc0201df2:	00093683          	ld	a3,0(s2)
ffffffffc0201df6:	87a2                	mv	a5,s0
ffffffffc0201df8:	fef699e3          	bne	a3,a5,ffffffffc0201dea <slob_alloc.constprop.0+0x3c>
    if (flag) {
ffffffffc0201dfc:	ee31                	bnez	a2,ffffffffc0201e58 <slob_alloc.constprop.0+0xaa>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201dfe:	4501                	li	a0,0
ffffffffc0201e00:	f4bff0ef          	jal	ra,ffffffffc0201d4a <__slob_get_free_pages.constprop.0>
ffffffffc0201e04:	842a                	mv	s0,a0
			if (!cur)
ffffffffc0201e06:	cd05                	beqz	a0,ffffffffc0201e3e <slob_alloc.constprop.0+0x90>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201e08:	6585                	lui	a1,0x1
ffffffffc0201e0a:	e8dff0ef          	jal	ra,ffffffffc0201c96 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201e0e:	10002673          	csrr	a2,sstatus
ffffffffc0201e12:	8a09                	andi	a2,a2,2
ffffffffc0201e14:	ee05                	bnez	a2,ffffffffc0201e4c <slob_alloc.constprop.0+0x9e>
			cur = slobfree;
ffffffffc0201e16:	00093783          	ld	a5,0(s2)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201e1a:	6780                	ld	s0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201e1c:	4018                	lw	a4,0(s0)
ffffffffc0201e1e:	fc974ae3          	blt	a4,s1,ffffffffc0201df2 <slob_alloc.constprop.0+0x44>
			if (cur->units == units) /* exact fit? */
ffffffffc0201e22:	04e48763          	beq	s1,a4,ffffffffc0201e70 <slob_alloc.constprop.0+0xc2>
				prev->next = cur + units;
ffffffffc0201e26:	00449693          	slli	a3,s1,0x4
ffffffffc0201e2a:	96a2                	add	a3,a3,s0
ffffffffc0201e2c:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201e2e:	640c                	ld	a1,8(s0)
				prev->next->units = cur->units - units;
ffffffffc0201e30:	9f05                	subw	a4,a4,s1
ffffffffc0201e32:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201e34:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201e36:	c004                	sw	s1,0(s0)
			slobfree = prev;
ffffffffc0201e38:	00f93023          	sd	a5,0(s2)
    if (flag) {
ffffffffc0201e3c:	e20d                	bnez	a2,ffffffffc0201e5e <slob_alloc.constprop.0+0xb0>
}
ffffffffc0201e3e:	60e2                	ld	ra,24(sp)
ffffffffc0201e40:	8522                	mv	a0,s0
ffffffffc0201e42:	6442                	ld	s0,16(sp)
ffffffffc0201e44:	64a2                	ld	s1,8(sp)
ffffffffc0201e46:	6902                	ld	s2,0(sp)
ffffffffc0201e48:	6105                	addi	sp,sp,32
ffffffffc0201e4a:	8082                	ret
        intr_disable();
ffffffffc0201e4c:	ffcfe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
			cur = slobfree;
ffffffffc0201e50:	00093783          	ld	a5,0(s2)
        return 1;
ffffffffc0201e54:	4605                	li	a2,1
ffffffffc0201e56:	b7d1                	j	ffffffffc0201e1a <slob_alloc.constprop.0+0x6c>
        intr_enable();
ffffffffc0201e58:	feafe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0201e5c:	b74d                	j	ffffffffc0201dfe <slob_alloc.constprop.0+0x50>
ffffffffc0201e5e:	fe4fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
}
ffffffffc0201e62:	60e2                	ld	ra,24(sp)
ffffffffc0201e64:	8522                	mv	a0,s0
ffffffffc0201e66:	6442                	ld	s0,16(sp)
ffffffffc0201e68:	64a2                	ld	s1,8(sp)
ffffffffc0201e6a:	6902                	ld	s2,0(sp)
ffffffffc0201e6c:	6105                	addi	sp,sp,32
ffffffffc0201e6e:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201e70:	6418                	ld	a4,8(s0)
ffffffffc0201e72:	e798                	sd	a4,8(a5)
ffffffffc0201e74:	b7d1                	j	ffffffffc0201e38 <slob_alloc.constprop.0+0x8a>
        intr_disable();
ffffffffc0201e76:	fd2fe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc0201e7a:	4605                	li	a2,1
ffffffffc0201e7c:	bf99                	j	ffffffffc0201dd2 <slob_alloc.constprop.0+0x24>
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201e7e:	843e                	mv	s0,a5
ffffffffc0201e80:	87b6                	mv	a5,a3
ffffffffc0201e82:	b745                	j	ffffffffc0201e22 <slob_alloc.constprop.0+0x74>
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201e84:	00005697          	auipc	a3,0x5
ffffffffc0201e88:	70468693          	addi	a3,a3,1796 # ffffffffc0207588 <commands+0xcf8>
ffffffffc0201e8c:	00005617          	auipc	a2,0x5
ffffffffc0201e90:	e1460613          	addi	a2,a2,-492 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0201e94:	06400593          	li	a1,100
ffffffffc0201e98:	00005517          	auipc	a0,0x5
ffffffffc0201e9c:	71050513          	addi	a0,a0,1808 # ffffffffc02075a8 <commands+0xd18>
ffffffffc0201ea0:	b68fe0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0201ea4 <kmalloc_init>:
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
ffffffffc0201ea4:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc0201ea6:	00005517          	auipc	a0,0x5
ffffffffc0201eaa:	71a50513          	addi	a0,a0,1818 # ffffffffc02075c0 <commands+0xd30>
kmalloc_init(void) {
ffffffffc0201eae:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc0201eb0:	a1cfe0ef          	jal	ra,ffffffffc02000cc <cprintf>
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201eb4:	60a2                	ld	ra,8(sp)
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201eb6:	00005517          	auipc	a0,0x5
ffffffffc0201eba:	72250513          	addi	a0,a0,1826 # ffffffffc02075d8 <commands+0xd48>
}
ffffffffc0201ebe:	0141                	addi	sp,sp,16
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201ec0:	a0cfe06f          	j	ffffffffc02000cc <cprintf>

ffffffffc0201ec4 <kallocated>:
}

size_t
kallocated(void) {
   return slob_allocated();
}
ffffffffc0201ec4:	4501                	li	a0,0
ffffffffc0201ec6:	8082                	ret

ffffffffc0201ec8 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201ec8:	1101                	addi	sp,sp,-32
ffffffffc0201eca:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201ecc:	6905                	lui	s2,0x1
{
ffffffffc0201ece:	e822                	sd	s0,16(sp)
ffffffffc0201ed0:	ec06                	sd	ra,24(sp)
ffffffffc0201ed2:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201ed4:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8be1>
{
ffffffffc0201ed8:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201eda:	04a7f963          	bgeu	a5,a0,ffffffffc0201f2c <kmalloc+0x64>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201ede:	4561                	li	a0,24
ffffffffc0201ee0:	ecfff0ef          	jal	ra,ffffffffc0201dae <slob_alloc.constprop.0>
ffffffffc0201ee4:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201ee6:	c929                	beqz	a0,ffffffffc0201f38 <kmalloc+0x70>
	bb->order = find_order(size);
ffffffffc0201ee8:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201eec:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201eee:	00f95763          	bge	s2,a5,ffffffffc0201efc <kmalloc+0x34>
ffffffffc0201ef2:	6705                	lui	a4,0x1
ffffffffc0201ef4:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201ef6:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201ef8:	fef74ee3          	blt	a4,a5,ffffffffc0201ef4 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201efc:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201efe:	e4dff0ef          	jal	ra,ffffffffc0201d4a <__slob_get_free_pages.constprop.0>
ffffffffc0201f02:	e488                	sd	a0,8(s1)
ffffffffc0201f04:	842a                	mv	s0,a0
	if (bb->pages) {
ffffffffc0201f06:	c525                	beqz	a0,ffffffffc0201f6e <kmalloc+0xa6>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201f08:	100027f3          	csrr	a5,sstatus
ffffffffc0201f0c:	8b89                	andi	a5,a5,2
ffffffffc0201f0e:	ef8d                	bnez	a5,ffffffffc0201f48 <kmalloc+0x80>
		bb->next = bigblocks;
ffffffffc0201f10:	000b1797          	auipc	a5,0xb1
ffffffffc0201f14:	ac078793          	addi	a5,a5,-1344 # ffffffffc02b29d0 <bigblocks>
ffffffffc0201f18:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201f1a:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201f1c:	e898                	sd	a4,16(s1)
  return __kmalloc(size, 0);
}
ffffffffc0201f1e:	60e2                	ld	ra,24(sp)
ffffffffc0201f20:	8522                	mv	a0,s0
ffffffffc0201f22:	6442                	ld	s0,16(sp)
ffffffffc0201f24:	64a2                	ld	s1,8(sp)
ffffffffc0201f26:	6902                	ld	s2,0(sp)
ffffffffc0201f28:	6105                	addi	sp,sp,32
ffffffffc0201f2a:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201f2c:	0541                	addi	a0,a0,16
ffffffffc0201f2e:	e81ff0ef          	jal	ra,ffffffffc0201dae <slob_alloc.constprop.0>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201f32:	01050413          	addi	s0,a0,16
ffffffffc0201f36:	f565                	bnez	a0,ffffffffc0201f1e <kmalloc+0x56>
ffffffffc0201f38:	4401                	li	s0,0
}
ffffffffc0201f3a:	60e2                	ld	ra,24(sp)
ffffffffc0201f3c:	8522                	mv	a0,s0
ffffffffc0201f3e:	6442                	ld	s0,16(sp)
ffffffffc0201f40:	64a2                	ld	s1,8(sp)
ffffffffc0201f42:	6902                	ld	s2,0(sp)
ffffffffc0201f44:	6105                	addi	sp,sp,32
ffffffffc0201f46:	8082                	ret
        intr_disable();
ffffffffc0201f48:	f00fe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201f4c:	000b1797          	auipc	a5,0xb1
ffffffffc0201f50:	a8478793          	addi	a5,a5,-1404 # ffffffffc02b29d0 <bigblocks>
ffffffffc0201f54:	6398                	ld	a4,0(a5)
		bigblocks = bb;
ffffffffc0201f56:	e384                	sd	s1,0(a5)
		bb->next = bigblocks;
ffffffffc0201f58:	e898                	sd	a4,16(s1)
        intr_enable();
ffffffffc0201f5a:	ee8fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
		return bb->pages;
ffffffffc0201f5e:	6480                	ld	s0,8(s1)
}
ffffffffc0201f60:	60e2                	ld	ra,24(sp)
ffffffffc0201f62:	64a2                	ld	s1,8(sp)
ffffffffc0201f64:	8522                	mv	a0,s0
ffffffffc0201f66:	6442                	ld	s0,16(sp)
ffffffffc0201f68:	6902                	ld	s2,0(sp)
ffffffffc0201f6a:	6105                	addi	sp,sp,32
ffffffffc0201f6c:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201f6e:	45e1                	li	a1,24
ffffffffc0201f70:	8526                	mv	a0,s1
ffffffffc0201f72:	d25ff0ef          	jal	ra,ffffffffc0201c96 <slob_free>
  return __kmalloc(size, 0);
ffffffffc0201f76:	b765                	j	ffffffffc0201f1e <kmalloc+0x56>

ffffffffc0201f78 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201f78:	c169                	beqz	a0,ffffffffc020203a <kfree+0xc2>
{
ffffffffc0201f7a:	1101                	addi	sp,sp,-32
ffffffffc0201f7c:	e822                	sd	s0,16(sp)
ffffffffc0201f7e:	ec06                	sd	ra,24(sp)
ffffffffc0201f80:	e426                	sd	s1,8(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc0201f82:	03451793          	slli	a5,a0,0x34
ffffffffc0201f86:	842a                	mv	s0,a0
ffffffffc0201f88:	e3d9                	bnez	a5,ffffffffc020200e <kfree+0x96>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201f8a:	100027f3          	csrr	a5,sstatus
ffffffffc0201f8e:	8b89                	andi	a5,a5,2
ffffffffc0201f90:	e7d9                	bnez	a5,ffffffffc020201e <kfree+0xa6>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201f92:	000b1797          	auipc	a5,0xb1
ffffffffc0201f96:	a3e7b783          	ld	a5,-1474(a5) # ffffffffc02b29d0 <bigblocks>
    return 0;
ffffffffc0201f9a:	4601                	li	a2,0
ffffffffc0201f9c:	cbad                	beqz	a5,ffffffffc020200e <kfree+0x96>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201f9e:	000b1697          	auipc	a3,0xb1
ffffffffc0201fa2:	a3268693          	addi	a3,a3,-1486 # ffffffffc02b29d0 <bigblocks>
ffffffffc0201fa6:	a021                	j	ffffffffc0201fae <kfree+0x36>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201fa8:	01048693          	addi	a3,s1,16
ffffffffc0201fac:	c3a5                	beqz	a5,ffffffffc020200c <kfree+0x94>
			if (bb->pages == block) {
ffffffffc0201fae:	6798                	ld	a4,8(a5)
ffffffffc0201fb0:	84be                	mv	s1,a5
				*last = bb->next;
ffffffffc0201fb2:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block) {
ffffffffc0201fb4:	fe871ae3          	bne	a4,s0,ffffffffc0201fa8 <kfree+0x30>
				*last = bb->next;
ffffffffc0201fb8:	e29c                	sd	a5,0(a3)
    if (flag) {
ffffffffc0201fba:	ee2d                	bnez	a2,ffffffffc0202034 <kfree+0xbc>
    return pa2page(PADDR(kva));
ffffffffc0201fbc:	c02007b7          	lui	a5,0xc0200
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201fc0:	4098                	lw	a4,0(s1)
ffffffffc0201fc2:	08f46963          	bltu	s0,a5,ffffffffc0202054 <kfree+0xdc>
ffffffffc0201fc6:	000b1697          	auipc	a3,0xb1
ffffffffc0201fca:	a526b683          	ld	a3,-1454(a3) # ffffffffc02b2a18 <va_pa_offset>
ffffffffc0201fce:	8c15                	sub	s0,s0,a3
    if (PPN(pa) >= npage) {
ffffffffc0201fd0:	8031                	srli	s0,s0,0xc
ffffffffc0201fd2:	000b1797          	auipc	a5,0xb1
ffffffffc0201fd6:	a2e7b783          	ld	a5,-1490(a5) # ffffffffc02b2a00 <npage>
ffffffffc0201fda:	06f47163          	bgeu	s0,a5,ffffffffc020203c <kfree+0xc4>
    return &pages[PPN(pa) - nbase];
ffffffffc0201fde:	00007517          	auipc	a0,0x7
ffffffffc0201fe2:	ce253503          	ld	a0,-798(a0) # ffffffffc0208cc0 <nbase>
ffffffffc0201fe6:	8c09                	sub	s0,s0,a0
ffffffffc0201fe8:	041a                	slli	s0,s0,0x6
  free_pages(kva2page(kva), 1 << order);
ffffffffc0201fea:	000b1517          	auipc	a0,0xb1
ffffffffc0201fee:	a1e53503          	ld	a0,-1506(a0) # ffffffffc02b2a08 <pages>
ffffffffc0201ff2:	4585                	li	a1,1
ffffffffc0201ff4:	9522                	add	a0,a0,s0
ffffffffc0201ff6:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201ffa:	4f4010ef          	jal	ra,ffffffffc02034ee <free_pages>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201ffe:	6442                	ld	s0,16(sp)
ffffffffc0202000:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0202002:	8526                	mv	a0,s1
}
ffffffffc0202004:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0202006:	45e1                	li	a1,24
}
ffffffffc0202008:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc020200a:	b171                	j	ffffffffc0201c96 <slob_free>
ffffffffc020200c:	e20d                	bnez	a2,ffffffffc020202e <kfree+0xb6>
ffffffffc020200e:	ff040513          	addi	a0,s0,-16
}
ffffffffc0202012:	6442                	ld	s0,16(sp)
ffffffffc0202014:	60e2                	ld	ra,24(sp)
ffffffffc0202016:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0202018:	4581                	li	a1,0
}
ffffffffc020201a:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc020201c:	b9ad                	j	ffffffffc0201c96 <slob_free>
        intr_disable();
ffffffffc020201e:	e2afe0ef          	jal	ra,ffffffffc0200648 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0202022:	000b1797          	auipc	a5,0xb1
ffffffffc0202026:	9ae7b783          	ld	a5,-1618(a5) # ffffffffc02b29d0 <bigblocks>
        return 1;
ffffffffc020202a:	4605                	li	a2,1
ffffffffc020202c:	fbad                	bnez	a5,ffffffffc0201f9e <kfree+0x26>
        intr_enable();
ffffffffc020202e:	e14fe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0202032:	bff1                	j	ffffffffc020200e <kfree+0x96>
ffffffffc0202034:	e0efe0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0202038:	b751                	j	ffffffffc0201fbc <kfree+0x44>
ffffffffc020203a:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc020203c:	00005617          	auipc	a2,0x5
ffffffffc0202040:	3e460613          	addi	a2,a2,996 # ffffffffc0207420 <commands+0xb90>
ffffffffc0202044:	06300593          	li	a1,99
ffffffffc0202048:	00005517          	auipc	a0,0x5
ffffffffc020204c:	3f850513          	addi	a0,a0,1016 # ffffffffc0207440 <commands+0xbb0>
ffffffffc0202050:	9b8fe0ef          	jal	ra,ffffffffc0200208 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0202054:	86a2                	mv	a3,s0
ffffffffc0202056:	00005617          	auipc	a2,0x5
ffffffffc020205a:	5a260613          	addi	a2,a2,1442 # ffffffffc02075f8 <commands+0xd68>
ffffffffc020205e:	06f00593          	li	a1,111
ffffffffc0202062:	00005517          	auipc	a0,0x5
ffffffffc0202066:	3de50513          	addi	a0,a0,990 # ffffffffc0207440 <commands+0xbb0>
ffffffffc020206a:	99efe0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc020206e <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc020206e:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0202070:	00005617          	auipc	a2,0x5
ffffffffc0202074:	3b060613          	addi	a2,a2,944 # ffffffffc0207420 <commands+0xb90>
ffffffffc0202078:	06300593          	li	a1,99
ffffffffc020207c:	00005517          	auipc	a0,0x5
ffffffffc0202080:	3c450513          	addi	a0,a0,964 # ffffffffc0207440 <commands+0xbb0>
pa2page(uintptr_t pa) {
ffffffffc0202084:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0202086:	982fe0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc020208a <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc020208a:	7135                	addi	sp,sp,-160
ffffffffc020208c:	ed06                	sd	ra,152(sp)
ffffffffc020208e:	e922                	sd	s0,144(sp)
ffffffffc0202090:	e526                	sd	s1,136(sp)
ffffffffc0202092:	e14a                	sd	s2,128(sp)
ffffffffc0202094:	fcce                	sd	s3,120(sp)
ffffffffc0202096:	f8d2                	sd	s4,112(sp)
ffffffffc0202098:	f4d6                	sd	s5,104(sp)
ffffffffc020209a:	f0da                	sd	s6,96(sp)
ffffffffc020209c:	ecde                	sd	s7,88(sp)
ffffffffc020209e:	e8e2                	sd	s8,80(sp)
ffffffffc02020a0:	e4e6                	sd	s9,72(sp)
ffffffffc02020a2:	e0ea                	sd	s10,64(sp)
ffffffffc02020a4:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc02020a6:	2dd020ef          	jal	ra,ffffffffc0204b82 <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc02020aa:	000b1697          	auipc	a3,0xb1
ffffffffc02020ae:	92e6b683          	ld	a3,-1746(a3) # ffffffffc02b29d8 <max_swap_offset>
ffffffffc02020b2:	010007b7          	lui	a5,0x1000
ffffffffc02020b6:	ff968713          	addi	a4,a3,-7
ffffffffc02020ba:	17e1                	addi	a5,a5,-8
ffffffffc02020bc:	42e7e663          	bltu	a5,a4,ffffffffc02024e8 <swap_init+0x45e>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }
     

     sm = &swap_manager_fifo;
ffffffffc02020c0:	000a5797          	auipc	a5,0xa5
ffffffffc02020c4:	3c078793          	addi	a5,a5,960 # ffffffffc02a7480 <swap_manager_fifo>
     int r = sm->init();
ffffffffc02020c8:	6798                	ld	a4,8(a5)
     sm = &swap_manager_fifo;
ffffffffc02020ca:	000b1b97          	auipc	s7,0xb1
ffffffffc02020ce:	916b8b93          	addi	s7,s7,-1770 # ffffffffc02b29e0 <sm>
ffffffffc02020d2:	00fbb023          	sd	a5,0(s7)
     int r = sm->init();
ffffffffc02020d6:	9702                	jalr	a4
ffffffffc02020d8:	892a                	mv	s2,a0
     
     if (r == 0)
ffffffffc02020da:	c10d                	beqz	a0,ffffffffc02020fc <swap_init+0x72>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc02020dc:	60ea                	ld	ra,152(sp)
ffffffffc02020de:	644a                	ld	s0,144(sp)
ffffffffc02020e0:	64aa                	ld	s1,136(sp)
ffffffffc02020e2:	79e6                	ld	s3,120(sp)
ffffffffc02020e4:	7a46                	ld	s4,112(sp)
ffffffffc02020e6:	7aa6                	ld	s5,104(sp)
ffffffffc02020e8:	7b06                	ld	s6,96(sp)
ffffffffc02020ea:	6be6                	ld	s7,88(sp)
ffffffffc02020ec:	6c46                	ld	s8,80(sp)
ffffffffc02020ee:	6ca6                	ld	s9,72(sp)
ffffffffc02020f0:	6d06                	ld	s10,64(sp)
ffffffffc02020f2:	7de2                	ld	s11,56(sp)
ffffffffc02020f4:	854a                	mv	a0,s2
ffffffffc02020f6:	690a                	ld	s2,128(sp)
ffffffffc02020f8:	610d                	addi	sp,sp,160
ffffffffc02020fa:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02020fc:	000bb783          	ld	a5,0(s7)
ffffffffc0202100:	00005517          	auipc	a0,0x5
ffffffffc0202104:	55050513          	addi	a0,a0,1360 # ffffffffc0207650 <commands+0xdc0>
ffffffffc0202108:	000ad417          	auipc	s0,0xad
ffffffffc020210c:	87840413          	addi	s0,s0,-1928 # ffffffffc02ae980 <free_area>
ffffffffc0202110:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc0202112:	4785                	li	a5,1
ffffffffc0202114:	000b1717          	auipc	a4,0xb1
ffffffffc0202118:	8cf72a23          	sw	a5,-1836(a4) # ffffffffc02b29e8 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc020211c:	fb1fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0202120:	641c                	ld	a5,8(s0)

static void
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
ffffffffc0202122:	4d01                	li	s10,0
ffffffffc0202124:	4d81                	li	s11,0
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202126:	34878163          	beq	a5,s0,ffffffffc0202468 <swap_init+0x3de>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc020212a:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020212e:	8b09                	andi	a4,a4,2
ffffffffc0202130:	32070e63          	beqz	a4,ffffffffc020246c <swap_init+0x3e2>
        count ++, total += p->property;
ffffffffc0202134:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202138:	679c                	ld	a5,8(a5)
ffffffffc020213a:	2d85                	addiw	s11,s11,1
ffffffffc020213c:	01a70d3b          	addw	s10,a4,s10
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202140:	fe8795e3          	bne	a5,s0,ffffffffc020212a <swap_init+0xa0>
     }
     assert(total == nr_free_pages());
ffffffffc0202144:	84ea                	mv	s1,s10
ffffffffc0202146:	3e8010ef          	jal	ra,ffffffffc020352e <nr_free_pages>
ffffffffc020214a:	42951763          	bne	a0,s1,ffffffffc0202578 <swap_init+0x4ee>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc020214e:	866a                	mv	a2,s10
ffffffffc0202150:	85ee                	mv	a1,s11
ffffffffc0202152:	00005517          	auipc	a0,0x5
ffffffffc0202156:	54650513          	addi	a0,a0,1350 # ffffffffc0207698 <commands+0xe08>
ffffffffc020215a:	f73fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc020215e:	8d6ff0ef          	jal	ra,ffffffffc0201234 <mm_create>
ffffffffc0202162:	8aaa                	mv	s5,a0
     assert(mm != NULL);
ffffffffc0202164:	46050a63          	beqz	a0,ffffffffc02025d8 <swap_init+0x54e>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc0202168:	000b1797          	auipc	a5,0xb1
ffffffffc020216c:	85878793          	addi	a5,a5,-1960 # ffffffffc02b29c0 <check_mm_struct>
ffffffffc0202170:	6398                	ld	a4,0(a5)
ffffffffc0202172:	3e071363          	bnez	a4,ffffffffc0202558 <swap_init+0x4ce>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202176:	000b1717          	auipc	a4,0xb1
ffffffffc020217a:	88270713          	addi	a4,a4,-1918 # ffffffffc02b29f8 <boot_pgdir>
ffffffffc020217e:	00073b03          	ld	s6,0(a4)
     check_mm_struct = mm;
ffffffffc0202182:	e388                	sd	a0,0(a5)
     assert(pgdir[0] == 0);
ffffffffc0202184:	000b3783          	ld	a5,0(s6)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0202188:	01653c23          	sd	s6,24(a0)
     assert(pgdir[0] == 0);
ffffffffc020218c:	42079663          	bnez	a5,ffffffffc02025b8 <swap_init+0x52e>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc0202190:	6599                	lui	a1,0x6
ffffffffc0202192:	460d                	li	a2,3
ffffffffc0202194:	6505                	lui	a0,0x1
ffffffffc0202196:	8e6ff0ef          	jal	ra,ffffffffc020127c <vma_create>
ffffffffc020219a:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc020219c:	52050a63          	beqz	a0,ffffffffc02026d0 <swap_init+0x646>

     insert_vma_struct(mm, vma);
ffffffffc02021a0:	8556                	mv	a0,s5
ffffffffc02021a2:	948ff0ef          	jal	ra,ffffffffc02012ea <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc02021a6:	00005517          	auipc	a0,0x5
ffffffffc02021aa:	53250513          	addi	a0,a0,1330 # ffffffffc02076d8 <commands+0xe48>
ffffffffc02021ae:	f1ffd0ef          	jal	ra,ffffffffc02000cc <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc02021b2:	018ab503          	ld	a0,24(s5)
ffffffffc02021b6:	4605                	li	a2,1
ffffffffc02021b8:	6585                	lui	a1,0x1
ffffffffc02021ba:	3ae010ef          	jal	ra,ffffffffc0203568 <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc02021be:	4c050963          	beqz	a0,ffffffffc0202690 <swap_init+0x606>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02021c2:	00005517          	auipc	a0,0x5
ffffffffc02021c6:	56650513          	addi	a0,a0,1382 # ffffffffc0207728 <commands+0xe98>
ffffffffc02021ca:	000ac497          	auipc	s1,0xac
ffffffffc02021ce:	74648493          	addi	s1,s1,1862 # ffffffffc02ae910 <check_rp>
ffffffffc02021d2:	efbfd0ef          	jal	ra,ffffffffc02000cc <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02021d6:	000ac997          	auipc	s3,0xac
ffffffffc02021da:	75a98993          	addi	s3,s3,1882 # ffffffffc02ae930 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02021de:	8a26                	mv	s4,s1
          check_rp[i] = alloc_page();
ffffffffc02021e0:	4505                	li	a0,1
ffffffffc02021e2:	27a010ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc02021e6:	00aa3023          	sd	a0,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bd0>
          assert(check_rp[i] != NULL );
ffffffffc02021ea:	2c050f63          	beqz	a0,ffffffffc02024c8 <swap_init+0x43e>
ffffffffc02021ee:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc02021f0:	8b89                	andi	a5,a5,2
ffffffffc02021f2:	34079363          	bnez	a5,ffffffffc0202538 <swap_init+0x4ae>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02021f6:	0a21                	addi	s4,s4,8
ffffffffc02021f8:	ff3a14e3          	bne	s4,s3,ffffffffc02021e0 <swap_init+0x156>
     }
     list_entry_t free_list_store = free_list;
ffffffffc02021fc:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc02021fe:	000aca17          	auipc	s4,0xac
ffffffffc0202202:	712a0a13          	addi	s4,s4,1810 # ffffffffc02ae910 <check_rp>
    elm->prev = elm->next = elm;
ffffffffc0202206:	e000                	sd	s0,0(s0)
     list_entry_t free_list_store = free_list;
ffffffffc0202208:	ec3e                	sd	a5,24(sp)
ffffffffc020220a:	641c                	ld	a5,8(s0)
ffffffffc020220c:	e400                	sd	s0,8(s0)
ffffffffc020220e:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc0202210:	481c                	lw	a5,16(s0)
ffffffffc0202212:	f43e                	sd	a5,40(sp)
     nr_free = 0;
ffffffffc0202214:	000ac797          	auipc	a5,0xac
ffffffffc0202218:	7607ae23          	sw	zero,1916(a5) # ffffffffc02ae990 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc020221c:	000a3503          	ld	a0,0(s4)
ffffffffc0202220:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202222:	0a21                	addi	s4,s4,8
        free_pages(check_rp[i],1);
ffffffffc0202224:	2ca010ef          	jal	ra,ffffffffc02034ee <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0202228:	ff3a1ae3          	bne	s4,s3,ffffffffc020221c <swap_init+0x192>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc020222c:	01042a03          	lw	s4,16(s0)
ffffffffc0202230:	4791                	li	a5,4
ffffffffc0202232:	42fa1f63          	bne	s4,a5,ffffffffc0202670 <swap_init+0x5e6>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc0202236:	00005517          	auipc	a0,0x5
ffffffffc020223a:	57a50513          	addi	a0,a0,1402 # ffffffffc02077b0 <commands+0xf20>
ffffffffc020223e:	e8ffd0ef          	jal	ra,ffffffffc02000cc <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0202242:	6705                	lui	a4,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc0202244:	000b0797          	auipc	a5,0xb0
ffffffffc0202248:	7807a223          	sw	zero,1924(a5) # ffffffffc02b29c8 <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc020224c:	4629                	li	a2,10
ffffffffc020224e:	00c70023          	sb	a2,0(a4) # 1000 <_binary_obj___user_faultread_out_size-0x8bd0>
     assert(pgfault_num==1);
ffffffffc0202252:	000b0697          	auipc	a3,0xb0
ffffffffc0202256:	7766a683          	lw	a3,1910(a3) # ffffffffc02b29c8 <pgfault_num>
ffffffffc020225a:	4585                	li	a1,1
ffffffffc020225c:	000b0797          	auipc	a5,0xb0
ffffffffc0202260:	76c78793          	addi	a5,a5,1900 # ffffffffc02b29c8 <pgfault_num>
ffffffffc0202264:	54b69663          	bne	a3,a1,ffffffffc02027b0 <swap_init+0x726>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc0202268:	00c70823          	sb	a2,16(a4)
     assert(pgfault_num==1);
ffffffffc020226c:	4398                	lw	a4,0(a5)
ffffffffc020226e:	2701                	sext.w	a4,a4
ffffffffc0202270:	3ed71063          	bne	a4,a3,ffffffffc0202650 <swap_init+0x5c6>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0202274:	6689                	lui	a3,0x2
ffffffffc0202276:	462d                	li	a2,11
ffffffffc0202278:	00c68023          	sb	a2,0(a3) # 2000 <_binary_obj___user_faultread_out_size-0x7bd0>
     assert(pgfault_num==2);
ffffffffc020227c:	4398                	lw	a4,0(a5)
ffffffffc020227e:	4589                	li	a1,2
ffffffffc0202280:	2701                	sext.w	a4,a4
ffffffffc0202282:	4ab71763          	bne	a4,a1,ffffffffc0202730 <swap_init+0x6a6>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc0202286:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc020228a:	4394                	lw	a3,0(a5)
ffffffffc020228c:	2681                	sext.w	a3,a3
ffffffffc020228e:	4ce69163          	bne	a3,a4,ffffffffc0202750 <swap_init+0x6c6>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0202292:	668d                	lui	a3,0x3
ffffffffc0202294:	4631                	li	a2,12
ffffffffc0202296:	00c68023          	sb	a2,0(a3) # 3000 <_binary_obj___user_faultread_out_size-0x6bd0>
     assert(pgfault_num==3);
ffffffffc020229a:	4398                	lw	a4,0(a5)
ffffffffc020229c:	458d                	li	a1,3
ffffffffc020229e:	2701                	sext.w	a4,a4
ffffffffc02022a0:	4cb71863          	bne	a4,a1,ffffffffc0202770 <swap_init+0x6e6>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc02022a4:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc02022a8:	4394                	lw	a3,0(a5)
ffffffffc02022aa:	2681                	sext.w	a3,a3
ffffffffc02022ac:	4ee69263          	bne	a3,a4,ffffffffc0202790 <swap_init+0x706>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc02022b0:	6691                	lui	a3,0x4
ffffffffc02022b2:	4635                	li	a2,13
ffffffffc02022b4:	00c68023          	sb	a2,0(a3) # 4000 <_binary_obj___user_faultread_out_size-0x5bd0>
     assert(pgfault_num==4);
ffffffffc02022b8:	4398                	lw	a4,0(a5)
ffffffffc02022ba:	2701                	sext.w	a4,a4
ffffffffc02022bc:	43471a63          	bne	a4,s4,ffffffffc02026f0 <swap_init+0x666>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc02022c0:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc02022c4:	439c                	lw	a5,0(a5)
ffffffffc02022c6:	2781                	sext.w	a5,a5
ffffffffc02022c8:	44e79463          	bne	a5,a4,ffffffffc0202710 <swap_init+0x686>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc02022cc:	481c                	lw	a5,16(s0)
ffffffffc02022ce:	2c079563          	bnez	a5,ffffffffc0202598 <swap_init+0x50e>
ffffffffc02022d2:	000ac797          	auipc	a5,0xac
ffffffffc02022d6:	65e78793          	addi	a5,a5,1630 # ffffffffc02ae930 <swap_in_seq_no>
ffffffffc02022da:	000ac717          	auipc	a4,0xac
ffffffffc02022de:	67e70713          	addi	a4,a4,1662 # ffffffffc02ae958 <swap_out_seq_no>
ffffffffc02022e2:	000ac617          	auipc	a2,0xac
ffffffffc02022e6:	67660613          	addi	a2,a2,1654 # ffffffffc02ae958 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc02022ea:	56fd                	li	a3,-1
ffffffffc02022ec:	c394                	sw	a3,0(a5)
ffffffffc02022ee:	c314                	sw	a3,0(a4)
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc02022f0:	0791                	addi	a5,a5,4
ffffffffc02022f2:	0711                	addi	a4,a4,4
ffffffffc02022f4:	fec79ce3          	bne	a5,a2,ffffffffc02022ec <swap_init+0x262>
ffffffffc02022f8:	000ac717          	auipc	a4,0xac
ffffffffc02022fc:	5f870713          	addi	a4,a4,1528 # ffffffffc02ae8f0 <check_ptep>
ffffffffc0202300:	000ac697          	auipc	a3,0xac
ffffffffc0202304:	61068693          	addi	a3,a3,1552 # ffffffffc02ae910 <check_rp>
ffffffffc0202308:	6585                	lui	a1,0x1
    if (PPN(pa) >= npage) {
ffffffffc020230a:	000b0c17          	auipc	s8,0xb0
ffffffffc020230e:	6f6c0c13          	addi	s8,s8,1782 # ffffffffc02b2a00 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0202312:	000b0c97          	auipc	s9,0xb0
ffffffffc0202316:	6f6c8c93          	addi	s9,s9,1782 # ffffffffc02b2a08 <pages>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc020231a:	00073023          	sd	zero,0(a4)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc020231e:	4601                	li	a2,0
ffffffffc0202320:	855a                	mv	a0,s6
ffffffffc0202322:	e836                	sd	a3,16(sp)
ffffffffc0202324:	e42e                	sd	a1,8(sp)
         check_ptep[i]=0;
ffffffffc0202326:	e03a                	sd	a4,0(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202328:	240010ef          	jal	ra,ffffffffc0203568 <get_pte>
ffffffffc020232c:	6702                	ld	a4,0(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc020232e:	65a2                	ld	a1,8(sp)
ffffffffc0202330:	66c2                	ld	a3,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0202332:	e308                	sd	a0,0(a4)
         assert(check_ptep[i] != NULL);
ffffffffc0202334:	1c050663          	beqz	a0,ffffffffc0202500 <swap_init+0x476>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0202338:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc020233a:	0017f613          	andi	a2,a5,1
ffffffffc020233e:	1e060163          	beqz	a2,ffffffffc0202520 <swap_init+0x496>
    if (PPN(pa) >= npage) {
ffffffffc0202342:	000c3603          	ld	a2,0(s8)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202346:	078a                	slli	a5,a5,0x2
ffffffffc0202348:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020234a:	14c7f363          	bgeu	a5,a2,ffffffffc0202490 <swap_init+0x406>
    return &pages[PPN(pa) - nbase];
ffffffffc020234e:	00007617          	auipc	a2,0x7
ffffffffc0202352:	97260613          	addi	a2,a2,-1678 # ffffffffc0208cc0 <nbase>
ffffffffc0202356:	00063a03          	ld	s4,0(a2)
ffffffffc020235a:	000cb603          	ld	a2,0(s9)
ffffffffc020235e:	6288                	ld	a0,0(a3)
ffffffffc0202360:	414787b3          	sub	a5,a5,s4
ffffffffc0202364:	079a                	slli	a5,a5,0x6
ffffffffc0202366:	97b2                	add	a5,a5,a2
ffffffffc0202368:	14f51063          	bne	a0,a5,ffffffffc02024a8 <swap_init+0x41e>
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc020236c:	6785                	lui	a5,0x1
ffffffffc020236e:	95be                	add	a1,a1,a5
ffffffffc0202370:	6795                	lui	a5,0x5
ffffffffc0202372:	0721                	addi	a4,a4,8
ffffffffc0202374:	06a1                	addi	a3,a3,8
ffffffffc0202376:	faf592e3          	bne	a1,a5,ffffffffc020231a <swap_init+0x290>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc020237a:	00005517          	auipc	a0,0x5
ffffffffc020237e:	50650513          	addi	a0,a0,1286 # ffffffffc0207880 <commands+0xff0>
ffffffffc0202382:	d4bfd0ef          	jal	ra,ffffffffc02000cc <cprintf>
    int ret = sm->check_swap();
ffffffffc0202386:	000bb783          	ld	a5,0(s7)
ffffffffc020238a:	7f9c                	ld	a5,56(a5)
ffffffffc020238c:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc020238e:	32051163          	bnez	a0,ffffffffc02026b0 <swap_init+0x626>

     nr_free = nr_free_store;
ffffffffc0202392:	77a2                	ld	a5,40(sp)
ffffffffc0202394:	c81c                	sw	a5,16(s0)
     free_list = free_list_store;
ffffffffc0202396:	67e2                	ld	a5,24(sp)
ffffffffc0202398:	e01c                	sd	a5,0(s0)
ffffffffc020239a:	7782                	ld	a5,32(sp)
ffffffffc020239c:	e41c                	sd	a5,8(s0)

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc020239e:	6088                	ld	a0,0(s1)
ffffffffc02023a0:	4585                	li	a1,1
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02023a2:	04a1                	addi	s1,s1,8
         free_pages(check_rp[i],1);
ffffffffc02023a4:	14a010ef          	jal	ra,ffffffffc02034ee <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02023a8:	ff349be3          	bne	s1,s3,ffffffffc020239e <swap_init+0x314>
     } 

     //free_page(pte2page(*temp_ptep));

     mm->pgdir = NULL;
ffffffffc02023ac:	000abc23          	sd	zero,24(s5)
     mm_destroy(mm);
ffffffffc02023b0:	8556                	mv	a0,s5
ffffffffc02023b2:	808ff0ef          	jal	ra,ffffffffc02013ba <mm_destroy>
     check_mm_struct = NULL;

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc02023b6:	000b0797          	auipc	a5,0xb0
ffffffffc02023ba:	64278793          	addi	a5,a5,1602 # ffffffffc02b29f8 <boot_pgdir>
ffffffffc02023be:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc02023c0:	000c3703          	ld	a4,0(s8)
     check_mm_struct = NULL;
ffffffffc02023c4:	000b0697          	auipc	a3,0xb0
ffffffffc02023c8:	5e06be23          	sd	zero,1532(a3) # ffffffffc02b29c0 <check_mm_struct>
    return pa2page(PDE_ADDR(pde));
ffffffffc02023cc:	639c                	ld	a5,0(a5)
ffffffffc02023ce:	078a                	slli	a5,a5,0x2
ffffffffc02023d0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02023d2:	0ae7fd63          	bgeu	a5,a4,ffffffffc020248c <swap_init+0x402>
    return &pages[PPN(pa) - nbase];
ffffffffc02023d6:	414786b3          	sub	a3,a5,s4
ffffffffc02023da:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc02023dc:	8699                	srai	a3,a3,0x6
ffffffffc02023de:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc02023e0:	00c69793          	slli	a5,a3,0xc
ffffffffc02023e4:	83b1                	srli	a5,a5,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02023e6:	000cb503          	ld	a0,0(s9)
    return page2ppn(page) << PGSHIFT;
ffffffffc02023ea:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02023ec:	22e7f663          	bgeu	a5,a4,ffffffffc0202618 <swap_init+0x58e>
     free_page(pde2page(pd0[0]));
ffffffffc02023f0:	000b0797          	auipc	a5,0xb0
ffffffffc02023f4:	6287b783          	ld	a5,1576(a5) # ffffffffc02b2a18 <va_pa_offset>
ffffffffc02023f8:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02023fa:	629c                	ld	a5,0(a3)
ffffffffc02023fc:	078a                	slli	a5,a5,0x2
ffffffffc02023fe:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202400:	08e7f663          	bgeu	a5,a4,ffffffffc020248c <swap_init+0x402>
    return &pages[PPN(pa) - nbase];
ffffffffc0202404:	414787b3          	sub	a5,a5,s4
ffffffffc0202408:	079a                	slli	a5,a5,0x6
ffffffffc020240a:	953e                	add	a0,a0,a5
ffffffffc020240c:	4585                	li	a1,1
ffffffffc020240e:	0e0010ef          	jal	ra,ffffffffc02034ee <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202412:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc0202416:	000c3703          	ld	a4,0(s8)
    return pa2page(PDE_ADDR(pde));
ffffffffc020241a:	078a                	slli	a5,a5,0x2
ffffffffc020241c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020241e:	06e7f763          	bgeu	a5,a4,ffffffffc020248c <swap_init+0x402>
    return &pages[PPN(pa) - nbase];
ffffffffc0202422:	000cb503          	ld	a0,0(s9)
ffffffffc0202426:	414787b3          	sub	a5,a5,s4
ffffffffc020242a:	079a                	slli	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc020242c:	4585                	li	a1,1
ffffffffc020242e:	953e                	add	a0,a0,a5
ffffffffc0202430:	0be010ef          	jal	ra,ffffffffc02034ee <free_pages>
     pgdir[0] = 0;
ffffffffc0202434:	000b3023          	sd	zero,0(s6)
  asm volatile("sfence.vma");
ffffffffc0202438:	12000073          	sfence.vma
    return listelm->next;
ffffffffc020243c:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc020243e:	00878a63          	beq	a5,s0,ffffffffc0202452 <swap_init+0x3c8>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0202442:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202446:	679c                	ld	a5,8(a5)
ffffffffc0202448:	3dfd                	addiw	s11,s11,-1
ffffffffc020244a:	40ed0d3b          	subw	s10,s10,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc020244e:	fe879ae3          	bne	a5,s0,ffffffffc0202442 <swap_init+0x3b8>
     }
     assert(count==0);
ffffffffc0202452:	1c0d9f63          	bnez	s11,ffffffffc0202630 <swap_init+0x5a6>
     assert(total==0);
ffffffffc0202456:	1a0d1163          	bnez	s10,ffffffffc02025f8 <swap_init+0x56e>

     cprintf("check_swap() succeeded!\n");
ffffffffc020245a:	00005517          	auipc	a0,0x5
ffffffffc020245e:	47650513          	addi	a0,a0,1142 # ffffffffc02078d0 <commands+0x1040>
ffffffffc0202462:	c6bfd0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc0202466:	b99d                	j	ffffffffc02020dc <swap_init+0x52>
     while ((le = list_next(le)) != &free_list) {
ffffffffc0202468:	4481                	li	s1,0
ffffffffc020246a:	b9f1                	j	ffffffffc0202146 <swap_init+0xbc>
        assert(PageProperty(p));
ffffffffc020246c:	00005697          	auipc	a3,0x5
ffffffffc0202470:	1fc68693          	addi	a3,a3,508 # ffffffffc0207668 <commands+0xdd8>
ffffffffc0202474:	00005617          	auipc	a2,0x5
ffffffffc0202478:	82c60613          	addi	a2,a2,-2004 # ffffffffc0206ca0 <commands+0x410>
ffffffffc020247c:	0bc00593          	li	a1,188
ffffffffc0202480:	00005517          	auipc	a0,0x5
ffffffffc0202484:	1c050513          	addi	a0,a0,448 # ffffffffc0207640 <commands+0xdb0>
ffffffffc0202488:	d81fd0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc020248c:	be3ff0ef          	jal	ra,ffffffffc020206e <pa2page.part.0>
        panic("pa2page called with invalid pa");
ffffffffc0202490:	00005617          	auipc	a2,0x5
ffffffffc0202494:	f9060613          	addi	a2,a2,-112 # ffffffffc0207420 <commands+0xb90>
ffffffffc0202498:	06300593          	li	a1,99
ffffffffc020249c:	00005517          	auipc	a0,0x5
ffffffffc02024a0:	fa450513          	addi	a0,a0,-92 # ffffffffc0207440 <commands+0xbb0>
ffffffffc02024a4:	d65fd0ef          	jal	ra,ffffffffc0200208 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc02024a8:	00005697          	auipc	a3,0x5
ffffffffc02024ac:	3b068693          	addi	a3,a3,944 # ffffffffc0207858 <commands+0xfc8>
ffffffffc02024b0:	00004617          	auipc	a2,0x4
ffffffffc02024b4:	7f060613          	addi	a2,a2,2032 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02024b8:	0fc00593          	li	a1,252
ffffffffc02024bc:	00005517          	auipc	a0,0x5
ffffffffc02024c0:	18450513          	addi	a0,a0,388 # ffffffffc0207640 <commands+0xdb0>
ffffffffc02024c4:	d45fd0ef          	jal	ra,ffffffffc0200208 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc02024c8:	00005697          	auipc	a3,0x5
ffffffffc02024cc:	28868693          	addi	a3,a3,648 # ffffffffc0207750 <commands+0xec0>
ffffffffc02024d0:	00004617          	auipc	a2,0x4
ffffffffc02024d4:	7d060613          	addi	a2,a2,2000 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02024d8:	0dc00593          	li	a1,220
ffffffffc02024dc:	00005517          	auipc	a0,0x5
ffffffffc02024e0:	16450513          	addi	a0,a0,356 # ffffffffc0207640 <commands+0xdb0>
ffffffffc02024e4:	d25fd0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc02024e8:	00005617          	auipc	a2,0x5
ffffffffc02024ec:	13860613          	addi	a2,a2,312 # ffffffffc0207620 <commands+0xd90>
ffffffffc02024f0:	02800593          	li	a1,40
ffffffffc02024f4:	00005517          	auipc	a0,0x5
ffffffffc02024f8:	14c50513          	addi	a0,a0,332 # ffffffffc0207640 <commands+0xdb0>
ffffffffc02024fc:	d0dfd0ef          	jal	ra,ffffffffc0200208 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc0202500:	00005697          	auipc	a3,0x5
ffffffffc0202504:	31868693          	addi	a3,a3,792 # ffffffffc0207818 <commands+0xf88>
ffffffffc0202508:	00004617          	auipc	a2,0x4
ffffffffc020250c:	79860613          	addi	a2,a2,1944 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202510:	0fb00593          	li	a1,251
ffffffffc0202514:	00005517          	auipc	a0,0x5
ffffffffc0202518:	12c50513          	addi	a0,a0,300 # ffffffffc0207640 <commands+0xdb0>
ffffffffc020251c:	cedfd0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202520:	00005617          	auipc	a2,0x5
ffffffffc0202524:	31060613          	addi	a2,a2,784 # ffffffffc0207830 <commands+0xfa0>
ffffffffc0202528:	07500593          	li	a1,117
ffffffffc020252c:	00005517          	auipc	a0,0x5
ffffffffc0202530:	f1450513          	addi	a0,a0,-236 # ffffffffc0207440 <commands+0xbb0>
ffffffffc0202534:	cd5fd0ef          	jal	ra,ffffffffc0200208 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0202538:	00005697          	auipc	a3,0x5
ffffffffc020253c:	23068693          	addi	a3,a3,560 # ffffffffc0207768 <commands+0xed8>
ffffffffc0202540:	00004617          	auipc	a2,0x4
ffffffffc0202544:	76060613          	addi	a2,a2,1888 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202548:	0dd00593          	li	a1,221
ffffffffc020254c:	00005517          	auipc	a0,0x5
ffffffffc0202550:	0f450513          	addi	a0,a0,244 # ffffffffc0207640 <commands+0xdb0>
ffffffffc0202554:	cb5fd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0202558:	00005697          	auipc	a3,0x5
ffffffffc020255c:	16868693          	addi	a3,a3,360 # ffffffffc02076c0 <commands+0xe30>
ffffffffc0202560:	00004617          	auipc	a2,0x4
ffffffffc0202564:	74060613          	addi	a2,a2,1856 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202568:	0c700593          	li	a1,199
ffffffffc020256c:	00005517          	auipc	a0,0x5
ffffffffc0202570:	0d450513          	addi	a0,a0,212 # ffffffffc0207640 <commands+0xdb0>
ffffffffc0202574:	c95fd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(total == nr_free_pages());
ffffffffc0202578:	00005697          	auipc	a3,0x5
ffffffffc020257c:	10068693          	addi	a3,a3,256 # ffffffffc0207678 <commands+0xde8>
ffffffffc0202580:	00004617          	auipc	a2,0x4
ffffffffc0202584:	72060613          	addi	a2,a2,1824 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202588:	0bf00593          	li	a1,191
ffffffffc020258c:	00005517          	auipc	a0,0x5
ffffffffc0202590:	0b450513          	addi	a0,a0,180 # ffffffffc0207640 <commands+0xdb0>
ffffffffc0202594:	c75fd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert( nr_free == 0);         
ffffffffc0202598:	00005697          	auipc	a3,0x5
ffffffffc020259c:	27068693          	addi	a3,a3,624 # ffffffffc0207808 <commands+0xf78>
ffffffffc02025a0:	00004617          	auipc	a2,0x4
ffffffffc02025a4:	70060613          	addi	a2,a2,1792 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02025a8:	0f300593          	li	a1,243
ffffffffc02025ac:	00005517          	auipc	a0,0x5
ffffffffc02025b0:	09450513          	addi	a0,a0,148 # ffffffffc0207640 <commands+0xdb0>
ffffffffc02025b4:	c55fd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgdir[0] == 0);
ffffffffc02025b8:	00005697          	auipc	a3,0x5
ffffffffc02025bc:	e2868693          	addi	a3,a3,-472 # ffffffffc02073e0 <commands+0xb50>
ffffffffc02025c0:	00004617          	auipc	a2,0x4
ffffffffc02025c4:	6e060613          	addi	a2,a2,1760 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02025c8:	0cc00593          	li	a1,204
ffffffffc02025cc:	00005517          	auipc	a0,0x5
ffffffffc02025d0:	07450513          	addi	a0,a0,116 # ffffffffc0207640 <commands+0xdb0>
ffffffffc02025d4:	c35fd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(mm != NULL);
ffffffffc02025d8:	00005697          	auipc	a3,0x5
ffffffffc02025dc:	c4068693          	addi	a3,a3,-960 # ffffffffc0207218 <commands+0x988>
ffffffffc02025e0:	00004617          	auipc	a2,0x4
ffffffffc02025e4:	6c060613          	addi	a2,a2,1728 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02025e8:	0c400593          	li	a1,196
ffffffffc02025ec:	00005517          	auipc	a0,0x5
ffffffffc02025f0:	05450513          	addi	a0,a0,84 # ffffffffc0207640 <commands+0xdb0>
ffffffffc02025f4:	c15fd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(total==0);
ffffffffc02025f8:	00005697          	auipc	a3,0x5
ffffffffc02025fc:	2c868693          	addi	a3,a3,712 # ffffffffc02078c0 <commands+0x1030>
ffffffffc0202600:	00004617          	auipc	a2,0x4
ffffffffc0202604:	6a060613          	addi	a2,a2,1696 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202608:	11e00593          	li	a1,286
ffffffffc020260c:	00005517          	auipc	a0,0x5
ffffffffc0202610:	03450513          	addi	a0,a0,52 # ffffffffc0207640 <commands+0xdb0>
ffffffffc0202614:	bf5fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202618:	00005617          	auipc	a2,0x5
ffffffffc020261c:	e3860613          	addi	a2,a2,-456 # ffffffffc0207450 <commands+0xbc0>
ffffffffc0202620:	06a00593          	li	a1,106
ffffffffc0202624:	00005517          	auipc	a0,0x5
ffffffffc0202628:	e1c50513          	addi	a0,a0,-484 # ffffffffc0207440 <commands+0xbb0>
ffffffffc020262c:	bddfd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(count==0);
ffffffffc0202630:	00005697          	auipc	a3,0x5
ffffffffc0202634:	28068693          	addi	a3,a3,640 # ffffffffc02078b0 <commands+0x1020>
ffffffffc0202638:	00004617          	auipc	a2,0x4
ffffffffc020263c:	66860613          	addi	a2,a2,1640 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202640:	11d00593          	li	a1,285
ffffffffc0202644:	00005517          	auipc	a0,0x5
ffffffffc0202648:	ffc50513          	addi	a0,a0,-4 # ffffffffc0207640 <commands+0xdb0>
ffffffffc020264c:	bbdfd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==1);
ffffffffc0202650:	00005697          	auipc	a3,0x5
ffffffffc0202654:	18868693          	addi	a3,a3,392 # ffffffffc02077d8 <commands+0xf48>
ffffffffc0202658:	00004617          	auipc	a2,0x4
ffffffffc020265c:	64860613          	addi	a2,a2,1608 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202660:	09500593          	li	a1,149
ffffffffc0202664:	00005517          	auipc	a0,0x5
ffffffffc0202668:	fdc50513          	addi	a0,a0,-36 # ffffffffc0207640 <commands+0xdb0>
ffffffffc020266c:	b9dfd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0202670:	00005697          	auipc	a3,0x5
ffffffffc0202674:	11868693          	addi	a3,a3,280 # ffffffffc0207788 <commands+0xef8>
ffffffffc0202678:	00004617          	auipc	a2,0x4
ffffffffc020267c:	62860613          	addi	a2,a2,1576 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202680:	0ea00593          	li	a1,234
ffffffffc0202684:	00005517          	auipc	a0,0x5
ffffffffc0202688:	fbc50513          	addi	a0,a0,-68 # ffffffffc0207640 <commands+0xdb0>
ffffffffc020268c:	b7dfd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc0202690:	00005697          	auipc	a3,0x5
ffffffffc0202694:	08068693          	addi	a3,a3,128 # ffffffffc0207710 <commands+0xe80>
ffffffffc0202698:	00004617          	auipc	a2,0x4
ffffffffc020269c:	60860613          	addi	a2,a2,1544 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02026a0:	0d700593          	li	a1,215
ffffffffc02026a4:	00005517          	auipc	a0,0x5
ffffffffc02026a8:	f9c50513          	addi	a0,a0,-100 # ffffffffc0207640 <commands+0xdb0>
ffffffffc02026ac:	b5dfd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(ret==0);
ffffffffc02026b0:	00005697          	auipc	a3,0x5
ffffffffc02026b4:	1f868693          	addi	a3,a3,504 # ffffffffc02078a8 <commands+0x1018>
ffffffffc02026b8:	00004617          	auipc	a2,0x4
ffffffffc02026bc:	5e860613          	addi	a2,a2,1512 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02026c0:	10200593          	li	a1,258
ffffffffc02026c4:	00005517          	auipc	a0,0x5
ffffffffc02026c8:	f7c50513          	addi	a0,a0,-132 # ffffffffc0207640 <commands+0xdb0>
ffffffffc02026cc:	b3dfd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(vma != NULL);
ffffffffc02026d0:	00005697          	auipc	a3,0x5
ffffffffc02026d4:	e0868693          	addi	a3,a3,-504 # ffffffffc02074d8 <commands+0xc48>
ffffffffc02026d8:	00004617          	auipc	a2,0x4
ffffffffc02026dc:	5c860613          	addi	a2,a2,1480 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02026e0:	0cf00593          	li	a1,207
ffffffffc02026e4:	00005517          	auipc	a0,0x5
ffffffffc02026e8:	f5c50513          	addi	a0,a0,-164 # ffffffffc0207640 <commands+0xdb0>
ffffffffc02026ec:	b1dfd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==4);
ffffffffc02026f0:	00005697          	auipc	a3,0x5
ffffffffc02026f4:	8c868693          	addi	a3,a3,-1848 # ffffffffc0206fb8 <commands+0x728>
ffffffffc02026f8:	00004617          	auipc	a2,0x4
ffffffffc02026fc:	5a860613          	addi	a2,a2,1448 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202700:	09f00593          	li	a1,159
ffffffffc0202704:	00005517          	auipc	a0,0x5
ffffffffc0202708:	f3c50513          	addi	a0,a0,-196 # ffffffffc0207640 <commands+0xdb0>
ffffffffc020270c:	afdfd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==4);
ffffffffc0202710:	00005697          	auipc	a3,0x5
ffffffffc0202714:	8a868693          	addi	a3,a3,-1880 # ffffffffc0206fb8 <commands+0x728>
ffffffffc0202718:	00004617          	auipc	a2,0x4
ffffffffc020271c:	58860613          	addi	a2,a2,1416 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202720:	0a100593          	li	a1,161
ffffffffc0202724:	00005517          	auipc	a0,0x5
ffffffffc0202728:	f1c50513          	addi	a0,a0,-228 # ffffffffc0207640 <commands+0xdb0>
ffffffffc020272c:	addfd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==2);
ffffffffc0202730:	00005697          	auipc	a3,0x5
ffffffffc0202734:	0b868693          	addi	a3,a3,184 # ffffffffc02077e8 <commands+0xf58>
ffffffffc0202738:	00004617          	auipc	a2,0x4
ffffffffc020273c:	56860613          	addi	a2,a2,1384 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202740:	09700593          	li	a1,151
ffffffffc0202744:	00005517          	auipc	a0,0x5
ffffffffc0202748:	efc50513          	addi	a0,a0,-260 # ffffffffc0207640 <commands+0xdb0>
ffffffffc020274c:	abdfd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==2);
ffffffffc0202750:	00005697          	auipc	a3,0x5
ffffffffc0202754:	09868693          	addi	a3,a3,152 # ffffffffc02077e8 <commands+0xf58>
ffffffffc0202758:	00004617          	auipc	a2,0x4
ffffffffc020275c:	54860613          	addi	a2,a2,1352 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202760:	09900593          	li	a1,153
ffffffffc0202764:	00005517          	auipc	a0,0x5
ffffffffc0202768:	edc50513          	addi	a0,a0,-292 # ffffffffc0207640 <commands+0xdb0>
ffffffffc020276c:	a9dfd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==3);
ffffffffc0202770:	00005697          	auipc	a3,0x5
ffffffffc0202774:	08868693          	addi	a3,a3,136 # ffffffffc02077f8 <commands+0xf68>
ffffffffc0202778:	00004617          	auipc	a2,0x4
ffffffffc020277c:	52860613          	addi	a2,a2,1320 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202780:	09b00593          	li	a1,155
ffffffffc0202784:	00005517          	auipc	a0,0x5
ffffffffc0202788:	ebc50513          	addi	a0,a0,-324 # ffffffffc0207640 <commands+0xdb0>
ffffffffc020278c:	a7dfd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==3);
ffffffffc0202790:	00005697          	auipc	a3,0x5
ffffffffc0202794:	06868693          	addi	a3,a3,104 # ffffffffc02077f8 <commands+0xf68>
ffffffffc0202798:	00004617          	auipc	a2,0x4
ffffffffc020279c:	50860613          	addi	a2,a2,1288 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02027a0:	09d00593          	li	a1,157
ffffffffc02027a4:	00005517          	auipc	a0,0x5
ffffffffc02027a8:	e9c50513          	addi	a0,a0,-356 # ffffffffc0207640 <commands+0xdb0>
ffffffffc02027ac:	a5dfd0ef          	jal	ra,ffffffffc0200208 <__panic>
     assert(pgfault_num==1);
ffffffffc02027b0:	00005697          	auipc	a3,0x5
ffffffffc02027b4:	02868693          	addi	a3,a3,40 # ffffffffc02077d8 <commands+0xf48>
ffffffffc02027b8:	00004617          	auipc	a2,0x4
ffffffffc02027bc:	4e860613          	addi	a2,a2,1256 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02027c0:	09300593          	li	a1,147
ffffffffc02027c4:	00005517          	auipc	a0,0x5
ffffffffc02027c8:	e7c50513          	addi	a0,a0,-388 # ffffffffc0207640 <commands+0xdb0>
ffffffffc02027cc:	a3dfd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02027d0 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc02027d0:	000b0797          	auipc	a5,0xb0
ffffffffc02027d4:	2107b783          	ld	a5,528(a5) # ffffffffc02b29e0 <sm>
ffffffffc02027d8:	6b9c                	ld	a5,16(a5)
ffffffffc02027da:	8782                	jr	a5

ffffffffc02027dc <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc02027dc:	000b0797          	auipc	a5,0xb0
ffffffffc02027e0:	2047b783          	ld	a5,516(a5) # ffffffffc02b29e0 <sm>
ffffffffc02027e4:	739c                	ld	a5,32(a5)
ffffffffc02027e6:	8782                	jr	a5

ffffffffc02027e8 <swap_out>:
{
ffffffffc02027e8:	711d                	addi	sp,sp,-96
ffffffffc02027ea:	ec86                	sd	ra,88(sp)
ffffffffc02027ec:	e8a2                	sd	s0,80(sp)
ffffffffc02027ee:	e4a6                	sd	s1,72(sp)
ffffffffc02027f0:	e0ca                	sd	s2,64(sp)
ffffffffc02027f2:	fc4e                	sd	s3,56(sp)
ffffffffc02027f4:	f852                	sd	s4,48(sp)
ffffffffc02027f6:	f456                	sd	s5,40(sp)
ffffffffc02027f8:	f05a                	sd	s6,32(sp)
ffffffffc02027fa:	ec5e                	sd	s7,24(sp)
ffffffffc02027fc:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc02027fe:	cde9                	beqz	a1,ffffffffc02028d8 <swap_out+0xf0>
ffffffffc0202800:	8a2e                	mv	s4,a1
ffffffffc0202802:	892a                	mv	s2,a0
ffffffffc0202804:	8ab2                	mv	s5,a2
ffffffffc0202806:	4401                	li	s0,0
ffffffffc0202808:	000b0997          	auipc	s3,0xb0
ffffffffc020280c:	1d898993          	addi	s3,s3,472 # ffffffffc02b29e0 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0202810:	00005b17          	auipc	s6,0x5
ffffffffc0202814:	140b0b13          	addi	s6,s6,320 # ffffffffc0207950 <commands+0x10c0>
                    cprintf("SWAP: failed to save\n");
ffffffffc0202818:	00005b97          	auipc	s7,0x5
ffffffffc020281c:	120b8b93          	addi	s7,s7,288 # ffffffffc0207938 <commands+0x10a8>
ffffffffc0202820:	a825                	j	ffffffffc0202858 <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0202822:	67a2                	ld	a5,8(sp)
ffffffffc0202824:	8626                	mv	a2,s1
ffffffffc0202826:	85a2                	mv	a1,s0
ffffffffc0202828:	7f94                	ld	a3,56(a5)
ffffffffc020282a:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc020282c:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc020282e:	82b1                	srli	a3,a3,0xc
ffffffffc0202830:	0685                	addi	a3,a3,1
ffffffffc0202832:	89bfd0ef          	jal	ra,ffffffffc02000cc <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0202836:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc0202838:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc020283a:	7d1c                	ld	a5,56(a0)
ffffffffc020283c:	83b1                	srli	a5,a5,0xc
ffffffffc020283e:	0785                	addi	a5,a5,1
ffffffffc0202840:	07a2                	slli	a5,a5,0x8
ffffffffc0202842:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc0202846:	4a9000ef          	jal	ra,ffffffffc02034ee <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc020284a:	01893503          	ld	a0,24(s2)
ffffffffc020284e:	85a6                	mv	a1,s1
ffffffffc0202850:	272020ef          	jal	ra,ffffffffc0204ac2 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0202854:	048a0d63          	beq	s4,s0,ffffffffc02028ae <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc0202858:	0009b783          	ld	a5,0(s3)
ffffffffc020285c:	8656                	mv	a2,s5
ffffffffc020285e:	002c                	addi	a1,sp,8
ffffffffc0202860:	7b9c                	ld	a5,48(a5)
ffffffffc0202862:	854a                	mv	a0,s2
ffffffffc0202864:	9782                	jalr	a5
          if (r != 0) {
ffffffffc0202866:	e12d                	bnez	a0,ffffffffc02028c8 <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc0202868:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc020286a:	01893503          	ld	a0,24(s2)
ffffffffc020286e:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc0202870:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0202872:	85a6                	mv	a1,s1
ffffffffc0202874:	4f5000ef          	jal	ra,ffffffffc0203568 <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0202878:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc020287a:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc020287c:	8b85                	andi	a5,a5,1
ffffffffc020287e:	cfb9                	beqz	a5,ffffffffc02028dc <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc0202880:	65a2                	ld	a1,8(sp)
ffffffffc0202882:	7d9c                	ld	a5,56(a1)
ffffffffc0202884:	83b1                	srli	a5,a5,0xc
ffffffffc0202886:	0785                	addi	a5,a5,1
ffffffffc0202888:	00879513          	slli	a0,a5,0x8
ffffffffc020288c:	3bc020ef          	jal	ra,ffffffffc0204c48 <swapfs_write>
ffffffffc0202890:	d949                	beqz	a0,ffffffffc0202822 <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc0202892:	855e                	mv	a0,s7
ffffffffc0202894:	839fd0ef          	jal	ra,ffffffffc02000cc <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0202898:	0009b783          	ld	a5,0(s3)
ffffffffc020289c:	6622                	ld	a2,8(sp)
ffffffffc020289e:	4681                	li	a3,0
ffffffffc02028a0:	739c                	ld	a5,32(a5)
ffffffffc02028a2:	85a6                	mv	a1,s1
ffffffffc02028a4:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc02028a6:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc02028a8:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc02028aa:	fa8a17e3          	bne	s4,s0,ffffffffc0202858 <swap_out+0x70>
}
ffffffffc02028ae:	60e6                	ld	ra,88(sp)
ffffffffc02028b0:	8522                	mv	a0,s0
ffffffffc02028b2:	6446                	ld	s0,80(sp)
ffffffffc02028b4:	64a6                	ld	s1,72(sp)
ffffffffc02028b6:	6906                	ld	s2,64(sp)
ffffffffc02028b8:	79e2                	ld	s3,56(sp)
ffffffffc02028ba:	7a42                	ld	s4,48(sp)
ffffffffc02028bc:	7aa2                	ld	s5,40(sp)
ffffffffc02028be:	7b02                	ld	s6,32(sp)
ffffffffc02028c0:	6be2                	ld	s7,24(sp)
ffffffffc02028c2:	6c42                	ld	s8,16(sp)
ffffffffc02028c4:	6125                	addi	sp,sp,96
ffffffffc02028c6:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc02028c8:	85a2                	mv	a1,s0
ffffffffc02028ca:	00005517          	auipc	a0,0x5
ffffffffc02028ce:	02650513          	addi	a0,a0,38 # ffffffffc02078f0 <commands+0x1060>
ffffffffc02028d2:	ffafd0ef          	jal	ra,ffffffffc02000cc <cprintf>
                  break;
ffffffffc02028d6:	bfe1                	j	ffffffffc02028ae <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc02028d8:	4401                	li	s0,0
ffffffffc02028da:	bfd1                	j	ffffffffc02028ae <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc02028dc:	00005697          	auipc	a3,0x5
ffffffffc02028e0:	04468693          	addi	a3,a3,68 # ffffffffc0207920 <commands+0x1090>
ffffffffc02028e4:	00004617          	auipc	a2,0x4
ffffffffc02028e8:	3bc60613          	addi	a2,a2,956 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02028ec:	06800593          	li	a1,104
ffffffffc02028f0:	00005517          	auipc	a0,0x5
ffffffffc02028f4:	d5050513          	addi	a0,a0,-688 # ffffffffc0207640 <commands+0xdb0>
ffffffffc02028f8:	911fd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02028fc <swap_in>:
{
ffffffffc02028fc:	7179                	addi	sp,sp,-48
ffffffffc02028fe:	e84a                	sd	s2,16(sp)
ffffffffc0202900:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc0202902:	4505                	li	a0,1
{
ffffffffc0202904:	ec26                	sd	s1,24(sp)
ffffffffc0202906:	e44e                	sd	s3,8(sp)
ffffffffc0202908:	f406                	sd	ra,40(sp)
ffffffffc020290a:	f022                	sd	s0,32(sp)
ffffffffc020290c:	84ae                	mv	s1,a1
ffffffffc020290e:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc0202910:	34d000ef          	jal	ra,ffffffffc020345c <alloc_pages>
     assert(result!=NULL);
ffffffffc0202914:	c129                	beqz	a0,ffffffffc0202956 <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0202916:	842a                	mv	s0,a0
ffffffffc0202918:	01893503          	ld	a0,24(s2)
ffffffffc020291c:	4601                	li	a2,0
ffffffffc020291e:	85a6                	mv	a1,s1
ffffffffc0202920:	449000ef          	jal	ra,ffffffffc0203568 <get_pte>
ffffffffc0202924:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc0202926:	6108                	ld	a0,0(a0)
ffffffffc0202928:	85a2                	mv	a1,s0
ffffffffc020292a:	290020ef          	jal	ra,ffffffffc0204bba <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc020292e:	00093583          	ld	a1,0(s2)
ffffffffc0202932:	8626                	mv	a2,s1
ffffffffc0202934:	00005517          	auipc	a0,0x5
ffffffffc0202938:	06c50513          	addi	a0,a0,108 # ffffffffc02079a0 <commands+0x1110>
ffffffffc020293c:	81a1                	srli	a1,a1,0x8
ffffffffc020293e:	f8efd0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc0202942:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc0202944:	0089b023          	sd	s0,0(s3)
}
ffffffffc0202948:	7402                	ld	s0,32(sp)
ffffffffc020294a:	64e2                	ld	s1,24(sp)
ffffffffc020294c:	6942                	ld	s2,16(sp)
ffffffffc020294e:	69a2                	ld	s3,8(sp)
ffffffffc0202950:	4501                	li	a0,0
ffffffffc0202952:	6145                	addi	sp,sp,48
ffffffffc0202954:	8082                	ret
     assert(result!=NULL);
ffffffffc0202956:	00005697          	auipc	a3,0x5
ffffffffc020295a:	03a68693          	addi	a3,a3,58 # ffffffffc0207990 <commands+0x1100>
ffffffffc020295e:	00004617          	auipc	a2,0x4
ffffffffc0202962:	34260613          	addi	a2,a2,834 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202966:	07e00593          	li	a1,126
ffffffffc020296a:	00005517          	auipc	a0,0x5
ffffffffc020296e:	cd650513          	addi	a0,a0,-810 # ffffffffc0207640 <commands+0xdb0>
ffffffffc0202972:	897fd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0202976 <default_init>:
    elm->prev = elm->next = elm;
ffffffffc0202976:	000ac797          	auipc	a5,0xac
ffffffffc020297a:	00a78793          	addi	a5,a5,10 # ffffffffc02ae980 <free_area>
ffffffffc020297e:	e79c                	sd	a5,8(a5)
ffffffffc0202980:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0202982:	0007a823          	sw	zero,16(a5)
}
ffffffffc0202986:	8082                	ret

ffffffffc0202988 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0202988:	000ac517          	auipc	a0,0xac
ffffffffc020298c:	00856503          	lwu	a0,8(a0) # ffffffffc02ae990 <free_area+0x10>
ffffffffc0202990:	8082                	ret

ffffffffc0202992 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0202992:	715d                	addi	sp,sp,-80
ffffffffc0202994:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0202996:	000ac417          	auipc	s0,0xac
ffffffffc020299a:	fea40413          	addi	s0,s0,-22 # ffffffffc02ae980 <free_area>
ffffffffc020299e:	641c                	ld	a5,8(s0)
ffffffffc02029a0:	e486                	sd	ra,72(sp)
ffffffffc02029a2:	fc26                	sd	s1,56(sp)
ffffffffc02029a4:	f84a                	sd	s2,48(sp)
ffffffffc02029a6:	f44e                	sd	s3,40(sp)
ffffffffc02029a8:	f052                	sd	s4,32(sp)
ffffffffc02029aa:	ec56                	sd	s5,24(sp)
ffffffffc02029ac:	e85a                	sd	s6,16(sp)
ffffffffc02029ae:	e45e                	sd	s7,8(sp)
ffffffffc02029b0:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02029b2:	2a878d63          	beq	a5,s0,ffffffffc0202c6c <default_check+0x2da>
    int count = 0, total = 0;
ffffffffc02029b6:	4481                	li	s1,0
ffffffffc02029b8:	4901                	li	s2,0
ffffffffc02029ba:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc02029be:	8b09                	andi	a4,a4,2
ffffffffc02029c0:	2a070a63          	beqz	a4,ffffffffc0202c74 <default_check+0x2e2>
        count ++, total += p->property;
ffffffffc02029c4:	ff87a703          	lw	a4,-8(a5)
ffffffffc02029c8:	679c                	ld	a5,8(a5)
ffffffffc02029ca:	2905                	addiw	s2,s2,1
ffffffffc02029cc:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02029ce:	fe8796e3          	bne	a5,s0,ffffffffc02029ba <default_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc02029d2:	89a6                	mv	s3,s1
ffffffffc02029d4:	35b000ef          	jal	ra,ffffffffc020352e <nr_free_pages>
ffffffffc02029d8:	6f351e63          	bne	a0,s3,ffffffffc02030d4 <default_check+0x742>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02029dc:	4505                	li	a0,1
ffffffffc02029de:	27f000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc02029e2:	8aaa                	mv	s5,a0
ffffffffc02029e4:	42050863          	beqz	a0,ffffffffc0202e14 <default_check+0x482>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02029e8:	4505                	li	a0,1
ffffffffc02029ea:	273000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc02029ee:	89aa                	mv	s3,a0
ffffffffc02029f0:	70050263          	beqz	a0,ffffffffc02030f4 <default_check+0x762>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02029f4:	4505                	li	a0,1
ffffffffc02029f6:	267000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc02029fa:	8a2a                	mv	s4,a0
ffffffffc02029fc:	48050c63          	beqz	a0,ffffffffc0202e94 <default_check+0x502>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0202a00:	293a8a63          	beq	s5,s3,ffffffffc0202c94 <default_check+0x302>
ffffffffc0202a04:	28aa8863          	beq	s5,a0,ffffffffc0202c94 <default_check+0x302>
ffffffffc0202a08:	28a98663          	beq	s3,a0,ffffffffc0202c94 <default_check+0x302>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0202a0c:	000aa783          	lw	a5,0(s5)
ffffffffc0202a10:	2a079263          	bnez	a5,ffffffffc0202cb4 <default_check+0x322>
ffffffffc0202a14:	0009a783          	lw	a5,0(s3)
ffffffffc0202a18:	28079e63          	bnez	a5,ffffffffc0202cb4 <default_check+0x322>
ffffffffc0202a1c:	411c                	lw	a5,0(a0)
ffffffffc0202a1e:	28079b63          	bnez	a5,ffffffffc0202cb4 <default_check+0x322>
    return page - pages + nbase;
ffffffffc0202a22:	000b0797          	auipc	a5,0xb0
ffffffffc0202a26:	fe67b783          	ld	a5,-26(a5) # ffffffffc02b2a08 <pages>
ffffffffc0202a2a:	40fa8733          	sub	a4,s5,a5
ffffffffc0202a2e:	00006617          	auipc	a2,0x6
ffffffffc0202a32:	29263603          	ld	a2,658(a2) # ffffffffc0208cc0 <nbase>
ffffffffc0202a36:	8719                	srai	a4,a4,0x6
ffffffffc0202a38:	9732                	add	a4,a4,a2
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0202a3a:	000b0697          	auipc	a3,0xb0
ffffffffc0202a3e:	fc66b683          	ld	a3,-58(a3) # ffffffffc02b2a00 <npage>
ffffffffc0202a42:	06b2                	slli	a3,a3,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a44:	0732                	slli	a4,a4,0xc
ffffffffc0202a46:	28d77763          	bgeu	a4,a3,ffffffffc0202cd4 <default_check+0x342>
    return page - pages + nbase;
ffffffffc0202a4a:	40f98733          	sub	a4,s3,a5
ffffffffc0202a4e:	8719                	srai	a4,a4,0x6
ffffffffc0202a50:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a52:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0202a54:	4cd77063          	bgeu	a4,a3,ffffffffc0202f14 <default_check+0x582>
    return page - pages + nbase;
ffffffffc0202a58:	40f507b3          	sub	a5,a0,a5
ffffffffc0202a5c:	8799                	srai	a5,a5,0x6
ffffffffc0202a5e:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a60:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0202a62:	30d7f963          	bgeu	a5,a3,ffffffffc0202d74 <default_check+0x3e2>
    assert(alloc_page() == NULL);
ffffffffc0202a66:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0202a68:	00043c03          	ld	s8,0(s0)
ffffffffc0202a6c:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0202a70:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0202a74:	e400                	sd	s0,8(s0)
ffffffffc0202a76:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0202a78:	000ac797          	auipc	a5,0xac
ffffffffc0202a7c:	f007ac23          	sw	zero,-232(a5) # ffffffffc02ae990 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0202a80:	1dd000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0202a84:	2c051863          	bnez	a0,ffffffffc0202d54 <default_check+0x3c2>
    free_page(p0);
ffffffffc0202a88:	4585                	li	a1,1
ffffffffc0202a8a:	8556                	mv	a0,s5
ffffffffc0202a8c:	263000ef          	jal	ra,ffffffffc02034ee <free_pages>
    free_page(p1);
ffffffffc0202a90:	4585                	li	a1,1
ffffffffc0202a92:	854e                	mv	a0,s3
ffffffffc0202a94:	25b000ef          	jal	ra,ffffffffc02034ee <free_pages>
    free_page(p2);
ffffffffc0202a98:	4585                	li	a1,1
ffffffffc0202a9a:	8552                	mv	a0,s4
ffffffffc0202a9c:	253000ef          	jal	ra,ffffffffc02034ee <free_pages>
    assert(nr_free == 3);
ffffffffc0202aa0:	4818                	lw	a4,16(s0)
ffffffffc0202aa2:	478d                	li	a5,3
ffffffffc0202aa4:	28f71863          	bne	a4,a5,ffffffffc0202d34 <default_check+0x3a2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202aa8:	4505                	li	a0,1
ffffffffc0202aaa:	1b3000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0202aae:	89aa                	mv	s3,a0
ffffffffc0202ab0:	26050263          	beqz	a0,ffffffffc0202d14 <default_check+0x382>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202ab4:	4505                	li	a0,1
ffffffffc0202ab6:	1a7000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0202aba:	8aaa                	mv	s5,a0
ffffffffc0202abc:	3a050c63          	beqz	a0,ffffffffc0202e74 <default_check+0x4e2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202ac0:	4505                	li	a0,1
ffffffffc0202ac2:	19b000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0202ac6:	8a2a                	mv	s4,a0
ffffffffc0202ac8:	38050663          	beqz	a0,ffffffffc0202e54 <default_check+0x4c2>
    assert(alloc_page() == NULL);
ffffffffc0202acc:	4505                	li	a0,1
ffffffffc0202ace:	18f000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0202ad2:	36051163          	bnez	a0,ffffffffc0202e34 <default_check+0x4a2>
    free_page(p0);
ffffffffc0202ad6:	4585                	li	a1,1
ffffffffc0202ad8:	854e                	mv	a0,s3
ffffffffc0202ada:	215000ef          	jal	ra,ffffffffc02034ee <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0202ade:	641c                	ld	a5,8(s0)
ffffffffc0202ae0:	20878a63          	beq	a5,s0,ffffffffc0202cf4 <default_check+0x362>
    assert((p = alloc_page()) == p0);
ffffffffc0202ae4:	4505                	li	a0,1
ffffffffc0202ae6:	177000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0202aea:	30a99563          	bne	s3,a0,ffffffffc0202df4 <default_check+0x462>
    assert(alloc_page() == NULL);
ffffffffc0202aee:	4505                	li	a0,1
ffffffffc0202af0:	16d000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0202af4:	2e051063          	bnez	a0,ffffffffc0202dd4 <default_check+0x442>
    assert(nr_free == 0);
ffffffffc0202af8:	481c                	lw	a5,16(s0)
ffffffffc0202afa:	2a079d63          	bnez	a5,ffffffffc0202db4 <default_check+0x422>
    free_page(p);
ffffffffc0202afe:	854e                	mv	a0,s3
ffffffffc0202b00:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0202b02:	01843023          	sd	s8,0(s0)
ffffffffc0202b06:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0202b0a:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0202b0e:	1e1000ef          	jal	ra,ffffffffc02034ee <free_pages>
    free_page(p1);
ffffffffc0202b12:	4585                	li	a1,1
ffffffffc0202b14:	8556                	mv	a0,s5
ffffffffc0202b16:	1d9000ef          	jal	ra,ffffffffc02034ee <free_pages>
    free_page(p2);
ffffffffc0202b1a:	4585                	li	a1,1
ffffffffc0202b1c:	8552                	mv	a0,s4
ffffffffc0202b1e:	1d1000ef          	jal	ra,ffffffffc02034ee <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0202b22:	4515                	li	a0,5
ffffffffc0202b24:	139000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0202b28:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0202b2a:	26050563          	beqz	a0,ffffffffc0202d94 <default_check+0x402>
ffffffffc0202b2e:	651c                	ld	a5,8(a0)
ffffffffc0202b30:	8385                	srli	a5,a5,0x1
ffffffffc0202b32:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0202b34:	54079063          	bnez	a5,ffffffffc0203074 <default_check+0x6e2>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0202b38:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0202b3a:	00043b03          	ld	s6,0(s0)
ffffffffc0202b3e:	00843a83          	ld	s5,8(s0)
ffffffffc0202b42:	e000                	sd	s0,0(s0)
ffffffffc0202b44:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0202b46:	117000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0202b4a:	50051563          	bnez	a0,ffffffffc0203054 <default_check+0x6c2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc0202b4e:	08098a13          	addi	s4,s3,128
ffffffffc0202b52:	8552                	mv	a0,s4
ffffffffc0202b54:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0202b56:	01042b83          	lw	s7,16(s0)
    nr_free = 0;
ffffffffc0202b5a:	000ac797          	auipc	a5,0xac
ffffffffc0202b5e:	e207ab23          	sw	zero,-458(a5) # ffffffffc02ae990 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0202b62:	18d000ef          	jal	ra,ffffffffc02034ee <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0202b66:	4511                	li	a0,4
ffffffffc0202b68:	0f5000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0202b6c:	4c051463          	bnez	a0,ffffffffc0203034 <default_check+0x6a2>
ffffffffc0202b70:	0889b783          	ld	a5,136(s3)
ffffffffc0202b74:	8385                	srli	a5,a5,0x1
ffffffffc0202b76:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0202b78:	48078e63          	beqz	a5,ffffffffc0203014 <default_check+0x682>
ffffffffc0202b7c:	0909a703          	lw	a4,144(s3)
ffffffffc0202b80:	478d                	li	a5,3
ffffffffc0202b82:	48f71963          	bne	a4,a5,ffffffffc0203014 <default_check+0x682>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0202b86:	450d                	li	a0,3
ffffffffc0202b88:	0d5000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0202b8c:	8c2a                	mv	s8,a0
ffffffffc0202b8e:	46050363          	beqz	a0,ffffffffc0202ff4 <default_check+0x662>
    assert(alloc_page() == NULL);
ffffffffc0202b92:	4505                	li	a0,1
ffffffffc0202b94:	0c9000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0202b98:	42051e63          	bnez	a0,ffffffffc0202fd4 <default_check+0x642>
    assert(p0 + 2 == p1);
ffffffffc0202b9c:	418a1c63          	bne	s4,s8,ffffffffc0202fb4 <default_check+0x622>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc0202ba0:	4585                	li	a1,1
ffffffffc0202ba2:	854e                	mv	a0,s3
ffffffffc0202ba4:	14b000ef          	jal	ra,ffffffffc02034ee <free_pages>
    free_pages(p1, 3);
ffffffffc0202ba8:	458d                	li	a1,3
ffffffffc0202baa:	8552                	mv	a0,s4
ffffffffc0202bac:	143000ef          	jal	ra,ffffffffc02034ee <free_pages>
ffffffffc0202bb0:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc0202bb4:	04098c13          	addi	s8,s3,64
ffffffffc0202bb8:	8385                	srli	a5,a5,0x1
ffffffffc0202bba:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0202bbc:	3c078c63          	beqz	a5,ffffffffc0202f94 <default_check+0x602>
ffffffffc0202bc0:	0109a703          	lw	a4,16(s3)
ffffffffc0202bc4:	4785                	li	a5,1
ffffffffc0202bc6:	3cf71763          	bne	a4,a5,ffffffffc0202f94 <default_check+0x602>
ffffffffc0202bca:	008a3783          	ld	a5,8(s4)
ffffffffc0202bce:	8385                	srli	a5,a5,0x1
ffffffffc0202bd0:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0202bd2:	3a078163          	beqz	a5,ffffffffc0202f74 <default_check+0x5e2>
ffffffffc0202bd6:	010a2703          	lw	a4,16(s4)
ffffffffc0202bda:	478d                	li	a5,3
ffffffffc0202bdc:	38f71c63          	bne	a4,a5,ffffffffc0202f74 <default_check+0x5e2>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0202be0:	4505                	li	a0,1
ffffffffc0202be2:	07b000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0202be6:	36a99763          	bne	s3,a0,ffffffffc0202f54 <default_check+0x5c2>
    free_page(p0);
ffffffffc0202bea:	4585                	li	a1,1
ffffffffc0202bec:	103000ef          	jal	ra,ffffffffc02034ee <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0202bf0:	4509                	li	a0,2
ffffffffc0202bf2:	06b000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0202bf6:	32aa1f63          	bne	s4,a0,ffffffffc0202f34 <default_check+0x5a2>

    free_pages(p0, 2);
ffffffffc0202bfa:	4589                	li	a1,2
ffffffffc0202bfc:	0f3000ef          	jal	ra,ffffffffc02034ee <free_pages>
    free_page(p2);
ffffffffc0202c00:	4585                	li	a1,1
ffffffffc0202c02:	8562                	mv	a0,s8
ffffffffc0202c04:	0eb000ef          	jal	ra,ffffffffc02034ee <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0202c08:	4515                	li	a0,5
ffffffffc0202c0a:	053000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0202c0e:	89aa                	mv	s3,a0
ffffffffc0202c10:	48050263          	beqz	a0,ffffffffc0203094 <default_check+0x702>
    assert(alloc_page() == NULL);
ffffffffc0202c14:	4505                	li	a0,1
ffffffffc0202c16:	047000ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0202c1a:	2c051d63          	bnez	a0,ffffffffc0202ef4 <default_check+0x562>

    assert(nr_free == 0);
ffffffffc0202c1e:	481c                	lw	a5,16(s0)
ffffffffc0202c20:	2a079a63          	bnez	a5,ffffffffc0202ed4 <default_check+0x542>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0202c24:	4595                	li	a1,5
ffffffffc0202c26:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0202c28:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0202c2c:	01643023          	sd	s6,0(s0)
ffffffffc0202c30:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc0202c34:	0bb000ef          	jal	ra,ffffffffc02034ee <free_pages>
    return listelm->next;
ffffffffc0202c38:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202c3a:	00878963          	beq	a5,s0,ffffffffc0202c4c <default_check+0x2ba>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0202c3e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0202c42:	679c                	ld	a5,8(a5)
ffffffffc0202c44:	397d                	addiw	s2,s2,-1
ffffffffc0202c46:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202c48:	fe879be3          	bne	a5,s0,ffffffffc0202c3e <default_check+0x2ac>
    }
    assert(count == 0);
ffffffffc0202c4c:	26091463          	bnez	s2,ffffffffc0202eb4 <default_check+0x522>
    assert(total == 0);
ffffffffc0202c50:	46049263          	bnez	s1,ffffffffc02030b4 <default_check+0x722>
}
ffffffffc0202c54:	60a6                	ld	ra,72(sp)
ffffffffc0202c56:	6406                	ld	s0,64(sp)
ffffffffc0202c58:	74e2                	ld	s1,56(sp)
ffffffffc0202c5a:	7942                	ld	s2,48(sp)
ffffffffc0202c5c:	79a2                	ld	s3,40(sp)
ffffffffc0202c5e:	7a02                	ld	s4,32(sp)
ffffffffc0202c60:	6ae2                	ld	s5,24(sp)
ffffffffc0202c62:	6b42                	ld	s6,16(sp)
ffffffffc0202c64:	6ba2                	ld	s7,8(sp)
ffffffffc0202c66:	6c02                	ld	s8,0(sp)
ffffffffc0202c68:	6161                	addi	sp,sp,80
ffffffffc0202c6a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0202c6c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0202c6e:	4481                	li	s1,0
ffffffffc0202c70:	4901                	li	s2,0
ffffffffc0202c72:	b38d                	j	ffffffffc02029d4 <default_check+0x42>
        assert(PageProperty(p));
ffffffffc0202c74:	00005697          	auipc	a3,0x5
ffffffffc0202c78:	9f468693          	addi	a3,a3,-1548 # ffffffffc0207668 <commands+0xdd8>
ffffffffc0202c7c:	00004617          	auipc	a2,0x4
ffffffffc0202c80:	02460613          	addi	a2,a2,36 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202c84:	0f000593          	li	a1,240
ffffffffc0202c88:	00005517          	auipc	a0,0x5
ffffffffc0202c8c:	d5850513          	addi	a0,a0,-680 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202c90:	d78fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0202c94:	00005697          	auipc	a3,0x5
ffffffffc0202c98:	dc468693          	addi	a3,a3,-572 # ffffffffc0207a58 <commands+0x11c8>
ffffffffc0202c9c:	00004617          	auipc	a2,0x4
ffffffffc0202ca0:	00460613          	addi	a2,a2,4 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202ca4:	0bd00593          	li	a1,189
ffffffffc0202ca8:	00005517          	auipc	a0,0x5
ffffffffc0202cac:	d3850513          	addi	a0,a0,-712 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202cb0:	d58fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0202cb4:	00005697          	auipc	a3,0x5
ffffffffc0202cb8:	dcc68693          	addi	a3,a3,-564 # ffffffffc0207a80 <commands+0x11f0>
ffffffffc0202cbc:	00004617          	auipc	a2,0x4
ffffffffc0202cc0:	fe460613          	addi	a2,a2,-28 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202cc4:	0be00593          	li	a1,190
ffffffffc0202cc8:	00005517          	auipc	a0,0x5
ffffffffc0202ccc:	d1850513          	addi	a0,a0,-744 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202cd0:	d38fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0202cd4:	00005697          	auipc	a3,0x5
ffffffffc0202cd8:	dec68693          	addi	a3,a3,-532 # ffffffffc0207ac0 <commands+0x1230>
ffffffffc0202cdc:	00004617          	auipc	a2,0x4
ffffffffc0202ce0:	fc460613          	addi	a2,a2,-60 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202ce4:	0c000593          	li	a1,192
ffffffffc0202ce8:	00005517          	auipc	a0,0x5
ffffffffc0202cec:	cf850513          	addi	a0,a0,-776 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202cf0:	d18fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0202cf4:	00005697          	auipc	a3,0x5
ffffffffc0202cf8:	e5468693          	addi	a3,a3,-428 # ffffffffc0207b48 <commands+0x12b8>
ffffffffc0202cfc:	00004617          	auipc	a2,0x4
ffffffffc0202d00:	fa460613          	addi	a2,a2,-92 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202d04:	0d900593          	li	a1,217
ffffffffc0202d08:	00005517          	auipc	a0,0x5
ffffffffc0202d0c:	cd850513          	addi	a0,a0,-808 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202d10:	cf8fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202d14:	00005697          	auipc	a3,0x5
ffffffffc0202d18:	ce468693          	addi	a3,a3,-796 # ffffffffc02079f8 <commands+0x1168>
ffffffffc0202d1c:	00004617          	auipc	a2,0x4
ffffffffc0202d20:	f8460613          	addi	a2,a2,-124 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202d24:	0d200593          	li	a1,210
ffffffffc0202d28:	00005517          	auipc	a0,0x5
ffffffffc0202d2c:	cb850513          	addi	a0,a0,-840 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202d30:	cd8fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(nr_free == 3);
ffffffffc0202d34:	00005697          	auipc	a3,0x5
ffffffffc0202d38:	e0468693          	addi	a3,a3,-508 # ffffffffc0207b38 <commands+0x12a8>
ffffffffc0202d3c:	00004617          	auipc	a2,0x4
ffffffffc0202d40:	f6460613          	addi	a2,a2,-156 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202d44:	0d000593          	li	a1,208
ffffffffc0202d48:	00005517          	auipc	a0,0x5
ffffffffc0202d4c:	c9850513          	addi	a0,a0,-872 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202d50:	cb8fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202d54:	00005697          	auipc	a3,0x5
ffffffffc0202d58:	dcc68693          	addi	a3,a3,-564 # ffffffffc0207b20 <commands+0x1290>
ffffffffc0202d5c:	00004617          	auipc	a2,0x4
ffffffffc0202d60:	f4460613          	addi	a2,a2,-188 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202d64:	0cb00593          	li	a1,203
ffffffffc0202d68:	00005517          	auipc	a0,0x5
ffffffffc0202d6c:	c7850513          	addi	a0,a0,-904 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202d70:	c98fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0202d74:	00005697          	auipc	a3,0x5
ffffffffc0202d78:	d8c68693          	addi	a3,a3,-628 # ffffffffc0207b00 <commands+0x1270>
ffffffffc0202d7c:	00004617          	auipc	a2,0x4
ffffffffc0202d80:	f2460613          	addi	a2,a2,-220 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202d84:	0c200593          	li	a1,194
ffffffffc0202d88:	00005517          	auipc	a0,0x5
ffffffffc0202d8c:	c5850513          	addi	a0,a0,-936 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202d90:	c78fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(p0 != NULL);
ffffffffc0202d94:	00005697          	auipc	a3,0x5
ffffffffc0202d98:	dec68693          	addi	a3,a3,-532 # ffffffffc0207b80 <commands+0x12f0>
ffffffffc0202d9c:	00004617          	auipc	a2,0x4
ffffffffc0202da0:	f0460613          	addi	a2,a2,-252 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202da4:	0f800593          	li	a1,248
ffffffffc0202da8:	00005517          	auipc	a0,0x5
ffffffffc0202dac:	c3850513          	addi	a0,a0,-968 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202db0:	c58fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(nr_free == 0);
ffffffffc0202db4:	00005697          	auipc	a3,0x5
ffffffffc0202db8:	a5468693          	addi	a3,a3,-1452 # ffffffffc0207808 <commands+0xf78>
ffffffffc0202dbc:	00004617          	auipc	a2,0x4
ffffffffc0202dc0:	ee460613          	addi	a2,a2,-284 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202dc4:	0df00593          	li	a1,223
ffffffffc0202dc8:	00005517          	auipc	a0,0x5
ffffffffc0202dcc:	c1850513          	addi	a0,a0,-1000 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202dd0:	c38fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202dd4:	00005697          	auipc	a3,0x5
ffffffffc0202dd8:	d4c68693          	addi	a3,a3,-692 # ffffffffc0207b20 <commands+0x1290>
ffffffffc0202ddc:	00004617          	auipc	a2,0x4
ffffffffc0202de0:	ec460613          	addi	a2,a2,-316 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202de4:	0dd00593          	li	a1,221
ffffffffc0202de8:	00005517          	auipc	a0,0x5
ffffffffc0202dec:	bf850513          	addi	a0,a0,-1032 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202df0:	c18fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0202df4:	00005697          	auipc	a3,0x5
ffffffffc0202df8:	d6c68693          	addi	a3,a3,-660 # ffffffffc0207b60 <commands+0x12d0>
ffffffffc0202dfc:	00004617          	auipc	a2,0x4
ffffffffc0202e00:	ea460613          	addi	a2,a2,-348 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202e04:	0dc00593          	li	a1,220
ffffffffc0202e08:	00005517          	auipc	a0,0x5
ffffffffc0202e0c:	bd850513          	addi	a0,a0,-1064 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202e10:	bf8fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0202e14:	00005697          	auipc	a3,0x5
ffffffffc0202e18:	be468693          	addi	a3,a3,-1052 # ffffffffc02079f8 <commands+0x1168>
ffffffffc0202e1c:	00004617          	auipc	a2,0x4
ffffffffc0202e20:	e8460613          	addi	a2,a2,-380 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202e24:	0b900593          	li	a1,185
ffffffffc0202e28:	00005517          	auipc	a0,0x5
ffffffffc0202e2c:	bb850513          	addi	a0,a0,-1096 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202e30:	bd8fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202e34:	00005697          	auipc	a3,0x5
ffffffffc0202e38:	cec68693          	addi	a3,a3,-788 # ffffffffc0207b20 <commands+0x1290>
ffffffffc0202e3c:	00004617          	auipc	a2,0x4
ffffffffc0202e40:	e6460613          	addi	a2,a2,-412 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202e44:	0d600593          	li	a1,214
ffffffffc0202e48:	00005517          	auipc	a0,0x5
ffffffffc0202e4c:	b9850513          	addi	a0,a0,-1128 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202e50:	bb8fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202e54:	00005697          	auipc	a3,0x5
ffffffffc0202e58:	be468693          	addi	a3,a3,-1052 # ffffffffc0207a38 <commands+0x11a8>
ffffffffc0202e5c:	00004617          	auipc	a2,0x4
ffffffffc0202e60:	e4460613          	addi	a2,a2,-444 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202e64:	0d400593          	li	a1,212
ffffffffc0202e68:	00005517          	auipc	a0,0x5
ffffffffc0202e6c:	b7850513          	addi	a0,a0,-1160 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202e70:	b98fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0202e74:	00005697          	auipc	a3,0x5
ffffffffc0202e78:	ba468693          	addi	a3,a3,-1116 # ffffffffc0207a18 <commands+0x1188>
ffffffffc0202e7c:	00004617          	auipc	a2,0x4
ffffffffc0202e80:	e2460613          	addi	a2,a2,-476 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202e84:	0d300593          	li	a1,211
ffffffffc0202e88:	00005517          	auipc	a0,0x5
ffffffffc0202e8c:	b5850513          	addi	a0,a0,-1192 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202e90:	b78fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0202e94:	00005697          	auipc	a3,0x5
ffffffffc0202e98:	ba468693          	addi	a3,a3,-1116 # ffffffffc0207a38 <commands+0x11a8>
ffffffffc0202e9c:	00004617          	auipc	a2,0x4
ffffffffc0202ea0:	e0460613          	addi	a2,a2,-508 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202ea4:	0bb00593          	li	a1,187
ffffffffc0202ea8:	00005517          	auipc	a0,0x5
ffffffffc0202eac:	b3850513          	addi	a0,a0,-1224 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202eb0:	b58fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(count == 0);
ffffffffc0202eb4:	00005697          	auipc	a3,0x5
ffffffffc0202eb8:	e1c68693          	addi	a3,a3,-484 # ffffffffc0207cd0 <commands+0x1440>
ffffffffc0202ebc:	00004617          	auipc	a2,0x4
ffffffffc0202ec0:	de460613          	addi	a2,a2,-540 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202ec4:	12500593          	li	a1,293
ffffffffc0202ec8:	00005517          	auipc	a0,0x5
ffffffffc0202ecc:	b1850513          	addi	a0,a0,-1256 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202ed0:	b38fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(nr_free == 0);
ffffffffc0202ed4:	00005697          	auipc	a3,0x5
ffffffffc0202ed8:	93468693          	addi	a3,a3,-1740 # ffffffffc0207808 <commands+0xf78>
ffffffffc0202edc:	00004617          	auipc	a2,0x4
ffffffffc0202ee0:	dc460613          	addi	a2,a2,-572 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202ee4:	11a00593          	li	a1,282
ffffffffc0202ee8:	00005517          	auipc	a0,0x5
ffffffffc0202eec:	af850513          	addi	a0,a0,-1288 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202ef0:	b18fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202ef4:	00005697          	auipc	a3,0x5
ffffffffc0202ef8:	c2c68693          	addi	a3,a3,-980 # ffffffffc0207b20 <commands+0x1290>
ffffffffc0202efc:	00004617          	auipc	a2,0x4
ffffffffc0202f00:	da460613          	addi	a2,a2,-604 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202f04:	11800593          	li	a1,280
ffffffffc0202f08:	00005517          	auipc	a0,0x5
ffffffffc0202f0c:	ad850513          	addi	a0,a0,-1320 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202f10:	af8fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0202f14:	00005697          	auipc	a3,0x5
ffffffffc0202f18:	bcc68693          	addi	a3,a3,-1076 # ffffffffc0207ae0 <commands+0x1250>
ffffffffc0202f1c:	00004617          	auipc	a2,0x4
ffffffffc0202f20:	d8460613          	addi	a2,a2,-636 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202f24:	0c100593          	li	a1,193
ffffffffc0202f28:	00005517          	auipc	a0,0x5
ffffffffc0202f2c:	ab850513          	addi	a0,a0,-1352 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202f30:	ad8fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0202f34:	00005697          	auipc	a3,0x5
ffffffffc0202f38:	d5c68693          	addi	a3,a3,-676 # ffffffffc0207c90 <commands+0x1400>
ffffffffc0202f3c:	00004617          	auipc	a2,0x4
ffffffffc0202f40:	d6460613          	addi	a2,a2,-668 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202f44:	11200593          	li	a1,274
ffffffffc0202f48:	00005517          	auipc	a0,0x5
ffffffffc0202f4c:	a9850513          	addi	a0,a0,-1384 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202f50:	ab8fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0202f54:	00005697          	auipc	a3,0x5
ffffffffc0202f58:	d1c68693          	addi	a3,a3,-740 # ffffffffc0207c70 <commands+0x13e0>
ffffffffc0202f5c:	00004617          	auipc	a2,0x4
ffffffffc0202f60:	d4460613          	addi	a2,a2,-700 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202f64:	11000593          	li	a1,272
ffffffffc0202f68:	00005517          	auipc	a0,0x5
ffffffffc0202f6c:	a7850513          	addi	a0,a0,-1416 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202f70:	a98fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0202f74:	00005697          	auipc	a3,0x5
ffffffffc0202f78:	cd468693          	addi	a3,a3,-812 # ffffffffc0207c48 <commands+0x13b8>
ffffffffc0202f7c:	00004617          	auipc	a2,0x4
ffffffffc0202f80:	d2460613          	addi	a2,a2,-732 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202f84:	10e00593          	li	a1,270
ffffffffc0202f88:	00005517          	auipc	a0,0x5
ffffffffc0202f8c:	a5850513          	addi	a0,a0,-1448 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202f90:	a78fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0202f94:	00005697          	auipc	a3,0x5
ffffffffc0202f98:	c8c68693          	addi	a3,a3,-884 # ffffffffc0207c20 <commands+0x1390>
ffffffffc0202f9c:	00004617          	auipc	a2,0x4
ffffffffc0202fa0:	d0460613          	addi	a2,a2,-764 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202fa4:	10d00593          	li	a1,269
ffffffffc0202fa8:	00005517          	auipc	a0,0x5
ffffffffc0202fac:	a3850513          	addi	a0,a0,-1480 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202fb0:	a58fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(p0 + 2 == p1);
ffffffffc0202fb4:	00005697          	auipc	a3,0x5
ffffffffc0202fb8:	c5c68693          	addi	a3,a3,-932 # ffffffffc0207c10 <commands+0x1380>
ffffffffc0202fbc:	00004617          	auipc	a2,0x4
ffffffffc0202fc0:	ce460613          	addi	a2,a2,-796 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202fc4:	10800593          	li	a1,264
ffffffffc0202fc8:	00005517          	auipc	a0,0x5
ffffffffc0202fcc:	a1850513          	addi	a0,a0,-1512 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202fd0:	a38fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0202fd4:	00005697          	auipc	a3,0x5
ffffffffc0202fd8:	b4c68693          	addi	a3,a3,-1204 # ffffffffc0207b20 <commands+0x1290>
ffffffffc0202fdc:	00004617          	auipc	a2,0x4
ffffffffc0202fe0:	cc460613          	addi	a2,a2,-828 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0202fe4:	10700593          	li	a1,263
ffffffffc0202fe8:	00005517          	auipc	a0,0x5
ffffffffc0202fec:	9f850513          	addi	a0,a0,-1544 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0202ff0:	a18fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0202ff4:	00005697          	auipc	a3,0x5
ffffffffc0202ff8:	bfc68693          	addi	a3,a3,-1028 # ffffffffc0207bf0 <commands+0x1360>
ffffffffc0202ffc:	00004617          	auipc	a2,0x4
ffffffffc0203000:	ca460613          	addi	a2,a2,-860 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0203004:	10600593          	li	a1,262
ffffffffc0203008:	00005517          	auipc	a0,0x5
ffffffffc020300c:	9d850513          	addi	a0,a0,-1576 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0203010:	9f8fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0203014:	00005697          	auipc	a3,0x5
ffffffffc0203018:	bac68693          	addi	a3,a3,-1108 # ffffffffc0207bc0 <commands+0x1330>
ffffffffc020301c:	00004617          	auipc	a2,0x4
ffffffffc0203020:	c8460613          	addi	a2,a2,-892 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0203024:	10500593          	li	a1,261
ffffffffc0203028:	00005517          	auipc	a0,0x5
ffffffffc020302c:	9b850513          	addi	a0,a0,-1608 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0203030:	9d8fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0203034:	00005697          	auipc	a3,0x5
ffffffffc0203038:	b7468693          	addi	a3,a3,-1164 # ffffffffc0207ba8 <commands+0x1318>
ffffffffc020303c:	00004617          	auipc	a2,0x4
ffffffffc0203040:	c6460613          	addi	a2,a2,-924 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0203044:	10400593          	li	a1,260
ffffffffc0203048:	00005517          	auipc	a0,0x5
ffffffffc020304c:	99850513          	addi	a0,a0,-1640 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0203050:	9b8fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0203054:	00005697          	auipc	a3,0x5
ffffffffc0203058:	acc68693          	addi	a3,a3,-1332 # ffffffffc0207b20 <commands+0x1290>
ffffffffc020305c:	00004617          	auipc	a2,0x4
ffffffffc0203060:	c4460613          	addi	a2,a2,-956 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0203064:	0fe00593          	li	a1,254
ffffffffc0203068:	00005517          	auipc	a0,0x5
ffffffffc020306c:	97850513          	addi	a0,a0,-1672 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0203070:	998fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(!PageProperty(p0));
ffffffffc0203074:	00005697          	auipc	a3,0x5
ffffffffc0203078:	b1c68693          	addi	a3,a3,-1252 # ffffffffc0207b90 <commands+0x1300>
ffffffffc020307c:	00004617          	auipc	a2,0x4
ffffffffc0203080:	c2460613          	addi	a2,a2,-988 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0203084:	0f900593          	li	a1,249
ffffffffc0203088:	00005517          	auipc	a0,0x5
ffffffffc020308c:	95850513          	addi	a0,a0,-1704 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0203090:	978fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0203094:	00005697          	auipc	a3,0x5
ffffffffc0203098:	c1c68693          	addi	a3,a3,-996 # ffffffffc0207cb0 <commands+0x1420>
ffffffffc020309c:	00004617          	auipc	a2,0x4
ffffffffc02030a0:	c0460613          	addi	a2,a2,-1020 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02030a4:	11700593          	li	a1,279
ffffffffc02030a8:	00005517          	auipc	a0,0x5
ffffffffc02030ac:	93850513          	addi	a0,a0,-1736 # ffffffffc02079e0 <commands+0x1150>
ffffffffc02030b0:	958fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(total == 0);
ffffffffc02030b4:	00005697          	auipc	a3,0x5
ffffffffc02030b8:	c2c68693          	addi	a3,a3,-980 # ffffffffc0207ce0 <commands+0x1450>
ffffffffc02030bc:	00004617          	auipc	a2,0x4
ffffffffc02030c0:	be460613          	addi	a2,a2,-1052 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02030c4:	12600593          	li	a1,294
ffffffffc02030c8:	00005517          	auipc	a0,0x5
ffffffffc02030cc:	91850513          	addi	a0,a0,-1768 # ffffffffc02079e0 <commands+0x1150>
ffffffffc02030d0:	938fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(total == nr_free_pages());
ffffffffc02030d4:	00004697          	auipc	a3,0x4
ffffffffc02030d8:	5a468693          	addi	a3,a3,1444 # ffffffffc0207678 <commands+0xde8>
ffffffffc02030dc:	00004617          	auipc	a2,0x4
ffffffffc02030e0:	bc460613          	addi	a2,a2,-1084 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02030e4:	0f300593          	li	a1,243
ffffffffc02030e8:	00005517          	auipc	a0,0x5
ffffffffc02030ec:	8f850513          	addi	a0,a0,-1800 # ffffffffc02079e0 <commands+0x1150>
ffffffffc02030f0:	918fd0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02030f4:	00005697          	auipc	a3,0x5
ffffffffc02030f8:	92468693          	addi	a3,a3,-1756 # ffffffffc0207a18 <commands+0x1188>
ffffffffc02030fc:	00004617          	auipc	a2,0x4
ffffffffc0203100:	ba460613          	addi	a2,a2,-1116 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0203104:	0ba00593          	li	a1,186
ffffffffc0203108:	00005517          	auipc	a0,0x5
ffffffffc020310c:	8d850513          	addi	a0,a0,-1832 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0203110:	8f8fd0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0203114 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0203114:	1141                	addi	sp,sp,-16
ffffffffc0203116:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0203118:	14058463          	beqz	a1,ffffffffc0203260 <default_free_pages+0x14c>
    for (; p != base + n; p ++) {
ffffffffc020311c:	00659693          	slli	a3,a1,0x6
ffffffffc0203120:	96aa                	add	a3,a3,a0
ffffffffc0203122:	87aa                	mv	a5,a0
ffffffffc0203124:	02d50263          	beq	a0,a3,ffffffffc0203148 <default_free_pages+0x34>
ffffffffc0203128:	6798                	ld	a4,8(a5)
ffffffffc020312a:	8b05                	andi	a4,a4,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020312c:	10071a63          	bnez	a4,ffffffffc0203240 <default_free_pages+0x12c>
ffffffffc0203130:	6798                	ld	a4,8(a5)
ffffffffc0203132:	8b09                	andi	a4,a4,2
ffffffffc0203134:	10071663          	bnez	a4,ffffffffc0203240 <default_free_pages+0x12c>
        p->flags = 0;
ffffffffc0203138:	0007b423          	sd	zero,8(a5)
    page->ref = val;
ffffffffc020313c:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0203140:	04078793          	addi	a5,a5,64
ffffffffc0203144:	fed792e3          	bne	a5,a3,ffffffffc0203128 <default_free_pages+0x14>
    base->property = n;
ffffffffc0203148:	2581                	sext.w	a1,a1
ffffffffc020314a:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020314c:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203150:	4789                	li	a5,2
ffffffffc0203152:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0203156:	000ac697          	auipc	a3,0xac
ffffffffc020315a:	82a68693          	addi	a3,a3,-2006 # ffffffffc02ae980 <free_area>
ffffffffc020315e:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0203160:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0203162:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0203166:	9db9                	addw	a1,a1,a4
ffffffffc0203168:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc020316a:	0ad78463          	beq	a5,a3,ffffffffc0203212 <default_free_pages+0xfe>
            struct Page* page = le2page(le, page_link);
ffffffffc020316e:	fe878713          	addi	a4,a5,-24
ffffffffc0203172:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0203176:	4581                	li	a1,0
            if (base < page) {
ffffffffc0203178:	00e56a63          	bltu	a0,a4,ffffffffc020318c <default_free_pages+0x78>
    return listelm->next;
ffffffffc020317c:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020317e:	04d70c63          	beq	a4,a3,ffffffffc02031d6 <default_free_pages+0xc2>
    for (; p != base + n; p ++) {
ffffffffc0203182:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0203184:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0203188:	fee57ae3          	bgeu	a0,a4,ffffffffc020317c <default_free_pages+0x68>
ffffffffc020318c:	c199                	beqz	a1,ffffffffc0203192 <default_free_pages+0x7e>
ffffffffc020318e:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0203192:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc0203194:	e390                	sd	a2,0(a5)
ffffffffc0203196:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0203198:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020319a:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc020319c:	00d70d63          	beq	a4,a3,ffffffffc02031b6 <default_free_pages+0xa2>
        if (p + p->property == base) {
ffffffffc02031a0:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02031a4:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base) {
ffffffffc02031a8:	02059813          	slli	a6,a1,0x20
ffffffffc02031ac:	01a85793          	srli	a5,a6,0x1a
ffffffffc02031b0:	97b2                	add	a5,a5,a2
ffffffffc02031b2:	02f50c63          	beq	a0,a5,ffffffffc02031ea <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02031b6:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc02031b8:	00d78c63          	beq	a5,a3,ffffffffc02031d0 <default_free_pages+0xbc>
        if (base + base->property == p) {
ffffffffc02031bc:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02031be:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p) {
ffffffffc02031c2:	02061593          	slli	a1,a2,0x20
ffffffffc02031c6:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02031ca:	972a                	add	a4,a4,a0
ffffffffc02031cc:	04e68a63          	beq	a3,a4,ffffffffc0203220 <default_free_pages+0x10c>
}
ffffffffc02031d0:	60a2                	ld	ra,8(sp)
ffffffffc02031d2:	0141                	addi	sp,sp,16
ffffffffc02031d4:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02031d6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02031d8:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02031da:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02031dc:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02031de:	02d70763          	beq	a4,a3,ffffffffc020320c <default_free_pages+0xf8>
    prev->next = next->prev = elm;
ffffffffc02031e2:	8832                	mv	a6,a2
ffffffffc02031e4:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02031e6:	87ba                	mv	a5,a4
ffffffffc02031e8:	bf71                	j	ffffffffc0203184 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02031ea:	491c                	lw	a5,16(a0)
ffffffffc02031ec:	9dbd                	addw	a1,a1,a5
ffffffffc02031ee:	feb72c23          	sw	a1,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02031f2:	57f5                	li	a5,-3
ffffffffc02031f4:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02031f8:	01853803          	ld	a6,24(a0)
ffffffffc02031fc:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc02031fe:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc0203200:	00b83423          	sd	a1,8(a6)
    return listelm->next;
ffffffffc0203204:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc0203206:	0105b023          	sd	a6,0(a1) # 1000 <_binary_obj___user_faultread_out_size-0x8bd0>
ffffffffc020320a:	b77d                	j	ffffffffc02031b8 <default_free_pages+0xa4>
ffffffffc020320c:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc020320e:	873e                	mv	a4,a5
ffffffffc0203210:	bf41                	j	ffffffffc02031a0 <default_free_pages+0x8c>
}
ffffffffc0203212:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0203214:	e390                	sd	a2,0(a5)
ffffffffc0203216:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0203218:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020321a:	ed1c                	sd	a5,24(a0)
ffffffffc020321c:	0141                	addi	sp,sp,16
ffffffffc020321e:	8082                	ret
            base->property += p->property;
ffffffffc0203220:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203224:	ff078693          	addi	a3,a5,-16
ffffffffc0203228:	9e39                	addw	a2,a2,a4
ffffffffc020322a:	c910                	sw	a2,16(a0)
ffffffffc020322c:	5775                	li	a4,-3
ffffffffc020322e:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0203232:	6398                	ld	a4,0(a5)
ffffffffc0203234:	679c                	ld	a5,8(a5)
}
ffffffffc0203236:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0203238:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020323a:	e398                	sd	a4,0(a5)
ffffffffc020323c:	0141                	addi	sp,sp,16
ffffffffc020323e:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0203240:	00005697          	auipc	a3,0x5
ffffffffc0203244:	ab868693          	addi	a3,a3,-1352 # ffffffffc0207cf8 <commands+0x1468>
ffffffffc0203248:	00004617          	auipc	a2,0x4
ffffffffc020324c:	a5860613          	addi	a2,a2,-1448 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0203250:	08300593          	li	a1,131
ffffffffc0203254:	00004517          	auipc	a0,0x4
ffffffffc0203258:	78c50513          	addi	a0,a0,1932 # ffffffffc02079e0 <commands+0x1150>
ffffffffc020325c:	fadfc0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(n > 0);
ffffffffc0203260:	00005697          	auipc	a3,0x5
ffffffffc0203264:	a9068693          	addi	a3,a3,-1392 # ffffffffc0207cf0 <commands+0x1460>
ffffffffc0203268:	00004617          	auipc	a2,0x4
ffffffffc020326c:	a3860613          	addi	a2,a2,-1480 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0203270:	08000593          	li	a1,128
ffffffffc0203274:	00004517          	auipc	a0,0x4
ffffffffc0203278:	76c50513          	addi	a0,a0,1900 # ffffffffc02079e0 <commands+0x1150>
ffffffffc020327c:	f8dfc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0203280 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0203280:	c941                	beqz	a0,ffffffffc0203310 <default_alloc_pages+0x90>
    if (n > nr_free) {
ffffffffc0203282:	000ab597          	auipc	a1,0xab
ffffffffc0203286:	6fe58593          	addi	a1,a1,1790 # ffffffffc02ae980 <free_area>
ffffffffc020328a:	0105a803          	lw	a6,16(a1)
ffffffffc020328e:	872a                	mv	a4,a0
ffffffffc0203290:	02081793          	slli	a5,a6,0x20
ffffffffc0203294:	9381                	srli	a5,a5,0x20
ffffffffc0203296:	00a7ee63          	bltu	a5,a0,ffffffffc02032b2 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc020329a:	87ae                	mv	a5,a1
ffffffffc020329c:	a801                	j	ffffffffc02032ac <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc020329e:	ff87a683          	lw	a3,-8(a5)
ffffffffc02032a2:	02069613          	slli	a2,a3,0x20
ffffffffc02032a6:	9201                	srli	a2,a2,0x20
ffffffffc02032a8:	00e67763          	bgeu	a2,a4,ffffffffc02032b6 <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc02032ac:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02032ae:	feb798e3          	bne	a5,a1,ffffffffc020329e <default_alloc_pages+0x1e>
        return NULL;
ffffffffc02032b2:	4501                	li	a0,0
}
ffffffffc02032b4:	8082                	ret
    return listelm->prev;
ffffffffc02032b6:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02032ba:	0087b303          	ld	t1,8(a5)
        struct Page *p = le2page(le, page_link);
ffffffffc02032be:	fe878513          	addi	a0,a5,-24
            p->property = page->property - n;
ffffffffc02032c2:	00070e1b          	sext.w	t3,a4
    prev->next = next;
ffffffffc02032c6:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc02032ca:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc02032ce:	02c77863          	bgeu	a4,a2,ffffffffc02032fe <default_alloc_pages+0x7e>
            struct Page *p = page + n;
ffffffffc02032d2:	071a                	slli	a4,a4,0x6
ffffffffc02032d4:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02032d6:	41c686bb          	subw	a3,a3,t3
ffffffffc02032da:	cb14                	sw	a3,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02032dc:	00870613          	addi	a2,a4,8
ffffffffc02032e0:	4689                	li	a3,2
ffffffffc02032e2:	40d6302f          	amoor.d	zero,a3,(a2)
    __list_add(elm, listelm, listelm->next);
ffffffffc02032e6:	0088b683          	ld	a3,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc02032ea:	01870613          	addi	a2,a4,24
        nr_free -= n;
ffffffffc02032ee:	0105a803          	lw	a6,16(a1)
    prev->next = next->prev = elm;
ffffffffc02032f2:	e290                	sd	a2,0(a3)
ffffffffc02032f4:	00c8b423          	sd	a2,8(a7)
    elm->next = next;
ffffffffc02032f8:	f314                	sd	a3,32(a4)
    elm->prev = prev;
ffffffffc02032fa:	01173c23          	sd	a7,24(a4)
ffffffffc02032fe:	41c8083b          	subw	a6,a6,t3
ffffffffc0203302:	0105a823          	sw	a6,16(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0203306:	5775                	li	a4,-3
ffffffffc0203308:	17c1                	addi	a5,a5,-16
ffffffffc020330a:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020330e:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc0203310:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0203312:	00005697          	auipc	a3,0x5
ffffffffc0203316:	9de68693          	addi	a3,a3,-1570 # ffffffffc0207cf0 <commands+0x1460>
ffffffffc020331a:	00004617          	auipc	a2,0x4
ffffffffc020331e:	98660613          	addi	a2,a2,-1658 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0203322:	06200593          	li	a1,98
ffffffffc0203326:	00004517          	auipc	a0,0x4
ffffffffc020332a:	6ba50513          	addi	a0,a0,1722 # ffffffffc02079e0 <commands+0x1150>
default_alloc_pages(size_t n) {
ffffffffc020332e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0203330:	ed9fc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0203334 <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc0203334:	1141                	addi	sp,sp,-16
ffffffffc0203336:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0203338:	c5f1                	beqz	a1,ffffffffc0203404 <default_init_memmap+0xd0>
    for (; p != base + n; p ++) {
ffffffffc020333a:	00659693          	slli	a3,a1,0x6
ffffffffc020333e:	96aa                	add	a3,a3,a0
ffffffffc0203340:	87aa                	mv	a5,a0
ffffffffc0203342:	00d50f63          	beq	a0,a3,ffffffffc0203360 <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0203346:	6798                	ld	a4,8(a5)
ffffffffc0203348:	8b05                	andi	a4,a4,1
        assert(PageReserved(p));
ffffffffc020334a:	cf49                	beqz	a4,ffffffffc02033e4 <default_init_memmap+0xb0>
        p->flags = p->property = 0;
ffffffffc020334c:	0007a823          	sw	zero,16(a5)
ffffffffc0203350:	0007b423          	sd	zero,8(a5)
ffffffffc0203354:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0203358:	04078793          	addi	a5,a5,64
ffffffffc020335c:	fed795e3          	bne	a5,a3,ffffffffc0203346 <default_init_memmap+0x12>
    base->property = n;
ffffffffc0203360:	2581                	sext.w	a1,a1
ffffffffc0203362:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0203364:	4789                	li	a5,2
ffffffffc0203366:	00850713          	addi	a4,a0,8
ffffffffc020336a:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020336e:	000ab697          	auipc	a3,0xab
ffffffffc0203372:	61268693          	addi	a3,a3,1554 # ffffffffc02ae980 <free_area>
ffffffffc0203376:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0203378:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020337a:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc020337e:	9db9                	addw	a1,a1,a4
ffffffffc0203380:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0203382:	04d78a63          	beq	a5,a3,ffffffffc02033d6 <default_init_memmap+0xa2>
            struct Page* page = le2page(le, page_link);
ffffffffc0203386:	fe878713          	addi	a4,a5,-24
ffffffffc020338a:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020338e:	4581                	li	a1,0
            if (base < page) {
ffffffffc0203390:	00e56a63          	bltu	a0,a4,ffffffffc02033a4 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc0203394:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0203396:	02d70263          	beq	a4,a3,ffffffffc02033ba <default_init_memmap+0x86>
    for (; p != base + n; p ++) {
ffffffffc020339a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020339c:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02033a0:	fee57ae3          	bgeu	a0,a4,ffffffffc0203394 <default_init_memmap+0x60>
ffffffffc02033a4:	c199                	beqz	a1,ffffffffc02033aa <default_init_memmap+0x76>
ffffffffc02033a6:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02033aa:	6398                	ld	a4,0(a5)
}
ffffffffc02033ac:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02033ae:	e390                	sd	a2,0(a5)
ffffffffc02033b0:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc02033b2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02033b4:	ed18                	sd	a4,24(a0)
ffffffffc02033b6:	0141                	addi	sp,sp,16
ffffffffc02033b8:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02033ba:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02033bc:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02033be:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02033c0:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02033c2:	00d70663          	beq	a4,a3,ffffffffc02033ce <default_init_memmap+0x9a>
    prev->next = next->prev = elm;
ffffffffc02033c6:	8832                	mv	a6,a2
ffffffffc02033c8:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02033ca:	87ba                	mv	a5,a4
ffffffffc02033cc:	bfc1                	j	ffffffffc020339c <default_init_memmap+0x68>
}
ffffffffc02033ce:	60a2                	ld	ra,8(sp)
ffffffffc02033d0:	e290                	sd	a2,0(a3)
ffffffffc02033d2:	0141                	addi	sp,sp,16
ffffffffc02033d4:	8082                	ret
ffffffffc02033d6:	60a2                	ld	ra,8(sp)
ffffffffc02033d8:	e390                	sd	a2,0(a5)
ffffffffc02033da:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02033dc:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02033de:	ed1c                	sd	a5,24(a0)
ffffffffc02033e0:	0141                	addi	sp,sp,16
ffffffffc02033e2:	8082                	ret
        assert(PageReserved(p));
ffffffffc02033e4:	00005697          	auipc	a3,0x5
ffffffffc02033e8:	93c68693          	addi	a3,a3,-1732 # ffffffffc0207d20 <commands+0x1490>
ffffffffc02033ec:	00004617          	auipc	a2,0x4
ffffffffc02033f0:	8b460613          	addi	a2,a2,-1868 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02033f4:	04900593          	li	a1,73
ffffffffc02033f8:	00004517          	auipc	a0,0x4
ffffffffc02033fc:	5e850513          	addi	a0,a0,1512 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0203400:	e09fc0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(n > 0);
ffffffffc0203404:	00005697          	auipc	a3,0x5
ffffffffc0203408:	8ec68693          	addi	a3,a3,-1812 # ffffffffc0207cf0 <commands+0x1460>
ffffffffc020340c:	00004617          	auipc	a2,0x4
ffffffffc0203410:	89460613          	addi	a2,a2,-1900 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0203414:	04600593          	li	a1,70
ffffffffc0203418:	00004517          	auipc	a0,0x4
ffffffffc020341c:	5c850513          	addi	a0,a0,1480 # ffffffffc02079e0 <commands+0x1150>
ffffffffc0203420:	de9fc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0203424 <pa2page.part.0>:
pa2page(uintptr_t pa) {
ffffffffc0203424:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0203426:	00004617          	auipc	a2,0x4
ffffffffc020342a:	ffa60613          	addi	a2,a2,-6 # ffffffffc0207420 <commands+0xb90>
ffffffffc020342e:	06300593          	li	a1,99
ffffffffc0203432:	00004517          	auipc	a0,0x4
ffffffffc0203436:	00e50513          	addi	a0,a0,14 # ffffffffc0207440 <commands+0xbb0>
pa2page(uintptr_t pa) {
ffffffffc020343a:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc020343c:	dcdfc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0203440 <pte2page.part.0>:
pte2page(pte_t pte) {
ffffffffc0203440:	1141                	addi	sp,sp,-16
        panic("pte2page called with invalid pte");
ffffffffc0203442:	00004617          	auipc	a2,0x4
ffffffffc0203446:	3ee60613          	addi	a2,a2,1006 # ffffffffc0207830 <commands+0xfa0>
ffffffffc020344a:	07500593          	li	a1,117
ffffffffc020344e:	00004517          	auipc	a0,0x4
ffffffffc0203452:	ff250513          	addi	a0,a0,-14 # ffffffffc0207440 <commands+0xbb0>
pte2page(pte_t pte) {
ffffffffc0203456:	e406                	sd	ra,8(sp)
        panic("pte2page called with invalid pte");
ffffffffc0203458:	db1fc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc020345c <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc020345c:	7139                	addi	sp,sp,-64
ffffffffc020345e:	f426                	sd	s1,40(sp)
ffffffffc0203460:	f04a                	sd	s2,32(sp)
ffffffffc0203462:	ec4e                	sd	s3,24(sp)
ffffffffc0203464:	e852                	sd	s4,16(sp)
ffffffffc0203466:	e456                	sd	s5,8(sp)
ffffffffc0203468:	e05a                	sd	s6,0(sp)
ffffffffc020346a:	fc06                	sd	ra,56(sp)
ffffffffc020346c:	f822                	sd	s0,48(sp)
ffffffffc020346e:	84aa                	mv	s1,a0
ffffffffc0203470:	000af917          	auipc	s2,0xaf
ffffffffc0203474:	5a090913          	addi	s2,s2,1440 # ffffffffc02b2a10 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0203478:	4a05                	li	s4,1
ffffffffc020347a:	000afa97          	auipc	s5,0xaf
ffffffffc020347e:	56ea8a93          	addi	s5,s5,1390 # ffffffffc02b29e8 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0203482:	0005099b          	sext.w	s3,a0
ffffffffc0203486:	000afb17          	auipc	s6,0xaf
ffffffffc020348a:	53ab0b13          	addi	s6,s6,1338 # ffffffffc02b29c0 <check_mm_struct>
ffffffffc020348e:	a01d                	j	ffffffffc02034b4 <alloc_pages+0x58>
            page = pmm_manager->alloc_pages(n);
ffffffffc0203490:	00093783          	ld	a5,0(s2)
ffffffffc0203494:	6f9c                	ld	a5,24(a5)
ffffffffc0203496:	9782                	jalr	a5
ffffffffc0203498:	842a                	mv	s0,a0
        swap_out(check_mm_struct, n, 0);
ffffffffc020349a:	4601                	li	a2,0
ffffffffc020349c:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc020349e:	ec0d                	bnez	s0,ffffffffc02034d8 <alloc_pages+0x7c>
ffffffffc02034a0:	029a6c63          	bltu	s4,s1,ffffffffc02034d8 <alloc_pages+0x7c>
ffffffffc02034a4:	000aa783          	lw	a5,0(s5)
ffffffffc02034a8:	2781                	sext.w	a5,a5
ffffffffc02034aa:	c79d                	beqz	a5,ffffffffc02034d8 <alloc_pages+0x7c>
        swap_out(check_mm_struct, n, 0);
ffffffffc02034ac:	000b3503          	ld	a0,0(s6)
ffffffffc02034b0:	b38ff0ef          	jal	ra,ffffffffc02027e8 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02034b4:	100027f3          	csrr	a5,sstatus
ffffffffc02034b8:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc02034ba:	8526                	mv	a0,s1
ffffffffc02034bc:	dbf1                	beqz	a5,ffffffffc0203490 <alloc_pages+0x34>
        intr_disable();
ffffffffc02034be:	98afd0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc02034c2:	00093783          	ld	a5,0(s2)
ffffffffc02034c6:	8526                	mv	a0,s1
ffffffffc02034c8:	6f9c                	ld	a5,24(a5)
ffffffffc02034ca:	9782                	jalr	a5
ffffffffc02034cc:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02034ce:	974fd0ef          	jal	ra,ffffffffc0200642 <intr_enable>
        swap_out(check_mm_struct, n, 0);
ffffffffc02034d2:	4601                	li	a2,0
ffffffffc02034d4:	85ce                	mv	a1,s3
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc02034d6:	d469                	beqz	s0,ffffffffc02034a0 <alloc_pages+0x44>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc02034d8:	70e2                	ld	ra,56(sp)
ffffffffc02034da:	8522                	mv	a0,s0
ffffffffc02034dc:	7442                	ld	s0,48(sp)
ffffffffc02034de:	74a2                	ld	s1,40(sp)
ffffffffc02034e0:	7902                	ld	s2,32(sp)
ffffffffc02034e2:	69e2                	ld	s3,24(sp)
ffffffffc02034e4:	6a42                	ld	s4,16(sp)
ffffffffc02034e6:	6aa2                	ld	s5,8(sp)
ffffffffc02034e8:	6b02                	ld	s6,0(sp)
ffffffffc02034ea:	6121                	addi	sp,sp,64
ffffffffc02034ec:	8082                	ret

ffffffffc02034ee <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02034ee:	100027f3          	csrr	a5,sstatus
ffffffffc02034f2:	8b89                	andi	a5,a5,2
ffffffffc02034f4:	e799                	bnez	a5,ffffffffc0203502 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02034f6:	000af797          	auipc	a5,0xaf
ffffffffc02034fa:	51a7b783          	ld	a5,1306(a5) # ffffffffc02b2a10 <pmm_manager>
ffffffffc02034fe:	739c                	ld	a5,32(a5)
ffffffffc0203500:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0203502:	1101                	addi	sp,sp,-32
ffffffffc0203504:	ec06                	sd	ra,24(sp)
ffffffffc0203506:	e822                	sd	s0,16(sp)
ffffffffc0203508:	e426                	sd	s1,8(sp)
ffffffffc020350a:	842a                	mv	s0,a0
ffffffffc020350c:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc020350e:	93afd0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203512:	000af797          	auipc	a5,0xaf
ffffffffc0203516:	4fe7b783          	ld	a5,1278(a5) # ffffffffc02b2a10 <pmm_manager>
ffffffffc020351a:	739c                	ld	a5,32(a5)
ffffffffc020351c:	85a6                	mv	a1,s1
ffffffffc020351e:	8522                	mv	a0,s0
ffffffffc0203520:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0203522:	6442                	ld	s0,16(sp)
ffffffffc0203524:	60e2                	ld	ra,24(sp)
ffffffffc0203526:	64a2                	ld	s1,8(sp)
ffffffffc0203528:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020352a:	918fd06f          	j	ffffffffc0200642 <intr_enable>

ffffffffc020352e <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020352e:	100027f3          	csrr	a5,sstatus
ffffffffc0203532:	8b89                	andi	a5,a5,2
ffffffffc0203534:	e799                	bnez	a5,ffffffffc0203542 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0203536:	000af797          	auipc	a5,0xaf
ffffffffc020353a:	4da7b783          	ld	a5,1242(a5) # ffffffffc02b2a10 <pmm_manager>
ffffffffc020353e:	779c                	ld	a5,40(a5)
ffffffffc0203540:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0203542:	1141                	addi	sp,sp,-16
ffffffffc0203544:	e406                	sd	ra,8(sp)
ffffffffc0203546:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0203548:	900fd0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020354c:	000af797          	auipc	a5,0xaf
ffffffffc0203550:	4c47b783          	ld	a5,1220(a5) # ffffffffc02b2a10 <pmm_manager>
ffffffffc0203554:	779c                	ld	a5,40(a5)
ffffffffc0203556:	9782                	jalr	a5
ffffffffc0203558:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020355a:	8e8fd0ef          	jal	ra,ffffffffc0200642 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc020355e:	60a2                	ld	ra,8(sp)
ffffffffc0203560:	8522                	mv	a0,s0
ffffffffc0203562:	6402                	ld	s0,0(sp)
ffffffffc0203564:	0141                	addi	sp,sp,16
ffffffffc0203566:	8082                	ret

ffffffffc0203568 <get_pte>:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0203568:	01e5d793          	srli	a5,a1,0x1e
ffffffffc020356c:	1ff7f793          	andi	a5,a5,511
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0203570:	7139                	addi	sp,sp,-64
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0203572:	078e                	slli	a5,a5,0x3
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0203574:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0203576:	00f504b3          	add	s1,a0,a5
    if (!(*pdep1 & PTE_V)) {
ffffffffc020357a:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc020357c:	f04a                	sd	s2,32(sp)
ffffffffc020357e:	ec4e                	sd	s3,24(sp)
ffffffffc0203580:	e852                	sd	s4,16(sp)
ffffffffc0203582:	fc06                	sd	ra,56(sp)
ffffffffc0203584:	f822                	sd	s0,48(sp)
ffffffffc0203586:	e456                	sd	s5,8(sp)
ffffffffc0203588:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc020358a:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc020358e:	892e                	mv	s2,a1
ffffffffc0203590:	89b2                	mv	s3,a2
ffffffffc0203592:	000afa17          	auipc	s4,0xaf
ffffffffc0203596:	46ea0a13          	addi	s4,s4,1134 # ffffffffc02b2a00 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc020359a:	e7b5                	bnez	a5,ffffffffc0203606 <get_pte+0x9e>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc020359c:	12060b63          	beqz	a2,ffffffffc02036d2 <get_pte+0x16a>
ffffffffc02035a0:	4505                	li	a0,1
ffffffffc02035a2:	ebbff0ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc02035a6:	842a                	mv	s0,a0
ffffffffc02035a8:	12050563          	beqz	a0,ffffffffc02036d2 <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc02035ac:	000afb17          	auipc	s6,0xaf
ffffffffc02035b0:	45cb0b13          	addi	s6,s6,1116 # ffffffffc02b2a08 <pages>
ffffffffc02035b4:	000b3503          	ld	a0,0(s6)
ffffffffc02035b8:	00080ab7          	lui	s5,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02035bc:	000afa17          	auipc	s4,0xaf
ffffffffc02035c0:	444a0a13          	addi	s4,s4,1092 # ffffffffc02b2a00 <npage>
ffffffffc02035c4:	40a40533          	sub	a0,s0,a0
ffffffffc02035c8:	8519                	srai	a0,a0,0x6
ffffffffc02035ca:	9556                	add	a0,a0,s5
ffffffffc02035cc:	000a3703          	ld	a4,0(s4)
ffffffffc02035d0:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc02035d4:	4685                	li	a3,1
ffffffffc02035d6:	c014                	sw	a3,0(s0)
ffffffffc02035d8:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc02035da:	0532                	slli	a0,a0,0xc
ffffffffc02035dc:	14e7f263          	bgeu	a5,a4,ffffffffc0203720 <get_pte+0x1b8>
ffffffffc02035e0:	000af797          	auipc	a5,0xaf
ffffffffc02035e4:	4387b783          	ld	a5,1080(a5) # ffffffffc02b2a18 <va_pa_offset>
ffffffffc02035e8:	6605                	lui	a2,0x1
ffffffffc02035ea:	4581                	li	a1,0
ffffffffc02035ec:	953e                	add	a0,a0,a5
ffffffffc02035ee:	3cd020ef          	jal	ra,ffffffffc02061ba <memset>
    return page - pages + nbase;
ffffffffc02035f2:	000b3683          	ld	a3,0(s6)
ffffffffc02035f6:	40d406b3          	sub	a3,s0,a3
ffffffffc02035fa:	8699                	srai	a3,a3,0x6
ffffffffc02035fc:	96d6                	add	a3,a3,s5
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02035fe:	06aa                	slli	a3,a3,0xa
ffffffffc0203600:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0203604:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0203606:	77fd                	lui	a5,0xfffff
ffffffffc0203608:	068a                	slli	a3,a3,0x2
ffffffffc020360a:	000a3703          	ld	a4,0(s4)
ffffffffc020360e:	8efd                	and	a3,a3,a5
ffffffffc0203610:	00c6d793          	srli	a5,a3,0xc
ffffffffc0203614:	0ce7f163          	bgeu	a5,a4,ffffffffc02036d6 <get_pte+0x16e>
ffffffffc0203618:	000afa97          	auipc	s5,0xaf
ffffffffc020361c:	400a8a93          	addi	s5,s5,1024 # ffffffffc02b2a18 <va_pa_offset>
ffffffffc0203620:	000ab403          	ld	s0,0(s5)
ffffffffc0203624:	01595793          	srli	a5,s2,0x15
ffffffffc0203628:	1ff7f793          	andi	a5,a5,511
ffffffffc020362c:	96a2                	add	a3,a3,s0
ffffffffc020362e:	00379413          	slli	s0,a5,0x3
ffffffffc0203632:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) {
ffffffffc0203634:	6014                	ld	a3,0(s0)
ffffffffc0203636:	0016f793          	andi	a5,a3,1
ffffffffc020363a:	e3ad                	bnez	a5,ffffffffc020369c <get_pte+0x134>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc020363c:	08098b63          	beqz	s3,ffffffffc02036d2 <get_pte+0x16a>
ffffffffc0203640:	4505                	li	a0,1
ffffffffc0203642:	e1bff0ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0203646:	84aa                	mv	s1,a0
ffffffffc0203648:	c549                	beqz	a0,ffffffffc02036d2 <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc020364a:	000afb17          	auipc	s6,0xaf
ffffffffc020364e:	3beb0b13          	addi	s6,s6,958 # ffffffffc02b2a08 <pages>
ffffffffc0203652:	000b3503          	ld	a0,0(s6)
ffffffffc0203656:	000809b7          	lui	s3,0x80
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020365a:	000a3703          	ld	a4,0(s4)
ffffffffc020365e:	40a48533          	sub	a0,s1,a0
ffffffffc0203662:	8519                	srai	a0,a0,0x6
ffffffffc0203664:	954e                	add	a0,a0,s3
ffffffffc0203666:	00c51793          	slli	a5,a0,0xc
    page->ref = val;
ffffffffc020366a:	4685                	li	a3,1
ffffffffc020366c:	c094                	sw	a3,0(s1)
ffffffffc020366e:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0203670:	0532                	slli	a0,a0,0xc
ffffffffc0203672:	08e7fa63          	bgeu	a5,a4,ffffffffc0203706 <get_pte+0x19e>
ffffffffc0203676:	000ab783          	ld	a5,0(s5)
ffffffffc020367a:	6605                	lui	a2,0x1
ffffffffc020367c:	4581                	li	a1,0
ffffffffc020367e:	953e                	add	a0,a0,a5
ffffffffc0203680:	33b020ef          	jal	ra,ffffffffc02061ba <memset>
    return page - pages + nbase;
ffffffffc0203684:	000b3683          	ld	a3,0(s6)
ffffffffc0203688:	40d486b3          	sub	a3,s1,a3
ffffffffc020368c:	8699                	srai	a3,a3,0x6
ffffffffc020368e:	96ce                	add	a3,a3,s3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0203690:	06aa                	slli	a3,a3,0xa
ffffffffc0203692:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0203696:	e014                	sd	a3,0(s0)
        }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0203698:	000a3703          	ld	a4,0(s4)
ffffffffc020369c:	068a                	slli	a3,a3,0x2
ffffffffc020369e:	757d                	lui	a0,0xfffff
ffffffffc02036a0:	8ee9                	and	a3,a3,a0
ffffffffc02036a2:	00c6d793          	srli	a5,a3,0xc
ffffffffc02036a6:	04e7f463          	bgeu	a5,a4,ffffffffc02036ee <get_pte+0x186>
ffffffffc02036aa:	000ab503          	ld	a0,0(s5)
ffffffffc02036ae:	00c95913          	srli	s2,s2,0xc
ffffffffc02036b2:	1ff97913          	andi	s2,s2,511
ffffffffc02036b6:	96aa                	add	a3,a3,a0
ffffffffc02036b8:	00391513          	slli	a0,s2,0x3
ffffffffc02036bc:	9536                	add	a0,a0,a3
}
ffffffffc02036be:	70e2                	ld	ra,56(sp)
ffffffffc02036c0:	7442                	ld	s0,48(sp)
ffffffffc02036c2:	74a2                	ld	s1,40(sp)
ffffffffc02036c4:	7902                	ld	s2,32(sp)
ffffffffc02036c6:	69e2                	ld	s3,24(sp)
ffffffffc02036c8:	6a42                	ld	s4,16(sp)
ffffffffc02036ca:	6aa2                	ld	s5,8(sp)
ffffffffc02036cc:	6b02                	ld	s6,0(sp)
ffffffffc02036ce:	6121                	addi	sp,sp,64
ffffffffc02036d0:	8082                	ret
            return NULL;
ffffffffc02036d2:	4501                	li	a0,0
ffffffffc02036d4:	b7ed                	j	ffffffffc02036be <get_pte+0x156>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02036d6:	00004617          	auipc	a2,0x4
ffffffffc02036da:	d7a60613          	addi	a2,a2,-646 # ffffffffc0207450 <commands+0xbc0>
ffffffffc02036de:	0fd00593          	li	a1,253
ffffffffc02036e2:	00004517          	auipc	a0,0x4
ffffffffc02036e6:	69e50513          	addi	a0,a0,1694 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc02036ea:	b1ffc0ef          	jal	ra,ffffffffc0200208 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02036ee:	00004617          	auipc	a2,0x4
ffffffffc02036f2:	d6260613          	addi	a2,a2,-670 # ffffffffc0207450 <commands+0xbc0>
ffffffffc02036f6:	10800593          	li	a1,264
ffffffffc02036fa:	00004517          	auipc	a0,0x4
ffffffffc02036fe:	68650513          	addi	a0,a0,1670 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0203702:	b07fc0ef          	jal	ra,ffffffffc0200208 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0203706:	86aa                	mv	a3,a0
ffffffffc0203708:	00004617          	auipc	a2,0x4
ffffffffc020370c:	d4860613          	addi	a2,a2,-696 # ffffffffc0207450 <commands+0xbc0>
ffffffffc0203710:	10500593          	li	a1,261
ffffffffc0203714:	00004517          	auipc	a0,0x4
ffffffffc0203718:	66c50513          	addi	a0,a0,1644 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc020371c:	aedfc0ef          	jal	ra,ffffffffc0200208 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0203720:	86aa                	mv	a3,a0
ffffffffc0203722:	00004617          	auipc	a2,0x4
ffffffffc0203726:	d2e60613          	addi	a2,a2,-722 # ffffffffc0207450 <commands+0xbc0>
ffffffffc020372a:	0f900593          	li	a1,249
ffffffffc020372e:	00004517          	auipc	a0,0x4
ffffffffc0203732:	65250513          	addi	a0,a0,1618 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0203736:	ad3fc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc020373a <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc020373a:	1141                	addi	sp,sp,-16
ffffffffc020373c:	e022                	sd	s0,0(sp)
ffffffffc020373e:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0203740:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0203742:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0203744:	e25ff0ef          	jal	ra,ffffffffc0203568 <get_pte>
    if (ptep_store != NULL) {
ffffffffc0203748:	c011                	beqz	s0,ffffffffc020374c <get_page+0x12>
        *ptep_store = ptep;
ffffffffc020374a:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc020374c:	c511                	beqz	a0,ffffffffc0203758 <get_page+0x1e>
ffffffffc020374e:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0203750:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0203752:	0017f713          	andi	a4,a5,1
ffffffffc0203756:	e709                	bnez	a4,ffffffffc0203760 <get_page+0x26>
}
ffffffffc0203758:	60a2                	ld	ra,8(sp)
ffffffffc020375a:	6402                	ld	s0,0(sp)
ffffffffc020375c:	0141                	addi	sp,sp,16
ffffffffc020375e:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0203760:	078a                	slli	a5,a5,0x2
ffffffffc0203762:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203764:	000af717          	auipc	a4,0xaf
ffffffffc0203768:	29c73703          	ld	a4,668(a4) # ffffffffc02b2a00 <npage>
ffffffffc020376c:	00e7ff63          	bgeu	a5,a4,ffffffffc020378a <get_page+0x50>
ffffffffc0203770:	60a2                	ld	ra,8(sp)
ffffffffc0203772:	6402                	ld	s0,0(sp)
    return &pages[PPN(pa) - nbase];
ffffffffc0203774:	fff80537          	lui	a0,0xfff80
ffffffffc0203778:	97aa                	add	a5,a5,a0
ffffffffc020377a:	079a                	slli	a5,a5,0x6
ffffffffc020377c:	000af517          	auipc	a0,0xaf
ffffffffc0203780:	28c53503          	ld	a0,652(a0) # ffffffffc02b2a08 <pages>
ffffffffc0203784:	953e                	add	a0,a0,a5
ffffffffc0203786:	0141                	addi	sp,sp,16
ffffffffc0203788:	8082                	ret
ffffffffc020378a:	c9bff0ef          	jal	ra,ffffffffc0203424 <pa2page.part.0>

ffffffffc020378e <unmap_range>:
 * 参数：
 *   pgdir  - 页目录指针
 *   start  - 起始虚拟地址
 *   end    - 结束虚拟地址
 */
void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc020378e:	7159                	addi	sp,sp,-112
    // 检查起始地址和结束地址是否对齐到页面边界
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203790:	00c5e7b3          	or	a5,a1,a2
void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0203794:	f486                	sd	ra,104(sp)
ffffffffc0203796:	f0a2                	sd	s0,96(sp)
ffffffffc0203798:	eca6                	sd	s1,88(sp)
ffffffffc020379a:	e8ca                	sd	s2,80(sp)
ffffffffc020379c:	e4ce                	sd	s3,72(sp)
ffffffffc020379e:	e0d2                	sd	s4,64(sp)
ffffffffc02037a0:	fc56                	sd	s5,56(sp)
ffffffffc02037a2:	f85a                	sd	s6,48(sp)
ffffffffc02037a4:	f45e                	sd	s7,40(sp)
ffffffffc02037a6:	f062                	sd	s8,32(sp)
ffffffffc02037a8:	ec66                	sd	s9,24(sp)
ffffffffc02037aa:	e86a                	sd	s10,16(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02037ac:	17d2                	slli	a5,a5,0x34
ffffffffc02037ae:	e3ed                	bnez	a5,ffffffffc0203890 <unmap_range+0x102>
    
    // 检查地址范围是否在用户空间内
    assert(USER_ACCESS(start, end));
ffffffffc02037b0:	002007b7          	lui	a5,0x200
ffffffffc02037b4:	842e                	mv	s0,a1
ffffffffc02037b6:	0ef5ed63          	bltu	a1,a5,ffffffffc02038b0 <unmap_range+0x122>
ffffffffc02037ba:	8932                	mv	s2,a2
ffffffffc02037bc:	0ec5fa63          	bgeu	a1,a2,ffffffffc02038b0 <unmap_range+0x122>
ffffffffc02037c0:	4785                	li	a5,1
ffffffffc02037c2:	07fe                	slli	a5,a5,0x1f
ffffffffc02037c4:	0ec7e663          	bltu	a5,a2,ffffffffc02038b0 <unmap_range+0x122>
ffffffffc02037c8:	89aa                	mv	s3,a0
        if (*ptep != 0) {
            page_remove_pte(pgdir, start, ptep);
        }

        // 继续处理下一个页面
        start += PGSIZE;
ffffffffc02037ca:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc02037cc:	000afc97          	auipc	s9,0xaf
ffffffffc02037d0:	234c8c93          	addi	s9,s9,564 # ffffffffc02b2a00 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02037d4:	000afc17          	auipc	s8,0xaf
ffffffffc02037d8:	234c0c13          	addi	s8,s8,564 # ffffffffc02b2a08 <pages>
ffffffffc02037dc:	fff80bb7          	lui	s7,0xfff80
        pmm_manager->free_pages(base, n);
ffffffffc02037e0:	000afd17          	auipc	s10,0xaf
ffffffffc02037e4:	230d0d13          	addi	s10,s10,560 # ffffffffc02b2a10 <pmm_manager>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02037e8:	00200b37          	lui	s6,0x200
ffffffffc02037ec:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02037f0:	4601                	li	a2,0
ffffffffc02037f2:	85a2                	mv	a1,s0
ffffffffc02037f4:	854e                	mv	a0,s3
ffffffffc02037f6:	d73ff0ef          	jal	ra,ffffffffc0203568 <get_pte>
ffffffffc02037fa:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc02037fc:	cd29                	beqz	a0,ffffffffc0203856 <unmap_range+0xc8>
        if (*ptep != 0) {
ffffffffc02037fe:	611c                	ld	a5,0(a0)
ffffffffc0203800:	e395                	bnez	a5,ffffffffc0203824 <unmap_range+0x96>
        start += PGSIZE;
ffffffffc0203802:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);  // 直到遍历完整个地址范围
ffffffffc0203804:	ff2466e3          	bltu	s0,s2,ffffffffc02037f0 <unmap_range+0x62>
}
ffffffffc0203808:	70a6                	ld	ra,104(sp)
ffffffffc020380a:	7406                	ld	s0,96(sp)
ffffffffc020380c:	64e6                	ld	s1,88(sp)
ffffffffc020380e:	6946                	ld	s2,80(sp)
ffffffffc0203810:	69a6                	ld	s3,72(sp)
ffffffffc0203812:	6a06                	ld	s4,64(sp)
ffffffffc0203814:	7ae2                	ld	s5,56(sp)
ffffffffc0203816:	7b42                	ld	s6,48(sp)
ffffffffc0203818:	7ba2                	ld	s7,40(sp)
ffffffffc020381a:	7c02                	ld	s8,32(sp)
ffffffffc020381c:	6ce2                	ld	s9,24(sp)
ffffffffc020381e:	6d42                	ld	s10,16(sp)
ffffffffc0203820:	6165                	addi	sp,sp,112
ffffffffc0203822:	8082                	ret
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0203824:	0017f713          	andi	a4,a5,1
ffffffffc0203828:	df69                	beqz	a4,ffffffffc0203802 <unmap_range+0x74>
    if (PPN(pa) >= npage) {
ffffffffc020382a:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020382e:	078a                	slli	a5,a5,0x2
ffffffffc0203830:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203832:	08e7ff63          	bgeu	a5,a4,ffffffffc02038d0 <unmap_range+0x142>
    return &pages[PPN(pa) - nbase];
ffffffffc0203836:	000c3503          	ld	a0,0(s8)
ffffffffc020383a:	97de                	add	a5,a5,s7
ffffffffc020383c:	079a                	slli	a5,a5,0x6
ffffffffc020383e:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0203840:	411c                	lw	a5,0(a0)
ffffffffc0203842:	fff7871b          	addiw	a4,a5,-1
ffffffffc0203846:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0203848:	cf11                	beqz	a4,ffffffffc0203864 <unmap_range+0xd6>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc020384a:	0004b023          	sd	zero,0(s1)
}

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020384e:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc0203852:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);  // 直到遍历完整个地址范围
ffffffffc0203854:	bf45                	j	ffffffffc0203804 <unmap_range+0x76>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203856:	945a                	add	s0,s0,s6
ffffffffc0203858:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);  // 直到遍历完整个地址范围
ffffffffc020385c:	d455                	beqz	s0,ffffffffc0203808 <unmap_range+0x7a>
ffffffffc020385e:	f92469e3          	bltu	s0,s2,ffffffffc02037f0 <unmap_range+0x62>
ffffffffc0203862:	b75d                	j	ffffffffc0203808 <unmap_range+0x7a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203864:	100027f3          	csrr	a5,sstatus
ffffffffc0203868:	8b89                	andi	a5,a5,2
ffffffffc020386a:	e799                	bnez	a5,ffffffffc0203878 <unmap_range+0xea>
        pmm_manager->free_pages(base, n);
ffffffffc020386c:	000d3783          	ld	a5,0(s10)
ffffffffc0203870:	4585                	li	a1,1
ffffffffc0203872:	739c                	ld	a5,32(a5)
ffffffffc0203874:	9782                	jalr	a5
    if (flag) {
ffffffffc0203876:	bfd1                	j	ffffffffc020384a <unmap_range+0xbc>
ffffffffc0203878:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020387a:	dcffc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc020387e:	000d3783          	ld	a5,0(s10)
ffffffffc0203882:	6522                	ld	a0,8(sp)
ffffffffc0203884:	4585                	li	a1,1
ffffffffc0203886:	739c                	ld	a5,32(a5)
ffffffffc0203888:	9782                	jalr	a5
        intr_enable();
ffffffffc020388a:	db9fc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc020388e:	bf75                	j	ffffffffc020384a <unmap_range+0xbc>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203890:	00004697          	auipc	a3,0x4
ffffffffc0203894:	50068693          	addi	a3,a3,1280 # ffffffffc0207d90 <default_pmm_manager+0x48>
ffffffffc0203898:	00003617          	auipc	a2,0x3
ffffffffc020389c:	40860613          	addi	a2,a2,1032 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02038a0:	13300593          	li	a1,307
ffffffffc02038a4:	00004517          	auipc	a0,0x4
ffffffffc02038a8:	4dc50513          	addi	a0,a0,1244 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc02038ac:	95dfc0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02038b0:	00004697          	auipc	a3,0x4
ffffffffc02038b4:	51068693          	addi	a3,a3,1296 # ffffffffc0207dc0 <default_pmm_manager+0x78>
ffffffffc02038b8:	00003617          	auipc	a2,0x3
ffffffffc02038bc:	3e860613          	addi	a2,a2,1000 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02038c0:	13600593          	li	a1,310
ffffffffc02038c4:	00004517          	auipc	a0,0x4
ffffffffc02038c8:	4bc50513          	addi	a0,a0,1212 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc02038cc:	93dfc0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc02038d0:	b55ff0ef          	jal	ra,ffffffffc0203424 <pa2page.part.0>

ffffffffc02038d4 <exit_range>:
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc02038d4:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02038d6:	00c5e7b3          	or	a5,a1,a2
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc02038da:	fc86                	sd	ra,120(sp)
ffffffffc02038dc:	f8a2                	sd	s0,112(sp)
ffffffffc02038de:	f4a6                	sd	s1,104(sp)
ffffffffc02038e0:	f0ca                	sd	s2,96(sp)
ffffffffc02038e2:	ecce                	sd	s3,88(sp)
ffffffffc02038e4:	e8d2                	sd	s4,80(sp)
ffffffffc02038e6:	e4d6                	sd	s5,72(sp)
ffffffffc02038e8:	e0da                	sd	s6,64(sp)
ffffffffc02038ea:	fc5e                	sd	s7,56(sp)
ffffffffc02038ec:	f862                	sd	s8,48(sp)
ffffffffc02038ee:	f466                	sd	s9,40(sp)
ffffffffc02038f0:	f06a                	sd	s10,32(sp)
ffffffffc02038f2:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02038f4:	17d2                	slli	a5,a5,0x34
ffffffffc02038f6:	20079a63          	bnez	a5,ffffffffc0203b0a <exit_range+0x236>
    assert(USER_ACCESS(start, end));
ffffffffc02038fa:	002007b7          	lui	a5,0x200
ffffffffc02038fe:	24f5e463          	bltu	a1,a5,ffffffffc0203b46 <exit_range+0x272>
ffffffffc0203902:	8ab2                	mv	s5,a2
ffffffffc0203904:	24c5f163          	bgeu	a1,a2,ffffffffc0203b46 <exit_range+0x272>
ffffffffc0203908:	4785                	li	a5,1
ffffffffc020390a:	07fe                	slli	a5,a5,0x1f
ffffffffc020390c:	22c7ed63          	bltu	a5,a2,ffffffffc0203b46 <exit_range+0x272>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0203910:	c00009b7          	lui	s3,0xc0000
ffffffffc0203914:	0135f9b3          	and	s3,a1,s3
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0203918:	ffe00937          	lui	s2,0xffe00
ffffffffc020391c:	400007b7          	lui	a5,0x40000
    return KADDR(page2pa(page));
ffffffffc0203920:	5cfd                	li	s9,-1
ffffffffc0203922:	8c2a                	mv	s8,a0
ffffffffc0203924:	0125f933          	and	s2,a1,s2
ffffffffc0203928:	99be                	add	s3,s3,a5
    if (PPN(pa) >= npage) {
ffffffffc020392a:	000afd17          	auipc	s10,0xaf
ffffffffc020392e:	0d6d0d13          	addi	s10,s10,214 # ffffffffc02b2a00 <npage>
    return KADDR(page2pa(page));
ffffffffc0203932:	00ccdc93          	srli	s9,s9,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc0203936:	000af717          	auipc	a4,0xaf
ffffffffc020393a:	0d270713          	addi	a4,a4,210 # ffffffffc02b2a08 <pages>
        pmm_manager->free_pages(base, n);
ffffffffc020393e:	000afd97          	auipc	s11,0xaf
ffffffffc0203942:	0d2d8d93          	addi	s11,s11,210 # ffffffffc02b2a10 <pmm_manager>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0203946:	c0000437          	lui	s0,0xc0000
ffffffffc020394a:	944e                	add	s0,s0,s3
ffffffffc020394c:	8079                	srli	s0,s0,0x1e
ffffffffc020394e:	1ff47413          	andi	s0,s0,511
ffffffffc0203952:	040e                	slli	s0,s0,0x3
ffffffffc0203954:	9462                	add	s0,s0,s8
ffffffffc0203956:	00043a03          	ld	s4,0(s0) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ec0>
        if (pde1 & PTE_V) {
ffffffffc020395a:	001a7793          	andi	a5,s4,1
ffffffffc020395e:	eb99                	bnez	a5,ffffffffc0203974 <exit_range+0xa0>
    } while (d1start != 0 && d1start < end);  // 遍历整个地址范围
ffffffffc0203960:	12098463          	beqz	s3,ffffffffc0203a88 <exit_range+0x1b4>
ffffffffc0203964:	400007b7          	lui	a5,0x40000
ffffffffc0203968:	97ce                	add	a5,a5,s3
ffffffffc020396a:	894e                	mv	s2,s3
ffffffffc020396c:	1159fe63          	bgeu	s3,s5,ffffffffc0203a88 <exit_range+0x1b4>
ffffffffc0203970:	89be                	mv	s3,a5
ffffffffc0203972:	bfd1                	j	ffffffffc0203946 <exit_range+0x72>
    if (PPN(pa) >= npage) {
ffffffffc0203974:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203978:	0a0a                	slli	s4,s4,0x2
ffffffffc020397a:	00ca5a13          	srli	s4,s4,0xc
    if (PPN(pa) >= npage) {
ffffffffc020397e:	1cfa7263          	bgeu	s4,a5,ffffffffc0203b42 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203982:	fff80637          	lui	a2,0xfff80
ffffffffc0203986:	9652                	add	a2,a2,s4
    return page - pages + nbase;
ffffffffc0203988:	000806b7          	lui	a3,0x80
ffffffffc020398c:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc020398e:	0196f5b3          	and	a1,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc0203992:	061a                	slli	a2,a2,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc0203994:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0203996:	18f5fa63          	bgeu	a1,a5,ffffffffc0203b2a <exit_range+0x256>
ffffffffc020399a:	000af817          	auipc	a6,0xaf
ffffffffc020399e:	07e80813          	addi	a6,a6,126 # ffffffffc02b2a18 <va_pa_offset>
ffffffffc02039a2:	00083b03          	ld	s6,0(a6)
            free_pd0 = 1;
ffffffffc02039a6:	4b85                	li	s7,1
    return &pages[PPN(pa) - nbase];
ffffffffc02039a8:	fff80e37          	lui	t3,0xfff80
    return KADDR(page2pa(page));
ffffffffc02039ac:	9b36                	add	s6,s6,a3
    return page - pages + nbase;
ffffffffc02039ae:	00080337          	lui	t1,0x80
ffffffffc02039b2:	6885                	lui	a7,0x1
ffffffffc02039b4:	a819                	j	ffffffffc02039ca <exit_range+0xf6>
                    free_pd0 = 0;  // 如果该页目录项无效，表示不需要释放该页目录
ffffffffc02039b6:	4b81                	li	s7,0
                d0start += PTSIZE;
ffffffffc02039b8:	002007b7          	lui	a5,0x200
ffffffffc02039bc:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02039be:	08090c63          	beqz	s2,ffffffffc0203a56 <exit_range+0x182>
ffffffffc02039c2:	09397a63          	bgeu	s2,s3,ffffffffc0203a56 <exit_range+0x182>
ffffffffc02039c6:	0f597063          	bgeu	s2,s5,ffffffffc0203aa6 <exit_range+0x1d2>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02039ca:	01595493          	srli	s1,s2,0x15
ffffffffc02039ce:	1ff4f493          	andi	s1,s1,511
ffffffffc02039d2:	048e                	slli	s1,s1,0x3
ffffffffc02039d4:	94da                	add	s1,s1,s6
ffffffffc02039d6:	609c                	ld	a5,0(s1)
                if (pde0 & PTE_V) {
ffffffffc02039d8:	0017f693          	andi	a3,a5,1
ffffffffc02039dc:	dee9                	beqz	a3,ffffffffc02039b6 <exit_range+0xe2>
    if (PPN(pa) >= npage) {
ffffffffc02039de:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02039e2:	078a                	slli	a5,a5,0x2
ffffffffc02039e4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02039e6:	14b7fe63          	bgeu	a5,a1,ffffffffc0203b42 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc02039ea:	97f2                	add	a5,a5,t3
    return page - pages + nbase;
ffffffffc02039ec:	006786b3          	add	a3,a5,t1
    return KADDR(page2pa(page));
ffffffffc02039f0:	0196feb3          	and	t4,a3,s9
    return &pages[PPN(pa) - nbase];
ffffffffc02039f4:	00679513          	slli	a0,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02039f8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02039fa:	12bef863          	bgeu	t4,a1,ffffffffc0203b2a <exit_range+0x256>
ffffffffc02039fe:	00083783          	ld	a5,0(a6)
ffffffffc0203a02:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++) {
ffffffffc0203a04:	011685b3          	add	a1,a3,a7
                        if (pt[i] & PTE_V) {
ffffffffc0203a08:	629c                	ld	a5,0(a3)
ffffffffc0203a0a:	8b85                	andi	a5,a5,1
ffffffffc0203a0c:	f7d5                	bnez	a5,ffffffffc02039b8 <exit_range+0xe4>
                    for (int i = 0; i < NPTEENTRY; i++) {
ffffffffc0203a0e:	06a1                	addi	a3,a3,8
ffffffffc0203a10:	fed59ce3          	bne	a1,a3,ffffffffc0203a08 <exit_range+0x134>
    return &pages[PPN(pa) - nbase];
ffffffffc0203a14:	631c                	ld	a5,0(a4)
ffffffffc0203a16:	953e                	add	a0,a0,a5
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203a18:	100027f3          	csrr	a5,sstatus
ffffffffc0203a1c:	8b89                	andi	a5,a5,2
ffffffffc0203a1e:	e7d9                	bnez	a5,ffffffffc0203aac <exit_range+0x1d8>
        pmm_manager->free_pages(base, n);
ffffffffc0203a20:	000db783          	ld	a5,0(s11)
ffffffffc0203a24:	4585                	li	a1,1
ffffffffc0203a26:	e032                	sd	a2,0(sp)
ffffffffc0203a28:	739c                	ld	a5,32(a5)
ffffffffc0203a2a:	9782                	jalr	a5
    if (flag) {
ffffffffc0203a2c:	6602                	ld	a2,0(sp)
ffffffffc0203a2e:	000af817          	auipc	a6,0xaf
ffffffffc0203a32:	fea80813          	addi	a6,a6,-22 # ffffffffc02b2a18 <va_pa_offset>
ffffffffc0203a36:	fff80e37          	lui	t3,0xfff80
ffffffffc0203a3a:	00080337          	lui	t1,0x80
ffffffffc0203a3e:	6885                	lui	a7,0x1
ffffffffc0203a40:	000af717          	auipc	a4,0xaf
ffffffffc0203a44:	fc870713          	addi	a4,a4,-56 # ffffffffc02b2a08 <pages>
                        pd0[PDX0(d0start)] = 0;     // 清除该页目录项
ffffffffc0203a48:	0004b023          	sd	zero,0(s1)
                d0start += PTSIZE;
ffffffffc0203a4c:	002007b7          	lui	a5,0x200
ffffffffc0203a50:	993e                	add	s2,s2,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc0203a52:	f60918e3          	bnez	s2,ffffffffc02039c2 <exit_range+0xee>
            if (free_pd0) {
ffffffffc0203a56:	f00b85e3          	beqz	s7,ffffffffc0203960 <exit_range+0x8c>
    if (PPN(pa) >= npage) {
ffffffffc0203a5a:	000d3783          	ld	a5,0(s10)
ffffffffc0203a5e:	0efa7263          	bgeu	s4,a5,ffffffffc0203b42 <exit_range+0x26e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203a62:	6308                	ld	a0,0(a4)
ffffffffc0203a64:	9532                	add	a0,a0,a2
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203a66:	100027f3          	csrr	a5,sstatus
ffffffffc0203a6a:	8b89                	andi	a5,a5,2
ffffffffc0203a6c:	efad                	bnez	a5,ffffffffc0203ae6 <exit_range+0x212>
        pmm_manager->free_pages(base, n);
ffffffffc0203a6e:	000db783          	ld	a5,0(s11)
ffffffffc0203a72:	4585                	li	a1,1
ffffffffc0203a74:	739c                	ld	a5,32(a5)
ffffffffc0203a76:	9782                	jalr	a5
ffffffffc0203a78:	000af717          	auipc	a4,0xaf
ffffffffc0203a7c:	f9070713          	addi	a4,a4,-112 # ffffffffc02b2a08 <pages>
                pgdir[PDX1(d1start)] = 0;   // 清除一级页目录项
ffffffffc0203a80:	00043023          	sd	zero,0(s0)
    } while (d1start != 0 && d1start < end);  // 遍历整个地址范围
ffffffffc0203a84:	ee0990e3          	bnez	s3,ffffffffc0203964 <exit_range+0x90>
}
ffffffffc0203a88:	70e6                	ld	ra,120(sp)
ffffffffc0203a8a:	7446                	ld	s0,112(sp)
ffffffffc0203a8c:	74a6                	ld	s1,104(sp)
ffffffffc0203a8e:	7906                	ld	s2,96(sp)
ffffffffc0203a90:	69e6                	ld	s3,88(sp)
ffffffffc0203a92:	6a46                	ld	s4,80(sp)
ffffffffc0203a94:	6aa6                	ld	s5,72(sp)
ffffffffc0203a96:	6b06                	ld	s6,64(sp)
ffffffffc0203a98:	7be2                	ld	s7,56(sp)
ffffffffc0203a9a:	7c42                	ld	s8,48(sp)
ffffffffc0203a9c:	7ca2                	ld	s9,40(sp)
ffffffffc0203a9e:	7d02                	ld	s10,32(sp)
ffffffffc0203aa0:	6de2                	ld	s11,24(sp)
ffffffffc0203aa2:	6109                	addi	sp,sp,128
ffffffffc0203aa4:	8082                	ret
            if (free_pd0) {
ffffffffc0203aa6:	ea0b8fe3          	beqz	s7,ffffffffc0203964 <exit_range+0x90>
ffffffffc0203aaa:	bf45                	j	ffffffffc0203a5a <exit_range+0x186>
ffffffffc0203aac:	e032                	sd	a2,0(sp)
        intr_disable();
ffffffffc0203aae:	e42a                	sd	a0,8(sp)
ffffffffc0203ab0:	b99fc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203ab4:	000db783          	ld	a5,0(s11)
ffffffffc0203ab8:	6522                	ld	a0,8(sp)
ffffffffc0203aba:	4585                	li	a1,1
ffffffffc0203abc:	739c                	ld	a5,32(a5)
ffffffffc0203abe:	9782                	jalr	a5
        intr_enable();
ffffffffc0203ac0:	b83fc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0203ac4:	6602                	ld	a2,0(sp)
ffffffffc0203ac6:	000af717          	auipc	a4,0xaf
ffffffffc0203aca:	f4270713          	addi	a4,a4,-190 # ffffffffc02b2a08 <pages>
ffffffffc0203ace:	6885                	lui	a7,0x1
ffffffffc0203ad0:	00080337          	lui	t1,0x80
ffffffffc0203ad4:	fff80e37          	lui	t3,0xfff80
ffffffffc0203ad8:	000af817          	auipc	a6,0xaf
ffffffffc0203adc:	f4080813          	addi	a6,a6,-192 # ffffffffc02b2a18 <va_pa_offset>
                        pd0[PDX0(d0start)] = 0;     // 清除该页目录项
ffffffffc0203ae0:	0004b023          	sd	zero,0(s1)
ffffffffc0203ae4:	b7a5                	j	ffffffffc0203a4c <exit_range+0x178>
ffffffffc0203ae6:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0203ae8:	b61fc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203aec:	000db783          	ld	a5,0(s11)
ffffffffc0203af0:	6502                	ld	a0,0(sp)
ffffffffc0203af2:	4585                	li	a1,1
ffffffffc0203af4:	739c                	ld	a5,32(a5)
ffffffffc0203af6:	9782                	jalr	a5
        intr_enable();
ffffffffc0203af8:	b4bfc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0203afc:	000af717          	auipc	a4,0xaf
ffffffffc0203b00:	f0c70713          	addi	a4,a4,-244 # ffffffffc02b2a08 <pages>
                pgdir[PDX1(d1start)] = 0;   // 清除一级页目录项
ffffffffc0203b04:	00043023          	sd	zero,0(s0)
ffffffffc0203b08:	bfb5                	j	ffffffffc0203a84 <exit_range+0x1b0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203b0a:	00004697          	auipc	a3,0x4
ffffffffc0203b0e:	28668693          	addi	a3,a3,646 # ffffffffc0207d90 <default_pmm_manager+0x48>
ffffffffc0203b12:	00003617          	auipc	a2,0x3
ffffffffc0203b16:	18e60613          	addi	a2,a2,398 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0203b1a:	15600593          	li	a1,342
ffffffffc0203b1e:	00004517          	auipc	a0,0x4
ffffffffc0203b22:	26250513          	addi	a0,a0,610 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0203b26:	ee2fc0ef          	jal	ra,ffffffffc0200208 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203b2a:	00004617          	auipc	a2,0x4
ffffffffc0203b2e:	92660613          	addi	a2,a2,-1754 # ffffffffc0207450 <commands+0xbc0>
ffffffffc0203b32:	06a00593          	li	a1,106
ffffffffc0203b36:	00004517          	auipc	a0,0x4
ffffffffc0203b3a:	90a50513          	addi	a0,a0,-1782 # ffffffffc0207440 <commands+0xbb0>
ffffffffc0203b3e:	ecafc0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0203b42:	8e3ff0ef          	jal	ra,ffffffffc0203424 <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc0203b46:	00004697          	auipc	a3,0x4
ffffffffc0203b4a:	27a68693          	addi	a3,a3,634 # ffffffffc0207dc0 <default_pmm_manager+0x78>
ffffffffc0203b4e:	00003617          	auipc	a2,0x3
ffffffffc0203b52:	15260613          	addi	a2,a2,338 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0203b56:	15900593          	li	a1,345
ffffffffc0203b5a:	00004517          	auipc	a0,0x4
ffffffffc0203b5e:	22650513          	addi	a0,a0,550 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0203b62:	ea6fc0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0203b66 <page_remove>:
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0203b66:	7179                	addi	sp,sp,-48
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0203b68:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0203b6a:	ec26                	sd	s1,24(sp)
ffffffffc0203b6c:	f406                	sd	ra,40(sp)
ffffffffc0203b6e:	f022                	sd	s0,32(sp)
ffffffffc0203b70:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0203b72:	9f7ff0ef          	jal	ra,ffffffffc0203568 <get_pte>
    if (ptep != NULL) {
ffffffffc0203b76:	c511                	beqz	a0,ffffffffc0203b82 <page_remove+0x1c>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0203b78:	611c                	ld	a5,0(a0)
ffffffffc0203b7a:	842a                	mv	s0,a0
ffffffffc0203b7c:	0017f713          	andi	a4,a5,1
ffffffffc0203b80:	e711                	bnez	a4,ffffffffc0203b8c <page_remove+0x26>
}
ffffffffc0203b82:	70a2                	ld	ra,40(sp)
ffffffffc0203b84:	7402                	ld	s0,32(sp)
ffffffffc0203b86:	64e2                	ld	s1,24(sp)
ffffffffc0203b88:	6145                	addi	sp,sp,48
ffffffffc0203b8a:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0203b8c:	078a                	slli	a5,a5,0x2
ffffffffc0203b8e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203b90:	000af717          	auipc	a4,0xaf
ffffffffc0203b94:	e7073703          	ld	a4,-400(a4) # ffffffffc02b2a00 <npage>
ffffffffc0203b98:	06e7f363          	bgeu	a5,a4,ffffffffc0203bfe <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc0203b9c:	fff80537          	lui	a0,0xfff80
ffffffffc0203ba0:	97aa                	add	a5,a5,a0
ffffffffc0203ba2:	079a                	slli	a5,a5,0x6
ffffffffc0203ba4:	000af517          	auipc	a0,0xaf
ffffffffc0203ba8:	e6453503          	ld	a0,-412(a0) # ffffffffc02b2a08 <pages>
ffffffffc0203bac:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc0203bae:	411c                	lw	a5,0(a0)
ffffffffc0203bb0:	fff7871b          	addiw	a4,a5,-1
ffffffffc0203bb4:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0203bb6:	cb11                	beqz	a4,ffffffffc0203bca <page_remove+0x64>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0203bb8:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203bbc:	12048073          	sfence.vma	s1
}
ffffffffc0203bc0:	70a2                	ld	ra,40(sp)
ffffffffc0203bc2:	7402                	ld	s0,32(sp)
ffffffffc0203bc4:	64e2                	ld	s1,24(sp)
ffffffffc0203bc6:	6145                	addi	sp,sp,48
ffffffffc0203bc8:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203bca:	100027f3          	csrr	a5,sstatus
ffffffffc0203bce:	8b89                	andi	a5,a5,2
ffffffffc0203bd0:	eb89                	bnez	a5,ffffffffc0203be2 <page_remove+0x7c>
        pmm_manager->free_pages(base, n);
ffffffffc0203bd2:	000af797          	auipc	a5,0xaf
ffffffffc0203bd6:	e3e7b783          	ld	a5,-450(a5) # ffffffffc02b2a10 <pmm_manager>
ffffffffc0203bda:	739c                	ld	a5,32(a5)
ffffffffc0203bdc:	4585                	li	a1,1
ffffffffc0203bde:	9782                	jalr	a5
    if (flag) {
ffffffffc0203be0:	bfe1                	j	ffffffffc0203bb8 <page_remove+0x52>
        intr_disable();
ffffffffc0203be2:	e42a                	sd	a0,8(sp)
ffffffffc0203be4:	a65fc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc0203be8:	000af797          	auipc	a5,0xaf
ffffffffc0203bec:	e287b783          	ld	a5,-472(a5) # ffffffffc02b2a10 <pmm_manager>
ffffffffc0203bf0:	739c                	ld	a5,32(a5)
ffffffffc0203bf2:	6522                	ld	a0,8(sp)
ffffffffc0203bf4:	4585                	li	a1,1
ffffffffc0203bf6:	9782                	jalr	a5
        intr_enable();
ffffffffc0203bf8:	a4bfc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0203bfc:	bf75                	j	ffffffffc0203bb8 <page_remove+0x52>
ffffffffc0203bfe:	827ff0ef          	jal	ra,ffffffffc0203424 <pa2page.part.0>

ffffffffc0203c02 <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0203c02:	7139                	addi	sp,sp,-64
ffffffffc0203c04:	e852                	sd	s4,16(sp)
ffffffffc0203c06:	8a32                	mv	s4,a2
ffffffffc0203c08:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0203c0a:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0203c0c:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0203c0e:	85d2                	mv	a1,s4
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0203c10:	f426                	sd	s1,40(sp)
ffffffffc0203c12:	fc06                	sd	ra,56(sp)
ffffffffc0203c14:	f04a                	sd	s2,32(sp)
ffffffffc0203c16:	ec4e                	sd	s3,24(sp)
ffffffffc0203c18:	e456                	sd	s5,8(sp)
ffffffffc0203c1a:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0203c1c:	94dff0ef          	jal	ra,ffffffffc0203568 <get_pte>
    if (ptep == NULL) {
ffffffffc0203c20:	c961                	beqz	a0,ffffffffc0203cf0 <page_insert+0xee>
    page->ref += 1;
ffffffffc0203c22:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) {
ffffffffc0203c24:	611c                	ld	a5,0(a0)
ffffffffc0203c26:	89aa                	mv	s3,a0
ffffffffc0203c28:	0016871b          	addiw	a4,a3,1
ffffffffc0203c2c:	c018                	sw	a4,0(s0)
ffffffffc0203c2e:	0017f713          	andi	a4,a5,1
ffffffffc0203c32:	ef05                	bnez	a4,ffffffffc0203c6a <page_insert+0x68>
    return page - pages + nbase;
ffffffffc0203c34:	000af717          	auipc	a4,0xaf
ffffffffc0203c38:	dd473703          	ld	a4,-556(a4) # ffffffffc02b2a08 <pages>
ffffffffc0203c3c:	8c19                	sub	s0,s0,a4
ffffffffc0203c3e:	000807b7          	lui	a5,0x80
ffffffffc0203c42:	8419                	srai	s0,s0,0x6
ffffffffc0203c44:	943e                	add	s0,s0,a5
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0203c46:	042a                	slli	s0,s0,0xa
ffffffffc0203c48:	8cc1                	or	s1,s1,s0
ffffffffc0203c4a:	0014e493          	ori	s1,s1,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc0203c4e:	0099b023          	sd	s1,0(s3) # ffffffffc0000000 <_binary_obj___user_exit_out_size+0xffffffffbfff4ec0>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203c52:	120a0073          	sfence.vma	s4
    return 0;
ffffffffc0203c56:	4501                	li	a0,0
}
ffffffffc0203c58:	70e2                	ld	ra,56(sp)
ffffffffc0203c5a:	7442                	ld	s0,48(sp)
ffffffffc0203c5c:	74a2                	ld	s1,40(sp)
ffffffffc0203c5e:	7902                	ld	s2,32(sp)
ffffffffc0203c60:	69e2                	ld	s3,24(sp)
ffffffffc0203c62:	6a42                	ld	s4,16(sp)
ffffffffc0203c64:	6aa2                	ld	s5,8(sp)
ffffffffc0203c66:	6121                	addi	sp,sp,64
ffffffffc0203c68:	8082                	ret
    return pa2page(PTE_ADDR(pte));
ffffffffc0203c6a:	078a                	slli	a5,a5,0x2
ffffffffc0203c6c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203c6e:	000af717          	auipc	a4,0xaf
ffffffffc0203c72:	d9273703          	ld	a4,-622(a4) # ffffffffc02b2a00 <npage>
ffffffffc0203c76:	06e7ff63          	bgeu	a5,a4,ffffffffc0203cf4 <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc0203c7a:	000afa97          	auipc	s5,0xaf
ffffffffc0203c7e:	d8ea8a93          	addi	s5,s5,-626 # ffffffffc02b2a08 <pages>
ffffffffc0203c82:	000ab703          	ld	a4,0(s5)
ffffffffc0203c86:	fff80937          	lui	s2,0xfff80
ffffffffc0203c8a:	993e                	add	s2,s2,a5
ffffffffc0203c8c:	091a                	slli	s2,s2,0x6
ffffffffc0203c8e:	993a                	add	s2,s2,a4
        if (p == page) {
ffffffffc0203c90:	01240c63          	beq	s0,s2,ffffffffc0203ca8 <page_insert+0xa6>
    page->ref -= 1;
ffffffffc0203c94:	00092783          	lw	a5,0(s2) # fffffffffff80000 <end+0x3fccd5c4>
ffffffffc0203c98:	fff7869b          	addiw	a3,a5,-1
ffffffffc0203c9c:	00d92023          	sw	a3,0(s2)
        if (page_ref(page) ==
ffffffffc0203ca0:	c691                	beqz	a3,ffffffffc0203cac <page_insert+0xaa>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203ca2:	120a0073          	sfence.vma	s4
}
ffffffffc0203ca6:	bf59                	j	ffffffffc0203c3c <page_insert+0x3a>
ffffffffc0203ca8:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc0203caa:	bf49                	j	ffffffffc0203c3c <page_insert+0x3a>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203cac:	100027f3          	csrr	a5,sstatus
ffffffffc0203cb0:	8b89                	andi	a5,a5,2
ffffffffc0203cb2:	ef91                	bnez	a5,ffffffffc0203cce <page_insert+0xcc>
        pmm_manager->free_pages(base, n);
ffffffffc0203cb4:	000af797          	auipc	a5,0xaf
ffffffffc0203cb8:	d5c7b783          	ld	a5,-676(a5) # ffffffffc02b2a10 <pmm_manager>
ffffffffc0203cbc:	739c                	ld	a5,32(a5)
ffffffffc0203cbe:	4585                	li	a1,1
ffffffffc0203cc0:	854a                	mv	a0,s2
ffffffffc0203cc2:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0203cc4:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203cc8:	120a0073          	sfence.vma	s4
ffffffffc0203ccc:	bf85                	j	ffffffffc0203c3c <page_insert+0x3a>
        intr_disable();
ffffffffc0203cce:	97bfc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0203cd2:	000af797          	auipc	a5,0xaf
ffffffffc0203cd6:	d3e7b783          	ld	a5,-706(a5) # ffffffffc02b2a10 <pmm_manager>
ffffffffc0203cda:	739c                	ld	a5,32(a5)
ffffffffc0203cdc:	4585                	li	a1,1
ffffffffc0203cde:	854a                	mv	a0,s2
ffffffffc0203ce0:	9782                	jalr	a5
        intr_enable();
ffffffffc0203ce2:	961fc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0203ce6:	000ab703          	ld	a4,0(s5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203cea:	120a0073          	sfence.vma	s4
ffffffffc0203cee:	b7b9                	j	ffffffffc0203c3c <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc0203cf0:	5571                	li	a0,-4
ffffffffc0203cf2:	b79d                	j	ffffffffc0203c58 <page_insert+0x56>
ffffffffc0203cf4:	f30ff0ef          	jal	ra,ffffffffc0203424 <pa2page.part.0>

ffffffffc0203cf8 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0203cf8:	00004797          	auipc	a5,0x4
ffffffffc0203cfc:	05078793          	addi	a5,a5,80 # ffffffffc0207d48 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0203d00:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc0203d02:	711d                	addi	sp,sp,-96
ffffffffc0203d04:	ec5e                	sd	s7,24(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0203d06:	00004517          	auipc	a0,0x4
ffffffffc0203d0a:	0d250513          	addi	a0,a0,210 # ffffffffc0207dd8 <default_pmm_manager+0x90>
    pmm_manager = &default_pmm_manager;
ffffffffc0203d0e:	000afb97          	auipc	s7,0xaf
ffffffffc0203d12:	d02b8b93          	addi	s7,s7,-766 # ffffffffc02b2a10 <pmm_manager>
void pmm_init(void) {
ffffffffc0203d16:	ec86                	sd	ra,88(sp)
ffffffffc0203d18:	e4a6                	sd	s1,72(sp)
ffffffffc0203d1a:	fc4e                	sd	s3,56(sp)
ffffffffc0203d1c:	f05a                	sd	s6,32(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0203d1e:	00fbb023          	sd	a5,0(s7)
void pmm_init(void) {
ffffffffc0203d22:	e8a2                	sd	s0,80(sp)
ffffffffc0203d24:	e0ca                	sd	s2,64(sp)
ffffffffc0203d26:	f852                	sd	s4,48(sp)
ffffffffc0203d28:	f456                	sd	s5,40(sp)
ffffffffc0203d2a:	e862                	sd	s8,16(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0203d2c:	ba0fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    pmm_manager->init();
ffffffffc0203d30:	000bb783          	ld	a5,0(s7)
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0203d34:	000af997          	auipc	s3,0xaf
ffffffffc0203d38:	ce498993          	addi	s3,s3,-796 # ffffffffc02b2a18 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc0203d3c:	000af497          	auipc	s1,0xaf
ffffffffc0203d40:	cc448493          	addi	s1,s1,-828 # ffffffffc02b2a00 <npage>
    pmm_manager->init();
ffffffffc0203d44:	679c                	ld	a5,8(a5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0203d46:	000afb17          	auipc	s6,0xaf
ffffffffc0203d4a:	cc2b0b13          	addi	s6,s6,-830 # ffffffffc02b2a08 <pages>
    pmm_manager->init();
ffffffffc0203d4e:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0203d50:	57f5                	li	a5,-3
ffffffffc0203d52:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0203d54:	00004517          	auipc	a0,0x4
ffffffffc0203d58:	09c50513          	addi	a0,a0,156 # ffffffffc0207df0 <default_pmm_manager+0xa8>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0203d5c:	00f9b023          	sd	a5,0(s3)
    cprintf("physcial memory map:\n");
ffffffffc0203d60:	b6cfc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc0203d64:	46c5                	li	a3,17
ffffffffc0203d66:	06ee                	slli	a3,a3,0x1b
ffffffffc0203d68:	40100613          	li	a2,1025
ffffffffc0203d6c:	07e005b7          	lui	a1,0x7e00
ffffffffc0203d70:	16fd                	addi	a3,a3,-1
ffffffffc0203d72:	0656                	slli	a2,a2,0x15
ffffffffc0203d74:	00004517          	auipc	a0,0x4
ffffffffc0203d78:	09450513          	addi	a0,a0,148 # ffffffffc0207e08 <default_pmm_manager+0xc0>
ffffffffc0203d7c:	b50fc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0203d80:	777d                	lui	a4,0xfffff
ffffffffc0203d82:	000b0797          	auipc	a5,0xb0
ffffffffc0203d86:	cb978793          	addi	a5,a5,-839 # ffffffffc02b3a3b <end+0xfff>
ffffffffc0203d8a:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0203d8c:	00088737          	lui	a4,0x88
ffffffffc0203d90:	e098                	sd	a4,0(s1)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0203d92:	00fb3023          	sd	a5,0(s6)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0203d96:	4701                	li	a4,0
ffffffffc0203d98:	4585                	li	a1,1
ffffffffc0203d9a:	fff80837          	lui	a6,0xfff80
ffffffffc0203d9e:	a019                	j	ffffffffc0203da4 <pmm_init+0xac>
        SetPageReserved(pages + i);
ffffffffc0203da0:	000b3783          	ld	a5,0(s6)
ffffffffc0203da4:	00671693          	slli	a3,a4,0x6
ffffffffc0203da8:	97b6                	add	a5,a5,a3
ffffffffc0203daa:	07a1                	addi	a5,a5,8
ffffffffc0203dac:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0203db0:	6090                	ld	a2,0(s1)
ffffffffc0203db2:	0705                	addi	a4,a4,1
ffffffffc0203db4:	010607b3          	add	a5,a2,a6
ffffffffc0203db8:	fef764e3          	bltu	a4,a5,ffffffffc0203da0 <pmm_init+0xa8>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0203dbc:	000b3503          	ld	a0,0(s6)
ffffffffc0203dc0:	079a                	slli	a5,a5,0x6
ffffffffc0203dc2:	c0200737          	lui	a4,0xc0200
ffffffffc0203dc6:	00f506b3          	add	a3,a0,a5
ffffffffc0203dca:	60e6e563          	bltu	a3,a4,ffffffffc02043d4 <pmm_init+0x6dc>
ffffffffc0203dce:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) {
ffffffffc0203dd2:	4745                	li	a4,17
ffffffffc0203dd4:	076e                	slli	a4,a4,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0203dd6:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) {
ffffffffc0203dd8:	4ae6e563          	bltu	a3,a4,ffffffffc0204282 <pmm_init+0x58a>
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0203ddc:	00004517          	auipc	a0,0x4
ffffffffc0203de0:	05450513          	addi	a0,a0,84 # ffffffffc0207e30 <default_pmm_manager+0xe8>
ffffffffc0203de4:	ae8fc0ef          	jal	ra,ffffffffc02000cc <cprintf>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0203de8:	000bb783          	ld	a5,0(s7)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0203dec:	000af917          	auipc	s2,0xaf
ffffffffc0203df0:	c0c90913          	addi	s2,s2,-1012 # ffffffffc02b29f8 <boot_pgdir>
    pmm_manager->check();
ffffffffc0203df4:	7b9c                	ld	a5,48(a5)
ffffffffc0203df6:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0203df8:	00004517          	auipc	a0,0x4
ffffffffc0203dfc:	05050513          	addi	a0,a0,80 # ffffffffc0207e48 <default_pmm_manager+0x100>
ffffffffc0203e00:	accfc0ef          	jal	ra,ffffffffc02000cc <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0203e04:	00007697          	auipc	a3,0x7
ffffffffc0203e08:	1fc68693          	addi	a3,a3,508 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc0203e0c:	00d93023          	sd	a3,0(s2)
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc0203e10:	c02007b7          	lui	a5,0xc0200
ffffffffc0203e14:	5cf6ec63          	bltu	a3,a5,ffffffffc02043ec <pmm_init+0x6f4>
ffffffffc0203e18:	0009b783          	ld	a5,0(s3)
ffffffffc0203e1c:	8e9d                	sub	a3,a3,a5
ffffffffc0203e1e:	000af797          	auipc	a5,0xaf
ffffffffc0203e22:	bcd7b923          	sd	a3,-1070(a5) # ffffffffc02b29f0 <boot_cr3>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0203e26:	100027f3          	csrr	a5,sstatus
ffffffffc0203e2a:	8b89                	andi	a5,a5,2
ffffffffc0203e2c:	48079263          	bnez	a5,ffffffffc02042b0 <pmm_init+0x5b8>
        ret = pmm_manager->nr_free_pages();
ffffffffc0203e30:	000bb783          	ld	a5,0(s7)
ffffffffc0203e34:	779c                	ld	a5,40(a5)
ffffffffc0203e36:	9782                	jalr	a5
ffffffffc0203e38:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0203e3a:	6098                	ld	a4,0(s1)
ffffffffc0203e3c:	c80007b7          	lui	a5,0xc8000
ffffffffc0203e40:	83b1                	srli	a5,a5,0xc
ffffffffc0203e42:	5ee7e163          	bltu	a5,a4,ffffffffc0204424 <pmm_init+0x72c>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0203e46:	00093503          	ld	a0,0(s2)
ffffffffc0203e4a:	5a050d63          	beqz	a0,ffffffffc0204404 <pmm_init+0x70c>
ffffffffc0203e4e:	03451793          	slli	a5,a0,0x34
ffffffffc0203e52:	5a079963          	bnez	a5,ffffffffc0204404 <pmm_init+0x70c>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0203e56:	4601                	li	a2,0
ffffffffc0203e58:	4581                	li	a1,0
ffffffffc0203e5a:	8e1ff0ef          	jal	ra,ffffffffc020373a <get_page>
ffffffffc0203e5e:	62051563          	bnez	a0,ffffffffc0204488 <pmm_init+0x790>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc0203e62:	4505                	li	a0,1
ffffffffc0203e64:	df8ff0ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0203e68:	8a2a                	mv	s4,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0203e6a:	00093503          	ld	a0,0(s2)
ffffffffc0203e6e:	4681                	li	a3,0
ffffffffc0203e70:	4601                	li	a2,0
ffffffffc0203e72:	85d2                	mv	a1,s4
ffffffffc0203e74:	d8fff0ef          	jal	ra,ffffffffc0203c02 <page_insert>
ffffffffc0203e78:	5e051863          	bnez	a0,ffffffffc0204468 <pmm_init+0x770>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0203e7c:	00093503          	ld	a0,0(s2)
ffffffffc0203e80:	4601                	li	a2,0
ffffffffc0203e82:	4581                	li	a1,0
ffffffffc0203e84:	ee4ff0ef          	jal	ra,ffffffffc0203568 <get_pte>
ffffffffc0203e88:	5c050063          	beqz	a0,ffffffffc0204448 <pmm_init+0x750>
    assert(pte2page(*ptep) == p1);
ffffffffc0203e8c:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0203e8e:	0017f713          	andi	a4,a5,1
ffffffffc0203e92:	5a070963          	beqz	a4,ffffffffc0204444 <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc0203e96:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203e98:	078a                	slli	a5,a5,0x2
ffffffffc0203e9a:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203e9c:	52e7fa63          	bgeu	a5,a4,ffffffffc02043d0 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0203ea0:	000b3683          	ld	a3,0(s6)
ffffffffc0203ea4:	fff80637          	lui	a2,0xfff80
ffffffffc0203ea8:	97b2                	add	a5,a5,a2
ffffffffc0203eaa:	079a                	slli	a5,a5,0x6
ffffffffc0203eac:	97b6                	add	a5,a5,a3
ffffffffc0203eae:	10fa16e3          	bne	s4,a5,ffffffffc02047ba <pmm_init+0xac2>
    assert(page_ref(p1) == 1);
ffffffffc0203eb2:	000a2683          	lw	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bd0>
ffffffffc0203eb6:	4785                	li	a5,1
ffffffffc0203eb8:	12f69de3          	bne	a3,a5,ffffffffc02047f2 <pmm_init+0xafa>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0203ebc:	00093503          	ld	a0,0(s2)
ffffffffc0203ec0:	77fd                	lui	a5,0xfffff
ffffffffc0203ec2:	6114                	ld	a3,0(a0)
ffffffffc0203ec4:	068a                	slli	a3,a3,0x2
ffffffffc0203ec6:	8efd                	and	a3,a3,a5
ffffffffc0203ec8:	00c6d613          	srli	a2,a3,0xc
ffffffffc0203ecc:	10e677e3          	bgeu	a2,a4,ffffffffc02047da <pmm_init+0xae2>
ffffffffc0203ed0:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203ed4:	96e2                	add	a3,a3,s8
ffffffffc0203ed6:	0006ba83          	ld	s5,0(a3)
ffffffffc0203eda:	0a8a                	slli	s5,s5,0x2
ffffffffc0203edc:	00fafab3          	and	s5,s5,a5
ffffffffc0203ee0:	00cad793          	srli	a5,s5,0xc
ffffffffc0203ee4:	62e7f263          	bgeu	a5,a4,ffffffffc0204508 <pmm_init+0x810>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0203ee8:	4601                	li	a2,0
ffffffffc0203eea:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203eec:	9ae2                	add	s5,s5,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0203eee:	e7aff0ef          	jal	ra,ffffffffc0203568 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0203ef2:	0aa1                	addi	s5,s5,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0203ef4:	5f551a63          	bne	a0,s5,ffffffffc02044e8 <pmm_init+0x7f0>

    p2 = alloc_page();
ffffffffc0203ef8:	4505                	li	a0,1
ffffffffc0203efa:	d62ff0ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0203efe:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0203f00:	00093503          	ld	a0,0(s2)
ffffffffc0203f04:	46d1                	li	a3,20
ffffffffc0203f06:	6605                	lui	a2,0x1
ffffffffc0203f08:	85d6                	mv	a1,s5
ffffffffc0203f0a:	cf9ff0ef          	jal	ra,ffffffffc0203c02 <page_insert>
ffffffffc0203f0e:	58051d63          	bnez	a0,ffffffffc02044a8 <pmm_init+0x7b0>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0203f12:	00093503          	ld	a0,0(s2)
ffffffffc0203f16:	4601                	li	a2,0
ffffffffc0203f18:	6585                	lui	a1,0x1
ffffffffc0203f1a:	e4eff0ef          	jal	ra,ffffffffc0203568 <get_pte>
ffffffffc0203f1e:	0e050ae3          	beqz	a0,ffffffffc0204812 <pmm_init+0xb1a>
    assert(*ptep & PTE_U);
ffffffffc0203f22:	611c                	ld	a5,0(a0)
ffffffffc0203f24:	0107f713          	andi	a4,a5,16
ffffffffc0203f28:	6e070d63          	beqz	a4,ffffffffc0204622 <pmm_init+0x92a>
    assert(*ptep & PTE_W);
ffffffffc0203f2c:	8b91                	andi	a5,a5,4
ffffffffc0203f2e:	6a078a63          	beqz	a5,ffffffffc02045e2 <pmm_init+0x8ea>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0203f32:	00093503          	ld	a0,0(s2)
ffffffffc0203f36:	611c                	ld	a5,0(a0)
ffffffffc0203f38:	8bc1                	andi	a5,a5,16
ffffffffc0203f3a:	68078463          	beqz	a5,ffffffffc02045c2 <pmm_init+0x8ca>
    assert(page_ref(p2) == 1);
ffffffffc0203f3e:	000aa703          	lw	a4,0(s5)
ffffffffc0203f42:	4785                	li	a5,1
ffffffffc0203f44:	58f71263          	bne	a4,a5,ffffffffc02044c8 <pmm_init+0x7d0>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0203f48:	4681                	li	a3,0
ffffffffc0203f4a:	6605                	lui	a2,0x1
ffffffffc0203f4c:	85d2                	mv	a1,s4
ffffffffc0203f4e:	cb5ff0ef          	jal	ra,ffffffffc0203c02 <page_insert>
ffffffffc0203f52:	62051863          	bnez	a0,ffffffffc0204582 <pmm_init+0x88a>
    assert(page_ref(p1) == 2);
ffffffffc0203f56:	000a2703          	lw	a4,0(s4)
ffffffffc0203f5a:	4789                	li	a5,2
ffffffffc0203f5c:	60f71363          	bne	a4,a5,ffffffffc0204562 <pmm_init+0x86a>
    assert(page_ref(p2) == 0);
ffffffffc0203f60:	000aa783          	lw	a5,0(s5)
ffffffffc0203f64:	5c079f63          	bnez	a5,ffffffffc0204542 <pmm_init+0x84a>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0203f68:	00093503          	ld	a0,0(s2)
ffffffffc0203f6c:	4601                	li	a2,0
ffffffffc0203f6e:	6585                	lui	a1,0x1
ffffffffc0203f70:	df8ff0ef          	jal	ra,ffffffffc0203568 <get_pte>
ffffffffc0203f74:	5a050763          	beqz	a0,ffffffffc0204522 <pmm_init+0x82a>
    assert(pte2page(*ptep) == p1);
ffffffffc0203f78:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0203f7a:	00177793          	andi	a5,a4,1
ffffffffc0203f7e:	4c078363          	beqz	a5,ffffffffc0204444 <pmm_init+0x74c>
    if (PPN(pa) >= npage) {
ffffffffc0203f82:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203f84:	00271793          	slli	a5,a4,0x2
ffffffffc0203f88:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203f8a:	44d7f363          	bgeu	a5,a3,ffffffffc02043d0 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0203f8e:	000b3683          	ld	a3,0(s6)
ffffffffc0203f92:	fff80637          	lui	a2,0xfff80
ffffffffc0203f96:	97b2                	add	a5,a5,a2
ffffffffc0203f98:	079a                	slli	a5,a5,0x6
ffffffffc0203f9a:	97b6                	add	a5,a5,a3
ffffffffc0203f9c:	6efa1363          	bne	s4,a5,ffffffffc0204682 <pmm_init+0x98a>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203fa0:	8b41                	andi	a4,a4,16
ffffffffc0203fa2:	6c071063          	bnez	a4,ffffffffc0204662 <pmm_init+0x96a>

    page_remove(boot_pgdir, 0x0);
ffffffffc0203fa6:	00093503          	ld	a0,0(s2)
ffffffffc0203faa:	4581                	li	a1,0
ffffffffc0203fac:	bbbff0ef          	jal	ra,ffffffffc0203b66 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0203fb0:	000a2703          	lw	a4,0(s4)
ffffffffc0203fb4:	4785                	li	a5,1
ffffffffc0203fb6:	68f71663          	bne	a4,a5,ffffffffc0204642 <pmm_init+0x94a>
    assert(page_ref(p2) == 0);
ffffffffc0203fba:	000aa783          	lw	a5,0(s5)
ffffffffc0203fbe:	74079e63          	bnez	a5,ffffffffc020471a <pmm_init+0xa22>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0203fc2:	00093503          	ld	a0,0(s2)
ffffffffc0203fc6:	6585                	lui	a1,0x1
ffffffffc0203fc8:	b9fff0ef          	jal	ra,ffffffffc0203b66 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0203fcc:	000a2783          	lw	a5,0(s4)
ffffffffc0203fd0:	72079563          	bnez	a5,ffffffffc02046fa <pmm_init+0xa02>
    assert(page_ref(p2) == 0);
ffffffffc0203fd4:	000aa783          	lw	a5,0(s5)
ffffffffc0203fd8:	70079163          	bnez	a5,ffffffffc02046da <pmm_init+0x9e2>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0203fdc:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0203fe0:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0203fe2:	000a3683          	ld	a3,0(s4)
ffffffffc0203fe6:	068a                	slli	a3,a3,0x2
ffffffffc0203fe8:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203fea:	3ee6f363          	bgeu	a3,a4,ffffffffc02043d0 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0203fee:	fff807b7          	lui	a5,0xfff80
ffffffffc0203ff2:	000b3503          	ld	a0,0(s6)
ffffffffc0203ff6:	96be                	add	a3,a3,a5
ffffffffc0203ff8:	069a                	slli	a3,a3,0x6
    return page->ref;
ffffffffc0203ffa:	00d507b3          	add	a5,a0,a3
ffffffffc0203ffe:	4390                	lw	a2,0(a5)
ffffffffc0204000:	4785                	li	a5,1
ffffffffc0204002:	6af61c63          	bne	a2,a5,ffffffffc02046ba <pmm_init+0x9c2>
    return page - pages + nbase;
ffffffffc0204006:	8699                	srai	a3,a3,0x6
ffffffffc0204008:	000805b7          	lui	a1,0x80
ffffffffc020400c:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc020400e:	00c69613          	slli	a2,a3,0xc
ffffffffc0204012:	8231                	srli	a2,a2,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0204014:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204016:	68e67663          	bgeu	a2,a4,ffffffffc02046a2 <pmm_init+0x9aa>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc020401a:	0009b603          	ld	a2,0(s3)
ffffffffc020401e:	96b2                	add	a3,a3,a2
    return pa2page(PDE_ADDR(pde));
ffffffffc0204020:	629c                	ld	a5,0(a3)
ffffffffc0204022:	078a                	slli	a5,a5,0x2
ffffffffc0204024:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0204026:	3ae7f563          	bgeu	a5,a4,ffffffffc02043d0 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc020402a:	8f8d                	sub	a5,a5,a1
ffffffffc020402c:	079a                	slli	a5,a5,0x6
ffffffffc020402e:	953e                	add	a0,a0,a5
ffffffffc0204030:	100027f3          	csrr	a5,sstatus
ffffffffc0204034:	8b89                	andi	a5,a5,2
ffffffffc0204036:	2c079763          	bnez	a5,ffffffffc0204304 <pmm_init+0x60c>
        pmm_manager->free_pages(base, n);
ffffffffc020403a:	000bb783          	ld	a5,0(s7)
ffffffffc020403e:	4585                	li	a1,1
ffffffffc0204040:	739c                	ld	a5,32(a5)
ffffffffc0204042:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0204044:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc0204048:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020404a:	078a                	slli	a5,a5,0x2
ffffffffc020404c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020404e:	38e7f163          	bgeu	a5,a4,ffffffffc02043d0 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0204052:	000b3503          	ld	a0,0(s6)
ffffffffc0204056:	fff80737          	lui	a4,0xfff80
ffffffffc020405a:	97ba                	add	a5,a5,a4
ffffffffc020405c:	079a                	slli	a5,a5,0x6
ffffffffc020405e:	953e                	add	a0,a0,a5
ffffffffc0204060:	100027f3          	csrr	a5,sstatus
ffffffffc0204064:	8b89                	andi	a5,a5,2
ffffffffc0204066:	28079363          	bnez	a5,ffffffffc02042ec <pmm_init+0x5f4>
ffffffffc020406a:	000bb783          	ld	a5,0(s7)
ffffffffc020406e:	4585                	li	a1,1
ffffffffc0204070:	739c                	ld	a5,32(a5)
ffffffffc0204072:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0204074:	00093783          	ld	a5,0(s2)
ffffffffc0204078:	0007b023          	sd	zero,0(a5) # fffffffffff80000 <end+0x3fccd5c4>
  asm volatile("sfence.vma");
ffffffffc020407c:	12000073          	sfence.vma
ffffffffc0204080:	100027f3          	csrr	a5,sstatus
ffffffffc0204084:	8b89                	andi	a5,a5,2
ffffffffc0204086:	24079963          	bnez	a5,ffffffffc02042d8 <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc020408a:	000bb783          	ld	a5,0(s7)
ffffffffc020408e:	779c                	ld	a5,40(a5)
ffffffffc0204090:	9782                	jalr	a5
ffffffffc0204092:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0204094:	71441363          	bne	s0,s4,ffffffffc020479a <pmm_init+0xaa2>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0204098:	00004517          	auipc	a0,0x4
ffffffffc020409c:	09850513          	addi	a0,a0,152 # ffffffffc0208130 <default_pmm_manager+0x3e8>
ffffffffc02040a0:	82cfc0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc02040a4:	100027f3          	csrr	a5,sstatus
ffffffffc02040a8:	8b89                	andi	a5,a5,2
ffffffffc02040aa:	20079d63          	bnez	a5,ffffffffc02042c4 <pmm_init+0x5cc>
        ret = pmm_manager->nr_free_pages();
ffffffffc02040ae:	000bb783          	ld	a5,0(s7)
ffffffffc02040b2:	779c                	ld	a5,40(a5)
ffffffffc02040b4:	9782                	jalr	a5
ffffffffc02040b6:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02040b8:	6098                	ld	a4,0(s1)
ffffffffc02040ba:	c0200437          	lui	s0,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02040be:	7afd                	lui	s5,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02040c0:	00c71793          	slli	a5,a4,0xc
ffffffffc02040c4:	6a05                	lui	s4,0x1
ffffffffc02040c6:	02f47c63          	bgeu	s0,a5,ffffffffc02040fe <pmm_init+0x406>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02040ca:	00c45793          	srli	a5,s0,0xc
ffffffffc02040ce:	00093503          	ld	a0,0(s2)
ffffffffc02040d2:	2ee7f263          	bgeu	a5,a4,ffffffffc02043b6 <pmm_init+0x6be>
ffffffffc02040d6:	0009b583          	ld	a1,0(s3)
ffffffffc02040da:	4601                	li	a2,0
ffffffffc02040dc:	95a2                	add	a1,a1,s0
ffffffffc02040de:	c8aff0ef          	jal	ra,ffffffffc0203568 <get_pte>
ffffffffc02040e2:	2a050a63          	beqz	a0,ffffffffc0204396 <pmm_init+0x69e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02040e6:	611c                	ld	a5,0(a0)
ffffffffc02040e8:	078a                	slli	a5,a5,0x2
ffffffffc02040ea:	0157f7b3          	and	a5,a5,s5
ffffffffc02040ee:	28879463          	bne	a5,s0,ffffffffc0204376 <pmm_init+0x67e>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02040f2:	6098                	ld	a4,0(s1)
ffffffffc02040f4:	9452                	add	s0,s0,s4
ffffffffc02040f6:	00c71793          	slli	a5,a4,0xc
ffffffffc02040fa:	fcf468e3          	bltu	s0,a5,ffffffffc02040ca <pmm_init+0x3d2>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc02040fe:	00093783          	ld	a5,0(s2)
ffffffffc0204102:	639c                	ld	a5,0(a5)
ffffffffc0204104:	66079b63          	bnez	a5,ffffffffc020477a <pmm_init+0xa82>

    struct Page *p;
    p = alloc_page();
ffffffffc0204108:	4505                	li	a0,1
ffffffffc020410a:	b52ff0ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc020410e:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0204110:	00093503          	ld	a0,0(s2)
ffffffffc0204114:	4699                	li	a3,6
ffffffffc0204116:	10000613          	li	a2,256
ffffffffc020411a:	85d6                	mv	a1,s5
ffffffffc020411c:	ae7ff0ef          	jal	ra,ffffffffc0203c02 <page_insert>
ffffffffc0204120:	62051d63          	bnez	a0,ffffffffc020475a <pmm_init+0xa62>
    assert(page_ref(p) == 1);
ffffffffc0204124:	000aa703          	lw	a4,0(s5) # fffffffffffff000 <end+0x3fd4c5c4>
ffffffffc0204128:	4785                	li	a5,1
ffffffffc020412a:	60f71863          	bne	a4,a5,ffffffffc020473a <pmm_init+0xa42>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc020412e:	00093503          	ld	a0,0(s2)
ffffffffc0204132:	6405                	lui	s0,0x1
ffffffffc0204134:	4699                	li	a3,6
ffffffffc0204136:	10040613          	addi	a2,s0,256 # 1100 <_binary_obj___user_faultread_out_size-0x8ad0>
ffffffffc020413a:	85d6                	mv	a1,s5
ffffffffc020413c:	ac7ff0ef          	jal	ra,ffffffffc0203c02 <page_insert>
ffffffffc0204140:	46051163          	bnez	a0,ffffffffc02045a2 <pmm_init+0x8aa>
    assert(page_ref(p) == 2);
ffffffffc0204144:	000aa703          	lw	a4,0(s5)
ffffffffc0204148:	4789                	li	a5,2
ffffffffc020414a:	72f71463          	bne	a4,a5,ffffffffc0204872 <pmm_init+0xb7a>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc020414e:	00004597          	auipc	a1,0x4
ffffffffc0204152:	11a58593          	addi	a1,a1,282 # ffffffffc0208268 <default_pmm_manager+0x520>
ffffffffc0204156:	10000513          	li	a0,256
ffffffffc020415a:	01a020ef          	jal	ra,ffffffffc0206174 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc020415e:	10040593          	addi	a1,s0,256
ffffffffc0204162:	10000513          	li	a0,256
ffffffffc0204166:	020020ef          	jal	ra,ffffffffc0206186 <strcmp>
ffffffffc020416a:	6e051463          	bnez	a0,ffffffffc0204852 <pmm_init+0xb5a>
    return page - pages + nbase;
ffffffffc020416e:	000b3683          	ld	a3,0(s6)
ffffffffc0204172:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0204176:	547d                	li	s0,-1
    return page - pages + nbase;
ffffffffc0204178:	40da86b3          	sub	a3,s5,a3
ffffffffc020417c:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020417e:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0204180:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0204182:	8031                	srli	s0,s0,0xc
ffffffffc0204184:	0086f733          	and	a4,a3,s0
    return page2ppn(page) << PGSHIFT;
ffffffffc0204188:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020418a:	50f77c63          	bgeu	a4,a5,ffffffffc02046a2 <pmm_init+0x9aa>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc020418e:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0204192:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0204196:	96be                	add	a3,a3,a5
ffffffffc0204198:	10068023          	sb	zero,256(a3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc020419c:	7a3010ef          	jal	ra,ffffffffc020613e <strlen>
ffffffffc02041a0:	68051963          	bnez	a0,ffffffffc0204832 <pmm_init+0xb3a>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc02041a4:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc02041a8:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02041aa:	000a3683          	ld	a3,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bd0>
ffffffffc02041ae:	068a                	slli	a3,a3,0x2
ffffffffc02041b0:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc02041b2:	20f6ff63          	bgeu	a3,a5,ffffffffc02043d0 <pmm_init+0x6d8>
    return KADDR(page2pa(page));
ffffffffc02041b6:	8c75                	and	s0,s0,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02041b8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02041ba:	4ef47463          	bgeu	s0,a5,ffffffffc02046a2 <pmm_init+0x9aa>
ffffffffc02041be:	0009b403          	ld	s0,0(s3)
ffffffffc02041c2:	9436                	add	s0,s0,a3
ffffffffc02041c4:	100027f3          	csrr	a5,sstatus
ffffffffc02041c8:	8b89                	andi	a5,a5,2
ffffffffc02041ca:	18079b63          	bnez	a5,ffffffffc0204360 <pmm_init+0x668>
        pmm_manager->free_pages(base, n);
ffffffffc02041ce:	000bb783          	ld	a5,0(s7)
ffffffffc02041d2:	4585                	li	a1,1
ffffffffc02041d4:	8556                	mv	a0,s5
ffffffffc02041d6:	739c                	ld	a5,32(a5)
ffffffffc02041d8:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc02041da:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc02041dc:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc02041de:	078a                	slli	a5,a5,0x2
ffffffffc02041e0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02041e2:	1ee7f763          	bgeu	a5,a4,ffffffffc02043d0 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc02041e6:	000b3503          	ld	a0,0(s6)
ffffffffc02041ea:	fff80737          	lui	a4,0xfff80
ffffffffc02041ee:	97ba                	add	a5,a5,a4
ffffffffc02041f0:	079a                	slli	a5,a5,0x6
ffffffffc02041f2:	953e                	add	a0,a0,a5
ffffffffc02041f4:	100027f3          	csrr	a5,sstatus
ffffffffc02041f8:	8b89                	andi	a5,a5,2
ffffffffc02041fa:	14079763          	bnez	a5,ffffffffc0204348 <pmm_init+0x650>
ffffffffc02041fe:	000bb783          	ld	a5,0(s7)
ffffffffc0204202:	4585                	li	a1,1
ffffffffc0204204:	739c                	ld	a5,32(a5)
ffffffffc0204206:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0204208:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage) {
ffffffffc020420c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020420e:	078a                	slli	a5,a5,0x2
ffffffffc0204210:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0204212:	1ae7ff63          	bgeu	a5,a4,ffffffffc02043d0 <pmm_init+0x6d8>
    return &pages[PPN(pa) - nbase];
ffffffffc0204216:	000b3503          	ld	a0,0(s6)
ffffffffc020421a:	fff80737          	lui	a4,0xfff80
ffffffffc020421e:	97ba                	add	a5,a5,a4
ffffffffc0204220:	079a                	slli	a5,a5,0x6
ffffffffc0204222:	953e                	add	a0,a0,a5
ffffffffc0204224:	100027f3          	csrr	a5,sstatus
ffffffffc0204228:	8b89                	andi	a5,a5,2
ffffffffc020422a:	10079363          	bnez	a5,ffffffffc0204330 <pmm_init+0x638>
ffffffffc020422e:	000bb783          	ld	a5,0(s7)
ffffffffc0204232:	4585                	li	a1,1
ffffffffc0204234:	739c                	ld	a5,32(a5)
ffffffffc0204236:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir[0] = 0;
ffffffffc0204238:	00093783          	ld	a5,0(s2)
ffffffffc020423c:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc0204240:	12000073          	sfence.vma
ffffffffc0204244:	100027f3          	csrr	a5,sstatus
ffffffffc0204248:	8b89                	andi	a5,a5,2
ffffffffc020424a:	0c079963          	bnez	a5,ffffffffc020431c <pmm_init+0x624>
        ret = pmm_manager->nr_free_pages();
ffffffffc020424e:	000bb783          	ld	a5,0(s7)
ffffffffc0204252:	779c                	ld	a5,40(a5)
ffffffffc0204254:	9782                	jalr	a5
ffffffffc0204256:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0204258:	3a8c1563          	bne	s8,s0,ffffffffc0204602 <pmm_init+0x90a>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc020425c:	00004517          	auipc	a0,0x4
ffffffffc0204260:	08450513          	addi	a0,a0,132 # ffffffffc02082e0 <default_pmm_manager+0x598>
ffffffffc0204264:	e69fb0ef          	jal	ra,ffffffffc02000cc <cprintf>
}
ffffffffc0204268:	6446                	ld	s0,80(sp)
ffffffffc020426a:	60e6                	ld	ra,88(sp)
ffffffffc020426c:	64a6                	ld	s1,72(sp)
ffffffffc020426e:	6906                	ld	s2,64(sp)
ffffffffc0204270:	79e2                	ld	s3,56(sp)
ffffffffc0204272:	7a42                	ld	s4,48(sp)
ffffffffc0204274:	7aa2                	ld	s5,40(sp)
ffffffffc0204276:	7b02                	ld	s6,32(sp)
ffffffffc0204278:	6be2                	ld	s7,24(sp)
ffffffffc020427a:	6c42                	ld	s8,16(sp)
ffffffffc020427c:	6125                	addi	sp,sp,96
    kmalloc_init();
ffffffffc020427e:	c27fd06f          	j	ffffffffc0201ea4 <kmalloc_init>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0204282:	6785                	lui	a5,0x1
ffffffffc0204284:	17fd                	addi	a5,a5,-1
ffffffffc0204286:	96be                	add	a3,a3,a5
ffffffffc0204288:	77fd                	lui	a5,0xfffff
ffffffffc020428a:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage) {
ffffffffc020428c:	00c7d693          	srli	a3,a5,0xc
ffffffffc0204290:	14c6f063          	bgeu	a3,a2,ffffffffc02043d0 <pmm_init+0x6d8>
    pmm_manager->init_memmap(base, n);
ffffffffc0204294:	000bb603          	ld	a2,0(s7)
    return &pages[PPN(pa) - nbase];
ffffffffc0204298:	96c2                	add	a3,a3,a6
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020429a:	40f707b3          	sub	a5,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc020429e:	6a10                	ld	a2,16(a2)
ffffffffc02042a0:	069a                	slli	a3,a3,0x6
ffffffffc02042a2:	00c7d593          	srli	a1,a5,0xc
ffffffffc02042a6:	9536                	add	a0,a0,a3
ffffffffc02042a8:	9602                	jalr	a2
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc02042aa:	0009b583          	ld	a1,0(s3)
}
ffffffffc02042ae:	b63d                	j	ffffffffc0203ddc <pmm_init+0xe4>
        intr_disable();
ffffffffc02042b0:	b98fc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc02042b4:	000bb783          	ld	a5,0(s7)
ffffffffc02042b8:	779c                	ld	a5,40(a5)
ffffffffc02042ba:	9782                	jalr	a5
ffffffffc02042bc:	842a                	mv	s0,a0
        intr_enable();
ffffffffc02042be:	b84fc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc02042c2:	bea5                	j	ffffffffc0203e3a <pmm_init+0x142>
        intr_disable();
ffffffffc02042c4:	b84fc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc02042c8:	000bb783          	ld	a5,0(s7)
ffffffffc02042cc:	779c                	ld	a5,40(a5)
ffffffffc02042ce:	9782                	jalr	a5
ffffffffc02042d0:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc02042d2:	b70fc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc02042d6:	b3cd                	j	ffffffffc02040b8 <pmm_init+0x3c0>
        intr_disable();
ffffffffc02042d8:	b70fc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc02042dc:	000bb783          	ld	a5,0(s7)
ffffffffc02042e0:	779c                	ld	a5,40(a5)
ffffffffc02042e2:	9782                	jalr	a5
ffffffffc02042e4:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc02042e6:	b5cfc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc02042ea:	b36d                	j	ffffffffc0204094 <pmm_init+0x39c>
ffffffffc02042ec:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02042ee:	b5afc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02042f2:	000bb783          	ld	a5,0(s7)
ffffffffc02042f6:	6522                	ld	a0,8(sp)
ffffffffc02042f8:	4585                	li	a1,1
ffffffffc02042fa:	739c                	ld	a5,32(a5)
ffffffffc02042fc:	9782                	jalr	a5
        intr_enable();
ffffffffc02042fe:	b44fc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0204302:	bb8d                	j	ffffffffc0204074 <pmm_init+0x37c>
ffffffffc0204304:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0204306:	b42fc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc020430a:	000bb783          	ld	a5,0(s7)
ffffffffc020430e:	6522                	ld	a0,8(sp)
ffffffffc0204310:	4585                	li	a1,1
ffffffffc0204312:	739c                	ld	a5,32(a5)
ffffffffc0204314:	9782                	jalr	a5
        intr_enable();
ffffffffc0204316:	b2cfc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc020431a:	b32d                	j	ffffffffc0204044 <pmm_init+0x34c>
        intr_disable();
ffffffffc020431c:	b2cfc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0204320:	000bb783          	ld	a5,0(s7)
ffffffffc0204324:	779c                	ld	a5,40(a5)
ffffffffc0204326:	9782                	jalr	a5
ffffffffc0204328:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020432a:	b18fc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc020432e:	b72d                	j	ffffffffc0204258 <pmm_init+0x560>
ffffffffc0204330:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0204332:	b16fc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0204336:	000bb783          	ld	a5,0(s7)
ffffffffc020433a:	6522                	ld	a0,8(sp)
ffffffffc020433c:	4585                	li	a1,1
ffffffffc020433e:	739c                	ld	a5,32(a5)
ffffffffc0204340:	9782                	jalr	a5
        intr_enable();
ffffffffc0204342:	b00fc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0204346:	bdcd                	j	ffffffffc0204238 <pmm_init+0x540>
ffffffffc0204348:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc020434a:	afefc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc020434e:	000bb783          	ld	a5,0(s7)
ffffffffc0204352:	6522                	ld	a0,8(sp)
ffffffffc0204354:	4585                	li	a1,1
ffffffffc0204356:	739c                	ld	a5,32(a5)
ffffffffc0204358:	9782                	jalr	a5
        intr_enable();
ffffffffc020435a:	ae8fc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc020435e:	b56d                	j	ffffffffc0204208 <pmm_init+0x510>
        intr_disable();
ffffffffc0204360:	ae8fc0ef          	jal	ra,ffffffffc0200648 <intr_disable>
ffffffffc0204364:	000bb783          	ld	a5,0(s7)
ffffffffc0204368:	4585                	li	a1,1
ffffffffc020436a:	8556                	mv	a0,s5
ffffffffc020436c:	739c                	ld	a5,32(a5)
ffffffffc020436e:	9782                	jalr	a5
        intr_enable();
ffffffffc0204370:	ad2fc0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0204374:	b59d                	j	ffffffffc02041da <pmm_init+0x4e2>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0204376:	00004697          	auipc	a3,0x4
ffffffffc020437a:	e1a68693          	addi	a3,a3,-486 # ffffffffc0208190 <default_pmm_manager+0x448>
ffffffffc020437e:	00003617          	auipc	a2,0x3
ffffffffc0204382:	92260613          	addi	a2,a2,-1758 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204386:	28900593          	li	a1,649
ffffffffc020438a:	00004517          	auipc	a0,0x4
ffffffffc020438e:	9f650513          	addi	a0,a0,-1546 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0204392:	e77fb0ef          	jal	ra,ffffffffc0200208 <__panic>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0204396:	00004697          	auipc	a3,0x4
ffffffffc020439a:	dba68693          	addi	a3,a3,-582 # ffffffffc0208150 <default_pmm_manager+0x408>
ffffffffc020439e:	00003617          	auipc	a2,0x3
ffffffffc02043a2:	90260613          	addi	a2,a2,-1790 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02043a6:	28800593          	li	a1,648
ffffffffc02043aa:	00004517          	auipc	a0,0x4
ffffffffc02043ae:	9d650513          	addi	a0,a0,-1578 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc02043b2:	e57fb0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc02043b6:	86a2                	mv	a3,s0
ffffffffc02043b8:	00003617          	auipc	a2,0x3
ffffffffc02043bc:	09860613          	addi	a2,a2,152 # ffffffffc0207450 <commands+0xbc0>
ffffffffc02043c0:	28800593          	li	a1,648
ffffffffc02043c4:	00004517          	auipc	a0,0x4
ffffffffc02043c8:	9bc50513          	addi	a0,a0,-1604 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc02043cc:	e3dfb0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc02043d0:	854ff0ef          	jal	ra,ffffffffc0203424 <pa2page.part.0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02043d4:	00003617          	auipc	a2,0x3
ffffffffc02043d8:	22460613          	addi	a2,a2,548 # ffffffffc02075f8 <commands+0xd68>
ffffffffc02043dc:	08000593          	li	a1,128
ffffffffc02043e0:	00004517          	auipc	a0,0x4
ffffffffc02043e4:	9a050513          	addi	a0,a0,-1632 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc02043e8:	e21fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02043ec:	00003617          	auipc	a2,0x3
ffffffffc02043f0:	20c60613          	addi	a2,a2,524 # ffffffffc02075f8 <commands+0xd68>
ffffffffc02043f4:	0db00593          	li	a1,219
ffffffffc02043f8:	00004517          	auipc	a0,0x4
ffffffffc02043fc:	98850513          	addi	a0,a0,-1656 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0204400:	e09fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0204404:	00004697          	auipc	a3,0x4
ffffffffc0204408:	a8468693          	addi	a3,a3,-1404 # ffffffffc0207e88 <default_pmm_manager+0x140>
ffffffffc020440c:	00003617          	auipc	a2,0x3
ffffffffc0204410:	89460613          	addi	a2,a2,-1900 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204414:	24c00593          	li	a1,588
ffffffffc0204418:	00004517          	auipc	a0,0x4
ffffffffc020441c:	96850513          	addi	a0,a0,-1688 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0204420:	de9fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0204424:	00004697          	auipc	a3,0x4
ffffffffc0204428:	a4468693          	addi	a3,a3,-1468 # ffffffffc0207e68 <default_pmm_manager+0x120>
ffffffffc020442c:	00003617          	auipc	a2,0x3
ffffffffc0204430:	87460613          	addi	a2,a2,-1932 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204434:	24b00593          	li	a1,587
ffffffffc0204438:	00004517          	auipc	a0,0x4
ffffffffc020443c:	94850513          	addi	a0,a0,-1720 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0204440:	dc9fb0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0204444:	ffdfe0ef          	jal	ra,ffffffffc0203440 <pte2page.part.0>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0204448:	00004697          	auipc	a3,0x4
ffffffffc020444c:	ad068693          	addi	a3,a3,-1328 # ffffffffc0207f18 <default_pmm_manager+0x1d0>
ffffffffc0204450:	00003617          	auipc	a2,0x3
ffffffffc0204454:	85060613          	addi	a2,a2,-1968 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204458:	25400593          	li	a1,596
ffffffffc020445c:	00004517          	auipc	a0,0x4
ffffffffc0204460:	92450513          	addi	a0,a0,-1756 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0204464:	da5fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0204468:	00004697          	auipc	a3,0x4
ffffffffc020446c:	a8068693          	addi	a3,a3,-1408 # ffffffffc0207ee8 <default_pmm_manager+0x1a0>
ffffffffc0204470:	00003617          	auipc	a2,0x3
ffffffffc0204474:	83060613          	addi	a2,a2,-2000 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204478:	25100593          	li	a1,593
ffffffffc020447c:	00004517          	auipc	a0,0x4
ffffffffc0204480:	90450513          	addi	a0,a0,-1788 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0204484:	d85fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0204488:	00004697          	auipc	a3,0x4
ffffffffc020448c:	a3868693          	addi	a3,a3,-1480 # ffffffffc0207ec0 <default_pmm_manager+0x178>
ffffffffc0204490:	00003617          	auipc	a2,0x3
ffffffffc0204494:	81060613          	addi	a2,a2,-2032 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204498:	24d00593          	li	a1,589
ffffffffc020449c:	00004517          	auipc	a0,0x4
ffffffffc02044a0:	8e450513          	addi	a0,a0,-1820 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc02044a4:	d65fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc02044a8:	00004697          	auipc	a3,0x4
ffffffffc02044ac:	af868693          	addi	a3,a3,-1288 # ffffffffc0207fa0 <default_pmm_manager+0x258>
ffffffffc02044b0:	00002617          	auipc	a2,0x2
ffffffffc02044b4:	7f060613          	addi	a2,a2,2032 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02044b8:	25d00593          	li	a1,605
ffffffffc02044bc:	00004517          	auipc	a0,0x4
ffffffffc02044c0:	8c450513          	addi	a0,a0,-1852 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc02044c4:	d45fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc02044c8:	00004697          	auipc	a3,0x4
ffffffffc02044cc:	b7868693          	addi	a3,a3,-1160 # ffffffffc0208040 <default_pmm_manager+0x2f8>
ffffffffc02044d0:	00002617          	auipc	a2,0x2
ffffffffc02044d4:	7d060613          	addi	a2,a2,2000 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02044d8:	26200593          	li	a1,610
ffffffffc02044dc:	00004517          	auipc	a0,0x4
ffffffffc02044e0:	8a450513          	addi	a0,a0,-1884 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc02044e4:	d25fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc02044e8:	00004697          	auipc	a3,0x4
ffffffffc02044ec:	a9068693          	addi	a3,a3,-1392 # ffffffffc0207f78 <default_pmm_manager+0x230>
ffffffffc02044f0:	00002617          	auipc	a2,0x2
ffffffffc02044f4:	7b060613          	addi	a2,a2,1968 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02044f8:	25a00593          	li	a1,602
ffffffffc02044fc:	00004517          	auipc	a0,0x4
ffffffffc0204500:	88450513          	addi	a0,a0,-1916 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0204504:	d05fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0204508:	86d6                	mv	a3,s5
ffffffffc020450a:	00003617          	auipc	a2,0x3
ffffffffc020450e:	f4660613          	addi	a2,a2,-186 # ffffffffc0207450 <commands+0xbc0>
ffffffffc0204512:	25900593          	li	a1,601
ffffffffc0204516:	00004517          	auipc	a0,0x4
ffffffffc020451a:	86a50513          	addi	a0,a0,-1942 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc020451e:	cebfb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0204522:	00004697          	auipc	a3,0x4
ffffffffc0204526:	ab668693          	addi	a3,a3,-1354 # ffffffffc0207fd8 <default_pmm_manager+0x290>
ffffffffc020452a:	00002617          	auipc	a2,0x2
ffffffffc020452e:	77660613          	addi	a2,a2,1910 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204532:	26700593          	li	a1,615
ffffffffc0204536:	00004517          	auipc	a0,0x4
ffffffffc020453a:	84a50513          	addi	a0,a0,-1974 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc020453e:	ccbfb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0204542:	00004697          	auipc	a3,0x4
ffffffffc0204546:	b5e68693          	addi	a3,a3,-1186 # ffffffffc02080a0 <default_pmm_manager+0x358>
ffffffffc020454a:	00002617          	auipc	a2,0x2
ffffffffc020454e:	75660613          	addi	a2,a2,1878 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204552:	26600593          	li	a1,614
ffffffffc0204556:	00004517          	auipc	a0,0x4
ffffffffc020455a:	82a50513          	addi	a0,a0,-2006 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc020455e:	cabfb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0204562:	00004697          	auipc	a3,0x4
ffffffffc0204566:	b2668693          	addi	a3,a3,-1242 # ffffffffc0208088 <default_pmm_manager+0x340>
ffffffffc020456a:	00002617          	auipc	a2,0x2
ffffffffc020456e:	73660613          	addi	a2,a2,1846 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204572:	26500593          	li	a1,613
ffffffffc0204576:	00004517          	auipc	a0,0x4
ffffffffc020457a:	80a50513          	addi	a0,a0,-2038 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc020457e:	c8bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0204582:	00004697          	auipc	a3,0x4
ffffffffc0204586:	ad668693          	addi	a3,a3,-1322 # ffffffffc0208058 <default_pmm_manager+0x310>
ffffffffc020458a:	00002617          	auipc	a2,0x2
ffffffffc020458e:	71660613          	addi	a2,a2,1814 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204592:	26400593          	li	a1,612
ffffffffc0204596:	00003517          	auipc	a0,0x3
ffffffffc020459a:	7ea50513          	addi	a0,a0,2026 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc020459e:	c6bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc02045a2:	00004697          	auipc	a3,0x4
ffffffffc02045a6:	c6e68693          	addi	a3,a3,-914 # ffffffffc0208210 <default_pmm_manager+0x4c8>
ffffffffc02045aa:	00002617          	auipc	a2,0x2
ffffffffc02045ae:	6f660613          	addi	a2,a2,1782 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02045b2:	29300593          	li	a1,659
ffffffffc02045b6:	00003517          	auipc	a0,0x3
ffffffffc02045ba:	7ca50513          	addi	a0,a0,1994 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc02045be:	c4bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc02045c2:	00004697          	auipc	a3,0x4
ffffffffc02045c6:	a6668693          	addi	a3,a3,-1434 # ffffffffc0208028 <default_pmm_manager+0x2e0>
ffffffffc02045ca:	00002617          	auipc	a2,0x2
ffffffffc02045ce:	6d660613          	addi	a2,a2,1750 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02045d2:	26100593          	li	a1,609
ffffffffc02045d6:	00003517          	auipc	a0,0x3
ffffffffc02045da:	7aa50513          	addi	a0,a0,1962 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc02045de:	c2bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(*ptep & PTE_W);
ffffffffc02045e2:	00004697          	auipc	a3,0x4
ffffffffc02045e6:	a3668693          	addi	a3,a3,-1482 # ffffffffc0208018 <default_pmm_manager+0x2d0>
ffffffffc02045ea:	00002617          	auipc	a2,0x2
ffffffffc02045ee:	6b660613          	addi	a2,a2,1718 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02045f2:	26000593          	li	a1,608
ffffffffc02045f6:	00003517          	auipc	a0,0x3
ffffffffc02045fa:	78a50513          	addi	a0,a0,1930 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc02045fe:	c0bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0204602:	00004697          	auipc	a3,0x4
ffffffffc0204606:	b0e68693          	addi	a3,a3,-1266 # ffffffffc0208110 <default_pmm_manager+0x3c8>
ffffffffc020460a:	00002617          	auipc	a2,0x2
ffffffffc020460e:	69660613          	addi	a2,a2,1686 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204612:	2a400593          	li	a1,676
ffffffffc0204616:	00003517          	auipc	a0,0x3
ffffffffc020461a:	76a50513          	addi	a0,a0,1898 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc020461e:	bebfb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0204622:	00004697          	auipc	a3,0x4
ffffffffc0204626:	9e668693          	addi	a3,a3,-1562 # ffffffffc0208008 <default_pmm_manager+0x2c0>
ffffffffc020462a:	00002617          	auipc	a2,0x2
ffffffffc020462e:	67660613          	addi	a2,a2,1654 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204632:	25f00593          	li	a1,607
ffffffffc0204636:	00003517          	auipc	a0,0x3
ffffffffc020463a:	74a50513          	addi	a0,a0,1866 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc020463e:	bcbfb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0204642:	00004697          	auipc	a3,0x4
ffffffffc0204646:	91e68693          	addi	a3,a3,-1762 # ffffffffc0207f60 <default_pmm_manager+0x218>
ffffffffc020464a:	00002617          	auipc	a2,0x2
ffffffffc020464e:	65660613          	addi	a2,a2,1622 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204652:	26c00593          	li	a1,620
ffffffffc0204656:	00003517          	auipc	a0,0x3
ffffffffc020465a:	72a50513          	addi	a0,a0,1834 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc020465e:	babfb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0204662:	00004697          	auipc	a3,0x4
ffffffffc0204666:	a5668693          	addi	a3,a3,-1450 # ffffffffc02080b8 <default_pmm_manager+0x370>
ffffffffc020466a:	00002617          	auipc	a2,0x2
ffffffffc020466e:	63660613          	addi	a2,a2,1590 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204672:	26900593          	li	a1,617
ffffffffc0204676:	00003517          	auipc	a0,0x3
ffffffffc020467a:	70a50513          	addi	a0,a0,1802 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc020467e:	b8bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0204682:	00004697          	auipc	a3,0x4
ffffffffc0204686:	8c668693          	addi	a3,a3,-1850 # ffffffffc0207f48 <default_pmm_manager+0x200>
ffffffffc020468a:	00002617          	auipc	a2,0x2
ffffffffc020468e:	61660613          	addi	a2,a2,1558 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204692:	26800593          	li	a1,616
ffffffffc0204696:	00003517          	auipc	a0,0x3
ffffffffc020469a:	6ea50513          	addi	a0,a0,1770 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc020469e:	b6bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
    return KADDR(page2pa(page));
ffffffffc02046a2:	00003617          	auipc	a2,0x3
ffffffffc02046a6:	dae60613          	addi	a2,a2,-594 # ffffffffc0207450 <commands+0xbc0>
ffffffffc02046aa:	06a00593          	li	a1,106
ffffffffc02046ae:	00003517          	auipc	a0,0x3
ffffffffc02046b2:	d9250513          	addi	a0,a0,-622 # ffffffffc0207440 <commands+0xbb0>
ffffffffc02046b6:	b53fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc02046ba:	00004697          	auipc	a3,0x4
ffffffffc02046be:	a2e68693          	addi	a3,a3,-1490 # ffffffffc02080e8 <default_pmm_manager+0x3a0>
ffffffffc02046c2:	00002617          	auipc	a2,0x2
ffffffffc02046c6:	5de60613          	addi	a2,a2,1502 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02046ca:	27300593          	li	a1,627
ffffffffc02046ce:	00003517          	auipc	a0,0x3
ffffffffc02046d2:	6b250513          	addi	a0,a0,1714 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc02046d6:	b33fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02046da:	00004697          	auipc	a3,0x4
ffffffffc02046de:	9c668693          	addi	a3,a3,-1594 # ffffffffc02080a0 <default_pmm_manager+0x358>
ffffffffc02046e2:	00002617          	auipc	a2,0x2
ffffffffc02046e6:	5be60613          	addi	a2,a2,1470 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02046ea:	27100593          	li	a1,625
ffffffffc02046ee:	00003517          	auipc	a0,0x3
ffffffffc02046f2:	69250513          	addi	a0,a0,1682 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc02046f6:	b13fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc02046fa:	00004697          	auipc	a3,0x4
ffffffffc02046fe:	9d668693          	addi	a3,a3,-1578 # ffffffffc02080d0 <default_pmm_manager+0x388>
ffffffffc0204702:	00002617          	auipc	a2,0x2
ffffffffc0204706:	59e60613          	addi	a2,a2,1438 # ffffffffc0206ca0 <commands+0x410>
ffffffffc020470a:	27000593          	li	a1,624
ffffffffc020470e:	00003517          	auipc	a0,0x3
ffffffffc0204712:	67250513          	addi	a0,a0,1650 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0204716:	af3fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc020471a:	00004697          	auipc	a3,0x4
ffffffffc020471e:	98668693          	addi	a3,a3,-1658 # ffffffffc02080a0 <default_pmm_manager+0x358>
ffffffffc0204722:	00002617          	auipc	a2,0x2
ffffffffc0204726:	57e60613          	addi	a2,a2,1406 # ffffffffc0206ca0 <commands+0x410>
ffffffffc020472a:	26d00593          	li	a1,621
ffffffffc020472e:	00003517          	auipc	a0,0x3
ffffffffc0204732:	65250513          	addi	a0,a0,1618 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0204736:	ad3fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p) == 1);
ffffffffc020473a:	00004697          	auipc	a3,0x4
ffffffffc020473e:	abe68693          	addi	a3,a3,-1346 # ffffffffc02081f8 <default_pmm_manager+0x4b0>
ffffffffc0204742:	00002617          	auipc	a2,0x2
ffffffffc0204746:	55e60613          	addi	a2,a2,1374 # ffffffffc0206ca0 <commands+0x410>
ffffffffc020474a:	29200593          	li	a1,658
ffffffffc020474e:	00003517          	auipc	a0,0x3
ffffffffc0204752:	63250513          	addi	a0,a0,1586 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0204756:	ab3fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc020475a:	00004697          	auipc	a3,0x4
ffffffffc020475e:	a6668693          	addi	a3,a3,-1434 # ffffffffc02081c0 <default_pmm_manager+0x478>
ffffffffc0204762:	00002617          	auipc	a2,0x2
ffffffffc0204766:	53e60613          	addi	a2,a2,1342 # ffffffffc0206ca0 <commands+0x410>
ffffffffc020476a:	29100593          	li	a1,657
ffffffffc020476e:	00003517          	auipc	a0,0x3
ffffffffc0204772:	61250513          	addi	a0,a0,1554 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0204776:	a93fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc020477a:	00004697          	auipc	a3,0x4
ffffffffc020477e:	a2e68693          	addi	a3,a3,-1490 # ffffffffc02081a8 <default_pmm_manager+0x460>
ffffffffc0204782:	00002617          	auipc	a2,0x2
ffffffffc0204786:	51e60613          	addi	a2,a2,1310 # ffffffffc0206ca0 <commands+0x410>
ffffffffc020478a:	28d00593          	li	a1,653
ffffffffc020478e:	00003517          	auipc	a0,0x3
ffffffffc0204792:	5f250513          	addi	a0,a0,1522 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0204796:	a73fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc020479a:	00004697          	auipc	a3,0x4
ffffffffc020479e:	97668693          	addi	a3,a3,-1674 # ffffffffc0208110 <default_pmm_manager+0x3c8>
ffffffffc02047a2:	00002617          	auipc	a2,0x2
ffffffffc02047a6:	4fe60613          	addi	a2,a2,1278 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02047aa:	27b00593          	li	a1,635
ffffffffc02047ae:	00003517          	auipc	a0,0x3
ffffffffc02047b2:	5d250513          	addi	a0,a0,1490 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc02047b6:	a53fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc02047ba:	00003697          	auipc	a3,0x3
ffffffffc02047be:	78e68693          	addi	a3,a3,1934 # ffffffffc0207f48 <default_pmm_manager+0x200>
ffffffffc02047c2:	00002617          	auipc	a2,0x2
ffffffffc02047c6:	4de60613          	addi	a2,a2,1246 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02047ca:	25500593          	li	a1,597
ffffffffc02047ce:	00003517          	auipc	a0,0x3
ffffffffc02047d2:	5b250513          	addi	a0,a0,1458 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc02047d6:	a33fb0ef          	jal	ra,ffffffffc0200208 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc02047da:	00003617          	auipc	a2,0x3
ffffffffc02047de:	c7660613          	addi	a2,a2,-906 # ffffffffc0207450 <commands+0xbc0>
ffffffffc02047e2:	25800593          	li	a1,600
ffffffffc02047e6:	00003517          	auipc	a0,0x3
ffffffffc02047ea:	59a50513          	addi	a0,a0,1434 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc02047ee:	a1bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc02047f2:	00003697          	auipc	a3,0x3
ffffffffc02047f6:	76e68693          	addi	a3,a3,1902 # ffffffffc0207f60 <default_pmm_manager+0x218>
ffffffffc02047fa:	00002617          	auipc	a2,0x2
ffffffffc02047fe:	4a660613          	addi	a2,a2,1190 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204802:	25600593          	li	a1,598
ffffffffc0204806:	00003517          	auipc	a0,0x3
ffffffffc020480a:	57a50513          	addi	a0,a0,1402 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc020480e:	9fbfb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0204812:	00003697          	auipc	a3,0x3
ffffffffc0204816:	7c668693          	addi	a3,a3,1990 # ffffffffc0207fd8 <default_pmm_manager+0x290>
ffffffffc020481a:	00002617          	auipc	a2,0x2
ffffffffc020481e:	48660613          	addi	a2,a2,1158 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204822:	25e00593          	li	a1,606
ffffffffc0204826:	00003517          	auipc	a0,0x3
ffffffffc020482a:	55a50513          	addi	a0,a0,1370 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc020482e:	9dbfb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0204832:	00004697          	auipc	a3,0x4
ffffffffc0204836:	a8668693          	addi	a3,a3,-1402 # ffffffffc02082b8 <default_pmm_manager+0x570>
ffffffffc020483a:	00002617          	auipc	a2,0x2
ffffffffc020483e:	46660613          	addi	a2,a2,1126 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204842:	29b00593          	li	a1,667
ffffffffc0204846:	00003517          	auipc	a0,0x3
ffffffffc020484a:	53a50513          	addi	a0,a0,1338 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc020484e:	9bbfb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0204852:	00004697          	auipc	a3,0x4
ffffffffc0204856:	a2e68693          	addi	a3,a3,-1490 # ffffffffc0208280 <default_pmm_manager+0x538>
ffffffffc020485a:	00002617          	auipc	a2,0x2
ffffffffc020485e:	44660613          	addi	a2,a2,1094 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204862:	29800593          	li	a1,664
ffffffffc0204866:	00003517          	auipc	a0,0x3
ffffffffc020486a:	51a50513          	addi	a0,a0,1306 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc020486e:	99bfb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0204872:	00004697          	auipc	a3,0x4
ffffffffc0204876:	9de68693          	addi	a3,a3,-1570 # ffffffffc0208250 <default_pmm_manager+0x508>
ffffffffc020487a:	00002617          	auipc	a2,0x2
ffffffffc020487e:	42660613          	addi	a2,a2,1062 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204882:	29400593          	li	a1,660
ffffffffc0204886:	00003517          	auipc	a0,0x3
ffffffffc020488a:	4fa50513          	addi	a0,a0,1274 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc020488e:	97bfb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204892 <copy_range>:
               bool share) {
ffffffffc0204892:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0204894:	00d667b3          	or	a5,a2,a3
               bool share) {
ffffffffc0204898:	f486                	sd	ra,104(sp)
ffffffffc020489a:	f0a2                	sd	s0,96(sp)
ffffffffc020489c:	eca6                	sd	s1,88(sp)
ffffffffc020489e:	e8ca                	sd	s2,80(sp)
ffffffffc02048a0:	e4ce                	sd	s3,72(sp)
ffffffffc02048a2:	e0d2                	sd	s4,64(sp)
ffffffffc02048a4:	fc56                	sd	s5,56(sp)
ffffffffc02048a6:	f85a                	sd	s6,48(sp)
ffffffffc02048a8:	f45e                	sd	s7,40(sp)
ffffffffc02048aa:	f062                	sd	s8,32(sp)
ffffffffc02048ac:	ec66                	sd	s9,24(sp)
ffffffffc02048ae:	e86a                	sd	s10,16(sp)
ffffffffc02048b0:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02048b2:	17d2                	slli	a5,a5,0x34
ffffffffc02048b4:	1e079763          	bnez	a5,ffffffffc0204aa2 <copy_range+0x210>
    assert(USER_ACCESS(start, end));
ffffffffc02048b8:	002007b7          	lui	a5,0x200
ffffffffc02048bc:	8432                	mv	s0,a2
ffffffffc02048be:	16f66a63          	bltu	a2,a5,ffffffffc0204a32 <copy_range+0x1a0>
ffffffffc02048c2:	8936                	mv	s2,a3
ffffffffc02048c4:	16d67763          	bgeu	a2,a3,ffffffffc0204a32 <copy_range+0x1a0>
ffffffffc02048c8:	4785                	li	a5,1
ffffffffc02048ca:	07fe                	slli	a5,a5,0x1f
ffffffffc02048cc:	16d7e363          	bltu	a5,a3,ffffffffc0204a32 <copy_range+0x1a0>
ffffffffc02048d0:	5b7d                	li	s6,-1
ffffffffc02048d2:	8aaa                	mv	s5,a0
ffffffffc02048d4:	89ae                	mv	s3,a1
        start += PGSIZE;
ffffffffc02048d6:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc02048d8:	000aec97          	auipc	s9,0xae
ffffffffc02048dc:	128c8c93          	addi	s9,s9,296 # ffffffffc02b2a00 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02048e0:	000aec17          	auipc	s8,0xae
ffffffffc02048e4:	128c0c13          	addi	s8,s8,296 # ffffffffc02b2a08 <pages>
    return page - pages + nbase;
ffffffffc02048e8:	00080bb7          	lui	s7,0x80
    return KADDR(page2pa(page));
ffffffffc02048ec:	00cb5b13          	srli	s6,s6,0xc
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc02048f0:	4601                	li	a2,0
ffffffffc02048f2:	85a2                	mv	a1,s0
ffffffffc02048f4:	854e                	mv	a0,s3
ffffffffc02048f6:	c73fe0ef          	jal	ra,ffffffffc0203568 <get_pte>
ffffffffc02048fa:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc02048fc:	c175                	beqz	a0,ffffffffc02049e0 <copy_range+0x14e>
        if (*ptep & PTE_V) {
ffffffffc02048fe:	611c                	ld	a5,0(a0)
ffffffffc0204900:	8b85                	andi	a5,a5,1
ffffffffc0204902:	e785                	bnez	a5,ffffffffc020492a <copy_range+0x98>
        start += PGSIZE;
ffffffffc0204904:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);  // 遍历整个地址范围
ffffffffc0204906:	ff2465e3          	bltu	s0,s2,ffffffffc02048f0 <copy_range+0x5e>
    return 0;  // 返回成功
ffffffffc020490a:	4501                	li	a0,0
}
ffffffffc020490c:	70a6                	ld	ra,104(sp)
ffffffffc020490e:	7406                	ld	s0,96(sp)
ffffffffc0204910:	64e6                	ld	s1,88(sp)
ffffffffc0204912:	6946                	ld	s2,80(sp)
ffffffffc0204914:	69a6                	ld	s3,72(sp)
ffffffffc0204916:	6a06                	ld	s4,64(sp)
ffffffffc0204918:	7ae2                	ld	s5,56(sp)
ffffffffc020491a:	7b42                	ld	s6,48(sp)
ffffffffc020491c:	7ba2                	ld	s7,40(sp)
ffffffffc020491e:	7c02                	ld	s8,32(sp)
ffffffffc0204920:	6ce2                	ld	s9,24(sp)
ffffffffc0204922:	6d42                	ld	s10,16(sp)
ffffffffc0204924:	6da2                	ld	s11,8(sp)
ffffffffc0204926:	6165                	addi	sp,sp,112
ffffffffc0204928:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL) {
ffffffffc020492a:	4605                	li	a2,1
ffffffffc020492c:	85a2                	mv	a1,s0
ffffffffc020492e:	8556                	mv	a0,s5
ffffffffc0204930:	c39fe0ef          	jal	ra,ffffffffc0203568 <get_pte>
ffffffffc0204934:	c161                	beqz	a0,ffffffffc02049f4 <copy_range+0x162>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0204936:	609c                	ld	a5,0(s1)
    if (!(pte & PTE_V)) {
ffffffffc0204938:	0017f713          	andi	a4,a5,1
ffffffffc020493c:	01f7f493          	andi	s1,a5,31
ffffffffc0204940:	14070563          	beqz	a4,ffffffffc0204a8a <copy_range+0x1f8>
    if (PPN(pa) >= npage) {
ffffffffc0204944:	000cb683          	ld	a3,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0204948:	078a                	slli	a5,a5,0x2
ffffffffc020494a:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020494e:	12d77263          	bgeu	a4,a3,ffffffffc0204a72 <copy_range+0x1e0>
    return &pages[PPN(pa) - nbase];
ffffffffc0204952:	000c3783          	ld	a5,0(s8)
ffffffffc0204956:	fff806b7          	lui	a3,0xfff80
ffffffffc020495a:	9736                	add	a4,a4,a3
ffffffffc020495c:	071a                	slli	a4,a4,0x6
            struct Page *npage = alloc_page();
ffffffffc020495e:	4505                	li	a0,1
ffffffffc0204960:	00e78db3          	add	s11,a5,a4
ffffffffc0204964:	af9fe0ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0204968:	8d2a                	mv	s10,a0
            assert(page != NULL);  // 确保源页面有效
ffffffffc020496a:	0a0d8463          	beqz	s11,ffffffffc0204a12 <copy_range+0x180>
            assert(npage != NULL); // 确保为目标进程分配的页面有效
ffffffffc020496e:	c175                	beqz	a0,ffffffffc0204a52 <copy_range+0x1c0>
    return page - pages + nbase;
ffffffffc0204970:	000c3703          	ld	a4,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204974:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0204978:	40ed86b3          	sub	a3,s11,a4
ffffffffc020497c:	8699                	srai	a3,a3,0x6
ffffffffc020497e:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204980:	0166f7b3          	and	a5,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0204984:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204986:	06c7fa63          	bgeu	a5,a2,ffffffffc02049fa <copy_range+0x168>
    return page - pages + nbase;
ffffffffc020498a:	40e507b3          	sub	a5,a0,a4
    return KADDR(page2pa(page));
ffffffffc020498e:	000ae717          	auipc	a4,0xae
ffffffffc0204992:	08a70713          	addi	a4,a4,138 # ffffffffc02b2a18 <va_pa_offset>
ffffffffc0204996:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc0204998:	8799                	srai	a5,a5,0x6
ffffffffc020499a:	97de                	add	a5,a5,s7
    return KADDR(page2pa(page));
ffffffffc020499c:	0167f733          	and	a4,a5,s6
ffffffffc02049a0:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc02049a4:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02049a6:	04c77963          	bgeu	a4,a2,ffffffffc02049f8 <copy_range+0x166>
            memcpy(dst, src, PGSIZE);
ffffffffc02049aa:	6605                	lui	a2,0x1
ffffffffc02049ac:	953e                	add	a0,a0,a5
ffffffffc02049ae:	01f010ef          	jal	ra,ffffffffc02061cc <memcpy>
            ret = page_insert(to, npage, start, perm);
ffffffffc02049b2:	86a6                	mv	a3,s1
ffffffffc02049b4:	8622                	mv	a2,s0
ffffffffc02049b6:	85ea                	mv	a1,s10
ffffffffc02049b8:	8556                	mv	a0,s5
ffffffffc02049ba:	a48ff0ef          	jal	ra,ffffffffc0203c02 <page_insert>
            assert(ret == 0);
ffffffffc02049be:	d139                	beqz	a0,ffffffffc0204904 <copy_range+0x72>
ffffffffc02049c0:	00004697          	auipc	a3,0x4
ffffffffc02049c4:	96068693          	addi	a3,a3,-1696 # ffffffffc0208320 <default_pmm_manager+0x5d8>
ffffffffc02049c8:	00002617          	auipc	a2,0x2
ffffffffc02049cc:	2d860613          	addi	a2,a2,728 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02049d0:	1e900593          	li	a1,489
ffffffffc02049d4:	00003517          	auipc	a0,0x3
ffffffffc02049d8:	3ac50513          	addi	a0,a0,940 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc02049dc:	82dfb0ef          	jal	ra,ffffffffc0200208 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02049e0:	00200637          	lui	a2,0x200
ffffffffc02049e4:	9432                	add	s0,s0,a2
ffffffffc02049e6:	ffe00637          	lui	a2,0xffe00
ffffffffc02049ea:	8c71                	and	s0,s0,a2
    } while (start != 0 && start < end);  // 遍历整个地址范围
ffffffffc02049ec:	dc19                	beqz	s0,ffffffffc020490a <copy_range+0x78>
ffffffffc02049ee:	f12461e3          	bltu	s0,s2,ffffffffc02048f0 <copy_range+0x5e>
ffffffffc02049f2:	bf21                	j	ffffffffc020490a <copy_range+0x78>
                return -E_NO_MEM;
ffffffffc02049f4:	5571                	li	a0,-4
ffffffffc02049f6:	bf19                	j	ffffffffc020490c <copy_range+0x7a>
ffffffffc02049f8:	86be                	mv	a3,a5
ffffffffc02049fa:	00003617          	auipc	a2,0x3
ffffffffc02049fe:	a5660613          	addi	a2,a2,-1450 # ffffffffc0207450 <commands+0xbc0>
ffffffffc0204a02:	06a00593          	li	a1,106
ffffffffc0204a06:	00003517          	auipc	a0,0x3
ffffffffc0204a0a:	a3a50513          	addi	a0,a0,-1478 # ffffffffc0207440 <commands+0xbb0>
ffffffffc0204a0e:	ffafb0ef          	jal	ra,ffffffffc0200208 <__panic>
            assert(page != NULL);  // 确保源页面有效
ffffffffc0204a12:	00004697          	auipc	a3,0x4
ffffffffc0204a16:	8ee68693          	addi	a3,a3,-1810 # ffffffffc0208300 <default_pmm_manager+0x5b8>
ffffffffc0204a1a:	00002617          	auipc	a2,0x2
ffffffffc0204a1e:	28660613          	addi	a2,a2,646 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204a22:	1c900593          	li	a1,457
ffffffffc0204a26:	00003517          	auipc	a0,0x3
ffffffffc0204a2a:	35a50513          	addi	a0,a0,858 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0204a2e:	fdafb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc0204a32:	00003697          	auipc	a3,0x3
ffffffffc0204a36:	38e68693          	addi	a3,a3,910 # ffffffffc0207dc0 <default_pmm_manager+0x78>
ffffffffc0204a3a:	00002617          	auipc	a2,0x2
ffffffffc0204a3e:	26660613          	addi	a2,a2,614 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204a42:	1ad00593          	li	a1,429
ffffffffc0204a46:	00003517          	auipc	a0,0x3
ffffffffc0204a4a:	33a50513          	addi	a0,a0,826 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0204a4e:	fbafb0ef          	jal	ra,ffffffffc0200208 <__panic>
            assert(npage != NULL); // 确保为目标进程分配的页面有效
ffffffffc0204a52:	00004697          	auipc	a3,0x4
ffffffffc0204a56:	8be68693          	addi	a3,a3,-1858 # ffffffffc0208310 <default_pmm_manager+0x5c8>
ffffffffc0204a5a:	00002617          	auipc	a2,0x2
ffffffffc0204a5e:	24660613          	addi	a2,a2,582 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204a62:	1ca00593          	li	a1,458
ffffffffc0204a66:	00003517          	auipc	a0,0x3
ffffffffc0204a6a:	31a50513          	addi	a0,a0,794 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0204a6e:	f9afb0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204a72:	00003617          	auipc	a2,0x3
ffffffffc0204a76:	9ae60613          	addi	a2,a2,-1618 # ffffffffc0207420 <commands+0xb90>
ffffffffc0204a7a:	06300593          	li	a1,99
ffffffffc0204a7e:	00003517          	auipc	a0,0x3
ffffffffc0204a82:	9c250513          	addi	a0,a0,-1598 # ffffffffc0207440 <commands+0xbb0>
ffffffffc0204a86:	f82fb0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0204a8a:	00003617          	auipc	a2,0x3
ffffffffc0204a8e:	da660613          	addi	a2,a2,-602 # ffffffffc0207830 <commands+0xfa0>
ffffffffc0204a92:	07500593          	li	a1,117
ffffffffc0204a96:	00003517          	auipc	a0,0x3
ffffffffc0204a9a:	9aa50513          	addi	a0,a0,-1622 # ffffffffc0207440 <commands+0xbb0>
ffffffffc0204a9e:	f6afb0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0204aa2:	00003697          	auipc	a3,0x3
ffffffffc0204aa6:	2ee68693          	addi	a3,a3,750 # ffffffffc0207d90 <default_pmm_manager+0x48>
ffffffffc0204aaa:	00002617          	auipc	a2,0x2
ffffffffc0204aae:	1f660613          	addi	a2,a2,502 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204ab2:	1aa00593          	li	a1,426
ffffffffc0204ab6:	00003517          	auipc	a0,0x3
ffffffffc0204aba:	2ca50513          	addi	a0,a0,714 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0204abe:	f4afb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204ac2 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0204ac2:	12058073          	sfence.vma	a1
}
ffffffffc0204ac6:	8082                	ret

ffffffffc0204ac8 <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0204ac8:	7179                	addi	sp,sp,-48
ffffffffc0204aca:	e84a                	sd	s2,16(sp)
ffffffffc0204acc:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc0204ace:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0204ad0:	f022                	sd	s0,32(sp)
ffffffffc0204ad2:	ec26                	sd	s1,24(sp)
ffffffffc0204ad4:	e44e                	sd	s3,8(sp)
ffffffffc0204ad6:	f406                	sd	ra,40(sp)
ffffffffc0204ad8:	84ae                	mv	s1,a1
ffffffffc0204ada:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc0204adc:	981fe0ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0204ae0:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0204ae2:	cd05                	beqz	a0,ffffffffc0204b1a <pgdir_alloc_page+0x52>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0204ae4:	85aa                	mv	a1,a0
ffffffffc0204ae6:	86ce                	mv	a3,s3
ffffffffc0204ae8:	8626                	mv	a2,s1
ffffffffc0204aea:	854a                	mv	a0,s2
ffffffffc0204aec:	916ff0ef          	jal	ra,ffffffffc0203c02 <page_insert>
ffffffffc0204af0:	ed0d                	bnez	a0,ffffffffc0204b2a <pgdir_alloc_page+0x62>
        if (swap_init_ok) {
ffffffffc0204af2:	000ae797          	auipc	a5,0xae
ffffffffc0204af6:	ef67a783          	lw	a5,-266(a5) # ffffffffc02b29e8 <swap_init_ok>
ffffffffc0204afa:	c385                	beqz	a5,ffffffffc0204b1a <pgdir_alloc_page+0x52>
            if (check_mm_struct != NULL) {
ffffffffc0204afc:	000ae517          	auipc	a0,0xae
ffffffffc0204b00:	ec453503          	ld	a0,-316(a0) # ffffffffc02b29c0 <check_mm_struct>
ffffffffc0204b04:	c919                	beqz	a0,ffffffffc0204b1a <pgdir_alloc_page+0x52>
                swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0204b06:	4681                	li	a3,0
ffffffffc0204b08:	8622                	mv	a2,s0
ffffffffc0204b0a:	85a6                	mv	a1,s1
ffffffffc0204b0c:	cd1fd0ef          	jal	ra,ffffffffc02027dc <swap_map_swappable>
                assert(page_ref(page) == 1);
ffffffffc0204b10:	4018                	lw	a4,0(s0)
                page->pra_vaddr = la;
ffffffffc0204b12:	fc04                	sd	s1,56(s0)
                assert(page_ref(page) == 1);
ffffffffc0204b14:	4785                	li	a5,1
ffffffffc0204b16:	04f71663          	bne	a4,a5,ffffffffc0204b62 <pgdir_alloc_page+0x9a>
}
ffffffffc0204b1a:	70a2                	ld	ra,40(sp)
ffffffffc0204b1c:	8522                	mv	a0,s0
ffffffffc0204b1e:	7402                	ld	s0,32(sp)
ffffffffc0204b20:	64e2                	ld	s1,24(sp)
ffffffffc0204b22:	6942                	ld	s2,16(sp)
ffffffffc0204b24:	69a2                	ld	s3,8(sp)
ffffffffc0204b26:	6145                	addi	sp,sp,48
ffffffffc0204b28:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204b2a:	100027f3          	csrr	a5,sstatus
ffffffffc0204b2e:	8b89                	andi	a5,a5,2
ffffffffc0204b30:	eb99                	bnez	a5,ffffffffc0204b46 <pgdir_alloc_page+0x7e>
        pmm_manager->free_pages(base, n);
ffffffffc0204b32:	000ae797          	auipc	a5,0xae
ffffffffc0204b36:	ede7b783          	ld	a5,-290(a5) # ffffffffc02b2a10 <pmm_manager>
ffffffffc0204b3a:	739c                	ld	a5,32(a5)
ffffffffc0204b3c:	8522                	mv	a0,s0
ffffffffc0204b3e:	4585                	li	a1,1
ffffffffc0204b40:	9782                	jalr	a5
            return NULL;
ffffffffc0204b42:	4401                	li	s0,0
ffffffffc0204b44:	bfd9                	j	ffffffffc0204b1a <pgdir_alloc_page+0x52>
        intr_disable();
ffffffffc0204b46:	b03fb0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0204b4a:	000ae797          	auipc	a5,0xae
ffffffffc0204b4e:	ec67b783          	ld	a5,-314(a5) # ffffffffc02b2a10 <pmm_manager>
ffffffffc0204b52:	739c                	ld	a5,32(a5)
ffffffffc0204b54:	8522                	mv	a0,s0
ffffffffc0204b56:	4585                	li	a1,1
ffffffffc0204b58:	9782                	jalr	a5
            return NULL;
ffffffffc0204b5a:	4401                	li	s0,0
        intr_enable();
ffffffffc0204b5c:	ae7fb0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0204b60:	bf6d                	j	ffffffffc0204b1a <pgdir_alloc_page+0x52>
                assert(page_ref(page) == 1);
ffffffffc0204b62:	00003697          	auipc	a3,0x3
ffffffffc0204b66:	7ce68693          	addi	a3,a3,1998 # ffffffffc0208330 <default_pmm_manager+0x5e8>
ffffffffc0204b6a:	00002617          	auipc	a2,0x2
ffffffffc0204b6e:	13660613          	addi	a2,a2,310 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0204b72:	22c00593          	li	a1,556
ffffffffc0204b76:	00003517          	auipc	a0,0x3
ffffffffc0204b7a:	20a50513          	addi	a0,a0,522 # ffffffffc0207d80 <default_pmm_manager+0x38>
ffffffffc0204b7e:	e8afb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204b82 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0204b82:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204b84:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0204b86:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204b88:	9a1fb0ef          	jal	ra,ffffffffc0200528 <ide_device_valid>
ffffffffc0204b8c:	cd01                	beqz	a0,ffffffffc0204ba4 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204b8e:	4505                	li	a0,1
ffffffffc0204b90:	99ffb0ef          	jal	ra,ffffffffc020052e <ide_device_size>
}
ffffffffc0204b94:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204b96:	810d                	srli	a0,a0,0x3
ffffffffc0204b98:	000ae797          	auipc	a5,0xae
ffffffffc0204b9c:	e4a7b023          	sd	a0,-448(a5) # ffffffffc02b29d8 <max_swap_offset>
}
ffffffffc0204ba0:	0141                	addi	sp,sp,16
ffffffffc0204ba2:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0204ba4:	00003617          	auipc	a2,0x3
ffffffffc0204ba8:	7a460613          	addi	a2,a2,1956 # ffffffffc0208348 <default_pmm_manager+0x600>
ffffffffc0204bac:	45b5                	li	a1,13
ffffffffc0204bae:	00003517          	auipc	a0,0x3
ffffffffc0204bb2:	7ba50513          	addi	a0,a0,1978 # ffffffffc0208368 <default_pmm_manager+0x620>
ffffffffc0204bb6:	e52fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204bba <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0204bba:	1141                	addi	sp,sp,-16
ffffffffc0204bbc:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204bbe:	00855793          	srli	a5,a0,0x8
ffffffffc0204bc2:	cbb1                	beqz	a5,ffffffffc0204c16 <swapfs_read+0x5c>
ffffffffc0204bc4:	000ae717          	auipc	a4,0xae
ffffffffc0204bc8:	e1473703          	ld	a4,-492(a4) # ffffffffc02b29d8 <max_swap_offset>
ffffffffc0204bcc:	04e7f563          	bgeu	a5,a4,ffffffffc0204c16 <swapfs_read+0x5c>
    return page - pages + nbase;
ffffffffc0204bd0:	000ae617          	auipc	a2,0xae
ffffffffc0204bd4:	e3863603          	ld	a2,-456(a2) # ffffffffc02b2a08 <pages>
ffffffffc0204bd8:	8d91                	sub	a1,a1,a2
ffffffffc0204bda:	4065d613          	srai	a2,a1,0x6
ffffffffc0204bde:	00004717          	auipc	a4,0x4
ffffffffc0204be2:	0e273703          	ld	a4,226(a4) # ffffffffc0208cc0 <nbase>
ffffffffc0204be6:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc0204be8:	00c61713          	slli	a4,a2,0xc
ffffffffc0204bec:	8331                	srli	a4,a4,0xc
ffffffffc0204bee:	000ae697          	auipc	a3,0xae
ffffffffc0204bf2:	e126b683          	ld	a3,-494(a3) # ffffffffc02b2a00 <npage>
ffffffffc0204bf6:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204bfa:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204bfc:	02d77963          	bgeu	a4,a3,ffffffffc0204c2e <swapfs_read+0x74>
}
ffffffffc0204c00:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c02:	000ae797          	auipc	a5,0xae
ffffffffc0204c06:	e167b783          	ld	a5,-490(a5) # ffffffffc02b2a18 <va_pa_offset>
ffffffffc0204c0a:	46a1                	li	a3,8
ffffffffc0204c0c:	963e                	add	a2,a2,a5
ffffffffc0204c0e:	4505                	li	a0,1
}
ffffffffc0204c10:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c12:	923fb06f          	j	ffffffffc0200534 <ide_read_secs>
ffffffffc0204c16:	86aa                	mv	a3,a0
ffffffffc0204c18:	00003617          	auipc	a2,0x3
ffffffffc0204c1c:	76860613          	addi	a2,a2,1896 # ffffffffc0208380 <default_pmm_manager+0x638>
ffffffffc0204c20:	45d1                	li	a1,20
ffffffffc0204c22:	00003517          	auipc	a0,0x3
ffffffffc0204c26:	74650513          	addi	a0,a0,1862 # ffffffffc0208368 <default_pmm_manager+0x620>
ffffffffc0204c2a:	ddefb0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0204c2e:	86b2                	mv	a3,a2
ffffffffc0204c30:	06a00593          	li	a1,106
ffffffffc0204c34:	00003617          	auipc	a2,0x3
ffffffffc0204c38:	81c60613          	addi	a2,a2,-2020 # ffffffffc0207450 <commands+0xbc0>
ffffffffc0204c3c:	00003517          	auipc	a0,0x3
ffffffffc0204c40:	80450513          	addi	a0,a0,-2044 # ffffffffc0207440 <commands+0xbb0>
ffffffffc0204c44:	dc4fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204c48 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0204c48:	1141                	addi	sp,sp,-16
ffffffffc0204c4a:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c4c:	00855793          	srli	a5,a0,0x8
ffffffffc0204c50:	cbb1                	beqz	a5,ffffffffc0204ca4 <swapfs_write+0x5c>
ffffffffc0204c52:	000ae717          	auipc	a4,0xae
ffffffffc0204c56:	d8673703          	ld	a4,-634(a4) # ffffffffc02b29d8 <max_swap_offset>
ffffffffc0204c5a:	04e7f563          	bgeu	a5,a4,ffffffffc0204ca4 <swapfs_write+0x5c>
    return page - pages + nbase;
ffffffffc0204c5e:	000ae617          	auipc	a2,0xae
ffffffffc0204c62:	daa63603          	ld	a2,-598(a2) # ffffffffc02b2a08 <pages>
ffffffffc0204c66:	8d91                	sub	a1,a1,a2
ffffffffc0204c68:	4065d613          	srai	a2,a1,0x6
ffffffffc0204c6c:	00004717          	auipc	a4,0x4
ffffffffc0204c70:	05473703          	ld	a4,84(a4) # ffffffffc0208cc0 <nbase>
ffffffffc0204c74:	963a                	add	a2,a2,a4
    return KADDR(page2pa(page));
ffffffffc0204c76:	00c61713          	slli	a4,a2,0xc
ffffffffc0204c7a:	8331                	srli	a4,a4,0xc
ffffffffc0204c7c:	000ae697          	auipc	a3,0xae
ffffffffc0204c80:	d846b683          	ld	a3,-636(a3) # ffffffffc02b2a00 <npage>
ffffffffc0204c84:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c88:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204c8a:	02d77963          	bgeu	a4,a3,ffffffffc0204cbc <swapfs_write+0x74>
}
ffffffffc0204c8e:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c90:	000ae797          	auipc	a5,0xae
ffffffffc0204c94:	d887b783          	ld	a5,-632(a5) # ffffffffc02b2a18 <va_pa_offset>
ffffffffc0204c98:	46a1                	li	a3,8
ffffffffc0204c9a:	963e                	add	a2,a2,a5
ffffffffc0204c9c:	4505                	li	a0,1
}
ffffffffc0204c9e:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204ca0:	8b9fb06f          	j	ffffffffc0200558 <ide_write_secs>
ffffffffc0204ca4:	86aa                	mv	a3,a0
ffffffffc0204ca6:	00003617          	auipc	a2,0x3
ffffffffc0204caa:	6da60613          	addi	a2,a2,1754 # ffffffffc0208380 <default_pmm_manager+0x638>
ffffffffc0204cae:	45e5                	li	a1,25
ffffffffc0204cb0:	00003517          	auipc	a0,0x3
ffffffffc0204cb4:	6b850513          	addi	a0,a0,1720 # ffffffffc0208368 <default_pmm_manager+0x620>
ffffffffc0204cb8:	d50fb0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0204cbc:	86b2                	mv	a3,a2
ffffffffc0204cbe:	06a00593          	li	a1,106
ffffffffc0204cc2:	00002617          	auipc	a2,0x2
ffffffffc0204cc6:	78e60613          	addi	a2,a2,1934 # ffffffffc0207450 <commands+0xbc0>
ffffffffc0204cca:	00002517          	auipc	a0,0x2
ffffffffc0204cce:	77650513          	addi	a0,a0,1910 # ffffffffc0207440 <commands+0xbb0>
ffffffffc0204cd2:	d36fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204cd6 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204cd6:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204cd8:	9402                	jalr	s0

	jal do_exit
ffffffffc0204cda:	6ac000ef          	jal	ra,ffffffffc0205386 <do_exit>

ffffffffc0204cde <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0204cde:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0204ce2:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0204ce6:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0204ce8:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0204cea:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0204cee:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0204cf2:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0204cf6:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0204cfa:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0204cfe:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0204d02:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0204d06:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0204d0a:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0204d0e:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0204d12:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0204d16:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0204d1a:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0204d1c:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0204d1e:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0204d22:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0204d26:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0204d2a:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0204d2e:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0204d32:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0204d36:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0204d3a:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0204d3e:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0204d42:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0204d46:	8082                	ret

ffffffffc0204d48 <alloc_proc>:
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
ffffffffc0204d48:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204d4a:	10800513          	li	a0,264
alloc_proc(void) {
ffffffffc0204d4e:	e022                	sd	s0,0(sp)
ffffffffc0204d50:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204d52:	976fd0ef          	jal	ra,ffffffffc0201ec8 <kmalloc>
ffffffffc0204d56:	842a                	mv	s0,a0
    if (proc != NULL) {
ffffffffc0204d58:	cd21                	beqz	a0,ffffffffc0204db0 <alloc_proc+0x68>
     /*
     * below fields(add in LAB5) in proc_struct need to be initialized  
     *       uint32_t wait_state;                        // waiting state
     *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
     */
        proc->state = PROC_UNINIT;
ffffffffc0204d5a:	57fd                	li	a5,-1
ffffffffc0204d5c:	1782                	slli	a5,a5,0x20
ffffffffc0204d5e:	e11c                	sd	a5,0(a0)
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0204d60:	07000613          	li	a2,112
ffffffffc0204d64:	4581                	li	a1,0
        proc->runs = 0;
ffffffffc0204d66:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;
ffffffffc0204d6a:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;
ffffffffc0204d6e:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc0204d72:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0204d76:	02053423          	sd	zero,40(a0)
        memset(&(proc->context), 0, sizeof(struct context));
ffffffffc0204d7a:	03050513          	addi	a0,a0,48
ffffffffc0204d7e:	43c010ef          	jal	ra,ffffffffc02061ba <memset>
        proc->tf = NULL;
        proc->cr3 = boot_cr3;
ffffffffc0204d82:	000ae797          	auipc	a5,0xae
ffffffffc0204d86:	c6e7b783          	ld	a5,-914(a5) # ffffffffc02b29f0 <boot_cr3>
        proc->tf = NULL;
ffffffffc0204d8a:	0a043023          	sd	zero,160(s0)
        proc->cr3 = boot_cr3;
ffffffffc0204d8e:	f45c                	sd	a5,168(s0)
        proc->flags = 0;
ffffffffc0204d90:	0a042823          	sw	zero,176(s0)
        memset(proc->name, 0, PROC_NAME_LEN);
ffffffffc0204d94:	463d                	li	a2,15
ffffffffc0204d96:	4581                	li	a1,0
ffffffffc0204d98:	0b440513          	addi	a0,s0,180
ffffffffc0204d9c:	41e010ef          	jal	ra,ffffffffc02061ba <memset>
        proc->wait_state = 0;
ffffffffc0204da0:	0e042623          	sw	zero,236(s0)
        proc->cptr = NULL;
ffffffffc0204da4:	0e043823          	sd	zero,240(s0)
        proc->optr = NULL;
ffffffffc0204da8:	10043023          	sd	zero,256(s0)
        proc->yptr = NULL;
ffffffffc0204dac:	0e043c23          	sd	zero,248(s0)
    }
    return proc;
}
ffffffffc0204db0:	60a2                	ld	ra,8(sp)
ffffffffc0204db2:	8522                	mv	a0,s0
ffffffffc0204db4:	6402                	ld	s0,0(sp)
ffffffffc0204db6:	0141                	addi	sp,sp,16
ffffffffc0204db8:	8082                	ret

ffffffffc0204dba <forkret>:
// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
ffffffffc0204dba:	000ae797          	auipc	a5,0xae
ffffffffc0204dbe:	c667b783          	ld	a5,-922(a5) # ffffffffc02b2a20 <current>
ffffffffc0204dc2:	73c8                	ld	a0,160(a5)
ffffffffc0204dc4:	fb3fb06f          	j	ffffffffc0200d76 <forkrets>

ffffffffc0204dc8 <user_main>:
// 如果执行失败，会触发 panic。
static int
user_main(void *arg) {
#ifdef TEST
    // 如果定义了 TEST，执行 TEST 程序
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204dc8:	000ae797          	auipc	a5,0xae
ffffffffc0204dcc:	c587b783          	ld	a5,-936(a5) # ffffffffc02b2a20 <current>
ffffffffc0204dd0:	43cc                	lw	a1,4(a5)
user_main(void *arg) {
ffffffffc0204dd2:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204dd4:	00003617          	auipc	a2,0x3
ffffffffc0204dd8:	5cc60613          	addi	a2,a2,1484 # ffffffffc02083a0 <default_pmm_manager+0x658>
ffffffffc0204ddc:	00003517          	auipc	a0,0x3
ffffffffc0204de0:	5d450513          	addi	a0,a0,1492 # ffffffffc02083b0 <default_pmm_manager+0x668>
user_main(void *arg) {
ffffffffc0204de4:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204de6:	ae6fb0ef          	jal	ra,ffffffffc02000cc <cprintf>
ffffffffc0204dea:	3fe06797          	auipc	a5,0x3fe06
ffffffffc0204dee:	b9e78793          	addi	a5,a5,-1122 # a988 <_binary_obj___user_forktest_out_size>
ffffffffc0204df2:	e43e                	sd	a5,8(sp)
ffffffffc0204df4:	00003517          	auipc	a0,0x3
ffffffffc0204df8:	5ac50513          	addi	a0,a0,1452 # ffffffffc02083a0 <default_pmm_manager+0x658>
ffffffffc0204dfc:	00098797          	auipc	a5,0x98
ffffffffc0204e00:	cfc78793          	addi	a5,a5,-772 # ffffffffc029caf8 <_binary_obj___user_forktest_out_start>
ffffffffc0204e04:	f03e                	sd	a5,32(sp)
ffffffffc0204e06:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);  // 存储返回值并获取程序名称的长度
ffffffffc0204e08:	e802                	sd	zero,16(sp)
ffffffffc0204e0a:	334010ef          	jal	ra,ffffffffc020613e <strlen>
ffffffffc0204e0e:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204e10:	4511                	li	a0,4
ffffffffc0204e12:	55a2                	lw	a1,40(sp)
ffffffffc0204e14:	4662                	lw	a2,24(sp)
ffffffffc0204e16:	5682                	lw	a3,32(sp)
ffffffffc0204e18:	4722                	lw	a4,8(sp)
ffffffffc0204e1a:	48a9                	li	a7,10
ffffffffc0204e1c:	9002                	ebreak
ffffffffc0204e1e:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204e20:	65c2                	ld	a1,16(sp)
ffffffffc0204e22:	00003517          	auipc	a0,0x3
ffffffffc0204e26:	5b650513          	addi	a0,a0,1462 # ffffffffc02083d8 <default_pmm_manager+0x690>
ffffffffc0204e2a:	aa2fb0ef          	jal	ra,ffffffffc02000cc <cprintf>
#else
    // 否则执行名为 "exit" 的程序
    KERNEL_EXECVE(exit);
#endif
    // 如果 execve 执行失败，触发 panic
    panic("user_main execve failed.\n");
ffffffffc0204e2e:	00003617          	auipc	a2,0x3
ffffffffc0204e32:	5ba60613          	addi	a2,a2,1466 # ffffffffc02083e8 <default_pmm_manager+0x6a0>
ffffffffc0204e36:	3d600593          	li	a1,982
ffffffffc0204e3a:	00003517          	auipc	a0,0x3
ffffffffc0204e3e:	5ce50513          	addi	a0,a0,1486 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc0204e42:	bc6fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204e46 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0204e46:	6d14                	ld	a3,24(a0)
put_pgdir(struct mm_struct *mm) {
ffffffffc0204e48:	1141                	addi	sp,sp,-16
ffffffffc0204e4a:	e406                	sd	ra,8(sp)
ffffffffc0204e4c:	c02007b7          	lui	a5,0xc0200
ffffffffc0204e50:	02f6ee63          	bltu	a3,a5,ffffffffc0204e8c <put_pgdir+0x46>
ffffffffc0204e54:	000ae517          	auipc	a0,0xae
ffffffffc0204e58:	bc453503          	ld	a0,-1084(a0) # ffffffffc02b2a18 <va_pa_offset>
ffffffffc0204e5c:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage) {
ffffffffc0204e5e:	82b1                	srli	a3,a3,0xc
ffffffffc0204e60:	000ae797          	auipc	a5,0xae
ffffffffc0204e64:	ba07b783          	ld	a5,-1120(a5) # ffffffffc02b2a00 <npage>
ffffffffc0204e68:	02f6fe63          	bgeu	a3,a5,ffffffffc0204ea4 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0204e6c:	00004517          	auipc	a0,0x4
ffffffffc0204e70:	e5453503          	ld	a0,-428(a0) # ffffffffc0208cc0 <nbase>
}
ffffffffc0204e74:	60a2                	ld	ra,8(sp)
ffffffffc0204e76:	8e89                	sub	a3,a3,a0
ffffffffc0204e78:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0204e7a:	000ae517          	auipc	a0,0xae
ffffffffc0204e7e:	b8e53503          	ld	a0,-1138(a0) # ffffffffc02b2a08 <pages>
ffffffffc0204e82:	4585                	li	a1,1
ffffffffc0204e84:	9536                	add	a0,a0,a3
}
ffffffffc0204e86:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0204e88:	e66fe06f          	j	ffffffffc02034ee <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0204e8c:	00002617          	auipc	a2,0x2
ffffffffc0204e90:	76c60613          	addi	a2,a2,1900 # ffffffffc02075f8 <commands+0xd68>
ffffffffc0204e94:	06f00593          	li	a1,111
ffffffffc0204e98:	00002517          	auipc	a0,0x2
ffffffffc0204e9c:	5a850513          	addi	a0,a0,1448 # ffffffffc0207440 <commands+0xbb0>
ffffffffc0204ea0:	b68fb0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204ea4:	00002617          	auipc	a2,0x2
ffffffffc0204ea8:	57c60613          	addi	a2,a2,1404 # ffffffffc0207420 <commands+0xb90>
ffffffffc0204eac:	06300593          	li	a1,99
ffffffffc0204eb0:	00002517          	auipc	a0,0x2
ffffffffc0204eb4:	59050513          	addi	a0,a0,1424 # ffffffffc0207440 <commands+0xbb0>
ffffffffc0204eb8:	b50fb0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0204ebc <proc_run>:
proc_run(struct proc_struct *proc) {
ffffffffc0204ebc:	7179                	addi	sp,sp,-48
ffffffffc0204ebe:	ec4a                	sd	s2,24(sp)
    if (proc != current) {
ffffffffc0204ec0:	000ae917          	auipc	s2,0xae
ffffffffc0204ec4:	b6090913          	addi	s2,s2,-1184 # ffffffffc02b2a20 <current>
proc_run(struct proc_struct *proc) {
ffffffffc0204ec8:	f026                	sd	s1,32(sp)
    if (proc != current) {
ffffffffc0204eca:	00093483          	ld	s1,0(s2)
proc_run(struct proc_struct *proc) {
ffffffffc0204ece:	f406                	sd	ra,40(sp)
ffffffffc0204ed0:	e84e                	sd	s3,16(sp)
    if (proc != current) {
ffffffffc0204ed2:	02a48863          	beq	s1,a0,ffffffffc0204f02 <proc_run+0x46>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204ed6:	100027f3          	csrr	a5,sstatus
ffffffffc0204eda:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204edc:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204ede:	ef9d                	bnez	a5,ffffffffc0204f1c <proc_run+0x60>

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned long cr3) {
    write_csr(satp, 0x8000000000000000 | (cr3 >> RISCV_PGSHIFT));
ffffffffc0204ee0:	755c                	ld	a5,168(a0)
ffffffffc0204ee2:	577d                	li	a4,-1
ffffffffc0204ee4:	177e                	slli	a4,a4,0x3f
ffffffffc0204ee6:	83b1                	srli	a5,a5,0xc
            current = proc;
ffffffffc0204ee8:	00a93023          	sd	a0,0(s2)
ffffffffc0204eec:	8fd9                	or	a5,a5,a4
ffffffffc0204eee:	18079073          	csrw	satp,a5
            switch_to(&(prev->context), &(next->context));
ffffffffc0204ef2:	03050593          	addi	a1,a0,48
ffffffffc0204ef6:	03048513          	addi	a0,s1,48
ffffffffc0204efa:	de5ff0ef          	jal	ra,ffffffffc0204cde <switch_to>
    if (flag) {
ffffffffc0204efe:	00099863          	bnez	s3,ffffffffc0204f0e <proc_run+0x52>
}
ffffffffc0204f02:	70a2                	ld	ra,40(sp)
ffffffffc0204f04:	7482                	ld	s1,32(sp)
ffffffffc0204f06:	6962                	ld	s2,24(sp)
ffffffffc0204f08:	69c2                	ld	s3,16(sp)
ffffffffc0204f0a:	6145                	addi	sp,sp,48
ffffffffc0204f0c:	8082                	ret
ffffffffc0204f0e:	70a2                	ld	ra,40(sp)
ffffffffc0204f10:	7482                	ld	s1,32(sp)
ffffffffc0204f12:	6962                	ld	s2,24(sp)
ffffffffc0204f14:	69c2                	ld	s3,16(sp)
ffffffffc0204f16:	6145                	addi	sp,sp,48
        intr_enable();
ffffffffc0204f18:	f2afb06f          	j	ffffffffc0200642 <intr_enable>
ffffffffc0204f1c:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0204f1e:	f2afb0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc0204f22:	6522                	ld	a0,8(sp)
ffffffffc0204f24:	4985                	li	s3,1
ffffffffc0204f26:	bf6d                	j	ffffffffc0204ee0 <proc_run+0x24>

ffffffffc0204f28 <do_fork>:
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0204f28:	7119                	addi	sp,sp,-128
ffffffffc0204f2a:	f0ca                	sd	s2,96(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0204f2c:	000ae917          	auipc	s2,0xae
ffffffffc0204f30:	b0c90913          	addi	s2,s2,-1268 # ffffffffc02b2a38 <nr_process>
ffffffffc0204f34:	00092703          	lw	a4,0(s2)
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0204f38:	fc86                	sd	ra,120(sp)
ffffffffc0204f3a:	f8a2                	sd	s0,112(sp)
ffffffffc0204f3c:	f4a6                	sd	s1,104(sp)
ffffffffc0204f3e:	ecce                	sd	s3,88(sp)
ffffffffc0204f40:	e8d2                	sd	s4,80(sp)
ffffffffc0204f42:	e4d6                	sd	s5,72(sp)
ffffffffc0204f44:	e0da                	sd	s6,64(sp)
ffffffffc0204f46:	fc5e                	sd	s7,56(sp)
ffffffffc0204f48:	f862                	sd	s8,48(sp)
ffffffffc0204f4a:	f466                	sd	s9,40(sp)
ffffffffc0204f4c:	f06a                	sd	s10,32(sp)
ffffffffc0204f4e:	ec6e                	sd	s11,24(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0204f50:	6785                	lui	a5,0x1
ffffffffc0204f52:	34f75063          	bge	a4,a5,ffffffffc0205292 <do_fork+0x36a>
ffffffffc0204f56:	8a2a                	mv	s4,a0
ffffffffc0204f58:	89ae                	mv	s3,a1
ffffffffc0204f5a:	8432                	mv	s0,a2
    if((proc = alloc_proc()) == NULL) {
ffffffffc0204f5c:	dedff0ef          	jal	ra,ffffffffc0204d48 <alloc_proc>
ffffffffc0204f60:	84aa                	mv	s1,a0
ffffffffc0204f62:	30050963          	beqz	a0,ffffffffc0205274 <do_fork+0x34c>
    proc->parent = current;
ffffffffc0204f66:	000aec17          	auipc	s8,0xae
ffffffffc0204f6a:	abac0c13          	addi	s8,s8,-1350 # ffffffffc02b2a20 <current>
ffffffffc0204f6e:	000c3783          	ld	a5,0(s8)
    assert(current->wait_state == 0);  // 确保当前进程的 wait_state 为 0
ffffffffc0204f72:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8ae4>
    proc->parent = current;
ffffffffc0204f76:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0);  // 确保当前进程的 wait_state 为 0
ffffffffc0204f78:	32071263          	bnez	a4,ffffffffc020529c <do_fork+0x374>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204f7c:	4509                	li	a0,2
ffffffffc0204f7e:	cdefe0ef          	jal	ra,ffffffffc020345c <alloc_pages>
    if (page != NULL) {
ffffffffc0204f82:	2e050663          	beqz	a0,ffffffffc020526e <do_fork+0x346>
    return page - pages + nbase;
ffffffffc0204f86:	000aea97          	auipc	s5,0xae
ffffffffc0204f8a:	a82a8a93          	addi	s5,s5,-1406 # ffffffffc02b2a08 <pages>
ffffffffc0204f8e:	000ab683          	ld	a3,0(s5)
ffffffffc0204f92:	00004b17          	auipc	s6,0x4
ffffffffc0204f96:	d2eb0b13          	addi	s6,s6,-722 # ffffffffc0208cc0 <nbase>
ffffffffc0204f9a:	000b3783          	ld	a5,0(s6)
ffffffffc0204f9e:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0204fa2:	000aeb97          	auipc	s7,0xae
ffffffffc0204fa6:	a5eb8b93          	addi	s7,s7,-1442 # ffffffffc02b2a00 <npage>
    return page - pages + nbase;
ffffffffc0204faa:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204fac:	5dfd                	li	s11,-1
ffffffffc0204fae:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc0204fb2:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0204fb4:	00cddd93          	srli	s11,s11,0xc
ffffffffc0204fb8:	01b6f633          	and	a2,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc0204fbc:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204fbe:	2ee67f63          	bgeu	a2,a4,ffffffffc02052bc <do_fork+0x394>
    struct mm_struct *mm, *oldmm = current->mm;  // 获取当前进程的内存管理结构
ffffffffc0204fc2:	000c3603          	ld	a2,0(s8)
ffffffffc0204fc6:	000aec17          	auipc	s8,0xae
ffffffffc0204fca:	a52c0c13          	addi	s8,s8,-1454 # ffffffffc02b2a18 <va_pa_offset>
ffffffffc0204fce:	000c3703          	ld	a4,0(s8)
ffffffffc0204fd2:	02863d03          	ld	s10,40(a2)
ffffffffc0204fd6:	e43e                	sd	a5,8(sp)
ffffffffc0204fd8:	96ba                	add	a3,a3,a4
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0204fda:	e894                	sd	a3,16(s1)
    if (oldmm == NULL) {  // 如果当前进程没有内存管理结构，说明它是一个内核线程
ffffffffc0204fdc:	020d0863          	beqz	s10,ffffffffc020500c <do_fork+0xe4>
    if (clone_flags & CLONE_VM) {
ffffffffc0204fe0:	100a7a13          	andi	s4,s4,256
ffffffffc0204fe4:	1c0a0663          	beqz	s4,ffffffffc02051b0 <do_fork+0x288>
}

static inline int
mm_count_inc(struct mm_struct *mm) {
    mm->mm_count += 1;
ffffffffc0204fe8:	030d2703          	lw	a4,48(s10)
    proc->cr3 = PADDR(mm->pgdir);  // 设置新进程的页目录物理地址
ffffffffc0204fec:	018d3783          	ld	a5,24(s10)
ffffffffc0204ff0:	c02006b7          	lui	a3,0xc0200
ffffffffc0204ff4:	2705                	addiw	a4,a4,1
ffffffffc0204ff6:	02ed2823          	sw	a4,48(s10)
    proc->mm = mm;  // 将新内存管理结构赋值给新进程
ffffffffc0204ffa:	03a4b423          	sd	s10,40(s1)
    proc->cr3 = PADDR(mm->pgdir);  // 设置新进程的页目录物理地址
ffffffffc0204ffe:	2ed7e763          	bltu	a5,a3,ffffffffc02052ec <do_fork+0x3c4>
ffffffffc0205002:	000c3703          	ld	a4,0(s8)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0205006:	6894                	ld	a3,16(s1)
    proc->cr3 = PADDR(mm->pgdir);  // 设置新进程的页目录物理地址
ffffffffc0205008:	8f99                	sub	a5,a5,a4
ffffffffc020500a:	f4dc                	sd	a5,168(s1)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020500c:	6709                	lui	a4,0x2
ffffffffc020500e:	ee070713          	addi	a4,a4,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x7cf0>
ffffffffc0205012:	9736                	add	a4,a4,a3
    *(proc->tf) = *tf;
ffffffffc0205014:	8622                	mv	a2,s0
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0205016:	f0d8                	sd	a4,160(s1)
    *(proc->tf) = *tf;
ffffffffc0205018:	87ba                	mv	a5,a4
ffffffffc020501a:	12040313          	addi	t1,s0,288
ffffffffc020501e:	00063883          	ld	a7,0(a2)
ffffffffc0205022:	00863803          	ld	a6,8(a2)
ffffffffc0205026:	6a08                	ld	a0,16(a2)
ffffffffc0205028:	6e0c                	ld	a1,24(a2)
ffffffffc020502a:	0117b023          	sd	a7,0(a5)
ffffffffc020502e:	0107b423          	sd	a6,8(a5)
ffffffffc0205032:	eb88                	sd	a0,16(a5)
ffffffffc0205034:	ef8c                	sd	a1,24(a5)
ffffffffc0205036:	02060613          	addi	a2,a2,32
ffffffffc020503a:	02078793          	addi	a5,a5,32
ffffffffc020503e:	fe6610e3          	bne	a2,t1,ffffffffc020501e <do_fork+0xf6>
    proc->tf->gpr.a0 = 0;
ffffffffc0205042:	04073823          	sd	zero,80(a4)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf - 4 : esp;
ffffffffc0205046:	12098f63          	beqz	s3,ffffffffc0205184 <do_fork+0x25c>
ffffffffc020504a:	01373823          	sd	s3,16(a4)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020504e:	00000797          	auipc	a5,0x0
ffffffffc0205052:	d6c78793          	addi	a5,a5,-660 # ffffffffc0204dba <forkret>
ffffffffc0205056:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0205058:	fc98                	sd	a4,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020505a:	100027f3          	csrr	a5,sstatus
ffffffffc020505e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205060:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205062:	14079363          	bnez	a5,ffffffffc02051a8 <do_fork+0x280>
    if (++ last_pid >= MAX_PID) {
ffffffffc0205066:	000a2817          	auipc	a6,0xa2
ffffffffc020506a:	47280813          	addi	a6,a6,1138 # ffffffffc02a74d8 <last_pid.1>
ffffffffc020506e:	00082783          	lw	a5,0(a6)
ffffffffc0205072:	6709                	lui	a4,0x2
ffffffffc0205074:	0017851b          	addiw	a0,a5,1
ffffffffc0205078:	00a82023          	sw	a0,0(a6)
ffffffffc020507c:	08e55d63          	bge	a0,a4,ffffffffc0205116 <do_fork+0x1ee>
    if (last_pid >= next_safe) {
ffffffffc0205080:	000a2317          	auipc	t1,0xa2
ffffffffc0205084:	45c30313          	addi	t1,t1,1116 # ffffffffc02a74dc <next_safe.0>
ffffffffc0205088:	00032783          	lw	a5,0(t1)
ffffffffc020508c:	000ae417          	auipc	s0,0xae
ffffffffc0205090:	90c40413          	addi	s0,s0,-1780 # ffffffffc02b2998 <proc_list>
ffffffffc0205094:	08f55963          	bge	a0,a5,ffffffffc0205126 <do_fork+0x1fe>
        proc->pid = get_pid();  // 分配 PID
ffffffffc0205098:	c0c8                	sw	a0,4(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020509a:	45a9                	li	a1,10
ffffffffc020509c:	2501                	sext.w	a0,a0
ffffffffc020509e:	534010ef          	jal	ra,ffffffffc02065d2 <hash32>
ffffffffc02050a2:	02051793          	slli	a5,a0,0x20
ffffffffc02050a6:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02050aa:	000aa797          	auipc	a5,0xaa
ffffffffc02050ae:	8ee78793          	addi	a5,a5,-1810 # ffffffffc02ae998 <hash_list>
ffffffffc02050b2:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02050b4:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc02050b6:	7094                	ld	a3,32(s1)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02050b8:	0d848793          	addi	a5,s1,216
    prev->next = next->prev = elm;
ffffffffc02050bc:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02050be:	6410                	ld	a2,8(s0)
    prev->next = next->prev = elm;
ffffffffc02050c0:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc02050c2:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02050c4:	0c848793          	addi	a5,s1,200
    elm->next = next;
ffffffffc02050c8:	f0ec                	sd	a1,224(s1)
    elm->prev = prev;
ffffffffc02050ca:	ece8                	sd	a0,216(s1)
    prev->next = next->prev = elm;
ffffffffc02050cc:	e21c                	sd	a5,0(a2)
ffffffffc02050ce:	e41c                	sd	a5,8(s0)
    elm->next = next;
ffffffffc02050d0:	e8f0                	sd	a2,208(s1)
    elm->prev = prev;
ffffffffc02050d2:	e4e0                	sd	s0,200(s1)
    proc->yptr = NULL;
ffffffffc02050d4:	0e04bc23          	sd	zero,248(s1)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc02050d8:	10e4b023          	sd	a4,256(s1)
ffffffffc02050dc:	c311                	beqz	a4,ffffffffc02050e0 <do_fork+0x1b8>
        proc->optr->yptr = proc;
ffffffffc02050de:	ff64                	sd	s1,248(a4)
    nr_process ++;
ffffffffc02050e0:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc02050e4:	fae4                	sd	s1,240(a3)
    nr_process ++;
ffffffffc02050e6:	2785                	addiw	a5,a5,1
ffffffffc02050e8:	00f92023          	sw	a5,0(s2)
    if (flag) {
ffffffffc02050ec:	18099663          	bnez	s3,ffffffffc0205278 <do_fork+0x350>
    wakeup_proc(proc);
ffffffffc02050f0:	8526                	mv	a0,s1
ffffffffc02050f2:	661000ef          	jal	ra,ffffffffc0205f52 <wakeup_proc>
    ret = proc->pid;
ffffffffc02050f6:	40c8                	lw	a0,4(s1)
}
ffffffffc02050f8:	70e6                	ld	ra,120(sp)
ffffffffc02050fa:	7446                	ld	s0,112(sp)
ffffffffc02050fc:	74a6                	ld	s1,104(sp)
ffffffffc02050fe:	7906                	ld	s2,96(sp)
ffffffffc0205100:	69e6                	ld	s3,88(sp)
ffffffffc0205102:	6a46                	ld	s4,80(sp)
ffffffffc0205104:	6aa6                	ld	s5,72(sp)
ffffffffc0205106:	6b06                	ld	s6,64(sp)
ffffffffc0205108:	7be2                	ld	s7,56(sp)
ffffffffc020510a:	7c42                	ld	s8,48(sp)
ffffffffc020510c:	7ca2                	ld	s9,40(sp)
ffffffffc020510e:	7d02                	ld	s10,32(sp)
ffffffffc0205110:	6de2                	ld	s11,24(sp)
ffffffffc0205112:	6109                	addi	sp,sp,128
ffffffffc0205114:	8082                	ret
        last_pid = 1;
ffffffffc0205116:	4785                	li	a5,1
ffffffffc0205118:	00f82023          	sw	a5,0(a6)
        goto inside;
ffffffffc020511c:	4505                	li	a0,1
ffffffffc020511e:	000a2317          	auipc	t1,0xa2
ffffffffc0205122:	3be30313          	addi	t1,t1,958 # ffffffffc02a74dc <next_safe.0>
    return listelm->next;
ffffffffc0205126:	000ae417          	auipc	s0,0xae
ffffffffc020512a:	87240413          	addi	s0,s0,-1934 # ffffffffc02b2998 <proc_list>
ffffffffc020512e:	00843e03          	ld	t3,8(s0)
        next_safe = MAX_PID;
ffffffffc0205132:	6789                	lui	a5,0x2
ffffffffc0205134:	00f32023          	sw	a5,0(t1)
ffffffffc0205138:	86aa                	mv	a3,a0
ffffffffc020513a:	4581                	li	a1,0
        while ((le = list_next(le)) != list) {
ffffffffc020513c:	6e89                	lui	t4,0x2
ffffffffc020513e:	148e0563          	beq	t3,s0,ffffffffc0205288 <do_fork+0x360>
ffffffffc0205142:	88ae                	mv	a7,a1
ffffffffc0205144:	87f2                	mv	a5,t3
ffffffffc0205146:	6609                	lui	a2,0x2
ffffffffc0205148:	a811                	j	ffffffffc020515c <do_fork+0x234>
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc020514a:	00e6d663          	bge	a3,a4,ffffffffc0205156 <do_fork+0x22e>
ffffffffc020514e:	00c75463          	bge	a4,a2,ffffffffc0205156 <do_fork+0x22e>
ffffffffc0205152:	863a                	mv	a2,a4
ffffffffc0205154:	4885                	li	a7,1
ffffffffc0205156:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0205158:	00878d63          	beq	a5,s0,ffffffffc0205172 <do_fork+0x24a>
            if (proc->pid == last_pid) {
ffffffffc020515c:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_faultread_out_size-0x7c94>
ffffffffc0205160:	fed715e3          	bne	a4,a3,ffffffffc020514a <do_fork+0x222>
                if (++ last_pid >= next_safe) {
ffffffffc0205164:	2685                	addiw	a3,a3,1
ffffffffc0205166:	10c6dc63          	bge	a3,a2,ffffffffc020527e <do_fork+0x356>
ffffffffc020516a:	679c                	ld	a5,8(a5)
ffffffffc020516c:	4585                	li	a1,1
        while ((le = list_next(le)) != list) {
ffffffffc020516e:	fe8797e3          	bne	a5,s0,ffffffffc020515c <do_fork+0x234>
ffffffffc0205172:	c581                	beqz	a1,ffffffffc020517a <do_fork+0x252>
ffffffffc0205174:	00d82023          	sw	a3,0(a6)
ffffffffc0205178:	8536                	mv	a0,a3
ffffffffc020517a:	f0088fe3          	beqz	a7,ffffffffc0205098 <do_fork+0x170>
ffffffffc020517e:	00c32023          	sw	a2,0(t1)
ffffffffc0205182:	bf19                	j	ffffffffc0205098 <do_fork+0x170>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf - 4 : esp;
ffffffffc0205184:	6989                	lui	s3,0x2
ffffffffc0205186:	edc98993          	addi	s3,s3,-292 # 1edc <_binary_obj___user_faultread_out_size-0x7cf4>
ffffffffc020518a:	99b6                	add	s3,s3,a3
ffffffffc020518c:	01373823          	sd	s3,16(a4) # 2010 <_binary_obj___user_faultread_out_size-0x7bc0>
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0205190:	00000797          	auipc	a5,0x0
ffffffffc0205194:	c2a78793          	addi	a5,a5,-982 # ffffffffc0204dba <forkret>
ffffffffc0205198:	f89c                	sd	a5,48(s1)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020519a:	fc98                	sd	a4,56(s1)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020519c:	100027f3          	csrr	a5,sstatus
ffffffffc02051a0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02051a2:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02051a4:	ec0781e3          	beqz	a5,ffffffffc0205066 <do_fork+0x13e>
        intr_disable();
ffffffffc02051a8:	ca0fb0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc02051ac:	4985                	li	s3,1
ffffffffc02051ae:	bd65                	j	ffffffffc0205066 <do_fork+0x13e>
    if ((mm = mm_create()) == NULL) {  // 创建新的内存管理结构
ffffffffc02051b0:	884fc0ef          	jal	ra,ffffffffc0201234 <mm_create>
ffffffffc02051b4:	8caa                	mv	s9,a0
ffffffffc02051b6:	c541                	beqz	a0,ffffffffc020523e <do_fork+0x316>
    if ((page = alloc_page()) == NULL) {
ffffffffc02051b8:	4505                	li	a0,1
ffffffffc02051ba:	aa2fe0ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc02051be:	cd2d                	beqz	a0,ffffffffc0205238 <do_fork+0x310>
    return page - pages + nbase;
ffffffffc02051c0:	000ab683          	ld	a3,0(s5)
ffffffffc02051c4:	67a2                	ld	a5,8(sp)
    return KADDR(page2pa(page));
ffffffffc02051c6:	000bb703          	ld	a4,0(s7)
    return page - pages + nbase;
ffffffffc02051ca:	40d506b3          	sub	a3,a0,a3
ffffffffc02051ce:	8699                	srai	a3,a3,0x6
ffffffffc02051d0:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02051d2:	01b6fdb3          	and	s11,a3,s11
    return page2ppn(page) << PGSHIFT;
ffffffffc02051d6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02051d8:	0eedf263          	bgeu	s11,a4,ffffffffc02052bc <do_fork+0x394>
ffffffffc02051dc:	000c3a03          	ld	s4,0(s8)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc02051e0:	6605                	lui	a2,0x1
ffffffffc02051e2:	000ae597          	auipc	a1,0xae
ffffffffc02051e6:	8165b583          	ld	a1,-2026(a1) # ffffffffc02b29f8 <boot_pgdir>
ffffffffc02051ea:	9a36                	add	s4,s4,a3
ffffffffc02051ec:	8552                	mv	a0,s4
ffffffffc02051ee:	7df000ef          	jal	ra,ffffffffc02061cc <memcpy>
}

static inline void
lock_mm(struct mm_struct *mm) {
    if (mm != NULL) {
        lock(&(mm->mm_lock));
ffffffffc02051f2:	038d0d93          	addi	s11,s10,56
    mm->pgdir = pgdir;
ffffffffc02051f6:	014cbc23          	sd	s4,24(s9)
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02051fa:	4785                	li	a5,1
ffffffffc02051fc:	40fdb7af          	amoor.d	a5,a5,(s11)
    return !test_and_set_bit(0, lock);
}

static inline void
lock(lock_t *lock) {
    while (!try_lock(lock)) {
ffffffffc0205200:	8b85                	andi	a5,a5,1
ffffffffc0205202:	4a05                	li	s4,1
ffffffffc0205204:	c799                	beqz	a5,ffffffffc0205212 <do_fork+0x2ea>
        schedule();
ffffffffc0205206:	5cd000ef          	jal	ra,ffffffffc0205fd2 <schedule>
ffffffffc020520a:	414db7af          	amoor.d	a5,s4,(s11)
    while (!try_lock(lock)) {
ffffffffc020520e:	8b85                	andi	a5,a5,1
ffffffffc0205210:	fbfd                	bnez	a5,ffffffffc0205206 <do_fork+0x2de>
        ret = dup_mmap(mm, oldmm);  // 将当前进程的内存映射复制到新进程
ffffffffc0205212:	85ea                	mv	a1,s10
ffffffffc0205214:	8566                	mv	a0,s9
ffffffffc0205216:	aa6fc0ef          	jal	ra,ffffffffc02014bc <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020521a:	57f9                	li	a5,-2
ffffffffc020521c:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc0205220:	8b85                	andi	a5,a5,1
    }
}

static inline void
unlock(lock_t *lock) {
    if (!test_and_clear_bit(0, lock)) {
ffffffffc0205222:	0e078e63          	beqz	a5,ffffffffc020531e <do_fork+0x3f6>
good_mm:
ffffffffc0205226:	8d66                	mv	s10,s9
    if (ret != 0) {
ffffffffc0205228:	dc0500e3          	beqz	a0,ffffffffc0204fe8 <do_fork+0xc0>
    exit_mmap(mm);  // 释放已复制的内存映射
ffffffffc020522c:	8566                	mv	a0,s9
ffffffffc020522e:	b28fc0ef          	jal	ra,ffffffffc0201556 <exit_mmap>
    put_pgdir(mm);  // 释放页目录
ffffffffc0205232:	8566                	mv	a0,s9
ffffffffc0205234:	c13ff0ef          	jal	ra,ffffffffc0204e46 <put_pgdir>
    mm_destroy(mm);  // 销毁内存管理结构
ffffffffc0205238:	8566                	mv	a0,s9
ffffffffc020523a:	980fc0ef          	jal	ra,ffffffffc02013ba <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020523e:	6894                	ld	a3,16(s1)
    return pa2page(PADDR(kva));
ffffffffc0205240:	c02007b7          	lui	a5,0xc0200
ffffffffc0205244:	0cf6e163          	bltu	a3,a5,ffffffffc0205306 <do_fork+0x3de>
ffffffffc0205248:	000c3783          	ld	a5,0(s8)
    if (PPN(pa) >= npage) {
ffffffffc020524c:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc0205250:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc0205254:	83b1                	srli	a5,a5,0xc
ffffffffc0205256:	06e7ff63          	bgeu	a5,a4,ffffffffc02052d4 <do_fork+0x3ac>
    return &pages[PPN(pa) - nbase];
ffffffffc020525a:	000b3703          	ld	a4,0(s6)
ffffffffc020525e:	000ab503          	ld	a0,0(s5)
ffffffffc0205262:	4589                	li	a1,2
ffffffffc0205264:	8f99                	sub	a5,a5,a4
ffffffffc0205266:	079a                	slli	a5,a5,0x6
ffffffffc0205268:	953e                	add	a0,a0,a5
ffffffffc020526a:	a84fe0ef          	jal	ra,ffffffffc02034ee <free_pages>
    kfree(proc);  // 释放进程结构体
ffffffffc020526e:	8526                	mv	a0,s1
ffffffffc0205270:	d09fc0ef          	jal	ra,ffffffffc0201f78 <kfree>
    ret = -E_NO_MEM;  // 初始化内存不足的错误代码
ffffffffc0205274:	5571                	li	a0,-4
    return ret;  // 返回子进程的 PID，或者错误代码
ffffffffc0205276:	b549                	j	ffffffffc02050f8 <do_fork+0x1d0>
        intr_enable();
ffffffffc0205278:	bcafb0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc020527c:	bd95                	j	ffffffffc02050f0 <do_fork+0x1c8>
                    if (last_pid >= MAX_PID) {
ffffffffc020527e:	01d6c363          	blt	a3,t4,ffffffffc0205284 <do_fork+0x35c>
                        last_pid = 1;
ffffffffc0205282:	4685                	li	a3,1
                    goto repeat;
ffffffffc0205284:	4585                	li	a1,1
ffffffffc0205286:	bd65                	j	ffffffffc020513e <do_fork+0x216>
ffffffffc0205288:	c599                	beqz	a1,ffffffffc0205296 <do_fork+0x36e>
ffffffffc020528a:	00d82023          	sw	a3,0(a6)
    return last_pid;
ffffffffc020528e:	8536                	mv	a0,a3
ffffffffc0205290:	b521                	j	ffffffffc0205098 <do_fork+0x170>
    int ret = -E_NO_FREE_PROC;  // 初始化返回值，表示没有空闲的进程
ffffffffc0205292:	556d                	li	a0,-5
ffffffffc0205294:	b595                	j	ffffffffc02050f8 <do_fork+0x1d0>
    return last_pid;
ffffffffc0205296:	00082503          	lw	a0,0(a6)
ffffffffc020529a:	bbfd                	j	ffffffffc0205098 <do_fork+0x170>
    assert(current->wait_state == 0);  // 确保当前进程的 wait_state 为 0
ffffffffc020529c:	00003697          	auipc	a3,0x3
ffffffffc02052a0:	18468693          	addi	a3,a3,388 # ffffffffc0208420 <default_pmm_manager+0x6d8>
ffffffffc02052a4:	00002617          	auipc	a2,0x2
ffffffffc02052a8:	9fc60613          	addi	a2,a2,-1540 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02052ac:	1b300593          	li	a1,435
ffffffffc02052b0:	00003517          	auipc	a0,0x3
ffffffffc02052b4:	15850513          	addi	a0,a0,344 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc02052b8:	f51fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    return KADDR(page2pa(page));
ffffffffc02052bc:	00002617          	auipc	a2,0x2
ffffffffc02052c0:	19460613          	addi	a2,a2,404 # ffffffffc0207450 <commands+0xbc0>
ffffffffc02052c4:	06a00593          	li	a1,106
ffffffffc02052c8:	00002517          	auipc	a0,0x2
ffffffffc02052cc:	17850513          	addi	a0,a0,376 # ffffffffc0207440 <commands+0xbb0>
ffffffffc02052d0:	f39fa0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02052d4:	00002617          	auipc	a2,0x2
ffffffffc02052d8:	14c60613          	addi	a2,a2,332 # ffffffffc0207420 <commands+0xb90>
ffffffffc02052dc:	06300593          	li	a1,99
ffffffffc02052e0:	00002517          	auipc	a0,0x2
ffffffffc02052e4:	16050513          	addi	a0,a0,352 # ffffffffc0207440 <commands+0xbb0>
ffffffffc02052e8:	f21fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    proc->cr3 = PADDR(mm->pgdir);  // 设置新进程的页目录物理地址
ffffffffc02052ec:	86be                	mv	a3,a5
ffffffffc02052ee:	00002617          	auipc	a2,0x2
ffffffffc02052f2:	30a60613          	addi	a2,a2,778 # ffffffffc02075f8 <commands+0xd68>
ffffffffc02052f6:	17100593          	li	a1,369
ffffffffc02052fa:	00003517          	auipc	a0,0x3
ffffffffc02052fe:	10e50513          	addi	a0,a0,270 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc0205302:	f07fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0205306:	00002617          	auipc	a2,0x2
ffffffffc020530a:	2f260613          	addi	a2,a2,754 # ffffffffc02075f8 <commands+0xd68>
ffffffffc020530e:	06f00593          	li	a1,111
ffffffffc0205312:	00002517          	auipc	a0,0x2
ffffffffc0205316:	12e50513          	addi	a0,a0,302 # ffffffffc0207440 <commands+0xbb0>
ffffffffc020531a:	eeffa0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("Unlock failed.\n");
ffffffffc020531e:	00003617          	auipc	a2,0x3
ffffffffc0205322:	12260613          	addi	a2,a2,290 # ffffffffc0208440 <default_pmm_manager+0x6f8>
ffffffffc0205326:	03100593          	li	a1,49
ffffffffc020532a:	00003517          	auipc	a0,0x3
ffffffffc020532e:	12650513          	addi	a0,a0,294 # ffffffffc0208450 <default_pmm_manager+0x708>
ffffffffc0205332:	ed7fa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0205336 <kernel_thread>:
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc0205336:	7129                	addi	sp,sp,-320
ffffffffc0205338:	fa22                	sd	s0,304(sp)
ffffffffc020533a:	f626                	sd	s1,296(sp)
ffffffffc020533c:	f24a                	sd	s2,288(sp)
ffffffffc020533e:	84ae                	mv	s1,a1
ffffffffc0205340:	892a                	mv	s2,a0
ffffffffc0205342:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0205344:	4581                	li	a1,0
ffffffffc0205346:	12000613          	li	a2,288
ffffffffc020534a:	850a                	mv	a0,sp
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc020534c:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020534e:	66d000ef          	jal	ra,ffffffffc02061ba <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0205352:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0205354:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0205356:	100027f3          	csrr	a5,sstatus
ffffffffc020535a:	edd7f793          	andi	a5,a5,-291
ffffffffc020535e:	1207e793          	ori	a5,a5,288
ffffffffc0205362:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0205364:	860a                	mv	a2,sp
ffffffffc0205366:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020536a:	00000797          	auipc	a5,0x0
ffffffffc020536e:	96c78793          	addi	a5,a5,-1684 # ffffffffc0204cd6 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0205372:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0205374:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0205376:	bb3ff0ef          	jal	ra,ffffffffc0204f28 <do_fork>
}
ffffffffc020537a:	70f2                	ld	ra,312(sp)
ffffffffc020537c:	7452                	ld	s0,304(sp)
ffffffffc020537e:	74b2                	ld	s1,296(sp)
ffffffffc0205380:	7912                	ld	s2,288(sp)
ffffffffc0205382:	6131                	addi	sp,sp,320
ffffffffc0205384:	8082                	ret

ffffffffc0205386 <do_exit>:
do_exit(int error_code) {
ffffffffc0205386:	7179                	addi	sp,sp,-48
ffffffffc0205388:	f022                	sd	s0,32(sp)
    if (current == idleproc) {
ffffffffc020538a:	000ad417          	auipc	s0,0xad
ffffffffc020538e:	69640413          	addi	s0,s0,1686 # ffffffffc02b2a20 <current>
ffffffffc0205392:	601c                	ld	a5,0(s0)
do_exit(int error_code) {
ffffffffc0205394:	f406                	sd	ra,40(sp)
ffffffffc0205396:	ec26                	sd	s1,24(sp)
ffffffffc0205398:	e84a                	sd	s2,16(sp)
ffffffffc020539a:	e44e                	sd	s3,8(sp)
ffffffffc020539c:	e052                	sd	s4,0(sp)
    if (current == idleproc) {
ffffffffc020539e:	000ad717          	auipc	a4,0xad
ffffffffc02053a2:	68a73703          	ld	a4,1674(a4) # ffffffffc02b2a28 <idleproc>
ffffffffc02053a6:	0ce78c63          	beq	a5,a4,ffffffffc020547e <do_exit+0xf8>
    if (current == initproc) {
ffffffffc02053aa:	000ad497          	auipc	s1,0xad
ffffffffc02053ae:	68648493          	addi	s1,s1,1670 # ffffffffc02b2a30 <initproc>
ffffffffc02053b2:	6098                	ld	a4,0(s1)
ffffffffc02053b4:	0ee78b63          	beq	a5,a4,ffffffffc02054aa <do_exit+0x124>
    struct mm_struct *mm = current->mm;
ffffffffc02053b8:	0287b983          	ld	s3,40(a5)
ffffffffc02053bc:	892a                	mv	s2,a0
    if (mm != NULL) {
ffffffffc02053be:	02098663          	beqz	s3,ffffffffc02053ea <do_exit+0x64>
ffffffffc02053c2:	000ad797          	auipc	a5,0xad
ffffffffc02053c6:	62e7b783          	ld	a5,1582(a5) # ffffffffc02b29f0 <boot_cr3>
ffffffffc02053ca:	577d                	li	a4,-1
ffffffffc02053cc:	177e                	slli	a4,a4,0x3f
ffffffffc02053ce:	83b1                	srli	a5,a5,0xc
ffffffffc02053d0:	8fd9                	or	a5,a5,a4
ffffffffc02053d2:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02053d6:	0309a783          	lw	a5,48(s3)
ffffffffc02053da:	fff7871b          	addiw	a4,a5,-1
ffffffffc02053de:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0) {
ffffffffc02053e2:	cb55                	beqz	a4,ffffffffc0205496 <do_exit+0x110>
        current->mm = NULL;
ffffffffc02053e4:	601c                	ld	a5,0(s0)
ffffffffc02053e6:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc02053ea:	601c                	ld	a5,0(s0)
ffffffffc02053ec:	470d                	li	a4,3
ffffffffc02053ee:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc02053f0:	0f27a423          	sw	s2,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02053f4:	100027f3          	csrr	a5,sstatus
ffffffffc02053f8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02053fa:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02053fc:	e3f9                	bnez	a5,ffffffffc02054c2 <do_exit+0x13c>
        proc = current->parent;
ffffffffc02053fe:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD) {
ffffffffc0205400:	800007b7          	lui	a5,0x80000
ffffffffc0205404:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0205406:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD) {
ffffffffc0205408:	0ec52703          	lw	a4,236(a0)
ffffffffc020540c:	0af70f63          	beq	a4,a5,ffffffffc02054ca <do_exit+0x144>
        while (current->cptr != NULL) {
ffffffffc0205410:	6018                	ld	a4,0(s0)
ffffffffc0205412:	7b7c                	ld	a5,240(a4)
ffffffffc0205414:	c3a1                	beqz	a5,ffffffffc0205454 <do_exit+0xce>
                if (initproc->wait_state == WT_CHILD) {
ffffffffc0205416:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE) {
ffffffffc020541a:	490d                	li	s2,3
                if (initproc->wait_state == WT_CHILD) {
ffffffffc020541c:	0985                	addi	s3,s3,1
ffffffffc020541e:	a021                	j	ffffffffc0205426 <do_exit+0xa0>
        while (current->cptr != NULL) {
ffffffffc0205420:	6018                	ld	a4,0(s0)
ffffffffc0205422:	7b7c                	ld	a5,240(a4)
ffffffffc0205424:	cb85                	beqz	a5,ffffffffc0205454 <do_exit+0xce>
            current->cptr = proc->optr;  // 更新当前进程的下一个子进程
ffffffffc0205426:	1007b683          	ld	a3,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff4fc0>
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc020542a:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;  // 更新当前进程的下一个子进程
ffffffffc020542c:	fb74                	sd	a3,240(a4)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc020542e:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc0205430:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc0205434:	10e7b023          	sd	a4,256(a5)
ffffffffc0205438:	c311                	beqz	a4,ffffffffc020543c <do_exit+0xb6>
                initproc->cptr->yptr = proc;
ffffffffc020543a:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc020543c:	4398                	lw	a4,0(a5)
            proc->parent = initproc;  // 设置子进程的新父进程为 initproc
ffffffffc020543e:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;  // 将子进程加入 initproc 的子进程链表
ffffffffc0205440:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc0205442:	fd271fe3          	bne	a4,s2,ffffffffc0205420 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD) {
ffffffffc0205446:	0ec52783          	lw	a5,236(a0)
ffffffffc020544a:	fd379be3          	bne	a5,s3,ffffffffc0205420 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc020544e:	305000ef          	jal	ra,ffffffffc0205f52 <wakeup_proc>
ffffffffc0205452:	b7f9                	j	ffffffffc0205420 <do_exit+0x9a>
    if (flag) {
ffffffffc0205454:	020a1263          	bnez	s4,ffffffffc0205478 <do_exit+0xf2>
    schedule();
ffffffffc0205458:	37b000ef          	jal	ra,ffffffffc0205fd2 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc020545c:	601c                	ld	a5,0(s0)
ffffffffc020545e:	00003617          	auipc	a2,0x3
ffffffffc0205462:	02a60613          	addi	a2,a2,42 # ffffffffc0208488 <default_pmm_manager+0x740>
ffffffffc0205466:	23800593          	li	a1,568
ffffffffc020546a:	43d4                	lw	a3,4(a5)
ffffffffc020546c:	00003517          	auipc	a0,0x3
ffffffffc0205470:	f9c50513          	addi	a0,a0,-100 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc0205474:	d95fa0ef          	jal	ra,ffffffffc0200208 <__panic>
        intr_enable();
ffffffffc0205478:	9cafb0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc020547c:	bff1                	j	ffffffffc0205458 <do_exit+0xd2>
        panic("idleproc exit.\n");  // 空闲进程不能退出，发生异常
ffffffffc020547e:	00003617          	auipc	a2,0x3
ffffffffc0205482:	fea60613          	addi	a2,a2,-22 # ffffffffc0208468 <default_pmm_manager+0x720>
ffffffffc0205486:	1e900593          	li	a1,489
ffffffffc020548a:	00003517          	auipc	a0,0x3
ffffffffc020548e:	f7e50513          	addi	a0,a0,-130 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc0205492:	d77fa0ef          	jal	ra,ffffffffc0200208 <__panic>
            exit_mmap(mm);
ffffffffc0205496:	854e                	mv	a0,s3
ffffffffc0205498:	8befc0ef          	jal	ra,ffffffffc0201556 <exit_mmap>
            put_pgdir(mm);
ffffffffc020549c:	854e                	mv	a0,s3
ffffffffc020549e:	9a9ff0ef          	jal	ra,ffffffffc0204e46 <put_pgdir>
            mm_destroy(mm);
ffffffffc02054a2:	854e                	mv	a0,s3
ffffffffc02054a4:	f17fb0ef          	jal	ra,ffffffffc02013ba <mm_destroy>
ffffffffc02054a8:	bf35                	j	ffffffffc02053e4 <do_exit+0x5e>
        panic("initproc exit.\n");  // 初始化进程不能退出，发生异常
ffffffffc02054aa:	00003617          	auipc	a2,0x3
ffffffffc02054ae:	fce60613          	addi	a2,a2,-50 # ffffffffc0208478 <default_pmm_manager+0x730>
ffffffffc02054b2:	1ec00593          	li	a1,492
ffffffffc02054b6:	00003517          	auipc	a0,0x3
ffffffffc02054ba:	f5250513          	addi	a0,a0,-174 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc02054be:	d4bfa0ef          	jal	ra,ffffffffc0200208 <__panic>
        intr_disable();
ffffffffc02054c2:	986fb0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc02054c6:	4a05                	li	s4,1
ffffffffc02054c8:	bf1d                	j	ffffffffc02053fe <do_exit+0x78>
            wakeup_proc(proc);
ffffffffc02054ca:	289000ef          	jal	ra,ffffffffc0205f52 <wakeup_proc>
ffffffffc02054ce:	b789                	j	ffffffffc0205410 <do_exit+0x8a>

ffffffffc02054d0 <do_wait.part.0>:
do_wait(int pid, int *code_store) {
ffffffffc02054d0:	715d                	addi	sp,sp,-80
ffffffffc02054d2:	f84a                	sd	s2,48(sp)
ffffffffc02054d4:	f44e                	sd	s3,40(sp)
        current->wait_state = WT_CHILD;  // 设置当前进程的等待状态为等待子进程
ffffffffc02054d6:	80000937          	lui	s2,0x80000
    if (0 < pid && pid < MAX_PID) {
ffffffffc02054da:	6989                	lui	s3,0x2
do_wait(int pid, int *code_store) {
ffffffffc02054dc:	fc26                	sd	s1,56(sp)
ffffffffc02054de:	f052                	sd	s4,32(sp)
ffffffffc02054e0:	ec56                	sd	s5,24(sp)
ffffffffc02054e2:	e85a                	sd	s6,16(sp)
ffffffffc02054e4:	e45e                	sd	s7,8(sp)
ffffffffc02054e6:	e486                	sd	ra,72(sp)
ffffffffc02054e8:	e0a2                	sd	s0,64(sp)
ffffffffc02054ea:	84aa                	mv	s1,a0
ffffffffc02054ec:	8a2e                	mv	s4,a1
        proc = current->cptr;  // 获取当前进程的第一个子进程
ffffffffc02054ee:	000adb97          	auipc	s7,0xad
ffffffffc02054f2:	532b8b93          	addi	s7,s7,1330 # ffffffffc02b2a20 <current>
    if (0 < pid && pid < MAX_PID) {
ffffffffc02054f6:	00050b1b          	sext.w	s6,a0
ffffffffc02054fa:	fff50a9b          	addiw	s5,a0,-1
ffffffffc02054fe:	19f9                	addi	s3,s3,-2
        current->wait_state = WT_CHILD;  // 设置当前进程的等待状态为等待子进程
ffffffffc0205500:	0905                	addi	s2,s2,1
    if (pid != 0) {
ffffffffc0205502:	ccbd                	beqz	s1,ffffffffc0205580 <do_wait.part.0+0xb0>
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205504:	0359e863          	bltu	s3,s5,ffffffffc0205534 <do_wait.part.0+0x64>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205508:	45a9                	li	a1,10
ffffffffc020550a:	855a                	mv	a0,s6
ffffffffc020550c:	0c6010ef          	jal	ra,ffffffffc02065d2 <hash32>
ffffffffc0205510:	02051793          	slli	a5,a0,0x20
ffffffffc0205514:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0205518:	000a9797          	auipc	a5,0xa9
ffffffffc020551c:	48078793          	addi	a5,a5,1152 # ffffffffc02ae998 <hash_list>
ffffffffc0205520:	953e                	add	a0,a0,a5
ffffffffc0205522:	842a                	mv	s0,a0
        while ((le = list_next(le)) != list) {
ffffffffc0205524:	a029                	j	ffffffffc020552e <do_wait.part.0+0x5e>
            if (proc->pid == pid) {
ffffffffc0205526:	f2c42783          	lw	a5,-212(s0)
ffffffffc020552a:	02978163          	beq	a5,s1,ffffffffc020554c <do_wait.part.0+0x7c>
ffffffffc020552e:	6400                	ld	s0,8(s0)
        while ((le = list_next(le)) != list) {
ffffffffc0205530:	fe851be3          	bne	a0,s0,ffffffffc0205526 <do_wait.part.0+0x56>
    return -E_BAD_PROC;  // 如果没有符合条件的子进程，返回错误
ffffffffc0205534:	5579                	li	a0,-2
}
ffffffffc0205536:	60a6                	ld	ra,72(sp)
ffffffffc0205538:	6406                	ld	s0,64(sp)
ffffffffc020553a:	74e2                	ld	s1,56(sp)
ffffffffc020553c:	7942                	ld	s2,48(sp)
ffffffffc020553e:	79a2                	ld	s3,40(sp)
ffffffffc0205540:	7a02                	ld	s4,32(sp)
ffffffffc0205542:	6ae2                	ld	s5,24(sp)
ffffffffc0205544:	6b42                	ld	s6,16(sp)
ffffffffc0205546:	6ba2                	ld	s7,8(sp)
ffffffffc0205548:	6161                	addi	sp,sp,80
ffffffffc020554a:	8082                	ret
        if (proc != NULL && proc->parent == current) {  // 如果该进程的父进程是当前进程
ffffffffc020554c:	000bb683          	ld	a3,0(s7)
ffffffffc0205550:	f4843783          	ld	a5,-184(s0)
ffffffffc0205554:	fed790e3          	bne	a5,a3,ffffffffc0205534 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE) {  // 如果子进程的状态为 ZOMBIE，表示它已经结束
ffffffffc0205558:	f2842703          	lw	a4,-216(s0)
ffffffffc020555c:	478d                	li	a5,3
ffffffffc020555e:	0ef70b63          	beq	a4,a5,ffffffffc0205654 <do_wait.part.0+0x184>
        current->state = PROC_SLEEPING;  // 设置进程状态为睡眠
ffffffffc0205562:	4785                	li	a5,1
ffffffffc0205564:	c29c                	sw	a5,0(a3)
        current->wait_state = WT_CHILD;  // 设置当前进程的等待状态为等待子进程
ffffffffc0205566:	0f26a623          	sw	s2,236(a3)
        schedule();  // 调用调度器进行进程切换
ffffffffc020556a:	269000ef          	jal	ra,ffffffffc0205fd2 <schedule>
        if (current->flags & PF_EXITING) {
ffffffffc020556e:	000bb783          	ld	a5,0(s7)
ffffffffc0205572:	0b07a783          	lw	a5,176(a5)
ffffffffc0205576:	8b85                	andi	a5,a5,1
ffffffffc0205578:	d7c9                	beqz	a5,ffffffffc0205502 <do_wait.part.0+0x32>
            do_exit(-E_KILLED);  // 如果进程正在退出，调用 do_exit 函数退出当前进程
ffffffffc020557a:	555d                	li	a0,-9
ffffffffc020557c:	e0bff0ef          	jal	ra,ffffffffc0205386 <do_exit>
        proc = current->cptr;  // 获取当前进程的第一个子进程
ffffffffc0205580:	000bb683          	ld	a3,0(s7)
ffffffffc0205584:	7ae0                	ld	s0,240(a3)
        for (; proc != NULL; proc = proc->optr) {
ffffffffc0205586:	d45d                	beqz	s0,ffffffffc0205534 <do_wait.part.0+0x64>
            if (proc->state == PROC_ZOMBIE) {  // 如果子进程的状态为 ZOMBIE
ffffffffc0205588:	470d                	li	a4,3
ffffffffc020558a:	a021                	j	ffffffffc0205592 <do_wait.part.0+0xc2>
        for (; proc != NULL; proc = proc->optr) {
ffffffffc020558c:	10043403          	ld	s0,256(s0)
ffffffffc0205590:	d869                	beqz	s0,ffffffffc0205562 <do_wait.part.0+0x92>
            if (proc->state == PROC_ZOMBIE) {  // 如果子进程的状态为 ZOMBIE
ffffffffc0205592:	401c                	lw	a5,0(s0)
ffffffffc0205594:	fee79ce3          	bne	a5,a4,ffffffffc020558c <do_wait.part.0+0xbc>
    if (proc == idleproc || proc == initproc) {
ffffffffc0205598:	000ad797          	auipc	a5,0xad
ffffffffc020559c:	4907b783          	ld	a5,1168(a5) # ffffffffc02b2a28 <idleproc>
ffffffffc02055a0:	0c878963          	beq	a5,s0,ffffffffc0205672 <do_wait.part.0+0x1a2>
ffffffffc02055a4:	000ad797          	auipc	a5,0xad
ffffffffc02055a8:	48c7b783          	ld	a5,1164(a5) # ffffffffc02b2a30 <initproc>
ffffffffc02055ac:	0cf40363          	beq	s0,a5,ffffffffc0205672 <do_wait.part.0+0x1a2>
    if (code_store != NULL) {
ffffffffc02055b0:	000a0663          	beqz	s4,ffffffffc02055bc <do_wait.part.0+0xec>
        *code_store = proc->exit_code;
ffffffffc02055b4:	0e842783          	lw	a5,232(s0)
ffffffffc02055b8:	00fa2023          	sw	a5,0(s4) # 1000 <_binary_obj___user_faultread_out_size-0x8bd0>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02055bc:	100027f3          	csrr	a5,sstatus
ffffffffc02055c0:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02055c2:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02055c4:	e7c1                	bnez	a5,ffffffffc020564c <do_wait.part.0+0x17c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02055c6:	6c70                	ld	a2,216(s0)
ffffffffc02055c8:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL) {
ffffffffc02055ca:	10043703          	ld	a4,256(s0)
        proc->optr->yptr = proc->yptr;
ffffffffc02055ce:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc02055d0:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02055d2:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02055d4:	6470                	ld	a2,200(s0)
ffffffffc02055d6:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc02055d8:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02055da:	e290                	sd	a2,0(a3)
    if (proc->optr != NULL) {
ffffffffc02055dc:	c319                	beqz	a4,ffffffffc02055e2 <do_wait.part.0+0x112>
        proc->optr->yptr = proc->yptr;
ffffffffc02055de:	ff7c                	sd	a5,248(a4)
    if (proc->yptr != NULL) {
ffffffffc02055e0:	7c7c                	ld	a5,248(s0)
ffffffffc02055e2:	c3b5                	beqz	a5,ffffffffc0205646 <do_wait.part.0+0x176>
        proc->yptr->optr = proc->optr;
ffffffffc02055e4:	10e7b023          	sd	a4,256(a5)
    nr_process --;
ffffffffc02055e8:	000ad717          	auipc	a4,0xad
ffffffffc02055ec:	45070713          	addi	a4,a4,1104 # ffffffffc02b2a38 <nr_process>
ffffffffc02055f0:	431c                	lw	a5,0(a4)
ffffffffc02055f2:	37fd                	addiw	a5,a5,-1
ffffffffc02055f4:	c31c                	sw	a5,0(a4)
    if (flag) {
ffffffffc02055f6:	e5a9                	bnez	a1,ffffffffc0205640 <do_wait.part.0+0x170>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02055f8:	6814                	ld	a3,16(s0)
ffffffffc02055fa:	c02007b7          	lui	a5,0xc0200
ffffffffc02055fe:	04f6ee63          	bltu	a3,a5,ffffffffc020565a <do_wait.part.0+0x18a>
ffffffffc0205602:	000ad797          	auipc	a5,0xad
ffffffffc0205606:	4167b783          	ld	a5,1046(a5) # ffffffffc02b2a18 <va_pa_offset>
ffffffffc020560a:	8e9d                	sub	a3,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc020560c:	82b1                	srli	a3,a3,0xc
ffffffffc020560e:	000ad797          	auipc	a5,0xad
ffffffffc0205612:	3f27b783          	ld	a5,1010(a5) # ffffffffc02b2a00 <npage>
ffffffffc0205616:	06f6fa63          	bgeu	a3,a5,ffffffffc020568a <do_wait.part.0+0x1ba>
    return &pages[PPN(pa) - nbase];
ffffffffc020561a:	00003517          	auipc	a0,0x3
ffffffffc020561e:	6a653503          	ld	a0,1702(a0) # ffffffffc0208cc0 <nbase>
ffffffffc0205622:	8e89                	sub	a3,a3,a0
ffffffffc0205624:	069a                	slli	a3,a3,0x6
ffffffffc0205626:	000ad517          	auipc	a0,0xad
ffffffffc020562a:	3e253503          	ld	a0,994(a0) # ffffffffc02b2a08 <pages>
ffffffffc020562e:	9536                	add	a0,a0,a3
ffffffffc0205630:	4589                	li	a1,2
ffffffffc0205632:	ebdfd0ef          	jal	ra,ffffffffc02034ee <free_pages>
    kfree(proc);
ffffffffc0205636:	8522                	mv	a0,s0
ffffffffc0205638:	941fc0ef          	jal	ra,ffffffffc0201f78 <kfree>
    return 0;  // 返回 0，表示成功回收资源
ffffffffc020563c:	4501                	li	a0,0
ffffffffc020563e:	bde5                	j	ffffffffc0205536 <do_wait.part.0+0x66>
        intr_enable();
ffffffffc0205640:	802fb0ef          	jal	ra,ffffffffc0200642 <intr_enable>
ffffffffc0205644:	bf55                	j	ffffffffc02055f8 <do_wait.part.0+0x128>
       proc->parent->cptr = proc->optr;
ffffffffc0205646:	701c                	ld	a5,32(s0)
ffffffffc0205648:	fbf8                	sd	a4,240(a5)
ffffffffc020564a:	bf79                	j	ffffffffc02055e8 <do_wait.part.0+0x118>
        intr_disable();
ffffffffc020564c:	ffdfa0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc0205650:	4585                	li	a1,1
ffffffffc0205652:	bf95                	j	ffffffffc02055c6 <do_wait.part.0+0xf6>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205654:	f2840413          	addi	s0,s0,-216
ffffffffc0205658:	b781                	j	ffffffffc0205598 <do_wait.part.0+0xc8>
    return pa2page(PADDR(kva));
ffffffffc020565a:	00002617          	auipc	a2,0x2
ffffffffc020565e:	f9e60613          	addi	a2,a2,-98 # ffffffffc02075f8 <commands+0xd68>
ffffffffc0205662:	06f00593          	li	a1,111
ffffffffc0205666:	00002517          	auipc	a0,0x2
ffffffffc020566a:	dda50513          	addi	a0,a0,-550 # ffffffffc0207440 <commands+0xbb0>
ffffffffc020566e:	b9bfa0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("wait idleproc or initproc.\n");  // 不能等待这两个特殊进程
ffffffffc0205672:	00003617          	auipc	a2,0x3
ffffffffc0205676:	e3660613          	addi	a2,a2,-458 # ffffffffc02084a8 <default_pmm_manager+0x760>
ffffffffc020567a:	36000593          	li	a1,864
ffffffffc020567e:	00003517          	auipc	a0,0x3
ffffffffc0205682:	d8a50513          	addi	a0,a0,-630 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc0205686:	b83fa0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020568a:	00002617          	auipc	a2,0x2
ffffffffc020568e:	d9660613          	addi	a2,a2,-618 # ffffffffc0207420 <commands+0xb90>
ffffffffc0205692:	06300593          	li	a1,99
ffffffffc0205696:	00002517          	auipc	a0,0x2
ffffffffc020569a:	daa50513          	addi	a0,a0,-598 # ffffffffc0207440 <commands+0xbb0>
ffffffffc020569e:	b6bfa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02056a2 <init_main>:
// 该函数会先记录当前的空闲内存页面数和已分配的内存数，
// 然后创建一个名为 `user_main` 的内核线程，
// 最后等待所有用户态进程结束并进行一些内存和进程的检查。
// 检查通过后，打印相关信息。
static int
init_main(void *arg) {
ffffffffc02056a2:	1141                	addi	sp,sp,-16
ffffffffc02056a4:	e406                	sd	ra,8(sp)
    // 记录当前的空闲页面数和内核分配的内存
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02056a6:	e89fd0ef          	jal	ra,ffffffffc020352e <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02056aa:	81bfc0ef          	jal	ra,ffffffffc0201ec4 <kallocated>

    // 创建 `user_main` 内核线程，启动用户程序
    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02056ae:	4601                	li	a2,0
ffffffffc02056b0:	4581                	li	a1,0
ffffffffc02056b2:	fffff517          	auipc	a0,0xfffff
ffffffffc02056b6:	71650513          	addi	a0,a0,1814 # ffffffffc0204dc8 <user_main>
ffffffffc02056ba:	c7dff0ef          	jal	ra,ffffffffc0205336 <kernel_thread>
    if (pid <= 0) {
ffffffffc02056be:	00a04563          	bgtz	a0,ffffffffc02056c8 <init_main+0x26>
ffffffffc02056c2:	a071                	j	ffffffffc020574e <init_main+0xac>
        panic("create user_main failed.\n");
    }

    // 等待所有子进程结束（如果 pid == 0，等待任何子进程）
    while (do_wait(0, NULL) == 0) {
        schedule();  // 调度其他进程
ffffffffc02056c4:	10f000ef          	jal	ra,ffffffffc0205fd2 <schedule>
    if (code_store != NULL) {
ffffffffc02056c8:	4581                	li	a1,0
ffffffffc02056ca:	4501                	li	a0,0
ffffffffc02056cc:	e05ff0ef          	jal	ra,ffffffffc02054d0 <do_wait.part.0>
    while (do_wait(0, NULL) == 0) {
ffffffffc02056d0:	d975                	beqz	a0,ffffffffc02056c4 <init_main+0x22>
    }

    // 打印所有用户态进程已经退出
    cprintf("all user-mode processes have quit.\n");
ffffffffc02056d2:	00003517          	auipc	a0,0x3
ffffffffc02056d6:	e1650513          	addi	a0,a0,-490 # ffffffffc02084e8 <default_pmm_manager+0x7a0>
ffffffffc02056da:	9f3fa0ef          	jal	ra,ffffffffc02000cc <cprintf>

    // 检查 initproc 的子进程和父进程链表是否为空
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02056de:	000ad797          	auipc	a5,0xad
ffffffffc02056e2:	3527b783          	ld	a5,850(a5) # ffffffffc02b2a30 <initproc>
ffffffffc02056e6:	7bf8                	ld	a4,240(a5)
ffffffffc02056e8:	e339                	bnez	a4,ffffffffc020572e <init_main+0x8c>
ffffffffc02056ea:	7ff8                	ld	a4,248(a5)
ffffffffc02056ec:	e329                	bnez	a4,ffffffffc020572e <init_main+0x8c>
ffffffffc02056ee:	1007b703          	ld	a4,256(a5)
ffffffffc02056f2:	ef15                	bnez	a4,ffffffffc020572e <init_main+0x8c>
    // 检查进程数应该为 2（包括 init 进程和 idle 进程）
    assert(nr_process == 2);
ffffffffc02056f4:	000ad697          	auipc	a3,0xad
ffffffffc02056f8:	3446a683          	lw	a3,836(a3) # ffffffffc02b2a38 <nr_process>
ffffffffc02056fc:	4709                	li	a4,2
ffffffffc02056fe:	0ae69463          	bne	a3,a4,ffffffffc02057a6 <init_main+0x104>
    return listelm->next;
ffffffffc0205702:	000ad697          	auipc	a3,0xad
ffffffffc0205706:	29668693          	addi	a3,a3,662 # ffffffffc02b2998 <proc_list>
    // 确保进程链表中仅有 initproc
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020570a:	6698                	ld	a4,8(a3)
ffffffffc020570c:	0c878793          	addi	a5,a5,200
ffffffffc0205710:	06f71b63          	bne	a4,a5,ffffffffc0205786 <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0205714:	629c                	ld	a5,0(a3)
ffffffffc0205716:	04f71863          	bne	a4,a5,ffffffffc0205766 <init_main+0xc4>

    // 打印内存检查通过的信息
    cprintf("init check memory pass.\n");
ffffffffc020571a:	00003517          	auipc	a0,0x3
ffffffffc020571e:	eb650513          	addi	a0,a0,-330 # ffffffffc02085d0 <default_pmm_manager+0x888>
ffffffffc0205722:	9abfa0ef          	jal	ra,ffffffffc02000cc <cprintf>
    return 0;
}
ffffffffc0205726:	60a2                	ld	ra,8(sp)
ffffffffc0205728:	4501                	li	a0,0
ffffffffc020572a:	0141                	addi	sp,sp,16
ffffffffc020572c:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020572e:	00003697          	auipc	a3,0x3
ffffffffc0205732:	de268693          	addi	a3,a3,-542 # ffffffffc0208510 <default_pmm_manager+0x7c8>
ffffffffc0205736:	00001617          	auipc	a2,0x1
ffffffffc020573a:	56a60613          	addi	a2,a2,1386 # ffffffffc0206ca0 <commands+0x410>
ffffffffc020573e:	3f400593          	li	a1,1012
ffffffffc0205742:	00003517          	auipc	a0,0x3
ffffffffc0205746:	cc650513          	addi	a0,a0,-826 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc020574a:	abffa0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("create user_main failed.\n");
ffffffffc020574e:	00003617          	auipc	a2,0x3
ffffffffc0205752:	d7a60613          	addi	a2,a2,-646 # ffffffffc02084c8 <default_pmm_manager+0x780>
ffffffffc0205756:	3e800593          	li	a1,1000
ffffffffc020575a:	00003517          	auipc	a0,0x3
ffffffffc020575e:	cae50513          	addi	a0,a0,-850 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc0205762:	aa7fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0205766:	00003697          	auipc	a3,0x3
ffffffffc020576a:	e3a68693          	addi	a3,a3,-454 # ffffffffc02085a0 <default_pmm_manager+0x858>
ffffffffc020576e:	00001617          	auipc	a2,0x1
ffffffffc0205772:	53260613          	addi	a2,a2,1330 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0205776:	3f900593          	li	a1,1017
ffffffffc020577a:	00003517          	auipc	a0,0x3
ffffffffc020577e:	c8e50513          	addi	a0,a0,-882 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc0205782:	a87fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0205786:	00003697          	auipc	a3,0x3
ffffffffc020578a:	dea68693          	addi	a3,a3,-534 # ffffffffc0208570 <default_pmm_manager+0x828>
ffffffffc020578e:	00001617          	auipc	a2,0x1
ffffffffc0205792:	51260613          	addi	a2,a2,1298 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0205796:	3f800593          	li	a1,1016
ffffffffc020579a:	00003517          	auipc	a0,0x3
ffffffffc020579e:	c6e50513          	addi	a0,a0,-914 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc02057a2:	a67fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(nr_process == 2);
ffffffffc02057a6:	00003697          	auipc	a3,0x3
ffffffffc02057aa:	dba68693          	addi	a3,a3,-582 # ffffffffc0208560 <default_pmm_manager+0x818>
ffffffffc02057ae:	00001617          	auipc	a2,0x1
ffffffffc02057b2:	4f260613          	addi	a2,a2,1266 # ffffffffc0206ca0 <commands+0x410>
ffffffffc02057b6:	3f600593          	li	a1,1014
ffffffffc02057ba:	00003517          	auipc	a0,0x3
ffffffffc02057be:	c4e50513          	addi	a0,a0,-946 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc02057c2:	a47fa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc02057c6 <do_execve>:
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc02057c6:	7171                	addi	sp,sp,-176
ffffffffc02057c8:	e4ee                	sd	s11,72(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02057ca:	000add97          	auipc	s11,0xad
ffffffffc02057ce:	256d8d93          	addi	s11,s11,598 # ffffffffc02b2a20 <current>
ffffffffc02057d2:	000db783          	ld	a5,0(s11)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc02057d6:	e54e                	sd	s3,136(sp)
ffffffffc02057d8:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02057da:	0287b983          	ld	s3,40(a5)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc02057de:	e94a                	sd	s2,144(sp)
ffffffffc02057e0:	f4de                	sd	s7,104(sp)
ffffffffc02057e2:	892a                	mv	s2,a0
ffffffffc02057e4:	8bb2                	mv	s7,a2
ffffffffc02057e6:	84ae                	mv	s1,a1
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc02057e8:	862e                	mv	a2,a1
ffffffffc02057ea:	4681                	li	a3,0
ffffffffc02057ec:	85aa                	mv	a1,a0
ffffffffc02057ee:	854e                	mv	a0,s3
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc02057f0:	f506                	sd	ra,168(sp)
ffffffffc02057f2:	f122                	sd	s0,160(sp)
ffffffffc02057f4:	e152                	sd	s4,128(sp)
ffffffffc02057f6:	fcd6                	sd	s5,120(sp)
ffffffffc02057f8:	f8da                	sd	s6,112(sp)
ffffffffc02057fa:	f0e2                	sd	s8,96(sp)
ffffffffc02057fc:	ece6                	sd	s9,88(sp)
ffffffffc02057fe:	e8ea                	sd	s10,80(sp)
ffffffffc0205800:	f05e                	sd	s7,32(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc0205802:	c00fc0ef          	jal	ra,ffffffffc0201c02 <user_mem_check>
ffffffffc0205806:	40050863          	beqz	a0,ffffffffc0205c16 <do_execve+0x450>
    memset(local_name, 0, sizeof(local_name));  // 清空缓冲区
ffffffffc020580a:	4641                	li	a2,16
ffffffffc020580c:	4581                	li	a1,0
ffffffffc020580e:	1808                	addi	a0,sp,48
ffffffffc0205810:	1ab000ef          	jal	ra,ffffffffc02061ba <memset>
    memcpy(local_name, name, len);  // 将传入的程序名复制到 local_name 中
ffffffffc0205814:	47bd                	li	a5,15
ffffffffc0205816:	8626                	mv	a2,s1
ffffffffc0205818:	1e97e063          	bltu	a5,s1,ffffffffc02059f8 <do_execve+0x232>
ffffffffc020581c:	85ca                	mv	a1,s2
ffffffffc020581e:	1808                	addi	a0,sp,48
ffffffffc0205820:	1ad000ef          	jal	ra,ffffffffc02061cc <memcpy>
    if (mm != NULL) {
ffffffffc0205824:	1e098163          	beqz	s3,ffffffffc0205a06 <do_execve+0x240>
        cputs("mm != NULL");  // 调试输出，显示当前进程有内存管理结构体
ffffffffc0205828:	00002517          	auipc	a0,0x2
ffffffffc020582c:	9f050513          	addi	a0,a0,-1552 # ffffffffc0207218 <commands+0x988>
ffffffffc0205830:	8d5fa0ef          	jal	ra,ffffffffc0200104 <cputs>
ffffffffc0205834:	000ad797          	auipc	a5,0xad
ffffffffc0205838:	1bc7b783          	ld	a5,444(a5) # ffffffffc02b29f0 <boot_cr3>
ffffffffc020583c:	577d                	li	a4,-1
ffffffffc020583e:	177e                	slli	a4,a4,0x3f
ffffffffc0205840:	83b1                	srli	a5,a5,0xc
ffffffffc0205842:	8fd9                	or	a5,a5,a4
ffffffffc0205844:	18079073          	csrw	satp,a5
ffffffffc0205848:	0309a783          	lw	a5,48(s3) # 2030 <_binary_obj___user_faultread_out_size-0x7ba0>
ffffffffc020584c:	fff7871b          	addiw	a4,a5,-1
ffffffffc0205850:	02e9a823          	sw	a4,48(s3)
        if (mm_count_dec(mm) == 0) {
ffffffffc0205854:	2c070263          	beqz	a4,ffffffffc0205b18 <do_execve+0x352>
        current->mm = NULL;  // 清空当前进程的内存管理结构体指针
ffffffffc0205858:	000db783          	ld	a5,0(s11)
ffffffffc020585c:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL) {
ffffffffc0205860:	9d5fb0ef          	jal	ra,ffffffffc0201234 <mm_create>
ffffffffc0205864:	84aa                	mv	s1,a0
ffffffffc0205866:	1c050b63          	beqz	a0,ffffffffc0205a3c <do_execve+0x276>
    if ((page = alloc_page()) == NULL) {
ffffffffc020586a:	4505                	li	a0,1
ffffffffc020586c:	bf1fd0ef          	jal	ra,ffffffffc020345c <alloc_pages>
ffffffffc0205870:	3a050763          	beqz	a0,ffffffffc0205c1e <do_execve+0x458>
    return page - pages + nbase;
ffffffffc0205874:	000adc97          	auipc	s9,0xad
ffffffffc0205878:	194c8c93          	addi	s9,s9,404 # ffffffffc02b2a08 <pages>
ffffffffc020587c:	000cb683          	ld	a3,0(s9)
    return KADDR(page2pa(page));
ffffffffc0205880:	000adc17          	auipc	s8,0xad
ffffffffc0205884:	180c0c13          	addi	s8,s8,384 # ffffffffc02b2a00 <npage>
    return page - pages + nbase;
ffffffffc0205888:	00003717          	auipc	a4,0x3
ffffffffc020588c:	43873703          	ld	a4,1080(a4) # ffffffffc0208cc0 <nbase>
ffffffffc0205890:	40d506b3          	sub	a3,a0,a3
ffffffffc0205894:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205896:	5afd                	li	s5,-1
ffffffffc0205898:	000c3783          	ld	a5,0(s8)
    return page - pages + nbase;
ffffffffc020589c:	96ba                	add	a3,a3,a4
ffffffffc020589e:	e83a                	sd	a4,16(sp)
    return KADDR(page2pa(page));
ffffffffc02058a0:	00cad713          	srli	a4,s5,0xc
ffffffffc02058a4:	ec3a                	sd	a4,24(sp)
ffffffffc02058a6:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02058a8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02058aa:	36f77e63          	bgeu	a4,a5,ffffffffc0205c26 <do_execve+0x460>
ffffffffc02058ae:	000adb17          	auipc	s6,0xad
ffffffffc02058b2:	16ab0b13          	addi	s6,s6,362 # ffffffffc02b2a18 <va_pa_offset>
ffffffffc02058b6:	000b3903          	ld	s2,0(s6)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc02058ba:	6605                	lui	a2,0x1
ffffffffc02058bc:	000ad597          	auipc	a1,0xad
ffffffffc02058c0:	13c5b583          	ld	a1,316(a1) # ffffffffc02b29f8 <boot_pgdir>
ffffffffc02058c4:	9936                	add	s2,s2,a3
ffffffffc02058c6:	854a                	mv	a0,s2
ffffffffc02058c8:	105000ef          	jal	ra,ffffffffc02061cc <memcpy>
    if (elf->e_magic != ELF_MAGIC) {
ffffffffc02058cc:	7782                	ld	a5,32(sp)
ffffffffc02058ce:	4398                	lw	a4,0(a5)
ffffffffc02058d0:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc02058d4:	0124bc23          	sd	s2,24(s1)
    if (elf->e_magic != ELF_MAGIC) {
ffffffffc02058d8:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b943f>
ffffffffc02058dc:	14f71663          	bne	a4,a5,ffffffffc0205a28 <do_execve+0x262>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02058e0:	7682                	ld	a3,32(sp)
ffffffffc02058e2:	0386d703          	lhu	a4,56(a3)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02058e6:	0206b983          	ld	s3,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02058ea:	00371793          	slli	a5,a4,0x3
ffffffffc02058ee:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02058f0:	99b6                	add	s3,s3,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02058f2:	078e                	slli	a5,a5,0x3
ffffffffc02058f4:	97ce                	add	a5,a5,s3
ffffffffc02058f6:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++) {
ffffffffc02058f8:	00f9fc63          	bgeu	s3,a5,ffffffffc0205910 <do_execve+0x14a>
        if (ph->p_type != ELF_PT_LOAD) {
ffffffffc02058fc:	0009a783          	lw	a5,0(s3)
ffffffffc0205900:	4705                	li	a4,1
ffffffffc0205902:	12e78f63          	beq	a5,a4,ffffffffc0205a40 <do_execve+0x27a>
    for (; ph < ph_end; ph++) {
ffffffffc0205906:	77a2                	ld	a5,40(sp)
ffffffffc0205908:	03898993          	addi	s3,s3,56
ffffffffc020590c:	fef9e8e3          	bltu	s3,a5,ffffffffc02058fc <do_execve+0x136>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) {
ffffffffc0205910:	4701                	li	a4,0
ffffffffc0205912:	46ad                	li	a3,11
ffffffffc0205914:	00100637          	lui	a2,0x100
ffffffffc0205918:	7ff005b7          	lui	a1,0x7ff00
ffffffffc020591c:	8526                	mv	a0,s1
ffffffffc020591e:	aeffb0ef          	jal	ra,ffffffffc020140c <mm_map>
ffffffffc0205922:	8a2a                	mv	s4,a0
ffffffffc0205924:	1e051063          	bnez	a0,ffffffffc0205b04 <do_execve+0x33e>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE , PTE_USER) != NULL);
ffffffffc0205928:	6c88                	ld	a0,24(s1)
ffffffffc020592a:	467d                	li	a2,31
ffffffffc020592c:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0205930:	998ff0ef          	jal	ra,ffffffffc0204ac8 <pgdir_alloc_page>
ffffffffc0205934:	38050163          	beqz	a0,ffffffffc0205cb6 <do_execve+0x4f0>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2*PGSIZE , PTE_USER) != NULL);
ffffffffc0205938:	6c88                	ld	a0,24(s1)
ffffffffc020593a:	467d                	li	a2,31
ffffffffc020593c:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0205940:	988ff0ef          	jal	ra,ffffffffc0204ac8 <pgdir_alloc_page>
ffffffffc0205944:	34050963          	beqz	a0,ffffffffc0205c96 <do_execve+0x4d0>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3*PGSIZE , PTE_USER) != NULL);
ffffffffc0205948:	6c88                	ld	a0,24(s1)
ffffffffc020594a:	467d                	li	a2,31
ffffffffc020594c:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0205950:	978ff0ef          	jal	ra,ffffffffc0204ac8 <pgdir_alloc_page>
ffffffffc0205954:	32050163          	beqz	a0,ffffffffc0205c76 <do_execve+0x4b0>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4*PGSIZE , PTE_USER) != NULL);
ffffffffc0205958:	6c88                	ld	a0,24(s1)
ffffffffc020595a:	467d                	li	a2,31
ffffffffc020595c:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0205960:	968ff0ef          	jal	ra,ffffffffc0204ac8 <pgdir_alloc_page>
ffffffffc0205964:	2e050963          	beqz	a0,ffffffffc0205c56 <do_execve+0x490>
    mm->mm_count += 1;
ffffffffc0205968:	589c                	lw	a5,48(s1)
    current->mm = mm;
ffffffffc020596a:	000db603          	ld	a2,0(s11)
    current->cr3 = PADDR(mm->pgdir);
ffffffffc020596e:	6c94                	ld	a3,24(s1)
ffffffffc0205970:	2785                	addiw	a5,a5,1
ffffffffc0205972:	d89c                	sw	a5,48(s1)
    current->mm = mm;
ffffffffc0205974:	f604                	sd	s1,40(a2)
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205976:	c02007b7          	lui	a5,0xc0200
ffffffffc020597a:	2cf6e263          	bltu	a3,a5,ffffffffc0205c3e <do_execve+0x478>
ffffffffc020597e:	000b3783          	ld	a5,0(s6)
ffffffffc0205982:	577d                	li	a4,-1
ffffffffc0205984:	177e                	slli	a4,a4,0x3f
ffffffffc0205986:	8e9d                	sub	a3,a3,a5
ffffffffc0205988:	00c6d793          	srli	a5,a3,0xc
ffffffffc020598c:	f654                	sd	a3,168(a2)
ffffffffc020598e:	8fd9                	or	a5,a5,a4
ffffffffc0205990:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0205994:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0205996:	4581                	li	a1,0
ffffffffc0205998:	12000613          	li	a2,288
ffffffffc020599c:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc020599e:	10043903          	ld	s2,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02059a2:	019000ef          	jal	ra,ffffffffc02061ba <memset>
    tf->epc = elf->e_entry;  // 设置程序入口点
ffffffffc02059a6:	7782                	ld	a5,32(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02059a8:	000db483          	ld	s1,0(s11)
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
ffffffffc02059ac:	edf97913          	andi	s2,s2,-289
    tf->epc = elf->e_entry;  // 设置程序入口点
ffffffffc02059b0:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;  // 设置用户栈顶
ffffffffc02059b2:	4785                	li	a5,1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02059b4:	0b448493          	addi	s1,s1,180
    tf->gpr.sp = USTACKTOP;  // 设置用户栈顶
ffffffffc02059b8:	07fe                	slli	a5,a5,0x1f
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02059ba:	4641                	li	a2,16
ffffffffc02059bc:	4581                	li	a1,0
    tf->gpr.sp = USTACKTOP;  // 设置用户栈顶
ffffffffc02059be:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;  // 设置程序入口点
ffffffffc02059c0:	10e43423          	sd	a4,264(s0)
    tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
ffffffffc02059c4:	11243023          	sd	s2,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc02059c8:	8526                	mv	a0,s1
ffffffffc02059ca:	7f0000ef          	jal	ra,ffffffffc02061ba <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc02059ce:	463d                	li	a2,15
ffffffffc02059d0:	180c                	addi	a1,sp,48
ffffffffc02059d2:	8526                	mv	a0,s1
ffffffffc02059d4:	7f8000ef          	jal	ra,ffffffffc02061cc <memcpy>
}
ffffffffc02059d8:	70aa                	ld	ra,168(sp)
ffffffffc02059da:	740a                	ld	s0,160(sp)
ffffffffc02059dc:	64ea                	ld	s1,152(sp)
ffffffffc02059de:	694a                	ld	s2,144(sp)
ffffffffc02059e0:	69aa                	ld	s3,136(sp)
ffffffffc02059e2:	7ae6                	ld	s5,120(sp)
ffffffffc02059e4:	7b46                	ld	s6,112(sp)
ffffffffc02059e6:	7ba6                	ld	s7,104(sp)
ffffffffc02059e8:	7c06                	ld	s8,96(sp)
ffffffffc02059ea:	6ce6                	ld	s9,88(sp)
ffffffffc02059ec:	6d46                	ld	s10,80(sp)
ffffffffc02059ee:	6da6                	ld	s11,72(sp)
ffffffffc02059f0:	8552                	mv	a0,s4
ffffffffc02059f2:	6a0a                	ld	s4,128(sp)
ffffffffc02059f4:	614d                	addi	sp,sp,176
ffffffffc02059f6:	8082                	ret
    memcpy(local_name, name, len);  // 将传入的程序名复制到 local_name 中
ffffffffc02059f8:	463d                	li	a2,15
ffffffffc02059fa:	85ca                	mv	a1,s2
ffffffffc02059fc:	1808                	addi	a0,sp,48
ffffffffc02059fe:	7ce000ef          	jal	ra,ffffffffc02061cc <memcpy>
    if (mm != NULL) {
ffffffffc0205a02:	e20993e3          	bnez	s3,ffffffffc0205828 <do_execve+0x62>
    if (current->mm != NULL) {
ffffffffc0205a06:	000db783          	ld	a5,0(s11)
ffffffffc0205a0a:	779c                	ld	a5,40(a5)
ffffffffc0205a0c:	e4078ae3          	beqz	a5,ffffffffc0205860 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0205a10:	00003617          	auipc	a2,0x3
ffffffffc0205a14:	be060613          	addi	a2,a2,-1056 # ffffffffc02085f0 <default_pmm_manager+0x8a8>
ffffffffc0205a18:	24300593          	li	a1,579
ffffffffc0205a1c:	00003517          	auipc	a0,0x3
ffffffffc0205a20:	9ec50513          	addi	a0,a0,-1556 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc0205a24:	fe4fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    put_pgdir(mm);  // 清理页目录
ffffffffc0205a28:	8526                	mv	a0,s1
ffffffffc0205a2a:	c1cff0ef          	jal	ra,ffffffffc0204e46 <put_pgdir>
    mm_destroy(mm);  // 销毁内存管理结构
ffffffffc0205a2e:	8526                	mv	a0,s1
ffffffffc0205a30:	98bfb0ef          	jal	ra,ffffffffc02013ba <mm_destroy>
        ret = -E_INVAL_ELF;  // 如果 ELF 魔数不匹配，返回无效 ELF 错误
ffffffffc0205a34:	5a61                	li	s4,-8
    do_exit(ret);
ffffffffc0205a36:	8552                	mv	a0,s4
ffffffffc0205a38:	94fff0ef          	jal	ra,ffffffffc0205386 <do_exit>
    int ret = -E_NO_MEM;  // 默认返回错误代码：内存不足
ffffffffc0205a3c:	5a71                	li	s4,-4
ffffffffc0205a3e:	bfe5                	j	ffffffffc0205a36 <do_execve+0x270>
        if (ph->p_filesz > ph->p_memsz) {
ffffffffc0205a40:	0289b603          	ld	a2,40(s3)
ffffffffc0205a44:	0209b783          	ld	a5,32(s3)
ffffffffc0205a48:	1cf66d63          	bltu	a2,a5,ffffffffc0205c22 <do_execve+0x45c>
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;  // 如果该段可执行
ffffffffc0205a4c:	0049a783          	lw	a5,4(s3)
ffffffffc0205a50:	0017f693          	andi	a3,a5,1
ffffffffc0205a54:	c291                	beqz	a3,ffffffffc0205a58 <do_execve+0x292>
ffffffffc0205a56:	4691                	li	a3,4
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE; // 如果该段可写
ffffffffc0205a58:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;  // 如果该段可读
ffffffffc0205a5c:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE; // 如果该段可写
ffffffffc0205a5e:	e779                	bnez	a4,ffffffffc0205b2c <do_execve+0x366>
        vm_flags = 0, perm = PTE_U | PTE_V;  // 默认用户可访问、有效
ffffffffc0205a60:	4d45                	li	s10,17
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;  // 如果该段可读
ffffffffc0205a62:	c781                	beqz	a5,ffffffffc0205a6a <do_execve+0x2a4>
ffffffffc0205a64:	0016e693          	ori	a3,a3,1
        if (vm_flags & VM_READ) perm |= PTE_R;
ffffffffc0205a68:	4d4d                	li	s10,19
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc0205a6a:	0026f793          	andi	a5,a3,2
ffffffffc0205a6e:	e3f1                	bnez	a5,ffffffffc0205b32 <do_execve+0x36c>
        if (vm_flags & VM_EXEC) perm |= PTE_X;
ffffffffc0205a70:	0046f793          	andi	a5,a3,4
ffffffffc0205a74:	c399                	beqz	a5,ffffffffc0205a7a <do_execve+0x2b4>
ffffffffc0205a76:	008d6d13          	ori	s10,s10,8
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) {
ffffffffc0205a7a:	0109b583          	ld	a1,16(s3)
ffffffffc0205a7e:	4701                	li	a4,0
ffffffffc0205a80:	8526                	mv	a0,s1
ffffffffc0205a82:	98bfb0ef          	jal	ra,ffffffffc020140c <mm_map>
ffffffffc0205a86:	8a2a                	mv	s4,a0
ffffffffc0205a88:	ed35                	bnez	a0,ffffffffc0205b04 <do_execve+0x33e>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205a8a:	0109bb83          	ld	s7,16(s3)
ffffffffc0205a8e:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0205a90:	0209ba03          	ld	s4,32(s3)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205a94:	0089b903          	ld	s2,8(s3)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205a98:	00fbfab3          	and	s5,s7,a5
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205a9c:	7782                	ld	a5,32(sp)
        end = ph->p_va + ph->p_filesz;
ffffffffc0205a9e:	9a5e                	add	s4,s4,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205aa0:	993e                	add	s2,s2,a5
        while (start < end) {
ffffffffc0205aa2:	054be963          	bltu	s7,s4,ffffffffc0205af4 <do_execve+0x32e>
ffffffffc0205aa6:	aa95                	j	ffffffffc0205c1a <do_execve+0x454>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205aa8:	6785                	lui	a5,0x1
ffffffffc0205aaa:	415b8533          	sub	a0,s7,s5
ffffffffc0205aae:	9abe                	add	s5,s5,a5
ffffffffc0205ab0:	417a8633          	sub	a2,s5,s7
            if (end < la) {
ffffffffc0205ab4:	015a7463          	bgeu	s4,s5,ffffffffc0205abc <do_execve+0x2f6>
                size -= la - end;
ffffffffc0205ab8:	417a0633          	sub	a2,s4,s7
    return page - pages + nbase;
ffffffffc0205abc:	000cb683          	ld	a3,0(s9)
ffffffffc0205ac0:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205ac2:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0205ac6:	40d406b3          	sub	a3,s0,a3
ffffffffc0205aca:	8699                	srai	a3,a3,0x6
ffffffffc0205acc:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205ace:	67e2                	ld	a5,24(sp)
ffffffffc0205ad0:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205ad4:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205ad6:	14b87863          	bgeu	a6,a1,ffffffffc0205c26 <do_execve+0x460>
ffffffffc0205ada:	000b3803          	ld	a6,0(s6)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205ade:	85ca                	mv	a1,s2
            start += size, from += size;
ffffffffc0205ae0:	9bb2                	add	s7,s7,a2
ffffffffc0205ae2:	96c2                	add	a3,a3,a6
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205ae4:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0205ae6:	e432                	sd	a2,8(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205ae8:	6e4000ef          	jal	ra,ffffffffc02061cc <memcpy>
            start += size, from += size;
ffffffffc0205aec:	6622                	ld	a2,8(sp)
ffffffffc0205aee:	9932                	add	s2,s2,a2
        while (start < end) {
ffffffffc0205af0:	054bf363          	bgeu	s7,s4,ffffffffc0205b36 <do_execve+0x370>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0205af4:	6c88                	ld	a0,24(s1)
ffffffffc0205af6:	866a                	mv	a2,s10
ffffffffc0205af8:	85d6                	mv	a1,s5
ffffffffc0205afa:	fcffe0ef          	jal	ra,ffffffffc0204ac8 <pgdir_alloc_page>
ffffffffc0205afe:	842a                	mv	s0,a0
ffffffffc0205b00:	f545                	bnez	a0,ffffffffc0205aa8 <do_execve+0x2e2>
        ret = -E_NO_MEM;
ffffffffc0205b02:	5a71                	li	s4,-4
    exit_mmap(mm);  // 清理内存映射
ffffffffc0205b04:	8526                	mv	a0,s1
ffffffffc0205b06:	a51fb0ef          	jal	ra,ffffffffc0201556 <exit_mmap>
    put_pgdir(mm);  // 清理页目录
ffffffffc0205b0a:	8526                	mv	a0,s1
ffffffffc0205b0c:	b3aff0ef          	jal	ra,ffffffffc0204e46 <put_pgdir>
    mm_destroy(mm);  // 销毁内存管理结构
ffffffffc0205b10:	8526                	mv	a0,s1
ffffffffc0205b12:	8a9fb0ef          	jal	ra,ffffffffc02013ba <mm_destroy>
    return ret;  // 返回处理结果
ffffffffc0205b16:	b705                	j	ffffffffc0205a36 <do_execve+0x270>
            exit_mmap(mm);   // 释放内存映射
ffffffffc0205b18:	854e                	mv	a0,s3
ffffffffc0205b1a:	a3dfb0ef          	jal	ra,ffffffffc0201556 <exit_mmap>
            put_pgdir(mm);   // 释放页目录
ffffffffc0205b1e:	854e                	mv	a0,s3
ffffffffc0205b20:	b26ff0ef          	jal	ra,ffffffffc0204e46 <put_pgdir>
            mm_destroy(mm);  // 销毁内存管理结构体
ffffffffc0205b24:	854e                	mv	a0,s3
ffffffffc0205b26:	895fb0ef          	jal	ra,ffffffffc02013ba <mm_destroy>
ffffffffc0205b2a:	b33d                	j	ffffffffc0205858 <do_execve+0x92>
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE; // 如果该段可写
ffffffffc0205b2c:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;  // 如果该段可读
ffffffffc0205b30:	fb95                	bnez	a5,ffffffffc0205a64 <do_execve+0x29e>
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc0205b32:	4d5d                	li	s10,23
ffffffffc0205b34:	bf35                	j	ffffffffc0205a70 <do_execve+0x2aa>
        end = ph->p_va + ph->p_memsz;
ffffffffc0205b36:	0109b683          	ld	a3,16(s3)
ffffffffc0205b3a:	0289b903          	ld	s2,40(s3)
ffffffffc0205b3e:	9936                	add	s2,s2,a3
        if (start < la) {
ffffffffc0205b40:	075bfd63          	bgeu	s7,s5,ffffffffc0205bba <do_execve+0x3f4>
            if (start == end) {
ffffffffc0205b44:	dd7901e3          	beq	s2,s7,ffffffffc0205906 <do_execve+0x140>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205b48:	6785                	lui	a5,0x1
ffffffffc0205b4a:	00fb8533          	add	a0,s7,a5
ffffffffc0205b4e:	41550533          	sub	a0,a0,s5
                size -= la - end;
ffffffffc0205b52:	41790a33          	sub	s4,s2,s7
            if (end < la) {
ffffffffc0205b56:	0b597d63          	bgeu	s2,s5,ffffffffc0205c10 <do_execve+0x44a>
    return page - pages + nbase;
ffffffffc0205b5a:	000cb683          	ld	a3,0(s9)
ffffffffc0205b5e:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205b60:	000c3603          	ld	a2,0(s8)
    return page - pages + nbase;
ffffffffc0205b64:	40d406b3          	sub	a3,s0,a3
ffffffffc0205b68:	8699                	srai	a3,a3,0x6
ffffffffc0205b6a:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205b6c:	67e2                	ld	a5,24(sp)
ffffffffc0205b6e:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205b72:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205b74:	0ac5f963          	bgeu	a1,a2,ffffffffc0205c26 <do_execve+0x460>
ffffffffc0205b78:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205b7c:	8652                	mv	a2,s4
ffffffffc0205b7e:	4581                	li	a1,0
ffffffffc0205b80:	96c2                	add	a3,a3,a6
ffffffffc0205b82:	9536                	add	a0,a0,a3
ffffffffc0205b84:	636000ef          	jal	ra,ffffffffc02061ba <memset>
            start += size;
ffffffffc0205b88:	017a0733          	add	a4,s4,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0205b8c:	03597463          	bgeu	s2,s5,ffffffffc0205bb4 <do_execve+0x3ee>
ffffffffc0205b90:	d6e90be3          	beq	s2,a4,ffffffffc0205906 <do_execve+0x140>
ffffffffc0205b94:	00003697          	auipc	a3,0x3
ffffffffc0205b98:	a8468693          	addi	a3,a3,-1404 # ffffffffc0208618 <default_pmm_manager+0x8d0>
ffffffffc0205b9c:	00001617          	auipc	a2,0x1
ffffffffc0205ba0:	10460613          	addi	a2,a2,260 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0205ba4:	2ac00593          	li	a1,684
ffffffffc0205ba8:	00003517          	auipc	a0,0x3
ffffffffc0205bac:	86050513          	addi	a0,a0,-1952 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc0205bb0:	e58fa0ef          	jal	ra,ffffffffc0200208 <__panic>
ffffffffc0205bb4:	ff5710e3          	bne	a4,s5,ffffffffc0205b94 <do_execve+0x3ce>
ffffffffc0205bb8:	8bd6                	mv	s7,s5
        while (start < end) {
ffffffffc0205bba:	d52bf6e3          	bgeu	s7,s2,ffffffffc0205906 <do_execve+0x140>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0205bbe:	6c88                	ld	a0,24(s1)
ffffffffc0205bc0:	866a                	mv	a2,s10
ffffffffc0205bc2:	85d6                	mv	a1,s5
ffffffffc0205bc4:	f05fe0ef          	jal	ra,ffffffffc0204ac8 <pgdir_alloc_page>
ffffffffc0205bc8:	842a                	mv	s0,a0
ffffffffc0205bca:	dd05                	beqz	a0,ffffffffc0205b02 <do_execve+0x33c>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205bcc:	6785                	lui	a5,0x1
ffffffffc0205bce:	415b8533          	sub	a0,s7,s5
ffffffffc0205bd2:	9abe                	add	s5,s5,a5
ffffffffc0205bd4:	417a8633          	sub	a2,s5,s7
            if (end < la) {
ffffffffc0205bd8:	01597463          	bgeu	s2,s5,ffffffffc0205be0 <do_execve+0x41a>
                size -= la - end;
ffffffffc0205bdc:	41790633          	sub	a2,s2,s7
    return page - pages + nbase;
ffffffffc0205be0:	000cb683          	ld	a3,0(s9)
ffffffffc0205be4:	67c2                	ld	a5,16(sp)
    return KADDR(page2pa(page));
ffffffffc0205be6:	000c3583          	ld	a1,0(s8)
    return page - pages + nbase;
ffffffffc0205bea:	40d406b3          	sub	a3,s0,a3
ffffffffc0205bee:	8699                	srai	a3,a3,0x6
ffffffffc0205bf0:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0205bf2:	67e2                	ld	a5,24(sp)
ffffffffc0205bf4:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205bf8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205bfa:	02b87663          	bgeu	a6,a1,ffffffffc0205c26 <do_execve+0x460>
ffffffffc0205bfe:	000b3803          	ld	a6,0(s6)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205c02:	4581                	li	a1,0
            start += size;
ffffffffc0205c04:	9bb2                	add	s7,s7,a2
ffffffffc0205c06:	96c2                	add	a3,a3,a6
            memset(page2kva(page) + off, 0, size);
ffffffffc0205c08:	9536                	add	a0,a0,a3
ffffffffc0205c0a:	5b0000ef          	jal	ra,ffffffffc02061ba <memset>
ffffffffc0205c0e:	b775                	j	ffffffffc0205bba <do_execve+0x3f4>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205c10:	417a8a33          	sub	s4,s5,s7
ffffffffc0205c14:	b799                	j	ffffffffc0205b5a <do_execve+0x394>
        return -E_INVAL;  // 如果程序名无效，返回无效参数错误
ffffffffc0205c16:	5a75                	li	s4,-3
ffffffffc0205c18:	b3c1                	j	ffffffffc02059d8 <do_execve+0x212>
        while (start < end) {
ffffffffc0205c1a:	86de                	mv	a3,s7
ffffffffc0205c1c:	bf39                	j	ffffffffc0205b3a <do_execve+0x374>
    int ret = -E_NO_MEM;  // 默认返回错误代码：内存不足
ffffffffc0205c1e:	5a71                	li	s4,-4
ffffffffc0205c20:	bdc5                	j	ffffffffc0205b10 <do_execve+0x34a>
            ret = -E_INVAL_ELF;  // 文件大小大于内存大小无效
ffffffffc0205c22:	5a61                	li	s4,-8
ffffffffc0205c24:	b5c5                	j	ffffffffc0205b04 <do_execve+0x33e>
ffffffffc0205c26:	00002617          	auipc	a2,0x2
ffffffffc0205c2a:	82a60613          	addi	a2,a2,-2006 # ffffffffc0207450 <commands+0xbc0>
ffffffffc0205c2e:	06a00593          	li	a1,106
ffffffffc0205c32:	00002517          	auipc	a0,0x2
ffffffffc0205c36:	80e50513          	addi	a0,a0,-2034 # ffffffffc0207440 <commands+0xbb0>
ffffffffc0205c3a:	dcefa0ef          	jal	ra,ffffffffc0200208 <__panic>
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205c3e:	00002617          	auipc	a2,0x2
ffffffffc0205c42:	9ba60613          	addi	a2,a2,-1606 # ffffffffc02075f8 <commands+0xd68>
ffffffffc0205c46:	2cd00593          	li	a1,717
ffffffffc0205c4a:	00002517          	auipc	a0,0x2
ffffffffc0205c4e:	7be50513          	addi	a0,a0,1982 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc0205c52:	db6fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4*PGSIZE , PTE_USER) != NULL);
ffffffffc0205c56:	00003697          	auipc	a3,0x3
ffffffffc0205c5a:	ada68693          	addi	a3,a3,-1318 # ffffffffc0208730 <default_pmm_manager+0x9e8>
ffffffffc0205c5e:	00001617          	auipc	a2,0x1
ffffffffc0205c62:	04260613          	addi	a2,a2,66 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0205c66:	2c800593          	li	a1,712
ffffffffc0205c6a:	00002517          	auipc	a0,0x2
ffffffffc0205c6e:	79e50513          	addi	a0,a0,1950 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc0205c72:	d96fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3*PGSIZE , PTE_USER) != NULL);
ffffffffc0205c76:	00003697          	auipc	a3,0x3
ffffffffc0205c7a:	a7268693          	addi	a3,a3,-1422 # ffffffffc02086e8 <default_pmm_manager+0x9a0>
ffffffffc0205c7e:	00001617          	auipc	a2,0x1
ffffffffc0205c82:	02260613          	addi	a2,a2,34 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0205c86:	2c700593          	li	a1,711
ffffffffc0205c8a:	00002517          	auipc	a0,0x2
ffffffffc0205c8e:	77e50513          	addi	a0,a0,1918 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc0205c92:	d76fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2*PGSIZE , PTE_USER) != NULL);
ffffffffc0205c96:	00003697          	auipc	a3,0x3
ffffffffc0205c9a:	a0a68693          	addi	a3,a3,-1526 # ffffffffc02086a0 <default_pmm_manager+0x958>
ffffffffc0205c9e:	00001617          	auipc	a2,0x1
ffffffffc0205ca2:	00260613          	addi	a2,a2,2 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0205ca6:	2c600593          	li	a1,710
ffffffffc0205caa:	00002517          	auipc	a0,0x2
ffffffffc0205cae:	75e50513          	addi	a0,a0,1886 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc0205cb2:	d56fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE , PTE_USER) != NULL);
ffffffffc0205cb6:	00003697          	auipc	a3,0x3
ffffffffc0205cba:	9a268693          	addi	a3,a3,-1630 # ffffffffc0208658 <default_pmm_manager+0x910>
ffffffffc0205cbe:	00001617          	auipc	a2,0x1
ffffffffc0205cc2:	fe260613          	addi	a2,a2,-30 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0205cc6:	2c500593          	li	a1,709
ffffffffc0205cca:	00002517          	auipc	a0,0x2
ffffffffc0205cce:	73e50513          	addi	a0,a0,1854 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc0205cd2:	d36fa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0205cd6 <do_yield>:
    current->need_resched = 1;  // 设置当前进程需要重新调度
ffffffffc0205cd6:	000ad797          	auipc	a5,0xad
ffffffffc0205cda:	d4a7b783          	ld	a5,-694(a5) # ffffffffc02b2a20 <current>
ffffffffc0205cde:	4705                	li	a4,1
ffffffffc0205ce0:	ef98                	sd	a4,24(a5)
}
ffffffffc0205ce2:	4501                	li	a0,0
ffffffffc0205ce4:	8082                	ret

ffffffffc0205ce6 <do_wait>:
do_wait(int pid, int *code_store) {
ffffffffc0205ce6:	1101                	addi	sp,sp,-32
ffffffffc0205ce8:	e822                	sd	s0,16(sp)
ffffffffc0205cea:	e426                	sd	s1,8(sp)
ffffffffc0205cec:	ec06                	sd	ra,24(sp)
ffffffffc0205cee:	842e                	mv	s0,a1
ffffffffc0205cf0:	84aa                	mv	s1,a0
    if (code_store != NULL) {
ffffffffc0205cf2:	c999                	beqz	a1,ffffffffc0205d08 <do_wait+0x22>
    struct mm_struct *mm = current->mm;
ffffffffc0205cf4:	000ad797          	auipc	a5,0xad
ffffffffc0205cf8:	d2c7b783          	ld	a5,-724(a5) # ffffffffc02b2a20 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1)) {
ffffffffc0205cfc:	7788                	ld	a0,40(a5)
ffffffffc0205cfe:	4685                	li	a3,1
ffffffffc0205d00:	4611                	li	a2,4
ffffffffc0205d02:	f01fb0ef          	jal	ra,ffffffffc0201c02 <user_mem_check>
ffffffffc0205d06:	c909                	beqz	a0,ffffffffc0205d18 <do_wait+0x32>
ffffffffc0205d08:	85a2                	mv	a1,s0
}
ffffffffc0205d0a:	6442                	ld	s0,16(sp)
ffffffffc0205d0c:	60e2                	ld	ra,24(sp)
ffffffffc0205d0e:	8526                	mv	a0,s1
ffffffffc0205d10:	64a2                	ld	s1,8(sp)
ffffffffc0205d12:	6105                	addi	sp,sp,32
ffffffffc0205d14:	fbcff06f          	j	ffffffffc02054d0 <do_wait.part.0>
ffffffffc0205d18:	60e2                	ld	ra,24(sp)
ffffffffc0205d1a:	6442                	ld	s0,16(sp)
ffffffffc0205d1c:	64a2                	ld	s1,8(sp)
ffffffffc0205d1e:	5575                	li	a0,-3
ffffffffc0205d20:	6105                	addi	sp,sp,32
ffffffffc0205d22:	8082                	ret

ffffffffc0205d24 <do_kill>:
do_kill(int pid) {
ffffffffc0205d24:	1141                	addi	sp,sp,-16
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205d26:	6789                	lui	a5,0x2
do_kill(int pid) {
ffffffffc0205d28:	e406                	sd	ra,8(sp)
ffffffffc0205d2a:	e022                	sd	s0,0(sp)
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205d2c:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205d30:	17f9                	addi	a5,a5,-2
ffffffffc0205d32:	02e7e963          	bltu	a5,a4,ffffffffc0205d64 <do_kill+0x40>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205d36:	842a                	mv	s0,a0
ffffffffc0205d38:	45a9                	li	a1,10
ffffffffc0205d3a:	2501                	sext.w	a0,a0
ffffffffc0205d3c:	097000ef          	jal	ra,ffffffffc02065d2 <hash32>
ffffffffc0205d40:	02051793          	slli	a5,a0,0x20
ffffffffc0205d44:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0205d48:	000a9797          	auipc	a5,0xa9
ffffffffc0205d4c:	c5078793          	addi	a5,a5,-944 # ffffffffc02ae998 <hash_list>
ffffffffc0205d50:	953e                	add	a0,a0,a5
ffffffffc0205d52:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list) {
ffffffffc0205d54:	a029                	j	ffffffffc0205d5e <do_kill+0x3a>
            if (proc->pid == pid) {
ffffffffc0205d56:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0205d5a:	00870b63          	beq	a4,s0,ffffffffc0205d70 <do_kill+0x4c>
ffffffffc0205d5e:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0205d60:	fef51be3          	bne	a0,a5,ffffffffc0205d56 <do_kill+0x32>
    return -E_INVAL;  // 如果未找到该进程，返回无效的 pid 错误
ffffffffc0205d64:	5475                	li	s0,-3
}
ffffffffc0205d66:	60a2                	ld	ra,8(sp)
ffffffffc0205d68:	8522                	mv	a0,s0
ffffffffc0205d6a:	6402                	ld	s0,0(sp)
ffffffffc0205d6c:	0141                	addi	sp,sp,16
ffffffffc0205d6e:	8082                	ret
        if (!(proc->flags & PF_EXITING)) {
ffffffffc0205d70:	fd87a703          	lw	a4,-40(a5)
ffffffffc0205d74:	00177693          	andi	a3,a4,1
ffffffffc0205d78:	e295                	bnez	a3,ffffffffc0205d9c <do_kill+0x78>
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205d7a:	4bd4                	lw	a3,20(a5)
            proc->flags |= PF_EXITING;  // 将该进程的 flags 设置为 PF_EXITING，标记为退出中
ffffffffc0205d7c:	00176713          	ori	a4,a4,1
ffffffffc0205d80:	fce7ac23          	sw	a4,-40(a5)
            return 0;  // 返回 0，表示成功标记进程为退出状态
ffffffffc0205d84:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205d86:	fe06d0e3          	bgez	a3,ffffffffc0205d66 <do_kill+0x42>
                wakeup_proc(proc);
ffffffffc0205d8a:	f2878513          	addi	a0,a5,-216
ffffffffc0205d8e:	1c4000ef          	jal	ra,ffffffffc0205f52 <wakeup_proc>
}
ffffffffc0205d92:	60a2                	ld	ra,8(sp)
ffffffffc0205d94:	8522                	mv	a0,s0
ffffffffc0205d96:	6402                	ld	s0,0(sp)
ffffffffc0205d98:	0141                	addi	sp,sp,16
ffffffffc0205d9a:	8082                	ret
        return -E_KILLED;  // 如果进程已经在退出状态，返回进程已终止错误
ffffffffc0205d9c:	545d                	li	s0,-9
ffffffffc0205d9e:	b7e1                	j	ffffffffc0205d66 <do_kill+0x42>

ffffffffc0205da0 <proc_init>:
// 该函数负责设置进程管理系统并启动内核线程。它包括以下步骤：
// 1. 初始化进程链表。
// 2. 创建一个名为 idleproc 的内核线程作为系统空闲线程。
// 3. 启动 init_main 内核线程，进一步启动用户进程。
void
proc_init(void) {
ffffffffc0205da0:	1101                	addi	sp,sp,-32
ffffffffc0205da2:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0205da4:	000ad797          	auipc	a5,0xad
ffffffffc0205da8:	bf478793          	addi	a5,a5,-1036 # ffffffffc02b2998 <proc_list>
ffffffffc0205dac:	ec06                	sd	ra,24(sp)
ffffffffc0205dae:	e822                	sd	s0,16(sp)
ffffffffc0205db0:	e04a                	sd	s2,0(sp)
ffffffffc0205db2:	000a9497          	auipc	s1,0xa9
ffffffffc0205db6:	be648493          	addi	s1,s1,-1050 # ffffffffc02ae998 <hash_list>
ffffffffc0205dba:	e79c                	sd	a5,8(a5)
ffffffffc0205dbc:	e39c                	sd	a5,0(a5)
    int i;

    // 初始化进程链表
    list_init(&proc_list);
    // 初始化散列表
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
ffffffffc0205dbe:	000ad717          	auipc	a4,0xad
ffffffffc0205dc2:	bda70713          	addi	a4,a4,-1062 # ffffffffc02b2998 <proc_list>
ffffffffc0205dc6:	87a6                	mv	a5,s1
ffffffffc0205dc8:	e79c                	sd	a5,8(a5)
ffffffffc0205dca:	e39c                	sd	a5,0(a5)
ffffffffc0205dcc:	07c1                	addi	a5,a5,16
ffffffffc0205dce:	fef71de3          	bne	a4,a5,ffffffffc0205dc8 <proc_init+0x28>
        list_init(hash_list + i);
    }

    // 为 idleproc 分配进程结构
    if ((idleproc = alloc_proc()) == NULL) {
ffffffffc0205dd2:	f77fe0ef          	jal	ra,ffffffffc0204d48 <alloc_proc>
ffffffffc0205dd6:	000ad917          	auipc	s2,0xad
ffffffffc0205dda:	c5290913          	addi	s2,s2,-942 # ffffffffc02b2a28 <idleproc>
ffffffffc0205dde:	00a93023          	sd	a0,0(s2)
ffffffffc0205de2:	0e050f63          	beqz	a0,ffffffffc0205ee0 <proc_init+0x140>
        panic("cannot alloc idleproc.\n");
    }

    // 设置 idleproc 的属性
    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0205de6:	4789                	li	a5,2
ffffffffc0205de8:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;  // 设置空闲进程的内核栈
ffffffffc0205dea:	00003797          	auipc	a5,0x3
ffffffffc0205dee:	21678793          	addi	a5,a5,534 # ffffffffc0209000 <bootstack>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205df2:	0b450413          	addi	s0,a0,180
    idleproc->kstack = (uintptr_t)bootstack;  // 设置空闲进程的内核栈
ffffffffc0205df6:	e91c                	sd	a5,16(a0)
    idleproc->need_resched = 1;  // 标记需要调度
ffffffffc0205df8:	4785                	li	a5,1
ffffffffc0205dfa:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205dfc:	4641                	li	a2,16
ffffffffc0205dfe:	4581                	li	a1,0
ffffffffc0205e00:	8522                	mv	a0,s0
ffffffffc0205e02:	3b8000ef          	jal	ra,ffffffffc02061ba <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205e06:	463d                	li	a2,15
ffffffffc0205e08:	00003597          	auipc	a1,0x3
ffffffffc0205e0c:	98858593          	addi	a1,a1,-1656 # ffffffffc0208790 <default_pmm_manager+0xa48>
ffffffffc0205e10:	8522                	mv	a0,s0
ffffffffc0205e12:	3ba000ef          	jal	ra,ffffffffc02061cc <memcpy>
    set_proc_name(idleproc, "idle");  // 设置进程名称为 "idle"
    nr_process ++;  // 系统进程数加 1
ffffffffc0205e16:	000ad717          	auipc	a4,0xad
ffffffffc0205e1a:	c2270713          	addi	a4,a4,-990 # ffffffffc02b2a38 <nr_process>
ffffffffc0205e1e:	431c                	lw	a5,0(a4)

    // 当前进程是 idleproc
    current = idleproc;
ffffffffc0205e20:	00093683          	ld	a3,0(s2)

    // 创建 init_main 内核线程
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205e24:	4601                	li	a2,0
    nr_process ++;  // 系统进程数加 1
ffffffffc0205e26:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205e28:	4581                	li	a1,0
ffffffffc0205e2a:	00000517          	auipc	a0,0x0
ffffffffc0205e2e:	87850513          	addi	a0,a0,-1928 # ffffffffc02056a2 <init_main>
    nr_process ++;  // 系统进程数加 1
ffffffffc0205e32:	c31c                	sw	a5,0(a4)
    current = idleproc;
ffffffffc0205e34:	000ad797          	auipc	a5,0xad
ffffffffc0205e38:	bed7b623          	sd	a3,-1044(a5) # ffffffffc02b2a20 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205e3c:	cfaff0ef          	jal	ra,ffffffffc0205336 <kernel_thread>
ffffffffc0205e40:	842a                	mv	s0,a0
    if (pid <= 0) {
ffffffffc0205e42:	08a05363          	blez	a0,ffffffffc0205ec8 <proc_init+0x128>
    if (0 < pid && pid < MAX_PID) {
ffffffffc0205e46:	6789                	lui	a5,0x2
ffffffffc0205e48:	fff5071b          	addiw	a4,a0,-1
ffffffffc0205e4c:	17f9                	addi	a5,a5,-2
ffffffffc0205e4e:	2501                	sext.w	a0,a0
ffffffffc0205e50:	02e7e363          	bltu	a5,a4,ffffffffc0205e76 <proc_init+0xd6>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205e54:	45a9                	li	a1,10
ffffffffc0205e56:	77c000ef          	jal	ra,ffffffffc02065d2 <hash32>
ffffffffc0205e5a:	02051793          	slli	a5,a0,0x20
ffffffffc0205e5e:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0205e62:	96a6                	add	a3,a3,s1
ffffffffc0205e64:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list) {
ffffffffc0205e66:	a029                	j	ffffffffc0205e70 <proc_init+0xd0>
            if (proc->pid == pid) {
ffffffffc0205e68:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7ca4>
ffffffffc0205e6c:	04870b63          	beq	a4,s0,ffffffffc0205ec2 <proc_init+0x122>
    return listelm->next;
ffffffffc0205e70:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0205e72:	fef69be3          	bne	a3,a5,ffffffffc0205e68 <proc_init+0xc8>
    return NULL;
ffffffffc0205e76:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205e78:	0b478493          	addi	s1,a5,180
ffffffffc0205e7c:	4641                	li	a2,16
ffffffffc0205e7e:	4581                	li	a1,0
        panic("create init_main failed.\n");
    }

    // 获取 initproc 对应的进程结构，并设置进程名
    initproc = find_proc(pid);
ffffffffc0205e80:	000ad417          	auipc	s0,0xad
ffffffffc0205e84:	bb040413          	addi	s0,s0,-1104 # ffffffffc02b2a30 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205e88:	8526                	mv	a0,s1
    initproc = find_proc(pid);
ffffffffc0205e8a:	e01c                	sd	a5,0(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205e8c:	32e000ef          	jal	ra,ffffffffc02061ba <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205e90:	463d                	li	a2,15
ffffffffc0205e92:	00003597          	auipc	a1,0x3
ffffffffc0205e96:	92658593          	addi	a1,a1,-1754 # ffffffffc02087b8 <default_pmm_manager+0xa70>
ffffffffc0205e9a:	8526                	mv	a0,s1
ffffffffc0205e9c:	330000ef          	jal	ra,ffffffffc02061cc <memcpy>
    set_proc_name(initproc, "init");

    // 检查 idleproc 和 initproc 是否正确初始化
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205ea0:	00093783          	ld	a5,0(s2)
ffffffffc0205ea4:	cbb5                	beqz	a5,ffffffffc0205f18 <proc_init+0x178>
ffffffffc0205ea6:	43dc                	lw	a5,4(a5)
ffffffffc0205ea8:	eba5                	bnez	a5,ffffffffc0205f18 <proc_init+0x178>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205eaa:	601c                	ld	a5,0(s0)
ffffffffc0205eac:	c7b1                	beqz	a5,ffffffffc0205ef8 <proc_init+0x158>
ffffffffc0205eae:	43d8                	lw	a4,4(a5)
ffffffffc0205eb0:	4785                	li	a5,1
ffffffffc0205eb2:	04f71363          	bne	a4,a5,ffffffffc0205ef8 <proc_init+0x158>
}
ffffffffc0205eb6:	60e2                	ld	ra,24(sp)
ffffffffc0205eb8:	6442                	ld	s0,16(sp)
ffffffffc0205eba:	64a2                	ld	s1,8(sp)
ffffffffc0205ebc:	6902                	ld	s2,0(sp)
ffffffffc0205ebe:	6105                	addi	sp,sp,32
ffffffffc0205ec0:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205ec2:	f2878793          	addi	a5,a5,-216
ffffffffc0205ec6:	bf4d                	j	ffffffffc0205e78 <proc_init+0xd8>
        panic("create init_main failed.\n");
ffffffffc0205ec8:	00003617          	auipc	a2,0x3
ffffffffc0205ecc:	8d060613          	addi	a2,a2,-1840 # ffffffffc0208798 <default_pmm_manager+0xa50>
ffffffffc0205ed0:	42300593          	li	a1,1059
ffffffffc0205ed4:	00002517          	auipc	a0,0x2
ffffffffc0205ed8:	53450513          	addi	a0,a0,1332 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc0205edc:	b2cfa0ef          	jal	ra,ffffffffc0200208 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205ee0:	00003617          	auipc	a2,0x3
ffffffffc0205ee4:	89860613          	addi	a2,a2,-1896 # ffffffffc0208778 <default_pmm_manager+0xa30>
ffffffffc0205ee8:	41200593          	li	a1,1042
ffffffffc0205eec:	00002517          	auipc	a0,0x2
ffffffffc0205ef0:	51c50513          	addi	a0,a0,1308 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc0205ef4:	b14fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205ef8:	00003697          	auipc	a3,0x3
ffffffffc0205efc:	8f068693          	addi	a3,a3,-1808 # ffffffffc02087e8 <default_pmm_manager+0xaa0>
ffffffffc0205f00:	00001617          	auipc	a2,0x1
ffffffffc0205f04:	da060613          	addi	a2,a2,-608 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0205f08:	42c00593          	li	a1,1068
ffffffffc0205f0c:	00002517          	auipc	a0,0x2
ffffffffc0205f10:	4fc50513          	addi	a0,a0,1276 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc0205f14:	af4fa0ef          	jal	ra,ffffffffc0200208 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205f18:	00003697          	auipc	a3,0x3
ffffffffc0205f1c:	8a868693          	addi	a3,a3,-1880 # ffffffffc02087c0 <default_pmm_manager+0xa78>
ffffffffc0205f20:	00001617          	auipc	a2,0x1
ffffffffc0205f24:	d8060613          	addi	a2,a2,-640 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0205f28:	42b00593          	li	a1,1067
ffffffffc0205f2c:	00002517          	auipc	a0,0x2
ffffffffc0205f30:	4dc50513          	addi	a0,a0,1244 # ffffffffc0208408 <default_pmm_manager+0x6c0>
ffffffffc0205f34:	ad4fa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0205f38 <cpu_idle>:

// cpu_idle - 当 kern_init 函数执行完成后，空闲进程 idleproc 将持续调用该函数。
// 该函数会在无限循环中等待调度，如果当前进程需要调度，则调用 `schedule`。
void
cpu_idle(void) {
ffffffffc0205f38:	1141                	addi	sp,sp,-16
ffffffffc0205f3a:	e022                	sd	s0,0(sp)
ffffffffc0205f3c:	e406                	sd	ra,8(sp)
ffffffffc0205f3e:	000ad417          	auipc	s0,0xad
ffffffffc0205f42:	ae240413          	addi	s0,s0,-1310 # ffffffffc02b2a20 <current>
    while (1) {
        if (current->need_resched) {  // 如果需要调度，调用调度函数
ffffffffc0205f46:	6018                	ld	a4,0(s0)
ffffffffc0205f48:	6f1c                	ld	a5,24(a4)
ffffffffc0205f4a:	dffd                	beqz	a5,ffffffffc0205f48 <cpu_idle+0x10>
            schedule();
ffffffffc0205f4c:	086000ef          	jal	ra,ffffffffc0205fd2 <schedule>
ffffffffc0205f50:	bfdd                	j	ffffffffc0205f46 <cpu_idle+0xe>

ffffffffc0205f52 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205f52:	4118                	lw	a4,0(a0)
wakeup_proc(struct proc_struct *proc) {
ffffffffc0205f54:	1101                	addi	sp,sp,-32
ffffffffc0205f56:	ec06                	sd	ra,24(sp)
ffffffffc0205f58:	e822                	sd	s0,16(sp)
ffffffffc0205f5a:	e426                	sd	s1,8(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205f5c:	478d                	li	a5,3
ffffffffc0205f5e:	04f70b63          	beq	a4,a5,ffffffffc0205fb4 <wakeup_proc+0x62>
ffffffffc0205f62:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205f64:	100027f3          	csrr	a5,sstatus
ffffffffc0205f68:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205f6a:	4481                	li	s1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205f6c:	ef9d                	bnez	a5,ffffffffc0205faa <wakeup_proc+0x58>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE) {
ffffffffc0205f6e:	4789                	li	a5,2
ffffffffc0205f70:	02f70163          	beq	a4,a5,ffffffffc0205f92 <wakeup_proc+0x40>
            proc->state = PROC_RUNNABLE;
ffffffffc0205f74:	c01c                	sw	a5,0(s0)
            proc->wait_state = 0;
ffffffffc0205f76:	0e042623          	sw	zero,236(s0)
    if (flag) {
ffffffffc0205f7a:	e491                	bnez	s1,ffffffffc0205f86 <wakeup_proc+0x34>
        else {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205f7c:	60e2                	ld	ra,24(sp)
ffffffffc0205f7e:	6442                	ld	s0,16(sp)
ffffffffc0205f80:	64a2                	ld	s1,8(sp)
ffffffffc0205f82:	6105                	addi	sp,sp,32
ffffffffc0205f84:	8082                	ret
ffffffffc0205f86:	6442                	ld	s0,16(sp)
ffffffffc0205f88:	60e2                	ld	ra,24(sp)
ffffffffc0205f8a:	64a2                	ld	s1,8(sp)
ffffffffc0205f8c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205f8e:	eb4fa06f          	j	ffffffffc0200642 <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205f92:	00003617          	auipc	a2,0x3
ffffffffc0205f96:	8b660613          	addi	a2,a2,-1866 # ffffffffc0208848 <default_pmm_manager+0xb00>
ffffffffc0205f9a:	45c9                	li	a1,18
ffffffffc0205f9c:	00003517          	auipc	a0,0x3
ffffffffc0205fa0:	89450513          	addi	a0,a0,-1900 # ffffffffc0208830 <default_pmm_manager+0xae8>
ffffffffc0205fa4:	accfa0ef          	jal	ra,ffffffffc0200270 <__warn>
ffffffffc0205fa8:	bfc9                	j	ffffffffc0205f7a <wakeup_proc+0x28>
        intr_disable();
ffffffffc0205faa:	e9efa0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        if (proc->state != PROC_RUNNABLE) {
ffffffffc0205fae:	4018                	lw	a4,0(s0)
        return 1;
ffffffffc0205fb0:	4485                	li	s1,1
ffffffffc0205fb2:	bf75                	j	ffffffffc0205f6e <wakeup_proc+0x1c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205fb4:	00003697          	auipc	a3,0x3
ffffffffc0205fb8:	85c68693          	addi	a3,a3,-1956 # ffffffffc0208810 <default_pmm_manager+0xac8>
ffffffffc0205fbc:	00001617          	auipc	a2,0x1
ffffffffc0205fc0:	ce460613          	addi	a2,a2,-796 # ffffffffc0206ca0 <commands+0x410>
ffffffffc0205fc4:	45a5                	li	a1,9
ffffffffc0205fc6:	00003517          	auipc	a0,0x3
ffffffffc0205fca:	86a50513          	addi	a0,a0,-1942 # ffffffffc0208830 <default_pmm_manager+0xae8>
ffffffffc0205fce:	a3afa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc0205fd2 <schedule>:

void
schedule(void) {
ffffffffc0205fd2:	1141                	addi	sp,sp,-16
ffffffffc0205fd4:	e406                	sd	ra,8(sp)
ffffffffc0205fd6:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205fd8:	100027f3          	csrr	a5,sstatus
ffffffffc0205fdc:	8b89                	andi	a5,a5,2
ffffffffc0205fde:	4401                	li	s0,0
ffffffffc0205fe0:	efbd                	bnez	a5,ffffffffc020605e <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205fe2:	000ad897          	auipc	a7,0xad
ffffffffc0205fe6:	a3e8b883          	ld	a7,-1474(a7) # ffffffffc02b2a20 <current>
ffffffffc0205fea:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205fee:	000ad517          	auipc	a0,0xad
ffffffffc0205ff2:	a3a53503          	ld	a0,-1478(a0) # ffffffffc02b2a28 <idleproc>
ffffffffc0205ff6:	04a88e63          	beq	a7,a0,ffffffffc0206052 <schedule+0x80>
ffffffffc0205ffa:	0c888693          	addi	a3,a7,200
ffffffffc0205ffe:	000ad617          	auipc	a2,0xad
ffffffffc0206002:	99a60613          	addi	a2,a2,-1638 # ffffffffc02b2998 <proc_list>
        le = last;
ffffffffc0206006:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0206008:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc020600a:	4809                	li	a6,2
ffffffffc020600c:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc020600e:	00c78863          	beq	a5,a2,ffffffffc020601e <schedule+0x4c>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0206012:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0206016:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc020601a:	03070163          	beq	a4,a6,ffffffffc020603c <schedule+0x6a>
                    break;
                }
            }
        } while (le != last);
ffffffffc020601e:	fef697e3          	bne	a3,a5,ffffffffc020600c <schedule+0x3a>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0206022:	ed89                	bnez	a1,ffffffffc020603c <schedule+0x6a>
            next = idleproc;
        }
        next->runs ++;
ffffffffc0206024:	451c                	lw	a5,8(a0)
ffffffffc0206026:	2785                	addiw	a5,a5,1
ffffffffc0206028:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc020602a:	00a88463          	beq	a7,a0,ffffffffc0206032 <schedule+0x60>
            proc_run(next);
ffffffffc020602e:	e8ffe0ef          	jal	ra,ffffffffc0204ebc <proc_run>
    if (flag) {
ffffffffc0206032:	e819                	bnez	s0,ffffffffc0206048 <schedule+0x76>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0206034:	60a2                	ld	ra,8(sp)
ffffffffc0206036:	6402                	ld	s0,0(sp)
ffffffffc0206038:	0141                	addi	sp,sp,16
ffffffffc020603a:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc020603c:	4198                	lw	a4,0(a1)
ffffffffc020603e:	4789                	li	a5,2
ffffffffc0206040:	fef712e3          	bne	a4,a5,ffffffffc0206024 <schedule+0x52>
ffffffffc0206044:	852e                	mv	a0,a1
ffffffffc0206046:	bff9                	j	ffffffffc0206024 <schedule+0x52>
}
ffffffffc0206048:	6402                	ld	s0,0(sp)
ffffffffc020604a:	60a2                	ld	ra,8(sp)
ffffffffc020604c:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020604e:	df4fa06f          	j	ffffffffc0200642 <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0206052:	000ad617          	auipc	a2,0xad
ffffffffc0206056:	94660613          	addi	a2,a2,-1722 # ffffffffc02b2998 <proc_list>
ffffffffc020605a:	86b2                	mv	a3,a2
ffffffffc020605c:	b76d                	j	ffffffffc0206006 <schedule+0x34>
        intr_disable();
ffffffffc020605e:	deafa0ef          	jal	ra,ffffffffc0200648 <intr_disable>
        return 1;
ffffffffc0206062:	4405                	li	s0,1
ffffffffc0206064:	bfbd                	j	ffffffffc0205fe2 <schedule+0x10>

ffffffffc0206066 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0206066:	000ad797          	auipc	a5,0xad
ffffffffc020606a:	9ba7b783          	ld	a5,-1606(a5) # ffffffffc02b2a20 <current>
}
ffffffffc020606e:	43c8                	lw	a0,4(a5)
ffffffffc0206070:	8082                	ret

ffffffffc0206072 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0206072:	4501                	li	a0,0
ffffffffc0206074:	8082                	ret

ffffffffc0206076 <sys_putc>:
    cputchar(c);
ffffffffc0206076:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0206078:	1141                	addi	sp,sp,-16
ffffffffc020607a:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc020607c:	886fa0ef          	jal	ra,ffffffffc0200102 <cputchar>
}
ffffffffc0206080:	60a2                	ld	ra,8(sp)
ffffffffc0206082:	4501                	li	a0,0
ffffffffc0206084:	0141                	addi	sp,sp,16
ffffffffc0206086:	8082                	ret

ffffffffc0206088 <sys_kill>:
    return do_kill(pid);
ffffffffc0206088:	4108                	lw	a0,0(a0)
ffffffffc020608a:	c9bff06f          	j	ffffffffc0205d24 <do_kill>

ffffffffc020608e <sys_yield>:
    return do_yield();
ffffffffc020608e:	c49ff06f          	j	ffffffffc0205cd6 <do_yield>

ffffffffc0206092 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0206092:	6d14                	ld	a3,24(a0)
ffffffffc0206094:	6910                	ld	a2,16(a0)
ffffffffc0206096:	650c                	ld	a1,8(a0)
ffffffffc0206098:	6108                	ld	a0,0(a0)
ffffffffc020609a:	f2cff06f          	j	ffffffffc02057c6 <do_execve>

ffffffffc020609e <sys_wait>:
    return do_wait(pid, store);
ffffffffc020609e:	650c                	ld	a1,8(a0)
ffffffffc02060a0:	4108                	lw	a0,0(a0)
ffffffffc02060a2:	c45ff06f          	j	ffffffffc0205ce6 <do_wait>

ffffffffc02060a6 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02060a6:	000ad797          	auipc	a5,0xad
ffffffffc02060aa:	97a7b783          	ld	a5,-1670(a5) # ffffffffc02b2a20 <current>
ffffffffc02060ae:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02060b0:	4501                	li	a0,0
ffffffffc02060b2:	6a0c                	ld	a1,16(a2)
ffffffffc02060b4:	e75fe06f          	j	ffffffffc0204f28 <do_fork>

ffffffffc02060b8 <sys_exit>:
    return do_exit(error_code);
ffffffffc02060b8:	4108                	lw	a0,0(a0)
ffffffffc02060ba:	accff06f          	j	ffffffffc0205386 <do_exit>

ffffffffc02060be <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc02060be:	715d                	addi	sp,sp,-80
ffffffffc02060c0:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc02060c2:	000ad497          	auipc	s1,0xad
ffffffffc02060c6:	95e48493          	addi	s1,s1,-1698 # ffffffffc02b2a20 <current>
ffffffffc02060ca:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc02060cc:	e0a2                	sd	s0,64(sp)
ffffffffc02060ce:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc02060d0:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc02060d2:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02060d4:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc02060d6:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02060da:	0327ee63          	bltu	a5,s2,ffffffffc0206116 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc02060de:	00391713          	slli	a4,s2,0x3
ffffffffc02060e2:	00002797          	auipc	a5,0x2
ffffffffc02060e6:	7ce78793          	addi	a5,a5,1998 # ffffffffc02088b0 <syscalls>
ffffffffc02060ea:	97ba                	add	a5,a5,a4
ffffffffc02060ec:	639c                	ld	a5,0(a5)
ffffffffc02060ee:	c785                	beqz	a5,ffffffffc0206116 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc02060f0:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc02060f2:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc02060f4:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc02060f6:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc02060f8:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc02060fa:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc02060fc:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc02060fe:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0206100:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc0206102:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0206104:	0028                	addi	a0,sp,8
ffffffffc0206106:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0206108:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020610a:	e828                	sd	a0,80(s0)
}
ffffffffc020610c:	6406                	ld	s0,64(sp)
ffffffffc020610e:	74e2                	ld	s1,56(sp)
ffffffffc0206110:	7942                	ld	s2,48(sp)
ffffffffc0206112:	6161                	addi	sp,sp,80
ffffffffc0206114:	8082                	ret
    print_trapframe(tf);
ffffffffc0206116:	8522                	mv	a0,s0
ffffffffc0206118:	f1efa0ef          	jal	ra,ffffffffc0200836 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc020611c:	609c                	ld	a5,0(s1)
ffffffffc020611e:	86ca                	mv	a3,s2
ffffffffc0206120:	00002617          	auipc	a2,0x2
ffffffffc0206124:	74860613          	addi	a2,a2,1864 # ffffffffc0208868 <default_pmm_manager+0xb20>
ffffffffc0206128:	43d8                	lw	a4,4(a5)
ffffffffc020612a:	06200593          	li	a1,98
ffffffffc020612e:	0b478793          	addi	a5,a5,180
ffffffffc0206132:	00002517          	auipc	a0,0x2
ffffffffc0206136:	76650513          	addi	a0,a0,1894 # ffffffffc0208898 <default_pmm_manager+0xb50>
ffffffffc020613a:	8cefa0ef          	jal	ra,ffffffffc0200208 <__panic>

ffffffffc020613e <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020613e:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0206142:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0206144:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0206146:	cb81                	beqz	a5,ffffffffc0206156 <strlen+0x18>
        cnt ++;
ffffffffc0206148:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc020614a:	00a707b3          	add	a5,a4,a0
ffffffffc020614e:	0007c783          	lbu	a5,0(a5)
ffffffffc0206152:	fbfd                	bnez	a5,ffffffffc0206148 <strlen+0xa>
ffffffffc0206154:	8082                	ret
    }
    return cnt;
}
ffffffffc0206156:	8082                	ret

ffffffffc0206158 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0206158:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc020615a:	e589                	bnez	a1,ffffffffc0206164 <strnlen+0xc>
ffffffffc020615c:	a811                	j	ffffffffc0206170 <strnlen+0x18>
        cnt ++;
ffffffffc020615e:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0206160:	00f58863          	beq	a1,a5,ffffffffc0206170 <strnlen+0x18>
ffffffffc0206164:	00f50733          	add	a4,a0,a5
ffffffffc0206168:	00074703          	lbu	a4,0(a4)
ffffffffc020616c:	fb6d                	bnez	a4,ffffffffc020615e <strnlen+0x6>
ffffffffc020616e:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0206170:	852e                	mv	a0,a1
ffffffffc0206172:	8082                	ret

ffffffffc0206174 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0206174:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0206176:	0005c703          	lbu	a4,0(a1)
ffffffffc020617a:	0785                	addi	a5,a5,1
ffffffffc020617c:	0585                	addi	a1,a1,1
ffffffffc020617e:	fee78fa3          	sb	a4,-1(a5)
ffffffffc0206182:	fb75                	bnez	a4,ffffffffc0206176 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc0206184:	8082                	ret

ffffffffc0206186 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0206186:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020618a:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020618e:	cb89                	beqz	a5,ffffffffc02061a0 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0206190:	0505                	addi	a0,a0,1
ffffffffc0206192:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0206194:	fee789e3          	beq	a5,a4,ffffffffc0206186 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0206198:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020619c:	9d19                	subw	a0,a0,a4
ffffffffc020619e:	8082                	ret
ffffffffc02061a0:	4501                	li	a0,0
ffffffffc02061a2:	bfed                	j	ffffffffc020619c <strcmp+0x16>

ffffffffc02061a4 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02061a4:	00054783          	lbu	a5,0(a0)
ffffffffc02061a8:	c799                	beqz	a5,ffffffffc02061b6 <strchr+0x12>
        if (*s == c) {
ffffffffc02061aa:	00f58763          	beq	a1,a5,ffffffffc02061b8 <strchr+0x14>
    while (*s != '\0') {
ffffffffc02061ae:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02061b2:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02061b4:	fbfd                	bnez	a5,ffffffffc02061aa <strchr+0x6>
    }
    return NULL;
ffffffffc02061b6:	4501                	li	a0,0
}
ffffffffc02061b8:	8082                	ret

ffffffffc02061ba <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02061ba:	ca01                	beqz	a2,ffffffffc02061ca <memset+0x10>
ffffffffc02061bc:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02061be:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02061c0:	0785                	addi	a5,a5,1
ffffffffc02061c2:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02061c6:	fec79de3          	bne	a5,a2,ffffffffc02061c0 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02061ca:	8082                	ret

ffffffffc02061cc <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02061cc:	ca19                	beqz	a2,ffffffffc02061e2 <memcpy+0x16>
ffffffffc02061ce:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02061d0:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02061d2:	0005c703          	lbu	a4,0(a1)
ffffffffc02061d6:	0585                	addi	a1,a1,1
ffffffffc02061d8:	0785                	addi	a5,a5,1
ffffffffc02061da:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc02061de:	fec59ae3          	bne	a1,a2,ffffffffc02061d2 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc02061e2:	8082                	ret

ffffffffc02061e4 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02061e4:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02061e8:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02061ea:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02061ee:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02061f0:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02061f4:	f022                	sd	s0,32(sp)
ffffffffc02061f6:	ec26                	sd	s1,24(sp)
ffffffffc02061f8:	e84a                	sd	s2,16(sp)
ffffffffc02061fa:	f406                	sd	ra,40(sp)
ffffffffc02061fc:	e44e                	sd	s3,8(sp)
ffffffffc02061fe:	84aa                	mv	s1,a0
ffffffffc0206200:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0206202:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0206206:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0206208:	03067e63          	bgeu	a2,a6,ffffffffc0206244 <printnum+0x60>
ffffffffc020620c:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc020620e:	00805763          	blez	s0,ffffffffc020621c <printnum+0x38>
ffffffffc0206212:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0206214:	85ca                	mv	a1,s2
ffffffffc0206216:	854e                	mv	a0,s3
ffffffffc0206218:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020621a:	fc65                	bnez	s0,ffffffffc0206212 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020621c:	1a02                	slli	s4,s4,0x20
ffffffffc020621e:	00002797          	auipc	a5,0x2
ffffffffc0206222:	79278793          	addi	a5,a5,1938 # ffffffffc02089b0 <syscalls+0x100>
ffffffffc0206226:	020a5a13          	srli	s4,s4,0x20
ffffffffc020622a:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc020622c:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020622e:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0206232:	70a2                	ld	ra,40(sp)
ffffffffc0206234:	69a2                	ld	s3,8(sp)
ffffffffc0206236:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206238:	85ca                	mv	a1,s2
ffffffffc020623a:	87a6                	mv	a5,s1
}
ffffffffc020623c:	6942                	ld	s2,16(sp)
ffffffffc020623e:	64e2                	ld	s1,24(sp)
ffffffffc0206240:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206242:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0206244:	03065633          	divu	a2,a2,a6
ffffffffc0206248:	8722                	mv	a4,s0
ffffffffc020624a:	f9bff0ef          	jal	ra,ffffffffc02061e4 <printnum>
ffffffffc020624e:	b7f9                	j	ffffffffc020621c <printnum+0x38>

ffffffffc0206250 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0206250:	7119                	addi	sp,sp,-128
ffffffffc0206252:	f4a6                	sd	s1,104(sp)
ffffffffc0206254:	f0ca                	sd	s2,96(sp)
ffffffffc0206256:	ecce                	sd	s3,88(sp)
ffffffffc0206258:	e8d2                	sd	s4,80(sp)
ffffffffc020625a:	e4d6                	sd	s5,72(sp)
ffffffffc020625c:	e0da                	sd	s6,64(sp)
ffffffffc020625e:	fc5e                	sd	s7,56(sp)
ffffffffc0206260:	f06a                	sd	s10,32(sp)
ffffffffc0206262:	fc86                	sd	ra,120(sp)
ffffffffc0206264:	f8a2                	sd	s0,112(sp)
ffffffffc0206266:	f862                	sd	s8,48(sp)
ffffffffc0206268:	f466                	sd	s9,40(sp)
ffffffffc020626a:	ec6e                	sd	s11,24(sp)
ffffffffc020626c:	892a                	mv	s2,a0
ffffffffc020626e:	84ae                	mv	s1,a1
ffffffffc0206270:	8d32                	mv	s10,a2
ffffffffc0206272:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206274:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0206278:	5b7d                	li	s6,-1
ffffffffc020627a:	00002a97          	auipc	s5,0x2
ffffffffc020627e:	762a8a93          	addi	s5,s5,1890 # ffffffffc02089dc <syscalls+0x12c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0206282:	00003b97          	auipc	s7,0x3
ffffffffc0206286:	976b8b93          	addi	s7,s7,-1674 # ffffffffc0208bf8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020628a:	000d4503          	lbu	a0,0(s10)
ffffffffc020628e:	001d0413          	addi	s0,s10,1
ffffffffc0206292:	01350a63          	beq	a0,s3,ffffffffc02062a6 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0206296:	c121                	beqz	a0,ffffffffc02062d6 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0206298:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020629a:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020629c:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020629e:	fff44503          	lbu	a0,-1(s0)
ffffffffc02062a2:	ff351ae3          	bne	a0,s3,ffffffffc0206296 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02062a6:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02062aa:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02062ae:	4c81                	li	s9,0
ffffffffc02062b0:	4881                	li	a7,0
        width = precision = -1;
ffffffffc02062b2:	5c7d                	li	s8,-1
ffffffffc02062b4:	5dfd                	li	s11,-1
ffffffffc02062b6:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc02062ba:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02062bc:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02062c0:	0ff5f593          	zext.b	a1,a1
ffffffffc02062c4:	00140d13          	addi	s10,s0,1
ffffffffc02062c8:	04b56263          	bltu	a0,a1,ffffffffc020630c <vprintfmt+0xbc>
ffffffffc02062cc:	058a                	slli	a1,a1,0x2
ffffffffc02062ce:	95d6                	add	a1,a1,s5
ffffffffc02062d0:	4194                	lw	a3,0(a1)
ffffffffc02062d2:	96d6                	add	a3,a3,s5
ffffffffc02062d4:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02062d6:	70e6                	ld	ra,120(sp)
ffffffffc02062d8:	7446                	ld	s0,112(sp)
ffffffffc02062da:	74a6                	ld	s1,104(sp)
ffffffffc02062dc:	7906                	ld	s2,96(sp)
ffffffffc02062de:	69e6                	ld	s3,88(sp)
ffffffffc02062e0:	6a46                	ld	s4,80(sp)
ffffffffc02062e2:	6aa6                	ld	s5,72(sp)
ffffffffc02062e4:	6b06                	ld	s6,64(sp)
ffffffffc02062e6:	7be2                	ld	s7,56(sp)
ffffffffc02062e8:	7c42                	ld	s8,48(sp)
ffffffffc02062ea:	7ca2                	ld	s9,40(sp)
ffffffffc02062ec:	7d02                	ld	s10,32(sp)
ffffffffc02062ee:	6de2                	ld	s11,24(sp)
ffffffffc02062f0:	6109                	addi	sp,sp,128
ffffffffc02062f2:	8082                	ret
            padc = '0';
ffffffffc02062f4:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02062f6:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02062fa:	846a                	mv	s0,s10
ffffffffc02062fc:	00140d13          	addi	s10,s0,1
ffffffffc0206300:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0206304:	0ff5f593          	zext.b	a1,a1
ffffffffc0206308:	fcb572e3          	bgeu	a0,a1,ffffffffc02062cc <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc020630c:	85a6                	mv	a1,s1
ffffffffc020630e:	02500513          	li	a0,37
ffffffffc0206312:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0206314:	fff44783          	lbu	a5,-1(s0)
ffffffffc0206318:	8d22                	mv	s10,s0
ffffffffc020631a:	f73788e3          	beq	a5,s3,ffffffffc020628a <vprintfmt+0x3a>
ffffffffc020631e:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0206322:	1d7d                	addi	s10,s10,-1
ffffffffc0206324:	ff379de3          	bne	a5,s3,ffffffffc020631e <vprintfmt+0xce>
ffffffffc0206328:	b78d                	j	ffffffffc020628a <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc020632a:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020632e:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206332:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0206334:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0206338:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020633c:	02d86463          	bltu	a6,a3,ffffffffc0206364 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0206340:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0206344:	002c169b          	slliw	a3,s8,0x2
ffffffffc0206348:	0186873b          	addw	a4,a3,s8
ffffffffc020634c:	0017171b          	slliw	a4,a4,0x1
ffffffffc0206350:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0206352:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0206356:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0206358:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc020635c:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0206360:	fed870e3          	bgeu	a6,a3,ffffffffc0206340 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0206364:	f40ddce3          	bgez	s11,ffffffffc02062bc <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0206368:	8de2                	mv	s11,s8
ffffffffc020636a:	5c7d                	li	s8,-1
ffffffffc020636c:	bf81                	j	ffffffffc02062bc <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020636e:	fffdc693          	not	a3,s11
ffffffffc0206372:	96fd                	srai	a3,a3,0x3f
ffffffffc0206374:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206378:	00144603          	lbu	a2,1(s0)
ffffffffc020637c:	2d81                	sext.w	s11,s11
ffffffffc020637e:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0206380:	bf35                	j	ffffffffc02062bc <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0206382:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206386:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020638a:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020638c:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc020638e:	bfd9                	j	ffffffffc0206364 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0206390:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0206392:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0206396:	01174463          	blt	a4,a7,ffffffffc020639e <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc020639a:	1a088e63          	beqz	a7,ffffffffc0206556 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc020639e:	000a3603          	ld	a2,0(s4)
ffffffffc02063a2:	46c1                	li	a3,16
ffffffffc02063a4:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02063a6:	2781                	sext.w	a5,a5
ffffffffc02063a8:	876e                	mv	a4,s11
ffffffffc02063aa:	85a6                	mv	a1,s1
ffffffffc02063ac:	854a                	mv	a0,s2
ffffffffc02063ae:	e37ff0ef          	jal	ra,ffffffffc02061e4 <printnum>
            break;
ffffffffc02063b2:	bde1                	j	ffffffffc020628a <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc02063b4:	000a2503          	lw	a0,0(s4)
ffffffffc02063b8:	85a6                	mv	a1,s1
ffffffffc02063ba:	0a21                	addi	s4,s4,8
ffffffffc02063bc:	9902                	jalr	s2
            break;
ffffffffc02063be:	b5f1                	j	ffffffffc020628a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02063c0:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02063c2:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02063c6:	01174463          	blt	a4,a7,ffffffffc02063ce <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02063ca:	18088163          	beqz	a7,ffffffffc020654c <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02063ce:	000a3603          	ld	a2,0(s4)
ffffffffc02063d2:	46a9                	li	a3,10
ffffffffc02063d4:	8a2e                	mv	s4,a1
ffffffffc02063d6:	bfc1                	j	ffffffffc02063a6 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063d8:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02063dc:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063de:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02063e0:	bdf1                	j	ffffffffc02062bc <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02063e2:	85a6                	mv	a1,s1
ffffffffc02063e4:	02500513          	li	a0,37
ffffffffc02063e8:	9902                	jalr	s2
            break;
ffffffffc02063ea:	b545                	j	ffffffffc020628a <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063ec:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02063f0:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063f2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02063f4:	b5e1                	j	ffffffffc02062bc <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02063f6:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02063f8:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02063fc:	01174463          	blt	a4,a7,ffffffffc0206404 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0206400:	14088163          	beqz	a7,ffffffffc0206542 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0206404:	000a3603          	ld	a2,0(s4)
ffffffffc0206408:	46a1                	li	a3,8
ffffffffc020640a:	8a2e                	mv	s4,a1
ffffffffc020640c:	bf69                	j	ffffffffc02063a6 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc020640e:	03000513          	li	a0,48
ffffffffc0206412:	85a6                	mv	a1,s1
ffffffffc0206414:	e03e                	sd	a5,0(sp)
ffffffffc0206416:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0206418:	85a6                	mv	a1,s1
ffffffffc020641a:	07800513          	li	a0,120
ffffffffc020641e:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0206420:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0206422:	6782                	ld	a5,0(sp)
ffffffffc0206424:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0206426:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc020642a:	bfb5                	j	ffffffffc02063a6 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020642c:	000a3403          	ld	s0,0(s4)
ffffffffc0206430:	008a0713          	addi	a4,s4,8
ffffffffc0206434:	e03a                	sd	a4,0(sp)
ffffffffc0206436:	14040263          	beqz	s0,ffffffffc020657a <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc020643a:	0fb05763          	blez	s11,ffffffffc0206528 <vprintfmt+0x2d8>
ffffffffc020643e:	02d00693          	li	a3,45
ffffffffc0206442:	0cd79163          	bne	a5,a3,ffffffffc0206504 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206446:	00044783          	lbu	a5,0(s0)
ffffffffc020644a:	0007851b          	sext.w	a0,a5
ffffffffc020644e:	cf85                	beqz	a5,ffffffffc0206486 <vprintfmt+0x236>
ffffffffc0206450:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206454:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206458:	000c4563          	bltz	s8,ffffffffc0206462 <vprintfmt+0x212>
ffffffffc020645c:	3c7d                	addiw	s8,s8,-1
ffffffffc020645e:	036c0263          	beq	s8,s6,ffffffffc0206482 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0206462:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206464:	0e0c8e63          	beqz	s9,ffffffffc0206560 <vprintfmt+0x310>
ffffffffc0206468:	3781                	addiw	a5,a5,-32
ffffffffc020646a:	0ef47b63          	bgeu	s0,a5,ffffffffc0206560 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020646e:	03f00513          	li	a0,63
ffffffffc0206472:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206474:	000a4783          	lbu	a5,0(s4)
ffffffffc0206478:	3dfd                	addiw	s11,s11,-1
ffffffffc020647a:	0a05                	addi	s4,s4,1
ffffffffc020647c:	0007851b          	sext.w	a0,a5
ffffffffc0206480:	ffe1                	bnez	a5,ffffffffc0206458 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0206482:	01b05963          	blez	s11,ffffffffc0206494 <vprintfmt+0x244>
ffffffffc0206486:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0206488:	85a6                	mv	a1,s1
ffffffffc020648a:	02000513          	li	a0,32
ffffffffc020648e:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0206490:	fe0d9be3          	bnez	s11,ffffffffc0206486 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0206494:	6a02                	ld	s4,0(sp)
ffffffffc0206496:	bbd5                	j	ffffffffc020628a <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0206498:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020649a:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc020649e:	01174463          	blt	a4,a7,ffffffffc02064a6 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc02064a2:	08088d63          	beqz	a7,ffffffffc020653c <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc02064a6:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc02064aa:	0a044d63          	bltz	s0,ffffffffc0206564 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc02064ae:	8622                	mv	a2,s0
ffffffffc02064b0:	8a66                	mv	s4,s9
ffffffffc02064b2:	46a9                	li	a3,10
ffffffffc02064b4:	bdcd                	j	ffffffffc02063a6 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc02064b6:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02064ba:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc02064bc:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc02064be:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02064c2:	8fb5                	xor	a5,a5,a3
ffffffffc02064c4:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02064c8:	02d74163          	blt	a4,a3,ffffffffc02064ea <vprintfmt+0x29a>
ffffffffc02064cc:	00369793          	slli	a5,a3,0x3
ffffffffc02064d0:	97de                	add	a5,a5,s7
ffffffffc02064d2:	639c                	ld	a5,0(a5)
ffffffffc02064d4:	cb99                	beqz	a5,ffffffffc02064ea <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02064d6:	86be                	mv	a3,a5
ffffffffc02064d8:	00000617          	auipc	a2,0x0
ffffffffc02064dc:	13860613          	addi	a2,a2,312 # ffffffffc0206610 <etext+0x28>
ffffffffc02064e0:	85a6                	mv	a1,s1
ffffffffc02064e2:	854a                	mv	a0,s2
ffffffffc02064e4:	0ce000ef          	jal	ra,ffffffffc02065b2 <printfmt>
ffffffffc02064e8:	b34d                	j	ffffffffc020628a <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02064ea:	00002617          	auipc	a2,0x2
ffffffffc02064ee:	4e660613          	addi	a2,a2,1254 # ffffffffc02089d0 <syscalls+0x120>
ffffffffc02064f2:	85a6                	mv	a1,s1
ffffffffc02064f4:	854a                	mv	a0,s2
ffffffffc02064f6:	0bc000ef          	jal	ra,ffffffffc02065b2 <printfmt>
ffffffffc02064fa:	bb41                	j	ffffffffc020628a <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02064fc:	00002417          	auipc	s0,0x2
ffffffffc0206500:	4cc40413          	addi	s0,s0,1228 # ffffffffc02089c8 <syscalls+0x118>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206504:	85e2                	mv	a1,s8
ffffffffc0206506:	8522                	mv	a0,s0
ffffffffc0206508:	e43e                	sd	a5,8(sp)
ffffffffc020650a:	c4fff0ef          	jal	ra,ffffffffc0206158 <strnlen>
ffffffffc020650e:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0206512:	01b05b63          	blez	s11,ffffffffc0206528 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0206516:	67a2                	ld	a5,8(sp)
ffffffffc0206518:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020651c:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020651e:	85a6                	mv	a1,s1
ffffffffc0206520:	8552                	mv	a0,s4
ffffffffc0206522:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206524:	fe0d9ce3          	bnez	s11,ffffffffc020651c <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206528:	00044783          	lbu	a5,0(s0)
ffffffffc020652c:	00140a13          	addi	s4,s0,1
ffffffffc0206530:	0007851b          	sext.w	a0,a5
ffffffffc0206534:	d3a5                	beqz	a5,ffffffffc0206494 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206536:	05e00413          	li	s0,94
ffffffffc020653a:	bf39                	j	ffffffffc0206458 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc020653c:	000a2403          	lw	s0,0(s4)
ffffffffc0206540:	b7ad                	j	ffffffffc02064aa <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0206542:	000a6603          	lwu	a2,0(s4)
ffffffffc0206546:	46a1                	li	a3,8
ffffffffc0206548:	8a2e                	mv	s4,a1
ffffffffc020654a:	bdb1                	j	ffffffffc02063a6 <vprintfmt+0x156>
ffffffffc020654c:	000a6603          	lwu	a2,0(s4)
ffffffffc0206550:	46a9                	li	a3,10
ffffffffc0206552:	8a2e                	mv	s4,a1
ffffffffc0206554:	bd89                	j	ffffffffc02063a6 <vprintfmt+0x156>
ffffffffc0206556:	000a6603          	lwu	a2,0(s4)
ffffffffc020655a:	46c1                	li	a3,16
ffffffffc020655c:	8a2e                	mv	s4,a1
ffffffffc020655e:	b5a1                	j	ffffffffc02063a6 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0206560:	9902                	jalr	s2
ffffffffc0206562:	bf09                	j	ffffffffc0206474 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0206564:	85a6                	mv	a1,s1
ffffffffc0206566:	02d00513          	li	a0,45
ffffffffc020656a:	e03e                	sd	a5,0(sp)
ffffffffc020656c:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020656e:	6782                	ld	a5,0(sp)
ffffffffc0206570:	8a66                	mv	s4,s9
ffffffffc0206572:	40800633          	neg	a2,s0
ffffffffc0206576:	46a9                	li	a3,10
ffffffffc0206578:	b53d                	j	ffffffffc02063a6 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc020657a:	03b05163          	blez	s11,ffffffffc020659c <vprintfmt+0x34c>
ffffffffc020657e:	02d00693          	li	a3,45
ffffffffc0206582:	f6d79de3          	bne	a5,a3,ffffffffc02064fc <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0206586:	00002417          	auipc	s0,0x2
ffffffffc020658a:	44240413          	addi	s0,s0,1090 # ffffffffc02089c8 <syscalls+0x118>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020658e:	02800793          	li	a5,40
ffffffffc0206592:	02800513          	li	a0,40
ffffffffc0206596:	00140a13          	addi	s4,s0,1
ffffffffc020659a:	bd6d                	j	ffffffffc0206454 <vprintfmt+0x204>
ffffffffc020659c:	00002a17          	auipc	s4,0x2
ffffffffc02065a0:	42da0a13          	addi	s4,s4,1069 # ffffffffc02089c9 <syscalls+0x119>
ffffffffc02065a4:	02800513          	li	a0,40
ffffffffc02065a8:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02065ac:	05e00413          	li	s0,94
ffffffffc02065b0:	b565                	j	ffffffffc0206458 <vprintfmt+0x208>

ffffffffc02065b2 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02065b2:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02065b4:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02065b8:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02065ba:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02065bc:	ec06                	sd	ra,24(sp)
ffffffffc02065be:	f83a                	sd	a4,48(sp)
ffffffffc02065c0:	fc3e                	sd	a5,56(sp)
ffffffffc02065c2:	e0c2                	sd	a6,64(sp)
ffffffffc02065c4:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02065c6:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02065c8:	c89ff0ef          	jal	ra,ffffffffc0206250 <vprintfmt>
}
ffffffffc02065cc:	60e2                	ld	ra,24(sp)
ffffffffc02065ce:	6161                	addi	sp,sp,80
ffffffffc02065d0:	8082                	ret

ffffffffc02065d2 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc02065d2:	9e3707b7          	lui	a5,0x9e370
ffffffffc02065d6:	2785                	addiw	a5,a5,1
ffffffffc02065d8:	02a7853b          	mulw	a0,a5,a0
    return (hash >> (32 - bits));
ffffffffc02065dc:	02000793          	li	a5,32
ffffffffc02065e0:	9f8d                	subw	a5,a5,a1
}
ffffffffc02065e2:	00f5553b          	srlw	a0,a0,a5
ffffffffc02065e6:	8082                	ret

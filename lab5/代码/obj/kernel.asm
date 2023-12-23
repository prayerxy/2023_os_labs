
bin/kernel：     文件格式 elf64-littleriscv


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
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200010:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200014:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200018:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc020001c:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200020:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200024:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200028:	c020b137          	lui	sp,0xc020b

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:
void grade_backtrace(void);

int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	000ab517          	auipc	a0,0xab
ffffffffc020003a:	74250513          	addi	a0,a0,1858 # ffffffffc02ab778 <edata>
ffffffffc020003e:	000b7617          	auipc	a2,0xb7
ffffffffc0200042:	cc260613          	addi	a2,a2,-830 # ffffffffc02b6d00 <end>
kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	6e6060ef          	jal	ra,ffffffffc0206734 <memset>
    cons_init();                // init the console
ffffffffc0200052:	536000ef          	jal	ra,ffffffffc0200588 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200056:	00006597          	auipc	a1,0x6
ffffffffc020005a:	70a58593          	addi	a1,a1,1802 # ffffffffc0206760 <etext+0x2>
ffffffffc020005e:	00006517          	auipc	a0,0x6
ffffffffc0200062:	72250513          	addi	a0,a0,1826 # ffffffffc0206780 <etext+0x22>
ffffffffc0200066:	128000ef          	jal	ra,ffffffffc020018e <cprintf>

    print_kerninfo();
ffffffffc020006a:	1ac000ef          	jal	ra,ffffffffc0200216 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006e:	5c6020ef          	jal	ra,ffffffffc0202634 <pmm_init>

    pic_init();                 // init interrupt controller
ffffffffc0200072:	5ee000ef          	jal	ra,ffffffffc0200660 <pic_init>
    idt_init();                 // init interrupt descriptor table
ffffffffc0200076:	5ec000ef          	jal	ra,ffffffffc0200662 <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc020007a:	44c040ef          	jal	ra,ffffffffc02044c6 <vmm_init>
    proc_init();                // init process table
ffffffffc020007e:	647050ef          	jal	ra,ffffffffc0205ec4 <proc_init>
    
    ide_init();                 // init ide devices
ffffffffc0200082:	57a000ef          	jal	ra,ffffffffc02005fc <ide_init>
    swap_init();                // init swap
ffffffffc0200086:	36a030ef          	jal	ra,ffffffffc02033f0 <swap_init>

    clock_init();               // init clock interrupt
ffffffffc020008a:	4a8000ef          	jal	ra,ffffffffc0200532 <clock_init>
    intr_enable();              // enable irq interrupt
ffffffffc020008e:	5c6000ef          	jal	ra,ffffffffc0200654 <intr_enable>
    
    cpu_idle();                 // run idle process
ffffffffc0200092:	77f050ef          	jal	ra,ffffffffc0206010 <cpu_idle>

ffffffffc0200096 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0200096:	715d                	addi	sp,sp,-80
ffffffffc0200098:	e486                	sd	ra,72(sp)
ffffffffc020009a:	e0a2                	sd	s0,64(sp)
ffffffffc020009c:	fc26                	sd	s1,56(sp)
ffffffffc020009e:	f84a                	sd	s2,48(sp)
ffffffffc02000a0:	f44e                	sd	s3,40(sp)
ffffffffc02000a2:	f052                	sd	s4,32(sp)
ffffffffc02000a4:	ec56                	sd	s5,24(sp)
ffffffffc02000a6:	e85a                	sd	s6,16(sp)
ffffffffc02000a8:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc02000aa:	c901                	beqz	a0,ffffffffc02000ba <readline+0x24>
        cprintf("%s", prompt);
ffffffffc02000ac:	85aa                	mv	a1,a0
ffffffffc02000ae:	00006517          	auipc	a0,0x6
ffffffffc02000b2:	6da50513          	addi	a0,a0,1754 # ffffffffc0206788 <etext+0x2a>
ffffffffc02000b6:	0d8000ef          	jal	ra,ffffffffc020018e <cprintf>
readline(const char *prompt) {
ffffffffc02000ba:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000bc:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000be:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000c0:	4aa9                	li	s5,10
ffffffffc02000c2:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000c4:	000abb97          	auipc	s7,0xab
ffffffffc02000c8:	6b4b8b93          	addi	s7,s7,1716 # ffffffffc02ab778 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000cc:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000d0:	136000ef          	jal	ra,ffffffffc0200206 <getchar>
ffffffffc02000d4:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02000d6:	00054b63          	bltz	a0,ffffffffc02000ec <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	00a95b63          	ble	a0,s2,ffffffffc02000f0 <readline+0x5a>
ffffffffc02000de:	029a5463          	ble	s1,s4,ffffffffc0200106 <readline+0x70>
        c = getchar();
ffffffffc02000e2:	124000ef          	jal	ra,ffffffffc0200206 <getchar>
ffffffffc02000e6:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02000e8:	fe0559e3          	bgez	a0,ffffffffc02000da <readline+0x44>
            return NULL;
ffffffffc02000ec:	4501                	li	a0,0
ffffffffc02000ee:	a099                	j	ffffffffc0200134 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc02000f0:	03341463          	bne	s0,s3,ffffffffc0200118 <readline+0x82>
ffffffffc02000f4:	e8b9                	bnez	s1,ffffffffc020014a <readline+0xb4>
        c = getchar();
ffffffffc02000f6:	110000ef          	jal	ra,ffffffffc0200206 <getchar>
ffffffffc02000fa:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02000fc:	fe0548e3          	bltz	a0,ffffffffc02000ec <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200100:	fea958e3          	ble	a0,s2,ffffffffc02000f0 <readline+0x5a>
ffffffffc0200104:	4481                	li	s1,0
            cputchar(c);
ffffffffc0200106:	8522                	mv	a0,s0
ffffffffc0200108:	0ba000ef          	jal	ra,ffffffffc02001c2 <cputchar>
            buf[i ++] = c;
ffffffffc020010c:	009b87b3          	add	a5,s7,s1
ffffffffc0200110:	00878023          	sb	s0,0(a5)
ffffffffc0200114:	2485                	addiw	s1,s1,1
ffffffffc0200116:	bf6d                	j	ffffffffc02000d0 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0200118:	01540463          	beq	s0,s5,ffffffffc0200120 <readline+0x8a>
ffffffffc020011c:	fb641ae3          	bne	s0,s6,ffffffffc02000d0 <readline+0x3a>
            cputchar(c);
ffffffffc0200120:	8522                	mv	a0,s0
ffffffffc0200122:	0a0000ef          	jal	ra,ffffffffc02001c2 <cputchar>
            buf[i] = '\0';
ffffffffc0200126:	000ab517          	auipc	a0,0xab
ffffffffc020012a:	65250513          	addi	a0,a0,1618 # ffffffffc02ab778 <edata>
ffffffffc020012e:	94aa                	add	s1,s1,a0
ffffffffc0200130:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0200134:	60a6                	ld	ra,72(sp)
ffffffffc0200136:	6406                	ld	s0,64(sp)
ffffffffc0200138:	74e2                	ld	s1,56(sp)
ffffffffc020013a:	7942                	ld	s2,48(sp)
ffffffffc020013c:	79a2                	ld	s3,40(sp)
ffffffffc020013e:	7a02                	ld	s4,32(sp)
ffffffffc0200140:	6ae2                	ld	s5,24(sp)
ffffffffc0200142:	6b42                	ld	s6,16(sp)
ffffffffc0200144:	6ba2                	ld	s7,8(sp)
ffffffffc0200146:	6161                	addi	sp,sp,80
ffffffffc0200148:	8082                	ret
            cputchar(c);
ffffffffc020014a:	4521                	li	a0,8
ffffffffc020014c:	076000ef          	jal	ra,ffffffffc02001c2 <cputchar>
            i --;
ffffffffc0200150:	34fd                	addiw	s1,s1,-1
ffffffffc0200152:	bfbd                	j	ffffffffc02000d0 <readline+0x3a>

ffffffffc0200154 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200154:	1141                	addi	sp,sp,-16
ffffffffc0200156:	e022                	sd	s0,0(sp)
ffffffffc0200158:	e406                	sd	ra,8(sp)
ffffffffc020015a:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020015c:	42e000ef          	jal	ra,ffffffffc020058a <cons_putc>
    (*cnt) ++;
ffffffffc0200160:	401c                	lw	a5,0(s0)
}
ffffffffc0200162:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200164:	2785                	addiw	a5,a5,1
ffffffffc0200166:	c01c                	sw	a5,0(s0)
}
ffffffffc0200168:	6402                	ld	s0,0(sp)
ffffffffc020016a:	0141                	addi	sp,sp,16
ffffffffc020016c:	8082                	ret

ffffffffc020016e <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020016e:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200170:	86ae                	mv	a3,a1
ffffffffc0200172:	862a                	mv	a2,a0
ffffffffc0200174:	006c                	addi	a1,sp,12
ffffffffc0200176:	00000517          	auipc	a0,0x0
ffffffffc020017a:	fde50513          	addi	a0,a0,-34 # ffffffffc0200154 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc020017e:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200180:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200182:	188060ef          	jal	ra,ffffffffc020630a <vprintfmt>
    return cnt;
}
ffffffffc0200186:	60e2                	ld	ra,24(sp)
ffffffffc0200188:	4532                	lw	a0,12(sp)
ffffffffc020018a:	6105                	addi	sp,sp,32
ffffffffc020018c:	8082                	ret

ffffffffc020018e <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020018e:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200190:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200194:	f42e                	sd	a1,40(sp)
ffffffffc0200196:	f832                	sd	a2,48(sp)
ffffffffc0200198:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020019a:	862a                	mv	a2,a0
ffffffffc020019c:	004c                	addi	a1,sp,4
ffffffffc020019e:	00000517          	auipc	a0,0x0
ffffffffc02001a2:	fb650513          	addi	a0,a0,-74 # ffffffffc0200154 <cputch>
ffffffffc02001a6:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02001a8:	ec06                	sd	ra,24(sp)
ffffffffc02001aa:	e0ba                	sd	a4,64(sp)
ffffffffc02001ac:	e4be                	sd	a5,72(sp)
ffffffffc02001ae:	e8c2                	sd	a6,80(sp)
ffffffffc02001b0:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001b2:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001b4:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02001b6:	154060ef          	jal	ra,ffffffffc020630a <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001ba:	60e2                	ld	ra,24(sp)
ffffffffc02001bc:	4512                	lw	a0,4(sp)
ffffffffc02001be:	6125                	addi	sp,sp,96
ffffffffc02001c0:	8082                	ret

ffffffffc02001c2 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02001c2:	3c80006f          	j	ffffffffc020058a <cons_putc>

ffffffffc02001c6 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02001c6:	1101                	addi	sp,sp,-32
ffffffffc02001c8:	e822                	sd	s0,16(sp)
ffffffffc02001ca:	ec06                	sd	ra,24(sp)
ffffffffc02001cc:	e426                	sd	s1,8(sp)
ffffffffc02001ce:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02001d0:	00054503          	lbu	a0,0(a0)
ffffffffc02001d4:	c51d                	beqz	a0,ffffffffc0200202 <cputs+0x3c>
ffffffffc02001d6:	0405                	addi	s0,s0,1
ffffffffc02001d8:	4485                	li	s1,1
ffffffffc02001da:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001dc:	3ae000ef          	jal	ra,ffffffffc020058a <cons_putc>
    (*cnt) ++;
ffffffffc02001e0:	008487bb          	addw	a5,s1,s0
    while ((c = *str ++) != '\0') {
ffffffffc02001e4:	0405                	addi	s0,s0,1
ffffffffc02001e6:	fff44503          	lbu	a0,-1(s0)
ffffffffc02001ea:	f96d                	bnez	a0,ffffffffc02001dc <cputs+0x16>
ffffffffc02001ec:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001f0:	4529                	li	a0,10
ffffffffc02001f2:	398000ef          	jal	ra,ffffffffc020058a <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001f6:	8522                	mv	a0,s0
ffffffffc02001f8:	60e2                	ld	ra,24(sp)
ffffffffc02001fa:	6442                	ld	s0,16(sp)
ffffffffc02001fc:	64a2                	ld	s1,8(sp)
ffffffffc02001fe:	6105                	addi	sp,sp,32
ffffffffc0200200:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200202:	4405                	li	s0,1
ffffffffc0200204:	b7f5                	j	ffffffffc02001f0 <cputs+0x2a>

ffffffffc0200206 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200206:	1141                	addi	sp,sp,-16
ffffffffc0200208:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020020a:	3b6000ef          	jal	ra,ffffffffc02005c0 <cons_getc>
ffffffffc020020e:	dd75                	beqz	a0,ffffffffc020020a <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200210:	60a2                	ld	ra,8(sp)
ffffffffc0200212:	0141                	addi	sp,sp,16
ffffffffc0200214:	8082                	ret

ffffffffc0200216 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200216:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200218:	00006517          	auipc	a0,0x6
ffffffffc020021c:	5a850513          	addi	a0,a0,1448 # ffffffffc02067c0 <etext+0x62>
void print_kerninfo(void) {
ffffffffc0200220:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200222:	f6dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200226:	00000597          	auipc	a1,0x0
ffffffffc020022a:	e1058593          	addi	a1,a1,-496 # ffffffffc0200036 <kern_init>
ffffffffc020022e:	00006517          	auipc	a0,0x6
ffffffffc0200232:	5b250513          	addi	a0,a0,1458 # ffffffffc02067e0 <etext+0x82>
ffffffffc0200236:	f59ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020023a:	00006597          	auipc	a1,0x6
ffffffffc020023e:	52458593          	addi	a1,a1,1316 # ffffffffc020675e <etext>
ffffffffc0200242:	00006517          	auipc	a0,0x6
ffffffffc0200246:	5be50513          	addi	a0,a0,1470 # ffffffffc0206800 <etext+0xa2>
ffffffffc020024a:	f45ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020024e:	000ab597          	auipc	a1,0xab
ffffffffc0200252:	52a58593          	addi	a1,a1,1322 # ffffffffc02ab778 <edata>
ffffffffc0200256:	00006517          	auipc	a0,0x6
ffffffffc020025a:	5ca50513          	addi	a0,a0,1482 # ffffffffc0206820 <etext+0xc2>
ffffffffc020025e:	f31ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200262:	000b7597          	auipc	a1,0xb7
ffffffffc0200266:	a9e58593          	addi	a1,a1,-1378 # ffffffffc02b6d00 <end>
ffffffffc020026a:	00006517          	auipc	a0,0x6
ffffffffc020026e:	5d650513          	addi	a0,a0,1494 # ffffffffc0206840 <etext+0xe2>
ffffffffc0200272:	f1dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200276:	000b7597          	auipc	a1,0xb7
ffffffffc020027a:	e8958593          	addi	a1,a1,-375 # ffffffffc02b70ff <end+0x3ff>
ffffffffc020027e:	00000797          	auipc	a5,0x0
ffffffffc0200282:	db878793          	addi	a5,a5,-584 # ffffffffc0200036 <kern_init>
ffffffffc0200286:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020028a:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020028e:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200290:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200294:	95be                	add	a1,a1,a5
ffffffffc0200296:	85a9                	srai	a1,a1,0xa
ffffffffc0200298:	00006517          	auipc	a0,0x6
ffffffffc020029c:	5c850513          	addi	a0,a0,1480 # ffffffffc0206860 <etext+0x102>
}
ffffffffc02002a0:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a2:	eedff06f          	j	ffffffffc020018e <cprintf>

ffffffffc02002a6 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002a6:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002a8:	00006617          	auipc	a2,0x6
ffffffffc02002ac:	4e860613          	addi	a2,a2,1256 # ffffffffc0206790 <etext+0x32>
ffffffffc02002b0:	04d00593          	li	a1,77
ffffffffc02002b4:	00006517          	auipc	a0,0x6
ffffffffc02002b8:	4f450513          	addi	a0,a0,1268 # ffffffffc02067a8 <etext+0x4a>
void print_stackframe(void) {
ffffffffc02002bc:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002be:	1c6000ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02002c2 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002c2:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002c4:	00006617          	auipc	a2,0x6
ffffffffc02002c8:	6ac60613          	addi	a2,a2,1708 # ffffffffc0206970 <commands+0xe0>
ffffffffc02002cc:	00006597          	auipc	a1,0x6
ffffffffc02002d0:	6c458593          	addi	a1,a1,1732 # ffffffffc0206990 <commands+0x100>
ffffffffc02002d4:	00006517          	auipc	a0,0x6
ffffffffc02002d8:	6c450513          	addi	a0,a0,1732 # ffffffffc0206998 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002dc:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002de:	eb1ff0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc02002e2:	00006617          	auipc	a2,0x6
ffffffffc02002e6:	6c660613          	addi	a2,a2,1734 # ffffffffc02069a8 <commands+0x118>
ffffffffc02002ea:	00006597          	auipc	a1,0x6
ffffffffc02002ee:	6e658593          	addi	a1,a1,1766 # ffffffffc02069d0 <commands+0x140>
ffffffffc02002f2:	00006517          	auipc	a0,0x6
ffffffffc02002f6:	6a650513          	addi	a0,a0,1702 # ffffffffc0206998 <commands+0x108>
ffffffffc02002fa:	e95ff0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc02002fe:	00006617          	auipc	a2,0x6
ffffffffc0200302:	6e260613          	addi	a2,a2,1762 # ffffffffc02069e0 <commands+0x150>
ffffffffc0200306:	00006597          	auipc	a1,0x6
ffffffffc020030a:	6fa58593          	addi	a1,a1,1786 # ffffffffc0206a00 <commands+0x170>
ffffffffc020030e:	00006517          	auipc	a0,0x6
ffffffffc0200312:	68a50513          	addi	a0,a0,1674 # ffffffffc0206998 <commands+0x108>
ffffffffc0200316:	e79ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    }
    return 0;
}
ffffffffc020031a:	60a2                	ld	ra,8(sp)
ffffffffc020031c:	4501                	li	a0,0
ffffffffc020031e:	0141                	addi	sp,sp,16
ffffffffc0200320:	8082                	ret

ffffffffc0200322 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200322:	1141                	addi	sp,sp,-16
ffffffffc0200324:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200326:	ef1ff0ef          	jal	ra,ffffffffc0200216 <print_kerninfo>
    return 0;
}
ffffffffc020032a:	60a2                	ld	ra,8(sp)
ffffffffc020032c:	4501                	li	a0,0
ffffffffc020032e:	0141                	addi	sp,sp,16
ffffffffc0200330:	8082                	ret

ffffffffc0200332 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200332:	1141                	addi	sp,sp,-16
ffffffffc0200334:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200336:	f71ff0ef          	jal	ra,ffffffffc02002a6 <print_stackframe>
    return 0;
}
ffffffffc020033a:	60a2                	ld	ra,8(sp)
ffffffffc020033c:	4501                	li	a0,0
ffffffffc020033e:	0141                	addi	sp,sp,16
ffffffffc0200340:	8082                	ret

ffffffffc0200342 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200342:	7115                	addi	sp,sp,-224
ffffffffc0200344:	e962                	sd	s8,144(sp)
ffffffffc0200346:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200348:	00006517          	auipc	a0,0x6
ffffffffc020034c:	59050513          	addi	a0,a0,1424 # ffffffffc02068d8 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc0200350:	ed86                	sd	ra,216(sp)
ffffffffc0200352:	e9a2                	sd	s0,208(sp)
ffffffffc0200354:	e5a6                	sd	s1,200(sp)
ffffffffc0200356:	e1ca                	sd	s2,192(sp)
ffffffffc0200358:	fd4e                	sd	s3,184(sp)
ffffffffc020035a:	f952                	sd	s4,176(sp)
ffffffffc020035c:	f556                	sd	s5,168(sp)
ffffffffc020035e:	f15a                	sd	s6,160(sp)
ffffffffc0200360:	ed5e                	sd	s7,152(sp)
ffffffffc0200362:	e566                	sd	s9,136(sp)
ffffffffc0200364:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200366:	e29ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020036a:	00006517          	auipc	a0,0x6
ffffffffc020036e:	59650513          	addi	a0,a0,1430 # ffffffffc0206900 <commands+0x70>
ffffffffc0200372:	e1dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    if (tf != NULL) {
ffffffffc0200376:	000c0563          	beqz	s8,ffffffffc0200380 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037a:	8562                	mv	a0,s8
ffffffffc020037c:	4ce000ef          	jal	ra,ffffffffc020084a <print_trapframe>
ffffffffc0200380:	00006c97          	auipc	s9,0x6
ffffffffc0200384:	510c8c93          	addi	s9,s9,1296 # ffffffffc0206890 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200388:	00006997          	auipc	s3,0x6
ffffffffc020038c:	5a098993          	addi	s3,s3,1440 # ffffffffc0206928 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200390:	00006917          	auipc	s2,0x6
ffffffffc0200394:	5a090913          	addi	s2,s2,1440 # ffffffffc0206930 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc0200398:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039a:	00006b17          	auipc	s6,0x6
ffffffffc020039e:	59eb0b13          	addi	s6,s6,1438 # ffffffffc0206938 <commands+0xa8>
    if (argc == 0) {
ffffffffc02003a2:	00006a97          	auipc	s5,0x6
ffffffffc02003a6:	5eea8a93          	addi	s5,s5,1518 # ffffffffc0206990 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003aa:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003ac:	854e                	mv	a0,s3
ffffffffc02003ae:	ce9ff0ef          	jal	ra,ffffffffc0200096 <readline>
ffffffffc02003b2:	842a                	mv	s0,a0
ffffffffc02003b4:	dd65                	beqz	a0,ffffffffc02003ac <kmonitor+0x6a>
ffffffffc02003b6:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003ba:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003bc:	c999                	beqz	a1,ffffffffc02003d2 <kmonitor+0x90>
ffffffffc02003be:	854a                	mv	a0,s2
ffffffffc02003c0:	356060ef          	jal	ra,ffffffffc0206716 <strchr>
ffffffffc02003c4:	c925                	beqz	a0,ffffffffc0200434 <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc02003c6:	00144583          	lbu	a1,1(s0)
ffffffffc02003ca:	00040023          	sb	zero,0(s0)
ffffffffc02003ce:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003d0:	f5fd                	bnez	a1,ffffffffc02003be <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc02003d2:	dce9                	beqz	s1,ffffffffc02003ac <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003d4:	6582                	ld	a1,0(sp)
ffffffffc02003d6:	00006d17          	auipc	s10,0x6
ffffffffc02003da:	4bad0d13          	addi	s10,s10,1210 # ffffffffc0206890 <commands>
    if (argc == 0) {
ffffffffc02003de:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003e0:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003e2:	0d61                	addi	s10,s10,24
ffffffffc02003e4:	308060ef          	jal	ra,ffffffffc02066ec <strcmp>
ffffffffc02003e8:	c919                	beqz	a0,ffffffffc02003fe <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003ea:	2405                	addiw	s0,s0,1
ffffffffc02003ec:	09740463          	beq	s0,s7,ffffffffc0200474 <kmonitor+0x132>
ffffffffc02003f0:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003f4:	6582                	ld	a1,0(sp)
ffffffffc02003f6:	0d61                	addi	s10,s10,24
ffffffffc02003f8:	2f4060ef          	jal	ra,ffffffffc02066ec <strcmp>
ffffffffc02003fc:	f57d                	bnez	a0,ffffffffc02003ea <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003fe:	00141793          	slli	a5,s0,0x1
ffffffffc0200402:	97a2                	add	a5,a5,s0
ffffffffc0200404:	078e                	slli	a5,a5,0x3
ffffffffc0200406:	97e6                	add	a5,a5,s9
ffffffffc0200408:	6b9c                	ld	a5,16(a5)
ffffffffc020040a:	8662                	mv	a2,s8
ffffffffc020040c:	002c                	addi	a1,sp,8
ffffffffc020040e:	fff4851b          	addiw	a0,s1,-1
ffffffffc0200412:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200414:	f8055ce3          	bgez	a0,ffffffffc02003ac <kmonitor+0x6a>
}
ffffffffc0200418:	60ee                	ld	ra,216(sp)
ffffffffc020041a:	644e                	ld	s0,208(sp)
ffffffffc020041c:	64ae                	ld	s1,200(sp)
ffffffffc020041e:	690e                	ld	s2,192(sp)
ffffffffc0200420:	79ea                	ld	s3,184(sp)
ffffffffc0200422:	7a4a                	ld	s4,176(sp)
ffffffffc0200424:	7aaa                	ld	s5,168(sp)
ffffffffc0200426:	7b0a                	ld	s6,160(sp)
ffffffffc0200428:	6bea                	ld	s7,152(sp)
ffffffffc020042a:	6c4a                	ld	s8,144(sp)
ffffffffc020042c:	6caa                	ld	s9,136(sp)
ffffffffc020042e:	6d0a                	ld	s10,128(sp)
ffffffffc0200430:	612d                	addi	sp,sp,224
ffffffffc0200432:	8082                	ret
        if (*buf == '\0') {
ffffffffc0200434:	00044783          	lbu	a5,0(s0)
ffffffffc0200438:	dfc9                	beqz	a5,ffffffffc02003d2 <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc020043a:	03448863          	beq	s1,s4,ffffffffc020046a <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc020043e:	00349793          	slli	a5,s1,0x3
ffffffffc0200442:	0118                	addi	a4,sp,128
ffffffffc0200444:	97ba                	add	a5,a5,a4
ffffffffc0200446:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020044a:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020044e:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200450:	e591                	bnez	a1,ffffffffc020045c <kmonitor+0x11a>
ffffffffc0200452:	b749                	j	ffffffffc02003d4 <kmonitor+0x92>
            buf ++;
ffffffffc0200454:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200456:	00044583          	lbu	a1,0(s0)
ffffffffc020045a:	ddad                	beqz	a1,ffffffffc02003d4 <kmonitor+0x92>
ffffffffc020045c:	854a                	mv	a0,s2
ffffffffc020045e:	2b8060ef          	jal	ra,ffffffffc0206716 <strchr>
ffffffffc0200462:	d96d                	beqz	a0,ffffffffc0200454 <kmonitor+0x112>
ffffffffc0200464:	00044583          	lbu	a1,0(s0)
ffffffffc0200468:	bf91                	j	ffffffffc02003bc <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020046a:	45c1                	li	a1,16
ffffffffc020046c:	855a                	mv	a0,s6
ffffffffc020046e:	d21ff0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc0200472:	b7f1                	j	ffffffffc020043e <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200474:	6582                	ld	a1,0(sp)
ffffffffc0200476:	00006517          	auipc	a0,0x6
ffffffffc020047a:	4e250513          	addi	a0,a0,1250 # ffffffffc0206958 <commands+0xc8>
ffffffffc020047e:	d11ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    return 0;
ffffffffc0200482:	b72d                	j	ffffffffc02003ac <kmonitor+0x6a>

ffffffffc0200484 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200484:	000b6317          	auipc	t1,0xb6
ffffffffc0200488:	6f430313          	addi	t1,t1,1780 # ffffffffc02b6b78 <is_panic>
ffffffffc020048c:	00033303          	ld	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200490:	715d                	addi	sp,sp,-80
ffffffffc0200492:	ec06                	sd	ra,24(sp)
ffffffffc0200494:	e822                	sd	s0,16(sp)
ffffffffc0200496:	f436                	sd	a3,40(sp)
ffffffffc0200498:	f83a                	sd	a4,48(sp)
ffffffffc020049a:	fc3e                	sd	a5,56(sp)
ffffffffc020049c:	e0c2                	sd	a6,64(sp)
ffffffffc020049e:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02004a0:	02031c63          	bnez	t1,ffffffffc02004d8 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004a4:	4785                	li	a5,1
ffffffffc02004a6:	8432                	mv	s0,a2
ffffffffc02004a8:	000b6717          	auipc	a4,0xb6
ffffffffc02004ac:	6cf73823          	sd	a5,1744(a4) # ffffffffc02b6b78 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b0:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc02004b2:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b4:	85aa                	mv	a1,a0
ffffffffc02004b6:	00006517          	auipc	a0,0x6
ffffffffc02004ba:	55a50513          	addi	a0,a0,1370 # ffffffffc0206a10 <commands+0x180>
    va_start(ap, fmt);
ffffffffc02004be:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c0:	ccfff0ef          	jal	ra,ffffffffc020018e <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004c4:	65a2                	ld	a1,8(sp)
ffffffffc02004c6:	8522                	mv	a0,s0
ffffffffc02004c8:	ca7ff0ef          	jal	ra,ffffffffc020016e <vcprintf>
    cprintf("\n");
ffffffffc02004cc:	00007517          	auipc	a0,0x7
ffffffffc02004d0:	51450513          	addi	a0,a0,1300 # ffffffffc02079e0 <default_pmm_manager+0x548>
ffffffffc02004d4:	cbbff0ef          	jal	ra,ffffffffc020018e <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004d8:	4501                	li	a0,0
ffffffffc02004da:	4581                	li	a1,0
ffffffffc02004dc:	4601                	li	a2,0
ffffffffc02004de:	48a1                	li	a7,8
ffffffffc02004e0:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004e4:	176000ef          	jal	ra,ffffffffc020065a <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004e8:	4501                	li	a0,0
ffffffffc02004ea:	e59ff0ef          	jal	ra,ffffffffc0200342 <kmonitor>
ffffffffc02004ee:	bfed                	j	ffffffffc02004e8 <__panic+0x64>

ffffffffc02004f0 <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004f0:	715d                	addi	sp,sp,-80
ffffffffc02004f2:	e822                	sd	s0,16(sp)
ffffffffc02004f4:	fc3e                	sd	a5,56(sp)
ffffffffc02004f6:	8432                	mv	s0,a2
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004f8:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004fa:	862e                	mv	a2,a1
ffffffffc02004fc:	85aa                	mv	a1,a0
ffffffffc02004fe:	00006517          	auipc	a0,0x6
ffffffffc0200502:	53250513          	addi	a0,a0,1330 # ffffffffc0206a30 <commands+0x1a0>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200506:	ec06                	sd	ra,24(sp)
ffffffffc0200508:	f436                	sd	a3,40(sp)
ffffffffc020050a:	f83a                	sd	a4,48(sp)
ffffffffc020050c:	e0c2                	sd	a6,64(sp)
ffffffffc020050e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200510:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200512:	c7dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200516:	65a2                	ld	a1,8(sp)
ffffffffc0200518:	8522                	mv	a0,s0
ffffffffc020051a:	c55ff0ef          	jal	ra,ffffffffc020016e <vcprintf>
    cprintf("\n");
ffffffffc020051e:	00007517          	auipc	a0,0x7
ffffffffc0200522:	4c250513          	addi	a0,a0,1218 # ffffffffc02079e0 <default_pmm_manager+0x548>
ffffffffc0200526:	c69ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    va_end(ap);
}
ffffffffc020052a:	60e2                	ld	ra,24(sp)
ffffffffc020052c:	6442                	ld	s0,16(sp)
ffffffffc020052e:	6161                	addi	sp,sp,80
ffffffffc0200530:	8082                	ret

ffffffffc0200532 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200532:	67e1                	lui	a5,0x18
ffffffffc0200534:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xdc10>
ffffffffc0200538:	000b6717          	auipc	a4,0xb6
ffffffffc020053c:	64f73423          	sd	a5,1608(a4) # ffffffffc02b6b80 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200540:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200544:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200546:	953e                	add	a0,a0,a5
ffffffffc0200548:	4601                	li	a2,0
ffffffffc020054a:	4881                	li	a7,0
ffffffffc020054c:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200550:	02000793          	li	a5,32
ffffffffc0200554:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200558:	00006517          	auipc	a0,0x6
ffffffffc020055c:	4f850513          	addi	a0,a0,1272 # ffffffffc0206a50 <commands+0x1c0>
    ticks = 0;
ffffffffc0200560:	000b6797          	auipc	a5,0xb6
ffffffffc0200564:	6607b823          	sd	zero,1648(a5) # ffffffffc02b6bd0 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200568:	c27ff06f          	j	ffffffffc020018e <cprintf>

ffffffffc020056c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020056c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200570:	000b6797          	auipc	a5,0xb6
ffffffffc0200574:	61078793          	addi	a5,a5,1552 # ffffffffc02b6b80 <timebase>
ffffffffc0200578:	639c                	ld	a5,0(a5)
ffffffffc020057a:	4581                	li	a1,0
ffffffffc020057c:	4601                	li	a2,0
ffffffffc020057e:	953e                	add	a0,a0,a5
ffffffffc0200580:	4881                	li	a7,0
ffffffffc0200582:	00000073          	ecall
ffffffffc0200586:	8082                	ret

ffffffffc0200588 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200588:	8082                	ret

ffffffffc020058a <cons_putc>:
#include <sched.h>
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020058a:	100027f3          	csrr	a5,sstatus
ffffffffc020058e:	8b89                	andi	a5,a5,2
ffffffffc0200590:	0ff57513          	andi	a0,a0,255
ffffffffc0200594:	e799                	bnez	a5,ffffffffc02005a2 <cons_putc+0x18>
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200596:	4581                	li	a1,0
ffffffffc0200598:	4601                	li	a2,0
ffffffffc020059a:	4885                	li	a7,1
ffffffffc020059c:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02005a0:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a2:	1101                	addi	sp,sp,-32
ffffffffc02005a4:	ec06                	sd	ra,24(sp)
ffffffffc02005a6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005a8:	0b2000ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc02005ac:	6522                	ld	a0,8(sp)
ffffffffc02005ae:	4581                	li	a1,0
ffffffffc02005b0:	4601                	li	a2,0
ffffffffc02005b2:	4885                	li	a7,1
ffffffffc02005b4:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005b8:	60e2                	ld	ra,24(sp)
ffffffffc02005ba:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02005bc:	0980006f          	j	ffffffffc0200654 <intr_enable>

ffffffffc02005c0 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02005c0:	100027f3          	csrr	a5,sstatus
ffffffffc02005c4:	8b89                	andi	a5,a5,2
ffffffffc02005c6:	eb89                	bnez	a5,ffffffffc02005d8 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005c8:	4501                	li	a0,0
ffffffffc02005ca:	4581                	li	a1,0
ffffffffc02005cc:	4601                	li	a2,0
ffffffffc02005ce:	4889                	li	a7,2
ffffffffc02005d0:	00000073          	ecall
ffffffffc02005d4:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d6:	8082                	ret
int cons_getc(void) {
ffffffffc02005d8:	1101                	addi	sp,sp,-32
ffffffffc02005da:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005dc:	07e000ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc02005e0:	4501                	li	a0,0
ffffffffc02005e2:	4581                	li	a1,0
ffffffffc02005e4:	4601                	li	a2,0
ffffffffc02005e6:	4889                	li	a7,2
ffffffffc02005e8:	00000073          	ecall
ffffffffc02005ec:	2501                	sext.w	a0,a0
ffffffffc02005ee:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005f0:	064000ef          	jal	ra,ffffffffc0200654 <intr_enable>
}
ffffffffc02005f4:	60e2                	ld	ra,24(sp)
ffffffffc02005f6:	6522                	ld	a0,8(sp)
ffffffffc02005f8:	6105                	addi	sp,sp,32
ffffffffc02005fa:	8082                	ret

ffffffffc02005fc <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc02005fc:	8082                	ret

ffffffffc02005fe <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc02005fe:	00253513          	sltiu	a0,a0,2
ffffffffc0200602:	8082                	ret

ffffffffc0200604 <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc0200604:	03800513          	li	a0,56
ffffffffc0200608:	8082                	ret

ffffffffc020060a <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc020060a:	000ab797          	auipc	a5,0xab
ffffffffc020060e:	56e78793          	addi	a5,a5,1390 # ffffffffc02abb78 <ide>
ffffffffc0200612:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc0200616:	1141                	addi	sp,sp,-16
ffffffffc0200618:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc020061a:	95be                	add	a1,a1,a5
ffffffffc020061c:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc0200620:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200622:	124060ef          	jal	ra,ffffffffc0206746 <memcpy>
    return 0;
}
ffffffffc0200626:	60a2                	ld	ra,8(sp)
ffffffffc0200628:	4501                	li	a0,0
ffffffffc020062a:	0141                	addi	sp,sp,16
ffffffffc020062c:	8082                	ret

ffffffffc020062e <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
ffffffffc020062e:	8732                	mv	a4,a2
    int iobase = secno * SECTSIZE;
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200630:	0095979b          	slliw	a5,a1,0x9
ffffffffc0200634:	000ab517          	auipc	a0,0xab
ffffffffc0200638:	54450513          	addi	a0,a0,1348 # ffffffffc02abb78 <ide>
                   size_t nsecs) {
ffffffffc020063c:	1141                	addi	sp,sp,-16
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020063e:	00969613          	slli	a2,a3,0x9
ffffffffc0200642:	85ba                	mv	a1,a4
ffffffffc0200644:	953e                	add	a0,a0,a5
                   size_t nsecs) {
ffffffffc0200646:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200648:	0fe060ef          	jal	ra,ffffffffc0206746 <memcpy>
    return 0;
}
ffffffffc020064c:	60a2                	ld	ra,8(sp)
ffffffffc020064e:	4501                	li	a0,0
ffffffffc0200650:	0141                	addi	sp,sp,16
ffffffffc0200652:	8082                	ret

ffffffffc0200654 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200654:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200658:	8082                	ret

ffffffffc020065a <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020065a:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020065e:	8082                	ret

ffffffffc0200660 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200660:	8082                	ret

ffffffffc0200662 <idt_init>:
void
idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200662:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200666:	00000797          	auipc	a5,0x0
ffffffffc020066a:	67a78793          	addi	a5,a5,1658 # ffffffffc0200ce0 <__alltraps>
ffffffffc020066e:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200672:	000407b7          	lui	a5,0x40
ffffffffc0200676:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020067a:	8082                	ret

ffffffffc020067c <print_regs>:
    cprintf("  tval 0x%08x\n", tf->tval);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs* gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020067c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs* gpr) {
ffffffffc020067e:	1141                	addi	sp,sp,-16
ffffffffc0200680:	e022                	sd	s0,0(sp)
ffffffffc0200682:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200684:	00006517          	auipc	a0,0x6
ffffffffc0200688:	71450513          	addi	a0,a0,1812 # ffffffffc0206d98 <commands+0x508>
void print_regs(struct pushregs* gpr) {
ffffffffc020068c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020068e:	b01ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200692:	640c                	ld	a1,8(s0)
ffffffffc0200694:	00006517          	auipc	a0,0x6
ffffffffc0200698:	71c50513          	addi	a0,a0,1820 # ffffffffc0206db0 <commands+0x520>
ffffffffc020069c:	af3ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02006a0:	680c                	ld	a1,16(s0)
ffffffffc02006a2:	00006517          	auipc	a0,0x6
ffffffffc02006a6:	72650513          	addi	a0,a0,1830 # ffffffffc0206dc8 <commands+0x538>
ffffffffc02006aa:	ae5ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02006ae:	6c0c                	ld	a1,24(s0)
ffffffffc02006b0:	00006517          	auipc	a0,0x6
ffffffffc02006b4:	73050513          	addi	a0,a0,1840 # ffffffffc0206de0 <commands+0x550>
ffffffffc02006b8:	ad7ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02006bc:	700c                	ld	a1,32(s0)
ffffffffc02006be:	00006517          	auipc	a0,0x6
ffffffffc02006c2:	73a50513          	addi	a0,a0,1850 # ffffffffc0206df8 <commands+0x568>
ffffffffc02006c6:	ac9ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02006ca:	740c                	ld	a1,40(s0)
ffffffffc02006cc:	00006517          	auipc	a0,0x6
ffffffffc02006d0:	74450513          	addi	a0,a0,1860 # ffffffffc0206e10 <commands+0x580>
ffffffffc02006d4:	abbff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02006d8:	780c                	ld	a1,48(s0)
ffffffffc02006da:	00006517          	auipc	a0,0x6
ffffffffc02006de:	74e50513          	addi	a0,a0,1870 # ffffffffc0206e28 <commands+0x598>
ffffffffc02006e2:	aadff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006e6:	7c0c                	ld	a1,56(s0)
ffffffffc02006e8:	00006517          	auipc	a0,0x6
ffffffffc02006ec:	75850513          	addi	a0,a0,1880 # ffffffffc0206e40 <commands+0x5b0>
ffffffffc02006f0:	a9fff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006f4:	602c                	ld	a1,64(s0)
ffffffffc02006f6:	00006517          	auipc	a0,0x6
ffffffffc02006fa:	76250513          	addi	a0,a0,1890 # ffffffffc0206e58 <commands+0x5c8>
ffffffffc02006fe:	a91ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200702:	642c                	ld	a1,72(s0)
ffffffffc0200704:	00006517          	auipc	a0,0x6
ffffffffc0200708:	76c50513          	addi	a0,a0,1900 # ffffffffc0206e70 <commands+0x5e0>
ffffffffc020070c:	a83ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200710:	682c                	ld	a1,80(s0)
ffffffffc0200712:	00006517          	auipc	a0,0x6
ffffffffc0200716:	77650513          	addi	a0,a0,1910 # ffffffffc0206e88 <commands+0x5f8>
ffffffffc020071a:	a75ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020071e:	6c2c                	ld	a1,88(s0)
ffffffffc0200720:	00006517          	auipc	a0,0x6
ffffffffc0200724:	78050513          	addi	a0,a0,1920 # ffffffffc0206ea0 <commands+0x610>
ffffffffc0200728:	a67ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020072c:	702c                	ld	a1,96(s0)
ffffffffc020072e:	00006517          	auipc	a0,0x6
ffffffffc0200732:	78a50513          	addi	a0,a0,1930 # ffffffffc0206eb8 <commands+0x628>
ffffffffc0200736:	a59ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020073a:	742c                	ld	a1,104(s0)
ffffffffc020073c:	00006517          	auipc	a0,0x6
ffffffffc0200740:	79450513          	addi	a0,a0,1940 # ffffffffc0206ed0 <commands+0x640>
ffffffffc0200744:	a4bff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200748:	782c                	ld	a1,112(s0)
ffffffffc020074a:	00006517          	auipc	a0,0x6
ffffffffc020074e:	79e50513          	addi	a0,a0,1950 # ffffffffc0206ee8 <commands+0x658>
ffffffffc0200752:	a3dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200756:	7c2c                	ld	a1,120(s0)
ffffffffc0200758:	00006517          	auipc	a0,0x6
ffffffffc020075c:	7a850513          	addi	a0,a0,1960 # ffffffffc0206f00 <commands+0x670>
ffffffffc0200760:	a2fff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200764:	604c                	ld	a1,128(s0)
ffffffffc0200766:	00006517          	auipc	a0,0x6
ffffffffc020076a:	7b250513          	addi	a0,a0,1970 # ffffffffc0206f18 <commands+0x688>
ffffffffc020076e:	a21ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200772:	644c                	ld	a1,136(s0)
ffffffffc0200774:	00006517          	auipc	a0,0x6
ffffffffc0200778:	7bc50513          	addi	a0,a0,1980 # ffffffffc0206f30 <commands+0x6a0>
ffffffffc020077c:	a13ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200780:	684c                	ld	a1,144(s0)
ffffffffc0200782:	00006517          	auipc	a0,0x6
ffffffffc0200786:	7c650513          	addi	a0,a0,1990 # ffffffffc0206f48 <commands+0x6b8>
ffffffffc020078a:	a05ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020078e:	6c4c                	ld	a1,152(s0)
ffffffffc0200790:	00006517          	auipc	a0,0x6
ffffffffc0200794:	7d050513          	addi	a0,a0,2000 # ffffffffc0206f60 <commands+0x6d0>
ffffffffc0200798:	9f7ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020079c:	704c                	ld	a1,160(s0)
ffffffffc020079e:	00006517          	auipc	a0,0x6
ffffffffc02007a2:	7da50513          	addi	a0,a0,2010 # ffffffffc0206f78 <commands+0x6e8>
ffffffffc02007a6:	9e9ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02007aa:	744c                	ld	a1,168(s0)
ffffffffc02007ac:	00006517          	auipc	a0,0x6
ffffffffc02007b0:	7e450513          	addi	a0,a0,2020 # ffffffffc0206f90 <commands+0x700>
ffffffffc02007b4:	9dbff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02007b8:	784c                	ld	a1,176(s0)
ffffffffc02007ba:	00006517          	auipc	a0,0x6
ffffffffc02007be:	7ee50513          	addi	a0,a0,2030 # ffffffffc0206fa8 <commands+0x718>
ffffffffc02007c2:	9cdff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02007c6:	7c4c                	ld	a1,184(s0)
ffffffffc02007c8:	00006517          	auipc	a0,0x6
ffffffffc02007cc:	7f850513          	addi	a0,a0,2040 # ffffffffc0206fc0 <commands+0x730>
ffffffffc02007d0:	9bfff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02007d4:	606c                	ld	a1,192(s0)
ffffffffc02007d6:	00007517          	auipc	a0,0x7
ffffffffc02007da:	80250513          	addi	a0,a0,-2046 # ffffffffc0206fd8 <commands+0x748>
ffffffffc02007de:	9b1ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007e2:	646c                	ld	a1,200(s0)
ffffffffc02007e4:	00007517          	auipc	a0,0x7
ffffffffc02007e8:	80c50513          	addi	a0,a0,-2036 # ffffffffc0206ff0 <commands+0x760>
ffffffffc02007ec:	9a3ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007f0:	686c                	ld	a1,208(s0)
ffffffffc02007f2:	00007517          	auipc	a0,0x7
ffffffffc02007f6:	81650513          	addi	a0,a0,-2026 # ffffffffc0207008 <commands+0x778>
ffffffffc02007fa:	995ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007fe:	6c6c                	ld	a1,216(s0)
ffffffffc0200800:	00007517          	auipc	a0,0x7
ffffffffc0200804:	82050513          	addi	a0,a0,-2016 # ffffffffc0207020 <commands+0x790>
ffffffffc0200808:	987ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020080c:	706c                	ld	a1,224(s0)
ffffffffc020080e:	00007517          	auipc	a0,0x7
ffffffffc0200812:	82a50513          	addi	a0,a0,-2006 # ffffffffc0207038 <commands+0x7a8>
ffffffffc0200816:	979ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020081a:	746c                	ld	a1,232(s0)
ffffffffc020081c:	00007517          	auipc	a0,0x7
ffffffffc0200820:	83450513          	addi	a0,a0,-1996 # ffffffffc0207050 <commands+0x7c0>
ffffffffc0200824:	96bff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200828:	786c                	ld	a1,240(s0)
ffffffffc020082a:	00007517          	auipc	a0,0x7
ffffffffc020082e:	83e50513          	addi	a0,a0,-1986 # ffffffffc0207068 <commands+0x7d8>
ffffffffc0200832:	95dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200836:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200838:	6402                	ld	s0,0(sp)
ffffffffc020083a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020083c:	00007517          	auipc	a0,0x7
ffffffffc0200840:	84450513          	addi	a0,a0,-1980 # ffffffffc0207080 <commands+0x7f0>
}
ffffffffc0200844:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200846:	949ff06f          	j	ffffffffc020018e <cprintf>

ffffffffc020084a <print_trapframe>:
print_trapframe(struct trapframe *tf) {
ffffffffc020084a:	1141                	addi	sp,sp,-16
ffffffffc020084c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020084e:	85aa                	mv	a1,a0
print_trapframe(struct trapframe *tf) {
ffffffffc0200850:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200852:	00007517          	auipc	a0,0x7
ffffffffc0200856:	84650513          	addi	a0,a0,-1978 # ffffffffc0207098 <commands+0x808>
print_trapframe(struct trapframe *tf) {
ffffffffc020085a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020085c:	933ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200860:	8522                	mv	a0,s0
ffffffffc0200862:	e1bff0ef          	jal	ra,ffffffffc020067c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200866:	10043583          	ld	a1,256(s0)
ffffffffc020086a:	00007517          	auipc	a0,0x7
ffffffffc020086e:	84650513          	addi	a0,a0,-1978 # ffffffffc02070b0 <commands+0x820>
ffffffffc0200872:	91dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200876:	10843583          	ld	a1,264(s0)
ffffffffc020087a:	00007517          	auipc	a0,0x7
ffffffffc020087e:	84e50513          	addi	a0,a0,-1970 # ffffffffc02070c8 <commands+0x838>
ffffffffc0200882:	90dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200886:	11043583          	ld	a1,272(s0)
ffffffffc020088a:	00007517          	auipc	a0,0x7
ffffffffc020088e:	85650513          	addi	a0,a0,-1962 # ffffffffc02070e0 <commands+0x850>
ffffffffc0200892:	8fdff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200896:	11843583          	ld	a1,280(s0)
}
ffffffffc020089a:	6402                	ld	s0,0(sp)
ffffffffc020089c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020089e:	00007517          	auipc	a0,0x7
ffffffffc02008a2:	85250513          	addi	a0,a0,-1966 # ffffffffc02070f0 <commands+0x860>
}
ffffffffc02008a6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02008a8:	8e7ff06f          	j	ffffffffc020018e <cprintf>

ffffffffc02008ac <pgfault_handler>:
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int
pgfault_handler(struct trapframe *tf) {
ffffffffc02008ac:	1101                	addi	sp,sp,-32
ffffffffc02008ae:	e426                	sd	s1,8(sp)
    extern struct mm_struct *check_mm_struct;
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc02008b0:	000b6497          	auipc	s1,0xb6
ffffffffc02008b4:	43848493          	addi	s1,s1,1080 # ffffffffc02b6ce8 <check_mm_struct>
ffffffffc02008b8:	609c                	ld	a5,0(s1)
pgfault_handler(struct trapframe *tf) {
ffffffffc02008ba:	e822                	sd	s0,16(sp)
ffffffffc02008bc:	ec06                	sd	ra,24(sp)
ffffffffc02008be:	842a                	mv	s0,a0
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc02008c0:	cbbd                	beqz	a5,ffffffffc0200936 <pgfault_handler+0x8a>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008c2:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008c6:	11053583          	ld	a1,272(a0)
ffffffffc02008ca:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008ce:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008d2:	cba1                	beqz	a5,ffffffffc0200922 <pgfault_handler+0x76>
ffffffffc02008d4:	11843703          	ld	a4,280(s0)
ffffffffc02008d8:	47bd                	li	a5,15
ffffffffc02008da:	05700693          	li	a3,87
ffffffffc02008de:	00f70463          	beq	a4,a5,ffffffffc02008e6 <pgfault_handler+0x3a>
ffffffffc02008e2:	05200693          	li	a3,82
ffffffffc02008e6:	00006517          	auipc	a0,0x6
ffffffffc02008ea:	43250513          	addi	a0,a0,1074 # ffffffffc0206d18 <commands+0x488>
ffffffffc02008ee:	8a1ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            print_pgfault(tf);
        }
    struct mm_struct *mm;
    if (check_mm_struct != NULL) {
ffffffffc02008f2:	6088                	ld	a0,0(s1)
ffffffffc02008f4:	c129                	beqz	a0,ffffffffc0200936 <pgfault_handler+0x8a>
        assert(current == idleproc);
ffffffffc02008f6:	000b6797          	auipc	a5,0xb6
ffffffffc02008fa:	2ba78793          	addi	a5,a5,698 # ffffffffc02b6bb0 <current>
ffffffffc02008fe:	6398                	ld	a4,0(a5)
ffffffffc0200900:	000b6797          	auipc	a5,0xb6
ffffffffc0200904:	2b878793          	addi	a5,a5,696 # ffffffffc02b6bb8 <idleproc>
ffffffffc0200908:	639c                	ld	a5,0(a5)
ffffffffc020090a:	04f71763          	bne	a4,a5,ffffffffc0200958 <pgfault_handler+0xac>
            print_pgfault(tf);
            panic("unhandled page fault.\n");
        }
        mm = current->mm;
    }
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc020090e:	11043603          	ld	a2,272(s0)
ffffffffc0200912:	11843583          	ld	a1,280(s0)
}
ffffffffc0200916:	6442                	ld	s0,16(sp)
ffffffffc0200918:	60e2                	ld	ra,24(sp)
ffffffffc020091a:	64a2                	ld	s1,8(sp)
ffffffffc020091c:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc020091e:	0ee0406f          	j	ffffffffc0204a0c <do_pgfault>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200922:	11843703          	ld	a4,280(s0)
ffffffffc0200926:	47bd                	li	a5,15
ffffffffc0200928:	05500613          	li	a2,85
ffffffffc020092c:	05700693          	li	a3,87
ffffffffc0200930:	faf719e3          	bne	a4,a5,ffffffffc02008e2 <pgfault_handler+0x36>
ffffffffc0200934:	bf4d                	j	ffffffffc02008e6 <pgfault_handler+0x3a>
        if (current == NULL) {
ffffffffc0200936:	000b6797          	auipc	a5,0xb6
ffffffffc020093a:	27a78793          	addi	a5,a5,634 # ffffffffc02b6bb0 <current>
ffffffffc020093e:	639c                	ld	a5,0(a5)
ffffffffc0200940:	cf85                	beqz	a5,ffffffffc0200978 <pgfault_handler+0xcc>
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200942:	11043603          	ld	a2,272(s0)
ffffffffc0200946:	11843583          	ld	a1,280(s0)
}
ffffffffc020094a:	6442                	ld	s0,16(sp)
ffffffffc020094c:	60e2                	ld	ra,24(sp)
ffffffffc020094e:	64a2                	ld	s1,8(sp)
        mm = current->mm;
ffffffffc0200950:	7788                	ld	a0,40(a5)
}
ffffffffc0200952:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200954:	0b80406f          	j	ffffffffc0204a0c <do_pgfault>
        assert(current == idleproc);
ffffffffc0200958:	00006697          	auipc	a3,0x6
ffffffffc020095c:	3e068693          	addi	a3,a3,992 # ffffffffc0206d38 <commands+0x4a8>
ffffffffc0200960:	00006617          	auipc	a2,0x6
ffffffffc0200964:	3f060613          	addi	a2,a2,1008 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0200968:	06b00593          	li	a1,107
ffffffffc020096c:	00006517          	auipc	a0,0x6
ffffffffc0200970:	3fc50513          	addi	a0,a0,1020 # ffffffffc0206d68 <commands+0x4d8>
ffffffffc0200974:	b11ff0ef          	jal	ra,ffffffffc0200484 <__panic>
            print_trapframe(tf);
ffffffffc0200978:	8522                	mv	a0,s0
ffffffffc020097a:	ed1ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020097e:	10043783          	ld	a5,256(s0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200982:	11043583          	ld	a1,272(s0)
ffffffffc0200986:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020098a:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc020098e:	e399                	bnez	a5,ffffffffc0200994 <pgfault_handler+0xe8>
ffffffffc0200990:	05500613          	li	a2,85
ffffffffc0200994:	11843703          	ld	a4,280(s0)
ffffffffc0200998:	47bd                	li	a5,15
ffffffffc020099a:	02f70663          	beq	a4,a5,ffffffffc02009c6 <pgfault_handler+0x11a>
ffffffffc020099e:	05200693          	li	a3,82
ffffffffc02009a2:	00006517          	auipc	a0,0x6
ffffffffc02009a6:	37650513          	addi	a0,a0,886 # ffffffffc0206d18 <commands+0x488>
ffffffffc02009aa:	fe4ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            panic("unhandled page fault.\n");
ffffffffc02009ae:	00006617          	auipc	a2,0x6
ffffffffc02009b2:	3d260613          	addi	a2,a2,978 # ffffffffc0206d80 <commands+0x4f0>
ffffffffc02009b6:	07200593          	li	a1,114
ffffffffc02009ba:	00006517          	auipc	a0,0x6
ffffffffc02009be:	3ae50513          	addi	a0,a0,942 # ffffffffc0206d68 <commands+0x4d8>
ffffffffc02009c2:	ac3ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02009c6:	05700693          	li	a3,87
ffffffffc02009ca:	bfe1                	j	ffffffffc02009a2 <pgfault_handler+0xf6>

ffffffffc02009cc <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02009cc:	11853783          	ld	a5,280(a0)
ffffffffc02009d0:	577d                	li	a4,-1
ffffffffc02009d2:	8305                	srli	a4,a4,0x1
ffffffffc02009d4:	8ff9                	and	a5,a5,a4
    switch (cause) {
ffffffffc02009d6:	472d                	li	a4,11
ffffffffc02009d8:	08f76763          	bltu	a4,a5,ffffffffc0200a66 <interrupt_handler+0x9a>
ffffffffc02009dc:	00006717          	auipc	a4,0x6
ffffffffc02009e0:	09070713          	addi	a4,a4,144 # ffffffffc0206a6c <commands+0x1dc>
ffffffffc02009e4:	078a                	slli	a5,a5,0x2
ffffffffc02009e6:	97ba                	add	a5,a5,a4
ffffffffc02009e8:	439c                	lw	a5,0(a5)
ffffffffc02009ea:	97ba                	add	a5,a5,a4
ffffffffc02009ec:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02009ee:	00006517          	auipc	a0,0x6
ffffffffc02009f2:	2ea50513          	addi	a0,a0,746 # ffffffffc0206cd8 <commands+0x448>
ffffffffc02009f6:	f98ff06f          	j	ffffffffc020018e <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02009fa:	00006517          	auipc	a0,0x6
ffffffffc02009fe:	2be50513          	addi	a0,a0,702 # ffffffffc0206cb8 <commands+0x428>
ffffffffc0200a02:	f8cff06f          	j	ffffffffc020018e <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200a06:	00006517          	auipc	a0,0x6
ffffffffc0200a0a:	27250513          	addi	a0,a0,626 # ffffffffc0206c78 <commands+0x3e8>
ffffffffc0200a0e:	f80ff06f          	j	ffffffffc020018e <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200a12:	00006517          	auipc	a0,0x6
ffffffffc0200a16:	28650513          	addi	a0,a0,646 # ffffffffc0206c98 <commands+0x408>
ffffffffc0200a1a:	f74ff06f          	j	ffffffffc020018e <cprintf>
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
ffffffffc0200a1e:	00006517          	auipc	a0,0x6
ffffffffc0200a22:	2da50513          	addi	a0,a0,730 # ffffffffc0206cf8 <commands+0x468>
ffffffffc0200a26:	f68ff06f          	j	ffffffffc020018e <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a2a:	1141                	addi	sp,sp,-16
ffffffffc0200a2c:	e406                	sd	ra,8(sp)
            clock_set_next_event();
ffffffffc0200a2e:	b3fff0ef          	jal	ra,ffffffffc020056c <clock_set_next_event>
            if (++ticks % TICK_NUM == 0 && current) {
ffffffffc0200a32:	000b6797          	auipc	a5,0xb6
ffffffffc0200a36:	19e78793          	addi	a5,a5,414 # ffffffffc02b6bd0 <ticks>
ffffffffc0200a3a:	639c                	ld	a5,0(a5)
ffffffffc0200a3c:	06400713          	li	a4,100
ffffffffc0200a40:	0785                	addi	a5,a5,1
ffffffffc0200a42:	02e7f733          	remu	a4,a5,a4
ffffffffc0200a46:	000b6697          	auipc	a3,0xb6
ffffffffc0200a4a:	18f6b523          	sd	a5,394(a3) # ffffffffc02b6bd0 <ticks>
ffffffffc0200a4e:	eb09                	bnez	a4,ffffffffc0200a60 <interrupt_handler+0x94>
ffffffffc0200a50:	000b6797          	auipc	a5,0xb6
ffffffffc0200a54:	16078793          	addi	a5,a5,352 # ffffffffc02b6bb0 <current>
ffffffffc0200a58:	639c                	ld	a5,0(a5)
ffffffffc0200a5a:	c399                	beqz	a5,ffffffffc0200a60 <interrupt_handler+0x94>
                current->need_resched = 1;
ffffffffc0200a5c:	4705                	li	a4,1
ffffffffc0200a5e:	ef98                	sd	a4,24(a5)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a60:	60a2                	ld	ra,8(sp)
ffffffffc0200a62:	0141                	addi	sp,sp,16
ffffffffc0200a64:	8082                	ret
            print_trapframe(tf);
ffffffffc0200a66:	de5ff06f          	j	ffffffffc020084a <print_trapframe>

ffffffffc0200a6a <exception_handler>:
void kernel_execve_ret(struct trapframe *tf,uintptr_t kstacktop);
void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200a6a:	11853783          	ld	a5,280(a0)
ffffffffc0200a6e:	473d                	li	a4,15
ffffffffc0200a70:	1af76e63          	bltu	a4,a5,ffffffffc0200c2c <exception_handler+0x1c2>
ffffffffc0200a74:	00006717          	auipc	a4,0x6
ffffffffc0200a78:	02870713          	addi	a4,a4,40 # ffffffffc0206a9c <commands+0x20c>
ffffffffc0200a7c:	078a                	slli	a5,a5,0x2
ffffffffc0200a7e:	97ba                	add	a5,a5,a4
ffffffffc0200a80:	439c                	lw	a5,0(a5)
void exception_handler(struct trapframe *tf) {
ffffffffc0200a82:	1101                	addi	sp,sp,-32
ffffffffc0200a84:	e822                	sd	s0,16(sp)
ffffffffc0200a86:	ec06                	sd	ra,24(sp)
ffffffffc0200a88:	e426                	sd	s1,8(sp)
    switch (tf->cause) {
ffffffffc0200a8a:	97ba                	add	a5,a5,a4
ffffffffc0200a8c:	842a                	mv	s0,a0
ffffffffc0200a8e:	8782                	jr	a5
            //cprintf("Environment call from U-mode\n");
            tf->epc += 4;
            syscall();
            break;
        case CAUSE_SUPERVISOR_ECALL:
            cprintf("Environment call from S-mode\n");
ffffffffc0200a90:	00006517          	auipc	a0,0x6
ffffffffc0200a94:	14050513          	addi	a0,a0,320 # ffffffffc0206bd0 <commands+0x340>
ffffffffc0200a98:	ef6ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            tf->epc += 4;
ffffffffc0200a9c:	10843783          	ld	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200aa0:	60e2                	ld	ra,24(sp)
ffffffffc0200aa2:	64a2                	ld	s1,8(sp)
            tf->epc += 4;
ffffffffc0200aa4:	0791                	addi	a5,a5,4
ffffffffc0200aa6:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200aaa:	6442                	ld	s0,16(sp)
ffffffffc0200aac:	6105                	addi	sp,sp,32
            syscall();
ffffffffc0200aae:	7580506f          	j	ffffffffc0206206 <syscall>
            cprintf("Environment call from H-mode\n");
ffffffffc0200ab2:	00006517          	auipc	a0,0x6
ffffffffc0200ab6:	13e50513          	addi	a0,a0,318 # ffffffffc0206bf0 <commands+0x360>
}
ffffffffc0200aba:	6442                	ld	s0,16(sp)
ffffffffc0200abc:	60e2                	ld	ra,24(sp)
ffffffffc0200abe:	64a2                	ld	s1,8(sp)
ffffffffc0200ac0:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc0200ac2:	eccff06f          	j	ffffffffc020018e <cprintf>
            cprintf("Environment call from M-mode\n");
ffffffffc0200ac6:	00006517          	auipc	a0,0x6
ffffffffc0200aca:	14a50513          	addi	a0,a0,330 # ffffffffc0206c10 <commands+0x380>
ffffffffc0200ace:	b7f5                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200ad0:	00006517          	auipc	a0,0x6
ffffffffc0200ad4:	16050513          	addi	a0,a0,352 # ffffffffc0206c30 <commands+0x3a0>
ffffffffc0200ad8:	b7cd                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200ada:	00006517          	auipc	a0,0x6
ffffffffc0200ade:	16e50513          	addi	a0,a0,366 # ffffffffc0206c48 <commands+0x3b8>
ffffffffc0200ae2:	eacff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200ae6:	8522                	mv	a0,s0
ffffffffc0200ae8:	dc5ff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200aec:	84aa                	mv	s1,a0
ffffffffc0200aee:	14051163          	bnez	a0,ffffffffc0200c30 <exception_handler+0x1c6>
}
ffffffffc0200af2:	60e2                	ld	ra,24(sp)
ffffffffc0200af4:	6442                	ld	s0,16(sp)
ffffffffc0200af6:	64a2                	ld	s1,8(sp)
ffffffffc0200af8:	6105                	addi	sp,sp,32
ffffffffc0200afa:	8082                	ret
            cprintf("Store/AMO page fault\n");
ffffffffc0200afc:	00006517          	auipc	a0,0x6
ffffffffc0200b00:	16450513          	addi	a0,a0,356 # ffffffffc0206c60 <commands+0x3d0>
ffffffffc0200b04:	e8aff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200b08:	8522                	mv	a0,s0
ffffffffc0200b0a:	da3ff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200b0e:	84aa                	mv	s1,a0
ffffffffc0200b10:	d16d                	beqz	a0,ffffffffc0200af2 <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200b12:	8522                	mv	a0,s0
ffffffffc0200b14:	d37ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200b18:	86a6                	mv	a3,s1
ffffffffc0200b1a:	00006617          	auipc	a2,0x6
ffffffffc0200b1e:	06660613          	addi	a2,a2,102 # ffffffffc0206b80 <commands+0x2f0>
ffffffffc0200b22:	0f800593          	li	a1,248
ffffffffc0200b26:	00006517          	auipc	a0,0x6
ffffffffc0200b2a:	24250513          	addi	a0,a0,578 # ffffffffc0206d68 <commands+0x4d8>
ffffffffc0200b2e:	957ff0ef          	jal	ra,ffffffffc0200484 <__panic>
            cprintf("Instruction address misaligned\n");
ffffffffc0200b32:	00006517          	auipc	a0,0x6
ffffffffc0200b36:	fae50513          	addi	a0,a0,-82 # ffffffffc0206ae0 <commands+0x250>
ffffffffc0200b3a:	b741                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Instruction access fault\n");
ffffffffc0200b3c:	00006517          	auipc	a0,0x6
ffffffffc0200b40:	fc450513          	addi	a0,a0,-60 # ffffffffc0206b00 <commands+0x270>
ffffffffc0200b44:	bf9d                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc0200b46:	00006517          	auipc	a0,0x6
ffffffffc0200b4a:	fda50513          	addi	a0,a0,-38 # ffffffffc0206b20 <commands+0x290>
ffffffffc0200b4e:	b7b5                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc0200b50:	00006517          	auipc	a0,0x6
ffffffffc0200b54:	fe850513          	addi	a0,a0,-24 # ffffffffc0206b38 <commands+0x2a8>
ffffffffc0200b58:	e36ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if(tf->gpr.a7 == 10){
ffffffffc0200b5c:	6458                	ld	a4,136(s0)
ffffffffc0200b5e:	47a9                	li	a5,10
ffffffffc0200b60:	f8f719e3          	bne	a4,a5,ffffffffc0200af2 <exception_handler+0x88>
                tf->epc += 4;
ffffffffc0200b64:	10843783          	ld	a5,264(s0)
ffffffffc0200b68:	0791                	addi	a5,a5,4
ffffffffc0200b6a:	10f43423          	sd	a5,264(s0)
                syscall();
ffffffffc0200b6e:	698050ef          	jal	ra,ffffffffc0206206 <syscall>
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b72:	000b6797          	auipc	a5,0xb6
ffffffffc0200b76:	03e78793          	addi	a5,a5,62 # ffffffffc02b6bb0 <current>
ffffffffc0200b7a:	639c                	ld	a5,0(a5)
ffffffffc0200b7c:	8522                	mv	a0,s0
}
ffffffffc0200b7e:	6442                	ld	s0,16(sp)
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b80:	6b9c                	ld	a5,16(a5)
}
ffffffffc0200b82:	60e2                	ld	ra,24(sp)
ffffffffc0200b84:	64a2                	ld	s1,8(sp)
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b86:	6589                	lui	a1,0x2
ffffffffc0200b88:	95be                	add	a1,a1,a5
}
ffffffffc0200b8a:	6105                	addi	sp,sp,32
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b8c:	2220006f          	j	ffffffffc0200dae <kernel_execve_ret>
            cprintf("Load address misaligned\n");
ffffffffc0200b90:	00006517          	auipc	a0,0x6
ffffffffc0200b94:	fb850513          	addi	a0,a0,-72 # ffffffffc0206b48 <commands+0x2b8>
ffffffffc0200b98:	b70d                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc0200b9a:	00006517          	auipc	a0,0x6
ffffffffc0200b9e:	fce50513          	addi	a0,a0,-50 # ffffffffc0206b68 <commands+0x2d8>
ffffffffc0200ba2:	decff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200ba6:	8522                	mv	a0,s0
ffffffffc0200ba8:	d05ff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200bac:	84aa                	mv	s1,a0
ffffffffc0200bae:	d131                	beqz	a0,ffffffffc0200af2 <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200bb0:	8522                	mv	a0,s0
ffffffffc0200bb2:	c99ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200bb6:	86a6                	mv	a3,s1
ffffffffc0200bb8:	00006617          	auipc	a2,0x6
ffffffffc0200bbc:	fc860613          	addi	a2,a2,-56 # ffffffffc0206b80 <commands+0x2f0>
ffffffffc0200bc0:	0cd00593          	li	a1,205
ffffffffc0200bc4:	00006517          	auipc	a0,0x6
ffffffffc0200bc8:	1a450513          	addi	a0,a0,420 # ffffffffc0206d68 <commands+0x4d8>
ffffffffc0200bcc:	8b9ff0ef          	jal	ra,ffffffffc0200484 <__panic>
            cprintf("Store/AMO access fault\n");
ffffffffc0200bd0:	00006517          	auipc	a0,0x6
ffffffffc0200bd4:	fe850513          	addi	a0,a0,-24 # ffffffffc0206bb8 <commands+0x328>
ffffffffc0200bd8:	db6ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200bdc:	8522                	mv	a0,s0
ffffffffc0200bde:	ccfff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200be2:	84aa                	mv	s1,a0
ffffffffc0200be4:	f00507e3          	beqz	a0,ffffffffc0200af2 <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200be8:	8522                	mv	a0,s0
ffffffffc0200bea:	c61ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200bee:	86a6                	mv	a3,s1
ffffffffc0200bf0:	00006617          	auipc	a2,0x6
ffffffffc0200bf4:	f9060613          	addi	a2,a2,-112 # ffffffffc0206b80 <commands+0x2f0>
ffffffffc0200bf8:	0d700593          	li	a1,215
ffffffffc0200bfc:	00006517          	auipc	a0,0x6
ffffffffc0200c00:	16c50513          	addi	a0,a0,364 # ffffffffc0206d68 <commands+0x4d8>
ffffffffc0200c04:	881ff0ef          	jal	ra,ffffffffc0200484 <__panic>
}
ffffffffc0200c08:	6442                	ld	s0,16(sp)
ffffffffc0200c0a:	60e2                	ld	ra,24(sp)
ffffffffc0200c0c:	64a2                	ld	s1,8(sp)
ffffffffc0200c0e:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200c10:	c3bff06f          	j	ffffffffc020084a <print_trapframe>
            panic("AMO address misaligned\n");
ffffffffc0200c14:	00006617          	auipc	a2,0x6
ffffffffc0200c18:	f8c60613          	addi	a2,a2,-116 # ffffffffc0206ba0 <commands+0x310>
ffffffffc0200c1c:	0d100593          	li	a1,209
ffffffffc0200c20:	00006517          	auipc	a0,0x6
ffffffffc0200c24:	14850513          	addi	a0,a0,328 # ffffffffc0206d68 <commands+0x4d8>
ffffffffc0200c28:	85dff0ef          	jal	ra,ffffffffc0200484 <__panic>
            print_trapframe(tf);
ffffffffc0200c2c:	c1fff06f          	j	ffffffffc020084a <print_trapframe>
                print_trapframe(tf);
ffffffffc0200c30:	8522                	mv	a0,s0
ffffffffc0200c32:	c19ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200c36:	86a6                	mv	a3,s1
ffffffffc0200c38:	00006617          	auipc	a2,0x6
ffffffffc0200c3c:	f4860613          	addi	a2,a2,-184 # ffffffffc0206b80 <commands+0x2f0>
ffffffffc0200c40:	0f100593          	li	a1,241
ffffffffc0200c44:	00006517          	auipc	a0,0x6
ffffffffc0200c48:	12450513          	addi	a0,a0,292 # ffffffffc0206d68 <commands+0x4d8>
ffffffffc0200c4c:	839ff0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0200c50 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
ffffffffc0200c50:	1101                	addi	sp,sp,-32
ffffffffc0200c52:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
//    cputs("some trap");
    if (current == NULL) {
ffffffffc0200c54:	000b6417          	auipc	s0,0xb6
ffffffffc0200c58:	f5c40413          	addi	s0,s0,-164 # ffffffffc02b6bb0 <current>
ffffffffc0200c5c:	6018                	ld	a4,0(s0)
trap(struct trapframe *tf) {
ffffffffc0200c5e:	ec06                	sd	ra,24(sp)
ffffffffc0200c60:	e426                	sd	s1,8(sp)
ffffffffc0200c62:	e04a                	sd	s2,0(sp)
ffffffffc0200c64:	11853683          	ld	a3,280(a0)
    if (current == NULL) {
ffffffffc0200c68:	cf1d                	beqz	a4,ffffffffc0200ca6 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c6a:	10053483          	ld	s1,256(a0)
        trap_dispatch(tf);
    } else {
        struct trapframe *otf = current->tf;
ffffffffc0200c6e:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200c72:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c74:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c78:	0206c463          	bltz	a3,ffffffffc0200ca0 <trap+0x50>
        exception_handler(tf);
ffffffffc0200c7c:	defff0ef          	jal	ra,ffffffffc0200a6a <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200c80:	601c                	ld	a5,0(s0)
ffffffffc0200c82:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel) {
ffffffffc0200c86:	e499                	bnez	s1,ffffffffc0200c94 <trap+0x44>
            if (current->flags & PF_EXITING) {
ffffffffc0200c88:	0b07a703          	lw	a4,176(a5)
ffffffffc0200c8c:	8b05                	andi	a4,a4,1
ffffffffc0200c8e:	e339                	bnez	a4,ffffffffc0200cd4 <trap+0x84>
                do_exit(-E_KILLED);
            }
            if (current->need_resched) {
ffffffffc0200c90:	6f9c                	ld	a5,24(a5)
ffffffffc0200c92:	eb95                	bnez	a5,ffffffffc0200cc6 <trap+0x76>
                schedule();
            }
        }
    }
}
ffffffffc0200c94:	60e2                	ld	ra,24(sp)
ffffffffc0200c96:	6442                	ld	s0,16(sp)
ffffffffc0200c98:	64a2                	ld	s1,8(sp)
ffffffffc0200c9a:	6902                	ld	s2,0(sp)
ffffffffc0200c9c:	6105                	addi	sp,sp,32
ffffffffc0200c9e:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200ca0:	d2dff0ef          	jal	ra,ffffffffc02009cc <interrupt_handler>
ffffffffc0200ca4:	bff1                	j	ffffffffc0200c80 <trap+0x30>
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200ca6:	0006c963          	bltz	a3,ffffffffc0200cb8 <trap+0x68>
}
ffffffffc0200caa:	6442                	ld	s0,16(sp)
ffffffffc0200cac:	60e2                	ld	ra,24(sp)
ffffffffc0200cae:	64a2                	ld	s1,8(sp)
ffffffffc0200cb0:	6902                	ld	s2,0(sp)
ffffffffc0200cb2:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200cb4:	db7ff06f          	j	ffffffffc0200a6a <exception_handler>
}
ffffffffc0200cb8:	6442                	ld	s0,16(sp)
ffffffffc0200cba:	60e2                	ld	ra,24(sp)
ffffffffc0200cbc:	64a2                	ld	s1,8(sp)
ffffffffc0200cbe:	6902                	ld	s2,0(sp)
ffffffffc0200cc0:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200cc2:	d0bff06f          	j	ffffffffc02009cc <interrupt_handler>
}
ffffffffc0200cc6:	6442                	ld	s0,16(sp)
ffffffffc0200cc8:	60e2                	ld	ra,24(sp)
ffffffffc0200cca:	64a2                	ld	s1,8(sp)
ffffffffc0200ccc:	6902                	ld	s2,0(sp)
ffffffffc0200cce:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200cd0:	4400506f          	j	ffffffffc0206110 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200cd4:	555d                	li	a0,-9
ffffffffc0200cd6:	035040ef          	jal	ra,ffffffffc020550a <do_exit>
ffffffffc0200cda:	601c                	ld	a5,0(s0)
ffffffffc0200cdc:	bf55                	j	ffffffffc0200c90 <trap+0x40>
	...

ffffffffc0200ce0 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200ce0:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200ce4:	00011463          	bnez	sp,ffffffffc0200cec <__alltraps+0xc>
ffffffffc0200ce8:	14002173          	csrr	sp,sscratch
ffffffffc0200cec:	712d                	addi	sp,sp,-288
ffffffffc0200cee:	e002                	sd	zero,0(sp)
ffffffffc0200cf0:	e406                	sd	ra,8(sp)
ffffffffc0200cf2:	ec0e                	sd	gp,24(sp)
ffffffffc0200cf4:	f012                	sd	tp,32(sp)
ffffffffc0200cf6:	f416                	sd	t0,40(sp)
ffffffffc0200cf8:	f81a                	sd	t1,48(sp)
ffffffffc0200cfa:	fc1e                	sd	t2,56(sp)
ffffffffc0200cfc:	e0a2                	sd	s0,64(sp)
ffffffffc0200cfe:	e4a6                	sd	s1,72(sp)
ffffffffc0200d00:	e8aa                	sd	a0,80(sp)
ffffffffc0200d02:	ecae                	sd	a1,88(sp)
ffffffffc0200d04:	f0b2                	sd	a2,96(sp)
ffffffffc0200d06:	f4b6                	sd	a3,104(sp)
ffffffffc0200d08:	f8ba                	sd	a4,112(sp)
ffffffffc0200d0a:	fcbe                	sd	a5,120(sp)
ffffffffc0200d0c:	e142                	sd	a6,128(sp)
ffffffffc0200d0e:	e546                	sd	a7,136(sp)
ffffffffc0200d10:	e94a                	sd	s2,144(sp)
ffffffffc0200d12:	ed4e                	sd	s3,152(sp)
ffffffffc0200d14:	f152                	sd	s4,160(sp)
ffffffffc0200d16:	f556                	sd	s5,168(sp)
ffffffffc0200d18:	f95a                	sd	s6,176(sp)
ffffffffc0200d1a:	fd5e                	sd	s7,184(sp)
ffffffffc0200d1c:	e1e2                	sd	s8,192(sp)
ffffffffc0200d1e:	e5e6                	sd	s9,200(sp)
ffffffffc0200d20:	e9ea                	sd	s10,208(sp)
ffffffffc0200d22:	edee                	sd	s11,216(sp)
ffffffffc0200d24:	f1f2                	sd	t3,224(sp)
ffffffffc0200d26:	f5f6                	sd	t4,232(sp)
ffffffffc0200d28:	f9fa                	sd	t5,240(sp)
ffffffffc0200d2a:	fdfe                	sd	t6,248(sp)
ffffffffc0200d2c:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200d30:	100024f3          	csrr	s1,sstatus
ffffffffc0200d34:	14102973          	csrr	s2,sepc
ffffffffc0200d38:	143029f3          	csrr	s3,stval
ffffffffc0200d3c:	14202a73          	csrr	s4,scause
ffffffffc0200d40:	e822                	sd	s0,16(sp)
ffffffffc0200d42:	e226                	sd	s1,256(sp)
ffffffffc0200d44:	e64a                	sd	s2,264(sp)
ffffffffc0200d46:	ea4e                	sd	s3,272(sp)
ffffffffc0200d48:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d4a:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d4c:	f05ff0ef          	jal	ra,ffffffffc0200c50 <trap>

ffffffffc0200d50 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d50:	6492                	ld	s1,256(sp)
ffffffffc0200d52:	6932                	ld	s2,264(sp)
ffffffffc0200d54:	1004f413          	andi	s0,s1,256
ffffffffc0200d58:	e401                	bnez	s0,ffffffffc0200d60 <__trapret+0x10>
ffffffffc0200d5a:	1200                	addi	s0,sp,288
ffffffffc0200d5c:	14041073          	csrw	sscratch,s0
ffffffffc0200d60:	10049073          	csrw	sstatus,s1
ffffffffc0200d64:	14191073          	csrw	sepc,s2
ffffffffc0200d68:	60a2                	ld	ra,8(sp)
ffffffffc0200d6a:	61e2                	ld	gp,24(sp)
ffffffffc0200d6c:	7202                	ld	tp,32(sp)
ffffffffc0200d6e:	72a2                	ld	t0,40(sp)
ffffffffc0200d70:	7342                	ld	t1,48(sp)
ffffffffc0200d72:	73e2                	ld	t2,56(sp)
ffffffffc0200d74:	6406                	ld	s0,64(sp)
ffffffffc0200d76:	64a6                	ld	s1,72(sp)
ffffffffc0200d78:	6546                	ld	a0,80(sp)
ffffffffc0200d7a:	65e6                	ld	a1,88(sp)
ffffffffc0200d7c:	7606                	ld	a2,96(sp)
ffffffffc0200d7e:	76a6                	ld	a3,104(sp)
ffffffffc0200d80:	7746                	ld	a4,112(sp)
ffffffffc0200d82:	77e6                	ld	a5,120(sp)
ffffffffc0200d84:	680a                	ld	a6,128(sp)
ffffffffc0200d86:	68aa                	ld	a7,136(sp)
ffffffffc0200d88:	694a                	ld	s2,144(sp)
ffffffffc0200d8a:	69ea                	ld	s3,152(sp)
ffffffffc0200d8c:	7a0a                	ld	s4,160(sp)
ffffffffc0200d8e:	7aaa                	ld	s5,168(sp)
ffffffffc0200d90:	7b4a                	ld	s6,176(sp)
ffffffffc0200d92:	7bea                	ld	s7,184(sp)
ffffffffc0200d94:	6c0e                	ld	s8,192(sp)
ffffffffc0200d96:	6cae                	ld	s9,200(sp)
ffffffffc0200d98:	6d4e                	ld	s10,208(sp)
ffffffffc0200d9a:	6dee                	ld	s11,216(sp)
ffffffffc0200d9c:	7e0e                	ld	t3,224(sp)
ffffffffc0200d9e:	7eae                	ld	t4,232(sp)
ffffffffc0200da0:	7f4e                	ld	t5,240(sp)
ffffffffc0200da2:	7fee                	ld	t6,248(sp)
ffffffffc0200da4:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200da6:	10200073          	sret

ffffffffc0200daa <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200daa:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200dac:	b755                	j	ffffffffc0200d50 <__trapret>

ffffffffc0200dae <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process       a0 = trapframe a1=kstacktop
    //其实trapframe就是处于内核栈顶
    addi a1, a1, -36*REGBYTES
ffffffffc0200dae:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x76a0>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200db2:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200db6:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200dba:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200dbe:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200dc2:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200dc6:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200dca:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200dce:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200dd2:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200dd4:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200dd6:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200dd8:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200dda:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200ddc:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200dde:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200de0:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200de2:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200de4:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200de6:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200de8:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200dea:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200dec:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200dee:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200df0:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200df2:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200df4:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200df6:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200df8:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200dfa:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200dfc:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200dfe:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200e00:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200e02:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200e04:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200e06:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200e08:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200e0a:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200e0c:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200e0e:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200e10:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200e12:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200e14:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200e16:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200e18:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200e1a:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200e1c:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200e1e:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200e20:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200e22:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200e24:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200e26:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200e28:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200e2a:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200e2c:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200e2e:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200e30:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200e32:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200e34:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200e36:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200e38:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200e3a:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200e3c:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200e3e:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200e40:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200e42:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200e44:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200e46:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200e48:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200e4a:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200e4c:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200e4e:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200e50:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    //调整sp到新进程的内核栈顶
    move sp, a1
ffffffffc0200e52:	812e                	mv	sp,a1
ffffffffc0200e54:	bdf5                	j	ffffffffc0200d50 <__trapret>

ffffffffc0200e56 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200e56:	000b6797          	auipc	a5,0xb6
ffffffffc0200e5a:	d8278793          	addi	a5,a5,-638 # ffffffffc02b6bd8 <free_area>
ffffffffc0200e5e:	e79c                	sd	a5,8(a5)
ffffffffc0200e60:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200e62:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200e66:	8082                	ret

ffffffffc0200e68 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200e68:	000b6517          	auipc	a0,0xb6
ffffffffc0200e6c:	d8056503          	lwu	a0,-640(a0) # ffffffffc02b6be8 <free_area+0x10>
ffffffffc0200e70:	8082                	ret

ffffffffc0200e72 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200e72:	715d                	addi	sp,sp,-80
ffffffffc0200e74:	f84a                	sd	s2,48(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200e76:	000b6917          	auipc	s2,0xb6
ffffffffc0200e7a:	d6290913          	addi	s2,s2,-670 # ffffffffc02b6bd8 <free_area>
ffffffffc0200e7e:	00893783          	ld	a5,8(s2)
ffffffffc0200e82:	e486                	sd	ra,72(sp)
ffffffffc0200e84:	e0a2                	sd	s0,64(sp)
ffffffffc0200e86:	fc26                	sd	s1,56(sp)
ffffffffc0200e88:	f44e                	sd	s3,40(sp)
ffffffffc0200e8a:	f052                	sd	s4,32(sp)
ffffffffc0200e8c:	ec56                	sd	s5,24(sp)
ffffffffc0200e8e:	e85a                	sd	s6,16(sp)
ffffffffc0200e90:	e45e                	sd	s7,8(sp)
ffffffffc0200e92:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e94:	31278463          	beq	a5,s2,ffffffffc020119c <default_check+0x32a>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200e98:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200e9c:	8305                	srli	a4,a4,0x1
ffffffffc0200e9e:	8b05                	andi	a4,a4,1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200ea0:	30070263          	beqz	a4,ffffffffc02011a4 <default_check+0x332>
    int count = 0, total = 0;
ffffffffc0200ea4:	4401                	li	s0,0
ffffffffc0200ea6:	4481                	li	s1,0
ffffffffc0200ea8:	a031                	j	ffffffffc0200eb4 <default_check+0x42>
ffffffffc0200eaa:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc0200eae:	8b09                	andi	a4,a4,2
ffffffffc0200eb0:	2e070a63          	beqz	a4,ffffffffc02011a4 <default_check+0x332>
        count ++, total += p->property;
ffffffffc0200eb4:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200eb8:	679c                	ld	a5,8(a5)
ffffffffc0200eba:	2485                	addiw	s1,s1,1
ffffffffc0200ebc:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ebe:	ff2796e3          	bne	a5,s2,ffffffffc0200eaa <default_check+0x38>
ffffffffc0200ec2:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0200ec4:	05c010ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
ffffffffc0200ec8:	73351e63          	bne	a0,s3,ffffffffc0201604 <default_check+0x792>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ecc:	4505                	li	a0,1
ffffffffc0200ece:	785000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200ed2:	8a2a                	mv	s4,a0
ffffffffc0200ed4:	46050863          	beqz	a0,ffffffffc0201344 <default_check+0x4d2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ed8:	4505                	li	a0,1
ffffffffc0200eda:	779000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200ede:	89aa                	mv	s3,a0
ffffffffc0200ee0:	74050263          	beqz	a0,ffffffffc0201624 <default_check+0x7b2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ee4:	4505                	li	a0,1
ffffffffc0200ee6:	76d000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200eea:	8aaa                	mv	s5,a0
ffffffffc0200eec:	4c050c63          	beqz	a0,ffffffffc02013c4 <default_check+0x552>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ef0:	2d3a0a63          	beq	s4,s3,ffffffffc02011c4 <default_check+0x352>
ffffffffc0200ef4:	2caa0863          	beq	s4,a0,ffffffffc02011c4 <default_check+0x352>
ffffffffc0200ef8:	2ca98663          	beq	s3,a0,ffffffffc02011c4 <default_check+0x352>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200efc:	000a2783          	lw	a5,0(s4)
ffffffffc0200f00:	2e079263          	bnez	a5,ffffffffc02011e4 <default_check+0x372>
ffffffffc0200f04:	0009a783          	lw	a5,0(s3)
ffffffffc0200f08:	2c079e63          	bnez	a5,ffffffffc02011e4 <default_check+0x372>
ffffffffc0200f0c:	411c                	lw	a5,0(a0)
ffffffffc0200f0e:	2c079b63          	bnez	a5,ffffffffc02011e4 <default_check+0x372>
extern size_t npage;
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page) {
    return page - pages + nbase;
ffffffffc0200f12:	000b6797          	auipc	a5,0xb6
ffffffffc0200f16:	cf678793          	addi	a5,a5,-778 # ffffffffc02b6c08 <pages>
ffffffffc0200f1a:	639c                	ld	a5,0(a5)
ffffffffc0200f1c:	00008717          	auipc	a4,0x8
ffffffffc0200f20:	f9470713          	addi	a4,a4,-108 # ffffffffc0208eb0 <nbase>
ffffffffc0200f24:	6310                	ld	a2,0(a4)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f26:	000b6717          	auipc	a4,0xb6
ffffffffc0200f2a:	c7270713          	addi	a4,a4,-910 # ffffffffc02b6b98 <npage>
ffffffffc0200f2e:	6314                	ld	a3,0(a4)
ffffffffc0200f30:	40fa0733          	sub	a4,s4,a5
ffffffffc0200f34:	8719                	srai	a4,a4,0x6
ffffffffc0200f36:	9732                	add	a4,a4,a2
ffffffffc0200f38:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f3a:	0732                	slli	a4,a4,0xc
ffffffffc0200f3c:	2cd77463          	bleu	a3,a4,ffffffffc0201204 <default_check+0x392>
    return page - pages + nbase;
ffffffffc0200f40:	40f98733          	sub	a4,s3,a5
ffffffffc0200f44:	8719                	srai	a4,a4,0x6
ffffffffc0200f46:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f48:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f4a:	4ed77d63          	bleu	a3,a4,ffffffffc0201444 <default_check+0x5d2>
    return page - pages + nbase;
ffffffffc0200f4e:	40f507b3          	sub	a5,a0,a5
ffffffffc0200f52:	8799                	srai	a5,a5,0x6
ffffffffc0200f54:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f56:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f58:	34d7f663          	bleu	a3,a5,ffffffffc02012a4 <default_check+0x432>
    assert(alloc_page() == NULL);
ffffffffc0200f5c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f5e:	00093c03          	ld	s8,0(s2)
ffffffffc0200f62:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200f66:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0200f6a:	000b6797          	auipc	a5,0xb6
ffffffffc0200f6e:	c727bb23          	sd	s2,-906(a5) # ffffffffc02b6be0 <free_area+0x8>
ffffffffc0200f72:	000b6797          	auipc	a5,0xb6
ffffffffc0200f76:	c727b323          	sd	s2,-922(a5) # ffffffffc02b6bd8 <free_area>
    nr_free = 0;
ffffffffc0200f7a:	000b6797          	auipc	a5,0xb6
ffffffffc0200f7e:	c607a723          	sw	zero,-914(a5) # ffffffffc02b6be8 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200f82:	6d1000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200f86:	2e051f63          	bnez	a0,ffffffffc0201284 <default_check+0x412>
    free_page(p0);
ffffffffc0200f8a:	4585                	li	a1,1
ffffffffc0200f8c:	8552                	mv	a0,s4
ffffffffc0200f8e:	74d000ef          	jal	ra,ffffffffc0201eda <free_pages>
    free_page(p1);
ffffffffc0200f92:	4585                	li	a1,1
ffffffffc0200f94:	854e                	mv	a0,s3
ffffffffc0200f96:	745000ef          	jal	ra,ffffffffc0201eda <free_pages>
    free_page(p2);
ffffffffc0200f9a:	4585                	li	a1,1
ffffffffc0200f9c:	8556                	mv	a0,s5
ffffffffc0200f9e:	73d000ef          	jal	ra,ffffffffc0201eda <free_pages>
    assert(nr_free == 3);
ffffffffc0200fa2:	01092703          	lw	a4,16(s2)
ffffffffc0200fa6:	478d                	li	a5,3
ffffffffc0200fa8:	2af71e63          	bne	a4,a5,ffffffffc0201264 <default_check+0x3f2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fac:	4505                	li	a0,1
ffffffffc0200fae:	6a5000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200fb2:	89aa                	mv	s3,a0
ffffffffc0200fb4:	28050863          	beqz	a0,ffffffffc0201244 <default_check+0x3d2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fb8:	4505                	li	a0,1
ffffffffc0200fba:	699000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200fbe:	8aaa                	mv	s5,a0
ffffffffc0200fc0:	3e050263          	beqz	a0,ffffffffc02013a4 <default_check+0x532>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fc4:	4505                	li	a0,1
ffffffffc0200fc6:	68d000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200fca:	8a2a                	mv	s4,a0
ffffffffc0200fcc:	3a050c63          	beqz	a0,ffffffffc0201384 <default_check+0x512>
    assert(alloc_page() == NULL);
ffffffffc0200fd0:	4505                	li	a0,1
ffffffffc0200fd2:	681000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200fd6:	38051763          	bnez	a0,ffffffffc0201364 <default_check+0x4f2>
    free_page(p0);
ffffffffc0200fda:	4585                	li	a1,1
ffffffffc0200fdc:	854e                	mv	a0,s3
ffffffffc0200fde:	6fd000ef          	jal	ra,ffffffffc0201eda <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200fe2:	00893783          	ld	a5,8(s2)
ffffffffc0200fe6:	23278f63          	beq	a5,s2,ffffffffc0201224 <default_check+0x3b2>
    assert((p = alloc_page()) == p0);
ffffffffc0200fea:	4505                	li	a0,1
ffffffffc0200fec:	667000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200ff0:	32a99a63          	bne	s3,a0,ffffffffc0201324 <default_check+0x4b2>
    assert(alloc_page() == NULL);
ffffffffc0200ff4:	4505                	li	a0,1
ffffffffc0200ff6:	65d000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200ffa:	30051563          	bnez	a0,ffffffffc0201304 <default_check+0x492>
    assert(nr_free == 0);
ffffffffc0200ffe:	01092783          	lw	a5,16(s2)
ffffffffc0201002:	2e079163          	bnez	a5,ffffffffc02012e4 <default_check+0x472>
    free_page(p);
ffffffffc0201006:	854e                	mv	a0,s3
ffffffffc0201008:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020100a:	000b6797          	auipc	a5,0xb6
ffffffffc020100e:	bd87b723          	sd	s8,-1074(a5) # ffffffffc02b6bd8 <free_area>
ffffffffc0201012:	000b6797          	auipc	a5,0xb6
ffffffffc0201016:	bd77b723          	sd	s7,-1074(a5) # ffffffffc02b6be0 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc020101a:	000b6797          	auipc	a5,0xb6
ffffffffc020101e:	bd67a723          	sw	s6,-1074(a5) # ffffffffc02b6be8 <free_area+0x10>
    free_page(p);
ffffffffc0201022:	6b9000ef          	jal	ra,ffffffffc0201eda <free_pages>
    free_page(p1);
ffffffffc0201026:	4585                	li	a1,1
ffffffffc0201028:	8556                	mv	a0,s5
ffffffffc020102a:	6b1000ef          	jal	ra,ffffffffc0201eda <free_pages>
    free_page(p2);
ffffffffc020102e:	4585                	li	a1,1
ffffffffc0201030:	8552                	mv	a0,s4
ffffffffc0201032:	6a9000ef          	jal	ra,ffffffffc0201eda <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201036:	4515                	li	a0,5
ffffffffc0201038:	61b000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020103c:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020103e:	28050363          	beqz	a0,ffffffffc02012c4 <default_check+0x452>
ffffffffc0201042:	651c                	ld	a5,8(a0)
ffffffffc0201044:	8385                	srli	a5,a5,0x1
ffffffffc0201046:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0201048:	54079e63          	bnez	a5,ffffffffc02015a4 <default_check+0x732>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020104c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020104e:	00093b03          	ld	s6,0(s2)
ffffffffc0201052:	00893a83          	ld	s5,8(s2)
ffffffffc0201056:	000b6797          	auipc	a5,0xb6
ffffffffc020105a:	b927b123          	sd	s2,-1150(a5) # ffffffffc02b6bd8 <free_area>
ffffffffc020105e:	000b6797          	auipc	a5,0xb6
ffffffffc0201062:	b927b123          	sd	s2,-1150(a5) # ffffffffc02b6be0 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc0201066:	5ed000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020106a:	50051d63          	bnez	a0,ffffffffc0201584 <default_check+0x712>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc020106e:	08098a13          	addi	s4,s3,128
ffffffffc0201072:	8552                	mv	a0,s4
ffffffffc0201074:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201076:	01092b83          	lw	s7,16(s2)
    nr_free = 0;
ffffffffc020107a:	000b6797          	auipc	a5,0xb6
ffffffffc020107e:	b607a723          	sw	zero,-1170(a5) # ffffffffc02b6be8 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0201082:	659000ef          	jal	ra,ffffffffc0201eda <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201086:	4511                	li	a0,4
ffffffffc0201088:	5cb000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020108c:	4c051c63          	bnez	a0,ffffffffc0201564 <default_check+0x6f2>
ffffffffc0201090:	0889b783          	ld	a5,136(s3)
ffffffffc0201094:	8385                	srli	a5,a5,0x1
ffffffffc0201096:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201098:	4a078663          	beqz	a5,ffffffffc0201544 <default_check+0x6d2>
ffffffffc020109c:	0909a703          	lw	a4,144(s3)
ffffffffc02010a0:	478d                	li	a5,3
ffffffffc02010a2:	4af71163          	bne	a4,a5,ffffffffc0201544 <default_check+0x6d2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02010a6:	450d                	li	a0,3
ffffffffc02010a8:	5ab000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc02010ac:	8c2a                	mv	s8,a0
ffffffffc02010ae:	46050b63          	beqz	a0,ffffffffc0201524 <default_check+0x6b2>
    assert(alloc_page() == NULL);
ffffffffc02010b2:	4505                	li	a0,1
ffffffffc02010b4:	59f000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc02010b8:	44051663          	bnez	a0,ffffffffc0201504 <default_check+0x692>
    assert(p0 + 2 == p1);
ffffffffc02010bc:	438a1463          	bne	s4,s8,ffffffffc02014e4 <default_check+0x672>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02010c0:	4585                	li	a1,1
ffffffffc02010c2:	854e                	mv	a0,s3
ffffffffc02010c4:	617000ef          	jal	ra,ffffffffc0201eda <free_pages>
    free_pages(p1, 3);
ffffffffc02010c8:	458d                	li	a1,3
ffffffffc02010ca:	8552                	mv	a0,s4
ffffffffc02010cc:	60f000ef          	jal	ra,ffffffffc0201eda <free_pages>
ffffffffc02010d0:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02010d4:	04098c13          	addi	s8,s3,64
ffffffffc02010d8:	8385                	srli	a5,a5,0x1
ffffffffc02010da:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02010dc:	3e078463          	beqz	a5,ffffffffc02014c4 <default_check+0x652>
ffffffffc02010e0:	0109a703          	lw	a4,16(s3)
ffffffffc02010e4:	4785                	li	a5,1
ffffffffc02010e6:	3cf71f63          	bne	a4,a5,ffffffffc02014c4 <default_check+0x652>
ffffffffc02010ea:	008a3783          	ld	a5,8(s4)
ffffffffc02010ee:	8385                	srli	a5,a5,0x1
ffffffffc02010f0:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02010f2:	3a078963          	beqz	a5,ffffffffc02014a4 <default_check+0x632>
ffffffffc02010f6:	010a2703          	lw	a4,16(s4)
ffffffffc02010fa:	478d                	li	a5,3
ffffffffc02010fc:	3af71463          	bne	a4,a5,ffffffffc02014a4 <default_check+0x632>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201100:	4505                	li	a0,1
ffffffffc0201102:	551000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0201106:	36a99f63          	bne	s3,a0,ffffffffc0201484 <default_check+0x612>
    free_page(p0);
ffffffffc020110a:	4585                	li	a1,1
ffffffffc020110c:	5cf000ef          	jal	ra,ffffffffc0201eda <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201110:	4509                	li	a0,2
ffffffffc0201112:	541000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0201116:	34aa1763          	bne	s4,a0,ffffffffc0201464 <default_check+0x5f2>

    free_pages(p0, 2);
ffffffffc020111a:	4589                	li	a1,2
ffffffffc020111c:	5bf000ef          	jal	ra,ffffffffc0201eda <free_pages>
    free_page(p2);
ffffffffc0201120:	4585                	li	a1,1
ffffffffc0201122:	8562                	mv	a0,s8
ffffffffc0201124:	5b7000ef          	jal	ra,ffffffffc0201eda <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201128:	4515                	li	a0,5
ffffffffc020112a:	529000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020112e:	89aa                	mv	s3,a0
ffffffffc0201130:	48050a63          	beqz	a0,ffffffffc02015c4 <default_check+0x752>
    assert(alloc_page() == NULL);
ffffffffc0201134:	4505                	li	a0,1
ffffffffc0201136:	51d000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020113a:	2e051563          	bnez	a0,ffffffffc0201424 <default_check+0x5b2>

    assert(nr_free == 0);
ffffffffc020113e:	01092783          	lw	a5,16(s2)
ffffffffc0201142:	2c079163          	bnez	a5,ffffffffc0201404 <default_check+0x592>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201146:	4595                	li	a1,5
ffffffffc0201148:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020114a:	000b6797          	auipc	a5,0xb6
ffffffffc020114e:	a977af23          	sw	s7,-1378(a5) # ffffffffc02b6be8 <free_area+0x10>
    free_list = free_list_store;
ffffffffc0201152:	000b6797          	auipc	a5,0xb6
ffffffffc0201156:	a967b323          	sd	s6,-1402(a5) # ffffffffc02b6bd8 <free_area>
ffffffffc020115a:	000b6797          	auipc	a5,0xb6
ffffffffc020115e:	a957b323          	sd	s5,-1402(a5) # ffffffffc02b6be0 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc0201162:	579000ef          	jal	ra,ffffffffc0201eda <free_pages>
    return listelm->next;
ffffffffc0201166:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020116a:	01278963          	beq	a5,s2,ffffffffc020117c <default_check+0x30a>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc020116e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201172:	679c                	ld	a5,8(a5)
ffffffffc0201174:	34fd                	addiw	s1,s1,-1
ffffffffc0201176:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201178:	ff279be3          	bne	a5,s2,ffffffffc020116e <default_check+0x2fc>
    }
    assert(count == 0);
ffffffffc020117c:	26049463          	bnez	s1,ffffffffc02013e4 <default_check+0x572>
    assert(total == 0);
ffffffffc0201180:	46041263          	bnez	s0,ffffffffc02015e4 <default_check+0x772>
}
ffffffffc0201184:	60a6                	ld	ra,72(sp)
ffffffffc0201186:	6406                	ld	s0,64(sp)
ffffffffc0201188:	74e2                	ld	s1,56(sp)
ffffffffc020118a:	7942                	ld	s2,48(sp)
ffffffffc020118c:	79a2                	ld	s3,40(sp)
ffffffffc020118e:	7a02                	ld	s4,32(sp)
ffffffffc0201190:	6ae2                	ld	s5,24(sp)
ffffffffc0201192:	6b42                	ld	s6,16(sp)
ffffffffc0201194:	6ba2                	ld	s7,8(sp)
ffffffffc0201196:	6c02                	ld	s8,0(sp)
ffffffffc0201198:	6161                	addi	sp,sp,80
ffffffffc020119a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020119c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020119e:	4401                	li	s0,0
ffffffffc02011a0:	4481                	li	s1,0
ffffffffc02011a2:	b30d                	j	ffffffffc0200ec4 <default_check+0x52>
        assert(PageProperty(p));
ffffffffc02011a4:	00006697          	auipc	a3,0x6
ffffffffc02011a8:	f6468693          	addi	a3,a3,-156 # ffffffffc0207108 <commands+0x878>
ffffffffc02011ac:	00006617          	auipc	a2,0x6
ffffffffc02011b0:	ba460613          	addi	a2,a2,-1116 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02011b4:	0f000593          	li	a1,240
ffffffffc02011b8:	00006517          	auipc	a0,0x6
ffffffffc02011bc:	f6050513          	addi	a0,a0,-160 # ffffffffc0207118 <commands+0x888>
ffffffffc02011c0:	ac4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02011c4:	00006697          	auipc	a3,0x6
ffffffffc02011c8:	fec68693          	addi	a3,a3,-20 # ffffffffc02071b0 <commands+0x920>
ffffffffc02011cc:	00006617          	auipc	a2,0x6
ffffffffc02011d0:	b8460613          	addi	a2,a2,-1148 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02011d4:	0bd00593          	li	a1,189
ffffffffc02011d8:	00006517          	auipc	a0,0x6
ffffffffc02011dc:	f4050513          	addi	a0,a0,-192 # ffffffffc0207118 <commands+0x888>
ffffffffc02011e0:	aa4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02011e4:	00006697          	auipc	a3,0x6
ffffffffc02011e8:	ff468693          	addi	a3,a3,-12 # ffffffffc02071d8 <commands+0x948>
ffffffffc02011ec:	00006617          	auipc	a2,0x6
ffffffffc02011f0:	b6460613          	addi	a2,a2,-1180 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02011f4:	0be00593          	li	a1,190
ffffffffc02011f8:	00006517          	auipc	a0,0x6
ffffffffc02011fc:	f2050513          	addi	a0,a0,-224 # ffffffffc0207118 <commands+0x888>
ffffffffc0201200:	a84ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201204:	00006697          	auipc	a3,0x6
ffffffffc0201208:	01468693          	addi	a3,a3,20 # ffffffffc0207218 <commands+0x988>
ffffffffc020120c:	00006617          	auipc	a2,0x6
ffffffffc0201210:	b4460613          	addi	a2,a2,-1212 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201214:	0c000593          	li	a1,192
ffffffffc0201218:	00006517          	auipc	a0,0x6
ffffffffc020121c:	f0050513          	addi	a0,a0,-256 # ffffffffc0207118 <commands+0x888>
ffffffffc0201220:	a64ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201224:	00006697          	auipc	a3,0x6
ffffffffc0201228:	07c68693          	addi	a3,a3,124 # ffffffffc02072a0 <commands+0xa10>
ffffffffc020122c:	00006617          	auipc	a2,0x6
ffffffffc0201230:	b2460613          	addi	a2,a2,-1244 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201234:	0d900593          	li	a1,217
ffffffffc0201238:	00006517          	auipc	a0,0x6
ffffffffc020123c:	ee050513          	addi	a0,a0,-288 # ffffffffc0207118 <commands+0x888>
ffffffffc0201240:	a44ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201244:	00006697          	auipc	a3,0x6
ffffffffc0201248:	f0c68693          	addi	a3,a3,-244 # ffffffffc0207150 <commands+0x8c0>
ffffffffc020124c:	00006617          	auipc	a2,0x6
ffffffffc0201250:	b0460613          	addi	a2,a2,-1276 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201254:	0d200593          	li	a1,210
ffffffffc0201258:	00006517          	auipc	a0,0x6
ffffffffc020125c:	ec050513          	addi	a0,a0,-320 # ffffffffc0207118 <commands+0x888>
ffffffffc0201260:	a24ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free == 3);
ffffffffc0201264:	00006697          	auipc	a3,0x6
ffffffffc0201268:	02c68693          	addi	a3,a3,44 # ffffffffc0207290 <commands+0xa00>
ffffffffc020126c:	00006617          	auipc	a2,0x6
ffffffffc0201270:	ae460613          	addi	a2,a2,-1308 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201274:	0d000593          	li	a1,208
ffffffffc0201278:	00006517          	auipc	a0,0x6
ffffffffc020127c:	ea050513          	addi	a0,a0,-352 # ffffffffc0207118 <commands+0x888>
ffffffffc0201280:	a04ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201284:	00006697          	auipc	a3,0x6
ffffffffc0201288:	ff468693          	addi	a3,a3,-12 # ffffffffc0207278 <commands+0x9e8>
ffffffffc020128c:	00006617          	auipc	a2,0x6
ffffffffc0201290:	ac460613          	addi	a2,a2,-1340 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201294:	0cb00593          	li	a1,203
ffffffffc0201298:	00006517          	auipc	a0,0x6
ffffffffc020129c:	e8050513          	addi	a0,a0,-384 # ffffffffc0207118 <commands+0x888>
ffffffffc02012a0:	9e4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02012a4:	00006697          	auipc	a3,0x6
ffffffffc02012a8:	fb468693          	addi	a3,a3,-76 # ffffffffc0207258 <commands+0x9c8>
ffffffffc02012ac:	00006617          	auipc	a2,0x6
ffffffffc02012b0:	aa460613          	addi	a2,a2,-1372 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02012b4:	0c200593          	li	a1,194
ffffffffc02012b8:	00006517          	auipc	a0,0x6
ffffffffc02012bc:	e6050513          	addi	a0,a0,-416 # ffffffffc0207118 <commands+0x888>
ffffffffc02012c0:	9c4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(p0 != NULL);
ffffffffc02012c4:	00006697          	auipc	a3,0x6
ffffffffc02012c8:	02468693          	addi	a3,a3,36 # ffffffffc02072e8 <commands+0xa58>
ffffffffc02012cc:	00006617          	auipc	a2,0x6
ffffffffc02012d0:	a8460613          	addi	a2,a2,-1404 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02012d4:	0f800593          	li	a1,248
ffffffffc02012d8:	00006517          	auipc	a0,0x6
ffffffffc02012dc:	e4050513          	addi	a0,a0,-448 # ffffffffc0207118 <commands+0x888>
ffffffffc02012e0:	9a4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free == 0);
ffffffffc02012e4:	00006697          	auipc	a3,0x6
ffffffffc02012e8:	ff468693          	addi	a3,a3,-12 # ffffffffc02072d8 <commands+0xa48>
ffffffffc02012ec:	00006617          	auipc	a2,0x6
ffffffffc02012f0:	a6460613          	addi	a2,a2,-1436 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02012f4:	0df00593          	li	a1,223
ffffffffc02012f8:	00006517          	auipc	a0,0x6
ffffffffc02012fc:	e2050513          	addi	a0,a0,-480 # ffffffffc0207118 <commands+0x888>
ffffffffc0201300:	984ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201304:	00006697          	auipc	a3,0x6
ffffffffc0201308:	f7468693          	addi	a3,a3,-140 # ffffffffc0207278 <commands+0x9e8>
ffffffffc020130c:	00006617          	auipc	a2,0x6
ffffffffc0201310:	a4460613          	addi	a2,a2,-1468 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201314:	0dd00593          	li	a1,221
ffffffffc0201318:	00006517          	auipc	a0,0x6
ffffffffc020131c:	e0050513          	addi	a0,a0,-512 # ffffffffc0207118 <commands+0x888>
ffffffffc0201320:	964ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201324:	00006697          	auipc	a3,0x6
ffffffffc0201328:	f9468693          	addi	a3,a3,-108 # ffffffffc02072b8 <commands+0xa28>
ffffffffc020132c:	00006617          	auipc	a2,0x6
ffffffffc0201330:	a2460613          	addi	a2,a2,-1500 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201334:	0dc00593          	li	a1,220
ffffffffc0201338:	00006517          	auipc	a0,0x6
ffffffffc020133c:	de050513          	addi	a0,a0,-544 # ffffffffc0207118 <commands+0x888>
ffffffffc0201340:	944ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201344:	00006697          	auipc	a3,0x6
ffffffffc0201348:	e0c68693          	addi	a3,a3,-500 # ffffffffc0207150 <commands+0x8c0>
ffffffffc020134c:	00006617          	auipc	a2,0x6
ffffffffc0201350:	a0460613          	addi	a2,a2,-1532 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201354:	0b900593          	li	a1,185
ffffffffc0201358:	00006517          	auipc	a0,0x6
ffffffffc020135c:	dc050513          	addi	a0,a0,-576 # ffffffffc0207118 <commands+0x888>
ffffffffc0201360:	924ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201364:	00006697          	auipc	a3,0x6
ffffffffc0201368:	f1468693          	addi	a3,a3,-236 # ffffffffc0207278 <commands+0x9e8>
ffffffffc020136c:	00006617          	auipc	a2,0x6
ffffffffc0201370:	9e460613          	addi	a2,a2,-1564 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201374:	0d600593          	li	a1,214
ffffffffc0201378:	00006517          	auipc	a0,0x6
ffffffffc020137c:	da050513          	addi	a0,a0,-608 # ffffffffc0207118 <commands+0x888>
ffffffffc0201380:	904ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201384:	00006697          	auipc	a3,0x6
ffffffffc0201388:	e0c68693          	addi	a3,a3,-500 # ffffffffc0207190 <commands+0x900>
ffffffffc020138c:	00006617          	auipc	a2,0x6
ffffffffc0201390:	9c460613          	addi	a2,a2,-1596 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201394:	0d400593          	li	a1,212
ffffffffc0201398:	00006517          	auipc	a0,0x6
ffffffffc020139c:	d8050513          	addi	a0,a0,-640 # ffffffffc0207118 <commands+0x888>
ffffffffc02013a0:	8e4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013a4:	00006697          	auipc	a3,0x6
ffffffffc02013a8:	dcc68693          	addi	a3,a3,-564 # ffffffffc0207170 <commands+0x8e0>
ffffffffc02013ac:	00006617          	auipc	a2,0x6
ffffffffc02013b0:	9a460613          	addi	a2,a2,-1628 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02013b4:	0d300593          	li	a1,211
ffffffffc02013b8:	00006517          	auipc	a0,0x6
ffffffffc02013bc:	d6050513          	addi	a0,a0,-672 # ffffffffc0207118 <commands+0x888>
ffffffffc02013c0:	8c4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013c4:	00006697          	auipc	a3,0x6
ffffffffc02013c8:	dcc68693          	addi	a3,a3,-564 # ffffffffc0207190 <commands+0x900>
ffffffffc02013cc:	00006617          	auipc	a2,0x6
ffffffffc02013d0:	98460613          	addi	a2,a2,-1660 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02013d4:	0bb00593          	li	a1,187
ffffffffc02013d8:	00006517          	auipc	a0,0x6
ffffffffc02013dc:	d4050513          	addi	a0,a0,-704 # ffffffffc0207118 <commands+0x888>
ffffffffc02013e0:	8a4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(count == 0);
ffffffffc02013e4:	00006697          	auipc	a3,0x6
ffffffffc02013e8:	05468693          	addi	a3,a3,84 # ffffffffc0207438 <commands+0xba8>
ffffffffc02013ec:	00006617          	auipc	a2,0x6
ffffffffc02013f0:	96460613          	addi	a2,a2,-1692 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02013f4:	12500593          	li	a1,293
ffffffffc02013f8:	00006517          	auipc	a0,0x6
ffffffffc02013fc:	d2050513          	addi	a0,a0,-736 # ffffffffc0207118 <commands+0x888>
ffffffffc0201400:	884ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free == 0);
ffffffffc0201404:	00006697          	auipc	a3,0x6
ffffffffc0201408:	ed468693          	addi	a3,a3,-300 # ffffffffc02072d8 <commands+0xa48>
ffffffffc020140c:	00006617          	auipc	a2,0x6
ffffffffc0201410:	94460613          	addi	a2,a2,-1724 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201414:	11a00593          	li	a1,282
ffffffffc0201418:	00006517          	auipc	a0,0x6
ffffffffc020141c:	d0050513          	addi	a0,a0,-768 # ffffffffc0207118 <commands+0x888>
ffffffffc0201420:	864ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201424:	00006697          	auipc	a3,0x6
ffffffffc0201428:	e5468693          	addi	a3,a3,-428 # ffffffffc0207278 <commands+0x9e8>
ffffffffc020142c:	00006617          	auipc	a2,0x6
ffffffffc0201430:	92460613          	addi	a2,a2,-1756 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201434:	11800593          	li	a1,280
ffffffffc0201438:	00006517          	auipc	a0,0x6
ffffffffc020143c:	ce050513          	addi	a0,a0,-800 # ffffffffc0207118 <commands+0x888>
ffffffffc0201440:	844ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201444:	00006697          	auipc	a3,0x6
ffffffffc0201448:	df468693          	addi	a3,a3,-524 # ffffffffc0207238 <commands+0x9a8>
ffffffffc020144c:	00006617          	auipc	a2,0x6
ffffffffc0201450:	90460613          	addi	a2,a2,-1788 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201454:	0c100593          	li	a1,193
ffffffffc0201458:	00006517          	auipc	a0,0x6
ffffffffc020145c:	cc050513          	addi	a0,a0,-832 # ffffffffc0207118 <commands+0x888>
ffffffffc0201460:	824ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201464:	00006697          	auipc	a3,0x6
ffffffffc0201468:	f9468693          	addi	a3,a3,-108 # ffffffffc02073f8 <commands+0xb68>
ffffffffc020146c:	00006617          	auipc	a2,0x6
ffffffffc0201470:	8e460613          	addi	a2,a2,-1820 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201474:	11200593          	li	a1,274
ffffffffc0201478:	00006517          	auipc	a0,0x6
ffffffffc020147c:	ca050513          	addi	a0,a0,-864 # ffffffffc0207118 <commands+0x888>
ffffffffc0201480:	804ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201484:	00006697          	auipc	a3,0x6
ffffffffc0201488:	f5468693          	addi	a3,a3,-172 # ffffffffc02073d8 <commands+0xb48>
ffffffffc020148c:	00006617          	auipc	a2,0x6
ffffffffc0201490:	8c460613          	addi	a2,a2,-1852 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201494:	11000593          	li	a1,272
ffffffffc0201498:	00006517          	auipc	a0,0x6
ffffffffc020149c:	c8050513          	addi	a0,a0,-896 # ffffffffc0207118 <commands+0x888>
ffffffffc02014a0:	fe5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02014a4:	00006697          	auipc	a3,0x6
ffffffffc02014a8:	f0c68693          	addi	a3,a3,-244 # ffffffffc02073b0 <commands+0xb20>
ffffffffc02014ac:	00006617          	auipc	a2,0x6
ffffffffc02014b0:	8a460613          	addi	a2,a2,-1884 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02014b4:	10e00593          	li	a1,270
ffffffffc02014b8:	00006517          	auipc	a0,0x6
ffffffffc02014bc:	c6050513          	addi	a0,a0,-928 # ffffffffc0207118 <commands+0x888>
ffffffffc02014c0:	fc5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02014c4:	00006697          	auipc	a3,0x6
ffffffffc02014c8:	ec468693          	addi	a3,a3,-316 # ffffffffc0207388 <commands+0xaf8>
ffffffffc02014cc:	00006617          	auipc	a2,0x6
ffffffffc02014d0:	88460613          	addi	a2,a2,-1916 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02014d4:	10d00593          	li	a1,269
ffffffffc02014d8:	00006517          	auipc	a0,0x6
ffffffffc02014dc:	c4050513          	addi	a0,a0,-960 # ffffffffc0207118 <commands+0x888>
ffffffffc02014e0:	fa5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02014e4:	00006697          	auipc	a3,0x6
ffffffffc02014e8:	e9468693          	addi	a3,a3,-364 # ffffffffc0207378 <commands+0xae8>
ffffffffc02014ec:	00006617          	auipc	a2,0x6
ffffffffc02014f0:	86460613          	addi	a2,a2,-1948 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02014f4:	10800593          	li	a1,264
ffffffffc02014f8:	00006517          	auipc	a0,0x6
ffffffffc02014fc:	c2050513          	addi	a0,a0,-992 # ffffffffc0207118 <commands+0x888>
ffffffffc0201500:	f85fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201504:	00006697          	auipc	a3,0x6
ffffffffc0201508:	d7468693          	addi	a3,a3,-652 # ffffffffc0207278 <commands+0x9e8>
ffffffffc020150c:	00006617          	auipc	a2,0x6
ffffffffc0201510:	84460613          	addi	a2,a2,-1980 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201514:	10700593          	li	a1,263
ffffffffc0201518:	00006517          	auipc	a0,0x6
ffffffffc020151c:	c0050513          	addi	a0,a0,-1024 # ffffffffc0207118 <commands+0x888>
ffffffffc0201520:	f65fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201524:	00006697          	auipc	a3,0x6
ffffffffc0201528:	e3468693          	addi	a3,a3,-460 # ffffffffc0207358 <commands+0xac8>
ffffffffc020152c:	00006617          	auipc	a2,0x6
ffffffffc0201530:	82460613          	addi	a2,a2,-2012 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201534:	10600593          	li	a1,262
ffffffffc0201538:	00006517          	auipc	a0,0x6
ffffffffc020153c:	be050513          	addi	a0,a0,-1056 # ffffffffc0207118 <commands+0x888>
ffffffffc0201540:	f45fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201544:	00006697          	auipc	a3,0x6
ffffffffc0201548:	de468693          	addi	a3,a3,-540 # ffffffffc0207328 <commands+0xa98>
ffffffffc020154c:	00006617          	auipc	a2,0x6
ffffffffc0201550:	80460613          	addi	a2,a2,-2044 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201554:	10500593          	li	a1,261
ffffffffc0201558:	00006517          	auipc	a0,0x6
ffffffffc020155c:	bc050513          	addi	a0,a0,-1088 # ffffffffc0207118 <commands+0x888>
ffffffffc0201560:	f25fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201564:	00006697          	auipc	a3,0x6
ffffffffc0201568:	dac68693          	addi	a3,a3,-596 # ffffffffc0207310 <commands+0xa80>
ffffffffc020156c:	00005617          	auipc	a2,0x5
ffffffffc0201570:	7e460613          	addi	a2,a2,2020 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201574:	10400593          	li	a1,260
ffffffffc0201578:	00006517          	auipc	a0,0x6
ffffffffc020157c:	ba050513          	addi	a0,a0,-1120 # ffffffffc0207118 <commands+0x888>
ffffffffc0201580:	f05fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201584:	00006697          	auipc	a3,0x6
ffffffffc0201588:	cf468693          	addi	a3,a3,-780 # ffffffffc0207278 <commands+0x9e8>
ffffffffc020158c:	00005617          	auipc	a2,0x5
ffffffffc0201590:	7c460613          	addi	a2,a2,1988 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201594:	0fe00593          	li	a1,254
ffffffffc0201598:	00006517          	auipc	a0,0x6
ffffffffc020159c:	b8050513          	addi	a0,a0,-1152 # ffffffffc0207118 <commands+0x888>
ffffffffc02015a0:	ee5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(!PageProperty(p0));
ffffffffc02015a4:	00006697          	auipc	a3,0x6
ffffffffc02015a8:	d5468693          	addi	a3,a3,-684 # ffffffffc02072f8 <commands+0xa68>
ffffffffc02015ac:	00005617          	auipc	a2,0x5
ffffffffc02015b0:	7a460613          	addi	a2,a2,1956 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02015b4:	0f900593          	li	a1,249
ffffffffc02015b8:	00006517          	auipc	a0,0x6
ffffffffc02015bc:	b6050513          	addi	a0,a0,-1184 # ffffffffc0207118 <commands+0x888>
ffffffffc02015c0:	ec5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02015c4:	00006697          	auipc	a3,0x6
ffffffffc02015c8:	e5468693          	addi	a3,a3,-428 # ffffffffc0207418 <commands+0xb88>
ffffffffc02015cc:	00005617          	auipc	a2,0x5
ffffffffc02015d0:	78460613          	addi	a2,a2,1924 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02015d4:	11700593          	li	a1,279
ffffffffc02015d8:	00006517          	auipc	a0,0x6
ffffffffc02015dc:	b4050513          	addi	a0,a0,-1216 # ffffffffc0207118 <commands+0x888>
ffffffffc02015e0:	ea5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(total == 0);
ffffffffc02015e4:	00006697          	auipc	a3,0x6
ffffffffc02015e8:	e6468693          	addi	a3,a3,-412 # ffffffffc0207448 <commands+0xbb8>
ffffffffc02015ec:	00005617          	auipc	a2,0x5
ffffffffc02015f0:	76460613          	addi	a2,a2,1892 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02015f4:	12600593          	li	a1,294
ffffffffc02015f8:	00006517          	auipc	a0,0x6
ffffffffc02015fc:	b2050513          	addi	a0,a0,-1248 # ffffffffc0207118 <commands+0x888>
ffffffffc0201600:	e85fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201604:	00006697          	auipc	a3,0x6
ffffffffc0201608:	b2c68693          	addi	a3,a3,-1236 # ffffffffc0207130 <commands+0x8a0>
ffffffffc020160c:	00005617          	auipc	a2,0x5
ffffffffc0201610:	74460613          	addi	a2,a2,1860 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201614:	0f300593          	li	a1,243
ffffffffc0201618:	00006517          	auipc	a0,0x6
ffffffffc020161c:	b0050513          	addi	a0,a0,-1280 # ffffffffc0207118 <commands+0x888>
ffffffffc0201620:	e65fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201624:	00006697          	auipc	a3,0x6
ffffffffc0201628:	b4c68693          	addi	a3,a3,-1204 # ffffffffc0207170 <commands+0x8e0>
ffffffffc020162c:	00005617          	auipc	a2,0x5
ffffffffc0201630:	72460613          	addi	a2,a2,1828 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201634:	0ba00593          	li	a1,186
ffffffffc0201638:	00006517          	auipc	a0,0x6
ffffffffc020163c:	ae050513          	addi	a0,a0,-1312 # ffffffffc0207118 <commands+0x888>
ffffffffc0201640:	e45fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201644 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201644:	1141                	addi	sp,sp,-16
ffffffffc0201646:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201648:	16058e63          	beqz	a1,ffffffffc02017c4 <default_free_pages+0x180>
    for (; p != base + n; p ++) {
ffffffffc020164c:	00659693          	slli	a3,a1,0x6
ffffffffc0201650:	96aa                	add	a3,a3,a0
ffffffffc0201652:	02d50d63          	beq	a0,a3,ffffffffc020168c <default_free_pages+0x48>
ffffffffc0201656:	651c                	ld	a5,8(a0)
ffffffffc0201658:	8b85                	andi	a5,a5,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020165a:	14079563          	bnez	a5,ffffffffc02017a4 <default_free_pages+0x160>
ffffffffc020165e:	651c                	ld	a5,8(a0)
ffffffffc0201660:	8385                	srli	a5,a5,0x1
ffffffffc0201662:	8b85                	andi	a5,a5,1
ffffffffc0201664:	14079063          	bnez	a5,ffffffffc02017a4 <default_free_pages+0x160>
ffffffffc0201668:	87aa                	mv	a5,a0
ffffffffc020166a:	a809                	j	ffffffffc020167c <default_free_pages+0x38>
ffffffffc020166c:	6798                	ld	a4,8(a5)
ffffffffc020166e:	8b05                	andi	a4,a4,1
ffffffffc0201670:	12071a63          	bnez	a4,ffffffffc02017a4 <default_free_pages+0x160>
ffffffffc0201674:	6798                	ld	a4,8(a5)
ffffffffc0201676:	8b09                	andi	a4,a4,2
ffffffffc0201678:	12071663          	bnez	a4,ffffffffc02017a4 <default_free_pages+0x160>
        p->flags = 0;
ffffffffc020167c:	0007b423          	sd	zero,8(a5)
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) {
    page->ref = val;
ffffffffc0201680:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201684:	04078793          	addi	a5,a5,64
ffffffffc0201688:	fed792e3          	bne	a5,a3,ffffffffc020166c <default_free_pages+0x28>
    base->property = n;
ffffffffc020168c:	2581                	sext.w	a1,a1
ffffffffc020168e:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201690:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201694:	4789                	li	a5,2
ffffffffc0201696:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020169a:	000b5697          	auipc	a3,0xb5
ffffffffc020169e:	53e68693          	addi	a3,a3,1342 # ffffffffc02b6bd8 <free_area>
ffffffffc02016a2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02016a4:	669c                	ld	a5,8(a3)
ffffffffc02016a6:	9db9                	addw	a1,a1,a4
ffffffffc02016a8:	000b5717          	auipc	a4,0xb5
ffffffffc02016ac:	54b72023          	sw	a1,1344(a4) # ffffffffc02b6be8 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc02016b0:	0cd78163          	beq	a5,a3,ffffffffc0201772 <default_free_pages+0x12e>
            struct Page* page = le2page(le, page_link);
ffffffffc02016b4:	fe878713          	addi	a4,a5,-24
ffffffffc02016b8:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02016ba:	4801                	li	a6,0
ffffffffc02016bc:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc02016c0:	00e56a63          	bltu	a0,a4,ffffffffc02016d4 <default_free_pages+0x90>
    return listelm->next;
ffffffffc02016c4:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02016c6:	04d70f63          	beq	a4,a3,ffffffffc0201724 <default_free_pages+0xe0>
        while ((le = list_next(le)) != &free_list) {
ffffffffc02016ca:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02016cc:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02016d0:	fee57ae3          	bleu	a4,a0,ffffffffc02016c4 <default_free_pages+0x80>
ffffffffc02016d4:	00080663          	beqz	a6,ffffffffc02016e0 <default_free_pages+0x9c>
ffffffffc02016d8:	000b5817          	auipc	a6,0xb5
ffffffffc02016dc:	50b83023          	sd	a1,1280(a6) # ffffffffc02b6bd8 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016e0:	638c                	ld	a1,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02016e2:	e390                	sd	a2,0(a5)
ffffffffc02016e4:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc02016e6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016e8:	ed0c                	sd	a1,24(a0)
    if (le != &free_list) {
ffffffffc02016ea:	06d58a63          	beq	a1,a3,ffffffffc020175e <default_free_pages+0x11a>
        if (p + p->property == base) {
ffffffffc02016ee:	ff85a603          	lw	a2,-8(a1)
        p = le2page(le, page_link);
ffffffffc02016f2:	fe858713          	addi	a4,a1,-24
        if (p + p->property == base) {
ffffffffc02016f6:	02061793          	slli	a5,a2,0x20
ffffffffc02016fa:	83e9                	srli	a5,a5,0x1a
ffffffffc02016fc:	97ba                	add	a5,a5,a4
ffffffffc02016fe:	04f51b63          	bne	a0,a5,ffffffffc0201754 <default_free_pages+0x110>
            p->property += base->property;
ffffffffc0201702:	491c                	lw	a5,16(a0)
ffffffffc0201704:	9e3d                	addw	a2,a2,a5
ffffffffc0201706:	fec5ac23          	sw	a2,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020170a:	57f5                	li	a5,-3
ffffffffc020170c:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201710:	01853803          	ld	a6,24(a0)
ffffffffc0201714:	7110                	ld	a2,32(a0)
            base = p;
ffffffffc0201716:	853a                	mv	a0,a4
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201718:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc020171c:	659c                	ld	a5,8(a1)
ffffffffc020171e:	01063023          	sd	a6,0(a2)
ffffffffc0201722:	a815                	j	ffffffffc0201756 <default_free_pages+0x112>
    prev->next = next->prev = elm;
ffffffffc0201724:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201726:	f114                	sd	a3,32(a0)
ffffffffc0201728:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020172a:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020172c:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020172e:	00d70563          	beq	a4,a3,ffffffffc0201738 <default_free_pages+0xf4>
ffffffffc0201732:	4805                	li	a6,1
ffffffffc0201734:	87ba                	mv	a5,a4
ffffffffc0201736:	bf59                	j	ffffffffc02016cc <default_free_pages+0x88>
ffffffffc0201738:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc020173a:	85be                	mv	a1,a5
    if (le != &free_list) {
ffffffffc020173c:	00d78d63          	beq	a5,a3,ffffffffc0201756 <default_free_pages+0x112>
        if (p + p->property == base) {
ffffffffc0201740:	ff85a603          	lw	a2,-8(a1)
        p = le2page(le, page_link);
ffffffffc0201744:	fe858713          	addi	a4,a1,-24
        if (p + p->property == base) {
ffffffffc0201748:	02061793          	slli	a5,a2,0x20
ffffffffc020174c:	83e9                	srli	a5,a5,0x1a
ffffffffc020174e:	97ba                	add	a5,a5,a4
ffffffffc0201750:	faf509e3          	beq	a0,a5,ffffffffc0201702 <default_free_pages+0xbe>
ffffffffc0201754:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc0201756:	fe878713          	addi	a4,a5,-24
ffffffffc020175a:	00d78963          	beq	a5,a3,ffffffffc020176c <default_free_pages+0x128>
        if (base + base->property == p) {
ffffffffc020175e:	4910                	lw	a2,16(a0)
ffffffffc0201760:	02061693          	slli	a3,a2,0x20
ffffffffc0201764:	82e9                	srli	a3,a3,0x1a
ffffffffc0201766:	96aa                	add	a3,a3,a0
ffffffffc0201768:	00d70e63          	beq	a4,a3,ffffffffc0201784 <default_free_pages+0x140>
}
ffffffffc020176c:	60a2                	ld	ra,8(sp)
ffffffffc020176e:	0141                	addi	sp,sp,16
ffffffffc0201770:	8082                	ret
ffffffffc0201772:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201774:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201778:	e398                	sd	a4,0(a5)
ffffffffc020177a:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020177c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020177e:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201780:	0141                	addi	sp,sp,16
ffffffffc0201782:	8082                	ret
            base->property += p->property;
ffffffffc0201784:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201788:	ff078693          	addi	a3,a5,-16
ffffffffc020178c:	9e39                	addw	a2,a2,a4
ffffffffc020178e:	c910                	sw	a2,16(a0)
ffffffffc0201790:	5775                	li	a4,-3
ffffffffc0201792:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201796:	6398                	ld	a4,0(a5)
ffffffffc0201798:	679c                	ld	a5,8(a5)
}
ffffffffc020179a:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020179c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020179e:	e398                	sd	a4,0(a5)
ffffffffc02017a0:	0141                	addi	sp,sp,16
ffffffffc02017a2:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02017a4:	00006697          	auipc	a3,0x6
ffffffffc02017a8:	cb468693          	addi	a3,a3,-844 # ffffffffc0207458 <commands+0xbc8>
ffffffffc02017ac:	00005617          	auipc	a2,0x5
ffffffffc02017b0:	5a460613          	addi	a2,a2,1444 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02017b4:	08300593          	li	a1,131
ffffffffc02017b8:	00006517          	auipc	a0,0x6
ffffffffc02017bc:	96050513          	addi	a0,a0,-1696 # ffffffffc0207118 <commands+0x888>
ffffffffc02017c0:	cc5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(n > 0);
ffffffffc02017c4:	00006697          	auipc	a3,0x6
ffffffffc02017c8:	cbc68693          	addi	a3,a3,-836 # ffffffffc0207480 <commands+0xbf0>
ffffffffc02017cc:	00005617          	auipc	a2,0x5
ffffffffc02017d0:	58460613          	addi	a2,a2,1412 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02017d4:	08000593          	li	a1,128
ffffffffc02017d8:	00006517          	auipc	a0,0x6
ffffffffc02017dc:	94050513          	addi	a0,a0,-1728 # ffffffffc0207118 <commands+0x888>
ffffffffc02017e0:	ca5fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02017e4 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02017e4:	c959                	beqz	a0,ffffffffc020187a <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc02017e6:	000b5597          	auipc	a1,0xb5
ffffffffc02017ea:	3f258593          	addi	a1,a1,1010 # ffffffffc02b6bd8 <free_area>
ffffffffc02017ee:	0105a803          	lw	a6,16(a1)
ffffffffc02017f2:	862a                	mv	a2,a0
ffffffffc02017f4:	02081793          	slli	a5,a6,0x20
ffffffffc02017f8:	9381                	srli	a5,a5,0x20
ffffffffc02017fa:	00a7ee63          	bltu	a5,a0,ffffffffc0201816 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02017fe:	87ae                	mv	a5,a1
ffffffffc0201800:	a801                	j	ffffffffc0201810 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0201802:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201806:	02071693          	slli	a3,a4,0x20
ffffffffc020180a:	9281                	srli	a3,a3,0x20
ffffffffc020180c:	00c6f763          	bleu	a2,a3,ffffffffc020181a <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201810:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201812:	feb798e3          	bne	a5,a1,ffffffffc0201802 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201816:	4501                	li	a0,0
}
ffffffffc0201818:	8082                	ret
        struct Page *p = le2page(le, page_link);
ffffffffc020181a:	fe878513          	addi	a0,a5,-24
    if (page != NULL) {
ffffffffc020181e:	dd6d                	beqz	a0,ffffffffc0201818 <default_alloc_pages+0x34>
    return listelm->prev;
ffffffffc0201820:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201824:	0087b303          	ld	t1,8(a5)
    prev->next = next;
ffffffffc0201828:	00060e1b          	sext.w	t3,a2
ffffffffc020182c:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201830:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0201834:	02d67863          	bleu	a3,a2,ffffffffc0201864 <default_alloc_pages+0x80>
            struct Page *p = page + n;
ffffffffc0201838:	061a                	slli	a2,a2,0x6
ffffffffc020183a:	962a                	add	a2,a2,a0
            p->property = page->property - n;
ffffffffc020183c:	41c7073b          	subw	a4,a4,t3
ffffffffc0201840:	ca18                	sw	a4,16(a2)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201842:	00860693          	addi	a3,a2,8
ffffffffc0201846:	4709                	li	a4,2
ffffffffc0201848:	40e6b02f          	amoor.d	zero,a4,(a3)
    __list_add(elm, listelm, listelm->next);
ffffffffc020184c:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201850:	01860693          	addi	a3,a2,24
    prev->next = next->prev = elm;
ffffffffc0201854:	0105a803          	lw	a6,16(a1)
ffffffffc0201858:	e314                	sd	a3,0(a4)
ffffffffc020185a:	00d8b423          	sd	a3,8(a7)
    elm->next = next;
ffffffffc020185e:	f218                	sd	a4,32(a2)
    elm->prev = prev;
ffffffffc0201860:	01163c23          	sd	a7,24(a2)
        nr_free -= n;
ffffffffc0201864:	41c8083b          	subw	a6,a6,t3
ffffffffc0201868:	000b5717          	auipc	a4,0xb5
ffffffffc020186c:	39072023          	sw	a6,896(a4) # ffffffffc02b6be8 <free_area+0x10>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201870:	5775                	li	a4,-3
ffffffffc0201872:	17c1                	addi	a5,a5,-16
ffffffffc0201874:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc0201878:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc020187a:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020187c:	00006697          	auipc	a3,0x6
ffffffffc0201880:	c0468693          	addi	a3,a3,-1020 # ffffffffc0207480 <commands+0xbf0>
ffffffffc0201884:	00005617          	auipc	a2,0x5
ffffffffc0201888:	4cc60613          	addi	a2,a2,1228 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc020188c:	06200593          	li	a1,98
ffffffffc0201890:	00006517          	auipc	a0,0x6
ffffffffc0201894:	88850513          	addi	a0,a0,-1912 # ffffffffc0207118 <commands+0x888>
default_alloc_pages(size_t n) {
ffffffffc0201898:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020189a:	bebfe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020189e <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc020189e:	1141                	addi	sp,sp,-16
ffffffffc02018a0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02018a2:	c1ed                	beqz	a1,ffffffffc0201984 <default_init_memmap+0xe6>
    for (; p != base + n; p ++) {
ffffffffc02018a4:	00659693          	slli	a3,a1,0x6
ffffffffc02018a8:	96aa                	add	a3,a3,a0
ffffffffc02018aa:	02d50463          	beq	a0,a3,ffffffffc02018d2 <default_init_memmap+0x34>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02018ae:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc02018b0:	87aa                	mv	a5,a0
ffffffffc02018b2:	8b05                	andi	a4,a4,1
ffffffffc02018b4:	e709                	bnez	a4,ffffffffc02018be <default_init_memmap+0x20>
ffffffffc02018b6:	a07d                	j	ffffffffc0201964 <default_init_memmap+0xc6>
ffffffffc02018b8:	6798                	ld	a4,8(a5)
ffffffffc02018ba:	8b05                	andi	a4,a4,1
ffffffffc02018bc:	c745                	beqz	a4,ffffffffc0201964 <default_init_memmap+0xc6>
        p->flags = p->property = 0;
ffffffffc02018be:	0007a823          	sw	zero,16(a5)
ffffffffc02018c2:	0007b423          	sd	zero,8(a5)
ffffffffc02018c6:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02018ca:	04078793          	addi	a5,a5,64
ffffffffc02018ce:	fed795e3          	bne	a5,a3,ffffffffc02018b8 <default_init_memmap+0x1a>
    base->property = n;
ffffffffc02018d2:	2581                	sext.w	a1,a1
ffffffffc02018d4:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018d6:	4789                	li	a5,2
ffffffffc02018d8:	00850713          	addi	a4,a0,8
ffffffffc02018dc:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02018e0:	000b5697          	auipc	a3,0xb5
ffffffffc02018e4:	2f868693          	addi	a3,a3,760 # ffffffffc02b6bd8 <free_area>
ffffffffc02018e8:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02018ea:	669c                	ld	a5,8(a3)
ffffffffc02018ec:	9db9                	addw	a1,a1,a4
ffffffffc02018ee:	000b5717          	auipc	a4,0xb5
ffffffffc02018f2:	2eb72d23          	sw	a1,762(a4) # ffffffffc02b6be8 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc02018f6:	04d78a63          	beq	a5,a3,ffffffffc020194a <default_init_memmap+0xac>
            struct Page* page = le2page(le, page_link);
ffffffffc02018fa:	fe878713          	addi	a4,a5,-24
ffffffffc02018fe:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201900:	4801                	li	a6,0
ffffffffc0201902:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201906:	00e56a63          	bltu	a0,a4,ffffffffc020191a <default_init_memmap+0x7c>
    return listelm->next;
ffffffffc020190a:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020190c:	02d70563          	beq	a4,a3,ffffffffc0201936 <default_init_memmap+0x98>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201910:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201912:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201916:	fee57ae3          	bleu	a4,a0,ffffffffc020190a <default_init_memmap+0x6c>
ffffffffc020191a:	00080663          	beqz	a6,ffffffffc0201926 <default_init_memmap+0x88>
ffffffffc020191e:	000b5717          	auipc	a4,0xb5
ffffffffc0201922:	2ab73d23          	sd	a1,698(a4) # ffffffffc02b6bd8 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201926:	6398                	ld	a4,0(a5)
}
ffffffffc0201928:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020192a:	e390                	sd	a2,0(a5)
ffffffffc020192c:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020192e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201930:	ed18                	sd	a4,24(a0)
ffffffffc0201932:	0141                	addi	sp,sp,16
ffffffffc0201934:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201936:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201938:	f114                	sd	a3,32(a0)
ffffffffc020193a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020193c:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020193e:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201940:	00d70e63          	beq	a4,a3,ffffffffc020195c <default_init_memmap+0xbe>
ffffffffc0201944:	4805                	li	a6,1
ffffffffc0201946:	87ba                	mv	a5,a4
ffffffffc0201948:	b7e9                	j	ffffffffc0201912 <default_init_memmap+0x74>
}
ffffffffc020194a:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020194c:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201950:	e398                	sd	a4,0(a5)
ffffffffc0201952:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201954:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201956:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201958:	0141                	addi	sp,sp,16
ffffffffc020195a:	8082                	ret
ffffffffc020195c:	60a2                	ld	ra,8(sp)
ffffffffc020195e:	e290                	sd	a2,0(a3)
ffffffffc0201960:	0141                	addi	sp,sp,16
ffffffffc0201962:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201964:	00006697          	auipc	a3,0x6
ffffffffc0201968:	b2468693          	addi	a3,a3,-1244 # ffffffffc0207488 <commands+0xbf8>
ffffffffc020196c:	00005617          	auipc	a2,0x5
ffffffffc0201970:	3e460613          	addi	a2,a2,996 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201974:	04900593          	li	a1,73
ffffffffc0201978:	00005517          	auipc	a0,0x5
ffffffffc020197c:	7a050513          	addi	a0,a0,1952 # ffffffffc0207118 <commands+0x888>
ffffffffc0201980:	b05fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(n > 0);
ffffffffc0201984:	00006697          	auipc	a3,0x6
ffffffffc0201988:	afc68693          	addi	a3,a3,-1284 # ffffffffc0207480 <commands+0xbf0>
ffffffffc020198c:	00005617          	auipc	a2,0x5
ffffffffc0201990:	3c460613          	addi	a2,a2,964 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201994:	04600593          	li	a1,70
ffffffffc0201998:	00005517          	auipc	a0,0x5
ffffffffc020199c:	78050513          	addi	a0,a0,1920 # ffffffffc0207118 <commands+0x888>
ffffffffc02019a0:	ae5fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02019a4 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc02019a4:	c125                	beqz	a0,ffffffffc0201a04 <slob_free+0x60>
		return;

	if (size)
ffffffffc02019a6:	e1a5                	bnez	a1,ffffffffc0201a06 <slob_free+0x62>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019a8:	100027f3          	csrr	a5,sstatus
ffffffffc02019ac:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02019ae:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019b0:	e3bd                	bnez	a5,ffffffffc0201a16 <slob_free+0x72>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019b2:	000aa797          	auipc	a5,0xaa
ffffffffc02019b6:	db678793          	addi	a5,a5,-586 # ffffffffc02ab768 <slobfree>
ffffffffc02019ba:	639c                	ld	a5,0(a5)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019bc:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019be:	00a7fa63          	bleu	a0,a5,ffffffffc02019d2 <slob_free+0x2e>
ffffffffc02019c2:	00e56c63          	bltu	a0,a4,ffffffffc02019da <slob_free+0x36>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019c6:	00e7fa63          	bleu	a4,a5,ffffffffc02019da <slob_free+0x36>
    return 0;
ffffffffc02019ca:	87ba                	mv	a5,a4
ffffffffc02019cc:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019ce:	fea7eae3          	bltu	a5,a0,ffffffffc02019c2 <slob_free+0x1e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019d2:	fee7ece3          	bltu	a5,a4,ffffffffc02019ca <slob_free+0x26>
ffffffffc02019d6:	fee57ae3          	bleu	a4,a0,ffffffffc02019ca <slob_free+0x26>
			break;

	if (b + b->units == cur->next) {
ffffffffc02019da:	4110                	lw	a2,0(a0)
ffffffffc02019dc:	00461693          	slli	a3,a2,0x4
ffffffffc02019e0:	96aa                	add	a3,a3,a0
ffffffffc02019e2:	08d70b63          	beq	a4,a3,ffffffffc0201a78 <slob_free+0xd4>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc02019e6:	4394                	lw	a3,0(a5)
		b->next = cur->next;
ffffffffc02019e8:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc02019ea:	00469713          	slli	a4,a3,0x4
ffffffffc02019ee:	973e                	add	a4,a4,a5
ffffffffc02019f0:	08e50f63          	beq	a0,a4,ffffffffc0201a8e <slob_free+0xea>
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;
ffffffffc02019f4:	e788                	sd	a0,8(a5)

	slobfree = cur;
ffffffffc02019f6:	000aa717          	auipc	a4,0xaa
ffffffffc02019fa:	d6f73923          	sd	a5,-654(a4) # ffffffffc02ab768 <slobfree>
    if (flag) {
ffffffffc02019fe:	c199                	beqz	a1,ffffffffc0201a04 <slob_free+0x60>
        intr_enable();
ffffffffc0201a00:	c55fe06f          	j	ffffffffc0200654 <intr_enable>
ffffffffc0201a04:	8082                	ret
		b->units = SLOB_UNITS(size);
ffffffffc0201a06:	05bd                	addi	a1,a1,15
ffffffffc0201a08:	8191                	srli	a1,a1,0x4
ffffffffc0201a0a:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a0c:	100027f3          	csrr	a5,sstatus
ffffffffc0201a10:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a12:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a14:	dfd9                	beqz	a5,ffffffffc02019b2 <slob_free+0xe>
{
ffffffffc0201a16:	1101                	addi	sp,sp,-32
ffffffffc0201a18:	e42a                	sd	a0,8(sp)
ffffffffc0201a1a:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201a1c:	c3ffe0ef          	jal	ra,ffffffffc020065a <intr_disable>
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a20:	000aa797          	auipc	a5,0xaa
ffffffffc0201a24:	d4878793          	addi	a5,a5,-696 # ffffffffc02ab768 <slobfree>
ffffffffc0201a28:	639c                	ld	a5,0(a5)
        return 1;
ffffffffc0201a2a:	6522                	ld	a0,8(sp)
ffffffffc0201a2c:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a2e:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a30:	00a7fa63          	bleu	a0,a5,ffffffffc0201a44 <slob_free+0xa0>
ffffffffc0201a34:	00e56c63          	bltu	a0,a4,ffffffffc0201a4c <slob_free+0xa8>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a38:	00e7fa63          	bleu	a4,a5,ffffffffc0201a4c <slob_free+0xa8>
    return 0;
ffffffffc0201a3c:	87ba                	mv	a5,a4
ffffffffc0201a3e:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a40:	fea7eae3          	bltu	a5,a0,ffffffffc0201a34 <slob_free+0x90>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a44:	fee7ece3          	bltu	a5,a4,ffffffffc0201a3c <slob_free+0x98>
ffffffffc0201a48:	fee57ae3          	bleu	a4,a0,ffffffffc0201a3c <slob_free+0x98>
	if (b + b->units == cur->next) {
ffffffffc0201a4c:	4110                	lw	a2,0(a0)
ffffffffc0201a4e:	00461693          	slli	a3,a2,0x4
ffffffffc0201a52:	96aa                	add	a3,a3,a0
ffffffffc0201a54:	04d70763          	beq	a4,a3,ffffffffc0201aa2 <slob_free+0xfe>
		b->next = cur->next;
ffffffffc0201a58:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc0201a5a:	4394                	lw	a3,0(a5)
ffffffffc0201a5c:	00469713          	slli	a4,a3,0x4
ffffffffc0201a60:	973e                	add	a4,a4,a5
ffffffffc0201a62:	04e50663          	beq	a0,a4,ffffffffc0201aae <slob_free+0x10a>
		cur->next = b;
ffffffffc0201a66:	e788                	sd	a0,8(a5)
	slobfree = cur;
ffffffffc0201a68:	000aa717          	auipc	a4,0xaa
ffffffffc0201a6c:	d0f73023          	sd	a5,-768(a4) # ffffffffc02ab768 <slobfree>
    if (flag) {
ffffffffc0201a70:	e58d                	bnez	a1,ffffffffc0201a9a <slob_free+0xf6>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201a72:	60e2                	ld	ra,24(sp)
ffffffffc0201a74:	6105                	addi	sp,sp,32
ffffffffc0201a76:	8082                	ret
		b->units += cur->next->units;
ffffffffc0201a78:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201a7a:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc0201a7c:	9e35                	addw	a2,a2,a3
ffffffffc0201a7e:	c110                	sw	a2,0(a0)
	if (cur + cur->units == b) {
ffffffffc0201a80:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201a82:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc0201a84:	00469713          	slli	a4,a3,0x4
ffffffffc0201a88:	973e                	add	a4,a4,a5
ffffffffc0201a8a:	f6e515e3          	bne	a0,a4,ffffffffc02019f4 <slob_free+0x50>
		cur->units += b->units;
ffffffffc0201a8e:	4118                	lw	a4,0(a0)
		cur->next = b->next;
ffffffffc0201a90:	6510                	ld	a2,8(a0)
		cur->units += b->units;
ffffffffc0201a92:	9eb9                	addw	a3,a3,a4
ffffffffc0201a94:	c394                	sw	a3,0(a5)
		cur->next = b->next;
ffffffffc0201a96:	e790                	sd	a2,8(a5)
ffffffffc0201a98:	bfb9                	j	ffffffffc02019f6 <slob_free+0x52>
}
ffffffffc0201a9a:	60e2                	ld	ra,24(sp)
ffffffffc0201a9c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201a9e:	bb7fe06f          	j	ffffffffc0200654 <intr_enable>
		b->units += cur->next->units;
ffffffffc0201aa2:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201aa4:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc0201aa6:	9e35                	addw	a2,a2,a3
ffffffffc0201aa8:	c110                	sw	a2,0(a0)
		b->next = cur->next->next;
ffffffffc0201aaa:	e518                	sd	a4,8(a0)
ffffffffc0201aac:	b77d                	j	ffffffffc0201a5a <slob_free+0xb6>
		cur->units += b->units;
ffffffffc0201aae:	4118                	lw	a4,0(a0)
		cur->next = b->next;
ffffffffc0201ab0:	6510                	ld	a2,8(a0)
		cur->units += b->units;
ffffffffc0201ab2:	9eb9                	addw	a3,a3,a4
ffffffffc0201ab4:	c394                	sw	a3,0(a5)
		cur->next = b->next;
ffffffffc0201ab6:	e790                	sd	a2,8(a5)
ffffffffc0201ab8:	bf45                	j	ffffffffc0201a68 <slob_free+0xc4>

ffffffffc0201aba <__slob_get_free_pages.isra.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201aba:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201abc:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201abe:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201ac2:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201ac4:	38e000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
  if(!page)
ffffffffc0201ac8:	c139                	beqz	a0,ffffffffc0201b0e <__slob_get_free_pages.isra.0+0x54>
    return page - pages + nbase;
ffffffffc0201aca:	000b5797          	auipc	a5,0xb5
ffffffffc0201ace:	13e78793          	addi	a5,a5,318 # ffffffffc02b6c08 <pages>
ffffffffc0201ad2:	6394                	ld	a3,0(a5)
ffffffffc0201ad4:	00007797          	auipc	a5,0x7
ffffffffc0201ad8:	3dc78793          	addi	a5,a5,988 # ffffffffc0208eb0 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201adc:	000b5717          	auipc	a4,0xb5
ffffffffc0201ae0:	0bc70713          	addi	a4,a4,188 # ffffffffc02b6b98 <npage>
    return page - pages + nbase;
ffffffffc0201ae4:	40d506b3          	sub	a3,a0,a3
ffffffffc0201ae8:	6388                	ld	a0,0(a5)
ffffffffc0201aea:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0201aec:	57fd                	li	a5,-1
ffffffffc0201aee:	6318                	ld	a4,0(a4)
    return page - pages + nbase;
ffffffffc0201af0:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc0201af2:	83b1                	srli	a5,a5,0xc
ffffffffc0201af4:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0201af6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201af8:	00e7ff63          	bleu	a4,a5,ffffffffc0201b16 <__slob_get_free_pages.isra.0+0x5c>
ffffffffc0201afc:	000b5797          	auipc	a5,0xb5
ffffffffc0201b00:	0fc78793          	addi	a5,a5,252 # ffffffffc02b6bf8 <va_pa_offset>
ffffffffc0201b04:	6388                	ld	a0,0(a5)
}
ffffffffc0201b06:	60a2                	ld	ra,8(sp)
ffffffffc0201b08:	9536                	add	a0,a0,a3
ffffffffc0201b0a:	0141                	addi	sp,sp,16
ffffffffc0201b0c:	8082                	ret
ffffffffc0201b0e:	60a2                	ld	ra,8(sp)
    return NULL;
ffffffffc0201b10:	4501                	li	a0,0
}
ffffffffc0201b12:	0141                	addi	sp,sp,16
ffffffffc0201b14:	8082                	ret
ffffffffc0201b16:	00006617          	auipc	a2,0x6
ffffffffc0201b1a:	9d260613          	addi	a2,a2,-1582 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc0201b1e:	06900593          	li	a1,105
ffffffffc0201b22:	00006517          	auipc	a0,0x6
ffffffffc0201b26:	9ee50513          	addi	a0,a0,-1554 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0201b2a:	95bfe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201b2e <slob_alloc.isra.1.constprop.3>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201b2e:	7179                	addi	sp,sp,-48
ffffffffc0201b30:	f406                	sd	ra,40(sp)
ffffffffc0201b32:	f022                	sd	s0,32(sp)
ffffffffc0201b34:	ec26                	sd	s1,24(sp)
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201b36:	01050713          	addi	a4,a0,16
ffffffffc0201b3a:	6785                	lui	a5,0x1
ffffffffc0201b3c:	0cf77b63          	bleu	a5,a4,ffffffffc0201c12 <slob_alloc.isra.1.constprop.3+0xe4>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201b40:	00f50413          	addi	s0,a0,15
ffffffffc0201b44:	8011                	srli	s0,s0,0x4
ffffffffc0201b46:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b48:	10002673          	csrr	a2,sstatus
ffffffffc0201b4c:	8a09                	andi	a2,a2,2
ffffffffc0201b4e:	ea5d                	bnez	a2,ffffffffc0201c04 <slob_alloc.isra.1.constprop.3+0xd6>
	prev = slobfree;
ffffffffc0201b50:	000aa497          	auipc	s1,0xaa
ffffffffc0201b54:	c1848493          	addi	s1,s1,-1000 # ffffffffc02ab768 <slobfree>
ffffffffc0201b58:	6094                	ld	a3,0(s1)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201b5a:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201b5c:	4398                	lw	a4,0(a5)
ffffffffc0201b5e:	0a875763          	ble	s0,a4,ffffffffc0201c0c <slob_alloc.isra.1.constprop.3+0xde>
		if (cur == slobfree) {
ffffffffc0201b62:	00f68a63          	beq	a3,a5,ffffffffc0201b76 <slob_alloc.isra.1.constprop.3+0x48>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201b66:	6788                	ld	a0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201b68:	4118                	lw	a4,0(a0)
ffffffffc0201b6a:	02875763          	ble	s0,a4,ffffffffc0201b98 <slob_alloc.isra.1.constprop.3+0x6a>
ffffffffc0201b6e:	6094                	ld	a3,0(s1)
ffffffffc0201b70:	87aa                	mv	a5,a0
		if (cur == slobfree) {
ffffffffc0201b72:	fef69ae3          	bne	a3,a5,ffffffffc0201b66 <slob_alloc.isra.1.constprop.3+0x38>
    if (flag) {
ffffffffc0201b76:	ea39                	bnez	a2,ffffffffc0201bcc <slob_alloc.isra.1.constprop.3+0x9e>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201b78:	4501                	li	a0,0
ffffffffc0201b7a:	f41ff0ef          	jal	ra,ffffffffc0201aba <__slob_get_free_pages.isra.0>
			if (!cur)
ffffffffc0201b7e:	cd29                	beqz	a0,ffffffffc0201bd8 <slob_alloc.isra.1.constprop.3+0xaa>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201b80:	6585                	lui	a1,0x1
ffffffffc0201b82:	e23ff0ef          	jal	ra,ffffffffc02019a4 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b86:	10002673          	csrr	a2,sstatus
ffffffffc0201b8a:	8a09                	andi	a2,a2,2
ffffffffc0201b8c:	ea1d                	bnez	a2,ffffffffc0201bc2 <slob_alloc.isra.1.constprop.3+0x94>
			cur = slobfree;
ffffffffc0201b8e:	609c                	ld	a5,0(s1)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201b90:	6788                	ld	a0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201b92:	4118                	lw	a4,0(a0)
ffffffffc0201b94:	fc874de3          	blt	a4,s0,ffffffffc0201b6e <slob_alloc.isra.1.constprop.3+0x40>
			if (cur->units == units) /* exact fit? */
ffffffffc0201b98:	04e40663          	beq	s0,a4,ffffffffc0201be4 <slob_alloc.isra.1.constprop.3+0xb6>
				prev->next = cur + units;
ffffffffc0201b9c:	00441693          	slli	a3,s0,0x4
ffffffffc0201ba0:	96aa                	add	a3,a3,a0
ffffffffc0201ba2:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201ba4:	650c                	ld	a1,8(a0)
				prev->next->units = cur->units - units;
ffffffffc0201ba6:	9f01                	subw	a4,a4,s0
ffffffffc0201ba8:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201baa:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201bac:	c100                	sw	s0,0(a0)
			slobfree = prev;
ffffffffc0201bae:	000aa717          	auipc	a4,0xaa
ffffffffc0201bb2:	baf73d23          	sd	a5,-1094(a4) # ffffffffc02ab768 <slobfree>
    if (flag) {
ffffffffc0201bb6:	ee15                	bnez	a2,ffffffffc0201bf2 <slob_alloc.isra.1.constprop.3+0xc4>
}
ffffffffc0201bb8:	70a2                	ld	ra,40(sp)
ffffffffc0201bba:	7402                	ld	s0,32(sp)
ffffffffc0201bbc:	64e2                	ld	s1,24(sp)
ffffffffc0201bbe:	6145                	addi	sp,sp,48
ffffffffc0201bc0:	8082                	ret
        intr_disable();
ffffffffc0201bc2:	a99fe0ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc0201bc6:	4605                	li	a2,1
			cur = slobfree;
ffffffffc0201bc8:	609c                	ld	a5,0(s1)
ffffffffc0201bca:	b7d9                	j	ffffffffc0201b90 <slob_alloc.isra.1.constprop.3+0x62>
        intr_enable();
ffffffffc0201bcc:	a89fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201bd0:	4501                	li	a0,0
ffffffffc0201bd2:	ee9ff0ef          	jal	ra,ffffffffc0201aba <__slob_get_free_pages.isra.0>
			if (!cur)
ffffffffc0201bd6:	f54d                	bnez	a0,ffffffffc0201b80 <slob_alloc.isra.1.constprop.3+0x52>
}
ffffffffc0201bd8:	70a2                	ld	ra,40(sp)
ffffffffc0201bda:	7402                	ld	s0,32(sp)
ffffffffc0201bdc:	64e2                	ld	s1,24(sp)
				return 0;
ffffffffc0201bde:	4501                	li	a0,0
}
ffffffffc0201be0:	6145                	addi	sp,sp,48
ffffffffc0201be2:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201be4:	6518                	ld	a4,8(a0)
ffffffffc0201be6:	e798                	sd	a4,8(a5)
			slobfree = prev;
ffffffffc0201be8:	000aa717          	auipc	a4,0xaa
ffffffffc0201bec:	b8f73023          	sd	a5,-1152(a4) # ffffffffc02ab768 <slobfree>
    if (flag) {
ffffffffc0201bf0:	d661                	beqz	a2,ffffffffc0201bb8 <slob_alloc.isra.1.constprop.3+0x8a>
ffffffffc0201bf2:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201bf4:	a61fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
}
ffffffffc0201bf8:	70a2                	ld	ra,40(sp)
ffffffffc0201bfa:	7402                	ld	s0,32(sp)
ffffffffc0201bfc:	6522                	ld	a0,8(sp)
ffffffffc0201bfe:	64e2                	ld	s1,24(sp)
ffffffffc0201c00:	6145                	addi	sp,sp,48
ffffffffc0201c02:	8082                	ret
        intr_disable();
ffffffffc0201c04:	a57fe0ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc0201c08:	4605                	li	a2,1
ffffffffc0201c0a:	b799                	j	ffffffffc0201b50 <slob_alloc.isra.1.constprop.3+0x22>
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201c0c:	853e                	mv	a0,a5
ffffffffc0201c0e:	87b6                	mv	a5,a3
ffffffffc0201c10:	b761                	j	ffffffffc0201b98 <slob_alloc.isra.1.constprop.3+0x6a>
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201c12:	00006697          	auipc	a3,0x6
ffffffffc0201c16:	97668693          	addi	a3,a3,-1674 # ffffffffc0207588 <default_pmm_manager+0xf0>
ffffffffc0201c1a:	00005617          	auipc	a2,0x5
ffffffffc0201c1e:	13660613          	addi	a2,a2,310 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0201c22:	06400593          	li	a1,100
ffffffffc0201c26:	00006517          	auipc	a0,0x6
ffffffffc0201c2a:	98250513          	addi	a0,a0,-1662 # ffffffffc02075a8 <default_pmm_manager+0x110>
ffffffffc0201c2e:	857fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201c32 <kmalloc_init>:
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
ffffffffc0201c32:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc0201c34:	00006517          	auipc	a0,0x6
ffffffffc0201c38:	98c50513          	addi	a0,a0,-1652 # ffffffffc02075c0 <default_pmm_manager+0x128>
kmalloc_init(void) {
ffffffffc0201c3c:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc0201c3e:	d50fe0ef          	jal	ra,ffffffffc020018e <cprintf>
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201c42:	60a2                	ld	ra,8(sp)
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c44:	00006517          	auipc	a0,0x6
ffffffffc0201c48:	92450513          	addi	a0,a0,-1756 # ffffffffc0207568 <default_pmm_manager+0xd0>
}
ffffffffc0201c4c:	0141                	addi	sp,sp,16
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c4e:	d40fe06f          	j	ffffffffc020018e <cprintf>

ffffffffc0201c52 <kallocated>:
}

size_t
kallocated(void) {
   return slob_allocated();
}
ffffffffc0201c52:	4501                	li	a0,0
ffffffffc0201c54:	8082                	ret

ffffffffc0201c56 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201c56:	1101                	addi	sp,sp,-32
ffffffffc0201c58:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201c5a:	6905                	lui	s2,0x1
{
ffffffffc0201c5c:	e822                	sd	s0,16(sp)
ffffffffc0201c5e:	ec06                	sd	ra,24(sp)
ffffffffc0201c60:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201c62:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8591>
{
ffffffffc0201c66:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201c68:	04a7fc63          	bleu	a0,a5,ffffffffc0201cc0 <kmalloc+0x6a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201c6c:	4561                	li	a0,24
ffffffffc0201c6e:	ec1ff0ef          	jal	ra,ffffffffc0201b2e <slob_alloc.isra.1.constprop.3>
ffffffffc0201c72:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201c74:	cd21                	beqz	a0,ffffffffc0201ccc <kmalloc+0x76>
	bb->order = find_order(size);
ffffffffc0201c76:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201c7a:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201c7c:	00f95763          	ble	a5,s2,ffffffffc0201c8a <kmalloc+0x34>
ffffffffc0201c80:	6705                	lui	a4,0x1
ffffffffc0201c82:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201c84:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201c86:	fef74ee3          	blt	a4,a5,ffffffffc0201c82 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201c8a:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201c8c:	e2fff0ef          	jal	ra,ffffffffc0201aba <__slob_get_free_pages.isra.0>
ffffffffc0201c90:	e488                	sd	a0,8(s1)
ffffffffc0201c92:	842a                	mv	s0,a0
	if (bb->pages) {
ffffffffc0201c94:	c935                	beqz	a0,ffffffffc0201d08 <kmalloc+0xb2>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c96:	100027f3          	csrr	a5,sstatus
ffffffffc0201c9a:	8b89                	andi	a5,a5,2
ffffffffc0201c9c:	e3a1                	bnez	a5,ffffffffc0201cdc <kmalloc+0x86>
		bb->next = bigblocks;
ffffffffc0201c9e:	000b5797          	auipc	a5,0xb5
ffffffffc0201ca2:	eea78793          	addi	a5,a5,-278 # ffffffffc02b6b88 <bigblocks>
ffffffffc0201ca6:	639c                	ld	a5,0(a5)
		bigblocks = bb;
ffffffffc0201ca8:	000b5717          	auipc	a4,0xb5
ffffffffc0201cac:	ee973023          	sd	s1,-288(a4) # ffffffffc02b6b88 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201cb0:	e89c                	sd	a5,16(s1)
  return __kmalloc(size, 0);
}
ffffffffc0201cb2:	8522                	mv	a0,s0
ffffffffc0201cb4:	60e2                	ld	ra,24(sp)
ffffffffc0201cb6:	6442                	ld	s0,16(sp)
ffffffffc0201cb8:	64a2                	ld	s1,8(sp)
ffffffffc0201cba:	6902                	ld	s2,0(sp)
ffffffffc0201cbc:	6105                	addi	sp,sp,32
ffffffffc0201cbe:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201cc0:	0541                	addi	a0,a0,16
ffffffffc0201cc2:	e6dff0ef          	jal	ra,ffffffffc0201b2e <slob_alloc.isra.1.constprop.3>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201cc6:	01050413          	addi	s0,a0,16
ffffffffc0201cca:	f565                	bnez	a0,ffffffffc0201cb2 <kmalloc+0x5c>
ffffffffc0201ccc:	4401                	li	s0,0
}
ffffffffc0201cce:	8522                	mv	a0,s0
ffffffffc0201cd0:	60e2                	ld	ra,24(sp)
ffffffffc0201cd2:	6442                	ld	s0,16(sp)
ffffffffc0201cd4:	64a2                	ld	s1,8(sp)
ffffffffc0201cd6:	6902                	ld	s2,0(sp)
ffffffffc0201cd8:	6105                	addi	sp,sp,32
ffffffffc0201cda:	8082                	ret
        intr_disable();
ffffffffc0201cdc:	97ffe0ef          	jal	ra,ffffffffc020065a <intr_disable>
		bb->next = bigblocks;
ffffffffc0201ce0:	000b5797          	auipc	a5,0xb5
ffffffffc0201ce4:	ea878793          	addi	a5,a5,-344 # ffffffffc02b6b88 <bigblocks>
ffffffffc0201ce8:	639c                	ld	a5,0(a5)
		bigblocks = bb;
ffffffffc0201cea:	000b5717          	auipc	a4,0xb5
ffffffffc0201cee:	e8973f23          	sd	s1,-354(a4) # ffffffffc02b6b88 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201cf2:	e89c                	sd	a5,16(s1)
        intr_enable();
ffffffffc0201cf4:	961fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0201cf8:	6480                	ld	s0,8(s1)
}
ffffffffc0201cfa:	60e2                	ld	ra,24(sp)
ffffffffc0201cfc:	64a2                	ld	s1,8(sp)
ffffffffc0201cfe:	8522                	mv	a0,s0
ffffffffc0201d00:	6442                	ld	s0,16(sp)
ffffffffc0201d02:	6902                	ld	s2,0(sp)
ffffffffc0201d04:	6105                	addi	sp,sp,32
ffffffffc0201d06:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d08:	45e1                	li	a1,24
ffffffffc0201d0a:	8526                	mv	a0,s1
ffffffffc0201d0c:	c99ff0ef          	jal	ra,ffffffffc02019a4 <slob_free>
  return __kmalloc(size, 0);
ffffffffc0201d10:	b74d                	j	ffffffffc0201cb2 <kmalloc+0x5c>

ffffffffc0201d12 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201d12:	c175                	beqz	a0,ffffffffc0201df6 <kfree+0xe4>
{
ffffffffc0201d14:	1101                	addi	sp,sp,-32
ffffffffc0201d16:	e426                	sd	s1,8(sp)
ffffffffc0201d18:	ec06                	sd	ra,24(sp)
ffffffffc0201d1a:	e822                	sd	s0,16(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc0201d1c:	03451793          	slli	a5,a0,0x34
ffffffffc0201d20:	84aa                	mv	s1,a0
ffffffffc0201d22:	eb8d                	bnez	a5,ffffffffc0201d54 <kfree+0x42>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d24:	100027f3          	csrr	a5,sstatus
ffffffffc0201d28:	8b89                	andi	a5,a5,2
ffffffffc0201d2a:	efc9                	bnez	a5,ffffffffc0201dc4 <kfree+0xb2>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201d2c:	000b5797          	auipc	a5,0xb5
ffffffffc0201d30:	e5c78793          	addi	a5,a5,-420 # ffffffffc02b6b88 <bigblocks>
ffffffffc0201d34:	6394                	ld	a3,0(a5)
ffffffffc0201d36:	ce99                	beqz	a3,ffffffffc0201d54 <kfree+0x42>
			if (bb->pages == block) {
ffffffffc0201d38:	669c                	ld	a5,8(a3)
ffffffffc0201d3a:	6a80                	ld	s0,16(a3)
ffffffffc0201d3c:	0af50e63          	beq	a0,a5,ffffffffc0201df8 <kfree+0xe6>
    return 0;
ffffffffc0201d40:	4601                	li	a2,0
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201d42:	c801                	beqz	s0,ffffffffc0201d52 <kfree+0x40>
			if (bb->pages == block) {
ffffffffc0201d44:	6418                	ld	a4,8(s0)
ffffffffc0201d46:	681c                	ld	a5,16(s0)
ffffffffc0201d48:	00970f63          	beq	a4,s1,ffffffffc0201d66 <kfree+0x54>
ffffffffc0201d4c:	86a2                	mv	a3,s0
ffffffffc0201d4e:	843e                	mv	s0,a5
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201d50:	f875                	bnez	s0,ffffffffc0201d44 <kfree+0x32>
    if (flag) {
ffffffffc0201d52:	e659                	bnez	a2,ffffffffc0201de0 <kfree+0xce>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201d54:	6442                	ld	s0,16(sp)
ffffffffc0201d56:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d58:	ff048513          	addi	a0,s1,-16
}
ffffffffc0201d5c:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d5e:	4581                	li	a1,0
}
ffffffffc0201d60:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d62:	c43ff06f          	j	ffffffffc02019a4 <slob_free>
				*last = bb->next;
ffffffffc0201d66:	ea9c                	sd	a5,16(a3)
ffffffffc0201d68:	e641                	bnez	a2,ffffffffc0201df0 <kfree+0xde>
    return pa2page(PADDR(kva));
ffffffffc0201d6a:	c02007b7          	lui	a5,0xc0200
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201d6e:	4018                	lw	a4,0(s0)
ffffffffc0201d70:	08f4ea63          	bltu	s1,a5,ffffffffc0201e04 <kfree+0xf2>
ffffffffc0201d74:	000b5797          	auipc	a5,0xb5
ffffffffc0201d78:	e8478793          	addi	a5,a5,-380 # ffffffffc02b6bf8 <va_pa_offset>
ffffffffc0201d7c:	6394                	ld	a3,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0201d7e:	000b5797          	auipc	a5,0xb5
ffffffffc0201d82:	e1a78793          	addi	a5,a5,-486 # ffffffffc02b6b98 <npage>
ffffffffc0201d86:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc0201d88:	8c95                	sub	s1,s1,a3
    if (PPN(pa) >= npage) {
ffffffffc0201d8a:	80b1                	srli	s1,s1,0xc
ffffffffc0201d8c:	08f4f963          	bleu	a5,s1,ffffffffc0201e1e <kfree+0x10c>
    return &pages[PPN(pa) - nbase];
ffffffffc0201d90:	00007797          	auipc	a5,0x7
ffffffffc0201d94:	12078793          	addi	a5,a5,288 # ffffffffc0208eb0 <nbase>
ffffffffc0201d98:	639c                	ld	a5,0(a5)
ffffffffc0201d9a:	000b5697          	auipc	a3,0xb5
ffffffffc0201d9e:	e6e68693          	addi	a3,a3,-402 # ffffffffc02b6c08 <pages>
ffffffffc0201da2:	6288                	ld	a0,0(a3)
ffffffffc0201da4:	8c9d                	sub	s1,s1,a5
ffffffffc0201da6:	049a                	slli	s1,s1,0x6
  free_pages(kva2page(kva), 1 << order);
ffffffffc0201da8:	4585                	li	a1,1
ffffffffc0201daa:	9526                	add	a0,a0,s1
ffffffffc0201dac:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201db0:	12a000ef          	jal	ra,ffffffffc0201eda <free_pages>
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201db4:	8522                	mv	a0,s0
}
ffffffffc0201db6:	6442                	ld	s0,16(sp)
ffffffffc0201db8:	60e2                	ld	ra,24(sp)
ffffffffc0201dba:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dbc:	45e1                	li	a1,24
}
ffffffffc0201dbe:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201dc0:	be5ff06f          	j	ffffffffc02019a4 <slob_free>
        intr_disable();
ffffffffc0201dc4:	897fe0ef          	jal	ra,ffffffffc020065a <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201dc8:	000b5797          	auipc	a5,0xb5
ffffffffc0201dcc:	dc078793          	addi	a5,a5,-576 # ffffffffc02b6b88 <bigblocks>
ffffffffc0201dd0:	6394                	ld	a3,0(a5)
ffffffffc0201dd2:	c699                	beqz	a3,ffffffffc0201de0 <kfree+0xce>
			if (bb->pages == block) {
ffffffffc0201dd4:	669c                	ld	a5,8(a3)
ffffffffc0201dd6:	6a80                	ld	s0,16(a3)
ffffffffc0201dd8:	00f48763          	beq	s1,a5,ffffffffc0201de6 <kfree+0xd4>
        return 1;
ffffffffc0201ddc:	4605                	li	a2,1
ffffffffc0201dde:	b795                	j	ffffffffc0201d42 <kfree+0x30>
        intr_enable();
ffffffffc0201de0:	875fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0201de4:	bf85                	j	ffffffffc0201d54 <kfree+0x42>
				*last = bb->next;
ffffffffc0201de6:	000b5797          	auipc	a5,0xb5
ffffffffc0201dea:	da87b123          	sd	s0,-606(a5) # ffffffffc02b6b88 <bigblocks>
ffffffffc0201dee:	8436                	mv	s0,a3
ffffffffc0201df0:	865fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0201df4:	bf9d                	j	ffffffffc0201d6a <kfree+0x58>
ffffffffc0201df6:	8082                	ret
ffffffffc0201df8:	000b5797          	auipc	a5,0xb5
ffffffffc0201dfc:	d887b823          	sd	s0,-624(a5) # ffffffffc02b6b88 <bigblocks>
ffffffffc0201e00:	8436                	mv	s0,a3
ffffffffc0201e02:	b7a5                	j	ffffffffc0201d6a <kfree+0x58>
    return pa2page(PADDR(kva));
ffffffffc0201e04:	86a6                	mv	a3,s1
ffffffffc0201e06:	00005617          	auipc	a2,0x5
ffffffffc0201e0a:	71a60613          	addi	a2,a2,1818 # ffffffffc0207520 <default_pmm_manager+0x88>
ffffffffc0201e0e:	06e00593          	li	a1,110
ffffffffc0201e12:	00005517          	auipc	a0,0x5
ffffffffc0201e16:	6fe50513          	addi	a0,a0,1790 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0201e1a:	e6afe0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201e1e:	00005617          	auipc	a2,0x5
ffffffffc0201e22:	72a60613          	addi	a2,a2,1834 # ffffffffc0207548 <default_pmm_manager+0xb0>
ffffffffc0201e26:	06200593          	li	a1,98
ffffffffc0201e2a:	00005517          	auipc	a0,0x5
ffffffffc0201e2e:	6e650513          	addi	a0,a0,1766 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0201e32:	e52fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201e36 <pa2page.part.4>:
pa2page(uintptr_t pa) {
ffffffffc0201e36:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201e38:	00005617          	auipc	a2,0x5
ffffffffc0201e3c:	71060613          	addi	a2,a2,1808 # ffffffffc0207548 <default_pmm_manager+0xb0>
ffffffffc0201e40:	06200593          	li	a1,98
ffffffffc0201e44:	00005517          	auipc	a0,0x5
ffffffffc0201e48:	6cc50513          	addi	a0,a0,1740 # ffffffffc0207510 <default_pmm_manager+0x78>
pa2page(uintptr_t pa) {
ffffffffc0201e4c:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201e4e:	e36fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201e52 <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0201e52:	715d                	addi	sp,sp,-80
ffffffffc0201e54:	e0a2                	sd	s0,64(sp)
ffffffffc0201e56:	fc26                	sd	s1,56(sp)
ffffffffc0201e58:	f84a                	sd	s2,48(sp)
ffffffffc0201e5a:	f44e                	sd	s3,40(sp)
ffffffffc0201e5c:	f052                	sd	s4,32(sp)
ffffffffc0201e5e:	ec56                	sd	s5,24(sp)
ffffffffc0201e60:	e486                	sd	ra,72(sp)
ffffffffc0201e62:	842a                	mv	s0,a0
ffffffffc0201e64:	000b5497          	auipc	s1,0xb5
ffffffffc0201e68:	d8c48493          	addi	s1,s1,-628 # ffffffffc02b6bf0 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201e6c:	4985                	li	s3,1
ffffffffc0201e6e:	000b5a17          	auipc	s4,0xb5
ffffffffc0201e72:	d3aa0a13          	addi	s4,s4,-710 # ffffffffc02b6ba8 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0201e76:	0005091b          	sext.w	s2,a0
ffffffffc0201e7a:	000b5a97          	auipc	s5,0xb5
ffffffffc0201e7e:	e6ea8a93          	addi	s5,s5,-402 # ffffffffc02b6ce8 <check_mm_struct>
ffffffffc0201e82:	a00d                	j	ffffffffc0201ea4 <alloc_pages+0x52>
            page = pmm_manager->alloc_pages(n);
ffffffffc0201e84:	609c                	ld	a5,0(s1)
ffffffffc0201e86:	6f9c                	ld	a5,24(a5)
ffffffffc0201e88:	9782                	jalr	a5
        swap_out(check_mm_struct, n, 0);
ffffffffc0201e8a:	4601                	li	a2,0
ffffffffc0201e8c:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201e8e:	ed0d                	bnez	a0,ffffffffc0201ec8 <alloc_pages+0x76>
ffffffffc0201e90:	0289ec63          	bltu	s3,s0,ffffffffc0201ec8 <alloc_pages+0x76>
ffffffffc0201e94:	000a2783          	lw	a5,0(s4)
ffffffffc0201e98:	2781                	sext.w	a5,a5
ffffffffc0201e9a:	c79d                	beqz	a5,ffffffffc0201ec8 <alloc_pages+0x76>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201e9c:	000ab503          	ld	a0,0(s5)
ffffffffc0201ea0:	4f1010ef          	jal	ra,ffffffffc0203b90 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ea4:	100027f3          	csrr	a5,sstatus
ffffffffc0201ea8:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0201eaa:	8522                	mv	a0,s0
ffffffffc0201eac:	dfe1                	beqz	a5,ffffffffc0201e84 <alloc_pages+0x32>
        intr_disable();
ffffffffc0201eae:	facfe0ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc0201eb2:	609c                	ld	a5,0(s1)
ffffffffc0201eb4:	8522                	mv	a0,s0
ffffffffc0201eb6:	6f9c                	ld	a5,24(a5)
ffffffffc0201eb8:	9782                	jalr	a5
ffffffffc0201eba:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201ebc:	f98fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0201ec0:	6522                	ld	a0,8(sp)
        swap_out(check_mm_struct, n, 0);
ffffffffc0201ec2:	4601                	li	a2,0
ffffffffc0201ec4:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201ec6:	d569                	beqz	a0,ffffffffc0201e90 <alloc_pages+0x3e>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0201ec8:	60a6                	ld	ra,72(sp)
ffffffffc0201eca:	6406                	ld	s0,64(sp)
ffffffffc0201ecc:	74e2                	ld	s1,56(sp)
ffffffffc0201ece:	7942                	ld	s2,48(sp)
ffffffffc0201ed0:	79a2                	ld	s3,40(sp)
ffffffffc0201ed2:	7a02                	ld	s4,32(sp)
ffffffffc0201ed4:	6ae2                	ld	s5,24(sp)
ffffffffc0201ed6:	6161                	addi	sp,sp,80
ffffffffc0201ed8:	8082                	ret

ffffffffc0201eda <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201eda:	100027f3          	csrr	a5,sstatus
ffffffffc0201ede:	8b89                	andi	a5,a5,2
ffffffffc0201ee0:	eb89                	bnez	a5,ffffffffc0201ef2 <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201ee2:	000b5797          	auipc	a5,0xb5
ffffffffc0201ee6:	d0e78793          	addi	a5,a5,-754 # ffffffffc02b6bf0 <pmm_manager>
ffffffffc0201eea:	639c                	ld	a5,0(a5)
ffffffffc0201eec:	0207b303          	ld	t1,32(a5)
ffffffffc0201ef0:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc0201ef2:	1101                	addi	sp,sp,-32
ffffffffc0201ef4:	ec06                	sd	ra,24(sp)
ffffffffc0201ef6:	e822                	sd	s0,16(sp)
ffffffffc0201ef8:	e426                	sd	s1,8(sp)
ffffffffc0201efa:	842a                	mv	s0,a0
ffffffffc0201efc:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201efe:	f5cfe0ef          	jal	ra,ffffffffc020065a <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201f02:	000b5797          	auipc	a5,0xb5
ffffffffc0201f06:	cee78793          	addi	a5,a5,-786 # ffffffffc02b6bf0 <pmm_manager>
ffffffffc0201f0a:	639c                	ld	a5,0(a5)
ffffffffc0201f0c:	85a6                	mv	a1,s1
ffffffffc0201f0e:	8522                	mv	a0,s0
ffffffffc0201f10:	739c                	ld	a5,32(a5)
ffffffffc0201f12:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201f14:	6442                	ld	s0,16(sp)
ffffffffc0201f16:	60e2                	ld	ra,24(sp)
ffffffffc0201f18:	64a2                	ld	s1,8(sp)
ffffffffc0201f1a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f1c:	f38fe06f          	j	ffffffffc0200654 <intr_enable>

ffffffffc0201f20 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201f20:	100027f3          	csrr	a5,sstatus
ffffffffc0201f24:	8b89                	andi	a5,a5,2
ffffffffc0201f26:	eb89                	bnez	a5,ffffffffc0201f38 <nr_free_pages+0x18>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f28:	000b5797          	auipc	a5,0xb5
ffffffffc0201f2c:	cc878793          	addi	a5,a5,-824 # ffffffffc02b6bf0 <pmm_manager>
ffffffffc0201f30:	639c                	ld	a5,0(a5)
ffffffffc0201f32:	0287b303          	ld	t1,40(a5)
ffffffffc0201f36:	8302                	jr	t1
size_t nr_free_pages(void) {
ffffffffc0201f38:	1141                	addi	sp,sp,-16
ffffffffc0201f3a:	e406                	sd	ra,8(sp)
ffffffffc0201f3c:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201f3e:	f1cfe0ef          	jal	ra,ffffffffc020065a <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f42:	000b5797          	auipc	a5,0xb5
ffffffffc0201f46:	cae78793          	addi	a5,a5,-850 # ffffffffc02b6bf0 <pmm_manager>
ffffffffc0201f4a:	639c                	ld	a5,0(a5)
ffffffffc0201f4c:	779c                	ld	a5,40(a5)
ffffffffc0201f4e:	9782                	jalr	a5
ffffffffc0201f50:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f52:	f02fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f56:	8522                	mv	a0,s0
ffffffffc0201f58:	60a2                	ld	ra,8(sp)
ffffffffc0201f5a:	6402                	ld	s0,0(sp)
ffffffffc0201f5c:	0141                	addi	sp,sp,16
ffffffffc0201f5e:	8082                	ret

ffffffffc0201f60 <get_pte>:
// parameter:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201f60:	7139                	addi	sp,sp,-64
ffffffffc0201f62:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f64:	01e5d493          	srli	s1,a1,0x1e
ffffffffc0201f68:	1ff4f493          	andi	s1,s1,511
ffffffffc0201f6c:	048e                	slli	s1,s1,0x3
ffffffffc0201f6e:	94aa                	add	s1,s1,a0
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201f70:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201f72:	f04a                	sd	s2,32(sp)
ffffffffc0201f74:	ec4e                	sd	s3,24(sp)
ffffffffc0201f76:	e852                	sd	s4,16(sp)
ffffffffc0201f78:	fc06                	sd	ra,56(sp)
ffffffffc0201f7a:	f822                	sd	s0,48(sp)
ffffffffc0201f7c:	e456                	sd	s5,8(sp)
ffffffffc0201f7e:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201f80:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201f84:	892e                	mv	s2,a1
ffffffffc0201f86:	8a32                	mv	s4,a2
ffffffffc0201f88:	000b5997          	auipc	s3,0xb5
ffffffffc0201f8c:	c1098993          	addi	s3,s3,-1008 # ffffffffc02b6b98 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201f90:	e7bd                	bnez	a5,ffffffffc0201ffe <get_pte+0x9e>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201f92:	12060c63          	beqz	a2,ffffffffc02020ca <get_pte+0x16a>
ffffffffc0201f96:	4505                	li	a0,1
ffffffffc0201f98:	ebbff0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0201f9c:	842a                	mv	s0,a0
ffffffffc0201f9e:	12050663          	beqz	a0,ffffffffc02020ca <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0201fa2:	000b5b17          	auipc	s6,0xb5
ffffffffc0201fa6:	c66b0b13          	addi	s6,s6,-922 # ffffffffc02b6c08 <pages>
ffffffffc0201faa:	000b3503          	ld	a0,0(s6)
    page->ref = val;
ffffffffc0201fae:	4785                	li	a5,1
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201fb0:	000b5997          	auipc	s3,0xb5
ffffffffc0201fb4:	be898993          	addi	s3,s3,-1048 # ffffffffc02b6b98 <npage>
    return page - pages + nbase;
ffffffffc0201fb8:	40a40533          	sub	a0,s0,a0
ffffffffc0201fbc:	00080ab7          	lui	s5,0x80
ffffffffc0201fc0:	8519                	srai	a0,a0,0x6
ffffffffc0201fc2:	0009b703          	ld	a4,0(s3)
    page->ref = val;
ffffffffc0201fc6:	c01c                	sw	a5,0(s0)
ffffffffc0201fc8:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc0201fca:	9556                	add	a0,a0,s5
ffffffffc0201fcc:	83b1                	srli	a5,a5,0xc
ffffffffc0201fce:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0201fd0:	0532                	slli	a0,a0,0xc
ffffffffc0201fd2:	14e7f363          	bleu	a4,a5,ffffffffc0202118 <get_pte+0x1b8>
ffffffffc0201fd6:	000b5797          	auipc	a5,0xb5
ffffffffc0201fda:	c2278793          	addi	a5,a5,-990 # ffffffffc02b6bf8 <va_pa_offset>
ffffffffc0201fde:	639c                	ld	a5,0(a5)
ffffffffc0201fe0:	6605                	lui	a2,0x1
ffffffffc0201fe2:	4581                	li	a1,0
ffffffffc0201fe4:	953e                	add	a0,a0,a5
ffffffffc0201fe6:	74e040ef          	jal	ra,ffffffffc0206734 <memset>
    return page - pages + nbase;
ffffffffc0201fea:	000b3683          	ld	a3,0(s6)
ffffffffc0201fee:	40d406b3          	sub	a3,s0,a3
ffffffffc0201ff2:	8699                	srai	a3,a3,0x6
ffffffffc0201ff4:	96d6                	add	a3,a3,s5
  asm volatile("sfence.vma");
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201ff6:	06aa                	slli	a3,a3,0xa
ffffffffc0201ff8:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201ffc:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201ffe:	77fd                	lui	a5,0xfffff
ffffffffc0202000:	068a                	slli	a3,a3,0x2
ffffffffc0202002:	0009b703          	ld	a4,0(s3)
ffffffffc0202006:	8efd                	and	a3,a3,a5
ffffffffc0202008:	00c6d793          	srli	a5,a3,0xc
ffffffffc020200c:	0ce7f163          	bleu	a4,a5,ffffffffc02020ce <get_pte+0x16e>
ffffffffc0202010:	000b5a97          	auipc	s5,0xb5
ffffffffc0202014:	be8a8a93          	addi	s5,s5,-1048 # ffffffffc02b6bf8 <va_pa_offset>
ffffffffc0202018:	000ab403          	ld	s0,0(s5)
ffffffffc020201c:	01595793          	srli	a5,s2,0x15
ffffffffc0202020:	1ff7f793          	andi	a5,a5,511
ffffffffc0202024:	96a2                	add	a3,a3,s0
ffffffffc0202026:	00379413          	slli	s0,a5,0x3
ffffffffc020202a:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) {
ffffffffc020202c:	6014                	ld	a3,0(s0)
ffffffffc020202e:	0016f793          	andi	a5,a3,1
ffffffffc0202032:	e3ad                	bnez	a5,ffffffffc0202094 <get_pte+0x134>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0202034:	080a0b63          	beqz	s4,ffffffffc02020ca <get_pte+0x16a>
ffffffffc0202038:	4505                	li	a0,1
ffffffffc020203a:	e19ff0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020203e:	84aa                	mv	s1,a0
ffffffffc0202040:	c549                	beqz	a0,ffffffffc02020ca <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0202042:	000b5b17          	auipc	s6,0xb5
ffffffffc0202046:	bc6b0b13          	addi	s6,s6,-1082 # ffffffffc02b6c08 <pages>
ffffffffc020204a:	000b3503          	ld	a0,0(s6)
    page->ref = val;
ffffffffc020204e:	4785                	li	a5,1
    return page - pages + nbase;
ffffffffc0202050:	00080a37          	lui	s4,0x80
ffffffffc0202054:	40a48533          	sub	a0,s1,a0
ffffffffc0202058:	8519                	srai	a0,a0,0x6
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020205a:	0009b703          	ld	a4,0(s3)
    page->ref = val;
ffffffffc020205e:	c09c                	sw	a5,0(s1)
ffffffffc0202060:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc0202062:	9552                	add	a0,a0,s4
ffffffffc0202064:	83b1                	srli	a5,a5,0xc
ffffffffc0202066:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202068:	0532                	slli	a0,a0,0xc
ffffffffc020206a:	08e7fa63          	bleu	a4,a5,ffffffffc02020fe <get_pte+0x19e>
ffffffffc020206e:	000ab783          	ld	a5,0(s5)
ffffffffc0202072:	6605                	lui	a2,0x1
ffffffffc0202074:	4581                	li	a1,0
ffffffffc0202076:	953e                	add	a0,a0,a5
ffffffffc0202078:	6bc040ef          	jal	ra,ffffffffc0206734 <memset>
    return page - pages + nbase;
ffffffffc020207c:	000b3683          	ld	a3,0(s6)
ffffffffc0202080:	40d486b3          	sub	a3,s1,a3
ffffffffc0202084:	8699                	srai	a3,a3,0x6
ffffffffc0202086:	96d2                	add	a3,a3,s4
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202088:	06aa                	slli	a3,a3,0xa
ffffffffc020208a:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc020208e:	e014                	sd	a3,0(s0)
ffffffffc0202090:	0009b703          	ld	a4,0(s3)
        }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202094:	068a                	slli	a3,a3,0x2
ffffffffc0202096:	757d                	lui	a0,0xfffff
ffffffffc0202098:	8ee9                	and	a3,a3,a0
ffffffffc020209a:	00c6d793          	srli	a5,a3,0xc
ffffffffc020209e:	04e7f463          	bleu	a4,a5,ffffffffc02020e6 <get_pte+0x186>
ffffffffc02020a2:	000ab503          	ld	a0,0(s5)
ffffffffc02020a6:	00c95793          	srli	a5,s2,0xc
ffffffffc02020aa:	1ff7f793          	andi	a5,a5,511
ffffffffc02020ae:	96aa                	add	a3,a3,a0
ffffffffc02020b0:	00379513          	slli	a0,a5,0x3
ffffffffc02020b4:	9536                	add	a0,a0,a3
}
ffffffffc02020b6:	70e2                	ld	ra,56(sp)
ffffffffc02020b8:	7442                	ld	s0,48(sp)
ffffffffc02020ba:	74a2                	ld	s1,40(sp)
ffffffffc02020bc:	7902                	ld	s2,32(sp)
ffffffffc02020be:	69e2                	ld	s3,24(sp)
ffffffffc02020c0:	6a42                	ld	s4,16(sp)
ffffffffc02020c2:	6aa2                	ld	s5,8(sp)
ffffffffc02020c4:	6b02                	ld	s6,0(sp)
ffffffffc02020c6:	6121                	addi	sp,sp,64
ffffffffc02020c8:	8082                	ret
            return NULL;
ffffffffc02020ca:	4501                	li	a0,0
ffffffffc02020cc:	b7ed                	j	ffffffffc02020b6 <get_pte+0x156>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02020ce:	00005617          	auipc	a2,0x5
ffffffffc02020d2:	41a60613          	addi	a2,a2,1050 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc02020d6:	0e300593          	li	a1,227
ffffffffc02020da:	00005517          	auipc	a0,0x5
ffffffffc02020de:	54650513          	addi	a0,a0,1350 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc02020e2:	ba2fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020e6:	00005617          	auipc	a2,0x5
ffffffffc02020ea:	40260613          	addi	a2,a2,1026 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc02020ee:	0ee00593          	li	a1,238
ffffffffc02020f2:	00005517          	auipc	a0,0x5
ffffffffc02020f6:	52e50513          	addi	a0,a0,1326 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc02020fa:	b8afe0ef          	jal	ra,ffffffffc0200484 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020fe:	86aa                	mv	a3,a0
ffffffffc0202100:	00005617          	auipc	a2,0x5
ffffffffc0202104:	3e860613          	addi	a2,a2,1000 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc0202108:	0eb00593          	li	a1,235
ffffffffc020210c:	00005517          	auipc	a0,0x5
ffffffffc0202110:	51450513          	addi	a0,a0,1300 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202114:	b70fe0ef          	jal	ra,ffffffffc0200484 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202118:	86aa                	mv	a3,a0
ffffffffc020211a:	00005617          	auipc	a2,0x5
ffffffffc020211e:	3ce60613          	addi	a2,a2,974 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc0202122:	0df00593          	li	a1,223
ffffffffc0202126:	00005517          	auipc	a0,0x5
ffffffffc020212a:	4fa50513          	addi	a0,a0,1274 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc020212e:	b56fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0202132 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0202132:	1141                	addi	sp,sp,-16
ffffffffc0202134:	e022                	sd	s0,0(sp)
ffffffffc0202136:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202138:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc020213a:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020213c:	e25ff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
    if (ptep_store != NULL) {
ffffffffc0202140:	c011                	beqz	s0,ffffffffc0202144 <get_page+0x12>
        *ptep_store = ptep;
ffffffffc0202142:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0202144:	c129                	beqz	a0,ffffffffc0202186 <get_page+0x54>
ffffffffc0202146:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202148:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc020214a:	0017f713          	andi	a4,a5,1
ffffffffc020214e:	e709                	bnez	a4,ffffffffc0202158 <get_page+0x26>
}
ffffffffc0202150:	60a2                	ld	ra,8(sp)
ffffffffc0202152:	6402                	ld	s0,0(sp)
ffffffffc0202154:	0141                	addi	sp,sp,16
ffffffffc0202156:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0202158:	000b5717          	auipc	a4,0xb5
ffffffffc020215c:	a4070713          	addi	a4,a4,-1472 # ffffffffc02b6b98 <npage>
ffffffffc0202160:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202162:	078a                	slli	a5,a5,0x2
ffffffffc0202164:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202166:	02e7f563          	bleu	a4,a5,ffffffffc0202190 <get_page+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc020216a:	000b5717          	auipc	a4,0xb5
ffffffffc020216e:	a9e70713          	addi	a4,a4,-1378 # ffffffffc02b6c08 <pages>
ffffffffc0202172:	6308                	ld	a0,0(a4)
ffffffffc0202174:	60a2                	ld	ra,8(sp)
ffffffffc0202176:	6402                	ld	s0,0(sp)
ffffffffc0202178:	fff80737          	lui	a4,0xfff80
ffffffffc020217c:	97ba                	add	a5,a5,a4
ffffffffc020217e:	079a                	slli	a5,a5,0x6
ffffffffc0202180:	953e                	add	a0,a0,a5
ffffffffc0202182:	0141                	addi	sp,sp,16
ffffffffc0202184:	8082                	ret
ffffffffc0202186:	60a2                	ld	ra,8(sp)
ffffffffc0202188:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc020218a:	4501                	li	a0,0
}
ffffffffc020218c:	0141                	addi	sp,sp,16
ffffffffc020218e:	8082                	ret
ffffffffc0202190:	ca7ff0ef          	jal	ra,ffffffffc0201e36 <pa2page.part.4>

ffffffffc0202194 <unmap_range>:
        tlb_invalidate(pgdir, la);  //(6) flush tlb
    }
}
//取消映射一段线性地址范围内的页表项
//在给定的页目录 pgdir 中，取消映射从线性地址 start 到线性地址 end 的连续内存区域
void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0202194:	711d                	addi	sp,sp,-96
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202196:	00c5e7b3          	or	a5,a1,a2
void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc020219a:	ec86                	sd	ra,88(sp)
ffffffffc020219c:	e8a2                	sd	s0,80(sp)
ffffffffc020219e:	e4a6                	sd	s1,72(sp)
ffffffffc02021a0:	e0ca                	sd	s2,64(sp)
ffffffffc02021a2:	fc4e                	sd	s3,56(sp)
ffffffffc02021a4:	f852                	sd	s4,48(sp)
ffffffffc02021a6:	f456                	sd	s5,40(sp)
ffffffffc02021a8:	f05a                	sd	s6,32(sp)
ffffffffc02021aa:	ec5e                	sd	s7,24(sp)
ffffffffc02021ac:	e862                	sd	s8,16(sp)
ffffffffc02021ae:	e466                	sd	s9,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021b0:	03479713          	slli	a4,a5,0x34
ffffffffc02021b4:	eb71                	bnez	a4,ffffffffc0202288 <unmap_range+0xf4>
    assert(USER_ACCESS(start, end));
ffffffffc02021b6:	002007b7          	lui	a5,0x200
ffffffffc02021ba:	842e                	mv	s0,a1
ffffffffc02021bc:	0af5e663          	bltu	a1,a5,ffffffffc0202268 <unmap_range+0xd4>
ffffffffc02021c0:	8932                	mv	s2,a2
ffffffffc02021c2:	0ac5f363          	bleu	a2,a1,ffffffffc0202268 <unmap_range+0xd4>
ffffffffc02021c6:	4785                	li	a5,1
ffffffffc02021c8:	07fe                	slli	a5,a5,0x1f
ffffffffc02021ca:	08c7ef63          	bltu	a5,a2,ffffffffc0202268 <unmap_range+0xd4>
ffffffffc02021ce:	89aa                	mv	s3,a0
        if (*ptep != 0) {
            //如果页表项存在，说明这段内存区域已经被映射，取消映射
            page_remove_pte(pgdir, start, ptep);
        }
        //继续处理下一个页,因为一个页表项pte映射至一个页，所以每次处理一个页
        start += PGSIZE;
ffffffffc02021d0:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc02021d2:	000b5c97          	auipc	s9,0xb5
ffffffffc02021d6:	9c6c8c93          	addi	s9,s9,-1594 # ffffffffc02b6b98 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02021da:	000b5c17          	auipc	s8,0xb5
ffffffffc02021de:	a2ec0c13          	addi	s8,s8,-1490 # ffffffffc02b6c08 <pages>
ffffffffc02021e2:	fff80bb7          	lui	s7,0xfff80
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02021e6:	00200b37          	lui	s6,0x200
ffffffffc02021ea:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02021ee:	4601                	li	a2,0
ffffffffc02021f0:	85a2                	mv	a1,s0
ffffffffc02021f2:	854e                	mv	a0,s3
ffffffffc02021f4:	d6dff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc02021f8:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc02021fa:	cd21                	beqz	a0,ffffffffc0202252 <unmap_range+0xbe>
        if (*ptep != 0) {
ffffffffc02021fc:	611c                	ld	a5,0(a0)
ffffffffc02021fe:	e38d                	bnez	a5,ffffffffc0202220 <unmap_range+0x8c>
        start += PGSIZE;
ffffffffc0202200:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202202:	ff2466e3          	bltu	s0,s2,ffffffffc02021ee <unmap_range+0x5a>
}
ffffffffc0202206:	60e6                	ld	ra,88(sp)
ffffffffc0202208:	6446                	ld	s0,80(sp)
ffffffffc020220a:	64a6                	ld	s1,72(sp)
ffffffffc020220c:	6906                	ld	s2,64(sp)
ffffffffc020220e:	79e2                	ld	s3,56(sp)
ffffffffc0202210:	7a42                	ld	s4,48(sp)
ffffffffc0202212:	7aa2                	ld	s5,40(sp)
ffffffffc0202214:	7b02                	ld	s6,32(sp)
ffffffffc0202216:	6be2                	ld	s7,24(sp)
ffffffffc0202218:	6c42                	ld	s8,16(sp)
ffffffffc020221a:	6ca2                	ld	s9,8(sp)
ffffffffc020221c:	6125                	addi	sp,sp,96
ffffffffc020221e:	8082                	ret
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0202220:	0017f713          	andi	a4,a5,1
ffffffffc0202224:	df71                	beqz	a4,ffffffffc0202200 <unmap_range+0x6c>
    if (PPN(pa) >= npage) {
ffffffffc0202226:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020222a:	078a                	slli	a5,a5,0x2
ffffffffc020222c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020222e:	06e7fd63          	bleu	a4,a5,ffffffffc02022a8 <unmap_range+0x114>
    return &pages[PPN(pa) - nbase];
ffffffffc0202232:	000c3503          	ld	a0,0(s8)
ffffffffc0202236:	97de                	add	a5,a5,s7
ffffffffc0202238:	079a                	slli	a5,a5,0x6
ffffffffc020223a:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020223c:	411c                	lw	a5,0(a0)
ffffffffc020223e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202242:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202244:	cf11                	beqz	a4,ffffffffc0202260 <unmap_range+0xcc>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0202246:	0004b023          	sd	zero,0(s1)
}

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020224a:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc020224e:	9452                	add	s0,s0,s4
ffffffffc0202250:	bf4d                	j	ffffffffc0202202 <unmap_range+0x6e>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202252:	945a                	add	s0,s0,s6
ffffffffc0202254:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc0202258:	d45d                	beqz	s0,ffffffffc0202206 <unmap_range+0x72>
ffffffffc020225a:	f9246ae3          	bltu	s0,s2,ffffffffc02021ee <unmap_range+0x5a>
ffffffffc020225e:	b765                	j	ffffffffc0202206 <unmap_range+0x72>
            free_page(page);
ffffffffc0202260:	4585                	li	a1,1
ffffffffc0202262:	c79ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
ffffffffc0202266:	b7c5                	j	ffffffffc0202246 <unmap_range+0xb2>
    assert(USER_ACCESS(start, end));
ffffffffc0202268:	00006697          	auipc	a3,0x6
ffffffffc020226c:	96068693          	addi	a3,a3,-1696 # ffffffffc0207bc8 <default_pmm_manager+0x730>
ffffffffc0202270:	00005617          	auipc	a2,0x5
ffffffffc0202274:	ae060613          	addi	a2,a2,-1312 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202278:	11200593          	li	a1,274
ffffffffc020227c:	00005517          	auipc	a0,0x5
ffffffffc0202280:	3a450513          	addi	a0,a0,932 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202284:	a00fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202288:	00006697          	auipc	a3,0x6
ffffffffc020228c:	91068693          	addi	a3,a3,-1776 # ffffffffc0207b98 <default_pmm_manager+0x700>
ffffffffc0202290:	00005617          	auipc	a2,0x5
ffffffffc0202294:	ac060613          	addi	a2,a2,-1344 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202298:	11100593          	li	a1,273
ffffffffc020229c:	00005517          	auipc	a0,0x5
ffffffffc02022a0:	38450513          	addi	a0,a0,900 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc02022a4:	9e0fe0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc02022a8:	b8fff0ef          	jal	ra,ffffffffc0201e36 <pa2page.part.4>

ffffffffc02022ac <exit_range>:
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc02022ac:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022ae:	00c5e7b3          	or	a5,a1,a2
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc02022b2:	fc86                	sd	ra,120(sp)
ffffffffc02022b4:	f8a2                	sd	s0,112(sp)
ffffffffc02022b6:	f4a6                	sd	s1,104(sp)
ffffffffc02022b8:	f0ca                	sd	s2,96(sp)
ffffffffc02022ba:	ecce                	sd	s3,88(sp)
ffffffffc02022bc:	e8d2                	sd	s4,80(sp)
ffffffffc02022be:	e4d6                	sd	s5,72(sp)
ffffffffc02022c0:	e0da                	sd	s6,64(sp)
ffffffffc02022c2:	fc5e                	sd	s7,56(sp)
ffffffffc02022c4:	f862                	sd	s8,48(sp)
ffffffffc02022c6:	f466                	sd	s9,40(sp)
ffffffffc02022c8:	f06a                	sd	s10,32(sp)
ffffffffc02022ca:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022cc:	03479713          	slli	a4,a5,0x34
ffffffffc02022d0:	1c071163          	bnez	a4,ffffffffc0202492 <exit_range+0x1e6>
    assert(USER_ACCESS(start, end));
ffffffffc02022d4:	002007b7          	lui	a5,0x200
ffffffffc02022d8:	20f5e563          	bltu	a1,a5,ffffffffc02024e2 <exit_range+0x236>
ffffffffc02022dc:	8b32                	mv	s6,a2
ffffffffc02022de:	20c5f263          	bleu	a2,a1,ffffffffc02024e2 <exit_range+0x236>
ffffffffc02022e2:	4785                	li	a5,1
ffffffffc02022e4:	07fe                	slli	a5,a5,0x1f
ffffffffc02022e6:	1ec7ee63          	bltu	a5,a2,ffffffffc02024e2 <exit_range+0x236>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02022ea:	c00009b7          	lui	s3,0xc0000
ffffffffc02022ee:	400007b7          	lui	a5,0x40000
ffffffffc02022f2:	0135f9b3          	and	s3,a1,s3
ffffffffc02022f6:	99be                	add	s3,s3,a5
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02022f8:	c0000337          	lui	t1,0xc0000
ffffffffc02022fc:	00698933          	add	s2,s3,t1
ffffffffc0202300:	01e95913          	srli	s2,s2,0x1e
ffffffffc0202304:	1ff97913          	andi	s2,s2,511
ffffffffc0202308:	8e2a                	mv	t3,a0
ffffffffc020230a:	090e                	slli	s2,s2,0x3
ffffffffc020230c:	9972                	add	s2,s2,t3
ffffffffc020230e:	00093b83          	ld	s7,0(s2)
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202312:	ffe004b7          	lui	s1,0xffe00
    return KADDR(page2pa(page));
ffffffffc0202316:	5dfd                	li	s11,-1
        if (pde1&PTE_V){
ffffffffc0202318:	001bf793          	andi	a5,s7,1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020231c:	8ced                	and	s1,s1,a1
    if (PPN(pa) >= npage) {
ffffffffc020231e:	000b5d17          	auipc	s10,0xb5
ffffffffc0202322:	87ad0d13          	addi	s10,s10,-1926 # ffffffffc02b6b98 <npage>
    return KADDR(page2pa(page));
ffffffffc0202326:	00cddd93          	srli	s11,s11,0xc
ffffffffc020232a:	000b5717          	auipc	a4,0xb5
ffffffffc020232e:	8ce70713          	addi	a4,a4,-1842 # ffffffffc02b6bf8 <va_pa_offset>
    return &pages[PPN(pa) - nbase];
ffffffffc0202332:	000b5e97          	auipc	t4,0xb5
ffffffffc0202336:	8d6e8e93          	addi	t4,t4,-1834 # ffffffffc02b6c08 <pages>
        if (pde1&PTE_V){
ffffffffc020233a:	e79d                	bnez	a5,ffffffffc0202368 <exit_range+0xbc>
    } while (d1start != 0 && d1start < end);
ffffffffc020233c:	12098963          	beqz	s3,ffffffffc020246e <exit_range+0x1c2>
ffffffffc0202340:	400007b7          	lui	a5,0x40000
ffffffffc0202344:	84ce                	mv	s1,s3
ffffffffc0202346:	97ce                	add	a5,a5,s3
ffffffffc0202348:	1369f363          	bleu	s6,s3,ffffffffc020246e <exit_range+0x1c2>
ffffffffc020234c:	89be                	mv	s3,a5
        pde1 = pgdir[PDX1(d1start)];
ffffffffc020234e:	00698933          	add	s2,s3,t1
ffffffffc0202352:	01e95913          	srli	s2,s2,0x1e
ffffffffc0202356:	1ff97913          	andi	s2,s2,511
ffffffffc020235a:	090e                	slli	s2,s2,0x3
ffffffffc020235c:	9972                	add	s2,s2,t3
ffffffffc020235e:	00093b83          	ld	s7,0(s2)
        if (pde1&PTE_V){
ffffffffc0202362:	001bf793          	andi	a5,s7,1
ffffffffc0202366:	dbf9                	beqz	a5,ffffffffc020233c <exit_range+0x90>
    if (PPN(pa) >= npage) {
ffffffffc0202368:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020236c:	0b8a                	slli	s7,s7,0x2
ffffffffc020236e:	00cbdb93          	srli	s7,s7,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202372:	14fbfc63          	bleu	a5,s7,ffffffffc02024ca <exit_range+0x21e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202376:	fff80ab7          	lui	s5,0xfff80
ffffffffc020237a:	9ade                	add	s5,s5,s7
    return page - pages + nbase;
ffffffffc020237c:	000806b7          	lui	a3,0x80
ffffffffc0202380:	96d6                	add	a3,a3,s5
ffffffffc0202382:	006a9593          	slli	a1,s5,0x6
    return KADDR(page2pa(page));
ffffffffc0202386:	01b6f633          	and	a2,a3,s11
    return page - pages + nbase;
ffffffffc020238a:	e42e                	sd	a1,8(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc020238c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020238e:	12f67263          	bleu	a5,a2,ffffffffc02024b2 <exit_range+0x206>
ffffffffc0202392:	00073a03          	ld	s4,0(a4)
            free_pd0 = 1;
ffffffffc0202396:	4c85                	li	s9,1
    return &pages[PPN(pa) - nbase];
ffffffffc0202398:	fff808b7          	lui	a7,0xfff80
    return KADDR(page2pa(page));
ffffffffc020239c:	9a36                	add	s4,s4,a3
    return page - pages + nbase;
ffffffffc020239e:	00080837          	lui	a6,0x80
ffffffffc02023a2:	6a85                	lui	s5,0x1
                d0start += PTSIZE;
ffffffffc02023a4:	00200c37          	lui	s8,0x200
ffffffffc02023a8:	a801                	j	ffffffffc02023b8 <exit_range+0x10c>
                    free_pd0 = 0;
ffffffffc02023aa:	4c81                	li	s9,0
                d0start += PTSIZE;
ffffffffc02023ac:	94e2                	add	s1,s1,s8
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc02023ae:	c0d9                	beqz	s1,ffffffffc0202434 <exit_range+0x188>
ffffffffc02023b0:	0934f263          	bleu	s3,s1,ffffffffc0202434 <exit_range+0x188>
ffffffffc02023b4:	0d64fc63          	bleu	s6,s1,ffffffffc020248c <exit_range+0x1e0>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02023b8:	0154d413          	srli	s0,s1,0x15
ffffffffc02023bc:	1ff47413          	andi	s0,s0,511
ffffffffc02023c0:	040e                	slli	s0,s0,0x3
ffffffffc02023c2:	9452                	add	s0,s0,s4
ffffffffc02023c4:	601c                	ld	a5,0(s0)
                if (pde0&PTE_V) {
ffffffffc02023c6:	0017f693          	andi	a3,a5,1
ffffffffc02023ca:	d2e5                	beqz	a3,ffffffffc02023aa <exit_range+0xfe>
    if (PPN(pa) >= npage) {
ffffffffc02023cc:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023d0:	00279513          	slli	a0,a5,0x2
ffffffffc02023d4:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc02023d6:	0eb57a63          	bleu	a1,a0,ffffffffc02024ca <exit_range+0x21e>
    return &pages[PPN(pa) - nbase];
ffffffffc02023da:	9546                	add	a0,a0,a7
    return page - pages + nbase;
ffffffffc02023dc:	010506b3          	add	a3,a0,a6
    return KADDR(page2pa(page));
ffffffffc02023e0:	01b6f7b3          	and	a5,a3,s11
    return page - pages + nbase;
ffffffffc02023e4:	051a                	slli	a0,a0,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02023e6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02023e8:	0cb7f563          	bleu	a1,a5,ffffffffc02024b2 <exit_range+0x206>
ffffffffc02023ec:	631c                	ld	a5,0(a4)
ffffffffc02023ee:	96be                	add	a3,a3,a5
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc02023f0:	015685b3          	add	a1,a3,s5
                        if (pt[i]&PTE_V){
ffffffffc02023f4:	629c                	ld	a5,0(a3)
ffffffffc02023f6:	8b85                	andi	a5,a5,1
ffffffffc02023f8:	fbd5                	bnez	a5,ffffffffc02023ac <exit_range+0x100>
ffffffffc02023fa:	06a1                	addi	a3,a3,8
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc02023fc:	fed59ce3          	bne	a1,a3,ffffffffc02023f4 <exit_range+0x148>
    return &pages[PPN(pa) - nbase];
ffffffffc0202400:	000eb783          	ld	a5,0(t4)
                        free_page(pde2page(pde0));
ffffffffc0202404:	4585                	li	a1,1
ffffffffc0202406:	e072                	sd	t3,0(sp)
ffffffffc0202408:	953e                	add	a0,a0,a5
ffffffffc020240a:	ad1ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
                d0start += PTSIZE;
ffffffffc020240e:	94e2                	add	s1,s1,s8
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202410:	00043023          	sd	zero,0(s0)
ffffffffc0202414:	000b4e97          	auipc	t4,0xb4
ffffffffc0202418:	7f4e8e93          	addi	t4,t4,2036 # ffffffffc02b6c08 <pages>
ffffffffc020241c:	6e02                	ld	t3,0(sp)
ffffffffc020241e:	c0000337          	lui	t1,0xc0000
ffffffffc0202422:	fff808b7          	lui	a7,0xfff80
ffffffffc0202426:	00080837          	lui	a6,0x80
ffffffffc020242a:	000b4717          	auipc	a4,0xb4
ffffffffc020242e:	7ce70713          	addi	a4,a4,1998 # ffffffffc02b6bf8 <va_pa_offset>
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc0202432:	fcbd                	bnez	s1,ffffffffc02023b0 <exit_range+0x104>
            if (free_pd0) {
ffffffffc0202434:	f00c84e3          	beqz	s9,ffffffffc020233c <exit_range+0x90>
    if (PPN(pa) >= npage) {
ffffffffc0202438:	000d3783          	ld	a5,0(s10)
ffffffffc020243c:	e072                	sd	t3,0(sp)
ffffffffc020243e:	08fbf663          	bleu	a5,s7,ffffffffc02024ca <exit_range+0x21e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202442:	000eb503          	ld	a0,0(t4)
                free_page(pde2page(pde1));
ffffffffc0202446:	67a2                	ld	a5,8(sp)
ffffffffc0202448:	4585                	li	a1,1
ffffffffc020244a:	953e                	add	a0,a0,a5
ffffffffc020244c:	a8fff0ef          	jal	ra,ffffffffc0201eda <free_pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202450:	00093023          	sd	zero,0(s2)
ffffffffc0202454:	000b4717          	auipc	a4,0xb4
ffffffffc0202458:	7a470713          	addi	a4,a4,1956 # ffffffffc02b6bf8 <va_pa_offset>
ffffffffc020245c:	c0000337          	lui	t1,0xc0000
ffffffffc0202460:	6e02                	ld	t3,0(sp)
ffffffffc0202462:	000b4e97          	auipc	t4,0xb4
ffffffffc0202466:	7a6e8e93          	addi	t4,t4,1958 # ffffffffc02b6c08 <pages>
    } while (d1start != 0 && d1start < end);
ffffffffc020246a:	ec099be3          	bnez	s3,ffffffffc0202340 <exit_range+0x94>
}
ffffffffc020246e:	70e6                	ld	ra,120(sp)
ffffffffc0202470:	7446                	ld	s0,112(sp)
ffffffffc0202472:	74a6                	ld	s1,104(sp)
ffffffffc0202474:	7906                	ld	s2,96(sp)
ffffffffc0202476:	69e6                	ld	s3,88(sp)
ffffffffc0202478:	6a46                	ld	s4,80(sp)
ffffffffc020247a:	6aa6                	ld	s5,72(sp)
ffffffffc020247c:	6b06                	ld	s6,64(sp)
ffffffffc020247e:	7be2                	ld	s7,56(sp)
ffffffffc0202480:	7c42                	ld	s8,48(sp)
ffffffffc0202482:	7ca2                	ld	s9,40(sp)
ffffffffc0202484:	7d02                	ld	s10,32(sp)
ffffffffc0202486:	6de2                	ld	s11,24(sp)
ffffffffc0202488:	6109                	addi	sp,sp,128
ffffffffc020248a:	8082                	ret
            if (free_pd0) {
ffffffffc020248c:	ea0c8ae3          	beqz	s9,ffffffffc0202340 <exit_range+0x94>
ffffffffc0202490:	b765                	j	ffffffffc0202438 <exit_range+0x18c>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202492:	00005697          	auipc	a3,0x5
ffffffffc0202496:	70668693          	addi	a3,a3,1798 # ffffffffc0207b98 <default_pmm_manager+0x700>
ffffffffc020249a:	00005617          	auipc	a2,0x5
ffffffffc020249e:	8b660613          	addi	a2,a2,-1866 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02024a2:	12800593          	li	a1,296
ffffffffc02024a6:	00005517          	auipc	a0,0x5
ffffffffc02024aa:	17a50513          	addi	a0,a0,378 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc02024ae:	fd7fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc02024b2:	00005617          	auipc	a2,0x5
ffffffffc02024b6:	03660613          	addi	a2,a2,54 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc02024ba:	06900593          	li	a1,105
ffffffffc02024be:	00005517          	auipc	a0,0x5
ffffffffc02024c2:	05250513          	addi	a0,a0,82 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc02024c6:	fbffd0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02024ca:	00005617          	auipc	a2,0x5
ffffffffc02024ce:	07e60613          	addi	a2,a2,126 # ffffffffc0207548 <default_pmm_manager+0xb0>
ffffffffc02024d2:	06200593          	li	a1,98
ffffffffc02024d6:	00005517          	auipc	a0,0x5
ffffffffc02024da:	03a50513          	addi	a0,a0,58 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc02024de:	fa7fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02024e2:	00005697          	auipc	a3,0x5
ffffffffc02024e6:	6e668693          	addi	a3,a3,1766 # ffffffffc0207bc8 <default_pmm_manager+0x730>
ffffffffc02024ea:	00005617          	auipc	a2,0x5
ffffffffc02024ee:	86660613          	addi	a2,a2,-1946 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02024f2:	12900593          	li	a1,297
ffffffffc02024f6:	00005517          	auipc	a0,0x5
ffffffffc02024fa:	12a50513          	addi	a0,a0,298 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc02024fe:	f87fd0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0202502 <page_remove>:
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0202502:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202504:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0202506:	e426                	sd	s1,8(sp)
ffffffffc0202508:	ec06                	sd	ra,24(sp)
ffffffffc020250a:	e822                	sd	s0,16(sp)
ffffffffc020250c:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020250e:	a53ff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
    if (ptep != NULL) {
ffffffffc0202512:	c511                	beqz	a0,ffffffffc020251e <page_remove+0x1c>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0202514:	611c                	ld	a5,0(a0)
ffffffffc0202516:	842a                	mv	s0,a0
ffffffffc0202518:	0017f713          	andi	a4,a5,1
ffffffffc020251c:	e711                	bnez	a4,ffffffffc0202528 <page_remove+0x26>
}
ffffffffc020251e:	60e2                	ld	ra,24(sp)
ffffffffc0202520:	6442                	ld	s0,16(sp)
ffffffffc0202522:	64a2                	ld	s1,8(sp)
ffffffffc0202524:	6105                	addi	sp,sp,32
ffffffffc0202526:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0202528:	000b4717          	auipc	a4,0xb4
ffffffffc020252c:	67070713          	addi	a4,a4,1648 # ffffffffc02b6b98 <npage>
ffffffffc0202530:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202532:	078a                	slli	a5,a5,0x2
ffffffffc0202534:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202536:	02e7fe63          	bleu	a4,a5,ffffffffc0202572 <page_remove+0x70>
    return &pages[PPN(pa) - nbase];
ffffffffc020253a:	000b4717          	auipc	a4,0xb4
ffffffffc020253e:	6ce70713          	addi	a4,a4,1742 # ffffffffc02b6c08 <pages>
ffffffffc0202542:	6308                	ld	a0,0(a4)
ffffffffc0202544:	fff80737          	lui	a4,0xfff80
ffffffffc0202548:	97ba                	add	a5,a5,a4
ffffffffc020254a:	079a                	slli	a5,a5,0x6
ffffffffc020254c:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020254e:	411c                	lw	a5,0(a0)
ffffffffc0202550:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202554:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202556:	cb11                	beqz	a4,ffffffffc020256a <page_remove+0x68>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0202558:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020255c:	12048073          	sfence.vma	s1
}
ffffffffc0202560:	60e2                	ld	ra,24(sp)
ffffffffc0202562:	6442                	ld	s0,16(sp)
ffffffffc0202564:	64a2                	ld	s1,8(sp)
ffffffffc0202566:	6105                	addi	sp,sp,32
ffffffffc0202568:	8082                	ret
            free_page(page);
ffffffffc020256a:	4585                	li	a1,1
ffffffffc020256c:	96fff0ef          	jal	ra,ffffffffc0201eda <free_pages>
ffffffffc0202570:	b7e5                	j	ffffffffc0202558 <page_remove+0x56>
ffffffffc0202572:	8c5ff0ef          	jal	ra,ffffffffc0201e36 <pa2page.part.4>

ffffffffc0202576 <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202576:	7179                	addi	sp,sp,-48
ffffffffc0202578:	e44e                	sd	s3,8(sp)
ffffffffc020257a:	89b2                	mv	s3,a2
ffffffffc020257c:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020257e:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202580:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202582:	85ce                	mv	a1,s3
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202584:	ec26                	sd	s1,24(sp)
ffffffffc0202586:	f406                	sd	ra,40(sp)
ffffffffc0202588:	e84a                	sd	s2,16(sp)
ffffffffc020258a:	e052                	sd	s4,0(sp)
ffffffffc020258c:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020258e:	9d3ff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
    if (ptep == NULL) {
ffffffffc0202592:	cd49                	beqz	a0,ffffffffc020262c <page_insert+0xb6>
    page->ref += 1;
ffffffffc0202594:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) {  //如果PTE_V，说明原先存在映射，不然应该全为0，所以现在先删除原先的映射
ffffffffc0202596:	611c                	ld	a5,0(a0)
ffffffffc0202598:	892a                	mv	s2,a0
ffffffffc020259a:	0016871b          	addiw	a4,a3,1
ffffffffc020259e:	c018                	sw	a4,0(s0)
ffffffffc02025a0:	0017f713          	andi	a4,a5,1
ffffffffc02025a4:	ef05                	bnez	a4,ffffffffc02025dc <page_insert+0x66>
ffffffffc02025a6:	000b4797          	auipc	a5,0xb4
ffffffffc02025aa:	66278793          	addi	a5,a5,1634 # ffffffffc02b6c08 <pages>
ffffffffc02025ae:	6398                	ld	a4,0(a5)
    return page - pages + nbase;
ffffffffc02025b0:	8c19                	sub	s0,s0,a4
ffffffffc02025b2:	000806b7          	lui	a3,0x80
ffffffffc02025b6:	8419                	srai	s0,s0,0x6
ffffffffc02025b8:	9436                	add	s0,s0,a3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02025ba:	042a                	slli	s0,s0,0xa
ffffffffc02025bc:	8c45                	or	s0,s0,s1
ffffffffc02025be:	00146413          	ori	s0,s0,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm); //有效位是每个pte自带的位，perm是权限位
ffffffffc02025c2:	00893023          	sd	s0,0(s2)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025c6:	12098073          	sfence.vma	s3
    return 0;
ffffffffc02025ca:	4501                	li	a0,0
}
ffffffffc02025cc:	70a2                	ld	ra,40(sp)
ffffffffc02025ce:	7402                	ld	s0,32(sp)
ffffffffc02025d0:	64e2                	ld	s1,24(sp)
ffffffffc02025d2:	6942                	ld	s2,16(sp)
ffffffffc02025d4:	69a2                	ld	s3,8(sp)
ffffffffc02025d6:	6a02                	ld	s4,0(sp)
ffffffffc02025d8:	6145                	addi	sp,sp,48
ffffffffc02025da:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc02025dc:	000b4717          	auipc	a4,0xb4
ffffffffc02025e0:	5bc70713          	addi	a4,a4,1468 # ffffffffc02b6b98 <npage>
ffffffffc02025e4:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc02025e6:	078a                	slli	a5,a5,0x2
ffffffffc02025e8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02025ea:	04e7f363          	bleu	a4,a5,ffffffffc0202630 <page_insert+0xba>
    return &pages[PPN(pa) - nbase];
ffffffffc02025ee:	000b4a17          	auipc	s4,0xb4
ffffffffc02025f2:	61aa0a13          	addi	s4,s4,1562 # ffffffffc02b6c08 <pages>
ffffffffc02025f6:	000a3703          	ld	a4,0(s4)
ffffffffc02025fa:	fff80537          	lui	a0,0xfff80
ffffffffc02025fe:	953e                	add	a0,a0,a5
ffffffffc0202600:	051a                	slli	a0,a0,0x6
ffffffffc0202602:	953a                	add	a0,a0,a4
        if (p == page) {//如果原先映射的物理页面就是page，那么直接更新页表项
ffffffffc0202604:	00a40a63          	beq	s0,a0,ffffffffc0202618 <page_insert+0xa2>
    page->ref -= 1;
ffffffffc0202608:	411c                	lw	a5,0(a0)
ffffffffc020260a:	fff7869b          	addiw	a3,a5,-1
ffffffffc020260e:	c114                	sw	a3,0(a0)
        if (page_ref(page) ==
ffffffffc0202610:	c691                	beqz	a3,ffffffffc020261c <page_insert+0xa6>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202612:	12098073          	sfence.vma	s3
ffffffffc0202616:	bf69                	j	ffffffffc02025b0 <page_insert+0x3a>
ffffffffc0202618:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc020261a:	bf59                	j	ffffffffc02025b0 <page_insert+0x3a>
            free_page(page);
ffffffffc020261c:	4585                	li	a1,1
ffffffffc020261e:	8bdff0ef          	jal	ra,ffffffffc0201eda <free_pages>
ffffffffc0202622:	000a3703          	ld	a4,0(s4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202626:	12098073          	sfence.vma	s3
ffffffffc020262a:	b759                	j	ffffffffc02025b0 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc020262c:	5571                	li	a0,-4
ffffffffc020262e:	bf79                	j	ffffffffc02025cc <page_insert+0x56>
ffffffffc0202630:	807ff0ef          	jal	ra,ffffffffc0201e36 <pa2page.part.4>

ffffffffc0202634 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202634:	00005797          	auipc	a5,0x5
ffffffffc0202638:	e6478793          	addi	a5,a5,-412 # ffffffffc0207498 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020263c:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc020263e:	715d                	addi	sp,sp,-80
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202640:	00005517          	auipc	a0,0x5
ffffffffc0202644:	00850513          	addi	a0,a0,8 # ffffffffc0207648 <default_pmm_manager+0x1b0>
void pmm_init(void) {
ffffffffc0202648:	e486                	sd	ra,72(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020264a:	000b4717          	auipc	a4,0xb4
ffffffffc020264e:	5af73323          	sd	a5,1446(a4) # ffffffffc02b6bf0 <pmm_manager>
void pmm_init(void) {
ffffffffc0202652:	e0a2                	sd	s0,64(sp)
ffffffffc0202654:	fc26                	sd	s1,56(sp)
ffffffffc0202656:	f84a                	sd	s2,48(sp)
ffffffffc0202658:	f44e                	sd	s3,40(sp)
ffffffffc020265a:	f052                	sd	s4,32(sp)
ffffffffc020265c:	ec56                	sd	s5,24(sp)
ffffffffc020265e:	e85a                	sd	s6,16(sp)
ffffffffc0202660:	e45e                	sd	s7,8(sp)
ffffffffc0202662:	e062                	sd	s8,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202664:	000b4417          	auipc	s0,0xb4
ffffffffc0202668:	58c40413          	addi	s0,s0,1420 # ffffffffc02b6bf0 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020266c:	b23fd0ef          	jal	ra,ffffffffc020018e <cprintf>
    pmm_manager->init();
ffffffffc0202670:	601c                	ld	a5,0(s0)
ffffffffc0202672:	000b4497          	auipc	s1,0xb4
ffffffffc0202676:	52648493          	addi	s1,s1,1318 # ffffffffc02b6b98 <npage>
ffffffffc020267a:	000b4917          	auipc	s2,0xb4
ffffffffc020267e:	58e90913          	addi	s2,s2,1422 # ffffffffc02b6c08 <pages>
ffffffffc0202682:	679c                	ld	a5,8(a5)
ffffffffc0202684:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0202686:	57f5                	li	a5,-3
ffffffffc0202688:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc020268a:	00005517          	auipc	a0,0x5
ffffffffc020268e:	fd650513          	addi	a0,a0,-42 # ffffffffc0207660 <default_pmm_manager+0x1c8>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0202692:	000b4717          	auipc	a4,0xb4
ffffffffc0202696:	56f73323          	sd	a5,1382(a4) # ffffffffc02b6bf8 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc020269a:	af5fd0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc020269e:	46c5                	li	a3,17
ffffffffc02026a0:	06ee                	slli	a3,a3,0x1b
ffffffffc02026a2:	40100613          	li	a2,1025
ffffffffc02026a6:	16fd                	addi	a3,a3,-1
ffffffffc02026a8:	0656                	slli	a2,a2,0x15
ffffffffc02026aa:	07e005b7          	lui	a1,0x7e00
ffffffffc02026ae:	00005517          	auipc	a0,0x5
ffffffffc02026b2:	fca50513          	addi	a0,a0,-54 # ffffffffc0207678 <default_pmm_manager+0x1e0>
ffffffffc02026b6:	ad9fd0ef          	jal	ra,ffffffffc020018e <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026ba:	777d                	lui	a4,0xfffff
ffffffffc02026bc:	000b5797          	auipc	a5,0xb5
ffffffffc02026c0:	64378793          	addi	a5,a5,1603 # ffffffffc02b7cff <end+0xfff>
ffffffffc02026c4:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc02026c6:	00088737          	lui	a4,0x88
ffffffffc02026ca:	000b4697          	auipc	a3,0xb4
ffffffffc02026ce:	4ce6b723          	sd	a4,1230(a3) # ffffffffc02b6b98 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026d2:	000b4717          	auipc	a4,0xb4
ffffffffc02026d6:	52f73b23          	sd	a5,1334(a4) # ffffffffc02b6c08 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02026da:	4701                	li	a4,0
ffffffffc02026dc:	4685                	li	a3,1
ffffffffc02026de:	fff80837          	lui	a6,0xfff80
ffffffffc02026e2:	a019                	j	ffffffffc02026e8 <pmm_init+0xb4>
ffffffffc02026e4:	00093783          	ld	a5,0(s2)
        SetPageReserved(pages + i);
ffffffffc02026e8:	00671613          	slli	a2,a4,0x6
ffffffffc02026ec:	97b2                	add	a5,a5,a2
ffffffffc02026ee:	07a1                	addi	a5,a5,8
ffffffffc02026f0:	40d7b02f          	amoor.d	zero,a3,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02026f4:	6090                	ld	a2,0(s1)
ffffffffc02026f6:	0705                	addi	a4,a4,1
ffffffffc02026f8:	010607b3          	add	a5,a2,a6
ffffffffc02026fc:	fef764e3          	bltu	a4,a5,ffffffffc02026e4 <pmm_init+0xb0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202700:	00093503          	ld	a0,0(s2)
ffffffffc0202704:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202708:	00661693          	slli	a3,a2,0x6
ffffffffc020270c:	97aa                	add	a5,a5,a0
ffffffffc020270e:	96be                	add	a3,a3,a5
ffffffffc0202710:	c02007b7          	lui	a5,0xc0200
ffffffffc0202714:	7af6ed63          	bltu	a3,a5,ffffffffc0202ece <pmm_init+0x89a>
ffffffffc0202718:	000b4997          	auipc	s3,0xb4
ffffffffc020271c:	4e098993          	addi	s3,s3,1248 # ffffffffc02b6bf8 <va_pa_offset>
ffffffffc0202720:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) {
ffffffffc0202724:	47c5                	li	a5,17
ffffffffc0202726:	07ee                	slli	a5,a5,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202728:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) {
ffffffffc020272a:	02f6f763          	bleu	a5,a3,ffffffffc0202758 <pmm_init+0x124>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020272e:	6585                	lui	a1,0x1
ffffffffc0202730:	15fd                	addi	a1,a1,-1
ffffffffc0202732:	96ae                	add	a3,a3,a1
    if (PPN(pa) >= npage) {
ffffffffc0202734:	00c6d713          	srli	a4,a3,0xc
ffffffffc0202738:	48c77a63          	bleu	a2,a4,ffffffffc0202bcc <pmm_init+0x598>
    pmm_manager->init_memmap(base, n);
ffffffffc020273c:	6010                	ld	a2,0(s0)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020273e:	75fd                	lui	a1,0xfffff
ffffffffc0202740:	8eed                	and	a3,a3,a1
    return &pages[PPN(pa) - nbase];
ffffffffc0202742:	9742                	add	a4,a4,a6
    pmm_manager->init_memmap(base, n);
ffffffffc0202744:	6a10                	ld	a2,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202746:	40d786b3          	sub	a3,a5,a3
ffffffffc020274a:	071a                	slli	a4,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc020274c:	00c6d593          	srli	a1,a3,0xc
ffffffffc0202750:	953a                	add	a0,a0,a4
ffffffffc0202752:	9602                	jalr	a2
ffffffffc0202754:	0009b583          	ld	a1,0(s3)
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0202758:	00005517          	auipc	a0,0x5
ffffffffc020275c:	f4850513          	addi	a0,a0,-184 # ffffffffc02076a0 <default_pmm_manager+0x208>
ffffffffc0202760:	a2ffd0ef          	jal	ra,ffffffffc020018e <cprintf>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0202764:	601c                	ld	a5,0(s0)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0202766:	000b4417          	auipc	s0,0xb4
ffffffffc020276a:	42a40413          	addi	s0,s0,1066 # ffffffffc02b6b90 <boot_pgdir>
    pmm_manager->check();
ffffffffc020276e:	7b9c                	ld	a5,48(a5)
ffffffffc0202770:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202772:	00005517          	auipc	a0,0x5
ffffffffc0202776:	f4650513          	addi	a0,a0,-186 # ffffffffc02076b8 <default_pmm_manager+0x220>
ffffffffc020277a:	a15fd0ef          	jal	ra,ffffffffc020018e <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc020277e:	00009697          	auipc	a3,0x9
ffffffffc0202782:	88268693          	addi	a3,a3,-1918 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc0202786:	000b4797          	auipc	a5,0xb4
ffffffffc020278a:	40d7b523          	sd	a3,1034(a5) # ffffffffc02b6b90 <boot_pgdir>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc020278e:	c02007b7          	lui	a5,0xc0200
ffffffffc0202792:	10f6eae3          	bltu	a3,a5,ffffffffc02030a6 <pmm_init+0xa72>
ffffffffc0202796:	0009b783          	ld	a5,0(s3)
ffffffffc020279a:	8e9d                	sub	a3,a3,a5
ffffffffc020279c:	000b4797          	auipc	a5,0xb4
ffffffffc02027a0:	46d7b223          	sd	a3,1124(a5) # ffffffffc02b6c00 <boot_cr3>
    // assert(npage <= KMEMSIZE / PGSIZE);
    // The memory starts at 2GB in RISC-V
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();
ffffffffc02027a4:	f7cff0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02027a8:	6098                	ld	a4,0(s1)
ffffffffc02027aa:	c80007b7          	lui	a5,0xc8000
ffffffffc02027ae:	83b1                	srli	a5,a5,0xc
    nr_free_store=nr_free_pages();
ffffffffc02027b0:	8a2a                	mv	s4,a0
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02027b2:	0ce7eae3          	bltu	a5,a4,ffffffffc0203086 <pmm_init+0xa52>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02027b6:	6008                	ld	a0,0(s0)
ffffffffc02027b8:	44050463          	beqz	a0,ffffffffc0202c00 <pmm_init+0x5cc>
ffffffffc02027bc:	6785                	lui	a5,0x1
ffffffffc02027be:	17fd                	addi	a5,a5,-1
ffffffffc02027c0:	8fe9                	and	a5,a5,a0
ffffffffc02027c2:	2781                	sext.w	a5,a5
ffffffffc02027c4:	42079e63          	bnez	a5,ffffffffc0202c00 <pmm_init+0x5cc>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02027c8:	4601                	li	a2,0
ffffffffc02027ca:	4581                	li	a1,0
ffffffffc02027cc:	967ff0ef          	jal	ra,ffffffffc0202132 <get_page>
ffffffffc02027d0:	78051b63          	bnez	a0,ffffffffc0202f66 <pmm_init+0x932>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc02027d4:	4505                	li	a0,1
ffffffffc02027d6:	e7cff0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc02027da:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc02027dc:	6008                	ld	a0,0(s0)
ffffffffc02027de:	4681                	li	a3,0
ffffffffc02027e0:	4601                	li	a2,0
ffffffffc02027e2:	85d6                	mv	a1,s5
ffffffffc02027e4:	d93ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc02027e8:	7a051f63          	bnez	a0,ffffffffc0202fa6 <pmm_init+0x972>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc02027ec:	6008                	ld	a0,0(s0)
ffffffffc02027ee:	4601                	li	a2,0
ffffffffc02027f0:	4581                	li	a1,0
ffffffffc02027f2:	f6eff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc02027f6:	78050863          	beqz	a0,ffffffffc0202f86 <pmm_init+0x952>
    assert(pte2page(*ptep) == p1);
ffffffffc02027fa:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02027fc:	0017f713          	andi	a4,a5,1
ffffffffc0202800:	3e070463          	beqz	a4,ffffffffc0202be8 <pmm_init+0x5b4>
    if (PPN(pa) >= npage) {
ffffffffc0202804:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202806:	078a                	slli	a5,a5,0x2
ffffffffc0202808:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020280a:	3ce7f163          	bleu	a4,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc020280e:	00093683          	ld	a3,0(s2)
ffffffffc0202812:	fff80637          	lui	a2,0xfff80
ffffffffc0202816:	97b2                	add	a5,a5,a2
ffffffffc0202818:	079a                	slli	a5,a5,0x6
ffffffffc020281a:	97b6                	add	a5,a5,a3
ffffffffc020281c:	72fa9563          	bne	s5,a5,ffffffffc0202f46 <pmm_init+0x912>
    assert(page_ref(p1) == 1);
ffffffffc0202820:	000aab83          	lw	s7,0(s5) # 1000 <_binary_obj___user_faultread_out_size-0x8580>
ffffffffc0202824:	4785                	li	a5,1
ffffffffc0202826:	70fb9063          	bne	s7,a5,ffffffffc0202f26 <pmm_init+0x8f2>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc020282a:	6008                	ld	a0,0(s0)
ffffffffc020282c:	76fd                	lui	a3,0xfffff
ffffffffc020282e:	611c                	ld	a5,0(a0)
ffffffffc0202830:	078a                	slli	a5,a5,0x2
ffffffffc0202832:	8ff5                	and	a5,a5,a3
ffffffffc0202834:	00c7d613          	srli	a2,a5,0xc
ffffffffc0202838:	66e67e63          	bleu	a4,a2,ffffffffc0202eb4 <pmm_init+0x880>
ffffffffc020283c:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202840:	97e2                	add	a5,a5,s8
ffffffffc0202842:	0007bb03          	ld	s6,0(a5) # 1000 <_binary_obj___user_faultread_out_size-0x8580>
ffffffffc0202846:	0b0a                	slli	s6,s6,0x2
ffffffffc0202848:	00db7b33          	and	s6,s6,a3
ffffffffc020284c:	00cb5793          	srli	a5,s6,0xc
ffffffffc0202850:	56e7f863          	bleu	a4,a5,ffffffffc0202dc0 <pmm_init+0x78c>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202854:	4601                	li	a2,0
ffffffffc0202856:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202858:	9b62                	add	s6,s6,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc020285a:	f06ff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020285e:	0b21                	addi	s6,s6,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202860:	55651063          	bne	a0,s6,ffffffffc0202da0 <pmm_init+0x76c>

    p2 = alloc_page();
ffffffffc0202864:	4505                	li	a0,1
ffffffffc0202866:	decff0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020286a:	8b2a                	mv	s6,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020286c:	6008                	ld	a0,0(s0)
ffffffffc020286e:	46d1                	li	a3,20
ffffffffc0202870:	6605                	lui	a2,0x1
ffffffffc0202872:	85da                	mv	a1,s6
ffffffffc0202874:	d03ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc0202878:	50051463          	bnez	a0,ffffffffc0202d80 <pmm_init+0x74c>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc020287c:	6008                	ld	a0,0(s0)
ffffffffc020287e:	4601                	li	a2,0
ffffffffc0202880:	6585                	lui	a1,0x1
ffffffffc0202882:	edeff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc0202886:	4c050d63          	beqz	a0,ffffffffc0202d60 <pmm_init+0x72c>
    assert(*ptep & PTE_U);
ffffffffc020288a:	611c                	ld	a5,0(a0)
ffffffffc020288c:	0107f713          	andi	a4,a5,16
ffffffffc0202890:	4a070863          	beqz	a4,ffffffffc0202d40 <pmm_init+0x70c>
    assert(*ptep & PTE_W);
ffffffffc0202894:	8b91                	andi	a5,a5,4
ffffffffc0202896:	48078563          	beqz	a5,ffffffffc0202d20 <pmm_init+0x6ec>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc020289a:	6008                	ld	a0,0(s0)
ffffffffc020289c:	611c                	ld	a5,0(a0)
ffffffffc020289e:	8bc1                	andi	a5,a5,16
ffffffffc02028a0:	46078063          	beqz	a5,ffffffffc0202d00 <pmm_init+0x6cc>
    assert(page_ref(p2) == 1);
ffffffffc02028a4:	000b2783          	lw	a5,0(s6) # 200000 <_binary_obj___user_exit_out_size+0x1f5570>
ffffffffc02028a8:	43779c63          	bne	a5,s7,ffffffffc0202ce0 <pmm_init+0x6ac>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02028ac:	4681                	li	a3,0
ffffffffc02028ae:	6605                	lui	a2,0x1
ffffffffc02028b0:	85d6                	mv	a1,s5
ffffffffc02028b2:	cc5ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc02028b6:	40051563          	bnez	a0,ffffffffc0202cc0 <pmm_init+0x68c>
    assert(page_ref(p1) == 2);
ffffffffc02028ba:	000aa703          	lw	a4,0(s5)
ffffffffc02028be:	4789                	li	a5,2
ffffffffc02028c0:	3ef71063          	bne	a4,a5,ffffffffc0202ca0 <pmm_init+0x66c>
    assert(page_ref(p2) == 0);
ffffffffc02028c4:	000b2783          	lw	a5,0(s6)
ffffffffc02028c8:	3a079c63          	bnez	a5,ffffffffc0202c80 <pmm_init+0x64c>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02028cc:	6008                	ld	a0,0(s0)
ffffffffc02028ce:	4601                	li	a2,0
ffffffffc02028d0:	6585                	lui	a1,0x1
ffffffffc02028d2:	e8eff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc02028d6:	38050563          	beqz	a0,ffffffffc0202c60 <pmm_init+0x62c>
    assert(pte2page(*ptep) == p1);
ffffffffc02028da:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02028dc:	00177793          	andi	a5,a4,1
ffffffffc02028e0:	30078463          	beqz	a5,ffffffffc0202be8 <pmm_init+0x5b4>
    if (PPN(pa) >= npage) {
ffffffffc02028e4:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02028e6:	00271793          	slli	a5,a4,0x2
ffffffffc02028ea:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02028ec:	2ed7f063          	bleu	a3,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc02028f0:	00093683          	ld	a3,0(s2)
ffffffffc02028f4:	fff80637          	lui	a2,0xfff80
ffffffffc02028f8:	97b2                	add	a5,a5,a2
ffffffffc02028fa:	079a                	slli	a5,a5,0x6
ffffffffc02028fc:	97b6                	add	a5,a5,a3
ffffffffc02028fe:	32fa9163          	bne	s5,a5,ffffffffc0202c20 <pmm_init+0x5ec>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202902:	8b41                	andi	a4,a4,16
ffffffffc0202904:	70071163          	bnez	a4,ffffffffc0203006 <pmm_init+0x9d2>

    page_remove(boot_pgdir, 0x0);
ffffffffc0202908:	6008                	ld	a0,0(s0)
ffffffffc020290a:	4581                	li	a1,0
ffffffffc020290c:	bf7ff0ef          	jal	ra,ffffffffc0202502 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202910:	000aa703          	lw	a4,0(s5)
ffffffffc0202914:	4785                	li	a5,1
ffffffffc0202916:	6cf71863          	bne	a4,a5,ffffffffc0202fe6 <pmm_init+0x9b2>
    assert(page_ref(p2) == 0);
ffffffffc020291a:	000b2783          	lw	a5,0(s6)
ffffffffc020291e:	6a079463          	bnez	a5,ffffffffc0202fc6 <pmm_init+0x992>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0202922:	6008                	ld	a0,0(s0)
ffffffffc0202924:	6585                	lui	a1,0x1
ffffffffc0202926:	bddff0ef          	jal	ra,ffffffffc0202502 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc020292a:	000aa783          	lw	a5,0(s5)
ffffffffc020292e:	50079363          	bnez	a5,ffffffffc0202e34 <pmm_init+0x800>
    assert(page_ref(p2) == 0);
ffffffffc0202932:	000b2783          	lw	a5,0(s6)
ffffffffc0202936:	4c079f63          	bnez	a5,ffffffffc0202e14 <pmm_init+0x7e0>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc020293a:	00043a83          	ld	s5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc020293e:	6090                	ld	a2,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202940:	000ab783          	ld	a5,0(s5)
ffffffffc0202944:	078a                	slli	a5,a5,0x2
ffffffffc0202946:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202948:	28c7f263          	bleu	a2,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc020294c:	fff80737          	lui	a4,0xfff80
ffffffffc0202950:	00093503          	ld	a0,0(s2)
ffffffffc0202954:	97ba                	add	a5,a5,a4
ffffffffc0202956:	079a                	slli	a5,a5,0x6
ffffffffc0202958:	00f50733          	add	a4,a0,a5
ffffffffc020295c:	4314                	lw	a3,0(a4)
ffffffffc020295e:	4705                	li	a4,1
ffffffffc0202960:	48e69a63          	bne	a3,a4,ffffffffc0202df4 <pmm_init+0x7c0>
    return page - pages + nbase;
ffffffffc0202964:	8799                	srai	a5,a5,0x6
ffffffffc0202966:	00080b37          	lui	s6,0x80
    return KADDR(page2pa(page));
ffffffffc020296a:	577d                	li	a4,-1
    return page - pages + nbase;
ffffffffc020296c:	97da                	add	a5,a5,s6
    return KADDR(page2pa(page));
ffffffffc020296e:	8331                	srli	a4,a4,0xc
ffffffffc0202970:	8f7d                	and	a4,a4,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0202972:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202974:	46c77363          	bleu	a2,a4,ffffffffc0202dda <pmm_init+0x7a6>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202978:	0009b683          	ld	a3,0(s3)
ffffffffc020297c:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc020297e:	639c                	ld	a5,0(a5)
ffffffffc0202980:	078a                	slli	a5,a5,0x2
ffffffffc0202982:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202984:	24c7f463          	bleu	a2,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0202988:	416787b3          	sub	a5,a5,s6
ffffffffc020298c:	079a                	slli	a5,a5,0x6
ffffffffc020298e:	953e                	add	a0,a0,a5
ffffffffc0202990:	4585                	li	a1,1
ffffffffc0202992:	d48ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202996:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage) {
ffffffffc020299a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020299c:	078a                	slli	a5,a5,0x2
ffffffffc020299e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02029a0:	22e7f663          	bleu	a4,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc02029a4:	00093503          	ld	a0,0(s2)
ffffffffc02029a8:	416787b3          	sub	a5,a5,s6
ffffffffc02029ac:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc02029ae:	953e                	add	a0,a0,a5
ffffffffc02029b0:	4585                	li	a1,1
ffffffffc02029b2:	d28ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
    boot_pgdir[0] = 0;
ffffffffc02029b6:	601c                	ld	a5,0(s0)
ffffffffc02029b8:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc02029bc:	12000073          	sfence.vma
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc02029c0:	d60ff0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
ffffffffc02029c4:	68aa1163          	bne	s4,a0,ffffffffc0203046 <pmm_init+0xa12>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc02029c8:	00005517          	auipc	a0,0x5
ffffffffc02029cc:	00050513          	mv	a0,a0
ffffffffc02029d0:	fbefd0ef          	jal	ra,ffffffffc020018e <cprintf>
static void check_boot_pgdir(void) {
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();
ffffffffc02029d4:	d4cff0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02029d8:	6098                	ld	a4,0(s1)
ffffffffc02029da:	c02007b7          	lui	a5,0xc0200
    nr_free_store=nr_free_pages();
ffffffffc02029de:	8a2a                	mv	s4,a0
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02029e0:	00c71693          	slli	a3,a4,0xc
ffffffffc02029e4:	18d7f563          	bleu	a3,a5,ffffffffc0202b6e <pmm_init+0x53a>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02029e8:	83b1                	srli	a5,a5,0xc
ffffffffc02029ea:	6008                	ld	a0,0(s0)
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02029ec:	c0200ab7          	lui	s5,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02029f0:	1ae7f163          	bleu	a4,a5,ffffffffc0202b92 <pmm_init+0x55e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02029f4:	7bfd                	lui	s7,0xfffff
ffffffffc02029f6:	6b05                	lui	s6,0x1
ffffffffc02029f8:	a029                	j	ffffffffc0202a02 <pmm_init+0x3ce>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02029fa:	00cad713          	srli	a4,s5,0xc
ffffffffc02029fe:	18f77a63          	bleu	a5,a4,ffffffffc0202b92 <pmm_init+0x55e>
ffffffffc0202a02:	0009b583          	ld	a1,0(s3)
ffffffffc0202a06:	4601                	li	a2,0
ffffffffc0202a08:	95d6                	add	a1,a1,s5
ffffffffc0202a0a:	d56ff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc0202a0e:	16050263          	beqz	a0,ffffffffc0202b72 <pmm_init+0x53e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202a12:	611c                	ld	a5,0(a0)
ffffffffc0202a14:	078a                	slli	a5,a5,0x2
ffffffffc0202a16:	0177f7b3          	and	a5,a5,s7
ffffffffc0202a1a:	19579963          	bne	a5,s5,ffffffffc0202bac <pmm_init+0x578>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0202a1e:	609c                	ld	a5,0(s1)
ffffffffc0202a20:	9ada                	add	s5,s5,s6
ffffffffc0202a22:	6008                	ld	a0,0(s0)
ffffffffc0202a24:	00c79713          	slli	a4,a5,0xc
ffffffffc0202a28:	fceae9e3          	bltu	s5,a4,ffffffffc02029fa <pmm_init+0x3c6>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc0202a2c:	611c                	ld	a5,0(a0)
ffffffffc0202a2e:	62079c63          	bnez	a5,ffffffffc0203066 <pmm_init+0xa32>

    struct Page *p;
    p = alloc_page();
ffffffffc0202a32:	4505                	li	a0,1
ffffffffc0202a34:	c1eff0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0202a38:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202a3a:	6008                	ld	a0,0(s0)
ffffffffc0202a3c:	4699                	li	a3,6
ffffffffc0202a3e:	10000613          	li	a2,256
ffffffffc0202a42:	85d6                	mv	a1,s5
ffffffffc0202a44:	b33ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc0202a48:	1e051c63          	bnez	a0,ffffffffc0202c40 <pmm_init+0x60c>
    assert(page_ref(p) == 1);
ffffffffc0202a4c:	000aa703          	lw	a4,0(s5) # ffffffffc0200000 <kern_entry>
ffffffffc0202a50:	4785                	li	a5,1
ffffffffc0202a52:	44f71163          	bne	a4,a5,ffffffffc0202e94 <pmm_init+0x860>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202a56:	6008                	ld	a0,0(s0)
ffffffffc0202a58:	6b05                	lui	s6,0x1
ffffffffc0202a5a:	4699                	li	a3,6
ffffffffc0202a5c:	100b0613          	addi	a2,s6,256 # 1100 <_binary_obj___user_faultread_out_size-0x8480>
ffffffffc0202a60:	85d6                	mv	a1,s5
ffffffffc0202a62:	b15ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc0202a66:	40051763          	bnez	a0,ffffffffc0202e74 <pmm_init+0x840>
    assert(page_ref(p) == 2);
ffffffffc0202a6a:	000aa703          	lw	a4,0(s5)
ffffffffc0202a6e:	4789                	li	a5,2
ffffffffc0202a70:	3ef71263          	bne	a4,a5,ffffffffc0202e54 <pmm_init+0x820>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202a74:	00005597          	auipc	a1,0x5
ffffffffc0202a78:	08c58593          	addi	a1,a1,140 # ffffffffc0207b00 <default_pmm_manager+0x668>
ffffffffc0202a7c:	10000513          	li	a0,256
ffffffffc0202a80:	45b030ef          	jal	ra,ffffffffc02066da <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202a84:	100b0593          	addi	a1,s6,256
ffffffffc0202a88:	10000513          	li	a0,256
ffffffffc0202a8c:	461030ef          	jal	ra,ffffffffc02066ec <strcmp>
ffffffffc0202a90:	44051b63          	bnez	a0,ffffffffc0202ee6 <pmm_init+0x8b2>
    return page - pages + nbase;
ffffffffc0202a94:	00093683          	ld	a3,0(s2)
ffffffffc0202a98:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202a9c:	5b7d                	li	s6,-1
    return page - pages + nbase;
ffffffffc0202a9e:	40da86b3          	sub	a3,s5,a3
ffffffffc0202aa2:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202aa4:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202aa6:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202aa8:	00cb5b13          	srli	s6,s6,0xc
ffffffffc0202aac:	0166f733          	and	a4,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202ab0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202ab2:	10f77f63          	bleu	a5,a4,ffffffffc0202bd0 <pmm_init+0x59c>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202ab6:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202aba:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202abe:	96be                	add	a3,a3,a5
ffffffffc0202ac0:	10068023          	sb	zero,256(a3) # fffffffffffff100 <end+0x3fd48400>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202ac4:	3d3030ef          	jal	ra,ffffffffc0206696 <strlen>
ffffffffc0202ac8:	54051f63          	bnez	a0,ffffffffc0203026 <pmm_init+0x9f2>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0202acc:	00043b83          	ld	s7,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0202ad0:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ad2:	000bb683          	ld	a3,0(s7) # fffffffffffff000 <end+0x3fd48300>
ffffffffc0202ad6:	068a                	slli	a3,a3,0x2
ffffffffc0202ad8:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202ada:	0ef6f963          	bleu	a5,a3,ffffffffc0202bcc <pmm_init+0x598>
    return KADDR(page2pa(page));
ffffffffc0202ade:	0166fb33          	and	s6,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202ae2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202ae4:	0efb7663          	bleu	a5,s6,ffffffffc0202bd0 <pmm_init+0x59c>
ffffffffc0202ae8:	0009b983          	ld	s3,0(s3)
    free_page(p);
ffffffffc0202aec:	4585                	li	a1,1
ffffffffc0202aee:	8556                	mv	a0,s5
ffffffffc0202af0:	99b6                	add	s3,s3,a3
ffffffffc0202af2:	be8ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202af6:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0202afa:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202afc:	078a                	slli	a5,a5,0x2
ffffffffc0202afe:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202b00:	0ce7f663          	bleu	a4,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b04:	00093503          	ld	a0,0(s2)
ffffffffc0202b08:	fff809b7          	lui	s3,0xfff80
ffffffffc0202b0c:	97ce                	add	a5,a5,s3
ffffffffc0202b0e:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc0202b10:	953e                	add	a0,a0,a5
ffffffffc0202b12:	4585                	li	a1,1
ffffffffc0202b14:	bc6ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b18:	000bb783          	ld	a5,0(s7)
    if (PPN(pa) >= npage) {
ffffffffc0202b1c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b1e:	078a                	slli	a5,a5,0x2
ffffffffc0202b20:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202b22:	0ae7f563          	bleu	a4,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b26:	00093503          	ld	a0,0(s2)
ffffffffc0202b2a:	97ce                	add	a5,a5,s3
ffffffffc0202b2c:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0202b2e:	953e                	add	a0,a0,a5
ffffffffc0202b30:	4585                	li	a1,1
ffffffffc0202b32:	ba8ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
    boot_pgdir[0] = 0;
ffffffffc0202b36:	601c                	ld	a5,0(s0)
ffffffffc0202b38:	0007b023          	sd	zero,0(a5) # ffffffffc0200000 <kern_entry>
  asm volatile("sfence.vma");
ffffffffc0202b3c:	12000073          	sfence.vma
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0202b40:	be0ff0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
ffffffffc0202b44:	3caa1163          	bne	s4,a0,ffffffffc0202f06 <pmm_init+0x8d2>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202b48:	00005517          	auipc	a0,0x5
ffffffffc0202b4c:	03050513          	addi	a0,a0,48 # ffffffffc0207b78 <default_pmm_manager+0x6e0>
ffffffffc0202b50:	e3efd0ef          	jal	ra,ffffffffc020018e <cprintf>
}
ffffffffc0202b54:	6406                	ld	s0,64(sp)
ffffffffc0202b56:	60a6                	ld	ra,72(sp)
ffffffffc0202b58:	74e2                	ld	s1,56(sp)
ffffffffc0202b5a:	7942                	ld	s2,48(sp)
ffffffffc0202b5c:	79a2                	ld	s3,40(sp)
ffffffffc0202b5e:	7a02                	ld	s4,32(sp)
ffffffffc0202b60:	6ae2                	ld	s5,24(sp)
ffffffffc0202b62:	6b42                	ld	s6,16(sp)
ffffffffc0202b64:	6ba2                	ld	s7,8(sp)
ffffffffc0202b66:	6c02                	ld	s8,0(sp)
ffffffffc0202b68:	6161                	addi	sp,sp,80
    kmalloc_init();
ffffffffc0202b6a:	8c8ff06f          	j	ffffffffc0201c32 <kmalloc_init>
ffffffffc0202b6e:	6008                	ld	a0,0(s0)
ffffffffc0202b70:	bd75                	j	ffffffffc0202a2c <pmm_init+0x3f8>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b72:	00005697          	auipc	a3,0x5
ffffffffc0202b76:	e7668693          	addi	a3,a3,-394 # ffffffffc02079e8 <default_pmm_manager+0x550>
ffffffffc0202b7a:	00004617          	auipc	a2,0x4
ffffffffc0202b7e:	1d660613          	addi	a2,a2,470 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202b82:	24a00593          	li	a1,586
ffffffffc0202b86:	00005517          	auipc	a0,0x5
ffffffffc0202b8a:	a9a50513          	addi	a0,a0,-1382 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202b8e:	8f7fd0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0202b92:	86d6                	mv	a3,s5
ffffffffc0202b94:	00005617          	auipc	a2,0x5
ffffffffc0202b98:	95460613          	addi	a2,a2,-1708 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc0202b9c:	24a00593          	li	a1,586
ffffffffc0202ba0:	00005517          	auipc	a0,0x5
ffffffffc0202ba4:	a8050513          	addi	a0,a0,-1408 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202ba8:	8ddfd0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202bac:	00005697          	auipc	a3,0x5
ffffffffc0202bb0:	e7c68693          	addi	a3,a3,-388 # ffffffffc0207a28 <default_pmm_manager+0x590>
ffffffffc0202bb4:	00004617          	auipc	a2,0x4
ffffffffc0202bb8:	19c60613          	addi	a2,a2,412 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202bbc:	24b00593          	li	a1,587
ffffffffc0202bc0:	00005517          	auipc	a0,0x5
ffffffffc0202bc4:	a6050513          	addi	a0,a0,-1440 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202bc8:	8bdfd0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0202bcc:	a6aff0ef          	jal	ra,ffffffffc0201e36 <pa2page.part.4>
    return KADDR(page2pa(page));
ffffffffc0202bd0:	00005617          	auipc	a2,0x5
ffffffffc0202bd4:	91860613          	addi	a2,a2,-1768 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc0202bd8:	06900593          	li	a1,105
ffffffffc0202bdc:	00005517          	auipc	a0,0x5
ffffffffc0202be0:	93450513          	addi	a0,a0,-1740 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0202be4:	8a1fd0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202be8:	00005617          	auipc	a2,0x5
ffffffffc0202bec:	bd060613          	addi	a2,a2,-1072 # ffffffffc02077b8 <default_pmm_manager+0x320>
ffffffffc0202bf0:	07400593          	li	a1,116
ffffffffc0202bf4:	00005517          	auipc	a0,0x5
ffffffffc0202bf8:	91c50513          	addi	a0,a0,-1764 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0202bfc:	889fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0202c00:	00005697          	auipc	a3,0x5
ffffffffc0202c04:	af868693          	addi	a3,a3,-1288 # ffffffffc02076f8 <default_pmm_manager+0x260>
ffffffffc0202c08:	00004617          	auipc	a2,0x4
ffffffffc0202c0c:	14860613          	addi	a2,a2,328 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202c10:	20e00593          	li	a1,526
ffffffffc0202c14:	00005517          	auipc	a0,0x5
ffffffffc0202c18:	a0c50513          	addi	a0,a0,-1524 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202c1c:	869fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202c20:	00005697          	auipc	a3,0x5
ffffffffc0202c24:	bc068693          	addi	a3,a3,-1088 # ffffffffc02077e0 <default_pmm_manager+0x348>
ffffffffc0202c28:	00004617          	auipc	a2,0x4
ffffffffc0202c2c:	12860613          	addi	a2,a2,296 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202c30:	22a00593          	li	a1,554
ffffffffc0202c34:	00005517          	auipc	a0,0x5
ffffffffc0202c38:	9ec50513          	addi	a0,a0,-1556 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202c3c:	849fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202c40:	00005697          	auipc	a3,0x5
ffffffffc0202c44:	e1868693          	addi	a3,a3,-488 # ffffffffc0207a58 <default_pmm_manager+0x5c0>
ffffffffc0202c48:	00004617          	auipc	a2,0x4
ffffffffc0202c4c:	10860613          	addi	a2,a2,264 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202c50:	25300593          	li	a1,595
ffffffffc0202c54:	00005517          	auipc	a0,0x5
ffffffffc0202c58:	9cc50513          	addi	a0,a0,-1588 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202c5c:	829fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202c60:	00005697          	auipc	a3,0x5
ffffffffc0202c64:	c1068693          	addi	a3,a3,-1008 # ffffffffc0207870 <default_pmm_manager+0x3d8>
ffffffffc0202c68:	00004617          	auipc	a2,0x4
ffffffffc0202c6c:	0e860613          	addi	a2,a2,232 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202c70:	22900593          	li	a1,553
ffffffffc0202c74:	00005517          	auipc	a0,0x5
ffffffffc0202c78:	9ac50513          	addi	a0,a0,-1620 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202c7c:	809fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202c80:	00005697          	auipc	a3,0x5
ffffffffc0202c84:	cb868693          	addi	a3,a3,-840 # ffffffffc0207938 <default_pmm_manager+0x4a0>
ffffffffc0202c88:	00004617          	auipc	a2,0x4
ffffffffc0202c8c:	0c860613          	addi	a2,a2,200 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202c90:	22800593          	li	a1,552
ffffffffc0202c94:	00005517          	auipc	a0,0x5
ffffffffc0202c98:	98c50513          	addi	a0,a0,-1652 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202c9c:	fe8fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202ca0:	00005697          	auipc	a3,0x5
ffffffffc0202ca4:	c8068693          	addi	a3,a3,-896 # ffffffffc0207920 <default_pmm_manager+0x488>
ffffffffc0202ca8:	00004617          	auipc	a2,0x4
ffffffffc0202cac:	0a860613          	addi	a2,a2,168 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202cb0:	22700593          	li	a1,551
ffffffffc0202cb4:	00005517          	auipc	a0,0x5
ffffffffc0202cb8:	96c50513          	addi	a0,a0,-1684 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202cbc:	fc8fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0202cc0:	00005697          	auipc	a3,0x5
ffffffffc0202cc4:	c3068693          	addi	a3,a3,-976 # ffffffffc02078f0 <default_pmm_manager+0x458>
ffffffffc0202cc8:	00004617          	auipc	a2,0x4
ffffffffc0202ccc:	08860613          	addi	a2,a2,136 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202cd0:	22600593          	li	a1,550
ffffffffc0202cd4:	00005517          	auipc	a0,0x5
ffffffffc0202cd8:	94c50513          	addi	a0,a0,-1716 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202cdc:	fa8fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202ce0:	00005697          	auipc	a3,0x5
ffffffffc0202ce4:	bf868693          	addi	a3,a3,-1032 # ffffffffc02078d8 <default_pmm_manager+0x440>
ffffffffc0202ce8:	00004617          	auipc	a2,0x4
ffffffffc0202cec:	06860613          	addi	a2,a2,104 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202cf0:	22400593          	li	a1,548
ffffffffc0202cf4:	00005517          	auipc	a0,0x5
ffffffffc0202cf8:	92c50513          	addi	a0,a0,-1748 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202cfc:	f88fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0202d00:	00005697          	auipc	a3,0x5
ffffffffc0202d04:	bc068693          	addi	a3,a3,-1088 # ffffffffc02078c0 <default_pmm_manager+0x428>
ffffffffc0202d08:	00004617          	auipc	a2,0x4
ffffffffc0202d0c:	04860613          	addi	a2,a2,72 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202d10:	22300593          	li	a1,547
ffffffffc0202d14:	00005517          	auipc	a0,0x5
ffffffffc0202d18:	90c50513          	addi	a0,a0,-1780 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202d1c:	f68fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202d20:	00005697          	auipc	a3,0x5
ffffffffc0202d24:	b9068693          	addi	a3,a3,-1136 # ffffffffc02078b0 <default_pmm_manager+0x418>
ffffffffc0202d28:	00004617          	auipc	a2,0x4
ffffffffc0202d2c:	02860613          	addi	a2,a2,40 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202d30:	22200593          	li	a1,546
ffffffffc0202d34:	00005517          	auipc	a0,0x5
ffffffffc0202d38:	8ec50513          	addi	a0,a0,-1812 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202d3c:	f48fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202d40:	00005697          	auipc	a3,0x5
ffffffffc0202d44:	b6068693          	addi	a3,a3,-1184 # ffffffffc02078a0 <default_pmm_manager+0x408>
ffffffffc0202d48:	00004617          	auipc	a2,0x4
ffffffffc0202d4c:	00860613          	addi	a2,a2,8 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202d50:	22100593          	li	a1,545
ffffffffc0202d54:	00005517          	auipc	a0,0x5
ffffffffc0202d58:	8cc50513          	addi	a0,a0,-1844 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202d5c:	f28fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202d60:	00005697          	auipc	a3,0x5
ffffffffc0202d64:	b1068693          	addi	a3,a3,-1264 # ffffffffc0207870 <default_pmm_manager+0x3d8>
ffffffffc0202d68:	00004617          	auipc	a2,0x4
ffffffffc0202d6c:	fe860613          	addi	a2,a2,-24 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202d70:	22000593          	li	a1,544
ffffffffc0202d74:	00005517          	auipc	a0,0x5
ffffffffc0202d78:	8ac50513          	addi	a0,a0,-1876 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202d7c:	f08fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202d80:	00005697          	auipc	a3,0x5
ffffffffc0202d84:	ab868693          	addi	a3,a3,-1352 # ffffffffc0207838 <default_pmm_manager+0x3a0>
ffffffffc0202d88:	00004617          	auipc	a2,0x4
ffffffffc0202d8c:	fc860613          	addi	a2,a2,-56 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202d90:	21f00593          	li	a1,543
ffffffffc0202d94:	00005517          	auipc	a0,0x5
ffffffffc0202d98:	88c50513          	addi	a0,a0,-1908 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202d9c:	ee8fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202da0:	00005697          	auipc	a3,0x5
ffffffffc0202da4:	a7068693          	addi	a3,a3,-1424 # ffffffffc0207810 <default_pmm_manager+0x378>
ffffffffc0202da8:	00004617          	auipc	a2,0x4
ffffffffc0202dac:	fa860613          	addi	a2,a2,-88 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202db0:	21c00593          	li	a1,540
ffffffffc0202db4:	00005517          	auipc	a0,0x5
ffffffffc0202db8:	86c50513          	addi	a0,a0,-1940 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202dbc:	ec8fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202dc0:	86da                	mv	a3,s6
ffffffffc0202dc2:	00004617          	auipc	a2,0x4
ffffffffc0202dc6:	72660613          	addi	a2,a2,1830 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc0202dca:	21b00593          	li	a1,539
ffffffffc0202dce:	00005517          	auipc	a0,0x5
ffffffffc0202dd2:	85250513          	addi	a0,a0,-1966 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202dd6:	eaefd0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202dda:	86be                	mv	a3,a5
ffffffffc0202ddc:	00004617          	auipc	a2,0x4
ffffffffc0202de0:	70c60613          	addi	a2,a2,1804 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc0202de4:	06900593          	li	a1,105
ffffffffc0202de8:	00004517          	auipc	a0,0x4
ffffffffc0202dec:	72850513          	addi	a0,a0,1832 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0202df0:	e94fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0202df4:	00005697          	auipc	a3,0x5
ffffffffc0202df8:	b8c68693          	addi	a3,a3,-1140 # ffffffffc0207980 <default_pmm_manager+0x4e8>
ffffffffc0202dfc:	00004617          	auipc	a2,0x4
ffffffffc0202e00:	f5460613          	addi	a2,a2,-172 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202e04:	23500593          	li	a1,565
ffffffffc0202e08:	00005517          	auipc	a0,0x5
ffffffffc0202e0c:	81850513          	addi	a0,a0,-2024 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202e10:	e74fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202e14:	00005697          	auipc	a3,0x5
ffffffffc0202e18:	b2468693          	addi	a3,a3,-1244 # ffffffffc0207938 <default_pmm_manager+0x4a0>
ffffffffc0202e1c:	00004617          	auipc	a2,0x4
ffffffffc0202e20:	f3460613          	addi	a2,a2,-204 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202e24:	23300593          	li	a1,563
ffffffffc0202e28:	00004517          	auipc	a0,0x4
ffffffffc0202e2c:	7f850513          	addi	a0,a0,2040 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202e30:	e54fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202e34:	00005697          	auipc	a3,0x5
ffffffffc0202e38:	b3468693          	addi	a3,a3,-1228 # ffffffffc0207968 <default_pmm_manager+0x4d0>
ffffffffc0202e3c:	00004617          	auipc	a2,0x4
ffffffffc0202e40:	f1460613          	addi	a2,a2,-236 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202e44:	23200593          	li	a1,562
ffffffffc0202e48:	00004517          	auipc	a0,0x4
ffffffffc0202e4c:	7d850513          	addi	a0,a0,2008 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202e50:	e34fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202e54:	00005697          	auipc	a3,0x5
ffffffffc0202e58:	c9468693          	addi	a3,a3,-876 # ffffffffc0207ae8 <default_pmm_manager+0x650>
ffffffffc0202e5c:	00004617          	auipc	a2,0x4
ffffffffc0202e60:	ef460613          	addi	a2,a2,-268 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202e64:	25600593          	li	a1,598
ffffffffc0202e68:	00004517          	auipc	a0,0x4
ffffffffc0202e6c:	7b850513          	addi	a0,a0,1976 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202e70:	e14fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202e74:	00005697          	auipc	a3,0x5
ffffffffc0202e78:	c3468693          	addi	a3,a3,-972 # ffffffffc0207aa8 <default_pmm_manager+0x610>
ffffffffc0202e7c:	00004617          	auipc	a2,0x4
ffffffffc0202e80:	ed460613          	addi	a2,a2,-300 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202e84:	25500593          	li	a1,597
ffffffffc0202e88:	00004517          	auipc	a0,0x4
ffffffffc0202e8c:	79850513          	addi	a0,a0,1944 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202e90:	df4fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202e94:	00005697          	auipc	a3,0x5
ffffffffc0202e98:	bfc68693          	addi	a3,a3,-1028 # ffffffffc0207a90 <default_pmm_manager+0x5f8>
ffffffffc0202e9c:	00004617          	auipc	a2,0x4
ffffffffc0202ea0:	eb460613          	addi	a2,a2,-332 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202ea4:	25400593          	li	a1,596
ffffffffc0202ea8:	00004517          	auipc	a0,0x4
ffffffffc0202eac:	77850513          	addi	a0,a0,1912 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202eb0:	dd4fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0202eb4:	86be                	mv	a3,a5
ffffffffc0202eb6:	00004617          	auipc	a2,0x4
ffffffffc0202eba:	63260613          	addi	a2,a2,1586 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc0202ebe:	21a00593          	li	a1,538
ffffffffc0202ec2:	00004517          	auipc	a0,0x4
ffffffffc0202ec6:	75e50513          	addi	a0,a0,1886 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202eca:	dbafd0ef          	jal	ra,ffffffffc0200484 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202ece:	00004617          	auipc	a2,0x4
ffffffffc0202ed2:	65260613          	addi	a2,a2,1618 # ffffffffc0207520 <default_pmm_manager+0x88>
ffffffffc0202ed6:	07f00593          	li	a1,127
ffffffffc0202eda:	00004517          	auipc	a0,0x4
ffffffffc0202ede:	74650513          	addi	a0,a0,1862 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202ee2:	da2fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202ee6:	00005697          	auipc	a3,0x5
ffffffffc0202eea:	c3268693          	addi	a3,a3,-974 # ffffffffc0207b18 <default_pmm_manager+0x680>
ffffffffc0202eee:	00004617          	auipc	a2,0x4
ffffffffc0202ef2:	e6260613          	addi	a2,a2,-414 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202ef6:	25a00593          	li	a1,602
ffffffffc0202efa:	00004517          	auipc	a0,0x4
ffffffffc0202efe:	72650513          	addi	a0,a0,1830 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202f02:	d82fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0202f06:	00005697          	auipc	a3,0x5
ffffffffc0202f0a:	aa268693          	addi	a3,a3,-1374 # ffffffffc02079a8 <default_pmm_manager+0x510>
ffffffffc0202f0e:	00004617          	auipc	a2,0x4
ffffffffc0202f12:	e4260613          	addi	a2,a2,-446 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202f16:	26600593          	li	a1,614
ffffffffc0202f1a:	00004517          	auipc	a0,0x4
ffffffffc0202f1e:	70650513          	addi	a0,a0,1798 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202f22:	d62fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202f26:	00005697          	auipc	a3,0x5
ffffffffc0202f2a:	8d268693          	addi	a3,a3,-1838 # ffffffffc02077f8 <default_pmm_manager+0x360>
ffffffffc0202f2e:	00004617          	auipc	a2,0x4
ffffffffc0202f32:	e2260613          	addi	a2,a2,-478 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202f36:	21800593          	li	a1,536
ffffffffc0202f3a:	00004517          	auipc	a0,0x4
ffffffffc0202f3e:	6e650513          	addi	a0,a0,1766 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202f42:	d42fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202f46:	00005697          	auipc	a3,0x5
ffffffffc0202f4a:	89a68693          	addi	a3,a3,-1894 # ffffffffc02077e0 <default_pmm_manager+0x348>
ffffffffc0202f4e:	00004617          	auipc	a2,0x4
ffffffffc0202f52:	e0260613          	addi	a2,a2,-510 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202f56:	21700593          	li	a1,535
ffffffffc0202f5a:	00004517          	auipc	a0,0x4
ffffffffc0202f5e:	6c650513          	addi	a0,a0,1734 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202f62:	d22fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0202f66:	00004697          	auipc	a3,0x4
ffffffffc0202f6a:	7ca68693          	addi	a3,a3,1994 # ffffffffc0207730 <default_pmm_manager+0x298>
ffffffffc0202f6e:	00004617          	auipc	a2,0x4
ffffffffc0202f72:	de260613          	addi	a2,a2,-542 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202f76:	20f00593          	li	a1,527
ffffffffc0202f7a:	00004517          	auipc	a0,0x4
ffffffffc0202f7e:	6a650513          	addi	a0,a0,1702 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202f82:	d02fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0202f86:	00005697          	auipc	a3,0x5
ffffffffc0202f8a:	80268693          	addi	a3,a3,-2046 # ffffffffc0207788 <default_pmm_manager+0x2f0>
ffffffffc0202f8e:	00004617          	auipc	a2,0x4
ffffffffc0202f92:	dc260613          	addi	a2,a2,-574 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202f96:	21600593          	li	a1,534
ffffffffc0202f9a:	00004517          	auipc	a0,0x4
ffffffffc0202f9e:	68650513          	addi	a0,a0,1670 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202fa2:	ce2fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0202fa6:	00004697          	auipc	a3,0x4
ffffffffc0202faa:	7b268693          	addi	a3,a3,1970 # ffffffffc0207758 <default_pmm_manager+0x2c0>
ffffffffc0202fae:	00004617          	auipc	a2,0x4
ffffffffc0202fb2:	da260613          	addi	a2,a2,-606 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202fb6:	21300593          	li	a1,531
ffffffffc0202fba:	00004517          	auipc	a0,0x4
ffffffffc0202fbe:	66650513          	addi	a0,a0,1638 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202fc2:	cc2fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202fc6:	00005697          	auipc	a3,0x5
ffffffffc0202fca:	97268693          	addi	a3,a3,-1678 # ffffffffc0207938 <default_pmm_manager+0x4a0>
ffffffffc0202fce:	00004617          	auipc	a2,0x4
ffffffffc0202fd2:	d8260613          	addi	a2,a2,-638 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202fd6:	22f00593          	li	a1,559
ffffffffc0202fda:	00004517          	auipc	a0,0x4
ffffffffc0202fde:	64650513          	addi	a0,a0,1606 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0202fe2:	ca2fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202fe6:	00005697          	auipc	a3,0x5
ffffffffc0202fea:	81268693          	addi	a3,a3,-2030 # ffffffffc02077f8 <default_pmm_manager+0x360>
ffffffffc0202fee:	00004617          	auipc	a2,0x4
ffffffffc0202ff2:	d6260613          	addi	a2,a2,-670 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0202ff6:	22e00593          	li	a1,558
ffffffffc0202ffa:	00004517          	auipc	a0,0x4
ffffffffc0202ffe:	62650513          	addi	a0,a0,1574 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0203002:	c82fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203006:	00005697          	auipc	a3,0x5
ffffffffc020300a:	94a68693          	addi	a3,a3,-1718 # ffffffffc0207950 <default_pmm_manager+0x4b8>
ffffffffc020300e:	00004617          	auipc	a2,0x4
ffffffffc0203012:	d4260613          	addi	a2,a2,-702 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203016:	22b00593          	li	a1,555
ffffffffc020301a:	00004517          	auipc	a0,0x4
ffffffffc020301e:	60650513          	addi	a0,a0,1542 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0203022:	c62fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203026:	00005697          	auipc	a3,0x5
ffffffffc020302a:	b2a68693          	addi	a3,a3,-1238 # ffffffffc0207b50 <default_pmm_manager+0x6b8>
ffffffffc020302e:	00004617          	auipc	a2,0x4
ffffffffc0203032:	d2260613          	addi	a2,a2,-734 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203036:	25d00593          	li	a1,605
ffffffffc020303a:	00004517          	auipc	a0,0x4
ffffffffc020303e:	5e650513          	addi	a0,a0,1510 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0203042:	c42fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0203046:	00005697          	auipc	a3,0x5
ffffffffc020304a:	96268693          	addi	a3,a3,-1694 # ffffffffc02079a8 <default_pmm_manager+0x510>
ffffffffc020304e:	00004617          	auipc	a2,0x4
ffffffffc0203052:	d0260613          	addi	a2,a2,-766 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203056:	23d00593          	li	a1,573
ffffffffc020305a:	00004517          	auipc	a0,0x4
ffffffffc020305e:	5c650513          	addi	a0,a0,1478 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0203062:	c22fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0203066:	00005697          	auipc	a3,0x5
ffffffffc020306a:	9da68693          	addi	a3,a3,-1574 # ffffffffc0207a40 <default_pmm_manager+0x5a8>
ffffffffc020306e:	00004617          	auipc	a2,0x4
ffffffffc0203072:	ce260613          	addi	a2,a2,-798 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203076:	24f00593          	li	a1,591
ffffffffc020307a:	00004517          	auipc	a0,0x4
ffffffffc020307e:	5a650513          	addi	a0,a0,1446 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0203082:	c02fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0203086:	00004697          	auipc	a3,0x4
ffffffffc020308a:	65268693          	addi	a3,a3,1618 # ffffffffc02076d8 <default_pmm_manager+0x240>
ffffffffc020308e:	00004617          	auipc	a2,0x4
ffffffffc0203092:	cc260613          	addi	a2,a2,-830 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203096:	20d00593          	li	a1,525
ffffffffc020309a:	00004517          	auipc	a0,0x4
ffffffffc020309e:	58650513          	addi	a0,a0,1414 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc02030a2:	be2fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02030a6:	00004617          	auipc	a2,0x4
ffffffffc02030aa:	47a60613          	addi	a2,a2,1146 # ffffffffc0207520 <default_pmm_manager+0x88>
ffffffffc02030ae:	0c100593          	li	a1,193
ffffffffc02030b2:	00004517          	auipc	a0,0x4
ffffffffc02030b6:	56e50513          	addi	a0,a0,1390 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc02030ba:	bcafd0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02030be <copy_range>:
               bool share) {
ffffffffc02030be:	7119                	addi	sp,sp,-128
ffffffffc02030c0:	f4a6                	sd	s1,104(sp)
ffffffffc02030c2:	84b6                	mv	s1,a3
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02030c4:	8ed1                	or	a3,a3,a2
               bool share) {
ffffffffc02030c6:	fc86                	sd	ra,120(sp)
ffffffffc02030c8:	f8a2                	sd	s0,112(sp)
ffffffffc02030ca:	f0ca                	sd	s2,96(sp)
ffffffffc02030cc:	ecce                	sd	s3,88(sp)
ffffffffc02030ce:	e8d2                	sd	s4,80(sp)
ffffffffc02030d0:	e4d6                	sd	s5,72(sp)
ffffffffc02030d2:	e0da                	sd	s6,64(sp)
ffffffffc02030d4:	fc5e                	sd	s7,56(sp)
ffffffffc02030d6:	f862                	sd	s8,48(sp)
ffffffffc02030d8:	f466                	sd	s9,40(sp)
ffffffffc02030da:	f06a                	sd	s10,32(sp)
ffffffffc02030dc:	ec6e                	sd	s11,24(sp)
ffffffffc02030de:	e03a                	sd	a4,0(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02030e0:	03469793          	slli	a5,a3,0x34
ffffffffc02030e4:	24079963          	bnez	a5,ffffffffc0203336 <copy_range+0x278>
    assert(USER_ACCESS(start, end));
ffffffffc02030e8:	00200737          	lui	a4,0x200
ffffffffc02030ec:	8d32                	mv	s10,a2
ffffffffc02030ee:	1ee66a63          	bltu	a2,a4,ffffffffc02032e2 <copy_range+0x224>
ffffffffc02030f2:	1e967863          	bleu	s1,a2,ffffffffc02032e2 <copy_range+0x224>
ffffffffc02030f6:	4705                	li	a4,1
ffffffffc02030f8:	077e                	slli	a4,a4,0x1f
ffffffffc02030fa:	1e976463          	bltu	a4,s1,ffffffffc02032e2 <copy_range+0x224>
ffffffffc02030fe:	5bfd                	li	s7,-1
ffffffffc0203100:	8a2a                	mv	s4,a0
ffffffffc0203102:	842e                	mv	s0,a1
        start += PGSIZE;
ffffffffc0203104:	6985                	lui	s3,0x1
    if (PPN(pa) >= npage) {
ffffffffc0203106:	000b4b17          	auipc	s6,0xb4
ffffffffc020310a:	a92b0b13          	addi	s6,s6,-1390 # ffffffffc02b6b98 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc020310e:	000b4a97          	auipc	s5,0xb4
ffffffffc0203112:	afaa8a93          	addi	s5,s5,-1286 # ffffffffc02b6c08 <pages>
ffffffffc0203116:	00080c37          	lui	s8,0x80
ffffffffc020311a:	00cbdb93          	srli	s7,s7,0xc
    return KADDR(page2pa(page));
ffffffffc020311e:	000b4c97          	auipc	s9,0xb4
ffffffffc0203122:	adac8c93          	addi	s9,s9,-1318 # ffffffffc02b6bf8 <va_pa_offset>
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203126:	4601                	li	a2,0
ffffffffc0203128:	85ea                	mv	a1,s10
ffffffffc020312a:	8522                	mv	a0,s0
ffffffffc020312c:	e35fe0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc0203130:	892a                	mv	s2,a0
        if (ptep == NULL) {
ffffffffc0203132:	c17d                	beqz	a0,ffffffffc0203218 <copy_range+0x15a>
        if (*ptep & PTE_V) {
ffffffffc0203134:	6118                	ld	a4,0(a0)
ffffffffc0203136:	8b05                	andi	a4,a4,1
ffffffffc0203138:	e705                	bnez	a4,ffffffffc0203160 <copy_range+0xa2>
        start += PGSIZE;
ffffffffc020313a:	9d4e                	add	s10,s10,s3
    } while (start != 0 && start < end);
ffffffffc020313c:	fe9d65e3          	bltu	s10,s1,ffffffffc0203126 <copy_range+0x68>
    return 0;
ffffffffc0203140:	4501                	li	a0,0
}
ffffffffc0203142:	70e6                	ld	ra,120(sp)
ffffffffc0203144:	7446                	ld	s0,112(sp)
ffffffffc0203146:	74a6                	ld	s1,104(sp)
ffffffffc0203148:	7906                	ld	s2,96(sp)
ffffffffc020314a:	69e6                	ld	s3,88(sp)
ffffffffc020314c:	6a46                	ld	s4,80(sp)
ffffffffc020314e:	6aa6                	ld	s5,72(sp)
ffffffffc0203150:	6b06                	ld	s6,64(sp)
ffffffffc0203152:	7be2                	ld	s7,56(sp)
ffffffffc0203154:	7c42                	ld	s8,48(sp)
ffffffffc0203156:	7ca2                	ld	s9,40(sp)
ffffffffc0203158:	7d02                	ld	s10,32(sp)
ffffffffc020315a:	6de2                	ld	s11,24(sp)
ffffffffc020315c:	6109                	addi	sp,sp,128
ffffffffc020315e:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL) {
ffffffffc0203160:	4605                	li	a2,1
ffffffffc0203162:	85ea                	mv	a1,s10
ffffffffc0203164:	8552                	mv	a0,s4
ffffffffc0203166:	dfbfe0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc020316a:	10050263          	beqz	a0,ffffffffc020326e <copy_range+0x1b0>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc020316e:	00093703          	ld	a4,0(s2)
    if (!(pte & PTE_V)) {
ffffffffc0203172:	00177693          	andi	a3,a4,1
ffffffffc0203176:	0007091b          	sext.w	s2,a4
ffffffffc020317a:	14068863          	beqz	a3,ffffffffc02032ca <copy_range+0x20c>
    if (PPN(pa) >= npage) {
ffffffffc020317e:	000b3683          	ld	a3,0(s6)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203182:	070a                	slli	a4,a4,0x2
ffffffffc0203184:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203186:	12d77663          	bleu	a3,a4,ffffffffc02032b2 <copy_range+0x1f4>
    return &pages[PPN(pa) - nbase];
ffffffffc020318a:	000ab683          	ld	a3,0(s5)
ffffffffc020318e:	fff807b7          	lui	a5,0xfff80
ffffffffc0203192:	973e                	add	a4,a4,a5
ffffffffc0203194:	071a                	slli	a4,a4,0x6
            struct Page *npage = alloc_page();
ffffffffc0203196:	4505                	li	a0,1
ffffffffc0203198:	00e68db3          	add	s11,a3,a4
ffffffffc020319c:	cb7fe0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc02031a0:	882a                	mv	a6,a0
            assert(page != NULL);
ffffffffc02031a2:	0e0d8863          	beqz	s11,ffffffffc0203292 <copy_range+0x1d4>
            assert(npage != NULL);
ffffffffc02031a6:	c571                	beqz	a0,ffffffffc0203272 <copy_range+0x1b4>
            if(share){
ffffffffc02031a8:	000ab503          	ld	a0,0(s5)
ffffffffc02031ac:	6782                	ld	a5,0(sp)
ffffffffc02031ae:	000b3683          	ld	a3,0(s6)
ffffffffc02031b2:	40ad8633          	sub	a2,s11,a0
ffffffffc02031b6:	8619                	srai	a2,a2,0x6
ffffffffc02031b8:	9662                	add	a2,a2,s8
ffffffffc02031ba:	00c61593          	slli	a1,a2,0xc
ffffffffc02031be:	01767633          	and	a2,a2,s7
ffffffffc02031c2:	cba5                	beqz	a5,ffffffffc0203232 <copy_range+0x174>
    return KADDR(page2pa(page));
ffffffffc02031c4:	14d67c63          	bleu	a3,a2,ffffffffc020331c <copy_range+0x25e>
ffffffffc02031c8:	000cb683          	ld	a3,0(s9)
                cprintf("share begin: 0x%x\n",page2kva(page));
ffffffffc02031cc:	00004517          	auipc	a0,0x4
ffffffffc02031d0:	42c50513          	addi	a0,a0,1068 # ffffffffc02075f8 <default_pmm_manager+0x160>
                page_insert(from, page, start, perm & (~PTE_W));
ffffffffc02031d4:	01b97913          	andi	s2,s2,27
                cprintf("share begin: 0x%x\n",page2kva(page));
ffffffffc02031d8:	95b6                	add	a1,a1,a3
ffffffffc02031da:	fb5fc0ef          	jal	ra,ffffffffc020018e <cprintf>
                page_insert(from, page, start, perm & (~PTE_W));
ffffffffc02031de:	86ca                	mv	a3,s2
ffffffffc02031e0:	866a                	mv	a2,s10
ffffffffc02031e2:	85ee                	mv	a1,s11
ffffffffc02031e4:	8522                	mv	a0,s0
ffffffffc02031e6:	b90ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
                ret = page_insert(to, page, start, perm & (~PTE_W));
ffffffffc02031ea:	86ca                	mv	a3,s2
ffffffffc02031ec:	866a                	mv	a2,s10
ffffffffc02031ee:	85ee                	mv	a1,s11
ffffffffc02031f0:	8552                	mv	a0,s4
ffffffffc02031f2:	b84ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
            assert(ret == 0);
ffffffffc02031f6:	d131                	beqz	a0,ffffffffc020313a <copy_range+0x7c>
ffffffffc02031f8:	00004697          	auipc	a3,0x4
ffffffffc02031fc:	41868693          	addi	a3,a3,1048 # ffffffffc0207610 <default_pmm_manager+0x178>
ffffffffc0203200:	00004617          	auipc	a2,0x4
ffffffffc0203204:	b5060613          	addi	a2,a2,-1200 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203208:	1aa00593          	li	a1,426
ffffffffc020320c:	00004517          	auipc	a0,0x4
ffffffffc0203210:	41450513          	addi	a0,a0,1044 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0203214:	a70fd0ef          	jal	ra,ffffffffc0200484 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203218:	00200737          	lui	a4,0x200
ffffffffc020321c:	00ed07b3          	add	a5,s10,a4
ffffffffc0203220:	ffe00737          	lui	a4,0xffe00
ffffffffc0203224:	00e7fd33          	and	s10,a5,a4
    } while (start != 0 && start < end);
ffffffffc0203228:	f00d0ce3          	beqz	s10,ffffffffc0203140 <copy_range+0x82>
ffffffffc020322c:	ee9d6de3          	bltu	s10,s1,ffffffffc0203126 <copy_range+0x68>
ffffffffc0203230:	bf01                	j	ffffffffc0203140 <copy_range+0x82>
ffffffffc0203232:	0ed67563          	bleu	a3,a2,ffffffffc020331c <copy_range+0x25e>
    return page - pages + nbase;
ffffffffc0203236:	40a80733          	sub	a4,a6,a0
ffffffffc020323a:	8719                	srai	a4,a4,0x6
    return KADDR(page2pa(page));
ffffffffc020323c:	000cb503          	ld	a0,0(s9)
    return page - pages + nbase;
ffffffffc0203240:	9762                	add	a4,a4,s8
    return KADDR(page2pa(page));
ffffffffc0203242:	01777633          	and	a2,a4,s7
ffffffffc0203246:	95aa                	add	a1,a1,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0203248:	0732                	slli	a4,a4,0xc
    return KADDR(page2pa(page));
ffffffffc020324a:	0ad67c63          	bleu	a3,a2,ffffffffc0203302 <copy_range+0x244>
                memcpy(dst_kvaddr,src_kvaddr,PGSIZE);
ffffffffc020324e:	6605                	lui	a2,0x1
ffffffffc0203250:	953a                	add	a0,a0,a4
ffffffffc0203252:	e442                	sd	a6,8(sp)
ffffffffc0203254:	4f2030ef          	jal	ra,ffffffffc0206746 <memcpy>
                ret = page_insert(to,npage,start,perm);
ffffffffc0203258:	6822                	ld	a6,8(sp)
ffffffffc020325a:	01f97693          	andi	a3,s2,31
ffffffffc020325e:	866a                	mv	a2,s10
ffffffffc0203260:	85c2                	mv	a1,a6
ffffffffc0203262:	8552                	mv	a0,s4
ffffffffc0203264:	b12ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
            assert(ret == 0);
ffffffffc0203268:	ec0509e3          	beqz	a0,ffffffffc020313a <copy_range+0x7c>
ffffffffc020326c:	b771                	j	ffffffffc02031f8 <copy_range+0x13a>
                return -E_NO_MEM;
ffffffffc020326e:	5571                	li	a0,-4
ffffffffc0203270:	bdc9                	j	ffffffffc0203142 <copy_range+0x84>
            assert(npage != NULL);
ffffffffc0203272:	00004697          	auipc	a3,0x4
ffffffffc0203276:	37668693          	addi	a3,a3,886 # ffffffffc02075e8 <default_pmm_manager+0x150>
ffffffffc020327a:	00004617          	auipc	a2,0x4
ffffffffc020327e:	ad660613          	addi	a2,a2,-1322 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203282:	18900593          	li	a1,393
ffffffffc0203286:	00004517          	auipc	a0,0x4
ffffffffc020328a:	39a50513          	addi	a0,a0,922 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc020328e:	9f6fd0ef          	jal	ra,ffffffffc0200484 <__panic>
            assert(page != NULL);
ffffffffc0203292:	00004697          	auipc	a3,0x4
ffffffffc0203296:	34668693          	addi	a3,a3,838 # ffffffffc02075d8 <default_pmm_manager+0x140>
ffffffffc020329a:	00004617          	auipc	a2,0x4
ffffffffc020329e:	ab660613          	addi	a2,a2,-1354 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02032a2:	18800593          	li	a1,392
ffffffffc02032a6:	00004517          	auipc	a0,0x4
ffffffffc02032aa:	37a50513          	addi	a0,a0,890 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc02032ae:	9d6fd0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02032b2:	00004617          	auipc	a2,0x4
ffffffffc02032b6:	29660613          	addi	a2,a2,662 # ffffffffc0207548 <default_pmm_manager+0xb0>
ffffffffc02032ba:	06200593          	li	a1,98
ffffffffc02032be:	00004517          	auipc	a0,0x4
ffffffffc02032c2:	25250513          	addi	a0,a0,594 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc02032c6:	9befd0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02032ca:	00004617          	auipc	a2,0x4
ffffffffc02032ce:	4ee60613          	addi	a2,a2,1262 # ffffffffc02077b8 <default_pmm_manager+0x320>
ffffffffc02032d2:	07400593          	li	a1,116
ffffffffc02032d6:	00004517          	auipc	a0,0x4
ffffffffc02032da:	23a50513          	addi	a0,a0,570 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc02032de:	9a6fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02032e2:	00005697          	auipc	a3,0x5
ffffffffc02032e6:	8e668693          	addi	a3,a3,-1818 # ffffffffc0207bc8 <default_pmm_manager+0x730>
ffffffffc02032ea:	00004617          	auipc	a2,0x4
ffffffffc02032ee:	a6660613          	addi	a2,a2,-1434 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02032f2:	17200593          	li	a1,370
ffffffffc02032f6:	00004517          	auipc	a0,0x4
ffffffffc02032fa:	32a50513          	addi	a0,a0,810 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc02032fe:	986fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203302:	86ba                	mv	a3,a4
ffffffffc0203304:	00004617          	auipc	a2,0x4
ffffffffc0203308:	1e460613          	addi	a2,a2,484 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc020330c:	06900593          	li	a1,105
ffffffffc0203310:	00004517          	auipc	a0,0x4
ffffffffc0203314:	20050513          	addi	a0,a0,512 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0203318:	96cfd0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc020331c:	86ae                	mv	a3,a1
ffffffffc020331e:	00004617          	auipc	a2,0x4
ffffffffc0203322:	1ca60613          	addi	a2,a2,458 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc0203326:	06900593          	li	a1,105
ffffffffc020332a:	00004517          	auipc	a0,0x4
ffffffffc020332e:	1e650513          	addi	a0,a0,486 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0203332:	952fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0203336:	00005697          	auipc	a3,0x5
ffffffffc020333a:	86268693          	addi	a3,a3,-1950 # ffffffffc0207b98 <default_pmm_manager+0x700>
ffffffffc020333e:	00004617          	auipc	a2,0x4
ffffffffc0203342:	a1260613          	addi	a2,a2,-1518 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203346:	17100593          	li	a1,369
ffffffffc020334a:	00004517          	auipc	a0,0x4
ffffffffc020334e:	2d650513          	addi	a0,a0,726 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc0203352:	932fd0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0203356 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0203356:	12058073          	sfence.vma	a1
}
ffffffffc020335a:	8082                	ret

ffffffffc020335c <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc020335c:	7179                	addi	sp,sp,-48
ffffffffc020335e:	e84a                	sd	s2,16(sp)
ffffffffc0203360:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc0203362:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc0203364:	f022                	sd	s0,32(sp)
ffffffffc0203366:	ec26                	sd	s1,24(sp)
ffffffffc0203368:	e44e                	sd	s3,8(sp)
ffffffffc020336a:	f406                	sd	ra,40(sp)
ffffffffc020336c:	84ae                	mv	s1,a1
ffffffffc020336e:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc0203370:	ae3fe0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0203374:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0203376:	cd1d                	beqz	a0,ffffffffc02033b4 <pgdir_alloc_page+0x58>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0203378:	85aa                	mv	a1,a0
ffffffffc020337a:	86ce                	mv	a3,s3
ffffffffc020337c:	8626                	mv	a2,s1
ffffffffc020337e:	854a                	mv	a0,s2
ffffffffc0203380:	9f6ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc0203384:	e121                	bnez	a0,ffffffffc02033c4 <pgdir_alloc_page+0x68>
        if (swap_init_ok) {
ffffffffc0203386:	000b4797          	auipc	a5,0xb4
ffffffffc020338a:	82278793          	addi	a5,a5,-2014 # ffffffffc02b6ba8 <swap_init_ok>
ffffffffc020338e:	439c                	lw	a5,0(a5)
ffffffffc0203390:	2781                	sext.w	a5,a5
ffffffffc0203392:	c38d                	beqz	a5,ffffffffc02033b4 <pgdir_alloc_page+0x58>
            if (check_mm_struct != NULL) {
ffffffffc0203394:	000b4797          	auipc	a5,0xb4
ffffffffc0203398:	95478793          	addi	a5,a5,-1708 # ffffffffc02b6ce8 <check_mm_struct>
ffffffffc020339c:	6388                	ld	a0,0(a5)
ffffffffc020339e:	c919                	beqz	a0,ffffffffc02033b4 <pgdir_alloc_page+0x58>
                swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc02033a0:	4681                	li	a3,0
ffffffffc02033a2:	8622                	mv	a2,s0
ffffffffc02033a4:	85a6                	mv	a1,s1
ffffffffc02033a6:	7da000ef          	jal	ra,ffffffffc0203b80 <swap_map_swappable>
                assert(page_ref(page) == 1);
ffffffffc02033aa:	4018                	lw	a4,0(s0)
                page->pra_vaddr = la;
ffffffffc02033ac:	fc04                	sd	s1,56(s0)
                assert(page_ref(page) == 1);
ffffffffc02033ae:	4785                	li	a5,1
ffffffffc02033b0:	02f71063          	bne	a4,a5,ffffffffc02033d0 <pgdir_alloc_page+0x74>
}
ffffffffc02033b4:	8522                	mv	a0,s0
ffffffffc02033b6:	70a2                	ld	ra,40(sp)
ffffffffc02033b8:	7402                	ld	s0,32(sp)
ffffffffc02033ba:	64e2                	ld	s1,24(sp)
ffffffffc02033bc:	6942                	ld	s2,16(sp)
ffffffffc02033be:	69a2                	ld	s3,8(sp)
ffffffffc02033c0:	6145                	addi	sp,sp,48
ffffffffc02033c2:	8082                	ret
            free_page(page);
ffffffffc02033c4:	8522                	mv	a0,s0
ffffffffc02033c6:	4585                	li	a1,1
ffffffffc02033c8:	b13fe0ef          	jal	ra,ffffffffc0201eda <free_pages>
            return NULL;
ffffffffc02033cc:	4401                	li	s0,0
ffffffffc02033ce:	b7dd                	j	ffffffffc02033b4 <pgdir_alloc_page+0x58>
                assert(page_ref(page) == 1);
ffffffffc02033d0:	00004697          	auipc	a3,0x4
ffffffffc02033d4:	26068693          	addi	a3,a3,608 # ffffffffc0207630 <default_pmm_manager+0x198>
ffffffffc02033d8:	00004617          	auipc	a2,0x4
ffffffffc02033dc:	97860613          	addi	a2,a2,-1672 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02033e0:	1ee00593          	li	a1,494
ffffffffc02033e4:	00004517          	auipc	a0,0x4
ffffffffc02033e8:	23c50513          	addi	a0,a0,572 # ffffffffc0207620 <default_pmm_manager+0x188>
ffffffffc02033ec:	898fd0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02033f0 <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc02033f0:	7135                	addi	sp,sp,-160
ffffffffc02033f2:	ed06                	sd	ra,152(sp)
ffffffffc02033f4:	e922                	sd	s0,144(sp)
ffffffffc02033f6:	e526                	sd	s1,136(sp)
ffffffffc02033f8:	e14a                	sd	s2,128(sp)
ffffffffc02033fa:	fcce                	sd	s3,120(sp)
ffffffffc02033fc:	f8d2                	sd	s4,112(sp)
ffffffffc02033fe:	f4d6                	sd	s5,104(sp)
ffffffffc0203400:	f0da                	sd	s6,96(sp)
ffffffffc0203402:	ecde                	sd	s7,88(sp)
ffffffffc0203404:	e8e2                	sd	s8,80(sp)
ffffffffc0203406:	e4e6                	sd	s9,72(sp)
ffffffffc0203408:	e0ea                	sd	s10,64(sp)
ffffffffc020340a:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc020340c:	0d1010ef          	jal	ra,ffffffffc0204cdc <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc0203410:	000b4797          	auipc	a5,0xb4
ffffffffc0203414:	88878793          	addi	a5,a5,-1912 # ffffffffc02b6c98 <max_swap_offset>
ffffffffc0203418:	6394                	ld	a3,0(a5)
ffffffffc020341a:	010007b7          	lui	a5,0x1000
ffffffffc020341e:	17e1                	addi	a5,a5,-8
ffffffffc0203420:	ff968713          	addi	a4,a3,-7
ffffffffc0203424:	4ae7ee63          	bltu	a5,a4,ffffffffc02038e0 <swap_init+0x4f0>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }
     

     sm = &swap_manager_fifo;
ffffffffc0203428:	000a8797          	auipc	a5,0xa8
ffffffffc020342c:	30078793          	addi	a5,a5,768 # ffffffffc02ab728 <swap_manager_fifo>
     int r = sm->init();
ffffffffc0203430:	6798                	ld	a4,8(a5)
     sm = &swap_manager_fifo;
ffffffffc0203432:	000b3697          	auipc	a3,0xb3
ffffffffc0203436:	76f6b723          	sd	a5,1902(a3) # ffffffffc02b6ba0 <sm>
     int r = sm->init();
ffffffffc020343a:	9702                	jalr	a4
ffffffffc020343c:	8aaa                	mv	s5,a0
     
     if (r == 0)
ffffffffc020343e:	c10d                	beqz	a0,ffffffffc0203460 <swap_init+0x70>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc0203440:	60ea                	ld	ra,152(sp)
ffffffffc0203442:	644a                	ld	s0,144(sp)
ffffffffc0203444:	8556                	mv	a0,s5
ffffffffc0203446:	64aa                	ld	s1,136(sp)
ffffffffc0203448:	690a                	ld	s2,128(sp)
ffffffffc020344a:	79e6                	ld	s3,120(sp)
ffffffffc020344c:	7a46                	ld	s4,112(sp)
ffffffffc020344e:	7aa6                	ld	s5,104(sp)
ffffffffc0203450:	7b06                	ld	s6,96(sp)
ffffffffc0203452:	6be6                	ld	s7,88(sp)
ffffffffc0203454:	6c46                	ld	s8,80(sp)
ffffffffc0203456:	6ca6                	ld	s9,72(sp)
ffffffffc0203458:	6d06                	ld	s10,64(sp)
ffffffffc020345a:	7de2                	ld	s11,56(sp)
ffffffffc020345c:	610d                	addi	sp,sp,160
ffffffffc020345e:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0203460:	000b3797          	auipc	a5,0xb3
ffffffffc0203464:	74078793          	addi	a5,a5,1856 # ffffffffc02b6ba0 <sm>
ffffffffc0203468:	639c                	ld	a5,0(a5)
ffffffffc020346a:	00004517          	auipc	a0,0x4
ffffffffc020346e:	7f650513          	addi	a0,a0,2038 # ffffffffc0207c60 <default_pmm_manager+0x7c8>
    return listelm->next;
ffffffffc0203472:	000b3417          	auipc	s0,0xb3
ffffffffc0203476:	76640413          	addi	s0,s0,1894 # ffffffffc02b6bd8 <free_area>
ffffffffc020347a:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc020347c:	4785                	li	a5,1
ffffffffc020347e:	000b3717          	auipc	a4,0xb3
ffffffffc0203482:	72f72523          	sw	a5,1834(a4) # ffffffffc02b6ba8 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0203486:	d09fc0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc020348a:	641c                	ld	a5,8(s0)
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc020348c:	36878e63          	beq	a5,s0,ffffffffc0203808 <swap_init+0x418>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0203490:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203494:	8305                	srli	a4,a4,0x1
ffffffffc0203496:	8b05                	andi	a4,a4,1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0203498:	36070c63          	beqz	a4,ffffffffc0203810 <swap_init+0x420>
     int ret, count = 0, total = 0, i;
ffffffffc020349c:	4481                	li	s1,0
ffffffffc020349e:	4901                	li	s2,0
ffffffffc02034a0:	a031                	j	ffffffffc02034ac <swap_init+0xbc>
ffffffffc02034a2:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc02034a6:	8b09                	andi	a4,a4,2
ffffffffc02034a8:	36070463          	beqz	a4,ffffffffc0203810 <swap_init+0x420>
        count ++, total += p->property;
ffffffffc02034ac:	ff87a703          	lw	a4,-8(a5)
ffffffffc02034b0:	679c                	ld	a5,8(a5)
ffffffffc02034b2:	2905                	addiw	s2,s2,1
ffffffffc02034b4:	9cb9                	addw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc02034b6:	fe8796e3          	bne	a5,s0,ffffffffc02034a2 <swap_init+0xb2>
ffffffffc02034ba:	89a6                	mv	s3,s1
     }
     assert(total == nr_free_pages());
ffffffffc02034bc:	a65fe0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
ffffffffc02034c0:	69351863          	bne	a0,s3,ffffffffc0203b50 <swap_init+0x760>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc02034c4:	8626                	mv	a2,s1
ffffffffc02034c6:	85ca                	mv	a1,s2
ffffffffc02034c8:	00004517          	auipc	a0,0x4
ffffffffc02034cc:	7b050513          	addi	a0,a0,1968 # ffffffffc0207c78 <default_pmm_manager+0x7e0>
ffffffffc02034d0:	cbffc0ef          	jal	ra,ffffffffc020018e <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc02034d4:	457000ef          	jal	ra,ffffffffc020412a <mm_create>
ffffffffc02034d8:	8baa                	mv	s7,a0
     assert(mm != NULL);
ffffffffc02034da:	60050b63          	beqz	a0,ffffffffc0203af0 <swap_init+0x700>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc02034de:	000b4797          	auipc	a5,0xb4
ffffffffc02034e2:	80a78793          	addi	a5,a5,-2038 # ffffffffc02b6ce8 <check_mm_struct>
ffffffffc02034e6:	639c                	ld	a5,0(a5)
ffffffffc02034e8:	62079463          	bnez	a5,ffffffffc0203b10 <swap_init+0x720>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc02034ec:	000b3797          	auipc	a5,0xb3
ffffffffc02034f0:	6a478793          	addi	a5,a5,1700 # ffffffffc02b6b90 <boot_pgdir>
ffffffffc02034f4:	0007bb03          	ld	s6,0(a5)
     check_mm_struct = mm;
ffffffffc02034f8:	000b3797          	auipc	a5,0xb3
ffffffffc02034fc:	7ea7b823          	sd	a0,2032(a5) # ffffffffc02b6ce8 <check_mm_struct>
     assert(pgdir[0] == 0);
ffffffffc0203500:	000b3783          	ld	a5,0(s6)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203504:	01653c23          	sd	s6,24(a0)
     assert(pgdir[0] == 0);
ffffffffc0203508:	4e079863          	bnez	a5,ffffffffc02039f8 <swap_init+0x608>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc020350c:	6599                	lui	a1,0x6
ffffffffc020350e:	460d                	li	a2,3
ffffffffc0203510:	6505                	lui	a0,0x1
ffffffffc0203512:	465000ef          	jal	ra,ffffffffc0204176 <vma_create>
ffffffffc0203516:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc0203518:	50050063          	beqz	a0,ffffffffc0203a18 <swap_init+0x628>

     insert_vma_struct(mm, vma);
ffffffffc020351c:	855e                	mv	a0,s7
ffffffffc020351e:	4c5000ef          	jal	ra,ffffffffc02041e2 <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc0203522:	00004517          	auipc	a0,0x4
ffffffffc0203526:	7c650513          	addi	a0,a0,1990 # ffffffffc0207ce8 <default_pmm_manager+0x850>
ffffffffc020352a:	c65fc0ef          	jal	ra,ffffffffc020018e <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc020352e:	018bb503          	ld	a0,24(s7)
ffffffffc0203532:	4605                	li	a2,1
ffffffffc0203534:	6585                	lui	a1,0x1
ffffffffc0203536:	a2bfe0ef          	jal	ra,ffffffffc0201f60 <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc020353a:	4e050f63          	beqz	a0,ffffffffc0203a38 <swap_init+0x648>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc020353e:	00004517          	auipc	a0,0x4
ffffffffc0203542:	7fa50513          	addi	a0,a0,2042 # ffffffffc0207d38 <default_pmm_manager+0x8a0>
ffffffffc0203546:	000b3997          	auipc	s3,0xb3
ffffffffc020354a:	6ca98993          	addi	s3,s3,1738 # ffffffffc02b6c10 <check_rp>
ffffffffc020354e:	c41fc0ef          	jal	ra,ffffffffc020018e <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203552:	000b3a17          	auipc	s4,0xb3
ffffffffc0203556:	6dea0a13          	addi	s4,s4,1758 # ffffffffc02b6c30 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc020355a:	8c4e                	mv	s8,s3
          check_rp[i] = alloc_page();
ffffffffc020355c:	4505                	li	a0,1
ffffffffc020355e:	8f5fe0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0203562:	00ac3023          	sd	a0,0(s8) # 80000 <_binary_obj___user_exit_out_size+0x75570>
          assert(check_rp[i] != NULL );
ffffffffc0203566:	32050d63          	beqz	a0,ffffffffc02038a0 <swap_init+0x4b0>
ffffffffc020356a:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc020356c:	8b89                	andi	a5,a5,2
ffffffffc020356e:	30079963          	bnez	a5,ffffffffc0203880 <swap_init+0x490>
ffffffffc0203572:	0c21                	addi	s8,s8,8
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203574:	ff4c14e3          	bne	s8,s4,ffffffffc020355c <swap_init+0x16c>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0203578:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc020357a:	000b3c17          	auipc	s8,0xb3
ffffffffc020357e:	696c0c13          	addi	s8,s8,1686 # ffffffffc02b6c10 <check_rp>
     list_entry_t free_list_store = free_list;
ffffffffc0203582:	ec3e                	sd	a5,24(sp)
ffffffffc0203584:	641c                	ld	a5,8(s0)
ffffffffc0203586:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc0203588:	481c                	lw	a5,16(s0)
ffffffffc020358a:	f43e                	sd	a5,40(sp)
    elm->prev = elm->next = elm;
ffffffffc020358c:	000b3797          	auipc	a5,0xb3
ffffffffc0203590:	6487ba23          	sd	s0,1620(a5) # ffffffffc02b6be0 <free_area+0x8>
ffffffffc0203594:	000b3797          	auipc	a5,0xb3
ffffffffc0203598:	6487b223          	sd	s0,1604(a5) # ffffffffc02b6bd8 <free_area>
     nr_free = 0;
ffffffffc020359c:	000b3797          	auipc	a5,0xb3
ffffffffc02035a0:	6407a623          	sw	zero,1612(a5) # ffffffffc02b6be8 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc02035a4:	000c3503          	ld	a0,0(s8)
ffffffffc02035a8:	4585                	li	a1,1
ffffffffc02035aa:	0c21                	addi	s8,s8,8
ffffffffc02035ac:	92ffe0ef          	jal	ra,ffffffffc0201eda <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02035b0:	ff4c1ae3          	bne	s8,s4,ffffffffc02035a4 <swap_init+0x1b4>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc02035b4:	01042c03          	lw	s8,16(s0)
ffffffffc02035b8:	4791                	li	a5,4
ffffffffc02035ba:	50fc1b63          	bne	s8,a5,ffffffffc0203ad0 <swap_init+0x6e0>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc02035be:	00005517          	auipc	a0,0x5
ffffffffc02035c2:	80250513          	addi	a0,a0,-2046 # ffffffffc0207dc0 <default_pmm_manager+0x928>
ffffffffc02035c6:	bc9fc0ef          	jal	ra,ffffffffc020018e <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc02035ca:	6685                	lui	a3,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc02035cc:	000b3797          	auipc	a5,0xb3
ffffffffc02035d0:	5e07a023          	sw	zero,1504(a5) # ffffffffc02b6bac <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc02035d4:	4629                	li	a2,10
     pgfault_num=0;
ffffffffc02035d6:	000b3797          	auipc	a5,0xb3
ffffffffc02035da:	5d678793          	addi	a5,a5,1494 # ffffffffc02b6bac <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc02035de:	00c68023          	sb	a2,0(a3) # 1000 <_binary_obj___user_faultread_out_size-0x8580>
     assert(pgfault_num==1);
ffffffffc02035e2:	4398                	lw	a4,0(a5)
ffffffffc02035e4:	4585                	li	a1,1
ffffffffc02035e6:	2701                	sext.w	a4,a4
ffffffffc02035e8:	38b71863          	bne	a4,a1,ffffffffc0203978 <swap_init+0x588>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc02035ec:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==1);
ffffffffc02035f0:	4394                	lw	a3,0(a5)
ffffffffc02035f2:	2681                	sext.w	a3,a3
ffffffffc02035f4:	3ae69263          	bne	a3,a4,ffffffffc0203998 <swap_init+0x5a8>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc02035f8:	6689                	lui	a3,0x2
ffffffffc02035fa:	462d                	li	a2,11
ffffffffc02035fc:	00c68023          	sb	a2,0(a3) # 2000 <_binary_obj___user_faultread_out_size-0x7580>
     assert(pgfault_num==2);
ffffffffc0203600:	4398                	lw	a4,0(a5)
ffffffffc0203602:	4589                	li	a1,2
ffffffffc0203604:	2701                	sext.w	a4,a4
ffffffffc0203606:	2eb71963          	bne	a4,a1,ffffffffc02038f8 <swap_init+0x508>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc020360a:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc020360e:	4394                	lw	a3,0(a5)
ffffffffc0203610:	2681                	sext.w	a3,a3
ffffffffc0203612:	30e69363          	bne	a3,a4,ffffffffc0203918 <swap_init+0x528>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203616:	668d                	lui	a3,0x3
ffffffffc0203618:	4631                	li	a2,12
ffffffffc020361a:	00c68023          	sb	a2,0(a3) # 3000 <_binary_obj___user_faultread_out_size-0x6580>
     assert(pgfault_num==3);
ffffffffc020361e:	4398                	lw	a4,0(a5)
ffffffffc0203620:	458d                	li	a1,3
ffffffffc0203622:	2701                	sext.w	a4,a4
ffffffffc0203624:	30b71a63          	bne	a4,a1,ffffffffc0203938 <swap_init+0x548>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc0203628:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc020362c:	4394                	lw	a3,0(a5)
ffffffffc020362e:	2681                	sext.w	a3,a3
ffffffffc0203630:	32e69463          	bne	a3,a4,ffffffffc0203958 <swap_init+0x568>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203634:	6691                	lui	a3,0x4
ffffffffc0203636:	4635                	li	a2,13
ffffffffc0203638:	00c68023          	sb	a2,0(a3) # 4000 <_binary_obj___user_faultread_out_size-0x5580>
     assert(pgfault_num==4);
ffffffffc020363c:	4398                	lw	a4,0(a5)
ffffffffc020363e:	2701                	sext.w	a4,a4
ffffffffc0203640:	37871c63          	bne	a4,s8,ffffffffc02039b8 <swap_init+0x5c8>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc0203644:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc0203648:	439c                	lw	a5,0(a5)
ffffffffc020364a:	2781                	sext.w	a5,a5
ffffffffc020364c:	38e79663          	bne	a5,a4,ffffffffc02039d8 <swap_init+0x5e8>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc0203650:	481c                	lw	a5,16(s0)
ffffffffc0203652:	40079363          	bnez	a5,ffffffffc0203a58 <swap_init+0x668>
ffffffffc0203656:	000b3797          	auipc	a5,0xb3
ffffffffc020365a:	5da78793          	addi	a5,a5,1498 # ffffffffc02b6c30 <swap_in_seq_no>
ffffffffc020365e:	000b3717          	auipc	a4,0xb3
ffffffffc0203662:	5fa70713          	addi	a4,a4,1530 # ffffffffc02b6c58 <swap_out_seq_no>
ffffffffc0203666:	000b3617          	auipc	a2,0xb3
ffffffffc020366a:	5f260613          	addi	a2,a2,1522 # ffffffffc02b6c58 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc020366e:	56fd                	li	a3,-1
ffffffffc0203670:	c394                	sw	a3,0(a5)
ffffffffc0203672:	c314                	sw	a3,0(a4)
ffffffffc0203674:	0791                	addi	a5,a5,4
ffffffffc0203676:	0711                	addi	a4,a4,4
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0203678:	fef61ce3          	bne	a2,a5,ffffffffc0203670 <swap_init+0x280>
ffffffffc020367c:	000b3697          	auipc	a3,0xb3
ffffffffc0203680:	63c68693          	addi	a3,a3,1596 # ffffffffc02b6cb8 <check_ptep>
ffffffffc0203684:	000b3817          	auipc	a6,0xb3
ffffffffc0203688:	58c80813          	addi	a6,a6,1420 # ffffffffc02b6c10 <check_rp>
ffffffffc020368c:	6d05                	lui	s10,0x1
    if (PPN(pa) >= npage) {
ffffffffc020368e:	000b3c97          	auipc	s9,0xb3
ffffffffc0203692:	50ac8c93          	addi	s9,s9,1290 # ffffffffc02b6b98 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203696:	00006d97          	auipc	s11,0x6
ffffffffc020369a:	81ad8d93          	addi	s11,s11,-2022 # ffffffffc0208eb0 <nbase>
ffffffffc020369e:	000b3c17          	auipc	s8,0xb3
ffffffffc02036a2:	56ac0c13          	addi	s8,s8,1386 # ffffffffc02b6c08 <pages>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc02036a6:	0006b023          	sd	zero,0(a3)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc02036aa:	4601                	li	a2,0
ffffffffc02036ac:	85ea                	mv	a1,s10
ffffffffc02036ae:	855a                	mv	a0,s6
ffffffffc02036b0:	e842                	sd	a6,16(sp)
         check_ptep[i]=0;
ffffffffc02036b2:	e436                	sd	a3,8(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc02036b4:	8adfe0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc02036b8:	66a2                	ld	a3,8(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc02036ba:	6842                	ld	a6,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc02036bc:	e288                	sd	a0,0(a3)
         assert(check_ptep[i] != NULL);
ffffffffc02036be:	20050163          	beqz	a0,ffffffffc02038c0 <swap_init+0x4d0>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc02036c2:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02036c4:	0017f613          	andi	a2,a5,1
ffffffffc02036c8:	1a060063          	beqz	a2,ffffffffc0203868 <swap_init+0x478>
    if (PPN(pa) >= npage) {
ffffffffc02036cc:	000cb603          	ld	a2,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc02036d0:	078a                	slli	a5,a5,0x2
ffffffffc02036d2:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02036d4:	14c7fe63          	bleu	a2,a5,ffffffffc0203830 <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc02036d8:	000db703          	ld	a4,0(s11)
ffffffffc02036dc:	000c3603          	ld	a2,0(s8)
ffffffffc02036e0:	00083583          	ld	a1,0(a6)
ffffffffc02036e4:	8f99                	sub	a5,a5,a4
ffffffffc02036e6:	079a                	slli	a5,a5,0x6
ffffffffc02036e8:	e43a                	sd	a4,8(sp)
ffffffffc02036ea:	97b2                	add	a5,a5,a2
ffffffffc02036ec:	14f59e63          	bne	a1,a5,ffffffffc0203848 <swap_init+0x458>
ffffffffc02036f0:	6785                	lui	a5,0x1
ffffffffc02036f2:	9d3e                	add	s10,s10,a5
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02036f4:	6795                	lui	a5,0x5
ffffffffc02036f6:	06a1                	addi	a3,a3,8
ffffffffc02036f8:	0821                	addi	a6,a6,8
ffffffffc02036fa:	fafd16e3          	bne	s10,a5,ffffffffc02036a6 <swap_init+0x2b6>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc02036fe:	00004517          	auipc	a0,0x4
ffffffffc0203702:	76a50513          	addi	a0,a0,1898 # ffffffffc0207e68 <default_pmm_manager+0x9d0>
ffffffffc0203706:	a89fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    int ret = sm->check_swap();
ffffffffc020370a:	000b3797          	auipc	a5,0xb3
ffffffffc020370e:	49678793          	addi	a5,a5,1174 # ffffffffc02b6ba0 <sm>
ffffffffc0203712:	639c                	ld	a5,0(a5)
ffffffffc0203714:	7f9c                	ld	a5,56(a5)
ffffffffc0203716:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc0203718:	40051c63          	bnez	a0,ffffffffc0203b30 <swap_init+0x740>

     nr_free = nr_free_store;
ffffffffc020371c:	77a2                	ld	a5,40(sp)
ffffffffc020371e:	000b3717          	auipc	a4,0xb3
ffffffffc0203722:	4cf72523          	sw	a5,1226(a4) # ffffffffc02b6be8 <free_area+0x10>
     free_list = free_list_store;
ffffffffc0203726:	67e2                	ld	a5,24(sp)
ffffffffc0203728:	000b3717          	auipc	a4,0xb3
ffffffffc020372c:	4af73823          	sd	a5,1200(a4) # ffffffffc02b6bd8 <free_area>
ffffffffc0203730:	7782                	ld	a5,32(sp)
ffffffffc0203732:	000b3717          	auipc	a4,0xb3
ffffffffc0203736:	4af73723          	sd	a5,1198(a4) # ffffffffc02b6be0 <free_area+0x8>

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc020373a:	0009b503          	ld	a0,0(s3)
ffffffffc020373e:	4585                	li	a1,1
ffffffffc0203740:	09a1                	addi	s3,s3,8
ffffffffc0203742:	f98fe0ef          	jal	ra,ffffffffc0201eda <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203746:	ff499ae3          	bne	s3,s4,ffffffffc020373a <swap_init+0x34a>
     } 

     //free_page(pte2page(*temp_ptep));

     mm->pgdir = NULL;
ffffffffc020374a:	000bbc23          	sd	zero,24(s7)
     mm_destroy(mm);
ffffffffc020374e:	855e                	mv	a0,s7
ffffffffc0203750:	361000ef          	jal	ra,ffffffffc02042b0 <mm_destroy>
     check_mm_struct = NULL;

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0203754:	000b3797          	auipc	a5,0xb3
ffffffffc0203758:	43c78793          	addi	a5,a5,1084 # ffffffffc02b6b90 <boot_pgdir>
ffffffffc020375c:	639c                	ld	a5,0(a5)
     check_mm_struct = NULL;
ffffffffc020375e:	000b3697          	auipc	a3,0xb3
ffffffffc0203762:	5806b523          	sd	zero,1418(a3) # ffffffffc02b6ce8 <check_mm_struct>
    if (PPN(pa) >= npage) {
ffffffffc0203766:	000cb703          	ld	a4,0(s9)
    return pa2page(PDE_ADDR(pde));
ffffffffc020376a:	6394                	ld	a3,0(a5)
ffffffffc020376c:	068a                	slli	a3,a3,0x2
ffffffffc020376e:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203770:	0ce6f063          	bleu	a4,a3,ffffffffc0203830 <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203774:	67a2                	ld	a5,8(sp)
ffffffffc0203776:	000c3503          	ld	a0,0(s8)
ffffffffc020377a:	8e9d                	sub	a3,a3,a5
ffffffffc020377c:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc020377e:	8699                	srai	a3,a3,0x6
ffffffffc0203780:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0203782:	57fd                	li	a5,-1
ffffffffc0203784:	83b1                	srli	a5,a5,0xc
ffffffffc0203786:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0203788:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020378a:	2ee7f763          	bleu	a4,a5,ffffffffc0203a78 <swap_init+0x688>
     free_page(pde2page(pd0[0]));
ffffffffc020378e:	000b3797          	auipc	a5,0xb3
ffffffffc0203792:	46a78793          	addi	a5,a5,1130 # ffffffffc02b6bf8 <va_pa_offset>
ffffffffc0203796:	639c                	ld	a5,0(a5)
ffffffffc0203798:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020379a:	629c                	ld	a5,0(a3)
ffffffffc020379c:	078a                	slli	a5,a5,0x2
ffffffffc020379e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02037a0:	08e7f863          	bleu	a4,a5,ffffffffc0203830 <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc02037a4:	69a2                	ld	s3,8(sp)
ffffffffc02037a6:	4585                	li	a1,1
ffffffffc02037a8:	413787b3          	sub	a5,a5,s3
ffffffffc02037ac:	079a                	slli	a5,a5,0x6
ffffffffc02037ae:	953e                	add	a0,a0,a5
ffffffffc02037b0:	f2afe0ef          	jal	ra,ffffffffc0201eda <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc02037b4:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc02037b8:	000cb703          	ld	a4,0(s9)
    return pa2page(PDE_ADDR(pde));
ffffffffc02037bc:	078a                	slli	a5,a5,0x2
ffffffffc02037be:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02037c0:	06e7f863          	bleu	a4,a5,ffffffffc0203830 <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc02037c4:	000c3503          	ld	a0,0(s8)
ffffffffc02037c8:	413787b3          	sub	a5,a5,s3
ffffffffc02037cc:	079a                	slli	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc02037ce:	4585                	li	a1,1
ffffffffc02037d0:	953e                	add	a0,a0,a5
ffffffffc02037d2:	f08fe0ef          	jal	ra,ffffffffc0201eda <free_pages>
     pgdir[0] = 0;
ffffffffc02037d6:	000b3023          	sd	zero,0(s6)
  asm volatile("sfence.vma");
ffffffffc02037da:	12000073          	sfence.vma
    return listelm->next;
ffffffffc02037de:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc02037e0:	00878963          	beq	a5,s0,ffffffffc02037f2 <swap_init+0x402>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc02037e4:	ff87a703          	lw	a4,-8(a5)
ffffffffc02037e8:	679c                	ld	a5,8(a5)
ffffffffc02037ea:	397d                	addiw	s2,s2,-1
ffffffffc02037ec:	9c99                	subw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc02037ee:	fe879be3          	bne	a5,s0,ffffffffc02037e4 <swap_init+0x3f4>
     }
     assert(count==0);
ffffffffc02037f2:	28091f63          	bnez	s2,ffffffffc0203a90 <swap_init+0x6a0>
     assert(total==0);
ffffffffc02037f6:	2a049d63          	bnez	s1,ffffffffc0203ab0 <swap_init+0x6c0>

     cprintf("check_swap() succeeded!\n");
ffffffffc02037fa:	00004517          	auipc	a0,0x4
ffffffffc02037fe:	6be50513          	addi	a0,a0,1726 # ffffffffc0207eb8 <default_pmm_manager+0xa20>
ffffffffc0203802:	98dfc0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc0203806:	b92d                	j	ffffffffc0203440 <swap_init+0x50>
     int ret, count = 0, total = 0, i;
ffffffffc0203808:	4481                	li	s1,0
ffffffffc020380a:	4901                	li	s2,0
     while ((le = list_next(le)) != &free_list) {
ffffffffc020380c:	4981                	li	s3,0
ffffffffc020380e:	b17d                	j	ffffffffc02034bc <swap_init+0xcc>
        assert(PageProperty(p));
ffffffffc0203810:	00004697          	auipc	a3,0x4
ffffffffc0203814:	8f868693          	addi	a3,a3,-1800 # ffffffffc0207108 <commands+0x878>
ffffffffc0203818:	00003617          	auipc	a2,0x3
ffffffffc020381c:	53860613          	addi	a2,a2,1336 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203820:	0bc00593          	li	a1,188
ffffffffc0203824:	00004517          	auipc	a0,0x4
ffffffffc0203828:	42c50513          	addi	a0,a0,1068 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc020382c:	c59fc0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203830:	00004617          	auipc	a2,0x4
ffffffffc0203834:	d1860613          	addi	a2,a2,-744 # ffffffffc0207548 <default_pmm_manager+0xb0>
ffffffffc0203838:	06200593          	li	a1,98
ffffffffc020383c:	00004517          	auipc	a0,0x4
ffffffffc0203840:	cd450513          	addi	a0,a0,-812 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0203844:	c41fc0ef          	jal	ra,ffffffffc0200484 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0203848:	00004697          	auipc	a3,0x4
ffffffffc020384c:	5f868693          	addi	a3,a3,1528 # ffffffffc0207e40 <default_pmm_manager+0x9a8>
ffffffffc0203850:	00003617          	auipc	a2,0x3
ffffffffc0203854:	50060613          	addi	a2,a2,1280 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203858:	0fc00593          	li	a1,252
ffffffffc020385c:	00004517          	auipc	a0,0x4
ffffffffc0203860:	3f450513          	addi	a0,a0,1012 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203864:	c21fc0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0203868:	00004617          	auipc	a2,0x4
ffffffffc020386c:	f5060613          	addi	a2,a2,-176 # ffffffffc02077b8 <default_pmm_manager+0x320>
ffffffffc0203870:	07400593          	li	a1,116
ffffffffc0203874:	00004517          	auipc	a0,0x4
ffffffffc0203878:	c9c50513          	addi	a0,a0,-868 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc020387c:	c09fc0ef          	jal	ra,ffffffffc0200484 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0203880:	00004697          	auipc	a3,0x4
ffffffffc0203884:	4f868693          	addi	a3,a3,1272 # ffffffffc0207d78 <default_pmm_manager+0x8e0>
ffffffffc0203888:	00003617          	auipc	a2,0x3
ffffffffc020388c:	4c860613          	addi	a2,a2,1224 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203890:	0dd00593          	li	a1,221
ffffffffc0203894:	00004517          	auipc	a0,0x4
ffffffffc0203898:	3bc50513          	addi	a0,a0,956 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc020389c:	be9fc0ef          	jal	ra,ffffffffc0200484 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc02038a0:	00004697          	auipc	a3,0x4
ffffffffc02038a4:	4c068693          	addi	a3,a3,1216 # ffffffffc0207d60 <default_pmm_manager+0x8c8>
ffffffffc02038a8:	00003617          	auipc	a2,0x3
ffffffffc02038ac:	4a860613          	addi	a2,a2,1192 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02038b0:	0dc00593          	li	a1,220
ffffffffc02038b4:	00004517          	auipc	a0,0x4
ffffffffc02038b8:	39c50513          	addi	a0,a0,924 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc02038bc:	bc9fc0ef          	jal	ra,ffffffffc0200484 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc02038c0:	00004697          	auipc	a3,0x4
ffffffffc02038c4:	56868693          	addi	a3,a3,1384 # ffffffffc0207e28 <default_pmm_manager+0x990>
ffffffffc02038c8:	00003617          	auipc	a2,0x3
ffffffffc02038cc:	48860613          	addi	a2,a2,1160 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02038d0:	0fb00593          	li	a1,251
ffffffffc02038d4:	00004517          	auipc	a0,0x4
ffffffffc02038d8:	37c50513          	addi	a0,a0,892 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc02038dc:	ba9fc0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc02038e0:	00004617          	auipc	a2,0x4
ffffffffc02038e4:	35060613          	addi	a2,a2,848 # ffffffffc0207c30 <default_pmm_manager+0x798>
ffffffffc02038e8:	02800593          	li	a1,40
ffffffffc02038ec:	00004517          	auipc	a0,0x4
ffffffffc02038f0:	36450513          	addi	a0,a0,868 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc02038f4:	b91fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==2);
ffffffffc02038f8:	00004697          	auipc	a3,0x4
ffffffffc02038fc:	50068693          	addi	a3,a3,1280 # ffffffffc0207df8 <default_pmm_manager+0x960>
ffffffffc0203900:	00003617          	auipc	a2,0x3
ffffffffc0203904:	45060613          	addi	a2,a2,1104 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203908:	09700593          	li	a1,151
ffffffffc020390c:	00004517          	auipc	a0,0x4
ffffffffc0203910:	34450513          	addi	a0,a0,836 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203914:	b71fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==2);
ffffffffc0203918:	00004697          	auipc	a3,0x4
ffffffffc020391c:	4e068693          	addi	a3,a3,1248 # ffffffffc0207df8 <default_pmm_manager+0x960>
ffffffffc0203920:	00003617          	auipc	a2,0x3
ffffffffc0203924:	43060613          	addi	a2,a2,1072 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203928:	09900593          	li	a1,153
ffffffffc020392c:	00004517          	auipc	a0,0x4
ffffffffc0203930:	32450513          	addi	a0,a0,804 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203934:	b51fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==3);
ffffffffc0203938:	00004697          	auipc	a3,0x4
ffffffffc020393c:	4d068693          	addi	a3,a3,1232 # ffffffffc0207e08 <default_pmm_manager+0x970>
ffffffffc0203940:	00003617          	auipc	a2,0x3
ffffffffc0203944:	41060613          	addi	a2,a2,1040 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203948:	09b00593          	li	a1,155
ffffffffc020394c:	00004517          	auipc	a0,0x4
ffffffffc0203950:	30450513          	addi	a0,a0,772 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203954:	b31fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==3);
ffffffffc0203958:	00004697          	auipc	a3,0x4
ffffffffc020395c:	4b068693          	addi	a3,a3,1200 # ffffffffc0207e08 <default_pmm_manager+0x970>
ffffffffc0203960:	00003617          	auipc	a2,0x3
ffffffffc0203964:	3f060613          	addi	a2,a2,1008 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203968:	09d00593          	li	a1,157
ffffffffc020396c:	00004517          	auipc	a0,0x4
ffffffffc0203970:	2e450513          	addi	a0,a0,740 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203974:	b11fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==1);
ffffffffc0203978:	00004697          	auipc	a3,0x4
ffffffffc020397c:	47068693          	addi	a3,a3,1136 # ffffffffc0207de8 <default_pmm_manager+0x950>
ffffffffc0203980:	00003617          	auipc	a2,0x3
ffffffffc0203984:	3d060613          	addi	a2,a2,976 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203988:	09300593          	li	a1,147
ffffffffc020398c:	00004517          	auipc	a0,0x4
ffffffffc0203990:	2c450513          	addi	a0,a0,708 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203994:	af1fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==1);
ffffffffc0203998:	00004697          	auipc	a3,0x4
ffffffffc020399c:	45068693          	addi	a3,a3,1104 # ffffffffc0207de8 <default_pmm_manager+0x950>
ffffffffc02039a0:	00003617          	auipc	a2,0x3
ffffffffc02039a4:	3b060613          	addi	a2,a2,944 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02039a8:	09500593          	li	a1,149
ffffffffc02039ac:	00004517          	auipc	a0,0x4
ffffffffc02039b0:	2a450513          	addi	a0,a0,676 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc02039b4:	ad1fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==4);
ffffffffc02039b8:	00004697          	auipc	a3,0x4
ffffffffc02039bc:	46068693          	addi	a3,a3,1120 # ffffffffc0207e18 <default_pmm_manager+0x980>
ffffffffc02039c0:	00003617          	auipc	a2,0x3
ffffffffc02039c4:	39060613          	addi	a2,a2,912 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02039c8:	09f00593          	li	a1,159
ffffffffc02039cc:	00004517          	auipc	a0,0x4
ffffffffc02039d0:	28450513          	addi	a0,a0,644 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc02039d4:	ab1fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==4);
ffffffffc02039d8:	00004697          	auipc	a3,0x4
ffffffffc02039dc:	44068693          	addi	a3,a3,1088 # ffffffffc0207e18 <default_pmm_manager+0x980>
ffffffffc02039e0:	00003617          	auipc	a2,0x3
ffffffffc02039e4:	37060613          	addi	a2,a2,880 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02039e8:	0a100593          	li	a1,161
ffffffffc02039ec:	00004517          	auipc	a0,0x4
ffffffffc02039f0:	26450513          	addi	a0,a0,612 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc02039f4:	a91fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgdir[0] == 0);
ffffffffc02039f8:	00004697          	auipc	a3,0x4
ffffffffc02039fc:	2d068693          	addi	a3,a3,720 # ffffffffc0207cc8 <default_pmm_manager+0x830>
ffffffffc0203a00:	00003617          	auipc	a2,0x3
ffffffffc0203a04:	35060613          	addi	a2,a2,848 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203a08:	0cc00593          	li	a1,204
ffffffffc0203a0c:	00004517          	auipc	a0,0x4
ffffffffc0203a10:	24450513          	addi	a0,a0,580 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203a14:	a71fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(vma != NULL);
ffffffffc0203a18:	00004697          	auipc	a3,0x4
ffffffffc0203a1c:	2c068693          	addi	a3,a3,704 # ffffffffc0207cd8 <default_pmm_manager+0x840>
ffffffffc0203a20:	00003617          	auipc	a2,0x3
ffffffffc0203a24:	33060613          	addi	a2,a2,816 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203a28:	0cf00593          	li	a1,207
ffffffffc0203a2c:	00004517          	auipc	a0,0x4
ffffffffc0203a30:	22450513          	addi	a0,a0,548 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203a34:	a51fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc0203a38:	00004697          	auipc	a3,0x4
ffffffffc0203a3c:	2e868693          	addi	a3,a3,744 # ffffffffc0207d20 <default_pmm_manager+0x888>
ffffffffc0203a40:	00003617          	auipc	a2,0x3
ffffffffc0203a44:	31060613          	addi	a2,a2,784 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203a48:	0d700593          	li	a1,215
ffffffffc0203a4c:	00004517          	auipc	a0,0x4
ffffffffc0203a50:	20450513          	addi	a0,a0,516 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203a54:	a31fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert( nr_free == 0);         
ffffffffc0203a58:	00004697          	auipc	a3,0x4
ffffffffc0203a5c:	88068693          	addi	a3,a3,-1920 # ffffffffc02072d8 <commands+0xa48>
ffffffffc0203a60:	00003617          	auipc	a2,0x3
ffffffffc0203a64:	2f060613          	addi	a2,a2,752 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203a68:	0f300593          	li	a1,243
ffffffffc0203a6c:	00004517          	auipc	a0,0x4
ffffffffc0203a70:	1e450513          	addi	a0,a0,484 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203a74:	a11fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203a78:	00004617          	auipc	a2,0x4
ffffffffc0203a7c:	a7060613          	addi	a2,a2,-1424 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc0203a80:	06900593          	li	a1,105
ffffffffc0203a84:	00004517          	auipc	a0,0x4
ffffffffc0203a88:	a8c50513          	addi	a0,a0,-1396 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0203a8c:	9f9fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(count==0);
ffffffffc0203a90:	00004697          	auipc	a3,0x4
ffffffffc0203a94:	40868693          	addi	a3,a3,1032 # ffffffffc0207e98 <default_pmm_manager+0xa00>
ffffffffc0203a98:	00003617          	auipc	a2,0x3
ffffffffc0203a9c:	2b860613          	addi	a2,a2,696 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203aa0:	11d00593          	li	a1,285
ffffffffc0203aa4:	00004517          	auipc	a0,0x4
ffffffffc0203aa8:	1ac50513          	addi	a0,a0,428 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203aac:	9d9fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(total==0);
ffffffffc0203ab0:	00004697          	auipc	a3,0x4
ffffffffc0203ab4:	3f868693          	addi	a3,a3,1016 # ffffffffc0207ea8 <default_pmm_manager+0xa10>
ffffffffc0203ab8:	00003617          	auipc	a2,0x3
ffffffffc0203abc:	29860613          	addi	a2,a2,664 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203ac0:	11e00593          	li	a1,286
ffffffffc0203ac4:	00004517          	auipc	a0,0x4
ffffffffc0203ac8:	18c50513          	addi	a0,a0,396 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203acc:	9b9fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0203ad0:	00004697          	auipc	a3,0x4
ffffffffc0203ad4:	2c868693          	addi	a3,a3,712 # ffffffffc0207d98 <default_pmm_manager+0x900>
ffffffffc0203ad8:	00003617          	auipc	a2,0x3
ffffffffc0203adc:	27860613          	addi	a2,a2,632 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203ae0:	0ea00593          	li	a1,234
ffffffffc0203ae4:	00004517          	auipc	a0,0x4
ffffffffc0203ae8:	16c50513          	addi	a0,a0,364 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203aec:	999fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(mm != NULL);
ffffffffc0203af0:	00004697          	auipc	a3,0x4
ffffffffc0203af4:	1b068693          	addi	a3,a3,432 # ffffffffc0207ca0 <default_pmm_manager+0x808>
ffffffffc0203af8:	00003617          	auipc	a2,0x3
ffffffffc0203afc:	25860613          	addi	a2,a2,600 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203b00:	0c400593          	li	a1,196
ffffffffc0203b04:	00004517          	auipc	a0,0x4
ffffffffc0203b08:	14c50513          	addi	a0,a0,332 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203b0c:	979fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0203b10:	00004697          	auipc	a3,0x4
ffffffffc0203b14:	1a068693          	addi	a3,a3,416 # ffffffffc0207cb0 <default_pmm_manager+0x818>
ffffffffc0203b18:	00003617          	auipc	a2,0x3
ffffffffc0203b1c:	23860613          	addi	a2,a2,568 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203b20:	0c700593          	li	a1,199
ffffffffc0203b24:	00004517          	auipc	a0,0x4
ffffffffc0203b28:	12c50513          	addi	a0,a0,300 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203b2c:	959fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(ret==0);
ffffffffc0203b30:	00004697          	auipc	a3,0x4
ffffffffc0203b34:	36068693          	addi	a3,a3,864 # ffffffffc0207e90 <default_pmm_manager+0x9f8>
ffffffffc0203b38:	00003617          	auipc	a2,0x3
ffffffffc0203b3c:	21860613          	addi	a2,a2,536 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203b40:	10200593          	li	a1,258
ffffffffc0203b44:	00004517          	auipc	a0,0x4
ffffffffc0203b48:	10c50513          	addi	a0,a0,268 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203b4c:	939fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(total == nr_free_pages());
ffffffffc0203b50:	00003697          	auipc	a3,0x3
ffffffffc0203b54:	5e068693          	addi	a3,a3,1504 # ffffffffc0207130 <commands+0x8a0>
ffffffffc0203b58:	00003617          	auipc	a2,0x3
ffffffffc0203b5c:	1f860613          	addi	a2,a2,504 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203b60:	0bf00593          	li	a1,191
ffffffffc0203b64:	00004517          	auipc	a0,0x4
ffffffffc0203b68:	0ec50513          	addi	a0,a0,236 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203b6c:	919fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0203b70 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0203b70:	000b3797          	auipc	a5,0xb3
ffffffffc0203b74:	03078793          	addi	a5,a5,48 # ffffffffc02b6ba0 <sm>
ffffffffc0203b78:	639c                	ld	a5,0(a5)
ffffffffc0203b7a:	0107b303          	ld	t1,16(a5)
ffffffffc0203b7e:	8302                	jr	t1

ffffffffc0203b80 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0203b80:	000b3797          	auipc	a5,0xb3
ffffffffc0203b84:	02078793          	addi	a5,a5,32 # ffffffffc02b6ba0 <sm>
ffffffffc0203b88:	639c                	ld	a5,0(a5)
ffffffffc0203b8a:	0207b303          	ld	t1,32(a5)
ffffffffc0203b8e:	8302                	jr	t1

ffffffffc0203b90 <swap_out>:
{
ffffffffc0203b90:	711d                	addi	sp,sp,-96
ffffffffc0203b92:	ec86                	sd	ra,88(sp)
ffffffffc0203b94:	e8a2                	sd	s0,80(sp)
ffffffffc0203b96:	e4a6                	sd	s1,72(sp)
ffffffffc0203b98:	e0ca                	sd	s2,64(sp)
ffffffffc0203b9a:	fc4e                	sd	s3,56(sp)
ffffffffc0203b9c:	f852                	sd	s4,48(sp)
ffffffffc0203b9e:	f456                	sd	s5,40(sp)
ffffffffc0203ba0:	f05a                	sd	s6,32(sp)
ffffffffc0203ba2:	ec5e                	sd	s7,24(sp)
ffffffffc0203ba4:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc0203ba6:	cde9                	beqz	a1,ffffffffc0203c80 <swap_out+0xf0>
ffffffffc0203ba8:	8ab2                	mv	s5,a2
ffffffffc0203baa:	892a                	mv	s2,a0
ffffffffc0203bac:	8a2e                	mv	s4,a1
ffffffffc0203bae:	4401                	li	s0,0
ffffffffc0203bb0:	000b3997          	auipc	s3,0xb3
ffffffffc0203bb4:	ff098993          	addi	s3,s3,-16 # ffffffffc02b6ba0 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203bb8:	00004b17          	auipc	s6,0x4
ffffffffc0203bbc:	380b0b13          	addi	s6,s6,896 # ffffffffc0207f38 <default_pmm_manager+0xaa0>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203bc0:	00004b97          	auipc	s7,0x4
ffffffffc0203bc4:	360b8b93          	addi	s7,s7,864 # ffffffffc0207f20 <default_pmm_manager+0xa88>
ffffffffc0203bc8:	a825                	j	ffffffffc0203c00 <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203bca:	67a2                	ld	a5,8(sp)
ffffffffc0203bcc:	8626                	mv	a2,s1
ffffffffc0203bce:	85a2                	mv	a1,s0
ffffffffc0203bd0:	7f94                	ld	a3,56(a5)
ffffffffc0203bd2:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0203bd4:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203bd6:	82b1                	srli	a3,a3,0xc
ffffffffc0203bd8:	0685                	addi	a3,a3,1
ffffffffc0203bda:	db4fc0ef          	jal	ra,ffffffffc020018e <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203bde:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc0203be0:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203be2:	7d1c                	ld	a5,56(a0)
ffffffffc0203be4:	83b1                	srli	a5,a5,0xc
ffffffffc0203be6:	0785                	addi	a5,a5,1
ffffffffc0203be8:	07a2                	slli	a5,a5,0x8
ffffffffc0203bea:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc0203bee:	aecfe0ef          	jal	ra,ffffffffc0201eda <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc0203bf2:	01893503          	ld	a0,24(s2)
ffffffffc0203bf6:	85a6                	mv	a1,s1
ffffffffc0203bf8:	f5eff0ef          	jal	ra,ffffffffc0203356 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0203bfc:	048a0d63          	beq	s4,s0,ffffffffc0203c56 <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc0203c00:	0009b783          	ld	a5,0(s3)
ffffffffc0203c04:	8656                	mv	a2,s5
ffffffffc0203c06:	002c                	addi	a1,sp,8
ffffffffc0203c08:	7b9c                	ld	a5,48(a5)
ffffffffc0203c0a:	854a                	mv	a0,s2
ffffffffc0203c0c:	9782                	jalr	a5
          if (r != 0) {
ffffffffc0203c0e:	e12d                	bnez	a0,ffffffffc0203c70 <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc0203c10:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203c12:	01893503          	ld	a0,24(s2)
ffffffffc0203c16:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc0203c18:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203c1a:	85a6                	mv	a1,s1
ffffffffc0203c1c:	b44fe0ef          	jal	ra,ffffffffc0201f60 <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203c20:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203c22:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc0203c24:	8b85                	andi	a5,a5,1
ffffffffc0203c26:	cfb9                	beqz	a5,ffffffffc0203c84 <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc0203c28:	65a2                	ld	a1,8(sp)
ffffffffc0203c2a:	7d9c                	ld	a5,56(a1)
ffffffffc0203c2c:	83b1                	srli	a5,a5,0xc
ffffffffc0203c2e:	00178513          	addi	a0,a5,1
ffffffffc0203c32:	0522                	slli	a0,a0,0x8
ffffffffc0203c34:	178010ef          	jal	ra,ffffffffc0204dac <swapfs_write>
ffffffffc0203c38:	d949                	beqz	a0,ffffffffc0203bca <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203c3a:	855e                	mv	a0,s7
ffffffffc0203c3c:	d52fc0ef          	jal	ra,ffffffffc020018e <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203c40:	0009b783          	ld	a5,0(s3)
ffffffffc0203c44:	6622                	ld	a2,8(sp)
ffffffffc0203c46:	4681                	li	a3,0
ffffffffc0203c48:	739c                	ld	a5,32(a5)
ffffffffc0203c4a:	85a6                	mv	a1,s1
ffffffffc0203c4c:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc0203c4e:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203c50:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc0203c52:	fa8a17e3          	bne	s4,s0,ffffffffc0203c00 <swap_out+0x70>
}
ffffffffc0203c56:	8522                	mv	a0,s0
ffffffffc0203c58:	60e6                	ld	ra,88(sp)
ffffffffc0203c5a:	6446                	ld	s0,80(sp)
ffffffffc0203c5c:	64a6                	ld	s1,72(sp)
ffffffffc0203c5e:	6906                	ld	s2,64(sp)
ffffffffc0203c60:	79e2                	ld	s3,56(sp)
ffffffffc0203c62:	7a42                	ld	s4,48(sp)
ffffffffc0203c64:	7aa2                	ld	s5,40(sp)
ffffffffc0203c66:	7b02                	ld	s6,32(sp)
ffffffffc0203c68:	6be2                	ld	s7,24(sp)
ffffffffc0203c6a:	6c42                	ld	s8,16(sp)
ffffffffc0203c6c:	6125                	addi	sp,sp,96
ffffffffc0203c6e:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0203c70:	85a2                	mv	a1,s0
ffffffffc0203c72:	00004517          	auipc	a0,0x4
ffffffffc0203c76:	26650513          	addi	a0,a0,614 # ffffffffc0207ed8 <default_pmm_manager+0xa40>
ffffffffc0203c7a:	d14fc0ef          	jal	ra,ffffffffc020018e <cprintf>
                  break;
ffffffffc0203c7e:	bfe1                	j	ffffffffc0203c56 <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc0203c80:	4401                	li	s0,0
ffffffffc0203c82:	bfd1                	j	ffffffffc0203c56 <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203c84:	00004697          	auipc	a3,0x4
ffffffffc0203c88:	28468693          	addi	a3,a3,644 # ffffffffc0207f08 <default_pmm_manager+0xa70>
ffffffffc0203c8c:	00003617          	auipc	a2,0x3
ffffffffc0203c90:	0c460613          	addi	a2,a2,196 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203c94:	06800593          	li	a1,104
ffffffffc0203c98:	00004517          	auipc	a0,0x4
ffffffffc0203c9c:	fb850513          	addi	a0,a0,-72 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203ca0:	fe4fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0203ca4 <swap_in>:
{
ffffffffc0203ca4:	7179                	addi	sp,sp,-48
ffffffffc0203ca6:	e84a                	sd	s2,16(sp)
ffffffffc0203ca8:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc0203caa:	4505                	li	a0,1
{
ffffffffc0203cac:	ec26                	sd	s1,24(sp)
ffffffffc0203cae:	e44e                	sd	s3,8(sp)
ffffffffc0203cb0:	f406                	sd	ra,40(sp)
ffffffffc0203cb2:	f022                	sd	s0,32(sp)
ffffffffc0203cb4:	84ae                	mv	s1,a1
ffffffffc0203cb6:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc0203cb8:	99afe0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
     assert(result!=NULL);
ffffffffc0203cbc:	c129                	beqz	a0,ffffffffc0203cfe <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0203cbe:	842a                	mv	s0,a0
ffffffffc0203cc0:	01893503          	ld	a0,24(s2)
ffffffffc0203cc4:	4601                	li	a2,0
ffffffffc0203cc6:	85a6                	mv	a1,s1
ffffffffc0203cc8:	a98fe0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc0203ccc:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc0203cce:	6108                	ld	a0,0(a0)
ffffffffc0203cd0:	85a2                	mv	a1,s0
ffffffffc0203cd2:	042010ef          	jal	ra,ffffffffc0204d14 <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc0203cd6:	00093583          	ld	a1,0(s2)
ffffffffc0203cda:	8626                	mv	a2,s1
ffffffffc0203cdc:	00004517          	auipc	a0,0x4
ffffffffc0203ce0:	f1450513          	addi	a0,a0,-236 # ffffffffc0207bf0 <default_pmm_manager+0x758>
ffffffffc0203ce4:	81a1                	srli	a1,a1,0x8
ffffffffc0203ce6:	ca8fc0ef          	jal	ra,ffffffffc020018e <cprintf>
}
ffffffffc0203cea:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc0203cec:	0089b023          	sd	s0,0(s3)
}
ffffffffc0203cf0:	7402                	ld	s0,32(sp)
ffffffffc0203cf2:	64e2                	ld	s1,24(sp)
ffffffffc0203cf4:	6942                	ld	s2,16(sp)
ffffffffc0203cf6:	69a2                	ld	s3,8(sp)
ffffffffc0203cf8:	4501                	li	a0,0
ffffffffc0203cfa:	6145                	addi	sp,sp,48
ffffffffc0203cfc:	8082                	ret
     assert(result!=NULL);
ffffffffc0203cfe:	00004697          	auipc	a3,0x4
ffffffffc0203d02:	ee268693          	addi	a3,a3,-286 # ffffffffc0207be0 <default_pmm_manager+0x748>
ffffffffc0203d06:	00003617          	auipc	a2,0x3
ffffffffc0203d0a:	04a60613          	addi	a2,a2,74 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203d0e:	07e00593          	li	a1,126
ffffffffc0203d12:	00004517          	auipc	a0,0x4
ffffffffc0203d16:	f3e50513          	addi	a0,a0,-194 # ffffffffc0207c50 <default_pmm_manager+0x7b8>
ffffffffc0203d1a:	f6afc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0203d1e <_fifo_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc0203d1e:	000b3797          	auipc	a5,0xb3
ffffffffc0203d22:	fba78793          	addi	a5,a5,-70 # ffffffffc02b6cd8 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
ffffffffc0203d26:	f51c                	sd	a5,40(a0)
ffffffffc0203d28:	e79c                	sd	a5,8(a5)
ffffffffc0203d2a:	e39c                	sd	a5,0(a5)
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc0203d2c:	4501                	li	a0,0
ffffffffc0203d2e:	8082                	ret

ffffffffc0203d30 <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0203d30:	4501                	li	a0,0
ffffffffc0203d32:	8082                	ret

ffffffffc0203d34 <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0203d34:	4501                	li	a0,0
ffffffffc0203d36:	8082                	ret

ffffffffc0203d38 <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc0203d38:	4501                	li	a0,0
ffffffffc0203d3a:	8082                	ret

ffffffffc0203d3c <_fifo_check_swap>:
_fifo_check_swap(void) {
ffffffffc0203d3c:	711d                	addi	sp,sp,-96
ffffffffc0203d3e:	fc4e                	sd	s3,56(sp)
ffffffffc0203d40:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203d42:	00004517          	auipc	a0,0x4
ffffffffc0203d46:	23650513          	addi	a0,a0,566 # ffffffffc0207f78 <default_pmm_manager+0xae0>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203d4a:	698d                	lui	s3,0x3
ffffffffc0203d4c:	4a31                	li	s4,12
_fifo_check_swap(void) {
ffffffffc0203d4e:	e8a2                	sd	s0,80(sp)
ffffffffc0203d50:	e4a6                	sd	s1,72(sp)
ffffffffc0203d52:	ec86                	sd	ra,88(sp)
ffffffffc0203d54:	e0ca                	sd	s2,64(sp)
ffffffffc0203d56:	f456                	sd	s5,40(sp)
ffffffffc0203d58:	f05a                	sd	s6,32(sp)
ffffffffc0203d5a:	ec5e                	sd	s7,24(sp)
ffffffffc0203d5c:	e862                	sd	s8,16(sp)
ffffffffc0203d5e:	e466                	sd	s9,8(sp)
    assert(pgfault_num==4);
ffffffffc0203d60:	000b3417          	auipc	s0,0xb3
ffffffffc0203d64:	e4c40413          	addi	s0,s0,-436 # ffffffffc02b6bac <pgfault_num>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203d68:	c26fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203d6c:	01498023          	sb	s4,0(s3) # 3000 <_binary_obj___user_faultread_out_size-0x6580>
    assert(pgfault_num==4);
ffffffffc0203d70:	4004                	lw	s1,0(s0)
ffffffffc0203d72:	4791                	li	a5,4
ffffffffc0203d74:	2481                	sext.w	s1,s1
ffffffffc0203d76:	14f49963          	bne	s1,a5,ffffffffc0203ec8 <_fifo_check_swap+0x18c>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203d7a:	00004517          	auipc	a0,0x4
ffffffffc0203d7e:	23e50513          	addi	a0,a0,574 # ffffffffc0207fb8 <default_pmm_manager+0xb20>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203d82:	6a85                	lui	s5,0x1
ffffffffc0203d84:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203d86:	c08fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203d8a:	016a8023          	sb	s6,0(s5) # 1000 <_binary_obj___user_faultread_out_size-0x8580>
    assert(pgfault_num==4);
ffffffffc0203d8e:	00042903          	lw	s2,0(s0)
ffffffffc0203d92:	2901                	sext.w	s2,s2
ffffffffc0203d94:	2a991a63          	bne	s2,s1,ffffffffc0204048 <_fifo_check_swap+0x30c>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203d98:	00004517          	auipc	a0,0x4
ffffffffc0203d9c:	24850513          	addi	a0,a0,584 # ffffffffc0207fe0 <default_pmm_manager+0xb48>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203da0:	6b91                	lui	s7,0x4
ffffffffc0203da2:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203da4:	beafc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203da8:	018b8023          	sb	s8,0(s7) # 4000 <_binary_obj___user_faultread_out_size-0x5580>
    assert(pgfault_num==4);
ffffffffc0203dac:	4004                	lw	s1,0(s0)
ffffffffc0203dae:	2481                	sext.w	s1,s1
ffffffffc0203db0:	27249c63          	bne	s1,s2,ffffffffc0204028 <_fifo_check_swap+0x2ec>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203db4:	00004517          	auipc	a0,0x4
ffffffffc0203db8:	25450513          	addi	a0,a0,596 # ffffffffc0208008 <default_pmm_manager+0xb70>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203dbc:	6909                	lui	s2,0x2
ffffffffc0203dbe:	4cad                	li	s9,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203dc0:	bcefc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203dc4:	01990023          	sb	s9,0(s2) # 2000 <_binary_obj___user_faultread_out_size-0x7580>
    assert(pgfault_num==4);
ffffffffc0203dc8:	401c                	lw	a5,0(s0)
ffffffffc0203dca:	2781                	sext.w	a5,a5
ffffffffc0203dcc:	22979e63          	bne	a5,s1,ffffffffc0204008 <_fifo_check_swap+0x2cc>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203dd0:	00004517          	auipc	a0,0x4
ffffffffc0203dd4:	26050513          	addi	a0,a0,608 # ffffffffc0208030 <default_pmm_manager+0xb98>
ffffffffc0203dd8:	bb6fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203ddc:	6795                	lui	a5,0x5
ffffffffc0203dde:	4739                	li	a4,14
ffffffffc0203de0:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4580>
    assert(pgfault_num==5);
ffffffffc0203de4:	4004                	lw	s1,0(s0)
ffffffffc0203de6:	4795                	li	a5,5
ffffffffc0203de8:	2481                	sext.w	s1,s1
ffffffffc0203dea:	1ef49f63          	bne	s1,a5,ffffffffc0203fe8 <_fifo_check_swap+0x2ac>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203dee:	00004517          	auipc	a0,0x4
ffffffffc0203df2:	21a50513          	addi	a0,a0,538 # ffffffffc0208008 <default_pmm_manager+0xb70>
ffffffffc0203df6:	b98fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203dfa:	01990023          	sb	s9,0(s2)
    assert(pgfault_num==5);
ffffffffc0203dfe:	401c                	lw	a5,0(s0)
ffffffffc0203e00:	2781                	sext.w	a5,a5
ffffffffc0203e02:	1c979363          	bne	a5,s1,ffffffffc0203fc8 <_fifo_check_swap+0x28c>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203e06:	00004517          	auipc	a0,0x4
ffffffffc0203e0a:	1b250513          	addi	a0,a0,434 # ffffffffc0207fb8 <default_pmm_manager+0xb20>
ffffffffc0203e0e:	b80fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203e12:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num==6);
ffffffffc0203e16:	401c                	lw	a5,0(s0)
ffffffffc0203e18:	4719                	li	a4,6
ffffffffc0203e1a:	2781                	sext.w	a5,a5
ffffffffc0203e1c:	18e79663          	bne	a5,a4,ffffffffc0203fa8 <_fifo_check_swap+0x26c>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203e20:	00004517          	auipc	a0,0x4
ffffffffc0203e24:	1e850513          	addi	a0,a0,488 # ffffffffc0208008 <default_pmm_manager+0xb70>
ffffffffc0203e28:	b66fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203e2c:	01990023          	sb	s9,0(s2)
    assert(pgfault_num==7);
ffffffffc0203e30:	401c                	lw	a5,0(s0)
ffffffffc0203e32:	471d                	li	a4,7
ffffffffc0203e34:	2781                	sext.w	a5,a5
ffffffffc0203e36:	14e79963          	bne	a5,a4,ffffffffc0203f88 <_fifo_check_swap+0x24c>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203e3a:	00004517          	auipc	a0,0x4
ffffffffc0203e3e:	13e50513          	addi	a0,a0,318 # ffffffffc0207f78 <default_pmm_manager+0xae0>
ffffffffc0203e42:	b4cfc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203e46:	01498023          	sb	s4,0(s3)
    assert(pgfault_num==8);
ffffffffc0203e4a:	401c                	lw	a5,0(s0)
ffffffffc0203e4c:	4721                	li	a4,8
ffffffffc0203e4e:	2781                	sext.w	a5,a5
ffffffffc0203e50:	10e79c63          	bne	a5,a4,ffffffffc0203f68 <_fifo_check_swap+0x22c>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203e54:	00004517          	auipc	a0,0x4
ffffffffc0203e58:	18c50513          	addi	a0,a0,396 # ffffffffc0207fe0 <default_pmm_manager+0xb48>
ffffffffc0203e5c:	b32fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203e60:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num==9);
ffffffffc0203e64:	401c                	lw	a5,0(s0)
ffffffffc0203e66:	4725                	li	a4,9
ffffffffc0203e68:	2781                	sext.w	a5,a5
ffffffffc0203e6a:	0ce79f63          	bne	a5,a4,ffffffffc0203f48 <_fifo_check_swap+0x20c>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203e6e:	00004517          	auipc	a0,0x4
ffffffffc0203e72:	1c250513          	addi	a0,a0,450 # ffffffffc0208030 <default_pmm_manager+0xb98>
ffffffffc0203e76:	b18fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203e7a:	6795                	lui	a5,0x5
ffffffffc0203e7c:	4739                	li	a4,14
ffffffffc0203e7e:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4580>
    assert(pgfault_num==10);
ffffffffc0203e82:	4004                	lw	s1,0(s0)
ffffffffc0203e84:	47a9                	li	a5,10
ffffffffc0203e86:	2481                	sext.w	s1,s1
ffffffffc0203e88:	0af49063          	bne	s1,a5,ffffffffc0203f28 <_fifo_check_swap+0x1ec>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203e8c:	00004517          	auipc	a0,0x4
ffffffffc0203e90:	12c50513          	addi	a0,a0,300 # ffffffffc0207fb8 <default_pmm_manager+0xb20>
ffffffffc0203e94:	afafc0ef          	jal	ra,ffffffffc020018e <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203e98:	6785                	lui	a5,0x1
ffffffffc0203e9a:	0007c783          	lbu	a5,0(a5) # 1000 <_binary_obj___user_faultread_out_size-0x8580>
ffffffffc0203e9e:	06979563          	bne	a5,s1,ffffffffc0203f08 <_fifo_check_swap+0x1cc>
    assert(pgfault_num==11);
ffffffffc0203ea2:	401c                	lw	a5,0(s0)
ffffffffc0203ea4:	472d                	li	a4,11
ffffffffc0203ea6:	2781                	sext.w	a5,a5
ffffffffc0203ea8:	04e79063          	bne	a5,a4,ffffffffc0203ee8 <_fifo_check_swap+0x1ac>
}
ffffffffc0203eac:	60e6                	ld	ra,88(sp)
ffffffffc0203eae:	6446                	ld	s0,80(sp)
ffffffffc0203eb0:	64a6                	ld	s1,72(sp)
ffffffffc0203eb2:	6906                	ld	s2,64(sp)
ffffffffc0203eb4:	79e2                	ld	s3,56(sp)
ffffffffc0203eb6:	7a42                	ld	s4,48(sp)
ffffffffc0203eb8:	7aa2                	ld	s5,40(sp)
ffffffffc0203eba:	7b02                	ld	s6,32(sp)
ffffffffc0203ebc:	6be2                	ld	s7,24(sp)
ffffffffc0203ebe:	6c42                	ld	s8,16(sp)
ffffffffc0203ec0:	6ca2                	ld	s9,8(sp)
ffffffffc0203ec2:	4501                	li	a0,0
ffffffffc0203ec4:	6125                	addi	sp,sp,96
ffffffffc0203ec6:	8082                	ret
    assert(pgfault_num==4);
ffffffffc0203ec8:	00004697          	auipc	a3,0x4
ffffffffc0203ecc:	f5068693          	addi	a3,a3,-176 # ffffffffc0207e18 <default_pmm_manager+0x980>
ffffffffc0203ed0:	00003617          	auipc	a2,0x3
ffffffffc0203ed4:	e8060613          	addi	a2,a2,-384 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203ed8:	05100593          	li	a1,81
ffffffffc0203edc:	00004517          	auipc	a0,0x4
ffffffffc0203ee0:	0c450513          	addi	a0,a0,196 # ffffffffc0207fa0 <default_pmm_manager+0xb08>
ffffffffc0203ee4:	da0fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==11);
ffffffffc0203ee8:	00004697          	auipc	a3,0x4
ffffffffc0203eec:	1f868693          	addi	a3,a3,504 # ffffffffc02080e0 <default_pmm_manager+0xc48>
ffffffffc0203ef0:	00003617          	auipc	a2,0x3
ffffffffc0203ef4:	e6060613          	addi	a2,a2,-416 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203ef8:	07300593          	li	a1,115
ffffffffc0203efc:	00004517          	auipc	a0,0x4
ffffffffc0203f00:	0a450513          	addi	a0,a0,164 # ffffffffc0207fa0 <default_pmm_manager+0xb08>
ffffffffc0203f04:	d80fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203f08:	00004697          	auipc	a3,0x4
ffffffffc0203f0c:	1b068693          	addi	a3,a3,432 # ffffffffc02080b8 <default_pmm_manager+0xc20>
ffffffffc0203f10:	00003617          	auipc	a2,0x3
ffffffffc0203f14:	e4060613          	addi	a2,a2,-448 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203f18:	07100593          	li	a1,113
ffffffffc0203f1c:	00004517          	auipc	a0,0x4
ffffffffc0203f20:	08450513          	addi	a0,a0,132 # ffffffffc0207fa0 <default_pmm_manager+0xb08>
ffffffffc0203f24:	d60fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==10);
ffffffffc0203f28:	00004697          	auipc	a3,0x4
ffffffffc0203f2c:	18068693          	addi	a3,a3,384 # ffffffffc02080a8 <default_pmm_manager+0xc10>
ffffffffc0203f30:	00003617          	auipc	a2,0x3
ffffffffc0203f34:	e2060613          	addi	a2,a2,-480 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203f38:	06f00593          	li	a1,111
ffffffffc0203f3c:	00004517          	auipc	a0,0x4
ffffffffc0203f40:	06450513          	addi	a0,a0,100 # ffffffffc0207fa0 <default_pmm_manager+0xb08>
ffffffffc0203f44:	d40fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==9);
ffffffffc0203f48:	00004697          	auipc	a3,0x4
ffffffffc0203f4c:	15068693          	addi	a3,a3,336 # ffffffffc0208098 <default_pmm_manager+0xc00>
ffffffffc0203f50:	00003617          	auipc	a2,0x3
ffffffffc0203f54:	e0060613          	addi	a2,a2,-512 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203f58:	06c00593          	li	a1,108
ffffffffc0203f5c:	00004517          	auipc	a0,0x4
ffffffffc0203f60:	04450513          	addi	a0,a0,68 # ffffffffc0207fa0 <default_pmm_manager+0xb08>
ffffffffc0203f64:	d20fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==8);
ffffffffc0203f68:	00004697          	auipc	a3,0x4
ffffffffc0203f6c:	12068693          	addi	a3,a3,288 # ffffffffc0208088 <default_pmm_manager+0xbf0>
ffffffffc0203f70:	00003617          	auipc	a2,0x3
ffffffffc0203f74:	de060613          	addi	a2,a2,-544 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203f78:	06900593          	li	a1,105
ffffffffc0203f7c:	00004517          	auipc	a0,0x4
ffffffffc0203f80:	02450513          	addi	a0,a0,36 # ffffffffc0207fa0 <default_pmm_manager+0xb08>
ffffffffc0203f84:	d00fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==7);
ffffffffc0203f88:	00004697          	auipc	a3,0x4
ffffffffc0203f8c:	0f068693          	addi	a3,a3,240 # ffffffffc0208078 <default_pmm_manager+0xbe0>
ffffffffc0203f90:	00003617          	auipc	a2,0x3
ffffffffc0203f94:	dc060613          	addi	a2,a2,-576 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203f98:	06600593          	li	a1,102
ffffffffc0203f9c:	00004517          	auipc	a0,0x4
ffffffffc0203fa0:	00450513          	addi	a0,a0,4 # ffffffffc0207fa0 <default_pmm_manager+0xb08>
ffffffffc0203fa4:	ce0fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==6);
ffffffffc0203fa8:	00004697          	auipc	a3,0x4
ffffffffc0203fac:	0c068693          	addi	a3,a3,192 # ffffffffc0208068 <default_pmm_manager+0xbd0>
ffffffffc0203fb0:	00003617          	auipc	a2,0x3
ffffffffc0203fb4:	da060613          	addi	a2,a2,-608 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203fb8:	06300593          	li	a1,99
ffffffffc0203fbc:	00004517          	auipc	a0,0x4
ffffffffc0203fc0:	fe450513          	addi	a0,a0,-28 # ffffffffc0207fa0 <default_pmm_manager+0xb08>
ffffffffc0203fc4:	cc0fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==5);
ffffffffc0203fc8:	00004697          	auipc	a3,0x4
ffffffffc0203fcc:	09068693          	addi	a3,a3,144 # ffffffffc0208058 <default_pmm_manager+0xbc0>
ffffffffc0203fd0:	00003617          	auipc	a2,0x3
ffffffffc0203fd4:	d8060613          	addi	a2,a2,-640 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203fd8:	06000593          	li	a1,96
ffffffffc0203fdc:	00004517          	auipc	a0,0x4
ffffffffc0203fe0:	fc450513          	addi	a0,a0,-60 # ffffffffc0207fa0 <default_pmm_manager+0xb08>
ffffffffc0203fe4:	ca0fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==5);
ffffffffc0203fe8:	00004697          	auipc	a3,0x4
ffffffffc0203fec:	07068693          	addi	a3,a3,112 # ffffffffc0208058 <default_pmm_manager+0xbc0>
ffffffffc0203ff0:	00003617          	auipc	a2,0x3
ffffffffc0203ff4:	d6060613          	addi	a2,a2,-672 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0203ff8:	05d00593          	li	a1,93
ffffffffc0203ffc:	00004517          	auipc	a0,0x4
ffffffffc0204000:	fa450513          	addi	a0,a0,-92 # ffffffffc0207fa0 <default_pmm_manager+0xb08>
ffffffffc0204004:	c80fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==4);
ffffffffc0204008:	00004697          	auipc	a3,0x4
ffffffffc020400c:	e1068693          	addi	a3,a3,-496 # ffffffffc0207e18 <default_pmm_manager+0x980>
ffffffffc0204010:	00003617          	auipc	a2,0x3
ffffffffc0204014:	d4060613          	addi	a2,a2,-704 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0204018:	05a00593          	li	a1,90
ffffffffc020401c:	00004517          	auipc	a0,0x4
ffffffffc0204020:	f8450513          	addi	a0,a0,-124 # ffffffffc0207fa0 <default_pmm_manager+0xb08>
ffffffffc0204024:	c60fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==4);
ffffffffc0204028:	00004697          	auipc	a3,0x4
ffffffffc020402c:	df068693          	addi	a3,a3,-528 # ffffffffc0207e18 <default_pmm_manager+0x980>
ffffffffc0204030:	00003617          	auipc	a2,0x3
ffffffffc0204034:	d2060613          	addi	a2,a2,-736 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0204038:	05700593          	li	a1,87
ffffffffc020403c:	00004517          	auipc	a0,0x4
ffffffffc0204040:	f6450513          	addi	a0,a0,-156 # ffffffffc0207fa0 <default_pmm_manager+0xb08>
ffffffffc0204044:	c40fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==4);
ffffffffc0204048:	00004697          	auipc	a3,0x4
ffffffffc020404c:	dd068693          	addi	a3,a3,-560 # ffffffffc0207e18 <default_pmm_manager+0x980>
ffffffffc0204050:	00003617          	auipc	a2,0x3
ffffffffc0204054:	d0060613          	addi	a2,a2,-768 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0204058:	05400593          	li	a1,84
ffffffffc020405c:	00004517          	auipc	a0,0x4
ffffffffc0204060:	f4450513          	addi	a0,a0,-188 # ffffffffc0207fa0 <default_pmm_manager+0xb08>
ffffffffc0204064:	c20fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204068 <_fifo_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc0204068:	751c                	ld	a5,40(a0)
{
ffffffffc020406a:	1141                	addi	sp,sp,-16
ffffffffc020406c:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc020406e:	cf91                	beqz	a5,ffffffffc020408a <_fifo_swap_out_victim+0x22>
     assert(in_tick==0);
ffffffffc0204070:	ee0d                	bnez	a2,ffffffffc02040aa <_fifo_swap_out_victim+0x42>
    return listelm->next;
ffffffffc0204072:	679c                	ld	a5,8(a5)
}
ffffffffc0204074:	60a2                	ld	ra,8(sp)
ffffffffc0204076:	4501                	li	a0,0
    __list_del(listelm->prev, listelm->next);
ffffffffc0204078:	6394                	ld	a3,0(a5)
ffffffffc020407a:	6798                	ld	a4,8(a5)
    *ptr_page = le2page(entry, pra_page_link);
ffffffffc020407c:	fd878793          	addi	a5,a5,-40
    prev->next = next;
ffffffffc0204080:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0204082:	e314                	sd	a3,0(a4)
ffffffffc0204084:	e19c                	sd	a5,0(a1)
}
ffffffffc0204086:	0141                	addi	sp,sp,16
ffffffffc0204088:	8082                	ret
         assert(head != NULL);
ffffffffc020408a:	00004697          	auipc	a3,0x4
ffffffffc020408e:	08668693          	addi	a3,a3,134 # ffffffffc0208110 <default_pmm_manager+0xc78>
ffffffffc0204092:	00003617          	auipc	a2,0x3
ffffffffc0204096:	cbe60613          	addi	a2,a2,-834 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc020409a:	04100593          	li	a1,65
ffffffffc020409e:	00004517          	auipc	a0,0x4
ffffffffc02040a2:	f0250513          	addi	a0,a0,-254 # ffffffffc0207fa0 <default_pmm_manager+0xb08>
ffffffffc02040a6:	bdefc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(in_tick==0);
ffffffffc02040aa:	00004697          	auipc	a3,0x4
ffffffffc02040ae:	07668693          	addi	a3,a3,118 # ffffffffc0208120 <default_pmm_manager+0xc88>
ffffffffc02040b2:	00003617          	auipc	a2,0x3
ffffffffc02040b6:	c9e60613          	addi	a2,a2,-866 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02040ba:	04200593          	li	a1,66
ffffffffc02040be:	00004517          	auipc	a0,0x4
ffffffffc02040c2:	ee250513          	addi	a0,a0,-286 # ffffffffc0207fa0 <default_pmm_manager+0xb08>
ffffffffc02040c6:	bbefc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02040ca <_fifo_map_swappable>:
    list_entry_t *entry=&(page->pra_page_link);
ffffffffc02040ca:	02860713          	addi	a4,a2,40
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc02040ce:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc02040d0:	cb09                	beqz	a4,ffffffffc02040e2 <_fifo_map_swappable+0x18>
ffffffffc02040d2:	cb81                	beqz	a5,ffffffffc02040e2 <_fifo_map_swappable+0x18>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02040d4:	6394                	ld	a3,0(a5)
    prev->next = next->prev = elm;
ffffffffc02040d6:	e398                	sd	a4,0(a5)
}
ffffffffc02040d8:	4501                	li	a0,0
ffffffffc02040da:	e698                	sd	a4,8(a3)
    elm->next = next;
ffffffffc02040dc:	fa1c                	sd	a5,48(a2)
    elm->prev = prev;
ffffffffc02040de:	f614                	sd	a3,40(a2)
ffffffffc02040e0:	8082                	ret
{
ffffffffc02040e2:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc02040e4:	00004697          	auipc	a3,0x4
ffffffffc02040e8:	00c68693          	addi	a3,a3,12 # ffffffffc02080f0 <default_pmm_manager+0xc58>
ffffffffc02040ec:	00003617          	auipc	a2,0x3
ffffffffc02040f0:	c6460613          	addi	a2,a2,-924 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02040f4:	03200593          	li	a1,50
ffffffffc02040f8:	00004517          	auipc	a0,0x4
ffffffffc02040fc:	ea850513          	addi	a0,a0,-344 # ffffffffc0207fa0 <default_pmm_manager+0xb08>
{
ffffffffc0204100:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc0204102:	b82fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204106 <check_vma_overlap.isra.2.part.3>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0204106:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0204108:	00004697          	auipc	a3,0x4
ffffffffc020410c:	04068693          	addi	a3,a3,64 # ffffffffc0208148 <default_pmm_manager+0xcb0>
ffffffffc0204110:	00003617          	auipc	a2,0x3
ffffffffc0204114:	c4060613          	addi	a2,a2,-960 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0204118:	06d00593          	li	a1,109
ffffffffc020411c:	00004517          	auipc	a0,0x4
ffffffffc0204120:	04c50513          	addi	a0,a0,76 # ffffffffc0208168 <default_pmm_manager+0xcd0>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0204124:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc0204126:	b5efc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020412a <mm_create>:
mm_create(void) {
ffffffffc020412a:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc020412c:	04000513          	li	a0,64
mm_create(void) {
ffffffffc0204130:	e022                	sd	s0,0(sp)
ffffffffc0204132:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0204134:	b23fd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc0204138:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc020413a:	c515                	beqz	a0,ffffffffc0204166 <mm_create+0x3c>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc020413c:	000b3797          	auipc	a5,0xb3
ffffffffc0204140:	a6c78793          	addi	a5,a5,-1428 # ffffffffc02b6ba8 <swap_init_ok>
ffffffffc0204144:	439c                	lw	a5,0(a5)
    elm->prev = elm->next = elm;
ffffffffc0204146:	e408                	sd	a0,8(s0)
ffffffffc0204148:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc020414a:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc020414e:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0204152:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0204156:	2781                	sext.w	a5,a5
ffffffffc0204158:	ef81                	bnez	a5,ffffffffc0204170 <mm_create+0x46>
        else mm->sm_priv = NULL;
ffffffffc020415a:	02053423          	sd	zero,40(a0)
    return mm->mm_count;
}

static inline void
set_mm_count(struct mm_struct *mm, int val) {
    mm->mm_count = val;
ffffffffc020415e:	02042823          	sw	zero,48(s0)

typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock) {
    *lock = 0;
ffffffffc0204162:	02043c23          	sd	zero,56(s0)
}
ffffffffc0204166:	8522                	mv	a0,s0
ffffffffc0204168:	60a2                	ld	ra,8(sp)
ffffffffc020416a:	6402                	ld	s0,0(sp)
ffffffffc020416c:	0141                	addi	sp,sp,16
ffffffffc020416e:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0204170:	a01ff0ef          	jal	ra,ffffffffc0203b70 <swap_init_mm>
ffffffffc0204174:	b7ed                	j	ffffffffc020415e <mm_create+0x34>

ffffffffc0204176 <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0204176:	1101                	addi	sp,sp,-32
ffffffffc0204178:	e04a                	sd	s2,0(sp)
ffffffffc020417a:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020417c:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0204180:	e822                	sd	s0,16(sp)
ffffffffc0204182:	e426                	sd	s1,8(sp)
ffffffffc0204184:	ec06                	sd	ra,24(sp)
ffffffffc0204186:	84ae                	mv	s1,a1
ffffffffc0204188:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020418a:	acdfd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
    if (vma != NULL) {
ffffffffc020418e:	c509                	beqz	a0,ffffffffc0204198 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc0204190:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc0204194:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0204196:	cd00                	sw	s0,24(a0)
}
ffffffffc0204198:	60e2                	ld	ra,24(sp)
ffffffffc020419a:	6442                	ld	s0,16(sp)
ffffffffc020419c:	64a2                	ld	s1,8(sp)
ffffffffc020419e:	6902                	ld	s2,0(sp)
ffffffffc02041a0:	6105                	addi	sp,sp,32
ffffffffc02041a2:	8082                	ret

ffffffffc02041a4 <find_vma>:
    if (mm != NULL) {
ffffffffc02041a4:	c51d                	beqz	a0,ffffffffc02041d2 <find_vma+0x2e>
        vma = mm->mmap_cache;
ffffffffc02041a6:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc02041a8:	c781                	beqz	a5,ffffffffc02041b0 <find_vma+0xc>
ffffffffc02041aa:	6798                	ld	a4,8(a5)
ffffffffc02041ac:	02e5f663          	bleu	a4,a1,ffffffffc02041d8 <find_vma+0x34>
                list_entry_t *list = &(mm->mmap_list), *le = list;
ffffffffc02041b0:	87aa                	mv	a5,a0
    return listelm->next;
ffffffffc02041b2:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc02041b4:	00f50f63          	beq	a0,a5,ffffffffc02041d2 <find_vma+0x2e>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc02041b8:	fe87b703          	ld	a4,-24(a5)
ffffffffc02041bc:	fee5ebe3          	bltu	a1,a4,ffffffffc02041b2 <find_vma+0xe>
ffffffffc02041c0:	ff07b703          	ld	a4,-16(a5)
ffffffffc02041c4:	fee5f7e3          	bleu	a4,a1,ffffffffc02041b2 <find_vma+0xe>
                    vma = le2vma(le, list_link);
ffffffffc02041c8:	1781                	addi	a5,a5,-32
        if (vma != NULL) {
ffffffffc02041ca:	c781                	beqz	a5,ffffffffc02041d2 <find_vma+0x2e>
            mm->mmap_cache = vma;
ffffffffc02041cc:	e91c                	sd	a5,16(a0)
}
ffffffffc02041ce:	853e                	mv	a0,a5
ffffffffc02041d0:	8082                	ret
    struct vma_struct *vma = NULL;
ffffffffc02041d2:	4781                	li	a5,0
}
ffffffffc02041d4:	853e                	mv	a0,a5
ffffffffc02041d6:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc02041d8:	6b98                	ld	a4,16(a5)
ffffffffc02041da:	fce5fbe3          	bleu	a4,a1,ffffffffc02041b0 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc02041de:	e91c                	sd	a5,16(a0)
    return vma;
ffffffffc02041e0:	b7fd                	j	ffffffffc02041ce <find_vma+0x2a>

ffffffffc02041e2 <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc02041e2:	6590                	ld	a2,8(a1)
ffffffffc02041e4:	0105b803          	ld	a6,16(a1) # 1010 <_binary_obj___user_faultread_out_size-0x8570>
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc02041e8:	1141                	addi	sp,sp,-16
ffffffffc02041ea:	e406                	sd	ra,8(sp)
ffffffffc02041ec:	872a                	mv	a4,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc02041ee:	01066863          	bltu	a2,a6,ffffffffc02041fe <insert_vma_struct+0x1c>
ffffffffc02041f2:	a8b9                	j	ffffffffc0204250 <insert_vma_struct+0x6e>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc02041f4:	fe87b683          	ld	a3,-24(a5)
ffffffffc02041f8:	04d66763          	bltu	a2,a3,ffffffffc0204246 <insert_vma_struct+0x64>
ffffffffc02041fc:	873e                	mv	a4,a5
ffffffffc02041fe:	671c                	ld	a5,8(a4)
        while ((le = list_next(le)) != list) {
ffffffffc0204200:	fef51ae3          	bne	a0,a5,ffffffffc02041f4 <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc0204204:	02a70463          	beq	a4,a0,ffffffffc020422c <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0204208:	ff073683          	ld	a3,-16(a4)
    assert(prev->vm_start < prev->vm_end);
ffffffffc020420c:	fe873883          	ld	a7,-24(a4)
ffffffffc0204210:	08d8f063          	bleu	a3,a7,ffffffffc0204290 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0204214:	04d66e63          	bltu	a2,a3,ffffffffc0204270 <insert_vma_struct+0x8e>
    }
    if (le_next != list) {
ffffffffc0204218:	00f50a63          	beq	a0,a5,ffffffffc020422c <insert_vma_struct+0x4a>
ffffffffc020421c:	fe87b683          	ld	a3,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc0204220:	0506e863          	bltu	a3,a6,ffffffffc0204270 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc0204224:	ff07b603          	ld	a2,-16(a5)
ffffffffc0204228:	02c6f263          	bleu	a2,a3,ffffffffc020424c <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc020422c:	5114                	lw	a3,32(a0)
    vma->vm_mm = mm;
ffffffffc020422e:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc0204230:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc0204234:	e390                	sd	a2,0(a5)
ffffffffc0204236:	e710                	sd	a2,8(a4)
}
ffffffffc0204238:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc020423a:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc020423c:	f198                	sd	a4,32(a1)
    mm->map_count ++;
ffffffffc020423e:	2685                	addiw	a3,a3,1
ffffffffc0204240:	d114                	sw	a3,32(a0)
}
ffffffffc0204242:	0141                	addi	sp,sp,16
ffffffffc0204244:	8082                	ret
    if (le_prev != list) {
ffffffffc0204246:	fca711e3          	bne	a4,a0,ffffffffc0204208 <insert_vma_struct+0x26>
ffffffffc020424a:	bfd9                	j	ffffffffc0204220 <insert_vma_struct+0x3e>
ffffffffc020424c:	ebbff0ef          	jal	ra,ffffffffc0204106 <check_vma_overlap.isra.2.part.3>
    assert(vma->vm_start < vma->vm_end);
ffffffffc0204250:	00004697          	auipc	a3,0x4
ffffffffc0204254:	08868693          	addi	a3,a3,136 # ffffffffc02082d8 <default_pmm_manager+0xe40>
ffffffffc0204258:	00003617          	auipc	a2,0x3
ffffffffc020425c:	af860613          	addi	a2,a2,-1288 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0204260:	07400593          	li	a1,116
ffffffffc0204264:	00004517          	auipc	a0,0x4
ffffffffc0204268:	f0450513          	addi	a0,a0,-252 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc020426c:	a18fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0204270:	00004697          	auipc	a3,0x4
ffffffffc0204274:	0a868693          	addi	a3,a3,168 # ffffffffc0208318 <default_pmm_manager+0xe80>
ffffffffc0204278:	00003617          	auipc	a2,0x3
ffffffffc020427c:	ad860613          	addi	a2,a2,-1320 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0204280:	06c00593          	li	a1,108
ffffffffc0204284:	00004517          	auipc	a0,0x4
ffffffffc0204288:	ee450513          	addi	a0,a0,-284 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc020428c:	9f8fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0204290:	00004697          	auipc	a3,0x4
ffffffffc0204294:	06868693          	addi	a3,a3,104 # ffffffffc02082f8 <default_pmm_manager+0xe60>
ffffffffc0204298:	00003617          	auipc	a2,0x3
ffffffffc020429c:	ab860613          	addi	a2,a2,-1352 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02042a0:	06b00593          	li	a1,107
ffffffffc02042a4:	00004517          	auipc	a0,0x4
ffffffffc02042a8:	ec450513          	addi	a0,a0,-316 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc02042ac:	9d8fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02042b0 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
    assert(mm_count(mm) == 0);
ffffffffc02042b0:	591c                	lw	a5,48(a0)
mm_destroy(struct mm_struct *mm) {
ffffffffc02042b2:	1141                	addi	sp,sp,-16
ffffffffc02042b4:	e406                	sd	ra,8(sp)
ffffffffc02042b6:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc02042b8:	e78d                	bnez	a5,ffffffffc02042e2 <mm_destroy+0x32>
ffffffffc02042ba:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc02042bc:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc02042be:	00a40c63          	beq	s0,a0,ffffffffc02042d6 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc02042c2:	6118                	ld	a4,0(a0)
ffffffffc02042c4:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc02042c6:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc02042c8:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02042ca:	e398                	sd	a4,0(a5)
ffffffffc02042cc:	a47fd0ef          	jal	ra,ffffffffc0201d12 <kfree>
    return listelm->next;
ffffffffc02042d0:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc02042d2:	fea418e3          	bne	s0,a0,ffffffffc02042c2 <mm_destroy+0x12>
    }
    kfree(mm); //kfree mm
ffffffffc02042d6:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc02042d8:	6402                	ld	s0,0(sp)
ffffffffc02042da:	60a2                	ld	ra,8(sp)
ffffffffc02042dc:	0141                	addi	sp,sp,16
    kfree(mm); //kfree mm
ffffffffc02042de:	a35fd06f          	j	ffffffffc0201d12 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc02042e2:	00004697          	auipc	a3,0x4
ffffffffc02042e6:	05668693          	addi	a3,a3,86 # ffffffffc0208338 <default_pmm_manager+0xea0>
ffffffffc02042ea:	00003617          	auipc	a2,0x3
ffffffffc02042ee:	a6660613          	addi	a2,a2,-1434 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02042f2:	09400593          	li	a1,148
ffffffffc02042f6:	00004517          	auipc	a0,0x4
ffffffffc02042fa:	e7250513          	addi	a0,a0,-398 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc02042fe:	986fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204302 <mm_map>:

//在给定的内存管理结构 mm 中，根据给定的线性地址 addr 和长度 len，创建一个新的 VMA，并将其插入到内存管理结构 mm 的 VMA 列表中。
int
mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
       struct vma_struct **vma_store) {
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0204302:	6785                	lui	a5,0x1
       struct vma_struct **vma_store) {
ffffffffc0204304:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0204306:	17fd                	addi	a5,a5,-1
ffffffffc0204308:	787d                	lui	a6,0xfffff
       struct vma_struct **vma_store) {
ffffffffc020430a:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020430c:	00f60433          	add	s0,a2,a5
       struct vma_struct **vma_store) {
ffffffffc0204310:	f426                	sd	s1,40(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0204312:	942e                	add	s0,s0,a1
       struct vma_struct **vma_store) {
ffffffffc0204314:	fc06                	sd	ra,56(sp)
ffffffffc0204316:	f04a                	sd	s2,32(sp)
ffffffffc0204318:	ec4e                	sd	s3,24(sp)
ffffffffc020431a:	e852                	sd	s4,16(sp)
ffffffffc020431c:	e456                	sd	s5,8(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020431e:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end)) {
ffffffffc0204322:	002007b7          	lui	a5,0x200
ffffffffc0204326:	01047433          	and	s0,s0,a6
ffffffffc020432a:	06f4e363          	bltu	s1,a5,ffffffffc0204390 <mm_map+0x8e>
ffffffffc020432e:	0684f163          	bleu	s0,s1,ffffffffc0204390 <mm_map+0x8e>
ffffffffc0204332:	4785                	li	a5,1
ffffffffc0204334:	07fe                	slli	a5,a5,0x1f
ffffffffc0204336:	0487ed63          	bltu	a5,s0,ffffffffc0204390 <mm_map+0x8e>
ffffffffc020433a:	89aa                	mv	s3,a0
ffffffffc020433c:	8a3a                	mv	s4,a4
ffffffffc020433e:	8ab6                	mv	s5,a3
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc0204340:	c931                	beqz	a0,ffffffffc0204394 <mm_map+0x92>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start) {
ffffffffc0204342:	85a6                	mv	a1,s1
ffffffffc0204344:	e61ff0ef          	jal	ra,ffffffffc02041a4 <find_vma>
ffffffffc0204348:	c501                	beqz	a0,ffffffffc0204350 <mm_map+0x4e>
ffffffffc020434a:	651c                	ld	a5,8(a0)
ffffffffc020434c:	0487e263          	bltu	a5,s0,ffffffffc0204390 <mm_map+0x8e>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204350:	03000513          	li	a0,48
ffffffffc0204354:	903fd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc0204358:	892a                	mv	s2,a0
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc020435a:	5571                	li	a0,-4
    if (vma != NULL) {
ffffffffc020435c:	02090163          	beqz	s2,ffffffffc020437e <mm_map+0x7c>

    if ((vma = vma_create(start, end, vm_flags)) == NULL) {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc0204360:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc0204362:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc0204366:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc020436a:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc020436e:	85ca                	mv	a1,s2
ffffffffc0204370:	e73ff0ef          	jal	ra,ffffffffc02041e2 <insert_vma_struct>
    if (vma_store != NULL) {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0204374:	4501                	li	a0,0
    if (vma_store != NULL) {
ffffffffc0204376:	000a0463          	beqz	s4,ffffffffc020437e <mm_map+0x7c>
        *vma_store = vma;
ffffffffc020437a:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc020437e:	70e2                	ld	ra,56(sp)
ffffffffc0204380:	7442                	ld	s0,48(sp)
ffffffffc0204382:	74a2                	ld	s1,40(sp)
ffffffffc0204384:	7902                	ld	s2,32(sp)
ffffffffc0204386:	69e2                	ld	s3,24(sp)
ffffffffc0204388:	6a42                	ld	s4,16(sp)
ffffffffc020438a:	6aa2                	ld	s5,8(sp)
ffffffffc020438c:	6121                	addi	sp,sp,64
ffffffffc020438e:	8082                	ret
        return -E_INVAL;
ffffffffc0204390:	5575                	li	a0,-3
ffffffffc0204392:	b7f5                	j	ffffffffc020437e <mm_map+0x7c>
    assert(mm != NULL);
ffffffffc0204394:	00004697          	auipc	a3,0x4
ffffffffc0204398:	90c68693          	addi	a3,a3,-1780 # ffffffffc0207ca0 <default_pmm_manager+0x808>
ffffffffc020439c:	00003617          	auipc	a2,0x3
ffffffffc02043a0:	9b460613          	addi	a2,a2,-1612 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02043a4:	0a800593          	li	a1,168
ffffffffc02043a8:	00004517          	auipc	a0,0x4
ffffffffc02043ac:	dc050513          	addi	a0,a0,-576 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc02043b0:	8d4fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02043b4 <dup_mmap>:
//用于将一个进程的内存映射表（Memory Mapping，简称 mmap）复制到另一个进程。
//将from的mmap复制到to的mmap链表里
int
dup_mmap(struct mm_struct *to, struct mm_struct *from) {
ffffffffc02043b4:	7139                	addi	sp,sp,-64
ffffffffc02043b6:	fc06                	sd	ra,56(sp)
ffffffffc02043b8:	f822                	sd	s0,48(sp)
ffffffffc02043ba:	f426                	sd	s1,40(sp)
ffffffffc02043bc:	f04a                	sd	s2,32(sp)
ffffffffc02043be:	ec4e                	sd	s3,24(sp)
ffffffffc02043c0:	e852                	sd	s4,16(sp)
ffffffffc02043c2:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc02043c4:	c535                	beqz	a0,ffffffffc0204430 <dup_mmap+0x7c>
ffffffffc02043c6:	892a                	mv	s2,a0
ffffffffc02043c8:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc02043ca:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc02043cc:	e59d                	bnez	a1,ffffffffc02043fa <dup_mmap+0x46>
ffffffffc02043ce:	a08d                	j	ffffffffc0204430 <dup_mmap+0x7c>
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL) {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc02043d0:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc02043d2:	0157b423          	sd	s5,8(a5) # 200008 <_binary_obj___user_exit_out_size+0x1f5578>
        insert_vma_struct(to, nvma);
ffffffffc02043d6:	854a                	mv	a0,s2
        vma->vm_end = vm_end;
ffffffffc02043d8:	0147b823          	sd	s4,16(a5)
        vma->vm_flags = vm_flags;
ffffffffc02043dc:	0137ac23          	sw	s3,24(a5)
        insert_vma_struct(to, nvma);
ffffffffc02043e0:	e03ff0ef          	jal	ra,ffffffffc02041e2 <insert_vma_struct>

        bool share = 1;//采取copy on write机制
        //父进程的用户内存地址空间的合法内容拷贝至新进程中(子进程)
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0) {
ffffffffc02043e4:	ff043683          	ld	a3,-16(s0)
ffffffffc02043e8:	fe843603          	ld	a2,-24(s0)
ffffffffc02043ec:	6c8c                	ld	a1,24(s1)
ffffffffc02043ee:	01893503          	ld	a0,24(s2)
ffffffffc02043f2:	4705                	li	a4,1
ffffffffc02043f4:	ccbfe0ef          	jal	ra,ffffffffc02030be <copy_range>
ffffffffc02043f8:	e105                	bnez	a0,ffffffffc0204418 <dup_mmap+0x64>
    return listelm->prev;
ffffffffc02043fa:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list) {
ffffffffc02043fc:	02848863          	beq	s1,s0,ffffffffc020442c <dup_mmap+0x78>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204400:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0204404:	fe843a83          	ld	s5,-24(s0)
ffffffffc0204408:	ff043a03          	ld	s4,-16(s0)
ffffffffc020440c:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204410:	847fd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc0204414:	87aa                	mv	a5,a0
    if (vma != NULL) {
ffffffffc0204416:	fd4d                	bnez	a0,ffffffffc02043d0 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc0204418:	5571                	li	a0,-4
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc020441a:	70e2                	ld	ra,56(sp)
ffffffffc020441c:	7442                	ld	s0,48(sp)
ffffffffc020441e:	74a2                	ld	s1,40(sp)
ffffffffc0204420:	7902                	ld	s2,32(sp)
ffffffffc0204422:	69e2                	ld	s3,24(sp)
ffffffffc0204424:	6a42                	ld	s4,16(sp)
ffffffffc0204426:	6aa2                	ld	s5,8(sp)
ffffffffc0204428:	6121                	addi	sp,sp,64
ffffffffc020442a:	8082                	ret
    return 0;
ffffffffc020442c:	4501                	li	a0,0
ffffffffc020442e:	b7f5                	j	ffffffffc020441a <dup_mmap+0x66>
    assert(to != NULL && from != NULL);
ffffffffc0204430:	00004697          	auipc	a3,0x4
ffffffffc0204434:	e6868693          	addi	a3,a3,-408 # ffffffffc0208298 <default_pmm_manager+0xe00>
ffffffffc0204438:	00003617          	auipc	a2,0x3
ffffffffc020443c:	91860613          	addi	a2,a2,-1768 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0204440:	0c200593          	li	a1,194
ffffffffc0204444:	00004517          	auipc	a0,0x4
ffffffffc0204448:	d2450513          	addi	a0,a0,-732 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc020444c:	838fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204450 <exit_mmap>:

//用于在进程退出时清理其mmap，取消页表对这一段的映射，销毁建立映射时页表占据的页。
void
exit_mmap(struct mm_struct *mm) {
ffffffffc0204450:	1101                	addi	sp,sp,-32
ffffffffc0204452:	ec06                	sd	ra,24(sp)
ffffffffc0204454:	e822                	sd	s0,16(sp)
ffffffffc0204456:	e426                	sd	s1,8(sp)
ffffffffc0204458:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc020445a:	c531                	beqz	a0,ffffffffc02044a6 <exit_mmap+0x56>
ffffffffc020445c:	591c                	lw	a5,48(a0)
ffffffffc020445e:	84aa                	mv	s1,a0
ffffffffc0204460:	e3b9                	bnez	a5,ffffffffc02044a6 <exit_mmap+0x56>
    return listelm->next;
ffffffffc0204462:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc0204464:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list) {
ffffffffc0204468:	02850663          	beq	a0,s0,ffffffffc0204494 <exit_mmap+0x44>
        struct vma_struct *vma = le2vma(le, list_link);
        //取消映射这一段虚拟地址
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc020446c:	ff043603          	ld	a2,-16(s0)
ffffffffc0204470:	fe843583          	ld	a1,-24(s0)
ffffffffc0204474:	854a                	mv	a0,s2
ffffffffc0204476:	d1ffd0ef          	jal	ra,ffffffffc0202194 <unmap_range>
ffffffffc020447a:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc020447c:	fe8498e3          	bne	s1,s0,ffffffffc020446c <exit_mmap+0x1c>
ffffffffc0204480:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list) {
ffffffffc0204482:	00848c63          	beq	s1,s0,ffffffffc020449a <exit_mmap+0x4a>
        struct vma_struct *vma = le2vma(le, list_link);
        //释放这一段虚拟地址在页表中建立映射用到的页，也就是页表用的页被释放
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0204486:	ff043603          	ld	a2,-16(s0)
ffffffffc020448a:	fe843583          	ld	a1,-24(s0)
ffffffffc020448e:	854a                	mv	a0,s2
ffffffffc0204490:	e1dfd0ef          	jal	ra,ffffffffc02022ac <exit_range>
ffffffffc0204494:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc0204496:	fe8498e3          	bne	s1,s0,ffffffffc0204486 <exit_mmap+0x36>
    }
}
ffffffffc020449a:	60e2                	ld	ra,24(sp)
ffffffffc020449c:	6442                	ld	s0,16(sp)
ffffffffc020449e:	64a2                	ld	s1,8(sp)
ffffffffc02044a0:	6902                	ld	s2,0(sp)
ffffffffc02044a2:	6105                	addi	sp,sp,32
ffffffffc02044a4:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02044a6:	00004697          	auipc	a3,0x4
ffffffffc02044aa:	e1268693          	addi	a3,a3,-494 # ffffffffc02082b8 <default_pmm_manager+0xe20>
ffffffffc02044ae:	00003617          	auipc	a2,0x3
ffffffffc02044b2:	8a260613          	addi	a2,a2,-1886 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02044b6:	0dc00593          	li	a1,220
ffffffffc02044ba:	00004517          	auipc	a0,0x4
ffffffffc02044be:	cae50513          	addi	a0,a0,-850 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc02044c2:	fc3fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02044c6 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc02044c6:	7139                	addi	sp,sp,-64
ffffffffc02044c8:	f822                	sd	s0,48(sp)
ffffffffc02044ca:	f426                	sd	s1,40(sp)
ffffffffc02044cc:	fc06                	sd	ra,56(sp)
ffffffffc02044ce:	f04a                	sd	s2,32(sp)
ffffffffc02044d0:	ec4e                	sd	s3,24(sp)
ffffffffc02044d2:	e852                	sd	s4,16(sp)
ffffffffc02044d4:	e456                	sd	s5,8(sp)

static void
check_vma_struct(void) {
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
ffffffffc02044d6:	c55ff0ef          	jal	ra,ffffffffc020412a <mm_create>
    assert(mm != NULL);
ffffffffc02044da:	842a                	mv	s0,a0
ffffffffc02044dc:	03200493          	li	s1,50
ffffffffc02044e0:	e919                	bnez	a0,ffffffffc02044f6 <vmm_init+0x30>
ffffffffc02044e2:	a989                	j	ffffffffc0204934 <vmm_init+0x46e>
        vma->vm_start = vm_start;
ffffffffc02044e4:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc02044e6:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02044e8:	00052c23          	sw	zero,24(a0)

    int i;
    for (i = step1; i >= 1; i --) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02044ec:	14ed                	addi	s1,s1,-5
ffffffffc02044ee:	8522                	mv	a0,s0
ffffffffc02044f0:	cf3ff0ef          	jal	ra,ffffffffc02041e2 <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc02044f4:	c88d                	beqz	s1,ffffffffc0204526 <vmm_init+0x60>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02044f6:	03000513          	li	a0,48
ffffffffc02044fa:	f5cfd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc02044fe:	85aa                	mv	a1,a0
ffffffffc0204500:	00248793          	addi	a5,s1,2
    if (vma != NULL) {
ffffffffc0204504:	f165                	bnez	a0,ffffffffc02044e4 <vmm_init+0x1e>
        assert(vma != NULL);
ffffffffc0204506:	00003697          	auipc	a3,0x3
ffffffffc020450a:	7d268693          	addi	a3,a3,2002 # ffffffffc0207cd8 <default_pmm_manager+0x840>
ffffffffc020450e:	00003617          	auipc	a2,0x3
ffffffffc0204512:	84260613          	addi	a2,a2,-1982 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0204516:	11c00593          	li	a1,284
ffffffffc020451a:	00004517          	auipc	a0,0x4
ffffffffc020451e:	c4e50513          	addi	a0,a0,-946 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc0204522:	f63fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    for (i = step1; i >= 1; i --) {
ffffffffc0204526:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc020452a:	1f900913          	li	s2,505
ffffffffc020452e:	a819                	j	ffffffffc0204544 <vmm_init+0x7e>
        vma->vm_start = vm_start;
ffffffffc0204530:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0204532:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0204534:	00052c23          	sw	zero,24(a0)
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0204538:	0495                	addi	s1,s1,5
ffffffffc020453a:	8522                	mv	a0,s0
ffffffffc020453c:	ca7ff0ef          	jal	ra,ffffffffc02041e2 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc0204540:	03248a63          	beq	s1,s2,ffffffffc0204574 <vmm_init+0xae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204544:	03000513          	li	a0,48
ffffffffc0204548:	f0efd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc020454c:	85aa                	mv	a1,a0
ffffffffc020454e:	00248793          	addi	a5,s1,2
    if (vma != NULL) {
ffffffffc0204552:	fd79                	bnez	a0,ffffffffc0204530 <vmm_init+0x6a>
        assert(vma != NULL);
ffffffffc0204554:	00003697          	auipc	a3,0x3
ffffffffc0204558:	78468693          	addi	a3,a3,1924 # ffffffffc0207cd8 <default_pmm_manager+0x840>
ffffffffc020455c:	00002617          	auipc	a2,0x2
ffffffffc0204560:	7f460613          	addi	a2,a2,2036 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0204564:	12200593          	li	a1,290
ffffffffc0204568:	00004517          	auipc	a0,0x4
ffffffffc020456c:	c0050513          	addi	a0,a0,-1024 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc0204570:	f15fb0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0204574:	6418                	ld	a4,8(s0)
ffffffffc0204576:	479d                	li	a5,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
ffffffffc0204578:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc020457c:	2ee40063          	beq	s0,a4,ffffffffc020485c <vmm_init+0x396>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0204580:	fe873603          	ld	a2,-24(a4)
ffffffffc0204584:	ffe78693          	addi	a3,a5,-2
ffffffffc0204588:	24d61a63          	bne	a2,a3,ffffffffc02047dc <vmm_init+0x316>
ffffffffc020458c:	ff073683          	ld	a3,-16(a4)
ffffffffc0204590:	24f69663          	bne	a3,a5,ffffffffc02047dc <vmm_init+0x316>
ffffffffc0204594:	0795                	addi	a5,a5,5
ffffffffc0204596:	6718                	ld	a4,8(a4)
    for (i = 1; i <= step2; i ++) {
ffffffffc0204598:	feb792e3          	bne	a5,a1,ffffffffc020457c <vmm_init+0xb6>
ffffffffc020459c:	491d                	li	s2,7
ffffffffc020459e:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc02045a0:	1f900a93          	li	s5,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc02045a4:	85a6                	mv	a1,s1
ffffffffc02045a6:	8522                	mv	a0,s0
ffffffffc02045a8:	bfdff0ef          	jal	ra,ffffffffc02041a4 <find_vma>
ffffffffc02045ac:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc02045ae:	30050763          	beqz	a0,ffffffffc02048bc <vmm_init+0x3f6>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc02045b2:	00148593          	addi	a1,s1,1
ffffffffc02045b6:	8522                	mv	a0,s0
ffffffffc02045b8:	bedff0ef          	jal	ra,ffffffffc02041a4 <find_vma>
ffffffffc02045bc:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc02045be:	2c050f63          	beqz	a0,ffffffffc020489c <vmm_init+0x3d6>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc02045c2:	85ca                	mv	a1,s2
ffffffffc02045c4:	8522                	mv	a0,s0
ffffffffc02045c6:	bdfff0ef          	jal	ra,ffffffffc02041a4 <find_vma>
        assert(vma3 == NULL);
ffffffffc02045ca:	2a051963          	bnez	a0,ffffffffc020487c <vmm_init+0x3b6>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc02045ce:	00348593          	addi	a1,s1,3
ffffffffc02045d2:	8522                	mv	a0,s0
ffffffffc02045d4:	bd1ff0ef          	jal	ra,ffffffffc02041a4 <find_vma>
        assert(vma4 == NULL);
ffffffffc02045d8:	32051263          	bnez	a0,ffffffffc02048fc <vmm_init+0x436>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc02045dc:	00448593          	addi	a1,s1,4
ffffffffc02045e0:	8522                	mv	a0,s0
ffffffffc02045e2:	bc3ff0ef          	jal	ra,ffffffffc02041a4 <find_vma>
        assert(vma5 == NULL);
ffffffffc02045e6:	2e051b63          	bnez	a0,ffffffffc02048dc <vmm_init+0x416>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc02045ea:	008a3783          	ld	a5,8(s4)
ffffffffc02045ee:	20979763          	bne	a5,s1,ffffffffc02047fc <vmm_init+0x336>
ffffffffc02045f2:	010a3783          	ld	a5,16(s4)
ffffffffc02045f6:	21279363          	bne	a5,s2,ffffffffc02047fc <vmm_init+0x336>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc02045fa:	0089b783          	ld	a5,8(s3)
ffffffffc02045fe:	20979f63          	bne	a5,s1,ffffffffc020481c <vmm_init+0x356>
ffffffffc0204602:	0109b783          	ld	a5,16(s3)
ffffffffc0204606:	21279b63          	bne	a5,s2,ffffffffc020481c <vmm_init+0x356>
ffffffffc020460a:	0495                	addi	s1,s1,5
ffffffffc020460c:	0915                	addi	s2,s2,5
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc020460e:	f9549be3          	bne	s1,s5,ffffffffc02045a4 <vmm_init+0xde>
ffffffffc0204612:	4491                	li	s1,4
    }

    for (i =4; i>=0; i--) {
ffffffffc0204614:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc0204616:	85a6                	mv	a1,s1
ffffffffc0204618:	8522                	mv	a0,s0
ffffffffc020461a:	b8bff0ef          	jal	ra,ffffffffc02041a4 <find_vma>
ffffffffc020461e:	0004859b          	sext.w	a1,s1
        if (vma_below_5 != NULL ) {
ffffffffc0204622:	c90d                	beqz	a0,ffffffffc0204654 <vmm_init+0x18e>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc0204624:	6914                	ld	a3,16(a0)
ffffffffc0204626:	6510                	ld	a2,8(a0)
ffffffffc0204628:	00004517          	auipc	a0,0x4
ffffffffc020462c:	e2850513          	addi	a0,a0,-472 # ffffffffc0208450 <default_pmm_manager+0xfb8>
ffffffffc0204630:	b5ffb0ef          	jal	ra,ffffffffc020018e <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc0204634:	00004697          	auipc	a3,0x4
ffffffffc0204638:	e4468693          	addi	a3,a3,-444 # ffffffffc0208478 <default_pmm_manager+0xfe0>
ffffffffc020463c:	00002617          	auipc	a2,0x2
ffffffffc0204640:	71460613          	addi	a2,a2,1812 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0204644:	14400593          	li	a1,324
ffffffffc0204648:	00004517          	auipc	a0,0x4
ffffffffc020464c:	b2050513          	addi	a0,a0,-1248 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc0204650:	e35fb0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0204654:	14fd                	addi	s1,s1,-1
    for (i =4; i>=0; i--) {
ffffffffc0204656:	fd2490e3          	bne	s1,s2,ffffffffc0204616 <vmm_init+0x150>
    }

    mm_destroy(mm);
ffffffffc020465a:	8522                	mv	a0,s0
ffffffffc020465c:	c55ff0ef          	jal	ra,ffffffffc02042b0 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0204660:	00004517          	auipc	a0,0x4
ffffffffc0204664:	e3050513          	addi	a0,a0,-464 # ffffffffc0208490 <default_pmm_manager+0xff8>
ffffffffc0204668:	b27fb0ef          	jal	ra,ffffffffc020018e <cprintf>
struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc020466c:	8b5fd0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
ffffffffc0204670:	89aa                	mv	s3,a0

    check_mm_struct = mm_create();
ffffffffc0204672:	ab9ff0ef          	jal	ra,ffffffffc020412a <mm_create>
ffffffffc0204676:	000b2797          	auipc	a5,0xb2
ffffffffc020467a:	66a7b923          	sd	a0,1650(a5) # ffffffffc02b6ce8 <check_mm_struct>
ffffffffc020467e:	84aa                	mv	s1,a0
    assert(check_mm_struct != NULL);
ffffffffc0204680:	36050663          	beqz	a0,ffffffffc02049ec <vmm_init+0x526>

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0204684:	000b2797          	auipc	a5,0xb2
ffffffffc0204688:	50c78793          	addi	a5,a5,1292 # ffffffffc02b6b90 <boot_pgdir>
ffffffffc020468c:	0007b903          	ld	s2,0(a5)
    assert(pgdir[0] == 0);
ffffffffc0204690:	00093783          	ld	a5,0(s2)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0204694:	01253c23          	sd	s2,24(a0)
    assert(pgdir[0] == 0);
ffffffffc0204698:	2c079e63          	bnez	a5,ffffffffc0204974 <vmm_init+0x4ae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020469c:	03000513          	li	a0,48
ffffffffc02046a0:	db6fd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc02046a4:	842a                	mv	s0,a0
    if (vma != NULL) {
ffffffffc02046a6:	18050b63          	beqz	a0,ffffffffc020483c <vmm_init+0x376>
        vma->vm_end = vm_end;
ffffffffc02046aa:	002007b7          	lui	a5,0x200
ffffffffc02046ae:	e81c                	sd	a5,16(s0)
        vma->vm_flags = vm_flags;
ffffffffc02046b0:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc02046b2:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc02046b4:	cc1c                	sw	a5,24(s0)
    insert_vma_struct(mm, vma);
ffffffffc02046b6:	8526                	mv	a0,s1
        vma->vm_start = vm_start;
ffffffffc02046b8:	00043423          	sd	zero,8(s0)
    insert_vma_struct(mm, vma);
ffffffffc02046bc:	b27ff0ef          	jal	ra,ffffffffc02041e2 <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc02046c0:	10000593          	li	a1,256
ffffffffc02046c4:	8526                	mv	a0,s1
ffffffffc02046c6:	adfff0ef          	jal	ra,ffffffffc02041a4 <find_vma>
ffffffffc02046ca:	10000793          	li	a5,256

    int i, sum = 0;

    for (i = 0; i < 100; i ++) {
ffffffffc02046ce:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc02046d2:	2ca41163          	bne	s0,a0,ffffffffc0204994 <vmm_init+0x4ce>
        *(char *)(addr + i) = i;
ffffffffc02046d6:	00f78023          	sb	a5,0(a5) # 200000 <_binary_obj___user_exit_out_size+0x1f5570>
        sum += i;
ffffffffc02046da:	0785                	addi	a5,a5,1
    for (i = 0; i < 100; i ++) {
ffffffffc02046dc:	fee79de3          	bne	a5,a4,ffffffffc02046d6 <vmm_init+0x210>
        sum += i;
ffffffffc02046e0:	6705                	lui	a4,0x1
    for (i = 0; i < 100; i ++) {
ffffffffc02046e2:	10000793          	li	a5,256
        sum += i;
ffffffffc02046e6:	35670713          	addi	a4,a4,854 # 1356 <_binary_obj___user_faultread_out_size-0x822a>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc02046ea:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc02046ee:	0007c683          	lbu	a3,0(a5)
ffffffffc02046f2:	0785                	addi	a5,a5,1
ffffffffc02046f4:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc02046f6:	fec79ce3          	bne	a5,a2,ffffffffc02046ee <vmm_init+0x228>
    }

    assert(sum == 0);
ffffffffc02046fa:	2c071963          	bnez	a4,ffffffffc02049cc <vmm_init+0x506>
    return pa2page(PDE_ADDR(pde));
ffffffffc02046fe:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0204702:	000b2a97          	auipc	s5,0xb2
ffffffffc0204706:	496a8a93          	addi	s5,s5,1174 # ffffffffc02b6b98 <npage>
ffffffffc020470a:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020470e:	078a                	slli	a5,a5,0x2
ffffffffc0204710:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0204712:	20e7f563          	bleu	a4,a5,ffffffffc020491c <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc0204716:	00004697          	auipc	a3,0x4
ffffffffc020471a:	79a68693          	addi	a3,a3,1946 # ffffffffc0208eb0 <nbase>
ffffffffc020471e:	0006ba03          	ld	s4,0(a3)
ffffffffc0204722:	414786b3          	sub	a3,a5,s4
ffffffffc0204726:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc0204728:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020472a:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc020472c:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc020472e:	83b1                	srli	a5,a5,0xc
ffffffffc0204730:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204732:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204734:	28e7f063          	bleu	a4,a5,ffffffffc02049b4 <vmm_init+0x4ee>
ffffffffc0204738:	000b2797          	auipc	a5,0xb2
ffffffffc020473c:	4c078793          	addi	a5,a5,1216 # ffffffffc02b6bf8 <va_pa_offset>
ffffffffc0204740:	6380                	ld	s0,0(a5)

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc0204742:	4581                	li	a1,0
ffffffffc0204744:	854a                	mv	a0,s2
ffffffffc0204746:	9436                	add	s0,s0,a3
ffffffffc0204748:	dbbfd0ef          	jal	ra,ffffffffc0202502 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc020474c:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc020474e:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc0204752:	078a                	slli	a5,a5,0x2
ffffffffc0204754:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0204756:	1ce7f363          	bleu	a4,a5,ffffffffc020491c <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc020475a:	000b2417          	auipc	s0,0xb2
ffffffffc020475e:	4ae40413          	addi	s0,s0,1198 # ffffffffc02b6c08 <pages>
ffffffffc0204762:	6008                	ld	a0,0(s0)
ffffffffc0204764:	414787b3          	sub	a5,a5,s4
ffffffffc0204768:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc020476a:	953e                	add	a0,a0,a5
ffffffffc020476c:	4585                	li	a1,1
ffffffffc020476e:	f6cfd0ef          	jal	ra,ffffffffc0201eda <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0204772:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0204776:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020477a:	078a                	slli	a5,a5,0x2
ffffffffc020477c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020477e:	18e7ff63          	bleu	a4,a5,ffffffffc020491c <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc0204782:	6008                	ld	a0,0(s0)
ffffffffc0204784:	414787b3          	sub	a5,a5,s4
ffffffffc0204788:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc020478a:	4585                	li	a1,1
ffffffffc020478c:	953e                	add	a0,a0,a5
ffffffffc020478e:	f4cfd0ef          	jal	ra,ffffffffc0201eda <free_pages>
    pgdir[0] = 0;
ffffffffc0204792:	00093023          	sd	zero,0(s2)
  asm volatile("sfence.vma");
ffffffffc0204796:	12000073          	sfence.vma
    flush_tlb();

    mm->pgdir = NULL;
ffffffffc020479a:	0004bc23          	sd	zero,24(s1)
    mm_destroy(mm);
ffffffffc020479e:	8526                	mv	a0,s1
ffffffffc02047a0:	b11ff0ef          	jal	ra,ffffffffc02042b0 <mm_destroy>
    check_mm_struct = NULL;
ffffffffc02047a4:	000b2797          	auipc	a5,0xb2
ffffffffc02047a8:	5407b223          	sd	zero,1348(a5) # ffffffffc02b6ce8 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02047ac:	f74fd0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
ffffffffc02047b0:	1aa99263          	bne	s3,a0,ffffffffc0204954 <vmm_init+0x48e>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc02047b4:	00004517          	auipc	a0,0x4
ffffffffc02047b8:	d6c50513          	addi	a0,a0,-660 # ffffffffc0208520 <default_pmm_manager+0x1088>
ffffffffc02047bc:	9d3fb0ef          	jal	ra,ffffffffc020018e <cprintf>
}
ffffffffc02047c0:	7442                	ld	s0,48(sp)
ffffffffc02047c2:	70e2                	ld	ra,56(sp)
ffffffffc02047c4:	74a2                	ld	s1,40(sp)
ffffffffc02047c6:	7902                	ld	s2,32(sp)
ffffffffc02047c8:	69e2                	ld	s3,24(sp)
ffffffffc02047ca:	6a42                	ld	s4,16(sp)
ffffffffc02047cc:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc02047ce:	00004517          	auipc	a0,0x4
ffffffffc02047d2:	d7250513          	addi	a0,a0,-654 # ffffffffc0208540 <default_pmm_manager+0x10a8>
}
ffffffffc02047d6:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc02047d8:	9b7fb06f          	j	ffffffffc020018e <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc02047dc:	00004697          	auipc	a3,0x4
ffffffffc02047e0:	b8c68693          	addi	a3,a3,-1140 # ffffffffc0208368 <default_pmm_manager+0xed0>
ffffffffc02047e4:	00002617          	auipc	a2,0x2
ffffffffc02047e8:	56c60613          	addi	a2,a2,1388 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02047ec:	12b00593          	li	a1,299
ffffffffc02047f0:	00004517          	auipc	a0,0x4
ffffffffc02047f4:	97850513          	addi	a0,a0,-1672 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc02047f8:	c8dfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc02047fc:	00004697          	auipc	a3,0x4
ffffffffc0204800:	bf468693          	addi	a3,a3,-1036 # ffffffffc02083f0 <default_pmm_manager+0xf58>
ffffffffc0204804:	00002617          	auipc	a2,0x2
ffffffffc0204808:	54c60613          	addi	a2,a2,1356 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc020480c:	13b00593          	li	a1,315
ffffffffc0204810:	00004517          	auipc	a0,0x4
ffffffffc0204814:	95850513          	addi	a0,a0,-1704 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc0204818:	c6dfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc020481c:	00004697          	auipc	a3,0x4
ffffffffc0204820:	c0468693          	addi	a3,a3,-1020 # ffffffffc0208420 <default_pmm_manager+0xf88>
ffffffffc0204824:	00002617          	auipc	a2,0x2
ffffffffc0204828:	52c60613          	addi	a2,a2,1324 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc020482c:	13c00593          	li	a1,316
ffffffffc0204830:	00004517          	auipc	a0,0x4
ffffffffc0204834:	93850513          	addi	a0,a0,-1736 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc0204838:	c4dfb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(vma != NULL);
ffffffffc020483c:	00003697          	auipc	a3,0x3
ffffffffc0204840:	49c68693          	addi	a3,a3,1180 # ffffffffc0207cd8 <default_pmm_manager+0x840>
ffffffffc0204844:	00002617          	auipc	a2,0x2
ffffffffc0204848:	50c60613          	addi	a2,a2,1292 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc020484c:	15b00593          	li	a1,347
ffffffffc0204850:	00004517          	auipc	a0,0x4
ffffffffc0204854:	91850513          	addi	a0,a0,-1768 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc0204858:	c2dfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc020485c:	00004697          	auipc	a3,0x4
ffffffffc0204860:	af468693          	addi	a3,a3,-1292 # ffffffffc0208350 <default_pmm_manager+0xeb8>
ffffffffc0204864:	00002617          	auipc	a2,0x2
ffffffffc0204868:	4ec60613          	addi	a2,a2,1260 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc020486c:	12900593          	li	a1,297
ffffffffc0204870:	00004517          	auipc	a0,0x4
ffffffffc0204874:	8f850513          	addi	a0,a0,-1800 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc0204878:	c0dfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma3 == NULL);
ffffffffc020487c:	00004697          	auipc	a3,0x4
ffffffffc0204880:	b4468693          	addi	a3,a3,-1212 # ffffffffc02083c0 <default_pmm_manager+0xf28>
ffffffffc0204884:	00002617          	auipc	a2,0x2
ffffffffc0204888:	4cc60613          	addi	a2,a2,1228 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc020488c:	13500593          	li	a1,309
ffffffffc0204890:	00004517          	auipc	a0,0x4
ffffffffc0204894:	8d850513          	addi	a0,a0,-1832 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc0204898:	bedfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma2 != NULL);
ffffffffc020489c:	00004697          	auipc	a3,0x4
ffffffffc02048a0:	b1468693          	addi	a3,a3,-1260 # ffffffffc02083b0 <default_pmm_manager+0xf18>
ffffffffc02048a4:	00002617          	auipc	a2,0x2
ffffffffc02048a8:	4ac60613          	addi	a2,a2,1196 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02048ac:	13300593          	li	a1,307
ffffffffc02048b0:	00004517          	auipc	a0,0x4
ffffffffc02048b4:	8b850513          	addi	a0,a0,-1864 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc02048b8:	bcdfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma1 != NULL);
ffffffffc02048bc:	00004697          	auipc	a3,0x4
ffffffffc02048c0:	ae468693          	addi	a3,a3,-1308 # ffffffffc02083a0 <default_pmm_manager+0xf08>
ffffffffc02048c4:	00002617          	auipc	a2,0x2
ffffffffc02048c8:	48c60613          	addi	a2,a2,1164 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02048cc:	13100593          	li	a1,305
ffffffffc02048d0:	00004517          	auipc	a0,0x4
ffffffffc02048d4:	89850513          	addi	a0,a0,-1896 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc02048d8:	badfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma5 == NULL);
ffffffffc02048dc:	00004697          	auipc	a3,0x4
ffffffffc02048e0:	b0468693          	addi	a3,a3,-1276 # ffffffffc02083e0 <default_pmm_manager+0xf48>
ffffffffc02048e4:	00002617          	auipc	a2,0x2
ffffffffc02048e8:	46c60613          	addi	a2,a2,1132 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02048ec:	13900593          	li	a1,313
ffffffffc02048f0:	00004517          	auipc	a0,0x4
ffffffffc02048f4:	87850513          	addi	a0,a0,-1928 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc02048f8:	b8dfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma4 == NULL);
ffffffffc02048fc:	00004697          	auipc	a3,0x4
ffffffffc0204900:	ad468693          	addi	a3,a3,-1324 # ffffffffc02083d0 <default_pmm_manager+0xf38>
ffffffffc0204904:	00002617          	auipc	a2,0x2
ffffffffc0204908:	44c60613          	addi	a2,a2,1100 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc020490c:	13700593          	li	a1,311
ffffffffc0204910:	00004517          	auipc	a0,0x4
ffffffffc0204914:	85850513          	addi	a0,a0,-1960 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc0204918:	b6dfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020491c:	00003617          	auipc	a2,0x3
ffffffffc0204920:	c2c60613          	addi	a2,a2,-980 # ffffffffc0207548 <default_pmm_manager+0xb0>
ffffffffc0204924:	06200593          	li	a1,98
ffffffffc0204928:	00003517          	auipc	a0,0x3
ffffffffc020492c:	be850513          	addi	a0,a0,-1048 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0204930:	b55fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(mm != NULL);
ffffffffc0204934:	00003697          	auipc	a3,0x3
ffffffffc0204938:	36c68693          	addi	a3,a3,876 # ffffffffc0207ca0 <default_pmm_manager+0x808>
ffffffffc020493c:	00002617          	auipc	a2,0x2
ffffffffc0204940:	41460613          	addi	a2,a2,1044 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0204944:	11500593          	li	a1,277
ffffffffc0204948:	00004517          	auipc	a0,0x4
ffffffffc020494c:	82050513          	addi	a0,a0,-2016 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc0204950:	b35fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc0204954:	00004697          	auipc	a3,0x4
ffffffffc0204958:	ba468693          	addi	a3,a3,-1116 # ffffffffc02084f8 <default_pmm_manager+0x1060>
ffffffffc020495c:	00002617          	auipc	a2,0x2
ffffffffc0204960:	3f460613          	addi	a2,a2,1012 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0204964:	17900593          	li	a1,377
ffffffffc0204968:	00004517          	auipc	a0,0x4
ffffffffc020496c:	80050513          	addi	a0,a0,-2048 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc0204970:	b15fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0204974:	00003697          	auipc	a3,0x3
ffffffffc0204978:	35468693          	addi	a3,a3,852 # ffffffffc0207cc8 <default_pmm_manager+0x830>
ffffffffc020497c:	00002617          	auipc	a2,0x2
ffffffffc0204980:	3d460613          	addi	a2,a2,980 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0204984:	15800593          	li	a1,344
ffffffffc0204988:	00003517          	auipc	a0,0x3
ffffffffc020498c:	7e050513          	addi	a0,a0,2016 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc0204990:	af5fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0204994:	00004697          	auipc	a3,0x4
ffffffffc0204998:	b3468693          	addi	a3,a3,-1228 # ffffffffc02084c8 <default_pmm_manager+0x1030>
ffffffffc020499c:	00002617          	auipc	a2,0x2
ffffffffc02049a0:	3b460613          	addi	a2,a2,948 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02049a4:	16000593          	li	a1,352
ffffffffc02049a8:	00003517          	auipc	a0,0x3
ffffffffc02049ac:	7c050513          	addi	a0,a0,1984 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc02049b0:	ad5fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc02049b4:	00003617          	auipc	a2,0x3
ffffffffc02049b8:	b3460613          	addi	a2,a2,-1228 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc02049bc:	06900593          	li	a1,105
ffffffffc02049c0:	00003517          	auipc	a0,0x3
ffffffffc02049c4:	b5050513          	addi	a0,a0,-1200 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc02049c8:	abdfb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(sum == 0);
ffffffffc02049cc:	00004697          	auipc	a3,0x4
ffffffffc02049d0:	b1c68693          	addi	a3,a3,-1252 # ffffffffc02084e8 <default_pmm_manager+0x1050>
ffffffffc02049d4:	00002617          	auipc	a2,0x2
ffffffffc02049d8:	37c60613          	addi	a2,a2,892 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02049dc:	16c00593          	li	a1,364
ffffffffc02049e0:	00003517          	auipc	a0,0x3
ffffffffc02049e4:	78850513          	addi	a0,a0,1928 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc02049e8:	a9dfb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc02049ec:	00004697          	auipc	a3,0x4
ffffffffc02049f0:	ac468693          	addi	a3,a3,-1340 # ffffffffc02084b0 <default_pmm_manager+0x1018>
ffffffffc02049f4:	00002617          	auipc	a2,0x2
ffffffffc02049f8:	35c60613          	addi	a2,a2,860 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02049fc:	15400593          	li	a1,340
ffffffffc0204a00:	00003517          	auipc	a0,0x3
ffffffffc0204a04:	76850513          	addi	a0,a0,1896 # ffffffffc0208168 <default_pmm_manager+0xcd0>
ffffffffc0204a08:	a7dfb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204a0c <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc0204a0c:	715d                	addi	sp,sp,-80
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0204a0e:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc0204a10:	e0a2                	sd	s0,64(sp)
ffffffffc0204a12:	fc26                	sd	s1,56(sp)
ffffffffc0204a14:	e486                	sd	ra,72(sp)
ffffffffc0204a16:	f84a                	sd	s2,48(sp)
ffffffffc0204a18:	f44e                	sd	s3,40(sp)
ffffffffc0204a1a:	f052                	sd	s4,32(sp)
ffffffffc0204a1c:	ec56                	sd	s5,24(sp)
ffffffffc0204a1e:	e85a                	sd	s6,16(sp)
ffffffffc0204a20:	8432                	mv	s0,a2
ffffffffc0204a22:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc0204a24:	f80ff0ef          	jal	ra,ffffffffc02041a4 <find_vma>

    pgfault_num++;
ffffffffc0204a28:	000b2797          	auipc	a5,0xb2
ffffffffc0204a2c:	18478793          	addi	a5,a5,388 # ffffffffc02b6bac <pgfault_num>
ffffffffc0204a30:	439c                	lw	a5,0(a5)
ffffffffc0204a32:	2785                	addiw	a5,a5,1
ffffffffc0204a34:	000b2717          	auipc	a4,0xb2
ffffffffc0204a38:	16f72c23          	sw	a5,376(a4) # ffffffffc02b6bac <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc0204a3c:	18050863          	beqz	a0,ffffffffc0204bcc <do_pgfault+0x1c0>
ffffffffc0204a40:	651c                	ld	a5,8(a0)
ffffffffc0204a42:	18f46563          	bltu	s0,a5,ffffffffc0204bcc <do_pgfault+0x1c0>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0204a46:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc0204a48:	4941                	li	s2,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc0204a4a:	8b89                	andi	a5,a5,2
ffffffffc0204a4c:	ebad                	bnez	a5,ffffffffc0204abe <do_pgfault+0xb2>
        perm |= READ_WRITE;
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0204a4e:	767d                	lui	a2,0xfffff

    pte_t *ptep=NULL;
  
    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0204a50:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc0204a52:	8c71                	and	s0,s0,a2
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc0204a54:	85a2                	mv	a1,s0
ffffffffc0204a56:	4605                	li	a2,1
ffffffffc0204a58:	d08fd0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc0204a5c:	18050963          	beqz	a0,ffffffffc0204bee <do_pgfault+0x1e2>
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
ffffffffc0204a60:	610c                	ld	a1,0(a0)
ffffffffc0204a62:	c1a5                	beqz	a1,ffffffffc0204ac2 <do_pgfault+0xb6>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if((*ptep & PTE_R)&&!(*ptep & PTE_W)){
ffffffffc0204a64:	0065f793          	andi	a5,a1,6
ffffffffc0204a68:	4709                	li	a4,2
ffffffffc0204a6a:	06e78b63          	beq	a5,a4,ffffffffc0204ae0 <do_pgfault+0xd4>
                page_insert(mm->pgdir,page,addr,perm|PTE_W|PTE_R|PTE_V);
                cprintf("Solve own write only read page!\n");
            }
        }
        else{
            if (swap_init_ok) {
ffffffffc0204a6e:	000b2797          	auipc	a5,0xb2
ffffffffc0204a72:	13a78793          	addi	a5,a5,314 # ffffffffc02b6ba8 <swap_init_ok>
ffffffffc0204a76:	439c                	lw	a5,0(a5)
ffffffffc0204a78:	2781                	sext.w	a5,a5
ffffffffc0204a7a:	16078263          	beqz	a5,ffffffffc0204bde <do_pgfault+0x1d2>
                //(2) According to the mm,
                //addr AND page, setup the
                //map of phy addr <--->
                //logical addr
                //(3) make the page swappable.
                swap_in(mm, addr, &page);  //这个里面有alloc_page可能缺页置换，然后把换出去的位于磁盘的页读取至新页page
ffffffffc0204a7e:	85a2                	mv	a1,s0
ffffffffc0204a80:	0030                	addi	a2,sp,8
ffffffffc0204a82:	8526                	mv	a0,s1
                struct Page *page = NULL;
ffffffffc0204a84:	e402                	sd	zero,8(sp)
                swap_in(mm, addr, &page);  //这个里面有alloc_page可能缺页置换，然后把换出去的位于磁盘的页读取至新页page
ffffffffc0204a86:	a1eff0ef          	jal	ra,ffffffffc0203ca4 <swap_in>
                page_insert(mm->pgdir, page, addr, perm); //更新页表，插入新的页表项
ffffffffc0204a8a:	65a2                	ld	a1,8(sp)
ffffffffc0204a8c:	6c88                	ld	a0,24(s1)
ffffffffc0204a8e:	86ca                	mv	a3,s2
ffffffffc0204a90:	8622                	mv	a2,s0
ffffffffc0204a92:	ae5fd0ef          	jal	ra,ffffffffc0202576 <page_insert>
            
                // setup the map of phy addr <---> virtual addr
                swap_map_swappable(mm, addr, page, 1);  //(3) make the page swappable.
ffffffffc0204a96:	6622                	ld	a2,8(sp)
ffffffffc0204a98:	4685                	li	a3,1
ffffffffc0204a9a:	85a2                	mv	a1,s0
ffffffffc0204a9c:	8526                	mv	a0,s1
ffffffffc0204a9e:	8e2ff0ef          	jal	ra,ffffffffc0203b80 <swap_map_swappable>
                page->pra_vaddr = addr;
ffffffffc0204aa2:	6722                	ld	a4,8(sp)
                goto failed;
            }
        }
        
   }
   ret = 0;
ffffffffc0204aa4:	4781                	li	a5,0
                page->pra_vaddr = addr;
ffffffffc0204aa6:	ff00                	sd	s0,56(a4)
failed:
    return ret;
}
ffffffffc0204aa8:	60a6                	ld	ra,72(sp)
ffffffffc0204aaa:	6406                	ld	s0,64(sp)
ffffffffc0204aac:	74e2                	ld	s1,56(sp)
ffffffffc0204aae:	7942                	ld	s2,48(sp)
ffffffffc0204ab0:	79a2                	ld	s3,40(sp)
ffffffffc0204ab2:	7a02                	ld	s4,32(sp)
ffffffffc0204ab4:	6ae2                	ld	s5,24(sp)
ffffffffc0204ab6:	6b42                	ld	s6,16(sp)
ffffffffc0204ab8:	853e                	mv	a0,a5
ffffffffc0204aba:	6161                	addi	sp,sp,80
ffffffffc0204abc:	8082                	ret
        perm |= READ_WRITE;
ffffffffc0204abe:	495d                	li	s2,23
ffffffffc0204ac0:	b779                	j	ffffffffc0204a4e <do_pgfault+0x42>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0204ac2:	6c88                	ld	a0,24(s1)
ffffffffc0204ac4:	864a                	mv	a2,s2
ffffffffc0204ac6:	85a2                	mv	a1,s0
ffffffffc0204ac8:	895fe0ef          	jal	ra,ffffffffc020335c <pgdir_alloc_page>
   ret = 0;
ffffffffc0204acc:	4781                	li	a5,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0204ace:	fd69                	bnez	a0,ffffffffc0204aa8 <do_pgfault+0x9c>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0204ad0:	00003517          	auipc	a0,0x3
ffffffffc0204ad4:	6f850513          	addi	a0,a0,1784 # ffffffffc02081c8 <default_pmm_manager+0xd30>
ffffffffc0204ad8:	eb6fb0ef          	jal	ra,ffffffffc020018e <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204adc:	57f1                	li	a5,-4
            goto failed;
ffffffffc0204ade:	b7e9                	j	ffffffffc0204aa8 <do_pgfault+0x9c>
    if (!(pte & PTE_V)) {
ffffffffc0204ae0:	0015f793          	andi	a5,a1,1
ffffffffc0204ae4:	14078663          	beqz	a5,ffffffffc0204c30 <do_pgfault+0x224>
    if (PPN(pa) >= npage) {
ffffffffc0204ae8:	000b2a17          	auipc	s4,0xb2
ffffffffc0204aec:	0b0a0a13          	addi	s4,s4,176 # ffffffffc02b6b98 <npage>
ffffffffc0204af0:	000a3783          	ld	a5,0(s4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0204af4:	058a                	slli	a1,a1,0x2
ffffffffc0204af6:	81b1                	srli	a1,a1,0xc
    if (PPN(pa) >= npage) {
ffffffffc0204af8:	12f5f063          	bleu	a5,a1,ffffffffc0204c18 <do_pgfault+0x20c>
    return &pages[PPN(pa) - nbase];
ffffffffc0204afc:	00004797          	auipc	a5,0x4
ffffffffc0204b00:	3b478793          	addi	a5,a5,948 # ffffffffc0208eb0 <nbase>
ffffffffc0204b04:	0007b983          	ld	s3,0(a5)
ffffffffc0204b08:	000b2a97          	auipc	s5,0xb2
ffffffffc0204b0c:	100a8a93          	addi	s5,s5,256 # ffffffffc02b6c08 <pages>
ffffffffc0204b10:	000ab903          	ld	s2,0(s5)
ffffffffc0204b14:	413585b3          	sub	a1,a1,s3
ffffffffc0204b18:	059a                	slli	a1,a1,0x6
ffffffffc0204b1a:	992e                	add	s2,s2,a1
            if(page_ref(page)>1){// 多个进程引用
ffffffffc0204b1c:	00092703          	lw	a4,0(s2)
ffffffffc0204b20:	4785                	li	a5,1
ffffffffc0204b22:	08e7d163          	ble	a4,a5,ffffffffc0204ba4 <do_pgfault+0x198>
                cprintf("Copy-on-write error!\n");
ffffffffc0204b26:	00003517          	auipc	a0,0x3
ffffffffc0204b2a:	6ca50513          	addi	a0,a0,1738 # ffffffffc02081f0 <default_pmm_manager+0xd58>
ffffffffc0204b2e:	e60fb0ef          	jal	ra,ffffffffc020018e <cprintf>
                struct Page *npage = alloc_page();
ffffffffc0204b32:	4505                	li	a0,1
ffffffffc0204b34:	b1efd0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
    return page - pages + nbase;
ffffffffc0204b38:	000ab703          	ld	a4,0(s5)
    return KADDR(page2pa(page));
ffffffffc0204b3c:	567d                	li	a2,-1
ffffffffc0204b3e:	000a3803          	ld	a6,0(s4)
    return page - pages + nbase;
ffffffffc0204b42:	40e906b3          	sub	a3,s2,a4
ffffffffc0204b46:	8699                	srai	a3,a3,0x6
ffffffffc0204b48:	96ce                	add	a3,a3,s3
    return KADDR(page2pa(page));
ffffffffc0204b4a:	8231                	srli	a2,a2,0xc
ffffffffc0204b4c:	00c6f7b3          	and	a5,a3,a2
ffffffffc0204b50:	8b2a                	mv	s6,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b52:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204b54:	0b07f663          	bleu	a6,a5,ffffffffc0204c00 <do_pgfault+0x1f4>
    return page - pages + nbase;
ffffffffc0204b58:	40e507b3          	sub	a5,a0,a4
    return KADDR(page2pa(page));
ffffffffc0204b5c:	000b2717          	auipc	a4,0xb2
ffffffffc0204b60:	09c70713          	addi	a4,a4,156 # ffffffffc02b6bf8 <va_pa_offset>
ffffffffc0204b64:	6308                	ld	a0,0(a4)
    return page - pages + nbase;
ffffffffc0204b66:	8799                	srai	a5,a5,0x6
ffffffffc0204b68:	97ce                	add	a5,a5,s3
    return KADDR(page2pa(page));
ffffffffc0204b6a:	8e7d                	and	a2,a2,a5
ffffffffc0204b6c:	00a685b3          	add	a1,a3,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b70:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0204b72:	09067663          	bleu	a6,a2,ffffffffc0204bfe <do_pgfault+0x1f2>
                memcpy(dst_kvaddr,src_kvaddr,PGSIZE);
ffffffffc0204b76:	953e                	add	a0,a0,a5
ffffffffc0204b78:	6605                	lui	a2,0x1
ffffffffc0204b7a:	3cd010ef          	jal	ra,ffffffffc0206746 <memcpy>
                page_insert(mm->pgdir,npage,addr,perm|PTE_USER);
ffffffffc0204b7e:	6c88                	ld	a0,24(s1)
ffffffffc0204b80:	46fd                	li	a3,31
ffffffffc0204b82:	8622                	mv	a2,s0
ffffffffc0204b84:	85da                	mv	a1,s6
ffffffffc0204b86:	9f1fd0ef          	jal	ra,ffffffffc0202576 <page_insert>
    page->ref -= 1;
ffffffffc0204b8a:	00092783          	lw	a5,0(s2)
                cprintf("Solve Copy-on-write error!\n");
ffffffffc0204b8e:	00003517          	auipc	a0,0x3
ffffffffc0204b92:	67a50513          	addi	a0,a0,1658 # ffffffffc0208208 <default_pmm_manager+0xd70>
ffffffffc0204b96:	37fd                	addiw	a5,a5,-1
ffffffffc0204b98:	00f92023          	sw	a5,0(s2)
ffffffffc0204b9c:	df2fb0ef          	jal	ra,ffffffffc020018e <cprintf>
   ret = 0;
ffffffffc0204ba0:	4781                	li	a5,0
ffffffffc0204ba2:	b719                	j	ffffffffc0204aa8 <do_pgfault+0x9c>
                cprintf("Own write only read page!\n");
ffffffffc0204ba4:	00003517          	auipc	a0,0x3
ffffffffc0204ba8:	68450513          	addi	a0,a0,1668 # ffffffffc0208228 <default_pmm_manager+0xd90>
ffffffffc0204bac:	de2fb0ef          	jal	ra,ffffffffc020018e <cprintf>
                page_insert(mm->pgdir,page,addr,perm|PTE_W|PTE_R|PTE_V);
ffffffffc0204bb0:	6c88                	ld	a0,24(s1)
ffffffffc0204bb2:	46dd                	li	a3,23
ffffffffc0204bb4:	8622                	mv	a2,s0
ffffffffc0204bb6:	85ca                	mv	a1,s2
ffffffffc0204bb8:	9bffd0ef          	jal	ra,ffffffffc0202576 <page_insert>
                cprintf("Solve own write only read page!\n");
ffffffffc0204bbc:	00003517          	auipc	a0,0x3
ffffffffc0204bc0:	68c50513          	addi	a0,a0,1676 # ffffffffc0208248 <default_pmm_manager+0xdb0>
ffffffffc0204bc4:	dcafb0ef          	jal	ra,ffffffffc020018e <cprintf>
   ret = 0;
ffffffffc0204bc8:	4781                	li	a5,0
ffffffffc0204bca:	bdf9                	j	ffffffffc0204aa8 <do_pgfault+0x9c>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc0204bcc:	85a2                	mv	a1,s0
ffffffffc0204bce:	00003517          	auipc	a0,0x3
ffffffffc0204bd2:	5aa50513          	addi	a0,a0,1450 # ffffffffc0208178 <default_pmm_manager+0xce0>
ffffffffc0204bd6:	db8fb0ef          	jal	ra,ffffffffc020018e <cprintf>
    int ret = -E_INVAL;
ffffffffc0204bda:	57f5                	li	a5,-3
        goto failed;
ffffffffc0204bdc:	b5f1                	j	ffffffffc0204aa8 <do_pgfault+0x9c>
                cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0204bde:	00003517          	auipc	a0,0x3
ffffffffc0204be2:	69250513          	addi	a0,a0,1682 # ffffffffc0208270 <default_pmm_manager+0xdd8>
ffffffffc0204be6:	da8fb0ef          	jal	ra,ffffffffc020018e <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204bea:	57f1                	li	a5,-4
                goto failed;
ffffffffc0204bec:	bd75                	j	ffffffffc0204aa8 <do_pgfault+0x9c>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc0204bee:	00003517          	auipc	a0,0x3
ffffffffc0204bf2:	5ba50513          	addi	a0,a0,1466 # ffffffffc02081a8 <default_pmm_manager+0xd10>
ffffffffc0204bf6:	d98fb0ef          	jal	ra,ffffffffc020018e <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204bfa:	57f1                	li	a5,-4
        goto failed;
ffffffffc0204bfc:	b575                	j	ffffffffc0204aa8 <do_pgfault+0x9c>
    return KADDR(page2pa(page));
ffffffffc0204bfe:	86be                	mv	a3,a5
ffffffffc0204c00:	00003617          	auipc	a2,0x3
ffffffffc0204c04:	8e860613          	addi	a2,a2,-1816 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc0204c08:	06900593          	li	a1,105
ffffffffc0204c0c:	00003517          	auipc	a0,0x3
ffffffffc0204c10:	90450513          	addi	a0,a0,-1788 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0204c14:	871fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204c18:	00003617          	auipc	a2,0x3
ffffffffc0204c1c:	93060613          	addi	a2,a2,-1744 # ffffffffc0207548 <default_pmm_manager+0xb0>
ffffffffc0204c20:	06200593          	li	a1,98
ffffffffc0204c24:	00003517          	auipc	a0,0x3
ffffffffc0204c28:	8ec50513          	addi	a0,a0,-1812 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0204c2c:	859fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0204c30:	00003617          	auipc	a2,0x3
ffffffffc0204c34:	b8860613          	addi	a2,a2,-1144 # ffffffffc02077b8 <default_pmm_manager+0x320>
ffffffffc0204c38:	07400593          	li	a1,116
ffffffffc0204c3c:	00003517          	auipc	a0,0x3
ffffffffc0204c40:	8d450513          	addi	a0,a0,-1836 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0204c44:	841fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204c48 <user_mem_check>:

bool
user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write) {
ffffffffc0204c48:	7179                	addi	sp,sp,-48
ffffffffc0204c4a:	f022                	sd	s0,32(sp)
ffffffffc0204c4c:	f406                	sd	ra,40(sp)
ffffffffc0204c4e:	ec26                	sd	s1,24(sp)
ffffffffc0204c50:	e84a                	sd	s2,16(sp)
ffffffffc0204c52:	e44e                	sd	s3,8(sp)
ffffffffc0204c54:	e052                	sd	s4,0(sp)
ffffffffc0204c56:	842e                	mv	s0,a1
    if (mm != NULL) {
ffffffffc0204c58:	c135                	beqz	a0,ffffffffc0204cbc <user_mem_check+0x74>
        if (!USER_ACCESS(addr, addr + len)) {
ffffffffc0204c5a:	002007b7          	lui	a5,0x200
ffffffffc0204c5e:	04f5e663          	bltu	a1,a5,ffffffffc0204caa <user_mem_check+0x62>
ffffffffc0204c62:	00c584b3          	add	s1,a1,a2
ffffffffc0204c66:	0495f263          	bleu	s1,a1,ffffffffc0204caa <user_mem_check+0x62>
ffffffffc0204c6a:	4785                	li	a5,1
ffffffffc0204c6c:	07fe                	slli	a5,a5,0x1f
ffffffffc0204c6e:	0297ee63          	bltu	a5,s1,ffffffffc0204caa <user_mem_check+0x62>
ffffffffc0204c72:	892a                	mv	s2,a0
ffffffffc0204c74:	89b6                	mv	s3,a3
            }
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK)) {
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204c76:	6a05                	lui	s4,0x1
ffffffffc0204c78:	a821                	j	ffffffffc0204c90 <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204c7a:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204c7e:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc0204c80:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204c82:	c685                	beqz	a3,ffffffffc0204caa <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc0204c84:	c399                	beqz	a5,ffffffffc0204c8a <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204c86:	02e46263          	bltu	s0,a4,ffffffffc0204caa <user_mem_check+0x62>
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0204c8a:	6900                	ld	s0,16(a0)
        while (start < end) {
ffffffffc0204c8c:	04947663          	bleu	s1,s0,ffffffffc0204cd8 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start) {
ffffffffc0204c90:	85a2                	mv	a1,s0
ffffffffc0204c92:	854a                	mv	a0,s2
ffffffffc0204c94:	d10ff0ef          	jal	ra,ffffffffc02041a4 <find_vma>
ffffffffc0204c98:	c909                	beqz	a0,ffffffffc0204caa <user_mem_check+0x62>
ffffffffc0204c9a:	6518                	ld	a4,8(a0)
ffffffffc0204c9c:	00e46763          	bltu	s0,a4,ffffffffc0204caa <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204ca0:	4d1c                	lw	a5,24(a0)
ffffffffc0204ca2:	fc099ce3          	bnez	s3,ffffffffc0204c7a <user_mem_check+0x32>
ffffffffc0204ca6:	8b85                	andi	a5,a5,1
ffffffffc0204ca8:	f3ed                	bnez	a5,ffffffffc0204c8a <user_mem_check+0x42>
            return 0;
ffffffffc0204caa:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0204cac:	70a2                	ld	ra,40(sp)
ffffffffc0204cae:	7402                	ld	s0,32(sp)
ffffffffc0204cb0:	64e2                	ld	s1,24(sp)
ffffffffc0204cb2:	6942                	ld	s2,16(sp)
ffffffffc0204cb4:	69a2                	ld	s3,8(sp)
ffffffffc0204cb6:	6a02                	ld	s4,0(sp)
ffffffffc0204cb8:	6145                	addi	sp,sp,48
ffffffffc0204cba:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0204cbc:	c02007b7          	lui	a5,0xc0200
ffffffffc0204cc0:	4501                	li	a0,0
ffffffffc0204cc2:	fef5e5e3          	bltu	a1,a5,ffffffffc0204cac <user_mem_check+0x64>
ffffffffc0204cc6:	962e                	add	a2,a2,a1
ffffffffc0204cc8:	fec5f2e3          	bleu	a2,a1,ffffffffc0204cac <user_mem_check+0x64>
ffffffffc0204ccc:	c8000537          	lui	a0,0xc8000
ffffffffc0204cd0:	0505                	addi	a0,a0,1
ffffffffc0204cd2:	00a63533          	sltu	a0,a2,a0
ffffffffc0204cd6:	bfd9                	j	ffffffffc0204cac <user_mem_check+0x64>
        return 1;
ffffffffc0204cd8:	4505                	li	a0,1
ffffffffc0204cda:	bfc9                	j	ffffffffc0204cac <user_mem_check+0x64>

ffffffffc0204cdc <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0204cdc:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204cde:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0204ce0:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204ce2:	91dfb0ef          	jal	ra,ffffffffc02005fe <ide_device_valid>
ffffffffc0204ce6:	cd01                	beqz	a0,ffffffffc0204cfe <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204ce8:	4505                	li	a0,1
ffffffffc0204cea:	91bfb0ef          	jal	ra,ffffffffc0200604 <ide_device_size>
}
ffffffffc0204cee:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204cf0:	810d                	srli	a0,a0,0x3
ffffffffc0204cf2:	000b2797          	auipc	a5,0xb2
ffffffffc0204cf6:	faa7b323          	sd	a0,-90(a5) # ffffffffc02b6c98 <max_swap_offset>
}
ffffffffc0204cfa:	0141                	addi	sp,sp,16
ffffffffc0204cfc:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0204cfe:	00004617          	auipc	a2,0x4
ffffffffc0204d02:	85a60613          	addi	a2,a2,-1958 # ffffffffc0208558 <default_pmm_manager+0x10c0>
ffffffffc0204d06:	45b5                	li	a1,13
ffffffffc0204d08:	00004517          	auipc	a0,0x4
ffffffffc0204d0c:	87050513          	addi	a0,a0,-1936 # ffffffffc0208578 <default_pmm_manager+0x10e0>
ffffffffc0204d10:	f74fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204d14 <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0204d14:	1141                	addi	sp,sp,-16
ffffffffc0204d16:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204d18:	00855793          	srli	a5,a0,0x8
ffffffffc0204d1c:	cfb9                	beqz	a5,ffffffffc0204d7a <swapfs_read+0x66>
ffffffffc0204d1e:	000b2717          	auipc	a4,0xb2
ffffffffc0204d22:	f7a70713          	addi	a4,a4,-134 # ffffffffc02b6c98 <max_swap_offset>
ffffffffc0204d26:	6318                	ld	a4,0(a4)
ffffffffc0204d28:	04e7f963          	bleu	a4,a5,ffffffffc0204d7a <swapfs_read+0x66>
    return page - pages + nbase;
ffffffffc0204d2c:	000b2717          	auipc	a4,0xb2
ffffffffc0204d30:	edc70713          	addi	a4,a4,-292 # ffffffffc02b6c08 <pages>
ffffffffc0204d34:	6310                	ld	a2,0(a4)
ffffffffc0204d36:	00004717          	auipc	a4,0x4
ffffffffc0204d3a:	17a70713          	addi	a4,a4,378 # ffffffffc0208eb0 <nbase>
    return KADDR(page2pa(page));
ffffffffc0204d3e:	000b2697          	auipc	a3,0xb2
ffffffffc0204d42:	e5a68693          	addi	a3,a3,-422 # ffffffffc02b6b98 <npage>
    return page - pages + nbase;
ffffffffc0204d46:	40c58633          	sub	a2,a1,a2
ffffffffc0204d4a:	630c                	ld	a1,0(a4)
ffffffffc0204d4c:	8619                	srai	a2,a2,0x6
    return KADDR(page2pa(page));
ffffffffc0204d4e:	577d                	li	a4,-1
ffffffffc0204d50:	6294                	ld	a3,0(a3)
    return page - pages + nbase;
ffffffffc0204d52:	962e                	add	a2,a2,a1
    return KADDR(page2pa(page));
ffffffffc0204d54:	8331                	srli	a4,a4,0xc
ffffffffc0204d56:	8f71                	and	a4,a4,a2
ffffffffc0204d58:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d5c:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204d5e:	02d77a63          	bleu	a3,a4,ffffffffc0204d92 <swapfs_read+0x7e>
ffffffffc0204d62:	000b2797          	auipc	a5,0xb2
ffffffffc0204d66:	e9678793          	addi	a5,a5,-362 # ffffffffc02b6bf8 <va_pa_offset>
ffffffffc0204d6a:	639c                	ld	a5,0(a5)
}
ffffffffc0204d6c:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204d6e:	46a1                	li	a3,8
ffffffffc0204d70:	963e                	add	a2,a2,a5
ffffffffc0204d72:	4505                	li	a0,1
}
ffffffffc0204d74:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204d76:	895fb06f          	j	ffffffffc020060a <ide_read_secs>
ffffffffc0204d7a:	86aa                	mv	a3,a0
ffffffffc0204d7c:	00004617          	auipc	a2,0x4
ffffffffc0204d80:	81460613          	addi	a2,a2,-2028 # ffffffffc0208590 <default_pmm_manager+0x10f8>
ffffffffc0204d84:	45d1                	li	a1,20
ffffffffc0204d86:	00003517          	auipc	a0,0x3
ffffffffc0204d8a:	7f250513          	addi	a0,a0,2034 # ffffffffc0208578 <default_pmm_manager+0x10e0>
ffffffffc0204d8e:	ef6fb0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0204d92:	86b2                	mv	a3,a2
ffffffffc0204d94:	06900593          	li	a1,105
ffffffffc0204d98:	00002617          	auipc	a2,0x2
ffffffffc0204d9c:	75060613          	addi	a2,a2,1872 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc0204da0:	00002517          	auipc	a0,0x2
ffffffffc0204da4:	77050513          	addi	a0,a0,1904 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0204da8:	edcfb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204dac <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0204dac:	1141                	addi	sp,sp,-16
ffffffffc0204dae:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204db0:	00855793          	srli	a5,a0,0x8
ffffffffc0204db4:	cfb9                	beqz	a5,ffffffffc0204e12 <swapfs_write+0x66>
ffffffffc0204db6:	000b2717          	auipc	a4,0xb2
ffffffffc0204dba:	ee270713          	addi	a4,a4,-286 # ffffffffc02b6c98 <max_swap_offset>
ffffffffc0204dbe:	6318                	ld	a4,0(a4)
ffffffffc0204dc0:	04e7f963          	bleu	a4,a5,ffffffffc0204e12 <swapfs_write+0x66>
    return page - pages + nbase;
ffffffffc0204dc4:	000b2717          	auipc	a4,0xb2
ffffffffc0204dc8:	e4470713          	addi	a4,a4,-444 # ffffffffc02b6c08 <pages>
ffffffffc0204dcc:	6310                	ld	a2,0(a4)
ffffffffc0204dce:	00004717          	auipc	a4,0x4
ffffffffc0204dd2:	0e270713          	addi	a4,a4,226 # ffffffffc0208eb0 <nbase>
    return KADDR(page2pa(page));
ffffffffc0204dd6:	000b2697          	auipc	a3,0xb2
ffffffffc0204dda:	dc268693          	addi	a3,a3,-574 # ffffffffc02b6b98 <npage>
    return page - pages + nbase;
ffffffffc0204dde:	40c58633          	sub	a2,a1,a2
ffffffffc0204de2:	630c                	ld	a1,0(a4)
ffffffffc0204de4:	8619                	srai	a2,a2,0x6
    return KADDR(page2pa(page));
ffffffffc0204de6:	577d                	li	a4,-1
ffffffffc0204de8:	6294                	ld	a3,0(a3)
    return page - pages + nbase;
ffffffffc0204dea:	962e                	add	a2,a2,a1
    return KADDR(page2pa(page));
ffffffffc0204dec:	8331                	srli	a4,a4,0xc
ffffffffc0204dee:	8f71                	and	a4,a4,a2
ffffffffc0204df0:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204df4:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204df6:	02d77a63          	bleu	a3,a4,ffffffffc0204e2a <swapfs_write+0x7e>
ffffffffc0204dfa:	000b2797          	auipc	a5,0xb2
ffffffffc0204dfe:	dfe78793          	addi	a5,a5,-514 # ffffffffc02b6bf8 <va_pa_offset>
ffffffffc0204e02:	639c                	ld	a5,0(a5)
}
ffffffffc0204e04:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204e06:	46a1                	li	a3,8
ffffffffc0204e08:	963e                	add	a2,a2,a5
ffffffffc0204e0a:	4505                	li	a0,1
}
ffffffffc0204e0c:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204e0e:	821fb06f          	j	ffffffffc020062e <ide_write_secs>
ffffffffc0204e12:	86aa                	mv	a3,a0
ffffffffc0204e14:	00003617          	auipc	a2,0x3
ffffffffc0204e18:	77c60613          	addi	a2,a2,1916 # ffffffffc0208590 <default_pmm_manager+0x10f8>
ffffffffc0204e1c:	45e5                	li	a1,25
ffffffffc0204e1e:	00003517          	auipc	a0,0x3
ffffffffc0204e22:	75a50513          	addi	a0,a0,1882 # ffffffffc0208578 <default_pmm_manager+0x10e0>
ffffffffc0204e26:	e5efb0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0204e2a:	86b2                	mv	a3,a2
ffffffffc0204e2c:	06900593          	li	a1,105
ffffffffc0204e30:	00002617          	auipc	a2,0x2
ffffffffc0204e34:	6b860613          	addi	a2,a2,1720 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc0204e38:	00002517          	auipc	a0,0x2
ffffffffc0204e3c:	6d850513          	addi	a0,a0,1752 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0204e40:	e44fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204e44 <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204e44:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204e46:	9402                	jalr	s0

	jal do_exit
ffffffffc0204e48:	6c2000ef          	jal	ra,ffffffffc020550a <do_exit>

ffffffffc0204e4c <alloc_proc>:
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
ffffffffc0204e4c:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204e4e:	10800513          	li	a0,264
alloc_proc(void) {
ffffffffc0204e52:	e022                	sd	s0,0(sp)
ffffffffc0204e54:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204e56:	e01fc0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc0204e5a:	842a                	mv	s0,a0
    if (proc != NULL) {
ffffffffc0204e5c:	cd29                	beqz	a0,ffffffffc0204eb6 <alloc_proc+0x6a>
     * below fields(add in LAB5) in proc_struct need to be initialized  
     *       uint32_t wait_state;                        // waiting state
     *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
     */
    //lab4内容
        proc->state = PROC_UNINIT;//进程有四个状态，分别是PROC_UNINIT, PROC_SLEEPING, PROC_RUNNABLE, PROC_ZOMBIE
ffffffffc0204e5e:	57fd                	li	a5,-1
ffffffffc0204e60:	1782                	slli	a5,a5,0x20
ffffffffc0204e62:	e11c                	sd	a5,0(a0)
        proc->runs = 0;//运行次数
        proc->kstack = 0;//内核栈 进程运行时使用的栈
        proc->need_resched = 0;//是否需要调度 1表示需要调度出去 0表示继续运行不调度
        proc->parent = NULL;//表示进程的父进程
        proc->mm = NULL;//用于内存管理的信息 lab3涉及。描述进程用户态的空间。
        memset(&(proc->context),0,sizeof(struct context));//进程上下文
ffffffffc0204e64:	07000613          	li	a2,112
ffffffffc0204e68:	4581                	li	a1,0
        proc->runs = 0;//运行次数
ffffffffc0204e6a:	00052423          	sw	zero,8(a0)
        proc->kstack = 0;//内核栈 进程运行时使用的栈
ffffffffc0204e6e:	00053823          	sd	zero,16(a0)
        proc->need_resched = 0;//是否需要调度 1表示需要调度出去 0表示继续运行不调度
ffffffffc0204e72:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;//表示进程的父进程
ffffffffc0204e76:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;//用于内存管理的信息 lab3涉及。描述进程用户态的空间。
ffffffffc0204e7a:	02053423          	sd	zero,40(a0)
        memset(&(proc->context),0,sizeof(struct context));//进程上下文
ffffffffc0204e7e:	03050513          	addi	a0,a0,48
ffffffffc0204e82:	0b3010ef          	jal	ra,ffffffffc0206734 <memset>
        proc->tf = NULL;//中断帧 当进程从内核态切换到用户态时，需要保存当前的中断帧，当进程从用户态切换到内核态时，需要恢复之前保存的中断帧。
        proc->cr3 = boot_cr3;//存页表，进程需要分配页表，这个页表的基址就是cr3寄存器的值。
ffffffffc0204e86:	000b2797          	auipc	a5,0xb2
ffffffffc0204e8a:	d7a78793          	addi	a5,a5,-646 # ffffffffc02b6c00 <boot_cr3>
ffffffffc0204e8e:	639c                	ld	a5,0(a5)
        proc->tf = NULL;//中断帧 当进程从内核态切换到用户态时，需要保存当前的中断帧，当进程从用户态切换到内核态时，需要恢复之前保存的中断帧。
ffffffffc0204e90:	0a043023          	sd	zero,160(s0)
        proc->flags = 0;//进程标志位
ffffffffc0204e94:	0a042823          	sw	zero,176(s0)
        proc->cr3 = boot_cr3;//存页表，进程需要分配页表，这个页表的基址就是cr3寄存器的值。
ffffffffc0204e98:	f45c                	sd	a5,168(s0)
        memset(proc->name,0,PROC_NAME_LEN);//置0
ffffffffc0204e9a:	463d                	li	a2,15
ffffffffc0204e9c:	4581                	li	a1,0
ffffffffc0204e9e:	0b440513          	addi	a0,s0,180
ffffffffc0204ea2:	093010ef          	jal	ra,ffffffffc0206734 <memset>
    //lab5
        proc->wait_state =0; //不为等待状态
ffffffffc0204ea6:	0e042623          	sw	zero,236(s0)
        proc->cptr = proc->optr = proc->yptr = NULL;//子进程，兄弟进程
ffffffffc0204eaa:	0e043c23          	sd	zero,248(s0)
ffffffffc0204eae:	10043023          	sd	zero,256(s0)
ffffffffc0204eb2:	0e043823          	sd	zero,240(s0)
    }
    return proc;
}
ffffffffc0204eb6:	8522                	mv	a0,s0
ffffffffc0204eb8:	60a2                	ld	ra,8(sp)
ffffffffc0204eba:	6402                	ld	s0,0(sp)
ffffffffc0204ebc:	0141                	addi	sp,sp,16
ffffffffc0204ebe:	8082                	ret

ffffffffc0204ec0 <forkret>:
// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
ffffffffc0204ec0:	000b2797          	auipc	a5,0xb2
ffffffffc0204ec4:	cf078793          	addi	a5,a5,-784 # ffffffffc02b6bb0 <current>
ffffffffc0204ec8:	639c                	ld	a5,0(a5)
ffffffffc0204eca:	73c8                	ld	a0,160(a5)
ffffffffc0204ecc:	edffb06f          	j	ffffffffc0200daa <forkrets>

ffffffffc0204ed0 <user_main>:

// user_main - kernel thread used to exec a user program
static int
user_main(void *arg) {
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204ed0:	000b2797          	auipc	a5,0xb2
ffffffffc0204ed4:	ce078793          	addi	a5,a5,-800 # ffffffffc02b6bb0 <current>
ffffffffc0204ed8:	639c                	ld	a5,0(a5)
user_main(void *arg) {
ffffffffc0204eda:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204edc:	00004617          	auipc	a2,0x4
ffffffffc0204ee0:	aa460613          	addi	a2,a2,-1372 # ffffffffc0208980 <default_pmm_manager+0x14e8>
ffffffffc0204ee4:	43cc                	lw	a1,4(a5)
ffffffffc0204ee6:	00004517          	auipc	a0,0x4
ffffffffc0204eea:	aaa50513          	addi	a0,a0,-1366 # ffffffffc0208990 <default_pmm_manager+0x14f8>
user_main(void *arg) {
ffffffffc0204eee:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204ef0:	a9efb0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc0204ef4:	00004797          	auipc	a5,0x4
ffffffffc0204ef8:	a8c78793          	addi	a5,a5,-1396 # ffffffffc0208980 <default_pmm_manager+0x14e8>
ffffffffc0204efc:	3fe05717          	auipc	a4,0x3fe05
ffffffffc0204f00:	75c70713          	addi	a4,a4,1884 # a658 <_binary_obj___user_cpw_test_out_size>
ffffffffc0204f04:	e43a                	sd	a4,8(sp)
    int64_t ret=0, len = strlen(name);
ffffffffc0204f06:	853e                	mv	a0,a5
ffffffffc0204f08:	0001b717          	auipc	a4,0x1b
ffffffffc0204f0c:	36070713          	addi	a4,a4,864 # ffffffffc0220268 <_binary_obj___user_cpw_test_out_start>
ffffffffc0204f10:	f03a                	sd	a4,32(sp)
ffffffffc0204f12:	f43e                	sd	a5,40(sp)
ffffffffc0204f14:	e802                	sd	zero,16(sp)
ffffffffc0204f16:	780010ef          	jal	ra,ffffffffc0206696 <strlen>
ffffffffc0204f1a:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204f1c:	4511                	li	a0,4
ffffffffc0204f1e:	55a2                	lw	a1,40(sp)
ffffffffc0204f20:	4662                	lw	a2,24(sp)
ffffffffc0204f22:	5682                	lw	a3,32(sp)
ffffffffc0204f24:	4722                	lw	a4,8(sp)
ffffffffc0204f26:	48a9                	li	a7,10
ffffffffc0204f28:	9002                	ebreak
ffffffffc0204f2a:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204f2c:	65c2                	ld	a1,16(sp)
ffffffffc0204f2e:	00004517          	auipc	a0,0x4
ffffffffc0204f32:	a8a50513          	addi	a0,a0,-1398 # ffffffffc02089b8 <default_pmm_manager+0x1520>
ffffffffc0204f36:	a58fb0ef          	jal	ra,ffffffffc020018e <cprintf>
#else
    KERNEL_EXECVE(waitkill);
#endif
    panic("user_main execve failed.\n");
ffffffffc0204f3a:	00004617          	auipc	a2,0x4
ffffffffc0204f3e:	a8e60613          	addi	a2,a2,-1394 # ffffffffc02089c8 <default_pmm_manager+0x1530>
ffffffffc0204f42:	39a00593          	li	a1,922
ffffffffc0204f46:	00004517          	auipc	a0,0x4
ffffffffc0204f4a:	aa250513          	addi	a0,a0,-1374 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc0204f4e:	d36fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204f52 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0204f52:	6d14                	ld	a3,24(a0)
put_pgdir(struct mm_struct *mm) {
ffffffffc0204f54:	1141                	addi	sp,sp,-16
ffffffffc0204f56:	e406                	sd	ra,8(sp)
ffffffffc0204f58:	c02007b7          	lui	a5,0xc0200
ffffffffc0204f5c:	04f6e263          	bltu	a3,a5,ffffffffc0204fa0 <put_pgdir+0x4e>
ffffffffc0204f60:	000b2797          	auipc	a5,0xb2
ffffffffc0204f64:	c9878793          	addi	a5,a5,-872 # ffffffffc02b6bf8 <va_pa_offset>
ffffffffc0204f68:	6388                	ld	a0,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0204f6a:	000b2797          	auipc	a5,0xb2
ffffffffc0204f6e:	c2e78793          	addi	a5,a5,-978 # ffffffffc02b6b98 <npage>
ffffffffc0204f72:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc0204f74:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage) {
ffffffffc0204f76:	82b1                	srli	a3,a3,0xc
ffffffffc0204f78:	04f6f063          	bleu	a5,a3,ffffffffc0204fb8 <put_pgdir+0x66>
    return &pages[PPN(pa) - nbase];
ffffffffc0204f7c:	00004797          	auipc	a5,0x4
ffffffffc0204f80:	f3478793          	addi	a5,a5,-204 # ffffffffc0208eb0 <nbase>
ffffffffc0204f84:	639c                	ld	a5,0(a5)
ffffffffc0204f86:	000b2717          	auipc	a4,0xb2
ffffffffc0204f8a:	c8270713          	addi	a4,a4,-894 # ffffffffc02b6c08 <pages>
ffffffffc0204f8e:	6308                	ld	a0,0(a4)
}
ffffffffc0204f90:	60a2                	ld	ra,8(sp)
ffffffffc0204f92:	8e9d                	sub	a3,a3,a5
ffffffffc0204f94:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0204f96:	4585                	li	a1,1
ffffffffc0204f98:	9536                	add	a0,a0,a3
}
ffffffffc0204f9a:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0204f9c:	f3ffc06f          	j	ffffffffc0201eda <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0204fa0:	00002617          	auipc	a2,0x2
ffffffffc0204fa4:	58060613          	addi	a2,a2,1408 # ffffffffc0207520 <default_pmm_manager+0x88>
ffffffffc0204fa8:	06e00593          	li	a1,110
ffffffffc0204fac:	00002517          	auipc	a0,0x2
ffffffffc0204fb0:	56450513          	addi	a0,a0,1380 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0204fb4:	cd0fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204fb8:	00002617          	auipc	a2,0x2
ffffffffc0204fbc:	59060613          	addi	a2,a2,1424 # ffffffffc0207548 <default_pmm_manager+0xb0>
ffffffffc0204fc0:	06200593          	li	a1,98
ffffffffc0204fc4:	00002517          	auipc	a0,0x2
ffffffffc0204fc8:	54c50513          	addi	a0,a0,1356 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0204fcc:	cb8fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204fd0 <setup_pgdir>:
setup_pgdir(struct mm_struct *mm) {
ffffffffc0204fd0:	1101                	addi	sp,sp,-32
ffffffffc0204fd2:	e426                	sd	s1,8(sp)
ffffffffc0204fd4:	84aa                	mv	s1,a0
    if ((page = alloc_page()) == NULL) {
ffffffffc0204fd6:	4505                	li	a0,1
setup_pgdir(struct mm_struct *mm) {
ffffffffc0204fd8:	ec06                	sd	ra,24(sp)
ffffffffc0204fda:	e822                	sd	s0,16(sp)
    if ((page = alloc_page()) == NULL) {
ffffffffc0204fdc:	e77fc0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0204fe0:	c125                	beqz	a0,ffffffffc0205040 <setup_pgdir+0x70>
    return page - pages + nbase;
ffffffffc0204fe2:	000b2797          	auipc	a5,0xb2
ffffffffc0204fe6:	c2678793          	addi	a5,a5,-986 # ffffffffc02b6c08 <pages>
ffffffffc0204fea:	6394                	ld	a3,0(a5)
ffffffffc0204fec:	00004797          	auipc	a5,0x4
ffffffffc0204ff0:	ec478793          	addi	a5,a5,-316 # ffffffffc0208eb0 <nbase>
ffffffffc0204ff4:	6380                	ld	s0,0(a5)
ffffffffc0204ff6:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0204ffa:	000b2717          	auipc	a4,0xb2
ffffffffc0204ffe:	b9e70713          	addi	a4,a4,-1122 # ffffffffc02b6b98 <npage>
    return page - pages + nbase;
ffffffffc0205002:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205004:	57fd                	li	a5,-1
ffffffffc0205006:	6318                	ld	a4,0(a4)
    return page - pages + nbase;
ffffffffc0205008:	96a2                	add	a3,a3,s0
    return KADDR(page2pa(page));
ffffffffc020500a:	83b1                	srli	a5,a5,0xc
ffffffffc020500c:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc020500e:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205010:	02e7fa63          	bleu	a4,a5,ffffffffc0205044 <setup_pgdir+0x74>
ffffffffc0205014:	000b2797          	auipc	a5,0xb2
ffffffffc0205018:	be478793          	addi	a5,a5,-1052 # ffffffffc02b6bf8 <va_pa_offset>
ffffffffc020501c:	6380                	ld	s0,0(a5)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc020501e:	000b2797          	auipc	a5,0xb2
ffffffffc0205022:	b7278793          	addi	a5,a5,-1166 # ffffffffc02b6b90 <boot_pgdir>
ffffffffc0205026:	638c                	ld	a1,0(a5)
ffffffffc0205028:	9436                	add	s0,s0,a3
ffffffffc020502a:	6605                	lui	a2,0x1
ffffffffc020502c:	8522                	mv	a0,s0
ffffffffc020502e:	718010ef          	jal	ra,ffffffffc0206746 <memcpy>
    return 0;
ffffffffc0205032:	4501                	li	a0,0
    mm->pgdir = pgdir;
ffffffffc0205034:	ec80                	sd	s0,24(s1)
}
ffffffffc0205036:	60e2                	ld	ra,24(sp)
ffffffffc0205038:	6442                	ld	s0,16(sp)
ffffffffc020503a:	64a2                	ld	s1,8(sp)
ffffffffc020503c:	6105                	addi	sp,sp,32
ffffffffc020503e:	8082                	ret
        return -E_NO_MEM;
ffffffffc0205040:	5571                	li	a0,-4
ffffffffc0205042:	bfd5                	j	ffffffffc0205036 <setup_pgdir+0x66>
ffffffffc0205044:	00002617          	auipc	a2,0x2
ffffffffc0205048:	4a460613          	addi	a2,a2,1188 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc020504c:	06900593          	li	a1,105
ffffffffc0205050:	00002517          	auipc	a0,0x2
ffffffffc0205054:	4c050513          	addi	a0,a0,1216 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0205058:	c2cfb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020505c <set_proc_name>:
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc020505c:	1101                	addi	sp,sp,-32
ffffffffc020505e:	e822                	sd	s0,16(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205060:	0b450413          	addi	s0,a0,180
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc0205064:	e426                	sd	s1,8(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205066:	4641                	li	a2,16
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc0205068:	84ae                	mv	s1,a1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc020506a:	8522                	mv	a0,s0
ffffffffc020506c:	4581                	li	a1,0
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc020506e:	ec06                	sd	ra,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205070:	6c4010ef          	jal	ra,ffffffffc0206734 <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205074:	8522                	mv	a0,s0
}
ffffffffc0205076:	6442                	ld	s0,16(sp)
ffffffffc0205078:	60e2                	ld	ra,24(sp)
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020507a:	85a6                	mv	a1,s1
}
ffffffffc020507c:	64a2                	ld	s1,8(sp)
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020507e:	463d                	li	a2,15
}
ffffffffc0205080:	6105                	addi	sp,sp,32
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0205082:	6c40106f          	j	ffffffffc0206746 <memcpy>

ffffffffc0205086 <proc_run>:
proc_run(struct proc_struct *proc) {
ffffffffc0205086:	1101                	addi	sp,sp,-32
ffffffffc0205088:	e426                	sd	s1,8(sp)
    if (proc != current) {
ffffffffc020508a:	000b2497          	auipc	s1,0xb2
ffffffffc020508e:	b2648493          	addi	s1,s1,-1242 # ffffffffc02b6bb0 <current>
ffffffffc0205092:	6098                	ld	a4,0(s1)
proc_run(struct proc_struct *proc) {
ffffffffc0205094:	ec06                	sd	ra,24(sp)
ffffffffc0205096:	e822                	sd	s0,16(sp)
ffffffffc0205098:	e04a                	sd	s2,0(sp)
    if (proc != current) {
ffffffffc020509a:	02a70b63          	beq	a4,a0,ffffffffc02050d0 <proc_run+0x4a>
ffffffffc020509e:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02050a0:	100027f3          	csrr	a5,sstatus
ffffffffc02050a4:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02050a6:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02050a8:	e3a9                	bnez	a5,ffffffffc02050ea <proc_run+0x64>

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned long cr3) {
    write_csr(satp, 0x8000000000000000 | (cr3 >> RISCV_PGSHIFT));
ffffffffc02050aa:	745c                	ld	a5,168(s0)
ffffffffc02050ac:	56fd                	li	a3,-1
ffffffffc02050ae:	16fe                	slli	a3,a3,0x3f
ffffffffc02050b0:	83b1                	srli	a5,a5,0xc
ffffffffc02050b2:	8fd5                	or	a5,a5,a3
ffffffffc02050b4:	18079073          	csrw	satp,a5
            switch_to(&(temp->context), &(proc->context));
ffffffffc02050b8:	03040593          	addi	a1,s0,48
ffffffffc02050bc:	03070513          	addi	a0,a4,48
            current = proc;
ffffffffc02050c0:	000b2797          	auipc	a5,0xb2
ffffffffc02050c4:	ae87b823          	sd	s0,-1296(a5) # ffffffffc02b6bb0 <current>
            switch_to(&(temp->context), &(proc->context));
ffffffffc02050c8:	763000ef          	jal	ra,ffffffffc020602a <switch_to>
    if (flag) {
ffffffffc02050cc:	00091863          	bnez	s2,ffffffffc02050dc <proc_run+0x56>
}
ffffffffc02050d0:	60e2                	ld	ra,24(sp)
ffffffffc02050d2:	6442                	ld	s0,16(sp)
ffffffffc02050d4:	64a2                	ld	s1,8(sp)
ffffffffc02050d6:	6902                	ld	s2,0(sp)
ffffffffc02050d8:	6105                	addi	sp,sp,32
ffffffffc02050da:	8082                	ret
ffffffffc02050dc:	6442                	ld	s0,16(sp)
ffffffffc02050de:	60e2                	ld	ra,24(sp)
ffffffffc02050e0:	64a2                	ld	s1,8(sp)
ffffffffc02050e2:	6902                	ld	s2,0(sp)
ffffffffc02050e4:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02050e6:	d6efb06f          	j	ffffffffc0200654 <intr_enable>
        intr_disable();
ffffffffc02050ea:	d70fb0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc02050ee:	6098                	ld	a4,0(s1)
ffffffffc02050f0:	4905                	li	s2,1
ffffffffc02050f2:	bf65                	j	ffffffffc02050aa <proc_run+0x24>

ffffffffc02050f4 <find_proc>:
    if (0 < pid && pid < MAX_PID) {
ffffffffc02050f4:	0005071b          	sext.w	a4,a0
ffffffffc02050f8:	6789                	lui	a5,0x2
ffffffffc02050fa:	fff7069b          	addiw	a3,a4,-1
ffffffffc02050fe:	17f9                	addi	a5,a5,-2
ffffffffc0205100:	04d7e063          	bltu	a5,a3,ffffffffc0205140 <find_proc+0x4c>
find_proc(int pid) {
ffffffffc0205104:	1141                	addi	sp,sp,-16
ffffffffc0205106:	e022                	sd	s0,0(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205108:	45a9                	li	a1,10
ffffffffc020510a:	842a                	mv	s0,a0
ffffffffc020510c:	853a                	mv	a0,a4
find_proc(int pid) {
ffffffffc020510e:	e406                	sd	ra,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0205110:	176010ef          	jal	ra,ffffffffc0206286 <hash32>
ffffffffc0205114:	02051693          	slli	a3,a0,0x20
ffffffffc0205118:	82f1                	srli	a3,a3,0x1c
ffffffffc020511a:	000ae517          	auipc	a0,0xae
ffffffffc020511e:	a5e50513          	addi	a0,a0,-1442 # ffffffffc02b2b78 <hash_list>
ffffffffc0205122:	96aa                	add	a3,a3,a0
ffffffffc0205124:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list) {
ffffffffc0205126:	a029                	j	ffffffffc0205130 <find_proc+0x3c>
            if (proc->pid == pid) {
ffffffffc0205128:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7654>
ffffffffc020512c:	00870c63          	beq	a4,s0,ffffffffc0205144 <find_proc+0x50>
ffffffffc0205130:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0205132:	fef69be3          	bne	a3,a5,ffffffffc0205128 <find_proc+0x34>
}
ffffffffc0205136:	60a2                	ld	ra,8(sp)
ffffffffc0205138:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc020513a:	4501                	li	a0,0
}
ffffffffc020513c:	0141                	addi	sp,sp,16
ffffffffc020513e:	8082                	ret
    return NULL;
ffffffffc0205140:	4501                	li	a0,0
}
ffffffffc0205142:	8082                	ret
ffffffffc0205144:	60a2                	ld	ra,8(sp)
ffffffffc0205146:	6402                	ld	s0,0(sp)
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205148:	f2878513          	addi	a0,a5,-216
}
ffffffffc020514c:	0141                	addi	sp,sp,16
ffffffffc020514e:	8082                	ret

ffffffffc0205150 <do_fork>:
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0205150:	7159                	addi	sp,sp,-112
ffffffffc0205152:	e0d2                	sd	s4,64(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0205154:	000b2a17          	auipc	s4,0xb2
ffffffffc0205158:	a74a0a13          	addi	s4,s4,-1420 # ffffffffc02b6bc8 <nr_process>
ffffffffc020515c:	000a2703          	lw	a4,0(s4)
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0205160:	f486                	sd	ra,104(sp)
ffffffffc0205162:	f0a2                	sd	s0,96(sp)
ffffffffc0205164:	eca6                	sd	s1,88(sp)
ffffffffc0205166:	e8ca                	sd	s2,80(sp)
ffffffffc0205168:	e4ce                	sd	s3,72(sp)
ffffffffc020516a:	fc56                	sd	s5,56(sp)
ffffffffc020516c:	f85a                	sd	s6,48(sp)
ffffffffc020516e:	f45e                	sd	s7,40(sp)
ffffffffc0205170:	f062                	sd	s8,32(sp)
ffffffffc0205172:	ec66                	sd	s9,24(sp)
ffffffffc0205174:	e86a                	sd	s10,16(sp)
ffffffffc0205176:	e46e                	sd	s11,8(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0205178:	6785                	lui	a5,0x1
ffffffffc020517a:	2cf75163          	ble	a5,a4,ffffffffc020543c <do_fork+0x2ec>
ffffffffc020517e:	89aa                	mv	s3,a0
ffffffffc0205180:	892e                	mv	s2,a1
ffffffffc0205182:	84b2                	mv	s1,a2
    if((proc = alloc_proc())==NULL){
ffffffffc0205184:	cc9ff0ef          	jal	ra,ffffffffc0204e4c <alloc_proc>
ffffffffc0205188:	842a                	mv	s0,a0
ffffffffc020518a:	28050763          	beqz	a0,ffffffffc0205418 <do_fork+0x2c8>
    if(current->wait_state == 0){
ffffffffc020518e:	000b2c17          	auipc	s8,0xb2
ffffffffc0205192:	a22c0c13          	addi	s8,s8,-1502 # ffffffffc02b6bb0 <current>
ffffffffc0205196:	000c3783          	ld	a5,0(s8)
ffffffffc020519a:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8494>
ffffffffc020519e:	1e070463          	beqz	a4,ffffffffc0205386 <do_fork+0x236>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc02051a2:	4509                	li	a0,2
ffffffffc02051a4:	caffc0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
    if (page != NULL) {
ffffffffc02051a8:	26050563          	beqz	a0,ffffffffc0205412 <do_fork+0x2c2>
    return page - pages + nbase;
ffffffffc02051ac:	000b2a97          	auipc	s5,0xb2
ffffffffc02051b0:	a5ca8a93          	addi	s5,s5,-1444 # ffffffffc02b6c08 <pages>
ffffffffc02051b4:	000ab683          	ld	a3,0(s5)
ffffffffc02051b8:	00004b17          	auipc	s6,0x4
ffffffffc02051bc:	cf8b0b13          	addi	s6,s6,-776 # ffffffffc0208eb0 <nbase>
ffffffffc02051c0:	000b3783          	ld	a5,0(s6)
ffffffffc02051c4:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc02051c8:	000b2b97          	auipc	s7,0xb2
ffffffffc02051cc:	9d0b8b93          	addi	s7,s7,-1584 # ffffffffc02b6b98 <npage>
    return page - pages + nbase;
ffffffffc02051d0:	8699                	srai	a3,a3,0x6
ffffffffc02051d2:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc02051d4:	000bb703          	ld	a4,0(s7)
ffffffffc02051d8:	57fd                	li	a5,-1
ffffffffc02051da:	83b1                	srli	a5,a5,0xc
ffffffffc02051dc:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02051de:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02051e0:	26e7f063          	bleu	a4,a5,ffffffffc0205440 <do_fork+0x2f0>
ffffffffc02051e4:	000b2c97          	auipc	s9,0xb2
ffffffffc02051e8:	a14c8c93          	addi	s9,s9,-1516 # ffffffffc02b6bf8 <va_pa_offset>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc02051ec:	000c3703          	ld	a4,0(s8)
ffffffffc02051f0:	000cb783          	ld	a5,0(s9)
ffffffffc02051f4:	02873c03          	ld	s8,40(a4)
ffffffffc02051f8:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc02051fa:	e814                	sd	a3,16(s0)
    if (oldmm == NULL) {
ffffffffc02051fc:	020c0863          	beqz	s8,ffffffffc020522c <do_fork+0xdc>
    if (clone_flags & CLONE_VM) {
ffffffffc0205200:	1009f993          	andi	s3,s3,256
ffffffffc0205204:	18098563          	beqz	s3,ffffffffc020538e <do_fork+0x23e>
}

static inline int
mm_count_inc(struct mm_struct *mm) {
    mm->mm_count += 1;
ffffffffc0205208:	030c2703          	lw	a4,48(s8)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc020520c:	018c3783          	ld	a5,24(s8)
ffffffffc0205210:	c02006b7          	lui	a3,0xc0200
ffffffffc0205214:	2705                	addiw	a4,a4,1
ffffffffc0205216:	02ec2823          	sw	a4,48(s8)
    proc->mm = mm;
ffffffffc020521a:	03843423          	sd	s8,40(s0)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc020521e:	22d7ed63          	bltu	a5,a3,ffffffffc0205458 <do_fork+0x308>
ffffffffc0205222:	000cb703          	ld	a4,0(s9)
ffffffffc0205226:	6814                	ld	a3,16(s0)
ffffffffc0205228:	8f99                	sub	a5,a5,a4
ffffffffc020522a:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020522c:	6789                	lui	a5,0x2
ffffffffc020522e:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x76a0>
ffffffffc0205232:	96be                	add	a3,a3,a5
ffffffffc0205234:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc0205236:	87b6                	mv	a5,a3
ffffffffc0205238:	12048813          	addi	a6,s1,288
ffffffffc020523c:	6088                	ld	a0,0(s1)
ffffffffc020523e:	648c                	ld	a1,8(s1)
ffffffffc0205240:	6890                	ld	a2,16(s1)
ffffffffc0205242:	6c98                	ld	a4,24(s1)
ffffffffc0205244:	e388                	sd	a0,0(a5)
ffffffffc0205246:	e78c                	sd	a1,8(a5)
ffffffffc0205248:	eb90                	sd	a2,16(a5)
ffffffffc020524a:	ef98                	sd	a4,24(a5)
ffffffffc020524c:	02048493          	addi	s1,s1,32
ffffffffc0205250:	02078793          	addi	a5,a5,32
ffffffffc0205254:	ff0494e3          	bne	s1,a6,ffffffffc020523c <do_fork+0xec>
    proc->tf->gpr.a0 = 0;
ffffffffc0205258:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x1a>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020525c:	12090763          	beqz	s2,ffffffffc020538a <do_fork+0x23a>
    if (++ last_pid >= MAX_PID) {
ffffffffc0205260:	000a6797          	auipc	a5,0xa6
ffffffffc0205264:	51078793          	addi	a5,a5,1296 # ffffffffc02ab770 <last_pid.1691>
ffffffffc0205268:	439c                	lw	a5,0(a5)
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020526a:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020526e:	00000717          	auipc	a4,0x0
ffffffffc0205272:	c5270713          	addi	a4,a4,-942 # ffffffffc0204ec0 <forkret>
    if (++ last_pid >= MAX_PID) {
ffffffffc0205276:	0017851b          	addiw	a0,a5,1
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020527a:	f818                	sd	a4,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020527c:	fc14                	sd	a3,56(s0)
    if (++ last_pid >= MAX_PID) {
ffffffffc020527e:	000a6717          	auipc	a4,0xa6
ffffffffc0205282:	4ea72923          	sw	a0,1266(a4) # ffffffffc02ab770 <last_pid.1691>
ffffffffc0205286:	6789                	lui	a5,0x2
ffffffffc0205288:	18f55a63          	ble	a5,a0,ffffffffc020541c <do_fork+0x2cc>
    if (last_pid >= next_safe) {
ffffffffc020528c:	000a6797          	auipc	a5,0xa6
ffffffffc0205290:	4e878793          	addi	a5,a5,1256 # ffffffffc02ab774 <next_safe.1690>
ffffffffc0205294:	439c                	lw	a5,0(a5)
ffffffffc0205296:	000b2497          	auipc	s1,0xb2
ffffffffc020529a:	a5a48493          	addi	s1,s1,-1446 # ffffffffc02b6cf0 <proc_list>
ffffffffc020529e:	06f54063          	blt	a0,a5,ffffffffc02052fe <do_fork+0x1ae>
        next_safe = MAX_PID;
ffffffffc02052a2:	6789                	lui	a5,0x2
ffffffffc02052a4:	000a6717          	auipc	a4,0xa6
ffffffffc02052a8:	4cf72823          	sw	a5,1232(a4) # ffffffffc02ab774 <next_safe.1690>
ffffffffc02052ac:	4581                	li	a1,0
ffffffffc02052ae:	87aa                	mv	a5,a0
ffffffffc02052b0:	000b2497          	auipc	s1,0xb2
ffffffffc02052b4:	a4048493          	addi	s1,s1,-1472 # ffffffffc02b6cf0 <proc_list>
    repeat:
ffffffffc02052b8:	6889                	lui	a7,0x2
ffffffffc02052ba:	882e                	mv	a6,a1
ffffffffc02052bc:	6609                	lui	a2,0x2
        le = list;
ffffffffc02052be:	000b2697          	auipc	a3,0xb2
ffffffffc02052c2:	a3268693          	addi	a3,a3,-1486 # ffffffffc02b6cf0 <proc_list>
ffffffffc02052c6:	6694                	ld	a3,8(a3)
        while ((le = list_next(le)) != list) {
ffffffffc02052c8:	00968f63          	beq	a3,s1,ffffffffc02052e6 <do_fork+0x196>
            if (proc->pid == last_pid) {
ffffffffc02052cc:	f3c6a703          	lw	a4,-196(a3)
ffffffffc02052d0:	0ae78663          	beq	a5,a4,ffffffffc020537c <do_fork+0x22c>
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc02052d4:	fee7d9e3          	ble	a4,a5,ffffffffc02052c6 <do_fork+0x176>
ffffffffc02052d8:	fec757e3          	ble	a2,a4,ffffffffc02052c6 <do_fork+0x176>
ffffffffc02052dc:	6694                	ld	a3,8(a3)
ffffffffc02052de:	863a                	mv	a2,a4
ffffffffc02052e0:	4805                	li	a6,1
        while ((le = list_next(le)) != list) {
ffffffffc02052e2:	fe9695e3          	bne	a3,s1,ffffffffc02052cc <do_fork+0x17c>
ffffffffc02052e6:	c591                	beqz	a1,ffffffffc02052f2 <do_fork+0x1a2>
ffffffffc02052e8:	000a6717          	auipc	a4,0xa6
ffffffffc02052ec:	48f72423          	sw	a5,1160(a4) # ffffffffc02ab770 <last_pid.1691>
ffffffffc02052f0:	853e                	mv	a0,a5
ffffffffc02052f2:	00080663          	beqz	a6,ffffffffc02052fe <do_fork+0x1ae>
ffffffffc02052f6:	000a6797          	auipc	a5,0xa6
ffffffffc02052fa:	46c7af23          	sw	a2,1150(a5) # ffffffffc02ab774 <next_safe.1690>
    proc->pid = get_pid();
ffffffffc02052fe:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0205300:	45a9                	li	a1,10
ffffffffc0205302:	2501                	sext.w	a0,a0
ffffffffc0205304:	783000ef          	jal	ra,ffffffffc0206286 <hash32>
ffffffffc0205308:	1502                	slli	a0,a0,0x20
ffffffffc020530a:	000ae797          	auipc	a5,0xae
ffffffffc020530e:	86e78793          	addi	a5,a5,-1938 # ffffffffc02b2b78 <hash_list>
ffffffffc0205312:	8171                	srli	a0,a0,0x1c
ffffffffc0205314:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0205316:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc0205318:	7014                	ld	a3,32(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020531a:	0d840793          	addi	a5,s0,216
    prev->next = next->prev = elm;
ffffffffc020531e:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0205320:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc0205322:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc0205324:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0205326:	0c840793          	addi	a5,s0,200
    elm->next = next;
ffffffffc020532a:	f06c                	sd	a1,224(s0)
    elm->prev = prev;
ffffffffc020532c:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc020532e:	e21c                	sd	a5,0(a2)
ffffffffc0205330:	000b2597          	auipc	a1,0xb2
ffffffffc0205334:	9cf5b423          	sd	a5,-1592(a1) # ffffffffc02b6cf8 <proc_list+0x8>
    elm->next = next;
ffffffffc0205338:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc020533a:	e464                	sd	s1,200(s0)
    proc->yptr = NULL;
ffffffffc020533c:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc0205340:	10e43023          	sd	a4,256(s0)
ffffffffc0205344:	c311                	beqz	a4,ffffffffc0205348 <do_fork+0x1f8>
        proc->optr->yptr = proc;
ffffffffc0205346:	ff60                	sd	s0,248(a4)
    nr_process ++;
ffffffffc0205348:	000a2783          	lw	a5,0(s4)
    ret = proc->pid;
ffffffffc020534c:	4048                	lw	a0,4(s0)
    proc->parent->cptr = proc;
ffffffffc020534e:	fae0                	sd	s0,240(a3)
    nr_process ++;
ffffffffc0205350:	2785                	addiw	a5,a5,1
ffffffffc0205352:	000b2717          	auipc	a4,0xb2
ffffffffc0205356:	86f72b23          	sw	a5,-1930(a4) # ffffffffc02b6bc8 <nr_process>
    proc->state = PROC_RUNNABLE;
ffffffffc020535a:	4789                	li	a5,2
ffffffffc020535c:	c01c                	sw	a5,0(s0)
}
ffffffffc020535e:	70a6                	ld	ra,104(sp)
ffffffffc0205360:	7406                	ld	s0,96(sp)
ffffffffc0205362:	64e6                	ld	s1,88(sp)
ffffffffc0205364:	6946                	ld	s2,80(sp)
ffffffffc0205366:	69a6                	ld	s3,72(sp)
ffffffffc0205368:	6a06                	ld	s4,64(sp)
ffffffffc020536a:	7ae2                	ld	s5,56(sp)
ffffffffc020536c:	7b42                	ld	s6,48(sp)
ffffffffc020536e:	7ba2                	ld	s7,40(sp)
ffffffffc0205370:	7c02                	ld	s8,32(sp)
ffffffffc0205372:	6ce2                	ld	s9,24(sp)
ffffffffc0205374:	6d42                	ld	s10,16(sp)
ffffffffc0205376:	6da2                	ld	s11,8(sp)
ffffffffc0205378:	6165                	addi	sp,sp,112
ffffffffc020537a:	8082                	ret
                if (++ last_pid >= next_safe) {
ffffffffc020537c:	2785                	addiw	a5,a5,1
ffffffffc020537e:	0ac7d663          	ble	a2,a5,ffffffffc020542a <do_fork+0x2da>
ffffffffc0205382:	4585                	li	a1,1
ffffffffc0205384:	b789                	j	ffffffffc02052c6 <do_fork+0x176>
        proc->parent = current;
ffffffffc0205386:	f11c                	sd	a5,32(a0)
ffffffffc0205388:	bd29                	j	ffffffffc02051a2 <do_fork+0x52>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc020538a:	8936                	mv	s2,a3
ffffffffc020538c:	bdd1                	j	ffffffffc0205260 <do_fork+0x110>
    if ((mm = mm_create()) == NULL) {
ffffffffc020538e:	d9dfe0ef          	jal	ra,ffffffffc020412a <mm_create>
ffffffffc0205392:	8d2a                	mv	s10,a0
ffffffffc0205394:	c539                	beqz	a0,ffffffffc02053e2 <do_fork+0x292>
    if (setup_pgdir(mm) != 0) {
ffffffffc0205396:	c3bff0ef          	jal	ra,ffffffffc0204fd0 <setup_pgdir>
ffffffffc020539a:	ed49                	bnez	a0,ffffffffc0205434 <do_fork+0x2e4>
}

static inline void
lock_mm(struct mm_struct *mm) {
    if (mm != NULL) {
        lock(&(mm->mm_lock));
ffffffffc020539c:	038c0d93          	addi	s11,s8,56
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02053a0:	4785                	li	a5,1
ffffffffc02053a2:	40fdb7af          	amoor.d	a5,a5,(s11)
ffffffffc02053a6:	8b85                	andi	a5,a5,1
ffffffffc02053a8:	4985                	li	s3,1
    return !test_and_set_bit(0, lock);
}

static inline void
lock(lock_t *lock) {
    while (!try_lock(lock)) {
ffffffffc02053aa:	c799                	beqz	a5,ffffffffc02053b8 <do_fork+0x268>
        schedule();
ffffffffc02053ac:	565000ef          	jal	ra,ffffffffc0206110 <schedule>
ffffffffc02053b0:	413db7af          	amoor.d	a5,s3,(s11)
ffffffffc02053b4:	8b85                	andi	a5,a5,1
    while (!try_lock(lock)) {
ffffffffc02053b6:	fbfd                	bnez	a5,ffffffffc02053ac <do_fork+0x25c>
        ret = dup_mmap(mm, oldmm);
ffffffffc02053b8:	85e2                	mv	a1,s8
ffffffffc02053ba:	856a                	mv	a0,s10
ffffffffc02053bc:	ff9fe0ef          	jal	ra,ffffffffc02043b4 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02053c0:	57f9                	li	a5,-2
ffffffffc02053c2:	60fdb7af          	amoand.d	a5,a5,(s11)
ffffffffc02053c6:	8b85                	andi	a5,a5,1
    }
}

static inline void
unlock(lock_t *lock) {
    if (!test_and_clear_bit(0, lock)) {
ffffffffc02053c8:	c7cd                	beqz	a5,ffffffffc0205472 <do_fork+0x322>
    if (ret != 0) {
ffffffffc02053ca:	8c6a                	mv	s8,s10
ffffffffc02053cc:	e2050ee3          	beqz	a0,ffffffffc0205208 <do_fork+0xb8>
    exit_mmap(mm);
ffffffffc02053d0:	856a                	mv	a0,s10
ffffffffc02053d2:	87eff0ef          	jal	ra,ffffffffc0204450 <exit_mmap>
    put_pgdir(mm);
ffffffffc02053d6:	856a                	mv	a0,s10
ffffffffc02053d8:	b7bff0ef          	jal	ra,ffffffffc0204f52 <put_pgdir>
    mm_destroy(mm);
ffffffffc02053dc:	856a                	mv	a0,s10
ffffffffc02053de:	ed3fe0ef          	jal	ra,ffffffffc02042b0 <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02053e2:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02053e4:	c02007b7          	lui	a5,0xc0200
ffffffffc02053e8:	0af6ed63          	bltu	a3,a5,ffffffffc02054a2 <do_fork+0x352>
ffffffffc02053ec:	000cb783          	ld	a5,0(s9)
    if (PPN(pa) >= npage) {
ffffffffc02053f0:	000bb703          	ld	a4,0(s7)
    return pa2page(PADDR(kva));
ffffffffc02053f4:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc02053f8:	83b1                	srli	a5,a5,0xc
ffffffffc02053fa:	08e7f863          	bleu	a4,a5,ffffffffc020548a <do_fork+0x33a>
    return &pages[PPN(pa) - nbase];
ffffffffc02053fe:	000b3703          	ld	a4,0(s6)
ffffffffc0205402:	000ab503          	ld	a0,0(s5)
ffffffffc0205406:	4589                	li	a1,2
ffffffffc0205408:	8f99                	sub	a5,a5,a4
ffffffffc020540a:	079a                	slli	a5,a5,0x6
ffffffffc020540c:	953e                	add	a0,a0,a5
ffffffffc020540e:	acdfc0ef          	jal	ra,ffffffffc0201eda <free_pages>
    kfree(proc);
ffffffffc0205412:	8522                	mv	a0,s0
ffffffffc0205414:	8fffc0ef          	jal	ra,ffffffffc0201d12 <kfree>
    ret = -E_NO_MEM;
ffffffffc0205418:	5571                	li	a0,-4
    return ret;
ffffffffc020541a:	b791                	j	ffffffffc020535e <do_fork+0x20e>
        last_pid = 1;
ffffffffc020541c:	4785                	li	a5,1
ffffffffc020541e:	000a6717          	auipc	a4,0xa6
ffffffffc0205422:	34f72923          	sw	a5,850(a4) # ffffffffc02ab770 <last_pid.1691>
ffffffffc0205426:	4505                	li	a0,1
ffffffffc0205428:	bdad                	j	ffffffffc02052a2 <do_fork+0x152>
                    if (last_pid >= MAX_PID) {
ffffffffc020542a:	0117c363          	blt	a5,a7,ffffffffc0205430 <do_fork+0x2e0>
                        last_pid = 1;
ffffffffc020542e:	4785                	li	a5,1
                    goto repeat;
ffffffffc0205430:	4585                	li	a1,1
ffffffffc0205432:	b561                	j	ffffffffc02052ba <do_fork+0x16a>
    mm_destroy(mm);
ffffffffc0205434:	856a                	mv	a0,s10
ffffffffc0205436:	e7bfe0ef          	jal	ra,ffffffffc02042b0 <mm_destroy>
ffffffffc020543a:	b765                	j	ffffffffc02053e2 <do_fork+0x292>
    int ret = -E_NO_FREE_PROC;
ffffffffc020543c:	556d                	li	a0,-5
ffffffffc020543e:	b705                	j	ffffffffc020535e <do_fork+0x20e>
    return KADDR(page2pa(page));
ffffffffc0205440:	00002617          	auipc	a2,0x2
ffffffffc0205444:	0a860613          	addi	a2,a2,168 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc0205448:	06900593          	li	a1,105
ffffffffc020544c:	00002517          	auipc	a0,0x2
ffffffffc0205450:	0c450513          	addi	a0,a0,196 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0205454:	830fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0205458:	86be                	mv	a3,a5
ffffffffc020545a:	00002617          	auipc	a2,0x2
ffffffffc020545e:	0c660613          	addi	a2,a2,198 # ffffffffc0207520 <default_pmm_manager+0x88>
ffffffffc0205462:	17800593          	li	a1,376
ffffffffc0205466:	00003517          	auipc	a0,0x3
ffffffffc020546a:	58250513          	addi	a0,a0,1410 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc020546e:	816fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("Unlock failed.\n");
ffffffffc0205472:	00003617          	auipc	a2,0x3
ffffffffc0205476:	30660613          	addi	a2,a2,774 # ffffffffc0208778 <default_pmm_manager+0x12e0>
ffffffffc020547a:	03100593          	li	a1,49
ffffffffc020547e:	00003517          	auipc	a0,0x3
ffffffffc0205482:	30a50513          	addi	a0,a0,778 # ffffffffc0208788 <default_pmm_manager+0x12f0>
ffffffffc0205486:	ffffa0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020548a:	00002617          	auipc	a2,0x2
ffffffffc020548e:	0be60613          	addi	a2,a2,190 # ffffffffc0207548 <default_pmm_manager+0xb0>
ffffffffc0205492:	06200593          	li	a1,98
ffffffffc0205496:	00002517          	auipc	a0,0x2
ffffffffc020549a:	07a50513          	addi	a0,a0,122 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc020549e:	fe7fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02054a2:	00002617          	auipc	a2,0x2
ffffffffc02054a6:	07e60613          	addi	a2,a2,126 # ffffffffc0207520 <default_pmm_manager+0x88>
ffffffffc02054aa:	06e00593          	li	a1,110
ffffffffc02054ae:	00002517          	auipc	a0,0x2
ffffffffc02054b2:	06250513          	addi	a0,a0,98 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc02054b6:	fcffa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02054ba <kernel_thread>:
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02054ba:	7129                	addi	sp,sp,-320
ffffffffc02054bc:	fa22                	sd	s0,304(sp)
ffffffffc02054be:	f626                	sd	s1,296(sp)
ffffffffc02054c0:	f24a                	sd	s2,288(sp)
ffffffffc02054c2:	84ae                	mv	s1,a1
ffffffffc02054c4:	892a                	mv	s2,a0
ffffffffc02054c6:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02054c8:	4581                	li	a1,0
ffffffffc02054ca:	12000613          	li	a2,288
ffffffffc02054ce:	850a                	mv	a0,sp
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc02054d0:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc02054d2:	262010ef          	jal	ra,ffffffffc0206734 <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc02054d6:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc02054d8:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc02054da:	100027f3          	csrr	a5,sstatus
ffffffffc02054de:	edd7f793          	andi	a5,a5,-291
ffffffffc02054e2:	1207e793          	ori	a5,a5,288
ffffffffc02054e6:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02054e8:	860a                	mv	a2,sp
ffffffffc02054ea:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02054ee:	00000797          	auipc	a5,0x0
ffffffffc02054f2:	95678793          	addi	a5,a5,-1706 # ffffffffc0204e44 <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02054f6:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02054f8:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02054fa:	c57ff0ef          	jal	ra,ffffffffc0205150 <do_fork>
}
ffffffffc02054fe:	70f2                	ld	ra,312(sp)
ffffffffc0205500:	7452                	ld	s0,304(sp)
ffffffffc0205502:	74b2                	ld	s1,296(sp)
ffffffffc0205504:	7912                	ld	s2,288(sp)
ffffffffc0205506:	6131                	addi	sp,sp,320
ffffffffc0205508:	8082                	ret

ffffffffc020550a <do_exit>:
do_exit(int error_code) {
ffffffffc020550a:	7179                	addi	sp,sp,-48
ffffffffc020550c:	e84a                	sd	s2,16(sp)
    if (current == idleproc) {
ffffffffc020550e:	000b1717          	auipc	a4,0xb1
ffffffffc0205512:	6aa70713          	addi	a4,a4,1706 # ffffffffc02b6bb8 <idleproc>
ffffffffc0205516:	000b1917          	auipc	s2,0xb1
ffffffffc020551a:	69a90913          	addi	s2,s2,1690 # ffffffffc02b6bb0 <current>
ffffffffc020551e:	00093783          	ld	a5,0(s2)
ffffffffc0205522:	6318                	ld	a4,0(a4)
do_exit(int error_code) {
ffffffffc0205524:	f406                	sd	ra,40(sp)
ffffffffc0205526:	f022                	sd	s0,32(sp)
ffffffffc0205528:	ec26                	sd	s1,24(sp)
ffffffffc020552a:	e44e                	sd	s3,8(sp)
ffffffffc020552c:	e052                	sd	s4,0(sp)
    if (current == idleproc) {
ffffffffc020552e:	0ce78c63          	beq	a5,a4,ffffffffc0205606 <do_exit+0xfc>
    if (current == initproc) {
ffffffffc0205532:	000b1417          	auipc	s0,0xb1
ffffffffc0205536:	68e40413          	addi	s0,s0,1678 # ffffffffc02b6bc0 <initproc>
ffffffffc020553a:	6018                	ld	a4,0(s0)
ffffffffc020553c:	0ee78b63          	beq	a5,a4,ffffffffc0205632 <do_exit+0x128>
    struct mm_struct *mm = current->mm;
ffffffffc0205540:	7784                	ld	s1,40(a5)
ffffffffc0205542:	89aa                	mv	s3,a0
    if (mm != NULL) {
ffffffffc0205544:	c48d                	beqz	s1,ffffffffc020556e <do_exit+0x64>
        lcr3(boot_cr3);
ffffffffc0205546:	000b1797          	auipc	a5,0xb1
ffffffffc020554a:	6ba78793          	addi	a5,a5,1722 # ffffffffc02b6c00 <boot_cr3>
ffffffffc020554e:	639c                	ld	a5,0(a5)
ffffffffc0205550:	577d                	li	a4,-1
ffffffffc0205552:	177e                	slli	a4,a4,0x3f
ffffffffc0205554:	83b1                	srli	a5,a5,0xc
ffffffffc0205556:	8fd9                	or	a5,a5,a4
ffffffffc0205558:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc020555c:	589c                	lw	a5,48(s1)
ffffffffc020555e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0205562:	d898                	sw	a4,48(s1)
        if (mm_count_dec(mm) == 0) {
ffffffffc0205564:	cf4d                	beqz	a4,ffffffffc020561e <do_exit+0x114>
        current->mm = NULL;
ffffffffc0205566:	00093783          	ld	a5,0(s2)
ffffffffc020556a:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc020556e:	00093783          	ld	a5,0(s2)
ffffffffc0205572:	470d                	li	a4,3
ffffffffc0205574:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc0205576:	0f37a423          	sw	s3,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020557a:	100027f3          	csrr	a5,sstatus
ffffffffc020557e:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205580:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205582:	e7e1                	bnez	a5,ffffffffc020564a <do_exit+0x140>
        proc = current->parent;
ffffffffc0205584:	00093703          	ld	a4,0(s2)
        if (proc->wait_state == WT_CHILD) {
ffffffffc0205588:	800007b7          	lui	a5,0x80000
ffffffffc020558c:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc020558e:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD) {
ffffffffc0205590:	0ec52703          	lw	a4,236(a0)
ffffffffc0205594:	0af70f63          	beq	a4,a5,ffffffffc0205652 <do_exit+0x148>
ffffffffc0205598:	00093683          	ld	a3,0(s2)
                if (initproc->wait_state == WT_CHILD) {
ffffffffc020559c:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02055a0:	448d                	li	s1,3
                if (initproc->wait_state == WT_CHILD) {
ffffffffc02055a2:	0985                	addi	s3,s3,1
        while (current->cptr != NULL) {
ffffffffc02055a4:	7afc                	ld	a5,240(a3)
ffffffffc02055a6:	cb95                	beqz	a5,ffffffffc02055da <do_exit+0xd0>
            current->cptr = proc->optr;
ffffffffc02055a8:	1007b703          	ld	a4,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff5670>
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc02055ac:	6008                	ld	a0,0(s0)
            current->cptr = proc->optr;
ffffffffc02055ae:	faf8                	sd	a4,240(a3)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc02055b0:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc02055b2:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc02055b6:	10e7b023          	sd	a4,256(a5)
ffffffffc02055ba:	c311                	beqz	a4,ffffffffc02055be <do_exit+0xb4>
                initproc->cptr->yptr = proc;
ffffffffc02055bc:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02055be:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc02055c0:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc02055c2:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02055c4:	fe9710e3          	bne	a4,s1,ffffffffc02055a4 <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD) {
ffffffffc02055c8:	0ec52783          	lw	a5,236(a0)
ffffffffc02055cc:	fd379ce3          	bne	a5,s3,ffffffffc02055a4 <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc02055d0:	2c5000ef          	jal	ra,ffffffffc0206094 <wakeup_proc>
ffffffffc02055d4:	00093683          	ld	a3,0(s2)
ffffffffc02055d8:	b7f1                	j	ffffffffc02055a4 <do_exit+0x9a>
    if (flag) {
ffffffffc02055da:	020a1363          	bnez	s4,ffffffffc0205600 <do_exit+0xf6>
    schedule();
ffffffffc02055de:	333000ef          	jal	ra,ffffffffc0206110 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc02055e2:	00093783          	ld	a5,0(s2)
ffffffffc02055e6:	00003617          	auipc	a2,0x3
ffffffffc02055ea:	17260613          	addi	a2,a2,370 # ffffffffc0208758 <default_pmm_manager+0x12c0>
ffffffffc02055ee:	22e00593          	li	a1,558
ffffffffc02055f2:	43d4                	lw	a3,4(a5)
ffffffffc02055f4:	00003517          	auipc	a0,0x3
ffffffffc02055f8:	3f450513          	addi	a0,a0,1012 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc02055fc:	e89fa0ef          	jal	ra,ffffffffc0200484 <__panic>
        intr_enable();
ffffffffc0205600:	854fb0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0205604:	bfe9                	j	ffffffffc02055de <do_exit+0xd4>
        panic("idleproc exit.\n");
ffffffffc0205606:	00003617          	auipc	a2,0x3
ffffffffc020560a:	13260613          	addi	a2,a2,306 # ffffffffc0208738 <default_pmm_manager+0x12a0>
ffffffffc020560e:	1fa00593          	li	a1,506
ffffffffc0205612:	00003517          	auipc	a0,0x3
ffffffffc0205616:	3d650513          	addi	a0,a0,982 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc020561a:	e6bfa0ef          	jal	ra,ffffffffc0200484 <__panic>
            exit_mmap(mm);
ffffffffc020561e:	8526                	mv	a0,s1
ffffffffc0205620:	e31fe0ef          	jal	ra,ffffffffc0204450 <exit_mmap>
            put_pgdir(mm);
ffffffffc0205624:	8526                	mv	a0,s1
ffffffffc0205626:	92dff0ef          	jal	ra,ffffffffc0204f52 <put_pgdir>
            mm_destroy(mm);
ffffffffc020562a:	8526                	mv	a0,s1
ffffffffc020562c:	c85fe0ef          	jal	ra,ffffffffc02042b0 <mm_destroy>
ffffffffc0205630:	bf1d                	j	ffffffffc0205566 <do_exit+0x5c>
        panic("initproc exit.\n");
ffffffffc0205632:	00003617          	auipc	a2,0x3
ffffffffc0205636:	11660613          	addi	a2,a2,278 # ffffffffc0208748 <default_pmm_manager+0x12b0>
ffffffffc020563a:	1fd00593          	li	a1,509
ffffffffc020563e:	00003517          	auipc	a0,0x3
ffffffffc0205642:	3aa50513          	addi	a0,a0,938 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc0205646:	e3ffa0ef          	jal	ra,ffffffffc0200484 <__panic>
        intr_disable();
ffffffffc020564a:	810fb0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc020564e:	4a05                	li	s4,1
ffffffffc0205650:	bf15                	j	ffffffffc0205584 <do_exit+0x7a>
            wakeup_proc(proc);
ffffffffc0205652:	243000ef          	jal	ra,ffffffffc0206094 <wakeup_proc>
ffffffffc0205656:	b789                	j	ffffffffc0205598 <do_exit+0x8e>

ffffffffc0205658 <do_wait.part.1>:
do_wait(int pid, int *code_store) {
ffffffffc0205658:	7139                	addi	sp,sp,-64
ffffffffc020565a:	e852                	sd	s4,16(sp)
        current->wait_state = WT_CHILD;
ffffffffc020565c:	80000a37          	lui	s4,0x80000
do_wait(int pid, int *code_store) {
ffffffffc0205660:	f426                	sd	s1,40(sp)
ffffffffc0205662:	f04a                	sd	s2,32(sp)
ffffffffc0205664:	ec4e                	sd	s3,24(sp)
ffffffffc0205666:	e456                	sd	s5,8(sp)
ffffffffc0205668:	e05a                	sd	s6,0(sp)
ffffffffc020566a:	fc06                	sd	ra,56(sp)
ffffffffc020566c:	f822                	sd	s0,48(sp)
ffffffffc020566e:	89aa                	mv	s3,a0
ffffffffc0205670:	8b2e                	mv	s6,a1
        proc = current->cptr;
ffffffffc0205672:	000b1917          	auipc	s2,0xb1
ffffffffc0205676:	53e90913          	addi	s2,s2,1342 # ffffffffc02b6bb0 <current>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc020567a:	448d                	li	s1,3
        current->state = PROC_SLEEPING;
ffffffffc020567c:	4a85                	li	s5,1
        current->wait_state = WT_CHILD;
ffffffffc020567e:	2a05                	addiw	s4,s4,1
    if (pid != 0) {
ffffffffc0205680:	02098f63          	beqz	s3,ffffffffc02056be <do_wait.part.1+0x66>
        proc = find_proc(pid);
ffffffffc0205684:	854e                	mv	a0,s3
ffffffffc0205686:	a6fff0ef          	jal	ra,ffffffffc02050f4 <find_proc>
ffffffffc020568a:	842a                	mv	s0,a0
        if (proc != NULL && proc->parent == current) {
ffffffffc020568c:	12050063          	beqz	a0,ffffffffc02057ac <do_wait.part.1+0x154>
ffffffffc0205690:	00093703          	ld	a4,0(s2)
ffffffffc0205694:	711c                	ld	a5,32(a0)
ffffffffc0205696:	10e79b63          	bne	a5,a4,ffffffffc02057ac <do_wait.part.1+0x154>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc020569a:	411c                	lw	a5,0(a0)
ffffffffc020569c:	02978c63          	beq	a5,s1,ffffffffc02056d4 <do_wait.part.1+0x7c>
        current->state = PROC_SLEEPING;
ffffffffc02056a0:	01572023          	sw	s5,0(a4)
        current->wait_state = WT_CHILD;
ffffffffc02056a4:	0f472623          	sw	s4,236(a4)
        schedule();
ffffffffc02056a8:	269000ef          	jal	ra,ffffffffc0206110 <schedule>
        if (current->flags & PF_EXITING) {
ffffffffc02056ac:	00093783          	ld	a5,0(s2)
ffffffffc02056b0:	0b07a783          	lw	a5,176(a5)
ffffffffc02056b4:	8b85                	andi	a5,a5,1
ffffffffc02056b6:	d7e9                	beqz	a5,ffffffffc0205680 <do_wait.part.1+0x28>
            do_exit(-E_KILLED);
ffffffffc02056b8:	555d                	li	a0,-9
ffffffffc02056ba:	e51ff0ef          	jal	ra,ffffffffc020550a <do_exit>
        proc = current->cptr;
ffffffffc02056be:	00093703          	ld	a4,0(s2)
ffffffffc02056c2:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr) {
ffffffffc02056c4:	e409                	bnez	s0,ffffffffc02056ce <do_wait.part.1+0x76>
ffffffffc02056c6:	a0dd                	j	ffffffffc02057ac <do_wait.part.1+0x154>
ffffffffc02056c8:	10043403          	ld	s0,256(s0)
ffffffffc02056cc:	d871                	beqz	s0,ffffffffc02056a0 <do_wait.part.1+0x48>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc02056ce:	401c                	lw	a5,0(s0)
ffffffffc02056d0:	fe979ce3          	bne	a5,s1,ffffffffc02056c8 <do_wait.part.1+0x70>
    if (proc == idleproc || proc == initproc) {
ffffffffc02056d4:	000b1797          	auipc	a5,0xb1
ffffffffc02056d8:	4e478793          	addi	a5,a5,1252 # ffffffffc02b6bb8 <idleproc>
ffffffffc02056dc:	639c                	ld	a5,0(a5)
ffffffffc02056de:	0c878d63          	beq	a5,s0,ffffffffc02057b8 <do_wait.part.1+0x160>
ffffffffc02056e2:	000b1797          	auipc	a5,0xb1
ffffffffc02056e6:	4de78793          	addi	a5,a5,1246 # ffffffffc02b6bc0 <initproc>
ffffffffc02056ea:	639c                	ld	a5,0(a5)
ffffffffc02056ec:	0cf40663          	beq	s0,a5,ffffffffc02057b8 <do_wait.part.1+0x160>
    if (code_store != NULL) {
ffffffffc02056f0:	000b0663          	beqz	s6,ffffffffc02056fc <do_wait.part.1+0xa4>
        *code_store = proc->exit_code;
ffffffffc02056f4:	0e842783          	lw	a5,232(s0)
ffffffffc02056f8:	00fb2023          	sw	a5,0(s6)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02056fc:	100027f3          	csrr	a5,sstatus
ffffffffc0205700:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205702:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205704:	e7d5                	bnez	a5,ffffffffc02057b0 <do_wait.part.1+0x158>
    __list_del(listelm->prev, listelm->next);
ffffffffc0205706:	6c70                	ld	a2,216(s0)
ffffffffc0205708:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL) {
ffffffffc020570a:	10043703          	ld	a4,256(s0)
ffffffffc020570e:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc0205710:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc0205712:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0205714:	6470                	ld	a2,200(s0)
ffffffffc0205716:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc0205718:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc020571a:	e290                	sd	a2,0(a3)
ffffffffc020571c:	c319                	beqz	a4,ffffffffc0205722 <do_wait.part.1+0xca>
        proc->optr->yptr = proc->yptr;
ffffffffc020571e:	ff7c                	sd	a5,248(a4)
ffffffffc0205720:	7c7c                	ld	a5,248(s0)
    if (proc->yptr != NULL) {
ffffffffc0205722:	c3d1                	beqz	a5,ffffffffc02057a6 <do_wait.part.1+0x14e>
        proc->yptr->optr = proc->optr;
ffffffffc0205724:	10e7b023          	sd	a4,256(a5)
    nr_process --;
ffffffffc0205728:	000b1797          	auipc	a5,0xb1
ffffffffc020572c:	4a078793          	addi	a5,a5,1184 # ffffffffc02b6bc8 <nr_process>
ffffffffc0205730:	439c                	lw	a5,0(a5)
ffffffffc0205732:	37fd                	addiw	a5,a5,-1
ffffffffc0205734:	000b1717          	auipc	a4,0xb1
ffffffffc0205738:	48f72a23          	sw	a5,1172(a4) # ffffffffc02b6bc8 <nr_process>
    if (flag) {
ffffffffc020573c:	e1b5                	bnez	a1,ffffffffc02057a0 <do_wait.part.1+0x148>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020573e:	6814                	ld	a3,16(s0)
ffffffffc0205740:	c02007b7          	lui	a5,0xc0200
ffffffffc0205744:	0af6e263          	bltu	a3,a5,ffffffffc02057e8 <do_wait.part.1+0x190>
ffffffffc0205748:	000b1797          	auipc	a5,0xb1
ffffffffc020574c:	4b078793          	addi	a5,a5,1200 # ffffffffc02b6bf8 <va_pa_offset>
ffffffffc0205750:	6398                	ld	a4,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0205752:	000b1797          	auipc	a5,0xb1
ffffffffc0205756:	44678793          	addi	a5,a5,1094 # ffffffffc02b6b98 <npage>
ffffffffc020575a:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc020575c:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage) {
ffffffffc020575e:	82b1                	srli	a3,a3,0xc
ffffffffc0205760:	06f6f863          	bleu	a5,a3,ffffffffc02057d0 <do_wait.part.1+0x178>
    return &pages[PPN(pa) - nbase];
ffffffffc0205764:	00003797          	auipc	a5,0x3
ffffffffc0205768:	74c78793          	addi	a5,a5,1868 # ffffffffc0208eb0 <nbase>
ffffffffc020576c:	639c                	ld	a5,0(a5)
ffffffffc020576e:	000b1717          	auipc	a4,0xb1
ffffffffc0205772:	49a70713          	addi	a4,a4,1178 # ffffffffc02b6c08 <pages>
ffffffffc0205776:	6308                	ld	a0,0(a4)
ffffffffc0205778:	8e9d                	sub	a3,a3,a5
ffffffffc020577a:	069a                	slli	a3,a3,0x6
ffffffffc020577c:	9536                	add	a0,a0,a3
ffffffffc020577e:	4589                	li	a1,2
ffffffffc0205780:	f5afc0ef          	jal	ra,ffffffffc0201eda <free_pages>
    kfree(proc);
ffffffffc0205784:	8522                	mv	a0,s0
ffffffffc0205786:	d8cfc0ef          	jal	ra,ffffffffc0201d12 <kfree>
    return 0;
ffffffffc020578a:	4501                	li	a0,0
}
ffffffffc020578c:	70e2                	ld	ra,56(sp)
ffffffffc020578e:	7442                	ld	s0,48(sp)
ffffffffc0205790:	74a2                	ld	s1,40(sp)
ffffffffc0205792:	7902                	ld	s2,32(sp)
ffffffffc0205794:	69e2                	ld	s3,24(sp)
ffffffffc0205796:	6a42                	ld	s4,16(sp)
ffffffffc0205798:	6aa2                	ld	s5,8(sp)
ffffffffc020579a:	6b02                	ld	s6,0(sp)
ffffffffc020579c:	6121                	addi	sp,sp,64
ffffffffc020579e:	8082                	ret
        intr_enable();
ffffffffc02057a0:	eb5fa0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc02057a4:	bf69                	j	ffffffffc020573e <do_wait.part.1+0xe6>
       proc->parent->cptr = proc->optr;
ffffffffc02057a6:	701c                	ld	a5,32(s0)
ffffffffc02057a8:	fbf8                	sd	a4,240(a5)
ffffffffc02057aa:	bfbd                	j	ffffffffc0205728 <do_wait.part.1+0xd0>
    return -E_BAD_PROC;
ffffffffc02057ac:	5579                	li	a0,-2
ffffffffc02057ae:	bff9                	j	ffffffffc020578c <do_wait.part.1+0x134>
        intr_disable();
ffffffffc02057b0:	eabfa0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc02057b4:	4585                	li	a1,1
ffffffffc02057b6:	bf81                	j	ffffffffc0205706 <do_wait.part.1+0xae>
        panic("wait idleproc or initproc.\n");
ffffffffc02057b8:	00003617          	auipc	a2,0x3
ffffffffc02057bc:	fe860613          	addi	a2,a2,-24 # ffffffffc02087a0 <default_pmm_manager+0x1308>
ffffffffc02057c0:	34400593          	li	a1,836
ffffffffc02057c4:	00003517          	auipc	a0,0x3
ffffffffc02057c8:	22450513          	addi	a0,a0,548 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc02057cc:	cb9fa0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02057d0:	00002617          	auipc	a2,0x2
ffffffffc02057d4:	d7860613          	addi	a2,a2,-648 # ffffffffc0207548 <default_pmm_manager+0xb0>
ffffffffc02057d8:	06200593          	li	a1,98
ffffffffc02057dc:	00002517          	auipc	a0,0x2
ffffffffc02057e0:	d3450513          	addi	a0,a0,-716 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc02057e4:	ca1fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02057e8:	00002617          	auipc	a2,0x2
ffffffffc02057ec:	d3860613          	addi	a2,a2,-712 # ffffffffc0207520 <default_pmm_manager+0x88>
ffffffffc02057f0:	06e00593          	li	a1,110
ffffffffc02057f4:	00002517          	auipc	a0,0x2
ffffffffc02057f8:	d1c50513          	addi	a0,a0,-740 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc02057fc:	c89fa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0205800 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
//在其中创建user_main线程
static int
init_main(void *arg) {
ffffffffc0205800:	1141                	addi	sp,sp,-16
ffffffffc0205802:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc0205804:	f1cfc0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc0205808:	c4afc0ef          	jal	ra,ffffffffc0201c52 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc020580c:	4601                	li	a2,0
ffffffffc020580e:	4581                	li	a1,0
ffffffffc0205810:	fffff517          	auipc	a0,0xfffff
ffffffffc0205814:	6c050513          	addi	a0,a0,1728 # ffffffffc0204ed0 <user_main>
ffffffffc0205818:	ca3ff0ef          	jal	ra,ffffffffc02054ba <kernel_thread>
    if (pid <= 0) {
ffffffffc020581c:	00a04563          	bgtz	a0,ffffffffc0205826 <init_main+0x26>
ffffffffc0205820:	a841                	j	ffffffffc02058b0 <init_main+0xb0>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0) {
        schedule();
ffffffffc0205822:	0ef000ef          	jal	ra,ffffffffc0206110 <schedule>
    if (code_store != NULL) {
ffffffffc0205826:	4581                	li	a1,0
ffffffffc0205828:	4501                	li	a0,0
ffffffffc020582a:	e2fff0ef          	jal	ra,ffffffffc0205658 <do_wait.part.1>
    while (do_wait(0, NULL) == 0) {
ffffffffc020582e:	d975                	beqz	a0,ffffffffc0205822 <init_main+0x22>
    }
    //user_main的用户态程序执行完毕
    cprintf("all user-mode processes have quit.\n");
ffffffffc0205830:	00003517          	auipc	a0,0x3
ffffffffc0205834:	fb050513          	addi	a0,a0,-80 # ffffffffc02087e0 <default_pmm_manager+0x1348>
ffffffffc0205838:	957fa0ef          	jal	ra,ffffffffc020018e <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020583c:	000b1797          	auipc	a5,0xb1
ffffffffc0205840:	38478793          	addi	a5,a5,900 # ffffffffc02b6bc0 <initproc>
ffffffffc0205844:	639c                	ld	a5,0(a5)
ffffffffc0205846:	7bf8                	ld	a4,240(a5)
ffffffffc0205848:	e721                	bnez	a4,ffffffffc0205890 <init_main+0x90>
ffffffffc020584a:	7ff8                	ld	a4,248(a5)
ffffffffc020584c:	e331                	bnez	a4,ffffffffc0205890 <init_main+0x90>
ffffffffc020584e:	1007b703          	ld	a4,256(a5)
ffffffffc0205852:	ef1d                	bnez	a4,ffffffffc0205890 <init_main+0x90>
    assert(nr_process == 2);
ffffffffc0205854:	000b1717          	auipc	a4,0xb1
ffffffffc0205858:	37470713          	addi	a4,a4,884 # ffffffffc02b6bc8 <nr_process>
ffffffffc020585c:	4314                	lw	a3,0(a4)
ffffffffc020585e:	4709                	li	a4,2
ffffffffc0205860:	0ae69463          	bne	a3,a4,ffffffffc0205908 <init_main+0x108>
    return listelm->next;
ffffffffc0205864:	000b1697          	auipc	a3,0xb1
ffffffffc0205868:	48c68693          	addi	a3,a3,1164 # ffffffffc02b6cf0 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020586c:	6698                	ld	a4,8(a3)
ffffffffc020586e:	0c878793          	addi	a5,a5,200
ffffffffc0205872:	06f71b63          	bne	a4,a5,ffffffffc02058e8 <init_main+0xe8>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0205876:	629c                	ld	a5,0(a3)
ffffffffc0205878:	04f71863          	bne	a4,a5,ffffffffc02058c8 <init_main+0xc8>

    cprintf("init check memory pass.\n");
ffffffffc020587c:	00003517          	auipc	a0,0x3
ffffffffc0205880:	04c50513          	addi	a0,a0,76 # ffffffffc02088c8 <default_pmm_manager+0x1430>
ffffffffc0205884:	90bfa0ef          	jal	ra,ffffffffc020018e <cprintf>
    return 0;
}
ffffffffc0205888:	60a2                	ld	ra,8(sp)
ffffffffc020588a:	4501                	li	a0,0
ffffffffc020588c:	0141                	addi	sp,sp,16
ffffffffc020588e:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0205890:	00003697          	auipc	a3,0x3
ffffffffc0205894:	f7868693          	addi	a3,a3,-136 # ffffffffc0208808 <default_pmm_manager+0x1370>
ffffffffc0205898:	00001617          	auipc	a2,0x1
ffffffffc020589c:	4b860613          	addi	a2,a2,1208 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02058a0:	3ae00593          	li	a1,942
ffffffffc02058a4:	00003517          	auipc	a0,0x3
ffffffffc02058a8:	14450513          	addi	a0,a0,324 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc02058ac:	bd9fa0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("create user_main failed.\n");
ffffffffc02058b0:	00003617          	auipc	a2,0x3
ffffffffc02058b4:	f1060613          	addi	a2,a2,-240 # ffffffffc02087c0 <default_pmm_manager+0x1328>
ffffffffc02058b8:	3a600593          	li	a1,934
ffffffffc02058bc:	00003517          	auipc	a0,0x3
ffffffffc02058c0:	12c50513          	addi	a0,a0,300 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc02058c4:	bc1fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc02058c8:	00003697          	auipc	a3,0x3
ffffffffc02058cc:	fd068693          	addi	a3,a3,-48 # ffffffffc0208898 <default_pmm_manager+0x1400>
ffffffffc02058d0:	00001617          	auipc	a2,0x1
ffffffffc02058d4:	48060613          	addi	a2,a2,1152 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02058d8:	3b100593          	li	a1,945
ffffffffc02058dc:	00003517          	auipc	a0,0x3
ffffffffc02058e0:	10c50513          	addi	a0,a0,268 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc02058e4:	ba1fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02058e8:	00003697          	auipc	a3,0x3
ffffffffc02058ec:	f8068693          	addi	a3,a3,-128 # ffffffffc0208868 <default_pmm_manager+0x13d0>
ffffffffc02058f0:	00001617          	auipc	a2,0x1
ffffffffc02058f4:	46060613          	addi	a2,a2,1120 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc02058f8:	3b000593          	li	a1,944
ffffffffc02058fc:	00003517          	auipc	a0,0x3
ffffffffc0205900:	0ec50513          	addi	a0,a0,236 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc0205904:	b81fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_process == 2);
ffffffffc0205908:	00003697          	auipc	a3,0x3
ffffffffc020590c:	f5068693          	addi	a3,a3,-176 # ffffffffc0208858 <default_pmm_manager+0x13c0>
ffffffffc0205910:	00001617          	auipc	a2,0x1
ffffffffc0205914:	44060613          	addi	a2,a2,1088 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0205918:	3af00593          	li	a1,943
ffffffffc020591c:	00003517          	auipc	a0,0x3
ffffffffc0205920:	0cc50513          	addi	a0,a0,204 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc0205924:	b61fa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0205928 <do_execve>:
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205928:	7135                	addi	sp,sp,-160
ffffffffc020592a:	f8d2                	sd	s4,112(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020592c:	000b1a17          	auipc	s4,0xb1
ffffffffc0205930:	284a0a13          	addi	s4,s4,644 # ffffffffc02b6bb0 <current>
ffffffffc0205934:	000a3783          	ld	a5,0(s4)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205938:	e14a                	sd	s2,128(sp)
ffffffffc020593a:	e922                	sd	s0,144(sp)
    struct mm_struct *mm = current->mm;
ffffffffc020593c:	0287b903          	ld	s2,40(a5)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205940:	fcce                	sd	s3,120(sp)
ffffffffc0205942:	f0da                	sd	s6,96(sp)
ffffffffc0205944:	89aa                	mv	s3,a0
ffffffffc0205946:	842e                	mv	s0,a1
ffffffffc0205948:	8b32                	mv	s6,a2
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc020594a:	4681                	li	a3,0
ffffffffc020594c:	862e                	mv	a2,a1
ffffffffc020594e:	85aa                	mv	a1,a0
ffffffffc0205950:	854a                	mv	a0,s2
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc0205952:	ed06                	sd	ra,152(sp)
ffffffffc0205954:	e526                	sd	s1,136(sp)
ffffffffc0205956:	f4d6                	sd	s5,104(sp)
ffffffffc0205958:	ecde                	sd	s7,88(sp)
ffffffffc020595a:	e8e2                	sd	s8,80(sp)
ffffffffc020595c:	e4e6                	sd	s9,72(sp)
ffffffffc020595e:	e0ea                	sd	s10,64(sp)
ffffffffc0205960:	fc6e                	sd	s11,56(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc0205962:	ae6ff0ef          	jal	ra,ffffffffc0204c48 <user_mem_check>
ffffffffc0205966:	40050663          	beqz	a0,ffffffffc0205d72 <do_execve+0x44a>
    memset(local_name, 0, sizeof(local_name));
ffffffffc020596a:	4641                	li	a2,16
ffffffffc020596c:	4581                	li	a1,0
ffffffffc020596e:	1008                	addi	a0,sp,32
ffffffffc0205970:	5c5000ef          	jal	ra,ffffffffc0206734 <memset>
    memcpy(local_name, name, len);
ffffffffc0205974:	47bd                	li	a5,15
ffffffffc0205976:	8622                	mv	a2,s0
ffffffffc0205978:	0687ee63          	bltu	a5,s0,ffffffffc02059f4 <do_execve+0xcc>
ffffffffc020597c:	85ce                	mv	a1,s3
ffffffffc020597e:	1008                	addi	a0,sp,32
ffffffffc0205980:	5c7000ef          	jal	ra,ffffffffc0206746 <memcpy>
    if (mm != NULL) {
ffffffffc0205984:	06090f63          	beqz	s2,ffffffffc0205a02 <do_execve+0xda>
        cputs("mm != NULL");
ffffffffc0205988:	00002517          	auipc	a0,0x2
ffffffffc020598c:	31850513          	addi	a0,a0,792 # ffffffffc0207ca0 <default_pmm_manager+0x808>
ffffffffc0205990:	837fa0ef          	jal	ra,ffffffffc02001c6 <cputs>
        lcr3(boot_cr3);
ffffffffc0205994:	000b1797          	auipc	a5,0xb1
ffffffffc0205998:	26c78793          	addi	a5,a5,620 # ffffffffc02b6c00 <boot_cr3>
ffffffffc020599c:	639c                	ld	a5,0(a5)
ffffffffc020599e:	577d                	li	a4,-1
ffffffffc02059a0:	177e                	slli	a4,a4,0x3f
ffffffffc02059a2:	83b1                	srli	a5,a5,0xc
ffffffffc02059a4:	8fd9                	or	a5,a5,a4
ffffffffc02059a6:	18079073          	csrw	satp,a5
ffffffffc02059aa:	03092783          	lw	a5,48(s2)
ffffffffc02059ae:	fff7871b          	addiw	a4,a5,-1
ffffffffc02059b2:	02e92823          	sw	a4,48(s2)
        if (mm_count_dec(mm) == 0) {
ffffffffc02059b6:	28070d63          	beqz	a4,ffffffffc0205c50 <do_execve+0x328>
        current->mm = NULL;
ffffffffc02059ba:	000a3783          	ld	a5,0(s4)
ffffffffc02059be:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL) {
ffffffffc02059c2:	f68fe0ef          	jal	ra,ffffffffc020412a <mm_create>
ffffffffc02059c6:	892a                	mv	s2,a0
ffffffffc02059c8:	c135                	beqz	a0,ffffffffc0205a2c <do_execve+0x104>
    if (setup_pgdir(mm) != 0) {
ffffffffc02059ca:	e06ff0ef          	jal	ra,ffffffffc0204fd0 <setup_pgdir>
ffffffffc02059ce:	e931                	bnez	a0,ffffffffc0205a22 <do_execve+0xfa>
    if (elf->e_magic != ELF_MAGIC) {
ffffffffc02059d0:	000b2703          	lw	a4,0(s6)
ffffffffc02059d4:	464c47b7          	lui	a5,0x464c4
ffffffffc02059d8:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b9aef>
ffffffffc02059dc:	04f70a63          	beq	a4,a5,ffffffffc0205a30 <do_execve+0x108>
    put_pgdir(mm);
ffffffffc02059e0:	854a                	mv	a0,s2
ffffffffc02059e2:	d70ff0ef          	jal	ra,ffffffffc0204f52 <put_pgdir>
    mm_destroy(mm);
ffffffffc02059e6:	854a                	mv	a0,s2
ffffffffc02059e8:	8c9fe0ef          	jal	ra,ffffffffc02042b0 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc02059ec:	59e1                	li	s3,-8
    do_exit(ret);
ffffffffc02059ee:	854e                	mv	a0,s3
ffffffffc02059f0:	b1bff0ef          	jal	ra,ffffffffc020550a <do_exit>
    memcpy(local_name, name, len);
ffffffffc02059f4:	463d                	li	a2,15
ffffffffc02059f6:	85ce                	mv	a1,s3
ffffffffc02059f8:	1008                	addi	a0,sp,32
ffffffffc02059fa:	54d000ef          	jal	ra,ffffffffc0206746 <memcpy>
    if (mm != NULL) {
ffffffffc02059fe:	f80915e3          	bnez	s2,ffffffffc0205988 <do_execve+0x60>
    if (current->mm != NULL) {
ffffffffc0205a02:	000a3783          	ld	a5,0(s4)
ffffffffc0205a06:	779c                	ld	a5,40(a5)
ffffffffc0205a08:	dfcd                	beqz	a5,ffffffffc02059c2 <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0205a0a:	00003617          	auipc	a2,0x3
ffffffffc0205a0e:	ba660613          	addi	a2,a2,-1114 # ffffffffc02085b0 <default_pmm_manager+0x1118>
ffffffffc0205a12:	23b00593          	li	a1,571
ffffffffc0205a16:	00003517          	auipc	a0,0x3
ffffffffc0205a1a:	fd250513          	addi	a0,a0,-46 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc0205a1e:	a67fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    mm_destroy(mm);
ffffffffc0205a22:	854a                	mv	a0,s2
ffffffffc0205a24:	88dfe0ef          	jal	ra,ffffffffc02042b0 <mm_destroy>
    int ret = -E_NO_MEM;
ffffffffc0205a28:	59f1                	li	s3,-4
ffffffffc0205a2a:	b7d1                	j	ffffffffc02059ee <do_execve+0xc6>
ffffffffc0205a2c:	59f1                	li	s3,-4
ffffffffc0205a2e:	b7c1                	j	ffffffffc02059ee <do_execve+0xc6>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0205a30:	038b5703          	lhu	a4,56(s6)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0205a34:	020b3403          	ld	s0,32(s6)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0205a38:	00371793          	slli	a5,a4,0x3
ffffffffc0205a3c:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0205a3e:	945a                	add	s0,s0,s6
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0205a40:	078e                	slli	a5,a5,0x3
ffffffffc0205a42:	97a2                	add	a5,a5,s0
ffffffffc0205a44:	ec3e                	sd	a5,24(sp)
    for (; ph < ph_end; ph ++) {
ffffffffc0205a46:	02f47b63          	bleu	a5,s0,ffffffffc0205a7c <do_execve+0x154>
    return KADDR(page2pa(page));
ffffffffc0205a4a:	5bfd                	li	s7,-1
ffffffffc0205a4c:	00cbd793          	srli	a5,s7,0xc
    return page - pages + nbase;
ffffffffc0205a50:	000b1d97          	auipc	s11,0xb1
ffffffffc0205a54:	1b8d8d93          	addi	s11,s11,440 # ffffffffc02b6c08 <pages>
ffffffffc0205a58:	00003d17          	auipc	s10,0x3
ffffffffc0205a5c:	458d0d13          	addi	s10,s10,1112 # ffffffffc0208eb0 <nbase>
    return KADDR(page2pa(page));
ffffffffc0205a60:	e43e                	sd	a5,8(sp)
ffffffffc0205a62:	000b1c97          	auipc	s9,0xb1
ffffffffc0205a66:	136c8c93          	addi	s9,s9,310 # ffffffffc02b6b98 <npage>
        if (ph->p_type != ELF_PT_LOAD) {
ffffffffc0205a6a:	4018                	lw	a4,0(s0)
ffffffffc0205a6c:	4785                	li	a5,1
ffffffffc0205a6e:	0ef70f63          	beq	a4,a5,ffffffffc0205b6c <do_execve+0x244>
    for (; ph < ph_end; ph ++) {
ffffffffc0205a72:	67e2                	ld	a5,24(sp)
ffffffffc0205a74:	03840413          	addi	s0,s0,56
ffffffffc0205a78:	fef469e3          	bltu	s0,a5,ffffffffc0205a6a <do_execve+0x142>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) {
ffffffffc0205a7c:	4701                	li	a4,0
ffffffffc0205a7e:	46ad                	li	a3,11
ffffffffc0205a80:	00100637          	lui	a2,0x100
ffffffffc0205a84:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0205a88:	854a                	mv	a0,s2
ffffffffc0205a8a:	879fe0ef          	jal	ra,ffffffffc0204302 <mm_map>
ffffffffc0205a8e:	89aa                	mv	s3,a0
ffffffffc0205a90:	1a051663          	bnez	a0,ffffffffc0205c3c <do_execve+0x314>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
ffffffffc0205a94:	01893503          	ld	a0,24(s2)
ffffffffc0205a98:	467d                	li	a2,31
ffffffffc0205a9a:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0205a9e:	8bffd0ef          	jal	ra,ffffffffc020335c <pgdir_alloc_page>
ffffffffc0205aa2:	36050463          	beqz	a0,ffffffffc0205e0a <do_execve+0x4e2>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
ffffffffc0205aa6:	01893503          	ld	a0,24(s2)
ffffffffc0205aaa:	467d                	li	a2,31
ffffffffc0205aac:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0205ab0:	8adfd0ef          	jal	ra,ffffffffc020335c <pgdir_alloc_page>
ffffffffc0205ab4:	32050b63          	beqz	a0,ffffffffc0205dea <do_execve+0x4c2>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
ffffffffc0205ab8:	01893503          	ld	a0,24(s2)
ffffffffc0205abc:	467d                	li	a2,31
ffffffffc0205abe:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0205ac2:	89bfd0ef          	jal	ra,ffffffffc020335c <pgdir_alloc_page>
ffffffffc0205ac6:	30050263          	beqz	a0,ffffffffc0205dca <do_execve+0x4a2>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
ffffffffc0205aca:	01893503          	ld	a0,24(s2)
ffffffffc0205ace:	467d                	li	a2,31
ffffffffc0205ad0:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0205ad4:	889fd0ef          	jal	ra,ffffffffc020335c <pgdir_alloc_page>
ffffffffc0205ad8:	2c050963          	beqz	a0,ffffffffc0205daa <do_execve+0x482>
    mm->mm_count += 1;
ffffffffc0205adc:	03092783          	lw	a5,48(s2)
    current->mm = mm;
ffffffffc0205ae0:	000a3603          	ld	a2,0(s4)
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205ae4:	01893683          	ld	a3,24(s2)
ffffffffc0205ae8:	2785                	addiw	a5,a5,1
ffffffffc0205aea:	02f92823          	sw	a5,48(s2)
    current->mm = mm;
ffffffffc0205aee:	03263423          	sd	s2,40(a2) # 100028 <_binary_obj___user_exit_out_size+0xf5598>
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205af2:	c02007b7          	lui	a5,0xc0200
ffffffffc0205af6:	28f6ee63          	bltu	a3,a5,ffffffffc0205d92 <do_execve+0x46a>
ffffffffc0205afa:	000b1797          	auipc	a5,0xb1
ffffffffc0205afe:	0fe78793          	addi	a5,a5,254 # ffffffffc02b6bf8 <va_pa_offset>
ffffffffc0205b02:	639c                	ld	a5,0(a5)
ffffffffc0205b04:	577d                	li	a4,-1
ffffffffc0205b06:	177e                	slli	a4,a4,0x3f
ffffffffc0205b08:	8e9d                	sub	a3,a3,a5
ffffffffc0205b0a:	00c6d793          	srli	a5,a3,0xc
ffffffffc0205b0e:	f654                	sd	a3,168(a2)
ffffffffc0205b10:	8fd9                	or	a5,a5,a4
ffffffffc0205b12:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0205b16:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0205b18:	4581                	li	a1,0
ffffffffc0205b1a:	12000613          	li	a2,288
ffffffffc0205b1e:	8522                	mv	a0,s0
ffffffffc0205b20:	415000ef          	jal	ra,ffffffffc0206734 <memset>
    tf->epc = elf->e_entry;
ffffffffc0205b24:	018b3703          	ld	a4,24(s6)
    tf->gpr.sp = USTACKTOP;
ffffffffc0205b28:	4785                	li	a5,1
ffffffffc0205b2a:	07fe                	slli	a5,a5,0x1f
ffffffffc0205b2c:	e81c                	sd	a5,16(s0)
    tf->epc = elf->e_entry;
ffffffffc0205b2e:	10e43423          	sd	a4,264(s0)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0205b32:	100027f3          	csrr	a5,sstatus
ffffffffc0205b36:	edf7f793          	andi	a5,a5,-289
    set_proc_name(current, local_name);
ffffffffc0205b3a:	000a3503          	ld	a0,0(s4)
    tf->status = (read_csr(sstatus) & ~SSTATUS_SPP) | SSTATUS_SPIE;
ffffffffc0205b3e:	0207e793          	ori	a5,a5,32
ffffffffc0205b42:	10f43023          	sd	a5,256(s0)
    set_proc_name(current, local_name);
ffffffffc0205b46:	100c                	addi	a1,sp,32
ffffffffc0205b48:	d14ff0ef          	jal	ra,ffffffffc020505c <set_proc_name>
}
ffffffffc0205b4c:	60ea                	ld	ra,152(sp)
ffffffffc0205b4e:	644a                	ld	s0,144(sp)
ffffffffc0205b50:	854e                	mv	a0,s3
ffffffffc0205b52:	64aa                	ld	s1,136(sp)
ffffffffc0205b54:	690a                	ld	s2,128(sp)
ffffffffc0205b56:	79e6                	ld	s3,120(sp)
ffffffffc0205b58:	7a46                	ld	s4,112(sp)
ffffffffc0205b5a:	7aa6                	ld	s5,104(sp)
ffffffffc0205b5c:	7b06                	ld	s6,96(sp)
ffffffffc0205b5e:	6be6                	ld	s7,88(sp)
ffffffffc0205b60:	6c46                	ld	s8,80(sp)
ffffffffc0205b62:	6ca6                	ld	s9,72(sp)
ffffffffc0205b64:	6d06                	ld	s10,64(sp)
ffffffffc0205b66:	7de2                	ld	s11,56(sp)
ffffffffc0205b68:	610d                	addi	sp,sp,160
ffffffffc0205b6a:	8082                	ret
        if (ph->p_filesz > ph->p_memsz) {
ffffffffc0205b6c:	7410                	ld	a2,40(s0)
ffffffffc0205b6e:	701c                	ld	a5,32(s0)
ffffffffc0205b70:	20f66363          	bltu	a2,a5,ffffffffc0205d76 <do_execve+0x44e>
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
ffffffffc0205b74:	405c                	lw	a5,4(s0)
ffffffffc0205b76:	0017f693          	andi	a3,a5,1
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205b7a:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
ffffffffc0205b7e:	068a                	slli	a3,a3,0x2
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205b80:	0e071263          	bnez	a4,ffffffffc0205c64 <do_execve+0x33c>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0205b84:	4745                	li	a4,17
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205b86:	8b91                	andi	a5,a5,4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0205b88:	e03a                	sd	a4,0(sp)
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205b8a:	c789                	beqz	a5,ffffffffc0205b94 <do_execve+0x26c>
        if (vm_flags & VM_READ) perm |= PTE_R;
ffffffffc0205b8c:	47cd                	li	a5,19
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205b8e:	0016e693          	ori	a3,a3,1
        if (vm_flags & VM_READ) perm |= PTE_R;
ffffffffc0205b92:	e03e                	sd	a5,0(sp)
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc0205b94:	0026f793          	andi	a5,a3,2
ffffffffc0205b98:	efe1                	bnez	a5,ffffffffc0205c70 <do_execve+0x348>
        if (vm_flags & VM_EXEC) perm |= PTE_X;
ffffffffc0205b9a:	0046f793          	andi	a5,a3,4
ffffffffc0205b9e:	c789                	beqz	a5,ffffffffc0205ba8 <do_execve+0x280>
ffffffffc0205ba0:	6782                	ld	a5,0(sp)
ffffffffc0205ba2:	0087e793          	ori	a5,a5,8
ffffffffc0205ba6:	e03e                	sd	a5,0(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) {
ffffffffc0205ba8:	680c                	ld	a1,16(s0)
ffffffffc0205baa:	4701                	li	a4,0
ffffffffc0205bac:	854a                	mv	a0,s2
ffffffffc0205bae:	f54fe0ef          	jal	ra,ffffffffc0204302 <mm_map>
ffffffffc0205bb2:	89aa                	mv	s3,a0
ffffffffc0205bb4:	e541                	bnez	a0,ffffffffc0205c3c <do_execve+0x314>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205bb6:	01043b83          	ld	s7,16(s0)
        end = ph->p_va + ph->p_filesz;
ffffffffc0205bba:	02043983          	ld	s3,32(s0)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205bbe:	00843a83          	ld	s5,8(s0)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205bc2:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0205bc4:	99de                	add	s3,s3,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205bc6:	9ada                	add	s5,s5,s6
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205bc8:	00fbfc33          	and	s8,s7,a5
        while (start < end) {
ffffffffc0205bcc:	053bef63          	bltu	s7,s3,ffffffffc0205c2a <do_execve+0x302>
ffffffffc0205bd0:	aa79                	j	ffffffffc0205d6e <do_execve+0x446>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205bd2:	6785                	lui	a5,0x1
ffffffffc0205bd4:	418b8533          	sub	a0,s7,s8
ffffffffc0205bd8:	9c3e                	add	s8,s8,a5
ffffffffc0205bda:	417c0833          	sub	a6,s8,s7
            if (end < la) {
ffffffffc0205bde:	0189f463          	bleu	s8,s3,ffffffffc0205be6 <do_execve+0x2be>
                size -= la - end;
ffffffffc0205be2:	41798833          	sub	a6,s3,s7
    return page - pages + nbase;
ffffffffc0205be6:	000db683          	ld	a3,0(s11)
ffffffffc0205bea:	000d3583          	ld	a1,0(s10)
    return KADDR(page2pa(page));
ffffffffc0205bee:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205bf0:	40d486b3          	sub	a3,s1,a3
ffffffffc0205bf4:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205bf6:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0205bfa:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0205bfc:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205c00:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205c02:	16c5fc63          	bleu	a2,a1,ffffffffc0205d7a <do_execve+0x452>
ffffffffc0205c06:	000b1797          	auipc	a5,0xb1
ffffffffc0205c0a:	ff278793          	addi	a5,a5,-14 # ffffffffc02b6bf8 <va_pa_offset>
ffffffffc0205c0e:	0007b883          	ld	a7,0(a5)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205c12:	85d6                	mv	a1,s5
ffffffffc0205c14:	8642                	mv	a2,a6
ffffffffc0205c16:	96c6                	add	a3,a3,a7
ffffffffc0205c18:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0205c1a:	9bc2                	add	s7,s7,a6
ffffffffc0205c1c:	e842                	sd	a6,16(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205c1e:	329000ef          	jal	ra,ffffffffc0206746 <memcpy>
            start += size, from += size;
ffffffffc0205c22:	6842                	ld	a6,16(sp)
ffffffffc0205c24:	9ac2                	add	s5,s5,a6
        while (start < end) {
ffffffffc0205c26:	053bf863          	bleu	s3,s7,ffffffffc0205c76 <do_execve+0x34e>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0205c2a:	01893503          	ld	a0,24(s2)
ffffffffc0205c2e:	6602                	ld	a2,0(sp)
ffffffffc0205c30:	85e2                	mv	a1,s8
ffffffffc0205c32:	f2afd0ef          	jal	ra,ffffffffc020335c <pgdir_alloc_page>
ffffffffc0205c36:	84aa                	mv	s1,a0
ffffffffc0205c38:	fd49                	bnez	a0,ffffffffc0205bd2 <do_execve+0x2aa>
        ret = -E_NO_MEM;
ffffffffc0205c3a:	59f1                	li	s3,-4
    exit_mmap(mm);
ffffffffc0205c3c:	854a                	mv	a0,s2
ffffffffc0205c3e:	813fe0ef          	jal	ra,ffffffffc0204450 <exit_mmap>
    put_pgdir(mm);
ffffffffc0205c42:	854a                	mv	a0,s2
ffffffffc0205c44:	b0eff0ef          	jal	ra,ffffffffc0204f52 <put_pgdir>
    mm_destroy(mm);
ffffffffc0205c48:	854a                	mv	a0,s2
ffffffffc0205c4a:	e66fe0ef          	jal	ra,ffffffffc02042b0 <mm_destroy>
    return ret;
ffffffffc0205c4e:	b345                	j	ffffffffc02059ee <do_execve+0xc6>
            exit_mmap(mm);
ffffffffc0205c50:	854a                	mv	a0,s2
ffffffffc0205c52:	ffefe0ef          	jal	ra,ffffffffc0204450 <exit_mmap>
            put_pgdir(mm);
ffffffffc0205c56:	854a                	mv	a0,s2
ffffffffc0205c58:	afaff0ef          	jal	ra,ffffffffc0204f52 <put_pgdir>
            mm_destroy(mm);
ffffffffc0205c5c:	854a                	mv	a0,s2
ffffffffc0205c5e:	e52fe0ef          	jal	ra,ffffffffc02042b0 <mm_destroy>
ffffffffc0205c62:	bba1                	j	ffffffffc02059ba <do_execve+0x92>
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205c64:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205c68:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205c6a:	2681                	sext.w	a3,a3
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205c6c:	f20790e3          	bnez	a5,ffffffffc0205b8c <do_execve+0x264>
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc0205c70:	47dd                	li	a5,23
ffffffffc0205c72:	e03e                	sd	a5,0(sp)
ffffffffc0205c74:	b71d                	j	ffffffffc0205b9a <do_execve+0x272>
ffffffffc0205c76:	01043983          	ld	s3,16(s0)
        end = ph->p_va + ph->p_memsz;
ffffffffc0205c7a:	7414                	ld	a3,40(s0)
ffffffffc0205c7c:	99b6                	add	s3,s3,a3
        if (start < la) {
ffffffffc0205c7e:	098bf163          	bleu	s8,s7,ffffffffc0205d00 <do_execve+0x3d8>
            if (start == end) {
ffffffffc0205c82:	df7988e3          	beq	s3,s7,ffffffffc0205a72 <do_execve+0x14a>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205c86:	6505                	lui	a0,0x1
ffffffffc0205c88:	955e                	add	a0,a0,s7
ffffffffc0205c8a:	41850533          	sub	a0,a0,s8
                size -= la - end;
ffffffffc0205c8e:	41798ab3          	sub	s5,s3,s7
            if (end < la) {
ffffffffc0205c92:	0d89fb63          	bleu	s8,s3,ffffffffc0205d68 <do_execve+0x440>
    return page - pages + nbase;
ffffffffc0205c96:	000db683          	ld	a3,0(s11)
ffffffffc0205c9a:	000d3583          	ld	a1,0(s10)
    return KADDR(page2pa(page));
ffffffffc0205c9e:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205ca0:	40d486b3          	sub	a3,s1,a3
ffffffffc0205ca4:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205ca6:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0205caa:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0205cac:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205cb0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205cb2:	0cc5f463          	bleu	a2,a1,ffffffffc0205d7a <do_execve+0x452>
ffffffffc0205cb6:	000b1617          	auipc	a2,0xb1
ffffffffc0205cba:	f4260613          	addi	a2,a2,-190 # ffffffffc02b6bf8 <va_pa_offset>
ffffffffc0205cbe:	00063803          	ld	a6,0(a2)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205cc2:	4581                	li	a1,0
ffffffffc0205cc4:	8656                	mv	a2,s5
ffffffffc0205cc6:	96c2                	add	a3,a3,a6
ffffffffc0205cc8:	9536                	add	a0,a0,a3
ffffffffc0205cca:	26b000ef          	jal	ra,ffffffffc0206734 <memset>
            start += size;
ffffffffc0205cce:	017a8733          	add	a4,s5,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0205cd2:	0389f463          	bleu	s8,s3,ffffffffc0205cfa <do_execve+0x3d2>
ffffffffc0205cd6:	d8e98ee3          	beq	s3,a4,ffffffffc0205a72 <do_execve+0x14a>
ffffffffc0205cda:	00003697          	auipc	a3,0x3
ffffffffc0205cde:	8fe68693          	addi	a3,a3,-1794 # ffffffffc02085d8 <default_pmm_manager+0x1140>
ffffffffc0205ce2:	00001617          	auipc	a2,0x1
ffffffffc0205ce6:	06e60613          	addi	a2,a2,110 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0205cea:	29d00593          	li	a1,669
ffffffffc0205cee:	00003517          	auipc	a0,0x3
ffffffffc0205cf2:	cfa50513          	addi	a0,a0,-774 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc0205cf6:	f8efa0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0205cfa:	ff8710e3          	bne	a4,s8,ffffffffc0205cda <do_execve+0x3b2>
ffffffffc0205cfe:	8be2                	mv	s7,s8
ffffffffc0205d00:	000b1a97          	auipc	s5,0xb1
ffffffffc0205d04:	ef8a8a93          	addi	s5,s5,-264 # ffffffffc02b6bf8 <va_pa_offset>
        while (start < end) {
ffffffffc0205d08:	053be763          	bltu	s7,s3,ffffffffc0205d56 <do_execve+0x42e>
ffffffffc0205d0c:	b39d                	j	ffffffffc0205a72 <do_execve+0x14a>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205d0e:	6785                	lui	a5,0x1
ffffffffc0205d10:	418b8533          	sub	a0,s7,s8
ffffffffc0205d14:	9c3e                	add	s8,s8,a5
ffffffffc0205d16:	417c0633          	sub	a2,s8,s7
            if (end < la) {
ffffffffc0205d1a:	0189f463          	bleu	s8,s3,ffffffffc0205d22 <do_execve+0x3fa>
                size -= la - end;
ffffffffc0205d1e:	41798633          	sub	a2,s3,s7
    return page - pages + nbase;
ffffffffc0205d22:	000db683          	ld	a3,0(s11)
ffffffffc0205d26:	000d3803          	ld	a6,0(s10)
    return KADDR(page2pa(page));
ffffffffc0205d2a:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205d2c:	40d486b3          	sub	a3,s1,a3
ffffffffc0205d30:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205d32:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0205d36:	96c2                	add	a3,a3,a6
    return KADDR(page2pa(page));
ffffffffc0205d38:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205d3c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205d3e:	02b87e63          	bleu	a1,a6,ffffffffc0205d7a <do_execve+0x452>
ffffffffc0205d42:	000ab803          	ld	a6,0(s5)
            start += size;
ffffffffc0205d46:	9bb2                	add	s7,s7,a2
            memset(page2kva(page) + off, 0, size);
ffffffffc0205d48:	4581                	li	a1,0
ffffffffc0205d4a:	96c2                	add	a3,a3,a6
ffffffffc0205d4c:	9536                	add	a0,a0,a3
ffffffffc0205d4e:	1e7000ef          	jal	ra,ffffffffc0206734 <memset>
        while (start < end) {
ffffffffc0205d52:	d33bf0e3          	bleu	s3,s7,ffffffffc0205a72 <do_execve+0x14a>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0205d56:	01893503          	ld	a0,24(s2)
ffffffffc0205d5a:	6602                	ld	a2,0(sp)
ffffffffc0205d5c:	85e2                	mv	a1,s8
ffffffffc0205d5e:	dfefd0ef          	jal	ra,ffffffffc020335c <pgdir_alloc_page>
ffffffffc0205d62:	84aa                	mv	s1,a0
ffffffffc0205d64:	f54d                	bnez	a0,ffffffffc0205d0e <do_execve+0x3e6>
ffffffffc0205d66:	bdd1                	j	ffffffffc0205c3a <do_execve+0x312>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205d68:	417c0ab3          	sub	s5,s8,s7
ffffffffc0205d6c:	b72d                	j	ffffffffc0205c96 <do_execve+0x36e>
        while (start < end) {
ffffffffc0205d6e:	89de                	mv	s3,s7
ffffffffc0205d70:	b729                	j	ffffffffc0205c7a <do_execve+0x352>
        return -E_INVAL;
ffffffffc0205d72:	59f5                	li	s3,-3
ffffffffc0205d74:	bbe1                	j	ffffffffc0205b4c <do_execve+0x224>
            ret = -E_INVAL_ELF;
ffffffffc0205d76:	59e1                	li	s3,-8
ffffffffc0205d78:	b5d1                	j	ffffffffc0205c3c <do_execve+0x314>
ffffffffc0205d7a:	00001617          	auipc	a2,0x1
ffffffffc0205d7e:	76e60613          	addi	a2,a2,1902 # ffffffffc02074e8 <default_pmm_manager+0x50>
ffffffffc0205d82:	06900593          	li	a1,105
ffffffffc0205d86:	00001517          	auipc	a0,0x1
ffffffffc0205d8a:	78a50513          	addi	a0,a0,1930 # ffffffffc0207510 <default_pmm_manager+0x78>
ffffffffc0205d8e:	ef6fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205d92:	00001617          	auipc	a2,0x1
ffffffffc0205d96:	78e60613          	addi	a2,a2,1934 # ffffffffc0207520 <default_pmm_manager+0x88>
ffffffffc0205d9a:	2b900593          	li	a1,697
ffffffffc0205d9e:	00003517          	auipc	a0,0x3
ffffffffc0205da2:	c4a50513          	addi	a0,a0,-950 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc0205da6:	edefa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
ffffffffc0205daa:	00003697          	auipc	a3,0x3
ffffffffc0205dae:	94668693          	addi	a3,a3,-1722 # ffffffffc02086f0 <default_pmm_manager+0x1258>
ffffffffc0205db2:	00001617          	auipc	a2,0x1
ffffffffc0205db6:	f9e60613          	addi	a2,a2,-98 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0205dba:	2b400593          	li	a1,692
ffffffffc0205dbe:	00003517          	auipc	a0,0x3
ffffffffc0205dc2:	c2a50513          	addi	a0,a0,-982 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc0205dc6:	ebefa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
ffffffffc0205dca:	00003697          	auipc	a3,0x3
ffffffffc0205dce:	8de68693          	addi	a3,a3,-1826 # ffffffffc02086a8 <default_pmm_manager+0x1210>
ffffffffc0205dd2:	00001617          	auipc	a2,0x1
ffffffffc0205dd6:	f7e60613          	addi	a2,a2,-130 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0205dda:	2b300593          	li	a1,691
ffffffffc0205dde:	00003517          	auipc	a0,0x3
ffffffffc0205de2:	c0a50513          	addi	a0,a0,-1014 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc0205de6:	e9efa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
ffffffffc0205dea:	00003697          	auipc	a3,0x3
ffffffffc0205dee:	87668693          	addi	a3,a3,-1930 # ffffffffc0208660 <default_pmm_manager+0x11c8>
ffffffffc0205df2:	00001617          	auipc	a2,0x1
ffffffffc0205df6:	f5e60613          	addi	a2,a2,-162 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0205dfa:	2b200593          	li	a1,690
ffffffffc0205dfe:	00003517          	auipc	a0,0x3
ffffffffc0205e02:	bea50513          	addi	a0,a0,-1046 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc0205e06:	e7efa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
ffffffffc0205e0a:	00003697          	auipc	a3,0x3
ffffffffc0205e0e:	80e68693          	addi	a3,a3,-2034 # ffffffffc0208618 <default_pmm_manager+0x1180>
ffffffffc0205e12:	00001617          	auipc	a2,0x1
ffffffffc0205e16:	f3e60613          	addi	a2,a2,-194 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0205e1a:	2b100593          	li	a1,689
ffffffffc0205e1e:	00003517          	auipc	a0,0x3
ffffffffc0205e22:	bca50513          	addi	a0,a0,-1078 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc0205e26:	e5efa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0205e2a <do_yield>:
    current->need_resched = 1;
ffffffffc0205e2a:	000b1797          	auipc	a5,0xb1
ffffffffc0205e2e:	d8678793          	addi	a5,a5,-634 # ffffffffc02b6bb0 <current>
ffffffffc0205e32:	639c                	ld	a5,0(a5)
ffffffffc0205e34:	4705                	li	a4,1
}
ffffffffc0205e36:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0205e38:	ef98                	sd	a4,24(a5)
}
ffffffffc0205e3a:	8082                	ret

ffffffffc0205e3c <do_wait>:
do_wait(int pid, int *code_store) {
ffffffffc0205e3c:	1101                	addi	sp,sp,-32
ffffffffc0205e3e:	e822                	sd	s0,16(sp)
ffffffffc0205e40:	e426                	sd	s1,8(sp)
ffffffffc0205e42:	ec06                	sd	ra,24(sp)
ffffffffc0205e44:	842e                	mv	s0,a1
ffffffffc0205e46:	84aa                	mv	s1,a0
    if (code_store != NULL) {
ffffffffc0205e48:	cd81                	beqz	a1,ffffffffc0205e60 <do_wait+0x24>
    struct mm_struct *mm = current->mm;
ffffffffc0205e4a:	000b1797          	auipc	a5,0xb1
ffffffffc0205e4e:	d6678793          	addi	a5,a5,-666 # ffffffffc02b6bb0 <current>
ffffffffc0205e52:	639c                	ld	a5,0(a5)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1)) {
ffffffffc0205e54:	4685                	li	a3,1
ffffffffc0205e56:	4611                	li	a2,4
ffffffffc0205e58:	7788                	ld	a0,40(a5)
ffffffffc0205e5a:	deffe0ef          	jal	ra,ffffffffc0204c48 <user_mem_check>
ffffffffc0205e5e:	c909                	beqz	a0,ffffffffc0205e70 <do_wait+0x34>
ffffffffc0205e60:	85a2                	mv	a1,s0
}
ffffffffc0205e62:	6442                	ld	s0,16(sp)
ffffffffc0205e64:	60e2                	ld	ra,24(sp)
ffffffffc0205e66:	8526                	mv	a0,s1
ffffffffc0205e68:	64a2                	ld	s1,8(sp)
ffffffffc0205e6a:	6105                	addi	sp,sp,32
ffffffffc0205e6c:	fecff06f          	j	ffffffffc0205658 <do_wait.part.1>
ffffffffc0205e70:	60e2                	ld	ra,24(sp)
ffffffffc0205e72:	6442                	ld	s0,16(sp)
ffffffffc0205e74:	64a2                	ld	s1,8(sp)
ffffffffc0205e76:	5575                	li	a0,-3
ffffffffc0205e78:	6105                	addi	sp,sp,32
ffffffffc0205e7a:	8082                	ret

ffffffffc0205e7c <do_kill>:
do_kill(int pid) {
ffffffffc0205e7c:	1141                	addi	sp,sp,-16
ffffffffc0205e7e:	e406                	sd	ra,8(sp)
ffffffffc0205e80:	e022                	sd	s0,0(sp)
    if ((proc = find_proc(pid)) != NULL) {
ffffffffc0205e82:	a72ff0ef          	jal	ra,ffffffffc02050f4 <find_proc>
ffffffffc0205e86:	cd0d                	beqz	a0,ffffffffc0205ec0 <do_kill+0x44>
        if (!(proc->flags & PF_EXITING)) {
ffffffffc0205e88:	0b052703          	lw	a4,176(a0)
ffffffffc0205e8c:	00177693          	andi	a3,a4,1
ffffffffc0205e90:	e695                	bnez	a3,ffffffffc0205ebc <do_kill+0x40>
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205e92:	0ec52683          	lw	a3,236(a0)
            proc->flags |= PF_EXITING;
ffffffffc0205e96:	00176713          	ori	a4,a4,1
ffffffffc0205e9a:	0ae52823          	sw	a4,176(a0)
            return 0;
ffffffffc0205e9e:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205ea0:	0006c763          	bltz	a3,ffffffffc0205eae <do_kill+0x32>
}
ffffffffc0205ea4:	8522                	mv	a0,s0
ffffffffc0205ea6:	60a2                	ld	ra,8(sp)
ffffffffc0205ea8:	6402                	ld	s0,0(sp)
ffffffffc0205eaa:	0141                	addi	sp,sp,16
ffffffffc0205eac:	8082                	ret
                wakeup_proc(proc);
ffffffffc0205eae:	1e6000ef          	jal	ra,ffffffffc0206094 <wakeup_proc>
}
ffffffffc0205eb2:	8522                	mv	a0,s0
ffffffffc0205eb4:	60a2                	ld	ra,8(sp)
ffffffffc0205eb6:	6402                	ld	s0,0(sp)
ffffffffc0205eb8:	0141                	addi	sp,sp,16
ffffffffc0205eba:	8082                	ret
        return -E_KILLED;
ffffffffc0205ebc:	545d                	li	s0,-9
ffffffffc0205ebe:	b7dd                	j	ffffffffc0205ea4 <do_kill+0x28>
    return -E_INVAL;
ffffffffc0205ec0:	5475                	li	s0,-3
ffffffffc0205ec2:	b7cd                	j	ffffffffc0205ea4 <do_kill+0x28>

ffffffffc0205ec4 <proc_init>:
    elm->prev = elm->next = elm;
ffffffffc0205ec4:	000b1797          	auipc	a5,0xb1
ffffffffc0205ec8:	e2c78793          	addi	a5,a5,-468 # ffffffffc02b6cf0 <proc_list>

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
void
proc_init(void) {
ffffffffc0205ecc:	1101                	addi	sp,sp,-32
ffffffffc0205ece:	000b1717          	auipc	a4,0xb1
ffffffffc0205ed2:	e2f73523          	sd	a5,-470(a4) # ffffffffc02b6cf8 <proc_list+0x8>
ffffffffc0205ed6:	000b1717          	auipc	a4,0xb1
ffffffffc0205eda:	e0f73d23          	sd	a5,-486(a4) # ffffffffc02b6cf0 <proc_list>
ffffffffc0205ede:	ec06                	sd	ra,24(sp)
ffffffffc0205ee0:	e822                	sd	s0,16(sp)
ffffffffc0205ee2:	e426                	sd	s1,8(sp)
ffffffffc0205ee4:	000ad797          	auipc	a5,0xad
ffffffffc0205ee8:	c9478793          	addi	a5,a5,-876 # ffffffffc02b2b78 <hash_list>
ffffffffc0205eec:	000b1717          	auipc	a4,0xb1
ffffffffc0205ef0:	c8c70713          	addi	a4,a4,-884 # ffffffffc02b6b78 <is_panic>
ffffffffc0205ef4:	e79c                	sd	a5,8(a5)
ffffffffc0205ef6:	e39c                	sd	a5,0(a5)
ffffffffc0205ef8:	07c1                	addi	a5,a5,16
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
ffffffffc0205efa:	fee79de3          	bne	a5,a4,ffffffffc0205ef4 <proc_init+0x30>
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL) {
ffffffffc0205efe:	f4ffe0ef          	jal	ra,ffffffffc0204e4c <alloc_proc>
ffffffffc0205f02:	000b1717          	auipc	a4,0xb1
ffffffffc0205f06:	caa73b23          	sd	a0,-842(a4) # ffffffffc02b6bb8 <idleproc>
ffffffffc0205f0a:	000b1497          	auipc	s1,0xb1
ffffffffc0205f0e:	cae48493          	addi	s1,s1,-850 # ffffffffc02b6bb8 <idleproc>
ffffffffc0205f12:	c559                	beqz	a0,ffffffffc0205fa0 <proc_init+0xdc>
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0205f14:	4709                	li	a4,2
ffffffffc0205f16:	e118                	sd	a4,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
    idleproc->need_resched = 1;
ffffffffc0205f18:	4405                	li	s0,1
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205f1a:	00003717          	auipc	a4,0x3
ffffffffc0205f1e:	0e670713          	addi	a4,a4,230 # ffffffffc0209000 <bootstack>
    set_proc_name(idleproc, "idle");
ffffffffc0205f22:	00003597          	auipc	a1,0x3
ffffffffc0205f26:	9de58593          	addi	a1,a1,-1570 # ffffffffc0208900 <default_pmm_manager+0x1468>
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205f2a:	e918                	sd	a4,16(a0)
    idleproc->need_resched = 1;
ffffffffc0205f2c:	ed00                	sd	s0,24(a0)
    set_proc_name(idleproc, "idle");
ffffffffc0205f2e:	92eff0ef          	jal	ra,ffffffffc020505c <set_proc_name>
    nr_process ++;
ffffffffc0205f32:	000b1797          	auipc	a5,0xb1
ffffffffc0205f36:	c9678793          	addi	a5,a5,-874 # ffffffffc02b6bc8 <nr_process>
ffffffffc0205f3a:	439c                	lw	a5,0(a5)

    current = idleproc;
ffffffffc0205f3c:	6098                	ld	a4,0(s1)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205f3e:	4601                	li	a2,0
    nr_process ++;
ffffffffc0205f40:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205f42:	4581                	li	a1,0
ffffffffc0205f44:	00000517          	auipc	a0,0x0
ffffffffc0205f48:	8bc50513          	addi	a0,a0,-1860 # ffffffffc0205800 <init_main>
    nr_process ++;
ffffffffc0205f4c:	000b1697          	auipc	a3,0xb1
ffffffffc0205f50:	c6f6ae23          	sw	a5,-900(a3) # ffffffffc02b6bc8 <nr_process>
    current = idleproc;
ffffffffc0205f54:	000b1797          	auipc	a5,0xb1
ffffffffc0205f58:	c4e7be23          	sd	a4,-932(a5) # ffffffffc02b6bb0 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205f5c:	d5eff0ef          	jal	ra,ffffffffc02054ba <kernel_thread>
    if (pid <= 0) {
ffffffffc0205f60:	08a05c63          	blez	a0,ffffffffc0205ff8 <proc_init+0x134>
        panic("create init_main failed.\n");
    }
    //initproc的线程函数是init_main
    initproc = find_proc(pid);
ffffffffc0205f64:	990ff0ef          	jal	ra,ffffffffc02050f4 <find_proc>
    set_proc_name(initproc, "init");
ffffffffc0205f68:	00003597          	auipc	a1,0x3
ffffffffc0205f6c:	9c058593          	addi	a1,a1,-1600 # ffffffffc0208928 <default_pmm_manager+0x1490>
    initproc = find_proc(pid);
ffffffffc0205f70:	000b1797          	auipc	a5,0xb1
ffffffffc0205f74:	c4a7b823          	sd	a0,-944(a5) # ffffffffc02b6bc0 <initproc>
    set_proc_name(initproc, "init");
ffffffffc0205f78:	8e4ff0ef          	jal	ra,ffffffffc020505c <set_proc_name>

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205f7c:	609c                	ld	a5,0(s1)
ffffffffc0205f7e:	cfa9                	beqz	a5,ffffffffc0205fd8 <proc_init+0x114>
ffffffffc0205f80:	43dc                	lw	a5,4(a5)
ffffffffc0205f82:	ebb9                	bnez	a5,ffffffffc0205fd8 <proc_init+0x114>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205f84:	000b1797          	auipc	a5,0xb1
ffffffffc0205f88:	c3c78793          	addi	a5,a5,-964 # ffffffffc02b6bc0 <initproc>
ffffffffc0205f8c:	639c                	ld	a5,0(a5)
ffffffffc0205f8e:	c78d                	beqz	a5,ffffffffc0205fb8 <proc_init+0xf4>
ffffffffc0205f90:	43dc                	lw	a5,4(a5)
ffffffffc0205f92:	02879363          	bne	a5,s0,ffffffffc0205fb8 <proc_init+0xf4>
}
ffffffffc0205f96:	60e2                	ld	ra,24(sp)
ffffffffc0205f98:	6442                	ld	s0,16(sp)
ffffffffc0205f9a:	64a2                	ld	s1,8(sp)
ffffffffc0205f9c:	6105                	addi	sp,sp,32
ffffffffc0205f9e:	8082                	ret
        panic("cannot alloc idleproc.\n");
ffffffffc0205fa0:	00003617          	auipc	a2,0x3
ffffffffc0205fa4:	94860613          	addi	a2,a2,-1720 # ffffffffc02088e8 <default_pmm_manager+0x1450>
ffffffffc0205fa8:	3c300593          	li	a1,963
ffffffffc0205fac:	00003517          	auipc	a0,0x3
ffffffffc0205fb0:	a3c50513          	addi	a0,a0,-1476 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc0205fb4:	cd0fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205fb8:	00003697          	auipc	a3,0x3
ffffffffc0205fbc:	9a068693          	addi	a3,a3,-1632 # ffffffffc0208958 <default_pmm_manager+0x14c0>
ffffffffc0205fc0:	00001617          	auipc	a2,0x1
ffffffffc0205fc4:	d9060613          	addi	a2,a2,-624 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0205fc8:	3d800593          	li	a1,984
ffffffffc0205fcc:	00003517          	auipc	a0,0x3
ffffffffc0205fd0:	a1c50513          	addi	a0,a0,-1508 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc0205fd4:	cb0fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205fd8:	00003697          	auipc	a3,0x3
ffffffffc0205fdc:	95868693          	addi	a3,a3,-1704 # ffffffffc0208930 <default_pmm_manager+0x1498>
ffffffffc0205fe0:	00001617          	auipc	a2,0x1
ffffffffc0205fe4:	d7060613          	addi	a2,a2,-656 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0205fe8:	3d700593          	li	a1,983
ffffffffc0205fec:	00003517          	auipc	a0,0x3
ffffffffc0205ff0:	9fc50513          	addi	a0,a0,-1540 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc0205ff4:	c90fa0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("create init_main failed.\n");
ffffffffc0205ff8:	00003617          	auipc	a2,0x3
ffffffffc0205ffc:	91060613          	addi	a2,a2,-1776 # ffffffffc0208908 <default_pmm_manager+0x1470>
ffffffffc0206000:	3d100593          	li	a1,977
ffffffffc0206004:	00003517          	auipc	a0,0x3
ffffffffc0206008:	9e450513          	addi	a0,a0,-1564 # ffffffffc02089e8 <default_pmm_manager+0x1550>
ffffffffc020600c:	c78fa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0206010 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
ffffffffc0206010:	1141                	addi	sp,sp,-16
ffffffffc0206012:	e022                	sd	s0,0(sp)
ffffffffc0206014:	e406                	sd	ra,8(sp)
ffffffffc0206016:	000b1417          	auipc	s0,0xb1
ffffffffc020601a:	b9a40413          	addi	s0,s0,-1126 # ffffffffc02b6bb0 <current>
    while (1) {
        if (current->need_resched) {
ffffffffc020601e:	6018                	ld	a4,0(s0)
ffffffffc0206020:	6f1c                	ld	a5,24(a4)
ffffffffc0206022:	dffd                	beqz	a5,ffffffffc0206020 <cpu_idle+0x10>
            schedule();
ffffffffc0206024:	0ec000ef          	jal	ra,ffffffffc0206110 <schedule>
ffffffffc0206028:	bfdd                	j	ffffffffc020601e <cpu_idle+0xe>

ffffffffc020602a <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc020602a:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc020602e:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0206032:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0206034:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0206036:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc020603a:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc020603e:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0206042:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0206046:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc020604a:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc020604e:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0206052:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0206056:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc020605a:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc020605e:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0206062:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0206066:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0206068:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc020606a:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc020606e:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0206072:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0206076:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc020607a:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc020607e:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0206082:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0206086:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc020608a:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc020608e:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0206092:	8082                	ret

ffffffffc0206094 <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0206094:	4118                	lw	a4,0(a0)
wakeup_proc(struct proc_struct *proc) {
ffffffffc0206096:	1101                	addi	sp,sp,-32
ffffffffc0206098:	ec06                	sd	ra,24(sp)
ffffffffc020609a:	e822                	sd	s0,16(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020609c:	478d                	li	a5,3
ffffffffc020609e:	04f70a63          	beq	a4,a5,ffffffffc02060f2 <wakeup_proc+0x5e>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02060a2:	100027f3          	csrr	a5,sstatus
ffffffffc02060a6:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02060a8:	4401                	li	s0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02060aa:	ef8d                	bnez	a5,ffffffffc02060e4 <wakeup_proc+0x50>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE) {
ffffffffc02060ac:	4789                	li	a5,2
ffffffffc02060ae:	00f70f63          	beq	a4,a5,ffffffffc02060cc <wakeup_proc+0x38>
            proc->state = PROC_RUNNABLE;
ffffffffc02060b2:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc02060b4:	0e052623          	sw	zero,236(a0)
    if (flag) {
ffffffffc02060b8:	e409                	bnez	s0,ffffffffc02060c2 <wakeup_proc+0x2e>
        else {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc02060ba:	60e2                	ld	ra,24(sp)
ffffffffc02060bc:	6442                	ld	s0,16(sp)
ffffffffc02060be:	6105                	addi	sp,sp,32
ffffffffc02060c0:	8082                	ret
ffffffffc02060c2:	6442                	ld	s0,16(sp)
ffffffffc02060c4:	60e2                	ld	ra,24(sp)
ffffffffc02060c6:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02060c8:	d8cfa06f          	j	ffffffffc0200654 <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc02060cc:	00003617          	auipc	a2,0x3
ffffffffc02060d0:	96c60613          	addi	a2,a2,-1684 # ffffffffc0208a38 <default_pmm_manager+0x15a0>
ffffffffc02060d4:	45c9                	li	a1,18
ffffffffc02060d6:	00003517          	auipc	a0,0x3
ffffffffc02060da:	94a50513          	addi	a0,a0,-1718 # ffffffffc0208a20 <default_pmm_manager+0x1588>
ffffffffc02060de:	c12fa0ef          	jal	ra,ffffffffc02004f0 <__warn>
ffffffffc02060e2:	bfd9                	j	ffffffffc02060b8 <wakeup_proc+0x24>
ffffffffc02060e4:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02060e6:	d74fa0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc02060ea:	6522                	ld	a0,8(sp)
ffffffffc02060ec:	4405                	li	s0,1
ffffffffc02060ee:	4118                	lw	a4,0(a0)
ffffffffc02060f0:	bf75                	j	ffffffffc02060ac <wakeup_proc+0x18>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02060f2:	00003697          	auipc	a3,0x3
ffffffffc02060f6:	90e68693          	addi	a3,a3,-1778 # ffffffffc0208a00 <default_pmm_manager+0x1568>
ffffffffc02060fa:	00001617          	auipc	a2,0x1
ffffffffc02060fe:	c5660613          	addi	a2,a2,-938 # ffffffffc0206d50 <commands+0x4c0>
ffffffffc0206102:	45a5                	li	a1,9
ffffffffc0206104:	00003517          	auipc	a0,0x3
ffffffffc0206108:	91c50513          	addi	a0,a0,-1764 # ffffffffc0208a20 <default_pmm_manager+0x1588>
ffffffffc020610c:	b78fa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0206110 <schedule>:

void
schedule(void) {
ffffffffc0206110:	1141                	addi	sp,sp,-16
ffffffffc0206112:	e406                	sd	ra,8(sp)
ffffffffc0206114:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0206116:	100027f3          	csrr	a5,sstatus
ffffffffc020611a:	8b89                	andi	a5,a5,2
ffffffffc020611c:	4401                	li	s0,0
ffffffffc020611e:	e3d1                	bnez	a5,ffffffffc02061a2 <schedule+0x92>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0206120:	000b1797          	auipc	a5,0xb1
ffffffffc0206124:	a9078793          	addi	a5,a5,-1392 # ffffffffc02b6bb0 <current>
ffffffffc0206128:	0007b883          	ld	a7,0(a5)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020612c:	000b1797          	auipc	a5,0xb1
ffffffffc0206130:	a8c78793          	addi	a5,a5,-1396 # ffffffffc02b6bb8 <idleproc>
ffffffffc0206134:	6388                	ld	a0,0(a5)
        current->need_resched = 0;
ffffffffc0206136:	0008bc23          	sd	zero,24(a7) # 2018 <_binary_obj___user_faultread_out_size-0x7568>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc020613a:	04a88e63          	beq	a7,a0,ffffffffc0206196 <schedule+0x86>
ffffffffc020613e:	0c888693          	addi	a3,a7,200
ffffffffc0206142:	000b1617          	auipc	a2,0xb1
ffffffffc0206146:	bae60613          	addi	a2,a2,-1106 # ffffffffc02b6cf0 <proc_list>
        le = last;
ffffffffc020614a:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc020614c:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc020614e:	4809                	li	a6,2
    return listelm->next;
ffffffffc0206150:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc0206152:	00c78863          	beq	a5,a2,ffffffffc0206162 <schedule+0x52>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0206156:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc020615a:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc020615e:	01070463          	beq	a4,a6,ffffffffc0206166 <schedule+0x56>
                    break;
                }
            }
        } while (le != last);
ffffffffc0206162:	fef697e3          	bne	a3,a5,ffffffffc0206150 <schedule+0x40>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0206166:	c589                	beqz	a1,ffffffffc0206170 <schedule+0x60>
ffffffffc0206168:	4198                	lw	a4,0(a1)
ffffffffc020616a:	4789                	li	a5,2
ffffffffc020616c:	00f70e63          	beq	a4,a5,ffffffffc0206188 <schedule+0x78>
            next = idleproc;
        }
        next->runs ++;
ffffffffc0206170:	451c                	lw	a5,8(a0)
ffffffffc0206172:	2785                	addiw	a5,a5,1
ffffffffc0206174:	c51c                	sw	a5,8(a0)
        if (next != current) {
ffffffffc0206176:	00a88463          	beq	a7,a0,ffffffffc020617e <schedule+0x6e>
            proc_run(next);
ffffffffc020617a:	f0dfe0ef          	jal	ra,ffffffffc0205086 <proc_run>
    if (flag) {
ffffffffc020617e:	e419                	bnez	s0,ffffffffc020618c <schedule+0x7c>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0206180:	60a2                	ld	ra,8(sp)
ffffffffc0206182:	6402                	ld	s0,0(sp)
ffffffffc0206184:	0141                	addi	sp,sp,16
ffffffffc0206186:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0206188:	852e                	mv	a0,a1
ffffffffc020618a:	b7dd                	j	ffffffffc0206170 <schedule+0x60>
}
ffffffffc020618c:	6402                	ld	s0,0(sp)
ffffffffc020618e:	60a2                	ld	ra,8(sp)
ffffffffc0206190:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc0206192:	cc2fa06f          	j	ffffffffc0200654 <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0206196:	000b1617          	auipc	a2,0xb1
ffffffffc020619a:	b5a60613          	addi	a2,a2,-1190 # ffffffffc02b6cf0 <proc_list>
ffffffffc020619e:	86b2                	mv	a3,a2
ffffffffc02061a0:	b76d                	j	ffffffffc020614a <schedule+0x3a>
        intr_disable();
ffffffffc02061a2:	cb8fa0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc02061a6:	4405                	li	s0,1
ffffffffc02061a8:	bfa5                	j	ffffffffc0206120 <schedule+0x10>

ffffffffc02061aa <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc02061aa:	000b1797          	auipc	a5,0xb1
ffffffffc02061ae:	a0678793          	addi	a5,a5,-1530 # ffffffffc02b6bb0 <current>
ffffffffc02061b2:	639c                	ld	a5,0(a5)
}
ffffffffc02061b4:	43c8                	lw	a0,4(a5)
ffffffffc02061b6:	8082                	ret

ffffffffc02061b8 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc02061b8:	4501                	li	a0,0
ffffffffc02061ba:	8082                	ret

ffffffffc02061bc <sys_putc>:
    cputchar(c);
ffffffffc02061bc:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc02061be:	1141                	addi	sp,sp,-16
ffffffffc02061c0:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc02061c2:	800fa0ef          	jal	ra,ffffffffc02001c2 <cputchar>
}
ffffffffc02061c6:	60a2                	ld	ra,8(sp)
ffffffffc02061c8:	4501                	li	a0,0
ffffffffc02061ca:	0141                	addi	sp,sp,16
ffffffffc02061cc:	8082                	ret

ffffffffc02061ce <sys_kill>:
    return do_kill(pid);
ffffffffc02061ce:	4108                	lw	a0,0(a0)
ffffffffc02061d0:	cadff06f          	j	ffffffffc0205e7c <do_kill>

ffffffffc02061d4 <sys_yield>:
    return do_yield();
ffffffffc02061d4:	c57ff06f          	j	ffffffffc0205e2a <do_yield>

ffffffffc02061d8 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02061d8:	6d14                	ld	a3,24(a0)
ffffffffc02061da:	6910                	ld	a2,16(a0)
ffffffffc02061dc:	650c                	ld	a1,8(a0)
ffffffffc02061de:	6108                	ld	a0,0(a0)
ffffffffc02061e0:	f48ff06f          	j	ffffffffc0205928 <do_execve>

ffffffffc02061e4 <sys_wait>:
    return do_wait(pid, store);
ffffffffc02061e4:	650c                	ld	a1,8(a0)
ffffffffc02061e6:	4108                	lw	a0,0(a0)
ffffffffc02061e8:	c55ff06f          	j	ffffffffc0205e3c <do_wait>

ffffffffc02061ec <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02061ec:	000b1797          	auipc	a5,0xb1
ffffffffc02061f0:	9c478793          	addi	a5,a5,-1596 # ffffffffc02b6bb0 <current>
ffffffffc02061f4:	639c                	ld	a5,0(a5)
    return do_fork(0, stack, tf);
ffffffffc02061f6:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc02061f8:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02061fa:	6a0c                	ld	a1,16(a2)
ffffffffc02061fc:	f55fe06f          	j	ffffffffc0205150 <do_fork>

ffffffffc0206200 <sys_exit>:
    return do_exit(error_code);
ffffffffc0206200:	4108                	lw	a0,0(a0)
ffffffffc0206202:	b08ff06f          	j	ffffffffc020550a <do_exit>

ffffffffc0206206 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc0206206:	715d                	addi	sp,sp,-80
ffffffffc0206208:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc020620a:	000b1497          	auipc	s1,0xb1
ffffffffc020620e:	9a648493          	addi	s1,s1,-1626 # ffffffffc02b6bb0 <current>
ffffffffc0206212:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc0206214:	e0a2                	sd	s0,64(sp)
ffffffffc0206216:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc0206218:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc020621a:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    //a0是sys_exec
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc020621c:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc020621e:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc0206222:	0327ee63          	bltu	a5,s2,ffffffffc020625e <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc0206226:	00391713          	slli	a4,s2,0x3
ffffffffc020622a:	00003797          	auipc	a5,0x3
ffffffffc020622e:	87678793          	addi	a5,a5,-1930 # ffffffffc0208aa0 <syscalls>
ffffffffc0206232:	97ba                	add	a5,a5,a4
ffffffffc0206234:	639c                	ld	a5,0(a5)
ffffffffc0206236:	c785                	beqz	a5,ffffffffc020625e <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc0206238:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc020623a:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc020623c:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc020623e:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc0206240:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc0206242:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc0206244:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc0206246:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0206248:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc020624a:	f43a                	sd	a4,40(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020624c:	0028                	addi	a0,sp,8
ffffffffc020624e:	9782                	jalr	a5
ffffffffc0206250:	e828                	sd	a0,80(s0)
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc0206252:	60a6                	ld	ra,72(sp)
ffffffffc0206254:	6406                	ld	s0,64(sp)
ffffffffc0206256:	74e2                	ld	s1,56(sp)
ffffffffc0206258:	7942                	ld	s2,48(sp)
ffffffffc020625a:	6161                	addi	sp,sp,80
ffffffffc020625c:	8082                	ret
    print_trapframe(tf);
ffffffffc020625e:	8522                	mv	a0,s0
ffffffffc0206260:	deafa0ef          	jal	ra,ffffffffc020084a <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0206264:	609c                	ld	a5,0(s1)
ffffffffc0206266:	86ca                	mv	a3,s2
ffffffffc0206268:	00002617          	auipc	a2,0x2
ffffffffc020626c:	7f060613          	addi	a2,a2,2032 # ffffffffc0208a58 <default_pmm_manager+0x15c0>
ffffffffc0206270:	43d8                	lw	a4,4(a5)
ffffffffc0206272:	06500593          	li	a1,101
ffffffffc0206276:	0b478793          	addi	a5,a5,180
ffffffffc020627a:	00003517          	auipc	a0,0x3
ffffffffc020627e:	80e50513          	addi	a0,a0,-2034 # ffffffffc0208a88 <default_pmm_manager+0x15f0>
ffffffffc0206282:	a02fa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0206286 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0206286:	9e3707b7          	lui	a5,0x9e370
ffffffffc020628a:	2785                	addiw	a5,a5,1
ffffffffc020628c:	02f5053b          	mulw	a0,a0,a5
    return (hash >> (32 - bits));
ffffffffc0206290:	02000793          	li	a5,32
ffffffffc0206294:	40b785bb          	subw	a1,a5,a1
}
ffffffffc0206298:	00b5553b          	srlw	a0,a0,a1
ffffffffc020629c:	8082                	ret

ffffffffc020629e <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020629e:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02062a2:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02062a4:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02062a8:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02062aa:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02062ae:	f022                	sd	s0,32(sp)
ffffffffc02062b0:	ec26                	sd	s1,24(sp)
ffffffffc02062b2:	e84a                	sd	s2,16(sp)
ffffffffc02062b4:	f406                	sd	ra,40(sp)
ffffffffc02062b6:	e44e                	sd	s3,8(sp)
ffffffffc02062b8:	84aa                	mv	s1,a0
ffffffffc02062ba:	892e                	mv	s2,a1
ffffffffc02062bc:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02062c0:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc02062c2:	03067e63          	bleu	a6,a2,ffffffffc02062fe <printnum+0x60>
ffffffffc02062c6:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02062c8:	00805763          	blez	s0,ffffffffc02062d6 <printnum+0x38>
ffffffffc02062cc:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02062ce:	85ca                	mv	a1,s2
ffffffffc02062d0:	854e                	mv	a0,s3
ffffffffc02062d2:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02062d4:	fc65                	bnez	s0,ffffffffc02062cc <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02062d6:	1a02                	slli	s4,s4,0x20
ffffffffc02062d8:	020a5a13          	srli	s4,s4,0x20
ffffffffc02062dc:	00003797          	auipc	a5,0x3
ffffffffc02062e0:	ae478793          	addi	a5,a5,-1308 # ffffffffc0208dc0 <error_string+0xc8>
ffffffffc02062e4:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02062e6:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02062e8:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02062ec:	70a2                	ld	ra,40(sp)
ffffffffc02062ee:	69a2                	ld	s3,8(sp)
ffffffffc02062f0:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02062f2:	85ca                	mv	a1,s2
ffffffffc02062f4:	8326                	mv	t1,s1
}
ffffffffc02062f6:	6942                	ld	s2,16(sp)
ffffffffc02062f8:	64e2                	ld	s1,24(sp)
ffffffffc02062fa:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02062fc:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02062fe:	03065633          	divu	a2,a2,a6
ffffffffc0206302:	8722                	mv	a4,s0
ffffffffc0206304:	f9bff0ef          	jal	ra,ffffffffc020629e <printnum>
ffffffffc0206308:	b7f9                	j	ffffffffc02062d6 <printnum+0x38>

ffffffffc020630a <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020630a:	7119                	addi	sp,sp,-128
ffffffffc020630c:	f4a6                	sd	s1,104(sp)
ffffffffc020630e:	f0ca                	sd	s2,96(sp)
ffffffffc0206310:	e8d2                	sd	s4,80(sp)
ffffffffc0206312:	e4d6                	sd	s5,72(sp)
ffffffffc0206314:	e0da                	sd	s6,64(sp)
ffffffffc0206316:	fc5e                	sd	s7,56(sp)
ffffffffc0206318:	f862                	sd	s8,48(sp)
ffffffffc020631a:	f06a                	sd	s10,32(sp)
ffffffffc020631c:	fc86                	sd	ra,120(sp)
ffffffffc020631e:	f8a2                	sd	s0,112(sp)
ffffffffc0206320:	ecce                	sd	s3,88(sp)
ffffffffc0206322:	f466                	sd	s9,40(sp)
ffffffffc0206324:	ec6e                	sd	s11,24(sp)
ffffffffc0206326:	892a                	mv	s2,a0
ffffffffc0206328:	84ae                	mv	s1,a1
ffffffffc020632a:	8d32                	mv	s10,a2
ffffffffc020632c:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc020632e:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206330:	00003a17          	auipc	s4,0x3
ffffffffc0206334:	870a0a13          	addi	s4,s4,-1936 # ffffffffc0208ba0 <syscalls+0x100>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206338:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020633c:	00003c17          	auipc	s8,0x3
ffffffffc0206340:	9bcc0c13          	addi	s8,s8,-1604 # ffffffffc0208cf8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206344:	000d4503          	lbu	a0,0(s10)
ffffffffc0206348:	02500793          	li	a5,37
ffffffffc020634c:	001d0413          	addi	s0,s10,1
ffffffffc0206350:	00f50e63          	beq	a0,a5,ffffffffc020636c <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc0206354:	c521                	beqz	a0,ffffffffc020639c <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206356:	02500993          	li	s3,37
ffffffffc020635a:	a011                	j	ffffffffc020635e <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc020635c:	c121                	beqz	a0,ffffffffc020639c <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc020635e:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206360:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0206362:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206364:	fff44503          	lbu	a0,-1(s0)
ffffffffc0206368:	ff351ae3          	bne	a0,s3,ffffffffc020635c <vprintfmt+0x52>
ffffffffc020636c:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0206370:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0206374:	4981                	li	s3,0
ffffffffc0206376:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0206378:	5cfd                	li	s9,-1
ffffffffc020637a:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020637c:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0206380:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206382:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0206386:	0ff6f693          	andi	a3,a3,255
ffffffffc020638a:	00140d13          	addi	s10,s0,1
ffffffffc020638e:	20d5e563          	bltu	a1,a3,ffffffffc0206598 <vprintfmt+0x28e>
ffffffffc0206392:	068a                	slli	a3,a3,0x2
ffffffffc0206394:	96d2                	add	a3,a3,s4
ffffffffc0206396:	4294                	lw	a3,0(a3)
ffffffffc0206398:	96d2                	add	a3,a3,s4
ffffffffc020639a:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020639c:	70e6                	ld	ra,120(sp)
ffffffffc020639e:	7446                	ld	s0,112(sp)
ffffffffc02063a0:	74a6                	ld	s1,104(sp)
ffffffffc02063a2:	7906                	ld	s2,96(sp)
ffffffffc02063a4:	69e6                	ld	s3,88(sp)
ffffffffc02063a6:	6a46                	ld	s4,80(sp)
ffffffffc02063a8:	6aa6                	ld	s5,72(sp)
ffffffffc02063aa:	6b06                	ld	s6,64(sp)
ffffffffc02063ac:	7be2                	ld	s7,56(sp)
ffffffffc02063ae:	7c42                	ld	s8,48(sp)
ffffffffc02063b0:	7ca2                	ld	s9,40(sp)
ffffffffc02063b2:	7d02                	ld	s10,32(sp)
ffffffffc02063b4:	6de2                	ld	s11,24(sp)
ffffffffc02063b6:	6109                	addi	sp,sp,128
ffffffffc02063b8:	8082                	ret
    if (lflag >= 2) {
ffffffffc02063ba:	4705                	li	a4,1
ffffffffc02063bc:	008a8593          	addi	a1,s5,8
ffffffffc02063c0:	01074463          	blt	a4,a6,ffffffffc02063c8 <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc02063c4:	26080363          	beqz	a6,ffffffffc020662a <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc02063c8:	000ab603          	ld	a2,0(s5)
ffffffffc02063cc:	46c1                	li	a3,16
ffffffffc02063ce:	8aae                	mv	s5,a1
ffffffffc02063d0:	a06d                	j	ffffffffc020647a <vprintfmt+0x170>
            goto reswitch;
ffffffffc02063d2:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02063d6:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063d8:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02063da:	b765                	j	ffffffffc0206382 <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc02063dc:	000aa503          	lw	a0,0(s5)
ffffffffc02063e0:	85a6                	mv	a1,s1
ffffffffc02063e2:	0aa1                	addi	s5,s5,8
ffffffffc02063e4:	9902                	jalr	s2
            break;
ffffffffc02063e6:	bfb9                	j	ffffffffc0206344 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02063e8:	4705                	li	a4,1
ffffffffc02063ea:	008a8993          	addi	s3,s5,8
ffffffffc02063ee:	01074463          	blt	a4,a6,ffffffffc02063f6 <vprintfmt+0xec>
    else if (lflag) {
ffffffffc02063f2:	22080463          	beqz	a6,ffffffffc020661a <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc02063f6:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc02063fa:	24044463          	bltz	s0,ffffffffc0206642 <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc02063fe:	8622                	mv	a2,s0
ffffffffc0206400:	8ace                	mv	s5,s3
ffffffffc0206402:	46a9                	li	a3,10
ffffffffc0206404:	a89d                	j	ffffffffc020647a <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc0206406:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020640a:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc020640c:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc020640e:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0206412:	8fb5                	xor	a5,a5,a3
ffffffffc0206414:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0206418:	1ad74363          	blt	a4,a3,ffffffffc02065be <vprintfmt+0x2b4>
ffffffffc020641c:	00369793          	slli	a5,a3,0x3
ffffffffc0206420:	97e2                	add	a5,a5,s8
ffffffffc0206422:	639c                	ld	a5,0(a5)
ffffffffc0206424:	18078d63          	beqz	a5,ffffffffc02065be <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc0206428:	86be                	mv	a3,a5
ffffffffc020642a:	00000617          	auipc	a2,0x0
ffffffffc020642e:	35e60613          	addi	a2,a2,862 # ffffffffc0206788 <etext+0x2a>
ffffffffc0206432:	85a6                	mv	a1,s1
ffffffffc0206434:	854a                	mv	a0,s2
ffffffffc0206436:	240000ef          	jal	ra,ffffffffc0206676 <printfmt>
ffffffffc020643a:	b729                	j	ffffffffc0206344 <vprintfmt+0x3a>
            lflag ++;
ffffffffc020643c:	00144603          	lbu	a2,1(s0)
ffffffffc0206440:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206442:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0206444:	bf3d                	j	ffffffffc0206382 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc0206446:	4705                	li	a4,1
ffffffffc0206448:	008a8593          	addi	a1,s5,8
ffffffffc020644c:	01074463          	blt	a4,a6,ffffffffc0206454 <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc0206450:	1e080263          	beqz	a6,ffffffffc0206634 <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc0206454:	000ab603          	ld	a2,0(s5)
ffffffffc0206458:	46a1                	li	a3,8
ffffffffc020645a:	8aae                	mv	s5,a1
ffffffffc020645c:	a839                	j	ffffffffc020647a <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc020645e:	03000513          	li	a0,48
ffffffffc0206462:	85a6                	mv	a1,s1
ffffffffc0206464:	e03e                	sd	a5,0(sp)
ffffffffc0206466:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0206468:	85a6                	mv	a1,s1
ffffffffc020646a:	07800513          	li	a0,120
ffffffffc020646e:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0206470:	0aa1                	addi	s5,s5,8
ffffffffc0206472:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc0206476:	6782                	ld	a5,0(sp)
ffffffffc0206478:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc020647a:	876e                	mv	a4,s11
ffffffffc020647c:	85a6                	mv	a1,s1
ffffffffc020647e:	854a                	mv	a0,s2
ffffffffc0206480:	e1fff0ef          	jal	ra,ffffffffc020629e <printnum>
            break;
ffffffffc0206484:	b5c1                	j	ffffffffc0206344 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0206486:	000ab603          	ld	a2,0(s5)
ffffffffc020648a:	0aa1                	addi	s5,s5,8
ffffffffc020648c:	1c060663          	beqz	a2,ffffffffc0206658 <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc0206490:	00160413          	addi	s0,a2,1
ffffffffc0206494:	17b05c63          	blez	s11,ffffffffc020660c <vprintfmt+0x302>
ffffffffc0206498:	02d00593          	li	a1,45
ffffffffc020649c:	14b79263          	bne	a5,a1,ffffffffc02065e0 <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02064a0:	00064783          	lbu	a5,0(a2)
ffffffffc02064a4:	0007851b          	sext.w	a0,a5
ffffffffc02064a8:	c905                	beqz	a0,ffffffffc02064d8 <vprintfmt+0x1ce>
ffffffffc02064aa:	000cc563          	bltz	s9,ffffffffc02064b4 <vprintfmt+0x1aa>
ffffffffc02064ae:	3cfd                	addiw	s9,s9,-1
ffffffffc02064b0:	036c8263          	beq	s9,s6,ffffffffc02064d4 <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc02064b4:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02064b6:	18098463          	beqz	s3,ffffffffc020663e <vprintfmt+0x334>
ffffffffc02064ba:	3781                	addiw	a5,a5,-32
ffffffffc02064bc:	18fbf163          	bleu	a5,s7,ffffffffc020663e <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc02064c0:	03f00513          	li	a0,63
ffffffffc02064c4:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02064c6:	0405                	addi	s0,s0,1
ffffffffc02064c8:	fff44783          	lbu	a5,-1(s0)
ffffffffc02064cc:	3dfd                	addiw	s11,s11,-1
ffffffffc02064ce:	0007851b          	sext.w	a0,a5
ffffffffc02064d2:	fd61                	bnez	a0,ffffffffc02064aa <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc02064d4:	e7b058e3          	blez	s11,ffffffffc0206344 <vprintfmt+0x3a>
ffffffffc02064d8:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02064da:	85a6                	mv	a1,s1
ffffffffc02064dc:	02000513          	li	a0,32
ffffffffc02064e0:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02064e2:	e60d81e3          	beqz	s11,ffffffffc0206344 <vprintfmt+0x3a>
ffffffffc02064e6:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02064e8:	85a6                	mv	a1,s1
ffffffffc02064ea:	02000513          	li	a0,32
ffffffffc02064ee:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02064f0:	fe0d94e3          	bnez	s11,ffffffffc02064d8 <vprintfmt+0x1ce>
ffffffffc02064f4:	bd81                	j	ffffffffc0206344 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02064f6:	4705                	li	a4,1
ffffffffc02064f8:	008a8593          	addi	a1,s5,8
ffffffffc02064fc:	01074463          	blt	a4,a6,ffffffffc0206504 <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc0206500:	12080063          	beqz	a6,ffffffffc0206620 <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc0206504:	000ab603          	ld	a2,0(s5)
ffffffffc0206508:	46a9                	li	a3,10
ffffffffc020650a:	8aae                	mv	s5,a1
ffffffffc020650c:	b7bd                	j	ffffffffc020647a <vprintfmt+0x170>
ffffffffc020650e:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc0206512:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206516:	846a                	mv	s0,s10
ffffffffc0206518:	b5ad                	j	ffffffffc0206382 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc020651a:	85a6                	mv	a1,s1
ffffffffc020651c:	02500513          	li	a0,37
ffffffffc0206520:	9902                	jalr	s2
            break;
ffffffffc0206522:	b50d                	j	ffffffffc0206344 <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc0206524:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc0206528:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020652c:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020652e:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc0206530:	e40dd9e3          	bgez	s11,ffffffffc0206382 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc0206534:	8de6                	mv	s11,s9
ffffffffc0206536:	5cfd                	li	s9,-1
ffffffffc0206538:	b5a9                	j	ffffffffc0206382 <vprintfmt+0x78>
            goto reswitch;
ffffffffc020653a:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc020653e:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206542:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0206544:	bd3d                	j	ffffffffc0206382 <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc0206546:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc020654a:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020654e:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0206550:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0206554:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0206558:	fcd56ce3          	bltu	a0,a3,ffffffffc0206530 <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc020655c:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc020655e:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc0206562:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0206566:	0196873b          	addw	a4,a3,s9
ffffffffc020656a:	0017171b          	slliw	a4,a4,0x1
ffffffffc020656e:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0206572:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc0206576:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc020657a:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc020657e:	fcd57fe3          	bleu	a3,a0,ffffffffc020655c <vprintfmt+0x252>
ffffffffc0206582:	b77d                	j	ffffffffc0206530 <vprintfmt+0x226>
            if (width < 0)
ffffffffc0206584:	fffdc693          	not	a3,s11
ffffffffc0206588:	96fd                	srai	a3,a3,0x3f
ffffffffc020658a:	00ddfdb3          	and	s11,s11,a3
ffffffffc020658e:	00144603          	lbu	a2,1(s0)
ffffffffc0206592:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206594:	846a                	mv	s0,s10
ffffffffc0206596:	b3f5                	j	ffffffffc0206382 <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc0206598:	85a6                	mv	a1,s1
ffffffffc020659a:	02500513          	li	a0,37
ffffffffc020659e:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02065a0:	fff44703          	lbu	a4,-1(s0)
ffffffffc02065a4:	02500793          	li	a5,37
ffffffffc02065a8:	8d22                	mv	s10,s0
ffffffffc02065aa:	d8f70de3          	beq	a4,a5,ffffffffc0206344 <vprintfmt+0x3a>
ffffffffc02065ae:	02500713          	li	a4,37
ffffffffc02065b2:	1d7d                	addi	s10,s10,-1
ffffffffc02065b4:	fffd4783          	lbu	a5,-1(s10)
ffffffffc02065b8:	fee79de3          	bne	a5,a4,ffffffffc02065b2 <vprintfmt+0x2a8>
ffffffffc02065bc:	b361                	j	ffffffffc0206344 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02065be:	00003617          	auipc	a2,0x3
ffffffffc02065c2:	8e260613          	addi	a2,a2,-1822 # ffffffffc0208ea0 <error_string+0x1a8>
ffffffffc02065c6:	85a6                	mv	a1,s1
ffffffffc02065c8:	854a                	mv	a0,s2
ffffffffc02065ca:	0ac000ef          	jal	ra,ffffffffc0206676 <printfmt>
ffffffffc02065ce:	bb9d                	j	ffffffffc0206344 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02065d0:	00003617          	auipc	a2,0x3
ffffffffc02065d4:	8c860613          	addi	a2,a2,-1848 # ffffffffc0208e98 <error_string+0x1a0>
            if (width > 0 && padc != '-') {
ffffffffc02065d8:	00003417          	auipc	s0,0x3
ffffffffc02065dc:	8c140413          	addi	s0,s0,-1855 # ffffffffc0208e99 <error_string+0x1a1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02065e0:	8532                	mv	a0,a2
ffffffffc02065e2:	85e6                	mv	a1,s9
ffffffffc02065e4:	e032                	sd	a2,0(sp)
ffffffffc02065e6:	e43e                	sd	a5,8(sp)
ffffffffc02065e8:	0cc000ef          	jal	ra,ffffffffc02066b4 <strnlen>
ffffffffc02065ec:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02065f0:	6602                	ld	a2,0(sp)
ffffffffc02065f2:	01b05d63          	blez	s11,ffffffffc020660c <vprintfmt+0x302>
ffffffffc02065f6:	67a2                	ld	a5,8(sp)
ffffffffc02065f8:	2781                	sext.w	a5,a5
ffffffffc02065fa:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc02065fc:	6522                	ld	a0,8(sp)
ffffffffc02065fe:	85a6                	mv	a1,s1
ffffffffc0206600:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206602:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0206604:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0206606:	6602                	ld	a2,0(sp)
ffffffffc0206608:	fe0d9ae3          	bnez	s11,ffffffffc02065fc <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020660c:	00064783          	lbu	a5,0(a2)
ffffffffc0206610:	0007851b          	sext.w	a0,a5
ffffffffc0206614:	e8051be3          	bnez	a0,ffffffffc02064aa <vprintfmt+0x1a0>
ffffffffc0206618:	b335                	j	ffffffffc0206344 <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc020661a:	000aa403          	lw	s0,0(s5)
ffffffffc020661e:	bbf1                	j	ffffffffc02063fa <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc0206620:	000ae603          	lwu	a2,0(s5)
ffffffffc0206624:	46a9                	li	a3,10
ffffffffc0206626:	8aae                	mv	s5,a1
ffffffffc0206628:	bd89                	j	ffffffffc020647a <vprintfmt+0x170>
ffffffffc020662a:	000ae603          	lwu	a2,0(s5)
ffffffffc020662e:	46c1                	li	a3,16
ffffffffc0206630:	8aae                	mv	s5,a1
ffffffffc0206632:	b5a1                	j	ffffffffc020647a <vprintfmt+0x170>
ffffffffc0206634:	000ae603          	lwu	a2,0(s5)
ffffffffc0206638:	46a1                	li	a3,8
ffffffffc020663a:	8aae                	mv	s5,a1
ffffffffc020663c:	bd3d                	j	ffffffffc020647a <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc020663e:	9902                	jalr	s2
ffffffffc0206640:	b559                	j	ffffffffc02064c6 <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc0206642:	85a6                	mv	a1,s1
ffffffffc0206644:	02d00513          	li	a0,45
ffffffffc0206648:	e03e                	sd	a5,0(sp)
ffffffffc020664a:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020664c:	8ace                	mv	s5,s3
ffffffffc020664e:	40800633          	neg	a2,s0
ffffffffc0206652:	46a9                	li	a3,10
ffffffffc0206654:	6782                	ld	a5,0(sp)
ffffffffc0206656:	b515                	j	ffffffffc020647a <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc0206658:	01b05663          	blez	s11,ffffffffc0206664 <vprintfmt+0x35a>
ffffffffc020665c:	02d00693          	li	a3,45
ffffffffc0206660:	f6d798e3          	bne	a5,a3,ffffffffc02065d0 <vprintfmt+0x2c6>
ffffffffc0206664:	00003417          	auipc	s0,0x3
ffffffffc0206668:	83540413          	addi	s0,s0,-1995 # ffffffffc0208e99 <error_string+0x1a1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020666c:	02800513          	li	a0,40
ffffffffc0206670:	02800793          	li	a5,40
ffffffffc0206674:	bd1d                	j	ffffffffc02064aa <vprintfmt+0x1a0>

ffffffffc0206676 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0206676:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0206678:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020667c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020667e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0206680:	ec06                	sd	ra,24(sp)
ffffffffc0206682:	f83a                	sd	a4,48(sp)
ffffffffc0206684:	fc3e                	sd	a5,56(sp)
ffffffffc0206686:	e0c2                	sd	a6,64(sp)
ffffffffc0206688:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020668a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020668c:	c7fff0ef          	jal	ra,ffffffffc020630a <vprintfmt>
}
ffffffffc0206690:	60e2                	ld	ra,24(sp)
ffffffffc0206692:	6161                	addi	sp,sp,80
ffffffffc0206694:	8082                	ret

ffffffffc0206696 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0206696:	00054783          	lbu	a5,0(a0)
ffffffffc020669a:	cb91                	beqz	a5,ffffffffc02066ae <strlen+0x18>
    size_t cnt = 0;
ffffffffc020669c:	4781                	li	a5,0
        cnt ++;
ffffffffc020669e:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc02066a0:	00f50733          	add	a4,a0,a5
ffffffffc02066a4:	00074703          	lbu	a4,0(a4)
ffffffffc02066a8:	fb7d                	bnez	a4,ffffffffc020669e <strlen+0x8>
    }
    return cnt;
}
ffffffffc02066aa:	853e                	mv	a0,a5
ffffffffc02066ac:	8082                	ret
    size_t cnt = 0;
ffffffffc02066ae:	4781                	li	a5,0
}
ffffffffc02066b0:	853e                	mv	a0,a5
ffffffffc02066b2:	8082                	ret

ffffffffc02066b4 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc02066b4:	c185                	beqz	a1,ffffffffc02066d4 <strnlen+0x20>
ffffffffc02066b6:	00054783          	lbu	a5,0(a0)
ffffffffc02066ba:	cf89                	beqz	a5,ffffffffc02066d4 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc02066bc:	4781                	li	a5,0
ffffffffc02066be:	a021                	j	ffffffffc02066c6 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc02066c0:	00074703          	lbu	a4,0(a4)
ffffffffc02066c4:	c711                	beqz	a4,ffffffffc02066d0 <strnlen+0x1c>
        cnt ++;
ffffffffc02066c6:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02066c8:	00f50733          	add	a4,a0,a5
ffffffffc02066cc:	fef59ae3          	bne	a1,a5,ffffffffc02066c0 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc02066d0:	853e                	mv	a0,a5
ffffffffc02066d2:	8082                	ret
    size_t cnt = 0;
ffffffffc02066d4:	4781                	li	a5,0
}
ffffffffc02066d6:	853e                	mv	a0,a5
ffffffffc02066d8:	8082                	ret

ffffffffc02066da <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc02066da:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc02066dc:	0585                	addi	a1,a1,1
ffffffffc02066de:	fff5c703          	lbu	a4,-1(a1)
ffffffffc02066e2:	0785                	addi	a5,a5,1
ffffffffc02066e4:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02066e8:	fb75                	bnez	a4,ffffffffc02066dc <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02066ea:	8082                	ret

ffffffffc02066ec <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02066ec:	00054783          	lbu	a5,0(a0)
ffffffffc02066f0:	0005c703          	lbu	a4,0(a1)
ffffffffc02066f4:	cb91                	beqz	a5,ffffffffc0206708 <strcmp+0x1c>
ffffffffc02066f6:	00e79c63          	bne	a5,a4,ffffffffc020670e <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc02066fa:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02066fc:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0206700:	0585                	addi	a1,a1,1
ffffffffc0206702:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0206706:	fbe5                	bnez	a5,ffffffffc02066f6 <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0206708:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020670a:	9d19                	subw	a0,a0,a4
ffffffffc020670c:	8082                	ret
ffffffffc020670e:	0007851b          	sext.w	a0,a5
ffffffffc0206712:	9d19                	subw	a0,a0,a4
ffffffffc0206714:	8082                	ret

ffffffffc0206716 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0206716:	00054783          	lbu	a5,0(a0)
ffffffffc020671a:	cb91                	beqz	a5,ffffffffc020672e <strchr+0x18>
        if (*s == c) {
ffffffffc020671c:	00b79563          	bne	a5,a1,ffffffffc0206726 <strchr+0x10>
ffffffffc0206720:	a809                	j	ffffffffc0206732 <strchr+0x1c>
ffffffffc0206722:	00b78763          	beq	a5,a1,ffffffffc0206730 <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0206726:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0206728:	00054783          	lbu	a5,0(a0)
ffffffffc020672c:	fbfd                	bnez	a5,ffffffffc0206722 <strchr+0xc>
    }
    return NULL;
ffffffffc020672e:	4501                	li	a0,0
}
ffffffffc0206730:	8082                	ret
ffffffffc0206732:	8082                	ret

ffffffffc0206734 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0206734:	ca01                	beqz	a2,ffffffffc0206744 <memset+0x10>
ffffffffc0206736:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0206738:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc020673a:	0785                	addi	a5,a5,1
ffffffffc020673c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0206740:	fec79de3          	bne	a5,a2,ffffffffc020673a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0206744:	8082                	ret

ffffffffc0206746 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0206746:	ca19                	beqz	a2,ffffffffc020675c <memcpy+0x16>
ffffffffc0206748:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc020674a:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc020674c:	0585                	addi	a1,a1,1
ffffffffc020674e:	fff5c703          	lbu	a4,-1(a1)
ffffffffc0206752:	0785                	addi	a5,a5,1
ffffffffc0206754:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0206758:	fec59ae3          	bne	a1,a2,ffffffffc020674c <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc020675c:	8082                	ret


bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    #a代表段是可访问的（allocatable），x代表段是可执行的（executable）
    #progbits：指示符，告诉汇编器这个段包含的是程序的正文（code），而不是其他类型的内容，如符号表或字符串表。
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02062b7          	lui	t0,0xc0206
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
ffffffffc0200024:	c0206137          	lui	sp,0xc0206

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	33c28293          	addi	t0,t0,828 # ffffffffc020033c <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <walk_print_device_tree>:
}

/// 遍历并打印设备树结构
void walk_print_device_tree(fdt_header_t* fdt_header) {
    // 检查魔数，0xd00dfeed，确保字节序正确
    assert(switch_endian(fdt_header->magic) == 0xd00dfeed);
ffffffffc0200032:	4118                	lw	a4,0(a0)
void walk_print_device_tree(fdt_header_t* fdt_header) {
ffffffffc0200034:	7119                	addi	sp,sp,-128
ffffffffc0200036:	ecce                	sd	s3,88(sp)
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc0200038:	69c1                	lui	s3,0x10
ffffffffc020003a:	0187561b          	srliw	a2,a4,0x18
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc020003e:	0187179b          	slliw	a5,a4,0x18
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc0200042:	0087569b          	srliw	a3,a4,0x8
ffffffffc0200046:	f0098993          	addi	s3,s3,-256 # ff00 <kern_entry-0xffffffffc01f0100>
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc020004a:	8fd1                	or	a5,a5,a2
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc020004c:	0136f6b3          	and	a3,a3,s3
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc0200050:	0087171b          	slliw	a4,a4,0x8
ffffffffc0200054:	00ff0637          	lui	a2,0xff0
ffffffffc0200058:	8f71                	and	a4,a4,a2
ffffffffc020005a:	8fd5                	or	a5,a5,a3
ffffffffc020005c:	8fd9                	or	a5,a5,a4
    assert(switch_endian(fdt_header->magic) == 0xd00dfeed);
ffffffffc020005e:	d00e0737          	lui	a4,0xd00e0
void walk_print_device_tree(fdt_header_t* fdt_header) {
ffffffffc0200062:	fc86                	sd	ra,120(sp)
ffffffffc0200064:	f8a2                	sd	s0,112(sp)
ffffffffc0200066:	f4a6                	sd	s1,104(sp)
ffffffffc0200068:	f0ca                	sd	s2,96(sp)
ffffffffc020006a:	e8d2                	sd	s4,80(sp)
ffffffffc020006c:	e4d6                	sd	s5,72(sp)
ffffffffc020006e:	e0da                	sd	s6,64(sp)
ffffffffc0200070:	fc5e                	sd	s7,56(sp)
ffffffffc0200072:	f862                	sd	s8,48(sp)
ffffffffc0200074:	f466                	sd	s9,40(sp)
ffffffffc0200076:	f06a                	sd	s10,32(sp)
ffffffffc0200078:	ec6e                	sd	s11,24(sp)
    assert(switch_endian(fdt_header->magic) == 0xd00dfeed);
ffffffffc020007a:	2781                	sext.w	a5,a5
ffffffffc020007c:	eed70713          	addi	a4,a4,-275 # ffffffffd00dfeed <end+0xfed897d>
ffffffffc0200080:	28e79e63          	bne	a5,a4,ffffffffc020031c <walk_print_device_tree+0x2ea>
    // 计算结构块的起始地址
    uint64_t structure_block_addr =
        (uint64_t)fdt_header + switch_endian(fdt_header->off_dt_struct);
    // 计算字符串块的起始地址
    uint64_t strings_block_addr =
        (uint64_t)fdt_header + switch_endian(fdt_header->off_dt_strings);
ffffffffc0200084:	4558                	lw	a4,12(a0)
        (uint64_t)fdt_header + switch_endian(fdt_header->totalsize);
ffffffffc0200086:	4154                	lw	a3,4(a0)
        (uint64_t)fdt_header + switch_endian(fdt_header->off_dt_struct);
ffffffffc0200088:	451c                	lw	a5,8(a0)
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc020008a:	01875b1b          	srliw	s6,a4,0x18
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc020008e:	01871e1b          	slliw	t3,a4,0x18
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc0200092:	0087581b          	srliw	a6,a4,0x8
ffffffffc0200096:	0186da1b          	srliw	s4,a3,0x18
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc020009a:	01869e9b          	slliw	t4,a3,0x18
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc020009e:	0086d89b          	srliw	a7,a3,0x8
ffffffffc02000a2:	0187d41b          	srliw	s0,a5,0x18
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc02000a6:	0187931b          	slliw	t1,a5,0x18
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc02000aa:	0087d59b          	srliw	a1,a5,0x8
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc02000ae:	01cb6b33          	or	s6,s6,t3
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc02000b2:	01387833          	and	a6,a6,s3
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc02000b6:	0087171b          	slliw	a4,a4,0x8
ffffffffc02000ba:	01da6a33          	or	s4,s4,t4
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc02000be:	0138f8b3          	and	a7,a7,s3
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc02000c2:	0086969b          	slliw	a3,a3,0x8
ffffffffc02000c6:	00646433          	or	s0,s0,t1
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc02000ca:	0135f5b3          	and	a1,a1,s3
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc02000ce:	0087979b          	slliw	a5,a5,0x8
ffffffffc02000d2:	010b6b33          	or	s6,s6,a6
ffffffffc02000d6:	8f71                	and	a4,a4,a2
ffffffffc02000d8:	8ff1                	and	a5,a5,a2
ffffffffc02000da:	011a6a33          	or	s4,s4,a7
ffffffffc02000de:	8ef1                	and	a3,a3,a2
ffffffffc02000e0:	8c4d                	or	s0,s0,a1
ffffffffc02000e2:	00eb6b33          	or	s6,s6,a4
ffffffffc02000e6:	8c5d                	or	s0,s0,a5
ffffffffc02000e8:	00da6a33          	or	s4,s4,a3
        (uint64_t)fdt_header + switch_endian(fdt_header->off_dt_strings);
ffffffffc02000ec:	1b02                	slli	s6,s6,0x20
        (uint64_t)fdt_header + switch_endian(fdt_header->totalsize);
ffffffffc02000ee:	1a02                	slli	s4,s4,0x20
        (uint64_t)fdt_header + switch_endian(fdt_header->off_dt_strings);
ffffffffc02000f0:	020b5b13          	srli	s6,s6,0x20
        (uint64_t)fdt_header + switch_endian(fdt_header->off_dt_struct);
ffffffffc02000f4:	1402                	slli	s0,s0,0x20
        (uint64_t)fdt_header + switch_endian(fdt_header->totalsize);
ffffffffc02000f6:	020a5a13          	srli	s4,s4,0x20
        (uint64_t)fdt_header + switch_endian(fdt_header->off_dt_struct);
ffffffffc02000fa:	9001                	srli	s0,s0,0x20
    uint64_t strings_block_addr =
ffffffffc02000fc:	00ab07b3          	add	a5,s6,a0
    uint64_t fdt_end_addr =
ffffffffc0200100:	9a2a                	add	s4,s4,a0
    uint64_t strings_block_addr =
ffffffffc0200102:	e03e                	sd	a5,0(sp)
    uint64_t structure_block_addr =
ffffffffc0200104:	942a                	add	s0,s0,a0

    size_t node_depth = 0; // 用于记录当前节点的深度
ffffffffc0200106:	4481                	li	s1,0
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc0200108:	00ff0ab7          	lui	s5,0xff0

    for (;;) {
        // 读取当前标记
        uint32_t marker = switch_endian(*p);

        switch (marker) {
ffffffffc020010c:	03000bb7          	lui	s7,0x3000
        cprintf("  ");
ffffffffc0200110:	00002917          	auipc	s2,0x2
ffffffffc0200114:	e6090913          	addi	s2,s2,-416 # ffffffffc0201f70 <etext+0x2>

                print_indent(node_depth); // 打印缩进

                // 通过字符串块中的偏移量获取属性名称
                const char* prop_name = (char*)(strings_block_addr + switch_endian(prop_data->nameoff));
                cprintf("%s: ", prop_name);
ffffffffc0200118:	00002d97          	auipc	s11,0x2
ffffffffc020011c:	ed8d8d93          	addi	s11,s11,-296 # ffffffffc0201ff0 <etext+0x82>

                // 打印属性值，按16进制打印
                uint8_t* prop_value = (uint8_t*)p;
                for (size_t i = 0; i < switch_endian(prop_data->len); i++) {
                    cprintf("%02x", prop_value[i]);
                    if (i % 4 == 3) cprintf(" ");
ffffffffc0200120:	4c0d                	li	s8,3
ffffffffc0200122:	00002d17          	auipc	s10,0x2
ffffffffc0200126:	eded0d13          	addi	s10,s10,-290 # ffffffffc0202000 <etext+0x92>
        uint32_t marker = switch_endian(*p);
ffffffffc020012a:	401c                	lw	a5,0(s0)
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc020012c:	0187d59b          	srliw	a1,a5,0x18
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc0200130:	0187969b          	slliw	a3,a5,0x18
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc0200134:	0087d71b          	srliw	a4,a5,0x8
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc0200138:	8dd5                	or	a1,a1,a3
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc020013a:	00e9f733          	and	a4,s3,a4
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc020013e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200142:	8dd9                	or	a1,a1,a4
ffffffffc0200144:	0157f7b3          	and	a5,a5,s5
ffffffffc0200148:	8ddd                	or	a1,a1,a5
ffffffffc020014a:	2581                	sext.w	a1,a1
        switch (marker) {
ffffffffc020014c:	0d758b63          	beq	a1,s7,ffffffffc0200222 <walk_print_device_tree+0x1f0>
ffffffffc0200150:	08bbe963          	bltu	s7,a1,ffffffffc02001e2 <walk_print_device_tree+0x1b0>
ffffffffc0200154:	010007b7          	lui	a5,0x1000
ffffffffc0200158:	06f59063          	bne	a1,a5,ffffffffc02001b8 <walk_print_device_tree+0x186>
                p++;
ffffffffc020015c:	0411                	addi	s0,s0,4
    for (size_t i = 0; i < indent; i++) {
ffffffffc020015e:	4c81                	li	s9,0
ffffffffc0200160:	c499                	beqz	s1,ffffffffc020016e <walk_print_device_tree+0x13c>
ffffffffc0200162:	0c85                	addi	s9,s9,1
        cprintf("  ");
ffffffffc0200164:	854a                	mv	a0,s2
ffffffffc0200166:	464000ef          	jal	ra,ffffffffc02005ca <cprintf>
    for (size_t i = 0; i < indent; i++) {
ffffffffc020016a:	ff949ce3          	bne	s1,s9,ffffffffc0200162 <walk_print_device_tree+0x130>
                if (strlen((char*)p) == 0) {
ffffffffc020016e:	8522                	mv	a0,s0
ffffffffc0200170:	091010ef          	jal	ra,ffffffffc0201a00 <strlen>
                node_depth++; // 节点深度增加
ffffffffc0200174:	0485                	addi	s1,s1,1
                if (strlen((char*)p) == 0) {
ffffffffc0200176:	18050a63          	beqz	a0,ffffffffc020030a <walk_print_device_tree+0x2d8>
                    cprintf("%s {\n", (char*)p);
ffffffffc020017a:	85a2                	mv	a1,s0
ffffffffc020017c:	00002517          	auipc	a0,0x2
ffffffffc0200180:	e6450513          	addi	a0,a0,-412 # ffffffffc0201fe0 <etext+0x72>
ffffffffc0200184:	446000ef          	jal	ra,ffffffffc02005ca <cprintf>
                p += (strlen((char*)p) + 4) / 4;
ffffffffc0200188:	8522                	mv	a0,s0
ffffffffc020018a:	077010ef          	jal	ra,ffffffffc0201a00 <strlen>
ffffffffc020018e:	0511                	addi	a0,a0,4
ffffffffc0200190:	9971                	andi	a0,a0,-4
ffffffffc0200192:	942a                	add	s0,s0,a0
                return;
            }
        }

        // 检查是否遍历完结构块或节点深度回到根节点
        if (node_depth == 0) return;
ffffffffc0200194:	c099                	beqz	s1,ffffffffc020019a <walk_print_device_tree+0x168>

        // 检查是否超出设备树的结束地址
        if ((uint64_t)p >= fdt_end_addr) return;
ffffffffc0200196:	f9446ae3          	bltu	s0,s4,ffffffffc020012a <walk_print_device_tree+0xf8>
    }
}
ffffffffc020019a:	70e6                	ld	ra,120(sp)
ffffffffc020019c:	7446                	ld	s0,112(sp)
ffffffffc020019e:	74a6                	ld	s1,104(sp)
ffffffffc02001a0:	7906                	ld	s2,96(sp)
ffffffffc02001a2:	69e6                	ld	s3,88(sp)
ffffffffc02001a4:	6a46                	ld	s4,80(sp)
ffffffffc02001a6:	6aa6                	ld	s5,72(sp)
ffffffffc02001a8:	6b06                	ld	s6,64(sp)
ffffffffc02001aa:	7be2                	ld	s7,56(sp)
ffffffffc02001ac:	7c42                	ld	s8,48(sp)
ffffffffc02001ae:	7ca2                	ld	s9,40(sp)
ffffffffc02001b0:	7d02                	ld	s10,32(sp)
ffffffffc02001b2:	6de2                	ld	s11,24(sp)
ffffffffc02001b4:	6109                	addi	sp,sp,128
ffffffffc02001b6:	8082                	ret
        switch (marker) {
ffffffffc02001b8:	020007b7          	lui	a5,0x2000
ffffffffc02001bc:	02f59d63          	bne	a1,a5,ffffffffc02001f6 <walk_print_device_tree+0x1c4>
                node_depth--; // 节点深度减少
ffffffffc02001c0:	14fd                	addi	s1,s1,-1
                p++;
ffffffffc02001c2:	0411                	addi	s0,s0,4
    for (size_t i = 0; i < indent; i++) {
ffffffffc02001c4:	4c81                	li	s9,0
ffffffffc02001c6:	c499                	beqz	s1,ffffffffc02001d4 <walk_print_device_tree+0x1a2>
ffffffffc02001c8:	0c85                	addi	s9,s9,1
        cprintf("  ");
ffffffffc02001ca:	854a                	mv	a0,s2
ffffffffc02001cc:	3fe000ef          	jal	ra,ffffffffc02005ca <cprintf>
    for (size_t i = 0; i < indent; i++) {
ffffffffc02001d0:	ff949ce3          	bne	s1,s9,ffffffffc02001c8 <walk_print_device_tree+0x196>
                cprintf("}\n");
ffffffffc02001d4:	00002517          	auipc	a0,0x2
ffffffffc02001d8:	e1450513          	addi	a0,a0,-492 # ffffffffc0201fe8 <etext+0x7a>
ffffffffc02001dc:	3ee000ef          	jal	ra,ffffffffc02005ca <cprintf>
                break;
ffffffffc02001e0:	bf55                	j	ffffffffc0200194 <walk_print_device_tree+0x162>
        switch (marker) {
ffffffffc02001e2:	040007b7          	lui	a5,0x4000
ffffffffc02001e6:	00f59463          	bne	a1,a5,ffffffffc02001ee <walk_print_device_tree+0x1bc>
                p++;
ffffffffc02001ea:	0411                	addi	s0,s0,4
                break;
ffffffffc02001ec:	b765                	j	ffffffffc0200194 <walk_print_device_tree+0x162>
        switch (marker) {
ffffffffc02001ee:	090007b7          	lui	a5,0x9000
ffffffffc02001f2:	faf584e3          	beq	a1,a5,ffffffffc020019a <walk_print_device_tree+0x168>
                cprintf("unknown marker: 0x%08x\n", marker);
ffffffffc02001f6:	00002517          	auipc	a0,0x2
ffffffffc02001fa:	e1250513          	addi	a0,a0,-494 # ffffffffc0202008 <etext+0x9a>
ffffffffc02001fe:	3cc000ef          	jal	ra,ffffffffc02005ca <cprintf>
                assert(0); // 触发断言，停止程序
ffffffffc0200202:	00002697          	auipc	a3,0x2
ffffffffc0200206:	e1e68693          	addi	a3,a3,-482 # ffffffffc0202020 <etext+0xb2>
ffffffffc020020a:	00002617          	auipc	a2,0x2
ffffffffc020020e:	d9e60613          	addi	a2,a2,-610 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc0200212:	09f00593          	li	a1,159
ffffffffc0200216:	00002517          	auipc	a0,0x2
ffffffffc020021a:	daa50513          	addi	a0,a0,-598 # ffffffffc0201fc0 <etext+0x52>
ffffffffc020021e:	434000ef          	jal	ra,ffffffffc0200652 <__panic>
                p += sizeof(fdt_prop_data_t) / sizeof(uint32_t); // 跳过属性数据头
ffffffffc0200222:	00c40793          	addi	a5,s0,12
ffffffffc0200226:	e43e                	sd	a5,8(sp)
    for (size_t i = 0; i < indent; i++) {
ffffffffc0200228:	4c81                	li	s9,0
ffffffffc020022a:	c499                	beqz	s1,ffffffffc0200238 <walk_print_device_tree+0x206>
ffffffffc020022c:	0c85                	addi	s9,s9,1
        cprintf("  ");
ffffffffc020022e:	854a                	mv	a0,s2
ffffffffc0200230:	39a000ef          	jal	ra,ffffffffc02005ca <cprintf>
    for (size_t i = 0; i < indent; i++) {
ffffffffc0200234:	ff949ce3          	bne	s1,s9,ffffffffc020022c <walk_print_device_tree+0x1fa>
                const char* prop_name = (char*)(strings_block_addr + switch_endian(prop_data->nameoff));
ffffffffc0200238:	441c                	lw	a5,8(s0)
                cprintf("%s: ", prop_name);
ffffffffc020023a:	856e                	mv	a0,s11
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc020023c:	0187969b          	slliw	a3,a5,0x18
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc0200240:	0187d59b          	srliw	a1,a5,0x18
ffffffffc0200244:	0087d71b          	srliw	a4,a5,0x8
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc0200248:	8dd5                	or	a1,a1,a3
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc020024a:	00e9f733          	and	a4,s3,a4
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc020024e:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200252:	8dd9                	or	a1,a1,a4
ffffffffc0200254:	0157f7b3          	and	a5,a5,s5
ffffffffc0200258:	8ddd                	or	a1,a1,a5
                cprintf("%s: ", prop_name);
ffffffffc020025a:	6782                	ld	a5,0(sp)
                const char* prop_name = (char*)(strings_block_addr + switch_endian(prop_data->nameoff));
ffffffffc020025c:	1582                	slli	a1,a1,0x20
ffffffffc020025e:	9181                	srli	a1,a1,0x20
                cprintf("%s: ", prop_name);
ffffffffc0200260:	95be                	add	a1,a1,a5
ffffffffc0200262:	368000ef          	jal	ra,ffffffffc02005ca <cprintf>
                for (size_t i = 0; i < switch_endian(prop_data->len); i++) {
ffffffffc0200266:	4058                	lw	a4,4(s0)
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc0200268:	0187579b          	srliw	a5,a4,0x18
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc020026c:	0187161b          	slliw	a2,a4,0x18
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc0200270:	0087569b          	srliw	a3,a4,0x8
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc0200274:	8fd1                	or	a5,a5,a2
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc0200276:	00d9f6b3          	and	a3,s3,a3
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc020027a:	0087171b          	slliw	a4,a4,0x8
ffffffffc020027e:	8fd5                	or	a5,a5,a3
ffffffffc0200280:	01577733          	and	a4,a4,s5
ffffffffc0200284:	8fd9                	or	a5,a5,a4
                for (size_t i = 0; i < switch_endian(prop_data->len); i++) {
ffffffffc0200286:	2781                	sext.w	a5,a5
ffffffffc0200288:	cbc1                	beqz	a5,ffffffffc0200318 <walk_print_device_tree+0x2e6>
                    cprintf("%02x", prop_value[i]);
ffffffffc020028a:	00c44583          	lbu	a1,12(s0)
ffffffffc020028e:	00002517          	auipc	a0,0x2
ffffffffc0200292:	d6a50513          	addi	a0,a0,-662 # ffffffffc0201ff8 <etext+0x8a>
                for (size_t i = 0; i < switch_endian(prop_data->len); i++) {
ffffffffc0200296:	4b01                	li	s6,0
                    cprintf("%02x", prop_value[i]);
ffffffffc0200298:	332000ef          	jal	ra,ffffffffc02005ca <cprintf>
ffffffffc020029c:	00002c97          	auipc	s9,0x2
ffffffffc02002a0:	d5cc8c93          	addi	s9,s9,-676 # ffffffffc0201ff8 <etext+0x8a>
                for (size_t i = 0; i < switch_endian(prop_data->len); i++) {
ffffffffc02002a4:	4058                	lw	a4,4(s0)
ffffffffc02002a6:	0b05                	addi	s6,s6,1
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc02002a8:	0187579b          	srliw	a5,a4,0x18
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc02002ac:	0187159b          	slliw	a1,a4,0x18
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc02002b0:	0087561b          	srliw	a2,a4,0x8
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc02002b4:	8fcd                	or	a5,a5,a1
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc02002b6:	00c9f633          	and	a2,s3,a2
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc02002ba:	0087171b          	slliw	a4,a4,0x8
ffffffffc02002be:	01577733          	and	a4,a4,s5
ffffffffc02002c2:	8fd1                	or	a5,a5,a2
ffffffffc02002c4:	8fd9                	or	a5,a5,a4
                for (size_t i = 0; i < switch_endian(prop_data->len); i++) {
ffffffffc02002c6:	02079713          	slli	a4,a5,0x20
ffffffffc02002ca:	9301                	srli	a4,a4,0x20
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc02002cc:	2781                	sext.w	a5,a5
                for (size_t i = 0; i < switch_endian(prop_data->len); i++) {
ffffffffc02002ce:	02eb7163          	bgeu	s6,a4,ffffffffc02002f0 <walk_print_device_tree+0x2be>
                    cprintf("%02x", prop_value[i]);
ffffffffc02002d2:	016407b3          	add	a5,s0,s6
ffffffffc02002d6:	00c7c583          	lbu	a1,12(a5) # 900000c <kern_entry-0xffffffffb71ffff4>
ffffffffc02002da:	8566                	mv	a0,s9
ffffffffc02002dc:	2ee000ef          	jal	ra,ffffffffc02005ca <cprintf>
                    if (i % 4 == 3) cprintf(" ");
ffffffffc02002e0:	003b7793          	andi	a5,s6,3
ffffffffc02002e4:	fd8790e3          	bne	a5,s8,ffffffffc02002a4 <walk_print_device_tree+0x272>
ffffffffc02002e8:	856a                	mv	a0,s10
ffffffffc02002ea:	2e0000ef          	jal	ra,ffffffffc02005ca <cprintf>
ffffffffc02002ee:	bf5d                	j	ffffffffc02002a4 <walk_print_device_tree+0x272>
                p += (switch_endian(prop_data->len) + 3) / 4;
ffffffffc02002f0:	278d                	addiw	a5,a5,3
ffffffffc02002f2:	0027d41b          	srliw	s0,a5,0x2
ffffffffc02002f6:	67a2                	ld	a5,8(sp)
ffffffffc02002f8:	040a                	slli	s0,s0,0x2
ffffffffc02002fa:	943e                	add	s0,s0,a5
                cprintf("\n");
ffffffffc02002fc:	00003517          	auipc	a0,0x3
ffffffffc0200300:	b2450513          	addi	a0,a0,-1244 # ffffffffc0202e20 <commands+0xa10>
ffffffffc0200304:	2c6000ef          	jal	ra,ffffffffc02005ca <cprintf>
                break;
ffffffffc0200308:	b571                	j	ffffffffc0200194 <walk_print_device_tree+0x162>
                    cprintf("devicetree {\n");
ffffffffc020030a:	00002517          	auipc	a0,0x2
ffffffffc020030e:	cc650513          	addi	a0,a0,-826 # ffffffffc0201fd0 <etext+0x62>
ffffffffc0200312:	2b8000ef          	jal	ra,ffffffffc02005ca <cprintf>
ffffffffc0200316:	bd8d                	j	ffffffffc0200188 <walk_print_device_tree+0x156>
                for (size_t i = 0; i < switch_endian(prop_data->len); i++) {
ffffffffc0200318:	6422                	ld	s0,8(sp)
ffffffffc020031a:	b7cd                	j	ffffffffc02002fc <walk_print_device_tree+0x2ca>
    assert(switch_endian(fdt_header->magic) == 0xd00dfeed);
ffffffffc020031c:	00002697          	auipc	a3,0x2
ffffffffc0200320:	c5c68693          	addi	a3,a3,-932 # ffffffffc0201f78 <etext+0xa>
ffffffffc0200324:	00002617          	auipc	a2,0x2
ffffffffc0200328:	c8460613          	addi	a2,a2,-892 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc020032c:	05200593          	li	a1,82
ffffffffc0200330:	00002517          	auipc	a0,0x2
ffffffffc0200334:	c9050513          	addi	a0,a0,-880 # ffffffffc0201fc0 <etext+0x52>
ffffffffc0200338:	31a000ef          	jal	ra,ffffffffc0200652 <__panic>

ffffffffc020033c <kern_init>:
//     /* do nothing */
//     while (1)
//         ;
// }

int kern_init(uint32_t hartid, uintptr_t dtb_pa) {
ffffffffc020033c:	1101                	addi	sp,sp,-32
    extern char edata[], end[];

    memset(edata, 0, end - edata);
ffffffffc020033e:	00007797          	auipc	a5,0x7
ffffffffc0200342:	cd278793          	addi	a5,a5,-814 # ffffffffc0207010 <free_buddy>
ffffffffc0200346:	00007617          	auipc	a2,0x7
ffffffffc020034a:	22a60613          	addi	a2,a2,554 # ffffffffc0207570 <end>
ffffffffc020034e:	8e1d                	sub	a2,a2,a5
int kern_init(uint32_t hartid, uintptr_t dtb_pa) {
ffffffffc0200350:	e822                	sd	s0,16(sp)
ffffffffc0200352:	e426                	sd	s1,8(sp)
ffffffffc0200354:	842e                	mv	s0,a1
ffffffffc0200356:	84aa                	mv	s1,a0
    memset(edata, 0, end - edata);
ffffffffc0200358:	4581                	li	a1,0
ffffffffc020035a:	853e                	mv	a0,a5
int kern_init(uint32_t hartid, uintptr_t dtb_pa) {
ffffffffc020035c:	ec06                	sd	ra,24(sp)
ffffffffc020035e:	e04a                	sd	s2,0(sp)
    memset(edata, 0, end - edata);
ffffffffc0200360:	70a010ef          	jal	ra,ffffffffc0201a6a <memset>

    // initialize the console
    cons_init();
ffffffffc0200364:	5fe000ef          	jal	ra,ffffffffc0200962 <cons_init>

    const char* message = "(os(hwxfzylc)) os is loading ...\0";
    cputs(message);
ffffffffc0200368:	00002517          	auipc	a0,0x2
ffffffffc020036c:	e2850513          	addi	a0,a0,-472 # ffffffffc0202190 <etext+0x222>
ffffffffc0200370:	292000ef          	jal	ra,ffffffffc0200602 <cputs>

    print_kerninfo();
ffffffffc0200374:	33a000ef          	jal	ra,ffffffffc02006ae <print_kerninfo>

    cprintf("hartid: %d\n", hartid);
ffffffffc0200378:	85a6                	mv	a1,s1
ffffffffc020037a:	00002517          	auipc	a0,0x2
ffffffffc020037e:	cae50513          	addi	a0,a0,-850 # ffffffffc0202028 <etext+0xba>
ffffffffc0200382:	248000ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("dtb_pa: 0x%016lx\n", dtb_pa);
ffffffffc0200386:	85a2                	mv	a1,s0
ffffffffc0200388:	00002517          	auipc	a0,0x2
ffffffffc020038c:	cb050513          	addi	a0,a0,-848 # ffffffffc0202038 <etext+0xca>
ffffffffc0200390:	23a000ef          	jal	ra,ffffffffc02005ca <cprintf>

    // 0x80000000 is still mapped to itself, so just use the physical address
    // here.
    fdt_header_t* fdt_header = (fdt_header_t*)(dtb_pa);

    cprintf("fdt_magic:             0x%08x\n",
ffffffffc0200394:	401c                	lw	a5,0(s0)
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc0200396:	64c1                	lui	s1,0x10
ffffffffc0200398:	f0048493          	addi	s1,s1,-256 # ff00 <kern_entry-0xffffffffc01f0100>
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc020039c:	0187961b          	slliw	a2,a5,0x18
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc02003a0:	0187d71b          	srliw	a4,a5,0x18
ffffffffc02003a4:	0087d69b          	srliw	a3,a5,0x8
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc02003a8:	00ff0937          	lui	s2,0xff0
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc02003ac:	8ee5                	and	a3,a3,s1
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc02003ae:	8f51                	or	a4,a4,a2
ffffffffc02003b0:	0087979b          	slliw	a5,a5,0x8
ffffffffc02003b4:	8f55                	or	a4,a4,a3
ffffffffc02003b6:	0127f7b3          	and	a5,a5,s2
ffffffffc02003ba:	8fd9                	or	a5,a5,a4
ffffffffc02003bc:	0007859b          	sext.w	a1,a5
ffffffffc02003c0:	00002517          	auipc	a0,0x2
ffffffffc02003c4:	c9050513          	addi	a0,a0,-880 # ffffffffc0202050 <etext+0xe2>
ffffffffc02003c8:	202000ef          	jal	ra,ffffffffc02005ca <cprintf>
            switch_endian(fdt_header->magic));
    cprintf("fdt_totalsize:         0x%08x\n",
ffffffffc02003cc:	405c                	lw	a5,4(s0)
ffffffffc02003ce:	00002517          	auipc	a0,0x2
ffffffffc02003d2:	ca250513          	addi	a0,a0,-862 # ffffffffc0202070 <etext+0x102>
ffffffffc02003d6:	0187961b          	slliw	a2,a5,0x18
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc02003da:	0187d71b          	srliw	a4,a5,0x18
ffffffffc02003de:	0087d69b          	srliw	a3,a5,0x8
ffffffffc02003e2:	8ee5                	and	a3,a3,s1
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc02003e4:	8f51                	or	a4,a4,a2
ffffffffc02003e6:	0087979b          	slliw	a5,a5,0x8
ffffffffc02003ea:	8f55                	or	a4,a4,a3
ffffffffc02003ec:	0127f7b3          	and	a5,a5,s2
ffffffffc02003f0:	8fd9                	or	a5,a5,a4
ffffffffc02003f2:	0007859b          	sext.w	a1,a5
ffffffffc02003f6:	1d4000ef          	jal	ra,ffffffffc02005ca <cprintf>
            switch_endian(fdt_header->totalsize));
    cprintf("fdt_off_dt_struct:     0x%08x\n",
ffffffffc02003fa:	441c                	lw	a5,8(s0)
ffffffffc02003fc:	00002517          	auipc	a0,0x2
ffffffffc0200400:	c9450513          	addi	a0,a0,-876 # ffffffffc0202090 <etext+0x122>
ffffffffc0200404:	0187961b          	slliw	a2,a5,0x18
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc0200408:	0187d71b          	srliw	a4,a5,0x18
ffffffffc020040c:	0087d69b          	srliw	a3,a5,0x8
ffffffffc0200410:	8ee5                	and	a3,a3,s1
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc0200412:	8f51                	or	a4,a4,a2
ffffffffc0200414:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200418:	8f55                	or	a4,a4,a3
ffffffffc020041a:	0127f7b3          	and	a5,a5,s2
ffffffffc020041e:	8fd9                	or	a5,a5,a4
ffffffffc0200420:	0007859b          	sext.w	a1,a5
ffffffffc0200424:	1a6000ef          	jal	ra,ffffffffc02005ca <cprintf>
            switch_endian(fdt_header->off_dt_struct));
    cprintf("fdt_off_dt_strings:    0x%08x\n",
ffffffffc0200428:	445c                	lw	a5,12(s0)
ffffffffc020042a:	00002517          	auipc	a0,0x2
ffffffffc020042e:	c8650513          	addi	a0,a0,-890 # ffffffffc02020b0 <etext+0x142>
ffffffffc0200432:	0187961b          	slliw	a2,a5,0x18
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc0200436:	0187d71b          	srliw	a4,a5,0x18
ffffffffc020043a:	0087d69b          	srliw	a3,a5,0x8
ffffffffc020043e:	8ee5                	and	a3,a3,s1
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc0200440:	8f51                	or	a4,a4,a2
ffffffffc0200442:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200446:	8f55                	or	a4,a4,a3
ffffffffc0200448:	0127f7b3          	and	a5,a5,s2
ffffffffc020044c:	8fd9                	or	a5,a5,a4
ffffffffc020044e:	0007859b          	sext.w	a1,a5
ffffffffc0200452:	178000ef          	jal	ra,ffffffffc02005ca <cprintf>
            switch_endian(fdt_header->off_dt_strings));
    cprintf("fdt_off_mem_rsvmap:    0x%08x\n",
ffffffffc0200456:	481c                	lw	a5,16(s0)
ffffffffc0200458:	00002517          	auipc	a0,0x2
ffffffffc020045c:	c7850513          	addi	a0,a0,-904 # ffffffffc02020d0 <etext+0x162>
ffffffffc0200460:	0187961b          	slliw	a2,a5,0x18
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc0200464:	0187d71b          	srliw	a4,a5,0x18
ffffffffc0200468:	0087d69b          	srliw	a3,a5,0x8
ffffffffc020046c:	8ee5                	and	a3,a3,s1
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc020046e:	8f51                	or	a4,a4,a2
ffffffffc0200470:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200474:	8f55                	or	a4,a4,a3
ffffffffc0200476:	0127f7b3          	and	a5,a5,s2
ffffffffc020047a:	8fd9                	or	a5,a5,a4
ffffffffc020047c:	0007859b          	sext.w	a1,a5
ffffffffc0200480:	14a000ef          	jal	ra,ffffffffc02005ca <cprintf>
            switch_endian(fdt_header->off_mem_rsvmap));
    cprintf("fdt_version:           0x%08x\n",
ffffffffc0200484:	485c                	lw	a5,20(s0)
ffffffffc0200486:	00002517          	auipc	a0,0x2
ffffffffc020048a:	c6a50513          	addi	a0,a0,-918 # ffffffffc02020f0 <etext+0x182>
ffffffffc020048e:	0187961b          	slliw	a2,a5,0x18
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc0200492:	0187d71b          	srliw	a4,a5,0x18
ffffffffc0200496:	0087d69b          	srliw	a3,a5,0x8
ffffffffc020049a:	8ee5                	and	a3,a3,s1
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc020049c:	8f51                	or	a4,a4,a2
ffffffffc020049e:	0087979b          	slliw	a5,a5,0x8
ffffffffc02004a2:	8f55                	or	a4,a4,a3
ffffffffc02004a4:	0127f7b3          	and	a5,a5,s2
ffffffffc02004a8:	8fd9                	or	a5,a5,a4
ffffffffc02004aa:	0007859b          	sext.w	a1,a5
ffffffffc02004ae:	11c000ef          	jal	ra,ffffffffc02005ca <cprintf>
            switch_endian(fdt_header->version));
    cprintf("fdt_last_comp_version: 0x%08x\n",
ffffffffc02004b2:	4c1c                	lw	a5,24(s0)
ffffffffc02004b4:	00002517          	auipc	a0,0x2
ffffffffc02004b8:	c5c50513          	addi	a0,a0,-932 # ffffffffc0202110 <etext+0x1a2>
ffffffffc02004bc:	0187961b          	slliw	a2,a5,0x18
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc02004c0:	0187d71b          	srliw	a4,a5,0x18
ffffffffc02004c4:	0087d69b          	srliw	a3,a5,0x8
ffffffffc02004c8:	8ee5                	and	a3,a3,s1
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc02004ca:	8f51                	or	a4,a4,a2
ffffffffc02004cc:	0087979b          	slliw	a5,a5,0x8
ffffffffc02004d0:	8f55                	or	a4,a4,a3
ffffffffc02004d2:	0127f7b3          	and	a5,a5,s2
ffffffffc02004d6:	8fd9                	or	a5,a5,a4
ffffffffc02004d8:	0007859b          	sext.w	a1,a5
ffffffffc02004dc:	0ee000ef          	jal	ra,ffffffffc02005ca <cprintf>
            switch_endian(fdt_header->last_comp_version));
    cprintf("fdt_boot_cpuid_phys:   0x%08x\n",
ffffffffc02004e0:	4c5c                	lw	a5,28(s0)
ffffffffc02004e2:	00002517          	auipc	a0,0x2
ffffffffc02004e6:	c4e50513          	addi	a0,a0,-946 # ffffffffc0202130 <etext+0x1c2>
ffffffffc02004ea:	0187961b          	slliw	a2,a5,0x18
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc02004ee:	0187d71b          	srliw	a4,a5,0x18
ffffffffc02004f2:	0087d69b          	srliw	a3,a5,0x8
ffffffffc02004f6:	8ee5                	and	a3,a3,s1
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc02004f8:	8f51                	or	a4,a4,a2
ffffffffc02004fa:	0087979b          	slliw	a5,a5,0x8
ffffffffc02004fe:	8f55                	or	a4,a4,a3
ffffffffc0200500:	0127f7b3          	and	a5,a5,s2
ffffffffc0200504:	8fd9                	or	a5,a5,a4
ffffffffc0200506:	0007859b          	sext.w	a1,a5
ffffffffc020050a:	0c0000ef          	jal	ra,ffffffffc02005ca <cprintf>
            switch_endian(fdt_header->boot_cpuid_phys));
    cprintf("fdt_size_dt_strings:   0x%08x\n",
ffffffffc020050e:	501c                	lw	a5,32(s0)
ffffffffc0200510:	00002517          	auipc	a0,0x2
ffffffffc0200514:	c4050513          	addi	a0,a0,-960 # ffffffffc0202150 <etext+0x1e2>
ffffffffc0200518:	0187961b          	slliw	a2,a5,0x18
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc020051c:	0187d71b          	srliw	a4,a5,0x18
ffffffffc0200520:	0087d69b          	srliw	a3,a5,0x8
ffffffffc0200524:	8ee5                	and	a3,a3,s1
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc0200526:	8f51                	or	a4,a4,a2
ffffffffc0200528:	0087979b          	slliw	a5,a5,0x8
ffffffffc020052c:	8f55                	or	a4,a4,a3
ffffffffc020052e:	0127f7b3          	and	a5,a5,s2
ffffffffc0200532:	8fd9                	or	a5,a5,a4
ffffffffc0200534:	0007859b          	sext.w	a1,a5
ffffffffc0200538:	092000ef          	jal	ra,ffffffffc02005ca <cprintf>
            switch_endian(fdt_header->size_dt_strings));
    cprintf("fdt_size_dt_struct:    0x%08x\n",
ffffffffc020053c:	505c                	lw	a5,36(s0)
ffffffffc020053e:	00002517          	auipc	a0,0x2
ffffffffc0200542:	c3250513          	addi	a0,a0,-974 # ffffffffc0202170 <etext+0x202>
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc0200546:	0187d61b          	srliw	a2,a5,0x18
ffffffffc020054a:	0087d69b          	srliw	a3,a5,0x8
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc020054e:	0187971b          	slliw	a4,a5,0x18
ffffffffc0200552:	8f51                	or	a4,a4,a2
ffffffffc0200554:	0087979b          	slliw	a5,a5,0x8
    return ((val & 0xff000000) >> 24) | ((val & 0x00ff0000) >> 8) |
ffffffffc0200558:	8cf5                	and	s1,s1,a3
           ((val & 0x0000ff00) << 8) | ((val & 0x000000ff) << 24);
ffffffffc020055a:	0127f933          	and	s2,a5,s2
ffffffffc020055e:	8f45                	or	a4,a4,s1
ffffffffc0200560:	01276933          	or	s2,a4,s2
ffffffffc0200564:	0009059b          	sext.w	a1,s2
ffffffffc0200568:	062000ef          	jal	ra,ffffffffc02005ca <cprintf>
            switch_endian(fdt_header->size_dt_struct));

    // Walk through the flattend device tree and print it out.
    // Comment this to `make grade`.
    walk_print_device_tree(fdt_header);
ffffffffc020056c:	8522                	mv	a0,s0
ffffffffc020056e:	ac5ff0ef          	jal	ra,ffffffffc0200032 <walk_print_device_tree>

    // Clean up the page table
    boot_page_table_sv39[2] = 0;
ffffffffc0200572:	00006797          	auipc	a5,0x6
ffffffffc0200576:	a8078823          	sb	zero,-1392(a5) # ffffffffc0206002 <boot_page_table_sv39+0x2>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc020057a:	402000ef          	jal	ra,ffffffffc020097c <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020057e:	05f000ef          	jal	ra,ffffffffc0200ddc <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200582:	3fa000ef          	jal	ra,ffffffffc020097c <idt_init>

    clock_init();  // init clock interrupt
ffffffffc0200586:	39a000ef          	jal	ra,ffffffffc0200920 <clock_init>

    intr_enable();  // enable irq interrupt
ffffffffc020058a:	3e6000ef          	jal	ra,ffffffffc0200970 <intr_enable>

    /* do nothing */
    while (1)
ffffffffc020058e:	a001                	j	ffffffffc020058e <kern_init+0x252>

ffffffffc0200590 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200590:	1141                	addi	sp,sp,-16
ffffffffc0200592:	e022                	sd	s0,0(sp)
ffffffffc0200594:	e406                	sd	ra,8(sp)
ffffffffc0200596:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc0200598:	3cc000ef          	jal	ra,ffffffffc0200964 <cons_putc>
    (*cnt) ++;
ffffffffc020059c:	401c                	lw	a5,0(s0)
}
ffffffffc020059e:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02005a0:	2785                	addiw	a5,a5,1
ffffffffc02005a2:	c01c                	sw	a5,0(s0)
}
ffffffffc02005a4:	6402                	ld	s0,0(sp)
ffffffffc02005a6:	0141                	addi	sp,sp,16
ffffffffc02005a8:	8082                	ret

ffffffffc02005aa <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02005aa:	1101                	addi	sp,sp,-32
ffffffffc02005ac:	862a                	mv	a2,a0
ffffffffc02005ae:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02005b0:	00000517          	auipc	a0,0x0
ffffffffc02005b4:	fe050513          	addi	a0,a0,-32 # ffffffffc0200590 <cputch>
ffffffffc02005b8:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02005ba:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02005bc:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02005be:	52a010ef          	jal	ra,ffffffffc0201ae8 <vprintfmt>
    return cnt;
}
ffffffffc02005c2:	60e2                	ld	ra,24(sp)
ffffffffc02005c4:	4532                	lw	a0,12(sp)
ffffffffc02005c6:	6105                	addi	sp,sp,32
ffffffffc02005c8:	8082                	ret

ffffffffc02005ca <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02005ca:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02005cc:	02810313          	addi	t1,sp,40 # ffffffffc0206028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02005d0:	8e2a                	mv	t3,a0
ffffffffc02005d2:	f42e                	sd	a1,40(sp)
ffffffffc02005d4:	f832                	sd	a2,48(sp)
ffffffffc02005d6:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02005d8:	00000517          	auipc	a0,0x0
ffffffffc02005dc:	fb850513          	addi	a0,a0,-72 # ffffffffc0200590 <cputch>
ffffffffc02005e0:	004c                	addi	a1,sp,4
ffffffffc02005e2:	869a                	mv	a3,t1
ffffffffc02005e4:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02005e6:	ec06                	sd	ra,24(sp)
ffffffffc02005e8:	e0ba                	sd	a4,64(sp)
ffffffffc02005ea:	e4be                	sd	a5,72(sp)
ffffffffc02005ec:	e8c2                	sd	a6,80(sp)
ffffffffc02005ee:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02005f0:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02005f2:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02005f4:	4f4010ef          	jal	ra,ffffffffc0201ae8 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02005f8:	60e2                	ld	ra,24(sp)
ffffffffc02005fa:	4512                	lw	a0,4(sp)
ffffffffc02005fc:	6125                	addi	sp,sp,96
ffffffffc02005fe:	8082                	ret

ffffffffc0200600 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200600:	a695                	j	ffffffffc0200964 <cons_putc>

ffffffffc0200602 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200602:	1101                	addi	sp,sp,-32
ffffffffc0200604:	e822                	sd	s0,16(sp)
ffffffffc0200606:	ec06                	sd	ra,24(sp)
ffffffffc0200608:	e426                	sd	s1,8(sp)
ffffffffc020060a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020060c:	00054503          	lbu	a0,0(a0)
ffffffffc0200610:	c51d                	beqz	a0,ffffffffc020063e <cputs+0x3c>
ffffffffc0200612:	0405                	addi	s0,s0,1
ffffffffc0200614:	4485                	li	s1,1
ffffffffc0200616:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200618:	34c000ef          	jal	ra,ffffffffc0200964 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020061c:	00044503          	lbu	a0,0(s0)
ffffffffc0200620:	008487bb          	addw	a5,s1,s0
ffffffffc0200624:	0405                	addi	s0,s0,1
ffffffffc0200626:	f96d                	bnez	a0,ffffffffc0200618 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200628:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020062c:	4529                	li	a0,10
ffffffffc020062e:	336000ef          	jal	ra,ffffffffc0200964 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200632:	60e2                	ld	ra,24(sp)
ffffffffc0200634:	8522                	mv	a0,s0
ffffffffc0200636:	6442                	ld	s0,16(sp)
ffffffffc0200638:	64a2                	ld	s1,8(sp)
ffffffffc020063a:	6105                	addi	sp,sp,32
ffffffffc020063c:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020063e:	4405                	li	s0,1
ffffffffc0200640:	b7f5                	j	ffffffffc020062c <cputs+0x2a>

ffffffffc0200642 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200642:	1141                	addi	sp,sp,-16
ffffffffc0200644:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200646:	326000ef          	jal	ra,ffffffffc020096c <cons_getc>
ffffffffc020064a:	dd75                	beqz	a0,ffffffffc0200646 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020064c:	60a2                	ld	ra,8(sp)
ffffffffc020064e:	0141                	addi	sp,sp,16
ffffffffc0200650:	8082                	ret

ffffffffc0200652 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200652:	00007317          	auipc	t1,0x7
ffffffffc0200656:	ece30313          	addi	t1,t1,-306 # ffffffffc0207520 <is_panic>
ffffffffc020065a:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc020065e:	715d                	addi	sp,sp,-80
ffffffffc0200660:	ec06                	sd	ra,24(sp)
ffffffffc0200662:	e822                	sd	s0,16(sp)
ffffffffc0200664:	f436                	sd	a3,40(sp)
ffffffffc0200666:	f83a                	sd	a4,48(sp)
ffffffffc0200668:	fc3e                	sd	a5,56(sp)
ffffffffc020066a:	e0c2                	sd	a6,64(sp)
ffffffffc020066c:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc020066e:	020e1a63          	bnez	t3,ffffffffc02006a2 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200672:	4785                	li	a5,1
ffffffffc0200674:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200678:	8432                	mv	s0,a2
ffffffffc020067a:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020067c:	862e                	mv	a2,a1
ffffffffc020067e:	85aa                	mv	a1,a0
ffffffffc0200680:	00002517          	auipc	a0,0x2
ffffffffc0200684:	b3850513          	addi	a0,a0,-1224 # ffffffffc02021b8 <etext+0x24a>
    va_start(ap, fmt);
ffffffffc0200688:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020068a:	f41ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    vcprintf(fmt, ap);
ffffffffc020068e:	65a2                	ld	a1,8(sp)
ffffffffc0200690:	8522                	mv	a0,s0
ffffffffc0200692:	f19ff0ef          	jal	ra,ffffffffc02005aa <vcprintf>
    cprintf("\n");
ffffffffc0200696:	00002517          	auipc	a0,0x2
ffffffffc020069a:	78a50513          	addi	a0,a0,1930 # ffffffffc0202e20 <commands+0xa10>
ffffffffc020069e:	f2dff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc02006a2:	2d4000ef          	jal	ra,ffffffffc0200976 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02006a6:	4501                	li	a0,0
ffffffffc02006a8:	130000ef          	jal	ra,ffffffffc02007d8 <kmonitor>
    while (1) {
ffffffffc02006ac:	bfed                	j	ffffffffc02006a6 <__panic+0x54>

ffffffffc02006ae <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc02006ae:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc02006b0:	00002517          	auipc	a0,0x2
ffffffffc02006b4:	b2850513          	addi	a0,a0,-1240 # ffffffffc02021d8 <etext+0x26a>
void print_kerninfo(void) {
ffffffffc02006b8:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc02006ba:	f11ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc02006be:	00000597          	auipc	a1,0x0
ffffffffc02006c2:	c7e58593          	addi	a1,a1,-898 # ffffffffc020033c <kern_init>
ffffffffc02006c6:	00002517          	auipc	a0,0x2
ffffffffc02006ca:	b3250513          	addi	a0,a0,-1230 # ffffffffc02021f8 <etext+0x28a>
ffffffffc02006ce:	efdff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc02006d2:	00002597          	auipc	a1,0x2
ffffffffc02006d6:	89c58593          	addi	a1,a1,-1892 # ffffffffc0201f6e <etext>
ffffffffc02006da:	00002517          	auipc	a0,0x2
ffffffffc02006de:	b3e50513          	addi	a0,a0,-1218 # ffffffffc0202218 <etext+0x2aa>
ffffffffc02006e2:	ee9ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc02006e6:	00007597          	auipc	a1,0x7
ffffffffc02006ea:	92a58593          	addi	a1,a1,-1750 # ffffffffc0207010 <free_buddy>
ffffffffc02006ee:	00002517          	auipc	a0,0x2
ffffffffc02006f2:	b4a50513          	addi	a0,a0,-1206 # ffffffffc0202238 <etext+0x2ca>
ffffffffc02006f6:	ed5ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02006fa:	00007597          	auipc	a1,0x7
ffffffffc02006fe:	e7658593          	addi	a1,a1,-394 # ffffffffc0207570 <end>
ffffffffc0200702:	00002517          	auipc	a0,0x2
ffffffffc0200706:	b5650513          	addi	a0,a0,-1194 # ffffffffc0202258 <etext+0x2ea>
ffffffffc020070a:	ec1ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc020070e:	00007597          	auipc	a1,0x7
ffffffffc0200712:	26158593          	addi	a1,a1,609 # ffffffffc020796f <end+0x3ff>
ffffffffc0200716:	00000797          	auipc	a5,0x0
ffffffffc020071a:	c2678793          	addi	a5,a5,-986 # ffffffffc020033c <kern_init>
ffffffffc020071e:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200722:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc0200726:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200728:	3ff5f593          	andi	a1,a1,1023
ffffffffc020072c:	95be                	add	a1,a1,a5
ffffffffc020072e:	85a9                	srai	a1,a1,0xa
ffffffffc0200730:	00002517          	auipc	a0,0x2
ffffffffc0200734:	b4850513          	addi	a0,a0,-1208 # ffffffffc0202278 <etext+0x30a>
}
ffffffffc0200738:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020073a:	bd41                	j	ffffffffc02005ca <cprintf>

ffffffffc020073c <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc020073c:	1141                	addi	sp,sp,-16

    panic("Not Implemented!");
ffffffffc020073e:	00002617          	auipc	a2,0x2
ffffffffc0200742:	b6a60613          	addi	a2,a2,-1174 # ffffffffc02022a8 <etext+0x33a>
ffffffffc0200746:	04e00593          	li	a1,78
ffffffffc020074a:	00002517          	auipc	a0,0x2
ffffffffc020074e:	b7650513          	addi	a0,a0,-1162 # ffffffffc02022c0 <etext+0x352>
void print_stackframe(void) {
ffffffffc0200752:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200754:	effff0ef          	jal	ra,ffffffffc0200652 <__panic>

ffffffffc0200758 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200758:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020075a:	00002617          	auipc	a2,0x2
ffffffffc020075e:	b7e60613          	addi	a2,a2,-1154 # ffffffffc02022d8 <etext+0x36a>
ffffffffc0200762:	00002597          	auipc	a1,0x2
ffffffffc0200766:	b9658593          	addi	a1,a1,-1130 # ffffffffc02022f8 <etext+0x38a>
ffffffffc020076a:	00002517          	auipc	a0,0x2
ffffffffc020076e:	b9650513          	addi	a0,a0,-1130 # ffffffffc0202300 <etext+0x392>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200772:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200774:	e57ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
ffffffffc0200778:	00002617          	auipc	a2,0x2
ffffffffc020077c:	b9860613          	addi	a2,a2,-1128 # ffffffffc0202310 <etext+0x3a2>
ffffffffc0200780:	00002597          	auipc	a1,0x2
ffffffffc0200784:	bb858593          	addi	a1,a1,-1096 # ffffffffc0202338 <etext+0x3ca>
ffffffffc0200788:	00002517          	auipc	a0,0x2
ffffffffc020078c:	b7850513          	addi	a0,a0,-1160 # ffffffffc0202300 <etext+0x392>
ffffffffc0200790:	e3bff0ef          	jal	ra,ffffffffc02005ca <cprintf>
ffffffffc0200794:	00002617          	auipc	a2,0x2
ffffffffc0200798:	bb460613          	addi	a2,a2,-1100 # ffffffffc0202348 <etext+0x3da>
ffffffffc020079c:	00002597          	auipc	a1,0x2
ffffffffc02007a0:	bcc58593          	addi	a1,a1,-1076 # ffffffffc0202368 <etext+0x3fa>
ffffffffc02007a4:	00002517          	auipc	a0,0x2
ffffffffc02007a8:	b5c50513          	addi	a0,a0,-1188 # ffffffffc0202300 <etext+0x392>
ffffffffc02007ac:	e1fff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    }
    return 0;
}
ffffffffc02007b0:	60a2                	ld	ra,8(sp)
ffffffffc02007b2:	4501                	li	a0,0
ffffffffc02007b4:	0141                	addi	sp,sp,16
ffffffffc02007b6:	8082                	ret

ffffffffc02007b8 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc02007b8:	1141                	addi	sp,sp,-16
ffffffffc02007ba:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc02007bc:	ef3ff0ef          	jal	ra,ffffffffc02006ae <print_kerninfo>
    return 0;
}
ffffffffc02007c0:	60a2                	ld	ra,8(sp)
ffffffffc02007c2:	4501                	li	a0,0
ffffffffc02007c4:	0141                	addi	sp,sp,16
ffffffffc02007c6:	8082                	ret

ffffffffc02007c8 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc02007c8:	1141                	addi	sp,sp,-16
ffffffffc02007ca:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc02007cc:	f71ff0ef          	jal	ra,ffffffffc020073c <print_stackframe>
    return 0;
}
ffffffffc02007d0:	60a2                	ld	ra,8(sp)
ffffffffc02007d2:	4501                	li	a0,0
ffffffffc02007d4:	0141                	addi	sp,sp,16
ffffffffc02007d6:	8082                	ret

ffffffffc02007d8 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc02007d8:	7115                	addi	sp,sp,-224
ffffffffc02007da:	ed5e                	sd	s7,152(sp)
ffffffffc02007dc:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02007de:	00002517          	auipc	a0,0x2
ffffffffc02007e2:	b9a50513          	addi	a0,a0,-1126 # ffffffffc0202378 <etext+0x40a>
kmonitor(struct trapframe *tf) {
ffffffffc02007e6:	ed86                	sd	ra,216(sp)
ffffffffc02007e8:	e9a2                	sd	s0,208(sp)
ffffffffc02007ea:	e5a6                	sd	s1,200(sp)
ffffffffc02007ec:	e1ca                	sd	s2,192(sp)
ffffffffc02007ee:	fd4e                	sd	s3,184(sp)
ffffffffc02007f0:	f952                	sd	s4,176(sp)
ffffffffc02007f2:	f556                	sd	s5,168(sp)
ffffffffc02007f4:	f15a                	sd	s6,160(sp)
ffffffffc02007f6:	e962                	sd	s8,144(sp)
ffffffffc02007f8:	e566                	sd	s9,136(sp)
ffffffffc02007fa:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02007fc:	dcfff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200800:	00002517          	auipc	a0,0x2
ffffffffc0200804:	ba050513          	addi	a0,a0,-1120 # ffffffffc02023a0 <etext+0x432>
ffffffffc0200808:	dc3ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    if (tf != NULL) {
ffffffffc020080c:	000b8563          	beqz	s7,ffffffffc0200816 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc0200810:	855e                	mv	a0,s7
ffffffffc0200812:	348000ef          	jal	ra,ffffffffc0200b5a <print_trapframe>
ffffffffc0200816:	00002c17          	auipc	s8,0x2
ffffffffc020081a:	bfac0c13          	addi	s8,s8,-1030 # ffffffffc0202410 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc020081e:	00002917          	auipc	s2,0x2
ffffffffc0200822:	baa90913          	addi	s2,s2,-1110 # ffffffffc02023c8 <etext+0x45a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200826:	00002497          	auipc	s1,0x2
ffffffffc020082a:	baa48493          	addi	s1,s1,-1110 # ffffffffc02023d0 <etext+0x462>
        if (argc == MAXARGS - 1) {
ffffffffc020082e:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200830:	00002b17          	auipc	s6,0x2
ffffffffc0200834:	ba8b0b13          	addi	s6,s6,-1112 # ffffffffc02023d8 <etext+0x46a>
        argv[argc ++] = buf;
ffffffffc0200838:	00002a17          	auipc	s4,0x2
ffffffffc020083c:	ac0a0a13          	addi	s4,s4,-1344 # ffffffffc02022f8 <etext+0x38a>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200840:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200842:	854a                	mv	a0,s2
ffffffffc0200844:	626010ef          	jal	ra,ffffffffc0201e6a <readline>
ffffffffc0200848:	842a                	mv	s0,a0
ffffffffc020084a:	dd65                	beqz	a0,ffffffffc0200842 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020084c:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200850:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200852:	e1bd                	bnez	a1,ffffffffc02008b8 <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc0200854:	fe0c87e3          	beqz	s9,ffffffffc0200842 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200858:	6582                	ld	a1,0(sp)
ffffffffc020085a:	00002d17          	auipc	s10,0x2
ffffffffc020085e:	bb6d0d13          	addi	s10,s10,-1098 # ffffffffc0202410 <commands>
        argv[argc ++] = buf;
ffffffffc0200862:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200864:	4401                	li	s0,0
ffffffffc0200866:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200868:	1ce010ef          	jal	ra,ffffffffc0201a36 <strcmp>
ffffffffc020086c:	c919                	beqz	a0,ffffffffc0200882 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020086e:	2405                	addiw	s0,s0,1
ffffffffc0200870:	0b540063          	beq	s0,s5,ffffffffc0200910 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200874:	000d3503          	ld	a0,0(s10)
ffffffffc0200878:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020087a:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020087c:	1ba010ef          	jal	ra,ffffffffc0201a36 <strcmp>
ffffffffc0200880:	f57d                	bnez	a0,ffffffffc020086e <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200882:	00141793          	slli	a5,s0,0x1
ffffffffc0200886:	97a2                	add	a5,a5,s0
ffffffffc0200888:	078e                	slli	a5,a5,0x3
ffffffffc020088a:	97e2                	add	a5,a5,s8
ffffffffc020088c:	6b9c                	ld	a5,16(a5)
ffffffffc020088e:	865e                	mv	a2,s7
ffffffffc0200890:	002c                	addi	a1,sp,8
ffffffffc0200892:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200896:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200898:	fa0555e3          	bgez	a0,ffffffffc0200842 <kmonitor+0x6a>
}
ffffffffc020089c:	60ee                	ld	ra,216(sp)
ffffffffc020089e:	644e                	ld	s0,208(sp)
ffffffffc02008a0:	64ae                	ld	s1,200(sp)
ffffffffc02008a2:	690e                	ld	s2,192(sp)
ffffffffc02008a4:	79ea                	ld	s3,184(sp)
ffffffffc02008a6:	7a4a                	ld	s4,176(sp)
ffffffffc02008a8:	7aaa                	ld	s5,168(sp)
ffffffffc02008aa:	7b0a                	ld	s6,160(sp)
ffffffffc02008ac:	6bea                	ld	s7,152(sp)
ffffffffc02008ae:	6c4a                	ld	s8,144(sp)
ffffffffc02008b0:	6caa                	ld	s9,136(sp)
ffffffffc02008b2:	6d0a                	ld	s10,128(sp)
ffffffffc02008b4:	612d                	addi	sp,sp,224
ffffffffc02008b6:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02008b8:	8526                	mv	a0,s1
ffffffffc02008ba:	19a010ef          	jal	ra,ffffffffc0201a54 <strchr>
ffffffffc02008be:	c901                	beqz	a0,ffffffffc02008ce <kmonitor+0xf6>
ffffffffc02008c0:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc02008c4:	00040023          	sb	zero,0(s0)
ffffffffc02008c8:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02008ca:	d5c9                	beqz	a1,ffffffffc0200854 <kmonitor+0x7c>
ffffffffc02008cc:	b7f5                	j	ffffffffc02008b8 <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc02008ce:	00044783          	lbu	a5,0(s0)
ffffffffc02008d2:	d3c9                	beqz	a5,ffffffffc0200854 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc02008d4:	033c8963          	beq	s9,s3,ffffffffc0200906 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc02008d8:	003c9793          	slli	a5,s9,0x3
ffffffffc02008dc:	0118                	addi	a4,sp,128
ffffffffc02008de:	97ba                	add	a5,a5,a4
ffffffffc02008e0:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02008e4:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc02008e8:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02008ea:	e591                	bnez	a1,ffffffffc02008f6 <kmonitor+0x11e>
ffffffffc02008ec:	b7b5                	j	ffffffffc0200858 <kmonitor+0x80>
ffffffffc02008ee:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02008f2:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02008f4:	d1a5                	beqz	a1,ffffffffc0200854 <kmonitor+0x7c>
ffffffffc02008f6:	8526                	mv	a0,s1
ffffffffc02008f8:	15c010ef          	jal	ra,ffffffffc0201a54 <strchr>
ffffffffc02008fc:	d96d                	beqz	a0,ffffffffc02008ee <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02008fe:	00044583          	lbu	a1,0(s0)
ffffffffc0200902:	d9a9                	beqz	a1,ffffffffc0200854 <kmonitor+0x7c>
ffffffffc0200904:	bf55                	j	ffffffffc02008b8 <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc0200906:	45c1                	li	a1,16
ffffffffc0200908:	855a                	mv	a0,s6
ffffffffc020090a:	cc1ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
ffffffffc020090e:	b7e9                	j	ffffffffc02008d8 <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200910:	6582                	ld	a1,0(sp)
ffffffffc0200912:	00002517          	auipc	a0,0x2
ffffffffc0200916:	ae650513          	addi	a0,a0,-1306 # ffffffffc02023f8 <etext+0x48a>
ffffffffc020091a:	cb1ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    return 0;
ffffffffc020091e:	b715                	j	ffffffffc0200842 <kmonitor+0x6a>

ffffffffc0200920 <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc0200920:	1141                	addi	sp,sp,-16
ffffffffc0200922:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200924:	02000793          	li	a5,32
ffffffffc0200928:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020092c:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200930:	67e1                	lui	a5,0x18
ffffffffc0200932:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200936:	953e                	add	a0,a0,a5
ffffffffc0200938:	600010ef          	jal	ra,ffffffffc0201f38 <sbi_set_timer>
}
ffffffffc020093c:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020093e:	00007797          	auipc	a5,0x7
ffffffffc0200942:	be07b523          	sd	zero,-1046(a5) # ffffffffc0207528 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200946:	00002517          	auipc	a0,0x2
ffffffffc020094a:	b1250513          	addi	a0,a0,-1262 # ffffffffc0202458 <commands+0x48>
}
ffffffffc020094e:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc0200950:	b9ad                	j	ffffffffc02005ca <cprintf>

ffffffffc0200952 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200952:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200956:	67e1                	lui	a5,0x18
ffffffffc0200958:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020095c:	953e                	add	a0,a0,a5
ffffffffc020095e:	5da0106f          	j	ffffffffc0201f38 <sbi_set_timer>

ffffffffc0200962 <cons_init>:
ffffffffc0200962:	8082                	ret

ffffffffc0200964 <cons_putc>:
ffffffffc0200964:	0ff57513          	zext.b	a0,a0
ffffffffc0200968:	5b60106f          	j	ffffffffc0201f1e <sbi_console_putchar>

ffffffffc020096c <cons_getc>:
ffffffffc020096c:	5e60106f          	j	ffffffffc0201f52 <sbi_console_getchar>

ffffffffc0200970 <intr_enable>:
ffffffffc0200970:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200974:	8082                	ret

ffffffffc0200976 <intr_disable>:
ffffffffc0200976:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020097a:	8082                	ret

ffffffffc020097c <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020097c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200980:	00000797          	auipc	a5,0x0
ffffffffc0200984:	2f078793          	addi	a5,a5,752 # ffffffffc0200c70 <__alltraps>
ffffffffc0200988:	10579073          	csrw	stvec,a5
}
ffffffffc020098c:	8082                	ret

ffffffffc020098e <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020098e:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200990:	1141                	addi	sp,sp,-16
ffffffffc0200992:	e022                	sd	s0,0(sp)
ffffffffc0200994:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200996:	00002517          	auipc	a0,0x2
ffffffffc020099a:	ae250513          	addi	a0,a0,-1310 # ffffffffc0202478 <commands+0x68>
void print_regs(struct pushregs *gpr) {
ffffffffc020099e:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02009a0:	c2bff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02009a4:	640c                	ld	a1,8(s0)
ffffffffc02009a6:	00002517          	auipc	a0,0x2
ffffffffc02009aa:	aea50513          	addi	a0,a0,-1302 # ffffffffc0202490 <commands+0x80>
ffffffffc02009ae:	c1dff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02009b2:	680c                	ld	a1,16(s0)
ffffffffc02009b4:	00002517          	auipc	a0,0x2
ffffffffc02009b8:	af450513          	addi	a0,a0,-1292 # ffffffffc02024a8 <commands+0x98>
ffffffffc02009bc:	c0fff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02009c0:	6c0c                	ld	a1,24(s0)
ffffffffc02009c2:	00002517          	auipc	a0,0x2
ffffffffc02009c6:	afe50513          	addi	a0,a0,-1282 # ffffffffc02024c0 <commands+0xb0>
ffffffffc02009ca:	c01ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02009ce:	700c                	ld	a1,32(s0)
ffffffffc02009d0:	00002517          	auipc	a0,0x2
ffffffffc02009d4:	b0850513          	addi	a0,a0,-1272 # ffffffffc02024d8 <commands+0xc8>
ffffffffc02009d8:	bf3ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02009dc:	740c                	ld	a1,40(s0)
ffffffffc02009de:	00002517          	auipc	a0,0x2
ffffffffc02009e2:	b1250513          	addi	a0,a0,-1262 # ffffffffc02024f0 <commands+0xe0>
ffffffffc02009e6:	be5ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02009ea:	780c                	ld	a1,48(s0)
ffffffffc02009ec:	00002517          	auipc	a0,0x2
ffffffffc02009f0:	b1c50513          	addi	a0,a0,-1252 # ffffffffc0202508 <commands+0xf8>
ffffffffc02009f4:	bd7ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02009f8:	7c0c                	ld	a1,56(s0)
ffffffffc02009fa:	00002517          	auipc	a0,0x2
ffffffffc02009fe:	b2650513          	addi	a0,a0,-1242 # ffffffffc0202520 <commands+0x110>
ffffffffc0200a02:	bc9ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200a06:	602c                	ld	a1,64(s0)
ffffffffc0200a08:	00002517          	auipc	a0,0x2
ffffffffc0200a0c:	b3050513          	addi	a0,a0,-1232 # ffffffffc0202538 <commands+0x128>
ffffffffc0200a10:	bbbff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200a14:	642c                	ld	a1,72(s0)
ffffffffc0200a16:	00002517          	auipc	a0,0x2
ffffffffc0200a1a:	b3a50513          	addi	a0,a0,-1222 # ffffffffc0202550 <commands+0x140>
ffffffffc0200a1e:	badff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200a22:	682c                	ld	a1,80(s0)
ffffffffc0200a24:	00002517          	auipc	a0,0x2
ffffffffc0200a28:	b4450513          	addi	a0,a0,-1212 # ffffffffc0202568 <commands+0x158>
ffffffffc0200a2c:	b9fff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200a30:	6c2c                	ld	a1,88(s0)
ffffffffc0200a32:	00002517          	auipc	a0,0x2
ffffffffc0200a36:	b4e50513          	addi	a0,a0,-1202 # ffffffffc0202580 <commands+0x170>
ffffffffc0200a3a:	b91ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200a3e:	702c                	ld	a1,96(s0)
ffffffffc0200a40:	00002517          	auipc	a0,0x2
ffffffffc0200a44:	b5850513          	addi	a0,a0,-1192 # ffffffffc0202598 <commands+0x188>
ffffffffc0200a48:	b83ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200a4c:	742c                	ld	a1,104(s0)
ffffffffc0200a4e:	00002517          	auipc	a0,0x2
ffffffffc0200a52:	b6250513          	addi	a0,a0,-1182 # ffffffffc02025b0 <commands+0x1a0>
ffffffffc0200a56:	b75ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200a5a:	782c                	ld	a1,112(s0)
ffffffffc0200a5c:	00002517          	auipc	a0,0x2
ffffffffc0200a60:	b6c50513          	addi	a0,a0,-1172 # ffffffffc02025c8 <commands+0x1b8>
ffffffffc0200a64:	b67ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a68:	7c2c                	ld	a1,120(s0)
ffffffffc0200a6a:	00002517          	auipc	a0,0x2
ffffffffc0200a6e:	b7650513          	addi	a0,a0,-1162 # ffffffffc02025e0 <commands+0x1d0>
ffffffffc0200a72:	b59ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a76:	604c                	ld	a1,128(s0)
ffffffffc0200a78:	00002517          	auipc	a0,0x2
ffffffffc0200a7c:	b8050513          	addi	a0,a0,-1152 # ffffffffc02025f8 <commands+0x1e8>
ffffffffc0200a80:	b4bff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a84:	644c                	ld	a1,136(s0)
ffffffffc0200a86:	00002517          	auipc	a0,0x2
ffffffffc0200a8a:	b8a50513          	addi	a0,a0,-1142 # ffffffffc0202610 <commands+0x200>
ffffffffc0200a8e:	b3dff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a92:	684c                	ld	a1,144(s0)
ffffffffc0200a94:	00002517          	auipc	a0,0x2
ffffffffc0200a98:	b9450513          	addi	a0,a0,-1132 # ffffffffc0202628 <commands+0x218>
ffffffffc0200a9c:	b2fff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200aa0:	6c4c                	ld	a1,152(s0)
ffffffffc0200aa2:	00002517          	auipc	a0,0x2
ffffffffc0200aa6:	b9e50513          	addi	a0,a0,-1122 # ffffffffc0202640 <commands+0x230>
ffffffffc0200aaa:	b21ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200aae:	704c                	ld	a1,160(s0)
ffffffffc0200ab0:	00002517          	auipc	a0,0x2
ffffffffc0200ab4:	ba850513          	addi	a0,a0,-1112 # ffffffffc0202658 <commands+0x248>
ffffffffc0200ab8:	b13ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200abc:	744c                	ld	a1,168(s0)
ffffffffc0200abe:	00002517          	auipc	a0,0x2
ffffffffc0200ac2:	bb250513          	addi	a0,a0,-1102 # ffffffffc0202670 <commands+0x260>
ffffffffc0200ac6:	b05ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200aca:	784c                	ld	a1,176(s0)
ffffffffc0200acc:	00002517          	auipc	a0,0x2
ffffffffc0200ad0:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0202688 <commands+0x278>
ffffffffc0200ad4:	af7ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200ad8:	7c4c                	ld	a1,184(s0)
ffffffffc0200ada:	00002517          	auipc	a0,0x2
ffffffffc0200ade:	bc650513          	addi	a0,a0,-1082 # ffffffffc02026a0 <commands+0x290>
ffffffffc0200ae2:	ae9ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200ae6:	606c                	ld	a1,192(s0)
ffffffffc0200ae8:	00002517          	auipc	a0,0x2
ffffffffc0200aec:	bd050513          	addi	a0,a0,-1072 # ffffffffc02026b8 <commands+0x2a8>
ffffffffc0200af0:	adbff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200af4:	646c                	ld	a1,200(s0)
ffffffffc0200af6:	00002517          	auipc	a0,0x2
ffffffffc0200afa:	bda50513          	addi	a0,a0,-1062 # ffffffffc02026d0 <commands+0x2c0>
ffffffffc0200afe:	acdff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200b02:	686c                	ld	a1,208(s0)
ffffffffc0200b04:	00002517          	auipc	a0,0x2
ffffffffc0200b08:	be450513          	addi	a0,a0,-1052 # ffffffffc02026e8 <commands+0x2d8>
ffffffffc0200b0c:	abfff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200b10:	6c6c                	ld	a1,216(s0)
ffffffffc0200b12:	00002517          	auipc	a0,0x2
ffffffffc0200b16:	bee50513          	addi	a0,a0,-1042 # ffffffffc0202700 <commands+0x2f0>
ffffffffc0200b1a:	ab1ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200b1e:	706c                	ld	a1,224(s0)
ffffffffc0200b20:	00002517          	auipc	a0,0x2
ffffffffc0200b24:	bf850513          	addi	a0,a0,-1032 # ffffffffc0202718 <commands+0x308>
ffffffffc0200b28:	aa3ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200b2c:	746c                	ld	a1,232(s0)
ffffffffc0200b2e:	00002517          	auipc	a0,0x2
ffffffffc0200b32:	c0250513          	addi	a0,a0,-1022 # ffffffffc0202730 <commands+0x320>
ffffffffc0200b36:	a95ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200b3a:	786c                	ld	a1,240(s0)
ffffffffc0200b3c:	00002517          	auipc	a0,0x2
ffffffffc0200b40:	c0c50513          	addi	a0,a0,-1012 # ffffffffc0202748 <commands+0x338>
ffffffffc0200b44:	a87ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b48:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200b4a:	6402                	ld	s0,0(sp)
ffffffffc0200b4c:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b4e:	00002517          	auipc	a0,0x2
ffffffffc0200b52:	c1250513          	addi	a0,a0,-1006 # ffffffffc0202760 <commands+0x350>
}
ffffffffc0200b56:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200b58:	bc8d                	j	ffffffffc02005ca <cprintf>

ffffffffc0200b5a <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc0200b5a:	1141                	addi	sp,sp,-16
ffffffffc0200b5c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b5e:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc0200b60:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b62:	00002517          	auipc	a0,0x2
ffffffffc0200b66:	c1650513          	addi	a0,a0,-1002 # ffffffffc0202778 <commands+0x368>
void print_trapframe(struct trapframe *tf) {
ffffffffc0200b6a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b6c:	a5fff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b70:	8522                	mv	a0,s0
ffffffffc0200b72:	e1dff0ef          	jal	ra,ffffffffc020098e <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b76:	10043583          	ld	a1,256(s0)
ffffffffc0200b7a:	00002517          	auipc	a0,0x2
ffffffffc0200b7e:	c1650513          	addi	a0,a0,-1002 # ffffffffc0202790 <commands+0x380>
ffffffffc0200b82:	a49ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b86:	10843583          	ld	a1,264(s0)
ffffffffc0200b8a:	00002517          	auipc	a0,0x2
ffffffffc0200b8e:	c1e50513          	addi	a0,a0,-994 # ffffffffc02027a8 <commands+0x398>
ffffffffc0200b92:	a39ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200b96:	11043583          	ld	a1,272(s0)
ffffffffc0200b9a:	00002517          	auipc	a0,0x2
ffffffffc0200b9e:	c2650513          	addi	a0,a0,-986 # ffffffffc02027c0 <commands+0x3b0>
ffffffffc0200ba2:	a29ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200ba6:	11843583          	ld	a1,280(s0)
}
ffffffffc0200baa:	6402                	ld	s0,0(sp)
ffffffffc0200bac:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bae:	00002517          	auipc	a0,0x2
ffffffffc0200bb2:	c2a50513          	addi	a0,a0,-982 # ffffffffc02027d8 <commands+0x3c8>
}
ffffffffc0200bb6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200bb8:	bc09                	j	ffffffffc02005ca <cprintf>

ffffffffc0200bba <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200bba:	11853783          	ld	a5,280(a0)
ffffffffc0200bbe:	472d                	li	a4,11
ffffffffc0200bc0:	0786                	slli	a5,a5,0x1
ffffffffc0200bc2:	8385                	srli	a5,a5,0x1
ffffffffc0200bc4:	08f76063          	bltu	a4,a5,ffffffffc0200c44 <interrupt_handler+0x8a>
ffffffffc0200bc8:	00002717          	auipc	a4,0x2
ffffffffc0200bcc:	cf070713          	addi	a4,a4,-784 # ffffffffc02028b8 <commands+0x4a8>
ffffffffc0200bd0:	078a                	slli	a5,a5,0x2
ffffffffc0200bd2:	97ba                	add	a5,a5,a4
ffffffffc0200bd4:	439c                	lw	a5,0(a5)
ffffffffc0200bd6:	97ba                	add	a5,a5,a4
ffffffffc0200bd8:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200bda:	00002517          	auipc	a0,0x2
ffffffffc0200bde:	c7650513          	addi	a0,a0,-906 # ffffffffc0202850 <commands+0x440>
ffffffffc0200be2:	b2e5                	j	ffffffffc02005ca <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200be4:	00002517          	auipc	a0,0x2
ffffffffc0200be8:	c4c50513          	addi	a0,a0,-948 # ffffffffc0202830 <commands+0x420>
ffffffffc0200bec:	baf9                	j	ffffffffc02005ca <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200bee:	00002517          	auipc	a0,0x2
ffffffffc0200bf2:	c0250513          	addi	a0,a0,-1022 # ffffffffc02027f0 <commands+0x3e0>
ffffffffc0200bf6:	9d5ff06f          	j	ffffffffc02005ca <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200bfa:	00002517          	auipc	a0,0x2
ffffffffc0200bfe:	c7650513          	addi	a0,a0,-906 # ffffffffc0202870 <commands+0x460>
ffffffffc0200c02:	9c9ff06f          	j	ffffffffc02005ca <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200c06:	1141                	addi	sp,sp,-16
ffffffffc0200c08:	e406                	sd	ra,8(sp)
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            // "sip寄存器中除了SSIP和USIP之外的所有位都是只读的。" 
	    // 实际上，调用sbi_set_timer函数将会清除STIP,或者你可以直接清除它。
            clock_set_next_event();
ffffffffc0200c0a:	d49ff0ef          	jal	ra,ffffffffc0200952 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200c0e:	00007697          	auipc	a3,0x7
ffffffffc0200c12:	91a68693          	addi	a3,a3,-1766 # ffffffffc0207528 <ticks>
ffffffffc0200c16:	629c                	ld	a5,0(a3)
ffffffffc0200c18:	06400713          	li	a4,100
ffffffffc0200c1c:	0785                	addi	a5,a5,1
ffffffffc0200c1e:	02e7f733          	remu	a4,a5,a4
ffffffffc0200c22:	e29c                	sd	a5,0(a3)
ffffffffc0200c24:	c30d                	beqz	a4,ffffffffc0200c46 <interrupt_handler+0x8c>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200c26:	60a2                	ld	ra,8(sp)
ffffffffc0200c28:	0141                	addi	sp,sp,16
ffffffffc0200c2a:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200c2c:	00002517          	auipc	a0,0x2
ffffffffc0200c30:	c6c50513          	addi	a0,a0,-916 # ffffffffc0202898 <commands+0x488>
ffffffffc0200c34:	997ff06f          	j	ffffffffc02005ca <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200c38:	00002517          	auipc	a0,0x2
ffffffffc0200c3c:	bd850513          	addi	a0,a0,-1064 # ffffffffc0202810 <commands+0x400>
ffffffffc0200c40:	98bff06f          	j	ffffffffc02005ca <cprintf>
            print_trapframe(tf);
ffffffffc0200c44:	bf19                	j	ffffffffc0200b5a <print_trapframe>
}
ffffffffc0200c46:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c48:	06400593          	li	a1,100
ffffffffc0200c4c:	00002517          	auipc	a0,0x2
ffffffffc0200c50:	c3c50513          	addi	a0,a0,-964 # ffffffffc0202888 <commands+0x478>
}
ffffffffc0200c54:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200c56:	975ff06f          	j	ffffffffc02005ca <cprintf>

ffffffffc0200c5a <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c5a:	11853783          	ld	a5,280(a0)
ffffffffc0200c5e:	0007c763          	bltz	a5,ffffffffc0200c6c <trap+0x12>
    switch (tf->cause) {
ffffffffc0200c62:	472d                	li	a4,11
ffffffffc0200c64:	00f76363          	bltu	a4,a5,ffffffffc0200c6a <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc0200c68:	8082                	ret
            print_trapframe(tf);
ffffffffc0200c6a:	bdc5                	j	ffffffffc0200b5a <print_trapframe>
        interrupt_handler(tf);
ffffffffc0200c6c:	b7b9                	j	ffffffffc0200bba <interrupt_handler>
	...

ffffffffc0200c70 <__alltraps>:
ffffffffc0200c70:	14011073          	csrw	sscratch,sp
ffffffffc0200c74:	712d                	addi	sp,sp,-288
ffffffffc0200c76:	e002                	sd	zero,0(sp)
ffffffffc0200c78:	e406                	sd	ra,8(sp)
ffffffffc0200c7a:	ec0e                	sd	gp,24(sp)
ffffffffc0200c7c:	f012                	sd	tp,32(sp)
ffffffffc0200c7e:	f416                	sd	t0,40(sp)
ffffffffc0200c80:	f81a                	sd	t1,48(sp)
ffffffffc0200c82:	fc1e                	sd	t2,56(sp)
ffffffffc0200c84:	e0a2                	sd	s0,64(sp)
ffffffffc0200c86:	e4a6                	sd	s1,72(sp)
ffffffffc0200c88:	e8aa                	sd	a0,80(sp)
ffffffffc0200c8a:	ecae                	sd	a1,88(sp)
ffffffffc0200c8c:	f0b2                	sd	a2,96(sp)
ffffffffc0200c8e:	f4b6                	sd	a3,104(sp)
ffffffffc0200c90:	f8ba                	sd	a4,112(sp)
ffffffffc0200c92:	fcbe                	sd	a5,120(sp)
ffffffffc0200c94:	e142                	sd	a6,128(sp)
ffffffffc0200c96:	e546                	sd	a7,136(sp)
ffffffffc0200c98:	e94a                	sd	s2,144(sp)
ffffffffc0200c9a:	ed4e                	sd	s3,152(sp)
ffffffffc0200c9c:	f152                	sd	s4,160(sp)
ffffffffc0200c9e:	f556                	sd	s5,168(sp)
ffffffffc0200ca0:	f95a                	sd	s6,176(sp)
ffffffffc0200ca2:	fd5e                	sd	s7,184(sp)
ffffffffc0200ca4:	e1e2                	sd	s8,192(sp)
ffffffffc0200ca6:	e5e6                	sd	s9,200(sp)
ffffffffc0200ca8:	e9ea                	sd	s10,208(sp)
ffffffffc0200caa:	edee                	sd	s11,216(sp)
ffffffffc0200cac:	f1f2                	sd	t3,224(sp)
ffffffffc0200cae:	f5f6                	sd	t4,232(sp)
ffffffffc0200cb0:	f9fa                	sd	t5,240(sp)
ffffffffc0200cb2:	fdfe                	sd	t6,248(sp)
ffffffffc0200cb4:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200cb8:	100024f3          	csrr	s1,sstatus
ffffffffc0200cbc:	14102973          	csrr	s2,sepc
ffffffffc0200cc0:	143029f3          	csrr	s3,stval
ffffffffc0200cc4:	14202a73          	csrr	s4,scause
ffffffffc0200cc8:	e822                	sd	s0,16(sp)
ffffffffc0200cca:	e226                	sd	s1,256(sp)
ffffffffc0200ccc:	e64a                	sd	s2,264(sp)
ffffffffc0200cce:	ea4e                	sd	s3,272(sp)
ffffffffc0200cd0:	ee52                	sd	s4,280(sp)
ffffffffc0200cd2:	850a                	mv	a0,sp
ffffffffc0200cd4:	f87ff0ef          	jal	ra,ffffffffc0200c5a <trap>

ffffffffc0200cd8 <__trapret>:
ffffffffc0200cd8:	6492                	ld	s1,256(sp)
ffffffffc0200cda:	6932                	ld	s2,264(sp)
ffffffffc0200cdc:	10049073          	csrw	sstatus,s1
ffffffffc0200ce0:	14191073          	csrw	sepc,s2
ffffffffc0200ce4:	60a2                	ld	ra,8(sp)
ffffffffc0200ce6:	61e2                	ld	gp,24(sp)
ffffffffc0200ce8:	7202                	ld	tp,32(sp)
ffffffffc0200cea:	72a2                	ld	t0,40(sp)
ffffffffc0200cec:	7342                	ld	t1,48(sp)
ffffffffc0200cee:	73e2                	ld	t2,56(sp)
ffffffffc0200cf0:	6406                	ld	s0,64(sp)
ffffffffc0200cf2:	64a6                	ld	s1,72(sp)
ffffffffc0200cf4:	6546                	ld	a0,80(sp)
ffffffffc0200cf6:	65e6                	ld	a1,88(sp)
ffffffffc0200cf8:	7606                	ld	a2,96(sp)
ffffffffc0200cfa:	76a6                	ld	a3,104(sp)
ffffffffc0200cfc:	7746                	ld	a4,112(sp)
ffffffffc0200cfe:	77e6                	ld	a5,120(sp)
ffffffffc0200d00:	680a                	ld	a6,128(sp)
ffffffffc0200d02:	68aa                	ld	a7,136(sp)
ffffffffc0200d04:	694a                	ld	s2,144(sp)
ffffffffc0200d06:	69ea                	ld	s3,152(sp)
ffffffffc0200d08:	7a0a                	ld	s4,160(sp)
ffffffffc0200d0a:	7aaa                	ld	s5,168(sp)
ffffffffc0200d0c:	7b4a                	ld	s6,176(sp)
ffffffffc0200d0e:	7bea                	ld	s7,184(sp)
ffffffffc0200d10:	6c0e                	ld	s8,192(sp)
ffffffffc0200d12:	6cae                	ld	s9,200(sp)
ffffffffc0200d14:	6d4e                	ld	s10,208(sp)
ffffffffc0200d16:	6dee                	ld	s11,216(sp)
ffffffffc0200d18:	7e0e                	ld	t3,224(sp)
ffffffffc0200d1a:	7eae                	ld	t4,232(sp)
ffffffffc0200d1c:	7f4e                	ld	t5,240(sp)
ffffffffc0200d1e:	7fee                	ld	t6,248(sp)
ffffffffc0200d20:	6142                	ld	sp,16(sp)
ffffffffc0200d22:	10200073          	sret

ffffffffc0200d26 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200d26:	100027f3          	csrr	a5,sstatus
ffffffffc0200d2a:	8b89                	andi	a5,a5,2
ffffffffc0200d2c:	e799                	bnez	a5,ffffffffc0200d3a <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0200d2e:	00007797          	auipc	a5,0x7
ffffffffc0200d32:	81a7b783          	ld	a5,-2022(a5) # ffffffffc0207548 <pmm_manager>
ffffffffc0200d36:	6f9c                	ld	a5,24(a5)
ffffffffc0200d38:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc0200d3a:	1141                	addi	sp,sp,-16
ffffffffc0200d3c:	e406                	sd	ra,8(sp)
ffffffffc0200d3e:	e022                	sd	s0,0(sp)
ffffffffc0200d40:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0200d42:	c35ff0ef          	jal	ra,ffffffffc0200976 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0200d46:	00007797          	auipc	a5,0x7
ffffffffc0200d4a:	8027b783          	ld	a5,-2046(a5) # ffffffffc0207548 <pmm_manager>
ffffffffc0200d4e:	6f9c                	ld	a5,24(a5)
ffffffffc0200d50:	8522                	mv	a0,s0
ffffffffc0200d52:	9782                	jalr	a5
ffffffffc0200d54:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0200d56:	c1bff0ef          	jal	ra,ffffffffc0200970 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0200d5a:	60a2                	ld	ra,8(sp)
ffffffffc0200d5c:	8522                	mv	a0,s0
ffffffffc0200d5e:	6402                	ld	s0,0(sp)
ffffffffc0200d60:	0141                	addi	sp,sp,16
ffffffffc0200d62:	8082                	ret

ffffffffc0200d64 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200d64:	100027f3          	csrr	a5,sstatus
ffffffffc0200d68:	8b89                	andi	a5,a5,2
ffffffffc0200d6a:	e799                	bnez	a5,ffffffffc0200d78 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0200d6c:	00006797          	auipc	a5,0x6
ffffffffc0200d70:	7dc7b783          	ld	a5,2012(a5) # ffffffffc0207548 <pmm_manager>
ffffffffc0200d74:	739c                	ld	a5,32(a5)
ffffffffc0200d76:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc0200d78:	1101                	addi	sp,sp,-32
ffffffffc0200d7a:	ec06                	sd	ra,24(sp)
ffffffffc0200d7c:	e822                	sd	s0,16(sp)
ffffffffc0200d7e:	e426                	sd	s1,8(sp)
ffffffffc0200d80:	842a                	mv	s0,a0
ffffffffc0200d82:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0200d84:	bf3ff0ef          	jal	ra,ffffffffc0200976 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0200d88:	00006797          	auipc	a5,0x6
ffffffffc0200d8c:	7c07b783          	ld	a5,1984(a5) # ffffffffc0207548 <pmm_manager>
ffffffffc0200d90:	739c                	ld	a5,32(a5)
ffffffffc0200d92:	85a6                	mv	a1,s1
ffffffffc0200d94:	8522                	mv	a0,s0
ffffffffc0200d96:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200d98:	6442                	ld	s0,16(sp)
ffffffffc0200d9a:	60e2                	ld	ra,24(sp)
ffffffffc0200d9c:	64a2                	ld	s1,8(sp)
ffffffffc0200d9e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0200da0:	bec1                	j	ffffffffc0200970 <intr_enable>

ffffffffc0200da2 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0200da2:	100027f3          	csrr	a5,sstatus
ffffffffc0200da6:	8b89                	andi	a5,a5,2
ffffffffc0200da8:	e799                	bnez	a5,ffffffffc0200db6 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0200daa:	00006797          	auipc	a5,0x6
ffffffffc0200dae:	79e7b783          	ld	a5,1950(a5) # ffffffffc0207548 <pmm_manager>
ffffffffc0200db2:	779c                	ld	a5,40(a5)
ffffffffc0200db4:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0200db6:	1141                	addi	sp,sp,-16
ffffffffc0200db8:	e406                	sd	ra,8(sp)
ffffffffc0200dba:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0200dbc:	bbbff0ef          	jal	ra,ffffffffc0200976 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0200dc0:	00006797          	auipc	a5,0x6
ffffffffc0200dc4:	7887b783          	ld	a5,1928(a5) # ffffffffc0207548 <pmm_manager>
ffffffffc0200dc8:	779c                	ld	a5,40(a5)
ffffffffc0200dca:	9782                	jalr	a5
ffffffffc0200dcc:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0200dce:	ba3ff0ef          	jal	ra,ffffffffc0200970 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0200dd2:	60a2                	ld	ra,8(sp)
ffffffffc0200dd4:	8522                	mv	a0,s0
ffffffffc0200dd6:	6402                	ld	s0,0(sp)
ffffffffc0200dd8:	0141                	addi	sp,sp,16
ffffffffc0200dda:	8082                	ret

ffffffffc0200ddc <pmm_init>:
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200ddc:	00002797          	auipc	a5,0x2
ffffffffc0200de0:	43478793          	addi	a5,a5,1076 # ffffffffc0203210 <buddy_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200de4:	638c                	ld	a1,0(a5)
        fppn=pa2page(mem_begin)-pages+nbase;
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0200de6:	715d                	addi	sp,sp,-80
ffffffffc0200de8:	f44e                	sd	s3,40(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200dea:	00002517          	auipc	a0,0x2
ffffffffc0200dee:	afe50513          	addi	a0,a0,-1282 # ffffffffc02028e8 <commands+0x4d8>
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200df2:	00006997          	auipc	s3,0x6
ffffffffc0200df6:	75698993          	addi	s3,s3,1878 # ffffffffc0207548 <pmm_manager>
void pmm_init(void) {
ffffffffc0200dfa:	e486                	sd	ra,72(sp)
ffffffffc0200dfc:	e0a2                	sd	s0,64(sp)
ffffffffc0200dfe:	f84a                	sd	s2,48(sp)
ffffffffc0200e00:	ec56                	sd	s5,24(sp)
ffffffffc0200e02:	e85a                	sd	s6,16(sp)
    pmm_manager = &buddy_pmm_manager;
ffffffffc0200e04:	00f9b023          	sd	a5,0(s3)
void pmm_init(void) {
ffffffffc0200e08:	fc26                	sd	s1,56(sp)
ffffffffc0200e0a:	f052                	sd	s4,32(sp)
ffffffffc0200e0c:	e45e                	sd	s7,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200e0e:	fbcff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    pmm_manager->init();
ffffffffc0200e12:	0009b783          	ld	a5,0(s3)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200e16:	00006917          	auipc	s2,0x6
ffffffffc0200e1a:	74a90913          	addi	s2,s2,1866 # ffffffffc0207560 <va_pa_offset>
    npage = maxpa / PGSIZE;
ffffffffc0200e1e:	00006a97          	auipc	s5,0x6
ffffffffc0200e22:	71aa8a93          	addi	s5,s5,1818 # ffffffffc0207538 <npage>
    pmm_manager->init();
ffffffffc0200e26:	679c                	ld	a5,8(a5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200e28:	00006417          	auipc	s0,0x6
ffffffffc0200e2c:	71840413          	addi	s0,s0,1816 # ffffffffc0207540 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200e30:	fff80b37          	lui	s6,0xfff80
    pmm_manager->init();
ffffffffc0200e34:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200e36:	57f5                	li	a5,-3
ffffffffc0200e38:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0200e3a:	00002517          	auipc	a0,0x2
ffffffffc0200e3e:	ac650513          	addi	a0,a0,-1338 # ffffffffc0202900 <commands+0x4f0>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200e42:	00f93023          	sd	a5,0(s2)
    cprintf("physcial memory map:\n");
ffffffffc0200e46:	f84ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0200e4a:	46c5                	li	a3,17
ffffffffc0200e4c:	06ee                	slli	a3,a3,0x1b
ffffffffc0200e4e:	40100613          	li	a2,1025
ffffffffc0200e52:	16fd                	addi	a3,a3,-1
ffffffffc0200e54:	07e005b7          	lui	a1,0x7e00
ffffffffc0200e58:	0656                	slli	a2,a2,0x15
ffffffffc0200e5a:	00002517          	auipc	a0,0x2
ffffffffc0200e5e:	abe50513          	addi	a0,a0,-1346 # ffffffffc0202918 <commands+0x508>
ffffffffc0200e62:	f68ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200e66:	777d                	lui	a4,0xfffff
ffffffffc0200e68:	00007797          	auipc	a5,0x7
ffffffffc0200e6c:	70778793          	addi	a5,a5,1799 # ffffffffc020856f <end+0xfff>
ffffffffc0200e70:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc0200e72:	00088737          	lui	a4,0x88
ffffffffc0200e76:	00eab023          	sd	a4,0(s5)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0200e7a:	00006597          	auipc	a1,0x6
ffffffffc0200e7e:	6f658593          	addi	a1,a1,1782 # ffffffffc0207570 <end>
ffffffffc0200e82:	e01c                	sd	a5,0(s0)
ffffffffc0200e84:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200e86:	4701                	li	a4,0
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200e88:	4505                	li	a0,1
ffffffffc0200e8a:	a011                	j	ffffffffc0200e8e <pmm_init+0xb2>
        SetPageReserved(pages + i);
ffffffffc0200e8c:	601c                	ld	a5,0(s0)
ffffffffc0200e8e:	97b6                	add	a5,a5,a3
ffffffffc0200e90:	07a1                	addi	a5,a5,8
ffffffffc0200e92:	40a7b02f          	amoor.d	zero,a0,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0200e96:	000ab783          	ld	a5,0(s5)
ffffffffc0200e9a:	0705                	addi	a4,a4,1
ffffffffc0200e9c:	02868693          	addi	a3,a3,40
ffffffffc0200ea0:	01678633          	add	a2,a5,s6
ffffffffc0200ea4:	fec764e3          	bltu	a4,a2,ffffffffc0200e8c <pmm_init+0xb0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200ea8:	6004                	ld	s1,0(s0)
ffffffffc0200eaa:	00279693          	slli	a3,a5,0x2
ffffffffc0200eae:	97b6                	add	a5,a5,a3
ffffffffc0200eb0:	fec006b7          	lui	a3,0xfec00
ffffffffc0200eb4:	94b6                	add	s1,s1,a3
ffffffffc0200eb6:	078e                	slli	a5,a5,0x3
ffffffffc0200eb8:	94be                	add	s1,s1,a5
ffffffffc0200eba:	c0200bb7          	lui	s7,0xc0200
ffffffffc0200ebe:	1974ea63          	bltu	s1,s7,ffffffffc0201052 <pmm_init+0x276>
ffffffffc0200ec2:	00093783          	ld	a5,0(s2)
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200ec6:	6a05                	lui	s4,0x1
ffffffffc0200ec8:	1a7d                	addi	s4,s4,-1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0200eca:	8c9d                	sub	s1,s1,a5
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0200ecc:	9a26                	add	s4,s4,s1
ffffffffc0200ece:	777d                	lui	a4,0xfffff
ffffffffc0200ed0:	00ea7a33          	and	s4,s4,a4
    cprintf("kern_end:  0x%016lx\n", (uint64_t)PADDR(end));
ffffffffc0200ed4:	1575ef63          	bltu	a1,s7,ffffffffc0201032 <pmm_init+0x256>
ffffffffc0200ed8:	8d9d                	sub	a1,a1,a5
ffffffffc0200eda:	00002517          	auipc	a0,0x2
ffffffffc0200ede:	aa650513          	addi	a0,a0,-1370 # ffffffffc0202980 <commands+0x570>
ffffffffc0200ee2:	ee8ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("pages:     0x%016lx\n", (uint64_t)PADDR(pages));
ffffffffc0200ee6:	6014                	ld	a3,0(s0)
ffffffffc0200ee8:	1376e963          	bltu	a3,s7,ffffffffc020101a <pmm_init+0x23e>
ffffffffc0200eec:	00093583          	ld	a1,0(s2)
ffffffffc0200ef0:	00002517          	auipc	a0,0x2
ffffffffc0200ef4:	aa850513          	addi	a0,a0,-1368 # ffffffffc0202998 <commands+0x588>
    cprintf("mem_end:   0x%016lx\n", mem_end);
ffffffffc0200ef8:	4bc5                	li	s7,17
    cprintf("pages:     0x%016lx\n", (uint64_t)PADDR(pages));
ffffffffc0200efa:	40b685b3          	sub	a1,a3,a1
ffffffffc0200efe:	eccff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("freemem:   0x%016lx\n", freemem);
ffffffffc0200f02:	85a6                	mv	a1,s1
ffffffffc0200f04:	00002517          	auipc	a0,0x2
ffffffffc0200f08:	aac50513          	addi	a0,a0,-1364 # ffffffffc02029b0 <commands+0x5a0>
ffffffffc0200f0c:	ebeff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("mem_begin: 0x%016lx\n", mem_begin);
ffffffffc0200f10:	85d2                	mv	a1,s4
ffffffffc0200f12:	00002517          	auipc	a0,0x2
ffffffffc0200f16:	ab650513          	addi	a0,a0,-1354 # ffffffffc02029c8 <commands+0x5b8>
ffffffffc0200f1a:	eb0ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    cprintf("mem_end:   0x%016lx\n", mem_end);
ffffffffc0200f1e:	01bb9593          	slli	a1,s7,0x1b
    if (freemem < mem_end) {
ffffffffc0200f22:	8bae                	mv	s7,a1
    cprintf("mem_end:   0x%016lx\n", mem_end);
ffffffffc0200f24:	00002517          	auipc	a0,0x2
ffffffffc0200f28:	abc50513          	addi	a0,a0,-1348 # ffffffffc02029e0 <commands+0x5d0>
ffffffffc0200f2c:	e9eff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    if (freemem < mem_end) {
ffffffffc0200f30:	0774e063          	bltu	s1,s7,ffffffffc0200f90 <pmm_init+0x1b4>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0200f34:	0009b783          	ld	a5,0(s3)
ffffffffc0200f38:	7b9c                	ld	a5,48(a5)
ffffffffc0200f3a:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0200f3c:	00002517          	auipc	a0,0x2
ffffffffc0200f40:	b2450513          	addi	a0,a0,-1244 # ffffffffc0202a60 <commands+0x650>
ffffffffc0200f44:	e86ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0200f48:	00005597          	auipc	a1,0x5
ffffffffc0200f4c:	0b858593          	addi	a1,a1,184 # ffffffffc0206000 <boot_page_table_sv39>
ffffffffc0200f50:	00006797          	auipc	a5,0x6
ffffffffc0200f54:	60b7b423          	sd	a1,1544(a5) # ffffffffc0207558 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0200f58:	c02007b7          	lui	a5,0xc0200
ffffffffc0200f5c:	10f5e863          	bltu	a1,a5,ffffffffc020106c <pmm_init+0x290>
ffffffffc0200f60:	00093603          	ld	a2,0(s2)
}
ffffffffc0200f64:	6406                	ld	s0,64(sp)
ffffffffc0200f66:	60a6                	ld	ra,72(sp)
ffffffffc0200f68:	74e2                	ld	s1,56(sp)
ffffffffc0200f6a:	7942                	ld	s2,48(sp)
ffffffffc0200f6c:	79a2                	ld	s3,40(sp)
ffffffffc0200f6e:	7a02                	ld	s4,32(sp)
ffffffffc0200f70:	6ae2                	ld	s5,24(sp)
ffffffffc0200f72:	6b42                	ld	s6,16(sp)
ffffffffc0200f74:	6ba2                	ld	s7,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0200f76:	40c58633          	sub	a2,a1,a2
ffffffffc0200f7a:	00006797          	auipc	a5,0x6
ffffffffc0200f7e:	5cc7bb23          	sd	a2,1494(a5) # ffffffffc0207550 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200f82:	00002517          	auipc	a0,0x2
ffffffffc0200f86:	afe50513          	addi	a0,a0,-1282 # ffffffffc0202a80 <commands+0x670>
}
ffffffffc0200f8a:	6161                	addi	sp,sp,80
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0200f8c:	e3eff06f          	j	ffffffffc02005ca <cprintf>
        cprintf("Checkpoint reached: freemem < mem_end\n");
ffffffffc0200f90:	00002517          	auipc	a0,0x2
ffffffffc0200f94:	a6850513          	addi	a0,a0,-1432 # ffffffffc02029f8 <commands+0x5e8>
ffffffffc0200f98:	e32ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0200f9c:	000ab783          	ld	a5,0(s5)
ffffffffc0200fa0:	00ca5493          	srli	s1,s4,0xc
ffffffffc0200fa4:	04f4ff63          	bgeu	s1,a5,ffffffffc0201002 <pmm_init+0x226>
    pmm_manager->init_memmap(base, n);
ffffffffc0200fa8:	0009b703          	ld	a4,0(s3)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0200fac:	016487b3          	add	a5,s1,s6
ffffffffc0200fb0:	6008                	ld	a0,0(s0)
ffffffffc0200fb2:	00279413          	slli	s0,a5,0x2
ffffffffc0200fb6:	97a2                	add	a5,a5,s0
ffffffffc0200fb8:	6b18                	ld	a4,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0200fba:	414b8a33          	sub	s4,s7,s4
ffffffffc0200fbe:	00379413          	slli	s0,a5,0x3
ffffffffc0200fc2:	00ca5a13          	srli	s4,s4,0xc
    pmm_manager->init_memmap(base, n);
ffffffffc0200fc6:	9522                	add	a0,a0,s0
ffffffffc0200fc8:	85d2                	mv	a1,s4
ffffffffc0200fca:	9702                	jalr	a4
        cprintf("size_t n is %d",(mem_end - mem_begin) / PGSIZE);
ffffffffc0200fcc:	85d2                	mv	a1,s4
ffffffffc0200fce:	00002517          	auipc	a0,0x2
ffffffffc0200fd2:	a8250513          	addi	a0,a0,-1406 # ffffffffc0202a50 <commands+0x640>
ffffffffc0200fd6:	df4ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    if (PPN(pa) >= npage) {
ffffffffc0200fda:	000ab783          	ld	a5,0(s5)
ffffffffc0200fde:	02f4f263          	bgeu	s1,a5,ffffffffc0201002 <pmm_init+0x226>
        fppn=pa2page(mem_begin)-pages+nbase;
ffffffffc0200fe2:	40345793          	srai	a5,s0,0x3
ffffffffc0200fe6:	00002417          	auipc	s0,0x2
ffffffffc0200fea:	4aa43403          	ld	s0,1194(s0) # ffffffffc0203490 <error_string+0x38>
ffffffffc0200fee:	028787b3          	mul	a5,a5,s0
ffffffffc0200ff2:	00080737          	lui	a4,0x80
ffffffffc0200ff6:	97ba                	add	a5,a5,a4
ffffffffc0200ff8:	00006717          	auipc	a4,0x6
ffffffffc0200ffc:	52f73c23          	sd	a5,1336(a4) # ffffffffc0207530 <fppn>
ffffffffc0201000:	bf15                	j	ffffffffc0200f34 <pmm_init+0x158>
        panic("pa2page called with invalid pa");
ffffffffc0201002:	00002617          	auipc	a2,0x2
ffffffffc0201006:	a1e60613          	addi	a2,a2,-1506 # ffffffffc0202a20 <commands+0x610>
ffffffffc020100a:	06b00593          	li	a1,107
ffffffffc020100e:	00002517          	auipc	a0,0x2
ffffffffc0201012:	a3250513          	addi	a0,a0,-1486 # ffffffffc0202a40 <commands+0x630>
ffffffffc0201016:	e3cff0ef          	jal	ra,ffffffffc0200652 <__panic>
    cprintf("pages:     0x%016lx\n", (uint64_t)PADDR(pages));
ffffffffc020101a:	00002617          	auipc	a2,0x2
ffffffffc020101e:	92e60613          	addi	a2,a2,-1746 # ffffffffc0202948 <commands+0x538>
ffffffffc0201022:	09300593          	li	a1,147
ffffffffc0201026:	00002517          	auipc	a0,0x2
ffffffffc020102a:	94a50513          	addi	a0,a0,-1718 # ffffffffc0202970 <commands+0x560>
ffffffffc020102e:	e24ff0ef          	jal	ra,ffffffffc0200652 <__panic>
    cprintf("kern_end:  0x%016lx\n", (uint64_t)PADDR(end));
ffffffffc0201032:	00006697          	auipc	a3,0x6
ffffffffc0201036:	53e68693          	addi	a3,a3,1342 # ffffffffc0207570 <end>
ffffffffc020103a:	00002617          	auipc	a2,0x2
ffffffffc020103e:	90e60613          	addi	a2,a2,-1778 # ffffffffc0202948 <commands+0x538>
ffffffffc0201042:	09200593          	li	a1,146
ffffffffc0201046:	00002517          	auipc	a0,0x2
ffffffffc020104a:	92a50513          	addi	a0,a0,-1750 # ffffffffc0202970 <commands+0x560>
ffffffffc020104e:	e04ff0ef          	jal	ra,ffffffffc0200652 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201052:	86a6                	mv	a3,s1
ffffffffc0201054:	00002617          	auipc	a2,0x2
ffffffffc0201058:	8f460613          	addi	a2,a2,-1804 # ffffffffc0202948 <commands+0x538>
ffffffffc020105c:	08d00593          	li	a1,141
ffffffffc0201060:	00002517          	auipc	a0,0x2
ffffffffc0201064:	91050513          	addi	a0,a0,-1776 # ffffffffc0202970 <commands+0x560>
ffffffffc0201068:	deaff0ef          	jal	ra,ffffffffc0200652 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020106c:	86ae                	mv	a3,a1
ffffffffc020106e:	00002617          	auipc	a2,0x2
ffffffffc0201072:	8da60613          	addi	a2,a2,-1830 # ffffffffc0202948 <commands+0x538>
ffffffffc0201076:	0b100593          	li	a1,177
ffffffffc020107a:	00002517          	auipc	a0,0x2
ffffffffc020107e:	8f650513          	addi	a0,a0,-1802 # ffffffffc0202970 <commands+0x560>
ffffffffc0201082:	dd0ff0ef          	jal	ra,ffffffffc0200652 <__panic>

ffffffffc0201086 <buddy_system_init>:
    }
    return count;
}

static void buddy_system_init(void){
    for(int i=0;i<16;i++){
ffffffffc0201086:	00006797          	auipc	a5,0x6
ffffffffc020108a:	f9278793          	addi	a5,a5,-110 # ffffffffc0207018 <free_buddy+0x8>
ffffffffc020108e:	00006717          	auipc	a4,0x6
ffffffffc0201092:	08a70713          	addi	a4,a4,138 # ffffffffc0207118 <free_buddy+0x108>
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0201096:	e79c                	sd	a5,8(a5)
ffffffffc0201098:	e39c                	sd	a5,0(a5)
ffffffffc020109a:	07c1                	addi	a5,a5,16
ffffffffc020109c:	fee79de3          	bne	a5,a4,ffffffffc0201096 <buddy_system_init+0x10>
        list_init(free_list+i);
    }
    nr_free=0;
ffffffffc02010a0:	00006797          	auipc	a5,0x6
ffffffffc02010a4:	0607ac23          	sw	zero,120(a5) # ffffffffc0207118 <free_buddy+0x108>
    order=0;
ffffffffc02010a8:	00006797          	auipc	a5,0x6
ffffffffc02010ac:	f607a423          	sw	zero,-152(a5) # ffffffffc0207010 <free_buddy>
}
ffffffffc02010b0:	8082                	ret

ffffffffc02010b2 <buddy_nr_free_pages>:
    return page+(ppn-page2ppn(page));
}

static size_t buddy_nr_free_pages(void){
    return nr_free;
}
ffffffffc02010b2:	00006517          	auipc	a0,0x6
ffffffffc02010b6:	06656503          	lwu	a0,102(a0) # ffffffffc0207118 <free_buddy+0x108>
ffffffffc02010ba:	8082                	ret

ffffffffc02010bc <buddy_system_memmap>:
void buddy_system_memmap(struct Page *base, size_t n) {
ffffffffc02010bc:	1141                	addi	sp,sp,-16
ffffffffc02010be:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02010c0:	cdc5                	beqz	a1,ffffffffc0201178 <buddy_system_memmap+0xbc>
    order = Get_Power_Of_2(n);
ffffffffc02010c2:	0005879b          	sext.w	a5,a1
    while(x>1){
ffffffffc02010c6:	4705                	li	a4,1
ffffffffc02010c8:	08f77363          	bgeu	a4,a5,ffffffffc020114e <buddy_system_memmap+0x92>
    uint32_t count=0;
ffffffffc02010cc:	4681                	li	a3,0
        x=x>>1;
ffffffffc02010ce:	0017d79b          	srliw	a5,a5,0x1
        count++;
ffffffffc02010d2:	2685                	addiw	a3,a3,1
    while(x>1){
ffffffffc02010d4:	fee79de3          	bne	a5,a4,ffffffffc02010ce <buddy_system_memmap+0x12>
    uint32_t real_n = 1 << order;
ffffffffc02010d8:	4585                	li	a1,1
ffffffffc02010da:	00d595bb          	sllw	a1,a1,a3
    for (; p != base + real_n; p += 1) {
ffffffffc02010de:	02059793          	slli	a5,a1,0x20
ffffffffc02010e2:	9381                	srli	a5,a5,0x20
ffffffffc02010e4:	00279613          	slli	a2,a5,0x2
ffffffffc02010e8:	963e                	add	a2,a2,a5
ffffffffc02010ea:	060e                	slli	a2,a2,0x3
    order = Get_Power_Of_2(n);
ffffffffc02010ec:	00006817          	auipc	a6,0x6
ffffffffc02010f0:	f2480813          	addi	a6,a6,-220 # ffffffffc0207010 <free_buddy>
ffffffffc02010f4:	00d82023          	sw	a3,0(a6)
    nr_free = real_n;
ffffffffc02010f8:	10b82423          	sw	a1,264(a6)
    for (; p != base + real_n; p += 1) {
ffffffffc02010fc:	962a                	add	a2,a2,a0
ffffffffc02010fe:	87aa                	mv	a5,a0
ffffffffc0201100:	00c50f63          	beq	a0,a2,ffffffffc020111e <buddy_system_memmap+0x62>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201104:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));  // 确保页面已保留
ffffffffc0201106:	8b05                	andi	a4,a4,1
ffffffffc0201108:	cb21                	beqz	a4,ffffffffc0201158 <buddy_system_memmap+0x9c>
        p->property = p->flags = 0;  // 清除属性和标志
ffffffffc020110a:	0007b423          	sd	zero,8(a5)
ffffffffc020110e:	0007a823          	sw	zero,16(a5)
static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201112:	0007a023          	sw	zero,0(a5)
    for (; p != base + real_n; p += 1) {
ffffffffc0201116:	02878793          	addi	a5,a5,40
ffffffffc020111a:	fec795e3          	bne	a5,a2,ffffffffc0201104 <buddy_system_memmap+0x48>
 * Insert the new element @elm *after* the element @listelm which
 * is already in the list.
 * */
static inline void
list_add_after(list_entry_t *listelm, list_entry_t *elm) {
    __list_add(elm, listelm, listelm->next);
ffffffffc020111e:	02069793          	slli	a5,a3,0x20
ffffffffc0201122:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0201126:	00d80733          	add	a4,a6,a3
ffffffffc020112a:	6b1c                	ld	a5,16(a4)
    list_add(&free_list[order], &base->page_link);  // 将块加入到空闲链表
ffffffffc020112c:	01850613          	addi	a2,a0,24
ffffffffc0201130:	06a1                	addi	a3,a3,8
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201132:	e390                	sd	a2,0(a5)
ffffffffc0201134:	eb10                	sd	a2,16(a4)
ffffffffc0201136:	96c2                	add	a3,a3,a6
    elm->next = next;
ffffffffc0201138:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020113a:	ed14                	sd	a3,24(a0)
    base->property = real_n;
ffffffffc020113c:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020113e:	4789                	li	a5,2
ffffffffc0201140:	00850713          	addi	a4,a0,8
ffffffffc0201144:	40f7302f          	amoor.d	zero,a5,(a4)
}
ffffffffc0201148:	60a2                	ld	ra,8(sp)
ffffffffc020114a:	0141                	addi	sp,sp,16
ffffffffc020114c:	8082                	ret
    while(x>1){
ffffffffc020114e:	02800613          	li	a2,40
ffffffffc0201152:	4585                	li	a1,1
    uint32_t count=0;
ffffffffc0201154:	4681                	li	a3,0
ffffffffc0201156:	bf59                	j	ffffffffc02010ec <buddy_system_memmap+0x30>
        assert(PageReserved(p));  // 确保页面已保留
ffffffffc0201158:	00002697          	auipc	a3,0x2
ffffffffc020115c:	98868693          	addi	a3,a3,-1656 # ffffffffc0202ae0 <commands+0x6d0>
ffffffffc0201160:	00001617          	auipc	a2,0x1
ffffffffc0201164:	e4860613          	addi	a2,a2,-440 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc0201168:	04300593          	li	a1,67
ffffffffc020116c:	00002517          	auipc	a0,0x2
ffffffffc0201170:	95c50513          	addi	a0,a0,-1700 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc0201174:	cdeff0ef          	jal	ra,ffffffffc0200652 <__panic>
    assert(n > 0);
ffffffffc0201178:	00002697          	auipc	a3,0x2
ffffffffc020117c:	94868693          	addi	a3,a3,-1720 # ffffffffc0202ac0 <commands+0x6b0>
ffffffffc0201180:	00001617          	auipc	a2,0x1
ffffffffc0201184:	e2860613          	addi	a2,a2,-472 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc0201188:	03400593          	li	a1,52
ffffffffc020118c:	00002517          	auipc	a0,0x2
ffffffffc0201190:	93c50513          	addi	a0,a0,-1732 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc0201194:	cbeff0ef          	jal	ra,ffffffffc0200652 <__panic>

ffffffffc0201198 <buddy_alloc_pages>:
static struct Page * buddy_alloc_pages(size_t real_n) {
ffffffffc0201198:	7139                	addi	sp,sp,-64
ffffffffc020119a:	fc06                	sd	ra,56(sp)
ffffffffc020119c:	f822                	sd	s0,48(sp)
ffffffffc020119e:	f426                	sd	s1,40(sp)
ffffffffc02011a0:	f04a                	sd	s2,32(sp)
ffffffffc02011a2:	ec4e                	sd	s3,24(sp)
ffffffffc02011a4:	e852                	sd	s4,16(sp)
ffffffffc02011a6:	e456                	sd	s5,8(sp)
ffffffffc02011a8:	e05a                	sd	s6,0(sp)
    assert(real_n > 0);
ffffffffc02011aa:	18050b63          	beqz	a0,ffffffffc0201340 <buddy_alloc_pages+0x1a8>

    if (real_n > nr_free) {
ffffffffc02011ae:	00006b17          	auipc	s6,0x6
ffffffffc02011b2:	e62b0b13          	addi	s6,s6,-414 # ffffffffc0207010 <free_buddy>
ffffffffc02011b6:	108b2603          	lw	a2,264(s6)
ffffffffc02011ba:	85aa                	mv	a1,a0
ffffffffc02011bc:	02061793          	slli	a5,a2,0x20
ffffffffc02011c0:	9381                	srli	a5,a5,0x20
ffffffffc02011c2:	16a7e463          	bltu	a5,a0,ffffffffc020132a <buddy_alloc_pages+0x192>
        cprintf("buddy_alloc_pages: Not enough free pages. Needed: %lu, Available: %d\n", real_n, nr_free);
        return NULL;
    }

    struct Page *page = NULL;
    order = Is_Power_Of_2(real_n) ? Get_Power_Of_2(real_n) : Get_Power_Of_2(real_n) + 1;
ffffffffc02011c6:	0005079b          	sext.w	a5,a0
    if(x>0&&(x&(x-1))==0){
ffffffffc02011ca:	fff5061b          	addiw	a2,a0,-1
ffffffffc02011ce:	8e7d                	and	a2,a2,a5
ffffffffc02011d0:	2601                	sext.w	a2,a2
ffffffffc02011d2:	14060363          	beqz	a2,ffffffffc0201318 <buddy_alloc_pages+0x180>
    while(x>1){
ffffffffc02011d6:	4605                	li	a2,1
ffffffffc02011d8:	4701                	li	a4,0
ffffffffc02011da:	4685                	li	a3,1
ffffffffc02011dc:	4a89                	li	s5,2
ffffffffc02011de:	4a09                	li	s4,2
ffffffffc02011e0:	00c78e63          	beq	a5,a2,ffffffffc02011fc <buddy_alloc_pages+0x64>
        x=x>>1;
ffffffffc02011e4:	0017d79b          	srliw	a5,a5,0x1
        count++;
ffffffffc02011e8:	0007061b          	sext.w	a2,a4
ffffffffc02011ec:	2705                	addiw	a4,a4,1
    while(x>1){
ffffffffc02011ee:	fed79be3          	bne	a5,a3,ffffffffc02011e4 <buddy_alloc_pages+0x4c>
    order = Is_Power_Of_2(real_n) ? Get_Power_Of_2(real_n) : Get_Power_Of_2(real_n) + 1;
ffffffffc02011f2:	2609                	addiw	a2,a2,2
    size_t n = 1 << order;
ffffffffc02011f4:	4a05                	li	s4,1
ffffffffc02011f6:	00ca1a3b          	sllw	s4,s4,a2
    while (1) {
        if (!list_empty(&(free_list[order]))) {
            page = le2page(list_next(&(free_list[order])), page_link);
            list_del(list_next(&(free_list[order])));
            SetPageProperty(page);
            nr_free -= n;
ffffffffc02011fa:	8ad2                	mv	s5,s4
    cprintf("buddy_alloc_pages: Request for %lu pages, calculated order: %u, n: %lu\n", real_n, order, n);
ffffffffc02011fc:	86d2                	mv	a3,s4
ffffffffc02011fe:	00002517          	auipc	a0,0x2
ffffffffc0201202:	94a50513          	addi	a0,a0,-1718 # ffffffffc0202b48 <commands+0x738>
    order = Is_Power_Of_2(real_n) ? Get_Power_Of_2(real_n) : Get_Power_Of_2(real_n) + 1;
ffffffffc0201206:	00cb2023          	sw	a2,0(s6)
    cprintf("buddy_alloc_pages: Request for %lu pages, calculated order: %u, n: %lu\n", real_n, order, n);
ffffffffc020120a:	bc0ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
        if (!list_empty(&(free_list[order]))) {
ffffffffc020120e:	000b2603          	lw	a2,0(s6)
            cprintf("buddy_alloc_pages: Allocated %lu pages from free_list[%u] at address %p\n", n, order, page);
            break;
        }

        for (int i = order; i < 16; i++) {
ffffffffc0201212:	44bd                	li	s1,15
ffffffffc0201214:	4441                	li	s0,16
    return list->next == list;
ffffffffc0201216:	02061713          	slli	a4,a2,0x20
ffffffffc020121a:	01c75793          	srli	a5,a4,0x1c
ffffffffc020121e:	00fb0733          	add	a4,s6,a5
ffffffffc0201222:	6b18                	ld	a4,16(a4)
        if (!list_empty(&(free_list[order]))) {
ffffffffc0201224:	07a1                	addi	a5,a5,8
ffffffffc0201226:	97da                	add	a5,a5,s6
            if (!list_empty(&(free_list[i]))) {
                struct Page *page1 = le2page(list_next(&(free_list[i])), page_link);
                struct Page *page2 = page1 + (1 << (i - 1));
ffffffffc0201228:	4985                	li	s3,1
                page1->property = i - 1;
                page2->property = i - 1;
                list_del(list_next(&(free_list[i])));
                list_add(&(free_list[i-1]), &(page2->page_link));
                list_add(&(free_list[i-1]), &(page1->page_link));
                cprintf("buddy_alloc_pages: Split block from free_list[%d] into two blocks of size %lu pages (power %d)\n", i, (1 << (i - 1)), i - 1);
ffffffffc020122a:	00002917          	auipc	s2,0x2
ffffffffc020122e:	9b690913          	addi	s2,s2,-1610 # ffffffffc0202be0 <commands+0x7d0>
        if (!list_empty(&(free_list[order]))) {
ffffffffc0201232:	0af71063          	bne	a4,a5,ffffffffc02012d2 <buddy_alloc_pages+0x13a>
ffffffffc0201236:	00461693          	slli	a3,a2,0x4
ffffffffc020123a:	06a1                	addi	a3,a3,8
        for (int i = order; i < 16; i++) {
ffffffffc020123c:	2601                	sext.w	a2,a2
ffffffffc020123e:	96da                	add	a3,a3,s6
ffffffffc0201240:	00c4c063          	blt	s1,a2,ffffffffc0201240 <buddy_alloc_pages+0xa8>
ffffffffc0201244:	87b6                	mv	a5,a3
ffffffffc0201246:	85b2                	mv	a1,a2
ffffffffc0201248:	a029                	j	ffffffffc0201252 <buddy_alloc_pages+0xba>
ffffffffc020124a:	2585                	addiw	a1,a1,1
ffffffffc020124c:	07c1                	addi	a5,a5,16
ffffffffc020124e:	fe8589e3          	beq	a1,s0,ffffffffc0201240 <buddy_alloc_pages+0xa8>
ffffffffc0201252:	6798                	ld	a4,8(a5)
            if (!list_empty(&(free_list[i]))) {
ffffffffc0201254:	fef70be3          	beq	a4,a5,ffffffffc020124a <buddy_alloc_pages+0xb2>
                struct Page *page2 = page1 + (1 << (i - 1));
ffffffffc0201258:	fff5869b          	addiw	a3,a1,-1
ffffffffc020125c:	00d9963b          	sllw	a2,s3,a3
ffffffffc0201260:	00261793          	slli	a5,a2,0x2
ffffffffc0201264:	97b2                	add	a5,a5,a2
ffffffffc0201266:	078e                	slli	a5,a5,0x3
    __list_del(listelm->prev, listelm->next);
ffffffffc0201268:	00073883          	ld	a7,0(a4)
ffffffffc020126c:	00873803          	ld	a6,8(a4)
ffffffffc0201270:	17a1                	addi	a5,a5,-24
                page1->property = i - 1;
ffffffffc0201272:	fed72c23          	sw	a3,-8(a4)
                struct Page *page2 = page1 + (1 << (i - 1));
ffffffffc0201276:	97ba                	add	a5,a5,a4
                page2->property = i - 1;
ffffffffc0201278:	cb94                	sw	a3,16(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc020127a:	0108b423          	sd	a6,8(a7)
                list_add(&(free_list[i-1]), &(page2->page_link));
ffffffffc020127e:	00469513          	slli	a0,a3,0x4
    next->prev = prev;
ffffffffc0201282:	01183023          	sd	a7,0(a6)
    __list_add(elm, listelm, listelm->next);
ffffffffc0201286:	00ab0833          	add	a6,s6,a0
ffffffffc020128a:	01083883          	ld	a7,16(a6)
ffffffffc020128e:	01878313          	addi	t1,a5,24
ffffffffc0201292:	0521                	addi	a0,a0,8
    prev->next = next->prev = elm;
ffffffffc0201294:	0068b023          	sd	t1,0(a7)
ffffffffc0201298:	00683823          	sd	t1,16(a6)
ffffffffc020129c:	955a                	add	a0,a0,s6
    elm->prev = prev;
ffffffffc020129e:	ef88                	sd	a0,24(a5)
    elm->next = next;
ffffffffc02012a0:	0317b023          	sd	a7,32(a5)
    __list_add(elm, listelm, listelm->next);
ffffffffc02012a4:	01083783          	ld	a5,16(a6)
    prev->next = next->prev = elm;
ffffffffc02012a8:	e398                	sd	a4,0(a5)
ffffffffc02012aa:	00e83823          	sd	a4,16(a6)
    elm->next = next;
ffffffffc02012ae:	e71c                	sd	a5,8(a4)
    elm->prev = prev;
ffffffffc02012b0:	e308                	sd	a0,0(a4)
                cprintf("buddy_alloc_pages: Split block from free_list[%d] into two blocks of size %lu pages (power %d)\n", i, (1 << (i - 1)), i - 1);
ffffffffc02012b2:	854a                	mv	a0,s2
ffffffffc02012b4:	b16ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
        if (!list_empty(&(free_list[order]))) {
ffffffffc02012b8:	000b2603          	lw	a2,0(s6)
    return list->next == list;
ffffffffc02012bc:	02061713          	slli	a4,a2,0x20
ffffffffc02012c0:	01c75793          	srli	a5,a4,0x1c
ffffffffc02012c4:	00fb0733          	add	a4,s6,a5
ffffffffc02012c8:	6b18                	ld	a4,16(a4)
ffffffffc02012ca:	07a1                	addi	a5,a5,8
ffffffffc02012cc:	97da                	add	a5,a5,s6
ffffffffc02012ce:	f6f704e3          	beq	a4,a5,ffffffffc0201236 <buddy_alloc_pages+0x9e>
    __list_del(listelm->prev, listelm->next);
ffffffffc02012d2:	671c                	ld	a5,8(a4)
ffffffffc02012d4:	6314                	ld	a3,0(a4)
            page = le2page(list_next(&(free_list[order])), page_link);
ffffffffc02012d6:	fe870413          	addi	s0,a4,-24
ffffffffc02012da:	1741                	addi	a4,a4,-16
    prev->next = next;
ffffffffc02012dc:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc02012de:	e394                	sd	a3,0(a5)
ffffffffc02012e0:	4789                	li	a5,2
ffffffffc02012e2:	40f7302f          	amoor.d	zero,a5,(a4)
            nr_free -= n;
ffffffffc02012e6:	108b2783          	lw	a5,264(s6)
            cprintf("buddy_alloc_pages: Allocated %lu pages from free_list[%u] at address %p\n", n, order, page);
ffffffffc02012ea:	86a2                	mv	a3,s0
ffffffffc02012ec:	85d2                	mv	a1,s4
            nr_free -= n;
ffffffffc02012ee:	41578abb          	subw	s5,a5,s5
            cprintf("buddy_alloc_pages: Allocated %lu pages from free_list[%u] at address %p\n", n, order, page);
ffffffffc02012f2:	00002517          	auipc	a0,0x2
ffffffffc02012f6:	89e50513          	addi	a0,a0,-1890 # ffffffffc0202b90 <commands+0x780>
            nr_free -= n;
ffffffffc02012fa:	115b2423          	sw	s5,264(s6)
            cprintf("buddy_alloc_pages: Allocated %lu pages from free_list[%u] at address %p\n", n, order, page);
ffffffffc02012fe:	accff0ef          	jal	ra,ffffffffc02005ca <cprintf>
            }
        }
    }

    return page;
}
ffffffffc0201302:	70e2                	ld	ra,56(sp)
ffffffffc0201304:	8522                	mv	a0,s0
ffffffffc0201306:	7442                	ld	s0,48(sp)
ffffffffc0201308:	74a2                	ld	s1,40(sp)
ffffffffc020130a:	7902                	ld	s2,32(sp)
ffffffffc020130c:	69e2                	ld	s3,24(sp)
ffffffffc020130e:	6a42                	ld	s4,16(sp)
ffffffffc0201310:	6aa2                	ld	s5,8(sp)
ffffffffc0201312:	6b02                	ld	s6,0(sp)
ffffffffc0201314:	6121                	addi	sp,sp,64
ffffffffc0201316:	8082                	ret
    while(x>1){
ffffffffc0201318:	4705                	li	a4,1
ffffffffc020131a:	02e50063          	beq	a0,a4,ffffffffc020133a <buddy_alloc_pages+0x1a2>
        x=x>>1;
ffffffffc020131e:	0017d79b          	srliw	a5,a5,0x1
        count++;
ffffffffc0201322:	2605                	addiw	a2,a2,1
    while(x>1){
ffffffffc0201324:	fee79de3          	bne	a5,a4,ffffffffc020131e <buddy_alloc_pages+0x186>
ffffffffc0201328:	b5f1                	j	ffffffffc02011f4 <buddy_alloc_pages+0x5c>
        cprintf("buddy_alloc_pages: Not enough free pages. Needed: %lu, Available: %d\n", real_n, nr_free);
ffffffffc020132a:	00001517          	auipc	a0,0x1
ffffffffc020132e:	7d650513          	addi	a0,a0,2006 # ffffffffc0202b00 <commands+0x6f0>
ffffffffc0201332:	a98ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
        return NULL;
ffffffffc0201336:	4401                	li	s0,0
ffffffffc0201338:	b7e9                	j	ffffffffc0201302 <buddy_alloc_pages+0x16a>
    while(x>1){
ffffffffc020133a:	4a05                	li	s4,1
ffffffffc020133c:	4a85                	li	s5,1
ffffffffc020133e:	bd7d                	j	ffffffffc02011fc <buddy_alloc_pages+0x64>
    assert(real_n > 0);
ffffffffc0201340:	00001697          	auipc	a3,0x1
ffffffffc0201344:	7b068693          	addi	a3,a3,1968 # ffffffffc0202af0 <commands+0x6e0>
ffffffffc0201348:	00001617          	auipc	a2,0x1
ffffffffc020134c:	c6060613          	addi	a2,a2,-928 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc0201350:	05800593          	li	a1,88
ffffffffc0201354:	00001517          	auipc	a0,0x1
ffffffffc0201358:	77450513          	addi	a0,a0,1908 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc020135c:	af6ff0ef          	jal	ra,ffffffffc0200652 <__panic>

ffffffffc0201360 <buddy_check_0>:

    ClearPageProperty(free_page);
    cprintf("buddy_free_pages: Pages successfully released\n");
}

static void buddy_check_0(void) {
ffffffffc0201360:	c8010113          	addi	sp,sp,-896

#define ALLOC_PAGE_NUM 100

    cprintf("[buddy_check_0] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
ffffffffc0201364:	00002517          	auipc	a0,0x2
ffffffffc0201368:	8dc50513          	addi	a0,a0,-1828 # ffffffffc0202c40 <commands+0x830>
static void buddy_check_0(void) {
ffffffffc020136c:	36113c23          	sd	ra,888(sp)
ffffffffc0201370:	37213023          	sd	s2,864(sp)
ffffffffc0201374:	35313c23          	sd	s3,856(sp)
ffffffffc0201378:	35413823          	sd	s4,848(sp)
ffffffffc020137c:	35513423          	sd	s5,840(sp)
ffffffffc0201380:	35613023          	sd	s6,832(sp)
ffffffffc0201384:	33713c23          	sd	s7,824(sp)
ffffffffc0201388:	33813823          	sd	s8,816(sp)
ffffffffc020138c:	33913423          	sd	s9,808(sp)
ffffffffc0201390:	36813823          	sd	s0,880(sp)
ffffffffc0201394:	36913423          	sd	s1,872(sp)
ffffffffc0201398:	33a13023          	sd	s10,800(sp)
    cprintf("[buddy_check_0] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
ffffffffc020139c:	a2eff0ef          	jal	ra,ffffffffc02005ca <cprintf>

    size_t initial_nr_free_pages = nr_free_pages();
ffffffffc02013a0:	a03ff0ef          	jal	ra,ffffffffc0200da2 <nr_free_pages>
ffffffffc02013a4:	8c2a                	mv	s8,a0

    cprintf("[buddy_check_0] before alloc: ");
ffffffffc02013a6:	00002517          	auipc	a0,0x2
ffffffffc02013aa:	8e250513          	addi	a0,a0,-1822 # ffffffffc0202c88 <commands+0x878>
ffffffffc02013ae:	a1cff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    //buddy_show();

    cprintf("[buddy_check_0] trying to alloc %d * 1 pages\n", ALLOC_PAGE_NUM);
ffffffffc02013b2:	06400593          	li	a1,100
ffffffffc02013b6:	00002517          	auipc	a0,0x2
ffffffffc02013ba:	8f250513          	addi	a0,a0,-1806 # ffffffffc0202ca8 <commands+0x898>
ffffffffc02013be:	a0cff0ef          	jal	ra,ffffffffc02005ca <cprintf>

    struct Page *pages[ALLOC_PAGE_NUM];


    for (int i = 0; i < ALLOC_PAGE_NUM; i++) {
        pages[i] = alloc_pages(1);
ffffffffc02013c2:	4505                	li	a0,1
ffffffffc02013c4:	963ff0ef          	jal	ra,ffffffffc0200d26 <alloc_pages>
ffffffffc02013c8:	00810993          	addi	s3,sp,8
ffffffffc02013cc:	8a2a                	mv	s4,a0
ffffffffc02013ce:	8ace                	mv	s5,s3
ffffffffc02013d0:	892a                	mv	s2,a0
    for (int i = 0; i < ALLOC_PAGE_NUM; i++) {
ffffffffc02013d2:	4c81                	li	s9,0
ffffffffc02013d4:	06400b93          	li	s7,100
        for (int j = 0; j < i; j++) {
            if (pages[i] == pages[j]) {
                cprintf("Error: Duplicate page pointer at %p (pages[%d] and pages[%d])\n", pages[i], i, j);
ffffffffc02013d8:	00002b17          	auipc	s6,0x2
ffffffffc02013dc:	900b0b13          	addi	s6,s6,-1792 # ffffffffc0202cd8 <commands+0x8c8>
            }   
        }
        assert(pages[i] != NULL);
ffffffffc02013e0:	0c090863          	beqz	s2,ffffffffc02014b0 <buddy_check_0+0x150>
    for (int i = 0; i < ALLOC_PAGE_NUM; i++) {
ffffffffc02013e4:	001c8d1b          	addiw	s10,s9,1
ffffffffc02013e8:	057d0363          	beq	s10,s7,ffffffffc020142e <buddy_check_0+0xce>
        pages[i] = alloc_pages(1);
ffffffffc02013ec:	4505                	li	a0,1
ffffffffc02013ee:	939ff0ef          	jal	ra,ffffffffc0200d26 <alloc_pages>
ffffffffc02013f2:	892a                	mv	s2,a0
ffffffffc02013f4:	00aab023          	sd	a0,0(s5)
ffffffffc02013f8:	87d2                	mv	a5,s4
ffffffffc02013fa:	84ce                	mv	s1,s3
        for (int j = 0; j < i; j++) {
ffffffffc02013fc:	4401                	li	s0,0
            if (pages[i] == pages[j]) {
ffffffffc02013fe:	00f90b63          	beq	s2,a5,ffffffffc0201414 <buddy_check_0+0xb4>
        for (int j = 0; j < i; j++) {
ffffffffc0201402:	0014071b          	addiw	a4,s0,1
ffffffffc0201406:	028c8163          	beq	s9,s0,ffffffffc0201428 <buddy_check_0+0xc8>
            if (pages[i] == pages[j]) {
ffffffffc020140a:	609c                	ld	a5,0(s1)
ffffffffc020140c:	843a                	mv	s0,a4
ffffffffc020140e:	04a1                	addi	s1,s1,8
ffffffffc0201410:	fef919e3          	bne	s2,a5,ffffffffc0201402 <buddy_check_0+0xa2>
                cprintf("Error: Duplicate page pointer at %p (pages[%d] and pages[%d])\n", pages[i], i, j);
ffffffffc0201414:	86a2                	mv	a3,s0
ffffffffc0201416:	866a                	mv	a2,s10
ffffffffc0201418:	85ca                	mv	a1,s2
ffffffffc020141a:	855a                	mv	a0,s6
ffffffffc020141c:	9aeff0ef          	jal	ra,ffffffffc02005ca <cprintf>
        for (int j = 0; j < i; j++) {
ffffffffc0201420:	0014071b          	addiw	a4,s0,1
ffffffffc0201424:	fe8c93e3          	bne	s9,s0,ffffffffc020140a <buddy_check_0+0xaa>
ffffffffc0201428:	0aa1                	addi	s5,s5,8
ffffffffc020142a:	8cea                	mv	s9,s10
ffffffffc020142c:	bf55                	j	ffffffffc02013e0 <buddy_check_0+0x80>
    }

    assert(nr_free_pages() == initial_nr_free_pages - ALLOC_PAGE_NUM);
ffffffffc020142e:	975ff0ef          	jal	ra,ffffffffc0200da2 <nr_free_pages>
ffffffffc0201432:	f9cc0793          	addi	a5,s8,-100
ffffffffc0201436:	0af51d63          	bne	a0,a5,ffffffffc02014f0 <buddy_check_0+0x190>

    cprintf("[buddy_check_0] after alloc:  ");
ffffffffc020143a:	00002517          	auipc	a0,0x2
ffffffffc020143e:	93650513          	addi	a0,a0,-1738 # ffffffffc0202d70 <commands+0x960>
ffffffffc0201442:	988ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    //buddy_show();

    for (int i = 0; i < ALLOC_PAGE_NUM; i++) {
ffffffffc0201446:	1600                	addi	s0,sp,800
ffffffffc0201448:	a021                	j	ffffffffc0201450 <buddy_check_0+0xf0>
        free_pages(pages[i], 1);
ffffffffc020144a:	0009ba03          	ld	s4,0(s3)
ffffffffc020144e:	09a1                	addi	s3,s3,8
ffffffffc0201450:	4585                	li	a1,1
ffffffffc0201452:	8552                	mv	a0,s4
ffffffffc0201454:	911ff0ef          	jal	ra,ffffffffc0200d64 <free_pages>
    for (int i = 0; i < ALLOC_PAGE_NUM; i++) {
ffffffffc0201458:	fe8999e3          	bne	s3,s0,ffffffffc020144a <buddy_check_0+0xea>
    }
    assert(nr_free_pages() == initial_nr_free_pages);
ffffffffc020145c:	947ff0ef          	jal	ra,ffffffffc0200da2 <nr_free_pages>
ffffffffc0201460:	07851863          	bne	a0,s8,ffffffffc02014d0 <buddy_check_0+0x170>

    cprintf("[buddy_check_0] after free:   ");
ffffffffc0201464:	00002517          	auipc	a0,0x2
ffffffffc0201468:	95c50513          	addi	a0,a0,-1700 # ffffffffc0202dc0 <commands+0x9b0>
ffffffffc020146c:	95eff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    //buddy_show();

    cprintf("[buddy_check_0] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");    
}
ffffffffc0201470:	37013403          	ld	s0,880(sp)
ffffffffc0201474:	37813083          	ld	ra,888(sp)
ffffffffc0201478:	36813483          	ld	s1,872(sp)
ffffffffc020147c:	36013903          	ld	s2,864(sp)
ffffffffc0201480:	35813983          	ld	s3,856(sp)
ffffffffc0201484:	35013a03          	ld	s4,848(sp)
ffffffffc0201488:	34813a83          	ld	s5,840(sp)
ffffffffc020148c:	34013b03          	ld	s6,832(sp)
ffffffffc0201490:	33813b83          	ld	s7,824(sp)
ffffffffc0201494:	33013c03          	ld	s8,816(sp)
ffffffffc0201498:	32813c83          	ld	s9,808(sp)
ffffffffc020149c:	32013d03          	ld	s10,800(sp)
    cprintf("[buddy_check_0] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");    
ffffffffc02014a0:	00002517          	auipc	a0,0x2
ffffffffc02014a4:	94050513          	addi	a0,a0,-1728 # ffffffffc0202de0 <commands+0x9d0>
}
ffffffffc02014a8:	38010113          	addi	sp,sp,896
    cprintf("[buddy_check_0] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");    
ffffffffc02014ac:	91eff06f          	j	ffffffffc02005ca <cprintf>
        assert(pages[i] != NULL);
ffffffffc02014b0:	00002697          	auipc	a3,0x2
ffffffffc02014b4:	86868693          	addi	a3,a3,-1944 # ffffffffc0202d18 <commands+0x908>
ffffffffc02014b8:	00001617          	auipc	a2,0x1
ffffffffc02014bc:	af060613          	addi	a2,a2,-1296 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc02014c0:	0bb00593          	li	a1,187
ffffffffc02014c4:	00001517          	auipc	a0,0x1
ffffffffc02014c8:	60450513          	addi	a0,a0,1540 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc02014cc:	986ff0ef          	jal	ra,ffffffffc0200652 <__panic>
    assert(nr_free_pages() == initial_nr_free_pages);
ffffffffc02014d0:	00002697          	auipc	a3,0x2
ffffffffc02014d4:	8c068693          	addi	a3,a3,-1856 # ffffffffc0202d90 <commands+0x980>
ffffffffc02014d8:	00001617          	auipc	a2,0x1
ffffffffc02014dc:	ad060613          	addi	a2,a2,-1328 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc02014e0:	0c600593          	li	a1,198
ffffffffc02014e4:	00001517          	auipc	a0,0x1
ffffffffc02014e8:	5e450513          	addi	a0,a0,1508 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc02014ec:	966ff0ef          	jal	ra,ffffffffc0200652 <__panic>
    assert(nr_free_pages() == initial_nr_free_pages - ALLOC_PAGE_NUM);
ffffffffc02014f0:	00002697          	auipc	a3,0x2
ffffffffc02014f4:	84068693          	addi	a3,a3,-1984 # ffffffffc0202d30 <commands+0x920>
ffffffffc02014f8:	00001617          	auipc	a2,0x1
ffffffffc02014fc:	ab060613          	addi	a2,a2,-1360 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc0201500:	0be00593          	li	a1,190
ffffffffc0201504:	00001517          	auipc	a0,0x1
ffffffffc0201508:	5c450513          	addi	a0,a0,1476 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc020150c:	946ff0ef          	jal	ra,ffffffffc0200652 <__panic>

ffffffffc0201510 <buddy_check>:

    assert(nr_free_pages() == initial_nr_free_pages);

    cprintf("[buddy_check_1] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
}
static void buddy_check(){
ffffffffc0201510:	7139                	addi	sp,sp,-64
ffffffffc0201512:	fc06                	sd	ra,56(sp)
ffffffffc0201514:	e05a                	sd	s6,0(sp)
ffffffffc0201516:	f822                	sd	s0,48(sp)
ffffffffc0201518:	f426                	sd	s1,40(sp)
ffffffffc020151a:	f04a                	sd	s2,32(sp)
ffffffffc020151c:	ec4e                	sd	s3,24(sp)
ffffffffc020151e:	e852                	sd	s4,16(sp)
ffffffffc0201520:	e456                	sd	s5,8(sp)
    //buddy_show();
    buddy_check_0();
ffffffffc0201522:	e3fff0ef          	jal	ra,ffffffffc0201360 <buddy_check_0>
    cprintf("[buddy_check_1] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n");
ffffffffc0201526:	00002517          	auipc	a0,0x2
ffffffffc020152a:	90250513          	addi	a0,a0,-1790 # ffffffffc0202e28 <commands+0xa18>
ffffffffc020152e:	89cff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    size_t initial_nr_free_pages = nr_free_pages();
ffffffffc0201532:	871ff0ef          	jal	ra,ffffffffc0200da2 <nr_free_pages>
ffffffffc0201536:	8b2a                	mv	s6,a0
    cprintf("[buddy_check_0] before alloc:          ");
ffffffffc0201538:	00002517          	auipc	a0,0x2
ffffffffc020153c:	93850513          	addi	a0,a0,-1736 # ffffffffc0202e70 <commands+0xa60>
ffffffffc0201540:	88aff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    struct Page* p0 = alloc_pages(512);
ffffffffc0201544:	20000513          	li	a0,512
ffffffffc0201548:	fdeff0ef          	jal	ra,ffffffffc0200d26 <alloc_pages>
    assert(p0 != NULL);
ffffffffc020154c:	12050763          	beqz	a0,ffffffffc020167a <buddy_check+0x16a>
    assert(p0->property == 9);
ffffffffc0201550:	4918                	lw	a4,16(a0)
ffffffffc0201552:	47a5                	li	a5,9
ffffffffc0201554:	842a                	mv	s0,a0
ffffffffc0201556:	2af71263          	bne	a4,a5,ffffffffc02017fa <buddy_check+0x2ea>
    cprintf("[buddy_check_1] after alloc 512 pages: ");
ffffffffc020155a:	00002517          	auipc	a0,0x2
ffffffffc020155e:	96650513          	addi	a0,a0,-1690 # ffffffffc0202ec0 <commands+0xab0>
ffffffffc0201562:	868ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    struct Page* p1 = alloc_pages(513);
ffffffffc0201566:	20100513          	li	a0,513
ffffffffc020156a:	fbcff0ef          	jal	ra,ffffffffc0200d26 <alloc_pages>
ffffffffc020156e:	84aa                	mv	s1,a0
    assert(p1 != NULL);
ffffffffc0201570:	26050563          	beqz	a0,ffffffffc02017da <buddy_check+0x2ca>
    assert(p1->property == 10);
ffffffffc0201574:	4918                	lw	a4,16(a0)
ffffffffc0201576:	47a9                	li	a5,10
ffffffffc0201578:	24f71163          	bne	a4,a5,ffffffffc02017ba <buddy_check+0x2aa>
    cprintf("[buddy_check_1] after alloc 513 pages: ");
ffffffffc020157c:	00002517          	auipc	a0,0x2
ffffffffc0201580:	99450513          	addi	a0,a0,-1644 # ffffffffc0202f10 <commands+0xb00>
ffffffffc0201584:	846ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    struct Page* p2 = alloc_pages(79);
ffffffffc0201588:	04f00513          	li	a0,79
ffffffffc020158c:	f9aff0ef          	jal	ra,ffffffffc0200d26 <alloc_pages>
ffffffffc0201590:	892a                	mv	s2,a0
    assert(p2 != NULL);
ffffffffc0201592:	20050463          	beqz	a0,ffffffffc020179a <buddy_check+0x28a>
    assert(p2->property == 7);
ffffffffc0201596:	4918                	lw	a4,16(a0)
ffffffffc0201598:	479d                	li	a5,7
ffffffffc020159a:	1ef71063          	bne	a4,a5,ffffffffc020177a <buddy_check+0x26a>
    cprintf("[buddy_check_1] after alloc 79 pages:  ");
ffffffffc020159e:	00002517          	auipc	a0,0x2
ffffffffc02015a2:	9c250513          	addi	a0,a0,-1598 # ffffffffc0202f60 <commands+0xb50>
ffffffffc02015a6:	824ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    struct Page* p3 = alloc_pages(37);
ffffffffc02015aa:	02500513          	li	a0,37
ffffffffc02015ae:	f78ff0ef          	jal	ra,ffffffffc0200d26 <alloc_pages>
ffffffffc02015b2:	89aa                	mv	s3,a0
    assert(p3 != NULL);
ffffffffc02015b4:	1a050363          	beqz	a0,ffffffffc020175a <buddy_check+0x24a>
    assert(p3->property == 6);
ffffffffc02015b8:	4918                	lw	a4,16(a0)
ffffffffc02015ba:	4799                	li	a5,6
ffffffffc02015bc:	16f71f63          	bne	a4,a5,ffffffffc020173a <buddy_check+0x22a>
    cprintf("[buddy_check_1] after alloc 37 pages:  ");
ffffffffc02015c0:	00002517          	auipc	a0,0x2
ffffffffc02015c4:	9f050513          	addi	a0,a0,-1552 # ffffffffc0202fb0 <commands+0xba0>
ffffffffc02015c8:	802ff0ef          	jal	ra,ffffffffc02005ca <cprintf>
    struct Page* p4 = alloc_pages(3);
ffffffffc02015cc:	450d                	li	a0,3
ffffffffc02015ce:	f58ff0ef          	jal	ra,ffffffffc0200d26 <alloc_pages>
ffffffffc02015d2:	8a2a                	mv	s4,a0
    assert(p4 != NULL);
ffffffffc02015d4:	14050363          	beqz	a0,ffffffffc020171a <buddy_check+0x20a>
    assert(p4->property == 2);
ffffffffc02015d8:	4918                	lw	a4,16(a0)
ffffffffc02015da:	4789                	li	a5,2
ffffffffc02015dc:	10f71f63          	bne	a4,a5,ffffffffc02016fa <buddy_check+0x1ea>
    cprintf("[buddy_check_1] after alloc 3 pages:   ");
ffffffffc02015e0:	00002517          	auipc	a0,0x2
ffffffffc02015e4:	a2050513          	addi	a0,a0,-1504 # ffffffffc0203000 <commands+0xbf0>
ffffffffc02015e8:	fe3fe0ef          	jal	ra,ffffffffc02005ca <cprintf>
    struct Page* p5 = alloc_pages(196);
ffffffffc02015ec:	0c400513          	li	a0,196
ffffffffc02015f0:	f36ff0ef          	jal	ra,ffffffffc0200d26 <alloc_pages>
ffffffffc02015f4:	8aaa                	mv	s5,a0
    assert(p5 != NULL);
ffffffffc02015f6:	0e050263          	beqz	a0,ffffffffc02016da <buddy_check+0x1ca>
    assert(p5->property == 8);
ffffffffc02015fa:	4918                	lw	a4,16(a0)
ffffffffc02015fc:	47a1                	li	a5,8
ffffffffc02015fe:	0af71e63          	bne	a4,a5,ffffffffc02016ba <buddy_check+0x1aa>
    cprintf("[buddy_check_1] after alloc 196 pages: ");
ffffffffc0201602:	00002517          	auipc	a0,0x2
ffffffffc0201606:	a4e50513          	addi	a0,a0,-1458 # ffffffffc0203050 <commands+0xc40>
ffffffffc020160a:	fc1fe0ef          	jal	ra,ffffffffc02005ca <cprintf>
    free_pages(p4, 3);
ffffffffc020160e:	458d                	li	a1,3
ffffffffc0201610:	8552                	mv	a0,s4
ffffffffc0201612:	f52ff0ef          	jal	ra,ffffffffc0200d64 <free_pages>
    free_pages(p0, 512);
ffffffffc0201616:	20000593          	li	a1,512
ffffffffc020161a:	8522                	mv	a0,s0
ffffffffc020161c:	f48ff0ef          	jal	ra,ffffffffc0200d64 <free_pages>
    free_pages(p2, 79);
ffffffffc0201620:	04f00593          	li	a1,79
ffffffffc0201624:	854a                	mv	a0,s2
ffffffffc0201626:	f3eff0ef          	jal	ra,ffffffffc0200d64 <free_pages>
    free_pages(p3, 37);
ffffffffc020162a:	02500593          	li	a1,37
ffffffffc020162e:	854e                	mv	a0,s3
ffffffffc0201630:	f34ff0ef          	jal	ra,ffffffffc0200d64 <free_pages>
    free_pages(p5, 196);
ffffffffc0201634:	0c400593          	li	a1,196
ffffffffc0201638:	8556                	mv	a0,s5
ffffffffc020163a:	f2aff0ef          	jal	ra,ffffffffc0200d64 <free_pages>
    free_pages(p1, 513);
ffffffffc020163e:	20100593          	li	a1,513
ffffffffc0201642:	8526                	mv	a0,s1
ffffffffc0201644:	f20ff0ef          	jal	ra,ffffffffc0200d64 <free_pages>
    cprintf("[buddy_check_1] after free:            ");
ffffffffc0201648:	00002517          	auipc	a0,0x2
ffffffffc020164c:	a3050513          	addi	a0,a0,-1488 # ffffffffc0203078 <commands+0xc68>
ffffffffc0201650:	f7bfe0ef          	jal	ra,ffffffffc02005ca <cprintf>
    assert(nr_free_pages() == initial_nr_free_pages);
ffffffffc0201654:	f4eff0ef          	jal	ra,ffffffffc0200da2 <nr_free_pages>
ffffffffc0201658:	04ab1163          	bne	s6,a0,ffffffffc020169a <buddy_check+0x18a>
    buddy_check_1();
}
ffffffffc020165c:	7442                	ld	s0,48(sp)
ffffffffc020165e:	70e2                	ld	ra,56(sp)
ffffffffc0201660:	74a2                	ld	s1,40(sp)
ffffffffc0201662:	7902                	ld	s2,32(sp)
ffffffffc0201664:	69e2                	ld	s3,24(sp)
ffffffffc0201666:	6a42                	ld	s4,16(sp)
ffffffffc0201668:	6aa2                	ld	s5,8(sp)
ffffffffc020166a:	6b02                	ld	s6,0(sp)
    cprintf("[buddy_check_1] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
ffffffffc020166c:	00002517          	auipc	a0,0x2
ffffffffc0201670:	a3450513          	addi	a0,a0,-1484 # ffffffffc02030a0 <commands+0xc90>
}
ffffffffc0201674:	6121                	addi	sp,sp,64
    cprintf("[buddy_check_1] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n");
ffffffffc0201676:	f55fe06f          	j	ffffffffc02005ca <cprintf>
    assert(p0 != NULL);
ffffffffc020167a:	00002697          	auipc	a3,0x2
ffffffffc020167e:	81e68693          	addi	a3,a3,-2018 # ffffffffc0202e98 <commands+0xa88>
ffffffffc0201682:	00001617          	auipc	a2,0x1
ffffffffc0201686:	92660613          	addi	a2,a2,-1754 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc020168a:	0d800593          	li	a1,216
ffffffffc020168e:	00001517          	auipc	a0,0x1
ffffffffc0201692:	43a50513          	addi	a0,a0,1082 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc0201696:	fbdfe0ef          	jal	ra,ffffffffc0200652 <__panic>
    assert(nr_free_pages() == initial_nr_free_pages);
ffffffffc020169a:	00001697          	auipc	a3,0x1
ffffffffc020169e:	6f668693          	addi	a3,a3,1782 # ffffffffc0202d90 <commands+0x980>
ffffffffc02016a2:	00001617          	auipc	a2,0x1
ffffffffc02016a6:	90660613          	addi	a2,a2,-1786 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc02016aa:	10700593          	li	a1,263
ffffffffc02016ae:	00001517          	auipc	a0,0x1
ffffffffc02016b2:	41a50513          	addi	a0,a0,1050 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc02016b6:	f9dfe0ef          	jal	ra,ffffffffc0200652 <__panic>
    assert(p5->property == 8);
ffffffffc02016ba:	00002697          	auipc	a3,0x2
ffffffffc02016be:	97e68693          	addi	a3,a3,-1666 # ffffffffc0203038 <commands+0xc28>
ffffffffc02016c2:	00001617          	auipc	a2,0x1
ffffffffc02016c6:	8e660613          	addi	a2,a2,-1818 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc02016ca:	0f900593          	li	a1,249
ffffffffc02016ce:	00001517          	auipc	a0,0x1
ffffffffc02016d2:	3fa50513          	addi	a0,a0,1018 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc02016d6:	f7dfe0ef          	jal	ra,ffffffffc0200652 <__panic>
    assert(p5 != NULL);
ffffffffc02016da:	00002697          	auipc	a3,0x2
ffffffffc02016de:	94e68693          	addi	a3,a3,-1714 # ffffffffc0203028 <commands+0xc18>
ffffffffc02016e2:	00001617          	auipc	a2,0x1
ffffffffc02016e6:	8c660613          	addi	a2,a2,-1850 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc02016ea:	0f800593          	li	a1,248
ffffffffc02016ee:	00001517          	auipc	a0,0x1
ffffffffc02016f2:	3da50513          	addi	a0,a0,986 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc02016f6:	f5dfe0ef          	jal	ra,ffffffffc0200652 <__panic>
    assert(p4->property == 2);
ffffffffc02016fa:	00002697          	auipc	a3,0x2
ffffffffc02016fe:	8ee68693          	addi	a3,a3,-1810 # ffffffffc0202fe8 <commands+0xbd8>
ffffffffc0201702:	00001617          	auipc	a2,0x1
ffffffffc0201706:	8a660613          	addi	a2,a2,-1882 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc020170a:	0f300593          	li	a1,243
ffffffffc020170e:	00001517          	auipc	a0,0x1
ffffffffc0201712:	3ba50513          	addi	a0,a0,954 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc0201716:	f3dfe0ef          	jal	ra,ffffffffc0200652 <__panic>
    assert(p4 != NULL);
ffffffffc020171a:	00002697          	auipc	a3,0x2
ffffffffc020171e:	8be68693          	addi	a3,a3,-1858 # ffffffffc0202fd8 <commands+0xbc8>
ffffffffc0201722:	00001617          	auipc	a2,0x1
ffffffffc0201726:	88660613          	addi	a2,a2,-1914 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc020172a:	0f200593          	li	a1,242
ffffffffc020172e:	00001517          	auipc	a0,0x1
ffffffffc0201732:	39a50513          	addi	a0,a0,922 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc0201736:	f1dfe0ef          	jal	ra,ffffffffc0200652 <__panic>
    assert(p3->property == 6);
ffffffffc020173a:	00002697          	auipc	a3,0x2
ffffffffc020173e:	85e68693          	addi	a3,a3,-1954 # ffffffffc0202f98 <commands+0xb88>
ffffffffc0201742:	00001617          	auipc	a2,0x1
ffffffffc0201746:	86660613          	addi	a2,a2,-1946 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc020174a:	0ed00593          	li	a1,237
ffffffffc020174e:	00001517          	auipc	a0,0x1
ffffffffc0201752:	37a50513          	addi	a0,a0,890 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc0201756:	efdfe0ef          	jal	ra,ffffffffc0200652 <__panic>
    assert(p3 != NULL);
ffffffffc020175a:	00002697          	auipc	a3,0x2
ffffffffc020175e:	82e68693          	addi	a3,a3,-2002 # ffffffffc0202f88 <commands+0xb78>
ffffffffc0201762:	00001617          	auipc	a2,0x1
ffffffffc0201766:	84660613          	addi	a2,a2,-1978 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc020176a:	0ec00593          	li	a1,236
ffffffffc020176e:	00001517          	auipc	a0,0x1
ffffffffc0201772:	35a50513          	addi	a0,a0,858 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc0201776:	eddfe0ef          	jal	ra,ffffffffc0200652 <__panic>
    assert(p2->property == 7);
ffffffffc020177a:	00001697          	auipc	a3,0x1
ffffffffc020177e:	7ce68693          	addi	a3,a3,1998 # ffffffffc0202f48 <commands+0xb38>
ffffffffc0201782:	00001617          	auipc	a2,0x1
ffffffffc0201786:	82660613          	addi	a2,a2,-2010 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc020178a:	0e700593          	li	a1,231
ffffffffc020178e:	00001517          	auipc	a0,0x1
ffffffffc0201792:	33a50513          	addi	a0,a0,826 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc0201796:	ebdfe0ef          	jal	ra,ffffffffc0200652 <__panic>
    assert(p2 != NULL);
ffffffffc020179a:	00001697          	auipc	a3,0x1
ffffffffc020179e:	79e68693          	addi	a3,a3,1950 # ffffffffc0202f38 <commands+0xb28>
ffffffffc02017a2:	00001617          	auipc	a2,0x1
ffffffffc02017a6:	80660613          	addi	a2,a2,-2042 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc02017aa:	0e600593          	li	a1,230
ffffffffc02017ae:	00001517          	auipc	a0,0x1
ffffffffc02017b2:	31a50513          	addi	a0,a0,794 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc02017b6:	e9dfe0ef          	jal	ra,ffffffffc0200652 <__panic>
    assert(p1->property == 10);
ffffffffc02017ba:	00001697          	auipc	a3,0x1
ffffffffc02017be:	73e68693          	addi	a3,a3,1854 # ffffffffc0202ef8 <commands+0xae8>
ffffffffc02017c2:	00000617          	auipc	a2,0x0
ffffffffc02017c6:	7e660613          	addi	a2,a2,2022 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc02017ca:	0e100593          	li	a1,225
ffffffffc02017ce:	00001517          	auipc	a0,0x1
ffffffffc02017d2:	2fa50513          	addi	a0,a0,762 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc02017d6:	e7dfe0ef          	jal	ra,ffffffffc0200652 <__panic>
    assert(p1 != NULL);
ffffffffc02017da:	00001697          	auipc	a3,0x1
ffffffffc02017de:	70e68693          	addi	a3,a3,1806 # ffffffffc0202ee8 <commands+0xad8>
ffffffffc02017e2:	00000617          	auipc	a2,0x0
ffffffffc02017e6:	7c660613          	addi	a2,a2,1990 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc02017ea:	0e000593          	li	a1,224
ffffffffc02017ee:	00001517          	auipc	a0,0x1
ffffffffc02017f2:	2da50513          	addi	a0,a0,730 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc02017f6:	e5dfe0ef          	jal	ra,ffffffffc0200652 <__panic>
    assert(p0->property == 9);
ffffffffc02017fa:	00001697          	auipc	a3,0x1
ffffffffc02017fe:	6ae68693          	addi	a3,a3,1710 # ffffffffc0202ea8 <commands+0xa98>
ffffffffc0201802:	00000617          	auipc	a2,0x0
ffffffffc0201806:	7a660613          	addi	a2,a2,1958 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc020180a:	0da00593          	li	a1,218
ffffffffc020180e:	00001517          	auipc	a0,0x1
ffffffffc0201812:	2ba50513          	addi	a0,a0,698 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc0201816:	e3dfe0ef          	jal	ra,ffffffffc0200652 <__panic>

ffffffffc020181a <buddy_free_pages>:
static void buddy_free_pages(struct Page *base, size_t n) {
ffffffffc020181a:	7159                	addi	sp,sp,-112
ffffffffc020181c:	f486                	sd	ra,104(sp)
ffffffffc020181e:	f0a2                	sd	s0,96(sp)
ffffffffc0201820:	eca6                	sd	s1,88(sp)
ffffffffc0201822:	e8ca                	sd	s2,80(sp)
ffffffffc0201824:	e4ce                	sd	s3,72(sp)
ffffffffc0201826:	e0d2                	sd	s4,64(sp)
ffffffffc0201828:	fc56                	sd	s5,56(sp)
ffffffffc020182a:	f85a                	sd	s6,48(sp)
ffffffffc020182c:	f45e                	sd	s7,40(sp)
ffffffffc020182e:	f062                	sd	s8,32(sp)
ffffffffc0201830:	ec66                	sd	s9,24(sp)
ffffffffc0201832:	e86a                	sd	s10,16(sp)
ffffffffc0201834:	e46e                	sd	s11,8(sp)
    assert(n > 0);
ffffffffc0201836:	1a058563          	beqz	a1,ffffffffc02019e0 <buddy_free_pages+0x1c6>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020183a:	00006a97          	auipc	s5,0x6
ffffffffc020183e:	d06a8a93          	addi	s5,s5,-762 # ffffffffc0207540 <pages>
ffffffffc0201842:	000ab703          	ld	a4,0(s5)
ffffffffc0201846:	00002b17          	auipc	s6,0x2
ffffffffc020184a:	c4ab3b03          	ld	s6,-950(s6) # ffffffffc0203490 <error_string+0x38>
ffffffffc020184e:	00002997          	auipc	s3,0x2
ffffffffc0201852:	c4a98993          	addi	s3,s3,-950 # ffffffffc0203498 <nbase>
ffffffffc0201856:	40e50733          	sub	a4,a0,a4
ffffffffc020185a:	870d                	srai	a4,a4,0x3
ffffffffc020185c:	03670733          	mul	a4,a4,s6
ffffffffc0201860:	0009b303          	ld	t1,0(s3)
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));
ffffffffc0201864:	00006a17          	auipc	s4,0x6
ffffffffc0201868:	ccca0a13          	addi	s4,s4,-820 # ffffffffc0207530 <fppn>
ffffffffc020186c:	8daa                	mv	s11,a0
    nr_free += 1 << base->property;
ffffffffc020186e:	4914                	lw	a3,16(a0)
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));
ffffffffc0201870:	000a3503          	ld	a0,0(s4)
    nr_free += 1 << base->property;
ffffffffc0201874:	4605                	li	a2,1
ffffffffc0201876:	00d618bb          	sllw	a7,a2,a3
ffffffffc020187a:	00005497          	auipc	s1,0x5
ffffffffc020187e:	79648493          	addi	s1,s1,1942 # ffffffffc0207010 <free_buddy>
ffffffffc0201882:	1084a803          	lw	a6,264(s1)
ffffffffc0201886:	971a                	add	a4,a4,t1
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));
ffffffffc0201888:	40a70433          	sub	s0,a4,a0
ffffffffc020188c:	01144433          	xor	s0,s0,a7
    return page+(ppn-page2ppn(page));
ffffffffc0201890:	40e50733          	sub	a4,a0,a4
ffffffffc0201894:	9722                	add	a4,a4,s0
ffffffffc0201896:	00271413          	slli	s0,a4,0x2
ffffffffc020189a:	943a                	add	s0,s0,a4
    cprintf("buddy_free_pages: Releasing %lu pages starting at address %p with property %u\n", n, free_page, free_page->property);
ffffffffc020189c:	866e                	mv	a2,s11
    nr_free += 1 << base->property;
ffffffffc020189e:	0118073b          	addw	a4,a6,a7
    cprintf("buddy_free_pages: Releasing %lu pages starting at address %p with property %u\n", n, free_page, free_page->property);
ffffffffc02018a2:	00002517          	auipc	a0,0x2
ffffffffc02018a6:	84650513          	addi	a0,a0,-1978 # ffffffffc02030e8 <commands+0xcd8>
    nr_free += 1 << base->property;
ffffffffc02018aa:	10e4a423          	sw	a4,264(s1)
    cprintf("buddy_free_pages: Releasing %lu pages starting at address %p with property %u\n", n, free_page, free_page->property);
ffffffffc02018ae:	d1dfe0ef          	jal	ra,ffffffffc02005ca <cprintf>
    list_add(&(free_list[free_page->property]), &(free_page->page_link));
ffffffffc02018b2:	010da603          	lw	a2,16(s11)
    return page+(ppn-page2ppn(page));
ffffffffc02018b6:	040e                	slli	s0,s0,0x3
ffffffffc02018b8:	946e                	add	s0,s0,s11
    __list_add(elm, listelm, listelm->next);
ffffffffc02018ba:	02061793          	slli	a5,a2,0x20
ffffffffc02018be:	01c7d713          	srli	a4,a5,0x1c
ffffffffc02018c2:	00e48833          	add	a6,s1,a4
ffffffffc02018c6:	01083503          	ld	a0,16(a6)
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02018ca:	640c                	ld	a1,8(s0)
    list_add(&(free_list[free_page->property]), &(free_page->page_link));
ffffffffc02018cc:	018d8d13          	addi	s10,s11,24
    prev->next = next->prev = elm;
ffffffffc02018d0:	01a53023          	sd	s10,0(a0)
ffffffffc02018d4:	0721                	addi	a4,a4,8
ffffffffc02018d6:	9726                	add	a4,a4,s1
ffffffffc02018d8:	01a83823          	sd	s10,16(a6)
ffffffffc02018dc:	8185                	srli	a1,a1,0x1
    elm->prev = prev;
ffffffffc02018de:	00edbc23          	sd	a4,24(s11)
    elm->next = next;
ffffffffc02018e2:	02adb023          	sd	a0,32(s11)
    while (!PageProperty(free_page_buddy) && free_page->property < 14) {
ffffffffc02018e6:	0015f713          	andi	a4,a1,1
            ClearPageProperty(free_page);
ffffffffc02018ea:	008d8913          	addi	s2,s11,8
    while (!PageProperty(free_page_buddy) && free_page->property < 14) {
ffffffffc02018ee:	ef51                	bnez	a4,ffffffffc020198a <buddy_free_pages+0x170>
ffffffffc02018f0:	4bb5                	li	s7,13
        cprintf("buddy_free_pages: Merged block, new property: %u, added to free_list[%u]\n", free_page->property, free_page->property);
ffffffffc02018f2:	00002c97          	auipc	s9,0x2
ffffffffc02018f6:	886c8c93          	addi	s9,s9,-1914 # ffffffffc0203178 <commands+0xd68>
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));
ffffffffc02018fa:	4c05                	li	s8,1
    while (!PageProperty(free_page_buddy) && free_page->property < 14) {
ffffffffc02018fc:	08cbe763          	bltu	s7,a2,ffffffffc020198a <buddy_free_pages+0x170>
        if (free_page_buddy < free_page) {
ffffffffc0201900:	0bb46c63          	bltu	s0,s11,ffffffffc02019b8 <buddy_free_pages+0x19e>
    __list_del(listelm->prev, listelm->next);
ffffffffc0201904:	018db503          	ld	a0,24(s11)
ffffffffc0201908:	020db583          	ld	a1,32(s11)
        free_page->property += 1;
ffffffffc020190c:	2605                	addiw	a2,a2,1
    __list_add(elm, listelm, listelm->next);
ffffffffc020190e:	02061793          	slli	a5,a2,0x20
    prev->next = next;
ffffffffc0201912:	e50c                	sd	a1,8(a0)
    next->prev = prev;
ffffffffc0201914:	e188                	sd	a0,0(a1)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201916:	01843803          	ld	a6,24(s0)
ffffffffc020191a:	700c                	ld	a1,32(s0)
    __list_add(elm, listelm, listelm->next);
ffffffffc020191c:	01c7d713          	srli	a4,a5,0x1c
ffffffffc0201920:	00e48533          	add	a0,s1,a4
    prev->next = next;
ffffffffc0201924:	00b83423          	sd	a1,8(a6)
    next->prev = prev;
ffffffffc0201928:	0105b023          	sd	a6,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc020192c:	690c                	ld	a1,16(a0)
ffffffffc020192e:	00cda823          	sw	a2,16(s11)
        list_add(&(free_list[free_page->property]), &(free_page->page_link));
ffffffffc0201932:	0721                	addi	a4,a4,8
    prev->next = next->prev = elm;
ffffffffc0201934:	01a5b023          	sd	s10,0(a1)
ffffffffc0201938:	01a53823          	sd	s10,16(a0)
ffffffffc020193c:	9726                	add	a4,a4,s1
    elm->next = next;
ffffffffc020193e:	02bdb023          	sd	a1,32(s11)
    elm->prev = prev;
ffffffffc0201942:	00edbc23          	sd	a4,24(s11)
        cprintf("buddy_free_pages: Merged block, new property: %u, added to free_list[%u]\n", free_page->property, free_page->property);
ffffffffc0201946:	85b2                	mv	a1,a2
ffffffffc0201948:	8566                	mv	a0,s9
ffffffffc020194a:	c81fe0ef          	jal	ra,ffffffffc02005ca <cprintf>
ffffffffc020194e:	000ab703          	ld	a4,0(s5)
ffffffffc0201952:	0009b503          	ld	a0,0(s3)
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));
ffffffffc0201956:	000a3583          	ld	a1,0(s4)
ffffffffc020195a:	40ed8733          	sub	a4,s11,a4
ffffffffc020195e:	870d                	srai	a4,a4,0x3
ffffffffc0201960:	03670733          	mul	a4,a4,s6
    uint32_t power=page->property; 
ffffffffc0201964:	010da603          	lw	a2,16(s11)
    size_t ppn=fppn+((1<<power)^(page2ppn(page)-fppn));
ffffffffc0201968:	00cc143b          	sllw	s0,s8,a2
ffffffffc020196c:	972a                	add	a4,a4,a0
ffffffffc020196e:	40b70533          	sub	a0,a4,a1
ffffffffc0201972:	8c29                	xor	s0,s0,a0
    return page+(ppn-page2ppn(page));
ffffffffc0201974:	40e58733          	sub	a4,a1,a4
ffffffffc0201978:	9722                	add	a4,a4,s0
ffffffffc020197a:	00271413          	slli	s0,a4,0x2
ffffffffc020197e:	943a                	add	s0,s0,a4
ffffffffc0201980:	040e                	slli	s0,s0,0x3
ffffffffc0201982:	946e                	add	s0,s0,s11
ffffffffc0201984:	6418                	ld	a4,8(s0)
    while (!PageProperty(free_page_buddy) && free_page->property < 14) {
ffffffffc0201986:	8b09                	andi	a4,a4,2
ffffffffc0201988:	db35                	beqz	a4,ffffffffc02018fc <buddy_free_pages+0xe2>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020198a:	57f5                	li	a5,-3
ffffffffc020198c:	60f9302f          	amoand.d	zero,a5,(s2)
}
ffffffffc0201990:	7406                	ld	s0,96(sp)
ffffffffc0201992:	70a6                	ld	ra,104(sp)
ffffffffc0201994:	64e6                	ld	s1,88(sp)
ffffffffc0201996:	6946                	ld	s2,80(sp)
ffffffffc0201998:	69a6                	ld	s3,72(sp)
ffffffffc020199a:	6a06                	ld	s4,64(sp)
ffffffffc020199c:	7ae2                	ld	s5,56(sp)
ffffffffc020199e:	7b42                	ld	s6,48(sp)
ffffffffc02019a0:	7ba2                	ld	s7,40(sp)
ffffffffc02019a2:	7c02                	ld	s8,32(sp)
ffffffffc02019a4:	6ce2                	ld	s9,24(sp)
ffffffffc02019a6:	6d42                	ld	s10,16(sp)
ffffffffc02019a8:	6da2                	ld	s11,8(sp)
    cprintf("buddy_free_pages: Pages successfully released\n");
ffffffffc02019aa:	00002517          	auipc	a0,0x2
ffffffffc02019ae:	81e50513          	addi	a0,a0,-2018 # ffffffffc02031c8 <commands+0xdb8>
}
ffffffffc02019b2:	6165                	addi	sp,sp,112
    cprintf("buddy_free_pages: Pages successfully released\n");
ffffffffc02019b4:	c17fe06f          	j	ffffffffc02005ca <cprintf>
            free_page->property = 0;
ffffffffc02019b8:	000da823          	sw	zero,16(s11)
ffffffffc02019bc:	57f5                	li	a5,-3
ffffffffc02019be:	60f9302f          	amoand.d	zero,a5,(s2)
            cprintf("buddy_free_pages: Swapped free_page and free_page_buddy\n");
ffffffffc02019c2:	00001517          	auipc	a0,0x1
ffffffffc02019c6:	77650513          	addi	a0,a0,1910 # ffffffffc0203138 <commands+0xd28>
ffffffffc02019ca:	c01fe0ef          	jal	ra,ffffffffc02005ca <cprintf>
    ClearPageProperty(free_page);
ffffffffc02019ce:	876e                	mv	a4,s11
        free_page->property += 1;
ffffffffc02019d0:	4810                	lw	a2,16(s0)
    ClearPageProperty(free_page);
ffffffffc02019d2:	8da2                	mv	s11,s0
ffffffffc02019d4:	00840913          	addi	s2,s0,8
ffffffffc02019d8:	01840d13          	addi	s10,s0,24
ffffffffc02019dc:	843a                	mv	s0,a4
ffffffffc02019de:	b71d                	j	ffffffffc0201904 <buddy_free_pages+0xea>
    assert(n > 0);
ffffffffc02019e0:	00001697          	auipc	a3,0x1
ffffffffc02019e4:	0e068693          	addi	a3,a3,224 # ffffffffc0202ac0 <commands+0x6b0>
ffffffffc02019e8:	00000617          	auipc	a2,0x0
ffffffffc02019ec:	5c060613          	addi	a2,a2,1472 # ffffffffc0201fa8 <etext+0x3a>
ffffffffc02019f0:	08100593          	li	a1,129
ffffffffc02019f4:	00001517          	auipc	a0,0x1
ffffffffc02019f8:	0d450513          	addi	a0,a0,212 # ffffffffc0202ac8 <commands+0x6b8>
ffffffffc02019fc:	c57fe0ef          	jal	ra,ffffffffc0200652 <__panic>

ffffffffc0201a00 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201a00:	00054783          	lbu	a5,0(a0)
strlen(const char *s) {
ffffffffc0201a04:	872a                	mv	a4,a0
    size_t cnt = 0;
ffffffffc0201a06:	4501                	li	a0,0
    while (*s ++ != '\0') {
ffffffffc0201a08:	cb81                	beqz	a5,ffffffffc0201a18 <strlen+0x18>
        cnt ++;
ffffffffc0201a0a:	0505                	addi	a0,a0,1
    while (*s ++ != '\0') {
ffffffffc0201a0c:	00a707b3          	add	a5,a4,a0
ffffffffc0201a10:	0007c783          	lbu	a5,0(a5)
ffffffffc0201a14:	fbfd                	bnez	a5,ffffffffc0201a0a <strlen+0xa>
ffffffffc0201a16:	8082                	ret
    }
    return cnt;
}
ffffffffc0201a18:	8082                	ret

ffffffffc0201a1a <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0201a1a:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201a1c:	e589                	bnez	a1,ffffffffc0201a26 <strnlen+0xc>
ffffffffc0201a1e:	a811                	j	ffffffffc0201a32 <strnlen+0x18>
        cnt ++;
ffffffffc0201a20:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201a22:	00f58863          	beq	a1,a5,ffffffffc0201a32 <strnlen+0x18>
ffffffffc0201a26:	00f50733          	add	a4,a0,a5
ffffffffc0201a2a:	00074703          	lbu	a4,0(a4)
ffffffffc0201a2e:	fb6d                	bnez	a4,ffffffffc0201a20 <strnlen+0x6>
ffffffffc0201a30:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc0201a32:	852e                	mv	a0,a1
ffffffffc0201a34:	8082                	ret

ffffffffc0201a36 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a36:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201a3a:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a3e:	cb89                	beqz	a5,ffffffffc0201a50 <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc0201a40:	0505                	addi	a0,a0,1
ffffffffc0201a42:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201a44:	fee789e3          	beq	a5,a4,ffffffffc0201a36 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201a48:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201a4c:	9d19                	subw	a0,a0,a4
ffffffffc0201a4e:	8082                	ret
ffffffffc0201a50:	4501                	li	a0,0
ffffffffc0201a52:	bfed                	j	ffffffffc0201a4c <strcmp+0x16>

ffffffffc0201a54 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201a54:	00054783          	lbu	a5,0(a0)
ffffffffc0201a58:	c799                	beqz	a5,ffffffffc0201a66 <strchr+0x12>
        if (*s == c) {
ffffffffc0201a5a:	00f58763          	beq	a1,a5,ffffffffc0201a68 <strchr+0x14>
    while (*s != '\0') {
ffffffffc0201a5e:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc0201a62:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201a64:	fbfd                	bnez	a5,ffffffffc0201a5a <strchr+0x6>
    }
    return NULL;
ffffffffc0201a66:	4501                	li	a0,0
}
ffffffffc0201a68:	8082                	ret

ffffffffc0201a6a <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201a6a:	ca01                	beqz	a2,ffffffffc0201a7a <memset+0x10>
ffffffffc0201a6c:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201a6e:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201a70:	0785                	addi	a5,a5,1
ffffffffc0201a72:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201a76:	fec79de3          	bne	a5,a2,ffffffffc0201a70 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201a7a:	8082                	ret

ffffffffc0201a7c <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201a7c:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a80:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201a82:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a86:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201a88:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201a8c:	f022                	sd	s0,32(sp)
ffffffffc0201a8e:	ec26                	sd	s1,24(sp)
ffffffffc0201a90:	e84a                	sd	s2,16(sp)
ffffffffc0201a92:	f406                	sd	ra,40(sp)
ffffffffc0201a94:	e44e                	sd	s3,8(sp)
ffffffffc0201a96:	84aa                	mv	s1,a0
ffffffffc0201a98:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201a9a:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201a9e:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0201aa0:	03067e63          	bgeu	a2,a6,ffffffffc0201adc <printnum+0x60>
ffffffffc0201aa4:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0201aa6:	00805763          	blez	s0,ffffffffc0201ab4 <printnum+0x38>
ffffffffc0201aaa:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201aac:	85ca                	mv	a1,s2
ffffffffc0201aae:	854e                	mv	a0,s3
ffffffffc0201ab0:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201ab2:	fc65                	bnez	s0,ffffffffc0201aaa <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201ab4:	1a02                	slli	s4,s4,0x20
ffffffffc0201ab6:	00001797          	auipc	a5,0x1
ffffffffc0201aba:	79278793          	addi	a5,a5,1938 # ffffffffc0203248 <buddy_pmm_manager+0x38>
ffffffffc0201abe:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201ac2:	9a3e                	add	s4,s4,a5
}
ffffffffc0201ac4:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201ac6:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201aca:	70a2                	ld	ra,40(sp)
ffffffffc0201acc:	69a2                	ld	s3,8(sp)
ffffffffc0201ace:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201ad0:	85ca                	mv	a1,s2
ffffffffc0201ad2:	87a6                	mv	a5,s1
}
ffffffffc0201ad4:	6942                	ld	s2,16(sp)
ffffffffc0201ad6:	64e2                	ld	s1,24(sp)
ffffffffc0201ad8:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201ada:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201adc:	03065633          	divu	a2,a2,a6
ffffffffc0201ae0:	8722                	mv	a4,s0
ffffffffc0201ae2:	f9bff0ef          	jal	ra,ffffffffc0201a7c <printnum>
ffffffffc0201ae6:	b7f9                	j	ffffffffc0201ab4 <printnum+0x38>

ffffffffc0201ae8 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201ae8:	7119                	addi	sp,sp,-128
ffffffffc0201aea:	f4a6                	sd	s1,104(sp)
ffffffffc0201aec:	f0ca                	sd	s2,96(sp)
ffffffffc0201aee:	ecce                	sd	s3,88(sp)
ffffffffc0201af0:	e8d2                	sd	s4,80(sp)
ffffffffc0201af2:	e4d6                	sd	s5,72(sp)
ffffffffc0201af4:	e0da                	sd	s6,64(sp)
ffffffffc0201af6:	fc5e                	sd	s7,56(sp)
ffffffffc0201af8:	f06a                	sd	s10,32(sp)
ffffffffc0201afa:	fc86                	sd	ra,120(sp)
ffffffffc0201afc:	f8a2                	sd	s0,112(sp)
ffffffffc0201afe:	f862                	sd	s8,48(sp)
ffffffffc0201b00:	f466                	sd	s9,40(sp)
ffffffffc0201b02:	ec6e                	sd	s11,24(sp)
ffffffffc0201b04:	892a                	mv	s2,a0
ffffffffc0201b06:	84ae                	mv	s1,a1
ffffffffc0201b08:	8d32                	mv	s10,a2
ffffffffc0201b0a:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201b0c:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201b10:	5b7d                	li	s6,-1
ffffffffc0201b12:	00001a97          	auipc	s5,0x1
ffffffffc0201b16:	76aa8a93          	addi	s5,s5,1898 # ffffffffc020327c <buddy_pmm_manager+0x6c>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201b1a:	00002b97          	auipc	s7,0x2
ffffffffc0201b1e:	93eb8b93          	addi	s7,s7,-1730 # ffffffffc0203458 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201b22:	000d4503          	lbu	a0,0(s10)
ffffffffc0201b26:	001d0413          	addi	s0,s10,1
ffffffffc0201b2a:	01350a63          	beq	a0,s3,ffffffffc0201b3e <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201b2e:	c121                	beqz	a0,ffffffffc0201b6e <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201b30:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201b32:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201b34:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201b36:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201b3a:	ff351ae3          	bne	a0,s3,ffffffffc0201b2e <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b3e:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201b42:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201b46:	4c81                	li	s9,0
ffffffffc0201b48:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201b4a:	5c7d                	li	s8,-1
ffffffffc0201b4c:	5dfd                	li	s11,-1
ffffffffc0201b4e:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201b52:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b54:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201b58:	0ff5f593          	zext.b	a1,a1
ffffffffc0201b5c:	00140d13          	addi	s10,s0,1
ffffffffc0201b60:	04b56263          	bltu	a0,a1,ffffffffc0201ba4 <vprintfmt+0xbc>
ffffffffc0201b64:	058a                	slli	a1,a1,0x2
ffffffffc0201b66:	95d6                	add	a1,a1,s5
ffffffffc0201b68:	4194                	lw	a3,0(a1)
ffffffffc0201b6a:	96d6                	add	a3,a3,s5
ffffffffc0201b6c:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201b6e:	70e6                	ld	ra,120(sp)
ffffffffc0201b70:	7446                	ld	s0,112(sp)
ffffffffc0201b72:	74a6                	ld	s1,104(sp)
ffffffffc0201b74:	7906                	ld	s2,96(sp)
ffffffffc0201b76:	69e6                	ld	s3,88(sp)
ffffffffc0201b78:	6a46                	ld	s4,80(sp)
ffffffffc0201b7a:	6aa6                	ld	s5,72(sp)
ffffffffc0201b7c:	6b06                	ld	s6,64(sp)
ffffffffc0201b7e:	7be2                	ld	s7,56(sp)
ffffffffc0201b80:	7c42                	ld	s8,48(sp)
ffffffffc0201b82:	7ca2                	ld	s9,40(sp)
ffffffffc0201b84:	7d02                	ld	s10,32(sp)
ffffffffc0201b86:	6de2                	ld	s11,24(sp)
ffffffffc0201b88:	6109                	addi	sp,sp,128
ffffffffc0201b8a:	8082                	ret
            padc = '0';
ffffffffc0201b8c:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0201b8e:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b92:	846a                	mv	s0,s10
ffffffffc0201b94:	00140d13          	addi	s10,s0,1
ffffffffc0201b98:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0201b9c:	0ff5f593          	zext.b	a1,a1
ffffffffc0201ba0:	fcb572e3          	bgeu	a0,a1,ffffffffc0201b64 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0201ba4:	85a6                	mv	a1,s1
ffffffffc0201ba6:	02500513          	li	a0,37
ffffffffc0201baa:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201bac:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201bb0:	8d22                	mv	s10,s0
ffffffffc0201bb2:	f73788e3          	beq	a5,s3,ffffffffc0201b22 <vprintfmt+0x3a>
ffffffffc0201bb6:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201bba:	1d7d                	addi	s10,s10,-1
ffffffffc0201bbc:	ff379de3          	bne	a5,s3,ffffffffc0201bb6 <vprintfmt+0xce>
ffffffffc0201bc0:	b78d                	j	ffffffffc0201b22 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201bc2:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0201bc6:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201bca:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201bcc:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201bd0:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201bd4:	02d86463          	bltu	a6,a3,ffffffffc0201bfc <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0201bd8:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201bdc:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201be0:	0186873b          	addw	a4,a3,s8
ffffffffc0201be4:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201be8:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201bea:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201bee:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201bf0:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0201bf4:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201bf8:	fed870e3          	bgeu	a6,a3,ffffffffc0201bd8 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201bfc:	f40ddce3          	bgez	s11,ffffffffc0201b54 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201c00:	8de2                	mv	s11,s8
ffffffffc0201c02:	5c7d                	li	s8,-1
ffffffffc0201c04:	bf81                	j	ffffffffc0201b54 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0201c06:	fffdc693          	not	a3,s11
ffffffffc0201c0a:	96fd                	srai	a3,a3,0x3f
ffffffffc0201c0c:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c10:	00144603          	lbu	a2,1(s0)
ffffffffc0201c14:	2d81                	sext.w	s11,s11
ffffffffc0201c16:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c18:	bf35                	j	ffffffffc0201b54 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201c1a:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c1e:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201c22:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c24:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0201c26:	bfd9                	j	ffffffffc0201bfc <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0201c28:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c2a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c2e:	01174463          	blt	a4,a7,ffffffffc0201c36 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201c32:	1a088e63          	beqz	a7,ffffffffc0201dee <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0201c36:	000a3603          	ld	a2,0(s4)
ffffffffc0201c3a:	46c1                	li	a3,16
ffffffffc0201c3c:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201c3e:	2781                	sext.w	a5,a5
ffffffffc0201c40:	876e                	mv	a4,s11
ffffffffc0201c42:	85a6                	mv	a1,s1
ffffffffc0201c44:	854a                	mv	a0,s2
ffffffffc0201c46:	e37ff0ef          	jal	ra,ffffffffc0201a7c <printnum>
            break;
ffffffffc0201c4a:	bde1                	j	ffffffffc0201b22 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201c4c:	000a2503          	lw	a0,0(s4)
ffffffffc0201c50:	85a6                	mv	a1,s1
ffffffffc0201c52:	0a21                	addi	s4,s4,8
ffffffffc0201c54:	9902                	jalr	s2
            break;
ffffffffc0201c56:	b5f1                	j	ffffffffc0201b22 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c58:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c5a:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c5e:	01174463          	blt	a4,a7,ffffffffc0201c66 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0201c62:	18088163          	beqz	a7,ffffffffc0201de4 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0201c66:	000a3603          	ld	a2,0(s4)
ffffffffc0201c6a:	46a9                	li	a3,10
ffffffffc0201c6c:	8a2e                	mv	s4,a1
ffffffffc0201c6e:	bfc1                	j	ffffffffc0201c3e <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c70:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201c74:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c76:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c78:	bdf1                	j	ffffffffc0201b54 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0201c7a:	85a6                	mv	a1,s1
ffffffffc0201c7c:	02500513          	li	a0,37
ffffffffc0201c80:	9902                	jalr	s2
            break;
ffffffffc0201c82:	b545                	j	ffffffffc0201b22 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c84:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0201c88:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c8a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c8c:	b5e1                	j	ffffffffc0201b54 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0201c8e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201c90:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201c94:	01174463          	blt	a4,a7,ffffffffc0201c9c <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0201c98:	14088163          	beqz	a7,ffffffffc0201dda <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0201c9c:	000a3603          	ld	a2,0(s4)
ffffffffc0201ca0:	46a1                	li	a3,8
ffffffffc0201ca2:	8a2e                	mv	s4,a1
ffffffffc0201ca4:	bf69                	j	ffffffffc0201c3e <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0201ca6:	03000513          	li	a0,48
ffffffffc0201caa:	85a6                	mv	a1,s1
ffffffffc0201cac:	e03e                	sd	a5,0(sp)
ffffffffc0201cae:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201cb0:	85a6                	mv	a1,s1
ffffffffc0201cb2:	07800513          	li	a0,120
ffffffffc0201cb6:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201cb8:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201cba:	6782                	ld	a5,0(sp)
ffffffffc0201cbc:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201cbe:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201cc2:	bfb5                	j	ffffffffc0201c3e <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201cc4:	000a3403          	ld	s0,0(s4)
ffffffffc0201cc8:	008a0713          	addi	a4,s4,8
ffffffffc0201ccc:	e03a                	sd	a4,0(sp)
ffffffffc0201cce:	14040263          	beqz	s0,ffffffffc0201e12 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201cd2:	0fb05763          	blez	s11,ffffffffc0201dc0 <vprintfmt+0x2d8>
ffffffffc0201cd6:	02d00693          	li	a3,45
ffffffffc0201cda:	0cd79163          	bne	a5,a3,ffffffffc0201d9c <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cde:	00044783          	lbu	a5,0(s0)
ffffffffc0201ce2:	0007851b          	sext.w	a0,a5
ffffffffc0201ce6:	cf85                	beqz	a5,ffffffffc0201d1e <vprintfmt+0x236>
ffffffffc0201ce8:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201cec:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cf0:	000c4563          	bltz	s8,ffffffffc0201cfa <vprintfmt+0x212>
ffffffffc0201cf4:	3c7d                	addiw	s8,s8,-1
ffffffffc0201cf6:	036c0263          	beq	s8,s6,ffffffffc0201d1a <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201cfa:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201cfc:	0e0c8e63          	beqz	s9,ffffffffc0201df8 <vprintfmt+0x310>
ffffffffc0201d00:	3781                	addiw	a5,a5,-32
ffffffffc0201d02:	0ef47b63          	bgeu	s0,a5,ffffffffc0201df8 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201d06:	03f00513          	li	a0,63
ffffffffc0201d0a:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d0c:	000a4783          	lbu	a5,0(s4)
ffffffffc0201d10:	3dfd                	addiw	s11,s11,-1
ffffffffc0201d12:	0a05                	addi	s4,s4,1
ffffffffc0201d14:	0007851b          	sext.w	a0,a5
ffffffffc0201d18:	ffe1                	bnez	a5,ffffffffc0201cf0 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201d1a:	01b05963          	blez	s11,ffffffffc0201d2c <vprintfmt+0x244>
ffffffffc0201d1e:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201d20:	85a6                	mv	a1,s1
ffffffffc0201d22:	02000513          	li	a0,32
ffffffffc0201d26:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201d28:	fe0d9be3          	bnez	s11,ffffffffc0201d1e <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201d2c:	6a02                	ld	s4,0(sp)
ffffffffc0201d2e:	bbd5                	j	ffffffffc0201b22 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201d30:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201d32:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201d36:	01174463          	blt	a4,a7,ffffffffc0201d3e <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201d3a:	08088d63          	beqz	a7,ffffffffc0201dd4 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201d3e:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201d42:	0a044d63          	bltz	s0,ffffffffc0201dfc <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201d46:	8622                	mv	a2,s0
ffffffffc0201d48:	8a66                	mv	s4,s9
ffffffffc0201d4a:	46a9                	li	a3,10
ffffffffc0201d4c:	bdcd                	j	ffffffffc0201c3e <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201d4e:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201d52:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201d54:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201d56:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201d5a:	8fb5                	xor	a5,a5,a3
ffffffffc0201d5c:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201d60:	02d74163          	blt	a4,a3,ffffffffc0201d82 <vprintfmt+0x29a>
ffffffffc0201d64:	00369793          	slli	a5,a3,0x3
ffffffffc0201d68:	97de                	add	a5,a5,s7
ffffffffc0201d6a:	639c                	ld	a5,0(a5)
ffffffffc0201d6c:	cb99                	beqz	a5,ffffffffc0201d82 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201d6e:	86be                	mv	a3,a5
ffffffffc0201d70:	00001617          	auipc	a2,0x1
ffffffffc0201d74:	50860613          	addi	a2,a2,1288 # ffffffffc0203278 <buddy_pmm_manager+0x68>
ffffffffc0201d78:	85a6                	mv	a1,s1
ffffffffc0201d7a:	854a                	mv	a0,s2
ffffffffc0201d7c:	0ce000ef          	jal	ra,ffffffffc0201e4a <printfmt>
ffffffffc0201d80:	b34d                	j	ffffffffc0201b22 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201d82:	00001617          	auipc	a2,0x1
ffffffffc0201d86:	4e660613          	addi	a2,a2,1254 # ffffffffc0203268 <buddy_pmm_manager+0x58>
ffffffffc0201d8a:	85a6                	mv	a1,s1
ffffffffc0201d8c:	854a                	mv	a0,s2
ffffffffc0201d8e:	0bc000ef          	jal	ra,ffffffffc0201e4a <printfmt>
ffffffffc0201d92:	bb41                	j	ffffffffc0201b22 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201d94:	00001417          	auipc	s0,0x1
ffffffffc0201d98:	4cc40413          	addi	s0,s0,1228 # ffffffffc0203260 <buddy_pmm_manager+0x50>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201d9c:	85e2                	mv	a1,s8
ffffffffc0201d9e:	8522                	mv	a0,s0
ffffffffc0201da0:	e43e                	sd	a5,8(sp)
ffffffffc0201da2:	c79ff0ef          	jal	ra,ffffffffc0201a1a <strnlen>
ffffffffc0201da6:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201daa:	01b05b63          	blez	s11,ffffffffc0201dc0 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc0201dae:	67a2                	ld	a5,8(sp)
ffffffffc0201db0:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201db4:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201db6:	85a6                	mv	a1,s1
ffffffffc0201db8:	8552                	mv	a0,s4
ffffffffc0201dba:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201dbc:	fe0d9ce3          	bnez	s11,ffffffffc0201db4 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201dc0:	00044783          	lbu	a5,0(s0)
ffffffffc0201dc4:	00140a13          	addi	s4,s0,1
ffffffffc0201dc8:	0007851b          	sext.w	a0,a5
ffffffffc0201dcc:	d3a5                	beqz	a5,ffffffffc0201d2c <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201dce:	05e00413          	li	s0,94
ffffffffc0201dd2:	bf39                	j	ffffffffc0201cf0 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201dd4:	000a2403          	lw	s0,0(s4)
ffffffffc0201dd8:	b7ad                	j	ffffffffc0201d42 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201dda:	000a6603          	lwu	a2,0(s4)
ffffffffc0201dde:	46a1                	li	a3,8
ffffffffc0201de0:	8a2e                	mv	s4,a1
ffffffffc0201de2:	bdb1                	j	ffffffffc0201c3e <vprintfmt+0x156>
ffffffffc0201de4:	000a6603          	lwu	a2,0(s4)
ffffffffc0201de8:	46a9                	li	a3,10
ffffffffc0201dea:	8a2e                	mv	s4,a1
ffffffffc0201dec:	bd89                	j	ffffffffc0201c3e <vprintfmt+0x156>
ffffffffc0201dee:	000a6603          	lwu	a2,0(s4)
ffffffffc0201df2:	46c1                	li	a3,16
ffffffffc0201df4:	8a2e                	mv	s4,a1
ffffffffc0201df6:	b5a1                	j	ffffffffc0201c3e <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201df8:	9902                	jalr	s2
ffffffffc0201dfa:	bf09                	j	ffffffffc0201d0c <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201dfc:	85a6                	mv	a1,s1
ffffffffc0201dfe:	02d00513          	li	a0,45
ffffffffc0201e02:	e03e                	sd	a5,0(sp)
ffffffffc0201e04:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201e06:	6782                	ld	a5,0(sp)
ffffffffc0201e08:	8a66                	mv	s4,s9
ffffffffc0201e0a:	40800633          	neg	a2,s0
ffffffffc0201e0e:	46a9                	li	a3,10
ffffffffc0201e10:	b53d                	j	ffffffffc0201c3e <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201e12:	03b05163          	blez	s11,ffffffffc0201e34 <vprintfmt+0x34c>
ffffffffc0201e16:	02d00693          	li	a3,45
ffffffffc0201e1a:	f6d79de3          	bne	a5,a3,ffffffffc0201d94 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201e1e:	00001417          	auipc	s0,0x1
ffffffffc0201e22:	44240413          	addi	s0,s0,1090 # ffffffffc0203260 <buddy_pmm_manager+0x50>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201e26:	02800793          	li	a5,40
ffffffffc0201e2a:	02800513          	li	a0,40
ffffffffc0201e2e:	00140a13          	addi	s4,s0,1
ffffffffc0201e32:	bd6d                	j	ffffffffc0201cec <vprintfmt+0x204>
ffffffffc0201e34:	00001a17          	auipc	s4,0x1
ffffffffc0201e38:	42da0a13          	addi	s4,s4,1069 # ffffffffc0203261 <buddy_pmm_manager+0x51>
ffffffffc0201e3c:	02800513          	li	a0,40
ffffffffc0201e40:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201e44:	05e00413          	li	s0,94
ffffffffc0201e48:	b565                	j	ffffffffc0201cf0 <vprintfmt+0x208>

ffffffffc0201e4a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e4a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201e4c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e50:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201e52:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201e54:	ec06                	sd	ra,24(sp)
ffffffffc0201e56:	f83a                	sd	a4,48(sp)
ffffffffc0201e58:	fc3e                	sd	a5,56(sp)
ffffffffc0201e5a:	e0c2                	sd	a6,64(sp)
ffffffffc0201e5c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201e5e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201e60:	c89ff0ef          	jal	ra,ffffffffc0201ae8 <vprintfmt>
}
ffffffffc0201e64:	60e2                	ld	ra,24(sp)
ffffffffc0201e66:	6161                	addi	sp,sp,80
ffffffffc0201e68:	8082                	ret

ffffffffc0201e6a <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201e6a:	715d                	addi	sp,sp,-80
ffffffffc0201e6c:	e486                	sd	ra,72(sp)
ffffffffc0201e6e:	e0a6                	sd	s1,64(sp)
ffffffffc0201e70:	fc4a                	sd	s2,56(sp)
ffffffffc0201e72:	f84e                	sd	s3,48(sp)
ffffffffc0201e74:	f452                	sd	s4,40(sp)
ffffffffc0201e76:	f056                	sd	s5,32(sp)
ffffffffc0201e78:	ec5a                	sd	s6,24(sp)
ffffffffc0201e7a:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc0201e7c:	c901                	beqz	a0,ffffffffc0201e8c <readline+0x22>
ffffffffc0201e7e:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc0201e80:	00001517          	auipc	a0,0x1
ffffffffc0201e84:	3f850513          	addi	a0,a0,1016 # ffffffffc0203278 <buddy_pmm_manager+0x68>
ffffffffc0201e88:	f42fe0ef          	jal	ra,ffffffffc02005ca <cprintf>
readline(const char *prompt) {
ffffffffc0201e8c:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e8e:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201e90:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201e92:	4aa9                	li	s5,10
ffffffffc0201e94:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201e96:	00005b97          	auipc	s7,0x5
ffffffffc0201e9a:	28ab8b93          	addi	s7,s7,650 # ffffffffc0207120 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201e9e:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201ea2:	fa0fe0ef          	jal	ra,ffffffffc0200642 <getchar>
        if (c < 0) {
ffffffffc0201ea6:	00054a63          	bltz	a0,ffffffffc0201eba <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201eaa:	00a95a63          	bge	s2,a0,ffffffffc0201ebe <readline+0x54>
ffffffffc0201eae:	029a5263          	bge	s4,s1,ffffffffc0201ed2 <readline+0x68>
        c = getchar();
ffffffffc0201eb2:	f90fe0ef          	jal	ra,ffffffffc0200642 <getchar>
        if (c < 0) {
ffffffffc0201eb6:	fe055ae3          	bgez	a0,ffffffffc0201eaa <readline+0x40>
            return NULL;
ffffffffc0201eba:	4501                	li	a0,0
ffffffffc0201ebc:	a091                	j	ffffffffc0201f00 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201ebe:	03351463          	bne	a0,s3,ffffffffc0201ee6 <readline+0x7c>
ffffffffc0201ec2:	e8a9                	bnez	s1,ffffffffc0201f14 <readline+0xaa>
        c = getchar();
ffffffffc0201ec4:	f7efe0ef          	jal	ra,ffffffffc0200642 <getchar>
        if (c < 0) {
ffffffffc0201ec8:	fe0549e3          	bltz	a0,ffffffffc0201eba <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201ecc:	fea959e3          	bge	s2,a0,ffffffffc0201ebe <readline+0x54>
ffffffffc0201ed0:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201ed2:	e42a                	sd	a0,8(sp)
ffffffffc0201ed4:	f2cfe0ef          	jal	ra,ffffffffc0200600 <cputchar>
            buf[i ++] = c;
ffffffffc0201ed8:	6522                	ld	a0,8(sp)
ffffffffc0201eda:	009b87b3          	add	a5,s7,s1
ffffffffc0201ede:	2485                	addiw	s1,s1,1
ffffffffc0201ee0:	00a78023          	sb	a0,0(a5)
ffffffffc0201ee4:	bf7d                	j	ffffffffc0201ea2 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc0201ee6:	01550463          	beq	a0,s5,ffffffffc0201eee <readline+0x84>
ffffffffc0201eea:	fb651ce3          	bne	a0,s6,ffffffffc0201ea2 <readline+0x38>
            cputchar(c);
ffffffffc0201eee:	f12fe0ef          	jal	ra,ffffffffc0200600 <cputchar>
            buf[i] = '\0';
ffffffffc0201ef2:	00005517          	auipc	a0,0x5
ffffffffc0201ef6:	22e50513          	addi	a0,a0,558 # ffffffffc0207120 <buf>
ffffffffc0201efa:	94aa                	add	s1,s1,a0
ffffffffc0201efc:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201f00:	60a6                	ld	ra,72(sp)
ffffffffc0201f02:	6486                	ld	s1,64(sp)
ffffffffc0201f04:	7962                	ld	s2,56(sp)
ffffffffc0201f06:	79c2                	ld	s3,48(sp)
ffffffffc0201f08:	7a22                	ld	s4,40(sp)
ffffffffc0201f0a:	7a82                	ld	s5,32(sp)
ffffffffc0201f0c:	6b62                	ld	s6,24(sp)
ffffffffc0201f0e:	6bc2                	ld	s7,16(sp)
ffffffffc0201f10:	6161                	addi	sp,sp,80
ffffffffc0201f12:	8082                	ret
            cputchar(c);
ffffffffc0201f14:	4521                	li	a0,8
ffffffffc0201f16:	eeafe0ef          	jal	ra,ffffffffc0200600 <cputchar>
            i --;
ffffffffc0201f1a:	34fd                	addiw	s1,s1,-1
ffffffffc0201f1c:	b759                	j	ffffffffc0201ea2 <readline+0x38>

ffffffffc0201f1e <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201f1e:	4781                	li	a5,0
ffffffffc0201f20:	00005717          	auipc	a4,0x5
ffffffffc0201f24:	0e873703          	ld	a4,232(a4) # ffffffffc0207008 <SBI_CONSOLE_PUTCHAR>
ffffffffc0201f28:	88ba                	mv	a7,a4
ffffffffc0201f2a:	852a                	mv	a0,a0
ffffffffc0201f2c:	85be                	mv	a1,a5
ffffffffc0201f2e:	863e                	mv	a2,a5
ffffffffc0201f30:	00000073          	ecall
ffffffffc0201f34:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc0201f36:	8082                	ret

ffffffffc0201f38 <sbi_set_timer>:
    __asm__ volatile (
ffffffffc0201f38:	4781                	li	a5,0
ffffffffc0201f3a:	00005717          	auipc	a4,0x5
ffffffffc0201f3e:	62e73703          	ld	a4,1582(a4) # ffffffffc0207568 <SBI_SET_TIMER>
ffffffffc0201f42:	88ba                	mv	a7,a4
ffffffffc0201f44:	852a                	mv	a0,a0
ffffffffc0201f46:	85be                	mv	a1,a5
ffffffffc0201f48:	863e                	mv	a2,a5
ffffffffc0201f4a:	00000073          	ecall
ffffffffc0201f4e:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201f50:	8082                	ret

ffffffffc0201f52 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201f52:	4501                	li	a0,0
ffffffffc0201f54:	00005797          	auipc	a5,0x5
ffffffffc0201f58:	0ac7b783          	ld	a5,172(a5) # ffffffffc0207000 <SBI_CONSOLE_GETCHAR>
ffffffffc0201f5c:	88be                	mv	a7,a5
ffffffffc0201f5e:	852a                	mv	a0,a0
ffffffffc0201f60:	85aa                	mv	a1,a0
ffffffffc0201f62:	862a                	mv	a2,a0
ffffffffc0201f64:	00000073          	ecall
ffffffffc0201f68:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201f6a:	2501                	sext.w	a0,a0
ffffffffc0201f6c:	8082                	ret

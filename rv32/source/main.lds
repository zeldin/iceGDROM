SECTIONS {
	/DISCARD/ : {
		*(.comment)
		*(.riscv.attributes)
	}
	.memory : {
		. = 0x000000;
		start.o(.text);
		*(.sdata*);
		*(.sbss*);
                *(.data*);
		*(.rodata*);
		*(.text*);
		*(*);
		. = ALIGN(4);
		end = .;
	}
	ASSERT(end <= __stack - 1000, "Less than 1k left for stack!")
}

ENTRY(_start)
/* PHDRS { text PT_LOAD; data PT_LOAD; bss PT_LOAD;} */

MEMORY {
	flash : ORIGIN = 0x30000000, LENGTH = 64M
	sram : ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS {
	. = ORIGIN(flash);
  	.text : {
    	*(entry)
    	*(.text*)
  	} > flash AT> flash
  	etext = .;
  	_etext = .;

  	.rodata : {
    	*(.rodata*)
		*(.srodata*)
  	} > flash AT> flash

	. = ORIGIN(sram);
  	.data : {
		_data_vma_start = .;
    	*(.data*)
		*(.sdata*)
  	} > sram AT> flash
  	edata = .;
  	_data = .;

	_data_lma_start = LOADADDR(.data);
	_data_size = SIZEOF(.data);

  	.bss : {
    	_bss_start = .;
    	*(.bss*)
    	*(.sbss*)
    	*(.scommon)
		_bss_end = .;
  	} > sram

	_bss_size = _bss_end - _bss_start;


	. = ALIGN(4);
  	_stack_top = .;
  	. = _stack_top + 0x800;
  	_stack_pointer = .;              /* 堆栈初始指针 */

  	_heap_start = .;        /* 堆起始地址，高地址 */
	_heap_end = ORIGIN(sram) + LENGTH(sram);
  	end = .;
  	_end = .;
}
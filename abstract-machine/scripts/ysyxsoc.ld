ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }

MEMORY {
	mrom : ORIGIN = 0x20000000, LENGTH = 4K
	sram : ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS {
	. = ORIGIN(mrom);
  	.text : {
    	*(entry)
    	*(.text*)
  	} :text > mrom AT> mrom
  	etext = .;
  	_etext = .;

  	.rodata : {
    	*(.rodata*)
  	} > mrom AT> mrom


  	.data : {
		. = ORIGIN(sram);
		_data_vma_start = .;
    	*(.data)
  	} :data > sram AT> mrom
  	edata = .;
  	_data = .;

	_data_lma_start = LOADADDR(.data);
	_data_size = SIZEOF(.data)

  	.bss : {
    	_bss_start = .;
    	*(.bss*)
    	*(.sbss*)
    	*(.scommon)
  	} > sram

	_bss_size = SIZEOF(.bss);


	. = ALIGN(4);
  	_stack_top = .;
  	. = _stack_top + 0x800;
  	_stack_pointer = .;              /* 堆栈初始指针 */

  	_heap_start = .;        /* 堆起始地址，高地址 */
	_heap_end = ORIGIN(sram) + LENGTH(sram);
  	end = .;
  	_end = .;
}
ENTRY(_start)
/* PHDRS { text PT_LOAD; data PT_LOAD; bss PT_LOAD;} */

MEMORY {
	sdram : ORIGIN = 0xa0000000, LENGTH = 128M
	psram : ORIGIN = 0x80000000, LENGTH = 4M
	flash : ORIGIN = 0x30000000, LENGTH = 64M
	sram : ORIGIN = 0x0f000000, LENGTH = 8K
}

SECTIONS {
	.fsld : {
		KEEP(*(.fsld))
	} > flash AT> flash

	. = ORIGIN(sram);
	.ssld : {
		_ssld_vma_start = .;
		KEEP(*(.ssld))
		_ssld_vma_end = .;
	} > sram AT> flash

	_ssld_lma_start = LOADADDR(.ssld);

	. = ORIGIN(sdram);
  	.text : {
		_text_vma_start = .;
    	*(entry)
    	*(.text*)
		_text_vma_end = .;
  	} > sdram AT> flash
  	etext = .;
  	_etext = .;

	_text_lma_start = LOADADDR(.text);

  	.rodata : {
		_rodata_vma_start = .;
    	*(.rodata*)
		*(.srodata*)
		_rodata_vma_end = .;
  	} > sdram AT> flash

	_rodata_lma_start = LOADADDR(.rodata);

  	.data : {
		_data_vma_start = .;
    	*(.data*)
		*(.sdata*)
		_data_vma_end = .;
  	} > sdram AT> flash
  	edata = .;
  	_data = .;

	_data_lma_start = LOADADDR(.data);

  	.bss : {
    	_bss_start = .;
    	*(.bss*)
    	*(.sbss*)
    	*(.scommon)
		_bss_end = .;
  	} > sdram

	_bss_size = _bss_end - _bss_start;

	. = ALIGN(4);
	_heap_start = .;
	_heap_end = ORIGIN(sdram) + LENGTH(sdram);


	. = ORIGIN(sram);
  	_stack_top = .;
  	. = _stack_top + LENGTH(sram);
  	_stack_pointer = .;              /* 堆栈初始指针 */

  	end = .;
  	_end = .;
}
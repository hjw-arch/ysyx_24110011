ENTRY(_start)
/* PHDRS { text PT_LOAD; data PT_LOAD; bss PT_LOAD;} */

MEMORY {
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

	. = ORIGIN(psram);
  	.text : {
		_text_vma_start = .;
    	*(entry)
    	*(.text*)
		_text_vma_end = .;
  	} > psram AT> flash
  	etext = .;
  	_etext = .;

	_text_lma_start = LOADADDR(.text);

  	.rodata : {
		_rodata_vma_start = .;
    	*(.rodata*)
		*(.srodata*)
		_rodata_vma_end = .;
  	} > psram AT> flash

	_rodata_lma_start = LOADADDR(.rodata);

  	.data : {
		_data_vma_start = .;
    	*(.data*)
		*(.sdata*)

		/* RTT */
		/* section information for finsh shell */
		__fsymtab_start = .;
		KEEP(*(FSymTab))
		__fsymtab_end = .;
		. = ALIGN(8);
		__vsymtab_start = .;
		KEEP(*(VSymTab))
		__vsymtab_end = .;
		. = ALIGN(8);

		/* section information for initial. */
		. = ALIGN(8);
		__rt_init_start = .;
		KEEP(*(SORT(.rti_fn*)))
		__rt_init_end = .;
		. = ALIGN(8);

		__rt_utest_tc_tab_start = .;
		KEEP(*(UtestTcTab))
		__rt_utest_tc_tab_end = .;

		. = ALIGN(8);
		__am_apps_data_start = .;
		*(__am_apps.data*)
		*(__am_apps.sdata*)
		__am_apps_data_end = .;
		. = ALIGN(8);


		_data_vma_end = .;
  	} > psram AT> flash
  	edata = .;
  	_data = .;

	_data_lma_start = LOADADDR(.data);

  	.bss : {
    	_bss_start = .;
    	*(.bss*)
    	*(.sbss*)
    	*(.scommon)

		/* RTT */
		. = ALIGN(8);
		__am_apps_bss_start = .;
		*(__am_apps.bss*)
		*(__am_apps.sbss*)
		*(__am_apps.scommon*)
		__am_apps_bss_end = .;
		. = ALIGN(8);

		_bss_end = .;
  	} > psram

	_bss_size = _bss_end - _bss_start;

	. = ALIGN(4);
	_heap_start = .;
	_heap_end = ORIGIN(psram) + LENGTH(psram);


	. = ORIGIN(sram);
  	_stack_top = .;
  	. = _stack_top + LENGTH(sram);
  	_stack_pointer = .;              /* 堆栈初始指针 */

  	end = .;
  	_end = .;
}
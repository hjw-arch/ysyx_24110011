ENTRY(_start)
PHDRS { text PT_LOAD; data PT_LOAD; }

SECTIONS {
  /* _pmem_start 和 _entry_offset 在 LDFLAGS 中定义 */
  . = _pmem_start + _entry_offset;
  .text : {
    *(entry)
    *(.text*)
  } :text
  etext = .;
  _etext = .;
  .rodata : {
    *(.rodata*)
  }
  .data : {
    *(.data)
  } :data
  edata = .;
  _data = .;
  .bss : {
    _bss_start = .;
    *(.bss*)
    *(.sbss*)
    *(.scommon)
  }

  /* 设置堆栈和堆到指定地址范围 */
  _stack_top = 0x0f000000;         /* 堆栈底部，低地址 */
  . = _stack_top + 0x800;          /* 推进到堆栈顶部边界外，0x0f000800 */
  _stack_pointer = .;              /* 堆栈初始指针 */

  _heap_start = 0x0f000800;        /* 堆起始地址，高地址 */
  /* 堆占用 6KB，结束于 0x0f001fff */

  end = .;
  _end = .;
}
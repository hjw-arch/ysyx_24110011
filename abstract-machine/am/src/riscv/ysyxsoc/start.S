.section .boot, "ax"
.globl _start
.type _start, @function

_start:
	mv s0, zero
  	la sp, _stack_pointer

_load_text:
	la a0, _text_vma_start
	la a1, _text_lma_start
	la a2, _text_vma_end
_copy_text:
	lw t0, 0(a1)
	sw  t0, 0(a0)
	addi a0, a0, 4
	addi a1, a1, 4
	blt a0, a2, _copy_text

_load_rodata:
	la a0, _rodata_vma_start
	la a1, _rodata_lma_start
	la a2, _rodata_vma_end
	beq a0, a2, _load_data
_copy_rodata:
	lbu t0, 0(a1)
	sb  t0, 0(a0)
	addi a0, a0, 1
	addi a1, a1, 1
	blt a0, a2, _copy_rodata

_load_data:
  	la a0, _data_vma_start
  	la a1, _data_lma_start
  	la a2, _data_vma_end
  	beq a0, a2, _load_bss
_copy_data:
	lbu t0, 0(a1)
	sb	t0, 0(a0)
	addi a0, a0, 1
	addi a1, a1, 1
	blt a0, a2, _copy_data

_load_bss:
	la a0, _bss_start
	la a1, _bss_end
	beq a0, a1, _call_init
_clear_bss:
	sb zero, 0(a0)
	addi a0, a0, 1
	blt a0, a1, _clear_bss

_call_init:
	la t0, _trm_init
  	jalr t0

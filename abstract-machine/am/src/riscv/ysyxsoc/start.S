.section entry, "ax"
.globl _start
.type _start, @function

_start:
	mv s0, zero
  	la sp, _stack_pointer
_load_data:
  	la a0, _data_vma_start
  	la a1, _data_lma_start
  	la a2, _data_size
  	beqz a2, _load_bss
_copy_data:
	lbu t0, 0(a1)
	sb	t0, 0(a0)
	addi a0, a0, 1
	addi a1, a1, 1
	addi a2, a2, -1
	bnez a2, _copy_data
_load_bss:
	la a0, _bss_start
	la a1, _bss_end
	beq a0, a1, _call_init
_clear_bss:
	sb zero, 0(a0)
	addi a0, a0, 1
	blt a0, a1, _clear_bss
_call_init:
  	jal _trm_init

.section entry, "ax"
.globl _start
.type _start, @function

_start:
	mv s0, zero
  	la sp, _stack_pointer
_test:
	la a0, 0x20000000
#	la a1, 0x04030201
#	sw a1, 0(a0)
	lbu t0, 0(a0)
	lbu t1, 1(a0)
	lbu t2, 2(a0)
	lbu a2, 3(a0)
	lhu	a3, 2(a0)
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

.data
	#####################
	### REGISTRADORES ###
	#####################
	r0:   .asciiz  "zero"
	r1:   .asciiz  "at"
	r2:   .asciiz  "v0"
	r3:   .asciiz  "v1"
	r4:   .asciiz  "a0"
	r5:   .asciiz  "a1"
	r6:   .asciiz  "a2"
	r7:   .asciiz  "a3"
	r8:   .asciiz  "t0"
	r9:   .asciiz  "t1"
	r10:  .asciiz  "t2"
	r11:  .asciiz  "t3"
	r12:  .asciiz  "t4"
	r13:  .asciiz  "t5"
	r14:  .asciiz  "t6"
	r15:  .asciiz  "t7"
	r16:  .asciiz  "s0"
	r17:  .asciiz  "s1"
	r18:  .asciiz  "s2"
	r19:  .asciiz  "s3"
	r20:  .asciiz  "s4"
	r21:  .asciiz  "s5"
	r22:  .asciiz  "s6"
	r23:  .asciiz  "s7"
	r24:  .asciiz  "t8"
	r25:  .asciiz  "t9"
	r26:  .asciiz  "k0"
	r27:  .asciiz  "k1"
	r28:  .asciiz  "gp"
	r29:  .asciiz  "sp"
	r30:  .asciiz  "fp"
	r31:  .asciiz  "ra"

    # como os registradores equivalem a inteiros sequenciais, basta colocar a sequência de registradores em um array
	tabela_reg:  .word  r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15,
					    r16, r17, r18, r19, r20, r21, r22, r23, r24, r25, r26, r27, r28, r29,
					    r30, r31

	###############
	### OPCODES ###
	###############
	# Referência https://en.wikibooks.org/wiki/MIPS_Assembly/Instruction_Formats#Opcodes + livro do Pat e auxílio do PET
	# .word 0  --> opcode_J = j ou jal
	# .word 1  --> tipo_i1 = rt, rs, imm
	# .word 2  --> tipo_i2 = rt, rs, offset
	# .word 3  --> tipo_i3 = rt, offset($rs)
	# .word 4  --> tipo_i4 = rt, imm
	# .word 5  --> tipo_i5 = rs, offset
	tabela_opcodes:
		.space    16           # 00 = VAI PARA A TABELA DE OPCODES TIPO R!
		.space    16
		.asciiz   "j      "    # 02 = J
		.word     0
		.space    4
		.asciiz   "jal    "    # 03 = J
		.word     0
		.space    4
		.asciiz   "beq    "    # 04 = I2
		.word     2
		.space    4
		.asciiz   "bne    "    # 05 = I2
		.word     2
		.space    4
		.asciiz   "blez   "    # 06 = I5
		.word     5
		.space    4
		.asciiz   "bgtz   "    # 07 = I5
		.word     5
		.space    4
		.asciiz   "addi   "    # 08 = I1
		.word     1
		.space    4
		.asciiz   "addiu  "    # 09 = I1
		.word     1
		.space    4
		.asciiz   "slti   "    # 10 = I1
		.word     1
		.space    4
		.asciiz   "sltiu  "    # 11 = I1
		.word     1
		.space    4
		.asciiz   "andi   "    # 12 = I1
		.word     1
		.space    4
		.asciiz   "ori    "    # 13 = I1
		.word     1
		.space    4
		.asciiz   "xori   "    # 14 = I1
		.word     1
		.space    4
		.asciiz   "lui    "    # 15 = I4
		.word     4
		.space    4
		.space    16
		.space    16
		.space    16
		.space    16
		.space    16
		.space    16
		.space    16
		.space    16
		.space    16
		.space    16
		.space    16
		.space    16
		.space    16
		.space    16
		.space    16
		.space    16
		.asciiz   "lb     "    # 32 = I3
		.word     3
		.space    4
		.space 	  16
		.space 	  16
		.asciiz   "lw     "    # 35 = I3
		.word     3
		.space    4
		.space 	  16
		.space 	  16
		.space 	  16
		.space    16
		.asciiz   "sb     "    # 40 = I3
		.word     3
		.space    4
		.space    16
		.space    16
		.asciiz   "sw     "    # 43 = I3
		.word     3
		.space    4
		.space    16
		.space    16
		.space 	  16



    # .word 0  -->  syscall
	# .word 1  --> tipo_r1 = rd, rs, rt
	# .word 2  --> tipo_r2 = rd, rt, shamt
	# .word 3  --> tipo_r3 = rs
	tabela_tipo_r:
		.asciiz   "sll    "    # 00 = R2
		.word     2
		.space    4
		.space    16           # 01
		.asciiz   "srl    "    # 02 = R2
		.word     2
		.space    4
		.space 	  16
		.space 	  16
		.space    16
		.space 	  16
		.space    16
		.asciiz   "jr     "    # 08 = R3
		.word     3
		.space    4
		.space    16
		.space 	  16
		.space 	  16
		.asciiz   "syscall"    # 12 = Syscall
		.word     0
		.space    4
		.space    16
		.space    16
		.space    16
		.space 	  16
		.space 	  16
		.space 	  16
		.space 	  16
		.space    16
		.space    16
		.space    16
		.space    16
		.space 	  16
		.space 	  16
		.space 	  16
		.space 	  16
		.space    16
		.space    16
		.space    16
		.space    16
		.asciiz   "add    "    # 32 = R1
		.word     1
		.space    4
		.asciiz   "addu   "    # 33 = R1
		.word     1
		.space    4
		.asciiz   "sub    "    # 34 = R1
		.word     1
		.space    4
		.asciiz   "subu   "    # 35 = R1
		.word     1
		.space    4
		.asciiz   "and    "    # 36 = R1
		.word     1
		.space    4
		.asciiz   "or     "    # 37 = R1
		.word     1
		.space    4
		.asciiz   "xor    "    # 38 = R1
		.word     1
		.space    4
		.asciiz   "nor    "    # 39 = R1
		.word     1
		.space    4
		.space    16
		.space    16
		.asciiz   "slt    "    # 42 = R1
		.word     1
		.space    4
		.asciiz   "sltu   "    # 43 = R1
		.word     1
		.space    4

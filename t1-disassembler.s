##########################################
### D I S A S S E M B L E R   M I P S
##########################################
###############################################################################################
# disassembler.s               Copyright (C) 2017 pprobst                                      
# This program is free software under GNU GPL V3 or later version                              
# see http://www.gnu.org/licences  															   
#                                                                                              
#-----------------------															           
# Assembler:  MARS         																	   
# Data:       2017 - 10 - 30                                                                   
#-----------------------																	   
#	   															                               
#-----------------------																	   
#  Descrição: 																				   
#-----------------------																	   
# Este programa lê um arquivo binário, com instruções em linguagem de máquina (hexadecimal)    
# e converte cada instrução em sua equivalente MIPS Assembly, imprimindo cada uma no console   
# e gravando a mesma em um arquivo texto.  		                                               
#	                                                                                           
################################################################################################
#							           	   													   
#------------------------																	   
#  Referências do código: 																	   
#------------------------																	   
# Computer Organization and Design, 4th Ed, D. A. Patterson and J. L. Hennessy                 
# https://en.wikibooks.org/wiki/MIPS_Assembly/Instruction_Formats                              
# https://www.eg.bucknell.edu/~csci320/mips_web/ 											
# http://alumni.cs.ucr.edu/~vladimir/cs161/mips.html                                           
# http://www.mrc.uidaho.edu/mrc/people/jff/digital/MIPSir.html                                 	
                                                                                               
################################################################################################


.include  "t1-macros.s"   # inclui o arquivo t1-macros.s neste arquivo
.include  "t1-tabelas.s"  # inclui o arquivo t1-tabelas.s neste arquivo

###############
### DEFINES ###
###############
.eqv  NUMERO_INSTRUCOES           16
.eqv  SERVICO_IMPRIME_STRING      4
.eqv  SERVICO_IMPRIME_CARACTER    11
.eqv  SERVICO_IMPRIME_NUM_HEX     34
.eqv  SERVICO_IMPRIME_NUM_INT     1
.eqv  SERVICO_TERMINA_PROGRAMA    17
.eqv  SERVICO_LE_DO_ARQUIVO       14
.eqv  PROGRAMA_EXECUTADO_SUCESSO  0
.eqv  PROGRAMA_EXECUTADO_ERRO     1
.eqv  SERVICO_ABRE_ARQUIVO	      13
.eqv  PC_INICIAL                  0x00400000
.eqv  MASCARA_PC                  0xF0000000
.eqv  MASCARA_CAMPO_FUNCT         0x0000003F
.eqv  MASCARA_CAMPO_IMM           0x0000FFFF
.eqv  MASCARA_CAMPO_OFFSET        0x0000FFFF
.eqv  MASCARA_CAMPO_SHAMT         0x000007C0
.eqv  MASCARA_CAMPO_ADDR          0x03FFFFFF
# observe que eu poderia ter usado máscaras para os campos RT, RS e RD também, mas optei por não fazê-lo

# ################# MAPA DA PILHA ###########################################
#
#					############
#		  sp + 11	#    PC    #
#					############
#		  sp + 10	#    PC	   #
#					############
#		  sp + 9	#    PC    # 
#					############
#		  sp + 8	#    PC	   #  --> program counter
#					############
#		  sp + 7	#  &buffer #
#					############
#		  sp + 6	#  &buffer #
#					############
#		  sp + 5	#  &buffer #	
#					############
#		  sp + 4	#  &buffer #  --> "instrução"
#					############
#		  sp + 3	# arqdescr #	  
#					############
#		  sp + 2	# arqdescr #	   
#					############
#	      sp + 1	# arqdescr #
#					############
#	      sp + 0	# arqdescr #  --> descritor do arquivo
#					############
#
############################################################################

.data
	input:  .asciiz  "input.bin"   # arquivo de entrada
	output: .asciiz  "output.txt"  # arquivo de saída
	
	buffer_hex:    .space  12  # buffer para a string de um hexadecimal
    hexadecimal:   .ascii  "0123456789ABCDEF"  # vetor com os caracteres hexadecimais

#################
### PRINCIPAL ###
#################
.text
	main:       
	    addi  $sp, $sp, -12 # alocamos na pilha espaço para receber três itens
    	
    	jal   abre_arq_output
    	imprime_caracter('\n')
    	jal   le_arq_input  # chama função para ler o arquivo de entrada


	##############################
	### MANIPULAÇÂO DE ARQUIVO ###
	##############################
	le_arq_input:	
    	# abertura do arquivo de entrada
    	la   $a0, input       # $a0 = nome do arquivo
    	li   $a1, 0 	      # flag = 0, leitura
    	li	 $a2, 0 	      # modo (ignorado)
	    
	    abre_arquivo()
	    
    	sw   $v0, 0($sp)      # salva o descritor do arquivo na pilha
    	
    	slt  $t0, $v0, $zero  # verifica erro na abertura do arquivo
    	bne  $t0, $zero, abertura_arquivo_erro
    	
    	li   $s0, PC_INICIAL  # $s0 = 0x00400000
    	sw   $s0, 8($sp)      # guarda o PC inicial na pilha
    	
    	# verifica se chegamos ao final do arquivo
    	j     verifica_fim 
    	
    abertura_arquivo_erro:
    	imprime_string("Erro na abertura do arquivo!\n")
    	termina_programa_erro()	
    
    verifica_fim:
    	sw     $s0, 8($sp)    # salva o PC em $s0

    	le_instrucao_arquivo()
    	
    	# se ainda não foram lidos quatro bytes, executa laço novamente
    	slti   $t0, $v0, 4
    	beq    $t0, $zero, loop_le_instrucao
    	
    	# terminamos o programa
    	addiu  $sp, $sp, 12  # restaura pilha
    	
    	# fecha o arquivo de output 
		li   $v0, 16       # systemcall para fechar arquivo
		move $a0, $s6      # descritor do arquivo para fechar
		syscall           
		
    	termina_programa_sucesso()

	abre_arq_output:
	    # abre o arquivo de saída
  		li    $v0, 13       # syscall para abrir arquivo
  		la    $a0, output   # output = nome do arquivo
  		li    $a1, 1        # flag = 1, escrita
 		li    $a2, 0        # modo (ignorado)
  		syscall             # abre o arquivo
  		
  		move  $s6, $v0      # salva o descritor do arquivo em $s6
		
		jr $ra 
		 
		 
	###############################
	### MANIPULAÇÂO DO CONTEÚDO ###
	###############################
	loop_le_instrucao:
		lw    $t0, 4($sp)  			# carrega a instrução do arquivo
    	
    	# imprime a instrução em linguagem de máquina
    	move  $a0, $t0
    	imprime_hex()
    	
    	# grava a instrução em linguagem de máquina no arquivo de saída
    	la    $a1, buffer_hex 
    	jal   converte_string_hexadecimal
        la 	  $a3, buffer_hex
		grava_hex_output()
    	
    	imprime_espaco()
    	grava_espaco_output()
    	imprime_string("-->")
    	grava_setinha_output()
    	imprime_espaco()
    	grava_espaco_output()

		# carrega e imprime o PC atual
    	lw    $a0, 8($sp)
    	imprime_hex()
    	
    	# grava o PC atual no arquivo de saída
    	la    $a1, buffer_hex 
    	jal   converte_string_hexadecimal
        la 	  $a3, buffer_hex
		grava_hex_output()
    	
    	imprime_espaco()
    	grava_espaco_output()
    	
    	# pega o opcode da instrução lida do arquivo
    	srl   $t0, $t0, 26 			# $t0 = 6 bits mais significativos da instrução (opcode!)
    	
    	# verifica se a instrução é do tipo R
    	slti  $t1, $t0, 1  			# verifica se $t0 é menor que 1 (opcode 0)
    	bne   $t1, $zero, opcode_r 	# se $t1 != 0, salta para tratamento de instruções tipo R
    
    	# imprime mnemônico para instruções do tipo I ou do tipo J
    	la    $t1, tabela_opcodes  # carrega endereço da tabela de opcodes em $t1
    	sll   $t2, $t0, 4  	       # $t2 = $t0 * 16
    	add   $t1, $t1, $t2        # $t1 = tabela + &tabela[i]
    	la    $a0, 0($t1)          # carrega valor pego da tabela em $a0
    	imprime_mnemonico()
    	
    	# verifica se a instrução é do tipo J
    	beq   $t0, 2, opcode_j  # j 
    	beq   $t0, 3, opcode_j  # jal
    	
    	# não é R nem J, então só pode ser I
    	j opcode_I
    	
    	
	opcode_r:
	    la   $t1, tabela_tipo_r        # carrela a tabela_tipo_r  em $t1
    	lw   $t0, 4($sp)               # carrega a instrução
    	li   $t2, MASCARA_CAMPO_FUNCT  # carrega a máscara do campo funct
    	
    	and  $t0, $t0, $t2             # pega os 6 bits menos significativos (funct)
    	sll  $t0, $t0, 4			   # $t0 * 16
    	add  $t1, $t1, $t0             # $t1 = endereço base + deslocamento
    	la   $a0, 0($t1)               # imprime mnemônico
    	
    	imprime_mnemonico()
    	
    	# grava mnemônico no arquivo de saída
    	move $a3, $a0
    	grava_mnem_output()

    	# seleciona qual é o tipo de instrução R e pula para o código correspondente
    	lw   $t0, 8($t1)       # carrega o tipo da instrução (é o inteiro representado pelo .word na tabela!)
    	beq  $t0, 1, tipo_r1   # tipo tipo_r1
    	beq  $t0, 2, tipo_r2   # tipo tipo_r2
    	beq  $t0, 3, tipo_r3   # tipo tipo_r3
    	
    	j nova_linha 		   # é syscall, então vai para o próxima linha

	tipo_r1:
    	imprime_espaco()
    	grava_espaco_output()
    	imprime_caracter('$')
    	grava_dolar_output()
    	
    	# pega e grava RD no arquivo de saída
    	lw   $t0, 4($sp)
    	sll  $t0, $t0, 16
		srl  $t0, $t0, 27
		add  $a0, $t0, $zero
		imprime_reg()
		
		move  $a3, $a0
		grava_reg_output()

		imprime_caracter(',')
		grava_virgula_output()
		imprime_espaco()
		grava_espaco_output()
		imprime_caracter('$')
		grava_dolar_output()

    	# pega e grava RS no arquivo de saída
    	lw   $t0, 4($sp)
    	sll  $t0, $t0, 6
		srl  $t0, $t0, 27
		add  $a0, $t0, $zero
		imprime_reg()
		
		# $t1 = endereço do registrador atual
		# $s2 = endereço base do array de registradores ($zero)
		beq  $t1, $s2, grava_zero3
		bne  $t1, $s2, grava_reg_normal3
		
		grava_zero3:
			move  $a3, $a0
			grava_zero_output()
			j pula3
	
		grava_reg_normal3:
			move  $a3, $a0
			grava_reg_output()
			
		pula3:

		imprime_caracter(',')
		grava_virgula_output()
		imprime_espaco()
		grava_espaco_output()
		imprime_caracter('$')
		grava_dolar_output()

    	# pega e grava RT no arquivo de saída
    	lw   $t0, 4($sp)
    	sll  $t0, $t0, 11
		srl  $t0, $t0, 27
		add  $a0, $t0, $zero
		imprime_reg()
		
		move  $a3, $a0
		grava_reg_output()

    	j nova_linha # pula para nova_linha

	tipo_r2:
    	imprime_espaco()
    	grava_espaco_output()
    	imprime_caracter('$')
    	grava_dolar_output()

    	# pega e grava RD no arquivo de saída
    	lw $t0, 4($sp)
    	sll $t0, $t0, 16
		srl $t0, $t0, 27
		add $a0, $t0, $zero
		imprime_reg()
		
		move  $a3, $a0
		grava_reg_output()

		imprime_caracter(',')
		grava_virgula_output()
		imprime_espaco()
		grava_espaco_output()
		imprime_caracter('$')
		grava_dolar_output()

    	# pega e grava RT no arquivo de saída
    	lw $t0, 4($sp)
    	sll $t0, $t0, 11
		srl $t0, $t0, 27
		add $a0, $t0, $zero
		imprime_reg()
		
		# $t1 = endereço do registrador atual
		# $s2 = endereço base do array de registradores ($zero)
		beq  $t1, $s2, grava_zero4
		bne  $t1, $s2, grava_reg_normal4
		
		grava_zero4:
			move  $a3, $a0
			grava_zero_output()
			j pula4
		
		grava_reg_normal4:
			move  $a3, $a0
			grava_reg_output()
			
		pula4:

		imprime_caracter(',')
		grava_virgula_output()

    	# pega e grava shamt (shift ammount - quantidade de bits deslocados)
    	lw    $t0, 4($sp)               # carrega a instrução
    	li    $t2, MASCARA_CAMPO_SHAMT  # carrega a máscara
    	and   $t0, $t0, $t2             # $t0 = 5 bits do shamt
    	srl   $a0, $t0, 6               # desloca 6 bits para a direita
    	li    $v0, 1                    # imprime shamt
    	syscall
    	
    	la $a1, buffer_hex
    	jal converte_string_hexadecimal
    	la $a3, buffer_hex
    	grava_hex_output()

    	j nova_linha # pula para nova_linha

	tipo_r3:
    	imprime_espaco()
    	grava_espaco_output()
    	imprime_caracter('$')
    	grava_dolar_output()

    	# pega e grava RS no arquivo de saída
    	lw $t0, 4($sp)
    	sll $t0, $t0, 6
		srl $t0, $t0, 27
		add $a0, $t0, $zero
		imprime_reg()
		
		# $t1 = endereço do registrador atual
		# $s2 = endereço base do array de registradores ($zero)
		beq  $t1, $s2, grava_zero5
		bne  $t1, $s2, grava_reg_normal5
		
		grava_zero5:
			move  $a3, $a0
			grava_zero_output()
			j pula5
	
		grava_reg_normal5:
			move  $a3, $a0
			grava_reg_output()
			
		pula5:

    	j nova_linha # pula para nova_linha
    	

	opcode_I:
    	# verifica com qual tipo de instrução I estamos lidando
    	lw   $t0, 8($t1)  	  # carrega instrução
    	beq  $t0, 1, tipo_i1  # tipo_i1
    	beq  $t0, 2, tipo_i2  # tipo_i2
    	beq  $t0, 3, tipo_i3  # tipo_i3
    	beq  $t0, 4, tipo_i4  # tipo_i4
    	beq  $t0, 5, tipo_i5  # tipo_i5
    	j nao_especificada

	tipo_i1:
	    # grava o mnemônico no arquivo
    	move  $a3, $a0
    	grava_mnem_output() 
		
    	imprime_espaco()
    	grava_espaco_output()
    	imprime_caracter('$')
    	grava_dolar_output()
		
	    # pega e grava RT no arquivo de saída
    	lw   $t0, 4($sp)
    	sll  $t0, $t0, 11
		srl  $t0, $t0, 27
		add  $a0, $t0, $zero
		imprime_reg()
		
		move  $a3, $a0
		grava_reg_output()
		
    	imprime_caracter(',')
    	grava_virgula_output()
    	imprime_espaco()
    	grava_espaco_output()
    	imprime_caracter('$')
    	grava_dolar_output()

    	# pega e grava RS no arquivo de saída
    	lw   $t0, 4($sp)
    	sll  $t0, $t0, 6
		srl  $t0, $t0, 27
		add  $a0, $t0, $zero
		imprime_reg()
		
		# $t1 = endereço do registrador atual
		# $s2 = endereço base do array de registradores ($zero)
		beq  $t1, $s2, grava_zero1
		bne  $t1, $s2, grava_reg_normal1
		
		grava_zero1:
			move  $a3, $a0
			grava_zero_output()
			j pula1
		
		grava_reg_normal1:
			move  $a3, $a0
			grava_reg_output()
			
		pula1:
		
    	imprime_caracter(',')
    	grava_virgula_output()
    	imprime_espaco()
    	grava_espaco_output()

    	# pega e grava imm no arquivo de saída
    	lw   $t0, 4($sp)                   # carrega instrução
    	li   $t2, MASCARA_CAMPO_IMM        # carrega máscara
    	and  $a0, $t0, $t2                 # pega os 16 bits
    	li   $v0, SERVICO_IMPRIME_NUM_HEX  # imprime immediate
    	syscall
    	
    	la $a1, buffer_hex
    	jal converte_string_hexadecimal
    	la $a3, buffer_hex
    	grava_hex_output()
    
    	j nova_linha  # pula para nova_linha

	tipo_i2:
		# grava o mnemônico no arquivo
    	move  $a3, $a0
    	grava_mnem_output() 
    	
    	imprime_espaco()
    	grava_espaco_output()
    	imprime_caracter('$')
    	grava_dolar_output()

    	# pega e grava RT no arquivo de saída
    	lw   $t0, 4($sp)
    	sll  $t0, $t0, 11
		srl  $t0, $t0, 27
		add  $a0, $t0, $zero
		imprime_reg()
		
		move  $a3, $a0
		grava_reg_output()
		
		imprime_caracter(',')
		grava_virgula_output()
		imprime_espaco()
		grava_espaco_output()
		imprime_caracter('$')
		grava_dolar_output()

    	# pega e grava RS no arquivo de saída
    	lw   $t0, 4($sp)
    	sll  $t0, $t0, 6
		srl  $t0, $t0, 27
		add  $a0, $t0, $zero
		imprime_reg()
		
		# $t1 = endereço do registrador atual
		# $s2 = endereço base do array de registradores ($zero)
		beq  $t1, $s2, grava_zero
		bne  $t1, $s2, grava_reg_normal
		
		grava_zero:
			move  $a3, $a0
			grava_zero_output()
			j pula
		
		grava_reg_normal:
			move  $a3, $a0
			grava_reg_output()
			
		pula:

		imprime_caracter(',')
		grava_virgula_output()
		imprime_espaco()
		grava_espaco_output()

    	# pega e grava offset no arquivo de saída
    	lw   $t0, 4($sp) 				   # carrega a instrução
    	li   $t2, MASCARA_CAMPO_OFFSET     # carrega a máscara
    	and  $a0, $t0, $t2                 # separa 16 bits
    	li   $v0, SERVICO_IMPRIME_NUM_HEX  # imprime offset
    	syscall
    	
    	la $a1, buffer_hex
    	jal converte_string_hexadecimal
    	la $a3, buffer_hex
    	grava_hex_output()

    	j nova_linha

	tipo_i3:
	    # grava o mnemônico no arquivo
    	move  $a3, $a0
    	grava_mnem_output() 
    	
    	imprime_espaco()
    	grava_espaco_output()
    	imprime_caracter('$')
    	grava_dolar_output()

    	# pega e grava RT no arquivo de saída
    	lw   $t0, 4($sp)
    	sll  $t0, $t0, 11
		srl  $t0, $t0, 27
		add  $a0, $t0, $zero
		imprime_reg()
		
		move  $a3, $a0
		grava_reg_output()

		imprime_caracter(',')
		grava_virgula_output()
		imprime_espaco()
		grava_espaco_output()

    	# pega grava offset no arquivo de saída
    	lw   $t0, 4($sp)                   # carrega instrução
    	li   $t2, MASCARA_CAMPO_OFFSET     # carrega máscara
    	and  $a0, $t0, $t2 				   # pega os 16 bits
    	li   $v0, SERVICO_IMPRIME_NUM_HEX  # imprime offset
    	syscall
    	
    	la $a1, buffer_hex
    	jal converte_string_hexadecimal
    	la $a3, buffer_hex
    	grava_hex_output()

		imprime_caracter('(')
		grava_abrepar_output()
		imprime_caracter('$')
		grava_dolar_output()

    	# pega e grava RS no arquivo de saída
    	lw   $t0, 4($sp)
    	sll  $t0, $t0, 6
		srl  $t0, $t0, 27
		add  $a0, $t0, $zero
		imprime_reg()
		
		# grava RS no arquivo de saída
		move  $a3, $a0
		grava_reg_output()

		imprime_caracter(')')
		grava_fechapar_output()
    
    	j nova_linha  # pula para nova_linha

	tipo_i4:
	    # grava o mnemônico no arquivo
    	move  $a3, $a0
    	grava_mnem_output() 
    	
    	imprime_espaco()
    	grava_espaco_output()
    	imprime_caracter('$')
    	grava_dolar_output()

    	# pega e grava RT no arquivo de saída
    	lw   $t0, 4($sp)
    	sll  $t0, $t0, 11
		srl  $t0, $t0, 27
		add  $a0, $t0, $zero
		imprime_reg()
		
		move  $a3, $a0
		grava_reg_output()

		imprime_caracter(',')
		grava_virgula_output()
		imprime_espaco()
		grava_espaco_output()

    	# pega e grava imm do arquivo de saída
    	lw   $t0, 4($sp)                   # carrega instrução
    	li   $t2, MASCARA_CAMPO_IMM        # carrega máscara
    	and  $a0, $t0, $t2                 # pega os 16 bits
    	li   $v0, SERVICO_IMPRIME_NUM_HEX  # imprime immediate como hex
    	syscall
    	
    	la $a1, buffer_hex
    	jal converte_string_hexadecimal
    	la $a3, buffer_hex
    	grava_hex_output()

    	j nova_linha # pula para nova_linha

	tipo_i5:
	    # grava o mnemônico no arquivo
    	move  $a3, $a0
    	grava_mnem_output() 
    	
    	imprime_espaco()
    	grava_espaco_output()
    	imprime_caracter('$')
    	grava_dolar_output()

    	# pega e grava RS no arquivo de saída
    	lw   $t0, 4($sp)
    	sll  $t0, $t0, 6
		srl  $t0, $t0, 27
		add  $a0, $t0, $zero
		imprime_reg()
		
		# $t1 = endereço do registrador atual
		# $s2 = endereço base do array de registradores ($zero)
		beq  $t1, $s2, grava_zero2
		bne  $t1, $s2, grava_reg_normal2
		
		grava_zero2:
			move  $a3, $a0
			grava_zero_output()
			j pula2
	
		grava_reg_normal2:
			move  $a3, $a0
			grava_reg_output()
			
		pula2:

		imprime_caracter(',')
		grava_virgula_output()
		imprime_espaco()
		grava_espaco_output()

    	# pega e grava offset no arquivo de saída
    	lw   $t0, 4($sp)                   # carrega a instrução
    	li   $t2, MASCARA_CAMPO_OFFSET     # carrega a máscara do campo offset
    	and  $a0, $t0, $t2                 # pega os 16 bits
    	li   $v0, SERVICO_IMPRIME_NUM_HEX  # imprime offset
    	syscall
    	
    	la $a1, buffer_hex
    	jal converte_string_hexadecimal
    	la $a3, buffer_hex
    	grava_hex_output()

    	j nova_linha # pula para nova_linha
		

	opcode_j:
	    # grava o mnemônico no arquivo
    	move  $a3, $a0
    	grava_mnem_output() 
	
		imprime_espaco()

    	# cálculo do endereço de desvio
    	lw    $t0, 4($sp)                   # carrega instrução
    	li    $t1, MASCARA_CAMPO_ADDR       # carrega a máscara do campo addr
    	and   $t0, $t0, $t1                 # armazena em $t0 os 26 últimos bits
    	sll   $s1, $t0, 2                   # desloca 2 bits para a esquerda

    	lw    $t0, 8($sp)                   # $s0 = PC atual
    	li    $t1, MASCARA_PC               # carrega a máscara do PC
    	and   $s2, $t0, $t1                 # armazena em $t1 os 4 primeiros bits do PC
    
    	or    $a0, $s1, $s2                 # $a0 = endereço de desvio

    	li    $v0, SERVICO_IMPRIME_NUM_HEX  # imprime o endereço de desvio
    	syscall
    	
    	# grava o endereço de desvio no arquivo de saída
    	la    $a1, buffer_hex 
    	jal   converte_string_hexadecimal
        la 	  $a3, buffer_hex
		grava_hex_output()
		
		j nova_linha
		
	
	nao_especificada:
		grava_naoespecificada_output()
		j  nova_linha


	nova_linha:
    	addi  $s0, $s0, 4  # soma PC+4 para atualizar o valor do PC atual
    	imprime_caracter('\n')
    	grava_novalinha_output()
    	j     verifica_fim
    
    converte_string_hexadecimal:
    	# converte valor hexadecimal para ser gravado em um arquivo texto
    	# $a1 = buffer
    	# $a0 = hexadecimal que será convertido em string
   
        li    $t7, ' '                  # $t0 <- '0'
		sb    $t7, 0($a1)               # armazenamos '0' no buffer
        li    $t7, '0'                  # $t0 <- 'x'
        sb    $t7, 1($a1)               # armazenamos 'x' no buffer
        li    $t7, 'x'                  # $t0 <- 'x'
        sb    $t7, 2($a1)               # armazenamos 'x' no buffer
        addiu $a1, $a1, 3               # ajustamos o ponteiro do buffer
		# para cada nibble encontramos o valor hexadeximal.
        lui   $t6, 0xF000               # $t1 = 0xF0000000
        li    $t5, 28                   # $t2 = 28
        la    $t4, hexadecimal          # $t4 = endereço de hexadecimal
        
		laco_converte_string:
        	and   $t3, $a0, $t6             # isolamos o nibble
        	srlv  $t3, $t3, $t5             # deslocamos para o byte menos significativo da palavra
        	add   $t3, $t4, $t3             # $t3 <- endereço do caracter hexadecimal do nibble
        	lbu   $t3, 0($t3)               # $t3 <- caracter hexadecimal do nibble
        	sb    $t3, 0($a1)               # armazenamos $t3 no buffer
        	addiu $a1, $a1, 1               # incrementamos o ponteiro do buffer
			addiu $t5, $t5, -4				# decrementamos 4 de $t2
        	srl   $t6, $t6, 4               # ajustamos a máscara para o próximo nibble
        	# repetimos estas operações até a máscara ser 0x00000000. Quando isto ocorre,
        	# todos os nibbles foram verificados
        	bne   $t6, $zero, laco_converte_string 
        	lb    $zero, 0($a1)             # adicionamos um 0 no final da string
        
        	jr    $ra                       # retornamos ao procedimento chamador
   

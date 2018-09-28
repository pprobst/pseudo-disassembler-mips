.data
	espaco:      .asciiz  " "
	dolar:       .asciiz  "$"
	virgula:     .asciiz  ","
	abre_par:    .asciiz  "("
	fecha_par:   .asciiz  ")"
	newline:     .asciiz "\n"
	setinha:     .asciiz "-->"
	syscall_:    .asciiz "syscall"
	n_especific: .asciiz  "???????"
	
##############
### MACROS ###
##############
######################################################################################################

# imprime_string(%str): imprime a string passada como parâmetro
# exemplo de uso: imprime_string("Olá Mundo!") ---> imprime "Olá Mundo!" no console
.macro imprime_string(%str)
.data
str: .asciiz %str
.text
            li  $v0, SERVICO_IMPRIME_STRING
            la  $a0, str
            syscall
.end_macro

######################################################################################################

.macro imprime_mnemonico()
            li  $v0, SERVICO_IMPRIME_STRING
            syscall
.end_macro

######################################################################################################

# imprime_caracter(%char): imprime um char de sua escolha
# exemplo de uso: imprime_caracter(',') ---> imprime uma vírgula
.macro imprime_caracter(%char)
.text
            li  $v0, SERVICO_IMPRIME_CARACTER
            li  $a0, %char
            syscall
.end_macro

######################################################################################################

# imprime_espaço(): imprime um caracter de espaço (' ')
.macro imprime_espaco()
            imprime_caracter(' ')
.end_macro

######################################################################################################

# newline(): imprime um caracter de nova linha ('\n')
.macro newline()
            imprime_caracter('\n')
.end_macro

######################################################################################################

# abre_arquiv(): usa a syscall 13 para abrir um arquivo
.macro abre_arquivo()
			li  $v0, SERVICO_ABRE_ARQUIVO	
	    	syscall	
.end_macro

######################################################################################################

# termina_programa_sucesso(): usa a syscall 17 para terminar o programa, 
# retornando 0 (sucesso)
.macro termina_programa_sucesso()
			li  $a0, PROGRAMA_EXECUTADO_SUCESSO
			li 	$v0, SERVICO_TERMINA_PROGRAMA
			syscall
.end_macro

#####################################################################################################

# termina_programa_erro(): usa a syscall 17 para terminar o programa, 
# retornando 1 (erro)
.macro termina_programa_erro()
			li  $a0, PROGRAMA_EXECUTADO_ERRO
			li 	$v0, SERVICO_TERMINA_PROGRAMA
			syscall
.end_macro

#####################################################################################################

# le_instrucao_arquivo(): como o nome implica, lê uma instrucao do arquivo
.macro le_instrucao_arquivo()
			lw     $a0, 0($sp)  # $a0 <-- descritor do arquivo
    		addiu  $a1, $sp, 4  # $a1 <-- endereço do buffer de entrada 
    		li     $a2, 4       # $a2 <-- número de caracteres (bytes?) lidos
    		li     $v0, SERVICO_LE_DO_ARQUIVO
    		syscall

.end_macro

#####################################################################################################

# imprime_reg(): substitui o valor inteiro que representa o registrador pela string equivalente
# ex: $8 --> $t0
 .macro imprime_reg()
      		la   $s2, tabela_reg
      		sll  $t1, $a0, 2
      		add  $t1, $s2, $t1
      		lw   $a0, 0($t1)
      		li   $v0, SERVICO_IMPRIME_STRING
      		syscall
.end_macro

####################################################################################################

# imprime_hex(): imprime um hexadecimal qualquer
.macro imprime_hex()
			li $v0, SERVICO_IMPRIME_NUM_HEX
			syscall
.end_macro

####################################################################################################

# grava_hex_output: grava um hexadecimal (8 bytes + 0x) no arquivo texto
.macro grava_hex_output()
			li    $v0, 15       # syscall para escrever no arquivo
        	move  $a0, $s6      # move o descritor do arquivo para $a0
        	move  $a1, $a3		# a1 = o que será escrito
        	li    $a2, 11		# tamanho do buffer
			syscall             # escreve no arquivo
.end_macro

####################################################################################################

# grava_reg_output: escreve algum dos registradores MIPS assembly no arquivo texto
.macro grava_reg_output()
			li    $v0, 15       # syscall para escrever no arquivo
        	move  $a0, $s6      # move o descritor do arquivo para $a0
        	move  $a1, $a3		# $a1 = o que será escrito
        	li    $a2, 2		# tamanho do buffer
			syscall             # escreve no arquivo
.end_macro

####################################################################################################

# grava_instr_output: escreve alguma das instruções mnemônicas MIPS Assembly no arquivo texto
.macro grava_mnem_output()
			li    $v0, 15       # syscall para escrever no arquivo
        	move  $a0, $s6      # move o descritor do arquivo para $a0
        	move  $a1, $a3		# a1 = o que será escrito
        	li    $a2, 7		# tamanho do buffer
			syscall             # escreve no arquivo
.end_macro

####################################################################################################

# grava_syscall_output: escreve "syscall" no arquivo texto
.macro grava_syscall_output()
			li    $v0, 15       # syscall para escrever no arquivo
        	move  $a0, $s6      # move o descritor do arquivo para $a0
       	 	la    $a1, syscall_
        	li    $a2, 7		# tamanho do buffer
			syscall             # escreve no arquivo
.end_macro

####################################################################################################

# grava_zero_output: escreve "zero" no arquivo texto
.macro grava_zero_output()
		li    $v0, 15       # syscall para escrever no arquivo
        move  $a0, $s6      # move o descritor do arquivo para $a0
        move  $a1, $a3		# a1 = o que será escrito
        li    $a2, 4		# tamanho do buffer
		syscall             # escreve no arquivo
.end_macro

####################################################################################################

# grava_espaco_output: escreve um caracter de espaco " " no arquivo
.macro grava_espaco_output()
		li    $v0, 15       # syscall para escrever no arquivo
        move  $a0, $s6      # move o descritor do arquivo para $a0
        la 	  $a1, espaco   # o que será escrito
        li    $a2, 1		# tamanho do buffer
		syscall             # escreve no arquivo
.end_macro

####################################################################################################

# grava_dolar_output: escreve "$" no arquivo
.macro grava_dolar_output()
		li    $v0, 15       # syscall para escrever no arquivo
        move  $a0, $s6      # move o descritor do arquivo para $a0
        la 	  $a1, dolar   # o que será escrito
        li    $a2, 1		# tamanho do buffer
		syscall             # escreve no arquivo
.end_macro

####################################################################################################

# grava_virgula_output: escreve "," no arquivo texto
.macro grava_virgula_output()
		li    $v0, 15       # syscall para escrever no arquivo
        move  $a0, $s6      # move o descritor do arquivo para $a0
        la 	  $a1, virgula   # o que será escrito
        li    $a2, 1		# tamanho do buffer
		syscall             # escreve no arquivo
.end_macro

####################################################################################################

# grava_abrepar_output: escreve "(" no arquivo texto
.macro grava_abrepar_output()
		li    $v0, 15       # syscall para escrever no arquivo
        move  $a0, $s6      # move o descritor do arquivo para $a0
        la 	  $a1, abre_par # o que será escrito
        li    $a2, 1		# tamanho do buffer
		syscall             # escreve no arquivo
.end_macro

####################################################################################################

# grava_fechapar_output: escreve ")" no arquivo texto
.macro grava_fechapar_output()
		li    $v0, 15       # syscall para escrever no arquivo
        move  $a0, $s6      # move o descritor do arquivo para $a0
        la 	  $a1, fecha_par   # o que será escrito
        li    $a2, 1		# tamanho do buffer
		syscall             # escreve no arquivo
.end_macro

####################################################################################################

# grava_novalinha_output: escreve um caracter de nova linha "\n" no arquivo texto
.macro grava_novalinha_output()
		li    $v0, 15         # syscall para escrever no arquivo
        move  $a0, $s6        # move o descritor do arquivo para $a0
        la 	  $a1, newline  # o que será escrito
        li    $a2, 1		  # tamanho do buffer
		syscall               # escreve no arquivo
.end_macro

####################################################################################################

# grava_setinha_output: escreve "-->" no arquivo de output
.macro grava_setinha_output()
		li    $v0, 15         # syscall para escrever no arquivo
        move  $a0, $s6        # move o descritor do arquivo para $a0
        la 	  $a1, setinha  # o que será escrito
        li    $a2, 3		  # tamanho do buffer
		syscall               # escreve no arquivo
.end_macro

####################################################################################################

# grava_naoespecificada_output: escreve "???????" no arquivo de output
.macro grava_naoespecificada_output()
		li    $v0, 15         # syscall para escrever no arquivo
        move  $a0, $s6        # move o descritor do arquivo para $a0
        la 	  $a1, n_especific  # o que será escrito
        li    $a2, 7		  # tamanho do buffer
		syscall               # escreve no arquivo
.end_macro

####################################################################################################
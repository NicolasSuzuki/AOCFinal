.data
    # Constantes de Strings e Interface
    header:     .asciiz "\n==================================\n   SIMULADOR SEMAFORO INTELIGENTE\n==================================\n"
    str_fluxo:  .asciiz "Fluxo detectado (carros): "
    str_media:  .asciiz "Media Movel (5 leituras): "
    str_tempo:  .asciiz "Tempo definido para VERDE: "
    str_seg:    .asciiz "s\n"
    
    # Desenhos ASCII dos estados
    s_red:      .asciiz "\n  [🔴] PARE\n  [  ]\n  [  ]\n"
    s_yellow:   .asciiz "\n  [  ]\n  [🟡] ATENCAO\n  [  ]\n"
    s_green:    .asciiz "\n  [  ]\n  [  ]\n  [🟢] SIGA\n"
    
    timer_msg:  .asciiz " > "

    # Variaveis Globais
    # Vetor para armazenar o historico dos ultimos 5 fluxos de carros
    historico_carros: .word 0, 0, 0, 0, 0 
    tamanho_hist:     .word 0
    tamanho_max:	.word 5
    indice_atual:     .word 0  # Para simular buffer circular

.text
.globl main

# -----------------------------------------------------------------------------
# Funcao Principal (MAIN)
# -----------------------------------------------------------------------------
main:

     # Loop infinito do sistema embarcado
    loop_sistema:
    
        # 1. Leitura de carros passando
        li $v0, 5
        syscall
        move $s0 , $v0

        # 2. Atualizar Vetor de Historico (Chama Funcao)
        move $a0, $s0   # Passa o fluxo atual como argumento
        jal atualizar_historico

        # 3. Calcular Media Movel (Algoritmo nao trivial - Chama Funcaoo)
        jal calcular_media_movel
        move $s1, $v0    # $s1 guarda a media calculada

        # 4. Decidir tempo do VERDE baseado na media
        # Se media > 10 carros, tempo = 9s. Se nao, tempo = 4s.
        li $s2, 4        # Tempo padrao (curto)
        ble $s1, 10, define_estado_verde
        li $s2, 9        # Tempo longo (alto fluxo)

    define_estado_verde:
        # --- ESTADO: VERDE ---
        la $a0, s_green      # Carrega desenho Verde
        move $a1, $s0        # Fluxo atual (para log)
        move $a2, $s1        # Media (para log)
        move $a3, $s2        # Tempo definido
        jal desenhar_interface
        
        # Contagem regressiva do verde
        move $a0, $s2
        jal contagem_regressiva

        # --- ESTADO: AMARELO ---
        # Tempo fixo: 2 segundos
        la $a0, s_yellow
        # Para simplificar, passamos 0 nos logs de fluxo no amarelo/vermelho ou mantemos o anterior
        li $a3, 2            
        jal desenhar_interface_simples # Interface sem stats detalhados
        
        li $a0, 2
        jal contagem_regressiva

        # --- ESTADO: VERMELHO ---
        # Tempo fixo: 5 segundos
        la $a0, s_red
        li $a3, 5
        jal desenhar_interface_simples
        
        li $a0, 5
        jal contagem_regressiva

        j loop_sistema   # Volta para o in?cio

# -----------------------------------------------------------------------------
# Funcaoo: Atualizar Historico (Uso de Vetor/Matriz)
# Descricaoo: Insere o novo valor no vetor substituindo o mais antigo (Round Robin) -> se vetor já tem 5 posições preenchidas
# Entrada: $a0 (novo valor)
# -----------------------------------------------------------------------------
atualizar_historico:
    # (Sem uso de pilha complexa pois eh folha, mas vamos usar t regs)
    lw $t0, indice_atual
    lw $t1, tamanho_hist
    la $t2, historico_carros
    lw $t5, tamanho_max
    
    # Se tamanho do historico menor que 5 (ou seja menos de 5 leituras feitas) ent o adiciona conforme leitura -> se ja for 5 segue com os ultimos 5 fluxos
    bge $t1, 5, continua_sem_atualizar_tamanho
    addi $t1, $t1, 1
    sw $t1, tamanho_hist
    
 continua_sem_atualizar_tamanho:   
    mul $t3, $t0, 4      # Calcula offset (indice * 4 bytes)
    add $t3, $t3, $t2    # Endereco base + offset
    
    sw $a0, 0($t3)       # Salva o novo valor no vetor
    
    # Atualiza indice circular: (i + 1) % tamanho
    addi $t0, $t0, 1
    div $t0, $t5
    mfhi $t0             # Resto da divisao eh o novo indice
    
    sw $t0, indice_atual # Salva na memoria
    jr $ra

# -----------------------------------------------------------------------------
# Funcao: Calcular Media Movel (Algoritmo Nao Trivial)
# Descricaoo: Percorre o vetor, soma e divide pelo tamanho.
# Saida: $v0 (media inteira)
# -----------------------------------------------------------------------------
calcular_media_movel:
    # Salvar $s0 na pilha
    addi $sp, $sp, -4
    sw $s0, 0($sp)
    
    la $t0, historico_carros
    lw $t1, tamanho_hist
    li $t2, 0            # Contador i
    li $t3, 0            # Acumulador soma
    
    loop_soma:
        beq $t2, $t1, fim_soma
        lw $t4, 0($t0)   # Carrega valor do vetor
        add $t3, $t3, $t4 # Soma
        addi $t0, $t0, 4 # Proximo endereco
        addi $t2, $t2, 1 # i++
        j loop_soma
        
    fim_soma:
        div $t3, $t1    # Soma / Tamanho
        mflo $v0         # Resultado em $v0
        move $t5, $v0
        
    # Epilogo: Restaurar pilha
    lw $s0, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# -----------------------------------------------------------------------------
# Funcao: Desenhar Interface Completa (ASCII)
# Entrada: $a0 (Addr String Estado), $a1 (Fluxo), $a2 (Media), $a3 (Tempo)
# -----------------------------------------------------------------------------
desenhar_interface:
    addi $sp, $sp, -4    # Salva $ra pois faremos syscalls
    sw $ra, 0($sp)
    
    move $t0, $a0        # Salva endereco da string do estado
    move $t1, $a1        # Salva fluxo
    move $t2, $a2        # Salva media
    move $t3, $a3        # Salva tempo

    # Imprime Header
    li $v0, 4
    la $a0, header
    syscall

    # Imprime Status do Sensor
    li $v0, 4
    la $a0, str_fluxo
    syscall
    li $v0, 1
    move $a0, $t1
    syscall
    li $v0, 11
    li $a0, 10 # \n
    syscall 
    
    # Imprime Media
    li $v0, 4
    la $a0, str_media
    syscall 
    li $v0, 1
    move $a0, $t5
    syscall
    li $v0, 11
    li $a0, 10 # \n
    syscall 
    
    # Imprime Desenho do Semaforo
    li $v0, 4
    move $a0, $t0
    syscall
    
    # Imprime Tempo Selecionado
    li $v0, 4
    la $a0, str_tempo
    syscall
    li $v0, 1
    move $a0, $t3
    syscall
    li $v0, 4
    la $a0, str_seg
    syscall

    lw $ra, 0($sp)       # Restaura $ra
    addi $sp, $sp, 4
    jr $ra

# -----------------------------------------------------------------------------
# Funcao Auxiliar: Desenhar Interface Simples (Amarelo/Vermelho)
# -----------------------------------------------------------------------------
desenhar_interface_simples:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    move $t0, $a0 # String estado
    
    li $v0, 4
    la $a0, header
    syscall
    
    li $v0, 4
    move $a0, $t0
    syscall
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# -----------------------------------------------------------------------------
# Funcao: Contagem Regressiva (Timer)
# Entrada: $a0 (segundos)
# -----------------------------------------------------------------------------
contagem_regressiva:
    move $t0, $a0
    
    loop_timer:
        blez $t0, fim_timer
        
        # Imprime numero atual
        li $v0, 1
        move $a0, $t0
        syscall
        
        # Imprime " > "
        li $v0, 4
        la $a0, timer_msg
        syscall
        
        # Delay de 1 segundo (1000 ms)
        li $v0, 32
        li $a0, 1000   # Para testar rapido, mude para 500 ou 200
        syscall
        
        addi $t0, $t0, -1
        j loop_timer
        
    fim_timer:
        # Pula linha no final
        li $v0, 11
        li $a0, 10
        syscall
        jr $ra
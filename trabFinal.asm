.data
    # Constantes de Strings e Interface
    header:     .asciiz "\n==================================\n   SIMULADOR SEMAFORO INTELIGENTE\n==================================\n"
    str_fluxo:  .asciiz "Fluxo detectado (carros): "
    str_media:  .asciiz "Media Movel (5 leituras): "
    str_tempo:  .asciiz "Tempo definido para VERDE: "
    str_seg:    .asciiz "s\n"
    
    # Desenhos ASCII dos estados
    s_red:      .asciiz "\n  [x] PARE\n  [  ]\n  [  ]\n"
    s_yellow:   .asciiz "\n  [  ]\n  [x] ATENCAO\n  [  ]\n"
    s_green:    .asciiz "\n  [  ]\n  [  ]\n  [x] SIGA\n"
    
    timer_msg:  .asciiz " > "

    # Variáveis Globais
    # Vetor para armazenar o histórico dos últimos 5 fluxos de carros
    historico_carros: .word 0, 0, 0, 0, 0 
    tamanho_hist:     .word 5
    indice_atual:     .word 0  # Para simular buffer circular

.text
.globl main

# -----------------------------------------------------------------------------
# Função Principal (MAIN)
# -----------------------------------------------------------------------------
main:
    # Loop infinito do sistema embarcado
    loop_sistema:
        
        # 1. Simular leitura do sensor (gera numero aleatorio 0-20)
        li $v0, 42       # Syscall random int range
        li $a0, 0        # ID do gerador
        li $a1, 20       # Upper bound (0 a 19 carros)
        syscall
        move $s0, $a0    # $s0 guarda o fluxo atual

        # 2. Atualizar Vetor de Histórico (Chama Função)
        move $a0, $s0    # Passa o fluxo atual como argumento
        jal atualizar_historico

        # 3. Calcular Média Móvel (Algoritmo não trivial - Chama Função)
        jal calcular_media_movel
        move $s1, $v0    # $s1 guarda a média calculada

        # 4. Decidir tempo do VERDE baseado na média
        # Se média > 10 carros, tempo = 9s. Se não, tempo = 4s.
        li $s2, 4        # Tempo padrão (curto)
        ble $s1, 10, define_estado_verde
        li $s2, 9        # Tempo longo (alto fluxo)

    define_estado_verde:
        # --- ESTADO: VERDE ---
        la $a0, s_green      # Carrega desenho Verde
        move $a1, $s0        # Fluxo atual (para log)
        move $a2, $s1        # Média (para log)
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

        j loop_sistema   # Volta para o início

# -----------------------------------------------------------------------------
# Função: Atualizar Histórico (Uso de Vetor/Matriz)
# Descrição: Insere o novo valor no vetor substituindo o mais antigo (Round Robin)
# Entrada: $a0 (novo valor)
# -----------------------------------------------------------------------------
atualizar_historico:
    # Prologo (Sem uso de pilha complexa pois é folha, mas vamos usar t regs)
    lw $t0, indice_atual
    lw $t1, tamanho_hist
    la $t2, historico_carros
    
    mul $t3, $t0, 4      # Calcula offset (indice * 4 bytes)
    add $t3, $t3, $t2    # Endereço base + offset
    
    sw $a0, 0($t3)       # Salva o novo valor no vetor
    
    # Atualiza índice circular: (i + 1) % tamanho
    addi $t0, $t0, 1
    div $t0, $t1
    mfhi $t0             # Resto da divisão é o novo índice
    
    sw $t0, indice_atual # Salva na memória
    jr $ra

# -----------------------------------------------------------------------------
# Função: Calcular Média Móvel (Algoritmo Não Trivial)
# Descrição: Percorre o vetor, soma e divide pelo tamanho.
# Saída: $v0 (média inteira)
# -----------------------------------------------------------------------------
calcular_media_movel:
    # Prologo: Salvar $s0 na pilha (exemplo de uso de pilha)
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
        addi $t0, $t0, 4 # Próximo endereço
        addi $t2, $t2, 1 # i++
        j loop_soma
        
    fim_soma:
        div $t3, $t1     # Soma / Tamanho
        mflo $v0         # Resultado em $v0
        
    # Epilogo: Restaurar pilha
    lw $s0, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# -----------------------------------------------------------------------------
# Função: Desenhar Interface Completa (ASCII)
# Entrada: $a0 (Addr String Estado), $a1 (Fluxo), $a2 (Media), $a3 (Tempo)
# -----------------------------------------------------------------------------
desenhar_interface:
    addi $sp, $sp, -4    # Salva $ra pois faremos syscalls
    sw $ra, 0($sp)
    
    move $t0, $a0        # Salva endereço da string do estado
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
    
    # Imprime Média
    li $v0, 4
    la $a0, str_media
    syscall 
    li $v0, 11
    li $a0, 10 # \n
    syscall 
    
    # Imprime Desenho do Semáforo
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
# Função Auxiliar: Desenhar Interface Simples (Amarelo/Vermelho)
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
# Função: Contagem Regressiva (Timer)
# Entrada: $a0 (segundos)
# -----------------------------------------------------------------------------
contagem_regressiva:
    move $t0, $a0
    
    loop_timer:
        blez $t0, fim_timer
        
        # Imprime número atual
        li $v0, 1
        move $a0, $t0
        syscall
        
        # Imprime " > "
        li $v0, 4
        la $a0, timer_msg
        syscall
        
        # Delay de 1 segundo (1000 ms)
        li $v0, 32
        li $a0, 1000   # Para testar rápido, mude para 500 ou 200
        syscall
        
        addi $t0, $t0, -1
        j loop_timer
        
    fim_timer:
        # Pula linha no final
        li $v0, 11
        li $a0, 10
        syscall
        jr $ra
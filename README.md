# Simulador de Semáforo Inteligente em MIPS  
Trabalho acadêmico para a materia de Arquitetura e Organização de Computadores (AOC) demonstrando uso de:
- Vetores  
- Buffer circular  
- Funções  
- Stack frame  
- Syscalls avançadas  
- Controle de estado em Assembly MIPS

---

## 🚦 Sobre o Projeto

Um controlador de tráfego criado em Assembly que ajusta o tempo do sinal com base no fluxo de veículos

Este projeto implementa um sistema embarcado simulado em **Assembly MIPS**, capaz de:

- Ler o fluxo de carros em tempo real  
- Armazenar as últimas 5 leituras em um buffer circular  
- Calcular automaticamente a **média móvel**  
- Ajustar o tempo do sinal verde conforme a demanda  
- Renderizar o semáforo em ASCII (vermelho, amarelo, verde)  
- Exibir uma contagem regressiva com temporização real (syscall sleep)

---

## 📁 Estrutura do Projeto
```
/AOCFINAL/
│
├── semaforo.asm # Código-fonte do simulador
└── README.md # Documentação do projeto
```


---

## 🧠 Funcionamento Geral

O sistema funciona em um loop contínuo formado por:

1. **Entrada do fluxo de carros** (syscall 5)  
2. **Atualização do histórico** das últimas 5 leituras  
3. **Cálculo da média móvel**  
4. **Escolha do tempo de sinal verde**:
   - Média ≤ 10 → 4s  
   - Média > 10 → 9s  
5. **Renderização do estado atual do semáforo**  
6. **Contagem regressiva** para verde, amarelo e vermelho

Toda a lógica simula exatamente o comportamento simplificado de um controlador inteligente de tráfego.

---

## 🔄 Buffer Circular (Histórico de Fluxo)

O vetor `historico_carros` armazena 5 valores.  
Assim que o limite é atingido, o índice retorna ao início.

Variáveis importantes:  
- `indice_atual` → aponta onde escrever o próximo valor  
- `tamanho_hist` → quantas leituras já existem  
- `tamanho_max` → limite de 5 posições  

Esse modelo garante que o histórico seja sempre atualizado sem deslocamento de dados.

---

## ➗ Cálculo da Média Móvel

A função `calcular_media_movel`:

- Percorre apenas os valores já preenchidos  
- Soma todos  
- Divide por `tamanho_hist`  
- Retorna a média inteira em `$v0`

A média determina o comportamento inteligente do semáforo.

---

## 🟢🟡🔴 Interface em ASCII

O programa exibe estados visuais do semáforo, como:

### Verde
```
[  ]
[  ]
[🟢] SIGA
```


### Amarelo
```
[  ]
[🟡] ATENCAO
[  ]
```

### Vermelho
```
[🔴] PARE
[  ]
[  ]  
```


---

## ⏱ Temporizador (Contagem Regressiva)

A função `contagem_regressiva` utiliza:

```asm
    syscall 32 # Sleep em milissegundos
```

Ela imprime o valor atual, mostra o símbolo `>`, espera 1 segundo e repete.

---

## ▶️ Como Executar

### Requisitos
- **MARS**, **QtSpim** ou equivalente

### Passos
1. Abra o arquivo `semaforo.asm`  
2. Ative as opções recomendadas:
   - *Settings > Allow pseudo instructions*
   - *MIPS32* habilitado
3. Clique em **Assemble**
4. Depois, clique em **Run**
5. Insira números quando solicitado:


O semáforo irá reagir automaticamente a cada nova leitura.

---




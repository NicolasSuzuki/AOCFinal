# 🚦 Semáforo Inteligente com Sensor de Fluxo de Veículos (MIPS)

Projeto acadêmico desenvolvido para a disciplina de **Arquitetura e Organização de Computadores (AOC)** – UNIFESP ICT.

O sistema simula um **dispositivo embarcado/IoT** em **Assembly MIPS**, capaz de ajustar dinamicamente o tempo do sinal verde de um semáforo com base no fluxo de veículos informado por um sensor simulado.

---

## 1. Resumo

Este projeto implementa um simulador de **semáforo inteligente** em arquitetura MIPS, utilizando uma **máquina de estados completa** (VERDE, AMARELO e VERMELHO), interface ASCII e lógica adaptativa baseada em **média móvel** do fluxo de veículos.

O sistema armazena as últimas leituras em um **buffer circular**, calcula a média móvel e decide automaticamente o tempo do sinal verde conforme a demanda. O resultado é um simulador funcional, modular e coerente com os princípios de programação em baixo nível e sistemas embarcados.

---

## 2. Motivação e Contexto

Semáforos inteligentes são amplamente utilizados em iniciativas de **cidades inteligentes**, com o objetivo de melhorar o fluxo de tráfego, reduzir congestionamentos e otimizar o uso do tempo nos cruzamentos.

O tema foi escolhido por representar claramente um **sistema embarcado real**, envolvendo:
- sensores (entrada de dados),
- processamento (lógica de decisão),
- atuadores (estados do semáforo).

Além disso, o projeto permite aplicar na prática conceitos fundamentais da disciplina, como:
- uso de registradores,
- manipulação de memória,
- pilha e chamadas de função,
- controle de fluxo,
- máquina de estados.

---

## 3. Funcionalidades Implementadas

- **Leitura simulada de sensor**
  - Entrada do número de carros via syscall.
- **Armazenamento em buffer circular**
  - Histórico fixo das últimas 5 leituras.
- **Controle automático de índice circular**
  - Atualização usando operação de módulo (div + mfhi).
- **Cálculo de média móvel**
  - Considera apenas as posições preenchidas do histórico.
- **Decisão dinâmica do tempo do sinal verde**
  - Média ≤ 10 → Verde por 4 segundos  
  - Média > 10 → Verde por 9 segundos
- **Máquina de estados completa**
  - Verde (tempo variável)  
  - Amarelo (2 segundos)  
  - Vermelho (5 segundos)
- **Interface ASCII organizada**
  - Exibe cabeçalho, fluxo atual, média, tempo do verde e desenho do semáforo.
- **Contagem regressiva realista**
  - Delay de 1 segundo entre cada número (syscall sleep).
- **Código modular**
  - Funções independentes e reutilizáveis.

---

## 4. Arquitetura do Programa

O programa foi desenvolvido de forma modular, mesmo com as limitações do Assembly, separando claramente as responsabilidades em funções.

### 4.1. Ciclo de Funcionamento

1. Usuário informa o fluxo de veículos (sensor)
2. Valor é inserido no buffer circular
3. Média móvel é calculada
4. Tempo do sinal verde é definido
5. Estado VERDE é exibido com contagem regressiva
6. Estado AMARELO é exibido
7. Estado VERMELHO é exibido
8. O sistema retorna ao início (loop infinito)

---

## 5. Funções Principais

- **main**
  - Controla o loop do sistema e a máquina de estados.
- **atualizar_historico**
  - Insere novas leituras no buffer circular e controla índice e tamanho.
- **calcular_media_movel**
  - Soma os valores do histórico e divide pelo número de leituras válidas.
- **desenhar_interface**
  - Exibe cabeçalho, fluxo, média, tempo e ASCII do estado.
- **desenhar_interface_simples**
  - Exibe apenas o cabeçalho e o estado (amarelo/vermelho).
- **contagem_regressiva**
  - Realiza a temporização do sistema.

### 5.1. Uso de Registradores

- `$s0` → fluxo atual de veículos  
- `$s1` → média móvel calculada  
- `$s2` → tempo definido para o sinal verde  

Os argumentos são passados via `$a0–$a3`, e retornos via `$v0`, seguindo boas práticas de convenção.

---

## 6. Máquina de Estados

### Estados do Sistema

- **VERDE**
  - Tempo variável conforme a média móvel.
- **AMARELO**
  - Tempo fixo de 2 segundos.
- **VERMELHO**
  - Tempo fixo de 5 segundos.

### Diagrama de Estados

VERDE ──▶ AMARELO ──▶ VERMELHO
                                             

▲─────-─── retorno <─────┘

As transições são sequenciais e determinísticas.

---

## 7. Estrutura de Dados

O sistema utiliza um **vetor de tamanho fixo** para armazenar o histórico de fluxo de veículos, implementado como **buffer circular**.

Variáveis auxiliares:
- `historico_carros` → vetor de leituras
- `indice_atual` → posição de escrita
- `tamanho_hist` → quantidade de leituras válidas

Essa estrutura é adequada para sistemas embarcados por:
- limitar o uso de memória,
- reduzir custo computacional,
- garantir previsibilidade temporal.

---

## 8. Testes e Resultados

Foram realizados testes manuais simulando diferentes cenários:

| Cenário | Entrada | Resultado Esperado |
|------|-------|------------------|
| Baixo fluxo | ≤ 10 | Verde = 4s |
| Alto fluxo | > 10 | Verde = 9s |
| Inicialização | primeiras leituras | crescimento gradual do histórico |
| Buffer cheio | > 5 leituras | sobrescrita correta |

Os testes confirmaram estabilidade do sistema e correção da lógica.

---

## 9. Uso de IA Generativa

A IA generativa foi utilizada **apenas como apoio pontual**, com finalidade didática, para auxiliar na compreensão da organização de dados em memória e do funcionamento da pilha em Assembly MIPS.

Especificamente, a IA foi utilizada para ajudar a entender a estrutura da seção `.data`, que contém strings da interface ASCII, o vetor de histórico e variáveis globais de controle. Todo o código foi compreendido, revisado e integrado manualmente pelo grupo, respeitando as regras do laboratório.

A explicação detalhada dos trechos com apoio de IA, incluindo registradores envolvidos, uso da pilha e correções realizadas, encontra-se documentada no relatório acadêmico do projeto.

---

## 10. Como Executar

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

## 11. Estrutura do Repositório

 /
 
 ├── semaforo.asm
 
 └── README.md

---

## 12. Conclusão

O projeto demonstrou ser possível desenvolver um **sistema reativo e estruturado em Assembly MIPS**, aplicando conceitos centrais da disciplina de Arquitetura e Organização de Computadores. A implementação da máquina de estados, do buffer circular e da média móvel resultou em um simulador funcional, estável e coerente com sistemas embarcados reais.

---

## 13. Referências

- Documentação MIPS32 – MARS / SPIM  
- Material da disciplina de Arquitetura e Organização de Computadores – UNIFESP ICT




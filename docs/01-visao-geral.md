# [01] - VISÃO GERAL - EMUNAH BANK LAB

Ambiente pessoal de simulação bancária em **IBM z/OS**, criado para a prática de rotinas, arquitetura e troubleshooting em **mainframe**.

O projeto reproduz, em escala controlada, elementos comuns de ambientes bancários legados que operam cargas críticas em mainframe, combinando tecnologias clássicas do ecossistema z/OS com ferramentas modernas de automação e operação.

---

## Sobre o projeto

O **Emunah Bank Lab** é um laboratório de prática técnica mainframe em contexto bancário.

A proposta é dominar o funcionamento de aplicações e processos típicos desse ambiente, incluindo:

- desenvolvimento de programas de negócio em **COBOL**;
- processamento transacional online com **CICS**;
- execução e controle de rotinas **batch** com **JCL**;
- manipulação de dados em **VSAM** e **DB2**;
- automação operacional com **REXX**;
- interação moderna com o ambiente por meio do **Zowe CLI**;
- análise de falhas e investigação de **abends**.

Este laboratório busca simular práticas reais de desenvolvimento, operação e suporte em **z/OS**.

---

## Objetivos

- Desenvolver experiência prática com tecnologias centrais do ecossistema **IBM z/OS**;
- Reproduzir fluxos operacionais inspirados em ambientes bancários reais (modelo *core banking*);
- Fortalecer conhecimentos em desenvolvimento, processamento batch, processamento online e suporte técnico;
- Praticar investigação de falhas em cenários de produção simulada;
- Integrar abordagens tradicionais de mainframe com ferramentas modernas de automação.

---

## Stack tecnológica

| Camada | Tecnologia |
|--------|------------|
| Sistema Operacional | z/OS |
| Linguagens | COBOL, REXX |
| Processamento Online | CICS TS, BMS (Basic Mapping Support) |
| Processamento Batch | JCL |
| Armazenamento Core | VSAM (KSDS, ESDS) |
| Banco de Dados Satélite | DB2 |
| Ambiente interativo | TSO / ISPF |
| Acesso ao ambiente | Terminal TN3270 (emulado) e Zowe |
| Tooling moderno | Zowe CLI / Zowe Explorer |
| Simulação operacional | EBOPS (Python) |

---

## Áreas de prática

### COBOL
Desenvolvimento e manutenção de programas com foco em regras de negócio bancárias, como:
- controle de saldo e limites;
- processamento transacional online (BMS/CICS);
- processamento de extrato e snapshot de contas;
- validações de dados e rotinas de postagem batch.

### JCL
Construção, orquestração e depuração de jobs batch, incluindo:
- alocação e definição de VSAM e GDGs;
- organização de esteiras encadeadas (cutoffs e file-watchers);
- controle de dependências via parâmetros `COND`;
- uso de utilitários como `IDCAMS`, `SORT` e `IEBGENER`.

### VSAM e DB2
Modelagem e manipulação de dados em formatos corporativos:
- **VSAM KSDS**: Livro-razão e base de clientes (acesso direto);
- **VSAM ESDS**: Trilhas de lançamentos sequenciais rápidos;
- **DB2**: Repositório relacional para tabelas auxiliares e integração de dados via SQL embarcado.

### CICS
Prática com o subsistema de transações IBM para operações online (*Customer Service*):
- construção e mapeamento de telas 3270 (BMS);
- transações de consulta de saldo, extrato e transferências;
- gestão de bloqueios de recursos (*Locks/Enqueue*) durante a janela online.

### REXX
Automação de tarefas utilitárias e operacionais, com foco em:
- submissão controlada de jobs (*submitters* genéricos);
- *health-checks* de validação de ambiente;
- automação de painéis no **TSO/ISPF**.

### TSO / ISPF
Interação direta com o z/OS via terminal 3270:
- navegação, edição e alocação de datasets;
- execução de comandos MVS e TSO;
- acompanhamento de execuções no SDSF (spool, JES output);
- diagnóstico e operação clássica de contingência.

### Zowe CLI
Uso de interface moderna para produtividade no mainframe:
- orquestração de deploys a partir do ambiente local;
- consumo de APIs z/OSMF para gestão de jobs e transferência de ficheiros;
- automação de esteiras sem a interface do terminal 3270.

### EBOPS — Simulador de Operações
O EBOPS (Emunah Bank Operations Simulator) injeta a componente "humana" e caótica num dia operacional bancário. Ele simula ferramentas corporativas (Control-M, Jira, Changeman, Fault Analyzer) e sorteia incidentes reais — mutando o código-fonte ou ficheiros JCL — para que o utilizador pratique a investigação de falhas (abends, dados truncados, deadlocks) com a pressão de uma operação *live*.

### Troubleshooting
Investigação de falhas em cenários rigorosos de produção:
- leitura de códigos de retorno (RC) e dumps;
- interpretação de abends como **S0C7**, **S878**, **S0C4**, **S806**;
- identificação de conflitos de partilha de ficheiros (ex: CICS *vs.* Batch);
- rastreamento de causa-raiz em falhas de conciliação.

---

## Cenários simulados

O laboratório permite praticar cenários que acontecem na vida real da operação de um grande banco:

- esteiras encadeadas com transição estrita de máquina de estados (`OPEN` → `EOTI` → `EOFI` → `CLOSED`);
- janelas operacionais exclusivas, exigindo comandos de desconexão entre o mundo transacional (CICS) e a janela de processamento pesado (Batch);
- corrupção de dados via ficheiros parceiros (campos truncados, carateres inválidos);
- falhas de integridade e conciliação (Three-way reconciliation);
- reprocessamento de ficheiros rejeitados fora do ciclo oficial (*Off-cycle*).

---

## Competências trabalhadas

- Desenvolvimento e manutenção estruturada em **COBOL** e **CICS**
- Engenharia de *scheduler* e orquestração de **JCL**
- Resiliência de bases de dados **VSAM** e **GDG**
- Automatização de fluxos com **REXX** e **Zowe CLI**
- Disciplina operacional e *Troubleshooting* em **z/OS**
- Diagnóstico em tempo real com o motor de simulação **EBOPS**

---

## Diferenciais do projeto

O **Emunah Bank Lab** combina dois elementos essenciais para o mercado tecnológico atual:

1. **Fidelidade ao rigor operacional:** Não basta compilar um código. A máquina de estados, a conciliação financeira e o isolamento de janelas refletem a gravidade da transação bancária legada.
2. **Abordagem moderna de estudo:** O laboratório não isola o mainframe. Pelo contrário, integra a sua operação com as ferramentas que os programadores da nova geração usam, como VS Code, Git e Zowe CLI.

Isto permite explorar a arquitetura clássica que processa milhões de transações diárias utilizando a agilidade das ferramentas ágeis.

---

## Finalidade

Este projeto tem como objetivo servir como laboratório contínuo de aprendizagem, documentação e evolução técnica em **mainframe bancário**, com foco na prática realista, na disciplina operacional e no aprofundamento técnico profundo.

O mercado financeiro que opera infraestruturas de missão crítica em mainframe enfrenta um desafio substancial de passagem de conhecimento para as novas gerações. O **Emunah Bank Lab** posiciona-se como uma ponte prática que ajuda a reduzir essa lacuna — preparando engenheiros com experiência nas regras e dinâmicas vitais para estas organizações.
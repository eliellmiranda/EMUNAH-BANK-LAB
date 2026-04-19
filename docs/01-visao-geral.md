# [01] - VISÃO GERAL - EMUNAH BANK LAB

Ambiente pessoal de simulação bancária em **IBM z/OS**, criado para estudo prático de rotinas, arquitetura e troubleshooting em **mainframe**.

O projeto reproduz, em escala controlada, elementos comuns de ambientes bancários legados que operam cargas críticas em mainframe, combinando tecnologias clássicas do ecossistema z/OS com ferramentas modernas de automação e operação.

---

## Sobre o projeto

O **Emunah Bank Lab** é um laboratório de prática técnica mainframe em contexto bancário.

A proposta é estudar, de forma prática, o funcionamento de aplicações e processos típicos desse ambiente, incluindo:

- desenvolvimento de programas de negócio em **COBOL**;
- execução e controle de rotinas **batch** com **JCL**;
- manipulação de dados em **VSAM** e **DB2**;
- automação operacional com **REXX**;
- interação moderna com o ambiente por meio do **Zowe CLI**;
- análise de falhas e investigação de **abends**.

Este laboratório busca simular práticas reais de desenvolvimento, operação e suporte em **z/OS**.

---

## Objetivos

- Desenvolver experiência prática com tecnologias centrais do ecossistema **IBM z/OS**;
- Reproduzir fluxos operacionais inspirados em ambientes bancários reais;
- Fortalecer conhecimentos em desenvolvimento, processamento batch e suporte técnico;
- Praticar investigação de falhas em cenários de produção simulada;
- Integrar abordagens tradicionais de mainframe com ferramentas modernas de automação.

---

## Stack tecnológica

| Camada | Tecnologia |
|--------|------------|
| Sistema Operacional | z/OS |
| Linguagens | COBOL, REXX |
| Processamento Batch | JCL |
| Armazenamento | VSAM |
| Banco de Dados | DB2 |
| Ambiente interativo | TSO / ISPF |
| Acesso ao ambiente | Terminal TN3270 emulado / Zowe |
| Tooling moderno | Zowe CLI |
| Simulação operacional | EBOPS (Python) |

---

## Áreas de prática

### COBOL
Desenvolvimento e manutenção de programas com foco em regras de negócio bancárias, como:

- controle de saldo;
- movimentações financeiras;
- processamento de extrato;
- validações de dados e rotinas transacionais.

### JCL
Construção e depuração de jobs batch, incluindo:

- definição de steps;
- organização de execuções;
- controle de retorno;
- análise de falhas e comportamento de jobs.

### VSAM e DB2
Modelagem e manipulação de dados em formatos amplamente utilizados no ambiente mainframe:

- **VSAM KSDS**
- **VSAM ESDS**
- **VSAM RRDS**
- consultas e integração com **DB2**
- uso de **SQL embarcado em COBOL**

### REXX
Automação de tarefas utilitárias e administrativas, com foco em:

- manipulação de datasets;
- validações operacionais;
- automação no **TSO/ISPF**;
- apoio a rotinas recorrentes do ambiente.

### TSO / ISPF
Interação direta e operação do ambiente z/OS via terminal 3270, incluindo:

- navegação pelo painel ISPF (edição, browse e gerenciamento de datasets);
- execução de comandos TSO nativos;
- submissão e acompanhamento de jobs via SDSF;
- inspeção de spool e investigação de falhas em tempo real;
- operação de suporte a rotinas batch e diagnóstico de abends.

### Zowe CLI
Uso de interface moderna para operações no mainframe, permitindo:

- submissão de jobs;
- consulta de spool e logs;
- transferência de datasets;
- execução de fluxos sem dependência exclusiva do terminal 3270.

### EBOPS — Simulador de Operações
O EBOPS (Emunah Bank Operations Simulator) adiciona uma camada de simulação de dia de trabalho bancário, gerando automaticamente tickets, incidentes e tarefas operacionais que reproduzem o que um profissional mainframe encontra ao abrir o computador. Inclui simulação de Control-M, Jira/ServiceNow, Changeman, File Manager e Fault Analyzer, com interface web local e um motor de injeção de falhas controladas no ambiente do lab.

### Troubleshooting
Investigação de falhas em cenários simulados de produção, incluindo:

- leitura de dumps;
- interpretação de abends como **S0C7**, **S222** e **S806**;
- rastreamento de causa-raiz;
- correlação entre erro, job, programa e dados.

---

## Cenários simulados

Este laboratório é orientado à reprodução de situações comuns em ambientes bancários, como:

- processamento batch de contas e transações;
- atualização de arquivos e bases de dados;
- execução encadeada de jobs;
- falhas por erro de dado, ausência de load module ou cancelamento de execução;
- consultas e validações operacionais via terminal e CLI.

---

## Competências trabalhadas

- Desenvolvimento em **COBOL**
- Organização de rotinas **batch**
- Estruturação de jobs com **JCL**
- Manipulação de arquivos **VSAM**
- Integração com **DB2**
- Automação com **REXX**
- Operação e navegação em **TSO/ISPF**
- Operação com **Zowe CLI**
- Diagnóstico e troubleshooting em **z/OS**
- Simulação de operações bancárias com **EBOPS**

---

## Diferenciais do projeto

O **Emunah Bank Lab** combina dois elementos importantes:

1. **fidelidade ao ambiente mainframe tradicional**, com tecnologias amplamente usadas em instituições financeiras;
2. **abordagem moderna de estudo e operação**, incorporando ferramentas atuais para automação, consulta e produtividade.

Isso permite explorar tanto a base clássica do ecossistema z/OS quanto práticas mais atuais de interação com o ambiente.

---

## Finalidade

Este projeto tem como objetivo servir como laboratório contínuo de aprendizado, documentação e evolução técnica em **mainframe bancário**, com ênfase em prática realista, disciplina operacional e aprofundamento técnico.

O laboratório também responde a uma necessidade concreta do mercado: instituições financeiras e empresas que operam sistemas críticos em mainframe enfrentam crescente dificuldade em encontrar profissionais qualificados e treinados nessas tecnologias. O **Emunah Bank Lab** busca ser um ambiente de formação prática que contribui para reduzir essa lacuna — preparando quem o utiliza com experiência concreta nos processos, ferramentas e dinâmicas operacionais exigidas por essas organizações.

---

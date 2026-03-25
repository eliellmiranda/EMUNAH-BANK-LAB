# Fluxo Zowe — Emunah Bank Lab

## Objetivo

Este documento explica como o laboratório utiliza **Zowe CLI** e **Zowe Explorer** para conectar o projeto local ao ambiente mainframe remoto.

O uso de Zowe é central no Emunah Bank Lab porque ele viabiliza um fluxo moderno de trabalho sem abandonar a dinâmica operacional do z/OS.

---

## Princípio geral

O laboratório é dividido em três camadas:

- **camada local** — fontes, documentação, scripts e automações
- **camada remota** — datasets, jobs, spool e arquivos de negócio
- **camada 3270** — operação clássica e troubleshooting aprofundado

O **Zowe** atua como a ponte entre o ambiente local e o ambiente remoto.

---

## Papel de cada camada no fluxo

### Ambiente local
Usado para editar COBOL, JCL e copybooks, manter documentação, versionar o projeto com Git e preparar automações e massa de teste.

### Ambiente remoto
Usado para armazenar datasets e membros, compilar fontes, executar jobs, gerar spool e manter os arquivos do laboratório.

### Ambiente 3270
Usado para ISPF, SDSF, TSO, troubleshooting e investigação quando a visão do Explorer não for suficiente.

### Zowe
Usado para publicar arquivos locais, abrir membros remotos no VS Code, submeter jobs, consultar outputs e automatizar tarefas por linha de comando.

---

## Fluxo de trabalho padrão

O fluxo padrão do laboratório segue esta sequência:

1. editar os arquivos localmente no VS Code
2. salvar na estrutura local do projeto
3. publicar no ambiente remoto por Zowe CLI ou Zowe Explorer
4. conferir a presença dos membros e datasets remotos
5. submeter o JCL correspondente
6. acompanhar status, RC e spool
7. aprofundar a investigação no 3270 quando necessário
8. corrigir localmente, republicar e repetir o ciclo

---

## Fluxo de publicação

### Publicação de copybooks
`copybooks/layouts/` → `Z77948.EMUNAH.DEV.COPY`

### Publicação de fontes COBOL batch
`cobol/batch/` → `Z77948.EMUNAH.DEV.COBOL`

### Publicação de JCLs
`jcl/compile/` e `jcl/batch/` → `Z77948.EMUNAH.DEV.JCL`

### Publicação de arquivo de entrada
`data/entrada/` → `Z77948.EMUNAH.ARQ.ENTRADA.SEQ`

---

## Fluxo de execução

O ciclo operacional mais comum do laboratório envolve:

- envio de programas e copybooks
- submissão dos jobs de build (`EBCOMP`, `EBLINK`, `EBBUILD`)
- envio do arquivo de entrada
- submissão da cadeia batch
- acompanhamento de RC e spool
- investigação complementar em TN3270 / SDSF

---

## Regras do laboratório

- o projeto local é a fonte principal do código e da documentação
- o ambiente remoto é a área de build e execução
- o 3270 é a ferramenta principal de operação e diagnóstico
- alterações permanentes devem ser feitas preferencialmente no ambiente local
- edição remota deve ser usada de forma excepcional e com finalidade operacional

---

## Critério de uso correto do Zowe

O fluxo com Zowe está adequado quando:

- os arquivos locais são publicados no remoto de forma controlada
- os membros aparecem corretamente no Explorer
- os jobs podem ser submetidos sem depender de edição manual no 3270
- os resultados podem ser consultados tanto no Explorer quanto no SDSF
- a correção definitiva volta para o repositório local

---

## Exemplo de ciclo completo

Um exemplo representativo do laboratório:

1. o desenvolvedor edita `EBPOST01.cbl` localmente
2. publica o membro em `Z77948.EMUNAH.DEV.COBOL(EBPOST01)`
3. publica o copybook relacionado
4. submete o job de build
5. submete o job batch
6. verifica RC e output
7. investiga erros no Explorer e, se necessário, no SDSF
8. corrige localmente antes de republicar e reexecutar

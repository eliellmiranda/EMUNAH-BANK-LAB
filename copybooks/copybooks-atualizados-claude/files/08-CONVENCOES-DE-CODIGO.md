# Convenções de Código — Emunah Bank Lab

## Objetivo

Este documento padroniza nomenclatura, estrutura de código, formatos de campo e terminologia do projeto. Toda nova entrega deve seguir estas convenções para manter consistência entre programas, JCLs, datasets, copybooks e documentação.

---

## Prefixos e nomenclatura

### Programas COBOL

| Padrão | Exemplo | Significado |
|---|---|---|
| `EB<MOD><NN>` | `EBPOST01` | EB = Emunah Bank, POST = aplicação de lançamentos, 01 = versão |
| `EBCLLOAD` | `EBCLLOAD` | Carga de clientes e contas (CL = client/conta, LOAD = carga) |

- prefixo `EB` é obrigatório para todos os programas do lab
- módulo identificado pelas letras seguintes (POST, VALI, SALD, EXTR, CONC, REPR, CL)
- sequencial numérico `01`, `02` etc. para versões ou variantes

### Jobs (JCL)

| Padrão | Exemplo | Significado |
|---|---|---|
| `EBJ<FUNC>` | `EBJVALD` | EBJ = Emunah Bank Job, VALD = validação |
| `EB<FUNC>` | `EBCOMP` | Jobs de build: COMP = compile, LINK = link, BUILD = build completo |
| `PRECHECK` | `PRECHECK` | Jobs utilitários podem usar nomes descritivos |

### Copybooks

| Padrão | Exemplo | Significado |
|---|---|---|
| `CP<ENTID>` | `CPCONTA` | CP = copybook, CONTA = entidade |

- prefixo `CP` para todos os copybooks de layout
- nome da entidade ou área funcional em seguida

Catálogo de copybooks do projeto:

| Copybook | Entidade | Registro | Dataset |
|---|---|---|---|
| `CPCLI001` | Cliente | 80 bytes | `ARQ.CLIENTE.KSDS` |
| `CPCNT001` | Conta | 100 bytes | `ARQ.CONTA.KSDS` |
| `CPLCT001` | Lançamento | 120 bytes | `ARQ.ENTRADA.SEQ`, `ARQ.LANCTO.ESDS` |
| `CPSLD001` | Saldo | 100 bytes | `ARQ.SALDO.KSDS` |
| `CPEXT001` | Extrato | 100 bytes | `ARQ.EXTRATO.GDG` |
| `CPREJ001` | Rejeito | 120 bytes | `ARQ.REJEITO.SEQ` |
| `CPAUD001` | Auditoria | 128 bytes | `ARQ.AUDIT.SEQ` |

### Datasets

Convenção geral:
```
Z77948.EMUNAH.<AMBIENTE>.<TIPO>
```

| Qualificador | Uso |
|---|---|
| `Z77948` | HLQ (userid no zXplore) |
| `EMUNAH` | Projeto |
| `DEV` / `HML` / `PRD` | Ambiente (bibliotecas) |
| `ARQ` | Arquivos de negócio |
| `SEED` | Massa inicial |

Tipos de biblioteca:
- `COBOL` — fontes
- `COPY` — copybooks
- `JCL` — JCLs
- `REXX` — scripts REXX
- `LOADLIB` — executáveis
- `PARMLIB` — parâmetros

Tipos de arquivo de negócio:
- `CLIENTE.KSDS` — cadastro de clientes
- `CONTA.KSDS` — cadastro de contas
- `SALDO.KSDS` — saldo consolidado
- `LANCTO.ESDS` — lançamentos aprovados
- `ENTRADA.SEQ` — arquivo de entrada do dia
- `REJEITO.SEQ` — registros rejeitados
- `AUDIT.SEQ` — trilha de auditoria
- `EXTRATO.GDG` — histórico de extratos

### DDNAMEs

| DDNAME | Dataset |
|---|---|
| `CLIENTE` | `ARQ.CLIENTE.KSDS` |
| `CONTA` | `ARQ.CONTA.KSDS` |
| `SALDO` | `ARQ.SALDO.KSDS` |
| `VALIDOS` | `ARQ.LANCTO.ESDS` |
| `ENTRADA` | `ARQ.ENTRADA.SEQ` |
| `REJEITO` | `ARQ.REJEITO.SEQ` |
| `AUDIT` | `ARQ.AUDIT.SEQ` |
| `CLIENTIN` | `SEED.CLIENTES.SEQ` |
| `CONTAIN` | `SEED.CONTAS.SEQ` |

---

## Estrutura de programa COBOL

### Divisões obrigatórias
Todo programa deve ter as quatro divisões na ordem padrão:
1. `IDENTIFICATION DIVISION`
2. `ENVIRONMENT DIVISION`
3. `DATA DIVISION`
4. `PROCEDURE DIVISION`

### IDENTIFICATION DIVISION
- `PROGRAM-ID` com o nome do programa (ex: `EBPOST01`)
- comentário de cabeçalho com: nome do programa, descrição, autor, data, módulo do lab

### WORKING-STORAGE SECTION
- agrupar variáveis por função com comentários separadores:
  - constantes e flags
  - contadores e acumuladores
  - áreas de trabalho
  - campos de data e hora
  - campos de retorno e status
  - mensagens e literais

### Parágrafos
- usar nomes descritivos com numeração: `1000-INICIALIZAR`, `2000-PROCESSAR`, `3000-FINALIZAR`
- separar claramente: inicialização, processamento principal, tratamento de erro, finalização
- usar `PERFORM` para organizar o fluxo
- evitar `GO TO` exceto em tratamento de erro de arquivo

### Comentários
- usar `*` na coluna 7 para comentários de linha
- comentar: propósito do parágrafo, regras de negócio, decisões de design
- não comentar o óbvio (ex: `MOVE 0 TO WS-CONTADOR` não precisa de "zerando contador")

---

## Formatos de campo

### Campos numéricos
- valores monetários em registros de arquivo: `PIC S9(11)V99` (formato DISPLAY, 13 bytes, sinalizado)
- valores monetários em WORKING-STORAGE: `PIC S9(13)V99 COMP-3` (compactado, para cálculos)
- contadores: `PIC S9(09) COMP-3`
- códigos numéricos curtos: `PIC 9(02)` ou `PIC 9(04)`

### Campos alfanuméricos
- nomes: `PIC X(40)`
- documentos (CPF): `PIC X(11)`
- descrições curtas: `PIC X(30)`
- mensagens de erro/auditoria: `PIC X(80)`

### Campos de data
- formato em registros de arquivo: `PIC 9(08)` no padrão `AAAAMMDD` — padrão mainframe batch
- formato em WORKING-STORAGE quando precisar de separador: `PIC X(10)` no padrão `AAAA-MM-DD`
- hora: `PIC 9(08)` no padrão `HHMMSSTH` (preenchido com `ACCEPT FROM TIME`)
- timestamp DB2: `PIC X(26)` no padrão `AAAA-MM-DD-HH.MM.SS.FFFFFF`
- nunca usar formato `DD/MM/AAAA` internamente — só na saída formatada

### Campos de status
- FILE STATUS: `PIC X(02)` — sempre declarar e verificar
- SQLCODE: `PIC S9(09) COMP` — sempre verificar após operação DB2
- códigos de retorno internos: `PIC S9(04) COMP`
- flags: `PIC X(01)` com valores `S`/`N` ou `0`/`1`

---

## Estrutura de JCL

### Cartão JOB
```jcl
//EBJVALD  JOB (EMUNAH),'VALIDACAO',
//         CLASS=A,MSGCLASS=H,MSGLEVEL=(1,1),
//         NOTIFY=&SYSUID
```
- nome do job = nome padronizado do projeto
- `NOTIFY=&SYSUID` sempre presente
- `MSGLEVEL=(1,1)` para diagnóstico completo

### Cartão EXEC
- referenciar programa pelo nome padronizado
- usar `STEPLIB` apontando para a LOADLIB do ambiente correto

### Cartões DD
- usar DDNAMEs conforme tabela padronizada
- sempre especificar `DISP` explicitamente
- datasets de saída devem ter `DISP=(NEW,CATLG,DELETE)` ou `DISP=(MOD,CATLG)` conforme o caso
- datasets de entrada devem ter `DISP=SHR` ou `DISP=(OLD,KEEP)`
- incluir DD de `SYSOUT` para mensagens do programa

### Organização
- agrupar steps logicamente
- documentar o propósito de cada step com comentário `//*`
- usar `COND` ou `IF/THEN/ELSE` para controle de fluxo entre steps

---

## Padrões de auditoria

Todo registro de auditoria deve conter no mínimo:
- data e hora da operação
- identificação do job ou programa
- ação executada (código ou descrição)
- entidade afetada e chave
- resultado (sucesso, rejeito, erro)
- mensagem descritiva

---

## Padrões de rejeito

Todo registro de rejeito deve conter no mínimo:
- registro original (ou chave do registro)
- motivo do rejeito (código e descrição)
- programa e etapa que gerou o rejeito
- data e hora

---

## Padrões de publicação local → remoto

- publicar copybook antes do fonte quando houver dependência
- nunca publicar direto em PRD sem passar por HML
- membro remoto deve ter o mesmo nome do arquivo local
- verificar presença do membro após publicação

---

## Glossário técnico

| Termo | Significado |
|---|---|
| `RC` | Return Code — código de retorno de um job ou step |
| `DISP` | Disposition — como o dataset é tratado (NEW, OLD, SHR, MOD) |
| `GDG` | Generation Data Group — grupo de datasets versionados por geração |
| `PDS` / `PDSE` | Partitioned Data Set — biblioteca com membros |
| `LOADLIB` | Biblioteca de módulos executáveis |
| `COPYLIB` | Biblioteca de copybooks compartilhados |
| `KSDS` | Key Sequenced Data Set — VSAM com acesso por chave |
| `ESDS` | Entry Sequenced Data Set — VSAM com acesso sequencial (append-only) |
| `RRDS` | Relative Record Data Set — VSAM com acesso por posição |
| `PS` / `SEQ` | Physical Sequential — arquivo sequencial simples |
| `SPOOL` | Área de saída de jobs (impressão, logs, mensagens) |
| `SDSF` | System Display and Search Facility — visualização de jobs e spool |
| `ISPF` | Interactive System Productivity Facility — editor e navegador do z/OS |
| `TSO` | Time Sharing Option — ambiente interativo de linha de comando |
| `JES2` | Job Entry Subsystem — gerencia submissão e execução de jobs |
| `IDCAMS` | Access Method Services — utilitário para criação e manutenção de VSAM |
| `ABEND` | Abnormal End — término anormal de programa ou job |
| `S0C7` | Abend por dados inválidos em operação numérica |
| `S222` | Abend por cancelamento do job pelo operador ou por tempo |
| `S806` | Abend por módulo não encontrado na LOADLIB |
| `FILE STATUS` | Código de retorno de operações de arquivo em COBOL |
| `SQLCODE` | Código de retorno de operações SQL em DB2 |
| `COMP-3` | Formato decimal compactado (packed decimal) |
| `HLQ` | High Level Qualifier — primeiro qualificador do nome de dataset |
| `MFT` | Managed File Transfer — transferência controlada de arquivos |
| `DDNAME` | Data Definition Name — nome lógico de arquivo no JCL |
| `STEPLIB` | DD que aponta para a biblioteca de executáveis do step |
| `COND` | Parâmetro de condição para controle de execução entre steps |
| `SEED` | Massa inicial de dados para carga do laboratório |
| `EOD` | End of Day — fechamento do dia operacional |

---

## Resultado esperado

Se estas convenções forem seguidas, o laboratório terá:
- consistência entre todos os artefatos
- facilidade de documentação e troubleshooting
- aparência profissional de ambiente corporativo
- base sólida para crescimento sem perda de rastreabilidade

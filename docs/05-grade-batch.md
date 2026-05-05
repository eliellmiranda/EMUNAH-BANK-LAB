# [05] - GRADE BATCH - EMUNAH BANK LAB

## Objetivo

Este documento descreve a cadeia batch principal do laboratório: ordem de execução dos jobs, transições de `ARQ.CTL.STATUS`, dependências, arquivos de entrada e saída, regras de bloqueio e critérios de sucesso do dia. 

A cadeia foi redesenhada para refletir, em escala de laboratório, o ciclo operacional de um banco real inspirado no modelo FLEXCUBE (`OPEN → EOTI → EOFI → CLOSED`), com isolamento da janela online, cutoffs financeiro e contábil, accruals, snapshot de saldo em GDG e housekeeping de trilhas.

---

## Status do dia — `ARQ.CTL.STATUS`

O dataset `ARQ.CTL.STATUS` é a fonte de verdade sobre a fase atual do ciclo. Cada transição é controlada programaticamente para garantir a integridade da máquina de estados.

| Valor      | Gravado por | Significado                                           |
|------------|-------------|-------------------------------------------------------|
| `OPEN`     | `EBJSOD`    | Dia aberto, cadeia pode prosseguir                    |
| `EOTI`     | `EBJCUTF`   | Cutoff financeiro concluído — fim da janela de postagem |
| `EOFI`     | `EBJCUTE`   | Cutoff contábil concluído — snapshot fechado          |
| `CLOSED`   | `EBJEOD`    | Fechamento diário executado                           |

Qualquer execução fora da sequência esperada deve abortar. O `EBJPRECK` valida o status esperado antes de autorizar o início da cadeia.

---

## Janela batch simulada

| Horário | Job | Papel | Status ao final |
|---|---|---|---|
| 05:55 | **EBJCLOSE** | **Desconecta KSDS do CICS para liberar a janela Batch** | (bloqueia online) |
| 06:00 | `EBJPRECK` | Valida ambiente e lê `CTL.STATUS` | (lê `CLOSED` ou Vazio) |
| 06:05 | `EBJSOD` | Start of Day — Limpeza inicial e abertura do dia | `OPEN` |
| 06:15 | `EBJBCKPD` | Backup das bases em GDG (+1) | `OPEN` |
| 06:30 | `EBJWAIT` | File-watcher — Aguarda e valida `STAGE.ENTRADA.SEQ` | `OPEN` |
| 06:45 | `EBJLOAD` | Promove arquivos do Staging para ARQ Operacional | `OPEN` |
| 07:00 | `EBJVALD` | Valida e separa arquivos em Válidos e Rejeitos | `OPEN` |
| 07:30 | `EBJPOST` | Postagem financeira — Atualiza contas e insere em `LANCTO.ESDS` | `OPEN` |
| 08:00 | `EBJCUTF` | Cutoff Financeiro — Trava entrada de novas transações | `EOTI` |
| 08:15 | `EBJACCR` | Cálculo e postagem de accruals (juros/tarifas) | `EOTI` |
| 08:30 | `EBJSNAP` | Snapshot da base KSDS de Contas para `SALDO.GDG(+1)` | `EOTI` |
| 08:45 | `EBJCUTE` | Cutoff Contábil — Prepara fechamento e conciliação | `EOFI` |
| 09:00 | `EBJCONC` | Conciliação Three-way | `EOFI` |
| 09:30 | `EBJEXTR` | Emissão de Extratos para cliente em `EXTRATO.GDG(+1)` | `EOFI` |
| 10:00 | `EBJEOD` | End of Day — Fechamento do dia (depende da conciliação OK) | `CLOSED` |
| 10:05 | **EBJOPEN** | **Reconecta bases ao CICS (Devolve acesso Online)** | (libera online) |

---

## Descrição dos jobs

### `EBJCLOSE` / `EBJOPEN`
Jobs de infraestrutura CICS. O `EBJCLOSE` desconecta os ficheiros VSAM do ambiente transacional para permitir que o Batch assuma o controle exclusivo (`DISP=OLD`). O `EBJOPEN` reverte o processo após o fechamento do dia.

### `EBJPRECK`
Verifica bibliotecas, presença do arquivo em staging e lê `CTL.STATUS`. Aborta se o status não for `CLOSED` (ciclo anterior fechado) ou vazio (ambiente novo).

### `EBJSOD`
Start of Day. Grava `CTL.STATUS=OPEN` e registra `CTL.PROCDATE`. Primeira escrita de controle do dia.

### `EBJBCKPD`
Backup da foto pré-batch. Exporta `CLIENTE.KSDS` e `CONTA.KSDS` via `REPRO` e arquiva `AUDIT.SEQ` via `IEBGENER`, todos para `BKP.*.GDG(+1)`.

### `EBJWAIT`
File-watcher sobre `STAGE.ENTRADA.SEQ`. Step `CHKEXST` (`LISTCAT`) + step `CHKCNT` (`ICETOOL COUNT NOEMPTY`) com retorno controlado. Falha se arquivo ausente ou vazio.

### `EBJLOAD`
Move `STAGE.ENTRADA.SEQ` para `ARQ.ENTRADA.SEQ` via `IEBGENER`. É aqui que o arquivo do dia entra oficialmente na cadeia operacional.

### `EBJVALD`
Executa `EBVALI01`. Valida layout, tipo de lançamento, valor positivo, conta existente. Gera `VALIDOS` (ESDS) e rejeitos em `ARQ.REJEITOS.SEQ`.

### `EBJPOST`
Executa `EBPOST01`. Aplica lançamentos válidos: atualiza `CONTA.KSDS`, grava em `LANCTO.ESDS` e auditoria em `AUDIT.SEQ`.

### `EBJCUTF`
Cutoff financeiro. Grava `CTL.STATUS=EOTI` via `EBCTL01` ou `IEBGENER`. Marca o fim da janela de postagens do dia.

### `EBJACCR`
Executa `EBACCR01`. Gera movimentos de accrual (juros e tarifas) com base em `PARM.JUROS.CONFIG` e grava em `ARQ.ACCR.MOV.SEQ`.

### `EBJSNAP`
Executa `EBSNAP01`. Fotografa o saldo consolidado de todas as contas em `SALDO.GDG(+1)`. Substitui o conceito antigo de `SALDO.KSDS`.

### `EBJCUTE`
Cutoff contábil. Grava `CTL.STATUS=EOFI`. Dia fica pronto para conciliação.

### `EBJCONC`
Executa `EBCONC01`. Produz `CONCIL.SEQ` (LRECL=132) com três seções de verificação:
1. entrada vs válidos + rejeitos
2. válidos vs postados
3. saldo inicial + líquidos vs saldo final
Qualquer divergência bloqueia o fechamento.

### `EBJEXTR`
Executa `EBEXTR01`. Gera nova geração em `EXTRATO.GDG(+1)`.

### `EBJEOD`
Executa `EBJEOD01`. Fecha o ciclo, grava `CTL.STATUS=CLOSED` e publica a última trilha de auditoria do dia.

### `EBJREPR` / `EBJRPOST`
Off-cycle. `EBJREPR` executa `EBREPR01` para preparar massa corrigida em `REPR.LANCTO.SEQ`; `EBJRPOST` reutiliza `EBPOST01` lendo `REPR.LANCTO.SEQ`.

### `EBJHKGDG`
Monitor passivo — `LISTCAT` das bases GDG. Não altera nada.

### `EBJHKAUD` / `EBJHKREJ`
Housekeeping ativo: `ARCHAUD`/`ARCHREJ` (GDG +1), `DELAUD`/`DELREJ` (IDCAMS), `ALLOCAUD`/`ALLOCREJ` (IEFBR14). Recria o sequencial vazio ao final.

---

## Dependências

- `EBJPRECK` depende do sucesso do `EBJCLOSE`.
- `EBJSOD` depende de `EBJPRECK` ler `CLOSED`.
- `EBJBCKPD` depende de `EBJSOD` (status `OPEN`).
- `EBJWAIT` depende de `EBJBCKPD`.
- `EBJLOAD` depende de `EBJWAIT`.
- `EBJVALD` depende de `EBJLOAD`.
- `EBJPOST` depende de `EBJVALD`.
- `EBJCUTF` depende de `EBJPOST`.
- `EBJACCR` depende de `EBJCUTF` (`EOTI`).
- `EBJSNAP` depende de `EBJACCR`.
- `EBJCUTE` depende de `EBJSNAP`.
- `EBJCONC` depende de `EBJCUTE` (`EOFI`).
- `EBJEXTR` depende de `EBJCONC`.
- `EBJEOD` depende de `EBJEXTR`.
- `EBJOPEN` depende de `EBJEOD` (status `CLOSED`).
- `EBJREPR` e `EBJRPOST` são independentes da cadeia principal.
- `EBJHKGDG`, `EBJHKAUD`, `EBJHKREJ` são independentes e off-cycle.

---

## Regras de bloqueio

A cadeia deve ser interrompida quando ocorrer pelo menos uma das condições abaixo:

- `CTL.STATUS` fora do valor esperado pela fase.
- Falha na desconexão do CICS (`EBJCLOSE`).
- ausência ou arquivo vazio em `STAGE.ENTRADA.SEQ` (detectado em `EBJWAIT`).
- erro crítico na validação (`EBJVALD`).
- divergência na conciliação three-way (`EBJCONC`).
- falha de allocation em GDG (`EBJBCKPD`, `EBJSNAP`, `EBJEXTR`).

O job de reprocessamento **não substitui** a execução normal do dia; só trata rejeitos corrigidos.

---

## Datasets principais da cadeia

- **Operacionais:** `<HLQ>.EMUNAH.ARQ.CLIENTE.KSDS`, `CONTA.KSDS`, `LANCTO.ESDS`, `ENTRADA.SEQ`, `REJEITOS.SEQ`, `AUDIT.SEQ`, `CONCIL.SEQ`, `CTL.STATUS`, `CTL.PROCDATE`, `ACCR.MOV.SEQ`, `REPR.LANCTO.SEQ`
- **Staging:** `<HLQ>.EMUNAH.STAGE.ENTRADA.SEQ`
- **Parâmetros:** `<HLQ>.EMUNAH.PARM.JUROS.CONFIG`
- **Seed:** `<HLQ>.EMUNAH.SEED.CLIENTES.SEQ`, `SEED.CONTAS.SEQ`
- **GDG:** `<HLQ>.EMUNAH.ARQ.EXTRATO.GDG`, `ARQ.SALDO.GDG`, `BKP.CLIENTE.GDG`, `BKP.CONTA.GDG`, `BKP.AUDIT.GDG`, `BKP.REJEITOS.GDG`

---

## Critérios de sucesso do dia

O dia é considerado bem-sucedido quando:

- `CTL.STATUS` percorreu `OPEN → EOTI → EOFI → CLOSED` sem retrocessos.
- O isolamento e retorno da janela online (`EBJCLOSE`/`EBJOPEN`) funcionou.
- arquivo de entrada foi recebido e promovido.
- lançamentos válidos foram postados; rejeitos foram gravados com consistência.
- accruals foram gerados.
- snapshot de saldo foi publicado em nova geração.
- conciliação three-way fechou (sem `DIVERGENTE`).
- extrato foi gerado.
- fechamento diário foi concluído.

---

## Valor da grade batch no projeto

A grade batch é uma peça central do laboratório porque permite praticar:

- ordenação de jobs e dependências baseadas em estado (`CTL.STATUS`).
- separação técnica entre janela transacional e janela de lote.
- cutoffs explícitos como portões de controle de negócio.
- leitura operacional de janelas batch e jobs off-cycle.
- critérios de parada e continuidade (*Stop-the-line*).
- impacto de falhas em cascata.
- investigação orientada por etapa do processo.
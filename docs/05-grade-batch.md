# [05] - GRADE BATCH - EMUNAH BANK LAB

## Objetivo

Este documento descreve a cadeia batch principal do laboratório: ordem de execução dos jobs, transições de `ARQ.CTL.STATUS`, dependências, arquivos de entrada e saída, regras de bloqueio e critérios de sucesso do dia.

A cadeia foi redesenhada para refletir, em escala de laboratório, o ciclo operacional de um banco real inspirado no modelo FLEXCUBE (`OPEN → EOTI → EOFI → CLOSED`), com cutoffs financeiro e contábil, accruals, snapshot de saldo em GDG e housekeeping de trilhas.

---

## Status do dia — `ARQ.CTL.STATUS`

O dataset `ARQ.CTL.STATUS` é a fonte de verdade sobre a fase atual do ciclo. Cada transição é controlada por um job:

| Valor      | Gravado por | Significado                                           |
|------------|-------------|-------------------------------------------------------|
| `OPEN`     | `EBJSOD`    | Dia aberto, cadeia pode prosseguir                    |
| `EOTI`     | `EBJCUTF`   | Cutoff financeiro concluído — fim da janela de postagem |
| `EOFI`     | `EBJCUTE`   | Cutoff contábil concluído — snapshot fechado          |
| `CLOSED`   | `EBJEOD`    | Fechamento diário executado                           |

Qualquer execução fora da sequência esperada deve abortar. O `EBJPRECK` valida o status esperado antes de autorizar a cadeia.

---

## Janela batch simulada

| Horário | Job | Papel | Status ao final |
|---|---|---|---|
| 06:00 | `EBJPRECK` | Valida ambiente e lê `CTL.STATUS` | (lê `CLOSED` do dia anterior) |
| 06:05 | `EBJSOD` | Start of Day — abre ciclo | `OPEN` |
| 06:15 | `EBJBCKPD` | Backup de CLIENTE/CONTA/AUDIT em GDG | `OPEN` |
| 06:20 | `EBJWAIT` | File-watcher sobre `STAGE.ENTRADA.SEQ` | `OPEN` |
| 06:30 | `EBJLOAD` | Promove `STAGE.ENTRADA.SEQ` → `ARQ.ENTRADA.SEQ` | `OPEN` |
| 07:00 | `EBJVALD` | Valida layout e regras de negócio | `OPEN` |
| 07:30 | `EBJPOST` | Aplica lançamentos válidos | `OPEN` |
| 08:00 | `EBJCUTF` | Cutoff financeiro | `EOTI` |
| 08:15 | (`EBACCR01`) | Gera accruals (juros/tarifas) em `ACCR.MOV.SEQ` | `EOTI` |
| 08:30 | `EBJSNAP` | Snapshot de saldo → `SALDO.GDG(+1)` | `EOTI` |
| 08:45 | `EBJCUTE` | Cutoff contábil | `EOFI` |
| 09:00 | `EBJCONC` | Conciliação three-way em `CONCIL.SEQ` | `EOFI` |
| 09:30 | `EBJEXTR` | Extrato → `EXTRATO.GDG(+1)` | `EOFI` |
| 10:00 | `EBJEOD` | Fechamento diário | `CLOSED` |
| Sob demanda | `EBJREPR` | Reprocessamento de rejeitos corrigidos | — |
| Sob demanda | `EBJRPOST` | Postagem de `REPR.LANCTO.SEQ` via `EBPOST01` | — |
| Sob demanda | `EBJHKGDG` | Monitor passivo das bases GDG | — |
| Sob demanda | `EBJHKAUD` | Housekeeping ativo de `ARQ.AUDIT.SEQ` | — |
| Sob demanda | `EBJHKREJ` | Housekeeping ativo de `ARQ.REJEITOS.SEQ` | — |

---

## Encadeamento principal

```text
EBJPRECK
  -> EBJSOD        (CTL.STATUS=OPEN)
  -> EBJBCKPD      (backup GDG)
  -> EBJWAIT       (file-watcher STAGE)
  -> EBJLOAD       (STAGE -> ARQ.ENTRADA)
  -> EBJVALD       (validação)
  -> EBJPOST       (postagem)
  -> EBJCUTF       (CTL.STATUS=EOTI)
  -> (EBACCR01)    (accruals)
  -> EBJSNAP       (SALDO.GDG(+1))
  -> EBJCUTE       (CTL.STATUS=EOFI)
  -> EBJCONC       (three-way)
  -> EBJEXTR       (EXTRATO.GDG(+1))
  -> EBJEOD        (CTL.STATUS=CLOSED)

Off-cycle:
  EBJREPR, EBJRPOST
  EBJHKGDG, EBJHKAUD, EBJHKREJ
```

---

## Descrição dos jobs

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

### `EBACCR01` (programa)
Gera movimentos de accrual (juros e tarifas) com base em `PARM.JUROS.CONFIG` e grava em `ARQ.ACCR.MOV.SEQ`. Pode ser embutido no step seguinte ou invocado como job separado.

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
Monitor passivo — `LISTCAT` das seis bases GDG. Não altera nada.

### `EBJHKAUD` / `EBJHKREJ`
Housekeeping ativo: `ARCHAUD`/`ARCHREJ` (GDG +1), `DELAUD`/`DELREJ` (IDCAMS), `ALLOCAUD`/`ALLOCREJ` (IEFBR14). Recria o sequencial vazio ao final.

---

## Dependências

- `EBJSOD` depende de `EBJPRECK` ler `CLOSED`
- `EBJBCKPD` depende de `EBJSOD` (status `OPEN`)
- `EBJWAIT` depende de `EBJBCKPD`
- `EBJLOAD` depende de `EBJWAIT`
- `EBJVALD` depende de `EBJLOAD`
- `EBJPOST` depende de `EBJVALD`
- `EBJCUTF` depende de `EBJPOST`
- `EBACCR01` depende de `EBJCUTF` (`EOTI`)
- `EBJSNAP` depende de `EBACCR01`
- `EBJCUTE` depende de `EBJSNAP`
- `EBJCONC` depende de `EBJCUTE` (`EOFI`)
- `EBJEXTR` depende de `EBJCONC`
- `EBJEOD` depende de `EBJEXTR`
- `EBJREPR` e `EBJRPOST` são independentes da cadeia principal
- `EBJHKGDG`, `EBJHKAUD`, `EBJHKREJ` são independentes e off-cycle

---

## Regras de bloqueio

A cadeia deve ser interrompida quando ocorrer pelo menos uma das condições abaixo:

- `CTL.STATUS` fora do valor esperado pela fase
- ausência ou arquivo vazio em `STAGE.ENTRADA.SEQ` (detectado em `EBJWAIT`)
- erro crítico na validação (`EBJVALD`)
- divergência na conciliação three-way (`EBJCONC`)
- falha de allocation em GDG (`EBJBCKPD`, `EBJSNAP`, `EBJEXTR`)

O job de reprocessamento **não substitui** a execução normal do dia; só trata rejeitos corrigidos.

---

## Datasets principais da cadeia

- Operacionais: `<HLQ>.EMUNAH.ARQ.CLIENTE.KSDS`, `CONTA.KSDS`, `LANCTO.ESDS`, `ENTRADA.SEQ`, `REJEITOS.SEQ`, `AUDIT.SEQ`, `CONCIL.SEQ`, `CTL.STATUS`, `CTL.PROCDATE`, `ACCR.MOV.SEQ`, `REPR.LANCTO.SEQ`
- Staging: `<HLQ>.EMUNAH.STAGE.ENTRADA.SEQ`
- Parâmetros: `<HLQ>.EMUNAH.PARM.JUROS.CONFIG`
- Seed: `<HLQ>.EMUNAH.SEED.CLIENTES.SEQ`, `SEED.CONTAS.SEQ`
- GDG: `<HLQ>.EMUNAH.ARQ.EXTRATO.GDG`, `ARQ.SALDO.GDG`, `BKP.CLIENTE.GDG`, `BKP.CONTA.GDG`, `BKP.AUDIT.GDG`, `BKP.REJEITOS.GDG`

---

## Critérios de sucesso do dia

O dia é considerado bem-sucedido quando:

- `CTL.STATUS` percorreu `OPEN → EOTI → EOFI → CLOSED` sem retrocessos
- arquivo de entrada foi recebido e promovido
- lançamentos válidos foram postados; rejeitos foram gravados com consistência
- accruals foram gerados
- snapshot de saldo foi publicado em nova geração
- conciliação three-way fechou (sem `DIVERGENTE`)
- extrato foi gerado
- fechamento diário foi concluído

---

## Valor da grade batch no projeto

A grade batch é uma peça central do laboratório porque permite praticar:

- ordenação de jobs e dependências baseadas em estado (`CTL.STATUS`)
- separação entre janela financeira e janela contábil
- cutoffs explícitos como portões de controle
- leitura operacional de janelas batch e jobs off-cycle
- critérios de parada e continuidade
- impacto de falhas em cadeia
- investigação orientada por etapa do processo
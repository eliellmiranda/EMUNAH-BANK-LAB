# Inventário de Mudanças — Redesenho da Cadeia Batch

> Branch: `refactor/cadeia-batch`
> Companheiro da proposta em `docs/proposta-cadeia-batch-realista.md`
> Serve como checklist operacional: o que manter, o que alterar, o que renomear, o que criar, o que descartar.

## Decisões de base

- Nome da branch: `refactor/cadeia-batch` (não `-eod`).
- Máxima proximidade com produção + `EBJACCR` agora → o programa de juros/tarifas vira `EBACCR01` de verdade, com arquivo de parâmetros (`PARM.JUROS.CONFIG`) e saída própria (`ARQ.ACCR.MOV.SEQ`). Não vai ser hook.
- `CTL.BRANCH.STATUS` como source of truth → `EBJSOD`/`EBJCUTF`/`EBJCUTE`/`EBJEOD` vão ler e gravar o status, e a dependência real da cadeia passa por ele, não por horário.

---

## 1. JCLs (`jcl/batch/` + `jcl/util/`)

### 1.1 Mantidos intactos (zero mudança)

| JCL | Observação |
|-----|------------|
| `EBJREPR.jcl` | Continua off-cycle, sem mexer. O ciclo fecha via `EBJRPOST` novo, não alterando este. |

### 1.2 Mantidos com alteração

| JCL | O que muda |
|-----|------------|
| `EBJPRECK.jcl` | Remover o step `CHKENTR` (passa para `EBJWAIT`). Acrescentar verificação do dataset `CTL.BRANCH.STATUS`. |
| `EBJLOAD.jcl` | Reescrito: deixa de ser `LISTCAT` e passa a ser carga real do arquivo do dia (`IEBGENER`/`REPRO`) para `ARQ.ENTRADA.SEQ`. |
| `EBJVALD.jcl` | Padronizar DD `REJEITOS` (plural) e DSN `ARQ.REJEITOS.SEQ`. |
| `EBJPOST.jcl` | Sem mudança funcional. O mesmo JCL serve como base para o `EBJRPOST` (com DD de input apontando para `REPR.LANCTO.SEQ`). |
| `EBJCONC.jcl` | Adicionar DDs para três-vias: `ENTRIN` (entrada), `REJEIT` (rejeitos), `SALDOIN` (snapshot GDG). Saída `CONCIL.SEQ` ganha novo layout. |
| `EBJEXTR.jcl` | Reposicionado na cadeia (após CONC). Output passa a ser `ARQ.EXTRATO.GDG(+1)` em vez de `EXTRATO.SEQ`. |
| `EBJEOD.jcl` | Adicionar step final que grava `CTL.BRANCH.STATUS=CLOSED` via `IEBGENER`. |

### 1.3 Renomeados / repropósito

| De | Para | Natureza |
|----|------|----------|
| `EBJBACKP.jcl` | `EBJBKPD.jcl` | Passa a gerar backup em GDG (`BKP.CLIENTE.GDG(+1)`, idem CONTA e AUDIT). Momento: ainda na fase SOD, mas conceitualmente é o backup do dia anterior já fechado. |
| `EBJSALD.jcl` | `EBJSNAP.jcl` | Invoca o programa novo `EBSNAP01`. A JCL é praticamente refeita. |

### 1.4 Novos

| JCL | Função |
|-----|--------|
| `EBJSOD.jcl` | Abre o dia contábil: grava `CTL.PROCDATE` e `CTL.BRANCH.STATUS=OPEN`. |
| `EBJWAIT.jcl` | File-watcher do `ENTRADA.SEQ`: existência + trailer + count + hash. |
| `EBJCUTF.jcl` | Marca `CTL.BRANCH.STATUS=EOTI` (fecha janela de input). |
| `EBJACCR.jcl` | Juros/tarifas — invoca `EBACCR01`. |
| `EBJCUTE.jcl` | Marca `CTL.BRANCH.STATUS=EOFI` (fecha janela contábil). |
| `EBJRPOST.jcl` | Reinjeta recuperados do `EBJREPR` em `EBPOST01` — fecha o ciclo de rejeito. |
| `EBJHKGDG.jcl` | Housekeeping de GDG (roll de gerações antigas). |
| `EBJHKAUD.jcl` | Rotação do `AUDIT.SEQ` (arquiva + reinicia). |
| `EBJHKREJ.jcl` | Arquivamento de `REJEITOS.SEQ` do dia. |

### 1.5 Movidos para `jcl/util/` (saem do batch)

| JCL | Destino | Motivo |
|-----|---------|--------|
| — | `jcl/util/EBUSALD.jcl` (novo) | Passa a invocar `EBSALD01` como utilitário de consulta manual de saldo. |

**Total na cadeia:** 1 intacto + 7 alterados + 2 renomeados + 9 novos = **19 JCLs orquestrados pelo batch**, contra os 10 atuais.

---

## 2. Programas COBOL (`cobol/batch/` + `cobol/util/`)

### 2.1 Mantidos intactos

| Programa | Observação |
|----------|------------|
| `EBPOST01.cbl` | Serve simultaneamente ao `EBJPOST` e ao `EBJRPOST`. Contrato de entrada já é o correto. |
| `EBREPR01.cbl` | Continua só revalidando; o re-post é problema do `EBJRPOST`. |
| `EBCLLOAD.cbl` | Fora da cadeia diária (seed), intacto. |

### 2.2 Alterados

| Programa | O que muda | Esforço |
|----------|------------|---------|
| `EBVALI01.cbl` | Remover o trailer `T***` do `VALIDOS` (vai para SYSOUT). Padronizar DDNAME `REJEITOS`. | S |
| `EBCONC01.cbl` | Refatoração grande: conciliação três-vias (entrada = válidos + rejeitos; válidos = postados; saldo inicial + líquidos = saldo final). RC=8 bloqueante se não bater. | M-L |
| `EBEXTR01.cbl` | Ajuste para escrever em GDG; lógica interna praticamente igual. | S |
| `EBJEOD01.cbl` | Gravar `CTL.BRANCH.STATUS=CLOSED`; ler `SALDO.GDG(0)` e validar contra `CONCIL.SEQ`. | S-M |

### 2.3 Novos

| Programa | Função | Esforço |
|----------|--------|---------|
| `EBSNAP01.cbl` | Lê `CONTA.KSDS` sequencial, grava `SALDO.GDG(+1)` com saldo final por conta (agência, conta, saldo, data D). | M |
| `EBACCR01.cbl` | Lê `CONTA.KSDS` + `PARM.JUROS.CONFIG`, calcula juros/tarifas por tipo de conta (corrente/poupança), atualiza `CONTA.KSDS`, grava `ARQ.ACCR.MOV.SEQ` e anexa em `LANCTO.ESDS`. | M-L |
| `EBCTL01.cbl` | Utilitário de status: lê estado atual, valida transição (OPEN→EOTI→EOFI→CLOSED), grava novo estado. Usado por `EBJSOD`, `EBJCUTF`, `EBJCUTE`, `EBJEOD`. | S |

### 2.4 Movidos para `cobol/util/`

| Programa | Destino | Observação |
|----------|---------|------------|
| `EBSALD01.cbl` | `cobol/util/EBSALD01.cbl` | Documentar como utilitário de consulta manual de saldo por conta. Precisa de `docs/` próprio ou seção no `03-modulos.md`. |

### 2.5 Descartados (deletados)

Nenhum. Tudo que era útil vira utilitário ou é alterado.

---

## 3. Datasets

### 3.1 Mantidos intactos

| Dataset | Org. | Observação |
|---------|------|------------|
| `ARQ.ENTRADA.SEQ` | PS | Arquivo de entrada do dia (passa a ser populado pelo `EBJLOAD` real). |
| `ARQ.CLIENTE.KSDS` | VSAM KSDS | Cadastro master de clientes. |
| `ARQ.CONTA.KSDS` | VSAM KSDS | Cadastro master de contas (saldo vive aqui). |
| `ARQ.LANCTO.ESDS` | VSAM ESDS | Histórico imutável de movimentos. |
| `ARQ.FECHTO.SEQ` | PS | Relatório de fechamento. |
| `ARQ.REPR.LANCTO.SEQ` | PS | Saída do `EBJREPR`; passa a ser input do `EBJRPOST`. |
| `ARQ.REPR.REJPERM.SEQ` | PS | Rejeitos permanentes após reprocessamento. |

### 3.2 Alterados

| Dataset | O que muda |
|---------|------------|
| `ARQ.AUDIT.SEQ`  | Nome e layout mantidos; passa a ter ciclo de vida com rotacao via EBJHKAUD (archive -> GDG + truncate). |
| `ARQ.CONCIL.SEQ` | DSN mantido. Layout novo (LRECL 132). Passa a ter 3 secoes de conciliacao: S1: ENTRADA vs VALIDOS + REJEITOS S2: VALIDOS vs POSTADOS; S3: SALDO INICIAL + LIQUIDOS vs SALDO FINAL. Cada secao grava linhas tipadas (H/D/R) + rodape (T98/T99). Layout detalhado sera registrado em copy CONCILR.cpy na Onda 4, junto com a refatoracao do EBCONC01. |

### 3.3 Renomeados

| De | Para | Motivo |
|----|------|--------|
| `ARQ.REJEITO.SEQ` | `ARQ.REJEITOS.SEQ` | Padronização confirmada (plural). Hoje existe inconsistência VALD vs REPR. |

### 3.4 Novos

| Dataset | Org. | Função |
|---------|------|--------|
| `ARQ.CTL.STATUS` | PS | Status do branch (`OPEN`/`EOTI`/`EOFI`/`CLOSED`). |
| `ARQ.CTL.PROCDATE` | PS | Data de processamento corrente (D). |
| `ARQ.SALDO.GDG` | GDG | Snapshots diários de saldo (base). |
| `ARQ.EXTRATO.GDG` | GDG | Extratos por geração (substitui `EXTRATO.SEQ`). |
| `BKP.CLIENTE.GDG` | GDG | Backup rotativo de `CLIENTE.KSDS`. |
| `BKP.CONTA.GDG` | GDG | Backup rotativo de `CONTA.KSDS`. |
| `BKP.AUDIT.GDG` | GDG | Backup rotativo de `AUDIT.SEQ`. |
| `BKP.REJEITOS.GDG` | GDG | Arquivamento diário de `REJEITOS.SEQ` (via `EBJHKREJ`). |
| `PARM.JUROS.CONFIG` | PS/PDS | Parâmetros de juros/tarifas por tipo de conta (usado por `EBACCR01`). |
| `ARQ.ACCR.MOV.SEQ` | PS | Movimentos de juros/tarifas gerados (feed para `LANCTO.ESDS`). |
| `ARQ.ENTRADA.TRAILER.SEQ` | PS | Trailer/manifest do `ENTRADA.SEQ` (hash, count, data) — usado pelo `EBJWAIT`. |

### 3.5 Descartados (substituídos)

| Dataset | Substituído por | Motivo |
|---------|-----------------|--------|
| `ARQ.EXTRATO.SEQ` | `ARQ.EXTRATO.GDG` | GDG de verdade, conforme doc original prometia. |
| `BKP.CLIENTE.SEQ` | `BKP.CLIENTE.GDG` | Rotação. |
| `BKP.CONTA.SEQ` | `BKP.CONTA.GDG` | Rotação. |
| `BKP.AUDIT.SEQ` | `BKP.AUDIT.GDG` | Rotação. |
| `ARQ.SALDO.SEQ` | — | Era input do `EBSALD01` (consulta). Passa a ser manual, quando o utilitário for usado. |

### 3.6 Decisão tomada

| Dataset | Decisão |
|---------|---------|
| `ARQ.SALDO.KSDS` | **Descartado.** Removido do mapa de datasets. Era órfão: declarado em `04-mapa-datasets.md`, nenhum JCL/COBOL o usava. |

---

## 4. Placar

- **JCLs:** 1 intacto · 7 alterados · 2 renomeados · 9 novos · 1 movido para util = **19 na cadeia + 1 no util**.
- **COBOL:** 3 intactos · 4 alterados · 3 novos · 1 movido para util = **10 programas vivos**.
- **Datasets:** 7 intactos · 2 alterados · 1 renomeado · 11 novos · 5 substituídos · 1 descartado.

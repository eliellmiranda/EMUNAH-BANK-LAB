# PROPOSTA — CADEIA BATCH REALISTA (aderência a banco real)

> **Status:** proposta aprovada pelo Eliel. Todas as decisões tomadas. Base técnica para a branch de implementação `refactor/cadeia-batch` (já aberta).
>
> **Autor da leitura:** pareamento com Claude.
> **Baseado em:** leitura dos JCLs (`jcl/batch/*.jcl`), COBOL (`cobol/batch/*.cbl`), `docs/05-grade-batch.md`, `docs/04-mapa-datasets.md`, `docs/06-runbooks.md`, `ebops/EBOPS-GUIA-COMPLETO.md` e cenários `01–04`.
> **Referência externa:** fases canônicas de EOD em core-banking (FLEXCUBE / BMC / literatura de EOD/BOD).

---

## 1. Como bancos reais organizam a janela batch

Independentemente do fornecedor (FLEXCUBE, Temenos T24, Hogan, ALTEC, sistemas próprios), o ciclo diário em mainframe bancário se organiza em **fases lógicas nomeadas**, não em uma fila plana de jobs. As fases abaixo são as mais comuns:

| Fase | Nome canônico | O que acontece |
|---|---|---|
| 1 | **SOD / BOD** (Start/Beginning of Day) | Ambiente preparado, data de processamento aberta, *baseline* do dia anterior preservado |
| 2 | **File Arrival / Intake** | Arquivos de entrada (lotes, CNAB, SPB, etc.) chegam, são validados em integridade (trailer, hash, contagem) e só então liberados para a cadeia |
| 3 | **EOTI** (End of Transaction Input) | Marca que nenhuma nova transação do dia será aceita. A partir daqui, o lote é fechado |
| 4 | **Validation** | Layout, regras de negócio, enriquecimento, rejeito segregado para quarentena |
| 5 | **Posting** | Lançamentos válidos aplicados às contas (atualiza saldo, grava movimento imutável) |
| 6 | **Accruals / Fees / Interest** | Juros, tarifas, IOF, rendimento — lançamentos gerados pelo próprio sistema |
| 7 | **Balance Snapshot** | Fotografia do saldo final do dia — é o saldo que vai aparecer no extrato e no SOD do dia seguinte |
| 8 | **Reconciliation** | Três-vias: entrada = válidos + rejeitos; válidos = postados; saldo inicial + líquidos = saldo final. **Bloqueante** — se não bater, o dia não fecha |
| 9 | **EOFI** (End of Financial Input) | Marca que nenhum lançamento contábil pode mais ser feito |
| 10 | **Output / Statements** | Extratos, arquivos de retorno, relatórios regulatórios — só após conciliação passar |
| 11 | **EOD** (End of Day) | Fechamento formal, mudança da data contábil, liberação para BOD do próximo dia |
| 12 | **Housekeeping** | GDG roll, arquivamento de AUDIT, rotação de rejeitos, limpeza de trabalho |
| 13 | **Off-cycle** | Reprocessamentos, reprocessos de rejeitos corrigidos, retrabalho — **fora** da cadeia oficial |

Três princípios que aparecem em 100% dos desenhos reais e que a cadeia atual do EMUNAH viola ou embute de forma implícita:

1. **Reconciliação é porteiro da saída ao cliente.** Extrato, arquivo de retorno e qualquer artefato que sai do banco só é produzido depois de a conciliação fechar.
2. **Rejeito é um objeto com ciclo de vida próprio.** Ele é *produzido* em uma fase, *quarentenado* em um dataset conhecido, *corrigido* fora do ciclo, e *reinjetado* via reprocessamento que atravessa POST novamente. Não basta "revalidar".
3. **Cada fase tem um marcador de status.** Em FLEXCUBE isso é literal (EOTI/EOFI/EOD no branch status). No EMUNAH será o dataset `ARQ.CTL.STATUS`, que passa a ser a *source of truth* da cadeia (horários viram apenas sugestão de janela).

---

## 2. O que a leitura do lab revelou

### 2.1. Achados de nomenclatura e intenção vs. implementação

| Job/Programa | Intenção documentada | O que o código faz de fato | Diagnóstico |
|---|---|---|---|
| `EBJLOAD` | "prepara o arquivo do dia" | `LISTCAT` em `ARQ.ENTRADA.SEQ` | **Não carrega nada.** É um *check* idêntico ao `CHKENTR` de `EBJPRECK` — duplicado |
| `EBJPRECK` | "verifica pré-condições" | `LISTCAT` de LOADLIB, COPY, ENTRADA, CLIENTE, CONTA | Correto, mas **já inclui a verificação do arquivo de entrada** → sobreposição com `EBJLOAD` |
| `EBSALD01` | "consolida saldos" | Lê `SALDO.SEQ` (input de consultas), busca conta no KSDS, grava relatório | **Não consolida nada.** É um *query report*. A consolidação real já é feita pelo `EBPOST01` |
| `EBCONC01` | "concilia totais" | Lê `LANCTO.ESDS` e totaliza C/D | **Totalização simples**, não é conciliação três-vias. Não lê entrada nem saldo |
| `EBJEXTR` | "gera extratos (GDG)" | Grava em `ARQ.EXTRATO.SEQ` (PS), não GDG | Doc diz GDG, JCL aloca PS — **divergência real** |
| `EBJREPR` | "reprocessa rejeitos corrigidos" | Revalida rejeitos, grava `REPR.LANCTO.SEQ` recuperados | **Ciclo aberto.** Recuperados ficam num arquivo órfão — não voltam para POST |
| `EBJBACKP` | "backup do estado anterior" | Exporta `CLIENTE.KSDS`, `CONTA.KSDS`, `AUDIT.SEQ` | Correto em intenção, **mas roda antes de qualquer coisa mudar**, o que equivale a um backup pós-EOD do dia anterior postergado |
| `EBVALI01` trailer | — | Grava registro `T***` como último do `VALIDOS.OUT` | Esse trailer **vai passar por POST, CONC e EXTR** se não for filtrado — potencial bug silencioso |
| `ARQ.REJEITOS.SEQ` vs `ARQ.REJEITO.SEQ` | — | VALD grava `REJEITOS` (plural); REPR lê `REJEITO` (singular); doc de datasets usa `REJEITO` | **Inconsistência de nome** |
| `ARQ.SALDO.KSDS` | "saldo consolidado por conta" | Declarado no mapa, **nenhum JCL/COBOL o usa** | **Órfão — descartado nesta proposta** (saldo autoritativo vive em `CONTA.KSDS.CNT-SALDO`) |

### 2.2. Ordem atual não bate com prática real

A cadeia `POST → SALD → EXTR → CONC → EOD` publica extrato **antes** de conciliar. Em banco real, `EXTR` viria **depois** de `CONC`, e `CONC` depois de um balance snapshot real.

### 2.3. O que está razoavelmente certo

- `EBJPRECK` como primeira barreira com RC=12 bloqueante é coerente.
- `EBJBACKP` como rede de segurança pré-processamento é válido (só o nome e o momento merecem revisão).
- `EBJVALD` acumular múltiplos motivos de rejeito por registro é **melhor** que o padrão da maioria dos legados.
- Segregação de `REJEITOS.SEQ` está implementada no COBOL (só faltou fechar o ciclo).
- Cenário `04-arquivo-entrada-ausente` já exercita o bloqueio da cadeia — a lógica de "porteiro" está na cultura do lab.

---

## 3. Cadeia proposta

### 3.1. Grade batch por fase e horário

Horários são **sugestão de janela**. A dependência real é o estado em `ARQ.CTL.STATUS`.

```text
┌──────── FASE 1 · SOD ─────────────────────────────────────────┐
│ 05:30  01  EBJSOD    → grava CTL.PROCDATE + STATUS=OPEN       │
│ 05:45  02  EBJPRECK  → verifica ambiente (LOADLIB, COPY, VSAM)│
│ 06:00  03  EBJBKPD   → backup do dia anterior (BKP.*.GDG)     │
└───────────────────────────────────────────────────────────────┘
                            ↓
┌──────── FASE 2 · INTAKE ──────────────────────────────────────┐
│ 06:15  04  EBJWAIT   → valida ENTRADA (trailer/hash/count)    │
│ 06:30  05  EBJLOAD   → carga real para ARQ.ENTRADA.SEQ        │
│ 06:45  06  EBJCUTF   → STATUS = EOTI (janela de input fecha)  │
└───────────────────────────────────────────────────────────────┘
                            ↓
┌──────── FASE 3 · VALIDATION ──────────────────────────────────┐
│ 07:00  07  EBJVALD   → VALIDOS.OUT + REJEITOS.SEQ             │
└───────────────────────────────────────────────────────────────┘
                            ↓
┌──────── FASE 4 · POSTING ─────────────────────────────────────┐
│ 07:30  08  EBJPOST   → atualiza CONTA.KSDS + LANCTO.ESDS      │
└───────────────────────────────────────────────────────────────┘
                            ↓
┌──────── FASE 5 · ACCRUAL ─────────────────────────────────────┐
│ 08:00  09  EBJACCR   → juros/tarifas                          │
│                      · CONTA.KSDS + PARM.JUROS.CONFIG         │
│                      · grava ACCR.MOV.SEQ                     │
│                      · append em LANCTO.ESDS                  │
└───────────────────────────────────────────────────────────────┘
                            ↓
┌──────── FASE 6 · SNAPSHOT ────────────────────────────────────┐
│ 08:30  10  EBJSNAP   → SALDO.GDG(+1) (saldo final do dia)     │
└───────────────────────────────────────────────────────────────┘
                            ↓
┌──────── FASE 7 · RECONCILIATION ──────────────────────────────┐
│ 08:45  11  EBJCONC   → conciliação 3-vias · BLOQUEANTE        │
│                      · ENTRADA = VALIDOS + REJEITOS           │
│                      · VALIDOS = postados em LANCTO.ESDS      │
│                      · SALDO(D-1) + líquidos = SALDO(D)       │
│ 09:30  12  EBJCUTE   → STATUS = EOFI                          │
└───────────────────────────────────────────────────────────────┘
                            ↓
┌──────── FASE 8 · OUTPUT ──────────────────────────────────────┐
│ 09:45  13  EBJEXTR   → EXTRATO.GDG(+1)                        │
│ 10:15  14  EBJEOD    → FECHTO.SEQ + STATUS = CLOSED           │
└───────────────────────────────────────────────────────────────┘
                            ↓
┌──────── FASE 9 · HOUSEKEEPING ────────────────────────────────┐
│ 22:00  15  EBJHKGDG  → roll de gerações antigas de GDG        │
│ 22:15  16  EBJHKAUD  → AUDIT.SEQ → BKP.AUDIT.GDG              │
│ 22:30  17  EBJHKREJ  → REJEITOS.SEQ → BKP.REJEITOS.GDG        │
└───────────────────────────────────────────────────────────────┘

──── OFF-CYCLE (sob demanda) ───────────────────────────────────
     EBJREPR    → revalida rejeitos corrigidos
     EBJRPOST   → reinjeta recuperados em EBPOST01
                  (só com STATUS = EOTI, janela ainda aberta)
```

### 3.2. Transições de status (porteiro real da cadeia)

| Job | Exige status | Grava status | Bloqueante |
|---|---|---|---|
| `EBJSOD` | — (ou `CLOSED` do dia D-1) | `OPEN` | sim |
| `EBJPRECK` | `OPEN` | — | sim |
| `EBJBKPD` | `OPEN` | — | sim |
| `EBJWAIT` | `OPEN` | — | sim |
| `EBJLOAD` | `OPEN` | — | sim |
| `EBJCUTF` | `OPEN` | `EOTI` | sim |
| `EBJVALD` | `EOTI` | — | sim |
| `EBJPOST` | `EOTI` | — | sim |
| `EBJACCR` | `EOTI` | — | sim |
| `EBJSNAP` | `EOTI` | — | sim |
| `EBJCONC` | `EOTI` | — | **sim (dia não fecha sem passar)** |
| `EBJCUTE` | `EOTI` | `EOFI` | sim |
| `EBJEXTR` | `EOFI` | — | sim |
| `EBJEOD` | `EOFI` | `CLOSED` | sim |
| `EBJHKGDG` / `EBJHKAUD` / `EBJHKREJ` | `CLOSED` | — | não |
| `EBJREPR` | qualquer | — | não |
| `EBJRPOST` | `EOTI` (precisa janela aberta) | — | condicional |

### 3.3. Mapeamento job atual → proposta

| Atual | Status | Proposta | Ação |
|---|---|---|---|
| `EBJPRECK` | **mantém** | `EBJPRECK` | Tirar o passo `CHKENTR` (passa a ser responsabilidade do `EBJWAIT`). Acrescentar check de `CTL.STATUS=OPEN` |
| `EBJBACKP` | **renomeia + altera** | `EBJBKPD` | Passa a gerar backup em GDG. Mesma fase (SOD), semântica de "backup do dia anterior já fechado" |
| `EBJLOAD` | **refaz** | `EBJLOAD` (real) | Deixa de ser LISTCAT. Passa a copiar o arquivo recebido para `ARQ.ENTRADA.SEQ` catalogado |
| — | **novo** | `EBJSOD` | Grava `CTL.PROCDATE` e `CTL.BRANCH.STATUS=OPEN` |
| — | **novo** | `EBJWAIT` | File-watcher: existe, trailer OK, quantidade bate, hash confere |
| — | **novo** | `EBJCUTF` | Marca `CTL.STATUS=EOTI` |
| `EBJVALD` | **mantém** | `EBJVALD` | Manter o comportamento multi-erro. Remover o trailer `T***` de `VALIDOS`. Padronizar DSN `REJEITOS.SEQ` (plural) |
| `EBJPOST` | **mantém** | `EBJPOST` | Sem mudança funcional. O mesmo JCL serve de base para o `EBJRPOST` |
| — | **novo** | `EBJACCR` | Juros/tarifas (programa `EBACCR01`). Lê `PARM.JUROS.CONFIG`, atualiza `CONTA.KSDS`, grava `ACCR.MOV.SEQ` e append em `LANCTO.ESDS` |
| `EBJSALD` | **repropósito** | `EBJSNAP` | Deixa de ser "query de saldo" e passa a ser "snapshot de fechamento" gerando `SALDO.GDG` do dia. Programa `EBSNAP01` novo; `EBSALD01` **movido** para `cobol/util/` |
| `EBJCONC` | **fortalece** | `EBJCONC` | Expandir `EBCONC01` para conciliação três-vias (lê `ENTRADA`, `VALIDOS`, `REJEITOS`, `LANCTO.ESDS`, `SALDO.GDG`) |
| — | **novo** | `EBJCUTE` | Marca `CTL.STATUS=EOFI` |
| `EBJEXTR` | **reposiciona + corrige** | `EBJEXTR` | Mover para **depois** do `CONC`. Corrigir alocação para GDG de verdade (`ARQ.EXTRATO.GDG(+1)`) |
| `EBJEOD` | **mantém + estende** | `EBJEOD` | Adicionar gravação de `CTL.STATUS=CLOSED`. Ler `SALDO.GDG(0)` e validar contra `CONCIL.SEQ` |
| — | **novo** | `EBJHKGDG`, `EBJHKAUD`, `EBJHKREJ` | Housekeeping tripla |
| `EBJREPR` | **mantém** | `EBJREPR` | Sem mudança |
| — | **novo** | `EBJRPOST` | Reinjeta recuperados em `POST`, fechando o ciclo de rejeito |

---

## 4. Impacto por artefato

### 4.1. COBOL (`cobol/batch/` + `cobol/util/`)

| Programa | Destino | Impacto | Esforço |
|---|---|---|---|
| `EBVALI01` | batch | Remover trailer `T***` de `VALIDOS` (vai para SYSOUT). Padronizar DDNAME `REJEITOS` | S |
| `EBPOST01` | batch | Nenhum no fluxo normal. Já aceita o mesmo contrato do `EBJRPOST` | XS |
| `EBCONC01` | batch | **Refatoração grande.** Passa a ler 5 arquivos e calcular reconciliation três-vias com RC=8 se não bater | M-L |
| `EBEXTR01` | batch | Pequeno: alocação muda para GDG; lógica interna quase igual | S |
| `EBJEOD01` | batch | Grava `CTL.STATUS=CLOSED`, lê snapshot e confirma | S-M |
| `EBREPR01` | batch | Nenhum (continua revalidando) | — |
| `EBSALD01` | **`cobol/util/`** | **Movido.** Documentar como utilitário de consulta manual de saldo no `03-modulos.md` | S (só mover e documentar) |
| `EBSNAP01` | batch (**novo**) | Lê `CONTA.KSDS` sequencial, grava `SALDO.GDG(+1)` com saldo final por conta (agência, conta, saldo, data D) | M |
| `EBACCR01` | batch (**novo**) | Lê `CONTA.KSDS` + `PARM.JUROS.CONFIG`, calcula juros/tarifas por tipo de conta, atualiza `CONTA.KSDS`, grava `ACCR.MOV.SEQ` e append em `LANCTO.ESDS` | M-L |
| `EBCTL01` | batch (**novo**) | Utilitário de status: lê estado atual, valida transição (`OPEN`→`EOTI`→`EOFI`→`CLOSED`), grava novo estado. Usado por `EBJSOD`/`EBJCUTF`/`EBJCUTE`/`EBJEOD` | S |
| `EBCLLOAD` | batch | Fora da cadeia diária (seed), intacto | — |

### 4.2. JCL (`jcl/batch/` + `jcl/util/`)

- **Mantidos intactos:** `EBJREPR.jcl`
- **Alterados:** `EBJPRECK`, `EBJLOAD` (reescrito), `EBJVALD`, `EBJPOST`, `EBJCONC`, `EBJEXTR`, `EBJEOD`
- **Renomeados/repropósito:** `EBJBACKP → EBJBKPD`, `EBJSALD → EBJSNAP`
- **Novos na cadeia:** `EBJSOD`, `EBJWAIT`, `EBJCUTF`, `EBJACCR`, `EBJCUTE`, `EBJRPOST`, `EBJHKGDG`, `EBJHKAUD`, `EBJHKREJ`
- **Movidos para `jcl/util/`:** novo `EBUSALD.jcl` para invocar `EBSALD01` como utilitário

### 4.3. Datasets

| Dataset | Tipo | Status |
|---|---|---|
| `ARQ.ENTRADA.SEQ` | PS | mantido |
| `ARQ.CLIENTE.KSDS` | VSAM KSDS | mantido |
| `ARQ.CONTA.KSDS` | VSAM KSDS | mantido |
| `ARQ.LANCTO.ESDS` | VSAM ESDS | mantido |
| `ARQ.FECHTO.SEQ` | PS | mantido |
| `ARQ.REPR.LANCTO.SEQ` | PS | mantido (agora vira input do `EBJRPOST`) |
| `ARQ.REPR.REJPERM.SEQ` | PS | mantido |
| `ARQ.AUDIT.SEQ` | PS | alterado — passa a ser rotacionado pelo `EBJHKAUD` |
| `ARQ.CONCIL.SEQ` | PS | alterado — novo layout três-vias |
| `ARQ.REJEITO.SEQ` | PS | **renomeado** → `ARQ.REJEITOS.SEQ` |
| `ARQ.CTL.STATUS` | PS | **novo** — status do branch |
| `ARQ.CTL.PROCDATE` | PS | **novo** — data de processamento |
| `ARQ.SALDO.GDG` | GDG | **novo** — snapshot diário |
| `ARQ.EXTRATO.GDG` | GDG | **novo** (substitui `EXTRATO.SEQ`) |
| `ARQ.ACCR.MOV.SEQ` | PS | **novo** — movimentos de accrual |
| `ARQ.ENTRADA.TRAILER.SEQ` | PS | **novo** — manifest do `ENTRADA.SEQ` (hash, count, data) |
| `PARM.JUROS.CONFIG` | PDS | **novo** — parâmetros de juros/tarifas |
| `BKP.CLIENTE.GDG` | GDG | **novo** (substitui `BKP.CLIENTE.SEQ`) |
| `BKP.CONTA.GDG` | GDG | **novo** (substitui `BKP.CONTA.SEQ`) |
| `BKP.AUDIT.GDG` | GDG | **novo** (substitui `BKP.AUDIT.SEQ`) |
| `BKP.REJEITOS.GDG` | GDG | **novo** — arquivamento diário |
| `ARQ.EXTRATO.SEQ` | PS | **descartado** (virou GDG) |
| `BKP.CLIENTE.SEQ` / `BKP.CONTA.SEQ` / `BKP.AUDIT.SEQ` | PS | **descartados** (viram GDG) |
| `ARQ.SALDO.SEQ` | PS | **descartado** do batch — era input do `EBSALD01` (query) |
| `ARQ.SALDO.KSDS` | VSAM KSDS | **descartado** — fantasma no mapa, nenhum JCL/COBOL o usa; saldo autoritativo vive em `CONTA.KSDS.CNT-SALDO` |

### 4.4. EBOPS (`ebops/EBOPS-GUIA-COMPLETO.md` + `ebops.py`)

- A grade batch mostrada no "painel Control-M" passa de **9 jobs** para **17 jobs orquestrados em 9 fases** + 2 off-cycle.
- Os templates de "Simular Normal" / "Simular Falha" precisam ser regenerados para cobrir os novos estados (HOLD em `EBJWAIT`, falha bloqueante em `EBJCONC`, erro em housekeeping, falha de transição de status).
- O mapeamento "tickets ↔ jobs" do EBOPS ganha novos cenários: incidente de *cutoff* não marcado, incidente de GDG cheio, incidente de conciliação três-vias, falha de accrual, falha de `EBJWAIT` por trailer inválido.

### 4.5. Cenários (`scenarios/`)

| Cenário atual | Ação |
|---|---|
| `cenario-01-cadeia-normal` | **Reescrito** com a nova grade (9 → 17 jobs), nova ordem e critérios de sucesso por fase |
| `cenario-02-rejeito-e-reprocessamento` | **Expandido:** agora cobre o ciclo completo `VALD → REJEITOS → REPR → RPOST` |
| `cenario-03-conta-inexistente` | Ajuste mínimo (fases mudam, a essência é a mesma) |
| `cenario-04-arquivo-entrada-ausente` | **Migra do `EBJPRECK` para o `EBJWAIT`** — o porteiro muda de lugar |
| `cenario-05-saldo-negativo` | Mantém, mas o saldo passa a ser conferido no snapshot |
| **Novos cenários** | `06-conciliacao-bloqueia-extrato`, `07-cutoff-nao-marcado`, `08-gdg-cheio`, `09-backup-dia-anterior-ausente`, `10-accrual-com-parametro-invalido` |

### 4.6. Runbooks (`docs/06-runbooks.md`)

- **Atualizar:** runbook de *arquivo de entrada ausente* (agora `EBJWAIT` em vez de `EBJLOAD`).
- **Atualizar:** runbook de *restauração de backup* (backups agora são GDG — muda o comando de restore).
- **Novos:** runbook de *cutoff não marcado*, *conciliação bloqueia dia*, *accrual com parâmetro inválido*, *GDG cheio*, *trailer inconsistente*.

### 4.7. Documentação (`docs/`)

- `05-grade-batch.md` → **reescrito** (fonte da verdade da nova cadeia, com horários e status)
- `04-mapa-datasets.md` → novos datasets, GDGs, remoção do `ARQ.SALDO.KSDS`
- `03-modulos.md` → documentar `EBSNAP01`, `EBACCR01`, `EBCTL01`, e `EBSALD01` como utilitário
- `06-runbooks.md` → conforme §4.6
- `mapa-emunah-bank-lab.html` → regerar o painel visual

---

## 5. Plano de migração em fases (branch `refactor/cadeia-batch`)

Fazer tudo de uma vez é convite a quebra. Cada onda é um PR separado. `main` nunca fica quebrada.

| Onda | Escopo | Reversível? |
|---|---|---|
| **Onda 0** | Correções baratas de inconsistência: `REJEITOS.SEQ` padronizado, `EBEXTR` passa a usar GDG, trailer `T***` sai de `VALIDOS` | Sim |
| **Onda 1** | Reordenar: mover `EBJCONC` antes de `EBJEXTR`. Refatorar `EBCONC01` para três-vias | Sim |
| **Onda 2** | Introduzir controle de status: `EBJSOD`, `EBJCUTF`, `EBJCUTE`, `EBCTL01`, `CTL.STATUS`, `CTL.PROCDATE`. `EBJEOD` passa a gravar `CLOSED` | Sim |
| **Onda 3** | Refazer `EBJLOAD` (carga real) e introduzir `EBJWAIT` com trailer. Retirar `CHKENTR` do `EBJPRECK`. `ARQ.ENTRADA.TRAILER.SEQ` | Sim, mas cenário `04` precisa mudar junto |
| **Onda 4** | Repropósito `EBJSALD` → `EBJSNAP` (programa `EBSNAP01`). Mover `EBSALD01` para `cobol/util/`. Criar `SALDO.GDG` | Parcialmente |
| **Onda 5** | Introduzir `EBJACCR` + `EBACCR01` + `PARM.JUROS.CONFIG` + `ACCR.MOV.SEQ` | Sim |
| **Onda 6** | Fechar ciclo de rejeito: `EBJRPOST` | Sim |
| **Onda 7** | Housekeeping: `EBJHKGDG`, `EBJHKAUD`, `EBJHKREJ`. Backups em GDG (`EBJBKPD` já com `BKP.*.GDG`) | Sim |
| **Onda 8** | Regerar EBOPS, cenários (incluindo 5 novos), mapa HTML, runbooks, `03-modulos.md`, `05-grade-batch.md`. Adicionar `case-007` no `change-log` | — |

---

## 6. Decisões tomadas

| Tema | Decisão |
|---|---|
| Nome da branch | `refactor/cadeia-batch` |
| Nomenclatura dos novos jobs | Confirmada (`EBJSOD`, `EBJWAIT`, `EBJCUTF`, `EBJCUTE`, `EBJACCR`, `EBJSNAP`, `EBJBKPD`, `EBJRPOST`, `EBJHK*`) |
| Padronização de rejeito | `REJEITOS.SEQ` (plural) em todos os artefatos |
| `EBSALD01` | Movido para `cobol/util/`, documentado como utilitário de consulta manual |
| `EBJACCR` | **Criado já nesta rodada** (não é hook) |
| Scheduler | `ARQ.CTL.STATUS` é *source of truth*. Horários viram sugestão de janela |
| Backup | `EBJBKPD` gera em GDG (`BKP.*.GDG`). Runbook de restore precisa ser atualizado |
| Meta de fidelidade | Máxima proximidade possível com produção bancária real |
| `case-007` | Eliel vai adicionar ao `change-log` depois |

### Pendências

Nenhuma. Todas as decisões foram tomadas.

---

## 7. Checklist antes de abrir a branch

- [x] Validar as 5 decisões pendentes com o Eliel
- [x] Confirmar nomenclatura dos novos jobs
- [x] Confirmar padronização `REJEITOS.SEQ`
- [x] Definir nome da branch: `refactor/cadeia-batch`
- [x] Resolver status do `ARQ.SALDO.KSDS` (decidido: descartar)
- [x] Abrir branch `refactor/cadeia-batch` a partir de `main`
- [ ] Abrir um case por onda (0 a 8) em `docs/change-log/` — começando pelo `case-007` de abertura do redesenho

---

## 8. Grau de confiança

- **Alto:** os achados de §2.1 (LOAD duplicado, SALD não consolida, CONC simples, EXTR antes de CONC, ciclo de rejeito aberto, `REJEITO` vs `REJEITOS`, trailer `T***`, `SALDO.KSDS` órfão) são **fatos** lidos no código.
- **Alto:** as fases canônicas de banco real (SOD/EOTI/posting/accrual/snapshot/recon/EOFI/output/EOD/housekeeping) são **padrão amplamente documentado** em FLEXCUBE e literatura de EOD.
- **Alto:** a adequação ao lab é coerente com a escolha explícita do Eliel de buscar máxima proximidade com produção real — `EBJACCR`, `EBJWAIT` robusto e `CTL.STATUS` como *source of truth* são consequência direta dessa escolha.
- **Baixo:** estimativa de dias/esforço das ondas — não estimei.

# Fluxo da Cadeia Batch — EMUNAH BANK LAB

Documento de passagem: descreve, passo a passo, o que cada job faz, quem escreve em `CTL.STATUS`, quais datasets são lidos/gravados e quais jobs ficam fora da cadeia automática.

---

## Revisão dos passos iniciais

### 1. Start of Day

O `EBJSOD` **só grava `OPEN`** em `ARQ.CTL.STATUS`. Os outros valores (`EOTI`, `EOFI`, `CLOSED`) são gravados em jobs posteriores:

| Valor    | Gravado por |
|----------|-------------|
| `OPEN`   | `EBJSOD`    |
| `EOTI`   | `EBJCUTF`   |
| `EOFI`   | `EBJCUTE`   |
| `CLOSED` | `EBJEOD`    |

A data em `ARQ.CTL.PROCDATE` é gravada aqui, também pelo `EBJSOD`.

---

### 2. Backup

Executado pelo `EBJBCKPD` (renomeado a partir do antigo `EBJBACKP` na Onda 7 do redesenho).

Os DSN corretos são `BKP.CONTA.GDG`, `BKP.CLIENTE.GDG`, `BKP.AUDIT.GDG` — **sem** o `ARQ.` na frente. O prefixo `ARQ.` era o bug que o `EBFIXBKP` corrigiu.

```
2. BACKUP — EBJBCKPD faz snapshot do estado atual
   a) ARQ.CONTA.KSDS    -> BKP.CONTA.GDG(+1)    via REPRO
   b) ARQ.CLIENTE.KSDS  -> BKP.CLIENTE.GDG(+1)  via REPRO
   c) ARQ.AUDIT.SEQ     -> BKP.AUDIT.GDG(+1)    via IEBGENER
```

---

### 3. Chegada do arquivo — file watcher e staging

Três pontos de atenção:

- O `EBJPRECK` é o **primeiro** job da cadeia, **não** parte da etapa de staging. Ele roda **antes** do `EBJSOD`, para garantir que o ciclo anterior fechou (`CTL.STATUS=CLOSED`) e que o ambiente está saudável.
- O `EBJWAIT` observa `STAGE.ENTRADA.SEQ`, **não** `ARQ.ENTRADA.SEQ`. O arquivo do dia chega primeiro no STAGE (zona de recebimento) e só vira `ARQ.ENTRADA.SEQ` depois do `EBJLOAD`.
- Validação de trailer/hash é **futuro**. Hoje o `EBJWAIT` só faz duas verificações: `CHKEXST` (existe no catálogo) e `CHKCNT` (tem pelo menos 1 registro, via ICETOOL). Trailer com contagem e hash é um projeto para a Onda 5/6, quando entrar o programa `EBWAIT01`.

Ordem correta:

```
0. EBJPRECK — primeiro de tudo:
   - confirma que CTL.STATUS = CLOSED (ou vazio)
   - confirma que bibliotecas e datasets obrigatórios existem

1. EBJSOD — abre o dia

2. EBJBCKPD — backup

3. FILE WATCHER E STAGING
   a) EBJWAIT observa STAGE.ENTRADA.SEQ:
      - CHKEXST: dataset existe no catálogo (LISTCAT)
      - CHKCNT:  não está vazio (ICETOOL COUNT NOEMPTY)
      - (futuro) trailer com contagem e hash

   b) EBJLOAD faz a promoção:
      - IEBGENER de STAGE.ENTRADA.SEQ -> ARQ.ENTRADA.SEQ
      - arquivo oficialmente aceito na cadeia operacional
```

---

## Continuação do fluxo (passos 4 → 13)

### 4. Validação — `EBJVALD`

Executa `EBVALI01`. Lê `ARQ.ENTRADA.SEQ` e valida cada registro:

- layout de 120 bytes
- conta existente em `ARQ.CONTA.KSDS`
- tipo de lançamento válido (C/D)
- valor positivo
- data no padrão

**Saídas:**

- registros aprovados → `ARQ.LANCTO.ESDS` (append)
- registros rejeitados → `ARQ.REJEITOS.SEQ`
- trilha → `ARQ.AUDIT.SEQ`

Regra de bloqueio: excesso de rejeitos pode abortar a cadeia.

---

### 5. Postagem — `EBJPOST`

Executa `EBPOST01`. Lê `ARQ.LANCTO.ESDS` (os válidos) e aplica nas contas:

- atualiza saldo em `ARQ.CONTA.KSDS` (READ + UPDATE direto no KSDS)
- grava trilha em `ARQ.AUDIT.SEQ`
- falha em conta específica vira rejeito em `ARQ.REJEITOS.SEQ` (ex.: conta bloqueada)

Este é o ponto em que o dinheiro "entra" nas contas.

---

### 6. Cutoff Financeiro — `EBJCUTF`

Fecha a janela de postagem. Grava `CTL.STATUS=EOTI` em `ARQ.CTL.STATUS`.

A partir daqui:

- nenhuma postagem transacional é mais aceita no dia
- começa a fase contábil (accruals, snapshot)

---

### 7. Accruals — `EBACCR01`

Programa; pode ter JCL próprio no futuro.

Lê `PARM.JUROS.CONFIG` (PDS com taxas/tarifas/datas-base). Varre `ARQ.CONTA.KSDS` e gera movimentos de juros e tarifas em `ARQ.ACCR.MOV.SEQ`.

Hoje é só geração — a aplicação dos accruals no saldo pode ser feita por um `EBJRPOST`-like ou embutida depois, conforme evolução.

---

### 8. Snapshot de Saldo — `EBJSNAP`

Executa `EBSNAP01`. Varre `ARQ.CONTA.KSDS` inteira e escreve o saldo consolidado de cada conta em `ARQ.SALDO.GDG(+1)`.

Cada execução cria uma **nova geração** — histórico diário versionado. Substitui o antigo `SALDO.KSDS` (que foi descartado).

---

### 9. Cutoff Contábil — `EBJCUTE`

Grava `CTL.STATUS=EOFI` em `ARQ.CTL.STATUS`. Snapshot está fechado; dia pronto para conciliação.

---

### 10. Conciliação Three-Way — `EBJCONC`

Executa `EBCONC01`. Produz `ARQ.CONCIL.SEQ` (LRECL=132) com três seções independentes:

| Seção | O que compara |
|-------|---------------|
| S1    | total de `ARQ.ENTRADA.SEQ` vs soma(válidos em `LANCTO.ESDS`) + soma(rejeitos em `REJEITOS.SEQ`) |
| S2    | total de `LANCTO.ESDS` vs soma efetivamente aplicada em `AUDIT.SEQ` |
| S3    | saldo inicial (geração anterior de `SALDO.GDG`) + líquido dos movimentos vs saldo final (geração atual de `SALDO.GDG`) |

Cada linha termina com `OK` ou `DIVERGENTE`. **Qualquer `DIVERGENTE` bloqueia o fechamento.**

---

### 11. Extrato — `EBJEXTR`

Executa `EBEXTR01`. Consolida movimentos do dia (`LANCTO.ESDS`) com o saldo final (`SALDO.GDG`) e gera nova geração em `ARQ.EXTRATO.GDG(+1)`. É o produto visível do dia.

---

### 12. Fechamento — `EBJEOD`

Executa `EBJEOD01`. Último passo da cadeia principal:

- verifica que conciliação fechou sem `DIVERGENTE`
- grava `CTL.STATUS=CLOSED` em `ARQ.CTL.STATUS`
- finaliza trilha de auditoria do dia

---

### 13. Off-cycle (fora da cadeia automática)

Rodam sob demanda, quando operação decide:

- **`EBJREPR`** — executa `EBREPR01` para preparar `ARQ.REPR.LANCTO.SEQ` a partir de rejeitos corrigidos
- **`EBJRPOST`** — reutiliza `EBPOST01` lendo `REPR.LANCTO.SEQ` em vez de `ENTRADA.SEQ`
- **`EBJHKGDG`** — monitor passivo; `LISTCAT` das 6 bases GDG
- **`EBJHKAUD`** — arquiva `ARQ.AUDIT.SEQ` em `BKP.AUDIT.GDG(+1)`, deleta, realoca vazio
- **`EBJHKREJ`** — idem para `ARQ.REJEITOS.SEQ`

---

## Fluxo consolidado (cronológico)

```
EBJPRECK  -> lê CTL.STATUS=CLOSED e valida ambiente
EBJSOD    -> grava CTL.STATUS=OPEN + CTL.PROCDATE
EBJBCKPD  -> backup CLIENTE/CONTA/AUDIT em GDG
EBJWAIT   -> observa STAGE.ENTRADA.SEQ (existe + não vazio)
EBJLOAD   -> STAGE.ENTRADA.SEQ -> ARQ.ENTRADA.SEQ
EBJVALD   -> valida; gera LANCTO.ESDS + REJEITOS.SEQ
EBJPOST   -> aplica saldo em CONTA.KSDS
EBJCUTF   -> grava CTL.STATUS=EOTI
(EBACCR01)-> gera ACCR.MOV.SEQ
EBJSNAP   -> grava SALDO.GDG(+1)
EBJCUTE   -> grava CTL.STATUS=EOFI
EBJCONC   -> grava CONCIL.SEQ (3 seções)
EBJEXTR   -> grava EXTRATO.GDG(+1)
EBJEOD    -> valida CONCIL; grava CTL.STATUS=CLOSED
```

---

## As três chaves mentais

1. **CTL.STATUS é um portão, não um registro passivo.** Cada transição é um commit de fase.
2. **ARQ é o mundo operacional do dia; BKP é histórico versionado; STAGE é zona de recebimento antes de virar `ARQ`.**
3. **Three-way conciliation é o último portão antes do fechamento.** Se as três seções não baterem, o dia não fecha.

Se a cadeia fluir assim sem intervenção, o dia está "verde". Qualquer parada cai no runbook correspondente em [`docs/06-runbooks.md`](06-runbooks.md).

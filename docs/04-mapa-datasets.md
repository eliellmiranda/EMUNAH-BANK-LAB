# [04] - MAPA DE DATASETS - EMUNAH BANK LAB

## Convenção de Nomenclatura

Todos os datasets seguem o padrão:
<HLQ>.EMUNAH.< CATEGORIA >.< FUNÇÃO >

- **HLQ:** `<HLQ>` (userid no zXplore)
- **PROJETO:** `EMUNAH`
- **CATEGORIAS:**
  - `DEV`, `HML`, `PRD` — bibliotecas por ambiente
  - `ARQ` — arquivos operacionais do dia
  - `BKP` — backups e históricos versionados
  - `STAGE` — staging (antes de entrar em ARQ)
  - `PARM` — parâmetros e configuração
  - `SEED` — massa de carga inicial

---

## Bibliotecas de Desenvolvimento (DEV)

| Dataset                      | Tipo     | Membros principais                                              | Finalidade                            |
|------------------------------|----------|-----------------------------------------------------------------|---------------------------------------|
| `<HLQ>.EMUNAH.DEV.COBOL`    | PDS/PDSE | EBCLLOAD, EBVALI01, EBPOST01, EBACCR01, EBSNAP01, EBCONC01, EBEXTR01, EBREPR01, EBCTL01, EBJEOD01, EBSALD01 | Fontes COBOL de desenvolvimento |
| `<HLQ>.EMUNAH.DEV.COPY`     | PDS/PDSE | CPCLI001, CPCNT001, CPLCT001, CPAUD001, CPSLD001, CPACR001, CPCTL001 | Copybooks e layouts de registro |
| `<HLQ>.EMUNAH.DEV.JCL`      | PDS/PDSE | EBALLOC, EBALLOC2, EBDEFGDG, EBDEPLOY, EBJPRECK, EBJSOD, EBJBCKPD, EBJWAIT, EBJLOAD, EBJVALD, EBJPOST, EBJCUTF, EBJSNAP, EBJCUTE, EBJCONC, EBJEXTR, EBJEOD, EBJREPR, EBJRPOST, EBJHKGDG, EBJHKAUD, EBJHKREJ, EBJCLLD, EBSEED, EBLISTDS, EBRESET | JCLs de alocação, cadeia batch e utilidades |
| `<HLQ>.EMUNAH.DEV.REXX`     | PDS/PDSE | Scripts utilitários                                             | Scripts REXX e automações             |
| `<HLQ>.EMUNAH.DEV.LOADLIB`  | PDS/PDSE | Load modules compilados                                         | Executáveis gerados no build DEV      |

---

## Bibliotecas de Homologação (HML)

| Dataset                      | Tipo     | Finalidade                              |
|------------------------------|----------|-----------------------------------------|
| `<HLQ>.EMUNAH.HML.COBOL`    | PDS/PDSE | Fontes promovidos de DEV para HML       |
| `<HLQ>.EMUNAH.HML.JCL`      | PDS/PDSE | JCLs de execução em HML                 |
| `<HLQ>.EMUNAH.HML.LOADLIB`  | PDS/PDSE | Executáveis compilados em HML           |

---

## Bibliotecas de Produção Simulada (PRD)

| Dataset                      | Tipo     | Finalidade                              |
|------------------------------|----------|-----------------------------------------|
| `<HLQ>.EMUNAH.PRD.JCL`      | PDS/PDSE | JCLs de execução em PRD                 |
| `<HLQ>.EMUNAH.PRD.LOADLIB`  | PDS/PDSE | Executáveis de produção                 |
| `<HLQ>.EMUNAH.PRD.PARMLIB`  | PDS/PDSE | Parâmetros e membros de configuração    |

---

## Arquivos Operacionais (ARQ)

Datasets do dia corrente. O ciclo bate todos os dias sobre estes datasets.

### VSAM

| Dataset                         | Tipo | Org. | DDNAME    | Finalidade                                     |
|---------------------------------|------|------|-----------|------------------------------------------------|
| `<HLQ>.EMUNAH.ARQ.CLIENTE.KSDS` | VSAM | KSDS | `CLIENTE` | Cadastro master de clientes (chave: nº cliente) |
| `<HLQ>.EMUNAH.ARQ.CONTA.KSDS`   | VSAM | KSDS | `CONTA`   | Cadastro master de contas (chave: nº conta)    |
| `<HLQ>.EMUNAH.ARQ.LANCTO.ESDS`  | VSAM | ESDS | `VALIDOS` | Lançamentos aprovados (append-only, imutável)  |

### Sequenciais — entrada e trilhas

| Dataset                                    | LRECL | DDNAME       | Finalidade                                                |
|--------------------------------------------|-------|--------------|-----------------------------------------------------------|
| `<HLQ>.EMUNAH.ARQ.ENTRADA.SEQ`             | 120   | `ENTRADA`    | Arquivo do dia aceito para processamento                  |
| `<HLQ>.EMUNAH.ARQ.ENTRADA.TRAILER.SEQ`     | 80    | `TRAILER`    | Trailer/hash do arquivo de entrada (futuro)               |
| `<HLQ>.EMUNAH.ARQ.REJEITOS.SEQ`            | 120   | `REJEITOS`   | Registros rejeitados na validação ou aplicação            |
| `<HLQ>.EMUNAH.ARQ.AUDIT.SEQ`               | 120   | `AUDIT`      | Trilha de auditoria do dia — arquivada via `EBJHKAUD`     |
| `<HLQ>.EMUNAH.ARQ.CONCIL.SEQ`              | 132   | `CONCIL`     | Relatório de conciliação three-way (três seções)          |
| `<HLQ>.EMUNAH.ARQ.REPR.LANCTO.SEQ`         | 120   | `MOVTIN`     | Lançamentos reprocessados, consumidos por `EBJRPOST`      |
| `<HLQ>.EMUNAH.ARQ.ACCR.MOV.SEQ`            | 120   | `ACCROUT`   | Movimentos de accrual (juros e tarifas)                   |

### Sequenciais — controle

| Dataset                              | LRECL | Finalidade                                             |
|--------------------------------------|-------|--------------------------------------------------------|
| `<HLQ>.EMUNAH.ARQ.CTL.STATUS`        | 80    | Estado atual do ciclo (`OPEN`/`EOTI`/`EOFI`/`CLOSED`)  |
| `<HLQ>.EMUNAH.ARQ.CTL.PROCDATE`      | 80    | Data de processamento do ciclo atual                   |

### GDGs operacionais

| Dataset                         | Tipo     | Finalidade                                                |
|---------------------------------|----------|-----------------------------------------------------------|
| `<HLQ>.EMUNAH.ARQ.EXTRATO.GDG`  | GDG Base | Histórico de extratos por geração (`EBJEXTR`)             |
| `<HLQ>.EMUNAH.ARQ.SALDO.GDG`    | GDG Base | Snapshot diário de saldo (`EBJSNAP`)                      |

---

## Layout — `CONCIL.SEQ` (LRECL=132)

| Posição   | Campo         | Descrição                                              |
|-----------|---------------|--------------------------------------------------------|
| 1–3       | TIPO-REG      | `H11`/`D11..14`/`R11` = seção 1; `H21`/`D21..22`/`R21` = seção 2; `H31`/`D31..34`/`R31` = seção 3; `T98`, `T99` = trailers |
| 4         | FILLER        | —                                                      |
| 5–54      | DESCRICAO     | 50 chars                                               |
| 55        | FILLER        | —                                                      |
| 56–70     | VALOR         | 15 chars (PIC `-Z(10)9,99`)                            |
| 71–75     | FILLER        | —                                                      |
| 76–125    | STATUS        | 50 chars — `OK`, `DIVERGENTE`, timestamps              |
| 126–132   | FILLER        | —                                                      |

Seções: **S1** entrada vs válidos+rejeitos · **S2** válidos vs postados · **S3** saldo inicial + líquidos vs saldo final.

---

## Backups e Históricos (BKP)

| Dataset                              | Tipo     | Alimentado por | Finalidade                                  |
|--------------------------------------|----------|----------------|---------------------------------------------|
| `<HLQ>.EMUNAH.BKP.CLIENTE.GDG`       | GDG Base | `EBJBCKPD`     | Backup pré-batch do `CLIENTE.KSDS`          |
| `<HLQ>.EMUNAH.BKP.CONTA.GDG`         | GDG Base | `EBJBCKPD`     | Backup pré-batch do `CONTA.KSDS`            |
| `<HLQ>.EMUNAH.BKP.AUDIT.GDG`         | GDG Base | `EBJBCKPD`, `EBJHKAUD` | Histórico de trilhas de auditoria    |
| `<HLQ>.EMUNAH.BKP.REJEITOS.GDG`      | GDG Base | `EBJHKREJ`     | Histórico de rejeitos arquivados            |

---

## Staging (STAGE)

| Dataset                               | LRECL | Finalidade                                                |
|---------------------------------------|-------|-----------------------------------------------------------|
| `<HLQ>.EMUNAH.STAGE.ENTRADA.SEQ`      | 120   | Arquivo do dia recebido, aguardando promoção para ARQ     |

Promovido para `ARQ.ENTRADA.SEQ` pelo `EBJLOAD` após validação do `EBJWAIT`.

---

## Parâmetros (PARM)

| Dataset                              | Tipo     | Finalidade                                      |
|--------------------------------------|----------|-------------------------------------------------|
| `<HLQ>.EMUNAH.PARM.JUROS.CONFIG`     | PDS      | Taxas, tarifas e datas-base consumidas por `EBACCR01` |

---

## Arquivos de Seed (Carga Inicial)

Massa real para população inicial dos VSAM via `EBJCLLD` (executa `EBCLLOAD`).

| Dataset                           | DDNAME     | Registros | Finalidade                        |
|-----------------------------------|------------|-----------|-----------------------------------|
| `<HLQ>.EMUNAH.SEED.CLIENTES.SEQ`  | `CLIENTIN` | 20        | Massa inicial de clientes         |
| `<HLQ>.EMUNAH.SEED.CONTAS.SEQ`    | `CONTAIN`  | 40        | Massa inicial de contas (2/cliente) |

---

## Mapa Visual

O arquivo [`mapa-emunah-bank-lab.html`](mapa-emunah-bank-lab.html) consolida os datasets acima em um painel interativo navegável com abas por categoria.

---

## Observações

- `ARQ.LANCTO.ESDS` usa organização ESDS por design — histórico imutável de movimentos aprovados do dia
- Não existe mais `ARQ.SALDO.KSDS`. O saldo consolidado é versionado em `ARQ.SALDO.GDG`
- `ARQ.AUDIT.SEQ` e `ARQ.REJEITOS.SEQ` são sequenciais de curta vida útil: housekeeping arquiva e recria vazios
- GDGs herdam DCB de `MODEL.DSCB` e devem ser definidos antes do primeiro uso (`EBDEFGDG`)
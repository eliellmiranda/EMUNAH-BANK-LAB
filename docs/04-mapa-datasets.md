# [04] - MAPA DE DATASETS - EMUNAH BANK LAB

## Convenção de Nomenclatura

Todos os datasets seguem o padrão corporativo:
`<HLQ>.EMUNAH.<CATEGORIA>.<FUNÇÃO>`

- **HLQ:** Userid no zXplore (ex: Z77948).
- **PROJETO:** `EMUNAH`.
- **CATEGORIAS:**
  - `DEV`, `HML`, `PRD` — Ambientes de ciclo de vida.
  - `ARQ` — Ficheiros operacionais e transacionais do dia.
  - `BKP` — Backups e históricos versionados via GDG.
  - `STAGE` — Área de recepção externa (Staging).
  - `PARM` — Tabelas de parâmetros e configuração de negócio.
  - `SEED` — Massa de dados para carga inicial.

---

## Bibliotecas de Desenvolvimento (DEV)

| Dataset | Tipo | Conteúdo Principal | Finalidade |
| :--- | :--- | :--- | :--- |
| `<HLQ>.EMUNAH.DEV.COBOL` | PDSE | `EBVALI01`, `EBPOST01`, `EBCSSLD`, `EBCSEXT` | Fontes Batch, Online e Subprogramas. |
| `<HLQ>.EMUNAH.DEV.COPY` | PDSE | `CPCLI001`, `CPCNT001`, `EBMSLD` (Mapas) | Copybooks, DCLGEN e Mapas BMS. |
| `<HLQ>.EMUNAH.DEV.JCL` | PDSE | `EBJPRECK`, `EBJCLOSE`, `EBJWAIT`, `EBJEOD` | JCLs de alocação, build e cadeia batch. |
| `<HLQ>.EMUNAH.DEV.REXX` | PDSE | `EBCHKLAB`, `EBRESET` | Scripts de automação e utilitários TSO. |
| `<HLQ>.EMUNAH.DEV.LOADLIB` | PDSE | Módulos Executáveis | Binários gerados no ambiente de desenvolvimento. |

---

## Bibliotecas de Produção Simulada (PRD)

| Dataset | Tipo | Finalidade |
| :--- | :--- | :--- |
| `<HLQ>.EMUNAH.PRD.JCL` | PDSE | JCLs estáveis da cadeia batch oficial. |
| `<HLQ>.EMUNAH.PRD.LOADLIB` | PDSE | Binários homologados para execução core. |
| `<HLQ>.EMUNAH.PRD.PARMLIB` | PDSE | Configurações de juros, tarifas e regras de negócio. |

---

## Arquivos Operacionais (ARQ)

Estes ficheiros representam o estado atual do banco. O processamento online e batch ocorre diretamente sobre eles.

### Core Transacional (VSAM)

| Dataset | Tipo | Org. | DDNAME | Papel no Sistema |
| :--- | :--- | :--- | :--- | :--- |
| `<HLQ>.EMUNAH.ARQ.CLIENTE.KSDS` | VSAM | KSDS | `CLIENTE` | Cadastro mestre de correntistas. |
| `<HLQ>.EMUNAH.ARQ.CONTA.KSDS` | VSAM | KSDS | `CONTA` | Saldos, limites e status financeiro. |
| `<HLQ>.EMUNAH.ARQ.LANCTO.ESDS` | VSAM | ESDS | `LANCTIN` | Livro-razão histórico do dia (imutável). |

### Dados Satélite e Auditoria (DB2)

| Objeto | Tipo | Finalidade |
| :--- | :--- | :--- |
| `TB_AUDITORIA` | Tabela | Repositório relacional de trilhas de auditoria (via SQL). |

### Sequenciais — Entrada e Trilhas Batch

| Dataset | LRECL | DDNAME | Finalidade |
| :--- | :--- | :--- | :--- |
| `<HLQ>.EMUNAH.ARQ.ENTRADA.SEQ` | 120 | `ENTRADA` | Ficheiro do dia promovido para processamento. |
| `<HLQ>.EMUNAH.ARQ.REJEITOS.SEQ` | 150 | `REJEITOS` | Transações inválidas (Layout `CPREJ001`). |
| `<HLQ>.EMUNAH.ARQ.AUDIT.SEQ` | 120 | `AUDIT` | Trilha de log sequencial pré-arquivamento. |
| `<HLQ>.EMUNAH.ARQ.CONCIL.SEQ` | 132 | `CONCIL` | Relatório de conciliação Three-way. |
| `<HLQ>.EMUNAH.ARQ.ACCR.MOV.SEQ` | 120 | `ACCROUT` | Lançamentos contábeis automáticos (Juros/Taxas). |

### Sequenciais — Controle da Máquina de Estados

| Dataset | LRECL | Conteúdo | Finalidade |
| :--- | :--- | :--- | :--- |
| `<HLQ>.EMUNAH.ARQ.CTL.STATUS` | 80 | Phase Name | Governa o ciclo (`OPEN`/`EOTI`/`EOFI`/`CLOSED`). |
| `<HLQ>.EMUNAH.ARQ.CTL.PROCDATE`| 80 | YYYYMMDD | Define a data lógica de processamento do banco. |

---

## Layout — `CONCIL.SEQ` (LRECL=132)

Este ficheiro é a base para o controle de integridade financeira do dia.

| Posição | Campo | Descrição |
| :--- | :--- | :--- |
| 1–3 | `TIPO-REG` | Identificador da seção (`H11`, `D21`, `T99`, etc). |
| 5–54 | `DESCRICAO` | Descrição amigável do cheque de conciliação. |
| 56–70 | `VALOR` | Valor monetário formatado para conferência. |
| 76–125 | `STATUS` | Resultado do cheque (`OK` ou `DIVERGENTE`). |

**Seções:** **S1** (Entrada *vs.* Válidos+Rejeitos); **S2** (Válidos *vs.* Postados); **S3** (Saldo Anterior + Movimentos *vs.* Saldo Final).

---

## Backups e Históricos (BKP/GDG)

O laboratório utiliza o modelo de Gerações (GDG) para manter a rastreabilidade histórica.

| Dataset | Tipo | Origem | Retenção | Finalidade |
| :--- | :--- | :--- | :--- | :--- |
| `<HLQ>.EMUNAH.BKP.CLIENTE.GDG` | GDG | `EBJBCKPD` | 7 dias | Cópia de segurança pré-batch. |
| `<HLQ>.EMUNAH.BKP.CONTA.GDG` | GDG | `EBJBCKPD` | 7 dias | Cópia de segurança pré-batch. |
| `<HLQ>.EMUNAH.ARQ.SALDO.GDG` | GDG | `EBJSNAP` | 30 dias | Snapshot diário consolidado (Substitui KSDS). |
| `<HLQ>.EMUNAH.ARQ.EXTRATO.GDG` | GDG | `EBJEXTR` | 30 dias | Ficheiros de extratos emitidos para clientes. |
| `<HLQ>.EMUNAH.BKP.AUDIT.GDG` | GDG | `EBJHKAUD` | 90 dias | Arquivo morto de trilhas de auditoria. |

---

## Áreas de Intermediação e Staging

| Dataset | LRECL | Papel |
| :--- | :--- | :--- |
| `<HLQ>.EMUNAH.STAGE.ENTRADA.SEQ` | 120 | Recepção de ficheiros locais via Zowe CLI. |
| `<HLQ>.EMUNAH.SEED.CLIENTES.SEQ` | 80 | Massa bruta para carga inicial (Bootstrap). |

---

## Observações Arquiteturais

1. **Abandono do `SALDO.KSDS`:** O saldo oficial consolidado é agora versionado exclusivamente em `ARQ.SALDO.GDG`. Isso garante que o fechamento (`CLOSED`) tenha um ponto de recuperação imutável.
2. **Imutabilidade do `LANCTO.ESDS`:** Registros aprovados não podem ser alterados ou deletados, apenas consultados pelo Online ou pelo job de extratos.
3. **Isolamento de Auditoria:** O `AUDIT.SEQ` ativo é resetado pelo housekeeping (`EBJHKAUD`) somente após a confirmação de arquivamento no respectivo GDG, prevenindo perda de trilha.
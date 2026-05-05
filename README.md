# 🏦 Emunah Bank Lab

![z/OS](https://img.shields.io/badge/z%2FOS-IBM%20zXplore-blue?style=flat-square&logo=ibm)
![COBOL](https://img.shields.io/badge/COBOL-85%2F2002-lightgrey?style=flat-square)
![CICS](https://img.shields.io/badge/CICS-TS-darkred?style=flat-square)
![JCL](https://img.shields.io/badge/JCL-batch-orange?style=flat-square)
![Zowe](https://img.shields.io/badge/Zowe-CLI%20%2F%20Explorer-green?style=flat-square)
![VSAM](https://img.shields.io/badge/VSAM-KSDS%20%2F%20ESDS-yellow?style=flat-square)
![GDG](https://img.shields.io/badge/GDG-generations-lightgrey?style=flat-square)
![DB2](https://img.shields.io/badge/DB2-z%2FOS-blue?style=flat-square&logo=ibm)
![REXX](https://img.shields.io/badge/REXX-automation-purple?style=flat-square)
![TSO/ISPF](https://img.shields.io/badge/TSO%2FISPF-terminal-lightblue?style=flat-square)
![EBOPS](https://img.shields.io/badge/EBOPS-simulator-red?style=flat-square)
![Status](https://img.shields.io/badge/status-em%20desenvolvimento-brightgreen?style=flat-square)

> Ambiente pessoal de simulação bancária mainframe com foco em desenvolvimento COBOL, processamento batch, investigação de falhas e integração via Zowe e TN3270.

---

## Sobre o laboratório

O **Emunah Bank Lab** replica, de forma controlada, os padrões operacionais de instituições financeiras que sustentam seus sistemas críticos em mainframe. A cadeia foi redesenhada (branch `refactor/cadeia-batch`) para refletir o ciclo canônico de core-banking — inspirado em FLEXCUBE — e cobre o dia inteiro do processamento bancário batch: Start of Day, backup, file-watcher, carga, validação, postagem, accrual, cutoff financeiro (`EOTI`), snapshot de saldo em GDG, cutoff contábil (`EOFI`), conciliação three-way bloqueante, extrato e fechamento (`CLOSED`), com cadeia de housekeeping mantendo o ambiente estável entre dias e ciclo de reprocessamento de rejeitos fora da janela oficial.

O dataset `ARQ.CTL.STATUS` é a *source of truth* da cadeia — horários são apenas sugestão de janela.

O nome *Emunah* (אֱמוּנָה) remete ao conceito hebraico de fidelidade e confiança — qualidades centrais tanto no setor bancário quanto nos sistemas mainframe, conhecidos por décadas de disponibilidade ininterrupta.

---

## Arquitetura

```text
┌─────────────────────────────────────────────────────────────┐
│                     CAMADA LOCAL                            │
│  VS Code + Zowe Explorer + Git                              │
│  .cbl  .jcl  .cpy  .rexx  /data  /docs                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
              Zowe CLI / Explorer
          (upload, submit, spool, fetch)
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                  CAMADA REMOTA                              │
│           IBM zXplore — z/OS                                │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  DEV        │  │  HML        │  │  PRD (simulado)     │  │
│  │  .COBOL     │  │  .COBOL     │  │  .JCL               │  │
│  │  .COPY      │  │  .JCL       │  │  .LOADLIB           │  │
│  │  .JCL       │  │  .LOADLIB   │  │  .PARMLIB           │  │
│  │  .REXX      │  └─────────────┘  └─────────────────────┘  │
│  │  .LOADLIB   │                                            │
│  └─────────────┘                                            │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Arquivos Operacionais (ARQ)                         │   │
│  │  CLIENTE.KSDS   CONTA.KSDS   LANCTO.ESDS             │   │
│  │  ENTRADA.SEQ    ENTRADA.TRAILER.SEQ                  │   │
│  │  REJEITOS.SEQ   AUDIT.SEQ   CONCIL.SEQ               │   │
│  │  ACCR.MOV.SEQ   REPR.LANCTO.SEQ   FECHTO.SEQ         │   │
│  │  CTL.STATUS     CTL.PROCDATE                         │   │
│  │  EXTRATO.GDG    SALDO.GDG                            │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Backups / Histórico (BKP)                           │   │
│  │  BKP.CLIENTE.GDG   BKP.CONTA.GDG                     │   │
│  │  BKP.AUDIT.GDG     BKP.REJEITOS.GDG                  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Staging (STAGE)  │  Seed (SEED)  │  Parms (PARM)    │   │
│  │  STAGE.ENTRADA.SEQ │ SEED.CLIENTES │ PARM.JUROS.CONFIG│   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────────────────┘
                       │
                   TN3270
            (operação e diagnóstico)
                       │
┌──────────────────────▼──────────────────────────────────────┐
│                CAMADA DE OPERAÇÃO                           │
│         ISPF  │  SDSF  │  TSO  │  IDCAMS                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Cadeia Batch e Separação de Janelas

O processamento do Emunah Bank é estritamente dividido entre a **Janela Online (CICS)** e a **Janela Batch (z/OS)**. Para garantir a integridade dos dados e evitar conflitos de bloqueio (*Enqueue/Lock*), o processamento Batch só pode ser iniciado após a desconexão formal dos arquivos VSAM do ambiente CICS (simulado via job `EBJCLOSE`).

A cadeia principal é governada pelo dataset `ARQ.CTL.STATUS`, que atua como a fonte de verdade (*Source of Truth*) da máquina de estados do dia operacional. As transições são protegidas por código COBOL para evitar corrupção de fases. O ciclo segue o modelo canônico de core-banking (inspirado em FLEXCUBE):

1. **OPEN**: Início do dia, recepção de arquivos de canais externos e abertura de transações.
2. **EOTI (End of Transaction Input)**: Cutoff financeiro. Encerramento do recebimento de transações interbancárias, atualização de saldos e postagem.
3. **EOFI (End of Financial Input)**: Cutoff contábil. Aplicação de *accruals* (juros/tarifas) e snapshot das posições em GDG.
4. **CLOSED**: Conciliação *three-way* bloqueante, geração de extratos e fechamento seguro do dia.

Horários são apenas sugestão de janela — a dependência real é o estado em `CTL.STATUS`.

```text
FASE 1 · SOD
  05:55  EBJCLOSE   ── [NOVO] desconecta VSAMs do CICS para liberar Batch
  06:00  EBJPRECK   ── valida ambiente e lê CTL.STATUS (espera CLOSED ou vazio)
  06:05  EBJSOD     ── Start of Day — grava CTL.STATUS=OPEN
  06:15  EBJBCKPD   ── backup CLIENTE/CONTA/AUDIT em GDG (BKP.*.GDG(+1))

FASE 2 · INTAKE
  06:20  EBJWAIT    ── file-watcher sobre STAGE.ENTRADA.SEQ (existência + trailer)
  06:30  EBJLOAD    ── promove STAGE.ENTRADA → ARQ.ENTRADA

FASE 3 · VALIDAÇÃO
  07:00  EBJVALD    ── EBVALI01 → VALIDOS.OUT + REJEITOS.SEQ

FASE 4 · POSTAGEM
  07:30  EBJPOST    ── EBPOST01 → atualiza CONTA.KSDS + LANCTO.ESDS

FASE 5 · ACCRUAL
  08:00  EBJACCR    ── EBACCR01 → ACCR.MOV.SEQ + append em LANCTO.ESDS
  08:00  EBJCUTF    ── cutoff financeiro (CTL.STATUS=EOTI)

FASE 6 · SNAPSHOT
  08:30  EBJSNAP    ── EBSNAP01 → SALDO.GDG(+1)

FASE 7 · RECONCILIATION
  08:45  EBJCUTE    ── cutoff contábil (CTL.STATUS=EOFI)
  09:00  EBJCONC    ── conciliação three-way em CONCIL.SEQ (BLOQUEANTE)

FASE 8 · OUTPUT
  09:30  EBJEXTR    ── EBEXTR01 → EXTRATO.GDG(+1)
  10:00  EBJEOD     ── fechamento — grava CTL.STATUS=CLOSED
  10:05  EBJOPEN    ── [NOVO] reconecta VSAMs ao CICS devolvendo ao online

FASE 9 · HOUSEKEEPING (sob demanda)
  EBJHKGDG  ── monitor/roll de gerações antigas de GDG
  EBJHKAUD  ── arquiva ARQ.AUDIT.SEQ → BKP.AUDIT.GDG e recria vazio
  EBJHKREJ  ── arquiva ARQ.REJEITOS.SEQ → BKP.REJEITOS.GDG e recria vazio

OFF-CYCLE (fora da cadeia oficial)
  EBJREPR   ── revalida rejeitos corrigidos → REPR.LANCTO.SEQ
  EBJRPOST  ── reinjeta recuperados em EBPOST01 (exige STATUS=EOTI)
```

Detalhes de dependência, transições de status, critérios de bloqueio e datasets envolvidos estão em [`docs/05-grade-batch.md`](docs/05-grade-batch.md).

### Utilitários de Resiliência

O laboratório conta com rotinas e programas de infraestrutura para garantir a tolerância a falhas e a correta governança da operação:
- **`EBCTL01`**: Módulo COBOL que blinda o arquivo de *Status*, garantindo que as fases sigam a ordem estrita (OPEN → EOTI → EOFI → CLOSED) e abortando a cadeia caso haja violação operacional.
- **`EBJCLOSE` / `EBJOPEN`**: Scripts que executam a transição entre Online e Batch no CICS, prevenindo locks órfãos e concorrência indevida.
- **`EBRESET` / `EBRESETF`**: Utilitários para limpeza (*purge*) de arquivos residuais, expurgo do `REJPERM.SEQ` e reinicialização segura do ambiente em caso de falhas severas.

---

## Estrutura do Repositório

```text
emunah-bank-lab/
│
├── cobol/
│   ├── batch/              # Programas COBOL batch da cadeia principal
│   │   ├── EBCLLOAD.cbl    # Carga de clientes e contas (seed)
│   │   ├── EBPCHK01.cbl    # Precheck programático do ambiente
│   │   ├── EBCTL01.cbl     # Utilitário de CTL.STATUS / CTL.PROCDATE
│   │   ├── EBVALI01.cbl    # Validação de lançamentos
│   │   ├── EBPOST01.cbl    # Aplicação de lançamentos (POST e RPOST)
│   │   ├── EBACCR01.cbl    # Accruals (juros e tarifas)
│   │   ├── EBSNAP01.cbl    # Snapshot de saldo → SALDO.GDG
│   │   ├── EBCONC01.cbl    # Conciliação three-way
│   │   ├── EBEXTR01.cbl    # Geração de extrato (GDG)
│   │   ├── EBREPR01.cbl    # Revalidação de rejeitos corrigidos
│   │   └── EBJEOD01.cbl    # Fechamento diário
│   │
│   ├── common/
│   │   └── EBCOMM01.cbl    # Rotinas comuns
│   │
│   ├── online/             # Simulações CICS/online
│   │   ├── EBCSEXT.cbl
│   │   ├── EBCSSLD.cbl
│   │   └── EBCSTRF.cbl
│   │
│   ├── hml/                # Cópias promovidas para HML (smoke tests)
│   │   └── EBSMKH01.cbl
│   │
│   └── util/
│       └── EBSALD01.cbl    # Utilitário manual de consulta de saldo
│
├── copybooks/
│   ├── layouts/            # Layouts de registro (CPCLI, CPCNT, CPLCT,
│   │                       # CPAUD, CPSLD, CPSNP, CPSTS, CPCNC, CPREJ, CPEXT)
│   ├── telas/              # Mapas de tela (EBMEXT, EBMSLD, EBMTRF)
│   └── db2/                # DCLGEN (DCLCLI, DCLCONTA, DCLLNCTO)
│
├── jcl/
│   ├── batch/              # JCLs da cadeia batch e off-cycle
│   │   ├── EBJPRECK.jcl    # Precheck de ambiente + CTL.STATUS
│   │   ├── EBJSOD.jcl      # Start of Day → CTL.STATUS=OPEN
│   │   ├── EBJBCKPD.jcl    # Backup GDG (CLIENTE/CONTA/AUDIT)
│   │   ├── EBJWAIT.jcl     # File-watcher STAGE.ENTRADA.SEQ
│   │   ├── EBJLOAD.jcl     # STAGE → ARQ.ENTRADA
│   │   ├── EBJVALD.jcl     # Validação
│   │   ├── EBJPOST.jcl     # Postagem
│   │   ├── EBJCUTF.jcl     # Cutoff financeiro → CTL.STATUS=EOTI
│   │   ├── EBJACCR.jcl     # Accruals (juros e tarifas)
│   │   ├── EBJSNAP.jcl     # Snapshot de saldo → SALDO.GDG
│   │   ├── EBJCUTE.jcl     # Cutoff contábil → CTL.STATUS=EOFI
│   │   ├── EBJCONC.jcl     # Conciliação three-way
│   │   ├── EBJEXTR.jcl     # Extrato → EXTRATO.GDG
│   │   ├── EBJEOD.jcl      # Fechamento → CTL.STATUS=CLOSED
│   │   ├── EBJREPR.jcl     # Reprocessamento de rejeitos (off-cycle)
│   │   ├── EBJRPOST.jcl    # Postagem de reprocessados (off-cycle)
│   │   ├── EBJHKGDG.jcl    # Monitor/roll de GDGs
│   │   ├── EBJHKAUD.jcl    # Housekeeping AUDIT.SEQ
│   │   ├── EBJHKREJ.jcl    # Housekeeping REJEITOS.SEQ
│   │   ├── EBJCLLD.jcl     # Carga inicial via EBCLLOAD
│   │   └── EBSEED.jcl      # Envio/carga de seed
│   │
│   ├── deploy/             # JCLs de alocação e deploy
│   │   ├── EBALLOC.jcl     # Aloca PDS, VSAM e sequenciais base
│   │   ├── EBDEFGDG.jcl    # Define bases GDG (BKP/SALDO/EXTRATO)
│   │   └── EBDEPLOY.jcl    # Pipeline de deploy atômico (&&TMPLOAD)
│   │
│   ├── compile/            # Pipeline de compilação
│   │   ├── EBBUILD.jcl
│   │   ├── EBCOMP.jcl
│   │   └── EBLINK.jcl
│   │
│   ├── hml/                # JCLs de HML (smoke + concil. paralela)
│   │   ├── EBJSMKH.jcl
│   │   └── EBJCONCH.jcl
│   │
│   ├── prd/                # JCLs de PRD simulado
│   │   └── EBJEODP.jcl
│   │
│   └── util/
│       ├── EBLISTDS.jcl    # Lista datasets do lab
│       ├── EBJCLOSE.jcl    # Fecha arquivos VSAM no CICS
│       ├── EBJOPEN.jcl     # Abre arquivos VSAM no CICS
│       └── EBRESET.jcl     # Reset controlado do ambiente
│
├── rexx/                   # Scripts REXX de automação
│   ├── EBCHKLAB.rexx       # Health-check do lab
│   ├── EBSUBJCL.rexx       # Submissor genérico
│   ├── operador/           # EBCADEIA, EBCHKENV, EBSUBMIT
│   └── util/               # EBDSLIST, EBRESET
│
├── data/
│   ├── seed/               # Massa de carga inicial
│   │   ├── clientes.txt
│   │   └── contas.txt
│   ├── entrada/            # Arquivos de entrada batch (formato local)
│   │   ├── lancamentos_d0.txt
│   │   └── lancamentos_simulados.txt
│   └── normalized/         # Massa pronta para upload (LRECL fixo z/OS)
│
├── ebops/                  # EBOPS — Simulador de operações bancárias
│
├── scenarios/              # Cenários de incidente para prática
│
└── docs/
    ├── 01-visao-geral.md
    ├── 02-arquitetura.md
    ├── 03-modulos.md
    ├── 04-mapa-datasets.md
    ├── 05-grade-batch.md
    ├── 06-runbooks.md
    ├── 07-cenarios-incidente.md
    ├── 08-fluxo-zowe.md
    ├── 09-padroes-publicacao.md
    ├── 10-gerador-lancamentos.md
    ├── setup.md
    ├── change-log/         # Estudos de caso (case-005, case-006, case-007 …)
    ├── sob revisao/        # Propostas e inventários do redesenho
    │   ├── proposta-cadeia-batch-realista.md
    │   ├── inventario-mudancas-cadeia-batch.md
    │   └── fluxo-cadeia-batch.md
    └── mapa-emunah-bank-lab.html
```

---

## Pré-requisitos

### Acesso ao mainframe
- Conta ativa no **IBM zXplore** — [zxplore.ibm.com](https://zxplore.ibm.com)
- Userid e senha do ambiente z/OS

### Ferramentas locais
| Ferramenta | Versão mínima | Link |
|---|---|---|
| VS Code | 1.80+ | [code.visualstudio.com](https://code.visualstudio.com) |
| Zowe CLI | 7.x+ | [docs.zowe.org](https://docs.zowe.org) |
| Zowe Explorer (extensão VS Code) | 2.x+ | [marketplace](https://marketplace.visualstudio.com/items?itemName=Zowe.vscode-extension-for-zowe) |
| Emulador TN3270 | qualquer | IBM PCOMM, Mocha TN3270, Vista TN3270 |
| Git | 2.x+ | [git-scm.com](https://git-scm.com) |

---

## Como Começar

### 1. Clone o repositório

```bash
git clone https://github.com/<seu-usuario>/emunah-bank-lab.git
cd emunah-bank-lab
```

### 2. Configure o perfil Zowe

```bash
zowe config init
zowe config set profiles.zosmf.properties.host <host-zxplore>
zowe config set profiles.zosmf.properties.port 443
zowe config set profiles.zosmf.properties.user <seu-userid>
zowe config set profiles.zosmf.properties.password <sua-senha>
zowe config set profiles.zosmf.properties.rejectUnauthorized false
```

### 3. Aloque o ambiente

```bash
# Sobe JCLs de deploy
zowe files upload dir-to-pds ./jcl/deploy "<HLQ>.EMUNAH.DEV.JCL"

# Aloca PDS, VSAM, sequenciais base e datasets auxiliares
# (PARM.JUROS.CONFIG, ACCR.MOV.SEQ, CTL.STATUS, CTL.PROCDATE,
#  ENTRADA.TRAILER.SEQ etc.)
zowe jobs submit data-set "<HLQ>.EMUNAH.DEV.JCL(EBALLOC)"

# Define bases GDG (BKP.CLIENTE, BKP.CONTA, BKP.AUDIT,
# BKP.REJEITOS, SALDO, EXTRATO)
zowe jobs submit data-set "<HLQ>.EMUNAH.DEV.JCL(EBDEFGDG)"
```

### 4. Publique fontes e JCLs

```bash
zowe files upload dir-to-pds ./copybooks/layouts "<HLQ>.EMUNAH.DEV.COPY"
zowe files upload dir-to-pds ./cobol/batch      "<HLQ>.EMUNAH.DEV.COBOL"
zowe files upload dir-to-pds ./cobol/util       "<HLQ>.EMUNAH.DEV.COBOL"
zowe files upload dir-to-pds ./jcl/batch        "<HLQ>.EMUNAH.DEV.JCL"
zowe files upload dir-to-pds ./jcl/util         "<HLQ>.EMUNAH.DEV.JCL"
zowe files upload dir-to-pds ./rexx/util        "<HLQ>.EMUNAH.DEV.REXX"
```

### 5. Carregue a massa inicial

```bash
zowe files upload file-to-data-set ./data/seed/clientes.txt \
  "<HLQ>.EMUNAH.SEED.CLIENTES.SEQ" --record-length 80
zowe files upload file-to-data-set ./data/seed/contas.txt \
  "<HLQ>.EMUNAH.SEED.CONTAS.SEQ" --record-length 120

zowe jobs submit data-set "<HLQ>.EMUNAH.DEV.JCL(EBJCLLD)"
```

### 6. Execute a cadeia batch

```bash
# Envie o arquivo de entrada para staging
zowe files upload file-to-data-set ./data/normalized/lancamentos_simulados.txt \
  "<HLQ>.EMUNAH.STAGE.ENTRADA.SEQ" --record-length 120

# Dispare a cadeia, do precheck ao fechamento
zowe jobs submit data-set "<HLQ>.EMUNAH.DEV.JCL(EBJPRECK)"
# depois, na ordem das fases:
#   EBJCLOSE → EBJSOD  → EBJBCKPD → EBJWAIT → EBJLOAD →
#   EBJVALD  → EBJPOST → EBJACCR  → EBJCUTF →
#   EBJSNAP  → EBJCUTE → EBJCONC  → EBJEXTR → EBJEOD → EBJOPEN
#
# Cada job lê e/ou grava ARQ.CTL.STATUS — execuções fora de ordem
# abortam por inconsistência de status.
```

---

## Documentação

| Documento | Descrição |
|---|---|
| [01 - Visão Geral](docs/01-visao-geral.md) | Objetivo, escopo e contexto do laboratório |
| [02 - Arquitetura](docs/02-arquitetura.md) | Camadas, ferramentas e fluxo de integração |
| [03 - Módulos](docs/03-modulos.md) | Módulos funcionais do sistema e seus programas |
| [04 - Mapa de Datasets](docs/04-mapa-datasets.md) | Datasets operacionais, backups, GDG, STAGE, PARM e SEED |
| [05 - Grade Batch](docs/05-grade-batch.md) | Cadeia batch redesenhada, fases, CTL.STATUS, cutoffs e housekeeping |
| [06 - Runbooks](docs/06-runbooks.md) | Procedimentos de diagnóstico e correção por incidente |
| [07 - Cenários de Incidente](docs/07-cenarios-incidente.md) | Cenários controlados para prática de troubleshooting |
| [08 - Fluxo Zowe](docs/08-fluxo-zowe.md) | Como o Zowe integra o ambiente local ao mainframe |
| [09 - Padrões de Publicação](docs/09-padroes-publicacao.md) | Mapeamento local→remoto e regras de promoção |
| [10 - Gerador de Lançamentos](docs/10-gerador-lancamentos.md) | Geração controlada de massa de entrada |
| [Setup do Lab](docs/setup.md) | Passo a passo de inicialização |
| [Proposta da Cadeia](docs/sob%20revisao/proposta-cadeia-batch-realista.md) | Racional, fases canônicas e decisões do redesenho |
| [Inventário de Mudanças](docs/sob%20revisao/inventario-mudancas-cadeia-batch.md) | Checklist do que foi mantido/alterado/criado/descartado |
| [Fluxo da Cadeia](docs/sob%20revisao/fluxo-cadeia-batch.md) | Diagrama detalhado do encadeamento por fase |
| [Estudos de Caso](docs/change-log/) | Diários de bordo dos incidentes resolvidos no lab |
| [Mapa Visual do Lab](docs/mapa-emunah-bank-lab.html) | Mapa interativo navegável em HTML |
| [EBOPS — Guia Completo](ebops/EBOPS-GUIA-COMPLETO.md) | Guia de implantação e uso do simulador |

---

## Módulos do Sistema

| Módulo | Programa(s) | Job(s) |
|---|---|---|
| CICS Control | — | `EBJCLOSE`, `EBJOPEN` |
| Precheck | `EBPCHK01` | `EBJPRECK` |
| Cliente / Conta (seed) | `EBCLLOAD` | `EBJCLLD` |
| Controle (CTL.STATUS / CTL.PROCDATE) | `EBCTL01` | `EBJSOD`, `EBJCUTF`, `EBJCUTE`, `EBJEOD` |
| Backup pré-batch | — | `EBJBCKPD` |
| Entrada (staging + watcher) | — | `EBJWAIT`, `EBJLOAD` |
| Lançamentos | `EBVALI01`, `EBPOST01` | `EBJVALD`, `EBJPOST` |
| Accrual | `EBACCR01` | `EBJACCR` |
| Saldo (snapshot) | `EBSNAP01` | `EBJSNAP` |
| Conciliação three-way | `EBCONC01` | `EBJCONC` |
| Extrato | `EBEXTR01` | `EBJEXTR` |
| Fechamento | `EBJEOD01` | `EBJEOD` |
| Reprocessamento | `EBREPR01`, `EBPOST01` | `EBJREPR`, `EBJRPOST` |
| Housekeeping | — | `EBJHKGDG`, `EBJHKAUD`, `EBJHKREJ` |
| Utilitário (consulta de saldo) | `EBSALD01` (em `cobol/util/`) | — |

---

## EBOPS — Simulador de Operações Bancárias

O **EBOPS** (Emunah Bank Operations Simulator) é a camada de simulação operacional do laboratório. Ele gera automaticamente demandas, incidentes e tarefas que reproduzem o cotidiano de um desenvolvedor mainframe em um banco real.

O EBOPS simula sete ferramentas corporativas amplamente usadas em ambientes bancários:

| Ferramenta simulada | Função no laboratório |
|---|---|
| **Control-M** | Grade batch visual com status por etapa, simulação de falha e HOLD |
| **Jira / ServiceNow** | Board de tickets com demandas e incidentes sorteados a cada "novo dia" |
| **Changeman / Endevor** | Fluxo de promoção DEV → HML → PRD, rollback e controle de versão |
| **File Manager** | Investigação de VSAM com layout de copybook, comparação antes/depois |
| **Abendaid / Fault Analyzer** | Diagnóstico de abends por offset do spool × listing de compilação |
| **Syncope / Scheduler Alerting** | Alertas de SLA, jobs fora da janela, notificações de falha |
| **SDSF / RMF** | Consulta de spool, análise de JES output e métricas de execução |

Para iniciar o EBOPS localmente:

```bash
cd ebops
python ebops_server.py
# Interface disponível em http://localhost:5000
```

Consulte o [Guia Completo do EBOPS](ebops/EBOPS-GUIA-COMPLETO.md) para detalhes de implantação, configuração e uso.

---

## Massa de Dados

O laboratório inclui massa seed completa carregada via job `EBJCLLD` (executa `EBCLLOAD`):

| Arquivo | Registros | Descrição |
|---|---|---|
| `data/seed/clientes.txt` | 20 | Cadastro com nome, CPF, data de nascimento e abertura |
| `data/seed/contas.txt` | 40 | 2 contas por cliente (C/C e poupança), saldo inicial de R$ 1.100,00 a R$ 4.000,00 |

---

## Tecnologias

- **z/OS** — sistema operacional mainframe IBM
- **COBOL** — linguagem principal dos programas batch e online
- **CICS** — processamento de transações online e telas 3270 (BMS)
- **JCL** — controle, parametrização e encadeamento de jobs
- **VSAM** — armazenamento de altíssima performance para o *Core Transacional* (KSDS para Contas/Clientes, ESDS para Lançamentos Diários)
- **DB2** — banco de dados relacional z/OS, utilizado para armazenamento de dados tabulares satélites (como Trilhas de Auditoria)
- **GDG** — histórico versionado automatizado (retenção de extratos, snapshots de saldo e backups)
- **IDCAMS / ICETOOL / SORT** — utilitários de administração e manipulação de datasets
- **REXX** — automação e scripts utilitários
- **TSO / ISPF** — operação interativa e navegação no ambiente z/OS via 3270
- **Zowe CLI / Explorer** — ponte entre ambiente local e mainframe
- **TN3270** — acesso ao terminal mainframe (emulador)
- **EBOPS** — simulador de operações e demandas bancárias (Python)

---

> *"Emunah (אֱמוּנָה) — fidelidade, confiança. A mesma qualidade que sustenta décadas de operação ininterrupta no mainframe"*
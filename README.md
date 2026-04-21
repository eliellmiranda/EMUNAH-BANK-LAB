# 🏦 Emunah Bank Lab

![z/OS](https://img.shields.io/badge/z%2FOS-IBM%20zXplore-blue?style=flat-square&logo=ibm)
![COBOL](https://img.shields.io/badge/COBOL-85%2F2002-lightgrey?style=flat-square)
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

O **Emunah Bank Lab** replica, de forma controlada, os padrões operacionais de instituições financeiras que sustentam seus sistemas críticos em mainframe. O laboratório cobre o ciclo completo de um processamento bancário batch: recepção do arquivo do dia, validação, aplicação de lançamentos, cutoff financeiro, cálculo de accruals, snapshot de saldo, cutoff contábil, extrato, conciliação three-way e fechamento, com cadeia de housekeeping para manter o ambiente estável entre dias.

O nome *Emunah* (אֱמוּנָה) remete ao conceito hebraico de fidelidade e confiança — qualidades centrais tanto no setor bancário quanto nos sistemas mainframe, conhecidos por décadas de disponibilidade ininterrupta.

---

## Arquitetura

```
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
│  │  ENTRADA.SEQ    REJEITOS.SEQ  AUDIT.SEQ              │   │
│  │  CONCIL.SEQ     CTL.STATUS   CTL.PROCDATE            │   │
│  │  ACCR.MOV.SEQ   REPR.LANCTO.SEQ                      │   │
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

## Cadeia Batch

A cadeia principal é governada pelo dataset `ARQ.CTL.STATUS`, que transita entre as fases inspiradas em FLEXCUBE (`OPEN → EOTI → EOFI → CLOSED`). Cada job ou lê o status esperado ou grava o próximo.

```
06:00  EBJPRECK   ── valida ambiente e lê CTL.STATUS
06:05  EBJSOD     ── Start of Day — grava CTL.STATUS=OPEN
06:15  EBJBACKP   ── backup CLIENTE/CONTA/AUDIT em GDG
06:20  EBJWAIT    ── file-watcher sobre STAGE.ENTRADA.SEQ
06:30  EBJLOAD    ── promove STAGE.ENTRADA → ARQ.ENTRADA
07:00  EBJVALD    ── valida layout e regras de negócio
07:30  EBJPOST    ── aplica lançamentos válidos (ENTRADA+REPR)
08:00  EBJCUTF    ── cutoff financeiro (CTL.STATUS=EOTI)
08:15  (EBACCR01) ── accruals (juros/tarifas → ACCR.MOV.SEQ)
08:30  EBJSNAP    ── snapshot diário de saldo → SALDO.GDG(+1)
08:45  EBJCUTE    ── cutoff contábil (CTL.STATUS=EOFI)
09:00  EBJCONC    ── conciliação three-way (CONCIL.SEQ)
09:30  EBJEXTR    ── gera EXTRATO.GDG(+1)
10:00  EBJEOD     ── fechamento — grava CTL.STATUS=CLOSED

  (sob demanda, fora da cadeia)
  EBJREPR   ── reaplicação de rejeitos corrigidos
  EBJRPOST  ── postagem de REPR.LANCTO.SEQ via EBPOST01
  EBJHKGDG  ── monitor passivo das bases GDG
  EBJHKAUD  ── housekeeping ativo de ARQ.AUDIT.SEQ
  EBJHKREJ  ── housekeeping ativo de ARQ.REJEITOS.SEQ
```

Detalhes de dependência, critérios de bloqueio, janelas e datasets envolvidos estão em [`docs/05-grade-batch.md`](docs/05-grade-batch.md).

---

## Estrutura do Repositório

```
emunah-bank-lab/
│
├── cobol/
│   ├── batch/              # Programas COBOL batch da cadeia principal
│   │   ├── EBCLLOAD.cbl    # Carga de clientes e contas (seed)
│   │   ├── EBVALI01.cbl    # Validação de lançamentos
│   │   ├── EBPOST01.cbl    # Aplicação de lançamentos
│   │   ├── EBACCR01.cbl    # Accruals (juros e tarifas)
│   │   ├── EBSNAP01.cbl    # Snapshot de saldo para SALDO.GDG
│   │   ├── EBCONC01.cbl    # Conciliação three-way
│   │   ├── EBEXTR01.cbl    # Geração de extrato
│   │   ├── EBREPR01.cbl    # Reprocessamento de rejeitos
│   │   ├── EBCTL01.cbl     # Controle de CTL.STATUS / CTL.PROCDATE
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
│   ├── hml/                # Cópias promovidas para HML
│   │
│   └── util/
│       └── EBSALD01.cbl    # Utilitário manual de consulta de saldo
│
├── copybooks/
│   └── layouts/            # Copybooks e layouts de registro
│
├── jcl/
│   ├── batch/              # JCLs da cadeia batch e off-cycle
│   │   ├── EBJPRECK.jcl    # Precheck de ambiente + CTL.STATUS
│   │   ├── EBJSOD.jcl      # Start of Day
│   │   ├── EBJBCKPD.jcl    # Backup GDG (CLIENTE/CONTA/AUDIT)
│   │   ├── EBJWAIT.jcl     # File-watcher STAGE.ENTRADA.SEQ
│   │   ├── EBJLOAD.jcl     # STAGE → ARQ.ENTRADA
│   │   ├── EBJVALD.jcl     # Validação
│   │   ├── EBJPOST.jcl     # Postagem
│   │   ├── EBJCUTF.jcl     # Cutoff financeiro
│   │   ├── EBJSNAP.jcl     # Snapshot de saldo
│   │   ├── EBJCUTE.jcl     # Cutoff contábil
│   │   ├── EBJCONC.jcl     # Conciliação three-way
│   │   ├── EBJEXTR.jcl     # Geração de extrato GDG
│   │   ├── EBJEOD.jcl      # Fechamento diário
│   │   ├── EBJREPR.jcl     # Reprocessamento (off-cycle)
│   │   ├── EBJRPOST.jcl    # Postagem de reprocessados
│   │   ├── EBJHKGDG.jcl    # Monitor passivo de GDGs
│   │   ├── EBJHKAUD.jcl    # Housekeeping AUDIT.SEQ
│   │   ├── EBJHKREJ.jcl    # Housekeeping REJEITOS.SEQ
│   │   ├── EBJCLLD.jcl     # Carga inicial via EBCLLOAD
│   │   └── EBSEED.jcl      # Envio/carga de seed
│   │
│   ├── deploy/             # JCLs de alocação e deploy
│   │   ├── EBALLOC.jcl     # Aloca PDS, VSAM, sequenciais base
│   │   ├── EBALLOC2.jcl    # Aloca PARM/ACCR/CTL.PROCDATE/TRAILER
│   │   ├── EBDEFGDG.jcl    # Define bases GDG
│   │   └── EBDEPLOY.jcl    # Pipeline de deploy
│   │
│   └── util/
│       ├── EBLISTDS.jcl    # Lista datasets do lab
│       └── EBRESET.jcl     # Reset controlado do ambiente
│
├── rexx/
│   └── util/               # Scripts REXX de automação
│
├── data/
│   ├── entrada/            # Arquivos de entrada batch
│   └── seed/               # Massa de dados inicial
│       ├── clientes.txt
│       └── contas.txt
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
    ├── inventario-mudancas-cadeia-batch.md
    ├── proposta-cadeia-batch-realista.md
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

# Aloca PDS, VSAM e sequenciais base
zowe jobs submit data-set "<HLQ>.EMUNAH.DEV.JCL(EBALLOC)"

# Aloca datasets auxiliares (PARM, ACCR, CTL.PROCDATE, TRAILER)
zowe jobs submit data-set "<HLQ>.EMUNAH.DEV.JCL(EBALLOC2)"

# Define bases GDG (EXTRATO, SALDO, BKP.*)
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
zowe files upload file-to-data-set ./data/entrada/lancamentos.txt \
  "<HLQ>.EMUNAH.STAGE.ENTRADA.SEQ" --record-length 120

# Dispare a cadeia, do precheck ao fechamento
zowe jobs submit data-set "<HLQ>.EMUNAH.DEV.JCL(EBJPRECK)"
# depois: EBJSOD → EBJBACKP → EBJWAIT → EBJLOAD → EBJVALD → EBJPOST →
#         EBJCUTF → EBJSNAP → EBJCUTE → EBJCONC → EBJEXTR → EBJEOD
```

---

## Documentação

| Documento | Descrição |
|---|---|
| [01 - Visão Geral](docs/01-visao-geral.md) | Objetivo, escopo e contexto do laboratório |
| [02 - Arquitetura](docs/02-arquitetura.md) | Camadas, ferramentas e fluxo de integração |
| [03 - Módulos](docs/03-modulos.md) | Módulos funcionais do sistema e seus programas |
| [04 - Mapa de Datasets](docs/04-mapa-datasets.md) | Datasets operacionais, backups, GDG, STAGE, PARM e SEED |
| [05 - Grade Batch](docs/05-grade-batch.md) | Cadeia batch completa, CTL.STATUS, cutoffs e housekeeping |
| [06 - Runbooks](docs/06-runbooks.md) | Procedimentos de diagnóstico e correção por incidente |
| [07 - Cenários de Incidente](docs/07-cenarios-incidente.md) | Cenários controlados para prática de troubleshooting |
| [08 - Fluxo Zowe](docs/08-fluxo-zowe.md) | Como o Zowe integra o ambiente local ao mainframe |
| [09 - Padrões de Publicação](docs/09-padroes-publicacao.md) | Mapeamento local→remoto e regras de promoção |
| [Inventário de Mudanças](docs/inventario-mudancas-cadeia-batch.md) | Inventário detalhado do redesenho da cadeia batch |
| [Proposta da Cadeia](docs/proposta-cadeia-batch-realista.md) | Baseline da cadeia batch realista |
| [Mapa Visual do Lab](docs/mapa-emunah-bank-lab.html) | Mapa interativo navegável em HTML |
| [EBOPS — Guia Completo](ebops/EBOPS-GUIA-COMPLETO.md) | Guia de implantação e uso do simulador |

---

## Módulos do Sistema

| Módulo | Programa(s) | Job(s) |
|---|---|---|
| Cliente | `EBCLLOAD` | `EBJCLLD` |
| Conta | `EBCLLOAD` | `EBJCLLD` |
| Controle (CTL.STATUS) | `EBCTL01` | `EBJSOD`, `EBJCUTF`, `EBJCUTE`, `EBJEOD` |
| Entrada (staging) | — | `EBJWAIT`, `EBJLOAD` |
| Lançamentos | `EBVALI01`, `EBPOST01` | `EBJVALD`, `EBJPOST` |
| Accrual | `EBACCR01` | — |
| Saldo (snapshot) | `EBSNAP01` | `EBJSNAP` |
| Conciliação | `EBCONC01` | `EBJCONC` |
| Extrato | `EBEXTR01` | `EBJEXTR` |
| Fechamento | `EBJEOD01` | `EBJEOD` |
| Reprocessamento | `EBREPR01` | `EBJREPR`, `EBJRPOST` |
| Backup | — | `EBJBCKPD` |
| Housekeeping | — | `EBJHKGDG`, `EBJHKAUD`, `EBJHKREJ` |
| Utilitários | `EBSALD01` | — |

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
- **COBOL** — linguagem principal dos programas batch
- **JCL** — controle e encadeamento de jobs
- **VSAM** — armazenamento dos arquivos master (KSDS, ESDS)
- **GDG** — histórico versionado (extrato, saldo, backups)
- **IDCAMS / ICETOOL / SORT** — utilitários de administração e manipulação de datasets
- **DB2** — banco de dados relacional z/OS
- **REXX** — automação e scripts utilitários
- **TSO / ISPF** — operação interativa e navegação no ambiente z/OS via 3270
- **Zowe CLI / Explorer** — ponte entre ambiente local e mainframe
- **TN3270** — acesso ao terminal mainframe (emulador)
- **EBOPS** — simulador de operações e demandas bancárias (Python)

---

> *"Emunah (אֱמוּנָה) — fidelidade, confiança. A mesma qualidade que sustenta décadas de operação ininterrupta no mainframe"*

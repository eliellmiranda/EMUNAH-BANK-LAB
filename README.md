# 🏦 Emunah Bank Lab

![z/OS](https://img.shields.io/badge/z%2FOS-IBM%20zXplore-blue?style=flat-square&logo=ibm)
![COBOL](https://img.shields.io/badge/COBOL-85%2F2002-lightgrey?style=flat-square)
![JCL](https://img.shields.io/badge/JCL-batch-orange?style=flat-square)
![Zowe](https://img.shields.io/badge/Zowe-CLI%20%2F%20Explorer-green?style=flat-square)
![VSAM](https://img.shields.io/badge/VSAM-KSDS%20%2F%20ESDS-yellow?style=flat-square)
![DB2](https://img.shields.io/badge/DB2-z%2FOS-blue?style=flat-square&logo=ibm)
![REXX](https://img.shields.io/badge/REXX-automation-purple?style=flat-square)
![Status](https://img.shields.io/badge/status-em%20desenvolvimento-brightgreen?style=flat-square)

> Ambiente pessoal de simulação bancária mainframe com foco em desenvolvimento COBOL, processamento batch, investigação de falhas e integração via Zowe e TN3270.

---

## Sobre o laboratório

O **Emunah Bank Lab** replica, de forma controlada, os padrões operacionais de instituições financeiras que sustentam seus sistemas críticos em mainframe. O laboratório cobre o ciclo completo de um processamento bancário batch: da entrada de lançamentos ao fechamento diário, passando por validação, aplicação, consolidação de saldo, geração de extrato, conciliação e reprocessamento de rejeitos.

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
│  │  Arquivos de Negócio (ARQ)                           │   │
│  │  CLIENTE.KSDS  CONTA.KSDS  SALDO.KSDS                │   │
│  │  LANCTO.ESDS   ENTRADA.SEQ  REJEITO.SEQ              │   │
│  │  AUDIT.SEQ     EXTRATO.GDG                           │   │
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

```
06:00  PRECHECK   ── verifica ambiente
06:15  EBBACKUP   ── backup do estado anterior
06:30  EBJLOAD    ── prepara arquivo do dia
07:00  EBJVALD    ── valida layout e regras de negócio
07:30  EBJPOST    ── aplica lançamentos
08:00  EBJSALD    ── consolida saldos
09:00  EBJEXTR    ── gera extratos (GDG)
09:30  EBJCONC    ── concilia totais
10:00  EBJEOD     ── fechamento do dia

           (sob demanda)
           EBJREPR ── reprocessa rejeitos corrigidos
```

---

## Estrutura do Repositório

```
emunah-bank-lab/
│
├── cobol/
│   └── batch/              # Programas COBOL batch
│       ├── EBCLLOAD.cbl    # Carga de clientes e contas
│       ├── EBVALI01.cbl    # Validação de lançamentos
│       ├── EBPOST01.cbl    # Aplicação de lançamentos
│       ├── EBSALD01.cbl    # Consolidação de saldo
│       ├── EBEXTR01.cbl    # Geração de extrato
│       ├── EBCONC01.cbl    # Conciliação
│       └── EBREPR01.cbl    # Reprocessamento de rejeitos
│
├── copybooks/
│   └── layouts/            # Copybooks e layouts de registro
│
├── jcl/
│   ├── compile/            # JCLs de compilação e link-edit
│   └── batch/              # JCLs da cadeia batch
│       ├── PRECHECK.jcl
│       ├── EBBACKUP.jcl
│       ├── EBJLOAD.jcl
│       ├── EBJVALD.jcl
│       ├── EBJPOST.jcl
│       ├── EBJSALD.jcl
│       ├── EBJEXTR.jcl
│       ├── EBJCONC.jcl
│       ├── EBJEOD.jcl
│       └── EBJREPR.jcl
│
├── rexx/
│   └── util/               # Scripts REXX de automação
│
├── data/
│   └── entrada/            # Arquivos de massa e entrada batch
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
    └── 09-padroes-publicacao.md
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

Teste a conexão:

```bash
zowe zosmf check status
```

### 3. Publique os fontes no mainframe

```bash
# Copybooks primeiro — sempre antes dos fontes COBOL
zowe files upload dir-to-pds ./copybooks/layouts "Z77948.EMUNAH.DEV.COPY"

# Fontes COBOL
zowe files upload dir-to-pds ./cobol/batch "Z77948.EMUNAH.DEV.COBOL"

# JCLs
zowe files upload dir-to-pds ./jcl/compile "Z77948.EMUNAH.DEV.JCL"
zowe files upload dir-to-pds ./jcl/batch   "Z77948.EMUNAH.DEV.JCL"

# Scripts REXX
zowe files upload dir-to-pds ./rexx/util "Z77948.EMUNAH.DEV.REXX"
```

### 4. Execute o build

```bash
# Compila todos os programas
zowe jobs submit data-set "Z77948.EMUNAH.DEV.JCL(EBBUILD)"

# Acompanhe o job
zowe jobs list jobs --owner Z77948
```

### 5. Execute a cadeia batch

```bash
# Envie o arquivo de entrada do dia
zowe files upload file-to-data-set \
  ./data/entrada/lancamentos.txt \
  "Z77948.EMUNAH.ARQ.ENTRADA.SEQ" --record-length 80

# Submeta a cadeia
zowe jobs submit data-set "Z77948.EMUNAH.DEV.JCL(EBJLOAD)"
```

---

## Documentação

| Documento | Descrição |
|---|---|
| [01 - Visão Geral](docs/01-visao-geral.md) | Objetivo, escopo e contexto do laboratório |
| [02 - Arquitetura](docs/02-arquitetura.md) | Camadas, ferramentas e fluxo de integração |
| [03 - Módulos](docs/03-modulos.md) | Módulos funcionais do sistema e seus programas |
| [04 - Mapa de Datasets](docs/04-mapa-datasets.md) | Todos os datasets, tipos, DDNAMEs e finalidades |
| [05 - Grade Batch](docs/05-grade-batch.md) | Cadeia batch completa com dependências e critérios |
| [06 - Runbooks](docs/06-runbooks.md) | Procedimentos de diagnóstico e correção por incidente |
| [07 - Cenários de Incidente](docs/07-cenarios-incidente.md) | Cenários controlados para prática de troubleshooting |
| [08 - Fluxo Zowe](docs/08-fluxo-zowe.md) | Como o Zowe integra o ambiente local ao mainframe |
| [09 - Padrões de Publicação](docs/09-padroes-publicacao.md) | Mapeamento local→remoto e regras de promoção |

---

## Módulos do Sistema

| Módulo | Programa(s) | Job(s) |
|---|---|---|
| Cliente | `EBCLLOAD` | — |
| Conta | `EBCLLOAD` | — |
| Lançamentos | `EBVALI01`, `EBPOST01` | `EBJVALD`, `EBJPOST` |
| Saldo | `EBSALD01` | `EBJSALD` |
| Extrato | `EBEXTR01` | `EBJEXTR` |
| Conciliação | `EBCONC01` | `EBJCONC` |
| Fechamento | — | `EBJEOD` |
| Reprocessamento | `EBREPR01` | `EBJREPR` |

---

## Tecnologias

- **z/OS** — sistema operacional mainframe IBM
- **COBOL** — linguagem principal dos programas batch
- **JCL** — controle e encadeamento de jobs
- **VSAM** — armazenamento dos arquivos master (KSDS, ESDS)
- **GDG** — histórico de extratos com geração automática
- **DB2** — banco de dados relacional z/OS
- **REXX** — automação e scripts utilitários
- **Zowe CLI / Explorer** — ponte entre ambiente local e mainframe
- **TN3270** — operação clássica via ISPF e SDSF

---

> *"Emunah (אֱמוּנָה) — fidelidade, confiança. A mesma qualidade que sustenta décadas de operação ininterrupta no mainframe."*

# Emunah Bank Lab

**Laboratório bancário em mainframe IBM z/OS, com foco em processamento batch, contexto operacional online e troubleshooting em ambiente corporativo simulado.**

O **Emunah Bank Lab** simula o ciclo operacional de um ambiente bancário em z/OS, cobrindo carga inicial, validação, aplicação de lançamentos, consolidação de saldo, geração de extrato, conciliação, reprocessamento de rejeitos e rotina de fechamento diário.

Mais do que uma cadeia batch, o projeto representa a dinâmica de um **core bancário híbrido**, em que arquivos master, consistência de dados, operação, suporte e investigação de falhas sustentam tanto o processamento diário quanto o contexto de sistemas **online**.

Desenvolvido em **IBM zXplore**, com fluxo local via **VS Code + Zowe CLI/Explorer** e execução remota em **z/OS**.

![z/OS](https://img.shields.io/badge/z%2FOS-IBM%20Mainframe-blue?style=flat-square\&logo=ibm)
![COBOL](https://img.shields.io/badge/COBOL-Enterprise%206.4-lightgrey?style=flat-square)
![JCL](https://img.shields.io/badge/JCL-Batch%20Processing-orange?style=flat-square)
![VSAM](https://img.shields.io/badge/VSAM-KSDS%20%7C%20ESDS-yellow?style=flat-square)
![GDG](https://img.shields.io/badge/GDG-Extratos-9cf?style=flat-square)
![REXX](https://img.shields.io/badge/REXX-Automação-purple?style=flat-square)
![Zowe](https://img.shields.io/badge/Zowe-CLI%20%2F%20Explorer-green?style=flat-square)
![Status](https://img.shields.io/badge/status-lab%20operacional-brightgreen?style=flat-square)

---

## Destaques do projeto

* **Processamento bancário batch ponta a ponta**, da entrada de lançamentos ao fechamento diário
* **Contexto operacional online**, com arquivos master, consistência de cadastro, suporte e investigação de falhas
* **7 programas COBOL batch** com regras de negócio, rejeitos, auditoria e consolidação
* **Cadeia JCL encadeada** com dependências, critérios de bloqueio e controle por etapa
* **VSAM KSDS e ESDS**, arquivos sequenciais e **GDG** para histórico de extratos
* **10 cenários de incidente** com runbooks operacionais e prática de troubleshooting
* **Integração local ↔ mainframe** com Zowe CLI / Explorer, além de operação complementar via TN3270
* **Documentação técnica estruturada**, com arquitetura, módulos, datasets, grade batch, runbooks e padrões de publicação

---

## O que este projeto demonstra

| Competência                       | Como aparece no projeto                                                          |
| --------------------------------- | -------------------------------------------------------------------------------- |
| **Desenvolvimento COBOL**         | Programas batch com regras de negócio, tratamento de erro, rejeito e auditoria   |
| **JCL e processamento batch**     | Cadeia diária com jobs encadeados, dependências, RC e critérios de parada        |
| **VSAM**                          | Uso de KSDS para cadastros e saldos, e ESDS para histórico de lançamentos        |
| **Operação de ambiente bancário** | Fluxo de carga, validação, aplicação, conciliação, fechamento e reprocessamento  |
| **Visão de core híbrido**         | Relação entre processamento batch, arquivos master e contexto operacional online |
| **Troubleshooting**               | Incidentes controlados, leitura de spool, diagnóstico e ação corretiva           |
| **Auditoria e rastreabilidade**   | Registro de eventos, rejeitos, evidências operacionais e trilha de processamento |
| **Integração local ↔ z/OS**       | Edição local, publicação remota, build, submit e análise de execução             |
| **Organização técnica**           | Documentação modular, convenções de código, datasets e promoção entre ambientes  |

---

## Arquitetura

```text
┌─────────────────────────────────────────────────────┐
│                  CAMADA LOCAL                       │
│  VS Code + Zowe Explorer + Git                      │
│  .cbl  .jcl  .cpy  .rexx  /data  /docs              │
└────────────────────┬────────────────────────────────┘
                     │
            Zowe CLI / Explorer
        (upload, submit, spool, fetch)
                     │
┌────────────────────▼────────────────────────────────┐
│               CAMADA REMOTA — z/OS                  │
│            IBM zXplore (mainframe real)             │
│                                                     │
│  ┌─────────┐  ┌─────────┐  ┌───────────────────┐    │
│  │  DEV    │  │  HML    │  │  PRD (simulado)   │    │
│  │ .COBOL  │  │ .COBOL  │  │  .JCL             │    │
│  │ .COPY   │  │ .JCL    │  │  .LOADLIB         │    │
│  │ .JCL    │  │ .LOADLIB│  │  .PARMLIB         │    │
│  │ .REXX   │  └─────────┘  └───────────────────┘    │
│  │ .LOADLIB│                                        │
│  └─────────┘                                        │
│                                                     │
│  ┌──────────────────────────────────────────────┐   │
│  │          Arquivos de Negócio (ARQ)           │   │
│  │  CLIENTE.KSDS   CONTA.KSDS   SALDO.KSDS      │   │
│  │  LANCTO.ESDS    ENTRADA.SEQ   REJEITO.SEQ    │   │
│  │  AUDIT.SEQ      EXTRATO.GDG                  │   │
│  └──────────────────────────────────────────────┘   │
└────────────────────┬────────────────────────────────┘
                     │
                  TN3270
          (operação e diagnóstico)
                     │
┌────────────────────▼────────────────────────────────┐
│             CAMADA DE OPERAÇÃO                      │
│      ISPF  │  SDSF  │  TSO  │  IDCAMS               │
└─────────────────────────────────────────────────────┘
```

---

## Escopo funcional

O laboratório está organizado em módulos que refletem responsabilidades típicas de um ambiente bancário:

| Módulo          | Programa   | Job       | Dataset principal                     | Papel                              |
| --------------- | ---------- | --------- | ------------------------------------- | ---------------------------------- |
| Carga inicial   | `EBCLLOAD` | `EBJCLLD` | `ARQ.CLIENTE.KSDS`, `ARQ.CONTA.KSDS`  | Popular arquivos master            |
| Validação       | `EBVALI01` | `EBJVALD` | `ARQ.ENTRADA.SEQ` → `ARQ.REJEITO.SEQ` | Validar layout e regras de negócio |
| Aplicação       | `EBPOST01` | `EBJPOST` | `ARQ.LANCTO.ESDS`, `ARQ.CONTA.KSDS`   | Aplicar lançamentos válidos        |
| Saldo           | `EBSALD01` | `EBJSALD` | `ARQ.SALDO.KSDS`                      | Consolidar saldo por conta         |
| Extrato         | `EBEXTR01` | `EBJEXTR` | `ARQ.EXTRATO.GDG`                     | Gerar histórico de extratos        |
| Conciliação     | `EBCONC01` | `EBJCONC` | Cruzamento de totais                  | Validar integridade do dia         |
| Fechamento      | —          | `EBJEOD`  | Encerramento operacional              | Fechar o ciclo diário              |
| Reprocessamento | `EBREPR01` | `EBJREPR` | Rejeitos corrigidos                   | Reaplicar registros sob demanda    |

---

## Batch e online no contexto do laboratório

Embora o núcleo do projeto seja a **cadeia batch diária**, o laboratório **não se limita ao batch**.

Ele também representa o contexto de sistemas **online** ao trabalhar com:

* **arquivos master de cliente e conta**, que sustentam consultas, validações e consistência operacional;
* **integridade entre cadastros, movimentos e saldos**, típica de ambientes que coexistem com processamento online;
* **suporte e troubleshooting**, com análise de falhas que impactam tanto o ciclo diário quanto a confiabilidade do ambiente;
* **visão de core bancário**, em que processamento batch e operação online coexistem no mesmo ecossistema mainframe.

Em outras palavras: o projeto demonstra **processamento batch**, mas também mostra compreensão da **arquitetura operacional maior em que o online existe e depende desses controles**.

---

## Cadeia batch — janela operacional

```text
06:00  PRECHECK   ── verifica pré-condições do ambiente
06:15  EBBACKUP   ── registra o estado anterior
06:30  EBJLOAD    ── prepara o arquivo de entrada do dia
07:00  EBJVALD    ── valida layout e regras de negócio
07:30  EBJPOST    ── aplica lançamentos válidos
08:00  EBJSALD    ── consolida saldos por conta
09:00  EBJEXTR    ── gera extratos (nova geração GDG)
09:30  EBJCONC    ── concilia totais e libera o fechamento
10:00  EBJEOD     ── encerra o dia operacional

         (sob demanda)
         EBJREPR   ── reprocessa rejeitos corrigidos
```

Falha em qualquer etapa crítica bloqueia a continuidade da cadeia até correção, reanálise e eventual reprocessamento controlado.

---

## Stack técnica

| Camada                    | Tecnologia                   | Uso no projeto                               |
| ------------------------- | ---------------------------- | -------------------------------------------- |
| Sistema operacional       | **z/OS**                     | Ambiente mainframe IBM                       |
| Linguagem principal       | **Enterprise COBOL 6.4**     | Programas batch com regras de negócio        |
| Controle de jobs          | **JCL**                      | Encadeamento, execução e controle de RC      |
| Armazenamento             | **VSAM (KSDS/ESDS)**         | Cadastros, saldos e histórico de lançamentos |
| Arquivos sequenciais      | **PS / SEQ**                 | Entrada, rejeitos e auditoria                |
| Histórico                 | **GDG**                      | Extratos versionados por geração             |
| Automação                 | **REXX**                     | Scripts utilitários e apoio operacional      |
| Integração local → remoto | **Zowe CLI / Zowe Explorer** | Upload, submit, spool e automação            |
| Operação                  | **ISPF, SDSF, TSO, IDCAMS**  | Diagnóstico, troubleshooting e investigação  |
| Versionamento             | **Git / GitHub**             | Controle de versão e portfólio técnico       |
| Evolução do laboratório   | **DB2 for z/OS**             | Frente prevista de expansão do projeto       |

---

## Cenários de incidente

O projeto inclui cenários controlados para prática de troubleshooting, com runbooks associados:

| Cenário               | Descrição                                  |
| --------------------- | ------------------------------------------ |
| `normal-day`          | Execução completa sem falhas               |
| `missing-input`       | Arquivo de entrada ausente                 |
| `invalid-layout`      | Layout de registro incorreto               |
| `duplicate-key`       | Tentativa de gravação duplicada em KSDS    |
| `wrong-disp`          | Parâmetro `DISP` inadequado no JCL         |
| `hold-job`            | Job bloqueado no JES2                      |
| `saldo-inconsistente` | Divergência na conciliação                 |
| `late-file`           | Atraso na chegada do arquivo de entrada    |
| `reprocess-required`  | Necessidade de reprocessamento de rejeitos |
| `validation-rc08`     | Falha relevante na validação               |

---

## Estrutura do repositório

```text
emunah-bank-lab/
├── cobol/batch/             # Programas COBOL batch
│   ├── EBCLLOAD.cbl         # Carga inicial de clientes e contas
│   ├── EBVALI01.cbl         # Validação de lançamentos
│   ├── EBPOST01.cbl         # Aplicação de lançamentos
│   ├── EBSALD01.cbl         # Consolidação de saldo
│   ├── EBEXTR01.cbl         # Geração de extrato
│   ├── EBCONC01.cbl         # Conciliação
│   └── EBREPR01.cbl         # Reprocessamento de rejeitos
├── copybooks/layouts/       # Copybooks e layouts de registro
├── jcl/
│   ├── compile/             # JCLs de compilação e link-edit
│   └── batch/               # JCLs da cadeia batch
├── rexx/util/               # Scripts REXX de automação
├── data/entrada/            # Massa de entrada e seeds
└── docs/                    # Documentação técnica
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

## Mapa de datasets

### Bibliotecas de desenvolvimento

```text
<HLQ>.EMUNAH.DEV.COBOL      → Fontes COBOL
<HLQ>.EMUNAH.DEV.COPY       → Copybooks e layouts
<HLQ>.EMUNAH.DEV.JCL        → JCLs de compilação e execução
<HLQ>.EMUNAH.DEV.REXX       → Scripts REXX
<HLQ>.EMUNAH.DEV.LOADLIB    → Executáveis do build
```

### Arquivos de negócio

```text
<HLQ>.EMUNAH.ARQ.CLIENTE.KSDS   → Cadastro master de clientes
<HLQ>.EMUNAH.ARQ.CONTA.KSDS     → Cadastro master de contas
<HLQ>.EMUNAH.ARQ.SALDO.KSDS     → Saldo consolidado por conta
<HLQ>.EMUNAH.ARQ.LANCTO.ESDS    → Lançamentos aprovados (append-only)
<HLQ>.EMUNAH.ARQ.ENTRADA.SEQ    → Arquivo de entrada do dia
<HLQ>.EMUNAH.ARQ.REJEITO.SEQ    → Registros rejeitados
<HLQ>.EMUNAH.ARQ.AUDIT.SEQ      → Trilha de auditoria
<HLQ>.EMUNAH.ARQ.EXTRATO.GDG    → Histórico de extratos
```

---

## Como executar

### Pré-requisitos

* Conta ativa no IBM zXplore
* VS Code com extensão Zowe Explorer
* Zowe CLI 7.x+
* Emulador TN3270
* Git

### Setup

```bash
# 1. Clone o repositório
git clone https://github.com/<seu-usuario>/emunah-bank-lab.git
cd emunah-bank-lab

# 2. Configure o perfil Zowe
zowe config init
zowe config set profiles.zosmf.properties.host <host-zxplore>
zowe config set profiles.zosmf.properties.port 443
zowe config set profiles.zosmf.properties.user <seu-userid>
zowe config set profiles.zosmf.properties.password <sua-senha>
zowe config set profiles.zosmf.properties.rejectUnauthorized false

# 3. Teste a conexão
zowe zosmf check status

# 4. Publique os fontes no mainframe
zowe files upload dir-to-pds ./copybooks/layouts "<HLQ>.EMUNAH.DEV.COPY"
zowe files upload dir-to-pds ./cobol/batch      "<HLQ>.EMUNAH.DEV.COBOL"
zowe files upload dir-to-pds ./jcl/compile      "<HLQ>.EMUNAH.DEV.JCL"
zowe files upload dir-to-pds ./jcl/batch        "<HLQ>.EMUNAH.DEV.JCL"
zowe files upload dir-to-pds ./rexx/util        "<HLQ>.EMUNAH.DEV.REXX"

# 5. Compile e execute o build
zowe jobs submit data-set "<HLQ>.EMUNAH.DEV.JCL(EBBUILD)"
zowe jobs list jobs --owner <seu-userid>

# 6. Envie o arquivo de entrada do dia
zowe files upload file-to-data-set \
  ./data/entrada/lancamentos.txt \
  "<HLQ>.EMUNAH.ARQ.ENTRADA.SEQ" --binary

# 7. Submeta a cadeia batch
zowe jobs submit data-set "<HLQ>.EMUNAH.DEV.JCL(EBJLOAD)"
```

---

## Evidências recomendadas

Para reforçar o caráter prático do laboratório, este repositório pode incluir evidências como:

* spool de execução com RC e resumo do processamento;
* screenshot de job no Zowe Explorer ou SDSF;
* exemplo de arquivo de entrada;
* exemplo de registro rejeitado;
* exemplo de extrato gerado;
* evidência de conciliação e fechamento.

---

## Documentação

| Documento                                              | Conteúdo                                   |
| ------------------------------------------------------ | ------------------------------------------ |
| [Visão Geral](docs/01-visao-geral.md)                  | Objetivo, escopo e contexto do laboratório |
| [Arquitetura](docs/02-arquitetura.md)                  | Camadas, ferramentas e fluxo de integração |
| [Módulos](docs/03-modulos.md)                          | Programas, responsabilidades e datasets    |
| [Mapa de Datasets](docs/04-mapa-datasets.md)           | Datasets, tipos, DDNAMEs e finalidades     |
| [Grade Batch](docs/05-grade-batch.md)                  | Cadeia de jobs, dependências e critérios   |
| [Runbooks](docs/06-runbooks.md)                        | Procedimentos de diagnóstico e correção    |
| [Cenários de Incidente](docs/07-cenarios-incidente.md) | Cenários controlados para troubleshooting  |
| [Fluxo Zowe](docs/08-fluxo-zowe.md)                    | Integração local ↔ mainframe               |
| [Padrões de Publicação](docs/09-padroes-publicacao.md) | Regras de promoção entre ambientes         |

---

## Sobre o nome

*Emunah* (אֱמוּנָה) vem do hebraico e significa **fidelidade** e **confiança** — qualidades centrais tanto no setor bancário quanto nos sistemas mainframe, conhecidos por estabilidade, rastreabilidade e disponibilidade.

---

## Licença

Projeto de uso pessoal e educacional, com finalidade de prática técnica, documentação e portfólio. 

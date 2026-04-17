# Mapa de Datasets — Emunah Bank Lab

## Convenção de Nomenclatura

Todos os datasets seguem o padrão:
```
<HLQ>.<PROJETO>.<AMBIENTE>.<TIPO/FUNÇÃO>
```

- **HLQ:** `<HLQ>` (userid no zXplore)
- **PROJETO:** `EMUNAH`
- **AMBIENTE:** `DEV`, `HML`, `PRD`, `ARQ` (negócio) ou `SEED` (carga inicial)

---

## Bibliotecas de Desenvolvimento (DEV)

| Dataset                      | Tipo     | Membros principais                                              | Finalidade                            |
|------------------------------|----------|-----------------------------------------------------------------|---------------------------------------|
| `<HLQ>.EMUNAH.DEV.COBOL`    | PDS/PDSE | EBCLLOAD, EBVALI01, EBPOST01, EBSALD01, EBEXTR01, EBCONC01, EBREPR01, EBJEOD01 | Fontes COBOL de desenvolvimento |
| `<HLQ>.EMUNAH.DEV.COPY`     | PDS/PDSE | CPAUD001, CPCLI001, CPCNT001, CPLCT001, CPSLD001               | Copybooks e layouts de registro       |
| `<HLQ>.EMUNAH.DEV.JCL`      | PDS/PDSE | EBJPRECK, EBJBACKP, EBJLOAD, EBJVALD, EBJPOST, EBJSALD, EBJEXTR, EBJCONC, EBJEOD, EBJREPR, EBSEED | JCLs de compilação e execução em DEV |
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

## Arquivos de Seed (Carga Inicial)

Estes arquivos contêm a massa de dados real utilizada para população inicial dos VSAM via job `EBSEED`. **Não são placeholders** — os registros estão completos e prontos para execução.

| Dataset                           | Tipo | DDNAME     | Registros | Finalidade                        |
|-----------------------------------|------|------------|-----------|-----------------------------------|
| `<HLQ>.EMUNAH.SEED.CLIENTES.SEQ` | PS   | `CLIENTIN` | 20        | Massa inicial de clientes         |
| `<HLQ>.EMUNAH.SEED.CONTAS.SEQ`   | PS   | `CONTAIN`  | 40        | Massa inicial de contas (2/cliente) |

### Clientes cadastrados (20 registros)

| Nº | Nome               | CPF fictício  | Dt. Nascimento | Dt. Abertura |
|----|--------------------|---------------|----------------|--------------|
| 01 | João Silva         | 12345678901   | 01/01/1990     | 12/03/2026   |
| 02 | Maria Souza        | 12345678902   | 15/02/1985     | 12/03/2026   |
| 03 | Pedro Santos       | 12345678903   | 10/03/1992     | 12/03/2026   |
| 04 | Ana Costa          | 12345678904   | 11/04/1988     | 12/03/2026   |
| 05 | Carla Moraes       | 12345678905   | 09/05/1991     | 12/03/2026   |
| 06 | Lucas Barbosa      | 12345678906   | 12/06/1987     | 12/03/2026   |
| 07 | Bruno Lima         | 12345678907   | 18/07/1990     | 12/03/2026   |
| 08 | Paula Almeida      | 12345678908   | 23/08/1986     | 12/03/2026   |
| 09 | Renata Araujo      | 12345678909   | 14/09/1993     | 12/03/2026   |
| 10 | Fábio Pereira      | 12345678910   | 11/10/1989     | 12/03/2026   |
| 11 | Marta Fernandes    | 12345678911   | 03/11/1984     | 12/03/2026   |
| 12 | Gustavo Rocha      | 12345678912   | 07/12/1990     | 12/03/2026   |
| 13 | Juliana Teixeira   | 12345678913   | 12/01/1991     | 12/03/2026   |
| 14 | Thiago Ribeiro     | 12345678914   | 18/02/1987     | 12/03/2026   |
| 15 | Fernanda Melo      | 12345678915   | 05/03/1992     | 12/03/2026   |
| 16 | Daniel Oliveira    | 12345678916   | 22/04/1988     | 12/03/2026   |
| 17 | Amanda Martins     | 12345678917   | 17/05/1989     | 12/03/2026   |
| 18 | Rodrigo Nunes      | 12345678918   | 26/06/1986     | 12/03/2026   |
| 19 | Camila Gomes       | 12345678919   | 10/07/1990     | 12/03/2026   |
| 20 | Rafael Duarte      | 12345678920   | 19/08/1991     | 12/03/2026   |

### Estrutura de contas (40 registros)

Cada cliente possui duas contas:
- **Conta Corrente (C):** número de conta par, DDNAME `CONTAIN`
- **Poupança (P):** número de conta ímpar, DDNAME `CONTAIN`

Saldos iniciais variam de R$ 1.100,00 (contas 1–2) a R$ 4.000,00 (contas 39–40), com limite de crédito fixo de R$ 5.000,00 para todas as contas.

---

## Arquivos de Negócio (ARQ)

| Dataset                            | Tipo      | Org.  | DDNAME    | Finalidade                                        |
|------------------------------------|-----------|-------|-----------|---------------------------------------------------|
| `<HLQ>.EMUNAH.ARQ.CLIENTE.KSDS`   | VSAM      | KSDS  | `CLIENTE` | Cadastro master de clientes (chave: nº cliente)   |
| `<HLQ>.EMUNAH.ARQ.CONTA.KSDS`     | VSAM      | KSDS  | `CONTA`   | Cadastro master de contas (chave: nº conta)       |
| `<HLQ>.EMUNAH.ARQ.SALDO.KSDS`     | VSAM      | KSDS  | `SALDO`   | Saldo consolidado por conta                       |
| `<HLQ>.EMUNAH.ARQ.LANCTO.ESDS`    | VSAM      | ESDS  | `VALIDOS` | Lançamentos aprovados (append-only, imutável)     |
| `<HLQ>.EMUNAH.ARQ.ENTRADA.SEQ`    | PS        | SEQ   | `ENTRADA` | Arquivo de lançamentos do dia (entrada batch)     |
| `<HLQ>.EMUNAH.ARQ.REJEITO.SEQ`    | PS        | SEQ   | `REJEITO` | Registros rejeitados na validação ou aplicação    |
| `<HLQ>.EMUNAH.ARQ.AUDIT.SEQ`      | PS        | SEQ   | `AUDIT`   | Trilha de auditoria e mensagens de log            |
| `<HLQ>.EMUNAH.ARQ.EXTRATO.GDG`    | GDG Base  | —     | —         | Base GDG para histórico de extratos por geração   |

---

## Mapa Visual

O arquivo [`mapa-emunah-bank-lab.html`](mapa-emunah-bank-lab.html) consolida todos os datasets acima em um painel interativo navegável com abas por categoria (DEV, HML, PRD, ARQ, SEED), exibindo tipos, DDNAMEs, fluxos e dependências entre artefatos. Abre diretamente no navegador.

---

## Observações

- `ARQ.LANCTO.ESDS` usa organização ESDS (sequential append-only) por design — representa o histórico imutável de movimentos do dia
- `ARQ.EXTRATO.GDG` gera uma nova geração (`G000xV00`) a cada execução do job `EBJEXTR`
- Os arquivos KSDS devem ser alocados via IDCAMS antes da primeira execução de qualquer job que os utilize
- O prefixo `<HLQ>` corresponde ao userid do ambiente zXplore e deve ser ajustado se o lab migrar para outro ambiente
- Os dados seed são ficcionais e não contêm informações pessoais reais
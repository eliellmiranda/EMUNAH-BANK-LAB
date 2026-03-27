# Modelo Funcional do Emunah Lab

## Objetivo

Este documento é a referência técnica central do laboratório. Ele reúne módulos, programas, datasets, grade batch, arquitetura e casos de teste do projeto real.

---

## Visão do laboratório

O Emunah Bank Lab simula um mini ambiente bancário mainframe com:

- aplicações COBOL com módulos funcionais definidos
- execução batch com cadeia encadeada e dependências
- persistência em VSAM (KSDS, ESDS) e arquivos sequenciais
- GDG para histórico de extratos
- trilha de auditoria
- runbooks e cenários de incidente
- fluxo de desenvolvimento local → remoto via Zowe
- documentação corporativa
- portfólio profissional

---

## Arquitetura do laboratório

### Três camadas

| Camada | Ambiente | Ferramentas | Responsabilidade |
|---|---|---|---|
| Local | Computador pessoal | VS Code, Zowe CLI, Zowe Explorer, Git | Edição, documentação, versionamento |
| Remota | IBM zXplore (z/OS) | JES2, ISPF, SDSF, IDCAMS, compilador COBOL | Datasets, compilação, execução batch |
| Operação | Emulador TN3270 | ISPF, SDSF, TSO | Troubleshooting aprofundado |

### Regras de camada

- o ambiente local é a fonte primária do código e documentação
- o ambiente remoto é a área de build e execução
- o 3270 é a ferramenta de operação e diagnóstico, não de edição
- correções permanentes devem ser feitas no local e republicadas
- ambientes DEV, HML e PRD são separados por convenção de nome de dataset

---

## Módulos do sistema

### cliente
Cadastro e manutenção dos dados de clientes.
- Programa: `EBCLLOAD`
- Dataset master: `Z77948.EMUNAH.ARQ.CLIENTE.KSDS`
- Seed: `Z77948.EMUNAH.SEED.CLIENTES.SEQ`

### conta
Cadastro e manutenção das contas bancárias.
- Programa: `EBCLLOAD`
- Dataset master: `Z77948.EMUNAH.ARQ.CONTA.KSDS`
- Seed: `Z77948.EMUNAH.SEED.CONTAS.SEQ`

### lançamentos
Recebimento, validação e aplicação dos movimentos financeiros.
- Programas: `EBVALI01` (validação), `EBPOST01` (aplicação)
- Jobs: `EBJVALD`, `EBJPOST`
- Entrada: `Z77948.EMUNAH.ARQ.ENTRADA.SEQ`
- Aprovados: `Z77948.EMUNAH.ARQ.LANCTO.ESDS`
- Rejeitos: `Z77948.EMUNAH.ARQ.REJEITO.SEQ`

### saldo
Consolidação do saldo por conta.
- Programa: `EBSALD01`
- Job: `EBJSALD`
- Dataset: `Z77948.EMUNAH.ARQ.SALDO.KSDS`

### extrato
Geração do extrato diário por conta.
- Programa: `EBEXTR01`
- Job: `EBJEXTR`
- Dataset: `Z77948.EMUNAH.ARQ.EXTRATO.GDG` (nova geração por execução)

### conciliação
Comparação de totais de entrada, registros aplicados e saldos finais.
- Programa: `EBCONC01`
- Job: `EBJCONC`
- Portão de controle: o dia não fecha se a conciliação não fechar.

### fechamento
Encerramento do dia operacional.
- Job: `EBJEOD`
- Depende de conciliação aprovada.

### rejeito
Registros que não passaram na validação ou aplicação.
- Dataset: `Z77948.EMUNAH.ARQ.REJEITO.SEQ`
- Gerado por: `EBVALI01`, `EBPOST01`

### reprocessamento
Reaplicação de registros corrigidos.
- Programa: `EBREPR01`
- Job: `EBJREPR`
- Fora da cadeia principal, sob demanda.

---

## Mapa de datasets

### Convenção de nomenclatura
```
<HLQ>.<PROJETO>.<AMBIENTE>.<TIPO/FUNÇÃO>
```
- HLQ: `Z77948` (userid no zXplore)
- PROJETO: `EMUNAH`
- AMBIENTE: `DEV`, `HML`, `PRD` ou `ARQ`

### Bibliotecas de desenvolvimento (DEV)

| Dataset | Tipo | Finalidade |
|---|---|---|
| `Z77948.EMUNAH.DEV.COBOL` | PDS/PDSE | Fontes COBOL |
| `Z77948.EMUNAH.DEV.COPY` | PDS/PDSE | Copybooks e layouts |
| `Z77948.EMUNAH.DEV.JCL` | PDS/PDSE | JCLs de compilação e execução |
| `Z77948.EMUNAH.DEV.REXX` | PDS/PDSE | Scripts REXX |
| `Z77948.EMUNAH.DEV.LOADLIB` | PDS/PDSE | Executáveis do build |

### Bibliotecas de homologação (HML)

| Dataset | Tipo | Finalidade |
|---|---|---|
| `Z77948.EMUNAH.HML.COBOL` | PDS/PDSE | Fontes promovidos |
| `Z77948.EMUNAH.HML.JCL` | PDS/PDSE | JCLs de execução |
| `Z77948.EMUNAH.HML.LOADLIB` | PDS/PDSE | Executáveis compilados |

### Bibliotecas de produção simulada (PRD)

| Dataset | Tipo | Finalidade |
|---|---|---|
| `Z77948.EMUNAH.PRD.JCL` | PDS/PDSE | JCLs de execução |
| `Z77948.EMUNAH.PRD.LOADLIB` | PDS/PDSE | Executáveis de produção |
| `Z77948.EMUNAH.PRD.PARMLIB` | PDS/PDSE | Parâmetros e configuração |

### Arquivos de seed

| Dataset | DDNAME | Finalidade |
|---|---|---|
| `Z77948.EMUNAH.SEED.CLIENTES.SEQ` | `CLIENTIN` | Massa inicial de clientes |
| `Z77948.EMUNAH.SEED.CONTAS.SEQ` | `CONTAIN` | Massa inicial de contas |

### Arquivos de negócio (ARQ)

| Dataset | Org. | DDNAME | Finalidade |
|---|---|---|---|
| `Z77948.EMUNAH.ARQ.CLIENTE.KSDS` | KSDS | `CLIENTE` | Cadastro master de clientes |
| `Z77948.EMUNAH.ARQ.CONTA.KSDS` | KSDS | `CONTA` | Cadastro master de contas |
| `Z77948.EMUNAH.ARQ.SALDO.KSDS` | KSDS | `SALDO` | Saldo consolidado por conta |
| `Z77948.EMUNAH.ARQ.LANCTO.ESDS` | ESDS | `VALIDOS` | Lançamentos aprovados (append-only) |
| `Z77948.EMUNAH.ARQ.ENTRADA.SEQ` | SEQ | `ENTRADA` | Arquivo de entrada batch do dia |
| `Z77948.EMUNAH.ARQ.REJEITO.SEQ` | SEQ | `REJEITO` | Registros rejeitados |
| `Z77948.EMUNAH.ARQ.AUDIT.SEQ` | SEQ | `AUDIT` | Trilha de auditoria |
| `Z77948.EMUNAH.ARQ.EXTRATO.GDG` | GDG | — | Histórico de extratos |

### Observações técnicas

- `ARQ.LANCTO.ESDS` usa ESDS por design — histórico imutável de movimentos do dia
- `ARQ.EXTRATO.GDG` gera nova geração (`G000xV00`) a cada execução de `EBJEXTR`
- arquivos KSDS devem ser alocados via IDCAMS antes da primeira execução
- o prefixo `Z77948` corresponde ao userid do zXplore e deve ser ajustado se o lab migrar

---

## Grade batch

### Janela batch simulada

| Horário | Job | Programa | Papel |
|---|---|---|---|
| 06:00 | `PRECHECK` | — | Valida pré-condições do ambiente |
| 06:15 | `EBBACKUP` | — | Registra estado anterior |
| 06:30 | `EBJLOAD` | — | Prepara arquivo do dia |
| 07:00 | `EBJVALD` | `EBVALI01` | Valida layout e regras de negócio |
| 07:30 | `EBJPOST` | `EBPOST01` | Aplica lançamentos válidos |
| 08:00 | `EBJSALD` | `EBSALD01` | Consolida saldos |
| 09:00 | `EBJEXTR` | `EBEXTR01` | Gera extratos |
| 09:30 | `EBJCONC` | `EBCONC01` | Faz conciliação |
| 10:00 | `EBJEOD` | — | Fechamento diário |
| Sob demanda | `EBJREPR` | `EBREPR01` | Reprocessa rejeitos corrigidos |

### Encadeamento

```
PRECHECK → EBBACKUP → EBJLOAD → EBJVALD → EBJPOST → EBJSALD → EBJEXTR → EBJCONC → EBJEOD
```

`EBJREPR` é independente da cadeia principal.

### Dependências

Cada job depende do anterior. `EBJEOD` só executa após `EBJCONC` aprovado.

### Regras de bloqueio

A cadeia deve ser interrompida quando ocorrer:
- ausência do arquivo de entrada
- erro crítico na validação
- falha inconsistente na aplicação
- divergência de conciliação

### Critérios de sucesso do dia

- arquivo de entrada recebido corretamente
- registros válidos processados
- rejeitos gravados com consistência
- saldos consolidados
- extrato gerado
- conciliação correta
- fechamento concluído

---

## Runbooks operacionais (resumo)

O lab possui runbooks para 7 incidentes. Cada um segue a estrutura: sintoma → causa provável → diagnóstico → ação corretiva → reprocessamento → evidências.

1. arquivo de entrada ausente → `EBJLOAD` falha → reenviar arquivo e reexecutar
2. layout inválido → `EBJVALD` com rejeitos → corrigir arquivo e reexecutar
3. conta inexistente → rejeição na validação ou aplicação → corrigir massa ou carga
4. falha na aplicação → `EBJPOST` falha → corrigir programa ou massa, verificar consistência
5. falha de conciliação → `EBJCONC` divergente → localizar divergência e corrigir origem
6. job em hold → job parado → liberar ou corrigir dependência
7. reprocessamento de rejeitos → massa corrigida → executar `EBJREPR`

---

## Cenários de incidente controlados (resumo)

10 cenários prontos para prática:
- `normal-day` — execução completa sem falhas
- `missing-input` — ausência do arquivo de entrada
- `invalid-layout` — layout incorreto
- `duplicate-key` — gravação duplicada em KSDS
- `wrong-disp` — parâmetro de alocação inadequado
- `hold-job` — job bloqueado
- `saldo-inconsistente` — divergência de conciliação
- `late-file` — atraso na chegada do arquivo
- `reprocess-required` — reaplicação de rejeitos
- `validation-rc08` — falha de validação relevante

---

## Casos de teste mínimos

### Caso 1 — carga válida
Esperado: cliente criado, conta criada, auditoria gravada.

### Caso 2 — carga inválida
Esperado: rejeito com motivo, auditoria gravada, sem conta criada.

### Caso 3 — depósito válido
Esperado: movimento gravado, saldo atualizado, extrato atualizado, auditoria gravada.

### Caso 4 — saque sem saldo
Esperado: rejeito ou negação, saldo preservado, auditoria gravada.

### Caso 5 — fechamento do dia
Esperado: conciliação executada, relatório gerado, posição coerente, evidência de processamento.

### Caso 6 — reprocessamento de rejeitos
Esperado: massa corrigida reaplicada, totais ajustados, evidência antes e depois.

---

## Evidências que o projeto deve sempre produzir

- massa de entrada
- JCL
- spool ou simulação de evidência
- saída gerada
- rejeitos
- auditoria
- explicação técnica
- explicação funcional
- decisão sobre reprocessamento quando aplicável

---

## Como este modelo vira portfólio

Cada entrega do laboratório deve provar:
- conhecimento técnico com as ferramentas reais do z/OS
- entendimento de operação bancária
- visão de produção com cadeia batch completa
- capacidade de troubleshooting com runbooks e cenários
- capacidade de documentação
- maturidade de raciocínio sobre legado com visão de modernização

---

## Resultado esperado

Se este modelo for seguido, o Emunah Lab terá:
- escopo controlado com módulos definidos
- coerência de domínio bancário
- aderência ao mercado de mainframe
- base forte para crescer sem perder foco

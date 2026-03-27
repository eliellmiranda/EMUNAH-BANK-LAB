# Mainframe na Prática Aplicado ao Emunah Lab

## Objetivo

Este documento define como o ambiente mainframe deve ser tratado no laboratório: não como teoria abstrata, mas como ambiente operacional real de aplicações.

---

## Princípio central

No Emunah Lab, mainframe deve ser entendido em quatro dimensões:

1. desenvolver
2. executar
3. manter
4. evoluir

---

## 1. Desenvolver

O laboratório demonstra construção de aplicações, não só leitura de conceito.

### O que isso significa na prática

- escrever programas COBOL com estrutura empresarial
- usar copybooks para layouts compartilhados
- tratar entrada, saída, rejeito e auditoria
- lidar com VSAM (KSDS, ESDS) e arquivos sequenciais
- documentar regras de negócio
- separar regra de negócio de controle de fluxo
- prever tratamento de erro e file status
- usar REXX para automação operacional

### Programas reais do lab

- `EBCLLOAD` — carga de clientes e contas
- `EBVALI01` — validação de lançamentos
- `EBPOST01` — aplicação de lançamentos
- `EBSALD01` — consolidação de saldo
- `EBEXTR01` — geração de extrato
- `EBCONC01` — conciliação
- `EBREPR01` — reprocessamento de rejeitos

---

## 2. Executar

Aplicação mainframe não termina no código. Ela precisa ser compilada, ligada, executada e controlada.

### O que isso significa na prática

- JCL de compile (`EBCOMP`), link (`EBLINK`) e build (`EBBUILD`)
- cadeia batch com 10 jobs encadeados e dependências explícitas
- janela batch simulada com horários definidos
- entradas e saídas definidas por dataset
- RC analisado
- spool revisado
- regras de bloqueio por falha

### Cadeia batch do lab

```
PRECHECK → EBBACKUP → EBJLOAD → EBJVALD → EBJPOST → EBJSALD → EBJEXTR → EBJCONC → EBJEOD
```

Job fora da cadeia: `EBJREPR` (reprocessamento sob demanda).

### Elementos que o lab trata

- JOB, EXEC, DD, DISP
- STEPLIB e LOADLIB (`DEV.LOADLIB`, `HML.LOADLIB`, `PRD.LOADLIB`)
- SYSOUT e SYSIN
- datasets sequenciais, PDS/PDSE, GDG, VSAM
- RC e erro de etapa
- promoção entre ambientes: DEV → HML → PRD

---

## 3. Manter

Ambiente corporativo real exige sustentação.

### O que isso significa na prática

- interpretar erro
- analisar spool
- identificar falha de JCL, arquivo, SQL ou layout
- investigar impacto
- produzir runbook
- descrever causa, correção e prevenção
- decidir sobre reprocessamento

### Incidentes documentados no lab

O laboratório possui runbooks para 7 tipos de incidente:
- arquivo de entrada ausente
- layout inválido no arquivo de entrada
- conta inexistente ou inválida
- falha na aplicação de lançamentos
- falha de conciliação
- job em hold ou não executado
- reprocessamento de rejeitos

### Cenários de incidente controlados

10 cenários prontos para prática de troubleshooting:
- `normal-day` — execução sem falhas
- `missing-input` — ausência do arquivo de entrada
- `invalid-layout` — layout incorreto
- `duplicate-key` — gravação duplicada em KSDS
- `wrong-disp` — parâmetro inadequado de alocação
- `hold-job` — job bloqueado
- `saldo-inconsistente` — divergência de conciliação
- `late-file` — atraso na chegada do arquivo
- `reprocess-required` — reaplicação de rejeitos
- `validation-rc08` — falha de validação relevante

### Regra geral de evidências

Sempre que ocorrer uma falha, preservar: nome do job, horário, RC, spool principal, datasets afetados, ação executada e decisão sobre reprocessamento.

---

## 4. Evoluir

O laboratório mostra que o legado pode conviver com práticas modernas.

### O que isso significa na prática

- documentação forte e versionada
- integração conceitual com APIs
- uso de Zowe CLI e Zowe Explorer como ponte local → remoto
- versionamento com Git/GitHub
- automação com scripts e REXX
- visão de modernização sem quebrar o núcleo do sistema

### Arquitetura de três camadas do lab

- **Camada local** — VS Code, Zowe CLI, Git: edição, documentação, controle de versão
- **Camada remota** — z/OS (zXplore): datasets, compilação, execução batch, spool
- **Camada 3270** — ISPF, SDSF, TSO: operação clássica, troubleshooting aprofundado

O Zowe atua como ponte entre o local e o remoto.

### Fluxo de trabalho padrão

1. editar arquivos localmente no VS Code
2. publicar no mainframe via Zowe CLI ou Explorer
3. conferir membros e datasets remotos
4. submeter o JCL correspondente
5. acompanhar status, RC e spool
6. aprofundar investigação no 3270 quando necessário
7. corrigir localmente, republicar e repetir o ciclo

### Padrões de publicação

O lab possui mapeamento definido entre pastas locais e datasets remotos:

| Pasta local | Dataset remoto |
|---|---|
| `copybooks/layouts/` | `Z77948.EMUNAH.DEV.COPY` |
| `cobol/batch/` | `Z77948.EMUNAH.DEV.COBOL` |
| `jcl/compile/` e `jcl/batch/` | `Z77948.EMUNAH.DEV.JCL` |
| `rexx/util/` | `Z77948.EMUNAH.DEV.REXX` |
| `data/entrada/` | `Z77948.EMUNAH.ARQ.ENTRADA.SEQ` |

Regras: publicar copybook antes do fonte, nunca publicar direto em PRD sem passar por HML, correções permanentes voltam para o repositório local.

---

## Componentes técnicos no raciocínio do projeto

### COBOL
Batch, validação, processamento de registros, atualização de dados, geração de saídas.

### JCL
Compile, link, run, utilitários, cadeia batch com dependência.

### DB2
Entidades persistentes, SQL em programas, consultas e atualizações, troubleshooting.

### CICS
Visão de online transacional, separação entre consulta online e consolidação batch.

### VSAM e arquivos
KSDS para masters, ESDS para histórico append-only, sequenciais para entrada/saída/rejeito/auditoria, GDG para extratos.

### TSO / ISPF
Referência operacional: membros, bibliotecas, edição, submissão, navegação técnica.

### Scheduler
Visão de produção: cadeia, ordem de execução, dependência lógica, janelas, controle operacional.

### REXX
Automação de tarefas utilitárias, manipulação de datasets, validações operacionais.

### Zowe
Ponte entre desenvolvimento local e execução remota: publicação, submissão, consulta de spool.

---

## Relação entre batch e online

- nem tudo é online, nem tudo é batch
- o banco normalmente combina ambos
- online atende interação imediata
- batch consolida, fecha, organiza, recalcula, integra, reconcilia e audita

---

## Checklist técnico para qualquer nova entrega

- há programa COBOL?
- há JCL de compile e execução?
- há dados de entrada e saída?
- há tratamento de erro e file status?
- há RC esperado documentado?
- há evidência no spool?
- há rejeito quando necessário?
- há auditoria quando necessário?
- há documentação funcional e técnica?
- há caso de teste?
- há copybook compartilhado quando aplicável?
- o fluxo de publicação local → remoto está definido?
- há runbook para os cenários de falha previsíveis?

---

## Resultado esperado

Se o laboratório seguir este documento, ele demonstra:
- prática realista de aplicações mainframe
- visão de execução e produção
- maturidade de sustentação
- operação moderna com Zowe sem abandonar o z/OS
- base para modernização sem perder o centro técnico

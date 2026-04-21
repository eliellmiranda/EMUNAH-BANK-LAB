# [03] - MÓDULOS DO SISTEMA - EMUNAH BANK LAB

## Visão Geral

O sistema é dividido em módulos funcionais que refletem as responsabilidades de um ambiente bancário batch. Cada módulo agrupa programas, copybooks e datasets relacionados a uma função específica do negócio ou do controle operacional.

---

## cliente
Cadastro e manutenção dos dados de clientes.

- **Programa principal:** `EBCLLOAD`
- **Job de carga:** `EBJCLLD`
- **Dataset master:** `EMUNAH.ARQ.CLIENTE.KSDS`
- **Entrada de seed:** `EMUNAH.SEED.CLIENTES.SEQ`
- **Papel na cadeia:** base de referência para validação

---

## conta
Cadastro e manutenção das contas bancárias.

- **Programa principal:** `EBCLLOAD`
- **Job de carga:** `EBJCLLD`
- **Dataset master:** `EMUNAH.ARQ.CONTA.KSDS`
- **Entrada de seed:** `EMUNAH.SEED.CONTAS.SEQ`
- **Papel na cadeia:** referência obrigatória para validação, aplicação e snapshot de saldo

---

## controle (CTL.STATUS / CTL.PROCDATE)
Governa a fase operacional do dia. Fonte de verdade consultada por todos os jobs da cadeia principal.

- **Programa principal:** `EBCTL01` (utilitário de leitura/gravação)
- **Jobs que escrevem o estado:** `EBJSOD` (OPEN), `EBJCUTF` (EOTI), `EBJCUTE` (EOFI), `EBJEOD` (CLOSED)
- **Jobs que leem o estado:** `EBJPRECK` (validação de entrada da cadeia) e qualquer job que exija uma fase específica
- **Datasets:** `EMUNAH.ARQ.CTL.STATUS`, `EMUNAH.ARQ.CTL.PROCDATE`
- **Papel na cadeia:** portão de estado — o dia não anda sem passar pelas transições na ordem certa

---

## entrada (staging + file-watcher)
Recebe o arquivo do dia em staging e só promove para o mundo operacional após checagem de existência e conteúdo.

- **Jobs:** `EBJWAIT` (file-watcher), `EBJLOAD` (promoção)
- **Datasets:** `EMUNAH.STAGE.ENTRADA.SEQ` (staging), `EMUNAH.ARQ.ENTRADA.SEQ` (operacional), `EMUNAH.ARQ.ENTRADA.TRAILER.SEQ` (futuro: hash/trailer)
- **Papel na cadeia:** porta de entrada controlada, com separação clara entre "arquivo recebido" e "arquivo aceito para processar"

---

## lançamentos
Recepção, validação e aplicação dos movimentos financeiros do dia.

- **Programas:** `EBVALI01` (validação), `EBPOST01` (aplicação)
- **Jobs:** `EBJVALD`, `EBJPOST`
- **Datasets:** `EMUNAH.ARQ.ENTRADA.SEQ`, `EMUNAH.ARQ.LANCTO.ESDS` (válidos aprovados), `EMUNAH.ARQ.REJEITOS.SEQ` (rejeitos)
- **Papel na cadeia:** coração do processamento diário

---

## accrual
Cálculo de juros e tarifas do dia a partir de parâmetros configuráveis.

- **Programa principal:** `EBACCR01`
- **Entrada:** `EMUNAH.PARM.JUROS.CONFIG` (PDS com parâmetros)
- **Saída:** `EMUNAH.ARQ.ACCR.MOV.SEQ`
- **Papel na cadeia:** gera movimentos contábeis entre o cutoff financeiro (`EOTI`) e o snapshot de saldo

---

## saldo (snapshot)
Fotografa o saldo consolidado de todas as contas em uma nova geração GDG.

- **Programa principal:** `EBSNAP01`
- **Job:** `EBJSNAP`
- **Dataset:** `EMUNAH.ARQ.SALDO.GDG(+1)` — cada execução cria nova geração
- **Papel na cadeia:** substitui o antigo `SALDO.KSDS`. Entrada para `EBJCONC` e `EBJEXTR`

---

## conciliação
Compara três visões independentes (entrada, postagem, saldo) e confirma a integridade do processamento.

- **Programa principal:** `EBCONC01`
- **Job:** `EBJCONC`
- **Dataset de saída:** `EMUNAH.ARQ.CONCIL.SEQ` (LRECL=132, três seções)
- **Papel na cadeia:** portão de controle antes do fechamento — o dia não fecha se a conciliação não fechar

---

## extrato
Gera o extrato diário de cada conta com base em lançamentos postados e saldo consolidado.

- **Programa principal:** `EBEXTR01`
- **Job:** `EBJEXTR`
- **Dataset de saída:** `EMUNAH.ARQ.EXTRATO.GDG(+1)`
- **Papel na cadeia:** produto final visível do processamento do dia

---

## fechamento
Encerra o dia operacional, atualiza controles e registra o fechamento do ciclo batch.

- **Programa principal:** `EBJEOD01`
- **Job:** `EBJEOD`
- **Efeitos:** grava `CTL.STATUS=CLOSED`, finaliza trilha de auditoria do dia
- **Papel na cadeia:** último passo da cadeia principal

---

## rejeito
Registra e disponibiliza lançamentos que não passaram na validação ou na aplicação.

- **Dataset:** `EMUNAH.ARQ.REJEITOS.SEQ`
- **Gerado por:** `EBVALI01`, `EBPOST01`
- **Papel na cadeia:** saída de diagnóstico; alimenta o módulo de reprocessamento

---

## reprocessamento
Reaplica registros corrigidos que foram rejeitados em execuções anteriores.

- **Programa principal:** `EBREPR01` (preparação)
- **Jobs:** `EBJREPR` (preparação), `EBJRPOST` (postagem via `EBPOST01` lendo `REPR.LANCTO.SEQ`)
- **Datasets:** `EMUNAH.ARQ.REPR.LANCTO.SEQ`
- **Papel na cadeia:** off-cycle; executado sob demanda após correção da massa ou do programa

---

## backup
Registra o estado dos masters e da auditoria antes da cadeia do dia.

- **Job:** `EBJBCKPD`
- **Datasets de saída:** `EMUNAH.BKP.CLIENTE.GDG(+1)`, `BKP.CONTA.GDG(+1)`, `BKP.AUDIT.GDG(+1)`
- **Papel na cadeia:** permite recuperação do estado pré-batch em caso de falha na cadeia principal

---

## housekeeping
Mantém `AUDIT.SEQ`, `REJEITOS.SEQ` e as bases GDG saudáveis ao longo do tempo.

- **Jobs:**
  - `EBJHKGDG` — monitor passivo (LISTCAT das bases GDG)
  - `EBJHKAUD` — arquiva `AUDIT.SEQ` em `BKP.AUDIT.GDG(+1)` e recria vazio
  - `EBJHKREJ` — arquiva `REJEITOS.SEQ` em `BKP.REJEITOS.GDG(+1)` e recria vazio
- **Papel na cadeia:** off-cycle; evita crescimento descontrolado dos sequenciais operacionais

---

## utilitários

Programas de apoio operacional que **não pertencem à cadeia batch automática**. São executados manualmente, sob demanda, para diagnóstico, auditoria e conferência de dados.

---

### EBSALD01 — Consulta Manual de Saldo por Conta

Utilitário batch de consulta pontual ao arquivo master de contas. Permite verificar o saldo de uma ou mais contas específicas sem interferir na cadeia principal de processamento.

**Localização:** `cobol/util/EBSALD01.cbl`

**Quando usar:**
- conferência de saldo após aplicação de lançamentos
- diagnóstico de inconsistências relatadas por operação ou suporte
- validação de registros antes de um reprocessamento
- auditoria manual de contas específicas durante ou após o batch

**Arquivos envolvidos:**

| DD Name   | Dataset / Tipo            | Papel                                       |
|-----------|---------------------------|---------------------------------------------|
| `SALDIN`  | Sequencial (entrada)      | Lista de contas a consultar (agência + conta, 80 bytes) |
| `CONTA`   | `EMUNAH.ARQ.CONTA.KSDS`  | Arquivo master VSAM KSDS — fonte do saldo   |
| `SALDOUT` | Sequencial (saída)        | Relatório com saldos encontrados e rejeições |

**Layout do registro de entrada (`SALDIN`):**

```
Posição  01–04  →  Agência   (PIC 9(4))
Posição  05–12  →  Conta     (PIC 9(8))
Posição  13–80  →  FILLER    (não utilizado)
```

**Copybook utilizado:** `CPCNT001` — fornece `CNT-CHAVE` e `CNT-SALDO` a partir do registro do arquivo `CONTA-KSDS`.

**Fluxo de execução:**

1. Abre `SALDIN`, `CONTA-KSDS` e `SALDOUT`
2. Lê registros de `SALDIN` sequencialmente
3. Para cada conta lida, monta a chave composta (agência + número) e executa leitura direta no KSDS
4. Se encontrada: formata e grava linha com saldo no `SALDOUT`
5. Se não encontrada: grava linha de rejeição com identificação da conta
6. Ao fim: exibe resumo no SYSOUT e fecha os arquivos

**Saída de console (DISPLAY):**

```
*** RESUMO CONSULTA SALDOS ***
CONTAS LIDAS          : NNNNN
CONTAS ENCONTRADAS    : NNNNN
CONTAS NAO ENCONTRADAS: NNNNN
```

**Contadores internos:**

| Campo                | Descrição                               |
|----------------------|-----------------------------------------|
| `WS-LIDOS`           | Total de registros lidos do `SALDIN`    |
| `WS-ENCONTRADOS`     | Contas localizadas no KSDS              |
| `WS-NAO-ENCONTRADOS` | Contas não encontradas (rejeições)      |

**Observações importantes:**
- Programa **somente leitura** — não altera nenhum registro no arquivo master de contas
- Não possui job automático associado; deve ser submetido manualmente com JCL próprio
- O arquivo `SALDIN` deve ser preparado antes da execução com as contas que se deseja consultar
- A saída `SALDOUT` substitui qualquer versão anterior a cada execução (OPEN OUTPUT)

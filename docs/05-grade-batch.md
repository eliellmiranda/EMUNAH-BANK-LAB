# Grade Batch — Emunah Bank Lab

## Objetivo

Este documento descreve a cadeia batch principal do laboratório: ordem de execução dos jobs, dependências, arquivos de entrada e saída, regras de bloqueio e critérios de sucesso do dia.

A ideia é simular uma rotina bancária diária com comportamento previsível, dependências explícitas e possibilidade de investigação controlada em caso de falha.

---

## Visão geral do processamento

A cadeia batch representa o processamento diário do laboratório, cobrindo:

- recepção do arquivo de entrada
- validação de layout e regras de negócio
- aplicação dos lançamentos
- consolidação de saldo
- geração de extratos
- conciliação de resultados
- fechamento do dia
- reprocessamento sob demanda

---

## Janela batch simulada

| Horário | Job | Papel |
|---|---|---|
| 06:00 | `PRECHECK` | valida pré-condições do ambiente |
| 06:15 | `EBBACKUP` | registra o estado anterior |
| 06:30 | `EBJLOAD` | prepara o arquivo do dia |
| 07:00 | `EBJVALD` | valida layout e regras de negócio |
| 07:30 | `EBJPOST` | aplica os lançamentos válidos |
| 08:00 | `EBJSALD` | consolida os saldos |
| 09:00 | `EBJEXTR` | gera os extratos |
| 09:30 | `EBJCONC` | faz a conciliação |
| 10:00 | `EBJEOD` | realiza o fechamento diário |
| Sob demanda | `EBJREPR` | reprocessa rejeitos corrigidos |

---

## Encadeamento principal

```text
PRECHECK
  -> EBBACKUP
  -> EBJLOAD
  -> EBJVALD
  -> EBJPOST
  -> EBJSALD
  -> EBJEXTR
  -> EBJCONC
  -> EBJEOD

Fora da cadeia normal:
EBJREPR
```

---

## Descrição dos jobs

### `PRECHECK`
Verifica se o ambiente está pronto para execução: existência de bibliotecas principais, presença do arquivo de entrada e integridade mínima do contexto operacional.

### `EBBACKUP`
Registra o estado anterior do ambiente para permitir análise ou recuperação em caso de falha durante a cadeia.

### `EBJLOAD`
Prepara o arquivo de entrada do dia a partir de `<HLQ>.EMUNAH.ARQ.ENTRADA.SEQ`.

### `EBJVALD`
Executa o programa `EBVALI01`, validando layout do arquivo e regras básicas de negócio, como conta válida, tipo de lançamento, valor positivo e preenchimento obrigatório.

### `EBJPOST`
Executa o programa `EBPOST01`, aplicando os lançamentos válidos, atualizando contas e gravando movimentos aprovados.

### `EBJSALD`
Executa `EBSALD01` para consolidar os saldos por conta após a aplicação dos lançamentos.

### `EBJEXTR`
Executa `EBEXTR01` para gerar uma nova geração de extrato em `<HLQ>.EMUNAH.ARQ.EXTRATO.GDG`.

### `EBJCONC`
Executa `EBCONC01` para comparar totais de entrada, aplicação e saldo final.

### `EBJEOD`
Realiza o fechamento diário, encerrando o ciclo operacional.

### `EBJREPR`
Executa `EBREPR01` para reaplicar rejeitos corrigidos. Não faz parte da cadeia normal e só deve ser acionado sob demanda.

---

## Dependências

- `EBBACKUP` depende de `PRECHECK`
- `EBJLOAD` depende de `EBBACKUP`
- `EBJVALD` depende de `EBJLOAD`
- `EBJPOST` depende de `EBJVALD`
- `EBJSALD` depende de `EBJPOST`
- `EBJEXTR` depende de `EBJSALD`
- `EBJCONC` depende de `EBJEXTR`
- `EBJEOD` depende de `EBJCONC`
- `EBJREPR` é independente da cadeia principal

---

## Regras de bloqueio

A cadeia deve ser interrompida quando ocorrer pelo menos uma das condições abaixo:

- ausência do arquivo de entrada
- erro crítico na validação
- falha inconsistente na aplicação de lançamentos
- divergência de conciliação

O job de reprocessamento **não substitui** a execução normal do dia. Ele apenas trata rejeitos já conhecidos e corrigidos.

---

## Datasets principais da cadeia

- `<HLQ>.EMUNAH.ARQ.ENTRADA.SEQ`
- `<HLQ>.EMUNAH.ARQ.REJEITO.SEQ`
- `<HLQ>.EMUNAH.ARQ.AUDIT.SEQ`
- `<HLQ>.EMUNAH.ARQ.CLIENTE.KSDS`
- `<HLQ>.EMUNAH.ARQ.CONTA.KSDS`
- `<HLQ>.EMUNAH.ARQ.LANCTO.ESDS`
- `<HLQ>.EMUNAH.ARQ.SALDO.KSDS`
- `<HLQ>.EMUNAH.ARQ.EXTRATO.GDG`

---

## Critérios de sucesso do dia

O dia é considerado bem-sucedido quando:

- o arquivo de entrada foi recebido corretamente
- os registros válidos foram processados
- os rejeitos foram gravados com consistência
- os saldos foram consolidados
- o extrato foi gerado
- a conciliação fechou corretamente
- o fechamento diário foi concluído

---

## Valor da grade batch no projeto

A grade batch é uma peça central do laboratório porque permite praticar:

- ordenação de jobs e dependências
- leitura operacional de janelas batch
- critérios de parada e continuidade
- impacto de falhas em cadeia
- investigação orientada por etapa do processo

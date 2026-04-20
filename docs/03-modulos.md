# [03] - MÓDULOS DO SISTEMA - EMUNAH BANK LAB

## Visão Geral

O sistema é dividido em módulos funcionais que refletem as
responsabilidades de um ambiente bancário batch. Cada módulo
agrupa programas, copybooks e datasets relacionados a uma função
específica do negócio.

---

## cliente
Responsável pelo cadastro e manutenção dos dados de clientes.
Garante que o arquivo master de clientes esteja íntegro e
acessível para os demais módulos.

- **Programa principal:** `EBCLLOAD`
- **Dataset master:** `EMUNAH.ARQ.CLIENTE.KSDS`
- **Entrada de seed:** `EMUNAH.SEED.CLIENTES.SEQ`
- **Papel na cadeia:** base de referência para validação e
  aplicação de lançamentos

---

## conta
Responsável pelo cadastro e manutenção das contas bancárias.
É o arquivo mais consultado durante o processamento batch.

- **Programa principal:** `EBCLLOAD`
- **Dataset master:** `EMUNAH.ARQ.CONTA.KSDS`
- **Entrada de seed:** `EMUNAH.SEED.CONTAS.SEQ`
- **Papel na cadeia:** referência obrigatória para validação,
  aplicação e consolidação de saldo

---

## lançamentos
Responsável pelo recebimento, validação e aplicação dos
movimentos financeiros do dia.

- **Programas:** `EBVALI01` (validação), `EBPOST01` (aplicação)
- **Jobs:** `EBJVALD`, `EBJPOST`
- **Datasets:** `EMUNAH.ARQ.ENTRADA.SEQ` (entrada),
  `EMUNAH.ARQ.LANCTO.ESDS` (movimentos aprovados),
  `EMUNAH.ARQ.REJEITO.SEQ` (rejeitos)
- **Papel na cadeia:** coração do processamento diário

---

## saldo
Responsável pela consolidação do saldo por conta ao final
do processamento dos lançamentos.

- **Programa principal:** `EBSALD01`
- **Job:** `EBJSALD`
- **Dataset:** `EMUNAH.ARQ.SALDO.KSDS`
- **Papel na cadeia:** entrada obrigatória para o módulo de
  extrato e conciliação

---

## extrato
Responsável pela geração do extrato diário de cada conta,
com base nos lançamentos aplicados e no saldo consolidado.

- **Programa principal:** `EBEXTR01`
- **Job:** `EBJEXTR`
- **Dataset de saída:** `EMUNAH.ARQ.EXTRATO.GDG` (nova geração
  a cada execução)
- **Papel na cadeia:** produto final visível do processamento
  do dia

---

## conciliação
Responsável por comparar os totais de entrada, registros
aplicados e saldos finais, confirmando a integridade do
processamento.

- **Programa principal:** `EBCONC01`
- **Job:** `EBJCONC`
- **Papel na cadeia:** portão de controle antes do fechamento —
  o dia não fecha se a conciliação não fechar

---

## fechamento
Responsável por encerrar o dia operacional, atualizar controles
e registrar o fechamento do ciclo batch.

- **Job:** `EBJEOD`
- **Dependência:** só executa após conciliação aprovada
- **Papel na cadeia:** último passo da cadeia principal

---

## rejeito
Responsável por registrar e disponibilizar os lançamentos
que não passaram na validação ou na aplicação.

- **Dataset:** `EMUNAH.ARQ.REJEITO.SEQ`
- **Gerado por:** `EBVALI01`, `EBPOST01`
- **Papel na cadeia:** saída de diagnóstico; alimenta o módulo
  de reprocessamento quando necessário

---

## reprocessamento
Responsável pela reaplicação de registros corrigidos que
foram rejeitados em execuções anteriores.

- **Programa principal:** `EBREPR01`
- **Job:** `EBJREPR`
- **Papel na cadeia:** fora da cadeia principal; executado
  somente sob demanda após correção da massa ou do programa

---

## utilitários

Programas de apoio operacional que **não pertencem à cadeia
batch automática**. São executados manualmente, sob demanda,
para diagnóstico, auditoria e conferência de dados.

---

### EBSALD01 — Consulta Manual de Saldo por Conta

Utilitário batch de consulta pontual ao arquivo master de contas.
Permite verificar o saldo de uma ou mais contas específicas sem
interferir na cadeia principal de processamento.

**Localização:** `cobol/util/EBSALD01.cbl`

**Quando usar:**
- conferência de saldo após aplicação de lançamentos
- diagnóstico de inconsistências relatadas por operação ou suporte
- validação de registros antes de um reprocessamento
- auditoria manual de contas específicas durante ou após o batch

**Arquivos envolvidos:**

| DD Name   | Dataset / Tipo             | Papel                                    |
|-----------|----------------------------|------------------------------------------|
| `SALDIN`  | Sequencial (entrada)       | Lista de contas a consultar (agência + conta, 80 bytes) |
| `CONTA`   | `EMUNAH.ARQ.CONTA.KSDS`   | Arquivo master VSAM KSDS — fonte do saldo |
| `SALDOUT` | Sequencial (saída)         | Relatório com saldos encontrados e rejeições |

**Layout do registro de entrada (`SALDIN`):**

```
Posição  01–04  →  Agência   (PIC 9(4))
Posição  05–12  →  Conta     (PIC 9(8))
Posição  13–80  →  FILLER    (não utilizado)
```

**Copybook utilizado:** `CPCNT001` — fornece `CNT-CHAVE` e `CNT-SALDO`
a partir do registro do arquivo `CONTA-KSDS`.

**Fluxo de execução:**

1. Abre `SALDIN`, `CONTA-KSDS` e `SALDOUT`
2. Lê registros de `SALDIN` sequencialmente
3. Para cada conta lida, monta a chave composta (agência + número)
   e executa leitura direta no KSDS
4. Se encontrada: formata e grava linha com saldo no `SALDOUT`
5. Se não encontrada: grava linha de rejeição com identificação
   da conta
6. Ao fim: exibe resumo no SYSOUT e fecha os arquivos

**Saída de console (DISPLAY):**

```
*** RESUMO CONSULTA SALDOS ***
CONTAS LIDAS          : NNNNN
CONTAS ENCONTRADAS    : NNNNN
CONTAS NAO ENCONTRADAS: NNNNN
```

**Contadores internos:**

| Campo              | Descrição                               |
|--------------------|-----------------------------------------|
| `WS-LIDOS`         | Total de registros lidos do `SALDIN`    |
| `WS-ENCONTRADOS`   | Contas localizadas no KSDS              |
| `WS-NAO-ENCONTRADOS` | Contas não encontradas (rejeições)    |

**Observações importantes:**
- Este programa é **somente leitura** — não altera nenhum registro
  no arquivo master de contas
- Não possui job automático associado; deve ser submetido
  manualmente com JCL próprio
- O arquivo `SALDIN` deve ser preparado antes da execução com
  as contas que se deseja consultar
- A saída `SALDOUT` substitui qualquer versão anterior a cada
  execução (OPEN OUTPUT)

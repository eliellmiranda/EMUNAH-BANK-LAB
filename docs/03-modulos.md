# Módulos do Sistema — Emunah Bank Lab

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
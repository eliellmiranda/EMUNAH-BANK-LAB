# Cenario 05 — Debito que Gera Saldo Negativo

## Objetivo
Observar o comportamento do EBPOST01 quando um debito excede o saldo da conta. O programa atual nao bloqueia saldo negativo — ele simplesmente aplica. Este cenario documenta isso como comportamento esperado para o laboratorio.

## Pre-condicoes
- Ambiente completo com cadeia batch funcional
- Uma conta com saldo baixo no VSAM (ex: saldo = R$ 100,00)

## Dados de teste
Incluir um debito maior que o saldo:
```
000100000001202504152OD000000990000DEBITO ALTO             APP
```
Debito de R$ 9.900,00 na conta 0001-00000001 (que tem saldo ~R$ 100,00).

## Sequencia de execucao

| Step | Job | RC esperado | Validacao |
|------|-----|-------------|-----------|
| 1 | EBJVALD | RC=0 | Lancamento valido (formato ok) |
| 2 | EBJPOST | RC=0 | Debito aplicado, saldo fica negativo |
| 3 | EBJSNAP | RC=0 | SALDO.GDG(+1) com saldo negativo registrado para a conta |
| 4 | EBJCONC | RC=0 | Conciliacao three-way ainda fecha — saldo negativo nao quebra a aritmetica |
| 5 | EBSALD01 (utilitario, opcional) | RC=0 | Relatorio manual mostra saldo negativo |

## Resultado esperado
- EBPOST01 aplica o debito sem verificar saldo suficiente
- O saldo da conta fica negativo (comportamento atual, sem limite)
- A auditoria registra "POSTADO" com saldo anterior e posterior
- O snapshot do dia em SALDO.GDG(+1) traz a conta com saldo negativo
- O utilitario `EBSALD01` (em `cobol/util/`), quando executado manualmente, exibe o saldo negativo

## Evidencias a coletar
- Spool do EBJPOST com saldo anterior e saldo posterior
- Geracao mais recente do SALDO.GDG mostrando o saldo negativo
- Trecho do CONCIL.SEQ confirmando que a conciliacao fechou
- Registro de auditoria correspondente

## Evolucao futura
- Adicionar verificacao de saldo + limite antes do debito
- Rejeitar debitos que excedam saldo + limite
- Este cenario serve de baseline para a implementacao dessa regra

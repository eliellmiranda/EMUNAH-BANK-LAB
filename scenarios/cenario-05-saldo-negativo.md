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
| 3 | EBJSALD | RC=0 | Relatorio mostra saldo negativo |

## Resultado esperado
- EBPOST01 aplica o debito sem verificar saldo suficiente
- O saldo da conta fica negativo (comportamento atual, sem limite)
- A auditoria registra "POSTADO" com saldo anterior e posterior
- O EBJSALD exibe o saldo negativo no relatorio

## Evidencias a coletar
- Spool do EBJPOST com saldo anterior e saldo posterior
- Conteudo do SALDO.OUT.SEQ mostrando saldo negativo
- Registro de auditoria correspondente

## Evolucao futura
- Adicionar verificacao de saldo + limite antes do debito
- Rejeitar debitos que excedam saldo + limite
- Este cenario serve de baseline para a implementacao dessa regra

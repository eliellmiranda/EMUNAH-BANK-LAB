# Cenario 01 — Cadeia Batch Normal (Golden Path)

## Objetivo
Executar a cadeia batch completa do inicio ao fim sem erros, validando que todos os jobs completam com RC=0 e que os datasets de saida sao gerados corretamente.

## Pre-condicoes
- Ambiente alocado (EBALLOC executado)
- Programas compilados (EBDEPLOY executado)
- Seed de clientes e contas carregado (EBSEED + EBJCLLD)
- Arquivo de entrada do dia (lancamentos_d0.txt) carregado

## Sequencia de execucao

| Step | Job | RC esperado | Validacao |
|------|-----|-------------|-----------|
| 1 | EBJPRECK | RC=0 | Todos os datasets existem |
| 2 | EBJBACKP | RC=0 | Backups criados (BKP.*) |
| 3 | EBJLOAD | RC=0 | ARQ.ENTRADA.SEQ catalogado |
| 4 | EBJVALD | RC=0 | LANCTO.ESDS populado, REJEITO.SEQ vazio ou com rejeitos |
| 5 | EBJPOST | RC=0 | Saldos atualizados no CONTA.KSDS |
| 6 | EBJSALD | RC=0 | SALDO.OUT.SEQ gerado |
| 7 | EBJEXTR | RC=0 | EXTRATO.SEQ gerado com cabecalho e detalhe |
| 8 | EBJCONC | RC=0 | CONCIL.SEQ gerado com totais |
| 9 | EBJEOD | RC=0 | FECHTO.SEQ gerado, auditoria atualizada |

## Resultado esperado
- 10 registros lidos do arquivo de entrada
- Todos validados e processados (supondo dados corretos)
- Saldos atualizados conforme creditos e debitos
- Extrato com 10 linhas de movimento
- Conciliacao com totais conferidos
- Fechamento concluido com sucesso

## Evidencias a coletar
- Spool de cada job (JESMSGLG, JESYSMSG, SYSOUT)
- Conteudo do ARQ.EXTRATO.SEQ
- Conteudo do ARQ.CONCIL.SEQ
- Conteudo do ARQ.FECHTO.SEQ
- Resumo exibido no SYSOUT de cada programa

## Como executar
```bash
# Via Zowe CLI:
bash automation/submit/submit_cadeia.sh

# Via REXX no TSO:
EXEC '<HLQ>.EMUNAH.DEV.REXX(EBCADEIA)'

# Validar saidas:
bash automation/valida/valida_saida.sh
```

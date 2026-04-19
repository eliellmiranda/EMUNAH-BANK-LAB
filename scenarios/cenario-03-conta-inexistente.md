# Cenario 03 — Lancamento para Conta Inexistente

## Objetivo
Validar o comportamento do EBPOST01 quando recebe um lancamento para uma conta que nao existe no cadastro master.

## Pre-condicoes
- Ambiente completo e funcional
- VSAM de contas carregado com as 40 contas do seed

## Dados de teste
Incluir no arquivo de entrada um lancamento apontando para uma conta inexistente:
```
0001999999992025041520C000000050000DEP CONTA INEXISTENTE  APP
```
A conta 0001-99999999 nao existe no VSAM de contas.

## Sequencia de execucao

| Step | Job | RC esperado | Validacao |
|------|-----|-------------|-----------|
| 1 | EBJVALD | RC=0 | Lancamento valido (campos corretos) |
| 2 | EBJPOST | RC=0 | Lancamento rejeitado por conta nao encontrada |

## Resultado esperado
- EBVALI01 valida o registro normalmente (formato correto)
- EBPOST01 tenta ler a conta 0001-99999999 no KSDS
- READ com INVALID KEY dispara rejeicao
- Auditoria registra "REJEITADO - CONTA NAO ENCONTRADA"
- Resumo do EBPOST01 mostra 1 rejeitado

## Evidencias a coletar
- Spool do EBJVALD (registro passou)
- Spool do EBJPOST (registro rejeitado)
- Conteudo do ARQ.AUDIT.SEQ com a mensagem de rejeicao

## Pontos de atencao
- Este cenario valida a protecao contra dados orfaos
- A rejeicao acontece na postagem, nao na validacao
- O EBVALI01 valida formato; o EBPOST01 valida integridade referencial

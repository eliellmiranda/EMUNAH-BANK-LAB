# Cenario 02 — Rejeito e Reprocessamento

## Objetivo
Validar o fluxo de rejeicao de lancamentos invalidos e o reprocessamento posterior com o job EBJREPR.

## Pre-condicoes
- Ambiente completo e funcional
- Arquivo de entrada com pelo menos 1 registro invalido (tipo != C/D, conta zero, etc.)

## Dados de teste
Incluir no arquivo de entrada (lancamentos_d0.txt) um registro com tipo invalido:
```
0001000000012025041520X000000010000LANCAMENTO TIPO X       APP
```

## Sequencia de execucao

| Step | Job | RC esperado | Validacao |
|------|-----|-------------|-----------|
| 1 | EBJVALD | RC=4 | Registros invalidos gravados em REJEITO.SEQ |
| 2 | (corrigir) | -- | Editar REJEITO.SEQ e corrigir o tipo para 'C' ou 'D' |
| 3 | EBJREPR | RC=0 | Registros recuperados em REPR.LANCTO.SEQ |

## Resultado esperado
- EBJVALD reporta pelo menos 1 rejeito no resumo
- ARQ.REJEITO.SEQ contem o registro com motivo "TIPO INVALIDO"
- Apos correcao e reprocessamento, EBREPR01 recupera o registro
- ARQ.REPR.LANCTO.SEQ contem o registro corrigido
- ARQ.REPR.REJPERM.SEQ vazio (se todos foram corrigidos)

## Evidencias a coletar
- Spool do EBJVALD mostrando RC=4 e contagem de rejeitos
- Conteudo do ARQ.REJEITO.SEQ (antes e depois da correcao)
- Spool do EBJREPR mostrando recuperacao
- Conteudo do ARQ.REPR.LANCTO.SEQ

## Pontos de atencao
- O EBREPR01 aplica as mesmas regras do EBVALI01
- Registros que continuam invalidos vao para REJPERM.SEQ
- O reprocessamento nao afeta a cadeia principal do dia

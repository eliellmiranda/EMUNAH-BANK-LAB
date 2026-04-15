# Cenario 04 — Arquivo de Entrada Ausente

## Objetivo
Validar que a cadeia batch e bloqueada corretamente quando o arquivo de entrada do dia nao existe.

## Pre-condicoes
- Ambiente alocado e programas compilados
- Arquivo ARQ.ENTRADA.SEQ **deletado** ou nao catalogado

## Como provocar a falha
```bash
# Via Zowe CLI:
zowe files delete ds "Z77948.EMUNAH.ARQ.ENTRADA.SEQ" -f

# Via REXX no TSO:
ADDRESS TSO "DELETE 'Z77948.EMUNAH.ARQ.ENTRADA.SEQ'"

# Via script de simulacao:
bash automation/incidentes/simula_incidente.sh 1
```

## Sequencia de execucao

| Step | Job | RC esperado | Validacao |
|------|-----|-------------|-----------|
| 1 | EBJPRECK | RC=12 | CHKENTR falha - arquivo ausente |
| 2 | (cadeia bloqueada) | -- | Jobs dependentes nao devem executar |

## Resultado esperado
- EBJPRECK step CHKENTR retorna RC=12
- IDCAMS reporta LASTCC > 0 no LISTCAT
- A cadeia e interrompida no PRECHECK
- Nenhum job subsequente executa

## Evidencias a coletar
- Spool do EBJPRECK mostrando o IDCAMS com RC=12
- SYSPRINT do IDCAMS com "ENTRY NOT FOUND"

## Resolucao
1. Recriar o arquivo de entrada com os dados do dia
2. Fazer upload do lancamentos_d0.txt
3. Reexecutar a cadeia a partir do EBJPRECK

## Pontos de atencao
- Se o EBJLOAD for executado diretamente (sem PRECHECK), ele tambem falhara com RC=12
- O PRECHECK e a primeira barreira de protecao da cadeia

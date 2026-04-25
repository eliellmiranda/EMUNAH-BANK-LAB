# Cenario 01 — Cadeia Batch Normal (Golden Path)

## Objetivo
Executar a cadeia batch redesenhada do inicio ao fim sem erros, validando que todos os jobs completam com RC aceitavel, que `ARQ.CTL.STATUS` transita `OPEN -> EOTI -> EOFI -> CLOSED`, e que os datasets/GDGs de saida sao gerados corretamente.

## Pre-condicoes
- Ambiente alocado (EBALLOC executado)
- Bases GDG definidas (EBDEFGDG executado)
- Programas compilados (EBDEPLOY / EBBUILD)
- Seed de clientes e contas carregado (EBSEED + EBJCLLD)
- `ARQ.CTL.STATUS` vazio ou `CLOSED` (ciclo anterior fechado)
- Arquivo do dia em `STAGE.ENTRADA.SEQ` (com trailer/manifest, se aplicavel)
- `PARM.JUROS.CONFIG` com parametros validos para `EBACCR01`

## Sequencia de execucao

| Step | Job | Fase | RC esperado | Validacao |
|------|-----|------|-------------|-----------|
| 1 | EBJPRECK | SOD | RC<=4 | Datasets/LOADLIB/COPY presentes; CTL.STATUS lido |
| 2 | EBJSOD   | SOD | RC=0 | CTL.STATUS=OPEN; CTL.PROCDATE gravado |
| 3 | EBJBCKPD | SOD | RC=0 | Geracao nova em BKP.CLIENTE/CONTA/AUDIT.GDG(+1) |
| 4 | EBJWAIT  | INTAKE | RC=0 | STAGE.ENTRADA.SEQ valido (existe + trailer OK) |
| 5 | EBJLOAD  | INTAKE | RC=0 | ARQ.ENTRADA.SEQ promovido a partir do STAGE |
| 6 | EBJVALD  | VALIDATION | RC<=4 | LANCTO.ESDS com validos; REJEITOS.SEQ segregado |
| 7 | EBJPOST  | POSTING | RC=0 | CONTA.KSDS atualizado; AUDIT.SEQ com trilha |
| 8 | EBJACCR  | ACCRUAL | RC=0 | ACCR.MOV.SEQ gerado; append em LANCTO.ESDS |
| 9 | EBJCUTF  | EOTI | RC=0 | CTL.STATUS=EOTI |
| 10 | EBJSNAP | SNAPSHOT | RC=0 | SALDO.GDG(+1) com saldo final por conta |
| 11 | EBJCUTE | EOFI | RC=0 | CTL.STATUS=EOFI |
| 12 | EBJCONC | RECONCILIATION | RC=0 | CONCIL.SEQ com tres secoes em `OK` (S1/S2/S3) |
| 13 | EBJEXTR | OUTPUT | RC=0 | EXTRATO.GDG(+1) com cabecalho e detalhe |
| 14 | EBJEOD  | OUTPUT | RC=0 | FECHTO.SEQ; CTL.STATUS=CLOSED |

## Resultado esperado
- 10 registros do STAGE promovidos para ARQ.ENTRADA.SEQ
- Todos validados e processados (supondo dados corretos)
- Saldos atualizados conforme creditos, debitos e accrual
- Snapshot de saldo do dia em SALDO.GDG(+1)
- Conciliacao three-way fechada (`OK` em S1, S2 e S3)
- Extrato em EXTRATO.GDG(+1) com cabecalho e detalhe
- Fechamento concluido (CTL.STATUS=CLOSED) e auditoria atualizada

## Evidencias a coletar
- Spool de cada job (JESMSGLG, JESYSMSG, SYSOUT)
- Conteudo final de `ARQ.CTL.STATUS` (CLOSED) e `ARQ.CTL.PROCDATE`
- Geracoes recem-criadas em SALDO.GDG, EXTRATO.GDG e BKP.*.GDG
- Conteudo do ARQ.CONCIL.SEQ (tres secoes)
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

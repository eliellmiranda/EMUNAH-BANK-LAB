/* REXX ----------------------------------------------------------- */
/* PROGRAMA : EBSUBMIT                                              */
/* FUNCAO   : SUBMETER JOB DA CADEIA BATCH EMUNAH BANK              */
/* LOCAL    : RECURSO DE OPERADOR                                   */
/*----------------------------------------------------------------- */
PARSE UPPER ARG JOBNAME

IF JOBNAME = '' THEN DO
  SAY 'ERRO: Informe o nome do JOB.'
  SAY 'USO : EBSUBMIT <JOBNAME>'
  SAY ''
  SAY 'JOBS DISPONIVEIS NO LAB:'
  SAY '  EBJPRECK - CHECKLIST DE AMBIENTE'
  SAY '  EBJBACKP - BACKUP DOS ARQUIVOS'
  SAY '  EBJVALD  - VALIDACAO DE MOVIMENTOS'
  SAY '  EBJCHAIN - CADEIA COMPLETA (EOD)'
  EXIT 4
END

JCLLIB = "Z77948.EMUNAH.DEV.JCL"
FULL_DSN = "'"JCLLIB"("JOBNAME")'"

/* Verifica se o membro existe na biblioteca antes de submeter */
X = LISTDSI(FULL_DSN)
IF X <> 0 THEN DO
  SAY 'ERRO: JOB' JOBNAME 'NAO ENCONTRADO EM' JCLLIB
  EXIT 8
END

SAY 'SUBMETENDO' JOBNAME '...'
ADDRESS TSO "SUBMIT" FULL_DSN

IF RC = 0 THEN DO
  SAY 'SUCESSO: JOB' JOBNAME 'ENVIADO PARA O JES.'
  SAY 'DICA: USE SDSF (ST) PARA MONITORAR.'
  EXIT 0
END
ELSE DO
  SAY 'FALHA: ERRO AO SUBMETER' JOBNAME '. RC='RC
  EXIT 12
END
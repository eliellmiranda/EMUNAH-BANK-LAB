/* REXX ---------------------------------------------------------------*/
/* PROGRAMA : EBSUBMIT                                                */
/* FUNCAO   : SUBMETER UM JOB DA CADEIA BATCH EMUNAH                 */
/*                                                                    */
/* USO: EXEC 'Z77948.EMUNAH.DEV.REXX(EBSUBMIT)' 'EBJVALD'          */
/*                                                                    */
/* O QUE ESTE EXEC FAZ:                                               */
/* - Recebe o nome do job como parametro                              */
/* - Valida se o membro existe na JCL library                         */
/* - Submete o job via SUBMIT                                         */
/* - Exibe confirmacao ou erro                                        */
/*                                                                    */
/* PARA QUE ELE SERVE:                                                */
/* - Facilitar a submissao de jobs do laboratorio                     */
/* - Padronizar a forma de execucao da cadeia batch                   */
/* - Servir como base para automacao mais complexa                    */
/*--------------------------------------------------------------------*/

PARSE ARG JOBNAME

IF JOBNAME = '' THEN DO
  SAY 'ERRO: Informe o nome do job.'
  SAY 'USO : EBSUBMIT <jobname>'
  SAY ''
  SAY 'Jobs disponiveis:'
  SAY '  EBJPRECK - Pre-check do ambiente'
  SAY '  EBJBACKP - Backup pre-batch'
  SAY '  EBJLOAD  - Prepara arquivo do dia'
  SAY '  EBJVALD  - Validacao de lancamentos'
  SAY '  EBJPOST  - Postagem de lancamentos'
  SAY '  EBJSALD  - Consolidacao de saldos'
  SAY '  EBJEXTR  - Geracao de extrato'
  SAY '  EBJCONC  - Conciliacao'
  SAY '  EBJEOD   - Fechamento diario'
  SAY '  EBJREPR  - Reprocessamento (sob demanda)'
  EXIT 4
END

JOBNAME = STRIP(JOBNAME)
JCLLIB = "Z77948.EMUNAH.DEV.JCL"

/* Verifica se o membro existe */
X = LISTDSI("'"JCLLIB"("JOBNAME")'")
IF X <> 0 THEN DO
  SAY 'ERRO: Membro 'JOBNAME' nao encontrado em 'JCLLIB
  EXIT 8
END

/* Submete o job */
SAY 'Submetendo 'JOBNAME'...'
ADDRESS TSO "SUBMIT '"JCLLIB"("JOBNAME")'"

IF RC = 0 THEN DO
  SAY 'Job 'JOBNAME' submetido com sucesso.'
  SAY 'Use SDSF (ST) para acompanhar a execucao.'
  EXIT 0
END
ELSE DO
  SAY 'ERRO ao submeter 'JOBNAME'. RC='RC
  EXIT 12
END

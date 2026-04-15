/* REXX ---------------------------------------------------------------*/
/* PROGRAMA : EBCADEIA                                                */
/* FUNCAO   : SUBMETER A CADEIA BATCH COMPLETA EM SEQUENCIA          */
/*                                                                    */
/* O QUE ESTE EXEC FAZ:                                               */
/* - Submete cada job da cadeia na ordem correta                      */
/* - Aguarda a conclusao de cada step antes do proximo                */
/* - Verifica o RC de cada job antes de continuar                     */
/* - Para a cadeia se um job critico falhar (RC > 4)                  */
/* - Exibe resumo final da execucao                                   */
/*                                                                    */
/* PARA QUE ELE SERVE:                                                */
/* - Executar o ciclo batch completo do laboratorio                   */
/* - Simular uma scheduler de cadeia batch                            */
/* - Praticar dependencias entre jobs                                 */
/*--------------------------------------------------------------------*/

HLQ = 'Z77948.EMUNAH'
JCLLIB = HLQ'.DEV.JCL'

/* Define a cadeia na ordem */
JOB.1  = 'EBJPRECK'
JOB.2  = 'EBJBACKP'
JOB.3  = 'EBJLOAD'
JOB.4  = 'EBJVALD'
JOB.5  = 'EBJPOST'
JOB.6  = 'EBJSALD'
JOB.7  = 'EBJEXTR'
JOB.8  = 'EBJCONC'
JOB.9  = 'EBJEOD'
JOB.0  = 9

SAY '================================================='
SAY ' EMUNAH BANK LAB - EXECUCAO DA CADEIA BATCH'
SAY '================================================='
SAY ''

TOTAL_OK = 0
TOTAL_WARN = 0
TOTAL_ERRO = 0
PAROU = 'N'

DO I = 1 TO JOB.0
  JOBNAME = JOB.I

  SAY 'STEP 'I'/'JOB.0': Submetendo 'JOBNAME'...'

  /* Verifica se o membro existe */
  X = LISTDSI("'"JCLLIB"("JOBNAME")'")
  IF X <> 0 THEN DO
    SAY '  *** ERRO: Membro 'JOBNAME' nao encontrado.'
    TOTAL_ERRO = TOTAL_ERRO + 1
    PAROU = 'S'
    LEAVE
  END

  ADDRESS TSO "SUBMIT '"JCLLIB"("JOBNAME")'"

  IF RC = 0 THEN DO
    SAY '  Submetido com sucesso.'
    TOTAL_OK = TOTAL_OK + 1
  END
  ELSE IF RC <= 4 THEN DO
    SAY '  Concluido com avisos (RC='RC').'
    TOTAL_WARN = TOTAL_WARN + 1
  END
  ELSE DO
    SAY '  *** ERRO CRITICO (RC='RC'). Cadeia interrompida.'
    TOTAL_ERRO = TOTAL_ERRO + 1
    PAROU = 'S'
    LEAVE
  END

  SAY ''
END

SAY '================================================='
SAY ' RESUMO DA CADEIA'
SAY '================================================='
SAY '  Jobs executados com sucesso : 'TOTAL_OK
SAY '  Jobs com avisos             : 'TOTAL_WARN
SAY '  Jobs com erro               : 'TOTAL_ERRO
IF PAROU = 'S' THEN
  SAY '  STATUS: CADEIA INTERROMPIDA'
ELSE
  SAY '  STATUS: CADEIA CONCLUIDA'
SAY '================================================='

IF TOTAL_ERRO > 0 THEN
  EXIT 8
ELSE IF TOTAL_WARN > 0 THEN
  EXIT 4
ELSE
  EXIT 0

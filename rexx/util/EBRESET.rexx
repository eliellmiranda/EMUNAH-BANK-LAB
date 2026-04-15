/* REXX ---------------------------------------------------------------*/
/* PROGRAMA : EBRESET                                                 */
/* FUNCAO   : RESETAR AMBIENTE DO LABORATORIO PARA ESTADO INICIAL    */
/*                                                                    */
/* O QUE ESTE EXEC FAZ:                                               */
/* - Deleta datasets de saida/temporarios da cadeia batch             */
/* - Mantem datasets de desenvolvimento (LOADLIB, COBOL, COPY, JCL)  */
/* - Mantem datasets de seed (CLIENTES, CONTAS)                      */
/* - Mantem VSAM masters (CLIENTE.KSDS, CONTA.KSDS)                  */
/* - Limpa: LANCTO, REJEITO, AUDIT, SALDO.OUT, CONCIL, EXTRATO,     */
/*   FECHTO, e datasets de backup                                    */
/*                                                                    */
/* PARA QUE ELE SERVE:                                                */
/* - Preparar o ambiente para uma nova execucao da cadeia batch       */
/* - Limpar resultados anteriores sem perder o cadastro master        */
/* - Permitir testes repetitivos e controlados                        */
/*                                                                    */
/* ATENCAO: Este exec deleta dados! Use com cuidado.                  */
/*--------------------------------------------------------------------*/

HLQ = 'Z77948.EMUNAH'

SAY '================================================='
SAY ' EMUNAH BANK LAB - RESET DO AMBIENTE'
SAY '================================================='
SAY ''
SAY 'ATENCAO: Datasets de saida serao deletados.'
SAY 'Datasets master e de seed serao preservados.'
SAY ''

/* Datasets a deletar (saida/temporarios) */
DEL.1  = HLQ'.ARQ.LANCTO.ESDS'
DEL.2  = HLQ'.ARQ.REJEITO.SEQ'
DEL.3  = HLQ'.ARQ.AUDIT.SEQ'
DEL.4  = HLQ'.ARQ.SALDO.OUT.SEQ'
DEL.5  = HLQ'.ARQ.CONCIL.SEQ'
DEL.6  = HLQ'.ARQ.EXTRATO.SEQ'
DEL.7  = HLQ'.ARQ.FECHTO.SEQ'
DEL.8  = HLQ'.ARQ.REPR.LANCTO.SEQ'
DEL.9  = HLQ'.ARQ.REPR.REJPERM.SEQ'
DEL.10 = HLQ'.BKP.CLIENTE.SEQ'
DEL.11 = HLQ'.BKP.CONTA.SEQ'
DEL.12 = HLQ'.BKP.AUDIT.SEQ'
DEL.0  = 12

DELETADOS = 0
AUSENTES  = 0
ERROS     = 0

DO I = 1 TO DEL.0
  DSN = DEL.I
  X = LISTDSI("'"DSN"'")
  IF X = 0 THEN DO
    ADDRESS TSO "DELETE '"DSN"'"
    IF RC = 0 THEN DO
      SAY '  DELETADO - 'DSN
      DELETADOS = DELETADOS + 1
    END
    ELSE DO
      SAY '  ERRO     - 'DSN' (RC='RC')'
      ERROS = ERROS + 1
    END
  END
  ELSE DO
    SAY '  AUSENTE  - 'DSN' (nada a fazer)'
    AUSENTES = AUSENTES + 1
  END
END

SAY ''
SAY '-------------------------------------------------'
SAY '  Datasets deletados : 'DELETADOS
SAY '  Ja ausentes        : 'AUSENTES
SAY '  Erros              : 'ERROS
SAY '-------------------------------------------------'
SAY ''

IF ERROS = 0 THEN DO
  SAY 'Ambiente resetado com sucesso.'
  SAY 'Execute EBJPRECK para iniciar nova cadeia.'
  EXIT 0
END
ELSE DO
  SAY 'Reset concluido com erros. Verifique manualmente.'
  EXIT 8
END

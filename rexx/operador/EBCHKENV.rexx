/* REXX ---------------------------------------------------------------*/
/* PROGRAMA : EBCHKENV                                                */
/* FUNCAO   : VERIFICAR AMBIENTE DO LABORATORIO EMUNAH BANK           */
/*                                                                    */
/* O QUE ESTE EXEC FAZ:                                               */
/* - Verifica se os datasets principais do lab existem                */
/* - Lista o status de cada recurso (OK / AUSENTE)                    */
/* - Retorna RC=0 se tudo ok, RC=8 se algum recurso falta            */
/*                                                                    */
/* PARA QUE ELE SERVE:                                                */
/* - Checklist rapido antes de executar a cadeia batch                */
/* - Diagnostico de ambiente para troubleshooting                     */
/* - Validacao apos deploy ou reset do ambiente                       */
/*--------------------------------------------------------------------*/

HLQ = 'Z77948.EMUNAH'
ERROS = 0

SAY '================================================='
SAY ' EMUNAH BANK LAB - VERIFICACAO DE AMBIENTE'
SAY '================================================='
SAY ''

/* Lista de datasets a verificar */
DS.1  = HLQ'.DEV.LOADLIB'
DS.2  = HLQ'.DEV.COBOL'
DS.3  = HLQ'.DEV.COPY'
DS.4  = HLQ'.DEV.JCL'
DS.5  = HLQ'.ARQ.CLIENTE.KSDS'
DS.6  = HLQ'.ARQ.CONTA.KSDS'
DS.7  = HLQ'.ARQ.ENTRADA.SEQ'
DS.8  = HLQ'.ARQ.LANCTO.ESDS'
DS.9  = HLQ'.ARQ.REJEITO.SEQ'
DS.10 = HLQ'.ARQ.AUDIT.SEQ'
DS.11 = HLQ'.ARQ.SALDO.SEQ'
DS.12 = HLQ'.ARQ.CONCIL.SEQ'
DS.13 = HLQ'.SEED.CLIENTES.SEQ'
DS.14 = HLQ'.SEED.CONTAS.SEQ'
DS.0  = 14

DO I = 1 TO DS.0
  DSN = DS.I
  X = LISTDSI("'"DSN"'")
  IF X = 0 THEN
    SAY '  OK      - 'DSN
  ELSE DO
    SAY '  AUSENTE - 'DSN
    ERROS = ERROS + 1
  END
END

SAY ''
SAY '-------------------------------------------------'
IF ERROS = 0 THEN DO
  SAY ' RESULTADO: AMBIENTE COMPLETO (0 ERROS)'
  SAY '-------------------------------------------------'
  EXIT 0
END
ELSE DO
  SAY ' RESULTADO: 'ERROS' RECURSO(S) AUSENTE(S)'
  SAY '-------------------------------------------------'
  EXIT 8
END

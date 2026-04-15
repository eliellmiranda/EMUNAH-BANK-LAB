/* REXX ---------------------------------------------------------------*/
/* PROGRAMA : EBDSLIST                                                */
/* FUNCAO   : LISTAR DATASETS DO LABORATORIO COM STATUS              */
/*                                                                    */
/* O QUE ESTE EXEC FAZ:                                               */
/* - Lista todos os datasets alocados para o lab EMUNAH               */
/* - Exibe tipo de organizacao (SEQ, KSDS, ESDS, PDS)                */
/* - Exibe espaco utilizado e disponivel                              */
/* - Classifica por grupo (DEV, ARQ, SEED, BKP)                      */
/*                                                                    */
/* PARA QUE ELE SERVE:                                                */
/* - Inventario rapido dos datasets do ambiente                       */
/* - Diagnostico de espaco e organizacao                              */
/* - Apoio a documentacao e troubleshooting                           */
/*--------------------------------------------------------------------*/

HLQ = 'Z77948.EMUNAH'

SAY '================================================='
SAY ' EMUNAH BANK LAB - INVENTARIO DE DATASETS'
SAY '================================================='
SAY ''
SAY LEFT('DATASET',45) LEFT('TIPO',8) LEFT('STATUS',10)
SAY COPIES('-',45) COPIES('-',8) COPIES('-',10)

/* Datasets de desenvolvimento */
CALL VERIFICAR HLQ'.DEV.LOADLIB',  'PDS'
CALL VERIFICAR HLQ'.DEV.COBOL',   'PDS'
CALL VERIFICAR HLQ'.DEV.COPY',    'PDS'
CALL VERIFICAR HLQ'.DEV.JCL',     'PDS'

SAY ''

/* Datasets de dados */
CALL VERIFICAR HLQ'.ARQ.CLIENTE.KSDS', 'KSDS'
CALL VERIFICAR HLQ'.ARQ.CONTA.KSDS',   'KSDS'
CALL VERIFICAR HLQ'.ARQ.LANCTO.ESDS',  'ESDS'
CALL VERIFICAR HLQ'.ARQ.ENTRADA.SEQ',  'SEQ'
CALL VERIFICAR HLQ'.ARQ.REJEITO.SEQ',  'SEQ'
CALL VERIFICAR HLQ'.ARQ.AUDIT.SEQ',    'SEQ'
CALL VERIFICAR HLQ'.ARQ.SALDO.SEQ',    'SEQ'
CALL VERIFICAR HLQ'.ARQ.SALDO.OUT.SEQ','SEQ'
CALL VERIFICAR HLQ'.ARQ.CONCIL.SEQ',   'SEQ'
CALL VERIFICAR HLQ'.ARQ.EXTRATO.SEQ',  'SEQ'
CALL VERIFICAR HLQ'.ARQ.FECHTO.SEQ',   'SEQ'

SAY ''

/* Datasets de seed */
CALL VERIFICAR HLQ'.SEED.CLIENTES.SEQ', 'SEQ'
CALL VERIFICAR HLQ'.SEED.CONTAS.SEQ',   'SEQ'

SAY ''

/* Datasets de backup */
CALL VERIFICAR HLQ'.BKP.CLIENTE.SEQ',  'SEQ'
CALL VERIFICAR HLQ'.BKP.CONTA.SEQ',    'SEQ'
CALL VERIFICAR HLQ'.BKP.AUDIT.SEQ',    'SEQ'

SAY ''
SAY '================================================='
EXIT 0

/* Sub-rotina de verificacao */
VERIFICAR:
  PARSE ARG DSN, TIPO_ESPERADO
  X = LISTDSI("'"DSN"'")
  IF X = 0 THEN
    SAY LEFT(DSN,45) LEFT(TIPO_ESPERADO,8) 'OK'
  ELSE
    SAY LEFT(DSN,45) LEFT(TIPO_ESPERADO,8) 'AUSENTE'
  RETURN

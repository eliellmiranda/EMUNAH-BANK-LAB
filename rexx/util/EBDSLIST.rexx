/* REXX ----------------------------------------------------------- */
/* PROGRAMA : EBDSLIST                                              */
/* FUNCAO   : INVENTARIO E VOLUMETRIA DE DATASETS - EMUNAH BANK     */
/* LOCAL    : RECURSO DE UTILITARIO                                 */
/*----------------------------------------------------------------- */
HLQ = 'Z77948.EMUNAH'

SAY CENTER(' EMUNAH BANK - INVENTARIO DE DATASETS ',65,'=')
SAY LEFT('DATASET',44) LEFT('ORG',5) LEFT('STATUS',7) 'USADO/ALOC'
SAY COPIES('-',65)

/* Grupo: Desenvolvimento */
CALL VERIFICAR HLQ'.DEV.LOADLIB'
CALL VERIFICAR HLQ'.DEV.COBOL'
CALL VERIFICAR HLQ'.DEV.COPY'
CALL VERIFICAR HLQ'.DEV.JCL'
SAY ''

/* Grupo: Arquivos de Dados */
CALL VERIFICAR HLQ'.ARQ.CLIENTE.KSDS'
CALL VERIFICAR HLQ'.ARQ.CONTA.KSDS'
CALL VERIFICAR HLQ'.ARQ.LANCTO.ESDS'
CALL VERIFICAR HLQ'.ARQ.ENTRADA.SEQ'
CALL VERIFICAR HLQ'.ARQ.REJEITO.SEQ'
SAY ''

/* Grupo: Seed e Backup */
CALL VERIFICAR HLQ'.SEED.CONTAS.SEQ'
CALL VERIFICAR HLQ'.BKP.CONTA.SEQ'

SAY COPIES('=',65)
EXIT 0

/* Sub-rotina para extrair metadados reais via LISTDSI */
VERIFICAR:
  PARSE ARG DSN
  X = LISTDSI("'"DSN"'")
  
  IF X = 0 THEN DO
    ORG = SYSDSORG
    IF ORG = 'VS' THEN ORG = 'VSAM'
    
    /* SYSUSED e SYSALLOC mostram a ocupacao em trilhas/blocos */
    SPACE = SYSUSED'/'SYSALLOC
    SAY LEFT(DSN,44) LEFT(ORG,5) LEFT('OK',7) SPACE
  END
  ELSE DO
    SAY LEFT(DSN,44) LEFT('????',5) LEFT('MISSING',7) '-'
  END
RETURN
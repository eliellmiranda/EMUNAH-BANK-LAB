/* REXX ----------------------------------------------------------- */
/* PROGRAMA : EBCHKLAB                                              */
/* FUNCAO   : AUDITORIA TECNICA DOS DATASETS DO LABORATORIO         */
/* LOCAL    : RECURSO DE OPERADOR                                   */
/*----------------------------------------------------------------- */
PARSE UPPER ARG PFX
ADDRESS TSO

/* Define o HLQ padrao se nenhum for informado via parametro */
IF PFX = '' THEN PFX = 'Z77948.EMUNAH'

SAY CENTER(' EMUNAH BANK - AUDITORIA DE ATRIBUTOS ',65,'-')
SAY 'PREFIXO ANALISADO: ' PFX
SAY COPIES('=',65)
SAY LEFT('DATASET',45) LEFT('ORG',6) 'LRECL/RECFM'
SAY COPIES('-',65)

I = 0
CALL ADDDSN PFX'.DEV.REXX'
CALL ADDDSN PFX'.HML.COBOL'
CALL ADDDSN PFX'.HML.JCL'
CALL ADDDSN PFX'.PRD.JCL'
CALL ADDDSN PFX'.PRD.LOADLIB'
CALL ADDDSN PFX'.SEED.CONTAS.SEQ'
CALL ADDDSN PFX'.ARQ.CONTA.KSDS'

DO X = 1 TO I
  RCX = LISTDSI("'"DS.X"'")

  IF RCX = 0 THEN DO
    ORG = SYSDSORG
    IF ORG = 'VS' THEN ORG = 'VSAM'
    
    ATTRS = RIGHT(SYSLRECL,5) '/' SYSRECFM
    SAY LEFT(DS.X,45) LEFT(ORG,6) ATTRS
  END
  ELSE DO
    SAY LEFT(DS.X,45) LEFT('????',6) 'NAO ENCONTRADO (RC='RCX')'
  END
END

SAY COPIES('=',65)
EXIT 0

/* Sub-rotina para empilhar os datasets na lista de auditoria */
ADDDSN:
  PARSE ARG NOME
  I = I + 1
  DS.I = NOME
RETURN
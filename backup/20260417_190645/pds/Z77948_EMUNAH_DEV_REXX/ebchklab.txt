/* REXX *************************************************************/
/* MEMBRO   : EBCHKLAB                                              */
/* BIBLIOTECA: Z77948.EMUNAH.DEV.REXX                               */
/* FUNCAO   : VERIFICAR SE OS PRINCIPAIS DATASETS DO LAB EXISTEM    */
/*                                                                    */
/* O QUE ESTE EXEC FAZ:                                              */
/* - Recebe opcionalmente um prefixo                                 */
/* - Monta a lista dos principais datasets do laboratorio            */
/* - Usa LISTDSI para verificar se o dataset existe                  */
/* - Exibe atributos basicos quando encontrado                       */
/*                                                                    */
/* EXEMPLOS DE USO:                                                  */
/*   EX 'Z77948.EMUNAH.DEV.REXX(EBCHKLAB)'                           */
/*   EX 'Z77948.EMUNAH.DEV.REXX(EBCHKLAB)' 'Z77948.EMUNAH'           */
/*                                                                    */
/* OBSERVACOES:                                                      */
/* - O prefixo padrao eh Z77948.EMUNAH                               */
/* - Ajuste a lista abaixo conforme a evolucao do laboratorio        */
/*********************************************************************/

PARSE UPPER ARG PFX
ADDRESS TSO

IF PFX = '' THEN
    PFX = 'Z77948.EMUNAH'

SAY '*** CHECK DO LAB EMUNAH ***'
SAY 'PREFIXO UTILIZADO:' PFX
SAY ' '

I = 0

CALL ADDDSN PFX'.DEV.REXX'
CALL ADDDSN PFX'.HML.COBOL'
CALL ADDDSN PFX'.HML.JCL'
CALL ADDDSN PFX'.PRD.JCL'
CALL ADDDSN PFX'.PRD.LOADLIB'
CALL ADDDSN PFX'.PRD.PARMLIB'
CALL ADDDSN PFX'.SEED.CLIENTES.SEQ'
CALL ADDDSN PFX'.SEED.CONTAS.SEQ'

DO X = 1 TO I
    RCX = LISTDSI("'"DS.X"'")

    IF RCX = 0 THEN DO
        SAY 'OK  - ' DS.X
        SAY '      DSORG=' SYSDSORG ' RECFM=' SYSRECFM,
            ' LRECL=' SYSLRECL
    END
    ELSE DO
        SAY 'NOK - ' DS.X ' NAO ENCONTRADO. RC=' RCX
    END
END

EXIT 0

ADDDSN:
    PARSE ARG NOME
    I = I + 1
    DS.I = NOME
    RETURN

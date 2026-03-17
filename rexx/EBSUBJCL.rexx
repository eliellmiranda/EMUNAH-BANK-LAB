/* REXX *************************************************************/
/* MEMBRO   : EBSUBJCL                                              */
/* BIBLIOTECA: Z77948.EMUNAH.DEV.REXX                               */
/* FUNCAO   : SUBMETER UM MEMBRO JCL INFORMADO POR PARAMETRO        */
/*                                                                    */
/* O QUE ESTE EXEC FAZ:                                              */
/* - Recebe o nome do membro JCL                                     */
/* - Recebe opcionalmente a biblioteca JCL                           */
/* - Monta o nome fully-qualified DSN(MEMBER)                        */
/* - Executa SUBMIT via TSO                                          */
/*                                                                    */
/* EXEMPLOS DE USO:                                                  */
/*   EX 'Z77948.EMUNAH.DEV.REXX(EBSUBJCL)' 'EBJSMKH'                 */
/*   EX 'Z77948.EMUNAH.DEV.REXX(EBSUBJCL)'                           */
/*      'EBJEODP Z77948.EMUNAH.PRD.JCL'                              */
/*                                                                    */
/* REGRAS:                                                           */
/* - Se a JCLLIB nao for informada, assume HML.JCL                   */
/* - O membro deve existir na biblioteca informada                   */
/*********************************************************************/

PARSE UPPER ARG MEMBRO JCLLIB
ADDRESS TSO

IF MEMBRO = '' THEN DO
    SAY 'USO: EBSUBJCL <MEMBRO> [JCLLIB]'
    SAY 'EX.: EBSUBJCL EBJSMKH'
    SAY 'EX.: EBSUBJCL EBJEODP Z77948.EMUNAH.PRD.JCL'
    EXIT 8
END

IF JCLLIB = '' THEN
    JCLLIB = 'Z77948.EMUNAH.HML.JCL'

ALVO = JCLLIB'('MEMBRO')'

SAY 'SUBMETENDO JOB:' ALVO
"SUBMIT '"ALVO"'"

IF RC <> 0 THEN DO
    SAY 'ERRO AO SUBMETER JOB. RC=' RC
    EXIT 8
END

SAY 'JOB SUBMETIDO COM SUCESSO:' ALVO
EXIT 0